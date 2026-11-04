#!/usr/bin/env python3
"""Build preset ring, POI and far-city payloads from an OSM PBF extract.

Requires pyosmium. The extract must cover the complete 12 km disc, or 2.5 km with
--near-only (including referenced ways/nodes) and its source replication timestamp is supplied by the
caller. Results use the app's existing Overpass JSON geometry format and query
caps. Spatial matching uses a local metre projection and segment distances.
"""
import argparse
import json
import math
import re
from pathlib import Path

import osmium

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("pbf", type=Path)
parser.add_argument("city", choices=("new_york", "san_francisco"))
parser.add_argument("timestamp", help="source replication timestamp in UTC")
parser.add_argument("output", type=Path)
parser.add_argument("--near-only", action="store_true", help="omit far city for a smaller complete extract")
parser.add_argument("--coverage", nargs=4, type=float, required=True, metavar=("WEST", "SOUTH", "EAST", "NORTH"),
                    help="bounds of the source extract before conversion")
args = parser.parse_args()
lat, lon = {"new_york": (40.7060, -74.0040), "san_francisco": (37.8040, -122.4195)}[args.city]
lat_scale = 111195.0
lon_scale = lat_scale * math.cos(math.radians(lat))
radius = 2500 if args.near_only else 12000
west, south, east, north = args.coverage
if west > lon - radius / lon_scale or east < lon + radius / lon_scale or \
        south > lat - radius / lat_scale or north < lat + radius / lat_scale:
    raise SystemExit("source bounds do not cover the required radius")
landuses = {"residential", "commercial", "industrial", "retail"}
highways = {"motorway", "trunk", "primary", "secondary", "tertiary"}
poi_keys = {"shop", "amenity", "office", "tourism", "craft", "advertising"}


def point_dist2(x, y, ax, ay, bx, by):
    dx, dy = bx - ax, by - ay
    if dx == 0 and dy == 0:
        return (x - ax) ** 2 + (y - ay) ** 2
    t = max(0.0, min(1.0, ((x - ax) * dx + (y - ay) * dy) / (dx * dx + dy * dy)))
    return (x - ax - t * dx) ** 2 + (y - ay - t * dy) ** 2


def near(geometry, radius):
    points = [((p["lon"] - lon) * lon_scale, (p["lat"] - lat) * lat_scale) for p in geometry]
    if any(x*x + y*y <= radius*radius for x, y in points):
        return True
    return any(point_dist2(0, 0, *a, *b) <= radius*radius for a, b in zip(points, points[1:]))


def tall(tags):
    try:
        if float(tags.get("building:levels", "0")) >= 15:
            return True
    except ValueError:
        pass
    raw = tags.get("height", "").strip()
    feet = re.search(r"(?:ft|')\s*$", raw, re.I)
    try:
        height = float(re.sub(r"(?:ft|')\s*$", "", raw, flags=re.I))
        return height * (0.3048 if feet else 1.0) >= 50
    except ValueError:
        return False


class Relations(osmium.SimpleHandler):
    def __init__(self):
        super().__init__()
        self.relations = []
        self.ways = set()

    def relation(self, rel):
        tags = dict(rel.tags)
        if tags.get("type") != "multipolygon" or not (
                tags.get("landuse") in landuses or "building" in tags or "building:part" in tags):
            return
        members = [(m.ref, m.role) for m in rel.members if m.type == "w"]
        if members:
            self.relations.append((rel.id, tags, members))
            self.ways.update(ref for ref, _ in members)


class Features(osmium.SimpleHandler):
    def __init__(self, member_ids):
        super().__init__()
        self.member_ids = member_ids
        self.member_geometry = {}
        self.ways = []
        self.pois = []
        self.missing = 0

    def node(self, node):
        tags = dict(node.tags)
        if poi_keys.intersection(tags) and node.location.valid():
            geometry = [{"lat": node.location.lat, "lon": node.location.lon}]
            if near(geometry, 800):
                self.pois.append({"type": "node", "id": node.id, "lat": node.location.lat,
                                  "lon": node.location.lon, "tags": tags})

    def way(self, way):
        tags = dict(way.tags)
        if way.id not in self.member_ids and not (
                tags.get("highway") in highways or "waterway" in tags or
                tags.get("natural") == "coastline" or tags.get("landuse") in landuses or
                "building" in tags or "building:part" in tags):
            return
        try:
            geometry = [{"lat": n.location.lat, "lon": n.location.lon} for n in way.nodes]
        except osmium.InvalidLocationError:
            self.missing += 1
            return
        if way.id in self.member_ids:
            self.member_geometry[way.id] = geometry
        if tags and geometry and near(geometry, 12000):
            self.ways.append({"type": "way", "id": way.id, "tags": tags, "geometry": geometry})


rels = Relations()
if not args.near_only:
    rels.apply_file(str(args.pbf))
features = Features(rels.ways)
features.apply_file(str(args.pbf), locations=True)
if features.missing:
    raise SystemExit(f"{features.missing} ways have missing nodes; use a complete extract")
relations = []
for ident, tags, members in rels.relations:
    if any(ref not in features.member_geometry for ref, _ in members):
        known = [features.member_geometry[ref] for ref, _ in members if ref in features.member_geometry]
        if any(near(geometry, 12000) for geometry in known):
            raise SystemExit(f"relation {ident} near the view has missing member geometry")
        continue
    ways = [{"type": "way", "ref": ref, "role": role, "geometry": features.member_geometry[ref]}
            for ref, role in members]
    if any(near(m["geometry"], 12000) for m in ways):
        relations.append({"type": "relation", "id": ident, "tags": tags, "members": ways})


def in_radius(item, radius):
    if item["type"] == "way":
        return near(item["geometry"], radius)
    return any(near(m["geometry"], radius) for m in item["members"])


def order(items):
    return sorted(items, key=lambda item: (0 if item["type"] == "way" else 1, item["id"]))


def write(layer, elements):
    doc = {"version": 0.6, "generator": "Planet Render 360 OSM extract conversion",
           "osm3s": {"timestamp_osm_base": args.timestamp,
                     "copyright": "© OpenStreetMap contributors, ODbL"}, "elements": elements}
    path = args.output / f"{args.city}_{layer}.json"
    path.write_text(json.dumps(doc, separators=(",", ":")), encoding="utf-8")
    print(layer, len(elements), path.stat().st_size, flush=True)

args.output.mkdir(parents=True, exist_ok=True)
write("poi", sorted(features.pois, key=lambda e: e["id"])[:2500])
for radius in (1600, 2500):
    roads = [w for w in features.ways if w["tags"].get("highway") in highways and in_radius(w, radius)]
    waterways = [w for w in features.ways if "waterway" in w["tags"] and in_radius(w, radius)]
    coast = [w for w in features.ways if w["tags"].get("natural") == "coastline" and in_radius(w, radius)]
    write(f"ring{radius}", order(roads)[:800] + order(waterways)[:150] + order(coast)[:100])
if args.near_only:
    raise SystemExit(0)
ways = features.ways
land_ways = order([w for w in ways if w["tags"].get("landuse") in landuses])[:6000]
land_relations = order([r for r in relations if r["tags"].get("landuse") in landuses])[:400]
towers = [e for e in ways + relations if ("building" in e["tags"] or "building:part" in e["tags"]) and tall(e["tags"])]
parts = [e for e in ways + relations if "building:part" in e["tags"]]
far = land_ways + land_relations + order([e for e in towers if in_radius(e, 4000)])[:6000] + order(towers)[:12000]
far += order([e for e in parts if in_radius(e, 4000)])[:8000] + order(parts)[:12000]
write("far", far)
