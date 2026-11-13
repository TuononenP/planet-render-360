class_name Snowbanks
extends RefCounted

## Ploughed snow just outside the kerbs near the camera. Desktop Ultra,
## snowy seasons only, merged in one surface. Junctions and mapped
## obstacles stay clear; each ridge follows the rendered ground.
const HEIGHT_M := 0.35
const WIDTH_M := 0.65

static func build(root: Node3D, data: LocationData, ground: GroundTruth) -> int:
	if not RenderQuality.ultra_desktop(data.quality_preset) or not ClimateModel.snowy_at_viewpoint(data, data.season):
		return 0
	var m := WorldScale.metres_to_units()
	var centre := View360.spawn_xz(data)
	var r2 := pow(ParkedCars.RADIUS_M * m, 2.0)
	var junc := RoadSurface.junctions(data)
	var obstacles := ParkedCars.obstacle_grid(data, m)
	var kit := ReliefKit.new()
	var source := StandardMaterial3D.new()
	source.albedo_color = Color(0.64, 0.65, 0.61)
	source.roughness = 0.95
	# Ploughed snow is old snow: grey with grit, not fresh white.
	var material := StreetSnow.material(source, 0.45)
	var count := 0
	for road in data.roads:
		if not (road is Dictionary) or str(road.get("class", "")) not in ParkedCars.CLASSES \
				or bool(road.get("bridge", false)) or bool(road.get("tunnel", false)) or bool(road.get("area", false)):
			continue
		var pts: PackedVector2Array = road.get("points", PackedVector2Array())
		if pts.size() < 2:
			continue
		var dense := KerbBuilder._dense(pts, 1.8 * m)
		var half := (float(road.get("width_m", 6.0)) * 0.5 + 0.35) * m
		for side in [-1.0, 1.0]:
			# Which stretches hold a bank, then each vertex's size, so
			# neighbouring stretches join and a run tapers where it stops.
			var keep: Array[bool] = []
			for i in dense.size() - 1:
				var n := _side_normal(dense[i], dense[i + 1], side)
				var mid := (dense[i] + dense[i + 1]) * 0.5 + n * half
				keep.append(not (mid.distance_squared_to(centre) > r2 or ground.water_at(mid.x, mid.y) > 0.0
					or ParkedCars._near_junction(mid, junc, KerbBuilder.CUT_M * m)
					or ParkedCars.blocked(mid, obstacles, m)))
			for i in dense.size() - 1:
				if not keep[i]:
					continue
				var a := _ridge(dense, i, keep, side, half, m, ground)
				var b := _ridge(dense, i + 1, keep, side, half, m, ground)
				_bank(kit, material, a, b)
				count += 1
	if count == 0:
		return 0
	kit.flush(root, "Snowbanks")
	return count

## Outward normal (plan view) of the road stretch a→b on `side`.
static func _side_normal(a: Vector2, b: Vector2, side: float) -> Vector2:
	var dir := (b - a).normalized()
	return Vector2(dir.y, -dir.x) * side

## Ridge line at dense vertex `i`: [foot centre, outward axis, height,
## half width]. Lumpy by position (shared by both stretches meeting
## there), shrinking to a low tail where the run stops.
static func _ridge(dense: PackedVector2Array, i: int, keep: Array[bool], side: float,
		half: float, m: float, ground: GroundTruth) -> Array:
	var a := dense[maxi(i - 1, 0)]
	var b := dense[mini(i + 1, dense.size() - 1)]
	var n := _side_normal(a, b, side)
	var joined := i > 0 and i < keep.size() and keep[i - 1] and keep[i]
	var lump := ParkedCars._hash(dense[i].x, dense[i].y, 8.0)
	var lump2 := ParkedCars._hash(dense[i].y, dense[i].x, 5.0)
	var taper := 1.0 if joined else 0.2
	var c := dense[i] + n * (half + (lump2 - 0.5) * 0.12 * m)
	var foot := Vector3(c.x, ground.height_at_world(c.x, c.y) + 0.03 * m, c.y)
	# Ploughs leave heaps, not a kerb: some stretches twice the height of others.
	var h := HEIGHT_M * (0.5 + 0.95 * lump * lump) * taper * m
	var w := WIDTH_M * 0.5 * (0.85 + 0.35 * lump2) * (1.0 if joined else 0.6) * m
	return [foot, Vector3(n.x, 0.0, n.y), h, w]

## Rounded cross-section (foot, shoulder, crown, shoulder, foot) between
## ridge points a and b: five flat facets, never a sharp prism.
const PROFILE := [Vector2(-1.0, 0.0), Vector2(-0.62, 0.6), Vector2(-0.22, 0.96),
	Vector2(0.22, 0.96), Vector2(0.62, 0.6), Vector2(1.0, 0.0)]

static func _bank(kit: ReliefKit, material: Material, a: Array, b: Array) -> void:
	for k in PROFILE.size() - 1:
		var p0 := _at(a, PROFILE[k])
		var p1 := _at(b, PROFILE[k])
		var p2 := _at(b, PROFILE[k + 1])
		var p3 := _at(a, PROFILE[k + 1])
		var n := (p1 - p0 + p2 - p3).cross(p3 - p0 + p2 - p1)
		if n.y < 0.0:
			n = -n
		kit.quad(material, p0, p1, p2, p3, n.normalized() if n.length_squared() > 1e-12 else Vector3.UP)

static func _at(r: Array, q: Vector2) -> Vector3:
	return (r[0] as Vector3) + (r[1] as Vector3) * (q.x * float(r[3])) + Vector3.UP * (q.y * float(r[2]))
