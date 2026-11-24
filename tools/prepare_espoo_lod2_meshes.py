#!/usr/bin/env python3
"""Compile attribute-only binary v2 .lod2m (PackedInt32Array zstd) cells for ALL
of Espoo under assets/city_models/espoo_lod2_meshes/.

Like Helsinki (prepare_helsinki_lod2_meshes.py), Espoo keeps BuildingBuilder's
clean procedural vertical walls, multi-part OSM 3D glass complexes & skylight
atria, BuildingTrim parapets/cornices, ModernBlockRelief curtain fins/fascias/
balconies, and manifold HelsinkiLod2 (espoo_lod2) roofs, while receiving all
sampled HSY Ortoilmakuva 2023 roof colours/materials and Mapillary wall colours
from these compact (~0.2 MB) attribute-only binary v2 cells (nwv=nwi=nrv=nri=0).
"""

import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lod2m_codec import write_bundle  # noqa: E402
from sample_capital_roofs import load_lod2_rows  # noqa: E402

ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
ESP_LOD2_DIR = os.path.join(ROOT, "assets", "city_models", "espoo_lod2")
OUT_DIR = os.path.join(ROOT, "assets", "city_models", "espoo_lod2_meshes")
ROOFS_PATH = os.path.join(ROOT, "build", "capital_roofs.json")
FACADES_PATH = os.path.join(ROOT, "build", "capital_facades.json")
CELL_M = 1000


def main():
    rows = load_lod2_rows(ESP_LOD2_DIR)
    roofs = json.load(open(ROOFS_PATH)) if os.path.exists(ROOFS_PATH) else {}
    facades = json.load(open(FACADES_PATH)) if os.path.exists(FACADES_PATH) else {}
    r_vtj, r_en = roofs.get("by_vtj", {}), roofs.get("by_en", {})
    f_vtj, f_en = facades.get("by_vtj", {}), facades.get("by_en", {})

    cells = {}
    with_roof = with_wall = 0
    for r in rows:
        vtj, e, n, area, h = str(r[0] or ""), float(r[1]), float(r[2]), float(r[3]), float(r[4])
        if area < 10.0 or h < 2.0:
            continue
        st = int(r[9]) if len(r) > 9 and int(r[9]) > 0 else max(1, int(round(h / 3.3)))
        ek = f"{int(round(e))},{int(round(n))}"
        rf = r_vtj.get(vtj) if vtj else None
        if rf is None:
            rf = r_en.get(ek)
        fc = f_vtj.get(vtj) if vtj else None
        if fc is None:
            fc = f_en.get(ek)
        if not rf and not fc:
            continue
        rec = {
            "e": round(e, 1),
            "n": round(n, 1),
            "area": round(area, 1),
            "h": round(h, 2),
            "st": st,
            "yr": 0,
            "wv": [], "wu": [], "wi": [],
            "rv": [], "ru": [], "ri": [],
        }
        if rf:
            rec["rm"], rec["rc"] = rf[0], rf[1]
            with_roof += 1
        if fc:
            rec["wm"], rec["wc"] = fc[0], fc[1]
            with_wall += 1
        ck = f"{int(e // CELL_M)}_{int(n // CELL_M)}"
        cells.setdefault(ck, []).append(rec)

    meta = {
        "source": "HSY Ortoilmakuva 2023 + Mapillary (attribute-only for clean BuildingBuilder geometry)",
        "licence": "CC BY 4.0 © City of Espoo & HSY; CC BY-SA 4.0 Mapillary contributors",
        "crs": "EPSG:3879",
        "mode": "attributes_only",
        "cell_m": CELL_M,
    }
    nb, _tris, total_raw, total_comp = write_bundle(OUT_DIR, cells, meta)
    print(
        f"Compiled {nb:,} Espoo attribute-only binary v2 records into {len(cells)} cells: "
        f"{total_raw / 1024:.0f} KB raw -> {total_comp / 1024:.0f} KB zstd"
    )
    print(f"  with HSY roof colour: {with_roof:,}/{nb:,}, with street wall colour: {with_wall:,}/{nb:,}")


if __name__ == "__main__":
    main()
