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
	var lm := LandmarkMesh.new()
	lm.use("Orange", LandmarkMaterials.paint("#DF631A", 0.65, 0.0))
	lm.use("Dark", LandmarkMaterials.paint("#29383C", 0.55, 0.0))
	lm.use("White", LandmarkMaterials.paint("#E7E4D8", 0.65, 0.0))
	# Double-ended hull and three orange passenger decks.
	lm.box("Orange", Vector3(0, 1.4, 0), Vector3(LENGTH_M, 4.0, BEAM_M))
	for level in 3:
		var y := 3.7 + float(level) * 3.0
		var length := LENGTH_M - 15.0 - float(level) * 6.0
		var width := BEAM_M - 3.0 - float(level) * 0.7
		lm.box("Orange", Vector3(0, y + 1.35, 0), Vector3(length, 2.7, width))
		for side in [-1.0, 1.0]:
			for i in 18:
				var x := -length * 0.46 + length * 0.92 * (float(i) + 0.5) / 18.0
				lm.box("Dark", Vector3(x, y + 1.5, side * (width * 0.5 + 0.02)),
					Vector3(length / 18.0 * 0.66, 1.25, 0.04))
		lm.box("White", Vector3(0, y + 2.73, 0), Vector3(length + 0.4, 0.16, width + 0.4))
	for end in [-1.0, 1.0]:
		lm.box("White", Vector3(end * 25.0, 13.7, 0), Vector3(10.0, 2.5, 9.0))
		lm.box("Dark", Vector3(end * 30.03, 14.0, 0), Vector3(0.06, 1.0, 7.5))
	return lm
