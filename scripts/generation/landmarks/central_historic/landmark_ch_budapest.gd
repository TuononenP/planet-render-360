class_name LandmarkChBudapest
extends RefCounted

## Fisherman's Bastion and Matthias Church on Buda Castle Hill in true
## metres (Frigyes Schulek, 1895-1902): a neo-Romanesque terrace of
## white limestone about 140 m long on the Danube side (+X), its seven
## conical towers for the seven Magyar chieftains (the main tower in the
## middle tallest, several storeys), arcaded galleries between them and
## the equestrian St Stephen. West of it the Gothic hall church with its
## diamond-patterned Zsolnay roof, the 80 m Matthias tower at the south
## west corner and the low Bela tower at the north west.

const BASTION_TOP := 80.0
## The seven tower centres (x, z), north (-Z) to south.
const TOWERS := [Vector2(0.0, -64.0), Vector2(8.0, -44.0), Vector2(14.0, -22.0), Vector2(16.0, 0.0),
	Vector2(14.0, 22.0), Vector2(8.0, 44.0), Vector2(0.0, 64.0)]
## Terrace walk level above the square.
const WALK := 1.4

static func bastion(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("limestone", "#D2C9AE", 3.0))
	lm.use("White", LandmarkMaterials.pbr("limestone", "#E9E4D4", 3.0))
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#8E8672", 3.0))
	lm.use("Cone", LandmarkMaterials.pbr("limestone", "#B8B4A6", 1.8))
	lm.use("Spire", LandmarkMaterials.pbr("stone", "#9C978A", 2.5))
	lm.use("Roof", LandmarkMaterials.pbr("terracotta", "#B9582F", 2.0))
	lm.use("RoofG", LandmarkMaterials.pbr("terracotta", "#4F7F5A", 2.0))
	lm.use("RoofY", LandmarkMaterials.pbr("terracotta", "#D9A93C", 2.0))
	lm.use("RoofB", LandmarkMaterials.pbr("terracotta", "#3C5C8C", 2.0))
	lm.use("Windows", LandmarkMaterials.glass("#222B30"))
	lm.use("Bronze", LandmarkMaterials.paint("#4C5A4E", 0.45, 0.5))
	lm.use("Gilt", LandmarkMaterials.gold())
	LandmarkChMatthias.church(lm)
	_terrace(lm)
	for k in TOWERS.size():
		var t: Vector2 = TOWERS[k]
		if k == 3:
			_main_tower(lm, Vector3(t.x, WALK, t.y))
		else:
			_cone_tower(lm, Vector3(t.x, WALK, t.y), 9.5 if k % 3 == 0 else 8.0)
	for k in TOWERS.size() - 1:
		var a: Vector2 = TOWERS[k]
		var b: Vector2 = TOWERS[k + 1]
		_gallery(lm, Vector3(a.x, WALK, a.y), Vector3(b.x, WALK, b.y))
	_stephen(lm, Vector3(-14.0, 0, 34.0))
	lm.commit(model)

## Terrace platform along the tower line: a plinth course, the walk with
## its kerb and the broad stair down from the middle of the bastion.
static func _terrace(lm: LandmarkMesh) -> void:
	for k in TOWERS.size() - 1:
		var a: Vector2 = TOWERS[k]
		var b: Vector2 = TOWERS[k + 1]
		var p := Vector3(a.x, 0, a.y)
		var q := Vector3(b.x, 0, b.y)
		LandmarkChParts.wall(lm, "Stone", p + Vector3(-2.0, 0, 0), q + Vector3(-2.0, 0, 0), 0.0, WALK, 10.0)
		LandmarkChParts.wall(lm, "White", p + Vector3(1.8, 0, 0), q + Vector3(1.8, 0, 0), WALK, WALK + 0.3, 1.6)
	# The middle stair with its landings, west of the main tower.
	for i in 6:
		lm.box("Stone", Vector3(9.0 - 1.1 * (float(i) + 0.5), WALK * (1.0 - float(i) / 6.0) * 0.5, 0),
			Vector3(1.1, WALK * (1.0 - float(i) / 6.0), 12.0), Basis(), 0.0)

## A tower of the bastion: octagonal shaft on a moulded plinth, two-light
## arched openings with a colonnette on the cardinal faces, a corbelled
## arcade frieze, the cornice and a tall stone cone with a finial.
static func _cone_tower(lm: LandmarkMesh, p: Vector3, body: float) -> void:
	var r := 3.0
	lm.lathe("White", p, PackedVector2Array([Vector2(r * 1.12, 0), Vector2(r * 1.1, 0.5), Vector2(r * 1.02, 0.8),
		Vector2(r, 1.0), Vector2(r * 0.97, body)]), 8, 1.0, 1.0, PI / 8.0, false)
	for k in 8:
		var a := TAU * float(k) / 8.0
		var d := Vector3(cos(a), 0, sin(a))
		var face := p + d * r * 0.9
		if k % 2 == 0:
			for s in [-0.42, 0.42]:
				var side := d.cross(Vector3.UP).normalized() * float(s)
				LandmarkChParts.arched_window(lm, "Wall", "Windows", face + side + Vector3(0, 2.4, 0), d, 0.7, 3.0, 0.2)
			lm.frustum("Wall", face + d * 0.12 + Vector3(0, 2.4, 0), 0.1, 0.09, 2.4, 6)
			LandmarkDetail.arch(lm, "Wall", face + Vector3(0, 4.9, 0), d, 1.9, 0.22, 0.25)
		else:
			LandmarkChParts.arched_window(lm, "Wall", "Windows", face + Vector3(0, body - 4.0, 0), d, 0.45, 1.6, 0.15)
		# Arched corbel frieze under the eave.
		var rt := d.cross(Vector3.UP).normalized()
		for i in 3:
			var x := (float(i) - 1.0) * 0.75
			LandmarkChParts.arched_window(lm, "White", "Wall", face + rt * x + Vector3(0, body - 1.4, 0), d, 0.55, 0.8,
				0.12, 4)
	lm.frustum("White", p + Vector3(0, body, 0), r * 1.12, r * 1.18, 0.6, 8, PI / 8.0)
	var cone := body * 0.95
	lm.lathe("Cone", p + Vector3(0, body + 0.6, 0), PackedVector2Array([Vector2(r * 1.2, 0), Vector2(r * 1.0, 0.8),
		Vector2(r * 0.7, cone * 0.4), Vector2(r * 0.33, cone * 0.75), Vector2(0.1, cone)]), 8, 1.0, 1.0, PI / 8.0, false)
	# Small gabled lucarnes on the cone.
	for k in 4:
		var a := TAU * float(k) / 4.0 + PI / 8.0
		var d := Vector3(cos(a), 0, sin(a))
		var lc := p + d * r * 0.95 + Vector3(0, body + 1.6, 0)
		var b := Basis(Vector3.UP, atan2(d.x, d.z))
		lm.box("White", lc, Vector3(0.9, 1.2, 0.8), b)
		lm.gable("Cone", lc + Vector3(0, 0.6, 0), 0.9, 0.8, 0.6, b, 0.08, "White")
	LandmarkChParts.finial(lm, "Cone", p + Vector3(0, body + 0.6 + cone, 0), 1.4, 0.3)

## The main tower in the middle of the bastion: a square multi-storey
## keep with a corbelled balcony, paired arcades and a tall cone.
static func _main_tower(lm: LandmarkMesh, p: Vector3) -> void:
	var hw := 3.8
	var h := 15.0
	lm.box("White", p + Vector3(0, h * 0.5, 0), Vector3(hw * 2.0, h, hw * 2.0))
	for y in [5.0, 10.0]:
		LandmarkChParts.band(lm, "Wall", y, hw, hw, 0.35, 0.2, p)
	for f in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * f)
		var n := b.z
		var face := p + b * Vector3(0, 0, hw)
		LandmarkDetail.arch(lm, "Wall", face + Vector3(0, 2.6, 0), n, 3.0, 0.35, 0.3)
		lm.box("Windows", face + Vector3(0, 1.6, 0.02), Vector3(3.0, 3.2, 0.04), b, 0.0)
		for x in [-1.3, 0.0, 1.3]:
			LandmarkChParts.arched_window(lm, "Wall", "Windows", face + b * Vector3(x, 6.0, 0), n, 0.8, 2.6, 0.2)
		for x in [-0.6, 0.6]:
			LandmarkChParts.arched_window(lm, "Wall", "Windows", face + b * Vector3(x, 11.0, 0), n, 0.8, 2.4, 0.2)
		LandmarkChParts.corbels(lm, "White", face + b * Vector3(-hw + 0.3, h - 0.6, 0),
			face + b * Vector3(hw - 0.3, h - 0.6, 0), n * 0.7, 0.9, 0.9)
		LandmarkDetail.balustrade(lm, "White", face + b * Vector3(-hw - 0.4, h, 0.5), face + b * Vector3(hw + 0.4, h, 0.5),
			0.9, 2.6)
	lm.box("White", p + Vector3(0, h - 0.15, 0), Vector3(hw * 2.0 + 1.6, 0.3, hw * 2.0 + 1.6))
	# Octagonal belfry stage and the cone.
	lm.lathe("White", p + Vector3(0, h, 0), PackedVector2Array([Vector2(3.1, 0), Vector2(3.0, 4.0)]), 8,
		1.0, 1.0, PI / 8.0, false)
	for k in 8:
		var a := TAU * float(k) / 8.0
		var d := Vector3(cos(a), 0, sin(a))
		LandmarkChParts.arched_window(lm, "Wall", "Windows", p + d * 2.82 + Vector3(0, h + 0.6, 0), d, 0.9, 2.6, 0.2)
	lm.frustum("White", p + Vector3(0, h + 4.0, 0), 3.4, 3.5, 0.5, 8, PI / 8.0)
	lm.lathe("Cone", p + Vector3(0, h + 4.5, 0), PackedVector2Array([Vector2(3.6, 0), Vector2(3.0, 1.2),
		Vector2(2.0, 5.0), Vector2(0.9, 9.5), Vector2(0.1, 12.0)]), 8, 1.0, 1.0, PI / 8.0, false)
	LandmarkChParts.finial(lm, "Gilt", p + Vector3(0, h + 16.5, 0), 1.8, 0.3)

## Two-level gallery between towers: an outer arcade of round arches on
## paired colonnettes over a parapet, a stone roof slab with a crested
## cornice, the inner arcade to the terrace.
static func _gallery(lm: LandmarkMesh, a: Vector3, b: Vector3) -> void:
	var dir := (b - a)
	dir.y = 0.0
	var run := dir.length()
	dir /= run
	var out := Vector3(dir.z, 0, -dir.x)
	if out.x < 0.0:
		out = -out
	var start := 3.4
	var length := run - 6.8
	var bays := maxi(int(length / 2.6), 3)
	var pitch := length / float(bays)
	var oh := 4.6
	for side in [0, 1]:
		var off: float = 2.2 if side == 0 else -2.2
		var n := out if side == 0 else -out
		var base := a + dir * start + out * off
		# Parapet below the outer arcade only.
		if side == 0:
			lm.box("White", base + dir * length * 0.5 + Vector3(0, 0.5, 0), Vector3(length, 1.0, 0.6),
				Basis(dir, Vector3.UP, out))
		for i in bays + 1:
			var c := base + dir * pitch * float(i)
			lm.box("White", c + Vector3(0, oh * 0.5, 0), Vector3(0.7, oh, 0.7), Basis(dir, Vector3.UP, out))
		for i in bays:
			var c := base + dir * pitch * (float(i) + 0.5)
			var y0 := 1.0 if side == 0 else 0.0
			for s in [-0.18, 0.18]:
				LandmarkChParts.colonnette(lm, "Wall", c + dir * float(s) + Vector3(0, y0, 0), 0.12, oh - 0.9 - y0)
			LandmarkDetail.arch(lm, "Wall", c + Vector3(0, oh - 0.9, 0) + n * 0.1, n, pitch - 0.7, 0.25, 0.25)
		# Spandrel wall above the arcade.
		lm.box("White", base + dir * length * 0.5 + Vector3(0, oh + 0.55, 0), Vector3(length + 0.7, 1.1, 0.7),
			Basis(dir, Vector3.UP, out))
	# Roof slab, cornice and the crenel crest on the outer edge.
	var mid := a + dir * (start + length * 0.5)
	lm.box("Stone", mid + Vector3(0, oh + 1.25, 0), Vector3(length + 0.8, 0.3, 5.4), Basis(dir, Vector3.UP, out))
	LandmarkDetail.cornice(lm, "White", a + dir * start + out * 2.6 + Vector3(0, oh + 1.1, 0),
		a + dir * (start + length) + out * 2.6 + Vector3(0, oh + 1.1, 0), out, 0.45, true)
	LandmarkCeParts.merlons(lm, "White", a + dir * start + out * 2.4 + Vector3(0, oh + 1.4, 0),
		a + dir * (start + length) + out * 2.4 + Vector3(0, oh + 1.4, 0), 1.3, 0.6, 0.7, 0.4)

## Bronze equestrian St Stephen (Alajos Strobl, 1906) on its tall
## neo-Romanesque pedestal with corner colonnettes and relief panels.
static func _stephen(lm: LandmarkMesh, p: Vector3) -> void:
	lm.box("Stone", p + Vector3(0, 0.3, 0), Vector3(7.0, 0.6, 5.0))
	lm.box("White", p + Vector3(0, 0.9, 0), Vector3(6.0, 0.6, 4.0))
	lm.box("White", p + Vector3(0, 3.0, 0), Vector3(5.0, 3.6, 3.0))
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			LandmarkDetail.column(lm, "Wall", p + Vector3(sx * 2.4, 1.2, sz * 1.4), 0.18, 3.6, "tuscan", 0)
	for sz in [-1.0, 1.0]:
		lm.box("Bronze", p + Vector3(0, 3.0, sz * 1.52), Vector3(3.4, 2.2, 0.06), Basis(), 0.0)
	LandmarkDetail.cornice(lm, "White", p + Vector3(-2.6, 4.8, 1.6), p + Vector3(2.6, 4.8, 1.6), Vector3.BACK, 0.5)
	LandmarkDetail.cornice(lm, "White", p + Vector3(2.6, 4.8, -1.6), p + Vector3(-2.6, 4.8, -1.6), Vector3.FORWARD, 0.5)
	lm.box("White", p + Vector3(0, 5.5, 0), Vector3(5.4, 0.4, 3.4))
	# Horse: barrel, neck, head, four legs and tail; the king with orb.
	var hb := p + Vector3(0, 5.7, 0)
	lm.beam("Bronze", hb + Vector3(-1.1, 1.9, 0), hb + Vector3(1.0, 1.95, 0), 0.95, 1.1)
	lm.beam("Bronze", hb + Vector3(0.9, 2.2, 0), hb + Vector3(1.4, 3.2, 0), 0.5, 0.45)
	lm.beam("Bronze", hb + Vector3(1.35, 3.25, 0), hb + Vector3(1.9, 2.8, 0), 0.38, 0.3)
	for lx in [-0.8, 0.8]:
		for lz in [-0.3, 0.3]:
			var top := hb + Vector3(lx, 1.5, lz)
			var foot := hb + Vector3(lx + (0.35 if lx > 0.0 and lz > 0.0 else 0.0), 0.0, lz)
			lm.beam("Bronze", top, foot, 0.2, 0.2)
	lm.beam("Bronze", hb + Vector3(-1.1, 2.1, 0), hb + Vector3(-1.4, 1.0, 0), 0.2, 0.15)
	LandmarkKits.statue_figure(lm, "Bronze", hb + Vector3(-0.1, 1.9, 0), 2.3, true)
	lm.lathe("Bronze", hb + Vector3(-0.1, 4.1, 0), PackedVector2Array([Vector2(0.18, 0), Vector2(0.24, 0.12),
		Vector2(0.2, 0.28)]), 10)
