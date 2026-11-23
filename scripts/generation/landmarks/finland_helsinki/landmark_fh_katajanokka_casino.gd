extends RefCounted

## Katajanokka Casino (Katajanokan kasino, the officers' casino by the Naval
## Barracks, c. 1914), Katajanokka. Front +Z is the long south face; the
## registry yaw (-2.4) turns the long axis onto OSM way 15242906's.
##
## From the Commons photos in visual-plan/refs/landmarks/katajanokka_casino/:
## - a two-storey block in pale cream render on a low grey granite plinth, with
##   giant fluted pilasters, a dentil band and a deep cornice under a flat
##   dark roof (not a hipped roof, not a lantern);
## - the tall brown-framed windows sit in the bays between the pilasters;
## - a dark ribbed dome (lead or copper, weathered) on a low drum over the
##   middle, and a taller block at the east end with a row of five small
##   square windows;
## - a projecting glazed bay window with a balcony on the south face and an
##   entrance with its own balcony at the east end;
## - at the north-east corner a semicircular bay with five columns carrying
##   a round balcony;
## - a tall white flagpole beside the dome.
##
## Measured: the outline (OSM way 15242906, 41 x 21 m, 3.5 levels), the axis
## and the position. Estimated from photos: the 8.3 m cornice, pilaster
## positions and window sizes, the dome (r 4.4 m, crown 12.6 m) and the
## flagpole. Pilaster x positions are scaled from the south-face photo and
## uncertain by a few metres. LoD2 height not available in this run.

const U = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")
const P = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_parts.gd")
const F = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_mall_footprints.gd")

const ENTRY := {"type": "katajanokka_casino", "name": "Katajanokka Casino", "lat": 60.169259, "lon": 24.965156,
	"radius_m": 1500.0, "wiki_title": "Katajanokan Kasino", "height_m": 15.5, "clear_m": 20.0,
	"yaw_deg": -2.4, "kind": "Restaurant", "aliases": ["katajanokka casino", "katajanokan kasino", "skatuddens kasino"]}

const POLY := [Vector2(17.9, -1.6), Vector2(17.9, 8.6), Vector2(12.1, 8.6), Vector2(11.0, 10.3), Vector2(8.4, 10.4),
	Vector2(7.4, 9.7), Vector2(7.4, 8.7), Vector2(6.1, 8.7), Vector2(6.1, 7.5), Vector2(-9.1, 7.5), Vector2(-10.4, 9.2),
	Vector2(-13.0, 9.2), Vector2(-14.2, 7.5), Vector2(-20.5, 7.4), Vector2(-20.5, -7.4), Vector2(-17.9, -7.4),
	Vector2(6.0, -7.3), Vector2(6.0, -10.4), Vector2(17.9, -10.3), Vector2(17.9, -7.7), Vector2(19.9, -6.5),
	Vector2(20.5, -4.3), Vector2(19.9, -2.8)]
const PLINTH := 1.2
const EAVE := 8.3
const ZS := 7.5
const ZN := -7.4
## Pilaster centres on the long faces and their widths.
const PILASTERS := [[-18.9, 2.6], [-11.0, 1.4], [-2.9, 1.4], [2.3, 1.4], [7.0, 1.4], [11.7, 2.2], [19.0, 1.6]]
const DOME_C := Vector3(3.5, 0.0, -1.0)
const BAY_C := Vector3(17.9, 0.0, -4.6)

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Render", LandmarkMaterials.pbr("render", "#EBE3AE", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("render", "#F3EDCB", 2.0))
	lm.use("Plinth", LandmarkMaterials.pbr("stone", "#7E766F", 2.5))
	lm.use("Frame", LandmarkMaterials.pbr("wood", "#4A3528", 1.5))
	lm.use("Glass", LandmarkMaterials.glass("#2B3338"))
	lm.use("Roof", LandmarkMaterials.paint("#3A3836", 0.7, 0.3))
	lm.use("Dome", LandmarkMaterials.paint("#44413F", 0.5, 0.5))
	var poly := PackedVector2Array(POLY)
	lm.poly_prism("Plinth", F.offset(poly, 0.1), 0.0, PLINTH)
	lm.poly_prism("Render", poly, PLINTH, EAVE)
	lm.poly_prism("Trim", F.offset(poly, 0.4), EAVE - 1.0, EAVE, false)
	lm.poly_prism("Roof", F.offset(poly, 0.25), EAVE, EAVE + 0.2)
	_faces(lm)
	_east_block(lm)
	_dome(lm)
	_bays(lm)
	_round_bay(lm)
	lm.commit(model)
	var warm := Color(1.0, 0.88, 0.66)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-4.0, 1.5, 24.0), Vector3(-2.0, 6.0, 7.5), 50.0, 0.9, 45.0, warm],
		[Vector3(0.0, 1.5, -24.0), Vector3(0.0, 6.0, -7.4), 50.0, 0.85, 45.0, warm],
		[Vector3(32.0, 1.5, -5.0), Vector3(18.0, 6.0, -4.6), 46.0, 0.9, 40.0, warm],
		[Vector3(-12.0, 9.0, 14.0), Vector3(3.5, 11.5, -1.0), 34.0, 0.95, 45.0, warm],
	])

## Pilasters with capitals, the dentil band and framed windows on both
## long faces.
static func _faces(lm: LandmarkMesh) -> void:
	for side: float in [1.0, -1.0]:
		var z: float = ZS if side > 0.0 else ZN
		var out := Vector3(0, 0, side)
		for p: Array in PILASTERS:
			var x: float = p[0]
			var w: float = p[1]
			if side > 0.0 and x > -14.5 and x < -8.8:
				continue
			if side < 0.0 and x > 5.5:
				continue
			lm.box("Trim", Vector3(x, (PLINTH + EAVE - 1.0) * 0.5, z + side * 0.18), Vector3(w, EAVE - 1.0 - PLINTH, 0.36))
			lm.box("Trim", Vector3(x, EAVE - 1.3, z + side * 0.3), Vector3(w + 0.5, 0.6, 0.6))
			# Flutes: three dark grooves down each wide pilaster.
			for g in 3:
				lm.box("Render", Vector3(x + (float(g) - 1.0) * w * 0.28, (PLINTH + EAVE - 1.9) * 0.5, z + side * 0.37),
					Vector3(0.06, EAVE - 1.9 - PLINTH, 0.04))
		var x0 := -20.4
		var x1 := 17.8 if side > 0.0 else 5.9
		var n := int((x1 - x0) / 0.55)
		for k in n:
			lm.box("Trim", Vector3(x0 + (float(k) + 0.5) * (x1 - x0) / float(n), EAVE - 1.15, z + side * 0.5),
				Vector3(0.28, 0.3, 0.3))
		lm.box("Trim", Vector3((x0 + x1) * 0.5, EAVE - 0.7, z + side * 0.45), Vector3(x1 - x0, 0.14, 0.2))
		var xs: Array[float] = []
		if side > 0.0:
			xs.assign([-16.0, -6.4, -0.2, 14.9])
		else:
			xs.assign([-15.9, -2.0, 2.3, 4.5])
		for x in xs:
			if side < 0.0 and x > 5.0:
				continue
			P.win_row(lm, "Frame", "Glass", Vector3(x, 0, z), Vector3(x, 0, z), out, PLINTH + 0.7, 1, 1.5, 2.5, false, 0.2)
			P.win_row(lm, "Frame", "Glass", Vector3(x, 0, z), Vector3(x, 0, z), out, 4.9, 1, 1.5, 2.3, false, 0.2)
		if side > 0.0:
			P.win_row(lm, "Frame", "Glass", Vector3(4.7, 0, z), Vector3(4.7, 0, z), out, 2.0, 1, 1.3, 6.0, false, 0.2)
		else:
			P.win_row(lm, "Frame", "Glass", Vector3(-9.0, 0, z), Vector3(-9.0, 0, z), out, PLINTH + 0.7, 1, 1.5, 2.5, false, 0.2)
	# West end wall: two windows a floor.
	P.win_row(lm, "Frame", "Glass", Vector3(-20.5, 0, -3.6), Vector3(-20.5, 0, 3.6), Vector3(-1, 0, 0), PLINTH + 0.7, 2, 1.5, 2.5, false, 0.2)
	P.win_row(lm, "Frame", "Glass", Vector3(-20.5, 0, -3.6), Vector3(-20.5, 0, 3.6), Vector3(-1, 0, 0), 4.9, 2, 1.5, 2.3, false, 0.2)

## The taller east block with its five small square windows.
static func _east_block(lm: LandmarkMesh) -> void:
	lm.box("Render", Vector3(14.3, EAVE + 0.9, 0.0), Vector3(7.2, 1.8, 15.0))
	lm.box("Trim", Vector3(14.3, EAVE + 1.9, 0.0), Vector3(7.8, 0.3, 15.6))
	lm.box("Roof", Vector3(14.3, EAVE + 2.1, 0.0), Vector3(7.4, 0.15, 15.2))
	P.win_row(lm, "Frame", "Glass", Vector3(11.5, 0, 7.5), Vector3(17.0, 0, 7.5), Vector3(0, 0, 1), EAVE + 0.5, 5, 0.8, 0.9, false, 0.2)

## Ribbed dome on a low drum, with a flagpole beside it.
static func _dome(lm: LandmarkMesh) -> void:
	var c := DOME_C + Vector3(0, EAVE + 0.2, 0)
	lm.frustum("Render", c, 4.7, 4.7, 1.5, 24)
	lm.frustum("Trim", c + Vector3(0, 1.5, 0), 4.95, 4.95, 0.3, 24)
	lm.lathe("Dome", c + Vector3(0, 1.8, 0), U.dome_prof(4.5, 2.6), 24)
	var prof := U.dome_prof(4.5, 2.6, 6)
	for i in 16:
		var a := TAU * float(i) / 16.0
		var d := Vector3(cos(a), 0, sin(a))
		for j in prof.size() - 2:
			lm.beam("Dome", c + Vector3(0, 1.8, 0) + d * (prof[j].x + 0.04) + Vector3(0, prof[j].y, 0),
				c + Vector3(0, 1.8, 0) + d * (prof[j + 1].x + 0.04) + Vector3(0, prof[j + 1].y, 0), 0.12, 0.1, d.cross(Vector3.UP))
	lm.beam("Trim", c + Vector3(-3.4, 1.8, -1.0), c + Vector3(-3.4, 7.0, -1.0), 0.14)

## The south bay window with its balcony and the east entrance with its
## own balcony.
static func _bays(lm: LandmarkMesh) -> void:
	var bz := 9.2
	P.win_row(lm, "Frame", "Glass", Vector3(-13.0, 0, bz), Vector3(-10.4, 0, bz), Vector3(0, 0, 1), PLINTH + 0.7, 3, 1.3, 2.5, false, 0.15)
	lm.box("Trim", Vector3(-11.7, 4.3, 8.4), Vector3(6.2, 0.3, 3.2))
	lm.box("Trim", Vector3(-11.7, 4.95, 9.85), Vector3(5.6, 1.0, 0.12))
	lm.box("Trim", Vector3(-14.4, 4.95, 8.6), Vector3(0.12, 1.0, 2.5))
	lm.box("Trim", Vector3(-9.0, 4.95, 8.6), Vector3(0.12, 1.0, 2.5))
	# East entrance: door, steps and the balcony over it.
	lm.box("Frame", Vector3(15.6, 1.9, 8.7), Vector3(1.6, 2.6, 0.2))
	U.steps(lm, "Plinth", Vector3(15.6, 0, 8.6), Vector3.BACK, 3.2, 0.38, 0.17, 5)
	lm.box("Trim", Vector3(15.0, 4.3, 9.4), Vector3(5.4, 0.3, 1.9))
	lm.box("Trim", Vector3(15.0, 4.95, 10.28), Vector3(5.4, 1.0, 0.12))
	lm.box("Trim", Vector3(12.3, 4.95, 9.5), Vector3(0.12, 1.0, 1.8))
	lm.box("Trim", Vector3(17.7, 4.95, 9.5), Vector3(0.12, 1.0, 1.8))
	for x: float in [12.9, 17.1]:
		lm.frustum("Trim", Vector3(x, 0.0, 9.9), 0.26, 0.24, 4.3, 10)

## Semicircular colonnaded bay at the north-east corner, round balcony over.
static func _round_bay(lm: LandmarkMesh) -> void:
	for k in 5:
		var a := deg_to_rad(-62.0 + 31.0 * float(k))
		var p := BAY_C + Vector3(cos(a), 0, sin(a)) * 3.6
		lm.frustum("Trim", p, 0.3, 0.26, 3.9, 12)
	lm.frustum("Trim", BAY_C + Vector3(0, 3.9, 0), 3.9, 3.9, 0.35, 20)
	lm.frustum("Trim", BAY_C + Vector3(0, 4.25, 0), 3.8, 3.8, 0.12, 20)
	lm.lathe("Roof", BAY_C + Vector3(0, 7.5, 0), U.dome_prof(3.4, 0.9), 20)
