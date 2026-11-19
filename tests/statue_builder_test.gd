extends SceneTree

## Mapped statues (historic=statue, e.g. Henri IV on the Pont Neuf, which
## OSM maps as building=yes) build as a stone pedestal under a bronze
## figure, a rider when statue=equestrian, not as a windowed building box.

const FIXTURE := """
{"elements":[
 {"type":"way","id":200452259,"tags":{"building":"yes","historic":"statue","statue":"equestrian",
   "tourism":"artwork","artwork_type":"statue","name":"Henri IV"},
  "geometry":[{"lat":48.8571361,"lon":2.3409362},{"lat":48.8571179,"lon":2.3409857},
              {"lat":48.8571356,"lon":2.3410006},{"lat":48.8571538,"lon":2.3409511},{"lat":48.8571361,"lon":2.3409362}]},
 {"type":"way","id":2,"tags":{"building":"yes","height":"20"},
  "geometry":[{"lat":48.85740,"lon":2.34150},{"lat":48.85740,"lon":2.34190},
              {"lat":48.85720,"lon":2.34190},{"lat":48.85720,"lon":2.34150},{"lat":48.85740,"lon":2.34150}]}
]}
"""

var failures: Array[String] = []

func _init() -> void:
	# Detection: tags -> statue form, never an archetype.
	_check(OsmTags.statue_kind({"building": "yes", "historic": "statue", "statue": "equestrian"}) == "equestrian",
		"historic=statue keeps its statue form")
	_check(OsmTags.statue_kind({"building": "yes", "tourism": "artwork", "artwork_type": "statue"}) == "figure",
		"An artwork statue without a form is a figure")
	_check(OsmTags.statue_kind({"building": "yes", "historic": "memorial"}) == "",
		"A memorial building is no statue")
	var parsed := OsmFetcher.parse_features(FIXTURE, 48.8572, 2.3412)
	var statue := {}
	var plain := {}
	for b in parsed["buildings"]:
		if StatueBuilder.accepts(b):
			statue = b
		else:
			plain = b
	_check(not statue.is_empty() and str(statue.get("statue", "")) == "equestrian",
		"The parsed statue must keep its form")
	_check(not plain.is_empty(), "An ordinary building must stay an ordinary building")
	_check(not (parsed.get("landmarks", []) as Array).any(func(c: Dictionary) -> bool:
		return str(c.get("archetype", "")) != ""), "A statue must add no landmark candidate")

	# Frame: the 4.1 x 2.3 m pedestal measured along its long edge, facing
	# east-south-east toward the Place Dauphine; a mapped direction wins.
	var f := StatueBuilder.frame(statue)
	_check(absf(float(f["length"]) - 4.1) < 0.4 and absf(float(f["width"]) - 2.3) < 0.4,
		"The pedestal must take the footprint's 4.1 x 2.3 m (got %.2f x %.2f)" % [f["length"], f["width"]])
	_check((f["heading"] as Vector2).x > 0.8, "Without a direction tag the figure faces the eastward end")
	var west := statue.duplicate()
	west["statue_dir"] = 290.0
	_check((StatueBuilder.frame(west)["heading"] as Vector2).x < -0.8, "A mapped direction turns the figure")
	var hall := statue.duplicate()
	hall["footprint"] = PackedVector2Array([Vector2(0, 0), Vector2(30, 0), Vector2(30, 20), Vector2(0, 20), Vector2(0, 0)])
	_check(not StatueBuilder.accepts(hall), "A 600 m² footprint is a building, not a pedestal")

	# Near city: the building pipeline routes it to the statue builder.
	var d := LocationData.new()
	d.grid_size = 33
	d.heights.resize(33 * 33)
	d.heights.fill(3.0)
	d.centre_elevation_m = 20.0
	d.quality_preset = RenderSettings.Preset.HIGH
	d.buildings = [statue, plain]
	var ground := GroundTruth.new(d)
	var built := BuildingBuilder.build_buildings(d, ground)
	var parts := built.find_children("Statue_*", "MeshInstance3D", true, false)
	_check(parts.size() == 2, "The statue must build as stone and bronze (got %d parts)" % parts.size())
	var c: Vector2 = f["centre"]
	var ground_y := ground.height_at_world(c.x, c.y)
	var stone_top := -INF
	var bronze_top := -INF
	var bronze_lo := INF
	for part in parts:
		var mi := part as MeshInstance3D
		_check(mi.has_meta("mapped_statue"), "Every statue part needs its source marker")
		var mat := mi.mesh.surface_get_material(0)
		_check(mat != null and not mat.has_meta("facade_set"), "A statue must not wear a facade")
		for v in mi.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX] as PackedVector3Array:
			_check(Vector2(v.x, v.z).distance_to(c) < 3.5, "The statue must stand on its footprint")
			if mi.name.ends_with("Stone"):
				stone_top = maxf(stone_top, v.y)
			else:
				bronze_top = maxf(bronze_top, v.y)
				bronze_lo = minf(bronze_lo, v.y)
	_check(stone_top - ground_y > 2.5 and stone_top - ground_y < 4.6,
		"The pedestal must stand 2.5-4.6 m (got %.1f)" % (stone_top - ground_y))
	# Hooves set a few centimetres into the cornice, never below it.
	_check(bronze_lo >= stone_top - 0.15, "The bronze must stand on the pedestal (lowest %.2f under its top)" % (stone_top - bronze_lo))
	_check(bronze_top - stone_top > 3.0, "The rider must rise over 3 m above the pedestal (got %.1f)" % (bronze_top - stone_top))
	_check(built.find_children("*", "MeshInstance3D", true, false).all(func(n: Node) -> bool:
		return n.name.begins_with("Statue_") or not n.has_meta("osm_id") \
			or str(n.get_meta("osm_id")) != str(statue.get("osm_id", ""))),
		"The statue must not also build as a building")
	built.free()

	if failures.is_empty():
		print("STATUE BUILDER OK: detection, no landmark slot, pedestal frame, direction, pipeline")
		quit(0)
	else:
		for msg in failures:
			printerr("STATUE BUILDER FAIL: ", msg)
		quit(1)

func _check(ok: bool, message: String) -> void:
	if not ok and not failures.has(message):
		failures.append(message)
