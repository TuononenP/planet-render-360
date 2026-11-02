class_name LandmarkSetFinlandRegions
extends RefCounted

## Builders of the finland_regions landmark batch: one `match` arm per
## registry type of LandmarkRegistryFinlandRegions. Returns false for a type it does
## not own so LandmarkBuilder tries the next set.

static func build(model: Node3D, type: String) -> bool:
	match type:
		"turku_castle": LandmarkFrTurku.turku_castle(model)
		"naantali_convent_church": LandmarkFrTurku.naantali(model)
		"rauma_holy_cross_church": LandmarkFrTurku.rauma(model)
		"tampere_cathedral": LandmarkFrTampere.cathedral(model)
		"nasinneula_tower": LandmarkFrTampere.nasinneula(model)
		"pyynikki_observation_tower": LandmarkFrTampere.pyynikki(model)
		"kaleva_church": LandmarkFrTampere.kaleva(model)
		"hame_castle": LandmarkFrCastles.hame(model)
		"olavinlinna_castle": LandmarkFrCastles.olavinlinna(model)
		"kastelholm_castle": LandmarkFrCastles.kastelholm(model)
		"puijo_tower": LandmarkFrCities.puijo(model)
		"kuopio_cathedral": LandmarkFrCities.kuopio_cathedral(model)
		"oulu_cathedral": LandmarkFrCities.oulu_cathedral(model)
		"vaasa_trinity_church": LandmarkFrCities.vaasa(model)
		"arktikum_rovaniemi": LandmarkFrNorth.arktikum(model)
		"lumberjacks_candle_bridge": LandmarkFrNorth.candle_bridge(model)
		"santa_claus_village": LandmarkFrNorth.santa_village(model)
		"lahti_ski_jumping_hills": LandmarkFrLahti.lahti(model)
		"kerimaki_church": LandmarkFrTimber.kerimaki(model)
		"petajavesi_old_church": LandmarkFrTimber.petajavesi(model)
		"ainola": LandmarkFrTimber.ainola(model)
		"hvittrask": LandmarkFrTimber.hvittrask(model)
		"lakeuden_risti_church": LandmarkFrAalto.lakeuden_risti(model)
		"saynatsalo_town_hall": LandmarkFrAalto.saynatsalo(model)
		"vuoksenniska_church": LandmarkFrAalto.vuoksenniska(model)
		_:
			return false
	return true
