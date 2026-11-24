extends RefCounted

## Runeberg Statue (Walter Runeberg, 1885), on the Esplanadi central walk.
##
## Stepped octagonal grey-granite platform surrounded by an ornate cast-iron
## floral perimeter fence, tall moulded red-granite pedestal with gilt bronze
## inscription & laurel wreath, high-resolution Maiden of Finland (Suomi-neito)
## holding the Maamme tablet on the lower front ledge, and bareheaded frock-
## coated Johan Ludvig Runeberg atop the pedestal at exact 8.0 m.

const U = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")
const ASSET_DIR := "res://assets/landmarks/helsinki_3d/"

const ENTRY := {"type": "runeberg_statue", "name": "Runeberg Statue", "lat": 60.16750, "lon": 24.94760,
	"radius_m": 1500.0, "wiki_title": "Statue of Johan Ludvig Runeberg", "height_m": 8.0, "clear_m": 8.0,
	"yaw_deg": 0.0, "kind": "Monument", "secondary": true,
	"aliases": ["runeberg statue", "johan ludvig runeberg statue", "runebergin patsas", "runebergsstatyn"]}

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#8C4B42", 1.8))
	lm.use("Step", LandmarkMaterials.pbr("stone", "#868480", 2.0))
	lm.use("Bronze", LandmarkMaterials.paint("#2F463B", 0.38, 0.68))
	lm.use("Iron", LandmarkMaterials.paint("#222628", 0.48, 0.58))
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
		for j in range(1, 6):
			var bp := p0.lerp(p1, float(j) / 6.0)
			lm.frustum("Iron", bp + Vector3(0, 0.22, 0), 0.025, 0.018, 0.72, 6)
			lm.frustum("Gold", bp + Vector3(0, 0.94, 0), 0.03, 0.005, 0.10, 6)

static func _pedestal_and_statues(lm: LandmarkMesh) -> void:
	# Moulded red-granite stepped pedestal + lower front ledge for Suomi-neito
	U.blk(lm, "Granite", 0.0, 0.42, 0.3, 3.2, 0.45, 3.6)
	U.blk(lm, "Granite", 0.0, 0.87, 1.35, 1.6, 0.65, 1.2)
	U.blk(lm, "Granite", 0.0, 0.87, 0.0, 2.5, 0.55, 2.5)
	lm.frustum("Granite", Vector3(0, 1.42, 0), 1.18, 0.98, 2.95, 4, PI * 0.25)
	U.blk(lm, "Granite", 0.0, 4.37, 0.0, 2.35, 0.43, 2.35)
	# Gilt inscription lines & bronze laurel wreath on pedestal front
	for row in 3:
		lm.box("Gold", Vector3(0.0, 3.35 - float(row) * 0.18, 0.88),
			Vector3(0.95 - float(row % 2) * 0.22, 0.06, 0.04), Basis(), 0.0)
	SculptureKit.stamp_path(lm, "Bronze", ASSET_DIR + "suomi_neito.glb",
		Vector3(0.0, 1.52, 1.38), Vector3.ONE, 0.0)
	SculptureKit.stamp_path(lm, "Bronze", ASSET_DIR + "runeberg_poet.glb",
		Vector3(0.0, 4.80, 0.0), Vector3.ONE, 0.0)
