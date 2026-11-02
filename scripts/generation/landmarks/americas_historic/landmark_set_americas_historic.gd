class_name LandmarkSetAmericasHistoric
extends RefCounted

## Builders of the americas_historic landmark batch: one `match` arm per
## registry type of LandmarkRegistryAmericasHistoric. Returns false for a type it does
## not own so LandmarkBuilder tries the next set.

static func build(model: Node3D, type: String) -> bool:
	match type:
		"teotihuacan_pyramid_sun": LandmarkAmhMaya.sun_pyramid(model)
		"palenque_inscriptions": LandmarkAmhMaya.inscriptions(model)
		"tikal_temple_i": LandmarkAmhMaya.tikal_temple_i(model)
		"uxmal_magician": LandmarkAmhMaya.magician(model)
		"mexico_city_cathedral": LandmarkAmhLatin.mexico_city_cathedral(model)
		"el_capitolio_havana": LandmarkAmhLatin.el_capitolio(model)
		"jefferson_memorial": LandmarkAmhUsa.jefferson_memorial(model)
		"independence_hall": LandmarkAmhUsa.independence_hall(model)
		"mount_rushmore": LandmarkAmhEarth.mount_rushmore(model)
		"monks_mound": LandmarkAmhEarth.monks_mound(model)
		_:
			return false
	return true
