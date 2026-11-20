extends RefCounted

## The German Church (Saksalainen kirkko, Bernhardinkatu 4; Gothic Revival,
## 1864), Kaartinkaupunki. Front +Z is the west end with the tower; the
## registry yaw (87) turns +Z onto the west and the apse onto the east, as in
## OSM way 22498190.
##
## From the Commons photos in visual-plan/refs/landmarks/german_church_helsinki/:
## - orange-red machine-made brick with lighter brick bands, and
##   weathered pale-green copper roofs (the church is red and green, not
##   white): the nave's steep gabled copper roof, a lower lean-to aisle
##   roof, and a polygonal apse with a conical copper roof;
## - the square west tower: a tall brick shaft with paired lancet belfry
##   openings under a corbel band, four steep brick gablets with copper
##   roofs crossing over its top, a copper pyramid, and a slender copper
##   spire with a small louvre stage and a finial cross;
## - a smaller stair turret on the tower's corner with its own thin spire;
## - on the long side a gabled bay (the transept) with a crow-stepped
##   corbel edge, a rose of three small lancets over two tall ones;
## - a low red-brick annex with a dark roof and tall narrow windows, and
##   brick garden walls round the courtyard.
##
## Measured: position and axis from OSM way 22498190 (a 20.6 x 27.2 m
## outline that includes the annexes; the nave itself is an estimate of
## 11 x 21 m). Heights are estimated from the photos against the registry
## 52 m: nave eaves 8.5 m, ridge 14 m, tower shaft 25 m, spire tip 54 m. LoD2
## could not be read in this run.

const U = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")
const P = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_parts.gd")

const ENTRY := {"type": "german_church_helsinki", "name": "German Church, Helsinki", "lat": 60.163314, "lon": 24.952022,
	"radius_m": 1500.0, "wiki_title": "German Church, Helsinki", "height_m": 54.0, "clear_m": 22.0,
	"yaw_deg": 87.0, "kind": "Church", "aliases": ["german church, helsinki", "saksalainen kirkko", "tyska kyrkan helsingfors"]}

const NAVE_HW := 5.5
const Z_APSE := -13.6
const Z_NAVE0 := -10.6
const Z_NAVE1 := 8.0
const EAVE := 8.5
const RIDGE := 5.5
const TOWER_HW := 4.0
const TOWER_Z0 := 5.6
const TOWER_Z1 := 13.6
const SHAFT := 25.0

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#A64B2F", 2.5))
	lm.use("Trim", LandmarkMaterials.pbr("brick", "#C69673", 2.5))
	lm.use("Copper", LandmarkMaterials.paint("#79A691", 0.5, 0.45))
	lm.use("Glass", LandmarkMaterials.glass("#2A3236"))
	lm.use("Dark", LandmarkMaterials.paint("#3B3F42", 0.6, 0.3))
	_nave(lm)
	_tower(lm)
	_transept(lm)
	_annex(lm)
	lm.commit(model)
	# Night: the brick tower and the copper spire are lit from the forecourt.
	var warm := Color(1.0, 0.94, 0.82)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-6.0, 1.0, 22.0), Vector3(0.0, 14.0, TOWER_Z1), 18.0, 1.0, 70.0, warm],
		[Vector3(6.0, 1.0, 22.0), Vector3(0.0, 14.0, TOWER_Z1), 18.0, 1.0, 70.0, warm],
		[Vector3(0.0, 1.0, 24.0), Vector3(0.0, 34.0, 9.0), 9.0, 0.9, 90.0, Color(0.85, 1.0, 0.92)],
	])

## Nave with its copper roof, lancets and buttresses, the lean-to aisle and
## the apse.
static func _nave(lm: LandmarkMesh) -> void:
	var ln := Z_NAVE1 - Z_NAVE0
	var cz := (Z_NAVE0 + Z_NAVE1) * 0.5
	U.blk(lm, "Brick", 0.0, 0.0, cz, NAVE_HW * 2.0, EAVE, ln)
	U.blk(lm, "Trim", 0.0, 0.0, cz, NAVE_HW * 2.0 + 0.3, 0.6, ln + 0.3)
	U.ridge_z(lm, "Copper", "Brick", Vector3(0, EAVE, cz), NAVE_HW * 2.0, ln, RIDGE, 0.5)
	# Lean-to aisle on the south (-X) side.
	U.blk(lm, "Brick", -NAVE_HW - 1.4, 0.0, -2.5, 2.8, 5.2, 12.0)
	var wx := -NAVE_HW
	var n_out := Vector3(-0.287, 0.958, 0.0)
	lm.quad("Copper", Vector3(wx, 6.2, 3.5), Vector3(wx, 6.2, -8.5), Vector3(wx - 3.2, 5.2, -8.5), Vector3(wx - 3.2, 5.2, 3.5), n_out)
	# Lancets down the north (+X) flank, buttress strips between.
	for k in 4:
		var z := -8.0 + float(k) * 4.0
		if z > -6.0 and z < 4.0:
			continue
		P.lancet(lm, "Trim", "Glass", Vector3(NAVE_HW, 2.0, z), Vector3(1, 0, 0), 1.3, 5.4)
		lm.box("Trim", Vector3(NAVE_HW + 0.15, 3.5, z + 2.0), Vector3(0.4, 7.0, 0.5))
	for k in 5:
		var z := -8.5 + float(k) * 3.2
		P.lancet(lm, "Trim", "Glass", Vector3(-NAVE_HW - 2.8, 1.2, z), Vector3(-1, 0, 0), 1.0, 3.3)
	# Polygonal apse with a conical roof.
	lm.frustum("Brick", Vector3(0, 0, Z_NAVE0), 4.3, 4.3, 7.0, 6, PI / 6.0)
	lm.lathe("Copper", Vector3(0, 7.0, Z_NAVE0), PackedVector2Array([Vector2(4.9, 0), Vector2(0.3, 4.2), Vector2(0, 4.5)]), 6, 1.0, 1.0, PI / 6.0, false)
	for k in 3:
		var a := PI + deg_to_rad(-50.0 + 50.0 * float(k))
		P.lancet(lm, "Trim", "Glass", Vector3(0, 1.6, Z_NAVE0) + Vector3(sin(a), 0, cos(a)) * 3.75, Vector3(sin(a), 0, cos(a)), 1.1, 4.4)

## The west tower: shaft, belfry gables, pyramid and spire, with the stair
## turret.
static func _tower(lm: LandmarkMesh) -> void:
	var cz := (TOWER_Z0 + TOWER_Z1) * 0.5
	var w := TOWER_HW * 2.0
	var d := TOWER_Z1 - TOWER_Z0
	U.blk(lm, "Trim", 0.0, 0.0, cz, w + 0.4, 0.9, d + 0.4)
	U.blk(lm, "Brick", 0.0, 0.9, cz, w, SHAFT - 0.9, d)
	for y: float in [9.0, 18.5]:
		lm.box("Trim", Vector3(0, y, cz), Vector3(w + 0.5, 0.3, d + 0.5))
	lm.box("Trim", Vector3(0, SHAFT - 0.2, cz), Vector3(w + 0.8, 0.5, d + 0.8))
	# Front portal and window over it; lancet pairs in the belfry zone.
	P.lancet(lm, "Trim", "Glass", Vector3(0, 1.0, TOWER_Z1), Vector3(0, 0, 1), 2.4, 5.6, 0.5)
	P.lancet(lm, "Trim", "Glass", Vector3(0, 10.5, TOWER_Z1), Vector3(0, 0, 1), 1.5, 5.0)
	for dx: float in [-1.4, 1.4]:
		P.lancet(lm, "Trim", "Glass", Vector3(dx, 19.5, TOWER_Z1), Vector3(0, 0, 1), 0.8, 4.4, 0.2, false)
		P.lancet(lm, "Trim", "Glass", Vector3(TOWER_HW, 19.5, cz + dx), Vector3(1, 0, 0), 0.8, 4.4, 0.2, false)
		P.lancet(lm, "Trim", "Glass", Vector3(-TOWER_HW, 19.5, cz + dx), Vector3(-1, 0, 0), 0.8, 4.4, 0.2, false)
	# Four gablets crossing over the shaft, copper-roofed.
	U.ridge_z(lm, "Copper", "Brick", Vector3(0, SHAFT, cz), w, d, 5.5, 0.3)
	U.ridge_x(lm, "Copper", "Brick", Vector3(0, SHAFT, cz), w, d, 5.5, 0.3)
	# Copper pyramid rising out of the crossing, then the spire.
	U.hip(lm, "Copper", Vector3(0, SHAFT + 1.0, cz), 6.4, 6.4, 10.5, 0.3)
	var base := Vector3(0, SHAFT + 11.5, cz)
	lm.frustum("Copper", base, 1.4, 1.1, 1.8, 8, PI / 8.0)
	lm.spire("Copper", base + Vector3(0, 1.8, 0), 1.1, 15.5, 0.0, 8)
	lm.box("Copper", base + Vector3(0, 17.7, 0), Vector3(0.12, 1.1, 0.12))
	lm.box("Copper", base + Vector3(0, 18.0, 0), Vector3(0.6, 0.12, 0.12))
	# Stair turret on the south-east corner with a thin spire.
	var tc := Vector3(-TOWER_HW - 0.2, 0.0, TOWER_Z0 + 0.3)
	U.blk(lm, "Brick", tc.x, 0.0, tc.z, 1.8, 17.0, 1.8)
	lm.spire("Copper", tc + Vector3(0, 17.0, 0), 1.05, 9.5, 0.0, 4)

## The gabled bay on the north (+X) side of the nave with its lancets.
static func _transept(lm: LandmarkMesh) -> void:
	var x0 := NAVE_HW
	var x1 := 9.0
	var cz := -0.8
	var d := 8.0
	U.blk(lm, "Brick", (x0 + x1) * 0.5, 0.0, cz, x1 - x0, EAVE, d)
	U.ridge_x(lm, "Copper", "Brick", Vector3((x0 + x1) * 0.5, EAVE, cz), x1 - x0 + 0.5, d, 4.8, 0.4)
	# Stepped corbel edge on the gable end and the lancets on its face.
	P.crow_gable(lm, "Trim", "Trim", Vector3(x1 + 0.05, 0, cz), Vector3(1, 0, 0), d - 0.4, EAVE, 4.0, 4, 0.2)
	P.lancet_row(lm, "Trim", "Glass", Vector3(x1, 0, cz - 2.6), Vector3(x1, 0, cz + 2.6), Vector3(1, 0, 0), 1.6, 2, 1.4, 5.6)
	for k in 3:
		P.lancet(lm, "Trim", "Glass", Vector3(x1, EAVE + 0.4 + 0.2 * float(k % 2), cz - 1.6 + 1.6 * float(k)), Vector3(1, 0, 0), 0.7, 2.0, 0.2, false)

## The low brick annex and the garden walls.
static func _annex(lm: LandmarkMesh) -> void:
	U.blk(lm, "Brick", 8.0, 0.0, -10.0, 5.6, 4.8, 8.6)
	U.hip(lm, "Dark", Vector3(8.0, 4.8, -10.0), 6.4, 9.4, 1.8, 0.2)
	for z: float in [-12.5, -10.0, -7.5]:
		P.win_row(lm, "Trim", "Glass", Vector3(10.8, 0, z), Vector3(10.8, 0, z), Vector3(1, 0, 0), 1.0, 1, 0.9, 2.8, false, 0.12)
	U.blk(lm, "Brick", 8.0, 0.0, 6.5, 0.6, 2.6, 6.0)
	U.blk(lm, "Brick", -9.0, 0.0, 9.0, 0.6, 2.4, 10.0)
