class_name LandmarkLnWestEastIcons
extends RefCounted

## West, South & East London major icons (`LN-4.9`, `LN-4.11`–`LN-4.14`):
## - `battersea_power_station`: Art Deco brick twin turbine halls + four 101 m white fluted chimneys.
## - `royal_albert_hall`: Elliptical red-brick & terracotta rotunda + 41 m glazed wrought-iron dome.
## - `natural_history_museum`: Waterhouse Romanesque terracotta twin towers & pavilions.
## - `marble_wellington_arches`: Decimus Burton's triumphal Wellington Arch + bronze Quadriga.
## - `o2_arena`: 365 m white PTFE cable-net dome suspended from twelve 100 m yellow masts.

static func battersea_power_station(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#8C5842", 3.4))
	lm.use("Chimney", LandmarkMaterials.pbr("concrete", "#ECE9E2", 3.0))
	lm.use("Glass", LandmarkMaterials.glass("#2A3A46"))
	lm.use("Steel", LandmarkMaterials.paint("#3E4348", 0.5, 0.5))
	lm.use("Beacon", LandmarkMaterials.lit("#FF2418", 2.4))
	# Monumental Art Deco brick boiler & twin turbine halls (152 m x 136 m x 48 m)
	lm.box("Brick", Vector3(0.0, 24.0, 0.0), Vector3(148.0, 48.0, 128.0))
	# Recessed vertical Art Deco cathedral-scale glazing slots
	for i in 12:
		var z := lerpf(-48.0, 48.0, float(i) / 11.0)
		for sx in [-1.0, 1.0]:
			lm.box("Glass", Vector3(float(sx) * 74.15, 25.0, z), Vector3(0.25, 34.0, 4.2))
	# Four corner fluted brick wash-towers & iconic 101 m white tapered concrete chimneys
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var cx := float(sx) * 62.0
			var cz := float(sz) * 52.0
			lm.box("Brick", Vector3(cx, 26.5, cz), Vector3(22.0, 53.0, 22.0))
			lm.frustum("Chimney", Vector3(cx, 53.0, cz), 4.6, 3.3, 48.0, 16)
			lm.frustum("Steel", Vector3(cx, 100.2, cz), 3.4, 3.4, 0.8, 16)
			lm.box("Beacon", Vector3(cx, 101.0, cz), Vector3(0.8, 0.8, 0.8))
	lm.commit(model)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-62.0, 54.0, 62.0), Vector3(-62.0, 92.0, 52.0), 42.0, 0.95, 60.0],
		[Vector3(62.0, 54.0, 62.0), Vector3(62.0, 92.0, 52.0), 42.0, 0.95, 60.0],
		[Vector3(-62.0, 54.0, -62.0), Vector3(-62.0, 92.0, -52.0), 42.0, 0.95, 60.0],
		[Vector3(62.0, 54.0, -62.0), Vector3(62.0, 92.0, -52.0), 42.0, 0.95, 60.0],
	])

static func royal_albert_hall(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Brick", LandmarkLnKit.red_brick("#9A4232", 2.8))
	lm.use("Terra", LandmarkMaterials.pbr("limestone", "#DFC8A6", 3.0))
	lm.use("Glass", LandmarkMaterials.glass("#6C8292"))
	lm.use("Iron", LandmarkMaterials.paint("#4B525A", 0.45, 0.6))
	# Elliptical Victorian red-brick rotunda (82 m x 70 m, eaves 26 m)
	var segs := 24
	var rx := 41.0
	var rz := 35.0
	for i in segs:
		var a0 := TAU * float(i) / float(segs)
		var a1 := TAU * float(i + 1) / float(segs)
		var am := (a0 + a1) * 0.5
		var p0 := Vector2(cos(a0) * rx, sin(a0) * rz)
		var p1 := Vector2(cos(a1) * rx, sin(a1) * rz)
		var pm := (p0 + p1) * 0.5
		var seg_w := p0.distance_to(p1) + 0.3
		var rot := Basis(Vector3.UP, -atan2(p1.y - p0.y, p1.x - p0.x))
		lm.box("Brick", Vector3(pm.x, 12.5, pm.y), Vector3(seg_w, 25.0, 4.5), rot)
		# Continuous buff terracotta mosaic frieze band & cornice
		lm.box("Terra", Vector3(pm.x, 22.8, pm.y), Vector3(seg_w + 0.1, 2.2, 4.9), rot)
		lm.box("Terra", Vector3(pm.x, 25.4, pm.y), Vector3(seg_w + 0.2, 1.2, 5.2), rot)
		lm.box("Glass", Vector3(pm.x, 14.5, pm.y) + (rot * Vector3(0.0, 0.0, 2.35)), Vector3(2.8, 6.2, 0.14), rot)
	# Elliptical glazed wrought-iron dome (26..41 m)
	for ring in 6:
		var t0 := float(ring) / 6.0
		var t1 := float(ring + 1) / 6.0
		var tm := (t0 + t1) * 0.5
		var ang := tm * PI * 0.48
		var r_scale := cos(ang)
		var y := 26.0 + sin(ang) * 14.5
		lm.frustum("Glass", Vector3(0.0, y, 0.0), rx * r_scale * 0.92, rx * r_scale * 0.84, 2.2, 20)
	lm.frustum("Iron", Vector3(0.0, 39.8, 0.0), 4.2, 1.2, 1.4, 12)
	lm.commit(model)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(0.0, 2.0, 48.0), Vector3(0.0, 22.0, 34.0), 65.0, 0.95, 60.0],
	])

static func natural_history_museum(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Buff", LandmarkMaterials.pbr("limestone", "#CDB896", 3.2))
	lm.use("BlueTerra", LandmarkMaterials.pbr("stone", "#788592", 3.2))
	lm.use("Slate", LandmarkLnKit.welsh_slate("#454E58", 2.4))
	lm.use("Glass", LandmarkMaterials.glass("#222B32"))
	# Monumental 200 m Waterhouse Romanesque terracotta facade (banded buff & blue-grey)
	lm.box("Buff", Vector3(0.0, 12.0, 0.0), Vector3(196.0, 24.0, 34.0))
	for k in 5:
		lm.box("BlueTerra", Vector3(0.0, 3.5 + float(k) * 4.5, 0.0), Vector3(196.5, 1.0, 34.5))
	lm.gable("Slate", Vector3(0.0, 24.0, 0.0), 33.0, 194.0, 7.5, Basis(Vector3.UP, PI * 0.5), 0.0, "Slate")
	# Twin central Romanesque portal towers (58.0 m) + grand central gable
	lm.box("Buff", Vector3(0.0, 16.0, 4.0), Vector3(28.0, 32.0, 38.0))
	for sx in [-1.0, 1.0]:
		var tx := float(sx) * 14.5
		lm.box("Buff", Vector3(tx, 22.0, 18.0), Vector3(8.5, 44.0, 8.5))
		lm.frustum("Slate", Vector3(tx, 44.0, 18.0), 4.6, 0.25, 14.0, 4)
		# Corner pavilions
		var px := float(sx) * 92.0
		lm.box("Buff", Vector3(px, 14.5, 2.0), Vector3(18.0, 29.0, 38.0))
		lm.frustum("Slate", Vector3(px, 29.0, 2.0), 9.4, 0.4, 11.0, 4)
	lm.commit(model)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(0.0, 2.0, 38.0), Vector3(0.0, 26.0, 16.0), 68.0, 0.95, 70.0],
	])

static func marble_wellington_arches(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkLnKit.portland("#E2DAC8", 3.0))
	lm.use("Bronze", LandmarkMaterials.paint("#2D3530", 0.45, 0.65))
	# Wellington Arch (Decimus Burton, 1830): Corinthian triumphal arch + bronze Quadriga (21.0 m)
	for sx in [-1.0, 1.0]:
		lm.box("Stone", Vector3(float(sx) * 7.2, 6.8, 0.0), Vector3(6.8, 13.6, 13.0))
	LandmarkLnKit.arch_rib(lm, "Stone", -3.8, 3.8, 7.6, 12.2, 6.0, 8, 1.4, 1.6)
	LandmarkLnKit.arch_rib(lm, "Stone", -3.8, 3.8, 7.6, 12.2, -6.0, 8, 1.4, 1.6)
	lm.box("Stone", Vector3(0.0, 14.8, 0.0), Vector3(22.0, 3.2, 13.6))
	lm.box("Stone", Vector3(0.0, 17.2, 0.0), Vector3(14.0, 1.8, 9.0))
	# Peace Descending on the Quadriga of War (18.1..21.0 m)
	lm.box("Bronze", Vector3(0.0, 19.3, 0.0), Vector3(5.4, 2.6, 4.2))
	lm.frustum("Bronze", Vector3(0.0, 19.6, 0.0), 1.4, 0.4, 1.4, 8)
	lm.commit(model)

static func o2_arena(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Dome", LandmarkMaterials.pbr("render", "#F2F0EA", 6.0))
	lm.use("Mast", LandmarkMaterials.paint("#E6B81E", 0.42, 0.55))
	lm.use("Cable", LandmarkMaterials.paint("#B0B6BC", 0.45, 0.7))
	lm.use("Lamp", LandmarkMaterials.lit("#FFF2D0", 1.3))
	# 365 m diameter white PTFE cable-net dome (radius 182.5 m, height 52 m)
	var prof := PackedVector2Array()
	for i in 10:
		var a := float(i) / 9.0 * PI * 0.5
		prof.append(Vector2(cos(a) * 182.5, sin(a) * 52.0))
	lm.lathe("Dome", Vector3(0.0, 0.0, 0.0), prof, 24)
	# Twelve 95 m yellow inclined steel masts piercing the dome ring
	for i in 12:
		var a := TAU * float(i) / 12.0
		var base := Vector3(cos(a) * 102.0, 0.0, sin(a) * 102.0)
		var top := Vector3(cos(a) * 116.0, 95.0, sin(a) * 116.0)
		lm.beam("Mast", base, top, 2.2, 2.2)
		lm.beam("Cable", top, Vector3(cos(a) * 182.0, 4.0, sin(a) * 182.0), 0.35, 0.35)
		lm.beam("Cable", top, Vector3(cos(a) * 42.0, 49.0, sin(a) * 42.0), 0.35, 0.35)
		lm.box("Lamp", top + Vector3(0.0, 0.6, 0.0), Vector3(1.6, 1.2, 1.6))
	lm.commit(model)
