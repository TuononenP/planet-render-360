class_name FarCityBuilder
extends RefCounted

## T5.4 + T7.3 — the city past the detailed extent, from real data.
## Replaces the v1 random silhouette ring. Every SettlementMap cell
## from R_IN to SettlementMap.RADIUS_M that real evidence calls built
## (far imagery drape texture/colour + OSM built-up landuse) gets
## low-poly textured masses:
##  - density thins with the settlement score and with distance
##    (THIN_FAR at the map edge) — haze (AtmosphereRig) does the rest;
##  - near (< SPLIT_M) a cell splits into 2x2 street blocks, farther it
##    is one block mass; a low-score residential cell gets low houses;
##  - kind from the landuse class (industrial sheds, commercial,
##    apartment fabric), storeys / floor height / roof form from the
##    region's ArchitectureStyle profile, blended from the real
##    buildings' median height at the extent edge (no step at 1.2 km);
##  - none in blocked cells (parks, forest, rivers, sea), on steep
##    slopes (> MAX_SLOPE), under the far sea plane, or at landmarks;
##  - modern towers ONLY where OSM maps them: LocationData.far_towers
##    (real footprints and heights, glass curtain for offices).
## Materials are the shared distant facade/roof set (FacadeMaterials,
## ≤ 6 per region) plus the glass curtain, tiled per real bay/storey by
## BuildingBuilder._walls — textured fabric, never flat boxes. Geometry
## is batched (MassBatch) per octant x distance band x material, tagged
## lod_layer "FarCity" with meta far_r0 (band inner radius) so LodRing
## shows bands up to the preset's reach; positions never depend on the
## preset (AC-12).

const R_IN := 1230.0
const SPLIT_M := 3500.0
const BANDS: Array[float] = [1200.0, 2500.0, 4500.0, 7500.0, 12001.0]
const MIN_SCORE := 0.22
const THIN_FAR := 0.55
const MAX_SLOPE := 0.3
const STREET_M := 12.0
const LANDMARK_CLEAR_M := 120.0

static func _hash(x: float, z: float, salt: float = 0.0) -> float:
	return fposmod(sin(x * 12.9898 + z * 78.233 + salt * 37.719) * 43758.5453, 1.0)

static func build(root: Node3D, data: LocationData, ground: GroundTruth,
		smap: SettlementMap) -> void:
	var t0 := Time.get_ticks_msec()
	var stats := {"far_blocks": 0, "far_towers": 0}
	if (smap == null or smap.is_empty()) and data.far_towers.is_empty():
		BuildingBuilder.last_stats.merge(stats, true)
		return
	var b := FarCityBuilder.new()
	b._setup(data, ground, smap)
	b._towers()
	if smap != null and not smap.is_empty():
		b._fabric()
	var batch := b.batch
	stats = {"far_blocks": b.blocks, "far_towers": b.towers,
		"far_tris": batch.triangles}
	var n := batch.commit(root, "FarCity", func(key: String) -> Dictionary:
		return {"far_r0": BANDS[int(key.get_slice(",", 1))]})
	BuildingBuilder.last_stats.merge(stats, true)
	print("FAR-CITY built in %d ms (blocks=%d towers=%d tris=%d meshes=%d source=%s)" % [
		Time.get_ticks_msec() - t0, b.blocks, b.towers, stats["far_tris"], n,
		smap.source if smap != null else ""])

var data: LocationData
var ground: GroundTruth
var smap: SettlementMap
var batch := MassBatch.new()
var blocks := 0
var towers := 0
var _surf := {}
var _far_ok := false
var _sea := true
var _region := ""
var _dfs: Array = []
var _drs: Array = []
var _glass: Material
var _h_edge := -1.0
var _landmarks: Array[Vector2] = []
var _tower_cells := {}

func _setup(d: LocationData, g: GroundTruth, m: SettlementMap) -> void:
	data = d
	ground = g
	smap = m
	batch.meta = {"lod_layer": "FarCity"}
	batch.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_far_ok = d.far_grid_size >= 2 \
		and d.far_heights.size() == d.far_grid_size * d.far_grid_size
	if _far_ok:
		_surf = FarTerrainBuilder._surface(d)
	_sea = not is_equal_approx(g.water_level_m, -3.0)
	_region = ArchitectureStyle.region_for(d.latitude, d.longitude)
	var fidelity := MaterialLibrary.fidelity_for_preset(d.quality_preset)
	_dfs = FacadeMaterials.distant_facades(fidelity, _region)
	_drs = FacadeMaterials.distant_roofs(_region, fidelity)
	_glass = FacadeMaterials.glass_material(0 if fidelity <= 1 else 1)
	if d.landmark_type != "none":
		_landmarks.append(TerrainBuilder.landmark_world_pos(d))
	for c in d.landmark_candidates:
		_landmarks.append(Vector2(float(c.get("x", 0.0)), float(c.get("z", 0.0))))
	# Real buildings' median height in the outer extent band: the far
	# fabric starts at what the street actually is, then eases to the
	# regional profile with distance.
	var hs: Array = []
	for bd in d.buildings:
		if not (bd is Dictionary):
			continue
		var r := Vector2(float(bd.get("x", 0.0)), float(bd.get("z", 0.0))).length()
		if r >= 700.0 and str(bd.get("height_source", "")) in ["tag_height", "levels"]:
			hs.append(float(bd.get("height", 0.0)))
	if hs.size() >= 8:
		hs.sort()
		_h_edge = float(hs[hs.size() / 2])

## Ground render-Y at metre XZ: GroundTruth inside the extent, the far
## ring blend surface outside (what actually renders there).
func _ground_y(x: float, z: float) -> float:
	if ground.is_inside(x, z) or not _far_ok:
		return ground.height_at_world(x, z)
	return FarTerrainBuilder._blend_height(data, ground, _surf, x, z)

func _key(x: float, z: float) -> String:
	var r := Vector2(x, z).length()
	var band := 0
	while band < BANDS.size() - 2 and r >= BANDS[band + 1]:
		band += 1
	var oct := posmod(floori((atan2(z, x) + PI) / (TAU / 8.0)), 8)
	return "%d,%d" % [oct, band]

func _near_landmark(x: float, z: float) -> bool:
	for p in _landmarks:
		if p.distance_to(Vector2(x, z)) < LANDMARK_CLEAR_M:
			return true
	return false

## Lowest ground under the ring and its relief; INF base when the site
## is unbuildable (sea, water, steep).
func _site(ring: PackedVector2Array, span: float) -> float:
	var lo := INF
	var hi := -INF
	for p in ring:
		var h := _ground_y(p.x, p.y)
		lo = minf(lo, h)
		hi = maxf(hi, h)
	var c := RingGeometry.aabb(ring).get_center()
	if hi - lo > MAX_SLOPE * maxf(span, 10.0):
		return INF
	if ground.is_inside(c.x, c.y):
		if ground.water_at(c.x, c.y) > 0.0:
			return INF
	elif _sea and ground.asl_y(lo) < FarTerrainBuilder.SEA_LEVEL_M:
		return INF
	return lo - 2.0

func _towers() -> void:
	for t in data.far_towers:
		if not (t is Dictionary):
			continue
		var c := Vector2(float(t.get("x", 0.0)), float(t.get("z", 0.0)))
		if c.length() < R_IN or c.length() > SettlementMap.RADIUS_M:
			continue  # inside the extent the real building is already built
		var ring := BuildingBuilder._clean_ring(t.get("footprint", PackedVector2Array()))
		if ring.size() < 3 or _near_landmark(c.x, c.y):
			continue
		var idx := Geometry2D.triangulate_polygon(ring)
		if idx.size() < 3:
			continue
		var base := _site(ring, 1e6)
		if base == INF:
			continue
		var h := float(t.get("height", 0.0))
		var levels := int(t.get("levels", 0))
		var kind := str(t.get("kind", "yes"))
		var mat: Material = _dfs[int(_hash(c.x, c.y) * 4.0) % _dfs.size()] \
			if kind in ["apartments", "residential", "dormitory", "hotel"] else _glass
		var storeys := levels if levels > 0 else maxi(1, roundi(h / 3.5))
		BuildingBuilder._batch = batch
		BuildingBuilder._batch_key = _key(c.x, c.y)
		BuildingBuilder._walls(null, ring, base, base + 2.0 + h, mat, float(storeys))
		BuildingBuilder._roof_cap(null, ring, idx, base + 2.0 + h, _drs[1 % _drs.size()])
		BuildingBuilder._batch = null
		_tower_cells[smap.cell_of(c.x, c.y) if smap != null else Vector2i(-9, -9)] = true
		towers += 1

func _fabric() -> void:
	var apt := ArchitectureStyle.profile(_region, "apartments")
	var house := ArchitectureStyle.profile(_region, "house")
	var ind := ArchitectureStyle.profile(_region, "industrial")
	var com := ArchitectureStyle.profile(_region, "commercial")
	var r2_in := R_IN * R_IN
	var r2_out := SettlementMap.RADIUS_M * SettlementMap.RADIUS_M
	for j in smap.n:
		for i in smap.n:
			var k := smap.index(i, j)
			var s := smap.score[k]
			if s < MIN_SCORE or smap.blocked[k] != 0:
				continue
			var cc := smap.centre(i, j)
			var d2 := cc.length_squared()
			if d2 < r2_in or d2 > r2_out or _tower_cells.has(Vector2i(i, j)):
				continue
			var d := sqrt(d2)
			var cls := smap.cls[k]
			var prof := apt
			var kind := "apartments"
			if cls == SettlementMap.Cls.INDUSTRIAL:
				prof = ind
				kind = "industrial"
			elif cls == SettlementMap.Cls.COMMERCIAL:
				prof = com
				kind = "commercial"
			elif s < 0.42:
				prof = house
				kind = "house"
			# District grid orientation: shared by ~600 m patches.
			var yaw := _hash(floorf(float(i) / 6.0), floorf(float(j) / 6.0), 3.0) * PI * 0.5
			var thin := lerpf(1.0, THIN_FAR, smoothstep(SPLIT_M, SettlementMap.RADIUS_M, d))
			var keep := clampf((s - 0.12) / 0.45, 0.2, 1.0) * thin
			var lots := 2 if d < SPLIT_M else 1
			var lot := SettlementMap.CELL_M / float(lots)
			for lj in lots:
				for li in lots:
					var lc := cc + Vector2((float(li) + 0.5) * lot - SettlementMap.CELL_M * 0.5,
						(float(lj) + 0.5) * lot - SettlementMap.CELL_M * 0.5)
					var hv := _hash(lc.x, lc.y)
					if hv > keep:
						continue
					if _near_landmark(lc.x, lc.y):
						continue
					if kind == "house":
						for hi in 2:
							var o := Vector2((_hash(lc.x, lc.y, 5.0 + hi) - 0.5) * lot * 0.5,
								(float(hi) - 0.5) * lot * 0.45)
							_mass(lc + o.rotated(yaw), Vector2(lerpf(9.0, 14.0, _hash(lc.x, lc.y, 7.0 + hi)),
								lerpf(7.0, 10.0, hv)), yaw, prof, d, "house")
					else:
						var fill := 0.75 if kind == "industrial" else 1.0
						var side := (lot - STREET_M) * fill
						_mass(lc, Vector2(side * lerpf(0.8, 1.0, _hash(lc.x, lc.y, 2.0)),
							side * lerpf(0.75, 1.0, _hash(lc.x, lc.y, 4.0))), yaw, prof, d, kind)

## One block mass: walls tiled per bay/storey + a regional roof form.
func _mass(c: Vector2, size: Vector2, yaw: float, prof: Dictionary, d: float,
		kind: String) -> void:
	var ring := BuildingBuilder._rect_ring(c, size, yaw)
	var base := _site(ring, minf(size.x, size.y))
	if base == INF:
		return
	var seed_v := _hash(c.x, c.y, 11.0)
	var st: Array = prof["st"]
	var lo := int(st[0])
	var hi := int(st[1])
	if kind == "apartments" and smap.score_at(c.x, c.y) > 0.65:
		lo += 1
		hi = int(ceil(float(hi) * 1.3))
	var storeys := lo + int(seed_v * float(hi - lo + 1))
	var fh := float(prof["fh"])
	var wall := float(storeys) * fh
	if _h_edge > 0.0 and kind == "apartments":
		var near_h := _h_edge * (0.85 + 0.3 * seed_v)
		wall = lerpf(near_h, wall, smoothstep(R_IN, 4000.0, d))
		storeys = maxi(1, roundi(wall / fh))
	var shape := ArchitectureStyle._pick_weighted(prof["r"] as Array, seed_v, 3)
	var span := minf(size.x, size.y)
	var rh := BuildingBuilder._roof_height_m(shape, span, 0.0, float(prof.get("pitch", 1.0)))
	if shape != "flat":
		wall = maxf(wall - rh * 0.5, fh)
	var top := base + 2.0 + wall
	# Past SPLIT_M tints are indistinguishable through the haze: two
	# facades + one roof per band keep the draw calls down.
	var far := d >= SPLIT_M
	var facade: Material = _dfs[int(seed_v * 97.0) % (mini(2, _dfs.size()) if far else _dfs.size())]
	var roof: Material = _drs[0 if far else int(seed_v * 53.0) % _drs.size()]
	BuildingBuilder._batch = batch
	BuildingBuilder._batch_key = _key(c.x, c.y)
	BuildingBuilder._walls(null, ring, base, top, facade, float(storeys))
	if shape == "flat" or rh < 0.3:
		BuildingBuilder._roof_cap(null, ring, PackedInt32Array([0, 1, 2, 0, 2, 3]), top, roof)
	else:
		_roof(ring, top, rh, shape, roof, size, yaw)
	BuildingBuilder._batch = null
	blocks += 1

## Low-poly pitched roof over a rect ring (corners 0..3 as _rect_ring
## emits them): gabled = ridge along the long axis; hipped/mansard =
## truncated hip; pyramidal/dome = apex.
func _roof(ring: PackedVector2Array, top: float, rh: float, shape: String,
		mat: Material, size: Vector2, yaw: float) -> void:
	var c := (ring[0] + ring[2]) * 0.5
	var ax := Vector2(1, 0).rotated(yaw)
	var az := Vector2(0, 1).rotated(yaw)
	var inset := 0.5
	var along_x := size.x >= size.y
	match shape:
		"gabled":
			inset = 0.0
		"hipped", "mansard":
			inset = 0.28
	# Ridge end points (a line for gabled/hipped, a point for apex forms).
	var half_ridge := 0.0
	if shape in ["gabled", "hipped", "mansard"]:
		half_ridge = (maxf(size.x, size.y) * 0.5) * (1.0 - inset * 2.0) \
			if shape != "gabled" else maxf(size.x, size.y) * 0.5
		half_ridge = maxf(half_ridge, 0.0)
	var dir := ax if along_x else az
	var r0 := c - dir * half_ridge
	var r1 := c + dir * half_ridge
	var apex_y := top + rh
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	# Each eave edge i→i+1 meets the ridge point(s) nearest to it.
	for e in 4:
		var a := ring[e]
		var b := ring[(e + 1) % 4]
		var mid := (a + b) * 0.5
		var pa := r0 if mid.distance_squared_to(r0) <= mid.distance_squared_to(r1) else r1
		var pb := r1 if pa == r0 else r0
		var edge_dir := (b - a).normalized()
		var long_edge := absf(edge_dir.dot(dir)) > 0.7
		var pts: Array[Vector3] = [Vector3(a.x, top, a.y), Vector3(b.x, top, b.y)]
		if long_edge and half_ridge > 0.01:
			# Trapezoid / rectangle slope: ridge ends ordered along the edge.
			var q0 := r0 if (r0 - a).dot(edge_dir) <= (r1 - a).dot(edge_dir) else r1
			var q1 := r1 if q0 == r0 else r0
			pts.append(Vector3(q1.x, apex_y, q1.y))
			pts.append(Vector3(q0.x, apex_y, q0.y))
		else:
			var p := pa if half_ridge > 0.01 else c
			pts.append(Vector3(p.x, apex_y, p.y))
		# Outward = away from the roof centre (slopes and gable ends).
		var nrm := (pts[1] - pts[0]).cross(pts[2] - pts[0]).normalized()
		var flip := nrm.dot(Vector3(mid.x - c.x, 0.01, mid.y - c.y)) < 0.0
		if flip:
			nrm = -nrm
		var k := verts.size()
		for p3 in pts:
			verts.append(p3)
			normals.append(nrm)
			uvs.append(Vector2(p3.x, p3.z) * 0.05)
		var tris := [0, 1, 2] if pts.size() == 3 else [0, 1, 2, 0, 2, 3]
		for t in range(0, tris.size(), 3):
			if flip:
				indices.append_array([k + tris[t], k + tris[t + 1], k + tris[t + 2]])
			else:
				indices.append_array([k + tris[t], k + tris[t + 2], k + tris[t + 1]])
	batch.add(BuildingBuilder._batch_key, mat, verts, normals, uvs, indices)
