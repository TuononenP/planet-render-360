class_name LandmarkMaModern
extends RefCounted

## Two modern icons in true metres: Tehran's Azadi Tower and the
## Museum of the Future in Dubai.

# --- Azadi Tower ---

## Plinth top and the height where the four legs meet the upper body.
const AZ_G := 1.4
const AZ_BODY_Y := 33.0

## Half-extents of the flaring legs at height y: along the long axis (Z,
## 63 m at the foot) and the short axis (X, 42 m), curving in to the
## upper body.
static func _az_ext(y: float) -> Vector2:
	var t := clampf((y - AZ_G) / (AZ_BODY_Y - AZ_G), 0.0, 1.0)
	var f := pow(1.0 - t, 1.8)
	return Vector2(11.0 + 10.0 * f, 13.0 + 18.5 * f)

## Half-width of the great Sasanian (parabolic) arch through the long
## faces, 22 m at the foot closing at 21 m, and of the smaller arch
## through the short faces (12 m, closing at 15 m).
static func _az_arch(y: float) -> Vector2:
	var h := y - AZ_G
	return Vector2(11.0 * sqrt(maxf(1.0 - h / 21.0, 0.0)), 6.0 * sqrt(maxf(1.0 - h / 15.0, 0.0)))

## 45 m white-marble gateway (1971) of some 8,000 Isfahan marble blocks:
## four legs flaring from a 63 x 42 m footing and curving up into the
## upper body, cut through by the great parabolic arch on the long (east
## and west) faces and a lower arch on the short faces, the pointed
## (broken) arch over the great arch, the lozenge network of ribs on the
## legs, turquoise tile in the vault, and the upper storey with its
## observation windows under the crowning roof; on its plinth in Azadi
## Square.
static func azadi(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#EDEBE4", 5.0))
	lm.use("Tile", LandmarkMaterials.pbr("terracotta", "#2E8C98", 3.0))
	lm.use("Plaza", LandmarkMaterials.pbr("pavement", "#CFC6B2", 6.0))
	lm.use("Glass", LandmarkMaterials.glass("#26343A"))
	lm.box("Plaza", Vector3(0, 0.4, 0), Vector3(120, 0.8, 140))
	lm.box("Marble", Vector3(0, 1.1, 0), Vector3(48, 0.6, 68))
	var ys := PackedFloat32Array()
	var n := 30
	for k in n + 1:
		ys.append(lerpf(AZ_G, AZ_BODY_Y, float(k) / n))
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_az_leg(lm, ys, sx, sz)
	# Upper body and crown.
	var e := _az_ext(AZ_BODY_Y)
	lm.box("Marble", Vector3(0, AZ_BODY_Y + 3.0, 0), Vector3(e.x * 2.0, 6.0, e.y * 2.0))
	lm.box("Tile", Vector3(0, AZ_BODY_Y + 6.3, 0), Vector3(e.x * 2.0 + 0.6, 0.6, e.y * 2.0 + 0.6))
	for s in [-1.0, 1.0]:
		LandmarkMaParts.arched_bays(lm, "Marble", "Glass", Vector3(s * e.x, AZ_BODY_Y + 0.6, -s * e.y),
			Vector3(0, 0, s), Vector3(s, 0, 0), e.y * 2.0, 5.0, 7, 2.0, 2.4, 1.6, 0.3)
		LandmarkMaParts.arched_bays(lm, "Marble", "Glass", Vector3(s * e.x, AZ_BODY_Y + 0.6, s * e.y),
			Vector3(-s, 0, 0), Vector3(0, 0, s), e.x * 2.0, 5.0, 5, 2.0, 2.4, 1.6, 0.3)
	LandmarkMaParts.hip_roof(lm, "Marble", Vector3(0, AZ_BODY_Y + 6.6, 0), e.x * 2.0, e.y * 2.0, 5.0, 4.0, 14.0)
	lm.box("Tile", Vector3(0, AZ_BODY_Y + 11.8, 0), Vector3(4.4, 0.4, 14.4))
	# Pointed (broken) arch over the great arch on both long faces.
	for s in [-1.0, 1.0]:
		var curve := LandmarkMaParts.arch_curve(7.0, 13.0, 8)
		for k in curve.size() - 1:
			var a := curve[k]
			var b := curve[k + 1]
			var ya := AZ_G + 19.0 + a.y
			var yb := AZ_G + 19.0 + b.y
			lm.beam("Marble", Vector3(s * (_az_ext(ya).x + 0.35), ya, a.x), Vector3(s * (_az_ext(yb).x + 0.35), yb, b.x),
				0.9, 0.7, Vector3(s, 0, 0))
		# Window grille inside the pointed arch.
		for k in 5:
			var z := -4.8 + 2.4 * float(k)
			var y1 := AZ_G + 19.0 + 12.0 - absf(z) * 1.1
			lm.beam("Marble", Vector3(s * (_az_ext(AZ_G + 22.0).x + 0.2), AZ_G + 21.5, z),
				Vector3(s * (_az_ext(y1).x + 0.2), y1, z), 0.35, 0.35)
	lm.commit(model)

## One leg (quadrant sx, sz): its two outer faces and the two arch
## soffits as lofts through the levels `ys`, the lozenge rib network on
## the outer faces and turquoise tile up the great vault.
static func _az_leg(lm: LandmarkMesh, ys: PackedFloat32Array, sx: float, sz: float) -> void:
	var long_face: Array = []
	var short_face: Array = []
	var vault_m: Array = []
	var vault_t: Array = []
	var vault_s: Array = []
	for y in ys:
		var e := _az_ext(y)
		var ar := _az_arch(y)
		long_face.append(_az_row(Vector3(sx * e.x, y, sz * ar.x), Vector3(sx * e.x, y, sz * e.y)))
		short_face.append(_az_row(Vector3(sx * ar.y, y, sz * e.y), Vector3(sx * e.x, y, sz * e.y)))
		var row_m := _az_row(Vector3(sx * ar.y, y, sz * ar.x), Vector3(sx * e.x, y, sz * ar.x))
		if y - AZ_G <= 13.0:
			vault_m.append(row_m)
		if y - AZ_G >= 12.0 and ar.x > 0.0:
			vault_t.append(row_m)
		if ar.y > 0.0:
			vault_s.append(_az_row(Vector3(sx * ar.y, y, sz * ar.x), Vector3(sx * ar.y, y, sz * e.y)))
	# Close the vaults at their crowns.
	var tc := Vector3(0, AZ_G + 21.0, 0)
	vault_t.append(_az_row(Vector3(sx * _az_arch(tc.y).y, tc.y, 0), Vector3(sx * _az_ext(tc.y).x, tc.y, 0)))
	vault_s.append(_az_row(Vector3(0, AZ_G + 15.0, sz * _az_arch(AZ_G + 15.0).x),
		Vector3(0, AZ_G + 15.0, sz * _az_ext(AZ_G + 15.0).y)))
	lm.grid("Marble", long_face, Vector3(sx, 0, 0))
	lm.grid("Marble", short_face, Vector3(0, 0, sz))
	lm.grid("Marble", vault_m, Vector3(0, 0, -sz))
	lm.grid("Tile", vault_t, Vector3(0, -0.3, -sz))
	lm.grid("Marble", vault_s, Vector3(-sx, -0.3, 0))
	# Lozenge ribs: diagonals across both outer faces.
	for face in [long_face, short_face]:
		var rows: Array = face
		var out := Vector3(sx, 0, 0) if face == long_face else Vector3(0, 0, sz)
		for j in range(0, rows.size() - 3, 3):
			var r0: PackedVector3Array = rows[j]
			var r1: PackedVector3Array = rows[j + 3]
			for i in r0.size() - 1:
				lm.beam("Marble", r0[i] + out * 0.12, r1[i + 1] + out * 0.12, 0.3, 0.25, out)
				lm.beam("Marble", r0[i + 1] + out * 0.12, r1[i] + out * 0.12, 0.3, 0.25, out)
	# Tile band lining the great arch's edge.
	for j in vault_t.size() - 1:
		var a: PackedVector3Array = vault_t[j]
		var b: PackedVector3Array = vault_t[j + 1]
		lm.beam("Tile", a[a.size() - 1] + Vector3(sx * 0.1, 0, 0), b[b.size() - 1] + Vector3(sx * 0.1, 0, 0), 0.6, 0.4)

## Seven points evenly from a to b (a loft row).
static func _az_row(a: Vector3, b: Vector3) -> PackedVector3Array:
	var row := PackedVector3Array()
	for i in 7:
		row.append(a.lerp(b, float(i) / 6.0))
	return row

# --- Museum of the Future ---

const MOF_OUTER := Vector2(39.0, 37.0)
const MOF_INNER := Vector2(17.0, 21.0)
const MOF_CENTER_Y := 40.0
const MOF_HALF_DEPTH := 24.0

## Point of the torus at ring angle th and tube angle phi: between the
## outer and inner ellipse, with a rounded (super-elliptic) tube
## cross-section MOF_HALF_DEPTH deep either side of the mid-plane.
static func _mof_point(th: float, phi: float) -> Vector3:
	var o := Vector2(MOF_OUTER.x * cos(th), MOF_OUTER.y * sin(th))
	var i := Vector2(MOF_INNER.x * cos(th), MOF_INNER.y * sin(th))
	var c := (o + i) * 0.5
	var d := (o - i) * 0.5
	var cp := cos(phi)
	var sp := sin(phi)
	var cq := signf(cp) * pow(absf(cp), 0.7)
	var sq := signf(sp) * pow(absf(sp), 0.7)
	return Vector3(c.x + d.x * cq, MOF_CENTER_Y + c.y + d.y * cq, MOF_HALF_DEPTH * sq)

## Outward normal of the torus surface at (th, phi), from neighbours.
static func _mof_normal(th: float, phi: float) -> Vector3:
	var e := 0.01
	var du := _mof_point(th + e, phi) - _mof_point(th - e, phi)
	var dv := _mof_point(th, phi + e) - _mof_point(th, phi - e)
	var n := du.cross(dv).normalized()
	var mid := _mof_point(th, phi + PI)
	if n.dot(_mof_point(th, phi) - (mid + _mof_point(th, phi)) * 0.5) < 0.0:
		n = -n
	return n

## 77 m torus (2022) of 1,024 stainless-steel panels on its three-storey
## podium under a landscaped green mound: an elliptical ring round the
## oval void, the steel diagrid seams over it and the Arabic
## calligraphy (Matar bin Lahej's poem) cut as windows in flowing strokes
## and dots across both broad faces.
static func museum_of_the_future(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Steel", LandmarkMaterials.paint("#C8CDD0", 0.28, 0.85))
	lm.use("Glass", LandmarkMaterials.lit("#BFD3DC", 0.25))
	lm.use("Mound", LandmarkMaterials.pbr("grass", "#6E8A4E", 8.0))
	lm.use("Plaza", LandmarkMaterials.pbr("pavement", "#CFC6B2", 6.0))
	lm.box("Plaza", Vector3(0, 0.3, 0), Vector3(150, 0.6, 110))
	# Podium storeys and the planted mound over them.
	lm.lathe("Plaza", Vector3(0, 0.6, 0), PackedVector2Array([Vector2(58, 0), Vector2(58, 4.0),
		Vector2(56, 4.4)]), 32, 1.0, 0.78)
	lm.lathe("Mound", Vector3(0, 5.0, 0), PackedVector2Array([Vector2(56, 0), Vector2(50, 2.5),
		Vector2(38, 6.0), Vector2(22, 8.4), Vector2(0, 9.4)]), 32, 1.0, 0.78)
	for i in 6:
		var a := TAU * float(i) / 6.0 + 0.3
		lm.box("Glass", Vector3(cos(a) * 57.0, 2.8, sin(a) * 57.0 * 0.78), Vector3(8.0, 3.2, 0.3),
			Basis(Vector3.UP, -a + PI * 0.5), 0.0)
	var n_th := 96
	var n_ph := 28
	var rows: Array = []
	for j in n_th + 1:
		var row := PackedVector3Array()
		for k in n_ph + 1:
			row.append(_mof_point(TAU * j / n_th, -TAU * k / n_ph))
		rows.append(row)
	lm.grid("Steel", rows)
	# Diagrid seams: raised steel lines spiralling both ways.
	for dir in [-1.0, 1.0]:
		for s in 16:
			var prev := Vector3.ZERO
			for k in 41:
				var t := float(k) / 40.0
				var th := TAU * (float(s) / 16.0 + t)
				var ph: float = dir * TAU * t * 3.0 + float(s) * 0.4
				var p := _mof_point(th, ph) + _mof_normal(th, ph) * 0.12
				if k > 0:
					lm.beam("Steel", prev, p, 0.22, 0.12)
				prev = p
	# Calligraphy strokes in three lines on each broad face.
	for face in [1.0, -1.0]:
		for line in 3:
			var phc: float = deg_to_rad(90.0 + (float(line) - 1.0) * 22.0) * face
			var th := 0.0
			var k := 0
			while th < TAU - 0.12:
				var span := 0.07 + 0.2 * absf(sin(float(k) * 2.3 + float(line)))
				_mof_stroke(lm, th, minf(th + span, TAU - 0.02), phc + sin(float(k) * 1.7) * 0.08, 0.07 + 0.05 *
					absf(cos(float(k) * 1.3)))
				if k % 3 == 1:
					var dp := _mof_point(th + span * 0.5, phc + 0.2 * face)
					lm.disc("Glass", dp + _mof_normal(th + span * 0.5, phc + 0.2 * face) * 0.3,
						_mof_normal(th + span * 0.5, phc + 0.2 * face), 0.7, 8)
				th += span + 0.05 + 0.04 * absf(sin(float(k) * 3.1))
				k += 1
	lm.commit(model)

## One calligraphy stroke from th0 to th1 at tube angle phc, ph_w wide:
## a window strip just proud of the steel, tapering at both ends.
static func _mof_stroke(lm: LandmarkMesh, th0: float, th1: float, phc: float, ph_w: float) -> void:
	var rows: Array = []
	var steps := 6
	for j in steps + 1:
		var t := float(j) / float(steps)
		var th := lerpf(th0, th1, t)
		var w := ph_w * (0.35 + 0.65 * sin(PI * t))
		var row := PackedVector3Array()
		for k in 3:
			var ph := phc + w * (float(k) - 1.0)
			row.append(_mof_point(th, ph) + _mof_normal(th, ph) * 0.3)
		rows.append(row)
	var mid := (th0 + th1) * 0.5
	lm.grid("Glass", rows, _mof_point(mid, phc + PI), true)
