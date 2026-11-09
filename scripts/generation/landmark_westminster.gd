class_name LandmarkWestminster
extends RefCounted

## Elizabeth Tower ("Big Ben", 96 m) with the Palace of Westminster in
## true metres, on the palace's own axis (the registry yaw of 6.2 deg
## turns the model onto it): the 12 m square Anston-limestone shaft with
## Perpendicular Gothic panelling (tiers of paired lancets between blind
## tracery panels, clasping corner buttresses, string courses), four 7 m
## opal clock dials at 55 m in gilt square surrounds with iron tracery and
## the DOMINE SALVAM FAC REGINAM band, the gabled clock stage with
## crocketed corner pinnacles, the arcaded belfry, and the steep
## cast-iron spire with two tiers of lucarnes, the Ayrton Light lantern,
## spirelet, orb and cross. The tower stands at the palace's north-west
## corner; the ranges (LandmarkWestminsterRanges) and the Hall, Central
## Tower and Victoria Tower (LandmarkWestminsterTowers) are placed from
## the OpenStreetMap parts of the palace (LandmarkWestminsterPlan).
## +Z runs south along the river front, the Thames lies east (+X).

const SHAFT_TOP := 50.0
const DIAL_Y := 55.0
const STAGE_TOP := 61.0
const BELFRY_TOP := 72.0
const TOP := 96.0

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#C9B488", 3.0))
	lm.use("Palace", LandmarkMaterials.pbr("limestone", "#C2AD84", 3.5))
	lm.use("Roof", LandmarkMaterials.pbr("slate", "#4A5254", 2.0))
	lm.use("Iron", LandmarkMaterials.paint("#2C3236", 0.55, 0.4))
	lm.use("Gilt", LandmarkMaterials.gold())
	lm.use("Dial", LandmarkMaterials.lit("#F2EEDF", 0.35))
	lm.use("Windows", LandmarkMaterials.glass("#252C30"))
	_elizabeth(lm)
	LandmarkWestminsterRanges.build(lm)
	LandmarkWestminsterTowers.build(lm)
	lm.commit(model)

static func _face_basis(side: int) -> Basis:
	return Basis(Vector3.UP, PI * 0.5 * float(side))

static func _elizabeth(lm: LandmarkMesh) -> void:
	var w := 12.0
	lm.box("Stone", Vector3(0, 1.5, 0), Vector3(w + 1.2, 3.0, w + 1.2))  # plinth
	lm.box("Stone", Vector3(0, SHAFT_TOP * 0.5, 0), Vector3(w, SHAFT_TOP, w))
	for side in 4:
		var rot := _face_basis(side)
		var out := rot * Vector3(0, 0, 1)
		var rt := rot * Vector3(1, 0, 0)
		var face := out * w * 0.5
		# Clasping corner buttresses, set back in three stages.
		for kv in [-1.0, 1.0]:
			var k: float = kv
			LandmarkCoreAGothic.buttress(lm, "Stone", face + rt * k * (w * 0.5 - 0.45), out, 0.9, 0.6,
				SHAFT_TOP, 3)
		# Tiers: two lancet windows flanked by blind tracery panels,
		# a string course over each tier, panel mullions between.
		for row in 8:
			var y := 5.0 + float(row) * 5.4
			for i in 4:
				var x := -3.6 + 2.4 * float(i)
				var lit := i == 1 or i == 2
				LandmarkCoreAGothic.lancet(lm, "Stone", "Windows" if lit else "Stone", face + rt * x + Vector3(0, y, 0),
					out, 1.3, 3.4, 0.22, 1, 0.75, lit, 0.16)
			lm.box("Stone", face + Vector3(0, y + 4.4, 0) + out * 0.15, Vector3(w - 1.8, 0.35, 0.3), rot, 0.0)
		for m in 5:
			var x := -4.8 + 2.4 * float(m)
			lm.box("Stone", face + rt * x + Vector3(0, 26.0, 0) + out * 0.1, Vector3(0.22, 44.0, 0.2), rot, 0.0)
	_clock_stage(lm, w)
	_belfry_spire(lm, w)

## Clock stage: slightly wider block; each face a gilt square surround,
## the opal dial with its iron tracery, numerals and hands, the
## inscription band, a gable over the dial; crocketed corner pinnacles.
static func _clock_stage(lm: LandmarkMesh, w: float) -> void:
	var sw := w + 1.4
	lm.box("Stone", Vector3(0, (SHAFT_TOP + STAGE_TOP) * 0.5, 0), Vector3(sw, STAGE_TOP - SHAFT_TOP, sw))
	lm.box("Stone", Vector3(0, SHAFT_TOP + 0.4, 0), Vector3(sw + 0.6, 0.8, sw + 0.6))
	for side in 4:
		var rot := _face_basis(side)
		var out := rot * Vector3(0, 0, 1)
		var rt := rot * Vector3(1, 0, 0)
		var c := rot * Vector3(0, DIAL_Y, sw * 0.5)
		lm.box("Gilt", c + out * 0.15, Vector3(8.2, 8.2, 0.3), rot)
		lm.box("Stone", c + out * 0.32, Vector3(7.6, 7.6, 0.06), rot, 0.0)
		lm.disc("Dial", c + out * 0.38, out, 3.5, 40)
		# Iron tracery in the opal glass: rim, inner ring, radial bars.
		for ring in [3.5, 2.3]:
			var rr: float = ring
			for i in 24:
				var a0 := TAU * float(i) / 24.0
				var a1 := TAU * float(i + 1) / 24.0
				lm.beam("Iron", c + out * 0.42 + (rt * cos(a0) + Vector3.UP * sin(a0)) * rr,
					c + out * 0.42 + (rt * cos(a1) + Vector3.UP * sin(a1)) * rr, 0.14, 0.06, out)
		for h in 12:
			var a := TAU * float(h) / 12.0
			var d := rt * sin(a) + Vector3.UP * cos(a)
			lm.beam("Iron", c + out * 0.41 + d * 0.5, c + out * 0.41 + d * 2.3, 0.07, 0.04, out)
			lm.box("Iron", c + out * 0.44 + d * 2.9, Vector3(0.22, 0.6, 0.08), rot * Basis(Vector3.BACK, -a), 0.0)
			# Gilt minute marks between the numerals.
			lm.box("Gilt", c + out * 0.44 + d * 3.35, Vector3(0.1, 0.22, 0.06), rot * Basis(Vector3.BACK, -a), 0.0)
		lm.beam("Iron", c + out * 0.5, c + out * 0.5 + rot * Vector3(1.6, 1.4, 0), 0.22, 0.08, out)
		lm.beam("Iron", c + out * 0.5, c + out * 0.5 + rot * Vector3(-0.4, 2.9, 0), 0.16, 0.08, out)
		lm.disc("Gilt", c + out * 0.55, out, 0.3, 12)
		# Gilt spandrel bosses in the surround's corners.
		for sx in [-1.0, 1.0]:
			for sy in [-1.0, 1.0]:
				lm.disc("Gilt", c + out * 0.34 + rt * float(sx) * 3.4 + Vector3(0, float(sy) * 3.4, 0), out, 0.45, 10)
		# Inscription band under the dial.
		lm.box("Gilt", c + Vector3(0, -4.6, 0) + out * 0.12, Vector3(8.6, 0.5, 0.24), rot, 0.0)
		# Gable over each dial, with its own crockets and finial.
		lm.gable("Stone", rot * Vector3(0, STAGE_TOP, sw * 0.5 - 1.0), 8.0, 2.0, 4.0, rot, 0.1, "Stone")
		for kv in [-1.0, 1.0]:
			var k: float = kv
			lm.beam("Stone", rot * Vector3(k * 4.1, STAGE_TOP + 0.1, sw * 0.5 + 0.05),
				rot * Vector3(0, STAGE_TOP + 4.1, sw * 0.5 + 0.05), 0.35, 0.35, out)
		LandmarkCoreAGothic.lancet(lm, "Stone", "Windows", rot * Vector3(0, STAGE_TOP + 0.3, sw * 0.5),
			out, 1.6, 2.6, 0.2, 1, 0.8, false, 0.15)
		lm.frustum("Gilt", rot * Vector3(0, STAGE_TOP + 4.0, sw * 0.5), 0.15, 0.05, 1.6, 6)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var p := Vector3(float(sx) * sw * 0.5, STAGE_TOP - 2.0, float(sz) * sw * 0.5)
			lm.frustum("Stone", p, 0.8, 0.8, 2.0, 8)
			LandmarkCoreAGothic.pinnacle(lm, "Stone", p + Vector3(0, 2.0, 0), 0.7, 6.0)
			lm.frustum("Gilt", p + Vector3(0, 7.6, 0), 0.08, 0.02, 1.2, 6)

## Belfry (the Great Bell's chamber): four tall louvred openings a side
## between piers; then the spire — steep cast-iron pyramid with two
## tiers of gabled lucarnes, gilt corner pinnacles, the Ayrton Light
## lantern, the spirelet and the orb and cross at 96 m.
static func _belfry_spire(lm: LandmarkMesh, w: float) -> void:
	var sw := w + 1.4
	var bw := w - 0.6
	lm.box("Stone", Vector3(0, STAGE_TOP + 0.6, 0), Vector3(sw, 1.2, sw))
	lm.box("Stone", Vector3(0, (STAGE_TOP + BELFRY_TOP) * 0.5, 0), Vector3(bw - 1.2, BELFRY_TOP - STAGE_TOP, bw - 1.2))
	for side in 4:
		var rot := _face_basis(side)
		var out := rot * Vector3(0, 0, 1)
		var face := out * (bw - 1.2) * 0.5
		for k in 4:
			var x := -bw * 0.5 + bw * (float(k) + 0.5) / 4.0
			LandmarkCoreAGothic.lancet(lm, "Stone", "Iron", face + rot * Vector3(x, STAGE_TOP + 2.2, 0), out,
				1.9, 7.4, 0.55, 1, 1.0, true, 0.2)
		for k in 5:
			var x := -bw * 0.5 + bw * float(k) / 4.0
			lm.box("Stone", rot * Vector3(x, STAGE_TOP + 5.5, bw * 0.5 - 0.3), Vector3(0.7, 9.8, 1.1), rot)
		LandmarkCoreAGothic.parapet(lm, "Stone", rot * Vector3(-bw * 0.5, BELFRY_TOP - 1.2, bw * 0.5),
			rot * Vector3(bw * 0.5, BELFRY_TOP - 1.2, bw * 0.5), out, 1.0, 0.4, 2.9)
	lm.box("Stone", Vector3(0, BELFRY_TOP - 0.6, 0), Vector3(bw + 0.8, 1.2, bw + 0.8))
	lm.spire("Iron", Vector3(0, BELFRY_TOP, 0), bw * 0.5, 12.0, 2.4)
	# Lucarnes: three gabled dormers on the lower tier, one above.
	for side in 4:
		var rot := _face_basis(side)
		var out := rot * Vector3(0, 0, 1)
		for tier in 2:
			var n := 3 if tier == 0 else 1
			var y := BELFRY_TOP + 1.2 + 5.2 * float(tier)
			var half := lerpf(bw * 0.5, 2.4, (y - BELFRY_TOP) / 12.0)
			for i in n:
				var x := (float(i) - float(n - 1) * 0.5) * 2.6
				var p := rot * Vector3(x, y, half - 0.3)
				lm.box("Iron", p + Vector3(0, 1.0, 0) + out * 0.4, Vector3(1.2, 2.0, 1.4), rot)
				lm.gable("Iron", p + Vector3(0, 2.0, 0) + out * 0.4, 1.2, 1.4, 1.1, rot, 0.08, "Iron")
				lm.box("Gilt", p + Vector3(0, 1.0, 0) + out * 1.12, Vector3(0.6, 1.3, 0.04), rot, 0.0)
				lm.frustum("Gilt", p + Vector3(0, 3.1, 0) + out * 1.1, 0.06, 0.02, 0.7, 6)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			LandmarkCoreAGothic.pinnacle(lm, "Gilt", Vector3(float(sx) * bw * 0.42, BELFRY_TOP, float(sz) * bw * 0.42),
				0.45, 6.5)
	# Ayrton Light lantern: gilt gallery, glazed octagon between iron
	# shafts, then the spirelet, orb and cross.
	var ly := BELFRY_TOP + 12.0
	lm.frustum("Gilt", Vector3(0, ly, 0), 2.6, 2.6, 0.5, 8, PI / 8.0)
	lm.frustum("Windows", Vector3(0, ly + 0.5, 0), 2.1, 2.1, 3.0, 8, PI / 8.0)
	for k in 8:
		var a := TAU * float(k) / 8.0
		lm.beam("Iron", Vector3(cos(a) * 2.2, ly + 0.5, sin(a) * 2.2), Vector3(cos(a) * 2.2, ly + 3.5, sin(a) * 2.2),
			0.25, 0.25)
		lm.beam("Gilt", Vector3(cos(a) * 2.5, ly + 0.5, sin(a) * 2.5), Vector3(cos(a) * 2.5, ly + 1.4, sin(a) * 2.5),
			0.08, 0.08)
	lm.frustum("Gilt", Vector3(0, ly + 3.5, 0), 2.4, 2.3, 0.35, 8, PI / 8.0)
	lm.spire("Iron", Vector3(0, ly + 3.85, 0), 2.3, 6.2, 0.2)
	var fy := ly + 10.05
	lm.frustum("Gilt", Vector3(0, fy, 0), 0.25, 0.12, TOP - fy - 1.4, 6)
	lm.lathe("Gilt", Vector3(0, TOP - 2.2, 0), PackedVector2Array([Vector2(0.0, 0), Vector2(0.3, 0.12),
		Vector2(0.38, 0.35), Vector2(0.3, 0.58), Vector2(0.0, 0.7)]), 10)
	lm.box("Gilt", Vector3(0, TOP - 0.75, 0), Vector3(0.12, 1.5, 0.12), Basis(), 0.0)
	lm.box("Gilt", Vector3(0, TOP - 0.5, 0), Vector3(0.7, 0.12, 0.12), Basis(), 0.0)
