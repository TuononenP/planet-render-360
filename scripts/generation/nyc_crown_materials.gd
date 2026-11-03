class_name NycCrownMaterials
extends RefCounted

## 70 Pine's mapped top contains a stack of one-metre parts from 256 to
## 264 m below its 26 m spire. The source describes the glass-enclosed
## observatory; the elevations are from those existing OSM parts.
## https://old.skyscraper.org/EXHIBITIONS/FAVORITES/fav_70pine.htm
static func apply(parent: Dictionary, part: Dictionary, effective: Dictionary) -> void:
	if str(parent.get("osm_id", "")) != "way:278069587" \
			or str(part.get("material", "")).strip_edges() != "" \
			or str(parent.get("material", "")).strip_edges() != "":
		return
	var bottom := float(part.get("min_height_m", 0.0))
	var top := float(part.get("height", 0.0))
	if bottom >= 256.0 and top <= 264.0 and top > bottom:
		effective["material"] = "glass"

## The mapped Municipal Building part from 176.79 to 182.79 m represents
## Civic Fame. Render a figure inside that envelope, leaving the dome and
## other mapped parts intact. The city describes the gilded statue:
## https://a856-centre360.nyc.gov/
static func is_civic_fame(parent: Dictionary, mass: Dictionary) -> bool:
	return str(parent.get("osm_id", "")) == "relation:13625437" \
		and absf(float(mass.get("min_m", 0.0)) - 176.79) < 0.1 \
		and absf(float(mass.get("wall_m", 0.0)) - 182.79) < 0.1

static func civic_fame(root: Node3D, centre: Vector2, base_y: float) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Gilt", LandmarkMaterials.paint("#C49A3D", 0.48, 0.7))
	lm.frustum("Gilt", Vector3(0, 0.0, 0), 0.65, 0.32, 3.0, 8)
	lm.box("Gilt", Vector3(0, 3.45, 0), Vector3(0.75, 1.25, 0.55))
	lm.frustum("Gilt", Vector3(0, 4.1, 0), 0.28, 0.24, 0.64, 8)
	lm.beam("Gilt", Vector3(-0.35, 3.9, 0), Vector3(-0.9, 5.25, 0), 0.19)
	lm.beam("Gilt", Vector3(-0.9, 5.25, 0), Vector3(-0.5, 5.7, 0), 0.16)
	lm.beam("Gilt", Vector3(0.35, 3.9, 0), Vector3(0.9, 3.0, 0), 0.19)
	lm.frustum("Gilt", Vector3(-0.5, 5.7, 0), 0.28, 0.34, 0.3, 8)
	for part in lm.commit(root, "CivicFame_"):
		part.position = Vector3(centre.x, base_y, centre.y)
		part.set_meta("nyc_civic_fame", true)
