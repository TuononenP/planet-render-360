class_name LandmarkCsAmericasAfrica
extends RefCounted

## Capital stations of the Americas and Africa in the station frame (+X
## along the main facade, +Z the forecourt): Washington Union Station,
## Buenos Aires Retiro Mitre, Santiago's Estación Central, Mexico City's
## Buenavista, Cairo's Ramses Station and Maputo's CFM station.

const K = preload("res://scripts/generation/landmarks/capital_stations/landmark_station_kit.gd")

## Daniel Burnham's Union Station (1907): the white granite Beaux-Arts
## front on Columbus Circle, its central triple arch after the Arch of
## Constantine with the six statues over the columns, the barrel-vaulted
## main hall behind it and the long arcaded wings.
static func union_station_dc(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "limestone", "#E2DDD0", "#ECE8DE", "roof_concrete", "#9C9A93")
	K.block(lm, "Walls", "Trim", "Glass", "Roof", 0.0, -8.0, 66.0, 40.0, 0.0, 20.0, "barrel", 9.0, 6.0, 7.0)
	K.arch_row(lm, "Trim", "Glass", Vector3(-24, 0, 12.05), Vector3(24, 0, 12.05), Vector3.BACK, 0.8, 3, 11.0, 17.0, 3)
	LandmarkFhUtil.columns(lm, "Trim", Vector3(-24, 0, 13.4), Vector3(24, 0, 13.4), 4, 16.0, 0.9)
	lm.box("Trim", Vector3(0, 17.0, 12.8), Vector3(66.0, 2.0, 1.8))
	lm.box("Walls", Vector3(0, 23.5, 11.5), Vector3(56.0, 7.0, 2.0))
	for i in 6:
		K.statue(lm, "Trim", Vector3(-24.0 + 9.6 * float(i), 18.0, 13.4), 5.0)
	for s in [-1.0, 1.0]:
		K.block(lm, "Walls", "Trim", "Glass", "Roof", s * 67.0, -2.0, 68.0, 26.0, 0.0, 15.0, "flat", 0.0, 6.0, 7.0, true)
		K.block(lm, "Walls", "Trim", "Glass", "Roof", s * 106.0, -2.0, 12.0, 30.0, 0.0, 18.0, "flat", 0.0, 4.0, 7.0, true)
	lm.commit(model)

## Retiro Mitre (Conder, Follet and Farmer, 1915): the brick and stone
## Edwardian front on Avenida Ramos Mejía with its corner towers under
## copper domes, the clock, and the two great iron sheds built in
## Liverpool behind it.
static func retiro_mitre(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "brick", "#A9644A", "#DDD2BE", "copper", "#5F8E7C")
	for s in [-1.0, 1.0]:
		K.shed(lm, "Roof", "Steel", "Glass", Vector3(s * 26.0, 0, -18), Vector3.FORWARD, 50.0, 250.0, 12.0, 14.0, 10.0,
			0.5, 1)
	K.block(lm, "Walls", "Trim", "Glass", "Roof", 0.0, 0.0, 120.0, 36.0, 0.0, 18.0, "mansard", 4.0, 4.5, 5.5, true)
	for s in [-1.0, 1.0]:
		var c := Vector3(s * 52.0, 0, 12.0)
		K.block(lm, "Walls", "Trim", "Glass", "Roof", c.x, c.z, 14.0, 14.0, 0.0, 24.0, "flat", 0.0, 3.4, 5.5, true)
		lm.lathe("Walls", c + Vector3.UP * 24.0, PackedVector2Array([Vector2(5.5, 0.0), Vector2(5.5, 2.0)]), 16)
		lm.lathe("Roof", c + Vector3.UP * 26.0, LandmarkFhUtil.dome_prof(6.0, 5.5), 16)
		lm.frustum("Trim", c + Vector3.UP * 31.5, 0.5, 0.15, 1.5, 8)
	K.clock(lm, "Dial", "Trim", Vector3(0, 15.0, 18.2), Vector3.BACK, 2.0)
	lm.commit(model)

## Santiago's Estación Central (1897): the iron and glass shed built by
## Schneider-Creusot, its glazed lattice end over the Alameda framed by
## the iron piers and the arched truss, and the low halls either side.
static func estacion_central(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "render", "#CFC2A5", "#E0D6C0", "sheet_metal", "#6E7A80", "#3F5A6B")
	K.shed(lm, "Roof", "Steel", "Glass", Vector3(0, 0, 0), Vector3.FORWARD, 52.0, 220.0, 10.0, 15.0, 9.0, 0.4, 3)
	for s in [-1.0, 1.0]:
		lm.box("Steel", Vector3(s * 26.0, 13.0, 0.3), Vector3(1.6, 26.0, 1.6), Basis(), 0.0)
		K.block(lm, "Walls", "Trim", "Glass", "Roof", s * 34.0, -60.0, 14.0, 120.0, 0.0, 8.0, "gable_z", 2.5, 4.0, 4.5, true)
	lm.box("Steel", Vector3(0, 10.0, 0.4), Vector3(52.0, 1.0, 1.2), Basis(), 0.0)
	K.clock(lm, "Dial", "Steel", Vector3(0, 18.0, 0.5), Vector3.BACK, 2.0)
	lm.commit(model)

## Mexico City's Buenavista (2008, the Tren Suburbano terminal): the long
## glazed concourse behind its steel portal frames and the canopy over the
## forecourt.
static func buenavista(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "concrete", "#B3AEA5", "#CBC6BD", "sheet_metal", "#A3A7AA")
	lm.box("Glass", Vector3(0, 8.0, 0), Vector3(150.0, 16.0, 40.0), Basis(), 0.0)
	for i in 11:
		var x := -75.0 + 15.0 * float(i)
		lm.box("Steel", Vector3(x, 9.5, 20.4), Vector3(0.8, 19.0, 0.8), Basis(), 0.0)
		lm.box("Steel", Vector3(x, 9.5, -20.4), Vector3(0.8, 19.0, 0.8), Basis(), 0.0)
		lm.box("Steel", Vector3(x, 19.2, 0), Vector3(0.8, 0.8, 42.0), Basis(), 0.0)
	lm.box("Roof", Vector3(0, 19.8, 0), Vector3(154.0, 0.6, 46.0))
	K.canopy(lm, "Roof", "Steel", Vector3(-40, 0, 20.5), Vector3(40, 0, 20.5), Vector3.BACK, 8.0, 6.0, 9)
	for i in 4:
		K.shed(lm, "Roof", "Steel", "Glass", Vector3(-60, 0, -30.0 - 12.0 * float(i)), Vector3.RIGHT, 10.0, 180.0, 5.0,
			1.0, 12.0, 0.2, 0)
	lm.commit(model)

## Cairo's Ramses Station (Edwin Patrick, 1892): the Islamic revival front
## on Ramses Square, its great pointed-arch portal between two square
## minaret towers, arabesque bands and crenellations.
static func ramses(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "render", "#CDB48E", "#DFCEB0", "roof_concrete", "#8B8174")
	K.block(lm, "Walls", "Trim", "Glass", "Roof", 0.0, 0.0, 90.0, 24.0, 0.0, 16.0, "flat", 0.0, 4.0, 5.0, true)
	LandmarkFhUtil.merlons(lm, "Trim", Vector3(-45, 16.0, 12.0), Vector3(45, 16.0, 12.0), 1.6, 0.8, 1.2, 0.5)
	K.block(lm, "Walls", "Trim", "Glass", "Roof", 0.0, 1.0, 26.0, 26.0, 0.0, 22.0, "flat", 0.0, 4.0, 6.0)
	var top := LandmarkCoreBArchKit.pointed(Vector3(0, 12.0, 14.1), Vector3.RIGHT, 12.0)
	lm.quad("Glass", Vector3(-6, 1.0, 14.06), Vector3(6, 1.0, 14.06), Vector3(6, 12.0, 14.06), Vector3(-6, 12.0, 14.06),
		Vector3.BACK)
	for i in top.size() - 1:
		lm.tri("Glass", Vector3(0, 12.0, 14.06), top[i], top[i + 1], Vector3.BACK, Vector3.BACK, Vector3.BACK,
			Vector2.ZERO, Vector2.ZERO, Vector2.ZERO)
		lm.beam("Trim", top[i] + Vector3(0, 0, 0.1), top[i + 1] + Vector3(0, 0, 0.1), 0.9, 0.4)
	LandmarkFhUtil.merlons(lm, "Trim", Vector3(-13, 22.0, 14.0), Vector3(13, 22.0, 14.0), 1.6, 0.8, 1.2, 0.5)
	for s in [-1.0, 1.0]:
		var c := Vector3(s * 17.0, 0, 9.0)
		lm.box("Walls", c + Vector3.UP * 14.0, Vector3(6.0, 28.0, 6.0))
		lm.lathe("Walls", c + Vector3.UP * 28.0, PackedVector2Array([Vector2(2.4, 0.0), Vector2(2.4, 3.0)]), 8)
		lm.lathe("Roof", c + Vector3.UP * 31.0, LandmarkFhUtil.dome_prof(2.6, 2.5), 12)
		lm.frustum("Gilt", c + Vector3.UP * 33.5, 0.2, 0.05, 1.5, 6)
	K.clock(lm, "Dial", "Trim", Vector3(0, 18.5, 14.2), Vector3.BACK, 1.6)
	lm.commit(model)

## Maputo's CFM station (1916): the white and green front with its great
## central dome of bronze-coloured metal over the hall, the wrought iron
## verandas and lattice of the wings either side.
static func maputo(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "render", "#E9E6D8", "#9EC4A8", "copper", "#5E8471", "#3E6B57")
	K.block(lm, "Walls", "Trim", "Glass", "Roof", 0.0, 0.0, 28.0, 24.0, 0.0, 14.0, "flat", 0.0, 3.5, 5.0, true)
	var c := Vector3(0, 14.0, 0)
	lm.lathe("Walls", c, PackedVector2Array([Vector2(9.0, 0.0), Vector2(9.0, 2.5)]), 20)
	lm.lathe("Roof", c + Vector3.UP * 2.5, LandmarkFhUtil.dome_prof(9.6, 7.0), 20)
	lm.lathe("Roof", c + Vector3.UP * 9.5, PackedVector2Array([Vector2(1.2, 0.0), Vector2(1.2, 1.2), Vector2(0.0, 1.5)]), 8)
	K.clock(lm, "Dial", "Trim", Vector3(0, 11.0, 12.2), Vector3.BACK, 1.5)
	K.arch_window(lm, "Trim", "Glass", Vector3(0, 0.6, 12.05), Vector3.BACK, 8.0, 9.5, 3)
	for s in [-1.0, 1.0]:
		K.block(lm, "Walls", "Trim", "Glass", "Roof", s * 34.0, -1.0, 40.0, 20.0, 0.0, 11.0, "flat", 0.0, 4.0, 5.0, true)
		LandmarkFhUtil.columns(lm, "Steel", Vector3(s * 16.0, 0, 13.5), Vector3(s * 52.0, 0, 13.5), 10, 9.0, 0.2, 6)
		lm.box("Steel", Vector3(s * 34.0, 9.2, 11.7), Vector3(38.0, 0.3, 4.0), Basis(), 0.0)
	for i in 3:
		K.shed(lm, "Roof", "Steel", "Glass", Vector3(-60, 0, -14.0 - 12.0 * float(i)), Vector3.RIGHT, 9.0, 120.0, 4.5,
			1.0, 12.0, 0.2, 0)
	lm.commit(model)
