class_name LandmarkFhMalls
extends RefCounted

## Biggest capital-region shopping centres, true metres: footprint-true
## low massing, banded facades, glazed entrances and roof plant. Heights
## are roof heights (mall block, excluding towers/parking above); see
## docs/helsinki-landmark-sources.md for areas and coordinates.

const U = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")

static func _mall(model: Node3D, w: float, d: float, h: float, wall: String, accent: String) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("concrete", wall, 3.0))
	lm.use("Glass", LandmarkMaterials.glass("#40555F"))
	lm.use("Trim", LandmarkMaterials.pbr("concrete", accent, 2.0))
	lm.use("Roof", LandmarkMaterials.paint("#5A5E60", 0.7))
	U.blk(lm, "Wall", 0, 0, 0, w, h - 2.5, d)
	# Horizontal facade bands and a continuous shopfront strip.
	for i in 3:
		U.blk(lm, "Trim", 0, 4.5 + float(i) * ((h - 7.0) / 3.0), 0, w + 0.4, 0.5, d + 0.4)
	U.blk(lm, "Glass", 0, 0.4, d * 0.5 + 0.06, w * 0.72, 3.6, 0.15)
	U.window_grid(lm, "Glass", Vector3(-w * 0.36, 0, d * 0.5), Vector3(w * 0.36, 0, d * 0.5),
		Vector3.BACK, 5.5, 2, (h - 8.0) * 0.5, 9, 3.2, 3.4)
	# Main entrance canopy and accent pylon at the front centre.
	U.blk(lm, "Trim", 0, 3.8, d * 0.5 + 2.2, 18.0, 0.5, 5.0)
	U.blk(lm, "Trim", 10.5, 0, d * 0.5 + 2.2, 0.8, h - 2.5, 0.8)
	# Roof slab, plant boxes and skylight strips.
	U.blk(lm, "Roof", 0, h - 2.5, 0, w - 4.0, 1.2, d - 4.0)
	for x in [-w * 0.28, 0.0, w * 0.28]:
		U.blk(lm, "Roof", x, h - 1.3, -d * 0.18, 16.0, 1.3, 9.0)
		U.blk(lm, "Glass", x, h - 1.25, d * 0.16, 22.0, 0.5, 5.0)
	U.blk(lm, "Trim", -w * 0.2, h - 1.3, d * 0.2, 10.0, 1.3, 8.0)
	lm.commit(model)

static func redi(model: Node3D) -> void:
	# The podium the Kalasatama towers stand on, topped by the Bryga
	# rooftop park (OSM leisure=park, layer 5): lawn, paths, planters,
	# trees and a pavilion on a stone parapet — not a flat slab. Short
	# park walkways run on the deck to the tower sides and end at the
	# parapet; they never leave the footprint, so the mapped layer-5
	# bridges land on a finished park instead of a bare roof.
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("concrete", "#9A8F82", 3.0))
	lm.use("Glass", LandmarkMaterials.glass("#40555F"))
	lm.use("Trim", LandmarkMaterials.pbr("stone", "#8E8B84", 2.5))
	lm.use("Roof", LandmarkMaterials.paint("#4C5052", 0.7))
	lm.use("Park", LandmarkMaterials.pbr("grass", "#66784A", 4.0))
	lm.use("Wood", LandmarkMaterials.pbr("wood", "#7A6248", 2.0))
	U.blk(lm, "Wall", 0, 0, 0, 200.0, 15.0, 180.0)
	U.blk(lm, "Glass", 0, 0.4, 90.06, 160.0, 4.2, 0.15)
	for i in 7:
		U.blk(lm, "Glass", (float(i) - 3.0) * 24.0, 6.0, 90.06, 12.0, 6.0, 0.15)
	# Stone parapet and the dark roof deck inside it.
	U.blk(lm, "Trim", 0, 15.0, 0, 202.0, 0.8, 182.0)
	U.blk(lm, "Roof", 0, 15.8, 0, 192.0, 0.7, 172.0)
	# Bryga lawn with gravel paths crossing it.
	U.blk(lm, "Park", 0, 16.5, 0, 156.0, 0.35, 128.0)
	U.blk(lm, "Trim", 0, 16.85, 0, 156.0, 0.1, 7.0)
	U.blk(lm, "Trim", 0, 16.85, 0, 7.0, 0.1, 128.0)
	for x in [-58.0, 58.0]:
		U.blk(lm, "Trim", x, 16.85, 0, 5.0, 0.1, 128.0)
	# Planters, benches and small park trees on the lawn.
	for x in [-66.0, -22.0, 22.0, 66.0]:
		for z in [-44.0, 44.0]:
			U.blk(lm, "Wood", x, 16.85, z, 9.0, 0.7, 2.2)
			lm.frustum("Wood", Vector3(x, 17.55, z), 0.14, 0.18, 1.5, 8)
			lm.lathe("Park", Vector3(x, 17.9, z), U.ball(1.05), 10)
	for x in [-44.0, 0.0, 44.0]:
		U.blk(lm, "Wood", x, 16.85, 10.0, 3.4, 0.5, 0.9)
	# Park walkways on the deck, running to the north tower side with
	# rails and posts that stand on the roof deck itself.
	for x in [19.0, -22.0]:
		U.blk(lm, "Trim", x, 16.95, -52.0, 4.2, 0.25, 72.0)
		for z in [-84.0, -64.0, -44.0, -24.0]:
			U.blk(lm, "Trim", x - 2.0, 16.5, z, 0.14, 1.1, 0.14)
			U.blk(lm, "Trim", x + 2.0, 16.5, z, 0.14, 1.1, 0.14)
		U.blk(lm, "Trim", x - 2.0, 17.55, -52.0, 0.1, 0.12, 72.0)
		U.blk(lm, "Trim", x + 2.0, 17.55, -52.0, 0.1, 0.12, 72.0)
	# Glass park pavilion and roof plant close at the registered height.
	U.blk(lm, "Glass", -52.0, 16.5, -30.0, 20.0, 2.6, 11.0)
	U.blk(lm, "Trim", -52.0, 19.1, -30.0, 21.0, 0.4, 12.0)
	U.blk(lm, "Roof", 48.0, 18.5, 28.0, 22.0, 1.5, 16.0)
	lm.commit(model)

static func tripla(model: Node3D) -> void:
	_mall(model, 190.0, 120.0, 30.0, "#A8A29A", "#38505A")

static func itis(model: Node3D) -> void:
	_mall(model, 200.0, 115.0, 25.0, "#B0A696", "#6A4A3E")

static func iso_omena(model: Node3D) -> void:
	_mall(model, 175.0, 110.0, 24.0, "#AEA79C", "#4A5A66")

static func sello(model: Node3D) -> void:
	_mall(model, 165.0, 105.0, 22.0, "#B5AA9C", "#5E5248")

static func jumbo(model: Node3D) -> void:
	_mall(model, 185.0, 120.0, 18.0, "#A39A90", "#54626A")
