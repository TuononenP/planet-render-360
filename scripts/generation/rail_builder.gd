class_name RailBuilder
extends RefCounted

## OSM railways as 3D track (LocationData.railways, parsed by OsmRail).
## * At grade: a ballast bed (gravel PBR, trapezoid section sized from
##   the real gauge) draped on the rendered terrain, concrete or timber
##   sleepers every 0.62 m near the viewpoint, and two steel rails (bright
##   running head, rusty web) at the tagged gauge (1435 mm default).
## * Street-running tram track (`embedded`, default for trams): grooved
##   rails flush in the carriageway, no ballast.
## * Bridges: short `bridge=yes` spans follow RoadBuilder's deck rule;
##   long or chained spans (an elevated line split into many ways) become
##   a viaduct at VIADUCT_CLEAR_M above the smoothed ground, ramping to
##   grade only at ends no other bridge track continues. North American
##   elevated lines get the riveted steel "el" look (painted girders on
##   paired columns with cross bents); elsewhere a concrete box deck on
##   single piers. Monorails are a concrete beam on piers.
## * electrified=contact_line: masts with cantilever arms and contact +
##   messenger wires near the viewpoint.
## * Tunnels / underground (tunnel, layer < 0, location=underground) are
##   never drawn. Platforms, canopies and subway entrances: RailStations
##   and SubwayEntrances. Absent in data → absent in the world.

const BALLAST_H_M := 0.35
## Sleeper length past each rail's gauge face (2.6 m sleeper on 1435).
const SLEEPER_OVERHANG_M := 0.58
const SLEEPER_W_M := 0.25
const SLEEPER_H_M := 0.16
const SLEEPER_SPACING_M := 0.62
const RAIL_HEAD_M := 0.072
const RAIL_H_M := 0.16
## Elevated (viaduct) track: deck top above the smoothed ground.
const VIADUCT_CLEAR_M := 7.5
## A bridge way at least this long (or continued by another bridge way)
## is a viaduct; shorter ones are a deck over a road or a stream.
const VIADUCT_MIN_M := 80.0
const RAMP_M := 60.0
const DECK_DEPTH_M := 1.3
const STEEL_COLUMN_SPACING_M := 15.0
const PIER_SPACING_M := 28.0
const MAST_SPACING_M := 55.0
const WIRE_H_M := 5.6
## Draw reach per preset (Fast, Balanced, High, Ultra), metres from the
## viewpoint: sleepers, rails, overhead line. Ballast and decks span the
## whole detailed extent.
const TIE_R: Array[float] = [0.0, 100.0, 200.0, 350.0]
const RAIL_R: Array[float] = [300.0, 600.0, 1200.0, 1700.0]
const WIRE_R: Array[float] = [0.0, 250.0, 450.0, 900.0]
const EXTENT := WorldScale.DETAILED_EXTENT_M * 0.5 - 2.0
## Classes that run on elevated steel in North American cities.
const EL_CLASSES := ["subway", "light_rail", "rail"]
const STEEL_COL := Color(0.29, 0.34, 0.31)
const CONCRETE_TIE := Color(0.60, 0.58, 0.54)
const TIMBER_TIE := Color(0.27, 0.21, 0.16)
const RAIL_HEAD_COL := Color(0.70, 0.70, 0.68)
const RAIL_WEB_COL := Color(0.30, 0.20, 0.14)
const WIRE_COL := Color(0.16, 0.15, 0.14)

static func has_rail(data: LocationData) -> bool:
	return not data.railways.is_empty() or not data.rail_platforms.is_empty() \
		or not data.transit_stops.is_empty()

## Railway subtree: track, decks, overhead line, then stations.
static func build_rail(data: LocationData, ground: GroundTruth = null) -> Node3D:
	if ground == null:
		ground = GroundTruth.new(data)
	var root := Node3D.new()
	root.name = "Rail"
	var surf := RoadBuilder._Surface.new(data, ground)
	var preset := RenderSettings.clamp_preset(data.quality_preset)
	var north_america := ArchitectureStyle.country_region_for(data.latitude,
		data.longitude) == "north_america"
	var bufs := {}
	for k in ["ballast", "deck", "steel", "ties", "rails", "wire"]:
		bufs[k] = TreeMeshLibrary.Buf.new()
	var ends := _bridge_ends(data.railways)
	for t in data.railways:
		if t is Dictionary:
			_track(bufs, t, surf, preset, north_america, ends)
	RailMesh.add(root, bufs["ballast"], RailMesh.pbr("gravel", "#77716a"), "Rail_ballast")
	RailMesh.add(root, bufs["deck"], RailMesh.pbr("concrete", "#a39d92"), "Rail_deck")
	RailMesh.add(root, bufs["steel"], RailMesh.colour_mat("steel", 0.45, 0.55), "Rail_el_steel")
	RailMesh.add(root, bufs["ties"], RailMesh.colour_mat("ties", 0.0, 0.9), "Rail_sleepers")
	RailMesh.add(root, bufs["rails"], RailMesh.colour_mat("rails", 0.7, 0.35), "Rail_rails")
	RailMesh.add(root, bufs["wire"], RailMesh.colour_mat("wire", 0.6, 0.5, true), "Rail_overhead")
	RailStations.build(root, data, surf, preset, ends)
	SubwayEntrances.build(root, data, surf, preset, north_america)
	return root

## Ground height averaged over a 25 m ring: viaducts and elevated
## platforms ride on this so they do not echo every DEM bump.
static func smooth_height(surf: RoadBuilder._Surface, p: Vector2) -> float:
	var acc := surf.height(p.x, p.y)
	for k in 8:
		var a := float(k) * TAU / 8.0
		acc += surf.height(p.x + cos(a) * 25.0, p.y + sin(a) * 25.0)
	return acc / 9.0

## Top of an elevated (layer ≥ 1) deck at p — shared with RailStations
## so elevated platforms meet their viaduct.
static func viaduct_top(surf: RoadBuilder._Surface, p: Vector2, layer: int) -> float:
	return smooth_height(surf, p) + VIADUCT_CLEAR_M + 6.0 * float(maxi(layer, 1) - 1)

## Endpoint -> number of bridge track ways ending there (½ m cells).
static func _bridge_ends(tracks: Array) -> Dictionary:
	var ends := {}
	for t in tracks:
		if not (t is Dictionary) or not bool((t as Dictionary).get("bridge", false)):
			continue
		var pts: PackedVector2Array = (t as Dictionary).get("points", PackedVector2Array())
		if pts.size() < 2:
			continue
		for p in [pts[0], pts[pts.size() - 1]]:
			var k := end_key(p)
			ends[k] = int(ends.get(k, 0)) + 1
	return ends

static func end_key(p: Vector2) -> Vector2i:
	return Vector2i(roundi(p.x * 2.0), roundi(p.y * 2.0))

static func _track(bufs: Dictionary, tr: Dictionary, surf: RoadBuilder._Surface,
		preset: int, north_america: bool, ends: Dictionary) -> void:
	if bool(tr.get("tunnel", false)):
		return
	var pts: PackedVector2Array = tr.get("points", PackedVector2Array())
	if pts.size() < 2:
		return
	var cls := str(tr.get("class", "rail"))
	var gauge := maxf(float(tr.get("gauge_m", 1.435)), 0.6)
	var dense := RoadBuilder._resample(pts, minf(surf.step * 0.34, 6.0))
	var monorail := cls == "monorail"
	var on_deck := bool(tr.get("bridge", false)) or monorail
	var embedded := bool(tr.get("embedded", false)) and not on_deck
	var half_top := gauge * 0.5 + SLEEPER_OVERHANG_M + 0.3
	var half_bot := half_top + 0.75
	var runs: Array = []
	if on_deck:
		var ys := _deck_profile(dense, surf, tr, ends)
		runs = _clip(dense, ys)
	else:
		for run in RoadBuilder._dry_runs(dense, surf):
			var r: PackedVector2Array = run
			var ys := PackedFloat32Array()
			for p in r:
				ys.append(surf.height(p.x, p.y))
			runs.append([r, ys])
	var service := str(tr.get("service", ""))
	var yard := service in ["yard", "siding", "spur"]
	var ballast_h := BALLAST_H_M * (0.6 if yard else 1.0)
	var tie_col := TIMBER_TIE if yard or cls in ["preserved", "narrow_gauge", "funicular"] \
		else CONCRETE_TIE
	var steel := north_america and cls in EL_CLASSES
	for run in runs:
		var rp: PackedVector2Array = run[0]
		var ry: PackedFloat32Array = run[1]
		if on_deck:
			if monorail:
				_deck(bufs["deck"], rp, ry, 0.45, 1.6, 0.0, Color.WHITE)
				_piers(bufs["deck"], rp, ry, surf, 0.0, 1.6, 20.0, 1.0, Color.WHITE)
				continue
			var hw := half_bot + 0.35
			if steel:
				_deck(bufs["steel"], rp, ry, hw, DECK_DEPTH_M + 0.3, 0.7, STEEL_COL)
				_piers(bufs["steel"], rp, ry, surf, hw - 0.35, DECK_DEPTH_M + 0.3,
					STEEL_COLUMN_SPACING_M, 0.45, STEEL_COL)
			else:
				_deck(bufs["deck"], rp, ry, hw, DECK_DEPTH_M, 0.9, Color.WHITE)
				_piers(bufs["deck"], rp, ry, surf, 0.0, DECK_DEPTH_M, PIER_SPACING_M,
					1.4, Color.WHITE)
		var top_off := 0.065 if embedded else ballast_h + 0.03
		if not embedded:
			_ballast(bufs["ballast"], rp, ry, half_top, minf(half_bot, half_top + 0.75),
				ballast_h, surf, on_deck)
		for near in _near(rp, ry, TIE_R[preset]):
			if not embedded:
				_ties(bufs["ties"], near[0], near[1], top_off, gauge + 2.0 * SLEEPER_OVERHANG_M,
					tie_col)
		for near in _near(rp, ry, RAIL_R[preset]):
			_rails(bufs["rails"], near[0], near[1], gauge, top_off, embedded)
		if str(tr.get("electrified", "")) == "contact_line":
			for near in _near(rp, ry, WIRE_R[preset]):
				_overhead(bufs["wire"], near[0], near[1], surf, top_off,
					half_top + (0.6 if on_deck else 1.2), cls == "tram" or embedded)

## Deck top heights along a bridge way: short spans arch like a road
## bridge (clearing water by 5 m); viaducts sit at VIADUCT_CLEAR_M over
## the smoothed ground and ramp down only at unconnected ends.
static func _deck_profile(pts: PackedVector2Array, surf: RoadBuilder._Surface,
		tr: Dictionary, ends: Dictionary) -> PackedFloat32Array:
	var n := pts.size()
	var dist := PackedFloat32Array([0.0])
	for i in range(1, n):
		dist.append(dist[i - 1] + pts[i].distance_to(pts[i - 1]))
	var total := maxf(dist[n - 1], 0.001)
	var orig: PackedVector2Array = tr.get("points", pts)
	var start_link := int(ends.get(end_key(orig[0]), 0)) > 1
	var end_link := int(ends.get(end_key(orig[orig.size() - 1]), 0)) > 1
	var cls := str(tr.get("class", "rail"))
	if cls == "monorail":
		# A monorail beam stays up end to end (its ways are not bridges).
		start_link = true
		end_link = true
	var ys := PackedFloat32Array()
	if cls != "monorail" and total < VIADUCT_MIN_M and not start_link and not end_link:
		var h0 := surf.height(pts[0].x, pts[0].y)
		var h1 := surf.height(pts[n - 1].x, pts[n - 1].y)
		var need := 0.0
		for i in n:
			var t := dist[i] / total
			var p := pts[i]
			var wet := surf.ground.water_at(p.x, p.y) > 0.0
			var floor_y := surf.height(p.x, p.y)
			if wet:
				floor_y = maxf(floor_y, surf.ground.water_level_at(p.x, p.y))
			var clear := 5.0 if wet else 0.6
			need = maxf(need, (floor_y + clear - lerpf(h0, h1, t))
				/ maxf(sin(PI * clampf(t, 0.02, 0.98)), 0.25))
		for i in n:
			var t := dist[i] / total
			ys.append(lerpf(h0, h1, t) + 0.05 + maxf(need, 0.0) * sin(PI * t))
		return ys
	var layer := int(tr.get("layer", 1))
	for i in n:
		var p := pts[i]
		var top := viaduct_top(surf, p, layer) if cls != "monorail" \
			else smooth_height(surf, p) + 6.0
		var ground_y := surf.height(p.x, p.y)
		var env := 1.0
		if not start_link:
			env = minf(env, smoothstep(0.0, RAMP_M, dist[i]))
		if not end_link:
			env = minf(env, smoothstep(0.0, RAMP_M, total - dist[i]))
		var y := lerpf(ground_y + 0.05, top, env)
		if surf.ground.water_at(p.x, p.y) > 0.0:
			y = maxf(y, surf.ground.water_level_at(p.x, p.y) + 6.0)
		ys.append(maxf(y, ground_y + 0.05))
	return ys

## Runs of (points, heights) inside the detailed surface.
static func _clip(pts: PackedVector2Array, ys: PackedFloat32Array) -> Array:
	var runs: Array = []
	var cp := PackedVector2Array()
	var cy := PackedFloat32Array()
	for i in pts.size():
		var p := pts[i]
		if absf(p.x) <= EXTENT and absf(p.y) <= EXTENT:
			cp.append(p)
			cy.append(ys[i])
			continue
		if cp.size() >= 2:
			runs.append([cp, cy])
		cp = PackedVector2Array()
		cy = PackedFloat32Array()
	if cp.size() >= 2:
		runs.append([cp, cy])
	return runs

## Sub-runs within r metres of the viewpoint.
static func _near(pts: PackedVector2Array, ys: PackedFloat32Array, r: float) -> Array:
	if r <= 0.0:
		return []
	var runs: Array = []
	var cp := PackedVector2Array()
	var cy := PackedFloat32Array()
	for i in pts.size():
		if pts[i].length() <= r:
			cp.append(pts[i])
			cy.append(ys[i])
			continue
		if cp.size() >= 2:
			runs.append([cp, cy])
		cp = PackedVector2Array()
		cy = PackedFloat32Array()
	if cp.size() >= 2:
		runs.append([cp, cy])
	return runs

static func _v3(p: Vector2, y: float) -> Vector3:
	return Vector3(p.x, y, p.y)

## Trapezoid ballast bed: left slope, crown, right slope.
static func _ballast(b: TreeMeshLibrary.Buf, pts: PackedVector2Array, ys: PackedFloat32Array,
		half_top: float, half_bot: float, h: float, surf: RoadBuilder._Surface,
		on_deck: bool) -> void:
	var along := 0.0
	var prev: Array = []
	for i in pts.size():
		if i > 0:
			along += pts[i].distance_to(pts[i - 1])
		var s := RoadBuilder._side(pts, i)
		var lb := pts[i] + s * half_bot
		var rb := pts[i] - s * half_bot
		var yl := ys[i] if on_deck else surf.height(lb.x, lb.y) - 0.05
		var yr := ys[i] if on_deck else surf.height(rb.x, rb.y) - 0.05
		var top := maxf(ys[i] + h, maxf(yl, yr) + 0.12)
		var cur := [_v3(lb, yl), _v3(pts[i] + s * half_top, top),
			_v3(pts[i] - s * half_top, top), _v3(rb, yr), along * 0.5,
			Vector3(s.x, 0.0, s.y).normalized()]
		if not prev.is_empty():
			var v0: float = prev[4]
			var v1: float = cur[4]
			var out: Vector3 = cur[5]
			var w := (half_bot - half_top) * 0.5
			var c := half_top
			RailMesh.quad(b, prev[0], cur[0], cur[1], prev[1], (out * 0.5 + Vector3.UP).normalized(),
				Color.WHITE, [Vector2(0, v0), Vector2(0, v1), Vector2(w, v1), Vector2(w, v0)])
			RailMesh.quad(b, prev[1], cur[1], cur[2], prev[2], Vector3.UP, Color.WHITE,
				[Vector2(w, v0), Vector2(w, v1), Vector2(w + c, v1), Vector2(w + c, v0)])
			RailMesh.quad(b, prev[2], cur[2], cur[3], prev[3], (-out * 0.5 + Vector3.UP).normalized(),
				Color.WHITE, [Vector2(w + c, v0), Vector2(w + c, v1), Vector2(2.0 * w + c, v1),
				Vector2(2.0 * w + c, v0)])
		prev = cur

## Calls f(p, y, dir) every `spacing` metres along the run (first at
## spacing / 2).
static func _walk(pts: PackedVector2Array, ys: PackedFloat32Array, spacing: float,
		f: Callable) -> void:
	var carry := spacing * 0.5
	for i in pts.size() - 1:
		var a := pts[i]
		var c := pts[i + 1]
		var seg := a.distance_to(c)
		if seg < 0.001:
			continue
		var dir := (c - a) / seg
		var t := carry
		while t < seg:
			var f01 := t / seg
			f.call(a.lerp(c, f01), lerpf(ys[i], ys[i + 1], f01), dir)
			t += spacing
		carry = t - seg

## Sleepers: crown + both long faces (ends and bottom are buried).
static func _ties(b: TreeMeshLibrary.Buf, pts: PackedVector2Array, ys: PackedFloat32Array,
		top_off: float, length: float, col: Color) -> void:
	var hw := SLEEPER_W_M * 0.5
	var hl := length * 0.5
	_walk(pts, ys, SLEEPER_SPACING_M, func(p: Vector2, y: float, dir: Vector2) -> void:
		var al := Vector3(dir.x, 0.0, dir.y) * hw
		var ac := Vector3(-dir.y, 0.0, dir.x) * hl
		var top := y + top_off
		var c := Vector3(p.x, top, p.y)
		var dn := Vector3(0, -SLEEPER_H_M * 0.6, 0)
		RailMesh.quad(b, c - al - ac, c + al - ac, c + al + ac, c - al + ac, Vector3.UP, col)
		var n := al.normalized()
		RailMesh.quad(b, c + al - ac, c + al + ac, c + al + ac + dn, c + al - ac + dn, n,
			col.darkened(0.15))
		RailMesh.quad(b, c - al - ac, c - al + ac, c - al + ac + dn, c - al - ac + dn, -n,
			col.darkened(0.15)))

## Two rails: bright running head on a rusty web (ballasted), or a head
## strip beside a dark flangeway groove (embedded tram track).
static func _rails(b: TreeMeshLibrary.Buf, pts: PackedVector2Array, ys: PackedFloat32Array,
		gauge: float, top_off: float, embedded: bool) -> void:
	var hw := RAIL_HEAD_M * 0.5
	var h := 0.0 if embedded else RAIL_H_M
	for sgn: float in [1.0, -1.0]:
		var off: float = (gauge * 0.5 + hw) * sgn
		for i in pts.size() - 1:
			var s0 := RoadBuilder._side(pts, i)
			var s1 := RoadBuilder._side(pts, i + 1)
			var y0 := ys[i] + top_off + h
			var y1 := ys[i + 1] + top_off + h
			var o0 := _v3(pts[i] + s0 * (off + hw * sgn), y0)
			var i0 := _v3(pts[i] + s0 * (off - hw * sgn), y0)
			var o1 := _v3(pts[i + 1] + s1 * (off + hw * sgn), y1)
			var i1 := _v3(pts[i + 1] + s1 * (off - hw * sgn), y1)
			RailMesh.quad(b, i0, o0, o1, i1, Vector3.UP, RAIL_HEAD_COL)
			var out := Vector3(s0.x, 0.0, s0.y).normalized() * sgn
			if embedded:
				# Flangeway groove on the gauge side of the head.
				var g0 := _v3(pts[i] + s0 * (off - (hw + 0.045) * sgn), y0 - 0.002)
				var g1 := _v3(pts[i + 1] + s1 * (off - (hw + 0.045) * sgn), y1 - 0.002)
				RailMesh.quad(b, g0, i0, i1, g1, Vector3.UP, Color(0.05, 0.05, 0.05))
				continue
			var dn := Vector3(0, -h, 0)
			RailMesh.quad(b, o0, o1, o1 + dn, o0 + dn, out, RAIL_WEB_COL)
			RailMesh.quad(b, i0, i1, i1 + dn, i0 + dn, -out, RAIL_WEB_COL)

## Overhead contact line: masts + cantilever arms (none for street
## trams, which hang from span wires) and contact + messenger wires.
static func _overhead(b: TreeMeshLibrary.Buf, pts: PackedVector2Array, ys: PackedFloat32Array,
		surf: RoadBuilder._Surface, top_off: float, mast_off: float, tram: bool) -> void:
	var wire_y := top_off + (WIRE_H_M + 0.3 if tram else WIRE_H_M)
	if not tram:
		_walk(pts, ys, MAST_SPACING_M, func(p: Vector2, y: float, dir: Vector2) -> void:
			var across := Vector2(-dir.y, dir.x)
			var foot := p + across * mast_off
			# On a deck the mast stands on the deck, else on the ground.
			var gy := surf.height(foot.x, foot.y)
			var fy := (gy if y - gy < 1.0 else y) - 0.2
			var top := y + wire_y + 1.6
			var al := Vector3(dir.x, 0.0, dir.y)
			RailMesh.post(b, _v3(foot, fy), al, 0.22, 0.22, top - fy, WIRE_COL)
			var arm_c := (foot + p) * 0.5
			var ac3 := Vector3(across.x, 0.0, across.y) * (mast_off * 0.5 + 0.3)
			RailMesh.box(b, _v3(arm_c, top - 0.35), al * 0.06, Vector3(0, 0.06, 0), ac3, WIRE_COL)
			RailMesh.box(b, _v3(arm_c, y + wire_y + 0.55), al * 0.04, Vector3(0, 0.04, 0),
				ac3, WIRE_COL))
	for lift: float in ([0.0] if tram else [0.0, 1.1]):
		for i in pts.size() - 1:
			var a := _v3(pts[i], ys[i] + wire_y + lift)
			var c := _v3(pts[i + 1], ys[i + 1] + wire_y + lift)
			var d := c - a
			if d.length() < 0.001:
				continue
			var side := Vector3(-d.z, 0.0, d.x).normalized() * 0.012
			var up := Vector3(0, 0.012, 0)
			RailMesh.quad(b, a - side, c - side, c + side, a + side, Vector3.UP, WIRE_COL)
			RailMesh.quad(b, a - up, c - up, c + up, a + up, side.normalized(), WIRE_COL)

## Bridge / viaduct deck along a run: slab top, outer girder faces from
## the soffit to the parapet, inner parapet faces, caps and soffit.
static func _deck(b: TreeMeshLibrary.Buf, pts: PackedVector2Array, ys: PackedFloat32Array,
		hw: float, depth: float, parapet: float, col: Color) -> void:
	for i in pts.size() - 1:
		var s0 := RoadBuilder._side(pts, i) * hw
		var s1 := RoadBuilder._side(pts, i + 1) * hw
		var y0 := ys[i]
		var y1 := ys[i + 1]
		var p0 := pts[i]
		var p1 := pts[i + 1]
		var seg := p0.distance_to(p1)
		var uv := [Vector2(0, 0), Vector2(seg * 0.25, 0), Vector2(seg * 0.25, hw * 0.5),
			Vector2(0, hw * 0.5)]
		RailMesh.quad(b, _v3(p0 + s0, y0), _v3(p1 + s1, y1), _v3(p1 - s1, y1),
			_v3(p0 - s0, y0), Vector3.UP, col, uv)
		RailMesh.quad(b, _v3(p0 + s0, y0 - depth), _v3(p1 + s1, y1 - depth),
			_v3(p1 - s1, y1 - depth), _v3(p0 - s0, y0 - depth), Vector3.DOWN, col.darkened(0.25), uv)
		for sgn: float in [1.0, -1.0]:
			var e0: Vector2 = p0 + s0 * sgn
			var e1: Vector2 = p1 + s1 * sgn
			var out := Vector3(s0.x, 0.0, s0.y).normalized() * sgn
			var wuv := [Vector2(0, 0), Vector2(seg * 0.25, 0),
				Vector2(seg * 0.25, (depth + parapet) * 0.25), Vector2(0, (depth + parapet) * 0.25)]
			RailMesh.quad(b, _v3(e0, y0 - depth), _v3(e1, y1 - depth), _v3(e1, y1 + parapet),
				_v3(e0, y0 + parapet), out, col.darkened(0.08), wuv)
			if parapet <= 0.0:
				continue
			var in0 := e0 - s0.normalized() * 0.25 * sgn
			var in1 := e1 - s1.normalized() * 0.25 * sgn
			RailMesh.quad(b, _v3(in0, y0), _v3(in1, y1), _v3(in1, y1 + parapet),
				_v3(in0, y0 + parapet), -out, col.darkened(0.04), wuv)
			RailMesh.quad(b, _v3(e0, y0 + parapet), _v3(e1, y1 + parapet),
				_v3(in1, y1 + parapet), _v3(in0, y0 + parapet), Vector3.UP, col)

## Supports under a deck wherever it clears the ground by > 2 m: a pair
## of columns at ±offset with a cross bent (steel el, offset > 0) or a
## single central pier (offset 0). Piers in water stand on the riverbed.
static func _piers(b: TreeMeshLibrary.Buf, pts: PackedVector2Array, ys: PackedFloat32Array,
		surf: RoadBuilder._Surface, offset: float, depth: float, spacing: float,
		thick: float, col: Color) -> void:
	_walk(pts, ys, spacing, func(p: Vector2, y: float, dir: Vector2) -> void:
		var al := Vector3(dir.x, 0.0, dir.y)
		var across := Vector2(-dir.y, dir.x)
		var soffit := y - depth
		var feet: Array = [p] if offset <= 0.0 else [p + across * offset, p - across * offset]
		var built := false
		for f in feet:
			var fp: Vector2 = f
			var fy := surf.height(fp.x, fp.y) - 0.3
			if surf.ground.water_at(fp.x, fp.y) > 0.0:
				fy = surf.ground.water_level_at(fp.x, fp.y) - 1.5
			if soffit - fy < 2.0:
				continue
			RailMesh.post(b, _v3(fp, fy), al, thick, thick, soffit - fy, col.darkened(0.1))
			built = true
		if built and offset > 0.0:
			RailMesh.box(b, _v3(p, soffit - 0.35), al * 0.3, Vector3(0, 0.35, 0),
				Vector3(across.x, 0.0, across.y) * (offset + thick * 0.5), col.darkened(0.15)))
