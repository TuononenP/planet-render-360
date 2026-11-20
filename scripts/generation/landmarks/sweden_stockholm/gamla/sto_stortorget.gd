extends RefCounted

## Stortorget, the old market square of Gamla stan, authored as a square in
## the manner of landmark_ft_kauppatori.gd: the cobbled floor, the row of
## gabled merchant houses on its west side, Börshuset on the north side and
## the old well (Stortorgsbrunnen) near the south-west corner.
##
## Frame: origin on the mapped square (OSM way 332635708, centroid 59.325020,
## 18.070806), registry yaw -18.1 so +X runs along the long axis (bearing
## 71.9, east-north-east) and +Z is south-south-east. The square lies at
## x -25.9..32.7, z -15.6..19.2 (58.6 x 35 m). y = 0.3 is the pavement.
##
## West row (x = -27.3, facing +X onto the square; from the photos in
## visual-plan/refs/landmarks/stortorget_stockholm/, south to north):
## - A (z 10..20): 4-storey red-brown plaster, white trim, dark mansard roof
##   with two dormers (OSM 1097711779).
## - B (Schantzska huset, no. 20, z 1..10): dark green-grey plaster with
##   white surrounds, a shaped baroque gable with a round window, copper roof.
## - C (Seyfridtzska huset, no. 18, z -6..1): the 5-storey red house, three
##   bays, grey-green sashes, a stepped gable (trappgavel) topped by a gilt
##   finial; the tallest house of the row (25 m).
## - D (z -15..-6): ochre-orange plaster, shaped gable with an oculus.
## - E (z -23..-15): yellow plaster under a dark mansard with dormers.
## - F (z -33..-23): salmon plaster under a hipped green copper roof.
## Each house runs back to its mapped footprint depth (10 to 34 m).
## Börshuset is built by sto_borshuset.gd. The square is paved in bluish
## granite setts; the well is a dark stone drum with a stepped shaft, four
## small urns and a large urn on top; dark benches, lamps and a flower tub.
## The five gabled houses of Kindstugatan one block west (OSM 1097711831-36)
## are not rebuilt.

const K = preload("res://scripts/generation/landmarks/sweden_stockholm/gamla/sto_gamla_kit.gd")
const Bors = preload("res://scripts/generation/landmarks/sweden_stockholm/gamla/sto_borshuset.gd")

const FRONT_X := -27.6
const G := 0.3
## Outline of the mapped square in the model frame (metres).
const SQUARE := [Vector2(31.1, -13.1), Vector2(-23.9, -15.6), Vector2(-25.9, -15.6), Vector2(-25.9, -6.6),
	Vector2(-25.9, 9.8), Vector2(-25.5, 19.2), Vector2(-24.2, 19.1), Vector2(13.6, 12.2), Vector2(25.6, 12.0),
	Vector2(28.9, 0.0), Vector2(32.7, -13.0)]
const WELL := Vector3(-19.0, G, 9.0)

static func materials() -> Dictionary:
	return {
		"Brick": LandmarkMaterials.pbr("render", "#93503F", 3.0),
		"Red": LandmarkMaterials.pbr("render", "#CC5A3C", 3.0),
		"Orange": LandmarkMaterials.pbr("render", "#E0A060", 3.0),
		"Yellow": LandmarkMaterials.pbr("render", "#E2B551", 3.0),
		"Green": LandmarkMaterials.pbr("render", "#637F70", 3.0),
		"Salmon": LandmarkMaterials.pbr("render", "#DDB08A", 3.0),
		"Pink": LandmarkMaterials.pbr("render", "#E4C8A8", 3.0),
		"Trim": LandmarkMaterials.pbr("limestone", "#E8E3D4", 2.5),
		"Slate": LandmarkMaterials.pbr("slate", "#3C4045", 2.5),
		"Copper": LandmarkMaterials.pbr("copper", "#6C9A86", 2.0, 0.55, 0.3),
		"Stone": LandmarkMaterials.pbr("stone", "#7E766A", 2.5),
		"Cobble": LandmarkMaterials.pbr("pavement", "#6C7178", 1.6),
		"Iron": LandmarkMaterials.paint("#26292A", 0.5, 0.5),
		"Gold": LandmarkMaterials.gold(),
		"Glass": LandmarkMaterials.glass("#2A3236"),
		"Lamp": LandmarkMaterials.lit("#FFE0A0", 1.2),
	}

static func build(model: Node3D) -> void:
	var mats := materials()
	var lm := K.fresh(mats)
	_floor(lm)
	_row(lm, mats)
	Bors.build(lm, mats)
	_well(lm)
	_furniture(lm)
	lm.commit(model)
	var warm := Color(1.0, 0.86, 0.66)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-8.0, 1.5, 4.0), Vector3(-27.3, 11.0, -2.0), 52.0, 0.85, 34.0, warm],
		[Vector3(-8.0, 1.5, -10.0), Vector3(-27.3, 11.0, -18.0), 52.0, 0.8, 34.0, warm],
		[Vector3(10.0, 1.5, -6.0), Vector3(8.0, 12.0, -17.8), 50.0, 0.9, 36.0, warm],
		[Vector3(-6.0, 1.5, 12.0), Vector3(-19.0, 4.0, 9.0), 40.0, 0.7, 26.0, warm],
	])

static func _floor(lm: LandmarkMesh) -> void:
	var poly := PackedVector2Array()
	for p in SQUARE:
		poly.append(p)
	lm.poly_prism("Cobble", poly, G, G + 0.06)

# --- West row ----------------------------------------------------------

## Houses of the row: z0, z1, depth, spec, plate ("stepped", "baroque", "").
static func _houses() -> Array:
	return [
		[10.4, 20.0, 25.4, {"wall": "Brick", "eave": 16.5, "base_h": 4.0, "cols": 3, "rows": 3, "roof": "mansard",
			"rise": 5.2, "dormers": 2, "chimneys": 2, "door": 1, "sides": true}, ""],
		[0.8, 10.4, 13.1, {"wall": "Green", "eave": 17.0, "base_h": 4.0, "cols": 3, "rows": 3, "roof": "gable",
			"rise": 5.0, "roof_key": "Copper", "door": 1}, "baroque"],
		[-5.8, 0.8, 10.2, {"wall": "Red", "eave": 18.0, "base_h": 4.2, "cols": 3, "rows": 4, "storey": 3.4,
			"win": Vector2(1.3, 1.9), "roof": "gable", "rise": 5.5, "door": 1}, "stepped"],
		[-14.8, -5.9, 31.2, {"wall": "Orange", "eave": 17.0, "base_h": 4.2, "cols": 2, "rows": 3,
			"win": Vector2(1.5, 2.0), "roof": "gable", "rise": 5.0, "door": 0}, "baroque"],
		[-22.9, -14.8, 32.4, {"wall": "Yellow", "eave": 16.5, "base_h": 4.0, "cols": 3, "rows": 3, "roof": "mansard",
			"rise": 5.4, "dormers": 2, "chimneys": 2, "door": 1}, ""],
		[-32.6, -22.9, 33.6, {"wall": "Salmon", "eave": 16.0, "base_h": 3.8, "cols": 3, "rows": 3, "roof": "hip",
			"rise": 5.0, "roof_key": "Copper", "chimneys": 2, "door": 1, "sides": true}, ""],
	]

static func _row(lm: LandmarkMesh, mats: Dictionary) -> void:
	for h in _houses():
		var z0: float = h[0]
		var z1: float = h[1]
		var spec: Dictionary = (h[3] as Dictionary).duplicate()
		spec["w"] = z1 - z0
		spec["d"] = h[2]
		var part := K.house(mats, spec)
		var plate: String = h[4]
		var wall: String = spec["wall"]
		if plate != "":
			_gable(part, mats, spec, plate, wall)
		K.place(lm, part, Vector3(FRONT_X, 0.0, (z0 + z1) * 0.5), PI * 0.5)

## The shaped front gable over the eave: baroque (ogee crown with an oculus
## and a window) or stepped (a window, an oculus and a gilt finial).
static func _gable(part: LandmarkMesh, mats: Dictionary, spec: Dictionary, kind: String, wall: String) -> void:
	var hw: float = float(spec["w"]) * 0.5
	var y0: float = float(spec["eave"]) + 0.15
	var zf := K.SKIN
	if kind == "stepped":
		var h := 7.0
		K.gable_plate(part, mats, wall, K.stepped_profile(hw, h), y0, zf, 0.6)
		var win := K.flat_window(mats, "Trim", 1.0, 1.5)
		K.window_rows(part, win, Vector3(-0.1, 0, zf), Vector3(0.1, 0, zf), Vector3(0, 0, 1), y0 + 1.1, 1, 1, 1.0)
		K.window_rows(part, win, Vector3(-hw * 0.5, 0, zf), Vector3(-hw * 0.5 + 0.2, 0, zf), Vector3(0, 0, 1),
			y0 + 0.4, 1, 1, 1.0)
		K.window_rows(part, win, Vector3(hw * 0.5, 0, zf), Vector3(hw * 0.5 + 0.2, 0, zf), Vector3(0, 0, 1),
			y0 + 0.4, 1, 1, 1.0)
		K.oculus(part, "Trim", Vector3(0, y0 + 4.9, zf), 0.4)
		# Stone coping along the steps, a gilt finial on top.
		part.lathe("Gold", Vector3(0, y0 + h, 0.0), PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.3, 0.1),
			Vector2(0.34, 0.42), Vector2(0.2, 0.7), Vector2(0.0, 0.76)]), 10)
		part.frustum("Gold", Vector3(0, y0 + h + 0.74, 0.0), 0.07, 0.015, 0.9, 6)
	else:
		var h := 5.8
		K.gable_plate(part, mats, wall, K.baroque_profile(hw, h), y0, zf, 0.6)
		K.oculus(part, "Trim", Vector3(0, y0 + h * 0.62, zf), 0.62)
		var win := K.flat_window(mats, "Trim", 1.1, 1.6)
		K.window_rows(part, win, Vector3(-0.1, 0, zf), Vector3(0.1, 0, zf), Vector3(0, 0, 1), y0 + 0.5, 1, 1, 1.0)

# --- Well, benches, lamps ----------------------------------------------

## Stortorgsbrunnen: a dark stone drum on a stepped plinth with a shaft,
## niches with lion spouts, four small urns and a large urn on top.
static func _well(lm: LandmarkMesh) -> void:
	lm.lathe("Stone", WELL, PackedVector2Array([Vector2(2.7, 0.0), Vector2(2.7, 0.35), Vector2(2.3, 0.45),
		Vector2(2.3, 0.9), Vector2(2.1, 1.0), Vector2(2.1, 2.6), Vector2(1.8, 2.7), Vector2(1.8, 3.3),
		Vector2(1.3, 3.45), Vector2(1.3, 4.1), Vector2(0.9, 4.25), Vector2(0.9, 4.9), Vector2(0.0, 4.9)]), 12)
	for i in 4:
		var a := TAU * (float(i) + 0.5) / 4.0
		var d := Vector3(cos(a), 0, sin(a))
		K.Pal.urn(lm, "Stone", WELL + d * 1.55 + Vector3(0, 3.45, 0), 1.1)
		lm.box("Stone", WELL + d * 2.1 + Vector3(0, 1.5, 0), Vector3(0.5, 0.7, 0.5), Basis(Vector3.UP, -a), 0.0)
	K.Pal.urn(lm, "Stone", WELL + Vector3(0, 4.9, 0), 1.9)
	# Cast-iron bollard ring round the plinth.
	for i in 8:
		var a := TAU * float(i) / 8.0
		lm.frustum("Stone", WELL + Vector3(cos(a), 0, sin(a)) * 3.5, 0.24, 0.2, 0.85, 8)

static func _furniture(lm: LandmarkMesh) -> void:
	# Long dark benches facing the houses.
	for b in [Vector2(-8.0, -9.0), Vector2(-8.0, -2.0), Vector2(-8.0, 5.0), Vector2(-1.0, -5.0),
			Vector2(-1.0, 3.0), Vector2(6.0, -1.0)]:
		var bx: float = b.x
		var bz: float = b.y
		lm.box("Iron", Vector3(bx, G + 0.45, bz), Vector3(0.5, 0.07, 3.6), Basis(), 0.0)
		lm.box("Iron", Vector3(bx + 0.28, G + 0.85, bz), Vector3(0.07, 0.55, 3.6), Basis(), 0.0)
		for s in [-1.4, 1.4]:
			lm.box("Iron", Vector3(bx, G + 0.22, bz + float(s)), Vector3(0.4, 0.44, 0.07), Basis(), 0.0)
	# Lamp standards.
	for l in [Vector2(-25.0, -12.0), Vector2(-25.0, 4.0), Vector2(-24.0, 16.0), Vector2(20.0, 10.0),
			Vector2(-18.0, -15.0), Vector2(28.0, -10.0)]:
		var p := Vector3(l.x, G, l.y)
		lm.frustum("Iron", p, 0.12, 0.07, 4.4, 6)
		lm.box("Lamp", p + Vector3(0, 4.7, 0), Vector3(0.32, 0.5, 0.32), Basis(), 0.0)
		lm.spire("Iron", p + Vector3(0, 4.95, 0), 0.26, 0.28)
	# Flower tub and a small kiosk on the east side.
	lm.frustum("Stone", Vector3(-14.0, G, 12.0), 0.6, 0.5, 0.6, 10)
	K.Pal.rb(lm, "Trim", 12.0, 15.0, G, G + 2.3, 8.5, 10.5, 0.0)
	lm.gable("Slate", Vector3(13.5, G + 2.3, 9.5), 2.4, 3.2, 0.7, Basis(Vector3.UP, PI * 0.5), 0.2, "Trim")
