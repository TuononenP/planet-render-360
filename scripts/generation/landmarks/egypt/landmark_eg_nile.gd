class_name LandmarkEgNile
extends RefCounted

## Three Ptolemaic and Roman temples of the upper Nile in true metres,
## entrance toward +Z and sanctuary toward -Z (registry yaw_deg turns
## them onto the real axis): Philae (Isis, relocated to Agilkia), Edfu
## (Horus) and Kom Ombo (Sobek and Haroeris).

# --- Philae ---

## Temple of Isis on Agilkia Island: the 45 m first pylon (18 m), the
## forecourt with the birth house (mammisi) west and the east colonnade,
## the 32 m second pylon, the long roofed temple, Hadrian's gate and, 72 m
## east, the unroofed Kiosk of Trajan. Origin at the centre of the temple.
static func philae(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Sand", LandmarkMaterials.pbr("stone", "#CDB083", 3.2))
	lm.use("Dark", LandmarkMaterials.pbr("stone", "#3A2E22", 2.0))
	lm.use("Ground", LandmarkMaterials.pbr("sand", "#D2BA8A", 8.0))
	lm.box("Ground", Vector3(14.0, -0.4, 16.0), Vector3(130.0, 1.0, 86.0))
	LandmarkEgParts.pylon(lm, "Sand", "Dark", Vector3(0, 0, 48.0), 45.0, 18.0, 9.0, 7.0)
	LandmarkEgParts.pylon(lm, "Sand", "Dark", Vector3(0, 0, 24.0), 32.0, 12.5, 6.0, 5.0)
	# The temple proper: pronaos front, roofed body, cavetto cornice.
	lm.box("Sand", Vector3(0, 4.75, 0), Vector3(27.0, 9.5, 38.0))
	LandmarkEgParts.taper(lm, "Sand", Vector3(0, 9.5, 0), 27.0, 38.0, 29.6, 40.6, 1.3)
	lm.box("Dark", Vector3(0, 3.0, 19.2), Vector3(3.0, 6.0, 0.4))
	for x in [-8.0, -4.5, 4.5, 8.0]:
		LandmarkEgParts.column(lm, "Sand", Vector3(x, 0, 21.0), 0.6, 8.2, LandmarkEgParts.OPEN)
	lm.box("Sand", Vector3(0, 8.8, 21.0), Vector3(20.0, 1.0, 2.6))
	# Mammisi (birth house) west of the forecourt, east colonnade opposite.
	lm.box("Sand", Vector3(-26.0, 4.0, 36.0), Vector3(13.0, 8.0, 22.0))
	LandmarkEgParts.taper(lm, "Sand", Vector3(-26.0, 8.0, 36.0), 13.0, 22.0, 14.8, 23.8, 1.0)
	LandmarkEgParts.colonnade(lm, "Sand", Vector3(-19.2, 0, 44.0), Vector3(-19.2, 0, 28.0), 5, 0.5,
		6.6, LandmarkEgParts.OPEN)
	LandmarkEgParts.colonnade(lm, "Sand", Vector3(17.0, 0, 44.0), Vector3(17.0, 0, 28.0), 7, 0.55,
		6.6, LandmarkEgParts.OPEN)
	lm.box("Sand", Vector3(17.0, 7.1, 36.0), Vector3(3.0, 0.9, 19.0))
	LandmarkEgParts.wall(lm, "Sand", Vector2(21.0, 45.0), Vector2(21.0, 27.0), 7.2, 1.4)
	# Gate of Hadrian, west of the temple.
	for s in [-1.0, 1.0]:
		lm.box("Sand", Vector3(-23.0 + s * 2.5, 3.5, -1.0), Vector3(1.6, 7.0, 3.6))
	lm.box("Sand", Vector3(-23.0, 7.4, -1.0), Vector3(6.6, 1.2, 4.0))
	_kiosk(lm, Vector3(72.0, 0, 30.0))
	lm.commit(model)

## Kiosk of Trajan: a 16 x 21 m platform ringed by 14 open-papyrus
## columns (4 per end, 3 along each side) joined by half-height screen
## walls, never roofed.
static func _kiosk(lm: LandmarkMesh, c: Vector3) -> void:
	lm.box("Sand", c + Vector3(0, 0.8, 0), Vector3(16.0, 1.6, 21.0))
	var spots: Array[Vector2] = []
	for x in [-6.0, -2.0, 2.0, 6.0]:
		spots.append(Vector2(x, -9.0))
		spots.append(Vector2(x, 9.0))
	for z in [-4.5, 0.0, 4.5]:
		spots.append(Vector2(-6.0, z))
		spots.append(Vector2(6.0, z))
	for p in spots:
		LandmarkEgParts.column(lm, "Sand", c + Vector3(p.x, 1.6, p.y), 0.62, 10.2,
			LandmarkEgParts.OPEN)
		lm.box("Sand", c + Vector3(p.x, 12.7, p.y), Vector3(2.0, 1.8, 2.0))
	for x in [-4.0, 0.0, 4.0]:
		for z in [-9.0, 9.0]:
			lm.box("Sand", c + Vector3(x, 4.0, z), Vector3(2.9, 4.8, 0.9))
	for z in [-6.75, -2.25, 2.25, 6.75]:
		for x in [-6.0, 6.0]:
			lm.box("Sand", c + Vector3(x, 4.0, z), Vector3(0.9, 4.8, 3.0))
	for z in [-9.0, 9.0]:
		lm.beam("Sand", c + Vector3(-6.0, 13.0, z), c + Vector3(6.0, 13.0, z), 1.2, 1.8, Vector3.UP, true)
	for x in [-6.0, 6.0]:
		lm.beam("Sand", c + Vector3(x, 13.0, -9.0), c + Vector3(x, 13.0, 9.0), 1.2, 1.8, Vector3.UP, true)

# --- Temple of Horus at Edfu ---

## The best preserved Egyptian temple: 64 m pylon of 36 m with two granite
## falcons, the colonnaded Court of Offerings, the roofed hypostyle block
## stepping down in three stages and the 12 m enclosure wall round all,
## 130 m end to end. Origin at the centre of the roofed temple.
static func edfu(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Sand", LandmarkMaterials.pbr("stone", "#CFB487", 3.4))
	lm.use("Dark", LandmarkMaterials.pbr("stone", "#3A2E22", 2.0))
	lm.use("Falcon", LandmarkMaterials.pbr("stone", "#2E2926", 2.0))
	lm.use("Ground", LandmarkMaterials.pbr("sand", "#D6BE8C", 8.0))
	lm.box("Ground", Vector3(0, -0.3, 25.0), Vector3(84.0, 0.8, 150.0))
	LandmarkEgParts.pylon(lm, "Sand", "Dark", Vector3(0, 0, 84.0), 64.0, 36.0, 12.0, 10.0)
	for s in [-1.0, 1.0]:
		LandmarkEgParts.taper(lm, "Falcon", Vector3(s * 8.0, 0, 93.0), 1.8, 2.4, 1.1, 1.5, 3.2)
		lm.box("Falcon", Vector3(s * 8.0, 3.7, 93.2), Vector3(1.1, 1.0, 1.2))
	# Court of Offerings: a column row against each side wall under a roof strip.
	for s in [-1.0, 1.0]:
		LandmarkEgParts.colonnade(lm, "Sand", Vector3(s * 27.0, 0, 74.0), Vector3(s * 27.0, 0, 40.0),
			12, 0.8, 9.0, LandmarkEgParts.OPEN, 10)
		lm.box("Sand", Vector3(s * 31.5, 9.5, 57.0), Vector3(9.0, 1.0, 40.0))
		LandmarkEgParts.wall(lm, "Sand", Vector2(s * 35.5, 78.0), Vector2(s * 35.5, -40.0), 12.0, 3.0)
	LandmarkEgParts.wall(lm, "Sand", Vector2(-35.5, -40.0), Vector2(35.5, -40.0), 12.0, 3.0)
	# Roofed temple in three descending stages, each under a cavetto cornice.
	lm.box("Sand", Vector3(0, 6.0, 24.0), Vector3(38.0, 12.0, 24.0))
	LandmarkEgParts.taper(lm, "Sand", Vector3(0, 12.0, 24.0), 38.0, 24.0, 40.4, 26.4, 1.4)
	lm.box("Sand", Vector3(0, 5.0, 0.0), Vector3(38.0, 10.0, 24.0))
	LandmarkEgParts.taper(lm, "Sand", Vector3(0, 10.0, 0.0), 38.0, 24.0, 40.2, 26.2, 1.2)
	lm.box("Sand", Vector3(0, 3.8, -24.0), Vector3(38.0, 7.6, 24.0))
	LandmarkEgParts.taper(lm, "Sand", Vector3(0, 7.6, -24.0), 38.0, 24.0, 40.0, 26.0, 1.0)
	lm.box("Dark", Vector3(0, 4.0, 36.2), Vector3(5.0, 8.0, 0.4))
	for x in [-14.0, -8.0, 8.0, 14.0]:
		LandmarkEgParts.column(lm, "Sand", Vector3(x, 0, 37.6), 0.85, 10.0, LandmarkEgParts.OPEN, 10)
	lm.box("Sand", Vector3(0, 10.6, 37.6), Vector3(32.0, 1.2, 2.4))
	# Mammisi in front of the pylon, west side.
	lm.box("Sand", Vector3(-30.0, 3.5, 104.0), Vector3(14.0, 7.0, 24.0))
	LandmarkEgParts.colonnade(lm, "Sand", Vector3(-35.0, 0, 117.0), Vector3(-25.0, 0, 117.0), 4, 0.5,
		6.0, LandmarkEgParts.OPEN)
	lm.commit(model)

# --- Temple of Kom Ombo ---

## Double temple of Sobek (east) and Haroeris (west) on the river bank:
## the colonnaded court, the outer hypostyle facade of five composite
## columns with two doors, the roofed halls behind and the two parallel
## sanctuaries, 15 m to the cornice.
static func kom_ombo(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Sand", LandmarkMaterials.pbr("stone", "#D2B98E", 3.4))
	lm.use("Dark", LandmarkMaterials.pbr("stone", "#3A2E22", 2.0))
	lm.use("Ground", LandmarkMaterials.pbr("sand", "#D6BE8C", 8.0))
	lm.box("Ground", Vector3(0, -3.0, 0), Vector3(66.0, 6.0, 110.0))
	lm.box("Ground", Vector3(0, -0.3, 0), Vector3(62.0, 0.8, 104.0))
	# Court: 16 columns (6 down each side, 4 across the front of the hall).
	for s in [-1.0, 1.0]:
		LandmarkEgParts.colonnade(lm, "Sand", Vector3(s * 17.0, 0, 42.0), Vector3(s * 17.0, 0, 24.0), 6,
			0.8, 8.6, LandmarkEgParts.OPEN, 10)
		lm.box("Sand", Vector3(s * 19.5, 9.4, 33.0), Vector3(6.0, 1.0, 22.0))
		LandmarkEgParts.wall(lm, "Sand", Vector2(s * 22.0, 44.0), Vector2(s * 22.0, 21.0), 9.6, 2.0)
	for x in [-12.0, -4.0, 4.0, 12.0]:
		LandmarkEgParts.column(lm, "Sand", Vector3(x, 0, 28.0), 0.8, 8.6, LandmarkEgParts.OPEN, 10)
	lm.box("Sand", Vector3(0, 9.4, 28.0), Vector3(28.0, 1.0, 3.0))
	lm.box("Sand", Vector3(0, 0.5, 44.0), Vector3(44.0, 1.0, 2.0))
	# Outer hypostyle: 15 composite columns in 3 rows under an architrave grid,
	# screen walls and the two doors on the facade, side walls to the cornice.
	for zr in [16.0, 9.0, 2.0]:
		for i in 5:
			LandmarkEgParts.column(lm, "Sand", Vector3(-17.0 + 8.5 * i, 0, zr), 1.0, 10.5,
				LandmarkEgParts.OPEN, 12)
		lm.beam("Sand", Vector3(-20.0, 11.4, zr), Vector3(20.0, 11.4, zr), 1.6, 2.4, Vector3.UP, true)
	for i in 5:
		lm.beam("Sand", Vector3(-17.0 + 8.5 * i, 11.4, 17.0), Vector3(-17.0 + 8.5 * i, 11.4, 1.0),
			1.6, 2.2, Vector3.UP, true)
	for x in [-12.75, -4.25, 4.25, 12.75]:
		lm.box("Sand", Vector3(x, 2.4, 16.0), Vector3(6.6, 4.8, 1.0))
	for s in [-1.0, 1.0]:
		lm.box("Dark", Vector3(s * 4.25, 3.4, 16.1), Vector3(2.6, 6.2, 0.5))
		LandmarkEgParts.wall(lm, "Sand", Vector2(s * 22.5, 18.0), Vector2(s * 22.5, -2.0), 11.5, 2.0)
	lm.box("Sand", Vector3(0, 12.0, -0.5), Vector3(44.0, 1.2, 5.0))
	# Inner hypostyle hall and the two parallel sanctuaries under cavetto cornices.
	lm.box("Sand", Vector3(0, 6.5, -7.0), Vector3(44.0, 13.0, 10.0))
	LandmarkEgParts.taper(lm, "Sand", Vector3(0, 13.0, -7.0), 44.0, 10.0, 46.4, 12.4, 2.0)
	lm.box("Sand", Vector3(0, 5.0, -30.0), Vector3(44.0, 10.0, 28.0))
	LandmarkEgParts.taper(lm, "Sand", Vector3(0, 10.0, -30.0), 44.0, 28.0, 46.0, 30.0, 1.3)
	lm.box("Dark", Vector3(-11.0, 3.0, -16.1), Vector3(2.4, 5.0, 0.4))
	lm.box("Dark", Vector3(11.0, 3.0, -16.1), Vector3(2.4, 5.0, 0.4))
	lm.commit(model)
