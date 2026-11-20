extends RefCounted

## Builders for the Stockholm station registry entry (data/stockholm/
## sto_reg_inner.gd: stockholm_central_station). Returns false for a type it
## does not own. LandmarkSetSwedenStockholm runs before the capital-station
## set, so this arm wins over the generic LandmarkStationKit result.

const Central = preload("res://scripts/generation/landmarks/sweden_stockholm/stations/sto_central_station.gd")

static func build(model: Node3D, type: String) -> bool:
	match type:
		"stockholm_central_station": Central.build(model)
		_:
			return false
	return true
