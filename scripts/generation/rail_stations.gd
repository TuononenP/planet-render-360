class_name RailStations
extends RefCounted

## Station platforms (LocationData.rail_platforms, OsmRail shapes) for
## RailBuilder. Each railway=platform area is extruded at its real
## footprint to a height measured from the top of rail — 0.76 m on a
## main line, 1.0 m on an elevated (layer ≥ 1) line, where the slab sits
## on the viaduct deck height RailBuilder uses and stands on columns;
## 0.25 m at a tram stop. Linear platform ways get their tagged width
## (4 m default). A yellow tactile strip runs along every long edge.
## Canopies: covered=yes spans the platform, covered=partial its middle
## half; untagged platforms of a station (within STATION_NEAR_M of a
## railway=station/halt node) get a central canopy over 60% of their
## length, the common case. covered=no never does. Station buildings are
## OSM buildings (building=train_station) and come from BuildingBuilder.

## Top of rail above the at-grade track base (ballast + sleeper + rail).
const RAIL_TOP_M := RailBuilder.BALLAST_H_M + 0.03 + RailBuilder.RAIL_H_M
const MAINLINE_HEIGHT_M := 0.76
const ELEVATED_HEIGHT_M := 1.0
const TRAM_HEIGHT_M := 0.25
const DEFAULT_WIDTH_M := 4.0
const EDGE_STRIP_M := 0.6
const EDGE_MIN_M := 6.0
const ELEVATED_SLAB_M := 0.8
const CANOPY_H_M := 3.3
const CANOPY_POST_SPACING_M := 9.0
const STATION_NEAR_M := 300.0
const TRAM_STOP_NEAR_M := 40.0
const STRIP_COL := Color(0.86, 0.70, 0.12)
const CANOPY_COL := Color(0.62, 0.63, 0.64)
const POST_COL := Color(0.22, 0.24, 0.26)

static func build(root: Node3D, data: LocationData, surf: RoadBuilder._Surface,
		_preset: int, _ends: Dictionary) -> void:
	if data.rail_platforms.is_empty():
		return
	var stations: Array[Vector2] = []
	var tram_stops: Array[Vector2] = []
	for s in data.transit_stops:
		if not (s is Dictionary):
			continue
		var at := Vector2(float(s.get("x", 0.0)), float(s.get("z", 0.0)))
		var kind := str(s.get("kind", ""))
		if kind in ["station", "halt"]:
			stations.append(at)
		elif kind == "tram_stop":
			tram_stops.append(at)
	var bufs := {}
	for k in ["top", "side", "strip", "canopy"]:
		bufs[k] = TreeMeshLibrary.Buf.new()
	for pf in data.rail_platforms:
		if pf is Dictionary:
			_platform(bufs, pf, surf, stations, tram_stops)
	RailMesh.add(root, bufs["top"], RailMesh.pbr("pavement", "#9a958c"), "Rail_platform")
	RailMesh.add(root, bufs["side"], RailMesh.pbr("concrete", "#a39d92"), "Rail_platform_side")
	RailMesh.add(root, bufs["strip"], RailMesh.colour_mat("strip", 0.0, 0.7), "Rail_platform_edge")
	RailMesh.add(root, bufs["canopy"], RailMesh.colour_mat("canopy", 0.35, 0.5), "Rail_canopy")

static func _near(p: Vector2, pts: Array[Vector2], r: float) -> bool:
	for q in pts:
		if q.distance_to(p) <= r:
			return true
	return false

## Footprint ring (no closing duplicate) of a platform dict.
static func ring_of(pf: Dictionary) -> PackedVector2Array:
	var pts: PackedVector2Array = pf.get("points", PackedVector2Array())
	if pts.size() < 2:
		return PackedVector2Array()
	if bool(pf.get("closed", false)):
		var ring := pts.duplicate()
		ring.remove_at(ring.size() - 1)
		return ring
	var w := float(pf.get("width_m", 0.0))
	var half := (w if w > 0.0 else DEFAULT_WIDTH_M) * 0.5
	var left := PackedVector2Array()
	var right := PackedVector2Array()
	for i in pts.size():
		var s := RoadBuilder._side(pts, i) * half
		left.append(pts[i] + s)
		right.append(pts[i] - s)
	right.reverse()
	left.append_array(right)
	return left

## Principal axis box of a ring: {centre, axis (unit), length, width}.
static func axis_box(ring: PackedVector2Array) -> Dictionary:
	var c := Vector2.ZERO
	for p in ring:
		c += p
	c /= float(ring.size())
	var sxx := 0.0
	var syy := 0.0
	var sxy := 0.0
	for p in ring:
		var d := p - c
		sxx += d.x * d.x
		syy += d.y * d.y
		sxy += d.x * d.y
	var ang := 0.5 * atan2(2.0 * sxy, sxx - syy)
	var axis := Vector2(cos(ang), sin(ang))
	var across := Vector2(-axis.y, axis.x)
	var lo := INF
	var hi := -INF
	var wlo := INF
	var whi := -INF
	for p in ring:
		var d := p - c
		lo = minf(lo, d.dot(axis))
		hi = maxf(hi, d.dot(axis))
		wlo = minf(wlo, d.dot(across))
		whi = maxf(whi, d.dot(across))
	return {"centre": c + axis * (lo + hi) * 0.5 + across * (wlo + whi) * 0.5,
		"axis": axis, "length": hi - lo, "width": whi - wlo}

static func _platform(bufs: Dictionary, pf: Dictionary, surf: RoadBuilder._Surface,
		stations: Array[Vector2], tram_stops: Array[Vector2]) -> void:
	if bool(pf.get("tunnel", false)):
		return
	var ring := ring_of(pf)
	if ring.size() < 3:
		return
	for p in ring:
		if absf(p.x) > RailBuilder.EXTENT or absf(p.y) > RailBuilder.EXTENT:
			return
	var box := axis_box(ring)
	var centre: Vector2 = box["centre"]
	var layer := int(pf.get("layer", 0))
	var elevated := layer >= 1
	var at_station := _near(centre, stations, STATION_NEAR_M)
	var tram := not at_station and _near(centre, tram_stops, TRAM_STOP_NEAR_M)
	var gys := PackedFloat32Array()
	var base := 0.0
	for p in ring:
		var gy := surf.height(p.x, p.y)
		gys.append(gy)
		base += gy
	base /= float(ring.size())
	var tag_h := float(pf.get("height_m", 0.0))
	var top: float
	if elevated:
		top = RailBuilder.viaduct_top(surf, centre, layer) + RAIL_TOP_M \
			+ (tag_h if tag_h > 0.0 else ELEVATED_HEIGHT_M)
	elif tram:
		top = base + (tag_h if tag_h > 0.0 else TRAM_HEIGHT_M)
	else:
		top = base + RAIL_TOP_M + (tag_h if tag_h > 0.0 else MAINLINE_HEIGHT_M)
	_top_face(bufs["top"], ring, top)
	var n := ring.size()
	for i in n:
		var a := ring[i]
		var c := ring[(i + 1) % n]
		var edge := c - a
		var ln := edge.length()
		if ln < 0.01:
			continue
		var out := Vector2(-edge.y, edge.x) / ln
		if out.dot((a + c) * 0.5 - centre) < 0.0:
			out = -out
		var out3 := Vector3(out.x, 0.0, out.y)
		var ya := top - ELEVATED_SLAB_M if elevated else gys[i] - 0.15
		var yc := top - ELEVATED_SLAB_M if elevated else gys[(i + 1) % n] - 0.15
		RailMesh.quad(bufs["side"], Vector3(a.x, ya, a.y), Vector3(c.x, yc, c.y),
			Vector3(c.x, top, c.y), Vector3(a.x, top, a.y), out3, Color.WHITE,
			[Vector2(0, 1), Vector2(ln * 0.25, 1), Vector2(ln * 0.25, 0), Vector2(0, 0)])
		if ln >= EDGE_MIN_M:
			var a_in := a - out * EDGE_STRIP_M
			var c_in := c - out * EDGE_STRIP_M
			var y := top + 0.006
			RailMesh.quad(bufs["strip"], Vector3(a.x, y, a.y), Vector3(c.x, y, c.y),
				Vector3(c_in.x, y, c_in.y), Vector3(a_in.x, y, a_in.y), Vector3.UP, STRIP_COL)
	if elevated:
		_elevated_supports(bufs["side"], ring, box, top, surf)
	var frac := _canopy_frac(str(pf.get("covered", "")), at_station or elevated,
		float(box["length"]), tram)
	if frac > 0.0:
		_canopy(bufs["canopy"], box, top, frac)

## Triangulated flat top; a degenerate footprint falls back to a fan.
static func _top_face(b: TreeMeshLibrary.Buf, ring: PackedVector2Array, top: float) -> void:
	var tris := Geometry2D.triangulate_polygon(ring)
	if tris.is_empty():
		for i in range(1, ring.size() - 1):
			tris.append_array([0, i, i + 1])
	var k := b.verts.size()
	for p in ring:
		b.verts.append(Vector3(p.x, top, p.y))
		b.normals.append(Vector3.UP)
		b.colors.append(Color.WHITE)
		b.uvs.append(p * 0.25)
	for t in range(0, tris.size(), 3):
		var i0 := k + tris[t]
		var i1 := k + tris[t + 1]
		var i2 := k + tris[t + 2]
		var v0 := b.verts[i0]
		# RoadBuilder._quad_up winding: front faces up.
		if (b.verts[i2] - v0).cross(b.verts[i1] - v0).y >= 0.0:
			b.idx.append_array([i0, i1, i2])
		else:
			b.idx.append_array([i0, i2, i1])

## Soffit + columns under an elevated platform: a column pair every
## 12 m along its axis.
static func _elevated_supports(b: TreeMeshLibrary.Buf, ring: PackedVector2Array,
		box: Dictionary, top: float, surf: RoadBuilder._Surface) -> void:
	var soffit := top - RailStations.ELEVATED_SLAB_M
	var tris := Geometry2D.triangulate_polygon(ring)
	var k := b.verts.size()
	for p in ring:
		b.verts.append(Vector3(p.x, soffit, p.y))
		b.normals.append(Vector3.DOWN)
		b.colors.append(Color(0.75, 0.75, 0.75))
		b.uvs.append(p * 0.25)
	for t in range(0, tris.size(), 3):
		var i0 := k + tris[t]
		var i1 := k + tris[t + 1]
		var i2 := k + tris[t + 2]
		var v0 := b.verts[i0]
		if (b.verts[i2] - v0).cross(b.verts[i1] - v0).y <= 0.0:
			b.idx.append_array([i0, i1, i2])
		else:
			b.idx.append_array([i0, i2, i1])
	var c: Vector2 = box["centre"]
	var axis: Vector2 = box["axis"]
	var across := Vector2(-axis.y, axis.x)
	var length := float(box["length"])
	var off := float(box["width"]) * 0.3
	var al := Vector3(axis.x, 0.0, axis.y)
	var t := -length * 0.5 + 3.0
	while t <= length * 0.5 - 3.0:
		for sgn: float in [1.0, -1.0]:
			var f := c + axis * t + across * off * sgn
			var fy := surf.height(f.x, f.y) - 0.3
			if soffit - fy > 1.0:
				RailMesh.post(b, Vector3(f.x, fy, f.y), al, 0.5, 0.5, soffit - fy,
					Color(0.8, 0.8, 0.8))
		t += 12.0

static func _canopy_frac(covered: String, at_station: bool, length: float,
		tram: bool) -> float:
	match covered:
		"yes":
			return 0.95
		"partial":
			return 0.5
		"no":
			return 0.0
	if tram:
		return 0.0
	return 0.6 if at_station and length >= 30.0 else 0.0

## Canopy roof slab over the platform's middle `frac` of its length on
## one central row of posts (two rows on wide island platforms).
static func _canopy(b: TreeMeshLibrary.Buf, box: Dictionary, top: float, frac: float) -> void:
	var c: Vector2 = box["centre"]
	var axis: Vector2 = box["axis"]
	var across := Vector2(-axis.y, axis.x)
	var cl := float(box["length"]) * frac
	var cw := clampf(float(box["width"]) * 0.9, 2.5, 12.0)
	var roof_y := top + CANOPY_H_M
	var al := Vector3(axis.x, 0.0, axis.y)
	var ac := Vector3(across.x, 0.0, across.y)
	RailMesh.box(b, Vector3(c.x, roof_y + 0.1, c.y), al * (cl * 0.5), Vector3(0, 0.1, 0),
		ac * (cw * 0.5), CANOPY_COL, false)
	# Fascia lip along both long edges.
	for sgn: float in [1.0, -1.0]:
		var e := c + across * (cw * 0.5) * sgn
		RailMesh.box(b, Vector3(e.x, roof_y + 0.05, e.y), al * (cl * 0.5), Vector3(0, 0.22, 0),
			ac * 0.04, POST_COL, false)
	var rows: Array = [0.0] if cw < 8.0 else [-cw * 0.3, cw * 0.3]
	var t := -cl * 0.5 + CANOPY_POST_SPACING_M * 0.5
	while t <= cl * 0.5:
		for r: float in rows:
			var p := c + axis * t + across * r
			RailMesh.post(b, Vector3(p.x, top, p.y), al, 0.22, 0.22, CANOPY_H_M, POST_COL)
		t += CANOPY_POST_SPACING_M
