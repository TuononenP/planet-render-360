class_name LandmarkSetShipTerminals
extends RefCounted

## Builders of the ship_terminals landmark batch: one `match` arm per
## registry type of LandmarkRegistryShipTerminals, all drawn by the shared
## LandmarkShipTerminalKit from the row's measured halls. Returns false for
## a type it does not own so LandmarkBuilder tries the next set.

static func build(model: Node3D, type: String) -> bool:
	match type:
		"tallinn_d_terminal", "riga_ferry_terminal", "copenhagen_ferry_terminal", \
		"oslo_cruise_terminal", "canaveral_terminal_1", "everglades_terminal_25", \
		"galveston_terminal_25", "manhattan_cruise_terminal", \
		"los_angeles_cruise_terminal", "seattle_smith_cove_terminal":
			LandmarkShipTerminalKit.build(model, LocationData.entry_for_type(type))
		_:
			return false
	return true
