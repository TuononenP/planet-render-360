extends RefCounted

## Stockholm bridges (plan S-4) are `BridgeSpecs` rows (bridge_specs_north_europe.gd) that register
## themselves; only Djurgårdsbron and Skeppsholmsbron have bespoke models, built by
## sweden_stockholm/bridges/sto_set_bridges.gd. This group stays empty.

static func entries() -> Array:
	return []
