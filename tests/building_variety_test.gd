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
	_pitch_checks(failures)
	_proportion_checks(failures)
	_elevation_checks(failures)
	_country_era_checks(failures)
	_roof_axis_checks(failures)
	_flat_roof_checks(failures)
	_block_era_checks(failures)
	_roof_hint_checks(failures)
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

## A bare-membrane flat roof is no longer one photo colour: Tokyo's roofs span
## several greys; a row naming its own roof colours keeps them; Tokyo's walls
## take less paint than the default render.
func _flat_roof_checks(failures: Array[String]) -> void:
	var region := "tokyo"
	var roofs := {}
	var walls := {}
	for i in 300:
		var sv := fmod(float(i) * 0.61803 + 0.02, 1.0)
		var b := {"kind": "apartments", "levels": 6}
		var look := ArchitectureStyle.resolve(b, region, "dense", sv, 400.0, {"looks": 2, "tints": 6})
		if str(look["roof_set"]) == "membrane":
			var rc := look["roof_colour"] as Color
			if rc.a <= 0.0:
				failures.append("a bare membrane roof must get a palette colour")
				return
			roofs["%.2f|%.2f|%.2f" % [rc.r, rc.g, rc.b]] = true
		if str(look["wall_set"]) == "render":
			walls["%.2f" % float(look["vt"])] = true
	if roofs.size() < 4:
		failures.append("Tokyo flat roofs show only %d colours" % roofs.size())
	if not walls.has("0.30"):
		failures.append("Tokyo render walls should take a paint weight of 0.3 (got %s)" % [walls.keys()])
	var slate := ArchitectureStyle.resolve({"kind": "apartments", "levels": 6}, "haussmann", "urban", 0.31, 400.0, {})
	if str(slate["roof_set"]) == "membrane" and (slate["roof_colour"] as Color).a <= 0.0:
		failures.append("Paris-style membrane roofs also take the flat-roof palette")

## A mapped roof:direction / roof:orientation turns a gabled ridge: the
## ridge runs across the slope bearing, and "across" turns it a quarter.
func _roof_axis_checks(failures: Array[String]) -> void:
	# A 30 x 12 footprint: its own long axis is X.
	var ring := PackedVector2Array([Vector2(-15, -6), Vector2(15, -6), Vector2(15, 6), Vector2(-15, 6)])
	if RoofForms.axis_from_tags({}, ring) != Vector2.ZERO:
		failures.append("untagged roofs must keep the footprint's own axis")
	var east := RoofForms.axis_from_tags({"roof_dir": 90.0}, ring)
	var north := RoofForms.axis_from_tags({"roof_dir": 0.0}, ring)
	var across := RoofForms.axis_from_tags({"roof_orient": "across"}, ring)
	if absf(absf(east.y) - 1.0) > 0.001 or absf(absf(north.x) - 1.0) > 0.001 or absf(absf(across.y) - 1.0) > 0.001:
		failures.append("roof axes wrong: east-sloping %s, north-sloping %s, across %s" % [east, north, across])
	# The built ridge follows it: the highest vertices spread along the axis.
	for case in [[Vector2.ZERO, 0], [Vector2(0, 1), 1]]:
		var mesh := RoofGeometry.form_mesh(ring, 10.0, 3.0, "gabled", PackedByteArray(), false, [],
			case[0] as Vector2)
		if mesh == null:
			failures.append("no gabled roof built for axis %s" % [case[0]])
			continue
		var arr := mesh.surface_get_arrays(0)
		var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var lo := Vector2(INF, INF)
		var hi := Vector2(-INF, -INF)
		for v in verts:
			if v.y > 12.9:
				lo = lo.min(Vector2(v.x, v.z))
				hi = hi.max(Vector2(v.x, v.z))
		var spread := hi - lo
		if int(case[1]) == 0 and not (spread.x > 20.0 and spread.y < 1.0):
			failures.append("default ridge should run along X, spread %s" % [spread])
		if int(case[1]) == 1 and not (spread.y > 8.0 and spread.x < 1.0):
			failures.append("a ridge turned to Z should spread along Z, got %s" % [spread])

## Each roof's pitch is its row's +-10%, stable per seed, and the regional
## mean holds.
func _pitch_checks(failures: Array[String]) -> void:
	var base := float(ArchitectureStyle.profile("haussmann", "apartments")["pitch"])
	var lo := INF
	var hi := -INF
	var sum := 0.0
	for i in 300:
		var sv := fmod(float(i) * 0.61803 + 0.02, 1.0)
		var b := {"kind": "apartments", "levels": 6}
		var look := ArchitectureStyle.resolve(b, "haussmann", "urban", sv, 400.0, {})
		var again := ArchitectureStyle.resolve(b, "haussmann", "urban", sv, 400.0, {})
		if float(look["pitch"]) != float(again["pitch"]):
			failures.append("pitch is not stable per seed")
			return
		lo = minf(lo, float(look["pitch"]) / base)
		hi = maxf(hi, float(look["pitch"]) / base)
		sum += float(look["pitch"]) / base
	if lo < 0.899 or hi > 1.101 or hi - lo < 0.15 or absf(sum / 300.0 - 1.0) > 0.03:
		failures.append("pitch should spread +-10%% around the row (%.3f..%.3f, mean %.3f)"
			% [lo, hi, sum / 300.0])

## Bays and storeys spread per building around the row on tiled patterns while
## bay_m (which names the material) stays the row's; a row's window palette
## shows every type even on the two-look tier; the Paris composer is untouched.
func _proportion_checks(failures: Array[String]) -> void:
	var b := {"kind": "apartments", "levels": 5}
	for looks: int in [ArchitectureStyle.LOOKS, ArchitectureStyle.ULTRA_LOOKS]:
		var scale_lo := INF
		var scale_hi := -INF
		var floor_lo := INF
		var floor_hi := -INF
		var windows := {}
		for i in 400:
			var sv := fmod(float(i) * 0.61803 + 0.02, 1.0)
			var look := ArchitectureStyle.resolve(b, "berlin", "urban", sv, 400.0, {"looks": looks})
			if str(look["era"]) != "berlin" or not FacadeComposer.is_tiled(str(look["pattern"])):
				continue
			var row := ArchitectureStyle.profile("berlin", "apartments")
			if float(look["bay_m"]) != float(row["bay"]):
				failures.append("bay_m must stay the row's so materials do not multiply")
				return
			scale_lo = minf(scale_lo, float(look["bay_scale"]))
			scale_hi = maxf(scale_hi, float(look["bay_scale"]))
			var ratio := float(look["floor_h"]) / float(row["fh"])
			floor_lo = minf(floor_lo, ratio)
			floor_hi = maxf(floor_hi, ratio)
			windows[str(look["window"])] = true
		if scale_lo < 0.879 or scale_hi > 1.121 or scale_hi - scale_lo < 0.15:
			failures.append("bay_scale should spread +-12%% (%.3f..%.3f)" % [scale_lo, scale_hi])
		if floor_lo < 0.949 or floor_hi > 1.051 or floor_hi - floor_lo < 0.06:
			failures.append("floor_h should spread +-5%% (%.3f..%.3f)" % [floor_lo, floor_hi])
		if not (windows.has("casement") and windows.has("french")):
			failures.append("Berlin's window palette collapsed at %d looks: %s" % [looks, windows.keys()])
	var paris := ArchitectureStyle.resolve(b, "paris", "urban", 0.37, 400.0, {})
	if str(paris["pattern"]) == "haussmann" and float(paris["bay_scale"]) != 1.0:
		failures.append("the Paris whole-facade composer must keep its bays")

## Decorated masonry gets a taller first upper storey and, on about half of
## fronts, a small-windowed attic; curtain walls, short fronts and fronts above
## a lower neighbour stay plain; relief storeys follow the bands.
func _elevation_checks(failures: Array[String]) -> void:
	var ornate := {"pattern": "ornate", "wall_set": "render", "window": "casement"}
	var attics := 0
	for i in 400:
		var plan := BuildingWalls.band_plan(ornate, fmod(float(i) * 0.61803 + 0.02, 1.0), 5, [], 10.0)
		if not bool(plan["piano"]):
			failures.append("an ornate masonry front should have a piano nobile")
			return
		attics += 1 if bool(plan["attic"]) else 0
	if attics < 140 or attics > 260:
		failures.append("about half of fronts should have an attic, got %d/400" % attics)
	var plain := [
		BuildingWalls.band_plan({"pattern": "curtain", "wall_set": "glass"}, 0.3, 8, [], 10.0),
		BuildingWalls.band_plan(ornate, 0.3, 2, [], 10.0),
		BuildingWalls.band_plan(ornate, 0.3, 5, [[[0.0, 1.0, 2.0]]], 10.0),
	]
	for plan: Dictionary in plain:
		if bool(plan["piano"]) or bool(plan["attic"]):
			failures.append("this front should take no bands: %s" % plan)
	var hidden := BuildingWalls.band_plan(ornate, 0.3, 5, [[[0.0, 1.0, 12.0], [0.0, 1.0, INF]]], 10.0)
	if not bool(hidden["piano"]):
		failures.append("a wall hidden by a taller neighbour should keep its bands")
	var attic := BuildingWalls.attic_look({"pattern": "ornate", "window": "sash", "variant": 2, "rails": 0.6})
	if str(attic["window"]) != "small" or int(attic["variant"]) != 0 or float(attic["rails"]) != 0.0:
		failures.append("the attic look must be small, plain and variant-free: %s" % attic)
	var look := {"pattern": "punched", "window": "casement", "relief": {}}
	var rows := FacadeRelief.storey_rows({"look": look, "base": 0.0, "top": 10.0, "g_top": 0.0,
		"v_rep": 4.0, "storeys": 4, "bands": {"piano": true, "attic": true}}, Vector3(3.0, 4.0, 1.0))
	var r0: Dictionary = rows[0]
	var r1: Dictionary = rows[1]
	var r3: Dictionary = rows[3]
	var unit := 10.0 / (4.0 + BuildingWalls.PIANO_STRETCH - 1.0)
	if absf(float(r0["y1"]) - float(r0["y0"]) - unit * BuildingWalls.PIANO_STRETCH) > 0.001 \
			or absf(float(r3["y1"]) - 10.0) > 0.001 or absf(float(r1["y0"]) - float(r0["y1"])) > 0.001:
		failures.append("relief storeys must stack on the bands: %s" % [rows])
	if float(r3["win1"]) - float(r3["win0"]) >= float(r1["win1"]) - float(r1["win0"]):
		failures.append("the attic's windows should be shorter than the storeys below")

## Outside city zones: real cues pick a country's period, kinds and regions
## without a table stay on the country row, and untagged neighbourhoods mostly
## share a period while the town as a whole shows several.
func _country_era_checks(failures: Array[String]) -> void:
	var r := "central_europe"
	var cases := [[{"start_year": 1880}, "central_europe_old"], [{"start_year": 1930}, r],
		[{"start_year": 1970}, "central_europe_postwar"], [{"start_year": 2015}, "central_europe_new"],
		[{"levels": 14}, "central_europe_new"], [{"heritage": true, "levels": 4}, "central_europe_old"],
		[{"architecture": "brutalist"}, "central_europe_postwar"]]
	for row: Array in cases:
		var got := BuildingEra.refine(r, "apartments", row[0] as Dictionary, {}, 0.4, 400.0)
		if got != str(row[1]):
			failures.append("%s should be %s, got %s" % [row[0], row[1], got])
	if BuildingEra.refine(r, "house", {"start_year": 1880}, {}, 0.4, 100.0) != r:
		failures.append("houses should keep the country row")
	if BuildingEra.refine("alpine", "apartments", {"start_year": 1880}, {}, 0.4, 400.0) != "alpine":
		failures.append("a region without a period table should come back unchanged")
	for region: String in ArchitectureCountryEras.ERAS:
		for e: Array in (ArchitectureCountryEras.ERAS[region] as Array):
			var key := str(e[0])
			if not ArchitectureData.REGIONS.has(key) \
					or (key != region and ArchitectureStyle.country_region(key) != region):
				failures.append("period %s must be a row inheriting from %s" % [key, region])
	var m := WorldScale.metres_to_units()
	var seen := {}
	var agree := 0.0
	var cells := 0
	for cx in 12:
		for cz in 12:
			var counts := {}
			for i in 20:
				var sv := fmod(float(i + cx * 31 + cz * 17) * 0.61803 + 0.02, 1.0)
				var b := {"x": ((float(cx) + 0.5) * ArchitectureCountryEras.CELL_M + float(i) * 3.0 - 30.0) * m,
					"z": ((float(cz) + 0.5) * ArchitectureCountryEras.CELL_M + 20.0) * m}
				var era := BuildingEra.refine(r, "apartments", b, {}, sv, 400.0)
				counts[era] = int(counts.get(era, 0)) + 1
				seen[era] = true
			agree += float(counts.values().max()) / 20.0
			cells += 1
	if seen.size() < 3:
		failures.append("a town should show several periods, got %s" % [seen.keys()])
	if agree / float(cells) < 0.55:
		failures.append("a neighbourhood should mostly share a period (%.2f)" % (agree / float(cells)))
	var old := ArchitectureStyle.resolve({"kind": "apartments", "levels": 4, "start_year": 1880}, r, "urban", 0.3, 400.0, {})
	if str(old["era"]) != "central_europe_old" or not (str(old["pattern"]) in ["ornate", "punched"]):
		failures.append("an 1880 block should take the old row: %s" % old)

## Untagged buildings in one 64 m block tend to share an era: the block's
## most common era covers most of it (random picks over several eras would not).
func _block_era_checks(failures: Array[String]) -> void:
	var region := "warsaw"
	var ctx := CityStyles.local_frame(region, 52.2297, 21.0122)
	ctx["looks"] = 2
	var covered := 0
	var total := 0
	for bx in 12:
		for bz in 3:
			var counts := {}
			var n := 0
			for k in 18:
				var x := (float(bx) * 64.0 + 4.0 + float(k % 6) * 9.0) - 400.0
				var z := (float(bz) * 64.0 + 4.0 + float(k / 6) * 15.0) - 100.0
				var sv := TerrainBuilder._hash(x, z)
				var b := {"kind": "apartments", "x": x, "z": z, "levels": 0}
				var look := ArchitectureStyle.resolve(b, region, "dense", sv, 350.0, ctx)
				counts[str(look["era"])] = int(counts.get(str(look["era"]), 0)) + 1
				n += 1
			var best := 0
			for e in counts:
				best = maxi(best, int(counts[e]))
			covered += best
			total += n
	var share := float(covered) / float(total)
	if share < 0.6:
		failures.append("a block's most common era covers only %.0f%% of its buildings" % [share * 100.0])

## A satellite roof colour reaches a distant building's roof residual: a
## terracotta sample and a grey one pull the shared roof differently, within
## the allowed range; a green (vegetation) sample is ignored.
func _roof_hint_checks(failures: Array[String]) -> void:
	FacadeMaterials.begin_build()
	var region := "rome"
	var found := false
	for i in 120:
		var sv := fmod(float(i) * 0.37 + 0.11, 1.0)
		var b := {"kind": "apartments", "levels": 5}
		var ctx := CityStyles.local_frame(region, 41.9028, 12.4964)
		ctx["looks"] = 2
		var style := ArchitectureStyle.resolve(b, region, "urban", sv, 400.0, ctx)
		var terra := Color(0.62, 0.30, 0.20)
		var grey := Color(0.42, 0.42, 0.44)
		var m := FacadeMaterials.roof_for_building(b, region, "gabled", terra, 2, true, sv, style)
		if str(m.get_meta("roof_set", "")) != str(style["roof_set"]):
			continue
		found = true
		var r_t := FacadeMaterials.roof_residual(m, b, style, terra)
		var r_g := FacadeMaterials.roof_residual(m, b, style, grey)
		var r_green := FacadeMaterials.roof_residual(m, b, style, Color(0.2, 0.5, 0.2))
		var r_none := FacadeMaterials.roof_residual(m, b, style)
		if r_t.is_equal_approx(r_g):
			failures.append("terracotta and grey satellite roofs gave the same residual")
		for c in [r_t, r_g]:
			var col := c as Color
			if minf(col.r, minf(col.g, col.b)) < FacadeMaterials.RESIDUAL_MIN - 0.001 \
					or maxf(col.r, maxf(col.g, col.b)) > 1.001:
				failures.append("a roof residual left [%.2f, 1]: %s" % [FacadeMaterials.RESIDUAL_MIN, col])
		if not r_green.is_equal_approx(r_none):
			failures.append("a vegetation-green satellite sample must be ignored")
		break
	if not found:
		failures.append("no Rome look in the sample had shared roofs of its own set")

## A shared material's tint after its residual (linear).
func _effective(m: Material, residual: Color) -> Color:
	var base := (m as StandardMaterial3D).albedo_color.srgb_to_linear()
	return Color(base.r * residual.r, base.g * residual.g, base.b * residual.b)
