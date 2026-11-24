class_name VnBridges
extends RefCounted

## Bespoke Grand Canal bridges (`VN-7.1`–`VN-7.3`) built along +X, water at y = 0:
## - Ponte dell'Accademia (Miozzi 1933, 48 m arched oak timber & steel tie footbridge)
## - Ponte degli Scalzi (Miozzi 1934, 40 m flattened white Istrian-stone single arch)
## - Ponte della Costituzione / Calatrava (2008, 81 m red-oxide steel & illuminated glass arch)

## Ponte dell'Accademia: 56 m total span, arch crown deck at y = 5.8 m and
## handrail top at y = 7.6 m (keeps the preset camera at eye_m = 8.0 unobstructed!).
static func ponte_accademia(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Timber", LandmarkVnKit.dark_wood("#5A3E2B", 2.0))
	lm.use("Deck", LandmarkMaterials.pbr("wood", "#7A5B42", 2.0))
	lm.use("Steel", LandmarkMaterials.pbr("concrete", "#34393E", 2.0, 0.45, 0.72))
	lm.use("Stone", LandmarkVnKit.istrian("#DCD5C6", 2.4))
	lm.use("Lamp", LandmarkVnKit.warm_lamp("#FFE0A0", 2.0))

	var hw := 4.0
	var half_span := 24.0
	var segs := 20
	# Massive bank abutments in Istrian stone extending slightly into the water
	for sx in [-1.0, 1.0]:
		lm.box("Stone", Vector3(sx * 25.5, 1.4, 0.0), Vector3(5.6, 4.2, hw * 2.15))
		lm.box("Stone", Vector3(sx * 26.8, 0.2, 0.0), Vector3(4.0, 1.8, hw * 2.25))

	# Sweeping arched timber ribs + stepped timber deck + dark iron tie rods & balustrades
	var prev_x := -half_span
	var prev_arch := _acc_arch(prev_x)
	var prev_deck := _acc_deck(prev_x)
	for i in range(1, segs + 1):
		var x := lerpf(-half_span, half_span, float(i) / float(segs))
		var ay := _acc_arch(x)
		var dy := _acc_deck(x)
		var xm := (prev_x + x) * 0.5
		var dym := (prev_deck + dy) * 0.5
		# Four parallel curved laminated-oak structural arch ribs
		for rz in [-hw + 0.35, -hw * 0.35, hw * 0.35, hw - 0.35]:
			lm.beam("Timber", Vector3(prev_x, prev_arch, rz), Vector3(x, ay, rz), 0.42, 0.95)
		# Lower dark-steel tension plates along outer faces
		for rz in [-hw + 0.12, hw - 0.12]:
			lm.beam("Steel", Vector3(prev_x, prev_arch - 0.35, rz), Vector3(x, ay - 0.35, rz), 0.16, 0.28)
		# Stepped wooden footway deck
		lm.beam("Deck", Vector3(prev_x, prev_deck, 0.0), Vector3(x, dy, 0.0), hw * 1.92, 0.36)
		# Vertical timber/steel spandrel struts between arch & deck
		if i < segs and i % 2 == 0:
			var sh := dy - ay
			if sh > 0.25:
				for rz in [-hw + 0.35, hw - 0.35]:
					lm.box("Steel", Vector3(x, ay + sh * 0.5, rz), Vector3(0.20, sh, 0.22))
		# Dark-iron vertical railing posts + warm timber top rail on both sides
		for rz in [-hw + 0.14, hw - 0.14]:
			lm.beam("Timber", Vector3(prev_x, prev_deck + 1.25, rz), Vector3(x, dy + 1.25, rz), 0.18, 0.14)
			lm.beam("Steel", Vector3(prev_x, prev_deck + 0.65, rz), Vector3(x, dy + 0.65, rz), 0.10, 0.10)
			lm.box("Steel", Vector3(xm, dym + 0.62, rz), Vector3(0.08, 1.22, 0.08))
		prev_x = x
		prev_arch = ay
		prev_deck = dy

	# Warm bridge lanterns mounted on the outer steel piers
	for lx in [-16.0, -6.0, 6.0, 16.0]:
		var ly := _acc_deck(float(lx)) + 1.55
		for rz in [-hw + 0.12, hw - 0.12]:
			lm.box("Steel", Vector3(float(lx), ly - 0.15, rz), Vector3(0.14, 0.6, 0.14))
			lm.box("Lamp", Vector3(float(lx), ly + 0.22, rz), Vector3(0.26, 0.34, 0.26))

	lm.commit(model)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(0.0, 1.2, 9.0), Vector3(0.0, 4.4, hw), 62.0, 0.75],
		[Vector3(0.0, 1.2, -9.0), Vector3(0.0, 4.4, -hw), 62.0, 0.75],
	])

static func _acc_arch(x: float) -> float:
	var u := x / 24.0
	return 5.15 - 4.35 * u * u

static func _acc_deck(x: float) -> float:
	var u := x / 24.0
	return 5.85 - 3.65 * u * u

## Ponte degli Scalzi: 52 m overall, 40 m single flattened white Istrian-stone arch.
static func ponte_scalzi(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkVnKit.istrian("#ECE7DA", 2.6))
	lm.use("Trim", LandmarkVnKit.istrian_trim("#F7F4EC", 2.0))
	lm.use("Paving", LandmarkMaterials.pbr("pavement", "#C9C2B4", 2.0))
	lm.use("Lamp", LandmarkVnKit.warm_lamp("#FFE2A4", 2.0))

	var hw := 5.5
	var poly := PackedVector2Array([Vector2(-26.0, -0.5), Vector2(-20.0, -0.5)])
	poly.append_array(LandmarkBrKit.arch_pts(0.0, 0.6, 20.0, 5.2, 24))
	poly.append_array(PackedVector2Array([Vector2(20.0, -0.5), Vector2(26.0, -0.5)]))
	for k in 21:
		var x := 26.0 - 2.6 * float(k)
		poly.append(Vector2(x, _scalzi_deck(x)))
	LandmarkBrKit.extrude_xy(lm, "Stone", poly, -hw, hw)
	# Crisp white Istrian archivolt ring & stepped stone parapets
	var ring := LandmarkBrKit.arch_pts(0.0, 0.6, 20.5, 5.7, 24)
	for f in [-hw, hw]:
		var sz := signf(f)
		for k in ring.size() - 1:
			lm.beam("Trim", Vector3(ring[k].x, ring[k].y, f + sz * 0.10),
				Vector3(ring[k + 1].x, ring[k + 1].y, f + sz * 0.10), 0.9, 0.22, Vector3(0, 0, 1))
	for k in 20:
		var x0 := -26.0 + 2.6 * float(k)
		var x1 := x0 + 2.6
		lm.beam("Paving", Vector3(x0, _scalzi_deck(x0) + 0.12, 0.0),
			Vector3(x1, _scalzi_deck(x1) + 0.12, 0.0), hw * 1.75, 0.24)
		for z in [-hw + 0.25, hw - 0.25]:
			LandmarkDetail.balustrade(lm, "Trim", Vector3(x0, _scalzi_deck(x0), z),
				Vector3(x1, _scalzi_deck(x1), z), 1.15, 2.6)
	# Four corner Istrian lamp pedestals reaching 8.8 m crest height
	for lx in [-14.0, 0.0, 14.0]:
		var y := _scalzi_deck(float(lx)) + 1.15
		for z in [-hw + 0.25, hw - 0.25]:
			lm.box("Trim", Vector3(float(lx), y + 0.45, z), Vector3(0.42, 0.9, 0.42))
			lm.box("Lamp", Vector3(float(lx), y + 1.05, z), Vector3(0.32, 0.42, 0.32))
	lm.commit(model)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(0.0, 1.4, 11.0), Vector3(0.0, 4.8, hw), 64.0, 0.85],
		[Vector3(0.0, 1.4, -11.0), Vector3(0.0, 4.8, -hw), 64.0, 0.85],
	])

static func _scalzi_deck(x: float) -> float:
	var u := x / 26.0
	return 6.65 - 4.35 * u * u

## Ponte della Costituzione (Santiago Calatrava, 2008): 81 m swept red-oxide steel
## & laminated-glass arch linking Piazzale Roma and Santa Lucia.
static func ponte_costituzione(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("RedSteel", LandmarkMaterials.pbr("concrete", "#923730", 2.0, 0.38, 0.65))
	lm.use("Glass", LandmarkMaterials.glass("#8CC2C8"))
	lm.use("Stone", LandmarkVnKit.istrian("#DCD8CE", 2.2))
	lm.use("Steel", LandmarkMaterials.pbr("concrete", "#C8CED2", 2.0, 0.32, 0.78))
	lm.use("Lamp", LandmarkMaterials.lit("#F4FAFF", 2.4))

	var half_span := 40.5
	var segs := 28
	# Curved Istrian bank abutments
	for sx in [-1.0, 1.0]:
		lm.box("Stone", Vector3(sx * 41.5, 1.0, 0.0), Vector3(4.5, 3.0, 11.0))

	var prev_x := -half_span
	var prev_y := _cal_y(prev_x)
	var prev_hw := _cal_hw(prev_x)
	for i in range(1, segs + 1):
		var x := lerpf(-half_span, half_span, float(i) / float(segs))
		var y := _cal_y(x)
		var hw := _cal_hw(x)
		# Central red-oxide steel box spine + twin lower outer swept arches
		lm.beam("RedSteel", Vector3(prev_x, prev_y - 0.55, 0.0), Vector3(x, y - 0.55, 0.0), 1.35, 0.85)
		for s in [-1.0, 1.0]:
			lm.beam("RedSteel", Vector3(prev_x, prev_y - 0.95, s * prev_hw * 0.72),
				Vector3(x, y - 0.95, s * hw * 0.72), 0.38, 0.46)
			# Swept laminated-glass parapet walls with brushed-steel top handrail
			lm.beam("Glass", Vector3(prev_x, prev_y + 0.65, s * prev_hw),
				Vector3(x, y + 0.65, s * hw), 0.14, 1.25)
			lm.beam("Steel", Vector3(prev_x, prev_y + 1.32, s * prev_hw),
				Vector3(x, y + 1.32, s * hw), 0.22, 0.12)
			# Continuous luminous white handrail LED strip
			lm.beam("Lamp", Vector3(prev_x, prev_y + 1.20, s * (prev_hw - 0.06)),
				Vector3(x, y + 1.20, s * (hw - 0.06)), 0.08, 0.08)
		# Stepped trachyte/glass footway deck
		lm.beam("Stone", Vector3(prev_x, prev_y, 0.0), Vector3(x, y, 0.0), (prev_hw + hw) * 0.95, 0.22)
		# Radial red-steel transverse ribs
		if i % 2 == 0:
			lm.box("RedSteel", Vector3(x, y - 0.45, 0.0), Vector3(0.24, 0.42, hw * 2.02))
		prev_x = x
		prev_y = y
		prev_hw = hw

	lm.commit(model)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(0.0, 1.2, 12.0), Vector3(0.0, 6.2, 4.5), 68.0, 0.85],
		[Vector3(0.0, 1.2, -12.0), Vector3(0.0, 6.2, -4.5), 68.0, 0.85],
	])

static func _cal_y(x: float) -> float:
	var u := x / 40.5
	return 8.85 - 6.95 * u * u

static func _cal_hw(x: float) -> float:
	var u := absf(x) / 40.5
	return lerpf(4.7, 7.6, u * u)

## Ponte della Paglia (1360 / 1847): white Istrian-stone single arch at the mouth of Rio di Palazzo
## directly in front of the Bridge of Sighs on Riva degli Schiavoni (height 5.4 m).
static func ponte_paglia(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkVnKit.istrian("#ECE6D9", 2.2))
	lm.use("Trim", LandmarkVnKit.istrian_trim("#F7F3EA", 1.8))
	lm.use("Paving", LandmarkMaterials.pbr("pavement", "#C2BBB0", 2.0))
	lm.use("Lamp", LandmarkVnKit.warm_lamp("#FFE19E", 1.8))
	var hw := 5.2
	var poly := PackedVector2Array([Vector2(-8.0, -0.5), Vector2(-6.2, -0.5)])
	poly.append_array(LandmarkBrKit.arch_pts(0.0, 0.5, 6.2, 3.1, 16))
	poly.append_array(PackedVector2Array([Vector2(6.2, -0.5), Vector2(8.0, -0.5),
		Vector2(8.0, 2.2), Vector2(0.0, 4.1), Vector2(-8.0, 2.2)]))
	LandmarkBrKit.extrude_xy(lm, "Stone", poly, -hw, hw)
	lm.box("Paving", Vector3(0.0, 4.15, 0.0), Vector3(4.5, 0.2, hw * 1.85))
	for z: float in [-hw + 0.25, hw - 0.25]:
		LandmarkDetail.balustrade(lm, "Trim", Vector3(-7.8, 2.3, z), Vector3(0.0, 4.15, z), 1.05, 2.6)
		LandmarkDetail.balustrade(lm, "Trim", Vector3(0.0, 4.15, z), Vector3(7.8, 2.3, z), 1.05, 2.6)
		lm.box("Lamp", Vector3(0.0, 5.25, z), Vector3(0.28, 0.34, 0.28))
	lm.commit(model)
	LandmarkVnKit.set_warm_floods(model, 16.0, 10.4, 5.4, 0.75, true)

## Ponte delle Guglie (1580): Cannaregio Canal single stone-and-brick arch flanked by 4 corner marble obelisks (7.6 m).
static func ponte_guglie(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Brick", LandmarkVnKit.brick("#B0563E", 2.4))
	lm.use("Stone", LandmarkVnKit.istrian("#ECE6D9", 2.2))
	lm.use("Trim", LandmarkVnKit.istrian_trim("#F7F3EA", 1.8))
	lm.use("Lamp", LandmarkVnKit.warm_lamp("#FFE19E", 1.8))
	var hw := 3.7
	var poly := PackedVector2Array([Vector2(-12.0, -0.5), Vector2(-9.5, -0.5)])
	poly.append_array(LandmarkBrKit.arch_pts(0.0, 0.6, 9.5, 4.1, 18))
	poly.append_array(PackedVector2Array([Vector2(9.5, -0.5), Vector2(12.0, -0.5),
		Vector2(12.0, 2.4), Vector2(0.0, 5.2), Vector2(-12.0, 2.4)]))
	LandmarkBrKit.extrude_xy(lm, "Brick", poly, -hw, hw)
	for z: float in [-hw + 0.22, hw - 0.22]:
		LandmarkDetail.balustrade(lm, "Trim", Vector3(-11.8, 2.5, z), Vector3(0.0, 5.25, z), 1.1, 3.0)
		LandmarkDetail.balustrade(lm, "Trim", Vector3(0.0, 5.25, z), Vector3(11.8, 2.5, z), 1.1, 3.0)
		for sx: float in [-10.8, 10.8]:
			lm.box("Stone", Vector3(sx, 3.3, z), Vector3(0.95, 1.8, 0.95))
			lm.spire("Trim", Vector3(sx, 4.2, z), 0.42, 3.4, 0.0, 4)
		lm.box("Lamp", Vector3(0.0, 6.45, z), Vector3(0.28, 0.34, 0.28))
	lm.commit(model)
	LandmarkVnKit.set_warm_floods(model, 24.0, 7.4, 7.6, 0.75, true)

## Ponte dei Tre Archi (Andrea Tirali, 1688): Venice's sole surviving triple-arch stone bridge (height 6.4 m).
static func ponte_tre_archi(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Brick", LandmarkVnKit.brick("#B0563E", 2.4))
	lm.use("Stone", LandmarkVnKit.istrian("#ECE6D9", 2.2))
	lm.use("Trim", LandmarkVnKit.istrian_trim("#F7F3EA", 1.8))
	lm.use("Lamp", LandmarkVnKit.warm_lamp("#FFE19E", 1.8))
	var hw := 3.4
	var piers := PackedFloat32Array([-15.0, -7.2, 7.2, 15.0])
	LandmarkBrKit.arcade(lm, "Stone", piers, -0.5, 4.9, 1.0, 0.85, 2.0, hw, 14)
	for z: float in [-hw + 0.22, hw - 0.22]:
		LandmarkDetail.balustrade(lm, "Trim", Vector3(-14.6, 4.95, z), Vector3(14.6, 4.95, z), 1.1, 3.6)
		lm.box("Lamp", Vector3(0.0, 6.15, z), Vector3(0.28, 0.34, 0.28))
	lm.commit(model)
	LandmarkVnKit.set_warm_floods(model, 30.0, 6.8, 6.4, 0.75, true)
