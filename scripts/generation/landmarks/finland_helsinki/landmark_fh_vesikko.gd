extends RefCounted

## Submarine Vesikko (CV-707, Finnish Navy 1933, a Type II coastal boat),
## a museum ship at Suomenlinna, Susisaari. She stands on dry land on four
## pairs of concrete cradles, bow +X, with her keel 0.7 m up.
##
## From the Commons photographs (visual-plan/refs/landmarks/vesikko_submarine/):
## - the pressure hull is minium red below the waterline mark and the
##   same red up to the deck line, with the hydroplane and the bow
##   ventilation grilles;
## - the upper casing is a flat-sided box painted in black and white
##   blocks with sloped joints (dazzle scheme), 3 m wide, carrying a rail
##   and a wire from the bow past the tower to the stern;
## - the conning tower is black at the foot, a yellow band, white above,
##   with a periscope standard and a mast, and a 20 mm gun forward of it;
## - a stair and rail lead up to the open hatch in the hull side amidships;
## - a sawtooth net cutter stands on the bow.
##
## Measured from OSM (way 123034962, tagged historic=ship): 40.2 m long
## and 4.0 m wide, long axis 94 deg from east toward south (almost
## north-south), so yaw 94 puts the bow on +X toward the south. Which end
## is the bow is not verified (the outline is nearly symmetric). Published
## 40.9 x 4.1 m. Estimated from the photographs: the cradle height, the
## casing and tower heights and the camouflage block lengths.

const U = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")

const ENTRY := {"type": "vesikko_submarine", "name": "Submarine Vesikko", "lat": 60.142591, "lon": 24.989606,
	"radius_m": 1500.0, "wiki_title": "Vesikko (submarine)", "height_m": 8.2, "clear_m": 24.0,
	"yaw_deg": 94.0, "kind": "Submarine", "aliases": ["submarine vesikko", "sukellusvene vesikko", "ubåten vesikko"]}

const HALF := 20.4
const AXIS_Y := 2.75
const RADIUS := 2.0
const CRADLE := 0.7

## Hull radius share along the length (-1 stern .. +1 bow): full amidships,
## a long taper aft, a finer entry forward.
static func _share(t: float) -> float:
	var a := absf(t)
	if t >= 0.0:
		return sqrt(clampf(1.0 - pow(maxf(a - 0.55, 0.0) / 0.45, 2.0), 0.0, 1.0))
	return sqrt(clampf(1.0 - pow(maxf(a - 0.45, 0.0) / 0.55, 2.0), 0.0, 1.0))

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Red", LandmarkMaterials.paint("#9E3F2B", 0.6, 0.35))
	lm.use("White", LandmarkMaterials.paint("#E4E5E0", 0.55, 0.3))
	lm.use("Black", LandmarkMaterials.paint("#2A2D2F", 0.55, 0.35))
	lm.use("Yellow", LandmarkMaterials.paint("#D9A92B", 0.55, 0.2))
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#9A978F", 3.0))
	lm.use("Iron", LandmarkMaterials.paint("#23262A", 0.5, 0.5))
	lm.use("Gravel", LandmarkMaterials.pbr("gravel", "#A9A08C", 3.0))
	lm.box("Gravel", Vector3(0, 0.03, 0), Vector3(46.0, 0.06, 9.0))
	_hull(lm)
	_casing(lm)
	_tower(lm)
	_cradles(lm)
	_stair(lm)
	_rig(lm)
	lm.commit(model)

static func _hull(lm: LandmarkMesh) -> void:
	var rows: Array = []
	var n := 28
	for k in n + 1:
		var t := -1.0 + 2.0 * float(k) / float(n)
		var x := t * HALF
		var r := RADIUS * _share(t)
		var ring := PackedVector3Array()
		for i in 17:
			var a := TAU * float(i) / 16.0
			# Slightly flattened underside, full top.
			var y := AXIS_Y + sin(a) * r * (0.92 if sin(a) < 0.0 else 1.0)
			ring.append(Vector3(x, y, cos(a) * r * 1.0))
		rows.append(ring)
	lm.grid("Red", rows, Vector3(0, AXIS_Y, 0), true)
	# Hydroplane (forward) and aft planes: thin fins either side.
	for s in [-1.0, 1.0]:
		lm.box("Red", Vector3(HALF * 0.52, AXIS_Y - 0.2, s * 2.5), Vector3(1.8, 0.1, 1.5), Basis(Vector3.UP, s * 0.18))
		lm.box("Red", Vector3(-HALF * 0.9, AXIS_Y - 0.1, s * 1.1), Vector3(1.4, 0.1, 1.2))

## The casing: black and white blocks, sloped joints, with a rail.
static func _casing(lm: LandmarkMesh) -> void:
	var y0 := AXIS_Y + 1.15
	var h := 1.1
	var x := -HALF * 0.86
	var end := HALF * 0.9
	var i := 0
	while x < end:
		var w := 3.6 if i % 2 == 0 else 2.6
		w = minf(w, end - x)
		var key := "Black" if i % 2 == 0 else "White"
		# Each block is a prism with sloped ends: a hull-width box turned
		# 10 degrees about the vertical so the joints read oblique.
		lm.box(key, Vector3(x + w * 0.5, y0 + h * 0.5, 0.0), Vector3(w + 0.5, h, 3.1))
		x += w
		i += 1
	# Deck and rail.
	lm.box("Black", Vector3(0.0, y0 + h + 0.03, 0.0), Vector3(2.0 * (end - 0.5), 0.06, 2.8))
	for s in [-1.0, 1.0]:
		lm.beam("Iron", Vector3(-end + 1.0, y0 + h + 0.9, s * 1.45), Vector3(end - 1.0, y0 + h + 0.9, s * 1.45), 0.04, 0.04)
		for k in 14:
			var px := lerpf(-end + 1.0, end - 1.0, float(k) / 13.0)
			lm.beam("Iron", Vector3(px, y0 + h, s * 1.45), Vector3(px, y0 + h + 0.9, s * 1.45), 0.04, 0.04)

## Conning tower: black foot, yellow band, white upper, periscope, mast.
static func _tower(lm: LandmarkMesh) -> void:
	var y0 := AXIS_Y + 2.25
	var cx := -2.0
	U.blk(lm, "Black", cx, y0, 0.0, 4.6, 1.0, 2.5)
	U.blk(lm, "Yellow", cx, y0 + 1.0, 0.0, 4.62, 0.4, 2.52)
	U.blk(lm, "White", cx, y0 + 1.4, 0.0, 4.5, 1.0, 2.4)
	U.blk(lm, "Black", cx, y0 + 2.4, 0.0, 4.6, 0.12, 2.5)
	# Bridge screen and the open hatch panel.
	U.blk(lm, "Iron", cx + 2.1, y0 + 2.4, 0.0, 0.1, 0.8, 2.4)
	lm.beam("Iron", Vector3(cx - 0.8, y0 + 2.4, 0), Vector3(cx - 0.8, y0 + 3.2, 0), 0.12, 0.12)
	lm.beam("Iron", Vector3(cx + 0.9, y0 + 2.4, 0), Vector3(cx + 0.9, y0 + 3.0, 0), 0.1, 0.1)
	# 20 mm gun on the casing forward of the tower.
	var gy := AXIS_Y + 2.25
	lm.frustum("Iron", Vector3(HALF * 0.3, gy, 0.0), 0.35, 0.25, 0.6, 8)
	lm.beam("Iron", Vector3(HALF * 0.3, gy + 0.7, 0.0), Vector3(HALF * 0.3 + 1.1, gy + 0.95, 0.0), 0.07, 0.07)

static func _cradles(lm: LandmarkMesh) -> void:
	for x in [-14.0, -5.0, 5.0, 13.5]:
		for s in [-1.0, 1.0]:
			U.blk(lm, "Concrete", x, 0.0, s * 1.5, 1.0, 1.0 + 0.0, 1.2)
			lm.box("Concrete", Vector3(x, 0.9, s * 1.3), Vector3(1.0, 0.25, 1.6))

## The stair and the open hull door amidships, with its fence.
static func _stair(lm: LandmarkMesh) -> void:
	var x := 3.0
	for k in 6:
		U.blk(lm, "Iron", x, 0.3 + 0.4 * float(k), 3.0 + float(k) * 0.4, 1.2, 0.08, 0.4)
	lm.box("Black", Vector3(x, 2.2, 2.0), Vector3(0.9, 1.2, 0.12), Basis(Vector3.RIGHT, -0.4))
	for s in [-1.0, 1.0]:
		lm.beam("Iron", Vector3(x + s * 0.65, 1.3, 2.9), Vector3(x + s * 0.65, 2.9, 5.4), 0.05, 0.05)
	# Low fence along the long side.
	lm.beam("Iron", Vector3(-17.0, 0.9, 4.2), Vector3(17.0, 0.9, 4.2), 0.04, 0.04)
	for k in 12:
		var px := lerpf(-17.0, 17.0, float(k) / 11.0)
		lm.beam("Iron", Vector3(px, 0.0, 4.2), Vector3(px, 0.95, 4.2), 0.04, 0.04)

## The sawtooth net cutter on the bow and the antenna wire.
static func _rig(lm: LandmarkMesh) -> void:
	var by := AXIS_Y + 2.3
	lm.beam("Iron", Vector3(HALF - 1.0, by + 0.3, 0.0), Vector3(HALF - 5.0, by + 1.4, 0.0), 0.08, 0.08)
	lm.beam("Iron", Vector3(HALF - 5.0, by + 1.4, 0.0), Vector3(HALF - 5.0, by - 0.1, 0.0), 0.06, 0.06)
	for k in 6:
		var p := Vector3(HALF - 1.0 - float(k) * 0.7, by + 0.35 + float(k) * 0.18, 0.0)
		lm.box("Iron", p + Vector3(0, 0.12, 0), Vector3(0.25, 0.26, 0.1), Basis(Vector3.BACK, 0.8))
	var top := Vector3(-2.0 - 0.8, AXIS_Y + 5.45, 0.0)
	lm.beam("Iron", top, Vector3(HALF - 5.0, by + 1.4, 0.0), 0.03, 0.03)
	lm.beam("Iron", top, Vector3(-HALF * 0.85, AXIS_Y + 2.5, 0.0), 0.03, 0.03)
