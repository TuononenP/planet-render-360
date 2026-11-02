class_name LandmarkAtModern
extends RefCounted

## Neoclassical Athens in true metres: the Hellenic Parliament (Old
## Royal Palace), the Zappeion and the Academy of Athens.

## One storey band of real window openings on a mass face: a pierced
## skin with `cols` openings of `win` size, the sill `sill` above `o`
## (the bottom-left of the face, `right` along the wall), each with a
## projecting sill and a cornice head.
static func _storey(lm: LandmarkMesh, wall: String, trim: String, o: Vector3, right: Vector3,
		normal: Vector3, w: float, h: float, cols: int, win: Vector2, sill: float, head: bool = true) -> void:
	LandmarkDetail.pierced_face(lm, wall, "Glass", o, right, normal, w, h, cols, 1, win, sill, h, 0.3)
	var b := Basis(right, Vector3.UP, normal)
	var pitch := w / float(cols)
	for i in cols:
		var c := o + right * pitch * (float(i) + 0.5) + normal * 0.35
		lm.box(trim, c + Vector3(0, sill - 0.08, 0), Vector3(win.x + 0.4, 0.16, 0.25), b, 0.0)
		if head:
			lm.box(trim, c + Vector3(0, sill + win.y + 0.15, 0), Vector3(win.x + 0.5, 0.3, 0.3), b, 0.0)

# --- Hellenic Parliament ----------------------------------------------

## Origin at the middle of the palace, the Syntagma (west) front toward +Z
## (yaw_deg turns it west). Gärtner's Old Royal Palace of 1836-43: four
## outer wings, about 90 m on the east and west fronts and 80 m on the
## north and south, round two courtyards, raised 1.5 m on its plinth;
## the outer wings have three floors (7.16, 7.11 and 5.5 m), the central
## wing on the main axis a ground floor and one 14.2 m state storey under
## a pitched roof whose pediments face both fronts, projecting 0.58 m.
## The Doric entrance portico carries a balcony; sill bands, a dentil
## cornice and low tiled roofs over each wing. 24 m to the pediments.
static func parliament(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Rust", LandmarkMaterials.pbr("limestone", "#D2C09E", 4.0))
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#E3D7BD", 4.0))
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#ECE3D0", 3.0))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#4A4339", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("slate", "#6F7479", 3.0))
	lm.use("Glass", LandmarkMaterials.glass())
	var hx := 45.0
	var hz := 40.0
	var y0 := 1.5
	var eave := y0 + 7.16 + 7.11 + 5.5
	lm.box("Rust", Vector3(0, y0 * 0.5, 0), Vector3(hx * 2.0 + 1.0, y0, hz * 2.0 + 1.0))
	# Outer wings 18 m deep round the two courtyards, and the central wing.
	var wd := 18.0
	for s in [-1.0, 1.0]:
		lm.box("Stone", Vector3(0, (y0 + eave) * 0.5, s * (hz - wd * 0.5)), Vector3(hx * 2.0, eave - y0, wd))
		lm.box("Stone", Vector3(s * (hx - wd * 0.5), (y0 + eave) * 0.5, 0), Vector3(wd, eave - y0, hz * 2.0 - wd * 2.0))
	var ct := y0 + 7.16 + 14.2
	lm.box("Stone", Vector3(0, (y0 + ct) * 0.5, 0), Vector3(22.0, ct - y0, hz * 2.0 + 1.16))
	# Sill bands, the crowning cornice with dentils and the low roofs.
	for f in [y0 + 7.16, y0 + 14.27]:
		var y: float = f
		for s in [-1.0, 1.0]:
			lm.box("Marble", Vector3(0, y, s * (hz + 0.4)), Vector3(hx * 2.0 + 0.8, 0.35, 0.5))
			lm.box("Marble", Vector3(s * (hx + 0.4), y, 0), Vector3(0.5, 0.35, hz * 2.0 + 0.8))
	var corners := [Vector3(-hx, 0, hz), Vector3(hx, 0, hz), Vector3(hx, 0, -hz), Vector3(-hx, 0, -hz)]
	for i in 4:
		var a: Vector3 = corners[i]
		var b: Vector3 = corners[(i + 1) % 4]
		var out := (a + b).normalized()
		LandmarkDetail.cornice(lm, "Marble", a + Vector3(0, eave, 0) - (b - a).normalized() * 0.9 + out * 0.0,
			b + Vector3(0, eave, 0) + (b - a).normalized() * 0.9, out, 1.0)
	var rq := Basis(Vector3.UP, PI * 0.5)
	for s in [-1.0, 1.0]:
		lm.gable("Roof", Vector3(0, eave + 1.0, s * (hz - wd * 0.5)), wd, hx * 2.0, 1.5, rq, 0.4)
		lm.gable("Roof", Vector3(s * (hx - wd * 0.5), eave + 1.0, 0), wd, hz * 2.0 - wd * 2.0, 1.5, Basis(), 0.4)
	lm.box("Marble", Vector3(0, ct + 0.3, 0), Vector3(22.8, 0.6, hz * 2.0 + 1.8))
	lm.gable("Roof", Vector3(0, ct + 0.6, 0), 22.0, hz * 2.0 + 1.16, 1.0, Basis(), 0.4, "Stone")
	for s in [-1.0, 1.0]:
		var e := Vector3(0, ct + 0.6, s * (hz + 0.68))
		for t in [-1.0, 1.0]:
			lm.beam("Marble", e + Vector3(t * 11.4, 0, 0), e + Vector3(0, 1.05, 0), 0.6, 0.5, Vector3(0, 0, 1))
	# Windows: the outer fronts in three storeys, the central wing's
	# tall state-floor windows over its ground floor.
	var fl: Array[float] = [y0, y0 + 7.16, y0 + 14.27]
	var fh: Array[float] = [7.16, 7.11, 5.5]
	var wins: Array[Vector2] = [Vector2(1.6, 3.4), Vector2(1.7, 3.8), Vector2(1.5, 2.6)]
	var sills: Array[float] = [1.8, 1.7, 1.2]
	for k in 3:
		for s in [-1.0, 1.0]:
			var z: float = s * hz
			var rt := Vector3(s, 0, 0)
			var n := Vector3(0, 0, s)
			# Front and back: two runs either side of the central wing.
			_storey(lm, "Stone", "Marble", Vector3(-s * hx, fl[k], z), rt, n, hx - 11.0, fh[k], 8, wins[k], sills[k])
			_storey(lm, "Stone", "Marble", Vector3(s * 11.0, fl[k], z), rt, n, hx - 11.0, fh[k], 8, wins[k], sills[k])
			# North and south fronts.
			_storey(lm, "Stone", "Marble", Vector3(s * hx, fl[k], s * hz), Vector3(0, 0, -s), Vector3(s, 0, 0),
				hz * 2.0, fh[k], 18, wins[k], sills[k])
	for s in [-1.0, 1.0]:
		var z: float = s * (hz + 0.58)
		if s < 0.0:
			_storey(lm, "Stone", "Marble", Vector3(-s * 11.0, y0, z), Vector3(s, 0, 0), Vector3(0, 0, s), 22.0, 7.16, 5,
				Vector2(1.6, 3.4), 1.8)
		_storey(lm, "Stone", "Marble", Vector3(-s * 11.0, y0 + 7.16, z), Vector3(s, 0, 0), Vector3(0, 0, s), 22.0, 14.2,
			5, Vector2(2.0, 6.2), 3.4)
	# Terrace stair and the Doric entrance portico carrying the balcony.
	var pz := hz + 0.58
	for k in range(1, 6):
		var top := y0 - 0.3 * float(k)
		lm.box("Marble", Vector3(0, top * 0.5, pz + 6.0 + 0.45 * float(k)), Vector3(26.0, top, 0.45))
	lm.box("Marble", Vector3(0, y0 * 0.5, pz + 3.0), Vector3(24.0, y0, 6.0))
	for i in 6:
		AtUtil.doric(lm, "Marble", Vector3(-10.0 + 4.0 * float(i), y0, pz + 5.0), 5.9, 0.5, 20)
	for s in [-1.0, 1.0]:
		lm.box("Marble", Vector3(s * 11.0, y0 + 2.95, pz + 2.5), Vector3(1.0, 5.9, 5.0))
	AtUtil.entab(lm, "Marble", "Stone", Vector3(0, y0 + 5.9, pz + 2.6), 23.0, 5.6, 0.5, 0.5, 0.35,
		Basis(), false, false)
	AtUtil.triglyphs(lm, "Marble", Vector3(-10.0, y0 + 6.65, pz + 5.45), Vector3(10.0, y0 + 6.65, pz + 5.45), 11,
		Vector3.BACK, 0.48, 0.32)
	LandmarkDetail.balustrade(lm, "Marble", Vector3(-11.4, y0 + 7.25, pz + 5.2), Vector3(11.4, y0 + 7.25, pz + 5.2),
		1.0, 4.0)
	for s in [-1.0, 1.0]:
		LandmarkDetail.balustrade(lm, "Marble", Vector3(s * 11.4, y0 + 7.25, pz + 5.2), Vector3(s * 11.4, y0 + 7.25, pz),
			1.0, 5.0)
	for x in [-4.0, 0.0, 4.0]:
		AtUtil.doorway(lm, "Marble", "Shadow", Vector3(float(x), y0, pz + 0.35), Vector3.BACK, 2.0, 4.4)
	lm.commit(model)

# --- Zappeion ----------------------------------------------------------

## Origin at the middle of the hall, the portico toward +Z (yaw_deg).
## Theophil Hansen's Zappeion Megaron (1874-88): a straight front with
## the Corinthian portico under its pediment, pilastered and windowed,
## and behind it the semicircular body wrapped round the round atrium,
## whose two-tier colonnade of 32 columns on each level opens to the sky
## inside a ring wall that rises above the roofs (19.9 m).
static func zappeion(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#E4D9C2", 4.0))
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#EEE6D3", 3.0))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#4A4339", 3.0))
	lm.use("Dome", LandmarkMaterials.pbr("slate", "#7B8588", 3.0))
	lm.use("Glass", LandmarkMaterials.glass())
	var zc := 9.0
	var rr := 35.0
	var top := 12.5
	# Plan: the front block and the half-round body behind, as two
	# mirrored prisms round the open atrium (radius ah).
	var ah := 15.0
	for side in [-1.0, 1.0]:
		var sd: float = side
		var plan := PackedVector2Array([Vector2(0.0, 26.0), Vector2(-rr * sd, 26.0), Vector2(-rr * sd, zc)])
		for i in range(1, 17):
			var a := PI * 0.5 * float(i) / 16.0
			plan.append(Vector2(-cos(a) * rr * sd, zc - sin(a) * rr))
		for i in range(0, 33):
			var a := PI * 0.5 - PI * float(i) / 32.0
			plan.append(Vector2(-cos(a) * ah * sd, zc - sin(a) * ah))
		if sd > 0.0:
			plan.reverse()
		lm.poly_prism("Stone", plan, 0.0, top)
	lm.box("Marble", Vector3(0, 0.5, 26.1), Vector3(rr * 2.0 + 0.6, 1.0, 0.4))
	LandmarkDetail.cornice(lm, "Marble", Vector3(-rr - 0.5, top, 26.0), Vector3(rr + 0.5, top, 26.0), Vector3.BACK, 0.9)
	for s in [-1.0, 1.0]:
		LandmarkDetail.cornice(lm, "Marble", Vector3(s * rr, top, 26.5), Vector3(s * rr, top, zc), Vector3(s, 0, 0), 0.9)
	for i in 32:
		var a0 := PI + PI * float(i) / 32.0
		var a1 := PI + PI * float(i + 1) / 32.0
		var p0 := Vector3(cos(a0) * rr, top, zc + sin(a0) * rr)
		var p1 := Vector3(cos(a1) * rr, top, zc + sin(a1) * rr)
		var mid := ((p0 + p1) * 0.5 - Vector3(0, top, zc)).normalized()
		LandmarkDetail.cornice(lm, "Marble", p0, p1, mid, 0.9, false)
		if i % 2 == 0:
			lm.box("Marble", Vector3(mid.x * (rr + 0.15), 6.5, zc + mid.z * (rr + 0.15)), Vector3(0.9, 11.0, 0.3),
				Basis(Vector3.UP, atan2(mid.x, mid.z)))
		else:
			for y in [2.0, 7.4]:
				LandmarkDetail.window(lm, "Marble", "Glass", Vector3(mid.x * rr, float(y) + 1.9, zc + mid.z * rr), mid,
					1.6, 3.6, float(y) < 5.0)
	lm.box("Stone", Vector3(0, top + 0.9, 25.0), Vector3(rr * 2.0, 1.8, 2.0))
	# Front: pilasters, windows in two storeys either side of the portico.
	for i in 13:
		var x := -33.0 + 5.5 * float(i)
		if absf(x) < 11.0:
			continue
		lm.box("Marble", Vector3(x, 6.5, 26.15), Vector3(0.9, 11.0, 0.3))
	for i in 12:
		var x := -30.25 + 5.5 * float(i)
		if absf(x) < 11.0:
			continue
		LandmarkDetail.window(lm, "Marble", "Glass", Vector3(x, 3.9, 26.0), Vector3.BACK, 1.8, 3.8, true)
		LandmarkDetail.window(lm, "Marble", "Glass", Vector3(x, 9.3, 26.0), Vector3.BACK, 1.6, 3.0)
	# Corinthian portico on three steps: six columns and their returns.
	AtUtil.steps(lm, "Marble", Vector3(0, 1.2, 29.0), 20.0, 6.4, 3, 0.4, 0.5)
	for i in 6:
		AtUtil.corinthian(lm, "Marble", Vector3(-8.0 + 3.2 * float(i), 1.2, 31.0), 9.5, 0.55, 24)
	for s in [-1.0, 1.0]:
		AtUtil.corinthian(lm, "Marble", Vector3(s * 8.0, 1.2, 28.3), 9.5, 0.55, 24)
		lm.box("Marble", Vector3(s * 9.1, 5.95, 26.6), Vector3(1.2, 9.5, 1.2))
	var et := AtUtil.entab(lm, "Marble", "Stone", Vector3(0, 10.7, 29.0), 18.6, 4.8, 0.7, 0.75, 0.5)
	AtUtil.roof(lm, "Marble", "Marble", "Stone", Vector3(0, et, 28.6), 18.8, 5.4, 2.4, 0.2)
	for s in [-1.0, 1.0]:
		lm.box("Marble", Vector3(s * 9.3, et + 0.4, 31.3), Vector3(0.6, 0.8, 0.3))
	lm.box("Marble", Vector3(0, et + 2.75, 31.3), Vector3(0.9, 0.7, 0.3))
	AtUtil.doorway(lm, "Marble", "Shadow", Vector3(0, 1.2, 26.05), Vector3.BACK, 3.4, 6.2, true)
	for s in [-1.0, 1.0]:
		AtUtil.doorway(lm, "Marble", "Shadow", Vector3(s * 5.0, 1.2, 26.05), Vector3.BACK, 1.8, 4.2)
	# The round atrium: two tiers of 32 columns round an open court,
	# inside the ring wall that rises over the roofs with its glazed
	# clerestory and cornice.
	var ac := Vector3(0, 0, zc)
	var ar := 13.0
	for i in 32:
		var a := TAU * float(i) / 32.0
		var d := Vector3(cos(a), 0, sin(a))
		AtUtil.ionic(lm, "Marble", ac + d * ar, 6.0, 0.32, 0, PI * 0.5 - a)
		AtUtil.fluted(lm, "Marble", ac + d * ar + Vector3(0, 7.0, 0), 4.6, 0.25, 0.22, 0)
		lm.box("Marble", ac + d * ar + Vector3(0, 11.75, 0), Vector3(0.7, 0.3, 0.7), Basis(Vector3.UP, -a))
	lm.frustum("Marble", ac + Vector3(0, 6.0, 0), ar + 0.6, ar + 0.6, 1.0, 32)
	lm.frustum("Marble", ac + Vector3(0, 11.9, 0), ar + 0.6, ar + 0.6, 0.8, 32)
	lm.lathe("Stone", ac, PackedVector2Array([Vector2(ar + 2.0, top), Vector2(ar + 2.0, 19.2)]), 32, 1.0, 1.0,
		0.0, true, false)
	lm.lathe("Stone", ac, PackedVector2Array([Vector2(ar + 0.6, 12.7), Vector2(ar + 0.6, 19.2)]), 32, 1.0, 1.0,
		0.0, true, false)
	SEuUtil.ring_openings(lm, "Glass", ac + Vector3(0, 0, 0), ar + 2.0, 32, 32, top + 2.3, 1.4, 2.6, false, 0.1)
	lm.lathe("Dome", ac, PackedVector2Array([Vector2(ar + 2.3, 19.2), Vector2(ar + 0.4, 19.45)]), 32, 1.0, 1.0,
		0.0, true, false)
	lm.lathe("Marble", ac, PackedVector2Array([Vector2(ar + 2.0, 19.2), Vector2(ar + 2.5, 19.6),
		Vector2(ar + 2.6, 19.9), Vector2(ar + 2.0, 19.9)]), 32, 1.0, 1.0, 0.0, true, false)
	lm.lathe("Marble", ac, PackedVector2Array([Vector2(ar + 2.3, 12.5), Vector2(ar + 0.3, 12.5)]), 32, 1.0, 1.0,
		0.0, true, false)
	lm.commit(model)

# --- Academy of Athens ---------------------------------------------------

## Origin at the middle of the building, the Ionic portico toward +Z
## (yaw_deg onto Panepistimiou Street). Hansen's marble Academy (1859-85):
## the hexastyle Ionic portico after the Erechtheion over five steps,
## its pediment of the Birth of Athena (Drosis) on a blue tympanum with
## gilded akroteria, two lower wings ending in tetrastyle temple fronts,
## the seated Plato and Socrates either side of the steps, and before
## them the two Ionic columns carrying Athena with her spear and Apollo
## with his lyre (19.2 m to the top of the statues).
static func academy(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#EAE0CB", 3.0))
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#DCCFB4", 4.0))
	lm.use("Blue", LandmarkMaterials.pbr("render", "#2F5C8A", 3.0))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#4A4339", 3.0))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.use("Glass", LandmarkMaterials.glass())
	var y0 := 1.5
	AtUtil.steps(lm, "Marble", Vector3(0, y0, 20.25), 19.4, 4.5, 5, 0.3, 0.45)
	lm.box("Marble", Vector3(0, 7.0, 0), Vector3(19.0, 14.0, 36.0))
	# Shoulders between the portico block and the wings.
	for s in [-1.0, 1.0]:
		lm.box("Stone", Vector3(s * 14.25, 6.75, 0), Vector3(9.5, 13.5, 36.0))
		LandmarkDetail.cornice(lm, "Marble", Vector3(s * 9.5, 13.0, 18.0), Vector3(s * 19.0, 13.0, 18.0),
			Vector3.BACK, 0.7)
		lm.box("Stone", Vector3(s * 14.25, 13.9, 0), Vector3(9.5, 0.4, 36.0))
		for k in 2:
			LandmarkDetail.window(lm, "Marble", "Glass", Vector3(s * (12.25 + 4.0 * float(k)), y0 + 3.0, 18.0),
				Vector3.BACK, 1.6, 3.2, true)
			LandmarkDetail.window(lm, "Marble", "Glass", Vector3(s * (12.25 + 4.0 * float(k)), y0 + 8.4, 18.0),
				Vector3.BACK, 1.5, 2.8)
	for i in 6:
		AtUtil.ionic(lm, "Marble", Vector3(-7.5 + 3.0 * float(i), y0, 21.0), 10.4, 0.6, 24, 0.0)
	var et := AtUtil.entab(lm, "Marble", "Blue", Vector3(0, y0 + 10.4, 19.5), 18.6, 4.4, 0.8, 0.8, 0.5)
	AtUtil.roof(lm, "Stone", "Marble", "Blue", Vector3(0, et, 0.9), 19.0, 42.4, 3.0, 0.2)
	# Birth of Athena in the tympanum, gilded akroteria.
	for i in 9:
		var t := (float(i) - 4.0) / 4.0
		var fh := 2.4 * (1.0 - absf(t) * 0.7)
		LandmarkKits.statue_figure(lm, "Marble", Vector3(t * 7.0, et + 0.05, 21.7), fh, i == 4)
	lm.lathe("Gold", Vector3(0, et + 3.0, 22.0), PackedVector2Array([Vector2(0.3, 0), Vector2(0.55, 0.4),
		Vector2(0.2, 0.8), Vector2(0.0, 1.0)]), 10)
	for s in [-1.0, 1.0]:
		lm.lathe("Gold", Vector3(s * 9.4, et, 22.0), PackedVector2Array([Vector2(0.25, 0), Vector2(0.45, 0.35),
			Vector2(0.15, 0.7), Vector2(0.0, 0.85)]), 10)
	for s in [-1.0, 1.0]:
		lm.box("Marble", Vector3(s * 9.5, y0 + 6.0, 20.0), Vector3(1.4, 12.0, 4.4))
		# Wings ending in tetrastyle Ionic temple fronts with pediments.
		var wx: float = s * 25.5
		lm.box("Stone", Vector3(wx, 6.6, 0), Vector3(13.0, 13.2, 26.0))
		var wt := AtUtil.entab(lm, "Marble", "Blue", Vector3(wx, 11.6, 13.6), 13.4, 1.4, 0.6, 0.6, 0.45)
		for i in 4:
			AtUtil.ionic(lm, "Marble", Vector3(wx - 4.5 + 3.0 * float(i), y0, 13.6), 11.6 - y0, 0.45, 24, 0.0)
		AtUtil.roof(lm, "Stone", "Marble", "Blue", Vector3(wx, wt, 0.3), 13.6, 26.6, 2.2, 0.2)
		for k in 3:
			LandmarkDetail.window(lm, "Marble", "Glass", Vector3(s * 32.0, y0 + 3.0, -7.0 + 7.0 * float(k)),
				Vector3(s, 0, 0), 1.6, 3.2, true)
			LandmarkDetail.window(lm, "Marble", "Glass", Vector3(s * 32.0, y0 + 8.0, -7.0 + 7.0 * float(k)),
				Vector3(s, 0, 0), 1.5, 2.6)
		AtUtil.doorway(lm, "Marble", "Shadow", Vector3(wx, y0, 13.0), Vector3.BACK, 2.0, 4.6)
		# Seated Plato (left) and Socrates (right) on their pedestals.
		lm.box("Marble", Vector3(s * 11.5, 1.1, 23.5), Vector3(2.0, 2.2, 2.6))
		LandmarkAtAgora.seated(lm, Vector3(s * 11.5, 2.2, 23.3), 2.6, Vector3.BACK)
	AtUtil.doorway(lm, "Marble", "Shadow", Vector3(0, y0, 18.05), Vector3.BACK, 3.4, 7.0, true)
	# The two statue columns before the steps: Athena (left) and Apollo.
	for s in [-1.0, 1.0]:
		lm.box("Marble", Vector3(s * 14.5, 0.5, 27.0), Vector3(2.2, 1.0, 2.2))
		AtUtil.ionic(lm, "Marble", Vector3(s * 14.5, 1.0, 27.0), 13.0, 0.75, 24, 0.0)
		lm.box("Marble", Vector3(s * 14.5, 14.4, 27.0), Vector3(1.8, 0.8, 1.8))
		LandmarkKits.statue_figure(lm, "Marble", Vector3(s * 14.5, 14.8, 27.0), 4.4, s < 0.0)
	lm.beam("Gold", Vector3(-14.0, 14.9, 27.0), Vector3(-14.0, 19.2, 27.0), 0.1, 0.1)
	lm.box("Gold", Vector3(15.1, 17.4, 27.0), Vector3(0.1, 0.9, 0.5))
	lm.commit(model)
