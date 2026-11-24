extends RefCounted

## Three Smiths Statue — Kolmen sepän patsas (Felix Nylund, 1932),
## Kolmensepänaukio outside Stockmann on Mannerheimintie / Aleksanterinkatu.
##
## Circular stepped grey-granite sett island, Felix Nylund's round tapering
## red-granite pedestal encircled by the gilt-inscribed `PRO HUMANITATE` band,
## and three high-resolution muscular nude bronze blacksmiths hammering a
## forged-iron horn anvil to exact 4.8 m.

const ASSET_DIR := "res://assets/landmarks/helsinki_3d/"

const ENTRY := {"type": "three_smiths_statue", "name": "Three Smiths Statue",
	"lat": 60.1686688, "lon": 24.9409553, "radius_m": 1500.0,
	"wiki_title": "Three Smiths Statue", "height_m": 4.8, "clear_m": 6.5,
	"yaw_deg": 0.0, "kind": "Monument", "secondary": true,
	"aliases": ["three smiths statue", "three smiths", "kolmen sepän patsas", "tre smeder"]}

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#7E7770", 2.0))
	lm.use("RedGranite", LandmarkMaterials.pbr("stone", "#8C4A40", 1.8))
	lm.use("Bronze", LandmarkMaterials.paint("#2B3B33", 0.38, 0.70))
	lm.use("Gold", LandmarkMaterials.gold())

	# Stepped circular granite sett island
	lm.frustum("Granite", Vector3.ZERO, 3.8, 3.8, 0.18, 28)
	lm.frustum("Granite", Vector3(0.0, 0.18, 0.0), 3.1, 3.1, 0.18, 28)
	# Round tapering red-granite pedestal with recessed PRO HUMANITATE inscription band
	lm.lathe("RedGranite", Vector3(0.0, 0.36, 0.0), PackedVector2Array([
		Vector2(1.58, 0.0), Vector2(1.55, 0.25), Vector2(1.42, 0.35),
		Vector2(1.30, 1.50), Vector2(1.25, 1.52), Vector2(1.25, 1.80),
		Vector2(1.34, 1.84), Vector2(1.32, 2.06), Vector2(0.0, 2.06),
	]), 28)
	# Gilt Latin inscription segments ("MONUMENTUM – CURAVIT – LEGATUM – J. TALLBERG – PRO HUMANITATE")
	for k in 18:
		var a := TAU * float(k) / 18.0
		var p := Vector3(cos(a) * 1.27, 2.02, sin(a) * 1.27)
		lm.box("Gold", p, Vector3(0.28, 0.10, 0.03), Basis(Vector3.UP, -a + PI * 0.5), 0.0)

	# Three high-resolution muscular bronze smiths + horn anvil + sledgehammers (2.42..4.80 m exact!)
	SculptureKit.stamp_path(lm, "Bronze", ASSET_DIR + "three_smiths_group.glb",
		Vector3(0.0, 2.42, 0.0), Vector3.ONE, 0.0)
	lm.commit(model)

	var warm := Color(1.0, 0.88, 0.66)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-3.6, 0.4, 3.6), Vector3(0.0, 3.4, 0.0), 44.0, 0.90, 14.0, warm],
		[Vector3(3.6, 0.4, -3.6), Vector3(0.0, 3.4, 0.0), 44.0, 0.90, 14.0, warm],
	])
