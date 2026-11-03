class_name LandmarkSetAngkorOuter
extends RefCounted

## Builders of the Siem Reap batch D: one `match` arm per registry type of
## LandmarkRegistryAngkorOuter. Returns false for a type it does not own so
## LandmarkBuilder tries the next set.

static func build(model: Node3D, type: String) -> bool:
	match type:
		"bakong_temple":
			LandmarkAngRoluos.bakong(model)
		"preah_ko_temple":
			LandmarkAngRoluos.preah_ko(model)
		"lolei_temple":
			LandmarkAngRoluos.lolei(model)
		"beng_mealea":
			LandmarkAngOuter.beng_mealea(model)
		"phnom_krom":
			LandmarkAngOuter.phnom_krom(model)
		"west_mebon":
			LandmarkAngOuter.west_mebon(model)
		_:
			return false
	return true
