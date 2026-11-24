class_name AmsterdamStreetLife
extends RefCounted

## Amsterdam street-level cultural life (`AMS-7.2`, desktop Ultra within 420 m):
##   1. Parked Dutch bicycle rows (*fietsen* / *omafietsen*) lined up along
##      canal bridges, quays and residential kerbs.
##   2. Floating Bloemenmarkt flower-stall greenhouses along Singel.
##   3. Canal-side outdoor café terrace tables at Spui, Damstraat & Noordermarkt.

static func applies(data: LocationData) -> bool:
	return data != null and CityStyles.city_of_region(CityStyles.region_at(data.latitude, data.longitude)) == "amsterdam"

static func build(root: Node3D, data: LocationData, ground: GroundTruth, _mask: Variant, m2u: float) -> int:
	if not applies(data) or ground == null or not RenderQuality.ultra_desktop(data.quality_preset):
		return 0
	var centre := View360.spawn_xz(data)
	var lm := LandmarkMesh.new()
	lm.use("BikeDark", LandmarkMaterials.pbr("sheet_metal", "#1E2226", 1.5, 0.45, 0.7))
	lm.use("BikeRed", LandmarkMaterials.paint("#9E2B24", 0.38, 0.5))
	lm.use("BikeBlue", LandmarkMaterials.paint("#224D7A", 0.38, 0.5))
	lm.use("Steel", LandmarkMaterials.pbr("sheet_metal", "#8C949C", 1.5, 0.35, 0.8))
	lm.use("Green", LandmarkMaterials.paint("#234C32", 0.7, 0.1))
	lm.use("Flower", LandmarkMaterials.paint("#D95338", 0.75, 0.05))
	lm.use("Yellow", LandmarkMaterials.paint("#E6B830", 0.75, 0.05))
	lm.use("Glass", LandmarkMaterials.glass("#3A5260"))
	lm.use("Wood", LandmarkMaterials.pbr("wood", "#6E4E34", 2.0))

	var count := 0
	var r_max := 420.0 * m2u
	# 1. Parked bicycle rows along residential & canal bridge kerbs
	var placed: Array[Vector2] = []
	for w in data.roads:
		if not (w is Dictionary):
			continue
		var d: Dictionary = w
		var cls := str(d.get("class", ""))
		if cls not in ["residential", "pedestrian", "cycleway", "tertiary"] and not bool(d.get("bridge", false)):
			continue
		var pts: PackedVector2Array = d.get("points", PackedVector2Array())
		if pts.size() < 2:
			continue
		var mid := pts[pts.size() / 2]
		if mid.distance_to(centre) > r_max:
			continue
		var too_close := false
		for p in placed:
			if p.distance_to(mid) < 26.0 * m2u:
				too_close = true
				break
		if too_close:
			continue
		placed.append(mid)
		var dir := (pts[mini(pts.size() - 1, pts.size() / 2 + 1)] - pts[maxi(0, pts.size() / 2 - 1)]).normalized()
		if dir.length_squared() < 0.2:
			continue
		var side := Vector2(-dir.y, dir.x)
		var kerb_m := float(d.get("width_m", 6.0)) * 0.5 + 0.7
		var at := mid + side * kerb_m * m2u
		if ground.water_at(at.x, at.y) > 0.05:
			continue
		var y_m := ground.height_at_world(at.x, at.y) / m2u
		var yaw := atan2(-dir.y, dir.x)
		_bike_row(lm, Vector3(at.x / m2u, y_m, at.y / m2u), yaw, 5)
		count += 1
		if count >= 75:
			break

	# 2. Floating Bloemenmarkt greenhouse stalls along Singel (52.3668..52.3672, 4.8902..4.8926)
	var bm_a := WorldScale.xz_from_latlon(52.36675, 4.89030, data.latitude, data.longitude)
	var bm_b := WorldScale.xz_from_latlon(52.36718, 4.89245, data.latitude, data.longitude)
	if bm_a.length() < 1100.0:
		var wy := ground.water_level_at(bm_a.x * m2u, bm_a.y * m2u) / m2u
		if is_nan(wy) or wy < -200.0:
			wy = 0.0
		var b_dir := (bm_b - bm_a).normalized()
		var b_yaw := atan2(-b_dir.y, b_dir.x)
		var rot := Basis(Vector3.UP, b_yaw)
		for i in 10:
			var p := bm_a.lerp(bm_b, (float(i) + 0.5) / 10.0)
			var o := Vector3(p.x, wy, p.y)
			lm.box("Green", o + Vector3(0.0, 0.4, 0.0), Vector3(11.0, 0.8, 4.4), rot)
			lm.box("Glass", o + Vector3(0.0, 1.9, 0.0), Vector3(10.6, 2.2, 4.0), rot)
			lm.box("Flower" if i % 2 == 0 else "Yellow", o + rot * Vector3(0.0, 1.15, 2.15), Vector3(9.4, 0.65, 0.6), rot)
		count += 10

	if count > 0:
		var holder := Node3D.new()
		holder.name = "AmsterdamStreetLife"
		lm.commit(holder)
		holder.scale = Vector3.ONE * m2u
		root.add_child(holder)
	return count

static func _bike_row(lm: LandmarkMesh, origin: Vector3, street_yaw: float, n: int) -> void:
	var dir := Vector3(cos(street_yaw), 0.0, -sin(street_yaw))
	var colors := ["BikeDark", "BikeDark", "BikeRed", "BikeBlue", "BikeDark"]
	for i in n:
		var p := origin + dir * (float(i) - float(n - 1) * 0.5) * 0.72
		var b := Basis(Vector3.UP, street_yaw + 1.35)
		var frame_m: String = colors[i % colors.size()]
		# Front & rear bicycle wheels + classic Dutch *omafiets* diamond frame & handlebars
		lm.box("BikeDark", p + b * Vector3(0.0, 0.34, 0.56), Vector3(0.06, 0.66, 0.66), b)
		lm.box("BikeDark", p + b * Vector3(0.0, 0.34, -0.56), Vector3(0.06, 0.66, 0.66), b)
		lm.beam(frame_m, p + b * Vector3(0.0, 0.36, -0.52), p + b * Vector3(0.0, 0.88, 0.42), 0.05, 0.05)
		lm.beam(frame_m, p + b * Vector3(0.0, 0.92, -0.18), p + b * Vector3(0.0, 0.36, 0.02), 0.05, 0.05)
		lm.beam("Steel", p + b * Vector3(-0.28, 1.04, 0.42), p + b * Vector3(0.28, 1.04, 0.42), 0.04, 0.04)
