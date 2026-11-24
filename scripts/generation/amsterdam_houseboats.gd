class_name AmsterdamHouseboats
extends RefCounted

## Authentic Dutch canal houseboats (*woonarken* & *woonschepen*, `AMS-5.3`)
## replacing the 472 mapped `building=houseboat` OSM footprints in Amsterdam
## that previously extruded as generic multi-storey brick buildings in water.
## Batched per build into one lightweight node via LandmarkMesh.

static func applies(data: LocationData) -> bool:
	return data != null and CityStyles.city_of_region(CityStyles.region_at(data.latitude, data.longitude)) == "amsterdam"

static func is_houseboat(b: Dictionary) -> bool:
	var kind := str(b.get("kind", "")).to_lower()
	return kind == "houseboat" or kind == "boat"

## Build all standing Amsterdam houseboats in one batched mesh and mark their
## indices in `handled` so BuildingBuilder skips brick extrusion for them.
static func build_all(root: Node3D, data: LocationData, ground: GroundTruth,
		sorted: Array, standing: PackedByteArray, handled: PackedByteArray) -> int:
	if not applies(data) or ground == null:
		return 0
	var m2u := WorldScale.metres_to_units()
	var lm := LandmarkMesh.new()
	lm.use("Hull", LandmarkMaterials.pbr("sheet_metal", "#23282D", 2.0, 0.55, 0.55))
	lm.use("Timber", LandmarkMaterials.pbr("wood", "#6E4A32", 2.0))
	lm.use("CladDark", LandmarkMaterials.pbr("sheet_metal", "#364048", 2.0, 0.45, 0.4))
	lm.use("CladWhite", LandmarkMaterials.pbr("render", "#E8E4DA", 2.0))
	lm.use("CladGreen", LandmarkMaterials.pbr("wood", "#234232", 2.0))
	lm.use("Roof", LandmarkMaterials.pbr("roof_concrete", "#4A4E52", 2.5))
	lm.use("Glass", LandmarkMaterials.glass("#1E2E3A"))
	var night_win := LandmarkMaterials.glass("#223442")
	night_win.set_meta(CityLights.META, 0.85)
	lm.use("Lamp", night_win)
	lm.use("Plant", LandmarkMaterials.paint("#2E5A32", 0.85, 0.02))

	var count := 0
	for k in sorted.size():
		if standing[k] == 0 or handled[k] != 0:
			continue
		var b: Dictionary = sorted[k]
		if not is_houseboat(b):
			continue
		var ring: PackedVector2Array = b.get("footprint", PackedVector2Array())
		if ring.size() < 3:
			continue
		var cx := float(b["x"])
		var cz := float(b["z"])
		var wy := ground.water_level_at(cx, cz)
		if is_nan(wy) or wy < -500.0:
			wy = ground.height_at_world(cx, cz)
		# Fit oriented bounding box from longest footprint edge
		var best_dir := Vector2.RIGHT
		var best_len := 0.0
		for i in ring.size():
			var e := ring[(i + 1) % ring.size()] - ring[i]
			if e.length() > best_len:
				best_len = e.length()
				best_dir = e.normalized()
		var perp := Vector2(-best_dir.y, best_dir.x)
		var min_u := INF
		var max_u := -INF
		var min_v := INF
		var max_v := -INF
		for p in ring:
			var d := p - Vector2(cx, cz)
			var u := d.dot(best_dir)
			var v := d.dot(perp)
			min_u = minf(min_u, u); max_u = maxf(max_u, u)
			min_v = minf(min_v, v); max_v = maxf(max_v, v)
		var len_m := clampf((max_u - min_u) / m2u, 7.0, 26.0)
		var wid_m := clampf((max_v - min_v) / m2u, 3.0, 6.2)
		var yaw := atan2(-best_dir.y, best_dir.x)
		var rot := Basis(Vector3.UP, yaw)
		var origin := Vector3(cx / m2u, wy / m2u, cz / m2u)
		var h_seed := int(absf(cx * 13.7 + cz * 29.3)) % 10
		var is_barge := h_seed < 3
		if is_barge:
			# Historic riveted-iron Dutch *woonschip* barge
			lm.box("Hull", origin + Vector3(0.0, 0.35, 0.0), Vector3(len_m, 0.9, wid_m), rot)
			var cab_l := len_m * 0.68
			var wall_mat := "CladGreen" if h_seed == 0 else ("Timber" if h_seed == 1 else "CladWhite")
			lm.box(wall_mat, origin + Vector3(0.0, 1.45, 0.0), Vector3(cab_l, 1.45, wid_m * 0.84), rot)
			lm.box("Roof", origin + Vector3(0.0, 2.24, 0.0), Vector3(cab_l + 0.25, 0.16, wid_m * 0.88), rot)
			# Wheelhouse at stern (+X)
			lm.box("Timber", origin + rot * Vector3(cab_l * 0.5 + 1.0, 1.65, 0.0), Vector3(2.0, 1.75, wid_m * 0.72), rot)
			lm.box("Lamp", origin + Vector3(0.0, 1.50, 0.0), Vector3(cab_l * 0.72, 0.55, wid_m * 0.87), rot)
		else:
			# Modern Dutch *woonark* pavilion
			lm.box("Hull", origin + Vector3(0.0, 0.28, 0.0), Vector3(len_m, 0.75, wid_m), rot)
			var wall_mat := "Timber" if h_seed in [3, 4] else ("CladDark" if h_seed in [5, 6] else ("CladWhite" if h_seed in [7, 8] else "CladGreen"))
			lm.box(wall_mat, origin + Vector3(0.0, 1.85, 0.0), Vector3(len_m * 0.92, 2.45, wid_m * 0.92), rot)
			lm.box("Roof", origin + Vector3(0.0, 3.16, 0.0), Vector3(len_m * 0.96, 0.22, wid_m * 0.96), rot)
			# Panoramic canal-side windows & warm interior night glow
			lm.box("Glass", origin + Vector3(0.0, 1.90, 0.0), Vector3(len_m * 0.76, 1.35, wid_m * 0.95), rot)
			lm.box("Lamp", origin + Vector3(0.0, 1.72, 0.0), Vector3(len_m * 0.62, 0.72, wid_m * 0.94), rot)
			# Rooftop planter boxes
			lm.box("Plant", origin + rot * Vector3(-len_m * 0.28, 3.48, 0.0), Vector3(1.8, 0.45, wid_m * 0.62), rot)
		handled[k] = 1
		count += 1

	if count > 0:
		var holder := Node3D.new()
		holder.name = "AmsterdamHouseboats"
		lm.commit(holder)
		holder.scale = Vector3.ONE * m2u
		root.add_child(holder)
	return count
