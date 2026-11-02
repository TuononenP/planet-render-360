class_name LandmarkIbRoyal
extends RefCounted

## The two Madrid landmarks facing each other across the Plaza de la
## Armeria, in true metres: the Royal Palace and the Almudena Cathedral.
## Each is built with its front toward +Z (the registry yaw_deg turns it
## onto the real bearing). The Alcazar of Toledo is LandmarkIbToledo.

# --- Royal Palace of Madrid ---

const PAL_HX := 70.0
const PAL_HZ := 67.5
const PAL_BASE := 11.0
const PAL_EAVE := 31.5
const PAL_TOP := 34.5

## The Baroque-classical palace (Juvarra, Sacchetti, 1738-1755): a 140 x
## 135 m block round a 64 x 64 m arcaded court. A two-storey rusticated
## granite base (arched ground-floor windows, a mezzanine) under a giant
## order of Tuscan pilasters in white Colmenar limestone framing three
## more floors: the piano nobile of balconied windows under alternating
## pediments, the second floor and an upper mezzanine. The Armeria
## (south) and Oriente (east) fronts carry projecting centre pieces of
## six engaged Ionic columns; the south one has Sabatini's balcony on
## four Doric columns over the doors and the clock with its bells and
## flanking statues on the attic. A dentilled cornice and a balustrade
## with urns crown the 34.5 m block; low slate roofs hide behind it.
static func palace(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#9B988F", 3.0))
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#E1D9C5", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("slate", "#5E6468", 3.0))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#3B3833", 3.0))
	lm.use("Gilt", LandmarkMaterials.gold())
	lm.use("Paving", LandmarkMaterials.pbr("pavement", "#B4AB9B", 4.0))
	lm.use("Glass", LandmarkMaterials.glass())
	lm.use("Iron", LandmarkMaterials.paint("#2B2E30", 0.6, 0.4))
	var hx := PAL_HX
	var hz := PAL_HZ
	lm.box("Paving", Vector3(0, 0.15, hz + 35.0), Vector3(2.0 * hx + 8.0, 0.3, 70.0))
	lm.box("Paving", Vector3(0, 0.15, 0), Vector3(64.0, 0.3, 64.0))
	# Four wings round the court: granite storey, limestone upper storeys.
	var wings := [[Vector3(0, 0, -49.75), Vector3(140.0, 0, 35.5)], [Vector3(0, 0, 49.75), Vector3(140.0, 0, 35.5)],
		[Vector3(-51.0, 0, 0), Vector3(38.0, 0, 64.0)], [Vector3(51.0, 0, 0), Vector3(38.0, 0, 64.0)]]
	for wg in wings:
		var c: Vector3 = wg[0]
		var s: Vector3 = wg[1]
		lm.box("Granite", c + Vector3(0, PAL_BASE * 0.5, 0), Vector3(s.x, PAL_BASE, s.z))
		lm.box("Stone", c + Vector3(0, (PAL_BASE + PAL_EAVE) * 0.5, 0), Vector3(s.x, PAL_EAVE - PAL_BASE, s.z))
		LandmarkCeParts.hip(lm, "Roof", c + Vector3(0, PAL_EAVE, 0), s.x - 3.0, s.z - 3.0, PAL_TOP - PAL_EAVE)
		# Chimney stacks along the ridge.
		var along := Vector3(1, 0, 0) if s.x > s.z else Vector3(0, 0, 1)
		for i in 4:
			var p := c + along * ((float(i) - 1.5) * maxf(s.x, s.z) * 0.22) + Vector3(0, PAL_EAVE + 2.6, 0)
			lm.box("Stone", p, Vector3(1.4, 2.4, 1.0))
			lm.box("Stone", p + Vector3(0, 1.3, 0), Vector3(1.7, 0.3, 1.3))
	for k in 4:
		_palace_front(lm, k)
	_palace_court(lm)
	# Corner pavilions: a raised attic with its own balustrade.
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var pc := Vector3(sx * (hx - 7.0), 0, sz * (hz - 7.0))
			lm.box("Stone", pc + Vector3(0, PAL_EAVE + 1.0, 0), Vector3(12.0, 2.0, 12.0))
			LandmarkIbParts.rail(lm, "Stone", pc + Vector3(-5.6, PAL_EAVE + 2.0, 5.6 * sz),
				pc + Vector3(5.6, PAL_EAVE + 2.0, 5.6 * sz), 0.9, 5.6, true)
	lm.commit(model)

## One outer front of the palace (k = 0 south, 1 east, 2 north, 3 west).
static func _palace_front(lm: LandmarkMesh, k: int) -> void:
	var r := Basis(Vector3.UP, PI * 0.5 * float(k))
	var out := r * Vector3(0, 0, 1)
	var right := r * Vector3(1, 0, 0)
	var dist := PAL_HZ if k % 2 == 0 else PAL_HX
	var length := 2.0 * (PAL_HX if k % 2 == 0 else PAL_HZ)
	var bays := roundi(length / 7.0)
	var pitch := length / float(bays)
	var face := out * dist
	var main := k < 2
	var cols := 6 if main else 4
	var span := 6.4 * float(cols - 1) + 3.2
	var gap := span * 0.5 + 0.3
	var basis := Basis(right, Vector3.UP, out)
	# Rusticated granite storey: plinth, channelled joints, string course.
	LandmarkIbParts.band(lm, "Granite", face, right, out, length + 1.2, 0.6, 1.2, 0.6)
	for j in 8:
		LandmarkIbParts.band(lm, "Granite", face, right, out, length, 1.7 + 1.15 * float(j), 0.14, 0.1)
	LandmarkIbParts.band(lm, "Stone", face, right, out, length + 1.0, PAL_BASE + 0.1, 0.9, 0.5)
	for i in bays:
		var s := (float(i) - float(bays - 1) * 0.5) * pitch
		if absf(s) < gap:
			continue
		var c := face + right * s
		LandmarkIbParts.portal(lm, "Granite", "Glass", c + Vector3(0, 1.6, 0), right, out, 2.0, 4.4, 1, 0.35)
		LandmarkIbParts.portal(lm, "Granite", "Glass", c + Vector3(0, 7.7, 0), right, out, 1.4, 1.4, 0, 0.25)
		# Piano nobile: a balcony window under a triangular pediment on
		# alternate bays; the second floor and the upper mezzanine.
		LandmarkDetail.window(lm, "Stone", "Glass", c + Vector3(0, 15.8, 0), out, 2.2, 4.6, false, 0.25)
		_balcony(lm, c + Vector3(0, 13.2, 0), right, out, 3.2)
		if i % 2 == 0:
			lm.gable("Stone", c + Vector3(0, 18.8, 0) + out * 0.35, 3.4, 0.7, 0.9, basis, 0.0, "Stone")
		LandmarkIbParts.portal(lm, "Stone", "Glass", c + Vector3(0, 22.2, 0), right, out, 2.0, 3.6, 0, 0.3)
		LandmarkIbParts.portal(lm, "Stone", "Glass", c + Vector3(0, 27.3, 0), right, out, 1.3, 1.0, 0, 0.2)
	LandmarkIbParts.pilaster_row(lm, "Stone", face, right, out, bays + 1, pitch, 1.5, 0.6,
		PAL_BASE + 0.55, PAL_EAVE - 2.0, gap)
	# Entablature: architrave, frieze, the dentilled cornice, the balustrade.
	LandmarkIbParts.band(lm, "Stone", face, right, out, length + 1.0, PAL_EAVE - 1.8, 0.5, 0.35)
	var ca := face - right * (length * 0.5 + 0.6) + Vector3(0, PAL_EAVE - 1.2, 0)
	var cb := face + right * (length * 0.5 + 0.6) + Vector3(0, PAL_EAVE - 1.2, 0)
	LandmarkDetail.cornice(lm, "Stone", ca, cb, out, 1.2, k == 0)
	LandmarkIbParts.rail(lm, "Stone", ca + Vector3(0, 1.2, 0) + out * 0.2 + right * 0.6,
		cb + Vector3(0, 1.2, 0) + out * 0.2 - right * 0.6, 1.5, pitch * 2.0, true)
	# Centre piece: projecting body, granite base with the doors, engaged
	# Ionic columns (pilasters on the north and west), attic with arms.
	lm.box("Stone", face + out * 1.5 + Vector3(0, PAL_EAVE * 0.5, 0), Vector3(span, PAL_EAVE, 3.0), r)
	lm.box("Granite", face + out * 1.6 + Vector3(0, PAL_BASE * 0.5, 0), Vector3(span + 0.6, PAL_BASE, 3.3), r)
	var cf := face + out * 3.0
	for i in cols:
		var cx := (float(i) - float(cols - 1) * 0.5) * 6.4
		if main:
			var base := cf + right * cx + out * 0.6 + Vector3(0, PAL_BASE, 0)
			lm.box("Stone", base + Vector3(0, 0.45, 0), Vector3(2.6, 0.9, 2.6), r)
			LandmarkDetail.column(lm, "Stone", base + Vector3(0, 0.9, 0), 0.95, PAL_EAVE - 2.1 - PAL_BASE - 0.9, "ionic", 0)
		else:
			LandmarkIbParts.pilaster(lm, "Stone", cf + right * cx, right, out, 1.7, 0.7, PAL_BASE + 0.55, PAL_EAVE - 2.0)
	for i in cols - 1:
		var cx := (float(i) - float(cols - 2) * 0.5) * 6.4
		var c := cf + right * cx
		LandmarkIbParts.portal(lm, "Granite", "Shadow", c + Vector3(0, 0.3, 0), right, out, 3.0, 6.4, 1, 0.45)
		LandmarkDetail.window(lm, "Stone", "Glass", c + Vector3(0, 16.0, 0), out, 2.4, 5.2, true, 0.25)
		LandmarkDetail.window(lm, "Stone", "Glass", c + Vector3(0, 24.2, 0), out, 2.2, 3.8, false, 0.2)
	var ea := cf + out * 1.5 - right * (span * 0.5 + 0.8) + Vector3(0, PAL_EAVE - 1.2, 0)
	var eb := cf + out * 1.5 + right * (span * 0.5 + 0.8) + Vector3(0, PAL_EAVE - 1.2, 0)
	lm.box("Stone", face + out * 2.4 + Vector3(0, PAL_EAVE - 1.6, 0), Vector3(span + 1.6, 1.2, 4.6), r)
	LandmarkDetail.cornice(lm, "Stone", ea, eb, out, 1.2, true)
	lm.box("Stone", face + out * 2.4 + Vector3(0, PAL_EAVE + 1.5, 0), Vector3(span - 6.0, 3.0, 3.0), r)
	LandmarkDetail.cornice(lm, "Stone", face + out * 3.9 - right * (span * 0.5 - 3.0) + Vector3(0, PAL_EAVE + 2.6, 0),
		face + out * 3.9 + right * (span * 0.5 - 3.0) + Vector3(0, PAL_EAVE + 2.6, 0), out, 0.5, false)
	lm.disc("Gilt", face + out * 3.95 + Vector3(0, PAL_EAVE + 1.6, 0), out, 1.1, 14)
	# Statues of kings on the balustrade over the Armeria centre piece.
	for sx in ([-1.0, 1.0] if k == 0 else []):
		for j in 2:
			var p: Vector3 = cf + out * 1.2 + right * (sx * (span * 0.5 - 0.6 - 4.5 * float(j))) + Vector3(0, PAL_EAVE, 0)
			LandmarkIbParts.statue(lm, "Stone", "Stone", p, 0.8, 2.4)
	if k == 0:
		_palace_clock(lm, face, right, out, basis)

## Sabatini's balcony over the Armeria doors on four Doric columns, and
## the clock on the attic with its bell frame and flanking figures.
static func _palace_clock(lm: LandmarkMesh, face: Vector3, right: Vector3, out: Vector3, basis: Basis) -> void:
	var bf := face + out * 6.2
	for x in [-4.5, -1.5, 1.5, 4.5]:
		LandmarkDetail.column(lm, "Granite", bf + right * float(x) + Vector3(0, 0.3, 0), 0.42, 6.0, "doric", 0)
	lm.box("Granite", bf + out * -1.3 + Vector3(0, 6.6, 0), Vector3(11.4, 0.6, 3.6), basis)
	LandmarkIbParts.rail(lm, "Stone", bf + out * 0.3 + right * -5.5 + Vector3(0, 6.9, 0),
		bf + out * 0.3 + right * 5.5 + Vector3(0, 6.9, 0), 1.0, 5.5)
	# Clock attic: the dial on a raised block, flanking figures, a gable.
	var at := face + out * 2.4 + Vector3(0, PAL_TOP, 0)
	lm.box("Stone", at + Vector3(0, 0.6, 0), Vector3(4.2, 1.2, 1.6), basis)
	lm.disc("Stone", at + out * 0.82 + Vector3(0, 0.6, 0), out, 0.55, 20)
	lm.disc("Gilt", at + out * 0.84 + Vector3(0, 0.6, 0), out, 0.42, 20)
	for sx in [-1.0, 1.0]:
		LandmarkKits.statue_figure(lm, "Stone", at + right * (sx * 2.7), 1.6, sx > 0.0)
	lm.gable("Stone", at + Vector3(0, 1.2, 0), 4.2, 1.6, 0.6, basis, 0.0, "Stone")

## Iron balcony w wide on a stone slab at `p` (floor level on the face).
static func _balcony(lm: LandmarkMesh, p: Vector3, right: Vector3, out: Vector3, w: float) -> void:
	var basis := Basis(right, Vector3.UP, out)
	lm.box("Stone", p + out * 0.45, Vector3(w, 0.25, 0.9), basis)
	lm.box("Iron", p + out * 0.85 + Vector3(0, 1.05, 0), Vector3(w - 0.1, 0.06, 0.06), basis)
	for s in [-1.0, 1.0]:
		lm.box("Iron", p + out * 0.45 + right * ((w * 0.5 - 0.06) * float(s)) + Vector3(0, 1.05, 0),
			Vector3(0.06, 0.06, 0.8), basis)
	for i in 4:
		var x := (float(i) / 3.0 - 0.5) * (w - 0.2)
		lm.box("Iron", p + out * 0.85 + right * x + Vector3(0, 0.6, 0), Vector3(0.05, 0.9, 0.05), basis)

## The court: an open arcade of round arches on the ground floor, the
## piano nobile and second floor windows, pilasters, cornice and parapet.
static func _palace_court(lm: LandmarkMesh) -> void:
	for wg in [[Vector3(0, 0, -32.0), Vector3(0, 0, 1)], [Vector3(0, 0, 32.0), Vector3(0, 0, -1)],
			[Vector3(-32.0, 0, 0), Vector3(1, 0, 0)], [Vector3(32.0, 0, 0), Vector3(-1, 0, 0)]]:
		var o: Vector3 = wg[0]
		var out: Vector3 = wg[1]
		var right := Vector3.UP.cross(out)
		for i in 9:
			var s := (float(i) - 4.0) * 7.0
			LandmarkIbParts.portal(lm, "Granite", "Shadow", o + right * s, right, out, 4.4, 8.0, 1, 0.5)
		LandmarkIbParts.band(lm, "Stone", o, right, out, 64.0, PAL_BASE + 0.1, 0.9, 0.5)
		LandmarkIbParts.window_row(lm, "Stone", "Glass", o, right, out, 15.8, 9, 7.0, 2.2, 4.6)
		for i in 9:
			LandmarkIbParts.portal(lm, "Stone", "Glass", o + right * ((float(i) - 4.0) * 7.0) + Vector3(0, 22.2, 0),
				right, out, 2.0, 3.6, 0, 0.25)
		LandmarkIbUtil.pilasters(lm, "Stone", o, right, out, 8, 7.0, 1.2, 0.5, PAL_BASE + 0.6, PAL_EAVE - 2.0)
		LandmarkIbParts.band(lm, "Stone", o, right, out, 64.0, PAL_EAVE - 1.0, 2.0, 1.2)
		LandmarkIbParts.band(lm, "Stone", o, right, out, 63.0, PAL_EAVE + 0.5, 1.0, 0.5)

# --- Almudena Cathedral ---

const ALM_TOP := 73.0

## Madrid's cathedral (Cubas, Chueca Goitia; 1883-1993): a 102 m Latin
## cross, north front toward +Z facing the palace across the square. The
## front, in white limestone over grey granite to match the palace,
## stands in two orders, paired Tuscan columns below and Ionic above
## under a pediment, with the bronze Peter and Paul at the doors, the
## four evangelists in the upper niches and four Spanish saints on the
## balustrade, between two 60 m bell towers with belfries and cupolas.
## Behind it the nave with its clerestory over buttressed aisles, the
## 68 m transept with rose windows (Saints Joachim and Anne at the
## Bailen front), the polygonal apse, and the slate dome on a pilastered
## drum with its lantern and cross at 73 m.
static func almudena(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#DAD6C9", 3.0))
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#A7A49C", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("slate", "#5F656A", 3.0))
	lm.use("Dome", LandmarkMaterials.pbr("slate", "#7F8A8E", 3.0))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#3B3833", 3.0))
	lm.use("Gilt", LandmarkMaterials.gold())
	lm.use("Steps", LandmarkMaterials.pbr("pavement", "#B9B1A2", 3.0))
	lm.use("Glass", LandmarkMaterials.glass())
	lm.use("Bronze", LandmarkMaterials.paint("#4A4436", 0.45, 0.7))
	# Nave with clerestory, aisles with buttresses and windows.
	lm.box("Stone", Vector3(0, 13.0, -1.0), Vector3(22.0, 26.0, 78.0))
	lm.gable("Roof", Vector3(0, 26.0, -1.0), 22.0, 78.0, 7.5, Basis(), 0.6)
	for s in [-1.0, 1.0]:
		var sn := Vector3(s, 0, 0)
		lm.box("Stone", Vector3(s * 16.5, 8.5, 0.0), Vector3(11.0, 17.0, 74.0))
		LandmarkCeParts.hip(lm, "Roof", Vector3(s * 16.5, 17.0, 0.0), 11.0, 74.0, 2.2)
		LandmarkIbParts.band(lm, "Granite", Vector3(s * 22.0, 0, 0), Vector3(0, 0, 1), sn, 74.0, 1.2, 2.4, 0.4)
		LandmarkIbParts.band(lm, "Stone", Vector3(s * 22.0, 0, 0), Vector3(0, 0, 1), sn, 74.0, 16.4, 1.0, 0.6)
		LandmarkIbParts.band(lm, "Stone", Vector3(s * 11.0, 0, -1.0), Vector3(0, 0, 1), sn, 78.0, 25.4, 1.0, 0.7)
		for z in [-30.0, -18.0, -6.0, 18.0, 30.0]:
			LandmarkIbParts.buttress(lm, "Granite", Vector3(s * 22.0, 0, z), sn, 1.6, 1.8, 16.0)
			LandmarkDetail.window(lm, "Stone", "Glass", Vector3(s * 22.0, 9.0, z + 6.0), sn, 2.2, 5.0, true)
			LandmarkDetail.window(lm, "Stone", "Glass", Vector3(s * 11.0, 21.4, z + 6.0), sn, 2.4, 5.4, true)
			lm.box("Stone", Vector3(s * 11.5, 21.0, z), Vector3(1.2, 8.0, 1.2))
		LandmarkDetail.window(lm, "Stone", "Glass", Vector3(s * 22.0, 9.0, -30.0 + 6.0 - 12.0), sn, 2.2, 5.0, true)
	# Transept, 68 m across, with a portal and a rose at each end.
	lm.box("Stone", Vector3(0, 13.0, 5.0), Vector3(68.0, 26.0, 18.0))
	lm.gable("Roof", Vector3(0, 26.0, 5.0), 18.0, 68.0, 6.5, Basis(Vector3.UP, PI * 0.5), 0.6)
	LandmarkDetail.window(lm, "Stone", "Glass", Vector3(0, 20.0, 14.0), Vector3(0, 0, 1), 3.0, 6.0, true)
	for s in [-1.0, 1.0]:
		var en := Vector3(s, 0, 0)
		var ef := Vector3(s * 34.0, 0, 5.0)
		lm.gable("Stone", ef + Vector3(s * 0.3, 26.0, 0), 18.0, 0.6, 6.5, Basis(Vector3.UP, PI * 0.5), 0.0, "Stone")
		LandmarkIbParts.portal(lm, "Stone", "Bronze", ef, Vector3.UP.cross(en), en, 3.6, 7.0, 1, 0.8)
		_rose(lm, ef + Vector3(0, 17.0, 0) + en * 0.05, en, 4.2)
		for z in [-7.0, 7.0]:
			LandmarkIbParts.buttress(lm, "Granite", ef + Vector3(0, 0, z), en, 1.8, 2.0, 25.0)
		LandmarkIbParts.rail(lm, "Stone", ef + Vector3(0, 26.0, -8.5) + en * 0.3, ef + Vector3(0, 26.0, 8.5) + en * 0.3, 1.0, 4.2)
		if s < 0.0:
			for z in [-3.6, 3.6]:
				LandmarkIbParts.statue(lm, "Granite", "Stone", ef + Vector3(-1.2, 0, z), 1.8, 2.6)
	# Apse: ten-sided, windowed between buttresses, slate cone.
	lm.frustum("Stone", Vector3(0, 0, -38.0), 12.5, 12.5, 25.0, 10, PI / 10.0)
	lm.frustum("Roof", Vector3(0, 25.0, -38.0), 13.4, 0.5, 10.0, 10, PI / 10.0)
	for i in 10:
		var a := PI / 10.0 + TAU * float(i) / 10.0
		var d := Vector3(cos(a), 0, sin(a))
		if d.z > 0.45:
			continue
		LandmarkIbParts.buttress(lm, "Granite", Vector3(0, 0, -38.0) + d * 12.4, d, 1.4, 1.6, 22.0)
		var m := a + PI / 10.0
		var dm := Vector3(cos(m), 0, sin(m))
		LandmarkDetail.window(lm, "Stone", "Glass", Vector3(0, 0, -38.0) + dm * 11.9 + Vector3(0, 9.0, 0), dm, 2.0, 5.0, true)
		LandmarkDetail.window(lm, "Stone", "Glass", Vector3(0, 0, -38.0) + dm * 11.9 + Vector3(0, 19.0, 0), dm, 1.8, 4.0, true)
	# Crossing: pilastered drum with sixteen windows, ribbed slate dome,
	# lantern and the cross at 73 m.
	var c := Vector3(0, 0, 5.0)
	lm.box("Stone", c + Vector3(0, 28.0, 0), Vector3(28.0, 4.0, 28.0))
	LandmarkKits.dome_on_drum(lm, "Stone", "Dome", c + Vector3(0, 30.0, 0), 12.2, 11.0, 15.0, 13.0, 48, 16)
	LandmarkCeParts.arched_ring(lm, "Stone", "Glass", c + Vector3(0, 33.0, 0), 12.2, 16, 1.8, 5.2)
	lm.lathe("Gilt", c + Vector3(0, 68.8, 0), SEuUtil.dome(0.45, 0.6, 5), 10)
	LandmarkCeParts.cross(lm, "Gilt", c + Vector3(0, 69.3, 0), ALM_TOP - 69.3)
	_almudena_front(lm)
	lm.commit(model)

## Rose window of radius rr on a wall facing n: moulded ring, glass,
## twelve spokes and an inner ring.
static func _rose(lm: LandmarkMesh, c: Vector3, n: Vector3, rr: float) -> void:
	var nn := n.normalized()
	var a := Vector3.UP.cross(nn).normalized()
	lm.disc("Glass", c + nn * 0.02, nn, rr, 24)
	var prev := c + a * rr
	for i in 24:
		var t := TAU * float(i + 1) / 24.0
		var p := c + (a * cos(t) + Vector3.UP * sin(t)) * rr
		lm.beam("Stone", prev + nn * 0.2, p + nn * 0.2, 0.45, 0.5, nn)
		prev = p
	for i in 12:
		var t := TAU * float(i) / 12.0
		lm.beam("Stone", c + (a * cos(t) + Vector3.UP * sin(t)) * rr * 0.3 + nn * 0.15,
			c + (a * cos(t) + Vector3.UP * sin(t)) * rr + nn * 0.15, 0.18, 0.3, nn)
	var prev2 := c + a * rr * 0.3
	for i in 12:
		var t := TAU * float(i + 1) / 12.0
		var p := c + (a * cos(t) + Vector3.UP * sin(t)) * rr * 0.3
		lm.beam("Stone", prev2 + nn * 0.15, p + nn * 0.15, 0.3, 0.35, nn)
		prev2 = p

## The north front: two orders between the towers, the steps.
static func _almudena_front(lm: LandmarkMesh) -> void:
	var zn := Vector3(0, 0, 1)
	lm.box("Stone", Vector3(0, 16.0, 45.0), Vector3(56.0, 32.0, 14.0))
	lm.box("Granite", Vector3(0, 4.0, 45.2), Vector3(57.0, 8.0, 14.4))
	lm.box("Stone", Vector3(0, 31.0, 45.0), Vector3(58.0, 2.0, 16.0))
	LandmarkIbParts.rail(lm, "Stone", Vector3(-28.0, 32.0, 52.4), Vector3(28.0, 32.0, 52.4), 1.4, 7.0, true)
	# Wings between the body and the towers: niches with saints above.
	for s in [-1.0, 1.0]:
		LandmarkIbParts.portal(lm, "Stone", "Shadow", Vector3(s * 12.0, 9.0, 52.1), Vector3.RIGHT, zn, 2.2, 5.0, 1, 0.4)
		LandmarkIbParts.statue(lm, "Stone", "Stone", Vector3(s * 12.0, 9.0, 52.3), 0.3, 3.4)
		LandmarkIbParts.portal(lm, "Stone", "Shadow", Vector3(s * 12.0, 20.0, 52.1), Vector3.RIGHT, zn, 2.2, 5.0, 1, 0.4)
		LandmarkIbParts.statue(lm, "Stone", "Stone", Vector3(s * 12.0, 20.0, 52.3), 0.3, 3.4)
		for j in 2:
			LandmarkIbParts.statue(lm, "Stone", "Stone", Vector3(s * (11.0 + 3.6 * float(j)), 32.0, 51.6), 1.2, 3.0)
	# Central body: lower order of paired Tuscan columns in granite.
	lm.box("Stone", Vector3(0, 16.0, 51.5), Vector3(26.0, 32.0, 2.0))
	lm.box("Granite", Vector3(0, 1.5, 54.0), Vector3(28.0, 3.0, 5.0))
	for x in [-10.8, -8.8, -3.6, 3.6, 8.8, 10.8]:
		LandmarkDetail.column(lm, "Granite", Vector3(x, 3.0, 54.6), 0.7, 12.4, "tuscan", 0)
	lm.box("Stone", Vector3(0, 16.2, 54.4), Vector3(26.0, 1.6, 2.4))
	LandmarkDetail.cornice(lm, "Stone", Vector3(-13.6, 17.0, 55.6), Vector3(13.6, 17.0, 55.6), zn, 1.0, true)
	LandmarkIbParts.portal(lm, "Stone", "Bronze", Vector3(0, 3.0, 52.5), Vector3.RIGHT, zn, 4.0, 9.0, 1, 0.6)
	for s in [-1.0, 1.0]:
		LandmarkIbParts.portal(lm, "Stone", "Bronze", Vector3(s * 6.2, 3.0, 52.5), Vector3.RIGHT, zn, 2.4, 6.4, 1, 0.5)
		LandmarkIbParts.statue(lm, "Granite", "Bronze", Vector3(s * 6.2, 3.0, 56.4), 1.4, 3.0)
	# Upper order: Ionic columns, the Virgin's niche and the evangelists.
	for x in [-10.8, -8.8, -3.6, 3.6, 8.8, 10.8]:
		LandmarkDetail.column(lm, "Stone", Vector3(x, 18.0, 54.0), 0.55, 10.6, "ionic", 0)
	lm.box("Stone", Vector3(0, 29.4, 53.8), Vector3(26.0, 1.4, 2.4))
	LandmarkDetail.cornice(lm, "Stone", Vector3(-13.6, 30.1, 55.0), Vector3(13.6, 30.1, 55.0), zn, 0.9, true)
	LandmarkIbParts.portal(lm, "Stone", "Shadow", Vector3(0, 19.4, 52.5), Vector3.RIGHT, zn, 3.6, 7.6, 1, 0.5)
	LandmarkIbParts.statue(lm, "Stone", "Gilt", Vector3(0, 19.4, 52.8), 0.6, 4.2)
	for x in [-6.2, 6.2]:
		LandmarkIbParts.portal(lm, "Stone", "Shadow", Vector3(x, 20.0, 52.5), Vector3.RIGHT, zn, 1.8, 4.6, 1, 0.3)
		LandmarkIbParts.statue(lm, "Stone", "Stone", Vector3(x, 20.0, 52.7), 0.3, 3.2)
	for x in [-9.8, 9.8]:
		LandmarkIbParts.urn(lm, "Stone", Vector3(x, 31.0, 54.4), 1.4)
	# Pediment with the arms.
	lm.gable("Stone", Vector3(0, 31.0, 54.0), 27.0, 4.0, 5.5, Basis(), 0.3, "Stone")
	lm.disc("Gilt", Vector3(0, 33.4, 56.05), zn, 1.6, 16)
	lm.box("Stone", Vector3(0, 37.4, 54.0), Vector3(1.0, 1.4, 1.0))
	LandmarkCeParts.cross(lm, "Gilt", Vector3(0, 38.1, 54.0), 2.6)
	for s in [-1.0, 1.0]:
		_almudena_tower(lm, Vector3(s * 21.5, 0, 47.0))
	# Steps and forecourt.
	for k in 5:
		var sh := 0.6 * float(5 - k)
		lm.box("Steps", Vector3(0, sh * 0.5, 57.2 + 1.2 * float(k)), Vector3(30.0 + 3.0 * float(k), sh, 1.2))

## One front tower, 60 m to the vane: granite base, windowed shaft,
## cornice and balustrade, the belfry stage with an arched opening and
## pilasters on each face, an octagonal drum and the cupola.
static func _almudena_tower(lm: LandmarkMesh, t: Vector3) -> void:
	lm.box("Stone", t + Vector3(0, 20.0, 0), Vector3(12.0, 40.0, 12.0))
	lm.box("Granite", t + Vector3(0, 4.0, 0), Vector3(12.6, 8.0, 12.6))
	lm.box("Stone", t + Vector3(0, 40.5, 0), Vector3(13.4, 1.0, 13.4))
	lm.box("Stone", t + Vector3(0, 45.0, 0), Vector3(9.0, 8.0, 9.0))
	lm.box("Stone", t + Vector3(0, 49.3, 0), Vector3(10.0, 0.6, 10.0))
	for k in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * float(k))
		var out := r * Vector3(0, 0, 1)
		var right := r * Vector3(1, 0, 0)
		LandmarkDetail.window(lm, "Stone", "Glass", t + out * 6.0 + Vector3(0, 23.0, 0), out, 2.2, 5.0, true)
		LandmarkDetail.window(lm, "Stone", "Glass", t + out * 6.0 + Vector3(0, 33.0, 0), out, 2.0, 4.0, false)
		LandmarkIbParts.pilaster_row(lm, "Stone", t + out * 6.0, right, out, 2, 10.6, 1.0, 0.4, 8.0, 39.8)
		LandmarkIbParts.rail(lm, "Stone", t + out * 6.4 - right * 6.2 + Vector3(0, 41.0, 0),
			t + out * 6.4 + right * 6.2 + Vector3(0, 41.0, 0), 1.0, 6.2, true)
		LandmarkIbParts.portal(lm, "Stone", "Shadow", t + out * 4.5 + Vector3(0, 41.6, 0), right, out, 2.6, 6.0, 1, 0.4)
		LandmarkIbParts.pilaster_row(lm, "Stone", t + out * 4.5, right, out, 2, 7.6, 0.8, 0.35, 41.0, 49.0)
	lm.frustum("Stone", t + Vector3(0, 49.6, 0), 4.0, 4.0, 1.4, 8, PI / 8.0)
	lm.lathe("Dome", t + Vector3(0, 51.0, 0), SEuUtil.dome(4.2, 4.4, 8), 16)
	for i in 8:
		var a := TAU * float(i) / 8.0
		lm.beam("Dome", t + Vector3(cos(a) * 4.25, 51.0, sin(a) * 4.25),
			t + Vector3(cos(a) * 1.0, 55.0, sin(a) * 1.0), 0.3, 0.2)
	lm.frustum("Stone", t + Vector3(0, 55.2, 0), 0.9, 0.8, 1.6, 8)
	lm.lathe("Dome", t + Vector3(0, 56.8, 0), SEuUtil.dome(1.0, 0.8, 4), 8)
	LandmarkCeParts.cross(lm, "Gilt", t + Vector3(0, 57.6, 0), 2.4)
