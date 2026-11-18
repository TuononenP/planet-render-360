class_name HeroLook
extends RefCounted

## Roof finishes for mapped landmarks (LandmarkFidelity): their tags are
## read literally instead of through the street fabric's muted sets, so a
## gilded onion is gold, a copper dome weathered green and St Basil's
## domes keep their colours — using real slate, standing-seam metal and
## terracotta PBR sets instead of smooth concrete. Anything untagged keeps
## the fabric roof.

const VERDIGRIS := "#6E9C88"
const LEAD := "#727A82"
## Tagged roof colours keep this much saturation (the fabric mutes to
## 0.42, which greys painted domes).
const MAX_CHROMA := 0.65
## Roof UVs are world units × 0.05 (20 m per UV unit). LandmarkMaterials.pbr
## sets uv1_scale = 1 / tile_m, so tile_m = 1 / MaterialLibrary.ROOF_UV[set].
const TILE_SLATE := 0.125       # 1 / 8.0 → 2.5 m slate sheet
const TILE_METAL := 0.18        # 3.6 / 20.0 → 3.6 m standing-seam repeat (6 pans)
const TILE_TILE := 0.227        # 1 / 4.4 → 4.5 m terracotta courses
const METALS: Array[String] = ["copper", "lead", "zinc", "metal", "metal_sheet", "tin", "steel"]
const TILES: Array[String] = ["tile", "tiles", "terracotta", "roof_tiles", "clay", "clay_tile"]

## The roof material for mapped landmark mass `b` (its b_eff, parent
## roof tags inherited), or `fallback` when nothing is tagged.
static func roof(b: Dictionary, fallback: Material) -> Material:
	var mat := str(b.get("roof_material", "")).strip_edges().to_lower()
	var raw := str(b.get("roof_colour", "")).strip_edges().to_lower()
	if mat in ["gold", "gilded"] or raw == "gold":
		return LandmarkMaterials.gold()
	if mat == "glass":
		return fallback
	var metal := mat in METALS
	var tag := MaterialLibrary.parse_colour_tag(raw)
	if tag.a > 0.0:
		var c := Color.from_hsv(tag.h, minf(tag.s, MAX_CHROMA), tag.v)
		var set_name := "sheet_metal" if metal else ("terracotta" if mat in TILES else "slate")
		var tile := TILE_METAL if metal else (TILE_TILE if set_name == "terracotta" else TILE_SLATE)
		var m := LandmarkMaterials.pbr(set_name, "#" + c.to_html(false), tile,
			-1.0, 0.20 if metal else 0.0)
		m.metallic_specular = 0.32 if metal else 0.20
		m.set_meta("roof", true)
		return m
	if mat == "copper":
		# Neutral-grey sheet_metal calibrated to verdigris keeps standing seams
		# and a green tint (g > r) on the material's albedo_color.
		var m := LandmarkMaterials.pbr("sheet_metal", VERDIGRIS, TILE_METAL, -1.0, 0.22)
		m.metallic_specular = 0.32
		m.set_meta("roof", true)
		return m
	if mat in ["lead", "zinc"]:
		var m := LandmarkMaterials.pbr("sheet_metal", LEAD, TILE_METAL, -1.0, 0.20)
		m.metallic_specular = 0.32
		m.set_meta("roof", true)
		return m
	return fallback
