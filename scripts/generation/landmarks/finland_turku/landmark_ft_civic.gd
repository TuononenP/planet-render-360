class_name LandmarkFtCivic
extends RefCounted

## Turku's civic and cultural landmarks in true metres (+X east, +Z south,
## turned onto the OSM footprint by registry yaw_deg):
##  - Turku Art Museum (1904, Gustaf Nyström, granite National Romantic)
##  - Vartiovuori Observatory (1819, C.L. Engel, neoclassical rotunda)
##  - Turku Market Hall (1896, Gustaf Nyström, red-brick hall)
##  - Turku Main Library (1903 Dutch Renaissance Old Library + 2007 wing)
##  - Turku City Theatre (1962 white modernist riverside block)

## Turku Art Museum (Turun taidemuseo, 1904) crowning Puolalanmäki hill:
## rough-hewn grey granite National Romantic castle-like facade with
## monumental front stairs, twin corner pavilions, arched entrance
## loggia, hipped copper/slate roof and central clerestory ridge.
static func turku_art_museum(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#86817B", 2.5))
	lm.use("GraniteDark", LandmarkMaterials.pbr("stone", "#68645E", 2.5))
	lm.use("Roof", LandmarkFrKit.copper("#4A6E5E"))
	lm.use("Trim", LandmarkMaterials.pbr("stone", "#A6A096", 2.5))
	lm.use("Glass", LandmarkMaterials.glass("#222A30"))
	# Monumental granite plinth & main gallery mass (38 x 28 m, eaves 14 m).
	LandmarkFrKit.rect(lm, "GraniteDark", -19.6, 19.6, -14.6, 14.6, 0.0, 3.0)
	LandmarkFrKit.rect(lm, "Granite", -19.0, 19.0, -14.0, 14.0, 3.0, 14.0)
	LandmarkFrParts.cornice_ring(lm, "Trim", -19.0, 19.0, -14.0, 14.0, 13.4, 0.7)
	LandmarkFrKit.hip(lm, "Roof", -19.0, 19.0, -14.0, 14.0, 14.0, 7.5, 0.7)
	# Twin projecting front corner pavilions (+Z faces Aurakatu).
	for sx: float in [-1.0, 1.0]:
		var x0 := sx * 12.0 - 4.2
		var x1 := sx * 12.0 + 4.2
		LandmarkFrKit.rect(lm, "Granite", x0, x1, 13.5, 17.5, 0.0, 15.2)
		LandmarkFrKit.hip(lm, "Roof", x0, x1, 13.5, 17.5, 15.2, 5.2, 0.5)
		LandmarkFrParts.opening(lm, "Trim", "Glass", Vector3(sx * 12.0, 7.0, 17.5), Vector3.BACK, 3.2, 4.8,
			LandmarkFrParts.HEAD_ROUND, 0.35, 0.16, 1)
	# Central arched entrance loggia and monumental stair (+Z).
	LandmarkFrKit.rect(lm, "GraniteDark", -8.0, 8.0, 14.0, 19.5, 0.0, 2.2)
	LandmarkFrKit.rect(lm, "GraniteDark", -6.5, 6.5, 19.5, 22.5, 0.0, 1.1)
	for k in 3:
		LandmarkFrParts.opening(lm, "GraniteDark", "Glass", Vector3(-4.2 + 4.2 * float(k), 2.2, 14.0),
			Vector3.BACK, 2.6, 5.0, LandmarkFrParts.HEAD_ROUND, 0.45, 0.3)
	# Side & rear windows + skylight ridge.
	for sz: float in [-1.0]:
		LandmarkFrParts.facade(lm, "Granite", "Glass", Vector3(-16.0, 4.0, sz * 14.0), Vector3(16.0, 4.0, sz * 14.0),
			Vector3(0, 0, sz), 9.0, 6, 1, Vector2(2.0, 3.8), 1.6, 4.0, 0.25)
	LandmarkFrKit.rect(lm, "Glass", -11.0, 11.0, -2.5, 2.5, 19.5, 21.8)
	lm.commit(model)

## Vartiovuori Observatory (Vartiovuoren tähtitorni, 1819, C.L. Engel):
## neoclassical pale-yellow/cream stone building with symmetric wings
## and a prominent central cylindrical observation rotunda (18 m).
static func vartiovuori_observatory(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("render", "#EFE6CE", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("render", "#F7F3EA", 3.0))
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#8E8A82", 2.5))
	lm.use("Roof", LandmarkMaterials.pbr("slate", "#3B4042", 2.0))
	lm.use("Glass", LandmarkMaterials.glass("#20282E"))
	# Symmetric main block (32 x 16 m, 2 storeys, eaves 9.5 m) + low hipped roof.
	LandmarkFrKit.rect(lm, "Stone", -16.4, 16.4, -8.4, 8.4, 0.0, 1.4)
	LandmarkFrKit.rect(lm, "Wall", -16.0, 16.0, -8.0, 8.0, 1.4, 9.5)
	LandmarkFrParts.cornice_ring(lm, "Trim", -16.0, 16.0, -8.0, 8.0, 9.0, 0.5)
	LandmarkFrKit.hip(lm, "Roof", -16.0, 16.0, -8.0, 8.0, 9.5, 3.2, 0.4)
	for sz: float in [-1.0, 1.0]:
		LandmarkFrParts.facade(lm, "Wall", "Glass", Vector3(-14.5, 2.0, sz * 8.0), Vector3(14.5, 2.0, sz * 8.0),
			Vector3(0, 0, sz), 7.0, 7, 2, Vector2(1.3, 2.1), 0.7, 3.4, 0.2)
	# Central cylindrical rotunda tower rising to 18 m with conical cap.
	lm.frustum("Wall", Vector3(0, 9.5, 0), 5.6, 5.5, 6.0, 24)
	lm.frustum("Trim", Vector3(0, 15.1, 0), 5.8, 5.8, 0.5, 24)
	LandmarkFrParts.ring_openings(lm, "Trim", "Glass", Vector3(0, 11.4, 0), 5.55, 8, 1.1, 2.2,
		LandmarkFrParts.HEAD_FLAT, PI / 8.0)
	lm.lathe("Roof", Vector3(0, 15.6, 0), PackedVector2Array([Vector2(6.0, 0), Vector2(0.15, 2.4)]), 24, 1.0, 1.0, 0.0, false)
	lm.commit(model)

## Turku Market Hall (Turun kauppahalli, 1896, Gustaf Nyström): long
## 118 m red-brick and granite market hall with monumental gable fronts
## on Eerikinkatu and Linnankatu, arched side windows and raised skylight
## monitor along the ridge.
static func turku_market_hall(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#964633", 2.5))
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#86827A", 2.5))
	lm.use("Trim", LandmarkMaterials.pbr("render", "#EDE7DA", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("slate", "#3A3F42", 2.0))
	lm.use("Glass", LandmarkMaterials.glass("#232B30"))
	# Main hall (116 x 24 m, eaves 7.5 m, gable ridge 12.2 m).
	LandmarkFrKit.rect(lm, "Stone", -58.4, 58.4, -12.4, 12.4, 0.0, 1.4)
	LandmarkFrKit.rect(lm, "Brick", -58.0, 58.0, -12.0, 12.0, 1.4, 7.6)
	LandmarkFrParts.cornice_ring(lm, "Trim", -58.0, 58.0, -12.0, 12.0, 7.2, 0.45)
	LandmarkFrKit.gable(lm, "Roof", -58.0, 58.0, -12.0, 12.0, 7.6, 4.6, 0.5, "Brick", 1)
	# Raised clerestory skylight monitor along the central ridge.
	LandmarkFrKit.rect(lm, "Glass", -50.0, 50.0, -3.2, 3.2, 10.6, 12.2)
	LandmarkFrKit.gable(lm, "Roof", -50.5, 50.5, -3.5, 3.5, 12.2, 1.0, 0.3, "Trim", 1)
	# Arched windows along both long facades.
	for sz: float in [-1.0, 1.0]:
		LandmarkFrParts.openings(lm, "Trim", "Glass", Vector3(-54.0, 2.8, sz * 12.0), Vector3(54.0, 2.8, sz * 12.0),
			Vector3(0, 0, sz), 22, 2.0, 3.6, LandmarkFrParts.HEAD_ROUND, 0.25, 0.14)
	# Ornate entrance portals on both gable ends (-X and +X).
	for sx: float in [-1.0, 1.0]:
		var n := Vector3(sx, 0, 0)
		LandmarkFrParts.opening(lm, "Stone", "Glass", Vector3(sx * 58.0, 0.4, 0.0), n, 5.0, 5.8,
			LandmarkFrParts.HEAD_ROUND, 0.5, 0.28)
		LandmarkFrParts.opening(lm, "Trim", "Glass", Vector3(sx * 58.0, 8.2, 0.0), n, 3.6, 2.2,
			LandmarkFrParts.HEAD_ROUND, 0.28, 0.14)
	lm.commit(model)

## Turku Main Library (Old Library, 1903, Karl August Wrede): Dutch
## Renaissance Revival red-brick and cream-plaster civic palace on the
## Aurajoki embankment with steep hipped/gabled roofs, stepped gables
## and a central corner turret.
static func turku_main_library(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#984B36", 2.5))
	lm.use("Trim", LandmarkMaterials.pbr("render", "#ECE5D6", 3.0))
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#86827B", 2.5))
	lm.use("Roof", LandmarkMaterials.pbr("terracotta", "#7F4435", 2.5))
	lm.use("Copper", LandmarkFrKit.copper("#4D7A68"))
	lm.use("Glass", LandmarkMaterials.glass("#222B30"))
	# Main L-shaped palace (38 x 24 m, 2.5 storeys, eaves 11.5 m).
	LandmarkFrKit.rect(lm, "Stone", -19.4, 19.4, -12.4, 12.4, 0.0, 1.8)
	LandmarkFrKit.rect(lm, "Brick", -19.0, 19.0, -12.0, 12.0, 1.8, 11.5)
	LandmarkFrParts.band(lm, "Trim", -19.0, 19.0, -12.0, 12.0, 6.4, 0.45, 0.14)
	LandmarkFrParts.cornice_ring(lm, "Trim", -19.0, 19.0, -12.0, 12.0, 11.0, 0.55)
	LandmarkFrKit.hip(lm, "Roof", -19.0, 19.0, -12.0, 12.0, 11.5, 5.5, 0.6)
	# Central projecting front gable toward Aurajoki (+Z).
	LandmarkFrKit.rect(lm, "Brick", -7.0, 7.0, 11.5, 14.5, 0.0, 12.2)
	LandmarkFrKit.gable(lm, "Roof", -7.0, 7.0, 11.5, 14.5, 12.2, 5.2, 0.4, "Brick", 0)
	LandmarkFrParts.opening(lm, "Stone", "Glass", Vector3(0.0, 0.4, 14.5), Vector3.BACK, 3.2, 4.6,
		LandmarkFrParts.HEAD_ROUND, 0.4, 0.22)
	for sz: float in [-1.0, 1.0]:
		LandmarkFrParts.facade(lm, "Brick", "Glass", Vector3(-17.0, 2.2, sz * 12.0), Vector3(17.0, 2.2, sz * 12.0),
			Vector3(0, 0, sz), 8.8, 8, 2, Vector2(1.5, 2.6), 0.9, 4.2, 0.22)
	# Decorative copper-capped turret at the corner.
	lm.frustum("Brick", Vector3(-17.5, 1.8, 11.0), 2.4, 2.3, 12.5, 8)
	lm.lathe("Copper", Vector3(-17.5, 14.3, 11.0), PackedVector2Array([Vector2(2.7, 0), Vector2(0.12, 4.2)]), 8)
	lm.commit(model)

## Turku City Theatre (Turun kaupunginteatteri, 1962, Risto-Veikko Luukkonen
## & Helmer Stenros): white modernist concrete-and-glass cultural landmark
## on the eastern Aurajoki embankment — broad glazed foyer wing facing the
## river and a tall white rectangular fly-tower behind it.
static func turku_city_theatre(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("White", LandmarkMaterials.pbr("render", "#EFECE4", 3.0))
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#C8C4BC", 2.5))
	lm.use("Roof", LandmarkMaterials.pbr("concrete", "#565A5E", 2.0))
	lm.use("Glass", LandmarkMaterials.glass("#283944"))
	lm.use("Frame", LandmarkMaterials.paint("#2E3236", 0.55, 0.4))
	# Riverside foyer wing (72 x 32 m, height 10.5 m) with continuous riverfront glazing (-Z faces river).
	LandmarkFrKit.rect(lm, "Concrete", -36.0, 36.0, -18.0, 14.0, 0.0, 1.2)
	LandmarkFrKit.rect(lm, "White", -36.0, 36.0, -18.0, 14.0, 1.2, 10.6)
	LandmarkFrKit.rect(lm, "Roof", -35.6, 35.6, -17.6, 13.6, 10.6, 11.0)
	# Panoramic glass foyer facade along the river (-Z).
	LandmarkFrKit.rect(lm, "Glass", -32.0, 32.0, -18.12, -17.9, 1.6, 8.6)
	for k in 17:
		var x := -32.0 + 4.0 * float(k)
		lm.box("Frame", Vector3(x, 5.1, -18.15), Vector3(0.22, 7.2, 0.28))
	# Cantilevered white roof canopy over the riverside terrace.
	LandmarkFrKit.rect(lm, "White", -37.0, 37.0, -21.5, -17.5, 8.6, 10.6)
	# Tall white stage fly-tower rising behind the auditorium to 22 m.
	LandmarkFrKit.rect(lm, "White", -16.0, 16.0, -2.0, 20.0, 10.6, 22.0)
	LandmarkFrKit.rect(lm, "Roof", -15.6, 15.6, -1.6, 19.6, 22.0, 22.4)
	LandmarkFrParts.band(lm, "Concrete", -16.0, 16.0, -2.0, 20.0, 21.3, 0.7, 0.15)
	lm.commit(model)
