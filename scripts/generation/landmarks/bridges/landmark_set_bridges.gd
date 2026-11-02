class_name LandmarkSetBridges
extends RefCounted

## Builders of the bridges landmark batch: one `match` arm per
## registry type of LandmarkRegistryBridges. Returns false for a type it does
## not own so LandmarkBuilder tries the next set.

static func build(model: Node3D, type: String) -> bool:
	match type:
		"millau_viaduct": LandmarkBrStayed.millau(model)
		"oresund_bridge": LandmarkBrStayed.oresund(model)
		"erasmus_bridge": LandmarkBrStayed.erasmus(model)
		"akashi_kaikyo_bridge": LandmarkBrSuspensionLong.akashi(model)
		"tsing_ma_bridge": LandmarkBrSuspensionLong.tsing_ma(model)
		"verrazzano_bridge": LandmarkBrSuspensionLong.verrazzano(model)
		"bosphorus_bridge": LandmarkBrSuspensionLong.bosphorus(model)
		"ponte_25_abril": LandmarkBrSuspensionMid.ponte_25_abril(model)
		"lions_gate_bridge": LandmarkBrSuspensionMid.lions_gate(model)
		"chain_bridge": LandmarkBrSuspensionMid.chain_bridge(model)
		"forth_bridge": LandmarkBrForth.forth(model)
		"pont_du_gard": LandmarkBrMasonry.pont_du_gard(model)
		"stari_most": LandmarkBrMasonry.stari_most(model)
		"rialto_bridge": LandmarkBrMasonry.rialto(model)
		"charles_bridge": LandmarkBrTowns.charles(model)
		"ponte_vecchio": LandmarkBrTowns.ponte_vecchio(model)
		_:
			return false
	return true
