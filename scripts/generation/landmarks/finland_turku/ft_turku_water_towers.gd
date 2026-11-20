class_name FtTurkuWaterTowers
extends RefCounted

## Turku Hilltop Water Towers (skyline: true):
##   1. build(model): Luolavuori Water Tower (Luolavuoren vesitorni, 1957-58)
##      crowning Luolavuori ridge (60.427200, 22.283600, height_m = 30.0):
##      - Iconic mid-century Finnish flared mushroom/conical concrete water
##        reservoir (28 m diameter top tank) perched on a slender fluted
##        cylindrical concrete pedestal shaft with vertical stair window slit.
##      - Ribbed vertical concrete pilasters wrapping the flared tank drum,
##        overhanging ring cornice, rooftop antenna mast, warm base floodlights,
##        and red aviation warning beacon (HALO_META).
##   2. build_iso_heikkila(model): Iso-Heikkilä / Juhannuskukkula Water Tower
##      (Juhannuskukkulan vesilinna, OSM way:770661224, 60.459139, 22.256609,
##      LoD2 height = 29.4 m, yaw_deg = -89.2°):
##      - Monumental hilltop cylindrical/rectangular modernist water tower &
##        attached pump-station/school wing on Juhannuskukkula overlooking
##        Central Station and Iso-Heikkilä, with vertical precast concrete
##        ribs, pale rendered reservoir drum, and warm night floodlights.
## Surfaces: 7 merged PBR parts (Concrete, ConcreteLight, Stone, Roof, Metal,
## Glass, Beacon).

const FOUND := -2.8
const LUOLAVUORI_H := 30.0
const ISO_HEIKKILA_H := 29.4

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	_materials(lm)
	_build_luolavuori(lm)
	lm.commit(model)
	_set_luolavuori_lights(model)

static func build_iso_heikkila(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	_materials(lm)
	_build_iso_heikkila(lm)
	lm.commit(model)
	_set_iso_heikkila_lights(model)

static func _materials(lm: LandmarkMesh) -> void:
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#B8B5AE", 3.0))
	lm.use("ConcreteLight", LandmarkMaterials.pbr("render", "#E2DFD7", 2.8))
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#797671", 2.5))
	lm.use("Roof", LandmarkMaterials.pbr("concrete", "#4C5156", 2.5))
	lm.use("Metal", LandmarkMaterials.paint("#3E454C", 0.42, 0.58))
	lm.use("Glass", LandmarkMaterials.glass("#223440"))
	lm.use("Beacon", LandmarkMaterials.lit("#FF281A", 2.2))

static func _build_luolavuori(lm: LandmarkMesh) -> void:
	# Circular granite & concrete hilltop foundation terrace.
	lm.frustum("Stone", Vector3(0.0, FOUND, 0.0), 10.5, 9.6, 1.4 - FOUND, 28)
	# Fluted cylindrical concrete pedestal shaft (r = 5.4 m, y = 1.4..14.8 m).
	lm.frustum("Concrete", Vector3(0.0, 1.4, 0.0), 5.4, 5.0, 13.4, 28)
	# Vertical entrance & stair window slit on the shaft.
	LandmarkFrKit.rect(lm, "Glass", -1.1, 1.1, 4.9, 5.55, 1.8, 13.5)
	LandmarkFrKit.rect(lm, "Metal", -1.3, 1.3, 4.9, 5.62, 1.4, 1.8)
	# Iconic flared mushroom concrete water tank bowl (lathe from r=5.0 at y=14.8 to r=14.2 at y=22.4).
	lm.lathe("ConcreteLight", Vector3(0.0, 14.8, 0.0), PackedVector2Array([
		Vector2(5.0, 0.0),
		Vector2(8.8, 2.2),
		Vector2(12.6, 4.8),
		Vector2(14.0, 7.6),
		Vector2(14.2, 12.2),
		Vector2(14.6, 12.6),
		Vector2(14.6, 13.1),
		Vector2(13.6, 13.1),
		Vector2(13.4, 12.6),
	]), 32)
	# Vertical structural concrete ribs wrapping the outer mushroom tank drum.
	for k in 24:
		var a := TAU * float(k) / 24.0
		var c := cos(a)
		var s := sin(a)
		lm.beam("Concrete", Vector3(c * 5.2, 14.8, s * 5.2), Vector3(c * 14.1, 22.4, s * 14.1), 0.34, 0.42)
		lm.beam("Concrete", Vector3(c * 14.15, 22.4, s * 14.15), Vector3(c * 14.25, 27.6, s * 14.25), 0.32, 0.38)
	# Conical concrete roof cap & central access penthouse rising to 30.0 m.
	lm.frustum("Roof", Vector3(0.0, 27.9, 0.0), 13.6, 3.6, 1.35, 32)
	lm.frustum("Concrete", Vector3(0.0, 29.0, 0.0), 3.2, 3.2, 0.95, 16)
	# Perimeter rooftop handrail & red aviation beacon at 30.0 m.
	for k in 18:
		var a := TAU * float(k) / 18.0
		var a2 := TAU * float((k + 1) % 18) / 18.0
		var p1 := Vector3(cos(a) * 13.9, 27.9, sin(a) * 13.9)
		var p2 := Vector3(cos(a2) * 13.9, 27.9, sin(a2) * 13.9)
		lm.beam("Metal", p1, p1 + Vector3(0, 1.05, 0), 0.08, 0.08)
		lm.beam("Metal", p1 + Vector3(0, 1.0, 0), p2 + Vector3(0, 1.0, 0), 0.07, 0.07)
	lm.box("Beacon", Vector3(0.0, LUOLAVUORI_H, 0.0), Vector3(0.45, 0.45, 0.45))

static func _build_iso_heikkila(lm: LandmarkMesh) -> void:
	# Juhannuskukkula / Iso-Heikkilä hilltop water tower & attached brick/concrete base wing.
	LandmarkFrKit.rect(lm, "Stone", -18.0, 18.0, -14.0, 14.0, FOUND, 1.6)
	# Attached lower technical/hall wing on -X flank.
	LandmarkFrKit.rect(lm, "Concrete", -17.0, 2.0, -11.5, 11.5, 1.6, 11.2)
	LandmarkFrKit.rect(lm, "Roof", -16.6, 1.6, -11.1, 11.1, 11.2, 11.6)
	for fl in 2:
		var fy := 3.4 + float(fl) * 3.6
		LandmarkFrKit.rect(lm, "Glass", -15.5, -1.5, 11.46, 11.62, fy, fy + 1.8)
		LandmarkFrKit.rect(lm, "Glass", -15.5, -1.5, -11.62, -11.46, fy, fy + 1.8)
	# Tall ribbed cylindrical concrete water reservoir drum on +X crest (cx = 6.5, R = 11.2 m, H = 29.4 m).
	var cx := 6.5
	lm.frustum("Concrete", Vector3(cx, FOUND, 0.0), 10.6, 10.6, 14.0 - FOUND, 28)
	lm.frustum("ConcreteLight", Vector3(cx, 14.0, 0.0), 11.4, 11.4, 13.8, 28)
	lm.frustum("Roof", Vector3(cx, 27.8, 0.0), 11.1, 9.6, 1.2, 28)
	lm.frustum("Concrete", Vector3(cx, 28.6, 0.0), 2.8, 2.8, 0.8, 16)
	# Rhythmic vertical concrete structural ribs around the reservoir cylinder & base drum.
	for k in 24:
		var a := TAU * float(k) / 24.0
		var rx := cx + cos(a) * 11.5
		var rz := sin(a) * 11.5
		lm.beam("Concrete", Vector3(rx, 13.8, rz), Vector3(rx, 27.8, rz), 0.34, 0.42)
		var bx := cx + cos(a) * 10.68
		var bz := sin(a) * 10.68
		lm.beam("ConcreteLight", Vector3(bx, 1.6, bz), Vector3(bx, 14.0, bz), 0.24, 0.28)
	# Perimeter rooftop handrail ring around the reservoir parapet.
	for k in 20:
		var a := TAU * float(k) / 20.0
		var a2 := TAU * float((k + 1) % 20) / 20.0
		var p1 := Vector3(cx + cos(a) * 11.0, 27.8, sin(a) * 11.0)
		var p2 := Vector3(cx + cos(a2) * 11.0, 27.8, sin(a2) * 11.0)
		lm.beam("Metal", p1, p1 + Vector3(0, 1.05, 0), 0.08, 0.08)
		lm.beam("Metal", p1 + Vector3(0, 1.0, 0), p2 + Vector3(0, 1.0, 0), 0.07, 0.07)
	# Wing window mullions & entrance canopy on south (+Z) face.
	for k in 8:
		var mx := lerpf(-15.2, -1.8, float(k) / 7.0)
		lm.box("Metal", Vector3(mx, 4.3, 11.62), Vector3(0.14, 1.85, 0.18))
		lm.box("Metal", Vector3(mx, 7.9, 11.62), Vector3(0.14, 1.85, 0.18))
	LandmarkFrKit.rect(lm, "ConcreteLight", -11.5, -5.5, 11.5, 14.2, 3.6, 4.1)
	lm.box("Beacon", Vector3(cx, ISO_HEIKKILA_H, 0.0), Vector3(0.42, 0.42, 0.42))

static func _set_luolavuori_lights(model: Node3D) -> void:
	model.set_meta(LandmarkLights.HALO_META, [
		[Vector3(0.0, LUOLAVUORI_H + 0.15, 0.0), 2.4, Color(1.0, 0.14, 0.08)],
	])
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(16.0, 2.0, 12.0), Vector3(0.0, 20.0, 0.0), 56.0, 0.80, 40.0, Color(0.95, 0.93, 0.88)],
		[Vector3(-16.0, 2.0, -12.0), Vector3(0.0, 20.0, 0.0), 56.0, 0.80, 40.0, Color(0.95, 0.93, 0.88)],
	])

static func _set_iso_heikkila_lights(model: Node3D) -> void:
	model.set_meta(LandmarkLights.HALO_META, [
		[Vector3(6.5, ISO_HEIKKILA_H + 0.15, 0.0), 2.2, Color(1.0, 0.14, 0.08)],
	])
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(20.0, 2.0, 14.0), Vector3(6.5, 20.0, 0.0), 56.0, 0.75, 40.0, Color(0.95, 0.93, 0.88)],
		[Vector3(-6.0, 2.0, -18.0), Vector3(6.5, 20.0, 0.0), 56.0, 0.75, 40.0, Color(0.95, 0.93, 0.88)],
	])
