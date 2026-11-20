extends RefCounted

## Sokos Helsinki (Kaivokatu / Asema-aukio, 1952, Kaarlo Borg's department
## store, today also the Vaakuna hotel), built on its OpenStreetMap outline
## (way 122595238, Douglas-Peucker simplified to 0.6 m, recentred on the
## footprint's bounding box, rotated by the entry's yaw onto the street grid
## so the walls run along X and Z; +X east of that, +Z south of that).
##
## From the Commons photos in visual-plan/refs/landmarks/sokos_helsinki/:
## - The long diagonal front (the 78 m south-west edge, facing the station
##   square) shows a two-storey glazed shop base with a dark canopy over the
##   central entrance, then five storeys of square punched windows in 27
##   bays (about 2.9 m a bay, 3.8 m a storey) in dark grey granite-clad wall
##   with a pale sill and lintel on each window.
## - A cornice and a balustrade close the main block at 27 m. Above is a
##   setback glazed storey and the roof deck with small penthouses.
## - The red "SOKOS" lettering stands on the roof, two flagpoles rise at
##   the corners, and two colour-block banners (yellow over blue, red over
##   blue) hang by the shops at the front corners.
##
## Measured: the outline (OSM), the 44.6 m top (LoD2, the flagpoles), the
## storey height and bay width (scaled from the photo by the 78 m front).
## Estimated: the setback depth and the roof penthouses.

const W = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_west_footprints.gd")
const F = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_mall_footprints.gd")

const ENTRY := {"type": "sokos_helsinki", "name": "Sokos Helsinki", "lat": 60.170462, "lon": 24.938511,
	"radius_m": 1500.0, "wiki_title": "Sokos (department store)", "height_m": 44.6, "clear_m": 56.0,
	"yaw_deg": -7.2, "kind": "Department store",
	"aliases": ["sokos helsinki", "sokos department store helsinki", "sokos tavaratalo helsinki"]}

const OUTLINE := [-25.4, -40.5, 34.8, -40.3, 35.8, 21.8, 3.5, 40.5, -35.2, -27.1, -35.8, -32.3, -33.5, -37.3,
	-30.8, -39.5]

const BASE := 5.2
const EAVE := 27.0
const SETBACK_TOP := 32.0
const TOP := 44.6

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("stone", "#47463F", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#8E8C84", 2.5))
	lm.use("Window", LandmarkMaterials.paint("#34393C", 0.3, 0.4))
	lm.use("Glass", LandmarkMaterials.paint("#5B6A68", 0.3, 0.4))
	lm.use("Frame", LandmarkMaterials.paint("#2D3030", 0.5, 0.5))
	lm.use("Roof", LandmarkMaterials.paint("#55575A", 0.8))
	lm.use("Copper", LandmarkMaterials.pbr("concrete", "#78A090", 2.0, 0.5, 0.3))
	lm.use("Canopy", LandmarkMaterials.paint("#2A2623", 0.5, 0.4))
	lm.use("Lamp", LandmarkMaterials.lit("#D83A2E", 0.5))
	lm.use("Blue", LandmarkMaterials.paint("#1D2B5C", 0.6))
	lm.use("Yellow", LandmarkMaterials.paint("#D9A93A", 0.6))
	lm.use("Red", LandmarkMaterials.paint("#B02A2C", 0.6))
	lm.use("Pole", LandmarkMaterials.paint("#D8D8D4", 0.5, 0.5))
	lm.use("Flag", LandmarkMaterials.paint("#E8EEEA", 0.7))
	var poly := PackedVector2Array()
	for i in range(0, OUTLINE.size() - 1, 2):
		poly.append(Vector2(float(OUTLINE[i]), float(OUTLINE[i + 1])))
	# Main block: granite wall, glazed two-storey shop base on slim mullions.
	lm.poly_prism("Wall", poly, 0.0, EAVE)
	lm.poly_prism("Glass", F.offset(poly, 0.08), 0.5, BASE, false)
	W.ribs(lm, "Frame", poly, 0.5, BASE, 2.9, 0.14, 0.16)
	lm.poly_prism("Trim", F.offset(poly, 0.3), BASE, BASE + 0.45)
	# Five storeys of square punched windows, a bay every 2.9 m, with sills
	# and lintels in pale stone.
	W.edge_windows(lm, "Window", poly, BASE + 1.3, 5, 3.8, 2.9, 1.5, 2.0, "Trim")
	# Cornice and balustrade round the main roof.
	lm.poly_prism("Trim", F.offset(poly, 0.35), EAVE - 0.7, EAVE)
	W.ribs(lm, "Trim", poly, EAVE, EAVE + 0.9, 0.9, 0.1, 0.1)
	lm.poly_prism("Trim", F.offset(poly, 0.05), EAVE + 0.8, EAVE + 1.0, false)
	lm.poly_prism("Roof", F.offset(poly, -0.3), EAVE - 0.05, EAVE + 0.02)
	# Setback glazed storey with a thin flat roof.
	var upper := F.offset(poly, -3.2)
	lm.poly_prism("Glass", upper, EAVE, SETBACK_TOP, false)
	W.ribs(lm, "Frame", upper, EAVE, SETBACK_TOP, 2.9, 0.12, 0.12)
	lm.poly_prism("Trim", F.offset(upper, 0.25), SETBACK_TOP, SETBACK_TOP + 0.4)
	# Roof-deck penthouses and plant.
	var top2 := F.offset(upper, -4.5)
	lm.poly_prism("Wall", top2, SETBACK_TOP, SETBACK_TOP + 2.6)
	lm.poly_prism("Roof", F.offset(top2, 0.2), SETBACK_TOP + 2.6, SETBACK_TOP + 2.8)
	for p in [Vector2(-18, -20), Vector2(14, -26), Vector2(20, 8), Vector2(-6, 6), Vector2(-20, 6)]:
		lm.box("Copper", Vector3(p.x, SETBACK_TOP + 3.6, p.y), Vector3(2.6, 1.6, 2.6))
	# The long diagonal front: entrance canopy, banners, roof lettering.
	var a := Vector2(3.5, 40.5)
	var b := Vector2(-35.2, -27.1)
	var m := (a + b) * 0.5
	var along := (b - a).normalized()
	var out := Vector2(-along.y, along.x)
	if out.dot(Vector2(-m.x, -m.y)) > 0.0:
		out = -out
	var yaw := atan2(out.x, out.y)
	var fb := Basis(Vector3.UP, yaw)
	var c3 := Vector3(m.x, 0, m.y) + Vector3(out.x, 0, out.y) * 0.4
	lm.box("Canopy", c3 + Vector3(0, 5.0, 0) + Vector3(out.x, 0, out.y) * 3.2, Vector3(15.0, 0.6, 7.0), fb)
	lm.box("Canopy", c3 + Vector3(0, 4.55, 0) + Vector3(out.x, 0, out.y) * 3.2, Vector3(12.0, 0.3, 5.5), fb)
	for s: float in [-1.0, 1.0]:
		var p2 := m + along * (s * 28.0)
		var p3 := Vector3(p2.x, 0, p2.y) + Vector3(out.x, 0, out.y) * 0.5
		lm.box("Blue", p3 + Vector3(0, 7.0, 0), Vector3(5.2, 4.8, 0.3), fb)
		lm.box("Red" if s > 0.0 else "Yellow", p3 + Vector3(0, 11.2, 0), Vector3(5.2, 3.6, 0.3), fb)
	# Roof lettering (lit) and the two corner flagpoles to the LoD2 top.
	var rs := m - along * 2.0 + out * -3.8
	lm.box("Lamp", Vector3(rs.x, SETBACK_TOP + 4.2, rs.y), Vector3(11.0, 2.0, 0.35), fb)
	for p in [Vector2(-17.0, -33.0), Vector2(26.0, -33.0)]:
		lm.frustum("Pole", Vector3(p.x, SETBACK_TOP, p.y), 0.14, 0.06, TOP - SETBACK_TOP, 6)
		lm.box("Flag", Vector3(p.x + 0.9, TOP - 1.4, p.y), Vector3(1.8, 1.2, 0.04))
	lm.commit(model)
