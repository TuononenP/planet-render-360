extends RefCounted

## Kungliga Dramatiska teatern, "Dramaten" (Fredrik Lilljekvist, 1901-08),
## Nybroplan. Origin at the OSM footprint centre (way 24210110, 60.7 x 53 m),
## front +Z. The registry yaw (22.6) turns local +Z onto bearing 202.6, the
## front facing south-south-west over Nybroplan; local +X is bearing 112.6.
##
## From the photos (front, quarter, aerial in visual-plan/refs/landmarks/
## dramaten/; the first front.jpg was an interior and was replaced):
## - Pale cream limestone and granite, Art Nouveau classicism. A rusticated
##   ground storey 6.5 m with arched windows, a tall piano nobile of
##   mullioned windows, a row of smaller windows, then the relief frieze under
##   the main cornice at 22.5 m.
## - The front: a central portico of four stout pillars with sculpted
##   shafts over a wide stair, the gilded canopy before the doors, and above
##   the portico a stone terrace with a balustrade. Behind it the wall rises
##   with three big windows, three small ones under the relief frieze, and
##   the attic with the sun cartouche and a group of three figures.
## - Two canted (octagonal) corner pavilions flank the front, taller than the
##   wings, each capped by a low green copper roof; the long flanks are plain
##   ashlar with three storeys of windows.
## - Over the middle of the house stands a square tower with louvred
##   windows, a cornice and corner urns, carrying the pale lead-clad
##   segmental dome with its finial (the tallest point, 37 m). The main roofs
##   are low dark sheet-metal hips.
## - Behind, a stage house 34 x 20 m rises to 28 m under a green copper hip
##   roof with a louvred lantern; lower side wings (19.5 m) flank it.
## - Before the front stand four stone lamp pillars topped with gilded lamp
##   clusters, on the paved forecourt behind a low granite kerb wall.
## Height 37 m is the dome finial, scaled from the aerial and quarter views
## against the 22.5 m cornice (OSM has only `building:levels=5`); the pavilion,
## stage house and tower heights are likewise photo-scaled.

const K = preload("res://scripts/generation/landmarks/sweden_stockholm/palaces/sto_pal_kit.gd")
const FhU = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")

const HW := 26.5
const ZB := -30.4
const ZF := 26.0
const ZP := 30.6
const BASE := 6.5
const CORN := 22.5
const REAR := 19.5
const STAGE := 28.0
const TOWER_Y := 31.0
const TOP := 37.0
const PAV_X := 20.0
const PAV_Z := 20.5
const PAV_FLAT := 6.0
const PAV_TOP := 25.0
const TOWER_Z := 12.0
const WING_X := 14.0
const POR_HW := 10.5

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#CDBA98", 3.0))
	lm.use("Base", LandmarkMaterials.pbr("limestone", "#B3A287", 2.4))
	lm.use("Relief", LandmarkMaterials.pbr("limestone", "#B9A684", 2.0))
	lm.use("Glass", LandmarkMaterials.glass("#2A3138"))
	lm.use("Frame", LandmarkMaterials.paint("#3D3A36", 0.5, 0.3))
	lm.use("Roof", LandmarkMaterials.pbr("sheet_metal", "#4A4A4D", 3.0, 0.6, 0.4))
	lm.use("Copper", LandmarkMaterials.pbr("sheet_metal", "#6F9C88", 3.0, 0.55, 0.35))
	lm.use("Dome", LandmarkMaterials.pbr("sheet_metal", "#D2D2CB", 2.5, 0.45, 0.45))
	lm.use("Gilt", LandmarkMaterials.gold())
	lm.use("Step", LandmarkMaterials.pbr("stone", "#9B948E", 3.0))
	lm.use("Door", LandmarkMaterials.pbr("wood", "#3C2B20", 2.0))
	_mass(lm)
	_front_wall(lm)
	_pavilions(lm)
	_flanks(lm)
	_portico(lm)
	_attic(lm)
	_tower(lm)
	_stage_house(lm)
	_roofs(lm)
	_forecourt(lm)
	lm.commit(model)
	# Night: the front and the dome are floodlit from the forecourt.
	var warm := Color(1.0, 0.86, 0.68)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-26.0, 1.5, 50.0), Vector3(-9.0, 13.0, 27.0), 45.0, 0.9, 62.0, warm],
		[Vector3(26.0, 1.5, 50.0), Vector3(9.0, 13.0, 27.0), 45.0, 0.9, 62.0, warm],
		[Vector3(0.0, 1.5, 56.0), Vector3(0.0, 26.0, 18.0), 38.0, 0.8, 72.0, warm]])

# --- Massing -----------------------------------------------------------

## The ashlar block: front range to the main cornice, lower rear range.
static func _mass(lm: LandmarkMesh) -> void:
	K.rb(lm, "Stone", -HW, HW, 0.0, CORN, -6.0, ZF, 0.0)
	K.rb(lm, "Stone", -HW, HW, 0.0, REAR, ZB, -6.0, 0.0)
	# Cornice and the low parapet ring above it round the front range.
	K.rb(lm, "Stone", -HW - 0.4, HW + 0.4, CORN - 0.2, CORN + 0.5, -6.0, ZF + 0.5, 0.0)
	K.rb(lm, "Stone", -HW - 0.4, HW + 0.4, REAR - 0.2, REAR + 0.5, ZB, -6.0, 0.0)
	K.courses(lm, "Base", Vector3(0, 0, ZF), Vector3(0, 0, 1), 2.0 * WING_X, 0.0, BASE, 1.3)

# --- Front -----------------------------------------------------------------

## Window bands of the front wall between the pavilions: ground, piano
## nobile and the upper row over the x range x0..x1.
static func _bands(lm: LandmarkMesh, x0: float, x1: float, ground: bool) -> void:
	var n := Vector3(0, 0, 1)
	var r := Vector3(1, 0, 0)
	var w := x1 - x0
	var cols := maxi(int(roundf(w / 4.4)), 1)
	if ground:
		LandmarkDetail.pierced_face(lm, "Base", "Glass", Vector3(x0, 0.0, ZF), r, n, w, BASE, cols, 1,
			Vector2(1.9, 4.2), 1.0, 7.0)
	LandmarkDetail.pierced_face(lm, "Stone", "Glass", Vector3(x0, BASE, ZF), r, n, w, 9.0, cols, 1,
		Vector2(2.2, 5.6), 1.4, 9.0)
	LandmarkDetail.pierced_face(lm, "Stone", "Glass", Vector3(x0, BASE + 9.0, ZF), r, n, w, CORN - BASE - 9.0,
		cols, 1, Vector2(1.7, 3.0), 1.6, 7.0)

## The wall behind the portico and the narrow wing bays beside it.
static func _front_wall(lm: LandmarkMesh) -> void:
	_bands(lm, -WING_X, -POR_HW, true)
	_bands(lm, POR_HW, WING_X, true)
	# Over the portico: three big windows, then three small ones.
	var n := Vector3(0, 0, 1)
	var r := Vector3(1, 0, 0)
	var w := 2.0 * POR_HW
	LandmarkDetail.pierced_face(lm, "Stone", "Glass", Vector3(-POR_HW, BASE, ZF), r, n, w, 9.0, 3, 1,
		Vector2(3.4, 6.2), 1.3, 9.0)
	LandmarkDetail.pierced_face(lm, "Stone", "Glass", Vector3(-POR_HW, BASE + 9.0, ZF), r, n, w, 4.2, 3, 1,
		Vector2(2.0, 2.6), 0.8, 7.0)
	# The recessed ground wall behind the pillars: three tall doors.
	K.rb(lm, "Base", -POR_HW, POR_HW, 0.0, BASE, ZF - 1.6, ZF - 1.0, 0.0)
	for x in [-6.0, 0.0, 6.0]:
		LandmarkDetail.window(lm, "Frame", "Door", Vector3(float(x), 2.5, ZF - 0.95), n, 2.6, 4.6, true, 0.2)
	# The relief frieze under the main cornice, between the pavilions.
	K.rb(lm, "Relief", -WING_X, WING_X, CORN - 3.0, CORN - 0.4, ZF, ZF + 0.3, 0.0)

# --- Pavilions ---------------------------------------------------------

## The two canted corner pavilions: octagonal prisms with windows on the
## three outer faces, a cornice and a low green copper roof.
static func _pavilions(lm: LandmarkMesh) -> void:
	var rr := PAV_FLAT / cos(PI / 8.0)
	for s in [-1.0, 1.0]:
		var c := Vector2(float(s) * PAV_X, PAV_Z)
		lm.poly_prism("Stone", _octagon(c, rr), 0.0, PAV_TOP, false)
		lm.poly_prism("Base", _octagon(c, rr + 0.12), 0.0, BASE, false)
		lm.poly_prism("Stone", _octagon(c, rr + 0.45), PAV_TOP - 1.0, PAV_TOP + 0.3, true)
		lm.spire("Copper", Vector3(c.x, PAV_TOP + 0.3, c.y), PAV_FLAT + 0.1, 2.2, 1.6, 8)
		# Faces: +z, the outward chamfer, the outer flank.
		for a_deg in [90.0, 90.0 + 45.0 * float(s) * -1.0, 90.0 + 90.0 * float(s) * -1.0]:
			var a := deg_to_rad(a_deg)
			var out := Vector3(cos(a), 0, sin(a))
			var p := Vector3(c.x, 0.0, c.y) + out * (PAV_FLAT + 0.07)
			FhU.opening(lm, "Glass", p + Vector3(0, 1.0, 0), out, 1.7, 4.2, true)
			FhU.opening(lm, "Glass", p + Vector3(0, BASE + 1.0, 0), out, 1.9, 5.4, false)
			FhU.opening(lm, "Glass", p + Vector3(0, BASE + 9.0 + 1.2, 0), out, 1.5, 2.8, false)
			var q := p + out * 0.04
			lm.box("Relief", Vector3(q.x, PAV_TOP - 2.0, q.z), Vector3(3.6, 1.6, 0.18),
				Basis(Vector3.UP, atan2(out.x, out.z)), 0.0)
		K.courses(lm, "Base", Vector3(c.x, 0, c.y + PAV_FLAT), Vector3(0, 0, 1), 3.8, 0.0, BASE, 1.3)

static func _octagon(c: Vector2, r: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for k in 8:
		var a := PI / 8.0 + TAU * float(k) / 8.0
		pts.append(c + Vector2(cos(a), sin(a)) * r)
	return pts

# --- Flanks ------------------------------------------------------------

## Both long flanks and the rear wall: ashlar with three storeys of windows.
static func _flanks(lm: LandmarkMesh) -> void:
	for s in [-1.0, 1.0]:
		var sg := float(s)
		var out := Vector3(sg, 0, 0)
		var r := K.right(out)
		# Front range, between the rear range and the pavilion.
		var z_hi := PAV_Z - PAV_FLAT * 0.4
		LandmarkDetail.pierced_face(lm, "Stone", "Glass", Vector3(sg * HW, 0.0, z_hi if sg > 0.0 else -6.0), r, out,
			z_hi + 6.0, CORN, 5, 3, Vector2(1.7, 4.5), 1.2, 7.0)
		LandmarkDetail.pierced_face(lm, "Stone", "Glass", Vector3(sg * HW, 0.0, -6.0 if sg > 0.0 else ZB), r, out,
			-6.0 - ZB, REAR, 6, 3, Vector2(1.6, 4.0), 1.2, 6.4)
		K.courses(lm, "Base", Vector3(sg * HW, 0, -6.0), out, 40.0, 0.0, BASE, 1.3)
	LandmarkDetail.pierced_face(lm, "Stone", "Glass", Vector3(HW, 0.0, ZB), Vector3(-1, 0, 0), Vector3(0, 0, -1),
		2.0 * HW, REAR, 10, 3, Vector2(1.7, 4.0), 1.2, 6.4)

# --- Portico -----------------------------------------------------------

## Stair, four pillars, entablature, terrace balustrade, gilded canopy.
static func _portico(lm: LandmarkMesh) -> void:
	FhU.steps(lm, "Step", Vector3(0, 0, ZP), Vector3(0, 0, 1), 2.0 * POR_HW + 2.0, 0.45, 0.2, 5)
	K.rb(lm, "Step", -POR_HW, POR_HW, 0.0, 1.0, ZF - 1.6, ZP, 0.0)
	for x in [-9.0, -3.0, 3.0, 9.0]:
		var base := Vector3(float(x), 1.0, ZP - 1.4)
		lm.box("Stone", base + Vector3(0, 0.3, 0), Vector3(2.0, 0.6, 2.0), Basis(), 0.0)
		lm.frustum("Stone", base + Vector3(0, 0.6, 0), 0.9, 0.78, 4.6, 12)
		lm.box("Relief", base + Vector3(0, 3.6, 0), Vector3(1.9, 1.4, 1.9), Basis(), 0.0)
		lm.box("Stone", base + Vector3(0, 5.5, 0), Vector3(2.2, 0.5, 2.2), Basis(), 0.0)
	# Entablature and the terrace slab over it.
	K.rb(lm, "Stone", -POR_HW - 0.6, POR_HW + 0.6, BASE - 0.4, BASE + 0.5, ZF, ZP + 0.4, 0.0)
	K.rb(lm, "Relief", -POR_HW, POR_HW, BASE - 1.5, BASE - 0.4, ZP - 2.4, ZP, 0.0)
	var y := BASE + 0.5
	LandmarkDetail.balustrade(lm, "Stone", Vector3(-POR_HW - 0.6, y, ZP + 0.4), Vector3(POR_HW + 0.6, y, ZP + 0.4), 1.0, 3.0, 6)
	LandmarkDetail.balustrade(lm, "Stone", Vector3(-POR_HW - 0.6, y, ZF), Vector3(-POR_HW - 0.6, y, ZP + 0.4), 1.0, 3.0, 6)
	LandmarkDetail.balustrade(lm, "Stone", Vector3(POR_HW + 0.6, y, ZF), Vector3(POR_HW + 0.6, y, ZP + 0.4), 1.0, 3.0, 6)
	# Gilded canopy before the doors.
	K.awning(lm, "Gilt", Vector3(0, 5.3, ZP - 0.2), Vector3(0, 0, 1), 11.0, 3.4, 1.0)

## The attic over the portico: cartouche with the sun face, three figures.
static func _attic(lm: LandmarkMesh) -> void:
	K.rb(lm, "Stone", -7.0, 7.0, CORN + 0.5, CORN + 3.4, ZF - 2.0, ZF + 0.5, 0.0)
	K.rb(lm, "Stone", -7.6, 7.6, CORN + 3.4, CORN + 3.9, ZF - 2.2, ZF + 0.8, 0.0)
	lm.disc("Gilt", Vector3(0, CORN + 2.0, ZF + 0.55), Vector3(0, 0, 1), 1.3, 20)
	lm.disc("Relief", Vector3(0, CORN + 2.0, ZF + 0.52), Vector3(0, 0, 1), 1.9, 20)
	for x in [-3.2, 0.0, 3.2]:
		K.figure(lm, "Stone", Vector3(float(x), CORN + 3.9, ZF - 0.8), 3.0)
	for x in [-6.6, 6.6]:
		K.urn(lm, "Stone", Vector3(float(x), CORN + 3.9, ZF - 0.8), 1.6)

# --- Tower and dome ------------------------------------------------------

static func _tower(lm: LandmarkMesh) -> void:
	var hw := 7.0
	K.rb(lm, "Stone", -hw, hw, CORN, TOWER_Y, TOWER_Z - hw, TOWER_Z + hw, 0.0)
	for s in [-1.0, 1.0]:
		for t in [-1.0, 1.0]:
			K.rb(lm, "Relief", float(s) * hw - 0.9, float(s) * hw + 0.9, CORN + 1.0, TOWER_Y,
				TOWER_Z + float(t) * hw - 0.9, TOWER_Z + float(t) * hw + 0.9, 0.0)
	# Three louvred lights on each face.
	var faces := [[Vector3(0, 0, 1), Vector3(0, 0, TOWER_Z + hw)], [Vector3(0, 0, -1), Vector3(0, 0, TOWER_Z - hw)],
		[Vector3(1, 0, 0), Vector3(hw, 0, TOWER_Z)], [Vector3(-1, 0, 0), Vector3(-hw, 0, TOWER_Z)]]
	for f in faces:
		var out: Vector3 = f[0]
		var p: Vector3 = f[1]
		K.holes(lm, "Frame", p + out * 0.03, out, [-3.0, 0.0, 3.0], CORN + 3.4, 1.3, 3.4, false)
	for f in faces:
		var out: Vector3 = f[0]
		var p: Vector3 = f[1]
		var along := K.right(out)
		var a := p - along * (hw + 0.5) + Vector3(0, TOWER_Y, 0) + out * 0.2
		var b := p + along * (hw + 0.5) + Vector3(0, TOWER_Y, 0) + out * 0.2
		LandmarkDetail.cornice(lm, "Stone", a, b, out, 0.9, false)
	for s in [-1.0, 1.0]:
		for t in [-1.0, 1.0]:
			K.urn(lm, "Stone", Vector3(float(s) * (hw - 0.2), TOWER_Y + 0.9, TOWER_Z + float(t) * (hw - 0.2)), 1.5)
	# The segmental dome, then its finial.
	var y0 := TOWER_Y + 0.9
	var prof := PackedVector2Array([Vector2(6.8, 0.0), Vector2(6.7, 0.5), Vector2(6.2, 1.3), Vector2(5.3, 2.3),
		Vector2(4.0, 3.2), Vector2(2.5, 3.8), Vector2(1.1, 4.1), Vector2(0.6, 4.2)])
	lm.lathe("Dome", Vector3(0, y0, TOWER_Z), prof, 16)
	lm.frustum("Copper", Vector3(0, y0 + 4.2, TOWER_Z), 0.55, 0.28, TOP - (y0 + 4.2), 8)

# --- Stage house and roofs -----------------------------------------------

static func _stage_house(lm: LandmarkMesh) -> void:
	var z0 := ZB + 2.4
	var z1 := -8.0
	K.rb(lm, "Stone", -17.0, 17.0, REAR, STAGE, z0, z1, 0.0)
	K.rb(lm, "Stone", -17.4, 17.4, STAGE - 0.2, STAGE + 0.4, z0 - 0.4, z1 + 0.4, 0.0)
	for s in [-1.0, 1.0]:
		var out := Vector3(float(s), 0, 0)
		LandmarkDetail.pierced_face(lm, "Stone", "Glass", Vector3(float(s) * 17.0, REAR, z1 if s > 0.0 else z0), K.right(out), out,
			z1 - z0, STAGE - REAR, 5, 1, Vector2(1.5, 5.0), 1.6, 8.0)
	LandmarkDetail.pierced_face(lm, "Stone", "Glass", Vector3(17.0, REAR, z0), Vector3(-1, 0, 0), Vector3(0, 0, -1),
		34.0, STAGE - REAR, 8, 1, Vector2(1.7, 5.0), 1.6, 8.0)
	# Copper hip roof and its louvred lantern.
	var cz := (z0 + z1) * 0.5
	FhU.hip(lm, "Copper", Vector3(0, STAGE + 0.4, cz), 34.8, z1 - z0 + 0.8, 5.6, 0.18)
	var ly := STAGE + 0.4 + 5.6
	K.rb(lm, "Frame", -2.8, 2.8, ly, ly + 2.2, cz - 1.7, cz + 1.7, 0.0)
	FhU.hip(lm, "Copper", Vector3(0, ly + 2.2, cz), 6.4, 3.9, 0.7, 0.0)

static func _roofs(lm: LandmarkMesh) -> void:
	# Low dark hips over the front range and the rear range, eaves behind the
	# parapet.
	FhU.hip(lm, "Roof", Vector3(0, CORN + 0.5, 10.0), 2.0 * HW, 32.0, 3.4, 0.6)
	FhU.hip(lm, "Roof", Vector3(0, REAR + 0.5, ZB + 12.2), 2.0 * HW, 24.4, 2.0, 0.85)

# --- Forecourt -----------------------------------------------------------

## Paved forecourt behind its kerb wall and the four lamp pillars.
static func _forecourt(lm: LandmarkMesh) -> void:
	K.rb(lm, "Step", -29.0, 29.0, 0.0, 0.12, ZP, 41.0, 0.0)
	K.rb(lm, "Base", -29.0, 29.0, 0.0, 0.9, 40.6, 41.2, 0.0)
	for x in [-21.5, -8.0, 8.0, 21.5]:
		var p := Vector3(float(x), 0.12, 36.5)
		lm.box("Stone", p + Vector3(0, 0.6, 0), Vector3(1.8, 1.2, 1.8), Basis(), 0.0)
		lm.frustum("Stone", p + Vector3(0, 1.2, 0), 0.55, 0.45, 5.6, 10)
		lm.box("Gilt", p + Vector3(0, 6.9, 0), Vector3(1.2, 0.35, 1.2), Basis(), 0.0)
		lm.frustum("Gilt", p + Vector3(0, 7.1, 0), 0.4, 0.2, 1.5, 8)
		for k in 3:
			var a := TAU * float(k) / 3.0
			lm.lathe("Gilt", p + Vector3(cos(a) * 0.8, 7.2, sin(a) * 0.8), LandmarkFhUtil.ball(0.4), 8)
		lm.lathe("Gilt", p + Vector3(0, 8.4, 0), LandmarkFhUtil.ball(0.35), 8)
