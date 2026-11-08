extends SceneTree

func _init() -> void:
	var errors: Array[String] = []
	var seen := {}
	for continent in CapitalContinents.COUNTRIES:
		for code in CapitalContinents.COUNTRIES[continent]:
			if seen.has(code):
				errors.append("%s is in both %s and %s" % [code, seen[code], continent])
			seen[code] = continent
	for row in CapitalCatalog.ROWS:
		if CapitalContinents.of_country(str(row[0])) == "":
			errors.append("no continent for " + str(row[0]))
	var picks := LocationData.quick_picks()
	var counts := {}
	for pick in picks:
		var continent := CapitalContinents.of_place(str(pick[1]))
		if continent == "":
			errors.append("no continent for quick pick " + str(pick[1]))
		counts[continent] = int(counts.get(continent, 0)) + 1
	for filter in CapitalContinents.FILTERS:
		if filter[0] != CapitalContinents.FEATURED and int(counts.get(filter[0], 0)) == 0:
			errors.append("no places on %s: %d" % [filter[0], int(counts.get(filter[0], 0))])
	var expected := {"Banff, Canada": "north_america", "Nairobi, Kenya": "africa",
		"Tokyo, Japan": "asia", "Monaco": "europe", "Canberra, Australia": "oceania",
		"Brasilia, Brazil": "south_america", "Ankara, Turkey": "asia", "Nicosia, Cyprus": "europe",
		"Moscow, Russia": "europe", "Washington, United States": "north_america"}
	for place_name in expected:
		if CapitalContinents.of_place(place_name) != expected[place_name]:
			errors.append("%s should be in %s, is in %s" % [place_name, expected[place_name],
				CapitalContinents.of_place(place_name)])
	if errors.is_empty():
		print("CAPITAL CONTINENTS OK: ", counts)
		quit(0)
	else:
		for error in errors:
			printerr("CAPITAL CONTINENTS FAIL: ", error)
		quit(1)
