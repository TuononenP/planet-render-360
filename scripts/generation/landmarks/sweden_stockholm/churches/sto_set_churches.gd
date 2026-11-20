extends RefCounted

## Builders for data/stockholm/sto_reg_churches.gd. Returns false for a
## type it does not own.

const GermanChurch = preload("res://scripts/generation/landmarks/sweden_stockholm/landmark_ss_german_church.gd")
const HeroChurches = preload("res://scripts/generation/landmarks/sweden_stockholm/landmark_ss_hero_churches.gd")

static func build(model: Node3D, type: String) -> bool:
	match type:
		"klara_church": HeroChurches.klara(model)
		"sofia_church_stockholm": HeroChurches.sofia(model)
		"tyska_kyrkan": GermanChurch.build(model)
		_:
			return false
	return true
