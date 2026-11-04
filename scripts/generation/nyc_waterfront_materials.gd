class_name NycWaterfrontMaterials
extends RefCounted

## Whitehall's steel-and-glass terminal, reopened in 2005. Only supply
## missing finishes; its hall and slip roofs keep the mapped part geometry.
## https://www.nyc.gov/html/dot/html/ferrybus/sif-traveler-info.shtml
static func apply(parent: Dictionary, part: Dictionary, effective: Dictionary) -> void:
	if str(parent.get("osm_id", "")) != "way:38868195" \
			or str(parent.get("material", "")).strip_edges() != "" \
			or str(part.get("material", "")).strip_edges() != "":
		return
	# The mapped 23 m entry hall corresponds to DOT's 75 ft glass hall.
	if str(part.get("osm_id", "")) == "way:213853440":
		effective["material"] = "glass"
	else:
		effective["material"] = "metal"
		if str(effective.get("colour", "")) == "":
			effective["colour"] = "#BBC2C3"
	if str(effective.get("roof_material", "")) == "":
		effective["roof_material"] = "metal"
