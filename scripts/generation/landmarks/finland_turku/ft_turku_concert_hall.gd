class_name FtTurkuConcertHall
extends RefCounted

## Turku Concert Hall (Turun konserttitalo, 1952, Risto-Veikko Luukkonen) &
## Aninkaisten koulutalo (Vocational Institute) on Aninkaistenmäki, in true
## metres (+X NE along Aninkaistenkatu, +Z SE toward Puutori, turned by
## registry yaw_deg = -35.2°):
##   1. Turku Concert Hall (OSM way:96558882, 58.2 x 55.6 m, turku_lod2
##      1032867388 H = 23.1 m, gabled 16°) at (0, 0): iconic Finnish postwar
##      functionalist music hall — white/cream rendered trapezoidal auditorium
##      wedge raised over a full-height recessed glazed foyer, signature
##      rhythmic vertical relief ribs along the auditorium upper walls,
##      cantilevered entrance canopy with granite terrace stairs toward
##      Aninkaistenkatu (-X), and low-pitched copper/metal gabled roof.
##   2. Aninkaisten koulutalo (OSM way:96558877, SEAT_META child at (+48, 0,
##      +18)): Luukkonen's paired white modernist courtyard school wings
##      (5-storey main classroom slab H = 19.2 m + 2-storey workshop wings
##      H = 9.4 m enclosing the school courtyard).
## Surfaces: 12 merged PBR parts (8 Concert Hall + 4 Aninkaisten koulutalo).

const FOUND := -2.8

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	_materials(lm)
	_build_concert_hall(lm)
	lm.commit(model)
	_build_aninkaisten_school(model, lm)
	_set_night_floods(model)

static func _materials(lm: LandmarkMesh) -> void:
	lm.use("CreamWall", LandmarkMaterials.pbr("render", "#EFECE2", 3.0))
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#7E7A72", 2.5))
	lm.use("Copper", LandmarkFrKit.copper("#4E7866"))
	lm.use("DarkMetal", LandmarkMaterials.paint("#2A2F35", 0.45, 0.55))
	lm.use("Timber", LandmarkMaterials.pbr("wood", "#B8844C", 2.0, 0.62))
	lm.use("Glass", LandmarkMaterials.glass("#22323E"))
	lm.use("Lamp", LandmarkMaterials.lit("#FFE8BA", 1.55))

static func _build_concert_hall(lm: LandmarkMesh) -> void:
	# Stepped granite hill podium & Aninkaistenkatu entrance terrace (-X front).
	LandmarkFrKit.rect(lm, "Granite", -30.0, 29.0, -28.0, 28.0, FOUND, 1.2)
	LandmarkFrKit.rect(lm, "Granite", -33.5, -30.0, -18.0, 18.0, FOUND, 0.65)
	# Tall recessed glazed concert foyer wrapping the -X front & flanks (y = 1.2..8.6 m).
	LandmarkFrKit.rect(lm, "Glass", -27.5, -8.0, -23.0, 23.0, 1.2, 8.6)
	# Warm wooden foyer acoustic ceiling & golden evening lobby glow.
	LandmarkFrKit.rect(lm, "Timber", -28.2, -8.0, -23.6, 23.6, 8.2, 8.7)
	lm.box("Lamp", Vector3(-18.0, 4.8, 0.0), Vector3(16.0, 5.2, 38.0))
	# Slender dark-metal foyer mullions & round white modernist foyer columns.
	for i in 11:
		var mz := lerpf(-22.5, 22.5, float(i) / 10.0)
		lm.box("DarkMetal", Vector3(-27.6, 4.9, mz), Vector3(0.22, 7.4, 0.22))
		if i % 2 == 0:
			lm.frustum("CreamWall", Vector3(-25.8, 1.2, mz), 0.32, 0.32, 7.2, 10)
	# Cantilevered flat entrance canopy projecting toward Aninkaistenkatu (-X).
	LandmarkFrKit.rect(lm, "CreamWall", -32.2, -27.2, -16.5, 16.5, 4.6, 5.15)
	lm.box("Lamp", Vector3(-29.8, 4.52, 0.0), Vector3(0.55, 0.10, 29.0))
	# Raised white/cream rendered auditorium wedge overhanging the glazed foyer!
	# Front auditorium mass (-28..+24, -22..+22, y = 8.6..18.6 m) + taller rear stage house.
	LandmarkFrKit.rect(lm, "CreamWall", -28.2, 16.0, -21.5, 21.5, 8.6, 18.4)
	LandmarkFrKit.rect(lm, "CreamWall", 14.0, 28.5, -24.5, 24.5, 1.2, 20.6)
	# Signature Luukkonen rhythmic vertical relief ribs on all upper auditorium facades!
	for i in 19:
		var rz := lerpf(-20.4, 20.4, float(i) / 18.0)
		lm.box("CreamWall", Vector3(-28.45, 13.5, rz), Vector3(0.45, 9.6, 0.42))
	for i in 17:
		var rx := lerpf(-26.8, 14.8, float(i) / 16.0)
		lm.box("CreamWall", Vector3(rx, 13.5, -21.75), Vector3(0.42, 9.6, 0.45))
		lm.box("CreamWall", Vector3(rx, 13.5, 21.75), Vector3(0.42, 9.6, 0.45))
	# Crisp overhanging cornice & low-pitched 16° copper gabled roof (18.4 -> 23.1 m).
	LandmarkFrParts.band(lm, "CreamWall", -28.2, 16.0, -21.5, 21.5, 18.0, 0.48, 0.45)
	LandmarkFrKit.gable(lm, "Copper", -28.2, 28.5, -21.5, 21.5, 18.4, 4.7, 0.55, "CreamWall", 1)
	# Flanking low office & dressing-room wings along -Z and +Z.
	for sz: float in [-1.0, 1.0]:
		LandmarkFrKit.rect(lm, "CreamWall", -10.0, 26.0, sz * 21.5, sz * 27.5, 1.2, 9.6)
		LandmarkFrKit.rect(lm, "Glass", -8.0, 24.0, sz * 27.4 - 0.14, sz * 27.4 + 0.14, 2.8, 5.2)
		LandmarkFrKit.rect(lm, "Glass", -8.0, 24.0, sz * 27.4 - 0.14, sz * 27.4 + 0.14, 6.4, 8.4)

## Aninkaisten koulutalo (1952 Vocational Institute) — white modernist courtyard school wings.
static func _build_aninkaisten_school(model: Node3D, base_lm: LandmarkMesh) -> void:
	var lm := LandmarkMesh.new()
	for k: String in ["CreamWall", "Copper", "DarkMetal", "Glass"]:
		lm.use(k, (base_lm._surfs[k] as LandmarkMesh.Surf).mat)
	# 5-storey white modernist classroom slab along the north-east spine (72 x 16 m, H = 19.2 m).
	LandmarkFrKit.rect(lm, "CreamWall", -36.0, 36.0, -28.0, -12.0, FOUND, 18.2)
	LandmarkFrKit.gable(lm, "Copper", -36.0, 36.0, -28.0, -12.0, 18.2, 1.8, 0.40, "CreamWall", 1)
	for lv in 5:
		var wy := 1.6 + float(lv) * 3.25
		for sz: float in [-1.0, 1.0]:
			var zf := -20.0 + sz * 8.0
			LandmarkFrKit.rect(lm, "Glass", -34.0, 34.0, zf - 0.14, zf + 0.14, wy, wy + 1.7)
	# Two 2-storey white courtyard workshop wings framing the school yard (+Z and +X).
	LandmarkFrKit.rect(lm, "CreamWall", -36.0, 36.0, 18.0, 32.0, FOUND, 9.4)
	LandmarkFrKit.rect(lm, "CreamWall", 20.0, 36.0, -12.0, 18.0, FOUND, 10.6)
	for lv in 2:
		var wy := 1.8 + float(lv) * 3.5
		LandmarkFrKit.rect(lm, "Glass", -33.5, 33.5, 31.86, 32.14, wy, wy + 1.8)
		LandmarkFrKit.rect(lm, "Glass", 35.86, 36.14, -10.0, 16.0, wy, wy + 1.8)
	var child := Node3D.new()
	child.name = "AninkaistenKoulutalo"
	child.position = Vector3(58.0, 0.0, 16.0)
	child.set_meta(LandmarkTerrain.SEAT_META, true)
	model.add_child(child)
	lm.commit(child)

static func _set_night_floods(model: Node3D) -> void:
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-42.0, 2.5, 0.0), Vector3(-28.0, 13.0, 0.0), 62.0, 0.95, 48.0, Color(1.0, 0.90, 0.72)],
		[Vector3(-34.0, 2.5, -26.0), Vector3(-24.0, 13.0, -18.0), 54.0, 0.70, 40.0, Color(1.0, 0.90, 0.72)],
		[Vector3(-34.0, 2.5, 26.0), Vector3(-24.0, 13.0, 18.0), 54.0, 0.70, 40.0, Color(1.0, 0.90, 0.72)],
	])
