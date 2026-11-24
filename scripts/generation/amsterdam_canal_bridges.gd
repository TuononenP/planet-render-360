class_name AmsterdamCanalBridges
extends RefCounted

## Historic Amsterdam brick arched canal bridges (`AMS-4.3`):
## Styled on generic OSM `bridge=yes` crossings over inland canals inside
## Amsterdam without consuming any monumental bridge slots:
##   - Red-brown Dutch brick spandrel walls & pier abutments
##   - Pale Bentheimer sandstone coping & central arch keystones
##   - Dark Amsterdam-green / charcoal wrought-iron balustrades
##   - Classic four-corner Amsterdam globe lamp posts
##   - Warm golden arch fairy-lights (*brugverlichting*) glowing at night

static func applies(data: LocationData) -> bool:
	return data != null and CityStyles.city_of_region(CityStyles.region_at(data.latitude, data.longitude)) == "amsterdam"

static func build(root: Node3D, data: LocationData, ground: GroundTruth, surf: RoadBuilder._Surface, m2u: float) -> int:
	if not applies(data) or ground == null:
		return 0
	var lm := LandmarkMesh.new()
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#7E3A2C", 2.4))
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#D9CEB8", 2.6))
	lm.use("Iron", LandmarkMaterials.pbr("sheet_metal", "#202A24", 2.0, 0.45, 0.7))
	lm.use("BridgeLamp", LandmarkMaterials.lit("#FFD27D", 2.6))

	var count := 0
	var placed: Array[Vector2] = []
	for w in data.roads:
		if not (w is Dictionary):
			continue
		var d: Dictionary = w
		if not bool(d.get("bridge", false)) or bool(d.get("tunnel", false)) or bool(d.get("area", false)):
			continue
		if int(d.get("layer", 0)) > 1:
			continue
		var pts: PackedVector2Array = d.get("points", PackedVector2Array())
		if pts.size() < 2:
			continue
		var span_u := 0.0
		for i in range(1, pts.size()):
			span_u += pts[i].distance_to(pts[i - 1])
		var span_m := span_u / m2u
		if span_m < 6.0 or span_m > 58.0:
			continue
		var mid := pts[pts.size() / 2]
		if pts.size() % 2 == 0:
			mid = (pts[pts.size() / 2 - 1] + pts[pts.size() / 2]) * 0.5
		if not _over_canal(pts, ground):
			continue
		var dup := false
		for pc in placed:
			if pc.distance_to(mid) < 8.5 * m2u:
				dup = true
				break
		if dup:
			continue
		placed.append(mid)
		_dress_bridge(lm, pts, clampf(float(d.get("width_m", 7.5)), 4.0, 18.0), surf, m2u)
		count += 1
		if count >= 260:
			break

	if count > 0:
		var holder := Node3D.new()
		holder.name = "AmsterdamCanalBridges"
		lm.commit(holder)
		holder.scale = Vector3.ONE * m2u
		root.add_child(holder)
	return count

static func _over_canal(pts: PackedVector2Array, ground: GroundTruth) -> bool:
	for t in [0.25, 0.5, 0.75]:
		var idx := clampi(int(t * float(pts.size() - 1)), 0, pts.size() - 1)
		if ground.water_at(pts[idx].x, pts[idx].y) > 0.15:
			return true
	var p_mid := pts[0].lerp(pts[pts.size() - 1], 0.5)
	return ground.water_at(p_mid.x, p_mid.y) > 0.15

static func _dress_bridge(lm: LandmarkMesh, pts: PackedVector2Array, width_m: float,
		surf: RoadBuilder._Surface, m2u: float) -> void:
	var deck := RoadBridgeBuild.deck_profile(pts, surf, m2u, width_m * 0.5 * m2u, 0)
	if deck.size() != pts.size():
		return
	var half_m := width_m * 0.5 + 0.08
	for sgn in [-1.0, 1.0]:
		var s := float(sgn)
		for i in pts.size() - 1:
			var sa := RoadBuilder._side(pts, i) * half_m * s
			var sb := RoadBuilder._side(pts, i + 1) * half_m * s
			var a := Vector3(pts[i].x / m2u + sa.x, deck[i] / m2u, pts[i].y / m2u + sa.y)
			var b := Vector3(pts[i + 1].x / m2u + sb.x, deck[i + 1] / m2u, pts[i + 1].y / m2u + sb.y)
			var seg_l := a.distance_to(b)
			if seg_l < 0.35:
				continue
			# Brick spandrel fascia + sandstone coping + wrought-iron railing
			lm.beam("Brick", a + Vector3(0.0, -0.55, 0.0), b + Vector3(0.0, -0.55, 0.0), 0.42, 0.95)
			lm.beam("Stone", a + Vector3(0.0, 0.02, 0.0), b + Vector3(0.0, 0.02, 0.0), 0.50, 0.22)
			lm.beam("Iron", a + Vector3(0.0, 0.96, 0.0), b + Vector3(0.0, 0.96, 0.0), 0.12, 0.10)
			lm.beam("Iron", a + Vector3(0.0, 0.28, 0.0), b + Vector3(0.0, 0.28, 0.0), 0.08, 0.08)
			var np := maxi(int(seg_l / 1.4), 1)
			for k in np:
				var bp := a.lerp(b, (float(k) + 0.5) / float(np))
				lm.box("Iron", bp + Vector3(0.0, 0.55, 0.0), Vector3(0.08, 0.85, 0.08), Basis(), 0.0)
			# Sandstone arch keystone & warm golden arch fairy-lights (*brugverlichting*)
			var mid_p := a.lerp(b, 0.5)
			lm.box("Stone", mid_p + Vector3(0.0, -0.42, 0.0), Vector3(0.55, 0.65, 0.55))
			lm.beam("BridgeLamp", a + Vector3(0.0, -0.96, 0.0), b + Vector3(0.0, -0.96, 0.0), 0.12, 0.12)
		# Classic Amsterdam corner brick piers & dark iron globe lamp posts
		for end_i in [0, pts.size() - 1]:
			var se := RoadBuilder._side(pts, end_i) * (half_m + 0.06) * s
			var cp := Vector3(pts[end_i].x / m2u + se.x, deck[end_i] / m2u, pts[end_i].y / m2u + se.y)
			lm.box("Brick", cp + Vector3(0.0, 0.45, 0.0), Vector3(0.62, 1.05, 0.62))
			lm.box("Stone", cp + Vector3(0.0, 1.02, 0.0), Vector3(0.70, 0.14, 0.70))
			lm.frustum("Iron", cp + Vector3(0.0, 1.08, 0.0), 0.12, 0.07, 1.85, 6)
			lm.lathe("BridgeLamp", cp + Vector3(0.0, 2.90, 0.0), PackedVector2Array([
				Vector2(0.08, 0.0), Vector2(0.22, 0.18), Vector2(0.20, 0.36), Vector2(0.04, 0.46)]), 6)
