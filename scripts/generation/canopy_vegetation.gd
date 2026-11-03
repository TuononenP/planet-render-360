class_name CanopyVegetation
extends RefCounted

## Trees inferred from the registered canopy-height raster, or WorldCover's
## tree class when canopy is unavailable. Real tree nodes and mapped green
## polygons keep their existing placement; all placement remains instanced
## through VegetationBuilder's normal plan and budgets.
const SPACING_M := 8.0
const TREE_EXCLUSION_M := 8.0

## A source consisting entirely of its no-data sentinel cannot suppress
## the existing procedural fallback.
static func usable(image: Image, nodata: int) -> bool:
	if image == null or image.is_empty():
		return false
	var img := image.duplicate() as Image
	if img.get_format() != Image.FORMAT_L8:
		img.convert(Image.FORMAT_L8)
	var bytes := img.get_data()
	return not bytes.is_empty() and bytes.count(nodata) < bytes.size()

static func add(plan: Dictionary, data: LocationData, ground: GroundTruth,
		mask: VegetationMask, ctx: Dictionary, abort: BuildAbort = null) -> int:
	if int(ctx.get("preset", 0)) <= RenderSettings.Preset.FAST:
		return 0
	var has_canopy := usable(data.canopy_image, 255)
	var source := data.canopy_image if has_canopy else data.landcover_image
	if source == null or source.is_empty():
		return 0
	var canopy := has_canopy
	var img := source.duplicate() as Image
	if img.get_format() != Image.FORMAT_L8:
		img.convert(Image.FORMAT_L8)
	var pixels := img.get_data()
	var width := img.get_width()
	var height := img.get_height()
	var fallback_pixels := PackedByteArray()
	var fallback_width := 0
	var fallback_height := 0
	if canopy and data.landcover_image != null and not data.landcover_image.is_empty():
		var fallback := data.landcover_image.duplicate() as Image
		if fallback.get_format() != Image.FORMAT_L8:
			fallback.convert(Image.FORMAT_L8)
		fallback_pixels = fallback.get_data()
		fallback_width = fallback.get_width()
		fallback_height = fallback.get_height()
	var buckets := {}
	for tree in data.trees:
		if not (tree is Dictionary) or not tree.has("x") or not tree.has("z"):
			continue
		var p := Vector2(float(tree["x"]), float(tree["z"]))
		var key := Vector2i(floori(p.x / TREE_EXCLUSION_M), floori(p.y / TREE_EXCLUSION_M))
		if not buckets.has(key):
			buckets[key] = []
		buckets[key].append(p)
	var limit := int(ctx["budget"]) * VegetationBuilder.IMPOSTOR_FACTOR
	var added := 0
	var half := WorldScale.detailed_extent_units() * 0.5
	var seed := float(data.seed_value)
	var bands := [0.0, 200.0, 450.0, 800.0, half * 1.42]
	for band in bands.size() - 1:
		var inside: float = bands[band]
		var outside: float = bands[band + 1]
		var steps := ceili(minf(outside, half) / SPACING_M)
		for iz in range(-steps, steps + 1):
			if abort != null and abort.requested:
				return added
			for ix in range(-steps, steps + 1):
				if (plan["pos"] as Array).size() >= limit:
					return added
				var x := (float(ix) + (VegetationBuilder._hash(ix, iz, seed + 41.0) - 0.5) * 0.7) * SPACING_M
				var z := (float(iz) + (VegetationBuilder._hash(ix, iz, seed + 42.0) - 0.5) * 0.7) * SPACING_M
				var d2 := x * x + z * z
				if d2 < inside * inside or d2 >= outside * outside or absf(x) >= half or absf(z) >= half:
					continue
				var px := clampi(int((x / (half * 2.0) + 0.5) * width), 0, width - 1)
				var py := clampi(int((z / (half * 2.0) + 0.5) * height), 0, height - 1)
				var value := int(pixels[py * width + px])
				var measured_canopy := canopy and value != 255
				if canopy and value == 255 and not fallback_pixels.is_empty():
					var fx := clampi(int((x / (half * 2.0) + 0.5) * fallback_width), 0, fallback_width - 1)
					var fz := clampi(int((z / (half * 2.0) + 0.5) * fallback_height), 0, fallback_height - 1)
					value = int(fallback_pixels[fz * fallback_width + fx])
				if (measured_canopy and value < 3) or (not measured_canopy and value not in [10, 95]):
					continue
				var cover := mask.cover_at(x, z)
				if cover >= 0 and str(mask.green[cover]["class"]) != "grass":
					continue
				if _near_mapped_tree(buckets, Vector2(x, z)) \
						or not VegetationBuilder._site_ok(x, z, ground, mask,
							VegetationMask.BUILDING | VegetationMask.ROAD_EDGE | VegetationMask.WATER, 0.8, ctx):
					continue
				if ground.asl_y(ground.height_at_world(x, z)) > float(ctx["treeline"]):
					continue
				var pick := VegetationBuilder._species_at(x, z, "park" if cover >= 0 else "forest", ground, ctx)
				var species := str(pick[0])
				var measured := float(value) if measured_canopy else 12.0
				var size := clampf(measured / float(TreeSpecies.spec(species).get("h", 15.0)), 0.2, 2.5)
				VegetationBuilder._add(plan, x, z, ground, species, size, 1.0, false)
				added += 1
	return added

static func _near_mapped_tree(buckets: Dictionary, p: Vector2) -> bool:
	var c := Vector2i(floori(p.x / TREE_EXCLUSION_M), floori(p.y / TREE_EXCLUSION_M))
	for dz in range(-1, 2):
		for dx in range(-1, 2):
			for q in buckets.get(c + Vector2i(dx, dz), []):
				if p.distance_squared_to(q) <= TREE_EXCLUSION_M * TREE_EXCLUSION_M:
					return true
	return false
