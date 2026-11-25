extends RefCounted

## Hötorgsskraporna (Hötorgscity, 1952-66, Sven Markelius and others), five
## slabs in one grouped model. Origin at the middle slab (OSM way 121854812),
## long axis along +X; the registry yaw (-25.2) turns it onto the mapped
## slabs (footprint bearing 90 + yaw = 64.8). The other four stand at the
## offsets the registry clears with `clear_offsets_m`, so the slab positions
## must not move (HOTORG_SLABS, derived from the same mapped centres).
##
## Every slab is 19 storeys and 61 m above its ground (the OSM `height=72`
## is above sea level, see docs/stockholm-landmark-sources.md) on a plan of
## 43.5 x 14.5 m (mapped 43.4-44.5 x 14.1-15.3 m).
##
## Each slab:
## - stands on a two-storey podium (7 m, 48 x 21 m) of pale stone with a
##   shop-front storey; the podium roof is the Sergelgången terrace, with a
##   glazed railing round its edge,
## - carries 17 storeys of curtain wall on the two long faces, its own
##   pattern for each slab (the photos show a different grid on each one):
##   1 pale ceramic rods on clear glass, 2 blue-green glass on pale spandrels,
##   3 bright aluminium grid, 4 terracotta-toned spandrels, 5 near-black
##   glass on pale mullions (the SSE slab to the NNW one),
## - is closed at both short ends by a blind pale stone wall, the curtain
##   wall stopping 1.6 m short of it,
## - has a stone parapet and a plant penthouse on the roof, with its lift
##   overrun, a duct block and radio masts; the highest mast tops 61.9 m.
## Covered bridges are not built between the slabs: the Sergelgången
## bridges are open decks at terrace level, 6 m wide with a glazed rail,
## joining the podium roofs across the cross streets.
##
## The facade surfaces are SkyKit curtain-wall materials, so the windows
## light at night like the generated towers' (FacadeShader).

const SLABS := [Vector2(-57.2, -65.3), Vector2(-28.7, -33.7), Vector2(0.0, 0.0),
	Vector2(30.0, 30.1), Vector2(58.9, 64.1)]
## [curtain finish, bay width m, plant penthouse (x offset, length, depth)].
const STYLES := [["ceramic_rods", 2.4, [-4.0, 22.0, 7.0]], ["lowe_blue", 2.4, [3.0, 20.0, 8.0]],
	["intl_aluminium", 3.0, [-2.0, 24.0, 7.5]], ["pale_terracotta", 2.7, [5.0, 18.0, 8.0]],
	["black_glass", 2.6, [-5.0, 21.0, 7.0]]]

const W := 43.5
const D := 14.5
const PODIUM_W := 48.0
const PODIUM_D := 21.0
const PODIUM_TOP := 7.0
const ROOF := 57.6
const PARAPET := 58.3
const PLANT_TOP := 61.0
const END_PIER := 1.6
const STOREY := 2.98

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Roof", LandmarkMaterials.pbr("concrete", "#6C6C6A", 4.0))
	lm.use("End", LandmarkMaterials.pbr("limestone", "#D5D0C4", 3.0))
	lm.use("Plant", LandmarkMaterials.pbr("concrete", "#8E918F", 3.0))
	lm.use("Steel", LandmarkMaterials.paint("#41464A", 0.55, 0.4))
	var kit := SkyKit.new(lm)
	kit.wall("Podium", "white_granite", 3.0, 3.5)
	for i in STYLES.size():
		kit.wall("Slab%d" % i, str(STYLES[i][0]), float(STYLES[i][1]), STOREY)
	for i in SLABS.size():
		_slab(lm, kit, i)
	for i in SLABS.size() - 1:
		_bridge(lm, SLABS[i], SLABS[i + 1])
	lm.commit(model)

static func _slab(lm: LandmarkMesh, kit: SkyKit, i: int) -> void:
	var c: Vector2 = SLABS[i]
	# Podium and its terrace edge.
	kit.prism("Podium", SkyKit.rect(PODIUM_W, PODIUM_D, c.x, c.y), 0.0, PODIUM_TOP, "Roof")
	_terrace_rail(lm, c)
	# The blind-ended stone core, its curtain walls and parapet.
	lm.poly_prism("End", SkyKit.rect(W, D, c.x, c.y), PODIUM_TOP, ROOF, false)
	lm.poly_prism("Roof", SkyKit.rect(W, D, c.x, c.y), ROOF, ROOF + 0.02, true)
	var x0 := c.x - W * 0.5 + END_PIER
	var x1 := c.x + W * 0.5 - END_PIER
	var key := "Slab%d" % i
	kit.face(key, Vector2(x0, c.y + D * 0.5 + 0.08), Vector2(x1, c.y + D * 0.5 + 0.08), PODIUM_TOP, ROOF, Vector3(0, 0, 1))
	kit.face(key, Vector2(x1, c.y - D * 0.5 - 0.08), Vector2(x0, c.y - D * 0.5 - 0.08), PODIUM_TOP, ROOF, Vector3(0, 0, -1))
	_parapet(lm, c)
	_plant(lm, c, STYLES[i][2] as Array, i)

## Glazed railing round the podium roof.
static func _terrace_rail(lm: LandmarkMesh, c: Vector2) -> void:
	var hx := PODIUM_W * 0.5 - 0.15
	var hz := PODIUM_D * 0.5 - 0.15
	var y := PODIUM_TOP
	for s in [-1.0, 1.0]:
		lm.beam("Steel", Vector3(c.x - hx, y + 1.1, c.y + float(s) * hz), Vector3(c.x + hx, y + 1.1, c.y + float(s) * hz), 0.08, 0.08)
		lm.beam("Steel", Vector3(c.x + float(s) * hx, y + 1.1, c.y - hz), Vector3(c.x + float(s) * hx, y + 1.1, c.y + hz), 0.08, 0.08)
		for k in 17:
			var x := c.x - hx + (hx * 2.0) * float(k) / 16.0
			lm.beam("Steel", Vector3(x, y, c.y + float(s) * hz), Vector3(x, y + 1.1, c.y + float(s) * hz), 0.06, 0.06)
		for k in 8:
			var z := c.y - hz + (hz * 2.0) * float(k) / 7.0
			lm.beam("Steel", Vector3(c.x + float(s) * hx, y, z), Vector3(c.x + float(s) * hx, y + 1.1, z), 0.06, 0.06)

## Stone parapet round the slab roof (four slim boxes).
static func _parapet(lm: LandmarkMesh, c: Vector2) -> void:
	var h := PARAPET - ROOF
	for s in [-1.0, 1.0]:
		lm.box("End", Vector3(c.x, ROOF + h * 0.5, c.y + float(s) * (D * 0.5 - 0.2)), Vector3(W, h, 0.4), Basis(), 0.0)
		lm.box("End", Vector3(c.x + float(s) * (W * 0.5 - 0.2), ROOF + h * 0.5, c.y), Vector3(0.4, h, D - 0.8), Basis(), 0.0)

## Roof plant: penthouse, lift overrun, duct block, radio masts.
static func _plant(lm: LandmarkMesh, c: Vector2, p: Array, i: int) -> void:
	var h := PLANT_TOP - ROOF
	var px := c.x + float(p[0])
	lm.box("Plant", Vector3(px, ROOF + h * 0.5, c.y), Vector3(float(p[1]), h, float(p[2])), Basis(), 0.0)
	lm.box("Roof", Vector3(px, PLANT_TOP + 0.1, c.y), Vector3(float(p[1]) + 0.4, 0.2, float(p[2]) + 0.4), Basis(), 0.0)
	var side := -1.0 if i % 2 == 0 else 1.0
	lm.box("Plant", Vector3(c.x - float(p[0]) * 1.8, ROOF + 1.45, c.y + side * 2.6), Vector3(5.0, 2.9, 3.0), Basis(), 0.0)
	lm.box("Steel", Vector3(px + float(p[1]) * 0.3, PLANT_TOP + 0.5, c.y - side * 1.5), Vector3(4.0, 0.8, 1.4), Basis(), 0.0)
	for m in 3:
		var mx := px - float(p[1]) * 0.4 + float(m) * float(p[1]) * 0.35
		var top := PLANT_TOP + 0.7 if m != 1 else 61.9
		lm.beam("Steel", Vector3(mx, PLANT_TOP + 0.2, c.y + side * 1.2), Vector3(mx, top, c.y + side * 1.2), 0.12, 0.12)
	lm.beam("Steel", Vector3(px - 2.5, 61.5, c.y + side * 1.2), Vector3(px + 2.5, 61.5, c.y + side * 1.2), 0.08, 0.08)

## An open bridge deck between the podium roofs of two slabs, over the
## cross street, centred on the overlap of their podiums.
static func _bridge(lm: LandmarkMesh, a: Vector2, b: Vector2) -> void:
	var x := (a.x + b.x) * 0.5
	var z0 := a.y + PODIUM_D * 0.5 - 0.2
	var z1 := b.y - PODIUM_D * 0.5 + 0.2
	var zc := (z0 + z1) * 0.5
	lm.box("Roof", Vector3(x, PODIUM_TOP - 0.45, zc), Vector3(6.0, 0.9, z1 - z0), Basis(), 0.0)
	for s in [-1.0, 1.0]:
		lm.beam("Steel", Vector3(x + float(s) * 2.9, PODIUM_TOP + 1.1, z0), Vector3(x + float(s) * 2.9, PODIUM_TOP + 1.1, z1), 0.08, 0.08)
		var n := maxi(int((z1 - z0) / 2.0), 2)
		for k in n + 1:
			var z := z0 + (z1 - z0) * float(k) / float(n)
			lm.beam("Steel", Vector3(x + float(s) * 2.9, PODIUM_TOP, z), Vector3(x + float(s) * 2.9, PODIUM_TOP + 1.1, z), 0.06, 0.06)
