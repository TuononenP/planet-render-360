class_name SEuRomeTrevi
extends RefCounted

## Trevi Fountain (Nicola Salvi & Giuseppe Pannini, 1732–1762) against Palazzo Poli.
## Origin at the centre of the sunken basin, facade facing +Z: 49.15 m wide,
## 26.3 m exact to the top of Clement XII's papal tiara crest.
##
## Combines Blender 5.3 sculpted Baroque hero `.glb` components
## (`assets/landmarks/trevi/`) with faithful Palazzo Poli architecture:
## - Deep semicircular coffered exedra apse & rosette half-dome (`trevi_exedra_apse.glb`)
## - Giant fluted Corinthian triumphal arch columns with ressaut entablature
## - Palazzo Poli rusticated basement, fluted pilasters, 3 storeys of Baroque
##   windows with scrolled corbels, balustrades & alternating pediments
## - Framed Agrippa & Aqua Virgo bas-relief panels (`trevi_relief_*.glb`)
## - Inscribed Latin attic frieze, 4 Season statues & Clement XII papal crest
##   with reclining winged Fames (`trevi_papal_crest.glb`)
## - Chiseled Baroque travertine cliff reef (`trevi_baroque_reef.glb`), scalloped
##   cockleshell chariot (`trevi_shell_chariot.glb`), Oceanus, base-trimmed
##   Rough Sea vs. Calm Sea horses (`trevi_horse_wild/calm.glb`), Tritons & masks
## - Curved-cheek sunken travertine basin, descending Piazza di Trevi seating
##   steps, perimeter bollards/chains & gap-free aligned `FountainKit` cascades.

const ASSET_DIR := "res://assets/landmarks/trevi/"
const FACADE_Z := -10.0

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Travertine", LandmarkMaterials.pbr("limestone", "#D7C8AA", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#E7DBC0", 2.0))
	lm.use("Exedra", LandmarkMaterials.pbr("limestone", "#C8B796", 2.4))
	lm.use("Glass", LandmarkMaterials.glass("#222C34"))
	lm.use("Rock", LandmarkMaterials.pbr("rock", "#BFB193", 3.0))
	lm.use("RockWet", LandmarkMaterials.pbr("rock", "#867D6A", 2.6, 0.35, 0.05))
	lm.use("Water", LandmarkMaterials.pool_water("#2A929E", 0.05))
	lm.use("Marble", LandmarkMaterials.marble("#E8E3D8", 0.34))
	lm.use("Iron", LandmarkMaterials.paint("#262A2C", 0.50, 0.55))

	_palazzo_poli_wings(lm)
	_triumphal_arch_and_attic(lm)
	_reef_and_sculptures(lm)
	_sunken_basin_and_steps(lm)
	lm.commit(model)
	_water_cascades(model)

	var warm := Color(1.0, 0.89, 0.68)
	var aqua := Color(0.62, 0.96, 1.0)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-12.0, 1.4, FACADE_Z + 18.0), Vector3(-6.0, 9.0, FACADE_Z + 3.0), 56.0, 1.0, 44.0, warm],
		[Vector3(12.0, 1.4, FACADE_Z + 18.0), Vector3(6.0, 9.0, FACADE_Z + 3.0), 56.0, 1.0, 44.0, warm],
		[Vector3(0.0, 2.8, FACADE_Z + 14.0), Vector3(0.0, 11.5, FACADE_Z + 2.5), 48.0, 1.05, 36.0, warm],
		[Vector3(0.0, 1.0, FACADE_Z + 19.0), Vector3(0.0, 5.5, FACADE_Z + 7.0), 64.0, 0.95, 34.0, aqua],
	])

static func _palazzo_poli_wings(lm: LandmarkMesh) -> void:
	var f := FACADE_Z
	var nz := Vector3(0.0, 0.0, 1.0)
	# Main palace block (width = 49.15 m, height = 20.5 m)
	lm.box("Travertine", Vector3(0.0, 10.2, f - 6.0), Vector3(49.15, 20.4, 12.0))
	# Rusticated ashlar basement courses along outer wings (y = 0..4.2 m)
	for row in 4:
		var y := 0.55 + float(row) * 0.95
		lm.box("Exedra", Vector3(0.0, y, f + 0.14), Vector3(49.25, 0.78, 0.34), Basis(), 0.0)
	lm.box("Trim", Vector3(0.0, 4.15, f + 0.24), Vector3(49.4, 0.52, 0.56))

	for s in [-1.0, 1.0]:
		var sf := float(s)
		# Giant fluted Corinthian pilasters dividing 3 bays per wing
		for i in 4:
			var x := sf * (13.0 + 3.6 * float(i))
			lm.box("Trim", Vector3(x, 11.0, f + 0.28), Vector3(1.18, 13.0, 0.54))
			# Pilaster fluting ribs
			for fl in [-0.32, 0.0, 0.32]:
				lm.box("Exedra", Vector3(x + float(fl), 11.0, f + 0.56), Vector3(0.11, 12.0, 0.06), Basis(), 0.0)
			lm.box("Trim", Vector3(x, 4.55, f + 0.36), Vector3(1.44, 0.56, 0.68))
			lm.box("Trim", Vector3(x, 17.65, f + 0.42), Vector3(1.62, 0.95, 0.78))
		# 3 articulated Baroque window bays per wing
		for i in 3:
			var x := sf * (14.8 + 3.6 * float(i))
			# Ground rusticated grilled basement window
			LandmarkDetail.window(lm, "Trim", "Glass", Vector3(x, 2.1, f + 0.20), nz, 1.25, 2.0, false, 0.24)
			# Piano nobile tall Baroque window: scrolled corbels, stone balustrade, alternating pediments
			LandmarkDetail.window(lm, "Trim", "Glass", Vector3(x, 7.9, f + 0.06), nz, 1.50, 3.35, false, 0.32)
			lm.box("Trim", Vector3(x, 5.95, f + 0.36), Vector3(2.05, 0.30, 0.54))
			# Miniature stone window balustrade & pair of scrolled corbels beneath sill
			for cx_off in [-0.72, 0.72]:
				lm.box("Trim", Vector3(x + float(cx_off), 5.55, f + 0.34), Vector3(0.26, 0.52, 0.46), Basis(), 0.0)
			for b_i in 4:
				var bx := lerpf(x - 0.58, x + 0.58, float(b_i) / 3.0)
				lm.frustum("Trim", Vector3(bx, 6.10, f + 0.42), 0.08, 0.06, 0.58, 6)
			lm.box("Trim", Vector3(x, 6.72, f + 0.42), Vector3(1.68, 0.14, 0.24), Basis(), 0.0)
			# Alternating triangular / segmental arched Baroque pediments
			if i == 1:
				SEuParts.arch_ring(lm, "Trim", Vector3(x, 9.75, f + 0.38), Vector3.RIGHT, nz, 2.05, 0.36, 0.48, false, 12)
			else:
				lm.gable("Trim", Vector3(x, 9.85, f + 0.34), 2.30, 0.58, 0.70, Basis(), 0.0, "Trim")
			# Mezzanine window with lugged architrave & sill console
			LandmarkDetail.window(lm, "Trim", "Glass", Vector3(x, 13.7, f + 0.06), nz, 1.38, 2.35, false, 0.26)
			lm.box("Trim", Vector3(x, 15.10, f + 0.28), Vector3(1.85, 0.28, 0.42))
			# Upper attic window
			LandmarkDetail.window(lm, "Trim", "Glass", Vector3(x, 19.35, f + 0.06), nz, 1.15, 1.38, false, 0.20)

	# Continuous deep modillion cornice & roofline balustrade with Baroque stone urns
	LandmarkDetail.cornice(lm, "Trim", Vector3(-24.8, 18.2, f + 0.15), Vector3(24.8, 18.2, f + 0.15), nz, 1.40, true)
	lm.box("Travertine", Vector3(0.0, 20.5, f - 6.0), Vector3(49.15, 1.0, 12.0))
	for s in [-1.0, 1.0]:
		var sf := float(s)
		SEuParts.rail(lm, "Trim", Vector3(sf * 12.6, 21.0, f - 0.15), Vector3(sf * 24.4, 21.0, f - 0.15), 1.30, 3.2)
		for ux in [16.5, 20.4, 24.2]:
			lm.lathe("Trim", Vector3(sf * float(ux), 22.30, f - 0.15), PackedVector2Array([
				Vector2(0.28, 0.0), Vector2(0.18, 0.25), Vector2(0.36, 0.65),
				Vector2(0.24, 0.95), Vector2(0.10, 1.25), Vector2(0.0, 1.35),
			]), 10)

static func _triumphal_arch_and_attic(lm: LandmarkMesh) -> void:
	var f := FACADE_Z
	var nz := Vector3(0.0, 0.0, 1.0)
	# Projecting central triumphal arch pier blocks (split left/right of the concave apse so the apse stays deeply hollowed!)
	for s in [-1.0, 1.0]:
		var sf := float(s)
		lm.box("Travertine", Vector3(sf * 8.1, 10.4, f + 1.55), Vector3(8.2, 20.8, 3.1))
	# Spandrel wall above the exedra arch crown (sealed down to y = 14.6 m behind the archivolt)
	lm.box("Travertine", Vector3(0.0, 17.7, f + 1.15), Vector3(10.0, 6.2, 2.3))
	# True deep semicircular coffered exedra apse & rosette half-dome (recessed into -Z from f + 3.10!)
	SculptureKit.stamp_path(lm, "Exedra", ASSET_DIR + "trevi_exedra_apse.glb",
		Vector3(0.0, 3.2, f + 3.10), Vector3.ONE, 0.0)
	# Inner Ionic engaged columns framing Oceanus inside the exedra opening
	for s in [-1.0, 1.0]:
		var sf := float(s)
		SEuParts.col(lm, "Trim", Vector3(sf * 3.75, 3.2, f + 3.35), 0.42, 9.0, "corinthian", 16)

	# Four giant fluted Corinthian triumphal columns on tall carved plinths + ressaut entablature breaks
	for x in [-11.0, -6.5, 6.5, 11.0]:
		var xf := float(x)
		lm.box("Trim", Vector3(xf, 1.35, f + 4.15), Vector3(2.55, 2.7, 2.55))
		LandmarkDetail.column(lm, "Trim", Vector3(xf, 2.7, f + 4.15), 0.82, 14.3, "corinthian", 24)
		# Projecting ressaut entablature block over each giant column
		lm.box("Trim", Vector3(xf, 17.85, f + 4.15), Vector3(2.70, 1.75, 2.65))
	# Continuous main triumphal arch entablature & deep cornice
	lm.box("Trim", Vector3(0.0, 17.85, f + 3.35), Vector3(25.0, 1.65, 2.45))
	LandmarkDetail.cornice(lm, "Trim", Vector3(-12.6, 18.75, f + 4.65), Vector3(12.6, 18.75, f + 4.65), nz, 1.15, true)

	# Flanking side niches (Abundance left, Salubrity right) & framed carved marble bas-relief panels above
	for s in [-1.0, 1.0]:
		var sf := float(s)
		SEuParts.niche(lm, "Trim", "Exedra", Vector3(sf * 8.75, 4.1, f + 3.10), nz, 2.75, 5.7, SEuParts.ROUND, 0.50)
		lm.box("Trim", Vector3(sf * 8.75, 4.25, f + 3.42), Vector3(1.75, 0.58, 1.20))
		SculptureKit.classical_figure(lm, "Marble", Vector3(sf * 8.75, 4.54, f + 3.50), 3.55, false, -sf * 0.14)
		var relief_file := "trevi_relief_agrippa.glb" if sf < 0.0 else "trevi_relief_virgo.glb"
		SculptureKit.stamp_path(lm, "Marble", ASSET_DIR + relief_file,
			Vector3(sf * 8.75, 11.15, f + 3.22), Vector3(3.85, 3.85, 3.85), 0.0)

	# High Dedication Attic with moulded Latin inscription tablet (CLEMENS XII PONT MAX)
	lm.box("Travertine", Vector3(0.0, 21.45, f + 1.55), Vector3(24.4, 4.3, 3.5))
	lm.box("Trim", Vector3(0.0, 21.35, f + 3.36), Vector3(12.6, 2.75, 0.26))
	lm.box("Exedra", Vector3(0.0, 21.35, f + 3.50), Vector3(11.6, 2.15, 0.08))
	# Carved stone inscription lines across the Latin dedication plaque
	for row in 4:
		var ly := 22.05 - float(row) * 0.45
		lm.box("Trim", Vector3(0.0, ly, f + 3.56), Vector3(9.8 - float(row % 2) * 1.4, 0.10, 0.04), Basis(), 0.0)
	LandmarkDetail.cornice(lm, "Trim", Vector3(-12.5, 23.62, f + 3.38), Vector3(12.5, 23.62, f + 3.38), nz, 0.65, false)

	# Four marble allegorical Season statues standing over the 4 giant Corinthian columns
	for x in [-11.0, -6.5, 6.5, 11.0]:
		var xf := float(x)
		lm.box("Trim", Vector3(xf, 19.25, f + 4.15), Vector3(1.65, 0.95, 1.65))
		SculptureKit.classical_figure(lm, "Marble", Vector3(xf, 19.72, f + 4.15), 3.15, false, 0.0)

	# Clement XII Corsini Papal Coat of Arms (escutcheon, tiara, crossed keys & reclining winged Fames) -> 26.30 m exact!
	SculptureKit.stamp_path(lm, "Marble", ASSET_DIR + "trevi_papal_crest.glb",
		Vector3(0.0, 23.60, f + 2.35), Vector3.ONE, 0.0)

static func _reef_and_sculptures(lm: LandmarkMesh) -> void:
	var f := FACADE_Z
	var reef_z := f + 6.4  # -3.6 m
	# Blender-sculpted chiseled Roman travertine reef with flat pedestal shelves & waterfall lips
	SculptureKit.stamp_path(lm, "Rock", ASSET_DIR + "trevi_baroque_reef.glb",
		Vector3(0.0, 0.0, reef_z), Vector3.ONE, 0.0)
	# Sculpted Baroque scalloped cockleshell chariot resting cleanly on the 3.85 m central shelf (z = f + 4.75)
	SculptureKit.stamp_path(lm, "Marble", ASSET_DIR + "trevi_shell_chariot.glb",
		Vector3(0.0, 3.82, f + 4.75), Vector3.ONE, 0.0)
	# Heroic Oceanus standing commanding atop the shell chariot
	SculptureKit.classical_figure(lm, "Marble", Vector3(0.0, 4.92, f + 4.82), 5.75, true, 0.0)

	# Base-trimmed Rough Sea (left, wild rearing) vs. Calm Sea (right, placid) horses + Tritons
	# Resting 100% UNBURIED on the flat 2.22 m reef shelves!
	SculptureKit.stamp_path(lm, "Marble", ASSET_DIR + "trevi_horse_wild.glb",
		Vector3(-4.9, 2.22, reef_z + 2.25), Vector3(3.45, 3.45, 3.45), -0.42)
	SculptureKit.stamp_path(lm, "Marble", ASSET_DIR + "trevi_horse_calm.glb",
		Vector3(4.9, 2.22, reef_z + 2.25), Vector3(3.35, 3.35, 3.35), 0.42)
	SculptureKit.triton_figure(lm, "Marble", Vector3(-8.4, 2.22, reef_z + 2.05), 3.05, -0.45, false)
	SculptureKit.triton_figure(lm, "Marble", Vector3(8.4, 2.22, reef_z + 2.05), 3.05, 0.45, true)

	# Four carved Baroque water-mask spouts set into the outer travertine cliff ledges
	for s in [-1.0, 1.0]:
		var sf := float(s)
		SculptureKit.stamp_path(lm, "Trim", ASSET_DIR + "trevi_corner_mask.glb",
			Vector3(sf * 13.8, 1.85, reef_z + 2.55), Vector3(1.05, 1.05, 1.05), sf * 0.15)
		SculptureKit.stamp_path(lm, "Trim", ASSET_DIR + "trevi_corner_mask.glb",
			Vector3(sf * 19.2, 1.35, reef_z + 1.30), Vector3(0.95, 0.95, 0.95), sf * 0.30)

static func _sunken_basin_and_steps(lm: LandmarkMesh) -> void:
	var f := FACADE_Z
	var z_front := f + 25.5   # +15.5 m
	var z_back := f + 4.5     # -5.5 m
	var hw := 24.0
	var cr := 5.2             # curved corner cheek radius

	# Rounded-corner travertine basin contour (quarter-round front corners!)
	var pts := PackedVector2Array()
	pts.append(Vector2(-hw, z_back))
	# Front-left curved corner
	for k in 9:
		var a := PI - PI * 0.5 * float(k) / 8.0
		pts.append(Vector2(-hw + cr + cos(a) * cr, z_front - cr + sin(a) * cr))
	# Front-right curved corner
	for k in 9:
		var a := PI * 0.5 - PI * 0.5 * float(k) / 8.0
		pts.append(Vector2(hw - cr + cos(a) * cr, z_front - cr + sin(a) * cr))
	pts.append(Vector2(hw, z_back))

	# Turquoise mineral-blue water plane filling the entire curved basin cleanly (closed fan!)
	var wat_y := 0.58
	var ctr := Vector3(0.0, wat_y, f + 15.0)
	for i in pts.size():
		var a2 := pts[i]
		var b2 := pts[(i + 1) % pts.size()]
		var p0 := Vector3(a2.x, wat_y, a2.y)
		var p1 := Vector3(b2.x, wat_y, b2.y)
		lm.tri("Water", ctr, p0, p1, Vector3.UP, Vector3.UP, Vector3.UP,
			Vector2.ZERO, Vector2(a2.x * 0.2, a2.y * 0.2), Vector2(b2.x * 0.2, b2.y * 0.2))

	# Moulded travertine basin rim, wet inner liner & 3 wide curved Piazza di Trevi seating steps
	for i in pts.size() - 1:
		var a := pts[i]
		var b := pts[i + 1]
		var seg_v := b - a
		var seg_len := seg_v.length()
		if seg_len < 0.05:
			continue
		var dir2 := seg_v / seg_len
		var out2 := Vector2(-dir2.y, dir2.x)
		if out2.dot(Vector2(a.x, a.y - (f + 15.0))) < 0.0:
			out2 = -out2
		var mid := (a + b) * 0.5
		var rot := Basis(Vector3(dir2.x, 0.0, dir2.y), Vector3.UP, Vector3(out2.x, 0.0, out2.y))
		# Wet inner basin wall + main rim + overhanging coping
		lm.box("RockWet", Vector3(mid.x - out2.x * 0.15, 0.42, mid.y - out2.y * 0.15),
			Vector3(seg_len + 0.12, 0.84, 0.35), rot, 0.0)
		lm.box("Travertine", Vector3(mid.x + out2.x * 0.38, 0.60, mid.y + out2.y * 0.38),
			Vector3(seg_len + 0.18, 1.20, 0.78), rot, 0.0)
		lm.box("Trim", Vector3(mid.x + out2.x * 0.38, 1.26, mid.y + out2.y * 0.38),
			Vector3(seg_len + 0.22, 0.16, 1.05), rot, 0.0)
		# 3 descending curved travertine seating steps wrapping the front & sides
		for st in 3:
			var dist := 1.15 + float(st) * 0.78
			var sh := 0.88 - float(st) * 0.26
			lm.box("Travertine", Vector3(mid.x + out2.x * dist, sh * 0.5, mid.y + out2.y * dist),
				Vector3(seg_len + 0.45, sh, 0.82), rot, 0.0)

	# Travertine perimeter bollards linked by wrought-iron chains along the front piazza edge
	var bollard_z := z_front + 3.4
	for k in 11:
		var bx := lerpf(-22.0, 22.0, float(k) / 10.0)
		lm.frustum("Trim", Vector3(bx, 0.0, bollard_z), 0.24, 0.18, 0.92, 8)
		lm.lathe("Trim", Vector3(bx, 0.92, bollard_z), PackedVector2Array([
			Vector2(0.18, 0.0), Vector2(0.22, 0.10), Vector2(0.12, 0.22), Vector2(0.0, 0.26),
		]), 8)
		if k < 10:
			var nx_b := lerpf(-22.0, 22.0, float(k + 1) / 10.0)
			var mid_x := (bx + nx_b) * 0.5
			lm.beam("Iron", Vector3(bx, 0.78, bollard_z), Vector3(mid_x, 0.56, bollard_z), 0.04, 0.04)
			lm.beam("Iron", Vector3(mid_x, 0.56, bollard_z), Vector3(nx_b, 0.78, bollard_z), 0.04, 0.04)

static func _water_cascades(model: Node3D) -> void:
	var fk := FountainKit.new()
	var f := FACADE_Z
	var wat_y := 0.60
	var fwd := Vector3(0.0, 0.0, 1.0)
	# Central two-tier waterfall pouring from beneath Oceanus's shell chariot over the sculpted reef lips
	fk.cascade_sheet(Vector3(-2.9, 0.0, f + 6.9), Vector3(2.9, 0.0, f + 6.9), 3.85, 2.35, fwd, 2.1, 0.82)
	fk.cascade_sheet(Vector3(-4.2, 0.0, f + 9.2), Vector3(4.2, 0.0, f + 9.2), 2.40, wat_y, fwd, 2.4, 0.94)
	# Flanking reef cascades & arched spouts from carved rock grottoes & Baroque corner masks
	for s in [-1.0, 1.0]:
		var sf := float(s)
		fk.cascade_sheet(Vector3(sf * 4.3, 0.0, f + 10.1), Vector3(sf * 9.5, 0.0, f + 9.7), 2.25, wat_y, fwd, 2.1, 0.88)
		fk.cascade_sheet(Vector3(sf * 10.0, 0.0, f + 9.4), Vector3(sf * 16.4, 0.0, f + 8.4), 2.10, wat_y, fwd, 1.9, 0.84)
		fk.cascade_sheet(Vector3(sf * 16.8, 0.0, f + 8.2), Vector3(sf * 21.4, 0.0, f + 6.8), 1.55, wat_y, fwd, 1.7, 0.78)
		# Arched spouts from beneath Oceanus, behind the horses & from the carved corner water-masks
		fk.arc_stream(Vector3(sf * 2.1, 3.88, f + 6.7), Vector3(sf * 3.1, wat_y, f + 13.2), 0.92, 0.18, 0.46)
		fk.arc_stream(Vector3(sf * 6.8, 2.30, f + 9.9), Vector3(sf * 7.8, wat_y, f + 14.0), 0.68, 0.16, 0.40)
		fk.arc_stream(Vector3(sf * 13.8, 2.28, f + 9.1), Vector3(sf * 14.5, wat_y, f + 13.2), 0.62, 0.15, 0.38)
		fk.arc_stream(Vector3(sf * 19.2, 1.75, f + 7.9), Vector3(sf * 19.6, wat_y, f + 11.4), 0.50, 0.13, 0.34)
		for pt in [Vector3(sf * 3.1, wat_y, f + 13.2), Vector3(sf * 7.8, wat_y, f + 14.0),
				Vector3(sf * 14.5, wat_y, f + 13.2), Vector3(sf * 19.6, wat_y, f + 11.4)]:
			fk.splash_ring(pt, 1.65, 0.90)
		fk.mist_emitter(Vector3(sf * 7.4, wat_y + 0.35, f + 12.2), 2.2, 1.5, 4)
		fk.mist_emitter(Vector3(sf * 14.4, wat_y + 0.30, f + 11.2), 1.8, 1.3, 3)
	# Churning aerated plunge-pool boil curving along the entire reef waterline
	fk.splash_strip(Vector3(-10.5, wat_y, f + 11.2), Vector3(10.5, wat_y, f + 11.2), fwd, 3.6, 0.95)
	fk.splash_strip(Vector3(-21.2, wat_y, f + 9.0), Vector3(-10.2, wat_y, f + 11.1), Vector3(-0.18, 0.0, 0.98), 3.3, 0.88)
	fk.splash_strip(Vector3(10.2, wat_y, f + 11.1), Vector3(21.2, wat_y, f + 9.0), Vector3(0.18, 0.0, 0.98), 3.3, 0.88)
	fk.mist_emitter(Vector3(0.0, wat_y + 0.45, f + 11.8), 2.8, 2.0, 6)
	fk.commit(model)
