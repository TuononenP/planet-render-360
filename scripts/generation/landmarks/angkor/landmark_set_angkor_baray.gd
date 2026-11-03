class_name LandmarkSetAngkorBaray
extends RefCounted

## Builders of the Siem Reap batch B: one `match` arm per registry type of
## LandmarkRegistryAngkorBaray. Returns false for a type it does not own so
## LandmarkBuilder tries the next set.

static func build(model: Node3D, type: String) -> bool:
	match type:
		"pre_rup":
			LandmarkAngBaray.pre_rup(model)
		"east_mebon":
			LandmarkAngBaray.east_mebon(model)
		"ta_som":
			LandmarkAngCloister.ta_som(model)
		"banteay_kdei":
			LandmarkAngCloister.banteay_kdei(model)
		"neak_pean":
			LandmarkAngNeakPean.neak_pean(model)
		_:
			return false
	return true
