class_name LandmarkAngTerraces
extends RefCounted

## The two terraces on the Royal Square of Angkor Thom in true metres: the
## 350 m Terrace of the Elephants with its stairs, garudas, lions and elephant
## parade, and the Terrace of the Leper King, the 25 m square platform with
## its seven carved courses at the north end.

const P = preload("res://scripts/generation/landmarks/angkor/landmark_ang_parts.gd")

## Projecting stair bays of the Elephants terrace: centre along the wall, flank
## width either side of the stair, stair width and depth of the bay.
const BAYS := [[0.0, 12.0, 10.0, 7.0], [44.0, 6.0, 6.0, 7.0], [-44.0, 6.0, 6.0, 7.0],
	[163.0, 4.0, 5.0, 6.0], [-163.0, 4.0, 5.0, 6.0]]

## Terrace of the Elephants (4.2 m): the 350 m retaining wall of the Royal
## Square (late 12th c.), 3 m high with its moulded base and cornice, facing
## east. Five stair bays project from it, three in the middle and one at each
## end; the centre one is flanked by garudas and lions, the two beside it by
## three-headed elephants whose trunks form the pillars, and the two long
## runs of wall between them carry the parade of life-size elephants with
## their mahouts. The terrace platform stretches behind the wall.
static func elephants(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	P.kit(lm, "#85796A")
	var half := 175.0
	lm.box("Laterite", Vector3(-10.3, 1.425, 0), Vector3(19.4, 2.85, half * 2.0))
	lm.box("Stone", Vector3(-0.3, 1.425, 0), Vector3(0.6, 2.85, half * 2.0))
	lm.box("Trim", Vector3(-10.0, 2.925, 0), Vector3(20.0, 0.15, half * 2.0), Basis(), 0.0)
	# Moulded base, string course and cornice along the wall.
	lm.box("Trim", Vector3(0.1, 0.3, 0), Vector3(0.8, 0.6, half * 2.0), Basis(), 0.0)
	lm.box("Trim", Vector3(0.1, 1.5, 0), Vector3(0.2, 0.18, half * 2.0), Basis(), 0.0)
	lm.box("Trim", Vector3(0.2, 2.75, 0), Vector3(0.9, 0.35, half * 2.0), Basis(), 0.0)
	for k in 12:
		lm.box("Moss", Vector3(-3.0 - float(k % 4) * 4.0, 3.0, -160.0 + float(k) * 29.0), Vector3(2.4, 0.06, 5.0),
			Basis(), 0.0)
	var b := P.facing(1)
	for i in BAYS.size():
		var bay: Array = BAYS[i]
		var zc: float = bay[0]
		var fw: float = bay[1]
		var sw: float = bay[2]
		var depth: float = bay[3]
		# Flank blocks either side of the stair, the stair between them.
		for s in [-1.0, 1.0]:
			var zf: float = zc + s * (sw * 0.5 + fw * 0.5)
			P.block(lm, "Stone", "Trim", Vector3(depth * 0.5, 0, zf), depth * 0.5, fw * 0.5, 3.0)
		P.stair(lm, "Stone", Vector3(0.2, 0, zc), b, sw, 3.0, 0.3, 0.5)
		for s in [-1.0, 1.0]:
			var zf: float = zc + s * (sw * 0.5 + fw * 0.5)
			var front := Vector3(depth + 0.4, 0, zf)
			if i == 0:
				# Garudas side by side along the front, a lion at each stair side.
				for g in 4:
					P.garuda(lm, "Stone", front + Vector3(0, 0, (float(g) - 1.5) * 2.8), b, 3.2)
				P.lion(lm, "Stone", Vector3(depth - 0.2, 3.0, zc + s * (sw * 0.5 + 0.8)), b, 1.2)
			elif i < 3:
				_three_headed(lm, Vector3(depth + 0.3, 0, zf), b)
			else:
				P.lion(lm, "Stone", Vector3(depth - 1.2, 3.0, zc + s * (sw * 0.5 + 1.3)), b, 1.2)
	# The parade of elephants (and their mahouts) in relief, heads toward the
	# central bays, between the flanking and the end bays.
	for s in [-1.0, 1.0]:
		for k in 15:
			var z: float = s * (58.0 + 6.4 * float(k))
			_relief_elephant(lm, z, -s)
	lm.commit(model)

## Three-headed elephant of Indra at a stair corner: three heads side by side
## on a shared body, their trunks plucking lotus stems down the front face.
static func _three_headed(lm: LandmarkMesh, base: Vector3, b: Basis) -> void:
	lm.box("Stone", base + b * Vector3(0, 1.7, -0.9), Vector3(5.4, 3.0, 1.8), b, 0.0)
	for k in 3:
		var dx := (float(k) - 1.0) * 1.7
		var hb := base + b * Vector3(dx, 0, 0)
		lm.box("Stone", hb + b * Vector3(0, 2.7, 0.2), Vector3(1.3, 1.8, 1.1), b, 0.0)
		lm.beam("Stone", hb + b * Vector3(0, 2.1, 0.9), hb + b * Vector3(0, 0.3, 1.3), 0.55, 0.5, b * Vector3.RIGHT)
		for s in [-1.0, 1.0]:
			lm.box("Stone", hb + b * Vector3(s * 0.7, 2.8, 0.1), Vector3(0.12, 1.3, 0.9), b, 0.0)
	lm.box("Trim", base + b * Vector3(0, 3.5, -0.9), Vector3(5.6, 0.2, 2.0), b, 0.0)

## One elephant of the parade, carved 0.35 m proud of the wall at ground
## position z along it, walking toward `dir` (+1 = +Z) with its mahout.
static func _relief_elephant(lm: LandmarkMesh, z: float, dir: float) -> void:
	lm.box("Stone", Vector3(0.2, 1.55, z), Vector3(0.4, 1.0, 3.0), Basis(), 0.0)
	for s in [-1.0, 1.0]:
		lm.box("Stone", Vector3(0.2, 0.83, z + s * 1.0), Vector3(0.4, 0.45, 0.5), Basis(), 0.0)
	lm.box("Stone", Vector3(0.2, 1.75, z + dir * 1.8), Vector3(0.4, 1.0, 1.0), Basis(), 0.0)
	lm.beam("Stone", Vector3(0.3, 1.5, z + dir * 2.2), Vector3(0.3, 0.8, z + dir * 2.7), 0.3, 0.3,
		Vector3.RIGHT)
	lm.box("Stone", Vector3(0.2, 2.35, z + dir * 0.4), Vector3(0.3, 0.6, 0.5), Basis(), 0.0)

## Terrace of the Leper King (7.6 m): the 25 m square platform, 6 m high, at
## the north end of the Elephants terrace (late 12th c.): a plain core inside
## an outer wall of seven carved courses (rows of devatas, nagas and demons
## in niches) that stands a narrow passage clear of a second, older wall,
## whose reliefs lie hidden behind it. The statue of Dharmaraja (Yama), a
## replica, sits on top. Built facing +X (east), the stair on that side.
static func leper_king(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	P.kit(lm, "#5C564A")
	lm.use("Statue", LandmarkMaterials.pbr("stone", "#8D8573", 3.0))
	var h := 12.5
	var courses := 7
	var ch := 5.6 / float(courses)
	var wt := 1.6
	# Inner (older) wall block and its top; the passage floor sits 0.3 m up.
	lm.box("Laterite", Vector3(0, 2.95, 0), Vector3((h - wt - 1.3) * 2.0, 5.9, (h - wt - 1.3) * 2.0))
	lm.box("Laterite", Vector3(0, 0.15, 0), Vector3(h * 2.0 - 2.0, 0.3, h * 2.0 - 2.0))
	for c in courses:
		var proj := 0.18 if c % 2 == 0 else 0.0
		var hc := h - 0.18 + proj
		var yc := ch * (float(c) + 0.5)
		# Outer wall of this course: four slabs round the passage.
		for s in [-1.0, 1.0]:
			lm.box("Stone", Vector3(0, yc, s * (hc - wt * 0.5)), Vector3(hc * 2.0, ch, wt), Basis(), 0.0)
			lm.box("Stone", Vector3(s * (hc - wt * 0.5), yc, 0), Vector3(wt, ch, hc * 2.0 - wt * 2.0), Basis(), 0.0)
		if c % 2 == 0 and c > 0:
			# Row of niches with dark recesses and a figure in each.
			var n := 11
			for side in 4:
				var b := P.facing(side)
				for k in n:
					var x := (float(k) - float(n - 1) * 0.5) * 2.1
					lm.box("Dark", b * Vector3(x, yc, hc + 0.02), Vector3(0.9, ch * 0.7, 0.06), b, 0.0)
					lm.box("Statue", b * Vector3(x, yc - ch * 0.05, hc + 0.08), Vector3(0.36, ch * 0.5, 0.1), b, 0.0)
	# Cornice, top slab and the east stair bridging the passage.
	lm.box("Trim", Vector3(0, 5.8, 0), Vector3(h * 2.0 + 0.6, 0.4, h * 2.0 + 0.6), Basis(), 0.0)
	lm.box("Trim", Vector3(0, 5.95, 0), Vector3((h - wt) * 2.0, 0.1, (h - wt) * 2.0), Basis(), 0.0)
	P.stair(lm, "Stone", Vector3(h + 0.3, 0, 0), P.facing(1), 4.5, 6.0, 0.4, 0.4)
	for k in 8:
		var a := 2.1 * float(k)
		lm.box("Moss", Vector3(cos(a) * 9.0, 6.03, sin(a) * 9.0), Vector3(2.0, 0.05, 1.4), Basis(Vector3.UP, a), 0.0)
	# Dharmaraja: a seated figure on a plinth.
	lm.box("Trim", Vector3(0, 6.25, 0), Vector3(2.6, 0.5, 2.6))
	lm.box("Statue", Vector3(0, 6.675, 0.0), Vector3(1.5, 0.35, 1.3), Basis(), 0.0)
	lm.box("Statue", Vector3(0.0, 7.075, -0.1), Vector3(0.8, 0.45, 0.5), Basis(), 0.0)
	lm.box("Statue", Vector3(0.0, 7.45, -0.1), Vector3(0.4, 0.3, 0.4), Basis(), 0.0)
	lm.commit(model)
