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
## +X: sand track, the low marble spina with its turning posts, stepped
## grass cavea all round, the brick arcade of the curved end and the
## Torre della Moletta. yaw_deg turns +X onto the course (bearing 129).
static func circus(model: Node3D) -> void:
	var lm := RmAMesh.new()
	lm.use("Sand", LandmarkMaterials.pbr("sand", "#B9A47C", 6.0))
	lm.use("Lawn", LandmarkMaterials.pbr("lawn", "#78814E", 5.0))
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#94694D", 2.5))
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#CDC3AC", 3.0))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#4B4237", 3.0))
	var poly := _u_outline(0.0, 0.0, 28)
	var poly2 := PackedVector2Array()
	for p in poly:
		poly2.append(Vector2(p.x, p.z))
	lm.poly_prism("Sand", poly2, -1.5, 0.12)
	# Spina and its two sets of three turning posts.
	lm.box("Marble", Vector3(0, 0.9, 0), Vector3(340.0, 1.8, 8.0))
	for sx in [-1.0, 1.0]:
		for k in 3:
			lm.lathe("Marble", Vector3(sx * 178.0, 1.8, -2.4 + 2.4 * float(k)),
				PackedVector2Array([Vector2(1.1, 0), Vector2(0.8, 2.0), Vector2(0.35, 4.0), Vector2(0, 5.0)]), 10)
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
	# Brick arcade of the curve and the Torre della Moletta.
	RmAUtil.arc_arcade(lm, "Brick", "Shadow", Vector3(C_CURVE, 0, 0), 77.0, -1.25, 1.25, 24, 0.0, 9.0,
		0.55, 0.5, 5.0, false, true)
	lm.box("Brick", Vector3(318.0, 10.0, -20.0), Vector3(8.0, 20.0, 8.0))
	lm.box("Marble", Vector3(318.0, 20.25, -20.0), Vector3(9.0, 0.5, 9.0))
	lm.box("Brick", Vector3(312.0, 3.5, -20.0), Vector3(8.0, 7.0, 14.0))
	for k in 4:
		var out := Vector3(sin(PI * 0.5 * float(k)), 0, cos(PI * 0.5 * float(k)))
		var right := Vector3.UP.cross(out)
		SEuUtil.opening(lm, "Shadow", Vector3(318.0, 12.0, -20.0) + out * 4.05, right, Vector3.UP, 1.1, 2.4)
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
## and its high rear wall at the north-east (-Z), the frigidarium with the
## standing piers of its three groin vaults, the tepidarium, the great
## round caldarium (35 m) at the south-west (+Z) with its tall broken drum,
## the two palaestrae with their apses and the ruined service rooms. A
## brick pier at 30 m is the highest remnant. yaw_deg turns +Z onto 218 deg.
static func baths(model: Node3D) -> void:
	var lm := RmAMesh.new()
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#8F6246", 2.5))
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#8E8472", 3.0))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#4B4237", 3.0))
	lm.use("Paving", LandmarkMaterials.pbr("pavement", "#A39981", 3.0))
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#8B8985", 2.5))
	lm.box("Paving", Vector3(0, -0.45, 0), Vector3(214.0, 1.0, 110.0))
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
		for z in [-26.0, -16.0]:
			RmAUtil.column(lm, "Granite", Vector3(sx * 14.0, 0, float(z)), 3.6, 1.2, "doric", 12)
	# Natatio: rear wall (the north-east facade) and side walls.
	RmAUtil.ruin_wall(lm, "Brick", Vector3(-26.0, 0, -55.0), Vector3(26.0, 0, -55.0), 3.4, 0.0, 9.0, 20.0, 2.6, 5.0)
	for sx in [-1.0, 1.0]:
		RmAUtil.ruin_wall(lm, "Brick", Vector3(sx * 26.0, 0, -55.0), Vector3(sx * 26.0, 0, -33.0), 3.0, 0.0, 4.0, 12.0, 2.8, sx + 3.0)
	# Tepidarium side walls and the partition to the caldarium.
	for sx in [-1.0, 1.0]:
		RmAUtil.ruin_wall(lm, "Brick", Vector3(sx * 15.0, 0, -9.0), Vector3(sx * 15.0, 0, 13.0), 3.4, 0.0, 6.0, 16.0, 2.8, sx + 9.0)
	# Caldarium: a 35 m rotunda drum, tall on the open side, broken stumps elsewhere.
	var c := Vector3(0, 0, 33.0)
	RmAUtil.arc_arcade(lm, "Brick", "Shadow", c, 21.0, -2.3, 1.1, 14, 0.0, 24.0, 0.46, 0.5, 4.5, false, false)
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
		for i in 7:
			var f2 := absf(sin(float(i) * 2.9 + sx))
			lm.frustum("Granite", Vector3(sx * (36.0 + 11.0 * float(i)), 0, -29.0), 0.7, 0.62, 0.6 + 2.6 * f2, 8)
			lm.frustum("Granite", Vector3(sx * (36.0 + 11.0 * float(i)), 0, 7.0), 0.7, 0.62, 0.6 + 2.6 * f2, 8)
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
## semicircle): two tiers of travertine arcades, Doric below and Ionic
## above, 41 bays to the full circle, the central 17 bays standing both
## tiers and four more either side only to the first; the cavea's radial
## brick walls behind them; on top, Peruzzi's Palazzo Savelli-Orsini of
## stucco with its cornice (30 m). yaw_deg turns +Z onto bearing 44.
static func marcellus(model: Node3D) -> void:
	var lm := RmAMesh.new()
	lm.use("Travertine", LandmarkMaterials.pbr("limestone", "#B9A98B", 3.0))
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#93694D", 2.5))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#4A4136", 3.0))
	lm.use("Stucco", LandmarkMaterials.pbr("render", "#C9A98A", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("terracotta", "#8E5A42", 3.0))
	var u := PI / float(T_BAYS)
	var lo := 12
	var hi := 29
	# Standing tiers: Doric (0-10.8 m) and Ionic (10.8-20.3 m) arcades.
	RmAUtil.arc_arcade(lm, "Travertine", "Shadow", Vector3.ZERO, T_R, u * lo, u * hi, hi - lo, 0.0, 10.8,
		0.62, 0.55, 5.0)
	RmAUtil.arc_arcade(lm, "Travertine", "Shadow", Vector3(0, 10.8, 0), T_R - 0.4, u * lo, u * hi, hi - lo, 0.0, 9.5,
		0.6, 0.55, 5.0, false, true)
	RmAUtil.arc_arcade(lm, "Travertine", "Shadow", Vector3.ZERO, T_R, u * (lo - 4), u * lo, 4, 0.0, 10.8,
		0.62, 0.55, 5.0, false, true)
	RmAUtil.arc_arcade(lm, "Travertine", "Shadow", Vector3.ZERO, T_R, u * hi, u * (hi + 4), 4, 0.0, 10.8,
		0.62, 0.55, 5.0, false, true)
	# Engaged half-columns on every pier and the tier cornices.
	for i in range(lo - 4, hi + 5):
		var a := u * float(i)
		var out := Vector3(cos(a), 0, sin(a))
		lm.frustum("Travertine", out * (T_R + 0.5), 0.72, 0.64, 9.2, 8)
		if i >= lo and i <= hi:
			lm.frustum("Travertine", Vector3(0, 10.8, 0) + out * (T_R - 0.1), 0.62, 0.55, 8.0, 8)
		if i < hi + 4:
			var b := u * float(i + 1)
			var p0 := Vector3(cos(a), 0, sin(a)) * (T_R + 0.4)
			var p1 := Vector3(cos(b), 0, sin(b)) * (T_R + 0.4)
			lm.beam("Travertine", p0 + Vector3(0, 10.2, 0), p1 + Vector3(0, 10.2, 0), 1.3, 1.2, Vector3.UP)
			if i >= lo and i < hi:
				lm.beam("Travertine", p0 + Vector3(0, 19.7, 0), p1 + Vector3(0, 19.7, 0), 1.3, 1.2, Vector3.UP)
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
		var q0 := Vector3(cos(a0), 0, sin(a0)) * (T_R - 0.2) + Vector3(0, 29.7, 0)
		var q1 := Vector3(cos(a1), 0, sin(a1)) * (T_R - 0.2) + Vector3(0, 29.7, 0)
		lm.beam("Travertine", q0, q1, 0.6, 1.6, Vector3.UP)
		var am := (a0 + a1) * 0.5
		var out := Vector3(cos(am), 0, sin(am))
		var right := Vector3.UP.cross(out)
		for yy in [22.0, 25.8]:
			SEuUtil.opening(lm, "Shadow", out * (T_R - 0.45) + Vector3(0, float(yy), 0), right, Vector3.UP, 1.5, 2.6)
	lm.commit(model)
