extends SceneTree

## Worldwide OSM airport planes, ground & rooftop helipads, and live animated
## AirTrafficPlan + AircraftDriver test:
##   tools/godot_bg.sh --headless --script tests/airport_planes_test.gd

func _init() -> void:
	var failures: Array[String] = []

	# 1. OsmAeroway parsing: runway, taxiway, apron, parking_position, gate, helipad.
	var payload := JSON.stringify({
		"elements": [
			{"type": "way", "id": 1, "tags": {"aeroway": "runway", "ref": "04R/22L", "width": "60"},
				"geometry": [{"lat": 60.3172, "lon": 24.9400}, {"lat": 60.3172, "lon": 24.9900}]},
			{"type": "way", "id": 2, "tags": {"aeroway": "taxiway"},
				"geometry": [{"lat": 60.3182, "lon": 24.9400}, {"lat": 60.3173, "lon": 24.9402}]},
			{"type": "node", "id": 3, "lat": 60.3190, "lon": 24.9600,
				"tags": {"aeroway": "parking_position", "ref": "12"}},
			{"type": "node", "id": 4, "lat": 60.3195, "lon": 24.9620,
				"tags": {"aeroway": "gate", "ref": "G14"}},
			{"type": "node", "id": 5, "lat": 60.3205, "lon": 24.9630,
				"tags": {"aeroway": "helipad", "emergency": "yes", "location": "roof", "name": "Hospital Helipad"}},
			{"type": "node", "id": 6, "lat": 60.3210, "lon": 24.9650,
				"tags": {"aeroway": "helipad", "name": "Airport Helipad"}},
			{"type": "node", "id": 7, "lat": 60.3172, "lon": 24.9633,
				"tags": {"aeroway": "aerodrome", "aerodrome:type": "international"}},
		]
	})
	var parsed := OsmParser.parse_features(payload, 60.3172, 24.9633)
	var aw: Dictionary = parsed.get("aeroways", {})
	if (aw.get("runways", []) as Array).size() != 1:
		failures.append("expected 1 parsed runway, got %d" % (aw.get("runways", []) as Array).size())
	if (aw.get("stands", []) as Array).size() != 1 or (aw.get("gates", []) as Array).size() != 1:
		failures.append("expected 1 stand and 1 gate")
	if (aw.get("helipads", []) as Array).size() != 2:
		failures.append("expected 2 helipads, got %d" % (aw.get("helipads", []) as Array).size())

	# 2. Synthetic LocationData: parked planes + ground & rooftop helipads + live traffic.
	var data := LocationData.new()
	data.latitude = 60.3172
	data.longitude = 24.9633
	data.country = "FI"
	data.quality_preset = RenderSettings.Preset.ULTRA
	data.aeroways = aw
	# Enclosing hospital building under the rooftop helipad (node 5).
	var hp0: Dictionary = (aw["helipads"] as Array)[0]
	var hx := float(hp0["x"])
	var hz := float(hp0["z"])
	data.buildings = [
		{
			"name": "Meilahti Hospital",
			"building": "hospital",
			"height": 28.0,
			"footprint": PackedVector2Array([
				Vector2(hx - 20.0, hz - 20.0), Vector2(hx + 20.0, hz - 20.0),
				Vector2(hx + 20.0, hz + 20.0), Vector2(hx - 20.0, hz + 20.0),
			]),
		}
	]
	var root := Node3D.new()
	var count := AirportPlanes.build(root, data, null)
	if count < 4:
		failures.append("expected >= 4 parked+active aircraft, got %d" % count)

	# Verify rooftop helipad was elevated to ~28 m roof height and marked emergency.
	var helis := AirportPlanes.plan_helipads(data, null, 1.0)
	var saw_rooftop := false
	for h: Dictionary in helis:
		if bool(h["rooftop"]) and (h["pos"] as Vector3).y > 27.5 and bool(h["emergency"]):
			saw_rooftop = true
	if not saw_rooftop:
		failures.append("rooftop hospital helipad was not seated at roof height with EMS flag")

	# 3. Capital-airport clear_rect_m exclusion: no double-parked planes inside Copenhagen EKCH.
	var cph := LocationData.new()
	cph.latitude = 55.625643
	cph.longitude = 12.650685
	cph.country = "DK"
	cph.quality_preset = RenderSettings.Preset.ULTRA
	cph.aeroways = OsmAeroway.empty()
	(cph.aeroways["stands"] as Array).append({"x": 0.0, "z": 0.0, "dir": Vector2.RIGHT, "ref": "A1"})
	var cph_parked := AirportPlanes.plan_parked(cph, null, 1.0)
	if not cph_parked.is_empty():
		failures.append("stand inside Copenhagen capital airport clear_rect_m should be skipped")

	# 3b. TYKS Majakkasairaala (Turku) rooftop helipad gets an EMS helicopter.
	var tyks := LocationData.new()
	tyks.latitude = 60.452602
	tyks.longitude = 22.294515
	tyks.country = "FI"
	tyks.quality_preset = RenderSettings.Preset.ULTRA
	var tyks_helis := AirportPlanes.plan_helipads(tyks, null, 1.0)
	if tyks_helis.is_empty() or not bool(tyks_helis[0]["emergency"]) or (tyks_helis[0]["pos"] as Vector3).y < 43.0:
		failures.append("TYKS Majakkasairaala helipad should get an EMS helicopter at rooftop height (~43.9 m)")

	# 3c. Keilaniemi Helipad (Espoo) gets a civil executive helicopter.
	var keila := LocationData.new()
	keila.latitude = 60.169471
	keila.longitude = 24.830453
	keila.country = "FI"
	keila.quality_preset = RenderSettings.Preset.ULTRA
	var keila_helis := AirportPlanes.plan_helipads(keila, null, 1.0)
	if keila_helis.is_empty() or bool(keila_helis[0]["emergency"]):
		failures.append("Keilaniemi helipad should get a civil helicopter")

	# 4. Live AircraftDriver state transitions (takeoff -> climb with gear retract, heli takeoff).
	var traffic := root.get_node_or_null("AirTraffic") as Node3D
	if traffic == null:
		failures.append("missing AirTraffic node")
	else:
		var driver := traffic.get_node_or_null("AircraftDriver") as AircraftDriver
		if driver == null or driver.flights.is_empty():
			failures.append("missing AircraftDriver or flights")
		else:
			var saw_climb := false
			var saw_gear_retracted := false
			var saw_heli_airborne := false
			for _step in 320:
				driver.advance(0.5)
				for f: Dictionary in driver.flights:
					var st := str(f.get("state", ""))
					var agl := float(f.get("agl", 0.0))
					if st == "CLIMB" and agl > 30.0:
						saw_climb = true
						var node := traffic.find_child("Aircraft_" + str(f["kind"]), false, false)
						# Check exact flight node by meta
						for c in traffic.get_children():
							if c is Node3D and int(c.get_meta("flight_id", -1)) == int(f["id"]):
								var g := c.get_node_or_null("Gear") as Node3D
								if g != null and not g.visible:
									saw_gear_retracted = true
					if str(f["mode"]) == "helicopter" and agl > 20.0:
						saw_heli_airborne = true
			if not saw_climb:
				failures.append("no fixed-wing flight reached CLIMB > 30 m AGL")
			if not saw_gear_retracted:
				failures.append("landing gear did not retract above 25 m AGL")
			if not saw_heli_airborne:
				failures.append("helicopter did not climb above 20 m AGL")

	root.free()

	if failures.is_empty():
		print("airport_planes_test: PASS (OSM parse + parked + rooftop heli + CPH exclusion + live flight)")
		quit(0)
	else:
		for f in failures:
			printerr("airport_planes_test FAIL: ", f)
		quit(1)
