class_name LandmarkLnKit
extends RefCounted

## Shared London architectural building blocks for `LandmarkSetLondon`:
## Portland-stone rusticated plinths, Corinthian/Ionic colonnades, Welsh-slate
## mansard roofs with dormers and chimney stacks, cast-iron Gothic bridge arches,
## and Victorian Thames globe lamp standards.

## Portland-stone PBR material (pale cream-white oolitic limestone).
static func portland(hex: String = "#DDD7C7", tile_m: float = 3.5) -> StandardMaterial3D:
	return LandmarkMaterials.pbr("limestone", hex, tile_m)

## London red-brick PBR material (St Pancras, Lambeth Palace, Albert Hall).
static func red_brick(hex: String = "#984836", tile_m: float = 2.8) -> StandardMaterial3D:
	return LandmarkMaterials.pbr("brick", hex, tile_m)

## Dark Welsh slate roof PBR material.
static func welsh_slate(hex: String = "#495159", tile_m: float = 2.4) -> StandardMaterial3D:
	return LandmarkMaterials.pbr("slate", hex, tile_m)

## Cornish granite plinth / embankment stone.
static func granite(hex: String = "#8A867F", tile_m: float = 3.2) -> StandardMaterial3D:
	return LandmarkMaterials.pbr("stone", hex, tile_m)

## Classical colonnade along X from x0..x1 at (y0, z), with base, shaft, capital, and entablature.
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

## Triangular classical pediment facing +Z (or -Z when flip < 0) resting at y0.
static func pediment_z(lm: LandmarkMesh, mat: String, cx: float, y0: float, z: float,
		width: float, rise: float, depth: float) -> void:
	var steps := 7
	for k in steps:
		var t0 := float(k) / float(steps)
		var t1 := float(k + 1) / float(steps)
		var w := width * (1.0 - (t0 + t1) * 0.5)
		var h := rise / float(steps)
		lm.box(mat, Vector3(cx, y0 + rise * (t0 + t1) * 0.5, z), Vector3(w, h + 0.08, depth))
	# Raking cornice beams
	var left := Vector3(cx - width * 0.52, y0, z)
	var peak := Vector3(cx, y0 + rise + 0.35, z)
	var right := Vector3(cx + width * 0.52, y0, z)
	lm.beam(mat, left, peak, 0.65, depth + 0.5)
	lm.beam(mat, peak, right, 0.65, depth + 0.5)

## Mansard roof sitting on y0 with hipped steep skirt, flat crown, and optional dormer rows.
static func mansard_roof(lm: LandmarkMesh, roof_mat: String, stone_mat: String, glass_mat: String,
		c: Vector3, w: float, d: float, h: float, dormers_x: int = 0) -> void:
	var low := PackedVector2Array([
		Vector2(c.x - w * 0.5, c.z - d * 0.5), Vector2(c.x + w * 0.5, c.z - d * 0.5),
		Vector2(c.x + w * 0.5, c.z + d * 0.5), Vector2(c.x - w * 0.5, c.z + d * 0.5)])
	var inset := minf(h * 0.65, minf(w, d) * 0.22)
	var high := PackedVector2Array([
		Vector2(c.x - w * 0.5 + inset, c.z - d * 0.5 + inset),
		Vector2(c.x + w * 0.5 - inset, c.z - d * 0.5 + inset),
		Vector2(c.x + w * 0.5 - inset, c.z + d * 0.5 - inset),
		Vector2(c.x - w * 0.5 + inset, c.z + d * 0.5 - inset)])
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
	lm.box(roof_mat, Vector3(c.x, c.y + h - 0.15, c.z), Vector3(w - inset * 2.0, 0.3, d - inset * 2.0))
	if dormers_x > 0:
		for sz in [-1.0, 1.0]:
			var dz := c.z + float(sz) * (d * 0.5 - inset * 0.45)
			for i in dormers_x:
				var dx := lerpf(c.x - w * 0.42, c.x + w * 0.42, (float(i) + 0.5) / float(dormers_x))
				lm.box(stone_mat, Vector3(dx, c.y + h * 0.48, dz), Vector3(1.5, h * 0.62, 1.4))
				lm.box(glass_mat, Vector3(dx, c.y + h * 0.48, dz + float(sz) * 0.72), Vector3(1.0, h * 0.44, 0.12))

## Victorian Thames cast-iron globe lamp standard at base `pos`.
static func globe_lamp(lm: LandmarkMesh, iron_mat: String, lamp_mat: String, pos: Vector3, h: float = 3.8) -> void:
	lm.frustum(iron_mat, pos, 0.24, 0.08, h - 0.55, 6)
	lm.frustum(lamp_mat, pos + Vector3(0.0, h - 0.55, 0.0), 0.22, 0.28, 0.35, 8)
	lm.frustum(lamp_mat, pos + Vector3(0.0, h - 0.20, 0.0), 0.28, 0.10, 0.25, 8)

## Elliptical arch rib between x0 and x1, springing at y_spring and peaking at y_crown, at Z = z.
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
