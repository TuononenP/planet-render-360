class_name LandmarkPaSeineWest
extends RefCounted

## Western Seine landmarks (`PA-3`):
## - Palais de Tokyo & Musée d'Art Moderne (1937 Art Deco twin wings & colonnade pool)
## - Maison de la Radio et de la Musique (Henry Bernard, 1963; circular aluminium drum + 68 m tower)
## - Statue of Liberty replica on Île aux Cygnes (Bartholdi, 1889; 17.5 m incl. granite plinth)

## Palais de Tokyo & Musée d'Art Moderne de Paris (20 m; 176 x 78 m):
## Twin symmetrical 1937 Art Deco white travertine pavilions joined by a dramatic open double
## colonnade overlooking a stepped reflecting pool and bronze bas-reliefs facing the Seine.
static func palais_de_tokyo(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkPaKit.lutetian("#E4DAC4", 3.5))
	lm.use("Ashlar", LandmarkPaKit.ashlar("#C9BEA6", 3.2))
	lm.use("Glass", LandmarkMaterials.glass("#2A353E"))
	lm.use("Water", LandmarkMaterials.pool_water())
	lm.use("Bronze", LandmarkPaKit.bronze("#464D42"))
	lm.use("Lamp", LandmarkMaterials.lit("#FFE4AC", 1.35))
	# Grand stepped riverside terrace & central reflecting pool (facing Seine +Z)
	lm.box("Ashlar", Vector3(0.0, 1.5, 16.0), Vector3(172.0, 3.0, 40.0))
	lm.box("Water", Vector3(0.0, 3.15, 16.0), Vector3(54.0, 0.25, 22.0))
	# Twin flanking Art Deco wings (West: Palais de Tokyo, East: Musée d'Art Moderne)
	for sx in [-1.0, 1.0]:
		var wx := float(sx) * 58.0
		lm.box("Stone", Vector3(wx, 10.0, 0.0), Vector3(52.0, 18.0, 68.0))
		lm.box("Stone", Vector3(wx, 19.5, 0.0), Vector3(53.4, 1.0, 69.4))
		# Art Deco recessed rooftop gallery skylight monitor
		lm.box("Ashlar", Vector3(wx, 19.6, 0.0), Vector3(44.0, 0.9, 58.0))
		lm.box("Glass", Vector3(wx, 20.1, 0.0), Vector3(36.0, 0.45, 48.0))
		# Monumental fluted Art Deco colonnade on the riverside (+Z) and courtyard inner faces
		LandmarkPaKit.colonnade_x(lm, "Stone", wx - 22.0, wx + 22.0, 3.0, 35.0, 9, 14.5, 0.62)
		LandmarkPaKit.win_grid_z(lm, "Glass", wx - 21.0, wx + 21.0, 34.1, [8.0, 14.2], 7, 2.4, 3.8)
		# Stepped bronze relief frieze on the outer wing
		lm.box("Bronze", Vector3(wx, 11.0, 34.4), Vector3(28.0, 3.2, 0.3))
	# Open double colonnade screen linking the two wings across the rear of the reflecting pool (-Z)
	lm.box("Stone", Vector3(0.0, 18.2, -16.0), Vector3(68.0, 3.6, 14.0))
	LandmarkPaKit.colonnade_x(lm, "Stone", -30.0, 30.0, 3.0, -10.0, 10, 13.6, 0.58)
	LandmarkPaKit.colonnade_x(lm, "Stone", -30.0, 30.0, 3.0, -21.0, 10, 13.6, 0.58)
	# Central bronze allegorical sculpture ("La France") standing before the pool
	lm.box("Ashlar", Vector3(0.0, 4.2, 2.0), Vector3(3.6, 2.4, 3.6))
	lm.frustum("Bronze", Vector3(0.0, 5.4, 2.0), 0.75, 0.45, 4.2, 8)
	for lx in [-42.0, -18.0, 18.0, 42.0]:
		LandmarkPaKit.paris_lamp(lm, "Bronze", "Lamp", Vector3(float(lx), 3.0, 34.5), 4.0)
	lm.commit(model)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-58.0, 4.0, 46.0), Vector3(-58.0, 14.0, 34.0), 64.0, 0.9, 55.0],
		[Vector3(0.0, 4.0, 14.0), Vector3(0.0, 14.0, -14.0), 64.0, 1.0, 55.0],
		[Vector3(58.0, 4.0, 46.0), Vector3(58.0, 14.0, 34.0), 64.0, 0.9, 55.0],
	])

## Maison de la Radio et de la Musique (68 m; outer ring diameter 154 m):
## Iconic 1963 circular brushed-aluminium drum with continuous horizontal ribbon glazing,
## inner courtyard ring, and 68 m central rectangular broadcasting tower.
static func maison_de_la_radio(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Alum", LandmarkMaterials.paint("#C9CED4", 0.36, 0.72))
	lm.use("DarkAlum", LandmarkMaterials.paint("#7B828A", 0.42, 0.65))
	lm.use("Glass", LandmarkMaterials.glass("#2A3B48"))
	lm.use("Stone", LandmarkPaKit.ashlar("#B6B2A8", 3.5))
	lm.use("Lamp", LandmarkMaterials.lit("#FFE4A8", 1.35))
	# Ground stone plinth ring
	lm.frustum("Stone", Vector3(0.0, 0.0, 0.0), 77.0, 77.0, 3.2, 36)
	# Outer circular aluminium ring (36 facets, 154 m diameter, 26 m tall) built as hollow ring segments
	var segs := 32
	var r_out := 74.0
	var r_in := 58.0
	var r_mid := (r_out + r_in) * 0.5
	var thick := r_out - r_in
	for i in segs:
		var a := TAU * (float(i) + 0.5) / float(segs)
		var chord := TAU * r_mid / float(segs) + 0.6
		var pos := Vector3(cos(a) * r_mid, 14.5, sin(a) * r_mid)
		var rot := Basis(Vector3.UP, -a)
		lm.box("Alum", pos, Vector3(thick, 22.6, chord), rot)
		# Horizontal ribbon window bands wrapping the circular facade
		for wy in [7.5, 12.2, 16.9, 21.6]:
			lm.box("Glass", Vector3(cos(a) * (r_out + 0.12), float(wy), sin(a) * (r_out + 0.12)),
				Vector3(0.24, 2.2, chord * 0.94), rot)
		# Vertical aluminium mullion fin
		var af := TAU * float(i) / float(segs)
		lm.box("DarkAlum", Vector3(cos(af) * (r_out + 0.3), 14.5, sin(af) * (r_out + 0.3)),
			Vector3(0.5, 22.8, 0.35), Basis(Vector3.UP, -af))
	# Inner low circular auditorium drum
	lm.frustum("DarkAlum", Vector3(0.0, 3.0, 0.0), 34.0, 34.0, 14.0, 24)
	# Iconic 68 m central rectangular broadcasting tower rising out of the circular courtyard
	lm.box("Alum", Vector3(0.0, 34.0, 0.0), Vector3(36.0, 68.0, 18.0))
	lm.box("DarkAlum", Vector3(0.0, 67.2, 0.0), Vector3(34.0, 1.6, 16.0))
	for wy in [28.0, 34.0, 40.0, 46.0, 52.0, 58.0, 63.0]:
		lm.box("Glass", Vector3(0.0, float(wy), 9.12), Vector3(32.5, 2.4, 0.2))
		lm.box("Glass", Vector3(0.0, float(wy), -9.12), Vector3(32.5, 2.4, 0.2))
	lm.box("Lamp", Vector3(0.0, 66.2, 9.2), Vector3(26.0, 0.7, 0.22))
	lm.box("Lamp", Vector3(0.0, 66.2, -9.2), Vector3(26.0, 0.7, 0.22))
	lm.commit(model)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(0.0, 26.0, 42.0), Vector3(0.0, 52.0, 9.0), 58.0, 1.0, 75.0],
		[Vector3(0.0, 26.0, -42.0), Vector3(0.0, 52.0, -9.0), 58.0, 1.0, 75.0],
	])

## Statue of Liberty replica on Île aux Cygnes (Bartholdi, 1889; 17.5 m total):
## 11.5 m dark bronze Lady Liberty holding aloft her gilded torch on a 6 m granite pedestal
## at the western prow of Île aux Cygnes by Pont de Grenelle, facing west toward New York.
static func statue_liberte_paris(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Granite", LandmarkPaKit.ashlar("#ABA498", 2.5))
	lm.use("Bronze", LandmarkPaKit.bronze("#3B453C"))
	lm.use("Gilt", LandmarkMaterials.gold())
	lm.use("TorchLamp", LandmarkMaterials.lit("#FFBE54", 2.2))
	# Stepped granite pedestal (0..6.0 m)
	lm.box("Granite", Vector3(0.0, 0.6, 0.0), Vector3(5.6, 1.2, 5.6))
	lm.box("Granite", Vector3(0.0, 3.4, 0.0), Vector3(3.8, 4.4, 3.8))
	lm.box("Granite", Vector3(0.0, 5.8, 0.0), Vector3(4.2, 0.5, 4.2))
	# Draped bronze figure (6.0..14.6 m)
	lm.frustum("Bronze", Vector3(0.0, 6.0, 0.0), 1.35, 0.92, 5.4, 12)
	lm.frustum("Bronze", Vector3(0.0, 11.4, 0.0), 0.92, 0.68, 2.1, 10)
	lm.frustum("Bronze", Vector3(0.0, 13.5, 0.0), 0.42, 0.36, 0.95, 10)
	# Spiked crown rays
	for k in 7:
		var a := lerpf(-1.0, 1.0, float(k) / 6.0)
		lm.beam("Bronze", Vector3(0.0, 14.3, 0.0), Vector3(sin(a) * 0.95, 14.9, cos(a) * 0.65), 0.07, 0.07)
	# Left arm holding tablet + raised right arm holding gilded torch (reaches 17.5 m)
	lm.box("Bronze", Vector3(-0.75, 12.2, 0.35), Vector3(0.35, 1.15, 0.85))
	lm.beam("Bronze", Vector3(0.65, 13.1, 0.0), Vector3(1.05, 16.4, 0.15), 0.28, 0.28)
	lm.frustum("Bronze", Vector3(1.05, 16.3, 0.15), 0.18, 0.34, 0.55, 8)
	lm.frustum("TorchLamp", Vector3(1.05, 16.85, 0.15), 0.22, 0.05, 0.65, 8)
	lm.commit(model)
	model.set_meta(LandmarkLights.HALO_META, [[Vector3(1.05, 17.2, 0.15), 1.2, Color(1.0, 0.72, 0.26)]])
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(0.0, 1.5, 10.0), Vector3(0.0, 11.0, 0.0), 54.0, 0.9, 28.0],
		[Vector3(0.0, 1.5, -10.0), Vector3(0.0, 11.0, 0.0), 54.0, 0.9, 28.0],
	])
