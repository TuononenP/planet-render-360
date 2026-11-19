class_name PlazaLife
extends RefCounted

## Data-driven public square furnishings across all cities (Balanced/High/Ultra):
## * Open-air markets (`amenity=marketplace` areas/POIs & named market squares)
## * Outdoor café terraces (`leisure=outdoor_seating` areas & ground-floor POIs)
## * Non-landmark fountains (`amenity=fountain` basins & free-standing nodes)
## * Raised planters (`man_made=planter` polygons, with bench slats when tagged)
## Built via pure coordinate hashes into one merged Node3D ("PlazaLife").

const MARKET_NAMES := [
	"kauppatori", "salutorget", "hakaniementori", "hietalahdentori",
	"tammelantori", "kauppahallintori", "hötorget", "stortorget",
	"marktplatz", "viktualienmarkt", "naschmarkt", "hackescher markt",
	"marché ", "marche ", "mercato ", "market square",
	"farmers market", "winter village", "stall market",
]
const MAX_STALLS_PER_SQ := 36
const MAX_STALLS_TOTAL := 140
const MAX_TABLES_TOTAL := 160
const MAX_FOUNTAINS := 40
const TURKU_CLEAR_M := 90.0

static func build(root: Node3D, data: LocationData, ground: GroundTruth,
		mask: VegetationMask, ctx: Dictionary) -> int:
	var preset := int(ctx.get("preset", 0))
	if preset < RenderSettings.Preset.BALANCED or data.buildings.is_empty():
		return 0
	var m2u: float = ctx.get("m2u", WorldScale.metres_to_units())
	var radius_m := 600.0 if preset >= RenderSettings.Preset.ULTRA else 260.0
	var radius_u := radius_m * m2u
	var centre := View360.spawn_xz(data)
	var ex := _exclusions(data, m2u)

	var pal := _palette(data)
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr(str(pal["stone_set"]), str(pal["stone_hex"]), 2.4, 0.78))
	lm.use("Wood", LandmarkMaterials.pbr("wood", str(pal["wood_hex"]), 2.0, 0.68))
	lm.use("Metal", LandmarkMaterials.paint("#2B2F34", 0.48, 0.45))
	lm.use("CanvasAccent", LandmarkMaterials.pbr("render", str(pal["accent"]), 2.0, 0.85))
	lm.use("CanvasSecondary", LandmarkMaterials.pbr("render", str(pal["secondary"]), 2.0, 0.85))
	lm.use("CanvasCream", LandmarkMaterials.pbr("render", str(pal["cream"]), 2.0, 0.85))
	lm.use("Foliage", LandmarkMaterials.pbr("lawn", "#486B3A", 1.5, 0.88))
	lm.use("Produce", LandmarkMaterials.pbr("render", "#C88B2E", 1.2, 0.78))
	lm.use("Water", LandmarkMaterials.pool_water("#2A606E", 0.08))
	lm.use("Spray", LandmarkMaterials.lit("#E6F5FF", 0.35))

	var occupied := {}
	var count := 0
	var f_ctx := {"data": data, "ground": ground, "mask": mask, "ex": ex,
		"centre": centre, "radius_u": radius_u, "m2u": m2u, "occ": occupied, "pal": pal}
	count += _build_fountains(lm, f_ctx)
	count += _build_planters(lm, f_ctx)
	count += _build_markets(lm, f_ctx)
	count += _build_terraces(lm, f_ctx)

	if count <= 0:
		return 0
	var node := Node3D.new()
	node.name = "PlazaLife"
	lm.commit(node)
	if node.get_child_count() == 0:
		node.free()
		return 0
	root.add_child(node)
	return count

## --- Regional palettes & site exclusions -------------------------------

static func _palette(data: LocationData) -> Dictionary:
	var iso := data.country.to_upper()
	if iso in ["FI", "SE", "NO", "DK", "IS", "EE"]:
		return {"accent": "#C85A38", "secondary": "#2E5473", "cream": "#EAE3D2",
			"stone_set": "pavement", "stone_hex": "#6A6D72", "wood_hex": "#BA8A58"}
	if iso in ["IT", "ES", "PT", "GR", "MC", "FR", "HR", "MT"]:
		return {"accent": "#B84B39", "secondary": "#4D6B4A", "cream": "#EFE6D2",
			"stone_set": "limestone", "stone_hex": "#C9BFA9", "wood_hex": "#9E6E44"}
	if iso in ["JP", "KR", "TW", "CN"]:
		return {"accent": "#2D4262", "secondary": "#8C3B32", "cream": "#EFECE4",
			"stone_set": "pavement", "stone_hex": "#8C8E92", "wood_hex": "#A97648"}
	return {"accent": "#7D2E38", "secondary": "#2E523E", "cream": "#EDE8DC",
		"stone_set": "limestone", "stone_hex": "#9B958B", "wood_hex": "#A07248"}

static func _exclusions(data: LocationData, m2u: float) -> Dictionary:
	var reg := []
	var kauppatori := Vector2.INF
	if data.landmark_type != "none":
		var pe := LocationData.entry_for_type(data.landmark_type)
		var pa := TerrainBuilder.landmark_site_xz(data)
		reg.append([pa, pe])
		if data.landmark_type == "turku_kauppatori":
			kauppatori = pa
	for c in data.landmark_candidates:
		if not (c is Dictionary):
			continue
		var cd: Dictionary = c
		if bool(cd.get("registry", false)):
			var at := Vector2(float(cd.get("x", 0.0)), float(cd.get("z", 0.0)))
			reg.append([at, cd])
			if str(cd.get("type", "")) == "turku_kauppatori":
				kauppatori = at
	var ped_areas := []
	var ped_ways := []
	for r in data.roads:
		if not (r is Dictionary):
			continue
		var rd: Dictionary = r
		if bool(rd.get("tunnel", false)) or bool(rd.get("bridge", false)):
			continue
		var pts: PackedVector2Array = rd.get("points", PackedVector2Array())
		var cls := str(rd.get("class", ""))
		if bool(rd.get("area", false)) and cls == "pedestrian" and pts.size() >= 3:
			ped_areas.append([pts, RingGeometry.aabb(pts), rd.get("holes", [])])
		elif not bool(rd.get("area", false)) and cls in ["pedestrian", "footway"] and pts.size() >= 2:
			ped_ways.append(pts)
	return {"models": LandmarkSites.model_rect_sites(data), "reg": reg,
		"kauppatori": kauppatori, "ped_areas": ped_areas, "ped_ways": ped_ways,
		"kauppatori_r": TURKU_CLEAR_M * m2u}

static func _excluded(p: Vector2, ex: Dictionary, include_fountain_reg: bool = false,
		ring: PackedVector2Array = PackedVector2Array()) -> bool:
	var kaup: Vector2 = ex["kauppatori"]
	if kaup != Vector2.INF and p.distance_to(kaup) < float(ex["kauppatori_r"]):
		return true
	if LandmarkSites.in_model_rects(p, ex["models"]):
		return true
	for v in ring:
		if LandmarkSites.in_model_rects(v, ex["models"]):
			return true
	if include_fountain_reg:
		for s: Array in ex["reg"]:
			var e: Dictionary = s[1]
			var clr := LandmarkSites.clear_m(e)
			if str(e.get("kind", "")) == "Fountain" or str(e.get("archetype", "")) == "Fountain":
				clr = maxf(clr, 16.0)
			if LandmarkSites.span_dist(p, s[0], e) < clr:
				return true
			for v in ring:
				if LandmarkSites.span_dist(v, s[0], e) < clr:
					return true
	return false

static func _near_spot(occ: Dictionary, p: Vector2, min_dist: float) -> bool:
	var cell := maxf(min_dist, 2.0)
	var ci := Vector2i(floori(p.x / cell), floori(p.y / cell))
	var d2 := min_dist * min_dist
	for dz in range(-1, 2):
		for dx in range(-1, 2):
			for q: Vector2 in occ.get(ci + Vector2i(dx, dz), []):
				if q.distance_squared_to(p) < d2:
					return true
	return false

static func _mark_spot(occ: Dictionary, p: Vector2, cell_size: float) -> void:
	var cell := maxf(cell_size, 2.0)
	var ci := Vector2i(floori(p.x / cell), floori(p.y / cell))
	if not occ.has(ci):
		occ[ci] = []
	(occ[ci] as Array).append(p)

static func _hash(x: float, z: float, salt: float) -> float:
	var v := sin(x * 12.9898 + z * 78.233 + salt * 37.719) * 43758.5453
	return v - floorf(v)

static func _median_float(arr: Array[float], fallback: float) -> float:
	if arr.is_empty():
		return fallback
	arr.sort()
	return arr[arr.size() / 2]

## --- A. Architectural Plaza Fountains ----------------------------------

static func _build_fountains(lm: LandmarkMesh, ctx: Dictionary) -> int:
	var data: LocationData = ctx["data"]
	var ground: GroundTruth = ctx["ground"]
	var mask: VegetationMask = ctx["mask"]
	var m2u: float = ctx["m2u"]
	var centre: Vector2 = ctx["centre"]
	var radius_u: float = ctx["radius_u"]
	var ex: Dictionary = ctx["ex"]
	var winter := data.season == LocationData.Season.WINTER
	var count := 0
	var poly_centres := PackedVector2Array()

	for poly in data.land_polygons:
		if count >= MAX_FOUNTAINS or not (poly is Dictionary):
			break
		var pd: Dictionary = poly
		if not bool(pd.get("fountain", false)):
			continue
		var pts: PackedVector2Array = pd.get("points", PackedVector2Array())
		if pts.size() < 3:
			continue
		var area := absf(RingGeometry.signed_area(pts))
		if area < 3.0 * m2u * m2u or area > 2500.0 * m2u * m2u:
			continue
		var c := RingGeometry.centroid(pts)
		if (c - centre).length() > radius_u or not ground.is_inside(c.x, c.y):
			continue
		if mask.blocked(c.x, c.y, VegetationMask.BUILDING | VegetationMask.ROAD, 0.5 * m2u):
			continue
		if _excluded(c, ex, true, pts):
			continue
		_emit_fountain_poly(lm, pts, pd.get("holes", []), c, area, ground, winter, m2u)
		poly_centres.append(c)
		_mark_spot(ctx["occ"], c, 5.0 * m2u)
		count += 1

	for poi in data.pois:
		if count >= MAX_FOUNTAINS or not (poi is Dictionary):
			break
		var p: Dictionary = poi
		if str(p.get("kind", "")) != "fountain" or bool(p.get("indoor", false)) or bool(p.get("wall_mounted", false)):
			continue
		var at := Vector2(float(p.get("x", 0.0)), float(p.get("z", 0.0)))
		if (at - centre).length() > radius_u or not ground.is_inside(at.x, at.y):
			continue
		if mask.blocked(at.x, at.y, VegetationMask.BUILDING | VegetationMask.ROAD | VegetationMask.WATER | VegetationMask.TREE, 1.8 * m2u):
			continue
		if _excluded(at, ex, true):
			continue
		var skip := false
		for pc in poly_centres:
			if pc.distance_to(at) < 12.0 * m2u:
				skip = true
				break
		if skip:
			continue
		var ring := _octagon(at, 1.5 * m2u)
		_emit_fountain_poly(lm, ring, [], at, PI * 1.5 * 1.5 * m2u * m2u, ground, winter, m2u)
		poly_centres.append(at)
		_mark_spot(ctx["occ"], at, 4.0 * m2u)
		count += 1
	return count

static func _emit_fountain_poly(lm: LandmarkMesh, pts: PackedVector2Array, holes: Array,
		c: Vector2, area: float, ground: GroundTruth, winter: bool, m2u: float) -> void:
	var cw := RingGeometry.signed_area(pts) > 0.0
	var rim_ys: Array[float] = []
	for p in pts:
		var out := (p - c).normalized() * 0.8 * m2u
		var q := p + out
		if ground.is_inside(q.x, q.y):
			rim_ys.append(ground.dry_height_at_world(q.x, q.y))
	var rim_y := _median_float(rim_ys, ground.dry_height_at_world(c.x, c.y))
	var bot_y := rim_y - 0.55 * m2u
	var top_y := rim_y + 0.48 * m2u
	var wat_y := rim_y + 0.36 * m2u
	var thick := 0.38 * m2u
	var n := pts.size()
	for i in n:
		var a := pts[i]
		var b := pts[(i + 1) % n]
		var e := b - a
		if e.length() < 0.05 * m2u:
			continue
		var out2 := (Vector2(e.y, -e.x) if cw else Vector2(-e.y, e.x)).normalized() * thick
		var out3 := Vector3(out2.x, 0.0, out2.y).normalized()
		var a2 := a + out2
		var b2 := b + out2
		lm.quad("Stone", Vector3(a2.x, bot_y, a2.y), Vector3(b2.x, bot_y, b2.y),
			Vector3(b2.x, top_y, b2.y), Vector3(a2.x, top_y, a2.y), out3)
		lm.quad("Stone", Vector3(b.x, wat_y - 0.1 * m2u, b.y), Vector3(a.x, wat_y - 0.1 * m2u, a.y),
			Vector3(a.x, top_y, a.y), Vector3(b.x, top_y, b.y), -out3)
		lm.quad("Stone", Vector3(a.x, top_y, a.y), Vector3(a2.x, top_y, a2.y),
			Vector3(b2.x, top_y, b2.y), Vector3(b.x, top_y, b.y), Vector3.UP)
	_tri_surface(lm, "Water", pts, holes, wat_y)

	var in_hole := false
	for h in holes:
		if h is PackedVector2Array and RingGeometry.point_in_ring(c, h):
			in_hole = true
			break
	if not in_hole and RingGeometry.point_in_ring(c, pts):
		var scale := clampf(sqrt(area / PI) / m2u * 0.18, 0.42, 1.55) * m2u
		var stem_h := 1.05 * scale
		lm.lathe("Stone", Vector3(c.x, wat_y - 0.1 * m2u, c.y), PackedVector2Array([
			Vector2(0.75 * scale, 0.0), Vector2(0.45 * scale, 0.25 * scale),
			Vector2(0.30 * scale, stem_h * 0.7), Vector2(0.95 * scale, stem_h),
			Vector2(0.88 * scale, stem_h + 0.12 * scale), Vector2(0.18 * scale, stem_h + 0.28 * scale)]), 10)
		if not winter:
			var jet_base := Vector3(c.x, wat_y + stem_h + 0.25 * scale, c.y)
			var jet_h := clampf(1.25 * scale, 0.9 * m2u, 2.8 * m2u)
			lm.frustum("Spray", jet_base, 0.12 * scale, 0.03 * scale, jet_h, 6)
			for k in 5:
				var a := TAU * float(k) / 5.0
				var p_top := jet_base + Vector3(cos(a) * 0.42 * scale, jet_h * 0.65, sin(a) * 0.42 * scale)
				lm.beam("Spray", jet_base, p_top, 0.06 * scale, 0.06 * scale)

## --- B. Raised Stone & Timber Planters ---------------------------------

static func _build_planters(lm: LandmarkMesh, ctx: Dictionary) -> int:
	var ground: GroundTruth = ctx["ground"]
	var mask: VegetationMask = ctx["mask"]
	var m2u: float = ctx["m2u"]
	var centre: Vector2 = ctx["centre"]
	var radius_u: float = ctx["radius_u"]
	var ex: Dictionary = ctx["ex"]
	var count := 0

	for poly in (ctx["data"] as LocationData).land_polygons:
		if not (poly is Dictionary):
			continue
		var pd: Dictionary = poly
		if not bool(pd.get("planter", false)):
			continue
		var pts: PackedVector2Array = pd.get("points", PackedVector2Array())
		if pts.size() < 3:
			continue
		var area := absf(RingGeometry.signed_area(pts))
		if area < 1.2 * m2u * m2u or area > 400.0 * m2u * m2u:
			continue
		var c := RingGeometry.centroid(pts)
		if (c - centre).length() > radius_u or not ground.is_inside(c.x, c.y):
			continue
		if mask.blocked(c.x, c.y, VegetationMask.BUILDING | VegetationMask.ROAD | VegetationMask.WATER, 0.4 * m2u):
			continue
		if _excluded(c, ex, false, pts):
			continue
		_emit_planter(lm, pts, pd.get("holes", []), bool(pd.get("bench", false)), c, ground, m2u)
		_mark_spot(ctx["occ"], c, 3.0 * m2u)
		count += 1
	return count

static func _emit_planter(lm: LandmarkMesh, pts: PackedVector2Array, holes: Array,
		has_bench: bool, c: Vector2, ground: GroundTruth, m2u: float) -> void:
	var ys: Array[float] = []
	for p in pts:
		if ground.is_inside(p.x, p.y):
			ys.append(ground.height_at_world(p.x, p.y))
	var gy := _median_float(ys, ground.height_at_world(c.x, c.y))
	var bot := gy - 0.45 * m2u
	var top := gy + 0.50 * m2u
	var cw := RingGeometry.signed_area(pts) > 0.0
	var n := pts.size()
	var best_edge_len := 0.0
	var bench_a := Vector2.ZERO
	var bench_b := Vector2.ZERO
	var bench_out := Vector2.ZERO
	for i in n:
		var a := pts[i]
		var b := pts[(i + 1) % n]
		var e := b - a
		var el := e.length()
		if el < 0.05 * m2u:
			continue
		var out2 := (Vector2(e.y, -e.x) if cw else Vector2(-e.y, e.x)).normalized()
		lm.quad("Stone", Vector3(a.x, bot, a.y), Vector3(b.x, bot, b.y),
			Vector3(b.x, top, b.y), Vector3(a.x, top, a.y), Vector3(out2.x, 0.0, out2.y))
		if has_bench and el > best_edge_len:
			best_edge_len = el
			bench_a = a
			bench_b = b
			bench_out = out2
	_tri_surface(lm, "Foliage", pts, holes, gy + 0.42 * m2u)
	if RingGeometry.point_in_ring(c, pts):
		lm.lathe("Foliage", Vector3(c.x, gy + 0.40 * m2u, c.y), PackedVector2Array([
			Vector2(0.05 * m2u, 0.0), Vector2(0.85 * m2u, 0.22 * m2u),
			Vector2(0.75 * m2u, 0.58 * m2u), Vector2(0.15 * m2u, 0.85 * m2u)]), 8)
	if has_bench and best_edge_len >= 1.6 * m2u:
		var mid := (bench_a + bench_b) * 0.5 + bench_out * 0.24 * m2u
		var dir := (bench_b - bench_a).normalized()
		var yaw := atan2(-dir.y, dir.x)
		lm.box("Wood", Vector3(mid.x, gy + 0.45 * m2u, mid.y),
			Vector3(maxf(best_edge_len - 0.5 * m2u, 1.0 * m2u), 0.08 * m2u, 0.44 * m2u),
			Basis(Vector3.UP, yaw), 0.0)

## --- C. Open-Air Market Stalls & Produce Tables ------------------------

static func _build_markets(lm: LandmarkMesh, ctx: Dictionary) -> int:
	var data: LocationData = ctx["data"]
	var ground: GroundTruth = ctx["ground"]
	var mask: VegetationMask = ctx["mask"]
	var m2u: float = ctx["m2u"]
	var centre: Vector2 = ctx["centre"]
	var radius_u: float = ctx["radius_u"]
	var ex: Dictionary = ctx["ex"]
	var total := 0
	var dressed_rings: Array = []

	for r in data.roads:
		if total >= MAX_STALLS_TOTAL or not (r is Dictionary):
			break
		var rd: Dictionary = r
		if not bool(rd.get("area", false)) or bool(rd.get("covered", false)) or bool(rd.get("tunnel", false)):
			continue
		var is_mkt := bool(rd.get("marketplace", false)) \
			or (str(rd.get("class", "")) == "pedestrian" and _is_market_square_name(str(rd.get("name", ""))))
		if not is_mkt:
			continue
		var pts: PackedVector2Array = rd.get("points", PackedVector2Array())
		if pts.size() < 3 or absf(RingGeometry.signed_area(pts)) < 90.0 * m2u * m2u:
			continue
		var box := RingGeometry.aabb(pts)
		if box.get_center().distance_to(centre) > radius_u + maxf(box.size.x, box.size.y) * 0.5:
			continue
		dressed_rings.append([pts, rd.get("holes", [])])
		total += _dress_market_poly(lm, pts, rd.get("holes", []), box, ctx, MAX_STALLS_TOTAL - total)

	for poi in data.pois:
		if total >= MAX_STALLS_TOTAL or not (poi is Dictionary):
			break
		var p: Dictionary = poi
		if str(p.get("kind", "")) != "marketplace" or bool(p.get("indoor", false)):
			continue
		var at := Vector2(float(p.get("x", 0.0)), float(p.get("z", 0.0)))
		if (at - centre).length() > radius_u or _excluded(at, ex, true):
			continue
		var already := false
		for dr: Array in dressed_rings:
			if RingGeometry.point_in_ring(at, dr[0]):
				already = true
				break
		if already or _near_spot(ctx["occ"], at, 6.0 * m2u):
			continue
		total += _dress_market_poi(lm, at, ctx, MAX_STALLS_TOTAL - total)
	return total

static func _is_market_square_name(raw: String) -> bool:
	if raw == "":
		return false
	var nm := raw.to_lower()
	for k in MARKET_NAMES:
		if nm.contains(k):
			return true
	return false

static func _dress_market_poly(lm: LandmarkMesh, pts: PackedVector2Array, holes: Array,
		box: Rect2, ctx: Dictionary, budget: int) -> int:
	var ground: GroundTruth = ctx["ground"]
	var mask: VegetationMask = ctx["mask"]
	var m2u: float = ctx["m2u"]
	var centre: Vector2 = ctx["centre"]
	var radius_u: float = ctx["radius_u"]
	var ex: Dictionary = ctx["ex"]
	var u := RingGeometry.dominant_axis(pts)
	var v := Vector2(-u.y, u.x)
	var u_min := INF
	var u_max := -INF
	var v_min := INF
	var v_max := -INF
	for p in pts:
		u_min = minf(u_min, p.dot(u))
		u_max = maxf(u_max, p.dot(u))
		v_min = minf(v_min, p.dot(v))
		v_max = maxf(v_max, p.dot(v))
	var yaw := atan2(-u.y, u.x)
	var step_u := 4.8 * m2u
	var placed := 0
	var row_i := 0
	var vv := v_min + 3.4 * m2u
	while vv <= v_max - 3.4 * m2u and placed < MAX_STALLS_PER_SQ and placed < budget:
		var uu := u_min + 3.4 * m2u
		while uu <= u_max - 3.4 * m2u and placed < MAX_STALLS_PER_SQ and placed < budget:
			var pos := u * uu + v * vv
			uu += step_u
			if not box.has_point(pos) or (pos - centre).length() > radius_u:
				continue
			if not _stall_inside(pos, u, v, pts, holes, 2.2 * m2u):
				continue
			if _hash(pos.x, pos.y, 13.0) < 0.14:
				continue
			if not ground.is_inside(pos.x, pos.y) or ground.water_at(pos.x, pos.y) > 0.0:
				continue
			if mask.blocked(pos.x, pos.y, VegetationMask.BUILDING | VegetationMask.ROAD | VegetationMask.WATER | VegetationMask.TREE, 2.0 * m2u):
				continue
			if _excluded(pos, ex, true) or _near_spot(ctx["occ"], pos, 3.6 * m2u):
				continue
			var scheme := (row_i + int(absf(floorf(uu / step_u)))) % 3
			_emit_stall(lm, pos, ground.height_at_world(pos.x, pos.y), yaw, scheme, m2u)
			_mark_spot(ctx["occ"], pos, 4.0 * m2u)
			placed += 1
		row_i += 1
		vv += (6.2 if row_i % 2 == 0 else 4.2) * m2u
	return placed

static func _dress_market_poi(lm: LandmarkMesh, at: Vector2, ctx: Dictionary, budget: int) -> int:
	var ground: GroundTruth = ctx["ground"]
	var mask: VegetationMask = ctx["mask"]
	var m2u: float = ctx["m2u"]
	var ex: Dictionary = ctx["ex"]
	var in_ped := _in_ped_areas(at, ex["ped_areas"])
	var placed := 0
	for ix in [-1, 0, 1]:
		for iz in [-1, 0]:
			if placed >= budget:
				break
			var pos := at + Vector2(float(ix) * 4.2 * m2u, float(iz) * 4.4 * m2u)
			if not ground.is_inside(pos.x, pos.y) or ground.water_at(pos.x, pos.y) > 0.0:
				continue
			if not in_ped and mask.cover_at(pos.x, pos.y) >= 0:
				continue
			if mask.blocked(pos.x, pos.y, VegetationMask.BUILDING | VegetationMask.ROAD | VegetationMask.WATER | VegetationMask.TREE, 2.0 * m2u):
				continue
			if _excluded(pos, ex, true) or _near_spot(ctx["occ"], pos, 3.6 * m2u):
				continue
			_emit_stall(lm, pos, ground.height_at_world(pos.x, pos.y), 0.0, (ix + iz + 4) % 3, m2u)
			_mark_spot(ctx["occ"], pos, 4.0 * m2u)
			placed += 1
	return placed

static func _stall_inside(p: Vector2, u: Vector2, v: Vector2, pts: PackedVector2Array,
		holes: Array, margin: float) -> bool:
	var checks := [p, p + u * margin, p - u * margin, p + v * margin, p - v * margin]
	for q in checks:
		if not RingGeometry.point_in_ring(q, pts):
			return false
		for h in holes:
			if h is PackedVector2Array and RingGeometry.point_in_ring(q, h):
				return false
	return true

static func _emit_stall(lm: LandmarkMesh, p: Vector2, gy: float, yaw: float,
		scheme: int, m2u: float) -> void:
	var b := Basis(Vector3.UP, yaw)
	var hw := 1.45 * m2u
	var hd := 1.35 * m2u
	var eave := gy + 2.15 * m2u
	for sx: float in [-hw, hw]:
		for sz: float in [-hd, hd]:
			var post := Vector3(p.x, gy, p.y) + b * Vector3(sx, 0.0, sz)
			lm.beam("Metal", post, post + Vector3(0.0, 2.15 * m2u, 0.0), 0.05 * m2u, 0.05 * m2u)
	var ckey := "CanvasCream" if scheme == 0 else ("CanvasAccent" if scheme == 1 else "CanvasSecondary")
	lm.gable(ckey, Vector3(p.x, eave, p.y), hw * 2.0, hd * 2.0, 0.62 * m2u, b, 0.16 * m2u, ckey)
	lm.box("Wood", Vector3(p.x, gy + 0.41 * m2u, p.y),
		Vector3(2.25 * m2u, 0.82 * m2u, 0.88 * m2u), b, 0.0)
	var goods := "Foliage" if int(absf(p.x + p.y)) % 3 == 0 else "Produce"
	for kx in [-0.7, 0.0, 0.7]:
		lm.box(goods, Vector3(p.x, gy + 0.92 * m2u, p.y) + b * Vector3(kx * m2u, 0.0, 0.0),
			Vector3(0.55 * m2u, 0.20 * m2u, 0.62 * m2u), b, 0.0)

## --- D. Outdoor Café Terraces ------------------------------------------

static func _build_terraces(lm: LandmarkMesh, ctx: Dictionary) -> int:
	var data: LocationData = ctx["data"]
	var ground: GroundTruth = ctx["ground"]
	var mask: VegetationMask = ctx["mask"]
	var m2u: float = ctx["m2u"]
	var centre: Vector2 = ctx["centre"]
	var radius_u: float = ctx["radius_u"]
	var ex: Dictionary = ctx["ex"]
	var winter := data.season == LocationData.Season.WINTER
	var tables := 0

	for r in data.roads:
		if tables >= MAX_TABLES_TOTAL or not (r is Dictionary):
			break
		var rd: Dictionary = r
		if not bool(rd.get("area", false)) or not bool(rd.get("outdoor_seating", false)):
			continue
		var pts: PackedVector2Array = rd.get("points", PackedVector2Array())
		if pts.size() < 3:
			continue
		var box := RingGeometry.aabb(pts)
		if box.get_center().distance_to(centre) > radius_u + maxf(box.size.x, box.size.y) * 0.5:
			continue
		tables += _dress_terrace_poly(lm, pts, rd.get("holes", []), box,
			not winter and not bool(rd.get("covered", false)), winter, ctx, MAX_TABLES_TOTAL - tables)

	for poi in data.pois:
		if tables >= MAX_TABLES_TOTAL or not (poi is Dictionary):
			break
		var p: Dictionary = poi
		if not bool(p.get("outdoor_seating", false)):
			continue
		var at := Vector2(float(p.get("x", 0.0)), float(p.get("z", 0.0)))
		if (at - centre).length() > radius_u or _excluded(at, ex, true):
			continue
		tables += _dress_poi_terrace(lm, at, winter, ctx, MAX_TABLES_TOTAL - tables)
	return tables

static func _dress_terrace_poly(lm: LandmarkMesh, pts: PackedVector2Array, holes: Array,
		box: Rect2, allow_parasol: bool, winter: bool, ctx: Dictionary, budget: int) -> int:
	var ground: GroundTruth = ctx["ground"]
	var mask: VegetationMask = ctx["mask"]
	var m2u: float = ctx["m2u"]
	var centre: Vector2 = ctx["centre"]
	var radius_u: float = ctx["radius_u"]
	var ex: Dictionary = ctx["ex"]
	var u := RingGeometry.dominant_axis(pts)
	var v := Vector2(-u.y, u.x)
	var u_min := INF
	var u_max := -INF
	var v_min := INF
	var v_max := -INF
	for p in pts:
		u_min = minf(u_min, p.dot(u))
		u_max = maxf(u_max, p.dot(u))
		v_min = minf(v_min, p.dot(v))
		v_max = maxf(v_max, p.dot(v))
	var step := (4.8 if winter else 3.0) * m2u
	var placed := 0
	var vv := v_min + 1.4 * m2u
	while vv <= v_max - 1.4 * m2u and placed < 16 and placed < budget:
		var uu := u_min + 1.4 * m2u
		while uu <= u_max - 1.4 * m2u and placed < 16 and placed < budget:
			var pos := u * uu + v * vv
			uu += step
			if not box.has_point(pos) or (pos - centre).length() > radius_u:
				continue
			if not _stall_inside(pos, u, v, pts, holes, 0.9 * m2u):
				continue
			if not ground.is_inside(pos.x, pos.y) or ground.water_at(pos.x, pos.y) > 0.0:
				continue
			if mask.blocked(pos.x, pos.y, VegetationMask.BUILDING | VegetationMask.ROAD | VegetationMask.WATER | VegetationMask.TREE, 1.3 * m2u):
				continue
			if _excluded(pos, ex, true) or _near_spot(ctx["occ"], pos, 2.4 * m2u):
				continue
			var par := allow_parasol and _hash(pos.x, pos.y, 7.0) < 0.68
			_emit_bistro_table(lm, pos, ground.height_at_world(pos.x, pos.y), par,
				int(floorf(_hash(pos.x, pos.y, 19.0) * 3.0)), m2u)
			_mark_spot(ctx["occ"], pos, 2.6 * m2u)
			placed += 1
		vv += step
	return placed

static func _dress_poi_terrace(lm: LandmarkMesh, at: Vector2, winter: bool,
		ctx: Dictionary, budget: int) -> int:
	var ground: GroundTruth = ctx["ground"]
	var mask: VegetationMask = ctx["mask"]
	var m2u: float = ctx["m2u"]
	var ex: Dictionary = ctx["ex"]
	var ang0 := _hash(at.x, at.y, 3.0) * TAU
	var best := Vector2.INF
	var best_score := -1
	var best_dir := Vector2(1, 0)
	for dist_m: float in [5.5, 8.0, 4.0]:
		for k in 8:
			var d := Vector2.from_angle(ang0 + TAU * float(k) / 8.0)
			var c := at + d * dist_m * m2u
			if not ground.is_inside(c.x, c.y) or ground.water_at(c.x, c.y) > 0.0:
				continue
			if mask.blocked(c.x, c.y, VegetationMask.BUILDING | VegetationMask.ROAD | VegetationMask.WATER | VegetationMask.TREE, 1.8 * m2u):
				continue
			if mask.cover_at(c.x, c.y) >= 0 or _excluded(c, ex, true) or _near_spot(ctx["occ"], c, 3.0 * m2u):
				continue
			var sc := 0
			if _in_ped_areas(c, ex["ped_areas"]):
				sc = 3
			elif _near_ped_way(c, ex["ped_ways"], 4.5 * m2u):
				sc = 2
			elif ground.land_class_at(c.x, c.y) == "urban" and mask.blocked(c.x, c.y, VegetationMask.BUILDING, 9.0 * m2u):
				sc = 1
			if sc > best_score:
				best_score = sc
				best = c
				best_dir = d
	if best_score < 1 or best == Vector2.INF:
		return 0
	var perp := Vector2(-best_dir.y, best_dir.x)
	var offsets := [0.0] if winter else [-2.5 * m2u, 0.0, 2.5 * m2u]
	var placed := 0
	for off in offsets:
		if placed >= budget:
			break
		var pos := best + perp * float(off)
		if not ground.is_inside(pos.x, pos.y) or ground.water_at(pos.x, pos.y) > 0.0:
			continue
		if mask.blocked(pos.x, pos.y, VegetationMask.BUILDING | VegetationMask.ROAD | VegetationMask.WATER | VegetationMask.TREE, 1.4 * m2u):
			continue
		if mask.cover_at(pos.x, pos.y) >= 0 or _excluded(pos, ex, true) or _near_spot(ctx["occ"], pos, 2.2 * m2u):
			continue
		var par := not winter and _hash(pos.x, pos.y, 11.0) < 0.72
		_emit_bistro_table(lm, pos, ground.height_at_world(pos.x, pos.y), par,
			int(floorf(_hash(at.x, at.y, 29.0) * 3.0)), m2u)
		_mark_spot(ctx["occ"], pos, 2.5 * m2u)
		placed += 1
	return placed

static func _emit_bistro_table(lm: LandmarkMesh, p: Vector2, gy: float, parasol: bool,
		scheme: int, m2u: float) -> void:
	lm.frustum("Metal", Vector3(p.x, gy, p.y), 0.04 * m2u, 0.035 * m2u, 0.72 * m2u, 6)
	lm.frustum("Wood", Vector3(p.x, gy + 0.72 * m2u, p.y), 0.42 * m2u, 0.42 * m2u, 0.05 * m2u, 8)
	for side: float in [-0.60 * m2u, 0.60 * m2u]:
		lm.box("Wood", Vector3(p.x + side, gy + 0.42 * m2u, p.y), Vector3(0.36, 0.06, 0.36) * m2u, Basis(), 0.0)
		lm.box("Metal", Vector3(p.x + side, gy + 0.21 * m2u, p.y), Vector3(0.32, 0.42, 0.32) * m2u, Basis(), 0.0)
	if parasol:
		var ckey := "CanvasCream" if scheme == 0 else ("CanvasAccent" if scheme == 1 else "CanvasSecondary")
		lm.frustum("Metal", Vector3(p.x, gy + 0.76 * m2u, p.y), 0.025 * m2u, 0.025 * m2u, 1.60 * m2u, 6)
		lm.lathe(ckey, Vector3(p.x, gy + 2.15 * m2u, p.y), PackedVector2Array([
			Vector2(1.15 * m2u, 0.0), Vector2(0.02 * m2u, 0.42 * m2u)]), 8)

## --- Geometry helpers --------------------------------------------------

static func _in_ped_areas(p: Vector2, ped_areas: Array) -> bool:
	for sq: Array in ped_areas:
		if not (sq[1] as Rect2).has_point(p) or not RingGeometry.point_in_ring(p, sq[0]):
			continue
		var in_h := false
		for h in sq[2]:
			if h is PackedVector2Array and RingGeometry.point_in_ring(p, h):
				in_h = true
				break
		if not in_h:
			return true
	return false

static func _near_ped_way(p: Vector2, ped_ways: Array, reach: float) -> bool:
	for pts: PackedVector2Array in ped_ways:
		for i in pts.size() - 1:
			if Geometry2D.get_closest_point_to_segment(p, pts[i], pts[i + 1]).distance_to(p) <= reach:
				return true
	return false

static func _octagon(c: Vector2, r: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in 8:
		var a := TAU * float(i) / 8.0
		out.append(c + Vector2(cos(a), sin(a)) * r)
	return out

static func _tri_surface(lm: LandmarkMesh, key: String, pts: PackedVector2Array,
		holes: Array, y: float) -> void:
	var idx := Geometry2D.triangulate_polygon(pts)
	for t in range(0, idx.size(), 3):
		var a := pts[idx[t]]
		var b := pts[idx[t + 1]]
		var c := pts[idx[t + 2]]
		var mid := (a + b + c) / 3.0
		var in_h := false
		for h in holes:
			if h is PackedVector2Array and RingGeometry.point_in_ring(mid, h):
				in_h = true
				break
		if not in_h:
			lm.tri(key, Vector3(a.x, y, a.y), Vector3(b.x, y, b.y), Vector3(c.x, y, c.y),
				Vector3.UP, Vector3.UP, Vector3.UP, a, b, c)
