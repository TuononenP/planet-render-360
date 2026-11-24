class_name LandmarkRegistryAmsterdam
extends RefCounted

## Registry entries for the Amsterdam landmark batch (`PLAN_Amsterdam_super_realistic.md`):
## Dam Square & Canal Ring (`AmsRegCentre`), Museumplein / Amstel / Jewish Quarter
## (`AmsRegCulture`), IJ Waterfront / Harbour / Stadiums / Bespoke Bridges
## (`AmsRegWaterfront`), and Skyline Towers (`AmsTowerSpecs`).
##
## Matches Stockholm's Ultra budget (`48` landmarks + `8` bridges = `56` total)
## on Amsterdam's four primary anchors so the full historic core, Museumplein,
## IJ waterfront and Amstel bridges all stand together on Ultra.

const ULTRA_REGISTRY_LIMIT := 48
const ULTRA_TOTAL_LIMIT := 56

const PRIMARIES: Array[String] = [
	"royal_palace_amsterdam",
	"westerkerk",
	"amsterdam_centraal",
	"rijksmuseum",
]

static func entries() -> Array:
	var out: Array = []
	for group in [AmsRegCentre.entries(), AmsRegCulture.entries(), AmsRegWaterfront.entries()]:
		for raw in group:
			var entry: Dictionary = (raw as Dictionary).duplicate()
			if str(entry.get("type", "")) in PRIMARIES:
				entry["icon"] = true
				entry["ultra_registry_limit"] = ULTRA_REGISTRY_LIMIT
				entry["ultra_total_limit"] = ULTRA_TOTAL_LIMIT
			elif not entry.has("secondary"):
				entry["secondary"] = true
			out.append(entry)
	out.append_array(AmsTowerSpecs.entries())
	return out
