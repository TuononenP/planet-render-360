class_name StoDjurgWaldemarsudde
extends RefCounted

## Waldemarsudde, Prince Eugen's villa on Djurgården's southern shore
## (Ferdinand Boberg, 1903-05). Origin at the centroid of OSM way 104727642,
## +X along the mapped long axis, registry yaw 1.5 (so +Z faces the water
## in the south). Footprint from the OSM outline: a main block x -17.5..8.9,
## z -7.5..12 with a north porch bay and a north-east wing x 5.9..19.6,
## z -12.9..1.5. The gallery (way 34838579, stands 56 m east, 17 m north)
## is built by StoDjurgWaldeGallery into the same model.
##
## Spec (visual-plan/refs/landmarks/waldemarsudde/; heights scaled from the
## photos, no height tag exists: approximate, flagged unverified):
## - Pale-yellow plastered walls on a low stone plinth: two storeys, eave
##   10.8 m, a cream string course between the floors and a cream cornice.
## - Main south front: five bays, tall paired-bar windows on the ground
##   floor (the three west bays rectangular, the two east bays arched
##   french windows opening to a stone terrace with a balustrade), smaller
##   windows above.
## - A mansard roof in dark patinated copper (steep lower slope with a row
##   of dormers on the south and west sides, shallow green upper slope with
##   skylights), two brick chimneys, a flagpole on the south lawn.
## - The NE wing is a one-storey-lower block under a plain hipped roof.
## There is no tower on the villa (the brief's tower is a mistake; the
## small clock tower seen behind it in photos is another building).

const X0 := -17.5
const X1 := 8.85
const Z0 := -7.5
const Z1 := 12.0
const EAVE := 10.8
const MANSARD := 4.2
const TOP := 20.0
const WING := Rect2(5.9, -12.9, 13.7, 14.4)

static func build(model: Node3D) -> void:
	var mats := {
		"Wall": LandmarkMaterials.pbr("render", "#E7D6A2", 3.0),
		"Trim": LandmarkMaterials.pbr("render", "#EFE7D0", 3.0),
		"White": LandmarkMaterials.pbr("render", "#EEEBE2", 3.0),
		"Zinc": LandmarkMaterials.pbr("sheet_metal", "#8D938E", 3.0, 0.55, 0.3),
		"Stone": LandmarkMaterials.pbr("stone", "#8A857B", 2.5),
		"Frame": LandmarkMaterials.paint("#F0EDE4"),
		"Glass": LandmarkMaterials.glass("#20282D"),
		"RoofLow": LandmarkMaterials.pbr("sheet_metal", "#5B5043", 3.0, 0.55, 0.3),
		"RoofTop": LandmarkMaterials.pbr("copper", "#7C9585", 3.0, 0.55, 0.3),
		"Brick": LandmarkMaterials.pbr("brick", "#9C6B55", 2.4),
		"Metal": LandmarkMaterials.paint("#DAD6CC"),
		"Blue": LandmarkMaterials.paint("#0B58A8", 0.7, 0.0),
		"Yellow": LandmarkMaterials.paint("#F2C515", 0.7, 0.0),
	}
	var lm := LandmarkMesh.new()
	StoChurchKit.use_all(lm, mats)
	_blocks(lm)
	_roofs(lm)
	_windows(lm, mats)
	_terrace(lm)
	StoDjurgWaldeGallery.build(lm, mats)
	lm.commit(model)
	_night(model)

static func _blocks(lm: LandmarkMesh) -> void:
	var cx := (X0 + X1) * 0.5
	var cz := (Z0 + Z1) * 0.5
	lm.box("Stone", Vector3(cx, 0.5, cz), Vector3(X1 - X0 + 0.5, 1.0, Z1 - Z0 + 0.5), Basis(), 0.0)
	LandmarkFhUtil.blk(lm, "Wall", cx, 1.0, cz, X1 - X0, EAVE - 1.0, Z1 - Z0)
	# North porch bay.
	lm.box("Stone", Vector3(-5.1, 0.5, Z0 - 0.75), Vector3(7.9, 1.0, 1.8), Basis(), 0.0)
	LandmarkFhUtil.blk(lm, "Wall", -5.1, 1.0, Z0 - 0.75, 7.6, EAVE - 1.0 - 1.5, 1.5)
	# North-east wing, a storey of roof lower.
	var wc := WING.get_center()
	lm.box("Stone", Vector3(wc.x, 0.5, wc.y), Vector3(WING.size.x + 0.5, 1.0, WING.size.y + 0.5), Basis(), 0.0)
	LandmarkFhUtil.blk(lm, "Wall", wc.x, 1.0, wc.y, WING.size.x, EAVE - 1.5, WING.size.y)
	# String courses and cornices.
	_belt(lm, cx, cz, X1 - X0, Z1 - Z0, 6.1, 0.35, 0.12)
	_belt(lm, cx, cz, X1 - X0, Z1 - Z0, EAVE - 0.5, 0.7, 0.35)
	lm.box("RoofTop", Vector3(cx, EAVE + 0.08, cz), Vector3(X1 - X0 + 1.5, 0.16, Z1 - Z0 + 1.5), Basis(), 0.0)
	_belt(lm, wc.x, wc.y, WING.size.x, WING.size.y, 6.1, 0.35, 0.12)
	_belt(lm, wc.x, wc.y, WING.size.x, WING.size.y, EAVE - 2.0, 0.7, 0.35)

static func _belt(lm: LandmarkMesh, cx: float, cz: float, w: float, d: float, y: float, h: float, out: float) -> void:
	lm.box("Trim", Vector3(cx, y + h * 0.5, cz), Vector3(w + out * 2.0, h, d + out * 2.0), Basis(), 0.0)

## Mansard on the main block; a plain hip over the wing; chimneys, skylights.
static func _roofs(lm: LandmarkMesh) -> void:
	var cx := (X0 + X1) * 0.5
	var cz := (Z0 + Z1) * 0.5
	var sx := (X1 - X0) * 0.5 + 0.35
	var sz := (Z1 - Z0) * 0.5 + 0.35
	var k := 1.4142
	lm.lathe("RoofLow", Vector3(cx, EAVE, cz), PackedVector2Array([
		Vector2(k, 0.0), Vector2(k * 0.86, MANSARD)]), 4, sx, sz, PI * 0.25, false, false)
	lm.lathe("RoofTop", Vector3(cx, EAVE + MANSARD, cz), PackedVector2Array([
		Vector2(k * 0.86, 0.0), Vector2(k * 0.5, 1.7), Vector2(0.0, 1.7)]), 4, sx, sz, PI * 0.25, false)
	# Skylights on the upper slope.
	for i in 4:
		lm.box("Glass", Vector3(cx - 7.0 + float(i) * 4.6, EAVE + MANSARD + 0.55, cz + 2.8), Vector3(1.8, 0.1, 1.2),
			Basis(Vector3.RIGHT, -0.45), 0.0)
	# Wing hip.
	var wc := WING.get_center()
	LandmarkFhUtil.hip(lm, "RoofLow", Vector3(wc.x, EAVE - 1.5, wc.y), WING.size.x + 0.9, WING.size.y + 0.9, 3.6, 0.25)
	# Chimneys on the main roof (brick, cream cap) and the wing.
	for p in [Vector2(-10.5, -2.0), Vector2(-1.0, -2.0), Vector2(13.5, -8.5)]:
		var y0 := EAVE + MANSARD + (1.2 if p.x < 10.0 else -1.4)
		var h := 2.6 if p.x < 10.0 else 3.0
		lm.box("Brick", Vector3(p.x, y0 + h * 0.5, p.y), Vector3(1.7, h, 1.3), Basis(), 0.0)
		lm.box("Trim", Vector3(p.x, y0 + h + 0.1, p.y), Vector3(2.0, 0.2, 1.6), Basis(), 0.0)

static func _windows(lm: LandmarkMesh, mats: Dictionary) -> void:
	var low := StoDjurgKit.unit(mats, 1.3, 3.5)
	var arch := StoDjurgKit.unit(mats, 1.5, 3.7, true)
	var up := StoDjurgKit.unit(mats, 1.2, 2.5)
	var dorm := StoDjurgKit.unit(mats, 0.9, 1.5)
	var sz := Vector3(0, 0, 1)
	var faces := [
		# [a, b, out, bays]: ground points along each wall face.
		[Vector3(X0, 0, Z1), Vector3(X1, 0, Z1), sz, 5],
		[Vector3(X0, 0, Z0), Vector3(X1 - 3.0, 0, Z0), -sz, 4],
		[Vector3(X0, 0, Z0), Vector3(X0, 0, Z1), Vector3.LEFT, 4],
		[Vector3(X1, 0, Z1), Vector3(X1, 0, 1.5), Vector3.RIGHT, 2],
	]
	for f in faces:
		var a: Vector3 = f[0]
		var b: Vector3 = f[1]
		var out: Vector3 = f[2]
		var n: int = f[3]
		var south: bool = out == sz
		for i in n:
			var p := a.lerp(b, (float(i) + 0.5) / float(n))
			var arched := south and i >= 3
			StoChurchKit.place(lm, arch if arched else low, Vector3(p.x, 1.7, p.z), out)
			StoChurchKit.place(lm, up, Vector3(p.x, 6.9, p.z), out)
			if south or out == Vector3.LEFT:
				_dormer(lm, dorm, p, out)
	# Wing faces.
	var wc := WING.get_center()
	var hw := WING.size.x * 0.5
	var hd := WING.size.y * 0.5
	var wf := [
		[Vector3(wc.x - hw, 0, wc.y + hd), Vector3(wc.x + hw, 0, wc.y + hd), sz, 3],
		[Vector3(wc.x - hw, 0, wc.y - hd), Vector3(wc.x + hw, 0, wc.y - hd), -sz, 3],
		[Vector3(wc.x + hw, 0, wc.y - hd), Vector3(wc.x + hw, 0, wc.y + hd), Vector3.RIGHT, 3],
	]
	for f in wf:
		var a: Vector3 = f[0]
		var b: Vector3 = f[1]
		var out: Vector3 = f[2]
		var n: int = f[3]
		for i in n:
			var p := a.lerp(b, (float(i) + 0.5) / float(n))
			StoChurchKit.place(lm, low, Vector3(p.x, 1.7, p.z), out)
			StoChurchKit.place(lm, up, Vector3(p.x, 6.2, p.z), out)

## A dormer on the steep lower slope: a small cheek box, window, hip cap.
static func _dormer(lm: LandmarkMesh, win: LandmarkMesh, p: Vector3, out: Vector3) -> void:
	var inset := 0.35 + 1.3 * 0.5
	var c := Vector3(p.x, EAVE + 1.9, p.z) - out * (inset - 0.55)
	var basis := Basis(Vector3.UP.cross(out), Vector3.UP, out)
	lm.box("Trim", c, Vector3(1.5, 2.1, 1.2), basis, 0.0)
	StoChurchKit.place(lm, win, c + out * 0.62 - Vector3(0, 0.8, 0), out)
	lm.gable("RoofLow", c + Vector3(0, 1.05, 0), 1.5, 1.2, 0.55, Basis(Vector3.UP, atan2(out.x, out.z)), 0.15, "Trim")

## Stone terrace with a balustrade on the south front.
static func _terrace(lm: LandmarkMesh) -> void:
	lm.box("Stone", Vector3(-4.3, 0.3, Z1 + 1.8), Vector3(X1 - X0 + 2.0, 0.6, 3.6), Basis(), 0.0)
	LandmarkDetail.balustrade(lm, "Trim", Vector3(X0 - 1.0, 0.6, Z1 + 3.4), Vector3(X1 + 1.0, 0.6, Z1 + 3.4), 0.9, 3.5)
	# Flagpole on the south lawn.
	lm.lathe("Metal", Vector3(-5.0, 0.0, Z1 + 7.0), PackedVector2Array([Vector2(0.14, 0.0), Vector2(0.08, TOP)]), 8)
	StoDjurgKit.flag(lm, Vector3(-4.95, 0, Z1 + 7.0), TOP - 0.2, 2.2, 1.4)

static func _night(model: Node3D) -> void:
	var warm := Color(1.0, 0.9, 0.72)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-12.0, 1.0, 22.0), Vector3(-4.0, 6.0, 12.0), 34.0, 0.9, 40.0, warm],
		[Vector3(6.0, 1.0, 22.0), Vector3(-4.0, 6.0, 12.0), 34.0, 0.9, 40.0, warm],
	])
