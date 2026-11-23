class_name LandmarkSetBridgeSpecs
extends RefCounted

## Builder of the capital bridge tables: any registry type that has a
## BridgeSpecs row is built from its numbers by BridgeParam (or a city's
## bespoke bridge enhancer sharing the same row). Returns false for a type
## it does not own so LandmarkBuilder tries the next set.

static func build(model: Node3D, type: String) -> bool:
	var row := BridgeSpecs.row_for(type)
	if row.is_empty():
		return false
	match type:
		"br_bangkok_rama_viii_bridge":
			LandmarkBkRamaViii.build(model, row)
		"br_bangkok_pok_klao_bridge":
			LandmarkBkPokKlao.build(model, row)
		"br_bangkok_memorial_bridge":
			LandmarkBkMemorialBridge.build(model, row)
		_:
			BridgeParam.build(model, row)
	return true
