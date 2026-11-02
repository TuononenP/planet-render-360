class_name LandmarkIbRoyal
extends RefCounted

## Three royal and ecclesiastical landmarks of Castile in true metres:
## the Royal Palace of Madrid, the Almudena Cathedral facing it across
## the Plaza de la Armeria and the Alcazar of Toledo on its hill. Each
## is built with its front toward +Z (the registry yaw_deg turns it onto
## the real bearing).

# --- Royal Palace of Madrid ---

const PAL_HX := 70.0
const PAL_HZ := 67.5
const PAL_BASE := 11.0
const PAL_EAVE := 31.5
const PAL_TOP := 34.5

## The Baroque-classical palace (Juvarra, Sacchetti): a 140 x 135 m block
## round a 64 x 64 m court, a rusticated granite storey under a giant
## order of pilasters in white limestone, a projecting centre piece with
## engaged columns on the Armeria (south) and Oriente (east) fronts, a
## crowning cornice and balustrade, corner pavilions and low slate roofs
## behind the parapet; 34.5 m to the attic. The podium drops 20 m for
## the slope of the west front, the Armeria paving spreads south.
static func palace(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#9B988F", 3.0))
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#E1D9C5", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("slate", "#5E6468", 3.0))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#3B3833", 3.0))
	lm.use("Gilt", LandmarkMaterials.gold())
	lm.use("Paving", LandmarkMaterials.pbr("pavement", "#B4AB9B", 4.0))
	var hx := PAL_HX
	var hz := PAL_HZ
	lm.box("Granite", Vector3(0, -10.1, 0), Vector3(2.0 * hx + 8.0, 20.0, 2.0 * hz + 8.0))
	lm.box("Paving", Vector3(0, -0.25, hz + 35.0), Vector3(2.0 * hx + 8.0, 1.5, 70.0))
	# Four wings round the court: granite storey, limestone upper storeys.
	var wings := [[Vector3(0, 0, -49.75), Vector3(140.0, 0, 35.5)], [Vector3(0, 0, 49.75), Vector3(140.0, 0, 35.5)],
		[Vector3(-51.0, 0, 0), Vector3(38.0, 0, 64.0)], [Vector3(51.0, 0, 0), Vector3(38.0, 0, 64.0)]]
	for wg in wings:
		var c: Vector3 = wg[0]
		var s: Vector3 = wg[1]
		lm.box("Granite", c + Vector3(0, (PAL_BASE - 1.0) * 0.5, 0), Vector3(s.x, PAL_BASE + 1.0, s.z))
		lm.box("Stone", c + Vector3(0, (PAL_BASE + PAL_EAVE) * 0.5, 0), Vector3(s.x, PAL_EAVE - PAL_BASE, s.z))
		LandmarkCeParts.hip(lm, "Roof", c + Vector3(0, PAL_EAVE, 0), s.x - 3.0, s.z - 3.0, PAL_TOP - PAL_EAVE)
	for k in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * float(k))
		var out := r * Vector3(0, 0, 1)
		var right := r * Vector3(1, 0, 0)
		var dist := hz if k % 2 == 0 else hx
		var length := 2.0 * (hx if k % 2 == 0 else hz)
		var bays := roundi(length / 7.0)
		var pitch := length / float(bays)
		var face := out * dist
		var cols := 6 if k < 2 else 4
		var span := 6.4 * float(cols - 1) + 3.2
		# String course, cornice, pilasters, windows and the balustrade.
		lm.box("Stone", face + Vector3(0, PAL_BASE, 0) + out * 0.25, Vector3(length + 1.0, 0.8, 1.0), r)
		lm.box("Stone", face + Vector3(0, PAL_EAVE - 1.0, 0) + out * 0.7, Vector3(length + 2.4, 2.0, 2.0), r)
		LandmarkIbUtil.pilasters(lm, "Stone", face, right, out, bays + 1, pitch, 1.5, 0.7,
			PAL_BASE, PAL_EAVE - 2.0, span * 0.5 + 0.4)
		SEuUtil.face_row(lm, "Shadow", face, right, out, 1.8, bays, pitch, 2.4, 4.6)
		LandmarkIbUtil.panes(lm, "Shadow", face, right, out, 7.4, bays, pitch, 1.4, 2.0)
		LandmarkIbUtil.panes(lm, "Shadow", face, right, out, 13.2, bays, pitch, 2.4, 6.4)
		LandmarkIbUtil.panes(lm, "Shadow", face, right, out, 22.0, bays, pitch, 2.0, 4.6)
		LandmarkIbUtil.balustrade(lm, "Stone", "Shadow", face - right * (length * 0.5) + Vector3(0, PAL_EAVE, 0),
			face + right * (length * 0.5) + Vector3(0, PAL_EAVE, 0), out, 1.8, 7.0)
		# Centre piece: projecting body, engaged columns, attic with arms.
		lm.box("Stone", face + out * 1.5 + Vector3(0, PAL_EAVE * 0.5, 0), Vector3(span, PAL_EAVE, 3.0), r)
		lm.box("Granite", face + out * 1.6 + Vector3(0, PAL_BASE * 0.5, 0), Vector3(span + 0.6, PAL_BASE, 3.3), r)
		for i in cols:
			var cx := (float(i) - float(cols - 1) * 0.5) * 6.4
			var base := face + right * cx + out * 3.4 + Vector3(0, PAL_BASE, 0)
			lm.frustum("Stone", base, 0.95, 0.82, PAL_EAVE - 2.6 - PAL_BASE, 12)
			lm.box("Stone", base + Vector3(0, PAL_EAVE - 2.6 - PAL_BASE + 0.3, 0), Vector3(2.4, 0.6, 2.4), r)
		lm.box("Stone", face + out * 2.4 + Vector3(0, PAL_EAVE - 1.0, 0), Vector3(span + 1.6, 2.0, 4.6), r)
		SEuUtil.face_row(lm, "Shadow", face + out * 3.0, right, out, 1.5, cols - 1, 6.4, 3.4, 7.0)
		LandmarkIbUtil.panes(lm, "Shadow", face + out * 3.0, right, out, 13.4, cols - 1, 6.4, 2.6, 6.8)
		LandmarkIbUtil.panes(lm, "Shadow", face + out * 3.0, right, out, 22.2, cols - 1, 6.4, 2.2, 4.8)
		lm.box("Stone", face + out * 2.4 + Vector3(0, PAL_EAVE + 1.5, 0), Vector3(span - 6.0, 3.0, 3.0), r)
		lm.disc("Gilt", face + out * 3.95 + Vector3(0, PAL_EAVE + 1.6, 0), out, 1.1, 14)
	# The court's inner faces: two rows of panes on each wing.
	for wg in [[Vector3(0, 0, -32.0), Vector3(0, 0, 1), 64.0], [Vector3(0, 0, 32.0), Vector3(0, 0, -1), 64.0],
			[Vector3(-32.0, 0, 0), Vector3(1, 0, 0), 64.0], [Vector3(32.0, 0, 0), Vector3(-1, 0, 0), 64.0]]:
		var out2: Vector3 = wg[1]
		var right2 := Vector3(-out2.z, 0, out2.x)
		SEuUtil.face_row(lm, "Shadow", wg[0], right2, out2, 1.8, 8, 7.4, 3.6, 7.0)
		LandmarkIbUtil.panes(lm, "Shadow", wg[0], right2, out2, 13.2, 8, 7.4, 2.4, 6.4)
		LandmarkIbUtil.panes(lm, "Shadow", wg[0], right2, out2, 22.0, 8, 7.4, 2.0, 4.6)
	lm.box("Paving", Vector3(0, -0.25, 0), Vector3(64.0, 1.5, 64.0))
	# Corner pavilions: a raised attic block over each end.
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			lm.box("Stone", Vector3(sx * (hx - 7.0), PAL_EAVE + 1.0, sz * (hz - 7.0)), Vector3(12.0, 2.0, 12.0))
	lm.commit(model)

# --- Almudena Cathedral ---

const ALM_TOP := 73.0

## Madrid's cathedral (Cubas, Chueca Goitia): the baroque-classical
## front of white limestone and grey granite to match the palace across
## the square, a 56 m wide facade with a six-column portico under a
## pediment between two domed towers, the 104 m Latin cross behind it
## (22 m nave under a slate gable, aisles, 76 m transept, polygonal
## apse) and the ribbed dome on its sixteen-sided drum with lantern and
## cross at 73 m. Front toward +Z.
static func almudena(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#DAD6C9", 3.0))
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#A7A49C", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("slate", "#5F656A", 3.0))
	lm.use("Dome", LandmarkMaterials.pbr("slate", "#7F8A8E", 3.0))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#3B3833", 3.0))
	lm.use("Gilt", LandmarkMaterials.gold())
	lm.use("Steps", LandmarkMaterials.pbr("pavement", "#B9B1A2", 3.0))
	# Nave, aisles, transept and apse.
	lm.box("Stone", Vector3(0, 13.0, -1.0), Vector3(22.0, 27.0, 78.0))
	lm.gable("Roof", Vector3(0, 26.0, -1.0), 22.0, 78.0, 7.5, Basis(), 0.6)
	for s in [-1.0, 1.0]:
		lm.box("Stone", Vector3(s * 16.5, 8.5, 0.0), Vector3(11.0, 17.0, 74.0))
		LandmarkCeParts.hip(lm, "Roof", Vector3(s * 16.5, 17.0, 0.0), 11.0, 74.0, 2.2)
		for z in [-24.0, -12.0, 0.0, 12.0, 24.0, 36.0]:
			lm.box("Granite", Vector3(s * 22.4, 10.0, z), Vector3(1.4, 20.0, 1.8))
		SEuUtil.face_row(lm, "Shadow", Vector3(s * 22.0, 0, 0), Vector3(0, 0, 1), Vector3(s, 0, 0), 4.0, 6, 12.0, 2.6, 8.0, true)
	lm.box("Stone", Vector3(0, 13.0, 5.0), Vector3(76.0, 27.0, 18.0))
	lm.gable("Roof", Vector3(0, 26.0, 5.0), 18.0, 76.0, 6.5, Basis(Vector3.UP, PI * 0.5), 0.6)
	SEuUtil.face_row(lm, "Shadow", Vector3(0, 0, 14.0), Vector3.RIGHT, Vector3(0, 0, 1), 5.0, 2, 60.0, 3.0, 12.0, true)
	for s in [-1.0, 1.0]:
		SEuUtil.face_row(lm, "Shadow", Vector3(s * 38.0, 0, 5.0), Vector3(0, 0, 1), Vector3(s, 0, 0), 6.0, 1, 1.0, 4.0, 14.0, true)
	lm.frustum("Stone", Vector3(0, 0, -38.0), 12.5, 12.5, 25.0, 10, PI / 10.0)
	lm.frustum("Roof", Vector3(0, 25.0, -38.0), 13.4, 0.5, 10.0, 10, PI / 10.0)
	SEuUtil.ring_openings(lm, "Shadow", Vector3(0, 0, -38.0), 12.5, 10, 5, 6.0, 2.4, 10.0, true, PI * 0.5)
	# Crossing: sixteen-sided drum, ribbed dome, lantern and cross.
	var c := Vector3(0, 0, 5.0)
	lm.frustum("Stone", c + Vector3(0, 27.0, 0), 12.2, 12.2, 14.0, 16)
	SEuUtil.ring_openings(lm, "Shadow", c + Vector3(0, 27.0, 0), 12.2, 16, 8, 3.0, 2.0, 8.0, true)
	for i in 16:
		var a := TAU * float(i) / 16.0
		lm.box("Granite", c + Vector3(cos(a) * 12.4, 34.0, sin(a) * 12.4), Vector3(1.0, 14.0, 1.0))
	lm.lathe("Dome", c + Vector3(0, 41.0, 0), SEuUtil.dome(12.6, 17.0, 9), 16, 1.0, 1.0, 0.0, false)
	lm.frustum("Stone", c + Vector3(0, 58.0, 0), 3.4, 3.0, 8.0, 12)
	SEuUtil.ring_openings(lm, "Shadow", c + Vector3(0, 58.0, 0), 3.4, 12, 4, 2.5, 1.0, 4.0, true)
	lm.frustum("Dome", c + Vector3(0, 66.0, 0), 3.8, 0.4, 4.6, 12)
	lm.box("Gilt", c + Vector3(0, 69.5, 0), Vector3(0.35, 7.0, 0.35))
	lm.box("Gilt", c + Vector3(0, 71.4, 0), Vector3(2.2, 0.35, 0.35))
	# Front: 56 m wide, portico under a pediment, two towers.
	lm.box("Stone", Vector3(0, 16.0, 45.0), Vector3(56.0, 32.0, 14.0))
	lm.box("Granite", Vector3(0, 5.0, 45.2), Vector3(57.0, 10.0, 14.4))
	lm.box("Stone", Vector3(0, 31.0, 45.0), Vector3(58.0, 2.0, 16.0))
	LandmarkIbUtil.balustrade(lm, "Stone", "Shadow", Vector3(-29.0, 32.0, 52.9), Vector3(29.0, 32.0, 52.9),
		Vector3(0, 0, 1), 1.6, 7.0)
	for i in 6:
		var x := (float(i) - 2.5) * 4.4
		lm.frustum("Stone", Vector3(x, 10.0, 54.5), 0.95, 0.85, 19.5, 12)
		lm.box("Stone", Vector3(x, 29.9, 54.5), Vector3(2.4, 0.6, 2.4))
	lm.box("Stone", Vector3(0, 16.0, 51.5), Vector3(26.0, 32.0, 2.0))
	lm.box("Granite", Vector3(0, 5.0, 54.4), Vector3(28.0, 10.0, 4.4))
	lm.box("Stone", Vector3(0, 31.0, 54.0), Vector3(28.0, 2.0, 6.0))
	lm.gable("Stone", Vector3(0, 32.0, 54.0), 28.0, 5.0, 5.5, Basis(), 0.0, "Stone")
	lm.disc("Gilt", Vector3(0, 33.6, 56.55), Vector3(0, 0, 1), 1.5, 14)
	SEuUtil.face_row(lm, "Shadow", Vector3(0, 0, 52.5), Vector3.RIGHT, Vector3(0, 0, 1), 10.0, 3, 7.0, 4.0, 11.0)
	LandmarkIbUtil.panes(lm, "Shadow", Vector3(0, 0, 52.5), Vector3.RIGHT, Vector3(0, 0, 1), 22.8, 3, 7.0, 3.4, 6.2)
	for s in [-1.0, 1.0]:
		var t := Vector3(s * 21.5, 0, 47.0)
		lm.box("Stone", t + Vector3(0, 20.0, 0), Vector3(12.0, 40.0, 12.0))
		lm.box("Granite", t + Vector3(0, 5.0, 0), Vector3(12.6, 10.0, 12.6))
		lm.box("Stone", t + Vector3(0, 40.5, 0), Vector3(13.4, 1.0, 13.4))
		lm.box("Stone", t + Vector3(0, 44.0, 0), Vector3(9.0, 6.0, 9.0))
		for k in 4:
			var r := Basis(Vector3.UP, PI * 0.5 * float(k))
			var out := r * Vector3(0, 0, 1)
			SEuUtil.face_row(lm, "Shadow", t + out * 6.05, r * Vector3(1, 0, 0), out, 21.0, 1, 1.0, 2.6, 9.0)
			SEuUtil.face_row(lm, "Shadow", t + out * 4.55, r * Vector3(1, 0, 0), out, 41.0, 1, 1.0, 2.4, 5.0)
		lm.lathe("Dome", t + Vector3(0, 47.0, 0), SEuUtil.dome(5.0, 6.0, 6), 12)
		lm.box("Gilt", t + Vector3(0, 55.0, 0), Vector3(0.3, 4.0, 0.3))
		lm.box("Gilt", t + Vector3(0, 55.4, 0), Vector3(1.6, 0.3, 0.3))
	# Steps and forecourt.
	for k in 5:
		var sh := 0.35 * float(5 - k)
		lm.box("Steps", Vector3(0, sh * 0.5 - 0.1, 57.2 + 1.2 * float(k)), Vector3(30.0 + 3.0 * float(k), sh + 0.2, 1.2))
	lm.commit(model)

# --- Alcazar of Toledo ---

const TOL_TOP := 60.0

## The Imperial fortress-palace (Covarrubias, Villalpando, Herrera):
## a 66 x 84 m block of warm ashlar and granite with four floors round a
## courtyard, the Herrera front toward +Z with its Doric portal under
## a pediment, a hipped slate roof, and the four 14 m square corner
## towers (60 m to the tip) with their steep slate spires. It stands on
## the rock of the hill: the podium drops 20 m below ground level and the
## front carries a stepped terrace.
static func toledo_alcazar(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#CDBB97", 3.0))
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#A89E8A", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("slate", "#4F5256", 3.0))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#3B3833", 3.0))
	lm.use("Rock", LandmarkMaterials.pbr("cliff", "#8A7C68", 5.0))
	lm.use("Gilt", LandmarkMaterials.gold())
	lm.box("Rock", Vector3(0, -10.1, 0), Vector3(90.0, 20.0, 108.0))
	lm.box("Granite", Vector3(0, -0.3, 49.5), Vector3(50.0, 2.2, 7.0))
	lm.box("Granite", Vector3(0, -0.1, 46.5), Vector3(30.0, 2.2, 3.0))
	var eave := 34.0
	# Four wings round the 20 x 38 m courtyard.
	for wg in [[Vector3(0, 0, -30.5), Vector3(66.0, 0, 23.0)], [Vector3(0, 0, 30.5), Vector3(66.0, 0, 23.0)],
			[Vector3(-21.5, 0, 0), Vector3(23.0, 0, 38.0)], [Vector3(21.5, 0, 0), Vector3(23.0, 0, 38.0)]]:
		var c: Vector3 = wg[0]
		var s: Vector3 = wg[1]
		lm.box("Granite", c + Vector3(0, 5.0, 0), Vector3(s.x, 12.0, s.z))
		lm.box("Stone", c + Vector3(0, 6.0 + eave * 0.5, 0), Vector3(s.x, eave - 6.0, s.z))
		LandmarkCeParts.hip(lm, "Roof", c + Vector3(0, eave, 0), s.x - 1.0, s.z - 1.0, 5.5)
	for k in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * float(k))
		var out := r * Vector3(0, 0, 1)
		var right := r * Vector3(1, 0, 0)
		var half := 42.0 if k % 2 == 0 else 33.0
		var length := 66.0 if k % 2 == 0 else 84.0
		var bays := roundi(length / 6.5)
		var pitch := length / float(bays)
		var face := out * half
		lm.box("Granite", face + Vector3(0, 12.0, 0) + out * 0.3, Vector3(length + 1.0, 0.8, 1.0), r)
		lm.box("Stone", face + Vector3(0, 22.0, 0) + out * 0.25, Vector3(length + 0.8, 0.6, 0.8), r)
		lm.box("Stone", face + Vector3(0, eave - 0.6, 0) + out * 0.9, Vector3(length + 2.0, 1.6, 2.2), r)
		SEuUtil.face_row(lm, "Shadow", face, right, out, 2.0, bays, pitch, 1.8, 4.6)
		LandmarkIbUtil.panes(lm, "Shadow", face, right, out, 8.0, bays, pitch, 1.4, 2.6)
		LandmarkIbUtil.panes(lm, "Shadow", face, right, out, 14.0, bays, pitch, 2.0, 5.2)
		LandmarkIbUtil.panes(lm, "Shadow", face, right, out, 24.0, bays, pitch, 1.8, 4.4)
		LandmarkIbUtil.panes(lm, "Shadow", face, right, out, 29.5, bays, pitch, 1.4, 3.0)
		LandmarkIbUtil.pilasters(lm, "Granite", face, right, out, bays + 1, pitch, 1.0, 0.5, 12.0, eave - 1.2)
	# Courtyard faces.
	for wg in [[Vector3(0, 0, -19.0), Vector3(0, 0, 1), 20.0], [Vector3(0, 0, 19.0), Vector3(0, 0, -1), 20.0],
			[Vector3(-10.0, 0, 0), Vector3(1, 0, 0), 38.0], [Vector3(10.0, 0, 0), Vector3(-1, 0, 0), 38.0]]:
		var o2: Vector3 = wg[1]
		var n2 := roundi(float(wg[2]) / 5.0)
		var r2 := Vector3(-o2.z, 0, o2.x)
		SEuUtil.face_row(lm, "Shadow", wg[0], r2, o2, 2.0, n2, 5.0, 3.0, 6.5, false)
		LandmarkIbUtil.panes(lm, "Shadow", wg[0], r2, o2, 14.0, n2, 5.0, 2.2, 5.0)
		LandmarkIbUtil.panes(lm, "Shadow", wg[0], r2, o2, 24.0, n2, 5.0, 2.2, 5.0)
	# Herrera portal: Doric half-columns under a pediment, grand door.
	lm.box("Stone", Vector3(0, 14.0, 43.5), Vector3(16.0, 28.0, 3.0))
	for x in [-6.0, -2.0, 2.0, 6.0]:
		lm.frustum("Stone", Vector3(x, 0, 45.3), 0.6, 0.52, 24.0, 10)
	lm.box("Stone", Vector3(0, 25.0, 44.8), Vector3(15.0, 2.2, 4.6))
	lm.gable("Stone", Vector3(0, 26.1, 44.8), 15.0, 4.0, 3.2, Basis(), 0.0, "Stone")
	SEuUtil.face_row(lm, "Shadow", Vector3(0, 0, 45.1), Vector3.RIGHT, Vector3(0, 0, 1), 0.3, 1, 1.0, 4.6, 10.0)
	LandmarkIbUtil.panes(lm, "Shadow", Vector3(0, 0, 45.1), Vector3.RIGHT, Vector3(0, 0, 1), 15.0, 2, 8.0, 2.6, 6.0)
	# Corner towers with their slate spires.
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var t := Vector3(sx * 33.0, 0, sz * 42.0)
			lm.box("Granite", t + Vector3(0, 5.0, 0), Vector3(15.0, 12.0, 15.0))
			lm.box("Stone", t + Vector3(0, 26.25, 0), Vector3(14.0, 40.5, 14.0))
			lm.box("Stone", t + Vector3(0, 46.2, 0), Vector3(15.6, 1.6, 15.6))
			for k in 4:
				var r := Basis(Vector3.UP, PI * 0.5 * float(k))
				var out := r * Vector3(0, 0, 1)
				var right := r * Vector3(1, 0, 0)
				for wy in [14.0, 25.0, 36.0]:
					LandmarkIbUtil.panes(lm, "Shadow", t + out * 7.0, right, out, wy, 2, 5.0, 1.8, 4.4)
			lm.spire("Roof", t + Vector3(0, 47.0, 0), 7.2, 12.5, 0.5)
			lm.box("Gilt", t + Vector3(0, 59.65, 0), Vector3(0.3, 0.7, 0.3))
	lm.commit(model)
