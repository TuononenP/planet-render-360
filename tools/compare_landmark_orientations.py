#!/usr/bin/env python3
"""Compare handbuilt landmark orientations against bundled OSM building footprints.

Usage:
  python3 tools/compare_landmark_orientations.py <census.tsv> <out_report.md> <out_table.tsv>
"""

import csv
import json
import math
import os
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))
import osmb  # noqa: E402

SNAPSHOTS_DIR = ROOT / "assets" / "osm_snapshots"
BUNDLED_GD = ROOT / "scripts" / "data" / "bundled_osm.gd"
CAPITAL_MANIFEST = SNAPSHOTS_DIR / "capital_manifest.json"


def load_snapshot_index():
    """Return list of (key, lat, lon, layer, path) for all bundled .osmb files."""
    index = []
    if CAPITAL_MANIFEST.exists():
        data = json.loads(CAPITAL_MANIFEST.read_text(encoding="utf-8"))
        for key, row in data.items():
            layer = row[2]
            if layer not in ("detailed", "detailed_extract", "ring1600", "ring2500", "far"):
                continue
            p = SNAPSHOTS_DIR / f"{key}.osmb"
            if p.exists():
                index.append((key, float(row[0]), float(row[1]), layer, p))
    if BUNDLED_GD.exists():
        txt = BUNDLED_GD.read_text(encoding="utf-8")
        for m in re.finditer(
            r'"([^"]+)"\s*:\s*\[\s*([-\d.]+)\s*,\s*([-\d.]+)\s*,\s*"([^"]+)"', txt
        ):
            key, lat, lon, layer = m.group(1), float(m.group(2)), float(m.group(3)), m.group(4)
            if layer not in ("detailed", "detailed_extract", "ring1600", "ring2500", "far"):
                continue
            p = SNAPSHOTS_DIR / f"{key}.osmb"
            if p.exists():
                index.append((key, lat, lon, layer, p))
    # Prioritize detailed > ring1600 > ring2500 > far
    prio = {"detailed": 0, "detailed_extract": 0, "ring1600": 1, "ring2500": 2, "far": 3}
    index.sort(key=lambda r: prio.get(r[3], 9))
    return index


def approx_dist_m(lat1, lon1, lat2, lon2):
    dy = (lat2 - lat1) * 111320.0
    dx = (lon2 - lon1) * math.cos(math.radians(0.5 * (lat1 + lat2))) * 111320.0
    return math.hypot(dx, dy)


def to_local_en(lat, lon, lat0, lon0):
    """Return (east_m, north_m) relative to (lat0, lon0)."""
    e = (lon - lon0) * math.cos(math.radians(lat0)) * 111320.0
    n = (lat - lat0) * 111320.0
    return (e, n)


def point_in_poly(x, y, poly):
    inside = False
    n = len(poly)
    j = n - 1
    for i in range(n):
        xi, yi = poly[i]
        xj, yj = poly[j]
        if ((yi > y) != (yj > y)) and (x < (xj - xi) * (y - yi) / (yj - yi + 1e-18) + xi):
            inside = not inside
        j = i
    return inside


def poly_area(poly):
    a = 0.0
    n = len(poly)
    for i in range(n):
        x1, y1 = poly[i]
        x2, y2 = poly[(i + 1) % n]
        a += x1 * y2 - x2 * y1
    return abs(a) * 0.5


def convex_hull(pts):
    pts = sorted(set(pts))
    if len(pts) <= 2:
        return pts

    def cross(o, a, b):
        return (a[0] - o[0]) * (b[1] - o[1]) - (a[1] - o[1]) * (b[0] - o[0])

    lower = []
    for p in pts:
        while len(lower) >= 2 and cross(lower[-2], lower[-1], p) <= 0:
            lower.pop()
        lower.append(p)
    upper = []
    for p in reversed(pts):
        while len(upper) >= 2 and cross(upper[-2], upper[-1], p) <= 0:
            upper.pop()
        upper.append(p)
    return lower[:-1] + upper[:-1]


def min_area_obb(poly_en):
    """Return (long_m, short_m, long_bearing_deg_0_180) for polygon in (east, north) metres."""
    hull = convex_hull(poly_en)
    if len(hull) < 3:
        return None
    best_area = float("inf")
    best = None
    n = len(hull)
    for i in range(n):
        x1, y1 = hull[i]
        x2, y2 = hull[(i + 1) % n]
        dx, dy = x2 - x1, y2 - y1
        L = math.hypot(dx, dy)
        if L < 1e-6:
            continue
        ux, uy = dx / L, dy / L
        vx, vy = -uy, ux
        min_u = min_v = float("inf")
        max_u = max_v = -float("inf")
        for px, py in hull:
            u = px * ux + py * uy
            v = px * vx + py * vy
            if u < min_u:
                min_u = u
            if u > max_u:
                max_u = u
            if v < min_v:
                min_v = v
            if v > max_v:
                max_v = v
        du = max_u - min_u
        dv = max_v - min_v
        area = du * dv
        if area < best_area:
            best_area = area
            if du >= dv:
                # long axis along (ux, uy) in (east, north)
                # true bearing (0=N, 90=E, clockwise) = atan2(east, north)
                bearing = math.degrees(math.atan2(ux, uy)) % 180.0
                best = (du, dv, bearing)
            else:
                bearing = math.degrees(math.atan2(vx, vy)) % 180.0
                best = (dv, du, bearing)
    return best


def extract_polygons(osm_data):
    """Extract (tags, [(lat, lon), ...]) for building/bridge/landmark ways & relations."""
    polys = []
    for el in osm_data.get("elements", []):
        tags = el.get("tags") or {}
        if not any(k in tags for k in ("building", "building:part", "bridge", "man_made", "historic", "tourism", "amenity")):
            continue
        if el.get("type") == "way":
            geom = el.get("geometry")
            if not geom or len(geom) < 3:
                continue
            pts = [(p["lat"], p["lon"]) for p in geom if p is not None]
            if len(pts) >= 3:
                polys.append((tags, pts))
        elif el.get("type") == "relation":
            for m in el.get("members", []):
                if m.get("role") in ("outer", ""):
                    geom = m.get("geometry")
                    if geom and len(geom) >= 3:
                        pts = [(p["lat"], p["lon"]) for p in geom if p is not None]
                        if len(pts) >= 3:
                            polys.append((tags, pts))
    return polys


def angle_diff_mod(a, b, period):
    """Signed shortest difference (a - b) wrapped to (-period/2, period/2]."""
    d = (a - b) % period
    if d > period * 0.5:
        d -= period
    return d


def main():
    if len(sys.argv) < 4:
        print("Usage: compare_landmark_orientations.py <census.tsv> <out_report.md> <out_table.tsv>")
        sys.exit(1)

    census_path = Path(sys.argv[1])
    report_path = Path(sys.argv[2])
    table_path = Path(sys.argv[3])

    rows = []
    with census_path.open(encoding="utf-8") as f:
        for r in csv.DictReader(f, delimiter="\t"):
            if r["category"] in ("core", "bespoke"):
                rows.append(r)

    snap_index = load_snapshot_index()
    snap_cache = {}

    def get_polys(key, path):
        if key not in snap_cache:
            data = osmb.read_osmb(str(path))
            snap_cache[key] = extract_polygons(data)
        return snap_cache[key]

    results = []
    for r in rows:
        lat = float(r["lat"])
        lon = float(r["lon"])
        yaw = float(r["yaw_deg"])
        has_yaw = r["has_yaw"] == "1"
        wx = float(r["width_x_m"])
        dz = float(r["depth_z_m"])
        aspect = float(r["aspect_ratio"])
        long_axis = r["long_axis"]

        # Find candidate snapshots within 3.5 km (or 15 km for far)
        cands = []
        for key, slat, slon, layer, path in snap_index:
            d = approx_dist_m(lat, lon, slat, slon)
            max_r = 12000.0 if layer == "far" else (3000.0 if layer in ("ring2500", "ring1600") else 2200.0)
            if d <= max_r:
                cands.append((d, key, layer, path))
        cands.sort(key=lambda x: (0 if x[2] in ("detailed", "detailed_extract") else 1, x[0]))

        best_match = None
        for _, key, layer, path in cands[:3]:
            polys = get_polys(key, path)
            # Search for polygon containing (lat, lon) or within 30m
            for tags, pts in polys:
                # quick bbox reject
                lats = [p[0] for p in pts]
                lons = [p[1] for p in pts]
                if lat < min(lats) - 0.0005 or lat > max(lats) + 0.0005:
                    continue
                if lon < min(lons) - 0.0007 or lon > max(lons) + 0.0007:
                    continue
                en = [to_local_en(p[0], p[1], lat, lon) for p in pts]
                inside = point_in_poly(0.0, 0.0, en)
                # distance to centroid
                cx = sum(p[0] for p in en) / len(en)
                cy = sum(p[1] for p in en) / len(en)
                cdist = math.hypot(cx, cy)
                if not inside and cdist > 35.0:
                    continue
                obb = min_area_obb(en)
                if not obb:
                    continue
                long_m, short_m, osm_bearing = obb
                area = poly_area(en)
                if area < 4.0:
                    continue
                # Score: prefer containing polygon, building tag, closer centroid, reasonable size
                is_bldg = 1 if ("building" in tags or "building:part" in tags) else 0
                score = (1000 if inside else 0) + (200 if is_bldg else 0) - cdist
                if best_match is None or score > best_match["score"]:
                    best_match = {
                        "score": score,
                        "inside": inside,
                        "cdist": cdist,
                        "long_m": long_m,
                        "short_m": short_m,
                        "osm_bearing": osm_bearing,
                        "osm_name": tags.get("name", tags.get("name:en", "")),
                        "snap": key,
                    }
            if best_match and best_match["inside"]:
                break

        # Compute model world bearing and delta
        # Local +X bears (90 + yaw) mod 360; Local +Z bears (180 + yaw) mod 360
        if long_axis == "X":
            model_bearing = (90.0 + yaw) % 180.0
            period = 180.0
        elif long_axis == "Z":
            model_bearing = (180.0 + yaw) % 180.0
            period = 180.0
        else:
            model_bearing = (90.0 + yaw) % 90.0
            period = 90.0

        status = "NO_OSM"
        delta = None
        osm_bearing_str = ""
        osm_size_str = ""
        osm_name = ""
        snap_used = ""
        if best_match:
            ob = best_match["osm_bearing"]
            osm_aspect = best_match["long_m"] / max(best_match["short_m"], 0.1)
            # If OSM footprint itself is square-ish, compare mod 90
            eff_period = 90.0 if (period == 90.0 or osm_aspect < 1.15) else 180.0
            delta = angle_diff_mod(ob, model_bearing, eff_period)
            abs_d = abs(delta)
            osm_bearing_str = f"{ob:.1f}"
            osm_size_str = f"{best_match['long_m']:.0f}x{best_match['short_m']:.0f}"
            osm_name = best_match["osm_name"]
            snap_used = best_match["snap"]
            if abs_d <= 5.0:
                status = "OK"
            elif abs_d <= 12.0:
                status = "MINOR_DIFF"
            else:
                status = "MISALIGNED_HIGH" if (aspect >= 1.25 and osm_aspect >= 1.25) else "MISALIGNED_MED"

        results.append({
            **r,
            "model_bearing": f"{model_bearing:.1f}",
            "osm_bearing": osm_bearing_str,
            "delta_deg": f"{delta:+.1f}" if delta is not None else "",
            "abs_delta": abs(delta) if delta is not None else -1.0,
            "osm_size_m": osm_size_str,
            "osm_name": osm_name,
            "snap": snap_used,
            "status": status,
        })

    # Write full TSV
    fieldnames = [
        "type", "name", "kind", "category", "lat", "lon",
        "has_yaw", "yaw_deg", "width_x_m", "depth_z_m", "aspect_ratio", "long_axis",
        "model_bearing", "osm_bearing", "delta_deg", "osm_size_m", "status", "osm_name", "snap"
    ]
    table_path.parent.mkdir(parents=True, exist_ok=True)
    with table_path.open("w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(f, fieldnames=fieldnames, delimiter="\t", extrasaction="ignore")
        w.writeheader()
        w.writerows(results)

    # Summary stats
    counts = {}
    for r in results:
        counts[r["status"]] = counts.get(r["status"], 0) + 1

    high = sorted([r for r in results if r["status"] == "MISALIGNED_HIGH"], key=lambda x: -x["abs_delta"])
    med = sorted([r for r in results if r["status"] == "MISALIGNED_MED"], key=lambda x: -x["abs_delta"])
    minor = sorted([r for r in results if r["status"] == "MINOR_DIFF"], key=lambda x: -x["abs_delta"])
    ok = [r for r in results if r["status"] == "OK"]
    no_osm = [r for r in results if r["status"] == "NO_OSM"]

    lines = [
        "# Handbuilt Landmark Orientation Audit Report",
        "",
        f"- **Total handbuilt landmarks**: {len(results)}",
        f"- **Aligned (≤ 5°)**: {len(ok)}",
        f"- **Minor difference (5°–12°)**: {len(minor)}",
        f"- **Misaligned — High priority (elongated, > 12°)**: {len(high)}",
        f"- **Misaligned — Medium priority (square/compact, > 12°)**: {len(med)}",
        f"- **Not matched in bundled OSM snapshots**: {len(no_osm)}",
        "",
        "## High-Priority Misalignments (Elongated, > 12° off OSM footprint)",
        "",
        "| Type | Name | Kind | `yaw_deg` (explicit?) | Model Size (X×Z m) | Model Bearing | OSM Bearing | Delta | OSM Footprint |",
        "|---|---|---|---:|---:|---:|---:|---:|---|",
    ]
    for r in high:
        exp = "" if r["has_yaw"] == "1" else " (default)"
        lines.append(
            f"| `{r['type']}` | {r['name']} | {r['kind']} | {float(r['yaw_deg']):.1f}°{exp} | "
            f"{float(r['width_x_m']):.0f}×{float(r['depth_z_m']):.0f} | {r['model_bearing']}° | "
            f"{r['osm_bearing']}° | **{r['delta_deg']}°** | {r['osm_size_m']} m |"
        )

    lines += [
        "",
        "## Medium-Priority Misalignments (Square / Compact, > 12° off OSM footprint)",
        "",
        "| Type | Name | Kind | `yaw_deg` (explicit?) | Model Size (X×Z m) | Model Bearing | OSM Bearing | Delta | OSM Footprint |",
        "|---|---|---|---:|---:|---:|---:|---:|---|",
    ]
    for r in med:
        exp = "" if r["has_yaw"] == "1" else " (default)"
        lines.append(
            f"| `{r['type']}` | {r['name']} | {r['kind']} | {float(r['yaw_deg']):.1f}°{exp} | "
            f"{float(r['width_x_m']):.0f}×{float(r['depth_z_m']):.0f} | {r['model_bearing']}° | "
            f"{r['osm_bearing']}° | **{r['delta_deg']}°** | {r['osm_size_m']} m |"
        )

    lines += [
        "",
        "## Minor Differences (5°–12°)",
        "",
        "| Type | Name | `yaw_deg` | Model Bearing | OSM Bearing | Delta |",
        "|---|---|---:|---:|---:|---:|",
    ]
    for r in minor:
        lines.append(
            f"| `{r['type']}` | {r['name']} | {float(r['yaw_deg']):.1f}° | "
            f"{r['model_bearing']}° | {r['osm_bearing']}° | {r['delta_deg']}° |"
        )

    lines += [
        "",
        f"## Full List of Unmatched Landmarks ({len(no_osm)} not in bundled OSM snapshots)",
        "",
        "| Type | Name | Kind | `lat`, `lon` | `yaw_deg` (explicit?) | Model Size (X×Z m) |",
        "|---|---|---|---|---:|---:|",
    ]
    for r in no_osm:
        exp = "" if r["has_yaw"] == "1" else " (default)"
        lines.append(
            f"| `{r['type']}` | {r['name']} | {r['kind']} | {float(r['lat']):.4f}, {float(r['lon']):.4f} | "
            f"{float(r['yaw_deg']):.1f}°{exp} | {float(r['width_x_m']):.0f}×{float(r['depth_z_m']):.0f} |"
        )

    report_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print("COMPARISON DONE:", counts)


if __name__ == "__main__":
    main()
