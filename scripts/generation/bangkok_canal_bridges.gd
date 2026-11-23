class_name BangkokCanalBridges
extends RefCounted

## Historic Rattanakosin khlong bridges (`BK-6.3`): Phan Fa Lilat, Makkhawan Rangsan,
## Chaloem Wan Chat, Pi Kun, Saphan Hok, Chang Rongsi, Ubon Rat, Phanuphan, Saphan Han,
## and Wisukam Narumeman.
## Styled on generic OSM `bridge=yes` road/footway ways crossing inland canals in Bangkok's
## old-town districts WITHOUT adding capital-bridge rows (preserving all 4 Chao Phraya river
## bridge slots): white moulded marble/stucco balustrades along both edges and 4 ornate
## bronze corner pedestals with glowing globe lamps.

const DISTRICTS := [
	"bangkok_oldtown", "bangkok_civic", "bangkok_ratchadamnoen",
	"bangkok_khaosan", "bangkok_shophouse", "bangkok_yaowarat",
]

static func applies(data: LocationData) -> bool:
	return data != null and CityStyles.city_of_region(CityStyles.region_at(data.latitude, data.longitude)) == "bangkok"

static func build(root: Node3D, data: LocationData, ground: GroundTruth, surf: RoadBuilder._Surface, m2u: float) -> int:
	if not applies(data) or ground == null:
		return 0
	var lm := LandmarkMesh.new()
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#F3EFE4", 3.0))
	lm.use("Bronze", LandmarkMaterials.pbr("copper", "#4B4234", 2.0, 0.42, 0.72))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.use("BridgeLamp", LandmarkMaterials.lit("#FFE6AA", 1.8))

	var count := 0
	var placed_centres: Array[Vector2] = []
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
		if span_m < 6.0 or span_m > 68.0:
			continue
		var mid := pts[pts.size() / 2]
		if pts.size() % 2 == 0:
			mid = (pts[pts.size() / 2 - 1] + pts[pts.size() / 2]) * 0.5
		if not _over_canal(pts, ground) or not _in_oldtown(mid / m2u, surf.districts):
			continue
		var dup := false
		for pc in placed_centres:
			if pc.distance_to(mid) < 9.0 * m2u:
				dup = true
				break
		if dup:
			continue
		placed_centres.append(mid)
		_ornament_bridge(lm, pts, maxf(float(d.get("width_m", 8.0)), 4.5), surf, m2u)
		count += 1

	if count > 0:
		var holder := Node3D.new()
		holder.name = "BangkokCanalBridges"
		lm.commit(holder)
		holder.scale = Vector3.ONE * m2u
		root.add_child(holder)
	return count

static func _over_canal(pts: PackedVector2Array, ground: GroundTruth) -> bool:
	for t in [0.25, 0.5, 0.75]:
		var idx := clampi(int(t * float(pts.size() - 1)), 0, pts.size() - 1)
		var p := pts[idx]
		if ground.water_at(p.x, p.y) > 0.15:
			return true
	var p_mid := pts[0].lerp(pts[pts.size() - 1], 0.5)
	return ground.water_at(p_mid.x, p_mid.y) > 0.15

static func _in_oldtown(mid_m: Vector2, districts: Array) -> bool:
	for dist in districts:
		if str(dist[0]) in DISTRICTS and mid_m.distance_to(dist[1] as Vector2) <= float(dist[2]):
			return true
	return false

static func _ornament_bridge(lm: LandmarkMesh, pts: PackedVector2Array, width_m: float,
		surf: RoadBuilder._Surface, m2u: float) -> void:
	var deck := RoadBridgeBuild.deck_profile(pts, surf, m2u, width_m * 0.5 * m2u, 0)
	if deck.size() != pts.size():
		return
	var half_m := width_m * 0.5 + 0.08
	# White marble balustrade coping & moulded balusters along both bridge parapets
	for sgn in [-1.0, 1.0]:
		var s := float(sgn)
		for i in pts.size() - 1:
			var sa := RoadBuilder._side(pts, i) * half_m * s
			var sb := RoadBuilder._side(pts, i + 1) * half_m * s
			var a := Vector3(pts[i].x / m2u + sa.x, deck[i] / m2u, pts[i].y / m2u + sa.y)
			var b := Vector3(pts[i + 1].x / m2u + sb.x, deck[i + 1] / m2u, pts[i + 1].y / m2u + sb.y)
			var seg_l := a.distance_to(b)
			if seg_l < 0.3:
				continue
			lm.beam("Marble", a + Vector3(0, 0.18, 0), b + Vector3(0, 0.18, 0), 0.38, 0.36)
			lm.beam("Marble", a + Vector3(0, 1.08, 0), b + Vector3(0, 1.08, 0), 0.42, 0.22)
			var nb := maxi(int(seg_l / 0.85), 1)
			for k in nb:
				var bp := a.lerp(b, (float(k) + 0.5) / float(nb))
				lm.box("Marble", bp + Vector3(0, 0.64, 0), Vector3(0.20, 0.66, 0.20), Basis(), 0.0)

		# Corner marble end-piers & ornate bronze globe lamp standards at the 4 corners!
		for end_i in [0, pts.size() - 1]:
			var se := RoadBuilder._side(pts, end_i) * (half_m + 0.06) * s
			var cp := Vector3(pts[end_i].x / m2u + se.x, deck[end_i] / m2u, pts[end_i].y / m2u + se.y)
			lm.box("Marble", cp + Vector3(0, 0.72, 0), Vector3(0.76, 1.44, 0.76))
			lm.box("Gold", cp + Vector3(0, 1.48, 0), Vector3(0.84, 0.12, 0.84))
			lm.frustum("Bronze", cp + Vector3(0, 1.54, 0), 0.18, 0.09, 2.05, 8)
			lm.lathe("BridgeLamp", cp + Vector3(0, 3.55, 0), PackedVector2Array([
				Vector2(0.08, 0.0), Vector2(0.24, 0.18), Vector2(0.22, 0.38), Vector2(0.04, 0.50)]), 8)
