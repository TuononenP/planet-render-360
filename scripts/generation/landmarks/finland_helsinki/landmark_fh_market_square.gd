extends RefCounted

## Market Square (Kauppatori): Keisarinnankivi, Engel's granite obelisk of
## 1835 with its gilt double-headed eagle, and the orange-tented market
## stalls in rows. Model origin on the obelisk (OSM memorial node
## 1376320190), yaw 0 (+X east, +Z south toward the harbour).
##
## From the photos (visual-plan/refs/landmarks/market_square_helsinki/): a
## square plinth on two granite steps, a tapering four-sided shaft in pink
## grey granite under a short pyramidion, the gilt eagle with spread wings
## and two heads under a crown; the stalls are 3 x 3 m orange canopies
## (some white) on four poles over a counter with crates of produce, in
## staggered rows. The granite quay, the Cholera Basin and the paving are
## left to the terrain builder (the OSM square outline is x -93..40, z -15..21
## from the obelisk; the basin lies west at x -97..-68, z 26..96).
##
## Measured: obelisk position and the square outline (OSM). Estimated:
## obelisk height (9 m with the eagle), stall positions and sizes.

const FhU = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")

const ENTRY := {"type": "market_square_helsinki", "name": "Market Square, Helsinki", "lat": 60.1676605, "lon": 24.9544392,
	"radius_m": 1500.0, "wiki_title": "Market Square, Helsinki", "height_m": 9.0, "clear_m": 20.0,
	"kind": "Square", "aliases": ["market square, helsinki", "kauppatori", "salutorget", "keisarinnankivi", "empress stone"]}

const OBELISK := 7.4
const EAGLE := 1.6

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#9A8D88", 3.0))
	lm.use("Orange", LandmarkMaterials.paint("#E0661A", 0.7))
	lm.use("White", LandmarkMaterials.paint("#EFEDE6", 0.7))
	lm.use("Pole", LandmarkMaterials.paint("#3A3C3E", 0.6))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.use("Counter", LandmarkMaterials.pbr("wood", "#B59468", 2.0))
	lm.use("Green", LandmarkMaterials.paint("#6F9A45", 0.8, 0.0))
	lm.use("Red", LandmarkMaterials.paint("#C5432F", 0.8, 0.0))
	_obelisk(lm)
	var n := 0
	for row in 3:
		var z := 15.0 + float(row) * 9.5
		for i in 9:
			var x := -26.0 + float(i) * 6.5 + (3.2 if row % 2 == 1 else 0.0)
			_stall(lm, x, z, "Orange" if (i * 3 + row) % 4 != 3 else "White", n)
			n += 1
	lm.commit(model)

## Two granite steps, the square pedestal, the tapering shaft with its
## pyramidion and the gilt eagle.
static func _obelisk(lm: LandmarkMesh) -> void:
	FhU.blk(lm, "Granite", 0.0, 0.0, 0.0, 5.0, 0.25, 5.0)
	FhU.blk(lm, "Granite", 0.0, 0.25, 0.0, 4.0, 0.25, 4.0)
	FhU.blk(lm, "Granite", 0.0, 0.5, 0.0, 3.1, 1.1, 3.1)
	FhU.blk(lm, "Granite", 0.0, 1.6, 0.0, 3.4, 0.25, 3.4)
	lm.lathe("Granite", Vector3(0, 1.85, 0), PackedVector2Array([Vector2(1.05, 0), Vector2(0.45, OBELISK - 2.6)]),
		4, 1.0, 1.0, PI * 0.25, false)
	lm.lathe("Granite", Vector3(0, OBELISK - 0.75, 0), PackedVector2Array([Vector2(0.5, 0), Vector2(0.0, 0.75)]),
		4, 1.0, 1.0, PI * 0.25, false)
	var top := Vector3(0, OBELISK - 0.05, 0)
	# Eagle: body, two heads on short necks, spread wings, crown.
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
