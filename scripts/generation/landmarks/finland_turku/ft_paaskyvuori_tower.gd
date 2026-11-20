class_name FtPaaskyvuoriTower
extends RefCounted

## Pääskyvuori Link Tower (Pääskyvuoren linkkitorni, 1964) crowning Pääskyvuori
## hill in eastern Turku in true metres (skyline: true, turned by yaw_deg = 32.9°):
##   - Measured from OSM way:788703096 / way:788703093 (60.447051, 22.332216;
##     LoD2 concrete shaft 106.1 m, OSM height = 135 m, published 134.6 m).
##   - Turku's tallest structure: slip-formed tapered grey concrete cylindrical
##     shaft rising from a flared concrete & technical-building base collar to
##     102.0 m.
##   - Cantilevered circular equipment & microwave-dish decks at 68 m, 82 m,
##     92 m, and 100 m with galvanized steel safety railings, vertical cable
##     chases, and white parabolic microwave relay dishes.
##   - Topped by a 32.6 m red-and-white painted steel lattice telecom mast
##     (102.0..134.6 m) with diagonal cross-bracing and multiple red ICAO
##     aviation obstruction lights & halos (HALO_META) visible across the entire
##     Turku eastern horizon.
## Surfaces: 7 merged PBR parts (Concrete, ConcreteDark, Metal, Red, White,
## Glass, Beacon).

const FOUND := -2.5
const SHAFT_H := 102.0
const TOP_M := 134.6
const PLATFORMS := [
	[68.0, 6.8, true],
	[82.0, 8.2, true],
	[92.0, 8.6, true],
	[100.0, 6.2, false],
]

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	_materials(lm)
	_build_base_and_shaft(lm)
	_build_platforms_and_dishes(lm)
	_build_lattice_mast(lm)
	lm.commit(model)
	_set_night_lights(model)

static func _materials(lm: LandmarkMesh) -> void:
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#B4AEA4", 3.0))
	lm.use("ConcreteDark", LandmarkMaterials.pbr("concrete", "#7E7A73", 2.8))
	lm.use("Metal", LandmarkMaterials.paint("#C0C4C8", 0.42, 0.62))
	lm.use("Red", LandmarkMaterials.paint("#C8261E", 0.45, 0.25))
	lm.use("White", LandmarkMaterials.paint("#F0EFEA", 0.45, 0.20))
	lm.use("Glass", LandmarkMaterials.glass("#243440"))
	lm.use("Beacon", LandmarkMaterials.lit("#FF2416", 2.4))

static func _build_base_and_shaft(lm: LandmarkMesh) -> void:
	# Technical transmitter base building & flared concrete hill plinth (18 x 14 m).
	LandmarkFrKit.rect(lm, "ConcreteDark", -9.5, 9.5, -7.2, 7.2, FOUND, 5.2)
	LandmarkFrKit.rect(lm, "Concrete", -9.2, 9.2, -6.9, 6.9, 5.2, 5.8)
	LandmarkFrKit.rect(lm, "Glass", -6.0, 6.0, 7.16, 7.32, 2.2, 4.2)
	# Tapered slip-formed concrete tower shaft (r = 4.6 m at base -> 2.9 m at 102 m).
	lm.frustum("Concrete", Vector3(0.0, FOUND, 0.0), 5.6, 4.7, 5.5 - FOUND, 24)
	lm.frustum("Concrete", Vector3(0.0, 5.5, 0.0), 4.7, 2.9, SHAFT_H - 5.5, 24)
	# Vertical concrete lift-core rib & external cable ladder climbing the shaft.
	for a: float in [0.0, PI]:
		lm.beam("ConcreteDark", Vector3(cos(a) * 4.6, 5.5, sin(a) * 4.6),
			Vector3(cos(a) * 2.9, SHAFT_H, sin(a) * 2.9), 0.75, 0.45)

static func _build_platforms_and_dishes(lm: LandmarkMesh) -> void:
	for pf in PLATFORMS:
		var y: float = pf[0]
		var r: float = pf[1]
		var has_dishes: bool = pf[2]
		# Flared concrete corbel bracket & circular equipment gallery deck.
		lm.frustum("Concrete", Vector3(0.0, y - 1.8, 0.0), r * 0.48, r, 1.8, 24)
		lm.frustum("Metal", Vector3(0.0, y, 0.0), r, r, 0.55, 24)
		lm.frustum("ConcreteDark", Vector3(0.0, y + 0.55, 0.0), r - 0.15, r - 0.15, 0.14, 24)
		# Galvanized perimeter safety railing & handrail ring.
		for k in 14:
			var a := TAU * float(k) / 14.0
			var a2 := TAU * float((k + 1) % 14) / 14.0
			var p1 := Vector3(cos(a) * (r - 0.18), y + 0.65, sin(a) * (r - 0.18))
			var p2 := Vector3(cos(a2) * (r - 0.18), y + 0.65, sin(a2) * (r - 0.18))
			lm.beam("Metal", p1, p1 + Vector3(0, 1.15, 0), 0.08, 0.08)
			lm.beam("Metal", p1 + Vector3(0, 1.12, 0), p2 + Vector3(0, 1.12, 0), 0.08, 0.08)
		# Equipment cabin drum under the 92 m main relay deck.
		if y > 90.0 and y < 95.0:
			lm.frustum("Concrete", Vector3(0.0, y - 5.2, 0.0), 5.6, 5.6, 3.6, 20)
			lm.frustum("Glass", Vector3(0.0, y - 4.0, 0.0), 5.68, 5.68, 1.35, 20)
		# Parabolic white microwave relay dishes mounted around the platform edge.
		if has_dishes:
			for k in 4:
				var da := TAU * (float(k) + 0.2) / 4.0
				var dc := Vector3(cos(da) * (r - 1.1), y + 1.55, sin(da) * (r - 1.1))
				lm.disc("White", dc, Vector3(cos(da), 0.0, sin(da)), 1.25, 12)
				lm.beam("Metal", Vector3(cos(da) * (r - 1.6), y + 0.65, sin(da) * (r - 1.6)), dc, 0.22, 0.22)

static func _build_lattice_mast(lm: LandmarkMesh) -> void:
	# Tapered concrete cap collar (102..105 m).
	lm.frustum("Concrete", Vector3(0.0, SHAFT_H, 0.0), 2.9, 1.65, 3.0, 16)
	# 29.6 m red-and-white steel lattice antenna mast (105.0..134.6 m).
	var bands := 8
	var y_start := SHAFT_H + 3.0
	var band_h := (TOP_M - y_start) / float(bands)
	for b in bands:
		var y0 := y_start + float(b) * band_h
		var y1 := y0 + band_h
		var t0 := float(b) / float(bands)
		var t1 := float(b + 1) / float(bands)
		var r0 := lerpf(1.45, 0.32, t0)
		var r1 := lerpf(1.45, 0.32, t1)
		var mat := "Red" if b % 2 == 0 else "White"
		# Central tubular antenna core + 4-legged lattice corner chords & X-bracing.
		lm.frustum(mat, Vector3(0.0, y0, 0.0), r0 * 0.38, r1 * 0.38, band_h, 10)
		for k in 4:
			var a0 := TAU * float(k) / 4.0 + PI * 0.25
			var a1 := TAU * float((k + 1) % 4) / 4.0 + PI * 0.25
			var p0 := Vector3(cos(a0) * r0, y0, sin(a0) * r0)
			var p1 := Vector3(cos(a0) * r1, y1, sin(a0) * r1)
			var q0 := Vector3(cos(a1) * r0, y0, sin(a1) * r0)
			var q1 := Vector3(cos(a1) * r1, y1, sin(a1) * r1)
			lm.beam(mat, p0, p1, 0.14, 0.14)
			lm.beam(mat, p0, q1, 0.09, 0.09)
			lm.beam(mat, q0, p1, 0.09, 0.09)
			lm.beam(mat, p1, q1, 0.10, 0.10)
	# Red ICAO aviation obstruction lamps at 82 m rim, 118 m mid-mast, and 134.6 m summit.
	lm.box("Beacon", Vector3(0.0, TOP_M, 0.0), Vector3(0.55, 0.55, 0.55))
	for a: float in [0.0, TAU / 3.0, 2.0 * TAU / 3.0]:
		lm.box("Beacon", Vector3(cos(a) * 8.1, 83.6, sin(a) * 8.1), Vector3(0.38, 0.38, 0.38))
		lm.box("Beacon", Vector3(cos(a) * 0.95, 118.0, sin(a) * 0.95), Vector3(0.36, 0.36, 0.36))

static func _set_night_lights(model: Node3D) -> void:
	var halos := [
		[Vector3(0.0, TOP_M + 0.2, 0.0), 3.6, Color(1.0, 0.10, 0.05)],
		[Vector3(0.0, 118.0, 0.0), 2.8, Color(1.0, 0.10, 0.05)],
	]
	for a: float in [0.0, TAU / 3.0, 2.0 * TAU / 3.0]:
		halos.append([Vector3(cos(a) * 8.2, 83.6, sin(a) * 8.2), 2.2, Color(1.0, 0.12, 0.06)])
	model.set_meta(LandmarkLights.HALO_META, halos)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(14.0, 2.0, 14.0), Vector3(0.0, 48.0, 0.0), 46.0, 0.70, 68.0, Color(0.95, 0.94, 0.90)],
		[Vector3(-14.0, 2.0, -14.0), Vector3(0.0, 48.0, 0.0), 46.0, 0.70, 68.0, Color(0.95, 0.94, 0.90)],
	])
