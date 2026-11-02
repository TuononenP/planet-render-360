class_name LandmarkMaTowers
extends RefCounted

## Three tall concrete towers in true metres: Tehran's Milad Tower,
## the Cairo Tower and the Kuwait Towers.

# --- Milad Tower ---

## 435 m telecommunications tower: tapering concrete shaft, the
## 68 m glazed head (12 floors, bulging above a narrow neck) at 247 m
## and the 120 m steel antenna with its service platforms.
static func milad(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Shaft", LandmarkMaterials.pbr("concrete", "#CFCBC2", 5.0))
	lm.use("Head", LandmarkMaterials.glass("#4A5C68"))
	lm.use("Mast", LandmarkMaterials.paint("#E8E8E6", 0.4, 0.4))
	lm.use("Rim", LandmarkMaterials.pbr("concrete", "#B9B4A8", 4.0))
	lm.lathe("Shaft", Vector3.ZERO, PackedVector2Array([Vector2(24, 0), Vector2(18, 6),
		Vector2(14, 40), Vector2(10.5, 120), Vector2(8.0, 247)]), 24)
	lm.lathe("Head", Vector3(0, 247, 0), PackedVector2Array([Vector2(8, 0), Vector2(18, 4),
		Vector2(27, 14), Vector2(30, 26), Vector2(30, 46), Vector2(24, 58), Vector2(10, 68)]), 24)
	for y in [26.0, 46.0]:
		lm.frustum("Rim", Vector3(0, 247.0 + y, 0), 30.4, 30.4, 1.2, 24)
	lm.frustum("Rim", Vector3(0, 313, 0), 12.0, 10.0, 2.0, 24)
	LandmarkMaParts.needle(lm, "Mast", Vector3(0, 315, 0), PackedVector2Array([Vector2(0, 5.0),
		Vector2(30, 3.6), Vector2(60, 2.4), Vector2(90, 1.2), Vector2(120, 0.2)]), 12)
	lm.frustum("Rim", Vector3(0, 345, 0), 6.0, 6.0, 3.0, 16)
	lm.frustum("Rim", Vector3(0, 385, 0), 4.0, 4.0, 2.0, 16)
	lm.commit(model)

# --- Cairo Tower ---

const CAIRO_STRANDS := 16
const CAIRO_RING_Y := 145.0

## Lotus-stem radius of the lattice at height y (waist at 95 m).
static func _cairo_r(y: float) -> float:
	if y <= 95.0:
		return 7.0 + 9.0 * pow((95.0 - y) / 92.0, 2.0)
	return 7.0 + 10.0 * pow((y - 95.0) / 50.0, 2.0)

## 187 m granite-concrete lattice tower in the shape of a lotus stem:
## 16 strands twisting each way over a waist at 95 m, a ring at 145 m,
## the revolving-restaurant drum and observation deck, then the mast.
static func cairo_tower(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Lattice", LandmarkMaterials.pbr("concrete", "#C4BCAC", 3.0))
	lm.use("Glass", LandmarkMaterials.glass("#3E4C54"))
	lm.use("Mast", LandmarkMaterials.paint("#9AA3AA", 0.4, 0.6))
	lm.use("Base", LandmarkMaterials.pbr("pavement", "#CFC6B2", 5.0))
	lm.frustum("Base", Vector3(0, -2, 0), 32.0, 30.0, 4.0, 24)
	var segs := 20
	for k in segs:
		var y0 := 3.0 + (CAIRO_RING_Y - 3.0) * k / segs
		var y1 := 3.0 + (CAIRO_RING_Y - 3.0) * (k + 1) / segs
		for dir in [-1.0, 1.0]:
			for i in CAIRO_STRANDS:
				var a0: float = TAU * i / CAIRO_STRANDS + dir * 0.8 * y0 / CAIRO_RING_Y
				var a1: float = TAU * i / CAIRO_STRANDS + dir * 0.8 * y1 / CAIRO_RING_Y
				var r0 := _cairo_r(y0)
				var r1 := _cairo_r(y1)
				lm.beam("Lattice", Vector3(cos(a0) * r0, y0, sin(a0) * r0),
					Vector3(cos(a1) * r1, y1, sin(a1) * r1), 0.9)
	lm.frustum("Lattice", Vector3(0, 142, 0), 15.5, 19.0, 6.0, 24)
	lm.frustum("Glass", Vector3(0, 148, 0), 18.0, 18.0, 10.0, 24)
	lm.frustum("Lattice", Vector3(0, 158, 0), 19.0, 19.0, 2.5, 24)
	LandmarkMaParts.dome(lm, "Lattice", Vector3(0, 160.5, 0), 14.0, 8.0, 24)
	lm.frustum("Glass", Vector3(0, 168.5, 0), 6.0, 6.0, 6.0, 16)
	lm.frustum("Lattice", Vector3(0, 174.5, 0), 6.5, 6.5, 1.0, 16)
	LandmarkMaParts.needle(lm, "Mast", Vector3(0, 175.5, 0),
		PackedVector2Array([Vector2(0, 2.0), Vector2(11.5, 0.2)]), 8)
	lm.commit(model)

# --- Kuwait Towers ---

## Three slender towers: the 187 m main tower with a 32 m water sphere
## at 82 m and an observation sphere at 123 m, the 147 m second tower
## with one sphere and the 113 m service needle. Spheres are covered in
## blue-green enamel mosaic.
static func kuwait_towers(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Shaft", LandmarkMaterials.pbr("concrete", "#D6D3CC", 4.0))
	lm.use("Sphere", LandmarkMaterials.pbr("render", "#3F8E9C", 2.0, 0.3, 0.2))
	lm.use("Needle", LandmarkMaterials.paint("#C9CED2", 0.35, 0.7))
	lm.use("Plinth", LandmarkMaterials.pbr("pavement", "#CFC6B2", 5.0))
	lm.box("Plinth", Vector3(0, -1, 0), Vector3(330, 2, 90))
	_kuwait_tower(lm, Vector3(45, 0, 0), 187.0, 82.0, 16.0, 123.0, 9.0)
	_kuwait_tower(lm, Vector3(-45, 0, 0), 147.0, 64.0, 12.0, 0.0, 0.0)
	_kuwait_tower(lm, Vector3(130, 0, 0), 113.0, 0.0, 0.0, 0.0, 0.0)
	lm.commit(model)

## One tower of height h: tapering shaft and needle, up to two spheres.
static func _kuwait_tower(lm: LandmarkMesh, base: Vector3, h: float, y1: float, r1: float,
		y2: float, r2: float) -> void:
	var s := h / 187.0
	var shaft_h := 0.86 * (h - 2.0)
	lm.frustum("Plinth", base, 9.0 * s + 3.0, 8.0 * s + 3.0, 2.0, 16)
	LandmarkMaParts.needle(lm, "Shaft", base + Vector3(0, 2, 0), PackedVector2Array([
		Vector2(0, 6.5 * s), Vector2(60 * s, 3.0 * s), Vector2(123 * s, 1.4 * s),
		Vector2(shaft_h, 0.7)]), 16)
	LandmarkMaParts.needle(lm, "Needle", base + Vector3(0, 2.0 + shaft_h, 0), PackedVector2Array([
		Vector2(0, 0.7), Vector2(h - 2.0 - shaft_h, 0.12)]), 8)
	if r1 > 0.0:
		LandmarkMaParts.sphere(lm, "Sphere", base + Vector3(0, y1, 0), r1, 24, 12)
	if r2 > 0.0:
		LandmarkMaParts.sphere(lm, "Sphere", base + Vector3(0, y2, 0), r2, 20, 10)
