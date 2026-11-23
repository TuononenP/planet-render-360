class_name LandmarkBkWatArun
extends RefCounted

## Wat Arun Ratchawararam (วัดอรุณราชวราราม / Temple of Dawn) — Bangkok BK-4.3
## Site: OSM way 23482275 & 1020893594, centroid 13.7437, 100.4889 (`skyline_priority: 2`).
## Spec (Rama II–III Khmer-revival riverside prang complex, Fine Arts Dept / Commons refs):
##   - Total height: 70.0 m to tip of Indra's 7-pronged golden Vajra trident (published figures
##     range from 67 m to 82 m; registry pinned at 70.0 m per Fine Arts Dept / UNESCO dossier).
##   - Three diminishing redented white porcelain-plaster terraces (`hw = 35, 28.5, 22 m`) inlaid
##     with speckled Chinese porcelain floral bands (celadon jade, muted coral-terracotta, gold),
##     steep axial staircases with Naga balustrades on all 4 sides, and terrace parapets.
##   - Central Prang (`Phra Prang Yai`, 12.0..62.0 m body + 8.0 m golden Vajra = 70.0 m):
##     22 finely stepped redented porcelain tiers, Yaksha & Monkey caryatid friezes supporting
##     the lower mouldings, 4 cardinal Indra-on-three-headed-Erawan niches, antefix lotus petals,
##     and ribbed `naphalai` crown bud.
##   - Four 31 m corner satellite prangs (`Phra Prang Noi`) + four cardinal `K2.mondop` shrines
##     with stepped green-and-orange roofs.
##   - Crowned riverside gateway (`Su้มประตูยอดมงกุฎ`) flanked by the two famous 6 m guardian
##     Yaksha (`Thotsakan` white & `Sahatsadecha` green) + riverside terrace balustrade & floodlights.

const U = preload("res://scripts/generation/landmarks/asia_south/landmark_asia_south_util.gd")
const K = preload("res://scripts/generation/landmarks/mainland_se_asia/landmark_mse_kit.gd")
const K2 = preload("res://scripts/generation/landmarks/mainland_se_asia/landmark_mse_kit2.gd")

const HEIGHT_M := 70.0

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Porcelain", LandmarkMaterials.pbr("render", "#F1EDE3", 3.2))
	lm.use("Mosaic", LandmarkMaterials.pbr("limestone", "#DFD7C8", 4.5))
	lm.use("Celadon", LandmarkMaterials.pbr("slate", "#567B6A", 2.5))
	lm.use("Coral", LandmarkMaterials.pbr("terracotta", "#A85E4C", 2.5))
	lm.use("Orange", LandmarkMaterials.pbr("terracotta", "#C95222", 2.0))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#322D28", 2.0))

	_riverside_terrace_and_gate(lm)
	_three_redent_terraces(lm)
	_corner_prangs_and_mondops(lm)
	_central_prang(lm, Vector3(0, 12.0, 0), 13.4, 50.2)
	_vajra_crown(lm, 62.2)
	lm.commit(model)

	# Warm golden floodlights illuminating Wat Arun's white porcelain prang & satellite prangs by night
	var spots: Array = []
	for i in 4:
		var a := PI * 0.25 + PI * 0.5 * float(i)
		var dir := Vector3(cos(a), 0, sin(a))
		spots.append([dir * 38.0 + Vector3(0, 5.0, 0), Vector3(0, 36.0, 0),
			50.0, 1.55, 68.0, Color(1.0, 0.84, 0.44)])
		var ca := PI * 0.5 * float(i)
		var cdir := Vector3(cos(ca), 0, sin(ca))
		spots.append([cdir * 42.0 + Vector3(0, 2.0, 0), cdir * 18.0 + Vector3(0, 22.0, 0),
			48.0, 1.15, 48.0, Color(1.0, 0.88, 0.56)])
	model.set_meta(LandmarkLights.FLOOD_META, spots)

static func _riverside_terrace_and_gate(lm: LandmarkMesh) -> void:
	# Broad stone & porcelain compound terrace (`82 x 86 m`) with riverside balustrade on +X/+Z
	lm.box("Mosaic", Vector3(0, 0.35, -2.0), Vector3(80.0, 0.7, 84.0))
	# Crowned spire gateway (`Phraeng Phichai`) on -Z side guarded by Thotsakan (white) & Sahatsadecha (green)
	var gc := Vector3(0, 0.7, -41.5)
	lm.box("Porcelain", gc + Vector3(0, 2.8, 0), Vector3(8.6, 5.6, 3.6))
	lm.box("Shadow", gc + Vector3(0, 2.1, 0), Vector3(2.8, 4.2, 3.8), Basis(), 0.0)
	K.thai_roof(lm, "Orange", "Celadon", "Gold", "Porcelain", gc + Vector3(0, 5.6, 0),
		Basis(Vector3.UP, PI * 0.5), 4.4, 9.8, 2.4, 0.7, 1, 0, 1.1)
	lm.lathe("Gold", gc + Vector3(0, 8.0, 0), PackedVector2Array([
		Vector2(1.4, 0.0), Vector2(1.1, 1.6), Vector2(0.7, 3.2), Vector2(0.25, 4.8), Vector2(0.0, 6.2)]), 10)
	K2.yaksha(lm, "Porcelain", "Mosaic", "Gold", gc + Vector3(-5.8, 0.0, -2.6), Basis(Vector3.UP, PI), 6.0)
	K2.yaksha(lm, "Celadon", "Mosaic", "Gold", gc + Vector3(5.8, 0.0, -2.6), Basis(Vector3.UP, PI), 6.0)

static func _three_redent_terraces(lm: LandmarkMesh) -> void:
	for k in 3:
		var hw := 35.0 - 6.4 * float(k)
		var plan := U.redent(hw, 2.4, 4)
		var y0 := 0.7 + 3.76 * float(k)
		var th := 3.76
		U.plan_frustum(lm, "Porcelain", Vector3.ZERO, plan, 1.0, 0.99, y0, y0 + th * 0.76)
		U.plan_frustum(lm, "Mosaic", Vector3.ZERO, plan, 1.005, 1.005, y0 + th * 0.76, y0 + th * 0.90)
		U.plan_frustum(lm, "Celadon" if k % 2 == 0 else "Coral", Vector3.ZERO, plan, 1.01, 1.0, y0 + th * 0.90, y0 + th)
		for side in 4:
			var b := Basis(Vector3.UP, PI * 0.5 * float(side))
			for sx in [-1.0, 1.0]:
				_parapet(lm, b * Vector3(float(sx) * 3.2, y0 + th, hw - 0.6),
					b * Vector3(float(sx) * (hw - 8.2), y0 + th, hw - 0.6))
			_steep_stair(lm, b * Vector3(0, y0, hw + 1.8), b, th, 3.8, 3.4)

static func _corner_prangs_and_mondops(lm: LandmarkMesh) -> void:
	# Four cardinal mondops on the upper terrace (y = 12.0 m) with stepped Thai roofs & spires
	var mk := {"wall": "Porcelain", "stone": "Mosaic", "tile": "Orange", "border": "Celadon", "gold": "Gold", "dark": "Shadow"}
	for side in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * float(side))
		K2.mondop(lm, mk, b * Vector3(0, 12.0, 18.8), b, 5.2, 4.2, 10.4, 5)
	# Four corner satellite prangs (`Phra Prang Noi`, 31 m top) built once & merged at the 4 corners
	var sat := LandmarkMesh.new()
	for k in ["Porcelain", "Mosaic", "Celadon", "Coral", "Gold", "Shadow"]:
		sat.use(k, LandmarkMaterials.gold())
	_prang_body(sat, Vector3.ZERO, 3.4, 26.5, 12)
	sat.beam("Gold", Vector3(0, 26.2, 0), Vector3(0, 29.0, 0), 0.18, 0.18)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			lm.merge(sat, Transform3D(Basis(), Vector3(float(sx) * 31.8, 4.46, float(sz) * 31.8)))

static func _central_prang(lm: LandmarkMesh, base: Vector3, hw: float, h: float) -> void:
	_prang_body(lm, base, hw, h, 22)

static func _prang_body(lm: LandmarkMesh, base: Vector3, hw: float, h: float, bands: int) -> void:
	var plan := U.redent(hw, hw * 0.11, 4)
	var bh := h * 0.83 / float(bands)
	var y := 0.0
	for k in bands:
		var t0 := float(k) / float(bands)
		var t1 := float(k + 1) / float(bands)
		var s0 := 1.0 - 0.79 * pow(t0, 0.76)
		var s1 := 1.0 - 0.79 * pow(t1, 0.76)
		var body_key := "Porcelain" if k % 2 == 0 else "Mosaic"
		var trim_key := "Celadon" if k % 3 == 0 else ("Coral" if k % 3 == 1 else "Gold")
		U.plan_frustum(lm, body_key, base, plan, s0, s1 * 1.015, y, y + bh * 0.80)
		U.plan_frustum(lm, trim_key, base, plan, s1 * 1.06, s1 * 1.01, y + bh * 0.80, y + bh)
		# Corner antefix lotus petals on lower & middle tiers
		if k < int(bands * 0.55) and k % 2 == 0:
			for q in U.convex_corners(plan):
				var cp := base + Vector3(q.x * s1 * 1.05, y + bh, q.y * s1 * 1.05)
				lm.lathe("Porcelain", cp, PackedVector2Array([
					Vector2(hw * 0.036, 0.0), Vector2(hw * 0.026, bh * 0.55), Vector2(0.0, bh * 0.95)]),
					4, 1.0, 1.0, PI / 4.0, false)
		# Demon & monkey caryatid friezes supporting tiers 2 and 5
		if bands >= 18 and (k == 2 or k == 5):
			var nper := int(hw * 1.1)
			var c_key := "Gold" if k == 5 else "Mosaic"
			for side in 4:
				var b := Basis(Vector3.UP, PI * 0.5 * float(side))
				for i in nper:
					var x := (-0.78 + 1.56 * (float(i) + 0.5) / float(nper)) * hw * s1
					var fp := base + b * Vector3(x, y + bh * 0.12, hw * s1 + 0.12)
					lm.box(c_key, fp + Vector3(0, bh * 0.34, 0), Vector3(hw * 0.042, bh * 0.65, hw * 0.04), b)
		# Four cardinal Indra-on-Erawan niches halfway up the central prang
		if bands >= 18 and k == 8:
			for side in 4:
				var b := Basis(Vector3.UP, PI * 0.5 * float(side))
				var np := base + b * Vector3(0, y, hw * s0)
				U.niche(lm, "Porcelain", "Shadow", np, b, hw * 0.46, bh * 2.4,
					hw * 0.28, 0.0, bh * 1.5, hw * 0.11, 0.22, 6)
				# Gilded Indra on three-headed Erawan elephant + flame pediment
				lm.box("Porcelain", np + b * Vector3(0, bh * 0.45, 0.16), Vector3(hw * 0.18, bh * 0.8, hw * 0.08), b)
				lm.box("Gold", np + b * Vector3(0, bh * 1.15, 0.18), Vector3(hw * 0.10, bh * 0.7, hw * 0.07), b)
				K.outline_prism(lm, "Gold", np + b * Vector3(0, bh * 2.15, 0.20), b,
					K.flame_outline(hw * 0.48, bh * 1.1), 0.14)
		y += bh

	# Ribbed Naphalai lotus crown bud
	var r := hw * 0.21
	lm.lathe("Porcelain", base + Vector3(0, y, 0), PackedVector2Array([
		Vector2(r, 0.0), Vector2(r * 1.14, h * 0.04), Vector2(r * 0.94, h * 0.09),
		Vector2(r * 0.52, h * 0.14), Vector2(r * 0.14, h * 0.165), Vector2(0.0, h - y)]), 14)
	for i in 8:
		var a := TAU * float(i) / 8.0
		var d := Vector3(cos(a), 0, sin(a))
		lm.beam("Gold", base + Vector3(0, y + h * 0.01, 0) + d * r * 1.03,
			base + Vector3(0, y + h * 0.12, 0) + d * r * 0.62, hw * 0.025, hw * 0.025)

static func _vajra_crown(lm: LandmarkMesh, y0: float) -> void:
	# Seven-pronged golden Vajra (Indra's trident) rising cleanly from y0 = 62.2 m to HEIGHT_M = 70.0 m
	lm.frustum("Gold", Vector3(0, y0, 0), 0.75, 0.52, 1.1, 10)
	lm.beam("Gold", Vector3(0, y0 + 1.0, 0), Vector3(0, HEIGHT_M, 0), 0.36, 0.36)
	for k in 3:
		var a := PI * float(k) / 3.0
		var d := Vector3(cos(a), 0, sin(a))
		for s in [-1.0, 1.0]:
			var dir := d * float(s)
			lm.beam("Gold", Vector3(0, y0 + 2.0, 0) + dir * 0.2, Vector3(0, y0 + 4.4, 0) + dir * 1.45, 0.20, 0.20)
			lm.beam("Gold", Vector3(0, y0 + 4.4, 0) + dir * 1.45, Vector3(0, HEIGHT_M - 1.2, 0) + dir * 1.22, 0.18, 0.18)

static func _parapet(lm: LandmarkMesh, a: Vector3, b: Vector3) -> void:
	var dir := (b - a).normalized()
	var basis := Basis(dir, Vector3.UP, dir.cross(Vector3.UP).normalized())
	var dl := a.distance_to(b)
	var mid := (a + b) * 0.5
	lm.box("Porcelain", mid + Vector3(0, 0.42, 0), Vector3(dl, 0.84, 0.35), basis)
	lm.box("Celadon", mid + Vector3(0, 0.88, 0), Vector3(dl, 0.12, 0.48), basis, 0.0)
	var n := maxi(int(dl / 2.4), 1)
	for i in n + 1:
		var p := a.lerp(b, float(i) / float(n))
		lm.box("Porcelain", p + Vector3(0, 0.56, 0), Vector3(0.42, 1.12, 0.48), basis, 0.0)
		lm.spire("Gold", p + Vector3(0, 1.12, 0), 0.18, 0.32, 0.0, 4)

static func _steep_stair(lm: LandmarkMesh, p: Vector3, b: Basis, rise: float, w: float, run: float) -> void:
	var n := int(rise / 0.28)
	for i in n:
		var t := float(i) / float(n)
		lm.box("Mosaic", p + b * Vector3(0, rise * t + rise / float(n) * 0.5, run * (0.5 - t) - run / float(n) * 0.5),
			Vector3(w, rise / float(n), run / float(n)), b, 0.0)
	for sx in [-1.0, 1.0]:
		var s := float(sx)
		K2.naga_rail(lm, "Porcelain", "Gold",
			p + b * Vector3(s * (w * 0.5 + 0.22), rise, -run * 0.5),
			p + b * Vector3(s * (w * 0.5 + 0.22), 0.0, run * 0.5), 0.82)
