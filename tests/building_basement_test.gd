extends SceneTree

## BuildingBasement (offline): godot --headless --script tests/building_basement_test.gd
## A plinth a storey tall gets doors and windows on its downhill wall,
## all of them on the wall between the ground and the floor line; a low
## plinth or flat ground gets none, and a wall a neighbour covers none.

func _init() -> void:
	_run()

func _ground(slope_m_per_post: float) -> GroundTruth:
	var d := LocationData.new()
	d.grid_size = 64
	d.heights.resize(64 * 64)
	for z in 64:
		for x in 64:
			d.heights[z * 64 + x] = 20.0 + slope_m_per_post * float(x)
	d.water_level = -3.0
	return GroundTruth.new(d)

func _square(c: Vector2, r: float) -> PackedVector2Array:
	return PackedVector2Array([c + Vector2(-r, -r), c + Vector2(r, -r),
		c + Vector2(r, r), c + Vector2(-r, r)])

func _verts(root: Node3D) -> PackedVector3Array:
	var out := PackedVector3Array()
	for child in root.get_children():
		var mi := child as MeshInstance3D
		if mi == null or mi.mesh == null:
			continue
		for s in mi.mesh.get_surface_count():
			out.append_array(mi.mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX])
	return out

func _run() -> void:
	var failures: Array[String] = []
	var m := WorldScale.metres_to_units()
	var ring := _square(Vector2.ZERO, 12.0 * m)
	var flat := _ground(0.0)
	var root := Node3D.new()
	BuildingBasement.dress(root, ring, BuildingFoundation.sample(flat, ring, Vector2.ZERO), flat)
	if not _verts(root).is_empty():
		failures.append("flat ground got openings")
	# Steep: the walls reach ground level a good way below the floor line.
	var steep := _ground(9.0)
	var footing := BuildingFoundation.sample(steep, ring, Vector2.ZERO)
	var steep_root := Node3D.new()
	BuildingBasement.dress(steep_root, ring, footing, steep)
	var verts := _verts(steep_root)
	if float(footing["plinth"]) / m < 4.0:
		failures.append("test slope too gentle: plinth %.1f m" % [float(footing["plinth"]) / m])
	if verts.is_empty():
		failures.append("steep plinth got no openings")
	# Frames and panes make two meshes; a door leaf is a third. Whether a
	# wall gets doors is a roll of its position, so try several sites.
	var doors := 0
	for k in 8:
		var centre := Vector2(float(k) * 31.0, float(k % 3) * 17.0) * m
		var site := _square(centre, 12.0 * m)
		var site_root := Node3D.new()
		BuildingBasement.dress(site_root, site, BuildingFoundation.sample(steep, site, centre), steep)
		if site_root.get_child_count() >= 3:
			doors += 1
		site_root.free()
	if doors == 0:
		failures.append("no site's steep wall got a door")
	var top := float(footing["floor"]) - BuildingFoundation.SINK_M * m
	for v in verts:
		var g := steep.height_at_world(v.x, v.z)
		if v.y < g - 0.2 * m or v.y > top:
			failures.append("opening vertex off the wall: y %.2f, ground %.2f, top %.2f" % [v.y, g, top])
			break
		if absf(v.x) > 12.0 * m + 0.3 * m and absf(v.z) > 12.0 * m + 0.3 * m:
			failures.append("opening past the corner: %s" % [v])
			break
	# Only the downhill (west, low x) wall: the uphill wall is buried.
	var east := 0
	for v in verts:
		if v.x > 0.0 and absf(v.z) < 11.0 * m:
			east += 1
	if east > 0:
		failures.append("%d opening vertices on the uphill wall" % east)
	# A covered wall gets none.
	var covered := PackedByteArray([1, 1, 1, 1])
	var party_root := Node3D.new()
	BuildingBasement.dress(party_root, ring, footing, steep, covered)
	if not _verts(party_root).is_empty():
		failures.append("party walls got openings")
	# Low relief: a plinth under a window's height gets none.
	var gentle := _ground(0.4)
	var low := BuildingFoundation.sample(gentle, ring, Vector2.ZERO)
	var low_root := Node3D.new()
	BuildingBasement.dress(low_root, ring, low, gentle)
	if not _verts(low_root).is_empty():
		failures.append("low plinth got openings: %.1f m" % [float(low["plinth"]) / m])
	if failures.is_empty():
		print("building_basement_test passed")
		quit(0)
	else:
		for f in failures:
			printerr(f)
		quit(1)
