class_name LandmarkAtTheatres
extends RefCounted

## The Odeon of Herodes Atticus, the Theatre of Dionysus and the
## Panathenaic Stadium in true metres: real stepped rows on the correct
## plan curvature (semicircle, 190-degree cavea, marble horseshoe).

# --- Odeon of Herodes Atticus ---------------------------------------

## Origin at the middle of the footprint, the arcaded facade toward +Z
## (yaw_deg onto the street side). Semicircular cavea of 80 m: 33 rows
## of Pentelic marble seats (20 lower and 11 upper round a diazoma),
## five wedges each split by stepped aisles, round a paved semicircular
## orchestra; the stage podium; the 28 m stage building of three storeys
## whose outer wall on the Dionysiou Areopagitou side is pierced by
## tiers of round-arched openings with moulded archivolts between
## pilaster strips, and whose inner face (scaenae frons) has its tiers
## of arched niches; the side wings with their arched gates and windows.
static func odeon(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#E3D7C0", 2.5))
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#C9B48E", 3.0))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#4C4439", 3.0))
	lm.use("Floor", LandmarkMaterials.pbr("stone", "#B9AD98", 2.5))
	var c := Vector3(0, 0, 12.5)
	var orch := PackedVector2Array()
	for i in 33:
		var a := PI + PI * float(i) / 32.0
		orch.append(Vector2(c.x + cos(a) * 10.05, c.z + sin(a) * 10.05))
	lm.poly_prism("Floor", orch, 0.0, 1.0)
	# Checkered paving of the orchestra in rings of dark slabs.
	for ring in 4:
		var rr := 2.0 + 2.0 * float(ring)
		var n := 6 + 5 * ring
		for i in n:
			var a := PI + PI * (float(i) + 0.5) / float(n)
			lm.box("Shadow", c + Vector3(cos(a) * rr, 1.0, sin(a) * rr), Vector3(0.9, 0.04, 0.9),
				Basis(Vector3.UP, -a), 0.0)
	AtUtil.cavea_wedges(lm, "Marble", "Floor", c, 10.0, 20, 0.9, 0.42, PI, TAU, 1.0, 0.0, 5, 0.05)
	AtUtil.cavea(lm, "Floor", c, 28.0, 1, 1.8, 0.0, PI, TAU, 9.4, 0.0)
	AtUtil.cavea_wedges(lm, "Marble", "Floor", c, 29.8, 11, 0.9, 0.42, PI, TAU, 9.4, 0.0, 5, 0.05)
	AtUtil.cavea(lm, "Stone", c, 39.7, 1, 1.4, 0.0, PI, TAU, 15.2, 0.0)
	# Stage podium, its front steps, the wings and the stage building.
	lm.box("Floor", Vector3(0, 1.0, 14.0), Vector3(80.0, 2.0, 3.0))
	for k in 3:
		lm.box("Marble", Vector3(0, 0.33 * float(k + 1) * 0.5 + 0.5, 11.75 + 0.3 * float(k)),
			Vector3(34.0, 0.33 * float(k + 1) + 1.0, 0.3))
	lm.box("Marble", Vector3(0, 2.05, 14.0), Vector3(36.0, 0.1, 3.2))
	for s in [-1.0, 1.0]:
		lm.box("Stone", Vector3(s * 25.5, 8.9, 14.0), Vector3(31.0, 17.8, 3.0))
		# Arched gate of the side entrance (parodos) and windows above.
		_arched(lm, Vector3(s * 30.0, 0.0, 12.45), Vector3.FORWARD, 3.6, 7.0)
		for k in 2:
			_arched(lm, Vector3(s * (18.0 + 6.0 * float(k)), 9.5, 12.45), Vector3.FORWARD, 2.0, 4.6)
	lm.box("Stone", Vector3(0, 14.0, 21.5), Vector3(82.0, 28.0, 12.0))
	lm.box("Marble", Vector3(0, 27.7, 21.5), Vector3(83.0, 0.6, 13.0))
	# Outer facade: three tiers of 23 arches between pilaster strips, with
	# moulded string courses.
	var tiers := [[0.5, 2.4, 7.6], [9.0, 2.4, 7.6], [17.8, 2.0, 7.2]]
	for t in tiers:
		var y: float = t[0]
		var w: float = t[1]
		var h: float = t[2]
		for i in 23:
			var x := (float(i) - 11.0) * 3.3
			_arched(lm, Vector3(x, y, 27.5), Vector3.BACK, w, h)
		for i in 24:
			var x := (float(i) - 11.5) * 3.3
			lm.box("Stone", Vector3(x, y + h * 0.5, 27.6), Vector3(0.55, h, 0.2))
	for y in [8.3, 16.8, 25.4]:
		LandmarkDetail.cornice(lm, "Marble", Vector3(-41.0, y, 27.5), Vector3(41.0, y, 27.5), Vector3.BACK,
			0.5, false)
	# Inner face of the stage building (scaenae frons) between the wings:
	# niche tiers with pilasters, the royal door in the middle.
	for tier in 3:
		var y := 2.0 + 8.5 * float(tier)
		for i in 5:
			var x := (float(i) - 2.0) * 4.0
			var door := tier == 0 and i == 2
			_arched(lm, Vector3(x, y, 15.5), Vector3.FORWARD, 2.8 if door else 2.4, 6.5 if tier < 2 else 6.0)
			if i < 4:
				lm.box("Stone", Vector3(x + 2.0, y + 3.2, 15.4), Vector3(0.6, 6.4, 0.2))
		LandmarkDetail.cornice(lm, "Marble", Vector3(-10.0, y + 7.6, 15.5), Vector3(10.0, y + 7.6, 15.5),
			Vector3.FORWARD, 0.45, false)
	lm.commit(model)

## A dark arched opening w x h standing on `o` (bottom centre on the wall
## face facing `n`), framed by a moulded archivolt.
static func _arched(lm: LandmarkMesh, o: Vector3, n: Vector3, w: float, h: float) -> void:
	var rt := Vector3.UP.cross(n).normalized()
	SEuUtil.opening(lm, "Shadow", o + n * 0.04, rt if rt.cross(Vector3.UP).dot(n) > 0.0 else -rt,
		Vector3.UP, w, h)
	LandmarkDetail.arch(lm, "Marble", o + Vector3(0, h - w * 0.5, 0), n, w, clampf(w * 0.12, 0.22, 0.45), 0.25)

# --- Theatre of Dionysus -----------------------------------------------

## Origin at the orchestra centre, the stage toward +Z (yaw_deg onto the
## south slope). Paved orchestra circle of 20 m, the front row of 67
## carved Pentelic thrones (proedria) round the priest of Dionysus's
## central throne, 20 lower rows, the diazoma and 14 upper rows over
## 190 degrees, in 13 wedges (kerkides) split by 12 stepped aisles, the
## Roman stage with the Bema of Phaedrus (relief slabs and the
## crouching Silenoi) and the ruined stage building behind.
static func dionysus(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Seat", LandmarkMaterials.pbr("limestone", "#BDB3A0", 2.5))
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#E3D7C0", 2.5))
	lm.use("Honey", LandmarkMaterials.pbr("limestone", "#CDB892", 3.0))
	lm.use("Dark", LandmarkMaterials.pbr("stone", "#5A5148", 2.5))
	lm.use("Floor", LandmarkMaterials.pbr("stone", "#B7AB96", 2.5))
	var a0 := PI * 1.5 - 1.658
	var a1 := PI * 1.5 + 1.658
	var orch := PackedVector2Array()
	for i in 48:
		var a := TAU * float(i) / 48.0
		orch.append(Vector2(cos(a) * 10.05, sin(a) * 10.05))
	lm.poly_prism("Floor", orch, 0.0, 0.05)
	# Rhomboid marble paving of the Roman orchestra.
	for i in 9:
		for j in 9:
			var p := Vector3(-7.2 + 1.8 * float(i), 0.06, -7.2 + 1.8 * float(j))
			if p.length() < 8.6 and (i + j) % 2 == 0:
				lm.box("Marble", p, Vector3(1.25, 0.03, 1.25), Basis(Vector3.UP, PI * 0.25), 0.0)
	AtUtil.cavea(lm, "Marble", Vector3.ZERO, 10.0, 1, 0.9, 0.2, a0, a1, 0.05, 0.0)
	# Proedria: 67 thrones on the marble step, the priest's in the middle.
	for i in 67:
		var a := lerpf(a0 + 0.03, a1 - 0.03, float(i) / 66.0)
		_throne(lm, Vector3(cos(a) * 10.4, 0.25, sin(a) * 10.4), a, 1.25 if i == 33 else 1.0)
	AtUtil.cavea_wedges(lm, "Seat", "Floor", Vector3.ZERO, 10.9, 20, 0.78, 0.4, a0, a1, 0.55, 0.0, 13, 0.04)
	AtUtil.cavea(lm, "Floor", Vector3.ZERO, 26.5, 1, 2.2, 0.0, a0, a1, 8.55, 0.0)
	AtUtil.cavea_wedges(lm, "Seat", "Floor", Vector3.ZERO, 28.7, 14, 0.78, 0.4, a0, a1, 8.55, 0.0, 13, 0.04)
	AtUtil.cavea(lm, "Honey", Vector3.ZERO, 39.6, 1, 1.3, 0.0, a0, a1, 15.0, 0.0)
	# Roman stage: platform, relief wall (Bema of Phaedrus), back wall.
	lm.box("Honey", Vector3(0, 1.0, 14.5), Vector3(44.0, 2.0, 6.0))
	lm.box("Marble", Vector3(0, 2.15, 14.5), Vector3(44.4, 0.3, 6.4))
	lm.box("Dark", Vector3(0, 1.0, 11.45), Vector3(38.0, 1.5, 0.12))
	for i in 7:
		lm.box("Marble", Vector3(-18.0 + 6.0 * float(i), 1.0, 11.4), Vector3(0.9, 1.7, 0.4))
		lm.box("Marble", Vector3(-18.0 + 6.0 * float(i), 1.95, 11.4), Vector3(1.1, 0.2, 0.5))
	for i in 6:
		var x := -15.0 + 6.0 * float(i)
		# Relief figures on each slab; the crouching Silenoi in the middle.
		for f in 3:
			LandmarkKits.statue_figure(lm, "Marble", Vector3(x - 1.6 + 1.6 * float(f), 0.3, 11.35), 1.3, f == 1)
		if i == 2 or i == 3:
			SEuUtil.blob(lm, "Marble", Vector3(x, 0.9, 11.2), 0.45, 0.55, 0.4)
	lm.box("Marble", Vector3(0, 0.25, 11.25), Vector3(38.0, 0.5, 0.5))
	# Steps up to the stage in the middle of the Bema.
	for k in 4:
		lm.box("Marble", Vector3(0, 0.25 * float(k + 1) * 0.5, 9.95 + 0.35 * float(k)),
			Vector3(3.0, 0.25 * float(k + 1), 0.35))
	lm.box("Honey", Vector3(0, 2.75, 19.5), Vector3(48.0, 5.5, 2.0))
	for i in 12:
		var x := -22.0 + 4.0 * float(i)
		var hh := 5.5 + 2.6 * absf(sin(float(i) * 1.7))
		lm.box("Honey", Vector3(x, hh * 0.5, 19.5), Vector3(3.2, hh, 1.9))
	for i in 6:
		lm.box("Marble", Vector3(-20.0 + 8.0 * float(i), 8.9, 19.5), Vector3(1.4, 1.3, 2.2))
		lm.box("Marble", Vector3(-20.0 + 8.0 * float(i), 4.4, 18.3), Vector3(1.0, 8.8, 0.9))
	# Stage-building foundations behind: the Hellenistic stoa wall.
	lm.box("Honey", Vector3(0, 0.6, 24.0), Vector3(60.0, 1.2, 1.4))
	for i in 16:
		lm.box("Honey", Vector3(-28.0 + 3.75 * float(i), 1.6, 24.0), Vector3(0.9, 0.8, 0.9))
	lm.commit(model)

## One proedria throne at `p` on the circle, angle `a` (seat facing the
## orchestra centre), scale `k`: seat with lion-paw legs, back and arms.
static func _throne(lm: LandmarkMesh, p: Vector3, a: float, k: float) -> void:
	var d := Vector3(cos(a), 0, sin(a))
	var b := Basis(d.cross(Vector3.UP), Vector3.UP, -d)
	lm.box("Marble", p + Vector3(0, 0.22 * k, 0), Vector3(0.62 * k, 0.44 * k, 0.55 * k), b)
	lm.box("Marble", p + d * 0.24 * k + Vector3(0, 0.62 * k, 0), Vector3(0.62 * k, 0.5 * k, 0.1 * k), b)
	for s in [-1.0, 1.0]:
		lm.box("Marble", p + b.x * 0.29 * k * float(s) + Vector3(0, 0.6 * k, 0), Vector3(0.08 * k, 0.32 * k,
			0.48 * k), b)

# --- Panathenaic Stadium ---------------------------------------------

## Origin at the middle of the stadium, the open end toward +Z and the
## sphendone toward -Z (yaw_deg onto the valley). The white Pentelic
## marble horseshoe: a 204 m arena 33 m wide on its raised marble kerb,
## 47 rows of seats (24 below the diazoma corridor, 23 above) climbed by
## stepped aisles, the parapet at 20 m, the two double herms of the
## turning post on the track, and the twin pylons at the entrance.
static func panathenaic(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#EAE2D1", 3.0))
	lm.use("Track", LandmarkMaterials.pbr("gravel", "#C2AC8C", 4.0))
	lm.use("Honey", LandmarkMaterials.pbr("limestone", "#D2BB93", 3.0))
	var z_open := 125.5
	var z_c := -62.0
	var arena := PackedVector2Array()
	arena.append(Vector2(-16.5, z_open))
	for i in range(0, 49):
		var t := PI + PI * float(i) / 48.0
		arena.append(Vector2(16.5 * cos(t), z_c + 16.5 * sin(t)))
	arena.append(Vector2(16.5, z_open))
	lm.poly_prism("Track", arena, 0.0, 0.03)
	AtUtil.u_band(lm, "Marble", z_open, z_c, 16.0, 16.5, 0.0, 0.5, 48)
	var depth := 0.95
	var rise := 0.4
	var r1 := 16.5 + depth * 24.0
	AtUtil.u_rows(lm, "Marble", z_open, z_c, 16.5, 24, depth, rise, 0.5, 0.0, 48)
	var yd := 0.5 + rise * 24.0
	AtUtil.u_band(lm, "Honey", z_open, z_c, r1, r1 + 2.5, 0.0, yd, 48)
	AtUtil.u_rows(lm, "Marble", z_open, z_c, r1 + 2.5, 23, depth, rise, yd, 0.0, 48)
	var r2 := r1 + 2.5 + depth * 23.0
	AtUtil.u_band(lm, "Honey", z_open, z_c, r2, r2 + 0.6, 0.0, 20.0, 48)
	AtUtil.u_band(lm, "Marble", z_open, z_c, r2 - 0.05, r2 + 0.65, 19.9, 20.0, 48)
	# Stepped aisles: radial in the sphendone, straight up the long sides.
	for i in 5:
		var am := PI + PI * (float(i) + 1.0) / 6.0
		AtUtil.aisle_steps(lm, "Honey", Vector3(0, 0, z_c), am, 1.0 / 16.5, 16.5, 24, depth, rise, 0.5)
		AtUtil.aisle_steps(lm, "Honey", Vector3(0, 0, z_c), am + 0.04, 1.0 / r1, r1 + 2.5, 23, depth, rise, yd)
	for i in 8:
		var z := z_c + 18.0 + 23.0 * float(i)
		for s in [-1.0, 1.0]:
			var am := 0.0 if s > 0.0 else PI
			AtUtil.aisle_steps(lm, "Honey", Vector3(0, 0, z), am, 0.0, 16.5, 24, depth, rise, 0.5, 1.1)
			AtUtil.aisle_steps(lm, "Honey", Vector3(0, 0, z + 11.5), am, 0.0, r1 + 2.5, 23, depth, rise, yd, 1.1)
	# Double herms of the turning post, and the entrance pylons.
	for z in [z_c + 8.0, z_open - 30.0]:
		for x in [-0.5, 0.5]:
			lm.box("Marble", Vector3(x, 0.8, z), Vector3(0.45, 1.6, 0.45))
			lm.lathe("Marble", Vector3(x, 1.6, z), PackedVector2Array([Vector2(0.18, 0), Vector2(0.24, 0.2),
				Vector2(0.2, 0.42), Vector2(0.0, 0.5)]), 10)
	for s in [-1.0, 1.0]:
		var p := Vector3(s * (r2 - 6.0), 0, z_open + 2.0)
		lm.box("Marble", p + Vector3(0, 3.0, 0), Vector3(2.4, 6.0, 2.4))
		lm.box("Marble", p + Vector3(0, 6.2, 0), Vector3(2.8, 0.4, 2.8))
	lm.commit(model)
