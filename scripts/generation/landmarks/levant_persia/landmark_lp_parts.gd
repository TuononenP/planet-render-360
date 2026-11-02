class_name LandmarkLpParts
extends RefCounted

## Shared shapes of the Levant / Persia / Central Asia landmark batch, in
## true metres on LandmarkMesh: pointed-arch slabs (iwan portals), classical
## columns, domes (hemispherical, bulbous, ribbed), crenellated walls. Every
## shape takes the material KEYS the caller registered with lm.use.

## Across (+u) and outward (+f) axes of a wall facing `yaw` (0 faces +Z).
static func across(yaw: float) -> Vector3:
	return Vector3(cos(yaw), 0.0, -sin(yaw))

static func outward(yaw: float) -> Vector3:
	return Vector3(sin(yaw), 0.0, cos(yaw))

## Two-centred pointed arch from the left spring (-a, 0) over the apex
## (0, rise) to the right spring (a, 0); rise == a gives a round arch.
static func arch_outline(a: float, rise: float, steps: int = 8) -> PackedVector2Array:
	var k := maxf((rise * rise - a * a) / (2.0 * a), 0.0)
	var big := a + k
	var t_apex := acos(clampf(-k / big, -1.0, 1.0))
	var left := PackedVector2Array()
	for i in steps + 1:
		var t := PI + (t_apex - PI) * float(i) / float(steps)
		left.append(Vector2(k + big * cos(t), big * sin(t)))
	var pts: PackedVector2Array = left.duplicate()
	for i in range(steps - 1, -1, -1):
		pts.append(Vector2(-left[i].x, left[i].y))
	return pts

## Wall face W x H pierced from the bottom by arched openings given as
## [centre u, half-width, spring height, rise], sorted left to right.
static func arcade_outline(w: float, h: float, arches: Array, steps: int = 8) -> PackedVector2Array:
	var pts := PackedVector2Array([Vector2(-w * 0.5, 0.0)])
	for ar in arches:
		var cx: float = ar[0]
		var a: float = ar[1]
		var spring: float = ar[2]
		pts.append(Vector2(cx - a, 0.0))
		for p in arch_outline(a, float(ar[3]), steps):
			pts.append(Vector2(cx + p.x, spring + p.y))
		pts.append(Vector2(cx + a, 0.0))
	pts.append(Vector2(w * 0.5, 0.0))
	pts.append(Vector2(w * 0.5, h))
	pts.append(Vector2(-w * 0.5, h))
	return pts

## Wall face W x H with one arched doorway/niche notched in from the
## bottom (half-width a, springing at `spring`, rising `rise`).
static func portal_outline(w: float, h: float, a: float, spring: float, rise: float,
		steps: int = 8) -> PackedVector2Array:
	return arcade_outline(w, h, [[0.0, a, spring, rise]], steps)

## Vertical slab: a 2D outline (u across, v up) extruded `depth` back from
## `front` along the wall frame of `yaw`, side walls and both faces closed.
static func slab(lm: LandmarkMesh, key: String, outline: PackedVector2Array, front: Vector3,
		yaw: float, depth: float) -> void:
	var r := across(yaw)
	var f := outward(yaw)
	var twice_area := 0.0
	for i in outline.size():
		var p := outline[i]
		var q := outline[(i + 1) % outline.size()]
		twice_area += p.x * q.y - q.x * p.y
	var sgn := 1.0 if twice_area > 0.0 else -1.0
	for i in outline.size():
		var p := outline[i]
		var q := outline[(i + 1) % outline.size()]
		var e := q - p
		if e.length() < 0.0001:
			continue
		var n2 := Vector2(e.y, -e.x).normalized() * sgn
		var pf := front + r * p.x + Vector3.UP * p.y
		var qf := front + r * q.x + Vector3.UP * q.y
		lm.quad(key, pf, qf, qf - f * depth, pf - f * depth, r * n2.x + Vector3.UP * n2.y)
	var idx := Geometry2D.triangulate_polygon(outline)
	for t in range(0, idx.size(), 3):
		var a := outline[idx[t]]
		var b := outline[idx[t + 1]]
		var c := outline[idx[t + 2]]
		var pa := front + r * a.x + Vector3.UP * a.y
		var pb := front + r * b.x + Vector3.UP * b.y
		var pc := front + r * c.x + Vector3.UP * c.y
		lm.tri(key, pa, pb, pc, f, f, f, a, b, c)
		lm.tri(key, pa - f * depth, pb - f * depth, pc - f * depth, -f, -f, -f, a, b, c)

## Iwan portal (pishtaq): a W x H face with a pointed-arched niche, `depth`
## thick, closed at the back by a dark plate (the vault shadow).
static func iwan(lm: LandmarkMesh, face: String, dark: String, front: Vector3, yaw: float,
		w: float, h: float, a: float, spring: float, rise: float, depth: float) -> void:
	slab(lm, face, portal_outline(w, h, a, spring, rise), front, yaw, depth)
	var fill := PackedVector2Array([Vector2(-a, 0.0)])
	for p in arch_outline(a, rise):
		fill.append(p + Vector2(0.0, spring))
	fill.append(Vector2(a, 0.0))
	slab(lm, dark, fill, front - outward(yaw) * (depth - 0.3), yaw, 0.3)

## Blind arched window/door of half-width a: a thin dark slab on a wall face.
static func arch_panel(lm: LandmarkMesh, key: String, front: Vector3, yaw: float, a: float,
		spring: float, rise: float) -> void:
	var fill := PackedVector2Array([Vector2(-a, 0.0)])
	for p in arch_outline(a, rise, 5):
		fill.append(p + Vector2(0.0, spring))
	fill.append(Vector2(a, 0.0))
	slab(lm, key, fill, front, yaw, 0.25)

## Classical column of height h on `base`: plinth, tapering shaft with
## entasis, flaring capital (Corinthian bell) and an abacus block.
static func column(lm: LandmarkMesh, key: String, base: Vector3, r: float, h: float,
		cap: float, seg: int = 12) -> void:
	var b := r * 0.8
	var top := h - cap
	var prof := PackedVector2Array([Vector2(r * 1.3, 0.0), Vector2(r * 1.3, b * 0.45),
		Vector2(r * 1.12, b), Vector2(r * 1.03, b + (top - b) * 0.4), Vector2(r * 0.9, top),
		Vector2(r * 1.0, top + cap * 0.2), Vector2(r * 1.3, top + cap * 0.6),
		Vector2(r * 1.5, h - cap * 0.12)])
	lm.lathe(key, base, prof, seg)
	lm.box(key, base + Vector3(0, h - cap * 0.06, 0), Vector3(r * 3.2, cap * 0.12, r * 3.2))

## Straight run of equal columns from a to b (n columns, both ends
## included), each of height h, with a continuous entablature beam on top.
static func colonnade(lm: LandmarkMesh, key: String, a: Vector3, b: Vector3, n: int, r: float,
		h: float, cap: float, ent_h: float, ent_d: float, skip: Array = [], seg: int = 12) -> void:
	for i in n:
		if i in skip:
			continue
		column(lm, key, a.lerp(b, float(i) / float(n - 1)), r, h, cap, seg)
	lm.beam(key, a + Vector3(0, h + ent_h * 0.5, 0), b + Vector3(0, h + ent_h * 0.5, 0), ent_h,
		ent_d, Vector3.UP)

## Hemispherical dome profile (radius, y) ending on the axis; tip > 0
## pulls the crown into a point.
static func dome_profile(r: float, h: float, steps: int = 8, tip: float = 0.0) -> PackedVector2Array:
	var p := PackedVector2Array()
	for i in steps + 1:
		var a := PI * 0.5 * float(i) / float(steps)
		p.append(Vector2(r * pow(cos(a), 1.0 + tip), h * sin(a)))
	return p

## Bulbous (Persian / Timurid) dome profile: the radius swells to `swell`
## x r a fifth of the way up, then closes in an ogee point.
static func bulb_profile(r: float, h: float, swell: float = 1.12, steps: int = 12,
		point: float = 1.3) -> PackedVector2Array:
	var p := PackedVector2Array()
	for i in steps + 1:
		var t := float(i) / float(steps)
		var rad := 0.0
		if t < 0.2:
			rad = r * (1.0 + (swell - 1.0) * sin(PI * 0.5 * t / 0.2))
		else:
			rad = r * swell * pow(cos(PI * 0.5 * (t - 0.2) / 0.8), point)
		p.append(Vector2(maxf(rad, 0.04), h * t))
	return p

## Dome with `ribs` raised meridian ribs (amplitude `amp` of the radius),
## following any (radius, y) profile.
static func ribbed_dome(lm: LandmarkMesh, key: String, base: Vector3, prof: PackedVector2Array,
		ribs: int, amp: float, per_rib: int = 4) -> void:
	var seg := ribs * per_rib
	var rows: Array = []
	for j in prof.size():
		var ring := PackedVector3Array()
		for i in seg + 1:
			var a := TAU * float(i) / float(seg)
			var bump := 1.0 + amp * (0.5 + 0.5 * cos(a * float(ribs)))
			ring.append(base + Vector3(cos(a) * prof[j].x * bump, prof[j].y, sin(a) * prof[j].x * bump))
		rows.append(ring)
	lm.grid(key, rows, base + Vector3(0, prof[prof.size() - 1].y * 0.35, 0), true)

## Needle / finial: radius tapers through (height, radius) pairs.
static func needle(lm: LandmarkMesh, key: String, base: Vector3, prof: PackedVector2Array,
		seg: int = 8) -> void:
	var p := PackedVector2Array()
	for v in prof:
		p.append(Vector2(v.y, v.x))
	lm.lathe(key, base, p, seg)

## Row of crenel merlons along a -> b (ground points; merlons stand on
## a.y), `w` wide, `h` high, `thick` deep, one every `pitch` metres.
static func merlons(lm: LandmarkMesh, key: String, a: Vector3, b: Vector3, w: float, h: float,
		thick: float, pitch: float) -> void:
	var d := b - a
	var n := maxi(int(d.length() / pitch), 1)
	var basis := Basis(Vector3.UP, atan2(-d.z, d.x))
	for i in n:
		var p := a.lerp(b, (float(i) + 0.5) / float(n))
		lm.box(key, p + Vector3(0, h * 0.5, 0), Vector3(w, h, thick), basis)

## Stack of `n` steps rising `rise` over `run` towards `dir` from `foot`,
## `w` wide (the topmost step is flush with y = foot.y + rise).
static func steps(lm: LandmarkMesh, key: String, foot: Vector3, dir: Vector3, w: float,
		run: float, rise: float, n: int) -> void:
	var basis := Basis(Vector3.UP, atan2(dir.x, dir.z))
	for i in n:
		var depth_i := run * (1.0 - float(i) / float(n))
		var hh := rise * float(i + 1) / float(n)
		lm.box(key, foot + dir * (run - depth_i + depth_i * 0.5) + Vector3(0, hh * 0.5, 0),
			Vector3(w, hh, depth_i), basis)
