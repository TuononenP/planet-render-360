extends RefCounted

## Katarinahissen (1936, Slussen), origin at the foot of the lattice tower,
## the footbridge to Mosebacke running along +X. The registry yaw (96.5)
## turns +X onto the mapped bridge (OSM way 27345548, heading about 186
## degrees); the tower's own edges sit at 6.6 / 97.3.
##
## Measured off the Commons photos (visual-plan/refs/landmarks/katarinahissen/)
## against the 4.7 m wide lattice, and OSM (tower 4.7 x 4.5 m, 42.5 m top):
## - the tower is a black steel lattice: four 0.55 m legs on a 4.4 m
##   square, X-braced in six panels up to the walkway underside at 27.8 m,
##   a glazed lift shaft inside it with one car showing,
## - the walkway cantilevers from it for about 60 m: a dark brown clad
##   belly (1.4 m), the glazed restaurant band of Gondolen (2.4 m, mullions
##   every 2.4 m with diagonal bracing), a roof slab that is the public
##   promenade, with a railing at 1.1 m along both edges,
## - on the tower a dark clad head house (cab) with a glazed band, a smaller
##   machine room above it carrying the lit Coop sign board on both long
##   faces, a roof railing and two radio masts to 42.5 m,
## - at night the lattice and the promenade rail are strung with warm lights,
## - at the foot a low glazed lift hall beside the tower, on a concrete
##   plinth; the far end of the walkway lands on a concrete abutment at
##   Mosebacke.

const LEG := 2.2
const BELLY_Y := 27.8
const BELLY_TOP := 29.2
const GLASS_TOP := 31.6
const DECK_Y := 32.2
const WALK_X0 := 2.3
const WALK_X1 := 62.0
const WALK_HALF := 3.5
const HEAD_TOP := 38.6
const ROOM_TOP := 41.2
const TOP := 42.5

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Steel", LandmarkMaterials.paint("#1E2124", 0.6, 0.35))
	lm.use("Clad", LandmarkMaterials.pbr("concrete", "#3E3128", 2.5, 0.55, 0.25))
	lm.use("Glass", LandmarkMaterials.glass("#2C3A44"))
	lm.use("Conc", LandmarkMaterials.pbr("concrete", "#8B8883", 3.0))
	lm.use("Lamp", LandmarkMaterials.lit("#FFE0A8", 0.6))
	_lattice(lm)
	_walkway(lm)
	_rail(lm)
	_head_house(lm)
	_foot(lm)
	lm.commit(model)

## Four legs, X-braced panels on all faces, the glazed shaft and a lift car.
static func _lattice(lm: LandmarkMesh) -> void:
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			lm.beam("Steel", Vector3(float(sx) * LEG, 0.8, float(sz) * LEG),
				Vector3(float(sx) * LEG, DECK_Y, float(sz) * LEG), 0.55, 0.55)
	var top := BELLY_Y
	for face in 4:
		var n := Vector3(1, 0, 0).rotated(Vector3.UP, PI * 0.5 * float(face))
		var t := Vector3.UP.cross(n)
		var c := n * LEG
		lm.lattice_panel("Steel", c - t * LEG + Vector3.UP * 0.8, c + t * LEG + Vector3.UP * 0.8,
			c - t * LEG + Vector3.UP * top, c + t * LEG + Vector3.UP * top, 0.26, 6)
		# Warm string lights on the three big crossings of each face.
		for k in 3:
			var y0 := 0.8 + (top - 0.8) * float(k) / 3.0
			var y1 := 0.8 + (top - 0.8) * float(k + 1) / 3.0
			var o := n * 0.2
			lm.beam("Lamp", c - t * LEG + o + Vector3.UP * y0, c + t * LEG + o + Vector3.UP * y1, 0.07, 0.07)
			lm.beam("Lamp", c + t * LEG + o + Vector3.UP * y0, c - t * LEG + o + Vector3.UP * y1, 0.07, 0.07)
	lm.box("Glass", Vector3(0, 14.5, 0), Vector3(2.3, 27.0, 2.3), Basis(), 0.0)
	lm.box("Clad", Vector3(0, 10.4, 0), Vector3(2.0, 2.6, 2.0), Basis(), 0.0)
	lm.box("Clad", Vector3(0, 27.4, 0), Vector3(2.4, 0.8, 2.4), Basis(), 0.0)

## The cantilevered Gondolen walkway: belly, glazed band with bracing, roof slab.
static func _walkway(lm: LandmarkMesh) -> void:
	var len := WALK_X1 - WALK_X0
	var cx := (WALK_X0 + WALK_X1) * 0.5
	lm.box("Clad", Vector3(cx, (BELLY_Y + BELLY_TOP) * 0.5, 0), Vector3(len, BELLY_TOP - BELLY_Y, WALK_HALF * 2.0), Basis(), 0.0)
	lm.box("Glass", Vector3(cx, (BELLY_TOP + GLASS_TOP) * 0.5, 0), Vector3(len, GLASS_TOP - BELLY_TOP, WALK_HALF * 2.0 - 0.3), Basis(), 0.0)
	lm.box("Clad", Vector3(cx, (GLASS_TOP + DECK_Y) * 0.5, 0), Vector3(len, DECK_Y - GLASS_TOP, WALK_HALF * 2.0 + 0.4), Basis(), 0.0)
	var bays := 25
	var step := len / float(bays)
	for side in [-1.0, 1.0]:
		var z := float(side) * (WALK_HALF - 0.1)
		for i in bays + 1:
			var x := WALK_X0 + step * float(i)
			lm.beam("Steel", Vector3(x, BELLY_TOP, z), Vector3(x, GLASS_TOP, z), 0.14, 0.14)
		for i in bays:
			var x := WALK_X0 + step * float(i)
			var a := Vector3(x, BELLY_TOP, z)
			var b := Vector3(x + step, GLASS_TOP, z)
			if i % 2 == 1:
				a = Vector3(x + step, BELLY_TOP, z)
				b = Vector3(x, GLASS_TOP, z)
			lm.beam("Steel", a, b, 0.09, 0.09)
		# Pale name board on the belly: blocks standing for the lettering.
		for i in 8:
			lm.box("Lamp", Vector3(WALK_X0 + 22.0 + float(i) * 1.1, BELLY_Y + 0.7, z + float(side) * 0.06),
				Vector3(0.7, 0.7, 0.05), Basis(), 0.0)
	# The abutment where it lands on Mosebacke.
	lm.box("Conc", Vector3(WALK_X1 + 0.9, DECK_Y * 0.5, 0), Vector3(1.8, DECK_Y, WALK_HALF * 2.0 + 0.4), Basis(), 0.0)

## Promenade railing along both edges, with a string of lights on the handrail.
static func _rail(lm: LandmarkMesh) -> void:
	var len := WALK_X1 - WALK_X0
	var posts := 25
	var step := len / float(posts)
	for side in [-1.0, 1.0]:
		var z := float(side) * (WALK_HALF + 0.1)
		for i in posts + 1:
			var x := WALK_X0 + step * float(i)
			lm.beam("Steel", Vector3(x, DECK_Y, z), Vector3(x, DECK_Y + 1.1, z), 0.07, 0.07)
		lm.beam("Steel", Vector3(WALK_X0, DECK_Y + 1.1, z), Vector3(WALK_X1, DECK_Y + 1.1, z), 0.1, 0.1)
		lm.beam("Steel", Vector3(WALK_X0, DECK_Y + 0.55, z), Vector3(WALK_X1, DECK_Y + 0.55, z), 0.05, 0.05)
		lm.beam("Lamp", Vector3(WALK_X0, DECK_Y + 1.22, z), Vector3(WALK_X1, DECK_Y + 1.22, z), 0.06, 0.06)
	lm.beam("Steel", Vector3(WALK_X1, DECK_Y + 1.1, -WALK_HALF - 0.1), Vector3(WALK_X1, DECK_Y + 1.1, WALK_HALF + 0.1), 0.1, 0.1)

## The cab on the tower: clad head house with its glazed band, the machine
## room, the lit Coop sign boards, the roof railing and two masts.
static func _head_house(lm: LandmarkMesh) -> void:
	lm.box("Clad", Vector3(0, (DECK_Y - 0.2 + HEAD_TOP) * 0.5, 0), Vector3(5.6, HEAD_TOP - DECK_Y + 0.2, 5.6), Basis(), 0.0)
	lm.box("Glass", Vector3(0, 34.6, 0), Vector3(5.72, 2.4, 5.72), Basis(), 0.0)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			lm.beam("Steel", Vector3(float(sx) * 2.88, 33.4, float(sz) * 2.88),
				Vector3(float(sx) * 2.88, 35.8, float(sz) * 2.88), 0.16, 0.16)
	lm.box("Steel", Vector3(0, HEAD_TOP + 0.15, 0), Vector3(6.0, 0.3, 6.0), Basis(), 0.0)
	lm.box("Clad", Vector3(0, (HEAD_TOP + 0.3 + ROOM_TOP) * 0.5, 0), Vector3(3.6, ROOM_TOP - HEAD_TOP - 0.3, 3.6), Basis(), 0.0)
	lm.box("Steel", Vector3(0, ROOM_TOP + 0.1, 0), Vector3(3.9, 0.2, 3.9), Basis(), 0.0)
	# Sign boards on the long faces, lit at night.
	for side in [-1.0, 1.0]:
		lm.box("Lamp", Vector3(0, 38.2, float(side) * 2.95), Vector3(5.0, 3.0, 0.2), Basis(), 0.0)
		lm.box("Steel", Vector3(0, 38.2, float(side) * 2.84), Vector3(5.3, 3.3, 0.12), Basis(), 0.0)
	# Roof railing round the head house roof.
	var h := HEAD_TOP + 0.3
	for s in [-1.0, 1.0]:
		lm.beam("Steel", Vector3(-3.0, h + 1.0, float(s) * 3.0), Vector3(3.0, h + 1.0, float(s) * 3.0), 0.07, 0.07)
		lm.beam("Steel", Vector3(float(s) * 3.0, h + 1.0, -3.0), Vector3(float(s) * 3.0, h + 1.0, 3.0), 0.07, 0.07)
		for x in [-3.0, -1.0, 1.0, 3.0]:
			lm.beam("Steel", Vector3(float(x), h, float(s) * 3.0), Vector3(float(x), h + 1.0, float(s) * 3.0), 0.06, 0.06)
	for m in [Vector2(-0.7, 0.6), Vector2(0.9, -0.5)]:
		lm.beam("Steel", Vector3(m.x, ROOM_TOP + 0.2, m.y), Vector3(m.x, TOP, m.y), 0.12, 0.12)

## Concrete plinth under the lattice and the glazed lift hall beside it.
static func _foot(lm: LandmarkMesh) -> void:
	lm.box("Conc", Vector3(0, 0.4, 0), Vector3(6.4, 0.8, 6.4), Basis(), 0.0)
	lm.box("Conc", Vector3(-7.4, 2.0, 0), Vector3(9.0, 4.0, 8.0), Basis(), 0.0)
	lm.box("Glass", Vector3(-7.4, 1.9, 0), Vector3(9.1, 2.6, 8.1), Basis(), 0.0)
	lm.box("Conc", Vector3(-7.4, 4.25, 0), Vector3(9.6, 0.5, 8.6), Basis(), 0.0)
	for i in 6:
		var x := -11.4 + float(i) * 1.6
		for s in [-1.0, 1.0]:
			lm.beam("Steel", Vector3(x, 0.6, float(s) * 4.06), Vector3(x, 3.2, float(s) * 4.06), 0.1, 0.1)
