extends RefCounted

## Havis Amanda (Ville Vallgren, 1908), the mermaid fountain at the head of
## Market Square. Model origin on the OSM artwork node (1376320186), yaw 0.
##
## From the photos (visual-plan/refs/landmarks/havis_amanda/): a broad
## shallow basin of polished red-pink granite on two low steps with a
## rounded rim, four bronze sea lions lying on the rim and spouting
## inward, a central mass of rock and fish heads in dark green-brown
## bronze carrying a shallow dish, and above it the slim standing nude
## figure rising from the spray (about 5 m over the pavement).
##
## Measured: position (OSM node). Estimated from the photos: basin radius
## 5.6 m, rim height 0.9 m, figure height; the casting's anatomy is
## approximated (one lathed body, limbs as beams).

const U = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")

const ENTRY := {"type": "havis_amanda", "name": "Havis Amanda", "lat": 60.1675863, "lon": 24.9513987,
	"radius_m": 1500.0, "wiki_title": "Havis Amanda", "height_m": 5.0, "clear_m": 7.0,
	"kind": "Fountain", "aliases": ["havis amanda", "havis amanda fountain", "manta helsinki"]}

const RIM := 0.9

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#A06B63", 1.2))
	lm.use("Step", LandmarkMaterials.pbr("stone", "#8E8A86", 2.0))
	lm.use("Bronze", LandmarkMaterials.paint("#3E5B4C", 0.5, 0.65))
	lm.use("Water", LandmarkMaterials.glass("#55796B"))
	# Two low paving steps and the basin: a rounded rim, the water inside.
	lm.lathe("Step", Vector3.ZERO, PackedVector2Array([Vector2(7.2, 0), Vector2(7.2, 0.14), Vector2(6.6, 0.16),
		Vector2(6.6, 0.3), Vector2(6.1, 0.32)]), 64)
	lm.lathe("Granite", Vector3(0, 0.3, 0), PackedVector2Array([Vector2(5.9, 0), Vector2(5.9, RIM - 0.3),
		Vector2(5.75, RIM - 0.08), Vector2(5.5, RIM), Vector2(5.2, RIM - 0.08), Vector2(5.15, 0.3), Vector2(5.1, 0.1)]), 64)
	lm.disc("Water", Vector3(0, RIM - 0.15, 0), Vector3.UP, 5.1, 64)
	# Rock-and-fish pedestal in the middle, then the dish under the figure.
	lm.lathe("Bronze", Vector3(0, 0.3, 0), PackedVector2Array([Vector2(1.7, 0), Vector2(1.45, 0.4), Vector2(1.7, 0.9),
		Vector2(1.2, 1.4), Vector2(1.0, 1.9), Vector2(0.8, 2.3), Vector2(0.55, 2.5)]), 32)
	lm.lathe("Bronze", Vector3(0, 2.55, 0), PackedVector2Array([Vector2(0.5, 0), Vector2(1.5, 0.12), Vector2(2.0, 0.34),
		Vector2(1.9, 0.4), Vector2(1.3, 0.3), Vector2(0.4, 0.22)]), 40)
	for i in 4:
		var a := TAU * float(i) / 4.0 + PI * 0.25
		var d := Vector3(cos(a), 0, sin(a))
		# A sea lion lying on the rim, head turned in toward the spray.
		var p := d * 4.75 + Vector3(0, RIM + 0.15, 0)
		lm.lathe("Bronze", p, U.ball(0.38), 16, 1.5, 2.2)
		lm.beam("Bronze", p + Vector3(0, 0.2, 0), p - d * 0.7 + Vector3(0, 0.05, 0), 0.4, 0.4)
		lm.beam("Bronze", p + Vector3(0, 0.25, 0), p - d * 1.0 + Vector3(0, 0.75, 0), 0.34, 0.3)
		lm.lathe("Bronze", p - d * 1.0 + Vector3(0, 0.75, 0), U.ball(0.27), 16)
		# A fish head on the rock, mouth toward the basin.
		lm.beam("Bronze", d * 0.9 + Vector3(0, 1.3, 0), d * 1.6 + Vector3(0, 1.4, 0), 0.3)
	var hip := Vector3(0.12, 3.7, 0)
	lm.beam("Bronze", Vector3(-0.12, 2.9, 0), hip + Vector3(-0.14, 0, 0), 0.18, 0.2)
	lm.beam("Bronze", Vector3(0.22, 2.9, 0), hip + Vector3(0.14, 0, 0), 0.17, 0.2)
	lm.lathe("Bronze", hip - Vector3.UP * 0.15, PackedVector2Array([Vector2(0.22, 0),
		Vector2(0.20, 0.3), Vector2(0.15, 0.55), Vector2(0.29, 0.9), Vector2(0.22, 1.05)]), 24)
	lm.frustum("Bronze", hip + Vector3(0, 0.95, 0), 0.10, 0.10, 0.25, 16)
	lm.lathe("Bronze", Vector3(0.12, 4.85, 0), U.ball(0.25), 24, 0.85, 1.0)
	lm.beam("Bronze", hip + Vector3(-0.25, 0.85, 0), hip + Vector3(-0.38, 0.12, 0.08), 0.12)
	lm.beam("Bronze", hip + Vector3(0.25, 0.85, 0), hip + Vector3(0.38, 0.15, -0.08), 0.12)
	lm.commit(model)
