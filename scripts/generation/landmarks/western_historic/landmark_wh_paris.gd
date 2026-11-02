class_name LandmarkWhParis
extends RefCounted

## Two Paris landmarks of the western historic batch in true metres,
## y = 0 at the street: the Sainte-Chapelle and the Palais Garnier.

## Sainte-Chapelle (75.5 m to the cross of the spire): the Rayonnant
## palace chapel on the Île de la Cité, nave along X with the west
## porch at -X. Lower chapel, the glazed upper chapel between its
## buttresses with the gablet over every bay, the steep lead roof
## (ridge 42.5 m), the seven-sided apse, the west rose window and the
## slender lead flèche of 1853 over the roof.
static func sainte_chapelle(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#CDBE9E", 3.0))
	lm.use("Lead", LandmarkMaterials.pbr("slate", "#59626A", 2.5))
	lm.use("Glass", LandmarkMaterials.glass("#26385C"))
	lm.use("Gilt", LandmarkMaterials.gold())
	var rot := Basis(Vector3.UP, PI * 0.5)
	var hw := 6.15
	# Lower chapel and the upper-chapel wall, 36 m long with the porch.
	LandmarkWestKit.blk(lm, "Stone", 0, 0, 0, 24.0, 27.0, hw * 2.0)
	for sz in [-1.0, 1.0]:
		var n := Vector3(0, 0, sz)
		for b in 4:
			var x := -9.0 + 6.0 * float(b)
			LandmarkWhKit.lancet(lm, "Glass", Vector3(x, 2.4, sz * (hw + 0.1)), n, 1.4, 2.6, 1.2)
			LandmarkWhKit.lancet(lm, "Glass", Vector3(x, 9.0, sz * (hw + 0.1)), n, 4.2, 12.5, 3.8)
			for mx in [-1.05, 1.05]:
				LandmarkWestKit.blk(lm, "Stone", x + mx, 9.0, sz * (hw + 0.2), 0.2, 14.0, 0.25)
			# Gablet over the bay crossing the roof balustrade.
			lm.gable("Stone", Vector3(x, 26.0, sz * (hw + 0.4)), 4.6, 3.6, 8.0, Basis(), 0.0, "Stone")
		for p in 5:
			var px := -12.0 + 6.0 * float(p)
			LandmarkWestKit.blk(lm, "Stone", px, 0, sz * (hw + 0.85), 1.4, 27.0, 1.8)
			LandmarkWhKit.pinnacle(lm, "Stone", Vector3(px, 27.0, sz * (hw + 0.85)), 0.55, 2.0, 4.0)
		LandmarkWestKit.blk(lm, "Stone", 0, 8.0, sz * (hw + 0.1), 24.0, 0.7, 0.4)
	lm.gable("Lead", Vector3(0, 27.0, 0), hw * 2.0, 25.0, 15.5, rot, 0.5, "Stone")
	# Seven-sided apse, windows on the five eastern faces, conical roof.
	var rv := 6.44
	var ap := rv * cos(PI / 7.0)
	lm.lathe("Stone", Vector3(12, 0, 0), PackedVector2Array([Vector2(rv, 0), Vector2(rv, 27.0)]), 7,
		1.0, 1.0, PI / 7.0, false)
	for k in [-2, -1, 0, 1, 2]:
		var psi := TAU * float(k) / 7.0
		var d := Vector3(cos(psi), 0, sin(psi))
		LandmarkWhKit.lancet(lm, "Glass", Vector3(12, 9.0, 0) + d * (ap + 0.1), d, 3.4, 11.5, 3.2)
		var vd := Vector3(cos(psi + PI / 7.0), 0, sin(psi + PI / 7.0))
		LandmarkWestKit.blk(lm, "Stone", 12.0 + vd.x * (rv + 0.6), 0, vd.z * (rv + 0.6), 1.3, 27.0, 1.3)
		LandmarkWhKit.pinnacle(lm, "Stone", Vector3(12.0 + vd.x * (rv + 0.6), 27.0, vd.z * (rv + 0.6)),
			0.5, 1.5, 3.5)
	lm.lathe("Lead", Vector3(12, 27.0, 0), PackedVector2Array([Vector2(rv + 0.5, 0), Vector2(0, 15.5)]), 7,
		1.0, 1.0, PI / 7.0, false)
	# West porch (two storeys), rose window, flanking turrets.
	LandmarkWestKit.blk(lm, "Stone", -15.0, 0, 0, 6.0, 11.0, hw * 2.0)
	LandmarkWhKit.lancet(lm, "Glass", Vector3(-18.1, 0, 0), Vector3(-1, 0, 0), 5.0, 5.0, 4.0)
	for sz in [-1.0, 1.0]:
		LandmarkWhKit.lancet(lm, "Glass", Vector3(-15.0, 0, sz * (hw + 0.1)), Vector3(0, 0, sz), 3.6, 4.0, 3.0)
		LandmarkWestKit.blk(lm, "Stone", -17.2, 0, sz * 6.6, 2.4, 30.0, 2.4)
		lm.spire("Stone", Vector3(-17.2, 30.0, sz * 6.6), 1.5, 8.0)
	lm.gable("Stone", Vector3(-15.0, 11.0, 0), hw * 2.0, 6.0, 5.5, rot, 0.0, "Stone")
	LandmarkWhKit.rose(lm, "Glass", "Stone", Vector3(-12.6, 21.5, 0), Vector3(-1, 0, 0), 4.2, 16)
	# The flèche: lead drum with gablets and pinnacles, then the needle.
	var sb := Vector3(2.0, 41.0, 0)
	lm.lathe("Lead", sb, PackedVector2Array([Vector2(3.0, 0), Vector2(3.0, 7.5), Vector2(2.5, 7.5),
		Vector2(2.1, 12.0), Vector2(1.6, 18.0), Vector2(1.1, 24.0), Vector2(0.7, 28.5), Vector2(0.4, 31.5),
		Vector2(0.0, 33.0)]), 8, 1.0, 1.0, PI / 8.0, false)
	for k in 8:
		var a := TAU * float(k) / 8.0
		LandmarkWhKit.pinnacle(lm, "Lead", sb + Vector3(cos(a) * 3.3, 7.5, sin(a) * 3.3), 0.3, 1.6, 3.2)
	for q in [Vector2(2.6, 0), Vector2(-2.6, 0)]:
		lm.gable("Stone", sb + Vector3(q.x, 3.0, 0), 2.0, 1.6, 4.0, rot, 0.0, "Stone")
	for q in [Vector2(0, 2.6), Vector2(0, -2.6)]:
		lm.gable("Stone", sb + Vector3(0, 3.0, q.y), 2.0, 1.6, 4.0, Basis(), 0.0, "Stone")
	LandmarkWhKit.ball(lm, "Gilt", sb + Vector3(0, 32.7, 0), 0.4)
	LandmarkWestKit.cross(lm, "Gilt", sb + Vector3(0, 33.0, 0), 1.6)
	lm.commit(model)

## Palais Garnier (56 m to the Apollo group): the Beaux-Arts opera
## house, front (south, +Z) of seven arches, the coupled-column loggia
## and gilded groups on the avant-corps, the two lateral pavilions,
## the auditorium block under its low verdigris dome, and the stage
## house behind with its pediment crowned by the golden Apollo group.
static func palais_garnier(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#D3C6A6", 3.5))
	lm.use("Column", LandmarkMaterials.pbr("stone", "#A8906F", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("slate", "#4C555B", 2.5))
	lm.use("Dome", LandmarkMaterials.pbr("slate", "#6F9A86", 2.5))
	lm.use("Glass", LandmarkMaterials.glass("#2A3338"))
	lm.use("Gilt", LandmarkMaterials.gold())
	var fz := 64.0
	for k in 3:
		LandmarkWestKit.blk(lm, "Stone", 0, 0, fz + 3.0 - 0.9 * float(k), 76.0 - 2.0 * float(k),
			0.5 * float(k + 1), 6.0 - 1.8 * float(k))
	# Front block: arcade of seven arches, loggia, entablature, attic.
	LandmarkWestKit.blk(lm, "Stone", 0, 0, 47.0, 72.0, 9.5, 34.0)
	LandmarkWestKit.blk(lm, "Stone", 0, 9.5, 44.0, 72.0, 20.5, 28.0)
	LandmarkWestKit.blk(lm, "Stone", 0, 9.5, 61.0, 72.0, 0.7, 6.0)
	LandmarkWestKit.blk(lm, "Stone", 0, 10.2, 63.6, 64.0, 1.0, 0.6)
	for k in 7:
		var x := -27.0 + 9.0 * float(k)
		LandmarkWhKit.arch_round(lm, "Glass", Vector3(x, 0.8, fz + 0.12), Vector3(0, 0, 1), 6.0, 4.5)
		LandmarkWestKit.blk(lm, "Stone", x + 4.5, 0, fz + 0.3, 1.6, 9.5, 0.7)
		if k < 6:
			LandmarkWhKit.arch_round(lm, "Glass", Vector3(x + 4.5, 11.0, 58.1), Vector3(0, 0, 1), 4.2, 6.0)
	for k in 8:
		var x := -28.0 + 8.0 * float(k)
		for dx in [-1.0, 1.0]:
			lm.frustum("Column", Vector3(x + dx, 10.2, 62.6), 0.72, 0.62, 12.8, 10)
			LandmarkWestKit.blk(lm, "Stone", x + dx, 23.0, 62.6, 1.9, 0.5, 1.9)
	LandmarkWestKit.blk(lm, "Stone", 0, 23.0, 60.0, 74.0, 2.9, 8.4)
	LandmarkWestKit.blk(lm, "Gilt", 0, 25.4, 64.3, 72.0, 0.5, 0.1)
	LandmarkWestKit.blk(lm, "Stone", 0, 25.9, 59.0, 72.0, 3.6, 6.0)
	LandmarkWestKit.blk(lm, "Roof", 0, 29.5, 46.0, 72.0, 0.8, 32.0)
	# Avant-corps at each end with the gilded groups on pedestals.
	for sx in [-1.0, 1.0]:
		LandmarkWestKit.blk(lm, "Stone", sx * 34.25, 9.5, 61.0, 5.5, 20.0, 7.0)
		LandmarkWestKit.blk(lm, "Stone", sx * 34.25, 29.5, 61.0, 6.0, 1.0, 7.5)
		LandmarkWestKit.blk(lm, "Stone", sx * 34.25, 30.5, 61.0, 2.4, 1.5, 2.4)
		LandmarkKits.statue_figure(lm, "Gilt", Vector3(sx * 34.25, 32.0, 61.0), 3.6, true)
		LandmarkWhKit.arch_round(lm, "Glass", Vector3(sx * 34.25, 12.0, 64.55), Vector3(0, 0, 1), 2.2, 5.0)
	# Lateral pavilions: east block with arcade, west rotunda under a dome.
	LandmarkWestKit.blk(lm, "Stone", 44.0, 0, 28.0, 16.0, 24.0, 50.0)
	LandmarkWestKit.hip(lm, "Roof", Vector3(44.0, 24.0, 28.0), 17.0, 51.0, 5.0, 0.5)
	for k in 4:
		LandmarkWhKit.arch_round(lm, "Glass", Vector3(52.1, 0.8, 12.0 + 12.0 * float(k)), Vector3(1, 0, 0), 5.0, 6.0)
	lm.lathe("Stone", Vector3(-47.0, 0, 28.0), PackedVector2Array([Vector2(10.5, 0), Vector2(10.5, 24.0)]), 20)
	lm.lathe("Dome", Vector3(-47.0, 24.0, 28.0), LandmarkWestKit.dome_prof(11.0, 6.0, 6), 20)
	LandmarkWestKit.blk(lm, "Stone", -44.0, 0, 6.0, 16.0, 24.0, 20.0)
	LandmarkWestKit.hip(lm, "Roof", Vector3(-44.0, 24.0, 6.0), 17.0, 21.0, 5.0, 0.5)
	# Auditorium block with the copper dome, then the stage house.
	LandmarkWestKit.blk(lm, "Stone", 0, 0, 9.0, 68.0, 33.0, 42.0)
	LandmarkWestKit.blk(lm, "Roof", 0, 33.0, 9.0, 66.0, 0.8, 40.0)
	lm.frustum("Stone", Vector3(0, 33.8, 6.0), 12.8, 12.8, 3.4, 28)
	lm.lathe("Dome", Vector3(0, 37.2, 6.0), LandmarkWestKit.dome_prof(13.0, 9.0, 8), 28)
	lm.frustum("Stone", Vector3(0, 46.0, 6.0), 2.2, 2.0, 2.0, 12)
	lm.lathe("Dome", Vector3(0, 48.0, 6.0), LandmarkWestKit.dome_prof(2.4, 2.4, 5), 12)
	LandmarkWestKit.blk(lm, "Stone", 0, 0, -46.0, 48.0, 41.0, 68.0)
	lm.gable("Roof", Vector3(0, 41.0, -46.0), 48.0, 68.0, 9.0, Basis(), 0.4, "Stone")
	for k in 3:
		LandmarkWhKit.arch_round(lm, "Glass", Vector3(-12.0 + 12.0 * float(k), 34.0, -11.85), Vector3(0, 0, 1),
			5.0, 4.0)
	LandmarkWestKit.blk(lm, "Stone", 0, 0, -88.0, 60.0, 27.0, 16.0)
	LandmarkWestKit.hip(lm, "Roof", Vector3(0, 27.0, -88.0), 61.0, 17.0, 4.0, 0.5)
	# Apollo group on the stage-house pediment (56 m).
	LandmarkWestKit.blk(lm, "Stone", 0, 49.6, -12.0, 3.4, 1.6, 3.0)
	LandmarkKits.statue_figure(lm, "Gilt", Vector3(0, 51.2, -12.0), 4.8, true)
	for sx in [-6.5, 6.5]:
		LandmarkWestKit.blk(lm, "Stone", sx, 46.0, -12.0, 2.2, 1.2, 2.2)
		LandmarkKits.statue_figure(lm, "Gilt", Vector3(sx, 47.2, -12.0), 3.4)
	LandmarkWhKit.shift(lm, Vector3(0, 0, 13.0))
	lm.commit(model)
