extends SceneTree

## Headless: godot --headless --script tests/coplanar_faces_test.gd
## Building relief must never lay two faces over each other in one plane
## facing the same way: such pairs z-fight (flicker) at any distance.
## Builds the fixtures that did (equal-height neighbours' parapet copings,
## a balconette over its sill, deep balconies, a stoop's nested steps, an
## inside corner's string courses, balconies and quoins) and checks every
## pair of their triangles. Also checks PartyWalls.enclosed, which drops
## a mass standing wholly inside an equal or taller one (two roofs in one
## plane).

## Same facing within 1°, one plane within 2 mm, overlapping over 1 cm².
const COS_TOL := 0.99985
const PLANE_TOL_M := 0.002
const AREA_TOL_M2 := 0.0001

var _fails := 0

func _init() -> void:
	_trim_neighbours()
	_deep_balconies()
	_stoop()
	_inside_corner()
	_enclosed()
	if _fails == 0:
		print("coplanar_faces_test: PASS")
	quit(1 if _fails > 0 else 0)

func _check(ok: bool, what: String) -> void:
	if not ok:
		_fails += 1
		printerr("FAIL: ", what)

func _ring(pts: Array) -> PackedVector2Array:
	var m := WorldScale.metres_to_units()
	var out := PackedVector2Array()
	for p in pts:
		out.append(Vector2(p[0], p[1]) * m)
	return out

func _stone() -> Material:
	return ReliefKit.stone("limestone", Color(0, 0, 0, 0))

## Two flat-roofed neighbours of one height sharing a party wall.
func _trim_neighbours() -> void:
	var m := WorldScale.metres_to_units()
	var root := Node3D.new()
	var a := _ring([[0, 0], [10, 0], [10, 10], [0, 10]])
	var b := _ring([[10, 0], [20, 0], [20, 10], [10, 10]])
	BuildingTrim.add(root, a, 12.0 * m, BuildingTrim.PARAPET, PackedByteArray([0, 1, 0, 0]))
	BuildingTrim.add(root, b, 12.0 * m, BuildingTrim.PARAPET, PackedByteArray([0, 0, 0, 1]))
	var deck := BuildingTrim.deck(12.0 * m, BuildingTrim.PARAPET)
	_expect_clean(root, "equal-height parapets on a party wall", func(p: Vector3) -> bool:
		var q := Vector2(p.x, p.z)
		return p.y < deck and (Geometry2D.is_point_in_polygon(q, a) or Geometry2D.is_point_in_polygon(q, b)))
	root.free()

func _deep_balconies() -> void:
	for glazed in [false, true]:
		var kit := ReliefKit.new()
		var m := WorldScale.metres_to_units()
		FacadeRelief._deep_balcony(kit, Vector2.ZERO, Vector3.RIGHT, Vector3.BACK, 3.0 * m,
			3.0 * m, _stone(), not glazed, glazed, 3.0 * m)
		var root := Node3D.new()
		kit.flush(root, "Relief")
		_expect_clean(root, "glazed deep balcony" if glazed else "solid deep balcony", _behind_wall, true)
		root.free()

func _stoop() -> void:
	var kit := ReliefKit.new()
	var sp := {"a": Vector2.ZERO, "dir": Vector2(1, 0), "n": Vector2(0, 1), "bays": 3, "len_m": 9.0}
	StreetFront._stoop(kit, sp, 0.0, _stone())
	var root := Node3D.new()
	kit.flush(root, "Relief")
	_expect_clean(root, "stoop steps", _behind_wall, true)
	root.free()

## An L block (inside corner at 10, 10) with string courses, a continuous
## balcony row, quoins and french windows with balconettes over punched
## sills.
func _inside_corner() -> void:
	var m := WorldScale.metres_to_units()
	var ring := _ring([[0, 0], [20, 0], [20, 10], [10, 10], [10, 20], [0, 20]])
	var cover: Array = []
	for i in ring.size():
		cover.append([[0.0, 1.0, PartyWalls.OPEN]])
	var look := {"pattern": "punched", "window": "french", "wall_set": "limestone",
		"relief": {"balconette": 1.0, "string_course": true, "quoins": true}}
	var rows: Array = [{"y0": 0.0, "y1": 4.0 * m, "storey": 0, "ground": true}]
	for k in 3:
		var y0 := (4.0 + 3.0 * k) * m
		rows.append({"y0": y0, "y1": y0 + 3.0 * m, "storey": k + 1, "ground": false,
			"win0": y0 + 0.9 * m, "win1": y0 + 2.6 * m, "win_w": 0.4,
			"balcony": k == 1, "balconette": false, "slab": y0 + 0.05 * m, "rail_h": 1.0 * m})
	var kit := ReliefKit.new()
	var spans := FacadeRelief.exposed_spans(ring, cover)
	var inside := 0
	for sp in spans:
		sp["bays"] = FacadeRelief.bay_count(float(sp["len_m"]), 3.0)
		inside += int(bool(sp["a_inside"])) + int(bool(sp["b_inside"]))
		FacadeRelief._storeys(kit, sp, rows, look, look["relief"], _stone(), 0.3, false)
	_check(inside == 2, "the L's one inside corner ends two stretches (got %d)" % inside)
	var root := Node3D.new()
	kit.flush(root, "Relief")
	_expect_clean(root, "inside corner relief", func(p: Vector3) -> bool:
		return p.y < 0.0 or Geometry2D.is_point_in_polygon(Vector2(p.x, p.z), ring), true)
	root.free()

func _enclosed() -> void:
	var pw := PartyWalls.new()
	var outer := _ring([[0, 0], [30, 0], [30, 30], [0, 30]])
	var inner := _ring([[5, 5], [15, 5], [15, 15], [5, 15]])
	pw._add_outline(outer, [], "outer", 12.0)
	pw._add_outline(inner, [], "inner", 12.0)
	pw._add_outline(inner, [], "tall_inner", 18.0)
	_check(pw.enclosed(inner, "inner"), "an equal-height mass inside another is dropped")
	_check(not pw.enclosed(outer, "outer"), "the enclosing mass stays")
	_check(not pw.enclosed(inner, "tall_inner"), "a taller mass inside stays")
	var low := PartyWalls.new()
	low._add_outline(outer, [], "outer", 12.0)
	low._add_outline(inner, [], "inner", 12.0)
	_check(not low.enclosed(inner, "inner", 3.0 * WorldScale.metres_to_units()),
		"a roof rising above the enclosing top keeps the mass")
	var twins := PartyWalls.new()
	twins._add_outline(inner, [], "first", 12.0)
	twins._add_outline(inner, [], "second", 12.0)
	_check(not twins.enclosed(inner, "first") and twins.enclosed(inner, "second"),
		"of two equal masses on one outline only the later is dropped")
	var u := PartyWalls.new()
	u._add_outline(_ring([[0, 0], [30, 0], [30, 30], [20, 30], [20, 10], [10, 10], [10, 30], [0, 30]]),
		[], "u", 12.0)
	var across := _ring([[5, 5], [25, 5], [25, 25], [5, 25]])
	u._add_outline(across, [], "across", 12.0)
	_check(not u.enclosed(across, "across"), "a mass spanning a notch is not enclosed")
	var court := PartyWalls.new()
	court._add_outline(outer, [_ring([[8, 8], [12, 8], [12, 12], [8, 12]])], "court", 12.0)
	court._add_outline(inner, [], "in_court", 12.0)
	_check(not court.enclosed(inner, "in_court"), "a mass over a courtyard is not enclosed")

## A wall along x at z = 0, the building behind it (z < 0), on the ground.
func _behind_wall(p: Vector3) -> bool:
	return p.z < 0.0 or p.y < 0.0

## `hidden(p)`: p lies inside the building the fixture stands against
## (faces flush on its wall or roof are never seen); with `solids` a
## point inside one of the fixture's own closed boxes is hidden too.
func _expect_clean(root: Node3D, what: String, hidden: Callable, solids: bool = false) -> void:
	var hits := _fights(root, hidden, solids)
	_check(hits.is_empty(), "%s: %d coplanar overlaps, first %s" % [what, hits.size(),
		hits[0] if not hits.is_empty() else ""])

## Triangle pairs of `root`'s meshes lying in one plane, same facing,
## overlapping. Double-sided materials (iron railings) are left out.
func _fights(root: Node3D, hidden: Callable, solids: bool) -> Array[String]:
	var m := WorldScale.metres_to_units()
	var tris: Array = []
	for c in root.get_children():
		if not (c is MeshInstance3D) or (c as MeshInstance3D).mesh == null:
			continue
		var mi := c as MeshInstance3D
		for s in mi.mesh.get_surface_count():
			var mat := mi.mesh.surface_get_material(s) as BaseMaterial3D
			if mat != null and mat.cull_mode == BaseMaterial3D.CULL_DISABLED:
				continue
			var arr := MeshArrays.surface(mi.mesh, s)
			var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			var vn: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
			var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
			for t in idx.size() / 3:
				var p0 := mi.transform * v[idx[t * 3]]
				var p1 := mi.transform * v[idx[t * 3 + 1]]
				var p2 := mi.transform * v[idx[t * 3 + 2]]
				var n := (p1 - p0).cross(p2 - p0)
				if n.length_squared() < 1e-12:
					continue
				# Facing out: the side its vertex normals take.
				if not vn.is_empty() and n.dot(mi.transform.basis * vn[idx[t * 3]]) < 0.0:
					n = -n
				tris.append([p0, p1, p2, n.normalized()])
	var out: Array[String] = []
	for i in tris.size():
		var ti: Array = tris[i]
		var n: Vector3 = ti[3]
		for j in range(i + 1, tris.size()):
			var tj: Array = tris[j]
			if n.dot(tj[3]) < COS_TOL:
				continue
			var off := PLANE_TOL_M * m
			if absf(n.dot(tj[0] - ti[0])) > off or absf(n.dot(tj[1] - ti[0])) > off \
					or absf(n.dot(tj[2] - ti[0])) > off:
				continue
			var shared := _overlap(ti, tj)
			var area: float = shared[0]
			if area <= AREA_TOL_M2 * m * m:
				continue
			# Seen only from open air: probe a centimetre off the shared face.
			var probe: Vector3 = shared[1] + n * 0.01 * m
			if hidden.call(probe) or (solids and _inside(probe, tris)):
				continue
			out.append("%s / %s (%.4f m²)" % [str(ti.slice(0, 3)), str(tj.slice(0, 3)), area / (m * m)])
	return out

## Whether `p` lies inside the closed boxes `tris` make (ray parity).
func _inside(p: Vector3, tris: Array) -> bool:
	var dir := Vector3(0.137, 0.981, 0.069).normalized()
	var hits := 0
	for t: Array in tris:
		if Geometry3D.ray_intersects_triangle(p, dir, t[0], t[1], t[2]) != null:
			hits += 1
	return hits % 2 == 1

## [area, centroid] of what two coplanar triangles share.
func _overlap(a: Array, b: Array) -> Array:
	var n: Vector3 = a[3]
	var u := ((a[1] as Vector3) - (a[0] as Vector3)).normalized()
	var w := n.cross(u)
	var o: Vector3 = a[0]
	var pa := PackedVector2Array()
	var pb := PackedVector2Array()
	for k in 3:
		pa.append(Vector2(((a[k] as Vector3) - o).dot(u), ((a[k] as Vector3) - o).dot(w)))
		pb.append(Vector2(((b[k] as Vector3) - o).dot(u), ((b[k] as Vector3) - o).dot(w)))
	var area := 0.0
	var c := Vector2.ZERO
	for poly in Geometry2D.intersect_polygons(pa, pb):
		var pa_ := absf(RingGeometry.signed_area(poly))
		area += pa_
		c += RingGeometry.centroid(poly) * pa_
	c = c / area if area > 0.0 else Vector2.ZERO
	return [area, o + u * c.x + w * c.y]
