#!/usr/bin/env python3
"""Validate and gzip a cached Overpass response for BundledOsm."""
import argparse
import gzip
import hashlib
import json
from pathlib import Path

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("layer", choices=("detailed", "detailed-extract", "far", "ring", "poi", "transit", "horizon"))
parser.add_argument("source", type=Path, help="current-query cache JSON")
parser.add_argument("destination", type=Path, help="snapshot .json.gz")
parser.add_argument("--allow-sparse", action="store_true", help="accept empty optional layers in a verified rural extract")
args = parser.parse_args()
if args.allow_sparse and args.layer in ("detailed", "detailed-extract"):
    raise SystemExit("sparse mode is only for optional layers")
raw = args.source.read_bytes()
data = json.loads(raw)
elements = data.get("elements")
if data.get("remark") or not isinstance(elements, list) or (not elements and not args.allow_sparse):
    raise SystemExit("incomplete or invalid Overpass response")
stamp = data.get("osm3s", {}).get("timestamp_osm_base", "")
if not stamp:
    raise SystemExit("missing Overpass source timestamp")
buildings = sum("building" in el.get("tags", {}) and bool(el.get("geometry") or el.get("members"))
                for el in elements)
if args.layer in ("detailed", "far") and not buildings and not args.allow_sparse:
    raise SystemExit("no mapped buildings")
if args.layer == "detailed":
    if not any(el.get("type") == "pr360_q12" for el in elements):
        raise SystemExit("detailed response is not query q12")
    if not any("highway" in el.get("tags", {}) and el.get("geometry") for el in elements):
        raise SystemExit("detailed highway geometry missing")
    if not any(el.get("type") == "area" and "ISO3166-1" in el.get("tags", {}) for el in elements):
        raise SystemExit("country statement missing: response may be incomplete")
elif args.layer == "detailed-extract":
    if data.get("generator") != "Planet Render 360 OSM extract conversion":
        raise SystemExit("not a known extract-derived payload")
    if not buildings and not any(any(k in el.get("tags", {}) for k in ("waterway", "natural")) for el in elements):
        raise SystemExit("no buildings or natural features")
    if not any(el.get("type") == "area" and "ISO3166-1" in el.get("tags", {}) for el in elements):
        raise SystemExit("country metadata missing")
elif args.layer == "far":
    if not args.allow_sparse and not any("landuse" in el.get("tags", {}) for el in elements):
        raise SystemExit("far-city landuse missing")
elif args.layer == "ring":
    if not args.allow_sparse and not any("highway" in el.get("tags", {}) and el.get("geometry") for el in elements):
        raise SystemExit("ring highway geometry missing")
elif args.layer == "horizon":
    # Optional labels: an empty list (open sea) is valid, a nameless or unplaced row is not.
    for el in elements:
        if not el.get("tags", {}).get("name") or not ("lat" in el or "center" in el):
            raise SystemExit("horizon row without a name or a position")
elif args.layer == "transit":
    stop_tags = (("railway", "tram_stop"), ("highway", "bus_stop"), ("railway", "station"), ("railway", "halt"),
                 ("railway", "platform"), ("public_transport", "stop_position"), ("public_transport", "platform"))
    if not args.allow_sparse and not any(any(el.get("tags", {}).get(k) == v for k, v in stop_tags) for el in elements):
        raise SystemExit("no transit stops, stations or platforms")
elif args.layer == "poi" and not args.allow_sparse and not any(any(k in el.get("tags", {}) for k in ("shop", "amenity", "office", "tourism", "craft", "advertising")) for el in elements):
    raise SystemExit("POI tags missing")
args.destination.parent.mkdir(parents=True, exist_ok=True)
with args.destination.open("wb") as out:
    with gzip.GzipFile(fileobj=out, mode="wb", filename="", mtime=0) as zipped:
        zipped.write(raw)
print(f"timestamp={stamp} bytes={len(raw)} sha256={hashlib.sha256(raw).hexdigest()} "
      f"elements={len(elements)} buildings={buildings} gzip_bytes={args.destination.stat().st_size}")
