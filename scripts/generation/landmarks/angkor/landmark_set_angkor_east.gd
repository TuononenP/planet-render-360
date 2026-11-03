class_name LandmarkSetAngkorEast
extends RefCounted

## Builders of the Siem Reap batch C: one `match` arm per registry type of
## LandmarkRegistryAngkorEast. Returns false for a type it does not own so
## LandmarkBuilder tries the next set.

static func build(model: Node3D, type: String) -> bool:
	match type:
		_:
			return false
	return true
