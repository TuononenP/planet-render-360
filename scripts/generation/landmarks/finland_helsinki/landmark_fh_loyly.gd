extends RefCounted

## Löyly (Avanto Architects, 2016), the public sauna and restaurant on the
## Hernesaari shore. Origin at the OSM building (way 625576876, 60.15218,
## 24.93044, yaw 0: the registry point read 1 km east of the building).
##
## From the Commons photos (visual-plan/refs/landmarks/loyly_helsinki/):
## - A low glazed restaurant storey with a timber-framed front, under a
##   faceted "hill" of pale grey-brown heat-treated pine slats. The west
##   (sea) face and both ends slope back like a ramp, the east face stays
##   steep; the top is a flat roof terrace edged by a glass balustrade and
##   reached by a stair up the sloping face.
## - Three thin black flues stand on the terrace (the smoke sauna and two
##   sauna stoves), the tallest to 8.6 m.
## - A wide timber sun deck steps down to the water on the west side.
##
## Measured: the footprint (the OSM outline reduced to its 46.4 x 14.2 m
## bounding rectangle, long axis 25.8 deg west of south) and the 6.9 m LoD2
## roof. Estimated: the 1.3 m glazed strip, the slope angles, the flue
## positions and heights, the deck size and all colours.

const U = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")

const ENTRY := {"type": "loyly_helsinki", "name": "Löyly", "lat": 60.15218, "lon": 24.93044,
	"radius_m": 1500.0, "wiki_title": "Löyly", "height_m": 8.6, "clear_m": 24.0,
	"kind": "Sauna", "aliases": ["löyly", "loyly sauna", "löyly helsinki"]}

## Centre of the footprint rectangle; u runs along the long axis toward the
## south end, n toward the sea (west).
const O := Vector2(-1.0, 2.85)
const AX_U := Vector2(-0.435, 0.9)
const AX_N := Vector2(-0.9, -0.435)
const HL := 23.2
const HW := 7.1
const BASE := 1.3
const ROOF := 6.9

static func _p(u: float, n: float) -> Vector2:
	return O + AX_U * u + AX_N * n

static func _v(u: float, n: float, y: float) -> Vector3:
	var p := _p(u, n)
	return Vector3(p.x, y, p.y)

## A quad between two (u, n, y) rings, facing away from the body centre.
static func _face(lm: LandmarkMesh, key: String, a: Vector3, b: Vector3, c: Vector3, d: Vector3, centre: Vector3) -> void:
	var nrm := (b - a).cross(d - a).normalized()
	if nrm.dot((a + b + c + d) * 0.25 - centre) < 0.0:
		nrm = -nrm
	lm.quad(key, a, b, c, d, nrm)

## Truncated rectangular pyramid: the rect (u0..u1, n0..n1) at y0 up to the
## rect (tu0..tu1, tn0..tn1) at y1, capped flat.
static func _frustum(lm: LandmarkMesh, key: String, cap: String, r0: Array, r1: Array, y0: float, y1: float) -> void:
	var centre := _v((r0[0] + r0[1]) * 0.5, (r0[2] + r0[3]) * 0.5, (y0 + y1) * 0.5)
	var b: Array = [_v(r0[0], r0[2], y0), _v(r0[1], r0[2], y0), _v(r0[1], r0[3], y0), _v(r0[0], r0[3], y0)]
	var t: Array = [_v(r1[0], r1[2], y1), _v(r1[1], r1[2], y1), _v(r1[1], r1[3], y1), _v(r1[0], r1[3], y1)]
	for i in 4:
		var j := (i + 1) % 4
		_face(lm, key, b[i], b[j], t[j], t[i], centre)
	lm.quad(cap, t[0], t[1], t[2], t[3], Vector3.UP)

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Slat", LandmarkMaterials.pbr("wood", "#7A6A58", 1.0))
	lm.use("Dark", LandmarkMaterials.pbr("wood", "#3A322C", 1.2))
	lm.use("Deck", LandmarkMaterials.pbr("wood", "#B49A78", 1.2))
	lm.use("Roof", LandmarkMaterials.pbr("wood", "#8A7A66", 1.2))
	lm.use("Glass", LandmarkMaterials.glass("#3A4A52"))
	lm.use("Flue", LandmarkMaterials.paint("#1E1F20", 0.5, 0.5))
	lm.use("Lamp", LandmarkMaterials.lit("#FFC878", 0.9))
	# Glazed restaurant storey under the slatted hill.
	U.blk(lm, "Dark", O.x, 0.0, O.y, 1.0, 0.1, 1.0)
	var rect := [-HL, HL, -HW, HW]
	_frustum(lm, "Glass", "Roof", rect, rect, 0.0, BASE)
	# Slender frame posts along the sea side and the ends.
	for k in 24:
		var u := lerpf(-HL, HL, float(k) / 23.0)
		var p := _p(u, HW + 0.05)
		lm.box("Dark", Vector3(p.x, BASE * 0.5, p.y), Vector3(0.14, BASE, 0.14), Basis(Vector3.UP, atan2(-AX_U.y, AX_U.x)), 0.0)
	# Warm light spilling from the restaurant at night.
	var lamp_n := HW + 0.12
	lm.quad("Lamp", _v(-HL + 3.0, lamp_n, 0.5), _v(HL - 3.0, lamp_n, 0.5), _v(HL - 3.0, lamp_n, BASE - 0.3),
		_v(-HL + 3.0, lamp_n, BASE - 0.3), Vector3(AX_N.x, 0, AX_N.y))
	lm.poly_prism("Dark", PackedVector2Array([_p(-HL - 0.3, -HW - 0.3), _p(HL + 0.3, -HW - 0.3),
		_p(HL + 0.3, HW + 0.3), _p(-HL - 0.3, HW + 0.3)]), BASE - 0.15, BASE + 0.1)
	# The slatted hill: steep east face, ramped sea face and ends.
	_frustum(lm, "Slat", "Roof", [-HL + 0.2, HL - 0.2, -HW + 0.2, HW - 0.2],
		[-HL + 8.0, HL - 7.0, -HW + 1.6, -1.6], BASE + 0.1, ROOF)
	# Glass balustrade round the roof terrace, flues and a stair strip.
	var ru0 := -HL + 8.0
	var ru1 := HL - 7.0
	var rn0 := -HW + 1.6
	var rn1 := -1.6
	for pair in [[ru0, rn0, ru1, rn0], [ru1, rn0, ru1, rn1], [ru1, rn1, ru0, rn1], [ru0, rn1, ru0, rn0]]:
		var a: Vector2 = _p(pair[0], pair[1])
		var b: Vector2 = _p(pair[2], pair[3])
		var m := (a + b) * 0.5
		var len := a.distance_to(b)
		var ang := atan2(-(b.y - a.y), b.x - a.x)
		lm.box("Glass", Vector3(m.x, ROOF + 0.55, m.y), Vector3(len, 1.1, 0.05), Basis(Vector3.UP, ang), 0.0)
	for f in [[-8.0, -4.0, 8.6], [-2.0, -3.0, 7.9], [9.0, -5.0, 8.3]]:
		var p := _p(f[0], f[1])
		lm.frustum("Flue", Vector3(p.x, ROOF, p.y), 0.22, 0.2, float(f[2]) - ROOF, 10)
	# Stair up the sea face: a strip of treads.
	for k in 14:
		var t := float(k) / 14.0
		var n := lerpf(HW - 0.4, -1.4, t)
		var y := lerpf(BASE + 0.2, ROOF, t)
		var p := _p(-HL + 9.0, n)
		lm.box("Deck", Vector3(p.x, y - 0.1, p.y), Vector3(0.5, 0.2, 2.4), Basis(Vector3.UP, atan2(AX_U.x, AX_U.y)), 0.0)
	# The sun deck on the water side with two low steps down.
	var deck := PackedVector2Array([_p(-HL - 2.0, HW), _p(HL + 4.0, HW), _p(HL + 4.0, HW + 8.0), _p(-HL - 2.0, HW + 8.0)])
	lm.poly_prism("Deck", deck, 0.0, 0.45)
	lm.poly_prism("Deck", PackedVector2Array([_p(-HL - 2.0, HW + 8.0), _p(HL + 4.0, HW + 8.0),
		_p(HL + 4.0, HW + 9.2), _p(-HL - 2.0, HW + 9.2)]), 0.0, 0.22)
	lm.commit(model)
