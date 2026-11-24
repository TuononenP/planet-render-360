#!/usr/bin/env python3
"""Compile true 3D glTF LoD2 building meshes for ALL of Helsinki into compact
binary v2 .lod2m (PackedInt32Array zstd) 1 km GK25 cells under
assets/city_models/helsinki_lod2_meshes/.

Reads the already-cached 3D Tiles 1.1 z16 .glb tiles in build/lod2_tiles/,
splits each building's triangles into walls vs roofs, computes true-metre UVs,
merges HSY Ortoilmakuva 2023 roof colours + Mapillary wall colours, and writes
1 km GK25 binary v2 cells.
"""

import concurrent.futures
import json
import math
import os
import posixpath
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lod2m_codec import write_bundle  # noqa: E402
from prepare_helsinki_lod2 import (  # noqa: E402
    CACHE_DIR, ROOF_MIN_UP, dot, ecef_to_lla, enu_basis, fetch, gk25, property_table,
    read_glb, triangles,
)

ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
OUT_DIR = os.path.join(ROOT, "assets", "city_models", "helsinki_lod2_meshes")
ROOFS_PATH = os.path.join(ROOT, "build", "capital_roofs.json")
FACADES_PATH = os.path.join(ROOT, "build", "capital_facades.json")
CELL_M = 1000


def cached_leaf_tiles():
    """Walk cached tileset JSONs in build/lod2_tiles/ to map each local .glb to its ECEF translation."""
    # Start from all cached top-level JSONs in build/lod2_tiles/9/
    found = {}

    def walk(tile, base, t):
        tr = tile.get("transform")
        if tr:
            t = (t[0] + tr[12], t[1] + tr[13], t[2] + tr[14])
        uri = tile.get("content", {}).get("uri")
        if uri:
            p = posixpath.normpath(posixpath.join(posixpath.dirname(base), uri))
            local = os.path.join(CACHE_DIR, p)
            if p.endswith(".json") and os.path.exists(local):
                try:
                    walk(json.load(open(local))["root"], p, t)
                except Exception:  # noqa: BLE001
                    pass
            elif p.endswith(".glb") and os.path.exists(local):
                found[p] = t
        for child in tile.get("children", []):
            walk(child, base, t)

    ts_path = os.path.join(CACHE_DIR, "tileset.json")
    if not os.path.exists(ts_path):
        raw_ts = fetch("tileset.json", cache=True)
        if not raw_ts:
            raise RuntimeError("Could not fetch Helsinki tileset.json for root ECEF transforms")
    walk(json.load(open(ts_path))["root"], "tileset.json", (0.0, 0.0, 0.0))
    return list(found.items())


def parse_glb_tile(item):
    rel_path, tr = item
    local = os.path.join(CACHE_DIR, rel_path)
    try:
        data = open(local, "rb").read()
        gltf, binary = read_glb(data)
        props, count = property_table(gltf, binary)
    except Exception:  # noqa: BLE001
        return []

    lat0, lon0, _ = ecef_to_lla(*tr)
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
        if ln < 1e-5:
            continue
        nx, ny, nz = nx / ln, ny / ln, nz / ln
        area = ln * 0.5
        if area < 0.04:
            continue
        rec = feats.setdefault(f, {"zmin": 1e9, "zmax": -1e9, "walls": [], "roofs": [], "plan": 0.0, "cx": 0.0, "cy": 0.0, "w": 0.0})
        for p in pts:
            rec["zmin"] = min(rec["zmin"], p[2])
            rec["zmax"] = max(rec["zmax"], p[2])
        if nz >= ROOF_MIN_UP:
            rec["roofs"].append((pts, (nx, ny, nz)))
            ap = area * nz
            rec["plan"] += ap
            rec["cx"] += ap * (pts[0][0] + pts[1][0] + pts[2][0]) / 3.0
            rec["cy"] += ap * (pts[0][1] + pts[1][1] + pts[2][1]) / 3.0
            rec["w"] += ap
        elif nz > -0.5:
            rec["walls"].append((pts, (nx, ny, nz)))

    vtj_col = props.get("VTJ_PRT") or props.get("vtj_prt") or []
    h_col = props.get("measuredHeight") or props.get("height") or []
    st_col = props.get("storeysAboveGround") or props.get("storeys") or []
    yr_col = props.get("yearOfConstruction") or []

    out = []
    for f, rec in feats.items():
        if f < 0 or f >= count or rec["plan"] < 12.0 or not rec["walls"] or not rec["roofs"] or rec["w"] <= 0.0:
            continue
        ce_l = rec["cx"] / rec["w"]
        cn_l = rec["cy"] / rec["w"]
        z0 = rec["zmin"]
        h = max(0.0, rec["zmax"] - z0)
        if f < len(h_col) and h_col[f] and float(h_col[f]) > 0.5:
            h = max(h, float(h_col[f]))
        if h < 2.2:
            continue
        # Convert tile-local ENU centroid back to ECEF -> LLA -> GK25
        ex = tr[0] + ce_l * east[0] + cn_l * north[0] + z0 * up[0]
        ey = tr[1] + ce_l * east[1] + cn_l * north[1] + z0 * up[1]
        ez = tr[2] + ce_l * east[2] + cn_l * north[2] + z0 * up[2]
        lat, lon, _ = ecef_to_lla(ex, ey, ez)
        ge, gn = gk25(lat, lon)
        if not (25480000.0 <= ge <= 25525000.0 and 6660000.0 <= gn <= 6695000.0):
            continue

        wv, wu, wi = [], [], []
        rv, ru, ri = [], [], []

        for pts, (nx, ny, nz) in rec["walls"]:
            # Godot local: x = E - ce_l, y = Z - z0, z = -(N - cn_l); normal = (nx, nz, -ny)
            gnx, gny, gnz = nx, nz, -ny
            gpts = [(p[0] - ce_l, p[2] - z0, -(p[1] - cn_l)) for p in pts]
            tx, tz = gnz, -gnx
            tl = math.hypot(tx, tz)
            if tl < 1e-5:
                tx, tz = 1.0, 0.0
            else:
                tx, tz = tx / tl, tz / tl
            p0 = gpts[0]
            us = [(p[0] - p0[0]) * tx + (p[2] - p0[2]) * tz for p in gpts]
            u0 = min(us)
            ymax = max(p[1] for p in gpts)
            base = len(wv) // 3
            for k in range(3):
                wv.extend((int(round(gpts[k][0] * 100.0)), int(round(gpts[k][1] * 100.0)), int(round(gpts[k][2] * 100.0))))
                wu.extend((int(round((us[k] - u0) * 100.0)), int(round((ymax - gpts[k][1]) * 100.0))))
            # Orient CW for Godot front-face matching outward normal
            ab = (gpts[1][0] - gpts[0][0], gpts[1][1] - gpts[0][1], gpts[1][2] - gpts[0][2])
            ac = (gpts[2][0] - gpts[0][0], gpts[2][1] - gpts[0][1], gpts[2][2] - gpts[0][2])
            cx = ab[1] * ac[2] - ab[2] * ac[1]
            cy = ab[2] * ac[0] - ab[0] * ac[2]
            cz = ab[0] * ac[1] - ab[1] * ac[0]
            if cx * gnx + cy * gny + cz * gnz > 0.0:
                wi.extend((base, base + 2, base + 1))
            else:
                wi.extend((base, base + 1, base + 2))

        for pts, (nx, ny, nz) in rec["roofs"]:
            gnx, gny, gnz = nx, nz, -ny
            if gny < 0.0:
                gnx, gny, gnz = -gnx, -gny, -gnz
            gpts = [(p[0] - ce_l, p[2] - z0, -(p[1] - cn_l)) for p in pts]
            tx, tz = gnz, -gnx
            tl = math.hypot(tx, tz)
            if tl < 1e-4:
                tx, ty, tz = 1.0, 0.0, 0.0
                bx, by, bz = 0.0, 0.0, -1.0
            else:
                tx, ty, tz = tx / tl, 0.0, tz / tl
                bx = gny * tz - gnz * ty
                by = gnz * tx - gnx * tz
                bz = gnx * ty - gny * tx
            p0 = gpts[0]
            us = [(p[0] - p0[0]) * tx + (p[1] - p0[1]) * ty + (p[2] - p0[2]) * tz for p in gpts]
            vs = [(p[0] - p0[0]) * bx + (p[1] - p0[1]) * by + (p[2] - p0[2]) * bz for p in gpts]
            u0, v0 = min(us), min(vs)
            base = len(rv) // 3
            for k in range(3):
                rv.extend((int(round(gpts[k][0] * 100.0)), int(round(gpts[k][1] * 100.0)), int(round(gpts[k][2] * 100.0))))
                ru.extend((int(round((us[k] - u0) * 100.0)), int(round((vs[k] - v0) * 100.0))))
            ab = (gpts[1][0] - gpts[0][0], gpts[1][1] - gpts[0][1], gpts[1][2] - gpts[0][2])
            ac = (gpts[2][0] - gpts[0][0], gpts[2][1] - gpts[0][1], gpts[2][2] - gpts[0][2])
            cx = ab[1] * ac[2] - ab[2] * ac[1]
            cy = ab[2] * ac[0] - ab[0] * ac[2]
            cz = ab[0] * ac[1] - ab[1] * ac[0]
            if cx * gnx + cy * gny + cz * gnz > 0.0:
                ri.extend((base, base + 2, base + 1))
            else:
                ri.extend((base, base + 1, base + 2))

        if not wi or not ri:
            continue
        vtj = str(vtj_col[f]).strip() if f < len(vtj_col) and vtj_col[f] else ""
        st = int(st_col[f]) if f < len(st_col) and st_col[f] and str(st_col[f]).isdigit() else 0
        if st <= 0 or st >= 200:
            st = max(1, int(round(h / 3.3)))
        yr = 0
        if f < len(yr_col) and yr_col[f]:
            sy = str(yr_col[f]).strip()[:4]
            if sy.isdigit() and 1700 <= int(sy) <= 2100:
                yr = int(sy)
        out.append({
            "vtj": vtj,
            "e": round(ge, 1),
            "n": round(gn, 1),
            "area": round(rec["plan"], 1),
            "h": round(h, 2),
            "st": st,
            "yr": yr,
            "wv": wv, "wu": wu, "wi": wi,
            "rv": rv, "ru": ru, "ri": ri,
        })
    return out


def main():
    roofs = json.load(open(ROOFS_PATH)) if os.path.exists(ROOFS_PATH) else {}
    facades = json.load(open(FACADES_PATH)) if os.path.exists(FACADES_PATH) else {}
    r_vtj, r_en = roofs.get("by_vtj", {}), roofs.get("by_en", {})
    f_vtj, f_en = facades.get("by_vtj", {}), facades.get("by_en", {})

    tiles = cached_leaf_tiles()
    print(f"Parsing {len(tiles):,} cached Helsinki z16 glTF tiles in parallel...")
    all_recs = []
    with concurrent.futures.ProcessPoolExecutor() as ex:
        for batch in ex.map(parse_glb_tile, tiles, chunksize=16):
            all_recs.extend(batch)

    # Deduplicate by (vtj or rounded e,n) keeping largest plan area
    dedup = {}
    for rec in all_recs:
        k = rec["vtj"] if rec["vtj"] else f"{int(round(rec['e']))},{int(round(rec['n']))}"
        cur = dedup.get(k)
        if cur is None or rec["area"] > cur["area"]:
            dedup[k] = rec

    cells = {}
    with_roof = with_wall = 0
    for rec in dedup.values():
        vtj = rec.pop("vtj", "")
        ek = f"{int(round(rec['e']))},{int(round(rec['n']))}"
        rf = r_vtj.get(vtj) if vtj else None
        if rf is None:
            rf = r_en.get(ek)
        if rf:
            rec["rm"], rec["rc"] = rf[0], rf[1]
            with_roof += 1
        fc = f_vtj.get(vtj) if vtj else None
        if fc is None:
            fc = f_en.get(ek)
        if fc:
            rec["wm"], rec["wc"] = fc[0], fc[1]
            with_wall += 1
        ck = f"{int(rec['e'] // CELL_M)}_{int(rec['n'] // CELL_M)}"
        cells.setdefault(ck, []).append(rec)

    meta = {
        "source": "City of Helsinki 3D city model (3D Tiles 1.1 LoD2) + HSY Ortoilmakuva 2023 + Mapillary",
        "licence": "CC BY 4.0 © City of Helsinki & HSY; CC BY-SA 4.0 Mapillary contributors",
        "crs": "EPSG:3879",
        "cell_m": CELL_M,
    }
    nb, total_tris, total_raw, total_comp = write_bundle(OUT_DIR, cells, meta)
    print(
        f"Compiled {nb:,} Helsinki LoD2 meshes ({total_tris:,} tris) into {len(cells)} binary v2 cells: "
        f"{total_raw / 1024 / 1024:.1f} MB raw -> {total_comp / 1024 / 1024:.1f} MB zstd"
    )
    print(f"  with HSY roof colour: {with_roof:,}/{nb:,}, with street wall colour: {with_wall:,}/{nb:,}")


if __name__ == "__main__":
    main()
