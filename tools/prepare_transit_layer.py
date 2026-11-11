#!/usr/bin/env python3
"""Fetch the transit layer of the preset cities for BundledOsm.

The bundled detailed snapshots carry no tram stops or station nodes, and bus
stops only within the furniture radius. This gathers what OsmQuery.build_query
asks for over the detailed radius around each preset, and prepares each answer
with prepare_osm_snapshot.py (validate, deterministic gzip). It prints the
BundledOsm.ENTRIES row to add.

Two sources: the app's own Overpass instances (OsmFetcher.ENDPOINTS), one
request per city (--source overpass), or, when those are down, the OSM API's
map call (--source api, the default): the square around the preset in small
tiles, filtered here to the same tags and radius and written in Overpass's
JSON shape.

    python3 -I tools/prepare_transit_layer.py helsinki san_francisco
    python3 -I tools/prepare_transit_layer.py --all --source overpass --pause 30

Cities are the `<name>_detailed` rows of BundledOsm.ENTRIES. Payloads are kept
in --work (default: a temporary directory) so a failed city can be retried alone.
"""
import argparse
import datetime
import hashlib
import json
import math
import re
import struct
import subprocess
import sys
import tempfile
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
RADIUS_M = 1200  # OsmFetcher.DETAILED_RADIUS_M
CAP_STOPS = 1500  # OsmQuery.CAP_STOPS
CAP_PLATFORMS = 600  # OsmQuery.CAP_PLATFORMS
CLIENT = "planet-render-360-transit-layer/1"
API = "https://api.openstreetmap.org/api/0.6/map.json"
API_TILES = 3  # tiles per side of the square; a refused (too dense) tile is split in four
API_PAUSE_S = 6.0
API_DEPTH = 3
BARRED_SUFFIXES = (".ru", ".su", ".xn--p1ai")
BARRED_NAMES = ("mail.ru", "yandex", "vk.com")


def endpoints() -> list[str]:
    """The Overpass URLs the app tries, read from OsmFetcher.ENDPOINTS."""
    text = (ROOT / "scripts/data/osm_fetcher.gd").read_text()
    block = re.search(r"const ENDPOINTS: Array\[String\] = \[(.*?)\]", text, re.S)
    urls = re.findall(r'"(https://[^"]+)"', block.group(1)) if block else []
    for url in urls:
        host = urllib.parse.urlparse(url).hostname or ""
        if host.endswith(BARRED_SUFFIXES) or any(name in host for name in BARRED_NAMES):
            raise SystemExit(f"refusing host {host}")
    if not urls:
        raise SystemExit("no endpoints found in osm_fetcher.gd")
    return urls


def presets() -> dict:
    """name -> (lat, lon) of every preset `<name>_detailed` row."""
    text = (ROOT / "scripts/data/bundled_osm.gd").read_text()
    rows = re.findall(r'"([a-z0-9_]+)_detailed": \[(-?[\d.]+), (-?[\d.]+), "detailed', text)
    return {name: (float(lat), float(lon)) for name, lat, lon in rows if not name.startswith("capital_")}


def f32(value: float) -> float:
    """Presets reach the fetchers through Vector2, which holds 32-bit floats."""
    return struct.unpack("f", struct.pack("f", value))[0]


def query(lat: float, lon: float, radius: int = RADIUS_M) -> str:
    around = f"(around:{radius},{f32(lat):.6f},{f32(lon):.6f})"
    return (
        "[out:json][timeout:60];"
        f'(node["railway"="tram_stop"]{around};'
        f'node["public_transport"="stop_position"]["tram"="yes"]{around};'
        f'node["highway"="bus_stop"]{around};);out {CAP_STOPS};'
        f'(way["railway"="platform"]{around};'
        f'way["public_transport"="platform"]["train"="yes"]{around};'
        f'node["railway"~"^(station|halt)$"]{around};);out geom {CAP_PLATFORMS};'
    )


def fetch(urls: list[str], body: str) -> bytes:
    data = ("data=" + urllib.parse.quote(body, safe="")).encode()
    last = []
    for url in urls:
        request = urllib.request.Request(url, data=data, headers={"User-Agent": CLIENT})
        try:
            with urllib.request.urlopen(request, timeout=90) as answer:
                raw = answer.read()
            payload = json.loads(raw)
            if payload.get("remark") or not isinstance(payload.get("elements"), list):
                last.append(f"{url}: incomplete answer ({str(payload.get('remark', ''))[:80]})")
                continue
            return raw
        except urllib.error.HTTPError as err:
            if err.code in (403, 429):
                raise SystemExit(f"{url} refused the request (HTTP {err.code}); stopping")
            last.append(f"{url}: {err}")
        except (urllib.error.URLError, TimeoutError, ValueError) as err:
            last.append(f"{url}: {err}")
        time.sleep(5)
    raise RuntimeError("; ".join(last))


def wanted_node(tags: dict) -> bool:
    """The node statements of query(): stops, and mainline stations."""
    if tags.get("railway") == "tram_stop" or tags.get("highway") == "bus_stop":
        return True
    if tags.get("public_transport") == "stop_position" and tags.get("tram") == "yes":
        return True
    return tags.get("railway") in ("station", "halt")


def wanted_way(tags: dict) -> bool:
    """The way statements of query(): platforms."""
    return tags.get("railway") == "platform" or (
        tags.get("public_transport") == "platform" and tags.get("train") == "yes")


def metres(lat: float, lon: float, clat: float, clon: float) -> float:
    dy = (lat - clat) * 110540.0
    dx = (lon - clon) * 111320.0 * math.cos(math.radians(clat))
    return math.hypot(dx, dy)


def api_tile(box: tuple, depth: int, seen: dict) -> None:
    """The elements of one bbox (west, south, east, north) into `seen`, splitting
    a tile the API refuses as too dense (HTTP 400) into four."""
    west, south, east, north = box
    url = f"{API}?bbox={west:.6f},{south:.6f},{east:.6f},{north:.6f}"
    request = urllib.request.Request(url, headers={"User-Agent": CLIENT})
    try:
        with urllib.request.urlopen(request, timeout=120) as answer:
            payload = json.loads(answer.read())
    except urllib.error.HTTPError as err:
        if err.code in (403, 429):
            raise SystemExit(f"{url} refused the request (HTTP {err.code}); stopping")
        if err.code in (400, 509) and depth < API_DEPTH:
            mid_x, mid_y = (west + east) / 2, (south + north) / 2
            for sub in ((west, south, mid_x, mid_y), (mid_x, south, east, mid_y),
                        (west, mid_y, mid_x, north), (mid_x, mid_y, east, north)):
                time.sleep(API_PAUSE_S)
                api_tile(sub, depth + 1, seen)
            return
        raise RuntimeError(f"{url}: {err}")
    except (urllib.error.URLError, TimeoutError, ValueError) as err:
        raise RuntimeError(f"{url}: {err}")
    for el in payload.get("elements", []):
        seen[(el.get("type"), el.get("id"))] = el


def fetch_api(lat: float, lon: float) -> bytes:
    """query()'s elements from the OSM API, in Overpass's JSON shape: nodes
    with the stop tags within RADIUS_M, and platform ways (with geometry) with
    a point within it."""
    clat, clon = f32(lat), f32(lon)
    dlat = RADIUS_M / 110540.0
    dlon = RADIUS_M / (111320.0 * math.cos(math.radians(clat)))
    seen: dict = {}
    for row in range(API_TILES):
        for col in range(API_TILES):
            box = (clon - dlon + 2 * dlon * col / API_TILES, clat - dlat + 2 * dlat * row / API_TILES,
                   clon - dlon + 2 * dlon * (col + 1) / API_TILES, clat - dlat + 2 * dlat * (row + 1) / API_TILES)
            if row or col:
                time.sleep(API_PAUSE_S)
            api_tile(box, 0, seen)
    nodes = {el["id"]: el for (kind, _), el in seen.items() if kind == "node"}
    stops, platforms = [], []
    for el in nodes.values():
        tags = el.get("tags", {})
        if tags and wanted_node(tags) and metres(el["lat"], el["lon"], clat, clon) <= RADIUS_M:
            stops.append({"type": "node", "id": el["id"], "lat": el["lat"], "lon": el["lon"], "tags": tags})
    for (kind, _), el in seen.items():
        tags = el.get("tags", {})
        if kind != "way" or not tags or not wanted_way(tags):
            continue
        geometry = [{"lat": nodes[n]["lat"], "lon": nodes[n]["lon"]} for n in el.get("nodes", []) if n in nodes]
        if len(geometry) >= 2 and any(metres(g["lat"], g["lon"], clat, clon) <= RADIUS_M for g in geometry):
            platforms.append({"type": "way", "id": el["id"], "tags": tags, "geometry": geometry})
    stops.sort(key=lambda el: el["id"])
    platforms.sort(key=lambda el: el["id"])
    # Stations are nodes; the app's query returns them with the platform ways.
    ordered = [el for el in stops if el["tags"].get("railway") not in ("station", "halt")][:CAP_STOPS]
    stations = [el for el in stops if el["tags"].get("railway") in ("station", "halt")]
    now = datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    payload = {"version": 0.6, "generator": "Planet Render 360 transit layer (OSM API map call)",
               "osm3s": {"timestamp_osm_base": now}, "elements": ordered + platforms[:CAP_PLATFORMS] + stations}
    return json.dumps(payload, separators=(",", ":"), sort_keys=True).encode()


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("cities", nargs="*", help="preset names, e.g. helsinki new_york_midtown")
    parser.add_argument("--all", action="store_true", help="every preset city")
    parser.add_argument("--source", choices=("api", "overpass"), default="api", help="where the data comes from")
    parser.add_argument("--pause", type=float, default=10.0, help="seconds between cities")
    parser.add_argument("--work", type=Path, help="directory for the raw answers")
    parser.add_argument("--allow-sparse", action="store_true", help="keep a city with no stops (rural presets)")
    parser.add_argument("--no-fetch", action="store_true", help="reuse answers already in --work")
    args = parser.parse_args()
    known = presets()
    names = list(known) if args.all else args.cities
    if not names or any(name not in known for name in names):
        raise SystemExit("choose preset names or --all; known: " + ", ".join(known))
    urls = endpoints() if args.source == "overpass" else []
    work = args.work or Path(tempfile.mkdtemp(prefix="pr360_transit_"))
    work.mkdir(parents=True, exist_ok=True)
    failed = []
    for index, name in enumerate(names):
        lat, lon = known[name]
        source = work / f"{name}_transit.json"
        if not args.no_fetch:
            if index:
                time.sleep(args.pause)
            try:
                source.write_bytes(fetch(urls, query(lat, lon)) if args.source == "overpass" else fetch_api(lat, lon))
            except RuntimeError as err:
                print(f"{name}: FAILED {err}")
                failed.append(name)
                continue
        destination = ROOT / "assets/osm_snapshots" / f"{name}_transit.json.gz"
        command = [sys.executable, "-I", str(ROOT / "tools/prepare_osm_snapshot.py"), "transit", str(source), str(destination)]
        if args.allow_sparse:
            command.append("--allow-sparse")
        done = subprocess.run(command, capture_output=True, text=True)
        if done.returncode != 0:
            print(f"{name}: REJECTED {done.stderr.strip() or done.stdout.strip()}")
            failed.append(name)
            continue
        fields = dict(part.split("=", 1) for part in done.stdout.split())
        print(f"{name}: {done.stdout.strip()}")
        print(f'\t"{name}_transit": [{lat:.4f}, {lon:.4f}, "transit", 1, "{fields["timestamp"].rstrip("Z")}", '
              f'{fields["bytes"]}, "{fields["sha256"]}"],')
    if failed:
        raise SystemExit("failed: " + ", ".join(failed))


if __name__ == "__main__":
    main()
