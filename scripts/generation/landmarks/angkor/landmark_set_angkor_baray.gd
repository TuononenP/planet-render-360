class_name LandmarkSetAngkorBaray
extends RefCounted

## Builders of the Siem Reap batch B: one `match` arm per registry type of
## LandmarkRegistryAngkorBaray. Returns false for a type it does not own so
## LandmarkBuilder tries the next set.

static func build(model: Node3D, type: String) -> bool:
	match type:
		_:
			return false
	return true
