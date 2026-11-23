class_name LandmarkSetMiami
extends RefCounted

## Builders of LandmarkRegistryMiami: a skyline spec tower through TowerSpec,
## or a bespoke Miami icon by its own builder class. Returns false for unknown
## types so LandmarkBuilder tries the next set.

static func build(model: Node3D, type: String) -> bool:
	var spec := MiamiTowerSpecs.spec_for(type)
	if not spec.is_empty():
		TowerSpec.build(model, spec)
		return true
	match type:
		"freedom_tower_miami": LandmarkMiFreedomTower.build(model)
		"kaseya_center": LandmarkMiKaseya.build(model)
		"pamm_miami": LandmarkMiPamm.build(model)
		"frost_science_miami": LandmarkMiFrost.build(model)
		"adrienne_arsht_center": LandmarkMiArsht.build(model)
		"skyviews_miami_wheel": LandmarkMiBayfront.build(model)
		"bacardi_building_miami": LandmarkMiBacardi.build(model)
		"one_thousand_museum": LandmarkMiOneThousandMuseum.build(model)
		"miamicentral_station": LandmarkMiMiamicentral.build(model)
		"miami_dade_cultural_center": LandmarkMiCulturalCenter.build(model)
		"brickell_city_centre_ribbon": LandmarkMiClimateRibbon.build(model)
		"atlantis_condominium": LandmarkMiAtlantis.build(model)
		"portmiami_terminal_a": LandmarkMiPortTerminalA.build(model)
		"portmiami_terminal_b": LandmarkMiPortTerminalB.build(model)
		"portmiami_terminal_v": LandmarkMiPortTerminalV.build(model)
		"portmiami_carnival_msc": LandmarkMiPortCarnivalMsc.build(model)
		"loandepot_park": LandmarkMiLoandepotPark.build(model)
		"wynwood_walls": LandmarkMiWynwoodWalls.build(model)
		"tower_theater_miami": LandmarkMiTowerTheater.build(model)
		"museum_garage_miami": LandmarkMiMuseumGarage.build(model)
		"fontainebleau_miami_beach": LandmarkMiFontainebleau.build(model)
		"faena_forum_miami_beach": LandmarkMiFaenaForum.build(model)
		"flagler_memorial_monument": LandmarkMiFlaglerMonument.build(model)
		"i395_signature_bridge": LandmarkMiSignatureBridge.build(model)
		"vizcaya_museum_gardens": LandmarkMiVizcaya.build(model)
		"miami_city_hall_dinner_key": LandmarkMiDinnerKeyCityHall.build(model)
		"ermita_de_la_caridad": LandmarkMiErmita.build(model)
		"biltmore_hotel_coral_gables": LandmarkMiBiltmore.build(model)
		"venetian_pool_coral_gables": LandmarkMiVenetianPool.build(model)
		"coral_gables_city_hall": LandmarkMiCgCityHall.build(model)
		"alhambra_water_tower": LandmarkMiAlhambraTower.build(model)
		"douglas_entrance_coral_gables": LandmarkMiDouglasEntrance.build(model)
		"cape_florida_lighthouse": LandmarkMiCapeFlorida.build(model)
		"miami_marine_stadium": LandmarkMiMarineStadium.build(model)
		"stiltsville_biscayne_bay": LandmarkMiStiltsville.build(model)
		"seaquarium_golden_dome": LandmarkMiSeaquariumDome.build(model)
		"hard_rock_stadium": LandmarkMiHardRockStadium.build(model)
		"nu_stadium_freedom_park": LandmarkMiNuStadium.build(model)
		"ancient_spanish_monastery": LandmarkMiSpanishMonastery.build(model)
		"opa_locka_city_hall": LandmarkMiOpaLockaCityHall.build(model)
		"ocean_drive_colony_starlite": LandmarkMiColonyStarlite.build(model)
		"ocean_drive_breakwater_edison": LandmarkMiBreakwaterEdison.build(model)
		"art_deco_welcome_center": LandmarkMiWelcomeCenter.build(model)
		"casa_casuarina_versace": LandmarkMiCasaCasuarina.build(model)
		"ocean_drive_carlyle_cardozo": LandmarkMiCarlyleCardozo.build(model)
		"lincoln_road_1111": LandmarkMiLincoln1111.build(model)
		"new_world_center_miami": LandmarkMiNewWorldCenter.build(model)
		"miami_beach_convention_center": LandmarkMiConventionCenter.build(model)
		"holocaust_memorial_miami_beach": LandmarkMiHolocaustMemorial.build(model)
		"old_city_hall_miami_beach": LandmarkMiMbOldCityHall.build(model)
		"south_pointe_pier_park": LandmarkMiSouthPointe.build(model)
		"br_miami_brickell_ave": LandmarkMiBrickellBridge.build(model, BridgeSpecs.row_for(type))
		_:
			return false
	return true
