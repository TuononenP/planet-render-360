extends RefCounted

## amos_rex. Registry entry and model in one file.

const U = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")

## Amos Rex (JKMM, 2018), the five paver-clad concrete mounds on Lasipalatsi
## Square that light the galleries below. Numbers are from the legacy model
## (an approximation round the mapped place; Amos Rex itself is underground,
## so there is no OSM or LoD2 footprint); the grey paver colour is read
## from the Commons photo (visual-plan/refs/landmarks/amos_rex/aerial.jpg).
## The mounds there are steeper-sided with a long gentle run to one side:
## still approximated as domes here (estimated, not measured).

const ENTRY := {"type": "amos_rex", "name": "Amos Rex", "lat": 60.17008, "lon": 24.93604,
	"radius_m": 1500.0, "wiki_title": "Amos Rex", "height_m": 6.35, "clear_m": 43.0,
	"yaw_deg": -3.0, "kind": "Museum", "aliases": ["amos rex", "amos rex museum", "amos rex museo"]}

## Five low concrete light scoops; each has an offset circular skylight.
static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("concrete", "#A8A8A4", 1.6))
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#92908A", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#E8E3D4", 2.0))
	lm.use("Glass", LandmarkMaterials.glass())
	U.blk(lm, "Stone", 0, 0, 0, 67.0, 0.15, 53.0)
	for dome in [[-18.0, -11.0, 10.0, 5.0], [5.0, -13.0, 9.0, 4.2],
			[20.0, 5.0, 7.0, 3.0], [-1.0, 11.0, 11.0, 6.0], [-23.0, 13.0, 6.0, 2.7]]:
		var base := Vector3(float(dome[0]), 0.15, float(dome[1]))
		var r := float(dome[2])
		var h := float(dome[3])
		var rings: Array = []
		for j in 13:
			var t := float(j) / 12.0
			var ring := PackedVector3Array()
			var rad := lerpf(r, 1.7, t)
			for k in 49:
				var a := TAU * float(k) / 48.0
				ring.append(base + Vector3(cos(a) * rad + t * 2.2,
					h * sin(t * PI * 0.5), sin(a) * rad))
			rings.append(ring)
		lm.grid("Wall", rings, base + Vector3(0, -2, 0), true)
		var top := base + Vector3(2.2, h, 0)
		lm.frustum("Trim", top, 1.85, 1.85, 0.20, 48)
		lm.disc("Glass", top + Vector3.UP * 0.21, Vector3.UP, 1.62, 48)
	lm.commit(model)
