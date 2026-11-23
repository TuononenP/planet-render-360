extends RefCounted

## SkyWheel Helsinki (Katajanokanlaituri, 2014), 40 m. The wheel stands in
## the model's XY plane with the axle along Z; the registry yaw (-90.4) turns
## the plane north-south, as OSM way 457949936 does (a 36 x 2.4 m outline
## about 60.16673, 24.95945, "height=40").
##
## Read from the Commons photos in visual-plan/refs/landmarks/skywheel_helsinki/:
## - a thin white lattice rim in two planes about 2 m apart, with a second,
##   smaller concentric ring at about 0.6 of the radius;
## - sixteen lattice spokes, each a pair of chords braced by diagonals,
##   meeting a white spherical hub;
## - thirty enclosed, glazed gondolas (white frame, blue glass) mounted on
##   the outside of the rim and kept upright, one of them the dark-timber
##   VIP gondola;
## - an A-frame of four white legs on each side that splay along the axle
##   from the hub to the quay (the wheel is seen edge-on between them);
## - white LED outlines on the rim and ring that glow at night (the "Lamp"
##   part); the real wheel is lit in changing colours.
##
## Measured: 40 m height (OSM tag and the owner's figure), the plan outline
## and the yaw (OSM). Estimated from photos: rim radius 16.5 m, gondola size
## 2.0 x 2.3 x 2.0 m, leg spread, the boarding platform.

const U = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")

const ENTRY := {"type": "skywheel_helsinki", "skyline_priority": 1, "name": "SkyWheel Helsinki", "lat": 60.1667282, "lon": 24.9594489,
	"radius_m": 5000.0, "wiki_title": "SkyWheel Helsinki", "height_m": 40.0, "clear_m": 22.0,
	"yaw_deg": -90.4, "kind": "Observation wheel", "aliases": ["skywheel helsinki", "helsinki skywheel", "finnair skywheel"]}

const HUB_Y := 21.15
const RIM_R := 16.5
const PLANE_Z := 1.0
const SPOKES := 16
const CABINS := 30
const CAB_W := 2.0
const CAB_H := 2.3

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("White", LandmarkMaterials.paint("#EEF0EE", 0.45, 0.35))
	lm.use("Cabin", LandmarkMaterials.paint("#4C9CC6", 0.3, 0.15))
	lm.use("Dark", LandmarkMaterials.pbr("wood", "#3B2E25", 2.0))
	lm.use("Wood", LandmarkMaterials.pbr("wood", "#8E7656", 2.0))
	lm.use("Lamp", LandmarkMaterials.lit("#E8F0FF", 1.2))
	var hub := Vector3(0, HUB_Y, 0)
	for s: float in [-1.0, 1.0]:
		_rim(lm, hub, s)
		_spokes(lm, hub, s)
	# Hub: axle, a white sphere on each side and the two small dishes.
	lm.beam("White", hub + Vector3(0, 0, -3.0), hub + Vector3(0, 0, 3.0), 1.2)
	for s: float in [-1.0, 1.0]:
		lm.lathe("White", hub + Vector3(0, -1.7, s * 2.3), U.ball(1.7), 16)
		lm.disc("White", hub + Vector3(1.6, 1.4, s * 3.2), Vector3(0, 0, s), 0.6, 12)
	_legs(lm, hub)
	_cabins(lm, hub)
	# Boarding platform, a stair up to it and the low ticket hut.
	U.blk(lm, "Wood", 0.0, 0.0, 0.0, 20.0, 0.7, 9.0)
	U.steps(lm, "Wood", Vector3(0, 0, 4.5), Vector3.BACK, 6.0, 0.5, 0.17, 4)
	U.blk(lm, "Dark", 9.0, 0.7, 6.8, 4.5, 2.6, 3.5)
	lm.commit(model)

## One rim plane: an outer ring, an inner ring and radial rungs, the
## outer chord doubled in the "Lamp" part.
static func _rim(lm: LandmarkMesh, hub: Vector3, s: float) -> void:
	var z := s * PLANE_Z
	var n := 96
	for i in n:
		var a := TAU * float(i) / float(n)
		var b := TAU * float(i + 1) / float(n)
		var pa := hub + Vector3(cos(a), sin(a), 0) * RIM_R + Vector3(0, 0, z)
		var pb := hub + Vector3(cos(b), sin(b), 0) * RIM_R + Vector3(0, 0, z)
		lm.beam("White", pa, pb, 0.34, 0.34, Vector3.BACK)
		lm.beam("Lamp", pa + (pa - hub - Vector3(0, 0, z)).normalized() * 0.2, pb + (pb - hub - Vector3(0, 0, z)).normalized() * 0.2,
			0.1, 0.1, Vector3.BACK)
		var ra := hub + Vector3(cos(a), sin(a), 0) * RIM_R * 0.62 + Vector3(0, 0, z)
		var rb := hub + Vector3(cos(b), sin(b), 0) * RIM_R * 0.62 + Vector3(0, 0, z)
		lm.beam("Lamp" if i % 2 == 0 else "White", ra, rb, 0.1, 0.1, Vector3.BACK)
	# Rungs across the rim between the two planes, one every 3 degrees x 4.
	if s > 0.0:
		for i in 64:
			var a := TAU * float(i) / 64.0
			var p := hub + Vector3(cos(a), sin(a), 0) * RIM_R
			lm.beam("White", p + Vector3(0, 0, -PLANE_Z), p + Vector3(0, 0, PLANE_Z), 0.12, 0.12, Vector3.RIGHT)

## Sixteen lattice spokes in one plane: two chords braced by a zigzag.
static func _spokes(lm: LandmarkMesh, hub: Vector3, s: float) -> void:
	var z := Vector3(0, 0, s * PLANE_Z * 0.55)
	for i in SPOKES:
		var a := TAU * (float(i) + 0.5 * float(int(s > 0.0))) / float(SPOKES)
		var d := Vector3(cos(a), sin(a), 0)
		var side := Vector3(-d.y, d.x, 0) * 0.4
		var r0 := 1.3
		var steps := 7
		for k in steps:
			var t0 := lerpf(r0, RIM_R, float(k) / float(steps))
			var t1 := lerpf(r0, RIM_R, float(k + 1) / float(steps))
			var flip := 1.0 if k % 2 == 0 else -1.0
			lm.beam("White", hub + d * t0 + side * flip + z, hub + d * t1 - side * flip + z, 0.1, 0.1, Vector3.BACK)
		lm.beam("White", hub + d * r0 + side + z, hub + d * RIM_R + side + z, 0.16, 0.16, Vector3.BACK)
		lm.beam("White", hub + d * r0 - side + z, hub + d * RIM_R - side + z, 0.16, 0.16, Vector3.BACK)

## The A-frame: four legs a side, splayed along the axle to the platform.
static func _legs(lm: LandmarkMesh, hub: Vector3) -> void:
	for s: float in [-1.0, 1.0]:
		for x: float in [-9.0, -4.5, 4.5, 9.0]:
			var top := hub + Vector3(x * 0.1, 0.0, s * 2.6)
			lm.beam("White", top, Vector3(x, 0.7, s * 6.8), 0.55, 0.55, Vector3.BACK, true)
		for y: float in [6.0, 12.0]:
			var f := (HUB_Y - y) / (HUB_Y - 0.7)
			var xa := lerpf(0.9, 9.0, f)
			lm.beam("White", Vector3(-xa, y, s * lerpf(2.6, 6.8, f)), Vector3(xa, y, s * lerpf(2.6, 6.8, f)), 0.22, 0.22, Vector3.BACK)

## Thirty upright gondolas on the outside of the rim, one in dark timber.
static func _cabins(lm: LandmarkMesh, hub: Vector3) -> void:
	for i in CABINS:
		var a := PI * 0.5 + TAU * float(i) / float(CABINS)
		var c := hub + Vector3(cos(a), sin(a), 0) * (RIM_R + 1.2)
		var vip := i == 3
		var body := "Dark" if vip else "White"
		var hw := CAB_W * 0.5
		var hh := CAB_H * 0.5
		lm.box(body, c + Vector3(0, hh - 0.08, 0), Vector3(CAB_W + 0.1, 0.16, CAB_W + 0.1))
		lm.box(body, c + Vector3(0, -hh + 0.08, 0), Vector3(CAB_W + 0.1, 0.16, CAB_W + 0.1))
		for sx: float in [-1.0, 1.0]:
			for sz: float in [-1.0, 1.0]:
				lm.box(body, c + Vector3(sx * hw, 0, sz * hw), Vector3(0.14, CAB_H - 0.2, 0.14))
		lm.box("Dark" if vip else "Cabin", c, Vector3(CAB_W - 0.12, CAB_H - 0.4, CAB_W - 0.12))
		lm.box("White", c + Vector3(0, 0, 0), Vector3(CAB_W + 0.04, 0.12, CAB_W + 0.04))
