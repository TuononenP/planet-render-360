class_name RoadReferences
extends RefCounted

## Source-backed widths for individual mapped ways that OSM leaves
## untagged. Match stable OSM identities, never override a tagged width,
## and leave raw OSM cache payloads unchanged (as BuildingReferences).
const ROWS := {
	"way:1209111146": {
		"source": "https://economist.co.kr/article/view/ecn202207170038",
		# Gwanghwamun's crossing between the square and the restored Woldae
		# (2023): the band spans the terrace's 30 m front (reference photo
		# refs/seoul/01); the city's plan gives the Woldae as 50 x 30 m.
		"width_method": "terrace_width", "width_uncertainty_m": 5.0, "width_m": 30.0,
	},
}

static func apply(roads: Array) -> void:
	for r in roads:
		if not (r is Dictionary) or bool(r.get("width_tagged", false)):
			continue
		var row: Dictionary = ROWS.get(str(r.get("osm_id", "")), {})
		if row.is_empty():
			continue
		r["width_m"] = float(row["width_m"])
		r["width_tagged"] = true
		r["reference"] = {"source": row["source"], "fields": ["width_m"], "width_method": row["width_method"],
			"width_uncertainty_m": row["width_uncertainty_m"]}
