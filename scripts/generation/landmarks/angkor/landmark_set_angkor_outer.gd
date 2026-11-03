class_name LandmarkSetAngkorOuter
extends RefCounted

## Builders of the Siem Reap batch D: one `match` arm per registry type of
## LandmarkRegistryAngkorOuter. Returns false for a type it does not own so
## LandmarkBuilder tries the next set.

static func build(model: Node3D, type: String) -> bool:
	match type:
		_:
			return false
	return true
