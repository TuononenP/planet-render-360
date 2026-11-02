class_name LandmarkSetFinlandHelsinki
extends RefCounted

## Builders of the finland_helsinki landmark batch: one `match` arm per
## registry type of LandmarkRegistryFinlandHelsinki. Returns false for a type it does
## not own so LandmarkBuilder tries the next set.

static func build(model: Node3D, type: String) -> bool:
	match type:
		"uspenski_cathedral": LandmarkFhHelsinkiSacred.uspenski(model)
		"temppeliaukio_church": LandmarkFhHelsinkiSacred.temppeliaukio(model)
		"st_johns_church_helsinki": LandmarkFhHelsinkiSacred.stjohns(model)
		"kallio_church": LandmarkFhHelsinkiSacred.kallio(model)
		"national_museum_of_finland": LandmarkFhHelsinkiCivic.natmuseum(model)
		"parliament_house_helsinki": LandmarkFhHelsinkiCivic.parliament(model)
		"presidential_palace_helsinki": LandmarkFhHelsinkiCivic.presidential(model)
		"ateneum": LandmarkFhHelsinkiCivic.ateneum(model)
		"finlandia_hall": LandmarkFhHelsinkiHalls.finlandia(model)
		"finnish_national_opera": LandmarkFhHelsinkiHalls.opera(model)
		"helsinki_music_centre": LandmarkFhHelsinkiHalls.music(model)
		"kiasma": LandmarkFhHelsinkiModern.kiasma(model)
		"oodi_library": LandmarkFhHelsinkiModern.oodi(model)
		"dipoli": LandmarkFhHelsinkiModern.dipoli(model)
		"heureka_science_centre": LandmarkFhHelsinkiModern.heureka(model)
		"helsinki_central_station": LandmarkFhHelsinkiCity.station(model)
		"hotel_torni": LandmarkFhHelsinkiCity.torni(model)
		"old_market_hall_helsinki": LandmarkFhHelsinkiCity.markethall(model)
		"national_library_of_finland": LandmarkFhHelsinkiCity.natlibrary(model)
		"sibelius_monument": LandmarkFhHelsinkiMonuments.sibelius(model)
		"suomenlinna_fortress": LandmarkFhHelsinkiMonuments.suomenlinna(model)
		"helsinki_olympic_stadium": LandmarkFhHelsinkiMonuments.stadium(model)
		"hanko_water_tower": LandmarkFhHelsinkiMonuments.hanko(model)
		"espoo_cathedral": LandmarkFhRegionalChurches.espoo(model)
		"porvoo_cathedral": LandmarkFhRegionalChurches.porvoo(model)
		_:
			return false
	return true
