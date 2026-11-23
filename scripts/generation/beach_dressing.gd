class_name BeachDressing
extends RefCounted

## Coastal & waterfront beach dressing (MI-7.2):
## * Pale sun-bleached Atlantic sand (`MIAMI_SAND`) in South Florida; unchanged elsewhere.
## * Data-driven props on waterfront `class == "sand"` polygons (`>= 1200 m²`):
##   - 8 procedural lifeguard tower variants (`lifeguard_0..7`, Balanced+)
##   - Landward dune sea-oats (`dune_oats`) & post-and-rope fence (`dune_post`, High/Ultra)
##   - Resort canvas umbrellas + twin sun loungers (`umbrella_0..4`, High/Ultra)
##   - Beach volleyball nets & undulating coral promenade low wall (Ultra)

const MIAMI_SAND := Color(0.84, 0.82, 0.77)
const PRESET_CAP: Array[int] = [0, 45, 140, 480]
const MIN_BEACH_AREA_M2 := 1200.0
const EXTENT_REACH_M := 1160.0
const LIFEGUARD_SPACING_M := 240.0
const LIFEGUARD_CLEAR_M := 130.0
const LIFEGUARD_SETBACK_M := 22.0
const SIGHTLINE_ALONG_M := 16.0
const DUNE_MIN_BACK_M := 30.0
const UMBRELLA_MIN_WIDTH_M := 35.0
const VOLLEYBALL_MIN_WIDTH_M := 50.0
const CROSSOVER_PERIOD_M := 85.0
const CROSSOVER_GAP_M := 5.0

const LIFEGUARD_THEMES := [
	["#F49AC2", "#30C5C8", "#FF5A1F", "ziggurat"],
	["#F4F5F7", "#1D5DEC", "#D92B2B", "porthole"],
	["#D92B2B", "#F5C728", "#FF6B1A", "peaked"],
	["#6ED6B8", "#F27457", "#1FB8B8", "butterfly"],
	["#F27D24", "#F7D436", "#D92B2B", "starburst"],
	["#B388EB", "#38C6D9", "#FF5A1F", "vault"],
	["#78C846", "#F5F5F0", "#FF5A1F", "pagoda"],
	["#1A4B8C", "#62C6F2", "#FF6B1A", "wave"],
]

const UMBRELLA_THEMES := [
	["#1B3B6F", "#F5F5F0"], ["#22B5B8", "#F7F5EC"], ["#E86F68", "#FAF6F0"],
	["#EEC632", "#F8F7F2"], ["#2A9D68", "#F5F6F2"],
]

const SHADOW_FOOTPRINT := {
	"lifeguard": Vector2(3.6, 3.2), "umbrella": Vector2(2.2, 2.5),
	"volleyball_court": Vector2(1.4, 9.2), "promenade_wall": Vector2(0.65, 3.3),
}

static var _meshes: Dictionary = {}
static var _shadow_quad: PlaneMesh

static func is_miami_coast(data: LocationData) -> bool:
	return data != null and data.latitude >= 25.55 and data.latitude <= 26.05 \
		and data.longitude >= -80.45 and data.longitude <= -80.05

static func palette_overrides(data: LocationData) -> Dictionary:
	return {"sand": MIAMI_SAND} if is_miami_coast(data) else {}

static func build(root: Node3D, data: LocationData, ground: GroundTruth,
		mask: VegetationMask = null) -> int:
	if root == null or data == null or ground == null:
		return 0
	var m2u := WorldScale.metres_to_units()
	var items: Array = plan(data, ground, mask, m2u)["items"]
	if items.is_empty():
		return 0
	var by_mesh := {}
	for it_v: Variant in items:
		var d: Dictionary = it_v
		var key := str(d["mesh"])
		if not by_mesh.has(key):
			by_mesh[key] = []
		var px := float(d["x"])
		var pz := float(d["z"])
		var basis := Basis(Vector3.UP, float(d["yaw"])).scaled(Vector3.ONE * m2u)
		(by_mesh[key] as Array).append(Transform3D(basis, Vector3(px, ground.height_at_world(px, pz), pz)))
	var holder := Node3D.new()
	holder.name = "BeachDressing"
	var keys := by_mesh.keys()
	keys.sort()
	for k_var: Variant in keys:
		var key := str(k_var)
		var xfs: Array = by_mesh[key]
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = mesh(key)
		mm.instance_count = xfs.size()
		for i: int in range(xfs.size()):
			mm.set_instance_transform(i, xfs[i] as Transform3D)
		var mmi := MultiMeshInstance3D.new()
		mmi.name = "Beach_%s" % key
		mmi.multimesh = mm
		if key == "dune_oats":
			mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		holder.add_child(mmi)
	_add_contact_shadows(holder, by_mesh, m2u)
	root.add_child(holder)
	return items.size()

static func plan(data: LocationData, ground: GroundTruth, mask: VegetationMask = null,
		m2u: float = WorldScale.metres_to_units()) -> Dictionary:
	var counts := {"lifeguard": 0, "umbrella": 0, "dune_post": 0, "dune_oats": 0,
		"volleyball": 0, "promenade_wall": 0}
	if data == null or ground == null or m2u <= 0.0:
		return {"items": [], "counts": counts, "total": 0}
	var preset := RenderSettings.clamp_preset(data.quality_preset)
	var cap: int = PRESET_CAP[preset]
	if cap <= 0:
		return {"items": [], "counts": counts, "total": 0}
	var shore_segs := _shore_segments(data, ground, m2u)
	if shore_segs.is_empty():
		return {"items": [], "counts": counts, "total": 0}
	var shore_grid := _build_seg_grid(shore_segs, 64.0)
	var beaches := _waterfront_sand_polys(data, ground, shore_grid, m2u)
	if beaches.is_empty():
		return {"items": [], "counts": counts, "total": 0}

	var eye := View360.spawn_xz(data)
	var ctx := {
		"data": data, "ground": ground, "mask": mask, "m2u": m2u,
		"seed": data.seed_value, "eye": eye, "shore_grid": shore_grid,
		"bldgs": _building_shapes(data, m2u),
		"roads": _road_segments(data, m2u, false),
		"walks": _road_segments(data, m2u, true),
	}
	var runs := _beach_shore_runs(shore_segs, beaches, ground, m2u)
	var lifeguards := _nearest_first(_plan_lifeguards(ctx, runs), eye, cap)
	var items: Array = []
	items.append_array(lifeguards)
	counts["lifeguard"] = lifeguards.size()
	if preset == RenderSettings.Preset.BALANCED or items.size() >= cap:
		return {"items": items, "counts": counts, "total": items.size()}

	var profiles := _sample_profiles(runs, ctx)
	var extras := _plan_extras(ctx, profiles, lifeguards, preset)
	var budgets := [
		["volleyball", 0 if preset < RenderSettings.Preset.ULTRA else 6],
		["promenade_wall", 0 if preset < RenderSettings.Preset.ULTRA else 76],
		["umbrella", 64 if preset == RenderSettings.Preset.HIGH else 190],
		["dune_post", 34 if preset == RenderSettings.Preset.HIGH else 88],
		["dune_oats", cap],
	]
	for b_row_v: Variant in budgets:
		var b_row: Array = b_row_v
		var kind := str(b_row[0])
		var take := mini(int(b_row[1]), cap - items.size())
		if take <= 0:
			continue
		var picked := _nearest_first(extras[kind] as Array, eye, take)
		items.append_array(picked)
		counts[kind] = picked.size()
	return {"items": items, "counts": counts, "total": items.size()}

static func _shore_segments(data: LocationData, ground: GroundTruth, m2u: float) -> Array:
	var out: Array = []
	var seen := {}
	var add_seg := func(a_m: Vector2, b_m: Vector2, land_dir: Vector2) -> void:
		if a_m.distance_to(b_m) < 0.8 or land_dir.length_squared() < 0.25:
			return
		if maxf(absf(a_m.x), absf(a_m.y)) > EXTENT_REACH_M and maxf(absf(b_m.x), absf(b_m.y)) > EXTENT_REACH_M:
			return
		var ld := land_dir.normalized()
		var p0 := a_m
		var p1 := b_m
		if (p1 - p0).dot(Vector2(-ld.y, ld.x)) < 0.0:
			p0 = b_m
			p1 = a_m
		var key := Vector2i(roundi((p0.x + p1.x) * 0.25), roundi((p0.y + p1.y) * 0.25))
		if not seen.has(key):
			seen[key] = true
			out.append([p0, p1, ld])

	if ground.shoreline != null and not ground.shoreline.segments.is_empty():
		var domains: Variant = ground.shoreline.domains
		for seg_v: Variant in ground.shoreline.segments:
			var seg: Dictionary = seg_v
			if domains != null and int(seg.get("body", -1)) >= 0 \
					and bool((domains.bodies[int(seg["body"])] as Dictionary).get("still_pool", false)):
				continue
			add_seg.call((seg["a"] as Vector2) / m2u, (seg["b"] as Vector2) / m2u, seg["land"] as Vector2)

	for w_v: Variant in data.waterways:
		if w_v is Dictionary and str((w_v as Dictionary).get("class", "")) == "coastline":
			var pts: PackedVector2Array = (w_v as Dictionary).get("points", PackedVector2Array())
			for i: int in range(pts.size() - 1):
				var d := (pts[i + 1] - pts[i]) / m2u
				if d.length() >= 0.8:
					var u := d.normalized()
					add_seg.call(pts[i] / m2u, pts[i + 1] / m2u, Vector2(u.y, -u.x))

	if out.is_empty():
		for p_v: Variant in data.land_polygons:
			if not (p_v is Dictionary):
				continue
			var pd: Dictionary = p_v
			var cls := str(pd.get("class", ""))
			if cls not in ["water", "sand"] or bool(pd.get("still_pool", false)):
				continue
			var ring: PackedVector2Array = pd.get("points", PackedVector2Array())
			for i: int in range(ring.size()):
				var a := ring[i]
				var b := ring[(i + 1) % ring.size()]
				if a.distance_to(b) < 0.8 * m2u:
					continue
				var nrm := Vector2(-(b.y - a.y), b.x - a.x).normalized()
				var mid := (a + b) * 0.5
				if cls == "water":
					var ld := nrm if not RingGeometry.point_in_ring(mid + nrm * (2.0 * m2u), ring) else -nrm
					add_seg.call(a / m2u, b / m2u, ld)
				elif ground.water_at(mid.x + nrm.x * 3.0 * m2u, mid.y + nrm.y * 3.0 * m2u) > 0.0:
					add_seg.call(a / m2u, b / m2u, -nrm)
				elif ground.water_at(mid.x - nrm.x * 3.0 * m2u, mid.y - nrm.y * 3.0 * m2u) > 0.0:
					add_seg.call(a / m2u, b / m2u, nrm)
	return out

static func _build_seg_grid(segs: Array, cell_m: float) -> Dictionary:
	var cells := {}
	for s_v: Variant in segs:
		var s: Array = s_v
		var a: Vector2 = s[0]
		var b: Vector2 = s[1]
		for cz: int in range(floori(minf(a.y, b.y) / cell_m), floori(maxf(a.y, b.y) / cell_m) + 1):
			for cx: int in range(floori(minf(a.x, b.x) / cell_m), floori(maxf(a.x, b.x) / cell_m) + 1):
				var k := Vector2i(cx, cz)
				if not cells.has(k):
					cells[k] = []
				(cells[k] as Array).append(s)
	return {"cell": cell_m, "cells": cells}

static func _nearest_shore(shore_grid: Dictionary, p_m: Vector2, max_d_m: float) -> Dictionary:
	var cell_m := float(shore_grid["cell"])
	var cells: Dictionary = shore_grid["cells"]
	var reach := int(ceil(max_d_m / cell_m))
	var c := Vector2i(floori(p_m.x / cell_m), floori(p_m.y / cell_m))
	var best_d := max_d_m
	var best := {}
	for dz: int in range(-reach, reach + 1):
		for dx: int in range(-reach, reach + 1):
			for s_v: Variant in cells.get(Vector2i(c.x + dx, c.y + dz), []):
				var s: Array = s_v
				var q := Geometry2D.get_closest_point_to_segment(p_m, s[0] as Vector2, s[1] as Vector2)
				var d := p_m.distance_to(q)
				if d < best_d:
					best_d = d
					best = {"point": q, "land": s[2] as Vector2, "dist": d}
	return best

static func _waterfront_sand_polys(data: LocationData, ground: GroundTruth,
		shore_grid: Dictionary, m2u: float) -> Array:
	var out: Array = []
	for p_v: Variant in data.land_polygons:
		if not (p_v is Dictionary) or str((p_v as Dictionary).get("class", "")) != "sand":
			continue
		var pd: Dictionary = p_v
		var pts: PackedVector2Array = pd.get("points", PackedVector2Array())
		if pts.size() < 3:
			continue
		var area_m2 := absf(RingGeometry.signed_area(pts)) / (m2u * m2u)
		for h_v: Variant in pd.get("holes", []):
			if h_v is PackedVector2Array:
				area_m2 -= absf(RingGeometry.signed_area(h_v as PackedVector2Array)) / (m2u * m2u)
		if area_m2 < MIN_BEACH_AREA_M2:
			continue
		var step := maxi(1, pts.size() / 64)
		for i: int in range(0, pts.size(), step):
			var pm := pts[i] / m2u
			var mid := (pm + pts[(i + 1) % pts.size()] / m2u) * 0.5
			if not _nearest_shore(shore_grid, pm, 20.0).is_empty() \
					or not _nearest_shore(shore_grid, mid, 20.0).is_empty() \
					or ground.water_at(pts[i].x, pts[i].y) > 0.0:
				out.append({"box": RingGeometry.aabb(pts), "index": PolygonIndex.new(pts, pd.get("holes", []))})
				break
	return out

static func _beach_shore_runs(shore_segs: Array, beaches: Array, ground: GroundTruth, m2u: float) -> Array:
	var segs: Array = []
	for s_v: Variant in shore_segs:
		var s: Array = s_v
		var mid_m := ((s[0] as Vector2) + (s[1] as Vector2)) * 0.5
		var ld: Vector2 = s[2]
		for probe_m: float in [4.0, 9.0, 15.0]:
			var pu := (mid_m + ld * probe_m) * m2u
			var inside := false
			for b_v: Variant in beaches:
				var b: Dictionary = b_v
				if (b["box"] as Rect2).has_point(pu) and (b["index"] as PolygonIndex).contains(pu):
					inside = true
					break
			if inside and ground.is_inside(pu.x, pu.y) and ground.land_class_at(pu.x, pu.y) == "sand":
				segs.append(s)
				break
	var starts := {}
	var ends := {}
	for i: int in range(segs.size()):
		var ka := Vector2i(roundi((segs[i][0] as Vector2).x), roundi((segs[i][0] as Vector2).y))
		var kb := Vector2i(roundi((segs[i][1] as Vector2).x), roundi((segs[i][1] as Vector2).y))
		if not starts.has(ka):
			starts[ka] = []
		(starts[ka] as Array).append(i)
		ends[kb] = true
	var order: Array[int] = []
	for pass_end: int in [0, 1]:
		for i: int in range(segs.size()):
			var ka := Vector2i(roundi((segs[i][0] as Vector2).x), roundi((segs[i][0] as Vector2).y))
			if int(ends.has(ka)) == pass_end:
				order.append(i)
	var used := {}
	var runs: Array = []
	for i: int in order:
		if used.has(i):
			continue
		var chain: Array = []
		var total_len := 0.0
		var cur := i
		while cur >= 0 and not used.has(cur):
			used[cur] = true
			chain.append(segs[cur])
			total_len += (segs[cur][0] as Vector2).distance_to(segs[cur][1] as Vector2)
			var tail: Vector2 = segs[cur][1]
			var kt := Vector2i(roundi(tail.x), roundi(tail.y))
			cur = -1
			for dz: int in [-1, 0, 1]:
				for dx: int in [-1, 0, 1]:
					for cand_v: Variant in starts.get(Vector2i(kt.x + dx, kt.y + dz), []):
						var cand := int(cand_v)
						if not used.has(cand) and tail.distance_to(segs[cand][0] as Vector2) <= 2.2:
							cur = cand
							break
					if cur >= 0:
						break
				if cur >= 0:
					break
		runs.append({"segs": chain, "length_m": total_len})
	return runs

static func _building_shapes(data: LocationData, m2u: float) -> Array:
	var out: Array = []
	for b_v: Variant in data.buildings:
		if not (b_v is Dictionary):
			continue
		var b: Dictionary = b_v
		var fp: Variant = b.get("footprint", null)
		var ring := fp as PackedVector2Array if fp is PackedVector2Array and (fp as PackedVector2Array).size() >= 3 else PackedVector2Array()
		if ring.is_empty():
			var bx := float(b.get("x", 0.0))
			var bz := float(b.get("z", 0.0))
			var hx := float(b.get("size_x", 0.0)) * 0.5
			var hz := float(b.get("size_z", 0.0)) * 0.5
			if hx <= 0.0 or hz <= 0.0:
				continue
			ring = PackedVector2Array([Vector2(bx - hx, bz - hz), Vector2(bx + hx, bz - hz),
				Vector2(bx + hx, bz + hz), Vector2(bx - hx, bz + hz)])
		out.append([RingGeometry.aabb(ring).grow(6.0 * m2u), ring])
	return out

static func _road_segments(data: LocationData, m2u: float, foot_only: bool) -> Dictionary:
	var segs: Array = []
	for r_v: Variant in data.roads:
		if not (r_v is Dictionary):
			continue
		var rd: Dictionary = r_v
		if bool(rd.get("tunnel", false)) or bool(rd.get("area", false)):
			continue
		var is_foot := str(rd.get("class", "")) in VegetationMask.FOOT_CLASSES
		if is_foot != foot_only:
			continue
		var pts: PackedVector2Array = rd.get("points", PackedVector2Array())
		var hw := maxf(float(rd.get("width_m", 2.5 if is_foot else 6.0)) * 0.5, 1.0)
		for i: int in range(pts.size() - 1):
			segs.append([pts[i] / m2u, pts[i + 1] / m2u, hw])
	return _build_seg_grid(segs, 48.0)

static func _near_way(way_grid: Dictionary, p_m: Vector2, extra_m: float) -> bool:
	var cell_m := float(way_grid["cell"])
	var cells: Dictionary = way_grid["cells"]
	var c := Vector2i(floori(p_m.x / cell_m), floori(p_m.y / cell_m))
	for dz: int in [-1, 0, 1]:
		for dx: int in [-1, 0, 1]:
			for s_v: Variant in cells.get(Vector2i(c.x + dx, c.y + dz), []):
				var s: Array = s_v
				if p_m.distance_to(Geometry2D.get_closest_point_to_segment(p_m, s[0] as Vector2, s[1] as Vector2)) <= float(s[2]) + extra_m:
					return true
	return false

static func _safe_sand(x_u: float, z_u: float, ctx: Dictionary, margin_m: float = 1.2) -> bool:
	var ground: GroundTruth = ctx["ground"]
	if not ground.is_inside(x_u, z_u) or ground.land_class_at(x_u, z_u) != "sand" or ground.water_at(x_u, z_u) > 0.0:
		return false
	var mask: VegetationMask = ctx["mask"]
	var clear_m := maxf(margin_m, 1.2)
	if mask != null and mask.blocked(x_u, z_u, VegetationMask.BUILDING | VegetationMask.ROAD | VegetationMask.WATER, clear_m):
		return false
	var m2u := float(ctx["m2u"])
	var pt := Vector2(x_u, z_u)
	var pad_u := clear_m * m2u
	for entry_v: Variant in (ctx["bldgs"] as Array):
		var entry: Array = entry_v
		if not (entry[0] as Rect2).has_point(pt):
			continue
		var ring: PackedVector2Array = entry[1]
		if Geometry2D.is_point_in_polygon(pt, ring):
			return false
		for i: int in range(ring.size()):
			if pt.distance_to(Geometry2D.get_closest_point_to_segment(pt, ring[i], ring[(i + 1) % ring.size()])) < pad_u:
				return false
	return not (mask == null and _near_way(ctx["roads"] as Dictionary, pt / m2u, clear_m))

static func _safe_footprint(center_u: Vector2, fwd: Vector2, hx_m: float, hz_m: float,
		ctx: Dictionary, margin_m: float = 1.2) -> bool:
	if not _safe_sand(center_u.x, center_u.y, ctx, margin_m):
		return false
	var m2u := float(ctx["m2u"])
	var right := Vector2(-fwd.y, fwd.x)
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			var c := center_u + (fwd * (sx * hx_m) + right * (sz * hz_m)) * m2u
			if not _safe_sand(c.x, c.y, ctx, 1.2):
				return false
	return true

static func _sample_profiles(runs: Array, ctx: Dictionary) -> Array:
	var ground: GroundTruth = ctx["ground"]
	var m2u := float(ctx["m2u"])
	var out: Array = []
	for r_idx: int in range(runs.size()):
		var run: Dictionary = runs[r_idx]
		var s_acc := 0.0
		var next_s := 1.5
		for seg_v: Variant in (run["segs"] as Array):
			var seg: Array = seg_v
			var a: Vector2 = seg[0]
			var b: Vector2 = seg[1]
			var seg_len := a.distance_to(b)
			if seg_len < 0.01:
				continue
			while next_s <= s_acc + seg_len:
				var prof := _march_sand(a.lerp(b, clampf((next_s - s_acc) / seg_len, 0.0, 1.0)), seg[2] as Vector2, ground, m2u)
				if not prof.is_empty():
					prof["run"] = r_idx
					prof["s_m"] = next_s
					out.append(prof)
				next_s += 3.0
			s_acc += seg_len
	return out

static func _march_sand(base_m: Vector2, land_dir: Vector2, ground: GroundTruth, m2u: float) -> Dictionary:
	var d_min := -1.0
	var d_max := -1.0
	var d := 1.5
	while d <= 170.0:
		var pu := (base_m + land_dir * d) * m2u
		if not ground.is_inside(pu.x, pu.y):
			break
		if ground.water_at(pu.x, pu.y) <= 0.0 and ground.land_class_at(pu.x, pu.y) == "sand":
			if d_min < 0.0:
				d_min = d
			d_max = d
		elif d_min >= 0.0:
			break
		elif d > 16.0:
			return {}
		d += 3.0
	if d_min < 0.0 or d_max - d_min < 8.0:
		return {}
	while d_max + 1.0 <= 175.0:
		var pu2 := (base_m + land_dir * (d_max + 1.0)) * m2u
		if ground.is_inside(pu2.x, pu2.y) and ground.water_at(pu2.x, pu2.y) <= 0.0 and ground.land_class_at(pu2.x, pu2.y) == "sand":
			d_max += 1.0
		else:
			break
	var beyond_u := (base_m + land_dir * (d_max + 3.0)) * m2u
	var beyond_cls := ground.land_class_at(beyond_u.x, beyond_u.y) if ground.is_inside(beyond_u.x, beyond_u.y) else ""
	return {"shore_m": base_m, "land_dir": land_dir, "d_min_m": d_min, "d_back_m": d_max,
		"width_m": d_max - d_min, "beyond_cls": beyond_cls}

static func _plan_lifeguards(ctx: Dictionary, runs: Array) -> Array:
	var data: LocationData = ctx["data"]
	var ground: GroundTruth = ctx["ground"]
	var m2u := float(ctx["m2u"])
	var seed_val := int(ctx["seed"])
	var out: Array = []
	var placed_m: Array[Vector2] = []
	var try_tower := func(pu: Vector2, water_dir: Vector2, min_sep: float) -> void:
		var pm := pu / m2u
		if _too_close(pm, placed_m, min_sep):
			return
		var ramp_u := pu - water_dir * (2.4 * m2u)
		if not _safe_footprint(pu, water_dir, 1.8, 1.5, ctx, 1.5) or not _safe_sand(ramp_u.x, ramp_u.y, ctx, 1.2):
			return
		var v := _hash_int(roundi(pm.x), roundi(pm.y), seed_val, 8)
		placed_m.append(pm)
		out.append({"kind": "lifeguard", "mesh": "lifeguard_%d" % v, "x": pu.x, "z": pu.y,
			"yaw": _yaw(water_dir), "variant": v, "water_dir": water_dir})

	for src_v: Variant in [data.pois, data.street_furniture]:
		for it_v: Variant in (src_v as Array):
			if it_v is Dictionary and str((it_v as Dictionary).get("kind", "")) == "lifeguard":
				var md: Dictionary = it_v
				var pu := Vector2(float(md.get("x", 0.0)), float(md.get("z", 0.0)))
				var sh := _nearest_shore(ctx["shore_grid"] as Dictionary, pu / m2u, 160.0)
				try_tower.call(pu, -(sh["land"] as Vector2) if not sh.is_empty() else Vector2.RIGHT, 12.0)

	for run_v: Variant in runs:
		var run: Dictionary = run_v
		var run_len := float(run["length_m"])
		if run_len < 180.0:
			continue
		var segs: Array = run["segs"]
		var target_s := 70.0 + float(_hash_int(segs.size(), roundi(run_len), seed_val, 80))
		var s_acc := 0.0
		for seg_v: Variant in segs:
			var seg: Array = seg_v
			var a: Vector2 = seg[0]
			var b: Vector2 = seg[1]
			var ld: Vector2 = seg[2]
			var seg_len := a.distance_to(b)
			while target_s <= s_acc + seg_len:
				var base_m := a.lerp(b, clampf((target_s - s_acc) / maxf(seg_len, 0.01), 0.0, 1.0))
				target_s += LIFEGUARD_SPACING_M
				var prof := _march_sand(base_m, ld, ground, m2u)
				if not prof.is_empty() and float(prof["width_m"]) >= 28.0:
					var d_set := clampf(float(prof["d_min_m"]) + LIFEGUARD_SETBACK_M,
						float(prof["d_min_m"]) + 12.0, float(prof["d_back_m"]) - 6.0)
					try_tower.call((base_m + ld * d_set) * m2u, -ld, LIFEGUARD_CLEAR_M)
			s_acc += seg_len
	return out

static func _in_sightline(pm: Vector2, lifeguards: Array, m2u: float) -> bool:
	for lg_v: Variant in lifeguards:
		var lg: Dictionary = lg_v
		var lm := Vector2(float(lg["x"]), float(lg["z"])) / m2u
		var wd: Vector2 = lg["water_dir"]
		var rel := pm - lm
		if rel.length() < 14.0 or (rel.dot(wd) > -6.0 and absf(rel.dot(Vector2(-wd.y, wd.x))) < SIGHTLINE_ALONG_M):
			return true
	return false

static func _plan_extras(ctx: Dictionary, profiles: Array, lifeguards: Array, preset: int) -> Dictionary:
	var ground: GroundTruth = ctx["ground"]
	var walks: Dictionary = ctx["walks"]
	var m2u := float(ctx["m2u"])
	var seed_val := int(ctx["seed"])
	var step_dune := 2 if preset == RenderSettings.Preset.HIGH else 1
	var out := {"umbrella": [], "volleyball": [], "dune_post": [], "dune_oats": [], "promenade_wall": []}
	var taken_umb: Array[Vector2] = []
	var taken_vb: Array[Vector2] = []
	var taken_post: Array[Vector2] = []
	var taken_oats: Array[Vector2] = []
	var taken_wall: Array[Vector2] = []

	for i: int in range(profiles.size()):
		var prof: Dictionary = profiles[i]
		var base_m: Vector2 = prof["shore_m"]
		var ld: Vector2 = prof["land_dir"]
		var water_dir := -ld
		var w_m := float(prof["width_m"])
		var d_min := float(prof["d_min_m"])
		var d_back := float(prof["d_back_m"])
		var s_m := float(prof["s_m"])
		var in_gap := fmod(s_m, CROSSOVER_PERIOD_M) < CROSSOVER_GAP_M

		if preset >= RenderSettings.Preset.ULTRA and (i % 8 == 0) and w_m >= VOLLEYBALL_MIN_WIDTH_M \
				and fmod(s_m + 35.0, 220.0) <= 26.0:
			var pm_v := base_m + ld * clampf(d_min + w_m * 0.56, d_min + 36.0, d_back - 12.0)
			var pu_v := pm_v * m2u
			if not _in_sightline(pm_v, lifeguards, m2u) and not _too_close(pm_v, taken_vb, 180.0) \
					and not _near_way(walks, pm_v, 6.0) and ground.slope_at(pu_v.x, pu_v.y) <= 0.08 \
					and _safe_footprint(pu_v, water_dir, 8.2, 4.6, ctx, 1.5):
				taken_vb.append(pm_v)
				taken_umb.append(pm_v)
				(out["volleyball"] as Array).append({"kind": "volleyball", "mesh": "volleyball_court",
					"x": pu_v.x, "z": pu_v.y, "yaw": _yaw(water_dir), "variant": _hash_int(roundi(pm_v.x), roundi(pm_v.y), seed_val, 2)})

		if (i % 2 == 0) and w_m >= UMBRELLA_MIN_WIDTH_M and fmod(s_m, 54.0) <= 21.0 \
				and fmod(s_m, CROSSOVER_PERIOD_M) >= CROSSOVER_GAP_M + 3.0:
			var col_idx := _hash_int(int(floor(s_m / 140.0)), int(prof["run"]) * 31, seed_val, 5)
			for row_d: float in [d_min + 18.0, d_min + 24.5]:
				if row_d > d_back - 8.5:
					continue
				var pm_u := base_m + ld * row_d
				var pu_u := pm_u * m2u
				if not _in_sightline(pm_u, lifeguards, m2u) and not _too_close(pm_u, taken_umb, 5.4) \
						and not _near_way(walks, pm_u, 2.5) and ground.slope_at(pu_u.x, pu_u.y) <= 0.14 \
						and _safe_footprint(pu_u, water_dir, 1.2, 1.35, ctx, 1.3):
					taken_umb.append(pm_u)
					(out["umbrella"] as Array).append({"kind": "umbrella", "mesh": "umbrella_%d" % col_idx,
						"x": pu_u.x, "z": pu_u.y, "yaw": _yaw(water_dir), "variant": col_idx})

		if d_back < DUNE_MIN_BACK_M or in_gap:
			continue
		if i % step_dune == 0:
			var pm_p := base_m + ld * (d_back - 3.2)
			var pu_p := pm_p * m2u
			if not _too_close(pm_p, taken_post, 2.5) and not _near_way(walks, pm_p, 2.2) \
					and _safe_footprint(pu_p, water_dir, 0.3, 1.45, ctx, 1.25):
				taken_post.append(pm_p)
				(out["dune_post"] as Array).append({"kind": "dune_post", "mesh": "dune_post",
					"x": pu_p.x, "z": pu_p.y, "yaw": _yaw(water_dir), "variant": 0})

			var jit := (float(_hash_int(i, roundi(s_m), seed_val, 100)) / 100.0 - 0.5) * 1.8
			var pm_o := base_m + ld * (d_back - 2.6 + jit)
			var pu_o := pm_o * m2u
			if not _too_close(pm_o, taken_oats, 2.0) and not _near_way(walks, pm_o, 2.0) \
					and _safe_sand(pu_o.x, pu_o.y, ctx, 1.25):
				taken_oats.append(pm_o)
				var oat_yaw := float(_hash_int(roundi(pm_o.x * 3.0), roundi(pm_o.y * 3.0), seed_val, 360)) * PI / 180.0
				(out["dune_oats"] as Array).append({"kind": "dune_oats", "mesh": "dune_oats",
					"x": pu_o.x, "z": pu_o.y, "yaw": oat_yaw, "variant": 0})

		if preset >= RenderSettings.Preset.ULTRA and fmod(s_m, CROSSOVER_PERIOD_M) >= CROSSOVER_GAP_M + 1.0:
			var edge_m := base_m + ld * d_back
			if str(prof["beyond_cls"]) == "grass" or _near_way(walks, edge_m + ld * 3.0, 5.0):
				var wave := sin(s_m * TAU / 24.0) * 0.35
				var pm_w := edge_m - ld * (1.55 - wave)
				var pu_w := pm_w * m2u
				var wd_w := -ld.rotated(atan2(cos(s_m * TAU / 24.0) * (TAU / 24.0) * 0.35, 1.0))
				if not _too_close(pm_w, taken_wall, 2.75) and not _near_way(walks, pm_w, 1.2) \
						and _safe_footprint(pu_w, wd_w, 0.35, 1.55, ctx, 1.2):
					taken_wall.append(pm_w)
					(out["promenade_wall"] as Array).append({"kind": "promenade_wall", "mesh": "promenade_wall",
						"x": pu_w.x, "z": pu_w.y, "yaw": _yaw(wd_w), "variant": 0})
	return out

static func _nearest_first(items: Array, eye: Vector2, limit: int) -> Array:
	if limit <= 0 or items.is_empty():
		return []
	var copy := items.duplicate()
	copy.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return Vector2(float(a["x"]), float(a["z"])).distance_squared_to(eye) \
			< Vector2(float(b["x"]), float(b["z"])).distance_squared_to(eye))
	return copy.slice(0, limit) if copy.size() > limit else copy

static func _too_close(p: Vector2, pts: Array[Vector2], min_d: float) -> bool:
	var d2 := min_d * min_d
	for q: Vector2 in pts:
		if p.distance_squared_to(q) < d2:
			return true
	return false

static func _yaw(facing: Vector2) -> float:
	return atan2(-facing.y, facing.x)

static func _hash_int(a: int, b: int, c: int, mod_n: int) -> int:
	return posmod((a * 73856093) ^ (b * 19349663) ^ (c * 83492791), mod_n)

# --- Procedural True-Metre Meshes ----------------------------------------

static func mesh(key: String) -> ArrayMesh:
	if _meshes.has(key):
		return _meshes[key] as ArrayMesh
	var built: ArrayMesh
	if key.begins_with("lifeguard_"):
		built = _lifeguard_mesh(clampi(key.trim_prefix("lifeguard_").to_int(), 0, 7))
	elif key.begins_with("umbrella_"):
		built = _umbrella_set_mesh(clampi(key.trim_prefix("umbrella_").to_int(), 0, 4))
	elif key == "dune_post":
		built = _dune_post_mesh()
	elif key == "dune_oats":
		built = _dune_oats_mesh()
	elif key == "volleyball_court":
		built = _volleyball_mesh()
	else:
		built = _promenade_wall_mesh()
	_meshes[key] = built
	return built

static func _lifeguard_mesh(variant: int) -> ArrayMesh:
	var row: Array = LIFEGUARD_THEMES[variant]
	var kind := str(row[3])
	var lm := LandmarkMesh.new()
	lm.use("Timber", LandmarkMaterials.pbr("wood", "#8C6D50", 2.0))
	lm.use("Primary", LandmarkMaterials.pbr("wood", str(row[0]), 1.8))
	lm.use("Accent", LandmarkMaterials.pbr("render", str(row[1]), 2.0))
	lm.use("White", LandmarkMaterials.pbr("render", "#F6F5F0", 2.0))
	lm.use("Glass", LandmarkMaterials.glass("#263845"))
	lm.use("Pennant", LandmarkMaterials.pbr("render", str(row[2]), 1.5, 0.72))

	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			lm.beam("Timber", Vector3(sx * 1.28, -0.15, sz * 1.16), Vector3(sx * 1.06, 1.70, sz * 0.98), 0.16, 0.16)
		lm.beam("Timber", Vector3(-1.18, 0.72, sx * 1.08), Vector3(1.18, 0.72, sx * 1.08), 0.10, 0.10)
		lm.beam("Timber", Vector3(-1.24, 0.15, sx * 1.12), Vector3(1.10, 1.58, sx * 1.00), 0.08, 0.08)

	lm.beam("Timber", Vector3(-2.32, 0.04, 0.0), Vector3(-1.30, 1.70, 0.0), 0.84, 0.09, Vector3.FORWARD, true)
	for sz: float in [-0.42, 0.42]:
		lm.beam("Timber", Vector3(-2.28, -0.08, sz), Vector3(-2.28, 0.90, sz), 0.08, 0.08)
		lm.beam("Timber", Vector3(-1.34, 1.70, sz), Vector3(-1.34, 2.60, sz), 0.08, 0.08)
		lm.beam("Accent", Vector3(-2.28, 0.90, sz), Vector3(-1.34, 2.60, sz), 0.06, 0.06)
		lm.beam("White", Vector3(-2.28, 0.48, sz), Vector3(-1.34, 2.15, sz), 0.04, 0.04)

	lm.box("Timber", Vector3(0.18, 1.72, 0.0), Vector3(3.16, 0.12, 2.76), Basis(), 0.02)
	for sx: float in [-1.34, 1.70]:
		for sz: float in [-1.32, 1.32]:
			lm.box("White", Vector3(sx, 2.20, sz), Vector3(0.08, 0.88, 0.08), Basis(), 0.0)
	for sz: float in [-1.32, 1.32]:
		lm.beam("Accent", Vector3(-1.34, 2.62, sz), Vector3(1.70, 2.62, sz), 0.07, 0.05)
		lm.beam("White", Vector3(-1.34, 2.20, sz), Vector3(1.70, 2.20, sz), 0.05, 0.04)
	lm.beam("Accent", Vector3(1.70, 2.62, -1.32), Vector3(1.70, 2.62, 1.32), 0.07, 0.05)
	lm.beam("White", Vector3(1.70, 2.20, -1.32), Vector3(1.70, 2.20, 1.32), 0.05, 0.04)
	lm.box("Pennant", Vector3(1.76, 2.34, 0.55), Vector3(0.14, 0.18, 0.68), Basis(), 0.04)

	lm.box("Primary", Vector3(0.06, 2.28, 0.0), Vector3(2.12, 1.00, 1.98), Basis(), 0.03)
	if kind == "porthole":
		for sx: float in [-0.98, 1.10]:
			for sz: float in [-0.92, 0.92]:
				lm.frustum("Primary", Vector3(sx, 1.78, sz), 0.18, 0.18, 2.08, 10)
		for sz: float in [-1.01, 1.01]:
			lm.disc("Accent", Vector3(0.06, 2.30, sz), Vector3(0.0, 0.0, signf(sz)), 0.24, 12)
			lm.disc("Glass", Vector3(0.06, 2.30, sz * 1.01), Vector3(0.0, 0.0, signf(sz)), 0.17, 12)
	var r0 := PackedVector3Array([Vector3(-1.00, 2.78, -0.99), Vector3(1.12, 2.78, -0.99),
		Vector3(1.12, 2.78, 0.99), Vector3(-1.00, 2.78, 0.99), Vector3(-1.00, 2.78, -0.99)])
	var r1 := PackedVector3Array([Vector3(-1.12, 3.86, -1.10), Vector3(1.26, 3.86, -1.10),
		Vector3(1.26, 3.86, 1.10), Vector3(-1.12, 3.86, 1.10), Vector3(-1.12, 3.86, -1.10)])
	lm.grid("Glass", [r0, r1], Vector3(0.06, 3.30, 0.0), true)
	for i: int in range(4):
		lm.beam("White", r0[i], r1[i], 0.12, 0.12)
		lm.beam("White", r0[i], r0[i + 1], 0.10, 0.10)
		lm.beam("White", r1[i], r1[i + 1], 0.12, 0.12)

	match kind:
		"ziggurat":
			lm.box("Accent", Vector3(1.28, 3.84, 0.0), Vector3(0.46, 0.09, 2.36), Basis(), 0.02)
			lm.box("Primary", Vector3(0.06, 4.02, 0.0), Vector3(2.58, 0.28, 2.40), Basis(), 0.03)
			lm.box("Accent", Vector3(0.06, 4.28, 0.0), Vector3(2.02, 0.24, 1.88), Basis(), 0.03)
			lm.box("Primary", Vector3(0.06, 4.54, 0.0), Vector3(1.36, 0.28, 1.28), Basis(), 0.03)
			lm.box("Accent", Vector3(1.36, 4.22, 0.0), Vector3(0.14, 0.72, 0.26), Basis(), 0.02)
		"porthole":
			lm.box("Accent", Vector3(0.18, 3.94, 0.0), Vector3(2.92, 0.16, 2.62), Basis(), 0.04)
			lm.box("White", Vector3(0.06, 4.16, 0.0), Vector3(2.24, 0.28, 2.04), Basis(), 0.04)
			lm.frustum("Accent", Vector3(0.06, 4.30, 0.0), 0.56, 0.28, 0.36, 12)
		"peaked":
			lm.box("Accent", Vector3(0.06, 3.92, 0.0), Vector3(2.92, 0.14, 2.76), Basis(), 0.02)
			lm.spire("Primary", Vector3(0.06, 3.99, 0.0), 1.44, 0.96, 0.06, 4)
			lm.box("White", Vector3(1.16, 2.30, 0.0), Vector3(0.06, 0.44, 0.14), Basis(), 0.0)
			lm.box("White", Vector3(1.16, 2.30, 0.0), Vector3(0.06, 0.14, 0.44), Basis(), 0.0)
		"butterfly":
			lm.box("Primary", Vector3(0.06, 3.92, 0.0), Vector3(2.56, 0.14, 2.34), Basis(), 0.02)
			for sz: float in [-1.0, 1.0]:
				lm.box("Accent", Vector3(0.10, 4.18, sz * 0.72), Vector3(2.88, 0.11, 1.56), Basis(Vector3.RIGHT, sz * -0.24), 0.02)
		"starburst":
			lm.box("Primary", Vector3(0.08, 3.96, 0.0), Vector3(2.74, 0.20, 2.52), Basis(), 0.03)
			lm.box("Accent", Vector3(0.24, 4.46, 0.0), Vector3(2.10, 0.92, 0.16), Basis(), 0.02)
			for k: int in range(-2, 3):
				var ang := float(k) * 0.34
				lm.beam("Accent", Vector3(1.46, 3.96, 0.0), Vector3(1.48, 3.96 + cos(ang) * 0.58, sin(ang) * 0.68), 0.08, 0.06)
		"vault":
			var vr0 := PackedVector3Array()
			var vr1 := PackedVector3Array()
			for k: int in range(7):
				var a := PI * float(k) / 6.0
				vr0.append(Vector3(-1.26, 3.88 + sin(a) * 0.76, -cos(a) * 1.34))
				vr1.append(Vector3(1.46, 3.88 + sin(a) * 0.76, -cos(a) * 1.34))
			lm.grid("Accent", [vr0, vr1], Vector3(0.10, 3.50, 0.0), true)
			lm.box("Primary", Vector3(0.10, 4.10, 0.0), Vector3(2.54, 0.44, 2.20), Basis(), 0.02)
		"pagoda":
			lm.box("White", Vector3(0.06, 3.90, 0.0), Vector3(3.00, 0.10, 2.84), Basis(), 0.02)
			lm.spire("Primary", Vector3(0.06, 3.95, 0.0), 1.46, 0.42, 0.84, 4)
			lm.box("White", Vector3(0.06, 4.42, 0.0), Vector3(1.74, 0.12, 1.66), Basis(), 0.02)
			lm.spire("Primary", Vector3(0.06, 4.48, 0.0), 0.94, 0.52, 0.04, 4)
		_:
			var wr0 := PackedVector3Array()
			var wr1 := PackedVector3Array()
			for k: int in range(9):
				var u := float(k) / 8.0
				var x := lerpf(-1.34, 1.54, u)
				var y := 4.02 + sin(u * TAU * 1.15) * 0.28 + u * 0.22
				wr0.append(Vector3(x, y, -1.36))
				wr1.append(Vector3(x, y, 1.36))
			lm.grid("Accent", [wr0, wr1], Vector3.UP)
			lm.box("Primary", Vector3(0.08, 3.94, 0.0), Vector3(2.52, 0.18, 2.32), Basis(), 0.02)

	lm.frustum("White", Vector3(1.18, 3.84, 1.04), 0.03, 0.018, 1.42, 8)
	var f0 := Vector3(1.18, 5.22, 1.04)
	var f1 := Vector3(1.18, 4.92, 1.04)
	var f2 := Vector3(0.54, 5.07, 1.16)
	lm.tri("Pennant", f0, f1, f2, Vector3.BACK, Vector3.BACK, Vector3.BACK, Vector2.ZERO, Vector2(0, 0.3), Vector2(0.65, 0.15))
	lm.tri("Pennant", f0, f2, f1, Vector3.FORWARD, Vector3.FORWARD, Vector3.FORWARD, Vector2.ZERO, Vector2(0.65, 0.15), Vector2(0, 0.3))
	return lm.to_array_mesh()

static func _umbrella_set_mesh(col_idx: int) -> ArrayMesh:
	var pair: Array = UMBRELLA_THEMES[col_idx]
	var lm := LandmarkMesh.new()
	lm.use("Pole", LandmarkMaterials.pbr("wood", "#D9D2C5", 1.5, 0.55))
	lm.use("Canopy", LandmarkMaterials.pbr("render", str(pair[0]), 1.8, 0.86))
	lm.use("Stripe", LandmarkMaterials.pbr("render", str(pair[1]), 1.8, 0.88))
	var tilt := Vector3(-0.16, 2.18, 0.06)
	lm.beam("Pole", Vector3(0.0, -0.12, 0.0), tilt, 0.055, 0.055)
	var apex := tilt + Vector3(-0.02, 0.12, 0.01)
	for i: int in range(8):
		var a0 := TAU * float(i) / 8.0
		var a1 := TAU * float(i + 1) / 8.0
		var p0 := tilt + Vector3(cos(a0) * 1.10, -0.24, sin(a0) * 1.10)
		var p1 := tilt + Vector3(cos(a1) * 1.10, -0.24, sin(a1) * 1.10)
		var k := "Canopy" if (i % 2 == 0) else "Stripe"
		var n := (p1 - apex).cross(p0 - apex).normalized()
		n = -n if n.y < 0.0 else n
		lm.tri(k, apex, p0, p1, n, n, n, Vector2(0.5, 0.5), Vector2(0, 0), Vector2(1, 0))
		lm.tri(k, apex, p1, p0, -n, -n, -n, Vector2(0.5, 0.5), Vector2(1, 0), Vector2(0, 0))
		lm.quad(k, p0, p1, p1 + Vector3(0, -0.09, 0), p0 + Vector3(0, -0.09, 0))
	for sz: float in [-0.92, 0.92]:
		lm.box("Stripe", Vector3(0.18, 0.28, sz), Vector3(1.32, 0.07, 0.64), Basis(), 0.01)
		lm.box("Canopy", Vector3(0.20, 0.33, sz), Vector3(1.24, 0.05, 0.56), Basis(), 0.01)
		var back_b := Basis(Vector3.FORWARD, 0.48)
		lm.box("Stripe", Vector3(-0.66, 0.48, sz), Vector3(0.62, 0.06, 0.62), back_b, 0.01)
		lm.box("Canopy", Vector3(-0.64, 0.52, sz), Vector3(0.56, 0.05, 0.54), back_b, 0.01)
		for lx: float in [-0.72, 0.68]:
			for lz: float in [-0.26, 0.26]:
				lm.box("Pole", Vector3(lx, 0.13, sz + lz), Vector3(0.05, 0.28, 0.05), Basis(), 0.0)
	return lm.to_array_mesh()

static func _dune_post_mesh() -> ArrayMesh:
	var lm := LandmarkMesh.new()
	lm.use("Post", LandmarkMaterials.pbr("wood", "#7A6248", 1.5))
	lm.use("Rope", LandmarkMaterials.pbr("limestone", "#C9B793", 1.2, 0.92))
	for sz: float in [-1.42, 0.0, 1.42]:
		lm.frustum("Post", Vector3(0.0, -0.12, sz), 0.065, 0.055, 1.16, 6)
	for y: float in [0.44, 0.84]:
		lm.beam("Rope", Vector3(0.0, y, -1.46), Vector3(0.0, y - 0.04, 0.0), 0.032, 0.032)
		lm.beam("Rope", Vector3(0.0, y - 0.04, 0.0), Vector3(0.0, y, 1.46), 0.032, 0.032)
	return lm.to_array_mesh()

static func _dune_oats_mesh() -> ArrayMesh:
	var lm := LandmarkMesh.new()
	lm.use("Blade", LandmarkMaterials.pbr("grass", "#798F4E", 1.5, 0.90))
	lm.use("Plume", LandmarkMaterials.pbr("sand", "#D2BC82", 1.2, 0.88))
	for i: int in range(7):
		var a := TAU * float(i) / 7.0 + 0.2
		var dir := Vector3(cos(a), 0.0, sin(a))
		var side := Vector3(-dir.z, 0.0, dir.x) * 0.055
		var h := 0.58 + float(i % 3) * 0.14
		var base := dir * 0.08
		var tip := dir * (0.42 + float(i % 2) * 0.12) + Vector3(0.0, h, 0.0)
		var n := (tip - base).cross(side).normalized()
		lm.tri("Blade", base - side, base + side, tip, n, n, n, Vector2.ZERO, Vector2(0.1, 0), Vector2(0.05, h))
		lm.tri("Blade", base + side, base - side, tip, -n, -n, -n, Vector2(0.1, 0), Vector2.ZERO, Vector2(0.05, h))
	for i: int in range(3):
		var a := TAU * float(i) / 3.0 + 0.55
		var dir := Vector3(cos(a), 0.0, sin(a))
		var top := dir * 0.34 + Vector3(0.0, 0.92, 0.0)
		lm.beam("Plume", dir * 0.05, top, 0.022, 0.022)
		lm.box("Plume", top + dir * 0.06 + Vector3(0.0, 0.05, 0.0), Vector3(0.07, 0.22, 0.05), Basis(), 0.0)
	return lm.to_array_mesh(false)

static func _volleyball_mesh() -> ArrayMesh:
	var lm := LandmarkMesh.new()
	lm.use("Pole", LandmarkMaterials.paint("#D8DCE0", 0.45, 0.45))
	lm.use("Tape", LandmarkMaterials.pbr("render", "#F7F5EE", 1.5, 0.82))
	lm.use("Net", LandmarkMaterials.paint("#2A3036", 0.78, 0.10))
	lm.use("Line", LandmarkMaterials.pbr("render", "#2884C8", 1.5, 0.88))
	for sz: float in [-4.5, 4.5]:
		lm.frustum("Pole", Vector3(0.0, -0.15, sz), 0.055, 0.05, 2.62, 8)
	lm.box("Tape", Vector3(0.0, 2.40, 0.0), Vector3(0.04, 0.08, 8.96), Basis(), 0.0)
	lm.box("Tape", Vector3(0.0, 1.42, 0.0), Vector3(0.035, 0.05, 8.96), Basis(), 0.0)
	for y: float in [1.62, 1.82, 2.02, 2.20]:
		lm.box("Net", Vector3(0.0, y, 0.0), Vector3(0.02, 0.02, 8.92), Basis(), 0.0)
	for k: int in range(-8, 9):
		lm.box("Net", Vector3(0.0, 1.91, float(k) * 0.52), Vector3(0.02, 0.94, 0.02), Basis(), 0.0)
	for sx: float in [-8.0, 8.0]:
		lm.box("Line", Vector3(sx, 0.025, 0.0), Vector3(0.07, 0.02, 8.0), Basis(), 0.0)
	for sz: float in [-4.0, 4.0]:
		lm.box("Line", Vector3(0.0, 0.025, sz), Vector3(16.0, 0.02, 0.07), Basis(), 0.0)
	return lm.to_array_mesh()

static func _promenade_wall_mesh() -> ArrayMesh:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("limestone", "#EAE1CF", 2.2))
	lm.use("Cap", LandmarkMaterials.pbr("render", "#F4EEE2", 1.8))
	lm.box("Wall", Vector3(0.0, 0.22, 0.0), Vector3(0.40, 0.68, 3.16), Basis(), 0.03)
	lm.box("Cap", Vector3(0.0, 0.60, 0.0), Vector3(0.50, 0.10, 3.22), Basis(), 0.03)
	return lm.to_array_mesh()

static func _contact_quad() -> PlaneMesh:
	if _shadow_quad == null:
		var p := PlaneMesh.new()
		p.size = Vector2.ONE
		p.center_offset = Vector3(0.0, 0.025, 0.0)
		p.material = CarPaint.shadow_material()
		_shadow_quad = p
	return _shadow_quad

static func _add_contact_shadows(holder: Node3D, by_mesh: Dictionary, m2u: float) -> void:
	var xfs: Array[Transform3D] = []
	for k_var: Variant in by_mesh:
		var key := str(k_var)
		var fam := "lifeguard" if key.begins_with("lifeguard_") else ("umbrella" if key.begins_with("umbrella_") else key)
		if not SHADOW_FOOTPRINT.has(fam):
			continue
		var sz: Vector2 = SHADOW_FOOTPRINT[fam]
		var scale_b := Basis.from_scale(Vector3(sz.x, 1.0, sz.y))
		for t_v: Variant in (by_mesh[key] as Array):
			var t: Transform3D = t_v
			xfs.append(Transform3D(t.basis * scale_b, t.origin))
	if xfs.is_empty():
		return
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = _contact_quad()
	mm.instance_count = xfs.size()
	for i: int in range(xfs.size()):
		mm.set_instance_transform(i, xfs[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.name = "BeachShadows"
	mmi.multimesh = mm
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mmi.set_meta("lod_own", true)
	mmi.visibility_range_end = 220.0 * m2u
	holder.add_child(mmi)
