class_name LandmarkMseSaigon
extends RefCounted

## Notre-Dame Cathedral Basilica of Saigon in true metres (1877-1880,
## Jules Bourard): red Toulouse brick Romanesque revival, 93 m long and
## 35 m across the transept, the nave vault 21 m high, nave and aisles
## with side chapels, a transept, a round apse with radiating chapels,
## and the west front of two 57.6 m towers (iron spires of 1895) whose
## crosses reach 60.5 m. Faces +Z (the front).

const U = preload("res://scripts/generation/landmarks/mainland_se_asia/landmark_mse_util.gd")

const TOP_M := 60.5
const FRONT_Z := 46.5

## Nave (12 m wide), aisles and chapels in seven bays from the front to
## the crossing, the transept, the choir and apse; the front with three
## portals, the arcaded gallery, the rose window and gable between the
## towers.
static func saigon_notre_dame(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#B04A30", 3.0))
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#CDBFA6", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("terracotta", "#B5573A", 2.0))
	lm.use("Steel", LandmarkMaterials.paint("#5A6068", 0.5, 0.6))
	lm.use("Dark", LandmarkMaterials.paint("#2A211C", 0.9, 0.0))
	lm.use("Glass", LandmarkMaterials.glass("#3A4A60"))
	var z_cross := -14.0
	var nave_l := FRONT_Z - 8.5 - (z_cross + 6.0)
	var nave_c := (FRONT_Z - 8.5 + z_cross + 6.0) * 0.5
	var choir_end := -34.0
	var full_c := (FRONT_Z - 8.5 + choir_end) * 0.5
	lm.box("Stone", Vector3(0, 0.4, -2.0), Vector3(32.0, 0.8, 88.0))
	# Nave: walls to the 21 m vault, clerestory, the gabled roof.
	lm.box("Brick", Vector3(0, 11.5, full_c), Vector3(12.0, 23.0, FRONT_Z - 8.5 - choir_end))
	U.swept_roof(lm, "Roof", "", "Brick", Vector3(0, 23.0, full_c), Basis(), 12.0,
		FRONT_Z - 8.5 - choir_end, 6.5, 0.0, 0.6)
	for s in [-1.0, 1.0]:
		var n := Vector3(s, 0, 0)
		# Aisle (6 m) and side chapels (3 m) under lean-to roofs.
		lm.box("Brick", Vector3(s * 9.0, 6.0, nave_c), Vector3(6.0, 12.0, nave_l))
		lm.box("Brick", Vector3(s * 13.5, 4.0, nave_c), Vector3(3.0, 8.0, nave_l))
		_lean_to(lm, Vector3(s * 6.0, 12.0, nave_c), s, 6.0, nave_l, 2.4)
		_lean_to(lm, Vector3(s * 12.0, 8.0, nave_c), s, 3.0, nave_l, 1.2)
		for i in 7:
			var z := FRONT_Z - 12.0 - 6.6 * float(i)
			lm.box("Brick", Vector3(s * 15.3, 4.4, z - 3.3), Vector3(0.9, 8.8, 1.1))
			LandmarkDetail.window(lm, "Stone", "Glass", Vector3(s * 15.02, 4.2, z), n, 1.4, 3.6, true, 0.2)
			LandmarkDetail.window(lm, "Stone", "Glass", Vector3(s * 6.02, 17.2, z), n, 1.6, 4.0, true, 0.2)
			lm.disc("Glass", Vector3(s * 12.05, 10.0, z), n, 0.7, 12)
			lm.box("Stone", Vector3(s * 12.0, 10.0, z), Vector3(0.24, 1.8, 1.8), Basis(), 0.0)
			lm.box("Brick", Vector3(s * 6.4, 18.0, z - 3.3), Vector3(0.8, 10.0, 1.0))
		lm.box("Stone", Vector3(s * 6.1, 22.6, full_c), Vector3(0.5, 0.5, FRONT_Z - 8.5 - choir_end))
	# Transept (35 m across), its gable ends with rose windows.
	lm.box("Brick", Vector3(0, 10.5, z_cross), Vector3(35.0, 21.0, 12.0))
	U.swept_roof(lm, "Roof", "", "Brick", Vector3(0, 21.0, z_cross), Basis(Vector3.UP, PI * 0.5), 12.0, 35.0, 6.0, 0.0, 0.6)
	for s in [-1.0, 1.0]:
		var n := Vector3(s, 0, 0)
		lm.disc("Glass", Vector3(s * 17.55, 14.5, z_cross), n, 2.6, 20)
		_tracery(lm, Vector3(s * 17.6, 14.5, z_cross), n, 2.6)
		LandmarkDetail.window(lm, "Stone", "Glass", Vector3(s * 17.52, 5.0, z_cross), n, 2.4, 5.0, true, 0.25)
		for zz in [-5.6, 5.6]:
			lm.box("Brick", Vector3(s * 17.0, 9.5, z_cross + zz), Vector3(2.0, 19.0, 1.2))
	# Choir and apse with its radiating chapels and half-cone roof.
	lm.lathe("Brick", Vector3(0, 0.8, choir_end), PackedVector2Array([Vector2(6.0, 0), Vector2(6.0, 22.2)]), 16)
	lm.lathe("Roof", Vector3(0, 23.0, choir_end), PackedVector2Array([Vector2(6.6, 0), Vector2(3.0, 3.6),
		Vector2(0.0, 6.5)]), 16)
	lm.lathe("Brick", Vector3(0, 0.8, choir_end), PackedVector2Array([Vector2(10.5, 0), Vector2(10.5, 10.2)]), 16)
	lm.lathe("Roof", Vector3(0, 11.0, choir_end), PackedVector2Array([Vector2(11.0, 0), Vector2(6.0, 2.8)]), 16)
	for i in 5:
		var a := PI * (0.1 + 0.2 * float(i))
		var d := Vector3(cos(a), 0, -sin(a))
		lm.frustum("Brick", Vector3(0, 0.8, choir_end) + d * 11.6, 2.6, 2.6, 7.0, 10)
		lm.frustum("Roof", Vector3(0, 7.8, choir_end) + d * 11.6, 3.0, 0.0, 2.2, 10)
		LandmarkDetail.window(lm, "Stone", "Glass", Vector3(0, 4.0, choir_end) + d * 14.22, d, 1.0, 3.0, true, 0.15)
		LandmarkDetail.window(lm, "Stone", "Glass", Vector3(0, 16.4, choir_end) + d * 6.02, d, 1.2, 3.6, true, 0.15)
	_front(lm)
	for s in [-1.0, 1.0]:
		_tower(lm, Vector3(s * 11.0, 0.8, FRONT_Z - 5.75), s)
	lm.commit(model)

## Lean-to roof falling outward (side s) from the wall line at `c`.
static func _lean_to(lm: LandmarkMesh, key_c: Vector3, s: float, w: float, l: float, drop: float) -> void:
	var o := w + 0.6
	lm.quad("Roof", key_c + Vector3(0, 0, -l * 0.5), key_c + Vector3(0, 0, l * 0.5),
		key_c + Vector3(s * o, -drop - 0.2, l * 0.5), key_c + Vector3(s * o, -drop - 0.2, -l * 0.5),
		Vector3(s * drop, w, 0).normalized())

## Rose-window tracery of radius r facing n: a stone ring and twelve spokes.
static func _tracery(lm: LandmarkMesh, c: Vector3, n: Vector3, r: float) -> void:
	var u := n.cross(Vector3.UP).normalized()
	var prev := c + u * r
	for i in 24:
		var a := TAU * float(i + 1) / 24.0
		var p := c + (u * cos(a) + Vector3.UP * sin(a)) * r
		lm.beam("Stone", prev, p, 0.35, 0.3, n)
		prev = p
	for i in 12:
		var a := TAU * float(i) / 12.0
		lm.beam("Stone", c + n * 0.05, c + n * 0.05 + (u * cos(a) + Vector3.UP * sin(a)) * r, 0.14, 0.14, n)
	lm.disc("Stone", c + n * 0.1, n, r * 0.22, 12)

## The front between the towers: three round-arched portals in stone
## surrounds, the arcaded gallery of the organ loft, the rose window
## and the gable with its cross.
static func _front(lm: LandmarkMesh) -> void:
	var z := FRONT_Z - 5.0
	var n := Vector3(0, 0, 1)
	lm.box("Brick", Vector3(0, 12.0, z - 3.5), Vector3(11.0, 24.0, 7.0))
	lm.gable("Brick", Vector3(0, 24.0, z - 3.5), 11.0, 7.0, 5.0, Basis(Vector3.UP, PI * 0.5), 0.2, "Brick")
	lm.box("Stone", Vector3(0, 0.8 + 6.0, z + 0.4), Vector3(11.0, 0.5, 0.8))
	lm.box("Dark", Vector3(0, 3.4, z + 0.06), Vector3(3.2, 5.2, 0.1), Basis(), 0.0)
	LandmarkDetail.arch(lm, "Stone", Vector3(0, 6.0, z), n, 3.2)
	for x in [-1.6, 1.6]:
		lm.box("Stone", Vector3(x * 1.2, 3.4, z + 0.25), Vector3(0.5, 5.2, 0.5))
	# Arcaded gallery: five small round arches on colonnettes.
	for i in 5:
		var x := -4.0 + 2.0 * float(i)
		lm.box("Dark", Vector3(x, 9.6, z + 0.03), Vector3(1.2, 2.4, 0.1), Basis(), 0.0)
		LandmarkDetail.arch(lm, "Stone", Vector3(x, 10.8, z), n, 1.2, 0.25, 0.2)
		lm.box("Stone", Vector3(x - 1.0, 9.6, z + 0.15), Vector3(0.3, 2.4, 0.3), Basis(), 0.0)
	lm.box("Stone", Vector3(0, 8.3, z + 0.3), Vector3(11.0, 0.4, 0.6))
	lm.disc("Glass", Vector3(0, 16.5, z + 0.05), n, 3.2, 24)
	_tracery(lm, Vector3(0, 16.5, z + 0.1), n, 3.2)
	lm.box("Stone", Vector3(0, 21.0, z + 0.3), Vector3(11.0, 0.4, 0.6))
	for k in 6:
		var y := 24.0 + 0.8 * float(k)
		var hw := 5.5 * (1.0 - float(k) / 6.0)
		lm.box("Stone", Vector3(-hw * 0.5, y + 0.4, z + 0.15), Vector3(0.6, 0.3, 0.3), Basis(), 0.0)
		lm.box("Stone", Vector3(hw * 0.5, y + 0.4, z + 0.15), Vector3(0.6, 0.3, 0.3), Basis(), 0.0)
	lm.beam("Stone", Vector3(0, 29.0, z - 0.2), Vector3(0, 32.0, z - 0.2), 0.3, 0.3)
	lm.beam("Stone", Vector3(-0.9, 31.0, z - 0.2), Vector3(0.9, 31.0, z - 0.2), 0.3, 0.3)

## One west tower on an 11 m square (s: -1 left, 1 right): stone plinth,
## brick shaft with clasping corner buttresses, the portal, string
## courses, two stages of paired round-arched windows, the belfry with
## twin louvred openings on each face, the corner pinnacles, the
## eight-sided iron spire with lucarnes and the cross (60.5 m).
static func _tower(lm: LandmarkMesh, c: Vector3, s: float) -> void:
	var w := 10.5
	lm.box("Stone", c + Vector3(0, 1.0, 0), Vector3(w + 1.0, 2.0, w + 1.0))
	lm.box("Brick", c + Vector3(0, 19.0, 0), Vector3(w, 36.0, w))
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			lm.box("Brick", c + Vector3(sx * (w * 0.5 - 0.3), 17.0, sz * (w * 0.5 - 0.3)), Vector3(1.8, 34.0, 1.8))
			lm.spire("Brick", c + Vector3(sx * (w * 0.5 - 0.3), 46.4, sz * (w * 0.5 - 0.3)), 0.7, 3.2, 0.0)
	var n := Vector3(0, 0, 1)
	lm.box("Dark", c + Vector3(0, 3.0, w * 0.5 + 0.06), Vector3(2.4, 4.0, 0.1), Basis(), 0.0)
	LandmarkDetail.arch(lm, "Stone", c + Vector3(0, 5.0, w * 0.5), n, 2.4)
	for y in [8.0, 18.0, 28.0, 37.2]:
		lm.box("Stone", c + Vector3(0, y, 0), Vector3(w + 0.8, 0.5, w + 0.8))
	for side in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * float(side))
		var fn: Vector3 = b * Vector3(0, 0, 1)
		var skip := side == 2 or (side == 1 and s < 0.0) or (side == 3 and s > 0.0)
		for x in [-1.8, 1.8]:
			if not skip:
				LandmarkDetail.window(lm, "Stone", "Glass", c + b * Vector3(x, 22.0, w * 0.5 + 0.02), fn, 1.0, 3.6, true, 0.15)
			LandmarkDetail.window(lm, "Stone", "Glass", c + b * Vector3(x, 31.6, w * 0.5 + 0.02), fn, 1.0, 3.6, true, 0.15)
		if side == 0:
			LandmarkDetail.window(lm, "Stone", "Glass", c + b * Vector3(0, 12.4, w * 0.5 + 0.02), fn, 1.4, 4.0, true, 0.2)
	# Belfry.
	lm.box("Brick", c + Vector3(0, 42.0, 0), Vector3(w - 1.0, 9.0, w - 1.0))
	for side in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * float(side))
		var fn: Vector3 = b * Vector3(0, 0, 1)
		for x in [-2.0, 2.0]:
			lm.box("Dark", c + b * Vector3(x, 41.2, (w - 1.0) * 0.5 + 0.04), Vector3(1.8, 5.0, 0.1), b, 0.0)
			for k in 5:
				lm.box("Brick", c + b * Vector3(x, 39.4 + 0.8 * float(k), (w - 1.0) * 0.5 + 0.1),
					Vector3(1.7, 0.12, 0.2), b, 0.0)
			LandmarkDetail.arch(lm, "Stone", c + b * Vector3(x, 43.7, (w - 1.0) * 0.5), fn, 1.8, 0.3, 0.25)
	lm.box("Stone", c + Vector3(0, 46.7, 0), Vector3(w + 0.4, 0.6, w + 0.4))
	# Iron spire: eight-sided, with a lucarne on each cardinal face.
	var sb := c + Vector3(0, 47.0, 0)
	var sh := TOP_M - 3.5 - sb.y
	lm.spire("Steel", sb, 4.2, sh, 0.12, 8)
	for side in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * float(side))
		lm.box("Steel", sb + b * Vector3(0, 1.6, 3.4), Vector3(1.2, 2.0, 1.0), b)
		lm.gable("Steel", sb + b * Vector3(0, 2.6, 3.4), 1.3, 1.1, 0.8, b, 0.1)
	var top := sb + Vector3(0, sh, 0)
	lm.lathe("Steel", top - Vector3(0, 0.2, 0), PackedVector2Array([Vector2(0.3, 0), Vector2(0.45, 0.3),
		Vector2(0.15, 0.6)]), 8)
	lm.beam("Steel", top, top + Vector3(0, 3.5, 0), 0.25, 0.25)
	lm.beam("Steel", top + Vector3(-1.0, 2.5, 0), top + Vector3(1.0, 2.5, 0), 0.22, 0.22)
