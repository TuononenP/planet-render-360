extends RefCounted

## Stockholm Waterfront Congress Centre and the Radisson Blu Waterfront
## Hotel beside Stockholm Central station (2010-11). Origin at the OSM base
## footprint centre (way 232363414, 179 x 70 m, bearing 147.5). The registry
## yaw 57.5 turns +X onto SSE: the hotel stands at the -X (north-north-west)
## end, the congress hall at the +X end, the station tracks lie on the -Z
## side and Klara sjö on +Z. 42 m to the hotel roofs (12 levels x 3.5 m:
## derived, OSM has levels only).
##
## From the photos (stockholm_waterfront/front.jpg and the Central station
## refs side.jpg and quarter.jpg, which show it from the tracks):
## - A two-storey glazed podium (green-tinted curtain wall, slim mullions,
##   green steel columns visible inside, a concrete roof slab) carries
##   everything and wraps the whole footprint.
## - Above it the congress hall is a stack of three leaning tiers clad in
##   vertical stainless-steel louvres (fins 0.3 m wide every 0.9 m), each
##   tier wider at the top than the base or tilting the other way so the
##   mass reads as a wavy, layered ship's hull; the lower tier flares out
##   over the podium, the upper ones step in, a dark plant stack on top.
##   Behind the louvres the walls are dark.
## - The hotel is three blocks at the north-west end: the Radisson Blu slab
##   (dark grey panels with a regular window grid and a white concrete
##   stripe at its end) and, further out, two dark glass curtain-wall
##   towers (OSM parts 12 levels), one a little lower.
## - A canopy on slanted struts marks the entrance on the track side.
## Sources: docs/stockholm-landmark-sources.md (way 232363414 with parts
## 1242589614-17: slabs 12 levels, waterside part 6 levels); the Commons photos.

const FhU = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")
const Kit = preload("res://scripts/generation/landmarks/sweden_stockholm/palaces/sto_baroque_kit.gd")

const PX0 := -62.0
const PX1 := 89.7
const PZ := 35.0
const POD_H := 9.5
const HOTEL_H := 40.8
const PLANT_TOP := 42.0
const FIN_STEP := 0.9

static func build(model: Node3D) -> void:
	var lm := Kit.fresh(_materials())
	_podium(lm)
	_hall(lm)
	_radisson(lm)
	_towers(lm)
	_canopy(lm)
	lm.commit(model)

static func _materials() -> Dictionary:
	return {
		"Louvre": LandmarkMaterials.pbr("sheet_metal", "#C4BDB0", 3.0, 0.4, 0.5),
		"HallWall": LandmarkMaterials.pbr("concrete", "#6A665F", 3.0),
		"Roof": LandmarkMaterials.pbr("membrane", "#3C3C3E", 3.0),
		"PodGlass": LandmarkMaterials.glass("#5E8A80"),
		"Curtain": LandmarkMaterials.glass("#26364A"),
		"Mull": LandmarkMaterials.paint("#8E9396", 0.4, 0.6),
		"Green": LandmarkMaterials.paint("#587A66"),
		"Concrete": LandmarkMaterials.pbr("concrete", "#8E8D88", 3.0),
		"Panel": LandmarkMaterials.pbr("concrete", "#3B4046", 3.0),
		"White": LandmarkMaterials.pbr("concrete", "#E3E1DA", 3.0),
		"Glass": LandmarkMaterials.glass("#2A3640"),
		"Lamp": LandmarkMaterials.lit("#FFE0A0", 0.7),
	}

## The glazed podium round the whole footprint: curtain wall, mullions,
## inside columns, a warm light strip and the concrete roof slab.
static func _podium(lm: LandmarkMesh) -> void:
	var w := PX1 - PX0
	var cx := (PX0 + PX1) * 0.5
	lm.box("Concrete", Vector3(cx, 0.3, 0), Vector3(w + 0.6, 0.6, PZ * 2.0 + 0.6), Basis(), 0.0)
	lm.box("Concrete", Vector3(cx, POD_H - 0.25, 0), Vector3(w + 1.4, 0.5, PZ * 2.0 + 1.4), Basis(), 0.0)
	var runs := [
		[Vector3(PX0, 0, -PZ), Vector3(PX1, 0, -PZ), Vector3(0, 0, -1)],
		[Vector3(PX0, 0, PZ), Vector3(PX1, 0, PZ), Vector3(0, 0, 1)],
		[Vector3(PX0, 0, -PZ), Vector3(PX0, 0, PZ), Vector3(-1, 0, 0)],
		[Vector3(PX1, 0, -PZ), Vector3(PX1, 0, PZ), Vector3(1, 0, 0)],
	]
	for r in runs:
		var a: Vector3 = r[0]
		var b: Vector3 = r[1]
		var out: Vector3 = r[2]
		lm.quad("PodGlass", a + Vector3(0, 0.6, 0), b + Vector3(0, 0.6, 0), b + Vector3(0, POD_H - 0.5, 0),
			a + Vector3(0, POD_H - 0.5, 0), out)
		var len := a.distance_to(b)
		var n := int(len / 3.0)
		var basis := Kit.face(out)
		for i in n + 1:
			var p := a.lerp(b, float(i) / float(n)) + out * 0.05
			lm.box("Mull", p + Vector3(0, POD_H * 0.5, 0), Vector3(0.14, POD_H - 1.1, 0.22), basis, 0.0)
		# Warm light strip behind the glass, under the roof slab.
		lm.quad("Lamp", a - out * 0.6 + Vector3(0, 7.7, 0), b - out * 0.6 + Vector3(0, 7.7, 0),
			b - out * 0.6 + Vector3(0, 8.2, 0), a - out * 0.6 + Vector3(0, 8.2, 0), out)
		# Green columns just inside.
		var cols := int(len / 9.0)
		for i in cols + 1:
			var q := a.lerp(b, float(i) / float(cols)) - out * 1.6
			lm.box("Green", q + Vector3(0, POD_H * 0.5, 0), Vector3(0.5, POD_H - 0.6, 0.5), Basis(), 0.0)

## Chamfered rectangle outline (x0..x1, z0..z1), corners cut by `c`.
static func _outline(x0: float, x1: float, z0: float, z1: float, c: float) -> PackedVector2Array:
	return PackedVector2Array([Vector2(x0 + c, z0), Vector2(x1 - c, z0), Vector2(x1, z0 + c), Vector2(x1, z1 - c),
		Vector2(x1 - c, z1), Vector2(x0 + c, z1), Vector2(x0, z1 - c), Vector2(x0, z0 + c)])

## The louvred congress hall: three leaning tiers on the podium roof.
static func _hall(lm: LandmarkMesh) -> void:
	var y0 := POD_H
	_tier(lm, _outline(16, 88, -33, 3, 4), _outline(10, 90, -35, 5, 5), y0, y0 + 8.5)
	_tier(lm, _outline(22, 80, -31, 1, 4), _outline(26, 86, -30, -1, 4), y0 + 8.5, y0 + 16.5)
	_tier(lm, _outline(32, 72, -29, -3, 3), _outline(30, 76, -30, -2, 3), y0 + 16.5, y0 + 22.0)
	# Dark plant stack on the top tier.
	lm.box("HallWall", Vector3(52.0, y0 + 22.0 + 1.2, -14.0), Vector3(5.0, 2.4, 5.0), Basis(), 0.0)
	lm.box("Roof", Vector3(52.0, y0 + 22.0 + 2.5, -14.0), Vector3(5.4, 0.2, 5.4), Basis(), 0.0)

## One tier from the bottom ring to the top ring (both the same chamfered
## rectangle, 8 points): dark backing wall, louvre fins and a roof cap.
static func _tier(lm: LandmarkMesh, bot: PackedVector2Array, top: PackedVector2Array, y0: float, y1: float) -> void:
	var centre := Vector2.ZERO
	for p in bot:
		centre += p
	centre /= float(bot.size())
	var n_pts := bot.size()
	var idx := 0
	for i in n_pts:
		var j := (i + 1) % n_pts
		var pb0 := Vector3(bot[i].x, y0, bot[i].y)
		var pb1 := Vector3(bot[j].x, y0, bot[j].y)
		var pt0 := Vector3(top[i].x, y1, top[i].y)
		var pt1 := Vector3(top[j].x, y1, top[j].y)
		var edge := pb1 - pb0
		var mid := (pb0 + pb1) * 0.5
		var out_h := Vector3(mid.x - centre.x, 0, mid.z - centre.y).normalized()
		var nrm := edge.cross(pt0 - pb0).normalized()
		if nrm.dot(out_h) < 0.0:
			nrm = -nrm
		lm.quad("HallWall", pb0, pb1, pt1, pt0, nrm)
		var count := maxi(int(edge.length() / FIN_STEP), 1)
		for k in count:
			var t := (float(k) + 0.5) / float(count)
			var fb := pb0.lerp(pb1, t) + nrm * 0.14
			var ft := pt0.lerp(pt1, t) + nrm * 0.14
			ft.y += 0.45 * sin(float(idx) * 0.37)
			lm.beam("Louvre", fb, ft, 0.3, 0.4, edge, false)
			idx += 1
	var tri := Geometry2D.triangulate_polygon(top)
	for t in range(0, tri.size(), 3):
		var a := top[tri[t]]
		var b := top[tri[t + 1]]
		var c := top[tri[t + 2]]
		lm.tri("Roof", Vector3(a.x, y1, a.y), Vector3(b.x, y1, b.y), Vector3(c.x, y1, c.y),
			Vector3.UP, Vector3.UP, Vector3.UP, a, b, c)

## Radisson Blu slab: dark panels, a window grid, a white end stripe.
static func _radisson(lm: LandmarkMesh) -> void:
	var x0 := -31.0
	var x1 := -8.0
	var z0 := -27.0
	var z1 := 35.0
	FhU.blk(lm, "Panel", (x0 + x1) * 0.5, POD_H, (z0 + z1) * 0.5, x1 - x0, HOTEL_H - POD_H, z1 - z0)
	FhU.blk(lm, "Roof", (x0 + x1) * 0.5, HOTEL_H, (z0 + z1) * 0.5 + 8.0, 13.0, PLANT_TOP - HOTEL_H, 30.0)
	FhU.blk(lm, "White", (x0 + x1) * 0.5, POD_H, z0 - 0.15, 3.0, HOTEL_H - POD_H, 0.3)
	_grid(lm, Vector3(x0, 0, z1), Vector3(x1, 0, z1), Vector3(0, 0, 1), 7, 3)
	_grid(lm, Vector3(x0, 0, z0), Vector3(x1, 0, z0), Vector3(0, 0, -1), 7, 5)
	_grid(lm, Vector3(x1, 0, z0), Vector3(x1, 0, z1), Vector3(1, 0, 0), 20, 7)
	_grid(lm, Vector3(x0, 0, z0), Vector3(x0, 0, z1), Vector3(-1, 0, 0), 20, 11)

## `n` window columns by nine storeys on a face run a..b, a few of them lit.
static func _grid(lm: LandmarkMesh, a: Vector3, b: Vector3, out: Vector3, n: int, seed_n: int) -> void:
	for j in 9:
		var y := POD_H + 1.0 + float(j) * 3.5
		for i in n:
			var p := a.lerp(b, (float(i) + 0.5) / float(n))
			var key := "Lamp" if (i * 17 + j * 29 + i * j * 5 + seed_n) % 9 == 0 else "Glass"
			FhU.opening(lm, key, p + Vector3(0, y, 0) + out * 0.06, out, 1.7, 2.1, false)

## Two dark curtain-wall towers: mullion grid, floor bands, a lit cell here
## and there.
static func _towers(lm: LandmarkMesh) -> void:
	_tower(lm, -53.5, 17.0, 33.0, HOTEL_H + 0.8, -18.5)
	_tower(lm, -53.5, 17.0, 33.0, HOTEL_H - 2.3, 18.5)

static func _tower(lm: LandmarkMesh, cx: float, w: float, d: float, top: float, cz: float) -> void:
	var h := top - POD_H
	FhU.blk(lm, "Curtain", cx, POD_H, cz, w, h, d)
	FhU.blk(lm, "Roof", cx, top, cz, w - 1.0, 0.25, d - 1.0)
	for y in range(0, int(h / 3.5) + 1):
		var yy := POD_H + float(y) * 3.5
		if yy > top - 0.2:
			break
		_collar(lm, cx, cz, w, d, yy)
	var faces := [
		[Vector3(cx - w * 0.5, 0, cz - d * 0.5), Vector3(cx - w * 0.5, 0, cz + d * 0.5), Vector3(-1, 0, 0), 20],
		[Vector3(cx + w * 0.5, 0, cz - d * 0.5), Vector3(cx + w * 0.5, 0, cz + d * 0.5), Vector3(1, 0, 0), 20],
		[Vector3(cx - w * 0.5, 0, cz - d * 0.5), Vector3(cx + w * 0.5, 0, cz - d * 0.5), Vector3(0, 0, -1), 10],
		[Vector3(cx - w * 0.5, 0, cz + d * 0.5), Vector3(cx + w * 0.5, 0, cz + d * 0.5), Vector3(0, 0, 1), 10],
	]
	var s := 0
	for f in faces:
		var a: Vector3 = f[0]
		var b: Vector3 = f[1]
		var out: Vector3 = f[2]
		var n: int = f[3]
		var basis := Kit.face(out)
		for i in n + 1:
			var p := a.lerp(b, float(i) / float(n)) + out * 0.05
			lm.box("Mull", p + Vector3(0, POD_H + h * 0.5, 0), Vector3(0.1, h, 0.2), basis, 0.0)
		for j in int(h / 3.5):
			for i in n:
				if (i * 5 + j * 11 + s) % 7 == 0:
					var q := a.lerp(b, (float(i) + 0.5) / float(n)) + Vector3(0, POD_H + 0.6 + float(j) * 3.5, 0)
					FhU.opening(lm, "Lamp", q + out * 0.08, out, d / float(n) * 0.85 if n == 20 else 1.3, 2.4, false)
		s += 3

## Floor band round a tower (a thin four-sided collar).
static func _collar(lm: LandmarkMesh, cx: float, cz: float, w: float, d: float, y: float) -> void:
	for s in [-1.0, 1.0]:
		var sg: float = s
		lm.box("Mull", Vector3(cx, y, cz + sg * (d * 0.5 + 0.06)), Vector3(w + 0.24, 0.25, 0.12), Basis(), 0.0)
		lm.box("Mull", Vector3(cx + sg * (w * 0.5 + 0.06), y, cz), Vector3(0.12, 0.25, d), Basis(), 0.0)

## Entrance canopy on slanted struts on the track side.
static func _canopy(lm: LandmarkMesh) -> void:
	lm.box("Concrete", Vector3(40.0, 6.3, -39.0), Vector3(22.0, 0.4, 8.0), Basis(), 0.0)
	for x in [30.0, 50.0]:
		lm.beam("Mull", Vector3(float(x), 0.6, -43.0), Vector3(float(x), 6.1, -37.0), 0.4, 0.4)
	for x in [30.0, 50.0]:
		lm.beam("Mull", Vector3(float(x), 6.1, -43.0), Vector3(float(x), 9.0, -36.0), 0.3, 0.3)
