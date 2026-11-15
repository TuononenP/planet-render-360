class_name LandmarkCsAmericasAfrica
extends RefCounted

## Capital stations of the Americas and Africa in the station frame (+X
## along the main facade, +Z the forecourt): Washington Union Station,
## Buenos Aires Retiro Mitre, Santiago's Estación Central, Mexico City's
## Buenavista, Cairo's Ramses Station and Maputo's CFM station.

const K = preload("res://scripts/generation/landmarks/capital_stations/landmark_station_kit.gd")

## Daniel Burnham's Union Station (1907): the white granite Beaux-Arts
## front on Columbus Circle, its central triple arch after the Arch of
## Constantine rising almost the full height, with the six statues on the
## attic over its columns; the barrel-vaulted main hall behind under its
## terracotta roof, the long wings and the open arched loggias of the end
## pavilions.
static func union_station_dc(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "limestone", "#E2DDD0", "#ECE8DE", "terracotta", "#A65A3E")
	K.block(lm, "Walls", "Trim", "Glass", "Roof", 0.0, -8.0, 66.0, 40.0, 0.0, 20.0, "barrel", 9.0, 6.0, 7.0)
	K.arch_row(lm, "Trim", "Glass", Vector3(-24, 0, 12.05), Vector3(24, 0, 12.05), Vector3.BACK, 0.6, 3, 12.0, 15.5, 3)
	LandmarkFhUtil.columns(lm, "Trim", Vector3(-24, 0, 13.4), Vector3(24, 0, 13.4), 4, 17.0, 0.9)
	lm.box("Trim", Vector3(0, 17.8, 12.8), Vector3(66.0, 1.6, 1.8))
	lm.box("Walls", Vector3(0, 23.5, 11.5), Vector3(56.0, 7.0, 2.0))
	for i in 6:
		K.statue(lm, "Trim", Vector3(-24.0 + 9.6 * float(i), 18.6, 13.4), 5.0)
	for s in [-1.0, 1.0]:
		K.block(lm, "Walls", "Trim", "Glass", "Roof", s * 67.0, -2.0, 68.0, 26.0, 0.0, 15.0, "flat", 0.0, 6.0, 7.0, true)
		K.block(lm, "Walls", "Trim", "Glass", "Roof", s * 106.0, -2.0, 12.0, 30.0, 0.0, 18.0, "flat", 0.0, 4.0, 7.0)
		K.arch_row(lm, "Trim", "Glass", Vector3(s * 106.0 - 5.0, 0, 13.05), Vector3(s * 106.0 + 5.0, 0, 13.05),
			Vector3.BACK, 0.6, 2, 3.6, 9.0, 0)
	lm.commit(model)

## Retiro Mitre (Conder, Follet and Farmer, 1915): the cream rendered
## Edwardian front on Avenida Ramos Mejía, its central slate dome with a
## lantern over the entrance and the corner towers under dark slate
## mansard cupolas, the clock, slate roofs, and the two great iron sheds
## built in Liverpool behind it.
static func retiro_mitre(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "render", "#D6C49A", "#E6DCC4", "slate", "#5C6A78", "#4A5056")
	for s in [-1.0, 1.0]:
		K.shed(lm, "Roof", "Steel", "Glass", Vector3(s * 26.0, 0, -18), Vector3.FORWARD, 50.0, 250.0, 12.0, 14.0, 10.0,
			0.5, 1)
	K.block(lm, "Walls", "Trim", "Glass", "Roof", 0.0, 0.0, 120.0, 36.0, 0.0, 18.0, "mansard", 4.0, 4.5, 5.5, true)
	var m := Vector3(0, 22.0, 10.0)
	lm.lathe("Walls", m, PackedVector2Array([Vector2(7.0, 0.0), Vector2(7.0, 3.0)]), 16)
	lm.lathe("Roof", m + Vector3.UP * 3.0, LandmarkFhUtil.dome_prof(7.4, 6.5), 16)
	lm.lathe("Trim", m + Vector3.UP * 9.5, PackedVector2Array([Vector2(1.6, 0.0), Vector2(1.6, 2.4)]), 8)
	lm.lathe("Roof", m + Vector3.UP * 11.9, LandmarkFhUtil.dome_prof(1.9, 1.6), 8)
	for s in [-1.0, 1.0]:
		var c := Vector3(s * 52.0, 0, 12.0)
		K.block(lm, "Walls", "Trim", "Glass", "Roof", c.x, c.z, 14.0, 14.0, 0.0, 24.0, "flat", 0.0, 3.4, 5.5, true)
		LandmarkFhUtil.hip(lm, "Roof", c + Vector3.UP * 24.0, 14.6, 14.6, 5.0, 0.4)
		lm.box("Trim", c + Vector3.UP * 29.4, Vector3(3.0, 0.8, 3.0))
		lm.frustum("Trim", c + Vector3.UP * 29.8, 0.5, 0.15, 1.6, 8)
	K.clock(lm, "Dial", "Trim", Vector3(0, 15.0, 18.2), Vector3.BACK, 2.0)
	lm.commit(model)

## Santiago's Estación Central (1897): the iron shed built by
## Schneider-Creusot, dark green-grey, with vertical side walls rising to
## curved shoulders and a pitched crown; its end over the Alameda mostly
## open lattice under the clock on the apex, between the two tall white
## two-storey neoclassical blocks with their pilasters and great arched
## windows.
static func estacion_central(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "render", "#ECE6D8", "#F4F0E6", "sheet_metal", "#5E6B6A", "#3E4A48")
	# The shed section (x, y): walls, shoulders and the pitched crown.
	var prof := [Vector2(-26.0, 0.0), Vector2(-26.0, 12.0), Vector2(-23.0, 16.5), Vector2(-17.0, 19.0), Vector2(0.0, 24.0),
		Vector2(17.0, 19.0), Vector2(23.0, 16.5), Vector2(26.0, 12.0), Vector2(26.0, 0.0)]
	var l := 220.0
	for i in prof.size() - 1:
		var p0: Vector2 = prof[i]
		var p1: Vector2 = prof[i + 1]
		var key := "Glass" if i == 3 or i == 4 else "Roof"
		var n := Vector3(p1.y - p0.y, -(p1.x - p0.x), 0).normalized() * -1.0
		lm.quad(key, Vector3(p0.x, p0.y, 0), Vector3(p1.x, p1.y, 0), Vector3(p1.x, p1.y, -l), Vector3(p0.x, p0.y, -l), n)
		lm.quad(key, Vector3(p1.x, p1.y, 0), Vector3(p0.x, p0.y, 0), Vector3(p0.x, p0.y, -l), Vector3(p1.x, p1.y, -l), -n)
		lm.beam("Steel", Vector3(p0.x, p0.y, 0.4), Vector3(p1.x, p1.y, 0.4), 0.8, 0.8)
	for k in 12:
		var z := -l * float(k) / 11.0
		for i in prof.size() - 1:
			var p0: Vector2 = prof[i]
			var p1: Vector2 = prof[i + 1]
			lm.beam("Steel", Vector3(p0.x, p0.y, z), Vector3(p1.x, p1.y, z), 0.4, 0.6)
	# The open lattice end: posts and diagonals under the crown.
	for k in 9:
		var x := -24.0 + 6.0 * float(k)
		var top := 24.0 - absf(x) * 0.29 if absf(x) < 17.0 else 19.0 - (absf(x) - 17.0) * 0.4
		lm.beam("Steel", Vector3(x, 0, 0.4), Vector3(x, top, 0.4), 0.35, 0.35)
		if k < 8:
			lm.beam("Steel", Vector3(x, 4.0, 0.45), Vector3(x + 6.0, top - 3.0, 0.45), 0.2, 0.2)
	K.clock(lm, "Dial", "Steel", Vector3(0, 20.5, 0.6), Vector3.BACK, 1.8)
	for s in [-1.0, 1.0]:
		var x: float = s * 35.0
		K.block(lm, "Walls", "Trim", "Glass", "Roof", x, -8.0, 18.0, 22.0, 0.0, 14.5, "flat", 0.0, 4.0, 6.0, true)
		K.arch_window(lm, "Trim", "Glass", Vector3(x, 1.0, 3.05), Vector3.BACK, 5.0, 9.0, 2)
		LandmarkFhParts.strips(lm, "Trim", Vector3(x - 8.5, 0, 3.0), Vector3(x + 8.5, 0, 3.0), Vector3.BACK, 0.0, 14.0, 4,
			0.9, 0.4)
		K.block(lm, "Walls", "Trim", "Glass", "Roof", s * 32.0, -110.0, 12.0, 170.0, 0.0, 8.0, "gable_z", 2.5, 4.0, 4.5, true)
	lm.commit(model)

## Mexico City's Buenavista (2008, the Tren Suburbano terminal): the long
## low glass box with white mullions under its flat terracotta-red roof
## and deep royal-blue fascia with a white line, the lower red-roofed
## blocks stepping down at one end, the red forecourt canopy, and the
## platform canopies behind.
static func buenavista(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "concrete", "#D9D6CF", "#F2F2EE", "terracotta", "#B85A3F", "#F2F2EE")
	lm.use("Glass", LandmarkMaterials.glass("#9DB2C2"))
	lm.use("Fascia", LandmarkMaterials.pbr("render", "#2A4A9A", 2.0))
	lm.box("Glass", Vector3(0, 5.0, 0), Vector3(150.0, 10.0, 40.0), Basis(), 0.0)
	LandmarkFhParts.ribs(lm, "Steel", Vector3(-75, 0, 20.05), Vector3(75, 0, 20.05), Vector3.BACK, 0.0, 10.0, 3.0, 0.2, 0.2)
	LandmarkFhParts.ribs(lm, "Steel", Vector3(-75, 0, -20.05), Vector3(75, 0, -20.05), Vector3.FORWARD, 0.0, 10.0, 3.0,
		0.2, 0.2)
	lm.box("Fascia", Vector3(0, 10.0, 0), Vector3(152.0, 2.0, 42.0))
	lm.box("Trim", Vector3(0, 10.9, 0), Vector3(152.2, 0.2, 42.2))
	lm.box("Roof", Vector3(0, 11.1, 0), Vector3(151.0, 0.2, 41.0))
	for i in 2:
		var x := 92.0 + 24.0 * float(i)
		lm.box("Walls", Vector3(x, 3.5, -4.0), Vector3(22.0, 7.0, 30.0))
		lm.box("Fascia", Vector3(x, 7.4, -4.0), Vector3(23.0, 0.8, 31.0))
		lm.box("Roof", Vector3(x, 7.9, -4.0), Vector3(22.6, 0.2, 30.6))
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

## Maputo's CFM station (1916): the pale mint-green front with white
## trim, its taller central pavilion with the great arched entrance, the
## clock and the curved parapet under the ribbed, bell-shaped dark bronze
## dome with its lantern (about 30 m), the two-storey wings with arched
## upper windows and wrought iron verandas, the end pavilions under dark
## grey mansards, and the platform canopies behind.
static func maputo(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "render", "#C8DCC6", "#F4F2EA", "slate", "#4A4F52", "#3E6B57")
	lm.use("Bronze", LandmarkMaterials.pbr("copper", "#3E4346", 2.0, -1.0, 0.4))
	K.block(lm, "Walls", "Trim", "Glass", "Roof", 0.0, 0.0, 26.0, 24.0, 0.0, 16.0, "flat", 0.0, 3.5, 5.0, true)
	var c := Vector3(0, 16.0, 0)
	lm.lathe("Walls", c, PackedVector2Array([Vector2(8.0, 0.0), Vector2(8.0, 2.0)]), 20)
	lm.lathe("Bronze", c + Vector3.UP * 2.0, PackedVector2Array([Vector2(8.4, 0.0), Vector2(8.0, 2.5), Vector2(6.8, 5.5),
		Vector2(4.6, 8.2), Vector2(2.0, 9.6), Vector2(1.4, 10.0)]), 20)
	for k in 12:
		var a := TAU * float(k) / 12.0
		var d := Vector3(cos(a), 0, sin(a))
		lm.beam("Trim", c + d * 8.45 + Vector3.UP * 2.0, c + d * 1.5 + Vector3.UP * 12.0, 0.25, 0.25)
	lm.lathe("Bronze", c + Vector3.UP * 12.0, PackedVector2Array([Vector2(1.4, 0.0), Vector2(1.4, 1.8), Vector2(0.0, 2.6)]), 8)
	lm.frustum("Gilt", c + Vector3.UP * 14.6, 0.12, 0.04, 1.4, 6)
	K.clock(lm, "Dial", "Trim", Vector3(0, 13.0, 12.2), Vector3.BACK, 1.5)
	K.arch_window(lm, "Trim", "Glass", Vector3(0, 0.6, 12.05), Vector3.BACK, 8.0, 10.5, 3)
	for s in [-1.0, 1.0]:
		K.block(lm, "Walls", "Trim", "Glass", "Roof", s * 31.0, -1.0, 36.0, 20.0, 0.0, 12.0, "flat", 0.0, 4.0, 5.5, true)
		K.arch_row(lm, "Trim", "Glass", Vector3(s * 31.0 - 16.0, 0, 9.05), Vector3(s * 31.0 + 16.0, 0, 9.05), Vector3.BACK,
			6.6, 7, 2.2, 4.0, 1)
		LandmarkFhUtil.columns(lm, "Steel", Vector3(s * 14.0, 0, 11.5), Vector3(s * 48.0, 0, 11.5), 10, 6.0, 0.15, 6)
		lm.box("Steel", Vector3(s * 31.0, 6.1, 10.3), Vector3(34.0, 0.3, 2.6), Basis(), 0.0)
		K.block(lm, "Walls", "Trim", "Glass", "Roof", s * 55.0, 0.0, 12.0, 22.0, 0.0, 13.0, "mansard", 4.0, 3.6, 5.5, true)
	for i in 3:
		K.shed(lm, "Roof", "Steel", "Glass", Vector3(-60, 0, -14.0 - 12.0 * float(i)), Vector3.RIGHT, 9.0, 120.0, 4.5,
			1.0, 12.0, 0.2, 0)
	lm.commit(model)
