extends RefCounted

## St Henry's Cathedral (Pyhan Henrikin katedraali, Ernst Lohrmann, 1860),
## Ullanlinna: the Catholic cathedral, a small Gothic Revival church. Front
## +Z carries the tower; the registry yaw (-101.4) turns it onto the east
## along the long axis of OSM way 22467530 (the apse is the round bulge at
## its other end).
##
## From the Commons photos in visual-plan/refs/landmarks/st_henrys_cathedral/:
## - dark red-brown brick (not light) with paler brick string courses,
##   green copper roofs, granite steps and a black iron fence;
## - a three-stage square tower that rises from a porch on the gabled front
##   wall: a pointed-arch portal with a patinated green door and a flight
##   of steps; a gilded statue of St Henry in a pointed niche and a round
##   window; then the belfry with paired louvred pointed openings, corbel
##   cornices, and a steep pyramidal copper spire with ball and black cross;
## - the nave gable front has two white statues in pointed niches either
##   side of the tower and a small brick pinnacle with a copper cone at each
##   corner, and crosses in brickwork;
## - a polygonal apse behind the nave.
##
## Measured: position and axis (OSM). Estimated by scaling the photos to
## the registry 24 m (cross tip): nave 11.2 x 20 m, eaves 7 m, ridge 11.6 m,
## tower 4.4 m square to 17.8 m, spire to 22.6 m, cross to 24 m. The OSM
## outline also holds a round annex that is not modelled; LoD2 could not be
## read in this run.

const U = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")
const P = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_parts.gd")

const ENTRY := {"type": "st_henrys_cathedral", "name": "St Henry's Cathedral", "lat": 60.159195, "lon": 24.954388,
	"radius_m": 1500.0, "wiki_title": "St Henry's Cathedral, Helsinki", "height_m": 24.0, "clear_m": 24.0,
	"yaw_deg": -101.4, "kind": "Cathedral", "aliases": ["st henry's cathedral", "pyhän henrikin katedraali", "sankt henriks katedral"]}

const NAVE_HW := 5.6
const Z_NAVE0 := -10.0
const Z_NAVE1 := 10.0
const EAVE := 7.0
const RIDGE := 4.6
const TOWER_HW := 2.2
const TOWER_Z0 := 8.0
const TOWER_Z1 := 12.4
const SHAFT := 17.8

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#7C3A2E", 2.0))
	lm.use("Trim", LandmarkMaterials.pbr("brick", "#9A5642", 2.0))
	lm.use("Copper", LandmarkMaterials.paint("#6FA58E", 0.5, 0.45))
	lm.use("Glass", LandmarkMaterials.glass("#2A3034"))
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#8A857E", 2.5))
	lm.use("Statue", LandmarkMaterials.paint("#E9E7E0", 0.6, 0.1))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.use("Iron", LandmarkMaterials.paint("#1E2022", 0.6, 0.5))
	_nave(lm)
	_tower(lm)
	_front_details(lm)
	_fence(lm)
	lm.commit(model)
	# Night: the front and the tower are lit from the street.
	var warm := Color(1.0, 0.94, 0.82)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-7.0, 1.0, 22.0), Vector3(0.0, 9.0, 11.0), 30.0, 1.0, 50.0, warm],
		[Vector3(7.0, 1.0, 22.0), Vector3(0.0, 9.0, 11.0), 30.0, 1.0, 50.0, warm],
	])

## Nave, buttressed lancets, the apse and the corner pinnacles.
static func _nave(lm: LandmarkMesh) -> void:
	var cz := (Z_NAVE0 + Z_NAVE1) * 0.5
	var ln := Z_NAVE1 - Z_NAVE0
	U.blk(lm, "Trim", 0.0, 0.0, cz, NAVE_HW * 2.0 + 0.3, 0.7, ln + 0.3)
	U.blk(lm, "Brick", 0.0, 0.0, cz, NAVE_HW * 2.0, EAVE, ln)
	U.ridge_z(lm, "Copper", "Brick", Vector3(0, EAVE, cz), NAVE_HW * 2.0, ln, RIDGE, 0.35)
	lm.box("Trim", Vector3(0, EAVE - 0.15, cz), Vector3(NAVE_HW * 2.0 + 0.4, 0.3, ln + 0.4))
	for s: float in [-1.0, 1.0]:
		var out := Vector3(s, 0, 0)
		for k in 4:
			var z := -7.0 + float(k) * 4.4
			P.lancet(lm, "Trim", "Glass", Vector3(s * NAVE_HW, 1.6, z), out, 1.1, 4.6, 0.25)
			lm.box("Brick", Vector3(s * (NAVE_HW + 0.2), 3.3, z + 2.2), Vector3(0.45, 6.6, 0.55))
	# Apse: half a heptagon behind the nave with a conical copper roof.
	lm.frustum("Brick", Vector3(0, 0, Z_NAVE0), 4.8, 4.8, 6.4, 7, PI / 7.0)
	lm.lathe("Copper", Vector3(0, 6.4, Z_NAVE0), PackedVector2Array([Vector2(5.2, 0), Vector2(0.3, 4.4), Vector2(0, 4.6)]), 7, 1.0, 1.0, PI / 7.0, false)
	for k in 3:
		var a := PI + deg_to_rad(-45.0 + 45.0 * float(k))
		var d := Vector3(sin(a), 0, cos(a))
		P.lancet(lm, "Trim", "Glass", Vector3(0, 1.4, Z_NAVE0) + d * 4.3, d, 1.0, 4.2, 0.2)
	# Corner pinnacles on the front gable.
	for s: float in [-1.0, 1.0]:
		U.blk(lm, "Brick", s * (NAVE_HW - 0.3), 0.0, Z_NAVE1 - 0.3, 1.0, EAVE + 3.6, 1.0)
		lm.lathe("Copper", Vector3(s * (NAVE_HW - 0.3), EAVE + 3.6, Z_NAVE1 - 0.3), PackedVector2Array([Vector2(0.75, 0), Vector2(0.05, 2.0), Vector2(0, 2.2)]), 4, 1.0, 1.0, PI / 4.0, false)

## The tower: shaft with string courses and corbel friezes, the louvred
## belfry, four corner pinnacles and the copper spire with cross.
static func _tower(lm: LandmarkMesh) -> void:
	var cz := (TOWER_Z0 + TOWER_Z1) * 0.5
	var w := TOWER_HW * 2.0
	var d := TOWER_Z1 - TOWER_Z0
	U.blk(lm, "Trim", 0.0, 0.0, cz, w + 0.5, 0.7, d + 0.5)
	U.blk(lm, "Brick", 0.0, 0.0, cz, w, SHAFT, d)
	for y: float in [7.6, 12.9]:
		lm.box("Trim", Vector3(0, y, cz), Vector3(w + 0.4, 0.28, d + 0.4))
		for s: float in [-1.0, 1.0]:
			P.arch_frieze(lm, "Trim", Vector3(-TOWER_HW, 0, cz + s * d * 0.5), Vector3(TOWER_HW, 0, cz + s * d * 0.5), Vector3(0, 0, s), y, 0.55, 0.15)
			P.arch_frieze(lm, "Trim", Vector3(s * TOWER_HW, 0, cz - d * 0.5), Vector3(s * TOWER_HW, 0, cz + d * 0.5), Vector3(s, 0, 0), y, 0.55, 0.15)
	lm.box("Trim", Vector3(0, SHAFT - 0.2, cz), Vector3(w + 0.6, 0.4, d + 0.6))
	# Belfry: paired louvred pointed openings on all four faces.
	for dx: float in [-0.75, 0.75]:
		P.lancet(lm, "Trim", "Glass", Vector3(dx, 13.4, TOWER_Z1), Vector3(0, 0, 1), 0.9, 3.4, 0.2, false)
		P.lancet(lm, "Trim", "Glass", Vector3(dx, 13.4, TOWER_Z0), Vector3(0, 0, -1), 0.9, 3.4, 0.2, false)
		P.lancet(lm, "Trim", "Glass", Vector3(TOWER_HW, 13.4, cz + dx), Vector3(1, 0, 0), 0.9, 3.4, 0.2, false)
		P.lancet(lm, "Trim", "Glass", Vector3(-TOWER_HW, 13.4, cz + dx), Vector3(-1, 0, 0), 0.9, 3.4, 0.2, false)
	# Round window and the niche with the gilded statue on the front.
	P.ring(lm, "Trim", Vector3(0, 10.6, TOWER_Z1 + 0.02), Vector3(0, 0, 1), 0.45, 0.7, 0.12, 14)
	lm.box("Glass", Vector3(0, 10.6, TOWER_Z1 + 0.03), Vector3(0.9, 0.9, 0.04))
	P.lancet(lm, "Trim", "Glass", Vector3(0, 6.1, TOWER_Z1), Vector3(0, 0, 1), 1.2, 2.6, 0.25, false)
	lm.box("Gold", Vector3(0, 7.0, TOWER_Z1 - 0.1), Vector3(0.45, 1.3, 0.35))
	# Gablets on the four faces, corner pinnacles, spire, ball and cross.
	for s: float in [-1.0, 1.0]:
		U.blk(lm, "Brick", s * (TOWER_HW - 0.2), SHAFT, TOWER_Z0 + 0.2, 0.5, 0.7, 0.5)
		U.blk(lm, "Brick", s * (TOWER_HW - 0.2), SHAFT, TOWER_Z1 - 0.2, 0.5, 0.7, 0.5)
	lm.spire("Copper", Vector3(0, SHAFT, cz), TOWER_HW + 0.15, 4.8, 0.0, 4)
	lm.lathe("Copper", Vector3(0, SHAFT + 4.7, cz), U.ball(0.32), 10)
	lm.box("Iron", Vector3(0, SHAFT + 5.9, cz), Vector3(0.1, 1.5, 0.1))
	lm.box("Iron", Vector3(0, SHAFT + 6.2, cz), Vector3(0.75, 0.1, 0.1))

## Portal and steps, the nave-front niches with their white statues, brick
## crosses.
static func _front_details(lm: LandmarkMesh) -> void:
	P.lancet(lm, "Trim", "Copper", Vector3(0, 0.7, TOWER_Z1), Vector3(0, 0, 1), 1.9, 4.2, 0.45)
	U.steps(lm, "Granite", Vector3(0, 0, TOWER_Z1 + 0.1), Vector3.BACK, 3.4, 0.45, 0.16, 5)
	for s: float in [-1.0, 1.0]:
		var x := s * 3.9
		P.lancet(lm, "Trim", "Glass", Vector3(x, 1.7, Z_NAVE1), Vector3(0, 0, 1), 1.5, 3.8, 0.25, false)
		lm.box("Statue", Vector3(x, 2.4, Z_NAVE1 + 0.05), Vector3(0.7, 0.4, 0.5))
		lm.frustum("Statue", Vector3(x, 2.6, Z_NAVE1 + 0.05), 0.42, 0.28, 1.5, 8)
		lm.lathe("Statue", Vector3(x, 4.1, Z_NAVE1 + 0.05), U.ball(0.24), 8)
		# Brick crosses on the gable.
		for p in [[s * 3.2, 8.6], [s * 4.7, 7.9]]:
			lm.box("Trim", Vector3(p[0], p[1], Z_NAVE1 + 0.03), Vector3(0.1, 0.6, 0.06))
			lm.box("Trim", Vector3(p[0], p[1] + 0.1, Z_NAVE1 + 0.03), Vector3(0.4, 0.1, 0.06))

## Black iron fence on a granite kerb across the front, a gap for the steps.
static func _fence(lm: LandmarkMesh) -> void:
	var z := 16.4
	for run in [[-9.5, -2.2], [2.2, 9.5]]:
		var a: float = run[0]
		var b: float = run[1]
		U.blk(lm, "Granite", (a + b) * 0.5, 0.0, z, b - a, 0.4, 0.4)
		lm.beam("Iron", Vector3(a, 1.35, z), Vector3(b, 1.35, z), 0.05, 0.05, Vector3.UP)
		lm.beam("Iron", Vector3(a, 0.6, z), Vector3(b, 0.6, z), 0.05, 0.05, Vector3.UP)
		var n := int((b - a) / 0.9)
		for k in n + 1:
			var x := a + (b - a) * float(k) / float(n)
			lm.beam("Iron", Vector3(x, 0.4, z), Vector3(x, 1.55, z), 0.04, 0.04, Vector3.BACK)
