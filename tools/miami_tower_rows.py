#!/usr/bin/env python3
"""Generate MiamiTowerSpecs.row(...) entries from decoded OSM JSON or .osmb snapshots.

Usage:
  python3 -I tools/miami_tower_rows.py <snapshot.osmb|file.json> [way:12345 relation:67890 ...]
  python3 -I tools/miami_tower_rows.py <snapshot.osmb|file.json> --min-height 80

For each requested building outline (or all tall buildings >= --min-height), computes:
- OSM outline centroid (lat, lon) and long-axis yaw_deg
- Local model-frame polygon / tier `poly` ops from mapped `building:part` elements
- OSM top height (metres, handling `ft` / `'` suffixes and `building:levels`)
- Maximum safe `clear_m` stopping short of the nearest other tall building (> 40 m)
"""
import argparse
import json
import math
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import osmb  # noqa: E402


def load_elements(path: Path) -> list[dict]:
    if path.suffix == ".osmb":
        data = osmb.read_osmb(str(path))
    else:
        data = json.loads(path.read_bytes())
    return data.get("elements", [])


def parse_h(val: str) -> float:
    if not val:
        return 0.0
    s = str(val).strip()
    ft = bool(re.search(r"(?:ft|')\s*$", s, re.I))
    m = re.match(r"^[-+]?\d+(?:\.\d+)?", s)
    if not m:
        return 0.0
    return float(m.group(0)) * (0.3048 if ft else 1.0)


def ring_pts(el: dict) -> list[tuple[float, float]]:
    if "geometry" in el and isinstance(el["geometry"], list):
        pts = [(float(p["lat"]), float(p["lon"])) for p in el["geometry"] if "lat" in p and "lon" in p]
        return pts[:-1] if len(pts) > 2 and pts[0] == pts[-1] else pts
    if "members" in el and isinstance(el["members"], list):
        for m in el["members"]:
            if m.get("role") in ("outer", "") and isinstance(m.get("geometry"), list):
                pts = [(float(p["lat"]), float(p["lon"])) for p in m["geometry"] if "lat" in p and "lon" in p]
                if len(pts) >= 3:
                    return pts[:-1] if pts[0] == pts[-1] else pts
    return []


def xz_from_latlon(lat: float, lon: float, clat: float, clon: float) -> tuple[float, float]:
    east = (lon - clon) * 111320.0 * math.cos(math.radians(clat))
    north = (lat - clat) * 110540.0
    return east, -north


def poly_area_signed(pts: list[tuple[float, float]]) -> float:
    acc = 0.0
    n = len(pts)
    for i in range(n):
        x0, z0 = pts[i]
        x1, z1 = pts[(i + 1) % n]
        acc += x0 * z1 - x1 * z0
    return acc * 0.5


def simplify_ring(pts: list[tuple[float, float]], tol: float = 0.6) -> list[tuple[float, float]]:
    if len(pts) <= 8:
        return pts
    out = [pts[0]]
    for p in pts[1:]:
        if math.hypot(p[0] - out[-1][0], p[1] - out[-1][1]) >= tol:
            out.append(p)
    if len(out) > 3 and math.hypot(out[0][0] - out[-1][0], out[0][1] - out[-1][1]) < tol:
        out.pop()
    # Collinear prune
    cleaned = []
    n = len(out)
    for i in range(n):
        a = out[(i - 1) % n]
        b = out[i]
        c = out[(i + 1) % n]
        v1 = (b[0] - a[0], b[1] - a[1])
        v2 = (c[0] - b[0], c[1] - b[1])
        l1 = math.hypot(*v1)
        l2 = math.hypot(*v2)
        if l1 > 0.01 and l2 > 0.01:
            cross = abs(v1[0] * v2[1] - v1[1] * v2[0]) / (l1 * l2)
            if cross < 0.04 and len(out) > 4:
                continue
        cleaned.append(b)
    return cleaned if len(cleaned) >= 3 else pts[:4]


def outline_frame(pts_ll: list[tuple[float, float]]):
    clat = sum(p[0] for p in pts_ll) / len(pts_ll)
    clon = sum(p[1] for p in pts_ll) / len(pts_ll)
    xz = [xz_from_latlon(lat, lon, clat, clon) for lat, lon in pts_ll]
    best_len = 0.0
    bdx, bdz = 1.0, 0.0
    n = len(xz)
    for i in range(n):
        dx = xz[(i + 1) % n][0] - xz[i][0]
        dz = xz[(i + 1) % n][1] - xz[i][1]
        sl = math.hypot(dx, dz)
        if sl > best_len:
            best_len = sl
            bdx, bdz = dx / sl, dz / sl
    # LandmarkSites turns model +X onto bearing (90 - yaw_deg) or axis(yaw_deg):
    # axis = Vector2(cos(yaw), sin(yaw)) in XZ (+X east, +Z south) where yaw_deg is clockwise around +Y (-yaw_deg)
    # Check: rotation.y = deg_to_rad(-yaw_deg) -> +X maps to (cos(yaw), +sin(yaw)) in (X, Z) when yaw>0!
    yaw_deg = math.degrees(math.atan2(bdz, bdx))
    while yaw_deg >= 90.0:
        yaw_deg -= 180.0
    while yaw_deg < -90.0:
        yaw_deg += 180.0
    rad = math.radians(yaw_deg)
    ca, sa = math.cos(rad), math.sin(rad)
    local = [(round(x * ca + z * sa, 1), round(-x * sa + z * ca, 1)) for x, z in xz]
    if poly_area_signed(local) < 0:
        local.reverse()
    return clat, clon, round(yaw_deg, 1), simplify_ring(local)


def slugify(name: str, eid: str) -> str:
    s = re.sub(r"[^a-z0-9]+", "_", name.lower()).strip("_")
    return s if s else eid.replace(":", "_")


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("source", type=Path)
    ap.add_argument("ids", nargs="*", help="way:<id> or relation:<id>")
    ap.add_argument("--min-height", type=float, default=90.0)
    args = ap.parse_args()

    els = load_elements(args.source)
    buildings = {}
    parts = []
    tall_others = []

    for el in els:
        tags = el.get("tags", {})
        eid = f"{el.get('type')}:{el.get('id')}"
        pts = ring_pts(el)
        if len(pts) < 3:
            continue
        h = parse_h(tags.get("height", ""))
        lv_s = str(tags.get("building:levels", ""))
        lv = float(lv_s) if re.match(r"^\d+(\.\d+)?$", lv_s) else 0.0
        eff_h = h if h > 0 else lv * 3.5
        clat = sum(p[0] for p in pts) / len(pts)
        clon = sum(p[1] for p in pts) / len(pts)
        if "building" in tags:
            buildings[eid] = (el, pts, clat, clon, eff_h)
            if eff_h > 40.0:
                tall_others.append((eid, clat, clon, eff_h, tags.get("name", "")))
        if "building:part" in tags and "building" not in tags:
            min_h = parse_h(tags.get("min_height", ""))
            min_lv_s = str(tags.get("building:min_levels", ""))
            min_lv = float(min_lv_s) if re.match(r"^\d+(\.\d+)?$", min_lv_s) else 0.0
            y0 = min_h if min_h > 0 else min_lv * 3.5
            if eff_h > y0 + 1.0:
                parts.append((eid, pts, clat, clon, round(y0, 1), round(eff_h, 1)))

    targets = args.ids if args.ids else [
        eid for eid, (el, _, _, _, eh) in buildings.items()
        if eh >= args.min_height and el.get("tags", {}).get("name")
    ]

    for eid in targets:
        if eid not in buildings:
            print(f"# MISSING: {eid}", file=sys.stderr)
            continue
        el, pts_ll, clat, clon, eff_h = buildings[eid]
        tags = el.get("tags", {})
        clat, clon, yaw, base_poly = outline_frame(pts_ll)
        rad = math.radians(yaw)
        ca, sa = math.cos(rad), math.sin(rad)
        xs = [p[0] for p in base_poly]
        zs = [p[1] for p in base_poly]
        span_x = max(xs) - min(xs)
        span_z = max(zs) - min(zs)
        diag_half = 0.5 * math.hypot(span_x, span_z)

        # Match parts whose centroid falls near outline
        matched = []
        for pid, ppts, pclat, pclon, y0, y1 in parts:
            dx, dz = xz_from_latlon(pclat, pclon, clat, clon)
            lx = dx * ca + dz * sa
            lz = -dx * sa + dz * ca
            if abs(lx) <= span_x * 0.55 + 6.0 and abs(lz) <= span_z * 0.55 + 6.0:
                lring = []
                for plat, plon in ppts:
                    px, pz = xz_from_latlon(plat, plon, clat, clon)
                    lring.append((round(px * ca + pz * sa, 1), round(-px * sa + pz * ca, 1)))
                if poly_area_signed(lring) < 0:
                    lring.reverse()
                matched.append((y0, y1, simplify_ring(lring)))

        matched.sort(key=lambda item: (item[0], item[1]))
        top_m = max([eff_h] + [m[1] for m in matched])
        top_m = round(max(top_m, 45.0), 1)

        # Compute safe clear_m against tall_others
        max_clear = round(diag_half + 8.0, 1)
        for oid, olat, olon, oh, _ in tall_others:
            if oid == eid:
                continue
            dx, dz = xz_from_latlon(olat, olon, clat, clon)
            lx = abs(dx * ca + dz * sa)
            lz = abs(-dx * sa + dz * ca)
            if lx <= span_x * 0.5 + 8.0 and lz <= span_z * 0.5 + 8.0:
                continue
            dist = math.hypot(dx, dz)
            if dist - 2.0 < max_clear:
                max_clear = max(12.0, math.floor(dist - 2.0))

        ops = []
        if matched:
            for y0, y1, lring in matched[:8]:
                pts_txt = "[" + ", ".join(f"[{x}, {z}]" for x, z in lring) + "]"
                ops.append(f'["poly", {y0}, {y1}, {pts_txt}]')
        else:
            pts_txt = "[" + ", ".join(f"[{x}, {z}]" for x, z in base_poly) + "]"
            ops.append(f'["poly", 0.0, {top_m}, {pts_txt}]')

        name = tags.get("name", eid)
        slug = slugify(name, eid)
        wiki = tags.get("wikipedia", "").removeprefix("en:") or name
        print(f'\t\t# {eid}: {len(matched)} parts, OSM top {top_m} m ({span_x:.1f}x{span_z:.1f} m)')
        print(f'\t\tMiamiTowerSpecs.row("{slug}", "{name}", {clat:.6f}, {clon:.6f}, {top_m}, {yaw}, {max_clear:.1f},')
        print(f'\t\t\t"{wiki}", 1, ["{name.lower()}"],')
        print(f'\t\t\t{{"finish": "lowe_blue", "bay": 3.0, "floor": 3.6, "ops": [{", ".join(ops)}]}}),')


if __name__ == "__main__":
    main()
