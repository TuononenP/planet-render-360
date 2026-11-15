#!/usr/bin/env python3
"""Measure each capital's main railway station from OpenStreetMap.

Feeds LandmarkRegistryCapitalStationsOsm, the registry rows that draw a
capital's station building as a `station` archetype on its real outline
(LandmarkCoreBArchStation), and prints the outlines the hand-built termini
(LandmarkRegistryCapitalStations) are traced from.

    python3 -I tools/capital_stations.py build --work /tmp/st
    python3 -I tools/capital_stations.py dump --work /tmp/st AT HU

tools/capital_stations.tsv lists one main station per capital: its rough
point, name, Wikipedia title, an optional height and clock tower, aliases,
optionally the OSM way ("w<id>") or relation ("r<id>"), and a `style`
(JSON, the keys of LandmarkCoreBArchStation) describing the real building
from photos: body height, colours, roof, towers, dome, hall and so on. The
registry height_m is the style's highest point (style_top). Without an id
the station building within RESOLVE_M of the point is taken (tagged
as the station, else holding the station node, else named as one; the
largest of its rank); a
capital with none is left out. `build` reads each station's square from the
OSM API's map call (the building, its parts and the railway lines beside
it, one request per station with a pause between; the public Overpass
instances are often at capacity for a batch like this), keeps the answers
in --work so a rerun only fetches what is missing, and writes the generated registry; rows marked `bespoke` (the
hand-built termini) are skipped. `dump` prints the outlines (model-frame
metres) and building:part rows the hand-built models are traced from.

The model frame: +X along the outline's long axis, +Z the side facing away
from the tracks (the forecourt), origin at the minimum-area rectangle's
centre. yaw_deg turns that frame onto the map as every registry row does.
"""
import argparse
import json
import socket
import math
import re
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CLIENT = "planet-render-360-capital-stations/1"
RAIL_M = 300
RESOLVE_M = 500
TSV = ROOT / "tools/capital_stations.tsv"
OUT = ROOT / "scripts/data/landmark_registry_capital_stations_osm.gd"
BARRED_SUFFIXES = (".ru", ".su", ".xn--p1ai")
API = "https://api.openstreetmap.org/api/0.6/map.json"
API_PAUSE_S = 6.0
MAX_POINTS = 48


socket.setdefaulttimeout(90)


def fetch_box(lat: float, lon: float, half_m: float, depth: int = 0) -> dict:
    """The OSM API map call for the square of half-side `half_m` round the
    point: {"node": {id: el}, "way": {...}, "relation": {...}}. A square the
    API refuses as too dense (HTTP 400/509) is split in four."""
    k = math.cos(math.radians(lat))
    dlat, dlon = half_m / 110540.0, half_m / (111320.0 * k)
    out = {"node": {}, "way": {}, "relation": {}}

    def tile(west, south, east, north, d):
        url = f"{API}?bbox={west:.6f},{south:.6f},{east:.6f},{north:.6f}"
        if urllib.parse.urlparse(url).hostname.endswith(BARRED_SUFFIXES):
            raise SystemExit("refusing host")
        for attempt in range(4):
            request = urllib.request.Request(url, headers={"User-Agent": CLIENT})
            try:
                with urllib.request.urlopen(request, timeout=90) as answer:
                    payload = json.loads(answer.read())
                break
            except urllib.error.HTTPError as err:
                if err.code in (400, 509) and d < 3:
                    mx, my = (west + east) / 2, (south + north) / 2
                    for sub in ((west, south, mx, my), (mx, south, east, my), (west, my, mx, north),
                                (mx, my, east, north)):
                        time.sleep(API_PAUSE_S)
                        tile(*sub, d + 1)
                    return
                if err.code == 403:
                    raise SystemExit(f"{url} refused the request (HTTP 403); stopping")
                if err.code == 429:  # over the API's rate: back off and retry
                    time.sleep(90 * (attempt + 1))
                    continue
                if attempt == 3:
                    raise RuntimeError(f"{url}: {err}")
            except (urllib.error.URLError, OSError, ValueError) as err:
                if attempt == 3:
                    raise RuntimeError(f"{url}: {err}")
            time.sleep(10 * (attempt + 1))
        for el in payload.get("elements", []):
            out[el["type"]][el["id"]] = el
    tile(lon - dlon, lat - dlat, lon + dlon, lat + dlat, depth)
    time.sleep(API_PAUSE_S)
    return out


def way_points(osm: dict, way: dict) -> list:
    return [(osm["node"][n]["lat"], osm["node"][n]["lon"]) for n in way.get("nodes", []) if n in osm["node"]]


def slug(text: str) -> str:
    return re.sub(r"[^a-z0-9]+", "_", text.lower()).strip("_")


# --- geometry -------------------------------------------------------------

def local(points: list, lat0: float, lon0: float) -> list:
    k = math.cos(math.radians(lat0))
    return [((p[1] - lon0) * 111320.0 * k, (p[0] - lat0) * 110540.0) for p in points]


def area(ring: list) -> float:
    return 0.5 * sum(ring[i][0] * ring[(i + 1) % len(ring)][1] - ring[(i + 1) % len(ring)][0] * ring[i][1]
                     for i in range(len(ring)))


def hull(points: list) -> list:
    pts = sorted(set(points))
    if len(pts) < 3:
        return pts

    def cross(o, a, b):
        return (a[0] - o[0]) * (b[1] - o[1]) - (a[1] - o[1]) * (b[0] - o[0])
    lower, upper = [], []
    for p in pts:
        while len(lower) >= 2 and cross(lower[-2], lower[-1], p) <= 0:
            lower.pop()
        lower.append(p)
    for p in reversed(pts):
        while len(upper) >= 2 and cross(upper[-2], upper[-1], p) <= 0:
            upper.pop()
        upper.append(p)
    return lower[:-1] + upper[:-1]


def min_rect(points: list) -> tuple:
    """(angle, length, width, cx, cy): the minimum-area rectangle, angle of its long side."""
    h = hull(points)
    best = None
    for i in range(len(h)):
        a, b = h[i], h[(i + 1) % len(h)]
        t = math.atan2(b[1] - a[1], b[0] - a[0])
        c, s = math.cos(t), math.sin(t)
        us = [p[0] * c + p[1] * s for p in h]
        vs = [-p[0] * s + p[1] * c for p in h]
        du, dv = max(us) - min(us), max(vs) - min(vs)
        if best is None or du * dv < best[0]:
            mu, mv = (max(us) + min(us)) * 0.5, (max(vs) + min(vs)) * 0.5
            cx, cy = mu * c - mv * s, mu * s + mv * c
            if du >= dv:
                best = (du * dv, t, du, dv, cx, cy)
            else:
                best = (du * dv, t + math.pi * 0.5, dv, du, cx, cy)
    return best[1:]


def simplify(ring: list, tol: float) -> list:
    def dp(pts):
        if len(pts) < 3:
            return pts
        a, b = pts[0], pts[-1]
        ab = (b[0] - a[0], b[1] - a[1])
        n = math.hypot(*ab) or 1e-9
        far, idx = 0.0, 0
        for i in range(1, len(pts) - 1):
            d = abs(ab[0] * (a[1] - pts[i][1]) - ab[1] * (a[0] - pts[i][0])) / n
            if d > far:
                far, idx = d, i
        if far <= tol:
            return [a, b]
        return dp(pts[:idx + 1])[:-1] + dp(pts[idx:])
    pts = [p for i, p in enumerate(ring) if i == 0 or math.dist(p, ring[i - 1]) > 0.05]
    if len(pts) < 4:
        return pts
    # Split the closed ring at its farthest pair so neither half's chord
    # collapses to a point.
    far = max(range(len(pts)), key=lambda i: math.dist(pts[0], pts[i]))
    out = dp(pts[:far + 1])[:-1] + dp(pts[far:] + [pts[0]])[:-1]
    return out if len(out) >= 3 else pts


def metres(raw) -> float:
    m = re.match(r"\s*(\d+(?:\.\d+)?)", str(raw or ""))
    return float(m.group(1)) if m else 0.0


def height_of(tags: dict, parts: list) -> float:
    h = metres(tags.get("height"))
    if h <= 0.0 and metres(tags.get("building:levels")) > 0.0:
        h = metres(tags["building:levels"]) * 4.5 + metres(tags.get("roof:height"))
    for p in parts:
        ph = metres(p.get("height"))
        if ph <= 0.0 and metres(p.get("building:levels")) > 0.0:
            ph = metres(p["building:levels"]) * 4.5
        h = max(h, ph)
    return h


def outer_ring(osm: dict, el: dict) -> list:
    if el["type"] == "way":
        return way_points(osm, el)
    best = []
    for m in el.get("members", []):
        if m.get("type") == "way" and m.get("role") == "outer" and m["ref"] in osm["way"]:
            ring = way_points(osm, osm["way"][m["ref"]])
            if len(ring) > len(best):
                best = ring
    return best


def station_tags(t: dict) -> bool:
    if not t.get("building") or t.get("station") in ("subway", "light_rail", "monorail") \
            or t.get("subway") == "yes" or t.get("tourism") == "museum":
        return False
    return t.get("building") == "train_station" or t.get("railway") == "station" \
        or (t.get("public_transport") == "station" and t.get("train") == "yes")


STATION_WORDS = ("station", "gare", "estación", "estacion", "estação", "stazione", "bahnhof", "stasiun",
                 "vokzal", "вокзал", "stanica", "stanice", "kolodvor", "postaja", "nádraží", "stacija",
                 "stotis", "gara ", "σταθμ", "محطة", "ایستگاه", "railway", "ferrocarril", "ga ")


def named_station(t: dict) -> bool:
    name = " ".join(str(t.get(k, "")) for k in ("name", "name:en", "name:fr", "official_name")).lower()
    return bool(t.get("building")) and t.get("building") != "no" and any(w in name for w in STATION_WORDS) \
        and t.get("station") not in ("subway", "light_rail", "monorail") and t.get("tourism") != "museum"


def inside(p: tuple, ring: list) -> bool:
    hit = False
    for i in range(len(ring)):
        a, b = ring[i], ring[(i + 1) % len(ring)]
        if (a[1] > p[1]) != (b[1] > p[1]) and p[0] < a[0] + (p[1] - a[1]) * (b[0] - a[0]) / (b[1] - a[1]):
            hit = not hit
    return hit


def measure(row: dict) -> dict:
    """The station building nearest the row's point (the named OSM element
    when the row gives one, else the largest station building within
    RESOLVE_M): its outline in the model frame, yaw and height."""
    osm = fetch_box(row["lat"], row["lon"], RESOLVE_M + 100.0)
    nodes = [local([(n["lat"], n["lon"])], row["lat"], row["lon"])[0] for n in osm["node"].values()
             if n.get("tags", {}).get("railway") == "station"
             and n["tags"].get("station") not in ("subway", "light_rail", "monorail", "funicular")]
    main, best = None, 0.0
    want = row["osm"] not in ("", "bespoke")
    for kind in ("way", "relation"):
        for el in osm[kind].values():
            if want and row["osm"] != kind[0] + str(el["id"]):
                continue
            t = el.get("tags", {})
            if not want and not t.get("building"):
                continue
            ring = outer_ring(osm, el)
            if len(ring) < 4:
                continue
            ring_m = local(ring, row["lat"], row["lon"])
            cx = sum(p[0] for p in ring_m) / len(ring_m)
            cy = sum(p[1] for p in ring_m) / len(ring_m)
            if math.hypot(cx, cy) > RESOLVE_M and not want:
                continue
            a = abs(area(ring_m))
            # Tagged as the station first, then a building holding (or by)
            # the station node, then one named as a station.
            rank = 3 if station_tags(t) else 0
            if not rank and any(inside(n, ring_m) or math.hypot(n[0] - cx, n[1] - cy) < 40.0 for n in nodes):
                rank = 2
            if not rank and named_station(t):
                rank = 1
            if not want and (not rank or a < 250.0):
                continue
            score = rank * 1e7 + a
            if score > best:
                main, best = el, score
    if main is None:
        raise LookupError(f"no station building near {row['lat']}, {row['lon']}")
    row["osm"] = main["type"][0] + str(main["id"])
    tags = main.get("tags", {})
    ring_ll = outer_ring(osm, main)
    if ring_ll and ring_ll[0] == ring_ll[-1]:
        ring_ll = ring_ll[:-1]
    lat0 = sum(p[0] for p in ring_ll) / len(ring_ll)
    lon0 = sum(p[1] for p in ring_ll) / len(ring_ll)
    ring = local(ring_ll, lat0, lon0)
    parts = []
    for el in osm["way"].values():
        t = el.get("tags", {})
        if "building:part" in t and t["building:part"] != "no":
            pts = local(way_points(osm, el), lat0, lon0)
            if pts and inside((sum(p[0] for p in pts) / len(pts), sum(p[1] for p in pts) / len(pts)), ring):
                parts.append(t)
    rails = []
    for el in osm["way"].values():
        if el.get("tags", {}).get("railway") in ("rail", "light_rail"):
            rails += [p for p in local(way_points(osm, el), lat0, lon0) if math.hypot(*p) < RAIL_M]
    t, length, width, cx, cy = min_rect(ring)
    # East/north angle t -> clockwise yaw from east, +Z (south) turned too.
    yaw = -math.degrees(t)
    a = (math.cos(t), math.sin(t))          # model +X in east/north
    c = (math.sin(t), -math.cos(t))         # model +Z in east/north (yaw turns +Z off south)
    side = 0.0
    for p in rails:
        side += (p[0] - cx) * c[0] + (p[1] - cy) * c[1]
    if side > 0.0:  # tracks on +Z: turn the frame so the forecourt is +Z
        yaw += 180.0
        a, c = (-a[0], -a[1]), (-c[0], -c[1])
    yaw = (yaw + 180.0) % 360.0 - 180.0
    model = [((p[0] - cx) * a[0] + (p[1] - cy) * a[1], (p[0] - cx) * c[0] + (p[1] - cy) * c[1]) for p in ring]
    if area(model) < 0.0:
        model.reverse()
    tol = 0.6
    simple = simplify(model, tol)
    while len(simple) > MAX_POINTS and tol < 50.0:
        tol *= 1.5
        simple = simplify(model, tol)
    k = math.cos(math.radians(lat0))
    clat = lat0 + cy / 110540.0
    clon = lon0 + cx / (111320.0 * k)
    h = row.get("height") or height_of(tags, parts)
    return {"lat": round(clat, 6), "lon": round(clon, 6), "yaw_deg": round(yaw, 1),
            "length": round(length, 1), "width": round(width, 1), "height": round(float(h), 1),
            "outline": [[round(x, 1), round(z, 1)] for x, z in simple], "tags": tags,
            "parts": parts, "rails": len(rails), "osm": row["osm"]}


def read_tsv() -> list[dict]:
    rows = []
    for line in TSV.read_text().splitlines():
        if not line.strip() or line.startswith("#"):
            continue
        cells = line.split("\t")
        cc, city, lat, lon, name, wiki, height, tower, aliases, osm, style = (cells + [""] * 11)[:11]
        rows.append({"cc": cc, "city": city, "lat": float(lat), "lon": float(lon), "osm": osm,
                     "name": name, "wiki": wiki,
                     "height": float(height) if height else 0.0, "tower": tower == "tower",
                     "aliases": [a.strip() for a in aliases.split(",") if a.strip()],
                     "style": json.loads(style) if style.strip() else {}})
    return rows


def style_top(style: dict, h: float) -> float:
    """The highest point LandmarkCoreBArchStation draws for `style` on a
    body of default height `h`: every style height is a total."""
    eave = float(style.get("eave", h))
    if style.get("underground"):
        return eave
    roof = style.get("roof", "flat")
    top = eave + (float(style.get("roof_rise", 5.0)) if roof == "hip" else 1.0 if roof == "overhang" else 0.0)
    if "tower" in style:
        top = max(top, float(style.get("tower_h", eave + 15.0)))
    if "dome" in style:
        top = max(top, float(style.get("dome_top", eave + float(style.get("dome_r", 8.0)) * 1.6)))
    if style.get("hall"):
        top = max(top, float(style.get("hall_top", eave + 8.0)))
    if "centre_h" in style:
        rise = float(style.get("centre_rise", 0.0)) if style.get("centre_roof", "flat") != "flat" else 0.0
        top = max(top, float(style["centre_h"]) + rise)
    if roof == "gable":
        top = max(top, eave + float(style.get("roof_rise", 3.0)))
    if "shell_canopy" in style:
        top = max(top, eave - 1.0 + float(style["shell_canopy"][1]) + 0.4)
    if "portal" in style:
        top = max(top, float(style["portal"][1]))
    if "cantilever" in style:
        top = max(top, eave + float(style["cantilever"][1]) + 0.2)
    if style.get("hall") and "hall_belfry" in style:
        top = max(top, float(style.get("hall_top", eave + 8.0)) + float(style["hall_belfry"]))
    if "pavilions" in style:
        top = max(top, float(style["pavilions"][1]))
    if style.get("shells"):
        top = max(top, float(style.get("shell_top", eave + (6.0 if style["shells"] == "umbrella" else 4.0))))
    return top


def gd_entry(row: dict, m: dict) -> str:
    # Untagged: a modest station hall, taller for a long one. The style (the
    # real building's form, from photos) may set the body and its features.
    h = max(m["height"], 8.0) if m["height"] > 0.0 else (18.0 if m["length"] > 120.0 else 14.0)
    style = dict(row["style"])
    if row["tower"] and not style:
        style = {"tower": "side", "tower_h": max(h + 10.0, 24.0)}
    top = style_top(style, h)
    if "eave" not in style and not style.get("underground"):
        style["eave"] = h
    hl = m["length"] * 0.5 + 4.0
    hw = m["width"] * 0.5 + 4.0
    aliases = sorted({row["name"].lower(), *[a.lower() for a in row["aliases"]]})
    outline = ", ".join(f"[{x}, {z}]" for x, z in m["outline"])
    return ("\t\t{" + f'"type": "{row["type"]}", "name": "{row["name"]}", "lat": {m["lat"]}, "lon": {m["lon"]},\n'
            f'\t\t\t"radius_m": 6000.0, "wiki_title": "{row["wiki"]}", "height_m": {round(top, 1)}, "kind": "Station",\n'
            f'\t\t\t"secondary": true, "yaw_deg": {m["yaw_deg"]}, "clear_m": 12.0,'
            f' "clear_rect_m": [0.0, 0.0, {hl:.1f}, {hw:.1f}],\n'
            f'\t\t\t"archetype": "station", "capital": "{row["cc"]}",\n'
            f'\t\t\t"style": {json.dumps(style, ensure_ascii=False)},\n'
            f'\t\t\t"aliases": [{", ".join(json.dumps(a, ensure_ascii=False) for a in aliases)}],\n'
            f'\t\t\t"outline_m": [{outline}]' + "},")


def build(work: Path) -> None:
    work.mkdir(parents=True, exist_ok=True)
    entries = []
    for row in read_tsv():
        if row["osm"] in ("-", "bespoke"):
            continue
        row["type"] = f"station_{row['cc'].lower()}_{slug(row['city'])}"
        cache = work / f"measure_{row['cc']}_{slug(row['city'])}.json"
        if cache.exists():
            m = json.loads(cache.read_text())
        else:
            try:
                m = measure(row)
            except LookupError as err:
                m = {"skip": str(err)}
            except (RuntimeError, StopIteration) as err:
                print(f"{row['type']}: failed ({err})", file=sys.stderr, flush=True)
                continue
            cache.write_text(json.dumps(m, ensure_ascii=False))
        if "skip" in m:
            print(f"{row['type']}: skipped ({m['skip']})", file=sys.stderr, flush=True)
            continue
        print(f"{row['type']}: {m['length']} x {m['width']} m, {m['height']} m, yaw {m['yaw_deg']}, "
              f"{len(m['outline'])} pts, {m['rails']} rail pts", flush=True)
        entries.append(gd_entry(row, m))
    OUT.write_text(
        "class_name LandmarkRegistryCapitalStationsOsm\nextends RefCounted\n\n"
        "## Generated by tools/capital_stations.py from tools/capital_stations.tsv and\n"
        "## OpenStreetMap (© OpenStreetMap contributors, ODbL); do not edit by hand.\n"
        "## The main railway station of each capital without a hand-built terminus\n"
        "## (LandmarkRegistryCapitalStations): its real outline in the model frame\n"
        "## (+X the long axis, +Z the forecourt away from the tracks), drawn by\n"
        "## LandmarkCoreBArchStation. Secondary: a station stands beside a\n"
        "## capital's icons, never instead of them.\n\n"
        "static func entries() -> Array:\n\treturn [\n" + "\n".join(entries) + "\n\t]\n")
    print(f"wrote {OUT.relative_to(ROOT)}: {len(entries)} stations")


def dump(work: Path, only: list[str]) -> None:
    for row in read_tsv():
        if only and row["cc"] not in only:
            continue
        if row["osm"] == "-":
            continue
        cache = work / f"dump_{row['cc']}_{slug(row['city'])}.json"
        try:
            m = json.loads(cache.read_text()) if cache.exists() else measure(row)
        except (LookupError, RuntimeError) as err:
            print(f"{row['cc']} {row['city']}: {err}", flush=True)
            continue
        cache.write_text(json.dumps(m, ensure_ascii=False))
        print(json.dumps({"cc": row["cc"], "name": row["name"], **{k: m[k] for k in
              ("lat", "lon", "yaw_deg", "length", "width", "height", "outline")},
              "parts": [{k: p.get(k, "") for k in ("height", "min_height", "building:levels", "roof:shape",
                                                    "roof:height", "name")} for p in m["parts"]]},
                         ensure_ascii=False))


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("command", choices=("build", "dump"))
    ap.add_argument("codes", nargs="*", help="country codes to (re)do; all when none")
    ap.add_argument("--work", type=Path, required=True)
    args = ap.parse_args()
    if args.command == "build":
        build(args.work)
    else:
        dump(args.work, args.codes)


if __name__ == "__main__":
    main()
