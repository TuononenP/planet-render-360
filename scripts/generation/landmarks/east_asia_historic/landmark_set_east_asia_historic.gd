class_name LandmarkSetEastAsiaHistoric
extends RefCounted

## Builders of the east_asia_historic landmark batch: one `match` arm per
## registry type of LandmarkRegistryEastAsiaHistoric. Returns false for a type it does
## not own so LandmarkBuilder tries the next set.

static func build(model: Node3D, type: String) -> bool:
	match type:
		"terracotta_army_pit1": LandmarkEahXian.terracotta_pit1(model)
		"big_wild_goose_pagoda": LandmarkEahXian.wild_goose(model)
		"summer_palace_buddhist_incense": LandmarkEahChina.incense_tower(model)
		"tiananmen_gate": LandmarkEahChina.tiananmen(model)
		"leshan_giant_buddha": LandmarkEahLeshan.leshan(model)
		"todaiji_daibutsuden": LandmarkEahTemples.todaiji(model)
		"kiyomizu_dera": LandmarkEahTemples.kiyomizu(model)
		"senso_ji": LandmarkEahSensoji.senso_ji(model)
		"osaka_castle": LandmarkEahCastles.osaka(model)
		"matsumoto_castle": LandmarkEahCastles.matsumoto(model)
		_:
			return false
	return true
