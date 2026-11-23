class_name RailViaductLook
extends RefCounted

## Zone-and-class viaduct look selector and elevated precast-concrete guideway
## geometry (hammerhead columns, flared pier caps, central monorail guide beams,
## and elevated rapid-transit stations) for modern concrete transit viaducts
## such as Miami's Metrorail / Metromover and Singapore's MRT / LRT, while
## preserving classic brick-fascia viaducts everywhere else.

const GUIDEWAY_CITIES := ["miami", "singapore"]
const GUIDEWAY_CLASSES := ["subway", "light_rail", "monorail"]
const MIAMI_LAT_MIN := 25.55
const MIAMI_LAT_MAX := 26.05
const MIAMI_LON_MIN := -80.45
const MIAMI_LON_MAX := -80.05

const PIER_PITCH_M := 28.0
const MONORAIL_BEAM_W_M := 0.45
const MONORAIL_BEAM_H_M := 0.38
const PLATFORM_LIFT_M := 1.05
const PLATFORM_THICK_M := 0.44
const CANOPY_CLEAR_M := 4.2
const CANOPY_RISE_M := 0.72
const METROMOVER_LEN_M := 32.0
const METRORAIL_LEN_M := 90.0
const STATION_MATCH_M := 24.0
const STATION_DEDUP_M := 42.0

## Returns `"concrete_guideway"` for elevated rapid transit (`subway`,
## `light_rail`, `monorail`) in Miami or Singapore, else `"brick"`.
static func look_for(data: LocationData, rail_class: String) -> String:
	if data == null or not (rail_class in GUIDEWAY_CLASSES):
		return "brick"
	var zone := CityStyles.zone_at(data.latitude, data.longitude)
	var city := "" if zone.is_empty() else str(zone[0])
	var in_miami_box := data.latitude >= MIAMI_LAT_MIN and data.latitude <= MIAMI_LAT_MAX \
		and data.longitude >= MIAMI_LON_MIN and data.longitude <= MIAMI_LON_MAX
	if city in GUIDEWAY_CITIES or in_miami_box:
		return "concrete_guideway"
	return "brick"

## True when `data` lies in a concrete-guideway transit zone.
static func has_guideways(data: LocationData) -> bool:
	return look_for(data, "subway") == "concrete_guideway"

## Elevated layer passed to `RoadBuilder.deck_profile`: `>= 1` for concrete
## guideways (~5 m per layer above ground), and exact `0` for `"brick"`.
static func bridge_layer(way: Dictionary, look: String) -> int:
	if look == "concrete_guideway":
		return maxi(int(way.get("layer", 1)), 1)
	return 0

## Places precast concrete hammerhead columns + flared pier caps every 28.0 m
## on dry land, skipping water and ground roads via RoadBridgeBuild._on_road_below.
static func add_guideway_piers(side: RoadBuilder._Batch, pts: PackedVector2Array,
		deck: PackedFloat32Array, surf: RoadBuilder._Surface, m2u: float) -> void:
	var n_pts := pts.size()
	if n_pts < 2 or deck.size() != n_pts:
		return
	var dist := RoadBridgeBuild._dist_of(pts)
	var next := 14.0 * m2u
	for i in range(1, n_pts - 1):
		if dist[i] < next:
			continue
		var p := pts[i]
		if RoadBridgeBuild._on_road_below(p, surf, m2u):
			continue
		next = dist[i] + PIER_PITCH_M * m2u
		if surf.ground.water_at(p.x, p.y) > 0.0:
			continue
		var low := surf.height(p.x, p.y) - 0.12 * m2u
		var soffit := deck[i] - RoadBuilder.DECK_DEPTH_M * m2u
		if soffit <= low + 1.1 * m2u:
			continue
		var cap_h := minf(0.85 * m2u, (soffit - low) * 0.32)
		var shaft_top := soffit - cap_h
		var d := (pts[i + 1] - pts[i - 1]).normalized()
		var n := Vector2(-d.y, d.x)
		_frustum_box(side, p, d, n, 0.56 * m2u, 0.64 * m2u, low, 0.52 * m2u, 0.60 * m2u, shaft_top)
		_frustum_box(side, p, d, n, 0.52 * m2u, 0.60 * m2u, shaft_top, 0.78 * m2u, 1.75 * m2u, soffit)

## Builds the raised central guide beam (0.45 m wide, 0.38 m tall) along
## automated people-mover / monorail concrete guideways (Miami Metromover).
static func add_monorail_beam(batch: RoadBuilder._Batch, pts: PackedVector2Array,
		deck: PackedFloat32Array, m2u: float) -> void:
	var n_pts := pts.size()
	if n_pts < 2 or deck.size() != n_pts:
		return
	batch.pad()
	var k_start := batch.verts.size()
	var hw := MONORAIL_BEAM_W_M * 0.5 * m2u
	var bh := MONORAIL_BEAM_H_M * m2u
	var k0 := batch.verts.size()
	var along := 0.0
	for i in n_pts:
		if i > 0:
			along += pts[i].distance_to(pts[i - 1])
		var s := RoadBuilder._side(pts, i) * hw
		var l := pts[i] + s
		var r := pts[i] - s
		var y_top := deck[i] + bh
		batch.verts.append(Vector3(l.x, y_top, l.y))
		batch.verts.append(Vector3(r.x, y_top, r.y))
		batch.normals.append(Vector3.UP)
		batch.normals.append(Vector3.UP)
		batch.uvs.append(Vector2(0.0, along / m2u))
		batch.uvs.append(Vector2(1.0, along / m2u))
	for i in n_pts - 1:
		var a := k0 + i * 2
		RoadBuilder._quad_up(batch, a, a + 1, a + 2, a + 3)
		var sa := RoadBuilder._side(pts, i).normalized()
		var sb := RoadBuilder._side(pts, i + 1).normalized()
		for sgn: float in [1.0, -1.0]:
			var pa := pts[i] + RoadBuilder._side(pts, i) * hw * sgn
			var pb := pts[i + 1] + RoadBuilder._side(pts, i + 1) * hw * sgn
			RoadBuilder._wall(batch, pa, pb, deck[i], deck[i + 1],
				deck[i] + bh, deck[i + 1] + bh, sa * sgn, true)
	# End caps on the beam.
	for end_i in [0, n_pts - 1]:
		var s := RoadBuilder._side(pts, end_i) * hw
		var dir := (pts[1] - pts[0]).normalized() if end_i == 0 else (pts[n_pts - 1] - pts[n_pts - 2]).normalized()
		var out_dir := -dir if end_i == 0 else dir
		RoadBuilder._wall(batch, pts[end_i] - s, pts[end_i] + s,
			deck[end_i], deck[end_i], deck[end_i] + bh, deck[end_i] + bh, out_dir, true)
	batch.pad()
	for i in range(k_start, batch.verts.size()):
		batch.uv2s[i] = Vector2(0.0, RailBuilder.BED_LAYER + 0.1)

## Builds elevated concrete station platform slabs (1.05 m above rail deck),
## slender support columns, and sleek arched white canopy roofs (4.2 m above
## platform, ~32 m for Metromover and ~90 m for Metrorail) at mapped
## `rail_platforms` and `rail_stations` near elevated `concrete_guideway` tracks.
static func build_elevated_stations(batches: Dictionary, data: LocationData,
		surf: RoadBuilder._Surface, decks: RailDecks, m2u: float) -> void:
	if data == null or (data.rail_platforms.is_empty() and data.rail_stations.is_empty()):
		return
	var tracks := _collect_guideways(data, surf, decks, m2u)
	if tracks.is_empty():
		return
	var placed := PackedVector2Array()
	var conc := RoadBuilder._batch(batches, "deck_concrete")
	var canopy := RoadBuilder._batch(batches, "station_canopy")

	# 1. Mapped platform ways/polygons beside elevated guideways.
	for raw in data.rail_platforms:
		if not (raw is Dictionary):
			continue
		var pts: PackedVector2Array = (raw as Dictionary).get("points", PackedVector2Array())
		if pts.size() < 2:
			continue
		var ext := _farthest_pair(pts)
		var mid: Vector2 = (ext[0] + ext[1]) * 0.5
		if not surf.inside(mid) or _near_any(placed, mid, STATION_DEDUP_M * m2u):
			continue
		var hit := _nearest_guideway(tracks, mid, STATION_MATCH_M * m2u)
		if hit.is_empty() or float(hit["deck_y"]) - surf.height(mid.x, mid.y) < 2.0 * m2u:
			continue
		var cls := str(hit["class"])
		var def_len := (METROMOVER_LEN_M if cls == "monorail" else METRORAIL_LEN_M) * m2u
		var length := clampf((ext[0] as Vector2).distance_to(ext[1]), 18.0 * m2u, def_len * 1.25)
		var dir: Vector2 = hit["dir"]
		var n := Vector2(-dir.y, dir.x)
		var track_pt: Vector2 = hit["pt"]
		var side_off := (mid - track_pt).dot(n)
		var plat_center := mid
		if absf(side_off) < 2.2 * m2u:
			plat_center = track_pt + n * (3.6 * m2u * (1.0 if side_off >= 0.0 else -1.0))
		var plat_w := (4.4 if cls == "monorail" else 5.6) * m2u
		var canopy_center := (plat_center + track_pt) * 0.5
		var canopy_w := maxf(plat_w + 4.2 * m2u, absf((plat_center - track_pt).dot(n)) + plat_w * 0.5 + 2.4 * m2u)
		_emit_station(conc, canopy, surf, plat_center, canopy_center, dir, length, plat_w, canopy_w,
			float(hit["deck_y"]), m2u)
		placed.append(track_pt)

	# 2. Station nodes beside elevated guideways (when not already covered).
	for raw in data.rail_stations:
		if not (raw is Dictionary):
			continue
		var st := raw as Dictionary
		var p := Vector2(float(st.get("x", 0.0)), float(st.get("z", 0.0)))
		if not surf.inside(p) or _near_any(placed, p, STATION_DEDUP_M * m2u):
			continue
		var hit := _nearest_guideway(tracks, p, STATION_MATCH_M * m2u)
		if hit.is_empty():
			continue
		var track_pt: Vector2 = hit["pt"]
		var deck_y := float(hit["deck_y"])
		if deck_y - surf.height(track_pt.x, track_pt.y) < 2.0 * m2u \
				or _near_any(placed, track_pt, STATION_DEDUP_M * m2u):
			continue
		var cls := str(hit["class"])
		var dir: Vector2 = hit["dir"]
		var n := Vector2(-dir.y, dir.x)
		var length := (METROMOVER_LEN_M if cls == "monorail" else METRORAIL_LEN_M) * m2u
		length = _clip_station_len(surf, track_pt, dir, length, m2u)
		if length < 16.0 * m2u:
			continue
		var mate := _sister_track(tracks, int(hit["track_idx"]), track_pt, dir, 15.0 * m2u)
		var plat_center := track_pt
		var canopy_center := track_pt
		var plat_w := (4.6 if cls == "monorail" else 5.8) * m2u
		var canopy_w := (8.8 if cls == "monorail" else 11.6) * m2u
		if not mate.is_empty():
			var mate_pt: Vector2 = mate["pt"]
			var gap := absf((mate_pt - track_pt).dot(n))
			canopy_center = (track_pt + mate_pt) * 0.5
			deck_y = maxf(deck_y, float(mate["deck_y"]))
			if gap >= 5.6 * m2u:
				plat_center = canopy_center
				plat_w = clampf(gap - 2.6 * m2u, 3.4 * m2u, 9.0 * m2u)
			else:
				var sgn := 1.0 if (p - canopy_center).dot(n) >= 0.0 else -1.0
				plat_center = canopy_center + n * (gap * 0.5 + 3.4 * m2u) * sgn
			canopy_w = maxf(canopy_w, gap + 6.4 * m2u)
		else:
			var sgn := 1.0 if (p - track_pt).dot(n) >= 0.0 else -1.0
			plat_center = track_pt + n * (3.7 * m2u * sgn)
			canopy_center = track_pt + n * (1.5 * m2u * sgn)
		_emit_station(conc, canopy, surf, plat_center, canopy_center, dir, length, plat_w, canopy_w, deck_y, m2u)
		placed.append(canopy_center)

static func _collect_guideways(data: LocationData, surf: RoadBuilder._Surface,
		decks: RailDecks, m2u: float) -> Array:
	var out: Array = []
	for w in data.railways:
		if not (w is Dictionary) or not bool((w as Dictionary).get("bridge", false)) \
				or bool((w as Dictionary).get("tunnel", false)):
			continue
		var way := w as Dictionary
		var cls := str(way.get("class", ""))
		if look_for(data, cls) != "concrete_guideway":
			continue
		var inside := PackedVector2Array()
		for p in RoadBuilder._resample(way.get("points", PackedVector2Array()), 2.5 * m2u):
			if surf.inside(p):
				inside.append(p)
		if inside.size() < 2:
			continue
		var half := float(way.get("width_m", 3.3)) * 0.5 * m2u
		var deck := RoadBuilder.deck_profile(inside, surf, m2u, half, bridge_layer(way, "concrete_guideway"), false)
		if deck.size() != inside.size():
			continue
		if decks != null:
			deck = decks.level(inside, deck)
		out.append({"pts": inside, "deck": deck, "class": cls})
	return out

static func _nearest_guideway(tracks: Array, p: Vector2, max_dist: float) -> Dictionary:
	var best_d := max_dist
	var best := {}
	for ti in tracks.size():
		var tr: Dictionary = tracks[ti]
		var pts: PackedVector2Array = tr["pts"]
		var deck: PackedFloat32Array = tr["deck"]
		for i in pts.size() - 1:
			var a := pts[i]
			var b := pts[i + 1]
			var ab := b - a
			var len_sq := ab.length_squared()
			if len_sq < 1e-6:
				continue
			var t := clampf((p - a).dot(ab) / len_sq, 0.0, 1.0)
			var q := a + ab * t
			var d := p.distance_to(q)
			if d < best_d:
				best_d = d
				best = {"pt": q, "dir": ab.normalized(), "deck_y": lerpf(deck[i], deck[i + 1], t),
					"class": tr["class"], "track_idx": ti}
	return best

static func _sister_track(tracks: Array, skip_idx: int, p: Vector2, dir: Vector2, max_gap: float) -> Dictionary:
	var best_d := max_gap
	var best := {}
	for ti in tracks.size():
		if ti == skip_idx:
			continue
		var tr: Dictionary = tracks[ti]
		var pts: PackedVector2Array = tr["pts"]
		var deck: PackedFloat32Array = tr["deck"]
		for i in pts.size() - 1:
			var a := pts[i]
			var b := pts[i + 1]
			var ab := b - a
			if ab.length_squared() < 1e-6 or absf(ab.normalized().dot(dir)) < 0.85:
				continue
			var q := Geometry2D.get_closest_point_to_segment(p, a, b)
			var d := p.distance_to(q)
			if d > 1.2 and d < best_d and absf((q - p).dot(dir)) < 3.0:
				best_d = d
				var t := clampf((q - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
				best = {"pt": q, "deck_y": lerpf(deck[i], deck[i + 1], t)}
	return best

static func _clip_station_len(surf: RoadBuilder._Surface, center: Vector2, dir: Vector2,
		want_len: float, m2u: float) -> float:
	var half := want_len * 0.5
	while half > 10.0 * m2u:
		if surf.inside(center + dir * half) and surf.inside(center - dir * half):
			return half * 2.0
		half -= 4.0 * m2u
	return half * 2.0

static func _near_any(pts: PackedVector2Array, p: Vector2, tol: float) -> bool:
	for q in pts:
		if q.distance_to(p) < tol:
			return true
	return false

static func _farthest_pair(pts: PackedVector2Array) -> Array:
	var a := pts[0]
	var b := pts[pts.size() - 1]
	var best := -1.0
	for i in pts.size():
		for j in range(i + 1, pts.size()):
			var d := pts[i].distance_squared_to(pts[j])
			if d > best:
				best = d
				a = pts[i]
				b = pts[j]
	return [a, b]

## Emits elevated concrete platform slab + ground columns + sleek vaulted white canopy.
static func _emit_station(conc: RoadBuilder._Batch, canopy: RoadBuilder._Batch,
		surf: RoadBuilder._Surface, plat_c: Vector2, roof_c: Vector2, dir: Vector2,
		length: float, plat_w: float, canopy_w: float, deck_y: float, m2u: float) -> void:
	var n := Vector2(-dir.y, dir.x)
	var hl := length * 0.5
	var hpw := plat_w * 0.5
	var plat_top := deck_y + PLATFORM_LIFT_M * m2u
	var plat_bot := plat_top - PLATFORM_THICK_M * m2u
	# Elevated platform slab + low safety parapet on outer edge.
	_frustum_box(conc, plat_c, dir, n, hl, hpw, plat_bot, hl, hpw, plat_top, true, true)
	# Slender ground columns under the platform slab (skipping water and ground roads).
	var col_step := 18.0 * m2u
	var n_cols := maxi(2, int(round(length / col_step)) + 1)
	for k in n_cols:
		var u := lerpf(-hl + 3.5 * m2u, hl - 3.5 * m2u, float(k) / float(maxi(n_cols - 1, 1)))
		var cp := plat_c + dir * u
		if surf.inside(cp) and surf.ground.water_at(cp.x, cp.y) <= 0.0 \
				and not RoadBridgeBuild._on_road_below(cp, surf, m2u):
			var g_y := surf.height(cp.x, cp.y) - 0.12 * m2u
			if plat_bot > g_y + 0.8 * m2u:
				_frustum_box(conc, cp, dir, n, 0.44 * m2u, 0.48 * m2u, g_y,
					0.40 * m2u, 0.44 * m2u, plat_bot)
	# Slender canopy spine columns rising from platform slab to canopy eaves/spine.
	var eave_y := plat_top + CANOPY_CLEAR_M * m2u
	var crown_y := eave_y + CANOPY_RISE_M * m2u
	var spine_posts := maxi(2, int(round(length / (12.0 * m2u))) + 1)
	for k in spine_posts:
		var u := lerpf(-hl + 3.0 * m2u, hl - 3.0 * m2u, float(k) / float(maxi(spine_posts - 1, 1)))
		var sp := plat_c + dir * u
		_frustum_box(canopy, sp, dir, n, 0.16 * m2u, 0.16 * m2u, plat_top,
			0.14 * m2u, 0.14 * m2u, eave_y + 0.15 * m2u)
		# Transverse cantilever cross-arm supporting the canopy shell.
		_frustum_box(canopy, roof_c + dir * u, dir, n, 0.14 * m2u, canopy_w * 0.46,
			eave_y - 0.12 * m2u, 0.14 * m2u, canopy_w * 0.48, eave_y + 0.06 * m2u, true, true)
	# Sleek 4-panel segmented barrel-vault station canopy roof (top + soffit + fascias).
	var hcw := canopy_w * 0.5
	var roof_hl := hl + 1.2 * m2u
	var thick := 0.16 * m2u
	var segs := 4
	for s in segs:
		var f0 := -1.0 + 2.0 * float(s) / float(segs)
		var f1 := -1.0 + 2.0 * float(s + 1) / float(segs)
		var y0 := crown_y - (crown_y - eave_y) * f0 * f0
		var y1 := crown_y - (crown_y - eave_y) * f1 * f1
		var p_a0 := roof_c - dir * roof_hl + n * (hcw * f0)
		var p_a1 := roof_c - dir * roof_hl + n * (hcw * f1)
		var p_b0 := roof_c + dir * roof_hl + n * (hcw * f0)
		var p_b1 := roof_c + dir * roof_hl + n * (hcw * f1)
		_roof_strip(canopy, p_a0, p_a1, p_b0, p_b1, y0, y1, thick, m2u)

static func _roof_strip(b: RoadBuilder._Batch, a0: Vector2, a1: Vector2,
		b0: Vector2, b1: Vector2, y0: float, y1: float, thick: float, m2u: float) -> void:
	var len_u := a0.distance_to(b0) / maxf(m2u, 0.001) / 4.0
	var wid_u := a0.distance_to(a1) / maxf(m2u, 0.001) / 4.0
	var kt := b.verts.size()
	b.verts.push_back(Vector3(a0.x, y0, a0.y))
	b.verts.push_back(Vector3(a1.x, y1, a1.y))
	b.verts.push_back(Vector3(b0.x, y0, b0.y))
	b.verts.push_back(Vector3(b1.x, y1, b1.y))
	var up_n := (b.verts[kt + 2] - b.verts[kt]).cross(b.verts[kt + 1] - b.verts[kt]).normalized()
	if up_n.y < 0.0:
		up_n = -up_n
	for q in 4:
		b.normals.append(up_n)
	b.uvs.push_back(Vector2(0.0, 0.0)); b.uvs.push_back(Vector2(wid_u, 0.0))
	b.uvs.push_back(Vector2(0.0, len_u)); b.uvs.push_back(Vector2(wid_u, len_u))
	RoadBuilder._quad_up(b, kt, kt + 1, kt + 2, kt + 3)
	# Underside soffit.
	var kb := b.verts.size()
	b.verts.push_back(Vector3(a1.x, y1 - thick, a1.y))
	b.verts.push_back(Vector3(a0.x, y0 - thick, a0.y))
	b.verts.push_back(Vector3(b1.x, y1 - thick, b1.y))
	b.verts.push_back(Vector3(b0.x, y0 - thick, b0.y))
	for q in 4:
		b.normals.append(-up_n)
	b.uvs.push_back(Vector2(0.0, 0.0)); b.uvs.push_back(Vector2(wid_u, 0.0))
	b.uvs.push_back(Vector2(0.0, len_u)); b.uvs.push_back(Vector2(wid_u, len_u))
	var front := (b.verts[kb + 2] - b.verts[kb]).cross(b.verts[kb + 1] - b.verts[kb])
	if front.y <= 0.0:
		b.indices.push_back(kb); b.indices.push_back(kb + 1); b.indices.push_back(kb + 2)
		b.indices.push_back(kb + 1); b.indices.push_back(kb + 3); b.indices.push_back(kb + 2)
	else:
		b.indices.push_back(kb); b.indices.push_back(kb + 2); b.indices.push_back(kb + 1)
		b.indices.push_back(kb + 1); b.indices.push_back(kb + 2); b.indices.push_back(kb + 3)

## Oriented tapered rectangular prism from `y0` (half-sizes hx0, hz0 along d, n)
## to `y1` (half-sizes hx1, hz1 along d, n) into `b`.
static func _frustum_box(b: RoadBuilder._Batch, c: Vector2, d: Vector2, n: Vector2,
		hx0: float, hz0: float, y0: float, hx1: float, hz1: float, y1: float,
		cap_top: bool = false, cap_bot: bool = false) -> void:
	var c0 := [c - d * hx0 - n * hz0, c + d * hx0 - n * hz0, c + d * hx0 + n * hz0, c - d * hx0 + n * hz0]
	var c1 := [c - d * hx1 - n * hz1, c + d * hx1 - n * hz1, c + d * hx1 + n * hz1, c - d * hx1 + n * hz1]
	var outs := [-n, d, n, -d]
	for s in 4:
		var s_next := (s + 1) % 4
		var a0: Vector2 = c0[s]
		var b0: Vector2 = c0[s_next]
		var b1: Vector2 = c1[s_next]
		var a1: Vector2 = c1[s]
		var k := b.verts.size()
		b.verts.push_back(Vector3(a0.x, y0, a0.y))
		b.verts.push_back(Vector3(b0.x, y0, b0.y))
		b.verts.push_back(Vector3(b1.x, y1, b1.y))
		b.verts.push_back(Vector3(a1.x, y1, a1.y))
		var out2: Vector2 = outs[s]
		var n3 := Vector3(out2.x, 0.0, out2.y)
		var fn := (b.verts[k + 2] - b.verts[k]).cross(b.verts[k + 1] - b.verts[k]).normalized()
		if fn.dot(n3) < 0.0:
			fn = -fn
		for q in 4:
			b.normals.append(fn)
		var u_len := a0.distance_to(b0)
		var v_len := maxf(y1 - y0, 0.05)
		b.uvs.push_back(Vector2(0.0, v_len)); b.uvs.push_back(Vector2(u_len, v_len))
		b.uvs.push_back(Vector2(u_len, 0.0)); b.uvs.push_back(Vector2(0.0, 0.0))
		var front := (b.verts[k + 2] - b.verts[k]).cross(b.verts[k + 1] - b.verts[k])
		if front.dot(n3) >= 0.0:
			b.indices.push_back(k); b.indices.push_back(k + 1); b.indices.push_back(k + 2)
			b.indices.push_back(k); b.indices.push_back(k + 2); b.indices.push_back(k + 3)
		else:
			b.indices.push_back(k); b.indices.push_back(k + 2); b.indices.push_back(k + 1)
			b.indices.push_back(k); b.indices.push_back(k + 3); b.indices.push_back(k + 2)
	if cap_top:
		var kt := b.verts.size()
		b.verts.push_back(Vector3((c1[0] as Vector2).x, y1, (c1[0] as Vector2).y))
		b.verts.push_back(Vector3((c1[3] as Vector2).x, y1, (c1[3] as Vector2).y))
		b.verts.push_back(Vector3((c1[1] as Vector2).x, y1, (c1[1] as Vector2).y))
		b.verts.push_back(Vector3((c1[2] as Vector2).x, y1, (c1[2] as Vector2).y))
		for q in 4:
			b.normals.append(Vector3.UP)
		b.uvs.push_back(Vector2(0.0, 0.0)); b.uvs.push_back(Vector2(hz1 * 0.5, 0.0))
		b.uvs.push_back(Vector2(0.0, hx1 * 0.5)); b.uvs.push_back(Vector2(hz1 * 0.5, hx1 * 0.5))
		RoadBuilder._quad_up(b, kt, kt + 1, kt + 2, kt + 3)
	if cap_bot:
		var kb := b.verts.size()
		b.verts.push_back(Vector3((c0[3] as Vector2).x, y0, (c0[3] as Vector2).y))
		b.verts.push_back(Vector3((c0[0] as Vector2).x, y0, (c0[0] as Vector2).y))
		b.verts.push_back(Vector3((c0[2] as Vector2).x, y0, (c0[2] as Vector2).y))
		b.verts.push_back(Vector3((c0[1] as Vector2).x, y0, (c0[1] as Vector2).y))
		for q in 4:
			b.normals.append(Vector3.DOWN)
		b.uvs.push_back(Vector2(0.0, 0.0)); b.uvs.push_back(Vector2(hz0 * 0.5, 0.0))
		b.uvs.push_back(Vector2(0.0, hx0 * 0.5)); b.uvs.push_back(Vector2(hz0 * 0.5, hx0 * 0.5))
		var f_bot := (b.verts[kb + 2] - b.verts[kb]).cross(b.verts[kb + 1] - b.verts[kb])
		if f_bot.y <= 0.0:
			b.indices.push_back(kb); b.indices.push_back(kb + 1); b.indices.push_back(kb + 2)
			b.indices.push_back(kb + 1); b.indices.push_back(kb + 3); b.indices.push_back(kb + 2)
		else:
			b.indices.push_back(kb); b.indices.push_back(kb + 2); b.indices.push_back(kb + 1)
			b.indices.push_back(kb + 1); b.indices.push_back(kb + 2); b.indices.push_back(kb + 3)
