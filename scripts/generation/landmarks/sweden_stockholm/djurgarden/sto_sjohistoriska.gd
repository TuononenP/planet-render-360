class_name StoSjohistoriska
extends RefCounted

## Sjöhistoriska museet (Ragnar Östberg, 1936), Djurgårdsbrunnsviken. Origin
## at the centre of OSM way 10502251 (121.2 x 43.7 m, bearing 169, registry
## yaw 79), +X along the long axis, the front at +Z (it faces the bay,
## west-south-west). From the front, aerial and bay photos in
## visual-plan/refs/landmarks/sjohistoriska/ (the sources doc's "red brick" is
## wrong: the walls are pale cream render with stone-framed windows):
## - A shallow-arc front range of two two-storey wings 13.5 m deep, walls
##   cream render to a 10.8 m eave on a stone plinth, a string course over
##   the ground floor and a cornice under a thin copper-green eave band. Low
##   hipped roofs in dark grey slate with flat tops.
## - Windows: tall stone-framed ground-floor openings (1.5 x 3.2 m) and
##   smaller upper ones (1.3 x 2.2 m), 13 bays per wing at 3.1 m.
## - In the middle the cylindrical entrance rotunda (r 6.3, to 11.4 m) with
##   a round-arched door on a three-step stair, a balcony over it, windows
##   either side and a low dark copper dome with a lantern (14.4 m).
## - Behind, an ochre-rendered rear hall, a connecting block and a west cross
##   wing in dark slate hip roofs, with red-framed small windows (the "cross
##   gabled" outline of the OSM way).
## - In front: a row of seven white flagpoles, the red and white beacon, and
##   the 19.5 m mast at the east end (the registry height).
## Window counts and the wing bend (about 4 degrees) are read from the
## photos; the rear halls are simplified.

const MUSEUM_Z := 15.0
const WING_L := 42.0
const HZ := 6.75
const EAVE := 10.8
const ROT_R := 6.3
const ROT_TOP := 11.4
const BEND := 0.0698
const TOP := 19.5

static func build(model: Node3D) -> void:
	var mats := _materials()
	var lm := LandmarkMesh.new()
	StoChurchKit.use_all(lm, mats)
	# Front range: one wing built to the right, merged twice about the rotunda.
	var right := _wing(mats)
	var left := right
	lm.merge(right, Transform3D(Basis(Vector3.UP, -BEND), Vector3(ROT_R - 0.6, 0, MUSEUM_Z)))
	lm.merge(left, Transform3D(Basis(Vector3.UP, PI + BEND), Vector3(-(ROT_R - 0.6), 0, MUSEUM_Z)))
	_rotunda(lm, mats)
	_rear(lm, mats)
	_front_yard(lm)
	lm.commit(model)
	var warm := Color(1.0, 0.9, 0.72)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-40.0, 1.2, 38.0), Vector3(-18.0, 6.0, MUSEUM_Z + 6.0), 45.0, 0.9, 60.0, warm],
		[Vector3(40.0, 1.2, 38.0), Vector3(18.0, 6.0, MUSEUM_Z + 6.0), 45.0, 0.9, 60.0, warm],
		[Vector3(0.0, 1.2, 36.0), Vector3(0.0, 9.0, MUSEUM_Z + ROT_R), 35.0, 0.9, 40.0, warm],
	])

static func _materials() -> Dictionary:
	return {
		"Wall": LandmarkMaterials.pbr("render", "#E6D9B4", 3.0),
		"Trim": LandmarkMaterials.pbr("stone", "#D2C8AE", 2.5),
		"Ochre": LandmarkMaterials.pbr("render", "#D69E58", 3.0),
		"OchreTrim": LandmarkMaterials.pbr("render", "#8E3B3A", 2.0),
		"Roof": LandmarkMaterials.pbr("slate", "#4F5659", 3.0, 0.55, 0.25),
		"Copper": LandmarkMaterials.pbr("concrete", "#78A18F", 2.0, 0.55, 0.3),
		"Dome": LandmarkMaterials.pbr("concrete", "#4A5753", 2.0, 0.5, 0.35),
		"Glass": LandmarkMaterials.glass("#26313A"),
		"Iron": LandmarkMaterials.pbr("concrete", "#F0EEE8", 2.0, 0.5, 0.2),
		"Mast": LandmarkMaterials.pbr("wood", "#B58A3C", 2.0),
		"Red": LandmarkMaterials.pbr("render", "#B03028", 2.0),
	}

static func _unit(mats: Dictionary, w: float, h: float, arched: bool = false, frame: String = "Trim") -> LandmarkMesh:
	var u := LandmarkMesh.new()
	StoChurchKit.use_all(u, mats)
	LandmarkDetail.window(u, frame, "Glass", Vector3(0, h * 0.5, 0), Vector3.BACK, w, h, arched, 0.25)
	return u

## A row of `n` copies of `unit` along z = `z` from x0 to x1 facing `out`.
static func _row(lm: LandmarkMesh, unit: LandmarkMesh, x0: float, x1: float, z: float, out: Vector3,
		y: float, n: int) -> void:
	for i in n:
		var x := lerpf(x0, x1, (float(i) + 0.5) / float(n))
		StoChurchKit.place(lm, unit, Vector3(x, y, z), out)

## One front wing in its own frame: x outward from the rotunda, both long
## faces alike, so the left wing is the same unit turned half a circle.
static func _wing(mats: Dictionary) -> LandmarkMesh:
	var lm := LandmarkMesh.new()
	StoChurchKit.use_all(lm, mats)
	var cx := WING_L * 0.5
	lm.box("Trim", Vector3(cx, 0.35, 0), Vector3(WING_L, 0.7, HZ * 2.0 + 0.3), Basis(), 0.0)
	LandmarkFhUtil.blk(lm, "Wall", cx, 0.0, 0.0, WING_L, EAVE, HZ * 2.0)
	for z in [-HZ, HZ]:
		var zs: float = float(z)
		var pr := 0.12 if zs > 0.0 else -0.12
		lm.box("Trim", Vector3(cx, 5.1, zs + pr), Vector3(WING_L, 0.35, 0.24), Basis(), 0.0)
		lm.box("Trim", Vector3(cx, EAVE - 0.35, zs + pr * 2.0), Vector3(WING_L + 0.4, 0.5, 0.5), Basis(), 0.0)
	lm.box("Copper", Vector3(cx, EAVE + 0.1, 0), Vector3(WING_L + 1.0, 0.28, HZ * 2.0 + 1.0), Basis(), 0.0)
	LandmarkFhUtil.hip(lm, "Roof", Vector3(cx, EAVE + 0.24, 0), WING_L + 0.8, HZ * 2.0 + 0.8, 2.6, 0.82)
	var tall := _unit(mats, 1.5, 3.2)
	var small := _unit(mats, 1.3, 2.2)
	var n := 13
	for s in [-1.0, 1.0]:
		var sg: float = s
		var out := Vector3(0, 0, sg)
		_row(lm, tall, 2.2, WING_L - 2.2, sg * HZ, out, 1.0, n)
		_row(lm, small, 2.2, WING_L - 2.2, sg * HZ, out, 5.9, n)
	for z in [-2.4, 2.4]:
		StoChurchKit.place(lm, small, Vector3(WING_L, 5.9, float(z)), Vector3.RIGHT)
		StoChurchKit.place(lm, tall, Vector3(WING_L, 1.0, float(z)), Vector3.RIGHT)
	return lm

static func _rotunda(lm: LandmarkMesh, mats: Dictionary) -> void:
	var c := Vector3(0, 0, MUSEUM_Z)
	lm.frustum("Trim", c, ROT_R + 0.3, ROT_R + 0.3, 0.7, 24)
	lm.frustum("Wall", c, ROT_R, ROT_R, ROT_TOP, 24)
	lm.frustum("Trim", c + Vector3.UP * 5.0, ROT_R + 0.12, ROT_R + 0.12, 0.35, 24)
	lm.frustum("Trim", c + Vector3.UP * (ROT_TOP - 0.7), ROT_R + 0.4, ROT_R + 0.4, 0.7, 24)
	lm.lathe("Dome", c + Vector3.UP * ROT_TOP, LandmarkFhUtil.dome_prof(ROT_R + 0.2, 3.0), 24)
	lm.frustum("Trim", c + Vector3.UP * (ROT_TOP + 2.9), 1.0, 0.8, 1.2, 12)
	lm.lathe("Dome", c + Vector3.UP * (ROT_TOP + 4.0), LandmarkFhUtil.dome_prof(0.9, 0.9, 6), 12)
	var door := _unit(mats, 2.4, 3.8, true)
	var narrow := _unit(mats, 1.0, 3.0)
	var upper := _unit(mats, 1.0, 2.2)
	for deg in [-60.0, -40.0, 40.0, 60.0]:
		var a := deg_to_rad(float(deg))
		StoChurchKit.place(lm, narrow, c + Vector3(sin(a), 0, cos(a)) * ROT_R + Vector3(0, 1.0, 0),
			Vector3(sin(a), 0, cos(a)))
	for deg in [-60.0, -30.0, 30.0, 60.0, 90.0, -90.0, 120.0, -120.0]:
		var a := deg_to_rad(float(deg))
		StoChurchKit.place(lm, upper, c + Vector3(sin(a), 0, cos(a)) * ROT_R + Vector3(0, 5.9, 0),
			Vector3(sin(a), 0, cos(a)))
	StoChurchKit.place(lm, door, c + Vector3(0, 0.9, ROT_R), Vector3.BACK)
	# Three-step stair, the balcony over the door and its iron rail.
	for k in 3:
		LandmarkFhUtil.blk(lm, "Trim", 0.0, 0.0, MUSEUM_Z + ROT_R + 0.9 + 0.5 * float(2 - k), 4.6 - 0.4 * float(k),
			0.3 * float(k + 1), 1.0)
	lm.box("Trim", Vector3(0, 5.0, MUSEUM_Z + ROT_R + 0.6), Vector3(3.6, 0.3, 1.4), Basis(), 0.0)
	LandmarkDetail.balustrade(lm, "Iron", Vector3(-1.8, 5.15, MUSEUM_Z + ROT_R + 1.25),
		Vector3(1.8, 5.15, MUSEUM_Z + ROT_R + 1.25), 0.9, 1.8)

## Ochre rear block with a red-framed window row on each long side.
static func _ochre(lm: LandmarkMesh, mats: Dictionary, x0: float, x1: float, z0: float, z1: float,
		eave: float) -> void:
	var cx := (x0 + x1) * 0.5
	var cz := (z0 + z1) * 0.5
	var w := x1 - x0
	var d := z1 - z0
	LandmarkFhUtil.blk(lm, "Ochre", cx, 0.0, cz, w, eave, d)
	lm.box("Roof", Vector3(cx, eave + 0.15, cz), Vector3(w + 1.0, 0.3, d + 1.0), Basis(), 0.0)
	LandmarkFhUtil.hip(lm, "Roof", Vector3(cx, eave + 0.3, cz), w + 0.8, d + 0.8, 3.0, 0.5)
	var win := _unit(mats, 1.1, 1.6, false, "OchreTrim")
	var low := _unit(mats, 1.1, 1.8, false, "OchreTrim")
	var n := maxi(int(w / 3.4), 2)
	for s in [z0, z1]:
		var out := Vector3(0, 0, 1.0 if float(s) == z1 else -1.0)
		_row(lm, low, x0 + 2.0, x1 - 2.0, float(s), out, 1.2, n)
		_row(lm, win, x0 + 2.0, x1 - 2.0, float(s), out, 4.6, n)
	var m := maxi(int(d / 3.4), 1)
	for k in m:
		var z := lerpf(z0 + 1.6, z1 - 1.6, (float(k) + 0.5) / float(m))
		StoChurchKit.place(lm, low, Vector3(x1, 1.2, z), Vector3.RIGHT)
		StoChurchKit.place(lm, low, Vector3(x0, 1.2, z), Vector3.LEFT)

static func _rear(lm: LandmarkMesh, mats: Dictionary) -> void:
	_ochre(lm, mats, -34.0, 40.0, -21.5, -8.0, 7.6)
	_ochre(lm, mats, -6.5, 6.5, -8.0, 8.0, 8.4)
	_ochre(lm, mats, -52.0, -36.0, -21.5, 6.0, 7.6)

static func _front_yard(lm: LandmarkMesh) -> void:
	# Seven flagpoles on the lawn line in front of the wings.
	for i in 7:
		var x := lerpf(-22.0, 22.0, float(i) / 6.0)
		var z := MUSEUM_Z + 13.2 + absf(x) * BEND
		lm.beam("Iron", Vector3(x, 0.0, z), Vector3(x, 9.0, z), 0.14, 0.14)
	# The beacon: a red and white tower on a stone plinth.
	var b := Vector3(-14.0, 0.0, 33.0)
	lm.frustum("Trim", b, 1.1, 1.0, 0.9, 10)
	lm.frustum("Red", b + Vector3.UP * 0.9, 0.9, 0.8, 1.5, 10)
	lm.frustum("Wall", b + Vector3.UP * 2.4, 0.8, 0.8, 1.0, 10)
	lm.frustum("Red", b + Vector3.UP * 3.4, 0.8, 0.8, 0.6, 10)
	lm.lathe("Roof", b + Vector3.UP * 4.0, LandmarkFhUtil.dome_prof(0.95, 0.7, 6), 10)
	# The mast at the east end: pole, crow's nest and two yards.
	var m := Vector3(54.0, 0.0, 26.0)
	lm.frustum("Mast", m, 0.34, 0.22, TOP, 8)
	lm.box("Mast", m + Vector3(0, 11.5, 0), Vector3(2.0, 0.3, 2.0), Basis(), 0.0)
	lm.beam("Mast", m + Vector3(-3.5, 13.6, 0), m + Vector3(3.5, 13.6, 0), 0.2, 0.2)
	lm.beam("Mast", m + Vector3(-2.5, 17.2, 0), m + Vector3(2.5, 17.2, 0), 0.16, 0.16)
