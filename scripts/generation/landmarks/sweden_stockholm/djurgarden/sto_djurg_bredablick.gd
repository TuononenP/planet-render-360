class_name StoDjurgBredablick
extends RefCounted

## Bredablick, the lookout tower on Skansen's hill (1890s, red brick). Origin
## at the centre of OSM way 33407172 (eight-sided, about 13 m across), the
## faces turned onto the mapped edge directions by registry yaw 13. Face k
## looks along (cos 45k, sin 45k) in (x, z): k = 0 is +X, k = 2 is +Z.
##
## Spec (visual-plan/refs/landmarks/skansen_bredablick/, scaled by the
## octagon width; the tower height 30 m is the OSM figure, the tier heights
## are read off the photos and are approximate):
## - A regular octagon in dark red brick, battered: apothem 6.5 m at the
##   foot, 5.6 m under the cornice, on a low stone plinth.
## - Three tiers separated by projecting brick string courses with a
##   saw-tooth (dentil) face. Tier 1 (to 10 m): one wide round-arched
##   window per face with a mullion and a relieving arch, a brick roundel
##   above it. Tier 2: two tall arched windows under a shared relieving
##   arch with a roundel. Tier 3: three small arched windows per face.
##   Window frames are dark green with glazing bars.
## - A heavy corbelled brick cornice (dentil row under a flared course).
## - On top a red-painted timber crown: four chimney-like corner posts with
##   pyramid caps, a railed balcony, an octagonal lantern with a window on
##   each face, a stepped hipped skirt and a plank drum under a flat top,
##   and a flagpole with the Swedish flag to 30 m.
## Lit at night by the church-style flood spots (the tower stands alone on
## its hill).

const A0 := 6.5
const BATTER := 0.036
const EAVE := 22.8
const TOP := 30.0
const TIER_Y := [10.0, 17.6]

static func _a(y: float) -> float:
	return A0 - BATTER * y

static func _r(y: float) -> float:
	return _a(y) / cos(PI / 8.0)

static func build(model: Node3D) -> void:
	var mats := {
		"Wall": LandmarkMaterials.pbr("brick", "#84402F", 2.4),
		"Trim": LandmarkMaterials.pbr("brick", "#6F3629", 2.4),
		"Stone": LandmarkMaterials.pbr("stone", "#7B746B", 2.5),
		"Frame": LandmarkMaterials.paint("#3F5E48"),
		"Glass": LandmarkMaterials.glass("#20282D"),
		"Red": LandmarkMaterials.pbr("wood", "#92403A", 2.0, 0.7),
		"Roof": LandmarkMaterials.pbr("sheet_metal", "#5B2B28", 3.0, 0.5, 0.3),
		"Metal": LandmarkMaterials.paint("#CFCBC2"),
		"Blue": LandmarkMaterials.paint("#0B58A8", 0.7, 0.0),
		"Yellow": LandmarkMaterials.paint("#F2C515", 0.7, 0.0),
	}
	var lm := LandmarkMesh.new()
	StoChurchKit.use_all(lm, mats)
	_body(lm)
	_windows(lm, mats)
	_cornice(lm)
	_crown(lm)
	lm.commit(model)
	StoChurchKit.flood(model, Vector3.ZERO, TOP, 14.0)

static func _ring(lm: LandmarkMesh, key: String, y0: float, h: float, proj: float) -> void:
	lm.frustum(key, Vector3(0, y0, 0), _r(y0) + proj * 1.0824, _r(y0 + h) + proj * 1.0824, h, 8, PI / 8.0)

## The battered octagonal shaft, the plinth and the string courses.
static func _body(lm: LandmarkMesh) -> void:
	lm.lathe("Wall", Vector3.ZERO, PackedVector2Array([Vector2(_r(0.0), 0.0), Vector2(_r(EAVE), EAVE)]),
		8, 1.0, 1.0, PI / 8.0, false)
	_ring(lm, "Stone", 0.0, 1.2, 0.18)
	_ring(lm, "Stone", 1.2, 0.2, 0.28)
	for y in TIER_Y:
		_ring(lm, "Trim", y - 0.2, 0.45, 0.2)
		_ring(lm, "Trim", y + 0.25, 0.25, 0.1)
	# Brick corbel table under the cornice.
	_ring(lm, "Trim", 20.9, 0.3, 0.12)

static func _roundel(lm: LandmarkMesh, k: int, y: float, r: float) -> void:
	var a := float(k) * PI / 4.0
	var n := Vector3(cos(a), 0, sin(a))
	var c := n * (_a(y) + 0.06) + Vector3(0, y, 0)
	lm.disc("Trim", c, n, r, 16)
	lm.disc("Wall", c + n * 0.03, n, r * 0.68, 16)

static func _windows(lm: LandmarkMesh, mats: Dictionary) -> void:
	var tilt := atan(BATTER)
	var w1 := StoDjurgKit.unit(mats, 2.6, 5.2, true, 0.28)
	var w2 := StoDjurgKit.unit(mats, 1.1, 4.2, true, 0.24)
	var w3 := StoDjurgKit.unit(mats, 0.8, 2.0, true, 0.2)
	for k in 8:
		var a := float(k) * PI / 4.0
		var n := Vector3(cos(a), 0, sin(a))
		var side := Vector3.UP.cross(n)
		StoChurchKit.place(lm, w1, n * _a(1.8) + Vector3(0, 1.8, 0), n, tilt)
		LandmarkDetail.arch(lm, "Trim", n * (_a(5.7) + 0.02) + Vector3(0, 5.7, 0), n, 3.7, 0.4, 0.22, 14)
		_roundel(lm, k, 9.0, 0.55)
		for s in [-1.0, 1.0]:
			var sg: float = s
			StoChurchKit.place(lm, w2, n * _a(11.0) + side * 0.95 * sg + Vector3(0, 11.0, 0), n, tilt)
			StoChurchKit.place(lm, w3, n * _a(18.9) + side * 1.3 * sg + Vector3(0, 18.9, 0), n, tilt)
		LandmarkDetail.arch(lm, "Trim", n * (_a(14.55) + 0.02) + Vector3(0, 14.55, 0), n, 3.1, 0.3, 0.2, 12)
		_roundel(lm, k, 15.9, 0.38)
		StoChurchKit.place(lm, w3, n * _a(18.9) + Vector3(0, 18.9, 0), n, tilt)

## Projecting corbelled cornice: a flared course over a dentil row.
static func _cornice(lm: LandmarkMesh) -> void:
	var y0 := 21.9
	lm.lathe("Trim", Vector3(0, y0, 0), PackedVector2Array([
		Vector2(_r(y0) + 0.05, 0.0), Vector2(_r(y0) + 0.4, 0.5),
		Vector2(_r(y0) + 1.1, 0.9)]), 8, 1.0, 1.0, PI / 8.0, false, false)
	_ring(lm, "Trim", EAVE - 0.05, 0.1, 1.1)
	for k in 8:
		var a := float(k) * PI / 4.0
		var n := Vector3(cos(a), 0, sin(a))
		var side := Vector3.UP.cross(n)
		var basis := Basis(side, Vector3.UP, n)
		for i in 11:
			var t := (float(i) - 5.0) * 0.43
			lm.box("Trim", n * (_a(21.5) + 0.18) + side * t + Vector3(0, 21.5, 0), Vector3(0.22, 0.38, 0.36), basis, 0.0)
	# The cornice slab closes the top of the brickwork.
	lm.lathe("Trim", Vector3(0, EAVE, 0), PackedVector2Array([
		Vector2(_r(EAVE) + 1.2, 0.0), Vector2(_r(EAVE) + 1.2, 0.18), Vector2(0.0, 0.18)]), 8, 1.0, 1.0,
		PI / 8.0, false)

## The red timber crown: corner posts, balcony, lantern, stepped roof, flag.
static func _crown(lm: LandmarkMesh) -> void:
	var y := EAVE + 0.18
	var corners := StoDjurgKit.octagon(_a(EAVE) + 0.7)
	StoDjurgKit.railing(lm, corners, y, 1.0, 0.8, "Metal")
	# Four corner posts with pyramid caps.
	for j in [0, 2, 4, 6]:
		var c := corners[j] as Vector3
		var p := Vector3(c.x * 0.93, y, c.z * 0.93)
		lm.box("Red", p + Vector3(0, 1.2, 0), Vector3(1.5, 2.4, 1.5), Basis(Vector3.UP, atan2(c.x, c.z)), 0.0)
		lm.spire("Roof", p + Vector3(0, 2.4, 0), 0.95, 0.9, 0.0)
	# Lantern: red octagonal walls with a window on each face.
	var la := 3.6
	lm.frustum("Red", Vector3(0, y, 0), la * 1.0824, la * 1.0824, 2.1, 8, PI / 8.0)
	for k in 8:
		var a := float(k) * PI / 4.0
		var n := Vector3(cos(a), 0, sin(a))
		var side := Vector3.UP.cross(n)
		var basis := Basis(side, Vector3.UP, n)
		for s in [-0.8, 0.8]:
			lm.box("Glass", n * (la + 0.02) + side * float(s) + Vector3(0, y + 1.15, 0), Vector3(0.9, 1.1, 0.05), basis, 0.0)
		lm.box("Frame", n * (la + 0.04) + Vector3(0, y + 1.15, 0), Vector3(0.12, 1.2, 0.06), basis, 0.0)
	# Stepped hipped skirt, plank drum and flat top.
	var y1 := y + 2.1
	lm.lathe("Red", Vector3(0, y1, 0), PackedVector2Array([
		Vector2(4.35, 0.0), Vector2(3.5, 0.9), Vector2(3.1, 0.9)]), 8, 1.0, 1.0, PI / 8.0, false)
	lm.frustum("Red", Vector3(0, y1 + 0.9, 0), 3.1, 3.1, 1.0, 8, PI / 8.0)
	lm.lathe("Roof", Vector3(0, y1 + 1.9, 0), PackedVector2Array([
		Vector2(3.5, 0.0), Vector2(3.5, 0.18), Vector2(0.0, 0.18)]), 8, 1.0, 1.0, PI / 8.0, false)
	var deck := y1 + 2.08
	lm.beam("Metal", Vector3(0, deck, 0), Vector3(0, TOP, 0), 0.1, 0.1)
	StoDjurgKit.flag(lm, Vector3(0.05, 0, 0), TOP - 0.2)
