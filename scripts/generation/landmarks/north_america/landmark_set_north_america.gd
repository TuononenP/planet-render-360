class_name LandmarkSetNorthAmerica
extends RefCounted

## Builders of the north america landmark batch: one `match` arm per
## registry type of LandmarkRegistryNorthAmerica. Returns false for a type it does
## not own so LandmarkBuilder tries the next set.

static func build(model: Node3D, type: String) -> bool:
	match type:
		"cn_tower": LandmarkNaTowers.cn_tower(model)
		"space_needle": LandmarkNaTowers.space_needle(model)
		"the_strat": LandmarkNaTowers.strat(model)
		"willis_tower": LandmarkNaSkyscrapers.willis_tower(model)
		"chrysler_building": LandmarkNaSkyscrapers.chrysler_building(model)
		"transamerica_pyramid": LandmarkNaSkyscrapers.transamerica_pyramid(model)
		"wtc_oculus": LandmarkNaOculus.build(model)
		"flatiron_building": LandmarkNaSkyscrapers.flatiron(model)
		"washington_monument": LandmarkNaMonuments.washington_monument(model)
		"lincoln_memorial": LandmarkNaMonuments.lincoln_memorial(model)
		"angel_of_independence": LandmarkNaMonuments.angel_of_independence(model)
		"us_capitol": LandmarkNaCapitol.build(model)
		"white_house": LandmarkNaBuildings.white_house(model)
		"bellas_artes": LandmarkNaBuildings.bellas_artes(model)
		"chateau_frontenac": LandmarkNaFrontenac.build(model)
		"gateway_arch": LandmarkNaCivil.gateway_arch(model)
		"hoover_dam": LandmarkNaCivil.hoover_dam(model)
		"hollywood_sign": LandmarkNaCivil.hollywood_sign(model)
		"el_castillo": LandmarkNaCastillo.build(model)
		_:
			return false
	return true
