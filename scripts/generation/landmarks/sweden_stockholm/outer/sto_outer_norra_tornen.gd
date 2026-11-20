class_name StoOuterNorraTornen
extends RefCounted

## Norra Tornen on Kungsholmen (OMA with Reinier de Graaf, 2020): the two
## residential towers, one grouped model. True metres from the OSM outlines
## (x east, z south from the centroid of the taller tower, no yaw: registry
## `yaw_deg` 0). Tower A (way 642654235, 125 m, 36 levels, 44 x 21 m) stands
## at the origin; tower B (way 834731659, 110 m, 33 levels, 50 x 18 m) at
## B_AT, 80 m away along the same long axis (bearing 50.85). The registry
## clears B's footprint with `clear_offsets_m` at B_AT.
##
## Facade spec, from visual-plan/refs/landmarks/norra_tornen/ (front,
## quarter, side):
## - Each tower is a stack of slabs that step in from one end as it rises
##   (full plan to 44 m, then 33 m, then 18 m long for A; the same for B at
##   40, 75 and 110 m), so the silhouette is a lopsided staircase.
## - Every face is a chessboard of deep window boxes: each storey a bay
##   3.3 m wide, a pale sandy-beige frame of ribbed pre-cast concrete
##   (about 0.9 m deep) round one big pane, the boxes alternating in
##   depth so the wall reads as stacked bricks; the glass is blue-grey.
## - The ground storey is a recessed dark-glass lobby behind slender
##   concrete piers; the roofs are flat with a glass balustrade.
## Bay widths and the step positions are scaled from the photos and the
## mapped outlines. A fifth of the panes glow warm at night.
## Surfaces (6): Frame, Wall, Glass, Lamp, Roof, Lobby.

const B_AT := Vector2(-63.5, 48.9)
const BEARING := 50.85
const BAY := 3.3
## Per tower: [centre offset along the tower's own axes (u, v), storey m,
## levels, tiers as [first level, last level + 1, u0, u1, v0, v1]].
const TOWERS := [
	{"at": Vector2(0.4, -0.3), "storey": 3.45, "levels": 36,
		"tiers": [[0, 13, -22.0, 22.5, -10.6, 10.6], [13, 24, -22.0, 11.0, -10.6, 10.6],
			[24, 36, -22.0, -4.0, -10.6, 9.0]]},
	{"at": Vector2(-63.5, 48.9), "storey": 3.3, "levels": 33,
		"tiers": [[0, 12, -25.2, 25.2, -8.95, 8.95], [12, 22, -25.2, 6.0, -8.95, 8.95],
			[22, 33, -25.2, -8.0, -8.95, 8.95]]},
]
const GROUND := 5.0

static var _u := Vector2(sin(deg_to_rad(BEARING)), -cos(deg_to_rad(BEARING)))
static var _v := Vector2(cos(deg_to_rad(BEARING)), sin(deg_to_rad(BEARING)))

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Frame", LandmarkMaterials.pbr("concrete", "#B9A689", 2.0, 0.85))
	lm.use("Wall", LandmarkMaterials.pbr("concrete", "#A59478", 3.0))
	lm.use("Glass", LandmarkMaterials.paint("#657B8C", 0.2, 0.0))
	lm.use("Lamp", LandmarkMaterials.lit("#FFD79A", 0.25))
	lm.use("Roof", LandmarkMaterials.pbr("concrete", "#6E6C68", 4.0))
	lm.use("Lobby", LandmarkMaterials.glass("#1F2A30"))
	for t in TOWERS.size():
		_tower(lm, TOWERS[t], t)
	lm.commit(model, "Norra_tornen_")

## World point of tower-local (u, v) about `at`.
static func _w(at: Vector2, u: float, v: float) -> Vector2:
	return at + _u * u + _v * v

static func _poly(at: Vector2, u0: float, u1: float, v0: float, v1: float) -> PackedVector2Array:
	return PackedVector2Array([_w(at, u0, v0), _w(at, u1, v0), _w(at, u1, v1), _w(at, u0, v1)])

static func _tower(lm: LandmarkMesh, tw: Dictionary, idx: int) -> void:
	var at: Vector2 = tw["at"]
	var st: float = tw["storey"]
	var tiers: Array = tw["tiers"]
	for k in tiers.size():
		var t: Array = tiers[k]
		var y0 := GROUND if k == 0 else float(t[0]) * st
		var y1 := float(t[1]) * st
		var u0: float = t[2]
		var u1: float = t[3]
		var v0: float = t[4]
		var v1: float = t[5]
		# Wall core, set back from the frame faces.
		lm.poly_prism("Wall", _poly(at, u0 + 0.3, u1 - 0.3, v0 + 0.3, v1 - 0.3), y0, y1, false)
		lm.poly_prism("Roof", _poly(at, u0, u1, v0, v1), y1, y1 + 0.05, true)
		_roof_edge(lm, at, u0, u1, v0, v1, y1, k == tiers.size() - 1, tiers, k)
		for fi in 4:
			_face(lm, at, st, idx, k, fi, u0, u1, v0, v1, y0, y1)
	_lobby(lm, at, tiers[0] as Array)

## Glass balustrade round a roof (the highest roof also gets a plant box).
static func _roof_edge(lm: LandmarkMesh, at: Vector2, u0: float, u1: float, v0: float, v1: float,
		y: float, topmost: bool, _tiers: Array, _k: int) -> void:
	var ring := _poly(at, u0, u1, v0, v1)
	lm.poly_prism("Frame", F.offset(ring, -0.05), y, y + 0.8, false)
	if topmost:
		var c := _w(at, (u0 + u1) * 0.5, (v0 + v1) * 0.5)
		lm.box("Roof", Vector3(c.x, y + 0.55, c.y), Vector3(minf(8.0, u1 - u0 - 2.0), 1.1, 5.0),
			Basis(Vector3(_u.x, 0, _u.y), Vector3.UP, Vector3(-_u.y, 0, _u.x)), 0.0)

## One face of a tier: the chessboard of window boxes. Face 0..3 = the +v,
## -v, +u and -u sides.
static func _face(lm: LandmarkMesh, at: Vector2, st: float, idx: int, k: int, fi: int,
		u0: float, u1: float, v0: float, v1: float, y0: float, y1: float) -> void:
	var along: Vector2
	var out: Vector2
	var a: Vector2
	var length: float
	match fi:
		0:
			along = _u
			out = _v
			a = _w(at, u0, v1)
			length = u1 - u0
		1:
			along = _u
			out = -_v
			a = _w(at, u0, v0)
			length = u1 - u0
		2:
			along = _v
			out = _u
			a = _w(at, u1, v0)
			length = v1 - v0
		_:
			along = _v
			out = -_u
			a = _w(at, u0, v0)
			length = v1 - v0
	var n := maxi(2, int(length / BAY))
	var bay := length / float(n)
	var rows := int(round((y1 - y0) / st))
	var o3 := Vector3(out.x, 0, out.y)
	var basis := Basis(Vector3(o3.z, 0, -o3.x), Vector3.UP, o3)
	var a3 := Vector3(along.x, 0, along.y)
	for r in rows:
		var yc := y0 + (float(r) + 0.5) * st
		for c in n:
			var deep := (r + c + fi + k) % 2 == 0
			var depth := 0.95 if deep else 0.35
			var p := a + along * (float(c) + 0.5) * bay + out * (depth * 0.5 - 0.3)
			lm.box("Frame", Vector3(p.x, yc, p.y), Vector3(bay - 0.3, st - 0.3, depth), basis, 0.0)
			var f := Vector3(p.x, yc, p.y) + o3 * (depth * 0.5 + 0.01)
			var key := "Lamp" if (r * 7 + c * 3 + fi + idx) % 8 == 0 else "Glass"
			var hw := a3 * (bay - 1.3) * 0.5
			var hh := Vector3(0, (st - 1.2) * 0.5, 0)
			lm.quad(key, f - hw - hh, f + hw - hh, f + hw + hh, f - hw + hh, o3)

## Recessed dark lobby ring with slender piers.
static func _lobby(lm: LandmarkMesh, at: Vector2, t: Array) -> void:
	var u0: float = t[2]
	var u1: float = t[3]
	var v0: float = t[4]
	var v1: float = t[5]
	lm.poly_prism("Lobby", _poly(at, u0 + 0.6, u1 - 0.6, v0 + 0.6, v1 - 0.6), 0.0, GROUND, false)
	for s in [v0 + 0.5, v1 - 0.5]:
		var n := int((u1 - u0) / 5.5)
		for i in n + 1:
			var c := _w(at, u0 + 0.5 + (u1 - u0 - 1.0) * float(i) / float(n), float(s))
			lm.frustum("Frame", Vector3(c.x, 0.0, c.y), 0.28, 0.28, GROUND, 8)

const F = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_mall_footprints.gd")
