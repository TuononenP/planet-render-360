#!/usr/bin/env python3
"""Validate and gzip a cached Overpass response for BundledOsm."""
import argparse
import gzip
import hashlib
import json
from pathlib import Path

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("layer", choices=("detailed", "far"))
parser.add_argument("source", type=Path, help="current-query cache JSON")
parser.add_argument("destination", type=Path, help="snapshot .json.gz")
args = parser.parse_args()
raw = args.source.read_bytes()
data = json.loads(raw)
elements = data.get("elements")
if data.get("remark") or not isinstance(elements, list) or not elements:
    raise SystemExit("incomplete or invalid Overpass response")
stamp = data.get("osm3s", {}).get("timestamp_osm_base", "")
if not stamp:
    raise SystemExit("missing Overpass source timestamp")
buildings = sum("building" in el.get("tags", {}) and bool(el.get("geometry") or el.get("members"))
                for el in elements)
if not buildings:
    raise SystemExit("no mapped buildings")
if args.layer == "detailed":
    if not any(el.get("type") == "pr360_q12" for el in elements):
        raise SystemExit("detailed response is not query q12")
    if not any("highway" in el.get("tags", {}) and el.get("geometry") for el in elements):
        raise SystemExit("detailed highway geometry missing")
    if not any(el.get("type") == "area" and "ISO3166-1" in el.get("tags", {}) for el in elements):
        raise SystemExit("country statement missing: response may be incomplete")
else:
    if not any("landuse" in el.get("tags", {}) for el in elements):
        raise SystemExit("far-city landuse missing")
args.destination.parent.mkdir(parents=True, exist_ok=True)
with args.destination.open("wb") as out:
    with gzip.GzipFile(fileobj=out, mode="wb", filename="", mtime=0) as zipped:
        zipped.write(raw)
print(f"timestamp={stamp} bytes={len(raw)} sha256={hashlib.sha256(raw).hexdigest()} "
      f"elements={len(elements)} buildings={buildings} gzip_bytes={args.destination.stat().st_size}")
