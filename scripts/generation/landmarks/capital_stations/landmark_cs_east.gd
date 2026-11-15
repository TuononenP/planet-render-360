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

## Riga Central Station: the 1960s hall and its 2003 rebuilding with the
## slender glass-and-steel clock tower over the station square.
static func riga_central(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "concrete", "#B9B6AF", "#D0CDC6", "roof_concrete", "#76736D", "#6D777D")
	K.block(lm, "Walls", "Trim", "Glass", "Roof", 0.0, 0.0, 110.0, 40.0, 0.0, 14.0, "flat", 0.0, 3.5, 4.5)
	lm.box("Glass", Vector3(-10, 8.0, 20.4), Vector3(60.0, 14.0, 0.4), Basis(), 0.0)
	K.canopy(lm, "Roof", "Steel", Vector3(-40, 0, 20.0), Vector3(20, 0, 20.0), Vector3.BACK, 7.0, 6.0, 7)
	# The tower: four steel legs, glazed shaft, four dials and a spike.
	var t := Vector3(42.0, 0, 26.0)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			lm.box("Steel", t + Vector3(sx * 2.6, 19.0, sz * 2.6), Vector3(0.7, 38.0, 0.7), Basis(), 0.0)
	lm.box("Glass", t + Vector3.UP * 19.0, Vector3(4.8, 38.0, 4.8), Basis(), 0.0)
	for i in 4:
		var n := Vector3(sin(PI * 0.5 * float(i)), 0, cos(PI * 0.5 * float(i)))
		K.clock(lm, "Dial", "Steel", t + n * 3.0 + Vector3.UP * 34.5, n, 2.0)
	lm.box("Steel", t + Vector3.UP * 38.3, Vector3(6.0, 0.6, 6.0), Basis(), 0.0)
	lm.frustum("Steel", t + Vector3.UP * 38.6, 0.4, 0.05, 6.4, 6)
	lm.commit(model)

## Sofia Central (1974, renewed 2016): the great concrete box of the
## booking hall under its deep overhanging roof slab, glazed between the
## ribs, on the square before it.
static func sofia_central(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "concrete", "#AFA9A0", "#C8C2B9", "roof_concrete", "#8A857D")
	lm.box("Glass", Vector3(0, 11.0, 0), Vector3(120.0, 22.0, 48.0), Basis(), 0.0)
	LandmarkFhParts.ribs(lm, "Walls", Vector3(-60, 0, 24.1), Vector3(60, 0, 24.1), Vector3.BACK, 0.0, 22.0, 6.0, 1.2, 1.4)
	lm.box("Walls", Vector3(0, 23.5, 3.0), Vector3(136.0, 3.0, 62.0))
	lm.box("Trim", Vector3(0, 25.3, 3.0), Vector3(137.0, 0.6, 63.0))
	for s in [-1.0, 1.0]:
		K.block(lm, "Walls", "Trim", "Glass", "Roof", s * 80.0, -6.0, 30.0, 36.0, 0.0, 12.0, "flat", 0.0, 4.0, 4.0)
	lm.commit(model)

## București Nord (1872): the long neoclassical range of the station with
## its taller pedimented centre and pavilions, and the platform canopies.
static func gara_de_nord(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "render", "#D4C6A6", "#E2D7C2", "slate", "#535A60")
	K.block(lm, "Walls", "Trim", "Glass", "Roof", 0.0, 0.0, 160.0, 18.0, 0.0, 11.0, "hip", 3.5, 4.0, 5.0, true)
	K.block(lm, "Walls", "Trim", "Glass", "Roof", 0.0, 1.5, 34.0, 21.0, 0.0, 14.0, "gable_z", 4.0, 3.6, 6.0, true)
	LandmarkFhUtil.columns(lm, "Trim", Vector3(-12, 0, 13.0), Vector3(12, 0, 13.0), 6, 12.5, 0.6)
	lm.box("Trim", Vector3(0, 13.2, 13.0), Vector3(26.0, 1.4, 2.0))
	K.clock(lm, "Dial", "Trim", Vector3(0, 15.8, 12.2), Vector3.BACK, 1.1)
	for s in [-1.0, 1.0]:
		K.block(lm, "Walls", "Trim", "Glass", "Roof", s * 74.0, 1.0, 14.0, 20.0, 0.0, 13.0, "hip", 4.0, 3.5, 5.0, true)
	for i in 5:
		K.shed(lm, "Roof", "Steel", "Glass", Vector3(-80, 0, -16.0 - 13.0 * float(i)), Vector3.RIGHT, 10.0, 160.0, 4.5,
			1.2, 10.0, 0.3, 0)
	lm.commit(model)

## Athens' Larissis station (1904): the small two-storey neoclassical
## building with its pedimented centre on Theodorou Diligianni.
static func athens_larissis(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "render", "#D9C9A8", "#E7DCC7", "terracotta", "#A0583A")
	K.block(lm, "Walls", "Trim", "Glass", "Roof", 0.0, 0.0, 66.0, 14.0, 0.0, 9.5, "hip", 2.6, 3.8, 4.4, true)
	K.block(lm, "Walls", "Trim", "Glass", "Roof", 0.0, 0.5, 16.0, 15.0, 0.0, 10.5, "gable_z", 2.5, 3.2, 4.8, true)
	K.clock(lm, "Dial", "Trim", Vector3(0, 11.6, 8.1), Vector3.BACK, 0.6)
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

## Ankara Garı (Şekip Akalın, 1937): the Art Deco hall of travertine with
## its tall ribbed front between flat-roofed wings and the canopy over the
## entrance, the end pavilions on Talat Paşa Bulvarı.
static func ankara_gari(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "limestone", "#D2C3A2", "#E2D7C0", "roof_concrete", "#8D877E")
	K.block(lm, "Walls", "Trim", "Glass", "Roof", 0.0, 0.0, 36.0, 30.0, 0.0, 22.0, "flat", 0.0, 4.0, 5.0)
	LandmarkFhParts.ribs(lm, "Trim", Vector3(-16, 0, 15.05), Vector3(16, 0, 15.05), Vector3.BACK, 3.0, 21.0, 3.2, 0.9, 0.7)
	LandmarkFhUtil.openings(lm, "Glass", Vector3(-15, 0, 15.1), Vector3(15, 0, 15.1), Vector3.BACK, 5.0, 10, 1.6, 14.0,
		false)
	K.canopy(lm, "Trim", "Trim", Vector3(-16, 0, 15.0), Vector3(16, 0, 15.0), Vector3.BACK, 6.0, 4.6, 2)
	K.clock(lm, "Dial", "Trim", Vector3(0, 19.8, 15.8), Vector3.BACK, 1.2)
	for s in [-1.0, 1.0]:
		K.block(lm, "Walls", "Trim", "Glass", "Roof", s * 48.0, -2.0, 60.0, 24.0, 0.0, 12.0, "flat", 0.0, 3.6, 4.5)
		K.block(lm, "Walls", "Trim", "Glass", "Roof", s * 84.0, -1.0, 12.0, 26.0, 0.0, 15.0, "flat", 0.0, 3.0, 4.5)
	lm.commit(model)
