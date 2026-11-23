class_name LandmarkLnCentralIcons
extends RefCounted

## Central London major icons (`LN-4.6`–`LN-4.8`, `LN-4.10`):
## - `st_pancras_station`: George Gilbert Scott's red-brick Victorian Gothic Renaissance
##   Hotel (82 m clock tower) fronting W. H. Barlow's 73 m single-span arched train shed.
## - `british_museum`: Robert Smirke's 44-column Ionic Portland-stone colonnade & pediment.
## - `westminster_cathedral`: Bentley's striped red-brick & Portland-stone neo-Byzantine
##   nave and 83 m St Edward's Campanile.
## - `bt_tower`: 188.4 m cylindrical telecom tower, microwave gallery, lit info-band & mast.

static func st_pancras_station(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Brick", LandmarkLnKit.red_brick("#9C3E2E", 2.8))
	lm.use("Stone", LandmarkLnKit.portland("#DDD6C4", 3.2))
	lm.use("Slate", LandmarkLnKit.welsh_slate("#444C56", 2.2))
	lm.use("ShedIron", LandmarkMaterials.paint("#5A788E", 0.45, 0.55))
	lm.use("Glass", LandmarkMaterials.glass("#263440"))
	lm.use("Dial", LandmarkMaterials.lit("#F5F0DC", 1.0))
	lm.use("Gilt", LandmarkMaterials.gold())
	# Victorian Gothic red-brick Renaissance Hotel frontage (+Z, 160 m wide)
	lm.box("Brick", Vector3(0.0, 14.0, 44.0), Vector3(156.0, 28.0, 22.0))
	lm.gable("Slate", Vector3(0.0, 28.0, 44.0), 21.0, 154.0, 7.5, Basis(Vector3.UP, PI * 0.5), 0.0, "Slate")
	# Stone banding & Gothic window rows
	for wy in [9.0, 17.0, 25.0]:
		lm.box("Stone", Vector3(0.0, float(wy), 55.1), Vector3(156.4, 0.7, 0.4))
	for i in 22:
		var wx := lerpf(-72.0, 72.0, float(i) / 21.0)
		for wy in [6.0, 13.0, 21.0]:
			lm.box("Glass", Vector3(wx, float(wy), 55.15), Vector3(2.2, 3.8, 0.14))
	# Iconic 82 m St Pancras Gothic clock tower on east end (+X)
	lm.box("Brick", Vector3(62.0, 28.0, 48.0), Vector3(13.0, 56.0, 13.0))
	for rot_i in 4:
		var rot := Basis(Vector3.UP, PI * 0.5 * float(rot_i))
		var out := rot * Vector3(0.0, 0.0, 1.0)
		lm.disc("Dial", Vector3(62.0, 48.0, 48.0) + out * 6.65, out, 2.4, 20)
	lm.frustum("Slate", Vector3(62.0, 56.0, 48.0), 6.8, 0.25, 25.0, 4)
	lm.box("Gilt", Vector3(62.0, 81.4, 48.0), Vector3(0.35, 1.2, 0.35))
	# West-end fairy-tale turret (58 m)
	lm.box("Brick", Vector3(-64.0, 21.0, 48.0), Vector3(11.0, 42.0, 11.0))
	lm.frustum("Slate", Vector3(-64.0, 42.0, 48.0), 5.8, 0.2, 16.0, 4)
	# Barlow's 73 m single-span arched iron-and-glass train shed behind (-Z)
	var arch_segs := 12
	for i in arch_segs:
		var a := lerpf(-1.35, 1.35, (float(i) + 0.5) / float(arch_segs))
		var rx := sin(a) * 36.5
		var ry := 6.0 + cos(a) * 26.0
		var rot := Basis(Vector3.BACK, a)
		var mat := "Glass" if absf(a) < 0.65 else "ShedIron"
		lm.box(mat, Vector3(rx, ry, -42.0), Vector3(9.8, 0.9, 148.0), rot)
	lm.commit(model)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(62.0, 4.0, 74.0), Vector3(62.0, 50.0, 48.0), 55.0, 1.0, 85.0],
		[Vector3(0.0, 4.0, 74.0), Vector3(0.0, 24.0, 46.0), 68.0, 0.9, 75.0],
	])

static func british_museum(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkLnKit.portland("#E0D9C8", 3.4))
	lm.use("Glass", LandmarkMaterials.glass("#3B4D5B"))
	lm.use("Lead", LandmarkMaterials.paint("#565E66", 0.5, 0.35))
	# Monumental U-shaped Portland-stone museum quadrangle (112 m x 96 m)
	lm.box("Stone", Vector3(0.0, 10.5, -16.0), Vector3(106.0, 21.0, 62.0))
	for sx in [-1.0, 1.0]:
		lm.box("Stone", Vector3(float(sx) * 42.0, 10.5, 28.0), Vector3(24.0, 21.0, 32.0))
	# Robert Smirke's famous Ionic colonnade & central octastyle portico with pediment (top = 26.0 m)
	LandmarkLnKit.colonnade_x(lm, "Stone", -50.0, 50.0, 2.0, 19.5, 16, 15.5, 0.68)
	LandmarkLnKit.colonnade_x(lm, "Stone", -16.0, 16.0, 2.0, 26.5, 8, 15.5, 0.72)
	LandmarkLnKit.pediment_z(lm, "Stone", 0.0, 19.2, 26.5, 34.0, 6.4, 2.8)
	# Great Court tessellated glass canopy & Reading Room drum behind
	lm.frustum("Glass", Vector3(0.0, 21.0, -14.0), 26.0, 22.0, 5.0, 16)
	lm.commit(model)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(0.0, 2.0, 44.0), Vector3(0.0, 16.0, 24.0), 68.0, 0.95, 65.0],
	])

static func westminster_cathedral(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Brick", LandmarkLnKit.red_brick("#9E4634", 2.6))
	lm.use("Stone", LandmarkLnKit.portland("#E2DAC8", 2.8))
	lm.use("Copper", LandmarkMaterials.pbr("copper", "#4F7A68", 2.2))
	lm.use("Lead", LandmarkMaterials.paint("#545C64", 0.5, 0.35))
	lm.use("Glass", LandmarkMaterials.glass("#222B32"))
	# Neo-Byzantine nave with horizontal red-brick and Portland-stone stripes (38 m x 96 m x 28 m)
	lm.box("Brick", Vector3(0.0, 14.0, 0.0), Vector3(38.0, 28.0, 96.0))
	for k in 7:
		lm.box("Stone", Vector3(0.0, 3.0 + float(k) * 3.8, 0.0), Vector3(38.5, 0.9, 96.5))
	# Shallow saucer domes along the nave roof
	for dz in [-26.0, 0.0, 26.0]:
		lm.frustum("Lead", Vector3(0.0, 28.0, float(dz)), 12.0, 4.0, 4.5, 16)
	# Slender 83 m striped St Edward's Campanile at north-west corner
	lm.box("Brick", Vector3(-16.0, 35.0, 44.0), Vector3(10.5, 70.0, 10.5))
	for k in 16:
		lm.box("Stone", Vector3(-16.0, 4.0 + float(k) * 4.2, 44.0), Vector3(10.9, 0.85, 10.9))
	lm.frustum("Stone", Vector3(-16.0, 70.0, 44.0), 4.6, 4.2, 5.0, 12)
	lm.frustum("Copper", Vector3(-16.0, 75.0, 44.0), 4.2, 0.3, 8.0, 12)
	lm.commit(model)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-16.0, 3.0, 62.0), Vector3(-16.0, 52.0, 44.0), 50.0, 0.95, 85.0],
	])

static func bt_tower(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Glass", LandmarkMaterials.glass("#486274"))
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#C8C5BC", 3.2))
	lm.use("Steel", LandmarkMaterials.paint("#A8B0B8", 0.4, 0.72))
	lm.use("InfoLamp", LandmarkMaterials.lit("#4CA6FF", 1.8))
	lm.use("Beacon", LandmarkMaterials.lit("#FF2418", 2.8))
	# Podium & concrete core (0..35 m)
	lm.box("Concrete", Vector3(0.0, 7.0, 0.0), Vector3(26.0, 14.0, 26.0))
	lm.frustum("Concrete", Vector3(0.0, 14.0, 0.0), 6.2, 6.2, 22.0, 16)
	# 16-storey cylindrical glazed curtain-wall shaft (36..115 m)
	lm.frustum("Glass", Vector3(0.0, 36.0, 0.0), 8.2, 8.2, 79.0, 20)
	for i in 15:
		lm.frustum("Concrete", Vector3(0.0, 38.0 + float(i) * 5.1, 0.0), 8.38, 8.38, 0.45, 20)
	# Open microwave-dish aerial gallery (115..152 m)
	lm.frustum("Concrete", Vector3(0.0, 115.0, 0.0), 4.4, 4.4, 37.0, 14)
	for k in 6:
		lm.frustum("Steel", Vector3(0.0, 118.0 + float(k) * 5.8, 0.0), 8.4, 8.4, 0.7, 16)
	# Iconic revolving restaurant drum & 360-degree illuminated LED info-band (152..177 m)
	lm.frustum("Glass", Vector3(0.0, 152.0, 0.0), 9.6, 9.6, 18.0, 20)
	lm.frustum("InfoLamp", Vector3(0.0, 166.5, 0.0), 9.75, 9.75, 3.2, 20)
	lm.frustum("Concrete", Vector3(0.0, 170.0, 0.0), 9.2, 5.5, 7.0, 16)
	# Lattice mast & red aviation beacon (177..188.4 m)
	lm.frustum("Steel", Vector3(0.0, 177.0, 0.0), 1.4, 0.25, 11.4, 8)
	lm.box("Beacon", Vector3(0.0, 188.0, 0.0), Vector3(0.9, 0.9, 0.9))
	lm.commit(model)
	model.set_meta(LandmarkLights.HALO_META, [[Vector3(0.0, 188.2, 0.0), 2.5, Color(1.0, 0.14, 0.06)]])
