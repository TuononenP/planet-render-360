extends SceneTree

## Headless: godot --headless --script tests/harbour_traffic_test.gd
## Helsinki harbour rows (HarbourVesselData) reach the world: commuter ferries
## and water buses on their routes, the icebreaker rafts and the market boats
## build where the rows are in view and nowhere else; a cruise ferry berthed at
## a listed terminal wears that line's livery.

func _world(lat: float, lon: float) -> Array:
	var d := LocationData.new()
	RenderSettings.apply_preset(d, RenderSettings.Preset.ULTRA)
	d.heights.resize(d.grid_size * d.grid_size)
	d.heights.fill(-8.0)  # open water over the whole extent
	d.water_level = 0.0
	d.land_polygons = [{"class": "water", "tidal": true,
		"points": PackedVector2Array([Vector2(-2400, -2400), Vector2(2400, -2400), Vector2(2400, 2400),
			Vector2(-2400, 2400)])}]
	d.seed_value = 7
	d.latitude = lat
	d.longitude = lon
	var ground := GroundTruth.new(d)
	return [d, ground, VegetationMask.new(d, ground)]

## Distinct vessels of one kind in the tree: godot renames repeated part
## names, so count the positions the parts of one hull share.
func _vessels(root: Node, kind: String) -> int:
	var at := {}
	for node in root.get_children():
		if node.has_meta("harbour_kind") and str(node.get_meta("harbour_kind")) == kind:
			at[(node as Node3D).position] = true
	return at.size()

func _names(root: Node, wanted: String) -> int:
	var n := 0
	for node in root.find_children("*" + wanted + "*", "MeshInstance3D", true, false):
		n += 1
	return n

func _init() -> void:
	var failures: Array[String] = []
	var w := _world(60.1665, 24.9600)
	var root := Node3D.new()
	var placed := HarbourTraffic.build(root, w[0], w[1], w[2])
	if placed < 6:
		failures.append("Helsinki harbour should place ferries, icebreakers and market boats, got %d" % placed)
	if _vessels(root, "commuter") < 2:
		failures.append("the Suomenlinna ferry and a water bus should stand on their routes")
	if _vessels(root, "icebreaker") < 3:
		failures.append("the icebreakers should lie at Katajanokka: %d" % _vessels(root, "icebreaker"))
	if _vessels(root, "market") < 3:
		failures.append("market boats should lie at the Kauppatori quay: %d" % _vessels(root, "market"))
	var away := _world(43.73, 7.42)
	var other := Node3D.new()
	if HarbourTraffic.build(other, away[0], away[1], away[2]) != 0:
		failures.append("a place far from Helsinki gets none of its harbour traffic")
	# Cruise liveries by terminal.
	var data: LocationData = w[0]
	var m := WorldScale.metres_to_units()
	var viking := FerryLivery.line_at(data,
		WorldScale.xz_from_latlon(60.1639, 24.9684, data.latitude, data.longitude) * m, m)
	if str(viking.get("id", "")) != "viking":
		failures.append("a ferry at Katajanokka terminal wears Viking Line, got %s" % viking.get("id", "none"))
	if not FerryLivery.line_at(data, Vector2(5000.0, 5000.0) * m, m).is_empty():
		failures.append("a ferry far from any listed terminal keeps the seeded livery")
	for id in ["silja", "viking", "tallink", "eckero"]:
		var parent := Node3D.new()
		var lm := VesselPrototypes.geometry("cruise_ferry", 200.0, 27.0, 42.0,
			VesselMaterials.paint(str(FerryLivery.row(id)["hull"]), false), true, false, 0.4, "line:" + id)
		lm.commit(parent, "F_")
		for key in ["Livery", "FunnelTop", "Letters"]:
			if _names(parent, "F_" + key) != 1:
				failures.append("%s livery should paint %s" % [id, key])
		if id in ["silja", "tallink"] and _names(parent, "F_Mark") != 1:
			failures.append("%s livery should carry its funnel emblem" % id)
		if id == "viking" and _names(parent, "F_Mark") != 0:
			failures.append("Viking has no funnel emblem")
	if failures.is_empty():
		print("HARBOUR TRAFFIC OK: routes, icebreakers, market boats, cruise liveries")
		quit(0)
	else:
		for f in failures:
			printerr("HARBOUR TRAFFIC FAIL: ", f)
		quit(1)
