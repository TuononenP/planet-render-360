class_name LandmarkSetCambodia
extends RefCounted

## Builders of the cambodia landmark batch: one `match` arm per
## registry type of LandmarkRegistryCambodia. Returns false for a type it does
## not own so LandmarkBuilder tries the next set.

static func build(model: Node3D, type: String) -> bool:
	match type:
		"independence_monument":
			LandmarkKhMonuments.independence(model)
		"cambodia_vietnam_monument":
			LandmarkKhMonuments.friendship(model)
		"vattanac_capital":
			LandmarkKhMonuments.vattanac(model)
		"royal_palace_phnom_penh":
			LandmarkKhPalace.royal_palace(model)
		"silver_pagoda":
			LandmarkKhPalace.silver_pagoda(model)
		"national_museum_cambodia":
			LandmarkKhPalace.national_museum(model)
		"wat_phnom":
			LandmarkKhCity.wat_phnom(model)
		"central_market_phnom_penh":
			LandmarkKhCity.central_market(model)
		"bayon_temple":
			LandmarkKhAngkor.bayon(model)
		"angkor_thom_south_gate":
			LandmarkKhAngkor.south_gate(model)
		"ta_prohm":
			LandmarkKhAngkor.ta_prohm(model)
		"banteay_srei":
			LandmarkKhTemples.banteay_srei(model)
		"phnom_bakheng":
			LandmarkKhTemples.phnom_bakheng(model)
		"preah_vihear_temple":
			LandmarkKhTemples.preah_vihear(model)
		"prasat_thom_koh_ker":
			LandmarkKhTemples.koh_ker(model)
		_:
			return false
	return true
