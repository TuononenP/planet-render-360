#!/usr/bin/env python3
"""Sample real roof colours and materials for all Helsinki & Espoo LoD2 buildings
from HSY's CC BY 4.0 Ortoilmakuva 2023 aerial orthophoto WMS.

Reads building centroids from assets/city_models/helsinki_lod2/ and espoo_lod2/
(already prepared), fetches 2.5 km HSY WMS JPEG tiles into build/hsy_roof_ortho/
(cached), samples diffuse roof pixels, and writes build/capital_roofs.json keyed
by rounded GK25 decimetre "e_dm,n_dm" (plus vtj_prt when non-empty).
"""

import concurrent.futures
import json
import math
import os
import subprocess
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from prepare_helsinki_lod2 import gk25_inverse  # noqa: E402
from sample_turku_roofs import classify_roof_color, latlon_to_3857, read_bmp, sample_bmp  # noqa: E402

ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
ORTHO_DIR = os.path.join(ROOT, "build", "hsy_roof_ortho")
OUT_PATH = os.path.join(ROOT, "build", "capital_roofs.json")
WMS_URL = "https://kartta.hsy.fi/geoserver/wms"
LAYER = "taustakartat_ja_aluejaot:Ortoilmakuva_2023"
UA = "planet-render-360 data tool"
TILE_M = 2400.0
TILE_PX = 1024


def load_lod2_rows(bundle_dir):
    manifest_path = os.path.join(bundle_dir, "manifest.json")
    if not os.path.exists(manifest_path):
        return []
    manifest = json.load(open(manifest_path))
    rows = []
    for ck in sorted(manifest.get("cells", {}).keys()):
        p = os.path.join(bundle_dir, ck + ".lod2")
        if not os.path.exists(p):
            continue
        raw = subprocess.run(["zstd", "-q", "-d", "-c", p], capture_output=True, check=True).stdout
        rows.extend(json.loads(raw).get("rows", []))
    return rows


def fetch_hsy_tile(tx, ty):
    os.makedirs(ORTHO_DIR, exist_ok=True)
    x0, y0 = tx * TILE_M, ty * TILE_M
    x1, y1 = x0 + TILE_M, y0 + TILE_M
    jpg_path = os.path.join(ORTHO_DIR, f"{tx}_{ty}.jpg")
    bmp_path = os.path.join(ORTHO_DIR, f"{tx}_{ty}.bmp")
    if not os.path.exists(bmp_path):
        if not os.path.exists(jpg_path):
            url = (
                f"{WMS_URL}?service=WMS&version=1.3.0&request=GetMap"
                f"&layers={LAYER}&styles=&crs=EPSG:3857&format=image/jpeg"
                f"&width={TILE_PX}&height={TILE_PX}&bbox={x0:.2f},{y0:.2f},{x1:.2f},{y1:.2f}"
            )
            try:
                subprocess.run(
                    ["curl", "-fsSL", "--max-time", "60", "-H", "User-Agent: " + UA, url, "-o", jpg_path + ".tmp"],
                    check=True, stderr=subprocess.DEVNULL,
                )
                os.replace(jpg_path + ".tmp", jpg_path)
            except Exception:  # noqa: BLE001
                return ((tx, ty), None)
        try:
            subprocess.run(
                ["sips", "-s", "format", "bmp", jpg_path, "--out", bmp_path],
                check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
            )
        except Exception:  # noqa: BLE001
            return ((tx, ty), None)
    return ((tx, ty), read_bmp(bmp_path))


def main():
    hel_rows = load_lod2_rows(os.path.join(ROOT, "assets", "city_models", "helsinki_lod2"))
    esp_rows = load_lod2_rows(os.path.join(ROOT, "assets", "city_models", "espoo_lod2"))
    all_rows = hel_rows + esp_rows
    print(f"Loaded {len(hel_rows):,} Helsinki + {len(esp_rows):,} Espoo = {len(all_rows):,} LoD2 rows")

    needed = set()
    pts_3857 = []
    for r in all_rows:
        vtj, e, n, area = r[0], float(r[1]), float(r[2]), float(r[3])
        if area < 10.0:
            continue
        is_flat = str(r[8]) == "flat"
        lat, lon = gk25_inverse(e, n)
        mx, my = latlon_to_3857(lat, lon)
        tx, ty = math.floor(mx / TILE_M), math.floor(my / TILE_M)
        needed.add((tx, ty))
        pts_3857.append((vtj, e, n, mx, my, tx, ty, is_flat))

    print(f"Fetching/loading {len(needed)} HSY Ortoilmakuva 2023 WMS tiles...")
    tiles = {}
    with concurrent.futures.ThreadPoolExecutor(max_workers=8) as ex:
        for k, bmp in ex.map(lambda t: fetch_hsy_tile(t[0], t[1]), sorted(needed)):
            if bmp is not None:
                tiles[k] = bmp
    print(f"Decoded {len(tiles)}/{len(needed)} HSY tiles")

    by_vtj = {}
    by_cell = {}
    mats = {}
    for vtj, e, n, mx, my, tx, ty, is_flat in pts_3857:
        bmp = tiles.get((tx, ty))
        if bmp is None:
            continue
        u = (mx - tx * TILE_M) / TILE_M
        v = 1.0 - (my - ty * TILE_M) / TILE_M
        samples = []
        for du, dv in ((0.0, 0.0), (0.0012, 0.0), (-0.0012, 0.0), (0.0, 0.0012), (0.0, -0.0012)):
            rgb = sample_bmp(bmp, u + du, v + dv)
            if rgb is None:
                continue
            r, g, b = rgb
            luma = 0.2126 * r + 0.7152 * g + 0.0722 * b
            if 28 <= luma <= 242:
                samples.append((luma, r, g, b))
        if not samples:
            continue
        samples.sort(key=lambda s: s[0])
        lo = int(len(samples) * 0.20)
        hi = max(lo + 1, int(len(samples) * 0.55))
        lit = samples[lo:hi]
        mid = len(lit) // 2
        rm, rc = classify_roof_color(
            sorted(s[1] for s in lit)[mid],
            sorted(s[2] for s in lit)[mid],
            sorted(s[3] for s in lit)[mid],
            is_flat,
        )
        mats[rm] = mats.get(rm, 0) + 1
        val = [rm, rc]
        if vtj:
            by_vtj[vtj] = val
        by_cell[f"{int(round(e))},{int(round(n))}"] = val

    os.makedirs(os.path.dirname(OUT_PATH), exist_ok=True)
    with open(OUT_PATH, "w") as f:
        json.dump(
            {
                "source": WMS_URL + " (" + LAYER + ")",
                "licence": "CC BY 4.0, © HSY, orthophoto 2023",
                "by_vtj": by_vtj,
                "by_en": by_cell,
            },
            f,
            separators=(",", ":"),
        )
    print(f"Sampled {len(by_cell):,} capital-region roofs -> {OUT_PATH}")
    print("Material breakdown:", mats)


if __name__ == "__main__":
    main()
