class_name LandmarkPaChaillot
extends RefCounted

## Palais de Chaillot (Carlu, Boileau & Azéma, 1937; OSM relation 6826569) and
## Fontaine de Varsovie / Jardins du Trocadéro (Roger-Henri Expert, 1937).
## Twin symmetrical Art Deco travertine & limestone wings curve around the
## Jardins du Trocadéro, framing the wide open Parvis des Droits de l'Homme
## (where the Paris preset camera stands at 48.8622, 2.2887 looking SE toward
## the Eiffel Tower). Below the Parvis belvedere parterre, the 4-tier Art Deco
## cascade, gilded-bronze animal sculptures, 102 m turquoise mirror basin with
## 20 parabolic water cannons, manicured yew topiaries, Davioud candelabra, and
## slope-stepped French boxwood parterre terraces bridge down to Place de Varsovie.

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkPaKit.lutetian("#E4DAC4", 3.5))
	lm.use("Ashlar", LandmarkPaKit.ashlar("#C9BEA6", 3.2))
	lm.use("Pave", LandmarkMaterials.pbr("pavement", "#D6CFC0", 4.0))
	lm.use("Turf", LandmarkMaterials.pbr("grass", "#4A6E38", 3.2))
	lm.use("Hedge", LandmarkMaterials.pbr("grass", "#2E4A26", 1.8))
	lm.use("Glass", LandmarkMaterials.glass("#2A353E"))
	lm.use("Gilt", LandmarkMaterials.gold())
	lm.use("Bronze", LandmarkPaKit.bronze("#4A5044"))
	lm.use("Lamp", LandmarkMaterials.lit("#FFE4A8", 1.45))
	# Open central Parvis des Droits de l'Homme travertine terrace slab (y = 0..0.38 m)
	lm.box("Pave", Vector3(0.0, 0.19, 2.0), Vector3(84.0, 0.38, 46.0))
	# Pierced Art Deco Lutetian-limestone balustrade overlooking the Jardins du Trocadéro (+Z)
	_balustrade_x(lm, "Stone", -39.5, 39.5, 0.38, 24.5, 0.72)
	# Frame left & right Parvis piers with sculpted gilded-bronze Art Deco figures & Davioud lamps;
	# keep central vista (x = -20..+20 m) completely unobstructed above the balustrade rail.
	for sx in [-36.0, -22.0, 22.0, 36.0]:
		var x := float(sx)
		lm.box("Ashlar", Vector3(x, 0.98, 24.5), Vector3(1.6, 1.38, 1.6))
		lm.box("Stone", Vector3(x, 1.72, 24.5), Vector3(1.85, 0.22, 1.85))
		if absf(x) > 30.0:
			LandmarkKits.statue_figure(lm, "Gilt", Vector3(x, 1.82, 24.5), 2.9, x > 0.0)
		else:
			LandmarkPaKit.paris_lamp(lm, "Bronze", "Lamp", Vector3(x, 1.82, 24.5), 3.3)
	# Convex-brow French Formal Belvedere Terrace in front of the Parvis balustrade (z = 24.8..36.6 m):
	# holds y = +0.42..+0.40 m over the z = 29.2 m DEM crest, then eases to y = -1.32 m at z = 36.6 m
	# so no grey sett strip shows and 100% of the Warsaw Fountains cascade & pool stay in sight.
	var belv_grid: Array[PackedVector3Array] = [
		PackedVector3Array([Vector3(-41.0, 0.42, 24.8), Vector3(41.0, 0.42, 24.8)]),
		PackedVector3Array([Vector3(-41.0, 0.40, 30.0), Vector3(41.0, 0.40, 30.0)]),
		PackedVector3Array([Vector3(-41.0, -1.32, 36.6), Vector3(41.0, -1.32, 36.6)]),
	]
	lm.grid("Pave", belv_grid)
	lm.box("Stone", Vector3(0.0, -1.28, 36.65), Vector3(82.4, 0.26, 0.75))
	# Four manicured French emerald-turf & clipped-boxwood broderie panels on the flat belvedere brow
	for px in [-27.0, -9.2, 9.2, 27.0]:
		var bx := float(px)
		lm.box("Turf", Vector3(bx, 0.45, 27.3), Vector3(14.0, 0.08, 3.8))
		lm.box("Hedge", Vector3(bx, 0.56, 25.5), Vector3(14.4, 0.26, 0.42))
		lm.box("Hedge", Vector3(bx, 0.56, 29.1), Vector3(14.4, 0.26, 0.42))
		for hs in [-1.0, 1.0]:
			lm.box("Hedge", Vector3(bx + float(hs) * 7.0, 0.56, 27.3), Vector3(0.42, 0.26, 3.8))
	# Twin monumental corner pavilions flanking the 84 m wide Parvis (x = +/-58 m, height 28.0 m)
	for side in [-1.0, 1.0]:
		var s := float(side)
		var px := s * 58.0
		lm.box("Ashlar", Vector3(px, 2.0, 0.0), Vector3(34.0, 4.0, 38.0))
		lm.box("Stone", Vector3(px, 14.5, 0.0), Vector3(32.0, 21.0, 35.0))
		lm.box("Stone", Vector3(px, 26.2, 0.0), Vector3(29.0, 3.6, 32.0))
		lm.box("Gilt", Vector3(px, 25.8, 16.15), Vector3(24.0, 1.0, 0.18))
		lm.box("Gilt", Vector3(px - s * 16.15, 25.8, 0.0), Vector3(0.18, 1.0, 24.0))
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
			var inward := rot * Vector3(0.0, 0.0, 8.15 * s)
			lm.box("Glass", pm + Vector3(0.0, 12.2, 0.0) + inward, Vector3(seg_l * 0.68, 12.0, 0.2), rot)
			lm.box("Stone", p0 + Vector3(0.0, 12.6, 0.0) + inward, Vector3(1.5, 18.2, 1.2), rot)
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
## Anchored at Place de Varsovie (`base_at_m: [0, 82]`, y = 0, height_m = 10.5):
## 102 x 32 m turquoise mirror pool, 20 inclined parabolic water cannons, 4-tier wide
## Art Deco cascade, gilded-bronze Jouve & Guyot animal sculptural groups, manicured
## Taxus yew topiaries in Versailles planters, Davioud candelabra, and low-profile
## slope-stepped French boxwood parterre terraces framed by real park bosquets.
static func fontaine_de_varsovie(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkPaKit.lutetian("#E4DAC4", 3.4))
	lm.use("Ashlar", LandmarkPaKit.ashlar("#C9BEA6", 3.2))
	lm.use("Pave", LandmarkMaterials.pbr("pavement", "#D5CEBF", 3.8))
	lm.use("Water", LandmarkMaterials.pool_water("#337688", 0.05))
	lm.use("Turf", LandmarkMaterials.pbr("grass", "#4B7039", 3.2))
	lm.use("Hedge", LandmarkMaterials.pbr("grass", "#2D4B25", 1.8))
	lm.use("Yew", LandmarkMaterials.pbr("grass", "#203A1E", 1.4))
	lm.use("Gilt", LandmarkMaterials.gold())
	lm.use("Bronze", LandmarkPaKit.bronze("#464D42"))
	lm.use("Lamp", LandmarkMaterials.lit("#FFE4AA", 1.35))

	# 1. SE Place de Varsovie stepped stone apron & lower basin promenade deck (y = -0.3..2.05 m)
	lm.box("Ashlar", Vector3(0.0, 0.15, 73.0), Vector3(58.0, 0.9, 16.0))
	lm.box("Pave", Vector3(0.0, 0.65, 72.0), Vector3(54.0, 0.3, 13.0))
	lm.box("Stone", Vector3(0.0, 1.15, 68.5), Vector3(51.0, 0.7, 8.0))
	lm.box("Ashlar", Vector3(0.0, 0.85, 13.0), Vector3(50.4, 2.3, 108.0))
	lm.box("Pave", Vector3(0.0, 2.02, 13.0), Vector3(49.8, 0.16, 107.2))

	# 2. Grand Miroir d'Eau (32 x 102 m turquoise reflecting pool, z = -38..+64 m)
	lm.box("Water", Vector3(0.0, 2.08, 13.0), Vector3(32.0, 0.20, 102.0))
	for sx in [-1.0, 1.0]:
		var s := float(sx)
		lm.box("Stone", Vector3(s * 16.55, 2.28, 13.0), Vector3(1.3, 0.52, 104.2))
		lm.box("Stone", Vector3(s * 16.55, 2.58, 13.0), Vector3(1.55, 0.14, 104.6))
		for j in 10:
			var jz := lerpf(-31.0, 41.0, float(j) / 9.0)
			lm.box("Ashlar", Vector3(s * 15.1, 2.12, jz), Vector3(1.5, 0.36, 1.8))
			lm.beam("Bronze", Vector3(s * 15.0, 2.26, jz - 0.2),
				Vector3(s * 14.3, 2.52, jz + 0.45), 0.22, 0.22)
	lm.box("Stone", Vector3(0.0, 2.28, 64.55), Vector3(34.6, 0.52, 1.3))
	lm.box("Stone", Vector3(0.0, 2.58, 64.55), Vector3(34.9, 0.14, 1.55))

	# 3. Lower Basin Promenades (|x| = 17.4..24.8 m): Versailles yew topiaries, Davioud lamps & benches
	for sx in [-1.0, 1.0]:
		var s := float(sx)
		for k in 9:
			var tz := lerpf(-33.0, 55.0, float(k) / 8.0)
			_yew_planter(lm, Vector3(s * 19.8, 2.10, tz), 2.25)
		for k in 7:
			var lz := lerpf(-36.0, 58.0, float(k) / 6.0)
			LandmarkPaKit.paris_lamp(lm, "Bronze", "Lamp", Vector3(s * 23.2, 2.10, lz), 4.0)
			if k < 6:
				var bz := lerpf(-28.0, 50.0, float(k) / 5.0)
				lm.box("Stone", Vector3(s * 23.8, 2.38, bz), Vector3(0.72, 0.52, 2.5))
				lm.box("Ashlar", Vector3(s * 23.8, 2.66, bz), Vector3(0.84, 0.10, 2.7))

	# 4. Low-Profile Slope-Matched Limestone Retaining Walls & French Boxwood Parterres (|x| = 25..34 m)
	# Six stepped garden bays tapering gently from z = -42 to z = +66 m (no tall walls blocking sightlines)
	var tier_heights := [6.2, 5.4, 4.6, 3.9, 3.3, 2.8]
	for bi in 6:
		var z0 := -42.0 + float(bi) * 18.0
		var z1 := z0 + 18.0
		var zc := (z0 + z1) * 0.5
		var blen := 18.05
		var h_mid := float(tier_heights[bi])
		var h_outer := h_mid + 1.15
		for sx in [-1.0, 1.0]:
			var s := float(sx)
			lm.box("Ashlar", Vector3(s * 25.4, h_mid * 0.5, zc), Vector3(1.4, h_mid, blen))
			lm.box("Stone", Vector3(s * 25.4, h_mid + 0.12, zc), Vector3(1.65, 0.24, blen + 0.15))
			_balustrade_z(lm, "Stone", s * 25.2, h_mid + 0.24, z0 + 0.4, z1 - 0.4, 0.72)
			# Manicured French parterre terrace (|x| = 26.1..31.5 m): emerald lawn & boxwood broderie
			lm.box("Ashlar", Vector3(s * 28.8, h_mid * 0.5, zc), Vector3(5.6, h_mid, blen))
			lm.box("Pave", Vector3(s * 28.8, h_mid + 0.08, zc), Vector3(5.5, 0.16, blen))
			lm.box("Turf", Vector3(s * 28.8, h_mid + 0.18, zc), Vector3(4.2, 0.12, blen - 2.0))
			lm.box("Hedge", Vector3(s * 26.6, h_mid + 0.44, zc), Vector3(0.55, 0.50, blen - 1.8))
			lm.box("Hedge", Vector3(s * 31.0, h_mid + 0.44, zc), Vector3(0.55, 0.50, blen - 1.8))
			lm.box("Hedge", Vector3(s * 28.8, h_mid + 0.44, z0 + 1.1), Vector3(4.6, 0.50, 0.55))
			lm.box("Hedge", Vector3(s * 28.8, h_mid + 0.44, z1 - 1.1), Vector3(4.6, 0.50, 0.55))
			lm.box("Hedge", Vector3(s * 28.8, h_mid + 0.38, zc), Vector3(2.6, 0.38, 0.48))
			_topiary_cone(lm, Vector3(s * 28.8, h_mid + 0.24, zc - 4.0), 0.56, 1.38)
			_topiary_cone(lm, Vector3(s * 28.8, h_mid + 0.24, zc + 4.0), 0.56, 1.38)
			# Outer coping wall & clipped French hornbeam/boxwood hedge meeting the park bosquets
			lm.box("Stone", Vector3(s * 32.6, h_outer * 0.5, zc), Vector3(2.2, h_outer, blen))
			lm.box("Pave", Vector3(s * 32.6, h_outer + 0.08, zc), Vector3(2.4, 0.16, blen))
			lm.box("Hedge", Vector3(s * 32.6, h_outer + 0.62, zc), Vector3(1.35, 0.96, blen - 0.6))

	# 5. Four-Tier Art Deco Upper Cascade (z = -55..-39 m, y = 3.1..7.6 m — fully visible from Parvis!)
	for ci in 4:
		var cy := 3.1 + float(ci) * 1.42
		var cz := -40.5 - float(ci) * 4.4
		var cw := 32.0 + float(ci) * 2.4
		lm.box("Ashlar", Vector3(0.0, cy * 0.5, cz), Vector3(cw + 2.4, cy, 4.8))
		lm.box("Stone", Vector3(0.0, cy + 0.20, cz + 2.15), Vector3(cw + 2.6, 0.48, 0.68))
		for sx in [-1.0, 1.0]:
			lm.box("Stone", Vector3(float(sx) * (cw * 0.5 + 0.85), cy + 0.32, cz), Vector3(1.3, 0.72, 4.8))
		lm.box("Water", Vector3(0.0, cy + 0.16, cz - 0.15), Vector3(cw - 0.4, 0.16, 3.9))

	# Flanking stepped stone stairs & hedges beside the upper cascade (|x| = 28.5 m, z = -56..-42 m)
	for sx in [-1.0, 1.0]:
		var s := float(sx)
		for st_i in 8:
			var t0 := float(st_i) / 8.0
			var sy := lerpf(2.8, 8.2, t0)
			var sz := lerpf(-42.5, -55.5, t0)
			lm.box("Pave", Vector3(s * 28.6, sy * 0.5, sz), Vector3(6.2, sy, 1.85))
			lm.box("Stone", Vector3(s * 28.6, sy + 0.06, sz + 0.80), Vector3(6.2, 0.14, 0.28))
		lm.box("Ashlar", Vector3(s * 32.6, 4.4, -49.0), Vector3(2.2, 8.8, 15.0))
		lm.box("Hedge", Vector3(s * 32.6, 9.25, -49.0), Vector3(1.35, 0.95, 14.4))

	# 6. Authentic Gilded-Bronze Sculptures Flanking the Cascade (crest y = 10.5 m):
	# Paul Jouve's Taureau & Daim (-X) and Georges Guyot's Chevaux & Chien (+X)
	for sx in [-1.0, 1.0]:
		var s := float(sx)
		var ped := Vector3(s * 20.8, 0.0, -45.0)
		lm.box("Ashlar", ped + Vector3(0.0, 3.1, 0.0), Vector3(5.2, 6.2, 6.2))
		lm.box("Stone", ped + Vector3(0.0, 6.4, 0.0), Vector3(5.7, 0.44, 6.7))
		lm.box("Stone", ped + Vector3(0.0, 6.95, 0.0), Vector3(4.2, 0.68, 5.2))
		_bronze_animal_group(lm, "Gilt", ped + Vector3(0.0, 7.30, 0.0), -s * 0.32, s < 0.0)

	lm.commit(model)
	_varsovie_water_flow(model)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-22.0, 3.5, -34.0), Vector3(-18.0, 9.5, -45.0), 64.0, 0.95, 56.0],
		[Vector3(22.0, 3.5, -34.0), Vector3(18.0, 9.5, -45.0), 64.0, 0.95, 56.0],
	])

static func _varsovie_water_flow(model: Node3D) -> void:
	var fk := FountainKit.new()
	var pool_y := 2.18
	var fwd := Vector3(0.0, 0.0, 1.0)
	# Four wide stepped Art Deco cascade weirs & 16 foaming vertical gerbes spilling into the pool.
	for ci in 4:
		var cy := 3.1 + float(ci) * 1.42
		var cz := -40.5 - float(ci) * 4.4
		var cw := 32.0 + float(ci) * 2.4
		var y_top := cy + 0.24
		var y_bot := pool_y if ci == 0 else (3.1 + float(ci - 1) * 1.42 + 0.24)
		var hw := (cw - 1.6) * 0.5
		fk.cascade_sheet(Vector3(-hw, 0.0, cz + 2.2), Vector3(hw, 0.0, cz + 2.2), y_top, y_bot, fwd, 0.48, 0.80)
		fk.splash_strip(Vector3(-hw, y_bot, cz + 2.6), Vector3(hw, y_bot, cz + 2.6), fwd, 1.6, 0.88)
		for gx in [-10.5, -3.5, 3.5, 10.5]:
			fk.jet_plume(Vector3(float(gx), y_top, cz - 0.2), 2.3, 0.13, 0.36)
	fk.mist_emitter(Vector3(0.0, pool_y + 0.5, -38.5), 2.5, 2.2, 5)

	# Twenty iconic Warsaw Water Cannons (2 flanking rows of 10) shooting long parabolic
	# foamy-white plumes forward & inward down the reflecting pool, leaving the central
	# mirror lane open to reflect the sky and Eiffel Tower.
	for j in 10:
		var jz := lerpf(-31.0, 41.0, float(j) / 9.0)
		for sx in [-1.0, 1.0]:
			var s := float(sx)
			var nozzle := Vector3(s * 14.3, pool_y + 0.34, jz + 0.45)
			var land := Vector3(s * 3.6, pool_y, jz + 16.5)
			fk.arc_stream(nozzle, land, 4.8, 0.22, 0.68, 0.96, 14)
			fk.arc_stream(nozzle + Vector3(0.0, -0.06, 0.0),
				Vector3(s * 6.8, pool_y, jz + 10.2), 2.6, 0.16, 0.48, 0.92, 10)
			fk.splash_ring(land, 2.5, 0.88)
			fk.splash_ring(Vector3(s * 6.8, pool_y, jz + 10.2), 1.6, 0.72)
			if j % 3 == 1:
				fk.mist_emitter(land + Vector3(0.0, 0.4, 0.0), 2.2, 1.9, 3)
	fk.commit(model)

## Pierced Lutetian-limestone balustrade along X with base plinth, balusters, piers & coping rail.
static func _balustrade_x(lm: LandmarkMesh, mat: String, x0: float, x1: float,
		y0: float, z: float, h: float) -> void:
	var span := absf(x1 - x0)
	var cx := (x0 + x1) * 0.5
	lm.box(mat, Vector3(cx, y0 + 0.10, z), Vector3(span, 0.20, 0.56))
	lm.box(mat, Vector3(cx, y0 + h - 0.08, z), Vector3(span + 0.12, 0.16, 0.62))
	var n := maxi(int(span / 1.35), 2)
	for i in n + 1:
		var x := lerpf(x0, x1, float(i) / float(n))
		var is_pier := i % 5 == 0 or i == n
		var w := 0.48 if is_pier else 0.18
		lm.box(mat, Vector3(x, y0 + h * 0.5, z), Vector3(w, h - 0.24, 0.48 if is_pier else 0.22))

## Pierced Lutetian-limestone balustrade along Z.
static func _balustrade_z(lm: LandmarkMesh, mat: String, x: float, y0: float,
		z0: float, z1: float, h: float) -> void:
	var span := absf(z1 - z0)
	var cz := (z0 + z1) * 0.5
	lm.box(mat, Vector3(x, y0 + 0.10, cz), Vector3(0.56, 0.20, span))
	lm.box(mat, Vector3(x, y0 + h - 0.08, cz), Vector3(0.62, 0.16, span + 0.12))
	var n := maxi(int(span / 1.5), 2)
	for i in n + 1:
		var z := lerpf(z0, z1, float(i) / float(n))
		var is_pier := i % 4 == 0 or i == n
		var d := 0.48 if is_pier else 0.18
		lm.box(mat, Vector3(x, y0 + h * 0.5, z), Vector3(0.48 if is_pier else 0.22, h - 0.24, d))

## Clipped dark-emerald conical Taxus yew topiary in a carved limestone Versailles planter box.
static func _yew_planter(lm: LandmarkMesh, base: Vector3, h: float) -> void:
	lm.box("Stone", base + Vector3(0.0, 0.34, 0.0), Vector3(1.35, 0.68, 1.35))
	lm.box("Ashlar", base + Vector3(0.0, 0.72, 0.0), Vector3(1.50, 0.10, 1.50))
	_topiary_cone(lm, base + Vector3(0.0, 0.76, 0.0), 0.60, h)

static func _topiary_cone(lm: LandmarkMesh, base: Vector3, r: float, h: float) -> void:
	lm.lathe("Yew", base, PackedVector2Array([
		Vector2(r * 0.82, 0.0), Vector2(r, h * 0.14), Vector2(r * 0.78, h * 0.48),
		Vector2(r * 0.46, h * 0.78), Vector2(r * 0.16, h * 0.94), Vector2(0.0, h),
	]), 10)

## Sculpted gilded-bronze Art Deco animal group (Jouve's Taureau & Daim / Guyot's Chevaux & Chien).
static func _bronze_animal_group(lm: LandmarkMesh, mat: String, base: Vector3,
		yaw: float, bull_variant: bool) -> void:
	var b := Basis(Vector3.UP, yaw)
	var p := func(v: Vector3) -> Vector3:
		return base + b * v
	var body_h := 1.55 if bull_variant else 1.75
	lm.beam(mat, p.call(Vector3(-0.35, body_h, -0.95)), p.call(Vector3(-0.35, body_h + 0.25, 0.95)),
		0.95 if bull_variant else 0.78, 1.05 if bull_variant else 0.88)
	lm.beam(mat, p.call(Vector3(-0.35, body_h + 0.20, 0.85)),
		p.call(Vector3(-0.35, body_h + (0.75 if bull_variant else 1.15), 1.55)), 0.62, 0.68)
	lm.box(mat, p.call(Vector3(-0.35, body_h + (0.82 if bull_variant else 1.22), 1.88)),
		Vector3(0.46, 0.48, 0.78), b)
	if bull_variant:
		for hs in [-1.0, 1.0]:
			lm.beam(mat, p.call(Vector3(-0.35 + float(hs) * 0.22, body_h + 1.02, 1.85)),
				p.call(Vector3(-0.35 + float(hs) * 0.62, body_h + 1.38, 2.05)), 0.10, 0.10)
	for lx in [-0.65, -0.05]:
		lm.beam(mat, p.call(Vector3(float(lx), body_h - 0.1, -0.85)),
			p.call(Vector3(float(lx), 0.0, -0.98)), 0.22, 0.22)
		lm.beam(mat, p.call(Vector3(float(lx), body_h + 0.1, 0.82)),
			p.call(Vector3(float(lx), 0.25 if lx > -0.3 else 0.0, 1.12)), 0.20, 0.20)
	lm.beam(mat, p.call(Vector3(0.75, 1.05, -0.35)), p.call(Vector3(0.75, 1.25, 0.75)), 0.42, 0.46)
	lm.beam(mat, p.call(Vector3(0.75, 1.22, 0.68)), p.call(Vector3(0.75, 1.88, 1.12)), 0.26, 0.28)
	for lx in [0.58, 0.92]:
		lm.beam(mat, p.call(Vector3(float(lx), 1.0, -0.30)), p.call(Vector3(float(lx), 0.0, -0.52)), 0.12, 0.12)
		lm.beam(mat, p.call(Vector3(float(lx), 1.18, 0.68)), p.call(Vector3(float(lx), 0.15, 0.95)), 0.11, 0.11)
	lm.box(mat, base + Vector3(0.0, 0.10, 0.0), Vector3(3.2, 0.20, 4.2), b)
