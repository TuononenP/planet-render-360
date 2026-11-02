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
	var prof := PackedVector2Array([Vector2(56.0, -1.0), Vector2(56.0, 0), Vector2(51.0, 4.0),
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
	lm.commit(model)

## Central Market (26 m): the Art Deco hall of 1937, a high octagonal
## drum and shallow dome over four barrel-roofed arms, each ending in a
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
	for i in 16:
		var a := TAU * (float(i) + 0.5) / 16.0
		var out := Vector3(cos(a), 0, sin(a))
		lm.box("Dark", out * 12.45 + Vector3(0, 14.4, 0), Vector3(2.2, 5.4, 0.3),
			Basis(Vector3.UP, -a + PI * 0.5))
	lm.frustum("Trim", Vector3(0, 19.0, 0), 13.2, 13.2, 0.8, 16)
	var dome := PackedVector2Array()
	for i in 9:
		var t := PI * 0.5 * float(i) / 8.0
		dome.append(Vector2(12.8 * cos(t), 4.4 * sin(t)))
	lm.lathe("Dome", Vector3(0, 19.8, 0), dome, 24)
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
