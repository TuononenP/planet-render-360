class_name StoOuterStadion
extends RefCounted

## Stockholms stadion, the 1912 Olympic stadium (Torben Grut), Lidingovagen.
## Origin at the centroid of the OSM outer stand ring (way 23152985); long
## axis local X. The registry yaw (-55.4) turns local +X onto bearing 34.6.
##
## The outline is the OSM geometry in the model frame (x -114..108, z -61..61):
## the outer wall ring (way 23152985, 64 radial samples about C below) and the
## inner ring at the foot of the stands (way 737537503, 193 x 90 m). The long
## sides are straight, the west end a rounded curve and the east end (the
## Marathon-gate end, with the two towers at the corners) a wide shallow
## bulge. See sto_stadion_tower.gd for the towers.
##
## From the photos (front and aerial are views from inside the bowl, quarter is
## a tower detail):
## - A closed oval bowl of raked seat tiers (grey concrete) rising from a
##   red running track and the green pitch (105 x 68 m).
## - Round the long sides and the west curve a dark timber roof on slender
##   posts covers the upper tiers, ending in a white fascia band; the east
##   end is open to the sky.
## - Behind the tiers a dark-red brick back wall 14.5 m high; on the outside
##   rows of small round-headed windows. At the east end the inner wall is
##   an arcade of round arches under a flat parapet, with the scoreboard in
##   the middle and a row of flagpoles along its top.
## - Two brick gate towers (40 m, OSM) at the east corners, lamp rigs on top.
## Height 40 m is the towers (OSM). Wall (14.5 m), roof (to 14.9 m) and tier
## rake are scaled from the aerial photo against the 40 m towers.
## Night: the lamp rigs glow, the towers are washed from outside.


const N := 64
const C := Vector2(-4.0, 0.0)
## Radius of the outer wall ring and of the inner ring (foot of the stands) at
## every 5.625 degrees about C, from the OSM geometry.
const R_OUT := [111.8, 111.8, 112.3, 113.1, 113.1, 111.4, 106.3, 95.2, 85.6, 78.4, 72.9, 68.8, 65.7, 63.5,
	61.9, 61.1, 60.8, 61.1, 62.0, 63.6, 65.9, 69.1, 73.3, 78.8, 85.3, 90.8, 95.4, 98.9, 102.3, 104.8, 106.4,
	106.6, 107.5, 107.7, 107.0, 105.4, 103.3, 100.4, 96.5, 91.6, 85.8, 79.0, 73.4, 69.1, 65.9, 63.6, 62.0,
	61.1, 60.7, 61.0, 61.8, 63.3, 65.5, 68.6, 72.7, 78.1, 85.3, 95.0, 105.5, 110.0, 112.1, 111.9, 111.5, 111.4]
const R_IN := [87.2, 87.2, 87.3, 87.2, 87.7, 88.5, 86.0, 83.0, 63.9, 58.5, 54.4, 51.3, 49.0, 47.3, 46.2,
	45.5, 45.3, 45.6, 46.2, 47.4, 49.1, 51.5, 54.6, 58.8, 64.3, 71.5, 78.2, 83.0, 86.9, 89.5, 91.6, 98.1,
	98.5, 98.0, 91.0, 89.4, 86.8, 82.7, 77.3, 70.4, 63.4, 58.1, 54.0, 50.9, 48.6, 47.0, 45.9, 45.2, 45.0,
	45.3, 45.9, 47.1, 48.8, 51.2, 54.3, 58.4, 63.9, 80.5, 91.6, 87.2, 87.1, 86.7, 86.8, 87.0]

const TIERS := 14
const SEAT_T := 0.70
const WALL_T := 0.93
const Y_FOOT := 0.9
const Y_SEAT := 8.0
const WALL_TOP := 14.5
const ROOF_T := 0.32
const ROOF_FRONT := 13.4
const ROOF_BACK := 14.9
## Sectors 57..63 and 0..7 (the east end, within about 40 degrees of +X) are
## open to the sky.
const OPEN_LO := 8
const OPEN_HI := 56

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#774434", 3.0))
	lm.use("Seat", LandmarkMaterials.pbr("concrete", "#9A968E", 3.0))
	lm.use("Track", LandmarkMaterials.pbr("asphalt", "#A24B33", 3.0, 0.7))
	lm.use("Pitch", LandmarkMaterials.pbr("grass", "#4F8239", 5.0))
	lm.use("Roof", LandmarkMaterials.pbr("sheet_metal", "#47403A", 3.0, 0.6, 0.4))
	lm.use("Fascia", LandmarkMaterials.paint("#DAD6CA", 0.55, 0.2))
	lm.use("Post", LandmarkMaterials.paint("#2D2B28", 0.55, 0.4))
	lm.use("Void", LandmarkMaterials.glass("#1E1B19"))
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#8E8A82", 2.4))
	lm.use("Frame", LandmarkMaterials.paint("#34302B", 0.5, 0.3))
	lm.use("Lamp", LandmarkMaterials.lit("#FFF4D8", 0.9))
	lm.use("Copper", LandmarkMaterials.pbr("copper", "#6F9B86", 2.0, 0.55, 0.3))
	lm.use("Flag", LandmarkMaterials.paint("#EDEDEA", 0.5, 0.2))
	_field(lm)
	_tiers(lm)
	_walls(lm)
	_roof(lm)
	_east_end(lm)
	StoOuterStadionTower.build(lm)
	lm.commit(model)
	var warm := Color(1.0, 0.9, 0.72)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(78.0, 1.5, -78.0), Vector3(65.0, 22.0, -56.0), 34.0, 1.0, 70.0, warm],
		[Vector3(78.0, 1.5, 78.0), Vector3(66.0, 22.0, 57.0), 34.0, 1.0, 70.0, warm],
		[Vector3(-130.0, 1.5, 0.0), Vector3(-110.0, 8.0, 0.0), 50.0, 0.8, 70.0, warm]])

# --- Ring helpers -----------------------------------------------------------

static func _dir(i: int) -> Vector2:
	var a := TAU * float(posmod(i, N)) / float(N)
	return Vector2(cos(a), sin(a))

## Point of sector edge `i` at fraction `t` from the inner ring (0) to the outer
## wall (1).
static func _pt(i: int, t: float) -> Vector2:
	var k := posmod(i, N)
	return C + _dir(k) * lerpf(float(R_IN[k]), float(R_OUT[k]), t)

static func _v(p: Vector2, y: float) -> Vector3:
	return Vector3(p.x, y, p.y)

static func _ring_poly(t: float) -> PackedVector2Array:
	var poly := PackedVector2Array()
	for i in N:
		poly.append(_pt(i, t))
	return poly

## Outward-facing wall quad along sector `i` between fractions-of-ring `t` at
## heights y0..y1; `out` is +1 when it faces away from the pitch.
static func _wall(lm: LandmarkMesh, key: String, i: int, t: float, y0: float, y1: float, out: float) -> void:
	var a := _pt(i, t)
	var b := _pt(i + 1, t)
	var mid := (_dir(i) + _dir(i + 1)).normalized() * out
	lm.quad(key, _v(a, y0), _v(b, y0), _v(b, y1), _v(a, y1), Vector3(mid.x, 0, mid.y))

## Horizontal band between fractions t0..t1 along sector `i` at height y.
static func _flat(lm: LandmarkMesh, key: String, i: int, t0: float, t1: float, y: float) -> void:
	lm.quad(key, _v(_pt(i, t0), y), _v(_pt(i + 1, t0), y), _v(_pt(i + 1, t1), y), _v(_pt(i, t1), y), Vector3.UP)

# --- Field ---------------------------------------------------------------------

static func _field(lm: LandmarkMesh) -> void:
	lm.poly_prism("Track", _ring_poly(0.0), 0.0, 0.1, true)
	var x0 := -9.5
	var rect := PackedVector2Array([Vector2(x0 - 52.5, -34.0), Vector2(x0 + 52.5, -34.0),
		Vector2(x0 + 52.5, 34.0), Vector2(x0 - 52.5, 34.0)])
	lm.poly_prism("Pitch", rect, 0.0, 0.14, true)

# --- Seat tiers -----------------------------------------------------------------

static func _tiers(lm: LandmarkMesh) -> void:
	for i in N:
		var prev_y := 0.1
		for k in TIERS:
			var t0 := SEAT_T * float(k) / float(TIERS)
			var t1 := SEAT_T * float(k + 1) / float(TIERS)
			var y := Y_FOOT + (Y_SEAT - Y_FOOT) * float(k + 1) / float(TIERS)
			# Riser then tread.
			var a := _pt(i, t0)
			var b := _pt(i + 1, t0)
			var inward := -(_dir(i) + _dir(i + 1)).normalized()
			lm.quad("Seat", _v(a, prev_y), _v(b, prev_y), _v(b, y), _v(a, y), Vector3(inward.x, 0, inward.y))
			_flat(lm, "Seat", i, t0, t1, y)
			prev_y = y
		# Concourse behind the last tier.
		_flat(lm, "Seat", i, SEAT_T, WALL_T, Y_SEAT)

# --- Walls ------------------------------------------------------------------------

static func _walls(lm: LandmarkMesh) -> void:
	for i in N:
		_wall(lm, "Brick", i, WALL_T, Y_SEAT, WALL_TOP, -1.0)
		_flat(lm, "Brick", i, WALL_T, 1.0, WALL_TOP)
		_wall(lm, "Brick", i, 1.0, 0.0, WALL_TOP, 1.0)
		# Granite plinth round the foot of the outer wall.
		var a := _pt(i, 1.0)
		var b := _pt(i + 1, 1.0)
		var o := (_dir(i) + _dir(i + 1)).normalized() * 0.25
		lm.quad("Stone", _v(a + o, 0.0), _v(b + o, 0.0), _v(b + o, 1.4), _v(a + o, 1.4), Vector3(o.x, 0, o.y))
		# Two round-headed windows per sector on the outer wall.
		var mid := (_dir(i) + _dir(i + 1)).normalized()
		for f in [0.3, 0.7]:
			var p := a.lerp(b, float(f))
			LandmarkFhUtil.opening(lm, "Void", _v(p + mid * 0.05, 5.0), Vector3(mid.x, 0, mid.y), 1.3, 3.2, true)

## The east end: the arcade on the inner wall, the scoreboard and the flagpoles.
static func _east_end(lm: LandmarkMesh) -> void:
	for i in range(-8, 8):
		var a := _pt(i, WALL_T)
		var b := _pt(i + 1, WALL_T)
		var inward := -(_dir(i) + _dir(i + 1)).normalized()
		var o := Vector3(inward.x, 0, inward.y)
		for f in [0.3, 0.7]:
			var p := a.lerp(b, float(f))
			LandmarkFhUtil.opening(lm, "Void", _v(p, Y_SEAT + 1.6) + o * 0.06, o, 2.2, 4.0, true)
	# Scoreboard in the middle of the end wall.
	var c := _pt(0, WALL_T)
	lm.box("Frame", Vector3(c.x - 0.15, Y_SEAT + 3.6, c.y), Vector3(0.3, 3.4, 14.0), Basis(), 0.0)
	# Flagpoles along the top of the wall.
	for i in range(-7, 8):
		var q := _pt(i, 0.97)
		lm.beam("Flag", _v(q, WALL_TOP), _v(q, WALL_TOP + 9.0), 0.2, 0.2)

# --- Roof --------------------------------------------------------------------------

static func _roof(lm: LandmarkMesh) -> void:
	for i in range(OPEN_LO, OPEN_HI + 1):
		var a0 := _pt(i, ROOF_T)
		var a1 := _pt(i + 1, ROOF_T)
		var b0 := _pt(i, 1.0)
		var b1 := _pt(i + 1, 1.0)
		var nrm := Vector3(0, 1.0, 0.0)
		lm.quad("Roof", _v(a0, ROOF_FRONT), _v(a1, ROOF_FRONT), _v(b1, ROOF_BACK), _v(b0, ROOF_BACK), nrm)
		# Underside.
		lm.quad("Roof", _v(a0, ROOF_FRONT - 0.5), _v(b0, ROOF_BACK - 0.5), _v(b1, ROOF_BACK - 0.5),
			_v(a1, ROOF_FRONT - 0.5), Vector3.DOWN)
		# White fascia along the front edge.
		var inward := -(_dir(i) + _dir(i + 1)).normalized()
		lm.quad("Fascia", _v(a0, ROOF_FRONT - 1.4), _v(a1, ROOF_FRONT - 1.4), _v(a1, ROOF_FRONT + 0.15),
			_v(a0, ROOF_FRONT + 0.15), Vector3(inward.x, 0, inward.y))
		if i % 2 == 0:
			var p := _pt(i, ROOF_T + 0.01)
			var rake := Y_FOOT + (Y_SEAT - Y_FOOT) * ROOF_T / SEAT_T
			lm.box("Post", Vector3(p.x, (rake + ROOF_FRONT - 1.4) * 0.5, p.y),
				Vector3(0.4, ROOF_FRONT - 1.4 - rake, 0.4), Basis(), 0.0)
