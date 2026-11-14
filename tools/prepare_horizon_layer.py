#!/usr/bin/env python3
"""Build the bundled horizon layer (HorizonFetcher) of every preset and capital.

HorizonFetcher.build_query asks Overpass for the named peaks, towns and lakes
around a place. This asks Postpass (postpass.geofabrik.de, a PostGIS copy of
OSM) the same thing, one request per place, and writes the answer in the
Overpass `out tags center` shape: a node keeps its position, a lake way or
relation gets the centre of its bounding box, as Overpass gives it. Only the
tags HorizonFetcher.parse reads are kept. Each answer is validated and written as .osmb
by prepare_osm_snapshot.py, and its row goes into
assets/osm_snapshots/horizon_manifest.json.

    python3 -I tools/prepare_horizon_layer.py --all
    python3 -I tools/prepare_horizon_layer.py helsinki capital_fi

Places are the `<name>_detailed` rows of BundledOsm.ENTRIES and of the capital
manifest, at exactly their coordinates. Answers are kept in --work so a failed
place can be retried alone (--no-fetch reuses them).
"""
import argparse
import json
import math
import re
import subprocess
import sys
import tempfile
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ASSETS = ROOT / "assets/osm_snapshots"
MANIFEST = ASSETS / "horizon_manifest.json"
URL = "https://postpass.geofabrik.de/api/interpreter"  # PostpassFallback.URL
QUERY_VERSION = 1  # HorizonFetcher.QUERY_VERSION
RADIUS_PEAK_M = 45000  # HorizonFetcher.RADIUS_PEAK_M
RADIUS_TOWN_M = 30000  # HorizonFetcher.RADIUS_TOWN_M
RADIUS_LAKE_M = 20000  # HorizonFetcher.RADIUS_LAKE_M
CAP = 1500  # HorizonFetcher.CAP
KEEP_TAGS = ("name", "natural", "place", "water", "ele")
USER_AGENT = "PlanetRender360-snapshot-tool/1.0"
TYPES = {"N": "node", "W": "way", "R": "relation"}


def places() -> dict:
    """name -> (lat text, lon text) of every preset and capital detailed row."""
    text = (ROOT / "scripts/data/bundled_osm.gd").read_text()
    out = {name: (lat, lon) for name, lat, lon in
           re.findall(r'"([a-z0-9_]+)_detailed": \[(-?[\d.]+), (-?[\d.]+), "detailed', text)}
    capitals = json.loads((ASSETS / "capital_manifest.json").read_text())
    for key, row in capitals.items():
        if key.endswith("_detailed"):
            out[key[: -len("_detailed")]] = (repr(row[0]), repr(row[1]))
    return out


def sql(lat: float, lon: float) -> str:
    dlat = RADIUS_PEAK_M / 111320.0
    dlon = RADIUS_PEAK_M / (111320.0 * max(math.cos(math.radians(lat)), 0.01))
    here = f"ST_SetSRID(ST_MakePoint({lon:.6f},{lat:.6f}),4326)::geography"
    return (
        "SELECT osm_type, osm_id, tags, ST_Centroid(ST_Envelope(geom)) AS geom FROM postpass_pointlinepolygon"
        f" WHERE geom && ST_MakeEnvelope({lon - dlon:.6f},{lat - dlat:.6f},{lon + dlon:.6f},{lat + dlat:.6f},4326)"
        " AND tags ? 'name' AND ("
        f"(osm_type = 'N' AND tags->>'natural' = 'peak' AND ST_DWithin(geom::geography, {here}, {RADIUS_PEAK_M}))"
        f" OR (osm_type = 'N' AND tags->>'place' IN ('city','town','village') AND ST_DWithin(geom::geography, {here}, {RADIUS_TOWN_M}))"
        f" OR (tags->>'natural' = 'water' AND tags->>'water' IN ('lake','reservoir') AND ST_DWithin(geom::geography, {here}, {RADIUS_LAKE_M})))")


def fetch(lat: float, lon: float) -> bytes:
    body = urllib.parse.urlencode({"data": sql(lat, lon)}).encode()
    request = urllib.request.Request(URL, data=body, headers={"User-Agent": USER_AGENT})
    try:
        with urllib.request.urlopen(request, timeout=180) as response:
            answer = json.loads(response.read())
    except (urllib.error.URLError, TimeoutError, json.JSONDecodeError) as err:
        raise RuntimeError(str(err)) from err
    stamp = answer.get("postpass_properties", {}).get("timestamp", "")
    if not stamp or not isinstance(answer.get("features"), list):
        raise RuntimeError("answer without a timestamp or features")
    elements = []
    for feature in answer["features"]:
        # Malformed rows are skipped, not fatal: a null geometry, no id, no tags.
        props = feature.get("properties") if isinstance(feature, dict) else None
        geometry = feature.get("geometry") if isinstance(feature, dict) else None
        if not isinstance(props, dict) or not isinstance(geometry, dict):
            continue
        coords = geometry.get("coordinates")
        kind = TYPES.get(props.get("osm_type"))
        raw_tags = props.get("tags")
        if kind is None or not isinstance(props.get("osm_id"), int) or not isinstance(raw_tags, dict) \
                or not isinstance(coords, list) or len(coords) < 2:
            continue
        tags = {k: v for k, v in raw_tags.items() if k in KEEP_TAGS}
        # HorizonFetcher.parse drops a blank name; the snapshot check would reject the place.
        if not str(tags.get("name", "")).strip():
            continue
        el = {"type": kind, "id": props["osm_id"], "tags": tags}
        if kind == "node":
            el.update({"lat": coords[1], "lon": coords[0]})
        else:
            el["center"] = {"lat": coords[1], "lon": coords[0]}
        elements.append(el)
    # Overpass prints a union by type, then id, and `out ... CAP` keeps the first CAP.
    order = {"node": 0, "way": 1, "relation": 2}
    elements.sort(key=lambda el: (order[el["type"]], el["id"]))
    payload = {"version": 0.6, "generator": "Planet Render 360 horizon layer (Postpass)",
               "osm3s": {"timestamp_osm_base": stamp}, "elements": elements[:CAP]}
    return json.dumps(payload, separators=(",", ":"), sort_keys=True, ensure_ascii=False).encode()


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("names", nargs="*", help="preset or capital names, e.g. helsinki capital_fi")
    parser.add_argument("--all", action="store_true", help="every preset and capital")
    parser.add_argument("--pause", type=float, default=1.0, help="seconds between requests")
    parser.add_argument("--work", type=Path, help="directory for the converted answers")
    parser.add_argument("--no-fetch", action="store_true", help="reuse answers already in --work")
    args = parser.parse_args()
    known = places()
    names = sorted(known) if args.all else args.names
    if not names or any(name not in known for name in names):
        raise SystemExit("choose names or --all; unknown: " + ", ".join(n for n in names if n not in known))
    work = args.work or Path(tempfile.mkdtemp(prefix="pr360_horizon_"))
    work.mkdir(parents=True, exist_ok=True)
    manifest = json.loads(MANIFEST.read_text()) if MANIFEST.exists() else {}
    failed = []
    for index, name in enumerate(names):
        lat_text, lon_text = known[name]
        source = work / f"{name}_horizon.json"
        if not args.no_fetch:
            if index:
                time.sleep(args.pause)
            try:
                source.write_bytes(fetch(float(lat_text), float(lon_text)))
            except (RuntimeError, ValueError, TypeError, KeyError, AttributeError) as err:
                print(f"{name}: FAILED {err}", flush=True)
                failed.append(name)
                continue
        destination = ASSETS / f"{name}_horizon.osmb"
        command = [sys.executable, "-I", str(ROOT / "tools/prepare_osm_snapshot.py"), "horizon",
                   str(source), str(destination)]
        if not json.loads(source.read_bytes())["elements"]:
            command.append("--allow-sparse")
        done = subprocess.run(command, capture_output=True, text=True)
        if done.returncode != 0:
            print(f"{name}: REJECTED {done.stderr.strip() or done.stdout.strip()}", flush=True)
            failed.append(name)
            continue
        fields = dict(part.split("=", 1) for part in done.stdout.split())
        stamp = fields["timestamp"].rstrip("Z")
        manifest[f"{name}_horizon"] = [json.loads(lat_text), json.loads(lon_text), "horizon", QUERY_VERSION,
                                       stamp, int(fields["bytes"]), fields["sha256"]]
        print(f"{name}: elements={fields['elements']} file_bytes={fields['file_bytes']}", flush=True)
        # Written after every place, so an interrupted run keeps what it finished.
        MANIFEST.write_text(json.dumps(dict(sorted(manifest.items())), indent=1) + "\n")
    if failed:
        raise SystemExit("failed: " + ", ".join(failed))


if __name__ == "__main__":
    main()
