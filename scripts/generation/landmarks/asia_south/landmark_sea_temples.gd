class_name LandmarkSeaTemples
extends RefCounted

## South-east Asian temples in true metres: Angkor Wat, Wat Arun, the
## Shwedagon Pagoda and Borobudur.

const U = preload("res://scripts/generation/landmarks/asia_south/landmark_asia_south_util.gd")

## Angkor Wat (65 m): the three nested galleries stepping up to the
## quincunx of lotus-bud towers (central tower 65 m above the ground,
## four corner towers). The outer moat and causeway are left out.
static func angkor_wat(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Sand", LandmarkMaterials.pbr("stone", "#8E8574", 3.0))
	lm.use("Laterite", LandmarkMaterials.pbr("stone", "#8A5A40", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("slate", "#6C655A", 3.0))
	lm.box("Laterite", Vector3(0, 5.25, 0), Vector3(108.0, 16.5, 120.0))
	lm.box("Sand", Vector3(0, 13.25, 0), Vector3(110.0, 0.5, 122.0))
	lm.box("Sand", Vector3(0, 18.0, 0), Vector3(62.0, 10.0, 62.0))
	_gallery(lm, 0.0, 94.0, 107.0, 7.0, 5.5)
	_gallery(lm, 13.5, 51.0, 57.0, 6.0, 4.5)
	_gallery(lm, 23.0, 30.0, 30.0, 5.0, 4.0)
	_prang(lm, Vector3(0, 23.0, 0), 7.0, 42.0)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_prang(lm, Vector3(sx * 21.0, 23.0, sz * 21.0), 4.6, 30.0)
	lm.commit(model)

## Rectangular covered gallery round (0,0): four roofed wall ranges.
static func _gallery(lm: LandmarkMesh, y: float, hx: float, hz: float, thick: float,
		wall_h: float) -> void:
	var rise := thick * 0.55
	for s in [-1.0, 1.0]:
		var zc: float = s * (hz - thick * 0.5)
		lm.box("Sand", Vector3(0, y + wall_h * 0.5, zc), Vector3(hx * 2.0, wall_h, thick))
		lm.gable("Roof", Vector3(0, y + wall_h, zc), thick, hx * 2.0, rise,
			Basis(Vector3.UP, PI * 0.5), 0.5, "Sand")
		var xc: float = s * (hx - thick * 0.5)
		lm.box("Sand", Vector3(xc, y + wall_h * 0.5, 0), Vector3(thick, wall_h, hz * 2.0 - thick * 2.0))
		lm.gable("Roof", Vector3(xc, y + wall_h, 0), thick, hz * 2.0 - thick * 2.0, rise, Basis(),
			0.5, "Sand")


## Khmer lotus-bud tower of total height h: a square base, five
## stepped, tapering storeys with eave ledges and an ovoid crown.
static func _prang(lm: LandmarkMesh, base: Vector3, hw: float, h: float) -> void:
	lm.box("Sand", base + Vector3(0, h * 0.15, 0), Vector3(hw * 2.0, h * 0.3, hw * 2.0))
	var y := h * 0.3
	for k in 5:
		var w := hw * (0.86 - 0.15 * float(k))
		lm.box("Sand", base + Vector3(0, y + h * 0.015, 0), Vector3(w * 2.2, h * 0.03, w * 2.2))
		lm.spire("Roof", base + Vector3(0, y + h * 0.03, 0), w, h * 0.07, w * 0.84)
		y += h * 0.1
	lm.lathe("Roof", base + Vector3(0, y, 0), PackedVector2Array([Vector2(hw * 0.24, 0),
		Vector2(hw * 0.26, h * 0.035), Vector2(hw * 0.22, h * 0.08), Vector2(hw * 0.1, h * 0.12),
		Vector2(0.0, h * 0.14)]), 8)
	U.finial(lm, "Sand", base + Vector3(0, y + h * 0.12, 0), h - y - h * 0.12, 0.5)

## Wat Arun (70 m): the tall central prang in eight tiers of cream plaster
## and ceramic-tiled terraces on three stepped bases, four satellite
## prangs at the corners and the trident spire.
static func wat_arun(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("White", LandmarkMaterials.pbr("render", "#EDE7D6", 3.0))
	lm.use("Tile", LandmarkMaterials.pbr("terracotta", "#B98A58", 3.0))
	lm.use("Teal", LandmarkMaterials.pbr("render", "#4E8C86", 3.0))
	lm.use("Gold", LandmarkMaterials.gold())
	for k in 3:
		lm.box("White", Vector3(0, -1.0 + 4.0 * float(k) + 2.5, 0),
			Vector3(72.0 - 12.0 * float(k), 5.0, 72.0 - 12.0 * float(k)))
	_arun_prang(lm, Vector3(0, 12.0, 0), 13.0, 8, 5.6, 5.2)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_arun_prang(lm, Vector3(sx * 19.0, 12.0, sz * 19.0), 4.8, 5, 3.2, 3.0)
	# Trident (Indra's vajra) on the central tower, 62 -> 70 m.
	lm.beam("Gold", Vector3(0, 61.5, 0), Vector3(0, 70.0, 0), 0.45, 0.45)
	for s in [-1.0, 1.0]:
		lm.beam("Gold", Vector3(s * 0.2, 62.0, 0), Vector3(s * 1.7, 66.0, 0), 0.3, 0.3)
		lm.beam("Gold", Vector3(s * 1.7, 66.0, 0), Vector3(s * 1.5, 68.2, 0), 0.3, 0.3)
	lm.commit(model)

static func _arun_prang(lm: LandmarkMesh, base: Vector3, hw: float, tiers: int, tier_h: float,
		bud_h: float) -> void:
	for k in tiers:
		var w := hw * lerpf(1.0, 0.24, pow(float(k) / tiers, 0.9))
		var y := tier_h * float(k)
		lm.box("Teal", base + Vector3(0, y + 0.3, 0), Vector3(w * 2.15, 0.6, w * 2.15))
		lm.spire("White" if k % 2 == 0 else "Tile", base + Vector3(0, y + 0.6, 0), w * 0.98,
			tier_h - 0.6, w * 0.84)
		if k < 3:
			# Mondop niches on the faces of the lowest tiers.
			for side in 4:
				var b := Basis(Vector3.UP, PI * 0.5 * float(side))
				lm.box("White", base + b * Vector3(0, y + tier_h * 0.45, w * 0.9),
					Vector3(w * 0.4, tier_h * 0.55, w * 0.4), b)
				lm.spire("Teal", base + b * Vector3(0, y + tier_h * 0.72, w * 0.9), w * 0.2,
					tier_h * 0.3, 0.0)
	var top := tier_h * float(tiers)
	lm.lathe("White", base + Vector3(0, top, 0), PackedVector2Array([Vector2(hw * 0.26, 0),
		Vector2(hw * 0.28, bud_h * 0.3), Vector2(hw * 0.2, bud_h * 0.65), Vector2(hw * 0.08, bud_h * 0.9),
		Vector2(0.0, bud_h)]), 8)
	if hw < 8.0:
		U.finial(lm, "Gold", base + Vector3(0, top + bud_h * 0.9, 0), 4.0, 0.3)

## Shwedagon Pagoda (99.4 m): three octagonal terraces under the gilded
## bell, ringed turban, inverted bowl, lotus petals, banana bud, the
## tiered hti umbrella and the diamond bud; 8 medium and 56 small stupas.
static func shwedagon(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Gold", LandmarkMaterials.gold())
	lm.use("Base", LandmarkMaterials.pbr("limestone", "#D5C9AE", 3.0))
	lm.use("Red", LandmarkMaterials.pbr("terracotta", "#A5502F", 3.0))
	for k in 3:
		lm.frustum("Base", Vector3(0, -1.0 + 5.5 * float(k), 0), 72.0 - 7.0 * float(k),
			70.0 - 7.0 * float(k), 6.5, 8, PI / 8.0)
	lm.frustum("Red", Vector3(0, 15.0, 0), 59.0, 58.0, 2.0, 8, PI / 8.0)
	var bell := PackedVector2Array([Vector2(33.0, 17.0), Vector2(32.5, 20.0), Vector2(29.0, 27.0),
		Vector2(23.0, 36.0), Vector2(18.5, 44.0), Vector2(16.2, 50.0)])
	lm.lathe("Gold", Vector3.ZERO, bell, 40)
	# Turban rings, then bowl, lotus petals and banana bud.
	var y := 50.0
	for r in [17.2, 15.6, 14.4, 13.2]:
		lm.frustum("Gold", Vector3(0, y, 0), r, r - 0.5, 1.6, 40)
		y += 1.7
	lm.lathe("Gold", Vector3(0, y, 0), PackedVector2Array([Vector2(12.0, 0), Vector2(14.0, 2.0),
		Vector2(13.4, 5.0), Vector2(11.0, 8.0), Vector2(8.6, 9.6)]), 32)
	y += 9.6
	lm.lathe("Gold", Vector3(0, y, 0), PackedVector2Array([Vector2(8.6, 0), Vector2(10.4, 0.8),
		Vector2(10.0, 2.2), Vector2(6.8, 3.4)]), 32)
	y += 3.4
	lm.lathe("Gold", Vector3(0, y, 0), PackedVector2Array([Vector2(6.0, 0), Vector2(6.4, 3.0),
		Vector2(5.4, 8.0), Vector2(3.0, 11.0), Vector2(1.4, 12.6)]), 24)
	y += 12.6
	# Hti: five bell-shaped umbrella rings, vane and the diamond bud (99.4 m).
	for k in 5:
		var r := 4.0 - 0.55 * float(k)
		lm.lathe("Gold", Vector3(0, y + 1.9 * float(k), 0), PackedVector2Array([Vector2(r * 0.8, 0),
			Vector2(r, 0.5), Vector2(r * 0.8, 1.4), Vector2(r * 0.5, 2.0)]), 16)
	y += 9.6
	lm.frustum("Gold", Vector3(0, y, 0), 1.6, 0.6, 3.1, 12)
	y += 3.1
	lm.lathe("Gold", Vector3(0, y, 0), PackedVector2Array([Vector2(0.5, 0), Vector2(1.4, 1.0),
		Vector2(1.5, 1.6), Vector2(0.9, 2.9), Vector2(0.0, 99.4 - y)]), 12)
	# Subsidiary stupas on the upper terrace.
	for i in 64:
		var a := TAU * float(i) / 64.0
		var big := i % 8 == 0
		var rr := 53.0 if big else 47.0
		_stupa(lm, Vector3(cos(a) * rr, 17.0, sin(a) * rr), 3.4 if big else 1.4, 14.0 if big else 6.0)
	lm.commit(model)

static func _stupa(lm: LandmarkMesh, base: Vector3, r: float, h: float) -> void:
	lm.lathe("Gold", base, PackedVector2Array([Vector2(r, 0), Vector2(r * 1.05, h * 0.2),
		Vector2(r * 0.75, h * 0.5), Vector2(r * 0.4, h * 0.65), Vector2(r * 0.3, h * 0.8),
		Vector2(0.0, h)]), 10)

## Borobudur (35 m): the Buddhist mandala of five square, niched terraces
## climbing by stairs on four sides, three round platforms carrying 72
## perforated stupas and the bell of the main stupa.
static func borobudur(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#706B62", 3.0))
	lm.use("Dark", LandmarkMaterials.pbr("stone", "#5A554D", 3.0))
	lm.use("Niche", LandmarkMaterials.pbr("concrete", "#2E2A25", 2.0))
	lm.box("Dark", Vector3(0, 0.75, 0), Vector3(123.0, 5.5, 123.0))
	var y := 3.5
	for k in 5:
		var hw := 55.0 - 6.5 * float(k)
		lm.box("Stone", Vector3(0, (y + 3.4 - 3.0) * 0.5, 0), Vector3(hw * 2.0, y + 3.4 + 3.0, hw * 2.0))
		U.niche_rows(lm, "Niche", Vector3.ZERO, hw, y + 1.7, Vector3(1.4, 1.6, 0.4), 12 - k)
		lm.box("Dark", Vector3(0, y + 3.4, 0), Vector3(hw * 2.0 + 1.0, 0.4, hw * 2.0 + 1.0))
		y += 3.4
	var ang := atan2(17.0, 32.5)
	for side in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * float(side))
		lm.box("Dark", b * Vector3(0, 12.1, 45.25), Vector3(7.0, 0.8, 32.5 / cos(ang)),
			b * Basis(Vector3.RIGHT, ang))
	for p in [[26.0, 2.6], [20.5, 2.6], [15.0, 2.6]]:
		lm.frustum("Stone", Vector3(0, y, 0), float(p[0]), float(p[0]) - 0.6, float(p[1]), 32)
		var ring := float(p[0]) - 3.2
		var n := int(ring * 1.4)
		y += float(p[1])
		for i in n:
			var a := TAU * float(i) / n
			_stupa_bell(lm, Vector3(cos(a) * ring, y, sin(a) * ring))
	lm.lathe("Stone", Vector3(0, y, 0), PackedVector2Array([Vector2(7.0, 0), Vector2(7.2, 1.5),
		Vector2(6.2, 3.5), Vector2(3.5, 5.2), Vector2(1.2, 5.8), Vector2(0.0, 6.7)]), 28)
	lm.commit(model)

static func _stupa_bell(lm: LandmarkMesh, base: Vector3) -> void:
	lm.lathe("Stone", base, PackedVector2Array([Vector2(1.7, 0), Vector2(1.7, 0.5), Vector2(1.3, 2.0),
		Vector2(0.5, 3.0), Vector2(0.0, 3.4)]), 10)
