extends RefCounted

## Builders for data/stockholm/sto_reg_palaces.gd. Returns false for a
## type it does not own.

const StoOpera = preload("res://scripts/generation/landmarks/sweden_stockholm/palaces/sto_opera.gd")
const StoGrandHotel = preload("res://scripts/generation/landmarks/sweden_stockholm/palaces/sto_grand_hotel.gd")
const StoRiddarhuset = preload("res://scripts/generation/landmarks/sweden_stockholm/palaces/sto_riddarhuset.gd")
const StoWrangel = preload("res://scripts/generation/landmarks/sweden_stockholm/palaces/sto_wrangel.gd")
const StoBonde = preload("res://scripts/generation/landmarks/sweden_stockholm/palaces/sto_bonde.gd")
const StoNationalmuseum = preload("res://scripts/generation/landmarks/sweden_stockholm/palaces/sto_nationalmuseum.gd")

static func build(model: Node3D, type: String) -> bool:
	match type:
		"royal_opera_stockholm": StoOpera.build(model)
		"grand_hotel_stockholm": StoGrandHotel.build(model)
		"riddarhuset_stockholm": StoRiddarhuset.build(model)
		"wrangel_palace": StoWrangel.build(model)
		"bonde_palace": StoBonde.build(model)
		"nationalmuseum_stockholm": StoNationalmuseum.build(model)
		_:
			return false
	return true
