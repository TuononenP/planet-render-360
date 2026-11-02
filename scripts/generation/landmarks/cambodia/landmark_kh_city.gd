class_name LandmarkKhCity
extends RefCounted

## Phnom Penh city landmarks in true metres: Wat Phnom on its artificial
## hill and the Art Deco Central Market (Phsar Thmei).

const U = preload("res://scripts/generation/landmarks/cambodia/landmark_kh_util.gd")

## Wat Phnom (46 m above the street): the 27 m artificial hill, the main
## east stair between naga balustrades (with plainer stairs on three other
## sides), the hilltop platform with the three-tier-roofed vihara and the
## white bell stupa of King Ponhea Yat. Built facing +X (east).
static func wat_phnom(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Hill", LandmarkMaterials.pbr("grass", "#5E7B3A", 5.0))
	lm.use("Stair", LandmarkMaterials.pbr("pavement", "#B5AC9A", 3.0))
	lm.use("Wall", LandmarkMaterials.pbr("render", "#EFE6CF", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("terracotta", "#C8622A", 3.0))
	lm.use("Red", LandmarkMaterials.pbr("render", "#8E3328", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#E6DDC8", 3.0))
	lm.use("Gold", LandmarkMaterials.gold())
	# The mound: an ellipse, 70 x 50 m radii at the foot, 35 x 25 m on top.
	var prof := PackedVector2Array([Vector2(56.0, 0), Vector2(51.0, 4.0),
		Vector2(44.0, 11.0), Vector2(37.0, 18.0), Vector2(32.0, 24.0), Vector2(28.0, 27.0)])
	lm.lathe("Hill", Vector3.ZERO, prof, 48, 1.25, 0.9)
	lm.frustum("Trim", Vector3(0, 27.0, 0), 28.0, 27.6, 1.2, 48, 0.0, 1.25, 0.9)
	var top := 28.2
	# Main stair east (nagas) and plain stairs on the other three sides.
	var eb := Basis(Vector3.UP, PI * 0.5)
	U.stair(lm, "Stair", Vector3(35.0, 0, 0), eb, 9.0, 65, 0.54, top / 65.0)
	for sz in [-1.0, 1.0]:
		U.naga_rail(lm, "Trim", Vector3(35.0, 0, sz * 5.0), eb, 34.5, top, 0.0, 1.0, 7)
	var others := [[Basis(), 22.5, 45.0, 4.0], [Basis(Vector3.UP, PI), 22.5, 45.0, 4.0],
		[Basis(Vector3.UP, -PI * 0.5), 35.0, 70.0, 5.0]]
	for o in others:
		var ob: Basis = o[0]
		var top_r: float = o[1]
		var run: float = o[2] - top_r
		var n := int(run / 0.55)
		U.stair(lm, "Stair", ob * Vector3(0, 0, top_r), ob, o[3], n, run / float(n), top / float(n))
	# Vihara at the east of the platform, ridge along Z; stupa to the west.
	U.hall(lm, "Wall", "Trim", "Roof", "Red", Vector3(14.0, top, 0), Basis(), 12.0, 24.0, 1.0, 7.0,
		3.4, 3, 8)
	U.stupa(lm, "Wall", "Gold", Vector3(-12.0, top, 0), 3.9, 46.0 - top)
	# Bell tower and a shrine pavilion on the platform.
	U.hall(lm, "Wall", "Trim", "Roof", "Red", Vector3(-2.0, top, 13.0), Basis(), 5.0, 7.0, 0.8, 4.0,
		2.4, 2, 0)
	U.hall(lm, "Wall", "Trim", "Roof", "Red", Vector3(-2.0, top, -13.0), Basis(), 5.0, 7.0, 0.8, 4.0,
		2.4, 2, 0)
	# Guardian lions at the foot and the head of the east stair.
	for sz in [-1.0, 1.0]:
		_lion(lm, "Trim", Vector3(71.5, 0, sz * 6.6), Basis(Vector3.UP, PI * 0.5), 2.4)
		_lion(lm, "Trim", Vector3(36.5, top, sz * 6.6), Basis(Vector3.UP, PI * 0.5), 1.8)
	# Small stupas at the platform corners.
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			U.stupa(lm, "Wall", "Gold", Vector3(sx * 24.0 + 2.0, top, sz * 17.0), 1.0, 5.0)
	# The trees that cover the mound, between the four stairs.
	lm.use("Leaf", LandmarkMaterials.pbr("forest", "#3F5F2C", 4.0))
	lm.use("Bark", LandmarkMaterials.pbr("wood", "#5A4A3A", 2.0))
	var rim := [[51.0, 4.0], [44.0, 11.0], [37.0, 18.0]]
	for j in 3:
		var r: float = rim[j][0]
		var yy: float = rim[j][1]
		for i in 12:
			var a := TAU * (float(i) + 0.5 + 0.3 * float(j)) / 12.0
			var d := Vector3(cos(a), 0, sin(a))
			if absf(d.x) > 0.93 or absf(d.z) > 0.93:
				continue
			var p := Vector3(d.x * r * 1.25, yy, d.z * r * 0.9) * 0.96
			var th := 7.0 + 2.0 * float((i + j) % 3)
			lm.frustum("Bark", p, 0.35, 0.22, th * 0.6, 6)
			lm.lathe("Leaf", p + Vector3(0, th * 0.45, 0), PackedVector2Array([Vector2(0.4, 0),
				Vector2(3.0, th * 0.12), Vector2(3.6, th * 0.3), Vector2(2.6, th * 0.48), Vector2(0.0, th * 0.58)]), 8)
	lm.commit(model)

## Seated Khmer guardian lion of height h at `base`, facing the basis +Z:
## plinth, haunches, upright forelegs, maned chest and the open-jawed head.
static func _lion(lm: LandmarkMesh, key: String, base: Vector3, b: Basis, h: float) -> void:
	lm.box(key, base + b * Vector3(0, h * 0.08, 0), Vector3(h * 0.5, h * 0.16, h * 0.8), b)
	lm.box(key, base + b * Vector3(0, h * 0.3, -h * 0.15), Vector3(h * 0.42, h * 0.3, h * 0.45), b)
	for sx in [-1.0, 1.0]:
		lm.box(key, base + b * Vector3(sx * h * 0.12, h * 0.35, h * 0.18), Vector3(h * 0.1, h * 0.4, h * 0.12), b)
	lm.box(key, base + b * Vector3(0, h * 0.6, h * 0.05), Vector3(h * 0.4, h * 0.3, h * 0.34), b)
	lm.box(key, base + b * Vector3(0, h * 0.82, h * 0.1), Vector3(h * 0.34, h * 0.24, h * 0.3), b)
	lm.box(key, base + b * Vector3(0, h * 0.78, h * 0.3), Vector3(h * 0.2, h * 0.12, h * 0.14), b)
	lm.box(key, base + b * Vector3(0, h * 0.68, h * 0.27), Vector3(h * 0.18, h * 0.05, h * 0.12), b, 0.0)
	lm.box(key, base + b * Vector3(0, h * 0.97, h * 0.04), Vector3(h * 0.24, h * 0.06, h * 0.2), b, 0.0)

## Central Market (26 m): Jean Desbois' Art Deco hall of 1937, a high
## octagonal base, a louvred drum and a ribbed shallow dome over four
## barrel-roofed arms reaching diagonally across the block, each ending in a
## stepped, finned frontage; yellow stucco and pale roofs. Arms run along
## the model axes (the registry yaw turns them onto the block).
static func central_market(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("render", "#E3C45C", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("render", "#F1E6BE", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("concrete", "#BDB48E", 3.0))
	lm.use("Dark", LandmarkMaterials.pbr("concrete", "#3A3630", 2.0))
	lm.use("Dome", LandmarkMaterials.pbr("render", "#EDE0AE", 3.0))
	# Central octagon, tall drum with window slits, shallow dome, lantern.
	lm.frustum("Wall", Vector3.ZERO, 17.0, 17.0, 9.0, 8, PI / 8.0)
	lm.box("Trim", Vector3(0, 9.2, 0), Vector3(30.0, 0.4, 30.0))
	lm.frustum("Wall", Vector3(0, 9.0, 0), 12.5, 12.5, 10.0, 16)
	# Drum: sixteen louvred bays between piers (the hall breathes through
	# its stacked concrete slats, not glass).
	for i in 16:
		var a := TAU * (float(i) + 0.5) / 16.0
		var out := Vector3(cos(a), 0, sin(a))
		var bb := Basis(Vector3.UP, -a + PI * 0.5)
		lm.box("Dark", out * 12.45 + Vector3(0, 14.4, 0), Vector3(3.4, 6.4, 0.3), bb, 0.0)
		for q in 7:
			lm.box("Trim", out * 12.62 + Vector3(0, 11.6 + 0.9 * float(q), 0), Vector3(3.4, 0.12, 0.4), bb, 0.0)
		var ap := TAU * float(i) / 16.0
		lm.box("Trim", Vector3(cos(ap), 0, sin(ap)) * 12.6 + Vector3(0, 14.0, 0), Vector3(0.7, 9.6, 0.6),
			Basis(Vector3.UP, -ap + PI * 0.5))
	lm.frustum("Trim", Vector3(0, 19.0, 0), 13.2, 13.2, 0.8, 16)
	var dome := PackedVector2Array()
	for i in 9:
		var t := PI * 0.5 * float(i) / 8.0
		dome.append(Vector2(12.8 * cos(t), 4.4 * sin(t)))
	lm.lathe("Dome", Vector3(0, 19.8, 0), dome, 24)
	# Ribs over the dome and three louvred rings round its haunches.
	for i in 16:
		var a := TAU * float(i) / 16.0
		var d := Vector3(cos(a), 0, sin(a))
		for j in 7:
			var p0 := dome[j]
			var p1 := dome[j + 1]
			lm.beam("Trim", Vector3(0, 19.8 + p0.y + 0.15, 0) + d * (p0.x + 0.1),
				Vector3(0, 19.8 + p1.y + 0.15, 0) + d * (p1.x + 0.1), 0.5, 0.3, d.cross(Vector3.UP))
	for q in 3:
		var t0 := PI * 0.5 * (1.5 + 1.6 * float(q)) / 8.0
		lm.frustum("Dark", Vector3(0, 19.8 + 4.4 * sin(t0), 0), 12.8 * cos(t0) + 0.15, 12.8 * cos(t0) - 0.25,
			0.6, 24)
		lm.frustum("Trim", Vector3(0, 19.8 + 4.4 * sin(t0) + 0.6, 0), 12.8 * cos(t0) + 0.3,
			12.8 * cos(t0) - 0.3, 0.18, 24)
	lm.frustum("Trim", Vector3(0, 24.2, 0), 2.0, 1.6, 1.4, 12)
	lm.spire("Trim", Vector3(0, 25.6, 0), 1.2, 0.4, 0.0, 8)
	# Four arms.
	for side in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * float(side))
		_arm(lm, b)
	lm.commit(model)

## One market arm along the basis +Z from the central octagon: walls with
## fins and a clerestory band, the barrel roof, and the stepped frontage.
static func _arm(lm: LandmarkMesh, b: Basis) -> void:
	var z0 := 14.0
	var z1 := 58.0
	var hw := 10.5
	var wall_h := 8.0
	lm.box("Wall", b * Vector3(0, wall_h * 0.5, (z0 + z1) * 0.5), Vector3(hw * 2.0, wall_h, z1 - z0), b)
	var fins := 9
	for i in fins:
		var z := z0 + 4.0 + (z1 - z0 - 10.0) * float(i) / float(fins - 1)
		for sx in [-1.0, 1.0]:
			lm.box("Trim", b * Vector3(sx * (hw + 0.2), wall_h * 0.5 + 0.8, z), Vector3(0.6, wall_h + 1.6, 1.4), b)
			lm.box("Dark", b * Vector3(sx * (hw + 0.05), wall_h * 0.62, z + 2.2), Vector3(0.1, 4.6, 1.8), b)
	# Barrel roof: a half-ellipse in cross-section, extruded along the arm.
	var rows: Array = []
	for zz in [z0, z1 - 1.0]:
		var row := PackedVector3Array()
		for i in 15:
			var t := PI * float(i) / 14.0
			row.append(b * Vector3(hw * cos(t) * 1.04, wall_h + 5.5 * sin(t), zz))
		rows.append(row)
	lm.grid("Roof", rows, b * Vector3(0, wall_h, (z0 + z1) * 0.5), true)
	# Transverse ribs over the barrel at every fin, the louvred clerestory
	# band along both springings.
	for i in fins:
		var z := z0 + 4.0 + (z1 - z0 - 10.0) * float(i) / float(fins - 1)
		for j in 14:
			var t0 := PI * float(j) / 14.0
			var t1 := PI * float(j + 1) / 14.0
			lm.beam("Trim", b * Vector3(hw * cos(t0) * 1.06, wall_h + 5.6 * sin(t0) + 0.1, z),
				b * Vector3(hw * cos(t1) * 1.06, wall_h + 5.6 * sin(t1) + 0.1, z), 0.4, 0.3, b * Vector3.BACK)
	for sx in [-1.0, 1.0]:
		for q in 3:
			lm.box("Trim", b * Vector3(sx * (hw + 0.1), wall_h - 1.3 + 0.45 * float(q), (z0 + z1) * 0.5),
				Vector3(0.35, 0.1, z1 - z0), b, 0.0)
		lm.box("Dark", b * Vector3(sx * (hw + 0.02), wall_h - 0.85, (z0 + z1) * 0.5),
			Vector3(0.1, 1.3, z1 - z0 - 0.4), b, 0.0)
	# Tympanum closing the arch against the drum.
	var cn := b * Vector3(0, wall_h, z0)
	var nrm := b * Vector3(0, 0, -1)
	for i in 14:
		var t0 := PI * float(i) / 14.0
		var t1 := PI * float(i + 1) / 14.0
		lm.tri("Roof", cn, b * Vector3(hw * cos(t0) * 1.04, wall_h + 5.5 * sin(t0), z0),
			b * Vector3(hw * cos(t1) * 1.04, wall_h + 5.5 * sin(t1), z0), nrm, nrm, nrm,
			Vector2(0, 0), Vector2(1, 0), Vector2(1, 1))
	# Frontage: three stepped blocks with tall window slits.
	lm.box("Trim", b * Vector3(0, 7.0, z1 - 0.5), Vector3(hw * 2.0 + 1.0, 14.0, 1.6), b)
	lm.box("Trim", b * Vector3(0, 8.5, z1 - 0.6), Vector3(hw * 1.4, 17.0, 1.4), b)
	lm.box("Trim", b * Vector3(0, 9.5, z1 - 0.7), Vector3(hw * 0.7, 19.0, 1.2), b)
	for sx in [-1.0, 0.0, 1.0]:
		lm.box("Dark", b * Vector3(sx * hw * 0.55, 6.0, z1 + 0.35), Vector3(hw * 0.28, 10.0, 0.15), b)
	lm.box("Dark", b * Vector3(0, 13.0, z1 + 0.15), Vector3(hw * 0.28, 8.0, 0.15), b)
	# Horizontal louvre slats across the frontage openings, a cornice band
	# on each step and the vertical Art Deco fins between the openings.
	for sx in [-1.0, 0.0, 1.0]:
		for q in 9:
			lm.box("Trim", b * Vector3(sx * hw * 0.55, 1.5 + 1.0 * float(q), z1 + 0.5),
				Vector3(hw * 0.28, 0.1, 0.3), b, 0.0)
	for q in 7:
		lm.box("Trim", b * Vector3(0, 9.5 + 1.0 * float(q), z1 + 0.3), Vector3(hw * 0.28, 0.1, 0.3), b, 0.0)
	for e in [[hw * 2.0 + 1.0, 14.0, -0.5], [hw * 1.4, 17.0, -0.6], [hw * 0.7, 19.0, -0.7]]:
		lm.box("Wall", b * Vector3(0, float(e[1]) + 0.2, z1 + float(e[2])), Vector3(float(e[0]) + 0.4, 0.4,
			2.0), b)
	for sx in [-1.0, 1.0]:
		for f in [0.27, 0.83]:
			lm.box("Wall", b * Vector3(sx * hw * f, 7.0, z1 + 0.45), Vector3(0.5, 13.0, 0.5), b)
