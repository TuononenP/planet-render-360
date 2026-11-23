class_name LandmarkMseKit2
extends RefCounted

## Extended Rattanakosin / Bangkok architectural kit (BK-1) built on
## LandmarkMesh, LandmarkMseUtil and LandmarkMseKit:
##   mondop, yaksha, chinese_guardian, chinese_pagoda, naga_rail,
##   royal_umbrella, kinnari_lamp, bai_sema, reclining_buddha, fort_tier.
## Every routine takes material keys registered on `lm` and builds in true
## metres upward from `base`.

const U = preload("res://scripts/generation/landmarks/mainland_se_asia/landmark_mse_util.gd")
const K = preload("res://scripts/generation/landmarks/mainland_se_asia/landmark_mse_kit.gd")

## Square Thai pavilion (mondop) w x w on a moulded plinth, wall_h body with
## peristyle columns, pointed windows on three sides and a door on +Z, crowned
## by a multi-tier prasat spire reaching total height plinth_h + wall_h + spire_h.
## Keys k = {wall, stone, tile, gold, dark, col}.
static func mondop(lm: LandmarkMesh, k: Dictionary, base: Vector3, basis: Basis,
		w: float, wall_h: float, spire_h: float, tiers: int = 5, plinth_h: float = 1.4) -> float:
	var wall: String = k["wall"]
	var stone: String = k["stone"]
	var tile: String = k["tile"]
	var gold: String = k["gold"]
	var dark: String = k["dark"]
	var col: String = k.get("col", gold)
	var peri := w * 0.16
	var pw := w + peri * 2.0
	K.plinth(lm, stone, base, basis, pw + 1.6, pw + 1.6, plinth_h)
	var y0 := plinth_h
	lm.box(wall, base + basis * Vector3(0, y0 + wall_h * 0.5, 0), Vector3(w, wall_h, w), basis)
	lm.box(gold, base + basis * Vector3(0, y0 + wall_h - 0.25, 0), Vector3(w + 0.3, 0.45, w + 0.3), basis)
	var nb := maxi(int(round(pw / 2.6)), 3)
	K.peristyle(lm, col, gold, base + basis * Vector3(0, y0, 0), basis, pw, pw, wall_h,
		clampf(w * 0.055, 0.42, 0.78), pw / float(nb))
	for side in 4:
		var sb := basis * Basis(Vector3.UP, PI * 0.5 * float(side))
		var is_door := (side == 0)
		var ow := w * (0.22 if is_door else 0.16)
		var oh := wall_h * (0.62 if is_door else 0.42)
		var oy := y0 + (0.0 if is_door else wall_h * 0.22)
		K.thai_window(lm, wall, dark, gold, base + sb * Vector3(0, oy, w * 0.5 + 0.02), sb, ow, oh)
	var sy := y0 + wall_h + 0.35
	lm.box(stone, base + basis * Vector3(0, sy - 0.18, 0), Vector3(pw + 0.6, 0.36, pw + 0.6), basis)
	U.prasat_spire(lm, wall, tile, gold, base + basis * Vector3(0, sy, 0), pw * 0.52, spire_h, tiers)
	return sy + spire_h

## Guardian giant (Thotsakan / Sahatsadecha yaksha, 5-6 m tall) standing on a
## stepped pedestal facing basis +Z, holding a tall vertical club (gada) in front.
static func yaksha(lm: LandmarkMesh, body: String, armour: String, gold: String,
		base: Vector3, basis: Basis, h: float = 5.6) -> void:
	var ph := h * 0.18
	lm.box(armour, base + basis * Vector3(0, ph * 0.35, 0), Vector3(h * 0.36, ph * 0.7, h * 0.36), basis)
	lm.box(gold, base + basis * Vector3(0, ph * 0.85, 0), Vector3(h * 0.30, ph * 0.3, h * 0.30), basis)
	var y := ph
	var fh := h - ph
	# Planted legs
	for sx in [-1.0, 1.0]:
		var hip := base + basis * Vector3(sx * fh * 0.09, y + fh * 0.30, 0)
		var foot := base + basis * Vector3(sx * fh * 0.11, y, fh * 0.02)
		lm.beam(body, foot, hip, fh * 0.09, fh * 0.10, basis.x)
		lm.box(gold, foot + basis * Vector3(0, fh * 0.03, fh * 0.03), Vector3(fh * 0.09, fh * 0.06, fh * 0.14), basis, 0.0)
	# Loincloth & armored torso
	lm.frustum(armour, base + basis * Vector3(0, y + fh * 0.24, 0), fh * 0.16, fh * 0.12, fh * 0.14, 8, basis.get_euler().y)
	lm.lathe(armour, base + basis * Vector3(0, y + fh * 0.36, 0), PackedVector2Array([
		Vector2(fh * 0.12, 0), Vector2(fh * 0.17, fh * 0.16), Vector2(fh * 0.14, fh * 0.24)]), 8, 1.15, 0.82, basis.get_euler().y)
	# Winged shoulder epaulets (inthanu) & arms forward to club
	for sx in [-1.0, 1.0]:
		var sh := base + basis * Vector3(sx * fh * 0.18, y + fh * 0.56, 0)
		lm.beam(gold, sh, sh + basis * Vector3(sx * fh * 0.08, fh * 0.08, -fh * 0.02), fh * 0.06, fh * 0.08, basis.z)
		var hand := base + basis * Vector3(sx * fh * 0.04, y + fh * 0.38, fh * 0.16)
		lm.beam(body, sh, hand, fh * 0.065, fh * 0.065, basis.x)
	# Head + tiered conical crown (mongkut)
	lm.lathe(body, base + basis * Vector3(0, y + fh * 0.60, 0), PackedVector2Array([
		Vector2(fh * 0.08, 0), Vector2(fh * 0.10, fh * 0.07), Vector2(fh * 0.085, fh * 0.14)]), 8, 1.0, 1.0, basis.get_euler().y)
	lm.lathe(gold, base + basis * Vector3(0, y + fh * 0.73, 0), PackedVector2Array([
		Vector2(fh * 0.105, 0), Vector2(fh * 0.08, fh * 0.07), Vector2(fh * 0.05, fh * 0.15),
		Vector2(fh * 0.02, fh * 0.22), Vector2(0.0, fh * 0.27)]), 8)
	# Vertical club (gada)
	var club_b := base + basis * Vector3(0, y, fh * 0.18)
	lm.beam(gold, club_b, club_b + Vector3(0, fh * 0.62, 0), fh * 0.045, fh * 0.045, basis.x)

## Carved grey stone Chinese ballast guardian warrior (Wat Pho / Wat Suthat).
static func chinese_guardian(lm: LandmarkMesh, stone: String, base: Vector3, basis: Basis, h: float = 3.2) -> void:
	var ph := h * 0.22
	lm.frustum(stone, base, h * 0.24, h * 0.20, ph, 7, basis.get_euler().y, 1.1, 0.9)
	var fh := h - ph
	lm.lathe(stone, base + Vector3(0, ph, 0), PackedVector2Array([
		Vector2(fh * 0.20, 0), Vector2(fh * 0.22, fh * 0.28), Vector2(fh * 0.18, fh * 0.52),
		Vector2(fh * 0.21, fh * 0.66), Vector2(fh * 0.11, fh * 0.74), Vector2(fh * 0.12, fh * 0.88),
		Vector2(fh * 0.08, fh * 0.96), Vector2(0.0, fh)]), 8, 1.15, 0.85, basis.get_euler().y)
	# Staff / halberd at right side
	var sb := base + basis * Vector3(fh * 0.20, ph, fh * 0.08)
	lm.beam(stone, sb, sb + Vector3(0, fh * 0.95, 0), fh * 0.035, fh * 0.035, basis.x)

## Hexagonal carved granite Chinese stone pagoda (thao, e.g. 28 around Wat Suthat).
static func chinese_pagoda(lm: LandmarkMesh, stone: String, base: Vector3, h: float = 4.8, tiers: int = 6) -> void:
	var r0 := h * 0.13
	lm.frustum(stone, base, r0 * 1.45, r0 * 1.2, h * 0.12, 6, 0.0)
	var y := h * 0.12
	var body_h := h * 0.74
	var th := body_h / float(tiers)
	for i in tiers:
		var f := 1.0 - 0.42 * float(i) / float(maxi(tiers, 1))
		var r := r0 * f
		lm.frustum(stone, base + Vector3(0, y, 0), r * 0.82, r * 0.78, th * 0.68, 6, 0.0)
		lm.lathe(stone, base + Vector3(0, y + th * 0.68, 0), PackedVector2Array([
			Vector2(r * 0.78, 0), Vector2(r * 1.28, th * 0.12), Vector2(r * 0.72, th * 0.32)]), 6, 1.0, 1.0, 0.0, false)
		y += th
	lm.lathe(stone, base + Vector3(0, y, 0), PackedVector2Array([
		Vector2(r0 * 0.32, 0), Vector2(r0 * 0.18, h * 0.06), Vector2(0.0, h * 0.14)]), 6, 1.0, 1.0, 0.0, false)

## Naga stair / terrace balustrade from `a` (top) to `b` (foot), rising into a
## multi-headed gilded Naga hood at `b`.
static func naga_rail(lm: LandmarkMesh, body: String, gold: String, a: Vector3, b: Vector3,
		rail_h: float = 0.85, head_h: float = 1.65) -> void:
	var d := b - a
	var flat := Vector3(d.x, 0, d.z)
	if flat.length() < 0.05:
		return
	var dir := flat.normalized()
	var side := Vector3(-dir.z, 0, dir.x)
	lm.beam(body, a + Vector3(0, rail_h * 0.5, 0), b + Vector3(0, rail_h * 0.5, 0), 0.32, rail_h, side)
	lm.beam(gold, a + Vector3(0, rail_h + 0.06, 0), b + Vector3(0, rail_h + 0.06, 0), 0.24, 0.14, side)
	# Upturned Naga neck and fanned 5-cobra hood at foot `b`
	var p0 := b + Vector3(0, rail_h * 0.6, 0)
	var p1 := b + dir * 0.35 + Vector3(0, rail_h + head_h * 0.45, 0)
	var p2 := b + dir * 0.20 + Vector3(0, rail_h + head_h * 0.92, 0)
	lm.beam(body, p0, p1, 0.30, 0.34, side)
	lm.beam(gold, p1, p2, 0.46, 0.20, side)
	var hb := Basis(side, Vector3.UP, dir)
	K.outline_prism(lm, gold, b + dir * 0.22 + Vector3(0, rail_h + head_h * 0.55, 0), hb,
		K.flame_outline(0.62, head_h * 0.55), 0.18)

## Tiered royal umbrella (chatra, 5/7/9 diminishing parasols on a slender pole).
static func royal_umbrella(lm: LandmarkMesh, gold: String, pole: String, base: Vector3,
		h: float = 4.2, tiers: int = 7) -> void:
	var r0 := h * 0.13
	lm.beam(pole, base, base + Vector3(0, h * 0.88, 0), h * 0.022, h * 0.022)
	var y0 := h * 0.32
	var span := h * 0.52
	for i in tiers:
		var t := float(i) / float(maxi(tiers - 1, 1))
		var r := r0 * lerpf(1.0, 0.36, t)
		var y := y0 + span * t
		lm.lathe(gold, base + Vector3(0, y, 0), PackedVector2Array([
			Vector2(r, 0), Vector2(r * 0.96, h * 0.022), Vector2(r * 0.15, h * 0.042)]), 10)
	lm.spire(gold, base + Vector3(0, h * 0.86, 0), r0 * 0.14, h * 0.14, 0.0, 6)

## Ornate Ratchadamnoen / civic kinnari lamp post with gilded figure & globe lamp.
static func kinnari_lamp(lm: LandmarkMesh, pole: String, gold: String, lamp_key: String,
		base: Vector3, yaw: float = 0.0, h: float = 6.2) -> void:
	var b := Basis(Vector3.UP, yaw)
	lm.frustum(pole, base, 0.28, 0.18, h * 0.16, 8)
	lm.beam(pole, base + Vector3(0, h * 0.16, 0), base + Vector3(0, h * 0.86, 0), 0.13, 0.13)
	# Gilded kinnari figure poised near upper shaft
	var ky := h * 0.66
	lm.lathe(gold, base + Vector3(0, ky, 0), PackedVector2Array([
		Vector2(0.10, 0), Vector2(0.20, h * 0.05), Vector2(0.13, h * 0.12), Vector2(0.05, h * 0.17)]), 8)
	lm.beam(gold, base + b * Vector3(0, ky + h * 0.08, -0.05), base + b * Vector3(0, ky + h * 0.15, -0.32), 0.12, 0.22, b.x)
	# Twin bracket arms + glowing globes
	for sx in [-1.0, 1.0]:
		var arm := base + b * Vector3(sx * 0.55, h * 0.88, 0)
		lm.beam(gold, base + Vector3(0, h * 0.82, 0), arm, 0.06, 0.06, b.z)
		lm.lathe(lamp_key, arm, PackedVector2Array([
			Vector2(0.08, 0), Vector2(0.22, h * 0.04), Vector2(0.20, h * 0.09), Vector2(0.04, h * 0.12)]), 8)

## Sacred boundary stone (bai sema) inside its 4-pillar Thai roofed niche.
static func bai_sema(lm: LandmarkMesh, stone: String, wall: String, tile: String, gold: String,
		base: Vector3, basis: Basis, h: float = 4.6) -> void:
	var w := h * 0.44
	lm.box(stone, base + basis * Vector3(0, h * 0.08, 0), Vector3(w * 1.2, h * 0.16, w * 1.2), basis)
	var leaf_h := h * 0.28
	K.outline_prism(lm, stone, base + basis * Vector3(0, h * 0.16, 0), basis,
		K.flame_outline(w * 0.46, leaf_h), 0.18)
	var col_h := h * 0.38
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			lm.box(wall, base + basis * Vector3(sx * w * 0.42, h * 0.16 + col_h * 0.5, sz * w * 0.42),
				Vector3(0.24, col_h, 0.24), basis, 0.0)
	var ry := h * 0.54
	U.prasat_spire(lm, wall, tile, gold, base + basis * Vector3(0, ry, 0), w * 0.54, h - ry, 3)

## Monumental Reclining Buddha (46 m long, 15 m high at Wat Pho): head at -X,
## feet at +X, facing +Z, resting on a moulded lotus pedestal with gilded
## pillow blocks and flat mother-of-pearl soles (`sole_key`).
static func reclining_buddha(lm: LandmarkMesh, gold: String, sole_key: String, pillow_key: String,
		base: Vector3, basis: Basis, length: float = 46.0, height: float = 15.0) -> void:
	var ph := height * 0.16
	K.plinth(lm, pillow_key, base, basis, length * 1.02, height * 0.48, ph)
	var y0 := ph
	var bh := height - ph
	# Gilded mosaic box pillows under head/right arm at -X
	lm.box(pillow_key, base + basis * Vector3(-length * 0.36, y0 + bh * 0.14, 0),
		Vector3(length * 0.16, bh * 0.28, height * 0.34), basis)
	lm.box(pillow_key, base + basis * Vector3(-length * 0.37, y0 + bh * 0.32, 0),
		Vector3(length * 0.12, bh * 0.16, height * 0.26), basis)
	# Reclining body swept along X from shoulders (-0.28 L) to ankles (+0.38 L)
	var rows: Array = []
	var prof_x := [-0.28, -0.18, -0.05, 0.10, 0.24, 0.38, 0.43]
	var prof_r := [0.27, 0.31, 0.27, 0.24, 0.20, 0.15, 0.12]
	var prof_yc := [0.42, 0.38, 0.32, 0.28, 0.24, 0.20, 0.19]
	for idx in prof_x.size():
		var cx := length * float(prof_x[idx])
		var cr := bh * float(prof_r[idx])
		var cy := y0 + bh * float(prof_yc[idx])
		var row := PackedVector3Array()
		for j in 11:
			var a := -PI * 0.15 + PI * 1.30 * float(j) / 10.0
			row.append(base + basis * Vector3(cx, cy + sin(a) * cr, cos(a) * cr * 0.78))
		rows.append(row)
	lm.grid(gold, rows, basis.y)
	# Stacked flat soles at +X in sole_key (pearl inlay)
	var fx := length * 0.445
	lm.box(gold, base + basis * Vector3(fx - 0.4, y0 + bh * 0.20, 0),
		Vector3(0.9, bh * 0.36, height * 0.22), basis)
	lm.box(sole_key, base + basis * Vector3(fx + 0.06, y0 + bh * 0.20, 0),
		Vector3(0.12, bh * 0.35, height * 0.21), basis, 0.0)
	# Supporting right arm, inclined head, curled hair & ushnisha flame to full `height`
	var head_c := base + basis * Vector3(-length * 0.35, y0 + bh * 0.56, height * 0.03)
	lm.beam(gold, base + basis * Vector3(-length * 0.31, y0 + bh * 0.22, height * 0.10),
		head_c + basis * Vector3(0, -bh * 0.06, 0.2), bh * 0.12, bh * 0.12, basis.z)
	lm.lathe(gold, head_c + Vector3(0, -bh * 0.14, 0), PackedVector2Array([
		Vector2(bh * 0.14, 0), Vector2(bh * 0.19, bh * 0.12), Vector2(bh * 0.17, bh * 0.26),
		Vector2(bh * 0.10, bh * 0.34), Vector2(bh * 0.05, bh * 0.40), Vector2(0.0, bh * 0.44)]), 12)

## Polygonal battered masonry bastion drum (Mahakan & Phra Sumen forts):
## `sides`-gon from `r_bot` to `r_top`, `h` tall, with moulded cordon,
## pointed-leaf battlements and dark cannon embrasure recesses.
static func fort_tier(lm: LandmarkMesh, wall: String, dark: String, base: Vector3,
		r_bot: float, r_top: float, h: float, sides: int = 8,
		crenel: bool = true, embrasures: bool = true) -> void:
	var rot := PI / float(sides)
	lm.lathe(wall, base, PackedVector2Array([
		Vector2(r_bot * 1.03, 0), Vector2(r_bot, h * 0.08),
		Vector2(r_top, h * 0.90), Vector2(r_top * 1.04, h * 0.95), Vector2(r_top * 1.02, h)]),
		sides, 1.0, 1.0, rot, false)
	var apothem := r_top * cos(PI / float(sides))
	var edge_len := 2.0 * r_top * sin(PI / float(sides))
	var leaf := PackedVector2Array([
		Vector2(-0.52, 0), Vector2(0.52, 0), Vector2(0.52, 0.48),
		Vector2(0.32, 0.85), Vector2(0.0, 1.12), Vector2(-0.32, 0.85), Vector2(-0.52, 0.48)])
	for s in sides:
		var a := rot + TAU * (float(s) + 0.5) / float(sides)
		var fb := Basis(Vector3.UP, PI * 0.5 - a)
		if embrasures:
			for k in [-0.24, 0.24]:
				var ep := base + fb * Vector3(k * edge_len, h * 0.58, apothem * 0.96)
				lm.box(dark, ep, Vector3(0.75, 0.95, 0.45), fb, 0.0)
				# Cannon barrel tip
				lm.beam(dark, ep + fb * Vector3(0, -0.1, 0.0), ep + fb * Vector3(0, -0.05, 0.65), 0.24, 0.24, fb.x)
		if crenel:
			var nm := maxi(int(floor(edge_len / 1.55)), 2)
			for m in nm:
				var u := -edge_len * 0.42 + edge_len * 0.84 * (float(m) + 0.5) / float(nm)
				K.outline_prism(lm, wall, base + fb * Vector3(u, h, apothem * 0.97), fb, leaf, 0.45)
