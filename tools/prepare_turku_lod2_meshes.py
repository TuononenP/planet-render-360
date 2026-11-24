#!/usr/bin/env python3
"""Compile true 3D CityGML LoD2 building meshes for the Aurajoki 150 m corridor
into compact zstd-compressed 1 km GK23 cells under assets/city_models/turku_lod2_meshes/.

Reads:
  - build/turku_lod2_boxes/*.xml.gz (City of Turku CC BY 4.0 CityGML 2.0)
  - build/turku_aurajoki_roofs.json (optional: Ilmakuva 2025 sampled roof colour/material)
  - build/turku_aurajoki_facades.json (optional: Panoramax sampled wall colour/material)

Each building record stores quantized integer-cm local coordinates (relative to
the building's GK23 centroid (e, n) and ground base z0), triangulated wall and
roof surfaces with true-metre UVs (in cm) ready for Godot's FacadeShader +
RoofMetalMaps, plus sampled roof/wall attributes.
"""

import gzip
import hashlib
import json
import math
import os
import shutil
import subprocess
import sys
import xml.etree.ElementTree as ET

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lod2m_codec import write_bundle  # noqa: E402
from prepare_turku_lod2 import attribute, parse_use_code, parse_year  # noqa: E402
from sample_turku_roofs import (  # noqa: E402
    BOX_E_RANGE, BOX_N_RANGE, CACHE_BOXES, CORRIDOR_M, INNER_RADIUS_M, NS, in_scope,
)

ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
OUT_DIR = os.path.join(ROOT, "assets", "city_models", "turku_lod2_meshes")
ROOFS_PATH = os.path.join(ROOT, "build", "turku_aurajoki_roofs.json")
FACADES_PATH = os.path.join(ROOT, "build", "turku_aurajoki_facades.json")
CELL_M = 1000
ZSTD_LEVEL = 19


def newell_normal(pts):
    """Outward unit normal and area of a 3D closed ring (last == first)."""
    nx = ny = nz = 0.0
    n = len(pts) - 1
    for i in range(n):
        x0, y0, z0 = pts[i]
        x1, y1, z1 = pts[i + 1]
        nx += (y0 - y1) * (z0 + z1)
        ny += (z0 - z1) * (x0 + x1)
        nz += (x0 - x1) * (y0 + y1)
    ln = math.sqrt(nx * nx + ny * ny + nz * nz)
    if ln < 1e-7:
        return None
    return (nx / ln, ny / ln, nz / ln, ln * 0.5)


def ear_clip_2d(poly):
    """Ear-clipping triangulation of a simple 2D polygon [(u, v), ...].
    Returns list of (i0, i1, i2) index tuples in CCW order."""
    n = len(poly)
    if n < 3:
        return []
    if n == 3:
        return [(0, 1, 2)]
    # Ensure CCW in 2D
    area2 = 0.0
    for i in range(n):
        x0, y0 = poly[i]
        x1, y1 = poly[(i + 1) % n]
        area2 += x0 * y1 - x1 * y0
    idxs = list(range(n))
    if area2 < 0.0:
        idxs.reverse()

    def cross(o, a, b):
        return (a[0] - o[0]) * (b[1] - o[1]) - (a[1] - o[1]) * (b[0] - o[0])

    def pt_in_tri(p, a, b, c):
        c1 = cross(a, b, p)
        c2 = cross(b, c, p)
        c3 = cross(c, a, p)
        return c1 >= -1e-7 and c2 >= -1e-7 and c3 >= -1e-7

    tris = []
    guard = n * n + 10
    while len(idxs) > 3 and guard > 0:
        guard -= 1
        m = len(idxs)
        clipped = False
        for k in range(m):
            i0 = idxs[(k - 1) % m]
            i1 = idxs[k]
            i2 = idxs[(k + 1) % m]
            a, b, c = poly[i0], poly[i1], poly[i2]
            if cross(a, b, c) <= 1e-7:
                continue
            inside = False
            for j in idxs:
                if j in (i0, i1, i2):
                    continue
                if pt_in_tri(poly[j], a, b, c):
                    inside = True
                    break
            if not inside:
                tris.append((i0, i1, i2))
                idxs.pop(k)
                clipped = True
                break
        if not clipped:
            # Fallback fan for degenerate/nearly-collinear CityGML polygons
            for k in range(1, len(idxs) - 1):
                tris.append((idxs[0], idxs[k], idxs[k + 1]))
            break
    if len(idxs) == 3:
        tris.append((idxs[0], idxs[1], idxs[2]))
    return tris


def dedup_ring(pts):
    """Strip closing duplicate and consecutive near-identical vertices."""
    if len(pts) < 4:
        return []
    out = []
    for p in pts[:-1]:
        if not out or math.hypot(p[0] - out[-1][0], p[1] - out[-1][1], p[2] - out[-1][2]) > 0.02:
            out.append(p)
    if len(out) >= 2 and math.hypot(out[0][0] - out[-1][0], out[0][1] - out[-1][1], out[0][2] - out[-1][2]) <= 0.02:
        out.pop()
    return out


def add_polygon(pts_closed, is_roof, ce, cn, z0, verts, uvs, indices):
    """Triangulate one 3D CityGML polygon into Godot local (dE, dZ, -dN) cm arrays."""
    norm = newell_normal(pts_closed)
    if norm is None:
        return
    nx_g, ny_g, nz_g, area = norm  # ENU outward normal (E, N, Z)
    if area < 0.08:
        return
    ring = dedup_ring(pts_closed)
    if len(ring) < 3:
        return

    # Convert to Godot right-handed local coords: x = E - ce, y = Z - z0, z = -(N - cn)
    # Outward normal in Godot coords: (nx_g, nz_g, -ny_g)
    gnx, gny, gnz = nx_g, nz_g, -ny_g
    gpts = [(p[0] - ce, p[2] - z0, -(p[1] - cn)) for p in ring]

    # Build orthonormal (T, B) on the polygon plane so (T x B) aligns with outward normal
    if not is_roof:
        # Vertical wall: T = normalize(UP x N) -> horizontal along wall; B = UP
        tx, ty, tz = gnz, 0.0, -gnx
        tl = math.hypot(tx, tz)
        if tl < 1e-5:
            tx, ty, tz = 1.0, 0.0, 0.0
        else:
            tx, tz = tx / tl, tz / tl
        bx, by, bz = 0.0, 1.0, 0.0
    else:
        # Roof facet: ensure outward normal points upward (gny > 0)
        if gny < 0.0:
            gnx, gny, gnz = -gnx, -gny, -gnz
        # T horizontal along contour: normalize(UP x N), fallback (1, 0, 0) for flat roof
        tx, ty, tz = gnz, 0.0, -gnx
        tl = math.hypot(tx, tz)
        if tl < 1e-4:
            tx, ty, tz = 1.0, 0.0, 0.0
            bx, by, bz = 0.0, 0.0, -1.0
        else:
            tx, tz = tx / tl, tz / tl
            # B = N x T (points up-slope)
            bx = gny * tz - gnz * ty
            by = gnz * tx - gnx * tz
            bz = gnx * ty - gny * tx

    # Project onto (T, B) for 2D triangulation & UV mapping
    p0 = gpts[0]
    proj = []
    for p in gpts:
        dx, dy, dz = p[0] - p0[0], p[1] - p0[1], p[2] - p0[2]
        proj.append((dx * tx + dy * ty + dz * tz, dx * bx + dy * by + dz * bz))

    tris = ear_clip_2d(proj)
    if not tris:
        return

    # Wall UV origin: u = 0 at min u on this polygon, v = 0 at top of polygon (increases downward)
    u_min = min(p[0] for p in proj)
    v_max = max(p[1] for p in proj)
    v_min = min(p[1] for p in proj)

    base = len(verts) // 3
    for idx_v, p in enumerate(gpts):
        verts.append(int(round(p[0] * 100.0)))
        verts.append(int(round(p[1] * 100.0)))
        verts.append(int(round(p[2] * 100.0)))
        u_m = proj[idx_v][0] - u_min
        v_m = (v_max - proj[idx_v][1]) if not is_roof else (proj[idx_v][1] - v_min)
        uvs.append(int(round(u_m * 100.0)))
        uvs.append(int(round(v_m * 100.0)))

    # Godot front-face is CW when viewed from outside: check each triangle's geometric normal
    # against (gnx, gny, gnz) and orient CW (meaning (p1-p0) x (p2-p0) points INWARD in Godot).
    # In Godot's right-handed coords, CW viewed from outside => (p2-p0) x (p1-p0) points OUTWARD.
    for i0, i1, i2 in tris:
        a, b, c = gpts[i0], gpts[i1], gpts[i2]
        abx, aby, abz = b[0] - a[0], b[1] - a[1], b[2] - a[2]
        acx, acy, acz = c[0] - a[0], c[1] - a[1], c[2] - a[2]
        # Cross product (ab x ac)
        cx = aby * acz - abz * acy
        cy = abz * acx - abx * acz
        cz = abx * acy - aby * acx
        dot = cx * gnx + cy * gny + cz * gnz
        if dot > 0.0:
            # CCW from outside -> swap to CW for Godot front-face
            indices.extend((base + i0, base + i2, base + i1))
        else:
            indices.extend((base + i0, base + i1, base + i2))


def zstd_compress(payload):
    if shutil.which("zstd") is None:
        raise RuntimeError("zstd CLI is required")
    return subprocess.run(
        ["zstd", "-q", "-c", f"-{ZSTD_LEVEL}"],
        input=payload, capture_output=True, check=True,
    ).stdout


def main():
    roofs_db = {}
    if os.path.exists(ROOFS_PATH):
        with open(ROOFS_PATH) as f:
            roofs_db = json.load(f).get("buildings", {})
    facades_db = {}
    if os.path.exists(FACADES_PATH):
        with open(FACADES_PATH) as f:
            facades_db = json.load(f).get("buildings", {})

    seen = {}
    for e0 in range(BOX_E_RANGE[0], BOX_E_RANGE[1], 500):
        for n0 in range(BOX_N_RANGE[0], BOX_N_RANGE[1], 500):
            fn = os.path.join(CACHE_BOXES, f"{e0}_{n0}.xml.gz")
            if not os.path.exists(fn):
                continue
            root = ET.fromstring(gzip.open(fn, "rb").read())
            for b in root.iter("{%s}Building" % NS["bldg"]):
                gid = b.get("{%s}id" % NS["gml"]) or ""
                if gid in seen:
                    continue
                wall_rings = []
                roof_rings = []
                zmin, zmax = math.inf, -math.inf
                plan_area = 0.0
                ce_sum = cn_sum = w_sum = 0.0

                for kind in ("WallSurface", "RoofSurface", "GroundSurface", "BuildingInstallation"):
                    for surf in b.iter("{%s}%s" % (NS["bldg"], kind)):
                        for ring in surf.iter("{%s}LinearRing" % NS["gml"]):
                            pts = []
                            for pos in ring.findall("gml:pos", NS):
                                v = (pos.text or "").split()
                                if len(v) >= 3:
                                    pts.append((float(v[0]), float(v[1]), float(v[2])))
                            if len(pts) < 4:
                                continue
                            zs = [p[2] for p in pts]
                            zmin = min(zmin, min(zs))
                            zmax = max(zmax, max(zs))
                            if kind == "WallSurface":
                                wall_rings.append(pts)
                            elif kind == "RoofSurface":
                                roof_rings.append(pts)
                                nm = newell_normal(pts)
                                if nm is not None and abs(nm[2]) > 0.15:
                                    a_proj = nm[3] * abs(nm[2])
                                    plan_area += a_proj
                                    k = len(pts) - 1
                                    ce_sum += a_proj * (sum(p[0] for p in pts[:k]) / k)
                                    cn_sum += a_proj * (sum(p[1] for p in pts[:k]) / k)
                                    w_sum += a_proj
                            elif kind == "BuildingInstallation":
                                nm = newell_normal(pts)
                                if nm is not None:
                                    if abs(nm[2]) > 0.45:
                                        roof_rings.append(pts)
                                    else:
                                        wall_rings.append(pts)

                if plan_area < 12.0 or not wall_rings or not roof_rings or w_sum <= 0.0:
                    continue
                ce = ce_sum / w_sum
                cn = cn_sum / w_sum
                if not in_scope(ce, cn):
                    continue
                h = max(0.0, zmax - zmin)
                if h < 2.2:
                    continue

                wv, wu, wi = [], [], []
                rv, ru, ri = [], [], []
                for pts in wall_rings:
                    add_polygon(pts, False, ce, cn, zmin, wv, wu, wi)
                for pts in roof_rings:
                    add_polygon(pts, True, ce, cn, zmin, rv, ru, ri)
                if not wi or not ri:
                    continue

                vtj = attribute(b, "pysyvarakennustunnus")
                key = vtj if vtj else gid
                storeys = 0
                st = b.find("bldg:storeysAboveGround", NS)
                if st is not None and st.text and st.text.strip().isdigit():
                    storeys = int(st.text.strip())
                if storeys <= 0:
                    kl = attribute(b, "kerrosluku")
                    if kl.isdigit():
                        storeys = int(kl)
                if storeys <= 0 or storeys >= 200:
                    storeys = max(1, int(round(h / 3.3)))

                rec = {
                    "id": key,
                    "e": round(ce, 1),
                    "n": round(cn, 1),
                    "z0": round(zmin, 2),
                    "area": round(plan_area, 1),
                    "h": round(h, 2),
                    "st": storeys,
                    "yr": parse_year(b),
                    "use": parse_use_code(b),
                    "wv": wv,
                    "wu": wu,
                    "wi": wi,
                    "rv": rv,
                    "ru": ru,
                    "ri": ri,
                }
                rf = roofs_db.get(key)
                if rf:
                    rec["rm"] = rf["roof_material"]
                    rec["rc"] = rf["roof_colour"]
                fc = facades_db.get(key)
                if fc:
                    rec["wm"] = fc["wall_material"]
                    rec["wc"] = fc["wall_colour"]
                seen[gid] = rec

    cells = {}
    for rec in seen.values():
        ck = f"{int(rec['e'] // CELL_M)}_{int(rec['n'] // CELL_M)}"
        cells.setdefault(ck, []).append(rec)

    meta = {
        "source": "City of Turku 3D city model (bldg:Building_LOD2) + Ilmakuva 2025 + Mapillary + Panoramax",
        "licence": "CC BY 4.0 © City of Turku; CC BY-SA 4.0 Mapillary & Panoramax contributors",
        "crs": "EPSG:3877",
        "corridor_m": CORRIDOR_M,
        "inner_radius_m": INNER_RADIUS_M,
        "cell_m": CELL_M,
    }
    nb, total_tris, total_raw, total_comp = write_bundle(OUT_DIR, cells, meta)

    with_roof = sum(1 for r in seen.values() if "rc" in r)
    with_wall = sum(1 for r in seen.values() if "wc" in r)
    print(
        f"Compiled {nb} Turku LoD2 meshes ({total_tris:,} tris) into {len(cells)} binary v2 cells: "
        f"{total_raw / 1024:.0f} KB raw -> {total_comp / 1024:.0f} KB zstd"
    )
    print(f"  with Ilmakuva roof colour: {with_roof}/{nb}, with street wall colour: {with_wall}/{nb}")


if __name__ == "__main__":
    main()
