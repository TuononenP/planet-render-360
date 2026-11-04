extends SceneTree

func _init() -> void:
	var parent := {"osm_id": "way:278069587"}
	var woolworth := {}
	NycCrownMaterials.apply({"osm_id": "way:75363809"}, {"material": ""}, woolworth)
	if woolworth.get("material", "") != "glazed_terracotta":
		printerr("NYC CROWN MATERIALS FAIL: Woolworth's glazed cladding must not become red brick")
		quit(1)
		return
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
	parent.merge({"kind": "commercial", "levels": 66, "x": 5.0, "z": 5.0, "footprint": ring,
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
			if int(mass["storeys"]) != 1 or str(mass["look"]["pattern"]) != "curtain" \
					or bool(mass["look"]["relief"].get("string_course", false)):
				printerr("NYC CROWN MATERIALS FAIL: a two-metre lantern must not inherit 66 storeys or masonry relief")
				quit(1)
				return
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
	var crown := Node3D.new()
	var mass := {"ring": ring, "centre": Vector2(5, 5), "min_m": 194.0,
		"wall_m": 202.8, "rh_m": 35.0, "shape": "pyramidal"}
	NycCrownMaterials.crown_details(crown, {"osm_id": "way:1"}, mass, 0.0)
	if crown.get_child_count() != 0:
		printerr("NYC CROWN MATERIALS FAIL: crown ornament leaked to an unrelated building")
		quit(1)
		return
	NycCrownMaterials.crown_details(crown, {"osm_id": "way:75363809"}, mass, 0.0)
	var bounded := crown.get_child_count() >= 2
	for child in crown.get_children():
		var bounds: AABB = child.mesh.get_aabb()
		bounded = bounded and bounds.position.y >= 194.0 - 0.2 and bounds.end.y <= 237.8
		bounded = bounded and child.get_meta("nyc_crown_detail", "") == "way:75363809"
	crown.free()
	if not bounded:
		printerr("NYC CROWN MATERIALS FAIL: crown ornament must retain mapped heights and identity")
		quit(1)
		return
	print("NYC CROWN MATERIALS OK")
	quit(0)
