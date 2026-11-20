class_name LandmarkRegistrySwedenStockholm
extends RefCounted

## Registry entries for the sweden_stockholm landmark batch, in the
## format of LocationData.landmarks(). Types are built by LandmarkSetSwedenStockholm.
## Each group lives in its own file under scripts/data/stockholm/ with a
## matching build set under generation/landmarks/sweden_stockholm/.
## Selection rule (LandmarkSites.select): only items that stand on the
## skyline (spires, domes, towers, slabs) carry `skyline_priority`; low
## palaces, museums and squares are chosen nearest the eye first.

const GROUPS := [
	preload("res://scripts/data/stockholm/sto_reg_hero.gd"),
	preload("res://scripts/data/stockholm/sto_reg_island.gd"),
	preload("res://scripts/data/stockholm/sto_reg_towers.gd"),
	preload("res://scripts/data/stockholm/sto_reg_churches.gd"),
	preload("res://scripts/data/stockholm/sto_reg_palaces.gd"),
	preload("res://scripts/data/stockholm/sto_reg_gamla.gd"),
	preload("res://scripts/data/stockholm/sto_reg_norrmalm.gd"),
	preload("res://scripts/data/stockholm/sto_reg_inner.gd"),
	preload("res://scripts/data/stockholm/sto_reg_djurgarden.gd"),
	preload("res://scripts/data/stockholm/sto_reg_outer.gd"),
	preload("res://scripts/data/stockholm/sto_reg_bridges.gd"),
]

## The landmarks that predate the realism pass: they may open as a place's
## primary landmark and answer their name from anywhere, as before.
const ORIGINALS := ["hotorgsskraporna", "katarinahissen", "grona_lund_eclipse", "kastellet_stockholm",
	"royal_opera_stockholm", "grand_hotel_stockholm", "soder_torn", "riddarhuset_stockholm", "wrangel_palace",
	"bonde_palace", "nationalmuseum_stockholm", "klara_church", "sofia_church_stockholm", "tyska_kyrkan",
	"royal_palace_stockholm", "storkyrkan", "katarina_church", "hedvig_eleonora_church", "ericsson_globe",
	"kaknas_tower", "vasa_museum", "nordic_museum", "stockholm_public_library", "stockholm_concert_hall",
	"riksdag_building"]
## Ultra budget of every Stockholm primary candidate (see LandmarkSites.select):
## the registry extras and the total with room for eight bridges.
const ULTRA_REGISTRY_LIMIT := 48
const ULTRA_TOTAL_LIMIT := 56

## Every Stockholm entry. The ones added since are `secondary`: a search for
## "Fotografiska" or "3Arena" made far from Stockholm must not open
## Stockholm's model, so their aliases only answer within `radius_m` of the
## site and they never open as a place's primary. The originals carry the
## city's Ultra budget, as they can be the primary.
static func entries() -> Array:
	var out: Array = []
	for group in GROUPS:
		out.append_array(group.entries())
	for entry in out:
		if str(entry["type"]) in ORIGINALS:
			entry["ultra_registry_limit"] = ULTRA_REGISTRY_LIMIT
			entry["ultra_total_limit"] = ULTRA_TOTAL_LIMIT
		else:
			entry["secondary"] = true
	return out
