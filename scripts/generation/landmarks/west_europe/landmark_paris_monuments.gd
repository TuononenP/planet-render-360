class_name LandmarkParisMonuments
extends RefCounted

## The Arc de Triomphe and the Louvre Pyramid in true metres, y = 0 at
## street level. (Versailles is LandmarkVersailles.)

## Arc de Triomphe (50 m): Chalgrin's 45 x 22 m arch (1806-1836) with
## the 14.6 x 29.2 m main arch (passage along Z, on the Axe historique)
## and the 8.4 x 18.7 m transverse arches; the coffered vault, moulded
## archivolts and imposts; the four 11 m high-relief groups (Le Départ
## de 1792, Le Triomphe, La Résistance, La Paix) on their pedestals, the
## battle panels above them, the Victories in the spandrels, the great
## frieze, the dentilled cornice, the attic with its thirty shields, and
## the Unknown Soldier's tomb under the vault.
static func arc_de_triomphe(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#D6C5A2", 3.0))
	lm.use("Relief", LandmarkMaterials.pbr("limestone", "#BEA984", 3.0))
	lm.use("Steps", LandmarkMaterials.pbr("pavement", "#A8A294", 4.0))
	lm.use("Bronze", LandmarkMaterials.paint("#5A5446", 0.5, 0.6))
	lm.use("FlameLamp", LandmarkMaterials.lit("#FF9B38", 2.6))
	LandmarkWestKit.blk(lm, "Steps", 0, 0.0, 0, 52.0, 0.4, 30.0)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			LandmarkWestKit.blk(lm, "Stone", sx * 14.9, 0, sz * 7.61, 15.19, 14.46, 6.78)
			# Plinth course round each pier.
			LandmarkWestKit.blk(lm, "Stone", sx * 14.9, 0, sz * 7.61, 15.8, 2.2, 7.4)
		# Transverse arch (passage along X) over its pier pair.
		LandmarkWestKit.arch_wall(lm, "Stone", Basis(Vector3.UP, PI * 0.5), Vector3(sx * 14.9, 0, 0),
			11.0, 7.595, 4.22, 14.46, 21.88)
		LandmarkDetail.arch(lm, "Stone", Vector3(sx * 22.5, 14.46, 0), Vector3(sx, 0, 0), 8.44, 0.8, 0.35)
		LandmarkWestKit.blk(lm, "Stone", sx * 22.6, 13.8, 0, 0.5, 0.7, 10.4)
	# Main arch block, archivolts and imposts.
	LandmarkWestKit.arch_wall(lm, "Stone", Basis(), Vector3.ZERO, 22.5, 11.0, 7.31, 21.88, 43.0)
	for sz in [-1.0, 1.0]:
		var n := Vector3(0, 0, sz)
		LandmarkDetail.arch(lm, "Stone", Vector3(0, 21.88, sz * 11.0), n, 14.62, 1.2, 0.4)
		for sx in [-1.0, 1.0]:
			LandmarkWestKit.blk(lm, "Stone", sx * 8.4, 21.0, sz * 11.1, 2.2, 0.9, 0.5)
			# Victories (Fames with trumpets) in the spandrels.
			var v := Vector3(sx * 10.6, 31.0, sz * 11.25)
			lm.beam("Relief", v + Vector3(sx * 3.2, 1.2, 0), v - Vector3(sx * 2.0, 2.2, 0), 1.0, 0.5)
			lm.beam("Relief", v + Vector3(sx * 0.5, 0.4, 0), v + Vector3(sx * 2.5, 3.2, 0), 1.6, 0.3)
			lm.beam("Bronze", v + Vector3(-sx * 2.0, -1.6, 0.0), v + Vector3(-sx * 4.4, -3.0, 0), 0.25, 0.3)
	# Coffered vault of the main arch: rosettes in rows across the soffit.
	for i in 9:
		var t := PI * (float(i) + 0.5) / 9.0
		for k in 7:
			var z := -9.0 + 3.0 * float(k)
			var p := Vector3(cos(t) * 7.2, 21.88 + sin(t) * 7.2, z)
			lm.box("Relief", p, Vector3(1.6, 1.6, 1.6), Basis(Vector3(0, 0, 1), t - PI * 0.5) , 0.0)
	lm.box("Relief", Vector3(0, 0.5, 0), Vector3(2.0, 0.2, 3.0), Basis(), 0.0)
	lm.frustum("Bronze", Vector3(0, 0.6, -1.0), 0.25, 0.1, 0.5, 8)
	lm.frustum("FlameLamp", Vector3(0, 1.05, -1.0), 0.22, 0.06, 0.65, 8)
	# Entablature, frieze, cornice, attic with shields, crowning cornice.
	LandmarkWestKit.blk(lm, "Stone", 0, 38.8, 0, 45.4, 0.8, 22.4)
	for i in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * float(i))
		var hw := 22.5 if i % 2 == 0 else 11.0
		var hd := 11.0 if i % 2 == 0 else 22.5
		var n: Vector3 = b * Vector3(0, 0, 1)
		var r: Vector3 = b * Vector3(1, 0, 0)
		LandmarkDetail.cornice(lm, "Stone", n * hd - r * hw + Vector3(0, 41.6, 0), n * hd + r * hw + Vector3(0, 41.6, 0), n, 1.4)
		# The great frieze: a procession of figures in relief.
		var cnt := int(hw * 2.0 / 2.2)
		for k in cnt:
			var p: Vector3 = n * (hd + 0.25) + r * (-hw + 2.2 * (float(k) + 0.5)) + Vector3(0, 36.4, 0)
			LandmarkWestKit.figure(lm, "Relief", p, 2.2)
		lm.box("Stone", n * (hd + 0.15) + Vector3(0, 35.8, 0), Vector3(hw * 2.0 if i % 2 == 0 else 0.3, 0.5,
			0.3 if i % 2 == 0 else hw * 2.0), Basis(), 0.0)
	LandmarkWestKit.blk(lm, "Stone", 0, 43.0, 0, 46.4, 1.2, 23.4)
	LandmarkWestKit.blk(lm, "Stone", 0, 44.2, 0, 44.0, 4.8, 21.2)
	LandmarkWestKit.blk(lm, "Stone", 0, 49.0, 0, 46.0, 1.0, 22.8)
	for sz in [-1.0, 1.0]:
		for k in 8:
			var x := -19.25 + 5.5 * float(k)
			lm.disc("Relief", Vector3(x, 46.6, sz * 10.65), Vector3(0, 0, sz), 1.15, 12)
			lm.frustum("Relief", Vector3(x, 46.6, sz * 10.6), 1.3, 1.3, 0.01, 12)
			lm.box("Stone", Vector3(x + 2.75, 46.6, sz * 10.7), Vector3(0.8, 4.8, 0.3), Basis(), 0.0)
	for sx in [-1.0, 1.0]:
		for k in 3:
			lm.disc("Relief", Vector3(sx * 22.05, 46.6, -6.0 + 6.0 * float(k)), Vector3(sx, 0, 0), 1.15, 12)
	# The four sculpted groups on their pedestals, and the battle panels.
	for sz in [-1.0, 1.0]:
		for sx in [-1.0, 1.0]:
			var g := Vector3(sx * 14.9, 0, sz * 11.6)
			LandmarkWestKit.blk(lm, "Stone", g.x, 0, g.z, 10.0, 4.0, 2.4)
			LandmarkDetail.cornice(lm, "Stone", g + Vector3(-5.0, 3.6, 1.2 * sz), g + Vector3(5.0, 3.6, 1.2 * sz),
				Vector3(0, 0, sz), 0.6, false)
			var heights := [6.5, 7.2, 6.0, 5.6]
			for k in 4:
				LandmarkKits.statue_figure(lm, "Relief", g + Vector3(-3.6 + 2.4 * float(k), 4.0, sz * 0.2),
					float(heights[k]), k == 1)
			# The winged genius above each group.
			lm.beam("Relief", g + Vector3(-1.0, 13.0, sz * 0.4), g + Vector3(1.5, 11.0, sz * 0.4), 1.0, 0.8)
			lm.beam("Relief", g + Vector3(0.0, 12.4, sz * 0.4), g + Vector3(-2.8, 14.6, sz * 0.4), 2.2, 0.3)
			# Battle panel framed above the group.
			var pc := Vector3(sx * 14.9, 26.0, sz * 11.15)
			LandmarkWestKit.blk(lm, "Stone", pc.x, 23.2, pc.z, 11.0, 0.5, 0.5)
			LandmarkWestKit.blk(lm, "Stone", pc.x, 28.6, pc.z, 11.0, 0.5, 0.5)
			for k in 6:
				LandmarkWestKit.figure(lm, "Relief", Vector3(pc.x - 4.5 + 1.8 * float(k), 23.7, pc.z + sz * 0.1), 4.6)
	# Side panels (Aboukir, Jemappes) over the transverse arches.
	for sx in [-1.0, 1.0]:
		LandmarkWestKit.blk(lm, "Relief", sx * 22.7, 30.0, 0, 0.5, 6.0, 18.0)
		for k in 7:
			LandmarkWestKit.figure(lm, "Relief", Vector3(sx * 22.95, 30.2, -7.2 + 2.4 * float(k)), 5.0)
	lm.commit(model)
	model.set_meta(LandmarkLights.HALO_META, [[Vector3(0.0, 1.5, -1.0), 1.6, Color(1.0, 0.58, 0.16)]])
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-12.0, 1.5, 22.0), Vector3(-12.0, 26.0, 11.0), 62.0, 1.0, 70.0],
		[Vector3(12.0, 1.5, 22.0), Vector3(12.0, 26.0, 11.0), 62.0, 1.0, 70.0],
		[Vector3(-12.0, 1.5, -22.0), Vector3(-12.0, 26.0, -11.0), 62.0, 1.0, 70.0],
		[Vector3(12.0, 1.5, -22.0), Vector3(12.0, 26.0, -11.0), 62.0, 1.0, 70.0],
		[Vector3(0.0, 1.5, 3.0), Vector3(0.0, 28.0, 0.0), 72.0, 0.9, 42.0],
	])

## Louvre Pyramid (21.6 m): I. M. Pei's 35.4 m glass pyramid (1989) on
## the Louvre axis — 603 rhombic and 70 triangular panes on a diagonal
## steel lattice (18 courses a face) carried by a tensioned inner space
## truss, the entrance on the west face, the three 5 m pyramids on the
## north, east and south sides, and the triangular fountain basins
## round them in the Cour Napoléon.
static func louvre_pyramid(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Glass", LandmarkMaterials.clear_glass("#D2EAF2", 0.20))
	lm.use("Frame", LandmarkMaterials.paint("#DCE2E6", 0.24, 0.85))
	lm.use("Paving", LandmarkMaterials.pbr("pavement", "#C8BFA9", 4.0))
	lm.use("HallStone", LandmarkMaterials.marble("#DFD5BE", 0.40))
	lm.use("Water", LandmarkMaterials.pool_water("#2A6878", 0.05))
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#4F5256", 2.0, 0.28))
	lm.use("CoreLamp", LandmarkMaterials.night_lit("#FFCE80", 1.45, "#CFC4AC"))
	# Level Cour Napoléon terrace apron with 1.2 m foundation skirt so sloped DEM never buries or undercuts it
	LandmarkWestKit.blk(lm, "Paving", 0, -1.20, 0, 108.0, 1.28, 108.0)
	# Perimeter dark-granite curb around the Grand Pyramid opening into the sunlit Hall Napoléon atrium
	for s in [-1.0, 1.0]:
		var sf := float(s)
		LandmarkWestKit.blk(lm, "Granite", sf * 17.65, 0.0, 0.0, 1.15, 0.34, 36.4)
		LandmarkWestKit.blk(lm, "Granite", 0.0, 0.0, sf * 17.65, 34.2, 0.34, 1.15)
	LandmarkWestKit.blk(lm, "HallStone", 0.0, 0.05, 0.0, 34.2, 0.08, 34.2)
	# Sunken Hall Napoléon central oculus well, cylindrical glass lift & Pei's helical limestone staircase
	lm.lathe("HallStone", Vector3(0.0, 0.12, 0.0), PackedVector2Array([
		Vector2(5.2, 0.0), Vector2(5.2, 0.42), Vector2(4.5, 0.42), Vector2(4.5, 0.05),
	]), 36, 1.0, 1.0, 0.0, true, false)
	lm.lathe("CoreLamp", Vector3(0.0, 0.13, 0.0), PackedVector2Array([
		Vector2(4.45, 0.0), Vector2(4.45, 0.12), Vector2(3.6, 0.12), Vector2(3.6, 0.0),
	]), 32, 1.0, 1.0, 0.0, true, false)
	lm.frustum("Frame", Vector3(0.0, 0.12, 0.0), 1.05, 1.05, 3.15, 20)
	for st in 18:
		var a := TAU * 0.82 * float(st) / 17.0
		var r_mid := 2.65
		var sx := cos(a) * r_mid
		var sz := sin(a) * r_mid
		lm.box("HallStone", Vector3(sx, 0.22 + 0.15 * float(st), sz),
			Vector3(1.55, 0.14, 0.62), Basis(Vector3.UP, -a), 0.0)
	_pyramid(lm, Vector3(0, 0.32, 0), 17.71, 21.32, 18, true)
	# Three 5 m satellite pyramids: Pyramide Nord (-Z), Pyramide Est (+X), Pyramide Sud (+Z)
	for p in [Vector3(0, 0.32, -31.5), Vector3(31.5, 0.32, 0), Vector3(0, 0.32, 31.5)]:
		for s in [-1.0, 1.0]:
			var sf := float(s)
			LandmarkWestKit.blk(lm, "Granite", p.x + sf * 4.0, 0.0, p.z, 0.65, 0.34, 8.6)
			LandmarkWestKit.blk(lm, "Granite", p.x, 0.0, p.z + sf * 4.0, 7.4, 0.34, 0.65)
		LandmarkWestKit.blk(lm, "HallStone", p.x, 0.05, p.z, 7.4, 0.08, 7.4)
		_pyramid(lm, p, 3.9, 4.95, 5, false)
	# True I. M. Pei Cour Napoléon fountain complex (~5,120 m² of non-overlapping dark-granite
	# triangular reflecting basins framing the Grand Pyramid & three satellite pyramids, leaving
	# the West (-X) visitor entrance forecourt open).
	var fk := FountainKit.new()
	var basins := [
		# Two huge East-quadrant right-triangle fountain basins flanking Pyramide Est (+X)
		[PackedVector2Array([Vector2(19.2, -5.6), Vector2(48.5, -5.6), Vector2(19.2, -34.9)]), true],
		[PackedVector2Array([Vector2(19.2, 5.6), Vector2(19.2, 34.9), Vector2(48.5, 5.6)]), true],
		# Two large North-quadrant right-triangle fountain basins flanking Pyramide Nord (-Z)
		[PackedVector2Array([Vector2(5.6, -19.2), Vector2(34.9, -19.2), Vector2(5.6, -48.5)]), true],
		[PackedVector2Array([Vector2(-5.6, -19.2), Vector2(-5.6, -48.5), Vector2(-34.9, -19.2)]), false],
		# Two large South-quadrant right-triangle fountain basins flanking Pyramide Sud (+Z)
		[PackedVector2Array([Vector2(5.6, 19.2), Vector2(5.6, 48.5), Vector2(34.9, 19.2)]), true],
		[PackedVector2Array([Vector2(-5.6, 19.2), Vector2(-34.9, 19.2), Vector2(-5.6, 48.5)]), false],
		# Diagonal NE & SE mirror triangles filling the square courtyard between the walkways
		[PackedVector2Array([Vector2(21.2, -36.9), Vector2(48.5, -9.6), Vector2(48.5, -36.9)]), true],
		[PackedVector2Array([Vector2(21.2, 36.9), Vector2(48.5, 36.9), Vector2(48.5, 9.6)]), true],
	]
	var wat_y := 0.54
	for entry in basins:
		var poly: PackedVector2Array = entry[0]
		var tall_gerbes: bool = entry[1]
		# Granite basin plinth below water + raised 0.55 m wide polished granite coping kerb around perimeter
		lm.poly_prism("Granite", poly, 0.06, 0.44)
		for e_i in poly.size():
			var pa := poly[e_i]
			var pb := poly[(e_i + 1) % poly.size()]
			lm.beam("Granite", Vector3(pa.x, 0.52, pa.y), Vector3(pb.x, 0.52, pb.y), 0.55, 0.20, Vector3.UP)
		var cen := (poly[0] + poly[1] + poly[2]) / 3.0
		var inner := PackedVector2Array()
		for q in poly:
			inner.append(q + (cen - q).normalized() * 0.48)
		lm.poly_prism("Water", inner, 0.44, wat_y)
		# Volumetric rows of tall pressurized Cour Napoléon water columns (5.5 m - 9.2 m high!)
		if tall_gerbes:
			var p_main := poly[0].lerp(cen, 0.72)
			fk.jet_plume(Vector3(p_main.x, wat_y, p_main.y), 9.2, 0.22, 0.68)
			fk.splash_ring(Vector3(p_main.x, wat_y, p_main.y), 3.2, 0.92)
			fk.mist_emitter(Vector3(p_main.x, wat_y + 0.6, p_main.y), 3.4, 2.2, 3)
			for k in 7:
				var u := 0.12 + 0.125 * float(k)
				var row_a := poly[0].lerp(poly[1], u)
				var row_b := poly[0].lerp(poly[2], u)
				var pt := row_a.lerp(row_b, 0.5)
				var h_jet := lerpf(7.6, 4.8, absf(float(k) - 3.0) / 3.5)
				fk.jet_plume(Vector3(pt.x, wat_y, pt.y), h_jet, 0.16, 0.48)
				fk.splash_ring(Vector3(pt.x, wat_y, pt.y), 2.1, 0.84)
		else:
			# NW / SW basins flanking the entrance parvis: graceful stepped 4.8 - 6.8 m plumes
			for k in 6:
				var u := 0.15 + 0.14 * float(k)
				var pt := poly[1].lerp(poly[2], u).lerp(poly[0], 0.38)
				var h_jet := lerpf(6.8, 4.6, absf(float(k) - 2.5) / 3.0)
				fk.jet_plume(Vector3(pt.x, wat_y, pt.y), h_jet, 0.15, 0.45)
				fk.splash_ring(Vector3(pt.x, wat_y, pt.y), 1.9, 0.82)
			fk.mist_emitter(Vector3(cen.x, wat_y + 0.5, cen.y), 2.6, 1.8, 2)
	# Glazed entrance canopy on the west (-X) face.
	lm.box("Frame", Vector3(-18.6, 1.65, 0), Vector3(1.6, 0.25, 5.0))
	for sz in [-2.4, 2.4]:
		lm.box("Frame", Vector3(-19.2, 0.90, sz), Vector3(0.18, 1.6, 0.18), Basis(), 0.0)
	lm.box("Glass", Vector3(-17.9, 1.35, 0), Vector3(0.05, 2.5, 4.4), Basis(), 0.0)
	var parts := lm.commit(model)
	var glass_sh := LandmarkMaterials.clear_glass_shader("#D8EEF5", 0.14)
	for mi in parts:
		if mi.name == "Glass":
			mi.set_surface_override_material(0, glass_sh)
			# Let real sunlight pour through the clear glass so the steel lattice casts shadows inside!
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	fk.commit(model)

## Glass pyramid on `c`: glass skin with lattice-aligned rhombic pane UVs,
## the diagonal lattice of n courses a face (members parallel to the hip edges),
## hips and base frame; with `truss`, the inner space truss — a second lattice
## 1.2 m inside joined by a strut at every node.
static func _pyramid(lm: LandmarkMesh, c: Vector3, hw: float, h: float, n: int, truss: bool) -> void:
	var apex := c + Vector3(0, h, 0)
	var w := hw * 0.006 + 0.08
	var corners := [Vector3(-hw, 0, -hw), Vector3(hw, 0, -hw), Vector3(hw, 0, hw), Vector3(-hw, 0, hw)]
	var nf := float(n)
	for i in 4:
		var a: Vector3 = c + corners[i]
		var b: Vector3 = c + corners[(i + 1) % 4]
		var fo := ((a + b) * 0.5 - c).normalized()
		var fn := (fo * h + Vector3.UP * hw).normalized()
		lm.tri("Glass", a, b, apex, fn, fn, fn, Vector2(0.0, 0.0), Vector2(nf, 0.0), Vector2(0.0, nf))
		var out := fn * 0.05
		lm.beam("Frame", a, b, w * 3.0, w * 2.0)
		lm.beam("Frame", a, apex, w * 2.2)
		for k in range(1, n):
			var t := float(k) / float(n)
			var q0 := a.lerp(b, t)
			lm.beam("Frame", q0 + out, q0 + (apex - a) * (1.0 - t) + out, w, w * 0.8, fn.cross(apex - a))
			lm.beam("Frame", q0 + out, q0 + (apex - b) * t + out, w, w * 0.8, fn.cross(apex - b))
		if not truss:
			continue
		# Inner chords 1.2 m in, along the same diagonals, and node struts.
		var inn := -fn * 1.2
		for k in range(1, n, 2):
			var t := float(k) / float(n)
			var q0 := a.lerp(b, t)
			lm.beam("Frame", q0 + inn + Vector3(0, 1.0, 0), q0 + (apex - a) * (1.0 - t) * 0.92 + inn, w * 0.6)
			lm.beam("Frame", q0 + inn + Vector3(0, 1.0, 0), q0 + (apex - b) * t * 0.92 + inn, w * 0.6)
		for k in range(1, n):
			for j in range(1, n - k):
				var u := float(k) / float(n)
				var v := float(j) / float(n)
				# Node where the k-th rising and j-th falling members cross.
				var p := a + (b - a) * u + (apex - a) * v
				if (k + j) % 2 == 0:
					lm.beam("Frame", p + out, p + inn * 0.9, w * 0.5)
