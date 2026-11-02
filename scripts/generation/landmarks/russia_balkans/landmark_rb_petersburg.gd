class_name LandmarkRbPetersburg
extends RefCounted

## Saint Isaac's Cathedral, Saint Petersburg (Montferrand, 1818-1858), in
## true metres: 111.3 x 97.6 m with its stairs, 101.5 m to the cross.
## 112 red granite Corinthian columns with bronze capitals: 48 in the four
## pedimented porticoes (eight across; north and south two rows deep),
## 24 round the dome's rotunda and 8 round each corner belfry; the
## gilded dome 25.8 m across; 24 statues on the roof and 24 more on the
## rotunda's balustrade.

const ISAAC_TOP := 101.5
const COL_R := 0.93
const COL_H := 17.0
const PODIUM := 1.8
const PITCH := 5.6
const CORNICE := 22.0
const ATTIC := 27.0

## Origin at the dome axis. Body 70 (X) x 83 (Z) m; the double-row
## north and south porticoes face +/-Z, the single-row east and west
## porticoes +/-X.
static func st_isaacs(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("limestone", "#B9B3A6", 4.0))
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#CFCAC0", 3.0))
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#9A6256", 3.0))
	lm.use("Steps", LandmarkMaterials.pbr("stone", "#8E8A82", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("slate", "#7B8680", 3.0, 0.6, 0.25))
	lm.use("Windows", LandmarkMaterials.glass("#26323A"))
	lm.use("Gilt", LandmarkMaterials.gold())
	lm.use("Bronze", LandmarkMaterials.pbr("concrete", "#6B5A3A", 2.0, 0.45, 0.75))
	# Granite stylobate, the grey marble-clad body, its entablature and
	# attic, the low hipped roof and the square base of the dome.
	lm.box("Steps", Vector3(0, PODIUM * 0.5, 0), Vector3(72.0, PODIUM, 85.0))
	lm.box("Wall", Vector3(0, PODIUM + (CORNICE - PODIUM) * 0.5, 0), Vector3(70.0, CORNICE - PODIUM, 83.0))
	lm.box("Marble", Vector3(0, CORNICE - 1.6, 0), Vector3(70.8, 3.2, 83.8))
	lm.box("Marble", Vector3(0, CORNICE + 0.3, 0), Vector3(72.0, 0.6, 85.0))
	lm.box("Wall", Vector3(0, (CORNICE + ATTIC) * 0.5 + 0.3, 0), Vector3(69.0, ATTIC - CORNICE - 0.6, 82.0))
	lm.box("Marble", Vector3(0, ATTIC, 0), Vector3(70.0, 0.6, 83.0))
	LandmarkCeParts.hip(lm, "Roof", Vector3(0, ATTIC + 0.3, 0), 68.0, 81.0, 4.0)
	lm.box("Wall", Vector3(0, 33.0, 0), Vector3(42.0, 12.0, 42.0))
	lm.box("Marble", Vector3(0, 39.2, 0), Vector3(43.4, 0.8, 43.4))
	var faces := [[Vector3(0, 0, 1), 41.5, 2, 83.0, 70.0], [Vector3(0, 0, -1), 41.5, 2, 83.0, 70.0],
		[Vector3(1, 0, 0), 35.0, 1, 70.0, 83.0], [Vector3(-1, 0, 0), 35.0, 1, 70.0, 83.0]]
	for f in faces:
		_isaac_front(lm, f[0], float(f[1]), int(f[2]), float(f[4]))
	# Corner pilasters and the roof statues at the attic corners.
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			lm.box("Marble", Vector3(sx * 34.4, CORNICE * 0.5, sz * 40.9), Vector3(2.6, CORNICE - 1.0, 2.6))
			LandmarkKits.statue_figure(lm, "Bronze", Vector3(sx * 33.8, ATTIC + 0.3, sz * 40.3), 4.2)
	_isaac_dome(lm)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_belfry(lm, Vector3(sx * 29.0, ATTIC + 0.3, sz * 35.5))
	lm.commit(model)

## One front: the portico of eight columns (`rows` deep) on its podium
## with the flight of steps, entablature, pediment with its bronze
## relief group and three statues; the bronze doors and the framed
## windows of the wall either side. `half` is the wall's distance from
## the axis, `wall_len` its length.
static func _isaac_front(lm: LandmarkMesh, out: Vector3, half: float, rows: int, wall_len: float) -> void:
	var b := LandmarkRbParts.facing(out)
	var right := b.x
	var row_pitch := 5.0
	var depth := float(rows) * row_pitch + 0.4
	var span := 7.0 * PITCH + COL_R * 5.0
	var o := out * half
	# Podium and steps.
	lm.box("Steps", o + out * (depth * 0.5) + Vector3(0, PODIUM * 0.5, 0), Vector3(span + 2.0, PODIUM, depth), b)
	# The east and west stairs run out further (wide granite flights).
	LandmarkRbParts.steps(lm, "Steps", o + out * depth, out, span + 2.0, 0.6 if rows > 1 else 1.25, PODIUM / 7.0, 6)
	for row in rows:
		var d := row_pitch * (float(row) + 0.5)
		for i in 8:
			var s := (float(i) - 3.5) * PITCH
			LandmarkRbParts.order_column(lm, "Granite", o + right * s + out * d + Vector3(0, PODIUM, 0), COL_R,
				COL_H, "corinthian", out, 16, "Bronze")
	# Entablature (architrave, frieze, cornice), raking cornice, pediment.
	var top := PODIUM + COL_H
	var ec := o + out * (depth * 0.5)
	lm.box("Marble", ec + Vector3(0, top + 0.6, 0), Vector3(span, 1.2, depth), b)
	lm.box("Marble", ec + Vector3(0, top + 1.6, 0) - out * 0.1, Vector3(span - 0.4, 0.8, depth - 0.2), b)
	lm.box("Marble", ec + Vector3(0, top + 2.6, 0) + out * 0.2, Vector3(span + 0.8, 1.2, depth + 0.4), b)
	LandmarkDetail.cornice(lm, "Marble", o + out * (depth + 0.2) - right * (span * 0.5 + 0.4) + Vector3(0, top + 2.0, 0),
		o + out * (depth + 0.2) + right * (span * 0.5 + 0.4) + Vector3(0, top + 2.0, 0), out, 1.2, true)
	var py := top + 3.2
	var rise := 6.0
	lm.gable("Roof", ec + Vector3(0, py, 0), span + 0.4, depth + 0.4, rise, b, 0.6, "Marble")
	# Raking cornices and the tympanum relief: bronze figures standing
	# lower toward the corners.
	var tymp := o + out * (depth + 0.05) + Vector3(0, py, 0)
	var hs := span * 0.5 + 0.6
	for sgn in [-1.0, 1.0]:
		lm.beam("Marble", tymp + out * 0.4 + right * (sgn * hs) + Vector3(0, 0.3, 0), tymp + out * 0.4 + Vector3(0, rise + 0.4, 0),
			1.0, 0.9, out)
	for i in 9:
		var s := (float(i) - 4.0) * 3.6
		var fh := (rise - 0.6) * (1.0 - absf(s) / (span * 0.5)) - 0.4
		if fh > 1.0:
			LandmarkRbParts.figure(lm, "Bronze", tymp - out * 0.3 + right * s + Vector3(0, 0.2, 0), fh, 0.0)
	# Statues on the apex and the two corners of the pediment.
	LandmarkKits.statue_figure(lm, "Bronze", tymp + Vector3(0, rise + 0.6, 0), 4.6)
	for sgn in [-1.0, 1.0]:
		LandmarkKits.statue_figure(lm, "Bronze", tymp + right * (sgn * (hs - 1.0)) + Vector3(0, 0.6, 0), 4.0)
	# Bronze doors in the portico and framed windows beside it.
	var wall := o + out * 0.05
	lm.box("Bronze", wall + Vector3(0, PODIUM + 6.0, 0), Vector3(6.0, 12.0, 0.4), b)
	LandmarkDetail.arch(lm, "Marble", wall + Vector3(0, PODIUM + 12.0, 0) - Vector3(0, 3.0, 0), out, 6.0, 0.8, 0.5)
	for sgn in [-1.0, 1.0]:
		var sx: float = sgn * (PITCH * 1.5)
		lm.box("Bronze", wall + right * sx + Vector3(0, PODIUM + 4.5, 0), Vector3(3.0, 8.0, 0.3), b)
		var wx: float = sgn * (span * 0.5 + (wall_len * 0.5 - span * 0.5) * 0.5)
		LandmarkDetail.window(lm, "Marble", "Windows", wall + right * wx + Vector3(0, PODIUM + 6.5, 0), out, 2.6, 6.0)
		LandmarkDetail.window(lm, "Marble", "Windows", wall + right * wx + Vector3(0, PODIUM + 15.5, 0), out, 2.6, 5.5, true)
		for k in [-1.0, 1.0]:
			LandmarkRbParts.pilaster(lm, "Marble", wall + right * (wx + k * 3.4) + Vector3(0, PODIUM, 0), out, 1.2,
				CORNICE - 3.2 - PODIUM, 0.4)

## Dome stack: rotunda base, 24-column peristyle under a statue-lined
## balustrade, windowed attic drum, the ribbed gilded dome 25.8 m
## across, the colonnaded lantern, its cupola and cross.
static func _isaac_dome(lm: LandmarkMesh) -> void:
	var d0 := 39.6
	lm.frustum("Wall", Vector3(0, d0, 0), 18.5, 18.5, 3.4, 32)
	lm.frustum("Marble", Vector3(0, d0 + 3.4, 0), 18.9, 18.9, 0.6, 32)
	var base := d0 + 4.0
	var ph := 14.0
	for i in 24:
		var a := TAU * float(i) / 24.0
		var d := Vector3(cos(a), 0, sin(a))
		LandmarkRbParts.order_column(lm, "Granite", Vector3(0, base, 0) + d * 15.6, 0.75, ph, "corinthian", d, 12,
			"Bronze")
		# Drum windows between the columns.
		var wa := a + PI / 24.0
		var wd := Vector3(cos(wa), 0, sin(wa))
		LandmarkDetail.window(lm, "Marble", "Windows", wd * 13.45 + Vector3(0, base + 6.5, 0), wd, 1.8, 6.0, true)
	lm.frustum("Wall", Vector3(0, base, 0), 13.4, 13.4, ph, 32)
	# Entablature ring, balustrade and the 24 statues over the columns.
	lm.frustum("Marble", Vector3(0, base + ph, 0), 16.6, 16.6, 1.6, 32)
	lm.lathe("Marble", Vector3(0, base + ph + 1.6, 0), PackedVector2Array([Vector2(16.6, 0), Vector2(17.1, 0.4),
		Vector2(17.2, 1.0), Vector2(0.0, 1.0)]), 32)
	var by := base + ph + 2.6
	for i in 24:
		var a0 := TAU * float(i) / 24.0
		var a1 := TAU * float(i + 1) / 24.0
		LandmarkRbParts.balustrade(lm, "Marble", Vector3(cos(a0), 0, sin(a0)) * 16.4 + Vector3(0, by, 0),
			Vector3(cos(a1), 0, sin(a1)) * 16.4 + Vector3(0, by, 0), 1.2, 0.6, 10.0)
		LandmarkRbParts.figure(lm, "Bronze", Vector3(cos(a0), 0, sin(a0)) * 16.4 + Vector3(0, by, 0), 3.4, 1.4)
	# Attic drum with its windows, the gilded ribbed dome.
	var dr := base + 16.6
	lm.frustum("Wall", Vector3(0, dr, 0), 13.0, 13.0, 6.5, 32)
	SEuUtil.ring_openings(lm, "Windows", Vector3(0, dr, 0), 13.0, 32, 12, 1.3, 2.0, 4.0, false, PI / 24.0)
	for i in 12:
		var a := TAU * float(i) / 12.0
		var d := Vector3(cos(a), 0, sin(a))
		lm.box("Marble", d * 13.1 + Vector3(0, dr + 3.25, 0), Vector3(1.0, 6.5, 0.4), Basis.looking_at(d))
	lm.frustum("Marble", Vector3(0, dr + 6.0, 0), 13.4, 13.6, 0.6, 32)
	var dy := dr + 6.5
	var prof := LandmarkRbParts.dome_profile(12.9, 21.5, 12)
	lm.lathe("Gilt", Vector3(0, dy, 0), prof, 48)
	for i in 24:
		var a := TAU * float(i) / 24.0
		var d := Vector3(cos(a), 0, sin(a))
		for j in prof.size() - 3:
			var p0 := d * (prof[j].x + 0.12) + Vector3(0, dy + prof[j].y, 0)
			var p1 := d * (prof[j + 1].x + 0.12) + Vector3(0, dy + prof[j + 1].y, 0)
			lm.beam("Gilt", p0, p1, 0.5, 0.3, d.cross(Vector3.UP))
	# Lantern: eight columns round a drum, cornice, gilded cupola, cross.
	var ly := dy + 21.5
	lm.frustum("Marble", Vector3(0, ly - 0.4, 0), 3.8, 3.6, 0.8, 16)
	for i in 8:
		var a := TAU * float(i) / 8.0
		var d := Vector3(cos(a), 0, sin(a))
		LandmarkRbParts.order_column(lm, "Marble", Vector3(0, ly + 0.4, 0) + d * 3.0, 0.28, 6.1, "corinthian", d, 8)
	lm.frustum("Wall", Vector3(0, ly + 0.4, 0), 2.4, 2.4, 6.1, 16)
	lm.frustum("Marble", Vector3(0, ly + 6.5, 0), 3.6, 3.6, 0.8, 16)
	lm.lathe("Gilt", Vector3(0, ly + 7.3, 0), LandmarkRbParts.dome_profile(3.2, 2.2, 6), 16)
	lm.frustum("Gilt", Vector3(0, ly + 9.4, 0), 0.5, 0.3, 0.6, 8)
	LandmarkRbParts.cross(lm, "Gilt", Vector3(0, ly + 10.0, 0), ISAAC_TOP - ly - 10.0)

## A corner belfry on the roof: square base with arched openings, eight
## columns round a round drum, cornice, gilded dome, lantern and cross.
static func _belfry(lm: LandmarkMesh, c: Vector3) -> void:
	lm.box("Wall", c + Vector3(0, 3.5, 0), Vector3(9.0, 7.0, 9.0))
	lm.box("Marble", c + Vector3(0, 7.2, 0), Vector3(9.6, 0.5, 9.6))
	for k in 4:
		var out := Vector3(cos(PI * 0.5 * k), 0, sin(PI * 0.5 * k))
		SEuUtil.opening(lm, "Windows", c + out * 4.55 + Vector3(0, 1.5, 0), Vector3.UP.cross(out), Vector3.UP, 2.0, 4.2)
	var cb := c + Vector3(0, 7.45, 0)
	for i in 8:
		var a := TAU * (float(i) + 0.5) / 8.0
		var d := Vector3(cos(a), 0, sin(a))
		LandmarkRbParts.order_column(lm, "Granite", cb + d * 3.6, 0.35, 7.0, "corinthian", d, 10, "Bronze")
	lm.frustum("Wall", cb, 2.8, 2.8, 7.0, 16)
	SEuUtil.ring_openings(lm, "Windows", cb, 2.8, 16, 4, 1.5, 1.2, 3.6, false, PI / 4.0)
	lm.frustum("Marble", cb + Vector3(0, 7.0, 0), 4.3, 4.3, 0.9, 16)
	lm.frustum("Wall", cb + Vector3(0, 7.9, 0), 3.4, 3.4, 1.0, 16)
	lm.lathe("Gilt", cb + Vector3(0, 8.9, 0), LandmarkRbParts.dome_profile(3.5, 4.4, 8), 20)
	lm.frustum("Gilt", cb + Vector3(0, 13.3, 0), 0.6, 0.5, 1.0, 8)
	lm.lathe("Gilt", cb + Vector3(0, 14.3, 0), LandmarkRbParts.dome_profile(0.6, 0.5, 3), 8)
	LandmarkRbParts.cross(lm, "Gilt", cb + Vector3(0, 14.8, 0), 3.0)
