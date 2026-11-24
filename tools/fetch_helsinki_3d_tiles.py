#!/usr/bin/env python3
"""
Fetches City of Helsinki 3D+ City Reality Mesh 3D Tiles (.b3dm / .glb)
intersecting each monument in tools/helsinki_3d_monuments.json.

Source: https://kartta.hel.fi/3d/mesh/Helsinki_2024/tileset.json (primary)
        https://kartta.hel.fi/3d/mesh/Helsinki_2017/tileset.json (leaf-off fallback)
License: CC BY 4.0 — © City of Helsinki, 3D city model

Outputs per monument into build/helsinki_3d_cache/<monument_id>/:
  - tile_<k>.glb           (stripped b3dm payload)
  - manifest.json          (lat, lon, ECEF->ENU transform, per-tile RTC_CENTER & matrix)

Usage:
  python3 tools/fetch_helsinki_3d_tiles.py [--only id1,id2] [--max-depth 24]
"""

import argparse
import hashlib
import json
import math
import os
import struct
import sys
import urllib.error
import urllib.parse
import urllib.request

REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
MANIFEST_PATH = os.path.join(REPO_ROOT, "tools", "helsinki_3d_monuments.json")
CACHE_ROOT = os.path.join(REPO_ROOT, "build", "helsinki_3d_cache")
RAW_CACHE = os.path.join(CACHE_ROOT, "_raw")
HEADERS = {"User-Agent": "planet-render-360 data tool", "Accept-Encoding": "identity"}

WGS84_A = 6378137.0
WGS84_F = 1.0 / 298.257223563
WGS84_E2 = WGS84_F * (2.0 - WGS84_F)


def lla_to_ecef(lat_deg, lon_deg, h=0.0):
    lat = math.radians(lat_deg)
    lon = math.radians(lon_deg)
    sl, cl = math.sin(lat), math.cos(lat)
    n = WGS84_A / math.sqrt(1.0 - WGS84_E2 * sl * sl)
    return (
        (n + h) * cl * math.cos(lon),
        (n + h) * cl * math.sin(lon),
        (n * (1.0 - WGS84_E2) + h) * sl,
    )


def enu_basis(lat_deg, lon_deg):
    """Returns unit ECEF vectors (east, north, up) at (lat_deg, lon_deg)."""
    lat = math.radians(lat_deg)
    lon = math.radians(lon_deg)
    sl, cl = math.sin(lat), math.cos(lat)
    so, co = math.sin(lon), math.cos(lon)
    east = (-so, co, 0.0)
    north = (-sl * co, -sl * so, cl)
    up = (cl * co, cl * so, sl)
    return east, north, up


def fetch_bytes(url):
    os.makedirs(RAW_CACHE, exist_ok=True)
    key = hashlib.sha256(url.encode("utf-8")).hexdigest()[:20]
    ext = os.path.splitext(urllib.parse.urlparse(url).path)[1] or ".bin"
    cached = os.path.join(RAW_CACHE, key + ext)
    if os.path.exists(cached) and os.path.getsize(cached) > 0:
        with open(cached, "rb") as f:
            return f.read()
    req = urllib.request.Request(url, headers=HEADERS)
    with urllib.request.urlopen(req, timeout=30) as resp:
        data = resp.read()
    with open(cached, "wb") as f:
        f.write(data)
    return data


def fetch_json(url):
    return json.loads(fetch_bytes(url).decode("utf-8"))


def mat4_mul(a, b):
    """Column-major 4x4 matrix multiply (3D Tiles convention)."""
    out = [0.0] * 16
    for c in range(4):
        for r in range(4):
            out[c * 4 + r] = sum(a[k * 4 + r] * b[c * 4 + k] for k in range(4))
    return out


IDENTITY = [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1]


def bv_intersects(bv, lat_deg, lon_deg, radius_m, pt_ecef):
    if not bv:
        return True
    if "region" in bv:
        w, s, e, n, _minh, _maxh = bv["region"]
        lat_r = math.radians(lat_deg)
        lon_r = math.radians(lon_deg)
        dlat = (radius_m + 3.0) / 6371000.0
        dlon = dlat / max(math.cos(lat_r), 0.1)
        return not (lon_r + dlon < w or lon_r - dlon > e or lat_r + dlat < s or lat_r - dlat > n)
    if "sphere" in bv:
        sx, sy, sz, sr = bv["sphere"]
        dx = pt_ecef[0] - sx
        dy = pt_ecef[1] - sy
        dz = pt_ecef[2] - sz
        return math.sqrt(dx * dx + dy * dy + dz * dz) <= (sr + radius_m + 3.0)
    if "box" in bv:
        bx, by, bz = bv["box"][0:3]
        # Half-axis lengths bound sphere radius
        hx = math.sqrt(sum(v * v for v in bv["box"][3:6]))
        hy = math.sqrt(sum(v * v for v in bv["box"][6:9]))
        hz = math.sqrt(sum(v * v for v in bv["box"][9:12]))
        br = math.sqrt(hx * hx + hy * hy + hz * hz)
        dx = pt_ecef[0] - bx
        dy = pt_ecef[1] - by
        dz = pt_ecef[2] - bz
        return math.sqrt(dx * dx + dy * dy + dz * dz) <= (br + radius_m + 12.0)
    return True


def collect_leaf_tiles(tileset_url, lat_deg, lon_deg, radius_m, max_depth=24):
    pt_ecef = lla_to_ecef(lat_deg, lon_deg, 25.0)
    leaves = []

    def walk_node(node, base_url, parent_xf, depth):
        if depth > max_depth:
            return
        if not bv_intersects(node.get("boundingVolume"), lat_deg, lon_deg, radius_m, pt_ecef):
            return
        xf = mat4_mul(parent_xf, node["transform"]) if "transform" in node else parent_xf
        content = node.get("content") or (node.get("contents", [None])[0] if node.get("contents") else None)
        children = node.get("children") or []

        # Descend into intersecting children first (REPLACE refinement means finest leaves win)
        child_hits = 0
        for ch in children:
            before = len(leaves)
            walk_node(ch, base_url, xf, depth + 1)
            if len(leaves) > before:
                child_hits += 1

        if content and "uri" in content:
            uri = urllib.parse.urljoin(base_url, content["uri"])
            low = uri.lower()
            if low.endswith(".json"):
                try:
                    sub = fetch_json(uri)
                    if "root" in sub:
                        walk_node(sub["root"], uri, xf, depth + 1)
                except Exception as exc:
                    print(f"  [warn] failed sub-tileset {uri}: {exc}", flush=True)
            elif (low.endswith(".b3dm") or low.endswith(".glb")) and child_hits == 0:
                leaves.append({
                    "uri": uri,
                    "geometricError": float(node.get("geometricError", 999.0)),
                    "transform": xf,
                })

    root_doc = fetch_json(tileset_url)
    if "root" in root_doc:
        walk_node(root_doc["root"], tileset_url, IDENTITY, 0)
    # Keep finest-detail tiles (lowest geometricError)
    leaves.sort(key=lambda item: item["geometricError"])
    if leaves:
        min_err = max(leaves[0]["geometricError"], 0.05)
        finest = [l for l in leaves if l["geometricError"] <= min_err * 2.5]
        return finest[:16]
    return []


def unpack_b3dm(raw_bytes):
    """Strips b3dm header and returns (glb_bytes, rtc_center_or_None)."""
    if raw_bytes[:4] == b"glTF":
        return raw_bytes, None
    if raw_bytes[:4] != b"b3dm":
        raise ValueError(f"Unsupported tile magic: {raw_bytes[:4]!r}")
    _magic, _ver, _byte_len, ft_json_len, ft_bin_len, bt_json_len, bt_bin_len = struct.unpack_from("<4sIIIIII", raw_bytes, 0)
    ft_start = 28
    ft_end = ft_start + ft_json_len
    rtc = None
    if ft_json_len > 0:
        ft_str = raw_bytes[ft_start:ft_end].decode("utf-8", errors="ignore").strip("\x00 ")
        if ft_str:
            try:
                ft = json.loads(ft_str)
                if "RTC_CENTER" in ft:
                    rtc = [float(v) for v in ft["RTC_CENTER"]]
            except Exception:
                pass
    glb_offset = 28 + ft_json_len + ft_bin_len + bt_json_len + bt_bin_len
    glb_bytes = raw_bytes[glb_offset:]
    if glb_bytes[:4] != b"glTF":
        idx = raw_bytes.find(b"glTF", 28)
        if idx >= 0:
            glb_bytes = raw_bytes[idx:]
    return glb_bytes, rtc


def fetch_monument(mon, cfg, max_depth):
    mid = mon["id"]
    lat, lon, rad = float(mon["lat"]), float(mon["lon"]), float(mon["radius_m"])
    ds = mon.get("dataset", "2024")
    primary_url = cfg["source"]["primary_tileset"] if ds == "2024" else cfg["source"]["fallback_tileset"]
    fallback_url = cfg["source"]["fallback_tileset"] if ds == "2024" else cfg["source"]["primary_tileset"]

    print(f"[fetch] {mid} ({lat:.5f}, {lon:.5f}, r={rad}m) via {ds}...", flush=True)
    leaves = collect_leaf_tiles(primary_url, lat, lon, rad, max_depth=max_depth)
    used_ds = ds
    if not leaves:
        print(f"  [fallback] no leaves in {ds}, trying fallback tileset...", flush=True)
        leaves = collect_leaf_tiles(fallback_url, lat, lon, rad, max_depth=max_depth)
        used_ds = "fallback"

    out_dir = os.path.join(CACHE_ROOT, mid)
    os.makedirs(out_dir, exist_ok=True)
    origin_ecef = lla_to_ecef(lat, lon, 0.0)
    east, north, up = enu_basis(lat, lon)

    tile_records = []
    for k, leaf in enumerate(leaves):
        try:
            raw = fetch_bytes(leaf["uri"])
            glb_bytes, rtc = unpack_b3dm(raw)
            glb_name = f"tile_{k}.glb"
            with open(os.path.join(out_dir, glb_name), "wb") as f:
                f.write(glb_bytes)
            tile_records.append({
                "file": glb_name,
                "uri": leaf["uri"],
                "geometricError": leaf["geometricError"],
                "transform": leaf["transform"],
                "rtc_center": rtc,
            })
        except Exception as exc:
            print(f"  [warn] tile {leaf['uri']} failed: {exc}", flush=True)

    meta = {
        "id": mid,
        "dataset": used_ds,
        "lat": lat,
        "lon": lon,
        "origin_ecef": list(origin_ecef),
        "east": list(east),
        "north": list(north),
        "up": list(up),
        "tiles": tile_records,
    }
    with open(os.path.join(out_dir, "manifest.json"), "w", encoding="utf-8") as f:
        json.dump(meta, f, indent=2)
    print(f"  -> {len(tile_records)} leaf tile(s) saved to {out_dir}", flush=True)
    return len(tile_records)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--only", default="", help="Comma-separated monument IDs to fetch")
    ap.add_argument("--max-depth", type=int, default=24)
    args = ap.parse_args()

    with open(MANIFEST_PATH, "r", encoding="utf-8") as f:
        cfg = json.load(f)
    wanted = set(x.strip() for x in args.only.split(",") if x.strip()) if args.only else None

    total = 0
    for mon in cfg["monuments"]:
        if wanted and mon["id"] not in wanted:
            continue
        total += fetch_monument(mon, cfg, args.max_depth)
    print(f"=== Helsinki 3D+ Tile Harvest Complete ({total} leaf tiles) ===", flush=True)


if __name__ == "__main__":
    main()
