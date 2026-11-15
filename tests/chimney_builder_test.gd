extends SceneTree

## Mapped chimneys (man_made=chimney, e.g. Salmisaari's 150 m stack in
## Helsinki) build as round windowless shafts, not windowed towers, in the
## near city and the far city, and take no landmark slot.

const FIXTURE := """
{"elements":[
 {"type":"way","id":349596091,"tags":{"building":"yes","man_made":"chimney","height":"150"},
  "geometry":[{"lat":60.16536,"lon":24.90445},{"lat":60.16536,"lon":24.90461},
              {"lat":60.16528,"lon":24.90461},{"lat":60.16528,"lon":24.90445},{"lat":60.16536,"lon":24.90445}]},
 {"type":"way","id":2,"tags":{"building":"yes","height":"20"},
  "geometry":[{"lat":60.16400,"lon":24.90000},{"lat":60.16400,"lon":24.90040},
              {"lat":60.16380,"lon":24.90040},{"lat":60.16380,"lon":24.90000},{"lat":60.16400,"lon":24.90000}]}
]}
"""

var failures: Array[String] = []

func _init() -> void:
	# Detection: tags -> flag, never an archetype.
	_check(OsmTags.is_chimney({"building": "yes", "man_made": "chimney"}), "man_made=chimney is a chimney")
	_check(OsmTags.is_chimney({"building": "chimney"}), "building=chimney is a chimney")
	_check(not OsmTags.is_chimney({"building": "yes", "man_made": "tower"}), "A tower is no chimney")
	_check(OsmTags.archetype_for({"building": "yes", "man_made": "chimney"}) == "",
		"A chimney must not take a landmark slot")
	var parsed := OsmFetcher.parse_features(FIXTURE, 60.1638, 24.8969)
	var stack := {}
	var plain := {}
	for b in parsed["buildings"]:
		if ChimneyBuilder.accepts(b):
			stack = b
		else:
			plain = b
	_check(not stack.is_empty() and absf(float(stack.get("height", 0.0)) - 150.0) < 0.01,
		"The parsed chimney must keep its flag and tagged height")
	_check(not plain.is_empty(), "An ordinary building must stay an ordinary building")
	_check(not (parsed.get("landmarks", []) as Array).any(func(c: Dictionary) -> bool:
		return str(c.get("archetype", "")) != ""), "A chimney must add no landmark candidate")

	# Shape: area-equivalent round base, tapering, true height.
	var s := ChimneyBuilder.shape(stack)
	var r0: float = s["r0"]
	_check(r0 > 3.0 and r0 < 7.0, "A 9 m square stack needs a ~5 m radius, got %.2f" % r0)
	_check(float(s["r1"]) < r0, "The shaft must taper")

	# Near city: the building pipeline routes it to the shaft builder.
	var d := LocationData.new()
	d.grid_size = 33
	d.heights.resize(33 * 33)
	d.heights.fill(3.0)
	d.centre_elevation_m = 20.0
	d.quality_preset = RenderSettings.Preset.HIGH
	d.buildings = [stack, plain]
	var ground := GroundTruth.new(d)
	var built := BuildingBuilder.build_buildings(d, ground)
	var parts := built.find_children("Chimney_*", "MeshInstance3D", true, false)
	_check(parts.size() >= 2, "The building pipeline must build the chimney as a shaft")
	var c: Vector2 = s["centre"]
	var top := -INF
	var bottom := INF
	var radii: Array[float] = []
	for part in parts:
		var mi := part as MeshInstance3D
		_check(mi.has_meta("mapped_chimney"), "Every chimney part needs its source marker")
		var mat := mi.mesh.surface_get_material(0) as StandardMaterial3D
		_check(mat != null and not mat.has_meta("facade_set"), "A chimney must not wear a facade")
		var verts: PackedVector3Array = mi.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		for v in verts:
			top = maxf(top, v.y)
			bottom = minf(bottom, v.y)
	for part in parts:
		var mi := part as MeshInstance3D
		if not mi.name.ends_with("Shaft"):
			continue
		for v in mi.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX] as PackedVector3Array:
			var r := Vector2(v.x, v.z).distance_to(c)
			if absf(v.y - bottom) < 0.01 and r > 0.5:  # the base cap's centre is no rim
				radii.append(r)
	_check(absf(top - bottom - 150.0) < 0.5, "The shaft must stand its tagged 150 m (got %.1f)" % (top - bottom))
	var lo: float = radii.min() if not radii.is_empty() else 0.0
	var hi: float = radii.max() if not radii.is_empty() else INF
	_check(not radii.is_empty() and hi - lo < 0.05, "The shaft base must be round")
	built.free()

	# Neighbour heights ignore the stack.
	var town := LocationData.new()
	town.buildings = [stack, stack, stack]
	_check(int(BuildingHeights._height_context(town)["tagged_n"]) == 0,
		"A stack must not pollute town height estimates")

	# Far city: the shaft goes into the batch.
	var batch := MassBatch.new()
	ChimneyBuilder.append_far(batch, "0,0", stack, 0.0)
	_check(not batch.is_empty(), "The far shaft must reach the batch")

	if failures.is_empty():
		print("CHIMNEY BUILDER OK: detection, no landmark slot, round shaft, height, pipeline, far batch")
		quit(0)
	else:
		for f in failures:
			printerr("CHIMNEY BUILDER FAIL: ", f)
		quit(1)

func _check(ok: bool, message: String) -> void:
	if not ok and not failures.has(message):
		failures.append(message)
