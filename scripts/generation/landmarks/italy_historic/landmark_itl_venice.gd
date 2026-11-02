class_name LandmarkItlVenice
extends RefCounted

## St Mark's Basilica in true metres: the Byzantine five-domed church of
## the Piazza San Marco (76.5 x 62.6 m), its marble-encrusted narthex
## front and Gothic crowning (late 14th - early 15th century).

const FACADE_Z := 37.0
const ARM := 19.2
const ROOF_Y := 21.0
const TERRACE_Y := 14.0
const XS := [-20.8, -10.4, 0.0, 10.4, 20.8]

## Origin under the central dome, the Piazza facade facing +Z. A Greek
## cross of five domes: 12.8 m arms with lower corner chapels and the
## apse, the 52 m narthex in front. The facade: five deep portals (the
## central one widest) with stepped archivolts between piers sheathed in
## two tiers of clustered marble columns, gold mosaic lunettes; the
## terrace balustrade with the four gilt horses over the central portal;
## the upper tier of five lunettes under ogee arches with crockets and a
## statue on each crown (St Mark over the centre, its lunette blue and
## starred with the winged lion), four tabernacle turrets with pinnacles
## between them and two at the ends. On the flanks the arcaded lower
## storey and lunettes with statues. The five lead-sheathed domes rise on
## drums of sixteen windows to bulbous lanterns and crosses, the central
## one 43 m.
static func basilica(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#E4DACA", 3.0))
	lm.use("Pink", LandmarkMaterials.pbr("limestone", "#CFA997", 3.0))
	lm.use("Lead", LandmarkMaterials.pbr("concrete", "#8E9496", 2.0, 0.45, 0.35))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.use("Blue", LandmarkMaterials.paint("#26437F", 0.5, 0.1))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#3E362E", 3.0))
	lm.use("Col", LandmarkMaterials.pbr("limestone", "#B9B3A5", 2.0))
	# Cross arms, corner chapels, narthex and apse.
	lm.box("Marble", Vector3(0, ROOF_Y * 0.5, 0), Vector3(12.8, ROOF_Y, 51.2))
	lm.box("Marble", Vector3(0, ROOF_Y * 0.5, 0), Vector3(51.2, ROOF_Y, 12.8))
	lm.box("Lead", Vector3(0, ROOF_Y + 0.1, 0), Vector3(12.6, 0.2, 51.0))
	lm.box("Lead", Vector3(0, ROOF_Y + 0.1, 0), Vector3(51.0, 0.2, 12.6))
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			lm.box("Marble", Vector3(sx * 16.0, 7.5, sz * 16.0), Vector3(19.2, 15.0, 19.2))
			lm.box("Lead", Vector3(sx * 16.0, 15.1, sz * 16.0), Vector3(19.0, 0.2, 19.0))
	lm.box("Marble", Vector3(0, TERRACE_Y * 0.5, 31.3), Vector3(51.8, TERRACE_Y, 11.4))
	lm.box("Lead", Vector3(0, TERRACE_Y + 0.05, 31.3), Vector3(51.4, 0.1, 10.8))
	lm.frustum("Marble", Vector3(0, 0, -25.6), 6.4, 6.4, 15.0, 12)
	lm.frustum("Lead", Vector3(0, 15.0, -25.6), 6.6, 0.0, 3.2, 12)
	for sgn in [-1.0, 1.0]:
		_flank(lm, float(sgn))
	# The five domes: central, then west, east, north and south arms.
	_dome(lm, Vector3.ZERO, 5.8, 5.5, 10.5, 3.5, 2.5)
	for p in [Vector3(0, 0, ARM), Vector3(0, 0, -ARM), Vector3(ARM, 0, 0), Vector3(-ARM, 0, 0)]:
		_dome(lm, p, 5.2, 4.5, 9.0, 3.0, 2.2)
	_facade(lm)
	_upper(lm)
	lm.commit(model)

## A dome: drum with sixteen arched windows between pilasters, onion shell
## of lead, open lantern of six colonnettes, bulb and gilt cross.
static func _dome(lm: LandmarkMesh, c: Vector3, r: float, drum_h: float, shell_h: float, lantern_h: float,
		finial_h: float) -> void:
	var base := Vector3(c.x, ROOF_Y, c.z)
	lm.frustum("Marble", base, r, r, drum_h, 32)
	lm.frustum("Pink", base, r * 1.04, r * 1.04, 0.4, 32)
	for i in 16:
		var a := TAU * (float(i) + 0.5) / 16.0
		var d := Vector3(cos(a), 0, sin(a))
		LandmarkItlParts.gothic_window(lm, "Pink", "Shadow", base + d * r * 0.99 + Vector3(0, 1.0, 0), d, 0.95,
			drum_h - 2.2, 1, false, 0.16, 0.14)
	lm.frustum("Pink", base + Vector3(0, drum_h - 0.5, 0), r * 1.06, r * 1.06, 0.5, 32)
	var top := base + Vector3(0, drum_h, 0)
	lm.lathe("Lead", top, LandmarkItlUtil.bulb(r, shell_h), 32)
	# Lantern: ring, colonnettes, a little roof and bulb.
	var lan := top + Vector3(0, shell_h - 0.3, 0)
	var lr := r * 0.24
	lm.frustum("Lead", lan, lr * 1.2, lr * 1.15, 0.3, 12)
	for i in 6:
		var a := TAU * float(i) / 6.0
		lm.frustum("Marble", lan + Vector3(cos(a) * lr, 0.3, sin(a) * lr), 0.1, 0.09, lantern_h * 0.45, 6)
	lm.frustum("Marble", lan + Vector3(0, 0.3, 0), lr * 0.55, lr * 0.55, lantern_h * 0.45, 8)
	var ly := lan + Vector3(0, 0.3 + lantern_h * 0.45, 0)
	lm.frustum("Lead", ly, lr * 1.25, lr * 1.2, 0.25, 12)
	lm.lathe("Gold", ly + Vector3(0, 0.25, 0), LandmarkItlUtil.bulb(lr * 0.9, lantern_h * 0.55 - 0.25), 12)
	SEuUtil.finial(lm, "Gold", top + Vector3(0, shell_h + lantern_h, 0), finial_h)

## The west front's lower register: five portals and the column piers.
static func _facade(lm: LandmarkMesh) -> void:
	var z := FACADE_Z
	var out := Vector3(0, 0, 1)
	var ws := [8.0, 8.0, 9.6, 8.0, 8.0]
	var hs := [10.2, 10.2, 12.0, 10.2, 10.2]
	for i in 5:
		var x: float = XS[i]
		var w: float = ws[i]
		var h: float = hs[i]
		var spring := h - w * 0.5
		var orders := 4 if i == 2 else 3
		# Recess: dark doorway, gold lunette, stepped archivolts receding.
		var inner := w - 0.9 * float(orders)
		lm.quad("Shadow", Vector3(x - inner * 0.5, 0, z + 0.04), Vector3(x + inner * 0.5, 0, z + 0.04),
			Vector3(x + inner * 0.5, spring, z + 0.04), Vector3(x - inner * 0.5, spring, z + 0.04), out)
		LandmarkItlUtil.lunette(lm, "Gold", Vector3(x, spring - 0.01, z + 0.05), Vector3.RIGHT, inner)
		lm.box("Marble", Vector3(x, spring - 0.3, z + 0.2), Vector3(inner + 0.4, 0.6, 0.4))
		for o in orders:
			var hw := inner * 0.5 + 0.45 * float(o) + 0.22
			var dz := 0.3 + 0.45 * float(o)
			var arc := LandmarkItlParts.arch_pts(Vector3(x, spring, z + dz), Vector3.RIGHT, hw, false, 12)
			for k in arc.size() - 1:
				lm.beam("Marble" if o % 2 == 0 else "Pink", arc[k], arc[k + 1], 0.45, 0.44, out)
			for s in [-1.0, 1.0]:
				lm.box("Marble", Vector3(x + float(s) * hw, spring * 0.5, z + dz * 0.5), Vector3(0.46, spring, dz + 0.1))
		# Gilt mosaic band round the outer arch.
		var oh := inner * 0.5 + 0.45 * float(orders) + 0.25
		var arc2 := LandmarkItlParts.arch_pts(Vector3(x, spring, z + 0.05), Vector3.RIGHT, oh, false, 14)
		for k in arc2.size() - 1:
			lm.beam("Gold", arc2[k], arc2[k + 1], 0.12, 0.3, out)
	# Piers between and beside the portals: two tiers of clustered columns.
	for px in [-25.35, -15.6, -5.6, 5.6, 15.6, 25.35]:
		var x: float = px
		lm.box("Marble", Vector3(x, 6.6, z + 0.2), Vector3(2.4, 13.2, 0.4))
		for tier in 2:
			var y0 := 0.0 if tier == 0 else 6.6
			var ch := 6.0
			lm.box("Pink", Vector3(x, y0 + 0.3, z + 0.9), Vector3(2.6, 0.6, 1.4))
			for cx in [-0.75, -0.25, 0.25, 0.75]:
				var dzz := 1.1 if absf(float(cx)) < 0.5 else 0.8
				LandmarkItlParts.column(lm, "Col", Vector3(x + float(cx), y0 + 0.6, z + dzz), 0.2, ch - 0.6, 8, false)
	lm.box("Marble", Vector3(0, 13.3, z + 0.4), Vector3(52.6, 1.4, 1.8))
	LandmarkDetail.cornice(lm, "Pink", Vector3(-26.3, 13.3, z + 1.3), Vector3(26.3, 13.3, z + 1.3), out, 0.7, false)
	# Terrace balustrade and the four horses.
	LandmarkDetail.balustrade(lm, "Marble", Vector3(-25.8, TERRACE_Y, z + 0.6), Vector3(25.8, TERRACE_Y, z + 0.6), 1.1,
		5.2)
	for x in [-4.2, -1.4, 1.4, 4.2]:
		_horse(lm, Vector3(x, TERRACE_Y, 35.0))

## The Gothic upper tier: lunettes under ogee arches with crockets and
## statues, tabernacle turrets between them.
static func _upper(lm: LandmarkMesh) -> void:
	var uz := 33.5
	var out := Vector3(0, 0, 1)
	lm.box("Marble", Vector3(0, 20.1, uz - 1.25), Vector3(51.8, 12.2, 2.5))
	lm.box("Pink", Vector3(0, 26.7, uz - 0.7), Vector3(52.6, 1.0, 1.6))
	for i in 5:
		var x: float = XS[i]
		var w: float = 9.8 if i == 2 else 8.6
		var top: float = 21.0 if i == 2 else 20.0
		lm.quad("Shadow", Vector3(x - w * 0.5, TERRACE_Y, uz + 0.06), Vector3(x + w * 0.5, TERRACE_Y, uz + 0.06),
			Vector3(x + w * 0.5, top, uz + 0.06), Vector3(x - w * 0.5, top, uz + 0.06), out)
		LandmarkItlUtil.lunette(lm, "Blue" if i == 2 else "Gold", Vector3(x, top, uz + 0.08), Vector3.RIGHT, w)
		var arc := LandmarkItlParts.arch_pts(Vector3(x, top, uz + 0.3), Vector3.RIGHT, w * 0.5 + 0.25, false, 14)
		for k in arc.size() - 1:
			lm.beam("Marble", arc[k], arc[k + 1], 0.5, 0.45, out)
		# Ogee crown with crockets from the arch haunches to a statue.
		var rise := 7.6 if i == 2 else 5.6
		_ogee(lm, Vector3(x, top + 0.2, uz + 0.4), w * 0.5 + 0.6, rise)
		var statue_h := 3.4 if i == 2 else 2.4
		lm.box("Marble", Vector3(x, top + rise + 0.6, uz + 0.4), Vector3(0.9, 0.6, 0.9))
		LandmarkKits.statue_figure(lm, "Gold", Vector3(x, top + rise + 0.9, uz + 0.4), statue_h, i == 2)
	# The winged lion and stars in the central lunette.
	for k in 9:
		var a := PI * (0.1 + 0.8 * float(k) / 8.0)
		lm.disc("Gold", Vector3(cos(a) * 4.0, 21.0 + sin(a) * 4.0, uz + 0.1), out, 0.28, 8)
	SEuUtil.blob(lm, "Gold", Vector3(0, 22.6, uz + 0.3), 1.3, 0.6, 0.35, Vector3.ZERO, false, 5, 12)
	for s in [-1.0, 1.0]:
		lm.beam("Gold", Vector3(float(s) * 0.3, 23.0, uz + 0.3), Vector3(float(s) * 1.6, 24.2, uz + 0.25), 0.9, 0.15)
	SEuUtil.blob(lm, "Gold", Vector3(1.4, 23.2, uz + 0.35), 0.4, 0.4, 0.3, Vector3.ZERO, false, 4, 8)
	# Tabernacle turrets between the lunettes and at both ends.
	for tx in [-25.6, -15.6, -5.2, 5.2, 15.6, 25.6]:
		_tabernacle(lm, Vector3(float(tx), 26.2, uz), absf(float(tx)) > 25.0)

## Ogee arch: two S-curves from the springers (half-span hw) meeting at
## a point `rise` above, a moulded band with leafy crockets on top.
static func _ogee(lm: LandmarkMesh, c: Vector3, hw: float, rise: float) -> void:
	for s in [-1.0, 1.0]:
		var sx: float = s
		var prev := c + Vector3(sx * hw, 0, 0)
		for k in 12:
			var t := float(k + 1) / 12.0
			var u := 1.0 - t
			# Cubic Bezier (hw,0) (hw,0.55r) (0.15hw,0.45r) (0,r).
			var px := u * u * u * hw + 3.0 * u * u * t * hw + 3.0 * u * t * t * hw * 0.15
			var py := 3.0 * u * u * t * rise * 0.55 + 3.0 * u * t * t * rise * 0.45 + t * t * t * rise
			var p := c + Vector3(sx * px, py, 0)
			lm.beam("Marble", prev, p, 0.4, 0.35, Vector3(0, 0, 1))
			if k % 2 == 1 and k < 11:
				var d := (p - prev).normalized()
				var nrm := Vector3(0, 0, 1).cross(d).normalized() * -sx
				if nrm.y < 0.0:
					nrm = -nrm
				SEuUtil.blob(lm, "Marble", p + nrm * 0.35, 0.22, 0.28, 0.18, Vector3.ZERO, false, 3, 6)
			prev = p

## Tabernacle turret on the cornice: a little open shrine of four
## colonnettes under gablets, then a crocketed pinnacle and a finial.
static func _tabernacle(lm: LandmarkMesh, b: Vector3, end: bool) -> void:
	var hw := 0.8 if end else 0.65
	var h := 3.2
	lm.box("Marble", b + Vector3(0, 0.25, 0), Vector3(hw * 2.4, 0.5, hw * 2.4))
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			lm.frustum("Col", b + Vector3(float(sx) * hw, 0.5, float(sz) * hw), 0.12, 0.1, h, 6)
	lm.box("Marble", b + Vector3(0, 0.5 + h * 0.4, 0), Vector3(hw * 1.2, h * 0.8, hw * 1.2))
	var tb := b + Vector3(0, 0.5 + h, 0)
	lm.box("Marble", tb + Vector3(0, 0.2, 0), Vector3(hw * 2.4, 0.4, hw * 2.4))
	for k in 4:
		var bas := Basis(Vector3.UP, PI * 0.5 * float(k))
		lm.gable("Marble", tb + Vector3(0, 0.4, 0) + bas * Vector3(0, 0, hw * 0.9), hw * 2.2, 0.3, 1.0, bas, 0.0, "Marble")
	var ph := 4.0 if end else 3.2
	lm.spire("Marble", tb + Vector3(0, 0.4, 0), hw * 0.9, ph, 0.0, 8)
	for k in 4:
		var y := 0.4 + ph * (0.2 + 0.2 * float(k))
		var rr := hw * 0.9 * (1.0 - (y - 0.4) / ph)
		for q in 4:
			var a := PI * 0.5 * float(q) + PI * 0.25 * float(k % 2)
			SEuUtil.blob(lm, "Marble", tb + Vector3(cos(a) * (rr + 0.1), y, sin(a) * (rr + 0.1)), 0.14, 0.18, 0.14,
				Vector3.ZERO, false, 3, 6)
	SEuUtil.finial(lm, "Gold", tb + Vector3(0, 0.4 + ph, 0), 1.0)

## North (+X, sgn 1) or south flank: blind arcade of columns and arches
## on the lower storey, lunettes with statues on the upper.
static func _flank(lm: LandmarkMesh, sgn: float) -> void:
	var out := Vector3(sgn, 0, 0)
	var x := 25.6 * sgn
	var right := Vector3(0, 0, -sgn)
	for i in 5:
		var zc := -16.8 + 8.4 * float(i)
		var o := Vector3(x, 0, zc)
		LandmarkItlParts.gothic_window(lm, "Pink", "Shadow", o + Vector3(0, 0.4, 0), out, 4.2, 9.0, 1, false, 0.3, 0.4)
		for s in [-1.0, 1.0]:
			LandmarkItlParts.column(lm, "Col", o + right * float(s) * 2.9 + out * 0.45 + Vector3(0, 0.4, 0), 0.24, 6.6, 8)
		if i == 2:
			LandmarkItlParts.gothic_window(lm, "Pink", "Shadow", o + Vector3(0, 15.4, 0), out, 3.6, 4.6, 2, false, 0.2)
	lm.box("Pink", out * 25.8 + Vector3(0, 12.4, 0), Vector3(0.3, 0.8, 51.2))
	lm.box("Pink", out * 25.75 + Vector3(0, 0.2, 0), Vector3(0.3, 0.4, 51.2))
	# Narthex flank: two arches with gold lunettes, statues over them.
	for zc in [28.6, 34.2]:
		var p := Vector3(25.9 * sgn, 0, float(zc))
		LandmarkItlParts.gothic_window(lm, "Pink", "Shadow", p + Vector3(0, 0.4, 0), out, 4.0, 10.0, 1, false, 0.3, 0.4)
		LandmarkItlUtil.lunette(lm, "Gold", p + out * 0.05 + Vector3(0, 8.4, 0), right, 3.8)
		LandmarkKits.statue_figure(lm, "Gold", p + Vector3(0, TERRACE_Y, 0) - out * 0.6, 2.0)

## A gilt horse of the quadriga, 3.2 m to the ears, facing +Z.
static func _horse(lm: LandmarkMesh, b: Vector3) -> void:
	SEuUtil.blob(lm, "Gold", b + Vector3(0, 1.5, 0), 0.45, 0.55, 1.0, Vector3.ZERO, false, 6, 12)
	lm.beam("Gold", b + Vector3(0, 1.9, 0.7), b + Vector3(0, 2.8, 1.2), 0.38)
	lm.box("Gold", b + Vector3(0, 2.95, 1.5), Vector3(0.3, 0.32, 0.75))
	for sx in [-0.22, 0.22]:
		lm.beam("Gold", b + Vector3(sx, 1.2, -0.55), b + Vector3(sx, 0, -0.65), 0.15)
		lm.beam("Gold", b + Vector3(sx, 1.2, 0.55), b + Vector3(sx, 1.8, 1.2), 0.15)
		lm.beam("Gold", b + Vector3(sx, 2.95, 1.25), b + Vector3(sx * 0.6, 3.25, 1.15), 0.08)
	lm.beam("Gold", b + Vector3(0, 1.6, -0.95), b + Vector3(0, 0.7, -1.2), 0.12)
