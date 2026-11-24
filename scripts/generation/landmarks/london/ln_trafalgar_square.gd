class_name LandmarkLnTrafalgarSquare
extends RefCounted

## Trafalgar Square ensemble (`LN-3.5`, OSM ways 150920358, 30734422):
## - Yorkstone stepped plaza terraces & four corner plinths (Fourth Plinth NW,
##   Chantrey's equestrian George IV NE, Havelock SE, Napier SW).
## - Nelson's Column (William Railton, 1843): 51.6 m fluted Dartmoor granite
##   Corinthian column on stepped bronze-relief plinth, four Edwin Landseer
##   reclining bronze lions on curved radiating pedestals, cast-bronze acanthus
##   Corinthian capital, and 5.5 m Craigleith-stone Admiral Nelson statue.
## - Twin Lutyens fountains (1939): four-lobed scalloped cruciform Portland
##   basins, tiered fluted bronze bowls, McMillan & Wheeler dolphin/mermaid/triton
##   sculptural groups, and multi-ring converging `FountainKit` water plumes.
## - William Wilkins' National Gallery & North Terrace (`LandmarkLnTrafalgarGallery`).
## - Iconic octagonal Trafalgar Square bronze lamp standards & warm dusk lighting.

const COL_TOP := 51.6
const ASSET_DIR := "res://assets/landmarks/trafalgar/"
const Gallery = preload("res://scripts/generation/landmarks/london/ln_trafalgar_gallery.gd")

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Granite", LandmarkLnKit.granite("#8B867E", 3.0))
	lm.use("Stone", LandmarkLnKit.portland("#E2DAC8", 3.4))
	lm.use("DarkStone", LandmarkLnKit.portland("#B9B09E", 3.2))
	lm.use("Statue", LandmarkMaterials.marble("#DCD6C8", 0.36))
	lm.use("Bronze", LandmarkMaterials.paint("#2A322C", 0.42, 0.68))
	lm.use("Lead", LandmarkMaterials.paint("#525B64", 0.50, 0.38))
	lm.use("Water", LandmarkMaterials.pool_water("#2F7482"))
	lm.use("Glass", LandmarkMaterials.glass("#222C34"))
	lm.use("Lamp", LandmarkMaterials.lit("#FFE2A8", 1.35))

	_square_floor_and_plinths(lm)
	_nelsons_column(lm)
	_lutyens_fountains(lm)
	Gallery.build(lm)
	_victorian_lanterns(lm)
	lm.commit(model)
	_fountain_flow(model)

	var warm := Color(1.0, 0.90, 0.72)
	var aqua := Color(0.65, 0.95, 1.0)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(0.0, 2.4, 15.0), Vector3(0.0, 38.0, 0.0), 44.0, 1.05, 70.0, warm],
		[Vector3(-12.0, 2.0, -10.0), Vector3(0.0, 12.0, 0.0), 50.0, 0.85, 45.0, warm],
		[Vector3(0.0, 4.2, -56.0), Vector3(0.0, 18.0, -76.0), 68.0, 0.95, 72.0, warm],
		[Vector3(0.0, 12.0, -64.0), Vector3(0.0, 34.0, -83.5), 48.0, 0.90, 60.0, warm],
		[Vector3(-25.0, 1.8, -32.0), Vector3(-25.0, 4.5, -35.0), 58.0, 0.85, 24.0, aqua],
		[Vector3(25.0, 1.8, -32.0), Vector3(25.0, 4.5, -35.0), 58.0, 0.85, 24.0, aqua],
	])

static func _square_floor_and_plinths(lm: LandmarkMesh) -> void:
	# Stepped Yorkstone plaza deck (medium warm grey granite paving contrasting with Portland stone gallery)
	lm.box("Granite", Vector3(0.0, 0.12, -24.0), Vector3(92.0, 0.24, 68.0))
	lm.box("DarkStone", Vector3(0.0, 0.26, -24.0), Vector3(88.0, 0.08, 64.0), Basis(), 0.0)
	# Four Corner Plinths around the square:
	# NE: Chantrey's Equestrian King George IV (+38, -50)
	# NW: Fourth Plinth (-38, -50)
	# SE & SW: Generals Havelock (+34, +6) & Napier (-34, +6)
	var plinths := [
		[Vector3(38.0, 0.28, -50.0), "george_iv_equestrian.glb", 4.6, 0.25],
		[Vector3(-38.0, 0.28, -50.0), "fourth_plinth_sculpture.glb", 3.8, -0.25],
		[Vector3(34.0, 0.28, 6.0), "general_plinth_statue.glb", 3.6, -0.35],
		[Vector3(-34.0, 0.28, 6.0), "general_plinth_statue.glb", 3.6, 0.35],
	]
	for p in plinths:
		var pos: Vector3 = p[0]
		var asset: String = p[1]
		var h_statue: float = p[2]
		var yaw: float = p[3]
		lm.box("Granite", pos + Vector3(0.0, 0.35, 0.0), Vector3(4.8, 0.70, 5.8))
		lm.box("Stone", pos + Vector3(0.0, 2.55, 0.0), Vector3(3.4, 3.7, 4.4))
		lm.box("Stone", pos + Vector3(0.0, 4.55, 0.0), Vector3(3.9, 0.42, 4.9))
		SculptureKit.stamp_path(lm, "Bronze", ASSET_DIR + asset,
			pos + Vector3(0.0, 4.76, 0.0), Vector3(h_statue, h_statue, h_statue), yaw)

static func _nelsons_column(lm: LandmarkMesh) -> void:
	# 3-step Dartmoor granite platform (y = 0.0..2.1 m)
	lm.box("Granite", Vector3(0.0, 0.35, 0.0), Vector3(15.6, 0.70, 15.6))
	lm.box("Granite", Vector3(0.0, 1.05, 0.0), Vector3(13.2, 0.70, 13.2))
	lm.box("Granite", Vector3(0.0, 1.75, 0.0), Vector3(10.8, 0.70, 10.8))
	# Tall moulded square granite pedestal (y = 2.1..11.2 m)
	lm.box("Granite", Vector3(0.0, 2.75, 0.0), Vector3(7.6, 1.3, 7.6))
	lm.box("Granite", Vector3(0.0, 6.75, 0.0), Vector3(6.4, 6.7, 6.4))
	lm.box("Granite", Vector3(0.0, 10.45, 0.0), Vector3(7.5, 0.75, 7.5))
	lm.box("Granite", Vector3(0.0, 11.05, 0.0), Vector3(6.8, 0.48, 6.8))
	# Four sculpted bronze Trafalgar battle bas-relief panels
	for rot_i in 4:
		var ang := PI * 0.5 * float(rot_i)
		var out := Vector3(sin(ang), 0.0, cos(ang))
		SculptureKit.stamp_path(lm, "Bronze", ASSET_DIR + "nelson_relief_panel.glb",
			Vector3(0.0, 4.55, 0.0) + out * 3.24, Vector3(4.35, 4.35, 4.35), ang)
	# Four Edwin Landseer reclining (couchant) bronze lions on curved radiating granite plinths
	for i in 4:
		var a := PI * 0.25 + PI * 0.5 * float(i)
		var dir := Vector3(cos(a), 0.0, sin(a))
		var yaw := atan2(dir.x, dir.z)
		var rot := Basis(Vector3.UP, yaw)
		var p_base := dir * 8.5
		lm.box("Granite", p_base + Vector3(0.0, 0.55, 0.0), Vector3(3.1, 1.1, 6.8), rot)
		lm.box("Granite", p_base + Vector3(0.0, 1.85, 0.0), Vector3(2.55, 1.5, 6.1), rot)
		lm.box("Stone", p_base + Vector3(0.0, 2.72, 0.0), Vector3(2.85, 0.28, 6.45), rot)
		# True reclining Landseer bronze lion (length = 5.8 m, paws facing outward!)
		SculptureKit.stamp_path(lm, "Bronze", ASSET_DIR + "landseer_lion.glb",
			p_base + Vector3(0.0, 2.86, 0.0), Vector3(5.8, 5.8, 5.8), yaw)

	# Moulded Attic torus-scotia-torus column base (11.29..12.6 m)
	lm.lathe("Granite", Vector3(0.0, 11.29, 0.0), PackedVector2Array([
		Vector2(2.75, 0.0), Vector2(2.78, 0.32), Vector2(2.42, 0.55),
		Vector2(2.58, 0.88), Vector2(2.25, 1.15), Vector2(2.12, 1.32),
	]), 24, 1.0, 1.0, 0.0, true, false)

	# 24-flute tapered Dartmoor granite Corinthian shaft (12.6..42.4 m) with subtle entasis
	_fluted_shaft(lm, "Granite", Vector3(0.0, 12.6, 0.0), 2.12, 1.72, 29.8, 24)

	# Sculpted cast-bronze Corinthian capital with acanthus leaves & volutes (42.4..45.4 m)
	SculptureKit.stamp_path(lm, "Bronze", ASSET_DIR + "corinthian_capital_bronze.glb",
		Vector3(0.0, 42.35, 0.0), Vector3(3.15, 3.15, 3.15), 0.0)
	# Circular stone drum supporting Admiral Nelson (45.4..46.1 m)
	lm.frustum("Granite", Vector3(0.0, 45.4, 0.0), 1.35, 1.28, 0.72, 18)
	# 5.5 m Craigleith sandstone statue of Admiral Horatio Nelson (46.1..51.6 m exact!)
	SculptureKit.stamp_path(lm, "Statue", ASSET_DIR + "nelson_statue.glb",
		Vector3(0.0, 46.1, 0.0), Vector3(5.5, 5.5, 5.5), 0.0)

static func _fluted_shaft(lm: LandmarkMesh, key: String, base: Vector3, r_bot: float, r_top: float,
		h: float, flutes: int) -> void:
	var segs := flutes * 2  # 48 perimeter points capturing crisp flutes & fillets
	var rings := 10
	var centers := PackedVector3Array()
	var rows: Array = []
	for j in rings + 1:
		var t := float(j) / float(rings)
		var y := base.y + t * h
		# Classical entasis curve
		var entasis := sin(t * PI) * 0.06
		var r := lerpf(r_bot, r_top, t) + entasis
		var flute_amp := 0.065 * sin(clampf(t * 14.0, 0.0, PI * 0.5)) * sin(clampf((1.0 - t) * 14.0, 0.0, PI * 0.5))
		centers.append(Vector3(base.x, y, base.z))
		var row := PackedVector3Array()
		for i in segs + 1:
			var a := TAU * float(i) / float(segs) if i < segs else 0.0
			var rf := r - flute_amp * (0.5 - 0.5 * cos(a * float(flutes)))
			row.append(Vector3(base.x + cos(a) * rf, y, base.z + sin(a) * rf))
		rows.append(row)
	SculptureKit.emit_rings(lm, key, centers, rows)

static func _lutyens_fountains(lm: LandmarkMesh) -> void:
	for sx in [-1.0, 1.0]:
		var fx := float(sx) * 25.0
		var fz := -35.0
		var c := Vector3(fx, 0.28, fz)
		# Four-lobed scalloped cruciform Portland-granite basin (Sir Edwin Lutyens, 1939)
		_four_lobed_basin(lm, c, 9.8)
		# Inner stepped bronze pedestal & two fluted cantilevered cascading saucer bowls
		lm.lathe("Granite", c + Vector3(0.0, 0.50, 0.0), PackedVector2Array([
			Vector2(2.65, 0.0), Vector2(2.45, 0.55), Vector2(1.95, 0.95),
		]), 20)
		lm.lathe("Bronze", c + Vector3(0.0, 1.45, 0.0), PackedVector2Array([
			Vector2(1.65, 0.0), Vector2(1.30, 0.85), Vector2(1.15, 1.55),
			Vector2(3.45, 2.05), Vector2(3.65, 2.32), Vector2(3.35, 2.38),
			Vector2(1.45, 2.15), Vector2(0.88, 2.85), Vector2(1.85, 3.25),
			Vector2(1.98, 3.45), Vector2(1.75, 3.50), Vector2(0.45, 3.35),
			Vector2(0.28, 4.15), Vector2(0.0, 4.30),
		]), 24)
		# McMillan & Wheeler sculpted dolphins, mermaids & tritons cluster
		SculptureKit.stamp_path(lm, "Bronze", ASSET_DIR + "lutyens_fountain_group.glb",
			c + Vector3(0.0, 0.65, 0.0), Vector3.ONE, 0.0 if sx < 0.0 else PI * 0.5)

static func _four_lobed_basin(lm: LandmarkMesh, c: Vector3, radius: float) -> void:
	var segs := 64
	# Cross-section profile (radial offset from contour, y): outer step, wall, coping, inner wall
	var prof := [
		Vector2(1.15, 0.0), Vector2(1.15, 0.25), Vector2(0.75, 0.25),
		Vector2(0.75, 0.95), Vector2(0.85, 1.12), Vector2(0.0, 1.12),
		Vector2(0.0, 0.50),
	]
	var contour_r := func(a: float) -> float:
		# Four-lobed cruciform Lutyens silhouette (scalloped bays at 0/90/180/270 deg)
		return radius * (0.90 + 0.14 * cos(4.0 * a) - 0.03 * cos(8.0 * a))

	var centers := PackedVector3Array()
	var rows: Array = []
	for pt in prof:
		centers.append(c + Vector3(0.0, pt.y, 0.0))
		var row := PackedVector3Array()
		for i in segs + 1:
			var a := TAU * float(i) / float(segs) if i < segs else 0.0
			var rr: float = contour_r.call(a) + pt.x
			row.append(Vector3(c.x + cos(a) * rr, c.y + pt.y, c.z + sin(a) * rr))
		rows.append(row)
	SculptureKit.emit_rings(lm, "Granite", centers, rows)

	# Contoured turquoise water surface filling the four-lobed basin cleanly
	var wat_y := c.y + 0.88
	var ctr := Vector3(c.x, wat_y, c.z)
	for i in segs:
		var a0 := TAU * float(i) / float(segs)
		var a1 := TAU * float(i + 1) / float(segs)
		var r0: float = contour_r.call(a0) + 0.08
		var r1: float = contour_r.call(a1) + 0.08
		var p0 := Vector3(c.x + cos(a0) * r0, wat_y, c.z + sin(a0) * r0)
		var p1 := Vector3(c.x + cos(a1) * r1, wat_y, c.z + sin(a1) * r1)
		lm.tri("Water", ctr, p0, p1, Vector3.UP, Vector3.UP, Vector3.UP,
			Vector2.ZERO, Vector2(cos(a0) * r0, sin(a0) * r0), Vector2(cos(a1) * r1, sin(a1) * r1))

static func _victorian_lanterns(lm: LandmarkMesh) -> void:
	# 8 iconic octagonal Trafalgar Square bronze lamp standards with glowing globes
	var spots := [
		Vector3(-12.2, 3.6, -57.6), Vector3(12.2, 3.6, -57.6),
		Vector3(-34.0, 3.6, -57.6), Vector3(34.0, 3.6, -57.6),
		Vector3(-16.0, 0.28, -14.0), Vector3(16.0, 0.28, -14.0),
		Vector3(-16.0, 0.28, 12.0), Vector3(16.0, 0.28, 12.0),
	]
	for p in spots:
		SculptureKit.stamp_path(lm, "Bronze", ASSET_DIR + "trafalgar_lantern.glb",
			p, Vector3(4.6, 4.6, 4.6), 0.0)
		lm.frustum("Lamp", p + Vector3(0.0, 3.55, 0.0), 0.28, 0.30, 0.62, 8)

static func _fountain_flow(model: Node3D) -> void:
	var fk := FountainKit.new()
	for sx in [-1.0, 1.0]:
		var c := Vector3(float(sx) * 25.0, 0.28, -35.0)
		var wat_y := 0.88
		# Tall central pressurized spire jet rising from upper bronze nozzle
		fk.jet_plume(c + Vector3(0.0, 5.75, 0.0), 6.2, 0.22, 0.72)
		# Cascading waterfall curtains spilling over upper & lower fluted bronze saucers
		fk.bowl_curtain(c, 1.95, 4.92, 3.82, 0.82, 20)
		fk.bowl_curtain(c, 3.60, 3.80, wat_y, 0.96, 28)
		fk.splash_ring(c + Vector3(0.0, wat_y, 0.0), 4.6, 0.92)
		# 8 converging perimeter arcs from dolphins & tritons
		for k in 8:
			var a := TAU * float(k) / 8.0
			var d := Vector3(cos(a), 0.0, sin(a))
			var r_start := 4.4 if (k % 2 == 0) else 4.9
			var h_start := 1.75 if (k % 2 == 0) else 2.25
			fk.arc_stream(c + d * r_start + Vector3(0.0, h_start, 0.0),
				c + d * 2.1 + Vector3(0.0, wat_y, 0.0), 2.35, 0.12, 0.34)
			fk.splash_ring(c + d * 2.1 + Vector3(0.0, wat_y, 0.0), 1.35, 0.82)
		fk.mist_emitter(c + Vector3(0.0, wat_y + 0.6, 0.0), 2.8, 2.0, 5)
	fk.commit(model)
