class_name LandmarkTsPalaceWalls
extends RefCounted

## Gyeongbokgung's front walls (gungjang) either side of Gwanghwamun, in
## true metres on LandmarkMesh, north-up about the registry site on the
## wall line 7 m south of Gwanghwamun's site (the gate itself is the core
## LandmarkGwanghwamun). The runs follow OSM ways 279963627 (west, the
## city_wall from the west corner) and 370282518 (east, round the cut
## corner towards Dongsipjagak), 4 m tall as tagged: a footing, coursed
## granite, a plastered band and the tiled coping with its ridge roll.
## Each run ends where OSM ends it (x -22.9 west, +8.1 east), inside the
## 35 m platform of the gate model, which stands on the OSM gatehouse
## centre (way 170199440, x -7.3, 1 m south of this site).

const H := 4.0
const WEST := [Vector2(-229.3, -113.3), Vector2(-221.7, -54.2), Vector2(-216.6, -17.7), Vector2(-216.5, -16.7),
	Vector2(-203.6, -7.7), Vector2(-194.3, -7.5), Vector2(-155.3, -5.2), Vector2(-128.1, -3.9),
	Vector2(-62.1, -0.5), Vector2(-22.9, 0.7)]
const EAST := [Vector2(8.1, 3.2), Vector2(18.0, 3.1), Vector2(91.3, 1.3), Vector2(112.3, 0.7),
	Vector2(127.0, -0.3), Vector2(150.0, -4.3), Vector2(173.0, -7.8), Vector2(196.4, -39.6),
	Vector2(213.3, -57.6), Vector2(213.3, -69.3)]

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#B4ADA2", 3.0))
	lm.use("Plaster", LandmarkMaterials.pbr("render", "#D9CDB8", 3.0))
	lm.use("Tiles", LandmarkMaterials.pbr("slate", "#4A4E52", 1.5))
	lm.use("Footing", LandmarkMaterials.pbr("stone", "#8C877E", 3.0))
	for run in [WEST, EAST]:
		_run(lm, run)
	lm.commit(model)

## One wall run along `pts`: each segment as its own courses, and a pier
## at every bend so the corners close.
static func _run(lm: LandmarkMesh, pts: Array) -> void:
	for i in pts.size() - 1:
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[i + 1]
		var length := a.distance_to(b)
		if length < 0.3:
			continue
		var d := Vector3(b.x - a.x, 0, b.y - a.y).normalized()
		var basis := Basis(d, Vector3.UP, d.cross(Vector3.UP).normalized())
		var mid := Vector3((a.x + b.x) * 0.5, 0, (a.y + b.y) * 0.5)
		lm.box("Footing", mid + Vector3(0, -0.4, 0), Vector3(length, 1.2, 2.4), basis)
		lm.box("Granite", mid + Vector3(0, 1.3, 0), Vector3(length, 2.6, 2.0), basis)
		lm.box("Plaster", mid + Vector3(0, 2.95, 0), Vector3(length, 0.7, 1.7), basis)
		lm.gable("Tiles", mid + Vector3(0, 3.3, 0), 2.2, length, 0.55, Basis(d.cross(Vector3.UP).normalized(),
			Vector3.UP, -d), 0.25, "Plaster")
		lm.beam("Tiles", Vector3(a.x, 3.85, a.y), Vector3(b.x, 3.85, b.y), 0.3, 0.3)
	for p in pts.slice(1, pts.size() - 1):
		var v := p as Vector2
		lm.box("Granite", Vector3(v.x, 1.3, v.y), Vector3(2.0, 2.6, 2.0))
		lm.box("Plaster", Vector3(v.x, 2.95, v.y), Vector3(1.7, 0.7, 1.7))
		lm.frustum("Tiles", Vector3(v.x, 3.3, v.y), 1.6, 0.2, 0.7, 4, PI * 0.25)
