#!/usr/bin/env python3
"""Per-building roof parameters from the City of Helsinki's LoD2 model.

The city's 3D viewer (https://kartta.hel.fi/3d/) serves its LoD2 building
model (CC BY 4.0, "© City of Helsinki, 3D city model") as 3D Tiles 1.1:
glTF 2.0 tiles with EXT_mesh_features / EXT_structural_metadata, one
feature per building with its measured height, storeys and VTJ_PRT id.
This tool walks the tileset to its z16 tiles over a GK25 (EPSG:3879)
box, reads each building's triangles and reduces them to what
HelsinkiLod2 (scripts/data/helsinki_lod2.gd) fills into OSM buildings:

  [vtj_prt, e, n, area_m2, height_m, roof_h_m, pitch_deg, ridge_az_deg,
   shape, storeys]

e/n: the roof's centroid in GK25; height: the model's measured height
(ground to the top); roof_h: ridge minus eave (towers and low annexes
skew it: HelsinkiLod2 fills the pitch and lets the footprint set the
rise); ridge_az: compass bearing of the ridge line (0-180), for a
skillion the bearing it slopes down (0-360); shape: flat, skillion, gabled, hipped,
mansard or complex (HelsinkiLod2 fills no shape for complex).

Rows go into 1 km GK25 cells, assets/city_models/helsinki_lod2/<E>_<N>.lod2
(zstd JSON, E and N in km), listed with each payload's size and SHA-256
in manifest.json beside them, as BundledOsm pins its snapshots.

Usage:
  tools/prepare_helsinki_lod2.py [--box E0,N0,E1,N1] [--workers 4]

The default box is central Helsinki (the peninsula to Kallio, Töölö,
Kalasatama and Lauttasaari). Downloaded tiles are kept in
build/lod2_tiles/ so a rerun or a wider box only fetches what is new.
Needs the zstd command. Read-only use of the city's public tile service.
"""

import argparse
import concurrent.futures
import hashlib
import json
import math
import os
import posixpath
import shutil
import struct
import subprocess
import sys
import urllib.error
import urllib.request

BASE = "https://kartta.hel.fi/3d/datasource-data/16fc3fd5-df6d-4f48-bfd5-9aeee430a02f/"
HEADERS = {"User-Agent": "planet-render-360 data tool", "Accept-Encoding": "identity"}
ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
OUT_DIR = os.path.join(ROOT, "assets", "city_models", "helsinki_lod2")
CACHE_DIR = os.path.join(ROOT, "build", "lod2_tiles")
DEFAULT_BOX = (25492000, 6668000, 25500000, 6676000)
LEAF_ZOOM = 16
CELL_M = 1000
ZSTD_LEVEL = 19

# Roof classification (degrees / area shares).
ROOF_MIN_UP = math.cos(math.radians(75.0))   # steeper than 75 degrees is wall
FLAT_DEG = 5.0
FLAT_SHARE = 0.7                              # this much flat roof: flat
BIN_SHARE = 0.15                              # a slope direction counts from here
MANSARD_SPLIT_DEG = 20.0


# --- GK25 (mirrors scripts/data/gk25.gd) -------------------------------------

_A = 6378137.0
_F = 1.0 / 298.257222101


def gk25(lat, lon):
    n = _F / (2.0 - _F)
    n2, n3 = n * n, n * n * n
    big_a = _A / (1.0 + n) * (1.0 + n2 / 4.0 + n2 * n2 / 64.0)
    alpha = [n / 2.0 - 2.0 * n2 / 3.0 + 5.0 * n3 / 16.0,
             13.0 * n2 / 48.0 - 3.0 * n3 / 5.0, 61.0 * n3 / 240.0]
    phi = math.radians(lat)
    dl = math.radians(lon - 25.0)
    c = 2.0 * math.sqrt(n) / (1.0 + n)
    t = math.sinh(math.atanh(math.sin(phi)) - c * math.atanh(c * math.sin(phi)))
    xi = math.atan2(t, math.cos(dl))
    eta = math.atanh(math.sin(dl) / math.sqrt(1.0 + t * t))
    e, nn = eta, xi
    for j in range(3):
        k = 2.0 * (j + 1)
        e += alpha[j] * math.cos(k * xi) * math.sinh(k * eta)
        nn += alpha[j] * math.sin(k * xi) * math.cosh(k * eta)
    return 25500000.0 + big_a * e, big_a * nn


def gk25_inverse(e, n):
    lat = 60.17 + (n - 6673000.0) / 111400.0
    lon = 25.0 + (e - 25500000.0) / (111320.0 * math.cos(math.radians(lat)))
    for _ in range(5):
        p = gk25(lat, lon)
        d = 1e-6
        pl, po = gk25(lat + d, lon), gk25(lat, lon + d)
        a, b = (pl[0] - p[0]) / d, (po[0] - p[0]) / d
        c, dd = (pl[1] - p[1]) / d, (po[1] - p[1]) / d
        det = a * dd - b * c
        re, rn = e - p[0], n - p[1]
        lat += (dd * re - b * rn) / det
        lon += (-c * re + a * rn) / det
    return lat, lon


def ecef_to_lla(x, y, z):
    a, f = 6378137.0, 1.0 / 298.257223563
    e2 = f * (2.0 - f)
    lon = math.atan2(y, x)
    p = math.hypot(x, y)
    lat = math.atan2(z, p * (1.0 - e2))
    h = 0.0
    for _ in range(6):
        nn = a / math.sqrt(1.0 - e2 * math.sin(lat) ** 2)
        h = p / math.cos(lat) - nn
        lat = math.atan2(z, p * (1.0 - e2 * nn / (nn + h)))
    return math.degrees(lat), math.degrees(lon), h


def enu_basis(lat, lon):
    la, lo = math.radians(lat), math.radians(lon)
    east = (-math.sin(lo), math.cos(lo), 0.0)
    north = (-math.sin(la) * math.cos(lo), -math.sin(la) * math.sin(lo), math.cos(la))
    up = (math.cos(la) * math.cos(lo), math.cos(la) * math.sin(lo), math.sin(la))
    return east, north, up


def dot(a, b):
    return a[0] * b[0] + a[1] * b[1] + a[2] * b[2]


# --- Fetching ----------------------------------------------------------------

def fetch(path, cache=True):
    local = os.path.join(CACHE_DIR, path)
    if cache and os.path.exists(local):
        with open(local, "rb") as f:
            return f.read()
    try:
        with urllib.request.urlopen(urllib.request.Request(BASE + path, headers=HEADERS), timeout=120) as r:
            data = r.read()
    except urllib.error.HTTPError as err:
        if err.code == 404:
            return None
        raise
    if cache:
        os.makedirs(os.path.dirname(local), exist_ok=True)
        with open(local + ".part", "wb") as f:
            f.write(data)
        os.replace(local + ".part", local)
    return data


def leaf_tiles(box):
    """{glb path: ECEF translation} of the leaf tiles whose region meets box."""
    corners = [gk25_inverse(e, n) for e in (box[0], box[2]) for n in (box[1], box[3])]
    lat_lo = math.radians(min(c[0] for c in corners))
    lat_hi = math.radians(max(c[0] for c in corners))
    lon_lo = math.radians(min(c[1] for c in corners))
    lon_hi = math.radians(max(c[1] for c in corners))
    found = {}

    def walk(tile, base, t):
        tr = tile.get("transform")
        if tr:
            if tr[:12] != [1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0]:
                raise ValueError("unexpected rotation in a tile transform")
            t = (t[0] + tr[12], t[1] + tr[13], t[2] + tr[14])
        w, s, e, n = tile["boundingVolume"]["region"][:4]
        if e < lon_lo or w > lon_hi or n < lat_lo or s > lat_hi:
            return
        uri = tile.get("content", {}).get("uri")
        if uri:
            p = posixpath.normpath(posixpath.join(posixpath.dirname(base), uri))
            if p.endswith(".json"):
                sub = fetch(p)
                if sub:
                    walk(json.loads(sub)["root"], p, t)
            elif p.startswith("%d/" % LEAF_ZOOM):
                found[p] = t
        for child in tile.get("children", []):
            walk(child, base, t)

    walk(json.loads(fetch("tileset.json", cache=False))["root"], "tileset.json", (0.0, 0.0, 0.0))
    return found


# --- glTF ----------------------------------------------------------------------

def _view(gltf, binary, index):
    bv = gltf["bufferViews"][index]
    start = bv.get("byteOffset", 0)
    return binary[start:start + bv["byteLength"]]


_OFFSET_CODES = {"UINT8": "B", "UINT16": "H", "UINT32": "I", "UINT64": "Q"}


def _strings(gltf, binary, values, offsets, count, offset_type="UINT32"):
    data = _view(gltf, binary, values)
    code = _OFFSET_CODES.get(offset_type, "I")
    offs = struct.unpack_from("<%d%s" % (count + 1, code), _view(gltf, binary, offsets))
    return [data[offs[i]:offs[i + 1]].decode("utf-8", "replace") for i in range(count)]


_SCALARS = {"FLOAT64": "d", "FLOAT32": "f", "INT32": "i", "UINT32": "I", "INT64": "q",
            "UINT64": "Q", "INT16": "h", "UINT16": "H", "INT8": "b", "UINT8": "B"}


def property_table(gltf, binary):
    ext = gltf["extensions"]["EXT_structural_metadata"]
    table = ext["propertyTables"][0]
    schema = ext["schema"]["classes"][table["class"]]["properties"]
    count = table["count"]
    out = {}
    for name, prop in table["properties"].items():
        kind = schema.get(name, {})
        if kind.get("type", "STRING") == "STRING" or "stringOffsets" in prop:
            out[name] = _strings(gltf, binary, prop["values"], prop["stringOffsets"], count,
                                 prop.get("stringOffsetType", "UINT32"))
        else:
            code = _SCALARS.get(kind.get("componentType", "FLOAT64"), "d")
            out[name] = list(struct.unpack_from("<%d%s" % (count, code), _view(gltf, binary, prop["values"])))
    return out, count


def read_glb(data):
    if data[:4] != b"glTF":
        raise ValueError("not a glb")
    json_len, = struct.unpack_from("<I", data, 12)
    gltf = json.loads(data[20:20 + json_len])
    bin_len, = struct.unpack_from("<I", data, 20 + json_len)
    binary = data[28 + json_len:28 + json_len + bin_len]
    return gltf, binary


_COMPONENTS = {5120: ("b", 1), 5121: ("B", 1), 5122: ("h", 2), 5123: ("H", 2), 5125: ("I", 4), 5126: ("f", 4)}
_IDENTITY = [1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0]


def _read_accessor(gltf, binary, acc, width):
    """The accessor's values as tuples of `width` (floats, de-normalised)."""
    if acc.get("sparse") or any(k in gltf.get("extensionsUsed", []) for k in
                                ("KHR_mesh_quantization", "EXT_meshopt_compression", "KHR_draco_mesh_compression")):
        raise ValueError("compressed or quantised glTF is not supported")
    code, size = _COMPONENTS[acc["componentType"]]
    bv = gltf["bufferViews"][acc["bufferView"]]
    base = bv.get("byteOffset", 0) + acc.get("byteOffset", 0)
    stride = bv.get("byteStride", 0) or size * width
    scale = {"b": 127.0, "B": 255.0, "h": 32767.0, "H": 65535.0}.get(code, 1.0) if acc.get("normalized") else 1.0
    fmt = "<%d%s" % (width, code)
    return [tuple(v / scale for v in struct.unpack_from(fmt, binary, base + i * stride)) for i in range(acc["count"])]


def triangles(gltf, binary):
    """Yields (feature, p0, p1, p2) per triangle, positions in glTF axes."""
    for node in gltf.get("nodes", []):
        if node.get("translation", [0.0, 0.0, 0.0]) != [0.0, 0.0, 0.0] \
                or node.get("rotation", [0.0, 0.0, 0.0, 1.0]) != [0.0, 0.0, 0.0, 1.0] \
                or node.get("scale", [1.0, 1.0, 1.0]) != [1.0, 1.0, 1.0] \
                or node.get("matrix", _IDENTITY) != _IDENTITY:
            raise ValueError("a node transform in the tile: not supported")
    if "EXT_mesh_gpu_instancing" in gltf.get("extensionsUsed", []):
        raise ValueError("instanced meshes are not supported")
    used = {node["mesh"] for node in gltf.get("nodes", []) if "mesh" in node}
    for index, mesh in enumerate(gltf["meshes"]):
        if index not in used:
            continue
        for prim in mesh["primitives"]:
            if prim.get("mode", 4) != 4:
                raise ValueError("only triangle-list primitives are supported")
            attrs = prim["attributes"]
            pos_acc = gltf["accessors"][attrs["POSITION"]]
            count = pos_acc["count"]
            pos = _read_accessor(gltf, binary, pos_acc, 3)
            fid = [int(round(v[0])) for v in _read_accessor(gltf, binary, gltf["accessors"][attrs["_FEATURE_ID_0"]], 1)]
            if "indices" in prim:
                acc = gltf["accessors"][prim["indices"]]
                code = {5121: "B", 5123: "H", 5125: "I"}[acc["componentType"]]
                bv = gltf["bufferViews"][acc["bufferView"]]
                idx = struct.unpack_from("<%d%s" % (acc["count"], code), binary,
                                         bv.get("byteOffset", 0) + acc.get("byteOffset", 0))
            else:
                idx = range(count)
            for k in range(0, len(idx) - 2, 3):
                a, b, c = idx[k], idx[k + 1], idx[k + 2]
                yield fid[a], pos[a], pos[b], pos[c]


# --- Roof analysis -------------------------------------------------------------

def analyse(data, translation):
    gltf, binary = read_glb(data)
    props, count = property_table(gltf, binary)
    # Local ENU at the tile's origin: glTF (x, y, z) is ECEF (x, -z, y)
    # offset from the accumulated tile translation.
    lat0, lon0, _ = ecef_to_lla(*translation)
    east, north, up = enu_basis(lat0, lon0)
    feats = {}
    for f, a, b, c in triangles(gltf, binary):
        pts = []
        for p in (a, b, c):
            q = (p[0], -p[2], p[1])
            pts.append((dot(q, east), dot(q, north), dot(q, up)))
        u = (pts[1][0] - pts[0][0], pts[1][1] - pts[0][1], pts[1][2] - pts[0][2])
        v = (pts[2][0] - pts[0][0], pts[2][1] - pts[0][1], pts[2][2] - pts[0][2])
        nx = u[1] * v[2] - u[2] * v[1]
        ny = u[2] * v[0] - u[0] * v[2]
        nz = u[0] * v[1] - u[1] * v[0]
        ln = math.sqrt(nx * nx + ny * ny + nz * nz)
        rec = feats.setdefault(f, {"zmin": 1e9, "zmax": -1e9, "roof": [], "eave": 1e9})
        for p in pts:
            rec["zmin"] = min(rec["zmin"], p[2])
            rec["zmax"] = max(rec["zmax"], p[2])
        if ln < 1e-9:
            continue
        nx, ny, nz = nx / ln, ny / ln, nz / ln
        if nz < ROOF_MIN_UP:
            continue
        area = ln * 0.5
        cx = (pts[0][0] + pts[1][0] + pts[2][0]) / 3.0
        cy = (pts[0][1] + pts[1][1] + pts[2][1]) / 3.0
        pitch = math.degrees(math.acos(max(-1.0, min(1.0, nz))))
        # Bearing the facet faces (slopes down toward).
        aspect = math.degrees(math.atan2(nx, ny)) % 360.0
        rec["roof"].append((area, pitch, aspect, cx, cy, min(p[2] for p in pts)))
    rows = []
    for f, rec in feats.items():
        if f < 0 or f >= count or not rec["roof"]:
            continue
        row = summarise(rec, props, f, translation, east, north, up)
        if row:
            rows.append(row)
    return rows


def classify_roof(roof, top):
    """(shape, pitch_deg, ridge_az_deg, roof_h_m) of a building's roof facets
    [(area, pitch_deg, aspect_deg, x, y, z_min)] (aspect: compass bearing the
    facet faces) whose highest point is `top`. Shared with
    prepare_espoo_lod2.py so both cities' roofs reduce alike."""
    sloped = [r for r in roof if r[1] >= FLAT_DEG]
    total = sum(r[0] for r in roof)
    sloped_area = sum(r[0] for r in sloped)
    shape, pitch, ridge_az, roof_h = "flat", 0.0, 0.0, 0.0
    if sloped_area > (1.0 - FLAT_SHARE) * total:
        # Axial mean of the slope directions: the gable axis.
        s2 = sum(r[0] * math.sin(math.radians(2.0 * r[2])) for r in sloped)
        c2 = sum(r[0] * math.cos(math.radians(2.0 * r[2])) for r in sloped)
        axis = math.degrees(math.atan2(s2, c2)) / 2.0
        bins = [0.0, 0.0, 0.0, 0.0]
        for a, _, aspect, *_ in sloped:
            rel = (aspect - axis + 45.0) % 360.0
            bins[int(rel // 90.0) % 4] += a
        used = [i for i in range(4) if bins[i] >= BIN_SHARE * sloped_area]
        pitch = sum(r[0] * r[1] for r in sloped) / sloped_area
        eave = min(r[5] for r in sloped)
        roof_h = max(0.0, top - eave)
        flat_share = 1.0 - sloped_area / total
        if flat_share > 0.35:
            shape = "complex"
        elif len(used) == 1:
            shape = "skillion"
            # A one-sided roof keeps which way it falls: the bearing it
            # slopes down (0-360) instead of the ridge's.
            ridge_az = (axis + 90.0 * used[0]) % 360.0
        elif len(used) == 2 and abs(used[0] - used[1]) == 2:
            shape = "gabled"
            ridge_az = (axis + 90.0) % 180.0
        elif len(used) >= 3:
            steep = [r for r in sloped if r[1] >= pitch + MANSARD_SPLIT_DEG / 2.0]
            low = [r for r in sloped if r[1] <= pitch - MANSARD_SPLIT_DEG / 2.0]
            mansard = sum(r[0] for r in steep) > 0.25 * sloped_area and sum(r[0] for r in low) > 0.25 * sloped_area
            shape = "mansard" if mansard else "hipped"
            ridge_az = (axis + 90.0) % 180.0
        else:
            shape = "complex"
    return shape, pitch, ridge_az, roof_h


def summarise(rec, props, f, translation, east, north, up):
    roof = rec["roof"]
    plan = sum(a * math.cos(math.radians(p)) for a, p, *_ in roof)
    if plan < 4.0:
        return None
    cx = sum(a * x for a, _, _, x, _, _ in roof) / sum(a for a, *_ in roof)
    cy = sum(a * y for a, _, _, _, y, _ in roof) / sum(a for a, *_ in roof)
    ground = rec["zmin"]
    top = rec["zmax"]
    height = props.get("height", [0.0] * (f + 1))[f]
    height = float(height) if isinstance(height, (int, float)) and height > 0.5 else top - ground
    storeys = props.get("storeysAboveGround", [0] * (f + 1))[f]
    storeys = int(storeys) if isinstance(storeys, (int, float)) and 0 < storeys < 200 else 0
    shape, pitch, ridge_az, roof_h = classify_roof(roof, top)
    # Centroid to GK25.
    ex = translation[0] + east[0] * cx + north[0] * cy
    ey = translation[1] + east[1] * cx + north[1] * cy
    ez = translation[2] + east[2] * cx + north[2] * cy
    lat, lon, _ = ecef_to_lla(ex, ey, ez)
    e, n = gk25(lat, lon)
    vtj = props.get("VTJ_PRT", [""] * (f + 1))[f] or ""
    return [vtj, round(e, 1), round(n, 1), round(plan, 1), round(height, 2), round(roof_h, 2),
            round(pitch, 1), round(ridge_az, 1), shape, storeys]


# --- Output --------------------------------------------------------------------

def zstd(payload):
    if shutil.which("zstd") is None:
        raise RuntimeError("the zstd command is required")
    return subprocess.run(["zstd", "-q", "-c", "-%d" % ZSTD_LEVEL], input=payload,
                          capture_output=True, check=True).stdout


def write_cells(rows, box):
    os.makedirs(OUT_DIR, exist_ok=True)
    manifest_path = os.path.join(OUT_DIR, "manifest.json")
    manifest = {}
    if os.path.exists(manifest_path):
        with open(manifest_path) as f:
            manifest = json.load(f).get("cells", {})
    cells = {}
    for row in rows:
        e, n = row[1], row[2]
        if not (box[0] <= e < box[2] and box[1] <= n < box[3]):
            continue
        key = "%d_%d" % (int(e // CELL_M), int(n // CELL_M))
        cells.setdefault(key, []).append(row)
    for key, cell_rows in sorted(cells.items()):
        cell_rows.sort(key=lambda r: (r[2], r[1]))
        payload = json.dumps({"rows": cell_rows}, separators=(",", ":"), ensure_ascii=False).encode("utf-8")
        with open(os.path.join(OUT_DIR, key + ".lod2"), "wb") as f:
            f.write(zstd(payload))
        manifest[key] = [len(payload), hashlib.sha256(payload).hexdigest(), len(cell_rows)]
    with open(manifest_path, "w") as f:
        json.dump({"source": BASE, "licence": "CC BY 4.0, © City of Helsinki, 3D city model",
                   "columns": ["vtj_prt", "e", "n", "area_m2", "height_m", "roof_h_m", "pitch_deg",
                               "ridge_az_deg", "shape", "storeys"],
                   "cell_m": CELL_M, "cells": dict(sorted(manifest.items()))}, f, indent=1)
    return cells


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--box", default=",".join(str(v) for v in DEFAULT_BOX),
                    help="GK25 E0,N0,E1,N1 in metres (whole km)")
    ap.add_argument("--workers", type=int, default=4)
    args = ap.parse_args()
    box = tuple(int(v) for v in args.box.split(","))
    if len(box) != 4 or box[0] >= box[2] or box[1] >= box[3]:
        sys.exit("--box needs E0,N0,E1,N1")
    if any(v % CELL_M for v in box):
        sys.exit("--box must be whole km (cells are rewritten whole)")
    tiles = leaf_tiles(box)
    print("%d z%d tiles meet the box" % (len(tiles), LEAF_ZOOM))
    rows = []
    done = 0

    def work(item):
        path, translation = item
        data = fetch(path)
        return analyse(data, translation) if data else []

    with concurrent.futures.ThreadPoolExecutor(max_workers=max(1, args.workers)) as pool:
        for tile_rows in pool.map(work, sorted(tiles.items())):
            rows.extend(tile_rows)
            done += 1
            if done % 50 == 0:
                print("  %d / %d tiles, %d buildings" % (done, len(tiles), len(rows)))
    cells = write_cells(rows, box)
    shapes = {}
    for r in rows:
        shapes[r[8]] = shapes.get(r[8], 0) + 1
    print("%d buildings in %d cells; shapes %s" % (sum(len(c) for c in cells.values()), len(cells), shapes))


if __name__ == "__main__":
    main()
