class_name BuildingWalls
extends RefCounted

## Wall and roof-cap geometry for BuildingBuilder: ring cleaning,
## textured wall extrusion and roof caps. Batch state stays on
## BuildingBuilder (_batch/_batch_key) so FarCityBuilder is unchanged.
static func _clean_ring(raw: PackedVector2Array) -> PackedVector2Array:
	var ring := PackedVector2Array(raw)
	while ring.size() > 1 \
			and ring[0].distance_to(ring[ring.size() - 1]) < 0.01:
		ring.remove_at(ring.size() - 1)
	if ring.size() < 3:
		return PackedVector2Array()
	if absf(RingGeometry.signed_area(ring)) < 0.01:
		return PackedVector2Array()
	return ring

## Vertical wall quads, one per ring edge. Outward normals come from
## the winding (exact for simple rings however concave — a centroid
## test can flip inside deep notches); `invert` flips them for a
## courtyard ring, whose walls face into the hole. Triangle order is
## picked per edge so the Godot front face (clockwise viewed from
## outside) lands on the outward normal. Wall UVs match BoxMesh (v = 1 at
## the base), so the facade grime stays at the ground and cornices stay
## upright. `cover` (PartyWalls.ring_cover, one partition per edge) splits
## an edge at its neighbours: wall below a neighbour's top is skipped,
## wall above a lower neighbour goes to `fire` (a blank firewall), and
## only exposed stretches carry the windowed facade.
## Height (m) of blank firewall above a lower neighbour before the
## windowed facade resumes on a wall that rises well past it.
const FIREWALL_BAND_M := 9.0
## Towers shorter than this have no plant floors in their shaft.
const MECH_MIN_STOREYS := 30
## A masonry front's elevation: the first upper storey of a decorated front
## stands taller (the piano nobile), and about half of the punched masonry
## fronts end in a plainer top storey with small windows (the attic).
const PIANO_STRETCH := 1.18
const ATTIC_SHARE := 0.5
const PIANO_PATTERNS: Array[String] = ["ornate", "brownstone"]
const ATTIC_PATTERNS: Array[String] = ["punched", "ornate", "brownstone"]
const BAND_WALL_SETS: Array[String] = ["brick", "stone", "limestone", "render", "terracotta"]

## Which elevation bands a building's upper storeys take: {piano, attic}.
## Needs three upper storeys, and every stretch either open or wholly hidden:
## a band above a lower neighbour would turn into firewall (see _walls).
static func band_plan(look: Dictionary, seed_v: float, upper_storeys: int,
		cover: Array, top: float) -> Dictionary:
	var pattern := str(look.get("pattern", ""))
	var out := {"piano": false, "attic": false}
	if upper_storeys < 3 or not str(look.get("wall_set", "")) in BAND_WALL_SETS:
		return out
	var clear := top - 0.3 * WorldScale.metres_to_units()
	for pieces: Array in cover:
		for pc: Array in pieces:
			if not is_inf(float(pc[2])) and float(pc[2]) < clear:
				return out
	out["piano"] = pattern in PIANO_PATTERNS
	out["attic"] = pattern in ATTIC_PATTERNS and str(look.get("window", "")) != "small" \
		and ArchitectureStyle._h(seed_v, 67) < ATTIC_SHARE
	return out

## The attic storey's look: small plain windows, no shutters, rails or
## variants, so it adds one texture per wall set, frame and bay at most.
static func attic_look(look: Dictionary) -> Dictionary:
	var out := look.duplicate()
	out["pattern"] = "punched"
	out["window"] = "small"
	out["shutter"] = Color.BLACK
	out["shutter_p"] = 0.0
	out["rails"] = 0.0
	out["variant"] = 0
	return out

## Storey height of the upper stack in world units: `top - y0` shared over `n`
## storeys, the first stretched when the plan has a piano nobile.
static func band_unit(y0: float, top: float, n: int, plan: Dictionary) -> float:
	return (top - y0) / (float(n) + (PIANO_STRETCH - 1.0 if bool(plan.get("piano", false)) else 0.0))

## A tower's plant floors among its `n` upper storeys, ascending: one every
## 20-30 storeys, and the top two when this mass carries the roofline.
## [] below MECH_MIN_STOREYS.
static func mech_floors(n: int, seed_v: float, roofline: bool) -> Array:
	if n < MECH_MIN_STOREYS:
		return []
	var out: Array = []
	var gap := 20 + int(ArchitectureStyle._h(seed_v, 61) * 11.0)
	var f := gap
	while f < n - 6:
		out.append(f)
		f += gap
	if roofline:
		out.append(n - 2)
		out.append(n - 1)
	return out

## y0..top as runs of `facade` split by single `louvre` storeys at `mech`.
static func _plant_run(root: Node3D, ring: PackedVector2Array, y0: float, top: float,
		facade: Material, louvre: Material, n: int, mech: Array, cover: Array,
		fire: Material, bay_scale: float) -> void:
	var unit := (top - y0) / float(n)
	var start := 0
	for f in mech:
		var floor_i := int(f)
		if floor_i > start:
			_walls(root, ring, y0 + float(start) * unit, y0 + float(floor_i) * unit, facade,
				float(floor_i - start), cover, fire, false, {}, bay_scale)
		_walls(root, ring, y0 + float(floor_i) * unit, y0 + float(floor_i + 1) * unit, louvre,
			1.0, cover, fire, false, {}, bay_scale)
		start = floor_i + 1
	if start < n:
		_walls(root, ring, y0 + float(start) * unit, top, facade, float(n - start),
			cover, fire, false, {}, bay_scale)

## Tile repeats up a wall of `wall_m` metres: the storey count, kept within
## ~30% of the style's floor height so a roof carved out of the total or a
## parent's storeys on a thin part never squash the windows.
static func storey_repeats(wall_m: float, storeys: int, floor_h: float) -> float:
	return roundf(clampf(float(maxi(storeys, 1)), maxf(1.0, wall_m / (floor_h * 1.35)),
		maxf(1.0, wall_m / (floor_h * 0.75))))

## The upper storeys y0..top as the plan's bands, `attic` on the top storey.
static func upper_walls(root: Node3D, ring: PackedVector2Array, y0: float, top: float,
		facade: Material, attic: Material, n: int, plan: Dictionary, cover: Array,
		fire: Material, bay_scale: float) -> void:
	var mech: Array = plan.get("mech", [])
	if not mech.is_empty():
		_plant_run(root, ring, y0, top, facade, plan["louvre"], n, mech, cover, fire, bay_scale)
		return
	var unit := band_unit(y0, top, n, plan)
	var y := y0
	var rest := n
	if bool(plan.get("piano", false)):
		_walls(root, ring, y, y + unit * PIANO_STRETCH, facade, 1.0, cover, fire, false, {}, bay_scale)
		y += unit * PIANO_STRETCH
		rest -= 1
	var y_top := top
	if bool(plan.get("attic", false)) and attic != null:
		y_top = top - unit
		_walls(root, ring, y_top, top, attic, 1.0, cover, fire, false, {}, bay_scale)
		rest -= 1
	if rest > 0:
		_walls(root, ring, y, y_top, facade, float(rest), cover, fire, false, {}, bay_scale)

static func _walls(root: Node3D, ring: PackedVector2Array, base: float,
		top: float, mat: Material, v_repeat: float = 1.0, cover: Array = [],
		fire: Material = null, invert: bool = false, edge_materials: Dictionary = {},
		bay_scale: float = 1.0) -> void:
	var ccw := RingGeometry.signed_area(ring) > 0.0
	# Style facades map UVs in real window bays (and, for tiled patterns,
	# real storeys) so windows keep their size on any wall; legacy
	# materials stretch 0..1 over the edge.
	var m2u := WorldScale.metres_to_units()
	var face := [PackedVector3Array(), PackedVector3Array(), PackedVector2Array(),
		PackedFloat32Array(), PackedInt32Array()]
	var per_material := {}
	var blank := [PackedVector3Array(), PackedVector3Array(), PackedVector2Array(),
		PackedFloat32Array(), PackedInt32Array()]
	var curve := curve_bays(ring, cover, FacadeMaterials.facade_uv(mat).x * bay_scale, edge_materials)
	for i in ring.size():
		var edge_mat: Material = edge_materials.get(i, mat)
		var edge_face := face
		if edge_mat != mat:
			if not per_material.has(edge_mat):
				per_material[edge_mat] = [PackedVector3Array(), PackedVector3Array(), PackedVector2Array(),
					PackedFloat32Array(), PackedInt32Array()]
			edge_face = per_material[edge_mat]
		var uvp := FacadeMaterials.facade_uv(edge_mat)
		var bay := uvp.x * bay_scale
		var ea := ring[i]
		var eb := ring[(i + 1) % ring.size()]
		if (eb - ea).length() < 0.001:
			continue
		var n := Vector2((eb - ea).y, -(eb - ea).x).normalized() if ccw \
			else Vector2(-(eb - ea).y, (eb - ea).x).normalized()
		if invert:
			n = -n
		var pieces: Array = cover[i] if i < cover.size() else [[0.0, 1.0, PartyWalls.OPEN]]
		for pc in pieces:
			var a := ea.lerp(eb, float(pc[0]))
			var b := ea.lerp(eb, float(pc[1]))
			var nb_top := float(pc[2])
			# A neighbour that stops below this wall (a raised tier) does not touch it.
			if is_inf(nb_top) or nb_top <= base:
				var u0 := 0.0
				var u1 := 1.0
				var v0 := 1.0
				if uvp.x > 0.0:
					var len_m := (b - a).length() / m2u
					# An edge under half a bay shows only the blank margin left
					# of the first window (a pillar must not become a zebra).
					u1 = 0.03 if len_m < bay * 0.5 else maxf(1.0, roundf(len_m / bay)) / uvp.y
					if curve.has(i):
						u0 = (curve[i] as Vector2).x / uvp.y
						u1 = (curve[i] as Vector2).y / uvp.y
					if uvp.z > 0.0:
						v0 = v_repeat
				_quad(edge_face, a, b, base, top, n, Vector2(u1, v0), u0)
			elif nb_top < top - 0.3 * m2u:
				var y0 := maxf(base, nb_top)
				var arr := blank if fire != null else edge_face
				# Blank only just above the neighbour: a tower's side rising
				# well past it has windows (a Manhattan tower, not a row house).
				# A curtain wall, or a wall given no firewall, has no blank band.
				var no_band := fire == null or str(edge_mat.get_meta("facade_set", "")) == "glass"
				var y1 := top
				if no_band or top - y0 > FIREWALL_BAND_M * m2u * 1.5:
					y1 = y0 if no_band else y0 + FIREWALL_BAND_M * m2u
					var len_m := (b - a).length() / m2u
					var u1 := 1.0
					if uvp.x > 0.0:
						u1 = 0.03 if len_m < bay * 0.5 else maxf(1.0, roundf(len_m / bay)) / uvp.y
					var v_up := (v_repeat if uvp.z > 0.0 else 1.0) * (top - y1) / maxf(top - base, 1e-4)
					_quad(edge_face, a, b, y1, top, n, Vector2(u1, v_up))
				if y1 > y0:
					_quad(arr, a, b, y0, y1, n, Vector2((b - a).length() / m2u / 4.0,
						(y1 - y0) / m2u / 4.0))
	_emit(root, face, mat)
	for edge_mat in per_material:
		_emit(root, per_material[edge_mat], edge_mat)
	if fire != null:
		_emit(root, blank, fire)

## Curved walls: OSM draws a curve as many short edges, and each began its
## windows afresh, squeezed, stretched or left blank. A run of CURVE_MIN_EDGES
## or more short, open edges, each turning under CURVE_TURN_DEG, shares one
## bay count spread along it by length. {edge: Vector2(u0, u1)} in bays;
## `skip` edges (another material's) stay out. FacadeRelief leaves these
## edges plain, since it lays relief on whole bays.
const CURVE_TURN_DEG := 25.0
const CURVE_EDGE_BAYS := 1.5
const CURVE_MIN_EDGES := 3

static func curve_bays(ring: PackedVector2Array, cover: Array, bay_m: float,
		skip: Dictionary = {}) -> Dictionary:
	var out := {}
	var n := ring.size()
	if bay_m <= 0.0 or n < CURVE_MIN_EDGES:
		return out
	var m2u := WorldScale.metres_to_units()
	var ok := PackedByteArray()
	ok.resize(n)
	for i in n:
		var len_m := ring[i].distance_to(ring[(i + 1) % n]) / m2u
		var pieces: Array = cover[i] if i < cover.size() else [[0.0, 1.0, PartyWalls.OPEN]]
		ok[i] = 1 if len_m > 0.001 and len_m < bay_m * CURVE_EDGE_BAYS and not skip.has(i) \
			and pieces.size() == 1 and is_inf(float(pieces[0][2])) else 0
	# link[i]: edge i runs on smoothly into edge i + 1.
	var link := PackedByteArray()
	link.resize(n)
	var cos_max := cos(deg_to_rad(CURVE_TURN_DEG))
	for i in n:
		var j := (i + 1) % n
		if ok[i] == 1 and ok[j] == 1:
			var d0 := (ring[j] - ring[i]).normalized()
			var d1 := (ring[(j + 1) % n] - ring[j]).normalized()
			link[i] = 1 if d0.dot(d1) > cos_max else 0
	# Start just after a break so no run wraps past edge 0; a ring that is
	# one curve all round (a round tower) starts at 0.
	var start := 0
	for i in n:
		if link[(i - 1 + n) % n] == 0:
			start = i
			break
	var run: Array[int] = []
	for k in n + 1:
		var i := (start + k) % n
		if k < n and ok[i] == 1 and (run.is_empty() or link[run[-1]] == 1):
			run.append(i)
			continue
		_spread_run(out, ring, run, bay_m)
		run = []
		if k < n and ok[i] == 1:
			run.append(i)
	return out

static func _spread_run(out: Dictionary, ring: PackedVector2Array, run: Array[int], bay_m: float) -> void:
	if run.size() < CURVE_MIN_EDGES:
		return
	var m2u := WorldScale.metres_to_units()
	var n := ring.size()
	var total := 0.0
	for i in run:
		total += ring[i].distance_to(ring[(i + 1) % n]) / m2u
	var bays := FacadeRelief.bay_count(total, bay_m)
	if bays == 0:
		return
	var s := 0.0
	for i in run:
		var len_m := ring[i].distance_to(ring[(i + 1) % n]) / m2u
		out[i] = Vector2(bays * s / total, bays * (s + len_m) / total)
		s += len_m

## One wall quad a→b from y0 to y1 facing n into `arr` [verts, normals,
## uvs, tangents, indices]; `uv` is the far corner (u at b, v at the base),
## `u0` the u at a.
static func _quad(arr: Array, a: Vector2, b: Vector2, y0: float, y1: float,
		n: Vector2, uv: Vector2, u0: float = 0.0) -> void:
	var verts: PackedVector3Array = arr[0]
	var normals: PackedVector3Array = arr[1]
	var uvs: PackedVector2Array = arr[2]
	var tangents: PackedFloat32Array = arr[3]
	var indices: PackedInt32Array = arr[4]
	var e := b - a
	var n3 := Vector3(n.x, 0.0, n.y)
	var k := verts.size()
	# Avoid Array literal alloc in hot loop: push individually.
	verts.push_back(Vector3(a.x, y0, a.y)); verts.push_back(Vector3(b.x, y0, b.y))
	verts.push_back(Vector3(b.x, y1, b.y)); verts.push_back(Vector3(a.x, y1, a.y))
	# Tangent along +u (a → b); w makes cross(N, T) · w point up, the
	# −v direction (v = 0 at the top), as Godot's own generate_tangents
	# writes it — the facade normal maps and window parallax need it.
	# Skip when batch mode: MassBatch discards tangents (recomputes later in commit).
	var use_tangents := BuildingBuilder._batch == null
	var t3 := Vector3.ZERO
	var w := 1.0
	if use_tangents:
		t3 = Vector3(e.x, 0.0, e.y).normalized()
		w = 1.0 if n3.cross(t3).y > 0.0 else -1.0
	for j in 4:
		normals.append(n3)
		if use_tangents:
			tangents.push_back(t3.x); tangents.push_back(t3.y); tangents.push_back(t3.z); tangents.push_back(w)
	uvs.push_back(Vector2(u0, uv.y)); uvs.push_back(Vector2(uv.x, uv.y))
	uvs.push_back(Vector2(uv.x, 0)); uvs.push_back(Vector2(u0, 0))
	# Forward order faces (e.y, -e.x): with s < 0 that is the
	# outward normal already, else the reversed order is emitted.
	var s := e.x * n.y - e.y * n.x
	if s > 0.0:
		indices.push_back(k); indices.push_back(k + 2); indices.push_back(k + 1)
		indices.push_back(k); indices.push_back(k + 3); indices.push_back(k + 2)
	else:
		indices.push_back(k); indices.push_back(k + 1); indices.push_back(k + 2)
		indices.push_back(k); indices.push_back(k + 2); indices.push_back(k + 3)

static func _emit(root: Node3D, arr: Array, mat: Material) -> void:
	if (arr[4] as PackedInt32Array).is_empty():
		return
	if BuildingBuilder._batch != null:
		BuildingBuilder._batch.add(BuildingBuilder._batch_key, mat, arr[0], arr[1], arr[2], arr[4])
		return
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = arr[0]
	arrays[Mesh.ARRAY_NORMAL] = arr[1]
	arrays[Mesh.ARRAY_TEX_UV] = arr[2]
	arrays[Mesh.ARRAY_TANGENT] = arr[3]
	arrays[Mesh.ARRAY_INDEX] = arr[4]
	# Arrays kept: LodRing merges these on the build thread (T7.5).
	TerrainBuilder._add(root, MeshArrays.mesh(arrays), mat)

## Flat roof cap over the triangulated ring: the whole roof for flat
## shapes, the eave-level seal under pitched T4.2 forms (it closes the
## gaps concave rings leave in apex fans). Triplets flip when the
## emitted triangle faces down, so the front face points up — the same
## convention as the terrain mesh.
## `cap` is the ring `idx` indexes when it is not `ring` (a courtyard
## block's keyhole ring, RingGeometry.bridge_holes); party edges get no
## cornice or parapet (the neighbour's wall continues there).
static func _roof_cap(root: Node3D, ring: PackedVector2Array,
		idx: PackedInt32Array, top: float, mat: Material, trim: int = 0,
		cap: PackedVector2Array = PackedVector2Array(),
		party: PackedByteArray = PackedByteArray(), wall_set: String = "") -> void:
	# Cornice / parapet relief at the wall top (BuildingTrim, near only);
	# a parapet sinks the deck behind it.
	BuildingTrim.add(root, ring, top, trim, party, wall_set)
	top = BuildingTrim.deck(top, trim)
	if not cap.is_empty():
		ring = cap
	# triangulate_polygon normalizes its output winding (a CW input
	# still yields CCW triplets), so the flip is read off the first
	# emitted triangle, not the ring: front.y equals its 2D cross.
	var flip := false
	if idx.size() >= 3:
		var p0 := ring[idx[0]]
		var p1 := ring[idx[1]]
		var p2 := ring[idx[2]]
		flip = (p1.x - p0.x) * (p2.y - p0.y) \
			- (p1.y - p0.y) * (p2.x - p0.x) < 0.0
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	for p in ring:
		verts.append(Vector3(p.x, top, p.y))
		normals.append(Vector3.UP)
		uvs.append(p * 0.05)
	var indices := PackedInt32Array()
	for t in idx.size() / 3:
		var i0 := idx[t * 3]
		var i1 := idx[t * 3 + 1]
		var i2 := idx[t * 3 + 2]
		if flip:
			indices.push_back(i0); indices.push_back(i2); indices.push_back(i1)
		else:
			indices.push_back(i0); indices.push_back(i1); indices.push_back(i2)
	if BuildingBuilder._batch != null:
		BuildingBuilder._batch.add(BuildingBuilder._batch_key, mat, verts, normals, uvs, indices)
		return
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	# +X tangent: the cap's normal map lights correctly (+v runs to +Z).
	var tangents := PackedFloat32Array()
	tangents.resize(verts.size() * 4)
	for i in verts.size():
		tangents[i * 4] = 1.0; tangents[i * 4 + 1] = 0.0; tangents[i * 4 + 2] = 0.0; tangents[i * 4 + 3] = 1.0
	arrays[Mesh.ARRAY_TANGENT] = tangents
	arrays[Mesh.ARRAY_INDEX] = indices
	# Arrays kept: LodRing merges these on the build thread (T7.5).
	TerrainBuilder._add(root, MeshArrays.mesh(arrays), mat)

## Floor height / default roof for the legacy box-mesh fallback only
## (corrupt footprints, AABB-only v1 dicts): box UVs cannot tile, so that
## path keeps the original Paris-vs-everywhere-else defaults. Every other
## building takes its numbers from ArchitectureStyle (T4.2 heights and
## roofs, now by region and kind).
const LEGACY_BOX = {
	"haussmann": {"floor_h": 3.1, "default_roof": "mansard"},
	"urban": {"floor_h": 3.0, "default_roof": "flat"},
}

static func _rect_ring(c: Vector2, size: Vector2, yaw: float) -> PackedVector2Array:
	var ring := PackedVector2Array()
	for corner in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
		ring.append(c + (corner * size * 0.5).rotated(yaw))
	return ring


static func _aabb_footprint(b: Dictionary) -> Dictionary:
	var out := b.duplicate()
	out.erase("parts")
	out["footprint"] = _rect_ring(Vector2(float(b["x"]), float(b["z"])),
		Vector2(float(b["size_x"]), float(b["size_z"])), 0.0)
	return out

## True-footprint masses for one §2.4 building: its building:part
## sub-polygons when present (OSM parts tile the parent outline, each
## with its own height, so the parent shell is skipped — extruding
## both would double coplanar walls), else the parent footprint alone.
## Returns true when at least one mass extruded; false routes to the
## logged AABB fallback in _real_buildings.
