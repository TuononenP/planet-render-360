class_name LandmarkSetFinlandTurku
extends RefCounted

## Dispatches the Turku landmark batch (LandmarkRegistryFinlandTurku).
## Returns true when `type` belongs to this set.

static func build(model: Node3D, type: String) -> bool:
	match type:
		"mikaelinkirkko": LandmarkFtChurches.mikaelinkirkko(model)
		"martinkirkko": LandmarkFtChurches.martinkirkko(model)
		"turku_orthodox_church": LandmarkFtChurches.turku_orthodox_church(model)
		"turku_art_museum": LandmarkFtCivic.turku_art_museum(model)
		"vartiovuori_observatory": LandmarkFtCivic.vartiovuori_observatory(model)
		"turku_market_hall": LandmarkFtCivic.turku_market_hall(model)
		"turku_main_library": LandmarkFtCivic.turku_main_library(model)
		"turku_city_theatre": LandmarkFtCivic.turku_city_theatre(model)
		"kakola_prison": LandmarkFtHistoric.kakola_prison(model)
		"vanha_suurtori": LandmarkFtHistoric.vanha_suurtori(model)
		"suomen_joutsen": LandmarkFtHistoric.suomen_joutsen(model)
		"fori_ferry": LandmarkFtHistoric.fori_ferry(model)
		_:
			return false
	return true
