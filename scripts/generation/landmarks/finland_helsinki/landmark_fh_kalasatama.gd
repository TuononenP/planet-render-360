class_name LandmarkFhKalasatama
extends RefCounted

## Kalasatama (Redi) towers, true metres. Heights and footprints follow
## OpenStreetMap (Majakka 134 m/35, Loisto 124 m/32, Lumo One 120 m/31,
## Horisontti 109 m/26, Visio 98 m/24); see docs/helsinki-landmark-sources.md.
## One parametric shaft per tower: balcony bands, glazed crown and mast
## bring each shaft to its documented height over the shared Redi podium.

const U = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")

static func _tower(model: Node3D, height: float, w: float, d: float, wall: String, accent: String) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("concrete", wall, 3.0))
	lm.use("Glass", LandmarkMaterials.glass("#3A4E58"))
	lm.use("Trim", LandmarkMaterials.pbr("concrete", accent, 2.0))
	lm.use("Roof", LandmarkMaterials.paint("#4A4F52", 0.6))
	# Podium slice the shaft shares with the Redi mall model.
	U.blk(lm, "Trim", 0, 0, 0, w + 6.0, 5.0, d + 6.0)
	U.blk(lm, "Wall", 0, 5.0, 0, w, height - 9.0, d)
	# Balcony bands and window rhythm up the shaft.
	var floors := int((height - 14.0) / 3.1)
	for i in range(1, floors):
		var y := 5.0 + float(i) * 3.1
		U.blk(lm, "Trim", 0, y, 0, w + 0.5, 0.28, d + 0.5)
	U.box_windows(lm, "Glass", 0, 0, w, d, 7.0, maxi(floors - 2, 4), 3.1,
		maxi(int(w / 4.5), 3), maxi(int(d / 4.5), 3), 1.7, 2.0)
	# Glazed crown, roof slab and mast close at the documented height.
	U.blk(lm, "Glass", 0, height - 4.0, 0, w - 3.0, 2.6, d - 3.0)
	U.blk(lm, "Roof", 0, height - 1.4, 0, w - 1.0, 0.5, d - 1.0)
	U.blk(lm, "Trim", 0, height - 0.9, 0, 0.7, 0.9, 0.7)
	lm.commit(model)

static func majakka(model: Node3D) -> void:
	_tower(model, 134.0, 25.0, 28.0, "#B9B0A2", "#7A4A3A")

static func loisto(model: Node3D) -> void:
	_tower(model, 124.0, 27.0, 25.0, "#C4BCB0", "#5A6A72")

static func lumo_one(model: Node3D) -> void:
	_tower(model, 120.0, 24.0, 24.0, "#AFA79A", "#6A5A48")

static func horisontti(model: Node3D) -> void:
	_tower(model, 109.0, 32.0, 31.0, "#B5BDC2", "#42565E")

static func visio(model: Node3D) -> void:
	_tower(model, 98.0, 32.0, 34.0, "#BCB2A4", "#74584A")
