class_name LandmarkSetAngkorEast
extends RefCounted

## Builders of the Siem Reap batch C: one `match` arm per registry type of
## LandmarkRegistryAngkorEast. Returns false for a type it does not own so
## LandmarkBuilder tries the next set.

static func build(model: Node3D, type: String) -> bool:
	match type:
		"preah_khan_angkor":
			LandmarkAngEast.preah_khan(model)
		"ta_keo":
			LandmarkAngTaKeo.ta_keo(model)
		"prasat_kravan":
			LandmarkAngEastSmall.prasat_kravan(model)
		"banteay_samre":
			LandmarkAngEastSmall.banteay_samre(model)
		"srah_srang":
			LandmarkAngEastSmall.srah_srang(model)
		_:
			return false
	return true
