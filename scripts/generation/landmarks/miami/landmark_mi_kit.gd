class_name LandmarkMiKit
extends RefCounted

## Shared architectural parts for Miami landmarks (MI-1): Tropical Art Deco
## eyebrows, ziggurat parapets, vertical blade fins with neon tubes, nautical
## porthole rows, wrap-around white balcony slabs, courtyard royal palms,
## Spanish barrel-tile roof strips, and Giralda belfry tiers (shared by
## Freedom Tower and the Biltmore Hotel).

## Projecting Streamline Moderne horizontal eyebrow shelf along `a..b` at `y`.
static func deco_eyebrow(lm: LandmarkMesh, key: String, a: Vector2, b: Vector2, y: float,
		proj: float = 0.55, thick: float = 0.16, outward: Vector2 = Vector2.ZERO) -> void:
	var edge := b - a
	var length := edge.length()
	if length < 0.1:
		return
	var dir := edge / length
	var n2 := outward.normalized() if outward.length_squared() > 0.001 else Vector2(dir.y, -dir.x)
	var mid := (a + b) * 0.5 + n2 * (proj * 0.5)
	var basis := Basis(Vector3(dir.x, 0.0, dir.y), Vector3.UP, Vector3(n2.x, 0.0, n2.y))
	lm.box(key, Vector3(mid.x, y, mid.y), Vector3(length, thick, proj), basis, 0.02)

## Stepped Art Deco ziggurat parapet centred on `center_xz` facing `outward`.
static func ziggurat_parapet(lm: LandmarkMesh, wall_key: String, trim_key: String,
		center_xz: Vector2, along: Vector2, outward: Vector2, base_y: float,
		width: float, step_h: float, steps: int = 3, thick: float = 0.55) -> void:
	var dir := along.normalized()
	var n2 := outward.normalized()
	var basis := Basis(Vector3(dir.x, 0.0, dir.y), Vector3.UP, Vector3(n2.x, 0.0, n2.y))
	for i in steps:
		var frac := 1.0 - float(i) * 0.24
		var w := maxf(width * frac, 1.2)
		var y0 := base_y + float(i) * step_h
		lm.box(wall_key, Vector3(center_xz.x, y0 + step_h * 0.5, center_xz.y),
			Vector3(w, step_h, thick), basis, 0.02)
		lm.box(trim_key, Vector3(center_xz.x, y0 + step_h + 0.05, center_xz.y),
			Vector3(w + 0.18, 0.10, thick + 0.12), basis, 0.0)

## Vertical Deco blade fin projecting outward from a facade, with neon edge tube.
static func vertical_fin(lm: LandmarkMesh, fin_key: String, neon_key: String,
		base_xz: Vector2, outward: Vector2, y0: float, y1: float,
		proj: float = 1.1, thick: float = 0.28) -> void:
	var n2 := outward.normalized()
	var tang := Vector2(-n2.y, n2.x)
	var basis := Basis(Vector3(tang.x, 0.0, tang.y), Vector3.UP, Vector3(n2.x, 0.0, n2.y))
	var mid := base_xz + n2 * (proj * 0.5)
	var h := y1 - y0
	if h <= 0.1:
		return
	lm.box(fin_key, Vector3(mid.x, y0 + h * 0.5, mid.y), Vector3(thick, h, proj), basis, 0.02)
	if neon_key != "":
		var tip := base_xz + n2 * (proj + 0.05)
		lm.beam(neon_key, Vector3(tip.x, y0 + 0.15, tip.y), Vector3(tip.x, y1 - 0.1, tip.y), 0.09, 0.09)

## Nautical Art Deco porthole row along `a..b` at height `y`.
static func porthole_row(lm: LandmarkMesh, frame_key: String, glass_key: String,
		a: Vector2, b: Vector2, y: float, count: int, radius: float, outward: Vector2) -> void:
	if count <= 0:
		return
	var n2 := outward.normalized()
	var n3 := Vector3(n2.x, 0.0, n2.y)
	var side := Vector3(-n2.y, 0.0, n2.x)
	for i in count:
		var t := (float(i) + 0.5) / float(count)
		var p2 := a.lerp(b, t)
		var c := Vector3(p2.x, y, p2.y) + n3 * 0.06
		lm.disc(glass_key, c + n3 * 0.02, n3, radius * 0.82, 12)
		var segs := 12
		for s in segs:
			var a0 := TAU * float(s) / float(segs)
			var a1 := TAU * float(s + 1) / float(segs)
			var q0 := c + side * (cos(a0) * radius) + Vector3.UP * (sin(a0) * radius)
			var q1 := c + side * (cos(a1) * radius) + Vector3.UP * (sin(a1) * radius)
			lm.beam(frame_key, q0, q1, 0.10, 0.12, n3)

## Continuous wrap-around white balcony slabs and glass railings around `poly`.
static func balcony_slab_stack(lm: LandmarkMesh, slab_key: String, rail_key: String,
		poly: PackedVector2Array, y0: float, floors: int, floor_h: float,
		overhang: float = 1.4, slab_h: float = 0.24, rail_h: float = 1.0) -> void:
	if poly.size() < 3 or floors <= 0:
		return
	var outer := _offset_poly(poly, overhang)
	var w := SkyKit.winding(outer)
	for f in floors:
		var y := y0 + float(f + 1) * floor_h
		lm.poly_prism(slab_key, outer, y - slab_h, y)
		if rail_key != "":
			for i in outer.size():
				var p := outer[i]
				var q := outer[(i + 1) % outer.size()]
				var n3 := SkyKit._edge_normal(p, q, w)
				var ry0 := y
				var ry1 := y + rail_h
				lm.quad(rail_key, Vector3(p.x, ry0, p.y), Vector3(q.x, ry0, q.y),
					Vector3(q.x, ry1, q.y), Vector3(p.x, ry1, p.y), n3)

static func _offset_poly(poly: PackedVector2Array, dist: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	var n := poly.size()
	var sign_w := 1.0 if SkyKit.winding(poly) > 0.0 else -1.0
	for i in n:
		var prev := poly[(i + n - 1) % n]
		var curr := poly[i]
		var next := poly[(i + 1) % n]
		var e0 := (curr - prev).normalized()
		var e1 := (next - curr).normalized()
		var n0 := Vector2(e0.y, -e0.x) * sign_w
		var n1 := Vector2(e1.y, -e1.x) * sign_w
		var bis := (n0 + n1)
		if bis.length_squared() < 0.001:
			bis = n0
		else:
			bis = bis.normalized() / maxf(bis.normalized().dot(n0), 0.45)
		out.append(curr + bis * dist)
	return out

## Glowing neon tube chain through `pts`.
static func neon_tube_line(lm: LandmarkMesh, lit_key: String, pts: PackedVector3Array,
		thickness: float = 0.08) -> void:
	for i in pts.size() - 1:
		lm.beam(lit_key, pts[i], pts[i + 1], thickness, thickness)

## Courtyard / baywalk Royal Palm (Roystonea regia): grey column trunk, green
## crownshaft, and arching frond crown.
static func royal_palm(lm: LandmarkMesh, trunk_key: String, frond_key: String,
		base: Vector3, height: float = 16.0, seed_angle: float = 0.0) -> void:
	var shaft_y := height * 0.76
	var crown_y := height * 0.90
	lm.frustum(trunk_key, base, 0.28, 0.21, shaft_y, 8)
	lm.frustum(frond_key, base + Vector3(0, shaft_y, 0), 0.22, 0.19, crown_y - shaft_y, 8)
	var top := base + Vector3(0, crown_y, 0)
	var fronds := 12
	var flen := height * 0.24
	for i in fronds:
		var a := seed_angle + TAU * float(i) / float(fronds)
		var lift := 0.35 if (i % 2 == 0) else 0.05
		var dir := Vector3(cos(a), 0.0, sin(a))
		var mid := top + dir * (flen * 0.52) + Vector3(0, flen * (0.28 + lift * 0.35), 0)
		var tip := top + dir * flen + Vector3(0, -flen * (0.22 - lift * 0.25), 0)
		var side := dir.cross(Vector3.UP)
		lm.beam(frond_key, top, mid, 0.36, 0.06, side)
		lm.beam(frond_key, mid, tip, 0.26, 0.04, side)

## Spanish / Mediterranean Revival clay barrel-tile sloping roof strip along `a..b`.
static func barrel_tile_strip(lm: LandmarkMesh, tile_key: String, a: Vector2, b: Vector2,
		eaves_y: float, ridge_y: float, depth: float, outward: Vector2) -> void:
	var n2 := outward.normalized()
	var back_a := a - n2 * depth
	var back_b := b - n2 * depth
	var front_a := a + n2 * 0.25
	var front_b := b + n2 * 0.25
	var p0 := Vector3(front_a.x, eaves_y, front_a.y)
	var p1 := Vector3(front_b.x, eaves_y, front_b.y)
	var p2 := Vector3(back_b.x, ridge_y, back_b.y)
	var p3 := Vector3(back_a.x, ridge_y, back_a.y)
	lm.quad(tile_key, p0, p1, p2, p3)
	var barrels := clampi(int(a.distance_to(b) / 0.65), 4, 48)
	for i in barrels:
		var t := (float(i) + 0.5) / float(barrels)
		var e_pt := front_a.lerp(front_b, t)
		var r_pt := back_a.lerp(back_b, t)
		lm.beam(tile_key, Vector3(e_pt.x, eaves_y + 0.05, e_pt.y),
			Vector3(r_pt.x, ridge_y + 0.05, r_pt.y), 0.16, 0.12)

## Shared Spanish Renaissance Giralda belfry tier (square or octagonal) for
## Freedom Tower (MI-2A.1) and Biltmore Hotel (MI-10).
static func giralda_tier(lm: LandmarkMesh, wall_key: String, stone_key: String,
		dark_key: String, center_xz: Vector2, y0: float, h: float, width: float,
		octagonal: bool = false, arches_per_side: int = 1, corner_urns: bool = true) -> void:
	var cx := center_xz.x
	var cz := center_xz.y
	if octagonal:
		var pts := TowerSpec.plan("chamfer", width, width, width * 0.29, cx, cz)
		lm.poly_prism(wall_key, pts, y0, y0 + h)
		var trim_pts := TowerSpec.plan("chamfer", width + 0.5, width + 0.5, (width + 0.5) * 0.29, cx, cz)
		lm.poly_prism(stone_key, trim_pts, y0 + h - 0.45, y0 + h + 0.15)
		for i in pts.size():
			var p := pts[i]
			var q := pts[(i + 1) % pts.size()]
			var edge_l := p.distance_to(q)
			if edge_l < 1.6:
				continue
			var mid := (p + q) * 0.5
			var n2 := Vector2(q.y - p.y, -(q.x - p.x)).normalized()
			if n2.dot(mid - center_xz) < 0.0:
				n2 = -n2
			var tang := (q - p).normalized()
			var basis := Basis(Vector3(tang.x, 0.0, tang.y), Vector3.UP, Vector3(n2.x, 0.0, n2.y))
			lm.box(dark_key, Vector3(mid.x + n2.x * 0.04, y0 + h * 0.48, mid.y + n2.y * 0.04),
				Vector3(edge_l * 0.48, h * 0.58, 0.16), basis, 0.0)
	else:
		lm.box(wall_key, Vector3(cx, y0 + h * 0.5, cz), Vector3(width, h, width), Basis(), 0.04)
		lm.box(stone_key, Vector3(cx, y0 + 0.25, cz), Vector3(width + 0.45, 0.5, width + 0.45), Basis(), 0.02)
		lm.box(stone_key, Vector3(cx, y0 + h - 0.22, cz), Vector3(width + 0.65, 0.55, width + 0.65), Basis(), 0.02)
		var hw := width * 0.5
		for side in 4:
			var ang := float(side) * PI * 0.5
			var n3 := Vector3(sin(ang), 0.0, cos(ang))
			var t3 := Vector3(cos(ang), 0.0, -sin(ang))
			var basis := Basis(t3, Vector3.UP, n3)
			var span := width * 0.72
			var bay_w := span / float(maxi(arches_per_side, 1))
			for k in maxi(arches_per_side, 1):
				var off := -span * 0.5 + bay_w * (float(k) + 0.5)
				var pos := Vector3(cx, y0 + h * 0.48, cz) + n3 * (hw + 0.03) + t3 * off
				lm.box(dark_key, pos, Vector3(bay_w * 0.58, h * 0.56, 0.18), basis, 0.0)
				lm.box(stone_key, pos + Vector3(0, h * 0.30, 0), Vector3(bay_w * 0.70, 0.24, 0.28), basis, 0.0)
			# Corner pilasters
			for sg: float in [-1.0, 1.0]:
				var ppos := Vector3(cx, y0 + h * 0.5, cz) + n3 * (hw + 0.08) + t3 * (sg * (width * 0.44))
				lm.box(stone_key, ppos, Vector3(width * 0.09, h * 0.92, 0.22), basis, 0.0)
		if corner_urns:
			for sx: float in [-1.0, 1.0]:
				for sz: float in [-1.0, 1.0]:
					var upos := Vector3(cx + sx * (hw - 0.25), y0 + h + 0.32, cz + sz * (hw - 0.25))
					lm.frustum(stone_key, upos - Vector3(0, 0.25, 0), 0.28, 0.36, 0.45, 8)
					lm.frustum(stone_key, upos + Vector3(0, 0.20, 0), 0.34, 0.06, 0.65, 8)
