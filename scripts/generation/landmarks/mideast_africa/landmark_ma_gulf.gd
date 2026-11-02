class_name LandmarkMaGulf
extends RefCounted

## Two Gulf skyscrapers in true metres: Burj Al Arab (Dubai) and the
## Makkah Royal Clock Tower (Abraj Al-Bait). Kingdom Centre and the
## Dubai Frame are LandmarkMaOpenTowers.

# --- Burj Al Arab ---

## Island top above the sea.
const ARAB_I := 6.0
## Height of the inhabited sail (the mast rises above it to 321 m).
const ARAB_H := 206.0
const ARAB_LEVELS := 24
## The V's apex (the spine) on the land side.
const ARAB_SPINE_Z := 14.0

## Half-span of the V's wing tips, depth from the spine to the tip line,
## the sail's bow beyond it and the wing thickness at height fraction t.
static func _arab_shape(t: float) -> Vector4:
	var x := 4.0 + 24.0 * (1.0 - pow(t, 1.6))
	var d := 8.0 + 44.0 * (1.0 - pow(t, 1.7))
	var bow := 16.0 * pow(1.0 - t, 1.2)
	var th := 6.0 + 9.0 * (1.0 - t)
	return Vector4(x, d, bow, th)

## Corners of the wing on side s at height fraction t: spine and tip on
## the atrium (inner) face, then on the outer face.
static func _arab_wing(t: float, s: float) -> Array[Vector3]:
	var sh := _arab_shape(t)
	var y := ARAB_I + ARAB_H * t
	var sp := Vector3(0, y, ARAB_SPINE_Z)
	var tip := Vector3(s * sh.x, y, ARAB_SPINE_Z - sh.y)
	var along := (tip - sp).normalized()
	var out := Vector3(-along.z, 0, along.x) * s
	if out.x * s < 0.0:
		out = -out
	return [sp, tip, sp + out * sh.w, tip + out * sh.w]

## 321 m sail-shaped hotel (1999) on its island 280 m offshore: two
## wings in a V round the 180 m atrium, the white fabric sail bowed
## across the open (sea) side, the giant white steel X-trusses of the
## exoskeleton on both outer faces, floor bands, the concrete spine, the
## Al Muntaha restaurant cantilevered 27 m at 200 m and the helipad at
## 210 m on the other side, and the tapering lattice mast to 321 m. The
## island has its rock revetment, entrance podium and the curving bridge
## stub to the shore.
static func burj_al_arab(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Sail", LandmarkMaterials.pbr("render", "#F6F4EE", 6.0))
	lm.use("Glass", LandmarkMaterials.glass("#3F5766"))
	lm.use("Mast", LandmarkMaterials.paint("#B9C1C7", 0.4, 0.6))
	lm.use("Island", LandmarkMaterials.pbr("concrete", "#BDB4A6", 4.0))
	# Island, its revetment of rock and the podium.
	lm.frustum("Island", Vector3(0, 0, 2), 64.0, 60.0, ARAB_I, 40)
	for i in 64:
		var a := TAU * float(i) / 64.0
		var r := 64.5 + 1.5 * sin(float(i) * 2.7)
		lm.box("Island", Vector3(cos(a) * r, 1.2, 2.0 + sin(a) * r), Vector3(3.2, 2.4, 2.6),
			Basis(Vector3.UP, a + sin(float(i)) * 0.4))
	lm.box("Island", Vector3(0, ARAB_I + 3.0, 22), Vector3(44, 6, 22))
	lm.frustum("Glass", Vector3(0, ARAB_I, -2), 22.0, 22.0, 5.0, 24)
	_arab_bridge(lm)
	# Wings: atrium face, outer face, end edges, as lofts over levels.
	for s in [-1.0, 1.0]:
		var inner: Array = []
		var outer: Array = []
		var tipf: Array = []
		for k in ARAB_LEVELS + 1:
			var c := _arab_wing(float(k) / ARAB_LEVELS, s)
			inner.append(PackedVector3Array([c[0], c[0].lerp(c[1], 0.5), c[1]]))
			outer.append(PackedVector3Array([c[2], c[2].lerp(c[3], 0.5), c[3]]))
			tipf.append(PackedVector3Array([c[1], c[3]]))
		lm.grid("Glass", outer, Vector3(-s * 1000.0, 100, 0), true)
		lm.grid("Glass", inner, Vector3(s * 1000.0, 100, 500), true)
		lm.grid("Sail", tipf, Vector3(0, 100, 1000), true)
		_arab_trusses(lm, s)
		# Floor bands across the outer face every second storey.
		for k in 30:
			var t := (float(k) + 0.5) / 30.0
			var c := _arab_wing(t, s)
			var o := (c[2] - c[0]).normalized() * 0.4
			lm.beam("Sail", c[2] + o, c[3] + o, 0.6, 0.5)
	# Sail: the fabric bowed between the wing tips.
	var rows: Array = []
	for k in ARAB_LEVELS + 1:
		var t := float(k) / ARAB_LEVELS
		var sh := _arab_shape(t)
		var y := ARAB_I + ARAB_H * t
		var row := PackedVector3Array()
		for i in 13:
			var u := -1.0 + float(i) / 6.0
			row.append(Vector3(u * sh.x, y, ARAB_SPINE_Z - sh.y - sh.z * (1.0 - u * u) - 0.5))
		rows.append(row)
	lm.grid("Sail", rows, Vector3(0, 0, -1))
	# Sail ribs: the fabric's vertical seams.
	for i in 6:
		var u := -1.0 + (float(i) + 0.5) / 3.0
		for k in ARAB_LEVELS:
			var sh0 := _arab_shape(float(k) / ARAB_LEVELS)
			var sh1 := _arab_shape(float(k + 1) / ARAB_LEVELS)
			var y0 := ARAB_I + ARAB_H * float(k) / ARAB_LEVELS
			var y1 := ARAB_I + ARAB_H * float(k + 1) / ARAB_LEVELS
			var a := Vector3(u * sh0.x, y0, ARAB_SPINE_Z - sh0.y - sh0.z * (1.0 - u * u) - 0.8)
			var b := Vector3(u * sh1.x, y1, ARAB_SPINE_Z - sh1.y - sh1.z * (1.0 - u * u) - 0.8)
			lm.beam("Sail", a, b, 0.5, 0.4)
	# Concrete spine (the V's apex) and the crown over the top floors.
	LandmarkMaParts.needle(lm, "Sail", Vector3(0, ARAB_I, ARAB_SPINE_Z + 2.0), PackedVector2Array([
		Vector2(0, 8.0), Vector2(100, 7.0), Vector2(ARAB_H, 5.5)]), 16)
	var top := ARAB_I + ARAB_H
	var ct := _arab_wing(1.0, 1.0)
	lm.box("Sail", Vector3(0, top + 1.0, (ct[0].z + ct[1].z) * 0.5), Vector3(ct[1].x * 2.0 + 12.0, 2.0,
		absf(ct[0].z - ct[1].z) + 10.0))
	_arab_restaurant(lm, Vector3(-4, ARAB_I + 194.0, 4))
	_arab_helipad(lm, Vector3(4, ARAB_I + 204.0, 4))
	_arab_mast(lm, Vector3(0, top + 2.0, ARAB_SPINE_Z - 4.0))
	lm.commit(model)

## White exoskeleton on the outer face of wing s: stacked giant X-truss
## tubes from the spine edge to the tip edge, with ties at each node.
static func _arab_trusses(lm: LandmarkMesh, s: float) -> void:
	var nodes := [0.0, 0.22, 0.45, 0.68, 0.9]
	for i in nodes.size() - 1:
		var a := _arab_wing(nodes[i], s)
		var b := _arab_wing(nodes[i + 1], s)
		var oa := (a[2] - a[0]).normalized() * 3.0
		var ob := (b[2] - b[0]).normalized() * 3.0
		lm.beam("Mast", a[2] + oa, b[3] + ob, 2.2, 2.2)
		lm.beam("Mast", a[3] + oa, b[2] + ob, 2.2, 2.2)
		lm.beam("Mast", a[2] + oa, b[2] + ob, 2.6, 2.6)
		lm.beam("Mast", a[3] + oa, b[3] + ob, 2.6, 2.6)
		lm.beam("Mast", b[2] + ob, b[3] + ob, 1.6, 1.6)
		# Struts back to the face at the nodes.
		lm.beam("Mast", b[2], b[2] + ob, 1.2, 1.2)
		lm.beam("Mast", b[3], b[3] + ob, 1.2, 1.2)

## Al Muntaha: the glazed restaurant pod cantilevered 27 m off the
## crown on the west side, on its raking struts.
static func _arab_restaurant(lm: LandmarkMesh, at: Vector3) -> void:
	var c := at + Vector3(-22, 0, 0)
	lm.lathe("Sail", c - Vector3(0, 0, 0), PackedVector2Array([Vector2(0.5, 0), Vector2(5.5, 1.0),
		Vector2(6.0, 2.0)]), 16, 3.2, 1.0)
	lm.frustum("Glass", c + Vector3(0, 2.0, 0), 6.0, 6.0, 4.0, 16, 0.0, 3.2, 1.0)
	lm.lathe("Sail", c + Vector3(0, 6.0, 0), PackedVector2Array([Vector2(6.2, 0), Vector2(5.0, 1.0),
		Vector2(0.5, 1.6)]), 16, 3.2, 1.0)
	for z in [-3.0, 3.0]:
		lm.beam("Mast", at + Vector3(0, -14, z), c + Vector3(-8, 0.5, z), 1.0, 1.0)

## Helipad: 24 m disc on a cantilevered truss arm, its rim net and
## landing circle.
static func _arab_helipad(lm: LandmarkMesh, at: Vector3) -> void:
	var c := at + Vector3(22, 0, 0)
	lm.frustum("Island", c, 12.0, 12.4, 1.0, 32)
	lm.frustum("Mast", c + Vector3(0, -0.6, 0), 12.6, 12.8, 0.6, 32)
	lm.frustum("Sail", c + Vector3(0, 1.0, 0), 6.5, 6.5, 0.04, 32)
	lm.frustum("Island", c + Vector3(0, 1.0, 0), 6.0, 6.0, 0.06, 32)
	for z in [-3.0, 3.0]:
		lm.beam("Mast", at + Vector3(0, 0.3, z), c + Vector3(-6, 0.3, z), 1.4, 1.4)
		lm.beam("Mast", at + Vector3(0, -16, z), c + Vector3(-5, -0.2, z), 1.0, 1.0)

## Tapering three-legged lattice mast from the crown to 321 m.
static func _arab_mast(lm: LandmarkMesh, base: Vector3) -> void:
	var h := 321.0 - base.y
	var legs: Array[Vector3] = [Vector3(0, 0, 9), Vector3(-7, 0, -4), Vector3(7, 0, -4)]
	var bays := 10
	for k in bays:
		var t0 := float(k) / bays
		var t1 := float(k + 1) / bays
		var s0 := pow(1.0 - t0, 1.3)
		var s1 := pow(1.0 - t1, 1.3) * 0.98 + 0.02
		for i in 3:
			var a0: Vector3 = base + legs[i] * s0 + Vector3(0, h * 0.94 * t0, 0)
			var a1: Vector3 = base + legs[i] * s1 + Vector3(0, h * 0.94 * t1, 0)
			var b0: Vector3 = base + legs[(i + 1) % 3] * s0 + Vector3(0, h * 0.94 * t0, 0)
			var b1: Vector3 = base + legs[(i + 1) % 3] * s1 + Vector3(0, h * 0.94 * t1, 0)
			lm.beam("Mast", a0, a1, 1.4 * s0 + 0.3, 1.4 * s0 + 0.3)
			lm.beam("Mast", a0, b1, 0.6 * s0 + 0.15, 0.6 * s0 + 0.15)
			lm.beam("Mast", b0, b1, 0.5 * s1 + 0.15, 0.5 * s1 + 0.15)
	lm.frustum("Mast", base + Vector3(0, h * 0.94, 0), 0.35, 0.05, h * 0.06, 6)

## Curving causeway bridge from the island toward the shore (+Z).
static func _arab_bridge(lm: LandmarkMesh) -> void:
	var prev := Vector3(0, ARAB_I - 0.5, 60)
	for i in 10:
		var t := float(i + 1) / 10.0
		var p := Vector3(-30.0 * t * t, ARAB_I - 0.5 - 1.5 * t, 60.0 + 80.0 * t)
		lm.beam("Island", prev, p, 0.9, 12.0, Vector3.UP)
		lm.frustum("Island", p - Vector3(0, p.y, 0), 1.2, 1.2, p.y - 1.0, 8)
		for s in [-1.0, 1.0]:
			var side: Vector3 = (p - prev).cross(Vector3.UP).normalized() * 5.6 * s
			lm.beam("Mast", prev + side + Vector3(0, 0.9, 0), p + side + Vector3(0, 0.9, 0), 0.2, 1.0, Vector3.UP)
		prev = p

# --- Abraj Al-Bait (Makkah Royal Clock Tower) ---

## 601 m clock tower (2012) on the mall podium among six hotel towers:
## a stone shaft with ribbed corners and pointed-arch bays, the 43 m
## clock faces on all four sides with gold rims, hour marks and hands,
## gold corner pillars and domes, the gilded inscription band, the
## stepped gold crown with the observatory to the top floor at 494 m,
## and the 93 m gold spire bearing the 21 m crescent.
static func abraj_al_bait(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#D9CDB4", 8.0))
	lm.use("Glass", LandmarkMaterials.glass("#3A4A52"))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.use("Clock", LandmarkMaterials.lit("#F4F0E6", 0.5))
	lm.use("Podium", LandmarkMaterials.pbr("concrete", "#C9C0AE", 6.0))
	lm.box("Podium", Vector3(0, 15, 0), Vector3(300, 30, 170))
	LandmarkMaParts.arched_bays(lm, "Podium", "Glass", Vector3(-150, 0, 85), Vector3.RIGHT, Vector3.BACK,
		300.0, 26.0, 24, 7.0, 13.0, 5.0, 0.8, "Stone", 4)
	for t in [[Vector2(-58, -30), 279.0], [Vector2(58, -30), 279.0], [Vector2(-115, -30), 232.0],
			[Vector2(115, -30), 232.0], [Vector2(-115, 45), 220.0], [Vector2(115, 45), 220.0]]:
		var p: Vector2 = t[0]
		_hotel_tower(lm, Vector3(p.x, 30, p.y), float(t[1]))
	_clock_tower(lm)
	lm.commit(model)

## A hotel tower `h` m tall from `base`: a chamfered stone shaft with
## glazed bays between piers, two setbacks, an arcaded top storey and a
## gold-domed cupola with its finial.
static func _hotel_tower(lm: LandmarkMesh, base: Vector3, h: float) -> void:
	var body := h - 30.0 - 40.0
	lm.frustum("Stone", base, 26.0, 25.0, body, 8, PI / 8.0)
	for i in 8:
		var a := PI / 8.0 + TAU * (float(i) + 0.5) / 8.0
		var d := Vector3(cos(a), 0, sin(a))
		lm.box("Glass", base + d * 24.0 + Vector3(0, body * 0.5, 0), Vector3(1.0, body - 6.0, 13.0),
			Basis.looking_at(d) * Basis(Vector3.UP, PI * 0.5), 0.0)
		for k in [-1.0, 1.0]:
			var side := d.cross(Vector3.UP)
			lm.box("Stone", base + d * 24.0 + side * k * 4.5 + Vector3(0, body * 0.5, 0), Vector3(1.4, body, 1.4),
				Basis(), 0.0)
	var b2 := base + Vector3(0, body, 0)
	lm.frustum("Stone", b2, 27.0, 27.0, 1.6, 8, PI / 8.0)
	lm.frustum("Stone", b2 + Vector3(0, 1.6, 0), 21.0, 20.0, 20.0, 8, PI / 8.0)
	LandmarkMaParts.arched_ring(lm, "Stone", "Glass", b2 + Vector3(0, 3.0, 0), 21.3, 8, 15.0, 4.0, 7.0, 3.0,
		0.5, PI / 8.0)
	var b3 := b2 + Vector3(0, 21.6, 0)
	lm.frustum("Stone", b3, 21.6, 21.6, 1.2, 8, PI / 8.0)
	lm.frustum("Stone", b3 + Vector3(0, 1.2, 0), 12.0, 11.0, 7.0, 8, PI / 8.0)
	var dome := b3 + Vector3(0, 8.2, 0)
	lm.lathe("Gold", dome, LandmarkKits.onion_profile(9.0, 9.8), 16)
	lm.frustum("Gold", dome + Vector3(0, 9.4, 0), 0.4, 0.1, h - 30.0 - (dome.y - base.y) - 9.4, 6)

## The clock tower: shaft, clock storey, crown and spire.
static func _clock_tower(lm: LandmarkMesh) -> void:
	var b := Vector3(0, 30, 0)
	# Base block, then the shaft tapering from 60 to 52 m.
	lm.box("Stone", b + Vector3(0, 30, 0), Vector3(72, 60, 72))
	for d in [Vector3.RIGHT, Vector3.LEFT, Vector3.BACK, Vector3.FORWARD]:
		var r: Vector3 = Vector3.UP.cross(d)
		LandmarkMaParts.arched_bays(lm, "Stone", "Glass", b + d * 36.0 - r * 36.0, r, d, 72.0, 56.0, 5, 9.0,
			34.0, 8.0, 0.8, "Gold", 5)
	var sb := b + Vector3(0, 60, 0)
	var sh := 302.0
	lm.spire("Stone", sb, 30.0, sh, 26.0)
	for d in [Vector3.RIGHT, Vector3.LEFT, Vector3.BACK, Vector3.FORWARD]:
		var r: Vector3 = Vector3.UP.cross(d)
		# Corner ribs and vertical glazed slots on each face.
		for k in [-1.0, 1.0]:
			lm.beam("Stone", sb + d * 30.6 + r * k * 28.0, sb + d * 26.6 + r * k * 24.4 + Vector3(0, sh, 0), 3.2, 2.0, d)
		for j in 5:
			var off := (float(j) - 2.0) * 9.0
			lm.beam("Glass", sb + d * 30.15 + r * off, sb + d * 26.15 + r * off * 0.87 + Vector3(0, sh, 0), 0.4, 3.4, d)
		# Pointed-arch heads under the clock storey.
		LandmarkMaParts.arched_bays(lm, "Stone", "Glass", sb + Vector3(0, sh - 20.0, 0) + d * 26.6 - r * 26.0, r,
			d, 52.0, 20.0, 5, 6.0, 9.0, 5.0, 0.6, "Gold", 4)
	# Clock storey: 57 m tall, 56 m square, faces at 427 m.
	var cb := sb + Vector3(0, sh, 0)
	lm.box("Stone", cb + Vector3(0, 28.5, 0), Vector3(56, 57, 56))
	var cy := cb.y + 30.0
	for d in [Vector3.RIGHT, Vector3.LEFT, Vector3.BACK, Vector3.FORWARD]:
		var r: Vector3 = Vector3.UP.cross(d)
		var fc: Vector3 = d * 28.0 + Vector3(0, cy, 0)
		lm.box("Gold", fc + d * 0.4, Vector3(52, 52, 0.8), Basis(r, Vector3.UP, d), 0.0)
		lm.disc("Gold", fc + d * 0.85, d, 23.5, 48)
		lm.disc("Clock", fc + d * 1.0, d, 21.5, 48)
		for k in 12:
			var a := TAU * float(k) / 12.0
			var m: Vector3 = fc + d * 1.15 + (r * cos(a) + Vector3.UP * sin(a)) * 18.5
			var mk := 4.0 if k % 3 == 0 else 2.4
			lm.beam("Gold", m, m + (r * cos(a) + Vector3.UP * sin(a)) * mk, 0.9, 0.3, d)
		lm.beam("Gold", fc + d * 1.3, fc + d * 1.3 + (r * 0.5 + Vector3.UP * 0.86) * 12.0, 1.4, 0.3, d)
		lm.beam("Gold", fc + d * 1.4, fc + d * 1.4 + (r * -0.9 + Vector3.UP * 0.2) * 17.0, 0.9, 0.3, d)
		# Gilded inscription band above the clock.
		for k in 18:
			var lx := (float(k) - 8.5) * 2.7
			var lh := 2.0 + 2.2 * absf(sin(float(k) * 1.7))
			lm.box("Gold", d * 28.6 + r * lx + Vector3(0, cb.y + 57.0 + lh * 0.5, 0), Vector3(1.0, lh, 0.5),
				Basis(r, Vector3.UP, d), 0.0)
		lm.box("Gold", d * 28.6 + Vector3(0, cb.y + 57.4, 0), Vector3(48, 0.8, 0.5), Basis(r, Vector3.UP, d), 0.0)
	# Corner pillars with their gold domes.
	for c in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
		var p := Vector3(c.x * 28.5, cb.y, c.y * 28.5)
		lm.box("Stone", p + Vector3(0, 33, 0), Vector3(7, 66, 7))
		lm.frustum("Stone", p + Vector3(0, 66, 0), 4.0, 4.0, 2.0, 16)
		lm.lathe("Gold", p + Vector3(0, 68, 0), LandmarkKits.onion_profile(3.6, 7.0), 16)
		lm.frustum("Gold", p + Vector3(0, 74.5, 0), 0.25, 0.05, 5.0, 6)
	# Crown: stepped gold tiers with the observatory, top floor 494 m.
	var kb := cb + Vector3(0, 57, 0)
	lm.box("Stone", kb + Vector3(0, 4, 0), Vector3(50, 8, 50))
	var tiers := [[24.0, 23.0, 12.0], [20.0, 19.0, 10.0], [16.0, 15.0, 10.0], [12.5, 12.0, 6.0]]
	var y := kb.y + 8.0
	for tr in tiers:
		lm.spire("Gold", Vector3(0, y, 0), float(tr[0]), float(tr[2]), float(tr[1]))
		LandmarkMaParts.arched_ring(lm, "Gold", "Glass", Vector3(0, y, 0), float(tr[1]) * 1.414 * 0.98, 4,
			float(tr[2]) * 0.8, float(tr[1]) * 0.35, float(tr[2]) * 0.35, float(tr[2]) * 0.2, 0.3, PI / 4.0)
		y += float(tr[2])
	# Spire to the crescent's tip at 601 m.
	var spb := Vector3(0, y, 0)
	var sp_h := 601.0 - y - 21.0
	lm.lathe("Gold", spb, PackedVector2Array([Vector2(9.0, 0), Vector2(6.5, sp_h * 0.2), Vector2(4.2, sp_h * 0.45),
		Vector2(2.4, sp_h * 0.75), Vector2(1.2, sp_h)]), 12)
	for k in 4:
		lm.frustum("Gold", spb + Vector3(0, sp_h * (0.15 + 0.2 * float(k)), 0),
			lerpf(7.5, 2.2, 0.2 + 0.25 * float(k)), lerpf(7.5, 2.2, 0.2 + 0.25 * float(k)), 1.0, 12)
	LandmarkMaParts.sphere(lm, "Gold", spb + Vector3(0, sp_h + 1.6, 0), 2.2, 12, 6)
	LandmarkMaParts.crescent(lm, "Gold", spb + Vector3(0, sp_h + 13.0, 0), 9.6, 1.6)
