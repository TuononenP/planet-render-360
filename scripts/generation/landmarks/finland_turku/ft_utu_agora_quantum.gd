class_name FtUtuAgoraQuantum
extends RefCounted

## University of Turku — Agora, Quantum, Educarium & Publicum campus blocks
## along Vesilinnantie / Assistentinkatu, in true metres (+X ENE, +Z SSE,
## turned by registry yaw_deg = -65.9°):
##   1. Agora (OSM way:218869876, 82.7 x 26.2 m, 4–5 lv, H = 22.8 m) at (0, 0):
##      modern university IT & research hall featuring the signature soaring
##      diagonal sloped glass atrium facade on the west/south side, dark steel
##      diagrid/mullion frame, pale metal & brick academic flanks, and warm
##      illuminated atrium interior at night.
##   2. Quantum (OSM way:34024258, 126 x 34 m, 6 lv, H = 23.6 m, SEAT_META
##      child at (+48, 0, +58)): long brick-and-metal physics/math wing with
##      rhythmic horizontal laboratory window bands & rooftop domes/penthouse.
##   3. Educarium & Publicum (OSM way:34103482, H = 19.5 m, SEAT_META child
##      at (-56, 0, +42)): twin red-brick & pale-metal social sciences/education
##      courtyard wings linked by a glazed sky-atrium.
## Surfaces: 14 merged PBR parts (7 Agora + 4 Quantum + 3 Educarium/Publicum).

const FOUND := -3.0

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	var sky := SkyKit.new(lm)
	_materials(lm, sky)
	_build_agora(lm, sky)
	lm.commit(model)
	_build_quantum(model, lm)
	_build_educarium_publicum(model, lm)
	_set_night_floods(model)

static func _materials(lm: LandmarkMesh, sky: SkyKit) -> void:
	lm.use("LightMetal", LandmarkMaterials.pbr("sheet_metal", "#DFE2E4", 2.8, 0.40, 0.25))
	lm.use("DarkSteel", LandmarkMaterials.paint("#2B3138", 0.42, 0.58))
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#9E5640", 2.4))
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#C2C0B8", 3.0))
	lm.use("Glass", LandmarkMaterials.glass("#223848"))
	sky.wall("WallLit", "steel_panel", 3.6, 3.85)
	lm.use("Lamp", LandmarkMaterials.lit("#FFECC2", 1.55))

static func _build_agora(lm: LandmarkMesh, sky: SkyKit) -> void:
	# Main 5-storey Agora academic block (82 x 26 m, H = 22.8 m).
	LandmarkFrKit.rect(lm, "Concrete", -41.5, 41.5, -13.5, 13.5, FOUND, 1.4)
	LandmarkFrKit.rect(lm, "DarkSteel", -40.6, 40.6, -12.6, 8.6, 1.4, 21.8)
	LandmarkFrKit.rect(lm, "LightMetal", -41.0, 41.0, -13.0, 9.0, 21.6, 22.4)
	sky.face("WallLit", Vector2(41.0, -13.0), Vector2(-41.0, -13.0), 1.4, 21.6, Vector3.FORWARD, 22)
	sky.face("WallLit", Vector2(41.0, 9.0), Vector2(41.0, -13.0), 1.4, 21.6, Vector3.RIGHT, 6)
	sky.face("WallLit", Vector2(-41.0, -13.0), Vector2(-41.0, 9.0), 1.4, 21.6, Vector3.LEFT, 6)
	# Signature soaring diagonal sloped glass atrium facade along +Z (x = -38..+38 m).
	# Steps outward toward ground (z = 14.2 at base -> z = 9.0 at roof 22.4 m).
	var atrium_pts := PackedVector3Array([
		Vector3(-38.0, 0.0, 14.4),
		Vector3(38.0, 0.0, 14.4),
		Vector3(38.0, 22.4, 9.0),
		Vector3(-38.0, 22.4, 9.0),
	])
	LandmarkFrKit.face(lm, "Glass", [atrium_pts[0], atrium_pts[1], atrium_pts[2], atrium_pts[3]])
	# Warm illuminated atrium interior behind sloped glass.
	lm.box("Lamp", Vector3(0.0, 10.5, 10.4), Vector3(68.0, 17.0, 2.2))
	# Diagonal steel structural ribs & horizontal transoms across the sloped glass atrium.
	for i in 13:
		var t := float(i) / 12.0
		var ax := lerpf(-38.0, 38.0, t)
		lm.beam("DarkSteel", Vector3(ax, 0.0, 14.48), Vector3(ax, 22.4, 9.08), 0.24, 0.30)
		if i < 12:
			var nx := lerpf(-38.0, 38.0, float(i + 1) / 12.0)
			lm.beam("DarkSteel", Vector3(ax, 0.0, 14.48), Vector3(nx, 22.4, 9.08), 0.14, 0.16)
	for lv in range(1, 5):
		var frac := float(lv) / 5.0
		var ty := frac * 22.4
		var tz := lerpf(14.48, 9.08, frac)
		lm.beam("DarkSteel", Vector3(-38.0, ty, tz), Vector3(38.0, ty, tz), 0.20, 0.24)
	# Sloped atrium side cheeks & rooftop skylight spine reaching 22.8 m.
	for sx: float in [-1.0, 1.0]:
		LandmarkFrKit.face(lm, "Glass", [
			Vector3(sx * 38.0, 0.0, 9.0),
			Vector3(sx * 38.0, 0.0, 14.4),
			Vector3(sx * 38.0, 22.4, 9.0),
		])
	LandmarkFrKit.rect(lm, "LightMetal", -32.0, 32.0, -5.0, 4.0, 22.4, 22.8)

## Quantum (OSM way:34024258) — 6-storey brick-and-metal physics/math wing (H = 23.6 m).
static func _build_quantum(model: Node3D, base_lm: LandmarkMesh) -> void:
	var lm := LandmarkMesh.new()
	for k: String in ["Brick", "LightMetal", "DarkSteel", "Glass"]:
		lm.use(k, (base_lm._surfs[k] as LandmarkMesh.Surf).mat)
	LandmarkFrKit.rect(lm, "Brick", -62.0, 62.0, -16.5, 16.5, FOUND, 21.8)
	LandmarkFrParts.band(lm, "LightMetal", -62.0, 62.0, -16.5, 16.5, 21.1, 0.72, 0.24)
	# Continuous horizontal 6-storey lab window strips.
	for lv in 6:
		var wy := 1.4 + float(lv) * 3.35
		for sz: float in [-1.0, 1.0]:
			LandmarkFrKit.rect(lm, "Glass", -59.5, 59.5, sz * 16.5 - 0.14, sz * 16.5 + 0.14, wy, wy + 1.75)
	# Rooftop mechanical penthouse & small observatory dome reaching 23.6 m.
	LandmarkFrKit.rect(lm, "LightMetal", -34.0, 34.0, -7.0, 7.0, 21.8, 23.5)
	lm.lathe("LightMetal", Vector3(44.0, 21.8, 0.0), PackedVector2Array([Vector2(2.4, 0.0), Vector2(2.4 * 0.85, 2.4 * 0.52), Vector2(2.4 * 0.48, 2.4 * 0.86), Vector2(0.05, 2.4)]), 10)
	var child := Node3D.new()
	child.name = "Quantum"
	child.position = Vector3(52.0, 0.0, 56.0)
	child.set_meta(LandmarkTerrain.SEAT_META, true)
	model.add_child(child)
	lm.commit(child)

## Educarium & Publicum — red-brick & pale-metal academic wings linked by glass atrium.
static func _build_educarium_publicum(model: Node3D, base_lm: LandmarkMesh) -> void:
	var lm := LandmarkMesh.new()
	for k: String in ["Brick", "LightMetal", "Glass"]:
		lm.use(k, (base_lm._surfs[k] as LandmarkMesh.Surf).mat)
	# Twin parallel 5-storey brick wings (54 x 16 m each, H = 19.5 m) with central glass link.
	for sz: float in [-1.0, 1.0]:
		var zc := sz * 18.0
		LandmarkFrKit.rect(lm, "Brick", -27.0, 27.0, zc - 8.0, zc + 8.0, FOUND, 19.5)
		LandmarkFrParts.band(lm, "LightMetal", -27.0, 27.0, zc - 8.0, zc + 8.0, 18.9, 0.62, 0.20)
		for lv in 5:
			var wy := 1.5 + float(lv) * 3.45
			LandmarkFrKit.rect(lm, "Glass", -25.0, 25.0, zc + 8.0 - 0.14, zc + 8.0 + 0.14, wy, wy + 1.7)
			LandmarkFrKit.rect(lm, "Glass", -25.0, 25.0, zc - 8.0 - 0.14, zc - 8.0 + 0.14, wy, wy + 1.7)
	# Central glazed sky-atrium connecting Educarium & Publicum.
	LandmarkFrKit.rect(lm, "Glass", -16.0, 16.0, -10.0, 10.0, FOUND, 17.5)
	LandmarkFrKit.rect(lm, "LightMetal", -16.4, 16.4, -10.4, 10.4, 17.3, 17.9)
	var child := Node3D.new()
	child.name = "EducariumPublicum"
	child.position = Vector3(-56.0, 0.0, 44.0)
	child.set_meta(LandmarkTerrain.SEAT_META, true)
	model.add_child(child)
	lm.commit(child)

static func _set_night_floods(model: Node3D) -> void:
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(0.0, 2.0, 28.0), Vector3(0.0, 12.0, 12.0), 66.0, 0.90, 48.0, Color(0.94, 0.96, 1.0)],
		[Vector3(-28.0, 2.0, 26.0), Vector3(-24.0, 12.0, 12.0), 58.0, 0.65, 42.0, Color(1.0, 0.90, 0.72)],
		[Vector3(28.0, 2.0, 26.0), Vector3(24.0, 12.0, 12.0), 58.0, 0.65, 42.0, Color(1.0, 0.90, 0.72)],
	])
