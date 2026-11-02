class_name LandmarkAeJapan
extends RefCounted

## Landmarks of Japan in true metres: Kinkaku-ji (12.5 m: the Golden
## Pavilion of 1955 after the 1397 original; a shinden-style ground
## floor of plain wood and white plaster behind an open veranda, the
## gilded Choon-do and Kukkyo-cho with bell-shaped katomado windows and
## railed balconies, cypress-bark roofs on exposed rafters, the fishing
## pavilion over the pond and the bronze phoenix), Himeji Castle (46.4 m:
## the white main keep on its 14.85 m fan-curved stone base, five roofs
## with chidori and kara gables, barred windows and shachihoko, and the
## east, west and north-west small keeps linked by watari-yagura round a
## courtyard) and the Itsukushima torii (16.6 m: the vermilion ryobu
## torii of 1875 in the sea, base: water; camphor main pillars about
## 10 m round, four sode-bashira with their own roofs, two tiers of nuki
## and the 24.2 m upswept kasagi). Halls face south (+Z).

# --- Kinkaku-ji ---

static func kinkakuji(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#8A857A", 3.0))
	lm.use("Wood", LandmarkMaterials.pbr("wood", "#CDB98F", 2.0))
	lm.use("Plaster", LandmarkMaterials.pbr("render", "#EEEAE0", 2.0))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.use("Shingle", LandmarkMaterials.pbr("wood", "#5E5346", 1.5))
	lm.use("Shadow", LandmarkMaterials.paint("#2A231C", 0.9, 0.0))
	lm.box("Stone", Vector3(0, 0.3, 0), Vector3(14.0, 0.6, 12.0))
	# Ground floor (Hosui-in): veranda deck, posts, plaster frieze over
	# latticed shitomido shutters, the fishing pavilion to the west.
	lm.box("Wood", Vector3(0, 0.75, 0), Vector3(13.2, 0.3, 11.0))
	lm.box("Wood", Vector3(0, 2.4, -0.6), Vector3(10.2, 3.0, 8.0))
	_posts(lm, "Wood", Vector2(11.0, 9.0), 0.9, 3.0, 6, 5, 0.14)
	for s in [-1.0, 1.0]:
		_shitomido(lm, Vector3(0, 0.9, -0.6 + s * 4.0), Vector3.RIGHT, 10.2, 2.1, Vector3(0, 0, s))
		_shitomido(lm, Vector3(s * 5.1, 0.9, -0.6), Vector3.BACK, 8.0, 2.1, Vector3(s, 0, 0))
	lm.box("Plaster", Vector3(0, 3.45, -0.6), Vector3(10.3, 0.9, 8.1))
	lm.box("Wood", Vector3(0, 3.95, 0), Vector3(11.4, 0.3, 9.4))
	_fishing_pavilion(lm)
	var c1 := Vector3(0, 4.1, 0)
	LandmarkAeParts.hip_roof(lm, "Shingle", c1, Vector2(15.4, 13.4), Vector2(9.6, 7.6), 1.0, 0.4)
	LandmarkAeParts.eave_fascia(lm, "Shingle", c1, Vector2(15.4, 13.4), 0.4, 0.35, Vector2(11.0, 9.0))
	# Second floor (Choon-do): gilded walls with real window openings,
	# a railed balcony, its own roof.
	var y2 := 4.4
	lm.box("Wood", Vector3(0, y2 + 0.1, 0), Vector3(10.0, 0.2, 8.4))
	_gold_storey(lm, Vector2(8.6, 7.0), y2 + 0.2, 2.3, 3, Vector2(1.3, 1.4))
	_railing(lm, Vector2(9.8, 8.2), y2 + 0.2, 0.75, "Gold")
	var c2 := Vector3(0, y2 + 2.5, 0)
	LandmarkAeParts.hip_roof(lm, "Shingle", c2, Vector2(12.4, 10.8), Vector2(7.0, 5.4), 1.0, 0.4)
	LandmarkAeParts.eave_fascia(lm, "Shingle", c2, Vector2(12.4, 10.8), 0.4, 0.3, Vector2(8.6, 7.0))
	# Third floor (Kukkyo-cho): gold inside and out, a panelled door
	# between two bell-shaped katomado on every face, balcony.
	var y3 := c2.y + 0.8
	lm.box("Gold", Vector3(0, y3 + 0.1, 0), Vector3(7.6, 0.2, 7.6))
	_gold_storey(lm, Vector2(6.2, 6.2), y3 + 0.2, 1.8, 3, Vector2(0.9, 1.1))
	for f in 4:
		var a := PI * 0.5 * f
		var n := Vector3(cos(a), 0, sin(a))
		var r := Vector3.UP.cross(n).normalized() * -1.0
		for i in [-1.0, 1.0]:
			var c: Vector3 = n * 3.45 + r * (6.2 / 3.0) * i + Vector3(0, y3 + 0.2 + 0.4 + 1.1, 0)
			LandmarkDetail.arch(lm, "Gold", c - Vector3(0, 0.1, 0), n, 0.9, 0.14, 0.08)
	_railing(lm, Vector2(7.4, 7.4), y3 + 0.2, 0.7, "Gold")
	var c3 := Vector3(0, y3 + 2.0, 0)
	LandmarkAeParts.hip_roof(lm, "Shingle", c3, Vector2(9.8, 9.8), Vector2(1.0, 1.0), 1.5, 0.4)
	LandmarkAeParts.eave_fascia(lm, "Shingle", c3, Vector2(9.8, 9.8), 0.4, 0.3, Vector2(6.2, 6.2))
	LandmarkAeParts.hip_ridges(lm, "Shingle", c3, Vector2(9.8, 9.8), Vector2(1.0, 1.0), 1.5, 0.4, 0.22)
	_phoenix(lm, Vector3(0, c3.y + 1.5, 0), 12.5)
	lm.commit(model)

## Square posts round a w x d rectangle from y, `nx` by `nz` per side.
static func _posts(lm: LandmarkMesh, key: String, size: Vector2, y: float, h: float, nx: int, nz: int,
		hw: float) -> void:
	for i in nx:
		var x := size.x * (float(i) / float(nx - 1) - 0.5)
		for s in [-1.0, 1.0]:
			lm.box(key, Vector3(x, y + h * 0.5, s * size.y * 0.5), Vector3(hw * 2.0, h, hw * 2.0), Basis(), 0.0)
	for i in range(1, nz - 1):
		var z := size.y * (float(i) / float(nz - 1) - 0.5)
		for s in [-1.0, 1.0]:
			lm.box(key, Vector3(s * size.x * 0.5, y + h * 0.5, z), Vector3(hw * 2.0, h, hw * 2.0), Basis(), 0.0)

## Shitomido: hinged lattice shutters, a grid of thin battens `w` wide
## along `along`, `h` tall from c (bottom centre), proud along `n`.
static func _shitomido(lm: LandmarkMesh, c: Vector3, along: Vector3, w: float, h: float, n: Vector3) -> void:
	var basis := Basis(along, Vector3.UP, n)
	var nv := int(w / 0.45)
	for i in nv + 1:
		lm.box("Wood", c + n * 0.04 + along * w * (float(i) / float(nv) - 0.5) + Vector3(0, h * 0.5, 0),
			Vector3(0.05, h, 0.05), basis, 0.0)
	var nh := int(h / 0.45)
	for j in nh + 1:
		lm.box("Wood", c + n * 0.06 + Vector3(0, h * float(j) / float(nh), 0), Vector3(w, 0.05, 0.05), basis, 0.0)

## Gilded storey of plan `size` from y, `h` tall: a gold mass with a
## pierced gold skin on each face (`cols` openings of `win`) and corner
## posts.
static func _gold_storey(lm: LandmarkMesh, size: Vector2, y: float, h: float, cols: int, win: Vector2) -> void:
	lm.box("Gold", Vector3(0, y + h * 0.5, 0), Vector3(size.x - 0.5, h, size.y - 0.5))
	for f in 4:
		var a := PI * 0.5 * f
		var n := Vector3(cos(a), 0, sin(a))
		var r := Vector3.UP.cross(n).normalized() * -1.0
		var w := size.x - 0.5 if f % 2 == 1 else size.y - 0.5
		var half := (size.y if f % 2 == 1 else size.x) * 0.5 - 0.25
		LandmarkDetail.pierced_face(lm, "Gold", "Shadow", Vector3(0, y, 0) + n * half - r * w * 0.5, r, n, w, h,
			cols, 1, win, 0.4, h, 0.25)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			lm.box("Gold", Vector3(sx * size.x * 0.5, y + h * 0.5, sz * size.y * 0.5), Vector3(0.3, h, 0.3), Basis(), 0.0)

## Balcony railing (koran) round a w x d deck at y: posts, top rail and
## a mid rail.
static func _railing(lm: LandmarkMesh, size: Vector2, y: float, h: float, key: String) -> void:
	for f in 4:
		var a := PI * 0.5 * f
		var n := Vector3(cos(a), 0, sin(a))
		var r := Vector3.UP.cross(n).normalized()
		var w := size.x if f % 2 == 1 else size.y
		var half := (size.y if f % 2 == 1 else size.x) * 0.5
		var c := Vector3(0, y, 0) + n * half
		var basis := Basis(r, Vector3.UP, n)
		var np := int(w / 0.9)
		for i in np + 1:
			lm.box(key, c + r * w * (float(i) / float(np) - 0.5) + Vector3(0, h * 0.5, 0), Vector3(0.08, h, 0.08), basis, 0.0)
		lm.box(key, c + Vector3(0, h, 0), Vector3(w + 0.1, 0.07, 0.1), basis, 0.0)
		lm.box(key, c + Vector3(0, h * 0.45, 0), Vector3(w, 0.05, 0.06), basis, 0.0)

## The tsuridono: a small open pavilion projecting west over the pond.
static func _fishing_pavilion(lm: LandmarkMesh) -> void:
	var cx := -7.4
	lm.box("Wood", Vector3(cx, 0.75, 1.5), Vector3(3.4, 0.3, 3.0))
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			lm.box("Wood", Vector3(cx + sx * 1.5, 1.95, 1.5 + sz * 1.3), Vector3(0.2, 2.1, 0.2), Basis(), 0.0)
	_railing(lm, Vector2(3.4, 3.0), 0.9, 0.6, "Wood")
	var c := Vector3(cx, 3.0, 1.5)
	LandmarkAeParts.hip_roof(lm, "Shingle", c, Vector2(5.0, 4.6), Vector2(2.6, 0.6), 0.9, 0.25)
	LandmarkAeParts.eave_fascia(lm, "Shingle", c, Vector2(5.0, 4.6), 0.25, 0.22)

## The bronze phoenix (gilded) on its stand, crest at `top`.
static func _phoenix(lm: LandmarkMesh, base: Vector3, top: float) -> void:
	lm.lathe("Gold", base, PackedVector2Array([Vector2(0.5, 0), Vector2(0.4, 0.2), Vector2(0.18, 0.35),
		Vector2(0.14, 0.55), Vector2(0.25, 0.6)]), 10)
	var b := base + Vector3(0, 0.6, 0)
	lm.box("Gold", b, Vector3(0.3, 0.3, 0.7), Basis(Vector3.RIGHT, -0.3), 0.0)
	lm.beam("Gold", b + Vector3(0, 0.1, 0.3), b + Vector3(0, 0.35, 0.55), 0.12, 0.14)
	lm.box("Gold", b + Vector3(0, 0.4, 0.62), Vector3(0.12, 0.14, 0.24), Basis(), 0.0)
	lm.beam("Gold", b + Vector3(0, 0.45, 0.6), Vector3(0, top, b.z + 0.5), 0.05, 0.05)
	for s in [-1.0, 1.0]:
		# Raised wings in two feathered panels.
		lm.beam("Gold", b + Vector3(s * 0.12, 0.05, 0.05), b + Vector3(s * 0.55, 0.35, -0.05), 0.3, 0.04)
		lm.beam("Gold", b + Vector3(s * 0.55, 0.35, -0.05), b + Vector3(s * 0.85, 0.5, -0.2), 0.24, 0.04)
	for k in 3:
		lm.beam("Gold", b + Vector3(0, 0, -0.3), b + Vector3((float(k) - 1.0) * 0.18, 0.45, -0.85), 0.08, 0.03)

# --- Himeji Castle ---

const HIMEJI_M := 46.4

static func himeji(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#8F897D", 3.0))
	lm.use("Plaster", LandmarkMaterials.pbr("render", "#EEEAE0", 3.0))
	lm.use("Tile", LandmarkMaterials.pbr("slate", "#4C5054", 1.5))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.use("Shadow", LandmarkMaterials.paint("#26221F", 0.9, 0.0))
	lm.use("Wood", LandmarkMaterials.paint("#3A3430", 0.8, 0.0))
	# Main keep (south-east), then the west, north-west (inui) and east
	# small keeps round the courtyard.
	LandmarkAeKeep.keep(lm, Vector2.ZERO, Vector2(24.0, 20.5), 14.85, 5, 1.0)
	LandmarkAeKeep.keep(lm, Vector2(-34.0, 2.0), Vector2(12.0, 10.0), 9.0, 3, 0.6)
	LandmarkAeKeep.keep(lm, Vector2(-34.0, -28.0), Vector2(12.5, 10.5), 9.0, 3, 0.62)
	LandmarkAeKeep.keep(lm, Vector2(0.0, -30.0), Vector2(11.0, 9.5), 9.0, 3, 0.58)
	# Two-storey watari-yagura closing the ring between the keeps.
	LandmarkAeKeep.yagura(lm, Vector3(-19.0, 0, 2.0), Vector3(-26.0, 0, 2.0), 7.0)
	LandmarkAeKeep.yagura(lm, Vector3(-34.0, 0, -6.0), Vector3(-34.0, 0, -20.0), 7.0)
	LandmarkAeKeep.yagura(lm, Vector3(-25.0, 0, -28.0), Vector3(-8.0, 0, -29.0), 7.0)
	LandmarkAeKeep.yagura(lm, Vector3(0.0, 0, -22.0), Vector3(0.0, 0, -15.0), 7.0)
	lm.commit(model)

# --- Itsukushima torii ---

const TORII_M := 16.6
const TORII_X := 5.45
## Calligraphy strokes (x, y, width, height) in a character cell.
const STROKES := [Vector4(0.0, 0.3, 0.3, 0.07), Vector4(-0.1, 0.0, 0.06, 0.6), Vector4(0.1, -0.05, 0.06, 0.5),
	Vector4(0.0, -0.3, 0.32, 0.07), Vector4(-0.08, 0.12, 0.14, 0.06), Vector4(0.08, 0.12, 0.14, 0.06),
	Vector4(0.0, 0.0, 0.26, 0.06), Vector4(0.12, 0.25, 0.05, 0.3)]

static func torii(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Paint", LandmarkMaterials.paint("#C8381F", 0.55, 0.0))
	lm.use("Bark", LandmarkMaterials.pbr("wood", "#4A4036", 2.0))
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#6F6A60", 3.0))
	lm.use("Plaque", LandmarkMaterials.paint("#1E2124", 0.6, 0.0))
	lm.use("Gold", LandmarkMaterials.gold())
	for s in [-1.0, 1.0]:
		var x: float = s * TORII_X
		# Main camphor pillar standing on the sea bed by its own weight,
		# with the black daiwa ring at its head.
		lm.frustum("Stone", Vector3(x, 0, 0), 1.9, 1.8, 0.35, 24)
		lm.lathe("Paint", Vector3(x, 0.35, 0), PackedVector2Array([Vector2(1.58, 0), Vector2(1.55, 2.0),
			Vector2(1.52, 4.0), Vector2(1.44, 9.0), Vector2(1.36, 13.25)]), 48)
		lm.frustum("Bark", Vector3(x, 12.9, 0), 1.42, 1.42, 0.7, 48)
		# Four sode-bashira, tied to it by two tiers of nuki, each pair
		# under a little bark roof.
		for z in [-3.6, 3.6]:
			lm.frustum("Stone", Vector3(x, 0, z), 0.9, 0.85, 0.3, 16)
			lm.lathe("Paint", Vector3(x, 0.3, z), PackedVector2Array([Vector2(0.62, 0), Vector2(0.6, 4.0), Vector2(0.56, 8.2)]), 24)
			lm.frustum("Bark", Vector3(x, 8.0, z), 0.66, 0.66, 0.35, 20)
			for ny in [3.4, 7.2]:
				var zm: float = z * 0.5
				lm.box("Paint", Vector3(x, ny, zm), Vector3(0.7, 0.75, absf(z) + 1.8))
				for side in [-1.0, 1.0]:
					lm.box("Paint", Vector3(x + side * 0.42, ny, z * 0.62), Vector3(0.14, 0.5, 0.35), Basis(), 0.0)
			lm.box("Paint", Vector3(x, 8.75, z), Vector3(1.6, 0.35, 1.6))
			lm.gable("Bark", Vector3(x, 8.95, z), 1.8, 1.8, 0.5, Basis(), 0.3, "Bark")
			# Thick bark eaves and bargeboards of the little roof.
			for sx in [-1.0, 1.0]:
				lm.beam("Bark", Vector3(x + sx * 1.2, 8.88, z - 1.1), Vector3(x + sx * 1.2, 8.88, z + 1.1), 0.18, 0.14, Vector3.UP)
				for sz in [-1.0, 1.0]:
					lm.beam("Paint", Vector3(x + sx * 1.2, 8.85, z + sz * 1.08), Vector3(x, 9.48, z + sz * 1.08), 0.2, 0.08,
						Vector3.UP)
		lm.box("Paint", Vector3(x, 8.55, 0), Vector3(1.2, 0.6, 7.2))
	# Nuki tie beam through both pillars, projecting beyond them, with
	# wedges either side of each pillar.
	lm.box("Paint", Vector3(0, 10.6, 0), Vector3(TORII_X * 2.0 + 6.0, 1.1, 1.0))
	for s in [-1.0, 1.0]:
		for side in [-1.0, 1.0]:
			lm.box("Paint", Vector3(s * TORII_X + side * 1.7, 10.6, 0.56), Vector3(0.5, 0.8, 0.14), Basis(), 0.0)
			lm.box("Paint", Vector3(s * TORII_X + side * 1.7, 10.6, -0.56), Vector3(0.5, 0.8, 0.14), Basis(), 0.0)
	# Gakuzuka strut and the two framed plaques (sea and shrine faces).
	lm.box("Paint", Vector3(0, 12.4, 0), Vector3(1.0, 2.6, 0.7))
	# Seaward "嚴嶋神社" (four characters), shrineward "伊都岐島神社" (six),
	# in Prince Arisugawa Takehito's hand: raised gilt strokes.
	for s in [-1.0, 1.0]:
		var pz: float = s * 0.42
		lm.box("Plaque", Vector3(0, 12.3, pz), Vector3(1.5, 2.3, 0.14))
		for fx in [-1.0, 1.0]:
			lm.box("Gold", Vector3(fx * 0.72, 12.3, pz + s * 0.08), Vector3(0.1, 2.4, 0.06), Basis(), 0.0)
			lm.box("Gold", Vector3(0, 12.3 + fx * 1.15, pz + s * 0.08), Vector3(1.54, 0.1, 0.06), Basis(), 0.0)
		var chars := 4 if s < 0.0 else 6
		var cell := 2.0 / float(chars)
		for k in chars:
			var cy := 13.3 - cell * (float(k) + 0.5)
			for i in 5:
				var st: Vector4 = STROKES[(k * 3 + i * 5 + (0 if s < 0.0 else 2)) % STROKES.size()]
				lm.box("Gold", Vector3(st.x * 0.9, cy + st.y * cell, pz + s * 0.085),
					Vector3(st.z * 0.9, st.w * cell, 0.04), Basis(), 0.0)
	# Shimaki and the upswept kasagi with its bark top.
	var half := 12.1
	_swept(lm, "Paint", half - 0.9, 13.65, 0.8, 1.7, 0.0)
	_swept(lm, "Paint", half, 14.45, 1.0, 2.0, 0.9)
	_swept(lm, "Bark", half + 0.15, 15.45, TORII_M - 15.45 - 0.9 - 0.12, 2.4, 0.9, 0.12)
	lm.commit(model)

## A beam along x from -half to half, section h tall x d deep, bottom at
## y in the middle and swept up by `sweep` at the ends (cubic), built
## as smooth faces and two end caps; `ridge` > 0 peaks the top into a
## shallow roof (the kasagi's bark covering).
static func _swept(lm: LandmarkMesh, key: String, half: float, y: float, h: float, d: float, sweep: float,
		ridge: float = 0.0) -> void:
	var n := 48
	var bot := PackedVector3Array()
	var top := PackedVector3Array()
	for i in n + 1:
		var x := -half + 2.0 * half * float(i) / float(n)
		var yc := y + sweep * pow(absf(x) / half, 3.0)
		bot.append(Vector3(x, yc, 0))
		top.append(Vector3(x, yc + h, 0))
	var hz := Vector3(0, 0, d * 0.5)
	var hzt := Vector3(0, 0, d * 0.5 * 1.0)
	var faces := [[_off(top, -hzt), _off(top, hzt), Vector3.UP], [_off(bot, hz), _off(bot, -hz), Vector3.DOWN],
		[_off(bot, hz), _off(top, hzt), Vector3.BACK], [_off(top, -hzt), _off(bot, -hz), Vector3.FORWARD]]
	for f in faces:
		if ridge > 0.0 and f[2] == Vector3.UP:
			var crest := _off(top, Vector3(0, ridge, 0))
			lm.grid(key, [f[0], crest], (Vector3.UP + Vector3.FORWARD).normalized())
			lm.grid(key, [crest, f[1]], (Vector3.UP + Vector3.BACK).normalized())
			for e in [0, n]:
				var s := -1.0 if e == 0 else 1.0
				var en := Vector3(s, 0, 0)
				lm.tri(key, top[e] - hzt, top[e] + hzt, crest[e], en, en, en,
					Vector2(-d * 0.5, 0), Vector2(d * 0.5, 0), Vector2(0, ridge))
			continue
		lm.grid(key, [f[0], f[1]], f[2])
	for e in [0, n]:
		var s := -1.0 if e == 0 else 1.0
		lm.quad(key, bot[e] - hz, bot[e] + hz, top[e] + hzt, top[e] - hzt, Vector3(s, 0, 0))

static func _off(pts: PackedVector3Array, o: Vector3) -> PackedVector3Array:
	var out := PackedVector3Array()
	for p in pts:
		out.append(p + o)
	return out
