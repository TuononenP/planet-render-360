class_name LandmarkLpJerusalem
extends RefCounted

## Two Old City landmarks of Jerusalem in true metres, built in compass
## frame (+X east, -Z north): the Church of the Holy Sepulchre and the
## Al-Aqsa Mosque on the Haram al-Sharif.

# --- Church of the Holy Sepulchre ---

## Crusader church seen from the parvis (south, +Z): the Romanesque facade
## (two round-arched portals under a window tier, cornice), the belfry at its
## west, the Rotunda of the Anastasis (r 17 m) with its ribbed lead dome and
## oculus lantern (35 m), the Catholicon's smaller ribbed dome, the roof of
## the transept and nave and the polygonal east apse.
static func holy_sepulchre(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#DCCBA6", 3.5))
	lm.use("Lead", LandmarkMaterials.pbr("slate", "#8A949C", 4.0))
	lm.use("Court", LandmarkMaterials.pbr("pavement", "#CFC1A0", 4.0))
	lm.use("Dark", LandmarkMaterials.pbr("concrete", "#26201A", 3.0, 0.92))
	lm.box("Court", Vector3(5, -0.2, 18), Vector3(52, 0.4, 32))
	# Rotunda: 17 m radius drum, ring of buttressed wall, ribbed dome, lantern.
	var rc := Vector3(-24, 0, -12)
	lm.frustum("Stone", rc, 17.0, 16.6, 21.0, 24)
	lm.frustum("Stone", rc + Vector3(0, 21.0, 0), 15.2, 14.6, 5.0, 24)
	LandmarkLpParts.ribbed_dome(lm, "Lead", rc + Vector3(0, 26.0, 0),
		LandmarkLpParts.dome_profile(14.6, 6.4, 8, 0.35), 16, 0.03)
	lm.frustum("Stone", rc + Vector3(0, 31.8, 0), 2.4, 2.1, 2.2, 12)
	lm.lathe("Lead", rc + Vector3(0, 34.0, 0), PackedVector2Array([Vector2(2.3, 0), Vector2(1.2, 0.5),
		Vector2(0.15, 1.0)]), 12)
	for k in 12:
		var a := TAU * float(k) / 12.0
		lm.box("Stone", rc + Vector3(cos(a) * 16.9, 10.5, sin(a) * 16.9), Vector3(1.4, 21.0, 1.4),
			Basis(Vector3.UP, -a))
	# Transept and nave block with the Catholicon dome and the apse.
	lm.box("Stone", Vector3(12.5, 10.0, -13), Vector3(39, 20.0, 30))
	lm.gable("Lead", Vector3(12.5, 20.0, -13), 26.0, 38.0, 3.2, Basis(Vector3.UP, PI * 0.5), 0.2, "Stone")
	var cc := Vector3(14, 0, -12)
	lm.frustum("Stone", cc + Vector3(0, 20.0, 0), 7.0, 7.0, 5.0, 16)
	LandmarkLpParts.ribbed_dome(lm, "Lead", cc + Vector3(0, 25.0, 0),
		LandmarkLpParts.dome_profile(7.3, 6.4, 8, 0.3), 12, 0.04)
	lm.frustum("Stone", cc + Vector3(0, 31.2, 0), 1.2, 1.0, 1.6, 8)
	lm.spire("Lead", cc + Vector3(0, 32.8, 0), 1.1, 1.6, 0.0, 8)
	var ap := Vector3(32, 0, -13)
	lm.frustum("Stone", ap, 9.0, 9.0, 15.0, 8)
	lm.lathe("Lead", ap + Vector3(0, 15.0, 0), PackedVector2Array([Vector2(9.2, 0), Vector2(6.0, 2.4),
		Vector2(0.2, 5.0)]), 8)
	# Facade: two portals (the west one walled up), window tier, cornice.
	var arches := [[-3.4, 2.0, 3.6, 2.0], [3.4, 2.0, 3.6, 2.0]]
	LandmarkLpParts.slab(lm, "Stone", LandmarkLpParts.arcade_outline(22.0, 17.0, arches), Vector3(6, 0, 3.0),
		0.0, 4.0)
	LandmarkLpParts.arch_panel(lm, "Dark", Vector3(2.6, 0, 3.04), 0.0, 1.6, 3.6, 1.6)
	LandmarkLpParts.arch_panel(lm, "Stone", Vector3(9.4, 0, 3.04), 0.0, 1.6, 3.6, 1.6)
	for s in [-1.0, 1.0]:
		LandmarkLpParts.arch_panel(lm, "Dark", Vector3(6.0 + s * 3.8, 9.2, 3.04), 0.0, 1.5, 3.0, 1.5)
		lm.box("Stone", Vector3(6.0 + s * 10.2, 8.5, 3.2), Vector3(1.2, 17.0, 1.2))
	lm.box("Stone", Vector3(6, 7.8, 3.4), Vector3(22.8, 0.6, 1.2))
	lm.box("Stone", Vector3(6, 17.3, 2.9), Vector3(23.0, 0.8, 1.8))
	# Belfry at the south-west corner: three stages, arched openings.
	var bt := Vector3(-11.0, 0, -2.0)
	lm.box("Stone", bt + Vector3(0, 10.0, 0), Vector3(8.0, 20.0, 8.0))
	lm.box("Stone", bt + Vector3(0, 20.4, 0), Vector3(9.0, 0.8, 9.0))
	lm.box("Stone", bt + Vector3(0, 23.2, 0), Vector3(7.2, 4.8, 7.2))
	for k in 4:
		var yaw := PI * 0.5 * float(k)
		var d := LandmarkLpParts.outward(yaw)
		LandmarkLpParts.arch_panel(lm, "Dark", bt + d * 3.64 + Vector3(0, 21.6, 0), yaw, 0.9, 1.6, 0.9)
		LandmarkLpParts.arch_panel(lm, "Dark", bt + d * 4.04 + Vector3(0, 7.0, 0), yaw, 0.6, 1.4, 0.6)
	lm.box("Stone", bt + Vector3(0, 26.0, 0), Vector3(8.0, 0.8, 8.0))
	lm.commit(model)

# --- Al-Aqsa Mosque ---

## 83 x 56 m seven-aisled hall (the nave twice as wide as an aisle) in
## compass frame with the 7-arch porch on the north (-Z) front, the long
## lead roofs and the transept, the silver-grey dome on its drum before the
## qibla wall, and the Mamluk square minaret (37 m) to the north-west.
static func al_aqsa(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#E4DAC4", 4.0))
	lm.use("Lead", LandmarkMaterials.pbr("slate", "#99A3AA", 5.0, 0.4))
	lm.use("Court", LandmarkMaterials.pbr("pavement", "#D5CBB3", 6.0))
	lm.use("Dark", LandmarkMaterials.pbr("concrete", "#262019", 3.0, 0.92))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.box("Court", Vector3(0, -0.2, -3), Vector3(96, 0.4, 100))
	lm.box("Stone", Vector3(0, 8.0, 0), Vector3(56, 16.0, 83))
	for s in [-1.0, 1.0]:
		lm.box("Lead", Vector3(s * 17.5, 16.15, 0), Vector3(21.0, 0.3, 82.0))
	lm.box("Stone", Vector3(0, 10.5, 0), Vector3(14.0, 21.0, 83))
	lm.gable("Lead", Vector3(0, 21.0, 0), 14.0, 83.0, 3.6, Basis(), 0.3, "Stone")
	# Transept in front of the mihrab and the dome on its drum.
	lm.box("Stone", Vector3(0, 10.5, 24.0), Vector3(56, 21.0, 16.0))
	lm.gable("Lead", Vector3(0, 21.0, 24.0), 16.0, 56.0, 3.2, Basis(Vector3.UP, PI * 0.5), 0.3, "Stone")
	var dc := Vector3(0, 0, 24.0)
	lm.frustum("Stone", dc + Vector3(0, 18.0, 0), 7.6, 7.6, 7.0, 16)
	for k in 8:
		var a := TAU * float(k) / 8.0
		lm.box("Dark", dc + Vector3(cos(a) * 7.65, 22.0, sin(a) * 7.65), Vector3(0.4, 3.0, 1.7),
			Basis(Vector3.UP, -a))
	lm.lathe("Lead", dc + Vector3(0, 25.0, 0), LandmarkLpParts.dome_profile(8.0, 7.2, 8, 0.15), 24)
	LandmarkLpParts.needle(lm, "Gold", dc + Vector3(0, 32.2, 0),
		PackedVector2Array([Vector2(0, 0.35), Vector2(2.6, 0.08)]))
	# North porch: seven arches (taller central one), parapet.
	var arches: Array = []
	for i in 7:
		var cx := -17.7 + 5.9 * float(i)
		arches.append([cx, 2.4 if i != 3 else 2.9, 4.4, 2.4 if i != 3 else 2.9])
	LandmarkLpParts.slab(lm, "Stone", LandmarkLpParts.arcade_outline(42.0, 11.0, arches, 6),
		Vector3(0, 0, -41.5 - 4.0), PI, 4.0)
	lm.box("Dark", Vector3(0, 5.0, -41.55), Vector3(41.0, 10.0, 0.1))
	# Fakhriyya-style minaret: square shaft, octagonal stage, balcony, lantern, cap.
	var mp := Vector3(-34.0, 0, -36.0)
	lm.box("Stone", mp + Vector3(0, 11.5, 0), Vector3(5.4, 23.0, 5.4))
	lm.box("Stone", mp + Vector3(0, 23.4, 0), Vector3(6.4, 0.8, 6.4))
	lm.frustum("Stone", mp + Vector3(0, 23.8, 0), 2.7, 2.4, 6.6, 8, PI / 8.0)
	lm.frustum("Stone", mp + Vector3(0, 28.2, 0), 3.4, 3.4, 0.5, 8, PI / 8.0)
	lm.frustum("Stone", mp + Vector3(0, 30.4, 0), 1.9, 1.7, 3.0, 8, PI / 8.0)
	lm.frustum("Stone", mp + Vector3(0, 33.4, 0), 2.3, 2.3, 0.4, 8, PI / 8.0)
	lm.spire("Lead", mp + Vector3(0, 33.8, 0), 2.0, 2.9, 0.0, 8)
	LandmarkLpParts.needle(lm, "Gold", mp + Vector3(0, 36.7, 0),
		PackedVector2Array([Vector2(0, 0.14), Vector2(0.3, 0.06)]), 6)
	lm.commit(model)
