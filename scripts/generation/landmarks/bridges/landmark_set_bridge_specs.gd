class_name LandmarkSetBridgeSpecs
extends RefCounted

## Builder of the capital bridge tables: any registry type that has a
## BridgeSpecs row is built from its numbers by BridgeParam. Returns false for
## a type it does not own so LandmarkBuilder tries the next set.

static func build(model: Node3D, type: String) -> bool:
	var row := BridgeSpecs.row_for(type)
	if row.is_empty():
		return false
	BridgeParam.build(model, row)
	return true
