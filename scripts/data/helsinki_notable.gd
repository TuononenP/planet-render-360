class_name HelsinkiNotable
extends RefCounted

## Well-known central Helsinki buildings that have no hand-built landmark
## model: their real facade finish, colour, roof and storeys, keyed by OSM
## identity, so the district roll cannot turn the Pohjola soapstone or the
## Grand Marina warehouse into a pastel apartment block. Values fill only
## what the map leaves out (BuildingReferences.fill) and run before the
## city register, so a mapped tag still wins and the curated row beats the
## register's coded guess. Each row names its source.

const PROVENANCE := "hel_notable"

## "way:<id>" → {name, source, values: {material, colour, roof_material,
## roof_colour, levels, start_year, ...}}.
## Every building the plan's audit named as missing now has a hand-built
## landmark (landmark_fh_*); the rows below are the commercial-core stone
## fronts that stay OSM extrusions and whose finish is documented.
const ROWS := {
	"way:17425472": {
		"name": "Pohjola Insurance building (Pohjolan toimitalo)",
		# Aleksanterinkatu 44, 1899-1901, Gesellius-Lindgren-Saarinen: rough-hewn
		# granite and soapstone, grey-green, the first National Romantic stone front.
		"source": "https://en.wikipedia.org/wiki/Pohjola_Insurance_building",
		"values": {"material": "stone", "colour": "#9a9d94", "start_year": 1901},
	},
	"way:123550797": {
		"name": "Stock Exchange building (Pörssitalo)",
		# Fabianinkatu 14, Lars Sonck, 1911-12: grey granite front.
		"source": "https://fi.wikipedia.org/wiki/Pörssitalo_(Helsinki)",
		"values": {"material": "stone", "colour": "#918f8a", "start_year": 1912},
	},
	"way:224711434": {
		"name": "New Student House (Uusi ylioppilastalo)",
		# Mannerheimintie 5, Lindgren and Lönn, 1910: a soapstone, not heavy
		# natural-stone, front, dark grey-green.
		"source": "https://en.wikipedia.org/wiki/New_Student_House,_Helsinki",
		"values": {"material": "stone", "colour": "#858c84", "start_year": 1910},
	},
}

static func apply(buildings: Array) -> int:
	var n := 0
	for b in buildings:
		if not (b is Dictionary):
			continue
		var row := row_for(b as Dictionary)
		if row.is_empty():
			continue
		if not BuildingReferences.fill(b as Dictionary, row["values"], PROVENANCE).is_empty():
			n += 1
	return n

## The row for one building ({} when it has none).
static func row_for(b: Dictionary) -> Dictionary:
	for id in OsmParser.ids_of(b):
		if ROWS.has(id):
			return ROWS[id]
	return {}
