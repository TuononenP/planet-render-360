class_name LandmarkRmAArena
extends RefCounted

## The Circus Maximus, the Baths of Caracalla and the Theatre of Marcellus
## in true metres.

# --- Circus Maximus ---------------------------------------------------

const C_HALF := 310.5
const C_WIDTH := 59.0
const C_CURVE := 251.5

## The 621 x 118 m course along X, flat end (the carceres, twelve brick
## starting gates between two towers) at -X and the curve (sphendone) at
## +X: sand track, the low marble spina with its basins and the turning
## posts (three cones on a half-round base at each end), stepped grass
## cavea all round, the excavated sphendone with its outer arcade, inner
## ring and the radial walls of the seating vaults, the foundations and
## column stumps of the Arch of Titus at the apex, and the Torre della
## Moletta (12th century) with its string courses, slits and merlons.
## yaw_deg turns +X onto the course (bearing 129).
static func circus(model: Node3D) -> void:
	var lm := RmAMesh.new()
	lm.use("Sand", LandmarkMaterials.pbr("sand", "#B9A47C", 6.0))
	lm.use("Lawn", LandmarkMaterials.pbr("lawn", "#78814E", 5.0))
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#94694D", 2.5))
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#CDC3AC", 3.0))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#4B4237", 3.0))
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#8E8472", 3.0))
	var poly := _u_outline(0.0, 0.0, 28)
	var poly2 := PackedVector2Array()
	for p in poly:
		poly2.append(Vector2(p.x, p.z))
	lm.poly_prism("Sand", poly2, 0.0, 0.12)
	# Spina with its water basins (euripus) and the two metae.
	lm.box("Marble", Vector3(0, 0.9, 0), Vector3(340.0, 1.8, 8.0))
	for i in 10:
		var x := -153.0 + 34.0 * float(i)
		lm.box("Shadow", Vector3(x, 1.82, 0), Vector3(26.0, 0.04, 5.0), Basis(), 0.0)
		lm.box("Marble", Vector3(x - 15.0, 2.4, 0), Vector3(2.6, 1.2, 2.6))
		lm.lathe("Marble", Vector3(x - 15.0, 3.0, 0), PackedVector2Array([Vector2(1.0, 0), Vector2(0.9, 0.6),
			Vector2(0.3, 1.4), Vector2(0, 1.6)]), 10)
	for sx in [-1.0, 1.0]:
		var mc := Vector3(sx * 175.0, 0, 0)
		lm.lathe("Marble", mc, PackedVector2Array([Vector2(5.2, 0), Vector2(5.2, 2.2), Vector2(4.9, 2.4)]), 20)
		for k in 3:
			lm.lathe("Marble", mc + Vector3(sx * 1.5, 2.4, -2.6 + 2.6 * float(k)),
				PackedVector2Array([Vector2(1.1, 0), Vector2(0.95, 1.0), Vector2(0.75, 2.6), Vector2(0.4, 4.4),
					Vector2(0.18, 5.4), Vector2(0, 6.0)]), 14)
	# Stepped cavea: four grassed tiers of 4 m treads rising 2 m, round the
	# long sides and the curve.
	for k in range(1, 5):
		var inner := _u_outline(4.0 * float(k - 1), 0.0, 24)
		var outer := _u_outline(4.0 * float(k), 0.0, 24)
		var h := 2.0 * float(k)
		for i in inner.size() - 1:
			var m := (inner[i] + inner[i + 1]) * 0.5
			var inward := _inward(m)
			lm.quad("Lawn", inner[i] + Vector3(0, h, 0), inner[i + 1] + Vector3(0, h, 0),
				outer[i + 1] + Vector3(0, h, 0), outer[i] + Vector3(0, h, 0), Vector3.UP)
			lm.quad("Lawn", inner[i] + Vector3(0, h - 2.0, 0), inner[i + 1] + Vector3(0, h - 2.0, 0),
				inner[i + 1] + Vector3(0, h, 0), inner[i] + Vector3(0, h, 0), inward)
	# Carceres: twelve starting gates and the two corner towers.
	RmAUtil.arcade(lm, "Brick", "Shadow", Vector3(-C_HALF, 0, -C_WIDTH), Vector3(-C_HALF, 0, C_WIDTH),
		Vector3.RIGHT, 12, 0.0, 6.5, 0.5, 0.5, 6.0)
	for sz in [-1.0, 1.0]:
		lm.box("Brick", Vector3(-C_HALF - 3.0, 6.0, sz * (C_WIDTH + 4.0)), Vector3(10.0, 12.0, 10.0))
		lm.box("Marble", Vector3(-C_HALF - 3.0, 12.25, sz * (C_WIDTH + 4.0)), Vector3(10.8, 0.5, 10.8))
	# Excavated sphendone: outer arcade, inner ring, radial vault walls.
	RmAUtil.arc_arcade(lm, "Brick", "Shadow", Vector3(C_CURVE, 0, 0), 77.0, -1.25, 1.25, 24, 0.0, 9.0,
		0.55, 0.5, 5.0, false, true)
	RmAUtil.arc_arcade(lm, "Brick", "Shadow", Vector3(C_CURVE, 0, 0), 66.0, -1.25, 1.25, 24, 0.0, 5.0,
		0.5, 0.5, 2.2, false, true)
	for i in 25:
		var a := -1.25 + 2.5 * float(i) / 24.0
		var d := Vector3(cos(a), 0, sin(a))
		var c0 := Vector3(C_CURVE, 0, 0)
		RmAUtil.ruin_wall(lm, "Brick", c0 + d * 66.2, c0 + d * 71.8, 1.6, 0.0, 4.0, 8.0, 1.9, float(i))
		lm.box("Concrete", c0 + d * 74.5 + Vector3(0, 8.6, 0), Vector3(2.0, 0.8, 4.2), Basis(Vector3.UP, -a))
	# Arch of Titus in the circus (AD 81): foundations and column stumps.
	var ta := Vector3(C_CURVE + 79.0, 0, 0)
	lm.box("Concrete", ta + Vector3(0, 0.7, 0), Vector3(15.0, 1.4, 17.0))
	for i in 4:
		for sz in [-1.0, 1.0]:
			var cp := ta + Vector3(-6.0 + 4.0 * float(i), 1.4, sz * 7.0)
			lm.box("Marble", cp + Vector3(0, 0.3, 0), Vector3(2.0, 0.6, 2.0))
			lm.lathe("Marble", cp + Vector3(0, 0.6, 0), PackedVector2Array([Vector2(0.85, 0), Vector2(0.9, 0.2),
				Vector2(0.72, 0.4), Vector2(0.65, 0.5), Vector2(0.62, 1.2 + 2.4 * absf(sin(float(i) * 2.3 + sz)))]), 20)
	# Torre della Moletta on its brick base.
	var tc := Vector3(318.0, 0, -20.0)
	lm.box("Brick", Vector3(312.0, 3.5, -20.0), Vector3(8.0, 7.0, 14.0))
	lm.box("Brick", tc + Vector3(0, 0.6, 0), Vector3(8.8, 1.2, 8.8))
	lm.box("Brick", tc + Vector3(0, 9.5, 0), Vector3(8.0, 17.4, 8.0))
	for y in [6.0, 12.5]:
		lm.box("Marble", tc + Vector3(0, float(y), 0), Vector3(8.3, 0.3, 8.3), Basis(), 0.0)
	lm.box("Brick", tc + Vector3(0, 18.6, 0), Vector3(8.6, 0.8, 8.6))
	for k in 4:
		var out := Vector3(sin(PI * 0.5 * float(k)), 0, cos(PI * 0.5 * float(k)))
		var right := Vector3.UP.cross(out)
		RmADetail.merlons(lm, "Brick", tc + out * 4.0 - right * 3.6 + Vector3(0, 19.0, 0),
			tc + out * 4.0 + right * 3.6 + Vector3(0, 19.0, 0), 0.9, 1.5, 0.6)
		for y in [3.0, 8.5, 14.5]:
			SEuUtil.opening(lm, "Shadow", tc + out * 4.04 + Vector3(0, float(y), 0), right, Vector3.UP, 0.35, 1.4)
		SEuUtil.opening(lm, "Shadow", tc + out * 4.04 + Vector3(0, 13.4, 0) + right * 1.8, right, Vector3.UP, 1.1, 2.4)
	lm.commit(model)

## Outline of the course at `d` metres outside the track edge, as points at
## height y: the north side, the curve, then the south side (back toward -X).
static func _u_outline(d: float, y: float, arc_n: int) -> Array[Vector3]:
	var out: Array[Vector3] = []
	var r := C_WIDTH + d
	out.append(Vector3(-C_HALF, y, -r))
	out.append(Vector3(C_CURVE, y, -r))
	for i in range(1, arc_n):
		var t := -PI * 0.5 + PI * float(i) / float(arc_n)
		out.append(Vector3(C_CURVE + cos(t) * r, y, sin(t) * r))
	out.append(Vector3(C_CURVE, y, r))
	out.append(Vector3(-C_HALF, y, r))
	return out

static func _inward(p: Vector3) -> Vector3:
	if p.x <= C_CURVE:
		return Vector3(0, 0, -signf(p.z))
	return (Vector3(C_CURVE, p.y, 0.0) - p).normalized()

# --- Baths of Caracalla -------------------------------------------------

## The ruined central block, 214 x 110 m, axis along Z: the open natatio
## and its high rear wall at the north-east (-Z) with its three tiers of
## statue niches between columns on consoles, the frigidarium with the
## standing piers of its three groin vaults and their springers, the
## column bases of its colossal granite order, the tepidarium, the great
## round caldarium (35 m) at the south-west (+Z) with its tall broken drum
## in two tiers of arches and windows, the two palaestrae with their
## colonnade stumps, apsed exedrae and niches, and the ruined service
## rooms. A brick pier at 30 m is the highest remnant. yaw_deg turns +Z
## onto 218 deg.
static func baths(model: Node3D) -> void:
	var lm := RmAMesh.new()
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#8F6246", 2.5))
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#8E8472", 3.0))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#4B4237", 3.0))
	lm.use("Paving", LandmarkMaterials.pbr("pavement", "#A39981", 3.0))
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#8B8985", 2.5))
	lm.box("Paving", Vector3(0, 0.15, 0), Vector3(214.0, 0.3, 110.0))
	# Frigidarium: long flank walls pierced by the palaestra passages, the
	# groin-vault piers and the transverse walls.
	for sx in [-1.0, 1.0]:
		RmAUtil.arch_wall(lm, "Brick", "Shadow", Vector3(sx * 29.0, 0, -33.0), Vector3.BACK,
			Vector3(sx, 0, 0), 0.0, 24.0, 0.0, 21.0, [[12.0, 12.0, 10.0, 0.0]], 4.5, 10)
		RmAUtil.ruin_wall(lm, "Brick", Vector3(sx * 29.0, 21.0, -33.0), Vector3(sx * 29.0, 21.0, -9.0), 4.5, 0.0, 1.0, 8.0, 3.0, sx)
		for z in [-28.0, -14.0]:
			lm.box("Brick", Vector3(sx * 24.0, 13.0, float(z)), Vector3(4.5, 26.0, 3.6))
	lm.box("Brick", Vector3(29.0, 15.0, -21.0), Vector3(4.5, 30.0, 4.0))
	for z in [-33.0, -9.0]:
		RmAUtil.arch_wall(lm, "Brick", "Shadow", Vector3(-24.0, 0, float(z) + 2.25), Vector3.RIGHT, Vector3.BACK,
			0.0, 48.0, 0.0, 14.0, [[12.0, 8.0, 7.0, 0.0], [36.0, 8.0, 7.0, 0.0]], 4.5, 8)
		RmAUtil.ruin_wall(lm, "Brick", Vector3(-24.0, 14.0, float(z)), Vector3(24.0, 14.0, float(z)), 4.5, 0.0, 0.5, 6.0, 3.0, z)
	for sx in [-1.0, 1.0]:
		for z in [-28.0, -14.0]:
			RmADetail.broken_column(lm, "Concrete", "Granite", Vector3(sx * 21.2, 0, float(z)), 1.0, 2.2 + 1.6 * absf(sin(float(z) * sx)))
			# Springers of the groin vaults leaning in off the pier tops.
			for dz in [-1.0, 1.0]:
				lm.beam("Brick", Vector3(sx * 24.0, 25.0, float(z) + float(dz) * 1.2),
					Vector3(sx * 21.0, 28.4, float(z) + float(dz) * 3.0), 3.0, 1.6)
	# Natatio: rear wall (the north-east facade) and side walls.
	RmAUtil.seg_box(lm, "Brick", Vector3(-26.0, 0, -55.0), Vector3(26.0, 0, -55.0), 3.4, 0.0, 15.5)
	RmAUtil.ruin_wall(lm, "Brick", Vector3(-26.0, 0, -55.0), Vector3(26.0, 0, -55.0), 3.4, 15.5, 0.5, 5.0, 2.6, 5.0)
	for tier in 3:
		var ty := 1.5 + 4.8 * float(tier)
		for i in 11:
			var nx := -21.0 + 4.2 * float(i)
			RmADetail.niche(lm, "Brick", "Shadow", Vector3(nx, ty, -53.3), Vector3.BACK, 1.8, 2.2, 0.5, 0.35)
			lm.box("Concrete", Vector3(nx + 2.1, ty - 0.15, -52.6), Vector3(1.0, 0.3, 1.4))
			RmAUtil.column(lm, "Granite", Vector3(nx + 2.1, ty, -52.4), 3.9, 0.22, "corinthian", 8)
		LandmarkDetail.cornice(lm, "Concrete", Vector3(-23.5, ty + 4.0, -53.3), Vector3(23.5, ty + 4.0, -53.3),
			Vector3.BACK, 0.45, false)
	for sx in [-1.0, 1.0]:
		RmAUtil.ruin_wall(lm, "Brick", Vector3(sx * 26.0, 0, -55.0), Vector3(sx * 26.0, 0, -33.0), 3.0, 0.0, 4.0, 12.0, 2.8, sx + 3.0)
		for i in 4:
			RmADetail.niche(lm, "Brick", "Shadow", Vector3(sx * 24.5, 1.0, -50.5 + 4.6 * float(i)), Vector3(-sx, 0, 0),
				1.8, 1.6, 0.45, 0.35)
	# Tepidarium side walls and the partition to the caldarium.
	for sx in [-1.0, 1.0]:
		RmAUtil.ruin_wall(lm, "Brick", Vector3(sx * 15.0, 0, -9.0), Vector3(sx * 15.0, 0, 13.0), 3.4, 0.0, 6.0, 16.0, 2.8, sx + 9.0)
	# Caldarium: a 35 m rotunda drum, tall on the open side, broken stumps elsewhere.
	var c := Vector3(0, 0, 33.0)
	RmAUtil.arc_arcade(lm, "Brick", "Shadow", c, 21.0, -2.3, 1.1, 14, 0.0, 12.0, 0.46, 0.55, 4.5, false, false)
	RmAUtil.arc_arcade(lm, "Brick", "Shadow", c + Vector3(0, 12.0, 0), 21.0, -2.3, 1.1, 14, 0.0, 12.0, 0.5, 0.35,
		4.5, false, false)
	for i in 14:
		var a0 := -2.3 + 3.4 * float(i) / 14.0
		var a1 := -2.3 + 3.4 * float(i + 1) / 14.0
		var o0 := Vector3(cos(a0), 0, sin(a0)) * 21.0
		var o1 := Vector3(cos(a1), 0, sin(a1)) * 21.0
		var om := Vector3(cos((a0 + a1) * 0.5), 0, sin((a0 + a1) * 0.5))
		LandmarkDetail.cornice(lm, "Concrete", c + o0 + Vector3(0, 11.6, 0), c + o1 + Vector3(0, 11.6, 0), om, 0.5, false)
	RmAUtil.arc_arcade(lm, "Brick", "Shadow", c, 21.0, 1.1, 3.98, 12, 0.0, 7.0, 0.46, 0.5, 4.5, false, true)
	for i in 14:
		var a := -2.3 + 3.4 * (float(i) + 0.5) / 14.0
		var f := absf(sin(float(i) * 4.7 + 1.0))
		lm.box("Brick", c + Vector3(cos(a) * 19.0, 24.0 + (0.5 + 5.0 * f) * 0.5, sin(a) * 19.0),
			Vector3(4.5, 0.5 + 5.0 * f, 6.0), Basis(Vector3.UP, -a))
	for i in 8:
		var a := TAU * float(i) / 8.0 + 0.4
		lm.box("Brick", c + Vector3(cos(a) * 17.4, 8.0, sin(a) * 17.4), Vector3(4.0, 16.0, 5.0), Basis(Vector3.UP, -a))
	# Palaestrae: outer walls, the apsidal ends and the portico stumps.
	for sx in [-1.0, 1.0]:
		RmAUtil.ruin_wall(lm, "Brick", Vector3(sx * 107.0, 0, -33.0), Vector3(sx * 107.0, 0, 11.0), 3.0, 0.0, 3.0, 8.0, 2.8, sx + 11.0)
		RmAUtil.ruin_wall(lm, "Brick", Vector3(sx * 29.0, 0, -33.0), Vector3(sx * 107.0, 0, -33.0), 3.0, 0.0, 2.0, 7.0, 2.8, sx + 12.0)
		RmAUtil.ruin_wall(lm, "Brick", Vector3(sx * 29.0, 0, 11.0), Vector3(sx * 107.0, 0, 11.0), 3.0, 0.0, 2.0, 7.0, 2.8, sx + 13.0)
		for i in 9:
			var a := -PI * 0.5 + PI * (float(i) + 0.5) / 9.0
			var f := absf(sin(float(i) * 6.1 + sx))
			var dx: float = sx * cos(a)
			var dz := sin(a)
			lm.box("Brick", Vector3(sx * 89.0 + dx * 18.0, (3.0 + 8.0 * f) * 0.5, -11.0 + dz * 18.0),
				Vector3(2.6, 3.0 + 8.0 * f, 4.4), Basis(Vector3.UP, atan2(-dz, dx)))
		for i in 13:
			var f2 := absf(sin(float(i) * 2.9 + sx))
			var f3 := absf(sin(float(i) * 1.7 + sx * 2.0))
			RmADetail.broken_column(lm, "Concrete", "Granite", Vector3(sx * (36.0 + 5.5 * float(i)), 0.3, -29.0), 0.55, 0.6 + 3.4 * f2)
			RmADetail.broken_column(lm, "Concrete", "Granite", Vector3(sx * (36.0 + 5.5 * float(i)), 0.3, 7.0), 0.55, 0.6 + 3.4 * f3)
		# Statue niches round the palaestra exedra.
		for i in 9:
			var a := -PI * 0.5 + PI * (float(i) + 0.5) / 9.0
			var out := Vector3(sx * cos(a), 0, sin(a))
			var nc := Vector3(sx * 89.0, 0, -11.0) + out * 16.6
			RmADetail.niche(lm, "Brick", "Shadow", nc + Vector3(0, 0.6, 0), -out, 1.6, 1.8, 0.4, 0.3)
	# Service rooms either side of the caldarium (changing rooms, laconica).
	for sx in [-1.0, 1.0]:
		for xo in [26.0, 48.0, 70.0]:
			RmAUtil.ruin_wall(lm, "Concrete", Vector3(sx * xo, 0, 11.0), Vector3(sx * xo, 0, 55.0), 2.6, 0.0, 3.0, 12.0, 2.6, xo + sx)
		for zo in [28.0, 42.0, 55.0]:
			RmAUtil.ruin_wall(lm, "Concrete", Vector3(sx * 26.0, 0, float(zo)), Vector3(sx * 70.0, 0, float(zo)), 2.4, 0.0, 2.0, 8.0, 2.4, zo)
	lm.commit(model)

# --- Theatre of Marcellus -----------------------------------------------

const T_R := 64.9
const T_BAYS := 41

## The curved facade toward +Z (the model origin is the centre of the
## semicircle): two tiers of travertine arcades, 41 bays to the full
## circle, the central 17 bays standing both tiers and four more either
## side only to the first. Below, Tuscan-Doric half-columns carry a
## Doric entablature with triglyphs and metopes; above, a plinth course,
## Ionic half-columns and the Ionic entablature; every arch has its
## impost and archivolt with a keystone. Behind them the cavea's radial
## brick walls; on top, Peruzzi's Palazzo Savelli-Orsini of stucco with
## two rows of framed windows, its crowning cornice and low tiled roof
## (30 m). To the north-west stand the three fluted Corinthian columns
## of the Temple of Apollo Sosianus on their podium. yaw_deg turns +Z
## onto bearing 44.
static func marcellus(model: Node3D) -> void:
	var lm := RmAMesh.new()
	lm.use("Travertine", LandmarkMaterials.pbr("limestone", "#B9A98B", 3.0))
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#93694D", 2.5))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#4A4136", 3.0))
	lm.use("Stucco", LandmarkMaterials.pbr("render", "#C9A98A", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("terracotta", "#8E5A42", 3.0))
	lm.use("Glass", LandmarkMaterials.glass("#2E3A40"))
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#D9D1BF", 3.0))
	var u := PI / float(T_BAYS)
	var lo := 12
	var hi := 29
	# Standing tiers: Doric (0-10.8 m) and Ionic (10.8-20.3 m) arcades.
	RmAUtil.arc_arcade(lm, "Travertine", "Shadow", Vector3.ZERO, T_R, u * lo, u * hi, hi - lo, 0.0, 10.8,
		0.62, 0.55, 5.0)
	RmAUtil.arc_arcade(lm, "Travertine", "Shadow", Vector3(0, 10.8, 0), T_R - 0.4, u * lo, u * hi, hi - lo, 0.0,
		9.5, 0.6, 0.55, 5.0, false, true)
	RmAUtil.arc_arcade(lm, "Travertine", "Shadow", Vector3.ZERO, T_R, u * (lo - 4), u * lo, 4, 0.0, 10.8,
		0.62, 0.55, 5.0, false, true)
	RmAUtil.arc_arcade(lm, "Travertine", "Shadow", Vector3.ZERO, T_R, u * hi, u * (hi + 4), 4, 0.0, 10.8,
		0.62, 0.55, 5.0, false, true)
	var cw := 2.0 * T_R * sin(u * 0.5)
	var cw2 := 2.0 * (T_R - 0.4) * sin(u * 0.5)
	for i in range(lo - 4, hi + 4):
		var am := u * (float(i) + 0.5)
		var upper := i >= lo and i < hi
		# Lower bay, in its own frame on the chord (local +Z outward).
		_bay_frame(lm, T_R * cos(u * 0.5), am)
		_bay(lm, cw, 0.0, 10.8, 0.62, 0.55, 0.43, "doric", i == hi + 3)
		if upper:
			_bay_frame(lm, (T_R - 0.4) * cos(u * 0.5), am, 10.8)
			lm.box("Travertine", Vector3(0, 0.4, 0.2), Vector3(cw2, 0.8, 0.4))
			_bay(lm, cw2, 0.0, 9.5, 0.6, 0.55, 0.36, "ionic", i == hi - 1, 0.8)
		lm.home()
	# Radial brick walls of the cavea, stepping down toward the stage.
	for i in range(lo - 4, hi + 5):
		var a := u * (float(i) + 0.5)
		var out := Vector3(cos(a), 0, sin(a))
		var top: float = 18.0 if i >= lo and i < hi else 9.0
		RmAUtil.seg_box(lm, "Brick", out * (T_R - 17.0), out * (T_R - 5.0), 1.4, 0.0, top * 0.55)
		RmAUtil.seg_box(lm, "Brick", out * (T_R - 12.0), out * (T_R - 5.0), 1.4, 0.0, top)
	# Palazzo Savelli-Orsini on the arcades.
	for i in range(lo + 1, hi - 1):
		var a0 := u * float(i)
		var a1 := u * float(i + 1)
		var p0 := Vector3(cos(a0), 0, sin(a0)) * (T_R - 3.5)
		var p1 := Vector3(cos(a1), 0, sin(a1)) * (T_R - 3.5)
		RmAUtil.seg_box(lm, "Stucco", p0, p1, 6.0, 20.3, 29.4)
		var q0 := Vector3(cos(a0), 0, sin(a0)) * (T_R - 0.2) + Vector3(0, 29.4, 0)
		var q1 := Vector3(cos(a1), 0, sin(a1)) * (T_R - 0.2) + Vector3(0, 29.4, 0)
		LandmarkDetail.cornice(lm, "Travertine", q0 - Vector3(cos(a0), 0, sin(a0)) * 0.3,
			q1 - Vector3(cos(a1), 0, sin(a1)) * 0.3, Vector3(cos((a0 + a1) * 0.5), 0, sin((a0 + a1) * 0.5)), 0.6, true)
		var r0 := Vector3(cos(a0), 0, sin(a0))
		var r1 := Vector3(cos(a1), 0, sin(a1))
		lm.quad("Roof", r0 * (T_R + 0.3) + Vector3(0, 30.0, 0), r1 * (T_R + 0.3) + Vector3(0, 30.0, 0),
			r1 * (T_R - 6.5) + Vector3(0, 31.4, 0), r0 * (T_R - 6.5) + Vector3(0, 31.4, 0))
		lm.quad("Roof", r0 * (T_R - 6.5) + Vector3(0, 31.4, 0), r1 * (T_R - 6.5) + Vector3(0, 31.4, 0),
			r1 * (T_R - 9.0) + Vector3(0, 29.4, 0), r0 * (T_R - 9.0) + Vector3(0, 29.4, 0))
		var am := (a0 + a1) * 0.5
		var out := Vector3(cos(am), 0, sin(am))
		var face := out * (T_R - 0.5) * cos(u * 0.5)
		for yy in [23.4, 27.1]:
			LandmarkDetail.window(lm, "Travertine", "Glass", face + Vector3(0, float(yy), 0), out, 1.1, 2.0,
				false, 0.18)
	lm.home()
	_apollo_sosianus(lm)
	lm.commit(model)

## Frame on the chord of a bay: origin on the chord midpoint at radius
## `rc`, local +Z outward (toward angle `am`), X along the chord.
static func _bay_frame(lm: RmAMesh, rc: float, am: float, y: float = 0.0) -> void:
	var out := Vector3(cos(am), 0, sin(am))
	lm.place(out.x * rc, out.z * rc, rad_to_deg(atan2(out.x, -out.z)), y)

## Orders and arch dressings on one bay `cw` wide between y0 and y1 (the
## arcade's own spring/opening fractions): the half-column on the
## bay's left pier (and right, for the last bay), impost bands, the
## archivolt and keystone, the entablature (triglyphs and metopes on
## the Doric tier) with its cornice.
static func _bay(lm: RmAMesh, cw: float, y0: float, y1: float, open_frac: float, spring_frac: float,
		r: float, order: String, last: bool, col_base: float = 0.0) -> void:
	var h := y1 - y0
	var ow := cw * open_frac
	var spring := y0 + h * spring_frac
	var ent := h * 0.2
	var col_h := y1 - ent - col_base
	var xs := [-cw * 0.5]
	if last:
		xs.append(cw * 0.5)
	for x in xs:
		LandmarkDetail.column(lm, "Travertine", Vector3(float(x), col_base, 0.18), r, col_h, order, 0)
	for s in [-1.0, 1.0]:
		lm.box("Travertine", Vector3(float(s) * (ow * 0.5 + 0.25), spring - 0.15, 0.06), Vector3(0.5, 0.3, 0.12))
	LandmarkDetail.arch(lm, "Travertine", Vector3(0, spring, 0), Vector3.BACK, ow, 0.42, 0.14)
	var ey := y1 - ent
	lm.box("Travertine", Vector3(0, ey + ent * 0.18, 0.3), Vector3(cw, ent * 0.36, 0.6), Basis(), 0.0)
	lm.box("Travertine", Vector3(0, ey + ent * 0.58, 0.25), Vector3(cw, ent * 0.44, 0.5), Basis(), 0.0)
	if order == "doric":
		for k in 3:
			var tx := -cw * 0.5 + cw * float(k) / 3.0
			for g in 3:
				lm.box("Travertine", Vector3(tx + (float(g) - 1.0) * 0.15, ey + ent * 0.58, 0.54),
					Vector3(0.1, ent * 0.42, 0.08), Basis(), 0.0)
			lm.disc("Travertine", Vector3(tx + cw / 6.0, ey + ent * 0.58, 0.51), Vector3.BACK, 0.22, 10)
	LandmarkDetail.cornice(lm, "Travertine", Vector3(-cw * 0.5, y1 - ent * 0.2, 0.5),
		Vector3(cw * 0.5, y1 - ent * 0.2, 0.5), Vector3.BACK, ent * 0.2, order == "ionic")

## Temple of Apollo Sosianus (rebuilt 34 BC): the podium and the three
## re-erected fluted Corinthian columns of the north-east corner with
## their entablature and frieze, north-west of the theatre.
static func _apollo_sosianus(lm: RmAMesh) -> void:
	lm.place(-70.0, 12.0, 120.0)
	lm.box("Brick", Vector3(0, 1.8, -4.0), Vector3(12.0, 3.6, 14.0))
	lm.box("Travertine", Vector3(0, 3.75, -4.0), Vector3(12.4, 0.3, 14.4))
	var pts := [Vector3(-4.0, 3.9, 2.0), Vector3(0.0, 3.9, 2.0), Vector3(-4.0, 3.9, -2.0)]
	for p in pts:
		LandmarkDetail.column(lm, "Marble", p, 0.7, 14.8, "corinthian", 24)
	RmAUtil.entablature(lm, "Marble", Vector3(-4.0, 18.7, 2.0), Vector3(0.0, 18.7, 2.0), 2.6, 1.9)
	RmAUtil.entablature(lm, "Marble", Vector3(-4.0, 18.7, 2.0), Vector3(-4.0, 18.7, -2.0), 2.6, 1.9)
	for k in 6:
		lm.box("Marble", Vector3(-3.4 + 0.65 * float(k), 19.95, 3.0), Vector3(0.3, 0.6, 0.08), Basis(), 0.0)
	lm.home()
