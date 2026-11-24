class_name LandmarkPaChaillot
extends RefCounted

## Palais de Chaillot (Carlu, Boileau & Azéma, 1937; OSM relation 6826569).
## Twin symmetrical Art Deco travertine & limestone wings curving around the
## Jardins du Trocadéro, framing the wide open Parvis des Droits de l'Homme
## (where the Paris preset camera stands at 48.8622, 2.2887 looking SE toward
## the Eiffel Tower). The central parvis (x = -34..+34 m) stays completely open
## at pavement level; the two monumental pavilions (Passy Wing -X, Paris Wing +X)
## rise to 28 m with fluted piers, gilded roof inscriptions, bronze terrace statues,
## and warm golden night uplighting.

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkPaKit.lutetian("#E4DAC4", 3.5))
	lm.use("Ashlar", LandmarkPaKit.ashlar("#C9BEA6", 3.2))
	lm.use("Pave", LandmarkMaterials.pbr("pavement", "#C7C0B2", 4.0))
	lm.use("Glass", LandmarkMaterials.glass("#2A353E"))
	lm.use("Gilt", LandmarkMaterials.gold())
	lm.use("Bronze", LandmarkPaKit.bronze("#4A5044"))
	lm.use("Lamp", LandmarkMaterials.lit("#FFE4A8", 1.45))
	# Open central Parvis des Droits de l'Homme terrace slab (y = 0..0.3, completely unobstructed!)
	lm.box("Pave", Vector3(0.0, 0.15, 2.0), Vector3(84.0, 0.3, 46.0))
	# Front terrace balustrade overlooking Warsaw Fountains (+Z toward Eiffel Tower)
	lm.box("Stone", Vector3(0.0, 0.55, 24.5), Vector3(80.0, 1.0, 0.9))
	# Frame left & right edges with gilded bronze Art Deco statues & Paris lamps; keep center x = -20..+20 completely open!
	for sx in [-36.0, -24.0, 24.0, 36.0]:
		var x := float(sx)
		lm.box("Ashlar", Vector3(x, 1.0, 24.5), Vector3(1.5, 1.4, 1.5))
		if absf(x) > 30.0:
			lm.frustum("Gilt", Vector3(x, 1.7, 24.5), 0.55, 0.38, 2.8, 8)
		else:
			LandmarkPaKit.paris_lamp(lm, "Bronze", "Lamp", Vector3(x, 1.7, 24.5), 3.4)
	# Twin monumental corner pavilions flanking the 84 m wide Parvis (x = +/-58 m, height 28.0 m)
	for side in [-1.0, 1.0]:
		var s := float(side)
		var px := s * 58.0
		lm.box("Ashlar", Vector3(px, 2.0, 0.0), Vector3(34.0, 4.0, 38.0))
		lm.box("Stone", Vector3(px, 14.5, 0.0), Vector3(32.0, 21.0, 35.0))
		# Stepped Art Deco attic crown reaching 28.0 m with gilded rooftop inscription band
		lm.box("Stone", Vector3(px, 26.2, 0.0), Vector3(29.0, 3.6, 32.0))
		lm.box("Gilt", Vector3(px, 25.8, 16.15), Vector3(24.0, 1.0, 0.18))
		lm.box("Gilt", Vector3(px - s * 16.15, 25.8, 0.0), Vector3(0.18, 1.0, 24.0))
		# Fluted monumental Art Deco piers & tall vertical glass bays on garden (+Z) & parvis inner faces
		for k in 6:
			var fx := px + lerpf(-13.0, 13.0, float(k) / 5.0)
			lm.box("Stone", Vector3(fx, 14.5, 17.9), Vector3(1.8, 20.5, 1.2))
		LandmarkPaKit.win_grid_z(lm, "Glass", px - 11.5, px + 11.5, 17.58, [8.5, 14.5, 20.5], 5, 2.3, 4.2)
		for k in 5:
			var fz := lerpf(-12.5, 12.5, float(k) / 4.0)
			lm.box("Stone", Vector3(px - s * 16.3, 14.5, fz), Vector3(1.2, 20.5, 1.8))
		LandmarkPaKit.win_grid_x(lm, "Glass", px - s * 16.08, -11.0, 11.0, [8.5, 14.5, 20.5], 4, 2.3, 4.2)
		# Sweeping curved gallery wing arcing forward (+Z) around Jardins du Trocadéro (9 segments, ~140 m)
		var segs := 9
		var r_arc := 155.0
		var arc_cz := 155.0
		for i in segs:
			var a0 := lerpf(0.46, 1.24, float(i) / float(segs)) * s
			var a1 := lerpf(0.46, 1.24, float(i + 1) / float(segs)) * s
			var p0 := Vector3(sin(a0) * r_arc, 0.0, arc_cz - cos(a0) * r_arc)
			var p1 := Vector3(sin(a1) * r_arc, 0.0, arc_cz - cos(a1) * r_arc)
			var pm := (p0 + p1) * 0.5
			var seg_l := p0.distance_to(p1) + 0.8
			var yaw := atan2(-(p1.z - p0.z), p1.x - p0.x)
			var rot := Basis(Vector3.UP, yaw)
			lm.box("Ashlar", pm + Vector3(0.0, 1.8, 0.0), Vector3(seg_l, 3.6, 17.5), rot)
			lm.box("Stone", pm + Vector3(0.0, 12.6, 0.0), Vector3(seg_l, 18.2, 16.0), rot)
			lm.box("Stone", pm + Vector3(0.0, 22.6, 0.0), Vector3(seg_l, 1.8, 16.8), rot)
			# Tall Art Deco gallery glazing facing inward toward Jardins du Trocadéro & Eiffel Tower
			var inward := rot * Vector3(0.0, 0.0, 8.15 * s)
			lm.box("Glass", pm + Vector3(0.0, 12.2, 0.0) + inward, Vector3(seg_l * 0.68, 12.0, 0.2), rot)
			# Columnar pilaster between bays
			lm.box("Stone", p0 + Vector3(0.0, 12.6, 0.0) + inward, Vector3(1.5, 18.2, 1.2), rot)
		# End sculptural rotunda pavilion at the outer tip of each curved wing
		var a_end := 1.24 * s
		var pe := Vector3(sin(a_end) * r_arc, 0.0, arc_cz - cos(a_end) * r_arc)
		lm.box("Stone", pe + Vector3(0.0, 12.5, 0.0), Vector3(22.0, 25.0, 22.0))
		lm.box("Gilt", pe + Vector3(0.0, 25.4, 0.0), Vector3(18.0, 0.8, 18.0))
	lm.commit(model)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-54.0, 2.0, 34.0), Vector3(-54.0, 18.0, 18.0), 64.0, 1.0, 68.0],
		[Vector3(54.0, 2.0, 34.0), Vector3(54.0, 18.0, 18.0), 64.0, 1.0, 68.0],
		[Vector3(-104.0, 2.0, 56.0), Vector3(-104.0, 16.0, 38.0), 64.0, 0.9, 68.0],
		[Vector3(104.0, 2.0, 56.0), Vector3(104.0, 16.0, 38.0), 64.0, 0.9, 68.0],
	])

## Fontaine de Varsovie (Warsaw Fountains, 1937; Roger-Henri Expert):
## Monumental dressed-limestone terraced esplanade bridging the Jardins du Trocadéro slope:
## flanking limestone stepped retaining walls & promenades, clipped boxwood parterre hedges,
## 112 m turquoise reflecting pool, upper Art Deco cascade steps, gilded-bronze terrace statues,
## and soft translucent white water-spray plumes (no opaque dark-shaded pipes).
static func fontaine_de_varsovie(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkPaKit.lutetian("#E2D8C2", 3.4))
	lm.use("Ashlar", LandmarkPaKit.ashlar("#C8BDA6", 3.2))
	lm.use("Pave", LandmarkMaterials.pbr("pavement", "#CFC8BC", 4.0))
	lm.use("Water", LandmarkMaterials.pool_water("#3B7485", 0.06))
	lm.use("Hedge", LandmarkMaterials.paint("#3B5733", 0.88, 0.0))
	lm.use("Gilt", LandmarkMaterials.gold())
	lm.use("Bronze", LandmarkPaKit.bronze("#464D42"))
	lm.use("Lamp", LandmarkMaterials.lit("#FFE4AA", 1.35))
	var spray := StandardMaterial3D.new()
	spray.albedo_color = Color(0.95, 0.98, 1.0, 0.42)
	spray.roughness = 0.25
	spray.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	spray.cull_mode = BaseMaterial3D.CULL_DISABLED
	spray.emission_enabled = true
	spray.emission = Color(0.86, 0.93, 0.98)
	spray.emission_energy_multiplier = 0.28
	lm.use("Spray", spray)
	# Broad stepped stone basin foundation & lower promenade deck (y = 0..2.2 m)
	lm.box("Ashlar", Vector3(0.0, 1.0, 2.0), Vector3(68.0, 2.0, 134.0))
	lm.box("Pave", Vector3(0.0, 2.1, 2.0), Vector3(66.0, 0.25, 132.0))
	# Flanking monumental stepped limestone terrace walls & upper garden walks (x = +/-30..+/-44 m)
	# covering the steep carved V-banks cleanly and meeting the Jardins du Trocadéro avenues!
	for sx in [-1.0, 1.0]:
		var s := float(sx)
		# Lower terrace retaining wall + mid stepped terrace + upper balustrade walk
		lm.box("Stone", Vector3(s * 30.0, 2.6, 0.0), Vector3(8.0, 5.2, 132.0))
		lm.box("Pave", Vector3(s * 30.0, 5.25, 0.0), Vector3(7.6, 0.18, 131.0))
		lm.box("Stone", Vector3(s * 38.0, 3.3, -2.0), Vector3(11.0, 6.6, 128.0))
		lm.box("Pave", Vector3(s * 38.0, 6.65, -2.0), Vector3(10.6, 0.18, 127.0))
		# Crisp dressed-limestone parapet balustrades & clipped French boxwood hedges along the upper walk
		lm.box("Stone", Vector3(s * 26.3, 5.85, 0.0), Vector3(0.75, 1.05, 130.0))
		lm.box("Hedge", Vector3(s * 34.0, 7.15, -2.0), Vector3(2.2, 1.05, 122.0))
		lm.box("Stone", Vector3(s * 43.0, 7.2, -2.0), Vector3(0.75, 1.0, 126.0))
		# Stone piers & warm Parisian lamps lining the lower pool promenade
		for k in 6:
			var lz := lerpf(-46.0, 54.0, float(k) / 5.0)
			lm.box("Ashlar", Vector3(s * 26.3, 6.0, lz), Vector3(1.3, 1.35, 1.3))
			LandmarkPaKit.paris_lamp(lm, "Bronze", "Lamp", Vector3(s * 24.0, 2.2, lz), 3.9)
		# Pool coping rim
		lm.box("Stone", Vector3(s * 16.6, 2.55, 6.0), Vector3(1.4, 0.8, 112.4))
	# Long rectangular turquoise reflecting pool (32 x 110 m)
	lm.box("Water", Vector3(0.0, 2.34, 6.0), Vector3(32.0, 0.28, 110.0))
	lm.box("Stone", Vector3(0.0, 2.55, 61.6), Vector3(34.6, 0.8, 1.4))
	# Upper stepped Art Deco cascade terraces at the Palais de Chaillot (-Z) head of the pool
	for step_i in 4:
		var sy := 2.6 + float(step_i) * 1.35
		var sz := -47.0 - float(step_i) * 4.4
		var sw := 34.0 + float(step_i) * 3.8
		lm.box("Stone", Vector3(0.0, sy * 0.5 + 1.0, sz), Vector3(sw, sy, 4.6))
		lm.box("Water", Vector3(0.0, sy + 1.04, sz + 0.35), Vector3(sw - 2.8, 0.16, 3.6))
		lm.box("Spray", Vector3(0.0, sy + 0.32, sz + 2.38), Vector3(sw - 3.6, 1.25, 0.16))
	# Iconic gilded-bronze allegorical statues flanking the upper cascade (real Warsaw Fountains sculptures)
	for sx in [-1.0, 1.0]:
		var s := float(sx)
		lm.box("Stone", Vector3(s * 20.5, 4.6, -50.0), Vector3(4.8, 5.2, 5.4))
		lm.box("Ashlar", Vector3(s * 20.5, 7.35, -50.0), Vector3(5.2, 0.35, 5.8))
		lm.frustum("Gilt", Vector3(s * 20.5, 7.5, -50.0), 0.72, 0.42, 2.8, 10)
	# Soft translucent white mist plumes & gentle fountain jets along the reflecting pool (crest 10.5 m)
	for j in 7:
		var jz := lerpf(-34.0, 44.0, float(j) / 6.0)
		for sx in [-1.0, 1.0]:
			var s := float(sx)
			# Translucent foam splash ring + gentle arched spray veil
			lm.frustum("Spray", Vector3(s * 12.2, 2.48, jz), 0.75, 0.18, 3.6, 8)
			var prev := Vector3(s * 12.2, 2.6, jz)
			for seg in range(1, 7):
				var t := float(seg) / 6.0
				var p := Vector3(lerpf(s * 12.2, s * 2.4, t), 2.6 + sin(t * PI) * 3.8, jz + t * 2.4)
				lm.beam("Spray", prev, p, 0.12, 0.12)
				prev = p
	# Three delicate central vertical mist plumes reaching 10.5 m
	for cz in [-24.0, 4.0, 32.0]:
		lm.frustum("Spray", Vector3(0.0, 2.45, float(cz)), 1.35, 0.25, 8.05, 10)
		lm.frustum("Spray", Vector3(0.0, 2.45, float(cz)), 2.4, 2.1, 0.18, 12)
	lm.commit(model)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-22.0, 3.0, -40.0), Vector3(0.0, 7.5, -52.0), 64.0, 0.95, 52.0],
		[Vector3(22.0, 3.0, -40.0), Vector3(0.0, 7.5, -52.0), 64.0, 0.95, 52.0],
	])
