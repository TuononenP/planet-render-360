class_name LandmarkCsEast
extends RefCounted

## Capital termini of eastern and south-eastern Europe in the station
## frame (+X along the main facade, +Z the forecourt): Tallinn Balti jaam,
## Riga Central, Sofia Central, București Nord, Athens (Larissis), Kyiv
## Passenger and Ankara Garı.

const K = preload("res://scripts/generation/landmarks/capital_stations/landmark_station_kit.gd")

## Tallinn's Baltic Station (Gersfeld, 1870): the low limestone range of
## two storeys with its taller centre and end pavilions under hipped roofs.
static func balti_jaam(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "limestone", "#C9C1AE", "#D9D2C2", "slate", "#4B5257")
	K.block(lm, "Walls", "Trim", "Glass", "Roof", 0.0, 0.0, 120.0, 16.0, 0.0, 9.5, "hip", 4.0, 4.0, 4.5, true)
	K.block(lm, "Walls", "Trim", "Glass", "Roof", 0.0, 0.5, 24.0, 18.0, 0.0, 11.5, "hip", 4.5, 3.6, 5.0, true)
	for s in [-1.0, 1.0]:
		K.block(lm, "Walls", "Trim", "Glass", "Roof", s * 56.0, 0.5, 12.0, 18.0, 0.0, 10.5, "hip", 4.0, 3.6, 5.0, true)
	K.clock(lm, "Dial", "Trim", Vector3(0, 9.6, 9.6), Vector3.BACK, 1.0)
	for i in 3:
		K.shed(lm, "Roof", "Steel", "Glass", Vector3(-60, 0, -14.0 - 12.0 * float(i)), Vector3.RIGHT, 9.0, 120.0,
			4.0, 1.0, 12.0, 0.2, 0)
	lm.commit(model)

## Riga Central Station: the 1960s hall and its 2003 rebuilding, pale
## concrete with a full-width sky-grey glass front and canopy, and the
## slender light steel-and-glass clock tower (about 30 m) over the square.
static func riga_central(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "concrete", "#D8D6CF", "#E4E2DC", "roof_concrete", "#8C8A84", "#D0D4D8")
	lm.use("Glass", LandmarkMaterials.glass("#8FA3B3"))
	K.block(lm, "Walls", "Trim", "Glass", "Roof", 0.0, 0.0, 110.0, 40.0, 0.0, 14.0, "flat", 0.0, 3.5, 4.5)
	lm.box("Glass", Vector3(-10, 7.0, 20.4), Vector3(60.0, 12.0, 0.4), Basis(), 0.0)
	K.canopy(lm, "Trim", "Steel", Vector3(-40, 0, 20.0), Vector3(20, 0, 20.0), Vector3.BACK, 7.0, 6.0, 7)
	# The tower: four light steel legs round a glazed shaft, four dials, a
	# flat cap and a short mast.
	var t := Vector3(42.0, 0, 26.0)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			lm.box("Steel", t + Vector3(sx * 2.0, 14.5, sz * 2.0), Vector3(0.6, 29.0, 0.6), Basis(), 0.0)
	lm.box("Glass", t + Vector3.UP * 14.5, Vector3(3.6, 29.0, 3.6), Basis(), 0.0)
	for k in 6:
		lm.box("Steel", t + Vector3.UP * (4.0 + 4.0 * float(k)), Vector3(4.4, 0.3, 4.4), Basis(), 0.0)
	for i in 4:
		var n := Vector3(sin(PI * 0.5 * float(i)), 0, cos(PI * 0.5 * float(i)))
		K.clock(lm, "Dial", "Steel", t + n * 2.35 + Vector3.UP * 26.0, n, 1.6)
	lm.box("Steel", t + Vector3.UP * 29.2, Vector3(5.0, 0.4, 5.0), Basis(), 0.0)
	lm.frustum("Steel", t + Vector3.UP * 29.4, 0.25, 0.05, 3.6, 6)
	lm.commit(model)

## Sofia Central (1974, renewed 2016): the booking hall's light grey-blue
## glazing between tapered concrete piers that lean out to carry the deep
## roof slab, its ribbed soffit rising to a thin white edge 10-12 m over
## the forecourt, the white entrance pavilions and the lower wings.
static func sofia_central(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "concrete", "#D4D0C8", "#F0EEE8", "roof_concrete", "#B8B4AC")
	lm.use("Glass", LandmarkMaterials.glass("#9DB0BE"))
	lm.box("Glass", Vector3(0, 10.0, 0), Vector3(120.0, 20.0, 48.0), Basis(), 0.0)
	LandmarkFhParts.ribs(lm, "Trim", Vector3(-60, 0, 24.05), Vector3(60, 0, 24.05), Vector3.BACK, 0.0, 20.0, 3.0, 0.15, 0.15)
	for k in 20:
		var x := -57.0 + 6.0 * float(k)
		lm.beam("Walls", Vector3(x, 0, 27.0), Vector3(x, 22.0, 31.0), 1.1, 1.4)
		lm.beam("Walls", Vector3(x, 0, -27.0), Vector3(x, 22.0, -30.0), 1.1, 1.4)
	lm.box("Walls", Vector3(0, 22.6, 2.0), Vector3(128.0, 1.2, 66.0))
	lm.box("Trim", Vector3(0, 23.0, 35.0), Vector3(128.0, 1.6, 0.6))
	for x in [-30.0, 0.0, 30.0]:
		lm.box("Trim", Vector3(x, 2.5, 25.5), Vector3(8.0, 5.0, 3.0))
	for s in [-1.0, 1.0]:
		K.block(lm, "Walls", "Trim", "Glass", "Roof", s * 80.0, -6.0, 30.0, 36.0, 0.0, 12.0, "flat", 0.0, 4.0, 4.0)
	lm.commit(model)

## București Nord (1872), a terminus: the head building on Piața Gării
## de Nord, a flat-roofed grey stone portico of eight square piers (about
## 14 m) beside the slender ochre clock tower (about 35 m) with its
## cornice, clocks and flag, and the long neoclassical ranges with hipped
## slate roofs running back along the tracks to the platform canopies.
static func gara_de_nord(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "render", "#D6BE8A", "#BDB6A8", "slate", "#535A60")
	lm.box("Trim", Vector3(-6, 14.6, 4.0), Vector3(72.0, 1.4, 12.0))
	lm.box("Walls", Vector3(-6, 8.0, -2.0), Vector3(72.0, 16.0, 4.0))
	for k in 8:
		lm.box("Trim", Vector3(-38.0 + 9.0 * float(k), 7.0, 9.0), Vector3(1.8, 14.0, 1.8))
	lm.box("Glass", Vector3(-6, 6.0, 0.1), Vector3(68.0, 11.0, 0.1), Basis(), 0.0)
	var t := Vector3(36.0, 0, 2.0)
	K.block(lm, "Walls", "Trim", "Glass", "Roof", t.x, t.z, 14.0, 14.0, 0.0, 33.0, "flat", 0.0, 3.5, 4.1)
	for i in 4:
		var n := Vector3(sin(PI * 0.5 * float(i)), 0, cos(PI * 0.5 * float(i)))
		K.clock(lm, "Dial", "Trim", t + n * 7.0 + Vector3.UP * 30.0, n, 1.6)
	lm.box("Trim", t + Vector3.UP * 33.4, Vector3(15.0, 0.8, 15.0))
	lm.box("Steel", t + Vector3.UP * 35.0, Vector3(0.15, 3.2, 0.15), Basis(), 0.0)
	for s in [-1.0, 1.0]:
		K.block(lm, "Walls", "Trim", "Glass", "Roof", s * 46.0, -105.0, 16.0, 190.0, 0.0, 12.0, "hip", 4.0, 4.2, 5.0, true)
	for i in 5:
		K.shed(lm, "Roof", "Steel", "Glass", Vector3(-28.0 + 14.0 * float(i), 0, -12.0), Vector3.FORWARD, 11.0, 190.0,
			4.5, 1.2, 10.0, 0.3, 0)
	lm.commit(model)

## Athens' Larissis station (1904): the flat-roofed two-storey cream
## block behind its parapet, rectangular upper windows over a ground
## floor portico of square columns, and a low raised centre.
static func athens_larissis(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "render", "#E0CFA8", "#ECE2CC", "roof_concrete", "#9C968C")
	K.block(lm, "Walls", "Trim", "Glass", "Roof", 0.0, 0.0, 66.0, 14.0, 0.0, 10.0, "flat", 0.0, 3.8, 4.6)
	K.block(lm, "Walls", "Trim", "Glass", "Roof", 0.0, 0.4, 16.0, 14.8, 0.0, 11.5, "flat", 0.0, 3.2, 4.6)
	lm.box("Trim", Vector3(0, 10.6, 0), Vector3(66.6, 1.2, 14.6))
	for k in 12:
		lm.box("Trim", Vector3(-27.5 + 5.0 * float(k), 2.2, 8.6), Vector3(0.7, 4.4, 0.7))
	lm.box("Trim", Vector3(0, 4.6, 8.0), Vector3(58.0, 0.5, 2.0))
	K.clock(lm, "Dial", "Trim", Vector3(0, 9.6, 7.6), Vector3.BACK, 0.6)
	K.canopy(lm, "Steel", "Steel", Vector3(-30, 0, -7.0), Vector3(30, 0, -7.0), Vector3.FORWARD, 6.0, 4.5, 6)
	lm.commit(model)

## Kyiv Passenger station (Oleksandr Verbytsky, 1932): the Ukrainian
## baroque front with its great arched portal window over the station
## square, the pediment, side wings with corner pavilions under domed
## roofs, and the platform canopies behind.
static func kyiv_passenger(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "render", "#D7C7A3", "#E6DDC9", "sheet_metal", "#6D7B7E")
	K.block(lm, "Walls", "Trim", "Glass", "Roof", 0.0, 0.0, 44.0, 40.0, 0.0, 28.0, "flat", 0.0, 4.0, 6.0)
	K.arch_window(lm, "Trim", "Glass", Vector3(0, 3.0, 20.05), Vector3.BACK, 22.0, 24.0, 6, 1.6)
	lm.gable("Roof", Vector3(0, 28.0, 0), 44.0, 40.0, 8.0, Basis(Vector3.UP, PI * 0.5), 0.4, "Walls")
	K.clock(lm, "Dial", "Trim", Vector3(0, 30.4, 20.3), Vector3.BACK, 1.6)
	for s in [-1.0, 1.0]:
		K.block(lm, "Walls", "Trim", "Glass", "Roof", s * 52.0, -2.0, 60.0, 30.0, 0.0, 16.0, "hip", 4.0, 4.0, 5.0, true)
		var c := Vector3(s * 86.0, 0, 0)
		K.block(lm, "Walls", "Trim", "Glass", "Roof", c.x, 0.0, 14.0, 34.0, 0.0, 19.0, "flat", 0.0, 3.5, 5.0, true)
		lm.lathe("Roof", c + Vector3.UP * 19.0, LandmarkFhUtil.dome_prof(6.5, 5.0), 4, 1.0, 2.4, PI * 0.25, false)
	for i in 5:
		K.shed(lm, "Roof", "Steel", "Glass", Vector3(-100, 0, -26.0 - 12.0 * float(i)), Vector3.RIGHT, 9.0, 200.0, 4.5,
			1.0, 12.0, 0.2, 0)
	lm.commit(model)

## Ankara Garı (Şekip Akalın, 1937): the pale travertine Art Deco hall
## whose front is a portico of six tall square piers with glazing behind,
## the red name sign on its parapet, the two half-cylinder towers rising
## above the hall's corners with their strip windows and flags, and the
## ochre wings either side.
static func ankara_gari(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "limestone", "#CDB08A", "#E6D8BE", "roof_concrete", "#8D877E")
	lm.use("Wing", LandmarkMaterials.pbr("render", "#C9A77A", 3.0))
	lm.use("Sign", LandmarkMaterials.lit("#B3262A", 0.4))
	K.block(lm, "Walls", "Trim", "Glass", "Roof", 0.0, -2.0, 36.0, 28.0, 0.0, 22.0, "flat", 0.0, 4.0, 5.0)
	lm.box("Glass", Vector3(0, 9.5, 12.1), Vector3(30.0, 17.0, 0.1), Basis(), 0.0)
	for k in 6:
		lm.box("Walls", Vector3(-15.0 + 6.0 * float(k), 9.5, 14.0), Vector3(1.8, 19.0, 1.8))
	lm.box("Walls", Vector3(0, 20.0, 14.0), Vector3(36.0, 2.0, 2.4))
	lm.box("Sign", Vector3(0, 20.0, 15.3), Vector3(16.0, 1.4, 0.15), Basis(), 0.0)
	for s in [-1.0, 1.0]:
		var c := Vector3(s * 18.0, 0, 12.0)
		lm.lathe("Walls", c, PackedVector2Array([Vector2(4.0, 0.0), Vector2(4.0, 28.0)]), 16)
		lm.lathe("Trim", c + Vector3.UP * 28.0, PackedVector2Array([Vector2(4.3, 0.0), Vector2(4.3, 0.6),
			Vector2(0.0, 0.7)]), 16)
		lm.box("Glass", c + Vector3(0, 15.0, 4.02), Vector3(1.0, 20.0, 0.1), Basis(), 0.0)
		lm.box("Steel", c + Vector3.UP * 30.7, Vector3(0.12, 4.0, 0.12), Basis(), 0.0)
		K.block(lm, "Wing", "Trim", "Glass", "Roof", s * 48.0, -2.0, 60.0, 24.0, 0.0, 12.0, "flat", 0.0, 3.6, 4.5)
		K.block(lm, "Wing", "Trim", "Glass", "Roof", s * 84.0, -1.0, 12.0, 26.0, 0.0, 15.0, "flat", 0.0, 3.0, 4.5)
	lm.commit(model)
