class_name LandmarkEgKarnak
extends RefCounted

## The two great Theban temples on the east bank in true metres, built
## with the entrance toward +Z and the sanctuary toward -Z (registry
## yaw_deg turns each onto its real axis): the Amun-Re precinct of Karnak
## and Luxor Temple.

# --- Karnak ---

## Amun-Re precinct, first pylon (z = 125, 43.5 m, 113 m wide, the
## unfinished mud-brick ramp on its back) through the Great Court with
## Taharqa's 21 m column, the second pylon and the Hypostyle Hall (134
## columns: 12 open-papyrus nave columns of 21 m and 122 of 13 m), the
## third to sixth pylons, Thutmose I's 21.8 m obelisk and Hatshepsut's
## 29.6 m obelisk. Origin at the centre of the hypostyle hall.
static func karnak(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Sand", LandmarkMaterials.pbr("stone", "#C9A978", 3.2))
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#B07C6C", 2.0))
	lm.use("Dark", LandmarkMaterials.pbr("stone", "#3A2E22", 2.0))
	lm.use("Mud", LandmarkMaterials.pbr("stone", "#8E7554", 4.0))
	lm.use("Ground", LandmarkMaterials.pbr("sand", "#D6BE8C", 8.0))
	lm.box("Ground", Vector3(0, -0.2, 14.0), Vector3(112.0, 0.6, 236.0))
	LandmarkEgParts.pylon(lm, "Sand", "Dark", Vector3(0, 0, 125.0), 113.0, 43.5, 15.0, 14.0)
	LandmarkEgParts.pylon(lm, "Sand", "Dark", Vector3(0, 0, 28.0), 98.0, 28.0, 11.0, 12.0)
	LandmarkEgParts.pylon(lm, "Sand", "Dark", Vector3(0, 0, -35.0), 92.0, 30.0, 10.0, 9.0)
	LandmarkEgParts.pylon(lm, "Sand", "Dark", Vector3(0, 0, -59.0), 56.0, 30.0, 10.0, 8.0)
	LandmarkEgParts.pylon(lm, "Sand", "Dark", Vector3(0, 0, -81.0), 50.0, 24.0, 8.0, 7.0)
	LandmarkEgParts.pylon(lm, "Sand", "Dark", Vector3(0, 0, -95.0), 52.0, 22.0, 6.0, 7.0)
	_mud_ramp(lm)
	_great_court(lm)
	_hypostyle(lm)
	LandmarkEgParts.obelisk(lm, "Granite", "Granite", Vector3(3.0, 0, -47.0), 1.9, 21.8)
	LandmarkEgParts.obelisk(lm, "Granite", "Granite", Vector3(-5.5, 0, -71.0), 2.7, 29.6)
	lm.commit(model)

## Sloping mud-brick construction ramp leaning on the rear of the first
## pylon's left tower.
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

## Great Court: 103 x 84 m, double colonnades of 10.4 m bud columns on
## both long sides under flat roofs, and Taharqa's lone 21 m column.
static func _great_court(lm: LandmarkMesh) -> void:
	for s in [-1.0, 1.0]:
		LandmarkEgParts.wall(lm, "Sand", Vector2(s * 52.7, 117.5), Vector2(s * 52.7, 33.5), 12.8, 2.4)
		for xr in [41.0, 47.5]:
			LandmarkEgParts.colonnade(lm, "Sand", Vector3(s * xr, 0, 112.0), Vector3(s * xr, 0, 38.0),
				13, 0.9, 10.4)
			lm.beam("Sand", Vector3(s * xr, 11.1, 112.0), Vector3(s * xr, 11.1, 38.0), 1.4, 1.8,
				Vector3.UP, true)
		lm.box("Sand", Vector3(s * 46.0, 12.3, 75.0), Vector3(13.0, 1.0, 82.0))
	lm.box("Sand", Vector3(0, 0.6, 68.0), Vector3(8.0, 1.2, 8.0))
	LandmarkEgParts.column(lm, "Sand", Vector3(0, 1.2, 68.0), 1.7, 19.8, LandmarkEgParts.OPEN, 12)

## Hypostyle Hall, 102 x 53 m: 2 x 6 nave columns of 21 m under a
## clerestory and roof, 14 aisle rows of 9 columns (13 m, four corner
## columns missing: 122) carrying a grid of architraves.
static func _hypostyle(lm: LandmarkMesh) -> void:
	for s in [-1.0, 1.0]:
		LandmarkEgParts.wall(lm, "Sand", Vector2(s * 51.8, 22.5), Vector2(s * 51.8, -30.0), 15.0, 3.0)
		for i in 6:
			LandmarkEgParts.column(lm, "Sand", Vector3(s * 5.5, 0, 18.5 - 8.2 * i), 1.7, 21.0,
				LandmarkEgParts.OPEN, 12)
		lm.beam("Sand", Vector3(s * 5.5, 21.9, 22.0), Vector3(s * 5.5, 21.9, -29.5), 1.8, 3.8,
			Vector3.UP, true)
		lm.box("Sand", Vector3(s * 9.8, 18.6, -3.8), Vector3(1.2, 7.4, 52.0))
		for i in 7:
			var x: float = s * (12.2 + 5.8 * i)
			for j in 9:
				if i == 6 and (j == 0 or j == 8):
					continue
				LandmarkEgParts.column(lm, "Sand", Vector3(x, 0, 18.0 - 5.4 * j), 1.05, 13.0)
			lm.beam("Sand", Vector3(x, 13.7, 20.5), Vector3(x, 13.7, -26.5), 1.4, 1.6, Vector3.UP, true)
	lm.box("Sand", Vector3(0, 23.4, -3.8), Vector3(21.0, 1.2, 52.0))
	for j in 9:
		lm.beam("Sand", Vector3(-50.0, 13.7, 18.0 - 5.4 * j), Vector3(-10.0, 13.7, 18.0 - 5.4 * j),
			1.4, 1.6, Vector3.UP, true)
		lm.beam("Sand", Vector3(10.0, 13.7, 18.0 - 5.4 * j), Vector3(50.0, 13.7, 18.0 - 5.4 * j),
			1.4, 1.6, Vector3.UP, true)

# --- Luxor Temple ---

## Luxor Temple, 195 m long: Ramesses II's 24 m pylon with two seated
## 15.5 m colossi and the 25 m obelisk, the court of Ramesses II (with
## the white Abu al-Haggag mosque on its east side), the 19 m open-papyrus
## colonnade of Amenhotep III, his court, the hypostyle hall and the
## sanctuary block. Origin at mid-length.
static func luxor(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Sand", LandmarkMaterials.pbr("stone", "#CBAB7A", 3.2))
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#B07C6C", 2.0))
	lm.use("Dark", LandmarkMaterials.pbr("stone", "#3A2E22", 2.0))
	lm.use("White", LandmarkMaterials.pbr("render", "#EDE6D4", 3.0))
	lm.use("Ground", LandmarkMaterials.pbr("sand", "#D6BE8C", 8.0))
	lm.box("Ground", Vector3(0, -0.2, 5.0), Vector3(72.0, 0.6, 204.0))
	LandmarkEgParts.pylon(lm, "Sand", "Dark", Vector3(0, 0, 92.0), 65.0, 24.0, 10.0, 8.0)
	for s in [-1.0, 1.0]:
		LandmarkEgParts.colossus(lm, "Sand", Vector3(s * 10.5, 0, 102.0), 15.5)
	LandmarkEgParts.obelisk(lm, "Granite", "Granite", Vector3(-23.0, 0, 104.0), 2.4, 25.0)
	# Court of Ramesses II: bud-column peristyle on three sides.
	for s in [-1.0, 1.0]:
		LandmarkEgParts.wall(lm, "Sand", Vector2(s * 29.0, 87.0), Vector2(s * 29.0, 36.0), 11.0, 2.0)
		for xr in [17.0, 23.0]:
			LandmarkEgParts.colonnade(lm, "Sand", Vector3(s * xr, 0, 82.0), Vector3(s * xr, 0, 40.0),
				9, 0.85, 10.0)
		lm.box("Sand", Vector3(s * 22.0, 10.7, 61.0), Vector3(14.0, 1.0, 48.0))
	for zr in [41.0, 46.0]:
		LandmarkEgParts.colonnade(lm, "Sand", Vector3(-9.0, 0, zr), Vector3(9.0, 0, zr), 5, 0.85, 10.0)
	lm.box("Sand", Vector3(0, 10.7, 43.5), Vector3(22.0, 1.0, 9.0))
	_abu_haggag(lm)
	# Colonnade of Amenhotep III: 2 x 7 open papyrus columns, 19 m.
	for s in [-1.0, 1.0]:
		LandmarkEgParts.colonnade(lm, "Sand", Vector3(s * 5.7, 0, 31.5), Vector3(s * 5.7, 0, -12.3),
			7, 1.45, 19.0, LandmarkEgParts.OPEN, 10)
		lm.beam("Sand", Vector3(s * 5.7, 20.0, 35.0), Vector3(s * 5.7, 20.0, -16.0), 2.0, 3.0,
			Vector3.UP, true)
		LandmarkEgParts.wall(lm, "Sand", Vector2(s * 12.0, 36.0), Vector2(s * 12.0, -17.0), 9.0, 1.6)
	# Court of Amenhotep III, hypostyle hall and sanctuary.
	for s in [-1.0, 1.0]:
		LandmarkEgParts.wall(lm, "Sand", Vector2(s * 25.0, -17.0), Vector2(s * 25.0, -92.0), 10.5, 2.0)
		for xr in [15.5, 20.5]:
			LandmarkEgParts.colonnade(lm, "Sand", Vector3(s * xr, 0, -22.0), Vector3(s * xr, 0, -50.0),
				6, 0.9, 9.5)
		lm.box("Sand", Vector3(s * 20.0, 10.2, -36.0), Vector3(11.0, 1.0, 34.0))
		for xr in [4.5, 11.0]:
			LandmarkEgParts.colonnade(lm, "Sand", Vector3(s * xr, 0, -58.0), Vector3(s * xr, 0, -73.0),
				4, 0.9, 9.5)
	lm.box("Sand", Vector3(0, 10.3, -65.5), Vector3(50.0, 1.4, 21.0))
	lm.box("Sand", Vector3(0, 4.5, -83.5), Vector3(50.0, 9.0, 17.0))
	lm.box("Dark", Vector3(0, 3.0, -74.9), Vector3(4.0, 6.0, 0.5))
	lm.commit(model)

## The Abu al-Haggag mosque built into the east (-X) side of the first
## court on a mound of old debris, with its slender minaret.
static func _abu_haggag(lm: LandmarkMesh) -> void:
	lm.box("Sand", Vector3(-20.0, 4.5, 58.0), Vector3(17.0, 9.0, 19.0))
	lm.box("White", Vector3(-20.0, 12.4, 58.0), Vector3(14.0, 6.8, 16.0))
	lm.lathe("White", Vector3(-20.0, 15.8, 58.0), PackedVector2Array([Vector2(4.2, 0),
		Vector2(3.6, 1.8), Vector2(2.0, 3.4), Vector2(0.0, 4.0)]), 12)
	LandmarkKits.minaret(lm, "White", "White", Vector3(-26.5, 9.0, 51.0), 1.0, 13.0, 1)
