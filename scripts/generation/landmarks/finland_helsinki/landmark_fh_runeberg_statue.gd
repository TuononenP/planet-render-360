extends RefCounted

## Runeberg Statue (Walter Runeberg, 1885), on the Esplanadi central walk.
##
## Stepped grey granite paving platform surrounded by a cast-iron floral
## perimeter fence, tall moulded red-granite pedestal, the bronze Maiden of
## Finland (Suomi-neito) holding a wreath on the front ledge, and Johan Ludvig
## Runeberg's standing bronze figure atop the pedestal at 8.0 m.

const U = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")

const ENTRY := {"type": "runeberg_statue", "name": "Runeberg Statue", "lat": 60.16750, "lon": 24.94760,
	"radius_m": 1500.0, "wiki_title": "Statue of Johan Ludvig Runeberg", "height_m": 8.0, "clear_m": 8.0,
	"yaw_deg": 0.0, "kind": "Monument", "secondary": true,
	"aliases": ["runeberg statue", "johan ludvig runeberg statue", "runebergin patsas", "runebergsstatyn"]}

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#8C534A", 1.8))
	lm.use("Step", LandmarkMaterials.pbr("stone", "#868480", 2.0))
	lm.use("Bronze", LandmarkMaterials.paint("#3E584A", 0.45, 0.65))
	lm.use("Iron", LandmarkMaterials.paint("#24282A", 0.5, 0.55))
	lm.use("Gold", LandmarkMaterials.gold())
	_platform_and_fence(lm)
	_pedestal_and_statues(lm)
	lm.commit(model)
	var warm := Color(1.0, 0.88, 0.64)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-4.2, 0.4, 4.2), Vector3(0.0, 5.2, 0.0), 42.0, 0.9, 14.0, warm],
		[Vector3(4.2, 0.4, 4.2), Vector3(0.0, 5.2, 0.0), 42.0, 0.9, 14.0, warm],
		[Vector3(-4.2, 0.4, -4.2), Vector3(0.0, 5.2, 0.0), 42.0, 0.8, 14.0, warm],
		[Vector3(4.2, 0.4, -4.2), Vector3(0.0, 5.2, 0.0), 42.0, 0.8, 14.0, warm],
	])

static func _platform_and_fence(lm: LandmarkMesh) -> void:
	lm.frustum("Step", Vector3.ZERO, 4.8, 4.8, 0.22, 8, PI / 8.0)
	lm.frustum("Step", Vector3(0, 0.22, 0), 4.2, 4.2, 0.20, 8, PI / 8.0)
	# Cast-iron floral perimeter fence around the octagonal platform.
	var r := 4.0
	for k in 8:
		var a0 := TAU * float(k) / 8.0 + PI / 8.0
		var a1 := TAU * float(k + 1) / 8.0 + PI / 8.0
		var p0 := Vector3(cos(a0) * r, 0.42, sin(a0) * r)
		var p1 := Vector3(cos(a1) * r, 0.42, sin(a1) * r)
		lm.frustum("Iron", p0, 0.09, 0.07, 1.05, 8)
		lm.lathe("Iron", p0 + Vector3(0, 1.05, 0), U.ball(0.09), 8)
		lm.beam("Iron", p0 + Vector3(0, 0.22, 0), p1 + Vector3(0, 0.22, 0), 0.05, 0.05)
		lm.beam("Iron", p0 + Vector3(0, 0.82, 0), p1 + Vector3(0, 0.82, 0), 0.06, 0.06)
		for j in range(1, 5):
			var bp := p0.lerp(p1, float(j) / 5.0)
			lm.frustum("Iron", bp + Vector3(0, 0.22, 0), 0.025, 0.02, 0.72, 6)

static func _pedestal_and_statues(lm: LandmarkMesh) -> void:
	# Stepped red granite pedestal + front ledge for Suomi-neito.
	U.blk(lm, "Granite", 0.0, 0.42, 0.3, 3.2, 0.45, 3.6)
	U.blk(lm, "Granite", 0.0, 0.87, 1.35, 1.6, 0.65, 1.2)
	U.blk(lm, "Granite", 0.0, 0.87, 0.0, 2.4, 0.55, 2.4)
	lm.frustum("Granite", Vector3(0, 1.42, 0), 1.15, 0.96, 3.0, 4, PI * 0.25)
	U.blk(lm, "Granite", 0.0, 4.42, 0.0, 2.25, 0.38, 2.25)
	# Gilded inscription plaque and bronze laurel wreath on the pedestal front.
	lm.box("Gold", Vector3(0.0, 3.1, 0.88), Vector3(0.95, 0.55, 0.06), Basis(), 0.0)
	lm.lathe("Bronze", Vector3(0.0, 2.35, 0.90), U.ball(0.24), 10, 1.0, 0.3)
	# Maiden of Finland (Suomi-neito) holding a laurel wreath on the lower ledge.
	LandmarkKits.statue_figure(lm, "Bronze", Vector3(0.0, 1.52, 1.35), 2.35, true)
	# Johan Ludvig Runeberg standing atop the pedestal to exact 8.0 m.
	LandmarkKits.statue_figure(lm, "Bronze", Vector3(0.0, 4.80, 0.0), 3.20, false)
