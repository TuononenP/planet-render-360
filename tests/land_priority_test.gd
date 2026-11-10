extends SceneTree

## Headless: godot --headless --script tests/land_priority_test.gd
## Overlapping land polygons: water first, then the smallest, in both the
## ground paint order and GroundTruth's class lookup (a park inside a
## city-wide residential landuse reads as park, not paving).

var failures: Array[String] = []

func _sq(c: Vector2, half: float) -> PackedVector2Array:
	return PackedVector2Array([c + Vector2(-half, -half), c + Vector2(half, -half),
		c + Vector2(half, half), c + Vector2(-half, half)])

func _init() -> void:
	var city := {"class": "urban", "points": _sq(Vector2.ZERO, 500.0)}
	var park := {"class": "grass", "points": _sq(Vector2(50, 0), 40.0)}
	var pond := {"class": "water", "points": _sq(Vector2(50, 0), 10.0)}
	var lake := {"class": "water", "points": _sq(Vector2(-400, 0), 300.0)}
	var out := OsmGeometry.land_by_priority([city, park, pond, lake])
	if out.size() != 4:
		failures.append("every polygon kept, got %d" % out.size())
	elif out[0] != pond or out[1] != lake or out[2] != park or out[3] != city:
		failures.append("order should be pond, lake, park, city: %s" % [out.map(func(p: Dictionary) -> String: return str(p["class"]))])
	var tied := OsmGeometry.land_by_priority([{"class": "grass", "points": _sq(Vector2.ZERO, 5.0), "id": 1},
		{"class": "grass", "points": _sq(Vector2(20, 0), 5.0), "id": 2}])
	if int(tied[0]["id"]) != 1:
		failures.append("equal polygons keep their order")
	var gt := GroundTruth.new(null)
	gt.set_land(out)
	if gt.land_class_at(70.0, 0.0) != "grass":
		failures.append("a park inside the city reads as park, got %s" % gt.land_class_at(70.0, 0.0))
	if gt.land_class_at(50.0, 0.0) != "water":
		failures.append("a pond in the park reads as water")
	if gt.land_class_at(-150.0, 0.0) != "water":
		failures.append("a lake the city overlaps reads as water")
	if failures.is_empty():
		print("LAND PRIORITY OK: water, then smallest first; park over city, pond over park")
		quit(0)
	else:
		for f in failures:
			printerr("LAND PRIORITY FAIL: ", f)
		quit(1)
