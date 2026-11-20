extends RefCounted

## Naturhistoriska riksmuseet (Swedish Museum of Natural History, Axel
## Lindegren and Gustaf Sandström, 1916), Frescati. Origin at the centroid of
## OSM relation 3723258 (9,870 m2), long front wing along +X (bearing 75,
## registry yaw -15), front +Z (the entrance side, SSE, toward the grass
## terrace and the obelisk).
##
## Plan, traced from the relation's outline in the model frame:
## - the front wing (x -68..66.5, z 64..82), eaves 17 m, with the stone
##   portal and the great arched stair window over it at its centre, a
##   copper-lanterned tower at the east end and a corner turret at the west;
## - the spine behind the west half (x -22..-5.5, z -55..66), eaves 19 m,
##   carrying the big square dome tower where it meets the rear-left wing
##   (x -70..-24, z -71..-54, eaves 15 m); the rear tail (x -24.5..-8,
##   z -118..-71, eaves 14 m) ends in a smaller domed turret;
## - the central block (x -5.7..50, z -32..14, eaves 17 m) with the
##   Cosmonova octagon, a low dark domed drum, on its courtyard side.
##
## Reddish-brown brick with pale sandstone trim, steep dark slate hips with
## green copper ridges and gutters, and bronze-grey copper domes with green
## lanterns. The dome tower (15 x 15 m) rises sheer to a stepped
## sandstone parapet at 30 m, then a windowed 12-sided drum with clock
## faces, the dome and a lantern with a finial at 50 m.
##
## Sources: OSM relation 3723258 (building=museum, levels 4, start 1916,
## brick), the Commons photos in
## visual-plan/refs/landmarks/naturhistoriska_riksmuseet/ (front.jpg: the
## dome tower and stone portal; aerial.jpg: the wing plan, the Cosmonova
## drum and the lantern towers). Eave and tower heights are scaled from
## front.jpg against the 17 m front-wing eaves; window counts are
## approximate.

const Far = preload("res://scripts/generation/landmarks/sweden_stockholm/outer/sto_far_kit.gd")

const TOWER_C := Vector2(-13.8, -60.0)
const COSMO_C := Vector2(30.4, 31.0)

## [cx, cz, w, d, eave height, roof inset, roof rise].
const WINGS := [
	[-0.8, 73.0, 134.6, 18.0, 17.0, 7.5, 6.5],
	[-13.75, 5.7, 16.5, 120.6, 19.0, 6.5, 6.0],
	[22.3, -8.9, 55.9, 46.3, 17.0, 9.0, 6.0],
	[-47.0, -62.5, 45.7, 16.7, 15.0, 6.0, 5.5],
	[-16.3, -94.5, 16.3, 47.0, 14.0, 6.0, 5.0],
	[-4.0, -82.5, 8.3, 55.0, 12.0, 3.5, 3.0],
]

static func build(model: Node3D) -> void:
	var lm := Far.fresh(_materials())
	for w in WINGS:
		_wing(lm, w)
	_cosmonova(lm)
	_front(lm)
	_dome_tower(lm)
	_turrets(lm)
	lm.commit(model)

static func _materials() -> Dictionary:
	return {
		"Brick": LandmarkMaterials.pbr("brick", "#8C4D3C", 3.0),
		"Stone": LandmarkMaterials.pbr("limestone", "#CDB892", 2.6),
		"Granite": LandmarkMaterials.pbr("stone", "#8C877F", 3.0),
		"Slate": LandmarkMaterials.pbr("slate", "#32373B", 2.5),
		"Dome": LandmarkMaterials.pbr("copper", "#5D5F58", 2.0),
		"Copper": LandmarkMaterials.pbr("copper", "#5A8670", 2.0),
		"Glass": LandmarkMaterials.glass("#2A3236"),
	}

## One range: brick walls, window rows, sandstone string courses and
## eave band, steep slate hip.
static func _wing(lm: LandmarkMesh, w: Array) -> void:
	var poly := Far.rect(float(w[0]), float(w[1]), float(w[2]), float(w[3]))
	var eave: float = w[4]
	lm.poly_prism("Brick", poly, 0.0, eave, false)
	var rows := 3 if eave >= 16.0 else 2
	var pitch := (eave - 5.0) / float(rows)
	Far.windows(lm, "Glass", poly, 2.2, rows, pitch, 4.8, 1.9, pitch - 1.6, 7.0)
	Far.band(lm, "Granite", poly, 0.0, 1.3, 0.25)
	Far.band(lm, "Stone", poly, 6.2, 0.4, 0.2)
	Far.band(lm, "Stone", poly, eave - 0.9, 0.9, 0.5)
	Far.hip_roof(lm, "Slate", poly, eave, float(w[5]), float(w[6]))
	# Green copper ridge line along the long axis.
	var ridge_y := eave + float(w[6])
	if float(w[2]) >= float(w[3]):
		lm.box("Copper", Vector3(float(w[0]), ridge_y + 0.1, float(w[1])),
			Vector3(float(w[2]) - float(w[5]) * 2.0, 0.3, 0.5), Basis(), 0.0)
	else:
		lm.box("Copper", Vector3(float(w[0]), ridge_y + 0.1, float(w[1])),
			Vector3(0.5, 0.3, float(w[3]) - float(w[5]) * 2.0), Basis(), 0.0)

## Cosmonova: the dark octagonal drum on the central block's courtyard side.
static func _cosmonova(lm: LandmarkMesh) -> void:
	var c := Vector3(COSMO_C.x, 0.0, COSMO_C.y)
	lm.lathe("Brick", c, PackedVector2Array([Vector2(15.6, 0), Vector2(15.6, 12.0)]), 8, 1.0, 1.0,
		PI / 8.0, false)
	lm.lathe("Slate", c + Vector3(0, 12.0, 0), PackedVector2Array([Vector2(16.2, 0), Vector2(14.0, 2.0),
		Vector2(8.0, 4.6), Vector2(1.0, 6.0)]), 8, 1.0, 1.0, PI / 8.0, false)

## The front wing's centre: the stone portal with its steps and the great
## arched window gable on the roof above it.
static func _front(lm: LandmarkMesh) -> void:
	var zf := 82.0
	lm.box("Stone", Vector3(-0.8, 6.5, zf + 1.4), Vector3(9.0, 13.0, 2.8), Basis(), 0.0)
	lm.box("Granite", Vector3(-0.8, 0.4, zf + 4.5), Vector3(13.0, 0.8, 3.4), Basis(), 0.0)
	lm.box("Granite", Vector3(-0.8, 0.9, zf + 3.4), Vector3(11.0, 0.8, 2.0), Basis(), 0.0)
	lm.box("Glass", Vector3(-0.8, 4.2, zf + 2.85), Vector3(3.2, 6.0, 0.2), Basis(), 0.0)
	lm.box("Stone", Vector3(-0.8, 13.4, zf + 1.4), Vector3(10.0, 0.8, 3.2), Basis(), 0.0)
	# The great arched window: a stone frame rising through the roof.
	lm.box("Stone", Vector3(-0.8, 21.5, zf - 3.0), Vector3(15.0, 9.0, 1.4), Basis(), 0.0)
	lm.box("Glass", Vector3(-0.8, 20.5, zf - 2.25), Vector3(11.0, 6.5, 0.2), Basis(), 0.0)
	lm.lathe("Copper", Vector3(-0.8, 25.9, zf - 3.0), PackedVector2Array([Vector2(7.5, 0), Vector2(6.4, 1.5),
		Vector2(3.6, 2.6), Vector2(0.5, 3.0)]), 16, 1.0, 0.18)

## The big square dome tower: brick shaft, stepped sandstone parapet,
## windowed drum, bronze dome, green lantern and finial (top 50 m).
static func _dome_tower(lm: LandmarkMesh) -> void:
	var c := TOWER_C
	var shaft := PackedVector2Array([Vector2(c.x - 7.5, c.y - 7.5), Vector2(c.x + 7.5, c.y - 7.5),
		Vector2(c.x + 7.5, c.y + 7.5), Vector2(c.x - 7.5, c.y + 7.5)])
	lm.poly_prism("Brick", shaft, 0.0, 29.0, false)
	Far.windows(lm, "Glass", shaft, 21.0, 1, 4.0, 3.0, 1.6, 3.2, 6.0)
	Far.band(lm, "Stone", shaft, 27.0, 1.2, 0.5)
	lm.poly_prism("Stone", PackedVector2Array([Vector2(c.x - 8.2, c.y - 8.2), Vector2(c.x + 8.2, c.y - 8.2),
		Vector2(c.x + 8.2, c.y + 8.2), Vector2(c.x - 8.2, c.y + 8.2)]), 29.0, 30.4, true)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			lm.box("Stone", Vector3(c.x + float(sx) * 7.3, 31.4, c.y + float(sz) * 7.3), Vector3(2.0, 2.0, 2.0),
				Basis(), 0.0)
	var base := Vector3(c.x, 30.4, c.y)
	lm.lathe("Brick", base, PackedVector2Array([Vector2(5.9, 0), Vector2(5.9, 9.0)]), 12, 1.0, 1.0, 0.0, false)
	lm.lathe("Stone", base + Vector3(0, 9.0, 0), PackedVector2Array([Vector2(6.3, 0), Vector2(6.3, 1.0)]), 12,
		1.0, 1.0, 0.0, false)
	for k in 6:
		var a := TAU * (float(k) + 0.5) / 6.0
		lm.box("Glass", base + Vector3(cos(a) * 5.95, 4.8, sin(a) * 5.95), Vector3(0.2, 4.0, 1.8),
			Basis(Vector3.UP, -a + PI * 0.5), 0.0)
	var dome := PackedVector2Array([Vector2(6.4, 0), Vector2(6.1, 1.6), Vector2(5.0, 3.6), Vector2(3.4, 5.2),
		Vector2(1.9, 6.0), Vector2(1.4, 6.2)])
	lm.lathe("Dome", base + Vector3(0, 10.0, 0), dome, 16)
	lm.lathe("Copper", base + Vector3(0, 16.2, 0), PackedVector2Array([Vector2(1.5, 0), Vector2(1.5, 1.8),
		Vector2(0.9, 2.4), Vector2(0.1, 3.0)]), 8)
	lm.box("Copper", base + Vector3(0, 19.7, 0), Vector3(0.16, 0.9, 0.16), Basis(), 0.0)

## The corner and end turrets: brick shaft, stepped crown, small copper dome.
static func _turrets(lm: LandmarkMesh) -> void:
	# [x, z, size, shaft height, dome rise]
	for t in [[60.0, 73.0, 8.0, 27.0, 5.5], [-65.0, 78.0, 6.0, 21.0, 3.5], [-10.0, 22.0, 7.0, 25.0, 4.5],
			[-16.3, -112.0, 8.0, 22.0, 4.5]]:
		var s: float = t[2]
		var p := PackedVector2Array([Vector2(t[0] - s * 0.5, t[1] - s * 0.5), Vector2(t[0] + s * 0.5, t[1] - s * 0.5),
			Vector2(t[0] + s * 0.5, t[1] + s * 0.5), Vector2(t[0] - s * 0.5, t[1] + s * 0.5)])
		lm.poly_prism("Brick", p, 0.0, float(t[3]), false)
		Far.band(lm, "Stone", p, float(t[3]) - 1.0, 1.0, 0.4)
		lm.box("Stone", Vector3(t[0], float(t[3]) + 0.2, t[1]), Vector3(s + 1.0, 0.4, s + 1.0), Basis(), 0.0)
		var top := float(t[3]) + 0.4
		lm.lathe("Copper", Vector3(t[0], top, t[1]), PackedVector2Array([Vector2(s * 0.55, 0),
			Vector2(s * 0.5, float(t[4]) * 0.4), Vector2(s * 0.3, float(t[4]) * 0.8), Vector2(0.1, float(t[4]))]), 12)
