class_name LandmarkArchetypes
extends RefCounted

## On-the-fly models for any OSM-tagged notable feature (church,
## cathedral, castle, lighthouse, stadium, mosque, temple, windmill,
## tower, big_wheel) in true metres at the feature's real height and footprint,
## with the same calibrated photographic PBR sets as buildings (T4.3)
## and the regional religious look (ArchitectureStyle.religious_look:
## wall set + stone/roof colour + tower style spire | bell | onion |
## minaret | pagoda | shikhara). Merged per material (LandmarkMesh).
## The models live in LandmarkCoreBArchChurch (church, cathedral),
## LandmarkCoreBArchSecular (castle, lighthouse, stadium, windmill,
## tower) and LandmarkCoreBArchTemple (mosque, temple) on the parts in
## LandmarkCoreBArchKit; the wheel in LandmarkWheel.

## `size` = footprint in metres (x, z); the model's long side runs
## along local Z and the node turns when the footprint is wider in X.
static func build(model: Node3D, archetype: String, h: float, size: Vector2,
		region: String = "") -> void:
	var look := _look(region)
	var lm := LandmarkMesh.new()
	lm.use("Walls", LandmarkMaterials.pbr(str(look["set"]), str(look["wall"]), 3.0))
	lm.use("Roof", LandmarkMaterials.pbr(str(look["roof_set"]), str(look["roof"]), 2.0))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#D8CFBE", 3.0))
	lm.use("Windows", LandmarkMaterials.glass("#22292D"))
	lm.use("Gilt", LandmarkMaterials.gold())
	var w := minf(size.x, size.y)
	var l := maxf(size.x, size.y)
	match archetype:
		"church": LandmarkCoreBArchChurch.build(lm, h, w, l, false, str(look["tower"]))
		"cathedral": LandmarkCoreBArchChurch.build(lm, h, w, l, true, str(look["tower"]))
		"castle": LandmarkCoreBArchSecular.castle(lm, h, w, l)
		"lighthouse": LandmarkCoreBArchSecular.lighthouse(lm, h, w, l)
		"stadium": LandmarkCoreBArchSecular.stadium(lm, h, w, l)
		"mosque": LandmarkCoreBArchTemple.mosque(lm, h, w, l)
		"temple": LandmarkCoreBArchTemple.temple(lm, h, w, l, str(look["tower"]))
		"windmill": LandmarkCoreBArchSecular.windmill(lm, h, w)
		"column": LandmarkMonuments.column(lm, h)
		"obelisk": LandmarkMonuments.obelisk(lm, h)
		"big_wheel": LandmarkWheel.build(lm, h, l)
		_: LandmarkCoreBArchSecular.tower(lm, h, w)
	lm.commit(model)
	if size.x > size.y:
		model.rotation.y = PI * 0.5

## Regional wall set/colours (sRGB hex) and tower style; neutral
## limestone + slate spire when no region is known.
static func _look(region: String) -> Dictionary:
	var out := {"set": "limestone", "wall": "#BFB4A2", "roof_set": "slate",
		"roof": "#4A535C", "tower": "spire"}
	if region == "":
		return out
	var look := ArchitectureStyle.religious_look(region)
	var p := ArchitectureStyle.profile(region, "religious")
	var walls: Array = p.get("w", [])
	if not walls.is_empty() and MaterialLibrary.PBR_SETS.has(str((walls[0] as Array)[0])):
		out["set"] = str((walls[0] as Array)[0])
		if out["set"] == "stone":
			out["set"] = "limestone"  # dressed ashlar; the sandstone set is too saturated to tint
	var roofs: Array = p.get("rf", [])
	if not roofs.is_empty() and MaterialLibrary.PBR_SETS.has(str((roofs[0] as Array)[0])):
		out["roof_set"] = str((roofs[0] as Array)[0])
	var stone: Color = look.get("stone", Color(0, 0, 0, 0))
	var roof: Color = look.get("roof", Color(0, 0, 0, 0))
	if stone.a > 0.0:
		out["wall"] = "#" + stone.linear_to_srgb().to_html(false)
	if roof.a > 0.0:
		out["roof"] = "#" + roof.linear_to_srgb().to_html(false)
	out["tower"] = str(look.get("tower", "spire"))
	return out
