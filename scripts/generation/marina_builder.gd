class_name MarinaBuilder
extends RefCounted

## Marina pontoons and moored boats (desktop Ultra, Ultra pass): Port
## Hercule is mapped pier by pier (man_made=pier, floating=yes) but
## nothing drew the pontoons or the yachts along them.
## * Pontoon decks: a narrow wood-grey ribbon on the water along every
##   floating pier.
## * Boats: moored stern-to along both sides of every floating pier (or
##   any pier standing in carved water) longer than MIN_PIER_M, bow out,
##   never overlapping a pontoon, a building, a road or each other. Where
##   the DEM has no carved water (Monaco's sea sits at a depth datum, so
##   the harbour reads as flat terrain at sea level) a berth counts as wet
##   when the terrain is flat within FLAT_M of the pier's height. Motor yachts and sailboats (mast, furled sail) of 7–29 m
##   (small ones commonest); hulls mostly white, some navy, grey and
##   cream. Placement is a fixed walk with position hashes, so the same
##   harbour always gets the same fleet.
## One MultiMesh per kind, true-metre meshes, nearest MAX_BOATS kept.
## Boats under 9 m are runabouts / consoles / RIBs, 9-14 m sport cruisers,
## longer ones flybridge yachts, sailboats from 7.5 m (VesselPrototypes).
## Coastal Mediterranean marinas also berth 10–22 m cruising catamarans.
## Boats are batched per BATCH_M cell (coarser when that would break
## MAX_DRAW_CALLS); each cell swaps to a "_far" mesh without rails,
## rigging and mullions beyond NEAR_M of the camera. Large ships (cruise liners and ferries from
## QuayMoorings.liners, cargo ships from CargoBerths) are committed one by
## one by LargeShips, outside the MultiMesh budget.

const RADIUS_M := 800.0
const MAX_BOATS := 700
## Near + far surfaces of every boat batch + pontoon. One batch per kind
## (VesselPrototypes.KINDS) always fits; finer cells only while they do.
const MAX_DRAW_CALLS := 80
## Boats farther than this from the camera use the reduced "_far" meshes (m).
const NEAR_M := 250.0
## Side of the square cells boats are batched in for the near/far switch
## (m); doubled, then dropped to one batch per kind, to fit MAX_DRAW_CALLS.
const BATCH_M := 120.0
const MIN_PIER_M := 20.0
const DECK_W_M := 2.2
const DECK_UP_M := 0.3
## Water deeper than this at both ends of a boat, or it stays out (m).
const MIN_DEPTH_M := 0.3
## Terrain within this of the pier's height counts as a flat basin (m):
## the smoothed DEM wobbles ~9 m across Port Hercule's quays and basin.
const FLAT_M := 5.0
## A berth's terrain (stern, middle, bow) may differ by this much (m); the
## boat sits at the median. More and a quay ramp would bury it.
const SPREAD_M := 2.5
const GAP_M := 0.9
const CELL_M := 0.75
const HULL_COLOURS := [Color(0.88, 0.88, 0.86), Color(0.88, 0.88, 0.86), Color(0.88, 0.88, 0.86),
	Color(0.88, 0.88, 0.86), Color(0.88, 0.88, 0.86), Color(0.88, 0.88, 0.86),
	Color(0.80, 0.76, 0.62), Color(0.03, 0.04, 0.09), Color(0.06, 0.06, 0.07), Color(0.30, 0.31, 0.32)]
const SAIL_SHARE := 0.35
## The boat meshes are 10 m long; an instance scales them uniformly.
const MESH_LEN_M := 10.0

## Boats [position, yaw, scale, kind, colour], deck ribbons (each an
## Array of [x, z, water y]) for `data`'s piers, nearest boats first, and
## large ships (LargeShips entries: liners, ferries, then cargo ships).
static func plan(data: LocationData, ground: GroundTruth, m2u: float,
		mask: VegetationMask = null) -> Dictionary:
	var boats: Array = []
	var decks: Array = []
	var taken := {}
	var centre := View360.spawn_xz(data)
	var r2 := pow(RADIUS_M * m2u, 2.0)
	var cats := mediterranean(data)
	var piers: Array = []
	for p in data.piers:
		var pts: PackedVector2Array = (p as Dictionary).get("points", PackedVector2Array())
		if pts.size() < 2 or (pts[pts.size() / 2] - centre).length_squared() > r2:
			continue
		piers.append(p)
	# Pontoon decks first, so boats keep off every one of them.
	for p in piers:
		if not bool((p as Dictionary).get("floating", false)):
			continue
		var pts: PackedVector2Array = (p as Dictionary)["points"]
		if _length(pts) < MIN_PIER_M * m2u:
			continue
		decks.append(_deck(pts, ground, m2u, taken))
	# Reserve large berths before filling the harbour with small craft.
	QuayMoorings.begin_plan(data, m2u)
	var liners := QuayMoorings.liners(data, ground, taken, m2u, mask)
	liners.append_array(CargoBerths.plan(data, ground, taken, m2u, mask, liners))
	QuayMoorings.end_plan()
	var k := 0
	for p in piers:
		var pts: PackedVector2Array = (p as Dictionary)["points"]
		var total := _length(pts)
		if total < MIN_PIER_M * m2u:
			continue
		var carved := ground.water_at(pts[pts.size() / 2].x, pts[pts.size() / 2].y) > MIN_DEPTH_M * m2u
		if not carved and not bool((p as Dictionary).get("floating", false)):
			continue  # a quay or mole on dry ground: no berths
		var y_ref := _pier_height(pts, ground)
		k += 1
		var t := 1.5 * m2u
		var slot := 0
		while t < total - 1.0 * m2u:
			var at := _at(pts, t)
			var pos: Vector2 = at[0]
			var dir: Vector2 = at[1]
			var nrm := Vector2(-dir.y, dir.x)
			var widest := 0.0
			for side: float in [-1.0, 1.0]:
				var h := _hash(pos.x, pos.y, float(k * 7 + slot) + (0.5 if side > 0.0 else 0.0))
				var len_m := 5.0 + 24.0 * h * h
				var sail := _hash(pos.y, pos.x, float(k * 13 + slot)) < SAIL_SHARE
				var pick := _hash(pos.x + 1.7, pos.y, float(slot))
				var kind := _kind(len_m, sail, pick)
				if cats and sail and len_m >= 10.0 and len_m <= 22.0 and pick < 0.35:
					kind = "catamaran"
				var beam_m := (CatamaranModel.BERTH_BEAM_SHARE if kind == "catamaran" else 0.3) * len_m
				widest = maxf(widest, beam_m)
				var stern: Vector2 = pos + nrm * side * (DECK_W_M * 0.5 + 0.5) * m2u
				var out := nrm * side
				var bow := stern + out * len_m * m2u
				if not _wet(ground, stern, m2u, y_ref, mask, true) or not _wet(ground, bow, m2u, y_ref, mask) \
						or not _wet(ground, stern + out * len_m * 0.5 * m2u, m2u, y_ref, mask):
					continue
				if kind == "catamaran" and not _wide_wet(ground, stern, out, len_m, beam_m, m2u, y_ref, mask):
					continue
				var y := _berth_y(ground, stern, stern + out * len_m * 0.5 * m2u, bow, m2u)
				if is_nan(y) or not _claim(taken, stern, out, len_m, beam_m + (CELL_M * 2.0 if kind == "catamaran" else 0.0), m2u):
					continue
				var col: Color = HULL_COLOURS[int(_hash(pos.x + 3.1, pos.y, float(slot)) * HULL_COLOURS.size()) % HULL_COLOURS.size()]
				boats.append([Vector3(stern.x, y, stern.y), atan2(-out.y, out.x),
					len_m / MESH_LEN_M * m2u, kind, col])
			slot += 1
			t += (widest + GAP_M) * m2u
	boats.append_array(QuayMoorings.plan(data, ground, taken, m2u, mask))
	boats.sort_custom(func(a: Array, b: Array) -> bool:
		return Vector2((a[0] as Vector3).x - centre.x, (a[0] as Vector3).z - centre.y).length_squared() \
			< Vector2((b[0] as Vector3).x - centre.x, (b[0] as Vector3).z - centre.y).length_squared())
	if boats.size() > MAX_BOATS:
		boats.resize(MAX_BOATS)
	return {"boats": boats, "decks": decks, "liners": liners}

## Adds the pontoons and boats under one "Marina" node of `root`; returns
## the number of boats.
static func build(root: Node3D, data: LocationData, ground: GroundTruth,
		mask: VegetationMask = null) -> int:
	if not RenderQuality.ultra_desktop(data.quality_preset):
		return 0
	var m2u := WorldScale.metres_to_units()
	var p := plan(data, ground, m2u, mask)
	var boats: Array = p["boats"]
	var decks: Array = p["decks"]
	var liners: Array = p["liners"]
	if boats.is_empty() and decks.is_empty() and liners.is_empty():
		return 0
	var holder := Node3D.new()
	holder.name = "Marina"
	if not decks.is_empty():
		var dm := MeshInstance3D.new()
		dm.name = "Pontoons"
		dm.mesh = _deck_mesh(decks, m2u)
		dm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		holder.add_child(dm)
	var cells := _cells(boats, MAX_DRAW_CALLS - (0 if decks.is_empty() else 1), m2u)
	for key in cells:
		var list: Array = cells[key]
		var near_mesh := mesh(list[0][3])
		var far_mesh := mesh(list[0][3] + "_far")
		var bounds := CellBatches.bounds(list.map(func(b: Array) -> Transform3D: return _transform(b)), near_mesh.get_aabb().merge(far_mesh.get_aabb()))
		_add_batch(holder, list, near_mesh, "Boats_%s" % key, 0.0, NEAR_M * m2u, bounds)
		var far := _add_batch(holder, list, far_mesh, "Boats_%s_far" % key, NEAR_M * m2u, 0.0, bounds)
		far.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	LargeShips.commit(holder, liners, View360.spawn_xz(data), m2u)
	root.add_child(holder)
	return boats.size() + liners.size()

static func _add_batch(holder: Node3D, list: Array, boat_mesh: Mesh, batch_name: String,
		begin: float, end: float, bounds: AABB) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = boat_mesh
	mm.instance_count = list.size()
	for i in list.size():
		var b: Array = list[i]
		mm.set_instance_transform(i, _transform(b))
		mm.set_instance_color(i, b[4])
	var mmi := MultiMeshInstance3D.new()
	mmi.name = batch_name
	mmi.multimesh = mm
	mmi.custom_aabb = bounds
	CellBatches.ranged(mmi, begin, end)
	holder.add_child(mmi)
	return mmi

static func _transform(b: Array) -> Transform3D:
	return Transform3D(Basis(Vector3.UP, float(b[1])).scaled(Vector3.ONE * float(b[2])), b[0])

## Boats bucketed by kind and BATCH_M cell, the cell doubled while the
## near + far surfaces of all buckets exceed `budget`, down to one bucket
## per kind (which always fits).
static func _cells(boats: Array, budget: int, m2u: float) -> Dictionary:
	var at_of := func(b: Array) -> Vector3: return b[0]
	var kind_of := func(b: Array) -> String: return b[3]
	var cells := {}
	for cell in [BATCH_M, BATCH_M * 2.0, BATCH_M * 4.0, BATCH_M * 8.0, INF]:
		cells = CellBatches.group(boats, float(cell) * m2u, at_of, kind_of)
		var calls := 0
		for key in cells:
			var kind: String = cells[key][0][3]
			calls += mesh(kind).get_surface_count() + mesh(kind + "_far").get_surface_count()
		if calls <= budget:
			break
	return cells

# --- Placement helpers ---------------------------------------------------

static func _length(pts: PackedVector2Array) -> float:
	var l := 0.0
	for i in pts.size() - 1:
		l += pts[i].distance_to(pts[i + 1])
	return l

## [point, unit direction] at arc length `t` along `pts`.
static func _at(pts: PackedVector2Array, t: float) -> Array:
	var run := 0.0
	for i in pts.size() - 1:
		var seg := pts[i].distance_to(pts[i + 1])
		if seg > 0.0 and run + seg >= t:
			var d := (pts[i + 1] - pts[i]) / seg
			return [pts[i] + d * (t - run), d]
		run += seg
	var last := pts.size() - 1
	return [pts[last], (pts[last] - pts[last - 1]).normalized()]

## Boat Y at a berth: the water surface in carved water, else the median
## terrain height (a flat-datum harbour draws its sea as terrain), NAN
## when the terrain differs by more than SPREAD_M along the boat.
static func _berth_y(ground: GroundTruth, stern: Vector2, mid: Vector2, bow: Vector2,
		m2u: float) -> float:
	if ground.water_at(stern.x, stern.y) > MIN_DEPTH_M * m2u:
		return ground.water_level_at(stern.x, stern.y)
	var hs := [ground.height_at_world(stern.x, stern.y), ground.height_at_world(mid.x, mid.y),
		ground.height_at_world(bow.x, bow.y)]
	hs.sort()
	if float(hs[2]) - float(hs[0]) > SPREAD_M * m2u:
		return NAN
	return float(hs[1]) - 0.3 * m2u

## Terrain height along a pier (its median), the berths' reference level.
static func _pier_height(pts: PackedVector2Array, ground: GroundTruth) -> float:
	var hs: Array = []
	for q in pts:
		hs.append(ground.height_at_world(q.x, q.y))
	hs.sort()
	return float(hs[hs.size() / 2])

## A berth point is wet in carved water, else on flat terrain at the
## pier's level that no building or road covers.
static func _wet(ground: GroundTruth, p: Vector2, m2u: float, y_ref: float,
		mask: VegetationMask, at_pier: bool = false) -> bool:
	if not ground.is_inside(p.x, p.y):
		return false
	# The pier itself is marked ROAD_EDGE for ground-cover exclusion. A
	# stern directly beside it must not reject its own pontoon verge;
	# actual buildings and carriageways still veto even carved-water berths.
	var bits := VegetationMask.BUILDING | VegetationMask.ROAD
	if not at_pier:
		bits |= VegetationMask.ROAD_EDGE
	if mask != null and mask.blocked(p.x, p.y, bits, 0.5):
		return false
	if ground.water_at(p.x, p.y) > MIN_DEPTH_M * m2u:
		return true
	return absf(ground.height_at_world(p.x, p.y) - y_ref) <= FLAT_M * m2u

static func _cell(p: Vector2, m2u: float) -> Vector2i:
	return Vector2i(floori(p.x / (CELL_M * m2u)), floori(p.y / (CELL_M * m2u)))

## Marks the boat's footprint taken, or returns false when any of it is.
static func _claim(taken: Dictionary, stern: Vector2, out: Vector2, len_m: float,
		beam_m: float, m2u: float) -> bool:
	var side := Vector2(-out.y, out.x)
	var cells: Array[Vector2i] = []
	var a := 0.6
	while a <= len_m:
		var w := -beam_m * 0.5
		while w <= beam_m * 0.5 + 0.01:
			var c := _cell(stern + (out * a + side * w) * m2u, m2u)
			if taken.has(c):
				return false
			cells.append(c)
			w += CELL_M
		a += CELL_M
	for c in cells:
		taken[c] = true
	return true

## A floating pier's deck as [x, z, water y] posts (every ~3 m), marking
## its cells taken.
static func _deck(pts: PackedVector2Array, ground: GroundTruth, m2u: float, taken: Dictionary) -> Array:
	var out: Array = []
	var total := _length(pts)
	var t := 0.0
	while t <= total:
		var at := _at(pts, t)
		var q: Vector2 = at[0]
		var nrm := Vector2(-(at[1] as Vector2).y, (at[1] as Vector2).x)
		out.append([q.x, q.y, maxf(ground.water_level_at(q.x, q.y), ground.height_at_world(q.x, q.y)), nrm.x, nrm.y])
		var w := -0.9
		while w <= 0.9:
			taken[_cell(q + nrm * w * m2u, m2u)] = true
			w += 0.45
		t += 3.0 * m2u
	return out

## Mediterranean scenery requires coastal evidence, excluding inland lakes
## and the Atlantic coast west/north of the Strait of Gibraltar.
static func mediterranean(data: LocationData) -> bool:
	if data.latitude < 30.0 or data.latitude > 46.0 or data.longitude < -5.6 or data.longitude > 36.5:
		return false
	if data.longitude < 0.0 and data.latitude > 42.0:
		return false
	if data.country in ["BG", "RO", "UA", "RU", "GE"]:
		return false
	if WaterBuilder._has_coastline(data) or LandmarkTerrain.has_sea(data):
		return true
	for poly in data.land_polygons:
		if str(poly.get("class", "")) == "water" and bool(poly.get("tidal", false)):
			return true
	return false

static func _wide_wet(ground: GroundTruth, stern: Vector2, out: Vector2, length: float, beam: float,
		m2u: float, y_ref: float, mask: VegetationMask) -> bool:
	var cross := Vector2(-out.y, out.x)
	for along in [0.08, 0.5, 0.95]:
		for side in [-0.5, 0.5]:
			var p := stern + (out * length * float(along) + cross * beam * float(side)) * m2u
			if not _wet(ground, p, m2u, y_ref, mask):
				return false
	return true

## Prototype kind for a berth of `len_m`; `pick` splits the small boats.
static func _kind(len_m: float, sail: bool, pick: float) -> String:
	if sail and len_m >= 7.5:
		return "sail"
	if len_m < 9.0:
		return "rib" if pick < 0.4 else "day"
	return "yacht" if len_m >= 14.0 else "motor"

static func _hash(x: float, z: float, salt: float) -> float:
	var v := sin(x * 12.9898 + z * 78.233 + salt * 37.719) * 43758.5453
	return v - floor(v)

# --- Meshes (metres; +X bow, origin at the stern's waterline centre) -----

static func _deck_mesh(decks: Array, m2u: float) -> ArrayMesh:
	var b := TreeMeshLibrary.Buf.new()
	var half := DECK_W_M * 0.5 * m2u
	for posts in decks:
		for i in (posts as Array).size() - 1:
			var p0: Array = posts[i]
			var p1: Array = posts[i + 1]
			var up := DECK_UP_M * m2u
			var c := [Vector3(float(p0[0]) - float(p0[3]) * half, float(p0[2]) + up, float(p0[1]) - float(p0[4]) * half),
				Vector3(float(p0[0]) + float(p0[3]) * half, float(p0[2]) + up, float(p0[1]) + float(p0[4]) * half),
				Vector3(float(p1[0]) + float(p1[3]) * half, float(p1[2]) + up, float(p1[1]) + float(p1[4]) * half),
				Vector3(float(p1[0]) - float(p1[3]) * half, float(p1[2]) + up, float(p1[1]) - float(p1[4]) * half)]
			_quad(b, c, Vector3.UP)
	var m := ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, b.arrays())
	m.surface_set_material(0, _material("pontoon"))
	return m

## One quad, wound to face `out` (clockwise seen from the front).
static func _quad(b: TreeMeshLibrary.Buf, c: Array, out: Vector3) -> void:
	var cross := ((c[1] as Vector3) - (c[0] as Vector3)).cross((c[2] as Vector3) - (c[0] as Vector3))
	var order := [3, 2, 1, 0] if cross.dot(out) > 0.0 else [0, 1, 2, 3]
	TreeMeshLibrary._card(b, [c[order[0]], c[order[1]], c[order[2]], c[order[3]]],
		[out, out, out, out], [1.0, 1.0, 1.0, 1.0])

static func mesh(kind: String) -> ArrayMesh:
	return VesselPrototypes.mesh(kind)

static func _material(name: String) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	if name == "pontoon":
		m.albedo_color = Color(0.36, 0.33, 0.29)
		m.roughness = 0.85
	return m
