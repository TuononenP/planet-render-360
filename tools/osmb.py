#!/usr/bin/env python3
"""Compact binary form of the bundled OSM snapshots (.osmb).

A snapshot is an Overpass JSON response. Most of its bytes are coordinate
text, repeated tag strings and way node-id lists nobody reads, so .osmb
keeps the same elements in a smaller shape:

  - coordinates as integers of 1e-7 degrees, OSM's own precision (so the
    decoded text matches live Overpass coordinates exactly), delta-coded
    against the previous coordinate in the file
  - one string table for types, tag keys and values and member roles
  - element and member ids delta-coded
  - way node-id lists and bounds dropped (OsmParser reads neither)

The whole payload is zstd-compressed (Godot reads it with
FileAccess.COMPRESSION_ZSTD). BundledOsm checks the payload's size and
SHA-256 against its manifest row, then decodes it back to Overpass JSON
text (SnapshotKernels natively, OsmbCodec in GDScript otherwise), so every
reader of snapshot text works unchanged.

Payload layout (varint = unsigned LEB128; svarint = zigzag varint):

  "PROB"  varint version (1)
  varint n + n bytes   header JSON: the response minus "elements"
  varint n             string table, then n x (varint len + UTF-8 bytes)
  varint n             elements, each:
    varint type        string index
    svarint id         minus the previous element's id
    varint flags       1 tags, 2 geometry, 4 lat/lon, 8 members, 16 center
    [tags]             varint n, n x (varint key, varint value)
    [lat/lon]          svarint dlat, svarint dlon
    [center]           svarint dlat, svarint dlon
    [geometry]         points
    [members]          varint n, n x member:
        varint type, svarint ref (minus the previous member's ref),
        varint role, varint flags (1 geometry, 2 lat/lon), then those
  points: varint count, varint nulls, nulls x varint index (null entries,
          ascending), then the rest as svarint dlat, svarint dlon

Usage:
  python3 tools/osmb.py encode in.json[.gz] out.osmb   prints size and sha256
  python3 tools/osmb.py decode in.osmb [out.json]      Overpass JSON text
  python3 tools/osmb.py convert-all [--from DIR]       every bundled snapshot,
                                                       from DIR/<key>.json.gz
"""

import gzip
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys

MAGIC = b"PROB"
VERSION = 2
SCALE = 10_000_000
F_TAGS, F_GEOM, F_LATLON, F_MEMBERS, F_CENTER = 1, 2, 4, 8, 16
M_GEOM, M_LATLON = 1, 2
ZSTD_LEVEL = 19

ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
SNAPSHOTS = os.path.join(ROOT, "assets", "osm_snapshots")
BUNDLED_GD = os.path.join(ROOT, "scripts", "data", "bundled_osm.gd")
MANIFESTS = ["capital_manifest.json", "horizon_manifest.json"]


def _varint(out, n):
    if n < 0:
        raise ValueError("negative varint")
    while n >= 0x80:
        out.append((n & 0x7F) | 0x80)
        n >>= 7
    out.append(n)


def _svarint(out, n):
    _varint(out, (n << 1) if n >= 0 else ((-n << 1) - 1))


def _micro(v):
    return int(round(float(v) * SCALE))


class _Encoder:
    def __init__(self):
        self.out = bytearray()
        self.strings = {}
        self.lat = 0
        self.lon = 0

    def s(self, text):
        text = str(text)
        if text not in self.strings:
            # Godot's json_escape writes U+000B as \v, which its JSON parser rejects.
            if "\x0b" in text:
                raise ValueError("string with a vertical tab: %r" % text)
            self.strings[text] = len(self.strings)
        return self.strings[text]

    def coord(self, body, lat, lon, exact=True):
        la, lo = _micro(lat), _micro(lon)
        # Lossless for OSM positions: a snapshot's coordinates must match live
        # Overpass text exactly, or ways joined across layers (a cached live
        # detailed layer and a bundled ring) stop meeting at their shared
        # nodes. A derived `center` (a bounding-box middle) may round.
        if exact and (la / SCALE != float(lat) or lo / SCALE != float(lon)):
            raise ValueError("coordinate finer than 1e-7 degrees: %r, %r" % (lat, lon))
        _svarint(body, la - self.lat)
        _svarint(body, lo - self.lon)
        self.lat, self.lon = la, lo

    def points(self, body, geom):
        _varint(body, len(geom))
        nulls = [i for i, g in enumerate(geom) if g is None]
        _varint(body, len(nulls))
        for i in nulls:
            _varint(body, i)
        for g in geom:
            if g is not None:
                self.coord(body, g["lat"], g["lon"])


def encode(data):
    """The .osmb payload (uncompressed) for an Overpass JSON object."""
    known = {"type", "id", "tags", "geometry", "lat", "lon", "members", "center", "nodes", "bounds"}
    enc = _Encoder()
    body = bytearray()
    elements = data.get("elements", [])
    _varint(body, len(elements))
    prev_id = 0
    for e in elements:
        extra = set(e) - known
        if extra:
            raise ValueError("element keys .osmb cannot hold: %s" % sorted(extra))
        _varint(body, enc.s(e["type"]))
        eid = int(e.get("id", 0))
        _svarint(body, eid - prev_id)
        prev_id = eid
        flags = 0
        if e.get("tags"):
            flags |= F_TAGS
        if "geometry" in e:
            flags |= F_GEOM
        if "lat" in e:
            flags |= F_LATLON
        if "members" in e:
            flags |= F_MEMBERS
        if "center" in e:
            flags |= F_CENTER
        _varint(body, flags)
        if flags & F_TAGS:
            _varint(body, len(e["tags"]))
            for k, v in e["tags"].items():
                if not isinstance(v, str):
                    raise ValueError("non-string tag value %r" % (v,))
                _varint(body, enc.s(k))
                _varint(body, enc.s(v))
        if flags & F_LATLON:
            enc.coord(body, e["lat"], e["lon"])
        if flags & F_CENTER:
            enc.coord(body, e["center"]["lat"], e["center"]["lon"], exact=False)
        if flags & F_GEOM:
            enc.points(body, e["geometry"])
        if flags & F_MEMBERS:
            _varint(body, len(e["members"]))
            prev_ref = 0
            for m in e["members"]:
                extra = set(m) - {"type", "ref", "role", "geometry", "lat", "lon"}
                if extra:
                    raise ValueError("member keys .osmb cannot hold: %s" % sorted(extra))
                _varint(body, enc.s(m["type"]))
                ref = int(m.get("ref", 0))
                _svarint(body, ref - prev_ref)
                prev_ref = ref
                _varint(body, enc.s(m.get("role", "")))
                mflags = (M_GEOM if "geometry" in m else 0) | (M_LATLON if "lat" in m else 0)
                _varint(body, mflags)
                if mflags & M_LATLON:
                    enc.coord(body, m["lat"], m["lon"])
                if mflags & M_GEOM:
                    enc.points(body, m["geometry"])
    header = {k: v for k, v in data.items() if k != "elements"}
    head = json.dumps(header, separators=(",", ":"), ensure_ascii=False).encode()
    out = bytearray(MAGIC)
    _varint(out, VERSION)
    _varint(out, len(head))
    out += head
    _varint(out, len(enc.strings))
    for text in enc.strings:  # insertion order is index order
        raw = text.encode()
        _varint(out, len(raw))
        out += raw
    out += body
    return bytes(out)


class _Reader:
    def __init__(self, buf):
        self.b = buf
        self.p = 0
        self.lat = 0
        self.lon = 0

    def varint(self):
        n = shift = 0
        while True:
            byte = self.b[self.p]
            self.p += 1
            n |= (byte & 0x7F) << shift
            if byte < 0x80:
                return n
            shift += 7

    def svarint(self):
        n = self.varint()
        return (n >> 1) ^ -(n & 1)

    def coord(self):
        self.lat += self.svarint()
        self.lon += self.svarint()
        return {"lat": self.lat / SCALE, "lon": self.lon / SCALE}

    def points(self):
        count = self.varint()
        nulls = {self.varint() for _ in range(self.varint())}
        return [None if i in nulls else self.coord() for i in range(count)]


def decode(payload):
    """The Overpass JSON object an .osmb payload holds."""
    r = _Reader(payload)
    if payload[:4] != MAGIC:
        raise ValueError("not an .osmb payload")
    r.p = 4
    if r.varint() != VERSION:
        raise ValueError("unknown .osmb version")
    n = r.varint()
    data = json.loads(payload[r.p:r.p + n].decode())
    r.p += n
    strings = []
    for _ in range(r.varint()):
        n = r.varint()
        strings.append(payload[r.p:r.p + n].decode())
        r.p += n
    elements = []
    eid = 0
    for _ in range(r.varint()):
        e = {"type": strings[r.varint()]}
        eid += r.svarint()
        e["id"] = eid
        flags = r.varint()
        if flags & F_TAGS:
            e["tags"] = {strings[r.varint()]: strings[r.varint()] for _ in range(r.varint())}
        if flags & F_LATLON:
            e.update(r.coord())
        if flags & F_CENTER:
            e["center"] = r.coord()
        if flags & F_GEOM:
            e["geometry"] = r.points()
        if flags & F_MEMBERS:
            members = []
            ref = 0
            for _ in range(r.varint()):
                m = {"type": strings[r.varint()]}
                ref += r.svarint()
                m["ref"] = ref
                m["role"] = strings[r.varint()]
                mflags = r.varint()
                if mflags & M_LATLON:
                    m.update(r.coord())
                if mflags & M_GEOM:
                    m["geometry"] = r.points()
                members.append(m)
            e["members"] = members
        elements.append(e)
    data["elements"] = elements
    return data


def _round(v):
    return round(float(v) * SCALE) / SCALE


def normalised(data):
    """`data` as decode(encode(data)) gives it back: what .osmb keeps."""
    def pts(geom):
        return [None if g is None else {"lat": _round(g["lat"]), "lon": _round(g["lon"])} for g in geom]
    out = {k: v for k, v in data.items() if k != "elements"}
    elements = []
    for e in data.get("elements", []):
        n = {"type": e["type"], "id": int(e.get("id", 0))}
        if e.get("tags"):
            n["tags"] = dict(e["tags"])
        if "lat" in e:
            n["lat"], n["lon"] = _round(e["lat"]), _round(e["lon"])
        if "center" in e:
            n["center"] = {"lat": _round(e["center"]["lat"]), "lon": _round(e["center"]["lon"])}
        if "geometry" in e:
            n["geometry"] = pts(e["geometry"])
        if "members" in e:
            ms = []
            for m in e["members"]:
                mm = {"type": m["type"], "ref": int(m.get("ref", 0)), "role": m.get("role", "")}
                if "lat" in m:
                    mm["lat"], mm["lon"] = _round(m["lat"]), _round(m["lon"])
                if "geometry" in m:
                    mm["geometry"] = pts(m["geometry"])
                ms.append(mm)
            n["members"] = ms
        elements.append(n)
    out["elements"] = elements
    return out


def _zstd(args, data):
    # A missing tool is not a damaged snapshot: callers treat OSError as one.
    if shutil.which("zstd") is None:
        raise RuntimeError("the zstd command is required for .osmb files")
    return subprocess.run(["zstd", "-q", "-c"] + args, input=data, capture_output=True, check=True).stdout


def compress(payload):
    return _zstd(["-%d" % ZSTD_LEVEL], payload)


def decompress(blob):
    return _zstd(["-d"], blob)


def read_json(path):
    with open(path, "rb") as f:
        raw = f.read()
    if raw[:2] == b"\x1f\x8b":
        raw = gzip.decompress(raw)
    return json.loads(raw)


def write_osmb(data, path):
    """Encode, check the round trip, compress and write: (payload size, sha256)."""
    payload = encode(data)
    if decode(payload) != normalised(data):
        raise ValueError("%s: .osmb round trip changed the data" % path)
    blob = compress(payload)
    if decompress(blob) != payload:
        raise ValueError("%s: zstd round trip failed" % path)
    tmp = path + ".tmp"
    with open(tmp, "wb") as f:
        f.write(blob)
    os.replace(tmp, path)
    return len(payload), hashlib.sha256(payload).hexdigest()


def read_osmb(path):
    with open(path, "rb") as f:
        return decode(decompress(f.read()))


ROW = re.compile(r'^(\t"(\w+)": \[)([-\d.]+), ([-\d.]+), "(\w+)", (\d+), "([^"]+)", (\d+), "([0-9a-f]{64})"(\],?)$')


def convert_all(source=SNAPSHOTS):
    """Every bundled snapshot -> .osmb, manifests and BundledOsm.ENTRIES rewritten.

    Reads <key>.json.gz from `source` (e.g. a checkout from before the switch),
    or re-encodes an existing .osmb when there is no JSON for it.
    """
    stats = {"in": 0, "out": 0}

    def convert(key):
        src = os.path.join(source, key + ".json.gz")
        dst = os.path.join(SNAPSHOTS, key + ".osmb")
        if not os.path.exists(src):
            raise FileNotFoundError(src)
        size, sha = write_osmb(read_json(src), dst)
        stats["in"] += os.path.getsize(src)
        stats["out"] += os.path.getsize(dst)
        return size, sha

    for name in MANIFESTS:
        path = os.path.join(SNAPSHOTS, name)
        with open(path) as f:
            manifest = json.load(f)
        for key, row in manifest.items():
            row[5], row[6] = convert(key)
        # Each manifest keeps the layout its own tool writes.
        if name == "horizon_manifest.json":
            text = json.dumps(dict(sorted(manifest.items())), indent=1)
        else:
            text = json.dumps(manifest, indent=2, ensure_ascii=False, sort_keys=True)
        with open(path + ".tmp", "w") as f:
            f.write(text + "\n")
        os.replace(path + ".tmp", path)
        print("%s: %d rows" % (name, len(manifest)))
    with open(BUNDLED_GD) as f:
        lines = f.read().split("\n")
    count = 0
    for i, line in enumerate(lines):
        m = ROW.match(line)
        if not m:
            continue
        size, sha = convert(m.group(2))
        lines[i] = '%s%s, %s, "%s", %s, "%s", %d, "%s"%s' % (
            m.group(1), m.group(3), m.group(4), m.group(5), m.group(6), m.group(7), size, sha, m.group(10))
        count += 1
    with open(BUNDLED_GD + ".tmp", "w") as f:
        f.write("\n".join(lines))
    os.replace(BUNDLED_GD + ".tmp", BUNDLED_GD)
    print("bundled_osm.gd: %d entries" % count)
    if stats["in"]:
        print("%.1f MB gzip JSON -> %.1f MB .osmb" % (stats["in"] / 1e6, stats["out"] / 1e6))


def main(argv):
    if len(argv) >= 4 and argv[1] == "encode":
        size, sha = write_osmb(read_json(argv[2]), argv[3])
        print("payload %d bytes, sha256 %s, file %d bytes" % (size, sha, os.path.getsize(argv[3])))
    elif len(argv) >= 3 and argv[1] == "decode":
        text = json.dumps(read_osmb(argv[2]), ensure_ascii=False)
        if len(argv) > 3:
            with open(argv[3], "w") as f:
                f.write(text)
        else:
            sys.stdout.write(text)
    elif len(argv) in (2, 4) and argv[1] == "convert-all":
        convert_all(argv[3] if len(argv) == 4 and argv[2] == "--from" else SNAPSHOTS)
    else:
        print(__doc__)
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
