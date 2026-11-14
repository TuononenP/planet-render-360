extends SceneTree

## Headless: godot --headless --script tests/train_test.gd
## Station trains (TrainSpecs, TramModel, StationTrains): every car
## builds grounded and outward-facing near and far within budget; the
## city, the country and the track's electrification pick the train; a
## fan of buffer stops is a terminus and takes trains on its platform
## tracks only (noses 6-14 m from the buffers, none overlapping, none
## past the switches), a lone siding, a tunnel and the data's edge take
## none; a roofed buffer end pushes the train out from under the roof; a
## viaduct's train stands on its deck; a mapped platform takes a train
## beside it; placement is deterministic and gated by quality.

const LIVERY := {"emu": "helsinki_commuter", "emu_uk": "london_grey", "intercity": "finland_long"}

func _init() -> void:
	_run()

func _data(lat: float, lon: float, country: String) -> LocationData:
	var data := LocationData.new()
	RenderSettings.apply_preset(data, RenderSettings.Preset.ULTRA)
	var n := data.grid_size
	data.heights.resize(n * n)
	data.heights.fill(3.0)
	data.water_level = -3.0
	data.latitude = lat
	data.longitude = lon
	data.country = country
	data.buildings = []
	return data

func _rail(tags: Dictionary, pts: Array) -> Dictionary:
	var all := {"railway": "rail", "electrified": "contact_line"}
	all.merge(tags, true)
	return OsmTags._rail_entry(all, PackedVector2Array(pts))

func _run() -> void:
	var failures: Array[String] = ["sentinel: the run did not finish (script error?)"]
	_models(failures)
	_selection(failures)
	_terminus(failures)
	_halls(failures)
	_edges(failures)
	_viaduct(failures)
	_platforms(failures)
	_gate(failures)
	failures.remove_at(0)
	if failures.is_empty():
		print("TRAIN OK: cars build grounded and outward-facing near and far, cities pick their trains, a fan of buffers takes trains on its platform tracks only, edges, sidings and tunnels take none, platforms take theirs, placement is deterministic and gated")
		quit(0)
	else:
		for failure in failures:
			printerr("TRAIN FAIL: ", failure)
		quit(1)

func _models(failures: Array[String]) -> void:
	for kind: String in TrainSpecs.KINDS:
		var livery: String = LIVERY[kind]
		var liv := TrainSpecs.livery(livery)
		var width := TrainSpecs.width_m(kind)
		if width < 2.8 or width > 3.0:
			failures.append("%s should be 2.8-3.0 m wide: %s" % [kind, width])
		for cars: int in [2, 3, 4]:
			if TrainSpecs.train(kind, cars, false).size() != cars:
				failures.append("%s should run %d cars" % [kind, cars])
		if TrainSpecs.train(kind, 9, false).size() != TrainSpecs.MAX_CARS or TrainSpecs.train(kind, 1, false).size() != TrainSpecs.MIN_CARS:
			failures.append("%s runs two to four cars" % kind)
		for panto: bool in [false, true]:
			var train := TrainSpecs.train(kind, 4, panto)
			var length := TrainSpecs.length_m(kind, 4)
			var low := [INF, INF]
			var wired := 0
			var x := length * 0.5
			for i in train.size():
				var sec: Dictionary = train[i]
				var id := str(sec["id"])
				var spec := TrainSpecs.section(kind, id)
				var prof: Array = spec["prof"]
				var top := float(prof[prof.size() - 1][0])
				if float(sec["len"]) < 19.0 or float(sec["len"]) > 25.5 or top < 3.8 or top > 4.2:
					failures.append("%s %s should be 19-25 m long and 3.8-4.2 m over the roof: %s, %s" % [kind, id, sec["len"], top])
				if (spec["bogies"] as Array).size() != 2 or (spec["doors"] as Array).size() != 2 or (spec["under"] as Array).is_empty():
					failures.append("%s %s needs two bogies, two doorways a side and underfloor cases" % [kind, id])
				if spec.has("panto"):
					wired += 1
				if absf(float(sec["at"]) - (x - float(sec["len"]) * 0.5)) > 0.001:
					failures.append("%s car %d is misplaced along the train" % [kind, i])
				x -= float(sec["len"]) + float(TrainSpecs.KIND[kind]["gap"])
				var sup: Vector2 = sec["sup"]
				if sup.x >= 0.0 or sup.y <= 0.0 or sup.y - sup.x < float(sec["len"]) * 0.55:
					failures.append("%s car %d should stand on its own two bogies: %s" % [kind, i, sup])
				var near := TramModel.mesh(kind, id, livery, bool(sec["tail"]))
				var far := TramModel.mesh(kind, id, livery, bool(sec["tail"]), true)
				if TramModel.mesh(kind, id, livery, bool(sec["tail"])) != near:
					failures.append("%s %s should share its mesh" % [kind, id])
				var counts: Array[int] = []
				for lod in 2:
					var m: ArrayMesh = [near, far][lod]
					var box := m.get_aabb()
					low[lod] = minf(low[lod], box.position.y)
					var roof_top := TramModel.COLLECTOR_M + 0.1 if spec.has("panto") and lod == 0 else top + 0.5
					if box.position.y < -0.01 or box.end.y > roof_top or box.end.y < top - 0.01 \
							or box.size.x < float(sec["len"]) - 0.05 or box.size.x > float(sec["len"]) + 0.8 \
							or box.size.z < width - 0.05 or box.size.z > width + 0.3 or absf(box.get_center().z) > 0.01:
						failures.append("%s %s lod %d bounds are not its car's: %s" % [kind, id, lod, box])
					if spec.has("panto") and lod == 0 and box.end.y < TramModel.COLLECTOR_M - 0.2:
						failures.append("%s %s pantograph should reach the wire: %s" % [kind, id, box.end.y])
					var names := {}
					var tris := 0
					for si in m.get_surface_count():
						names[m.surface_get_name(si)] = m.surface_get_material(si)
						var arr := m.surface_get_arrays(si)
						var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
						var n: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
						tris += v.size() / 3
						for t in range(0, v.size(), 3):
							# Front faces as Godot winds them: clockwise about the normal.
							if (v[t + 1] - v[t]).cross(v[t + 2] - v[t]).dot(n[t] + n[t + 1] + n[t + 2]) > 0.0:
								failures.append("%s %s lod %d surface %s has a back-facing triangle" % [kind, id, lod, m.surface_get_name(si)])
								break
					counts.append(tris)
					var glass := names.get("Glass") as StandardMaterial3D
					if glass == null or not glass.has_meta(CityLights.META) or glass.roughness > 0.06:
						failures.append("%s %s lod %d needs smooth glass that lights at night" % [kind, id, lod])
					if not names.has("Roof") or not (names["Roof"] is ShaderMaterial):
						failures.append("%s %s lod %d roof should take snow" % [kind, id, lod])
					if lod == 1 and m.get_surface_count() > 3:
						failures.append("%s %s far mesh should fold to three surfaces: %s" % [kind, id, names.keys()])
					if lod == 0 and not names.has(TramModel._ckey(liv["door"])):
						failures.append("%s %s should carry painted doors" % [kind, id])
					if lod == 0 and id.begins_with("cab") and not (names.has("HeadLamp") or names.has("TailLamp")):
						failures.append("%s %s cab needs lamps" % [kind, id])
				if counts[0] > 9000 or counts[1] > 1000 or counts[1] >= counts[0]:
					failures.append("%s %s triangle budget: near %d, far %d" % [kind, id, counts[0], counts[1]])
			for lod in 2:
				if absf(low[lod]) > 0.03:
					failures.append("%s lod %d wheels should stand on the rail (y = 0): %s" % [kind, lod, low[lod]])
			if wired != (1 if panto else 0):
				failures.append("%s should carry %d pantograph, got %d" % [kind, int(panto), wired])
	if TrainSpecs.length_m("emu", 4) < 76.0 or TrainSpecs.length_m("emu", 4) > 100.0 \
			or TrainSpecs.length_m("emu", 2) > TrainSpecs.length_m("emu", 3):
		failures.append("a four-car unit is about 80 m, a shorter one shorter: %s" % TrainSpecs.length_m("emu", 4))
	if not TrainSpecs.train("emu", 2, true)[0]["id"] == "cabp" or not TrainSpecs.train("emu", 4, true)[1]["id"] == "midp":
		failures.append("the pantograph rides the second car, or a two-car unit's first")

func _selection(failures: Array[String]) -> void:
	var line := [Vector2.ZERO, Vector2(10, 0)]
	var wired := _rail({}, line)
	var third := _rail({"electrified": "rail"}, line)
	var bare := _rail({"electrified": "no"}, line)
	var tram := OsmTags._rail_entry({"railway": "tram"}, PackedVector2Array(line))
	var seen := {}
	for i in 50:
		var h := (float(i) + 0.5) / 50.0
		var hel := TrainSpecs.pick("helsinki", "FI", wired, h)
		if not ((str(hel["kind"]) == "emu" and str(hel["livery"]) == "helsinki_commuter")
				or (str(hel["kind"]) == "intercity" and str(hel["livery"]) == "finland_long")) or not bool(hel["panto"]):
			failures.append("Helsinki stands white commuter and long-distance units under the wire: %s" % hel)
		seen[str(hel["livery"])] = true
		var lon := TrainSpecs.pick("london", "GB", third, h)
		if str(lon["kind"]) != "emu_uk" or not str(lon["livery"]) in TrainSpecs.LONDON_LIVERIES or bool(lon["panto"]):
			failures.append("London stands third-rail units without a pantograph: %s" % lon)
		if bool(TrainSpecs.pick("london", "GB", wired, h)["panto"]):
			failures.append("the London liveries carry no pantograph")
		seen[str(lon["livery"])] = true
		var de := TrainSpecs.pick("", "DE", wired, h)
		if str(de["kind"]) != "emu" or str(de["livery"]) != str(TrainSpecs.pick("", "de", wired, 0.5)["livery"]) \
				or not str(de["livery"]).begins_with("rail") or not bool(de["panto"]):
			failures.append("elsewhere a country runs one generic livery: %s" % de)
		for got: Dictionary in [hel, lon, de]:
			if int(got["cars"]) < TrainSpecs.MIN_CARS or int(got["cars"]) > TrainSpecs.MAX_CARS:
				failures.append("a train has two to four cars: %s" % got)
		if bool(TrainSpecs.pick("", "DE", bare, h)["panto"]) or bool(TrainSpecs.pick("helsinki", "FI", third, h)["panto"]):
			failures.append("no pantograph without an overhead line")
	if seen.size() != 5:
		failures.append("Helsinki's two and London's three liveries should all turn up: %s" % [seen.keys()])
	if TrainSpecs.pick("", "DE", wired, 0.3) != TrainSpecs.pick("", "DE", wired, 0.3):
		failures.append("the pick is a pure function")
	if not TrainSpecs.pick("helsinki", "FI", tram, 0.5).is_empty() or not TramSpecs.pick("helsinki", "FI", wired, 0.5).is_empty():
		failures.append("trains keep to heavy rail and trams off it")
	# Berlin's S-Bahn: light rail on a third rail is a train (red and ochre,
	# no pantograph); light rail under the wire stays a tram line.
	var sbahn := OsmTags._rail_entry({"railway": "light_rail", "electrified": "rail"}, PackedVector2Array(line))
	var wired_light := OsmTags._rail_entry({"railway": "light_rail", "electrified": "contact_line"}, PackedVector2Array(line))
	var ber := TrainSpecs.pick("berlin", "DE", sbahn, 0.5)
	if str(ber.get("livery", "")) != "berlin_sbahn" or bool(ber["panto"]) or not TrainSpecs.pick("", "DE", wired_light, 0.5).is_empty():
		failures.append("Berlin's S-Bahn stands red and ochre units; wired light rail carries none: %s" % ber)
	var generic := TrainSpecs.livery(str(TrainSpecs.pick("", "DE", wired, 0.5)["livery"]))
	if generic["lower"] != TrainSpecs.WHITE or not (generic["band"] as Color) in TramSpecs.GENERIC_BANDS:
		failures.append("the generic train is white with a palette band")
	var commuter := TrainSpecs.livery("helsinki_commuter")
	var door: Color = commuter["door"]
	var band: Color = TrainSpecs.livery("finland_long")["band"]
	if (commuter["lower"] as Color).v < 0.85 or door.b < door.g * 2.0 or door.r < door.g or band.g < band.r * 2.0 or band.g < band.b * 2.0:
		failures.append("Helsinki's commuter is white with violet doors, the long-distance unit white with a green band")
	var yellow := 0
	for id: String in TrainSpecs.LONDON_LIVERIES:
		var liv := TrainSpecs.livery(id)
		if liv.has("cab") and (liv["cab"] as Color).r > 0.8 and (liv["cab"] as Color).b < 0.2:
			yellow += 1
		if not TrainSpecs.has_livery(id):
			failures.append("%s should be a livery" % id)
	if yellow < 1 or TrainSpecs.has_livery("nope") or not TrainSpecs.has_livery("rail2"):
		failures.append("a London colourway has yellow cab ends")

## A terminus: six platform tracks 5 m apart, buffers at z = 0, running
## north for 200 m and merging through switches into two running lines.
## Track 0 is mapped in two pieces; track 5's first 30 m are roofed.
func _station(data: LocationData, tags: Dictionary = {}) -> void:
	for i in 6:
		var x := 5.0 * float(i)
		if i == 0:
			data.railways.append(_rail(tags, [Vector2(x, 0), Vector2(x, -30)]))
			data.railways.append(_rail(tags, [Vector2(x, -200), Vector2(x, -30)]))
		elif i == 5:
			var roofed := tags.duplicate()
			roofed["covered"] = "yes"
			data.railways.append(_rail(roofed, [Vector2(x, 0), Vector2(x, -30)]))
			data.railways.append(_rail(tags, [Vector2(x, -30), Vector2(x, -200)]))
		else:
			data.railways.append(_rail(tags, [Vector2(x, 0), Vector2(x, -100), Vector2(x, -200)]))
	# The two running lines carry tracks 2 and 3 straight on; the others
	# join them over switches at points inside those ways.
	data.railways.append(_rail(tags, [Vector2(10, -200), Vector2(10, -240), Vector2(10, -280), Vector2(10, -700)]))
	data.railways.append(_rail(tags, [Vector2(15, -200), Vector2(15, -240), Vector2(15, -280), Vector2(15, -700)]))
	data.railways.append(_rail(tags, [Vector2(5, -200), Vector2(10, -240)]))
	data.railways.append(_rail(tags, [Vector2(0, -200), Vector2(10, -280)]))
	data.railways.append(_rail(tags, [Vector2(20, -200), Vector2(15, -240)]))
	data.railways.append(_rail(tags, [Vector2(25, -200), Vector2(15, -280)]))

func _terminus(failures: Array[String]) -> void:
	var data := _data(60.17, 24.94, "FI")
	_station(data)
	# A lone siding, a fan of three buffers inside a tunnel, and three
	# ways that run out of the data together (cut by its edge).
	data.railways.append(_rail({"service": "siding"}, [Vector2(300, 300), Vector2(300, 520)]))
	for i in 3:
		data.railways.append(_rail({"tunnel": "yes"}, [Vector2(-300.0 + 5.0 * float(i), 0), Vector2(-300.0 + 5.0 * float(i), -300)]))
		data.railways.append(_rail({}, [Vector2(600.0 + 5.0 * float(i), -700), Vector2(600.0 + 5.0 * float(i), -1195)]))
	var ground := GroundTruth.new(data)
	var m2u := WorldScale.metres_to_units()
	var termini := StationTrains.fans(data, ground, m2u)
	if termini.size() != 1 or (termini[0] as Array).size() != 6:
		failures.append("the six buffers are the one terminus: %s" % [termini])
	var trains := StationTrains.plan(data, ground, m2u)
	var again := StationTrains.plan(data, ground, m2u)
	if trains.size() < 2 or trains.size() > 6 or trains.size() != again.size():
		failures.append("about 60 %% of six platform tracks should hold a train, the same every time: %d / %d" % [trains.size(), again.size()])
	var rail_y := ground.height_at_world(0.0, -50.0) + RailBuilder.BED_LIFT_M + RailBuilder.RAIL_HEIGHT_M
	var tracks := {}
	for i in trains.size():
		var t: Dictionary = trains[i]
		if i < again.size() and (t["s"] != again[i]["s"] or t["kind"] != again[i]["kind"] or t["poses"] != again[i]["poses"]
				or t["livery"] != again[i]["livery"]):
			failures.append("train %d must stand the same on every build" % i)
		var a: Vector2 = t["a"]
		var b: Vector2 = t["b"]
		var track := roundi(a.x / 5.0)
		if str(t["at"]) != "terminus" or absf(a.x - 5.0 * float(track)) > 0.01 or absf(b.x - a.x) > 0.01 or track < 0 or track > 5:
			failures.append("train %d should stand on a platform track: %s .. %s" % [i, a, b])
		if tracks.has(track):
			failures.append("two trains on track %d" % track)
		tracks[track] = true
		var roof := 30.0 if track == 5 else 0.0
		var nose := minf(-a.y, -b.y) - roof
		if nose < StationTrains.NOSE_MIN_M - 0.01 or nose > StationTrains.NOSE_MAX_M + 0.01 or absf(nose - float(t["nose_m"])) > 0.01:
			failures.append("train %d nose should stand 6-14 m from the buffers (or the roof's edge): %.2f" % [i, nose])
		if maxf(-a.y, -b.y) > 200.0 - StationTrains.CLEAR_M or absf(a.distance_to(b) - float(t["length"])) > 0.05:
			failures.append("train %d should end short of the switches: %s .. %s" % [i, a, b])
		if not str(t["kind"]) in ["emu", "intercity"] or not bool(t["panto"]) or int(t["cars"]) < 2 \
				or (t["sections"] as Array).size() != int(t["cars"]) or (t["poses"] as Array).size() != int(t["cars"]):
			failures.append("Helsinki should stand its own wired units, a pose per car: %s" % t["kind"])
		for pose: Transform3D in t["poses"]:
			if absf(pose.origin.y - rail_y) > 0.01 or absf(pose.origin.x - 5.0 * float(track)) > 0.01:
				failures.append("train %d should stand on its rails: %s" % [i, pose.origin])
				break
		for j in range(i + 1, trains.size()):
			if StationTrains.gap(t, trains[j]) < TrainSpecs.width_m("intercity") + StationTrains.SIDE_M:
				failures.append("trains %d and %d overlap" % [i, j])
	# Too short for two cars: no train; long enough for two only: two.
	var short := _data(60.17, 24.94, "FI")
	for i in 3:
		short.railways.append(_rail({}, [Vector2(5.0 * float(i), 0), Vector2(5.0 * float(i), -70)]))
		short.railways.append(_rail({}, [Vector2(5.0 * float(i), -70), Vector2(5, -75), Vector2(5, -600)]))
		short.railways.append(_rail({}, [Vector2(100.0 + 5.0 * float(i), 0), Vector2(100.0 + 5.0 * float(i), -40)]))
		short.railways.append(_rail({}, [Vector2(100.0 + 5.0 * float(i), -40), Vector2(105, -45), Vector2(105, -600)]))
	var short_ground := GroundTruth.new(short)
	var seen_short := 0
	for seed_x in 8:
		# Shift the yard until the hash stands a train on the 70 m tracks.
		var moved := _data(60.17, 24.94, "FI")
		for r: Dictionary in short.railways:
			var pts: PackedVector2Array = (r["points"] as PackedVector2Array).duplicate()
			for k in pts.size():
				pts[k] += Vector2(0.0, 13.0 * float(seed_x))
			moved.railways.append(_rail({}, Array(pts)))
		for t: Dictionary in StationTrains.plan(moved, short_ground, m2u):
			seen_short += 1
			if (t["a"] as Vector2).x > 50.0 or int(t["cars"]) > 3 or TrainSpecs.length_m(str(t["kind"]), int(t["cars"])) > 65.0:
				failures.append("a 70 m track takes a short train and a 40 m track none: %s cars at %s" % [t["cars"], t["a"]])
	if seen_short == 0:
		failures.append("the 70 m tracks should hold a short train on some build")

func _building(kind: String, x0: float, z0: float, x1: float, z1: float) -> Dictionary:
	var ring := PackedVector2Array([Vector2(x0, z0), Vector2(x1, z0), Vector2(x1, z1), Vector2(x0, z1), Vector2(x0, z0)])
	return OsmTags._building_entry({"building": kind}, ring, Rect2(x0, z0, x1 - x0, z1 - z0))

## A station hall and a platform roof drawn over the buffers push the
## trains out from under them; a block across the tracks further out
## ends the platform track.
func _halls(failures: Array[String]) -> void:
	var data := _data(60.17, 24.94, "FI")
	_station(data)
	data.buildings = [_building("train_station", -10, -50, 35, 20), _building("roof", -10, -90, 35, -50),
		_building("office", -10, -190, 35, -170)]
	var ground := GroundTruth.new(data)
	var trains := StationTrains.plan(data, ground, WorldScale.metres_to_units())
	if trains.size() < 2:
		failures.append("a terminus behind its hall should still hold trains: %d" % trains.size())
	for t: Dictionary in trains:
		var a: Vector2 = t["a"]
		var b: Vector2 = t["b"]
		var nose := minf(-a.y, -b.y) - 90.0
		if nose < StationTrains.NOSE_MIN_M - 0.01 or nose > StationTrains.NOSE_MAX_M + StationTrains.SPAN_STEP_M + 0.01:
			failures.append("a train's nose should stand 6-14 m out from the hall and its platform roof: %.2f" % nose)
		if maxf(-a.y, -b.y) > 170.0 - StationTrains.CLEAR_M + StationTrains.SPAN_STEP_M + 0.01:
			failures.append("a train should end short of the block across its track: %s" % b)

## Dead ends the data's edge made are no terminus, whatever the radius.
func _edges(failures: Array[String]) -> void:
	var data := _data(51.5, -0.11, "GB")
	_station(data)
	# A fallback fetch that reached 500 m: three tracks run out at 600 m.
	for i in 3:
		data.railways.append(_rail({}, [Vector2(-200.0 + 5.0 * float(i), -480), Vector2(-200.0 + 5.0 * float(i), -640)]))
	var ground := GroundTruth.new(data)
	var m2u := WorldScale.metres_to_units()
	var termini := StationTrains.fans(data, ground, m2u)
	if termini.size() != 1 or (termini[0] as Array).size() != 6:
		failures.append("tracks leaving a small fetch are not a terminus: %d fans" % termini.size())
	for t: Dictionary in StationTrains.plan(data, ground, m2u):
		if (t["a"] as Vector2).x < -10.0:
			failures.append("no train stands where the data ends")
	# Two buffers are no terminus, unless a mapped station stands by them.
	var two := _data(51.5, -0.11, "GB")
	two.railways.append(_rail({}, [Vector2(0, 0), Vector2(0, -300), Vector2(2.5, -340)]))
	two.railways.append(_rail({}, [Vector2(5, 0), Vector2(5, -300), Vector2(2.5, -340)]))
	two.railways.append(_rail({}, [Vector2(2.5, -340), Vector2(2.5, -800)]))
	if not StationTrains.fans(two, ground, m2u).is_empty():
		failures.append("two buffers alone are a siding")
	two.rail_stations = [{"x": 20.0, "z": 30.0, "name": "Halt"}]
	if StationTrains.fans(two, ground, m2u).size() != 1:
		failures.append("two buffers at a mapped station are a terminus")

## London: third rail on a viaduct. The trains stand on the deck
## RailBuilder lays, without a pantograph.
func _viaduct(failures: Array[String]) -> void:
	var data := _data(51.503, -0.113, "GB")
	_station(data, {"electrified": "rail", "bridge": "viaduct", "layer": "1"})
	var ground := GroundTruth.new(data)
	var m2u := WorldScale.metres_to_units()
	var trains := StationTrains.plan(data, ground, m2u)
	if trains.size() < 2:
		failures.append("a terminus on a viaduct should hold trains: %d" % trains.size())
	var surf := RoadBuilder._Surface.new(data, ground)
	for t: Dictionary in trains:
		if str(t["kind"]) != "emu_uk" or bool(t["panto"]) or not str(t["livery"]) in TrainSpecs.LONDON_LIVERIES:
			failures.append("London stands its third-rail units: %s %s" % [t["kind"], t["livery"]])
		var a: Vector2 = t["a"]
		# Tracks 0 and 5 are mapped in two pieces; the others in one.
		if roundi(a.x / 5.0) in [0, 5]:
			continue
		# The deck of the way under the train, as RailBuilder lays it: level
		# with the tracks beside it.
		var way := PackedVector2Array([Vector2(a.x, 0), Vector2(a.x, -100), Vector2(a.x, -200)])
		var dense := RoadBuilder._resample(way, surf.step * 0.34)
		var deck := RailDecks.of(data, surf, m2u).level(dense,
			RoadBuilder.deck_profile(dense, surf, m2u, 1.435 * 0.5 + 0.95, 0, false))
		for pose: Transform3D in t["poses"]:
			var best := 0
			for k in dense.size():
				if absf(dense[k].y - pose.origin.z) < absf(dense[best].y - pose.origin.z):
					best = k
			if absf(pose.origin.y - (deck[best] + RailBuilder.RAIL_HEIGHT_M)) > 0.03:
				failures.append("a viaduct's train should stand on its deck: %s vs %s" % [pose.origin.y, deck[best] + RailBuilder.RAIL_HEIGHT_M])
				break

func _platforms(failures: Array[String]) -> void:
	var data := _data(48.85, 2.35, "FR")
	# Six through tracks 40 m apart (they leave the data at both ends), a 200 m platform outline 2 m beside
	# each; one mapped as a line down its middle; one far from any track.
	for i in 6:
		var z := 40.0 * float(i) - 100.0
		data.railways.append(_rail({}, [Vector2(-1300, z), Vector2(0, z), Vector2(1300, z)]))
		if i == 5:
			data.rail_platforms.append({"points": PackedVector2Array([Vector2(-100, z + 5.0), Vector2(100, z + 5.0)])})
		else:
			data.rail_platforms.append({"points": PackedVector2Array([Vector2(-100, z + 2.0), Vector2(100, z + 2.0),
				Vector2(100, z + 8.0), Vector2(-100, z + 8.0), Vector2(-100, z + 2.0)])})
	data.rail_platforms.append({"points": PackedVector2Array([Vector2(-100, 600), Vector2(100, 600)])})
	# A 50 m platform takes a two-car train at most.
	for i in 4:
		var z := -300.0 - 40.0 * float(i)
		data.railways.append(_rail({}, [Vector2(-1300, z), Vector2(1300, z)]))
		data.rail_platforms.append({"points": PackedVector2Array([Vector2(200, z - 2.0), Vector2(250, z - 2.0),
			Vector2(250, z - 6.0), Vector2(200, z - 6.0), Vector2(200, z - 2.0)])})
	var ground := GroundTruth.new(data)
	var m2u := WorldScale.metres_to_units()
	var trains := StationTrains.plan(data, ground, m2u)
	if trains.size() < 2 or trains.size() > 10 or trains.size() != StationTrains.plan(data, ground, m2u).size():
		failures.append("about half of ten platform tracks should hold a train: %d" % trains.size())
	for t: Dictionary in trains:
		var mid: Vector2 = ((t["a"] as Vector2) + (t["b"] as Vector2)) * 0.5
		var short := mid.y < -200.0
		if str(t["at"]) != "platform" or absf(mid.x - (225.0 if short else 0.0)) > 0.5 \
				or absf(fposmod(mid.y + 100.0 + 20.0, 40.0) - 20.0) > 0.01:
			failures.append("a platform's train stands on its track, centred on the platform: %s" % mid)
		if short and int(t["cars"]) != 2:
			failures.append("a 50 m platform takes two cars: %d" % int(t["cars"]))
		if not str(t["livery"]).begins_with("rail"):
			failures.append("France runs the generic unit here: %s" % t["livery"])
	data.rail_platforms = []
	if not StationTrains.plan(data, ground, m2u).is_empty():
		failures.append("through tracks without platforms hold no train")

func _gate(failures: Array[String]) -> void:
	var data := _data(60.17, 24.94, "FI")
	_station(data)
	var ground := GroundTruth.new(data)
	var m2u := WorldScale.metres_to_units()
	RenderSettings.apply_preset(data, RenderSettings.Preset.BALANCED)
	var none := Node3D.new()
	if StationTrains.build(none, data, ground) != 0 or none.get_child_count() != 0:
		failures.append("Balanced builds no trains")
	none.free()
	RenderSettings.apply_preset(data, RenderSettings.Preset.ULTRA)
	var holder := Node3D.new()
	var built := StationTrains.build(holder, data, ground)
	if built < 2 or built > StationTrains.MAX_TRAINS or holder.get_child_count() != 1 or str(holder.get_child(0).name) != "Trains":
		failures.append("Ultra should build the trains under one holder: %d" % built)
	else:
		var near := 0
		var far := 0
		var shadows := 0
		for node in holder.get_child(0).get_children():
			var mi := node as MeshInstance3D
			if not mi.has_meta("lod_own"):
				failures.append("%s must own its visibility range (LodRing)" % mi.name)
			if mi.name.ends_with("_near"):
				near += 1
				if mi.visibility_range_begin != 0.0 or absf(mi.visibility_range_end - StationTrains.DETAIL_M * m2u) > 0.01:
					failures.append("%s should draw up to the detail range" % mi.name)
			elif mi.name.ends_with("_far"):
				far += 1
				# No far limit: a train is seen from across the station and beyond.
				if absf(mi.visibility_range_begin - StationTrains.DETAIL_M * m2u) > 0.01 or mi.visibility_range_end != 0.0:
					failures.append("%s should draw from the detail range on, without end" % mi.name)
				if mi.custom_aabb != (holder.get_child(0).get_node(str(mi.name).replace("_far", "_near")) as MeshInstance3D).custom_aabb:
					failures.append("%s and its near mesh must switch at one distance" % mi.name)
			else:
				shadows += 1
		if near == 0 or near != far or shadows != near:
			failures.append("every car needs a near, a far and a shadow instance: %d / %d / %d" % [near, far, shadows])
	holder.free()
	if StationTrains.DETAIL_M < 240.0 or StationTrains.MAX_TRAINS > 30:
		failures.append("a station switches detail around 250 m and caps its trains")
