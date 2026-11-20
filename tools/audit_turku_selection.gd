extends SceneTree

## Which Turku registry landmarks LandmarkSites.select() builds from a set
## of 8 Turku eyes, per preset (High=2, Ultra=3), and which in range fall
## back to OSM extrusions. No OSM fetch: the registry slots are decided
## before OSM candidates fill in.
## Run headlessly in the background:
## tools/godot_bg.sh --headless --path . --script tools/audit_turku_selection.gd

const EYES := [
	["auransilta", 60.44872, 22.27005],
	["kauppatori", 60.45169, 22.26690],
	["vanha_suurtori", 60.45085, 22.27520],
	["martinsilta", 60.44300, 22.25640],
	["forum_marinum", 60.43660, 22.23750],
	["turku_castle", 60.43540, 22.22880],
	["yliopistonmaki", 60.45400, 22.28450],
	["tyks", 60.45250, 22.29250],
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
