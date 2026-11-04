class_name NycCrownMaterials
extends RefCounted

## 70 Pine's mapped top contains a stack of one-metre parts from 256 to
## 264 m below its 26 m spire. The source describes the glass-enclosed
## observatory; the elevations are from those existing OSM parts.
## https://old.skyscraper.org/EXHIBITIONS/FAVORITES/fav_70pine.htm
static func apply(parent: Dictionary, part: Dictionary, effective: Dictionary) -> void:
	if str(part.get("material", "")).strip_edges() != "" \
			or str(parent.get("material", "")).strip_edges() != "":
		return
	var id := str(parent.get("osm_id", ""))
	# Glazed architectural terra cotta is pale cladding, not red brick.
	# https://old.skyscraper.org/EXHIBITIONS/WOOLWORTH/case2_atc.php
	if id == "way:75363809":
		effective["material"] = "glazed_terracotta"
		return
	if id != "way:278069587":
		return
	var bottom := float(part.get("min_height_m", 0.0))
	var top := float(part.get("height", 0.0))
	if bottom >= 256.0 and top <= 264.0 and top > bottom:
		effective["material"] = "glass"
	elif bottom >= 242.0 and top <= 256.0 and top > bottom:
		# The limestone pinnacle beneath the observatory: LPC LP-2441.
		# https://s-media.nyc.gov/agencies/lpc/lp/2441.pdf
		effective["material"] = "limestone"

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

## Ornament follows the existing crown rings and elevations, never a
## replacement tower. Woolworth's four turrets and main copper pyramid
## are already mapped; fine hips and Gothic corner shafts articulate them.
## https://old.skyscraper.org/EXHIBITIONS/WOOLWORTH/case2_atc.php
static func crown_details(root: Node3D, parent: Dictionary, mass: Dictionary, floor_y: float) -> void:
	var id := str(parent.get("osm_id", ""))
	if id not in ["way:75363809", "way:278042253", "way:278069587"]:
		return
	var ring: PackedVector2Array = mass["ring"]
	var bottom := float(mass["min_m"])
	var wall := float(mass["wall_m"])
	var roof := float(mass["rh_m"])
	var lantern := id == "way:278069587" and bottom >= 256.0 and wall <= 264.0
	var pyramid := str(mass["shape"]) == "pyramidal" and roof > 3.0 \
		and id in ["way:75363809", "way:278042253"] and wall > 190.0
	if not lantern and not pyramid:
		return
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.paint("#DCD5C5", 0.75))
	lm.use("Metal", LandmarkMaterials.paint("#709184", 0.55, 0.6))
	var centre: Vector2 = mass["centre"]
	for i in ring.size():
		var p := ring[i]
		var q := ring[(i + 1) % ring.size()]
		if lantern:
			lm.beam("Stone", Vector3(p.x, floor_y + bottom + 0.1, p.y),
				Vector3(p.x, floor_y + wall - 0.1, p.y), 0.16, 0.16)
			lm.beam("Stone", Vector3(p.x, floor_y + wall - 0.1, p.y),
				Vector3(q.x, floor_y + wall - 0.1, q.y), 0.16, 0.16)
		else:
			var inset := p.lerp(centre, 0.02)
			lm.beam("Metal", Vector3(inset.x, floor_y + wall + roof * 0.02, inset.y),
				Vector3(centre.x, floor_y + wall + roof - 0.15, centre.y), 0.2, 0.2)
			if id == "way:75363809":
				var out := (p - centre).normalized() * 0.12
				lm.beam("Stone", Vector3(p.x + out.x, floor_y + maxf(bottom, wall - 12.0), p.y + out.y),
					Vector3(p.x + out.x, floor_y + wall - 0.15, p.y + out.y), 0.3, 0.3)
	for part in lm.commit(root, "NycCrown_"):
		part.set_meta("nyc_crown_detail", id)
