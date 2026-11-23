extends RefCounted

## Market Square (Kauppatori): Keisarinnankivi, Engel's granite obelisk of
## 1835 with its gilt double-headed eagle, granite sett apron, stepped
## granite quay coping with cast-iron mooring bollards, and the orange-tented
## market stalls in rows. Model origin on the obelisk (OSM memorial node
## 1376320190), yaw 0 (+X east, +Z south toward the harbour).

const FhU = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")

const ENTRY := {"type": "market_square_helsinki", "name": "Market Square, Helsinki", "lat": 60.1676605, "lon": 24.9544392,
	"radius_m": 1500.0, "wiki_title": "Market Square, Helsinki", "height_m": 9.0, "clear_m": 20.0,
	"kind": "Square", "aliases": ["market square, helsinki", "kauppatori", "salutorget", "keisarinnankivi", "empress stone"]}

const OBELISK := 7.70
const EAGLE := 1.30

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#9A8D88", 2.5))
	lm.use("Sett", LandmarkMaterials.pbr("stone", "#6B6563", 1.2))
	lm.use("Orange", LandmarkMaterials.paint("#E0661A", 0.7))
	lm.use("White", LandmarkMaterials.paint("#EFEDE6", 0.7))
	lm.use("Pole", LandmarkMaterials.paint("#2E3134", 0.55, 0.45))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.use("Counter", LandmarkMaterials.pbr("wood", "#B59468", 2.0))
	lm.use("Green", LandmarkMaterials.paint("#6F9A45", 0.8, 0.0))
	lm.use("Red", LandmarkMaterials.paint("#C5432F", 0.8, 0.0))
	_sett_apron(lm)
	_obelisk(lm)
	_quay_edge(lm)
	var n := 0
	for row in 3:
		var z := -11.0 + float(row) * 8.0
		for i in 9:
			var x := -28.0 + float(i) * 6.5 + (3.2 if row % 2 == 1 else 0.0)
			if Vector2(x, z).length() < 9.5:
				continue
			_stall(lm, x, z, "Orange" if (i * 3 + row) % 4 != 3 else "White", n)
			n += 1
	lm.commit(model)
	var warm := Color(1.0, 0.88, 0.64)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-6.2, 0.4, -6.2), Vector3(0.0, 6.6, 0.0), 34.0, 1.0, 22.0, warm],
		[Vector3(6.2, 0.4, -6.2), Vector3(0.0, 6.6, 0.0), 34.0, 1.0, 22.0, warm],
		[Vector3(-6.2, 0.4, 6.2), Vector3(0.0, 6.6, 0.0), 34.0, 1.0, 22.0, warm],
		[Vector3(6.2, 0.4, 6.2), Vector3(0.0, 6.6, 0.0), 34.0, 1.0, 22.0, warm],
	])

## Concentric granite sett apron and corner granite kerbs round Keisarinnankivi.
static func _sett_apron(lm: LandmarkMesh) -> void:
	lm.frustum("Sett", Vector3.ZERO, 8.2, 8.2, 0.04, 16)
	lm.frustum("Granite", Vector3(0, 0.04, 0), 6.2, 6.2, 0.04, 8, PI / 8.0)
	for i in 8:
		var a := TAU * float(i) / 8.0 + PI / 8.0
		var d := Vector3(cos(a), 0, sin(a))
		lm.box("Granite", d * 7.8 + Vector3(0, 0.28, 0), Vector3(0.45, 0.56, 0.45), Basis.looking_at(d))

## Granite quay steps and cast-iron mooring bollards along the harbour edge
## within clear_m (20 m).
static func _quay_edge(lm: LandmarkMesh) -> void:
	FhU.blk(lm, "Granite", 0.0, 0.0, 14.5, 24.0, 0.24, 3.2)
	FhU.blk(lm, "Sett", 0.0, 0.24, 14.2, 23.4, 0.14, 2.2)
	FhU.steps(lm, "Granite", Vector3(0.0, 0.0, 16.1), Vector3.BACK, 10.0, 0.42, 0.12, 3)
	for k in 5:
		var bx := -10.0 + float(k) * 5.0
		var bp := Vector3(bx, 0.24, 15.6)
		lm.frustum("Pole", bp, 0.20, 0.14, 0.45, 12)
		lm.frustum("Pole", bp + Vector3(0, 0.45, 0), 0.14, 0.22, 0.16, 12)
		lm.lathe("Pole", bp + Vector3(0, 0.61, 0), FhU.ball(0.18), 10)
		lm.box("Pole", bp + Vector3(0, 0.48, 0), Vector3(0.44, 0.08, 0.10), Basis(), 0.0)

## Two granite steps, the square pedestal, the tapering shaft with its
## pyramidion and the gilt eagle.
static func _obelisk(lm: LandmarkMesh) -> void:
	FhU.blk(lm, "Granite", 0.0, 0.08, 0.0, 5.0, 0.25, 5.0)
	FhU.blk(lm, "Granite", 0.0, 0.33, 0.0, 4.0, 0.25, 4.0)
	FhU.blk(lm, "Granite", 0.0, 0.58, 0.0, 3.1, 1.1, 3.1)
	FhU.blk(lm, "Granite", 0.0, 1.68, 0.0, 3.4, 0.25, 3.4)
	lm.lathe("Granite", Vector3(0, 1.93, 0), PackedVector2Array([Vector2(1.05, 0), Vector2(0.45, OBELISK - 2.68)]),
		4, 1.0, 1.0, PI * 0.25, false)
	lm.lathe("Granite", Vector3(0, OBELISK - 0.75, 0), PackedVector2Array([Vector2(0.5, 0), Vector2(0.0, 0.75)]),
		4, 1.0, 1.0, PI * 0.25, false)
	var top := Vector3(0, OBELISK - 0.05, 0)
	lm.lathe("Gold", top + Vector3(0, 0.2, 0), FhU.ball(0.28), 12, 0.8, 1.3)
	for s in [-1.0, 1.0]:
		lm.beam("Gold", top + Vector3(s * 0.12, 0.75, 0), top + Vector3(s * 0.34, 1.1, 0), 0.1, 0.1)
		lm.lathe("Gold", top + Vector3(s * 0.38, 1.0, 0), FhU.ball(0.09), 8)
		lm.beam("Gold", top + Vector3(s * 0.28, 0.55, 0), top + Vector3(s * 1.05, 0.95, 0), 0.26, 0.05)
		lm.beam("Gold", top + Vector3(s * 0.4, 0.45, 0), top + Vector3(s * 0.95, 0.5, 0), 0.22, 0.05)
	lm.box("Gold", top + Vector3(0, 1.28, 0), Vector3(0.3, 0.12, 0.12))
	lm.box("Gold", top + Vector3(0, 0.0, 0), Vector3(0.6, 0.1, 0.6))

## A stall: four poles, a gabled canopy with a scalloped white edge, a
## counter and crates of produce.
static func _stall(lm: LandmarkMesh, x: float, z: float, key: String, n: int) -> void:
	for dx in [-1.3, 1.3]:
		for dz in [-1.3, 1.3]:
			lm.box("Pole", Vector3(x + dx, 1.1, z + dz), Vector3(0.07, 2.2, 0.07), Basis(), 0.0)
	FhU.ridge_x(lm, key, key, Vector3(x, 2.2, z), 3.3, 3.2, 0.8, 0.2)
	lm.box("White", Vector3(x, 2.2, z + 1.62), Vector3(3.4, 0.22, 0.04), Basis(), 0.0)
	lm.box("White", Vector3(x, 2.2, z - 1.62), Vector3(3.4, 0.22, 0.04), Basis(), 0.0)
	lm.box("Counter", Vector3(x, 0.45, z + 0.3), Vector3(2.4, 0.9, 1.0))
	var crate := "Green" if n % 2 == 0 else "Red"
	for k in 3:
		lm.box(crate, Vector3(x - 0.8 + 0.8 * float(k), 1.0, z + 0.3), Vector3(0.55, 0.22, 0.6), Basis(), 0.0)
