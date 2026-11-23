class_name MiamiTowerSpecsEdgewater
extends RefCounted

## Miami TowerSpec rows for Arts & Entertainment District, Edgewater and Midtown (MI-3A).
## Positions, yaw_deg and footprint polygons come from OpenStreetMap outlines and
## parts in Miami.osm.pbf; standing heights follow docs/miami-landmark-sources.md.

static func entries() -> Array:
	return [
		# way:483326775 Marquis Miami: 3 parts, CTBUH top 207.0 m (OSM 212.1 m)
		MiamiTowerSpecs.row("marquis_miami", "Marquis Miami", 25.785186, -80.190256, 207.0, -80.6, 45.0, "Marquis Miami", 2, ["marquis miami", "1100 biscayne"], {
			"finish": "balcony_aqua", "bay": 3.2, "floor": 3.1, "trim": "#dce8ec",
			"walls": {"Glass": ["lowe_blue", 3.0, 3.4]}, "ops": [
				["poly", 0.0, 35.0, [[8.6, -1.3], [13.1, 20.4], [-8.2, 20.4], [-9.2, 14.1], [-13.6, -9.4], [6.2, -13.3]]],
				["poly", 0.0, 42.0, [[8.6, -1.3], [6.2, -13.3], [-13.6, -9.4], [-9.2, 14.1], [-20.4, 14.9], [-24.8, -6.3], [-22.5, -6.7], [-25.5, -21.5], [2.7, -27.3], [2.9, -26.3], [18.2, -29.4], [24.1, -0.4]]],
				["poly", 0.0, 198.0, [[33.2, 46.9], [-13.8, 46.9], [-20.4, 14.9], [-9.2, 14.1], [-8.2, 20.4], [13.1, 20.4], [8.6, -1.3], [24.1, -0.4]]],
				["use", "Glass"],
				["tier", 198.0, 206.6, 40.0, 26.0, 6.0, 30.0],
			]}),
		# way:255191962 Aria Reserve South: 0 parts, completed top 197.8 m (OSM 217.0 m)
		MiamiTowerSpecs.row("aria_reserve_south", "Aria Reserve South", 25.799670, -80.185749, 197.8, -89.7, 18.0, "Aria Reserve", 2, ["aria reserve south"], {
			"finish": "balcony_white", "bay": 3.2, "floor": 3.2, "trim": "#e7ecee",
			"walls": {"Glass": ["balcony_aqua", 3.2, 3.2]}, "ops": [
				["poly", 0.0, 189.0, [[30.9, 22.1], [-31.2, 22.1], [-32.1, -9.7], [-14.0, -9.7], [-13.8, 0.4], [15.4, -1.5], [14.8, -11.5], [30.0, -12.2]]],
				["use", "Glass"],
				["poly", 189.0, 197.8, [[28.5, 20.5], [-28.5, 20.5], [-29.0, -8.0], [-13.5, -8.0], [-13.5, 0.8], [14.5, -1.0], [14.5, -9.5], [27.5, -10.0]]],
			]}),
		# way:435730634 Aria Reserve North: 0 parts, completed top 197.8 m (OSM 217.0 m)
		MiamiTowerSpecs.row("aria_reserve_north", "Aria Reserve North", 25.800271, -80.185744, 197.8, 89.5, 35.0, "Aria Reserve", 2, ["aria reserve north"], {
			"finish": "balcony_white", "bay": 3.2, "floor": 3.2, "trim": "#e7ecee",
			"walls": {"Glass": ["balcony_aqua", 3.2, 3.2]}, "ops": [
				["poly", 0.0, 189.0, [[-7.5, 4.9], [-7.3, 8.1], [-32.0, 8.4], [-33.2, -22.6], [29.0, -22.6], [29.0, 9.0], [11.0, 9.7], [11.0, 5.1]]],
				["use", "Glass"],
				["poly", 189.0, 197.8, [[-7.0, 4.5], [-7.0, 7.2], [-29.5, 7.5], [-30.5, -20.5], [26.5, -20.5], [26.5, 7.8], [10.2, 8.2], [10.2, 4.6]]],
			]}),
		# way:954741754 Missoni Baia: 0 parts, CTBUH top 197.8 m (57 fl)
		MiamiTowerSpecs.row("missoni_baia", "Missoni Baia", 25.799019, -80.185931, 197.8, -1.8, 38.0, "Missoni Baia", 1, ["missoni baia"], {
			"finish": "balcony_white", "bay": 3.4, "floor": 3.4, "trim": "#f0f1ee",
			"walls": {"Glass": ["clear_fin", 3.2, 3.4]}, "ops": [
				["tier", 0.0, 24.0, 54.0, 32.0],
				["tier", 24.0, 190.0, 44.0, 25.0],
				["use", "Glass"],
				["tier", 190.0, 197.4, 40.0, 22.0],
				["ribs", "Trim", 24.0, 197.8, 44.4, 25.4, 8.8],
			]}),
		# way:468023516 Elysee Miami: 0 parts, CTBUH top 197.8 m (57 fl telescoping tower)
		MiamiTowerSpecs.row("elysee_miami", "Elysee Miami", 25.798523, -80.185638, 197.8, 89.3, 36.0, "Elysee Miami", 1, ["elysee miami"], {
			"finish": "balcony_white", "bay": 3.0, "floor": 3.4, "trim": "#ecebe6",
			"walls": {"Glass": ["silver_reflective", 2.8, 3.4]}, "ops": [
				["shape", "round", 0.0, 24.0, 44.0, 26.0, 4.0],
				["use", "Glass"],
				["shape", "round", 24.0, 86.0, 28.0, 20.0, 4.0],
				["use", "Facade"],
				["shape", "round", 86.0, 144.0, 34.0, 23.0, 4.5],
				["shape", "round", 144.0, 197.8, 40.0, 26.0, 5.0],
			]}),
		# way:444351430 Casa Bella by B&B Italia: 3 parts, OSM top 196.0 m
		MiamiTowerSpecs.row("casa_bella_miami", "Casa Bella by B&B Italia", 25.788613, -80.189549, 196.0, -1.5, 16.0, "Arts & Entertainment District", 1, ["casa bella miami", "casa bella by b&b italia"], {
			"finish": "balcony_white", "bay": 3.2, "floor": 3.4, "trim": "#eae9e4", "ops": [
				["poly", 0.0, 24.5, [[-10.8, -15.0], [-11.1, 23.2], [-20.2, 23.1], [-20.7, -3.4], [-48.3, -3.5], [-48.3, -1.6], [-55.6, -1.6], [-55.6, -3.4], [-82.9, -3.5], [-82.8, 10.1], [-96.4, 10.0], [-96.2, -15.8]]],
				["poly", 0.0, 31.5, [[22.9, -24.6], [22.5, -27.4], [21.6, -28.5], [19.8, -29.0], [-0.9, -29.9], [-2.6, -29.5], [-3.5, -27.2], [-3.0, -15.1], [-65.4, -15.5], [-65.4, -46.8], [24.4, -46.7]]],
				["poly", 0.0, 196.0, [[19.7, 20.7], [19.4, 21.9], [18.9, 22.7], [18.2, 23.3], [17.1, 23.5], [0.6, 22.9], [-1.3, 22.5], [-2.6, 21.4], [-3.2, 20.1], [-3.5, -27.2], [-2.6, -29.5], [-0.9, -29.9], [19.8, -29.0], [21.6, -28.5], [22.5, -27.4], [22.9, -24.6]]],
			]}),
		# way:643553505 Gran Paraiso: 0 parts, CTBUH top 185.0 m (OSM 192.5 m)
		MiamiTowerSpecs.row("gran_paraiso", "Gran Paraiso", 25.806176, -80.186709, 185.0, 88.2, 39.0, "Edgewater (Miami)", 1, ["gran paraiso"], {
			"finish": "balcony_white", "bay": 3.2, "floor": 3.3, "trim": "#e6eaec",
			"walls": {"Wave": ["balcony_aqua", 3.2, 3.3]}, "ops": [
				["poly", 0.0, 178.0, [[-33.7, 8.4], [-33.7, -21.6], [25.3, -21.6], [25.3, 9.2], [12.3, 9.2], [12.3, 0.9], [-16.5, 0.9], [-16.5, 8.4]]],
				["use", "Wave"],
				["tier", 178.0, 184.6, 52.0, 22.0, -4.2, -6.5],
			]}),
		# way:643553506 Paraiso Bay: 0 parts, CTBUH top 183.0 m (OSM 189.0 m)
		MiamiTowerSpecs.row("paraiso_bay", "Paraiso Bay", 25.806892, -80.186448, 183.0, -34.9, 36.0, "Edgewater (Miami)", 1, ["paraiso bay"], {
			"finish": "balcony_white", "bay": 3.2, "floor": 3.3, "trim": "#e8eaec",
			"walls": {"Ring": ["balcony_aqua", 3.0, 3.3]}, "ops": [
				["poly", 0.0, 176.0, [[28.9, -7.7], [29.1, 18.0], [-26.7, 18.0], [-26.9, -8.4], [-15.4, -8.4], [-15.3, -1.9], [13.2, -1.9], [13.1, -7.7]]],
				["use", "Ring"],
				["shape", "ellipse", 48.0, 128.0, 34.0, 22.0, 20.0, 34.0, 22.0, 1.0, 5.0],
				["tier", 176.0, 182.6, 48.0, 20.0, 1.0, 5.0],
			]}),
		# way:643553511 One Paraiso: 0 parts, CTBUH top 183.0 m (OSM 185.5 m)
		MiamiTowerSpecs.row("one_paraiso", "One Paraiso", 25.807187, -80.185632, 183.0, 88.6, 39.0, "Edgewater (Miami)", 1, ["one paraiso"], {
			"finish": "balcony_aqua", "bay": 3.2, "floor": 3.4, "trim": "#dfecee", "ops": [
				["poly", 0.0, 183.0, [[35.6, -12.3], [35.6, 8.3], [-15.1, 8.1], [-28.1, 8.3], [-28.0, -12.3]]],
			]}),
		# way:927927331 Aria on the Bay: 0 parts, CTBUH top 177.0 m (OSM 185.5 m)
		MiamiTowerSpecs.row("aria_on_the_bay", "Aria on the Bay", 25.793403, -80.187012, 177.0, 12.0, 30.0, "Aria on the Bay", 1, ["aria on the bay"], {
			"finish": "balcony_white", "bay": 3.2, "floor": 3.3, "trim": "#e7ecee",
			"walls": {"Wave": ["balcony_aqua", 3.2, 3.3]}, "ops": [
				["poly", 0.0, 36.0, [[49.5, 32.1], [-68.3, 31.1], [-69.8, 29.5], [-67.2, 3.0], [-43.2, -2.2], [-40.7, 0.4], [-36.2, -1.5], [-26.1, -7.6], [-20.1, -7.5], [-4.1, -12.8], [9.0, -15.4], [20.3, -18.6], [29.9, -19.1], [40.9, -21.2], [46.1, -14.2], [48.0, -3.7], [46.3, 0.3], [47.2, 10.4], [49.3, 19.1], [50.0, 29.3]]],
				["use", "Wave"],
				["shape", "ellipse", 36.0, 170.0, 74.0, 26.0, 24.0, 68.0, 24.0, -6.0, 6.0],
				["use", "Facade"],
				["shape", "ellipse", 170.0, 177.0, 60.0, 21.0, 24.0, 52.0, 18.0, -6.0, 6.0],
			]}),
		# way:468023495 Paramount Bay: 0 parts, OSM top 168.5 m
		MiamiTowerSpecs.row("paramount_bay", "Paramount Bay", 25.796792, -80.187679, 168.5, 0.2, 19.0, "Paramount Bay", 1, ["paramount bay"], {
			"finish": "balcony_aqua", "bay": 3.2, "floor": 3.5, "trim": "#dce8ec", "ops": [
				["poly", 0.0, 168.5, [[-13.7, 34.9], [-14.0, 52.4], [-34.4, 19.1], [-21.6, -7.0], [-10.1, -19.1], [0.6, -24.7], [9.6, -28.5], [39.3, -34.2], [38.0, -18.7], [31.8, -14.6], [20.8, -12.8], [13.7, -10.0], [5.5, -4.4], [-3.4, 9.9], [-11.4, 30.0]]],
			]}),
		# way:1360151970 Biscayne Beach: 0 parts, OSM top 167.6 m
		MiamiTowerSpecs.row("biscayne_beach", "Biscayne Beach", 25.805033, -80.185847, 167.6, -3.0, 43.0, "Biscayne Beach (Miami)", 1, ["biscayne beach"], {
			"finish": "balcony_white", "bay": 3.2, "floor": 3.2, "trim": "#e8eae6", "ops": [
				["poly", 0.0, 167.6, [[-20.6, 31.7], [-20.3, 23.8], [-13.3, 20.0], [3.8, 14.3], [6.0, 11.8], [-8.1, -11.0], [-13.6, -13.2], [-8.9, -16.8], [-9.3, -20.9], [-9.2, -26.6], [6.3, -29.8], [22.7, -16.4], [22.2, 13.2], [17.0, 28.5], [-18.3, 34.9]]],
			]}),
		# way:468023505 Quantum on the Bay: 2 parts, OSM top 165.9 m
		MiamiTowerSpecs.row("quantum_on_the_bay", "Quantum on the Bay", 25.794387, -80.186919, 165.9, -42.2, 88.0, "Quantum on the Bay", 1, ["quantum on the bay"], {
			"finish": "balcony_aqua", "bay": 3.2, "floor": 3.2, "trim": "#dce7ea",
			"walls": {"South": ["lowe_blue", 3.0, 3.3]}, "ops": [
				["poly", 0.0, 30.0, [[-44.3, -62.2], [-40.0, -73.0], [15.7, -80.9], [35.4, -65.8], [39.7, -16.2], [36.1, -8.0], [25.3, -1.3], [23.2, -4.1], [20.0, -10.4], [2.0, -5.9], [-3.1, 50.0], [-12.4, 54.4], [-11.9, 63.0], [-18.9, 68.2], [-29.2, 60.1], [-72.9, 28.9]]],
				["use", "South"],
				["poly", 0.0, 145.7, [[23.7, -66.5], [20.1, -63.5], [16.7, -61.2], [11.2, -58.3], [7.3, -56.9], [1.3, -55.3], [-7.0, -54.6], [-9.1, -54.7], [-13.2, -55.1], [-19.3, -56.4], [-27.0, -59.5], [-30.6, -61.5], [-34.0, -63.9], [-38.7, -68.0], [-40.1, -69.6], [-40.0, -73.0], [-42.1, -73.1], [-40.4, -80.9], [15.7, -80.9]]],
				["use", "Facade"],
				["poly", 0.0, 165.9, [[39.8, -18.4], [35.6, -8.5], [26.1, -0.5], [23.8, -3.1], [23.8, -6.3], [6.1, -17.9], [-5.0, -18.0], [-13.6, -24.2], [-24.1, -28.0], [-32.6, -30.9], [-29.1, -41.1], [-23.6, -46.4], [-5.5, -47.5], [28.4, -35.9], [39.1, -28.4]]],
			]}),
		# way:468023506 Opera Tower: 1 part, CTBUH top 165.5 m (56 fl)
		MiamiTowerSpecs.row("opera_tower_miami", "Opera Tower", 25.792422, -80.187119, 165.5, 29.0, 44.0, "Opera Tower", 1, ["opera tower", "opera tower miami"], {
			"finish": "balcony_white", "bay": 3.0, "floor": 3.0, "trim": "#eceae2",
			"walls": {"Crown": ["lowe_blue", 3.0, 3.2]}, "ops": [
				["shape", "round", 0.0, 30.0, 62.0, 46.0, 6.0],
				["poly", 0.0, 159.0, [[-20.5, -6.9], [-14.5, -12.7], [-6.8, -17.0], [2.4, -20.5], [12.2, -21.7], [18.7, -20.4], [25.6, -15.7], [27.0, -11.6], [25.8, -4.2], [22.4, 3.5], [17.1, 11.0], [9.0, 16.4], [2.6, 19.3], [-4.7, 20.6], [-15.1, 20.6], [-21.1, 18.7], [-26.8, 13.4], [-27.7, 6.8], [-25.0, -0.5]]],
				["use", "Crown"],
				["shape", "ellipse", 159.0, 165.5, 46.0, 34.0, 20.0],
			]}),
		# way:628377019 Icon Bay: 0 parts, CTBUH top 161.0 m (OSM 168.0 m)
		MiamiTowerSpecs.row("icon_bay_edgewater", "Icon Bay", 25.803591, -80.187266, 161.0, 88.9, 39.0, "Edgewater (Miami)", 1, ["icon bay", "icon bay miami"], {
			"finish": "balcony_white", "bay": 3.2, "floor": 3.3, "trim": "#e6eaec",
			"walls": {"Glass": ["lowe_blue", 3.0, 3.4]}, "ops": [
				["poly", 0.0, 155.0, [[-32.2, 7.9], [-31.9, -17.9], [29.2, -17.9], [27.4, 5.0], [17.2, 5.6], [14.4, 2.5], [-15.3, 2.1], [-16.6, 7.9]]],
				["use", "Glass"],
				["tier", 155.0, 160.6, 52.0, 19.0, -1.5, -6.0],
			]}),
	]
