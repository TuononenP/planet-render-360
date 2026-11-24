#!/usr/bin/env python3
"""Sample real facade wall colours and materials for Aurajoki 150 m corridor
buildings from street-level imagery:
  - Mapillary Graph API v4 (CC BY-SA 4.0) when mapillary_accesstoken.txt or
    MAPILLARY_TOKEN is present (supports both 360° panoramas and perspective);
  - Panoramax (keyless, CC BY-SA 4.0) as additional/fallback coverage.

Matches street-facing CityGML WallSurface polygons to nearby photos using camera
position + compass angle, downloads thumbnails into build/street_facade_cache/,
samples upper-mid wall bands (excluding sky, foliage, shadows and glass), and
writes build/turku_aurajoki_facades.json.
"""

import concurrent.futures
import gzip
import json
import math
import os
import subprocess
import sys
import urllib.parse
import urllib.request
import xml.etree.ElementTree as ET

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from sample_turku_roofs import (  # noqa: E402
    BOX_E_RANGE, BOX_N_RANGE, CACHE_BOXES, CENTRE_GK23, CORRIDOR_M, INNER_RADIUS_M, NS,
    dist_to_aurajoki, gk23_forward, in_scope, read_bmp, sample_bmp,
)

ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
CACHE_DIR = os.path.join(ROOT, "build", "street_facade_cache")
OUT_PATH = os.path.join(ROOT, "build", "turku_aurajoki_facades.json")
TOKEN_FILE = os.path.join(ROOT, "mapillary_accesstoken.txt")
MAPILLARY_API = "https://graph.mapillary.com/images"
PANO_API = "https://api.panoramax.xyz/api/search"
UA = "planet-render-360 data tool"


def _inner_city_boxes():
    """Grid of small overlapping WGS84 bboxes (< 0.0001 deg²) covering Turku
    Extended Inner City (1.8 km around Kauppatori + Aurajoki to Castle)."""
    boxes = []
    # lon 22.224..22.304 (step 0.011), lat 60.433..60.468 (step 0.006)
    lon = 22.224
    while lon < 22.303:
        lat = 60.433
        while lat < 60.467:
            ce, cn = gk23_forward(lat + 0.003, lon + 0.0055)
            if math.hypot(ce - CENTRE_GK23[0], cn - CENTRE_GK23[1]) <= INNER_RADIUS_M + 450.0 \
                    or dist_to_aurajoki(ce, cn) <= CORRIDOR_M + 450.0:
                boxes.append((round(lon, 4), round(lat, 4), round(lon + 0.012, 4), round(lat + 0.0065, 4)))
            lat += 0.006
        lon += 0.011
    return boxes


CORRIDOR_BOXES = _inner_city_boxes()


def load_mapillary_token():
    tok = os.environ.get("MAPILLARY_TOKEN", "").strip()
    if tok:
        return tok
    if os.path.exists(TOKEN_FILE):
        with open(TOKEN_FILE, "r", encoding="utf-8") as f:
            return f.read().strip()
    return ""


def fetch_mapillary_index(token):
    os.makedirs(CACHE_DIR, exist_ok=True)
    idx_path = os.path.join(CACHE_DIR, "mapillary_index_inner.json")
    if os.path.exists(idx_path):
        with open(idx_path) as f:
            cached = json.load(f)
            if cached:
                return cached
    seen = {}
    fields = "id,compass_angle,computed_compass_angle,computed_geometry,geometry,thumb_1024_url,is_pano"
    for w, s, e, n in CORRIDOR_BOXES:
        params = urllib.parse.urlencode({
            "access_token": token,
            "fields": fields,
            "bbox": f"{w},{s},{e},{n}",
            "limit": "1500",
        })
        url = f"{MAPILLARY_API}?{params}"
        req = urllib.request.Request(url, headers={"User-Agent": UA})
        try:
            with urllib.request.urlopen(req, timeout=30) as resp:
                data = json.loads(resp.read())
        except Exception as exc:  # noqa: BLE001
            print(f"Mapillary bbox {w},{s} failed: {type(exc).__name__}", file=sys.stderr)
            continue
        for item in data.get("data", []):
            iid = str(item.get("id") or "")
            if not iid or iid in seen:
                continue
            geom = item.get("computed_geometry") or item.get("geometry") or {}
            coords = geom.get("coordinates") or []
            az = item.get("computed_compass_angle")
            if az is None:
                az = item.get("compass_angle")
            url_img = item.get("thumb_1024_url") or ""
            if len(coords) < 2 or az is None or not url_img:
                continue
            lon, lat = float(coords[0]), float(coords[1])
            pe, pn = gk23_forward(lat, lon)
            if math.hypot(pe - CENTRE_GK23[0], pn - CENTRE_GK23[1]) > INNER_RADIUS_M + 100.0 \
                    and dist_to_aurajoki(pe, pn) > CORRIDOR_M + 100.0:
                continue
            seen[iid] = {
                "id": "mapillary:" + iid,
                "src": "mapillary",
                "e": pe,
                "n": pn,
                "az": float(az),
                "url": url_img,
                "is_pano": bool(item.get("is_pano", False)),
                "fov": 360.0 if bool(item.get("is_pano", False)) else 82.0,
            }
    photos = list(seen.values())
    if photos:
        with open(idx_path, "w") as f:
            json.dump(photos, f)
    return photos


def fetch_panoramax_index():
    os.makedirs(CACHE_DIR, exist_ok=True)
    idx_path = os.path.join(CACHE_DIR, "panoramax_index_inner.json")
    if os.path.exists(idx_path):
        with open(idx_path) as f:
            return json.load(f)
    seen = {}
    for w, s, e, n in CORRIDOR_BOXES:
        url = f"{PANO_API}?bbox={w},{s},{e},{n}&limit=200"
        req = urllib.request.Request(url, headers={"User-Agent": UA})
        try:
            with urllib.request.urlopen(req, timeout=20) as resp:
                data = json.loads(resp.read())
        except Exception:  # noqa: BLE001
            continue
        for feat in data.get("features", []):
            fid = feat.get("id")
            if not fid or fid in seen:
                continue
            props = feat.get("properties", {})
            az = props.get("view:azimuth")
            coords = (feat.get("geometry") or {}).get("coordinates") or []
            sd = ((feat.get("assets") or {}).get("sd") or {}).get("href")
            if az is None or len(coords) < 2 or not sd:
                continue
            lon, lat = float(coords[0]), float(coords[1])
            pe, pn = gk23_forward(lat, lon)
            if math.hypot(pe - CENTRE_GK23[0], pn - CENTRE_GK23[1]) > INNER_RADIUS_M + 100.0 \
                    and dist_to_aurajoki(pe, pn) > CORRIDOR_M + 100.0:
                continue
            seen[fid] = {
                "id": "panoramax:" + fid,
                "src": "panoramax",
                "e": pe,
                "n": pn,
                "az": float(az),
                "url": sd,
                "is_pano": False,
                "fov": float((props.get("pers:interior_orientation") or {}).get("field_of_view") or 85.0),
            }
    photos = list(seen.values())
    with open(idx_path, "w") as f:
        json.dump(photos, f)
    return photos


def collect_building_walls():
    bldgs = {}
    for e0 in range(BOX_E_RANGE[0], BOX_E_RANGE[1], 500):
        for n0 in range(BOX_N_RANGE[0], BOX_N_RANGE[1], 500):
            fn = os.path.join(CACHE_BOXES, f"{e0}_{n0}.xml.gz")
            if not os.path.exists(fn):
                continue
            root = ET.fromstring(gzip.open(fn, "rb").read())
            for b in root.iter("{%s}Building" % NS["bldg"]):
                gid = b.get("{%s}id" % NS["gml"]) or ""
                if gid in bldgs:
                    continue
                vtj = ""
                yr = 0
                for a in b.findall("gen:stringAttribute", NS):
                    if a.get("name") == "pysyvarakennustunnus":
                        v = a.find("gen:value", NS)
                        vtj = (v.text or "").strip() if v is not None else ""
                    elif a.get("name") == "valmistunut":
                        v = a.find("gen:value", NS)
                        raw = (v.text or "").strip() if v is not None else ""
                        for cand in (raw[:4], raw[-4:]):
                            if len(cand) == 4 and cand.isdigit() and 1700 <= int(cand) <= 2100:
                                yr = int(cand)
                                break
                walls = []
                zmin, zmax = 1e9, -1e9
                for ws in b.iter("{%s}WallSurface" % NS["bldg"]):
                    for ring in ws.iter("{%s}LinearRing" % NS["gml"]):
                        pts = []
                        for pos in ring.findall("gml:pos", NS):
                            v = (pos.text or "").split()
                            if len(v) >= 3:
                                pts.append((float(v[0]), float(v[1]), float(v[2])))
                        if len(pts) < 4:
                            continue
                        nx = ny = nz = 0.0
                        for i in range(len(pts) - 1):
                            x0, y0, z0 = pts[i]
                            x1, y1, z1 = pts[i + 1]
                            nx += (y0 - y1) * (z0 + z1)
                            ny += (z0 - z1) * (x0 + x1)
                            nz += (x0 - x1) * (y0 + y1)
                        ln = math.sqrt(nx * nx + ny * ny + nz * nz)
                        if ln < 10.0:
                            continue
                        nx, ny, nz = nx / ln, ny / ln, nz / ln
                        if abs(nz) > 0.35:
                            continue
                        k = len(pts) - 1
                        ce = sum(p[0] for p in pts[:k]) / k
                        cn = sum(p[1] for p in pts[:k]) / k
                        zs = [p[2] for p in pts[:k]]
                        z0, z1 = min(zs), max(zs)
                        zmin = min(zmin, z0)
                        zmax = max(zmax, z1)
                        if z1 - z0 < 2.2:
                            continue
                        walls.append((ce, cn, z0, z1, nx, ny, ln * 0.5))
                if not walls:
                    continue
                ce = sum(w[0] * w[6] for w in walls) / sum(w[6] for w in walls)
                cn = sum(w[1] * w[6] for w in walls) / sum(w[6] for w in walls)
                if not in_scope(ce, cn):
                    continue
                walls.sort(key=lambda w: w[6], reverse=True)
                bldgs[gid] = {
                    "key": vtj if vtj else gid,
                    "e": ce,
                    "n": cn,
                    "h": max(0.0, zmax - zmin),
                    "yr": yr,
                    "walls": walls[:12],
                }
    return list(bldgs.values())


def angle_diff_deg(a, b):
    d = (a - b + 180.0) % 360.0 - 180.0
    return abs(d)


def download_photo_bmp(photo):
    safe = photo["id"].replace(":", "_")
    jpg_path = os.path.join(CACHE_DIR, f"{safe}.jpg")
    bmp_path = os.path.join(CACHE_DIR, f"{safe}.bmp")
    if not os.path.exists(bmp_path):
        if not os.path.exists(jpg_path):
            try:
                subprocess.run(
                    ["curl", "-fsSL", "--max-time", "25", "-H", "User-Agent: " + UA, photo["url"], "-o", jpg_path + ".tmp"],
                    check=True, stderr=subprocess.DEVNULL,
                )
                os.replace(jpg_path + ".tmp", jpg_path)
            except Exception:  # noqa: BLE001
                return (photo["id"], None)
        try:
            subprocess.run(
                ["sips", "-s", "format", "bmp", jpg_path, "--out", bmp_path],
                check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
            )
        except Exception:  # noqa: BLE001
            return (photo["id"], None)
    return (photo["id"], read_bmp(bmp_path))


def classify_wall(r, g, b, yr, h):
    # Reject cool blue-cast sky-shadow tint and lift shaded facades into realistic albedo range
    if b > r + 12 and b > g + 6:
        b = int((r + g) * 0.5)
    luma = 0.2126 * r + 0.7152 * g + 0.0722 * b
    if luma < 125.0:
        lift = min(1.85, 132.0 / max(luma, 1.0))
        r = min(228, int(r * lift))
        g = min(226, int(g * lift))
        b = min(220, int(b * lift))
    mx, mn = max(r, g, b), min(r, g, b)
    sat = (mx - mn) / max(mx, 1)
    hex_col = f"#{r:02x}{g:02x}{b:02x}"
    if r >= 92 and r > g * 1.24 and r > b * 1.48 and sat >= 0.24:
        return ("brick", hex_col)
    if yr > 0 and yr <= 1945 and h <= 9.5:
        return ("wood", hex_col)
    if sat < 0.085 and (yr >= 1955 or (yr == 0 and h >= 14.0)):
        return ("concrete", hex_col)
    return ("render", hex_col)


def main():
    token = load_mapillary_token()
    photos = []
    if token:
        mp = fetch_mapillary_index(token)
        panos = sum(1 for p in mp if p["is_pano"])
        print(f"Mapillary photos along Aurajoki corridor: {len(mp)} ({panos} 360° panos)")
        photos.extend(mp)
    pm = fetch_panoramax_index()
    print(f"Panoramax photos along Aurajoki corridor: {len(pm)}")
    photos.extend(pm)

    # Spatial grid (50 m cells) over photos for fast matching
    pgrid = {}
    for p in photos:
        ck = (int(p["e"] // 50), int(p["n"] // 50))
        pgrid.setdefault(ck, []).append(p)

    bldgs = collect_building_walls()
    print(f"Buildings with vertical walls within {CORRIDOR_M:.0f} m: {len(bldgs)}")

    matches = {}
    needed_photos = {}
    for b in bldgs:
        candidates = []
        ge, gn = int(b["e"] // 50), int(b["n"] // 50)
        nearby = []
        for de in (-2, -1, 0, 1, 2):
            for dn in (-2, -1, 0, 1, 2):
                nearby.extend(pgrid.get((ge + de, gn + dn), ()))
        for p in nearby:
            if math.hypot(b["e"] - p["e"], b["n"] - p["n"]) > 80.0:
                continue
            for w in b["walls"]:
                we, wn, z0, z1, nx, ny, area = w
                dx, dy = we - p["e"], wn - p["n"]
                dist = math.hypot(dx, dy)
                if not (8.0 <= dist <= 65.0):
                    continue
                dot_face = -(dx * nx + dy * ny) / dist
                if dot_face < 0.25:
                    continue
                bearing = math.degrees(math.atan2(dx, dy)) % 360.0
                if p["is_pano"]:
                    ang_weight = 1.0
                else:
                    ang_off = angle_diff_deg(bearing, p["az"])
                    if ang_off > 36.0:
                        continue
                    ang_weight = 1.0 - ang_off / 44.0
                # Prefer closer, face-on, 360° panos
                pano_bonus = 1.35 if p["is_pano"] else 1.0
                score = pano_bonus * dot_face * min(area, 120.0) / (dist + 10.0) * ang_weight
                candidates.append((score, p, w, bearing, dist))
        if not candidates:
            continue
        candidates.sort(key=lambda c: c[0], reverse=True)
        chosen = []
        used_pids = set()
        for c in candidates:
            if c[1]["id"] in used_pids:
                continue
            chosen.append(c)
            used_pids.add(c[1]["id"])
            needed_photos[c[1]["id"]] = c[1]
            if len(chosen) >= 2:
                break
        matches[b["key"]] = (b, chosen)

    print(f"Matched {len(matches)}/{len(bldgs)} buildings to {len(needed_photos)} unique photos")
    bmps = {}
    with concurrent.futures.ThreadPoolExecutor(max_workers=12) as ex:
        for pid, bmp in ex.map(download_photo_bmp, needed_photos.values()):
            if bmp is not None:
                bmps[pid] = bmp
    print(f"Decoded {len(bmps)} street-level photos")

    out = {}
    for key, (b, chosen) in matches.items():
        samples = []
        used_ids = []
        for _, p, w, bearing, dist in chosen:
            bmp = bmps.get(p["id"])
            if bmp is None:
                continue
            d_az = (bearing - p["az"] + 180.0) % 360.0 - 180.0
            h_wall = max(3.5, w[3] - w[2])
            el_lo = math.degrees(math.atan2(max(1.5, h_wall * 0.35 - 1.6), dist))
            el_hi = math.degrees(math.atan2(max(2.5, h_wall * 0.78 - 1.6), dist))
            if p["is_pano"]:
                # Equirectangular 360° x 180°: u=0.5 is heading, wraps around [0, 1]
                u_center = (0.5 + d_az / 360.0) % 1.0
                v_hi = 0.5 - el_lo / 180.0
                v_lo = 0.5 - el_hi / 180.0
                du_span = min(0.035, max(0.012, 1.5 / max(dist, 8.0)))
            else:
                fov = p["fov"] if 35.0 <= p["fov"] <= 120.0 else 82.0
                u_center = 0.5 + (d_az / fov)
                if not (0.06 <= u_center <= 0.94):
                    continue
                vfov = fov * (bmp[1] / max(1, bmp[0]))
                v_hi = 0.5 - el_lo / vfov
                v_lo = 0.5 - el_hi / vfov
                du_span = min(0.09, max(0.03, 3.5 / max(dist, 8.0)))
            v_lo = max(0.10, min(0.55, v_lo))
            v_hi = max(v_lo + 0.03, min(0.60, v_hi))
            used_ids.append(p["id"])
            for iu in range(-3, 4):
                u = u_center + iu * (du_span / 3.0)
                if p["is_pano"]:
                    u = u % 1.0
                elif not (0.04 <= u <= 0.96):
                    continue
                for iv in range(5):
                    v = v_lo + (v_hi - v_lo) * (iv / 4.0)
                    rgb = sample_bmp(bmp, u, v)
                    if rgb is None:
                        continue
                    r, g, bl = rgb
                    luma = 0.2126 * r + 0.7152 * g + 0.0722 * bl
                    if luma < 56 or luma > 238:
                        continue
                    if bl > r + 18 and bl > g + 6 and luma > 135:
                        continue  # blue sky
                    if g > r + 10 and g > bl + 8:
                        continue  # green tree canopy
                    samples.append((luma, r, g, bl))
        if len(samples) < 8:
            continue
        samples.sort(key=lambda s: s[0])
        lo = int(len(samples) * 0.25)
        hi = max(lo + 1, int(len(samples) * 0.85))
        mid_s = samples[lo:hi]
        rs = sorted(s[1] for s in mid_s)
        gs = sorted(s[2] for s in mid_s)
        bs = sorted(s[3] for s in mid_s)
        m = len(mid_s) // 2
        mat, hex_col = classify_wall(rs[m], gs[m], bs[m], b["yr"], b["h"])
        out[key] = {
            "wall_material": mat,
            "wall_colour": hex_col,
            "samples": len(mid_s),
            "photo_ids": used_ids,
        }

    os.makedirs(os.path.dirname(OUT_PATH), exist_ok=True)
    with open(OUT_PATH, "w") as f:
        json.dump(
            {
                "source": "Mapillary Graph API v4 + Panoramax",
                "licence": "CC BY-SA 4.0, Mapillary & Panoramax contributors",
                "buildings": out,
            },
            f,
            indent=1,
            sort_keys=True,
        )
    mats = {}
    for v in out.values():
        mats[v["wall_material"]] = mats.get(v["wall_material"], 0) + 1
    print(f"Sampled facades for {len(out)}/{len(bldgs)} buildings -> {OUT_PATH}")
    print("Wall material breakdown:", mats)


if __name__ == "__main__":
    main()
