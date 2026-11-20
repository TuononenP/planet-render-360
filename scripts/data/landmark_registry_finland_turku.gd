class_name LandmarkRegistryFinlandTurku
extends RefCounted

## Registry entries for the Turku landmark batch, in the format of
## LocationData.landmarks(). Types are built by LandmarkSetFinlandTurku.
## Each group lives in its own file under scripts/data/turku/; coordinates
## and yaw_deg follow OpenStreetMap footprints (see
## docs/turku-landmark-sources.md); +X east, +Z south, model turns by
## -yaw_deg so +X bears (90 + yaw_deg)°.

const GROUPS := [
	preload("res://scripts/data/turku/tku_reg_centre.gd"),
	preload("res://scripts/data/turku/tku_reg_aurajoki.gd"),
	preload("res://scripts/data/turku/tku_reg_hills.gd"),
	preload("res://scripts/data/turku/tku_reg_harbour.gd"),
	preload("res://scripts/data/turku/tku_reg_skyline.gd"),
]

static func entries() -> Array:
	var out: Array = []
	for group in GROUPS:
		out.append_array(group.entries())
	return out
