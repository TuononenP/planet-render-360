extends RefCounted

## helsinki_cathedral. Its registry row is a core entry (LocationData,
## Helsinki's primary landmark); LandmarkBuilder builds it here.

static func build(model: Node3D) -> void:
	LandmarkCathedrals.helsinki(model)
	var warm := Color(1.0, 0.88, 0.68)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(0.0, 10.4, 42.0), Vector3(0.0, 21.0, 31.0), 44.0, 0.95, 55.0, warm],
		[Vector3(0.0, 10.4, -42.0), Vector3(0.0, 21.0, -31.0), 44.0, 0.85, 55.0, warm],
		[Vector3(42.0, 10.4, 0.0), Vector3(31.0, 21.0, 0.0), 44.0, 0.85, 55.0, warm],
		[Vector3(-42.0, 10.4, 0.0), Vector3(-31.0, 21.0, 0.0), 44.0, 0.85, 55.0, warm],
		[Vector3(-22.0, 27.0, 22.0), Vector3(0.0, 42.0, 0.0), 34.0, 1.0, 65.0, warm],
		[Vector3(22.0, 27.0, -22.0), Vector3(0.0, 42.0, 0.0), 34.0, 1.0, 65.0, warm],
	])
