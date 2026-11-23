class_name BangkokWaterfront
extends RefCounted

## Bangkok khlong & Chao Phraya waterfront details (`BK-7.1`, `BK-7.3`, `BK-7.4`, `BK-10`):
##   1. Vertical weathered-concrete canal retaining walls, wet algae waterline bands,
##      paved bank footpaths (`1.4 m` coping walk), and white canal balustrades along
##      Rattanakosin's historic khlongs (`Khlong Rop Krung`, `Khlong Khu Mueang Doem`,
##      `Khlong Lot`, `Khlong Maha Nak` / `Saen Saep`), including segments where a park
##      lawn strip kept `ShoreEvidence` from marking the bank `"hard"`.
##   2. Floating steel-and-timber passenger pontoons with green/orange Thai pitched-roof
##      pier shelters & warm `PierLamp` globes (`BK-10`) at `Tha Chang`, `Tha Tien`,
##      `Tha Maharaj`, `Phra Arthit`, `Wat Arun`, and `Phan Fa Lilat` (Khlong Saen Saep
##      terminus, 520 m from the capital eye).
##   3. Floating green water-hyacinth (`Phak Top Chawa`) clumps near quiet canal & river
##      banks on Desktop Ultra (`BK-7.4`).

const PIERS := [
	# [id, lat, lon, bearing_deg, roof_hex, length_m, width_m]
	["tha_chang", 13.75232, 100.48872, 172.0, "#2E7A54", 28.0, 7.5],
	["tha_maharaj", 13.75518, 100.48842, 174.0, "#D26422", 26.0, 7.0],
	["tha_tien", 13.74568, 100.48992, 165.0, "#2E7A54", 28.0, 7.5],
	["wat_arun_pier", 13.74408, 100.48962, 164.0, "#D26422", 24.0, 6.8],
	["phra_arthit", 13.76315, 100.49368, 140.0, "#29688A", 26.0, 7.2],
	["phan_fa_lilat", 13.75602, 100.50615, 76.0, "#2E7A54", 18.0, 4.2],
]

static func applies(data: LocationData) -> bool:
	return data != null and CityStyles.city_of_region(CityStyles.region_at(data.latitude, data.longitude)) == "bangkok"

static func build(root: Node3D, data: LocationData, ground: GroundTruth, abort: BuildAbort = null) -> int:
	if not applies(data) or ground == null or ground.shoreline == null or not ground.shoreline.ready:
		return 0
	var m2u := WorldScale.metres_to_units()
	var lm := LandmarkMesh.new()
	lm.use("CanalWall", LandmarkMaterials.pbr("concrete", "#9F9B8E", 3.0))
	lm.use("WetBand", LandmarkMaterials.pbr("stone", "#464B3C", 2.0))
	lm.use("Walk", LandmarkMaterials.pbr("pavement", "#B8B2A4", 2.5))
	lm.use("Balustrade", LandmarkMaterials.pbr("render", "#F2EFE6", 2.0))
	lm.use("Pontoon", LandmarkMaterials.pbr("wood", "#6E533B", 2.0))
	lm.use("FloatSteel", LandmarkMaterials.paint("#333B42", 0.55, 0.4))
	lm.use("RoofGreen", LandmarkMaterials.pbr("slate", "#2E7A54", 2.0))
	lm.use("RoofOrange", LandmarkMaterials.pbr("terracotta", "#D26422", 2.0))
	lm.use("Hyacinth", LandmarkMaterials.pbr("grass", "#446F2E", 2.0))
	lm.use("PierLamp", LandmarkMaterials.lit("#FFE29C", 1.9))

	var wall_count := _khlong_walls_and_hyacinth(lm, data, ground, m2u, abort)
	var pier_count := _floating_piers(lm, data, ground, m2u)
	if wall_count + pier_count > 0:
		var holder := Node3D.new()
		holder.name = "BangkokWaterfront"
		lm.commit(holder)
		holder.scale = Vector3.ONE * m2u
		root.add_child(holder)
	return wall_count + pier_count

static func _khlong_walls_and_hyacinth(lm: LandmarkMesh, data: LocationData, ground: GroundTruth,
		m2u: float, abort: BuildAbort) -> int:
	var domains: ShoreDomains = ground.shoreline.domains
	var seen := {}
	var count := 0
	var ultra := RenderQuality.ultra_desktop(data.quality_preset)
	var bridge_pts: Array[Vector2] = []
	for r in data.roads:
		if r is Dictionary and bool((r as Dictionary).get("bridge", false)):
			var pts: PackedVector2Array = (r as Dictionary).get("points", PackedVector2Array())
			if pts.size() >= 2:
				bridge_pts.append((pts[0] + pts[pts.size() - 1]) * 0.5 / m2u)

	for seg in ground.shoreline.segments:
		if abort != null and abort.requested:
			break
		var body: Dictionary = domains.bodies[int(seg["body"])]
		if bool(body.get("still_pool", false)):
			continue
		var a_u: Vector2 = seg["a"]
		var b_u: Vector2 = seg["b"]
		var a := a_u / m2u
		var b := b_u / m2u
		var len_m := a.distance_to(b)
		if len_m < 1.2:
			continue
		var key := str([Vector2i(roundi(a.x * 10.0), roundi(a.y * 10.0)),
			Vector2i(roundi(b.x * 10.0), roundi(b.y * 10.0))])
		if seen.has(key):
			continue
		seen[key] = true

		var mid := (a + b) * 0.5
		# Old-town khlong belt lies within 1,350 m of Rattanakosin centre
		var in_khlong_zone := mid.length() <= 1350.0
		var is_hard := str(seg.get("kind", "")) == "hard"
		if not in_khlong_zone and not is_hard:
			continue

		var land: Vector2 = seg["land"]
		var wa := float(seg["water_a"]) / m2u
		var wb := float(seg["water_b"]) / m2u
		var ta := maxf(float(seg["top_a"]) / m2u, wa + 1.15)
		var tb := maxf(float(seg["top_b"]) / m2u, wb + 1.15)
		var wall_y := (ta + tb) * 0.5
		var water_y := (wa + wb) * 0.5
		var dir3 := Vector3(b.x - a.x, 0.0, b.y - a.y).normalized()
		var basis := Basis(dir3, Vector3.UP, Vector3(-land.x, 0.0, -land.y))
		var mid3 := Vector3(mid.x, 0.0, mid.y)

		# Vertical masonry/concrete khlong wall + wet waterline algae band + 1.25 m bank footpath slab
		var h_wall := maxf(wall_y - water_y + 0.55, 1.35)
		lm.box("CanalWall", mid3 + Vector3(land.x * 0.18, water_y - 0.5 + h_wall * 0.5, land.y * 0.18),
			Vector3(len_m + 0.12, h_wall, 0.38), basis, 0.0)
		lm.box("WetBand", mid3 + Vector3(-land.x * 0.02, water_y + 0.18, -land.y * 0.02),
			Vector3(len_m + 0.10, 0.42, 0.06), basis, 0.0)
		lm.box("Walk", mid3 + Vector3(land.x * 0.72, wall_y + 0.03, land.y * 0.72),
			Vector3(len_m + 0.08, 0.08, 1.25), basis, 0.0)

		# White canal balustrade along non-hard khlong segments (hard ones already get ShoreRailings)
		if in_khlong_zone and not is_hard and len_m >= 2.2:
			var near_bridge := false
			for bp in bridge_pts:
				if bp.distance_to(mid) < 8.5:
					near_bridge = true
					break
			if not near_bridge:
				var rail_off := Vector3(land.x * 0.28, 0.0, land.y * 0.28)
				var ra := Vector3(a.x, ta, a.y) + rail_off
				var rb := Vector3(b.x, tb, b.y) + rail_off
				lm.beam("Balustrade", ra + Vector3(0, 0.88, 0), rb + Vector3(0, 0.88, 0), 0.16, 0.12)
				lm.beam("Balustrade", ra + Vector3(0, 0.12, 0), rb + Vector3(0, 0.12, 0), 0.18, 0.14)
				var np := maxi(int(len_m / 1.6), 1)
				for k in np + 1:
					var pp := ra.lerp(rb, float(k) / float(np))
					lm.box("Balustrade", pp + Vector3(0, 0.48, 0), Vector3(0.14, 0.78, 0.14), Basis(), 0.0)

		# Floating green water hyacinth clumps drifting near banks on Ultra (`BK-7.4`)
		if ultra and fposmod(sin(mid.x * 19.3 + mid.y * 47.1) * 43758.5, 1.0) < 0.14:
			var hp := mid3 + Vector3(-land.x * 1.6, water_y + 0.06, -land.y * 1.6)
			lm.lathe("Hyacinth", hp, PackedVector2Array([
				Vector2(1.15, 0.0), Vector2(0.95, 0.16), Vector2(0.0, 0.22)]), 7, 1.35, 0.75)
		count += 1
	return count

static func _floating_piers(lm: LandmarkMesh, data: LocationData, ground: GroundTruth, m2u: float) -> int:
	var placed := 0
	for row in PIERS:
		var xz_u := WorldScale.xz_from_latlon(float(row[1]), float(row[2]), data.latitude, data.longitude)
		if not ground.is_inside(xz_u.x, xz_u.y):
			continue
		# Search within 32 m perpendicular to pier axis for true open water (`water_at >= 0.45`)
		var yaw := deg_to_rad(90.0 - float(row[3]))
		var along := Vector2(cos(yaw), -sin(yaw))
		var out_perp := Vector2(-along.y, along.x)
		var best_u := Vector2(INF, INF)
		for off_m in [0.0, 8.0, -8.0, 16.0, -16.0, 26.0, -26.0]:
			var cand := xz_u + out_perp * (float(off_m) * m2u)
			if ground.is_inside(cand.x, cand.y) and ground.water_at(cand.x, cand.y) >= 0.45:
				best_u = cand
				break
		if best_u.x == INF:
			continue

		var wy := ground.water_level_at(best_u.x, best_u.y) / m2u
		var p := Vector3(best_u.x / m2u, wy, best_u.y / m2u)
		var b := Basis(Vector3.UP, yaw)
		var plen := float(row[5])
		var pw := float(row[6])
		var roof_key := "RoofOrange" if str(row[4]) == "#D26422" else "RoofGreen"

		# Floating steel pontoon hull + timber deck + white guardrails + Thai pitched shelter + PierLamps
		lm.box("FloatSteel", p + Vector3(0, 0.18, 0), Vector3(plen, 0.65, pw), b, 0.0)
		lm.box("Pontoon", p + Vector3(0, 0.54, 0), Vector3(plen - 0.3, 0.10, pw - 0.3), b, 0.0)
		for sx in [-0.36, 0.0, 0.36]:
			for sz in [-0.38, 0.38]:
				lm.box("Balustrade", p + b * Vector3(sx * plen, 1.95, sz * pw), Vector3(0.22, 2.8, 0.22), b, 0.0)
		lm.gable(roof_key, p + Vector3(0, 3.35, 0), pw + 0.8, plen * 0.82, 1.55,
			b * Basis(Vector3.UP, PI * 0.5), 0.35, "Balustrade")
		for sx in [-0.38, 0.38]:
			lm.lathe("PierLamp", p + b * Vector3(sx * plen, 3.10, 0.0), PackedVector2Array([
				Vector2(0.08, 0.0), Vector2(0.22, 0.16), Vector2(0.05, 0.32)]), 8)
		placed += 1
	return placed
