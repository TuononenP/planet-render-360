#!/usr/bin/env python3
"""Sample real roof colours and materials for Aurajoki 150 m corridor buildings
from the City of Turku's CC BY 4.0 Ilmakuva 2025 aerial orthophoto WMS.

Reads cached CityGML boxes in build/turku_lod2_boxes/, fetches 500 m WMS tiles
into build/turku_roof_ortho/ (cached), samples median sunlit roof pixels per
building, and writes build/turku_aurajoki_roofs.json.
"""

import concurrent.futures
import gzip
import json
import math
import os
import struct
import subprocess
import sys
import xml.etree.ElementTree as ET

ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
CACHE_BOXES = os.path.join(ROOT, "build", "turku_lod2_boxes")
ORTHO_DIR = os.path.join(ROOT, "build", "turku_roof_ortho")
OUT_PATH = os.path.join(ROOT, "build", "turku_aurajoki_roofs.json")

WMS_URL = "https://turku.asiointi.fi/TeklaOGCWeb/WMS.ashx"
UA = "planet-render-360 data tool"
CORRIDOR_M = 150.0
# Extended inner city: 1.8 km around Kauppatori/Auransilta PLUS 150 m along Aurajoki to Castle.
CENTRE_GK23 = (23459600.0, 6704450.0)
INNER_RADIUS_M = 1800.0
BOX_E_RANGE = (23457000, 23462000)
BOX_N_RANGE = (6702500, 6706500)

NS = {
    "gml": "http://www.opengis.net/gml",
    "bldg": "http://www.opengis.net/citygml/building/2.0",
    "gen": "http://www.opengis.net/citygml/generics/2.0",
}

# Aurajoki centerline in GK23 (EPSG:3877) from Tuomiokirkkosilta/Cathedral to Aura mouth/Castle.
AURAJOKI_GK23 = [
    (23460480.0, 6705200.0),
    (23460320.0, 6704920.0),
    (23460100.0, 6704680.0),
    (23459760.0, 6704450.0),
    (23459460.0, 6704240.0),
    (23459160.0, 6703940.0),
    (23458880.0, 6703660.0),
    (23458580.0, 6703440.0),
    (23458240.0, 6703180.0),
    (23457860.0, 6702960.0),
    (23457460.0, 6702820.0),
]

# GK23 -> WGS84 (Krüger inverse via Newton, matching scripts/data/gk23.gd)
_A = 6378137.0
_F = 1.0 / 298.257222101
_LON0 = 23.0
_E0 = 23500000.0
_HALF_C = math.pi * 6378137.0


def gk23_forward(lat, lon):
    n = _F / (2.0 - _F)
    n2, n3 = n * n, n * n * n
    big_a = _A / (1.0 + n) * (1.0 + n2 / 4.0 + n2 * n2 / 64.0)
    alpha = [
        n / 2.0 - 2.0 * n2 / 3.0 + 5.0 * n3 / 16.0,
        13.0 * n2 / 48.0 - 3.0 * n3 / 5.0,
        61.0 * n3 / 240.0,
    ]
    phi = math.radians(lat)
    dl = math.radians(lon - _LON0)
    c = 2.0 * math.sqrt(n) / (1.0 + n)
    t = math.sinh(math.atanh(math.sin(phi)) - c * math.atanh(c * math.sin(phi)))
    xi = math.atan2(t, math.cos(dl))
    eta = math.atanh(math.sin(dl) / math.sqrt(1.0 + t * t))
    e, nn = eta, xi
    for j in range(3):
        k = 2.0 * (j + 1)
        e += alpha[j] * math.cos(k * xi) * math.sinh(k * eta)
        nn += alpha[j] * math.sin(k * xi) * math.cosh(k * eta)
    return (_E0 + big_a * e, big_a * nn)


def gk23_to_latlon(e, n):
    lat = 60.45 + (n - 6704000.0) / 111400.0
    lon = _LON0 + (e - _E0) / (111320.0 * math.cos(math.radians(lat)))
    for _ in range(5):
        p = gk23_forward(lat, lon)
        d = 1e-6
        pl = gk23_forward(lat + d, lon)
        po = gk23_forward(lat, lon + d)
        a, b = (pl[0] - p[0]) / d, (po[0] - p[0]) / d
        c, dd = (pl[1] - p[1]) / d, (po[1] - p[1]) / d
        det = a * dd - b * c
        if abs(det) < 1e-9:
            break
        re, rn = e - p[0], n - p[1]
        lat += (dd * re - b * rn) / det
        lon += (-c * re + a * rn) / det
    return (lat, lon)


def latlon_to_3857(lat, lon):
    x = lon * _HALF_C / 180.0
    y = math.log(math.tan(math.pi / 4.0 + math.radians(lat) / 2.0)) * 6378137.0
    return (x, y)


def dist_to_aurajoki(e, n):
    best = 1e9
    for i in range(len(AURAJOKI_GK23) - 1):
        x1, y1 = AURAJOKI_GK23[i]
        x2, y2 = AURAJOKI_GK23[i + 1]
        dx, dy = x2 - x1, y2 - y1
        t = max(0.0, min(1.0, ((e - x1) * dx + (n - y1) * dy) / (dx * dx + dy * dy)))
        d = math.hypot(e - (x1 + t * dx), n - (y1 + t * dy))
        if d < best:
            best = d
    return best


def read_bmp(path):
    """Return (width, height, bytes_bgr_or_bgra, bpp, row_stride, top_down)."""
    with open(path, "rb") as f:
        data = f.read()
    if data[:2] != b"BM":
        return None
    offset = struct.unpack_from("<I", data, 10)[0]
    w, h = struct.unpack_from("<ii", data, 18)
    bpp = struct.unpack_from("<H", data, 28)[0]
    top_down = h < 0
    h = abs(h)
    ch = bpp // 8
    stride = ((w * ch + 3) // 4) * 4
    return (w, h, data[offset:], ch, stride, top_down)


def sample_bmp(bmp, u, v):
    """Sample (r, g, b) in 0..255 at normalized u, v in [0, 1] (v=0 top)."""
    w, h, buf, ch, stride, top_down = bmp
    px = max(0, min(w - 1, int(u * w)))
    py = max(0, min(h - 1, int(v * h)))
    row = py if top_down else (h - 1 - py)
    off = row * stride + px * ch
    if off + 3 > len(buf):
        return None
    b, g, r = buf[off], buf[off + 1], buf[off + 2]
    return (r, g, b)


def fetch_tile(tx, ty, tile_m=800.0, px=1024):
    os.makedirs(ORTHO_DIR, exist_ok=True)
    x0, y0 = tx * tile_m, ty * tile_m
    x1, y1 = x0 + tile_m, y0 + tile_m
    png_path = os.path.join(ORTHO_DIR, f"{tx}_{ty}.png")
    bmp_path = os.path.join(ORTHO_DIR, f"{tx}_{ty}.bmp")
    if not os.path.exists(bmp_path):
        if not os.path.exists(png_path):
            url = (
                f"{WMS_URL}?service=WMS&version=1.3.0&request=GetMap"
                f"&layers=Ilmakuva%202025&styles=&crs=EPSG:3857&format=image/png"
                f"&width={px}&height={px}&bbox={x0:.2f},{y0:.2f},{x1:.2f},{y1:.2f}"
            )
            subprocess.run(
                ["curl", "-fsSL", "--max-time", "60", "-H", "User-Agent: " + UA, url, "-o", png_path + ".tmp"],
                check=True,
            )
            os.replace(png_path + ".tmp", png_path)
        subprocess.run(
            ["sips", "-s", "format", "bmp", png_path, "--out", bmp_path],
            check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
        )
    return ((tx, ty), read_bmp(bmp_path))


def classify_roof_color(r, g, b, is_flat):
    # Clamp sunlit specular glare on aerial orthophotos so dark sheet-metal roofs
    # never wash out to chalky white when calibrated onto PBR sheet_metal.
    luma = 0.2126 * r + 0.7152 * g + 0.0722 * b
    if g > r * 1.07 and g > b * 1.02 and (g - r) >= 7:
        scale = min(1.0, 145.0 / max(luma, 1.0))
        return ("copper", f"#{int(r * scale):02x}{int(g * scale):02x}{int(b * scale):02x}")
    if r > g * 1.22 and r > b * 1.38 and r >= 85:
        scale = min(1.0, 150.0 / max(luma, 1.0))
        return ("terracotta", f"#{int(r * scale):02x}{int(g * scale):02x}{int(b * scale):02x}")
    if is_flat and luma >= 95 and abs(r - b) < 18:
        scale = min(1.0, 128.0 / max(luma, 1.0))
        return ("bitumen", f"#{int(r * scale):02x}{int(g * scale):02x}{int(b * scale):02x}")
    # Sheet metal: cap luminance to realistic Nordic painted/zinc roof albedo (#2e3238..#767c82)
    scale = min(1.0, 118.0 / max(luma, 1.0))
    return ("metal", f"#{int(r * scale):02x}{int(g * scale):02x}{int(b * scale):02x}")


def in_scope(e, n):
    """True inside Extended Inner City (1.8 km of Kauppatori) or within 150 m of Aurajoki."""
    if math.hypot(e - CENTRE_GK23[0], n - CENTRE_GK23[1]) <= INNER_RADIUS_M:
        return True
    return dist_to_aurajoki(e, n) <= CORRIDOR_M


def collect_corridor_buildings():
    buildings = {}
    for e0 in range(BOX_E_RANGE[0], BOX_E_RANGE[1], 500):
        for n0 in range(BOX_N_RANGE[0], BOX_N_RANGE[1], 500):
            fn = os.path.join(CACHE_BOXES, f"{e0}_{n0}.xml.gz")
            if not os.path.exists(fn):
                continue
            root = ET.fromstring(gzip.open(fn, "rb").read())
            for b in root.iter("{%s}Building" % NS["bldg"]):
                gid = b.get("{%s}id" % NS["gml"]) or ""
                if gid in buildings:
                    continue
                vtj = ""
                for a in b.findall("gen:stringAttribute", NS):
                    if a.get("name") == "pysyvarakennustunnus":
                        v = a.find("gen:value", NS)
                        vtj = (v.text or "").strip() if v is not None else ""
                pts_roof = []
                flat_like = True
                for rs in b.iter("{%s}RoofSurface" % NS["bldg"]):
                    for ring in rs.iter("{%s}LinearRing" % NS["gml"]):
                        coords = []
                        for pos in ring.findall("gml:pos", NS):
                            vals = (pos.text or "").split()
                            if len(vals) >= 3:
                                coords.append((float(vals[0]), float(vals[1]), float(vals[2])))
                        if len(coords) >= 4:
                            k = len(coords) - 1
                            cx = sum(p[0] for p in coords[:k]) / k
                            cy = sum(p[1] for p in coords[:k]) / k
                            zs = [p[2] for p in coords[:k]]
                            if max(zs) - min(zs) > 0.8:
                                flat_like = False
                            pts_roof.append((cx, cy))
                if not pts_roof:
                    continue
                ce = sum(p[0] for p in pts_roof) / len(pts_roof)
                cn = sum(p[1] for p in pts_roof) / len(pts_roof)
                if not in_scope(ce, cn):
                    continue
                key = vtj if vtj else gid
                buildings[gid] = {
                    "key": key,
                    "gid": gid,
                    "e": ce,
                    "n": cn,
                    "pts": pts_roof[:40],
                    "flat": flat_like,
                }
    return list(buildings.values())


def main():
    bldgs = collect_corridor_buildings()
    print(f"Found {len(bldgs)} buildings within {CORRIDOR_M:.0f} m of Aurajoki")
    tile_m = 800.0
    needed_tiles = set()
    bldg_3857 = []
    for b in bldgs:
        pts_m = []
        for pe, pn in b["pts"]:
            lat, lon = gk23_to_latlon(pe, pn)
            mx, my = latlon_to_3857(lat, lon)
            pts_m.append((mx, my))
            needed_tiles.add((math.floor(mx / tile_m), math.floor(my / tile_m)))
        bldg_3857.append((b, pts_m))
    print(f"Fetching/loading {len(needed_tiles)} Ilmakuva 2025 WMS tiles...")
    tiles = {}
    with concurrent.futures.ThreadPoolExecutor(max_workers=4) as ex:
        for k, bmp in ex.map(lambda t: fetch_tile(t[0], t[1], tile_m), sorted(needed_tiles)):
            if bmp is not None:
                tiles[k] = bmp
    out = {}
    for b, pts_m in bldg_3857:
        samples = []
        for mx, my in pts_m:
            tx, ty = math.floor(mx / tile_m), math.floor(my / tile_m)
            bmp = tiles.get((tx, ty))
            if bmp is None:
                continue
            u = (mx - tx * tile_m) / tile_m
            v = 1.0 - (my - ty * tile_m) / tile_m
            # Sample 3x3 small cross around each roof facet centroid
            for du, dv in ((0.0, 0.0), (0.002, 0.0), (-0.002, 0.0), (0.0, 0.002), (0.0, -0.002)):
                rgb = sample_bmp(bmp, u + du, v + dv)
                if rgb is None:
                    continue
                r, g, bl = rgb
                luma = 0.2126 * r + 0.7152 * g + 0.0722 * bl
                if 28 <= luma <= 242:
                    samples.append((luma, r, g, bl))
        if not samples:
            continue
        # Take 20%..55% luma band to reject both deep cast shadows and sun-glare slopes
        samples.sort(key=lambda s: s[0])
        lo = int(len(samples) * 0.20)
        hi = max(lo + 1, int(len(samples) * 0.55))
        lit = samples[lo:hi]
        rs = sorted(s[1] for s in lit)
        gs = sorted(s[2] for s in lit)
        bs = sorted(s[3] for s in lit)
        mid = len(lit) // 2
        mat, hex_col = classify_roof_color(rs[mid], gs[mid], bs[mid], b["flat"])
        out[b["key"]] = {
            "roof_material": mat,
            "roof_colour": hex_col,
            "samples": len(lit),
        }
    os.makedirs(os.path.dirname(OUT_PATH), exist_ok=True)
    with open(OUT_PATH, "w") as f:
        json.dump(
            {
                "source": WMS_URL + " (Ilmakuva 2025)",
                "licence": "CC BY 4.0, © City of Turku, orthophoto 2025",
                "buildings": out,
            },
            f,
            indent=1,
            sort_keys=True,
        )
    mats = {}
    for v in out.values():
        mats[v["roof_material"]] = mats.get(v["roof_material"], 0) + 1
    print(f"Sampled roofs for {len(out)}/{len(bldgs)} buildings -> {OUT_PATH}")
    print("Material breakdown:", mats)


if __name__ == "__main__":
    main()
