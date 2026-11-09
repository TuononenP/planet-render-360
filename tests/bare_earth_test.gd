extends SceneTree

## BareEarth + ShoreApron (offline): godot --headless --script tests/bare_earth_test.gd
## North of 60°N the DEM is a surface model, so a city block read as a
## 20–30 m hill: BareEarth must flatten a mapped block and a tree-sized
## bump beside it onto the ground around them, keep a wide natural hill,
## and never raise a post. Shore aprons must not stretch a quad across a
## skipped stretch (Helsinki's long tan flaps) and must face up (back
## faces lit near-black).

const SIZE := 96
const STEP := 2400.0 / float(SIZE - 1)

func _init() -> void:
	_run()

func _post(x: int, z: int) -> Vector2:
	return Vector2((float(x) - SIZE / 2.0) * STEP, (float(z) - SIZE / 2.0) * STEP)

func _square(c: Vector2, r: float) -> PackedVector2Array:
	return PackedVector2Array([c + Vector2(-r, -r), c + Vector2(r, -r),
		c + Vector2(r, r), c + Vector2(-r, r)])

func _run() -> void:
	var failures: Array[String] = []
	var half := float(SIZE) / 2.0
	# Ramp rising 0.2 m per post east; a 25 m block (footprint ~4 posts
	# across) at (30, 30); a 12 m single-post tree crown two posts east
	# of it; a wide 15 m hill (~80 m radius) at (70, 60), no buildings.
	var ramp := PackedFloat32Array()
	ramp.resize(SIZE * SIZE)
	for z in SIZE:
		for x in SIZE:
			ramp[z * SIZE + x] = 20.0 + 0.2 * float(x)
	var src := ramp.duplicate()
	for z in range(28, 33):
		for x in range(28, 33):
			src[z * SIZE + x] += 25.0
	src[30 * SIZE + 35] += 12.0
	for z in SIZE:
		for x in SIZE:
			var d := Vector2(float(x - 70), float(z - 60)).length() * STEP
			src[z * SIZE + x] += 15.0 * maxf(0.0, 1.0 - d / 80.0)
	var hill := src[60 * SIZE + 70] - ramp[60 * SIZE + 70]
	var buildings: Array = [{"x": _post(30, 30).x, "z": _post(30, 30).y,
		"footprint": _square(_post(30, 30), STEP * 1.6)}]
	# A canopy bump inside mapped forest far from buildings is removed,
	# while the same bump outside that polygon remains untouched.
	var forest_src := ramp.duplicate()
	forest_src[20 * SIZE + 70] += 12.0
	forest_src[20 * SIZE + 10] += 12.0
	var forest_out := forest_src.duplicate()
	BareEarth.strip(forest_out, SIZE, STEP, half, [], [{"class": "forest",
		"points": _square(_post(70, 20), STEP * 4.0)}])
	if forest_out[20 * SIZE + 70] > ramp[20 * SIZE + 70] + 1.0:
		failures.append("mapped forest canopy away from buildings remains")
	if forest_out[20 * SIZE + 10] != forest_src[20 * SIZE + 10]:
		failures.append("unmapped natural relief must remain")
	var out := src.duplicate()
	var t0 := Time.get_ticks_msec()
	BareEarth.strip(out, SIZE, STEP, half, buildings)
	var ms := Time.get_ticks_msec() - t0
	var block := out[30 * SIZE + 30] - ramp[30 * SIZE + 30]
	if absf(block) > 1.0:
		failures.append("block left %.2f m above the ramp" % block)
	var tree := out[30 * SIZE + 35] - ramp[30 * SIZE + 35]
	if absf(tree) > 1.0:
		failures.append("tree crown left %.2f m above the ramp" % tree)
	var hill_after := out[60 * SIZE + 70] - ramp[60 * SIZE + 70]
	if absf(hill_after - hill) > 0.01:
		failures.append("wide hill changed %.2f → %.2f m" % [hill, hill_after])
	var raised := 0
	for i in out.size():
		if out[i] > src[i] + 1e-4:
			raised += 1
	if raised > 0:
		failures.append("%d posts raised" % raised)
	# An unmapped steep-sided roof near a mapped building goes; a smooth
	# 14 m cone just as near stays (its slope is 1–2 m per post).
	var fine := 9.41
	var near_b := Vector2((30.0 - half) * fine, (30.0 - half) * fine)
	var roof_buildings: Array = [{"x": near_b.x, "z": near_b.y, "footprint": _square(near_b, fine * 1.6)}]
	var roofs := ramp.duplicate()
	for z in range(38, 44):
		for x in range(44, 50):
			roofs[z * SIZE + x] += 15.0
	var cone_c := Vector2(40.0, 52.0)
	for z in SIZE:
		for x in SIZE:
			var cd := (Vector2(float(x), float(z)) - cone_c).length() * fine
			roofs[z * SIZE + x] += 14.0 * maxf(0.0, 1.0 - cd / 94.0)
	var cone_peak := roofs[52 * SIZE + 40] - ramp[52 * SIZE + 40]
	var roofs_out := roofs.duplicate()
	BareEarth.strip(roofs_out, SIZE, fine, half, roof_buildings)
	var roof_left := roofs_out[40 * SIZE + 46] - ramp[40 * SIZE + 46]
	if roof_left > 1.5:
		failures.append("unmapped roof left %.2f m above the ramp" % roof_left)
	var cone_left := roofs_out[52 * SIZE + 40] - ramp[52 * SIZE + 40]
	if absf(cone_left - cone_peak) > 0.5:
		failures.append("smooth cone near buildings changed %.2f → %.2f m" % [cone_peak, cone_left])
	var far_roof := roofs.duplicate()
	BareEarth.strip(far_roof, SIZE, fine, half, [{"x": (90.0 - half) * fine, "z": (90.0 - half) * fine,
		"footprint": _square(Vector2((90.0 - half) * fine, (90.0 - half) * fine), fine * 1.6)}])
	if absf(far_roof[40 * SIZE + 46] - roofs[40 * SIZE + 46]) > 0.01:
		failures.append("a bump with no mapped building near was filtered")
	# Full-size cost: a 256 grid with a dense block pattern.
	var big := 256
	var bstep := 2400.0 / float(big - 1)
	var bsurf := PackedFloat32Array()
	bsurf.resize(big * big)
	var bb: Array = []
	for z in big:
		for x in big:
			bsurf[z * big + x] = 20.0 + (25.0 if (x % 12 > 3 and z % 12 > 3) else 0.0)
	for z in range(8, big, 12):
		for x in range(8, big, 12):
			var c := Vector2((float(x) - big / 2.0) * bstep, (float(z) - big / 2.0) * bstep)
			bb.append({"x": c.x, "z": c.y, "footprint": _square(c, bstep * 3.5)})
	var t1 := Time.get_ticks_msec()
	BareEarth.strip(bsurf, big, bstep, float(big) / 2.0, bb)
	var big_ms := Time.get_ticks_msec() - t1
	var worst := 0.0
	for h in bsurf:
		worst = maxf(worst, h - 20.0)
	if worst > 1.0:
		failures.append("dense 256 grid kept a %.2f m block" % worst)
	# lower_canopy: a district of 10 m blocks, 25 % covered, 20 m tall, sits
	# 5 m of mean height on the posts: the surface drops CANOPY_K of that
	# inside the district, and stays put where there are no buildings.
	var csize := 80
	var cstep := 10.0
	var chalf := float(csize) / 2.0
	var canopy := PackedFloat32Array()
	canopy.resize(csize * csize)
	canopy.fill(100.0)
	var blocks: Array = []
	for bz in range(24, 56, 2):
		for bx in range(24, 56, 2):
			var at := Vector2(float(bx) - chalf, float(bz) - chalf) * cstep
			blocks.append({"x": at.x, "z": at.y, "height": 20.0, "footprint": _square(at, 5.0)})
	BareEarth.lower_canopy(canopy, csize, cstep, chalf, blocks)
	var inside := 100.0 - canopy[40 * csize + 40]
	if absf(inside - BareEarth.CANOPY_K * 5.0) > 0.4:
		failures.append("canopy lowered the district by %.2f m, expected %.2f" % [inside, BareEarth.CANOPY_K * 5.0])
	if canopy[2 * csize + 2] != 100.0:
		failures.append("canopy lowered an empty corner to %.2f" % canopy[2 * csize + 2])
	var capped := PackedFloat32Array()
	capped.resize(csize * csize)
	capped.fill(100.0)
	var towers: Array = []
	for bz in range(0, csize):
		for bx in range(0, csize):
			towers.append({"x": (float(bx) - chalf) * cstep, "z": (float(bz) - chalf) * cstep,
				"height": 300.0, "footprint": _square(Vector2((float(bx) - chalf) * cstep, (float(bz) - chalf) * cstep), 5.0)})
	BareEarth.lower_canopy(capped, csize, cstep, chalf, towers)
	if absf((100.0 - capped[40 * csize + 40]) - BareEarth.CANOPY_MAX_M) > 0.01:
		failures.append("canopy ignored its cap: %.2f m" % (100.0 - capped[40 * csize + 40]))
	# applies(): real geo data on a surface-model DEM (ArcticDEM and the
	# SRTM / EU-DEM class tiles), not the US lidar tiles.
	var d := LocationData.new()
	d.dem_source = {"source_zoom": DemFetcher.ZOOM_NEAR}
	d.latitude = 60.1699
	if not BareEarth.applies(d):
		failures.append("applies() false at Helsinki")
	d.latitude = 48.8566
	d.longitude = 2.3522
	if not BareEarth.applies(d):
		failures.append("applies() false at Paris")
	d.latitude = 40.7128
	d.longitude = -74.006
	if BareEarth.applies(d):
		failures.append("applies() true on the New York lidar tiles")
	_check_aprons(failures)
	print("BareEarth: %d ms (96 grid), %d ms (256 dense)" % [ms, big_ms])
	if failures.is_empty():
		print("BARE EARTH PASS")
		quit(0)
	else:
		for f in failures:
			printerr("BARE EARTH FAIL: ", f)
		quit(1)

## A lake ring half past `bound`: stations past it are skipped, and no
## quad may bridge the gap or close the ring across it; every triangle
## faces up (an island hole winds the other way round).
func _check_aprons(failures: Array[String]) -> void:
	var d := LocationData.new()
	d.grid_size = 64
	d.heights.resize(64 * 64)
	d.heights.fill(10.0)
	d.water_level = 0.0
	var ground := GroundTruth.new(d)
	var width := 20.0
	var stride := 12.0
	var bound := 300.0
	var ring := PackedVector2Array()
	for i in 64:
		var a := TAU * float(i) / 64.0
		ring.append(Vector2(250.0 + cos(a) * 200.0, sin(a) * 200.0))
	for water_inside in [true, false]:
		var verts: Array = []
		var normals: Array = []
		var colors: Array = []
		var uvs: Array = []
		var indices: Array = []
		var r := ring if water_inside else ring.duplicate()
		if not water_inside:
			r.reverse()
		ShoreApron._apron_ring(verts, normals, colors, uvs, indices, r,
			water_inside, ground, width, stride, bound)
		if indices.is_empty():
			failures.append("apron ring built no triangles")
			continue
		var longest := 0.0
		var down := 0
		for t in range(0, indices.size(), 3):
			var va: Vector3 = verts[indices[t]]
			var vb: Vector3 = verts[indices[t + 1]]
			var vc: Vector3 = verts[indices[t + 2]]
			longest = maxf(longest, maxf(va.distance_to(vb),
				maxf(vb.distance_to(vc), vc.distance_to(va))))
			if (vc - va).cross(vb - va).y < 0.0:
				down += 1
		if longest > stride * 3.0:
			failures.append("apron quad spans %.0f m (stride %.0f)" % [longest, stride])
		if down > 0:
			failures.append("%d apron triangles face down" % down)
