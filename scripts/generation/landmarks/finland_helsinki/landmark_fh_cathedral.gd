extends RefCounted

## helsinki_cathedral. Its registry row is a core entry (LocationData,
## Helsinki's primary landmark); LandmarkBuilder builds it here.

static func build(model: Node3D) -> void:
	LandmarkCathedrals.helsinki(model)
