class_name LandmarkSeaTemples
extends RefCounted

## South-east Asian temple-mountains in true metres: Angkor Wat and Wat
## Arun. The Shwedagon Pagoda and Borobudur are in LandmarkSeaStupas.

const U = preload("res://scripts/generation/landmarks/asia_south/landmark_asia_south_util.gd")

## Angkor Wat (65 m): three nested galleries stepping up to the quincunx.
## The outer gallery (215 m E-W x 187 m N-S, X is east) on its laterite
## terrace: a relief wall under a vaulted roof and the outer half-gallery
## of square pillars under a lean-to, corner pavilions and the western
## gopura with its three towers. The cruciform cloister (Preah Poan)
## links it to the second enclosure (115 x 100 m, 8.5 m up) whose wall
## has balustered windows and corner towers. The Bakan (60 m square)
## rises 13.5 m in three tiers with steep axial stairs to the upper
## gallery, four corner towers, cross galleries and the central
## lotus-bud tower 43 m above the upper level, 65 m above the ground.
## The sandstone is the weathered grey of the real temple (lichen-dark,
## not buff), laterite only on the terrace's flanks; the precinct round
## it (wall, gopura, causeway, avenue, libraries) is
## LandmarkAngkorWatPrecinct.
static func angkor_wat(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Sand", LandmarkMaterials.pbr("stone", LandmarkAngParts.STONE_GREY, 3.0))
	lm.use("Laterite", LandmarkMaterials.pbr("stone", LandmarkAngParts.LATERITE, 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("slate", LandmarkAngParts.ROOF, 3.0))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#3E3A33", 2.0))
	lm.use("Flag", LandmarkMaterials.pbr("stone", LandmarkAngParts.FLAGSTONE, 4.0))
	# Outer terrace (laterite flanks, worn sandstone flags) and gallery (floor 2 m).
	lm.box("Laterite", Vector3(0, 0.94, 0), Vector3(221.0, 1.88, 193.0))
	lm.box("Flag", Vector3(0, 1.94, 0), Vector3(221.4, 0.12, 193.4), Basis(), 0.0)
	_gallery(lm, Vector3(0, 2.0, 0), 107.5, 93.5, 4.6, true)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_pavilion(lm, Vector3(sx * 105.0, 2.0, sz * 91.0), 6.0, 13.0)
	# Gopuras mid-side; the western one carries three towers.
	for k in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * float(k))
		var p := b * Vector3(0, 2.0, 93.5) if k % 2 == 0 else b * Vector3(0, 2.0, 107.5)
		_pavilion(lm, p, 8.0, 12.0)
	for z in [-24.0, 0.0, 24.0]:
		_prang(lm, Vector3(-107.5, 2.0, z), 4.0 if z == 0.0 else 3.2, 22.0 if z == 0.0 else 16.0)
	# Second level: platform with stairs, and the cruciform cloister west of it.
	var c2 := Vector3(12.0, 0, 0)
	lm.box("Sand", c2 + Vector3(0, 5.25, 0), Vector3(117.0, 6.5, 102.0))
	lm.box("Sand", c2 + Vector3(0, 8.3, 0), Vector3(118.0, 0.4, 103.0))
	_cloister(lm, Vector3(-62.0, 2.0, 0))
	_gallery(lm, c2 + Vector3(0, 8.5, 0), 57.5, 50.0, 4.2, false)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_prang(lm, c2 + Vector3(sx * 55.0, 8.5, sz * 47.5), 4.2, 22.0)
	# Bakan: three steep tiers to the upper court at 22 m, axial stairs.
	var c3 := c2
	var tiers := [[34.0, 8.5, 13.0], [32.0, 13.0, 17.5], [30.5, 17.5, 22.0]]
	for t in tiers:
		var hw: float = t[0]
		var plan := U.redent(hw, 2.0, 2)
		U.plan_frustum(lm, "Sand", c3, plan, 1.0, 1.0, float(t[1]), float(t[2]) - 0.5)
		U.plan_frustum(lm, "Sand", c3, plan, 1.02, 1.02, float(t[2]) - 0.5, float(t[2]))
	for k in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * float(k))
		for off in ([-20.0, 0.0, 20.0] if k % 2 == 1 else [0.0]):
			_stair(lm, c3 + b * Vector3(off, 8.5, 34.0), b, 13.5, 4.0, 9.0)
	_gallery(lm, c3 + Vector3(0, 22.0, 0), 30.0, 30.0, 3.6, false)
	# Cross galleries from the central sanctuary to the mid-sides.
	for k in 2:
		var b := Basis(Vector3.UP, PI * 0.5 * float(k))
		lm.box("Sand", c3 + Vector3(0, 24.0, 0), Vector3(56.0, 4.0, 3.6), b)
		lm.gable("Roof", c3 + Vector3(0, 26.0, 0), 3.6, 56.0, 2.2, b * Basis(Vector3.UP, PI * 0.5), 0.4, "Sand")
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_prang(lm, c3 + Vector3(sx * 28.0, 22.0, sz * 28.0), 5.0, 31.0)
	_prang(lm, c3 + Vector3(0, 22.0, 0), 7.5, 43.0)
	LandmarkAngkorWatPrecinct.build(lm)
	lm.commit(model)

## Covered gallery ring round `c` (half extents hx, hz): the relief wall
## with its vaulted roof, and either the outer pillared half-gallery
## under a lean-to (`pillars`) or a wall with balustered windows.
static func _gallery(lm: LandmarkMesh, c: Vector3, hx: float, hz: float, wall_h: float, pillars: bool) -> void:
	for k in 4:
		var along_x := k % 2 == 0
		var s := -1.0 if k < 2 else 1.0
		var run := hx * 2.0 if along_x else hz * 2.0
		var b := Basis(Vector3.UP, 0.0 if along_x else PI * 0.5)
		var out := Vector3(0, 0, s) if along_x else Vector3(s, 0, 0)
		var edge: float = hz if along_x else hx
		var wall_c := c + out * (edge - 3.2)
		# Inner relief wall and outer wall (windows) under a vaulted roof.
		lm.box("Sand", wall_c - out * 1.2 + Vector3(0, wall_h * 0.5, 0), Vector3(run - 4.0, wall_h, 0.9), b)
		lm.box("Sand", wall_c + out * 1.2 + Vector3(0, wall_h * 0.5, 0), Vector3(run - 4.0, wall_h, 0.9), b)
		lm.box("Sand", wall_c + Vector3(0, wall_h + 0.2, 0), Vector3(run - 3.0, 0.4, 3.6), b)
		lm.gable("Roof", wall_c + Vector3(0, wall_h + 0.4, 0), 3.4, run - 3.0, 2.0,
			b * Basis(Vector3.UP, PI * 0.5), 0.3, "Sand")
		# Roof ridge cresting.
		lm.box("Sand", wall_c + Vector3(0, wall_h + 2.45, 0), Vector3(run - 3.0, 0.25, 0.3), b, 0.0)
		var n := int((run - 8.0) / 3.4)
		for i in n:
			var t := -0.5 + (float(i) + 0.5) / float(n)
			var along := (Vector3(1, 0, 0) if along_x else Vector3(0, 0, 1)) * t * (run - 8.0)
			if pillars:
				# Square pillar with a capital under the lean-to.
				var pp := c + along + out * (edge + 0.2)
				lm.box("Sand", pp + Vector3(0, wall_h * 0.45, 0), Vector3(0.7, wall_h * 0.9, 0.7), b)
				lm.box("Sand", pp + Vector3(0, wall_h * 0.93, 0), Vector3(1.0, 0.3, 1.0), b, 0.0)
			else:
				# Window with five turned balusters in the outer wall.
				var wp := wall_c + out * 1.66 + along + Vector3(0, wall_h * 0.5, 0)
				lm.box("Shadow", wp - out * 0.02, Vector3(1.8, 1.8, 0.04), b, 0.0)
				for j in 5:
					var lat := (Vector3(1, 0, 0) if along_x else Vector3(0, 0, 1)) * (-0.72 + 0.36 * float(j))
					lm.lathe("Sand", wp + lat - Vector3(0, 0.9, 0), PackedVector2Array([Vector2(0.09, 0),
						Vector2(0.14, 0.45), Vector2(0.08, 0.9), Vector2(0.14, 1.35), Vector2(0.09, 1.8)]), 5,
						1.0, 1.0, 0.0, true, false)
				lm.box("Sand", wp + out * 0.1 - Vector3(0, 1.0, 0), Vector3(2.2, 0.2, 0.3), b, 0.0)
				lm.box("Sand", wp + out * 0.1 + Vector3(0, 1.0, 0), Vector3(2.2, 0.2, 0.3), b, 0.0)
		if pillars:
			# Lean-to over the half-gallery, beam on the pillar heads.
			lm.box("Sand", c + out * (edge + 0.2) + Vector3(0, wall_h * 1.02, 0), Vector3(run, 0.4, 0.9), b)
			var lo := c + out * (edge + 0.9) + Vector3(0, wall_h * 1.05, 0)
			var hi := wall_c + out * 1.6 + Vector3(0, wall_h + 0.9, 0)
			var side_v := Vector3(1, 0, 0) if along_x else Vector3(0, 0, 1)
			lm.quad("Roof", lo - side_v * run * 0.5, lo + side_v * run * 0.5, hi + side_v * run * 0.5,
				hi - side_v * run * 0.5, (out + Vector3.UP * 1.5).normalized())

## Cruciform pavilion (corner pavilion or gopura): crossing gabled roofs
## over a square hall w wide, a small tower on the crossing.
static func _pavilion(lm: LandmarkMesh, p: Vector3, w: float, span_l: float) -> void:
	for k in 2:
		var b := Basis(Vector3.UP, PI * 0.5 * float(k))
		lm.box("Sand", p + Vector3(0, 2.6, 0), Vector3(span_l, 5.2, w), b)
		lm.gable("Roof", p + Vector3(0, 5.2, 0), w, span_l, 2.6, b * Basis(Vector3.UP, PI * 0.5), 0.4, "Sand")
		lm.gable("Roof", p + Vector3(0, 7.9, 0), w * 0.7, span_l * 0.7, 1.8, b * Basis(Vector3.UP, PI * 0.5), 0.3, "Sand")
	U.plan_frustum(lm, "Sand", p, U.redent(w * 0.4, w * 0.06, 2), 1.0, 0.7, 7.0, 10.5)
	lm.lathe("Roof", p + Vector3(0, 10.5, 0), PackedVector2Array([Vector2(w * 0.25, 0), Vector2(w * 0.24, 1.2),
		Vector2(w * 0.12, 2.6), Vector2(0.0, 3.4)]), 12)

## Preah Poan: two crossing galleries with pillared aisles enclosing the
## four basins, the western stair down to the outer gallery.
static func _cloister(lm: LandmarkMesh, p: Vector3) -> void:
	for k in 2:
		var b := Basis(Vector3.UP, PI * 0.5 * float(k))
		var l := 40.0 if k == 0 else 70.0
		lm.box("Sand", p + Vector3(0, 0.3, 0), Vector3(l, 0.6, 6.0), b)
		for s in [-1.0, 1.0]:
			for i in int(l / 3.0):
				var x := -l * 0.5 + 1.5 + 3.0 * float(i)
				lm.box("Sand", p + b * Vector3(x, 2.6, s * 2.4), Vector3(0.6, 4.0, 0.6), b)
		lm.box("Sand", p + Vector3(0, 4.8, 0), Vector3(l, 0.4, 6.0), b)
		lm.gable("Roof", p + Vector3(0, 5.0, 0), 6.0, l, 2.4, b * Basis(Vector3.UP, PI * 0.5), 0.4, "Sand")
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			lm.box("Shadow", p + Vector3(sx * 11.0, 0.05, sz * 18.0), Vector3(14.0, 0.1, 28.0), Basis(), 0.0)

## Steep axial stair from `p` (foot, on the face) climbing `rise` over
## `run` back into the mass along -basis Z, w wide, with side walls.
static func _stair(lm: LandmarkMesh, p: Vector3, b: Basis, rise: float, w: float, run: float) -> void:
	var n := int(rise / 0.45)
	for i in n:
		var t := float(i) / float(n)
		lm.box("Sand", p + b * Vector3(0, rise * t + rise / n * 0.5, run * (1.0 - t) - run * 0.5),
			Vector3(w, rise / n, run / n), b, 0.0)
	for sx in [-1.0, 1.0]:
		lm.beam("Sand", p + b * Vector3(sx * (w * 0.5 + 0.3), 0.5, run * 0.5),
			p + b * Vector3(sx * (w * 0.5 + 0.3), rise + 0.5, -run * 0.5), 0.6, 1.0, b * Vector3.RIGHT)

## Khmer tower of total height h on a redented plan hw wide: sanctuary
## with porches and pediments, five diminishing tiers each with an
## antefix on every outer corner, the lotus-bud crown and finial.
static func _prang(lm: LandmarkMesh, base: Vector3, hw: float, h: float) -> void:
	var plan := U.redent(hw, hw * 0.13, 2)
	var body := h * 0.3
	U.plan_frustum(lm, "Sand", base, plan, 1.06, 1.06, 0.0, h * 0.03)
	U.plan_frustum(lm, "Sand", base, plan, 1.0, 0.97, h * 0.03, body)
	U.plan_frustum(lm, "Sand", base, plan, 1.04, 1.04, body, body + h * 0.02)
	for k in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * float(k))
		var pc := base + b * Vector3(0, 0, hw * 0.95)
		lm.box("Sand", pc + Vector3(0, body * 0.42, 0), Vector3(hw * 0.7, body * 0.84, hw * 0.5), b)
		lm.box("Shadow", pc + b * Vector3(0, body * 0.32, hw * 0.26), Vector3(hw * 0.3, body * 0.6, 0.04), b, 0.0)
		lm.gable("Roof", pc + Vector3(0, body * 0.84, 0), hw * 0.7, hw * 0.5, hw * 0.35, b, 0.15, "Sand")
	var y := body + h * 0.02
	var s := 0.86
	for k in 5:
		var th := h * 0.085
		var s1 := s * 0.9
		U.plan_frustum(lm, "Sand", base, plan, s, s1, y, y + th)
		U.plan_frustum(lm, "Roof", base, plan, s1 * 1.08, s1 * 1.0, y + th, y + th + h * 0.012)
		for q in U.convex_corners(plan):
			var cp := base + Vector3(q.x * s1 * 1.05, y + th, q.y * s1 * 1.05)
			lm.lathe("Sand", cp, PackedVector2Array([Vector2(hw * 0.06, 0), Vector2(hw * 0.05, th * 0.4),
				Vector2(0.0, th * 0.75)]), 4, 1.0, 1.0, PI / 4.0, false)
		y += th + h * 0.012
		s = s1 * 0.86
	lm.lathe("Roof", base + Vector3(0, y, 0), PackedVector2Array([Vector2(hw * s, 0),
		Vector2(hw * s * 1.08, h * 0.03), Vector2(hw * s * 0.92, h * 0.07), Vector2(hw * s * 0.5, h * 0.1),
		Vector2(0.0, h * 0.12)]), 12)
	U.finial(lm, "Sand", base + Vector3(0, y + h * 0.11, 0), h - y - h * 0.11, maxf(hw * 0.07, 0.2))

## Wat Arun (70 m): the Khmer-style central prang of Rama II and III on
## three redented terraces with balustrades and steep stairs on the four
## axes, four mondops at the cardinal points of the base and four
## satellite prangs at the corners. The prang climbs in bands of cream
## plaster set with Chinese porcelain, ringed by the yaksha caryatid
## band, has niches with Indra on Erawan on the four faces, the
## naphalai bud and the seven-pronged trident (vajra) on top.
static func wat_arun(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("White", LandmarkMaterials.pbr("render", "#EDE7D6", 3.0))
	lm.use("Tile", LandmarkMaterials.pbr("terracotta", "#B98A58", 3.0))
	lm.use("Teal", LandmarkMaterials.pbr("render", "#4E8C86", 3.0))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#3F3A33", 2.0))
	for k in 3:
		var hw := 36.0 - 6.0 * float(k)
		var plan := U.redent(hw, 2.4, 3)
		var y0 := 4.0 * float(k)
		U.plan_frustum(lm, "White", Vector3.ZERO, plan, 1.0, 1.0, y0, y0 + 3.6)
		U.plan_frustum(lm, "Teal", Vector3.ZERO, plan, 1.01, 1.01, y0 + 3.6, y0 + 4.0)
		# Balustrade along the terrace edges (between the stairs).
		for side in 4:
			var b := Basis(Vector3.UP, PI * 0.5 * float(side))
			for sx in [-1.0, 1.0]:
				_parapet(lm, b * Vector3(sx * 3.0, y0 + 4.0, hw - 0.5), b * Vector3(sx * (hw - 8.0), y0 + 4.0, hw - 0.5))
			_steep_stair(lm, b * Vector3(0, y0, hw + 1.6), b, 4.0, 3.6, 3.4)
	# Mondops at the four cardinal points of the upper terrace.
	for side in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * float(side))
		_mondop(lm, b * Vector3(0, 12.0, 18.5), b)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_arun_prang(lm, Vector3(sx * 33.0, 4.0, sz * 33.0), 2.9, 28.0)
	_arun_prang(lm, Vector3(0, 12.0, 0), 13.0, 49.0)
	# Trident (Indra's vajra) on the central bud, to 70 m.
	var ty := 61.5
	lm.beam("Gold", Vector3(0, ty, 0), Vector3(0, 70.0, 0), 0.45, 0.45)
	for k in 3:
		var a := PI * float(k) / 3.0
		var d := Vector3(cos(a), 0, sin(a))
		for s in [-1.0, 1.0]:
			lm.beam("Gold", Vector3(0, 63.0, 0) + d * s * 0.2, Vector3(0, 66.0, 0) + d * s * 1.5, 0.25, 0.25)
			lm.beam("Gold", Vector3(0, 66.0, 0) + d * s * 1.5, Vector3(0, 68.4, 0) + d * s * 1.3, 0.25, 0.25)
	lm.frustum("Gold", Vector3(0, 62.6, 0), 0.6, 0.6, 0.5, 8)
	lm.commit(model)

## Thai terrace parapet along a-b: a low wall with a moulded coping,
## porcelain-set panels between square posts every 2 m.
static func _parapet(lm: LandmarkMesh, a: Vector3, b: Vector3) -> void:
	var dir := (b - a).normalized()
	var basis := Basis(dir, Vector3.UP, dir.cross(Vector3.UP).normalized())
	var dl := a.distance_to(b)
	var mid := (a + b) * 0.5
	lm.box("White", mid + Vector3(0, 0.4, 0), Vector3(dl, 0.8, 0.35), basis)
	lm.box("Teal", mid + Vector3(0, 0.86, 0), Vector3(dl, 0.12, 0.5), basis, 0.0)
	var n := maxi(int(dl / 2.0), 1)
	for i in n + 1:
		var p := a.lerp(b, float(i) / float(n))
		lm.box("White", p + Vector3(0, 0.55, 0), Vector3(0.45, 1.1, 0.5), basis, 0.0)
		lm.lathe("Tile", p + Vector3(0, 1.1, 0), PackedVector2Array([Vector2(0.2, 0), Vector2(0.0, 0.35)]), 4,
			1.0, 1.0, PI / 4.0, false)
		if i < n:
			lm.box("Tile", a.lerp(b, (float(i) + 0.5) / float(n)) + Vector3(0, 0.4, 0),
				Vector3(dl / float(n) * 0.6, 0.45, 0.4), basis, 0.0)

## Steep stair of `rise` up a terrace face, foot at p, w wide.
static func _steep_stair(lm: LandmarkMesh, p: Vector3, b: Basis, rise: float, w: float, run: float) -> void:
	var n := int(rise / 0.3)
	for i in n:
		var t := float(i) / float(n)
		lm.box("White", p + b * Vector3(0, rise * t + rise / n * 0.5, run * (0.5 - t) - run / n * 0.5),
			Vector3(w, rise / n, run / n), b, 0.0)
	for sx in [-1.0, 1.0]:
		lm.beam("Teal", p + b * Vector3(sx * (w * 0.5 + 0.2), 0.6, run * 0.5),
			p + b * Vector3(sx * (w * 0.5 + 0.2), rise + 0.6, -run * 0.5), 0.35, 0.5, b * Vector3.RIGHT)

## A mondop: a small square shrine with a dark doorway, a stack of
## diminishing roofs and a slim spire; at p facing basis +Z.
static func _mondop(lm: LandmarkMesh, p: Vector3, b: Basis) -> void:
	lm.box("White", p + Vector3(0, 2.0, 0), Vector3(4.6, 4.0, 4.6), b)
	U.niche(lm, "White", "Shadow", p + b * Vector3(0, 0, 2.3), b, 2.6, 3.6, 1.4, 0.0, 2.2, 1.0, 0.3, 6)
	var plan := U.redent(2.8, 0.35, 2)
	var y := 4.0
	var s := 1.0
	for k in 5:
		U.plan_frustum(lm, "Teal" if k % 2 == 0 else "Tile", p, plan, s, s * 0.82, y, y + 1.0)
		y += 1.0
		s *= 0.8
	lm.frustum("White", p + Vector3(0, y, 0), 0.6, 0.0, 3.0, 8)

## Thai prang of total height h (bud top), base half-width hw: a tall
## redented body of porcelain bands curving in, a yaksha caryatid ring,
## niches on the faces, antefix leaves on the lower tiers, and the
## naphalai bud.
static func _arun_prang(lm: LandmarkMesh, base: Vector3, hw: float, h: float) -> void:
	var plan := U.redent(hw, hw * 0.1, 3)
	var bands := 16
	var bh := h * 0.82 / float(bands)
	var y := 0.0
	for k in bands:
		var t0 := float(k) / float(bands)
		var t1 := float(k + 1) / float(bands)
		var s0 := 1.0 - 0.78 * pow(t0, 0.75)
		var s1 := 1.0 - 0.78 * pow(t1, 0.75)
		U.plan_frustum(lm, "White" if k % 2 == 0 else "Tile", base, plan, s0, s1 * 1.02, y, y + bh * 0.82)
		U.plan_frustum(lm, "Teal", base, plan, s1 * 1.08, s1 * 1.02, y + bh * 0.82, y + bh)
		if k < 6:
			for q in U.convex_corners(plan):
				var cp := base + Vector3(q.x * s1 * 1.06, y + bh, q.y * s1 * 1.06)
				lm.lathe("White", cp, PackedVector2Array([Vector2(hw * 0.04, 0), Vector2(hw * 0.03, bh * 0.5),
					Vector2(0.0, bh * 0.9)]), 4, 1.0, 1.0, PI / 4.0, false)
		if k == 2:
			# Yaksha caryatids holding up the band above.
			var nper := int(hw * 1.2)
			for side in 4:
				var b := Basis(Vector3.UP, PI * 0.5 * float(side))
				for i in nper:
					var x := (-0.8 + 1.6 * (float(i) + 0.5) / float(nper)) * hw * s1
					var fp := base + b * Vector3(x, y + bh * 0.1, hw * s1 * 1.0 + 0.1)
					lm.box("Tile", fp + Vector3(0, bh * 0.3, 0), Vector3(hw * 0.05, bh * 0.6, hw * 0.04), b)
					lm.box("White", fp + Vector3(0, bh * 0.68, 0), Vector3(hw * 0.035, hw * 0.035, hw * 0.035), b, 0.0)
		if k == 6:
			# Niches with Indra on Erawan on the four faces.
			for side in 4:
				var b := Basis(Vector3.UP, PI * 0.5 * float(side))
				U.niche(lm, "White", "Shadow", base + b * Vector3(0, y, hw * s0 * 1.0), b, hw * 0.5, bh * 1.6,
					hw * 0.3, 0.0, bh * 1.0, hw * 0.12, 0.2, 6)
				lm.box("White", base + b * Vector3(0, y + bh * 0.4, hw * s0 + 0.1), Vector3(hw * 0.18, bh * 0.8,
					hw * 0.06), b)
		y += bh
	# Naphalai bud: ribbed, to the top.
	var r := hw * 0.22
	lm.lathe("White", base + Vector3(0, y, 0), PackedVector2Array([Vector2(r, 0), Vector2(r * 1.15, h * 0.04),
		Vector2(r * 0.95, h * 0.09), Vector2(r * 0.5, h * 0.14), Vector2(r * 0.12, h * 0.17),
		Vector2(0.0, h - y)]), 12)
	for i in 8:
		var a := TAU * float(i) / 8.0
		var d := Vector3(cos(a), 0, sin(a))
		lm.beam("Teal", base + Vector3(0, y + h * 0.005, 0) + d * r * 1.02,
			base + Vector3(0, y + h * 0.04, 0) + d * r * 1.17, hw * 0.03, hw * 0.03)
		lm.beam("Teal", base + Vector3(0, y + h * 0.04, 0) + d * r * 1.17,
			base + Vector3(0, y + h * 0.12, 0) + d * r * 0.65, hw * 0.03, hw * 0.03)
