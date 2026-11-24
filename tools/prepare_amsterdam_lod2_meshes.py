#!/usr/bin/env python3
"""Compile true 3D 3DBAG LoD2.2 building meshes for central Amsterdam into
compact binary v2 .lod2m (PackedInt32Array zstd) 1 km RD New (EPSG:28992) cells
under assets/city_models/amsterdam_lod2_meshes/.

Data sources (all CC BY 4.0):
  - 3D building geometry: TU Delft / 3DGI 3DBAG API (api.3dbag.nl, LoD 2.2)
  - Real-life roof colour sampling: PDOK Luchtfoto Actueel_orthoHR (WMS EPSG:28992)
"""

import concurrent.futures
import json
import math
import os
import struct
import subprocess
import sys
import urllib.request

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lod2m_codec import write_bundle  # noqa: E402

ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
OUT_DIR = os.path.join(ROOT, "assets", "city_models", "amsterdam_lod2_meshes")
BAG_CACHE = os.path.join(ROOT, "build", "amsterdam_3dbag_cache")
ORTHO_CACHE = os.path.join(ROOT, "build", "amsterdam_ortho_cache")
CELL_M = 1000
SUB_M = 250  # 250 m query tiles keep 3DBAG API fast & reliable

# 3x3 km core covering Dam, Grachtengordel, Jordaan, Centraal, Oosterdok,
# Museumplein, Amstel, Plantage and Overhoeks (centre 52.37403, 4.88969 -> RD 121077, 487450).
X_CELLS = [120, 121, 122]
Y_CELLS = [486, 487, 488]
UA = "planet-render-360/1.0 (Amsterdam LoD2.2 builder)"


def fetch_bytes(url, cache_path, timeout=25):
    if os.path.exists(cache_path) and os.path.getsize(cache_path) > 0:
        with open(cache_path, "rb") as f:
            return f.read()
    os.makedirs(os.path.dirname(cache_path), exist_ok=True)
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    for attempt in range(3):
        try:
            with urllib.request.urlopen(req, timeout=timeout) as r:
                raw = r.read()
            tmp = cache_path + ".tmp"
            with open(tmp, "wb") as f:
                f.write(raw)
            os.replace(tmp, cache_path)
            return raw
        except Exception:
            if attempt == 2:
                return b""
    return b""


class BmpImage:
    """Minimal pure-Python 24/32-bit uncompressed BMP reader (decoded via macOS sips)."""
    def __init__(self, path):
        data = open(path, "rb").read()
        self.off = struct.unpack_from("<I", data, 10)[0]
        self.w, self.h = struct.unpack_from("<ii", data, 18)
        self.bpp = struct.unpack_from("<H", data, 28)[0]
        self.top_down = self.h < 0
        self.h = abs(self.h)
        self.stride = ((self.w * (self.bpp // 8) + 3) // 4) * 4
        self.data = data

    def getpixel(self, xy):
        x, y = xy
        row = y if self.top_down else (self.h - 1 - y)
        pos = self.off + row * self.stride + x * (self.bpp // 8)
        b, g, r = self.data[pos], self.data[pos + 1], self.data[pos + 2]
        return (r, g, b)


def fetch_ortho_cell(ek, nk):
    x0, y0 = ek * CELL_M, nk * CELL_M
    x1, y1 = x0 + CELL_M, y0 + CELL_M
    url = (
        "https://service.pdok.nl/hwh/luchtfotorgb/wms/v1_0?"
        "SERVICE=WMS&VERSION=1.3.0&REQUEST=GetMap&LAYERS=Actueel_orthoHR"
        f"&CRS=EPSG:28992&BBOX={x0},{y0},{x1},{y1}&WIDTH=1000&HEIGHT=1000&FORMAT=image/jpeg"
    )
    jpg_path = os.path.join(ORTHO_CACHE, f"{ek}_{nk}.jpg")
    bmp_path = os.path.join(ORTHO_CACHE, f"{ek}_{nk}.bmp")
    raw = fetch_bytes(url, jpg_path, timeout=30)
    if not raw or not raw.startswith(b"\xff\xd8"):
        return None
    if not os.path.exists(bmp_path):
        subprocess.run(["sips", "-s", "format", "bmp", jpg_path, "--out", bmp_path],
                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)
    try:
        return BmpImage(bmp_path)
    except Exception:
        return None


def fetch_bag_subtile(x0, y0, size=SUB_M):
    x1, y1 = x0 + size, y0 + size
    cache_file = os.path.join(BAG_CACHE, f"{x0}_{y0}_{size}.json")
    if os.path.exists(cache_file) and os.path.getsize(cache_file) > 10:
        try:
            return json.load(open(cache_file))
        except Exception:
            pass
    os.makedirs(BAG_CACHE, exist_ok=True)
    pages = []
    url = f"https://api.3dbag.nl/collections/pand/items?bbox={x0},{y0},{x1},{y1}&limit=100"
    while url and len(pages) < 25:
        req = urllib.request.Request(url, headers={"User-Agent": UA})
        data = None
        for attempt in range(3):
            try:
                with urllib.request.urlopen(req, timeout=30) as r:
                    data = json.loads(r.read())
                break
            except Exception:
                if attempt == 2:
                    data = None
        if not data:
            break
        pages.append({
            "transform": data.get("metadata", {}).get("transform", {"scale": [1, 1, 1], "translate": [0, 0, 0]}),
            "features": data.get("features", []),
        })
        nxt = None
        for lk in data.get("links", []):
            if lk.get("rel") == "next":
                nxt = lk.get("href")
                break
        url = nxt
    tmp = cache_file + ".tmp"
    with open(tmp, "w") as f:
        json.dump(pages, f)
    os.replace(tmp, cache_file)
    return pages


def poly_normal(pts):
    nx = ny = nz = 0.0
    n = len(pts)
    for i in range(n):
        p0 = pts[i]
        p1 = pts[(i + 1) % n]
        nx += (p0[1] - p1[1]) * (p0[2] + p1[2])
        ny += (p0[2] - p1[2]) * (p0[0] + p1[0])
        nz += (p0[0] - p1[0]) * (p0[1] + p1[1])
    ln = math.sqrt(nx * nx + ny * ny + nz * nz)
    if ln < 1e-6:
        return None
    return (nx / ln, ny / ln, nz / ln)


def triangulate_ring(pts, norm):
    """Ear-clip a 3D planar polygon ring into triangles after removing duplicate/collinear vertices."""
    # Strip consecutive duplicate vertices so ear-clipping never stalls on zero-length edges
    clean = []
    for p in pts:
        if not clean or math.hypot(p[0] - clean[-1][0], p[1] - clean[-1][1], p[2] - clean[-1][2]) > 1e-3:
            clean.append(p)
    if len(clean) >= 2 and math.hypot(clean[0][0] - clean[-1][0], clean[0][1] - clean[-1][1], clean[0][2] - clean[-1][2]) <= 1e-3:
        clean.pop()
    pts = clean
    n = len(pts)
    if n < 3:
        return []
    if n == 3:
        return [(pts[0], pts[1], pts[2])]
    # Project onto 2D basis perpendicular to norm
    nx, ny, nz = norm
    if abs(nz) < 0.9:
        ux, uy, uz = -ny, nx, 0.0
    else:
        ux, uy, uz = 1.0, 0.0, 0.0
    ul = math.hypot(ux, uy, uz)
    ux, uy, uz = ux / ul, uy / ul, uz / ul
    vx = ny * uz - nz * uy
    vy = nz * ux - nx * uz
    vz = nx * uy - ny * ux
    p0 = pts[0]
    p2d = [((p[0] - p0[0]) * ux + (p[1] - p0[1]) * uy + (p[2] - p0[2]) * uz,
            (p[0] - p0[0]) * vx + (p[1] - p0[1]) * vy + (p[2] - p0[2]) * vz) for p in pts]
    # Ensure CCW winding in 2D
    area2 = sum(p2d[i][0] * p2d[(i + 1) % n][1] - p2d[(i + 1) % n][0] * p2d[i][1] for i in range(n))
    idxs = list(range(n)) if area2 >= 0.0 else list(reversed(range(n)))
    tris = []

    def cross2(a, b, c):
        return (b[0] - a[0]) * (c[1] - a[1]) - (b[1] - a[1]) * (c[0] - a[0])

    def in_tri(p, a, b, c):
        return cross2(a, b, p) >= -1e-6 and cross2(b, c, p) >= -1e-6 and cross2(c, a, p) >= -1e-6

    guard = n * n + 10
    while len(idxs) > 3 and guard > 0:
        guard -= 1
        clipped = False
        m = len(idxs)
        for i in range(m):
            ia, ib, ic = idxs[(i - 1) % m], idxs[i], idxs[(i + 1) % m]
            a, b, c = p2d[ia], p2d[ib], p2d[ic]
            cr = cross2(a, b, c)
            if abs(cr) <= 1e-6:
                # Drop collinear vertex cleanly instead of stalling
                idxs.pop(i)
                clipped = True
                break
            if cr < 0.0:
                continue
            if any(in_tri(p2d[j], a, b, c) for j in idxs if j not in (ia, ib, ic)):
                continue
            tris.append((pts[ia], pts[ib], pts[ic]))
            idxs.pop(i)
            clipped = True
            break
        if not clipped:
            break
    if len(idxs) == 3:
        tris.append((pts[idxs[0]], pts[idxs[1]], pts[idxs[2]]))
    return tris


def classify_roof_from_ortho(img, x0, y0, e, n, dak_type):
    if img is None:
        return ("terracotta", "#7a3b2c") if dak_type == "slanted" else ("bitumen", "#4a4e52")
    px = int(max(0, min(999, round(e - x0))))
    py = int(max(0, min(999, round((y0 + CELL_M) - n))))
    # Sample 5x5 patch average
    rs = gs = bs = 0
    cnt = 0
    for dx in (-2, 0, 2):
        for dy in (-2, 0, 2):
            sx, sy = max(0, min(999, px + dx)), max(0, min(999, py + dy))
            r, g, b = img.getpixel((sx, sy))
            rs += r; gs += g; bs += b; cnt += 1
    r, g, b = rs // cnt, gs // cnt, bs // cnt
    # True oxidised green copper dome/roof
    if g > r + 14 and g > b + 6 and (r + g + b) < 480:
        return ("copper", f"#{r:02x}{g:02x}{b:02x}")
    if dak_type == "horizontal":
        # Flat Dutch roofs: dark weathered gravel/bitumen, never bright sunlit white
        lum = max(58, min(105, (r + g + b) // 3))
        return ("bitumen", f"#{lum:02x}{lum:02x}{min(110, lum + 3):02x}")
    # Pitched Dutch roofs: corrugated Dutch clay *dakpannen* (`terracotta` PBR
    # tiles) in warm red-orange clay or dark anthracite charcoal (avoiding flat
    # banding slate on steep gables).
    if r > g + 8 and r > b + 12:
        tr = max(100, min(156, int(r * 0.86)))
        tg = max(50, min(84, int(g * 0.74)))
        tb = max(36, min(62, int(b * 0.68)))
        return ("terracotta", f"#{tr:02x}{tg:02x}{tb:02x}")
    # Dark glazed Dutch *zwarte dakpannen* clay tiles (corrugated terracotta PBR tinted charcoal)
    sl = max(54, min(78, (r + g + b) // 4))
    return ("terracotta", f"#{sl:02x}{sl:02x}{min(84, sl + 4):02x}")


def wall_palette_for_year(yr, h_hash):
    # Authentic Amsterdam brick & render palettes by BAG construction year
    if yr <= 0 or yr < 1860:
        # Historic Grachtengordel / Jordaan: dark charcoal, claret, warm red-brown Dutch brick
        cols = ["#3b2c27", "#4a2e28", "#5c342b", "#6e3e30", "#463630", "#2f2a29", "#7b4836"]
        return ("brick", cols[h_hash % len(cols)])
    if yr < 1910:
        cols = ["#7a3d2e", "#8a4834", "#6b382c", "#96543c", "#5e362c"]
        return ("brick", cols[h_hash % len(cols)])
    if yr < 1946:
        # Amsterdam School warm sculpted brick
        cols = ["#864432", "#753c2c", "#94503a", "#683528"]
        return ("brick", cols[h_hash % len(cols)])
    if yr < 1985:
        cols = ["#7a6c60", "#8e8478", "#6b5a4e", "#a29a8e"]
        return ("brick" if h_hash % 3 != 0 else "concrete", cols[h_hash % len(cols)])
    cols = ["#6a5a50", "#8a7a6a", "#b4aea4", "#5c4e46"]
    return ("brick" if h_hash % 2 == 0 else "render", cols[h_hash % len(cols)])


def pack_surface(tris, ce, cn, z0, is_roof):
    verts = []
    uvs = []
    idxs = []
    vmap = {}
    for tri, norm in tris:
        nx, ny, nz = norm
        hl = math.hypot(nx, ny)
        tx, ty = (-ny / hl, nx / hl) if hl > 1e-4 else (1.0, 0.0)
        # Slope-aligned up-roof tangent (bx, by, bz) = cross(norm, horizontal_tangent)
        if is_roof and hl > 0.12:
            # Horizontal eave vector (tx, ty, 0) and up-slope vector perpendicular to norm
            sx = -nz * ty
            sy = nz * tx
            sz = hl
        else:
            sx, sy, sz = 0.0, 1.0, 0.0
        for p in tri:
            lx = p[0] - ce
            ly = p[2] - z0
            lz = -(p[1] - cn)  # WorldScale +Z is South, RD +Y is North
            if is_roof:
                if hl > 0.12:
                    u = lx * tx + (p[1] - cn) * ty
                    v = lx * sx + (p[1] - cn) * sy + ly * sz
                else:
                    u = lx
                    v = lz
            else:
                u = lx * tx + (p[1] - cn) * ty
                v = ly
            vx = int(round(lx * 100.0))
            vy = int(round(ly * 100.0))
            vz = int(round(lz * 100.0))
            ui = int(round(u * 100.0))
            vi = int(round(v * 100.0))
            key = (vx, vy, vz, ui, vi)
            idx = vmap.get(key)
            if idx is None:
                idx = len(verts) // 3
                vmap[key] = idx
                verts.extend((vx, vy, vz))
                uvs.extend((ui, vi))
            idxs.append(idx)
    return verts, uvs, idxs


def compile_feature(feat, tr, ortho_cells):
    scale = tr.get("scale", [1.0, 1.0, 1.0])
    trans = tr.get("translate", [0.0, 0.0, 0.0])
    raw_v = feat.get("vertices", [])
    if not raw_v:
        return None
    vlist = [(v[0] * scale[0] + trans[0], v[1] * scale[1] + trans[1], v[2] * scale[2] + trans[2]) for v in raw_v]
    cos = feat.get("CityObjects", {})
    b_attrs = {}
    walls = []
    roofs = []
    zmin = 1e9
    zmax = -1e9
    plan_area = 0.0
    cx = cy = wsum = 0.0

    for co in cos.values():
        if co.get("type") == "Building":
            b_attrs = co.get("attributes", {})
        for g in co.get("geometry", []):
            if str(g.get("lod", "")) != "2.2":
                continue
            sem = g.get("semantics", {})
            surfaces = sem.get("surfaces", [])
            svals = sem.get("values", [])
            bounds = g.get("boundaries", [])
            # Solid -> list of shells -> list of faces -> list of rings
            shells = bounds if g.get("type") == "Solid" else [bounds]
            for si, shell in enumerate(shells):
                shell_vals = svals[si] if si < len(svals) else []
                for fi, face in enumerate(shell):
                    if not face or not face[0]:
                        continue
                    sidx = shell_vals[fi] if fi < len(shell_vals) else None
                    stype = surfaces[sidx].get("type", "") if (sidx is not None and sidx < len(surfaces)) else ""
                    if stype == "GroundSurface":
                        continue
                    ring = [vlist[vi] for vi in face[0] if 0 <= vi < len(vlist)]
                    if len(ring) < 3:
                        continue
                    norm = poly_normal(ring)
                    if norm is None:
                        continue
                    # Classify by both CityJSON semantics and true face slope:
                    # prevents steep vertical dormer cheeks from drooping roof tiles
                    # over walls, and prevents flat gable-top slivers from showing brick.
                    is_roof = (norm[2] >= 0.45) or (stype == "RoofSurface" and norm[2] >= 0.22) or (stype == "" and norm[2] >= 0.35)
                    for a, b, c in triangulate_ring(ring, norm):
                        # Flip winding for Godot (+X east, +Y up, +Z south)
                        for p in (a, b, c):
                            if p[2] < zmin:
                                zmin = p[2]
                            if p[2] > zmax:
                                zmax = p[2]
                        if is_roof:
                            roofs.append(((a, c, b), norm))
                            ux, uy = b[0] - a[0], b[1] - a[1]
                            vx, vy = c[0] - a[0], c[1] - a[1]
                            ap = abs(ux * vy - uy * vx) * 0.5
                            plan_area += ap
                            cx += ap * (a[0] + b[0] + c[0]) / 3.0
                            cy += ap * (a[1] + b[1] + c[1]) / 3.0
                            wsum += ap
                        else:
                            walls.append(((a, c, b), norm))

    if plan_area < 10.0 or not walls or not roofs or wsum <= 0.0:
        return None
    ce = cx / wsum
    cn = cy / wsum
    ek = int(math.floor(ce / CELL_M))
    nk = int(math.floor(cn / CELL_M))
    if ek not in X_CELLS or nk not in Y_CELLS:
        return None

    h = max(2.5, zmax - zmin)
    st = int(b_attrs.get("b3_bouwlagen") or max(1, round(h / 3.2)))
    yr = int(b_attrs.get("oorspronkelijkbouwjaar") or 0)
    dak_type = str(b_attrs.get("b3_dak_type") or "slanted")
    ortho = ortho_cells.get((ek, nk))
    rm, rc = classify_roof_from_ortho(ortho, ek * CELL_M, nk * CELL_M, ce, cn, dak_type)
    wm, wc = wall_palette_for_year(yr, abs(hash(feat.get("id", ""))))

    wv, wu, wi = pack_surface(walls, ce, cn, zmin, False)
    rv, ru, ri = pack_surface(roofs, ce, cn, zmin, True)
    if len(wi) < 3 or len(ri) < 3:
        return None
    return (f"{ek}_{nk}", feat.get("id", ""), {
        "e": ce, "n": cn, "area": plan_area, "h": h, "st": st, "yr": yr,
        "rm": rm, "rc": rc, "wm": wm, "wc": wc,
        "wv": wv, "wu": wu, "wi": wi, "rv": rv, "ru": ru, "ri": ri,
    })


def main():
    print("Fetching PDOK Actueel_orthoHR 1 km tiles for Amsterdam roof colours...")
    ortho_cells = {}
    with concurrent.futures.ThreadPoolExecutor(max_workers=6) as ex:
        futs = {(ek, nk): ex.submit(fetch_ortho_cell, ek, nk) for ek in X_CELLS for nk in Y_CELLS}
        for k, f in futs.items():
            ortho_cells[k] = f.result()
    print(f"Loaded {sum(1 for v in ortho_cells.values() if v is not None)}/{len(ortho_cells)} PDOK ortho cells")

    subtiles = []
    for ek in X_CELLS:
        for nk in Y_CELLS:
            for dx in range(0, CELL_M, SUB_M):
                for dy in range(0, CELL_M, SUB_M):
                    subtiles.append((ek * CELL_M + dx, nk * CELL_M + dy))

    print(f"Fetching 3DBAG LoD2.2 across {len(subtiles)} subtiles (3x3 km central Amsterdam)...")
    cells = {}
    seen_ids = set()
    with concurrent.futures.ThreadPoolExecutor(max_workers=8) as ex:
        for idx, pages in enumerate(ex.map(lambda xy: fetch_bag_subtile(xy[0], xy[1]), subtiles), 1):
            for page in pages:
                tr = page["transform"]
                for feat in page["features"]:
                    fid = feat.get("id", "")
                    if fid in seen_ids:
                        continue
                    seen_ids.add(fid)
                    res = compile_feature(feat, tr, ortho_cells)
                    if res is not None:
                        ck, _, rec = res
                        cells.setdefault(ck, []).append(rec)
            if idx % 24 == 0 or idx == len(subtiles):
                total = sum(len(v) for v in cells.values())
                print(f"  progress {idx}/{len(subtiles)} subtiles -> {total} LoD2.2 buildings")

    meta = {
        "city": "amsterdam",
        "crs": "EPSG:28992",
        "source": "3DBAG by TU Delft & 3DGI (LoD 2.2, CC BY 4.0) + PDOK Luchtfoto Actueel_orthoHR (CC BY 4.0)",
    }
    nb, nt, raw_b, comp_b = write_bundle(OUT_DIR, cells, meta)
    print(f"Wrote {len(cells)} cells to {OUT_DIR}: {nb} buildings, {nt} tris, "
          f"{raw_b / 1e6:.2f} MB raw -> {comp_b / 1e6:.2f} MB zstd")


if __name__ == "__main__":
    main()
