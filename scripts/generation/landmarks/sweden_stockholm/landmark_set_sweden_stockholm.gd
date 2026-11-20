class_name LandmarkSetSwedenStockholm
extends RefCounted

## Builders of the sweden_stockholm landmark batch: each group's set (one
## per data/stockholm/sto_reg_*.gd file) is tried in turn. Returns false
## for a type none of them owns so LandmarkBuilder tries the next set.

const SETS := [
	preload("res://scripts/generation/landmarks/sweden_stockholm/sto_set_hero.gd"),
	preload("res://scripts/generation/landmarks/sweden_stockholm/island/sto_set_island.gd"),
	preload("res://scripts/generation/landmarks/sweden_stockholm/towers/sto_set_towers.gd"),
	preload("res://scripts/generation/landmarks/sweden_stockholm/churches/sto_set_churches.gd"),
	preload("res://scripts/generation/landmarks/sweden_stockholm/palaces/sto_set_palaces.gd"),
	preload("res://scripts/generation/landmarks/sweden_stockholm/gamla/sto_set_gamla.gd"),
	preload("res://scripts/generation/landmarks/sweden_stockholm/norrmalm/sto_set_norrmalm.gd"),
	preload("res://scripts/generation/landmarks/sweden_stockholm/inner/sto_set_inner.gd"),
	preload("res://scripts/generation/landmarks/sweden_stockholm/stations/sto_set_stations.gd"),
	preload("res://scripts/generation/landmarks/sweden_stockholm/djurgarden/sto_set_djurgarden.gd"),
	preload("res://scripts/generation/landmarks/sweden_stockholm/outer/sto_set_outer.gd"),
	preload("res://scripts/generation/landmarks/sweden_stockholm/bridges/sto_set_bridges.gd"),
]

static func build(model: Node3D, type: String) -> bool:
	for set in SETS:
		if set.build(model, type):
			return true
	return false
