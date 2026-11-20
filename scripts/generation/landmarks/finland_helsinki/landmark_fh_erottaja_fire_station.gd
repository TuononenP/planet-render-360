extends RefCounted

## Erottaja Fire Station (Erottajan paloasema, Theodor Decker, 1891),
## Korkeavuorenkatu 26. Origin at the OSM outline's bounding-box centre, front
## +Z toward the Korkeavuorenkatu side (registry yaw -93.6 turns +Z east).
##
## Measured: the outline (relation 167018, simplified to 1 m: a 72 x 31 m
## block with a 29 x 6 m projection on the +Z side), three levels per OSM, the
## LoD2 top 26.3 m. The registry point lay 80 m from the building. Estimated
## from visual-plan/refs/erottaja_fire_station/: dark red clinker brick, pale
## stone arches and string courses, pairs of round-headed windows in two
## rows, engine-house arches on the ground floor, the crenellated parapet and
## stepped end gables, and the square tapering tower with its overhanging
## corbelled crown and merlons, clock roundel and tall slit windows. The tower
## position on the projection, the number of engine doors and the gable step
## sizes are approximate.

const D = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_d_kit.gd")
const U = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")
const P = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_parts.gd")

const ENTRY := {"type": "erottaja_fire_station", "name": "Erottaja Fire Station", "lat": 60.165151, "lon": 24.945167,
	"radius_m": 1500.0, "wiki_title": "Helsinki Central Fire Station", "height_m": 27.0, "clear_m": 42.0,
	"yaw_deg": -93.6, "kind": "Fire station",
	"aliases": ["erottaja fire station", "erottajan paloasema", "skillnadens brandstation", "helsinki central fire station"]}

const OUTLINE := [36.0, -18.4, 36.0, 12.4, 15.6, 12.2, 15.6, 16.6, -9.9, 16.4, -12.2, 18.4, -13.6, 17.1, -13.6, 12.6, -36.0, 12.5, -36.0, -18.5]
const EAVE := 14.5
const TOWER := Vector2(9.0, 12.0)

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("brick", "#7B392B", 2.2))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#BDB19B", 2.0))
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#6C6862", 3.0))
	lm.use("Glass", LandmarkMaterials.glass("#2B3236"))
	lm.use("Door", LandmarkMaterials.paint("#6E2A22", 0.6, 0.1))
	lm.use("Roof", LandmarkMaterials.paint("#4A4E50", 0.6, 0.3))
	lm.use("Lamp", LandmarkMaterials.lit("#F6E6B0", 0.3))
	var p := D.poly(OUTLINE)
	D.block(lm, p, {"eave": EAVE, "plinth": 1.4, "cornice": 0.9, "cornice_out": 0.45, "course_y": 6.2, "rows": 0})
	U.blk(lm, "Roof", 0.0, EAVE, -3.0, 70.0, 0.2, 29.0)
	for run in D.runs(p):
		var a: Vector3 = run[0]
		var b: Vector3 = run[1]
		var o: Vector3 = run[2]
		var run_len := a.distance_to(b)
		if run_len < 6.0:
			continue
		var n := maxi(int(round(run_len / 3.4)), 1)
		P.win_row(lm, "Trim", "Glass", a, b, o, 1.9, n, 1.5, 4.2, true, 0.3)
		P.win_row(lm, "Trim", "Glass", a, b, o, 7.8, n, 1.5, 5.0, true, 0.3)
		P.band(lm, "Trim", a, b, o, 12.6, 0.45, 0.22)
		U.merlons(lm, "Wall", a + Vector3(0, EAVE, 0), b + Vector3(0, EAVE, 0), 1.7, 0.9, 0.9, 0.6)
	# Engine-house doors on the projecting front: tall round-headed arches.
	U.openings(lm, "Door", Vector3(-8.5, 0, 16.5), Vector3(14.0, 0, 16.5), Vector3(0, 0, 1), 0.0, 4, 3.4, 5.0, true, 0.06)
	# Stepped gables on both short ends, with a round window each.
	for s in [-1.0, 1.0]:
		P.crow_gable(lm, "Wall", "Trim", Vector3(s * 35.9, 0.0, -3.0), Vector3(s, 0, 0), 20.0, EAVE, 4.5, 4, 0.8)
		lm.disc("Glass", Vector3(s * 36.2, 11.8, -3.0), Vector3(s, 0, 0), 1.3, 16)
	_tower(lm)
	lm.commit(model)
	D.flood(model, [
		[Vector3(30.0, 0.5, 34.0), Vector3(10.0, 10.0, 17.0), 55.0, 0.9, 50.0, Color(1.0, 0.88, 0.7)],
		[Vector3(-10.0, 0.5, 34.0), Vector3(0.0, 10.0, 17.0), 55.0, 0.7, 50.0, Color(1.0, 0.88, 0.7)]])

## The square tapering tower: brick shaft with paired slit windows, a clock
## roundel, a grey corbelled crown with merlons and the lightning rods.
static func _tower(lm: LandmarkMesh) -> void:
	var c := Vector3(TOWER.x, 0.0, TOWER.y)
	lm.spire("Wall", c, 3.9, 24.0, 3.3, 4)
	for f in 4:
		var basis := Basis(Vector3.UP, PI * 0.5 * float(f))
		var out: Vector3 = basis * Vector3(0, 0, 1)
		var rt: Vector3 = basis * Vector3(1, 0, 0)
		var fc: Vector3 = c + out * 3.5
		U.openings(lm, "Glass", fc - rt * 1.9, fc + rt * 1.9, out, 8.5, 3, 0.7, 11.5, true, 0.1)
		P.band(lm, "Trim", fc - rt * 3.4, fc + rt * 3.4, out, 7.2, 0.4, 0.2)
		P.band(lm, "Trim", fc - rt * 3.2, fc + rt * 3.2, out, 22.0, 0.4, 0.2)
		U.blk(lm, "Trim", c.x + out.x * 3.45, 17.5, c.z + out.z * 3.45, 0.6 + 6.0 * absf(rt.x), 2.0, 0.6 + 6.0 * absf(rt.z))
	lm.disc("Trim", c + Vector3(0, 12.5, 3.5), Vector3.BACK, 1.1, 20)
	lm.disc("Glass", c + Vector3(0, 12.5, 3.56), Vector3.BACK, 0.9, 20)
	# Overhanging crown on corbels, then the merlons.
	U.blk(lm, "Stone", c.x, 24.0, c.z, 8.6, 0.8, 8.6)
	U.blk(lm, "Wall", c.x, 24.8, c.z, 9.8, 1.0, 9.8)
	for k in 12:
		var a := TAU * (float(k) + 0.5) / 12.0
		var d := Vector3(cos(a), 0, sin(a))
		var r := 4.8 / maxf(absf(d.x), absf(d.z))
		lm.box("Wall", c + d * r + Vector3(0, 26.1, 0), Vector3(1.1, 1.0, 1.1), Basis(), 0.0)
	for q in 4:
		var cp := c + Vector3(4.8 if q % 2 == 0 else -4.8, 26.1, 4.8 if q < 2 else -4.8)
		lm.box("Wall", cp, Vector3(1.2, 1.0, 1.2), Basis(), 0.0)
	lm.beam("Stone", c + Vector3(0, 25.8, 0), c + Vector3(0, 28.2, 0), 0.12)
