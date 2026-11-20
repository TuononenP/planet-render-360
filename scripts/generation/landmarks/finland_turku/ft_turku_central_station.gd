class_name FtTurkuCentralStation
extends RefCounted

## Turku Central Railway Station (Turun päärautatieasema, Väinö Vähäkallio &
## Martti Välikangas, 1940) in true metres (+X ENE along Ratapihankatu, +Z SSE
## facing Humalistonkatu/station square, -Z NNW facing railway platforms, turned
## by yaw_deg = -34.3°):
##   - Measured from OSM way:315580344 (60.455677, 22.260744, 50.9 x 16.1 m,
##     LoD2 height 22.9 m).
##   - Classic 1940 Finnish Functionalist yellow-brick station on a pink-grey
##     granite plinth with wide granite entrance steps on the city front (+Z).
##   - Double-height central ticket & concourse hall (22 x 16 m, H 13.8 m) with
##     tall rhythmic full-height glazed bays facing both Ratapihankatu and the
##     tracks, cantilevered entrance canopy, and iconic illuminated station
##     clock & "TURKU / ÅBO" fascia strip.
##   - Asymmetric functionalist stair/clock tower pavilion rising to 22.6 m on
##     the west-central flank with tall vertical stair glazing & copper roof cap.
##   - Symmetric 3-storey yellow-brick east and west wings with crisp ribbon
##     windows and low-pitched dark-metal/copper roofs.
##   - Trackside (-Z) concrete island platforms & twin cantilevered steel-and-
##     glass platform canopies with warm under-canopy linear lighting.
## Surfaces: 9 merged PBR parts (YellowBrick, Stone, Concrete, Roof, Copper,
## Trim, Frame, Glass, Lamp).

const FOUND := -1.8
const TOP_M := 22.6

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	_materials(lm)
	_build_station_body(lm)
	_build_concourse_and_tower(lm)
	_build_platform_canopies(lm)
	lm.commit(model)
	_set_night_floods(model)

static func _materials(lm: LandmarkMesh) -> void:
	lm.use("YellowBrick", LandmarkMaterials.pbr("brick", "#C9A663", 2.5))
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#867D76", 2.5))
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#C8C4BA", 2.8))
	lm.use("Roof", LandmarkMaterials.pbr("concrete", "#434A4E", 2.5, 0.55, 0.45))
	lm.use("Copper", LandmarkFrKit.copper("#536F63"))
	lm.use("Trim", LandmarkMaterials.pbr("render", "#E7E1D3", 2.4))
	lm.use("Frame", LandmarkMaterials.paint("#2A2F35", 0.42, 0.60))
	lm.use("Glass", LandmarkMaterials.glass("#223440"))
	lm.use("Lamp", LandmarkMaterials.lit("#FFE6B2", 1.5))

static func _build_station_body(lm: LandmarkMesh) -> void:
	# Granite base plinth & wide station-square entrance steps (+Z faces Ratapihankatu).
	LandmarkFrKit.rect(lm, "Stone", -26.2, 26.2, -8.5, 8.6, FOUND, 1.35)
	for st in 4:
		var t := float(st) / 3.0
		var z0 := lerpf(8.6, 10.6, t)
		var y1 := lerpf(1.25, 0.20, t)
		LandmarkFrKit.rect(lm, "Stone", -12.0, 12.0, z0, z0 + 0.55, FOUND, y1)
	# Symmetric 3-storey yellow-brick functionalist side wings (x = -25.5..-10.5 and 10.5..25.5).
	for sx: float in [-1.0, 1.0]:
		var x0 := -25.5 if sx < 0.0 else 10.5
		var x1 := -10.5 if sx < 0.0 else 25.5
		LandmarkFrKit.rect(lm, "YellowBrick", x0, x1, -8.0, 8.0, 1.35, 11.4)
		LandmarkFrKit.rect(lm, "Trim", x0 - 0.2, x1 + 0.2, -8.2, 8.2, 11.2, 11.65)
		lm.gable("Roof", Vector3((x0 + x1) * 0.5, 11.65, 0.0), 16.0, 15.0, 1.6, Basis(Vector3.UP, PI * 0.5), 0.25, "YellowBrick")
		# Horizontal functionalist strip windows on 3 levels (both +Z and -Z faces).
		for fl in 3:
			var fy := 2.4 + float(fl) * 2.95
			for fz: float in [8.06, -8.06]:
				LandmarkFrKit.rect(lm, "Glass", x0 + 1.4, x1 - 1.4, fz - 0.08, fz + 0.08, fy, fy + 1.65)
				if fl == 0 or (fl == 1 and sx > 0.0):
					LandmarkFrKit.rect(lm, "Lamp", x0 + 1.8, x1 - 1.8, fz - 0.35 * signf(fz), fz - 0.15 * signf(fz), fy + 0.2, fy + 1.45)
				for k in 6:
					var mx := lerpf(x0 + 1.5, x1 - 1.5, float(k) / 5.0)
					lm.box("Frame", Vector3(mx, fy + 0.82, fz + 0.04 * signf(fz)), Vector3(0.14, 1.72, 0.18))
		# End-wall functionalist windows.
		var ex := x0 - 0.06 if sx < 0.0 else x1 + 0.06
		for fl in 3:
			var fy := 2.4 + float(fl) * 2.95
			LandmarkFrKit.rect(lm, "Glass", ex - 0.08, ex + 0.08, -5.5, 5.5, fy, fy + 1.65)

static func _build_concourse_and_tower(lm: LandmarkMesh) -> void:
	# Central double-height glazed ticket concourse hall (x = -10.8..10.8, H 14.4 m).
	LandmarkFrKit.rect(lm, "YellowBrick", -10.8, 10.8, -8.2, 8.2, 1.35, 14.2)
	LandmarkFrKit.rect(lm, "Trim", -11.0, 11.0, -8.4, 8.4, 13.8, 14.45)
	LandmarkFrKit.rect(lm, "Copper", -10.6, 10.6, -8.0, 8.0, 14.45, 14.85)
	# Tall panoramic concourse glazing on +Z (city) and -Z (track) fronts.
	for fz: float in [8.22, -8.22]:
		var s := signf(fz)
		LandmarkFrKit.rect(lm, "Glass", -8.8, 8.8, fz - 0.08, fz + 0.08, 1.6, 12.6)
		LandmarkFrKit.rect(lm, "Lamp", -8.2, 8.2, fz - 0.55 * s, fz - 0.30 * s, 2.0, 12.0)
		for k in 9:
			var mx := lerpf(-8.6, 8.6, float(k) / 8.0)
			var mw := 0.28 if k % 2 == 0 else 0.14
			lm.box("Frame", Vector3(mx, 7.1, fz + 0.08 * s), Vector3(mw, 11.1, 0.26))
		for tr_y: float in [4.6, 7.4, 10.2]:
			lm.box("Frame", Vector3(0.0, tr_y, fz + 0.08 * s), Vector3(17.6, 0.18, 0.22))
	# Cantilevered functionalist entrance canopy on city front (+Z = 8.2..12.6) with soffit glow.
	LandmarkFrKit.rect(lm, "Concrete", -11.8, 11.8, 8.2, 12.6, 4.45, 5.15)
	LandmarkFrKit.rect(lm, "Copper", -11.9, 11.9, 8.15, 12.65, 5.15, 5.32)
	LandmarkFrKit.rect(lm, "Lamp", -10.5, 10.5, 9.6, 11.2, 4.35, 4.46)
	# Circular illuminated functionalist station clock mounted on the central facade (+Z).
	lm.disc("Frame", Vector3(0.0, 12.1, 8.38), Vector3(0, 0, 1), 1.35, 20)
	lm.disc("Lamp", Vector3(0.0, 12.1, 8.44), Vector3(0, 0, 1), 1.15, 20)
	lm.box("Frame", Vector3(0.0, 12.45, 8.50), Vector3(0.10, 0.72, 0.08))
	lm.box("Frame", Vector3(0.32, 12.1, 8.50), Vector3(0.62, 0.10, 0.08))
	# Functionalist stair / clock tower pavilion on west-central flank rising to 22.6 m (LoD2 22.9 m).
	LandmarkFrKit.rect(lm, "YellowBrick", -14.8, -8.8, -7.8, -1.6, 11.4, 21.6)
	LandmarkFrKit.rect(lm, "Trim", -15.0, -8.6, -8.0, -1.4, 21.3, 21.85)
	LandmarkFrKit.rect(lm, "Copper", -14.6, -9.0, -7.6, -1.8, 21.85, TOP_M)
	# Vertical functionalist stair glass strip & upper clock dial on tower.
	LandmarkFrKit.rect(lm, "Glass", -13.0, -10.6, -1.55, -1.35, 13.8, 20.6)
	LandmarkFrKit.rect(lm, "Lamp", -12.6, -11.0, -1.9, -1.7, 14.2, 20.2)
	lm.disc("Frame", Vector3(-11.8, 19.6, -7.92), Vector3(0, 0, -1), 1.15, 18)
	lm.disc("Lamp", Vector3(-11.8, 19.6, -7.98), Vector3(0, 0, -1), 0.96, 18)

static func _build_platform_canopies(lm: LandmarkMesh) -> void:
	# Trackside (-Z) concrete main platform & island platform with cantilevered steel canopies.
	LandmarkFrKit.rect(lm, "Concrete", -42.0, 42.0, -16.5, -8.2, FOUND, 0.95)
	LandmarkFrKit.rect(lm, "Concrete", -44.0, 44.0, -30.0, -23.2, FOUND, 0.95)
	# Platform 1 canopy attached to station rear (-Z = -15.2..-8.2) & Island Platform canopy (-29.2..-24.0).
	for cz: float in [-12.2, -26.6]:
		var cw := 6.6 if cz > -20.0 else 5.4
		LandmarkFrKit.rect(lm, "Roof", -36.0, 36.0, cz - cw * 0.5, cz + cw * 0.5, 4.65, 5.05)
		LandmarkFrKit.rect(lm, "Lamp", -34.0, 34.0, cz - 0.45, cz + 0.45, 4.52, 4.66)
		for k in 10:
			var px := lerpf(-33.0, 33.0, float(k) / 9.0)
			lm.beam("Frame", Vector3(px, 0.95, cz), Vector3(px, 4.68, cz), 0.24, 0.24)
			lm.beam("Frame", Vector3(px, 4.2, cz - cw * 0.45), Vector3(px, 4.65, cz + cw * 0.45), 0.16, 0.20)

static func _set_night_floods(model: Node3D) -> void:
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-12.0, 2.0, 18.0), Vector3(-8.0, 8.5, 8.2), 56.0, 0.85, 38.0, Color(1.0, 0.88, 0.68)],
		[Vector3(12.0, 2.0, 18.0), Vector3(8.0, 8.5, 8.2), 56.0, 0.85, 38.0, Color(1.0, 0.88, 0.68)],
		[Vector3(-12.0, 12.0, 6.0), Vector3(-11.8, 19.0, -1.6), 48.0, 0.75, 32.0, Color(1.0, 0.86, 0.65)],
	])
