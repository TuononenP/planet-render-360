class_name LandmarkLpPersia
extends RefCounted

## Two ancient Near Eastern gateways in true metres: Persepolis (the Gate
## of All Nations and the Apadana on the terrace) and the reconstructed
## Ishtar Gate of Babylon.

# --- Persepolis ---

## Height of the terrace top above the Marvdasht plain.
const PLATFORM_H := 12.5

## Compass frame, y = 0 on the plain. A 215 x 170 m piece of the dark-grey
## limestone terrace with the double-return Great Stairway (111 shallow
## steps) on its west face; on it the Gate of All Nations of Xerxes as it
## stands (the mud-brick walls gone: the stone west doorway with its two
## colossal bulls, the east doorway with two winged human-headed lamassu,
## the south doorway, two of the four 16.5 m columns standing) and the
## Apadana on its own 2.6 m terrace with the north and east double stairs
## and their relief registers and the 14 columns (19.2 m, fluted, bell
## bases) that stand today: both rows of the north portico and two of the
## hall. Top of the capitals 34.3 m.
static func persepolis(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#7D786E", 4.0))
	lm.use("Terrace", LandmarkMaterials.pbr("rock", "#6E675B", 8.0))
	lm.use("Door", LandmarkMaterials.pbr("concrete", "#1B1713", 3.0, 0.92))
	var ph := PLATFORM_H
	lm.box("Terrace", Vector3(7.5, ph * 0.5, 0), Vector3(215, ph, 170))
	# Coursed ashlar of the retaining wall: projecting courses on the west face.
	for c in 5:
		lm.box("Terrace", Vector3(-100.15, 1.2 + 2.4 * float(c), 0), Vector3(0.3, 0.25, 170), Basis(), 0.0)
	lm.box("Marble", Vector3(7.5, ph + 0.15, 0), Vector3(215.6, 0.3, 170.6))
	_great_stairway(lm, -100.0, ph)
	_gate_of_all_nations(lm, Vector3(-62.5, ph, -15.0))
	_apadana(lm, Vector3(32.0, ph, 11.0))
	lm.commit(model)

## Double-return stair against the terrace's west face (x = face_x): two
## lower flights climb outward from the middle to landings, the upper
## flights turn back and climb to the terrace; parapets with stepped merlons.
static func _great_stairway(lm: LandmarkMesh, face_x: float, ph: float) -> void:
	var w := 7.0
	var run := 25.0
	var half := ph * 0.5
	for s in [-1.0, 1.0]:
		var sg := float(s)
		var z_in := sg * 4.0
		# Lower flight in the outer lane, rising away from the middle.
		LandmarkLpParts.steps(lm, "Marble", Vector3(face_x - w * 1.5, 0, z_in), Vector3(0, 0, sg), w, run, half, 28)
		# Landing at the outer end spanning both lanes.
		var lz := z_in + sg * (run + 3.5)
		lm.box("Marble", Vector3(face_x - w, half * 0.5, lz), Vector3(w * 2.0, half, 7.0))
		# Upper flight in the inner lane, rising back toward the middle.
		LandmarkLpParts.steps(lm, "Marble", Vector3(face_x - w * 0.5, half, z_in + sg * run), Vector3(0, 0, -sg),
			w, run, half, 28)
		lm.box("Marble", Vector3(face_x - w * 0.5, half * 0.5, z_in + sg * run * 0.5), Vector3(w, half, run))
		# Parapets: the outer edge of each flight and round the landing.
		var p0 := Vector3(face_x - w * 2.0 - 0.4, 0, z_in)
		var p1 := Vector3(face_x - w * 2.0 - 0.4, half, z_in + sg * run)
		lm.beam("Marble", p0 + Vector3(0, 0.6, 0), p1 + Vector3(0, 0.6, 0), 0.8, 1.2, Vector3.RIGHT)
		lm.box("Marble", Vector3(face_x - w - 0.4, half + 0.6, lz + sg * 3.1), Vector3(w * 2.0 + 0.8, 1.2, 0.8))
		lm.box("Marble", Vector3(face_x - w * 2.0 - 0.4, half + 0.6, lz), Vector3(0.8, 1.2, 7.0))
		LandmarkLpDetail.stepped_merlons(lm, "Marble", Vector3(face_x - w * 2.0 - 0.4, half + 1.2, lz - 3.5),
			Vector3(face_x - w * 2.0 - 0.4, half + 1.2, lz + 3.5), 0.9, 0.9, 0.6, 1.4)
		var q0 := Vector3(face_x - w - 0.2, half, z_in + sg * run)
		var q1 := Vector3(face_x - w - 0.2, ph, z_in)
		lm.beam("Marble", q0 + Vector3(0, 0.6, 0), q1 + Vector3(0, 0.6, 0), 0.6, 1.2, Vector3.RIGHT)

## The Gate of Xerxes (a 25 m square hall): the stone doorways and their
## guardian colossi, the column positions and the wall footings.
static func _gate_of_all_nations(lm: LandmarkMesh, g: Vector3) -> void:
	# Wall footings of the vanished mud-brick walls.
	for s in [-1.0, 1.0]:
		lm.box("Marble", g + Vector3(float(s) * 11.0, 0.4, 0), Vector3(3.2, 0.8, 25.0))
		lm.box("Marble", g + Vector3(0, 0.4, float(s) * 11.0), Vector3(25.0, 0.8, 3.2))
	lm.box("Door", g + Vector3(0, 0.03, 0), Vector3(19.0, 0.06, 19.0), Basis(), 0.0)
	# West (bulls) and east (lamassu) doorways: two 10.2 m piers each.
	for side in [-1.0, 1.0]:
		var sx := float(side)
		for t in [-1.0, 1.0]:
			var pz := float(t) * 2.85
			var pc := g + Vector3(sx * 11.0, 0, pz)
			lm.box("Marble", pc + Vector3(0, 0.4, 0), Vector3(6.4, 0.8, 2.4))
			lm.box("Marble", pc + Vector3(0, 5.1, 0), Vector3(5.8, 10.2, 1.9))
			lm.box("Marble", pc + Vector3(0, 9.6, 0), Vector3(6.0, 0.5, 2.1))
			# Colossus carved out of the pier, face out of the gate, flank on the passage.
			_colossus(lm, pc + Vector3(0, 0.8, -float(t) * 1.25), sx, sx > 0.0)
			# Inscription panel above.
			lm.box("Marble", pc + Vector3(0, 8.6, -float(t) * 0.96), Vector3(3.6, 1.2, 0.06), Basis(), 0.0)
	# South doorway towards the Apadana: plainer jambs and the threshold.
	for t in [-1.0, 1.0]:
		lm.box("Marble", g + Vector3(float(t) * 2.6, 3.6, 11.0), Vector3(1.6, 7.2, 3.6))
		lm.box("Marble", g + Vector3(float(t) * 2.6, 7.35, 11.0), Vector3(1.8, 0.3, 3.8))
	# Four columns in the hall: two stand to the double-bull capitals.
	var cols := [Vector3(-5.5, 0, -5.5), Vector3(5.5, 0, -5.5), Vector3(-5.5, 0, 5.5), Vector3(5.5, 0, 5.5)]
	for i in 4:
		var p: Vector3 = g + (cols[i] as Vector3)
		if i < 2:
			_column(lm, "Marble", p, 16.5, 0.65, true)
		else:
			_bell_base(lm, "Marble", p, 0.65)

## Colossal guardian (5.5 m) standing along X, its forepart at the pier's
## outer end (dir = +1 east): body, five legs (two seen from the front),
## folded wings, chest, a bull's head (or a bearded human head with a
## horned cylindrical tiara when `human`).
static func _colossus(lm: LandmarkMesh, base: Vector3, dir: float, human: bool) -> void:
	var b := Basis()
	lm.box("Marble", base + Vector3(-dir * 0.2, 2.6, 0), Vector3(4.2, 1.8, 1.1), b)
	for x in [-1.6, -0.7, 1.1, 1.85]:
		lm.box("Marble", base + Vector3(dir * float(x), 0.85, 0), Vector3(0.5, 1.7, 0.8), b)
	lm.box("Marble", base + Vector3(dir * 2.05, 0.85, 0.0), Vector3(0.35, 1.7, 1.0), b)
	lm.box("Marble", base + Vector3(dir * 1.6, 3.2, 0), Vector3(1.1, 2.4, 1.2), b)
	# Wing: four tiers of feathers sweeping back from the shoulder.
	for k in 4:
		lm.box("Marble", base + Vector3(-dir * (0.2 + 0.25 * float(k)), 3.7 + 0.35 * float(k), 0),
			Vector3(3.4 - 0.5 * float(k), 0.32, 1.15), b)
	var hc := base + Vector3(dir * 2.0, 4.6, 0)
	if human:
		lm.lathe("Marble", hc, PackedVector2Array([Vector2(0.5, 0), Vector2(0.55, 0.4), Vector2(0.5, 0.75),
			Vector2(0.3, 0.9)]), 10, 1.0, 0.9)
		lm.box("Marble", hc + Vector3(dir * 0.3, -0.35, 0), Vector3(0.5, 1.0, 0.8), b)
		lm.frustum("Marble", hc + Vector3(0, 0.75, 0), 0.5, 0.55, 0.8, 12)
		for k in 3:
			lm.frustum("Marble", hc + Vector3(0, 0.8 + 0.25 * float(k), 0), 0.58, 0.58, 0.06, 12)
	else:
		lm.box("Marble", hc + Vector3(dir * 0.35, -0.2, 0), Vector3(1.1, 0.8, 0.8), b)
		for s in [-1.0, 1.0]:
			lm.beam("Marble", hc + Vector3(0, 0.25, float(s) * 0.35), hc + Vector3(dir * 0.2, 0.75, float(s) * 0.7), 0.16)

## Fluted Achaemenid column of height h (to the top of the capital):
## square plinth, bell base with lotus petals, 40-flute shaft, and, when
## `capital`, the palm-leaf bell, the vertical double volutes and the
## kneeling double-bull protome block; else the shaft ends broken.
static func _column(lm: LandmarkMesh, key: String, base: Vector3, h: float, r: float, capital: bool) -> void:
	_bell_base(lm, key, base, r)
	var cap_h := h * 0.25 if capital else 0.0
	var sb := base + Vector3(0, 2.2, 0)
	var shaft_h := h - 2.2 - cap_h
	LandmarkDetail._fluted_shaft(lm, key, sb, r, shaft_h, 40)
	if not capital:
		return
	var cb := sb + Vector3(0, shaft_h, 0)
	var u := cap_h
	# Palm / bell: drooping leaves, then an upturned calyx (0.3 of the capital).
	lm.lathe(key, cb, PackedVector2Array([Vector2(r * 0.85, 0), Vector2(r * 1.2, u * 0.06),
		Vector2(r * 1.25, u * 0.11), Vector2(r * 0.95, u * 0.16), Vector2(r * 1.15, u * 0.24),
		Vector2(r * 1.45, u * 0.3)]), 16)
	# Vertical double volutes (four scrolls on a slab), 0.35.
	var vb := cb + Vector3(0, u * 0.3, 0)
	lm.box(key, vb + Vector3(0, u * 0.175, 0), Vector3(r * 1.5, u * 0.35, r * 1.5))
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			lm.frustum(key, vb + Vector3(float(sx) * r * 0.5, u * 0.04, float(sz) * r * 0.78), r * 0.32, r * 0.32,
				u * 0.28, 10)
	# Double-bull protome: two foreparts back to back, kneeling (0.35).
	var pb := vb + Vector3(0, u * 0.35, 0)
	lm.box(key, pb + Vector3(0, u * 0.06, 0), Vector3(r * 2.2, u * 0.12, r * 1.5))
	for s in [-1.0, 1.0]:
		var sd := float(s)
		lm.box(key, pb + Vector3(sd * r * 1.6, u * 0.16, 0), Vector3(r * 1.6, u * 0.2, r * 1.3))
		lm.box(key, pb + Vector3(sd * r * 2.5, u * 0.25, 0), Vector3(r * 0.8, u * 0.16, r * 0.8))
		lm.box(key, pb + Vector3(sd * r * 1.9, u * 0.03, 0), Vector3(r * 0.9, u * 0.06, r * 1.0))
	lm.box(key, pb + Vector3(0, u * 0.3, 0), Vector3(r * 2.6, u * 0.1, r * 1.2))

## Square plinth and a bell-shaped base of hanging lotus petals.
static func _bell_base(lm: LandmarkMesh, key: String, base: Vector3, r: float) -> void:
	lm.box(key, base + Vector3(0, 0.25, 0), Vector3(r * 3.6, 0.5, r * 3.6))
	lm.lathe(key, base + Vector3(0, 0.5, 0), PackedVector2Array([Vector2(r * 1.75, 0.0), Vector2(r * 1.7, 0.2),
		Vector2(r * 1.45, 0.6), Vector2(r * 1.15, 1.1), Vector2(r * 1.05, 1.4), Vector2(r * 1.2, 1.5),
		Vector2(r * 1.2, 1.6), Vector2(r * 1.02, 1.7)]), 16)
	for k in 12:
		var a := TAU * float(k) / 12.0
		var d := Vector3(cos(a), 0, sin(a))
		lm.beam(key, base + d * r * 1.72 + Vector3(0, 0.55, 0), base + d * r * 1.12 + Vector3(0, 1.55, 0),
			r * 0.55, r * 0.08, d.cross(Vector3.UP))

## The Apadana on its 2.6 m platform: the north and east double stairs
## with parapets and relief registers, and the 14 standing columns.
static func _apadana(lm: LandmarkMesh, a: Vector3) -> void:
	var ay := a.y + 2.6
	lm.box("Marble", Vector3(a.x, a.y + 1.3, a.z), Vector3(110, 2.6, 110))
	lm.box("Marble", Vector3(a.x, ay - 0.1, a.z), Vector3(110.6, 0.2, 110.6))
	for out in [Vector3(0, 0, -1), Vector3(1, 0, 0)]:
		var along := Vector3(-out.z, 0, out.x)
		var face := Vector3(a.x, a.y, a.z) + (out as Vector3) * 55.0
		for s in [-1.0, 1.0]:
			# Two flights rising inward toward the centre of each facade.
			LandmarkLpParts.steps(lm, "Marble", face + along * (float(s) * 34.0) + out * 3.25, -along * float(s),
				6.5, 13.0, 2.6, 13)
		# Central projection with its relief registers (tribute bearers).
		lm.box("Marble", face + out * 3.25 + Vector3(0, 1.7, 0),
			Vector3(absf(along.x) * 42.0 + absf(out.x) * 6.5, 3.4, absf(along.z) * 42.0 + absf(out.z) * 6.5))
		var basis := Basis.looking_at(out)
		for reg in 2:
			var y := 0.5 + 1.2 * float(reg)
			lm.box("Marble", face + out * 6.52 + Vector3(0, y + 0.95, 0), Vector3(38.0, 0.08, 0.1), basis, 0.0)
			for i in 34:
				var u := -18.0 + 36.0 * (float(i) + 0.5) / 34.0
				lm.box("Marble", face + out * 6.55 + along * u + Vector3(0, y + 0.45, 0),
					Vector3(0.38, 0.9, 0.08), basis, 0.0)
		LandmarkLpDetail.stepped_merlons(lm, "Marble", face + out * 6.3 - along * 20.0 + Vector3(0, 3.4, 0),
			face + out * 6.3 + along * 20.0 + Vector3(0, 3.4, 0), 0.9, 0.9, 0.5, 1.4)
	# Standing columns: both rows of the north portico, two of the hall.
	var h := 19.2
	var n := 0
	for row in [-46.0, -35.0]:
		for i in 6:
			_column(lm, "Marble", Vector3(a.x - 27.5 + 11.0 * float(i), ay, a.z + float(row)), h, 0.8, n % 3 == 0)
			n += 1
	for x in [-27.5, 27.5]:
		_column(lm, "Marble", Vector3(a.x + float(x), ay, a.z - 24.0), h, 0.8, false)
	# Bases of the 36-column hall.
	for i in 6:
		for k in 6:
			var p := Vector3(a.x - 27.5 + 11.0 * float(i), ay, a.z - 24.0 + 11.0 * float(k))
			if k == 0 and (i == 0 or i == 5):
				continue
			lm.box("Marble", p + Vector3(0, 0.25, 0), Vector3(2.6, 0.5, 2.6))

# --- Ishtar Gate ---

## Iraqi reconstruction beside the Babylon ruins (about 14 m): the main gate
## between its flanking towers and the smaller outer gate before it, blue
## glazed brick in rows of ochre aurochs (Adad) and mushhushshu dragons
## (Marduk) on both faces, white rosette and cream bands, a cream archivolt
## over each round-arched passage, stepped merlons along every top, and the
## Processional Way walls with striding lions above a rosette band.
## Main gate at z = -38 (north), approach from the south (+Z).
static func ishtar_gate(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Blue", LandmarkMaterials.pbr("render", "#1E4F9C", 2.0, 0.38))
	lm.use("Ochre", LandmarkMaterials.pbr("render", "#C9A24A", 2.0, 0.5))
	lm.use("Cream", LandmarkMaterials.pbr("render", "#E8DFC4", 2.0, 0.5))
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#B98A5A", 3.0))
	var gz := -38.0
	lm.box("Brick", Vector3(0, 0.15, 0.0), Vector3(44, 0.3, 94), Basis(), 0.0)
	var y0 := 0.3
	# Main gate: 30 m wide, 14 m deep, round-arched passage, flanking towers.
	var arch := [[0.0, 3.4, 5.6, 3.4]]
	LandmarkLpParts.slab(lm, "Blue", LandmarkLpParts.arcade_outline(30.0, 12.2, arch, 12),
		Vector3(0, y0, gz + 7.0), 0.0, 14.0)
	for fz in [-1.0, 1.0]:
		var zf := gz + float(fz) * 7.0
		LandmarkLpDetail.arch_band(lm, "Cream", Vector3(0, y0, zf), 0.0 if fz > 0.0 else PI, 3.4, 5.6, 3.4, 0.5,
			0.12, 12)
		for s in [-1.0, 1.0]:
			lm.box("Blue", Vector3(float(s) * 11.0, y0 + 6.1, zf + float(fz) * 1.0), Vector3(8.0, 12.2, 2.0))
			LandmarkLpDetail.stepped_merlons(lm, "Blue", Vector3(float(s) * 11.0 - 4.0, y0 + 12.2, zf + float(fz) * 1.5),
				Vector3(float(s) * 11.0 + 4.0, y0 + 12.2, zf + float(fz) * 1.5), 1.4, 1.5, 1.0, 2.0)
		LandmarkLpDetail.stepped_merlons(lm, "Blue", Vector3(-7.0, y0 + 12.2, zf), Vector3(7.0, y0 + 12.2, zf),
			1.4, 1.5, 1.2, 2.3)
		_animal_rows(lm, Vector3(0, y0, zf + float(fz) * 0.02), Vector3(float(fz), 0, 0), Vector3(0, 0, float(fz)),
			30.0, 12.2, 3.4, 9.6, 7.0, 2.0)
	for s in [-1.0, 1.0]:
		LandmarkLpDetail.stepped_merlons(lm, "Blue", Vector3(float(s) * 15.0, y0 + 12.2, gz - 7.0),
			Vector3(float(s) * 15.0, y0 + 12.2, gz + 7.0), 1.4, 1.5, 1.2, 2.3)
	# Outer gate: 22 m wide, 9 m deep, 9.5 m tall with its own towers.
	var oz := gz + 26.0
	LandmarkLpParts.slab(lm, "Blue", LandmarkLpParts.arcade_outline(22.0, 8.3, [[0.0, 2.8, 4.0, 2.8]], 12),
		Vector3(0, y0, oz + 4.5), 0.0, 9.0)
	for fz in [-1.0, 1.0]:
		var zf := oz + float(fz) * 4.5
		LandmarkLpDetail.arch_band(lm, "Cream", Vector3(0, y0, zf), 0.0 if fz > 0.0 else PI, 2.8, 4.0, 2.8, 0.4,
			0.1, 12)
		for s in [-1.0, 1.0]:
			lm.box("Blue", Vector3(float(s) * 8.5, y0 + 4.6, zf + float(fz) * 0.75), Vector3(5.0, 9.2, 1.5))
			LandmarkLpDetail.stepped_merlons(lm, "Blue", Vector3(float(s) * 8.5 - 2.5, y0 + 9.2, zf + float(fz) * 1.1),
				Vector3(float(s) * 8.5 + 2.5, y0 + 9.2, zf + float(fz) * 1.1), 1.2, 1.2, 0.9, 1.7)
		LandmarkLpDetail.stepped_merlons(lm, "Blue", Vector3(-6.0, y0 + 8.3, zf), Vector3(6.0, y0 + 8.3, zf),
			1.2, 1.2, 1.0, 2.0)
		_animal_rows(lm, Vector3(0, y0, zf + float(fz) * 0.02), Vector3(float(fz), 0, 0), Vector3(0, 0, float(fz)),
			22.0, 8.3, 2.8, 7.2, 6.0, 1.5)
	# Processional Way walls, 6.5 m, lions striding north above a rosette band.
	for s in [-1.0, 1.0]:
		var sx := float(s)
		lm.box("Blue", Vector3(sx * 8.5, y0 + 3.25, oz + 31.0), Vector3(3.0, 6.5, 52.0))
		LandmarkLpDetail.stepped_merlons(lm, "Blue", Vector3(sx * 8.5, y0 + 6.5, oz + 5.0),
			Vector3(sx * 8.5, y0 + 6.5, oz + 57.0), 1.2, 1.2, 1.0, 2.2)
		var xf := sx * 6.98
		var n := Vector3(-sx, 0, 0)
		lm.box("Cream", Vector3(xf - sx * 0.01, y0 + 1.6, oz + 31.0), Vector3(0.06, 0.22, 52.0), Basis(), 0.0)
		lm.box("Cream", Vector3(xf - sx * 0.01, y0 + 5.0, oz + 31.0), Vector3(0.06, 0.22, 52.0), Basis(), 0.0)
		for i in 26:
			lm.disc("Cream", Vector3(xf - sx * 0.02, y0 + 1.0, oz + 6.0 + 2.0 * float(i)), n, 0.35, 8)
		for i in 13:
			_lion(lm, Vector3(xf, y0 + 2.2, oz + 8.0 + 3.8 * float(i)), Vector3(0, 0, -1), n)
	lm.commit(model)

## Rows of ochre aurochs and dragons alternating on a gate face (origin
## o at the foot centre, `r` along the face, `n` out of it; width w, rows
## up to h) round an arched passage of half-width `gap` (clear up to
## `gap_top`), separated by rosette bands; beyond |u| > tower_u the face
## stands tower_dn proud (the flanking towers).
static func _animal_rows(lm: LandmarkMesh, o: Vector3, r: Vector3, n: Vector3, w: float, h: float,
		gap: float, gap_top: float, tower_u: float, tower_dn: float) -> void:
	var rows := int((h - 1.0) / 1.7)
	for row in rows:
		var y := 1.0 + 1.7 * float(row)
		var band := o + Vector3(0, y + 1.5, 0)
		for side in [-1.0, 1.0]:
			var u0 := gap + 0.6 if y + 1.5 < gap_top else 0.0
			var u1 := tower_u - 0.2
			if u1 > u0:
				var um := float(side) * (u0 + u1) * 0.5
				lm.box("Cream", band + r * um + n * 0.03, Vector3(u1 - u0, 0.12, 0.06), Basis(r, Vector3.UP, n), 0.0)
		var cnt := int((w - 1.0) / 2.6)
		for i in cnt:
			var u := -w * 0.5 + 0.5 + 2.6 * (float(i) + 0.5) + (w - 1.0 - 2.6 * float(cnt)) * 0.5
			if absf(u) < gap + 1.4 and y < gap_top:
				continue
			var p := o + r * u + Vector3(0, y + 0.1, 0) + n * (tower_dn if absf(u) > tower_u else 0.0)
			var walk := r * (-1.0 if u > 0.0 else 1.0)
			if (i + row) % 2 == 1:
				_dragon(lm, p, walk, n)
			else:
				_aurochs(lm, p, walk, n)

## Relief aurochs about 1.9 x 1.3 m, feet at p, walking along `walk` on a
## face with normal n: body, four legs, neck and head, horns, tail.
static func _aurochs(lm: LandmarkMesh, p: Vector3, walk: Vector3, n: Vector3) -> void:
	var b := Basis(walk, Vector3.UP, n)
	var q := p + n * 0.06
	lm.box("Ochre", q + Vector3(0, 0.85, 0), Vector3(1.4, 0.55, 0.12), b, 0.0)
	for x in [-0.55, -0.35, 0.4, 0.6]:
		lm.box("Ochre", q + walk * float(x) + Vector3(0, 0.3, 0), Vector3(0.13, 0.6, 0.1), b, 0.0)
	lm.box("Ochre", q + walk * 0.8 + Vector3(0, 1.05, 0), Vector3(0.35, 0.4, 0.12), b, 0.0)
	lm.box("Ochre", q + walk * 1.0 + Vector3(0, 0.95, 0), Vector3(0.3, 0.22, 0.12), b, 0.0)
	lm.box("Ochre", q + walk * 0.85 + Vector3(0, 1.32, 0), Vector3(0.08, 0.3, 0.1), b, 0.0)
	lm.box("Ochre", q - walk * 0.78 + Vector3(0, 0.6, 0), Vector3(0.07, 0.6, 0.08), b, 0.0)

## Relief mushhushshu: slender scaled body, lion forelegs, eagle hind
## legs, long upright neck with horned head and an upturned tail.
static func _dragon(lm: LandmarkMesh, p: Vector3, walk: Vector3, n: Vector3) -> void:
	var b := Basis(walk, Vector3.UP, n)
	var q := p + n * 0.06
	lm.box("Ochre", q + Vector3(0, 0.75, 0), Vector3(1.2, 0.32, 0.12), b, 0.0)
	for x in [-0.45, -0.3, 0.38, 0.52]:
		lm.box("Ochre", q + walk * float(x) + Vector3(0, 0.3, 0), Vector3(0.1, 0.6, 0.1), b, 0.0)
	lm.beam("Ochre", q + walk * 0.55 + Vector3(0, 0.85, 0), q + walk * 0.75 + Vector3(0, 1.45, 0), 0.16, 0.12, n.cross(walk))
	lm.box("Ochre", q + walk * 0.9 + Vector3(0, 1.48, 0), Vector3(0.36, 0.14, 0.12), b, 0.0)
	lm.box("Ochre", q + walk * 0.72 + Vector3(0, 1.66, 0), Vector3(0.06, 0.26, 0.1), b, 0.0)
	lm.beam("Ochre", q - walk * 0.6 + Vector3(0, 0.75, 0), q - walk * 0.85 + Vector3(0, 1.2, 0), 0.08, 0.1, n.cross(walk))

## Relief lion striding along `walk` (about 2.4 x 1.3 m) with its mane.
static func _lion(lm: LandmarkMesh, p: Vector3, walk: Vector3, n: Vector3) -> void:
	var b := Basis(walk, Vector3.UP, n)
	var q := p + n * 0.07
	lm.box("Ochre", q + Vector3(0, 0.8, 0), Vector3(1.8, 0.5, 0.14), b, 0.0)
	lm.box("Cream", q + walk * 0.65 + Vector3(0, 0.95, 0) + n * 0.02, Vector3(0.6, 0.7, 0.14), b, 0.0)
	lm.box("Ochre", q + walk * 1.05 + Vector3(0, 1.05, 0) + n * 0.03, Vector3(0.4, 0.38, 0.14), b, 0.0)
	for x in [-0.75, -0.5, 0.5, 0.75]:
		lm.box("Ochre", q + walk * float(x) + Vector3(0, 0.28, 0), Vector3(0.16, 0.56, 0.12), b, 0.0)
	lm.beam("Ochre", q - walk * 0.9 + Vector3(0, 0.9, 0), q - walk * 1.25 + Vector3(0, 1.25, 0), 0.08, 0.1, n.cross(walk))
