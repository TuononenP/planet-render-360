class_name LandmarkSetAfricaHistoric
extends RefCounted

## Builders of the africa_historic landmark batch: one `match` arm per
## registry type of LandmarkRegistryAfricaHistoric. Returns false for a type it does
## not own so LandmarkBuilder tries the next set.

static func build(model: Node3D, type: String) -> bool:
	match type:
		"koutoubia_mosque": LandmarkAfhMorocco.koutoubia(model)
		"hassan_tower_rabat": LandmarkAfhMorocco.hassan_tower(model)
		"ait_benhaddou": LandmarkAfhMorocco.ait_benhaddou(model)
		"great_mosque_kairouan": LandmarkAfhTunisia.kairouan(model)
		"el_djem_amphitheatre": LandmarkAfhTunisia.el_djem(model)
		"lalibela_st_george": LandmarkAfhEthiopia.lalibela_st_george(model)
		"aksum_obelisk": LandmarkAfhEthiopia.aksum_obelisk(model)
		"great_zimbabwe_enclosure": LandmarkAfhZimbabwe.great_enclosure(model)
		_:
			return false
	return true
