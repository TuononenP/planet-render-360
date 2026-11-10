extends SceneTree

## Headless: godot --headless --script tests/car_fleet_test.gd
## Regional fleets (CarFleet): every fleet names kinds that have specs,
## each region parks its own mix and its own taxi in a modest share, and
## picks are deterministic.

func _init() -> void:
	var failures: Array[String] = []
	for name: String in CarFleet.FLEETS:
		for kind: String in CarFleet.FLEETS[name]["kinds"]:
			if not CarSpecs.has(kind):
				failures.append("%s fleet names an unknown kind %s" % [name, kind])
	for region: String in CarFleet.TAXIS:
		if not CarSpecs.has(str(CarFleet.TAXIS[region]["kind"])):
			failures.append("%s taxi has no spec" % region)
	var expect := {"US": "pickup", "JP": "kei", "FI": "wagon", "PT": "hatch"}
	for country: String in expect:
		if _counts(CarFleet.profile_for("", country)).get(expect[country], 0) < 60:
			failures.append("%s should park plenty of %s" % [country, expect[country]])
	if _counts(CarFleet.profile_for("", "FI")).has("pickup") or _counts(CarFleet.profile_for("", "")).has("kei"):
		failures.append("pickups and light cars keep to their own regions")
	if CarFleet.profile_for("tokyo", "")["kinds"] != CarFleet.profile_for("", "JP")["kinds"]:
		failures.append("a city with no country code falls back to its region's fleet")
	# Taxis: the city's own cab, a modest share, solid paint.
	for row in [["new_york", "US", "taxi", CarFleet.TAXI_YELLOW], ["london", "GB", "cab_london", CarFleet.BLACK],
			["lisbon", "PT", "taxi_lisbon", CarFleet.BLACK]]:
		var fleet := CarFleet.profile_for(row[0], row[1])
		var cabs := 0
		for i in 1000:
			var car: Array = CarFleet.pick(fleet, Vector2(float(i) * 7.0, 31.0))
			if car[0] == row[2]:
				cabs += 1
				if (car[1] as Color) != (row[3] as Color) and row[0] != "london":
					failures.append("%s cab paint: %s" % [row[0], car[1]])
				if (car[2] as Color).r != 0.0:
					failures.append("%s cabs are solid paint" % row[0])
		if cabs < 20 or cabs > 160:
			failures.append("%s should park a modest share of its cabs: %d" % [row[0], cabs])
	for i in 300:
		var car: Array = CarFleet.pick(CarFleet.profile_for("helsinki", "FI"), Vector2(float(i) * 7.0, 31.0))
		if (car[1] as Color) == CarFleet.TAXI_YELLOW or car[0] == "cab_london":
			failures.append("another city's cab parked in Helsinki")
			break
	var fleet := CarFleet.profile_for("san_francisco", "US")
	if CarFleet.pick(fleet, Vector2(12.5, -40.0)) != CarFleet.pick(fleet, Vector2(12.5, -40.0)):
		failures.append("picks must be deterministic")
	if failures.is_empty():
		print("CAR FLEET OK: regional kinds, paint and taxis, deterministic")
		quit(0)
	else:
		for failure in failures:
			printerr("CAR FLEET FAIL: ", failure)
		quit(1)

func _counts(fleet: Dictionary) -> Dictionary:
	var counts := {}
	for i in 600:
		var kind: String = CarFleet.pick(fleet, Vector2(float(i) * 5.0, 17.0))[0]
		counts[kind] = int(counts.get(kind, 0)) + 1
	return counts
