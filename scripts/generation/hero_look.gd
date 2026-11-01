class_name HeroLook
extends RefCounted

## Roof finishes for mapped landmarks (LandmarkFidelity): their tags are
## read literally instead of through the street fabric's muted sets, so a
## gilded onion is gold, a copper dome weathered green and St Basil's
## domes keep their colours. Anything untagged keeps the fabric roof.

const VERDIGRIS := "#6E9C88"
const LEAD := "#8A8F94"
## Tagged roof colours keep this much saturation (the fabric mutes to
## 0.42, which greys painted domes).
const MAX_CHROMA := 0.65
## Roof UVs are world units × 0.05 (RoofGeometry.push_tri); this tile
## repeats the sheet-metal relief every 4 m.
const TILE := 0.2
const METALS: Array[String] = ["copper", "lead", "zinc", "metal", "metal_sheet", "tin", "steel"]

## The roof material for mapped landmark mass `b` (its b_eff, parent
## roof tags inherited), or `fallback` when nothing is tagged.
static func roof(b: Dictionary, fallback: Material) -> Material:
	var mat := str(b.get("roof_material", "")).strip_edges().to_lower()
	var raw := str(b.get("roof_colour", "")).strip_edges().to_lower()
	if mat in ["gold", "gilded"] or raw == "gold":
		return LandmarkMaterials.gold()
	var metal := mat in METALS
	var tag := MaterialLibrary.parse_colour_tag(raw)
	if tag.a > 0.0:
		var c := Color.from_hsv(tag.h, minf(tag.s, MAX_CHROMA), tag.v)
		return LandmarkMaterials.pbr("concrete", "#" + c.to_html(false), TILE,
			0.5 if metal else 0.7, 0.35 if metal else 0.0)
	if mat == "copper":
		return LandmarkMaterials.pbr("concrete", VERDIGRIS, TILE, 0.55, 0.3)
	if mat in ["lead", "zinc"]:
		return LandmarkMaterials.pbr("concrete", LEAD, TILE, 0.5, 0.45)
	return fallback
