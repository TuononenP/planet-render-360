class_name LandmarkChCastles
extends RefCounted

## Two strongholds in true metres: Heidelberg Castle (red Neckar
## sandstone round its courtyard: the Friedrichsbau of 1601-07 on the
## north side with its 16 ancestor statues in four tiers and two great
## gables, the roofless Ottheinrichsbau on the east with 16 allegorical
## figures, the Glaserner Saalbau between them, the Dicker Turm and the
## blown-up tower, the gate tower and the Ruprechtsbau) and Hohensalzburg
## Fortress (white walls of the 450 m outer ring on the rock, the Hoher
## Stock residence with its corner turrets, the Reckturm, St George's
## church, the bell tower, Kuenburg bastion and the arsenal ranges).
## The Porta Nigra is LandmarkChPorta.

# --- Heidelberg Castle ---

const HEIDELBERG_TOP := 34.5

static func heidelberg(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#A86A52", 3.0))
	lm.use("Ruin", LandmarkMaterials.pbr("stone", "#8A5E4C", 3.0))
	lm.use("Pale", LandmarkMaterials.pbr("limestone", "#C79A7C", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("slate", "#58505A", 3.0))
	lm.use("Windows", LandmarkMaterials.glass("#222B30"))
	lm.use("Rock", LandmarkMaterials.pbr("stone", "#7A6C5C", 4.0))
	# Terrace platform of the castle on the Jettenbuhl.
	var rock := PackedVector2Array([Vector2(-38, -38), Vector2(40, -38), Vector2(42, 34), Vector2(-38, 36)])
	lm.poly_prism("Rock", rock, 0.0, 0.8)
	_friedrichsbau(lm)
	_ottheinrichsbau(lm)
	_heidelberg_ranges(lm)
	_heidelberg_towers(lm)
	lm.commit(model)

## Friedrichsbau: four storeys under the steep slate roof; on the court
## side (+Z) pilasters of the four orders, 16 ancestor statues in
## niches, cross-mullioned windows and two voluted gables; the north
## front to the town with its own window rows.
static func _friedrichsbau(lm: LandmarkMesh) -> void:
	var c := Vector3(0, 0, -22.0)
	lm.box("Stone", c + Vector3(0, 11.0, 0), Vector3(40.0, 22.0, 14.0))
	lm.gable("Roof", c + Vector3(0, 22.0, 0), 14.0, 40.0, 12.0, Basis(Vector3.UP, PI * 0.5), 0.6, "Stone")
	for sz in [-1.0, 1.0]:
		var n := Vector3(0, 0, sz)
		var z: float = c.z + sz * 7.0
		for y in [5.5, 11.0, 16.5]:
			lm.box("Pale", Vector3(0, y, z + sz * 0.25), Vector3(40.4, 0.5, 0.5), Basis(), 0.0)
		LandmarkDetail.cornice(lm, "Pale", Vector3(-20.0, 21.2, z), Vector3(20.0, 21.2, z), n, 0.8, false)
		for r in 4:
			var y0 := 5.5 * r
			for i in 8:
				var x := -17.5 + 5.0 * i
				LandmarkChParts.frame_window(lm, "Pale", "Windows", Vector3(x, y0 + 2.9, z), n, 1.8, 2.8, 0.24, 0.2)
				lm.box("Pale", Vector3(x, y0 + 3.0, z + sz * 0.12), Vector3(0.14, 2.8, 0.1), Basis(), 0.0)
				lm.box("Pale", Vector3(x, y0 + 3.6, z + sz * 0.12), Vector3(1.8, 0.14, 0.1), Basis(), 0.0)
			if sz > 0.0:
				for i in 9:
					var x := -20.0 + 5.0 * i
					lm.box("Pale", Vector3(x, y0 + 2.75, z + 0.25), Vector3(0.7, 5.0, 0.5))
				for x in [-15.0, -5.0, 5.0, 15.0]:
					lm.box("Pale", Vector3(x, y0 + 1.0, z + 0.55), Vector3(1.2, 0.3, 0.7), Basis(), 0.0)
					LandmarkKits.statue_figure(lm, "Pale", Vector3(x, y0 + 1.15, z + 0.55), 2.3, r % 2 == 0)
					LandmarkChParts.arch_band(lm, "Pale", Vector3(x, y0 + 3.3, z + 0.1), n, 1.2, 0.2, 0.2, 6)
	# The two court-side gables, stepped with volutes and obelisks.
	for x in [-10.0, 10.0]:
		var g := Vector3(x, 22.0, c.z + 6.6)
		var steps := [[11.0, 4.0], [8.0, 3.6], [5.0, 3.0], [2.4, HEIDELBERG_TOP - 22.0 - 10.6]]
		var y := 0.0
		for st in steps:
			var w: float = st[0]
			var h: float = st[1]
			lm.box("Pale", g + Vector3(0, y + h * 0.5, 0), Vector3(w, h, 1.0))
			LandmarkChParts.frame_window(lm, "Pale", "Windows", g + Vector3(0, y + h * 0.5, 0.5), Vector3.BACK,
				minf(w * 0.3, 1.6), h * 0.5, 0.2, 0.15)
			for s in ([-1.0, 1.0] if y + h < HEIDELBERG_TOP - 22.5 else []):
				lm.lathe("Pale", g + Vector3(s * w * 0.5, y + h, 0), PackedVector2Array([Vector2(0.3, 0), Vector2(0.15, 1.2),
					Vector2(0.0, 1.5)]), 4, 1.0, 1.0, PI * 0.25, false)
				lm.beam("Pale", g + Vector3(s * w * 0.5, y, 0.3), g + Vector3(s * (w * 0.5 + 0.8), y + h * 0.45, 0.3), 0.5, 0.4)
			y += h
		lm.gable("Roof", g + Vector3(0, 0, -3.0), 11.0, 6.0, 8.0, Basis(), 0.2, "Stone")
	# Dormers on the north roof slope.
	for i in 5:
		var x := -16.0 + 8.0 * i
		var dp := Vector3(x, 23.2, c.z - 4.6)
		lm.box("Stone", dp + Vector3(0, 1.0, 0), Vector3(2.0, 2.0, 1.8))
		lm.gable("Roof", dp + Vector3(0, 2.0, 0), 2.0, 1.8, 1.3, Basis(), 0.15, "Stone")
		LandmarkChParts.frame_window(lm, "Pale", "Windows", dp + Vector3(0, 1.0, -0.92), Vector3.FORWARD, 0.9, 1.2, 0.14, 0.1)

## Ottheinrichsbau: the roofless Renaissance palace on the east side of
## the court, its ornate west front of four storeys with pilasters,
## paired windows, 16 figures in niches and the triumphal-arch portal.
static func _ottheinrichsbau(lm: LandmarkMesh) -> void:
	var c := Vector3(20.0, 0, 1.0)
	lm.box("Stone", c + Vector3(0, 12.0, 0), Vector3(12.0, 24.0, 30.0))
	var x := c.x - 6.0
	var n := Vector3.LEFT
	for y in [6.5, 12.5, 18.5]:
		lm.box("Pale", Vector3(x - 0.25, y, c.z), Vector3(0.5, 0.5, 30.4), Basis(), 0.0)
	for r in 4:
		var y0 := 6.0 * r + (0.5 if r > 0 else 0.0)
		for i in 7:
			var z := c.z - 12.6 + 4.2 * i
			if r == 0 and i == 3:
				continue
			LandmarkChParts.frame_window(lm, "Pale", "Windows", Vector3(x, y0 + 3.0, z), n, 2.2, 3.0, 0.24, 0.2)
			lm.box("Pale", Vector3(x - 0.12, y0 + 3.0, z), Vector3(0.1, 3.0, 0.14), Basis(), 0.0)
		for i in 8:
			var z := c.z - 14.7 + 4.2 * i
			lm.box("Pale", Vector3(x - 0.25, y0 + 2.9, z), Vector3(0.5, 5.4, 0.7))
		for k in 4:
			var z := c.z - 10.5 + 7.0 * k
			if r == 0 and (k == 1 or k == 2):
				z = c.z + (-3.6 if k == 1 else 3.6)
			lm.box("Pale", Vector3(x - 0.55, y0 + 0.9, z), Vector3(0.7, 0.3, 1.0), Basis(), 0.0)
			LandmarkKits.statue_figure(lm, "Pale", Vector3(x - 0.55, y0 + 1.05, z), 2.4, k % 2 == 1)
	# Portal: paired columns, arch, the crowning aedicule.
	LandmarkChParts.arch_band(lm, "Pale", Vector3(x, 3.6, c.z), n, 2.6, 0.4, 0.4, 8)
	lm.box("Windows", Vector3(x - 0.02, 2.0, c.z), Vector3(0.05, 4.0, 2.6), Basis(), 0.0)
	for s in [-1.0, 1.0]:
		LandmarkDetail.column(lm, "Pale", Vector3(x - 0.6, 0.8, c.z + s * 2.3), 0.28, 4.8, "corinthian", 0)
	lm.box("Pale", Vector3(x - 0.6, 6.0, c.z), Vector3(1.0, 0.8, 5.6))
	lm.box("Pale", Vector3(x - 0.3, 1.0, c.z), Vector3(1.6, 2.0, 6.4))
	# Double stair up to the portal.
	for i in 4:
		lm.box("Pale", Vector3(x - 1.8 + 0.4 * i, 0.2 * i + 0.1, c.z), Vector3(0.4, 0.2 * (i + 1), 6.0), Basis(), 0.0)
	# Broken wall heads where the gables stood.
	_jagged(lm, "Ruin", Vector3(c.x - 6.0, 24.0, c.z - 15.0), Vector3(c.x - 6.0, 24.0, c.z + 15.0), 1.6)
	_jagged(lm, "Ruin", Vector3(c.x + 6.0, 24.0, c.z - 15.0), Vector3(c.x + 6.0, 24.0, c.z + 15.0), 1.6)

## Glaserner Saalbau, Ruprechtsbau, Ludwigsbau and the curtain wall.
static func _heidelberg_ranges(lm: LandmarkMesh) -> void:
	# Glaserner Saalbau: north east, roofless, arcaded galleries to the court.
	var gs := Vector3(26.0, 0, -22.0)
	lm.box("Ruin", gs + Vector3(0, 10.0, 0), Vector3(12.0, 20.0, 14.0))
	_jagged(lm, "Ruin", gs + Vector3(-6.0, 20.0, -7.0), gs + Vector3(-6.0, 20.0, 7.0), 1.4)
	_jagged(lm, "Ruin", gs + Vector3(6.0, 20.0, -7.0), gs + Vector3(6.0, 20.0, 7.0), 1.4)
	for r in 3:
		for i in 3:
			var p := gs + Vector3(-4.0 + 4.0 * i, 1.0 + 6.0 * r, 7.0)
			LandmarkChParts.arch_band(lm, "Pale", p + Vector3(0, 3.4, 0), Vector3.BACK, 3.0, 0.4, 0.35, 8)
			lm.box("Windows", p + Vector3(0, 2.4, 0.02), Vector3(3.0, 4.6, 0.04), Basis(), 0.0)
	# Ruprechtsbau on the west: the oldest range, under a steep roof.
	var rb := Vector3(-27.0, 0, 6.0)
	lm.box("Stone", rb + Vector3(0, 8.0, 0), Vector3(12.0, 16.0, 24.0))
	lm.gable("Roof", rb + Vector3(0, 16.0, 0), 12.0, 24.0, 9.0, Basis(), 0.5, "Stone")
	for r in 3:
		for i in 5:
			LandmarkChParts.frame_window(lm, "Pale", "Windows", rb + Vector3(6.0, 3.0 + 5.0 * r, -9.6 + 4.8 * i),
				Vector3.RIGHT, 1.4, 2.4, 0.22, 0.18)
	# Ludwigsbau ruin, south east.
	var lb := Vector3(26.0, 0, 24.0)
	lm.box("Ruin", lb + Vector3(0, 8.0, 0), Vector3(12.0, 16.0, 16.0))
	_jagged(lm, "Ruin", lb + Vector3(-6.0, 16.0, -8.0), lb + Vector3(-6.0, 16.0, 8.0), 1.4)
	for r in 3:
		for i in 3:
			LandmarkChParts.frame_window(lm, "Pale", "Windows", lb + Vector3(-6.0, 3.0 + 5.0 * r, -5.0 + 5.0 * i),
				Vector3.LEFT, 1.6, 2.8, 0.22, 0.18)
	# Curtain wall closing the terrace, with a coping.
	var wall_pts := [Vector3(-36, 0, -36), Vector3(38, 0, -36), Vector3(40, 0, 32), Vector3(-36, 0, 34)]
	for i in 4:
		LandmarkChParts.wall(lm, "Stone", wall_pts[i], wall_pts[(i + 1) % 4], 0.0, 6.0, 2.0)
		LandmarkCeParts.merlons(lm, "Stone", wall_pts[i] + Vector3(0, 6.0, 0), wall_pts[(i + 1) % 4] + Vector3(0, 6.0, 0),
			3.0, 1.4, 1.0, 1.8)

## Gate tower with its hip roof and giants, the bell tower, the Dicker
## Turm and the blown-up tower torn open on the garden side.
static func _heidelberg_towers(lm: LandmarkMesh) -> void:
	var gt := Vector3(-14.0, 0, 26.0)
	lm.box("Stone", gt + Vector3(0, 12.0, 0), Vector3(9.0, 24.0, 9.0))
	LandmarkCeParts.hip(lm, "Roof", gt + Vector3(0, 24.0, 0), 10.0, 10.0, 10.0)
	LandmarkChParts.arch_band(lm, "Pale", gt + Vector3(0, 3.8, 4.5), Vector3.BACK, 3.6, 0.5, 0.4, 8)
	lm.box("Windows", gt + Vector3(0, 2.0, 4.52), Vector3(3.6, 4.0, 0.04), Basis(), 0.0)
	for s in [-1.0, 1.0]:
		lm.box("Pale", gt + Vector3(s * 2.8, 6.4, 4.9), Vector3(1.0, 0.3, 0.8), Basis(), 0.0)
		LandmarkKits.statue_figure(lm, "Pale", gt + Vector3(s * 2.8, 6.55, 4.9), 3.0, s > 0.0)
	for f in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * f)
		for y in [10.0, 15.0, 20.0]:
			LandmarkChParts.frame_window(lm, "Pale", "Windows", gt + b * Vector3(0, y, 4.5), b.z, 1.2, 2.2, 0.2, 0.15)
	var bell := Vector3(38.0, 0, -30.0)
	lm.frustum("Stone", bell, 5.4, 5.0, 28.0, 8, PI / 8.0)
	for k in 8:
		var a := PI * 0.25 * k
		var d := Vector3(cos(a), 0, sin(a))
		for y in [8.0, 16.0, 23.0]:
			LandmarkChParts.frame_window(lm, "Pale", "Windows", bell + d * 4.8 + Vector3(0, y, 0), d, 1.0, 2.2, 0.18, 0.15)
	_jagged_ring(lm, "Ruin", bell + Vector3(0, 28.0, 0), 5.0, 8)
	var fat := Vector3(-26.0, 0, -30.0)
	lm.frustum("Stone", fat, 8.0, 8.0, 22.0, 32)
	lm.frustum("Ruin", fat + Vector3(0, 22.0, 0), 8.6, 8.6, 1.2, 32)
	for k in 6:
		var a := PI * 0.5 + PI * (float(k) + 0.5) / 6.0 + PI * 0.5
		var d := Vector3(cos(a), 0, sin(a))
		for y in [6.0, 14.0]:
			LandmarkChParts.frame_window(lm, "Pale", "Windows", fat + d * 7.95 + Vector3(0, y, 0), d, 1.4, 2.4, 0.2, 0.15)
	# Blown-up tower on the south east, its fallen half beside it.
	var c := Vector2(36.0, 14.0)
	var ring := PackedVector2Array()
	for a in range(-60, 241, 15):
		ring.append(c + Vector2(cos(deg_to_rad(float(a))), sin(deg_to_rad(float(a)))) * 10.5)
	for a in range(240, -61, -15):
		ring.append(c + Vector2(cos(deg_to_rad(float(a))), sin(deg_to_rad(float(a)))) * 4.5)
	lm.poly_prism("Ruin", ring, 0.0, 18.0)
	for k in 10:
		var a := deg_to_rad(-60.0 + 30.0 * k)
		lm.box("Ruin", Vector3(c.x + cos(a) * 7.5, 18.0 + float((k * 3) % 4) * 0.8, c.y + sin(a) * 7.5),
			Vector3(3.0, 1.6 + float((k * 3) % 4) * 1.6, 5.8), Basis(Vector3.UP, -a))
	lm.box("Ruin", Vector3(c.x - 3.0, 3.0, c.y - 9.0), Vector3(9.0, 6.0, 5.0), Basis(Vector3.UP, 0.5))

## Broken wall top: boxes of changing height along a line, `thick` through.
static func _jagged(lm: LandmarkMesh, key: String, a: Vector3, b: Vector3, thick: float) -> void:
	var n := maxi(int(a.distance_to(b) / 2.6), 1)
	var dir := (b - a).normalized()
	var basis := Basis(Vector3.UP, atan2(-dir.z, dir.x))
	for i in n:
		var h := 0.8 + float((i * 5) % 4) * 0.9
		lm.box(key, a.lerp(b, (float(i) + 0.5) / float(n)) + Vector3(0, h * 0.5, 0), Vector3(2.6, h, thick), basis)

## Broken rim round a tower top: alternating teeth on a circle.
static func _jagged_ring(lm: LandmarkMesh, key: String, c: Vector3, r: float, count: int) -> void:
	for i in count:
		var a := TAU * float(i) / float(count)
		var h := 0.8 + float((i * 5) % 3) * 1.1
		lm.box(key, c + Vector3(cos(a) * r, h * 0.5, sin(a) * r), Vector3(2.0, h, 1.4), Basis(Vector3.UP, -a))

# --- Hohensalzburg Fortress ---

static func hohensalzburg(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Plaster", LandmarkMaterials.pbr("render", "#E0D6BE", 3.0))
	lm.use("Rock", LandmarkMaterials.pbr("stone", "#8A8272", 4.0))
	lm.use("Roof", LandmarkMaterials.pbr("terracotta", "#A24A32", 2.5))
	lm.use("Windows", LandmarkMaterials.glass("#222B30"))
	lm.use("Gilt", LandmarkMaterials.gold())
	LandmarkChSalzburg.build(lm)
	lm.commit(model)
