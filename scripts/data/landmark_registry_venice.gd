class_name LandmarkRegistryVenice
extends RefCounted

## Registry entries for the Venice super-realistic landmark batch (`VN-1`–`VN-7`).
## Types are built by `LandmarkSetVenice`.

static func entries() -> Array:
	var out: Array = []
	out.append_array(VnRegGrandCanal.entries())
	out.append_array(VnRegSanMarco.entries())
	out.append_array(VnRegSestieri.entries())
	out.append_array(VnRegBridges.entries())
	return out
