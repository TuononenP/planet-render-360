extends RefCounted

## Embassy of Sweden, Helsinki (Pohjoisesplanadi 7, A.F. Granstedt 1839 /
## Torben Grut 1922), facing Market Square (+Z, yaw -3).
##
## Pale-ochre Neo-Classical palazzo with grey-pink granite plinth, rusticated
## ground arcade, central projecting 3-bay pilastered risalit, pedimented
## piano nobile windows, roof balustrade crowned with stone urns, sheet-metal
## hip roof to 18.5 m, and architectural floodlights.

const U = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")
const P = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_parts.gd")
const E = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_empire.gd")

const ENTRY := {"type": "swedish_embassy_helsinki", "name": "Embassy of Sweden, Helsinki",
	"lat": 60.16808, "lon": 24.95425, "radius_m": 1500.0, "wiki_title": "Embassy of Sweden, Helsinki",
	"height_m": 18.5, "clear_m": 18.0, "yaw_deg": -3.0, "kind": "Embassy", "secondary": true,
	"aliases": ["swedish embassy, helsinki", "embassy of sweden, helsinki", "ruotsin suurlähetystö",
		"sveriges ambassad helsingfors", "pohjoisesplanadi 7"]}

const W := 26.0
const D := 18.0
const HW := W * 0.5
const HD := D * 0.5
const PLINTH := 1.2
const F1 := 5.6
const EAVE := 14.8

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("render", "#DFC68E", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#EFE9D8", 2.0))
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#8F8780", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("sheet_metal", "#555C5E", 3.0, 0.55, 0.35))
	lm.use("Glass", LandmarkMaterials.glass("#2B3438"))
	lm.use("Gold", LandmarkMaterials.gold())
	U.blk(lm, "Stone", 0.0, 0.0, 0.0, W + 0.4, PLINTH, D + 0.4)
	U.blk(lm, "Wall", 0.0, PLINTH, 0.0, W, EAVE - PLINTH, D)
	# Central 3-bay projecting risalit on the Market Square (+Z) facade.
	U.blk(lm, "Wall", 0.0, PLINTH, HD + 0.35, 9.6, EAVE - PLINTH, 0.7)
	_front(lm)
	_sides(lm)
	_roof_and_balustrade(lm)
	lm.commit(model)
	var warm := Color(1.0, 0.88, 0.66)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-8.5, 0.8, HD + 12.0), Vector3(-5.0, 8.5, HD), 48.0, 0.9, 36.0, warm],
		[Vector3(8.5, 0.8, HD + 12.0), Vector3(5.0, 8.5, HD), 48.0, 0.9, 36.0, warm],
		[Vector3(0.0, 0.8, HD + 13.0), Vector3(0.0, 10.0, HD + 0.7), 38.0, 1.0, 38.0, warm],
	])

static func _front(lm: LandmarkMesh) -> void:
	var out := Vector3(0, 0, 1)
	# Rusticated ground arcade across the Market Square front.
	for k in 4:
		E.course(lm, "Stone", Vector2(-HW, HD), Vector2(HW, HD), Vector2(0, 1), PLINTH + 0.9 + 1.0 * float(k), 0.07, 0.06)
	P.arcade(lm, "Trim", Vector3(-HW + 1.4, 0, HD), Vector3(-5.0, 0, HD), out, PLINTH, F1 - PLINTH - 0.3, 2, 0.22)
	P.arcade(lm, "Trim", Vector3(5.0, 0, HD), Vector3(HW - 1.4, 0, HD), out, PLINTH, F1 - PLINTH - 0.3, 2, 0.22)
	P.arcade(lm, "Trim", Vector3(-4.8, 0, HD + 0.7), Vector3(4.8, 0, HD + 0.7), out, PLINTH, F1 - PLINTH - 0.2, 3, 0.25)
	E.row(lm, "Trim", "Glass", Vector3(-HW + 1.4, 0, HD), Vector3(-5.0, 0, HD), out, 1.6, 2, 1.3, 2.8, "arch")
	E.row(lm, "Trim", "Glass", Vector3(5.0, 0, HD), Vector3(HW - 1.4, 0, HD), out, 1.6, 2, 1.3, 2.8, "arch")
	E.row(lm, "Trim", "Glass", Vector3(-4.4, 0, HD + 0.7), Vector3(4.4, 0, HD + 0.7), out, 1.5, 3, 1.4, 3.1, "arch")
	# Piano nobile and top storey windows.
	E.row(lm, "Trim", "Glass", Vector3(-HW + 1.4, 0, HD), Vector3(-5.0, 0, HD), out, 6.4, 2, 1.4, 3.2, "hood")
	E.row(lm, "Trim", "Glass", Vector3(5.0, 0, HD), Vector3(HW - 1.4, 0, HD), out, 6.4, 2, 1.4, 3.2, "hood")
	E.row(lm, "Trim", "Glass", Vector3(-4.4, 0, HD + 0.7), Vector3(4.4, 0, HD + 0.7), out, 6.4, 3, 1.5, 3.4, "hood")
	E.row(lm, "Trim", "Glass", Vector3(-HW + 1.4, 0, HD), Vector3(-5.0, 0, HD), out, 11.0, 2, 1.3, 2.3, "rect")
	E.row(lm, "Trim", "Glass", Vector3(5.0, 0, HD), Vector3(HW - 1.4, 0, HD), out, 11.0, 2, 1.3, 2.3, "rect")
	E.row(lm, "Trim", "Glass", Vector3(-4.4, 0, HD + 0.7), Vector3(4.4, 0, HD + 0.7), out, 11.0, 3, 1.3, 2.3, "rect")
	# Paired giant pilasters on the corners and central risalit.
	for x in [-HW + 0.8, -4.5, 4.5, HW - 0.8]:
		var pz := HD + (0.7 if absf(x) < 5.0 else 0.0)
		E.pilaster(lm, "Trim", Vector3(x, 0, pz), out, F1, EAVE - 0.9 - F1, 0.75, 0.28)
	E.course(lm, "Trim", Vector2(-HW, HD), Vector2(HW, HD), Vector2(0, 1), F1 - 0.2, 0.45, 0.25)
	E.course(lm, "Trim", Vector2(-HW, HD), Vector2(HW, HD), Vector2(0, 1), 10.3, 0.28, 0.18)
	LandmarkDetail.cornice(lm, "Trim", Vector3(-HW, EAVE - 0.9, HD), Vector3(HW, EAVE - 0.9, HD), out, 1.0, true)

static func _sides(lm: LandmarkMesh) -> void:
	var rows := [[1.6, 1.2, 2.6, "plain"], [6.4, 1.3, 3.0, "rect"], [11.0, 1.2, 2.2, "plain"]]
	E.run(lm, "Trim", "Glass", Vector2(HW, -HD), Vector2(-HW, -HD), Vector2(0, -1), 3.6, rows, 1.5)
	E.run(lm, "Trim", "Glass", Vector2(HW, -HD), Vector2(HW, HD), Vector2(1, 0), 3.6, rows, 1.5)
	E.run(lm, "Trim", "Glass", Vector2(-HW, HD), Vector2(-HW, -HD), Vector2(-1, 0), 3.6, rows, 1.5)

static func _roof_and_balustrade(lm: LandmarkMesh) -> void:
	U.hip(lm, "Roof", Vector3(0.0, EAVE, 0.0), W + 0.6, D + 0.6, 3.7, 0.55)
	LandmarkDetail.balustrade(lm, "Trim", Vector3(-HW + 0.3, EAVE + 0.1, HD - 0.1),
		Vector3(HW - 0.3, EAVE + 0.1, HD - 0.1), 1.05, 5.0, 8)
	# Classical urn finials along the Market Square balustrade piers.
	var urn := PackedVector2Array([Vector2(0.18, 0.0), Vector2(0.12, 0.15), Vector2(0.28, 0.42),
		Vector2(0.22, 0.65), Vector2(0.14, 0.78), Vector2(0.22, 0.88), Vector2(0.0, 0.95)])
	for k in 6:
		var ux := lerpf(-HW + 0.3, HW - 0.3, float(k) / 5.0)
		lm.lathe("Trim", Vector3(ux, EAVE + 1.15, HD - 0.1), urn, 12)
	# Gilded crown emblem on the central risalit parapet and flagpole.
	U.blk(lm, "Trim", 0.0, EAVE + 0.1, HD + 0.55, 4.2, 1.25, 0.45)
	lm.disc("Gold", Vector3(0.0, EAVE + 0.75, HD + 0.80), Vector3(0, 0, 1), 0.42, 12)
	lm.frustum("Trim", Vector3(0.0, EAVE + 3.7, 0.0), 0.10, 0.05, 0.0, 6)
