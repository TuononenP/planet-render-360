class_name LandmarkRegistryBridgeSpecs
extends RefCounted

## Registry entries of the capital bridge tables, derived from the rows
## (BridgeSpec.to_entry) so an entry can never disagree with its table.
## Types are built by LandmarkSetBridgeSpecs.

static func entries() -> Array:
	var out: Array = []
	for row in BridgeSpecs.built():
		out.append(BridgeSpec.to_entry(row))
	return out
