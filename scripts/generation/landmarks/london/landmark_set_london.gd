class_name LandmarkSetLondon
extends RefCounted

## Builders of the London landmark batch (`LandmarkRegistryLondon`).
## Returns false for unknown types so `LandmarkBuilder` continues down the sets list.

static func build(model: Node3D, type: String) -> bool:
	var spec := LnTowerSpecs.spec_for(type)
	if not spec.is_empty():
		TowerSpec.build(model, spec)
		if type == "one_canada_square":
			model.set_meta(LandmarkLights.HALO_META, [[Vector3(0.0, 235.0, 0.0), 3.0, Color(1.0, 0.12, 0.05)]])
		return true
	match type:
		"county_hall":
			LandmarkLnCountyHall.build(model)
		"westminster_bridge":
			LandmarkLnWestminsterBridge.build(model)
		"hungerford_golden_jubilee":
			LandmarkLnHungerfordBridge.build(model)
		"millennium_bridge":
			LandmarkLnMillenniumBridge.build(model)
		"portcullis_house":
			LandmarkLnPortcullisHouse.build(model)
		"whitehall_horse_guards":
			LandmarkLnWhitehall.horse_guards(model)
		"whitehall_court":
			LandmarkLnWhitehall.whitehall_court(model)
		"admiralty_arch":
			LandmarkLnWhitehall.admiralty_arch(model)
		"trafalgar_square":
			LandmarkLnTrafalgarSquare.build(model)
		"royal_festival_hall":
			LandmarkLnSouthBankArts.royal_festival_hall(model)
		"national_theatre":
			LandmarkLnSouthBankArts.national_theatre(model)
		"oxo_tower":
			LandmarkLnSouthBankArts.oxo_tower(model)
		"somerset_house":
			LandmarkLnSomersetWestminster.somerset_house(model)
		"methodist_central_hall":
			LandmarkLnSomersetWestminster.methodist_central_hall(model)
		"lambeth_palace":
			LandmarkLnSomersetWestminster.lambeth_palace(model)
		"cleopatras_needle_london":
			LandmarkLnSomersetWestminster.cleopatras_needle(model)
		"tate_modern":
			LandmarkLnBanksideCity.tate_modern(model)
		"shakespeares_globe":
			LandmarkLnBanksideCity.shakespeares_globe(model)
		"bank_junction":
			LandmarkLnBanksideCity.bank_junction(model)
		"monument_london":
			LandmarkLnBanksideCity.monument_london(model)
		"lloyds_building":
			LandmarkLnBanksideCity.lloyds_building(model)
		"st_pancras_station":
			LandmarkLnCentralIcons.st_pancras_station(model)
		"british_museum":
			LandmarkLnCentralIcons.british_museum(model)
		"westminster_cathedral":
			LandmarkLnCentralIcons.westminster_cathedral(model)
		"bt_tower":
			LandmarkLnCentralIcons.bt_tower(model)
		"battersea_power_station":
			LandmarkLnWestEastIcons.battersea_power_station(model)
		"royal_albert_hall":
			LandmarkLnWestEastIcons.royal_albert_hall(model)
		"natural_history_museum":
			LandmarkLnWestEastIcons.natural_history_museum(model)
		"marble_wellington_arches":
			LandmarkLnWestEastIcons.marble_wellington_arches(model)
		"o2_arena":
			LandmarkLnWestEastIcons.o2_arena(model)
		_:
			return false
	return true
