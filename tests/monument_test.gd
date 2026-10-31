extends SceneTree

## Memorial columns and obelisks (offline): godot --headless --script tests/monument_test.gd
## A tall slender `historic=monument` building (Nelson's Column: a slim 46 m
## shaft part on a ~28 m plinth footprint) becomes a
## free-standing column/obelisk landmark so the building pipeline does not
## dress it in floors of windows; wide halls and low memorials stay buildings.

# Frame centre 48.8566, 2.3522. 0.00005° lat ≈ 5.5 m, 0.00008° lon ≈ 5.9 m.
const FIXTURE := """
{"elements":[
 {"type":"way","id":1,"tags":{"building":"yes","historic":"monument","name":"Test Column"},
  "geometry":[{"lat":48.85670,"lon":2.35200},{"lat":48.85670,"lon":2.35240},
              {"lat":48.85645,"lon":2.35240},{"lat":48.85645,"lon":2.35200}]},
 {"type":"way","id":2,"tags":{"building:part":"yes","height":"46","min_height":"6"},
  "geometry":[{"lat":48.85659,"lon":2.35222},{"lat":48.85659,"lon":2.35226},
              {"lat":48.85656,"lon":2.35226},{"lat":48.85656,"lon":2.35222}]},
 {"type":"way","id":3,"tags":{"building":"yes","historic":"monument","name":"Test Obelisk"},
  "geometry":[{"lat":48.85760,"lon":2.35220},{"lat":48.85760,"lon":2.35228},
              {"lat":48.85755,"lon":2.35228},{"lat":48.85755,"lon":2.35220}]},
 {"type":"way","id":4,"tags":{"building:part":"yes","height":"30"},
  "geometry":[{"lat":48.85759,"lon":2.35222},{"lat":48.85759,"lon":2.35226},
              {"lat":48.85756,"lon":2.35226},{"lat":48.85756,"lon":2.35222}]},
 {"type":"way","id":5,"tags":{"building":"yes","historic":"memorial","height":"25","name":"Memorial Hall"},
  "geometry":[{"lat":48.85860,"lon":2.35200},{"lat":48.85860,"lon":2.35260},
              {"lat":48.85850,"lon":2.35260},{"lat":48.85850,"lon":2.35200}]},
 {"type":"way","id":6,"tags":{"building":"yes","historic":"memorial","height":"4","name":"Shrine"},
  "geometry":[{"lat":48.85960,"lon":2.35220},{"lat":48.85960,"lon":2.35226},
              {"lat":48.85955,"lon":2.35226},{"lat":48.85955,"lon":2.35220}]},
 {"type":"way","id":7,"tags":{"building":"yes","height":"40","name":"Slim Office"},
  "geometry":[{"lat":48.85560,"lon":2.35220},{"lat":48.85560,"lon":2.35228},
              {"lat":48.85555,"lon":2.35228},{"lat":48.85555,"lon":2.35220}]}
]}
"""

func _init() -> void:
	_run()

func _run() -> void:
	var failures: Array[String] = []
	if OsmTags.monument_kind({"man_made": "obelisk"}) != "obelisk" \
			or OsmTags.monument_kind({"historic": "monument", "name": "Obelisco Lateranense"}) != "obelisk" \
			or OsmTags.monument_kind({"historic": "monument"}) != "column" \
			or OsmTags.monument_kind({"building": "yes"}) != "":
		failures.append("monument_kind should read column/obelisk from tags and ignore plain buildings")
	var result := OsmFetcher.parse_features(FIXTURE, 48.8566, 2.3522)
	var found := {}
	for l in result["landmarks"]:
		found[str(l["name"])] = l
	if not found.has("Test Column") or str(found["Test Column"]["archetype"]) != "column":
		failures.append("tall slender monument should become a column landmark, got %s" % [found])
	elif absf(float(found["Test Column"]["height"]) - 46.0) > 0.1:
		failures.append("column height should come from its tallest part (46 m), got %s" % found["Test Column"]["height"])
	if not found.has("Test Obelisk") or str(found["Test Obelisk"]["archetype"]) != "obelisk":
		failures.append("a monument named Obelisk should become an obelisk landmark")
	for quiet in ["Memorial Hall", "Shrine", "Slim Office"]:
		if found.has(quiet):
			failures.append("%s must stay an ordinary building" % quiet)
	for kind in ["column", "obelisk"]:
		var node := LandmarkBuilder.build_archetype(kind, 51.6, Vector2(24, 24))
		var tris := 0
		for mi in LandmarkBuilder.parts(node):
			tris += mi.mesh.get_faces().size() / 3
		if tris < (100 if kind == "column" else 40):
			failures.append("%s model should have real geometry, got %d triangles" % [kind, tris])
		node.free()
	if failures.is_empty():
		print("MONUMENT OK: tall slender monuments become column/obelisk landmarks, halls and offices stay buildings")
		quit(0)
	else:
		for f in failures:
			print("FAIL: ", f)
		quit(1)
