class_name LandmarkTsWoldae
extends RefCounted

## Gwanghwamun's Woldae, the royal terrace restored before the gate in 2023
## (Cultural Heritage Administration: 48.7 m north-south, 29.7 m east-west,
## 0.7 m high, a 7 m royal road down its middle), in true metres on
## LandmarkMesh, north-up about its centre on OSM's terrace outline (way
## 1350696284); its north end meets the gate's front. Granite, the royal
## road a step higher and ramped down to the street, low steps either side,
## a stone balustrade (standing in for the mapped fences, the registry's
## model_rects_m) and the gate's two haetae on it. The registry reads its
## base at the centre (base_at_m), so the ground's fall along and across
## it is taken up by a deep footing and a ramp whose foot runs into the street.

const LEN := 48.7
const W := 29.7
const H := 0.7
const ROYAL_ROAD_W := 7.0
const ROYAL_ROAD_RISE := 0.12
const RAMP_LEN := 7.0
## The ramp ends this far under the base, so its foot never stands proud.
const RAMP_SINK := 0.5
const FOOT := 1.2
const STEPS := 3
const STEP_TREAD := 0.45
const POST_EVERY_M := 2.0
## The haetae either side of the royal road, metres south of the north end.
const HAETAE_X := 9.0
const HAETAE_Z := 9.0

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#C9C3B7", 3.0))
	lm.use("Paving", LandmarkMaterials.pbr("stone", "#D4CEC2", 2.0))
	var z0 := -LEN * 0.5
	var z1 := LEN * 0.5 - RAMP_LEN
	var half := W * 0.5
	var top := H + ROYAL_ROAD_RISE
	lm.box("Granite", Vector3(0, (H - FOOT) * 0.5, (z0 + z1) * 0.5), Vector3(W, H + FOOT, z1 - z0))
	lm.box("Paving", Vector3(0, H + ROYAL_ROAD_RISE * 0.5, (z0 + z1) * 0.5),
		Vector3(ROYAL_ROAD_W, ROYAL_ROAD_RISE, z1 - z0))
	# The royal road ramps to the street: a slab whose top runs from the
	# terrace's front edge down under the street RAMP_LEN south.
	var drop := top + RAMP_SINK
	var run := Vector2(RAMP_LEN, drop).length()
	var n := Vector3(0, RAMP_LEN, drop) / run
	var d := Vector3(0, -drop, RAMP_LEN) / run
	lm.box("Paving", Vector3(0, top - drop * 0.5, z1 + RAMP_LEN * 0.5) - n * 0.3,
		Vector3(ROYAL_ROAD_W, 0.6, run), Basis(Vector3.RIGHT, n, d))
	for side: float in [-1.0, 1.0]:
		var inner := side * ROYAL_ROAD_W * 0.5
		var outer := side * half
		for k in STEPS:
			var h := H * float(STEPS - k) / float(STEPS + 1)
			lm.box("Granite", Vector3((inner + outer) * 0.5, (h - FOOT) * 0.5, z1 + STEP_TREAD * (k + 0.5)),
				Vector3(absf(outer - inner), h + FOOT, STEP_TREAD))
		_balustrade(lm, Vector2(outer - side * 0.2, z0), Vector2(outer - side * 0.2, z1 - 0.2))
		_balustrade(lm, Vector2(outer - side * 0.2, z1 - 0.2), Vector2(outer - side * 3.2, z1 - 0.2))
		LandmarkGwanghwamun._haetae(lm, Vector3(side * HAETAE_X, H, z0 + HAETAE_Z))
	lm.commit(model)

## A stone balustrade along a-b on the terrace: posts every POST_EVERY_M
## on a sill, a rail along their tops.
static func _balustrade(lm: LandmarkMesh, a: Vector2, b: Vector2) -> void:
	lm.beam("Granite", Vector3(a.x, H + 0.08, a.y), Vector3(b.x, H + 0.08, b.y), 0.32, 0.16)
	lm.beam("Granite", Vector3(a.x, H + 0.72, a.y), Vector3(b.x, H + 0.72, b.y), 0.16, 0.18)
	var count := maxi(1, ceili(a.distance_to(b) / POST_EVERY_M))
	for i in count + 1:
		var p := a.lerp(b, float(i) / float(count))
		lm.box("Granite", Vector3(p.x, H + 0.45, p.y), Vector3(0.24, 0.9, 0.24))
