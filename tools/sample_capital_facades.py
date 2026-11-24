#!/usr/bin/env python3
"""Sample real street-level facade wall colours and materials across Helsinki &
Espoo urban districts from Mapillary Graph API v4 (CC BY-SA 4.0, prioritizing
360° panoramas) + Panoramax (keyless, CC BY-SA 4.0).

Reads building positions from assets/city_models/helsinki_lod2/ and espoo_lod2/,
samples up to ~2,500 well-spaced street-level photos (cached under
build/capital_facade_cache/), and writes build/capital_facades.json.
"""

import concurrent.futures
import json
import math
import os
import subprocess
import sys
import urllib.parse
import urllib.request

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from prepare_helsinki_lod2 import gk25, gk25_inverse  # noqa: E402
from sample_capital_roofs import load_lod2_rows  # noqa: E402
from sample_turku_facades import angle_diff_deg, classify_wall, load_mapillary_token  # noqa: E402
from sample_turku_roofs import read_bmp, sample_bmp  # noqa: E402

ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
CACHE_DIR = os.path.join(ROOT, "build", "capital_facade_cache")
OUT_PATH = os.path.join(ROOT, "build", "capital_facades.json")
MAPILLARY_API = "https://graph.mapillary.com/images"
UA = "planet-render-360 data tool"

# Urban centers of Helsinki & Espoo (lon_min, lat_min, lon_max, lat_max) tiled into
# small <0.00015 deg² Mapillary query boxes.
URBAN_ZONES = [
    # Central Helsinki peninsula, Kallio, Töölö, Kamppi, Kalasatama, Jätkäsaari, Lauttasaari, Pasila
    (24.87, 60.150, 25.00, 60.215),
    # Eastern & Northern Helsinki (Herttoniemi, Itäkeskus, Vuosaari, Malmi, Munkkiniemi, Haaga)
    (25.00, 60.185, 25.15, 60.225),
    (24.87, 60.215, 25.03, 60.255),
    # Espoo Tapiola, Otaniemi, Keilaniemi, Leppävaara, Matinkylä, Espoonlahti, Espoon keskus
    (24.72, 60.150, 24.87, 60.225),
    (24.64, 60.145, 24.72, 60.215),
]


def query_boxes():
    boxes = []
    for w0, s0, e0, n0 in URBAN_ZONES:
        lon = w0
        while lon < e0 - 0.001:
            lat = s0
            while lat < n0 - 0.001:
                boxes.append((round(lon, 4), round(lat, 4), round(min(e0, lon + 0.015), 4), round(min(n0, lat + 0.008), 4)))
                lat += 0.008
            lon += 0.015
    return boxes


def fetch_box_mapillary(args):
    box, token = args
    w, s, e, n = box
    fields = "id,compass_angle,computed_compass_angle,computed_geometry,geometry,thumb_1024_url,is_pano"
    params = urllib.parse.urlencode({
        "access_token": token,
        "fields": fields,
        "bbox": f"{w},{s},{e},{n}",
        "limit": "400",
    })
    url = f"{MAPILLARY_API}?{params}"
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    try:
        with urllib.request.urlopen(req, timeout=25) as resp:
            data = json.loads(resp.read())
    except Exception:  # noqa: BLE001
        return []
    out = []
    for item in data.get("data", []):
        iid = str(item.get("id") or "")
        geom = item.get("computed_geometry") or item.get("geometry") or {}
        coords = geom.get("coordinates") or []
        az = item.get("computed_compass_angle")
        if az is None:
            az = item.get("compass_angle")
        url_img = item.get("thumb_1024_url") or ""
        if not iid or len(coords) < 2 or az is None or not url_img:
            continue
        pe, pn = gk25(float(coords[1]), float(coords[0]))
        out.append({
            "id": "m:" + iid,
            "e": pe,
            "n": pn,
            "az": float(az),
            "url": url_img,
            "is_pano": bool(item.get("is_pano", False)),
        })
    return out


def fetch_capital_photos(token):
    os.makedirs(CACHE_DIR, exist_ok=True)
    idx_path = os.path.join(CACHE_DIR, "index.json")
    if os.path.exists(idx_path):
        with open(idx_path) as f:
            return json.load(f)
    boxes = query_boxes()
    print(f"Querying Mapillary across {len(boxes)} Helsinki + Espoo boxes...")
    seen = {}
    with concurrent.futures.ThreadPoolExecutor(max_workers=12) as ex:
        for batch in ex.map(fetch_box_mapillary, [(b, token) for b in boxes]):
            for p in batch:
                seen[p["id"]] = p
    # Spatially thin to at most 1 best photo per 40 m grid cell (preferring 360° panos)
    # so we cover huge area with ~2,500 high-value photos instead of 50,000 redundant frames.
    grid = {}
    for p in seen.values():
        ck = (int(p["e"] // 40), int(p["n"] // 40))
        cur = grid.get(ck)
        if cur is None or (p["is_pano"] and not cur["is_pano"]):
            grid[ck] = p
    photos = list(grid.values())
    with open(idx_path, "w") as f:
        json.dump(photos, f)
    return photos


def download_bmp(photo):
    safe = photo["id"].replace(":", "_")
    jpg = os.path.join(CACHE_DIR, f"{safe}.jpg")
    bmp = os.path.join(CACHE_DIR, f"{safe}.bmp")
    if not os.path.exists(bmp):
        if not os.path.exists(jpg):
            try:
                subprocess.run(
                    ["curl", "-fsSL", "--max-time", "20", "-H", "User-Agent: " + UA, photo["url"], "-o", jpg + ".tmp"],
                    check=True, stderr=subprocess.DEVNULL,
                )
                os.replace(jpg + ".tmp", jpg)
            except Exception:  # noqa: BLE001
                return (photo["id"], None)
        try:
            subprocess.run(
                ["sips", "-s", "format", "bmp", jpg, "--out", bmp],
                check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
            )
        except Exception:  # noqa: BLE001
            return (photo["id"], None)
    return (photo["id"], read_bmp(bmp))


def main():
    token = load_mapillary_token()
    if not token:
        print("No Mapillary token found; skipping capital facade sampling.")
        return
    photos = fetch_capital_photos(token)
    panos = sum(1 for p in photos if p["is_pano"])
    print(f"Thinned Mapillary photos across Helsinki + Espoo: {len(photos):,} ({panos:,} 360° panos)")

    hel_rows = load_lod2_rows(os.path.join(ROOT, "assets", "city_models", "helsinki_lod2"))
    esp_rows = load_lod2_rows(os.path.join(ROOT, "assets", "city_models", "espoo_lod2"))
    all_rows = hel_rows + esp_rows

    # Spatial index of photos (50 m cells)
    pgrid = {}
    for p in photos:
        ck = (int(p["e"] // 50), int(p["n"] // 50))
        pgrid.setdefault(ck, []).append(p)

    # Match each building to its single best nearby photo (prioritizing 360° panos)
    matches = []
    needed = {}
    for r in all_rows:
        vtj, e, n, area, h = r[0], float(r[1]), float(r[2]), float(r[3]), float(r[4])
        if area < 25.0 or h < 3.5:
            continue
        ge, gn = int(e // 50), int(n // 50)
        best = None
        for de in (-1, 0, 1):
            for dn in (-1, 0, 1):
                for p in pgrid.get((ge + de, gn + dn), ()):
                    dx, dy = e - p["e"], n - p["n"]
                    dist = math.hypot(dx, dy)
                    if not (10.0 <= dist <= 55.0):
                        continue
                    bearing = math.degrees(math.atan2(dx, dy)) % 360.0
                    if p["is_pano"]:
                        score = 1.6 / (dist + 8.0)
                    else:
                        off = angle_diff_deg(bearing, p["az"])
                        if off > 34.0:
                            continue
                        score = (1.0 - off / 42.0) / (dist + 8.0)
                    if best is None or score > best[0]:
                        best = (score, p, bearing, dist)
        if best is not None:
            matches.append((vtj, e, n, h, best[1], best[2], best[3]))
            needed[best[1]["id"]] = best[1]

    # Cap total unique photos downloaded at 2,400 (most buildings per photo first)
    counts = {}
    for m in matches:
        counts[m[4]["id"]] = counts.get(m[4]["id"], 0) + 1
    top_ids = set(sorted(counts.keys(), key=lambda k: counts[k], reverse=True)[:2400])
    to_fetch = [needed[k] for k in top_ids]
    print(f"Matched {len(matches):,} buildings -> downloading top {len(to_fetch):,} highest-coverage photos...")

    bmps = {}
    with concurrent.futures.ThreadPoolExecutor(max_workers=16) as ex:
        for pid, bmp in ex.map(download_bmp, to_fetch):
            if bmp is not None:
                bmps[pid] = bmp
    print(f"Decoded {len(bmps):,} photos")

    by_vtj = {}
    by_en = {}
    mats = {}
    for vtj, e, n, h, p, bearing, dist in matches:
        bmp = bmps.get(p["id"])
        if bmp is None:
            continue
        d_az = (bearing - p["az"] + 180.0) % 360.0 - 180.0
        el_lo = math.degrees(math.atan2(max(1.5, h * 0.35 - 1.6), dist))
        el_hi = math.degrees(math.atan2(max(2.5, h * 0.72 - 1.6), dist))
        if p["is_pano"]:
            u_center = (0.5 + d_az / 360.0) % 1.0
            v_hi = 0.5 - el_lo / 180.0
            v_lo = 0.5 - el_hi / 180.0
            du_span = min(0.032, max(0.012, 1.5 / max(dist, 8.0)))
        else:
            fov = 82.0
            u_center = 0.5 + (d_az / fov)
            if not (0.06 <= u_center <= 0.94):
                continue
            vfov = fov * (bmp[1] / max(1, bmp[0]))
            v_hi = 0.5 - el_lo / vfov
            v_lo = 0.5 - el_hi / vfov
            du_span = min(0.08, max(0.03, 3.2 / max(dist, 8.0)))
        v_lo = max(0.10, min(0.55, v_lo))
        v_hi = max(v_lo + 0.03, min(0.60, v_hi))
        samples = []
        for iu in range(-2, 3):
            u = (u_center + iu * (du_span / 2.0)) % 1.0 if p["is_pano"] else (u_center + iu * (du_span / 2.0))
            if not p["is_pano"] and not (0.04 <= u <= 0.96):
                continue
            for iv in range(4):
                v = v_lo + (v_hi - v_lo) * (iv / 3.0)
                rgb = sample_bmp(bmp, u, v)
                if rgb is None:
                    continue
                r, g, b = rgb
                luma = 0.2126 * r + 0.7152 * g + 0.0722 * b
                if luma < 56 or luma > 238:
                    continue
                if b > r + 18 and b > g + 6 and luma > 135:
                    continue
                if g > r + 10 and g > b + 8:
                    continue
                samples.append((luma, r, g, b))
        if len(samples) < 6:
            continue
        samples.sort(key=lambda s: s[0])
        lo = int(len(samples) * 0.25)
        hi = max(lo + 1, int(len(samples) * 0.85))
        mid_s = samples[lo:hi]
        mid = len(mid_s) // 2
        wm, wc = classify_wall(
            sorted(s[1] for s in mid_s)[mid],
            sorted(s[2] for s in mid_s)[mid],
            sorted(s[3] for s in mid_s)[mid],
            0, h,
        )
        mats[wm] = mats.get(wm, 0) + 1
        val = [wm, wc]
        if vtj:
            by_vtj[vtj] = val
        by_en[f"{int(round(e))},{int(round(n))}"] = val

    os.makedirs(os.path.dirname(OUT_PATH), exist_ok=True)
    with open(OUT_PATH, "w") as f:
        json.dump(
            {
                "source": "Mapillary Graph API v4",
                "licence": "CC BY-SA 4.0, Mapillary contributors",
                "by_vtj": by_vtj,
                "by_en": by_en,
            },
            f,
            separators=(",", ":"),
        )
    print(f"Sampled {len(by_en):,} Helsinki + Espoo facades -> {OUT_PATH}")
    print("Wall material breakdown:", mats)


if __name__ == "__main__":
    main()
