class_name HarbourFerries
extends RefCounted

## Procedural harbour traffic at a mapped Staten Island Ferry terminal.
## This is scenery, not a claim about a vessel's real-time position.
## The 310 ft / 70 ft municipal-orange ferries: https://siferry.com/current-vessels/
const LENGTH_M := 94.5
const BEAM_M := 21.3

static func terminal(b: Dictionary) -> bool:
	return str(b.get("use", "")) == "ferry_terminal" \
		and str(b.get("name", "")).to_lower().contains("staten island ferry")

## Search outward from the terminal, keeping the entire vessel in water
## and clear of mapped roads and buildings. Its long axis points to shore.
static func berth(b: Dictionary, ground: GroundTruth, mask: VegetationMask) -> Dictionary:
	var origin := Vector2(float(b.get("x", 0.0)), float(b.get("z", 0.0)))
	for distance in [180.0, 220.0, 260.0, 300.0]:
		for i in 24:
			var a := TAU * float(i) / 24.0
			var axis := Vector2(cos(a), sin(a))
			var side := Vector2(-axis.y, axis.x)
			var centre: Vector2 = origin + axis * float(distance)
			var clear := true
			for along in [-0.5, 0.0, 0.5]:
				for across in [-0.5, 0.0, 0.5]:
					var p: Vector2 = centre + axis * (LENGTH_M + 16.0) * float(along) \
						+ side * (BEAM_M + 16.0) * float(across)
					if not ground.is_inside(p.x, p.y) or ground.water_at(p.x, p.y) < 0.5 \
							or mask.blocked(p.x, p.y, VegetationMask.BUILDING | VegetationMask.ROAD, 0.0):
						clear = false
			if clear:
				return {"centre": centre, "axis": axis}
	return {}

static func build(root: Node3D, data: LocationData, ground: GroundTruth, mask: VegetationMask) -> int:
	if not RenderQuality.ultra_desktop(data.quality_preset):
		return 0
	for b in data.buildings:
		if not (b is Dictionary) or not terminal(b):
			continue
		var site := berth(b, ground, mask)
		if site.is_empty():
			continue
		var lm := model()
		var p: Vector2 = site["centre"]
		var axis: Vector2 = site["axis"]
		print("HARBOUR-FERRY berth=(%.1f, %.1f) axis=(%.2f, %.2f)" % [p.x, p.y, axis.x, axis.y])
		for part in lm.commit(root, "HarbourFerry_"):
			part.position = Vector3(p.x, ground.water_level_at(p.x, p.y), p.y)
			part.rotation.y = atan2(-axis.y, axis.x)
			part.set_meta("procedural_ferry", true)
		return 1
	return 0

static func model() -> LandmarkMesh:
	return FerryVesselModel.build()
