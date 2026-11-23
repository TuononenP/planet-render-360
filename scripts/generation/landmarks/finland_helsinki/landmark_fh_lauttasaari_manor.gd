extends RefCounted

## Lauttasaari Manor (Lauttasaaren kartano, Drumsö gård), main building of
## 1837 in Empire style (fi.wikipedia; Koneen Saatio restored it in 2018).
## Origin at the OSM building (way 29993853, 60.159028, 24.879080, yaw 0),
## `roof:shape=hipped`, two storeys.
##
## Measured: the outline and the City LoD2 roof (13.5 m with the chimneys).
## Estimated: the 7.8 m eaves, the pale ochre render, white trim, the grey
## roof and the two chimneys. Commons photos are not yet matched against the
## model (visual-plan/refs/landmarks/lauttasaari_manor/ if present).

const U = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")
const F = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_mall_footprints.gd")
const W = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_west_footprints.gd")

const ENTRY := {"type": "lauttasaari_manor", "name": "Lauttasaari Manor", "lat": 60.159028, "lon": 24.879080,
	"radius_m": 3500.0, "wiki_title": "Lauttasaari Manor", "height_m": 13.5, "clear_m": 19.0,
	"kind": "Manor", "aliases": ["lauttasaari manor", "lauttasaaren kartano", "drumsö gård"]}

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Render", LandmarkMaterials.pbr("concrete", "#E6D9A6", 2.0))
	lm.use("Trim", LandmarkMaterials.pbr("concrete", "#F1EEE4", 2.0))
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#6A6A66", 3.0))
	lm.use("Glass", LandmarkMaterials.glass("#2E383C"))
	lm.use("Roof", LandmarkMaterials.paint("#4E5352", 0.7))
	var poly := W.outline("lauttasaari_manor")
	var eave := 7.8
	lm.poly_prism("Granite", F.offset(poly, 0.15), 0.0, 0.8)
	lm.poly_prism("Render", poly, 0.8, eave)
	lm.poly_prism("Trim", F.offset(poly, 0.12), 4.1, 4.4, false)
	lm.poly_prism("Trim", F.offset(poly, 0.2), eave - 0.5, eave)
	W.edge_windows(lm, "Glass", poly, 1.5, 2, 3.4, 2.8, 1.1, 1.8, "Trim")
	# White corner pilasters and narrow wall strips between the bays.
	W.ribs(lm, "Trim", poly, 0.8, eave - 0.5, 5.6, 0.5, 0.1)
	var main := [Vector2(5.0, -16.8), Vector2(15.9, -7.4), Vector2(1.6, 8.9), Vector2(-9.3, -0.5)]
	W.hip_rect(lm, "Roof", main[0], main[1], main[2], main[3], eave, 4.0)
	W.hip_rect(lm, "Roof", Vector2(0.3, 7.8), Vector2(-1.9, 10.3), Vector2(-9.7, 3.6),
		Vector2(-7.5, 1.1), eave, 1.8)
	# Two brick chimneys on the ridge line of the main block.
	var centre: Vector2 = (main[0] + main[1] + main[2] + main[3]) * 0.25
	var ridge: Vector2 = (main[2] - main[1]).normalized()
	for s: float in [-1.0, 1.0]:
		var c := centre + ridge * (3.2 * s)
		U.blk(lm, "Render", c.x, eave + 2.0, c.y, 0.9, 3.45, 0.9)
		U.blk(lm, "Trim", c.x, eave + 5.45, c.y, 1.1, 0.25, 1.1)
	_porch(lm, poly, eave)
	lm.commit(model, "Lauttasaari_manor_")
	var warm := Color(1.0, 0.88, 0.68)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(21.0, 1.2, 11.5), Vector3(8.75, 5.0, 0.75), 48.0, 1.0, 35.0, warm],
		[Vector3(-16.0, 1.2, -16.0), Vector3(-2.0, 5.0, -7.0), 48.0, 0.85, 35.0, warm],
		[Vector3(16.0, 1.2, -22.0), Vector3(8.0, 5.0, -11.0), 46.0, 0.8, 35.0, warm],
		[Vector3(-12.0, 1.2, 18.0), Vector3(-3.0, 5.0, 6.0), 46.0, 0.8, 35.0, warm],
	])

## 1837 Empire pedimented columned front porch on the south-east main facade.
static func _porch(lm: LandmarkMesh, poly: PackedVector2Array, eave: float) -> void:
	var a := Vector2(15.9, -7.4)
	var b := Vector2(1.6, 8.9)
	var mid := (a + b) * 0.5
	var along2 := (b - a).normalized()
	var out2 := W.outward(poly, a, b)
	var out := Vector3(out2.x, 0.0, out2.y)
	var right := Vector3(along2.x, 0.0, along2.y)
	var basis := Basis(right, Vector3.UP, out)
	var depth := 2.7
	var width := 7.6
	var pc := Vector3(mid.x, 0.0, mid.y) + out * (depth * 0.5)
	lm.box("Granite", pc + Vector3(0, 0.42, 0), Vector3(width + 0.6, 0.84, depth + 0.3), basis)
	U.steps(lm, "Granite", Vector3(mid.x, 0.0, mid.y) + out * depth, out, 4.6, 0.38, 0.2, 4)
	# Four white Empire columns supporting the entablature and triangular pediment.
	var col_line := Vector3(mid.x, 0.84, mid.y) + out * (depth - 0.55)
	U.columns(lm, "Trim", col_line - right * (width * 0.42), col_line + right * (width * 0.42), 4, eave - 1.74, 0.32, 12)
	lm.box("Trim", pc + Vector3(0, eave - 0.45, 0), Vector3(width + 0.5, 0.9, depth + 0.3), basis)
	lm.gable("Roof", pc + Vector3(0, eave, 0), width + 0.6, depth + 0.4, 2.1, basis, 0.2, "Trim")
	# Glazed Empire entrance double doors behind the portico.
	var dc := Vector3(mid.x, 2.2, mid.y) + out * 0.06
	lm.box("Trim", dc, Vector3(2.4, 3.0, 0.16), basis, 0.0)
	lm.box("Glass", dc + out * 0.06, Vector3(1.8, 2.6, 0.08), basis, 0.0)
