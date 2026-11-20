extends RefCounted

## Builders for the Stockholm bridges that BridgeParam alone cannot draw
## (plan S-4). Their registry entries are rows of BridgeSpecs
## (data/bridges/bridge_specs_north_europe.gd), so data/stockholm/
## sto_reg_bridges.gd stays empty. Returns false for a type it does not own.

const TYPES := ["br_stockholm_djurgardsbron", "br_stockholm_skeppsholmsbron", "br_stockholm_stromsbron"]

static func build(model: Node3D, type: String) -> bool:
	if not type in TYPES:
		return false
	return build_row(model, type, BridgeSpecs.row_for(type))

## `type` built from `row` (a BridgeSpecs row, or BridgeSpec.fitted of one).
static func build_row(model: Node3D, type: String, row: Dictionary) -> bool:
	match type:
		"br_stockholm_djurgardsbron": StoBridgeDjurgard.build(model, row)
		"br_stockholm_skeppsholmsbron": StoBridgeSkeppsholm.build(model, row)
		"br_stockholm_stromsbron": StoBridgeStromsbron.build(model, row)
		_:
			return false
	return true
