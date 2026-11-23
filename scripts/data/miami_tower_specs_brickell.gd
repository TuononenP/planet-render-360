class_name MiamiTowerSpecsBrickell
extends RefCounted

## Miami TowerSpec rows for Brickell, Brickell Key and South Brickell (MI-3B).

static func entries() -> Array:
	return [
		# way:301823928 Cipriani Residences Miami: 0 parts, topped-out height 289.6 m
		MiamiTowerSpecs.row("cipriani_residences_miami", "Cipriani Residences Miami", 25.759410, -80.193257, 289.6, -76.8, 36.0, "Cipriani Residences Miami", 3, ["cipriani residences miami", "1420 south miami avenue"], {
			"finish": "lowe_blue", "bay": 2.8, "floor": 3.5, "trim": "#dce2e6", "rib": 4.8, "walls": {"Crown": ["clear_fin", 2.8, 3.8], "Base": ["white_panel", 3.4, 4.2]}, "ops": [
				["use", "Base"],
				["shape", "round", 0.0, 24.0, 56.0, 38.0, 7.0],
				["use", "Facade"],
				["poly", 24.0, 178.0, [[-21.0, -6.9], [-9.5, -14.6], [9.5, -14.6], [21.0, -5.6], [19.3, 6.9], [8.4, 14.2], [-8.4, 14.2], [-19.3, 5.6]], 0.96],
				["poly", 178.0, 256.0, [[-20.1, -6.6], [-9.1, -13.9], [9.1, -13.9], [20.1, -5.4], [18.5, 6.6], [8.1, 13.5], [-8.1, 13.5], [-18.5, 5.4]], 0.9],
				["poly", 256.0, 278.0, [[-18.1, -5.9], [-8.2, -12.4], [8.2, -12.4], [18.1, -4.9], [16.7, 5.9], [7.3, 12.1], [-7.3, 12.1], [-16.7, 4.9]], 0.88],
				["use", "Crown"],
				["shape", "round", 278.0, 289.6, 29.0, 17.5, 6.0, 26.0, 15.5],
			]}),
		# way:676817045 Panorama Tower: 1 part, CTBUH height 264.6 m (OSM 265.0 m)
		MiamiTowerSpecs.row("panorama_tower", "Panorama Tower", 25.763170, -80.190280, 264.6, 14.1, 42.4, "Panorama Tower", 3, ["panorama tower", "1101 brickell bay drive"], {
			"finish": "balcony_aqua", "bay": 3.0, "floor": 3.1, "trim": "#cfd8dc", "walls": {"Podium": ["silver_reflective", 3.2, 3.2], "Spine": ["silver_reflective", 3.0, 3.4]}, "ops": [
				["use", "Podium"],
				["poly", 0.0, 58.0, [[-40.0, -33.9], [10.4, -15.3], [11.0, -5.3], [47.5, 32.7], [56.0, 49.0], [-42.5, 49.0], [-40.8, -15.3]]],
				["use", "Facade"],
				["shape", "round", 58.0, 254.0, 33.2, 68.5, 11.0, 33.2, 68.5, -10.0, 8.8],
				["use", "Spine"],
				["tier", 58.0, 260.0, 12.0, 46.0, -19.5, 8.8],
				["shape", "round", 254.0, 264.6, 27.0, 56.0, 9.0, 25.0, 52.0, -10.0, 8.8],
			]}),
		# way:933174532 Four Seasons Hotel & Tower Miami: 6 parts, OSM top 240.0 m
		MiamiTowerSpecs.row("four_seasons_miami", "Four Seasons Hotel & Tower Miami", 25.758713, -80.191435, 240.0, 12.4, 69.3, "Four Seasons Hotel Miami", 3, ["four seasons miami", "four seasons hotel miami", "1435 brickell avenue"], {
			"finish": "white_granite", "bay": 3.2, "floor": 3.5, "trim": "#dcd8ce", "walls": {"Glass": ["green_glass", 3.0, 3.5]}, "ops": [
				["poly", 0.0, 21.0, [[-8.7, -40.0], [52.8, -40.0], [67.2, -24.2], [72.7, -2.8], [68.1, 15.0], [49.8, 35.8], [-41.8, 32.7], [-40.8, -9.7]]],
				["tier", 0.0, 57.0, 46.0, 45.0, -64.5, -17.2],
				["tier", 0.0, 206.0, 46.2, 31.4, -32.0, -24.6],
				["use", "Glass"],
				["tier", 18.0, 224.0, 34.0, 32.4, -30.5, -24.6],
				["use", "Facade"],
				["tier", 206.0, 232.0, 38.0, 26.5, -31.5, -24.6],
				["use", "Glass"],
				["shape", "chamfer", 232.0, 240.0, 30.0, 21.0, 3.5, 28.0, 19.5, -31.5, -24.6],
			]}),
		# site 25.768950,-80.189500 Baccarat Residences Brickell: 0 parts, late-2026 standing height 225.0 m
		MiamiTowerSpecs.row("baccarat_residences_brickell", "Baccarat Residences Brickell", 25.768950, -80.189500, 225.0, 88.0, 22.0, "Baccarat Residences Brickell", 2, ["baccarat residences brickell", "444 brickell avenue"], {
			"finish": "clear_fin", "bay": 2.9, "floor": 3.4, "trim": "#e2e5e8", "walls": {"Wave": ["balcony_aqua", 3.0, 3.4]}, "ops": [
				["tier", 0.0, 24.0, 42.0, 30.0],
				["use", "Wave"],
				["poly", 24.0, 145.0, [[-19.0, -6.3], [-8.6, -13.1], [8.6, -13.1], [19.0, -5.2], [17.5, 6.3], [7.6, 12.8], [-7.6, 12.8], [-17.5, 5.2]], 0.96],
				["use", "Facade"],
				["poly", 145.0, 216.0, [[-18.2, -6.1], [-8.2, -12.5], [8.2, -12.5], [18.2, -5.0], [16.8, 6.1], [7.3, 12.2], [-7.3, 12.2], [-16.8, 5.0]], 0.93],
				["shape", "round", 216.0, 225.0, 30.0, 18.5, 5.0],
			]}),
		# way:954745204 Brickell Flatiron: 0 parts, CTBUH height 224.0 m
		MiamiTowerSpecs.row("brickell_flatiron", "Brickell Flatiron", 25.764104, -80.192935, 224.0, 88.3, 54.8, "Brickell Flatiron", 3, ["brickell flatiron", "1000 brickell plaza"], {
			"finish": "balcony_aqua", "bay": 2.8, "floor": 3.4, "trim": "#dce5e7", "walls": {"Glass": ["lowe_blue", 2.8, 3.6]}, "ops": [
				["use", "Glass"],
				["poly", 0.0, 46.0, [[-17.2, -24.6], [52.3, -6.5], [56.6, 1.4], [56.7, 9.6], [54.7, 19.7], [-24.7, 19.7], [-29.0, 17.7], [-28.8, 0.8], [-24.3, -17.9]]],
				["use", "Facade"],
				["shape", "tri", 46.0, 152.0, 76.0, 38.0, 8.5, 74.0, 37.0, 11.0, -1.0],
				["shape", "tri", 152.0, 214.0, 74.0, 37.0, 8.5, 70.0, 35.0, 11.0, -1.0],
				["use", "Glass"],
				["shape", "tri", 214.0, 224.0, 62.0, 30.0, 7.5, 58.0, 28.0, 10.0, -1.0],
			]}),
		# way:995060605 830 Brickell: 0 parts, CTBUH height 220.7 m (OSM 220.0 m)
		MiamiTowerSpecs.row("830_brickell", "830 Brickell", 25.766060, -80.192485, 220.7, -79.0, 36.0, "830 Brickell", 3, ["830 brickell", "830 brickell plaza"], {
			"finish": "lowe_blue", "bay": 3.0, "floor": 4.0, "trim": "#b8c2c8", "walls": {"Upper": ["clear_fin", 3.0, 4.0], "Base": ["steel_panel", 3.5, 4.0]}, "ops": [
				["use", "Base"],
				["poly", 0.0, 40.0, [[25.0, -13.2], [32.2, 15.9], [30.7, 23.0], [-38.1, 23.0], [-46.5, -16.4], [-20.9, -22.3], [-18.0, -8.2], [2.2, -8.2]]],
				["use", "Facade"],
				["tier", 40.0, 128.0, 48.0, 34.0, -4.0, 3.5],
				["gap", 128.0, 132.0, 44.0, 31.0, -2.5, 3.5],
				["use", "Upper"],
				["tier", 132.0, 212.0, 46.0, 33.0, -1.0, 4.5],
				["use", "Facade"],
				["poly", 212.0, 220.7, [[-22.0, -10.5], [20.5, -10.5], [20.5, 19.5], [-22.0, 19.5]]],
			]}),
		# way:1071017393 Echo Brickell: 0 parts, OSM top 194.0 m
		MiamiTowerSpecs.row("echo_brickell", "Echo Brickell", 25.758041, -80.192418, 194.0, -76.9, 30.3, "Echo Brickell", 2, ["echo brickell", "1451 brickell avenue"], {
			"finish": "clear_fin", "bay": 2.8, "floor": 3.4, "trim": "#e6e8ea", "walls": {"Balcony": ["balcony_white", 3.0, 3.4]}, "ops": [
				["poly", 0.0, 38.0, [[-16.1, 8.1], [-10.4, -8.4], [-6.4, -16.4], [32.2, -16.4], [32.3, 16.6], [-18.1, 16.6]]],
				["use", "Balcony"],
				["tier", 38.0, 146.0, 42.0, 26.0, 6.0, 0.2],
				["gap", 146.0, 152.0, 38.0, 23.0, 6.0, 0.2],
				["use", "Facade"],
				["tier", 152.0, 188.0, 44.0, 27.5, 4.5, 0.2],
				["poly", 188.0, 194.0, [[-14.0, -11.5], [23.0, -11.5], [23.0, 12.0], [-14.0, 12.0]]],
			]}),
		# way:480909183 St. Regis Residences Brickell: 0 parts, topped-out height 192.0 m
		MiamiTowerSpecs.row("st_regis_brickell", "St. Regis Residences Brickell", 25.753697, -80.196711, 192.0, -37.1, 46.0, "St. Regis Residences, Miami", 2, ["st regis brickell", "1809 brickell avenue"], {
			"finish": "limestone_pier", "bay": 3.2, "floor": 3.8, "trim": "#dfd7c8", "walls": {"Terrace": ["balcony_white", 3.2, 3.8]}, "ops": [
				["tier", 0.0, 22.0, 56.0, 34.0],
				["use", "Terrace"],
				["shape", "chamfer", 22.0, 128.0, 46.0, 26.0, 4.0],
				["shape", "chamfer", 128.0, 168.0, 39.0, 23.0, 3.5],
				["use", "Facade"],
				["shape", "chamfer", 168.0, 186.0, 31.0, 19.5, 3.0],
				["poly", 186.0, 192.0, [[-11.5, -7.5], [11.5, -7.5], [11.5, 7.5], [-11.5, 7.5]]],
			]}),
		# way:465518927 Mint at Riverfront: 2 parts, OSM top 192.3 m
		MiamiTowerSpecs.row("mint_at_riverfront", "Mint at Riverfront", 25.769499, -80.195162, 192.3, -1.2, 58.6, "Mint at Riverfront", 1, ["mint at riverfront", "92 southwest 3rd street"], {
			"finish": "balcony_aqua", "bay": 3.0, "floor": 3.4, "trim": "#d6e2e0", "walls": {"Glass": ["green_glass", 3.0, 3.4]}, "ops": [
				["poly", 0.0, 18.0, [[31.2, -43.0], [31.9, -29.7], [20.6, 6.6], [13.8, 20.4], [-10.5, 28.3], [-37.5, 33.9], [-39.9, -43.0]]],
				["poly", 18.0, 184.0, [[-22.8, -26.9], [-3.1, -28.9], [0.7, -9.0], [5.8, 5.0], [13.8, 20.4], [-10.5, 28.3], [-37.6, 33.9], [-38.0, 19.8], [-22.9, 14.2]]],
				["use", "Glass"],
				["poly", 184.0, 192.3, [[-20.0, -18.0], [-4.0, -19.0], [8.0, 16.0], [-12.0, 24.0], [-32.0, 26.0]]],
			]}),
		# way:300211766 Plaza on Brickell Tower I: 0 parts, CTBUH height 186.0 m (OSM 190.5 m)
		MiamiTowerSpecs.row("plaza_on_brickell_i", "Plaza on Brickell Tower I", 25.765030, -80.190191, 186.0, 13.1, 21.5, "Plaza on Brickell", 1, ["plaza on brickell tower i", "951 brickell avenue"], {
			"finish": "balcony_white", "bay": 3.0, "floor": 3.3, "trim": "#e4e4df", "walls": {"Glass": ["lowe_blue", 3.0, 3.3]}, "ops": [
				["tier", 0.0, 32.0, 62.0, 26.5],
				["shape", "round", 32.0, 177.0, 58.0, 24.5, 6.0],
				["use", "Glass"],
				["shape", "round", 177.0, 186.0, 44.0, 19.0, 5.0],
			]}),
		# way:435234024 Infinity at Brickell: 0 parts, OSM top 186.4 m
		MiamiTowerSpecs.row("infinity_at_brickell", "Infinity at Brickell", 25.761122, -80.194284, 186.4, 87.1, 51.0, "Infinity at Brickell", 2, ["infinity at brickell", "60 southwest 13th street"], {
			"finish": "balcony_white", "bay": 3.0, "floor": 3.4, "trim": "#ecece8", "walls": {"Glass": ["lowe_blue", 3.0, 3.5]}, "mats": {"Arch": ["render", "#F2F1EC"]}, "ops": [
				["tier", 0.0, 34.0, 74.0, 34.0],
				["tier", 34.0, 166.0, 58.0, 24.0, 4.0, 0.0],
				["use", "Glass"],
				["tier", 34.0, 174.0, 28.0, 25.2, 6.0, 0.0],
				["box", "Arch", -10.0, 166.0, 0.0, 5.5, 20.4, 24.4],
				["box", "Arch", 22.0, 166.0, 0.0, 5.5, 20.4, 24.4],
				["box", "Arch", 6.0, 181.4, 0.0, 37.5, 5.0, 24.4],
			]}),
		# way:1552890381 1201 Brickell Bay Drive: 0 parts, OSM top 188.0 m
		MiamiTowerSpecs.row("citadel_1201_brickell", "1201 Brickell Bay Drive", 25.761194, -80.189291, 188.0, 12.2, 58.8, "1201 Brickell Bay Drive", 1, ["1201 brickell bay drive"], {
			"finish": "clear_fin", "bay": 3.0, "floor": 4.0, "trim": "#c6cdd2", "walls": {"Lower": ["lowe_blue", 3.0, 4.0]}, "ops": [
				["use", "Lower"],
				["tier", 0.0, 28.0, 76.0, 48.0],
				["use", "Facade"],
				["shape", "chamfer", 28.0, 134.0, 54.0, 36.0, 5.0],
				["shape", "chamfer", 134.0, 180.0, 48.0, 32.0, 4.5],
				["poly", 180.0, 188.0, [[-20.0, -13.0], [20.0, -13.0], [20.0, 13.0], [-20.0, 13.0]]],
			]}),
		# way:296968438 Icon Brickell North Tower: 0 parts, CTBUH height 178.6 m (OSM 179.0 m)
		MiamiTowerSpecs.row("icon_brickell_north", "Icon Brickell North Tower", 25.769055, -80.188626, 178.6, 0.0, 58.2, "Icon Brickell", 2, ["icon brickell north", "475 brickell avenue"], {
			"finish": "balcony_white", "bay": 3.0, "floor": 3.1, "trim": "#e6e6e2", "walls": {"Glass": ["silver_reflective", 3.0, 3.1]}, "ops": [
				["tier", 0.0, 38.0, 76.0, 44.0],
				["poly", 38.0, 170.0, [[-38.0, 20.0], [-36.0, 1.5], [-3.0, -0.5], [18.0, -26.0], [42.0, -15.0], [12.0, 20.0]]],
				["use", "Glass"],
				["poly", 170.0, 178.6, [[-28.0, 15.0], [-26.0, 2.0], [16.0, -19.0], [34.0, -11.0], [10.0, 15.0]]],
			]}),
		# way:296968436 Icon Brickell South Tower: 0 parts, CTBUH height 178.6 m (OSM 179.0 m)
		MiamiTowerSpecs.row("icon_brickell_south", "Icon Brickell South Tower", 25.768306, -80.188648, 178.6, 13.9, 45.9, "Icon Brickell", 2, ["icon brickell south", "495 brickell avenue"], {
			"finish": "balcony_white", "bay": 3.0, "floor": 3.1, "trim": "#e6e6e2", "walls": {"Glass": ["silver_reflective", 3.0, 3.1]}, "ops": [
				["poly", 0.0, 38.0, [[-32.7, 15.2], [-27.7, -10.7], [42.7, -10.9], [37.7, 15.2]]],
				["poly", 38.0, 170.0, [[-30.0, 13.5], [-25.5, -9.8], [39.0, -9.8], [34.5, 13.5]]],
				["use", "Glass"],
				["poly", 170.0, 178.6, [[-23.0, 10.5], [-19.5, -7.5], [31.0, -7.5], [27.5, 10.5]]],
			]}),
		# way:954745216 SLS Lux Brickell: 0 parts, CTBUH height 181.4 m, clear held to 36 m by 830 Brickell
		MiamiTowerSpecs.row("sls_lux_brickell", "SLS Lux Brickell", 25.765908, -80.192883, 181.4, 89.1, 36.0, "SLS Lux Brickell", 2, ["sls lux brickell", "805 south miami avenue"], {
			"finish": "balcony_aqua", "bay": 3.0, "floor": 3.2, "trim": "#dfe6e8", "walls": {"Glass": ["lowe_blue", 3.0, 3.4]}, "ops": [
				["tier", 0.0, 34.0, 74.0, 52.0],
				["tier", 34.0, 154.0, 48.0, 34.0, -4.0, 4.0],
				["use", "Glass"],
				["tier", 154.0, 174.0, 42.0, 29.0, -4.0, 4.0],
				["poly", 174.0, 181.4, [[-20.0, -6.5], [12.0, -6.5], [12.0, 14.5], [-20.0, 14.5]]],
			]}),
		# way:954745215 Brickell Heights: 0 parts, OSM top 169.0 m
		MiamiTowerSpecs.row("brickell_heights_east", "Brickell Heights", 25.765721, -80.193895, 169.0, -2.4, 68.4, "Brickell Heights", 1, ["brickell heights", "55 southwest 9th street"], {
			"finish": "balcony_white", "bay": 3.0, "floor": 3.4, "trim": "#e4e5e2", "walls": {"Glass": ["lowe_blue", 3.0, 3.4]}, "ops": [
				["tier", 0.0, 30.0, 108.0, 38.0, -8.0, 0.0],
				["tier", 30.0, 162.0, 41.0, 29.0, 22.0, 0.0],
				["tier", 30.0, 154.0, 39.0, 29.0, -34.0, 0.0],
				["use", "Glass"],
				["poly", 162.0, 169.0, [[6.0, -11.5], [38.0, -11.5], [38.0, 11.5], [6.0, 11.5]]],
				["poly", 154.0, 161.0, [[-50.0, -11.5], [-18.0, -11.5], [-18.0, 11.5], [-50.0, 11.5]]],
			]}),
		# way:954745212 Solitair Brickell: 1 part, OSM top 169.0 m
		MiamiTowerSpecs.row("solitair_brickell", "Solitair Brickell", 25.766121, -80.194495, 169.0, -1.4, 42.8, "Solitair Brickell", 2, ["solitair brickell", "86 southwest 8th street"], {
			"finish": "balcony_white", "bay": 3.0, "floor": 3.3, "trim": "#e2dfd8", "walls": {"Glass": ["clear_fin", 3.0, 3.4]}, "mats": {"Lattice": ["render", "#EAE7DF"]}, "ops": [
				["tier", 0.0, 24.0, 58.0, 38.0, 4.8, 2.0],
				["tier", 24.0, 162.0, 42.0, 29.6, 4.8, -0.3],
				["diagrid", "Lattice", 24.0, 162.0, 42.2, 29.8, 15.3, 4, 4.8, -0.3],
				["use", "Glass"],
				["poly", 162.0, 169.0, [[-12.0, -11.5], [21.6, -11.5], [21.6, 10.9], [-12.0, 10.9]]],
			]}),
		# way:300492232 Jade Residences at Brickell Bay: 0 parts, OSM top 163.1 m
		MiamiTowerSpecs.row("jade_at_brickell_bay", "Jade Residences at Brickell Bay", 25.760319, -80.189586, 163.1, -77.8, 43.9, "Jade at Brickell Bay", 1, ["jade at brickell bay", "1331 brickell bay drive"], {
			"finish": "balcony_aqua", "bay": 3.0, "floor": 3.3, "trim": "#cde0df", "walls": {"Sail": ["green_glass", 3.0, 3.4]}, "ops": [
				["tier", 0.0, 26.0, 68.0, 28.0, 0.0, 4.8],
				["shape", "round", 26.0, 151.0, 64.0, 25.0, 5.5, 62.0, 24.0, 0.0, 4.8],
				["use", "Sail"],
				["shape", "ellipse", 151.0, 163.1, 46.0, 18.0, 20.0, 36.0, 13.0, 0.0, 4.8],
			]}),
		# way:301776791 Santa Maria: 0 parts, OSM top 159.7 m
		MiamiTowerSpecs.row("santa_maria_brickell", "Santa Maria", 25.755446, -80.194962, 159.7, -42.3, 53.5, "Santa Maria (building)", 1, ["santa maria brickell", "1643 brickell avenue"], {
			"finish": "balcony_white", "bay": 3.2, "floor": 3.1, "trim": "#ebe9e2", "mats": {"Frame": ["render", "#F0EFE9"]}, "ops": [
				["shape", "chamfer", 0.0, 146.0, 78.0, 24.0, 4.5],
				["box", "Frame", -24.0, 146.0, 0.0, 7.0, 13.7, 20.0],
				["box", "Frame", 24.0, 146.0, 0.0, 7.0, 13.7, 20.0],
				["box", "Frame", 0.0, 155.2, 0.0, 55.0, 4.5, 20.0],
			]}),
		# way:400594464 Brickell House: 0 parts, OSM top 161.3 m
		MiamiTowerSpecs.row("brickell_house", "Brickell House", 25.760320, -80.190344, 161.3, -31.5, 44.6, "Brickell House", 1, ["brickell house", "1300 brickell bay drive"], {
			"finish": "balcony_white", "bay": 3.0, "floor": 3.4, "trim": "#dedfda", "walls": {"Glass": ["lowe_blue", 3.0, 3.4]}, "ops": [
				["poly", 0.0, 32.0, [[23.3, 9.3], [-23.0, 9.5], [-37.0, -4.2], [-25.9, -14.3], [26.2, -14.3], [36.5, -4.8]]],
				["poly", 32.0, 153.0, [[21.0, 8.2], [-21.0, 8.2], [-33.0, -3.8], [-23.5, -12.8], [23.5, -12.8], [33.0, -4.2]]],
				["use", "Glass"],
				["poly", 153.0, 161.3, [[16.0, 6.2], [-16.0, 6.2], [-25.0, -3.0], [-18.0, -9.8], [18.0, -9.8], [25.0, -3.0]]],
			]}),
		# way:283161497 1060 Brickell Avenue: 0 parts, OSM top 160.7 m
		MiamiTowerSpecs.row("1060_brickell", "1060 Brickell Avenue", 25.763151, -80.191912, 160.7, -78.2, 29.1, "1060 Brickell", 1, ["1060 brickell", "1060 brickell avenue"], {
			"finish": "balcony_white", "bay": 3.0, "floor": 3.4, "trim": "#e2e2dc", "walls": {"Glass": ["green_glass", 3.0, 3.4]}, "ops": [
				["tier", 0.0, 30.0, 35.0, 28.5],
				["tier", 30.0, 153.0, 32.5, 26.0],
				["use", "Glass"],
				["poly", 153.0, 160.7, [[-12.5, -10.0], [12.5, -10.0], [12.5, 10.0], [-12.5, 10.0]]],
			]}),
		# way:300486578 600 Brickell World Plaza: 0 parts, OSM top 160.0 m
		MiamiTowerSpecs.row("600_brickell_world_plaza", "600 Brickell World Plaza", 25.767502, -80.191012, 160.0, 12.9, 40.1, "Brickell World Plaza", 1, ["600 brickell", "brickell world plaza"], {
			"finish": "silver_reflective", "bay": 3.0, "floor": 3.9, "trim": "#c2c7cc", "walls": {"Stone": ["white_granite", 3.2, 4.0]}, "ops": [
				["use", "Stone"],
				["tier", 0.0, 38.0, 60.0, 36.0],
				["use", "Facade"],
				["notch", 38.0, 146.0, 56.0, 33.0, 5.0],
				["shape", "rect", 146.0, 160.0, 18.0, 31.0, 0.0, 18.0, 31.0, -18.0, 0.0],
				["shape", "rect", 146.0, 160.0, 18.0, 31.0, 0.0, 18.0, 31.0, 18.0, 0.0],
				["box", "Trim", 0.0, 156.5, 0.0, 54.0, 3.5, 8.0],
			]}),
		# way:301823926 1450 Brickell: 2 parts, OSM top 154.6 m
		MiamiTowerSpecs.row("1450_brickell", "1450 Brickell", 25.758576, -80.193119, 154.6, -76.4, 44.4, "1450 Brickell", 1, ["1450 brickell", "1450 brickell avenue"], {
			"finish": "lowe_blue", "bay": 3.0, "floor": 3.8, "trim": "#c9c4b4", "walls": {"GoldWall": ["gold_reflective", 3.0, 3.8]}, "ops": [
				["poly", 0.0, 38.0, [[38.8, -23.7], [38.6, 14.2], [-27.5, 15.2], [-19.9, -4.8], [-17.5, -23.7]]],
				["poly", 38.0, 136.0, [[36.0, -21.5], [36.0, 13.0], [-4.0, 13.5], [-17.5, -6.5], [-16.0, -21.5]]],
				["use", "GoldWall"],
				["poly", 38.0, 148.0, [[-17.5, -6.5], [-4.0, 13.5], [-25.5, 14.0], [-20.0, -4.0]]],
				["use", "Facade"],
				["poly", 136.0, 154.6, [[4.0, -16.0], [32.0, -16.0], [32.0, 10.5], [0.0, 10.5]]],
			]}),
		# way:300510112 Brickell Arch (1395 Brickell): 0 parts, OSM top 154.0 m
		MiamiTowerSpecs.row("espirito_santo_brickell_arch", "Brickell Arch (1395 Brickell)", 25.760677, -80.191714, 154.0, -78.4, 42.2, "Brickell Arch", 2, ["brickell arch", "espirito santo plaza", "1395 brickell avenue"], {
			"finish": "silver_reflective", "bay": 3.0, "floor": 4.0, "trim": "#d8d4ca", "walls": {"Concave": ["lowe_blue", 3.0, 4.0]}, "mats": {"Arch": ["limestone", "#DFD9CC"]}, "ops": [
				["poly", 0.0, 28.0, [[32.1, -16.3], [32.3, -0.9], [21.0, 21.6], [-21.5, 21.6], [-29.5, 1.6], [-28.9, -13.7], [0.8, -11.7]]],
				["use", "Concave"],
				["poly", 28.0, 150.0, [[24.0, -8.5], [24.0, 19.5], [-24.0, 19.5], [-24.0, -8.5], [-12.0, -4.5], [0.0, -3.0], [12.0, -4.5]]],
				["box", "Arch", -23.5, 0.0, -10.5, 7.5, 154.0, 7.0],
				["box", "Arch", 23.5, 0.0, -10.5, 7.5, 154.0, 7.0],
				["box", "Arch", -17.5, 96.0, -9.8, 6.5, 58.0, 6.0],
				["box", "Arch", 17.5, 96.0, -9.8, 6.5, 58.0, 6.0],
				["box", "Arch", -11.5, 122.0, -9.2, 6.5, 32.0, 5.5],
				["box", "Arch", 11.5, 122.0, -9.2, 6.5, 32.0, 5.5],
				["box", "Arch", 0.0, 138.0, -8.8, 18.0, 16.0, 5.5],
				["use", "Facade"],
				["poly", 150.0, 154.0, [[19.5, -5.0], [19.5, 17.0], [-19.5, 17.0], [-19.5, -5.0]]],
			]}),
		# way:300193839 701 Brickell Avenue: 0 parts, OSM top 150.0 m
		MiamiTowerSpecs.row("701_brickell", "701 Brickell Avenue", 25.767088, -80.189719, 150.0, 12.7, 44.4, "701 Brickell Avenue", 1, ["701 brickell", "701 brickell avenue"], {
			"finish": "silver_reflective", "bay": 3.0, "floor": 4.2, "trim": "#cfd4d8", "walls": {"Base": ["white_granite", 3.2, 4.2]}, "ops": [
				["use", "Base"],
				["tier", 0.0, 24.0, 64.0, 34.0],
				["use", "Facade"],
				["shape", "chamfer", 24.0, 128.0, 48.0, 32.0, 6.5],
				["shape", "chamfer", 128.0, 142.0, 39.0, 26.0, 6.0],
				["shape", "chamfer", 142.0, 150.0, 30.0, 20.0, 5.0],
			]}),
		# way:117631366 Asia on Brickell Key: 7 parts, OSM top 147.0 m
		MiamiTowerSpecs.row("asia_brickell_key", "Asia on Brickell Key", 25.769191, -80.185772, 147.0, 88.1, 40.1, "Asia (Miami)", 2, ["asia brickell key", "900 brickell key boulevard"], {
			"finish": "balcony_aqua", "bay": 3.0, "floor": 3.8, "trim": "#dce6e6", "walls": {"Glass": ["green_glass", 3.0, 3.8]}, "ops": [
				["tier", 0.0, 22.0, 50.0, 38.0],
				["poly", 22.0, 126.0, [[-26.0, -18.5], [-4.0, -18.5], [8.0, -8.0], [23.0, -7.5], [23.0, 8.5], [8.0, 9.0], [-4.0, 19.5], [-26.0, 19.5]]],
				["poly", 126.0, 138.0, [[-24.0, -14.0], [-2.0, -14.0], [10.0, -6.5], [18.0, -6.5], [18.0, 7.0], [10.0, 7.0], [-2.0, 14.5], [-24.0, 14.5]]],
				["use", "Glass"],
				["shape", "round", 138.0, 147.0, 32.0, 18.0, 5.0, 28.0, 15.0, -6.0, 0.5],
			]}),
		# way:117635432 Three Tequesta Point: 0 parts, OSM top 146.0 m
		MiamiTowerSpecs.row("three_tequesta_point", "Three Tequesta Point", 25.769383, -80.183711, 146.0, 24.8, 36.2, "Three Tequesta Point", 2, ["three tequesta point", "848 brickell key drive"], {
			"finish": "balcony_white", "bay": 3.0, "floor": 3.1, "trim": "#e4e3dc", "walls": {"Crown": ["green_glass", 3.0, 3.2]}, "ops": [
				["tier", 0.0, 20.0, 48.0, 32.0],
				["shape", "round", 20.0, 132.0, 44.0, 27.0, 7.0],
				["use", "Crown"],
				["shape", "round", 132.0, 141.0, 34.0, 21.0, 6.0],
				["shape", "ellipse", 141.0, 146.0, 22.0, 14.0, 16.0],
			]}),
		# way:231873520 Brickell on the River North: 0 parts, OSM top 147.0 m
		MiamiTowerSpecs.row("brickell_on_the_river_north", "Brickell on the River North", 25.769600, -80.191948, 147.0, 88.2, 35.4, "Brickell on the River", 1, ["brickell on the river north", "31 southeast 5th street"], {
			"finish": "balcony_white", "bay": 3.0, "floor": 3.3, "trim": "#e5e3da", "walls": {"Glass": ["lowe_blue", 3.0, 3.4]}, "ops": [
				["poly", 0.0, 24.0, [[-32.6, 11.2], [-32.8, -8.9], [21.9, -8.9], [21.5, 12.7]]],
				["tier", 24.0, 134.0, 48.0, 19.5, -5.0, 1.5],
				["use", "Glass"],
				["shape", "round", 134.0, 147.0, 34.0, 15.5, 4.5, 28.0, 13.5, -5.0, 1.5],
			]}),
		# way:429421646 Ivy at Riverfront: 3 parts, OSM top 144.0 m
		MiamiTowerSpecs.row("ivy_at_riverfront", "Ivy at Riverfront", 25.770414, -80.195204, 144.0, -1.2, 61.0, "Ivy at Riverfront", 1, ["ivy at riverfront", "90 southwest 3rd street"], {
			"finish": "balcony_aqua", "bay": 3.0, "floor": 3.2, "trim": "#d6e0df", "walls": {"Glass": ["lowe_blue", 3.0, 3.2]}, "ops": [
				["tier", 0.0, 28.0, 68.0, 62.0],
				["shape", "round", 28.0, 136.0, 54.0, 25.0, 6.0, 54.0, 25.0, 2.0, -8.0],
				["use", "Glass"],
				["shape", "round", 136.0, 144.0, 42.0, 19.0, 5.0, 38.0, 17.0, 2.0, -8.0],
			]}),
		# way:296968437 W Miami (Icon Tower 3): 0 parts, OSM top 142.0 m
		MiamiTowerSpecs.row("w_miami_icon", "W Miami (Icon Tower 3)", 25.768692, -80.189593, 142.0, 88.2, 36.1, "W Miami", 1, ["w miami", "485 brickell avenue"], {
			"finish": "silver_reflective", "bay": 3.0, "floor": 3.0, "trim": "#dadcd9", "walls": {"Balcony": ["balcony_white", 3.0, 3.0]}, "ops": [
				["poly", 0.0, 32.0, [[-25.1, 17.4], [-29.8, -17.0], [14.6, -17.0], [19.5, 17.4]]],
				["use", "Balcony"],
				["poly", 32.0, 135.0, [[-23.0, 15.5], [-27.0, -15.0], [13.0, -15.0], [17.5, 15.5]]],
				["use", "Facade"],
				["poly", 135.0, 142.0, [[-18.0, 12.0], [-21.0, -11.5], [9.5, -11.5], [13.0, 12.0]]],
			]}),
		# way:300211767 Plaza on Brickell Tower II: 0 parts, OSM top 143.0 m
		MiamiTowerSpecs.row("plaza_on_brickell_ii", "Plaza on Brickell Tower II", 25.764633, -80.190724, 143.0, -76.2, 40.4, "Plaza on Brickell", 1, ["plaza on brickell tower ii", "950 brickell bay drive"], {
			"finish": "balcony_white", "bay": 3.0, "floor": 3.1, "trim": "#e4e4df", "walls": {"Glass": ["lowe_blue", 3.0, 3.2]}, "ops": [
				["tier", 0.0, 28.0, 60.0, 23.5],
				["shape", "round", 28.0, 135.0, 56.0, 21.5, 5.5],
				["use", "Glass"],
				["shape", "round", 135.0, 143.0, 42.0, 17.0, 4.5],
			]}),
		# site 25.767600,-80.193100 Brickell City Centre Reach & Rise: 2 parts, CTBUH height 152.0 m
		MiamiTowerSpecs.row("bcc_reach_rise", "Brickell City Centre Reach & Rise", 25.767600, -80.193100, 152.0, 88.1, 42.0, "Brickell City Centre", 2, ["brickell city centre reach", "brickell city centre rise"], {
			"finish": "balcony_white", "bay": 3.0, "floor": 3.4, "trim": "#e3e6e8", "walls": {"Glass": ["lowe_blue", 3.0, 3.4]}, "ops": [
				["use", "Glass"],
				["tier", 0.0, 26.0, 68.0, 38.0],
				["use", "Facade"],
				["shape", "round", 26.0, 144.0, 28.0, 32.0, 5.0, 28.0, 32.0, -18.0, 0.0],
				["shape", "round", 26.0, 144.0, 28.0, 32.0, 5.0, 28.0, 32.0, 18.0, 0.0],
				["use", "Glass"],
				["shape", "ellipse", 144.0, 152.0, 22.0, 26.0, 18.0, 20.0, 24.0, -18.0, 0.0],
				["shape", "ellipse", 144.0, 152.0, 22.0, 26.0, 18.0, 20.0, 24.0, 18.0, 0.0],
			]}),
		# way:474905113 Una Residences: 0 parts, CTBUH height 176.5 m
		MiamiTowerSpecs.row("una_residences_brickell", "Una Residences", 25.749315, -80.201236, 176.5, 53.8, 32.7, "Una Residences", 1, ["una residences", "175 southeast 25th road"], {
			"finish": "clear_fin", "bay": 3.0, "floor": 3.6, "trim": "#c9b396", "walls": {"Deck": ["balcony_aqua", 3.0, 3.6]}, "ops": [
				["tier", 0.0, 16.0, 46.0, 22.5, 9.0, 0.0],
				["use", "Deck"],
				["poly", 16.0, 118.0, [[-12.5, -5.4], [-0.7, -11.2], [18.7, -11.2], [30.5, -4.4], [28.8, 5.4], [17.6, 10.9], [0.4, 10.9], [-10.8, 4.4]], 0.96],
				["use", "Facade"],
				["poly", 118.0, 169.0, [[-11.6, -5.1], [-0.3, -10.8], [18.3, -10.8], [29.6, -4.2], [28.0, 5.1], [17.2, 10.5], [0.8, 10.5], [-10.0, 4.2]], 0.9],
				["shape", "round", 169.0, 176.5, 31.0, 14.5, 5.0, 27.0, 12.5, 9.0, 0.0],
			]}),
		# way:300221113 500 Brickell East & West: 2 twin towers, OSM top 130.0 m
		MiamiTowerSpecs.row("500_brickell_towers", "500 Brickell East & West", 25.768386, -80.191028, 130.0, 13.5, 45.0, "500 Brickell", 2, ["500 brickell", "500 brickell avenue"], {
			"finish": "balcony_white", "bay": 3.0, "floor": 3.0, "trim": "#f0efe9", "walls": {"Glass": ["lowe_blue", 3.0, 3.2]}, "mats": {"Portal": ["render", "#F4F3EE"]}, "ops": [
				["use", "Glass"],
				["tier", 0.0, 32.0, 68.0, 32.0],
				["use", "Facade"],
				["shape", "ellipse", 32.0, 124.0, 25.0, 24.0, 20.0, 25.0, 24.0, -18.0, 0.0],
				["shape", "ellipse", 32.0, 124.0, 25.0, 24.0, 20.0, 25.0, 24.0, 18.0, 0.0],
				["box", "Portal", -18.0, 124.0, 0.0, 18.0, 6.0, 22.0],
				["box", "Portal", 18.0, 124.0, 0.0, 18.0, 6.0, 22.0],
				["box", "Portal", 0.0, 127.2, 0.0, 56.0, 2.8, 24.0],
				["box", "Portal", 0.0, 124.0, -9.5, 22.0, 3.2, 3.5],
				["box", "Portal", 0.0, 124.0, 9.5, 22.0, 3.2, 3.5],
			]}),
		# way:117631372 Two Tequesta Point: 0 parts, OSM top 128.3 m
		MiamiTowerSpecs.row("two_tequesta_point", "Two Tequesta Point", 25.768685, -80.183174, 128.3, -46.2, 41.1, "Two Tequesta Point", 1, ["two tequesta point", "808 brickell key drive"], {
			"finish": "balcony_white", "bay": 3.0, "floor": 3.1, "trim": "#e5e3db", "walls": {"Crown": ["green_glass", 3.0, 3.2]}, "ops": [
				["tier", 0.0, 20.0, 60.0, 27.5],
				["shape", "hex", 20.0, 118.0, 56.0, 24.5, 9.0],
				["use", "Crown"],
				["shape", "hex", 118.0, 128.3, 42.0, 19.0, 7.0, 36.0, 16.0],
			]}),
		# way:300753073 Axis at Brickell Village: 0 parts, OSM top 127.0 m
		MiamiTowerSpecs.row("axis_brickell", "Axis at Brickell Village", 25.763230, -80.194434, 127.0, -1.2, 38.0, "Axis at Brickell Village", 1, ["axis at brickell", "1111 southwest 1st avenue"], {
			"finish": "balcony_white", "bay": 3.0, "floor": 3.1, "trim": "#e2e2dd", "walls": {"Glass": ["silver_reflective", 3.0, 3.1]}, "ops": [
				["tier", 0.0, 26.0, 64.0, 26.5],
				["tier", 26.0, 120.0, 60.0, 24.5],
				["use", "Glass"],
				["poly", 120.0, 127.0, [[-24.0, -10.0], [24.0, -10.0], [24.0, 10.0], [-24.0, 10.0]]],
			]}),
		# way:995059976 Wind: 2 parts, OSM top 125.7 m
		MiamiTowerSpecs.row("wind_by_neo", "Wind", 25.770612, -80.194344, 125.7, 88.2, 47.0, "Wind (Miami)", 1, ["wind by neo", "350 west flagler street"], {
			"finish": "balcony_aqua", "bay": 3.0, "floor": 3.1, "trim": "#dbe3e4", "walls": {"Glass": ["lowe_blue", 3.0, 3.1]}, "ops": [
				["tier", 0.0, 28.0, 50.0, 68.0, 4.0, -14.0],
				["poly", 28.0, 118.0, [[-18.2, 13.1], [-10.1, -11.0], [-4.0, -33.6], [5.4, -56.5], [18.7, -55.1], [19.9, -39.4], [13.3, -19.6], [7.5, 3.6], [-5.5, 22.1]]],
				["use", "Glass"],
				["poly", 118.0, 125.7, [[-14.0, 10.0], [-4.0, -28.0], [6.0, -48.0], [15.5, -46.5], [11.0, -16.0], [4.0, 6.0], [-4.5, 17.0]]],
			]}),
		# way:301821630 Bristol Tower: 0 parts, OSM top 124.3 m
		MiamiTowerSpecs.row("bristol_tower_brickell", "Bristol Tower", 25.752098, -80.199373, 124.3, -85.4, 38.5, "Bristol Tower", 1, ["bristol tower", "2127 brickell avenue"], {
			"finish": "balcony_white", "bay": 2.8, "floor": 3.1, "trim": "#eceae3", "walls": {"Glass": ["green_glass", 2.8, 3.2]}, "ops": [
				["shape", "ellipse", 0.0, 18.0, 44.0, 42.0, 24.0],
				["shape", "ellipse", 18.0, 116.0, 38.0, 36.0, 24.0],
				["use", "Glass"],
				["shape", "ellipse", 116.0, 124.3, 28.0, 26.0, 20.0, 22.0, 20.0],
			]}),
		# way:117631352 Carbonell Condominium: 4 parts, OSM top 124.0 m
		MiamiTowerSpecs.row("carbonell_brickell_key", "Carbonell Condominium", 25.769250, -80.186947, 124.0, -17.6, 49.1, "Carbonell Condominium", 1, ["carbonell brickell key", "901 brickell key boulevard"], {
			"finish": "balcony_aqua", "bay": 3.0, "floor": 3.1, "trim": "#d6e4e0", "walls": {"Crown": ["green_glass", 3.0, 3.2]}, "ops": [
				["poly", 0.0, 110.0, [[-36.6, -9.2], [-24.9, -12.8], [8.0, -12.9], [22.3, -8.5], [36.2, 4.7], [32.8, 18.9], [21.2, 25.3], [4.2, 11.4], [-23.4, 9.3], [-35.5, 2.2]]],
				["poly", 110.0, 117.0, [[-21.8, -12.5], [8.0, -12.5], [22.3, -8.0], [34.0, 3.5], [28.0, 16.0], [4.2, 10.5], [-21.0, 8.5]]],
				["use", "Crown"],
				["shape", "round", 117.0, 124.0, 40.0, 20.0, 6.0, 34.0, 17.0, 8.0, 0.5],
			]}),
		# way:301775188 The Palace: 8 parts, OSM top 121.6 m
		MiamiTowerSpecs.row("the_palace_brickell", "The Palace", 25.756551, -80.192333, 121.6, -25.0, 62.9, "The Palace (Miami)", 2, ["the palace brickell", "1541 brickell avenue"], {
			"finish": "white_panel", "bay": 3.0, "floor": 2.9, "trim": "#efeee9", "walls": {"Glass": ["silver_reflective", 3.0, 2.9]}, "mats": {"Red": ["render", "#B8292F"]}, "ops": [
				["use", "Glass"],
				["tier", 0.0, 116.0, 74.0, 17.6, -16.0, -26.3],
				["use", "Facade"],
				["poly", 116.0, 121.6, [[-51.0, -34.5], [19.0, -34.5], [19.0, -18.1], [-51.0, -18.1]]],
				["box", "Red", 0.4, 0.0, -26.3, 11.5, 104.0, 22.5],
				["box", "Red", 0.4, 0.0, -6.0, 11.2, 86.0, 20.0],
				["box", "Red", 0.4, 0.0, 9.0, 11.0, 66.0, 14.0],
				["box", "Red", 0.4, 0.0, 20.0, 11.0, 48.0, 10.0],
				["box", "Red", 0.4, 0.0, 29.0, 11.0, 34.0, 10.0],
				["box", "Red", 0.4, 0.0, 36.5, 11.0, 24.0, 7.0],
			]}),
		# site 25.759200,-80.191800 The Residences at 1428 Brickell: 0 parts, late-2026 standing height 115.0 m
		MiamiTowerSpecs.row("1428_brickell_partial", "The Residences at 1428 Brickell", 25.759200, -80.191800, 115.0, -76.6, 28.0, "The Residences at 1428 Brickell", 1, ["1428 brickell"], {
			"finish": "lowe_blue", "bay": 3.0, "floor": 3.6, "trim": "#d5d8da", "walls": {"Core": ["warm_concrete", 3.5, 3.6]}, "ops": [
				["tier", 0.0, 22.0, 42.0, 30.0],
				["shape", "ellipse", 22.0, 104.0, 36.0, 25.0, 20.0],
				["use", "Core"],
				["poly", 104.0, 115.0, [[-9.0, -7.0], [9.0, -7.0], [9.0, 7.0], [-9.0, 7.0]]],
			]}),
		# way:301776326 Villa Regina: 0 parts, OSM top 98.7 m
		MiamiTowerSpecs.row("villa_regina_brickell", "Villa Regina", 25.756212, -80.193510, 98.7, -80.3, 52.2, "Villa Regina (Miami)", 2, ["villa regina", "1581 brickell avenue"], {
			"finish": "balcony_white", "bay": 3.0, "floor": 3.2, "trim": "#f2f1ec", "mats": {"Cyan": ["paint", "#00A6E2", 0.38, 0.18], "Yellow": ["paint", "#F4C41C", 0.38, 0.18], "Magenta": ["paint", "#D81B60", 0.38, 0.18], "Blue": ["paint", "#1E56B0", 0.38, 0.18]}, "ops": [
				["tier", 0.0, 12.0, 34.0, 68.0, 0.0, -2.0],
				["poly", 12.0, 95.0, [[16.0, -34.0], [18.0, -20.0], [8.0, -6.0], [6.0, 14.0], [4.5, 34.0], [-16.5, 34.0], [-16.5, 8.0], [-13.5, -14.0], [-6.0, -34.0]]],
				["box", "Cyan", 0.0, 18.0, 0.0, 35.2, 2.2, 69.0],
				["box", "Yellow", 0.0, 29.0, 0.0, 35.2, 2.2, 69.0],
				["box", "Magenta", 0.0, 40.0, 0.0, 35.2, 2.2, 69.0],
				["box", "Blue", 0.0, 51.0, 0.0, 35.2, 2.2, 69.0],
				["box", "Cyan", 0.0, 62.0, 0.0, 35.2, 2.2, 69.0],
				["box", "Yellow", 0.0, 73.0, 0.0, 35.2, 2.2, 69.0],
				["box", "Magenta", 0.0, 84.0, 0.0, 35.2, 2.2, 69.0],
				["poly", 95.0, 98.7, [[-11.0, -22.0], [10.0, -22.0], [4.0, 24.0], [-11.0, 24.0]]],
			]}),
		# way:255188209 The Imperial at Brickell: 0 parts, CTBUH height 96.0 m
		MiamiTowerSpecs.row("the_imperial_brickell", "The Imperial at Brickell", 25.755944, -80.194186, 96.0, 51.4, 40.7, "The Imperial at Brickell", 1, ["the imperial at brickell", "1627 brickell avenue"], {
			"finish": "lowe_blue", "bay": 2.8, "floor": 3.1, "trim": "#dce4ea", "walls": {"Mirror": ["silver_reflective", 2.8, 3.1]}, "mats": {"Red": ["render", "#B8282E"]}, "ops": [
				["tier", 8.0, 88.0, 82.0, 15.6, -6.0, 4.5],
				["use", "Mirror"],
				["shape", "ellipse", 0.0, 89.0, 12.0, 10.0, 16.0, 12.0, 10.0, 8.8, -2.5],
				["box", "Red", 0.0, 0.0, 6.2, 102.0, 96.0, 5.2],
			]}),
	]
