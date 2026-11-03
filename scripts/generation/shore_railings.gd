class_name ShoreRailings
extends RefCounted

## Pedestrian waterfront guardrails where a mapped coastal edge runs
## alongside a paved walk. Existing mapped barriers win. The coastline
## supplies the edge; no rail is guessed on an unwalked natural shore.
## Ultra only, within the same near-eye radius as other street furniture.
const RADIUS_M := 400.0
const CELL_M := 32.0
const WALK_CLASSES := ["footway", "pedestrian", "path", "cycleway"]
const PAVED := ["asphalt", "paved", "paving_stones", "sett", "cobblestone", "concrete", "stone"]
const BARRIERS := ["fence", "railing", "guard_rail", "handrail", "wall"]

static func build(root: Node3D, data: LocationData, ground: GroundTruth) -> int:
	if not RenderQuality.ultra_desktop(data.quality_preset) or ground.shoreline == null \
			or not ground.shoreline.ready:
		return 0
	var centre := View360.spawn_xz(data)
	var m := WorldScale.metres_to_units()
	var walks := _index(data.roads, centre, m, false)
	if walks.is_empty():
		return 0
	var barriers := _index(data.barriers, centre, m, true)
	var buf := TreeMeshLibrary.Buf.new()
	var count := 0
	for seg in ground.shoreline.segments:
		var a: Vector2 = seg["a"]
		var b: Vector2 = seg["b"]
		var mid := (a + b) * 0.5
		if mid.distance_squared_to(centre) > pow(RADIUS_M * m, 2.0):
			continue
		var body: Dictionary = ground.shoreline.domains.bodies[int(seg["body"])]
		if not bool(body.get("tidal", false)):
			continue
		if not eligible(seg, _near(walks, mid, m), _near(barriers, mid, m), m):
			continue
		# The bank's top is the canonical shoreline height; move a little
		# inland so posts sit on the promenade instead of the water face.
		var land: Vector2 = seg["land"]
		var p0 := a + land * 0.35 * m
		var p1 := b + land * 0.35 * m
		StreetProps._fence_piece(buf, p0, p1, float(seg["top_a"]), float(seg["top_b"]), 1.1 * m, m)
		count += 1
	if not buf.idx.is_empty():
		var mesh := ArrayMesh.new()
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, buf.arrays())
		var mi := MeshInstance3D.new()
		mi.name = "ShoreRailings"
		mi.mesh = mesh
		mi.material_override = StreetProps._fence_material()
		root.add_child(mi)
	return count

## A guardrail needs a parallel paved path on its landward side. A mapped
## barrier nearby suppresses the inferred rail, including at junctions.
static func eligible(seg: Dictionary, walks: Array, barriers: Array, m: float) -> bool:
	var a: Vector2 = seg["a"]
	var b: Vector2 = seg["b"]
	var mid := (a + b) * 0.5
	var land: Vector2 = seg["land"]
	var dir := (b - a).normalized()
	if dir.length_squared() < 0.5:
		return false
	for line in barriers:
		var q := Geometry2D.get_closest_point_to_segment(mid, line[0], line[1])
		if q.distance_to(mid) < 3.0 * m:
			return false
	for line in walks:
		var q := Geometry2D.get_closest_point_to_segment(mid, line[0], line[1])
		if q.distance_to(mid) <= (8.0 + float(line[2]) * 0.5) * m \
				and (q - mid).dot(land) >= -0.5 * m \
				and absf((line[1] - line[0]).normalized().dot(dir)) >= 0.75:
			return true
	return false

## Spatial bins keep the edge test local even in a dense city.
static func _index(rows: Array, centre: Vector2, m: float, barriers: bool) -> Dictionary:
	var cells := {}
	var cell := CELL_M * m
	var reach := (RADIUS_M + 30.0) * m
	for row in rows:
		if not (row is Dictionary) or bool(row.get("tunnel", false)) or bool(row.get("bridge", false)):
			continue
		var cls := str(row.get("class", ""))
		if barriers:
			if cls not in BARRIERS:
				continue
		else:
			var surface := str(row.get("surface", ""))
			if cls not in WALK_CLASSES or (surface != "" and surface not in PAVED):
				continue
		var pts: PackedVector2Array = row.get("points", PackedVector2Array())
		for i in pts.size() - 1:
			var a := pts[i]
			var b := pts[i + 1]
			if Geometry2D.get_closest_point_to_segment(centre, a, b).distance_to(centre) > reach:
				continue
			var lo := Vector2i(floori(minf(a.x, b.x) / cell), floori(minf(a.y, b.y) / cell))
			var hi := Vector2i(floori(maxf(a.x, b.x) / cell), floori(maxf(a.y, b.y) / cell))
			var line := [a, b, maxf(float(row.get("width_m", 2.0)), 0.0)]
			for x in range(lo.x, hi.x + 1):
				for z in range(lo.y, hi.y + 1):
					var key := Vector2i(x, z)
					if not cells.has(key):
						cells[key] = []
					cells[key].append(line)
	return cells

static func _near(cells: Dictionary, p: Vector2, m: float) -> Array:
	var cell := CELL_M * m
	var key := Vector2i(floori(p.x / cell), floori(p.y / cell))
	var out: Array = []
	for x in range(-1, 2):
		for z in range(-1, 2):
			out.append_array(cells.get(key + Vector2i(x, z), []))
	return out
