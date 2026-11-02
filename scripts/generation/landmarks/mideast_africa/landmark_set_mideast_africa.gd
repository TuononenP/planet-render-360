class_name LandmarkSetMideastAfrica
extends RefCounted

## Builders of the mideast africa landmark batch: one `match` arm per
## registry type of LandmarkRegistryMideastAfrica. Returns false for a type it does
## not own so LandmarkBuilder tries the next set.

static func build(model: Node3D, type: String) -> bool:
	match type:
		"sheikh_zayed_mosque": LandmarkMaZayed.build(model)
		"hassan_ii_mosque": LandmarkMaMosques.hassan_ii(model)
		"djenne_mosque": LandmarkMaMosques.djenne(model)
		"dome_of_the_rock": LandmarkMaMosques.dome_of_rock(model)
		"petra_treasury": LandmarkMaAncient.petra(model)
		"abu_simbel": LandmarkMaAncient.abu_simbel(model)
		"great_sphinx": LandmarkMaSphinx.build(model)
		"burj_al_arab": LandmarkMaGulf.burj_al_arab(model)
		"abraj_al_bait": LandmarkMaGulf.abraj_al_bait(model)
		"kingdom_centre": LandmarkMaOpenTowers.kingdom_centre(model)
		"dubai_frame": LandmarkMaOpenTowers.dubai_frame(model)
		"milad_tower": LandmarkMaTowers.milad(model)
		"cairo_tower": LandmarkMaTowers.cairo_tower(model)
		"kuwait_towers": LandmarkMaTowers.kuwait_towers(model)
		"azadi_tower": LandmarkMaModern.azadi(model)
		"museum_of_the_future": LandmarkMaModern.museum_of_the_future(model)
		_:
			return false
	return true
