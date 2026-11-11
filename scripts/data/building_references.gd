class_name BuildingReferences
extends RefCounted

## Source-backed defaults for individual mapped buildings. Match stable OSM
## identities, retain the real footprint and never replace mapped dimensions
## or a building:part model. Raw OSM cache payloads remain unchanged.
const ROWS := {
	"way:23192814": {
		"source": "https://www.senaatti.fi/app/uploads/2017/05/3168-2013_Mustonen_Hki_Rahapaja_Kunnostusraportti_web.pdf",
		# Old Mint: printed pp. 14–15, 1:200 elevations on the A3 spread.
		# Main ridge ≈11.5 m above the low facade base; roof rise ≈2.5 m.
		# Rounded drawing measurements, not surveyed or OSM-tagged heights.
		"height_method": "scaled_elevation", "height_uncertainty_m": 1.0,
		"height_m": 11.5, "levels": 2.0,
		"values": {"start_year": 1863, "roof_shape": "gabled",
			"roof_height_m": 2.5, "roof_material": "metal", "roof_colour": "#484c48"},
	},
}

static func apply(buildings: Array) -> void:
	for b in buildings:
		if not (b is Dictionary):
			continue
		var row: Dictionary = {}
		for id in OsmParser.ids_of(b):
			row = ROWS.get(id, {})
			if not row.is_empty():
				break
		if row.is_empty() or not (b.get("parts", []) as Array).is_empty():
			continue
		var fields: Array = []
		var source := str(b.get("height_source", ""))
		if source in ["default", "estimate"] and float(b.get("levels", 0.0)) <= 0.0:
			b["height"] = float(row["height_m"])
			b["height_source"] = "reference"
			b["levels"] = float(row["levels"])
			fields.append_array(["height", "levels"])
		for key in row["values"]:
			var value: Variant = row["values"][key]
			var missing := str(b.get(key, "")) == "" if value is String else float(b.get(key, 0)) <= 0.0
			if missing:
				b[key] = value
				fields.append(key)
		if not fields.is_empty():
			b["reference"] = {"source": row["source"], "fields": fields,
				"height_method": row["height_method"], "height_uncertainty_m": row["height_uncertainty_m"]}
