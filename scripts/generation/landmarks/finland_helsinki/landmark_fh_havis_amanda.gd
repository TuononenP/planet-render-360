extends RefCounted

## Havis Amanda (Ville Vallgren, 1908), the Art Nouveau mermaid fountain at the
## head of Helsinki Market Square. Model origin on OSM artwork node 1376320186.
##
## Uses the authentic Vehmaa red-granite stepped circular basin & upper saucer
## bowl with the real laser-scanned bronze Havis Amanda mermaid + 4 sea-fish
## (`havis_amanda_figure.glb`) and 4 real bronze rim sea lions (`sea_lion.glb`,
## FGI / Aalto University CC-BY-4.0 scan, DOI 10.5281/zenodo.3768777) paired with
## GPU-animated FountainWater cascades and parabolic arcs.

const ENTRY := {"type": "havis_amanda", "name": "Havis Amanda", "lat": 60.1675863, "lon": 24.9513987,
	"radius_m": 1500.0, "wiki_title": "Havis Amanda", "height_m": 5.0, "clear_m": 7.0,
	"kind": "Fountain", "aliases": ["havis amanda", "havis amanda fountain", "manta helsinki"]}

const RIM := 0.88

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#A66A60", 1.2, 0.36))
	lm.use("Step", LandmarkMaterials.pbr("stone", "#8C8884", 2.0))
	lm.use("Bronze", LandmarkMaterials.paint("#3B5949", 0.36, 0.68))
	lm.use("Water", LandmarkMaterials.pool_water("#46847E", 0.06))

	# Two stepped grey-granite paving rings & moulded polished Vehmaa red-granite basin.
	lm.lathe("Step", Vector3.ZERO, PackedVector2Array([
		Vector2(6.65, 0.0), Vector2(6.65, 0.14),
		Vector2(6.15, 0.15), Vector2(6.15, 0.29), Vector2(5.75, 0.30),
	]), 64)
	lm.lathe("Granite", Vector3(0.0, 0.29, 0.0), PackedVector2Array([
		Vector2(5.65, 0.0), Vector2(5.62, 0.18), Vector2(5.48, 0.42),
		Vector2(5.58, 0.52), Vector2(5.42, RIM - 0.29),
		Vector2(5.16, RIM - 0.33), Vector2(5.08, 0.25), Vector2(5.02, 0.08),
	]), 64)
	lm.disc("Water", Vector3(0.0, RIM - 0.14, 0.0), Vector3.UP, 5.08, 64)

	# Authentic sculpted Vehmaa red-granite central pedestal & circular upper saucer bowl (y = 2.34 m).
	lm.lathe("Granite", Vector3(0.0, 0.30, 0.0), PackedVector2Array([
		Vector2(1.12, 0.0), Vector2(1.02, 0.38), Vector2(0.86, 0.85),
		Vector2(0.64, 1.38), Vector2(0.58, 1.66), Vector2(1.38, 1.88),
		Vector2(1.62, 2.02), Vector2(1.56, 2.08), Vector2(1.42, 2.04),
		Vector2(0.75, 1.98), Vector2(0.0, 2.04),
	]), 48)
	lm.disc("Water", Vector3(0.0, 2.33, 0.0), Vector3.UP, 1.46, 48)

	var fk := FountainKit.new()
	_sea_lions_and_fish(lm, fk)

	# Real laser-scanned Ville Vallgren bronze Havis Amanda mermaid + 4 spouting sea-fish (2.30..5.02 m)
	SculptureKit.stamp_asset(lm, "Bronze", "havis_amanda_figure",
		Vector3(0.0, 2.30, 0.0), Vector3(2.72, 2.72, 2.72), 0.20)

	lm.commit(model)
	fk.commit(model)
	var warm := Color(1.0, 0.88, 0.66)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(4.2, RIM + 0.1, 4.2), Vector3(0.0, 3.8, 0.0), 50.0, 0.9, 14.0, warm],
		[Vector3(-4.2, RIM + 0.1, 4.2), Vector3(0.0, 3.8, 0.0), 50.0, 0.9, 14.0, warm],
		[Vector3(-4.2, RIM + 0.1, -4.2), Vector3(0.0, 3.8, 0.0), 50.0, 0.9, 14.0, warm],
		[Vector3(4.2, RIM + 0.1, -4.2), Vector3(0.0, 3.8, 0.0), 50.0, 0.9, 14.0, warm],
	])

static func _sea_lions_and_fish(lm: LandmarkMesh, fk: FountainKit) -> void:
	var wat_y := RIM - 0.14
	for i in 4:
		var a := TAU * float(i) / 4.0 + PI * 0.25
		var d := Vector3(cos(a), 0.0, sin(a))
		var yaw_inward := atan2(-d.x, -d.z)
		# Projecting red-granite rim plinth under each real bronze sea lion
		var plinth_c := d * 5.25 + Vector3(0.0, 0.62, 0.0)
		lm.box("Granite", plinth_c, Vector3(1.18, 0.68, 1.58), Basis(Vector3.UP, yaw_inward))
		lm.box("Granite", plinth_c + Vector3(0.0, 0.36, 0.0), Vector3(1.28, 0.10, 1.68), Basis(Vector3.UP, yaw_inward))
		var lion_base := d * 5.18 + Vector3(0.0, 0.98, 0.0)
		var mouth := SculptureKit.sea_lion(lm, "Bronze", lion_base, 1.38, yaw_inward)
		var land := d * 2.05 + Vector3(0.0, wat_y, 0.0)
		fk.arc_stream(mouth, land, 0.68, 0.060, 0.16)
		fk.splash_ring(land, 0.85, 0.82)

		# Four sea-fish parabolic arcs spouting out from the scanned fish mouths on the saucer
		var fa := a + PI * 0.25
		var fd := Vector3(cos(fa), 0.0, sin(fa))
		var fish_mouth := fd * 0.68 + Vector3(0.0, 2.96, 0.0)
		var fish_land := fd * 3.15 + Vector3(0.0, wat_y, 0.0)
		fk.arc_stream(fish_mouth, fish_land, 0.28, 0.045, 0.13)
		fk.splash_ring(fish_land, 0.72, 0.76)

	# Delicate shimmering water curtain overflowing the red-granite upper saucer rim into the main basin
	fk.bowl_curtain(Vector3.ZERO, 1.58, 2.34, wat_y, 0.42, 48, 1.0, 1.0, 0.24)
	fk.splash_ring(Vector3(0.0, wat_y, 0.0), 2.35, 0.65)
	fk.mist_emitter(Vector3(0.0, wat_y + 0.25, 0.0), 1.1, 0.85, 3)
