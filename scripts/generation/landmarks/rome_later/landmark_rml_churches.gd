class_name LandmarkRmLChurches
extends RefCounted

## The Gesù and Sant'Ivo alla Sapienza in true metres.

# --- Il Gesù -----------------------------------------------------------

## Origin at the middle of the church (75 x 35 m), facade facing +Z
## (west onto Piazza del Gesù; yaw_deg turns it): Della Porta's
## two-storey travertine facade (1571-77) of paired Corinthian
## pilasters, six pairs below and four above, the central portal with
## engaged columns under a segmental pediment set in a triangular one,
## side doors, statue niches, the upper window with its balcony, the
## great scroll volutes and the crowning pediment; behind it the nave
## (three chapels a side under lean-to roofs, lunette windows over
## them), the transept, apse and Vignola's drum, ribbed dome and lantern
## over the crossing (52.5 m).
static func gesu(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#D2C2A0", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#E6DBC2", 2.0))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#4A4136", 3.0))
	lm.use("Plaster", LandmarkMaterials.pbr("render", "#C79F6E", 4.0))
	lm.use("Tile", LandmarkMaterials.pbr("terracotta", "#A65A3E", 2.0))
	lm.use("Dome", LandmarkMaterials.pbr("concrete", "#8E9291", 3.0, 0.55, 0.3))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.box("Plaster", Vector3(0, 13.5, -1.5), Vector3(21.2, 27.0, 69.0))
	lm.gable("Tile", Vector3(0, 27.0, -1.5), 21.2, 69.0, 5.0, Basis(), 0.5, "Plaster")
	LandmarkDetail.cornice(lm, "Trim", Vector3(-10.6, 26.2, 33.0), Vector3(-10.6, 26.2, -36.0), Vector3(-1, 0, 0), 0.8, false)
	LandmarkDetail.cornice(lm, "Trim", Vector3(10.6, 26.2, 33.0), Vector3(10.6, 26.2, -36.0), Vector3(1, 0, 0), 0.8, false)
	for s in [-1.0, 1.0]:
		# Chapels with lean-to roofs, their windows, and the nave lunettes.
		lm.box("Plaster", Vector3(s * 13.9, 7.5, 1.5), Vector3(6.6, 15.0, 63.0))
		lm.box("Trim", Vector3(s * 13.9, 15.3, 1.5), Vector3(7.4, 0.6, 64.0))
		lm.quad("Tile", Vector3(s * 17.6, 15.6, 33.0), Vector3(s * 17.6, 15.6, -30.0),
			Vector3(s * 10.6, 18.4, -30.0), Vector3(s * 10.6, 18.4, 33.0), Vector3(s * 0.4, 1.0, 0).normalized())
		for i in 3:
			var z := 22.0 - 13.0 * float(i)
			var n := Vector3(s, 0, 0)
			var lr := Vector3.UP.cross(n)
			LandmarkRmLKit.arcade(lm, "Plaster", "Shadow", Vector3(s * 10.6, 19.0, z) - lr * 3.2, lr, n, 6.4, 6.0, 1, 4.4,
				1.0, 0.3)
			var co := Vector3(s * 17.2, 0, z)
			lm.box("Shadow", co + Vector3(0, 7.5, 0) + n * 0.05, Vector3(0.1, 4.6, 2.0), Basis(), 0.0)
			LandmarkRmLKit.frame_opening(lm, "Trim", co + Vector3(0, 5.2, 0) + n * 0.1, Vector3.UP.cross(n), n, 2.0, 4.6, 0)
			lm.box("Trim", co + Vector3(0, 7.5, 0) + Vector3(0, 0, 6.5) + n * 0.3, Vector3(0.6, 15.0, 1.0))
	# Transept and apse.
	lm.box("Plaster", Vector3(0, 14.0, -15.0), Vector3(41.0, 28.0, 22.0))
	lm.gable("Tile", Vector3(0, 28.0, -15.0), 22.0, 41.0, 4.0, Basis(Vector3.UP, PI * 0.5), 0.5, "Plaster")
	for s in [-1.0, 1.0]:
		var n := Vector3(s, 0, 0)
		LandmarkRmLKit.pilaster_row(lm, "Trim", Vector3(s * 20.5, 0, -24.5), Vector3(0, 0, 1), n, 19.0, 4, 1.2, 27.0, 0.4)
		lm.box("Shadow", Vector3(s * 20.55, 18.0, -15.0), Vector3(0.1, 6.0, 3.6), Basis(), 0.0)
		LandmarkRmLKit.frame_opening(lm, "Trim", Vector3(s * 20.6, 15.0, -15.0), Vector3.UP.cross(n), n, 3.6, 6.0, 1)
	lm.frustum("Plaster", Vector3(0, 0, -36.0), 10.6, 10.6, 24.0, 24)
	lm.lathe("Tile", Vector3(0, 24.0, -36.0), SEuUtil.dome(10.8, 4.0, 5), 24)
	for k in 7:
		var a := PI * 0.2 + PI * 0.6 * float(k) / 6.0
		var d := Vector3(cos(a), 0, -sin(a))
		LandmarkRmLKit.pilaster(lm, "Trim", Vector3(0, 0, -36.0) + d * 10.5, Vector3.UP.cross(d), d, 1.0, 23.0, 0.4)
	_gesu_facade(lm)
	LandmarkRmLUtil.dome_stack(lm, Vector3(0, 28.0, -15.0), 8.6, 7.5, 8.5, 5.0, 24.5, 8, 16)
	lm.commit(model)

## Della Porta's facade: lower order 34.4 m wide at z = 37, the upper
## 21.2 m wide at z = 36; 15 m and 13 m tall, pediment to 34.6 m.
static func _gesu_facade(lm: LandmarkMesh) -> void:
	var n := Vector3(0, 0, 1)
	var r := Vector3.RIGHT
	lm.box("Stone", Vector3(0, 7.5, 35.0), Vector3(34.4, 15.0, 4.0))
	lm.box("Stone", Vector3(0, 21.5, 34.5), Vector3(21.2, 13.0, 3.0))
	# Central bay steps forward; plinth.
	lm.box("Stone", Vector3(0, 7.5, 37.3), Vector3(12.0, 15.0, 0.6))
	lm.box("Stone", Vector3(0, 21.5, 36.3), Vector3(9.0, 13.0, 0.6))
	lm.box("Trim", Vector3(0, 0.6, 37.3), Vector3(35.0, 1.2, 0.8))
	# Lower order: paired pilasters, engaged columns at the portal.
	for s in [-1.0, 1.0]:
		for x in [16.6, 14.6, 9.2, 7.2]:
			LandmarkRmLKit.pilaster(lm, "Trim", Vector3(s * float(x), 1.2, 37.0), r, n, 1.1, 12.8, 0.5)
		for x in [5.0, 3.4]:
			LandmarkDetail.column(lm, "Trim", Vector3(s * float(x), 1.2, 38.2), 0.55, 12.8, "corinthian", 0)
	LandmarkRmLKit.entablature(lm, "Trim", Vector3(-17.4, 14.0, 37.0), Vector3(17.4, 14.0, 37.0), n, 1.8, 0.6, true)
	LandmarkRmLKit.entablature(lm, "Trim", Vector3(-6.0, 14.0, 37.6), Vector3(6.0, 14.0, 37.6), n, 1.8, 0.8, true)
	# Portal: door, frame, segmental pediment inside a triangular one.
	lm.box("Shadow", Vector3(0, 4.9, 37.65), Vector3(3.6, 7.4, 0.1), Basis(), 0.0)
	LandmarkRmLKit.frame_opening(lm, "Trim", Vector3(0, 1.2, 37.7), r, n, 3.6, 7.4, 4)
	LandmarkRmLKit.pediment(lm, "Trim", Vector3(0, 10.4, 37.7), r, n, 9.4, 2.4, 1.0, true)
	for s in [-1.0, 1.0]:
		# Side doors, niches with statues above them and between pairs.
		var sx := float(s) * 11.9
		lm.box("Shadow", Vector3(sx, 4.2, 37.05), Vector3(2.4, 6.0, 0.1), Basis(), 0.0)
		LandmarkRmLKit.frame_opening(lm, "Trim", Vector3(sx, 1.2, 37.1), r, n, 2.4, 6.0, 1)
		# Statue niche over the side door.
		var o := Vector3(sx - 1.0, 8.2, 36.6)
		LandmarkRmLKit.arcade(lm, "Stone", "Shadow", o, r, n, 2.0, 4.6, 1, 1.5, 2.6, 0.4)
		LandmarkKits.statue_figure(lm, "Trim", o + Vector3(1.0, 0.2, 0.1), 2.8)
	# Upper order: paired pilasters, window with balcony, niches.
	lm.box("Stone", Vector3(0, 16.0, 35.6), Vector3(21.2, 2.0, 2.4))
	for s in [-1.0, 1.0]:
		for x in [10.0, 8.0, 4.2, 2.6]:
			LandmarkRmLKit.pilaster(lm, "Trim", Vector3(s * float(x), 17.0, 36.0 if float(x) > 5.0 else 36.6), r, n, 0.9, 10.4, 0.45)
		var o := Vector3(s * 6.1 - 0.9, 18.6, 36.0)
		LandmarkRmLKit.arcade(lm, "Stone", "Shadow", o - n * 0.4, r, n, 1.8, 4.6, 1, 1.3, 2.6, 0.4)
		LandmarkKits.statue_figure(lm, "Trim", o + Vector3(0.9, 0.2, -0.1), 2.6)
		# Great volute: an S-scroll from the outer pilaster down to the
		# lower cornice, with a spiral eye at its foot.
		_volute(lm, "Stone", Vector3(s * 10.6, 26.8, 35.2), Vector3(s * 16.6, 16.2, 35.2), n)
	LandmarkRmLKit.entablature(lm, "Trim", Vector3(-10.9, 27.4, 36.0), Vector3(10.9, 27.4, 36.0), n, 1.6, 0.6, true)
	lm.box("Shadow", Vector3(0, 21.6, 36.65), Vector3(3.0, 5.4, 0.1), Basis(), 0.0)
	LandmarkRmLKit.frame_opening(lm, "Trim", Vector3(0, 18.9, 36.7), r, n, 3.0, 5.4, 1)
	LandmarkRmLKit.balustrade(lm, "Trim", Vector3(-2.6, 17.2, 37.6), Vector3(2.6, 17.2, 37.6), 1.0, 2.6)
	LandmarkRmLKit.pediment(lm, "Trim", Vector3(0, 29.0, 35.3), r, n, 22.6, 5.0, 1.3, true)
	lm.disc("Trim", Vector3(0, 30.9, 36.65), n, 1.2, 16)
	SEuUtil.steps_up(lm, "Trim", Vector3(0, 0, 38.0), Vector3(0, 0, 1), 20.0, 0.6, 0.25, 3)

## Scroll volute along a (top, inner) to b (foot, outer) on a face
## facing n: a curved band with a spiral eye at the foot.
static func _volute(lm: LandmarkMesh, key: String, a: Vector3, b: Vector3, n: Vector3) -> void:
	var prev := a
	for i in 12:
		var t := float(i + 1) / 12.0
		var p := a.lerp(b, t) + Vector3(0, sin(t * PI) * 1.4, 0) + (b - a).cross(n).normalized() * 0.0
		lm.beam(key, prev, p, 1.4, 1.2, n)
		prev = p
	var eye := b + Vector3(0, 1.0, 0)
	var q := b
	for i in 14:
		var t := float(i + 1) / 14.0
		var ang := -PI * 0.5 + t * TAU * 1.2
		var rr := 1.0 * (1.0 - t * 0.7)
		var p := eye + Vector3(cos(ang) * rr * signf(b.x - a.x), sin(ang) * rr, 0) + n * 0.2
		lm.beam(key, q, p, 0.4, 1.0, n)
		q = p
	lm.box(key, b + Vector3(0, 0.25, 0), Vector3(2.6, 0.5, 1.6))

# --- Sant'Ivo alla Sapienza --------------------------------------------

## Origin at the dome axis of Borromini's church (1642-60, 27 x 26 m on
## a six-lobed star plan); the concave facade faces +Z and closes the
## east end of Della Porta's courtyard of the Palazzo della Sapienza,
## whose two storeys of arcades run round the other three sides and
## continue across the church front. Over the concave front rises the
## convex six-lobed drum with paired pilasters, the stepped dome with
## its buttress ribs, the lantern of six concave bays with paired
## columns and torch flames, and the spiral ending in an iron crown,
## orb and cross (58 m).
static func ivo(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#CDBA96", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#E4D8BE", 2.0))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#4A4136", 3.0))
	lm.use("Plaster", LandmarkMaterials.pbr("render", "#BE9266", 4.0))
	lm.use("Dome", LandmarkMaterials.pbr("concrete", "#8E9291", 3.0, 0.55, 0.3))
	lm.use("Iron", LandmarkMaterials.paint("#2C2C2C", 0.6, 0.5))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.use("Tile", LandmarkMaterials.pbr("terracotta", "#A65A3E", 2.0))
	lm.box("Stone", Vector3(0, 13.0, -3.0), Vector3(27.0, 26.0, 24.0))
	for s in [-1.0, 1.0]:
		lm.box("Stone", Vector3(s * 11.25, 9.0, 12.0), Vector3(4.5, 18.0, 4.0))
		# Palazzo ranges beside the church and round the court.
		LandmarkRmLUtil.block(lm, "Plaster", Vector3(s * 18.75, 0, -0.5), 29.0, 22.0, 10.5, Vector3(s, 0, 0), 3, 6,
			1.3, 2.3, "Tile")
		LandmarkRmLUtil.block(lm, "Plaster", Vector3(s * 19.0, 0, 34.0), 40.0, 22.0, 10.0, Vector3(-s, 0, 0), 3, 8,
			2.6, 4.6, "Tile")
		# Two-storey arcades down the long sides of the court.
		var n := Vector3(-s, 0, 0)
		var r := Vector3.UP.cross(n)
		var o := Vector3(s * 14.0, 0, 34.0) - r * 20.0
		_court_arcade(lm, o, r, n, 40.0, 8)
	LandmarkRmLUtil.block(lm, "Plaster", Vector3(0, 0, 56.0), 48.0, 22.0, 8.0, Vector3(0, 0, -1), 3, 9, 2.6, 4.6, "Tile")
	_court_arcade(lm, Vector3(14.0, 0, 52.0), Vector3(-1, 0, 0), Vector3(0, 0, -1), 28.0, 5)
	_ivo_facade(lm)
	_ivo_dome(lm)
	lm.commit(model)

## Della Porta's court arcade: an open ground-floor arcade and the
## arched loggia over it (each storey 8.6 m) on Doric and Ionic
## pilasters, `bays` bays over w, 3 m deep in front of the wall at o.
static func _court_arcade(lm: LandmarkMesh, o: Vector3, r: Vector3, n: Vector3, w: float, bays: int) -> void:
	for f in 2:
		var y := 8.6 * float(f)
		var fo := o + Vector3(0, y, 0)
		LandmarkRmLKit.arcade(lm, "Stone", "Shadow", fo, r, n, w, 8.6, bays, 3.0, 4.6 if f == 0 else 4.2, 3.0,
			0.0 if f == 0 else 1.0)
		LandmarkRmLKit.archivolts(lm, "Trim", fo, r, n, w, bays, 3.0, 4.6 if f == 0 else 4.2, 3.0, 0.3)
		LandmarkRmLKit.pilaster_row(lm, "Trim", fo + n * 3.0, r, n, w, bays + 1, 0.8, 8.0, 0.35, true)
		lm.box("Trim", fo + r * w * 0.5 + n * 3.2 + Vector3(0, 8.3, 0), Vector3(w, 0.6, 0.6) if absf(r.x) > 0.5 else Vector3(0.6, 0.6, w))
		if f == 1:
			LandmarkRmLKit.balustrade(lm, "Trim", fo + n * 3.2 + Vector3(0, 0.2, 0), fo + n * 3.2 + r * w + Vector3(0, 0.2, 0), 1.0, w / float(bays))
	lm.box("Tile", o + r * w * 0.5 + n * 1.5 + Vector3(0, 17.25, 0), Vector3(w, 0.5, 3.2) if absf(r.x) > 0.5 else Vector3(3.2, 0.5, w))

## The concave church front on an 11 m arc: two storeys continuing the
## court arcades, pilasters with capitals, a curved entablature and a
## balustraded attic.
static func _ivo_facade(lm: LandmarkMesh) -> void:
	var prev := Vector3.ZERO
	for i in 9:
		var x := -9.0 + 2.25 * float(i)
		var p := Vector3(x, 0, 21.5 - sqrt(121.0 - x * x))
		var n := Vector3(-x, 0, 21.5 - p.z).normalized()
		var rr := Vector3.UP.cross(n)
		LandmarkRmLKit.pilaster(lm, "Trim", p + n * 1.0, rr, n, 0.9, 8.4, 0.5)
		LandmarkRmLKit.pilaster(lm, "Trim", p + n * 1.0 + Vector3(0, 8.6, 0), rr, n, 0.8, 8.4, 0.45)
		if i > 0:
			var pn := Vector3(-prev.x, 0, 21.5 - prev.z).normalized()
			lm.beam("Stone", prev + Vector3(0, 9.0, 0), p + Vector3(0, 9.0, 0), 18.0, 2.0, Vector3.UP)
			for y in [8.4, 17.0]:
				lm.beam("Trim", prev + Vector3(0, float(y) + 0.4, 0) + pn * 0.5, p + Vector3(0, float(y) + 0.4, 0) + n * 0.5,
					0.8, 1.6, Vector3.UP)
			lm.beam("Stone", prev + Vector3(0, 19.4, 0), p + Vector3(0, 19.4, 0), 2.2, 1.6, Vector3.UP)
			LandmarkRmLKit.balustrade(lm, "Trim", prev + Vector3(0, 20.5, 0) + pn * 0.4, p + Vector3(0, 20.5, 0) + n * 0.4, 1.0, 2.3)
			var mid := (prev + p) * 0.5
			var mn := Vector3(-mid.x, 0, 21.5 - mid.z).normalized()
			var mr := Vector3.UP.cross(mn)
			var b := Basis(mr, Vector3.UP, mn)
			var door := i == 4 or i == 5
			var wh := 5.6 if door else 3.2
			var wy := 0.4 if door else 2.4
			lm.box("Shadow", mid + mn * 1.05 + Vector3(0, wy + wh * 0.5, 0), Vector3(1.4, wh, 0.1), b, 0.0)
			LandmarkRmLKit.frame_opening(lm, "Trim", mid + mn * 1.1 + Vector3(0, wy, 0), mr, mn, 1.4, wh, 1 if door else 0)
			lm.box("Shadow", mid + mn * 1.05 + Vector3(0, 12.4, 0), Vector3(1.3, 3.4, 0.1), b, 0.0)
			LandmarkRmLKit.frame_opening(lm, "Trim", mid + mn * 1.1 + Vector3(0, 10.7, 0), mr, mn, 1.3, 3.4, 4 if i % 2 == 0 else 1)
		prev = p

## Six-lobed drum, stepped dome with buttress ribs, lantern of six
## concave bays, the spiral and the crown.
static func _ivo_dome(lm: LandmarkMesh) -> void:
	var c := Vector3(0, 0, -1.0)
	var poly := PackedVector2Array()
	for k in 72:
		var a := TAU * float(k) / 72.0
		var rr := 8.2 + 0.6 * absf(cos(3.0 * a))
		poly.append(Vector2(c.x + cos(a) * rr, c.z + sin(a) * rr))
	lm.poly_prism("Stone", poly, 18.0, 28.0)
	for k in 6:
		var a := TAU * (float(k) + 0.5) / 6.0
		var d := Vector3(cos(a), 0, sin(a))
		var a2 := TAU * float(k) / 6.0
		var d2 := Vector3(cos(a2), 0, sin(a2))
		for s in [-0.6, 0.6]:
			LandmarkRmLKit.pilaster(lm, "Trim", c + d * 8.25 + Vector3.UP.cross(d) * float(s) + Vector3(0, 18.0, 0),
				Vector3.UP.cross(d), d, 0.7, 9.6, 0.4)
		var wb := Basis(Vector3.UP.cross(d2), Vector3.UP, d2)
		lm.box("Shadow", c + d2 * 8.85 + Vector3(0, 23.0, 0), Vector3(1.8, 3.8, 0.1), wb, 0.0)
		LandmarkRmLKit.frame_opening(lm, "Trim", c + d2 * 8.9 + Vector3(0, 21.1, 0), Vector3.UP.cross(d2), d2, 1.8, 3.8, 4)
	lm.frustum("Trim", c + Vector3(0, 28.0, 0), 9.4, 9.4, 0.9, 36)
	var steps := PackedVector2Array([Vector2(8.4, 0.0), Vector2(8.4, 1.2), Vector2(7.5, 1.2),
		Vector2(7.5, 2.6), Vector2(6.5, 2.6), Vector2(6.5, 4.0), Vector2(5.5, 4.0), Vector2(5.5, 5.4),
		Vector2(4.5, 5.4), Vector2(4.5, 6.8), Vector2(3.8, 6.8)])
	lm.lathe("Dome", c + Vector3(0, 28.9, 0), steps, 36, 1.0, 1.0, 0.0, false)
	# Buttress ribs climbing the steps (the "sugar loaf" ribs).
	for k in 6:
		var a := TAU * (float(k) + 0.5) / 6.0
		var d := Vector3(cos(a), 0, sin(a))
		var rib := [Vector2(9.0, 0.0), Vector2(8.0, 1.6), Vector2(7.0, 3.0), Vector2(6.0, 4.4),
			Vector2(5.0, 5.8), Vector2(4.0, 6.8)]
		for j in rib.size() - 1:
			var q0: Vector2 = rib[j]
			var q1: Vector2 = rib[j + 1]
			lm.beam("Stone", c + d * q0.x + Vector3(0, 28.9 + q0.y, 0), c + d * q1.x + Vector3(0, 28.9 + q1.y, 0),
				0.7, 1.2, Vector3.UP.cross(d))
	# Lantern: six concave bays between paired columns.
	var lp := PackedVector2Array()
	for k in 48:
		var a := TAU * float(k) / 48.0
		var rr := 3.0 - 0.6 * absf(sin(3.0 * a))
		lp.append(Vector2(c.x + cos(a) * rr, c.z + sin(a) * rr))
	lm.poly_prism("Stone", lp, 35.7, 39.7)
	for k in 6:
		var a := TAU * float(k) / 6.0
		var d := Vector3(cos(a), 0, sin(a))
		for s in [-0.45, 0.45]:
			LandmarkRmLKit.column_lite(lm, "Trim", c + d * 3.3 + Vector3.UP.cross(d) * float(s) + Vector3(0, 35.7, 0),
				0.22, 4.0)
		# Torch flames on the cornice over each pair.
		lm.lathe("Trim", c + d * 3.3 + Vector3(0, 40.4, 0), PackedVector2Array([Vector2(0.3, 0.0),
			Vector2(0.45, 0.4), Vector2(0.2, 1.1), Vector2(0.0, 1.6)]), 8)
		var a2 := TAU * (float(k) + 0.5) / 6.0
		var d2 := Vector3(cos(a2), 0, sin(a2))
		lm.box("Shadow", c + d2 * 2.45 + Vector3(0, 37.6, 0), Vector3(1.1, 2.6, 0.1), Basis(Vector3.UP.cross(d2), Vector3.UP, d2), 0.0)
	lm.frustum("Trim", c + Vector3(0, 39.7, 0), 3.8, 3.8, 0.7, 24)
	lm.frustum("Stone", c + Vector3(0, 40.4, 0), 2.5, 2.1, 5.3, 16)
	# The spiral, three and a half turns to the crown.
	var q := Vector3.ZERO
	for k in 49:
		var t := float(k) / 48.0
		var a := 3.5 * TAU * t
		var r := lerpf(2.9, 0.5, t)
		var p := c + Vector3(cos(a) * r, 45.7 + 6.8 * t, sin(a) * r)
		if k > 0:
			lm.beam("Stone", q, p, lerpf(1.0, 0.45, t), 0.7)
		q = p
	# Iron crown of flames, orb and cross.
	var cr := c + Vector3(0, 52.5, 0)
	lm.frustum("Iron", cr, 0.9, 1.1, 0.4, 12)
	for k in 8:
		var a := TAU * float(k) / 8.0
		lm.beam("Iron", cr + Vector3(cos(a), 0.4, sin(a)) * 1.0, cr + Vector3(cos(a) * 1.3, 1.6, sin(a) * 1.3), 0.12, 0.12)
	lm.beam("Iron", cr, cr + Vector3(0, 2.0, 0), 0.2, 0.2)
	SEuUtil.finial(lm, "Gold", cr + Vector3(0, 2.0, 0), 3.5)
