class_name LandmarkSacreCoeur
extends RefCounted

## Sacré-Cœur in true metres, y = 0 on the parvis at the top of the
## Montmartre stairs.

## Sacré-Cœur (83 m; 85 x 35 m): Abadie's white Château-Landon
## travertine basilica (1875-1914) — the ovoid 16 m central dome on a
## drum ringed by an arcaded gallery, with its colonnaded lantern; four
## lesser domes; the triple-arched south porch carrying the bronze
## equestrian Joan of Arc and Saint Louis under the gable niche of the
## Sacred Heart; the apse with radiating chapels; and the Savoyarde
## campanile behind it (north, -Z).
static func sacre_coeur(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("White", LandmarkMaterials.pbr("limestone", "#E6E1D3", 3.0))
	lm.use("Steps", LandmarkMaterials.pbr("stone", "#B5AE9F", 3.0))
	lm.use("Glass", LandmarkMaterials.glass("#2A3338"))
	lm.use("Gilt", LandmarkMaterials.gold())
	lm.use("Bronze", LandmarkMaterials.paint("#4E5A4C", 0.5, 0.6))
	_body(lm)
	_main_dome(lm, Vector3(0, 28, 3.0))
	_porch(lm)
	_campanile(lm, Vector3(0, 0, -54.0))
	lm.commit(model)

## Latin-cross body, apse and radiating chapels with arched windows.
static func _body(lm: LandmarkMesh) -> void:
	LandmarkWestKit.blk(lm, "White", 0, 0.0, 0, 28.0, 28.0, 62.0)
	LandmarkWestKit.blk(lm, "White", 0, 0.0, 3.0, 52.0, 28.0, 22.0)
	LandmarkWestKit.blk(lm, "White", 0, 0.0, 0, 29.0, 0.9, 63.0)
	LandmarkWestKit.blk(lm, "White", 0, 0.0, 3.0, 53.0, 0.9, 23.0)
	for sx in [-1.0, 1.0]:
		var n := Vector3(sx, 0, 0)
		# Nave flanks: buttress piers and two tiers of round-arched windows.
		for k in 4:
			var z := -27.0 + 5.5 * float(k)
			LandmarkDetail.window(lm, "White", "Glass", Vector3(sx * 14.0, 9.0, z), n, 2.4, 6.0, true)
			LandmarkDetail.window(lm, "White", "Glass", Vector3(sx * 14.0, 20.0, z), n, 2.0, 5.0, true)
		for k in 5:
			lm.box("White", Vector3(sx * 14.4, 13.5, -29.8 + 5.5 * float(k)), Vector3(0.8, 27.0, 1.4))
		# Transept ends with rose-like oculus and twin windows.
		var f := Vector3(sx * 26.0, 0, 3.0)
		lm.disc("Glass", f + Vector3(sx * 0.05, 20.0, 0), n, 3.0, 20)
		LandmarkDetail.arch(lm, "White", f + Vector3(0, 20.0, 0) - Vector3(0, 0, 0), n, 6.0, 0.6)
		for wz in [-4.5, 4.5]:
			LandmarkDetail.window(lm, "White", "Glass", f + Vector3(0, 8.5, wz), n, 2.6, 7.0, true)
		LandmarkDetail.cornice(lm, "White", Vector3(sx * 14.0, 27.0, -31.0), Vector3(sx * 14.0, 27.0, -8.0), n, 1.0)
		LandmarkDetail.cornice(lm, "White", f + Vector3(0, 27.0, -11.0), f + Vector3(0, 27.0, 11.0), n, 1.0)
	# Apse with five radiating chapels and their half-domes.
	lm.lathe("White", Vector3(0, 0, -31.0), PackedVector2Array([Vector2(14, 0), Vector2(14, 28)]), 18,
		1.0, 1.0, 0.0, false)
	lm.lathe("White", Vector3(0, 28, -31.0), LandmarkWestKit.dome_prof(14.0, 9.0, 7, 1.5), 18)
	for k in 5:
		var a := PI + PI * (float(k) + 0.5) / 5.0
		var d := Vector3(cos(a), 0, sin(a))
		var p := Vector3(0, 0, -31.0) + d * 14.5
		lm.frustum("White", p, 4.2, 4.2, 16.0, 14)
		lm.lathe("White", p + Vector3(0, 16, 0), LandmarkWestKit.dome_prof(4.4, 3.4, 5), 14)
		LandmarkWestKit.cross(lm, "Gilt", p + Vector3(0, 19.3, 0), 1.4)
		LandmarkDetail.window(lm, "White", "Glass", p + d * 4.2 + Vector3(0, 8.0, 0), d, 1.6, 4.6, true)
	# Four lesser domes and the two facade turrets, with lanterns.
	for p in [Vector2(-15, -9), Vector2(15, -9), Vector2(-15, 15), Vector2(15, 15),
			Vector2(-12, 27), Vector2(12, 27)]:
		var b := Vector3(p.x, 28, p.y)
		var front := absf(p.y) > 20.0
		var r := 3.0 if front else 4.3
		LandmarkWestKit.small_dome(lm, "White", "White", "Glass", b, r, 6.0, 7.0, 3.0, 8, 1.3)
		LandmarkWestKit.cross(lm, "Gilt", b + Vector3(0, 16.0, 0), 2.0)

## Central drum with its arcaded gallery, ovoid dome, ribs, lantern.
static func _main_dome(lm: LandmarkMesh, c: Vector3) -> void:
	lm.frustum("White", c, 9.5, 9.5, 14.0, 32)
	lm.frustum("White", c, 11.6, 11.6, 0.8, 32)
	lm.frustum("White", c + Vector3(0, 9.6, 0), 11.6, 11.5, 0.9, 32)
	for k in 16:
		var a := TAU * float(k) / 16.0
		var d := Vector3(cos(a), 0, sin(a))
		LandmarkDetail.window(lm, "White", "Glass", c + d * 9.5 + Vector3(0, 4.5, 0), d, 1.5, 4.6, true)
		# Gallery column pairs carrying round arches.
		var a2 := a + PI / 16.0
		var d2 := Vector3(cos(a2), 0, sin(a2))
		LandmarkWestKit.shaft(lm, "White", c + d2 * 11.0 + Vector3(0, 0.8, 0), 0.32, 7.4)
		var d3 := Vector3(cos(a2 + TAU / 16.0), 0, sin(a2 + TAU / 16.0))
		var mid := (d2 + d3).normalized()
		LandmarkWestKit.round_arch(lm, "White", c + mid * 11.0 * cos(PI / 16.0) + Vector3(0, 8.2, 0), mid,
			d2.distance_to(d3) * 11.0 - 0.6, 0.45)
		lm.box("White", c + Vector3(cos(a), 13.0, sin(a)) * Vector3(9.8, 1.0, 9.8) + Vector3(0, 0, 0),
			Vector3(1.0, 2.0, 0.6), Basis(Vector3.UP, -a + PI * 0.5))
	lm.lathe("White", c + Vector3(0, 13.2, 0), PackedVector2Array([Vector2(9.5, 0), Vector2(10.1, 0.5),
		Vector2(10.3, 0.8)]), 32)
	# Ovoid dome with sixteen ribs.
	var prof := LandmarkWestKit.dome_prof(9.7, 26.0, 14, 1.5)
	lm.lathe("White", c + Vector3(0, 14, 0), prof, 32)
	for k in 16:
		var d := Vector3(cos(TAU * float(k) / 16.0), 0, sin(TAU * float(k) / 16.0))
		for j in prof.size() - 3:
			lm.beam("White", c + Vector3(0, 14, 0) + d * (prof[j].x + 0.15) + Vector3(0, prof[j].y, 0),
				c + Vector3(0, 14, 0) + d * (prof[j + 1].x + 0.15) + Vector3(0, prof[j + 1].y, 0), 0.55, 0.4)
	# Lantern: eight columns round a core, cupola, cross (83 m).
	var lb := c + Vector3(0, 39.0, 0)
	lm.frustum("White", lb, 3.2, 3.0, 1.0, 16)
	lm.frustum("White", lb + Vector3(0, 1.0, 0), 2.0, 2.0, 7.0, 16)
	for i in 8:
		var a := TAU * float(i) / 8.0
		lm.frustum("White", lb + Vector3(cos(a), 0, sin(a)) * 2.6 + Vector3(0, 1.0, 0), 0.25, 0.22, 7.0, 8)
	lm.frustum("White", lb + Vector3(0, 8.0, 0), 3.0, 3.1, 1.0, 16)
	lm.lathe("White", lb + Vector3(0, 9.0, 0), LandmarkWestKit.dome_prof(2.6, 3.0, 6, 1.4), 16)
	lm.lathe("Gilt", lb + Vector3(0, 11.8, 0), LandmarkWestKit.ball(0.35), 8)
	LandmarkWestKit.cross(lm, "Gilt", lb + Vector3(0, 12.4, 0), 3.6)

## South porch: three arches, gable niche, equestrian bronzes, stairs.
static func _porch(lm: LandmarkMesh) -> void:
	var n := Vector3(0, 0, 1)
	LandmarkWestKit.blk(lm, "White", 0, 0.0, 31.5, 30.0, 14.0, 5.0)
	LandmarkWestKit.blk(lm, "White", 0, 14.0, 31.5, 31.0, 1.0, 5.6)
	for x in [-8.0, 0.0, 8.0]:
		lm.box("Glass", Vector3(x, 4.5, 34.05), Vector3(5.0, 9.0, 0.1), Basis(), 0.0)
		LandmarkDetail.arch(lm, "White", Vector3(x, 9.0, 34.0), n, 5.6, 0.7, 0.5)
	for x in [-12.0, -4.0, 4.0, 12.0]:
		LandmarkDetail.column(lm, "White", Vector3(x, 0.0, 34.6), 0.5, 9.0, "corinthian", 0)
	# Gable with the Sacred Heart in its niche.
	LandmarkWestKit.blk(lm, "White", 0, 15.0, 31.5, 12.0, 5.0, 4.0)
	lm.gable("White", Vector3(0, 20.0, 31.5), 12.0, 4.0, 4.5, Basis(), 0.3, "White")
	LandmarkDetail.arch(lm, "White", Vector3(0, 18.5, 33.5), n, 3.0, 0.4)
	LandmarkKits.statue_figure(lm, "Bronze", Vector3(0, 15.3, 33.0), 4.0, true)
	LandmarkDetail.balustrade(lm, "White", Vector3(-15.0, 15.0, 33.8), Vector3(-6.0, 15.0, 33.8), 1.0, 3.0)
	LandmarkDetail.balustrade(lm, "White", Vector3(6.0, 15.0, 33.8), Vector3(15.0, 15.0, 33.8), 1.0, 3.0)
	# Joan of Arc and Saint Louis on horseback on their pedestals.
	for x in [-11.0, 11.0]:
		LandmarkWestKit.blk(lm, "White", x, 15.0, 32.0, 3.0, 1.5, 4.0)
		var hb := Vector3(x, 16.5, 32.0)
		lm.beam("Bronze", hb + Vector3(0, 1.6, -1.1), hb + Vector3(0, 1.8, 1.0), 0.9, 1.1)
		for lz in [-0.9, 0.9]:
			for lx in [-0.3, 0.3]:
				lm.beam("Bronze", hb + Vector3(lx, 1.4, lz), hb + Vector3(lx, 0.0, lz + 0.1), 0.18)
		lm.beam("Bronze", hb + Vector3(0, 2.1, 1.0), hb + Vector3(0, 2.9, 1.6), 0.4, 0.5)
		LandmarkKits.statue_figure(lm, "Bronze", hb + Vector3(0, 1.8, -0.1), 2.0, true)
	# Parvis stairs rising to the porch, with balustrade cheeks.
	for k in 6:
		LandmarkWestKit.blk(lm, "Steps", 0, 0.0, 35.0 + 1.0 * float(5 - k) + 0.5, 34.0 - 0.8 * float(k), 0.25 * float(k + 1), 1.0)
	for sx in [-1.0, 1.0]:
		LandmarkWestKit.rail(lm, "White", Vector3(sx * 17.5, 0.0, 41.0), Vector3(sx * 17.5, 0.0, 34.5), 1.1, 0.5)

## The Savoyarde campanile: shaft, belfry stage, dome and lantern.
static func _campanile(lm: LandmarkMesh, c: Vector3) -> void:
	LandmarkWestKit.blk(lm, "White", c.x, 0.0, c.z, 12.5, 62.0, 12.5)
	LandmarkWestKit.blk(lm, "White", c.x, 62.0, c.z, 10.5, 11.0, 10.5)
	for side in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * float(side))
		var n: Vector3 = r * Vector3(0, 0, 1)
		for k in 3:
			LandmarkDetail.window(lm, "White", "Glass", c + n * 6.25 + Vector3(0, 14.0 + 14.0 * float(k), 0),
				n, 1.4, 4.0, true)
		LandmarkDetail.window(lm, "White", "Glass", c + n * 5.25 + Vector3(0, 67.5, 0), n, 3.2, 7.0, true)
		LandmarkDetail.cornice(lm, "White", c + n * 6.25 + r * Vector3(-6.25, 61.0, 0), c + n * 6.25 + r * Vector3(6.25, 61.0, 0),
			n, 1.0, false)
		for s in [-1.0, 1.0]:
			lm.box("White", c + n * 6.4 + r * Vector3(s * 5.6, 31.0, 0), Vector3(1.2, 62.0, 0.4), r)
	lm.lathe("White", c + Vector3(0, 73, 0), LandmarkWestKit.dome_prof(5.4, 5.4, 8, 1.4), 16)
	lm.frustum("White", c + Vector3(0, 78.2, 0), 1.0, 0.9, 1.6, 8)
	LandmarkWestKit.cross(lm, "Gilt", c + Vector3(0, 79.8, 0), 2.4)
