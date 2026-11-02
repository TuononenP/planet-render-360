class_name LandmarkItlVenice
extends RefCounted

## St Mark's Basilica and the Bridge of Sighs in true metres: the
## Byzantine five-domed church of the Piazza San Marco and the enclosed
## Baroque limestone bridge over the Rio di Palazzo.

# --- St Mark's Basilica ---------------------------------------------------

const FACADE_Z := 37.0
const ARM := 19.2
const ROOF_Y := 21.0
const TERRACE_Y := 14.0

## Origin under the central dome, the Piazza facade facing +Z. A Greek
## cross of five domes: the lower mass of 12.8 m arms with lower corner
## chapels and the apse, the 52 m wide narthex in front, and the five-
## portal facade: round arches with gold mosaic lunettes between two tiers
## of marble columns, the terrace with the four gilt horses, the upper
## tier of five arches (blue starred lunette in the centre) under
## crocketed gables with statues, and above all the five onion domes
## sheathed in lead on pierced drums, the central one 43 m to its cross.
static func basilica(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#E4DACA", 3.0))
	lm.use("Pink", LandmarkMaterials.pbr("limestone", "#CFA997", 3.0))
	lm.use("Lead", LandmarkMaterials.pbr("concrete", "#8E9496", 2.0, 0.45, 0.35))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.use("Blue", LandmarkMaterials.paint("#26437F", 0.5, 0.1))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#3E362E", 3.0))
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
		var out := Vector3(sgn, 0, 0)
		SEuUtil.face_row(lm, "Shadow", out * 25.64, Vector3(0, 0, 1), out, 3.0, 5, 8.4, 3.0, 9.0)
		SEuUtil.face_row(lm, "Shadow", out * 25.64, Vector3(0, 0, 1), out, 15.0, 3, 8.4, 2.6, 4.4)
		lm.box("Pink", out * 25.8 + Vector3(0, 12.4, 0), Vector3(0.3, 0.8, 51.2))
	# The five domes: central, then west, east, north and south arms.
	_dome(lm, Vector3.ZERO, 5.8, 5.5, 10.5, 3.5, 2.5)
	for p in [Vector3(0, 0, ARM), Vector3(0, 0, -ARM), Vector3(ARM, 0, 0), Vector3(-ARM, 0, 0)]:
		_dome(lm, p, 5.2, 4.5, 9.0, 3.0, 2.2)
	_facade(lm)
	lm.commit(model)

## A dome: pierced drum, onion shell of lead, columned lantern, finial.
static func _dome(lm: LandmarkMesh, c: Vector3, r: float, drum_h: float, shell_h: float, lantern_h: float,
		finial_h: float) -> void:
	var base := Vector3(c.x, ROOF_Y, c.z)
	lm.frustum("Marble", base, r, r, drum_h, 16)
	SEuUtil.ring_openings(lm, "Shadow", base, r, 16, 16, 1.0, 1.2, drum_h - 2.0, false)
	lm.frustum("Pink", base + Vector3(0, drum_h - 0.5, 0), r * 1.05, r * 1.05, 0.5, 16)
	var top := base + Vector3(0, drum_h, 0)
	lm.lathe("Lead", top, LandmarkItlUtil.bulb(r, shell_h), 24)
	var lan := top + Vector3(0, shell_h, 0)
	lm.frustum("Marble", lan, r * 0.2, r * 0.17, lantern_h * 0.75, 8)
	lm.lathe("Gold", lan + Vector3(0, lantern_h * 0.75, 0), SEuUtil.dome(r * 0.22, lantern_h * 0.25, 4), 8)
	SEuUtil.finial(lm, "Gold", lan + Vector3(0, lantern_h, 0), finial_h)

## The west facade on the Piazza: two tiers, terrace, gables, horses.
static func _facade(lm: LandmarkMesh) -> void:
	var z := FACADE_Z
	var xs := [-20.8, -10.4, 0.0, 10.4, 20.8]
	var ws := [8.0, 8.0, 9.6, 8.0, 8.0]
	var hs := [10.2, 10.2, 12.0, 10.2, 10.2]
	for i in 5:
		var x: float = xs[i]
		var w: float = ws[i]
		var h: float = hs[i]
		var spring := h - w * 0.5
		lm.quad("Shadow", Vector3(x - w * 0.5, 0, z + 0.06), Vector3(x + w * 0.5, 0, z + 0.06),
			Vector3(x + w * 0.5, spring, z + 0.06), Vector3(x - w * 0.5, spring, z + 0.06), Vector3(0, 0, 1))
		SEuUtil.opening(lm, "Gold", Vector3(x, spring, z + 0.08), Vector3.RIGHT, Vector3.UP, w, w * 0.5)
	# Marble columns on the piers, two tiers, and the entablature.
	for x in [-25.35, -15.6, -5.6, 5.6, 15.6, 25.35]:
		lm.frustum("Pink", Vector3(x, 0, z + 0.5), 0.5, 0.42, 6.4, 10)
		lm.frustum("Pink", Vector3(x, 6.4, z + 0.5), 0.44, 0.38, 6.4, 10)
	lm.box("Marble", Vector3(0, 13.3, z + 0.3), Vector3(52.6, 1.4, 1.6))
	# Terrace, balustrade and the four horses.
	lm.box("Marble", Vector3(0, TERRACE_Y + 0.55, z - 0.3), Vector3(51.6, 1.1, 0.5))
	for x in [-4.2, -1.4, 1.4, 4.2]:
		_horse(lm, Vector3(x, TERRACE_Y, 35.0))
	# Upper tier set back behind the terrace.
	var uz := 33.5
	lm.box("Marble", Vector3(0, 20.1, uz - 1.25), Vector3(51.8, 12.2, 2.5))
	lm.box("Pink", Vector3(0, 26.7, uz - 0.7), Vector3(52.6, 1.0, 1.6))
	for i in 5:
		var x: float = xs[i]
		var w: float = 9.8 if i == 2 else 8.6
		var top: float = 21.0 if i == 2 else 20.0
		lm.quad("Shadow", Vector3(x - w * 0.5, TERRACE_Y, uz + 0.06), Vector3(x + w * 0.5, TERRACE_Y, uz + 0.06),
			Vector3(x + w * 0.5, top, uz + 0.06), Vector3(x - w * 0.5, top, uz + 0.06), Vector3(0, 0, 1))
		SEuUtil.opening(lm, "Blue" if i == 2 else "Gold", Vector3(x, top, uz + 0.08), Vector3.RIGHT, Vector3.UP, w, w * 0.5)
		var rise := 7.0 if i == 2 else 5.0
		lm.gable("Pink", Vector3(x, 27.2, uz), w + 1.2, 0.9, rise, Basis(), 0.0, "Pink")
		LandmarkKits.statue_figure(lm, "Gold", Vector3(x, 27.2 + rise, uz), 3.4 if i == 2 else 2.4)
	for k in 6:
		var a := PI * (0.12 + 0.76 * float(k) / 5.0)
		lm.disc("Gold", Vector3(cos(a) * 3.8, 21.0 + sin(a) * 3.8, uz + 0.1), Vector3(0, 0, 1), 0.3, 8)
	lm.box("Gold", Vector3(0, 22.6, uz + 0.14), Vector3(1.8, 1.1, 0.25))
	lm.box("Gold", Vector3(0, 23.5, uz + 0.14), Vector3(3.4, 0.5, 0.25))
	for sx in [-1.0, 1.0]:
		lm.box("Marble", Vector3(sx * 25.3, 30.0, uz), Vector3(1.4, 7.0, 1.4))
		lm.spire("Marble", Vector3(sx * 25.3, 33.5, uz), 0.9, 3.5)

## A gilt horse of the quadriga, 3.2 m to the ears, facing +Z.
static func _horse(lm: LandmarkMesh, b: Vector3) -> void:
	SEuUtil.blob(lm, "Gold", b + Vector3(0, 1.5, 0), 0.45, 0.55, 1.0, Vector3.ZERO, false, 5, 10)
	lm.beam("Gold", b + Vector3(0, 1.9, 0.7), b + Vector3(0, 2.8, 1.2), 0.38)
	lm.box("Gold", b + Vector3(0, 2.95, 1.5), Vector3(0.3, 0.32, 0.75))
	for sx in [-0.22, 0.22]:
		lm.beam("Gold", b + Vector3(sx, 1.2, -0.55), b + Vector3(sx, 0, -0.65), 0.15)
		lm.beam("Gold", b + Vector3(sx, 1.2, 0.55), b + Vector3(sx, 1.8, 1.2), 0.15)

# --- Bridge of Sighs --------------------------------------------------------

## Built along +X (the palace at -X, the New Prison at +X), water at y=0:
## the enclosed limestone passage 10 m long, 3.8 m wide on a flattened
## arch over the 6.8 m Rio di Palazzo, with its heavy cornice, two stone-
## latticed windows a side under little pediments and a shallow lead roof,
## entering the palace wall (pink Verona marble) and the prison (Istrian
## stone) either side.
static func bridge_of_sighs(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#EAE3D3", 2.5))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#F2EDE0", 2.0))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#3E362E", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("slate", "#8A8E8F", 2.0))
	lm.use("Pink", LandmarkMaterials.pbr("limestone", "#E2CFC3", 3.0))
	lm.use("Grey", LandmarkMaterials.pbr("limestone", "#CFC8B8", 3.0))
	lm.box("Stone", Vector3(0, 8.7, 0), Vector3(10.0, 3.4, 3.8))
	lm.box("Trim", Vector3(0, 7.2, 0), Vector3(10.4, 0.4, 4.2))
	lm.box("Trim", Vector3(0, 10.6, 0), Vector3(10.8, 0.5, 4.4))
	lm.gable("Roof", Vector3(0, 10.85, 0), 3.8, 10.4, 1.0, Basis(Vector3.UP, PI * 0.5), 0.2, "Stone")
	for sgn in [-1.0, 1.0]:
		var out := Vector3(0, 0, sgn)
		SEuUtil.face_row(lm, "Shadow", out * 1.9, Vector3.RIGHT, out, 7.9, 2, 4.4, 1.5, 2.0)
		for x in [-2.2, 2.2]:
			var z: float = sgn * 2.0
			lm.lattice_panel("Trim", Vector3(x - 0.75, 7.9, z), Vector3(x + 0.75, 7.9, z), Vector3(x - 0.75, 9.9, z),
				Vector3(x + 0.75, 9.9, z), 0.09, 3, true)
			lm.gable("Trim", Vector3(x, 9.95, sgn * 1.95), 1.9, 0.3, 0.5, Basis(), 0.0, "Trim")
			# Window surround: jambs and sill.
			for jx in [-0.85, 0.85]:
				lm.box("Trim", Vector3(x + jx, 8.9, sgn * 1.97), Vector3(0.25, 2.2, 0.16))
			lm.box("Trim", Vector3(x, 7.78, sgn * 2.0), Vector3(1.9, 0.22, 0.3))
	# Flattened arch under the passage with its spandrels.
	var prev := Vector2(-3.4, 5.0)
	for k in range(1, 11):
		var t := float(k) / 10.0
		var p := Vector2(-3.4 + 6.8 * t, 5.0 + 1.3 * sin(PI * t))
		var d := p - prev
		var n := Vector3(d.y, -d.x, 0).normalized()
		lm.quad("Stone", Vector3(prev.x, prev.y, -1.9), Vector3(p.x, p.y, -1.9), Vector3(p.x, p.y, 1.9),
			Vector3(prev.x, prev.y, 1.9), n)
		for zz in [-1.9, 1.9]:
			lm.quad("Stone", Vector3(prev.x, prev.y, zz), Vector3(p.x, p.y, zz), Vector3(p.x, 7.0, zz),
				Vector3(prev.x, 7.0, zz), Vector3(0, 0, signf(zz)))
		prev = p
	# The palace wall and the prison wall either side of the canal.
	lm.box("Pink", Vector3(-7.9, 5.5, 0), Vector3(9.0, 11.0, 14.0))
	lm.box("Grey", Vector3(7.4, 4.9, 0), Vector3(8.0, 9.8, 14.0))
	SEuUtil.face_row(lm, "Shadow", Vector3(-3.44, 0, 0), Vector3(0, 0, -1), Vector3(1, 0, 0), 1.5, 3, 4.4, 1.6, 4.0, true)
	SEuUtil.face_row(lm, "Shadow", Vector3(-3.44, 0, 0), Vector3(0, 0, -1), Vector3(1, 0, 0), 8.6, 2, 7.6, 1.3, 2.6, true)
	SEuUtil.face_row(lm, "Shadow", Vector3(3.44, 0, 0), Vector3(0, 0, 1), Vector3(-1, 0, 0), 1.5, 3, 4.4, 1.2, 3.0)
	SEuUtil.face_row(lm, "Shadow", Vector3(3.44, 0, 0), Vector3(0, 0, 1), Vector3(-1, 0, 0), 4.6, 3, 4.4, 1.0, 1.6)
	lm.commit(model)
