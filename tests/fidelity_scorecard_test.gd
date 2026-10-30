extends SceneTree

## Fidelity scorecard (T8.1, docs/fidelity-scorecard.md checks a-e):
## godot --headless --script tests/fidelity_scorecard_test.gd
## Env: SCORECARD_PRESET (0-3, default 2 High), SCORECARD_OUT (report
## dir, default user://scorecard), SCORECARD_ONLY (one location key).
## Runs the real pipeline per golden location (cache first, live when
## uncached), measures the *rendered* builder output against the source
## data, and writes one Markdown report per location even when checks
## fail. Checks it cannot measure headless are BLOCKED with the reason,
## never passed. Exit 0 only when every automated check passes.
##
## Fixed sampling rules (scorecard §4, versioned here — SAMPLE_RULES):
## (a) centre + N/E/S/W at 1/3 and 2/3 of the 1200 m radius; (b/c)
## buildings sorted by distance, split into near/mid/far thirds, evenly
## spaced picks per third; (d) water: evenly spaced shoreline vertices
## and waterway centreline points inside the extent; roads: evenly spaced
## junctions (points shared by ≥2 non-tunnel roads).

const SAMPLE_RULES := "v1 2026-10-29"
const RADIUS_M := 1200.0
const LOCATIONS := [
	{"key": "paris", "name": "Paris", "lat": 48.8566, "lon": 2.3522, "dem_bar": 3.0, "urban": true},
	{"key": "interlaken", "name": "Interlaken", "lat": 46.6863, "lon": 7.8632, "dem_bar": 8.0, "urban": false},
	{"key": "banff", "name": "Banff", "lat": 51.1789, "lon": -115.5708, "dem_bar": 8.0, "urban": false},
	{"key": "bigsur", "name": "Big Sur", "lat": 36.2704, "lon": -121.8081, "dem_bar": 8.0, "urban": false},
	{"key": "turku", "name": "Turku", "lat": 60.4518, "lon": 22.2666, "dem_bar": 3.0, "urban": true},
]

func _init() -> void:
	_run()

func _run() -> void:
	var preset := int(OS.get_environment("SCORECARD_PRESET")) if OS.get_environment("SCORECARD_PRESET") != "" else 2
	var out_dir := OS.get_environment("SCORECARD_OUT")
	if out_dir == "":
		out_dir = "user://scorecard"
	DirAccess.make_dir_recursive_absolute(out_dir)
	var only := OS.get_environment("SCORECARD_ONLY")
	var all_pass := true
	var summary: Array[String] = []
	for loc in LOCATIONS:
		if only != "" and only != str(loc["key"]):
			continue
		var rep := await _score(loc, preset)
		var path := "%s/scorecard-%s-%s.md" % [out_dir, loc["key"], RenderSettings.preset_name(preset).to_lower()]
		var f := FileAccess.open(path, FileAccess.WRITE)
		if f != null:
			f.store_string("\n".join(rep["lines"]) + "\n")
		summary.append("%s: %s" % [loc["name"], " ".join(rep["verdicts"])])
		all_pass = all_pass and bool(rep["pass"])
		print("SCORECARD report ", ProjectSettings.globalize_path(path))
	for s in summary:
		print("SCORECARD ", s)
	if all_pass:
		print("SCORECARD OK: every automated check passed")
		quit(0)
	else:
		printerr("SCORECARD FAIL: see the reports (FAIL / BLOCKED rows)")
		quit(1)

# --- One location ---

func _score(loc: Dictionary, preset: int) -> Dictionary:
	var lines: Array[String] = []
	var verdicts: Array[String] = []
	var date := Time.get_date_string_from_system()
	lines.append("# Scorecard — %s — %s — %s" % [loc["name"], RenderSettings.preset_name(preset), date])
	var pipe := GenerationPipeline.new()
	root.add_child(pipe)
	await process_frame  # _ready wires the fetchers
	var box: Array = []
	pipe.finished.connect(func(d: LocationData) -> void: box.append(d))
	var t0 := Time.get_ticks_msec()
	pipe.run(float(loc["lat"]), float(loc["lon"]), str(loc["name"]), preset)
	while box.is_empty() and Time.get_ticks_msec() - t0 < 600000:
		await process_frame
	if box.is_empty():
		lines.append("- Run: pipeline did not finish in 600 s → every check BLOCKED(no data)")
		pipe.queue_free()
		return {"lines": lines, "verdicts": ["BLOCKED"], "pass": false}
	var data: LocationData = box[0]
	var fetch_ms := Time.get_ticks_msec() - t0
	pipe.queue_free()
	var t1 := Time.get_ticks_msec()
	var ground := GroundTruth.new(data)
	var buildings := BuildingBuilder.build_buildings(data, ground)
	var water := WaterBuilder.build_water(data, ground)
	var roads := RoadBuilder.build_roads(data, ground)
	lines.append("- Run: preset %s, seed %d, sample rules %s, cache data v%d, OSM %s (%d buildings, %d roads), satellite %s, DEM source z%s; pipeline %.1f s, ground+builders %.1f s"
		% [RenderSettings.preset_name(preset), data.seed_value, SAMPLE_RULES, CacheStore.DATA_VERSION,
		"real" if pipe.used_osm else "absent", data.buildings.size(), data.roads.size(),
		"real" if pipe.used_satellite else "absent", str(data.dem_source.get("source_zoom", "?")),
		fetch_ms / 1000.0, (Time.get_ticks_msec() - t1) / 1000.0])
	_osm_real = pipe.used_osm
	var ok := true
	for r in [_check_a(loc, data, ground), _check_bc(loc, data, ground, buildings),
			_check_d(data, ground, water, roads), _check_e(data)]:
		for l in r["lines"]:
			lines.append(l)
		for v in r["verdicts"]:
			verdicts.append(v)
			ok = ok and (v.ends_with("PASS") or v.ends_with("N-A"))
	lines.append("- (f) %s → %s" % ["human side-by-side rating (signed checklist, T8.3)",
		"PENDING" if str(loc["key"]) == "paris" else "NO-REFERENCE — geometry-only scoring"])
	lines.append("- AC-14 counters: BLOCKED(headless — fps/draws need a windowed run; see the T7.2 plan note)")
	buildings.free()
	water.free()
	roads.free()
	return {"lines": lines, "verdicts": verdicts, "pass": ok}

# --- (a) DEM spot heights ---

func _check_a(loc: Dictionary, data: LocationData, ground: GroundTruth) -> Dictionary:
	var pts: Array[Vector2] = [Vector2.ZERO]
	for f in [1.0 / 3.0, 2.0 / 3.0]:
		var r: float = RADIUS_M * f
		pts.append_array([Vector2(0, -r), Vector2(r, 0), Vector2(0, r), Vector2(-r, 0)])
	var max_e := 0.0
	var sum_e := 0.0
	var n := 0
	var per: Array[String] = []
	for p in pts:
		var ll := WorldScale.latlon_from_xz(p.x, p.y, data.latitude, data.longitude)
		var ref := _dem_z14(ll.x, ll.y)
		if is_nan(ref):
			return {"lines": ["- (a) DEM → BLOCKED(z14 tile not cached at %.5f, %.5f)" % [ll.x, ll.y]],
				"verdicts": ["a:BLOCKED"]}
		var got := ground.asl_y(ground.height_at_world(p.x, p.y))
		if ground.water_at(p.x, p.y) > 0.05:
			# Mapped water: the bed is carved below the surface on purpose.
			per.append("(%.0f,%.0f) water, carved %.1f m — excluded" % [p.x, p.y, got - ref])
			continue
		var e := absf(got - ref)
		per.append("(%.0f,%.0f) %+.2f" % [p.x, p.y, got - ref])
		max_e = maxf(max_e, e)
		sum_e += e
		n += 1
	var bar := float(loc["dem_bar"])
	var v := "PASS" if n >= 6 and max_e <= bar else ("BLOCKED" if n < 6 else "FAIL")
	return {"lines": ["- (a) DEM: max %.2f m / mean %.2f m over %d land points (bar ≤ %.0f m) → %s" % [max_e, sum_e / maxf(n, 1), n, bar, v],
		"  - points (x,z m: rendered − z14): " + "; ".join(per)],
		"verdicts": ["a:" + v]}

## Independent z14 Terrarium sample (bilinear) from the v2 tile cache.
func _dem_z14(lat: float, lon: float) -> float:
	var n := float(1 << 14)
	var gx := (lon + 180.0) / 360.0 * n * 256.0 - 0.5
	var gy := (1.0 - asinh(tan(deg_to_rad(lat))) / PI) / 2.0 * n * 256.0 - 0.5
	var x0 := floori(gx)
	var y0 := floori(gy)
	var v := [[0.0, 0.0], [0.0, 0.0]]
	for dy in 2:
		for dx in 2:
			var px := x0 + dx
			var py := y0 + dy
			var img := _tile(px / 256, py / 256)
			if img == null:
				return NAN
			var c := img.get_pixel(px % 256, py % 256)
			v[dy][dx] = (c.r8 * 256.0 + c.g8 + c.b8 / 256.0) - 32768.0
	var tx := gx - float(x0)
	var ty := gy - float(y0)
	return lerpf(lerpf(v[0][0], v[0][1], tx), lerpf(v[1][0], v[1][1], tx), ty)

var _tiles := {}
var _osm_real := true

func _tile(x: int, y: int) -> Image:
	var key := Vector2i(x, y)
	if not _tiles.has(key):
		var path := CacheStore.dem_path(14, x, y)
		var img: Image = null
		if FileAccess.file_exists(path):
			img = Image.new()
			if img.load(path) != OK:
				img = null
		_tiles[key] = img
	return _tiles[key]

# --- (b) footprints + (c) heights, measured on the rendered roofs ---

func _check_bc(loc: Dictionary, data: LocationData, ground: GroundTruth, built: Node3D) -> Dictionary:
	var want := 20 if bool(loc["urban"]) else 10
	var sample := _building_sample(data, want)
	if sample.is_empty():
		return {"lines": ["- (b) footprints → BLOCKED(no OSM buildings in the extent)",
			"- (c) heights → BLOCKED(no OSM buildings in the extent)"], "verdicts": ["b:BLOCKED", "c:BLOCKED"]}
	var tris := _roof_triangles(built, sample)
	var ious: Array = []
	var offsets: Array = []
	var errs: Array = []
	var tagged := 0
	var per_c: Array[String] = []
	var ctx := BuildingHeights._height_context(data)
	for b in sample:
		var poly: PackedVector2Array = b["footprint"]
		var m := _measure(poly, tris)
		ious.append(m["iou"])
		offsets.append(m["offset"])
		var expect := _expected_height(b, ctx)
		if expect > 0.0:
			tagged += 1
			if m["top"] > -INF:
				# OSM height is from the lowest ground at the footprint
				# (the builder's wall base, before its 0.6 m sink).
				var base := INF
				for q in poly:
					base = minf(base, ground.height_at_world(q.x, q.y))
				var got := float(m["top"]) - base
				errs.append(absf(got - expect))
				per_c.append("%s %.1f→%.1f m" % [str(b.get("height_source", "")), expect, got])
			else:
				errs.append(expect)  # fail-closed: nothing rendered
				per_c.append("%s %.1f→none" % [str(b.get("height_source", "")), expect])
	var iou := _median(ious)
	var off := _median(offsets)
	var urban := bool(loc["urban"])
	var vb := "PASS" if iou >= (0.85 if urban else 0.75) and off <= 2.0 else "FAIL"
	var lines: Array[String] = ["- (b) footprints: median IoU %.3f, centroid offset %.2f m over %d sampled (bar IoU ≥ %.2f, ≤ 2 m) → %s"
		% [iou, off, sample.size(), 0.85 if urban else 0.75, vb]]
	var vc := "BLOCKED"
	if errs.is_empty():
		lines.append("- (c) heights: coverage 0/%d with height/levels tags → BLOCKED(no tagged sample)" % sample.size())
	else:
		var med := _median(errs)
		vc = "PASS" if med <= 3.0 else "FAIL"
		lines.append("- (c) heights: median err %.2f m, coverage %d/%d tagged (bar ≤ 3 m ≈ 1 storey) → %s"
			% [med, tagged, sample.size(), vc])
		lines.append("  - tagged (source expected→rendered): " + "; ".join(per_c))
	return {"lines": lines, "verdicts": ["b:" + vb, "c:" + vc]}

func _building_sample(data: LocationData, want: int) -> Array:
	var inside: Array = []
	for b in data.buildings:
		if b is Dictionary and (b as Dictionary).has("footprint") \
				and (b["footprint"] as PackedVector2Array).size() >= 3:
			var c := _centroid(b["footprint"])
			if absf(c.x) < RADIUS_M - 20.0 and absf(c.y) < RADIUS_M - 20.0:
				inside.append(b)
	inside.sort_custom(func(p: Dictionary, q: Dictionary) -> bool:
		return _centroid(p["footprint"]).length() < _centroid(q["footprint"]).length())
	var out: Array = []
	if inside.is_empty():
		return out
	var per := ceili(float(want) / 3.0)
	for band in 3:
		var lo := band * inside.size() / 3
		var hi := (band + 1) * inside.size() / 3
		var n := mini(per, hi - lo)
		for i in n:
			if out.size() < want:
				out.append(inside[lo + int((float(i) + 0.5) * float(hi - lo) / float(n))])
	return out

## Upward-facing triangles (XZ + Y) of every building mesh near a sample.
func _roof_triangles(built: Node3D, sample: Array) -> Array:
	var boxes: Array[Rect2] = []
	for b in sample:
		var r := Rect2((b["footprint"] as PackedVector2Array)[0], Vector2.ZERO)
		for q in (b["footprint"] as PackedVector2Array):
			r = r.expand(q)
		boxes.append(r.grow(12.0))
	var out: Array = []
	for c in built.get_children():
		if not (c is MeshInstance3D) or str(c.get_meta("lod_layer", "Buildings")) != "Buildings":
			continue
		var mi := c as MeshInstance3D
		for s in mi.mesh.get_surface_count():
			var a := mi.mesh.surface_get_arrays(s)
			var v: PackedVector3Array = a[Mesh.ARRAY_VERTEX]
			var idx: PackedInt32Array = a[Mesh.ARRAY_INDEX] if a[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
			var count := idx.size() if not idx.is_empty() else v.size()
			for t in range(0, count - 2, 3):
				var p0 := mi.transform * v[idx[t] if not idx.is_empty() else t]
				var p1 := mi.transform * v[idx[t + 1] if not idx.is_empty() else t + 1]
				var p2 := mi.transform * v[idx[t + 2] if not idx.is_empty() else t + 2]
				var nrm := (p1 - p0).cross(p2 - p0)
				if nrm.length_squared() < 1e-8 or absf(nrm.normalized().y) < 0.2:
					continue
				var tb := Rect2(Vector2(p0.x, p0.z), Vector2.ZERO).expand(Vector2(p1.x, p1.z)).expand(Vector2(p2.x, p2.z))
				for bx in boxes:
					if bx.intersects(tb):
						out.append([p0, p1, p2, tb])
						break
	return out

## IoU of the OSM footprint vs. the rendered roof cover on a 1 m grid,
## the rendered cover's centroid offset, and the highest roof point.
func _measure(poly: PackedVector2Array, tris: Array) -> Dictionary:
	var box := Rect2(poly[0], Vector2.ZERO)
	for q in poly:
		box = box.expand(q)
	box = box.grow(10.0)
	# Attribution: only roof triangles whose centroid lies inside this
	# footprint belong to it (party-wall neighbours fill the margin).
	var near: Array = []
	for t in tris:
		if (t[3] as Rect2).intersects(box):
			var a3: Vector3 = (t[0] + t[1] + t[2]) / 3.0
			if Geometry2D.is_point_in_polygon(Vector2(a3.x, a3.z), poly):
				near.append(t)
	var inter := 0
	var union := 0
	var sum := Vector2.ZERO
	var cover_n := 0
	var osm_sum := Vector2.ZERO
	var osm_n := 0
	var top := -INF
	var y := box.position.y + 0.5
	while y < box.end.y:
		var x := box.position.x + 0.5
		while x < box.end.x:
			var p := Vector2(x, y)
			var in_osm := Geometry2D.is_point_in_polygon(p, poly)
			var hit := -INF
			for t in near:
				var a: Vector3 = t[0]
				var b: Vector3 = t[1]
				var c: Vector3 = t[2]
				if (t[3] as Rect2).has_point(p) and Geometry2D.point_is_inside_triangle(p,
						Vector2(a.x, a.z), Vector2(b.x, b.z), Vector2(c.x, c.z)):
					hit = maxf(hit, maxf(a.y, maxf(b.y, c.y)))
			var in_r := hit > -INF
			if in_r and in_osm:
				inter += 1
				top = maxf(top, hit)
			if in_r or in_osm:
				union += 1
			if in_osm:
				osm_sum += p
				osm_n += 1
			if in_r:
				sum += p
				cover_n += 1
			x += 1.0
		y += 1.0
	if cover_n == 0:
		return {"iou": 0.0, "offset": 10.0, "top": -INF}
	return {"iou": float(inter) / float(maxi(union, 1)),
		"offset": (sum / float(cover_n)).distance_to(osm_sum / float(maxi(osm_n, 1))), "top": top}

func _expected_height(b: Dictionary, ctx: Dictionary) -> float:
	var src := str(b.get("height_source", ""))
	if src == "tag_height":
		return float(b.get("height", 0.0))
	if src == "levels" and int(b.get("levels", 0)) > 0:
		var look := BuildingHeights._look_for(b, ctx)
		return float(b["levels"]) * float(look["floor_h"])
	return 0.0

# --- (d) water + roads ---

func _check_d(data: LocationData, ground: GroundTruth, water: Node3D, roads: Node3D) -> Dictionary:
	var lines: Array[String] = []
	var verdicts: Array[String] = []
	if not _osm_real:
		return {"lines": ["- (d) water + roads → BLOCKED(data-unavailable — OSM fetch failed; geometry-only scoring)"],
			"verdicts": ["d-water:BLOCKED", "d-roads:BLOCKED"]}
	var wpts: Array[Vector2] = []
	for l in data.land_polygons:
		if l is Dictionary and str(l.get("class", "")) == "water":
			for q in (l["points"] as PackedVector2Array):
				wpts.append(q)
	for w in data.waterways:
		if w is Dictionary and float(w.get("width_m", 0.0)) > 0.0:
			for q in (w["points"] as PackedVector2Array):
				wpts.append(q)
	wpts = _inside(wpts)
	var wtris := _tris(water, Callable(self, "_is_water"))
	if wpts.is_empty():
		var v := "PASS" if wtris.is_empty() else "FAIL"
		lines.append("- (d) water: no OSM water in the extent; rendered water triangles %d (absence check) → %s" % [wtris.size(), v])
		verdicts.append("d-water:" + v)
	else:
		var pick := _spread(wpts, 5)
		var hits := 0
		var per: Array[String] = []
		for p in pick:
			var r := _near_visible(p, wtris, 10.0, ground)
			if r["ok"]:
				hits += 1
			per.append("(%.0f,%.0f) %s" % [p.x, p.y, "visible water at %.1f m" % r["dist"] if r["ok"]
				else ("nearest water %.1f m%s" % [r["dist"], ", under terrain" if r["dist"] <= 10.0 else ""])])
		var v2 := "PASS" if hits == pick.size() else "FAIL"
		lines.append("- (d) water: %d/%d shoreline/centreline samples with visible rendered water within 10 m → %s" % [hits, pick.size(), v2])
		lines.append("  - samples: " + "; ".join(per))
		verdicts.append("d-water:" + v2)
	var junctions := _junctions(data)
	if junctions.is_empty():
		lines.append("- (d) roads → BLOCKED(no OSM road junctions in the extent)")
		verdicts.append("d-roads:BLOCKED")
		return {"lines": lines, "verdicts": verdicts}
	var rtris := _tris(roads, Callable(self, "_any"))
	# Junctions inside an OSM footprint are mapped passages under a
	# building, not rendering faults: excluded from the sample, counted.
	var open_j: Array[Vector2] = []
	var passages := 0
	for p in junctions:
		var inside := false
		for b in data.buildings:
			if b is Dictionary and b.has("footprint") and Geometry2D.is_point_in_polygon(p, b["footprint"]):
				inside = true
				break
		if inside:
			passages += 1
		else:
			open_j.append(p)
	var jp := _spread(open_j, 5)
	var ok := 0
	var worst_lift := 0.0
	for p in jp:
		var d := _nearest(p, rtris)
		if d["dist"] <= 3.0:
			ok += 1
			worst_lift = maxf(worst_lift, absf(float(d["y"]) - ground.height_at_world(p.x, p.y)))
	var vr := "PASS" if jp.size() > 0 and ok >= mini(4, jp.size()) else "FAIL"
	lines.append("- (d) roads: %d/%d junctions with a rendered ribbon within 3 m (%d of %d junctions are passages under OSM buildings, excluded); max ribbon lift %.2f m over ground (PRD flush ≤ 0.05 m — recorded, not gated: ribbons include bridges) → %s"
		% [ok, jp.size(), passages, junctions.size(), worst_lift, vr])
	verdicts.append("d-roads:" + vr)
	return {"lines": lines, "verdicts": verdicts}

func _any(_mi: MeshInstance3D) -> bool:
	return true

func _is_water(mi: MeshInstance3D) -> bool:
	var wm := WaterBuilder.real_water_material()
	return mi.material_override == wm \
		or (mi.mesh.get_surface_count() > 0 and mi.mesh.surface_get_material(0) == wm)

func _junctions(data: LocationData) -> Array[Vector2]:
	var seen := {}
	var out: Array[Vector2] = []
	for r in data.roads:
		if not (r is Dictionary) or bool(r.get("tunnel", false)):
			continue
		var own := {}
		for q in (r.get("points", PackedVector2Array()) as PackedVector2Array):
			var k := "%.1f,%.1f" % [q.x, q.y]
			if own.has(k):
				continue
			own[k] = true
			seen[k] = int(seen.get(k, 0)) + 1
			if int(seen[k]) == 2:
				out.append(q)
	return _inside(out)

func _tris(node: Node3D, keep: Callable) -> Array:
	var out: Array = []
	for c in node.get_children():
		if c is Node3D and c.get_child_count() > 0:
			out.append_array(_tris(c, keep))
		if not (c is MeshInstance3D) or (c as MeshInstance3D).mesh == null or not keep.call(c):
			continue
		var mi := c as MeshInstance3D
		var xf := mi.global_transform if mi.is_inside_tree() else mi.transform
		for s in mi.mesh.get_surface_count():
			var a := mi.mesh.surface_get_arrays(s)
			var v: PackedVector3Array = a[Mesh.ARRAY_VERTEX]
			var idx: PackedInt32Array = a[Mesh.ARRAY_INDEX] if a[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
			var count := idx.size() if not idx.is_empty() else v.size()
			for t in range(0, count - 2, 3):
				var p0 := xf * v[idx[t] if not idx.is_empty() else t]
				var p1 := xf * v[idx[t + 1] if not idx.is_empty() else t + 1]
				var p2 := xf * v[idx[t + 2] if not idx.is_empty() else t + 2]
				out.append([p0, p1, p2])
	return out

## Distance (XZ) from `p` to the nearest triangle and that triangle's
## mean height.
func _nearest(p: Vector2, tris: Array) -> Dictionary:
	var best := INF
	var y := 0.0
	for t in tris:
		var a := Vector2(t[0].x, t[0].z)
		var b := Vector2(t[1].x, t[1].z)
		var c := Vector2(t[2].x, t[2].z)
		var d := 0.0
		if not Geometry2D.point_is_inside_triangle(p, a, b, c):
			d = minf(_seg(p, a, b), minf(_seg(p, b, c), _seg(p, c, a)))
		if d < best:
			best = d
			y = (t[0].y + t[1].y + t[2].y) / 3.0
	return {"dist": best, "y": y}

## Nearest rendered water within `r` that is visible (above the
## terrain), tested 3 m inside the triangle from its nearest point: at a
## quay edge the bilinear terrain still blends in the bank top.
func _near_visible(p: Vector2, tris: Array, r: float, ground: GroundTruth) -> Dictionary:
	var nearest := INF
	for t in tris:
		var a := Vector2(t[0].x, t[0].z)
		var b := Vector2(t[1].x, t[1].z)
		var c := Vector2(t[2].x, t[2].z)
		var d := 0.0
		if not Geometry2D.point_is_inside_triangle(p, a, b, c):
			d = minf(_seg(p, a, b), minf(_seg(p, b, c), _seg(p, c, a)))
		nearest = minf(nearest, d)
		if d > r:
			continue
		var q := p
		if d > 0.0:
			q = Geometry2D.get_closest_point_to_segment(p, a, b)
			for e in [[b, c], [c, a]]:
				var qe := Geometry2D.get_closest_point_to_segment(p, e[0], e[1])
				if qe.distance_to(p) < q.distance_to(p):
					q = qe
		var cen := (a + b + c) / 3.0
		q = q.move_toward(cen, minf(3.0, q.distance_to(cen)))
		if (t[0].y + t[1].y + t[2].y) / 3.0 >= ground.height_at_world(q.x, q.y) - 0.3:
			return {"ok": true, "dist": d}
	return {"ok": false, "dist": nearest}

# --- (e) landmark bearing ---

func _check_e(data: LocationData) -> Dictionary:
	if data.landmark_type == "none" or not data.has_landmark_site:
		return {"lines": ["- (e) landmark: n/a — no registry landmark for this location → N-A"], "verdicts": ["e:N-A"]}
	var site := TerrainBuilder.landmark_world_pos(data)
	var cam := View360.spawn_xz(data)
	var cam_ll := WorldScale.latlon_from_xz(cam.x, cam.y, data.latitude, data.longitude)
	var d := site - cam
	var model_brg := fposmod(rad_to_deg(atan2(d.x, -d.y)), 360.0)
	var true_brg := _geodesic_bearing(cam_ll.x, cam_ll.y, data.landmark_lat, data.landmark_lon)
	var err := absf(wrapf(model_brg - true_brg, -180.0, 180.0))
	var v := "PASS" if err <= 1.0 else "FAIL"
	return {"lines": ["- (e) %s: bearing error %.3f° (model %.2f°, geodesic %.2f°, %.0f m; bar ≤ 1°) → %s; apparent height + AC-06 silhouette → BLOCKED(headless — needs the windowed spawn capture)"
		% [data.landmark_type, err, model_brg, true_brg, d.length(), v]], "verdicts": ["e:" + v]}

static func _geodesic_bearing(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
	var p1 := deg_to_rad(lat1)
	var p2 := deg_to_rad(lat2)
	var dl := deg_to_rad(lon2 - lon1)
	return fposmod(rad_to_deg(atan2(sin(dl) * cos(p2),
		cos(p1) * sin(p2) - sin(p1) * cos(p2) * cos(dl))), 360.0)

# --- Helpers ---

func _inside(pts: Array[Vector2]) -> Array[Vector2]:
	var out: Array[Vector2] = []
	for p in pts:
		if absf(p.x) < RADIUS_M - 20.0 and absf(p.y) < RADIUS_M - 20.0:
			out.append(p)
	return out

## `n` evenly spaced items of `a` (stable: no random sampling).
func _spread(a: Array[Vector2], n: int) -> Array[Vector2]:
	var out: Array[Vector2] = []
	var k := mini(n, a.size())
	for i in k:
		out.append(a[int((float(i) + 0.5) * float(a.size()) / float(k))])
	return out

static func _seg(p: Vector2, a: Vector2, b: Vector2) -> float:
	return p.distance_to(Geometry2D.get_closest_point_to_segment(p, a, b))

static func _centroid(poly: PackedVector2Array) -> Vector2:
	var s := Vector2.ZERO
	for q in poly:
		s += q
	return s / float(maxi(poly.size(), 1))

static func _median(a: Array) -> float:
	if a.is_empty():
		return 0.0
	var b := a.duplicate()
	b.sort()
	return float(b[b.size() / 2])
