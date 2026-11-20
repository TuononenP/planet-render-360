extends RefCounted

## Strawberry Arena (Friends Arena, 2012, Solna) with the Quality Hotel
## Friends tower beside it. Origin on the point midway between the two
## OSM footprints (arena relation 1932910, hotel way 194699561), long axis
## +X along the pitch (bearing 159, registry yaw 69), front +Z.
##
## - The bowl is the mapped 19-point outline (about 241 x 167 m), walled to
##   24 m in pale diamond-faceted steel cladding with vertical fins every
##   6 m, and capped by a dark rounded roof: three stepped hips over the
##   outline's hull rising to 33 m (OSM height=33, roof:shape=round,
##   ridge along the pitch).
## - A dark entrance bay stands at each short end (black cladding, the
##   Friends sign wall), 22 m tall.
## - The hotel is the 18.4 x 47.4 m white concrete slab, 25 levels, 94 m
##   (OSM height=94), its faces perforated by round dark windows in a
##   regular grid, a low dark base, and four red aviation lamps on the
##   roof corners. The arena facade carries a blue lamp band (the real one
##   is lit blue at night).
##
## Sources: docs/stockholm-landmark-sources.md (Tier C), OSM relation
## 1932910 and way 194699561, Commons photos in
## visual-plan/refs/landmarks/strawberry_arena/ (front.jpg: the tower and
## the lit bowl; aerial.jpg: the facade pattern). Fin spacing and the
## window grid are scaled from front.jpg against the 94 m tower.

const Far = preload("res://scripts/generation/landmarks/sweden_stockholm/outer/sto_far_kit.gd")

const OUTLINE := [Vector2(-162.7, 6.1), Vector2(-166.6, 38.5), Vector2(-165.8, 103.8),
	Vector2(-158.0, 124.2), Vector2(-144.6, 137.7), Vector2(-126.6, 142.6), Vector2(5.6, 140.9),
	Vector2(17.3, 138.1), Vector2(30.3, 129.6), Vector2(42.6, 110.2), Vector2(74.6, 110.8),
	Vector2(73.0, -17.5), Vector2(57.8, -17.8), Vector2(57.8, -11.3), Vector2(36.5, -10.5),
	Vector2(22.5, -23.4), Vector2(8.4, -25.7), Vector2(-117.8, -24.5), Vector2(-147.5, -14.2)]
const WALL_H := 24.0
const ROOF_H := 33.0
const HOTEL_C := Vector2(48.6, -54.6)
const HOTEL_W := 18.4
const HOTEL_D := 47.4
const HOTEL_H := 94.0

static func build(model: Node3D) -> void:
	var lm := Far.fresh(_materials())
	_arena(lm)
	_hotel(lm)
	lm.commit(model)

static func _materials() -> Dictionary:
	return {
		"Skin": LandmarkMaterials.pbr("sheet_metal", "#C3C8CB", 3.0),
		"Fin": LandmarkMaterials.pbr("sheet_metal", "#8D949A", 2.0),
		"Roof": LandmarkMaterials.pbr("sheet_metal", "#2C3236", 4.0),
		"Dark": LandmarkMaterials.pbr("concrete", "#22262A", 3.0),
		"Concrete": LandmarkMaterials.pbr("concrete", "#E8E7E2", 3.0),
		"Glass": LandmarkMaterials.glass("#1C2630"),
		"Lamp": LandmarkMaterials.lit("#3E62FF", 0.9),
		"BeaconLamp": LandmarkMaterials.lit("#FF2A1A", 1.2),
	}

## The bowl: walls on the mapped outline, fins, the lit band, the entrance
## bays and the two stepped roofs over the outline's hull.
static func _arena(lm: LandmarkMesh) -> void:
	var ring := PackedVector2Array(OUTLINE)
	lm.poly_prism("Skin", ring, 0.0, WALL_H, false)
	var n := ring.size()
	for i in n:
		var a := ring[i]
		var b := ring[(i + 1) % n]
		var len := a.distance_to(b)
		if len < 6.0:
			continue
		var o := Far.out2(ring, i)
		var cnt := maxi(int(len / 6.0), 2)
		Far.FhP.strips(lm, "Fin", Vector3(a.x, 0, a.y), Vector3(b.x, 0, b.y), Vector3(o.x, 0, o.y),
			1.0, WALL_H - 1.5, cnt, 0.5, 0.7)
	Far.band(lm, "Lamp", ring, 16.0, 1.2, 0.35)
	Far.band(lm, "Fin", ring, WALL_H - 0.5, 0.9, 0.5)
	lm.box("Dark", Vector3(-168.8, 11.0, 71.0), Vector3(4.4, 22.0, 30.0), Basis(), 0.0)
	lm.box("Dark", Vector3(76.8, 11.0, 46.0), Vector3(4.4, 22.0, 32.0), Basis(), 0.0)
	var hull := Geometry2D.convex_hull(ring)
	if hull.size() > 1 and hull[0] == hull[hull.size() - 1]:
		hull.remove_at(hull.size() - 1)
	# Three stepped hips round the bowl's roof: 3 + 3.5 + 2.5 m of rise.
	var roof := hull
	var y := WALL_H
	for step in [[16.0, 3.0], [20.0, 3.5], [24.0, 2.5]]:
		Far.hip_roof(lm, "Roof", roof, y, float(step[0]), float(step[1]))
		roof = Far.inset(roof, float(step[0]))
		y += float(step[1])

## The hotel slab with its grid of round windows, base and beacons.
static func _hotel(lm: LandmarkMesh) -> void:
	var c := HOTEL_C
	lm.box("Dark", Vector3(c.x, 3.0, c.y), Vector3(HOTEL_W + 5.0, 6.0, HOTEL_D + 5.0), Basis(), 0.0)
	lm.box("Concrete", Vector3(c.x, 6.0 + (HOTEL_H - 6.0) * 0.5, c.y), Vector3(HOTEL_W, HOTEL_H - 6.0, HOTEL_D),
		Basis(), 0.0)
	lm.box("Concrete", Vector3(c.x, HOTEL_H - 0.5, c.y), Vector3(HOTEL_W + 0.6, 1.0, HOTEL_D + 0.6), Basis(), 0.0)
	var hx := HOTEL_W * 0.5
	var hz := HOTEL_D * 0.5
	# [wall centre, run direction, run length, outward normal]
	var faces := [
		[Vector3(c.x, 0, c.y + hz), Vector3(1, 0, 0), HOTEL_W, Vector3(0, 0, 1)],
		[Vector3(c.x, 0, c.y - hz), Vector3(1, 0, 0), HOTEL_W, Vector3(0, 0, -1)],
		[Vector3(c.x + hx, 0, c.y), Vector3(0, 0, 1), HOTEL_D, Vector3(1, 0, 0)],
		[Vector3(c.x - hx, 0, c.y), Vector3(0, 0, 1), HOTEL_D, Vector3(-1, 0, 0)],
	]
	for f in faces:
		var cols := int((float(f[2]) - 2.0) / 3.0)
		for r in 25:
			var y := 9.0 + 3.4 * float(r)
			if y > HOTEL_H - 3.0:
				break
			for k in cols:
				var t := (float(k) + 0.5) / float(cols) - 0.5
				var p: Vector3 = (f[0] as Vector3) + (f[1] as Vector3) * (t * (float(f[2]) - 2.0)) \
					+ (f[3] as Vector3) * 0.06 + Vector3(0, y, 0)
				lm.disc("Glass", p, f[3] as Vector3, 0.62, 8)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			lm.box("BeaconLamp", Vector3(c.x + float(sx) * (hx - 0.5), HOTEL_H + 0.3, c.y + float(sz) * (hz - 0.5)),
				Vector3(0.7, 0.6, 0.7), Basis(), 0.0)
