extends RefCounted

## Builders for data/stockholm/sto_reg_island.gd. Returns false for a
## type it does not own.

static func build(model: Node3D, type: String) -> bool:
	match type:
		"af_chapman": StoIslandChapman.build(model)
		"skeppsholmen_church": StoIslandChurch.build(model)
		"moderna_museet": StoIslandModerna.build(model)
		"birger_jarls_torn": StoIslandBirger.build(model)
		"norstedts_building": StoIslandNorstedts.build(model)
		"evert_taubes_terrass": StoIslandTaube.build(model)
		_:
			return false
	return true
