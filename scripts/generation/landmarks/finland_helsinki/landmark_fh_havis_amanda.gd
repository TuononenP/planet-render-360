extends RefCounted

## Havis Amanda (Ville Vallgren, 1908), the Art Nouveau mermaid fountain at the
## head of Helsinki Market Square. Model origin on OSM artwork node 1376320186.
##
## Uses the authentic Vehmaa red-granite stepped circular basin & curved rim
## sea-lion lobes, dark-bronze sculpted seaweed pedestal (`havis_amanda_pedestal.glb`)
## and wide upper saucer bowl, high-detail bronze Havis Amanda mermaid + 4 sea-fish
## (`havis_amanda_figure.glb`), and 4 real bronze rim sea lions (`sea_lion.glb`,
## FGI / Aalto University CC-BY-4.0 scan, DOI 10.5281/zenodo.3768777) paired with
## GPU-animated FountainWater cascades and parabolic arcs.

const ENTRY := {"type": "havis_amanda", "name": "Havis Amanda", "lat": 60.1675863, "lon": 24.9513987,
	"radius_m": 1500.0, "wiki_title": "Havis Amanda", "height_m": 5.0, "clear_m": 7.0,
	"model_rects_m": [[0.0, 0.0, 7.0, 7.0]], "base_at_m": [0.0, 0.0], "base_drop_m": 0.30,
	"kind": "Fountain", "aliases": ["havis amanda", "havis amanda fountain", "manta helsinki"]}

const RIM := 0.96

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Granite", LandmarkMaterials.marble("#7D463D", 0.20))
	lm.use("Step", LandmarkMaterials.marble("#9E8075", 0.62))
	lm.use("DarkBronze", LandmarkMaterials.paint("#242722", 0.28, 0.72))
	lm.use("Bronze", LandmarkMaterials.paint("#3B483D", 0.36, 0.72))
	lm.use("Water", LandmarkMaterials.pool_water("#46847E", 0.06))

	# Two stepped rose-granite circular rings (with buried foundation skirt so sloped paving never gaps)
	# and moulded polished Vehmaa red-granite outer basin wall.
	lm.lathe("Step", Vector3.ZERO, PackedVector2Array([
		Vector2(6.90, -0.45), Vector2(6.90, 0.15),
		Vector2(6.34, 0.16), Vector2(6.34, 0.31), Vector2(5.68, 0.32),
	]), 64)
	lm.lathe("Granite", Vector3(0.0, 0.31, 0.0), PackedVector2Array([
		Vector2(5.68, 0.0), Vector2(5.65, 0.14), Vector2(5.46, 0.36),
		Vector2(5.60, 0.52), Vector2(5.44, RIM - 0.31),
		Vector2(5.14, RIM - 0.34), Vector2(5.06, 0.28), Vector2(5.00, 0.06),
	]), 64)
	lm.disc("Water", Vector3(0.0, RIM - 0.14, 0.0), Vector3.UP, 5.10, 64)

	# Authentic sculpted dark-bronze rocky seaweed pedestal + fluted drum (`havis_amanda_pedestal.glb`)
	# supporting the wide dark-bronze circular upper saucer bowl (rim at y = 2.38 m).
	SculptureKit.stamp_asset(lm, "DarkBronze", "havis_amanda_pedestal",
		Vector3(0.0, 0.48, 0.0), Vector3(1.74, 1.74, 1.74), 0.20)
	lm.lathe("DarkBronze", Vector3(0.0, 2.08, 0.0), PackedVector2Array([
		Vector2(0.62, 0.0), Vector2(0.86, 0.08), Vector2(1.42, 0.18),
		Vector2(1.68, 0.26), Vector2(1.64, 0.30), Vector2(1.48, 0.28),
		Vector2(0.80, 0.22), Vector2(0.0, 0.24),
	]), 48)
	lm.disc("Water", Vector3(0.0, 2.35, 0.0), Vector3.UP, 1.52, 48)

	var fk := FountainKit.new()
	_sea_lions_and_fish(lm, fk)

	# High-detail bronze Havis Amanda mermaid + 4 spouting sea-fish (2.30..5.02 m)
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
	var lobe_h := RIM - 0.31
	var lobe_profile := PackedVector2Array([
		Vector2(0.74, 0.0), Vector2(0.71, 0.14), Vector2(0.56, 0.36),
		Vector2(0.66, 0.52), Vector2(0.58, lobe_h), Vector2(0.0, lobe_h),
	])
	var fig_base := Vector3(0.0, 2.30, 0.0)
	var fig_scale := 2.72
	var fig_yaw := 0.20
	var mouth_ref := Vector3(0.1243, 0.2176, 0.1732)
	var dir_ref := Vector3(0.3033, -0.8361, 0.4571)
	for i in 4:
		var a := TAU * float(i) / 4.0 + PI * 0.25
		var d := Vector3(cos(a), 0.0, sin(a))
		var yaw_inward := atan2(-d.x, -d.z)
		# Curved moulded Vehmaa red-granite rim lobe flush with the basin rim top (y = RIM)
		lm.lathe("Granite", d * 5.62 + Vector3(0.0, 0.31, 0.0), lobe_profile, 28)
		var lion_base := d * 5.52 + Vector3(0.0, RIM, 0.0)
		var mouth := SculptureKit.sea_lion(lm, "Bronze", lion_base, 1.38, yaw_inward)
		var land := d * 2.05 + Vector3(0.0, wat_y, 0.0)
		fk.arc_stream(mouth, land, 0.58, 0.055, 0.16)
		fk.splash_ring(land, 0.85, 0.82)

		# Steep natural gravity pour emerging from inside each sculpted sea-fish's gaping
		# jaws onto the upper bronze saucer (y = 2.35 m) — zero water cannons below saucer.
		var q_rot := Basis(Vector3.UP, fig_yaw + TAU * float(i) / 4.0)
		var fish_mouth := fig_base + (q_rot * mouth_ref) * fig_scale
		var fish_dir := q_rot * dir_ref
		var fish_land := Vector3(fish_mouth.x + fish_dir.x * 0.64, 2.35, fish_mouth.z + fish_dir.z * 0.64)
		fk.arc_stream(fish_mouth, fish_land, 0.015, 0.036, 0.082)
		fk.splash_ring(fish_land, 0.22, 0.58)

	fk.mist_emitter(Vector3(0.0, 2.42, 0.0), 0.55, 0.65, 2)
