class_name LandmarkSetLevantPersia
extends RefCounted

## Builders of the levant_persia landmark batch: one `match` arm per
## registry type of LandmarkRegistryLevantPersia. Returns false for a type it does
## not own so LandmarkBuilder tries the next set.

static func build(model: Node3D, type: String) -> bool:
	match type:
		"palmyra_temple_of_bel": LandmarkLpLevant.palmyra_bel(model)
		"baalbek_temple_of_jupiter": LandmarkLpLevant.baalbek(model)
		"jerash_oval_plaza": LandmarkLpJerash.jerash_plaza(model)
		"jerash_hadrians_arch": LandmarkLpJerash.hadrians_arch(model)
		"persepolis_gate_of_all_nations": LandmarkLpPersia.persepolis(model)
		"ishtar_gate_babylon": LandmarkLpPersia.ishtar_gate(model)
		"holy_sepulchre_jerusalem": LandmarkLpJerusalem.holy_sepulchre(model)
		"al_aqsa_mosque": LandmarkLpJerusalem.al_aqsa(model)
		"umayyad_mosque_damascus": LandmarkLpSyria.umayyad(model)
		"krak_des_chevaliers": LandmarkLpKrak.krak(model)
		"imam_mosque_isfahan": LandmarkLpSilkRoad.imam_mosque(model)
		"registan_samarkand": LandmarkLpRegistan.registan(model)
		"kalyan_minaret_bukhara": LandmarkLpSilkRoad.kalyan(model)
		_:
			return false
	return true
