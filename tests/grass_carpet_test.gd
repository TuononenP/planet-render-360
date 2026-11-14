extends SceneTree

## Headless: godot --headless --script tests/grass_carpet_test.gd
## Grass realism: OSM sward (mown vs wild) reaches the ground paint and
## the cover; mown lawns keep short tufts and meadows stand tall with seed
## heads; the near-eye blade carpet grows only on desktop High/Ultra, with
## a bounded clump count and heights baked where the shader reads them.

var failures: Array[String] = ["sentinel: the run did not finish (script error?)"]

func _init() -> void:
	_run()
	if failures.is_empty():
		print("GRASS CARPET OK")
		quit(0)
	else:
		for f in failures:
			printerr("GRASS CARPET FAIL: ", f)
		quit(1)

func _check(ok: bool, what: String) -> void:
	if not ok:
		failures.append(what)

## A wide flat green area of `sward` around the viewpoint.
func _green(preset: int, sward: String, season: int = LocationData.Season.SUMMER) -> LocationData:
	var d := LocationData.new()
	RenderSettings.apply_preset(d, preset)
	d.season = season
	d.heights.resize(d.grid_size * d.grid_size)
	d.heights.fill(3.0)
	d.water_level = -3.0
	d.latitude = 48.8566
	d.longitude = 2.3522
	var half := 700.0
	d.land_polygons = [{"class": "grass", "sward": sward, "points": PackedVector2Array([Vector2(-half, -half),
		Vector2(half, -half), Vector2(half, half), Vector2(-half, half)]), "holes": []}]
	return d

func _plan(d: LocationData) -> Dictionary:
	var g := GroundTruth.new(d)
	return GroundCover.plan(d, g, VegetationMask.new(d, g))

func _mean_height(placed: Dictionary, kind: String) -> float:
	var list: Array = placed.get(kind, [])
	var sum := 0.0
	for e: Array in list:
		sum += float(e[4])
	return sum / maxf(float(list.size()), 1.0)

func _run() -> void:
	failures.clear()
	# Tags.
	_check(OsmTags.sward({"leisure": "park"}) == "mown", "a park is mown")
	_check(OsmTags.sward({"landuse": "grass"}) == "mown", "landuse=grass is mown")
	_check(OsmTags.sward({"landuse": "meadow"}) == "wild", "a meadow is wild")
	_check(OsmTags.sward({"natural": "grassland"}) == "wild", "grassland is wild")
	_check(OsmTags.sward({"natural": "wood"}) == "", "a wood says nothing about sward")
	_check(VegetationMask.sward_of("grass") == "mown" and VegetationMask.sward_of("wetland") == "wild",
		"untagged lawns default to mown, wetland to wild")
	# Ground paint: a wild polygon paints the meadow class, a mown one lawn.
	var wild := _green(RenderSettings.Preset.HIGH, "wild")
	var cmap := GroundMaterial.class_map(wild, 64)
	_check(roundi(cmap.get_pixel(32, 32).r * 255.0) == int(GroundMaterial.ID["meadow"]), "a wild polygon paints meadow")
	var mown := _green(RenderSettings.Preset.HIGH, "mown")
	cmap = GroundMaterial.class_map(mown, 64)
	_check(roundi(cmap.get_pixel(32, 32).r * 255.0) == int(GroundMaterial.ID["grass"]), "a mown polygon paints lawn")
	var pal := GroundMaterial.palette()
	_check(pal.get_pixel(int(GroundMaterial.ID["meadow"]), 1).a > 0.0, "meadow has a palette row")
	# Cover: short tufts on a lawn, tall ones and seed heads in a meadow.
	var p_mown := _plan(mown)
	var p_wild := _plan(wild)
	var hm := _mean_height(p_mown, "tuft")
	var hw := _mean_height(p_wild, "tuft")
	_check(hm > 0.0 and hm < 0.6, "lawn tufts stay short: %.2f" % hm)
	_check(hw > 1.0, "meadow tufts stand tall: %.2f" % hw)
	_check((p_wild.get("seedhead", []) as Array).size() > 50, "a summer meadow carries seed heads")
	_check((p_mown.get("seedhead", []) as Array).is_empty(), "a mown lawn has none")
	# The mower leaves the grass standing round a trunk.
	var treed := _green(RenderSettings.Preset.HIGH, "mown")
	var tg := GroundTruth.new(treed)
	var tmask := VegetationMask.new(treed, tg)
	var m2u := WorldScale.metres_to_units()
	var trunks: Array = []
	for k in 40:
		trunks.append(Vector3((float(k % 8) - 3.5) * 9.0 * m2u, 0.0, (float(k / 8) - 2.0) * 9.0 * m2u))
	tmask.mark_trees(trunks)
	var by_trunk := [0.0, 0.0, 0.0, 0.0]
	for e: Array in (GroundCover.plan(treed, tg, tmask).get("tuft", []) as Array):
		var near := tmask.blocked((e[0] as Vector3).x, (e[0] as Vector3).z, VegetationMask.TREE, GroundCover.TRUNK_TALL_M)
		by_trunk[0 if near else 2] += float(e[4])
		by_trunk[1 if near else 3] += 1.0
	_check(by_trunk[1] > 0.0 and by_trunk[0] / by_trunk[1] > 1.3 * by_trunk[2] / maxf(by_trunk[3], 1.0),
		"tufts round a trunk stand taller: %s" % [by_trunk])
	var winter := _plan(_green(RenderSettings.Preset.HIGH, "wild", LocationData.Season.WINTER))
	_check((winter.get("seedhead", []) as Array).is_empty(), "no seed heads in winter")
	# Cards and paint.
	var card := GrassCards.card("tuft")
	_check(card.surface_get_array_len(0) == 12, "a tuft is three quads")
	var img := GrassCards.paint("tuft", LocationData.Season.SUMMER, false)
	_check(img.get_width() == GrassCards.N and img.has_mipmaps(), "tuft cards are 256 px with mipmaps")
	var soft := 0
	for y in range(0, GrassCards.N, 2):
		for x in range(0, GrassCards.N, 2):
			var a := img.get_pixel(x, y).a
			soft += 1 if a > 0.05 and a < 0.95 else 0
	_check(soft > 50, "blade edges carry fractional alpha for coverage: %d" % soft)
	_check(GrassCards.straw_share(LocationData.Season.AUTUMN, false) > GrassCards.straw_share(LocationData.Season.SUMMER, false),
		"autumn has more dead blades than summer")
	# Carpet.
	var root := Node3D.new()
	_check(GrassCarpet.build(root, _green(RenderSettings.Preset.FAST, "mown")) == null, "Fast grows no carpet")
	_check(GrassCarpet.build(root, _green(RenderSettings.Preset.BALANCED, "mown")) == null, "Balanced grows no carpet")
	var ultra := _green(RenderSettings.Preset.ULTRA, "mown")
	var mmi := GrassCarpet.build(root, ultra)
	_check(mmi != null and mmi.name == "GrassCarpet", "Ultra grows the carpet")
	if mmi != null:
		var side := int(GrassCarpet.SIDE[RenderSettings.Preset.ULTRA])
		_check(mmi.multimesh.instance_count == side * side and side * side <= 30000,
			"the carpet is one bounded grid: %d" % mmi.multimesh.instance_count)
		_check(mmi.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, "the carpet casts no shadow")
		_check(not mmi.visible, "the carpet waits for its heights")
	var mesh := GrassCarpet.clump_mesh()
	_check(mesh.surface_get_array_len(0) == GrassCarpet.BLADES * (GrassCarpet.SEGMENTS + 1) * 2,
		"a clump is %d blades of %d segments" % [GrassCarpet.BLADES, GrassCarpet.SEGMENTS])
	# Heights: a slope baked at texel centres.
	var slope := _green(RenderSettings.Preset.ULTRA, "mown")
	var gs := slope.grid_size
	for z in gs:
		for x in gs:
			slope.heights[z * gs + x] = float(x) * 0.5
	var g := GroundTruth.new(slope)
	var span := 40.0 * WorldScale.metres_to_units()
	var himg := GrassCarpet.height_image(g, Vector2.ZERO, span)
	var n := GrassCarpet.HEIGHT_TEXELS
	var ok := true
	for t: Vector2i in [Vector2i(0, 0), Vector2i(n / 2, n / 3), Vector2i(n - 1, n - 1)]:
		var wx := ((float(t.x) + 0.5) / float(n) - 0.5) * span
		var wz := ((float(t.y) + 0.5) / float(n) - 0.5) * span
		ok = ok and absf(himg.get_pixel(t.x, t.y).r - g.height_at_world(wx, wz)) < 0.01
	_check(ok and himg.get_format() == Image.FORMAT_RF, "heights are baked at the texel centres the shader reads")
	_check(GrassCarpet.attach(root, g) == null, "no terrain, no carpet driver")
	# The carpet only shows where grass lies within reach.
	var span_u := GrassCarpet.HEIGHT_SPAN_M * WorldScale.metres_to_units()
	_check(GrassCarpet.grass_near(GroundTruth.new(ultra), null, Vector2.ZERO, span_u * 0.5), "a park keeps its carpet")
	var paved := _green(RenderSettings.Preset.ULTRA, "mown")
	paved.land_polygons = [{"class": "urban", "points": (ultra.land_polygons[0] as Dictionary)["points"], "holes": []}]
	_check(not GrassCarpet.grass_near(GroundTruth.new(paved), null, Vector2.ZERO, span_u * 0.5), "a paved square hides it")
	var wc := Image.create(8, 8, false, Image.FORMAT_L8)
	wc.fill(Color(30.0 / 255.0, 0, 0))
	var bare := _green(RenderSettings.Preset.ULTRA, "mown")
	bare.land_polygons = []
	_check(GrassCarpet.grass_near(GroundTruth.new(bare), wc, Vector2.ZERO, span_u * 0.5), "unmapped WorldCover grassland keeps it")
	root.free()
