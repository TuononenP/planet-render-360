class_name LandmarkMseThai
extends RefCounted

## Thai temples in true metres: Wat Chaiwatthanaram (35 m: the ruined
## Khmer-style redented prang of Ayutthaya, 1630, with four corner
## prangs on its base, the eight meru chapels joined by the Phra
## Rabiang gallery and its seated Buddhas, and the ruined ordination
## hall east between two chedis of twelve indented corners) and Wat
## Rong Khun, the White Temple of Chiang Rai (30 m: the white ubosot with
## its mirror-glass trim and bristling layered roofs, the bridge over
## the lake past the field of reaching hands, the gate of heaven and
## the golden hall).

const U = preload("res://scripts/generation/landmarks/mainland_se_asia/landmark_mse_util.gd")
const K = preload("res://scripts/generation/landmarks/mainland_se_asia/landmark_mse_kit.gd")

const PRANG_M := 35.0
const WHITE_TEMPLE_M := 30.0

# --- Wat Chaiwatthanaram ---

## The laterite court, the central prang (35 m) on its 33 m base with
## steep stairs up to the entrances halfway up, four corner prangs on
## the same base, the gallery ring with the eight merus (at the corners
## and mid-sides) and, east of it, the ruined ordination hall between
## the two twelve-cornered chedis.
static func chaiwatthanaram(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#A9573A", 3.0))
	lm.use("Laterite", LandmarkMaterials.pbr("stone", "#8F5A3E", 3.0))
	lm.use("Plaster", LandmarkMaterials.pbr("render", "#CBBCA4", 3.0))
	lm.use("Dark", LandmarkMaterials.paint("#241D18", 0.9, 0.0))
	lm.box("Laterite", Vector3(0, 0.5, 0), Vector3(96.0, 1.0, 96.0))
	K.redent_lathe(lm, "Laterite", Vector3(0, 1.0, 0), PackedVector2Array([Vector2(17.0, 0), Vector2(17.0, 0.4),
		Vector2(16.5, 0.6), Vector2(16.5, 1.5)]), 0.06)
	var py := 2.5
	K.redent_prang(lm, "Brick", "Dark", "Plaster", Vector3(0, py, 0), 7.2, PRANG_M - py, 7, true)
	# Steep stairs on the axes up to the entrances halfway up the prang.
	var door_y := py + (PRANG_M - py) * 0.2
	for side in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * float(side))
		U.stairs(lm, "Laterite", b * Vector3(0, 1.0, 9.0), b, 3.2, 20, 0.5, (door_y - 1.0) / 20.0)
		for sx in [-1.0, 1.0]:
			lm.beam("Brick", b * Vector3(sx * 1.9, 1.6, 19.0), b * Vector3(sx * 1.9, door_y + 0.8, 8.5), 0.5, 0.6)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			K.redent_prang(lm, "Brick", "Dark", "Plaster", Vector3(sx * 12.5, py, sz * 12.5), 2.6, 16.0, 5, true)
	# The gallery: outer wall, the stumps of its pillars, the Buddha row.
	var hw := 44.0
	for s in [-1.0, 1.0]:
		lm.box("Brick", Vector3(0, 2.6, s * hw), Vector3(hw * 2.0, 3.2, 1.6))
		lm.box("Brick", Vector3(s * hw, 2.6, 0), Vector3(1.6, 3.2, hw * 2.0 - 1.6))
		for i in 2:
			var seg_x := -hw + 8.0 + 39.0 * float(i)
			U.posts(lm, "Plaster", Vector3(seg_x, 1.0, s * (hw - 5.0)), Vector3(seg_x + 29.0, 1.0, s * (hw - 5.0)), 10, 1.4, 0.8, 0.0)
			U.posts(lm, "Plaster", Vector3(s * (hw - 5.0), 1.0, seg_x), Vector3(s * (hw - 5.0), 1.0, seg_x + 29.0), 10, 1.4, 0.8, 0.0)
			for j in 8:
				var t := seg_x + 1.8 + 25.4 * float(j) / 7.0
				K.seated_buddha(lm, "Plaster", Vector3(t, 1.0, s * (hw - 1.8)), Basis(Vector3.UP, 0.0 if s < 0.0 else PI), 2.2)
				K.seated_buddha(lm, "Plaster", Vector3(s * (hw - 1.8), 1.0, t), Basis(Vector3.UP, -PI * 0.5 * s), 2.2)
	for c in [Vector3(-hw, 0, -hw), Vector3(hw, 0, -hw), Vector3(hw, 0, hw), Vector3(-hw, 0, hw),
			Vector3(0, 0, -hw), Vector3(hw, 0, 0), Vector3(0, 0, hw), Vector3(-hw, 0, 0)]:
		_meru(lm, c + Vector3(0, 1.0, 0), Basis(Vector3.UP, atan2(-c.x, -c.z)), absf(c.x) > 1.0 and absf(c.z) > 1.0)
	# Ruined ordination hall: wall stubs, the column rows and the base,
	# between the two chedis of twelve indented corners.
	var hc := Vector3(72.0, 0, 0)
	lm.box("Laterite", hc + Vector3(0, 0.6, 0), Vector3(16.0, 1.2, 34.0))
	for s in [-1.0, 1.0]:
		lm.box("Brick", hc + Vector3(s * 6.0, 2.6, 2.0), Vector3(1.4, 2.8, 26.0))
		lm.box("Brick", hc + Vector3(s * 3.0, 3.8, -14.4), Vector3(4.6, 5.2, 1.4))
		for i in 8:
			K.thai_column(lm, "Plaster", "Plaster", hc + Vector3(s * 3.0, 1.2, -11.0 + 25.0 * float(i) / 7.0), 1.0,
				2.4 + 1.2 * float(i % 3))
		K.redent_chedi(lm, "Brick", "Brick", "Plaster", hc + Vector3(0, 0, s * 25.0), 2.6, 13.0, 0.14)
	K.seated_buddha(lm, "Plaster", hc + Vector3(0, 1.2, -11.5), Basis(), 4.2)
	lm.commit(model)

## A meru (chedi-prasat chapel) of the gallery: a laterite base, the
## redented brick cella with a porch and doorway toward the prang and
## Jataka relief panels on the other faces, then its redented bell
## spire. Corner merus are square, mid-side ones longer along the
## gallery.
static func _meru(lm: LandmarkMesh, c: Vector3, b: Basis, corner: bool) -> void:
	var w := 4.8 if corner else 5.4
	lm.box("Laterite", c + Vector3(0, 0.6, 0), Vector3(11.0, 1.2, 11.0), b)
	K.redent_lathe(lm, "Brick", c + Vector3(0, 1.2, 0), PackedVector2Array([Vector2(w * 1.06, 0), Vector2(w, 0.5),
		Vector2(w, 6.0), Vector2(w * 1.1, 6.4), Vector2(w * 1.1, 6.9)]), 0.1, 0.0, 1)
	lm.box("Brick", c + b * Vector3(0, 4.0, w + 0.8), Vector3(3.6, 5.6, 1.6), b)
	lm.box("Dark", c + b * Vector3(0, 3.4, w + 1.62), Vector3(1.6, 3.4, 0.1), b, 0.0)
	K.outline_prism(lm, "Brick", c + b * Vector3(0, 6.8, w + 0.9), b, K.flame_outline(3.6, 2.6), 1.2)
	for side in [1, 2, 3]:
		var sb := b * Basis(Vector3.UP, PI * 0.5 * float(side))
		for x in [-2.6, 0.0, 2.6]:
			lm.box("Plaster", c + sb * Vector3(x, 4.2, w + 0.04), Vector3(1.6, 2.4, 0.12), sb, 0.0)
	K.redent_lathe(lm, "Brick", c + Vector3(0, 8.1, 0), PackedVector2Array([Vector2(w * 0.95, 0),
		Vector2(w * 0.8, 0.8), Vector2(w * 0.86, 1.2), Vector2(w * 0.62, 2.6), Vector2(w * 0.66, 3.0),
		Vector2(w * 0.42, 4.4), Vector2(w * 0.3, 5.0), Vector2(w * 0.12, 6.2), Vector2(0.0, 6.8)]), 0.12)

# --- Wat Rong Khun ---

## The White Temple (30 m), facing south (+Z) over the lake: the ubosot
## on its plinth (white walls inlaid with mirror glass, pointed
## windows, a three-layer stepped roof bristling with white-and-mirror
## gable trim and spikes, the spired crown), the columned porch and
## naga stair, the bridge past the reaching hands, the gate of heaven
## with its guardians, and the golden hall.
static func rong_khun(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("White", LandmarkMaterials.pbr("render", "#F6F4EE", 3.0))
	lm.use("Mirror", LandmarkMaterials.paint("#DDE7EC", 0.1, 0.9))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.use("Water", LandmarkMaterials.glass("#355F6B"))
	lm.use("Dark", LandmarkMaterials.paint("#2A2623", 0.9, 0.0))
	K.plinth(lm, "White", Vector3.ZERO, Basis(), 26.0, 40.0, 1.6)
	lm.box("White", Vector3(0, 6.1, 0), Vector3(20.0, 9.0, 32.0))
	for sx in [-1.0, 1.0]:
		var sb := Basis(Vector3.UP, PI * 0.5 * sx)
		for i in 7:
			var z := -13.7 + 4.57 * float(i)
			K.thai_window(lm, "White", "Dark", "Mirror", Vector3(sx * 10.02, 3.4, z), sb, 1.8, 4.0)
			lm.box("Mirror", Vector3(sx * 10.06, 9.3, z), Vector3(0.1, 1.2, 2.6), Basis(), 0.0)
		for i in 8:
			lm.box("White", Vector3(sx * 10.25, 6.1, -16.0 + 32.0 * float(i) / 7.0), Vector3(0.5, 9.0, 0.5))
	K.thai_window(lm, "White", "Dark", "Mirror", Vector3(0, 1.6, -16.02), Basis(Vector3.UP, PI), 3.0, 6.0)
	# Porch: columns, gable roof, the door and the naga stair.
	for sx in [-1.0, 1.0]:
		for z in [17.0, 20.4]:
			K.thai_column(lm, "White", "Mirror", Vector3(sx * 5.0, 1.6, z), 0.9, 7.6)
	K.thai_window(lm, "White", "Dark", "Mirror", Vector3(0, 1.6, 16.02), Basis(), 3.6, 6.0)
	K.thai_roof(lm, "White", "Mirror", "White", "White", Vector3(0, 9.6, 18.6), Basis(), 12.0, 6.0, 3.4, 1.2, 0, 1, 2.0)
	U.stairs(lm, "White", Vector3(0, 0, 21.2), Basis(), 8.0, 4, 0.7, 0.4)
	for sx in [-1.0, 1.0]:
		var prev := Vector3(sx * 4.4, 2.2, 21.4)
		for i in 6:
			var p := Vector3(sx * (4.4 + 0.3 * sin(float(i) * 1.3)), 2.2 - 0.25 * float(i) + 0.4 * sin(float(i)), 21.4 + 0.9 * float(i + 1))
			lm.beam("White", prev, p, 0.7, 0.8)
			prev = p
		lm.beam("Mirror", prev, prev + Vector3(0, 2.2, 0.8), 0.9, 0.7)
	# The stepped three-layer roof with spiked eaves and its crown.
	var y := 10.6
	for k in 3:
		var f := 1.0 - 0.2 * float(k)
		var w := 22.0 * f
		var l := 34.0 * (1.0 - 0.12 * float(k))
		var rise := 4.5 * f
		var c := Vector3(0, y, 0)
		K.thai_roof(lm, "White", "Mirror", "White", "White", c, Basis(), w, l, rise, 1.6, 1, 0 if k > 0 else 1, 1.8)
		U.eave_spikes(lm, "Mirror", c, Basis(), w, l * (1.0 - 0.14), rise, 1.6, 0.9, 1.7, 1.9)
		if k < 2:
			lm.box("White", c + Vector3(0, (rise + 1.6) * 0.5, 0), Vector3(22.0 * (f - 0.2), rise + 1.6,
				34.0 * (1.0 - 0.12 * float(k + 1)) * 0.86))
			y += rise + 1.6
		else:
			y += rise
	for z in [-9.0, 0.0, 9.0]:
		var h := WHITE_TEMPLE_M - y if z == 0.0 else 3.0
		lm.lathe("White", Vector3(0, y - 0.4, z), PackedVector2Array([Vector2(0.9, 0), Vector2(1.1, h * 0.1),
			Vector2(0.7, h * 0.3), Vector2(0.8, h * 0.38), Vector2(0.45, h * 0.6), Vector2(0.5, h * 0.66),
			Vector2(0.15, h * 0.9), Vector2(0.0, h + 0.4)]), 8)
	# Lake, bridge and the field of reaching hands before it.
	lm.box("Water", Vector3(0, 0.1, 40.0), Vector3(60.0, 0.2, 40.0))
	lm.box("White", Vector3(0, 0.5, 40.0), Vector3(5.0, 1.0, 36.0))
	for s in [-1.0, 1.0]:
		U.posts(lm, "White", Vector3(s * 2.4, 1.0, 22.0), Vector3(s * 2.4, 1.0, 58.0), 19, 1.5, 0.4)
		lm.box("White", Vector3(s * 2.4, 2.3, 40.0), Vector3(0.3, 0.3, 36.0))
	for i in 140:
		var a := float(i) * 2.39996
		var rr := 3.4 + 4.0 * sqrt(float(i) / 140.0)
		var hp := Vector3(cos(a) * rr, 0.2, 52.0 + sin(a) * rr * 0.7)
		if absf(hp.x) < 2.8:
			continue
		var tip := hp + Vector3(sin(a * 3.0) * 0.3, 1.3 + 0.6 * fmod(float(i) * 0.37, 1.0), cos(a * 2.0) * 0.3)
		lm.beam("White", hp, tip, 0.22, 0.16)
		lm.beam("White", tip, tip + Vector3(0, 0.35, 0.05), 0.3, 0.1)
	# Kinnaree on the lake.
	for s in [-1.0, 1.0]:
		lm.box("White", Vector3(s * 12.0, 0.6, 36.0), Vector3(1.6, 1.2, 1.6))
		LandmarkKits.statue_figure(lm, "White", Vector3(s * 12.0, 1.2, 36.0), 2.6, true)
	# Gate of heaven with Death and Rahu as guardians.
	for s in [-1.0, 1.0]:
		lm.box("White", Vector3(s * 3.0, 3.0, 24.0), Vector3(1.2, 6.0, 1.2))
		lm.box("White", Vector3(s * 4.6, 0.5, 24.6), Vector3(1.4, 1.0, 1.4))
		LandmarkKits.statue_figure(lm, "White", Vector3(s * 4.6, 1.0, 24.6), 2.4, false)
	lm.box("White", Vector3(0, 6.4, 24.0), Vector3(8.0, 1.2, 1.6))
	K.roof_piece(lm, "White", "Mirror", "White", "White", Vector3(0, 7.0, 24.0), Basis(Vector3.UP, PI * 0.5), 3.0, 8.0,
		1.8, 0.8, 0.6, 1.2)
	# Golden hall beside the lake.
	var gc := Vector3(46.0, 0, 28.0)
	K.plinth(lm, "Gold", gc, Basis(), 12.0, 16.0, 1.2)
	lm.box("Gold", gc + Vector3(0, 4.7, 0), Vector3(10.0, 7.0, 14.0))
	for sx in [-1.0, 1.0]:
		for i in 3:
			K.thai_window(lm, "Gold", "Dark", "Gold", gc + Vector3(sx * 5.02, 2.4, -4.0 + 4.0 * float(i)),
				Basis(Vector3.UP, PI * 0.5 * sx), 1.4, 3.0)
	K.thai_roof(lm, "Gold", "Gold", "Gold", "Gold", gc + Vector3(0, 8.2, 0), Basis(), 11.0, 15.0, 3.0, 1.0, 1, 1, 1.4)
	lm.commit(model)
