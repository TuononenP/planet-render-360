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
	var material := StreetSnow.material(source)
	var count := 0
	for road in data.roads:
		if not (road is Dictionary) or str(road.get("class", "")) not in ParkedCars.CLASSES \
				or bool(road.get("bridge", false)) or bool(road.get("tunnel", false)) or bool(road.get("area", false)):
			continue
		var pts: PackedVector2Array = road.get("points", PackedVector2Array())
		if pts.size() < 2:
			continue
		var dense := KerbBuilder._dense(pts, 3.0 * m)
		for side in [-1.0, 1.0]:
			for i in dense.size() - 1:
				var dir := (dense[i + 1] - dense[i]).normalized()
				var n := Vector2(dir.y, -dir.x) * float(side)
				var half := (float(road.get("width_m", 6.0)) * 0.5 + 0.35) * m
				var a := dense[i] + n * half
				var b := dense[i + 1] + n * half
				var mid := (a + b) * 0.5
				if mid.distance_squared_to(centre) > r2 or ground.water_at(mid.x, mid.y) > 0.0 \
						or ParkedCars._near_junction(mid, junc, KerbBuilder.CUT_M * m) \
						or ParkedCars.blocked(mid, obstacles, m):
					continue
				var ya := ground.height_at_world(a.x, a.y)
				var yb := ground.height_at_world(b.x, b.y)
				var wobble := 0.8 + ParkedCars._hash(mid.x, mid.y, 8.0) * 0.35
				var h := HEIGHT_M * wobble * m
				var az := Vector3(n.x, 0, n.y)
				var pa := Vector3(a.x, ya + 0.03 * m, a.y)
				var pb := Vector3(b.x, yb + 0.03 * m, b.y)
				var skirt := az * WIDTH_M * 0.5 * m
				var crown := Vector3.UP * h
				kit.quad(material, pa - skirt, pb - skirt, pb + crown, pa + crown, (-az + Vector3.UP).normalized())
				kit.quad(material, pa + crown, pb + crown, pb + skirt, pa + skirt, (az + Vector3.UP).normalized())
				count += 1
	if count == 0:
		return 0
	kit.flush(root, "Snowbanks")
	return count
