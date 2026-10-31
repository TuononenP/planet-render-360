class_name SubwayEntrances
extends RefCounted

## Street-level subway entrances from railway=subway_entrance nodes
## (LocationData.transit_stops) for RailBuilder.
## The stair opening is a 1.9 x 5.0 m well in the sidewalk, its long side
## parallel to the nearest street (or along the tagged `direction`, the
## way the stair descends), entered at the mapped node. The well is
## drawn as stepped treads that fall into shadow with depth (the terrain
## cannot be cut, so depth is read from the tread shading), ringed by a
## waist-high railing on three sides with the open end at the node.
## * North America — the New York look: dark green painted railing with
##   baluster infill and a coping kerb, a pair of green globe lamps on
##   posts flanking the open end (green: open at all hours) and a black
##   station sign across the far rail.
## * Elsewhere: brushed steel railing and a single lit totem sign.
## entrance=elevator nodes are a glass lift kiosk instead. Entrances
## inside a tunnel are skipped. Merged into a handful of meshes.

const WELL_W_M := 1.9
const WELL_L_M := 5.0
const TREADS := 16
const RAIL_H_M := 1.07
const POST_SPACING_M := 1.25
const LAMP_H_M := 2.3
const ROAD_SNAP_M := 30.0
## Reach per preset (Fast, Balanced, High, Ultra).
const ENTRANCE_R: Array[float] = [300.0, 600.0, 1200.0, 1700.0]
const NYC_GREEN := Color(0.10, 0.22, 0.15)
const STEEL := Color(0.56, 0.58, 0.59)
const GLOBE_GREEN := Color(0.30, 0.95, 0.45)
const TOTEM_LIGHT := Color(0.92, 0.94, 0.97)
const SIGN_BLACK := Color(0.035, 0.035, 0.04)

static func build(root: Node3D, data: LocationData, surf: RoadBuilder._Surface,
		preset: int, north_america: bool) -> int:
	var r: float = ENTRANCE_R[preset]
	var todo: Array = []
	for s in data.transit_stops:
		if not (s is Dictionary) or str(s.get("kind", "")) != "subway_entrance" \
				or bool(s.get("tunnel", false)):
			continue
		var p := Vector2(float(s.get("x", 0.0)), float(s.get("z", 0.0)))
		if p.length() > r or absf(p.x) > RailBuilder.EXTENT or absf(p.y) > RailBuilder.EXTENT:
			continue
		todo.append(s)
	if todo.is_empty():
		return 0
	var segs := _road_grid(data)
	var bufs := {}
	for k in ["metal", "infill", "stair", "globe", "glass"]:
		bufs[k] = TreeMeshLibrary.Buf.new()
	for s in todo:
		var at := Vector2(float(s["x"]), float(s["z"]))
		var fwd := _facing(s, at, segs)
		if bool(s.get("elevator", false)):
			_kiosk(bufs, at, fwd, surf, north_america)
		else:
			_stair(bufs, at, fwd, surf, north_america)
	RailMesh.add(root, bufs["metal"], RailMesh.colour_mat("entrance_metal", 0.5, 0.45),
		"Rail_entrance_metal")
	RailMesh.add(root, bufs["infill"], RailMesh.infill_mat(), "Rail_entrance_infill")
	RailMesh.add(root, bufs["stair"], RailMesh.colour_mat("entrance_stair", 0.0, 0.85),
		"Rail_entrance_stair")
	RailMesh.add(root, bufs["globe"], RailMesh.glow_mat(GLOBE_GREEN if north_america \
		else TOTEM_LIGHT), "Rail_entrance_light")
	RailMesh.add(root, bufs["glass"], _glass_mat(), "Rail_entrance_glass")
	return todo.size()

# --- Orientation -------------------------------------------------------------

## Road segments bucketed by ROAD_SNAP_M cell: cell -> [[a, b], ...].
static func _road_grid(data: LocationData) -> Dictionary:
	var grid := {}
	for rd in data.roads:
		var pts: PackedVector2Array
		if rd is Dictionary:
			if bool((rd as Dictionary).get("tunnel", false)):
				continue
			pts = (rd as Dictionary).get("points", PackedVector2Array())
		elif rd is PackedVector2Array:
			pts = rd
		else:
			continue
		for i in pts.size() - 1:
			var a := pts[i]
			var b := pts[i + 1]
			var lo := Vector2i(floori(minf(a.x, b.x) / ROAD_SNAP_M), floori(minf(a.y, b.y) / ROAD_SNAP_M))
			var hi := Vector2i(floori(maxf(a.x, b.x) / ROAD_SNAP_M), floori(maxf(a.y, b.y) / ROAD_SNAP_M))
			if (hi.x - lo.x + 1) * (hi.y - lo.y + 1) > 64:
				continue
			for cx in range(lo.x, hi.x + 1):
				for cz in range(lo.y, hi.y + 1):
					var key := Vector2i(cx, cz)
					if not grid.has(key):
						grid[key] = []
					(grid[key] as Array).append([a, b])
	return grid

## Unit XZ direction the stair descends: the `direction` tag, else along
## the nearest street (either way, chosen by a stable hash), else a
## hashed heading.
static func _facing(s: Dictionary, at: Vector2, segs: Dictionary) -> Vector2:
	var dir_deg := float(s.get("direction", NAN))
	if not is_nan(dir_deg):
		var a := deg_to_rad(dir_deg)
		return Vector2(sin(a), -cos(a))
	var best := INF
	var best_dir := Vector2.ZERO
	var cell := Vector2i(floori(at.x / ROAD_SNAP_M), floori(at.y / ROAD_SNAP_M))
	for dx in range(-1, 2):
		for dz in range(-1, 2):
			for seg in segs.get(Vector2i(cell.x + dx, cell.y + dz), []):
				var a: Vector2 = seg[0]
				var b: Vector2 = seg[1]
				var q := Geometry2D.get_closest_point_to_segment(at, a, b)
				var d := q.distance_to(at)
				if d < best and a.distance_to(b) > 0.5:
					best = d
					best_dir = (b - a).normalized()
	var h := TerrainBuilder._hash(at.x, at.y)
	if best_dir == Vector2.ZERO or best > ROAD_SNAP_M:
		var ang := h * TAU
		return Vector2(cos(ang), sin(ang))
	return best_dir if h < 0.5 else -best_dir

# --- Geometry ----------------------------------------------------------------

## Local frame: x across (right of the descent), z along the descent from
## the open end at the node, y up from the sidewalk.
class _Frame extends RefCounted:
	var o: Vector2
	var f: Vector2
	var r: Vector2
	var g: float

	func _init(at: Vector2, fwd: Vector2, ground: float) -> void:
		o = at
		f = fwd
		r = Vector2(-fwd.y, fwd.x)
		g = ground

	func p(x: float, y: float, z: float) -> Vector3:
		var q := o + r * x + f * z
		return Vector3(q.x, g + y, q.y)

	func along() -> Vector3:
		return Vector3(f.x, 0.0, f.y)

	func across() -> Vector3:
		return Vector3(r.x, 0.0, r.y)

## The sidewalk level at the well: the highest ground under it, so no
## corner of the railing sinks into a slope.
static func _ground(surf: RoadBuilder._Surface, at: Vector2, fwd: Vector2) -> float:
	var r := Vector2(-fwd.y, fwd.x)
	var g := surf.height(at.x, at.y)
	for c in [r * WELL_W_M * 0.5, -r * WELL_W_M * 0.5,
			r * WELL_W_M * 0.5 + fwd * WELL_L_M, -r * WELL_W_M * 0.5 + fwd * WELL_L_M]:
		var q: Vector2 = at + c
		g = maxf(g, surf.height(q.x, q.y))
	return g + 0.02

static func _stair(bufs: Dictionary, at: Vector2, fwd: Vector2, surf: RoadBuilder._Surface,
		nyc: bool) -> void:
	var fr := _Frame.new(at, fwd, _ground(surf, at, fwd))
	var hw := WELL_W_M * 0.5
	var wi := hw - 0.12
	var stair: TreeMeshLibrary.Buf = bufs["stair"]
	# Treads falling into shadow, each with a lighter nosing.
	var dz := (WELL_L_M - 0.2) / float(TREADS)
	for k in TREADS:
		var depth := pow(float(k) / float(TREADS - 1), 0.6)
		var lum := lerpf(0.46, 0.03, depth)
		var z0 := 0.1 + float(k) * dz
		var z1 := z0 + dz
		var nose := Color(0.78, 0.66, 0.22) * lerpf(1.0, 0.08, depth)
		nose.a = 1.0
		RailMesh.quad(stair, fr.p(-wi, 0.01, z0), fr.p(wi, 0.01, z0), fr.p(wi, 0.01, z0 + 0.05),
			fr.p(-wi, 0.01, z0 + 0.05), Vector3.UP, nose)
		RailMesh.quad(stair, fr.p(-wi, 0.01, z0 + 0.05), fr.p(wi, 0.01, z0 + 0.05),
			fr.p(wi, 0.01, z1), fr.p(-wi, 0.01, z1), Vector3.UP, Color(lum, lum * 0.98, lum * 0.95))
		# Side walls of the well read as a darker margin.
		var wall := Color(lum * 0.45, lum * 0.45, lum * 0.45)
		for sgn: float in [1.0, -1.0]:
			RailMesh.quad(stair, fr.p(wi * sgn, 0.011, z0), fr.p((wi - 0.14) * sgn, 0.011, z0),
				fr.p((wi - 0.14) * sgn, 0.011, z1), fr.p(wi * sgn, 0.011, z1), Vector3.UP, wall)
	# Granite coping under the railing on the three closed sides.
	var coping := Color(0.62, 0.61, 0.58)
	for sgn: float in [1.0, -1.0]:
		RailMesh.box(stair, fr.p(hw * sgn - 0.06 * sgn, 0.0, WELL_L_M * 0.5),
			fr.across() * 0.08, Vector3(0, 0.06, 0), fr.along() * (WELL_L_M * 0.5), coping)
	RailMesh.box(stair, fr.p(0.0, 0.0, WELL_L_M - 0.06), fr.along() * 0.08,
		Vector3(0, 0.06, 0), fr.across() * hw, coping)
	var col := NYC_GREEN if nyc else STEEL
	# Railing runs: both long sides, then across the far end.
	_railing(bufs, fr, Vector2(-hw, 0.0), Vector2(-hw, WELL_L_M), col)
	_railing(bufs, fr, Vector2(hw, 0.0), Vector2(hw, WELL_L_M), col)
	_railing(bufs, fr, Vector2(-hw, WELL_L_M), Vector2(hw, WELL_L_M), col)
	var metal: TreeMeshLibrary.Buf = bufs["metal"]
	if nyc:
		for sgn: float in [1.0, -1.0]:
			_globe_lamp(bufs, fr, hw * sgn, col)
		# Black station sign across the far rail, white lettering band on
		# both faces.
		var sc := fr.p(0.0, RAIL_H_M + 0.3, WELL_L_M)
		RailMesh.box(metal, sc, fr.across() * 0.8, Vector3(0, 0.19, 0), fr.along() * 0.025,
			SIGN_BLACK, false)
		for sgn: float in [1.0, -1.0]:
			var face := sc + fr.along() * (0.027 * sgn)
			var ax := fr.across() * 0.55
			var up := Vector3(0, 0.045, 0)
			RailMesh.quad(metal, face - ax - up, face + ax - up, face + ax + up, face - ax + up,
				fr.along() * sgn, Color(0.93, 0.93, 0.9))
		for sgn: float in [1.0, -1.0]:
			RailMesh.post(metal, fr.p(0.75 * sgn, RAIL_H_M, WELL_L_M), fr.along(), 0.04, 0.04,
				0.12, col)
	else:
		# Totem: steel post with a lit sign box, at the open end.
		var foot := fr.p(-hw - 0.35, -0.2, 0.0)
		RailMesh.post(metal, foot, fr.along(), 0.14, 0.14, 3.0, STEEL.darkened(0.2))
		RailMesh.box(bufs["globe"], foot + Vector3(0, 3.35, 0), fr.along() * 0.22,
			Vector3(0, 0.25, 0), fr.across() * 0.22, TOTEM_LIGHT, false)

## One railing run a→b (local x/z): posts, top and bottom rails, and the
## alpha-tested baluster infill between them.
static func _railing(bufs: Dictionary, fr: _Frame, a: Vector2, b: Vector2, col: Color) -> void:
	var metal: TreeMeshLibrary.Buf = bufs["metal"]
	var ln := a.distance_to(b)
	var n := maxi(1, ceili(ln / POST_SPACING_M))
	var dir3 := (fr.p(b.x, 0.0, b.y) - fr.p(a.x, 0.0, a.y)).normalized()
	for i in n + 1:
		var q := a.lerp(b, float(i) / float(n))
		RailMesh.post(metal, fr.p(q.x, -0.2, q.y), dir3, 0.07, 0.07, RAIL_H_M + 0.24, col)
		# Ball finial on each post.
		RailMesh.box(metal, fr.p(q.x, RAIL_H_M + 0.08, q.y), dir3 * 0.04, Vector3(0, 0.04, 0),
			Vector3(-dir3.z, 0.0, dir3.x) * 0.04, col, false)
	var mid := a.lerp(b, 0.5)
	var half := dir3 * (ln * 0.5)
	var side := Vector3(-dir3.z, 0.0, dir3.x)
	RailMesh.box(metal, fr.p(mid.x, RAIL_H_M, mid.y), half, Vector3(0, 0.03, 0), side * 0.035,
		col, false)
	RailMesh.box(metal, fr.p(mid.x, 0.13, mid.y), half, Vector3(0, 0.02, 0), side * 0.02,
		col, false)
	var p0 := fr.p(a.x, RAIL_H_M - 0.03, a.y)
	var p1 := fr.p(b.x, RAIL_H_M - 0.03, b.y)
	var drop := Vector3(0, RAIL_H_M - 0.03 - 0.15, 0)
	RailMesh.quad(bufs["infill"], p0, p1, p1 - drop, p0 - drop, side, col,
		[Vector2(0, 0), Vector2(ln, 0), Vector2(ln, 1), Vector2(0, 1)])

## New York globe lamp at the open-end corner x: a slim post, a collar
## and a glowing green globe.
static func _globe_lamp(bufs: Dictionary, fr: _Frame, x: float, col: Color) -> void:
	var metal: TreeMeshLibrary.Buf = bufs["metal"]
	var foot := fr.p(x, -0.2, 0.0)
	RailMesh.post(metal, foot, fr.along(), 0.09, 0.09, LAMP_H_M + 0.2, col)
	var c := fr.p(x, LAMP_H_M, 0.0)
	RailMesh.box(metal, c + Vector3(0, 0.04, 0), fr.along() * 0.08, Vector3(0, 0.04, 0),
		fr.across() * 0.08, col, false)
	var prof: Array = []
	var radii: Array = []
	for k in 7:
		var t := float(k) / 6.0
		prof.append(c + Vector3(0, 0.08 + t * 0.4, 0))
		radii.append(maxf(sin(t * PI) * 0.2, 0.02))
	TreeMeshLibrary._tube(bufs["globe"], prof, radii, 10, 1.0, 1.0)
	RailMesh.box(metal, c + Vector3(0, 0.5, 0), fr.along() * 0.05, Vector3(0, 0.03, 0),
		fr.across() * 0.05, col, false)

## Elevator kiosk: a 2 x 2 x 2.8 m glass box on a framed base with a
## solid roof.
static func _kiosk(bufs: Dictionary, at: Vector2, fwd: Vector2, surf: RoadBuilder._Surface,
		nyc: bool) -> void:
	var fr := _Frame.new(at, fwd, surf.height(at.x, at.y) + 0.02)
	var col := NYC_GREEN if nyc else STEEL
	var metal: TreeMeshLibrary.Buf = bufs["metal"]
	var h := 2.8
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			RailMesh.post(metal, fr.p(sx * 0.95, -0.2, 1.0 + sz * 0.95), fr.along(), 0.1, 0.1,
				h + 0.2, col)
	RailMesh.box(metal, fr.p(0.0, h + 0.1, 1.0), fr.along() * 1.1, Vector3(0, 0.1, 0),
		fr.across() * 1.1, col.darkened(0.2), false)
	var glass: TreeMeshLibrary.Buf = bufs["glass"]
	var corners := [Vector2(-0.95, 0.05), Vector2(0.95, 0.05), Vector2(0.95, 1.95),
		Vector2(-0.95, 1.95)]
	for i in 4:
		var a: Vector2 = corners[i]
		var b: Vector2 = corners[(i + 1) % 4]
		var mid := (a + b) * 0.5
		var out := fr.p(mid.x, 0.0, mid.y) - fr.p(0.0, 0.0, 1.0)
		RailMesh.quad(glass, fr.p(a.x, 0.0, a.y), fr.p(b.x, 0.0, b.y), fr.p(b.x, h, b.y),
			fr.p(a.x, h, a.y), out.normalized(), Color(1, 1, 1))

static func _glass_mat() -> StandardMaterial3D:
	var m := RailMesh.colour_mat("entrance_glass", 0.2, 0.08, true)
	m.albedo_color = Color(0.55, 0.68, 0.72, 0.35)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return m
