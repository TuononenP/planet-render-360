class_name MiamiTowerSpecsFar
extends RefCounted

## Miami TowerSpec rows for Coconut Grove and Sunny Isles Beach far skyline (MI-3B).

static func entries() -> Array:
	return [
		# way:699802357 Turnberry Ocean Club: 0 parts, OSM top 197.8 m
		MiamiTowerSpecs.row("turnberry_ocean_club", "Turnberry Ocean Club", 25.947663, -80.119898, 197.8, -88.5, 30.6, "Turnberry Ocean Club Residences", 2, ["turnberry ocean club", "18501 collins avenue"], {
			"finish": "clear_fin", "bay": 3.0, "floor": 3.6, "trim": "#e8ecef", "walls": {"Balcony": ["balcony_white", 3.0, 3.6]}, "mats": {"Pool": ["glass", "#36B4D8"], "Fin": ["render", "#F2F2EE"]}, "ops": [
				["use", "Balcony"],
				["tier", 0.0, 22.0, 54.0, 42.0],
				["use", "Facade"],
				["poly", 22.0, 188.0, [[22.0, -16.0], [24.0, 16.0], [-22.0, 18.0], [-24.0, -15.0]]],
				["box", "Fin", 0.0, 98.0, 0.0, 56.0, 9.0, 44.0],
				["box", "Pool", 14.0, 100.0, 24.0, 9.5, 4.2, 14.0],
				["box", "Pool", -14.0, 100.0, 24.0, 9.5, 4.2, 14.0],
				["box", "Fin", -16.0, 188.0, 0.0, 4.0, 9.8, 30.0],
				["box", "Fin", 16.0, 188.0, 0.0, 4.0, 9.8, 30.0],
				["poly", 188.0, 194.0, [[15.0, -11.0], [15.0, 11.0], [-15.0, 11.0], [-15.0, -11.0]]],
			]}),
		# way:494975767 Muse Sunny Isles: 0 parts, OSM top 197.8 m
		MiamiTowerSpecs.row("muse_sunny_isles", "Muse Sunny Isles", 25.934914, -80.121027, 197.8, -4.6, 32.1, "Muse (building)", 1, ["muse sunny isles", "17141 collins avenue"], {
			"finish": "balcony_aqua", "bay": 2.8, "floor": 3.8, "trim": "#e2eaec", "walls": {"Glass": ["silver_reflective", 2.8, 3.8]}, "ops": [
				["poly", 0.0, 34.0, [[-19.0, 9.2], [-16.0, -0.5], [-21.0, -9.3], [26.5, -9.3], [26.0, 9.8]]],
				["poly", 34.0, 76.0, [[-19.1, 7.3], [-19.3, -10.3], [25.1, -7.2], [24.3, 10.5]]],
				["poly", 76.0, 118.0, [[-18.5, 5.5], [-17.5, -11.6], [24.0, -5.4], [22.0, 11.6]]],
				["poly", 118.0, 158.0, [[-17.1, 6.7], [-17.3, -9.8], [22.1, -6.7], [21.3, 9.7]]],
				["poly", 158.0, 189.0, [[-15.5, 7.8], [-16.5, -7.8], [20.0, -7.8], [20.5, 7.8]], 0.92],
				["use", "Glass"],
				["shape", "round", 189.0, 197.8, 30.0, 13.5, 4.5, 25.0, 11.0, 2.0, 0.0],
			]}),
		# way:402232479 Porsche Design Tower: 0 parts, CTBUH height 195.4 m (OSM 195.0 m)
		MiamiTowerSpecs.row("porsche_design_tower", "Porsche Design Tower", 25.948195, -80.119880, 195.4, 4.4, 31.1, "Porsche Design Tower", 2, ["porsche design tower", "18555 collins avenue"], {
			"finish": "black_glass", "bay": 3.0, "floor": 3.2, "trim": "#34373b", "walls": {"Core": ["silver_reflective", 2.8, 3.2]}, "ops": [
				["shape", "ellipse", 0.0, 22.0, 51.4, 51.0, 24.0],
				["shape", "ellipse", 22.0, 186.0, 44.5, 44.5, 24.0],
				["use", "Core"],
				["shape", "ellipse", 186.0, 195.4, 34.0, 34.0, 20.0, 28.0, 28.0],
			]}),
		# way:494975766 Jade Signature: 0 parts, OSM top 193.9 m
		MiamiTowerSpecs.row("jade_signature_sunny_isles", "Jade Signature", 25.932711, -80.121133, 193.9, -64.9, 51.3, "Jade Signature", 2, ["jade signature", "16901 collins avenue"], {
			"finish": "balcony_white", "bay": 3.2, "floor": 3.4, "trim": "#f2f1ed", "walls": {"Glass": ["clear_fin", 3.2, 3.4]}, "mats": {"Blade": ["render", "#F5F4F0"]}, "ops": [
				["poly", 0.0, 18.0, [[27.9, -14.5], [43.1, 14.4], [-28.2, 14.4], [-42.8, -14.3]]],
				["poly", 18.0, 186.0, [[25.5, -13.0], [39.5, 13.0], [-25.5, 13.0], [-39.5, -13.0]]],
				["box", "Blade", -22.0, 0.0, 0.0, 1.4, 193.9, 27.2],
				["box", "Blade", -11.0, 0.0, 0.0, 1.4, 193.9, 27.2],
				["box", "Blade", 0.0, 0.0, 0.0, 1.4, 193.9, 27.2],
				["box", "Blade", 11.0, 0.0, 0.0, 1.4, 193.9, 27.2],
				["box", "Blade", 22.0, 0.0, 0.0, 1.4, 193.9, 27.2],
				["use", "Glass"],
				["poly", 186.0, 193.9, [[20.0, -10.0], [31.0, 10.0], [-20.0, 10.0], [-31.0, -10.0]]],
			]}),
		# way:1529521451 Grove at Grand Bay: 8 parts, CTBUH height 94.0 m
		MiamiTowerSpecs.row("grove_at_grand_bay", "Grove at Grand Bay", 25.730460, -80.236896, 94.0, 87.9, 42.0, "Grove at Grand Bay", 2, ["grove at grand bay", "2669 south bayshore drive"], {
			"finish": "balcony_white", "bay": 3.0, "floor": 4.2, "trim": "#ebeae4", "walls": {"Glass": ["clear_fin", 3.0, 4.2]}, "ops": [
				["use", "Glass"],
				["tier", 0.0, 10.0, 86.0, 56.0],
				["use", "Facade"],
				["poly", 10.0, 26.8, [[-38.7, 2.0], [-15.3, 2.0], [-12.5, 4.8], [-12.5, 24.2], [-15.3, 27.0], [-38.7, 27.0], [-41.5, 24.2], [-41.5, 4.8]]],
				["poly", 26.8, 43.6, [[-36.5, 0.2], [-13.4, 4.1], [-11.1, 7.3], [-14.3, 26.5], [-17.5, 28.8], [-40.6, 24.9], [-42.9, 21.7], [-39.7, 2.5]]],
				["poly", 43.6, 60.4, [[-34.0, -1.1], [-11.9, 6.5], [-10.1, 10.0], [-16.4, 28.4], [-20.0, 30.1], [-42.1, 22.5], [-43.9, 19.0], [-37.6, 0.6]]],
				["poly", 60.4, 77.2, [[-31.3, -2.1], [-10.8, 9.1], [-9.6, 12.9], [-18.9, 29.9], [-22.7, 31.1], [-43.2, 19.9], [-44.4, 16.1], [-35.1, -0.9]]],
				["poly", 77.2, 94.0, [[-28.5, -2.6], [-10.1, 11.9], [-9.6, 15.8], [-21.5, 31.1], [-25.5, 31.6], [-43.9, 17.1], [-44.4, 13.2], [-32.5, -2.1]]],
				["poly", 10.0, 26.8, [[15.3, -27.0], [38.7, -27.0], [41.5, -24.2], [41.5, -4.8], [38.7, -2.0], [15.3, -2.0], [12.5, -4.8], [12.5, -24.2]]],
				["poly", 26.8, 43.6, [[17.5, -28.8], [40.6, -24.9], [42.9, -21.7], [39.7, -2.5], [36.5, -0.2], [13.4, -4.1], [11.1, -7.3], [14.3, -26.5]]],
				["poly", 43.6, 60.4, [[20.0, -30.1], [42.1, -22.5], [43.9, -19.0], [37.6, -0.6], [34.0, 1.1], [11.9, -6.5], [10.1, -10.0], [16.4, -28.4]]],
				["poly", 60.4, 77.2, [[22.7, -31.1], [43.2, -19.9], [44.4, -16.1], [35.1, 0.9], [31.3, 2.1], [10.8, -9.1], [9.6, -12.9], [18.9, -29.9]]],
				["poly", 77.2, 94.0, [[25.5, -31.6], [43.9, -17.1], [44.4, -13.2], [32.5, 2.1], [28.5, 2.6], [10.1, -11.9], [9.6, -15.8], [21.5, -31.1]]],
			]}),
		# way:749258403 Park Grove: 3 organic towers, CTBUH height 90.0 m
		MiamiTowerSpecs.row("park_grove_towers", "Park Grove", 25.729320, -80.238541, 90.0, 22.8, 56.0, "Park Grove (Miami)", 1, ["park grove", "2701 south bayshore drive"], {
			"finish": "balcony_white", "bay": 3.2, "floor": 4.0, "trim": "#e7e4dc", "walls": {"Colonnade": ["limestone_pier", 3.2, 4.0]}, "ops": [
				["use", "Colonnade"],
				["shape", "round", 0.0, 12.0, 96.0, 58.0, 10.0, 96.0, 58.0, -2.0, 10.0],
				["use", "Facade"],
				["shape", "ellipse", 12.0, 90.0, 26.0, 38.0, 20.0, 25.0, 36.0, 0.0, 0.0],
				["shape", "ellipse", 12.0, 90.0, 26.0, 38.0, 20.0, 25.0, 36.0, 32.0, 20.0],
				["shape", "ellipse", 12.0, 82.0, 28.0, 28.0, 20.0, 26.0, 26.0, -34.0, -4.0],
			]}),
	]
