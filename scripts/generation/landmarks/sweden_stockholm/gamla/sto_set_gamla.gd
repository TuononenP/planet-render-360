extends RefCounted

## Builders for data/stockholm/sto_reg_gamla.gd. Returns false for a
## type it does not own.

const Stortorget = preload("res://scripts/generation/landmarks/sweden_stockholm/gamla/sto_stortorget.gd")
const Skeppsbron = preload("res://scripts/generation/landmarks/sweden_stockholm/gamla/sto_skeppsbron.gd")
const Slussen = preload("res://scripts/generation/landmarks/sweden_stockholm/gamla/sto_slussen.gd")

static func build(model: Node3D, type: String) -> bool:
	match type:
		"slussen_guldbron": Slussen.build(model)
		"stortorget_stockholm": Stortorget.build(model)
		"skeppsbron_stockholm": Skeppsbron.build(model)
		_:
			return false
	return true
