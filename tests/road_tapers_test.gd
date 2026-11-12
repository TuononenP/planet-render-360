extends SceneTree

## Headless: godot --headless --script tests/road_tapers_test.gd
## Road tapers (RoadTapers): a two-lane way running straight on into a
## one-lane way gets paving that eases from the wider width to the narrower
## one along the narrower way; a side road leaving at an angle, a bridge or
## a node where three ways meet gets none.

func _init() -> void:
	var failures: Array[String] = []
	var wide := {"class": "primary", "width_m": 7.0, "lanes": 2,
		"points": PackedVector2Array([Vector2(0, -100), Vector2(0, 0)])}
	var narrow := {"class": "primary", "width_m": 3.5, "lanes": 1,
		"points": PackedVector2Array([Vector2(0, 0), Vector2(0, 100)])}
	var d := LocationData.new()
	d.roads = [wide, narrow]
	var found := RoadTapers.tapers(d, 1.0)
	if found.size() != 1 or found[0][0] != narrow:
		failures.append("a straight lane drop should get one taper on the narrower way, got %d" % found.size())
	else:
		var ring := RoadTapers.wedge(found[0][1], float(found[0][2]), float(found[0][3]), 1.0)
		var lo := Vector2(INF, INF)
		var hi := -lo
		for p in ring:
			lo = lo.min(p)
			hi = hi.max(p)
		# 3.5 m lost: 12 m per metre, 42 m long, 7 m wide at the node.
		if absf(hi.x - lo.x - 7.0) > 0.2 or absf(hi.y - 42.0) > 1.0 or absf(lo.y) > 0.01:
			failures.append("the taper should run 42 m from 7 m wide, spans %s..%s" % [lo, hi])
	var side := narrow.duplicate()
	side["points"] = PackedVector2Array([Vector2(0, 0), Vector2(60, 60)])
	d.roads = [wide, side]
	if not RoadTapers.tapers(d, 1.0).is_empty():
		failures.append("a way turning off at 45 degrees is no lane drop")
	var deck := narrow.duplicate()
	deck["bridge"] = true
	d.roads = [wide, deck]
	if not RoadTapers.tapers(d, 1.0).is_empty():
		failures.append("a bridge deck gets no taper")
	d.roads = [wide, narrow, side]
	if not RoadTapers.tapers(d, 1.0).is_empty():
		failures.append("a junction of three ways is no lane drop")
	if failures.is_empty():
		print("ROAD TAPERS OK")
		quit(0)
	else:
		for f in failures:
			printerr("ROAD TAPERS FAIL: ", f)
		quit(1)
