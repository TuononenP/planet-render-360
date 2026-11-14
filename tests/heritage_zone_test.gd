extends SceneTree

## Headless: godot --headless --script tests/heritage_zone_test.gd
## Heritage zones (HeritageZones) round the Angkor temples: an untagged
## footprint inside the park is a low house, never an apartment block;
## inside the Angkor Wat island it is one storey; a mapped gate or ruin
## there gives way to the landmark model; a temple has no pagoda tower and
## builds no generic archetype; a tagged height is kept; nothing changes
## outside a zone. Also the precinct clearance (clear_rect_m, tree
## keep-outs) and the monsoon dry season (ClimateModel.winter_dry).

const WAT := Vector2(13.41249, 103.86684)

func _init() -> void:
	var failures: Array[String] = []
	_zone_checks(failures)
	_building_checks(failures)
	_clearance_checks(failures)
	_climate_checks(failures)
	if failures.is_empty():
		print("HERITAGE ZONE OK: Angkor footprints low, monuments to the models, precinct clear, dry season")
		quit(0)
	else:
		for f in failures:
			printerr("HERITAGE ZONE FAIL: ", f)
		quit(1)

static func _square(c: Vector2, side: float) -> PackedVector2Array:
	var h := side * 0.5
	return PackedVector2Array([c + Vector2(-h, -h), c + Vector2(h, -h), c + Vector2(h, h), c + Vector2(-h, h)])

static func _building(c: Vector2, side: float, extra: Dictionary = {}) -> Dictionary:
	var b := {"x": c.x, "z": c.y, "footprint": _square(c, side), "size_x": side, "size_z": side,
		"height": 10.0, "height_source": "default", "levels": 0, "kind": "yes", "use": "",
		"religion": "", "historic": ""}
	b.merge(extra, true)
	return b

static func _data(at: Vector2, country: String) -> LocationData:
	var d := LocationData.new()
	d.latitude = at.x
	d.longitude = at.y
	d.country = country
	return d

func _zone_checks(failures: Array[String]) -> void:
	if int(HeritageZones.rule_at(WAT.x, WAT.y).get("max_storeys", 0)) != 1:
		failures.append("the Angkor Wat island should cap storeys at 1")
	var ta_prohm := HeritageZones.rule_at(13.4350, 103.8893)
	if int(ta_prohm.get("max_storeys", 0)) != 2 or str(ta_prohm.get("tree_mix", "")) != "khmer":
		failures.append("the Angkor park should cap storeys at 2 with the khmer tree mix, got %s" % str(ta_prohm))
	if not HeritageZones.rule_at(13.7563, 100.5018).is_empty():
		failures.append("Bangkok lies in no heritage zone")
	if HeritageZones.near(13.7563, 100.5018, 2400.0):
		failures.append("Bangkok should not be near a heritage zone")

func _building_checks(failures: Array[String]) -> void:
	var d := _data(WAT, "KH")
	# Inside the island, north of the temple (z is south).
	var hall := _building(Vector2(60.0, -300.0), 25.0)
	var gate := _building(Vector2(-548.0, 0.0), 36.0, {"historic": "city_gate"})
	var temple := _building(Vector2(-20.0, 330.0), 30.0, {"kind": "temple", "religion": "buddhist"})
	var tagged := _building(Vector2(150.0, -320.0), 20.0,
		{"height": 12.0, "height_source": "tag_height"})
	d.buildings = [hall, gate, temple, tagged]
	d.land_polygons = [{"class": "grass", "points": _square(Vector2(-300.0, 150.0), 40.0)}]
	HeritageZones.apply(d)
	if d.buildings.has(gate):
		failures.append("a historic gate inside the island should give way to the model")
	if not d.buildings.has(hall) or not d.buildings.has(temple) or not d.buildings.has(tagged):
		failures.append("ordinary footprints inside the zone must stay")
	if str(hall.get("kind", "")) != "house":
		failures.append("an untagged 625 m2 footprint should become a house, got %s" % str(hall.get("kind", "")))
	if str((d.land_polygons[0] as Dictionary).get("sward", "")) != "wild":
		failures.append("park grass in the zone should read as wild meadow")
	var ctx := BuildingHeights._height_context(d)
	var look := BuildingHeights._look_for(hall, ctx)
	var h := float(BuildingHeights._resolve_total(hall, hall, ctx, {}, look)["total_m"])
	if h > float(look["floor_h"]) + BuildingHeights.ZONE_ROOF_M + 0.01 or int(look["storeys"]) > 1:
		failures.append("an untagged hall on the island should be one storey, got %.1f m / %d" % [h, int(look["storeys"])])
	var tl := BuildingHeights._look_for(temple, ctx)
	if str(tl["kind"]) != "religious" or str(tl["tower"]) != "":
		failures.append("a temple in the zone should be a religious hall with no tower, got %s / %s"
			% [str(tl["kind"]), str(tl["tower"])])
	var th := BuildingHeights._look_for(tagged, ctx)
	if absf(float(BuildingHeights._resolve_total(tagged, tagged, ctx, {}, th)["total_m"]) - 12.0) > 0.01:
		failures.append("a tagged height inside the zone must be kept")
	# The park outside the island: two storeys at most, never apartments.
	var park := _data(Vector2(13.4350, 103.8893), "KH")
	var block := _building(Vector2(200.0, 200.0), 30.0)
	park.buildings = [block]
	HeritageZones.apply(park)
	var pctx := BuildingHeights._height_context(park)
	var pl := BuildingHeights._look_for(block, pctx)
	var ph := float(BuildingHeights._resolve_total(block, block, pctx, {}, pl)["total_m"])
	if str(pl["kind"]) == "apartments" or ph > 2.0 * float(pl["floor_h"]) + BuildingHeights.ZONE_ROOF_M + 0.01:
		failures.append("an untagged park footprint should stay a low house, got %s %.1f m" % [str(pl["kind"]), ph])
	# OSM temple archetypes give way in the zone.
	var kept := HeritageZones.filter_candidates(d, [{"x": -20.0, "z": 330.0, "archetype": "temple"}])
	if not kept.is_empty():
		failures.append("an OSM temple candidate in the zone should build no generic archetype")
	# Outside every zone nothing changes.
	var bkk := _data(Vector2(13.7563, 100.5018), "TH")
	var flat := _building(Vector2(0.0, 0.0), 30.0, {"historic": "ruins"})
	bkk.buildings = [flat]
	HeritageZones.apply(bkk)
	if not bkk.buildings.has(flat) or flat.has("zone_storeys") or str(flat["kind"]) != "yes":
		failures.append("buildings outside a zone must be left alone")
	if HeritageZones.filter_candidates(bkk, [{"x": 0.0, "z": 0.0}]).size() != 1:
		failures.append("candidates outside a zone must be kept")

func _clearance_checks(failures: Array[String]) -> void:
	var entry := LocationData.entry_for_type("angkor_wat")
	var site := Vector2.ZERO
	if LandmarkSites.rect_dist(Vector2(-400.0, 0.0), site, entry) != 0.0:
		failures.append("the Angkor Wat avenue should lie inside its precinct rect")
	if LandmarkSites.span_dist(Vector2(0.0, -330.0), site, entry) < LandmarkSites.clear_m(entry):
		failures.append("the monastery north of the temple should stay outside the clearance")
	var d := _data(WAT, "KH")
	d.landmark_type = "angkor_wat"
	d.has_landmark_site = true
	d.landmark_lat = WAT.x
	d.landmark_lon = WAT.y
	var clears := LandmarkSites.tree_clears(d)
	if not LandmarkSites.tree_cleared(Vector2(-450.0, 30.0), clears):
		failures.append("no tree should stand on the avenue lawn")
	if LandmarkSites.tree_cleared(Vector2(200.0, -300.0), clears):
		failures.append("trees should stand north-east inside the enclosure")
	# Without a precinct the default 48 m circle still holds.
	var paris := LocationData.entry_for_type("eiffel_tower")
	if not paris.is_empty() and paris.has("tree_clear_m"):
		failures.append("the Eiffel Tower should keep the default tree clearance")

func _climate_checks(failures: Array[String]) -> void:
	var siem_reap := _data(Vector2(13.36, 103.86), "KH")
	siem_reap.climate = {"t_warm_c": 30.0, "t_cold_c": 25.5, "precip_mm": 1400.0,
		"precip_warm_mm": 260.0, "precip_dry_mm": 28.0}
	if not ClimateModel.winter_dry(siem_reap):
		failures.append("Siem Reap should have a hard winter dry season")
	if ClimateModel.grass_tint(siem_reap, LocationData.Season.WINTER).a < 0.5:
		failures.append("Siem Reap grass should be straw-coloured in the dry season")
	if ClimateModel.grass_tint(siem_reap, LocationData.Season.SUMMER).a > 0.5:
		failures.append("Siem Reap grass should stay green in the wet season")
	if ClimateModel.biome(siem_reap) != "tropical":
		failures.append("Siem Reap should stay tropical")
	var paris := _data(Vector2(48.85, 2.35), "FR")
	paris.climate = {"t_warm_c": 19.0, "t_cold_c": 4.5, "precip_mm": 640.0, "precip_warm_mm": 165.0,
		"precip_dry_mm": 140.0}
	if ClimateModel.winter_dry(paris):
		failures.append("Paris has no tropical dry season")
	var old := _data(Vector2(13.36, 103.86), "KH")
	old.climate = {"t_warm_c": 30.0, "t_cold_c": 25.5, "precip_mm": 1400.0, "precip_warm_mm": 260.0}
	if ClimateModel.winter_dry(old):
		failures.append("a climate copy without the driest quarter must not guess a dry season")
