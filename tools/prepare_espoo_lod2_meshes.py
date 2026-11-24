#!/usr/bin/env python3
"""Compile true 3D CityGML LoD2 building meshes for ALL of Espoo into compact
binary v2 .lod2m (PackedInt32Array zstd) 1 km GK25 cells under
assets/city_models/espoo_lod2_meshes/.
"""

import concurrent.futures
import glob
import gzip
import json
import math
import os
import sys
import xml.etree.ElementTree as ET

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lod2m_codec import write_bundle  # noqa: E402
from prepare_turku_lod2_meshes import add_polygon, newell_normal  # noqa: E402

ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
CACHE_BOXES = os.path.join(ROOT, "build", "espoo_lod2_boxes")
OUT_DIR = os.path.join(ROOT, "assets", "city_models", "espoo_lod2_meshes")
ROOFS_PATH = os.path.join(ROOT, "build", "capital_roofs.json")
FACADES_PATH = os.path.join(ROOT, "build", "capital_facades.json")
CELL_M = 1000

NS = {
    "gml": "http://www.opengis.net/gml",
    "bldg": "http://www.opengis.net/citygml/building/2.0",
    "gen": "http://www.opengis.net/citygml/generics/2.0",
}


def _attr(b, name):
    for a in b.findall("gen:stringAttribute", NS):
        if a.get("name") == name:
            v = a.find("gen:value", NS)
            return (v.text or "").strip() if v is not None else ""
    return ""


def parse_box(fn):
    out = {}
    try:
        root = ET.fromstring(gzip.open(fn, "rb").read())
    except Exception:  # noqa: BLE001
        return out
    for b in root.iter("{%s}Building" % NS["bldg"]):
        gid = b.get("{%s}id" % NS["gml"]) or ""
        wall_rings = []
        roof_rings = []
        zmin, zmax = math.inf, -math.inf
        plan_area = 0.0
        ce_sum = cn_sum = w_sum = 0.0
        for kind in ("WallSurface", "RoofSurface", "GroundSurface", "BuildingInstallation"):
            for surf in b.iter("{%s}%s" % (NS["bldg"], kind)):
                for ring in surf.iter("{%s}LinearRing" % NS["gml"]):
                    pts = []
                    for pos in ring.findall("gml:pos", NS):
                        v = (pos.text or "").split()
                        if len(v) >= 3:
                            pts.append((float(v[0]), float(v[1]), float(v[2])))
                    if len(pts) < 4:
                        continue
                    zs = [p[2] for p in pts]
                    zmin = min(zmin, min(zs))
                    zmax = max(zmax, max(zs))
                    if kind == "WallSurface":
                        wall_rings.append(pts)
                    elif kind == "RoofSurface":
                        roof_rings.append(pts)
                        nm = newell_normal(pts)
                        if nm is not None and abs(nm[2]) > 0.15:
                            a_proj = nm[3] * abs(nm[2])
                            plan_area += a_proj
                            k = len(pts) - 1
                            ce_sum += a_proj * (sum(p[0] for p in pts[:k]) / k)
                            cn_sum += a_proj * (sum(p[1] for p in pts[:k]) / k)
                            w_sum += a_proj
                    elif kind == "BuildingInstallation":
                        nm = newell_normal(pts)
                        if nm is not None:
                            if abs(nm[2]) > 0.45:
                                roof_rings.append(pts)
                            else:
                                wall_rings.append(pts)
        if plan_area < 12.0 or not wall_rings or not roof_rings or w_sum <= 0.0:
            continue
        ce = ce_sum / w_sum
        cn = cn_sum / w_sum
        h = max(0.0, zmax - zmin)
        if h < 2.2:
            continue
        wv, wu, wi = [], [], []
        rv, ru, ri = [], [], []
        for pts in wall_rings:
            add_polygon(pts, False, ce, cn, zmin, wv, wu, wi)
        for pts in roof_rings:
            add_polygon(pts, True, ce, cn, zmin, rv, ru, ri)
        if not wi or not ri:
            continue
        vtj = _attr(b, "rakennustunnus") or _attr(b, "pysyvarakennustunnus")
        storeys = 0
        st = b.find("bldg:storeysAboveGround", NS)
        if st is not None and st.text and st.text.strip().isdigit():
            storeys = int(st.text.strip())
        if storeys <= 0 or storeys >= 200:
            storeys = max(1, int(round(h / 3.3)))
        yr = 0
        yc = b.find("bldg:yearOfConstruction", NS)
        raw_y = (yc.text or "").strip() if yc is not None else ""
        if len(raw_y) >= 4 and raw_y[:4].isdigit() and 1700 <= int(raw_y[:4]) <= 2100:
            yr = int(raw_y[:4])
        out[gid] = {
            "id": vtj if vtj else gid,
            "vtj": vtj,
            "e": round(ce, 1),
            "n": round(cn, 1),
            "area": round(plan_area, 1),
            "h": round(h, 2),
            "st": storeys,
            "yr": yr,
            "wv": wv, "wu": wu, "wi": wi,
            "rv": rv, "ru": ru, "ri": ri,
        }
    return out


def main():
    roofs = json.load(open(ROOFS_PATH)) if os.path.exists(ROOFS_PATH) else {}
    facades = json.load(open(FACADES_PATH)) if os.path.exists(FACADES_PATH) else {}
    r_vtj, r_en = roofs.get("by_vtj", {}), roofs.get("by_en", {})
    f_vtj, f_en = facades.get("by_vtj", {}), facades.get("by_en", {})

    files = sorted(glob.glob(os.path.join(CACHE_BOXES, "*.xml.gz")))
    print(f"Parsing {len(files)} Espoo CityGML boxes in parallel...")
    seen = {}
    with concurrent.futures.ProcessPoolExecutor() as ex:
        for batch in ex.map(parse_box, files, chunksize=8):
            seen.update(batch)

    cells = {}
    with_roof = with_wall = 0
    for rec in seen.values():
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
        "source": "City of Espoo 3D city model (bldg:building_lod2) + HSY Ortoilmakuva 2023 + Mapillary",
        "licence": "CC BY 4.0 © City of Espoo & HSY; CC BY-SA 4.0 Mapillary contributors",
        "crs": "EPSG:3879",
        "cell_m": CELL_M,
    }
    nb, total_tris, total_raw, total_comp = write_bundle(OUT_DIR, cells, meta)
    print(
        f"Compiled {nb:,} Espoo LoD2 meshes ({total_tris:,} tris) into {len(cells)} binary v2 cells: "
        f"{total_raw / 1024 / 1024:.1f} MB raw -> {total_comp / 1024 / 1024:.1f} MB zstd"
    )
    print(f"  with HSY roof colour: {with_roof:,}/{nb:,}, with street wall colour: {with_wall:,}/{nb:,}")


if __name__ == "__main__":
    main()
