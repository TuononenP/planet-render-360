#!/usr/bin/env python3
"""List the named bridges in the bundled OSM snapshots, with measured geometry.

Offline. Reads assets/osm_snapshots/<prefix>_{detailed,far}.json.gz (Overpass
shaped, `out geom`) and prints one JSON line per named bridge: the centre of the
deck, its true bearing (compass degrees, principal axis of the ways with that
name), its length, and the OSM tags that matter (bridge, bridge:structure,
layer, width, lanes, highway/railway, whether it crosses water).

    tools/bridge_candidates.py capital_hu_47.4979_19.0402
    tools/bridge_candidates.py paris --min-length 60

The prefix is a snapshot name without the layer suffix. The figures seed the
tables in scripts/data/bridges/; a bridge outside the snapshot's extent is not
listed and is authored from published figures instead.
"""
import argparse
import glob
import gzip
import json
import math
import os
import sys

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "osm_snapshots")
KEEP_TAGS = ("bridge", "bridge:structure", "bridge:movable", "layer", "width", "lanes",
             "highway", "railway", "man_made", "wikidata", "wikipedia", "material")


def load(path):
    with gzip.open(path, "rt", encoding="utf-8") as f:
        return json.load(f).get("elements", [])


def metres(lat0, p):
    """Local east/north metres of p=(lat, lon) about lat0."""
    return ((p[1]) * 111320.0 * math.cos(math.radians(lat0)), p[0] * 110540.0)


def principal_bearing(points):
    """True bearing in 0..180 degrees of the long axis of the points."""
    if len(points) < 2:
        return 0.0
    lat0 = sum(p[0] for p in points) / len(points)
    xy = [metres(lat0, p) for p in points]
    mx = sum(p[0] for p in xy) / len(xy)
    my = sum(p[1] for p in xy) / len(xy)
    sxx = sum((p[0] - mx) ** 2 for p in xy)
    syy = sum((p[1] - my) ** 2 for p in xy)
    sxy = sum((p[0] - mx) * (p[1] - my) for p in xy)
    theta = 0.5 * math.atan2(2 * sxy, sxx - syy)  # from east, counter-clockwise
    bearing = 90.0 - math.degrees(theta)
    return bearing % 180.0


def extent(points, bearing):
    """(length, cross, centre) of the points along / across a compass bearing:
    the deck length and centre-line spread, not the sum of parallel ways."""
    lat0 = sum(p[0] for p in points) / len(points)
    lon0 = sum(p[1] for p in points) / len(points)
    b = math.radians(bearing)
    ax, ay = math.sin(b), math.cos(b)  # east, north unit vector of the axis
    along, across = [], []
    for p in points:
        x = (p[1] - lon0) * 111320.0 * math.cos(math.radians(lat0))
        y = (p[0] - lat0) * 110540.0
        along.append(x * ax + y * ay)
        across.append(-x * ay + y * ax)
    mid = (max(along) + min(along)) / 2
    cmid = (max(across) + min(across)) / 2
    clat = lat0 + (mid * ay - cmid * ax) / 110540.0
    clon = lon0 + (mid * ax + cmid * ay) / (111320.0 * math.cos(math.radians(lat0)))
    return max(along) - min(along), max(across) - min(across), (clat, clon)


def way_length(points):
    total = 0.0
    for a, b in zip(points, points[1:]):
        lat0 = (a[0] + b[0]) / 2
        dx = (b[1] - a[1]) * 111320.0 * math.cos(math.radians(lat0))
        dy = (b[0] - a[0]) * 110540.0
        total += math.hypot(dx, dy)
    return total


def water_ways(elements):
    """Bounding boxes of waterways / water polygons, to test a crossing."""
    boxes = []
    for e in elements:
        t = e.get("tags", {})
        if e.get("type") != "way" or "geometry" not in e:
            continue
        if t.get("waterway") in ("river", "canal", "riverbank", "dock") or t.get("natural") == "water" \
                or t.get("water") in ("river", "lake", "canal", "reservoir"):
            g = [(n["lat"], n["lon"]) for n in e["geometry"]]
            boxes.append((min(p[0] for p in g), min(p[1] for p in g), max(p[0] for p in g), max(p[1] for p in g)))
    return boxes


def candidates(prefix, min_length):
    out = {}
    water = []
    for layer in ("detailed", "far"):
        path = os.path.join(ROOT, "%s_%s.json.gz" % (prefix, layer))
        if not os.path.exists(path):
            continue
        elements = load(path)
        water += water_ways(elements)
        for e in elements:
            t = e.get("tags", {})
            if e.get("type") != "way" or "geometry" not in e:
                continue
            if t.get("bridge") in (None, "no") and t.get("man_made") != "bridge":
                continue
            name = t.get("name") or t.get("bridge:name")
            if not name:
                continue
            g = [(n["lat"], n["lon"]) for n in e["geometry"]]
            rec = out.setdefault(name, {"points": [], "length": 0.0, "tags": {}, "ways": 0, "layer": layer})
            rec["points"] += g
            rec["length"] += way_length(g)
            rec["ways"] += 1
            for k in KEEP_TAGS:
                if k in t and k not in rec["tags"]:
                    rec["tags"][k] = t[k]
    rows = []
    for name, rec in out.items():
        pts = rec["points"]
        if rec["length"] < min_length:
            continue
        bearing = principal_bearing(pts)
        length, cross, (lat, lon) = extent(pts, bearing)
        over_water = any(b[0] - 0.0002 <= lat <= b[2] + 0.0002 and b[1] - 0.0003 <= lon <= b[3] + 0.0003
                         for b in water)
        rows.append({"name": name, "lat": round(lat, 5), "lon": round(lon, 5),
                     "bearing": round(bearing, 1), "length_m": round(length), "cross_m": round(cross),
                     "ways": rec["ways"], "layer": rec["layer"], "over_water": over_water,
                     "tags": rec["tags"]})
    rows.sort(key=lambda r: -r["length_m"])
    return rows


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("prefix", help="snapshot name without the layer suffix, or a glob such as 'capital_hu_*'")
    ap.add_argument("--min-length", type=float, default=40.0, help="shortest bridge to list, metres")
    ap.add_argument("--water-only", action="store_true", help="only bridges that cross mapped water")
    args = ap.parse_args()
    prefixes = sorted({os.path.basename(p).rsplit("_", 1)[0] for p in glob.glob(
        os.path.join(ROOT, args.prefix + "_*.json.gz"))})
    if not prefixes:
        print("no snapshot matches %r in %s" % (args.prefix, os.path.normpath(ROOT)), file=sys.stderr)
        return 1
    for prefix in prefixes:
        if prefix.endswith(("_poi", "_ring1600", "_ring2500")):
            continue
        for row in candidates(prefix, args.min_length):
            if args.water_only and not row["over_water"]:
                continue
            row["snapshot"] = prefix
            print(json.dumps(row, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    sys.exit(main())
