class_name LandmarkSgKit
extends RefCounted

## Shared architectural primitives for the Singapore landmark batch:
## - adaptive folded triangular aluminium sunshades (Esplanade durian skin)
## - curved lofted shells & external gridshell steel arch ribs (Gardens domes, MBS)
## - upward-curving lotus petals (ArtScience Museum)
## - tropical palms & sky-garden planter clusters (SkyPark, Raffles, Supertrees)
## - warm colonial colonnades, louvered rainbow shutters, and glowing night LED ribbons.

## Adds a curved lofted dome/shell (`rx`, `rz`, `height`) over `center` with
## `rings` latitude rows and `segs` longitude steps.
static func loft_shell(lm: LandmarkMesh, key: String, center: Vector3, rx: float, rz: float,
		height: float, rings: int = 12, segs: int = 24, power: float = 0.72) -> void:
	var grid: Array = []
	for r in rings + 1:
		var v := float(r) / float(rings)
		var y := center.y + height * pow(sin(v * PI * 0.5), power)
		var rad := cos(v * PI * 0.5)
		var row: Array = []
		for s in segs + 1:
			# Negative angle winds quads counter-clockwise from outside so normals face outward.
			var a := -TAU * float(s) / float(segs)
			row.append(Vector3(center.x + cos(a) * rx * rad, y, center.z + sin(a) * rz * rad))
		grid.append(row)
	lm.grid(key, grid)

## Adds Esplanade-style folded triangular aluminium sunshades over an ellipsoid shell.
## Opening/beak height increases on the steeper east/west flanks and flattens near the crown.
static func durian_shades(lm: LandmarkMesh, key: String, center: Vector3, rx: float, rz: float,
		height: float, rings: int = 18, segs: int = 44, power: float = 0.72, beak_m: float = 1.65) -> void:
	for r in range(1, rings):
		var v0 := float(r) / float(rings)
		var v1 := float(r + 1) / float(rings)
		var vm := 0.5 * (v0 + v1)
		var y0 := center.y + height * pow(sin(v0 * PI * 0.5), power)
		var y1 := center.y + height * pow(sin(v1 * PI * 0.5), power)
		var ym := 0.5 * (y0 + y1)
		var rad0 := cos(v0 * PI * 0.5)
		var rad1 := cos(v1 * PI * 0.5)
		var radm := cos(vm * PI * 0.5)
		var n_seg := maxi(12, int(roundf(float(segs) * maxf(radm, 0.18))))
		var shift := 0.5 if (r % 2) == 1 else 0.0
		for s in n_seg:
			var a0 := TAU * (float(s) + shift) / float(n_seg)
			var a1 := TAU * (float(s + 1) + shift) / float(n_seg)
			var am := 0.5 * (a0 + a1)
			var p0 := Vector3(center.x + cos(a0) * rx * rad0, y0, center.z + sin(a0) * rz * rad0)
			var p1 := Vector3(center.x + cos(a1) * rx * rad0, y0, center.z + sin(a1) * rz * rad0)
			var p2 := Vector3(center.x + cos(am) * rx * rad1, y1, center.z + sin(am) * rz * rad1)
			var nrm := Vector3(cos(am) / maxf(rx, 1.0), (1.0 - radm) * 0.85 / maxf(height, 1.0), sin(am) / maxf(rz, 1.0)).normalized()
			# Steeper flanks have deeper protruding sunshade beaks; apex flattens.
			var flank := clampf(1.0 - vm * 0.75, 0.22, 1.0)
			var spike := (p0 + p1 + p2) / 3.0 + nrm * (beak_m * flank) + Vector3(0.0, -0.35 * flank, 0.0)
			outward_tri(lm, key, p0, p1, spike, nrm)
			outward_tri(lm, key, p1, p2, spike, nrm)
			outward_tri(lm, key, p2, p0, spike, nrm)

## Adds a series of external structural steel arch ribs standing slightly proud of a glass shell.
static func shell_arch_ribs(lm: LandmarkMesh, key: String, center: Vector3, rx: float, rz: float,
		height: float, rib_count: int, stand_off: float = 0.75, tube_w: float = 0.55,
		steps: int = 16, power: float = 0.72) -> void:
	for i in rib_count:
		var a := PI * float(i) / float(rib_count)
		var ca := cos(a)
		var sa := sin(a)
		var prev := Vector3.ZERO
		for s in steps + 1:
			var u := -1.0 + 2.0 * float(s) / float(steps)
			var ang := u * PI * 0.5
			var y := center.y + (height + stand_off) * pow(cos(ang), power)
			var rad := sin(ang)
			var p := Vector3(center.x + ca * (rx + stand_off) * rad, y, center.z + sa * (rz + stand_off) * rad)
			if s > 0:
				lm.beam(key, prev, p, tube_w, tube_w)
			prev = p

## Adds a lush tropical palm (curved ringed trunk + arching frond blades).
static func palm(lm: LandmarkMesh, trunk_key: String, leaf_key: String, base: Vector3,
		h: float = 8.0, lean: Vector2 = Vector2(0.4, 0.2), fronds: int = 8) -> void:
	var p0 := base
	var p1 := base + Vector3(lean.x * 0.35, h * 0.5, lean.y * 0.35)
	var p2 := base + Vector3(lean.x, h, lean.y)
	lm.beam(trunk_key, p0, p1, 0.34, 0.34)
	lm.beam(trunk_key, p1, p2, 0.26, 0.26)
	var flen := clampf(h * 0.36, 2.0, 4.0)
	for k in fronds:
		var a := TAU * float(k) / float(fronds) + lean.x
		var dir := Vector3(cos(a), 0.0, sin(a))
		var mid := p2 + dir * (flen * 0.55) + Vector3(0.0, flen * 0.22, 0.0)
		var tip := p2 + dir * flen + Vector3(0.0, -flen * 0.28, 0.0)
		lm.beam(leaf_key, p2, mid, 0.55, 0.08)
		lm.beam(leaf_key, mid, tip, 0.42, 0.07)

## Adds a cluster of tropical garden foliage domes + palms (SkyPark, sky-gardens, plazas).
static func sky_garden_patch(lm: LandmarkMesh, trunk_key: String, leaf_key: String,
		center: Vector3, rx: float, rz: float, seed_val: int = 0) -> void:
	for i in 5:
		var a := TAU * float(i) / 5.0 + float(seed_val) * 0.7
		var r := 0.45 + 0.35 * absf(sin(float(i + seed_val) * 1.9))
		var p := Vector3(center.x + cos(a) * rx * r, center.y, center.z + sin(a) * rz * r)
		var dome_r := 1.6 + 1.0 * absf(cos(float(i) * 2.1 + float(seed_val)))
		var dome_h := 1.8 + 1.4 * absf(sin(float(i) * 1.3 + float(seed_val)))
		LandmarkAsiaSouthUtil.dome(lm, leaf_key, p, dome_r, dome_h, 8, 4)
	palm(lm, trunk_key, leaf_key, center + Vector3(rx * 0.2, 0.0, -rz * 0.15), 6.2, Vector2(0.3, 0.2), 7)

## Adds a classical colonnade along the segment a..b at base elevation y0.
static func colonnade(lm: LandmarkMesh, key: String, a: Vector3, b: Vector3,
		col_h: float, col_r: float, count: int) -> void:
	if count < 2:
		return
	for i in count:
		var t := float(i) / float(count - 1)
		var p := a.lerp(b, t)
		lm.frustum(key, p, col_r * 1.06, col_r * 0.90, col_h, 8)
		lm.box(key, p + Vector3(0.0, 0.35, 0.0), Vector3(col_r * 2.5, 0.7, col_r * 2.5))
		lm.box(key, p + Vector3(0.0, col_h - 0.35, 0.0), Vector3(col_r * 2.6, 0.7, col_r * 2.6))

## Adds a glowing LED ribbon strip along a polyline of Vector3 points (`*Lamp` surface).
static func led_ribbon(lm: LandmarkMesh, lamp_key: String, pts: Array, width: float = 0.28) -> void:
	for i in pts.size() - 1:
		lm.beam(lamp_key, pts[i] as Vector3, pts[i + 1] as Vector3, width, width)

## Adds a single flat-shaded triangle with auto-computed outward normal and UVs.
static func flat_tri(lm: LandmarkMesh, key: String, a: Vector3, b: Vector3, c: Vector3) -> void:
	var n := (b - a).cross(c - a)
	if n.length_squared() < 1e-8:
		return
	n = n.normalized()
	lm.tri(key, a, b, c, n, n, n, Vector2(0.0, 0.0), Vector2(1.0, 0.0), Vector2(0.5, 1.0))

## Adds a flat-shaded triangle whose winding is guaranteed to face `outward`.
static func outward_tri(lm: LandmarkMesh, key: String, a: Vector3, b: Vector3, c: Vector3, outward: Vector3) -> void:
	var n := (b - a).cross(c - a)
	if n.length_squared() < 1e-8:
		return
	if n.dot(outward) < 0.0:
		var tmp := b
		b = c
		c = tmp
		n = -n
	n = n.normalized()
	lm.tri(key, a, b, c, n, n, n, Vector2(0.0, 0.0), Vector2(1.0, 0.0), Vector2(0.5, 1.0))

## Adds a pitched hipped roof over a rectangular footprint `(sx, sz)` whose eaves sit at `base_center.y`
## and whose ridge rises by `ridge_h`. Includes a thin fascia band so eaves look crisp from below.
static func hipped_roof(lm: LandmarkMesh, key: String, base_center: Vector3,
		sx: float, sz: float, ridge_h: float, hip_inset: float = -1.0) -> void:
	var hx := sx * 0.5
	var hz := sz * 0.5
	var y0 := base_center.y
	var y1 := y0 + ridge_h
	var cx := base_center.x
	var cz := base_center.z
	# Thin eave fascia so underside is sealed.
	lm.box(key, Vector3(cx, y0 - 0.18, cz), Vector3(sx, 0.36, sz))
	var inset := hip_inset if hip_inset >= 0.0 else minf(hx, hz) * 0.65
	var rx := maxf(0.0, hx - inset) if sx >= sz else 0.0
	var rz := maxf(0.0, hz - inset) if sz > sx else 0.0
	var c0 := Vector3(cx - hx, y0, cz - hz)
	var c1 := Vector3(cx + hx, y0, cz - hz)
	var c2 := Vector3(cx + hx, y0, cz + hz)
	var c3 := Vector3(cx - hx, y0, cz + hz)
	var r0 := Vector3(cx - rx, y1, cz - rz)
	var r1 := Vector3(cx + rx, y1, cz + rz)
	if sx >= sz:
		# Ridge runs along X: r0 = west ridge end, r1 = east ridge end.
		outward_tri(lm, key, c0, c1, r1, Vector3(0.0, 1.0, -1.0))
		outward_tri(lm, key, c0, r1, r0, Vector3(0.0, 1.0, -1.0))
		outward_tri(lm, key, c2, c3, r0, Vector3(0.0, 1.0, 1.0))
		outward_tri(lm, key, c2, r0, r1, Vector3(0.0, 1.0, 1.0))
		outward_tri(lm, key, c1, c2, r1, Vector3(1.0, 1.0, 0.0))
		outward_tri(lm, key, c3, c0, r0, Vector3(-1.0, 1.0, 0.0))
	else:
		# Ridge runs along Z: r0 = north ridge end, r1 = south ridge end.
		outward_tri(lm, key, c1, c2, r1, Vector3(1.0, 1.0, 0.0))
		outward_tri(lm, key, c1, r1, r0, Vector3(1.0, 1.0, 0.0))
		outward_tri(lm, key, c3, c0, r0, Vector3(-1.0, 1.0, 0.0))
		outward_tri(lm, key, c3, r0, r1, Vector3(-1.0, 1.0, 0.0))
		outward_tri(lm, key, c0, c1, r0, Vector3(0.0, 1.0, -1.0))
		outward_tri(lm, key, c2, c3, r1, Vector3(0.0, 1.0, 1.0))

## Adds a solid 3D classical triangular pediment (front & back tympanums + sloped roof cheeks).
## When `face_z` is true, the triangle faces ±Z with `width` along X and `depth` along Z.
static func pediment_prism(lm: LandmarkMesh, tymp_key: String, roof_key: String,
		base_center: Vector3, width: float, height: float, depth: float, face_z: bool = true) -> void:
	var hw := width * 0.5
	var hd := depth * 0.5
	var y0 := base_center.y
	var y1 := y0 + height
	var cx := base_center.x
	var cz := base_center.z
	if face_z:
		var fl := Vector3(cx - hw, y0, cz + hd)
		var fr := Vector3(cx + hw, y0, cz + hd)
		var ft := Vector3(cx, y1, cz + hd)
		var bl := Vector3(cx - hw, y0, cz - hd)
		var br := Vector3(cx + hw, y0, cz - hd)
		var bt := Vector3(cx, y1, cz - hd)
		outward_tri(lm, tymp_key, fl, fr, ft, Vector3(0.0, 0.0, 1.0))
		outward_tri(lm, tymp_key, br, bl, bt, Vector3(0.0, 0.0, -1.0))
		outward_tri(lm, roof_key, fl, ft, bt, Vector3(-1.0, 1.0, 0.0))
		outward_tri(lm, roof_key, fl, bt, bl, Vector3(-1.0, 1.0, 0.0))
		outward_tri(lm, roof_key, fr, br, bt, Vector3(1.0, 1.0, 0.0))
		outward_tri(lm, roof_key, fr, bt, ft, Vector3(1.0, 1.0, 0.0))
	else:
		var fl := Vector3(cx + hd, y0, cz - hw)
		var fr := Vector3(cx + hd, y0, cz + hw)
		var ft := Vector3(cx + hd, y1, cz)
		var bl := Vector3(cx - hd, y0, cz - hw)
		var br := Vector3(cx - hd, y0, cz + hw)
		var bt := Vector3(cx - hd, y1, cz)
		outward_tri(lm, tymp_key, fl, fr, ft, Vector3(1.0, 0.0, 0.0))
		outward_tri(lm, tymp_key, br, bl, bt, Vector3(-1.0, 0.0, 0.0))
		outward_tri(lm, roof_key, fl, ft, bt, Vector3(0.0, 1.0, -1.0))
		outward_tri(lm, roof_key, fl, bt, bl, Vector3(0.0, 1.0, -1.0))
		outward_tri(lm, roof_key, fr, br, bt, Vector3(0.0, 1.0, 1.0))
		outward_tri(lm, roof_key, fr, bt, ft, Vector3(0.0, 1.0, 1.0))
