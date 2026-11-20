extends RefCounted

## Builders for data/stockholm/sto_reg_towers.gd. Returns false for a
## type it does not own.

const Hotorg = preload("res://scripts/generation/landmarks/sweden_stockholm/towers/landmark_ss_hotorg.gd")
const Katarinahissen = preload("res://scripts/generation/landmarks/sweden_stockholm/towers/landmark_ss_katarinahissen.gd")
const Kastellet = preload("res://scripts/generation/landmarks/sweden_stockholm/towers/landmark_ss_kastellet.gd")
const SoderTorn = preload("res://scripts/generation/landmarks/sweden_stockholm/towers/landmark_ss_soder_torn.gd")

static func build(model: Node3D, type: String) -> bool:
	match type:
		"hotorgsskraporna": Hotorg.build(model)
		"katarinahissen": Katarinahissen.build(model)
		"kastellet_stockholm": Kastellet.build(model)
		"soder_torn": SoderTorn.build(model)
		_:
			return false
	return true
