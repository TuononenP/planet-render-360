extends RefCounted

## Hotel Torni (Jung & Jung, 1931), Yrjönkatu 26. Origin at the OSM footprint
## centre (registry yaw -35 turns the block onto Yrjönkatu), front +Z.
##
## Measured: footprint and part heights from OSM (way 123525580 and the
## building:part ways: the 30 m square base, the 24 m wings, the 7.6 x 19.7 m
## tower slab, the 49 m terrace storey, the 58 m lantern, the 70 m mast; the
## LoD2 roof is 58.2 m, which stops below the mast). Estimated: the pale
## buff render (visual-plan/refs/hotel_torni/ shows it from far away only),
## the pier spacing, window sizes, the glazed Ateljee Bar storey and the red
## sign band. The photos (visual-plan/refs/hotel_torni/tower.jpg) showed
## warm ochre plaster, horizontal string courses on the tower and no
## vertical piers, so the earlier ribs were replaced. The Jugend courtyard wings behind the tower are not modelled.
##
## Night: the tower and lantern are floodlit, as in the real city.
##
## Jung & Jung's Torni (1931), 13 storeys and 70 m, the tallest building in
## Helsinki on completion; parts after the OSM 3D outline: the 30 m square
## six-storey base with its shopfront plinth, the setback storey and the
## flanking wings (24 m), the slender tower slab ribbed by vertical piers to
## 45 m, the glazed Ateljee Bar storey and terraces (49 m), the lantern (58 m)
## and the mast.

const D = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_d_kit.gd")
const FhU = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")
const FhP = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_parts.gd")

const ENTRY := {"type": "hotel_torni", "skyline": true, "name": "Hotel Torni", "lat": 60.16780, "lon": 24.93864,
	"radius_m": 5000.0, "wiki_title": "Hotel Torni", "height_m": 70.0, "clear_m": 30.0,
	"yaw_deg": -35.0, "kind": "Tower", "aliases": ["hotel torni", "sokos hotel torni", "hotelli torni",
		"solo sokos hotel torni"]}

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("render", "#C9A872", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#E9DFC6", 2.5))
	lm.use("Plinth", LandmarkMaterials.pbr("stone", "#8A8780", 4.0))
	lm.use("Copper", LandmarkMaterials.pbr("concrete", "#6E9C88", 2.0, 0.5, 0.3))
	lm.use("Glass", LandmarkMaterials.glass("#2A3236"))
	lm.use("Sign", LandmarkMaterials.lit("#D8322A", 0.6))
	lm.use("Lamp", LandmarkMaterials.lit("#FFE7A8", 0.5))
	# Base block: granite shopfront storey, five rendered storeys, cornice.
	var bx := 0.2
	var bz := 1.15
	var bw := 29.8
	var bd := 30.3
	FhU.blk(lm, "Plinth", bx, 0.0, bz, bw + 0.3, 4.2, bd + 0.3)
	FhU.blk(lm, "Wall", bx, 4.2, bz, bw, 14.6, bd)
	for face in FhP.faces(bx, bz, bw, bd):
		var fa: Vector3 = face[0]
		var fb: Vector3 = face[1]
		var fo: Vector3 = face[2]
		FhP.pierce(lm, "Wall", "Glass", fa, fb, fo, 4.2, 14.2, 9, 4, Vector2(1.5, 1.9), 0.9, 3.4, 0.25)
		FhU.openings(lm, "Glass", fa, fb, fo, 0.4, 5, 3.6, 3.0, false, 0.04)
		FhP.band(lm, "Trim", fa, fb, fo, 4.0, 0.4, 0.3)
		LandmarkDetail.cornice(lm, "Trim", fa + Vector3(0, 18.2, 0), fb + Vector3(0, 18.2, 0), fo, 0.6, false)
	# Setback storey and the wings either side of the tower.
	FhU.blk(lm, "Wall", -0.95, 18.8, 0.95, 27.5, 2.2, 26.7)
	FhU.blk(lm, "Trim", -0.95, 20.8, 0.95, 27.9, 0.25, 27.1)
	for wg in [[-9.05, -5.2, 11.3, 7.4], [6.9, 0.95, 5.6, 19.7], [-6.05, 7.2, 5.5, 7.0]]:
		FhU.blk(lm, "Wall", float(wg[0]), 21.0, float(wg[1]), float(wg[2]), 3.0, float(wg[3]))
		FhU.blk(lm, "Trim", float(wg[0]), 23.8, float(wg[1]), float(wg[2]) + 0.3, 0.25, float(wg[3]) + 0.3)
	# The tower slab, its vertical piers and windows between them.
	var tx := 0.3
	var tz := 0.95
	var tw := 7.6
	var td := 19.7
	FhU.blk(lm, "Wall", tx, 21.0, tz, tw, 24.0, td)
	for face in FhP.faces(tx, tz, tw, td):
		var fa: Vector3 = face[0]
		var fb: Vector3 = face[1]
		var fo: Vector3 = face[2]
		var n := 2 if fa.distance_to(fb) < 10.0 else 5
		FhP.pierce(lm, "Wall", "Glass", fa, fb, fo, 24.0, 20.6, n, 6, Vector2(1.3, 2.0), 0.6, 3.3, 0.2)
		# Horizontal string courses every two storeys, as the photos show.
		for k in range(1, 4):
			FhP.band(lm, "Trim", fa, fb, fo, 21.0 + 6.6 * float(k), 0.5, 0.25)
	FhU.blk(lm, "Trim", tx, 44.6, tz, tw + 0.6, 0.4, td + 0.6)
	# Ateljee Bar: glazed storey with the terrace rails round it.
	FhU.blk(lm, "Glass", tx, 45.0, 1.0, 7.4, 3.6, 10.4)
	FhP.ribs(lm, "Trim", Vector3(tx - 3.7, 0, 6.2), Vector3(tx + 3.7, 0, 6.2), Vector3(0, 0, 1), 45.0, 48.6, 1.2, 0.15, 0.1)
	FhP.ribs(lm, "Trim", Vector3(tx + 3.7, 0, -4.2), Vector3(tx - 3.7, 0, -4.2), Vector3(0, 0, -1), 45.0, 48.6, 1.2, 0.15,
		0.1)
	for s in [-1.0, 1.0]:
		FhP.ribs(lm, "Trim", Vector3(tx + s * 3.7, 0, -4.2), Vector3(tx + s * 3.7, 0, 6.2), Vector3(s, 0, 0), 45.0, 48.6,
			1.3, 0.15, 0.1)
	FhU.blk(lm, "Trim", tx, 48.6, 1.0, 7.8, 0.4, 10.8)
	for z in [-6.6, 8.6]:
		lm.box("Trim", Vector3(tx, 45.55, z), Vector3(7.4, 1.1, 0.1), Basis(), 0.0)
	# Lantern: stepped shaft with vertical slits, copper cap, mast.
	FhU.blk(lm, "Wall", 0.35, 49.0, 1.05, 4.2, 3.0, 4.2)
	FhU.blk(lm, "Wall", 0.35, 52.0, 1.05, 2.9, 5.0, 3.0)
	for face in FhP.faces(0.35, 1.05, 2.9, 3.0):
		FhU.openings(lm, "Lamp", face[0], face[1], face[2], 52.6, 2, 0.4, 3.6, false, 0.03)
	FhU.blk(lm, "Trim", 0.35, 57.0, 1.05, 3.3, 0.3, 3.4)
	FhU.hip(lm, "Copper", Vector3(0.35, 57.3, 1.05), 3.1, 3.2, 1.2, 0.3)
	lm.frustum("Copper", Vector3(0.4, 58.5, 1.0), 0.35, 0.08, 11.0, 8)
	lm.lathe("Copper", Vector3(0.4, 69.2, 1.0), FhU.ball(0.15), 8)
	# The dark portal canopy over the entrance with the lit name.
	FhU.blk(lm, "Plinth", 0.2, 4.2, bz + bd * 0.5 + 1.7, 12.0, 0.45, 3.4)
	lm.box("Lamp", Vector3(0.2, 5.4, bz + bd * 0.5 + 0.5), Vector3(4.2, 1.0, 0.15), Basis(), 0.0)
	# The red sign band on the tower's street face.
	lm.box("Sign", Vector3(tx, 42.4, tz + td * 0.5 + 0.3), Vector3(6.0, 1.2, 0.15))
	lm.commit(model)
	D.flood(model, [
		[Vector3(-14.0, 1.0, -26.0), Vector3(0.3, 38.0, 1.0), 14.0, 0.9, 80.0, Color(1.0, 0.92, 0.76)],
		[Vector3(18.0, 1.0, 26.0), Vector3(0.3, 38.0, 1.0), 14.0, 0.9, 80.0, Color(1.0, 0.92, 0.76)],
		[Vector3(-14.0, 1.0, 26.0), Vector3(0.3, 45.0, 1.0), 14.0, 0.7, 90.0, Color(1.0, 0.92, 0.76)],
		[Vector3(18.0, 1.0, -26.0), Vector3(0.3, 45.0, 1.0), 14.0, 0.7, 90.0, Color(1.0, 0.92, 0.76)]])
