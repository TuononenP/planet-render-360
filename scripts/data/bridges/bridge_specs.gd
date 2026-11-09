class_name BridgeSpecs
extends RefCounted

## Every capital-bridge row (BridgeSpec), one table file per region listed
## here, plus the by-id lookup the builder uses. A new region is a
## BridgeSpecs<Region> class with `static func rows() -> Array`, added below.

static var _all: Array = []
static var _by_id: Dictionary = {}

static func all() -> Array:
	if _all.is_empty():
		for batch in [BridgeSpecsPilot.rows(), BridgeSpecsAfricaWestCentral.rows(),
				BridgeSpecsCaribbeanIslands.rows(), BridgeSpecsNorthAmerica.rows(),
				BridgeSpecsMideastNorthAfrica.rows(), BridgeSpecsWestEurope.rows(),
				BridgeSpecsSouthAmerica.rows(), BridgeSpecsSouthAsia.rows(),
				BridgeSpecsAfricaEastSouth.rows(), BridgeSpecsSoutheastAsiaAuNz.rows(),
				BridgeSpecsNorthEurope.rows(), BridgeSpecsCentralEurope.rows(),
				BridgeSpecsEastAsia.rows(), BridgeSpecsEastEuropeCentralAsia.rows(),
				BridgeSpecsSouthEastEurope.rows()]:
			_all.append_array(batch)
		for row in _all:
			_by_id[str(row["id"])] = row
	return _all

## The rows that are built: confident enough (BridgeSpec.MIN_BUILT_CONF) to
## replace the mapped deck with a model.
static func built() -> Array:
	return all().filter(func(row: Dictionary) -> bool: return int(row["conf"]) >= BridgeSpec.MIN_BUILT_CONF)

## The built row with registry type `id`, {} when it is not a spec bridge.
static func row_for(id: String) -> Dictionary:
	all()
	var row: Dictionary = _by_id.get(id, {})
	return row if int(row.get("conf", 0)) >= BridgeSpec.MIN_BUILT_CONF else {}
