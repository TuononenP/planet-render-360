class_name LandmarkEahSensoji
extends RefCounted

## The Senso-ji precinct at Asakusa in true metres (53 m to the pagoda
## finial): the Kaminarimon (11.7 m high, 11.4 m wide: the eight-post
## gabled gate with its 3.9 m red lantern and the wind and thunder gods
## in its front bays), the 250 m Nakamise shop street (54 shops east, 35
## west), the two-storey Hozomon (21.7 m, 21.1 m wide, its 3.75 m lantern
## and the 4.5 m straw sandals on the back), the main hall (34.5 x 32.7
## m, 29.4 m to the steep hip-and-gable ridge, porch and 4.5 m lantern)
## and the five-storey pagoda (48 m on its 5 m base) west of it. Halls
## face south (+Z); the model is turned a quarter circle so its 425 m
## axis runs along X (registry span_m), which is how the 110 m-wide strip
## of mapped buildings it replaces is cleared.

const SENSOJI_M := 53.0
## Natural frame: south +Z, origin on the registry point; the axis the
## gates stand on is x = SENSO_AXIS_X, Kaminarimon at z = SENSO_Z0 and the
## rest 312 m (Hozomon) and 402 m (main hall) north of it.
const SENSO_AXIS_X := 25.0
const SENSO_Z0 := 207.5

static func senso_ji(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#9C9488", 3.0))
	lm.use("Pave", LandmarkMaterials.pbr("pavement", "#B7ADA0", 4.0))
	lm.use("Lacquer", LandmarkMaterials.paint("#B3281D", 0.6, 0.0))
	lm.use("Tile", LandmarkMaterials.pbr("slate", "#4B5054", 1.5))
	lm.use("Plaster", LandmarkMaterials.pbr("render", "#EDE8DC", 3.0))
	lm.use("Shop", LandmarkMaterials.pbr("render", "#E3D6BD", 3.0))
	lm.use("Wood", LandmarkMaterials.paint("#5C3F2D", 0.8, 0.0))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.use("Shadow", LandmarkMaterials.paint("#26221F", 0.9, 0.0))
	lm.use("Lantern", LandmarkMaterials.lit("#C2261C", 0.35))
	var ax := SENSO_AXIS_X
	_street(lm, ax)
	_kaminarimon(lm, Vector2(ax, SENSO_Z0))
	_hozomon(lm, Vector2(ax, SENSO_Z0 - 312.8))
	_hondo(lm, Vector2(ax, SENSO_Z0 - 401.7))
	_pagoda(lm, Vector2(ax - 58.0, SENSO_Z0 - 385.0))
	var holder := Node3D.new()
	holder.name = "Axis"
	holder.rotation.y = -PI * 0.5
	model.add_child(holder)
	lm.commit(holder)

## Paving of the approach and the forecourt, and the Nakamise: two rows of
## roofed shops (54 east, 35 west) with red piers every 3.3 m, each shop
## an open front under a tiled pent eave with its name board.
static func _street(lm: LandmarkMesh, ax: float) -> void:
	var z_end := SENSO_Z0 - 313.0
	LandmarkEahParts.slab(lm, "Pave", Vector3(ax - 4.5, 0.0, z_end), Vector3(ax + 4.5, 0.4, SENSO_Z0 + 4.0))
	LandmarkEahParts.slab(lm, "Pave", Vector3(ax - 28.0, 0.0, SENSO_Z0 - 420.0), Vector3(ax + 28.0, 0.4, z_end))
	for s in [-1.0, 1.0]:
		var x0: float = ax + s * 4.5
		var x1: float = ax + s * 11.5
		var za := SENSO_Z0 - 304.0
		var zb := SENSO_Z0 - 12.0
		LandmarkEahParts.slab(lm, "Shop", Vector3(minf(x0, x1), 0.0, za), Vector3(maxf(x0, x1), 4.4, zb))
		lm.gable("Tile", Vector3((x0 + x1) * 0.5, 4.4, (za + zb) * 0.5), 7.0, zb - za, 2.0, Basis(), 0.5, "Shop")
		var n := int((zb - za) / 3.3)
		for k in n + 1:
			var z := za + 3.3 * k
			lm.box("Lacquer", Vector3(x0 - 0.15 * s, 2.1, z), Vector3(0.3, 4.2, 0.45))
			if k == n:
				continue
			var mz := z + 1.65
			# Open shop front, pent eave on brackets, name board above it.
			lm.box("Shadow", Vector3(x0 - 0.02 * s, 1.35, mz), Vector3(0.06, 2.5, 2.8), Basis(), 0.0)
			lm.box("Tile", Vector3(x0 - 0.7 * s, 2.95, mz), Vector3(1.5, 0.12, 3.2),
				Basis(Vector3.BACK, 0.25 * s), 0.0)
			lm.box("Wood", Vector3(x0 - 0.05 * s, 3.6, mz), Vector3(0.1, 0.6, 2.2), Basis(), 0.0)
			lm.box("Lantern", Vector3(x0 - 0.5 * s, 2.5, mz - 1.0), Vector3(0.35, 0.5, 0.35), Basis(), 0.0)

## Eight-post gate (hakkyakumon) with a gabled roof; the great lantern in
## the centre bay, Fujin and Raijin behind grilles in the front side bays.
static func _kaminarimon(lm: LandmarkMesh, c: Vector2) -> void:
	LandmarkEahParts.slab(lm, "Stone", Vector3(c.x - 6.2, 0.0, c.y - 3.6), Vector3(c.x + 6.2, 0.8, c.y + 3.6))
	LandmarkEahParts.colonnade(lm, "Lacquer", c, Vector2(10.2, 5.0), 0.8, 5.0, 3, 2, 0.4, 12)
	LandmarkEahDetail.ring_beams(lm, "Lacquer", Vector3(c.x, 0, c.y), Vector2(10.2, 5.0), 4.2, 0.45, 0.35)
	LandmarkEahParts.slab(lm, "Lacquer", Vector3(c.x - 5.9, 5.8, c.y - 2.8), Vector3(c.x + 5.9, 6.5, c.y + 2.8))
	LandmarkAeParts.brackets(lm, "Wood", Vector3(c.x, 5.8, c.y), 11.0, 5.6, 0.6, 1.1)
	for s in [-1.0, 1.0]:
		var bx: float = c.x + s * 3.4
		lm.box("Shadow", Vector3(bx, 3.0, c.y), Vector3(2.8, 4.4, 4.4))
		for side in [-1.0, 1.0]:
			var z: float = c.y + side * 2.25
			LandmarkKits.statue_figure(lm, "Wood" if s > 0.0 else "Lacquer", Vector3(bx, 0.8, z - side * 1.2), 2.2,
				s > 0.0)
			LandmarkEahDetail.lattice(lm, "Lacquer", "Shadow", Vector3(bx, 2.9, z), Vector3(0, 0, side), 3.0, 4.0, 9, 1)
	# Gabled (kirizuma) roof with its ridge to 11.7 m, rafters and boards.
	var rc := Vector3(c.x, 6.5, c.y)
	lm.gable("Tile", rc, 9.0, 13.0, 4.6, Basis(Vector3.UP, PI * 0.5), 0.6, "Plaster")
	for s in [-1.0, 1.0]:
		var gx: float = c.x + s * 6.5
		lm.beam("Wood", Vector3(gx, 6.4, c.y - 5.2), Vector3(gx, 11.1, c.y), 0.45, 0.35, Vector3.RIGHT)
		lm.beam("Wood", Vector3(gx, 6.4, c.y + 5.2), Vector3(gx, 11.1, c.y), 0.45, 0.35, Vector3.RIGHT)
		lm.box("Gold", Vector3(gx + s * 0.1, 10.6, c.y), Vector3(0.1, 0.6, 0.8), Basis(), 0.0)
	LandmarkEahDetail.ridge(lm, "Tile", c.x - 6.6, c.x + 6.6, 11.0, c.y, 0.8, 0.7)
	_lantern(lm, Vector3(c.x, 1.6, c.y + 0.4), 3.9, 1.65)

## Two-storey Hozomon (1964): five bays below with the Nio in the side
## bays, a hip skirt roof, the upper storey with a railed balcony, the
## hip-and-gable roof to 21.7 m; sandals on the north face.
static func _hozomon(lm: LandmarkMesh, c: Vector2) -> void:
	LandmarkEahParts.slab(lm, "Stone", Vector3(c.x - 11.0, 0.0, c.y - 5.0), Vector3(c.x + 11.0, 0.9, c.y + 5.0))
	LandmarkEahParts.colonnade(lm, "Lacquer", c, Vector2(19.2, 7.2), 0.9, 8.1, 6, 2, 0.5, 12)
	LandmarkEahDetail.ring_beams(lm, "Lacquer", Vector3(c.x, 0, c.y), Vector2(19.2, 7.2), 7.6, 0.5, 0.4)
	for s in [-1.0, 1.0]:
		var x0: float = c.x + s * 3.0
		var x1: float = c.x + s * 9.6
		LandmarkEahParts.slab(lm, "Lacquer", Vector3(minf(x0, x1), 0.9, c.y - 3.4), Vector3(maxf(x0, x1), 9.0, c.y + 3.4))
		lm.box("Shadow", Vector3(c.x + s * 6.3, 4.4, c.y + 3.46), Vector3(4.4, 5.0, 0.12))
		LandmarkEahDetail.lattice(lm, "Lacquer", "Shadow", Vector3(c.x + s * 6.3, 4.4, c.y + 3.45), Vector3(0, 0, 1),
			4.6, 5.2, 10, 2)
		LandmarkKits.statue_figure(lm, "Wood", Vector3(c.x + s * 6.3, 0.9, c.y + 1.8), 5.45, false)
		# The 4.5 m straw sandals hung on the north face.
		lm.box("Shop", Vector3(c.x + s * 6.3, 4.6, c.y - 3.55), Vector3(1.5, 4.5, 0.3), Basis(), 0.0)
	LandmarkEahParts.slab(lm, "Lacquer", Vector3(c.x - 3.0, 7.4, c.y - 3.4), Vector3(c.x + 3.0, 9.0, c.y + 3.4))
	LandmarkAeParts.brackets(lm, "Wood", Vector3(c.x, 8.1, c.y), 19.2, 7.2, 0.9, 1.4)
	var r1 := Vector3(c.x, 9.0, c.y)
	LandmarkAeParts.hip_roof(lm, "Tile", r1, Vector2(25.6, 11.8), Vector2(15.4, 5.6), 2.4, 0.8)
	LandmarkAeParts.eave_fascia(lm, "Wood", r1, Vector2(25.6, 11.8), 0.8, 0.3, Vector2(19.2, 7.2), 0.7)
	LandmarkAeParts.hip_ridges(lm, "Tile", r1, Vector2(25.6, 11.8), Vector2(15.4, 5.6), 2.4, 0.8, 0.3)
	# Upper storey 20.0 m wide with its balcony.
	LandmarkEahParts.slab(lm, "Wood", Vector3(c.x - 8.4, 11.2, c.y - 3.6), Vector3(c.x + 8.4, 11.5, c.y + 3.6))
	LandmarkEahDetail.railing_loop(lm, "Lacquer", Vector3(c.x, 11.5, c.y), Vector2(16.4, 7.0), 0.9, 1.2, 0.12)
	LandmarkEahParts.slab(lm, "Lacquer", Vector3(c.x - 7.2, 11.4, c.y - 2.6), Vector3(c.x + 7.2, 15.6, c.y + 2.6))
	for i in 5:
		LandmarkEahDetail.lattice(lm, "Lacquer", "Shadow", Vector3(c.x - 5.76 + 2.88 * i, 13.4, c.y + 2.6), Vector3(0, 0, 1),
			2.3, 3.0, 6, 3)
	LandmarkAeParts.brackets(lm, "Wood", Vector3(c.x, 15.6, c.y), 14.4, 5.2, 0.6, 1.2)
	var r2 := Vector3(c.x, 16.3, c.y)
	LandmarkEahParts.irimoya(lm, "Tile", "Plaster", r2, Vector2(24.0, 10.4), Vector2(15.0, 3.5), 2.6, 2.2, 0.7)
	LandmarkAeParts.eave_fascia(lm, "Wood", r2, Vector2(24.0, 10.4), 0.7, 0.3, Vector2(14.4, 5.2), 0.7)
	LandmarkAeParts.hip_ridges(lm, "Tile", r2, Vector2(24.0, 10.4), Vector2(15.0, 3.5), 2.6, 0.7, 0.3)
	LandmarkEahDetail.ridge(lm, "Tile", c.x - 7.5, c.x + 7.5, 21.0, c.y, 1.1, 0.7)
	_lantern(lm, Vector3(c.x, 3.4, c.y + 0.4), 3.75, 1.35)

## Main hall (1958): 34.5 x 32.7 m, 29.4 m to the ridge; seven bays of
## lattice doors on the front, bracket band, steep irimoya roof, the
## porch with its gable and lantern, and the bronze incense burner.
static func _hondo(lm: LandmarkMesh, c: Vector2) -> void:
	LandmarkEahParts.slab(lm, "Stone", Vector3(c.x - 18.0, 0.0, c.y - 16.0), Vector3(c.x + 18.0, 1.2, c.y + 16.0))
	LandmarkEahParts.stairs(lm, "Stone", c.x, c.y + 20.0, 0.0, 7.0, 4, 0.3, 0.9)
	LandmarkEahParts.colonnade(lm, "Lacquer", c, Vector2(32.0, 29.0), 1.2, 9.6, 7, 6, 0.5, 12)
	lm.box("Lacquer", Vector3(c.x, 6.0, c.y), Vector3(30.0, 9.6, 27.0))
	LandmarkEahDetail.bays(lm, "Lacquer", "Shadow", Vector3(c.x, 1.2, c.y), Vector2(30.0, 27.0), 7.6, 7, 6,
		func(face: int, i: int) -> int: return 1 if face == 0 and absi(i - 3) <= 2 else 2)
	LandmarkEahDetail.railing_loop(lm, "Lacquer", Vector3(c.x, 1.2, c.y), Vector2(34.4, 31.4), 0.9, 1.6, 0.14)
	LandmarkEahDetail.ring_beams(lm, "Lacquer", Vector3(c.x, 0, c.y), Vector2(32.0, 29.0), 9.6, 0.6, 0.45)
	LandmarkAeParts.brackets(lm, "Wood", Vector3(c.x, 10.0, c.y), 32.0, 29.0, 0.8, 1.6)
	LandmarkEahParts.slab(lm, "Wood", Vector3(c.x - 17.2, 10.8, c.y - 15.5), Vector3(c.x + 17.2, 11.9, c.y + 15.5))
	var rc := Vector3(c.x, 11.9, c.y)
	LandmarkEahParts.irimoya(lm, "Tile", "Plaster", rc, Vector2(43.0, 37.0), Vector2(24.0, 12.0), 8.0, 7.5, 1.0)
	LandmarkAeParts.eave_fascia(lm, "Wood", rc, Vector2(43.0, 37.0), 1.0, 0.45, Vector2(34.4, 31.0), 0.8)
	LandmarkAeParts.hip_ridges(lm, "Tile", rc, Vector2(43.0, 37.0), Vector2(24.0, 12.0), 8.0, 1.0, 0.5)
	for s in [-1.0, 1.0]:
		lm.box("Gold", Vector3(c.x + s * 12.05, 23.0, c.y), Vector3(0.12, 1.4, 1.4), Basis(), 0.0)
	LandmarkEahDetail.ridge(lm, "Tile", c.x - 12.5, c.x + 12.5, 27.3, c.y, 1.6, 1.1)
	for s in [-1.0, 1.0]:
		LandmarkEahParts.horn(lm, "Gold", Vector3(c.x + s * 12.0, 28.3, c.y), 1.1, -s, 0.4)
	# Front porch (kohai) under its own gable, with the great lantern.
	for s in [-1.0, 1.0]:
		LandmarkEahParts.column(lm, "Lacquer", Vector3(c.x + s * 6.5, 1.2, c.y + 20.0), 7.4, 0.45, 12)
		LandmarkEahParts.column(lm, "Lacquer", Vector3(c.x + s * 6.5, 1.2, c.y + 15.0), 7.4, 0.45, 12)
	LandmarkEahParts.slab(lm, "Wood", Vector3(c.x - 7.2, 8.6, c.y + 12.0), Vector3(c.x + 7.2, 9.1, c.y + 20.8))
	lm.gable("Tile", Vector3(c.x, 9.1, c.y + 16.5), 15.0, 9.0, 3.2, Basis(), 0.6, "Plaster")
	LandmarkEahDetail.karahafu(lm, "Tile", "Plaster", "Wood", Vector3(c.x, 8.9, c.y + 21.2), Vector3(0, 0, 1),
		9.0, 1.4, 3.0, "Gold")
	_lantern(lm, Vector3(c.x, 3.4, c.y + 19.2), 4.5, 1.75)
	# Bronze incense burner (jokoro) in the forecourt under its roof.
	var j := Vector3(c.x, 0.4, c.y + 34.0)
	lm.lathe("Wood", j, PackedVector2Array([Vector2(1.6, 0), Vector2(1.7, 0.6), Vector2(1.9, 1.2),
		Vector2(1.6, 1.35)]), 16)
	for s in [-1.0, 1.0]:
		for t in [-1.0, 1.0]:
			lm.box("Wood", j + Vector3(s * 1.2, 2.1, t * 1.2), Vector3(0.18, 1.5, 0.18), Basis(), 0.0)
	lm.lathe("Wood", j + Vector3(0, 2.8, 0), PackedVector2Array([Vector2(2.0, 0), Vector2(1.2, 0.5),
		Vector2(0.3, 1.0), Vector2(0.0, 1.4)]), 4, 1.0, 1.0, PI * 0.25, false)

## Red paper lantern of height h, radius r at the belly, hung from base:
## ribbed body, black lacquered rims top and bottom.
static func _lantern(lm: LandmarkMesh, base: Vector3, h: float, r: float) -> void:
	lm.lathe("Lantern", base, PackedVector2Array([Vector2(r * 0.55, 0), Vector2(r * 0.9, h * 0.12),
		Vector2(r, h * 0.3), Vector2(r * 1.02, h * 0.5), Vector2(r, h * 0.7), Vector2(r * 0.9, h * 0.88),
		Vector2(r * 0.55, h)]), 20)
	lm.frustum("Shadow", base + Vector3(0, -0.15, 0), r * 0.6, r * 0.6, 0.3, 16)
	lm.frustum("Shadow", base + Vector3(0, h - 0.15, 0), r * 0.6, r * 0.6, 0.3, 16)
	lm.box("Shadow", base + Vector3(0, -0.45, 0), Vector3(r * 0.3, 0.3, r * 0.3), Basis(), 0.0)

const PAGODA_W := [7.6, 6.9, 6.2, 5.6, 5.0]
const PAGODA_EAVE := [15.0, 13.6, 12.2, 10.9, 9.7]
const PAGODA_H := [6.0, 5.4, 4.9, 4.6, 4.2]
const PAGODA_RISE := [3.0, 2.8, 2.6, 2.4, 2.4]

## The five-storey pagoda (1973): 5 m platform, five red three-bay
## storeys (lattice door in the middle bay, white panels either side)
## on bracket sets under grey tile hip roofs with balconies, gilt sorin
## spire with nine rings to 53 m.
static func _pagoda(lm: LandmarkMesh, c: Vector2) -> void:
	LandmarkEahParts.slab(lm, "Stone", Vector3(c.x - 10.0, 0.0, c.y - 10.0), Vector3(c.x + 10.0, 5.0, c.y + 10.0))
	LandmarkEahParts.slab(lm, "Stone", Vector3(c.x - 10.3, 4.7, c.y - 10.3), Vector3(c.x + 10.3, 5.1, c.y + 10.3))
	LandmarkEahParts.stairs(lm, "Stone", c.x, c.y + 14.5, 0.0, 5.0, 10, 0.5, 0.45)
	LandmarkEahDetail.railing_loop(lm, "Lacquer", Vector3(c.x, 5.1, c.y), Vector2(19.4, 19.4), 0.9, 1.6, 0.14)
	var y := 5.0
	for i in 5:
		var w: float = PAGODA_W[i]
		var h: float = PAGODA_H[i]
		var cc := Vector3(c.x, y, c.y)
		lm.box("Lacquer", cc + Vector3(0, h * 0.5, 0), Vector3(w, h, w))
		for n in [Vector3(0, 0, 1), Vector3(0, 0, -1), Vector3(1, 0, 0), Vector3(-1, 0, 0)]:
			var nv: Vector3 = n
			var along := Vector3(absf(nv.z), 0, absf(nv.x))
			LandmarkEahDetail.lattice(lm, "Lacquer", "Shadow", cc + nv * (w * 0.5) + Vector3(0, h * 0.42, 0), nv,
				w * 0.3, h * 0.62, 4, 3)
			for s in [-1.0, 1.0]:
				lm.box("Plaster", cc + nv * (w * 0.5 + 0.02) + along * s * w * 0.31 + Vector3(0, h * 0.45, 0),
					Vector3(w * 0.22 * along.x + 0.06 * absf(nv.x), h * 0.55, w * 0.22 * along.z + 0.06 * absf(nv.z)), Basis(), 0.0)
		if i > 0:
			LandmarkEahDetail.railing_loop(lm, "Lacquer", cc, Vector2(w + 1.6, w + 1.6), 0.8, 1.1, 0.1)
		y += h
		LandmarkAeParts.brackets(lm, "Wood", Vector3(c.x, y - 0.9, c.y), w, w, 0.9, 1.0)
		var nxt: float = PAGODA_W[i + 1] if i < 4 else 1.0
		var e := Vector2(PAGODA_EAVE[i], PAGODA_EAVE[i])
		var t := Vector2(nxt + 0.8, nxt + 0.8)
		var rc := Vector3(c.x, y, c.y)
		LandmarkAeParts.hip_roof(lm, "Tile", rc, e, t, PAGODA_RISE[i], 0.9)
		LandmarkAeParts.eave_fascia(lm, "Wood", rc, e, 0.9, 0.3, Vector2(w, w), 0.6)
		LandmarkAeParts.hip_ridges(lm, "Tile", rc, e, t, PAGODA_RISE[i], 0.9, 0.3)
		y += PAGODA_RISE[i]
	# Sorin: pedestal, bowl, nine rings on the mast, flame, jewel.
	lm.box("Gold", Vector3(c.x, y + 0.25, c.y), Vector3(1.8, 0.5, 1.8))
	lm.lathe("Gold", Vector3(c.x, y + 0.5, c.y), PackedVector2Array([Vector2(1.2, 0), Vector2(1.4, 0.35),
		Vector2(0.9, 0.9), Vector2(0.3, 1.2)]), 12)
	lm.frustum("Gold", Vector3(c.x, y + 1.7, c.y), 0.18, 0.12, SENSOJI_M - y - 2.2, 8)
	for k in 9:
		lm.frustum("Gold", Vector3(c.x, y + 2.2 + 0.58 * k, c.y), 1.15 - 0.07 * k, 1.15 - 0.07 * k, 0.12, 16)
	lm.lathe("Gold", Vector3(c.x, y + 7.0, c.y), PackedVector2Array([Vector2(0.55, 0), Vector2(0.6, 0.5),
		Vector2(0.3, 1.1), Vector2(0.05, 1.6)]), 10)
	LandmarkAeParts.ball(lm, "Gold", Vector3(c.x, SENSOJI_M - 0.4, c.y), 0.4, 10, 6)
