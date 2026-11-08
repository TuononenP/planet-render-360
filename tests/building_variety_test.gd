extends SceneTree

## Headless: godot --headless --script tests/building_variety_test.gd
## Building variety: the look/tint tiers per preset, the per-building paint
## families (WallVariety / RoofVariety chroma), the extra palette tints that
## add colours but no textures, and a distant building keeping its own colour
## on the shared materials (FacadeMaterials residual).

func _init() -> void:
	var failures: Array[String] = []
	_tier_checks(failures)
	_tint_checks(failures)
	_palette_checks(failures)
	_distant_checks(failures)
	_built_block_checks(failures)
	_roof_angle_checks(failures)
	if failures.is_empty():
		print("BUILDING VARIETY OK")
		quit(0)
	else:
		for f in failures:
			printerr("BUILDING VARIETY FAIL: ", f)
		quit(1)

## Fast and anything off Forward+ keep today's two looks and two tints;
## Balanced and High add tints; desktop Ultra widens both.
func _tier_checks(failures: Array[String]) -> void:
	var P := RenderSettings.Preset
	var cases := [
		[P.FAST, true, Vector2i(2, 2)], [P.FAST, false, Vector2i(2, 2)],
		[P.BALANCED, true, Vector2i(2, 4)], [P.HIGH, true, Vector2i(2, 4)],
		[P.HIGH, false, Vector2i(2, 2)], [P.ULTRA, true, Vector2i(5, 6)],
		[P.ULTRA, false, Vector2i(2, 2)]]
	for c in cases:
		var got := ArchitectureStyle.tiers_for(int(c[0]), bool(c[1]))
		if got != c[2]:
			failures.append("tiers_for(%d, fp=%s) = %s, want %s" % [c[0], c[1], got, c[2]])
	if ArchitectureStyle.chroma_of("render") <= ArchitectureStyle.chroma_of("brick") \
			or ArchitectureStyle.chroma_of("sheet_metal") != 0.0:
		failures.append("chroma_of: render must outweigh brick, metal must be 0")
	if ArchitectureStyle.chroma_of("limestone") > 0.3:
		failures.append("limestone is cut stone: its paint chroma must stay a trace (Paris stays cream)")

## chroma 0 is the plain seeded tint (the far city's native kernel copies it);
## a chromatic tint is stable, never brighter than 1, uses most paint
## families, follows the place's tone, and tints a roof only half as far.
func _tint_checks(failures: Array[String]) -> void:
	var plain_diffs := 0
	var families := {}
	var tone_a := {}
	var tone_b := {}
	var over := 0
	for i in 400:
		var x := float(i % 20) * 31.7 - 300.0
		var z := float(i / 20) * 27.3 - 250.0
		var l := 1.0 + (TerrainBuilder._hash(x * 0.53 + 17.0, z * 0.29) * 2.0 - 1.0) * WallVariety.SPREAD
		var w := (TerrainBuilder._hash(z * 0.61 + 3.0, x * 1.13) * 2.0 - 1.0) * WallVariety.WARMTH
		if not WallVariety.tint_for(x, z).is_equal_approx(Color(l * (1.0 + w), l, l * (1.0 - w))) \
				or not WallVariety.tint_for(x, z, 0.0, 0.7).is_equal_approx(WallVariety.tint_for(x, z)):
			plain_diffs += 1
		var c := WallVariety.tint_for(x, z, 1.0, 0.3)
		if not c.is_equal_approx(WallVariety.tint_for(x, z, 1.0, 0.3)):
			failures.append("chromatic tint is not stable per position")
			return
		if c.r > 1.0 or c.g > 1.0 or c.b > 1.0:
			over += 1
		families[WallVariety._family(x, z, 0.3)] = true
		var fa := WallVariety._family(x, z, 0.0)
		var fb := WallVariety._family(x, z, 0.5)
		tone_a[fa] = int(tone_a.get(fa, 0)) + 1
		tone_b[fb] = int(tone_b.get(fb, 0)) + 1
	if plain_diffs > 0:
		failures.append("chroma 0 changed the plain tint at %d positions" % plain_diffs)
	if over > 0:
		failures.append("%d chromatic wall tints exceed 1 (8-bit vertex colours clamp)" % over)
	if families.size() < 5:
		failures.append("only %d of %d paint families used over 400 buildings" % [families.size(), WallVariety.FAMILIES.size()])
	if tone_a == tone_b:
		failures.append("the place's tone does not change which paint families a city leans to")
	# A street of neighbours 20 m apart shows several families, not one.
	var street := {}
	for k in 12:
		street[WallVariety._family(float(k) * 20.0, 55.0, 0.3)] = true
	if street.size() < 4:
		failures.append("12 neighbours share only %d paint families" % street.size())
	# Roofs follow, half as far.
	var wall_spread := 0.0
	var roof_spread := 0.0
	for i in 200:
		var x := float(i) * 13.1
		var z := float(i) * 7.7 + 40.0
		var wc := WallVariety.tint_for(x, z, 1.0, 0.3)
		var rc := RoofVariety.tint_for(x, z, RoofVariety.ROOF_CHROMA, 0.3)
		wall_spread += absf(wc.r - wc.b)
		roof_spread += absf(rc.r - rc.b)
	if roof_spread <= 0.0 or roof_spread >= wall_spread:
		failures.append("a roof should shift less than a wall (roof %.2f, wall %.2f)" % [roof_spread, wall_spread])

## More palette tints (ctx "tints") add colours, never textures: wall set,
## pattern, shutter, variant and roof shape do not move; without the key the
## look is exactly today's.
func _palette_checks(failures: Array[String]) -> void:
	var region := "haussmann"
	var colours2 := {}
	var colours4 := {}
	var roofs2 := {}
	var roofs4 := {}
	for i in 400:
		var seed_v := fmod(float(i) * 0.61803, 1.0)
		var b := {"kind": "apartments", "levels": 6}
		var base := ArchitectureStyle.resolve(b, region, "urban", seed_v, 400.0, {})
		var two := ArchitectureStyle.resolve(b, region, "urban", seed_v, 400.0, {"looks": 2})
		var four := ArchitectureStyle.resolve(b, region, "urban", seed_v, 400.0, {"looks": 2, "tints": 4})
		if str(base["wall_colour"]) != str(two["wall_colour"]) or str(base["roof_colour"]) != str(two["roof_colour"]):
			failures.append("a context without tints must resolve as today (seed %.3f)" % seed_v)
			return
		for key in ["wall_set", "pattern", "shutter", "variant", "roof_shape", "roof_set", "ground"]:
			if str(two[key]) != str(four[key]):
				failures.append("tints changed %s (seed %.3f)" % [key, seed_v])
				return
		if not is_equal_approx(float(four["vt"]), ArchitectureStyle.chroma_of(str(four["wall_set"]))):
			failures.append("look vt must be the wall set's chroma")
			return
		colours2[str(two["wall_colour"])] = true
		colours4[str(four["wall_colour"])] = true
		roofs2[str(two["roof_colour"])] = true
		roofs4[str(four["roof_colour"])] = true
	if colours4.size() <= colours2.size() and roofs4.size() <= roofs2.size():
		failures.append("4 tints gave no more colours than 2 (wall %d -> %d, roof %d -> %d)"
			% [colours2.size(), colours4.size(), roofs2.size(), roofs4.size()])

## A distant building keeps its own colour: a mapped `building:colour` pulls
## its shared wall toward that colour; the shared set stays within PRD §6, and
## more tints add far fewer materials than buildings.
func _distant_checks(failures: Array[String]) -> void:
	FacadeMaterials.begin_build()
	var region := "haussmann"
	var found := false
	for i in 200:
		var seed_v := fmod(float(i) * 0.37 + 0.11, 1.0)
		var plain := {"kind": "apartments", "levels": 6}
		var red := {"kind": "apartments", "levels": 6, "colour": "#c04040"}
		var style := ArchitectureStyle.resolve(plain, region, "urban", seed_v, 400.0, {"looks": 2, "tints": 4})
		var mat_plain := FacadeMaterials.facade_for_building(plain, region, 6, 2, true, seed_v, style)
		var mat_red := FacadeMaterials.facade_for_building(red, region, 6, 2, true, seed_v, style)
		if str(mat_plain.get_meta("facade_set", "")) != str(style["wall_set"]):
			continue  # the shared walls are another set for this look: no residual
		found = true
		var got_plain := _effective(mat_plain, FacadeMaterials.wall_residual(mat_plain, plain, style, seed_v))
		var got_red := _effective(mat_red, FacadeMaterials.wall_residual(mat_red, red, style, seed_v))
		var redness_plain := got_plain.r / maxf(got_plain.g + got_plain.b, 0.001)
		var redness_red := got_red.r / maxf(got_red.g + got_red.b, 0.001)
		if redness_red <= redness_plain:
			failures.append("a #c04040 distant wall is not redder than its plain neighbour (%.3f vs %.3f)"
				% [redness_red, redness_plain])
			return
		break
	if not found:
		failures.append("no look in the sample had shared walls of its own set")
	var dist := FacadeMaterials.distant_facades(2, region).size() + FacadeMaterials.distant_roofs(region, 2).size()
	if dist > 6:
		failures.append("%s distant materials %d > 6 (PRD §6)" % [region, dist])
	# Residuals stay in range and never brighten.
	var m := FacadeMaterials.distant_facades(2, region)[0] as Material
	var r := FacadeMaterials.residual(m, Color(0.0, 0.0, 0.0))
	var q := FacadeMaterials.residual(m, Color(9.0, 9.0, 9.0))
	if r.r < FacadeMaterials.RESIDUAL_MIN - 0.001 or q.r > 1.0 or q.g > 1.0 or q.b > 1.0:
		failures.append("residual left [%.2f, 1]: %s / %s" % [FacadeMaterials.RESIDUAL_MIN, r, q])

## 16 untagged apartment blocks 40 m apart, built through BuildingBuilder at
## High in Helsinki (render walls): the wall tints that reach the meshes.
## Many distinct tints, all within 1 (the chroma path clamps; the plain tint
## runs up to 1.14), and a second city's tone changes them.
func _built_block_checks(failures: Array[String]) -> void:
	var a := _wall_tints(60.1699, 24.9384, 6)
	if a.has("error"):
		failures.append(str(a["error"]))
		return
	var tints: Array = a["tints"]
	if int(a["chroma_buildings"]) < 8:
		failures.append("only %d of 16 built Helsinki blocks carry a paint weight (wall sets: %s)"
			% [int(a["chroma_buildings"]), a["sets"]])
		return
	var distinct := {}
	var over := 0
	for c in tints:
		var col := c as Color
		distinct["%.2f|%.2f|%.2f" % [col.r, col.g, col.b]] = true
		if col.r > 1.0005 or col.g > 1.0005 or col.b > 1.0005:
			over += 1
	if distinct.size() < 6:
		failures.append("16 built blocks show only %d distinct wall tints" % distinct.size())
	if over > 0:
		failures.append("%d built wall tints exceed 1: the paint-family path did not run on the meshes" % over)
	# The same layout in a city with another tone is painted differently.
	var b := _wall_tints(40.7128, -74.006, 6)
	if not b.has("error") and (b["tints"] as Array) == tints:
		failures.append("two cities with the same layout got identical wall tints")

## {tints: wall tint per built building (the brightest wall vertex colour,
## free of the foot shade), chroma_buildings, sets} for 16 untagged blocks
## built at High around (lat, lon); {error} when nothing built.
func _wall_tints(lat: float, lon: float, preset: int) -> Dictionary:
	var data := LocationData.new()
	RenderSettings.apply_preset(data, RenderSettings.Preset.HIGH)
	var n := data.grid_size
	data.heights.resize(n * n)
	data.heights.fill(3.0)
	data.water_level = -3.0
	data.seed_value = preset
	data.latitude = lat
	data.longitude = lon
	data.buildings = []
	for i in 16:
		var c := Vector2(float(i % 4) * 40.0 - 60.0, float(i / 4) * 40.0 - 60.0)
		data.buildings.append({"x": c.x, "z": c.y, "size_x": 20.0, "size_z": 14.0,
			"height": 18.0, "levels": 6, "height_source": "levels", "kind": "apartments",
			"footprint": PackedVector2Array([c + Vector2(-10, -7), c + Vector2(10, -7),
				c + Vector2(10, 7), c + Vector2(-10, 7)])})
	var root := BuildingBuilder.build_buildings(data, GroundTruth.new(data))
	var tints: Array = []
	for child in root.get_children():
		var mi := child as MeshInstance3D
		if mi == null or mi.mesh == null or child.has_meta("lod_impostor"):
			continue
		var best := Color(0, 0, 0)
		var found := false
		for s in mi.mesh.get_surface_count():
			if not WallVariety.is_wall(mi.get_active_material(s)):
				continue
			var cols = MeshArrays.surface(mi.mesh, s)[Mesh.ARRAY_COLOR]
			if cols == null:
				continue
			for col in (cols as PackedColorArray):
				if col.r + col.g + col.b > best.r + best.g + best.b:
					best = col
					found = true
		if found:
			tints.append(Color(snappedf(best.r, 0.005), snappedf(best.g, 0.005), snappedf(best.b, 0.005)))
	var ctx := BuildingHeights._height_context(data)
	var chroma_n := 0
	var sets := {}
	for b in data.buildings:
		var look := BuildingHeights._look_for(b as Dictionary, ctx)
		sets[str(look["wall_set"])] = true
		if float(look["vt"]) > 0.0:
			chroma_n += 1
	root.free()
	if tints.is_empty():
		return {"error": "no wall tints found on the blocks built at %.2f, %.2f" % [lat, lon]}
	return {"tints": tints, "chroma_buildings": chroma_n, "sets": ", ".join(sets.keys())}

## A mapped `roof:angle` sets a ridged roof's rise (tan(angle) over half the
## span); a mapped `roof:height` still wins; no angle keeps the regional pitch.
func _roof_angle_checks(failures: Array[String]) -> void:
	var data := LocationData.new()
	RenderSettings.apply_preset(data, RenderSettings.Preset.HIGH)
	data.latitude = 60.1699
	data.longitude = 24.9384
	data.buildings = []
	var ctx := BuildingHeights._height_context(data)
	var rise := {}
	var span := 0.0
	var i := 0
	for angle in [0.0, 20.0, 45.0, -1.0]:
		var c := Vector2(300.0 + float(i) * 60.0, 300.0)
		i += 1
		var b := {"x": c.x, "z": c.y, "size_x": 20.0, "size_z": 14.0, "levels": 4,
			"height_source": "levels", "kind": "apartments", "height": 13.0,
			"roof_shape": "gabled", "roof_angle": maxf(angle, 0.0),
			"footprint": PackedVector2Array([c + Vector2(-10, -7), c + Vector2(10, -7),
				c + Vector2(10, 7), c + Vector2(-10, 7)])}
		if angle < 0.0:
			b["roof_angle"] = 45.0
			b["roof_height_m"] = 5.0
		var masses := BuildingMasses.plan(b, ctx)
		if masses.is_empty():
			failures.append("no mass planned for the roof-angle block")
			return
		rise[angle] = float((masses[0] as Dictionary)["rh_m"])
		span = BuildingHeights._ring_span_m((masses[0] as Dictionary)["ring"])
	var want20 := clampf(tan(deg_to_rad(20.0)) * span * 0.5, 0.8, maxf(span * 0.9, 0.8))
	var want45 := clampf(tan(deg_to_rad(45.0)) * span * 0.5, 0.8, maxf(span * 0.9, 0.8))
	if absf(float(rise[20.0]) - want20) > 0.05 or absf(float(rise[45.0]) - want45) > 0.05:
		failures.append("roof:angle rise 20/45 deg should be %.2f/%.2f m, got %.2f/%.2f"
			% [want20, want45, float(rise[20.0]), float(rise[45.0])])
	if float(rise[45.0]) <= float(rise[20.0]) * 1.5:
		failures.append("a 45 deg roof should rise well above a 20 deg one (%.2f vs %.2f)"
			% [float(rise[45.0]), float(rise[20.0])])
	if absf(float(rise[-1.0]) - 5.0) > 0.05:
		failures.append("an explicit roof:height must beat roof:angle (want 5.0, got %.2f)" % float(rise[-1.0]))
	if absf(float(rise[0.0]) - want20) < 0.01 and absf(float(rise[0.0]) - want45) < 0.01:
		failures.append("an untagged angle should keep the regional pitch")

## A shared material's tint after its residual (linear).
func _effective(m: Material, residual: Color) -> Color:
	var base := (m as StandardMaterial3D).albedo_color.srgb_to_linear()
	return Color(base.r * residual.r, base.g * residual.g, base.b * residual.b)
