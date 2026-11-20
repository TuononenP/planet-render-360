extends RefCounted

## Builders for data/stockholm/sto_reg_norrmalm.gd. Returns false for a
## type it does not own.

const Dramaten = preload("res://scripts/generation/landmarks/sweden_stockholm/norrmalm/sto_dramaten.gd")
const Kungstornen = preload("res://scripts/generation/landmarks/sweden_stockholm/norrmalm/sto_kungstornen.gd")
const Kulturhuset = preload("res://scripts/generation/landmarks/sweden_stockholm/norrmalm/sto_kulturhuset.gd")
const StoRosenbad = preload("res://scripts/generation/landmarks/sweden_stockholm/norrmalm/sto_rosenbad.gd")
const StoSagerska = preload("res://scripts/generation/landmarks/sweden_stockholm/norrmalm/sto_sagerska.gd")
const StoArvfurstens = preload("res://scripts/generation/landmarks/sweden_stockholm/norrmalm/sto_arvfurstens.gd")
const StoWaterfront = preload("res://scripts/generation/landmarks/sweden_stockholm/norrmalm/sto_waterfront.gd")

static func build(model: Node3D, type: String) -> bool:
	match type:
		"dramaten": Dramaten.build(model)
		"kungstornen": Kungstornen.build(model)
		"kulturhuset_sergels_torg": Kulturhuset.build(model)
		"rosenbad": StoRosenbad.build(model)
		"sagerska_huset": StoSagerska.build(model)
		"arvfurstens_palats": StoArvfurstens.build(model)
		"stockholm_waterfront": StoWaterfront.build(model)
		_:
			return false
	return true
