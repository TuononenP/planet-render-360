#!/usr/bin/env python3
"""Validate a cached Overpass response and write it as a BundledOsm .osmb snapshot.

Prints the payload size and SHA-256 its manifest row records (tools/osmb.py).
"""
import argparse
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import osmb  # noqa: E402

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("layer", choices=("detailed", "detailed-extract", "far", "ring", "poi", "transit", "horizon"))
parser.add_argument("source", type=Path, help="current-query cache JSON")
parser.add_argument("destination", type=Path, help="snapshot .osmb")
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
if args.destination.suffix != ".osmb":
    raise SystemExit("destination must be an .osmb file")
args.destination.parent.mkdir(parents=True, exist_ok=True)
size, sha = osmb.write_osmb(data, str(args.destination))
print(f"timestamp={stamp} bytes={size} sha256={sha} "
      f"elements={len(elements)} buildings={buildings} file_bytes={args.destination.stat().st_size}")
