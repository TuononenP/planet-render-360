class_name LandmarkSetSouthEurope
extends RefCounted

## Builders of the south europe landmark batch: one `match` arm per
## registry type of LandmarkRegistrySouthEurope. Returns false for a type it does
## not own so LandmarkBuilder tries the next set.

static func build(model: Node3D, type: String) -> bool:
	match type:
		"leaning_tower_pisa": SEuPisa.build(model)
		"st_peters_basilica": SEuRomeSacred.peters(model)
		"pantheon_rome": SEuRomeSacred.pantheon(model)
		"castel_sant_angelo": SEuRomeCivic.castel(model)
		"trevi_fountain": SEuRomeCivic.trevi(model)
		"altare_della_patria": SEuRomeCivic.vittoriano(model)
		"milan_cathedral": SEuDuomos.milan(model)
		"florence_duomo": SEuDuomos.florence(model)
		"st_marks_campanile": SEuVenice.campanile(model)
		"doges_palace": SEuVenice.doge(model)
		"alhambra": SEuAlhambra.alhambra(model)
		"parthenon_athens": SEuAlhambra.parthenon(model)
		"guggenheim_bilbao": SEuIberia.guggenheim(model)
		"giralda_seville": SEuIberia.giralda(model)
		"belem_tower": SEuIberia.belem(model)
		_:
			return false
	return true
