extends SceneTree

func _init() -> void:
	var parent := {"osm_id": "way:278069587"}
	var lantern := {"min_height_m": 256.0, "height": 258.0, "material": ""}
	var effective := {}
	NycCrownMaterials.apply(parent, lantern, effective)
	if effective.get("material", "") != "glass":
		printerr("NYC CROWN MATERIALS FAIL: lantern should be glass")
		quit(1)
		return
	var explicitly_mapped := {"material": "stone"}
	NycCrownMaterials.apply(parent, {"min_height_m": 256.0, "height": 258.0, "material": "stone"}, explicitly_mapped)
	var other := {}
	NycCrownMaterials.apply({"osm_id": "way:1"}, lantern, other)
	var spire := {}
	NycCrownMaterials.apply(parent, {"min_height_m": 264.0, "height": 290.0}, spire)
	if explicitly_mapped["material"] != "stone" or not other.is_empty() or not spire.is_empty():
		printerr("NYC CROWN MATERIALS FAIL: defaults must not replace mapped material or affect other parts")
		quit(1)
		return
	var ring := PackedVector2Array([Vector2(0, 0), Vector2(10, 0), Vector2(10, 10), Vector2(0, 10)])
	parent.merge({"kind": "commercial", "x": 5.0, "z": 5.0, "footprint": ring,
		"height": 290.0, "height_source": "tag_height", "parts": [{"footprint": ring,
			"height": 258.0, "height_source": "tag_height", "min_height_m": 256.0, "material": ""}]})
	var data := LocationData.new()
	data.latitude = 40.706
	data.longitude = -74.004
	data.buildings = [parent]
	BuildingMasses.begin_build()
	var masses := BuildingMasses.plan(parent, BuildingBuilder._height_context(data))
	var has_lantern := false
	for mass in masses:
		if float(mass.get("min_m", 0.0)) >= 256.0 and str(mass["b_eff"].get("material", "")) == "glass":
			has_lantern = true
	BuildingMasses.end_build()
	if not has_lantern:
		printerr("NYC CROWN MATERIALS FAIL: mass planning must apply the lantern material")
		quit(1)
		return
	var statue := {"min_m": 176.79, "wall_m": 182.79}
	if not NycCrownMaterials.is_civic_fame({"osm_id": "relation:13625437"}, statue) \
			or NycCrownMaterials.is_civic_fame({"osm_id": "relation:1"}, statue):
		printerr("NYC CROWN MATERIALS FAIL: statue replacement must be limited to its mapped part")
		quit(1)
		return
	var root := Node3D.new()
	NycCrownMaterials.civic_fame(root, Vector2.ZERO, 176.79)
	if root.get_child_count() == 0 or not root.get_child(0).has_meta("nyc_civic_fame"):
		printerr("NYC CROWN MATERIALS FAIL: Civic Fame figure was not emitted")
		root.free()
		quit(1)
		return
	root.free()
	print("NYC CROWN MATERIALS OK")
	quit(0)
