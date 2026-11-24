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
	# Historic Venetian *fondamenta* have open Istrian-stone canal edges without modern crash-railings (`VN-9.2`).
	if CityStyles.city_of_region(CityStyles.region_at(data.latitude, data.longitude)) == "venice":
		return 0
	var centre := View360.spawn_xz(data)
	var m := WorldScale.metres_to_units()
	var walks := _index(data.roads, centre, m, false)
	if walks.is_empty():
		return 0
	var barriers := _index(data.barriers, centre, m, true)
	var bridge_spans := LandmarkSites.bridge_spans(data)
	var bridge_roads := _index_bridges(data.roads, centre, m)
	var domains: ShoreDomains = ground.shoreline.domains
	var buf := TreeMeshLibrary.Buf.new()
	var count := 0
	for seg in ground.shoreline.segments:
		# Only walled/quayed edges carry a promenade rail: a natural sloping
		# shore has no retaining face and dips into the water.
		if str(seg.get("kind", "")) != "hard":
			continue
		var a: Vector2 = seg["a"]
		var b: Vector2 = seg["b"]
		var mid := (a + b) * 0.5
		if mid.distance_squared_to(centre) > pow(RADIUS_M * m, 2.0):
			continue
		var body: Dictionary = domains.bodies[int(seg["body"])]
		if not railed_body(body, data):
			continue
		if minf(float(seg["top_a"]) - float(seg["water_a"]),
				float(seg["top_b"]) - float(seg["water_b"])) < 0.25 * m:
			continue
		if not eligible(seg, _near(walks, mid, m), _near(barriers, mid, m), m, domains):
			continue
		# The bank's top is the canonical shoreline height; move a little
		# inland so posts sit on the promenade instead of the water face.
		var land: Vector2 = seg["land"]
		var p0 := a + land * 0.35 * m
		var p1 := b + land * 0.35 * m
		if domains.at(p0) >= 0 or domains.at(p1) >= 0 or domains.at((p0 + p1) * 0.5) >= 0:
			continue
		if on_bridge(p0, p1, bridge_spans, _near(bridge_roads, mid, m), m):
			continue
		StreetProps._fence_piece(buf, p0, p1, float(seg["top_a"]), float(seg["top_b"]), 1.1 * m, m)
		count += 1
	if not buf.idx.is_empty():
		var mesh := ArrayMesh.new()
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, buf.arrays())
		var mi := MeshInstance3D.new()
		mi.name = "ShoreRailings"
		mi.mesh = mesh
		mi.material_override = _white_rail_material() if _bangkok(data) else StreetProps._fence_material()
		root.add_child(mi)
	return count

static var _white_mat: StandardMaterial3D = null

static func _bangkok(data: LocationData) -> bool:
	return data != null and CityStyles.city_of_region(CityStyles.region_at(data.latitude, data.longitude)) == "bangkok"

static func _white_rail_material() -> StandardMaterial3D:
	if _white_mat == null:
		_white_mat = LandmarkMaterials.pbr("render", "#F2EFE6", 2.0)
	return _white_mat

## Which water carries a rail: tidal bodies, and in Stockholm or Bangkok every
## urban canal and river body (except ornamental pools).
static func railed_body(body: Dictionary, data: LocationData) -> bool:
	if bool(body.get("still_pool", false)):
		return false
	return bool(body.get("tidal", false)) or ShoreApron.stockholm(data) or _bangkok(data)

## A guardrail needs a parallel paved path on its landward side. A mapped
## barrier nearby suppresses the inferred rail, including at junctions.
static func eligible(seg: Dictionary, walks: Array, barriers: Array, m: float,
		domains: ShoreDomains = null) -> bool:
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
		if domains != null and domains.at(q) >= 0:
			continue
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

## True when a shoreline railing segment crosses a registry bridge deck or an
## OSM bridge way landing on the bank, so guardrails never block bridge roads.
static func on_bridge(p0: Vector2, p1: Vector2, bridge_spans: Array,
		bridge_roads: Array, m: float) -> bool:
	var mid := (p0 + p1) * 0.5
	for sp in bridge_spans:
		var at: Vector2 = sp[0]
		var entry: Dictionary = sp[1]
		var axis := LandmarkSites.axis(entry)
		var cross := Vector2(-axis.y, axis.x)
		var half_l := float(entry.get("span_m", 0.0)) * 0.5 * m + 3.0 * m
		var half_w := maxf(float(entry.get("deck_width_m", 0.0)) * 0.5,
			LandmarkSites.clear_m(entry) * 0.5) * m + 1.5 * m
		for pt in [p0, mid, p1]:
			var d: Vector2 = pt - at
			if absf(d.dot(axis)) <= half_l and absf(d.dot(cross)) <= half_w:
				return true
	for line in bridge_roads:
		var pad := (float(line[2]) * 0.5 + 2.0) * m
		for pt in [p0, mid, p1]:
			if Geometry2D.get_closest_point_to_segment(pt, line[0], line[1]).distance_to(pt) <= pad:
				return true
	return false

## Spatial bins for OSM bridge ways near `centre`.
static func _index_bridges(rows: Array, centre: Vector2, m: float) -> Dictionary:
	var cells := {}
	var cell := CELL_M * m
	var reach := (RADIUS_M + 30.0) * m
	for row in rows:
		if not (row is Dictionary) or bool(row.get("tunnel", false)) or not bool(row.get("bridge", false)):
			continue
		var pts: PackedVector2Array = row.get("points", PackedVector2Array())
		for i in pts.size() - 1:
			var a := pts[i]
			var b := pts[i + 1]
			if Geometry2D.get_closest_point_to_segment(centre, a, b).distance_to(centre) > reach:
				continue
			var lo := Vector2i(floori(minf(a.x, b.x) / cell), floori(minf(a.y, b.y) / cell))
			var hi := Vector2i(floori(maxf(a.x, b.x) / cell), floori(maxf(a.y, b.y) / cell))
			var line := [a, b, maxf(float(row.get("width_m", 4.0)), 2.0)]
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
