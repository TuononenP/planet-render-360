class_name ShipBuilder
extends RefCounted

## Mapped vessels retain their oriented map envelope, but use a lofted hull
## and a vessel model chosen by type and length (cruise liner, passenger
## ship, tall ship, motor or sailing yacht, runabout, houseboat) rather than
## apartment height inference and facade extrusion. Missing type / height /
## colour uses a documented generic look: a coastal passenger ship, or a
## cruise liner from LINER_MIN_M.
const KINDS := ["ship", "boat", "houseboat"]
const SAILING := ["sailing", "sailboat", "sailing_ship", "tall_ship"]
const LINER_MIN_M := 100.0
const HULL_COLOURS := ["#2d3b4a", "#6f2c26", "#202225", "#e6e4db", "#2f4a3c"]

static func accepts(b: Dictionary) -> bool:
	return str(b.get("kind", "")) in KINDS

static func frame(b: Dictionary) -> Dictionary:
	var ring: PackedVector2Array = b.get("footprint", PackedVector2Array())
	if ring.size() < 3:
		ring = BuildingWalls._rect_ring(Vector2(float(b["x"]), float(b["z"])),
			Vector2(float(b.get("size_x", 10.0)), float(b.get("size_z", 3.0))), 0.0)
	var axis := RingGeometry.dominant_axis(ring)
	var side := Vector2(-axis.y, axis.x)
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for p in ring:
		var q := Vector2(p.dot(axis), p.dot(side))
		lo = lo.min(q)
		hi = hi.max(q)
	var size := hi - lo
	if size.y > size.x:
		axis = side
		return frame_with_axis(ring, axis)
	return frame_with_axis(ring, axis)

static func frame_with_axis(ring: PackedVector2Array, axis: Vector2) -> Dictionary:
	var side := Vector2(-axis.y, axis.x)
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for p in ring:
		var q := Vector2(p.dot(axis), p.dot(side))
		lo = lo.min(q)
		hi = hi.max(q)
	var mid := (lo + hi) * 0.5
	var centre := axis * mid.x + side * mid.y
	if _width(ring, axis, lo.x + (hi.x - lo.x) * 0.1) < _width(ring, axis, hi.x - (hi.x - lo.x) * 0.1) * 0.8:
		axis = -axis  # the narrower end is the mapped bow
	return {"centre": centre, "axis": axis,
		"length": maxf(hi.x - lo.x, 0.5), "beam": maxf(hi.y - lo.y, 0.3)}

static func _width(ring: PackedVector2Array, axis: Vector2, at: float) -> float:
	var side := Vector2(-axis.y, axis.x)
	var lo := INF
	var hi := -INF
	for i in ring.size():
		var a := ring[i]
		var b := ring[(i + 1) % ring.size()]
		var dx := (b - a).dot(axis)
		if absf(dx) < 0.0001:
			continue
		var t := (at - a.dot(axis)) / dx
		if t >= 0.0 and t <= 1.0:
			var v := a.lerp(b, t).dot(side)
			lo = minf(lo, v)
			hi = maxf(hi, v)
	return maxf(hi - lo, 0.0)

static func height(b: Dictionary, length: float) -> float:
	var source := str(b.get("height_source", ""))
	if source == "tag_height" or (source == "" and float(b.get("height", 0.0)) > 0.0):
		return maxf(float(b["height"]), 0.5)
	if float(b.get("levels", 0.0)) > 0.0:
		return 1.4 + float(b["levels"]) * 2.4
	if length >= LINER_MIN_M:
		return clampf(length * 0.2, 22.0, 65.0)
	return clampf(3.0 + length * 0.12, 4.5, 16.0)

## The vessel model for a mapped feature of `length` metres.
static func model_for(b: Dictionary, length: float) -> String:
	var kind := str(b.get("kind", ""))
	if kind == "houseboat":
		return "houseboat"
	var vessel := str(b.get("vessel_kind", "motor"))
	if vessel in SAILING:
		return "tall_ship" if length >= 30.0 else "sail_yacht"
	if length >= LINER_MIN_M:
		return "liner"
	if kind == "boat" or vessel in ["yacht", "motor_yacht", "pleasure", "sport"]:
		if length < 9.0:
			return "runabout"
		if length < 30.0:
			return "motor_yacht"
	return "passenger"

static func build(root: Node3D, b: Dictionary, data: LocationData, ground: GroundTruth) -> bool:
	if not accepts(b):
		return false
	var f := frame(b)
	var at: Vector2 = f["centre"]
	var sea := WaterBuilder._has_coastline(data) or LandmarkTerrain.has_sea(data)
	var fallback := ground.render_y(0.0) if sea else ground.height_at_world(at.x, at.y)
	var y := ground.water_level_at(at.x, at.y, fallback)
	var length: float = f["length"]
	var model := model_for(b, length)
	var seed_value := fposmod(sin(at.x * 12.9898 + at.y * 78.233) * 43758.5453, 1.0)
	var maps := data.quality_preset != RenderSettings.Preset.FAST
	var colour := str(b.get("colour", ""))
	if MaterialLibrary.parse_colour_tag(colour).a <= 0.0:
		colour = CruiseLinerModel.hull_hex(seed_value * 4.0) if model == "liner" \
			else str(HULL_COLOURS[int(seed_value * HULL_COLOURS.size()) % HULL_COLOURS.size()])
	var lm := VesselPrototypes.geometry(model, length, float(f["beam"]), height(b, length),
		VesselMaterials.paint(colour, maps, 0.42, 0.05), maps, maps, seed_value)
	var yaw := atan2(-(f["axis"] as Vector2).y, (f["axis"] as Vector2).x)
	for part in lm.commit(root, "MappedShip_"):
		part.position = Vector3(at.x, y, at.y)
		part.rotation.y = yaw
		part.set_meta("mapped_vessel", true)
		part.set_meta("vessel_model", model)
		part.set_meta("vessel_name", str(b.get("name", "")))
	return true

## A ten-metre prototype for the Ultra quay-side MultiMeshes. +X is bow.
static func mesh(kind: String) -> ArrayMesh:
	return VesselPrototypes.mesh(kind)

static func _paint(colour: String) -> StandardMaterial3D:
	return VesselMaterials.paint(colour, true, 0.6, 0.05)
