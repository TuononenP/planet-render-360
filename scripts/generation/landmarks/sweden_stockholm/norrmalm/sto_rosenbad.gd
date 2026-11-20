extends RefCounted

## Rosenbad, the Swedish government offices on Strömgatan (Boberg-style
## Jugend / Renaissance-revival, 1902). Origin at the OSM footprint centre
## (relation 279566, 83.9 x 65.6 m, bearing 62.6), long axis +X, so the
## registry yaw -27.4 turns +X onto ENE and +Z onto the water front (SSE,
## Strömgatan and Norrström). 38 m to the tower turrets (OSM height).
##
## From the photos (visual-plan/refs/landmarks/rosenbad/):
## - One closed block of five storeys round four courtyards (a cross of
##   inner ranges): a rusticated granite ground floor with round-headed
##   openings (a blind arcade along the east front), then four floors of
##   orange-salmon plaster with pale stone string courses and a stepped
##   cornice. 20 window bays on the south front, 16 on the east front.
## - The west 35 m of the south front is a brick-red wing (the older
##   Rosenbad) under a pale green copper mansard with a row of small
##   dormers; everything else wears a black sheet-metal mansard (steep
##   lower slope, shallow upper one) and brick chimney stacks.
## - The south-east corner carries the tower: an 11.5 m shaft with two
##   extra window storeys above the cornice, a pale stone crown with a
##   crenellated parapet and four pinnacle turrets with copper caps (the
##   38 m top). A smaller twin tower stands at the north-east corner.
## - On the south front, a stone portal with a balcony and, above it, a
##   two-storey stone oriel under a copper hip; a green copper dome with
##   a drum rises behind the north-west roof (OSM 37 m).
## Sources: docs/stockholm-landmark-sources.md (relation 279566, height 38);
## the Commons photos (front.jpg, quarter.jpg, aerial.jpg). Window rhythm and
## storey heights are scaled from front.jpg and the aerial, so approximate.

const Kit = preload("res://scripts/generation/landmarks/sweden_stockholm/palaces/sto_baroque_kit.gd")
const Nm = preload("res://scripts/generation/landmarks/sweden_stockholm/norrmalm/sto_nm_kit.gd")
const FhU = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")

const HX := 42.0
const HZ := 32.8
const PLINTH := 5.0
const EAVE := 24.5
const SILLS := [6.2, 10.55, 14.9, 19.25]
const PORTAL_X := 10.5
const TOWER_C := Vector2(36.25, 27.05)
const TOWER_W := 11.5
const TOWER_TOP := 33.0
const NE_C := Vector2(38.0, -28.8)
const NE_W := 8.0
## Mansard of the long ranges: [inset, rise] of the eave, the break, the top.
const MANSARD := [[0.0, 0.0], [3.0, 5.5], [7.0, 8.0]]
const MANSARD_LOW := [[0.0, 0.0], [3.0, 4.5], [7.0, 6.5]]

static func build(model: Node3D) -> void:
	var mats := _materials()
	var lm := Kit.fresh(mats)
	var win := Nm.window(mats, "Trim", 1.5, 2.6)
	_masses(lm)
	_courses(lm)
	_facades(lm, win)
	_portal(lm, mats)
	_roofs(lm, mats)
	_tower(lm, win, TOWER_C, TOWER_W, 3.4, 1.2, true)
	_tower(lm, win, NE_C, NE_W, 2.8, 1.0, false)
	_dome(lm)
	lm.commit(model)

static func _materials() -> Dictionary:
	return {
		"Wall": LandmarkMaterials.pbr("render", "#E2A07A", 3.0),
		"Brick": LandmarkMaterials.pbr("brick", "#A85A47", 3.0),
		"Stone": LandmarkMaterials.pbr("limestone", "#A99F8B", 2.6),
		"Trim": LandmarkMaterials.pbr("limestone", "#D6C8AA", 2.6),
		"Slate": LandmarkMaterials.pbr("slate", "#2C2F33", 2.5),
		"Copper": LandmarkMaterials.pbr("copper", "#8CAA9B", 2.0),
		"Iron": LandmarkMaterials.paint("#26282A"),
		"Glass": LandmarkMaterials.glass("#2A3238"),
	}

## The ring of ranges round four courtyards: the south range (brick wing in
## the west), the north range, west and east wings and the two cross ranges.
static func _masses(lm: LandmarkMesh) -> void:
	FhU.blk(lm, "Brick", -24.5, 0.0, 25.8, 35.0, EAVE, 14.0)
	FhU.blk(lm, "Wall", 17.5, 0.0, 25.8, 49.0, EAVE, 14.0)
	FhU.blk(lm, "Wall", 0.0, 0.0, -25.8, 84.0, EAVE, 14.0)
	FhU.blk(lm, "Wall", -35.0, 0.0, 0.0, 14.0, EAVE, 37.6)
	FhU.blk(lm, "Wall", 35.0, 0.0, 0.0, 14.0, EAVE, 37.6)
	FhU.blk(lm, "Wall", 0.0, 0.0, 0.0, 14.0, EAVE, 37.6)
	FhU.blk(lm, "Wall", 0.0, 0.0, 0.0, 56.0, EAVE, 14.0)
	# Granite ground floor with its cap course.
	Nm.ring(lm, "Stone", 0.0, 0.0, HX * 2.0, HZ * 2.0, 0.0, PLINTH, 0.4)
	Nm.ring(lm, "Trim", 0.0, 0.0, HX * 2.0, HZ * 2.0, PLINTH, 0.3, 0.6)

## String courses between the storeys and the stepped cornice.
static func _courses(lm: LandmarkMesh) -> void:
	for y in [9.15, 13.5, 17.85]:
		Nm.ring(lm, "Trim", 0.0, 0.0, HX * 2.0, HZ * 2.0, y, 0.3, 0.25)
	Nm.ring(lm, "Trim", 0.0, 0.0, HX * 2.0, HZ * 2.0, EAVE - 1.2, 0.5, 0.55)
	Nm.ring(lm, "Trim", 0.0, 0.0, HX * 2.0, HZ * 2.0, EAVE - 0.7, 0.7, 0.95)

## Window rows and the round-headed ground openings on the four outer fronts,
## and flat openings on the courtyard walls.
static func _facades(lm: LandmarkMesh, win: LandmarkMesh) -> void:
	# [a, b, out, bays]
	var runs := [
		[Vector3(-HX, 0, HZ), Vector3(HX, 0, HZ), Vector3(0, 0, 1), 20],
		[Vector3(HX, 0, -HZ), Vector3(HX, 0, HZ), Vector3(1, 0, 0), 16],
		[Vector3(-HX, 0, -HZ), Vector3(HX, 0, -HZ), Vector3(0, 0, -1), 20],
		[Vector3(-HX, 0, -HZ), Vector3(-HX, 0, HZ), Vector3(-1, 0, 0), 16],
	]
	for i in runs.size():
		var r: Array = runs[i]
		var n: int = r[3]
		for sill in SILLS:
			var skip: Array = []
			if i == 0 and (is_equal_approx(float(sill), 10.55) or is_equal_approx(float(sill), 14.9)):
				skip = [12]
			Kit.row(lm, win, r[0], r[1], r[2], float(sill), n, skip)
		for k in n:
			if i == 0 and k == 12:
				continue
			var p: Vector3 = (r[0] as Vector3).lerp(r[1], (float(k) + 0.5) / float(n))
			FhU.opening(lm, "Glass", p + Vector3(0, 0.9, 0) + (r[2] as Vector3) * 0.45, r[2], 1.7, 3.1, true)
	# Courtyard walls: flat dark openings, three storeys.
	for cx in [-17.5, 17.5]:
		for cz in [-12.9, 12.9]:
			_court(lm, float(cx), float(cz), 21.0, 11.8)

static func _court(lm: LandmarkMesh, cx: float, cz: float, w: float, d: float) -> void:
	for sill in [7.0, 12.2, 17.4]:
		var y := float(sill)
		FhU.openings(lm, "Glass", Vector3(cx - w * 0.5, 0, cz - d * 0.5), Vector3(cx + w * 0.5, 0, cz - d * 0.5),
			Vector3(0, 0, 1), y, 4, 1.3, 2.2, false, 0.05)
		FhU.openings(lm, "Glass", Vector3(cx - w * 0.5, 0, cz + d * 0.5), Vector3(cx + w * 0.5, 0, cz + d * 0.5),
			Vector3(0, 0, -1), y, 4, 1.3, 2.2, false, 0.05)

## South-front portal with its balcony and the stone oriel above it.
static func _portal(lm: LandmarkMesh, mats: Dictionary) -> void:
	var z := HZ + 0.4
	FhU.opening(lm, "Glass", Vector3(PORTAL_X, 0.2, z + 0.12), Vector3(0, 0, 1), 2.3, 3.8, true)
	for s in [-1.0, 1.0]:
		var sg: float = s
		lm.box("Trim", Vector3(PORTAL_X + sg * 1.65, 2.3, z + 0.2), Vector3(0.6, 4.6, 0.6), Basis(), 0.0)
	lm.box("Trim", Vector3(PORTAL_X, 4.85, z + 0.25), Vector3(4.0, 0.7, 0.7), Basis(), 0.0)
	FhU.steps(lm, "Stone", Vector3(PORTAL_X, 0.0, z), Vector3(0, 0, 1), 3.4, 0.35, 0.16, 3)
	lm.box("Trim", Vector3(PORTAL_X, 5.5, z + 0.7), Vector3(4.6, 0.3, 1.5), Basis(), 0.0)
	Kit.railing(lm, "Iron", Vector3(PORTAL_X - 2.2, 5.65, z + 1.4), Vector3(PORTAL_X + 2.2, 5.65, z + 1.4), 0.95)
	# Two-storey oriel: stone box, four panes a storey, a copper hip.
	var oz := HZ + 0.55
	lm.box("Trim", Vector3(PORTAL_X, 14.4, oz), Vector3(3.6, 9.6, 1.1), Basis(), 0.0)
	var pane := Nm.window(mats, "Trim", 0.75, 2.3)
	for sill in [10.55, 14.9]:
		for k in 3:
			Kit.put(lm, pane, Vector3(PORTAL_X + (float(k) - 1.0) * 1.1, float(sill), oz + 0.55), Vector3(0, 0, 1))
	lm.box("Trim", Vector3(PORTAL_X, 13.0, oz + 0.1), Vector3(3.9, 0.35, 1.3), Basis(), 0.0)
	Kit.hip(lm, "Copper", Vector3(PORTAL_X, 19.2, oz), 1.95, 0.8, [[0.0, 0.0], [0.75, 1.7]])

## Mansards, dormers and chimneys.
static func _roofs(lm: LandmarkMesh, mats: Dictionary) -> void:
	# [centre x, centre z, half x, half z, key, profile]
	var hips := [
		[-24.5, 25.8, 17.9, 7.4, "Copper", MANSARD],
		[10.5, 25.8, 17.5, 7.4, "Slate", MANSARD],
		[0.0, -25.8, 28.0, 7.4, "Slate", MANSARD],
		[-35.0, -7.0, 7.4, 26.2, "Slate", MANSARD],
		[35.0, 0.0, 7.4, 33.2, "Slate", MANSARD],
		[0.0, 0.0, 7.2, 18.8, "Slate", MANSARD_LOW],
		[0.0, 0.0, 28.0, 7.2, "Slate", MANSARD_LOW],
	]
	for h in hips:
		Kit.hip(lm, str(h[4]), Vector3(float(h[0]), EAVE, float(h[1])), float(h[2]), float(h[3]), h[5])
	# The brick wing's row of small copper dormers on the south slope.
	var dorm_cu := Nm.dormer(mats, "Copper")
	for i in 8:
		Kit.put(lm, dorm_cu, Vector3(-38.0 + float(i) * 4.2, 26.4, 31.8), Vector3(0, 0, 1))
	var dorm_sl := Nm.dormer(mats, "Slate")
	for i in 7:
		Kit.put(lm, dorm_sl, Vector3(41.0, 26.4, -28.0 + float(i) * 8.4), Vector3(1, 0, 0))
	for x in [-1.0, 11.0, 24.0]:
		Nm.chimney(lm, "Brick", "Stone", Vector3(float(x), 31.4, 25.8), 1.6, 1.6, 2.2)
	for z in [-16.0, 2.0, 16.0]:
		Nm.chimney(lm, "Brick", "Stone", Vector3(35.0, 31.4, float(z)), 1.6, 1.6, 2.2)
	for x in [-20.0, 0.0, 20.0]:
		Nm.chimney(lm, "Brick", "Stone", Vector3(float(x), 31.4, -25.8), 1.6, 1.6, 2.2)

## A corner tower: the shaft above the cornice with two window storeys, a
## stone crown with a crenellated parapet and four pinnacle turrets.
static func _tower(lm: LandmarkMesh, win: LandmarkMesh, c: Vector2, w: float, turret_h: float,
		cap_h: float, big: bool) -> void:
	var rise := TOWER_TOP - EAVE + 0.1
	FhU.blk(lm, "Wall", c.x, EAVE - 0.1, c.y, w, rise, w)
	Nm.ring(lm, "Trim", c.x, c.y, w, w, 28.3, 0.3, 0.25)
	Nm.ring(lm, "Trim", c.x, c.y, w, w, TOWER_TOP - 0.9, 0.9, 0.5)
	lm.box("Trim", Vector3(c.x, TOWER_TOP + 0.2, c.y), Vector3(w + 1.2, 0.4, w + 1.2), Basis(), 0.0)
	# Window storeys above the cornice, on the two street faces.
	var ex := c.x + w * 0.5
	var sz := c.y + w * 0.5 if big else c.y - w * 0.5
	var out_z := Vector3(0, 0, 1) if big else Vector3(0, 0, -1)
	var bays_z := [17, 18, 19]
	var bays_x := [13, 14, 15]
	if not big:
		bays_z = [18, 19]
		bays_x = [0, 1]
	for sill in [25.7, 29.4]:
		Kit.row(lm, win, Vector3(-HX, 0, sz), Vector3(HX, 0, sz), out_z, float(sill), 20, _except(20, bays_z))
		Kit.row(lm, win, Vector3(ex, 0, -HZ), Vector3(ex, 0, HZ), Vector3(1, 0, 0), float(sill), 16, _except(16, bays_x))
	# Crenellated parapet between the corner turrets.
	var top := TOWER_TOP + 0.4
	var hw := w * 0.5 - 0.15
	var tw := 1.3
	for s in [-1.0, 1.0]:
		var sg: float = s
		FhU.merlons(lm, "Trim", Vector3(c.x - hw + tw * 2.0, top, c.y + sg * hw), Vector3(c.x + hw - tw * 2.0, top, c.y + sg * hw),
			1.3, 0.75, 1.0, 0.5)
		FhU.merlons(lm, "Trim", Vector3(c.x + sg * hw, top, c.y - hw + tw * 2.0), Vector3(c.x + sg * hw, top, c.y + hw - tw * 2.0),
			1.3, 0.75, 1.0, 0.5)
	var tr := 1.1 if big else 0.9
	for sx in [-1.0, 1.0]:
		for sz2 in [-1.0, 1.0]:
			var p := Vector3(c.x + float(sx) * (w * 0.5 - tr), top, c.y + float(sz2) * (w * 0.5 - tr))
			Nm.turret(lm, "Trim", "Copper", p, tr * 2.0, turret_h, cap_h)

## Indices 0..n-1 except `keep` (the bays a row leaves bare).
static func _except(n: int, keep: Array) -> Array:
	var out: Array = []
	for i in n:
		if not keep.has(i):
			out.append(i)
	return out

## Green copper dome and drum behind the north-west roof.
static func _dome(lm: LandmarkMesh) -> void:
	var prof := PackedVector2Array([Vector2(3.8, 0.0), Vector2(3.8, 2.0), Vector2(4.15, 2.4), Vector2(3.9, 2.9),
		Vector2(3.2, 3.7), Vector2(2.2, 4.6), Vector2(1.2, 5.3), Vector2(0.6, 5.8), Vector2(0.25, 6.4)])
	lm.lathe("Copper", Vector3(-30.0, 31.0, -26.0), prof, 20)
	lm.frustum("Copper", Vector3(-30.0, 24.0, -26.0), 3.8, 3.8, 7.1, 16)
