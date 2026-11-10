extends SceneTree

## Tall towers keep real window scale at every distance: raised parts count
## their own storeys, distant and far glass tiles by bay and storey, far
## masonry is not a stretched Paris front, and a curtain wall has no blank
## band above a lower neighbour.

const RING := [Vector2(-20, -20), Vector2(20, -20), Vector2(20, 20), Vector2(-20, 20)]

var failures: Array[String] = []

func _init() -> void:
	_storey_repeats()
	_raised_part()
	_distant_glass()
	_far_masonry()
	_firewalls()
	for f in failures:
		printerr("TOWER FACADE FAIL: ", f)
	print("tower_facade_uv_test: %s" % ("FAIL" if not failures.is_empty() else "PASS"))
	quit(1 if not failures.is_empty() else 0)

func _ring() -> PackedVector2Array:
	return PackedVector2Array(RING)

func _data() -> LocationData:
	var d := LocationData.new()
	d.latitude = 40.706
	d.longitude = -74.004
	d.grid_size = 49
	d.heights.resize(49 * 49)
	d.heights.fill(0.0)
	d.water_level = -3.0
	return d

func _storey_repeats() -> void:
	# 27 m of wall at 3.6 m floors: its own storeys, whatever the parent says.
	var r := BuildingWalls.storey_repeats(27.0, 66, 3.6)
	if r < 5.0 or r > 10.0:
		failures.append("a 27 m wall must keep 5-10 storeys, got %.1f" % r)
	if BuildingWalls.storey_repeats(2.0, 66, 3.6) != 1.0:
		failures.append("a 2 m crown part is one storey")

## Largest storey repeat on `root`'s surfaces in material set `set_name`.
func _max_v(root: Node3D, set_name: String) -> float:
	var out := 0.0
	for child in root.get_children():
		if not child is MeshInstance3D:
			continue
		var mesh := (child as MeshInstance3D).mesh
		for s in mesh.get_surface_count():
			var m: Material = (child as MeshInstance3D).material_override
			if m == null:
				m = mesh.surface_get_material(s)
			if m == null or str(m.get_meta("facade_set", "")) != set_name:
				continue
			for uv in mesh.surface_get_arrays(s)[Mesh.ARRAY_TEX_UV]:
				out = maxf(out, (uv as Vector2).y)
	return out

func _raised_part() -> void:
	var data := _data()
	var ground := GroundTruth.new(data)
	var ctx := BuildingBuilder._height_context(data)
	var b := {"kind": "commercial", "levels": 8, "material": "glass", "x": 0.0, "z": 0.0}
	var look := ArchitectureStyle.resolve({"kind": "commercial"}, "nyc_glass", "mid", 0.3, 1600.0)
	var root := Node3D.new()
	BuildingBuilder._extrude_polygon(root, data, ground, _ring(), 150.0,
		Vector2.ZERO, "flat", 0.0, b, ctx, 8, look, false, {"min_m": 123.0})
	var v := _max_v(root, "glass")
	var fh := float(look["floor_h"])
	if v <= 0.0:
		failures.append("the raised glass part built no tiled wall")
	elif 27.0 / v < fh * 0.75 or 27.0 / v > fh * 1.35:
		failures.append("raised 123-150 m part: %.2f m a storey at %.1f m floors" % [27.0 / v, fh])
	root.free()

func _distant_glass() -> void:
	FacadeMaterials.begin_build()
	var m := FacadeMaterials.facade_for_building({"material": "mirror"}, "north_america", 72, 3, true)
	var uvp := FacadeMaterials.facade_uv(m)
	if uvp.x <= 0.0 or uvp.z <= 0.0:
		failures.append("distant glass must tile by real bay and storey, got %s" % uvp)
	if str(m.get_meta("facade_set", "")) != "glass":
		failures.append("distant mapped mirror must stay glass")
	# Fast composes the tile with no normal or roughness maps.
	var fast := FacadeMaterials.facade_for_building({"material": "mirror"}, "north_america", 72, 1, true)
	if FacadeMaterials.facade_uv(fast).x <= 0.0:
		failures.append("Fast's distant glass must tile by real bay too")
	var s := FacadeShader.from_standard(m as StandardMaterial3D)
	if (s.get_shader_parameter("cells") as Vector2).y < 1.0:
		failures.append("distant glass needs at least one shader cell per storey")

func _far_masonry() -> void:
	var data := _data()
	var builder := FarCityBuilder.new()
	builder._height_ctx = BuildingBuilder._height_context(data)
	builder._region = "north_america"
	builder._fidelity = 3
	var mass := {"kind": "commercial", "material": "limestone", "levels": 40, "height": 150.0,
		"height_source": "tag_height", "footprint": _ring(), "x": 0.0, "z": 0.0}
	var m := builder._tower_material(mass, StandardMaterial3D.new(), Vector2.ZERO)
	if str(m.get_meta("facade_pattern", "")) == "haussmann":
		failures.append("a far limestone tower must not wear the Paris facade")
	if FacadeMaterials.facade_uv(m).x <= 0.0:
		failures.append("a far limestone tower must keep real bays")
	# Mapped concrete under a glass-tower look, and the shared distant look.
	var look := ArchitectureStyle.resolve({"kind": "commercial"}, "nyc_glass", "mid", 0.3, 1600.0)
	var concrete := FacadeMaterials.facade_for_building({"material": "concrete"}, "north_america", 40, 3, true, 0.3, look)
	if str(concrete.get_meta("facade_pattern", "")) == "curtain":
		failures.append("a concrete wall must not take the curtain-wall pattern")
	var shared := ArchitectureStyle.distant_look("nyc_glass")
	if str(shared["pattern"]) == "curtain" and str(shared["wall_set"]) != "glass":
		failures.append("the shared distant look pairs a solid wall with the curtain pattern")

## Height of `root`'s surfaces in material `m`, summed over one wall.
func _span(root: Node3D, m: Material) -> float:
	var lo := INF
	var hi := -INF
	for child in root.get_children():
		if child is MeshInstance3D and (child as MeshInstance3D).material_override == m:
			for v in (child as MeshInstance3D).mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]:
				lo = minf(lo, (v as Vector3).y)
				hi = maxf(hi, (v as Vector3).y)
	return 0.0 if lo == INF else hi - lo

func _wall_above(facade: Material, fire: Material, base: float = 0.0) -> Node3D:
	var root := Node3D.new()
	# One side against a 30 m neighbour, the other three open.
	var cover := [[[0.0, 1.0, 30.0]], [[0.0, 1.0, PartyWalls.OPEN]],
		[[0.0, 1.0, PartyWalls.OPEN]], [[0.0, 1.0, PartyWalls.OPEN]]]
	BuildingWalls._walls(root, _ring(), base, 150.0, facade, 38.0, cover, fire)
	return root

func _firewalls() -> void:
	FacadeMaterials.begin_build()
	var fire := StandardMaterial3D.new()
	var glass := FacadeMaterials.facade_for_building({"material": "mirror"}, "north_america", 38, 3, true)
	var over_glass := _wall_above(glass, fire)
	if _span(over_glass, fire) > 0.0:
		failures.append("a curtain wall above a lower neighbour must have no blank band")
	over_glass.free()
	var look := ArchitectureStyle.resolve({"kind": "commercial"}, "nyc_prewar", "mid", 0.3, 800.0)
	var stone := FacadeMaterials.facade_for_building({"material": "limestone"}, "north_america", 38, 3, false, 0.3, look)
	var over_stone := _wall_above(stone, fire)
	var band := _span(over_stone, fire)
	if absf(band - BuildingWalls.FIREWALL_BAND_M) > 0.01:
		failures.append("masonry keeps its %.0f m lot-line band, got %.1f m" % [BuildingWalls.FIREWALL_BAND_M, band])
	over_stone.free()
	var raised_tier := _wall_above(stone, fire, 123.0)
	if _span(raised_tier, fire) > 0.0:
		failures.append("a raised tier above a lower neighbour must have no blank band")
	raised_tier.free()
	# A mapped part above its own building's lower part: windows at real bays.
	var own_part := _wall_above(stone, null)
	var bay_u := FacadeMaterials.facade_uv(stone)
	var max_u := 0.0
	for child in own_part.get_children():
		for uv in (child as MeshInstance3D).mesh.surface_get_arrays(0)[Mesh.ARRAY_TEX_UV]:
			max_u = maxf(max_u, (uv as Vector2).x)
	if max_u > 40.0 / bay_u.x / bay_u.y + 1.0:
		failures.append("a wall above its own lower part must keep real bay UVs, got u=%.1f" % max_u)
	own_part.free()
	var legacy := StandardMaterial3D.new()
	var over_legacy := _wall_above(legacy, fire)
	if absf(_span(over_legacy, fire) - BuildingWalls.FIREWALL_BAND_M) > 0.01:
		failures.append("a stretched distant wall keeps windows above the band too")
	over_legacy.free()
