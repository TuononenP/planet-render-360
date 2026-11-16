class_name LandmarkCsMajorWorld
extends RefCounted

## Capital stations of large cities in the Americas and Europe without a
## terminus in the other LandmarkCs batches, in the station frame (+X
## along the main facade, +Z the forecourt): Lima's Desamparados,
## Bogotá's La Sabana, Minsk Passenger and Havana Central.

const K = preload("res://scripts/generation/landmarks/capital_stations/landmark_station_kit.gd")

## Desamparados, Lima (Ricardo de Jaxa Malachowski, 1912): the cream
## Beaux-Arts front of two tall storeys under a flat roof and balustrade,
## arched ground-floor openings between giant pilasters, and the centre
## bay crowned by the clock in its scrolled cartouche.
static func desamparados(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "render", "#ECE6D6", "#F3EFE4", "concrete", "#C9C4B8")
	K.block(lm, "Walls", "Trim", "Glass", "Roof", 0.0, -2.0, 60.0, 44.0, 0.0, 14.0, "flat", 0.0, 4.6, 6.5, true)
	LandmarkFhUtil.merlons(lm, "Trim", Vector3(-30.0, 14.0, 20.2), Vector3(30.0, 14.0, 20.2), 0.9, 0.35, 1.0, 0.35)
	lm.box("Trim", Vector3(0, 15.1, 20.2), Vector3(60.0, 0.3, 0.5))
	LandmarkFhParts.strips(lm, "Trim", Vector3(-29.0, 0, 20.0), Vector3(29.0, 0, 20.0), Vector3.BACK, 1.0, 12.8, 9,
		1.2, 0.5)
	# The centre bay, a little proud, and its clock cartouche.
	lm.box("Walls", Vector3(0, 7.5, 20.6), Vector3(18.0, 15.0, 1.6))
	lm.box("Trim", Vector3(0, 14.8, 20.8), Vector3(18.8, 0.8, 2.0))
	K.arch_window(lm, "Trim", "Glass", Vector3(0, 0.2, 21.45), Vector3.BACK, 4.6, 8.0, 3)
	for s in [-1.0, 1.0]:
		lm.box("Trim", Vector3(s * 8.5, 7.5, 21.5), Vector3(1.2, 15.0, 0.6))
	lm.box("Walls", Vector3(0, 17.5, 20.6), Vector3(9.0, 5.0, 1.4))
	lm.lathe("Trim", Vector3(0, 20.0, 20.6), PackedVector2Array([Vector2(4.5, 0.0), Vector2(3.0, 1.6),
		Vector2(0.0, 2.0)]), 12, 1.0, 0.3)
	K.clock(lm, "Dial", "Trim", Vector3(0, 17.6, 21.35), Vector3.BACK, 1.6)
	lm.box("Steel", Vector3(0, 24.5, 20.4), Vector3(0.15, 5.0, 0.15), Basis(), 0.0)
	lm.commit(model)

## La Sabana, Bogotá (William Lidstone, 1917): the beige neoclassical
## front of three storeys, giant columns and tall windows on the wings,
## the raised central pavilion with its arched upper windows, balustrades
## along the roof and the bronze condor on the crest.
static func la_sabana(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "limestone", "#D9C9A6", "#E8DEC6", "concrete", "#A39B8C")
	lm.use("Bronze", LandmarkMaterials.pbr("copper", "#5E5A4C", 2.0))
	K.block(lm, "Walls", "Trim", "Glass", "Roof", 0.0, -2.0, 46.0, 26.0, 0.0, 16.0, "flat", 0.0, 3.6, 5.2)
	for s in [-1.0, 1.0]:
		LandmarkFhUtil.columns(lm, "Trim", Vector3(s * 11.5, 0, 11.6), Vector3(s * 21.5, 0, 11.6), 4, 14.0, 0.55)
		lm.box("Trim", Vector3(s * 16.5, 14.6, 11.4), Vector3(11.0, 1.4, 1.2))
		LandmarkFhUtil.merlons(lm, "Trim", Vector3(s * 10.0, 16.0, 11.2), Vector3(s * 23.0, 16.0, 11.2), 0.9, 0.35,
			1.0, 0.35)
	# The central pavilion, its arched windows and the condor.
	K.block(lm, "Walls", "Trim", "Glass", "Roof", 0.0, 0.0, 18.0, 26.0, 0.0, 19.0, "flat", 0.0, 3.6, 5.2)
	K.arch_row(lm, "Trim", "Glass", Vector3(-6.0, 0, 13.05), Vector3(6.0, 0, 13.05), Vector3.BACK, 7.0, 3, 2.4, 5.0, 1)
	K.arch_row(lm, "Trim", "Glass", Vector3(-6.0, 0, 13.05), Vector3(6.0, 0, 13.05), Vector3.BACK, 0.8, 3, 2.6, 5.0, 1)
	LandmarkFhUtil.merlons(lm, "Trim", Vector3(-9.0, 19.0, 13.2), Vector3(9.0, 19.0, 13.2), 0.9, 0.35, 1.0, 0.35)
	lm.box("Walls", Vector3(0, 20.5, 11.0), Vector3(8.0, 3.0, 3.0))
	K.statue(lm, "Bronze", Vector3(0, 22.0, 11.0), 3.0)
	for s in [-1.0, 1.0]:
		lm.box("Bronze", Vector3(s * 1.6, 24.0, 11.0), Vector3(3.0, 0.3, 1.0), Basis(Vector3.BACK, s * 0.35))
	lm.commit(model)

## Minsk Passenger (2002): the glass and white-steel front, a tall glazed
## central atrium under a pointed glass gable, long glazed wings with white
## bands, and the thin white roof sweeping out over them.
static func minsk_passenger(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "render", "#EEEEEC", "#F2F2F0", "sheet_metal", "#DCDCDA")
	lm.use("Curtain", LandmarkMaterials.pbr("render", "#93AEC2", 6.0, 0.2, 0.3))
	for s in [-1.0, 1.0]:
		var cx: float = s * 55.0
		lm.box("Curtain", Vector3(cx, 12.0, -6.0), Vector3(70.0, 24.0, 60.0))
		for y in [6.0, 12.0, 18.0]:
			LandmarkFhParts.box_band(lm, "Walls", cx, -6.0, 70.0, 60.0, y - 0.4, 0.8, 0.2)
		lm.box("Roof", Vector3(cx, 24.6, -4.0), Vector3(74.0, 1.2, 66.0))
	# The atrium and its pointed glass gable.
	lm.box("Curtain", Vector3(0, 15.0, 0.0), Vector3(40.0, 30.0, 52.0))
	LandmarkFhUtil.ridge_z(lm, "Curtain", "Curtain", Vector3(0, 30.0, 0.0), 40.0, 52.0, 9.0, 0.6)
	LandmarkFhParts.strips(lm, "Walls", Vector3(-19.5, 0, 26.05), Vector3(19.5, 0, 26.05), Vector3.BACK, 0.0, 30.0, 9,
		0.5, 0.4)
	for y in [8.0, 16.0, 24.0]:
		LandmarkFhParts.band(lm, "Walls", Vector3(-20.0, 0, 26.0), Vector3(20.0, 0, 26.0), Vector3.BACK, y, 0.6, 0.4)
	lm.box("Walls", Vector3(0, 30.4, 26.3), Vector3(41.0, 0.8, 1.0))
	K.canopy(lm, "Walls", "Steel", Vector3(-30.0, 0, 26.0), Vector3(30.0, 0, 26.0), Vector3.BACK, 6.0, 6.0, 5)
	lm.commit(model)

## Havana Central (Kenneth MacKenzie Murchison, 1912): the buff Spanish
## Colonial Revival range of four storeys over an arcade, a balustraded
## balcony along the first floor, and its two unequal square towers with
## arched open belvederes and flat caps.
static func havana_central(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	K.mats(lm, "limestone", "#E4D6B4", "#EFE6CF", "terracotta", "#A8503A")
	K.block(lm, "Walls", "Trim", "Glass", "Roof", 0.0, 0.0, 76.0, 26.0, 0.0, 21.0, "flat", 0.0, 4.2, 4.8, true)
	LandmarkFhUtil.merlons(lm, "Trim", Vector3(-38.0, 21.0, 13.2), Vector3(38.0, 21.0, 13.2), 1.0, 0.4, 1.0, 0.35)
	lm.box("Trim", Vector3(0, 6.2, 14.0), Vector3(70.0, 0.4, 2.0))
	LandmarkFhUtil.merlons(lm, "Trim", Vector3(-35.0, 6.4, 14.8), Vector3(35.0, 6.4, 14.8), 0.8, 0.3, 1.0, 0.3)
	# The entrance porch under its tiled roof.
	lm.box("Trim", Vector3(-6.0, 4.5, 16.0), Vector3(14.0, 0.5, 6.0))
	K.hip_roof(lm, "Roof", Vector3(-6.0, 4.75, 16.0), 14.6, 6.6, 1.6)
	for x in [-12.5, 0.5]:
		lm.box("Trim", Vector3(x, 2.25, 18.6), Vector3(0.7, 4.5, 0.7))
	_belvedere_tower(lm, Vector3(-6.0, 0, 9.0), 8.0, 45.0)
	_belvedere_tower(lm, Vector3(33.0, 0, 9.0), 7.0, 37.0)
	lm.commit(model)

## A square tower `w` wide standing on `base`, `h` to its flat cap: plain
## shaft, a clock just under a cornice, then the open belvedere of arched
## bays and the small flat-capped lantern.
static func _belvedere_tower(lm: LandmarkMesh, base: Vector3, w: float, h: float) -> void:
	var shaft := h - 9.0
	lm.box("Walls", base + Vector3.UP * shaft * 0.5, Vector3(w, shaft, w))
	lm.box("Trim", base + Vector3.UP * (shaft - 0.4), Vector3(w + 0.8, 0.8, w + 0.8))
	K.clock(lm, "Dial", "Trim", base + Vector3(0, shaft - 3.0, w * 0.5 + 0.05), Vector3.BACK, w * 0.22)
	var b := base + Vector3.UP * shaft
	for i in 4:
		var n := Vector3(sin(PI * 0.5 * float(i)), 0, cos(PI * 0.5 * float(i)))
		var r := Vector3.UP.cross(n)
		for s in [-1.0, 1.0]:
			lm.box("Walls", b + n * (w * 0.5 - 0.4) + r * s * (w * 0.5 - 0.5) + Vector3.UP * 2.75,
				Vector3(1.0, 5.5, 1.0))
		LandmarkFhUtil.openings(lm, "Glass", b + n * (w * 0.5 - 0.3) - r * w * 0.2, b + n * (w * 0.5 - 0.3) + r * w * 0.2,
			n, 0.4, 2, w * 0.25, 4.6, true, 0.05)
	lm.box("Walls", b + Vector3.UP * 2.75, Vector3(w - 1.6, 5.5, w - 1.6))
	lm.box("Trim", b + Vector3.UP * 5.9, Vector3(w + 0.6, 0.8, w + 0.6))
	lm.box("Walls", b + Vector3.UP * 7.4, Vector3(w * 0.55, 2.4, w * 0.55))
	lm.box("Trim", b + Vector3.UP * 8.8, Vector3(w * 0.65, 0.4, w * 0.65))
