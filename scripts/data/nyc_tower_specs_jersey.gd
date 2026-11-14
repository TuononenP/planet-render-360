class_name NycTowerSpecsJersey
extends RefCounted

## Jersey City's waterfront and Journal Square towers as TowerSpec rows
## (NycTowerSpecs), seen across the Hudson from Lower Manhattan. 99 Hudson
## Street is newer than the bundled snapshots: its part is from live OSM.

static func entries() -> Array:
	return [
		# way:259686624 30 Hudson Street: 4 parts, OSM top 238.0 m
		NycTowerSpecs.row("goldman_sachs_tower", "Goldman Sachs Tower", 40.713042, -74.033992, 238.0, 8.7, 65, "30 Hudson Street", 1, ["goldman sachs tower", "30 hudson street"], {
			"finish": "silver_reflective", "bay": 3.0, "floor": 4.0, "trim": "#c5c9cd", "ops": [
				["poly", 0.0, 145.0, [[-10.6, -24.3], [-1.9, -27.0], [21.8, -29.7], [35.9, -28.6], [45.0, -26.5], [47.4, -19.1], [48.6, 2.0], [47.7, 17.7], [45.5, 25.1], [36.6, 27.9], [12.9, 30.6], [-1.2, 29.4], [-10.2, 27.4], [-12.7, 20.0], [-13.9, -1.1], [-13.0, -16.8]]],
				["poly", 0.0, 180.0, [[-9.8, -23.5], [-1.7, -26.0], [21.8, -28.7], [35.8, -27.6], [44.2, -25.7], [46.4, -18.8], [47.6, 2.0], [46.7, 17.5], [44.7, 24.3], [36.4, 26.9], [12.9, 29.6], [-1.0, 28.5], [-9.5, 26.6], [-11.7, 19.7], [-12.9, -1.1], [-12.0, -16.6]]],
				["poly", 0.0, 210.0, [[-9.0, -22.7], [-1.4, -25.0], [21.8, -27.7], [35.6, -26.6], [43.4, -24.8], [45.5, -18.6], [46.6, 2.1], [45.8, 17.3], [43.9, 23.6], [36.2, 25.9], [12.9, 28.6], [-0.9, 27.5], [-8.7, 25.7], [-10.7, 19.5], [-11.9, -1.1], [-11.0, -16.4]]],
				["poly", 0.0, 238.0, [[-7.8, -21.5], [12.4, -25.7], [21.8, -26.2], [42.3, -23.6], [44.0, -18.3], [45.1, 2.1], [44.3, 17.0], [42.7, 22.4], [22.3, 26.6], [13.0, 27.1], [-7.5, 24.5], [-9.2, 19.2], [-10.4, -1.2], [-9.5, -16.1]]],
			]}),
		# way:450195382 Jersey City Urby: 2 parts, OSM top 217.0 m
		NycTowerSpecs.row("urby_jersey_city", "Urby Jersey City", 40.720330, -74.034600, 217.0, 18.4, 52, "Urby Jersey City", 0, ["urby jersey city"], {
			"finish": "white_panel", "bay": 3.0, "floor": 3.2, "trim": "#dcdad4", "ops": [
				["poly", 0.0, 22.4, [[-6.8, -11.0], [-3.3, 7.5], [-15.6, 9.8], [-13.9, 19.1], [16.6, 13.4], [17.6, 19.1], [41.1, 14.7], [37.6, -3.9], [26.8, -1.9], [23.4, -16.8]]],
				["poly", 0.0, 217.0, [[-6.8, -11.0], [-8.9, -22.0], [-37.2, -16.7], [-31.7, 12.9], [-3.3, 7.5]]],
			]}),
		# way:1185956830 Journal Squared 2: 0 parts, OSM top 230.0 m
		NycTowerSpecs.row("journal_squared_2", "Journal Squared 2", 40.732209, -74.060692, 230.0, -80.9, 28, "Journal Squared", 0, ["journal squared 2"], {
			"finish": "white_panel", "bay": 3.0, "floor": 3.2, "trim": "#dcdad4", "ops": [
				["tier", 0.0, 230.0, 28.9, 26.9, -0.0, -0.0],
			]}),
		# way:633148079 Journal Squared 3: 0 parts, OSM top 195.0 m
		NycTowerSpecs.row("journal_squared_3", "Journal Squared 3", 40.732412, -74.060175, 195.0, 8.5, 29, "Journal Squared", 0, ["journal squared 3"], {
			"finish": "white_panel", "bay": 3.0, "floor": 3.2, "trim": "#dcdad4", "ops": [
				["tier", 0.0, 195.0, 31.9, 27.3, 0.0, 0.1],
			]}),
		# way:633148077 Journal Squared 1: 0 parts, OSM top 175.0 m
		NycTowerSpecs.row("journal_squared_1", "Journal Squared 1", 40.732522, -74.061219, 175.0, 8.5, 29, "Journal Squared", 0, ["journal squared 1"], {
			"finish": "white_panel", "bay": 3.0, "floor": 3.2, "trim": "#dcdad4", "ops": [
				["tier", 0.0, 175.0, 30.4, 28.2, -0.0, -0.1],
			]}),
		# way:508993049 101 Hudson Street: 2 parts, OSM top 167.0 m
		NycTowerSpecs.row("one_oh_one_hudson", "101 Hudson Street", 40.716097, -74.034990, 167.0, 8.7, 67, "101 Hudson Street", 0, ["101 hudson street"], {
			"finish": "pink_granite", "bay": 3.0, "floor": 3.8, "trim": "#b7a08c", "ops": [
				["poly", 0.0, 41.6, [[38.0, 11.8], [38.0, 3.7], [55.8, 3.7], [55.7, 28.5], [-46.2, 28.7], [-46.1, 11.8]]],
				["tier", 0.0, 150.0, 84.2, 43.1, -4.0, -9.8],
				["pyramid", "Roof", 150.0, 84.3, 43.1, 17.0, 0.3, -4.0, -9.8],
			]}),
		# way:259759694 55 Hudson Street: 0 parts, OSM top 194.2 m
		NycTowerSpecs.row("fifty_five_hudson", "55 Hudson", 40.713923, -74.035430, 194.2, 8.9, 67, "55 Hudson", 0, ["55 hudson"], {
			"finish": "lowe_blue", "bay": 3.0, "floor": 3.3, "trim": "#b9bcbf", "ops": [
				["tier", 0.0, 194.2, 103.1, 56.3, 0.0, -0.0],
			]}),
		# cluster:ninety_nine_hudson 99 Hudson Street: 1 parts, OSM top 274.0 m
		NycTowerSpecs.row("ninety_nine_hudson", "99 Hudson Street", 40.715345, -74.034816, 274.0, -81.6, 42, "99 Hudson Street", 1, ["99 hudson street"], {
			"finish": "white_granite", "bay": 3.0, "floor": 3.4, "trim": "#d6d2c8", "ops": [
				["poly", 0.0, 274.0, [[18.3, -19.5], [2.7, -3.7], [-3.7, -3.6], [-19.4, -19.5], [-28.1, -10.8], [-24.2, -6.9], [-27.8, -3.2], [-25.0, -0.3], [-28.0, 2.7], [-12.1, 18.8], [-12.1, 20.7], [10.9, 20.9], [10.9, 19.4], [27.3, 2.7], [24.3, -0.3], [27.1, -3.1], [22.8, -7.4], [26.7, -11.2]]],
			]}),
	]
