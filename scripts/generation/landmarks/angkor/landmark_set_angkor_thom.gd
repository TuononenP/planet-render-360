class_name LandmarkSetAngkorThom
extends RefCounted

## Builders of the Siem Reap batch A: one `match` arm per registry type of
## LandmarkRegistryAngkorThom. Returns false for a type it does not own so
## LandmarkBuilder tries the next set.

static func build(model: Node3D, type: String) -> bool:
	match type:
		_:
			return false
	return true
