class_name LandmarkAmhCathedral
extends RefCounted

## Mexico City's Metropolitan Cathedral on the Zocalo in true metres,
## built with the main (south) facade toward +Z.

const CATHEDRAL_TOP_M := 67.0

## Metropolitan Cathedral (1573-1813): the grey-stone church (59 m wide,
## about 120 m long) on its raised atrium; chapels and aisles with
## buttresses, arched windows and Tolsa's balustrade of urns along the
## roof edge, the aisle vaults' rows of small lanterned cupolas, the
## raised nave and transept with clerestory windows; the south front's
## three-tier Baroque central portal with its paired columns, Tolsa's
## clock tower crowned by Faith, Hope and Charity, the side portals and
## the two 67 m bell towers (two belfry stages with balustrades and
## urns, bell-shaped crowns, lanterns and crosses); and Tolsa's
## ribbed dome on its windowed, column-ringed drum over the crossing.
static func mexico_city_cathedral(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#8F8B80", 4.0))
	lm.use("Carved", LandmarkMaterials.pbr("limestone", "#B9B2A0", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("slate", "#6F7473", 3.0))
	lm.use("Dome", LandmarkMaterials.pbr("slate", "#8E9892", 3.0))
	lm.use("Windows", LandmarkMaterials.glass("#2A3236"))
	lm.use("Gold", LandmarkMaterials.gold())
	# Atrium platform, the body of chapels and aisles, the raised nave
	# and transept and their roofs.
	lm.box("Stone", Vector3(0, 0.5, 3.0), Vector3(66.0, 1.0, 128.0))
	lm.box("Stone", Vector3(0, 11.5, 0), Vector3(59.0, 21.0, 118.0))
	lm.box("Roof", Vector3(0, 22.1, 0), Vector3(59.4, 0.4, 118.4))
	lm.box("Stone", Vector3(0, 28.0, -6.0), Vector3(24.0, 12.0, 104.0))
	lm.box("Stone", Vector3(0, 28.0, 2.0), Vector3(59.0, 12.0, 24.0))
	lm.gable("Roof", Vector3(0, 34.0, -6.0), 24.0, 104.0, 2.5, Basis(), 0.3)
	lm.gable("Roof", Vector3(0, 34.0, 2.0), 24.0, 59.0, 2.5, Basis(Vector3.UP, PI * 0.5), 0.3)
	for s in [-1.0, 1.0]:
		var n := Vector3(s, 0, 0)
		for i in 16:
			var z := -55.5 + 7.4 * float(i)
			# Buttress with its pinnacle, then the chapel window beside it.
			lm.box("Stone", Vector3(s * 30.1, 11.0, z), Vector3(1.2, 20.0, 1.8))
			lm.box("Carved", Vector3(s * 29.6, 23.0, z), Vector3(1.2, 1.4, 1.2))
			lm.lathe("Carved", Vector3(s * 29.6, 23.7, z),
				PackedVector2Array([Vector2(0.45, 0.0), Vector2(0.6, 0.4), Vector2(0.35, 1.0),
				Vector2(0.15, 1.6), Vector2(0.0, 2.0)]), 8)
			if i < 15 and absf(z + 3.7 - 2.0) > 9.0:
				LandmarkDetail.window(lm, "Carved", "Windows", Vector3(s * 29.5, 13.5, z + 3.7), n, 2.2,
					4.6, true, 0.3)
		LandmarkNaParts.balusters(lm, "Carved", Vector3(s * 29.3, 22.3, -58.0),
			Vector3(s * 29.3, 22.3, 44.0), 1.1, 0.6, 7.4)
		for i in 12:
			var z := -54.0 + 8.4 * float(i)
			if absf(z - 2.0) < 13.0:
				continue
			LandmarkDetail.window(lm, "Carved", "Windows", Vector3(s * 12.0, 28.5, z), n, 2.0, 4.2,
				true, 0.3)
		# A row of lanterned cupolas over the aisle vaults.
		for i in 8:
			var z := -50.0 + 12.4 * float(i)
			if absf(z - 2.0) < 13.0:
				continue
			_cupola(lm, Vector3(s * 19.5, 22.3, z), 2.4)
		# Transept end portal.
		var tp := Vector3(s * 29.5, 1.0, 2.0)
		var rb := Basis(Vector3.UP, s * PI * 0.5)
		lm.box("Carved", tp + rb * Vector3(0, 8.0, 0.6), Vector3(12.0, 16.0, 1.2), rb)
		LandmarkAmhParts.opening(lm, "Windows", tp + rb * Vector3(0, 3.5, 1.25), rb, 3.6, 7.0, 0.1)
		LandmarkDetail.arch(lm, "Carved", tp + rb * Vector3(0, 7.0, 1.2), rb * Vector3.BACK, 3.6, 0.6,
			0.4)
		for dx in [-4.2, -2.8, 2.8, 4.2]:
			LandmarkNaParts.column_lite(lm, "Carved", tp + rb * Vector3(dx, 0, 1.9), 0.4, 9.0, 1.0, 10)
		lm.box("Carved", tp + rb * Vector3(0, 9.6, 1.9), Vector3(10.6, 1.2, 1.4), rb)
	_cathedral_facade(lm)
	for s in [-1.0, 1.0]:
		_bell_tower(lm, s * 22.15)
	_cathedral_dome(lm, Vector3(0, 34.0, 2.0))
	lm.commit(model)

## Small aisle cupola at `c` (its foot on the roof): drum, dome and
## lantern with a ball finial.
static func _cupola(lm: LandmarkMesh, c: Vector3, r: float) -> void:
	lm.frustum("Carved", c, r, r, 1.2, 16)
	lm.frustum("Carved", c + Vector3(0, 1.2, 0), r * 1.08, r * 1.08, 0.25, 16)
	lm.lathe("Dome", c + Vector3(0, 1.45, 0),
		PackedVector2Array([Vector2(r, 0.0), Vector2(r * 0.92, r * 0.4), Vector2(r * 0.7, r * 0.75),
		Vector2(r * 0.38, r * 0.95), Vector2(r * 0.2, r)]), 16)
	lm.frustum("Carved", c + Vector3(0, 1.45 + r, 0), r * 0.22, r * 0.2, 0.9, 8)
	lm.lathe("Dome", c + Vector3(0, 2.35 + r, 0),
		PackedVector2Array([Vector2(r * 0.26, 0.0), Vector2(r * 0.15, 0.3), Vector2(0.0, 0.6)]), 8)

## Facade screen between the towers: the central three-tier portal
## (paired columns, door, relief panel, choir window, pediment), the
## two side portals, the statued balustrade and Tolsa's clock tower
## with Faith, Hope and Charity on top.
static func _cathedral_facade(lm: LandmarkMesh) -> void:
	lm.box("Stone", Vector3(0, 17.5, 56.0), Vector3(30.6, 33.0, 6.0))
	lm.box("Carved", Vector3(0, 13.0, 59.8), Vector3(12.0, 24.0, 1.6))
	# Lower tier: the round-arched door between paired columns.
	LandmarkAmhParts.opening(lm, "Windows", Vector3(0, 4.6, 60.65), Basis(), 4.6, 7.2, 0.1)
	LandmarkDetail.arch(lm, "Carved", Vector3(0, 8.2, 60.6), Vector3.BACK, 4.6, 0.6, 0.4)
	for x in [-6.6, -4.6, 4.6, 6.6]:
		lm.box("Carved", Vector3(x, 1.8, 61.4), Vector3(1.6, 1.6, 1.6))
		LandmarkDetail.column(lm, "Carved", Vector3(x, 2.6, 61.4), 0.55, 9.4, "corinthian", 0)
	lm.box("Carved", Vector3(0, 12.6, 61.3), Vector3(16.0, 1.2, 2.6))
	LandmarkDetail.cornice(lm, "Carved", Vector3(-8.0, 13.2, 62.6), Vector3(8.0, 13.2, 62.6),
		Vector3.BACK, 0.8, true)
	# Second tier: relief panel between columns, niches.
	lm.box("Carved", Vector3(0, 18.4, 60.7), Vector3(6.0, 7.6, 0.5))
	for x in [-4.6, 4.6]:
		LandmarkDetail.column(lm, "Carved", Vector3(x, 14.0, 61.2), 0.42, 7.6, "corinthian", 0)
	for x in [-6.4, 6.4]:
		lm.box("Carved", Vector3(x, 17.8, 60.8), Vector3(1.6, 3.4, 0.4))
		LandmarkKits.statue_figure(lm, "Carved", Vector3(x, 16.1, 61.3), 2.6)
	lm.box("Carved", Vector3(0, 21.9, 61.0), Vector3(13.0, 0.8, 1.8))
	# Third tier: the choir window and the pediment.
	lm.disc("Windows", Vector3(0, 24.5, 61.0), Vector3.BACK, 1.5, 20)
	LandmarkNaParts.ring(lm, "Carved", Vector3(0, 24.5, 61.0), 1.6, 0.4, 0.3, 24)
	lm.gable("Carved", Vector3(0, 26.4, 59.8), 12.0, 2.0, 2.4, Basis(), 0.0, "Carved")
	# Side portals.
	for s in [-1.0, 1.0]:
		var x: float = s * 11.0
		lm.box("Carved", Vector3(x, 9.5, 59.4), Vector3(6.4, 17.0, 0.8))
		LandmarkAmhParts.opening(lm, "Windows", Vector3(x, 4.0, 59.85), Basis(), 3.2, 6.0, 0.1)
		LandmarkDetail.arch(lm, "Carved", Vector3(x, 7.0, 59.8), Vector3.BACK, 3.2, 0.5, 0.3)
		for dx in [-2.6, 2.6]:
			LandmarkNaParts.column_lite(lm, "Carved", Vector3(x + dx, 1.0, 60.2), 0.42, 9.5, 1.0, 10)
		lm.box("Carved", Vector3(x, 11.2, 60.2), Vector3(6.8, 1.0, 1.2))
		LandmarkDetail.window(lm, "Carved", "Windows", Vector3(x, 15.0, 59.8), Vector3.BACK, 1.6, 3.2,
			true, 0.3)
	# Top balustrade with urns, then the clock tower and its statues.
	lm.box("Carved", Vector3(0, 34.6, 58.5), Vector3(30.6, 1.2, 1.0))
	LandmarkNaParts.balusters(lm, "Carved", Vector3(-15.0, 35.2, 58.6), Vector3(15.0, 35.2, 58.6), 1.2,
		0.5, 3.75)
	for i in 9:
		var x := -15.0 + 3.75 * float(i)
		lm.lathe("Carved", Vector3(x, 36.4, 58.6),
			PackedVector2Array([Vector2(0.3, 0.0), Vector2(0.45, 0.3), Vector2(0.3, 0.7),
			Vector2(0.12, 1.0), Vector2(0.0, 1.2)]), 8)
	var ct := Vector3(0, 35.2, 57.0)
	lm.box("Stone", ct + Vector3(0, 3.0, 0), Vector3(9.0, 6.0, 4.0))
	for x in [-4.0, 4.0]:
		lm.box("Carved", ct + Vector3(x, 3.0, 2.0), Vector3(1.0, 6.0, 0.5))
	lm.disc("Carved", ct + Vector3(0, 3.2, 2.06), Vector3.BACK, 1.5, 24)
	lm.disc("Windows", ct + Vector3(0, 3.2, 2.1), Vector3.BACK, 1.25, 24)
	lm.beam("Gold", ct + Vector3(0, 3.2, 2.14), ct + Vector3(0, 4.2, 2.14), 0.1, 0.04)
	lm.beam("Gold", ct + Vector3(0, 3.2, 2.14), ct + Vector3(0.7, 3.2, 2.14), 0.1, 0.04)
	lm.box("Carved", ct + Vector3(0, 6.3, 0), Vector3(9.6, 0.6, 4.6))
	for i in 3:
		var x := -3.0 + 3.0 * float(i)
		lm.box("Carved", ct + Vector3(x, 7.0, 0), Vector3(1.3, 0.8, 1.3))
		LandmarkKits.statue_figure(lm, "Carved", ct + Vector3(x, 7.4, 0), 3.4, i == 1)

## One bell tower centred at `x` on the facade: the square base with its
## portal and windows, two square belfry stages with arched openings,
## corner pilasters, balustrades and urns, the bell-shaped crown, the
## lantern and the gilded cross.
static func _bell_tower(lm: LandmarkMesh, x: float) -> void:
	var c := Vector3(x, 0, 52.0)
	lm.box("Stone", c + Vector3(0, 14.0, 0), Vector3(14.7, 26.0, 14.0))
	lm.box("Carved", c + Vector3(0, 7.0, 7.6), Vector3(6.6, 12.0, 1.2))
	LandmarkAmhParts.opening(lm, "Windows", c + Vector3(0, 4.75, 8.25), Basis(), 3.2, 7.5, 0.1)
	LandmarkDetail.arch(lm, "Carved", c + Vector3(0, 8.5, 8.2), Vector3.BACK, 3.2, 0.5, 0.3)
	for dx in [-3.5, 3.5]:
		lm.box("Carved", c + Vector3(dx, 8.0, 8.0), Vector3(0.9, 14.0, 0.9))
	for y in [17.0, 22.0]:
		LandmarkDetail.window(lm, "Carved", "Windows", c + Vector3(0, y, 7.0), Vector3.BACK, 1.6, 3.0,
			true, 0.3)
	lm.box("Carved", c + Vector3(0, 27.0, 0), Vector3(15.5, 0.8, 14.8))
	_belfry(lm, c + Vector3(0, 27.4, 0), 12.6, 13.3, 2)
	_belfry(lm, c + Vector3(0, 41.1, 0), 10.2, 9.8, 1)
	var crown := c + Vector3(0, 51.1, 0)
	lm.lathe("Dome", crown,
		PackedVector2Array([Vector2(4.6, 0.0), Vector2(4.8, 0.8), Vector2(4.6, 2.2), Vector2(4.2, 3.8),
		Vector2(3.5, 5.4), Vector2(2.6, 6.9), Vector2(1.8, 8.2), Vector2(1.4, 9.3)]), 24)
	for q in 4:
		var a := PI * 0.5 * float(q) + PI * 0.25
		var d := Vector3(cos(a), 0, sin(a))
		var prof := [[4.85, 0.6], [4.65, 2.2], [4.25, 3.8], [3.55, 5.4], [2.65, 6.9], [1.85, 8.2],
			[1.45, 9.3]]
		for j in prof.size() - 1:
			var p0 := crown + d * float(prof[j][0]) + Vector3(0, float(prof[j][1]), 0)
			var p1 := crown + d * float(prof[j + 1][0]) + Vector3(0, float(prof[j + 1][1]), 0)
			lm.beam("Carved", p0, p1, 0.5, 0.3, d.cross(Vector3.UP))
	lm.frustum("Carved", crown + Vector3(0, 9.3, 0), 1.5, 1.3, 3.0, 12)
	for q in 8:
		var a := TAU * float(q) / 8.0
		lm.box("Carved", crown + Vector3(cos(a) * 1.45, 10.8, sin(a) * 1.45), Vector3(0.3, 3.0, 0.3),
			Basis(), 0.0)
	lm.lathe("Dome", crown + Vector3(0, 12.3, 0),
		PackedVector2Array([Vector2(1.7, 0.0), Vector2(1.2, 0.8), Vector2(0.0, 2.2)]), 12)
	var cross := crown + Vector3(0, 14.5, 0)
	lm.lathe("Gold", cross - Vector3(0, 0.1, 0),
		PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.35, 0.15), Vector2(0.35, 0.45),
		Vector2(0.0, 0.6)]), 10)
	lm.beam("Gold", cross, cross + Vector3(0, CATHEDRAL_TOP_M - 65.6, 0), 0.22, 0.22)
	lm.beam("Gold", cross + Vector3(-0.5, 0.9, 0), cross + Vector3(0.5, 0.9, 0), 0.2, 0.2)

## Square belfry stage `w` wide and `h` tall from `b`: corner pilasters,
## `bays` arched bell openings per face, the cornice, a balustrade and
## urns on the corners.
static func _belfry(lm: LandmarkMesh, b: Vector3, w: float, h: float, bays: int) -> void:
	lm.box("Stone", b + Vector3(0, h * 0.5, 0), Vector3(w - 0.6, h, w - 0.6))
	for q in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * float(q))
		var n := r * Vector3.BACK
		for i in bays:
			var x := (float(i) + 0.5 - float(bays) * 0.5) * (w / float(bays) * 0.9)
			LandmarkDetail.window(lm, "Carved", "Windows", b + r * Vector3(x, h * 0.48, w * 0.5 - 0.3),
				n, 2.4 if bays > 1 else 2.6, h * 0.5, true, 0.35)
		for sx in [-1.0, 1.0]:
			lm.box("Carved", b + r * Vector3(sx * (w * 0.5 - 0.5), h * 0.5, w * 0.5 - 0.2),
				Vector3(1.0, h, 0.6), r)
	lm.box("Carved", b + Vector3(0, h - 0.3, 0), Vector3(w + 0.4, 0.6, w + 0.4))
	for q in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * float(q))
		var e := w * 0.5
		LandmarkNaParts.balusters(lm, "Carved", b + r * Vector3(-e, h, e), b + r * Vector3(e, h, e),
			1.0, 0.5, w)
		lm.lathe("Carved", b + r * Vector3(e, h + 1.0, e),
			PackedVector2Array([Vector2(0.35, 0.0), Vector2(0.5, 0.35), Vector2(0.3, 0.8),
			Vector2(0.1, 1.2), Vector2(0.0, 1.4)]), 8)

## Tolsa's dome over the crossing at `c`: the drum ringed by columns
## between its arched windows, the entablature and balustrade, the
## ribbed dome, the colonnaded lantern and the gilded cross.
static func _cathedral_dome(lm: LandmarkMesh, c: Vector3) -> void:
	lm.frustum("Stone", c, 11.6, 11.6, 11.0, 32)
	for k in 16:
		var a := TAU * float(k) / 16.0
		LandmarkNaParts.column_lite(lm, "Carved", c + Vector3(cos(a), 0, sin(a)) * 12.2, 0.5, 10.4, 1.0,
			10)
	for k in 8:
		var a := TAU * float(k) / 8.0 + PI / 16.0
		var d := Vector3(cos(a), 0, sin(a))
		LandmarkDetail.window(lm, "Carved", "Windows", c + d * 11.6 + Vector3(0, 5.4, 0), d, 1.8, 4.4,
			true, 0.3)
	lm.frustum("Carved", c + Vector3(0, 10.4, 0), 12.9, 12.9, 0.9, 32)
	lm.lathe("Carved", c + Vector3(0, 11.3, 0),
		PackedVector2Array([Vector2(12.9, 0.0), Vector2(13.3, 0.4), Vector2(13.4, 0.7)]), 32)
	LandmarkNaParts.ring_posts(lm, "Carved", c + Vector3(0, 12.0, 0), 12.0, 0.9, 48, 0.22, 0.22)
	LandmarkNaParts.ring(lm, "Carved", c + Vector3(0, 12.9, 0), 12.0, 0.5, 0.2, 32)
	var d := c + Vector3(0, 12.4, 0)
	var prof := PackedVector2Array([Vector2(11.6, 0.0), Vector2(11.4, 1.0), Vector2(10.6, 3.2),
		Vector2(9.1, 5.4), Vector2(7.0, 7.4), Vector2(4.6, 8.8), Vector2(2.4, 9.6), Vector2(1.5, 9.9)])
	lm.lathe("Dome", d, prof, 32)
	for k in 8:
		var a := TAU * float(k) / 8.0
		var dir := Vector3(cos(a), 0, sin(a))
		for j in prof.size() - 2:
			lm.beam("Carved", d + dir * (prof[j].x + 0.1) + Vector3(0, prof[j].y, 0),
				d + dir * (prof[j + 1].x + 0.1) + Vector3(0, prof[j + 1].y, 0), 0.6, 0.35,
				dir.cross(Vector3.UP))
	var l := d + Vector3(0, 9.9, 0)
	lm.frustum("Carved", l, 1.7, 1.7, 3.2, 12)
	for k in 8:
		var a := TAU * float(k) / 8.0
		lm.frustum("Carved", l + Vector3(cos(a), 0, sin(a)) * 1.9, 0.18, 0.16, 3.2, 8)
	lm.frustum("Carved", l + Vector3(0, 3.2, 0), 2.2, 2.2, 0.3, 12)
	lm.lathe("Dome", l + Vector3(0, 3.5, 0),
		PackedVector2Array([Vector2(2.1, 0.0), Vector2(1.7, 0.6), Vector2(0.0, 2.0)]), 12)
	var t := l + Vector3(0, 5.5, 0)
	lm.beam("Gold", t, t + Vector3(0, 2.4, 0), 0.3, 0.3)
	lm.beam("Gold", t + Vector3(-0.7, 1.5, 0), t + Vector3(0.7, 1.5, 0), 0.25, 0.25)
