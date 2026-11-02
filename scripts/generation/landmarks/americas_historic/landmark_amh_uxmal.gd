class_name LandmarkAmhUxmal
extends RefCounted

## The Pyramid of the Magician (Pyramid of the Soothsayer) at Uxmal in
## true metres: the oval pyramid, its two stairs, the Chenes Temple IV
## and the summit Temple V. Built with the west stair facing +Z and the
## long north-south axis along X; the registry yaw turns the west stair
## onto the solstice-sunset bearing.

const MAGICIAN_TOP_M := 35.0
## Ratio of the long (north-south, X) to the short (Z) base radius: the
## oval is 69 x 49 m.
const MAGICIAN_SX := 34.5 / 24.5
## Bodies along the short axis (Z): foot radius, top radius, height.
const MAGICIAN_BODIES := [[24.5, 22.6, 6.5], [21.2, 19.4, 6.5], [18.0, 16.1, 6.5], [14.7, 13.1, 5.5],
	[11.7, 10.6, 4.0]]

## Pyramid of the Magician: the 35 m elliptical pyramid (69 x 49 m,
## long axis north-south), five rounded bodies with moulded ledges; on
## the west (+Z) the steep narrow stair lined both sides with stacked
## Chaac masks up to Chenes Temple IV, whose whole front is a Chaac mask
## with its jaws for the doorway; on the east (-Z) the broader stair
## from the foot to the summit, cut near the top by the entrance to
## Temple II; and on the summit Temple V (the House of the Magician),
## three rooms under a frieze of stone latticework.
static func magician(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#C5B99D", 4.0))
	lm.use("Steps", LandmarkMaterials.pbr("limestone", "#D0C6AB", 3.0))
	lm.use("Stucco", LandmarkMaterials.pbr("render", "#D9CFB4", 3.0))
	lm.use("Door", LandmarkMaterials.glass("#1F2528"))
	var outer := PackedVector2Array()
	var y := 0.0
	for b in MAGICIAN_BODIES:
		var r0: float = b[0]
		var r1: float = b[1]
		var h: float = b[2]
		lm.frustum("Stone", Vector3(0, y, 0), r0, r1, h - 0.5, 64, 0.0, MAGICIAN_SX, 1.0)
		# Ledge moulding: a projecting band at the top of each body.
		lm.lathe("Stucco", Vector3(0, y + h - 0.5, 0),
			PackedVector2Array([Vector2(r1 + 0.05, 0.0), Vector2(r1 + 0.3, 0.15),
			Vector2(r1 + 0.3, 0.4), Vector2(r1, 0.5)]), 64, MAGICIAN_SX, 1.0)
		outer.append(Vector2(r0, y))
		outer.append(Vector2(r1, y + h))
		y += h
	var top_y := y
	# West stair to Temple IV's porch (y 24) with its rows of masks.
	LandmarkAmhParts.stair_hug(lm, "Steps", Vector3.ZERO, Basis(), 7.0, outer, 0.0, 24.0, 56, 8.0, 0.45,
		1.2, "Stone")
	for s in [-1.0, 1.0]:
		var my := 2.2
		while my < 22.0:
			var z := LandmarkAmhParts._outer_at(outer, my + 0.9) + 0.3
			chaac_mask(lm, "Stucco", Vector3(s * 6.0, my, z), Basis(), 2.6)
			my += 2.1
	_temple_iv(lm)
	_temple_i(lm, outer)
	# East stair: foot to the Temple II entrance, then on to the summit.
	var back := Basis(Vector3.UP, PI)
	LandmarkAmhParts.stair_hug(lm, "Steps", Vector3.ZERO, back, 11.0, outer, 0.0, 21.5, 48, 8.0, 0.45,
		1.4, "Stone")
	_temple_ii(lm, back)
	LandmarkAmhParts.stair_hug(lm, "Steps", Vector3.ZERO, back, 8.0, outer, 24.6, top_y, 11, 8.0, 0.45,
		1.2, "Stone")
	_temple_v(lm, top_y)
	lm.commit(model)

## A Puuc / Chenes Chaac (rain god) mask `w` wide centred at `c` on a
## face whose outward normal is local +Z of `r`: a backing panel, the
## brow, square eyes with pupils, the hooked trunk-nose, ear flares
## with plugs and the fanged mouth.
static func chaac_mask(lm: LandmarkMesh, key: String, c: Vector3, r: Basis, w: float) -> void:
	var P := func(x: float, y: float, z: float) -> Vector3:
		return c + r * Vector3(x * w, y * w, z * w)
	var S := func(x: float, y: float, z: float) -> Vector3:
		return Vector3(x * w, y * w, z * w)
	lm.box(key, P.call(0.0, 0.0, 0.05), S.call(1.0, 0.82, 0.1), r)
	lm.box(key, P.call(0.0, 0.33, 0.14), S.call(1.04, 0.14, 0.16), r)
	for sx in [-1.0, 1.0]:
		lm.box(key, P.call(sx * 0.22, 0.14, 0.14), S.call(0.24, 0.2, 0.1), r)
		lm.box(key, P.call(sx * 0.22, 0.14, 0.2), S.call(0.1, 0.1, 0.06), r, 0.0)
		lm.box(key, P.call(sx * 0.46, 0.02, 0.14), S.call(0.1, 0.42, 0.12), r)
		lm.box(key, P.call(sx * 0.46, 0.04, 0.22), S.call(0.07, 0.07, 0.06), r, 0.0)
		lm.box(key, P.call(sx * 0.16, -0.33, 0.16), S.call(0.06, 0.1, 0.06), r, 0.0)
	lm.box(key, P.call(0.0, 0.02, 0.18), S.call(0.13, 0.3, 0.16), r)
	lm.box(key, P.call(0.0, -0.13, 0.32), S.call(0.13, 0.08, 0.3), r)
	lm.box(key, P.call(0.0, -0.02, 0.46), S.call(0.1, 0.22, 0.08), r)
	lm.box(key, P.call(0.0, -0.27, 0.14), S.call(0.5, 0.08, 0.12), r)
	lm.box(key, P.call(0.0, -0.36, 0.12), S.call(0.42, 0.06, 0.1), r)

## Chenes Temple IV, jutting from the west face on its porch at y 24:
## the facade is one great Chaac mask whose jaws frame the doorway,
## with stacked trunk-noses over it, side panels of smaller masks and a
## frieze, under a moulded cornice.
static func _temple_iv(lm: LandmarkMesh) -> void:
	lm.box("Stone", Vector3(0, 24.5, 12.0), Vector3(10.4, 1.0, 5.4))
	var fz := 14.2
	lm.box("Stone", Vector3(0, 27.6, fz - 3.2), Vector3(9.4, 5.2, 6.4))
	lm.box("Stucco", Vector3(0, 25.2, fz + 0.05), Vector3(9.6, 0.4, 0.5))
	# Jaws round the door: upper and lower teeth rows.
	LandmarkAmhParts.opening(lm, "Door", Vector3(0, 26.6, fz + 0.05), Basis(), 2.2, 2.6, 0.3)
	for j in 6:
		var x := -1.25 + 0.5 * float(j)
		lm.box("Stucco", Vector3(x, 27.75, fz + 0.15), Vector3(0.28, 0.35, 0.3), Basis(), 0.0)
		lm.box("Stucco", Vector3(x, 25.55, fz + 0.15), Vector3(0.28, 0.3, 0.3), Basis(), 0.0)
	lm.box("Stucco", Vector3(0, 28.2, fz + 0.15), Vector3(3.6, 0.5, 0.4))
	# The great mask's eyes, brow, ear flares and stacked noses.
	for sx in [-1.0, 1.0]:
		lm.box("Stucco", Vector3(sx * 1.9, 28.9, fz + 0.15), Vector3(1.3, 1.0, 0.4))
		lm.box("Stucco", Vector3(sx * 1.9, 28.9, fz + 0.35), Vector3(0.55, 0.55, 0.2), Basis(), 0.0)
		lm.box("Stucco", Vector3(sx * 3.5, 27.3, fz + 0.15), Vector3(0.7, 3.4, 0.4))
		lm.box("Stucco", Vector3(sx * 3.5, 27.6, fz + 0.4), Vector3(0.4, 0.4, 0.2), Basis(), 0.0)
		chaac_mask(lm, "Stucco", Vector3(sx * 3.5, 29.4, fz), Basis(), 1.2)
	lm.box("Stucco", Vector3(0, 29.7, fz + 0.2), Vector3(5.2, 0.4, 0.5))
	for j in 3:
		lm.box("Stucco", Vector3(0, 28.85 + 0.35 * float(j), fz + 0.3 + 0.12 * float(j)),
			Vector3(0.7, 0.3, 0.5), Basis(), 0.0)
	for j in 7:
		lm.box("Stone", Vector3(-3.9 + 1.3 * float(j), 30.0, fz + 0.1), Vector3(0.9, 0.35, 0.3),
			Basis(), 0.0)
	lm.box("Stucco", Vector3(0, 30.45, fz - 3.2), Vector3(9.8, 0.5, 7.0))

## Temple I, the oldest, at the foot of the west face either side of
## the stair: a low front of doorways under a frieze of small Chaac
## masks between mouldings, built against the pyramid's first body.
static func _temple_i(lm: LandmarkMesh, outer: PackedVector2Array) -> void:
	var z := LandmarkAmhParts._outer_at(outer, 1.5) + 1.6
	for s in [-1.0, 1.0]:
		var x0: float = s * 6.2
		var x1: float = s * 20.0
		var xm := (x0 + x1) * 0.5
		var len_x := absf(x1 - x0)
		lm.box("Stone", Vector3(xm, 2.6, z - 2.0), Vector3(len_x, 5.2, 4.0))
		lm.box("Stucco", Vector3(xm, 0.2, z + 0.05), Vector3(len_x + 0.3, 0.4, 0.4))
		for i in 3:
			LandmarkAmhParts.opening(lm, "Door",
				Vector3(x0 + s * (2.8 + 4.4 * float(i)), 1.3, z + 0.02), Basis(), 1.4, 2.2, 0.2)
		lm.box("Stucco", Vector3(xm, 2.75, z + 0.1), Vector3(len_x + 0.4, 0.35, 0.5))
		for i in 6:
			chaac_mask(lm, "Stucco", Vector3(x0 + s * (1.2 + 2.28 * float(i)), 3.95, z), Basis(), 1.5)
		lm.box("Stucco", Vector3(xm, 5.0, z + 0.1), Vector3(len_x + 0.4, 0.4, 0.5))

## Temple II's entrance cut into the east stair at y 21.5: a vaulted
## doorway in a framed front, its threshold landing, lintel and frieze.
static func _temple_ii(lm: LandmarkMesh, back: Basis) -> void:
	var c := Vector3(0, 21.5, 0)
	lm.box("Stone", c + back * Vector3(0, 1.55, 12.5), Vector3(10.0, 3.1, 6.0), back)
	lm.box("Steps", c + back * Vector3(0, 0.15, 15.8), Vector3(11.0, 0.3, 1.2), back)
	LandmarkAmhParts.opening(lm, "Door", c + back * Vector3(0, 1.3, 15.5), back, 2.4, 2.3, 0.3)
	lm.box("Stucco", c + back * Vector3(0, 2.6, 15.55), Vector3(3.4, 0.35, 0.4), back)
	lm.box("Stucco", c + back * Vector3(0, 3.0, 15.6), Vector3(10.4, 0.3, 0.5), back)
	for j in 8:
		lm.box("Stone", c + back * Vector3(-4.2 + 1.2 * float(j), 2.0, 15.55), Vector3(0.5, 1.0, 0.3),
			back, 0.0)

## Temple V on the summit at `ty`: a long building of three rooms on the
## north-south axis with three doorways to the east, a basal moulding,
## the medial and upper mouldings and the frieze of lattice between,
## with Puuc Chaac masks turning each corner of the frieze.
static func _temple_v(lm: LandmarkMesh, ty: float) -> void:
	var c := Vector3(0, ty, 0)
	var hl := 10.5
	var hd := 2.6
	lm.box("Stone", c + Vector3(0, 0.15, 0), Vector3(2.0 * hl + 1.0, 0.3, 2.0 * hd + 1.0))
	lm.box("Stone", c + Vector3(0, 1.7, 0), Vector3(2.0 * hl, 2.8, 2.0 * hd))
	for i in 3:
		LandmarkAmhParts.opening(lm, "Door", c + Vector3(-7.0 + 7.0 * float(i), 1.4, -hd), Basis(), 1.5,
			2.2, 0.3)
	lm.box("Stucco", c + Vector3(0, 3.3, 0), Vector3(2.0 * hl + 0.6, 0.4, 2.0 * hd + 0.6))
	lm.box("Stone", c + Vector3(0, 4.5, 0), Vector3(2.0 * hl - 0.1, 2.0, 2.0 * hd - 0.1))
	lm.box("Stucco", c + Vector3(0, 5.75, 0), Vector3(2.0 * hl + 0.6, 0.5, 2.0 * hd + 0.6))
	for cx in [-1.0, 1.0]:
		for cz in [-1.0, 1.0]:
			chaac_mask(lm, "Stucco", c + Vector3(cx * (hl - 0.8), 4.5, cz * hd),
				Basis(Vector3.UP, 0.0 if cz > 0.0 else PI), 1.6)
			chaac_mask(lm, "Stucco", c + Vector3(cx * hl, 4.5, cz * (hd - 0.8)),
				Basis(Vector3.UP, cx * PI * 0.5), 1.6)
	# Latticework: diagonal bars crossing in a diamond net on every face.
	for q in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * float(q))
		var span := hl if q % 2 == 0 else hd
		var depth := hd if q % 2 == 0 else hl
		var o := c + Vector3(0, 3.5, 0)
		var cell := 0.55
		var n := int(2.0 * span / cell)
		for i in n:
			var x0 := -span + cell * float(i)
			if absf(x0 + cell * 0.5) > span - 1.7:
				continue
			for k in 3:
				var y0 := 0.1 + cell * float(k)
				var a := o + r * Vector3(x0, y0, depth + 0.02)
				var b := o + r * Vector3(x0 + cell, y0 + cell, depth + 0.02)
				var a2 := o + r * Vector3(x0 + cell, y0, depth + 0.02)
				var b2 := o + r * Vector3(x0, y0 + cell, depth + 0.02)
				lm.beam("Stucco", a, b, 0.11, 0.14, r * Vector3.FORWARD)
				lm.beam("Stucco", a2, b2, 0.11, 0.14, r * Vector3.FORWARD)
