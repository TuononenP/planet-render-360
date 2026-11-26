class_name LandmarkSetCapitalAirports
extends RefCounted

## Builders of the capital_airports landmark batch: one `match` arm per
## registry type of LandmarkRegistryCapitalAirports. Returns false for a
## type it does not own so LandmarkBuilder tries the next set.

static func build(model: Node3D, type: String) -> bool:
	match type:
		"reykjavik_airport": LandmarkCaNorth.reykjavik(model)
		"tallinn_airport": LandmarkCaNorth.tallinn(model)
		"stockholm_bromma_airport": LandmarkCaNorth.stockholm(model)
		"vilnius_airport": LandmarkCaNorth.vilnius(model)
		"copenhagen_airport": LandmarkCaNorth.copenhagen(model)
		"lisbon_airport": LandmarkCaAtlantic.lisbon(model)
		"washington_national_airport": LandmarkCaAtlantic.washington(model)
		"aeroparque_jorge_newbery": LandmarkCaAtlantic.aeroparque(model)
		"taipei_songshan_airport": LandmarkCaFar.songshan(model)
		"wellington_airport": LandmarkCaFar.wellington(model)
		"kathmandu_airport": LandmarkCaFar.kathmandu(model)
		"wattay_airport": LandmarkCaFar.wattay(model)
		"maputo_airport": LandmarkCaFar.maputo(model)
		"helsinki_vantaa_airport": LandmarkCaNorth.vantaa(model)
		_:
			return false
	return true
