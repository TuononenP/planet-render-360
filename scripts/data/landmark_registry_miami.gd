class_name LandmarkRegistryMiami
extends RefCounted

## Registry entries for the Miami landmark batch, in the format of
## LocationData.landmarks(). Bespoke icons live in group files under
## scripts/data/miami/ and skyline spec towers in MiamiTowerSpecs.
## Types are built by LandmarkSetMiami.

const GROUPS := [
	preload("res://scripts/data/miami/mia_reg_downtown.gd"),
	preload("res://scripts/data/miami/mia_reg_port.gd"),
	preload("res://scripts/data/miami/mia_reg_brickell.gd"),
	preload("res://scripts/data/miami/mia_reg_beach.gd"),
	preload("res://scripts/data/miami/mia_reg_midbeach.gd"),
	preload("res://scripts/data/miami/mia_reg_grove_gables.gd"),
	preload("res://scripts/data/miami/mia_reg_far.gd"),
]

## Primary view anchors per Miami view centre: each carries `icon: true` and
## the Miami Ultra slot budget (26 registry extras + room for 8 bridges).
const PRIMARIES := [
	"freedom_tower_miami",
	"brickell_city_centre_ribbon",
	"ocean_drive_carlyle_cardozo",
	"ocean_drive_breakwater_edison",
	"fontainebleau_miami_beach",
	"vizcaya_museum_gardens",
	"biltmore_hotel_coral_gables",
]

const ULTRA_REGISTRY_LIMIT := 26
const ULTRA_TOTAL_LIMIT := 34

static func icons() -> Array:
	var out: Array = []
	for group in GROUPS:
		for raw in group.entries():
			var entry: Dictionary = (raw as Dictionary).duplicate()
			if str(entry.get("type", "")) in PRIMARIES:
				entry["icon"] = true
				entry["ultra_registry_limit"] = ULTRA_REGISTRY_LIMIT
				entry["ultra_total_limit"] = ULTRA_TOTAL_LIMIT
			elif not entry.has("secondary"):
				entry["secondary"] = true
			out.append(entry)
	return out

static func entries() -> Array:
	var out := icons()
	for raw in MiamiTowerSpecs.entries():
		var entry: Dictionary = (raw as Dictionary).duplicate()
		if str(entry.get("type", "")) in PRIMARIES:
			entry.erase("secondary")
			entry["icon"] = true
			entry["ultra_registry_limit"] = ULTRA_REGISTRY_LIMIT
			entry["ultra_total_limit"] = ULTRA_TOTAL_LIMIT
		out.append(entry)
	return out
