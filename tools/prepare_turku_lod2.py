#!/usr/bin/env python3
"""Per-building roof parameters from the City of Turku's LoD2 city model.

Turku serves its 3D city model (CC BY 4.0, "Turun kaupungin kaupunkitietomalli")
as CityGML 2.0 from its open WFS (layer bldg:Building_LOD2, GK23 / EPSG:3877,
gml:pos "E N Z"), one bldg:Building per building with its measured height,
storeys, VTJ building id (pysyvarakennustunnus) and boundary surfaces. This
tool reads the model box by box over a GK23 area, reduces each building's
RoofSurface polygons with prepare_helsinki_lod2.classify_roof:

  [vtj_prt, e, n, area_m2, height_m, roof_h_m, pitch_deg, ridge_az_deg,
   shape, storeys, start_year, use_code]

and writes 1 km cells to assets/city_models/turku_lod2/<E>_<N>.lod2 (zstd JSON)
with manifest.json, read by HelsinkiLod2 beside Helsinki's and Espoo's bundles.

Usage:
  tools/prepare_turku_lod2.py [--box E0,N0,E1,N1] [--workers 8]

The default box covers urban Turku (Castle, Ruissalo east, Hirvensalo north,
Port Arthur, Centre, Aurajoki, Kupittaa, Runosmäki, Varissuo). Answers are
kept gzipped in build/turku_lod2_boxes/ so a rerun only fetches what is new.
"""

import argparse
import concurrent.futures
import gzip
import hashlib
import json
import math
import os
import shutil
import subprocess
import sys
import xml.etree.ElementTree as ET

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from prepare_helsinki_lod2 import classify_roof, ROOF_MIN_UP  # noqa: E402

WFS = "https://turku.asiointi.fi/TeklaOGCWeb/WFS.ashx"
UA = "planet-render-360 data tool"
ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
OUT_DIR = os.path.join(ROOT, "assets", "city_models", "turku_lod2")
CACHE_DIR = os.path.join(ROOT, "build", "turku_lod2_boxes")
# GK23 (EPSG:3877): urban Turku 12 x 10 km (Castle/Ruissalo to Varissuo, Hirvensalo to Runosmäki)
DEFAULT_BOX = (23454000, 6700000, 23466000, 6710000)
BOX_M = 500
CELL_M = 1000
ZSTD_LEVEL = 19

NS = {
    "gml": "http://www.opengis.net/gml",
    "bldg": "http://www.opengis.net/citygml/building/2.0",
    "gen": "http://www.opengis.net/citygml/generics/2.0",
}

# Turku's CityGML 2.0 bldg:function uses 4-digit ALKIS/CityGML codes alongside
# pass-through 3-digit Finnish VTJ 1994 codes. Normalise the 4-digit codes to
# VTJ 1994 strings so RegisterCodes.kind_for() resolves them uniformly.
CITYGML_TO_VTJ = {
    "1000": "011",  # residential / house
    "1010": "032",  # apartments / tenement
    "1020": "151",  # office
    "1050": "111",  # retail / department store
    "1070": "141",  # commercial / restaurant
    "1100": "041",  # holiday cabin
    "1240": "121",  # hotel
    "1310": "711",  # warehouse (or 611 industrial when bldg:class in 691/692/699)
    "1360": "931",  # shed / outbuilding
    "1700": "711",  # storage / warehouse
    "1760": "899",  # farm / agricultural
    "1940": "899",  # farm / boathouse
    "2070": "511",  # school
    "2120": "311",  # civic / library / cultural
    "2210": "341",  # church
    "2300": "221",  # civic / social / daycare
    "2340": "211",  # hospital
    "2410": "721",  # fire_station
    "2440": "722",  # civic (prison / institutional)
    "2550": "351",  # sports_hall
}


def fetch(e, n, offline=False):
    """The box's GML (bytes), cached gzipped; None when unavailable."""
    path = os.path.join(CACHE_DIR, "%d_%d.xml.gz" % (e, n))
    if os.path.exists(path):
        with gzip.open(path, "rb") as f:
            return f.read()
    if offline:
        return None
    url = "%s?service=WFS&version=1.1.0&request=GetFeature&typeName=bldg:Building_LOD2&bbox=%d,%d,%d,%d" % (
        WFS, e, n, e + BOX_M, n + BOX_M)
    data = None
    for _ in range(3):
        try:
            res = subprocess.run(
                ["curl", "-fsS", "--max-time", "90", "-H", "User-Agent: " + UA, url],
                capture_output=True, check=True,
            )
            data = res.stdout
            break
        except Exception:  # noqa: BLE001
            data = None
    if not data or b"FeatureCollection" not in data[:2000]:
        return None
    os.makedirs(CACHE_DIR, exist_ok=True)
    with gzip.open(path + ".tmp", "wb") as f:
        f.write(data)
    os.replace(path + ".tmp", path)
    return data


def facet(points):
    """(area, pitch, aspect, x, y, z_min) of a 3D ring, or None for a wall."""
    nx = ny = nz = 0.0
    for i in range(len(points) - 1):
        x0, y0, z0 = points[i]
        x1, y1, z1 = points[i + 1]
        nx += (y0 - y1) * (z0 + z1)
        ny += (z0 - z1) * (x0 + x1)
        nz += (x0 - x1) * (y0 + y1)
    ln = math.sqrt(nx * nx + ny * ny + nz * nz)
    if ln < 1e-9:
        return None
    if nz < 0.0:
        nx, ny, nz = -nx, -ny, -nz
    nx, ny, nz = nx / ln, ny / ln, nz / ln
    if nz < ROOF_MIN_UP:
        return None
    area = ln * 0.5
    k = len(points) - 1
    cx = sum(p[0] for p in points[:k]) / k
    cy = sum(p[1] for p in points[:k]) / k
    pitch = math.degrees(math.acos(max(-1.0, min(1.0, nz))))
    aspect = math.degrees(math.atan2(nx, ny)) % 360.0
    return (area, pitch, aspect, cx, cy, min(p[2] for p in points))


def rings(elem):
    for ring in elem.iter("{%s}LinearRing" % NS["gml"]):
        pts = []
        for pos in ring.findall("gml:pos", NS):
            v = (pos.text or "").split()
            if len(v) >= 3:
                pts.append((float(v[0]), float(v[1]), float(v[2])))
        if len(pts) >= 4:
            yield pts


def attribute(b, name):
    for a in b.findall("gen:stringAttribute", NS):
        if a.get("name") == name:
            v = a.find("gen:value", NS)
            return (v.text or "").strip() if v is not None else ""
    return ""


def parse_year(b):
    """Completion year (1700..2100) from yearOfConstruction or valmistunut, else 0."""
    yc = b.find("bldg:yearOfConstruction", NS)
    raw = (yc.text or "").strip() if yc is not None else ""
    if not raw:
        raw = attribute(b, "valmistunut")
    if not raw:
        return 0
    # Accept "1927", "1927-01-01", or Finnish "01.01.1927".
    for candidate in (raw[:4], raw[-4:]):
        if len(candidate) == 4 and candidate.isdigit():
            y = int(candidate)
            if 1700 <= y <= 2100:
                return y
    return 0


def parse_use_code(b):
    """Normalised VTJ 1994 3-digit use code from bldg:function / käyttötarkoitus, else ''."""
    fn = b.find("bldg:function", NS)
    raw = (fn.text or "").strip() if fn is not None else ""
    if not raw or raw == "0":
        kt = attribute(b, "käyttötarkoitus")
        if kt and kt.lower() != "ei arvoa" and kt != "0":
            raw = kt
        else:
            return ""
    if raw in CITYGML_TO_VTJ:
        if raw == "1310":
            cl = b.find("bldg:class", NS)
            cls = (cl.text or "").strip() if cl is not None else ""
            if cls in ("691", "692", "699"):
                return "611"
        return CITYGML_TO_VTJ[raw]
    if len(raw) == 3 and raw.isdigit() and raw != "999":
        return raw
    return ""


def analyse(data):
    """{gml id: row} of the buildings in one box's GML."""
    out = {}
    try:
        root = ET.fromstring(data)
    except ET.ParseError:
        return out
    for b in root.iter("{%s}Building" % NS["bldg"]):
        gid = b.get("{%s}id" % NS["gml"]) or ""
        roof = []
        zmin = math.inf
        top = -math.inf
        for kind in ("RoofSurface", "WallSurface", "GroundSurface"):
            for surf in b.iter("{%s}%s" % (NS["bldg"], kind)):
                for pts in rings(surf):
                    zs = [p[2] for p in pts]
                    zmin = min(zmin, min(zs))
                    top = max(top, max(zs))
                    if kind == "RoofSurface":
                        f = facet(pts)
                        if f:
                            roof.append(f)
        if not roof or not math.isfinite(zmin):
            continue
        plan = sum(a * math.cos(math.radians(p)) for a, p, *_ in roof)
        if plan < 4.0:
            continue
        w = sum(r[0] for r in roof)
        e = sum(r[0] * r[3] for r in roof) / w
        n = sum(r[0] * r[4] for r in roof) / w
        height = 0.0
        mh = b.find("bldg:measuredHeight", NS)
        if mh is not None and mh.text:
            try:
                height = float(mh.text)
            except ValueError:
                height = 0.0
        if height <= 0.5:
            height = top - zmin
        storeys = 0
        st = b.find("bldg:storeysAboveGround", NS)
        if st is not None and st.text and st.text.strip().isdigit():
            storeys = int(st.text.strip())
            storeys = storeys if 0 < storeys < 200 else 0
        if storeys == 0:
            kl = attribute(b, "kerrosluku")
            if kl.isdigit():
                v = int(kl)
                storeys = v if 0 < v < 200 else 0
        shape, pitch, ridge_az, roof_h = classify_roof(roof, top)
        start_year = parse_year(b)
        use_code = parse_use_code(b)
        out[gid] = [attribute(b, "pysyvarakennustunnus"), round(e, 1), round(n, 1), round(plan, 1),
                    round(height, 2), round(roof_h, 2), round(pitch, 1), round(ridge_az, 1), shape, storeys,
                    start_year, use_code]
    return out


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
        cells.setdefault("%d_%d" % (int(e // CELL_M), int(n // CELL_M)), []).append(row)
    for key, cell_rows in sorted(cells.items()):
        cell_rows.sort(key=lambda r: (r[2], r[1]))
        payload = json.dumps({"rows": cell_rows}, separators=(",", ":"), ensure_ascii=False).encode("utf-8")
        with open(os.path.join(OUT_DIR, key + ".lod2"), "wb") as f:
            f.write(zstd(payload))
        manifest[key] = [len(payload), hashlib.sha256(payload).hexdigest(), len(cell_rows)]
    with open(manifest_path, "w") as f:
        json.dump({"source": WFS + " (bldg:Building_LOD2)",
                   "licence": "CC BY 4.0, © City of Turku, 3D city model",
                   "crs": "EPSG:3877",
                   "columns": ["vtj_prt", "e", "n", "area_m2", "height_m", "roof_h_m", "pitch_deg",
                               "ridge_az_deg", "shape", "storeys", "start_year", "use_code"],
                   "cell_m": CELL_M, "cells": dict(sorted(manifest.items()))}, f, indent=1)
    return cells


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--box", default=",".join(str(v) for v in DEFAULT_BOX),
                    help="GK23 E0,N0,E1,N1 in metres (whole km)")
    ap.add_argument("--workers", type=int, default=8)
    ap.add_argument("--offline", action="store_true",
                    help="Read only cached boxes in build/turku_lod2_boxes/; never make network calls")
    args = ap.parse_args()
    box = tuple(int(v) for v in args.box.split(","))
    if len(box) != 4 or box[0] >= box[2] or box[1] >= box[3] or any(v % CELL_M for v in box):
        sys.exit("--box needs E0,N0,E1,N1 in whole km")
    boxes = [(e, n) for e in range(box[0], box[2], BOX_M) for n in range(box[1], box[3], BOX_M)]
    print("%d boxes of %d m" % (len(boxes), BOX_M), flush=True)
    found = {}
    done = 0

    def work(item):
        data = fetch(*item, offline=args.offline)
        return analyse(data) if data else {}

    with concurrent.futures.ThreadPoolExecutor(max_workers=max(1, args.workers)) as pool:
        for got in pool.map(work, boxes):
            found.update(got)
            done += 1
            if done % 60 == 0 or done == len(boxes):
                print("  %d / %d boxes, %d buildings" % (done, len(boxes), len(found)), flush=True)
    cells = write_cells(list(found.values()), box)
    shapes = {}
    for r in found.values():
        shapes[r[8]] = shapes.get(r[8], 0) + 1
    print("%d buildings in %d cells; shapes %s" % (sum(len(c) for c in cells.values()), len(cells), shapes), flush=True)


if __name__ == "__main__":
    main()
