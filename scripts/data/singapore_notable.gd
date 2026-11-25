class_name SingaporeNotable
extends RefCounted

## Well-known Singapore buildings with no bespoke landmark or skyline tower row:
## supplies verified heights (fixing OSM `height=0` anomalies), materials, colours,
## and roof forms keyed by OSM identity (`way:<id>` / `relation:<id>`).
## Applied in `OsmParser` beside `HelsinkiNotable`, `TurkuNotable` and `MiamiNotable`.

const PROVENANCE := "sg_notable"

const ROWS := {
	"way:46594832": {"name": "Peninsula Plaza", "address": "111 North Bridge Road",
		"source": "docs/singapore-landmark-sources.md",
		"values": {"height": 110.0, "levels": 30, "material": "concrete", "colour": "#d8d4ca", "roof_material": "concrete", "start_year": 1980}},
	"way:612174812": {"name": "Grand Park City Hall", "address": "10 Coleman Street",
		"source": "docs/singapore-landmark-sources.md",
		"values": {"height": 38.0, "levels": 10, "material": "render", "colour": "#ebe5d8", "roof_material": "terracotta", "start_year": 1998}},
	"way:699168484": {"name": "Clarke Quay Central", "address": "6 Eu Tong Sen Street",
		"source": "docs/singapore-landmark-sources.md",
		"values": {"height": 95.0, "levels": 25, "material": "glass", "colour": "#7a98a8", "roof_material": "concrete", "start_year": 2007}},
	"way:47300926": {"name": "Great Eastern Centre", "address": "1 Pickering Street",
		"source": "docs/singapore-landmark-sources.md",
		"values": {"height": 74.0, "levels": 18, "material": "stone", "colour": "#cfc6b6", "roof_material": "concrete", "start_year": 2001}},
	"way:44414594": {"name": "Havelock II", "address": "2 Havelock Road",
		"source": "docs/singapore-landmark-sources.md",
		"values": {"height": 42.0, "levels": 10, "material": "concrete", "colour": "#dcd8d0", "roof_material": "concrete", "start_year": 1984}},
	"way:699163968": {"name": "Park Regis Singapore", "address": "23 Merchant Road",
		"source": "docs/singapore-landmark-sources.md",
		"values": {"height": 32.0, "levels": 7, "material": "glass", "colour": "#8ca0aa", "roof_material": "concrete", "start_year": 2010}},
	"way:468206082": {"name": "Furama City Centre", "address": "60 Eu Tong Sen Street",
		"source": "docs/singapore-landmark-sources.md",
		"values": {"height": 92.0, "levels": 23, "material": "concrete", "colour": "#dfd8cc", "roof_material": "concrete", "start_year": 1984}},
	"way:147102974": {"name": "The Riverside Piazza", "address": "11 Keng Cheow Street",
		"source": "docs/singapore-landmark-sources.md",
		"values": {"height": 34.0, "levels": 9, "material": "render", "colour": "#e6d8c4", "roof_material": "terracotta", "start_year": 1995}},
	"way:171999284": {"name": "The Arcade", "address": "11 Collyer Quay",
		"source": "docs/singapore-landmark-sources.md",
		"values": {"height": 84.0, "levels": 20, "material": "concrete", "colour": "#d2cec6", "roof_material": "concrete", "start_year": 1981}},
	"way:44414529": {"name": "Carlton Hotel Singapore", "address": "76 Bras Basah Road",
		"source": "docs/singapore-landmark-sources.md",
		"values": {"height": 94.0, "levels": 26, "material": "concrete", "colour": "#e6e2da", "roof_material": "concrete", "start_year": 1988}},
	"way:986973996": {"name": "OUE Tower", "address": "60 Collyer Quay",
		"source": "docs/singapore-landmark-sources.md",
		"values": {"height": 42.0, "levels": 8, "material": "glass", "colour": "#7892a0", "roof_material": "concrete", "start_year": 2011}},
	"way:742205653": {"name": "PARKROYAL COLLECTION Marina Bay", "address": "6 Raffles Boulevard",
		"source": "docs/singapore-landmark-sources.md",
		"values": {"height": 82.0, "levels": 21, "material": "concrete", "colour": "#dcd6c8", "roof_material": "concrete", "start_year": 1987}},
	"way:303311927": {"name": "Marina Square", "address": "6 Raffles Boulevard",
		"source": "docs/singapore-landmark-sources.md",
		"values": {"height": 24.0, "levels": 5, "material": "concrete", "colour": "#e2ddd4", "roof_material": "concrete", "start_year": 1987}},
	"way:47345005": {"name": "Ascott Raffles Place Singapore", "address": "2 Finlayson Green",
		"source": "docs/singapore-landmark-sources.md",
		"values": {"height": 95.0, "levels": 25, "material": "stone", "colour": "#dcd4c4", "roof_material": "concrete", "start_year": 1954}},
	"way:47298664": {"name": "Yue Hwa Building (Nam Tin)", "address": "70 Eu Tong Sen Street",
		"source": "docs/singapore-landmark-sources.md",
		"values": {"height": 28.0, "levels": 6, "material": "render", "colour": "#ece4d4", "roof_material": "concrete", "start_year": 1927}},
	"way:393090489": {"name": "Suntec Singapore Convention & Exhibition Centre", "address": "1 Raffles Boulevard",
		"source": "docs/singapore-landmark-sources.md",
		"values": {"height": 34.0, "levels": 6, "material": "glass", "colour": "#6a889c", "roof_material": "metal", "start_year": 1995}},
	"way:46594816": {"name": "Mandarin Oriental, Singapore", "address": "5 Raffles Avenue",
		"source": "docs/singapore-landmark-sources.md",
		"values": {"height": 78.0, "levels": 21, "material": "concrete", "colour": "#d8cec0", "roof_material": "concrete", "start_year": 1987}},
	"way:44414589": {"name": "People's Park Complex", "address": "1 Park Road",
		"source": "docs/singapore-landmark-sources.md",
		"values": {"height": 103.0, "levels": 31, "material": "concrete", "colour": "#d6b85a", "roof_material": "concrete", "start_year": 1973}},
	"way:1077992859": {"name": "Golden Mile Tower", "address": "6001 Beach Road",
		"source": "docs/singapore-landmark-sources.md",
		"values": {"height": 88.0, "levels": 22, "material": "concrete", "colour": "#d4cec2", "roof_material": "concrete", "start_year": 1974}},
	"relation:16125339": {"name": "People's Park Centre", "address": "101 Upper Cross Street",
		"source": "docs/singapore-landmark-sources.md",
		"values": {"height": 105.0, "levels": 30, "material": "concrete", "colour": "#d6d2c8", "roof_material": "concrete", "start_year": 1976}},
}

static func apply(buildings: Array) -> int:
	var touched := 0
	for b_var in buildings:
		if not (b_var is Dictionary):
			continue
		var b := b_var as Dictionary
		var osm_id := str(b.get("osm_id", ""))
		if not ROWS.has(osm_id):
			continue
		var row: Dictionary = ROWS[osm_id]
		var vals: Dictionary = row["values"]
		# Fix OSM `height=0` or missing height directly, then fill other missing tags.
		if vals.has("height") and float(b.get("height", 0.0)) <= 1.0:
			b["height"] = float(vals["height"])
		if vals.has("levels") and int(b.get("levels", 0)) <= 0:
			b["levels"] = int(vals["levels"])
		BuildingReferences.fill(b, vals, PROVENANCE)
		touched += 1
	return touched
