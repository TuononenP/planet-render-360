class_name StoOuterKb
extends RefCounted

## Kungliga biblioteket, the National Library of Sweden (Gustaf Dahl, 1878),
## Humlegarden. Origin at the OSM footprint centroid (way 15803083), long axis
## local X, front +Z. The registry yaw (21.8) turns local +X onto bearing
## 111.8 and the front (+Z) onto bearing 201.8, facing the park.
##
## Footprint from the OSM way, in the model frame: the main range x -54.4..54.4,
## z -11.7..9.3 (21 m deep); the wide central projection x -41.4..41.4 out to
## z 15.3; a narrow rear annex x -2.5..3 back to z -44.3.
##
## From the photos (front, quarter, aerial in visual-plan/refs/landmarks/
## kungliga_biblioteket/; they show a pale yellow plastered Italianate block
## with low dark roofs, not the green copper the brief assumed):
## - Two storeys over a granite base: a rusticated ground storey (to 7.2 m)
##   with small windows, and a tall upper storey (7.2-16 m) of big
##   mullioned windows, a pilaster between each pair, a string course
##   between the storeys and a dentilled cornice at 16 m.
## - The central projection has 19 bays (4.36 m each); each wing three. Its
##   middle rises in an attic block (26 m wide, to 19.5 m) with a red-painted
##   panel (KONGL. BIBLIOTEKET) between two grey-green coats of arms.
## - The entrance is a grey stone surround (tall pilasters, lintel) with a
##   green door in the middle bay, four granite steps, lamp globes beside it.
## - Low hipped dark metal roofs, a few black roof lanterns.
## - The rear annex is a plain three-storey strip.
## Height 19.5 m is the attic cornice, scaled from the front photo against the
## 16 m storey stack (the OSM parts only give 3-4 levels, no height tags).

const K = preload("res://scripts/generation/landmarks/sweden_stockholm/palaces/sto_pal_kit.gd")

const X0 := 54.4
const XC := 41.4
const Z_BACK := -11.7
const Z_WING := 9.3
const Z_FRONT := 15.3
const GROUND := 7.2
const CORN := 16.0
const ATTIC := 19.5
const SKIN := 0.35
const BAYS := 19

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Plaster", LandmarkMaterials.pbr("render", "#E1CE9C", 3.0))
	lm.use("Rust", LandmarkMaterials.pbr("render", "#D5BF8B", 2.4))
	lm.use("Trim", LandmarkMaterials.pbr("render", "#E9DCB4", 2.4))
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#9C9993", 2.4))
	lm.use("Glass", LandmarkMaterials.glass("#2C343B"))
	lm.use("Frame", LandmarkMaterials.paint("#34302B", 0.5, 0.3))
	lm.use("Roof", LandmarkMaterials.pbr("sheet_metal", "#3B3C3F", 3.0, 0.6, 0.4))
	lm.use("Door", LandmarkMaterials.pbr("wood", "#2F5A4A", 2.0))
	lm.use("Panel", LandmarkMaterials.pbr("render", "#BF6A5C", 2.4))
	lm.use("Arms", LandmarkMaterials.paint("#7F9690", 0.55, 0.3))
	lm.use("Lamp", LandmarkMaterials.lit("#FFF1D6", 0.8))
	lm.use("Path", LandmarkMaterials.pbr("gravel", "#A89F8E", 3.0))
	_masses(lm)
	_front(lm)
	_flanks(lm)
	_attic(lm)
	_entrance(lm)
	_roofs(lm)
	_annex(lm)
	_lamps(lm)
	lm.commit(model)
	# Night: the front is washed from the park.
	var warm := Color(1.0, 0.86, 0.66)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-30.0, 1.5, 34.0), Vector3(-18.0, 9.0, 15.0), 42.0, 0.9, 58.0, warm],
		[Vector3(30.0, 1.5, 34.0), Vector3(18.0, 9.0, 15.0), 42.0, 0.9, 58.0, warm],
		[Vector3(0.0, 1.5, 36.0), Vector3(0.0, 12.0, 15.0), 36.0, 0.9, 60.0, warm]])

# --- Masses --------------------------------------------------------------

static func _masses(lm: LandmarkMesh) -> void:
	K.rb(lm, "Plaster", -X0, X0, 0.0, CORN, Z_BACK, Z_WING, 0.0)
	K.rb(lm, "Plaster", -XC, XC, 0.0, CORN, Z_WING, Z_FRONT, 0.0)
	# Granite base and the string course between the storeys.
	K.rb(lm, "Stone", -X0 - 0.3, X0 + 0.3, 0.0, 1.2, Z_BACK - 0.3, Z_WING + 0.3, 0.0)
	K.rb(lm, "Stone", -XC - 0.3, XC + 0.3, 0.0, 1.2, Z_WING, Z_FRONT + SKIN + 0.3, 0.0)

# --- Facades ---------------------------------------------------------------

## Both storeys of one wall run: `cols` bays across `w`, ground storey of
## small windows, upper storey of tall windows with pilasters between.
static func _bands(lm: LandmarkMesh, origin: Vector3, right: Vector3, out: Vector3, w: float, cols: int) -> void:
	LandmarkDetail.pierced_face(lm, "Rust", "Glass", origin, right, out, w, GROUND, cols, 1,
		Vector2(1.6, 3.2), 2.5, 9.0, SKIN)
	LandmarkDetail.pierced_face(lm, "Plaster", "Glass", origin + Vector3(0, GROUND, 0), right, out, w,
		CORN - GROUND, cols, 1, Vector2(2.2, 5.2), 1.7, 9.0, SKIN)
	var pitch := w / float(cols)
	var basis := Basis(right, Vector3.UP, out)
	for i in cols + 1:
		var c := origin + right * (pitch * float(i)) + Vector3(0, GROUND + 4.2, 0) + out * (SKIN + 0.1)
		lm.box("Trim", c, Vector3(0.6, 8.0, 0.25), basis, 0.0)
	# String course and the dentilled cornice.
	lm.box("Trim", origin + right * (w * 0.5) + Vector3(0, GROUND, 0) + out * (SKIN + 0.08),
		Vector3(w + 0.2, 0.4, 0.3), basis, 0.0)
	var a := origin + Vector3(0, CORN - 0.2, 0) + out * (SKIN - 0.05)
	LandmarkDetail.cornice(lm, "Trim", a, a + right * w, out, 1.0, true)

static func _front(lm: LandmarkMesh) -> void:
	var r := Vector3(1, 0, 0)
	var n := Vector3(0, 0, 1)
	_bands(lm, Vector3(-XC, 0, Z_FRONT), r, n, 2.0 * XC, BAYS)
	_bands(lm, Vector3(XC, 0, Z_WING), r, n, X0 - XC, 3)
	_bands(lm, Vector3(-X0, 0, Z_WING), r, n, X0 - XC, 3)

static func _flanks(lm: LandmarkMesh) -> void:
	# End walls of the main range, the sides of the projection and the rear.
	for s in [-1.0, 1.0]:
		var sg: float = s
		var out := Vector3(sg, 0, 0)
		var right := K.right(out)
		_bands(lm, Vector3(sg * X0, 0, Z_WING if sg > 0.0 else Z_BACK), right, out, Z_WING - Z_BACK, 5)
		_bands(lm, Vector3(sg * XC, 0, Z_FRONT if sg > 0.0 else Z_WING), right, out, Z_FRONT - Z_WING, 1)
	var out_b := Vector3(0, 0, -1)
	_bands(lm, Vector3(X0, 0, Z_BACK), K.right(out_b), out_b, 2.0 * X0, 25)

# --- Attic and entrance -----------------------------------------------------

static func _attic(lm: LandmarkMesh) -> void:
	var zf := Z_FRONT + SKIN
	K.rb(lm, "Plaster", -13.1, 13.1, CORN, ATTIC - 0.9, 4.0, zf, 0.0)
	var a := Vector3(-13.1, ATTIC - 1.0, zf)
	LandmarkDetail.cornice(lm, "Trim", a, a + Vector3(26.2, 0, 0), Vector3(0, 0, 1), 1.0, true)
	for s in [-1.0, 1.0]:
		var sg: float = s
		LandmarkDetail.cornice(lm, "Trim", Vector3(sg * 13.1, ATTIC - 1.0, zf), Vector3(sg * 13.1, ATTIC - 1.0, 4.0),
			Vector3(sg, 0, 0), 1.0, false)
		# Coat of arms between pilaster strips.
		K.rb(lm, "Arms", sg * 11.4 - 0.9, sg * 11.4 + 0.9, CORN + 0.5, CORN + 2.5, zf, zf + 0.2, 0.0)
		K.rb(lm, "Trim", sg * 13.1 - 0.5, sg * 13.1 + 0.5, CORN, ATTIC - 0.9, zf, zf + 0.2, 0.0)
	K.rb(lm, "Panel", -8.4, 8.4, CORN + 0.4, CORN + 2.2, zf, zf + 0.12, 0.0)
	K.rb(lm, "Trim", -8.7, 8.7, CORN + 0.3, CORN + 0.45, zf, zf + 0.18, 0.0)
	K.rb(lm, "Trim", -8.7, 8.7, CORN + 2.2, CORN + 2.35, zf, zf + 0.18, 0.0)

## Grey stone surround, green door, granite steps in the middle bay.
static func _entrance(lm: LandmarkMesh) -> void:
	var zf := Z_FRONT + SKIN
	for s in [-1.0, 1.0]:
		var sg: float = s
		K.rb(lm, "Stone", sg * 1.9 - 0.45, sg * 1.9 + 0.45, 0.0, 6.2, zf, zf + 0.55, 0.0)
	K.rb(lm, "Stone", -2.4, 2.4, 6.2, 6.9, zf, zf + 0.65, 0.0)
	K.rb(lm, "Stone", -1.4, 1.4, 6.9, 7.5, zf, zf + 0.45, 0.0)
	K.rb(lm, "Door", -1.4, 1.4, 1.2, 5.8, zf, zf + 0.12, 0.0)
	K.rb(lm, "Frame", -1.4, 1.4, 5.0, 5.15, zf + 0.12, zf + 0.2, 0.0)
	for k in 4:
		K.rb(lm, "Stone", -3.4 - 0.2 * float(k), 3.4 + 0.2 * float(k), 0.0, 0.3 * float(4 - k),
			zf, zf + 0.5 + 0.4 * float(k + 1), 0.0)
	K.rb(lm, "Path", -3.0, 3.0, 0.0, 0.05, zf + 2.2, zf + 22.0, 0.0)

# --- Roofs ---------------------------------------------------------------------

static func _roofs(lm: LandmarkMesh) -> void:
	var cz := (Z_BACK + Z_FRONT) * 0.5
	LandmarkFhUtil.hip(lm, "Roof", Vector3(0, CORN - 0.1, cz), 2.0 * XC + 0.8, Z_FRONT - Z_BACK + 0.8, 2.9, 0.7)
	for s in [-1.0, 1.0]:
		var sg: float = s
		var cx: float = sg * (XC + X0) * 0.5
		var wz := (Z_BACK + Z_WING) * 0.5
		LandmarkFhUtil.hip(lm, "Roof", Vector3(cx, CORN - 0.1, wz), X0 - XC + 0.8, Z_WING - Z_BACK + 0.8, 2.4, 0.6)
	# Black roof lanterns.
	for p in [Vector2(-30.0, 2.0), Vector2(-10.0, -4.0), Vector2(18.0, 3.0), Vector2(32.0, -5.0)]:
		K.rb(lm, "Frame", p.x - 0.8, p.x + 0.8, CORN + 2.4, CORN + 3.4, p.y - 0.8, p.y + 0.8, 0.0)

## The narrow rear annex: three storeys under a low hip.
static func _annex(lm: LandmarkMesh) -> void:
	var x0 := -2.5
	var x1 := 3.0
	var z0 := -44.3
	var z1 := Z_BACK
	K.rb(lm, "Plaster", x0, x1, 0.0, 12.0, z0, z1, 0.0)
	K.rb(lm, "Stone", x0 - 0.2, x1 + 0.2, 0.0, 1.0, z0 - 0.2, z1, 0.0)
	for s in [-1.0, 1.0]:
		var sg: float = s
		var out := Vector3(sg, 0, 0)
		var org := Vector3(x1 if sg > 0.0 else x0, 0, z1 if sg > 0.0 else z0)
		var right := K.right(out)
		LandmarkDetail.pierced_face(lm, "Plaster", "Glass", org, right, out, z1 - z0, 12.0, 8, 3,
			Vector2(1.4, 2.0), 1.6, 3.6, 0.3)
	var out_r := Vector3(0, 0, -1)
	LandmarkDetail.pierced_face(lm, "Plaster", "Glass", Vector3(x1, 0, z0), K.right(out_r), out_r, x1 - x0, 12.0, 2, 3,
		Vector2(1.3, 2.0), 1.6, 3.6, 0.3)
	LandmarkFhUtil.hip(lm, "Roof", Vector3((x0 + x1) * 0.5, 12.0, (z0 + z1) * 0.5), x1 - x0 + 0.9, z1 - z0 + 0.9, 1.4, 0.0)

## Globe lamps by the entrance and along the front.
static func _lamps(lm: LandmarkMesh) -> void:
	for x in [-5.5, 5.5, -22.0, 22.0]:
		var p := Vector3(float(x), 0.0, Z_FRONT + SKIN + 5.0)
		lm.beam("Frame", p, p + Vector3(0, 3.6, 0), 0.14, 0.14)
		lm.lathe("Lamp", p + Vector3(0, 3.6, 0), LandmarkFhUtil.ball(0.32), 8)
