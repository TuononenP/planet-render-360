extends SceneTree

## Which Helsinki registry landmarks LandmarkSites.select() builds from a set
## of eyes, per preset, and which in range fall back to OSM extrusions. No
## OSM fetch: the registry slots are decided before OSM candidates fill in.
## Run headlessly in the background:
## tools/godot_bg.sh --headless --path . --script tools/audit_helsinki_selection.gd

const EYES := [
	["harbour_opening", 60.1680, 24.9530],
	["senate_square", 60.16955, 24.95218],
	["toolonlahti", 60.17660, 24.93520],
	["kamppi", 60.16900, 24.93180],
	["hakaniemi", 60.17900, 24.95100],
	["kalasatama", 60.18700, 24.97700],
	["jatkasaari", 60.15800, 24.91900],
]

func _init() -> void:
	var dropped_any := {}
	for eye in EYES:
		for preset in [2, 3]:
			var data := LocationData.new()
			data.latitude = float(eye[1])
			data.longitude = float(eye[2])
			data.quality_preset = preset
			data.landmark_type = LocationData.landmark_for(data.latitude, data.longitude, "")
			var built := {}
			for c in LandmarkSites.select(data, []):
				built[str((c as Dictionary)["type"])] = true
			var dropped: Array = []
			for e in LocationData.registry_extras(data.latitude, data.longitude, data.landmark_type):
				var entry := e as Dictionary
				var d := LocationData.distance_m(data.latitude, data.longitude, float(entry["lat"]), float(entry["lon"]))
				if d > 2500.0 or built.has(str(entry["type"])) or str(entry.get("kind", "")) == "Bridge":
					continue
				dropped.append("%s@%dm" % [entry["type"], int(d)])
				dropped_any[str(entry["type"])] = true
			print("SELECT %s preset=%d primary=%s built=%d dropped<2.5km=%s" % [eye[0], preset,
				data.landmark_type, built.size(), ", ".join(dropped)])
	print("SELECT dropped somewhere: ", dropped_any.keys())
	quit(0)
