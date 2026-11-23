class_name LandmarkBkGiantSwing
extends RefCounted

## Giant Swing (Sao Chingcha / เสาชิงช้า) — Bangkok BK-2.1
## Site: OSM way 178353988 (`man_made=ceremonial_gate`), centroid 13.751811, 100.501275,
## traffic island on Bamrung Mueang Rd between Lan Khon Mueang and Wat Suthat.
## Spec (BMA / Fine Arts Dept 2007 Golden Teak reconstruction, Commons refs):
##   - Total height: 21.15 m above street level.
##   - Base: two-tier whitewashed stone/marble stepped octagonal-ended plinth
##     (~10.6 x 6.4 m, 1.55 m high) with axial stairs on E/W faces and low stone posts.
##   - Frame: two main round golden-teak pillars leaning slightly inward (~10.4 m span
##     at plinth tapering to ~8.2 m at top), flanked on N and S by two shorter raking
##     buttress posts per side (6 red teak poles total), painted vermilion (#C8261E)
##     with white/stone collars at their sockets.
##   - Crown: triple horizontal carved crossbeams with gilded lotus mouldings and an
##     openwork carved pediment (Vishnu/Naga motif) with gilded edge & upturned horns;
##     no swing seat (ceremony abolished 1935).
##   - Night: four warm-white ground floodlights washing the vermilion frame.

const K = preload("res://scripts/generation/landmarks/mainland_se_asia/landmark_mse_kit.gd")
const U = preload("res://scripts/generation/landmarks/mainland_se_asia/landmark_mse_util.gd")

const HEIGHT_M := 21.15

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Red", LandmarkMaterials.pbr("concrete", "#C8261E", 2.0, 0.42, 0.05))
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#ECE8DE", 2.5))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.use("Dark", LandmarkMaterials.paint("#2A2220", 0.85, 0.1))

	# Frame spans N-S along local X (so with yaw_deg matching the island, traffic passes E-W along Z)
	_plinth(lm)
	_pillars(lm)
	_crosshead(lm)
	lm.commit(model)

	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(0.0, 0.8, 7.5), Vector3(0.0, 13.5, 0.0), 48.0, 1.15, 34.0, Color(1.0, 0.92, 0.80)],
		[Vector3(0.0, 0.8, -7.5), Vector3(0.0, 13.5, 0.0), 48.0, 1.15, 34.0, Color(1.0, 0.92, 0.80)],
		[Vector3(7.5, 0.8, 0.0), Vector3(0.0, 15.0, 0.0), 42.0, 0.90, 32.0, Color(1.0, 0.90, 0.76)],
		[Vector3(-7.5, 0.8, 0.0), Vector3(0.0, 15.0, 0.0), 42.0, 0.90, 32.0, Color(1.0, 0.90, 0.76)],
	])

static func _plinth(lm: LandmarkMesh) -> void:
	# Rounded/chamfered two-step white marble terrace (10.8 x 5.8 m) + perimeter bollards
	var p0 := PackedVector2Array([
		Vector2(-5.4, -1.7), Vector2(-4.1, -2.9), Vector2(4.1, -2.9), Vector2(5.4, -1.7),
		Vector2(5.4, 1.7), Vector2(4.1, 2.9), Vector2(-4.1, 2.9), Vector2(-5.4, 1.7)])
	var p1 := PackedVector2Array([
		Vector2(-4.8, -1.3), Vector2(-3.7, -2.3), Vector2(3.7, -2.3), Vector2(4.8, -1.3),
		Vector2(4.8, 1.3), Vector2(3.7, 2.3), Vector2(-3.7, 2.3), Vector2(-4.8, 1.3)])
	lm.poly_prism("Stone", p0, 0.0, 0.72)
	lm.poly_prism("Stone", p1, 0.72, 1.45)
	# Moulded coping rim
	lm.box("Stone", Vector3(0, 1.50, 0), Vector3(7.6, 0.12, 4.7))
	for sz in [-1.0, 1.0]:
		var sb := Basis(Vector3.UP, 0.0 if sz > 0.0 else PI)
		U.stairs(lm, "Stone", Vector3(0, 1.45, sz * 2.3), sb, 2.6, 5, 0.28, 0.29)
	# Twin pedestal sockets under the two pillar groups
	for sx in [-1.0, 1.0]:
		lm.frustum("Stone", Vector3(sx * 4.35, 1.45, 0), 0.78, 0.64, 0.65, 8)
		for sz in [-1.0, 1.0]:
			lm.frustum("Stone", Vector3(sx * 4.45, 1.45, sz * 1.48), 0.44, 0.36, 0.50, 8)

static func _pillars(lm: LandmarkMesh) -> void:
	# Main inward-leaning round teak columns (entasis tapered via stacked segments)
	var y_base := 2.05
	var y_top := 18.85
	for sx in [-1.0, 1.0]:
		var foot := Vector3(sx * 4.35, y_base, 0.0)
		var head := Vector3(sx * 3.58, y_top, 0.0)
		var segs := 6
		for i in segs:
			var t0 := float(i) / float(segs)
			var t1 := float(i + 1) / float(segs)
			var a := foot.lerp(head, t0)
			var b := foot.lerp(head, t1)
			var r := lerpf(0.54, 0.38, (t0 + t1) * 0.5) * (1.0 + 0.04 * sin(PI * (t0 + t1) * 0.5))
			_round_strut(lm, "Red", a, b, r)
		# Gilded collars at mid-tie and capital
		lm.frustum("Gold", foot.lerp(head, 0.84), 0.44, 0.44, 0.26, 10)
		lm.frustum("Gold", head + Vector3(0, -0.22, 0), 0.43, 0.48, 0.28, 10)
		# Two raking buttress struts per main column (bracing along Z)
		for sz in [-1.0, 1.0]:
			var s_foot := Vector3(sx * 4.45, 1.90, sz * 1.48)
			var s_head := foot.lerp(head, 0.78) + Vector3(0, 0, sz * 0.14)
			_round_strut(lm, "Red", s_foot, s_head, 0.25)
			lm.box("Gold", s_head, Vector3(0.52, 0.24, 0.52))
			# Horizontal tie bars between main column and raking strut
			for tf in [0.32, 0.58]:
				lm.beam("Red", foot.lerp(head, tf), s_foot.lerp(s_head, tf), 0.14, 0.14, Vector3.RIGHT)

static func _round_strut(lm: LandmarkMesh, key: String, a: Vector3, b: Vector3, r: float) -> void:
	var dir := (b - a).normalized()
	var ref := Vector3.FORWARD if absf(dir.dot(Vector3.UP)) > 0.95 else Vector3.UP
	var bx := ref.cross(dir).normalized()
	var bz := dir.cross(bx).normalized()
	var basis := Basis(bx, dir, bz)
	var sub := LandmarkMesh.new()
	sub.use(key, LandmarkMaterials.gold()) # re-pointed on merge
	sub.frustum(key, Vector3.ZERO, r * 1.04, r * 0.96, a.distance_to(b), 10)
	lm.merge(sub, Transform3D(basis, a))

static func _crosshead(lm: LandmarkMesh) -> void:
	# Lower carved tie beam (swing hanger bar), middle lintel, and arched carved crown pediment to 21.15 m
	lm.beam("Red", Vector3(-3.75, 17.55, 0), Vector3(3.75, 17.55, 0), 0.36, 0.44, Vector3.FORWARD, true)
	for sx in [-1.4, 1.4]:
		lm.box("Gold", Vector3(sx, 17.32, 0), Vector3(0.26, 0.28, 0.48))
		lm.box("Dark", Vector3(sx, 17.12, 0), Vector3(0.14, 0.20, 0.14), Basis(), 0.0)
	lm.beam("Red", Vector3(-4.05, 18.85, 0), Vector3(4.05, 18.85, 0), 0.44, 0.52, Vector3.FORWARD, true)
	lm.beam("Gold", Vector3(-4.12, 19.14, 0), Vector3(4.12, 19.14, 0), 0.48, 0.14, Vector3.FORWARD, true)
	# Vertical carved balusters between lower tie and upper crossbeam
	for x in [-2.6, -1.3, 0.0, 1.3, 2.6]:
		lm.beam("Red", Vector3(x, 17.75, 0), Vector3(x, 18.70, 0), 0.20, 0.22, Vector3.FORWARD)
		lm.box("Gold", Vector3(x, 18.22, 0), Vector3(0.28, 0.22, 0.28))
	# Carved openwork red-and-gold arched pediment (krachang) rising from 19.18 m to 21.15 m
	var ped := PackedVector2Array([
		Vector2(-3.95, 0.0), Vector2(3.95, 0.0), Vector2(3.60, 0.42),
		Vector2(2.45, 0.98), Vector2(1.15, 1.52), Vector2(0.0, 1.97),
		Vector2(-1.15, 1.52), Vector2(-2.45, 0.98), Vector2(-3.60, 0.42)])
	K.outline_prism(lm, "Red", Vector3(0, 19.18, 0), Basis(), ped, 0.34)
	var ped_trim := PackedVector2Array([
		Vector2(-4.02, 0.0), Vector2(4.02, 0.0), Vector2(3.65, 0.46),
		Vector2(2.50, 1.02), Vector2(1.18, 1.56), Vector2(0.0, 1.97),
		Vector2(-1.18, 1.56), Vector2(-2.50, 1.02), Vector2(-3.65, 0.46)])
	K.outline_prism(lm, "Gold", Vector3(0, 19.18, 0), Basis(), ped_trim, 0.22)
	# Upturned Naga-horn finials at both ends of the upper crossbeam
	for sx in [-1.0, 1.0]:
		var e0 := Vector3(sx * 3.95, 18.92, 0)
		var e1 := Vector3(sx * 4.55, 19.55, 0)
		var e2 := Vector3(sx * 4.82, 20.35, 0)
		lm.beam("Red", e0, e1, 0.30, 0.26, Vector3.FORWARD)
		lm.beam("Gold", e1, e2, 0.18, 0.16, Vector3.FORWARD)
	# Central gilded medallion on both N and S faces
	for sz in [-1.0, 1.0]:
		lm.disc("Gold", Vector3(0, 19.88, sz * 0.19), Vector3(0, 0, sz), 0.52, 12)
