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
	K.house(lm, "Brick", "Roof", 7.0, 21.0, y0, 30.0, 12.0, 5.2, 3.6, 9, 1, 1.3, 2.3, 1.2)
	# Mine laboratory, ochre plaster.
	K.house(lm, "Ochre", "Roof", 4.0, -18.0, y0, 22.0, 20.0, 5.4, 4.6, 6, 1, 1.2, 2.0, 1.2)
	# Demagnetisation shed, low red brick.
	K.house(lm, "Brick", "Roof", 6.0, 38.0, y0, 30.0, 8.0, 4.0, 2.6, 10, 1, 1.0, 1.6, 1.1)
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
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(7.0, 1.0, 46.0), Vector3(7.0, 5.0, 27.0), 50.0, 0.9, 50.0, Color(1.0, 0.86, 0.66)],
		[Vector3(-33.0, 1.0, -30.0), Vector3(-33.0, 3.0, -35.0), 45.0, 0.7, 30.0, Color(1.0, 0.86, 0.66)]])

## Hall with its ridge along Z.
static func _hall_z(lm: LandmarkMesh, y0: float, cx: float, cz: float, w: float, d: float) -> void:
	U.blk(lm, "Granite", cx, y0, cz, w + 0.3, 0.5, d + 0.3)
	U.blk(lm, "Ochre", cx, y0 + 0.5, cz, w, 4.6, d)
	U.ridge_z(lm, "Roof", "Ochre", Vector3(cx, y0 + 5.1, cz), w + 1.0, d + 0.9, minf(w * 0.28, 4.0), 0.0)
	for s in [-1.0, 1.0]:
		K.row(lm, "Window", Vector3(cx + s * w * 0.5, y0, cz - d * 0.5 + 2.0), Vector3(cx + s * w * 0.5, y0, cz + d * 0.5 - 2.0),
			Vector3(s, 0, 0), 1.2, maxi(int(d / 4.5), 2), 1.1, 1.9)

## The new sauna by the west jetty: cream timber, black hipped roof.
static func _sauna(lm: LandmarkMesh, y0: float) -> void:
	var cx := -32.5
	var cz := -35.0
	U.blk(lm, "Timber", cx, y0, cz, 7.0, 3.0, 6.0)
	K.hip(lm, "Roof", cx, cz, y0 + 3.0, 7.0, 6.0, 2.6, 2.0, 0.6)
	U.blk(lm, "Roof", cx - 1.5, y0 + 4.2, cz + 0.8, 1.4, 1.0, 1.4)
	U.blk(lm, "Roof", cx + 1.0, y0 + 5.2, cz - 0.6, 0.7, 1.7, 0.7)
	K.row(lm, "Window", Vector3(cx - 2.5, y0, cz + 3.0), Vector3(cx + 2.5, y0, cz + 3.0), Vector3(0, 0, 1), 0.8, 2, 1.0, 1.8, false)
	U.blk(lm, "Deck", cx, y0 - 0.2, cz + 5.5, 5.0, 0.2, 4.0)

static func _jetties(lm: LandmarkMesh) -> void:
	U.blk(lm, "Deck", -29.0, 0.9, -48.0, 10.0, 0.3, 4.0)
	U.blk(lm, "Deck", -28.0, 0.9, 95.0 - 40.0, 4.0, 0.3, 40.0)
	for k in 8:
		lm.box("Granite", Vector3(-28.0 + (1.8 if k % 2 == 0 else -1.8), 0.4, 58.0 + float(k) * 4.5), Vector3(0.3, 1.0, 0.3))
