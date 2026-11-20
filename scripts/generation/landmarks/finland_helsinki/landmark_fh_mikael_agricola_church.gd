extends RefCounted

## Mikael Agricola Church (Lars Sonck, 1935), Tehtaankatu 23, Ullanlinna. The
## registry yaw (-36.1) turns the model's +Z, the front with the tower, onto
## the south-east, the street side; the origin is the centre of the 63.7 x
## 59 m OSM outline (way 123832057, nave and parish wings together).
##
## From the Commons photos in visual-plan/refs/landmarks/mikael_agricola_church/:
## - a very tall, slightly tapering rectangular tower of dark red-brown brick,
##   plain but for a band of corbelled brick under a small slit window at
##   about two fifths of its height and a corbel course at the top;
## - above it a stepped crown of pale-green copper: three setbacks of narrow
##   vertical fins, a little neck, and a needle spire with a cross, 97 m in
##   all;
## - at its foot a deep entrance recess with bronze doors and a granite
##   surround, reached by a broad flight of about 17 granite steps between
##   two pink-grey granite blocks with doors;
## - the church stands on a terrace of the same pink-grey granite, a
##   rusticated retaining wall along Tehtaankatu;
## - the long brick nave block and the parish wings stay low (11.55 m by
##   OSM), flat-looking copper roofs behind a brick parapet, small windows.
##
## Measured: outline, nave height 11.55 m (OSM tag) and the tower's 9.4 m
## width at the base. Estimated from photos: the 4 m terrace, the taper (10 m
## at the base to 7.6 m below the crown), the corbel band at 38 m, shaft top
## at 68 m, crown 7.8 m wide stepping to 2.4 m, an 18 m needle, the stair. The registry 97 m (to the cross
## tip) is Wikipedia's figure; LoD2 was not read in this run.

const U = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")
const P = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_parts.gd")
const F = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_mall_footprints.gd")
const W = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_west_footprints.gd")

const ENTRY := {"type": "mikael_agricola_church", "name": "Mikael Agricola Church", "lat": 60.158279, "lon": 24.938642,
	"radius_m": 1500.0, "wiki_title": "Mikael Agricola Church", "height_m": 97.0, "clear_m": 42.0,
	"yaw_deg": -36.1, "kind": "Church", "aliases": ["mikael agricola church", "mikael agricolan kirkko", "mikael agricola kyrkan"]}

const POLY := [Vector2(-16.0, 5.0), Vector2(-13.4, 6.6), Vector2(-0.4, 6.9), Vector2(-0.4, 18.7), Vector2(-16.6, 18.1),
	Vector2(-31.8, 9.2), Vector2(-9.2, -29.5), Vector2(30.6, -29.1), Vector2(31.8, 27.1), Vector2(26.4, 27.1),
	Vector2(26.4, 29.5), Vector2(17.1, 29.4), Vector2(17.0, 26.9), Vector2(10.8, 27.1), Vector2(11.1, -19.1),
	Vector2(-1.8, -18.6)]
const TERRACE := 4.0
const EAVE := 11.55
const TX := 21.7
const TZ := 22.2
const TW0 := 10.0
const TW1 := 7.6
const SHAFT_TOP := 68.0

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#7E3C2C", 2.5))
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#9C8680", 2.0))
	lm.use("Copper", LandmarkMaterials.paint("#58A58F", 0.5, 0.5))
	lm.use("Roof", LandmarkMaterials.paint("#5D6E66", 0.6, 0.4))
	lm.use("Glass", LandmarkMaterials.glass("#262B2F"))
	lm.use("Bronze", LandmarkMaterials.paint("#5B4A2E", 0.45, 0.7))
	lm.use("Steel", LandmarkMaterials.paint("#7E8286", 0.5, 0.6))
	var poly := PackedVector2Array(POLY)
	_base(lm, poly)
	_naves(lm, poly)
	_tower(lm)
	_stairs(lm)
	lm.commit(model)
	# Night: the tower and its green crown are floodlit from the terrace.
	var warm := Color(1.0, 0.94, 0.82)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(TX + 7.0, TERRACE + 0.6, TZ + 18.0), Vector3(TX, 40.0, TZ), 9.0, 1.0, 120.0, warm],
		[Vector3(TX - 7.0, TERRACE + 0.6, TZ + 18.0), Vector3(TX, 40.0, TZ), 9.0, 1.0, 120.0, warm],
		[Vector3(TX, TERRACE + 0.6, TZ + 20.0), Vector3(TX, 80.0, TZ), 6.0, 0.9, 150.0, Color(0.85, 1.0, 0.92)],
	])

## The granite terrace under the whole church, rusticated courses on its
## walls.
static func _base(lm: LandmarkMesh, poly: PackedVector2Array) -> void:
	lm.poly_prism("Granite", F.offset(poly, 1.2), 0.0, TERRACE)
	lm.poly_prism("Granite", F.offset(poly, 1.4), TERRACE - 0.3, TERRACE, false)
	# Front terrace wall toward the street, with its two door-blocks.
	var xs := [-4.0, 44.0]
	U.blk(lm, "Granite", (xs[0] + xs[1]) * 0.5, 0.0, 33.0, xs[1] - xs[0], TERRACE, 7.0)
	lm.box("Granite", Vector3((xs[0] + xs[1]) * 0.5, TERRACE - 0.1, 36.6), Vector3(xs[1] - xs[0] + 0.3, 0.3, 0.5))
	for x: float in [10.0, 34.0]:
		lm.box("Bronze", Vector3(x, 1.4, 36.55), Vector3(1.8, 2.8, 0.08))

## The low brick volumes under their flat-pitched copper roofs.
static func _naves(lm: LandmarkMesh, poly: PackedVector2Array) -> void:
	lm.poly_prism("Brick", poly, TERRACE, TERRACE + EAVE)
	lm.poly_prism("Granite", F.offset(poly, 0.1), TERRACE + EAVE - 0.4, TERRACE + EAVE, false)
	lm.poly_prism("Roof", F.offset(poly, 0.2), TERRACE + EAVE, TERRACE + EAVE + 0.35)
	W.edge_windows(lm, "Glass", poly, TERRACE + 3.2, 2, 3.8, 4.0, 1.0, 2.2, "Granite")

## The tapering brick tower, its corbel band, the stepped copper crown and
## the needle.
static func _tower(lm: LandmarkMesh) -> void:
	var y0 := TERRACE
	var n := 14
	for k in n:
		var t0 := float(k) / float(n)
		var t1 := float(k + 1) / float(n)
		var w0 := lerpf(TW0, TW1, t0)
		var w1 := lerpf(TW0, TW1, t1)
		var ya := y0 + (SHAFT_TOP - y0) * t0
		var yb := y0 + (SHAFT_TOP - y0) * t1
		lm.lathe("Brick", Vector3(TX, ya, TZ), PackedVector2Array([Vector2(w0 * 0.7071, 0), Vector2(w1 * 0.7071, yb - ya)]), 4, 1.0, 1.0, PI * 0.25, false)
	# Corbel band and slit at 38 m, parapet course at the top.
	lm.box("Brick", Vector3(TX, 37.0, TZ), Vector3(8.6, 0.5, 8.6))
	lm.box("Brick", Vector3(TX, 38.0, TZ), Vector3(8.8, 1.8, 8.8))
	lm.box("Granite", Vector3(TX, 38.9, TZ), Vector3(9.0, 0.3, 9.0))
	for s: float in [-1.0, 1.0]:
		lm.box("Glass", Vector3(TX, 44.0, TZ + s * 4.2), Vector3(0.5, 0.8, 0.1))
		lm.box("Glass", Vector3(TX + s * 4.2, 44.0, TZ), Vector3(0.1, 0.8, 0.5))
	lm.box("Granite", Vector3(TX, SHAFT_TOP - 0.3, TZ), Vector3(TW1 + 0.5, 0.6, TW1 + 0.5))
	# Entrance recess with the bronze doors, granite surround.
	lm.box("Granite", Vector3(TX, 6.0, TZ + 5.0), Vector3(7.6, 4.0, 0.5))
	lm.box("Bronze", Vector3(TX, 5.2, TZ + 5.28), Vector3(3.4, 3.2, 0.1))
	lm.box("Glass", Vector3(TX, 7.0, TZ + 5.3), Vector3(5.4, 0.3, 0.1))
	# Crown: three setbacks of fins, neck, needle with cross.
	var c := Vector3(TX, SHAFT_TOP, TZ)
	var steps := [[7.8, 2.8], [6.2, 2.6], [4.6, 2.8]]
	var y := 0.0
	for st: Array in steps:
		var w: float = st[0]
		var h: float = st[1]
		lm.box("Copper", c + Vector3(0, y + h * 0.5, 0), Vector3(w, h, w))
		for k in 7:
			var o := -w * 0.5 + w * (float(k) + 0.5) / 7.0
			lm.box("Copper", c + Vector3(o, y + h * 0.5, w * 0.5 + 0.1), Vector3(0.24, h, 0.2))
			lm.box("Copper", c + Vector3(o, y + h * 0.5, -w * 0.5 - 0.1), Vector3(0.24, h, 0.2))
			lm.box("Copper", c + Vector3(w * 0.5 + 0.1, y + h * 0.5, o), Vector3(0.2, h, 0.24))
			lm.box("Copper", c + Vector3(-w * 0.5 - 0.1, y + h * 0.5, o), Vector3(0.2, h, 0.24))
		y += h
	lm.box("Copper", c + Vector3(0, y + 1.0, 0), Vector3(2.4, 2.0, 2.4))
	lm.spire("Copper", c + Vector3(0, y + 2.0, 0), 1.0, 97.0 - SHAFT_TOP - y - 2.0 - 1.6, 0.0, 4)
	lm.box("Copper", c + Vector3(0, 97.0 - SHAFT_TOP - 0.9, 0), Vector3(0.1, 1.6, 0.1))
	lm.box("Copper", c + Vector3(0, 97.0 - SHAFT_TOP - 0.6, 0), Vector3(0.6, 0.1, 0.1))

## Broad granite stair up the terrace to the doors, rails either side.
static func _stairs(lm: LandmarkMesh) -> void:
	U.steps(lm, "Granite", Vector3(TX, 0, 36.3), Vector3.BACK, 11.0, 0.55, TERRACE / 14.0, 14)
	for s: float in [-1.0, 1.0]:
		lm.beam("Steel", Vector3(TX + s * 5.4, TERRACE + 0.9, 36.3), Vector3(TX + s * 5.4, 0.9, 44.0), 0.06, 0.06, Vector3.RIGHT)
