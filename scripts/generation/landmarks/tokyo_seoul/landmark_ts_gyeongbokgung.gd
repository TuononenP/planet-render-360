class_name LandmarkTsGyeongbokgung
extends RefCounted

## Gyeongbokgung's ceremonial axis north of Gwanghwamun, in true metres on
## LandmarkMesh with the Joseon kit of LandmarkKoreanRoof, in the palace
## frame (registry yaw_deg 2: +X bears 92, front faces south, +Z). Plans
## from the OSM ways (sources in docs/tokyo-seoul-landmark-sources.md).

## Heungnyemun, the second gate (rebuilt 2001): the two-storey gate of
## 3 x 2 bays on its granite platform with front and back stairs. Lower
## eaves at about 7.5 m and the upper roof from 11.5 m, as the OSM roof
## parts give, ridge at 13.8 m and chimi to 15 m.
static func heungnyemun(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	LandmarkKoreanRoof.materials(lm)
	var low := Vector2(17.5, 9.5)
	lm.box("Granite", Vector3(0, 0.6, 0), Vector3(23.5, 1.2, 15.0))
	lm.box("Granite", Vector3(0, 1.5, 0), Vector3(low.x + 2.0, 0.6, low.y + 2.0))
	for s in [-1.0, 1.0]:
		stair(lm, Vector3(0, 0, s * 7.5), Vector3(0, 0, s), 6.0, 1.2)
	LandmarkKoreanRoof.two_storey(lm, 1.8, low, Vector2(15.0, 7.0), 3.8, 3.4, 15.0)
	lm.commit(model)

## Geunjeongjeon, the throne hall (1867), with its courtyard: the hall on
## the two-tier granite terrace (woldae) with balustrades and stairs, the
## raised royal path between the rank stones, and the roofed cloister
## (LandmarkTsCloister) with Geunjeongmun and the side gates. Built about
## the cloister's centre; the hall stands at (2.0, -23.3), where OSM way
## 170199428 puts it. Its parts (building:part 1569283607-20) rise 25.4 m
## above the terrace, which adds 2.4 m: 27.8 m in all.
static func geunjeongjeon(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	LandmarkKoreanRoof.materials(lm)
	var hall := LandmarkMesh.new()
	LandmarkKoreanRoof.materials(hall)
	_hall(hall)
	LandmarkKoreanRoof.place(lm, hall, Vector3(2.0, 0, -23.3))
	# Royal path from the terrace stairs to Geunjeongmun between the two
	# rows of rank stones (pumgyeseok).
	lm.box("Granite", Vector3(1.6, 0.06, 31.0), Vector3(7.0, 0.12, 57.0), Basis(), 0.0)
	lm.box("Granite", Vector3(1.6, 0.16, 31.0), Vector3(2.4, 0.2, 57.0), Basis(), 0.0)
	for k in 12:
		for s in [-1.0, 1.0]:
			lm.box("Granite", Vector3(1.6 + s * 6.0, 0.45, 6.0 + 4.4 * k), Vector3(0.45, 0.9, 0.35))
	LandmarkTsCloister.build(lm)
	lm.commit(model)

## The hall about its own centre (front +Z): woldae, stylobate, the lower
## storey of 5 x 5 bays under its skirt roof, the upper storey and the
## hipped-and-gabled roof.
static func _hall(lm: LandmarkMesh) -> void:
	# Woldae: lower tier 54 x 43 m, 1.3 m; upper 44 x 34 m, 1.1 m.
	_tier(lm, Vector3(0, 0, 1.8), Vector2(54.0, 43.0), 1.3)
	_tier(lm, Vector3(0, 1.3, 1.3), Vector2(44.0, 34.0), 1.1)
	var w := 2.4
	# Bronze cauldrons (deumeu) at the upper terrace's front corners.
	for s in [-1.0, 1.0]:
		lm.lathe("Shadow", Vector3(s * 19.5, w, 16.0), PackedVector2Array([Vector2(0.5, 0.0), Vector2(0.75, 0.5),
			Vector2(0.7, 1.0), Vector2(0.0, 1.0)]), 10)
	lm.box("Granite", Vector3(0, w + 0.25, 0), Vector3(36.0, 0.5, 27.0))
	lm.box("Granite", Vector3(0, w + 0.75, 0), Vector3(35.0, 0.5, 26.0))
	var bays := Vector2i(5, 5)
	var y1 := w + 1.0
	var low := Vector2(30.0, 21.0)
	var low_h := 4.6
	lm.box("Plaster", Vector3(0, y1 + (low_h - 0.2) * 0.5, 0), Vector3(low.x - 1.0, low_h - 0.2, low.y - 1.0))
	LandmarkKoreanRoof.columns(lm, y1, low, low_h, 0.38, bays)
	LandmarkKoreanRoof.lattice(lm, y1, low, low_h - 0.4, bays)
	LandmarkKoreanRoof.brackets(lm, y1 + low_h, low, 1, bays)
	var skirt_y := y1 + low_h + 0.9
	LandmarkKoreanRoof.rafters(lm, skirt_y, low + Vector2(1.6, 1.6), 2.6)
	LandmarkKoreanRoof.roof(lm, skirt_y, low + Vector2(9.0, 9.0), low + Vector2(-1.0, -1.0), 3.0, false)
	# Upper storey: its eaves at 14.24 m above the terrace (OSM part).
	var y2 := w + 8.6
	var up := Vector2(26.0, 17.0)
	var eave_y := w + 14.24
	var up_h := eave_y - 0.7 - y2
	lm.box("Timber", Vector3(0, y2 + 0.2, 0), Vector3(up.x + 0.6, 0.4, up.y + 0.6))
	lm.box("Plaster", Vector3(0, y2 + up_h * 0.5, 0), Vector3(up.x - 0.6, up_h, up.y - 0.6))
	LandmarkKoreanRoof.columns(lm, y2, up, up_h, 0.32, bays)
	LandmarkKoreanRoof.lattice(lm, y2 + 0.2, up, up_h - 0.4, bays)
	LandmarkKoreanRoof.brackets(lm, y2 + up_h, up, 1, bays)
	var top_m := w + 25.4
	var ridge_y := top_m - 1.4
	LandmarkKoreanRoof.rafters(lm, eave_y, up + Vector2(1.6, 1.6), 3.2)
	var eave := up + Vector2(11.0, 11.0)
	var top := Vector2(up.x * 0.62, 0.8)
	LandmarkKoreanRoof.roof(lm, eave_y, eave, top, ridge_y - eave_y, true)
	LandmarkKoreanRoof.hips(lm, eave_y, eave, top, ridge_y - eave_y)
	LandmarkKoreanRoof.ridge(lm, ridge_y, top.x, top_m)

## One woldae tier `size` (x, z) and `h` tall on `c`: the ashlar block, its
## coping, a stone balustrade of posts and rails round the edge (open at
## the stairs), and stairs on the front (three flights), back and sides.
static func _tier(lm: LandmarkMesh, c: Vector3, size: Vector2, h: float) -> void:
	lm.box("Granite", c + Vector3(0, h * 0.5, 0), Vector3(size.x, h, size.y))
	lm.box("Granite", c + Vector3(0, h - 0.1, 0), Vector3(size.x + 0.4, 0.2, size.y + 0.4))
	var hx := size.x * 0.5 - 0.3
	var hz := size.y * 0.5 - 0.3
	var top := c.y + h
	var corners := [Vector2(-hx, -hz), Vector2(hx, -hz), Vector2(hx, hz), Vector2(-hx, hz)]
	# Openings (along-edge centre, half width) per edge: back, east, front, west.
	var gaps := [[0.0, 2.5], [0.0, 2.5], [0.0, 7.0], [0.0, 2.5]]
	for e in 4:
		var a: Vector2 = corners[e]
		var b: Vector2 = corners[(e + 1) % 4]
		var gap: Array = gaps[e]
		var mid := (a + b) * 0.5
		var dir := (b - a).normalized()
		var g0 := mid - dir * float(gap[1])
		var g1 := mid + dir * float(gap[1])
		_rail(lm, Vector3(c.x + a.x, top, c.z + a.y), Vector3(c.x + g0.x, top, c.z + g0.y))
		_rail(lm, Vector3(c.x + g1.x, top, c.z + g1.y), Vector3(c.x + b.x, top, c.z + b.y))
		var out := Vector3(dir.y, 0, -dir.x)
		if out.dot(Vector3(mid.x, 0, mid.y)) < 0.0:
			out = -out
		var edge := Vector3(c.x + mid.x, c.y, c.z + mid.y) + out * 0.3
		if e == 2:
			for k in [-1.0, 0.0, 1.0]:
				stair(lm, edge + Vector3(k * 4.4, 0, 0), out, 3.6 if k != 0.0 else 3.0, h)
			lm.box("Granite", edge + out * h + Vector3(0, h * 0.5, 0), Vector3(2.4, 0.15, h * 2.6),
				Basis(Vector3.RIGHT, atan2(h, h * 2.4)), 0.0)
		else:
			stair(lm, edge, out, float(gap[1]) * 2.0 - 0.6, h)

## Stone balustrade along a-b: posts every 2.4 m, a low rail and a top
## rail on small struts.
static func _rail(lm: LandmarkMesh, a: Vector3, b: Vector3) -> void:
	var length := a.distance_to(b)
	if length < 0.5:
		return
	var n := maxi(int(length / 2.4), 1)
	for k in n + 1:
		var p := a.lerp(b, float(k) / float(n))
		lm.box("Granite", p + Vector3(0, 0.45, 0), Vector3(0.28, 0.9, 0.28), Basis(), 0.0)
	lm.beam("Granite", a + Vector3(0, 0.15, 0), b + Vector3(0, 0.15, 0), 0.22, 0.3)
	lm.beam("Granite", a + Vector3(0, 0.72, 0), b + Vector3(0, 0.72, 0), 0.16, 0.16)

## A straight stair `width` wide climbing `h` from the ground in front of
## `edge` (on the wall face, at the foot) up to it, leading inward
## against `out`.
static func stair(lm: LandmarkMesh, edge: Vector3, out: Vector3, width: float, h: float) -> void:
	var steps := maxi(int(round(h / 0.2)), 2)
	var rise := h / float(steps)
	var run := 0.34
	var side := Vector3(-out.z, 0, out.x)
	for k in steps:
		var depth := run * float(steps - k)
		var centre := edge + out * depth * 0.5 + Vector3(0, rise * (k + 0.5), 0)
		var size := side.abs() * width + out.abs() * depth + Vector3(0, rise, 0)
		lm.box("Granite", centre, size, Basis(), 0.0)
