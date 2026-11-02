class_name LandmarkEgKarnak
extends RefCounted

## The two great Theban temples on the east bank in true metres, built
## with the entrance toward +Z and the sanctuary toward -Z (registry
## yaw_deg turns each onto its real axis): the Amun-Re precinct of Karnak
## and Luxor Temple.

# --- Karnak ---

## Amun-Re precinct: the avenue of ram-headed sphinxes and the quay
## approach, the unfinished first pylon (z = 125, 43.5 m, 113 m wide, 15 m
## thick, never corniced, the mud-brick ramp on its back), the Great
## Court with its north colonnade of 18 and south colonnade of 9 bud
## columns, Seti II's triple bark shrine, the temple of Ramesses III
## breaking through the south side with its Osiride pillars, Taharqa's
## lone 21 m column and the Pinedjem colossus at the second pylon; the
## Hypostyle Hall (134 columns: 12 open-papyrus nave columns of 21 m
## under the clerestory with its stone window grilles, and 122 bud
## columns of 13 m), the third to sixth pylons, Thutmose I's 21.8 m
## obelisk and Hatshepsut's 29.6 m obelisk. Origin at the centre of the
## hypostyle hall.
static func karnak(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Sand", LandmarkMaterials.pbr("stone", "#C9A978", 3.2))
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#B07C6C", 2.0))
	lm.use("Dark", LandmarkMaterials.pbr("stone", "#3A2E22", 2.0))
	lm.use("Mud", LandmarkMaterials.pbr("stone", "#8E7554", 4.0))
	lm.use("Ground", LandmarkMaterials.pbr("sand", "#D6BE8C", 8.0))
	lm.box("Ground", Vector3(0, 0.1, 34.0), Vector3(118.0, 0.2, 276.0), Basis(), 0.0)
	LandmarkEgParts.pylon(lm, "Sand", "Dark", Vector3(0, 0, 125.0), 113.0, 43.5, 15.0, 14.0, 2, false)
	LandmarkEgParts.pylon(lm, "Sand", "Dark", Vector3(0, 0, 28.0), 98.0, 28.0, 11.0, 12.0)
	LandmarkEgParts.pylon(lm, "Sand", "Dark", Vector3(0, 0, -35.0), 92.0, 30.0, 10.0, 9.0)
	LandmarkEgParts.pylon(lm, "Sand", "Dark", Vector3(0, 0, -59.0), 56.0, 30.0, 10.0, 8.0)
	LandmarkEgParts.pylon(lm, "Sand", "Dark", Vector3(0, 0, -81.0), 50.0, 24.0, 8.0, 7.0)
	LandmarkEgParts.pylon(lm, "Sand", "Dark", Vector3(0, 0, -95.0), 52.0, 22.0, 6.0, 7.0)
	_mud_ramp(lm)
	_great_court(lm)
	_hypostyle(lm)
	LandmarkEgParts.obelisk(lm, "Granite", "Granite", Vector3(3.0, 0, -47.0), 1.9, 21.8, "Dark")
	LandmarkEgParts.obelisk(lm, "Granite", "Granite", Vector3(-5.5, 0, -71.0), 2.7, 29.6, "Dark")
	# Avenue of ram-headed sphinxes on the dromos in front of the first pylon.
	lm.box("Sand", Vector3(0, 0.3, 152.0), Vector3(14.0, 0.4, 40.0))
	for i in 10:
		for s in [-1.0, 1.0]:
			var p := Vector3(s * 9.0, 0, 136.0 + 3.8 * float(i))
			lm.box("Sand", p + Vector3(0, 0.6, 0), Vector3(2.4, 1.2, 4.2))
			LandmarkEgParts.sphinx(lm, "Sand", p + Vector3(0, 1.2, 0), 3.8, true,
				Basis(Vector3.UP, -s * PI * 0.5))
	lm.commit(model)

## Sloping mud-brick construction ramp leaning on the rear of the first
## pylon's left tower, its stepped brick courses showing on the flanks.
static func _mud_ramp(lm: LandmarkMesh) -> void:
	var x0 := -40.0
	var x1 := -24.0
	var foot := 62.0
	var back := 117.5
	var top := 36.0
	var n := Vector3(0, back - foot, -top).normalized()
	var a := Vector3(x0, 0, foot)
	var b := Vector3(x1, 0, foot)
	lm.quad("Mud", a, b, Vector3(x1, top, back), Vector3(x0, top, back), n)
	for s in [[x0, -1.0], [x1, 1.0]]:
		var sx: float = s[0]
		var sn := Vector3(s[1], 0, 0)
		lm.tri("Mud", Vector3(sx, 0, foot), Vector3(sx, top, back), Vector3(sx, 0, back), sn, sn, sn,
			Vector2(foot, 0), Vector2(back, top), Vector2(back, 0))
		for k in 8:
			var y := top * (float(k) + 0.5) / 8.0
			var z := lerpf(foot, back, (float(k) + 0.5) / 8.0)
			lm.box("Mud", Vector3(sx + float(s[1]) * 0.2, y * 0.5, (z + back) * 0.5),
				Vector3(0.4, 0.5, back - z), Basis(), 0.0)

## Great Court, 103 x 84 m: one bud-column colonnade along each side
## under a flat roof, Seti II's triple shrine in the north-west corner,
## Ramesses III's temple breaking through the south side, the Kiosk of
## Taharqa's lone 21 m column, and the Pinedjem colossus at the second
## pylon.
static func _great_court(lm: LandmarkMesh) -> void:
	for s in [-1.0, 1.0]:
		LandmarkEgParts.temple_wall(lm, "Sand", Vector2(s * 52.7, 117.5), Vector2(s * 52.7, 33.5), 12.8, 2.4)
	LandmarkEgParts.colonnade(lm, "Sand", Vector3(46.0, 0, 112.0), Vector3(46.0, 0, 38.0), 18, 0.9, 10.4,
		LandmarkEgParts.BUD, 10)
	lm.box("Sand", Vector3(48.4, 11.0, 75.0), Vector3(8.4, 1.2, 80.0))
	LandmarkEgParts.colonnade(lm, "Sand", Vector3(-46.0, 0, 112.0), Vector3(-46.0, 0, 82.0), 9, 0.9, 10.4,
		LandmarkEgParts.BUD, 10)
	lm.box("Sand", Vector3(-48.4, 11.0, 97.0), Vector3(8.4, 1.2, 34.0))
	# Triple bark shrine of Seti II.
	for k in 3:
		var z := 104.0 - 7.0 * float(k)
		lm.box("Sand", Vector3(36.0, 3.5, z), Vector3(12.0, 7.0, 6.0))
		LandmarkEgParts.cavetto(lm, "Sand", Vector3(36.0, 7.0, z), 12.0, 6.0, 0.9, 0.5)
		lm.box("Dark", Vector3(29.9, 2.4, z), Vector3(0.2, 4.0, 2.0), Basis(), 0.0)
	# Temple of Ramesses III: pylon, court of Osiride pillars, hypostyle.
	var r3 := Vector3(-36.0, 0, 64.0)
	var rb := Basis(Vector3.UP, -PI * 0.5)
	lm.box("Sand", r3 + Vector3(4.0, 4.0, 0), Vector3(2.0, 8.0, 18.0))
	for s in [-1.0, 1.0]:
		LandmarkEgParts.taper(lm, "Sand", r3 + Vector3(4.0, 0, s * 6.5), 3.0, 7.0, 2.2, 6.2, 12.0)
		LandmarkEgParts.cavetto(lm, "Sand", r3 + Vector3(4.0, 12.0, s * 6.5), 2.2, 6.2, 1.0, 0.6)
		LandmarkEgParts.temple_wall(lm, "Sand", Vector2(r3.x + 3.0, r3.z + s * 9.0), Vector2(r3.x - 46.0,
			r3.z + s * 9.0), 8.5, 1.4)
		for i in 8:
			var p := r3 + Vector3(-3.0 - 4.0 * float(i), 0, s * 5.0)
			lm.box("Sand", p + Vector3(0, 3.5, 0), Vector3(1.4, 7.0, 1.4))
			LandmarkEgParts.osiride(lm, "Sand", p + Vector3(0, 0, -s * 1.0), 6.6)
		lm.box("Sand", r3 + Vector3(-17.0, 7.4, s * 6.2), Vector3(34.0, 0.8, 4.0))
	lm.box("Sand", r3 + Vector3(-42.0, 4.0, 0), Vector3(10.0, 8.0, 18.0))
	lm.box("Dark", r3 + Vector3(-36.9, 2.6, 0), Vector3(0.2, 4.4, 2.4), Basis(), 0.0)
	lm.box("Dark", r3 + Vector3(5.1, 2.6, 0), Vector3(0.2, 4.4, 2.4), Basis(), 0.0)
	# Kiosk of Taharqa: its single standing 21 m column and the screen-wall stubs.
	lm.box("Sand", Vector3(0, 0.6, 68.0), Vector3(16.0, 1.2, 34.0))
	LandmarkEgParts.column(lm, "Sand", Vector3(0, 1.2, 76.0), 1.7, 19.8, LandmarkEgParts.OPEN, 16)
	for i in 5:
		for s in [-1.0, 1.0]:
			lm.frustum("Sand", Vector3(s * 5.5, 1.2, 54.0 + 7.0 * float(i)), 1.5, 1.45, 1.4, 12)
	# Pinedjem colossus, 15 m, standing before the second pylon's north tower.
	_standing_king(lm, "Granite", Vector3(17.0, 0, 37.0), 15.0)
	_standing_king(lm, "Granite", Vector3(-17.0, 0, 37.0), 7.0)

## Standing striding king facing +Z, `h` tall: base, legs (left foot
## forward), kilt, torso, arms at the sides, nemes and double crown.
static func _standing_king(lm: LandmarkMesh, key: String, c: Vector3, h: float) -> void:
	lm.box(key, c + Vector3(0, h * 0.04, h * 0.05), Vector3(h * 0.26, h * 0.08, h * 0.42))
	lm.box(key, c + Vector3(0, h * 0.45, -h * 0.1), Vector3(h * 0.12, h * 0.8, h * 0.06))
	for s in [-1.0, 1.0]:
		var fz: float = h * (0.1 if s < 0.0 else -0.02)
		lm.beam(key, c + Vector3(s * h * 0.05, h * 0.1, fz), c + Vector3(s * h * 0.055, h * 0.45, -h * 0.03),
			h * 0.065, h * 0.08)
		lm.box(key, c + Vector3(s * h * 0.05, h * 0.095, fz + h * 0.03), Vector3(h * 0.06, h * 0.03, h * 0.12))
		lm.beam(key, c + Vector3(s * h * 0.13, h * 0.69, -h * 0.03), c + Vector3(s * h * 0.13, h * 0.42, -h * 0.02),
			h * 0.05, h * 0.05)
	lm.frustum(key, c + Vector3(0, h * 0.4, -h * 0.03), h * 0.1, h * 0.09, h * 0.12, 10, 0.0, 1.0, 0.7)
	lm.lathe(key, c + Vector3(0, h * 0.52, -h * 0.03), PackedVector2Array([Vector2(h * 0.08, 0),
		Vector2(h * 0.09, h * 0.08), Vector2(h * 0.12, h * 0.17), Vector2(h * 0.06, h * 0.2)]), 10, 1.0, 0.6)
	var hb := c + Vector3(0, h * 0.72, -h * 0.03)
	lm.lathe(key, hb, PackedVector2Array([Vector2(h * 0.09, 0), Vector2(h * 0.075, h * 0.06),
		Vector2(h * 0.05, h * 0.1), Vector2(0.0, h * 0.11)]), 10)
	lm.lathe(key, hb + Vector3(0, h * 0.1, 0), PackedVector2Array([Vector2(h * 0.05, 0),
		Vector2(h * 0.045, h * 0.1), Vector2(h * 0.025, h * 0.16), Vector2(0.0, h * 0.18)]), 8)

## Hypostyle Hall, 102 x 53 m: 2 x 6 nave columns of 21 m under the
## clerestory (its windows filled with stone grilles of upright slats)
## and roof, 14 aisle rows of 9 bud columns (13 m, four corner columns
## missing: 122) carrying a grid of architraves and roof slabs.
static func _hypostyle(lm: LandmarkMesh) -> void:
	for s in [-1.0, 1.0]:
		LandmarkEgParts.temple_wall(lm, "Sand", Vector2(s * 51.8, 22.5), Vector2(s * 51.8, -30.0), 15.0, 3.0)
		for i in 6:
			LandmarkEgParts.column(lm, "Sand", Vector3(s * 5.5, 0, 18.5 - 8.2 * i), 1.7, 21.0,
				LandmarkEgParts.OPEN, 16)
		lm.beam("Sand", Vector3(s * 5.5, 21.9, 22.0), Vector3(s * 5.5, 21.9, -29.5), 1.8, 3.8,
			Vector3.UP, true)
		# Clerestory: piers between grille windows, the slats inside each.
		var cx: float = s * 9.8
		lm.box("Sand", Vector3(cx, 15.6, -3.8), Vector3(1.2, 1.4, 52.0))
		lm.box("Sand", Vector3(cx, 21.6, -3.8), Vector3(1.2, 1.4, 52.0))
		for k in 9:
			var z := 21.0 - 6.2 * float(k)
			lm.box("Sand", Vector3(cx, 18.6, z), Vector3(1.2, 4.6, 1.6))
			if k < 8:
				for j in 5:
					lm.box("Sand", Vector3(cx, 18.6, z - 1.3 - 0.75 * float(j) - 0.35), Vector3(0.5, 4.6, 0.3),
						Basis(), 0.0)
				lm.box("Dark", Vector3(cx - s * 0.2, 18.6, z - 3.1), Vector3(0.1, 4.6, 4.6), Basis(), 0.0)
		for i in 7:
			var x: float = s * (12.2 + 5.8 * i)
			for j in 9:
				if i == 6 and (j == 0 or j == 8):
					continue
				LandmarkEgParts.column(lm, "Sand", Vector3(x, 0, 18.0 - 5.4 * j), 1.05, 13.0,
					LandmarkEgParts.BUD, 10)
			lm.beam("Sand", Vector3(x, 13.7, 20.5), Vector3(x, 13.7, -26.5), 1.4, 1.6, Vector3.UP, true)
	lm.box("Sand", Vector3(0, 23.4, -3.8), Vector3(21.0, 1.2, 52.0))
	for j in 9:
		lm.beam("Sand", Vector3(-50.0, 13.7, 18.0 - 5.4 * j), Vector3(-10.0, 13.7, 18.0 - 5.4 * j),
			1.4, 1.6, Vector3.UP, true)
		lm.beam("Sand", Vector3(10.0, 13.7, 18.0 - 5.4 * j), Vector3(50.0, 13.7, 18.0 - 5.4 * j),
			1.4, 1.6, Vector3.UP, true)

# --- Luxor Temple ---

## Luxor Temple, 260 m long: the end of the avenue of human-headed
## sphinxes, Ramesses II's 24 m pylon with two seated 15.5 m colossi, two
## standing colossi and the 25 m obelisk; the court of Ramesses II with
## its double peristyle of bundled-papyrus columns, standing colossi
## between the front columns, Thutmose III's triple shrine and the white
## Abu al-Haggag mosque raised on its east side; the 19 m open-papyrus
## colonnade of Amenhotep III, his sun court with double rows of bundled
## columns on three sides, the 32-column hypostyle hall and the
## sanctuary block. Origin at mid-length.
static func luxor(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Sand", LandmarkMaterials.pbr("stone", "#CBAB7A", 3.2))
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#B07C6C", 2.0))
	lm.use("Dark", LandmarkMaterials.pbr("stone", "#3A2E22", 2.0))
	lm.use("White", LandmarkMaterials.pbr("render", "#EDE6D4", 3.0))
	lm.use("Ground", LandmarkMaterials.pbr("sand", "#D6BE8C", 8.0))
	lm.box("Ground", Vector3(0, 0.1, 20.0), Vector3(76.0, 0.2, 236.0), Basis(), 0.0)
	LandmarkEgParts.pylon(lm, "Sand", "Dark", Vector3(0, 0, 92.0), 65.0, 24.0, 10.0, 8.0)
	for s in [-1.0, 1.0]:
		lm.box("Sand", Vector3(s * 10.5, 0.5, 101.0), Vector3(7.6, 1.0, 9.0))
		LandmarkEgParts.colossus(lm, "Sand", Vector3(s * 10.5, 1.0, 102.0), 14.5)
		lm.box("Granite", Vector3(s * 26.0, 0.6, 99.0), Vector3(3.6, 1.2, 4.0))
		LandmarkEgKarnak._standing_king(lm, "Granite", Vector3(s * 26.0, 1.2, 99.0), 11.0)
	LandmarkEgParts.obelisk(lm, "Granite", "Granite", Vector3(-17.0, 0, 104.0), 2.4, 25.0, "Dark")
	lm.box("Granite", Vector3(17.0, 0.6, 104.0), Vector3(5.2, 1.2, 5.2))
	# The end of the avenue of sphinxes and the Roman-era forecourt.
	for i in 6:
		for s in [-1.0, 1.0]:
			var p := Vector3(s * 7.5, 0, 112.0 + 4.2 * float(i))
			lm.box("Sand", p + Vector3(0, 0.5, 0), Vector3(2.2, 1.0, 4.0))
			LandmarkEgParts.sphinx(lm, "Sand", p + Vector3(0, 1.0, 0), 3.6, false,
				Basis(Vector3.UP, -s * PI * 0.5))
	_ramesses_court(lm)
	_abu_haggag(lm)
	# Colonnade of Amenhotep III: 2 x 7 open papyrus columns, 19 m.
	for s in [-1.0, 1.0]:
		LandmarkEgParts.colonnade(lm, "Sand", Vector3(s * 5.7, 0, 31.5), Vector3(s * 5.7, 0, -12.3),
			7, 1.45, 19.0, LandmarkEgParts.OPEN, 16)
		lm.beam("Sand", Vector3(s * 5.7, 20.0, 35.0), Vector3(s * 5.7, 20.0, -16.0), 2.0, 3.0,
			Vector3.UP, true)
		LandmarkEgParts.temple_wall(lm, "Sand", Vector2(s * 12.0, 36.0), Vector2(s * 12.0, -17.0), 9.0, 1.6)
	for k in 7:
		lm.beam("Sand", Vector3(-5.7, 21.2, 31.5 - 7.3 * float(k)), Vector3(5.7, 21.2, 31.5 - 7.3 * float(k)),
			1.2, 1.4, Vector3.UP, true)
	# Sun court of Amenhotep III: double rows on three sides.
	for s in [-1.0, 1.0]:
		LandmarkEgParts.temple_wall(lm, "Sand", Vector2(s * 25.0, -17.0), Vector2(s * 25.0, -92.0), 10.5, 2.0)
		for xr in [16.0, 21.0]:
			LandmarkEgParts.colonnade(lm, "Sand", Vector3(s * xr, 0, -20.0), Vector3(s * xr, 0, -50.0),
				6, 0.9, 9.5, LandmarkEgParts.BUNDLE)
		lm.box("Sand", Vector3(s * 19.0, 10.0, -35.0), Vector3(10.0, 1.0, 33.0))
	for zr in [-17.5, -22.5]:
		LandmarkEgParts.colonnade(lm, "Sand", Vector3(-11.0, 0, zr), Vector3(11.0, 0, zr), 4, 0.9, 9.5,
			LandmarkEgParts.BUNDLE)
	# Hypostyle hall: 4 rows of 8 bundled columns, its roof, sanctuary block.
	for zr in [-55.0, -59.5, -64.0, -68.5]:
		LandmarkEgParts.colonnade(lm, "Sand", Vector3(-20.0, 0, zr), Vector3(20.0, 0, zr), 8, 0.9, 9.5,
			LandmarkEgParts.BUNDLE)
		lm.beam("Sand", Vector3(-21.0, 10.2, zr), Vector3(21.0, 10.2, zr), 1.2, 1.6, Vector3.UP, true)
	lm.box("Sand", Vector3(0, 4.5, -83.5), Vector3(50.0, 9.0, 17.0))
	LandmarkEgParts.cavetto(lm, "Sand", Vector3(0, 9.0, -83.5), 50.0, 17.0, 1.4, 0.8)
	lm.box("Dark", Vector3(0, 3.0, -74.9), Vector3(4.0, 6.0, 0.5))
	lm.commit(model)

## Court of Ramesses II, 57 x 51 m: a double peristyle of 74 bundled
## papyrus columns (the court sits askew to the axis), standing colossi
## of the king between the front columns of the south side, and Thutmose
## III's triple bark shrine against the north-west corner.
static func _ramesses_court(lm: LandmarkMesh) -> void:
	for s in [-1.0, 1.0]:
		LandmarkEgParts.temple_wall(lm, "Sand", Vector2(s * 29.0, 87.0), Vector2(s * 29.0, 36.0), 11.0, 2.0)
		for xr in [18.0, 24.0]:
			LandmarkEgParts.colonnade(lm, "Sand", Vector3(s * xr, 0, 82.0), Vector3(s * xr, 0, 41.0),
				8, 0.85, 10.0, LandmarkEgParts.BUNDLE)
		lm.box("Sand", Vector3(s * 21.5, 10.6, 61.5), Vector3(10.0, 1.0, 46.0))
	for zr in [41.0, 46.0]:
		LandmarkEgParts.colonnade(lm, "Sand", Vector3(-12.0, 0, zr), Vector3(12.0, 0, zr), 5, 0.85, 10.0,
			LandmarkEgParts.BUNDLE)
	lm.box("Sand", Vector3(0, 10.6, 43.5), Vector3(28.0, 1.0, 9.0))
	for k in 4:
		var x := -6.0 + 4.0 * float(k)
		lm.box("Granite", Vector3(x, 0.5, 49.0), Vector3(2.0, 1.0, 2.6))
		_standing(lm, Vector3(x, 1.0, 49.0), 7.0)
	for k in 3:
		var z := 80.0 - 5.0 * float(k)
		lm.box("Granite", Vector3(13.0, 2.6, z), Vector3(5.0, 5.2, 4.2))
		LandmarkEgParts.cavetto(lm, "Granite", Vector3(13.0, 5.2, z), 5.0, 4.2, 0.6, 0.3)
		lm.box("Dark", Vector3(10.4, 2.0, z), Vector3(0.2, 3.0, 1.4), Basis(), 0.0)

static func _standing(lm: LandmarkMesh, c: Vector3, h: float) -> void:
	LandmarkEgKarnak._standing_king(lm, "Granite", c, h)

## The Abu al-Haggag mosque built into the east (-X) side of the first
## court on a mound of old debris: whitewashed walls with a crenellated
## parapet, small arched windows, its dome and the slender minaret.
static func _abu_haggag(lm: LandmarkMesh) -> void:
	lm.box("Sand", Vector3(-20.0, 4.5, 58.0), Vector3(17.0, 9.0, 19.0))
	lm.box("White", Vector3(-20.0, 12.4, 58.0), Vector3(14.0, 6.8, 16.0))
	for i in 7:
		for s in [-1.0, 1.0]:
			lm.box("White", Vector3(-26.0 + 2.0 * float(i), 16.1, 58.0 + s * 7.8), Vector3(0.9, 0.6, 0.4))
		lm.box("Dark", Vector3(-26.0 + 2.0 * float(i), 12.8, 66.05), Vector3(0.7, 1.4, 0.1), Basis(), 0.0)
	lm.lathe("White", Vector3(-20.0, 15.8, 58.0), PackedVector2Array([Vector2(4.2, 0),
		Vector2(4.0, 1.0), Vector2(3.6, 1.8), Vector2(2.8, 2.8), Vector2(2.0, 3.4), Vector2(0.0, 4.0)]), 16)
	LandmarkKits.minaret(lm, "White", "White", Vector3(-26.5, 9.0, 51.0), 1.0, 13.0, 1)
