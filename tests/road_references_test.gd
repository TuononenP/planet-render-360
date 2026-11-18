extends SceneTree

var failures: Array[String] = []

func _init() -> void:
	var crossing := {"osm_id": "way:1209111146", "class": "footway", "crossing": true, "width_m": 2.0}
	var tagged := {"osm_id": "way:1209111146", "class": "footway", "crossing": true, "width_m": 4.0,
		"width_tagged": true}
	var other := {"osm_id": "way:1", "class": "footway", "crossing": true, "width_m": 2.0}
	RoadReferences.apply([crossing, tagged, other, "not a road"])
	_check(is_equal_approx(float(crossing["width_m"]), 30.0) and bool(crossing["width_tagged"]),
		"Gwanghwamun's crossing must take the Woldae's 30 m width")
	var ref: Dictionary = crossing.get("reference", {})
	_check(ref.get("width_method") == "terrace_width" and ref.get("width_uncertainty_m") == 5.0
		and str(ref.get("source", "")).begins_with("https://"),
		"A reference width must keep its method, uncertainty and source")
	_check(is_equal_approx(float(tagged["width_m"]), 4.0) and not tagged.has("reference"),
		"A mapped width must never be overridden")
	_check(is_equal_approx(float(other["width_m"]), 2.0) and not other.has("reference"),
		"Ways without a row stay as mapped")
	if failures.is_empty():
		print("ROAD REFERENCES PASS")
		quit(0)
	else:
		for f in failures:
			print("FAIL: ", f)
		quit(1)

func _check(ok: bool, msg: String) -> void:
	if not ok:
		failures.append(msg)
