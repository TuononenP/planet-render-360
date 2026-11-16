#!/usr/bin/env python3
"""Measure each capital's central airport from OpenStreetMap.

Feeds the hand-built airfields (LandmarkRegistryCapitalAirports): for every
row of tools/capital_airports.tsv it fetches the aerodrome's `aeroway`
features and buildings, converts them into the model frame and writes one
layout class per airport (scripts/generation/landmarks/capital_airports/
capital_airport_layout_<city>.gd) that the builders draw from.

    python3 -I tools/capital_airports.py fetch --work /tmp/ap
    python3 -I tools/capital_airports.py dump --work /tmp/ap IS EE
    python3 -I tools/capital_airports.py build --work /tmp/ap

`fetch` asks Overpass for the aerodrome found by its ICAO code (falling back
to a box round the rough point) and keeps each answer in --work, so a rerun
only fetches what is missing. `dump` prints a short measurement of each
airport; `build` writes the layout classes and prints the registry rows'
lat/lon/yaw/clear_rect_m for LandmarkRegistryCapitalAirports.

The model frame: +X along the longest runway, +Z to its right, origin at the
terminal's centre; yaw_deg turns that frame onto the map as every registry
row does (the same convention as tools/capital_stations.py).
"""
import argparse
import json
import math
import re
import socket
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CLIENT = "planet-render-360-capital-airports/1"
TSV = ROOT / "tools/capital_airports.tsv"
OUT_DIR = ROOT / "scripts/generation/landmarks/capital_airports"
BARRED_SUFFIXES = (".ru", ".su", ".xn--p1ai")
ENDPOINTS = ("https://overpass.openstreetmap.fr/api/interpreter", "https://overpass.kumi.systems/api/interpreter",
             "https://overpass-api.de/api/interpreter")
PAUSE_S = 8.0
TAXIWAY_W = 18.0
TAXILANE_W = 12.0
MIN_RUNWAY_M = 250.0
socket.setdefaulttimeout(150)


def slug(text: str) -> str:
    return re.sub(r"[^a-z0-9]+", "_", text.lower()).strip("_")


def read_tsv() -> list:
    rows = []
    for line in TSV.read_text().splitlines():
        if not line.strip() or line.startswith("#"):
            continue
        f = line.split("\t")
        rows.append({"cc": f[0], "city": f[1], "icao": f[2], "lat": float(f[3]), "lon": float(f[4]),
                     "name": f[5], "wiki": f[6], "half_m": float(f[7]),
                     "aliases": [a for a in (f[8] if len(f) > 8 else "").split(",") if a]})
    return rows


# --- fetching -------------------------------------------------------------

def overpass(query: str) -> dict:
    last = None
    for attempt in range(6):
        url = ENDPOINTS[attempt % len(ENDPOINTS)]
        if urllib.parse.urlparse(url).hostname.endswith(BARRED_SUFFIXES):
            raise SystemExit("refusing host")
        data = urllib.parse.urlencode({"data": query}).encode()
        request = urllib.request.Request(url, data=data, headers={"User-Agent": CLIENT})
        try:
            with urllib.request.urlopen(request, timeout=150) as answer:
                return json.loads(answer.read())
        except (urllib.error.URLError, OSError, ValueError) as err:
            last = err
            time.sleep(PAUSE_S * (attempt + 1))
    raise RuntimeError(f"overpass: {last}")


def query_icao(icao: str) -> str:
    return ('[out:json][timeout:120];'
            f'(way["aeroway"="aerodrome"]["icao"="{icao}"];rel["aeroway"="aerodrome"]["icao"="{icao}"];)->.ad;'
            '.ad map_to_area->.a;'
            '(nwr["aeroway"](area.a);way["building"](area.a);'
            'nwr["man_made"="tower"]["tower:type"="air_traffic_control"](area.a););out geom;')


def query_box(row: dict) -> str:
    k = math.cos(math.radians(row["lat"]))
    d = row["half_m"]
    s, n = row["lat"] - d / 110540.0, row["lat"] + d / 110540.0
    w, e = row["lon"] - d / (111320.0 * k), row["lon"] + d / (111320.0 * k)
    bb = f"{s:.6f},{w:.6f},{n:.6f},{e:.6f}"
    return ('[out:json][timeout:120];'
            f'(nwr["aeroway"]({bb});way["building"~"^(terminal|hangar|transportation)$"]({bb}););out geom;')


def fetch(work: Path, only: list) -> None:
    work.mkdir(parents=True, exist_ok=True)
    for row in read_tsv():
        if only and row["cc"] not in only:
            continue
        cache = work / f"osm_{row['cc']}_{slug(row['city'])}.json"
        if cache.exists():
            continue
        answer = overpass(query_icao(row["icao"]))
        if len(answer.get("elements", [])) < 5:
            time.sleep(PAUSE_S)
            answer = overpass(query_box(row))
        cache.write_text(json.dumps(answer))
        print(f"{row['cc']} {row['city']}: {len(answer['elements'])} elements", flush=True)
        time.sleep(PAUSE_S)


# --- geometry -------------------------------------------------------------

def to_local(geom: list, lat0: float, lon0: float) -> list:
    k = math.cos(math.radians(lat0))
    return [((g["lon"] - lon0) * 111320.0 * k, (g["lat"] - lat0) * 110540.0) for g in geom]


def area(ring: list) -> float:
    return 0.5 * sum(ring[i][0] * ring[(i + 1) % len(ring)][1] - ring[(i + 1) % len(ring)][0] * ring[i][1]
                     for i in range(len(ring)))


def centroid(ring: list) -> tuple:
    a = area(ring)
    if abs(a) < 1e-6:
        return (sum(p[0] for p in ring) / len(ring), sum(p[1] for p in ring) / len(ring))
    cx = cy = 0.0
    for i in range(len(ring)):
        p, q = ring[i], ring[(i + 1) % len(ring)]
        f = p[0] * q[1] - q[0] * p[1]
        cx += (p[0] + q[0]) * f
        cy += (p[1] + q[1]) * f
    return (cx / (6 * a), cy / (6 * a))


def dp_open(pts: list, tol: float) -> list:
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
    return dp_open(pts[:idx + 1], tol)[:-1] + dp_open(pts[idx:], tol)


def simplify_ring(ring: list, tol: float) -> list:
    pts = ring[:-1] if len(ring) > 1 and ring[0] == ring[-1] else ring
    if len(pts) < 5:
        return pts
    far = max(range(len(pts)), key=lambda i: math.dist(pts[0], pts[i]))
    out = dp_open(pts[:far + 1], tol)[:-1] + dp_open(pts[far:] + [pts[0]], tol)[:-1]
    return out if len(out) >= 3 else pts


def simplify_line(pts: list, tol: float) -> list:
    return dp_open(pts, tol)


def metres(raw, default: float) -> float:
    m = re.match(r"\s*(\d+(?:\.\d+)?)", str(raw or ""))
    return float(m.group(1)) if m else default


def element_rings(el: dict) -> list:
    """Closed rings (lists of {lat,lon}) of a way or the outer members of a relation."""
    if el["type"] == "way":
        g = el.get("geometry", [])
        return [g] if len(g) >= 3 else []
    segs = [m["geometry"] for m in el.get("members", []) if m.get("role") == "outer" and m.get("geometry")]
    rings = []
    while segs:
        cur = list(segs.pop(0))
        grew = True
        while grew and not (len(cur) > 2 and cur[0] == cur[-1]):
            grew = False
            for i, s in enumerate(segs):
                if s[0] == cur[-1]:
                    cur += s[1:]
                elif s[-1] == cur[-1]:
                    cur += list(reversed(s))[1:]
                else:
                    continue
                segs.pop(i)
                grew = True
                break
        if len(cur) >= 3:
            rings.append(cur)
    return rings


def classify(els: list, lat0: float, lon0: float) -> dict:
    """The aerodrome's features in local east/north metres."""
    out = {"runways": [], "taxiways": [], "aprons": [], "buildings": [], "towers": [], "stands": [],
           "helipads": [], "boundary": []}
    for el in els:
        t = el.get("tags", {})
        aw = t.get("aeroway", "")
        bld = t.get("building", "")
        if el["type"] == "node":
            p = to_local([el], lat0, lon0)[0]
            if aw in ("parking_position", "gate"):
                out["stands"].append({"p": p, "ref": t.get("ref", ""), "aeroway": aw})
            elif aw == "helipad":
                out["helipads"].append({"p": p})
            elif aw == "tower" or t.get("tower:type") == "air_traffic_control" or t.get("man_made") == "tower":
                out["towers"].append({"p": p, "h": metres(t.get("height"), 0.0), "name": t.get("name", "")})
            continue
        if aw == "runway" and el["type"] == "way":
            pts = to_local(el["geometry"], lat0, lon0)
            out["runways"].append({"ref": t.get("ref", ""), "pts": pts, "w": metres(t.get("width"), 0.0),
                                   "surface": t.get("surface", "")})
        elif aw in ("taxiway", "taxilane") and el["type"] == "way":
            out["taxiways"].append({"pts": to_local(el["geometry"], lat0, lon0), "lane": aw == "taxilane",
                                    "w": metres(t.get("width"), TAXILANE_W if aw == "taxilane" else TAXIWAY_W),
                                    "ref": t.get("ref", "")})
        elif aw == "apron":
            for ring in element_rings(el):
                out["aprons"].append(to_local(ring, lat0, lon0))
        elif aw == "helipad" and el["type"] == "way":
            ring = to_local(el["geometry"], lat0, lon0)
            out["helipads"].append({"p": centroid(ring)})
        elif aw == "aerodrome":
            for ring in element_rings(el):
                out["boundary"].append(to_local(ring, lat0, lon0))
        elif (t.get("man_made") == "tower" or bld == "control_tower" or aw == "tower") and el["type"] == "way" \
                and t.get("tower:type") != "communication":
            ring = to_local(el["geometry"], lat0, lon0)
            out["towers"].append({"p": centroid(ring), "h": metres(t.get("height"), 0.0),
                                  "name": t.get("name:en", t.get("name", "")), "area": abs(area(ring)),
                                  "type": t.get("tower:type", "")})
        elif aw in ("terminal", "hangar") or bld:
            kind = "terminal" if aw == "terminal" or bld in ("terminal", "transportation") else \
                "hangar" if aw == "hangar" or bld == "hangar" else "other"
            if t.get("man_made") == "tower" and t.get("tower:type") == "air_traffic_control":
                kind = "tower"
            lv = metres(t.get("building:levels"), 0.0)
            h = metres(t.get("height"), lv * 3.6 if lv else 0.0)
            for ring in element_rings(el):
                out["buildings"].append({"kind": kind, "ring": to_local(ring, lat0, lon0), "h": h,
                                         "levels": lv, "name": t.get("name", "")})
        elif t.get("man_made") == "tower" and t.get("tower:type") == "air_traffic_control":
            g = el.get("geometry", [])
            if g:
                out["towers"].append({"p": centroid(to_local(g, lat0, lon0)), "h": metres(t.get("height"), 0.0),
                                      "name": t.get("name", "")})
    return out


def merge_runways(rs: list) -> list:
    """Runway ways mapped in pieces become one strip each: pieces that are parallel
    and in line, with the same ref or touching ends, are joined end to end. A piece
    with no ref and under 600 m that joins nothing is dropped."""
    n = len(rs)
    parent = list(range(n))

    def find(i):
        while parent[i] != i:
            parent[i] = parent[parent[i]]
            i = parent[i]
        return i

    def unit(r):
        a, b = r["pts"][0], r["pts"][-1]
        d = math.dist(a, b) or 1e-9
        return ((b[0] - a[0]) / d, (b[1] - a[1]) / d)

    def refkey(r):
        return frozenset(q.strip().upper() for q in re.split(r"[/;,]", r["ref"] or "") if q.strip())

    for i in range(n):
        for j in range(i + 1, n):
            di, dj = unit(rs[i]), unit(rs[j])
            if abs(di[0] * dj[1] - di[1] * dj[0]) > math.sin(math.radians(5.0)):
                continue
            a = rs[i]["pts"][0]
            off = max(abs((p[0] - a[0]) * di[1] - (p[1] - a[1]) * di[0]) for p in (rs[j]["pts"][0], rs[j]["pts"][-1]))
            if off > 40.0:
                continue
            ends = min(math.dist(p, q) for p in (rs[i]["pts"][0], rs[i]["pts"][-1])
                       for q in (rs[j]["pts"][0], rs[j]["pts"][-1]))
            ki, kj = refkey(rs[i]), refkey(rs[j])
            if (ki and ki == kj) or ends < 80.0:
                parent[find(i)] = find(j)
    groups = {}
    for i in range(n):
        groups.setdefault(find(i), []).append(rs[i])
    out = []
    for members in groups.values():
        ends = [p for r in members for p in (r["pts"][0], r["pts"][-1])]
        a, b = max(((p, q) for p in ends for q in ends), key=lambda pq: math.dist(*pq))
        ref = next((r["ref"] for r in sorted(members, key=lambda r: -math.dist(r["pts"][0], r["pts"][-1])) if r["ref"]), "")
        if not ref and math.dist(a, b) < 600.0:
            continue
        out.append({"ref": ref, "pts": [a, b], "w": max(r["w"] for r in members),
                    "surface": members[0]["surface"]})
    return out


def frame(feats: dict) -> tuple:
    """(theta, origin): bearing (degrees clockwise from north, [0, 180)) of the
    longest runway's direction, and the terminal's centre in local metres."""
    if not feats["runways"]:
        raise LookupError("no runway")
    best = max(feats["runways"], key=lambda r: math.dist(r["pts"][0], r["pts"][-1]))
    a, b = best["pts"][0], best["pts"][-1]
    theta = math.degrees(math.atan2(b[0] - a[0], b[1] - a[1])) % 360.0
    if theta >= 180.0:
        theta -= 180.0
    terminals = [b for b in feats["buildings"] if b["kind"] == "terminal" and len(b["ring"]) >= 3]
    pool = terminals or sorted([b for b in feats["buildings"] if len(b["ring"]) >= 3],
                               key=lambda b: -abs(area(b["ring"])))[:3]
    if pool:
        w = sum(abs(area(b["ring"])) for b in pool) or 1.0
        ox = sum(centroid(b["ring"])[0] * abs(area(b["ring"])) for b in pool) / w
        oy = sum(centroid(b["ring"])[1] * abs(area(b["ring"])) for b in pool) / w
    else:
        ox, oy = (a[0] + b[0]) / 2, (a[1] + b[1]) / 2
    return theta, (ox, oy)


def designators(ref: str, brg: float) -> tuple:
    """The numbers painted at a runway's first and last ends: each end's number is
    the heading an aircraft landing from it flies (`brg` is first -> last)."""
    want = [(brg / 10.0) % 36.0, ((brg + 180.0) / 10.0) % 36.0]
    parts = [q.strip().upper() for q in re.split(r"[/;,]", ref or "") if re.match(r"\s*\d{1,2}[LRC]?\s*$", q)]

    def num(q):
        return int(re.match(r"\d+", q).group(0)) % 36

    def gap(a, b):
        d = abs(a - b) % 36.0
        return min(d, 36.0 - d)

    if len(parts) == 2:
        if gap(num(parts[0]), want[0]) + gap(num(parts[1]), want[1]) <= gap(num(parts[1]), want[0]) + gap(num(parts[0]), want[1]):
            return parts[0].zfill(2) if parts[0].isdigit() else parts[0], parts[1].zfill(2) if parts[1].isdigit() else parts[1]
        return parts[1], parts[0]
    n = int(round(want[0])) % 36 or 36
    m = int(round(want[1])) % 36 or 36
    return f"{n:02d}", f"{m:02d}"


def measure(row: dict, answer: dict) -> dict:
    els = answer.get("elements", [])
    feats = classify(els, row["lat"], row["lon"])
    feats["runways"] = merge_runways(feats["runways"])
    theta, (ox, oy) = frame(feats)
    s, c = math.sin(math.radians(theta)), math.cos(math.radians(theta))

    def mp(p):  # east/north -> model (x along runway, z to its right)
        e, n = p[0] - ox, p[1] - oy
        return (e * s + n * c, e * c - n * s)

    k = math.cos(math.radians(row["lat"]))
    runways = []
    for r in feats["runways"]:
        a, b = mp(r["pts"][0]), mp(r["pts"][-1])
        length = math.dist(a, b)
        if length < MIN_RUNWAY_M:  # a mapped runway fragment, not a strip
            continue
        east, north = r["pts"][-1][0] - r["pts"][0][0], r["pts"][-1][1] - r["pts"][0][1]
        na, nb = designators(r["ref"], math.degrees(math.atan2(east, north)) % 360.0)
        runways.append({"ref": r["ref"], "na": na, "nb": nb, "a": a, "b": b, "w": r["w"] or (45.0 if length > 2200 else 30.0 if length > 1100 else 23.0),
                        "surface": r["surface"]})
    taxiways = [{"pts": [mp(p) for p in simplify_line(t["pts"], 2.5)], "w": t["w"], "lane": t["lane"]}
                for t in feats["taxiways"] if len(t["pts"]) >= 2]
    aprons = [[mp(p) for p in simplify_ring(a, 2.5)] for a in feats["aprons"] if len(a) >= 3]
    buildings = [{"kind": b["kind"], "ring": [mp(p) for p in simplify_ring(b["ring"], 0.8)], "h": b["h"],
                  "levels": b["levels"], "name": b["name"]}
                 for b in feats["buildings"] if abs(area(b["ring"])) >= 60.0]
    towers = [{"p": mp(t["p"]), "h": t["h"], "name": t["name"]} for t in feats["towers"]]
    stands = [{"p": mp(t["p"]), "ref": t["ref"]} for t in feats["stands"]]
    helipads = [{"p": mp(h["p"])} for h in feats["helipads"]]
    xs = [p[0] for r in runways for p in (r["a"], r["b"])]
    zs = [p[1] for r in runways for p in (r["a"], r["b"])]
    for t in taxiways:
        xs += [p[0] for p in t["pts"]]
        zs += [p[1] for p in t["pts"]]
    for a in aprons:
        xs += [p[0] for p in a]
        zs += [p[1] for p in a]
    for b in buildings:
        xs += [p[0] for p in b["ring"]]
        zs += [p[1] for p in b["ring"]]
    return {"cc": row["cc"], "lat": round(row["lat"] + oy / 110540.0, 6),
            "lon": round(row["lon"] + ox / (111320.0 * k), 6), "yaw_deg": round(theta - 90.0, 1),
            "runways": runways, "taxiways": taxiways, "aprons": aprons, "buildings": buildings,
            "towers": towers, "stands": stands, "helipads": helipads,
            "bounds": [round(min(xs), 1), round(min(zs), 1), round(max(xs), 1), round(max(zs), 1)]}


def measured(work: Path, row: dict) -> dict:
    cache = work / f"osm_{row['cc']}_{slug(row['city'])}.json"
    if not cache.exists():
        raise LookupError("not fetched yet (run fetch)")
    return measure(row, json.loads(cache.read_text()))


# --- output ---------------------------------------------------------------

def pt(p) -> str:
    return f"[{p[0]:.1f}, {p[1]:.1f}]"


def pts(ps) -> str:
    return "[" + ", ".join(pt(p) for p in ps) + "]"


def layout_gd(row: dict, m: dict) -> str:
    cls = "CaLayout" + "".join(w.capitalize() for w in slug(row["city"]).split("_"))
    lines = [f"class_name {cls}", "extends RefCounted", "",
             f"## {row['name']} ({row['icao']}) measured from OpenStreetMap by tools/capital_airports.py:",
             "## model-frame metres, +X along the longest runway, +Z to its right, origin at the terminal's",
             "## centre. Runways are centre lines; taxiways centre lines with a width; aprons and buildings",
             "## are outlines. OpenStreetMap contributors, ODbL.", "",
             "const DATA := {"]
    lines.append('\t"runways": [')
    for r in m["runways"]:
        lines.append(f'\t\t{{"ref": "{r["ref"]}", "na": "{r["na"]}", "nb": "{r["nb"]}", "a": {pt(r["a"])}, "b": {pt(r["b"])}, "w": {r["w"]:.0f}}},')
    lines.append("\t],")
    lines.append('\t"taxiways": [')
    for t in m["taxiways"]:
        lines.append(f'\t\t{{"w": {t["w"]:.0f}, "pts": {pts(t["pts"])}}},')
    lines.append("\t],")
    lines.append('\t"aprons": [')
    for a in m["aprons"]:
        lines.append(f"\t\t{pts(a)},")
    lines.append("\t],")
    lines.append('\t"buildings": [')
    for b in m["buildings"]:
        name = b["name"].replace('"', "'")
        lines.append(f'\t\t{{"kind": "{b["kind"]}", "h": {b["h"]:.1f}, "name": "{name}", "ring": {pts(b["ring"])}}},')
    lines.append("\t],")
    lines.append('\t"towers": [' + ", ".join(f'{{"p": {pt(t["p"])}, "h": {t["h"]:.1f}}}' for t in m["towers"]) + "],")
    lines.append('\t"stands": [' + ", ".join(pt(s["p"]) for s in m["stands"]) + "],")
    lines.append('\t"helipads": [' + ", ".join(pt(h["p"]) for h in m["helipads"]) + "],")
    lines.append(f'\t"bounds": {pt(m["bounds"][:2])[:-1]}, {pt(m["bounds"][2:])[1:]},')
    lines.append("}")
    return cls, "\n".join(lines) + "\n"


def build(work: Path, only: list) -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    for row in read_tsv():
        if only and row["cc"] not in only:
            continue
        try:
            m = measured(work, row)
        except (LookupError, RuntimeError) as err:
            print(f"{row['cc']} {row['city']}: {err}", flush=True)
            continue
        cls, text = layout_gd(row, m)
        (OUT_DIR / f"capital_airport_layout_{slug(row['city'])}.gd").write_text(text)
        b = m["bounds"]
        print(f"{row['cc']} {row['city']}: lat {m['lat']} lon {m['lon']} yaw {m['yaw_deg']} bounds {b} "
              f"clear_rect_m [{(b[0] + b[2]) / 2:.0f}, {(b[1] + b[3]) / 2:.0f}, {(b[2] - b[0]) / 2 + 40:.0f}, "
              f"{(b[3] - b[1]) / 2 + 40:.0f}] class {cls}", flush=True)


def dump(work: Path, only: list) -> None:
    for row in read_tsv():
        if only and row["cc"] not in only:
            continue
        try:
            m = measured(work, row)
        except (LookupError, RuntimeError) as err:
            print(f"{row['cc']} {row['city']}: {err}", flush=True)
            continue
        print(json.dumps({"cc": row["cc"], "lat": m["lat"], "lon": m["lon"], "yaw_deg": m["yaw_deg"],
                          "bounds": m["bounds"],
                          "runways": [{"ref": r["ref"], "len": round(math.dist(r["a"], r["b"])), "w": r["w"]}
                                      for r in m["runways"]],
                          "taxiways": len(m["taxiways"]), "aprons": len(m["aprons"]),
                          "terminals": [{"name": b["name"], "h": b["h"], "area": round(abs(area(b["ring"])))}
                                        for b in m["buildings"] if b["kind"] == "terminal"],
                          "hangars": sum(1 for b in m["buildings"] if b["kind"] == "hangar"),
                          "other": sum(1 for b in m["buildings"] if b["kind"] == "other"),
                          "towers": m["towers"], "stands": len(m["stands"])}, ensure_ascii=False))


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("command", choices=("fetch", "dump", "build"))
    ap.add_argument("codes", nargs="*", help="country codes to (re)do; all when none")
    ap.add_argument("--work", type=Path, required=True)
    args = ap.parse_args()
    {"fetch": fetch, "dump": dump, "build": build}[args.command](args.work, args.codes)


if __name__ == "__main__":
    sys.exit(main())
