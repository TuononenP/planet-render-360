extends RefCounted

## finlandia_hall. Registry entry and model in one file.

const FhU = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")
const FhP = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_parts.gd")

const ENTRY := {"type": "finlandia_hall", "skyline_priority": 1, "name": "Finlandia Hall", "lat": 60.17582, "lon": 24.93356,
	"radius_m": 5000.0, "wiki_title": "Finlandia Hall", "height_m": 33.9, "clear_m": 112.0,
	"yaw_deg": 74.0, "kind": "Concert hall", "aliases": ["finlandia hall", "finlandia-talo", "finlandiahuset"]}

## Height of the concert hall block's tall (bay-side) wall: the LoD2 top
## (33.9 m) less the stepped crown on it.
const TOWER := 31.5

## From the Commons photos (visual-plan/refs/landmarks/finlandia_hall/):
## grey-white Carrara marble in vertical panels, a long fin-ribbed wing
## with slim upright windows, a black granite lower wall and the
## angular stepped auditorium block. Measured: outline (OSM way 8034126)
## and the 33.9 m top (LoD2, the auditorium block). Estimated: the block's
## stepped heights.
##
## Aalto's Finlandia Hall (1971, congress wing 1975), origin at the OSM
## footprint centre, x along the 200 m long axis (north-north-west to
## south-south-east), front +Z on the Mannerheimintie side: the marble
## base, the tower-like concert hall volume with its sloping roof and the
## black trapezium on the bay wall, the wedge of the congress wing and the
## covered walk along the bay.
static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#D6D4CE", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("limestone", "#C9C7C1", 3.0))
	lm.use("Black", LandmarkMaterials.pbr("concrete", "#1E1E20", 3.0, 0.5, 0.1))
	lm.use("Glass", LandmarkMaterials.glass("#2A3236"))
	lm.use("Copper", LandmarkMaterials.pbr("concrete", "#6E8A78", 2.0, 0.5, 0.3))
	var base := PackedVector2Array([Vector2(-58.9, 38.5), Vector2(-84.6, 2.4), Vector2(-81.0, -0.2),
		Vector2(-98.3, -24.7), Vector2(-57.2, -25.0), Vector2(-57.8, -28.0), Vector2(-40.4, -28.0),
		Vector2(-38.3, -25.1), Vector2(32.4, -25.4), Vector2(55.3, -25.8), Vector2(55.3, -28.3),
		Vector2(72.7, -28.5), Vector2(72.7, -26.7), Vector2(99.9, -26.0), Vector2(90.8, 0.4),
		Vector2(79.5, -2.7), Vector2(70.3, -1.7), Vector2(62.8, -1.0), Vector2(59.7, -5.5),
		Vector2(53.9, -4.0), Vector2(50.4, -6.5), Vector2(38.8, -2.9), Vector2(32.5, -2.9),
		Vector2(16.4, 1.3), Vector2(17.2, 4.9), Vector2(9.1, 7.1), Vector2(11.0, 14.2),
		Vector2(3.2, 17.7), Vector2(4.2, 22.0), Vector2(-52.9, 38.7)])
	lm.poly_prism("Marble", base, 0.0, 10.5)
	# Congress wing: a flat upper storey over the northern wedge.
	lm.poly_prism("Roof", PackedVector2Array([Vector2(-96.0, -23.0), Vector2(-58.5, -23.3),
		Vector2(-57.0, 36.0), Vector2(-83.0, 1.5), Vector2(-80.5, -0.8)]), 10.5, 14.0)
	# The concert hall tower, its roof falling toward the street side.
	FhU.wedge(lm, "Marble", "Roof", -14.0, 34.0, -25.7, 4.0, 0.0, TOWER, 18.0)
	lm.quad("Black", Vector3(-8.0, 4.0, -25.9), Vector3(30.0, 4.0, -25.9), Vector3(23.0, TOWER - 3.0, -25.9),
		Vector3(-3.0, TOWER - 3.0, -25.9), Vector3(0, 0, -1))
	# Auditorium fan on the south: lower stepped roof.
	lm.poly_prism("Roof", PackedVector2Array([Vector2(38.0, -24.0), Vector2(97.0, -25.0), Vector2(89.0, -3.0),
		Vector2(62.0, -3.0), Vector2(50.0, -6.0), Vector2(38.5, -3.8)]), 10.5, 15.0)
	# Foyer glazing along the street front and the entrance canopy.
	var ang := atan2(16.7, 57.1)
	var mid := Vector3(-24.35, 0.0, 30.35)
	var fb := Basis(Vector3.UP, ang)
	lm.box("Glass", mid + fb * Vector3(0, 4.0, 0.2), Vector3(58.0, 6.0, 0.3), fb)
	lm.box("Roof", mid + fb * Vector3(0, 7.4, 2.2), Vector3(60.0, 0.5, 6.0), fb)
	for i in 14:
		var t := (float(i) + 0.5) / 14.0
		lm.box("Marble", mid + fb * Vector3((t - 0.5) * 58.0, 3.5, 3.6), Vector3(0.6, 7.0, 0.6), fb)
	# Covered walk and slim columns on the bay side.
	lm.box("Roof", Vector3(-8.0, 4.5, -30.0), Vector3(95.0, 0.5, 6.0))
	FhU.columns(lm, "Marble", Vector3(-54.0, 0.0, -32.6), Vector3(38.0, 0.0, -32.6), 16, 4.3, 0.22, 8)
	# Ribbon windows along the bay wall west of the tower.
	FhU.wall_run(lm, "Glass", Vector2(-36.2, -25.11), Vector2(-17.1, -25.22), Vector2.ZERO, 4.5, 2, 3.0, 5, 3.0, 1.6)
		# Black granite plinth course under the marble.
	lm.poly_prism("Black", base, 0.0, 0.6, false)
	# The marble skin: narrow profiled slabs read as vertical fins down
	# every long wall of the base, the congress storey and the tower.
	for i in base.size():
		var p := base[i]
		var q := base[(i + 1) % base.size()]
		if p.distance_to(q) > 8.0:
			FhP.ribs(lm, "Marble", Vector3(p.x, 0, p.y), Vector3(q.x, 0, q.y), FhP.edge_out(base, i), 0.6, 10.3,
				1.4, 0.3, 0.12)
	var cong := PackedVector2Array([Vector2(-96.0, -23.0), Vector2(-58.5, -23.3), Vector2(-57.0, 36.0),
		Vector2(-83.0, 1.5), Vector2(-80.5, -0.8)])
	# Ribbon window and mullions round the congress wing's upper storey.
	for i in cong.size():
		var p := cong[i]
		var q := cong[(i + 1) % cong.size()]
		var o := FhP.edge_out(cong, i)
		var a3 := Vector3(p.x, 0, p.y) + o * 0.04
		var b3 := Vector3(q.x, 0, q.y) + o * 0.04
		lm.quad("Glass", a3 + Vector3(0, 11.3, 0), b3 + Vector3(0, 11.3, 0), b3 + Vector3(0, 13.1, 0),
			a3 + Vector3(0, 13.1, 0), o)
		FhP.ribs(lm, "Marble", a3, b3, o, 11.3, 13.1, 1.8, 0.2, 0.1)
		FhP.band(lm, "Marble", a3, b3, o, 13.2, 0.8, 0.25)
	# The tower: fins on its bay and end walls, a step under the sloping
	# roof and the eaves fascia along its falling edges.
	for x in [-14.0, 34.0]:
		var sx := -1.0 if x < 0.0 else 1.0
		FhP.ribs(lm, "Marble", Vector3(x, 0, -25.7), Vector3(x, 0, 4.0), Vector3(sx, 0, 0), 10.5, 13.5, 1.6, 0.3, 0.12)
		lm.beam("Roof", Vector3(x + sx * 0.2, TOWER + 0.2, -25.9), Vector3(x + sx * 0.2, 18.2, 4.2), 0.5, 0.8, Vector3(0, 0, 1))
	FhP.ribs(lm, "Marble", Vector3(-13.0, 0, -25.75), Vector3(33.0, 0, -25.75), Vector3(0, 0, -1), 10.5, TOWER - 0.4, 1.6,
		0.3, 0.14)
	FhP.band(lm, "Roof", Vector3(-14.0, 0, -25.7), Vector3(34.0, 0, -25.7), Vector3(0, 0, -1), TOWER - 0.4, 0.6, 0.5)
	FhU.wedge(lm, "Marble", "Roof", -6.0, 26.0, -18.0, -2.0, TOWER, 1.4, 0.8)
	# Chamber-hall fan: fins and its stepped roof edge.
	FhP.band(lm, "Marble", Vector3(38.0, 0, -24.5), Vector3(97.0, 0, -25.5), Vector3(0, 0, -1), 14.6, 0.6, 0.3)
	FhP.ribs(lm, "Marble", Vector3(38.0, 0, -24.4), Vector3(97.0, 0, -25.4), Vector3(0, 0, -1), 10.5, 14.6, 1.6, 0.3,
		0.12)
	# Entrance canopies on the street front, on slender round columns.
	for e in [Vector3(-44.0, 0, 37.5), Vector3(-6.0, 0, 26.6)]:
		var eb := Basis(Vector3.UP, ang)
		lm.box("Roof", e + eb * Vector3(0, 3.6, 3.0), Vector3(12.0, 0.4, 6.0), eb)
		for k in 4:
			lm.frustum("Marble", e + eb * Vector3(-5.0 + 3.33 * float(k), 0, 5.6), 0.16, 0.16, 3.4, 10)
	lm.commit(model)
