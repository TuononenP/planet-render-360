class_name StoIslandNorstedts
extends RefCounted

## Norstedtshuset (Norstedts publishing house, 1882-1891, Helgo Zettervall)
## on Riddarholmskajen, OSM way 23841377 (5 levels, 39 m). Origin at the
## outline centroid, no yaw: +X east, +Z south, and the footprint is the
## mapped outline itself (a pinwheel of three wings round a court).
## From visual-plan/refs/landmarks/norstedtshuset/:
## - Walls: a rusticated pale-sandstone ground storey with round-arched
##   windows (6.5 m), above it four storeys of red-brown brick with
##   round-arched windows in stone surrounds, string courses at every
##   floor and a deep corbelled cornice at 24 m.
## - Roofs: steep dark slate over each wing (A along the north-west face,
##   B along the water front, C the west wing) with a dormer every 6.5 m
##   on both slopes; the gabled bay of wing A (west end) has stepped
##   brick gable shoulders.
## - Tower: a square brick tower at the north corner (the 45-degree chamfer
##   where wings A and B meet), belfry stage of slim arched openings, four
##   corner spirelets and the flared, concave copper spire to 39 m.
## - The blue "NORSTEDTS" lettering across the fourth storey of wing A,
##   lit at night, and amber-lit windows.
## Surfaces (6): Stone, Brick, Slate, Copper, WinLamp, SignLamp.

const P := [Vector2(22.9, -27.8), Vector2(21.0, -26.0), Vector2(17.3, -22.5), Vector2(14.7, -19.9),
	Vector2(17.7, -16.8), Vector2(-0.3, 0.7), Vector2(2.5, 3.5), Vector2(-1.3, 7.2), Vector2(-3.8, 5.6),
	Vector2(-5.3, 4.7), Vector2(-7.5, 4.1), Vector2(-18.8, 1.6), Vector2(-12.0, -3.7), Vector2(-6.9, -7.9),
	Vector2(-17.5, -20.1), Vector2(-33.9, -1.2), Vector2(-39.5, 5.5), Vector2(-40.6, 9.0), Vector2(-38.9, 11.4),
	Vector2(-33.5, 12.6), Vector2(-2.7, 19.8), Vector2(-0.3, 20.1), Vector2(6.4, 21.6), Vector2(11.0, 17.0),
	Vector2(32.5, -3.8), Vector2(39.7, -10.7), Vector2(35.9, -14.6), Vector2(34.5, -16.1)]
const BASE_H := 6.5
const EAVE := 24.0
## Tower centre (east, north) and side; spire top.
const TOWER := Vector2(8.7, 19.3)
const TOWER_W := 7.4
const TOWER_SHAFT := 28.0
const TOP_M := 39.0
## Wings: [centre east, centre north, length, width, bearing, rise].
const WINGS := [[-14.7, 9.7, 46.4, 14.6, 77.3, 7.5], [17.4, -2.75, 43.0, 20.2, 134.0, 8.0],
	[-20.7, -4.4, 26.0, 16.6, 139.2, 7.0]]

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#C7B48C", 3.0))
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#7A4132", 2.5))
	lm.use("Slate", LandmarkMaterials.pbr("slate", "#3E4448", 3.0))
	lm.use("Copper", LandmarkMaterials.pbr("concrete", "#5F8573", 2.0, 0.55, 0.3))
	lm.use("WinLamp", _lamp_glass("#FFC878", 0.9))
	lm.use("SignLamp", _lamp_glass("#3A74FF", 1.6))
	var ring := PackedVector2Array()
	for p in P:
		ring.append(Vector2(p.x, -p.y))
	lm.poly_prism("Stone", ring, 0.0, BASE_H)
	lm.poly_prism("Brick", ring, BASE_H, EAVE - 0.1)
	lm.poly_prism("Slate", ring, EAVE - 0.1, EAVE)
	_faces(lm, ring)
	for w in WINGS:
		_wing_roof(lm, w)
	_tower(lm)
	_sign(lm)
	lm.commit(model)

static func _lamp_glass(hex: String, glow: float) -> StandardMaterial3D:
	var m := LandmarkMaterials.glass("#2A3438").duplicate() as StandardMaterial3D
	m.emission_enabled = true
	m.emission = Color(hex)
	m.emission_energy_multiplier = 0.0
	m.set_meta(LandmarkLights.NIGHT_GLOW_META, glow)
	return m

## Windows on every outline edge of 7 m or more, string courses and the cornice.
static func _faces(lm: LandmarkMesh, ring: PackedVector2Array) -> void:
	var area := 0.0
	for i in ring.size():
		var a := ring[i]
		var b := ring[(i + 1) % ring.size()]
		area += a.x * b.y - b.x * a.y
	var sgn := 1.0 if area > 0.0 else -1.0
	for i in ring.size():
		var a := ring[i]
		var b := ring[(i + 1) % ring.size()]
		var len := a.distance_to(b)
		if len < 7.0:
			continue
		var d := (b - a) / len
		# Outward normal in the xz plane (model z = row y of the ring).
		var n2 := Vector2(d.y, -d.x) * sgn
		var n := Vector3(n2.x, 0, n2.y)
		var right := Vector3.UP.cross(n)
		var along := Vector3(d.x, 0, d.y)
		var o := Vector3(a.x, 0, a.y)
		if right.dot(along) < 0.0:
			o = Vector3(b.x, 0, b.y)
		var cols := maxi(int(round(len / 3.6)), 2)
		LandmarkDetail.pierced_face(lm, "Stone", "WinLamp", o, right, n, len, BASE_H, cols, 1,
			Vector2(1.3, 2.9), 1.3, 3.0, 0.3)
		LandmarkDetail.pierced_face(lm, "Brick", "WinLamp", o + Vector3(0, BASE_H, 0), right, n, len, EAVE - BASE_H - 1.2,
			cols, 4, Vector2(1.4, 2.2), 0.9, 4.2, 0.3)
		var mid := (Vector3(a.x, 0, a.y) + Vector3(b.x, 0, b.y)) * 0.5
		var basis := Basis(along, Vector3.UP, along.cross(Vector3.UP))
		for y in [BASE_H + 0.1, 10.7, 14.9, 19.1]:
			lm.box("Stone", mid + n * 0.2 + Vector3(0, y, 0), Vector3(len, 0.3, 0.6), basis, 0.0)
		lm.box("Stone", mid + n * 0.4 + Vector3(0, EAVE - 0.5, 0), Vector3(len, 1.0, 1.0), basis, 0.0)

static func _basis(bearing: float) -> Basis:
	var b := deg_to_rad(bearing)
	var along := Vector3(sin(b), 0, -cos(b))
	return Basis(Vector3.UP.cross(along), Vector3.UP, along)

## Slate roof over a wing, with dormers down both slopes and gable ends.
static func _wing_roof(lm: LandmarkMesh, w: Array) -> void:
	var bs := _basis(float(w[4]))
	var c := Vector3(float(w[0]), EAVE, -float(w[1]))
	var len := float(w[2])
	var wid := float(w[3])
	var rise := float(w[5])
	lm.gable("Slate", c, wid, len, rise, bs, 0.5, "Brick")
	var nd := maxi(int(len / 6.5), 2)
	for k in nd:
		var u := -len * 0.5 + len * (float(k) + 0.5) / float(nd)
		for s in [-1.0, 1.0]:
			var dc := c + bs * Vector3(float(s) * wid * 0.25, rise * 0.5 - 0.3, u)
			var fb := bs * Basis(Vector3.UP, (PI * 0.5) * float(s))
			lm.box("Brick", dc + Vector3(0, 1.0, 0), Vector3(1.6, 2.2, 1.6), fb)
			lm.box("WinLamp", dc + fb * Vector3(0, 1.0, 0.82), Vector3(0.9, 1.5, 0.05), fb, 0.0)
			lm.gable("Slate", dc + Vector3(0, 2.1, 0), 1.6, 1.7, 0.9, fb, 0.15, "Brick")

static func _tower(lm: LandmarkMesh) -> void:
	var c := Vector3(TOWER.x, 0, -TOWER.y)
	var bs := _basis(77.3)
	lm.box("Brick", c + Vector3(0, TOWER_SHAFT * 0.5, 0), Vector3(TOWER_W, TOWER_SHAFT, TOWER_W), bs)
	lm.box("Stone", c + Vector3(0, 0.6, 0), Vector3(TOWER_W + 0.6, 1.2, TOWER_W + 0.6), bs)
	for y in [BASE_H, 14.0, 21.0]:
		lm.box("Stone", c + Vector3(0, y, 0), Vector3(TOWER_W + 0.4, 0.4, TOWER_W + 0.4), bs, 0.0)
	lm.box("Stone", c + Vector3(0, TOWER_SHAFT - 0.4, 0), Vector3(TOWER_W + 1.0, 0.8, TOWER_W + 1.0), bs)
	for f in 4:
		var r := bs * Basis(Vector3.UP, PI * 0.5 * float(f))
		for k in 3:
			lm.box("WinLamp", c + r * Vector3((float(k) - 1.0) * 1.8, 24.4, TOWER_W * 0.5 + 0.03), Vector3(0.9, 3.0, 0.06), r, 0.0)
		lm.box("WinLamp", c + r * Vector3(0, 16.0, TOWER_W * 0.5 + 0.03), Vector3(1.1, 2.4, 0.06), r, 0.0)
	# Corner spirelets and the flared copper spire.
	var phi := atan2(bs.z.z, bs.z.x)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var p := c + bs * Vector3(sx * (TOWER_W * 0.5 + 0.1), TOWER_SHAFT, sz * (TOWER_W * 0.5 + 0.1))
			lm.frustum("Brick", p, 0.55, 0.5, 3.0, 8)
			lm.lathe("Copper", p + Vector3(0, 3.0, 0), PackedVector2Array([Vector2(0.75, 0.0), Vector2(0.0, 4.2)]), 8, 1.0, 1.0,
				PI / 8.0, false)
	lm.lathe("Copper", c + Vector3(0, TOWER_SHAFT, 0), PackedVector2Array([Vector2(5.5, 0.0), Vector2(4.0, 2.0),
		Vector2(2.8, 4.5), Vector2(1.8, 7.2), Vector2(1.0, 9.4), Vector2(0.45, 10.7), Vector2(0.0, TOP_M - TOWER_SHAFT)]),
		4, 1.0, 1.0, phi + PI * 0.25, false)

## The blue letters across the fourth storey of wing A (north-west face).
static func _sign(lm: LandmarkMesh) -> void:
	var a := Vector2(-38.9, -11.4)
	var b := Vector2(6.4, -21.6)
	var d := (b - a).normalized()
	var along := Vector3(d.x, 0, d.y)
	var n := Vector3(d.y, 0, -d.x)
	if n.dot(Vector3(-0.2, 0, -1.0)) < 0.0:
		n = -n
	var bs := Basis(along, Vector3.UP, along.cross(Vector3.UP))
	if bs.z.dot(n) < 0.0:
		bs = Basis(-along, Vector3.UP, (-along).cross(Vector3.UP))
	for k in 9:
		var t := 8.0 + 3.2 * float(k)
		var p := Vector3(a.x, 0, a.y) + along * t + n * 0.55 + Vector3(0, 16.4, 0)
		lm.box("SignLamp", p, Vector3(1.5, 1.9, 0.2), bs, 0.0)
