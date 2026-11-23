class_name LandmarkMiLincoln1111
extends RefCounted

## 1111 Lincoln Road (Herzog & de Meuron, 2010) - MI-4B.
## Site: relation 12268481 (25.790897, -80.140767, yaw_deg -1.3), footprint 51.6 x 45.5 m,
## height_m = 34.0.
## Open-air raw board-formed concrete "card house": seven thin floor plates at wildly
## varying levels (y = 5.5, 7.5, 11.0, 15.5, 22.0, 26.5, 34.0 m), carried only by splayed
## V / inverted-V wedge piers, with no exterior spandrel walls at all. A glazed retail box
## fills the ground storey, a helical stair spirals through the stack, the top plate is a
## planted roof garden, and warm DeckLamp strips glow under every deck at night.

const HEIGHT_M := 34.0
const LEVELS: Array[float] = [5.5, 7.5, 11.0, 15.5, 22.0, 26.5, 34.0]
const PLATE_W: Array[float] = [48.0, 51.6, 46.0, 51.0, 49.0, 44.0, 51.6]
const PLATE_D: Array[float] = [40.0, 45.5, 43.0, 38.0, 45.5, 41.0, 45.5]
const PLATE_X: Array[float] = [0.0, 0.8, -1.2, 1.0, -0.6, 1.2, 0.0]
const PLATE_Z: Array[float] = [0.0, -0.6, 1.0, -1.2, 0.8, -0.4, 0.0]
const STAIR_C := Vector2(14.0, 8.0)

static func _top(i: int) -> float:
	return LEVELS[i] - 0.3 if i == LEVELS.size() - 1 else LEVELS[i]

static func _thick(i: int) -> float:
	return 0.9 if i == LEVELS.size() - 1 else 0.45

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#A8A49B", 3.0))
	lm.use("Glass", LandmarkMaterials.glass("#3C5560"))
	lm.use("Steel", LandmarkMaterials.paint("#2C2F31", 0.5, 0.6))
	lm.use("Planter", LandmarkMaterials.paint("#5E8C3E", 0.9, 0.0))
	lm.use("DeckLamp", LandmarkMaterials.lit("#FFC46A", 1.1))
	_ground(lm)
	_plates(lm)
	_piers(lm)
	_stair(lm)
	_lamps(lm)
	lm.commit(model)
	var warm := Color(1.0, 0.78, 0.45)
	var spots: Array = []
	for i: int in [2, 3, 4, 5, 6]:
		var y_hi: float = _top(i) - _thick(i)
		var y_lo: float = LEVELS[i - 1]
		spots.append([Vector3(0.0, y_lo + 1.0, 10.0), Vector3(0.0, y_hi, -2.0), 80.0, 0.9,
			(y_hi - y_lo) + 18.0, warm])
	model.set_meta(LandmarkLights.FLOOD_META, spots)

static func _ground(lm: LandmarkMesh) -> void:
	lm.box("Concrete", Vector3(0.0, -0.15, 0.0), Vector3(51.6, 0.3, 45.5), Basis(), 0.0)
	# Ground retail glass box, recessed under the first plate (y = 0..5.05 m)
	lm.box("Glass", Vector3(0.0, 2.5, 0.0), Vector3(44.0, 5.0, 34.0), Basis(), 0.0)
	for k in 12:
		var x: float = -22.0 + 4.0 * float(k)
		for sz: float in [-17.0, 17.0]:
			lm.beam("Steel", Vector3(x, 0.0, sz), Vector3(x, 5.05, sz), 0.18, 0.18)

static func _plates(lm: LandmarkMesh) -> void:
	for i in LEVELS.size():
		var t: float = _thick(i)
		var top: float = _top(i)
		lm.box("Concrete", Vector3(PLATE_X[i], top - t * 0.5, PLATE_Z[i]),
			Vector3(PLATE_W[i], t, PLATE_D[i]), Basis(), 0.0)
	# Roof-garden planters on the top plate (y = 33.7..34.0 m)
	for px: float in [-18.0, -6.0, 6.0, 18.0]:
		for pz: float in [-12.0, 12.0]:
			lm.box("Planter", Vector3(px, 33.85, pz), Vector3(8.0, 0.3, 5.0), Basis(), 0.0)

static func _piers(lm: LandmarkMesh) -> void:
	var xs: Array[float] = [-21.0, -7.0, 7.0, 21.0]
	var zs: Array[float] = [-16.0, 0.0, 16.0]
	for i in LEVELS.size():
		var y_lo: float = 0.0 if i == 0 else LEVELS[i - 1]
		var y_hi: float = _top(i) - _thick(i)
		var splay: float = clampf(0.45 * (y_hi - y_lo), 0.8, 4.0)
		for ix in xs.size():
			for iz in zs.size():
				var x: float = xs[ix]
				var z: float = zs[iz]
				if (ix + iz + i) % 2 == 0:
					lm.beam("Concrete", Vector3(x, y_lo, z), Vector3(x - splay, y_hi, z), 0.8, 1.1, Vector3.BACK)
					lm.beam("Concrete", Vector3(x, y_lo, z), Vector3(x + splay, y_hi, z), 0.8, 1.1, Vector3.BACK)
				else:
					lm.beam("Concrete", Vector3(x - splay, y_lo, z), Vector3(x, y_hi, z), 0.8, 1.1, Vector3.BACK)
					lm.beam("Concrete", Vector3(x + splay, y_lo, z), Vector3(x, y_hi, z), 0.8, 1.1, Vector3.BACK)

static func _stair(lm: LandmarkMesh) -> void:
	# Central helical stair & cantilevered ramp spiralling through the decks
	lm.frustum("Concrete", Vector3(STAIR_C.x, 0.0, STAIR_C.y), 0.6, 0.6, 33.6, 10)
	var steps := 96
	var rise: float = 33.0 / float(steps)
	for i in steps:
		var a: float = TAU * 6.0 * float(i) / float(steps)
		var c := Vector3(STAIR_C.x + cos(a) * 3.0, float(i) * rise + 0.2, STAIR_C.y + sin(a) * 3.0)
		lm.box("Concrete", c, Vector3(4.6, 0.35, 1.5), Basis(Vector3.UP, -a), 0.0)

static func _lamps(lm: LandmarkMesh) -> void:
	for i in LEVELS.size():
		var y: float = _top(i) - _thick(i) - 0.12
		for z: float in [-14.0, 0.0, 14.0]:
			lm.beam("DeckLamp", Vector3(-20.0, y, z), Vector3(20.0, y, z), 0.3, 0.1)
