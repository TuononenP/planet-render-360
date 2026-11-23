class_name LandmarkLnSouthBankArts
extends RefCounted

## South Bank cultural strip (`LN-3.7`, `LN-3.8`, `LN-3.10`):
## - `royal_festival_hall`: Grade I modernist Portland-stone & glass riverside hall
##   (1951, OSM way 5987419) with cantilevered terraces and curved copper auditorium roof.
## - `national_theatre`: Denys Lasdun's Brutalist board-marked concrete terraces &
##   twin 35 m stepped flytowers (1976, OSM relation 2023676 — fixes OSM `h=6.5` bug).
## - `oxo_tower`: Art Deco wharf & 67 m tower with glowing red/white "OXO" cutout bands
##   (1929, OSM ways 25298098, 1449888762).

static func royal_festival_hall(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkLnKit.portland("#E2DDD0", 3.5))
	lm.use("Glass", LandmarkMaterials.glass("#263440"))
	lm.use("Copper", LandmarkMaterials.pbr("copper", "#4B7666", 2.4))
	lm.use("Frame", LandmarkMaterials.paint("#2E3338", 0.45, 0.5))
	lm.use("Lamp", LandmarkMaterials.lit("#FFF0CE", 1.1))
	var w := 76.0
	var d := 86.0
	# Cantilevered riverside modernist terraces
	lm.box("Stone", Vector3(0.0, 2.2, 8.0), Vector3(w + 10.0, 4.4, d + 12.0))
	lm.box("Stone", Vector3(0.0, 5.2, 10.0), Vector3(w + 12.0, 0.7, d + 14.0))
	# Glazed foyer facade with slender vertical mullions
	lm.box("Glass", Vector3(0.0, 12.6, 0.0), Vector3(w, 15.2, d))
	lm.box("Stone", Vector3(0.0, 20.6, 0.0), Vector3(w + 2.4, 1.4, d + 2.4))
	for i in 15:
		var x := lerpf(-w * 0.48, w * 0.48, float(i) / 14.0)
		lm.box("Frame", Vector3(x, 12.6, d * 0.5 + 0.15), Vector3(0.45, 15.2, 0.4))
		lm.box("Frame", Vector3(x, 12.6, -d * 0.5 - 0.15), Vector3(0.45, 15.2, 0.4))
	# Raised "egg-in-a-box" curved copper auditorium roof (top = 28.0 m)
	lm.box("Stone", Vector3(0.0, 23.0, -4.0), Vector3(w * 0.72, 4.0, d * 0.68))
	var segs := 10
	for i in segs:
		var a0 := lerpf(-0.9, 0.9, float(i) / float(segs))
		var a1 := lerpf(-0.9, 0.9, float(i + 1) / float(segs))
		var am := (a0 + a1) * 0.5
		var y := 25.0 + cos(am) * 3.0
		var rx := sin(am) * (w * 0.36)
		lm.box("Copper", Vector3(rx, y, -4.0), Vector3(w * 0.72 / float(segs) + 0.4, 0.8, d * 0.70))
	lm.commit(model)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(0.0, 4.0, d * 0.5 + 10.0), Vector3(0.0, 16.0, d * 0.5), 65.0, 0.9, 55.0],
	])

static func national_theatre(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#C5C0B6", 3.6))
	lm.use("DarkConc", LandmarkMaterials.pbr("concrete", "#9D988E", 3.6))
	lm.use("Glass", LandmarkMaterials.glass("#222B34"))
	lm.use("Lamp", LandmarkMaterials.lit("#FFE4B8", 1.2))
	# Stepped horizontal Brutalist concrete terraces overlooking the Thames
	lm.box("Concrete", Vector3(0.0, 2.2, 0.0), Vector3(114.0, 4.4, 72.0))
	lm.box("Glass", Vector3(0.0, 6.2, 4.0), Vector3(96.0, 4.4, 58.0))
	lm.box("Concrete", Vector3(0.0, 9.0, 4.0), Vector3(106.0, 1.3, 64.0))
	lm.box("Glass", Vector3(-6.0, 12.2, 0.0), Vector3(82.0, 5.2, 48.0))
	lm.box("Concrete", Vector3(-6.0, 15.4, 0.0), Vector3(92.0, 1.3, 54.0))
	# Cantilevered terrace corner stairs & horizontal parapet bands
	for sx in [-1.0, 1.0]:
		lm.box("DarkConc", Vector3(float(sx) * 44.0, 10.5, 22.0), Vector3(14.0, 12.0, 14.0))
	# Twin iconic stepped Brutalist concrete flytowers (Olivier 35.0 m & Lyttelton 31.0 m)
	lm.box("Concrete", Vector3(-18.0, 25.0, -8.0), Vector3(26.0, 20.0, 24.0))
	lm.box("DarkConc", Vector3(-18.0, 33.8, -8.0), Vector3(27.0, 2.4, 25.0))
	lm.box("Concrete", Vector3(22.0, 23.0, -6.0), Vector3(22.0, 16.0, 20.0))
	lm.box("DarkConc", Vector3(22.0, 29.8, -6.0), Vector3(23.0, 2.4, 21.0))
	# Warm glowing terrace strip under main cantilever
	lm.box("Lamp", Vector3(0.0, 8.2, 33.0), Vector3(94.0, 0.35, 0.35))
	lm.commit(model)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-18.0, 16.0, 14.0), Vector3(-18.0, 32.0, -8.0), 55.0, 0.95, 45.0],
		[Vector3(22.0, 16.0, 14.0), Vector3(22.0, 28.0, -6.0), 55.0, 0.9, 45.0],
	])

static func oxo_tower(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Render", LandmarkMaterials.pbr("render", "#E6E1D4", 3.5))
	lm.use("Brick", LandmarkLnKit.red_brick("#8D4A3A", 3.0))
	lm.use("Glass", LandmarkMaterials.glass("#222C34"))
	lm.use("OxoLamp", LandmarkMaterials.lit("#FF3A28", 1.8))
	lm.use("WhiteLamp", LandmarkMaterials.lit("#FFF4DC", 1.4))
	# Long Art Deco wharf building along the Thames (84 m x 28 m x 28 m)
	lm.box("Brick", Vector3(0.0, 4.5, 0.0), Vector3(84.0, 9.0, 28.0))
	lm.box("Render", Vector3(0.0, 18.5, 0.0), Vector3(82.0, 19.0, 26.0))
	for i in 14:
		var wx := lerpf(-37.0, 37.0, float(i) / 13.0)
		for row in 4:
			var wy := 11.5 + float(row) * 4.2
			lm.box("Glass", Vector3(wx, wy, 13.1), Vector3(2.8, 2.6, 0.14))
			lm.box("Glass", Vector3(wx, wy, -13.1), Vector3(2.8, 2.6, 0.14))
	# Signature central stepped Art Deco tower (28..67 m)
	lm.box("Render", Vector3(0.0, 40.0, 0.0), Vector3(13.5, 24.0, 13.5))
	lm.box("Render", Vector3(0.0, 56.0, 0.0), Vector3(10.5, 10.0, 10.5))
	lm.frustum("Render", Vector3(0.0, 61.0, 0.0), 5.0, 1.2, 6.0, 8)
	# Backlit red-and-white "OXO" vertical window bands on all 4 faces (42..56 m)
	for rot_i in 4:
		var rot := Basis(Vector3.UP, PI * 0.5 * float(rot_i))
		var out := rot * Vector3(0.0, 0.0, 1.0)
		var rt := rot * Vector3(1.0, 0.0, 0.0)
		for row in 3:
			var y := 43.0 + float(row) * 4.0
			for k in [-1.0, 0.0, 1.0]:
				var mat := "OxoLamp" if k != 0.0 else "WhiteLamp"
				lm.box(mat, Vector3(0.0, y, 0.0) + out * 6.85 + rt * float(k) * 3.1,
					Vector3(2.0, 2.6, 0.16), rot)
	lm.commit(model)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(0.0, 28.0, 14.0), Vector3(0.0, 56.0, 0.0), 48.0, 0.85, 48.0],
	])
