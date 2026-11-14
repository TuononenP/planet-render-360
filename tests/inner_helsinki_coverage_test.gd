extends SceneTree

## Katajanokka, Kallio, Jätkäsaari and Ruoholahti: bespoke registry
## landmarks at their documented heights, built on their OSM outlines,
## searchable by name, with clearance that covers every footprint but does
## not swallow a neighbouring landmark, and the districts' fabric.
const TYPES := {
	"enso_gutzeit_hq": 24.0, "merikasarmi": 18.0, "katajanokka_terminal": 14.0,
	"kallio_library": 19.0, "kallio_virastotalo": 40.0, "linnanmaki": 75.0,
	"clarion_hotel": 78.0, "west_terminal_2": 18.0, "cable_factory": 28.0, "salmisaari_power_plant": 150.0,
}

func _init() -> void:
	var failures: Array[String] = []
	for type in TYPES:
		var entry := LocationData.entry_for_type(type)
		if entry.is_empty():
			failures.append(type + " missing from registry")
			continue
		if absf(float(entry["height_m"]) - float(TYPES[type])) > 0.01:
			failures.append("%s height_m %s want %s" % [type, entry["height_m"], TYPES[type]])
		if not LandmarkBuilder.is_bespoke(type):
			failures.append(type + " must have a bespoke builder")
			continue
		var model := Node3D.new()
		LandmarkSetFinlandHelsinki.build(model, type)
		var bounds := AABB()
		var first := true
		var tris := 0
		if model.get_child_count() < 3 or model.get_child_count() > 10:
			failures.append("%s must merge geometry by material, got %d parts" % [type, model.get_child_count()])
		for part in model.get_children():
			var mesh := (part as MeshInstance3D).mesh
			bounds = mesh.get_aabb() if first else bounds.merge(mesh.get_aabb())
			first = false
			var vertices: PackedVector3Array = mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
			tris += vertices.size() / 3
			for v in vertices:
				if not v.is_finite():
					failures.append(type + " has non-finite vertices")
					break
			var mat := mesh.surface_get_material(0) as StandardMaterial3D
			if mat == null or mat.albedo_texture == null:
				failures.append(type + " needs textured materials")
		if absf(bounds.end.y - float(TYPES[type])) > 0.5:
			failures.append("%s built height %.2f want %.1f" % [type, bounds.end.y, TYPES[type]])
		if bounds.position.y < -0.1:
			failures.append(type + " sinks below base")
		if tris < 1000 or tris > 150000:
			failures.append("%s triangle count %d outside budget" % [type, tris])
		var polys := LandmarkFhInnerFootprints.outlines(type)
		if polys.is_empty():
			failures.append(type + " has no outline")
		for poly in polys:
			_check_outline(failures, type, entry, poly)
		_check_spill(failures, type, polys, bounds)
		var lookup := LocationData.landmark_for(float(entry["lat"]), float(entry["lon"]), str(entry["name"]))
		if lookup != type:
			failures.append("%s name resolves to %s" % [type, lookup])
		print("INNER HELSINKI %s: %d tris, %.2f m, %d parts" % [type, tris, bounds.end.y, model.get_child_count()])
		model.free()
	_check_neighbours(failures)
	_check_extras(failures)
	_check_fabric(failures)
	if failures.is_empty():
		print("INNER HELSINKI COVERAGE OK: %d bespoke landmarks" % TYPES.size())
		quit(0)
	else:
		for f in failures:
			printerr("INNER HELSINKI FAIL: ", f)
		quit(1)

## Every point 6 m inside the outline lies within the entry's clearance.
func _check_outline(failures: Array[String], type: String, entry: Dictionary, poly: PackedVector2Array) -> void:
	if Geometry2D.triangulate_polygon(poly).is_empty():
		failures.append(type + " outline does not triangulate")
		return
	var inner := LandmarkFhMallFootprints.offset(poly, -6.0)
	var lo := Vector2(INF, INF)
	var hi := -lo
	for p in poly:
		lo = lo.min(p)
		hi = hi.max(p)
	var missed := 0
	var x := lo.x
	while x <= hi.x:
		var z := lo.y
		while z <= hi.y:
			var p := Vector2(x, z)
			if Geometry2D.is_point_in_polygon(p, inner) \
					and LandmarkSites.span_dist(p, Vector2.ZERO, entry) >= LandmarkSites.clear_m(entry):
				missed += 1
			z += 2.0
		x += 2.0
	if missed > 0:
		failures.append("%s: %d points inside the outline escape clearance" % [type, missed])

## The model stays within 6 m of its outlines' extent.
func _check_spill(failures: Array[String], type: String, polys: Array[PackedVector2Array], bounds: AABB) -> void:
	var lo := Vector2(INF, INF)
	var hi := -lo
	for poly in polys:
		for p in poly:
			lo = lo.min(p)
			hi = hi.max(p)
	if bounds.position.x < lo.x - 6.0 or bounds.end.x > hi.x + 6.0 \
			or bounds.position.z < lo.y - 6.0 or bounds.end.z > hi.y + 6.0:
		failures.append("%s model %s spills past its outline %s..%s" % [type, bounds, lo, hi])

## No landmark's clearance reaches another registry landmark's centre.
func _check_neighbours(failures: Array[String]) -> void:
	for type in TYPES:
		var a := LocationData.entry_for_type(type)
		for other in LocationData.landmarks():
			var b: Dictionary = other
			if str(b["type"]) == type:
				continue
			var d := LocationData.distance_m(float(a["lat"]), float(a["lon"]), float(b["lat"]), float(b["lon"]))
			if d > 400.0:
				continue
			var at := WorldScale.xz_from_latlon(float(b["lat"]), float(b["lon"]), float(a["lat"]), float(a["lon"]))
			if LandmarkSites.span_dist(at, Vector2.ZERO, a) < LandmarkSites.clear_m(a):
				failures.append("%s clearance swallows %s" % [type, b["type"]])

## A view of one landmark builds its area's neighbours too.
func _check_extras(failures: Array[String]) -> void:
	for row in [["enso_gutzeit_hq", ["uspenski_cathedral", "merikasarmi", "katajanokka_terminal"]],
			["kallio_library", ["kallio_church", "kallio_virastotalo", "linnanmaki", "hakaniemi_market_hall"]],
			["clarion_hotel", ["west_terminal_2", "cable_factory", "salmisaari_power_plant"]]]:
		var e := LocationData.entry_for_type(str(row[0]))
		var got := LocationData.registry_extras(float(e["lat"]), float(e["lon"]), str(row[0])).map(
			func(x: Dictionary) -> String: return str(x["type"]))
		for want in row[1]:
			if not got.has(want):
				failures.append("%s extras missing %s" % [row[0], want])

## Katajanokka's Jugend west and 1970s–80s east, Kallio's Jugend blocks,
## the 1920s classicism of Torkkelinmäki and the new-built harbour
## districts of Jätkäsaari, Ruoholahti and Sompasaari.
func _check_fabric(failures: Array[String]) -> void:
	for row in [[60.1680, 24.9640, "helsinki", "helsinki"], [60.1668, 24.9760, "helsinki", "helsinki_midrise"],
			[60.1830, 24.9490, "helsinki", "helsinki"], [60.1853, 24.9548, "helsinki", "helsinki_classicism"],
			[60.1560, 24.9130, "helsinki", "helsinki_midrise"], [60.1625, 24.9110, "helsinki", "helsinki_midrise"],
			[60.1830, 24.9870, "helsinki", "helsinki_midrise"]]:
		var region := CityStyles.region_at(row[0], row[1])
		if region != row[2]:
			failures.append("zone at %s, %s is %s want %s" % [row[0], row[1], region, row[2]])
			continue
		var frame := CityStyles.local_frame(region, row[0], row[1])
		var best := INF
		var district := ""
		for d in (frame["districts"] as Array):
			var dr: Array = d
			if float(dr[2]) < best and (dr[1] as Vector2).length() <= float(dr[2]):
				best = float(dr[2])
				district = str(dr[0])
		if district != row[3]:
			failures.append("district at %s, %s is %s want %s" % [row[0], row[1], district, row[3]])
