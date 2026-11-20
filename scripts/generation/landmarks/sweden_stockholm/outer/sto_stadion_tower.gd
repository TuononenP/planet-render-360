class_name StoOuterStadionTower
extends RefCounted

## The two brick gate towers of Stockholms stadion (Torben Grut, 1912) and the
## row of flagpoles on the east end wall. Model frame of sto_stadion.gd:
## Sofiatornet (OSM way 779124619) 7.7 x 9.3 m at x 60.9..68.6, z -60.3..-51.0
## and Klocktornet (779124622) 7.0 x 7.9 m at x 62.5..69.5, z 52.5..60.5, both on
## the outer wall of the long sides. From the quarter and aerial photos: plain
## dark-red brick shafts with a few granite string courses and corbels,
## a stepped battlement and a lamp rig on top (40 m, OSM); the Klocktornet
## carries a verdigris-ringed clock over a pair of arched windows, on its
## field face (and on the street face).

const K = preload("res://scripts/generation/landmarks/sweden_stockholm/palaces/sto_pal_kit.gd")

const SHAFT_Y := 37.0
const TOP := 40.0

## Both towers; `inner` is the sign of the face that looks onto the pitch
## (-1 for the tower at +z, +1 for the one at -z in the local frame).
static func build(lm: LandmarkMesh) -> void:
	_tower(lm, Vector3(64.75, 0.0, -55.65), 7.7, 9.3, 1.0, false)
	_tower(lm, Vector3(66.0, 0.0, 56.5), 7.0, 7.9, -1.0, true)

static func _tower(lm: LandmarkMesh, c: Vector3, w: float, d: float, inner: float, clock: bool) -> void:
	K.rb(lm, "Brick", c.x - w * 0.5, c.x + w * 0.5, 0.0, SHAFT_Y, c.z - d * 0.5, c.z + d * 0.5, 0.0)
	K.rb(lm, "Stone", c.x - w * 0.5 - 0.25, c.x + w * 0.5 + 0.25, 0.0, 1.5, c.z - d * 0.5 - 0.25,
		c.z + d * 0.5 + 0.25, 0.0)
	# Granite string courses.
	for y in [9.0, 18.0, 29.0]:
		K.rb(lm, "Stone", c.x - w * 0.5 - 0.12, c.x + w * 0.5 + 0.12, float(y), float(y) + 0.4,
			c.z - d * 0.5 - 0.12, c.z + d * 0.5 + 0.12, 0.0)
	# Corbelled battlement.
	K.rb(lm, "Brick", c.x - w * 0.5 - 0.5, c.x + w * 0.5 + 0.5, SHAFT_Y, SHAFT_Y + 0.5,
		c.z - d * 0.5 - 0.5, c.z + d * 0.5 + 0.5, 0.0)
	var hx := w * 0.5 + 0.5
	var hz := d * 0.5 + 0.5
	var y0 := SHAFT_Y + 0.5
	LandmarkFhUtil.merlons(lm, "Brick", Vector3(c.x - hx, y0, c.z - hz), Vector3(c.x + hx, y0, c.z - hz), 1.8, 1.0, 1.0, 0.8)
	LandmarkFhUtil.merlons(lm, "Brick", Vector3(c.x - hx, y0, c.z + hz), Vector3(c.x + hx, y0, c.z + hz), 1.8, 1.0, 1.0, 0.8)
	LandmarkFhUtil.merlons(lm, "Brick", Vector3(c.x - hx, y0, c.z - hz), Vector3(c.x - hx, y0, c.z + hz), 1.8, 1.0, 1.0, 0.8)
	LandmarkFhUtil.merlons(lm, "Brick", Vector3(c.x + hx, y0, c.z - hz), Vector3(c.x + hx, y0, c.z + hz), 1.8, 1.0, 1.0, 0.8)
	# Slit windows on every face; the pair of arched windows on the clock tower.
	for out in [Vector3(0, 0, 1), Vector3(0, 0, -1), Vector3(1, 0, 0), Vector3(-1, 0, 0)]:
		var o: Vector3 = out
		var half := (d if absf(o.z) > 0.5 else w) * 0.5
		var p: Vector3 = c + o * (half + 0.03)
		K.holes(lm, "Void", p, o, [0.0], 14.0, 0.7, 2.4, true)
		K.holes(lm, "Void", p, o, [0.0], 32.0, 0.9, 2.6, true)
	if clock:
		for s in [-1.0, 1.0]:
			var o := Vector3(0, 0, float(s))
			var p := c + o * (d * 0.5 + 0.06) + Vector3(0, 26.0, 0)
			lm.disc("Copper", p + o * 0.04, o, 1.7, 16)
			lm.disc("Brick", p + o * 0.08, o, 1.35, 16)
			lm.beam("Frame", p + o * 0.12, p + o * 0.12 + Vector3(0.5, 0.9, 0), 0.12, 0.08)
			lm.beam("Frame", p + o * 0.12, p + o * 0.12 + Vector3(-0.9, -0.2, 0), 0.1, 0.08)
			K.holes(lm, "Void", c + o * (d * 0.5 + 0.03), o, [-0.55, 0.55], 20.5, 0.7, 1.8, true)
	_lamp_rig(lm, Vector3(c.x, y0, c.z), inner)

## The floodlight rig: a mast and a lamp panel facing the pitch.
static func _lamp_rig(lm: LandmarkMesh, base: Vector3, inner: float) -> void:
	lm.box("Frame", base + Vector3(0, 0.6, 0), Vector3(0.5, 1.2, 0.5), Basis(), 0.0)
	var panel := base + Vector3(0, 1.7, 0)
	lm.box("Frame", panel, Vector3(3.2, 1.6, 0.25), Basis(), 0.0)
	var o := Vector3(0, 0, inner)
	for ix in 4:
		for iy in 3:
			var q := panel + Vector3(-1.2 + 0.8 * float(ix), -0.5 + 0.5 * float(iy), 0.0) + o * 0.2
			lm.box("Lamp", q, Vector3(0.45, 0.35, 0.3), Basis(), 0.0)
	lm.box("Frame", Vector3(base.x, TOP - 0.1, base.z), Vector3(3.4, 0.2, 0.5), Basis(), 0.0)
