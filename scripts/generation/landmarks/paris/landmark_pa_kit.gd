class_name LandmarkPaKit
extends RefCounted

## Shared Paris architectural building blocks for `LandmarkSetParis`:
## Lutetian limestone, standing-seam Parisian zinc & Angers slate mansards,
## classical colonnades, pediments, ribbed domes, Beaux-Arts arched bays,
## elliptical bridge ribs, gilded bronze quadrigas/statues, and Davioud /
## Pont Alexandre III cast-iron globe lamp candelabra.

## Warm blond Lutetian limestone (Paris's signature cut stone).
static func lutetian(hex: String = "#DCD0B4", tile_m: float = 3.5) -> StandardMaterial3D:
	return LandmarkMaterials.pbr("limestone", hex, tile_m)

## Deeper weathered ashlar / rusticated base stone.
static func ashlar(hex: String = "#C5B89B", tile_m: float = 3.2) -> StandardMaterial3D:
	return LandmarkMaterials.pbr("stone", hex, tile_m)

## Standing-seam Parisian zinc roof (muted cool blue-grey).
static func zinc(hex: String = "#596570", tile_m: float = 2.4) -> StandardMaterial3D:
	return LandmarkMaterials.pbr("slate", hex, tile_m)

## Deep blue-black Angers slate roof (Louvre, Hôtel de Ville, Conciergerie).
static func slate(hex: String = "#424B54", tile_m: float = 2.4) -> StandardMaterial3D:
	return LandmarkMaterials.pbr("slate", hex, tile_m)

## Parisian bottle-green cast iron (Passerelle Debilly, Guimard, lamps).
static func paris_green(hex: String = "#224B3B") -> StandardMaterial3D:
	return LandmarkMaterials.paint(hex, 0.48, 0.45)

## Verdigris / patinated bronze (Grand Palais steel, Vendôme/Bastille columns, statues).
static func verdigris(hex: String = "#4F7D6C") -> StandardMaterial3D:
	return LandmarkMaterials.pbr("copper", hex, 2.2)

## Dark architectural bronze (statues, fountains, candelabra).
static func bronze(hex: String = "#3A3E38") -> StandardMaterial3D:
	return LandmarkMaterials.paint(hex, 0.42, 0.72)

## Classical colonnade along X from x0..x1 at (y0, z), with plinth, shaft, capital & entablature.
static func colonnade_x(lm: LandmarkMesh, mat: String, x0: float, x1: float, y0: float, z: float,
		count: int, col_h: float, col_r: float) -> void:
	var n := maxi(count, 2)
	for i in n:
		var x := lerpf(x0, x1, float(i) / float(n - 1))
		lm.box(mat, Vector3(x, y0 + 0.4, z), Vector3(col_r * 2.5, 0.8, col_r * 2.5))
		lm.frustum(mat, Vector3(x, y0 + 0.8, z), col_r, col_r * 0.88, col_h - 1.5, 10)
		lm.box(mat, Vector3(x, y0 + col_h - 0.35, z), Vector3(col_r * 2.6, 0.7, col_r * 2.6))
	var span := absf(x1 - x0) + col_r * 3.0
	lm.box(mat, Vector3((x0 + x1) * 0.5, y0 + col_h + 0.8, z), Vector3(span, 1.6, col_r * 3.0))

## Classical colonnade along Z from z0..z1 at (x, y0).
static func colonnade_z(lm: LandmarkMesh, mat: String, x: float, y0: float, z0: float, z1: float,
		count: int, col_h: float, col_r: float) -> void:
	var n := maxi(count, 2)
	for i in n:
		var z := lerpf(z0, z1, float(i) / float(n - 1))
		lm.box(mat, Vector3(x, y0 + 0.4, z), Vector3(col_r * 2.5, 0.8, col_r * 2.5))
		lm.frustum(mat, Vector3(x, y0 + 0.8, z), col_r, col_r * 0.88, col_h - 1.5, 10)
		lm.box(mat, Vector3(x, y0 + col_h - 0.35, z), Vector3(col_r * 2.6, 0.7, col_r * 2.6))
	var span := absf(z1 - z0) + col_r * 3.0
	lm.box(mat, Vector3(x, y0 + col_h + 0.8, (z0 + z1) * 0.5), Vector3(col_r * 3.0, 1.6, span))

## Triangular classical pediment spanning X, facing +/-Z, base at y0.
static func pediment_z(lm: LandmarkMesh, mat: String, cx: float, y0: float, z: float,
		width: float, rise: float, depth: float) -> void:
	var steps := 7
	for k in steps:
		var t0 := float(k) / float(steps)
		var t1 := float(k + 1) / float(steps)
		var w := width * (1.0 - (t0 + t1) * 0.5)
		var h := rise / float(steps)
		lm.box(mat, Vector3(cx, y0 + rise * (t0 + t1) * 0.5, z), Vector3(w, h + 0.08, depth))
	var left := Vector3(cx - width * 0.52, y0, z)
	var peak := Vector3(cx, y0 + rise + 0.35, z)
	var right := Vector3(cx + width * 0.52, y0, z)
	lm.beam(mat, left, peak, 0.65, depth + 0.5)
	lm.beam(mat, peak, right, 0.65, depth + 0.5)

## Steep Parisian mansard roof with dormer rows and optional zinc/gilt cresting.
static func mansard(lm: LandmarkMesh, roof_mat: String, stone_mat: String, glass_mat: String,
		c: Vector3, w: float, d: float, h: float, dormers_x: int = 0, dormers_z: int = 0) -> void:
	var low := PackedVector2Array([
		Vector2(c.x - w * 0.5, c.z - d * 0.5), Vector2(c.x - w * 0.5, c.z + d * 0.5),
		Vector2(c.x + w * 0.5, c.z + d * 0.5), Vector2(c.x + w * 0.5, c.z - d * 0.5)])
	var inset := minf(h * 0.55, minf(w, d) * 0.24)
	var high := PackedVector2Array([
		Vector2(c.x - w * 0.5 + inset, c.z - d * 0.5 + inset),
		Vector2(c.x - w * 0.5 + inset, c.z + d * 0.5 - inset),
		Vector2(c.x + w * 0.5 - inset, c.z + d * 0.5 - inset),
		Vector2(c.x + w * 0.5 - inset, c.z - d * 0.5 + inset)])
	var grid: Array[PackedVector3Array] = []
	var r0 := PackedVector3Array()
	var r1 := PackedVector3Array()
	for i in 5:
		var p0 := low[i % 4]
		var p1 := high[i % 4]
		r0.append(Vector3(p0.x, c.y, p0.y))
		r1.append(Vector3(p1.x, c.y + h, p1.y))
	grid.append(r0)
	grid.append(r1)
	lm.grid(roof_mat, grid)
	lm.box(roof_mat, Vector3(c.x, c.y + h - 0.15, c.z), Vector3(maxf(w - inset * 2.0, 0.5), 0.3, maxf(d - inset * 2.0, 0.5)))
	if dormers_x > 0:
		for sz in [-1.0, 1.0]:
			var dz := c.z + float(sz) * (d * 0.5 - inset * 0.45)
			for i in dormers_x:
				var dx := lerpf(c.x - w * 0.42, c.x + w * 0.42, (float(i) + 0.5) / float(dormers_x))
				lm.box(stone_mat, Vector3(dx, c.y + h * 0.48, dz), Vector3(1.5, h * 0.62, 1.4))
				lm.box(glass_mat, Vector3(dx, c.y + h * 0.48, dz + float(sz) * 0.72), Vector3(1.0, h * 0.44, 0.12))
	if dormers_z > 0:
		for sx in [-1.0, 1.0]:
			var dx := c.x + float(sx) * (w * 0.5 - inset * 0.45)
			for i in dormers_z:
				var dz := lerpf(c.z - d * 0.42, c.z + d * 0.42, (float(i) + 0.5) / float(dormers_z))
				lm.box(stone_mat, Vector3(dx, c.y + h * 0.48, dz), Vector3(1.4, h * 0.62, 1.5))
				lm.box(glass_mat, Vector3(dx + float(sx) * 0.72, c.y + h * 0.48, dz), Vector3(0.12, h * 0.44, 1.0))

## Quadrangular French pavilion dome (Louvre Pavillon de l'Horloge, École Militaire, Luxembourg).
static func pavilion_dome(lm: LandmarkMesh, roof_mat: String, trim_mat: String,
		c: Vector3, w: float, d: float, h: float) -> void:
	var segs := 6
	var grid: Array[PackedVector3Array] = []
	for s in segs + 1:
		var t := float(s) / float(segs)
		# Convex ogee-like bulge tapering to a crown deck
		var k := lerpf(1.0, 0.28, pow(t, 1.35)) + sin(t * PI) * 0.08
		var hw := w * 0.5 * k
		var hd := d * 0.5 * k
		var y := c.y + h * t
		var ring := PackedVector3Array([
			Vector3(c.x - hw, y, c.z - hd), Vector3(c.x - hw, y, c.z + hd),
			Vector3(c.x + hw, y, c.z + hd), Vector3(c.x + hw, y, c.z - hd),
			Vector3(c.x - hw, y, c.z - hd)])
		grid.append(ring)
	lm.grid(roof_mat, grid)
	lm.box(trim_mat, Vector3(c.x, c.y + h + 0.25, c.z), Vector3(w * 0.30, 0.5, d * 0.30))

## Elliptical arch rib spanning X from x0..x1, springing at y_spring to y_crown, at Z = z.
static func arch_rib(lm: LandmarkMesh, mat: String, x0: float, x1: float, y_spring: float, y_crown: float,
		z: float, segs: int, thick_y: float, thick_z: float) -> void:
	var cx := (x0 + x1) * 0.5
	var rx := absf(x1 - x0) * 0.5
	var ry := y_crown - y_spring
	for i in segs:
		var a0 := PI * float(i) / float(segs)
		var a1 := PI * float(i + 1) / float(segs)
		var p0 := Vector3(cx - cos(a0) * rx, y_spring + sin(a0) * ry, z)
		var p1 := Vector3(cx - cos(a1) * rx, y_spring + sin(a1) * ry, z)
		lm.beam(mat, p0, p1, thick_y, thick_z)

## Window grid along a Z-facing facade.
static func win_grid_z(lm: LandmarkMesh, mat: String, x0: float, x1: float, z: float,
		ys: Array, count: int, ww: float = 1.8, wh: float = 3.0) -> void:
	var n := maxi(count, 1)
	for yv in ys:
		var y := float(yv)
		for i in n:
			var x := lerpf(x0, x1, (float(i) + 0.5) / float(n))
			lm.box(mat, Vector3(x, y, z), Vector3(ww, wh, 0.16))

## Window grid along an X-facing facade.
static func win_grid_x(lm: LandmarkMesh, mat: String, x: float, z0: float, z1: float,
		ys: Array, count: int, ww: float = 1.8, wh: float = 3.0) -> void:
	var n := maxi(count, 1)
	for yv in ys:
		var y := float(yv)
		for i in n:
			var z := lerpf(z0, z1, (float(i) + 0.5) / float(n))
			lm.box(mat, Vector3(x, y, z), Vector3(0.16, wh, ww))

## Single Parisian Davioud / bridge globe lamp standard at base `pos`.
static func paris_lamp(lm: LandmarkMesh, iron_mat: String, lamp_mat: String, pos: Vector3, h: float = 4.2) -> void:
	lm.frustum(iron_mat, pos, 0.28, 0.16, 0.85, 8)
	lm.frustum(iron_mat, pos + Vector3(0.0, 0.85, 0.0), 0.14, 0.08, h - 1.45, 6)
	lm.frustum(lamp_mat, pos + Vector3(0.0, h - 0.60, 0.0), 0.20, 0.30, 0.36, 8)
	lm.frustum(lamp_mat, pos + Vector3(0.0, h - 0.24, 0.0), 0.30, 0.08, 0.24, 8)

## Ornate Pont Alexandre III four-globe Art Nouveau candelabrum at base `pos`.
static func candelabrum(lm: LandmarkMesh, iron_mat: String, lamp_mat: String, pos: Vector3, h: float = 5.4) -> void:
	lm.frustum(iron_mat, pos, 0.42, 0.22, 1.3, 8)
	lm.frustum(iron_mat, pos + Vector3(0.0, 1.3, 0.0), 0.18, 0.10, h - 1.9, 8)
	# Central crowning globe
	lm.frustum(lamp_mat, pos + Vector3(0.0, h - 0.60, 0.0), 0.26, 0.34, 0.34, 8)
	lm.frustum(lamp_mat, pos + Vector3(0.0, h - 0.26, 0.0), 0.34, 0.10, 0.26, 8)
	# Four branching arms with hanging globes
	for k in 4:
		var a := TAU * float(k) / 4.0 + PI * 0.25
		var d := Vector3(cos(a), 0.0, sin(a))
		var arm_top := pos + Vector3(0.0, h - 1.25, 0.0) + d * 0.85
		lm.beam(iron_mat, pos + Vector3(0.0, h - 1.85, 0.0), arm_top, 0.08, 0.08)
		lm.frustum(lamp_mat, arm_top + Vector3(0.0, -0.05, 0.0), 0.18, 0.24, 0.28, 6)
		lm.frustum(lamp_mat, arm_top + Vector3(0.0, 0.23, 0.0), 0.24, 0.08, 0.18, 6)

## Monumental bronze or gilded equestrian statue (Pont d'Iéna, Pont Neuf Henri IV, Pont Alexandre III Pegasus).
static func equestrian(lm: LandmarkMesh, mat: String, base: Vector3, scale: float = 1.0,
		yaw: float = 0.0, winged: bool = false) -> void:
	var b := Basis(Vector3.UP, yaw)
	var p := func(v: Vector3) -> Vector3:
		return base + b * (v * scale)
	# Horse torso, neck, head, four legs
	lm.beam(mat, p.call(Vector3(0.0, 1.8, -1.1)), p.call(Vector3(0.0, 2.2, 1.0)), 0.9 * scale, 1.0 * scale)
	lm.beam(mat, p.call(Vector3(0.0, 2.2, 1.0)), p.call(Vector3(0.0, 3.3, 1.7)), 0.52 * scale, 0.58 * scale)
	lm.box(mat, p.call(Vector3(0.0, 3.4, 2.05)), Vector3(0.42, 0.46, 0.88) * scale, b)
	for lx in [-0.32, 0.32]:
		lm.beam(mat, p.call(Vector3(lx, 1.7, -1.0)), p.call(Vector3(lx, 0.0, -1.15)), 0.20 * scale, 0.20 * scale)
		lm.beam(mat, p.call(Vector3(lx, 2.0, 0.9)), p.call(Vector3(lx, 0.15 if lx > 0 else 0.0, 1.25)),
			0.18 * scale, 0.18 * scale)
	# Rider / Fame figure
	lm.frustum(mat, p.call(Vector3(0.0, 2.3, -0.15)), 0.36 * scale, 0.28 * scale, 1.55 * scale, 6)
	lm.frustum(mat, p.call(Vector3(0.0, 3.85, -0.15)), 0.24 * scale, 0.20 * scale, 0.42 * scale, 6)
	if winged:
		for sx in [-1.0, 1.0]:
			var fsx := float(sx)
			var w0: Vector3 = p.call(Vector3(fsx * 0.45, 2.35, 0.25))
			var w1: Vector3 = p.call(Vector3(fsx * 2.1, 4.1, -0.7))
			var w2: Vector3 = p.call(Vector3(fsx * 2.8, 4.5, -1.8))
			lm.beam(mat, w0, w1, 0.65 * scale, 0.18 * scale)
			lm.beam(mat, w1, w2, 0.45 * scale, 0.14 * scale)
