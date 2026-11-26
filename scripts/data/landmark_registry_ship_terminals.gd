class_name LandmarkRegistryShipTerminals
extends RefCounted

## Principal passenger ship terminals: the ferry terminals of the
## Nordic/Baltic capitals and the cruise terminals of the major USA ports
## with big liners. Each is a secondary "Ferry terminal" / "Cruise terminal"
## landmark (a pin on the map, a city-wide search hit, a kit model from
## LandmarkSetShipTerminals), standing beside a city's icons, never instead
## of them. `outline_m` (plus `outline_b_m` at `height_b_m` for a second
## hall) is the measured footprint in model-frame metres, x east and z south
## from lat/lon with yaw_deg 0, from the OSM way or relation noted per entry
## (OpenStreetMap contributors, ODbL). Heights are mapped where OSM tags
## them, estimated from the terminal type where not (marked EST).
## `clear_rect_m` covers the halls with a 40 m margin.

static func entries() -> Array:
	return [
		# D-terminal, Tallinn (way 26886044, 38 points, height 18.4 mapped).
		{"type": "tallinn_d_terminal", "name": "Tallinn D-Terminal", "lat": 59.443501, "lon": 24.766911,
			"radius_m": 4000.0, "wiki_title": "Port of Tallinn", "height_m": 18.4, "kind": "Ferry terminal",
			"secondary": true, "yaw_deg": 0.0, "clear_m": 24.0,
			"clear_rect_m": [0.0, 0.0, 107.0, 90.0],
			"outline_m": [[29.2, -43.4], [60.4, 40.1], [52.9, 42.8], [55.0, 48.7], [45.0, 48.3], [44.3, 45.9], [34.2, 49.9], [24.3, 25.5], [-1.7, 20.6], [-2.5, 25.9], [-21.8, 22.8], [-50.8, 32.9], [-59.6, 2.0], [-64.7, 4.1], [-66.8, -2.3], [-61.6, -4.4], [-64.9, -14.5], [27.4, -48.7]],
			"aliases": ["tallinn d-terminal", "d-terminal", "d-terminaali", "tallinna d-terminal"]},
		# Riga Ferry Terminal, Eksporta iela 3A (way 87775719, 18 points; no mapped height, EST).
		{"type": "riga_ferry_terminal", "name": "Riga Ferry Terminal", "lat": 56.959310, "lon": 24.094659,
			"radius_m": 4000.0, "wiki_title": "Port of Riga", "height_m": 11.0, "kind": "Ferry terminal",
			"secondary": true, "yaw_deg": 0.0, "clear_m": 24.0,
			"clear_rect_m": [0.0, 0.0, 70.0, 99.0],
			"outline_m": [[9.4, 59.2], [-20.2, -7.6], [-17.7, -8.8], [-19.9, -14.7], [-14.3, -16.8], [-25.8, -49.1], [-2.8, -57.9], [12.2, -18.7], [1.3, -14.3], [12.0, 16.7], [16.2, 15.3], [29.8, 51.6]],
			"aliases": ["riga ferry terminal", "rīgas pasažieru osta", "riga passenger terminal"]},
		# Copenhagen Ferry Terminal, the DFDS terminal at Dampfærgevej (way 132470968, 25 points,
		# building unnamed in OSM; no mapped height, EST).
		{"type": "copenhagen_ferry_terminal", "name": "Copenhagen Ferry Terminal", "lat": 55.701566, "lon": 12.596045,
			"radius_m": 4000.0, "wiki_title": "Port of Copenhagen", "height_m": 10.0, "kind": "Ferry terminal",
			"secondary": true, "yaw_deg": 0.0, "clear_m": 24.0,
			"clear_rect_m": [0.0, 0.0, 97.0, 105.0],
			"outline_m": [[56.9, -58.7], [49.3, -65.2], [19.9, -31.1], [18.1, -32.6], [-11.6, 5.2], [-14.4, 2.9], [-35.6, 27.5], [-32.7, 30.0], [-55.5, 57.3], [-49.4, 62.4], [-24.1, 34.4], [-20.8, 37.2], [26.6, -17.8], [23.7, -20.2]],
			"aliases": ["copenhagen ferry terminal", "københavns færgeterminal", "dfds terminal copenhagen"]},
		# Oslo Cruise Terminal, Filipstad (way 111833921 "Oslo Cruiseterminal", 4 points, height 6.5 mapped).
		{"type": "oslo_cruise_terminal", "name": "Oslo Cruise Terminal", "lat": 59.906684, "lon": 10.734988,
			"radius_m": 4000.0, "wiki_title": "Port of Oslo", "height_m": 6.5, "kind": "Cruise terminal",
			"secondary": true, "yaw_deg": 0.0, "clear_m": 24.0,
			"clear_rect_m": [0.0, 0.0, 54.0, 65.0],
			"outline_m": [[-2.5, -24.7], [-13.9, -20.7], [2.5, 24.7], [13.9, 20.7]],
			"aliases": ["oslo cruise terminal", "oslo cruiseterminal", "filipstad cruise terminal"]},
		# Port Canaveral Terminal 1 (relation 10840703 outer way 460074697, 38 points; no mapped height, EST).
		{"type": "canaveral_terminal_1", "name": "Port Canaveral Terminal 1", "lat": 28.407656, "lon": -80.612436,
			"radius_m": 4000.0, "wiki_title": "Port Canaveral", "height_m": 14.0, "kind": "Cruise terminal",
			"secondary": true, "yaw_deg": 0.0, "clear_m": 24.0,
			"clear_rect_m": [0.0, 0.0, 208.0, 121.0],
			"outline_m": [[-70.3, -61.8], [167.8, -62.7], [167.8, -55.7], [58.3, -55.2], [58.5, -6.3], [42.4, -6.2], [42.4, -17.6], [39.0, -17.7], [38.7, -55.4], [33.4, -55.4], [32.0, 35.0], [96.4, 34.7], [96.5, 44.1], [40.1, 44.4], [27.5, 56.7], [27.4, 76.9], [37.8, 77.0], [39.2, 80.9], [-41.6, 80.9], [-68.7, -33.6], [-73.4, -33.7], [-73.3, -55.8], [-70.4, -56.0]],
			"aliases": ["port canaveral terminal 1", "canaveral cruise terminal", "cruise terminal 1 canaveral"]},
		# Port Everglades Terminal 25: the long pier hall (way 108334371, 17 points) with its
		# connector annex (way 108059864, 11 points); no mapped heights, EST.
		{"type": "everglades_terminal_25", "name": "Port Everglades Terminal 25", "lat": 26.087294, "lon": -80.115005,
			"radius_m": 4000.0, "wiki_title": "Port Everglades", "height_m": 12.0, "kind": "Cruise terminal",
			"secondary": true, "yaw_deg": 0.0, "clear_m": 24.0,
			"clear_rect_m": [0.0, 0.0, 88.0, 257.0],
			"outline_m": [[7.3, 97.9], [-9.3, 36.3], [-4.5, 34.9], [-47.8, -109.8], [-13.8, -119.4], [44.8, 100.2], [27.3, 116.6], [21.7, 111.5], [5.1, 116.7], [0.2, 100.1]],
			"outline_b_m": [[-36.6, 206.3], [-28.6, 217.1], [-30.1, 209.3], [-12.9, 205.4], [-29.0, 143.3], [-38.8, 146.7]],
			"height_b_m": 8.0,
			"aliases": ["port everglades terminal 25", "everglades cruise terminal", "terminal 25 everglades"]},
		# Port of Galveston Cruise Terminal 25 (way 1143763503, 24 points; no mapped height, EST).
		# The larger way 287982754 of the same name spans the garage complex and is not modelled.
		{"type": "galveston_terminal_25", "name": "Port of Galveston Cruise Terminal 25", "lat": 29.307913, "lon": -94.800111,
			"radius_m": 4000.0, "wiki_title": "Port of Galveston", "height_m": 12.0, "kind": "Cruise terminal",
			"secondary": true, "yaw_deg": 0.0, "clear_m": 24.0,
			"clear_rect_m": [0.0, 0.0, 175.0, 96.0],
			"outline_m": [[-83.0, 6.0], [-74.1, 42.3], [-119.5, 56.0], [-135.3, 4.6], [-89.8, -9.1], [-87.1, -0.2], [-72.5, -0.8], [-74.7, -29.1], [48.2, -31.7], [47.9, -39.5], [107.9, -41.6], [109.8, -34.1], [111.8, 22.4], [-27.2, 27.3], [-27.5, 16.6], [-41.6, 17.1], [-42.0, 4.6]],
			"aliases": ["port of galveston cruise terminal 25", "galveston cruise terminal", "galveston terminal 25"]},
		# Manhattan Cruise Terminal, piers 88/90 (ways 265357849/265357869, 18/11 points,
		# heights 15.6/16.3 mapped): the taller north hall carries the entry height.
		{"type": "manhattan_cruise_terminal", "name": "Manhattan Cruise Terminal", "lat": 40.767027, "lon": -73.999322,
			"radius_m": 4000.0, "wiki_title": "New York Passenger Ship Terminal", "height_m": 16.3, "kind": "Cruise terminal",
			"secondary": true, "yaw_deg": 0.0, "clear_m": 24.0,
			"clear_rect_m": [0.0, 0.0, 222.0, 200.0],
			"outline_m": [[182.0, 129.1], [163.9, 159.3], [-105.2, 10.2], [-88.4, -20.2]],
			"outline_b_m": [[88.5, 20.5], [-182.0, -129.7], [-165.4, -159.8], [105.3, -9.8]],
			"height_b_m": 15.6,
			"aliases": ["manhattan cruise terminal", "new york passenger ship terminal", "pier 88", "pier 90"]},
		# Los Angeles World Cruise Center, the Berth 93 passenger terminal (way 345534092, 42 points,
		# "Passenger Terminal", height 20.0 mapped).
		{"type": "los_angeles_cruise_terminal", "name": "Los Angeles World Cruise Center", "lat": 33.747386, "lon": -118.276949,
			"radius_m": 4000.0, "wiki_title": "Port of Los Angeles", "height_m": 20.0, "kind": "Cruise terminal",
			"secondary": true, "yaw_deg": 0.0, "clear_m": 24.0,
			"clear_rect_m": [0.0, 0.0, 194.0, 155.0],
			"outline_m": [[-117.6, -111.1], [-153.8, -50.4], [93.8, 97.0], [90.2, 103.1], [110.3, 114.6], [152.2, 48.2]],
			"aliases": ["los angeles world cruise center", "world cruise center", "san pedro cruise terminal", "los angeles cruise terminal"]},
		# Smith Cove Cruise Terminal, Seattle Terminal 91 (way 119238635, 16 points; no mapped height, EST).
		{"type": "seattle_smith_cove_terminal", "name": "Smith Cove Cruise Terminal", "lat": 47.627704, "lon": -122.382924,
			"radius_m": 4000.0, "wiki_title": "Port of Seattle", "height_m": 12.0, "kind": "Cruise terminal",
			"secondary": true, "yaw_deg": 0.0, "clear_m": 24.0,
			"clear_rect_m": [0.0, 0.0, 70.0, 115.0],
			"outline_m": [[-29.1, -72.2], [27.8, -72.7], [30.0, -43.2], [27.9, -43.2], [28.7, 71.4], [11.7, 71.5], [11.8, 74.8], [-28.0, 71.9]],
			"aliases": ["smith cove cruise terminal", "terminal 91 seattle", "seattle cruise terminal", "pier 91 seattle"]},
	]
