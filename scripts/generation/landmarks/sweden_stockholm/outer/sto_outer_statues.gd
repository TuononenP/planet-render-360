class_name StoOuterStatues
extends RefCounted

## Two bronze monuments of central Stockholm, built on StatueBuilder's figure
## and horse (model origin at the pedestal centre, +X east, +Z south, no yaw).
##
## Karl XII (Johan Peter Molin, 1868; OSM node 300169645 at the southern end
## of Kungsträdgården, on Karl XII:s torg; the brief's "north end" is the
## mapped position's opposite): a standing verdigris bronze king in a long
## coat, right arm flung out and up to the east, left hand on the sword,
## on a tall pale-granite pedestal (plinth, die, cornice) standing on three
## granite steps; four bronze mortars on granite blocks stand at the corners
## and are joined by iron chain. Photos: visual-plan/refs/karl_xii_statue/.
##
## Gustav II Adolf (Sergel, cast 1796; OSM way 1275232253 on Gustav Adolfs
## torg): the king in armour on a walking horse, baton raised, in dark green
## patinated bronze on a dark red-brown granite pedestal (long side along
## X, the horse faces west) about 4.8 m high with two bronze medallions on
## each long side; two seated bronze allegories (Clio and Wisdom) at the
## base, two granite steps round it and low squared granite bollards on a
## chain. The horse and king are built here, not by StatueBuilder. Photos: visual-plan/refs/gustav_ii_adolf_statue/.
## Heights are estimated from the photos (about 8.5 m, 9 m with the
## raised arm for Karl XII); no height is mapped.
## Surfaces (3 each): Stone, Bronze, Post (granite blocks).

const STEP_H := 0.25
## Leg thickness over the anatomical radii: a monument's legs read heavy.
const LEG_K := 1.3

static func build_karl(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#B9B2A3", 3.0))
	lm.use("Bronze", LandmarkMaterials.pbr("concrete", "#4F8F7C", 2.0, 0.5, 0.6))
	lm.use("Post", LandmarkMaterials.pbr("stone", "#8A8A84", 2.5))
	# Three steps up to the pedestal.
	for k in 3:
		var w := 5.8 - 0.9 * float(k)
		lm.box("Post", Vector3(0, STEP_H * (float(k) + 0.5), 0), Vector3(w, STEP_H, w), Basis(), 0.0)
	var y := STEP_H * 3.0
	var fig := {"x": 0.0, "z": 0.0, "statue": "statue", "statue_dir": 90.0, "size_x": 2.5, "size_z": 2.5,
		"height": 8.5 - y, "height_source": "tag_height"}
	lm.merge(StatueBuilder.mesh(fig, y), Transform3D())
	# Right arm out and up, pointing east, with the cuff and hand.
	var fig_h := 3.25
	var ph := 8.5 - y - fig_h
	var sh := Vector3(0.0, y + ph + fig_h * 0.77, 0.0)
	lm.beam("Bronze", sh + Vector3(0.1, 0, 0.15), sh + Vector3(0.8, 0.5, 0.2), 0.2, 0.2)
	lm.beam("Bronze", sh + Vector3(0.8, 0.5, 0.2), sh + Vector3(1.4, 1.0, 0.2), 0.15, 0.15)
	# Sword hanging at the hip.
	lm.beam("Bronze", Vector3(-0.35, y + ph + fig_h * 0.45, 0.1), Vector3(-0.2, y + ph + 0.1, 0.55), 0.08, 0.08)
	_mortars(lm, 3.4, 4.2)
	lm.commit(model, "Karl_xii_")

## Cast bronze with a smooth green patina: a plain tinted albedo, no concrete
## grain or normal map, so the skin's own normals carry the highlights.
static func _bronze() -> StandardMaterial3D:
	var img := Image.create(4, 4, false, Image.FORMAT_RGB8)
	for y in 4:
		for x in 4:
			img.set_pixel(x, y, Color("#46705F").lerp(Color("#527A68"), float(x + y) / 6.0))
	var m := StandardMaterial3D.new()
	m.albedo_texture = ImageTexture.create_from_image(img)
	m.metallic = 0.55
	m.roughness = 0.36
	return m

static func build_gustav(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#A5826F", 3.0))
	lm.use("Bronze", LandmarkMaterials.pbr("concrete", "#3F6556", 2.0, 0.5, 0.6))
	lm.use("Post", LandmarkMaterials.pbr("stone", "#B4B0A6", 2.5))
	# Granite pedestal, long side along X: two steps, plinth, die, cornice.
	for k in 2:
		lm.box("Post", Vector3(0, STEP_H * (float(k) + 0.5), 0),
			Vector3(6.6 - 0.8 * float(k), STEP_H, 4.0 - 0.6 * float(k)), Basis(), 0.0)
	var y := STEP_H * 2.0
	lm.box("Stone", Vector3(0, y + 0.3, 0), Vector3(5.4, 0.6, 3.5), Basis(), 0.0)
	lm.box("Stone", Vector3(0, y + 0.6 + 1.5, 0), Vector3(4.6, 3.0, 2.8), Basis(), 0.0)
	lm.box("Stone", Vector3(0, y + 3.6 + 0.15, 0), Vector3(5.2, 0.3, 3.3), Basis(), 0.0)
	lm.box("Stone", Vector3(0, y + 3.9 + 0.2, 0), Vector3(5.6, 0.4, 3.6), Basis(), 0.0)
	# Moulding bands at the foot and head of the die, in pale granite.
	for by in [0.7, 3.4]:
		lm.box("Post", Vector3(0, y + by, 0), Vector3(4.78, 0.14, 2.98), Basis(), 0.0)
	var top := y + 4.3
	# Medallions on the two long faces.
	for s in [-1.0, 1.0]:
		for k in 2:
			var c := Vector3((float(k) - 0.5) * 2.0, y + 2.1, float(s) * 1.43)
			_medallion(lm, c, float(s))
	# The king on his horse, facing west, built facing +Z and turned.
	var part := LandmarkMesh.new()
	part.use("Bronze", null)  # lm carries the material
	_horse(part)
	_king(part)
	lm.merge(part, Transform3D(Basis(Vector3.UP, -PI * 0.5), Vector3(0, top, 0)))
	# Two seated allegories at the front corners, on the square.
	for s in [-1.0, 1.0]:
		LandmarkKits.statue_figure(lm, "Bronze", Vector3(float(s) * 1.6, 0.0, 2.45), 1.9)
	_posts(lm)
	lm.commit(model, "Gustav_adolf_")

## A tapered round member from `a` (radius r0) to `b` (radius r1).
static func _limb(lm: LandmarkMesh, a: Vector3, b: Vector3, r0: float, r1: float) -> void:
	var axis := b - a
	if axis.length() < 0.001:
		return
	var up := axis.normalized()
	var x := up.cross(Vector3.FORWARD if absf(up.z) < 0.9 else Vector3.RIGHT).normalized()
	var piece := LandmarkMesh.new()
	piece.use("Bronze", null)  # lm carries the material
	piece.frustum("Bronze", Vector3.ZERO, r0, r1, axis.length(), 16)
	lm.merge(piece, Transform3D(Basis(x, up, x.cross(up)), a))

const Sdf = preload("res://scripts/generation/landmarks/sweden_stockholm/outer/sto_sdf_bronze.gd")
## Grid spacing of the horse's and the king's skins, metres.
const HORSE_CELL := 0.065
const KING_CELL := 0.04

## The walking horse, nose to +Z, hooves on y = 0, about 2.5 m at the
## withers (a monument's larger-than-life scale), as one smooth skin
## (StoSdfBronze), proportioned from visual-plan/refs/landmarks/
## gustav_ii_adolf_statue: a slim barrel, a long arched neck with a mane
## ridge, a small head with poll, brow, long face, jaw, muzzle, eyes and
## nostrils, haunch and shoulder masses, slim legs through knee, stifle,
## hock and fetlock to hooves (near fore leg raised, near hind leg back on
## its toe with a clear hock angle) and a tail ribbon. The ears are separate
## thin cones.
static func _horse(lm: LandmarkMesh) -> void:
	var m: Array = []
	# Body: chest, belly and croup run together into one slim barrel.
	m.append(Sdf.egg(Vector3(0, 1.8, 0.7), Vector3(0.46, 0.63, 0.56), 0.25))
	m.append(Sdf.egg(Vector3(0, 1.74, -0.1), Vector3(0.44, 0.57, 0.76), 0.25))
	m.append(Sdf.egg(Vector3(0, 1.86, -0.92), Vector3(0.47, 0.58, 0.5), 0.25))
	m.append(Sdf.egg(Vector3(0, 2.4, 0.62), Vector3(0.32, 0.3, 0.38), 0.2))
	# Neck: long and arched, thick at the shoulder; the mane is a ridge of
	# flat ellipsoids along its crest.
	m.append(Sdf.capsule(Vector3(0, 1.95, 0.8), Vector3(0, 2.65, 1.0), 0.35, 0.26, 0.2))
	m.append(Sdf.capsule(Vector3(0, 2.65, 1.0), Vector3(0, 3.2, 1.38), 0.26, 0.18, 0.18))
	m.append(Sdf.capsule(Vector3(0, 3.2, 1.38), Vector3(0, 3.42, 1.7), 0.18, 0.14, 0.12))
	for i in 7:
		var t := float(i) / 6.0
		m.append(Sdf.egg(Vector3(0, lerpf(2.7, 3.46, t), lerpf(0.7, 1.55, t)), Vector3(0.045, 0.15, 0.1), 0.08))
	# Head: poll, brow, long face, jaw, muzzle, eyes, nostrils.
	m.append(Sdf.egg(Vector3(0, 3.42, 1.74), Vector3(0.13, 0.16, 0.18), 0.08))
	m.append(Sdf.capsule(Vector3(0, 3.4, 1.76), Vector3(0, 2.95, 2.12), 0.11, 0.075, 0.06))
	m.append(Sdf.egg(Vector3(0, 3.1, 1.98), Vector3(0.09, 0.12, 0.15), 0.04))
	m.append(Sdf.egg(Vector3(0, 2.92, 2.16), Vector3(0.08, 0.085, 0.12), 0.04))
	for sx in [-1.0, 1.0]:
		var sg: float = sx
		m.append(Sdf.egg(Vector3(sg * 0.11, 3.47, 1.82), Vector3(0.05, 0.035, 0.07), 0.025))
		m.append(Sdf.egg(Vector3(sg * 0.12, 3.43, 1.87), Vector3(0.04, 0.045, 0.045), 0.025))
		m.append(Sdf.egg(Vector3(sg * 0.05, 2.92, 2.27), Vector3(0.03, 0.035, 0.035), 0.025))
	# Haunch and shoulder masses, then the legs through their joints.
	for sx in [-1.0, 1.0]:
		var sg: float = sx
		m.append(Sdf.egg(Vector3(sg * 0.28, 1.82, -0.95), Vector3(0.19, 0.4, 0.34), 0.16))
		m.append(Sdf.egg(Vector3(sg * 0.27, 1.8, 0.82), Vector3(0.17, 0.36, 0.27), 0.16))
	# Near (x > 0) fore leg raised and bent, the far fore leg planted.
	_leg(m, [Vector3(0.24, 1.75, 0.8), Vector3(0.26, 1.2, 1.4), Vector3(0.26, 0.86, 1.3),
		Vector3(0.26, 0.55, 1.42)], [0.17, 0.11, 0.072, 0.08])
	_leg(m, [Vector3(-0.24, 1.75, 0.8), Vector3(-0.24, 0.95, 0.88), Vector3(-0.24, 0.34, 0.9),
		Vector3(-0.24, 0.1, 0.95)], [0.17, 0.11, 0.072, 0.085])
	# Hind legs: hip, stifle, hock, fetlock, hoof. The near one steps back
	# with the hock far behind the stifle.
	_leg(m, [Vector3(0.26, 1.9, -0.9), Vector3(0.27, 1.32, -1.12), Vector3(0.28, 0.92, -1.62),
		Vector3(0.28, 0.42, -1.32), Vector3(0.28, 0.1, -1.16)], [0.2, 0.14, 0.09, 0.068, 0.078])
	_leg(m, [Vector3(-0.26, 1.9, -0.9), Vector3(-0.26, 1.3, -1.1), Vector3(-0.26, 0.86, -1.38),
		Vector3(-0.26, 0.34, -1.28), Vector3(-0.26, 0.1, -1.2)], [0.2, 0.14, 0.09, 0.068, 0.082])
	# Tail: from the croup in a long curve, a ribbon ending in a tuft.
	m.append(Sdf.capsule(Vector3(0, 2.3, -1.34), Vector3(0, 1.9, -1.95), 0.09, 0.1, 0.1))
	m.append(Sdf.capsule(Vector3(0, 1.9, -1.95), Vector3(0, 1.1, -2.15), 0.1, 0.09, 0.1))
	m.append(Sdf.egg(Vector3(0, 0.88, -2.15), Vector3(0.08, 0.3, 0.11), 0.08))
	Sdf.mesh(lm, "Bronze", m, HORSE_CELL)
	for sx in [-1.0, 1.0]:
		_limb(lm, Vector3(float(sx) * 0.08, 3.5, 1.68), Vector3(float(sx) * 0.07, 3.8, 1.62), 0.06, 0.012)

## A leg through its joints (hip first, hoof last) with their radii, as
## blended capsules; the last capsule is the hoof, a little wider.
static func _leg(m: Array, pts: Array, radii: Array) -> void:
	var n := pts.size()
	for i in n - 1:
		m.append(Sdf.capsule(pts[i], pts[i + 1], float(radii[i]) * LEG_K, float(radii[i + 1]) * LEG_K,
			0.14 if i == 0 else 0.07))
	var hoof: Vector3 = pts[n - 1]
	m.append(Sdf.capsule(hoof + Vector3(0, 0.05, 0), hoof - Vector3(0, 0.02, 0), float(radii[n - 1]) * 1.2,
		float(radii[n - 1]) * 1.3, 0.05))

## Gustav II Adolf in armour, one smooth skin: seated astride, a torso with
## cuirass and narrow pauldrons, a cloak falling behind over the horse's
## croup, a head with nose, brow ridge, moustache and beard, arms with real
## forearms (right raised with the commander's baton, left to the reins),
## thighs, shins and riding boots. The plumed hat with its brim, the baton
## and the reins are separate thin members.
static func _king(lm: LandmarkMesh) -> void:
	var m: Array = []
	m.append(Sdf.egg(Vector3(0, 2.62, -0.1), Vector3(0.28, 0.2, 0.32), 0.15))
	m.append(Sdf.capsule(Vector3(0, 2.72, -0.1), Vector3(0, 3.2, -0.08), 0.22, 0.26, 0.15))
	m.append(Sdf.egg(Vector3(0, 3.2, -0.05), Vector3(0.27, 0.3, 0.2), 0.15))
	m.append(Sdf.capsule(Vector3(0, 3.45, -0.08), Vector3(0, 3.65, -0.06), 0.1, 0.085, 0.08))
	# Head: skull, brow ridge, nose, moustache, beard.
	m.append(Sdf.egg(Vector3(0, 3.84, -0.05), Vector3(0.13, 0.17, 0.14), 0.05))
	m.append(Sdf.egg(Vector3(0, 3.9, 0.05), Vector3(0.1, 0.03, 0.06), 0.03))
	m.append(Sdf.egg(Vector3(0, 3.81, 0.1), Vector3(0.035, 0.065, 0.07), 0.03))
	m.append(Sdf.egg(Vector3(0, 3.73, 0.09), Vector3(0.075, 0.025, 0.05), 0.02))
	m.append(Sdf.capsule(Vector3(0, 3.7, 0.06), Vector3(0, 3.58, 0.09), 0.065, 0.04, 0.04))
	# Cloak: a broad drape from the shoulders down the back and over the croup.
	m.append(Sdf.capsule(Vector3(-0.27, 3.5, -0.24), Vector3(-0.32, 2.5, -0.52), 0.09, 0.12, 0.12))
	m.append(Sdf.capsule(Vector3(0.27, 3.5, -0.24), Vector3(0.32, 2.5, -0.52), 0.09, 0.12, 0.12))
	m.append(Sdf.egg(Vector3(0, 3.0, -0.4), Vector3(0.34, 0.5, 0.1), 0.12))
	m.append(Sdf.egg(Vector3(0, 2.35, -0.62), Vector3(0.34, 0.42, 0.1), 0.12))
	for sx in [-1.0, 1.0]:
		var sg: float = sx
		m.append(Sdf.egg(Vector3(sg * 0.31, 3.48, -0.1), Vector3(0.12, 0.1, 0.13), 0.08))
		# Thigh, knee, shin, boot with its cuff and toe.
		m.append(Sdf.capsule(Vector3(sg * 0.24, 2.64, -0.05), Vector3(sg * 0.48, 2.0, 0.3), 0.16, 0.11, 0.1))
		m.append(Sdf.capsule(Vector3(sg * 0.48, 2.0, 0.3), Vector3(sg * 0.48, 1.5, 0.2), 0.11, 0.09, 0.08))
		m.append(Sdf.capsule(Vector3(sg * 0.48, 1.62, 0.2), Vector3(sg * 0.48, 1.4, 0.24), 0.12, 0.1, 0.05))
		m.append(Sdf.egg(Vector3(sg * 0.48, 1.3, 0.34), Vector3(0.095, 0.085, 0.19), 0.05))
	# Right arm: upper arm up and out, forearm forward to the baton hand.
	m.append(Sdf.capsule(Vector3(0.33, 3.48, -0.1), Vector3(0.56, 3.72, 0.2), 0.105, 0.085, 0.07))
	m.append(Sdf.capsule(Vector3(0.56, 3.72, 0.2), Vector3(0.6, 3.98, 0.52), 0.085, 0.06, 0.05))
	m.append(Sdf.egg(Vector3(0.6, 4.0, 0.55), Vector3(0.07, 0.07, 0.08), 0.04))
	# Left arm: down and forward to the reins.
	m.append(Sdf.capsule(Vector3(-0.33, 3.48, -0.1), Vector3(-0.5, 3.12, 0.15), 0.105, 0.085, 0.07))
	m.append(Sdf.capsule(Vector3(-0.5, 3.12, 0.15), Vector3(-0.14, 3.0, 0.7), 0.085, 0.06, 0.05))
	m.append(Sdf.egg(Vector3(-0.12, 3.0, 0.72), Vector3(0.07, 0.07, 0.08), 0.04))
	Sdf.mesh(lm, "Bronze", m, KING_CELL)
	# Saddle cloth, plumed hat with a turned brim, baton and rein.
	lm.box("Bronze", Vector3(0, 2.42, -0.08), Vector3(0.8, 0.1, 1.05), Basis(), 0.0)
	lm.lathe("Bronze", Vector3(0, 3.95, -0.05), PackedVector2Array([Vector2(0.34, 0.0), Vector2(0.31, 0.04),
		Vector2(0.18, 0.07), Vector2(0.165, 0.2), Vector2(0.13, 0.25), Vector2(0.0, 0.25)]), 24)
	_limb(lm, Vector3(-0.12, 4.13, -0.08), Vector3(-0.3, 4.25, -0.4), 0.045, 0.03)
	_limb(lm, Vector3(-0.3, 4.25, -0.4), Vector3(-0.4, 4.05, -0.62), 0.03, 0.012)
	var hand := Vector3(0.6, 4.0, 0.55)
	_limb(lm, hand - Vector3(0, 0.05, -0.15), hand + Vector3(0.1, 0.55, 0.85), 0.03, 0.025)
	lm.beam("Bronze", Vector3(-0.12, 3.0, 0.72), Vector3(0, 2.95, 2.1), 0.025, 0.025)

## A medallion on the long face at `c` looking along `side` (+-Z): a raised
## disc inside a moulded ring.
static func _medallion(lm: LandmarkMesh, c: Vector3, side: float) -> void:
	var ring := PackedVector2Array()
	for i in 9:
		var a := TAU * float(i) / 8.0
		ring.append(Vector2(0.5 + 0.06 * cos(a), 0.06 * sin(a)))
	var piece := LandmarkMesh.new()
	piece.use("Bronze", null)  # lm carries the material
	piece.lathe("Bronze", Vector3.ZERO, ring, 24, 1.0, 1.0, 0.0, true, false)
	piece.lathe("Bronze", Vector3.ZERO, PackedVector2Array([Vector2(0.46, 0.0), Vector2(0.4, 0.05),
		Vector2(0.0, 0.1)]), 24)
	lm.merge(piece, Transform3D(Basis(Vector3.RIGHT, side * PI * 0.5), c))

## Four bronze mortars on granite blocks at the corners of a square, joined
## by sagging iron chain.
static func _mortars(lm: LandmarkMesh, half: float, _unused: float) -> void:
	var corners := [Vector2(-half, -half), Vector2(half, -half), Vector2(half, half), Vector2(-half, half)]
	for c in corners:
		lm.box("Post", Vector3(c.x, 0.35, c.y), Vector3(1.0, 0.7, 1.0), Basis(), 0.0)
		lm.lathe("Bronze", Vector3(c.x, 0.7, c.y), PackedVector2Array([Vector2(0.5, 0), Vector2(0.4, 0.15),
			Vector2(0.38, 0.7), Vector2(0.42, 1.1), Vector2(0.45, 1.25), Vector2(0.25, 1.4), Vector2(0.0, 1.5)]), 14)
	for i in 4:
		_chain(lm, Vector3(corners[i].x, 1.45, corners[i].y), Vector3(corners[(i + 1) % 4].x, 1.45, corners[(i + 1) % 4].y))

## Chain of short links sagging 0.4 m between two posts.
static func _chain(lm: LandmarkMesh, a: Vector3, b: Vector3) -> void:
	var prev := a
	for k in range(1, 7):
		var t := float(k) / 6.0
		var p := a.lerp(b, t)
		p.y -= 0.45 * 4.0 * t * (1.0 - t)
		lm.beam("Bronze", prev, p, 0.07, 0.07)
		prev = p

## Squared granite bollards round Gustav II Adolf, linked by chain.
static func _posts(lm: LandmarkMesh) -> void:
	var ring: Array = []
	var hx := 5.4
	var hz := 3.8
	for i in 4:
		ring.append(Vector2(-hx + 2.0 * hx * float(i) / 3.0, -hz))
	for i in 1:
		ring.append(Vector2(hx, 0.0))
	for i in 4:
		ring.append(Vector2(hx - 2.0 * hx * float(i) / 3.0, hz))
	ring.append(Vector2(-hx, 0.0))
	for c in ring:
		lm.box("Post", Vector3(c.x, 0.55, c.y), Vector3(0.6, 1.1, 0.6), Basis(), 0.0)
	for i in ring.size():
		var a: Vector2 = ring[i]
		var b: Vector2 = ring[(i + 1) % ring.size()]
		_chain(lm, Vector3(a.x, 0.95, a.y), Vector3(b.x, 0.95, b.y))
