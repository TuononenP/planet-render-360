extends RefCounted

## Lonna, the former naval mine-depot island off Katajanokka, now a
## restaurant and sauna island. The model is the working cluster at the
## island's centre: the old smithy (Miinapaja, now the restaurant), the
## mine laboratory, the guard house, the depot shed and a ruin, plus the
## small new sauna by the west jetty. Frame: origin at the cluster centre,
## front +Z; registry yaw 27 lays +X on the depots' long axis.
##
## What the photographs show (visual-plan/refs/landmarks/lonna_island/):
## the old buildings are one and a half storey, steep dark-metal gables,
## walls in red brick or yellow-ochre plaster with white-framed windows,
## stone plinths; the sauna is a low cream timber box with a black
## standing-seam hipped roof, dormers and a chimney; the shore is bare
## pink granite with scrub and large trees behind.
##
## Measured from OSM: each building's footprint, position and the long
## axis (27 deg), and the restaurant node (inside Miinapaja). The
## old registry point lay 490 m west of the island. Which wall colour
## each old building wears is read from the photographs and not
## verified building by building. Heights are estimated.

const U = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")
const K = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_g_kit.gd")
const FhP = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_parts.gd")

const ENTRY := {"type": "lonna_island", "name": "Lonna", "lat": 60.15432, "lon": 24.99057,
	"radius_m": 1500.0, "wiki_title": "Lonna", "height_m": 11.5, "clear_m": 58.0,
	"yaw_deg": 27.0, "kind": "Island", "aliases": ["lonna", "lonna island", "lonnan saari", "lonna helsinki"]}

const BASE := 1.5

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#A04F3A", 2.5))
	lm.use("Ochre", LandmarkMaterials.pbr("render", "#D9A941", 3.0))
	lm.use("Timber", LandmarkMaterials.pbr("wood", "#D8C8A4", 2.0))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#F1EEE4", 2.0))
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#7A746C", 3.0))
	lm.use("Roof", LandmarkMaterials.paint("#34383B", 0.55, 0.5))
	lm.use("Window", LandmarkMaterials.glass("#2B3640"))
	lm.use("Rock", LandmarkMaterials.pbr("rock", "#9A8A82", 4.0))
	lm.use("Deck", LandmarkMaterials.pbr("wood", "#A78A66", 1.2))
	lm.use("Lamp", LandmarkMaterials.lit("#FFE2A8", 0.8))
	# Shore rock under the cluster: one broad ledge.
	K.ledge(lm, "Rock", 52.0, 40.0, BASE, 28)
	var y0 := BASE
	# Restaurant (old smithy), brick, ridge along X.
	_depot_x(lm, "Brick", 7.0, 21.0, y0, 30.0, 12.0, 5.2, 3.6, 9, 1.3, 2.3)
	# Mine laboratory, ochre plaster.
	_depot_x(lm, "Ochre", 4.0, -18.0, y0, 22.0, 20.0, 5.4, 4.6, 6, 1.2, 2.0)
	# Demagnetisation shed, low red brick.
	_depot_x(lm, "Brick", 6.0, 38.0, y0, 30.0, 8.0, 4.0, 2.6, 10, 1.0, 1.6)
	# Guard house, ochre, ridge along Z (a 25 m long 18 m wide hall).
	_hall_z(lm, y0, 31.0, -1.5, 18.0, 25.0)
	# Depot shed, ochre, long along Z.
	_hall_z(lm, y0, -29.0, 12.5, 10.0, 35.0)
	# Stone shell of the ruin.
	for k in 4:
		var z := -2.0 + float(k) * 7.0
		U.blk(lm, "Granite", -37.0, y0, z, 1.0, 1.6 + float(k % 2) * 0.8, 6.0)
	_sauna(lm, y0)
	_jetties(lm)
	lm.commit(model)
	var lantern := Color(1.0, 0.82, 0.56)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(7.0, 1.2, 46.0), Vector3(7.0, 5.0, 27.0), 50.0, 0.9, 50.0, lantern],
		[Vector3(-14.0, 1.2, -32.0), Vector3(4.0, 5.5, -18.0), 50.0, 0.85, 50.0, lantern],
		[Vector3(46.0, 1.2, -2.0), Vector3(31.0, 5.0, -2.0), 50.0, 0.85, 45.0, lantern],
		[Vector3(-42.0, 1.2, -40.0), Vector3(-32.5, 3.6, -35.0), 46.0, 0.9, 32.0, lantern],
	])

## 19th-century mine-depot hall with ridge along X: rough stone plinth,
## corner pilasters, arched windows with stone lintels, standing-seam roof.
static func _depot_x(lm: LandmarkMesh, wall: String, cx: float, cz: float, y0: float,
		w: float, d: float, h: float, rise: float, cols: int, ww: float, wh: float) -> void:
	U.blk(lm, "Granite", cx, y0, cz, w + 0.4, 0.65, d + 0.4)
	U.blk(lm, wall, cx, y0 + 0.65, cz, w, h - 0.65, d)
	U.blk(lm, "Trim", cx, y0 + h - 0.25, cz, w + 0.35, 0.25, d + 0.35)
	U.ridge_x(lm, "Roof", wall, Vector3(cx, y0 + h, cz), w + 0.4, d + 0.9, rise, 0.0)
	_standing_seams_x(lm, cx, cz, y0 + h, w + 0.4, d + 0.9, rise)
	for s: float in [-1.0, 1.0]:
		var fz := cz + s * d * 0.5
		FhP.win_row(lm, "Trim", "Window", Vector3(cx - w * 0.5 + 1.6, y0, fz),
			Vector3(cx + w * 0.5 - 1.6, y0, fz), Vector3(0, 0, s), 1.4, cols, ww, wh, true, 0.16)
		var gx := cx + s * w * 0.5
		FhP.win_row(lm, "Trim", "Window", Vector3(gx, y0, cz - d * 0.22),
			Vector3(gx, y0, cz + d * 0.22), Vector3(s, 0, 0), 1.4, 2, ww * 0.9, wh * 0.9, true, 0.16)
		LandmarkDetail.window(lm, "Trim", "Window", Vector3(gx, y0 + h + rise * 0.42, cz) + Vector3(s, 0, 0) * 0.04,
			Vector3(s, 0, 0), 1.1, 1.4, true, 0.14)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			U.blk(lm, wall, cx + sx * (w * 0.5 - 0.15), y0 + 0.65, cz + sz * (d * 0.5 - 0.15), 0.5, h - 0.9, 0.5)

## Hall with its ridge along Z, arched windows and standing-seam roof.
static func _hall_z(lm: LandmarkMesh, y0: float, cx: float, cz: float, w: float, d: float) -> void:
	var h := 5.1
	var rise := minf(w * 0.28, 4.0)
	U.blk(lm, "Granite", cx, y0, cz, w + 0.4, 0.65, d + 0.4)
	U.blk(lm, "Ochre", cx, y0 + 0.65, cz, w, h - 0.65, d)
	U.blk(lm, "Trim", cx, y0 + h - 0.25, cz, w + 0.35, 0.25, d + 0.35)
	U.ridge_z(lm, "Roof", "Ochre", Vector3(cx, y0 + h, cz), w + 1.0, d + 0.9, rise, 0.0)
	_standing_seams_z(lm, cx, cz, y0 + h, w + 1.0, d + 0.9, rise)
	for s in [-1.0, 1.0]:
		FhP.win_row(lm, "Trim", "Window", Vector3(cx + s * w * 0.5, y0, cz - d * 0.5 + 2.0),
			Vector3(cx + s * w * 0.5, y0, cz + d * 0.5 - 2.0), Vector3(s, 0, 0),
			1.4, maxi(int(d / 4.5), 2), 1.1, 1.9, true, 0.16)
		LandmarkDetail.window(lm, "Trim", "Window", Vector3(cx, y0 + h + rise * 0.42, cz + s * d * 0.5) + Vector3(0, 0, s) * 0.04,
			Vector3(0, 0, s), 1.1, 1.4, true, 0.14)

static func _standing_seams_x(lm: LandmarkMesh, cx: float, cz: float, ye: float, w: float, d: float, rise: float) -> void:
	var n := maxi(int(w / 2.2), 2)
	for k in n + 1:
		var x := cx - w * 0.5 + w * float(k) / float(n)
		for sz in [-1.0, 1.0]:
			lm.beam("Roof", Vector3(x, ye, cz + sz * d * 0.5), Vector3(x, ye + rise + 0.04, cz), 0.07, 0.07)
	lm.beam("Roof", Vector3(cx - w * 0.5, ye + rise + 0.05, cz), Vector3(cx + w * 0.5, ye + rise + 0.05, cz), 0.14, 0.14)

static func _standing_seams_z(lm: LandmarkMesh, cx: float, cz: float, ye: float, w: float, d: float, rise: float) -> void:
	var n := maxi(int(d / 2.2), 2)
	for k in n + 1:
		var z := cz - d * 0.5 + d * float(k) / float(n)
		for sx in [-1.0, 1.0]:
			lm.beam("Roof", Vector3(cx + sx * w * 0.5, ye, z), Vector3(cx, ye + rise + 0.04, z), 0.07, 0.07)
	lm.beam("Roof", Vector3(cx, ye + rise + 0.05, cz - d * 0.5), Vector3(cx, ye + rise + 0.05, cz + d * 0.5), 0.14, 0.14)

## OOPEAA's sculpted pitched timber public sauna by the west jetty.
static func _sauna(lm: LandmarkMesh, y0: float) -> void:
	var cx := -32.5
	var cz := -35.0
	U.blk(lm, "Granite", cx, y0 - 0.1, cz, 8.8, 0.4, 7.6)
	U.blk(lm, "Deck", cx - 0.5, y0, cz + 5.2, 7.6, 0.28, 4.8)
	# Sculpted asymmetrical twin pitched timber volumes and cantilevered porch canopy.
	U.blk(lm, "Timber", cx - 1.2, y0 + 0.2, cz - 0.4, 5.4, 3.2, 6.4)
	U.blk(lm, "Timber", cx + 2.2, y0 + 0.2, cz + 0.6, 3.6, 2.7, 5.2)
	U.ridge_z(lm, "Roof", "Timber", Vector3(cx - 1.2, y0 + 3.4, cz - 0.2), 6.2, 7.8, 2.4, 0.4)
	U.ridge_x(lm, "Roof", "Timber", Vector3(cx + 2.0, y0 + 2.9, cz + 0.6), 4.4, 5.8, 1.8, 0.4)
	# Sea-facing panoramic sauna window and warm lantern glow.
	lm.quad("Window", Vector3(cx - 3.2, y0 + 0.8, cz + 2.84), Vector3(cx + 0.4, y0 + 0.8, cz + 2.84),
		Vector3(cx + 0.4, y0 + 2.8, cz + 2.84), Vector3(cx - 3.2, y0 + 2.8, cz + 2.84), Vector3(0, 0, 1))
	lm.box("Lamp", Vector3(cx - 1.4, y0 + 1.8, cz + 2.76), Vector3(3.2, 1.6, 0.08), Basis(), 0.0)
	lm.box("Lamp", Vector3(cx + 2.0, y0 + 2.3, cz + 3.3), Vector3(0.7, 0.5, 0.4), Basis(), 0.0)
	# Slender stove chimney.
	lm.frustum("Roof", Vector3(cx - 1.0, y0 + 4.8, cz - 0.8), 0.22, 0.22, 1.8, 8)

static func _jetties(lm: LandmarkMesh) -> void:
	U.blk(lm, "Deck", -29.0, 0.9, -48.0, 10.0, 0.3, 4.0)
	U.blk(lm, "Deck", -28.0, 0.9, 95.0 - 40.0, 4.0, 0.3, 40.0)
	for k in 8:
		lm.box("Granite", Vector3(-28.0 + (1.8 if k % 2 == 0 else -1.8), 0.4, 58.0 + float(k) * 4.5), Vector3(0.3, 1.0, 0.3))
