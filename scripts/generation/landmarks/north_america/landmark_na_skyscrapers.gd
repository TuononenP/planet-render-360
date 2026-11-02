class_name LandmarkNaSkyscrapers
extends RefCounted

## Four skyscrapers in true metres: Chicago's Willis Tower, New York's
## Chrysler Building and Flatiron Building, San Francisco's Transamerica
## Pyramid. Manhattan's two are built in the street grid (the registry
## turns them 29°).

const WILLIS_TIP_M := 527.3
const WILLIS_ROOF_M := 442.1
const WILLIS_TUBE_M := 22.9
const CHRYSLER_TIP_M := 318.9
const CHRYSLER_CROWN_M := 198.0
const FLATIRON_TOP_M := 87.0
const TRANS_PYRAMID_M := 205.0
const TRANS_TIP_M := 260.0

## Willis Tower: nine 22.9 m square black-aluminium tubes bundled 3 x 3,
## dropping out as it rises (two end at the 50th floor, two at the 66th,
## three at the 90th) until two reach the 442 m roof, carrying the two
## antennas to 527.3 m; belt-truss bands at the mechanical floors.
static func willis_tower(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Tower", LandmarkMaterials.paint("#1D1F22", 0.4, 0.6))
	lm.use("Glass", LandmarkMaterials.glass("#2B2620"))
	lm.use("Mast", LandmarkMaterials.paint("#CFD2D4", 0.4, 0.6))
	lm.use("Base", LandmarkMaterials.pbr("stone", "#6D6A64", 4.0))
	# Tube tops by row (north to south) and column (west to east).
	var tops := [[205.0, WILLIS_ROOF_M, 270.0], [345.0, WILLIS_ROOF_M, 345.0],
		[270.0, 345.0, 205.0]]
	var span := WILLIS_TUBE_M
	for j in 3:
		for i in 3:
			var h: float = tops[j][i]
			var c := Vector3((i - 1) * span, 0, (j - 1) * span)
			lm.box("Tower", c + Vector3(0, h * 0.5, 0), Vector3(span, h, span))
			lm.box("Mast", c + Vector3(0, h - 0.5, 0), Vector3(span + 0.3, 1.0, span + 0.3))
			for q in 4:
				var r := Basis(Vector3.UP, PI * 0.5 * q)
				for k in 6:
					var x := -9.0 + 3.6 * k
					lm.box("Glass", c + r * Vector3(x, h * 0.5 - 1.5, span * 0.5 + 0.05),
						Vector3(2.4, h - 9.0, 0.2), r)
			# Belt trusses at the mechanical floors (29-31, 64-66, 88-90).
			for band in [[112.0, 122.0], [226.0, 234.0], [318.0, 326.0]]:
				if h > float(band[1]) + 8.0:
					lm.box("Tower", c + Vector3(0, (float(band[0]) + float(band[1])) * 0.5, 0),
						Vector3(span + 0.5, float(band[1]) - float(band[0]), span + 0.5))
	lm.box("Base", Vector3(0, -0.5, 0), Vector3(84.0, 2.0, 84.0))
	var ants := [[Vector3(-6.0, WILLIS_ROOF_M, 0.0), WILLIS_TIP_M],
		[Vector3(6.0, WILLIS_ROOF_M, -span), WILLIS_TIP_M - 7.0]]
	for a in ants:
		var base: Vector3 = a[0]
		lm.lathe("Mast", base, PackedVector2Array([Vector2(1.7, 0.0), Vector2(1.0, 35.0),
			Vector2(0.15, float(a[1]) - WILLIS_ROOF_M)]), 8)
	lm.commit(model)

## Chrysler Building: the white-and-grey brick tower in its setbacks to
## the 61st floor, the corner eagles there, then the seven concentric
## terraced arches of the stainless-steel crown with their triangular
## windows and the 38 m needle ("Vertex") to 318.9 m.
static func chrysler_building(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#C9C3B6", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#D2CBBB", 3.0))
	lm.use("Steel", LandmarkMaterials.paint("#C9CFD4", 0.22, 0.9))
	lm.use("Glass", LandmarkMaterials.glass("#3A4349"))
	# [y0, y1, half-width] stacked masses.
	var masses := [[0.0, 30.0, 29.0], [30.0, 58.0, 25.0], [58.0, 120.0, 21.0],
		[120.0, 184.0, 17.5], [184.0, CHRYSLER_CROWN_M, 15.0]]
	for m in masses:
		var y0: float = m[0]
		var y1: float = m[1]
		var hw: float = m[2]
		lm.box("Brick", Vector3(0, (y0 + y1) * 0.5, 0), Vector3(hw * 2.0, y1 - y0, hw * 2.0))
		lm.box("Trim", Vector3(0, y1 - 0.6, 0), Vector3(hw * 2.0 + 1.2, 1.2, hw * 2.0 + 1.2))
		var bays := floori(hw * 2.0 / 3.4)
		for q in 4:
			var r := Basis(Vector3.UP, PI * 0.5 * q)
			for k in bays:
				var x := -hw + hw * 2.0 * (float(k) + 0.5) / float(bays)
				lm.box("Glass", r * Vector3(x, (y0 + y1) * 0.5, hw + 0.05),
					Vector3(1.5, y1 - y0 - 3.0, 0.2), r)
	# Corner eagles on the 61st floor.
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			lm.beam("Steel", Vector3(sx * 14.0, CHRYSLER_CROWN_M - 2.0, sz * 14.0),
				Vector3(sx * 18.5, CHRYSLER_CROWN_M + 0.5, sz * 18.5), 2.0, 2.0)
	# Crown: seven arches, each drawing in to the next, with sunburst windows.
	var radii := [13.5, 12.0, 10.5, 9.0, 7.5, 6.0, 4.5, 3.0]
	for i in 7:
		var y := CHRYSLER_CROWN_M + 12.0 * i
		var r0: float = radii[i]
		var r1: float = radii[i + 1]
		lm.lathe("Steel", Vector3(0, y, 0), PackedVector2Array([Vector2(r0, 0.0),
			Vector2(r0 * 0.99, 5.0), Vector2(lerpf(r0, r1, 0.75), 9.6), Vector2(r1 * 1.06, 11.4),
			Vector2(r1, 12.0)]), 8, 1.0, 1.0, PI / 8.0, false)
		for q in 4:
			var b := Basis(Vector3.UP, PI * 0.5 * q)
			var w := r0 * 0.45
			var a0 := r0 * 0.924 + 0.12
			var a1 := lerpf(r0, r1, 0.75) * 0.924 + 0.12
			var n := b * Vector3(0, 0.25, 1.0).normalized()
			lm.tri("Glass", b * Vector3(-w, y + 1.8, a0), b * Vector3(w, y + 1.8, a0),
				b * Vector3(0, y + 9.0, a1), n, n, n, Vector2(0, 0), Vector2(w * 2.0, 0),
				Vector2(w, -7.0))
	var needle := CHRYSLER_CROWN_M + 84.0
	lm.lathe("Steel", Vector3(0, needle, 0), PackedVector2Array([Vector2(3.0, 0.0), Vector2(2.0, 10.0),
		Vector2(1.0, 22.0), Vector2(0.15, CHRYSLER_TIP_M - needle)]), 8)
	lm.commit(model)

## Transamerica Pyramid: the quartz-clad four-sided pyramid narrowing
## from 53 m to 14 m over 205 m with its window rows, the elevator and
## stair wings rising vertically from the 29th floor on the east and
## west faces, and the aluminium spire (crown) to 260 m.
static func transamerica_pyramid(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Concrete", LandmarkMaterials.pbr("limestone", "#E9E6DD", 3.0))
	lm.use("Glass", LandmarkMaterials.glass("#3B4750"))
	lm.use("Spire", LandmarkMaterials.paint("#D8DCDF", 0.3, 0.8))
	lm.use("Base", LandmarkMaterials.pbr("stone", "#8E8A82", 4.0))
	lm.spire("Concrete", Vector3.ZERO, 26.5, TRANS_PYRAMID_M, 7.0)
	for s in [-1.0, 1.0]:
		lm.box("Concrete", Vector3(s * 10.5, 165.0, 0), Vector3(12.0, 94.0, 8.0))
	lm.spire("Spire", Vector3(0, TRANS_PYRAMID_M, 0), 7.0, TRANS_TIP_M - TRANS_PYRAMID_M, 0.3)
	var slope := Vector3(0, 19.5 / TRANS_PYRAMID_M, 1.0).normalized()
	for q in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * q)
		var y := 5.0
		while y + 3.2 < TRANS_PYRAMID_M - 4.0:
			var h0 := 26.5 - 19.5 * y / TRANS_PYRAMID_M + 0.1
			var h1 := 26.5 - 19.5 * (y + 3.2) / TRANS_PYRAMID_M + 0.1
			lm.quad("Glass", r * Vector3(-h0 * 0.94, y, h0), r * Vector3(h0 * 0.94, y, h0),
				r * Vector3(h1 * 0.94, y + 3.2, h1), r * Vector3(-h1 * 0.94, y + 3.2, h1), r * slope)
			y += 6.4
	lm.box("Base", Vector3(0, -0.5, 0), Vector3(62.0, 1.6, 62.0))
	lm.commit(model)

## Flatiron Building: the 87 m wedge between Fifth Avenue (east) and
## Broadway (west), its prow rounded at the north end, a rusticated
## base, limestone and terracotta shaft with window bays on every
## face, string courses and the projecting cornice.
static func flatiron(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Limestone", LandmarkMaterials.pbr("limestone", "#D6CFBF", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#E1DACB", 3.0))
	lm.use("Glass", LandmarkMaterials.glass("#2F3A40"))
	var raw := [Vector2(11.5, -43.0), Vector2(14.0, -41.0), Vector2(14.0, 43.0), Vector2(-27.0, 43.0)]
	var poly := PackedVector2Array()
	for p in raw:
		poly.append((p as Vector2) - Vector2(0, 14.3))
	lm.poly_prism("Limestone", poly, 0.0, FLATIRON_TOP_M - 4.0)
	lm.poly_prism("Trim", _grow(poly, 0.6), 0.0, 9.0, false)
	for y in [30.0, 55.0]:
		lm.poly_prism("Trim", _grow(poly, 0.5), y, y + 1.2)
	lm.poly_prism("Trim", _grow(poly, 1.6), FLATIRON_TOP_M - 4.5, FLATIRON_TOP_M)
	for e in poly.size():
		var a := poly[e]
		var b := poly[(e + 1) % poly.size()]
		var length := a.distance_to(b)
		if length < 8.0:
			continue
		var dir := (b - a) / length
		var n := Vector2(dir.y, -dir.x)
		if n.dot((a + b) * 0.5) < 0.0:
			n = -n
		var basis := Basis(Vector3.UP, atan2(n.x, n.y))
		var bays := floori(length / 3.2)
		for k in bays:
			var p := a + dir * length * (float(k) + 0.5) / float(bays) + n * 0.05
			lm.box("Glass", Vector3(p.x, 44.0, p.y), Vector3(1.6, 66.0, 0.2), basis)
	lm.commit(model)

static func _grow(poly: PackedVector2Array, by: float) -> PackedVector2Array:
	var out: Array = Geometry2D.offset_polygon(poly, by, Geometry2D.JOIN_MITER)
	return out[0]
