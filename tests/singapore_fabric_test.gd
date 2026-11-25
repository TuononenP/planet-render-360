extends SceneTree

## Offline contract for Singapore city fabric, flora, water, fleet, buses, street furniture & notable overrides:
## `PLAN_Singapore_super_realistic.md` (SG-5, SG-6, SG-7).

var failures: Array[String] = []

func _init() -> void:
	# 1. Singapore districts resolve distinctly across Civic, Chinatown, CBD, Tiong Bahru, Orchard, Toa Payoh.
	var checks := [
		[1.2830, 103.8440, "sg_shophouse"],
		[1.2905, 103.8515, "sg_colonial"],
		[1.2840, 103.8510, "sg_tower"],
		[1.2848, 103.8330, "sg_artdeco"],
		[1.3040, 103.8325, "sg_mall"],
		[1.3340, 103.8490, "sg_hdb_slab"],
	]
	for ch in checks:
		var frame := CityStyles.local_frame("singapore", float(ch[0]), float(ch[1]))
		var hit := false
		for d_row in (frame.get("districts", []) as Array):
			var d := d_row as Array
			if str(d[0]) == str(ch[2]) and (d[1] as Vector2).length() <= float(d[2]):
				hit = true
				break
		if not hit:
			failures.append("district at %.4f,%.4f: expected '%s' active in local_frame" % [ch[0], ch[1], ch[2]])

	# 2. singapore_rule does NOT turn a large 3-storey civic hall into a shophouse.
	var big_civic := ArchitectureCitiesSingapore.singapore_rule("civic", {"district": "sg_colonial", "lv": 3, "area": 2400.0, "small": false, "year": 1930})
	if big_civic != "sg_colonial":
		failures.append("large 3-storey civic should be sg_colonial, got %s" % big_civic)
	var tall_hdb := ArchitectureCitiesSingapore.singapore_rule("apartments", {"district": "sg_hdb_slab", "lv": 40, "area": 1200.0, "small": false, "year": 2015})
	if tall_hdb != "sg_hdb_new":
		failures.append("40-storey HDB should be sg_hdb_new, got %s" % tall_hdb)

	# 3. SingaporeNotable fixes height=0 buildings cleanly.
	var sample := [{"osm_id": "way:46594832", "height": 0.0, "levels": 0}]
	var n := SingaporeNotable.apply(sample)
	if n != 1 or float(sample[0]["height"]) < 100.0:
		failures.append("SingaporeNotable did not fix Peninsula Plaza height=0: %s" % str(sample[0]))

	# 4. CityDetail includes singapore.
	if CityDetail.city_at(1.28967, 103.85007) != "singapore":
		failures.append("CityDetail.city_at(Padang) should be 'singapore', got '%s'" % CityDetail.city_at(1.28967, 103.85007))

	# 5. Garden City tree mix & HeritageZones singapore_island.
	var hz := HeritageZones.rule_at(1.28967, 103.85007)
	if str(hz.get("tree_mix", "")) != "singapore":
		failures.append("HeritageZones at Singapore should set tree_mix='singapore', got %s" % str(hz))
	var sg_street := TreeSpecies.mix("singapore", "street")
	if sg_street.is_empty() or str(sg_street[0][0]) != "rain_tree":
		failures.append("TreeSpecies.mix('singapore', 'street') should lead with rain_tree")

	# 6. WaterSurface Singapore palette.
	var d := LocationData.new()
	d.latitude = 1.2864
	d.longitude = 103.8545
	if not WaterSurface.singapore_water(d.latitude, d.longitude) or WaterSurface.inland_palette(d).is_empty():
		failures.append("WaterSurface Singapore inland palette missing")

	# 7. CarFleet, StreetFurniture, TrainSpecs, PresetViews.
	var fleet := CarFleet.profile_for("singapore", "SG")
	if (fleet["taxi"]["paint"] as Array).size() < 4:
		failures.append("Singapore taxi liveries missing")
	if StreetFurniture.furniture_family("southeast_asia", "SG", "singapore") != "sg":
		failures.append("StreetFurniture family for Singapore should be 'sg'")
	if not "singapore" in TrainSpecs.METRO_REGIONS:
		failures.append("TrainSpecs.METRO_REGIONS missing 'singapore'")
	var pv := PresetViews.for_pin(1.28967, 103.85007)
	if str(pv.get("id", "")) != "singapore":
		failures.append("PresetViews.for_pin(Singapore) should resolve to 'singapore', got %s" % str(pv))

	if failures.is_empty():
		print("SINGAPORE FABRIC OK: districts, rule, notable, trees, water, fleet, furniture, MRT, preset")
		quit(0)
	else:
		for f in failures:
			printerr("SINGAPORE FABRIC FAIL: ", f)
		quit(1)
