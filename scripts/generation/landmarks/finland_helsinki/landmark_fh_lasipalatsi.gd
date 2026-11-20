class_name LandmarkFhLasipalatsi
extends RefCounted

## Lasipalatsi (the Glass Palace, 1936, Revell, Riihimäki and Kokko) beside
## Amos Rex, true metres, extruded from its OpenStreetMap outline (way
## 8035238, 3 levels, flat roof; Douglas-Peucker simplified to 0.5 m; flat
## x, z pairs about the registry origin, +X east, +Z south, yaw 0): a pale
## rendered functionalist block with a glazed shopfront storey on slim steel
## mullions and two storeys of continuous ribbon windows. Heights are
## estimates: docs/helsinki-landmark-sources.md. From the Commons photos
## (visual-plan/refs/landmarks/lasipalatsi/): bright white render, white window
## frames, tinted shopfront glazing; the slender clock tower (OSM way
## 28775756) is not modelled because the registry height is 12.8 m.

const F = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_mall_footprints.gd")
const W = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_west_footprints.gd")

const OUTLINE := [
	-58.9, -24.3, -62.5, -34.0, -35.8, -53.9, -36.5, -54.8, -31.7, -58.4, -31.0, -57.5, -20.8, -65.4,
	49.7, 28.1, 6.7, 59.9, -0.4, 50.4, 31.5, 26.8, 19.0, 10.2, 13.9, 14.3, -17.8, -28.0]

const EAVE := 12.2
const SHOP := 4.6

static func lasipalatsi(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("render", "#E2E0D4", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("render", "#ECEADC", 2.0))
	lm.use("Glass", LandmarkMaterials.paint("#6F8F95", 0.25, 0.4))
	lm.use("Metal", LandmarkMaterials.paint("#EDEBE0", 0.5))
	lm.use("Roof", LandmarkMaterials.paint("#5A5E5E", 0.8))
	var poly := PackedVector2Array()
	for i in range(0, OUTLINE.size() - 1, 2):
		poly.append(Vector2(float(OUTLINE[i]), float(OUTLINE[i + 1])))
	lm.poly_prism("Wall", poly, 0.0, EAVE)
	# Glazed shopfront storey on slim steel mullions, over a low plinth.
	lm.poly_prism("Glass", F.offset(poly, 0.06), 0.5, SHOP, false)
	W.ribs(lm, "Metal", poly, 0.5, SHOP, 2.2, 0.07, 0.12)
	lm.poly_prism("Trim", F.offset(poly, 0.25), SHOP, SHOP + 0.35)
	# Two storeys of continuous ribbon windows, mullioned.
	W.ribbons(lm, "Glass", poly, SHOP + 1.3, 1.7, 2, 3.4)
	W.ribs(lm, "Metal", poly, SHOP + 1.3, SHOP + 3.0, 3.0, 0.08, 0.12)
	W.ribs(lm, "Metal", poly, SHOP + 4.7, SHOP + 6.4, 3.0, 0.08, 0.12)
	# Flat roof behind a pale parapet.
	lm.poly_prism("Trim", F.offset(poly, 0.2), EAVE, EAVE + 0.6)
	lm.poly_prism("Roof", F.offset(poly, -0.5), EAVE + 0.3, EAVE + 0.5)
	lm.commit(model, "Lasipalatsi_")
