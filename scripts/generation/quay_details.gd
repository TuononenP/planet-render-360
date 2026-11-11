class_name QuayDetails
extends RefCounted

## One merged casting mesh on the dry top of finalized hard banks.
## Keep harbour fittings off natural shores and ornamental pools, and
## out of quayside buildings and carriageways when a mask is given.
static func build(root: Node3D, data: LocationData, ground: GroundTruth, mask: VegetationMask = null) -> int:
	if not RenderQuality.ultra_desktop(data.quality_preset) or ground.shoreline == null or not ground.shoreline.ready:
		return 0
	var lm := LandmarkMesh.new()
	lm.use("Iron", StreetSnow.material(ShipBuilder._paint("#343b3e")))
	var taken := {}
	var centre := View360.spawn_xz(data)
	for segment in ground.shoreline.segments:
		if str(segment["kind"]) != "hard":
			continue
		var body: Dictionary = ground.shoreline.domains.bodies[int(segment["body"])]
		if bool(body.get("still_pool", false)):
			continue
		var p: Vector2 = (segment["a"] + segment["b"]) * 0.5
		if p.distance_to(centre) > MarinaBuilder.RADIUS_M:
			continue
		var key := Vector2i(roundi(p.x / 12.0), roundi(p.y / 12.0))
		if taken.has(key):
			continue
		var top := (float(segment["top_a"]) + float(segment["top_b"])) * 0.5
		var water := (float(segment["water_a"]) + float(segment["water_b"])) * 0.5
		if top - water < 0.3 or top - water > 5.0:
			continue
		var at: Vector2 = p + (segment["land"] as Vector2) * 0.8
		# Not inside a warehouse built on the quay wall, nor in a quayside
		# carriageway.
		if mask != null and mask.blocked(at.x, at.y, VegetationMask.BUILDING | VegetationMask.ROAD, 0.0):
			continue
		var pos := Vector3(at.x, top, at.y)
		lm.box("Iron", pos + Vector3.UP * 0.04, Vector3(0.48, 0.08, 0.48), Basis(), 0.025)
		lm.frustum("Iron", pos + Vector3.UP * 0.08, 0.15, 0.20, 0.34, 10)
		var dir: Vector2 = (segment["b"] - segment["a"]).normalized()
		var horn := Vector3(dir.x, 0, dir.y) * 0.30
		lm.beam("Iron", pos + Vector3.UP * 0.34 - horn, pos + Vector3.UP * 0.34 + horn, 0.15)
		# A separate iron mooring ring hangs on the water-facing wall.
		# Offset it below the deck and just outside the wall plane.
		var land: Vector2 = segment["land"]
		var ring_at := Vector3(p.x - land.x * 0.05, top - 0.55, p.y - land.y * 0.05)
		_mooring_ring(lm, ring_at, Vector3(dir.x, 0, dir.y))
		taken[key] = true
	lm.commit(root, "QuayBollards_")
	return taken.size()

## Iron ring in the wall's vertical plane, with a small mounting plate.
static func _mooring_ring(lm: LandmarkMesh, centre: Vector3, along: Vector3) -> void:
	var radius := 0.16
	var first := centre + along * radius
	var previous := first
	for i in range(1, 13):
		var angle := TAU * float(i) / 12.0
		var next := centre + (along * cos(angle) + Vector3.UP * sin(angle)) * radius
		lm.beam("Iron", previous, next, 0.045, 0.045)
		previous = next
	lm.beam("Iron", centre + Vector3.UP * radius, centre + Vector3.UP * (radius + 0.12), 0.06)
