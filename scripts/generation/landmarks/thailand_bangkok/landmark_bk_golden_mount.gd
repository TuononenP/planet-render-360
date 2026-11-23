class_name LandmarkBkGoldenMount
extends RefCounted

## Golden Mount / Phu Khao Thong, Wat Saket (ภูเขาทอง วัดสระเกศ) — Bangkok BK-2.5
## Site: OSM way 243936903 & way 88359228, centroid 13.753852, 100.506676 (`skyline_priority: 3`).
## Spec (Rama III collapsed chedi core encased in artificial craggy wooded mound under Rama IV-V):
##   - Artificial hill (~118 x 102 m base, rising to 56.0 m summit terrace): stepped craggy grey
##     limestone/brick retaining walls, lush overlapping dark/mid-green tropical forest canopy
##     blanketing the slopes, grotto shrines, and a whitewashed spiral staircase with red handrails.
##   - Rounded-corner sheer white masonry summit bastion & gallery vihara (`way:243936903`,
##     46.0..60.2 m): wide whitewashed rounded-rectangle citadel wall crowned by the red-and-gold
##     Thai gallery roof, pierced window arcades, and 4 golden corner mini-chedis.
##   - Crowning Phra Boromabanphot Golden Bell Chedi (60.2..77.0 m = 16.8 m tall): gleaming gold
##     mosaic bell chedi (`U.bell_chedi`) visible across all of Rattanakosin, floodlit bright gold
##     above the dark wooded hill at night.

const U = preload("res://scripts/generation/landmarks/mainland_se_asia/landmark_mse_util.gd")
const K = preload("res://scripts/generation/landmarks/mainland_se_asia/landmark_mse_kit.gd")

const HEIGHT_M := 77.0

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Rock", LandmarkMaterials.pbr("stone", "#6A685E", 4.0))
	lm.use("Moss", LandmarkMaterials.pbr("grass", "#2A4B22", 4.0, 0.90, 0.0))
	lm.use("Foliage", LandmarkMaterials.pbr("grass", "#2E5825", 3.2, 0.88, 0.0))
	lm.use("Canopy", LandmarkMaterials.pbr("grass", "#3D6A2E", 3.2, 0.86, 0.0))
	lm.use("Wall", LandmarkMaterials.pbr("render", "#F3F0E7", 3.0))
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#DDD6C8", 3.0))
	lm.use("Orange", LandmarkMaterials.pbr("terracotta", "#C94E22", 2.0))
	lm.use("Green", LandmarkMaterials.pbr("slate", "#2E7854", 2.0))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.use("Dark", LandmarkMaterials.paint("#241F1C", 0.9, 0.05))

	_hill_and_foliage(lm)
	_spiral_stair(lm)
	_summit_vihara_and_chedi(lm)
	lm.commit(model)

	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(0.0, 61.2, 13.5), Vector3(0.0, 69.5, 0.0), 46.0, 1.75, 28.0, Color(1.0, 0.84, 0.38)],
		[Vector3(0.0, 61.2, -13.5), Vector3(0.0, 69.5, 0.0), 46.0, 1.75, 28.0, Color(1.0, 0.84, 0.38)],
		[Vector3(13.5, 61.2, 0.0), Vector3(0.0, 69.5, 0.0), 46.0, 1.75, 28.0, Color(1.0, 0.84, 0.38)],
		[Vector3(-13.5, 61.2, 0.0), Vector3(0.0, 69.5, 0.0), 46.0, 1.75, 28.0, Color(1.0, 0.84, 0.38)],
		[Vector3(0.0, 49.0, 26.0), Vector3(0.0, 58.0, 0.0), 52.0, 0.85, 36.0, Color(1.0, 0.92, 0.76)],
		[Vector3(0.0, 49.0, -26.0), Vector3(0.0, 58.0, 0.0), 52.0, 0.85, 36.0, Color(1.0, 0.92, 0.76)],
	])

static func _hill_r(y: float, angle: float) -> Vector2:
	var t := clampf(y / 50.0, 0.0, 1.0)
	var rx := lerpf(57.5, 23.5, pow(t, 0.76))
	var rz := lerpf(49.5, 20.0, pow(t, 0.76))
	var crag := 1.0 + (1.0 - t * 0.65) * (0.08 * sin(angle * 5.0 + y * 0.13) + 0.06 * cos(angle * 8.0 - y * 0.09))
	return Vector2(cos(angle) * rx * crag, sin(angle) * rz * crag)

static func _hill_and_foliage(lm: LandmarkMesh) -> void:
	# Base masonry retaining ring so the hill foot meets city ground cleanly with zero seam
	lm.lathe("Stone", Vector3(0, -0.4, 0), PackedVector2Array([
		Vector2(59.0, 0.0), Vector2(58.5, 1.6), Vector2(56.8, 2.0)]), 28, 1.0, 0.86, 0.0, false)

	# Moss-draped artificial hill core + protruding craggy grey limestone outcrops
	var moss_rows: Array = []
	var nv := 11
	var nu := 29
	for j in nv:
		var y := 49.5 * float(j) / float(nv - 1)
		var row := PackedVector3Array()
		for i in nu:
			var a := TAU * float(i) / float(nu - 1)
			var p := _hill_r(y, a)
			row.append(Vector3(p.x, y, p.y))
		moss_rows.append(row)
	lm.grid("Moss", moss_rows, Vector3.ZERO, true)

	# Craggy limestone cliff buttresses & retaining wall segments peeking through the jungle
	var crag_mesh := LandmarkMesh.new()
	crag_mesh.use("Rock", LandmarkMaterials.pbr("stone", "#6A685E", 4.0))
	crag_mesh.lathe("Rock", Vector3.ZERO, PackedVector2Array([
		Vector2(5.2, 0.0), Vector2(5.6, 3.2), Vector2(4.5, 7.0), Vector2(2.4, 9.2), Vector2(0.0, 9.8)]),
		6, 1.0, 1.0, 0.0, false)
	for c in 18:
		var cy := 4.0 + 38.0 * fposmod(float(c) * 0.61803, 1.0)
		var ca := TAU * float(c) / 18.0 + 0.35
		var cp := _hill_r(cy, ca) * 0.94
		var sc := 0.85 + 0.55 * fposmod(sin(float(c) * 19.3) * 313.7, 1.0)
		lm.merge(crag_mesh, Transform3D(Basis(Vector3.UP, ca * 1.7).scaled(Vector3(sc * 1.2, sc, sc * 0.9)),
			Vector3(cp.x, maxf(0.2, cy - 3.5), cp.y)))

	# Two lush multi-lobed tropical banyan/rain-tree cluster archetypes merged into a continuous jungle canopy
	var dark_clump := _make_foliage_clump("Foliage")
	var lit_clump := _make_foliage_clump("Canopy")
	for band in 8:
		var y := 3.2 + 5.3 * float(band)
		var count := 26 - band * 2
		for k in count:
			var h1 := fposmod(sin(float(band * 29 + k * 47)) * 43758.5, 1.0)
			var h2 := fposmod(cos(float(band * 17 + k * 71)) * 23421.3, 1.0)
			var a := TAU * (float(k) + 0.42 * float(band) + (h1 - 0.5) * 0.45) / float(count)
			var stair_a := fposmod((y / 51.0) * TAU * 1.65, TAU)
			if absf(angle_difference(a, stair_a)) < 0.16:
				continue
			var hp := _hill_r(y, a) * lerpf(0.88, 1.01, h2)
			var sx := lerpf(1.05, 1.75, h1)
			var sy := lerpf(0.85, 1.35, h2)
			var clump := lit_clump if ((band + k) % 3 == 0) else dark_clump
			lm.merge(clump, Transform3D(Basis(Vector3.UP, h1 * TAU).scaled(Vector3(sx, sy, sx * 0.92)),
				Vector3(hp.x, maxf(0.1, y - 2.2), hp.y)))

static func _make_foliage_clump(mat_key: String) -> LandmarkMesh:
	var sub := LandmarkMesh.new()
	sub.use(mat_key, LandmarkMaterials.gold())
	var offsets := [
		[Vector3(0.0, 0.0, 0.0), 5.6, 5.8],
		[Vector3(3.1, -0.4, 1.6), 4.4, 4.8],
		[Vector3(-2.8, 0.3, -1.8), 4.6, 5.1],
		[Vector3(0.8, 1.4, -2.2), 3.8, 4.4],
	]
	for o in offsets:
		var p: Vector3 = o[0]
		var r: float = o[1]
		var h: float = o[2]
		sub.lathe(mat_key, p, PackedVector2Array([
			Vector2(r * 0.55, 0.0), Vector2(r, h * 0.35), Vector2(r * 0.92, h * 0.68),
			Vector2(r * 0.52, h * 0.90), Vector2(0.0, h)]), 7, 1.0, 1.0, 0.0, false)
	return sub

static func _spiral_stair(lm: LandmarkMesh) -> void:
	var steps := 46
	var prev := Vector3.ZERO
	for i in steps + 1:
		var t := float(i) / float(steps)
		var y := lerpf(1.8, 51.5, t)
		var a := t * TAU * 1.65
		var hp := _hill_r(y, a) * 1.05
		var cur := Vector3(hp.x, y, hp.y)
		if i > 0:
			var out := Vector3(cur.x, 0, cur.z).normalized()
			lm.beam("Stone", prev + Vector3(0, -0.75, 0), cur + Vector3(0, -0.75, 0), 2.2, 1.7, out)
			lm.beam("Wall", prev + out * 0.95 + Vector3(0, 0.45, 0), cur + out * 0.95 + Vector3(0, 0.45, 0), 0.35, 0.95, out)
			lm.beam("Orange", prev + out * 0.95 + Vector3(0, 1.0, 0), cur + out * 0.95 + Vector3(0, 1.0, 0), 0.22, 0.16, out)
		if i == 0 or i == 18 or i == 33:
			var sb := Basis(Vector3.UP, -a)
			lm.box("Wall", cur + Vector3(0, 1.6, 0), Vector3(3.4, 3.2, 3.4), sb)
			lm.spire("Orange", cur + Vector3(0, 3.2, 0), 2.2, 1.8, 0.0, 4)
		prev = cur

static func _rounded_rect(hx: float, hz: float, corner: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var centres := [
		Vector2(hx - corner, hz - corner),
		Vector2(-hx + corner, hz - corner),
		Vector2(-hx + corner, -hz + corner),
		Vector2(hx - corner, -hz + corner),
	]
	for q in 4:
		var c: Vector2 = centres[q]
		for s in 5:
			var a := PI * 0.5 * (float(q) + float(s) / 4.0)
			pts.append(c + Vector2(cos(a), sin(a)) * corner)
	return pts

static func _summit_vihara_and_chedi(lm: LandmarkMesh) -> void:
	# Broad rounded-corner sheer whitewashed masonry drum (`way:243936903`, y = 44.5..55.2 m)
	var drum_poly := _rounded_rect(21.5, 18.0, 7.5)
	lm.poly_prism("Wall", drum_poly, 44.5, 55.2)
	var gal_poly := _rounded_rect(19.0, 15.8, 5.2)
	lm.poly_prism("Wall", gal_poly, 55.2, 59.8)

	# Windows around the upper summit vihara gallery
	for sz in [-1.0, 1.0]:
		var sb := Basis(Vector3.UP, 0.0 if sz > 0.0 else PI)
		for k in 7:
			var x := -12.0 + 4.0 * float(k)
			K.thai_window(lm, "Wall", "Dark", "Gold", Vector3(x, 56.1, float(sz) * 15.85), sb, 1.45, 2.3)
	for sx in [-1.0, 1.0]:
		var eb := Basis(Vector3.UP, PI * 0.5 * float(sx))
		for k in 5:
			var z := -8.8 + 4.4 * float(k)
			K.thai_window(lm, "Wall", "Dark", "Gold", Vector3(float(sx) * 19.05, 56.1, z), eb, 1.45, 2.3)

	# Overhanging orange-and-gold Thai gallery roof skirt & upper marble terrace at y = 60.2 m
	var eave_poly := _rounded_rect(20.6, 17.4, 5.6)
	lm.poly_prism("Orange", eave_poly, 59.1, 59.75)
	lm.poly_prism("Gold", _rounded_rect(20.8, 17.6, 5.7), 58.92, 59.12)
	lm.poly_prism("Green", _rounded_rect(19.6, 16.4, 5.2), 59.75, 60.0)
	lm.poly_prism("Stone", _rounded_rect(18.4, 15.2, 4.8), 60.0, 60.25)
	U.crenel_ring(lm, "Wall", Vector3(0, 60.25, 0), 16.6, 13.6, 0.85, 0.45, 2.0)

	# Four golden corner mini-chedis on the summit terrace
	for sx in [-13.6, 13.6]:
		for sz in [-10.6, 10.6]:
			K.small_chedi(lm, "Gold", "Gold", Vector3(sx, 60.25, sz), 1.35, 5.6)

	# Central gleaming Golden Bell Chedi (Phra Boromabanphot): y = 60.25 m + 16.75 m = 77.0 m!
	U.bell_chedi(lm, "Gold", "Gold", "Gold", Vector3(0, 60.25, 0), 5.8, HEIGHT_M - 60.25)
