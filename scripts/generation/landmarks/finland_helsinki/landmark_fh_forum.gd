extends RefCounted

## Forum shopping centre (Kauppakeskus Forum, 1985), Mannerheimintie 20. Origin
## at the OSM outline's bounding-box centre (registry yaw -3 keeps the street
## grid).
##
## Measured: the outline (way 289767497, the whole 94 x 100 m block, simplified
## to 1.5 m) and the LoD2 top of the sign tower, 38.5 m. The registry point lay
## close (5 m). Estimated from visual-plan/refs/forum_helsinki/ (the earlier
## brick model was wrong; the brick building in the OSM data is a neighbour):
## black-glazed curtain walls with a silver grid, six storeys over a glazed
## shop floor with a deep shaded band between, a clear-glass corner cube at
## the east apex of the block carrying the FORUM sign box and a flagpole, and
## the lower, stepped street fronts with their angular bays. Storey heights
## and the corner position are read from the photo and are approximate.

const D = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_d_kit.gd")
const U = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")
const P = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_parts.gd")

const ENTRY := {"type": "forum_helsinki", "name": "Forum Shopping Centre", "lat": 60.169230, "lon": 24.938175,
	"radius_m": 1500.0, "wiki_title": "Forum (shopping centre)", "height_m": 38.0, "clear_m": 50.0,
	"yaw_deg": -3.0, "kind": "Shopping centre", "aliases": ["forum shopping centre", "kauppakeskus forum", "forum helsinki"]}

const OUTLINE := [-21.6, 24.9, -47.1, -13.1, -36.8, -20.7, -22.6, -30.5, 6.6, -50.3, 14.7, -37.7, 32.6, -11.0, 47.1, 11.4, 33.9, 20.3,
	35.5, 23.1, 12.3, 37.6, -6.6, 47.7, -13.2, 50.3, -18.0, 43.5, -23.0, 46.9, -28.8, 38.3, -29.8, 30.0]
const SHOP := 6.4
const EAVE := 27.2

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("concrete", "#2A2B30", 3.0))
	lm.use("Dark", LandmarkMaterials.glass("#1B1D22"))
	lm.use("Pane", LandmarkMaterials.glass("#2B3338"))
	lm.use("Clear", LandmarkMaterials.paint("#A9C4CE", 0.1, 0.5))
	lm.use("Frame", LandmarkMaterials.paint("#A6ABAE", 0.4, 0.6))
	lm.use("Shop", LandmarkMaterials.glass("#4A5A62"))
	lm.use("Band", LandmarkMaterials.paint("#222426", 0.6, 0.3))
	lm.use("Sign", LandmarkMaterials.pbr("concrete", "#C9CCCB", 3.0))
	lm.use("Lamp", LandmarkMaterials.lit("#E8EEF0", 0.4))
	var p := D.poly(OUTLINE)
	lm.poly_prism("Wall", p, 0.0, EAVE, true)
	D.slab(lm, "Band", p, 0.2, SHOP - 0.6, 1.2)
	D.slab(lm, "Frame", p, 0.35, EAVE - 0.4, 0.6)
	for run in D.runs(p):
		var a: Vector3 = run[0]
		var b: Vector3 = run[1]
		var o: Vector3 = run[2]
		var run_len := a.distance_to(b)
		if run_len < 5.0:
			continue
		var n := maxi(int(round(run_len / 3.6)), 1)
		P.pierce(lm, "Band", "Shop", a, b, o, 0.0, SHOP - 0.6, n, 1, Vector2(3.0, 4.6), 0.4, 5.0, 0.25)
		D.pier_run(lm, "Wall", "Frame", "Pane", a, b, o, SHOP + 0.6, EAVE - 0.4, 3.6, 0.22, 0.12, Vector2(3.2, 2.6), 0.5, 3.4, 6, 0.3, 5.0)
	# Roof deck plant and the stepped upper stage.
	# The clear-glass corner cube at the east apex, with the FORUM sign box.
	var cc := Vector2(37.0, 9.0)
	U.blk(lm, "Clear", cc.x, 0.0, cc.y, 16.0, EAVE + 1.0, 16.0)
	for k in range(0, 9):
		U.blk(lm, "Frame", cc.x, 3.0 * float(k) + 0.2, cc.y, 16.4, 0.25, 16.4)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			U.blk(lm, "Frame", cc.x + sx * 8.0, 0.0, cc.y + sz * 8.0, 0.4, EAVE + 1.0, 0.4)
	U.blk(lm, "Sign", cc.x, EAVE + 1.0, cc.y, 14.5, 38.0 - EAVE - 1.0, 14.5)
	lm.box("Lamp", Vector3(cc.x, 33.0, cc.y + 7.4), Vector3(11.0, 2.2, 0.2), Basis(), 0.0)
	lm.box("Lamp", Vector3(cc.x + 7.4, 33.0, cc.y), Vector3(0.2, 2.2, 11.0), Basis(), 0.0)
	lm.commit(model)
