#!/usr/bin/env python3
"""Binary v2 encoder/codec for compact .lod2m (PackedInt32Array zstd) cells.

Layout (little-endian int32 stream):
  Header (3 int32s):
    [0] MAGIC = 0x324D444C ("LDM2")
    [1] VERSION = 2
    [2] building_count

  Per building (14 int32s fixed header + geometry arrays):
    [0]  e_dm         GK23/GK25 Easting in decimetres (round(e * 10))
    [1]  n_dm         GK23/GK25 Northing in decimetres (round(n * 10))
    [2]  area_dm2     plan area in 0.1 m^2 (round(area * 10))
    [3]  h_cm         height in cm (round(h * 100))
    [4]  storeys      storey count (>= 1)
    [5]  start_year   completion year (0 if unknown)
    [6]  roof_mat_id  0=none, 1=metal, 2=terracotta, 3=copper, 4=bitumen
    [7]  roof_rgb     0x00RRGGBB (0 if unsampled)
    [8]  wall_mat_id  0=none, 1=render, 2=brick, 3=concrete, 4=wood, 5=stone, 6=glass
    [9]  wall_rgb     0x00RRGGBB (0 if unsampled)
    [10] n_wall_verts wall vertex count (wv = 3*n, wu = 2*n)
    [11] n_wall_idx   wall index count (wi = n)
    [12] n_roof_verts roof vertex count (rv = 3*n, ru = 2*n)
    [13] n_roof_idx   roof index count (ri = n)
    followed by: wv, wu, wi, rv, ru, ri (all int32).
"""

import array
import hashlib
import json
import os
import shutil
import subprocess

MAGIC = 0x324D444C
VERSION = 2
ZSTD_LEVEL = 19

ROOF_MAT_IDS = {"": 0, "metal": 1, "terracotta": 2, "copper": 3, "bitumen": 4}
WALL_MAT_IDS = {"": 0, "render": 1, "brick": 2, "concrete": 3, "wood": 4, "stone": 5, "glass": 6}


def parse_hex_rgb(h):
    if not h or not isinstance(h, str):
        return 0
    s = h.lstrip("#")
    if len(s) != 6:
        return 0
    try:
        return int(s, 16)
    except ValueError:
        return 0


def pack_cell(recs):
    """Pack a list of building dicts into little-endian int32 bytes."""
    buf = array.array("i")
    buf.append(MAGIC)
    buf.append(VERSION)
    buf.append(len(recs))
    for r in recs:
        wv = r["wv"]
        wu = r["wu"]
        wi = r["wi"]
        rv = r["rv"]
        ru = r["ru"]
        ri = r["ri"]
        nwv = len(wv) // 3
        nwi = len(wi)
        nrv = len(rv) // 3
        nri = len(ri)
        buf.extend((
            int(round(r["e"] * 10.0)),
            int(round(r["n"] * 10.0)),
            int(round(r["area"] * 10.0)),
            int(round(r["h"] * 100.0)),
            int(r.get("st", 1)),
            int(r.get("yr", 0)),
            ROOF_MAT_IDS.get(r.get("rm", ""), 0),
            parse_hex_rgb(r.get("rc", "")),
            WALL_MAT_IDS.get(r.get("wm", ""), 0),
            parse_hex_rgb(r.get("wc", "")),
            nwv,
            nwi,
            nrv,
            nri,
        ))
        buf.extend(wv)
        buf.extend(wu)
        buf.extend(wi)
        buf.extend(rv)
        buf.extend(ru)
        buf.extend(ri)
    return buf.tobytes()


def zstd_compress(payload):
    if shutil.which("zstd") is None:
        raise RuntimeError("zstd CLI is required")
    return subprocess.run(
        ["zstd", "-q", "-c", f"-{ZSTD_LEVEL}"],
        input=payload, capture_output=True, check=True,
    ).stdout


def write_bundle(out_dir, cells, meta):
    """Write zstd-compressed binary .lod2m cells + manifest.json."""
    os.makedirs(out_dir, exist_ok=True)
    # Remove any stale .lod2m cells not in this build
    for fn in os.listdir(out_dir):
        if fn.endswith(".lod2m"):
            ck = fn[:-6]
            if ck not in cells:
                os.remove(os.path.join(out_dir, fn))
    manifest_cells = {}
    total_raw = total_comp = total_bldgs = total_tris = 0
    for ck, recs in sorted(cells.items()):
        recs.sort(key=lambda r: (r["n"], r["e"]))
        payload = pack_cell(recs)
        comp = zstd_compress(payload)
        with open(os.path.join(out_dir, ck + ".lod2m"), "wb") as f:
            f.write(comp)
        manifest_cells[ck] = [len(payload), hashlib.sha256(payload).hexdigest(), len(recs)]
        total_raw += len(payload)
        total_comp += len(comp)
        total_bldgs += len(recs)
        for r in recs:
            total_tris += (len(r["wi"]) + len(r["ri"])) // 3
    manifest = dict(meta)
    manifest["format"] = "ldm2_int32"
    manifest["cells"] = manifest_cells
    with open(os.path.join(out_dir, "manifest.json"), "w") as f:
        json.dump(manifest, f, indent=1)
    return total_bldgs, total_tris, total_raw, total_comp
