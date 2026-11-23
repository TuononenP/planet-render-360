extends RefCounted

## Supreme Court of Finland (Korkein oikeus, F.A. Sjöström, 1883),
## Pohjoisesplanadi 3, facing Market Square (+Z, yaw -3).
##
## Neo-Renaissance palace with rusticated granite base and arched portals,
## cream-sandstone piano nobile with triangular-pedimented windows and
## central Corinthian-pilastered risalit, bracketed cornice, steep hip/mansard
## sheet-metal roof with dormers to 20.0 m, and architectural floodlights.

const U = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")
const P = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_parts.gd")
const E = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_empire.gd")

const ENTRY := {"type": "supreme_court_helsinki", "name": "Supreme Court of Finland",
	"lat": 60.16792, "lon": 24.95545, "radius_m": 1500.0, "wiki_title": "Supreme Court of Finland",
	"height_m": 20.0, "clear_m": 18.0, "yaw_deg": -3.0, "kind": "Courthouse", "secondary": true,
	"aliases": ["supreme court of finland", "korkein oikeus", "högsta domstolen", "pohjoisesplanadi 3"]}

const W := 26.0
const D := 18.0
const HW := W * 0.5
const HD := D * 0.5
const PLINTH := 1.4
const F1 := 6.0
const EAVE := 15.8

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("limestone", "#D9C9A5", 2.5))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#EFE7D4", 2.0))
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#867E78", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("sheet_metal", "#4C5355", 3.0, 0.55, 0.35))
	lm.use("Glass", LandmarkMaterials.glass("#2A3237"))
	lm.use("Lamp", LandmarkMaterials.lit("#FFE4AC", 0.5))
	U.blk(lm, "Stone", 0.0, 0.0, 0.0, W + 0.4, PLINTH, D + 0.4)
	U.blk(lm, "Stone", 0.0, PLINTH, 0.0, W + 0.15, F1 - PLINTH, D + 0.15)
	U.blk(lm, "Wall", 0.0, F1, 0.0, W, EAVE - F1, D)
	# Central projecting 3-bay Neo-Renaissance risalit.
	U.blk(lm, "Stone", 0.0, PLINTH, HD + 0.4, 9.8, F1 - PLINTH, 0.8)
	U.blk(lm, "Wall", 0.0, F1, HD + 0.4, 9.8, EAVE - F1, 0.8)
	_front(lm)
	_sides(lm)
	_roof(lm)
	lm.commit(model)
	var warm := Color(1.0, 0.88, 0.66)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-8.5, 0.8, HD + 12.0), Vector3(-5.0, 9.5, HD), 48.0, 0.9, 36.0, warm],
		[Vector3(8.5, 0.8, HD + 12.0), Vector3(5.0, 9.5, HD), 48.0, 0.9, 36.0, warm],
		[Vector3(0.0, 0.8, HD + 13.0), Vector3(0.0, 12.0, HD + 0.8), 38.0, 1.0, 38.0, warm],
	])

static func _front(lm: LandmarkMesh) -> void:
	var out := Vector3(0, 0, 1)
	# Rusticated granite ground floor with arched bays and central portal.
	for k in 5:
		E.course(lm, "Trim", Vector2(-HW, HD + 0.08), Vector2(HW, HD + 0.08), Vector2(0, 1),
			PLINTH + 0.8 + 0.9 * float(k), 0.08, 0.06)
	E.row(lm, "Trim", "Glass", Vector3(-HW + 1.4, 0, HD + 0.08), Vector3(-5.2, 0, HD + 0.08), out, 1.8, 2, 1.3, 2.8, "arch")
	E.row(lm, "Trim", "Glass", Vector3(5.2, 0, HD + 0.08), Vector3(HW - 1.4, 0, HD + 0.08), out, 1.8, 2, 1.3, 2.8, "arch")
	E.row(lm, "Trim", "Glass", Vector3(-4.2, 0, HD + 0.8), Vector3(4.2, 0, HD + 0.8), out, 1.7, 3, 1.5, 3.2, "arch")
	LandmarkDetail.arch(lm, "Trim", Vector3(0.0, 4.3, HD + 0.8), out, 2.4, 0.4, 0.35)
	for sx in [-2.2, 2.2]:
		lm.lathe("Lamp", Vector3(sx, 3.6, HD + 1.05), U.ball(0.20), 10)
	# Piano nobile and upper storey with classical pilasters and pediments.
	E.row(lm, "Trim", "Glass", Vector3(-HW + 1.4, 0, HD), Vector3(-5.2, 0, HD), out, 6.8, 2, 1.4, 3.4, "hood")
	E.row(lm, "Trim", "Glass", Vector3(5.2, 0, HD), Vector3(HW - 1.4, 0, HD), out, 6.8, 2, 1.4, 3.4, "hood")
	E.row(lm, "Trim", "Glass", Vector3(-4.2, 0, HD + 0.8), Vector3(4.2, 0, HD + 0.8), out, 6.8, 3, 1.5, 3.6, "hood")
	E.row(lm, "Trim", "Glass", Vector3(-HW + 1.4, 0, HD), Vector3(-5.2, 0, HD), out, 11.8, 2, 1.3, 2.5, "round")
	E.row(lm, "Trim", "Glass", Vector3(5.2, 0, HD), Vector3(HW - 1.4, 0, HD), out, 11.8, 2, 1.3, 2.5, "round")
	E.row(lm, "Trim", "Glass", Vector3(-4.2, 0, HD + 0.8), Vector3(4.2, 0, HD + 0.8), out, 11.8, 3, 1.3, 2.5, "round")
	for x in [-HW + 0.7, -4.6, -1.6, 1.6, 4.6, HW - 0.7]:
		var pz := HD + (0.8 if absf(x) < 5.0 else 0.0)
		E.pilaster(lm, "Trim", Vector3(x, 0, pz), out, F1, EAVE - 1.0 - F1, 0.75, 0.30)
	E.course(lm, "Trim", Vector2(-HW, HD), Vector2(HW, HD), Vector2(0, 1), F1 - 0.2, 0.45, 0.25)
	E.course(lm, "Trim", Vector2(-HW, HD), Vector2(HW, HD), Vector2(0, 1), 11.0, 0.32, 0.20)
	LandmarkDetail.cornice(lm, "Trim", Vector3(-HW, EAVE - 1.0, HD), Vector3(HW, EAVE - 1.0, HD), out, 1.1, true)

static func _sides(lm: LandmarkMesh) -> void:
	var rows := [[1.8, 1.2, 2.7, "arch"], [6.8, 1.3, 3.2, "hood"], [11.8, 1.2, 2.4, "plain"]]
	E.run(lm, "Trim", "Glass", Vector2(HW, -HD), Vector2(-HW, -HD), Vector2(0, -1), 3.6, rows, 1.5)
	E.run(lm, "Trim", "Glass", Vector2(HW, -HD), Vector2(HW, HD), Vector2(1, 0), 3.6, rows, 1.5)
	E.run(lm, "Trim", "Glass", Vector2(-HW, HD), Vector2(-HW, -HD), Vector2(-1, 0), 3.6, rows, 1.5)

static func _roof(lm: LandmarkMesh) -> void:
	U.hip(lm, "Roof", Vector3(0.0, EAVE, 0.0), W + 0.8, D + 0.8, 4.2, 0.45)
	# Central Neo-Renaissance risalit pediment/attic crest.
	U.blk(lm, "Trim", 0.0, EAVE, HD + 0.3, 9.6, 1.2, 0.7)
	lm.gable("Trim", Vector3(0.0, EAVE + 1.2, HD + 0.1), 9.6, 1.6, 2.2, Basis(), 0.2, "Wall")
	# Flanking roof dormers and brick/limestone chimneys.
	for sx in [-8.2, 8.2]:
		U.blk(lm, "Trim", sx, EAVE + 0.4, HD - 1.6, 1.6, 1.9, 1.3)
		lm.gable("Roof", Vector3(sx, EAVE + 2.3, HD - 1.6), 1.6, 1.3, 0.8, Basis(), 0.1, "Trim")
		lm.quad("Glass", Vector3(sx - 0.5, EAVE + 0.7, HD - 0.92), Vector3(sx + 0.5, EAVE + 0.7, HD - 0.92),
			Vector3(sx + 0.5, EAVE + 2.0, HD - 0.92), Vector3(sx - 0.5, EAVE + 2.0, HD - 0.92), Vector3(0, 0, 1))
	for cx in [-6.5, 6.5]:
		U.blk(lm, "Stone", cx, EAVE + 2.0, -2.5, 1.0, 2.0, 1.0)
		U.blk(lm, "Trim", cx, EAVE + 3.9, -2.5, 1.25, 0.25, 1.25)
