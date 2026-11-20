class_name StoIslandRiddarholmen
extends RefCounted

## Riddarholmen Church (Riddarholmskyrkan, c. 1290-1300) in true metres,
## origin at the centroid of OSM way 23841420 and the nave along +X (east);
## the registry yaw (-13.2) turns +X onto the 76.8 degree axis. Plan and
## heights from the OSM building:part ways of the church; look from the
## photos in visual-plan/refs/landmarks/riddarholmen/.
## - Nave (x -22..25, 11 m wide): red-brown Gothic brick to 16.5 m under a
##   steep verdigris copper roof to 22.5 m; its east end is a five-sided
##   apse under a steep copper hip. A slim octagonal ridge turret with an
##   open belfry and a copper spire stands on the ridge.
## - Aisles: the north row (14 m) and the south row (15 m, running west
##   beside the tower) under lean-to copper roofs, their outer walls
##   lined with tall traceried lancets (two sub-lights under an oculus).
## - Chapels, all with copper domes and lanterns: the Caroline chapel (NE,
##   21 m + dome to 28 m), the Gustavian chapel (SE, 24 m + dome and
##   lantern to 33 m), two small pyramid-domed chapels on the south side
##   and two small domed drums on the north. Sandstone corner strips, string
##   courses and tall mullioned arched windows in stone frames.
## - West tower (10 x 10 m, x -32..-22, 50 m): plain brick shaft with a
##   tall traceried lancet on each face, two clock faces, stone string
##   courses, a belfry stage of paired louvred lancets and four iron
##   corner pinnacles.
## - The cast-iron spire of 1835-41: an openwork square pyramid from 50 m
##   to a gilt needle and cross at 90 m: framed stages with pointed-arch
##   tracery panels in the lower three, X-bracing above, ring beams and
##   corner ribs.
## Surfaces (6): Brick, Copper, Stone, Windows, Iron, Gilt.

const TOP_M := 90.0
const TX := -26.95
const TZ := 0.55
const SHAFT := 50.0
const NAVE_WALL := 16.5
const NAVE_X1 := 25.3
const Kit = preload("res://scripts/generation/landmark_core_b_arch_kit.gd")

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#74402F", 2.5))
	lm.use("Copper", LandmarkMaterials.pbr("concrete", "#56695A", 2.0, 0.55, 0.3))
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#CDB98F", 3.0))
	lm.use("Windows", LandmarkMaterials.glass("#1E2427"))
	lm.use("Iron", LandmarkMaterials.paint("#222425", 0.5, 0.7))
	lm.use("Gilt", LandmarkMaterials.gold())
	_nave(lm)
	_aisles(lm)
	_chapels(lm)
	_tower(lm)
	_spire(lm)
	lm.commit(model)

static func _nave(lm: LandmarkMesh) -> void:
	var x0 := -22.1
	var len := NAVE_X1 - x0
	var cx := (x0 + NAVE_X1) * 0.5
	lm.box("Brick", Vector3(cx, NAVE_WALL * 0.5, 0.4), Vector3(len, NAVE_WALL, 11.0))
	lm.box("Stone", Vector3(cx, NAVE_WALL - 0.25, 0.4), Vector3(len + 0.5, 0.5, 11.5))
	lm.gable("Copper", Vector3(cx, NAVE_WALL, 0.4), 11.0, len, 6.0, Basis(Vector3.UP, PI * 0.5), 0.5)
	lm.box("Copper", Vector3(cx, NAVE_WALL + 6.1, 0.4), Vector3(len + 0.4, 0.3, 0.3), Basis(), 0.0)
	# Five-sided apse and its steep hip.
	var apse := PackedVector2Array()
	for k in 6:
		var a := -PI * 0.5 + PI * float(k) / 5.0
		apse.append(Vector2(NAVE_X1 + cos(a) * 5.5, 0.4 + sin(a) * 5.5))
	lm.poly_prism("Brick", apse, 0.0, NAVE_WALL)
	lm.lathe("Copper", Vector3(NAVE_X1, NAVE_WALL, 0.4), PackedVector2Array([Vector2(6.1, 0.0), Vector2(0.3, 6.0)]),
		10, 1.0, 1.0, 0.0, false)
	for deg in [-36.0, 0.0, 36.0]:
		var a := deg_to_rad(deg)
		var p := Vector3(NAVE_X1 + cos(a) * 5.0, 0.0, 0.4 + sin(a) * 5.0)
		Kit.lancet(lm, "Stone", "Windows", p + Vector3(0, 2.2, 0), Vector3(cos(a), 0, sin(a)), 2.0, 10.5, 0.35, true)
	_ridge_turret(lm, Vector3(12.0, NAVE_WALL + 6.0, 0.4))

## Slim octagonal ridge turret: open belfry, copper spire, gilt cross.
static func _ridge_turret(lm: LandmarkMesh, b: Vector3) -> void:
	lm.frustum("Copper", b, 1.5, 1.3, 3.2, 8, PI / 8.0)
	for k in 8:
		var a := PI / 8.0 + TAU * float(k) / 8.0 + PI / 8.0
		lm.box("Windows", b + Vector3(cos(a) * 1.3, 2.0, sin(a) * 1.3), Vector3(0.5, 1.3, 0.06),
			Basis(Vector3.UP, -a + PI * 0.5), 0.0)
	lm.frustum("Copper", b + Vector3(0, 3.2, 0), 1.8, 1.45, 0.4, 8, PI / 8.0)
	lm.lathe("Copper", b + Vector3(0, 3.6, 0), PackedVector2Array([Vector2(1.45, 0.0), Vector2(0.9, 1.4),
		Vector2(0.22, 6.6)]), 8, 1.0, 1.0, PI / 8.0, false)
	lm.lathe("Gilt", b + Vector3(0, 10.2, 0), PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.3, 0.3), Vector2(0.0, 0.7)]), 8)
	Kit.cross(lm, "Gilt", b + Vector3(0, 10.8, 0), 2.0)

## North and south aisle rows under lean-to roofs, their lancets.
static func _aisles(lm: LandmarkMesh) -> void:
	_aisle(lm, -22.0, 7.7, -16.0, -4.2, 14.0, -1.0)
	_aisle(lm, -32.1, 14.2, 5.5, 16.6, 15.0, 1.0)
	# Stair block north of the tower.
	lm.box("Brick", Vector3(-26.75, 9.75, -7.2), Vector3(9.9, 19.5, 6.0))
	lm.box("Stone", Vector3(-26.75, 19.3, -7.2), Vector3(10.3, 0.5, 6.4))

static func _aisle(lm: LandmarkMesh, x0: float, x1: float, z0: float, z1: float, h: float, side: float) -> void:
	var cx := (x0 + x1) * 0.5
	var cz := (z0 + z1) * 0.5
	lm.box("Brick", Vector3(cx, h * 0.5, cz), Vector3(x1 - x0, h, z1 - z0))
	lm.box("Stone", Vector3(cx, h - 0.25, cz), Vector3(x1 - x0 + 0.5, 0.5, z1 - z0 + 0.5))
	lm.box("Stone", Vector3(cx, 0.5, cz), Vector3(x1 - x0 + 0.5, 1.0, z1 - z0 + 0.5))
	# Lean-to copper roof rising toward the nave wall.
	var up := 1.6
	var wall := z1 if side < 0.0 else z0
	var outer := z0 if side < 0.0 else z1
	lm.quad("Copper", Vector3(x0 - 0.3, h, outer + side * 0.4), Vector3(x1 + 0.3, h, outer + side * 0.4),
		Vector3(x1 + 0.3, h + up, wall), Vector3(x0 - 0.3, h + up, wall), Vector3(0, 1.0, side * 0.5).normalized())
	var n := Vector3(0, 0, side)
	var count := int((x1 - x0 - 1.0) / 4.6)
	for k in count:
		var x := x0 + (x1 - x0) * (float(k) + 0.5) / float(count)
		Kit.lancet(lm, "Stone", "Windows", Vector3(x, 3.4, outer + side * 0.0), n, 1.9, 8.2, 0.3, true)

## The six chapels with their domes and lanterns, from the OSM parts.
static func _chapels(lm: LandmarkMesh) -> void:
	# [x0, x1, z0, z1, wall, dome rise, lantern?, facing z]
	_chapel(lm, 13.7, 26.4, -16.6, -6.1, 21.0, 7.0, false, -1.0)
	_chapel(lm, 18.4, 26.8, 10.0, 17.1, 24.0, 9.0, true, 1.0)
	_chapel(lm, 5.2, 14.3, 9.6, 17.1, 22.0, 6.5, true, 1.0)
	_chapel(lm, -4.8, 1.3, 10.5, 17.0, 22.0, 7.0, true, 1.0)
	_chapel(lm, -16.7, -7.7, -15.9, -10.3, 19.0, 5.0, false, -1.0)
	_chapel(lm, -3.8, 7.5, -16.2, -10.3, 19.0, 5.0, false, -1.0)

static func _chapel(lm: LandmarkMesh, x0: float, x1: float, z0: float, z1: float, wall: float, rise: float,
		lantern: bool, face: float) -> void:
	var cx := (x0 + x1) * 0.5
	var cz := (z0 + z1) * 0.5
	var sx := x1 - x0
	var sz := z1 - z0
	lm.box("Brick", Vector3(cx, wall * 0.5, cz), Vector3(sx, wall, sz))
	lm.box("Stone", Vector3(cx, wall - 0.3, cz), Vector3(sx + 0.7, 0.6, sz + 0.7))
	lm.box("Stone", Vector3(cx, wall * 0.55, cz), Vector3(sx + 0.3, 0.3, sz + 0.3), Basis(), 0.0)
	# Sandstone quoins on the corners.
	for qx in [-1.0, 1.0]:
		for qz in [-1.0, 1.0]:
			lm.box("Stone", Vector3(cx + qx * (sx * 0.5 - 0.1), wall * 0.5, cz + qz * (sz * 0.5 - 0.1)),
				Vector3(0.5, wall - 0.6, 0.5), Basis(), 0.0)
	# Tall arched windows in stone frames on the outer face.
	var wz := cz + face * sz * 0.5
	var nw := maxi(int(sx / 3.2), 1)
	for k in nw:
		var x := x0 + sx * (float(k) + 0.5) / float(nw)
		LandmarkDetail.window(lm, "Stone", "Windows", Vector3(x, wall * 0.42, wz), Vector3(0, 0, face), 1.5, 7.0, true, 0.3)
	# Copper dome (the footprint's own proportions) under its lantern.
	var rx := sx * 0.5 + 0.35
	var rz := sz * 0.5 + 0.35
	var rm := maxf(rx, rz)
	lm.lathe("Copper", Vector3(cx, wall, cz), Kit.dome(rm, rise, 8), 16, rx / rm, rz / rm)
	if lantern:
		var ly := wall + rise - 0.2
		lm.frustum("Copper", Vector3(cx, ly, cz), 1.0, 0.95, 2.6, 8, PI / 8.0)
		lm.lathe("Copper", Vector3(cx, ly + 2.6, cz), PackedVector2Array([Vector2(1.2, 0.0), Vector2(0.6, 1.2),
			Vector2(0.15, 3.4)]), 8, 1.0, 1.0, PI / 8.0, false)
		Kit.cross(lm, "Gilt", Vector3(cx, ly + 6.0, cz), 1.6)

static func _tower(lm: LandmarkMesh) -> void:
	var t := Vector3(TX, 0.0, TZ)
	lm.box("Stone", t + Vector3(0, 0.6, 0), Vector3(10.6, 1.2, 10.8))
	lm.box("Brick", t + Vector3(0, SHAFT * 0.5, 0), Vector3(9.9, SHAFT, 10.1))
	for y in [24.0, 44.5, SHAFT]:
		lm.box("Stone", t + Vector3(0, y, 0), Vector3(10.5, 0.55, 10.7))
	var faces := [Vector3(-1, 0, 0), Vector3(1, 0, 0), Vector3(0, 0, -1), Vector3(0, 0, 1)]
	for f in faces:
		var n: Vector3 = f
		var half := 4.95 if absf(n.x) > 0.5 else 5.05
		var face := t + n * half
		# Tall traceried lancet, then the belfry's paired louvred lancets.
		Kit.lancet(lm, "Stone", "Windows", face + Vector3(0, 27.0, 0), n, 2.8, 13.0, 0.35, true)
		for s in [-1.4, 1.4]:
			var side := Vector3.UP.cross(n).normalized() * float(s)
			Kit.lancet(lm, "Stone", "Windows", face + side + Vector3(0, 46.0, 0), n, 1.5, 4.4, 0.25, false)
	# Clock faces on the south and north faces.
	for sgn in [-1.0, 1.0]:
		var n := Vector3(0, 0, sgn)
		var c := t + n * 5.1 + Vector3(0, 41.0, 0)
		lm.disc("Stone", c, n, 1.7, 20)
		Kit.ring_beams(lm, "Gilt", c + n * 0.05, n, 1.7, 0.22, 20)
		lm.beam("Iron", c + n * 0.1, c + n * 0.1 + Vector3(0.9, 0.6, 0), 0.14, 0.05, n)
		lm.beam("Iron", c + n * 0.1, c + n * 0.1 + Vector3(-0.2, 1.2, 0), 0.12, 0.05, n)
	# Corner pinnacles in iron.
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			Kit.pinnacle(lm, "Iron", t + Vector3(sx * 4.35, SHAFT + 0.3, sz * 4.45), 0.55, 9.0)

## Cast-iron openwork spire: stages tapering from the tower top.
static func _spire(lm: LandmarkMesh) -> void:
	var y0 := SHAFT + 0.4
	var y1 := 86.4
	var stages := 8
	lm.box("Iron", Vector3(TX, y0, TZ), Vector3(9.4, 0.6, 9.4), Basis(), 0.0)
	var ring_prev := _ring(y0 + 0.3, 3.9)
	for k in stages:
		var yb := lerpf(y0 + 0.3, y1, float(k + 1) / float(stages))
		var hb := lerpf(3.9, 0.3, pow(float(k + 1) / float(stages), 0.9))
		var ring := _ring(yb, hb)
		for f in 4:
			var g := (f + 1) % 4
			if k < 3:
				_arch_panel(lm, ring_prev[f], ring_prev[g], ring[f], ring[g])
			else:
				lm.lattice_panel("Iron", ring_prev[f], ring_prev[g], ring[f], ring[g], 0.16)
			lm.beam("Iron", ring_prev[f], ring[f], 0.32, 0.32)
			lm.beam("Iron", ring[f], ring[g], 0.2, 0.2)
		ring_prev = ring
	lm.beam("Iron", Vector3(TX, y1, TZ), Vector3(TX, TOP_M - 2.4, TZ), 0.2, 0.2)
	lm.lathe("Gilt", Vector3(TX, TOP_M - 3.4, TZ), PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.28, 0.3),
		Vector2(0.0, 0.9)]), 8)
	Kit.cross(lm, "Gilt", Vector3(TX, TOP_M - 2.4, TZ), 2.4)

static func _ring(y: float, h: float) -> Array:
	return [Vector3(TX - h, y, TZ - h), Vector3(TX + h, y, TZ - h), Vector3(TX + h, y, TZ + h), Vector3(TX - h, y, TZ + h)]

## A framed panel with a pointed-arch tracery light between two ring
## beams (stages 1-3 of the spire).
static func _arch_panel(lm: LandmarkMesh, p0: Vector3, p1: Vector3, q0: Vector3, q1: Vector3) -> void:
	var mid_b := (p0 + p1) * 0.5
	var mid_t := (q0 + q1) * 0.5
	var right := (p1 - p0).normalized()
	var w := p0.distance_to(p1) * 0.62
	var rise := Kit.pointed_rise(w)
	var lift := maxf(mid_t.y - mid_b.y - rise - 0.3, 0.2)
	var mid := mid_b.lerp(mid_t, 0.5)
	var base := Vector3(mid.x, mid_b.y, mid.z)
	var out := right.cross(Vector3.UP)
	var arch := Kit.pointed(base + Vector3.UP * lift, right, w, 3)
	for i in arch.size() - 1:
		lm.beam("Iron", arch[i], arch[i + 1], 0.16, 0.16, out)
	for s in [-1.0, 1.0]:
		lm.beam("Iron", base + right * w * 0.5 * s, base + right * w * 0.5 * s + Vector3.UP * lift, 0.16, 0.16, out)
	lm.beam("Iron", base, base + Vector3.UP * (lift + rise * 0.7), 0.12, 0.12, out)
