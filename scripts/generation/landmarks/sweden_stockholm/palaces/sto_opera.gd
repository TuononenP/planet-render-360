extends RefCounted

## Kungliga Operan (Axel Anderberg, 1898), Gustav Adolfs torg. Origin at
## the OSM footprint centre (way 16108358, 118 x 66 m), long axis local X.
## The registry yaw (-25.2) turns local +X onto bearing 64.8 deg, so the
## FRONT, on Gustav Adolfs torg to the south-west, is the short -X end and
## the Strömgatan flank with the Operakällaren terrace is +Z (SSE).
##
## From the photos (front, quarter, aerial in visual-plan/refs/landmarks/
## royal_opera_stockholm/):
## - Rusticated pink-grey granite base 9.6 m tall in ~1.2 m courses; above
##   it salmon-ochre render with sandstone dressings.
## - Front 66 m wide, two flush 14 m wings (tall framed window and a
##   cartouche above a large panel; an arched side door in the base) and a
##   38 m central risalit. The risalit: a 4-column Tuscan portico over
##   three arched doors, carrying the balcony with its balustrade; above
##   it four pink-granite Corinthian giant columns frame three arched
##   windows; the entablature (OPERAN in gilt) and cornice; the attic with
##   three oval windows between statues, a cornice and the balustrade.
## - Roofs are low dark sheet-metal hips (the photos show dark grey, not
##   green copper), a drum over the auditorium with a conical cap, glazed
##   roof lights, a flagpole on the front attic.
## - The fly tower (stage house) rises behind to 37.6 m with arched
##   windows, a cornice, a balustrade and urns at its corners.
## - Operakällaren: the terrace wing on the +Z flank with its balustrade
##   and cream awnings, and the glazed veranda at the rear.
## Heights: OSM 41.5 m (the flagpole tip); base 9.6, wings 22.8, attic
## balustrade 30.0, stage cornice 37.6, urns 40.3. Window counts and
## depths of the wings are approximate.

const K = preload("res://scripts/generation/landmarks/sweden_stockholm/palaces/sto_pal_kit.gd")

const X0 := -53.0
const XP := -59.4
const X1 := 59.0
const ZH := 33.0
const BASE := 9.6
const BODY := 22.8
const ATT := 28.8
const STAGE := 37.6
const HALL_X0 := -24.0
const STAGE_X0 := 8.0
const STAGE_X1 := 46.0
const STAGE_Z0 := -17.0
const STAGE_Z1 := 21.0
const RISALIT_HW := 19.0
const COL_Z := [-13.2, -4.4, 4.4, 13.2]
const BAY_Z := [-8.8, 0.0, 8.8]
const PITCH := 7.0
const TOP := 41.5

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("render", "#C99472", 3.0))
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#D4B994", 2.5))
	lm.use("Rust", LandmarkMaterials.pbr("stone", "#B18D7D", 2.0))
	lm.use("Pink", LandmarkMaterials.pbr("stone", "#B98980", 2.0, 0.35))
	lm.use("Roof", LandmarkMaterials.pbr("sheet_metal", "#4B4C4F", 3.0, 0.6, 0.4))
	lm.use("Glass", LandmarkMaterials.glass("#2A3138"))
	lm.use("Door", LandmarkMaterials.pbr("wood", "#4A3022", 2.0))
	lm.use("Gilt", LandmarkMaterials.gold())
	lm.use("Awning", LandmarkMaterials.pbr("render", "#E6E0D0", 2.0))
	lm.use("Pole", LandmarkMaterials.paint("#E9E9E5", 0.5, 0.3))
	lm.use("Iron", LandmarkMaterials.paint("#2A2A2B", 0.5, 0.5))
	lm.use("Lamp", LandmarkMaterials.lit("#FFE2A8", 0.45))
	_mass(lm)
	_front_wings(lm)
	_portico(lm)
	_giant_order(lm)
	_attic(lm)
	_flanks(lm)
	_stage(lm)
	_roofs(lm)
	_kallaren(lm)
	_street(lm)
	lm.commit(model)
	# Night: the real front is floodlit; wash it and the flank from the street.
	var warm := Color(1.0, 0.86, 0.68)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-84.0, 1.5, -20.0), Vector3(-53.0, 13.0, -9.0), 45.0, 0.9, 62.0, warm],
		[Vector3(-84.0, 1.5, 20.0), Vector3(-53.0, 13.0, 9.0), 45.0, 0.9, 62.0, warm],
		[Vector3(-84.0, 1.5, 0.0), Vector3(-53.0, 22.0, 0.0), 40.0, 0.8, 66.0, warm],
		[Vector3(-30.0, 1.5, 58.0), Vector3(-30.0, 12.0, 33.0), 50.0, 0.7, 55.0, warm],
		[Vector3(25.0, 1.5, 58.0), Vector3(25.0, 14.0, 33.0), 50.0, 0.7, 55.0, warm],
	])

# --- Massing -----------------------------------------------------------

## Rusticated base, wall blocks, the stepped front (wings, risalit and
## attic), the hall and ranges, the stage house, and the stone courses.
static func _mass(lm: LandmarkMesh) -> void:
	K.rb(lm, "Rust", X0 - 0.3, X1 + 0.3, 0.0, BASE, -ZH - 0.3, ZH + 0.3)
	K.rb(lm, "Stone", X0 - 0.45, X1 + 0.45, BASE - 0.6, BASE, -ZH - 0.45, ZH + 0.45, 0.0)
	K.rb(lm, "Wall", X0, HALL_X0, BASE, BODY, -ZH, ZH)
	K.rb(lm, "Wall", X0, -29.0, BODY, ATT, -RISALIT_HW, RISALIT_HW)
	K.rb(lm, "Wall", HALL_X0, X1, BASE, BODY, -ZH, ZH)
	K.rb(lm, "Wall", STAGE_X0, STAGE_X1, BODY, STAGE, STAGE_Z0, STAGE_Z1)
	# Granite courses on all four faces of the base.
	for out in [Vector3(-1, 0, 0), Vector3(1, 0, 0), Vector3(0, 0, -1), Vector3(0, 0, 1)]:
		var o: Vector3 = out
		var len := (2.0 * ZH if absf(o.x) > 0.5 else X1 - X0) + 0.6
		var mid := Vector3((X0 + X1) * 0.5, 0, 0) if absf(o.z) > 0.5 else Vector3(0, 0, 0)
		var p: Vector3 = mid + Vector3(X0 - 0.3 if o.x < -0.5 else (X1 + 0.3 if o.x > 0.5 else 0.0), 0,
			(ZH + 0.3) * o.z)
		K.courses(lm, "Rust", p, o, len, 0.0, BASE - 0.6, 1.2, 0.2, 0.12)
	# Cornices round the main body and the stage house.
	for s in [-1.0, 1.0]:
		var sz: float = float(s)
		LandmarkDetail.cornice(lm, "Stone", Vector3(X0 - 0.2, BODY - 1.1, sz * ZH), Vector3(X1 + 0.2, BODY - 1.1, sz * ZH),
			Vector3(0, 0, sz), 1.1, true)
	LandmarkDetail.cornice(lm, "Stone", Vector3(X1, BODY - 1.1, -ZH), Vector3(X1, BODY - 1.1, ZH), Vector3(1, 0, 0), 1.1, true)
	for side in [[Vector3(STAGE_X0 - 0.1, STAGE - 1.1, STAGE_Z0), Vector3(STAGE_X1 + 0.1, STAGE - 1.1, STAGE_Z0), Vector3(0, 0, -1)],
			[Vector3(STAGE_X0 - 0.1, STAGE - 1.1, STAGE_Z1), Vector3(STAGE_X1 + 0.1, STAGE - 1.1, STAGE_Z1), Vector3(0, 0, 1)],
			[Vector3(STAGE_X1, STAGE - 1.1, STAGE_Z0), Vector3(STAGE_X1, STAGE - 1.1, STAGE_Z1), Vector3(1, 0, 0)],
			[Vector3(STAGE_X0, STAGE - 1.1, STAGE_Z0), Vector3(STAGE_X0, STAGE - 1.1, STAGE_Z1), Vector3(-1, 0, 0)]]:
		LandmarkDetail.cornice(lm, "Stone", side[0], side[1], side[2], 1.1, true)

# --- Front -------------------------------------------------------------

## The two wings: arched side door in the base, tall framed window in a
## panel, cartouche above, corner pilaster, cornice.
static func _front_wings(lm: LandmarkMesh) -> void:
	var out := Vector3(-1, 0, 0)
	for s in [-1.0, 1.0]:
		var zc: float = float(s) * 26.0
		var p := Vector3(X0 - 0.3, 0, zc)
		K.wins(lm, "Stone", "Door", p, out, [0.0], 0.4, 2.8, 4.8, true, 0.3)
		K.wins(lm, "Stone", "Glass", Vector3(X0, 0, zc), out, [0.0], 12.0, 2.6, 5.4, false, 0.3)
		# Panel border and cartouche.
		for e in [[0.0, 10.6, 9.4, 0.5], [0.0, 20.0, 9.4, 0.5]]:
			K.rb(lm, "Stone", X0 - 0.15, X0, float(e[1]), float(e[1]) + float(e[3]), zc - float(e[2]) * 0.5, zc + float(e[2]) * 0.5, 0.0)
		for e in [-4.45, 4.45]:
			K.rb(lm, "Stone", X0 - 0.15, X0, 10.6, 20.5, zc + float(e) - 0.25, zc + float(e) + 0.25, 0.0)
		K.rb(lm, "Stone", X0 - 0.25, X0, 18.0, 19.4, zc - 1.5, zc + 1.5)
		lm.disc("Gilt", Vector3(X0 - 0.3, 18.7, zc), out, 0.5, 10)
		# Corner and inner pilasters.
		K.rb(lm, "Stone", X0 - 0.35, X0 + 1.2, BASE, BODY - 1.1, float(s) * (ZH - 1.3) - 0.8, float(s) * (ZH - 1.3) + 0.8)
	LandmarkDetail.cornice(lm, "Stone", Vector3(X0 - 0.2, BODY - 1.1, -ZH), Vector3(X0 - 0.2, BODY - 1.1, -RISALIT_HW), out, 1.1, true)
	LandmarkDetail.cornice(lm, "Stone", Vector3(X0 - 0.2, BODY - 1.1, RISALIT_HW), Vector3(X0 - 0.2, BODY - 1.1, ZH), out, 1.1, true)

## Portico: four pink Tuscan columns and end piers under the balcony, three
## arched doors behind, the steps.
static func _portico(lm: LandmarkMesh) -> void:
	var out := Vector3(-1, 0, 0)
	var floor_y := 0.5
	K.rb(lm, "Stone", XP, X0, 0.0, floor_y, -16.4, 16.4, 0.0)
	for k in 3:
		var d := 0.0 + float(k) * 1.0
		K.rb(lm, "Rust", XP - 1.0 - d, XP - d, 0.0, 0.5 - float(k) * 0.17, -16.0, 16.0, 0.0)
	for z in COL_Z:
		LandmarkDetail.column(lm, "Pink", Vector3(XP + 1.0, floor_y, float(z)), 0.65, 8.4, "tuscan", 0, 12)
	for s in [-1.0, 1.0]:
		K.rb(lm, "Rust", XP, X0, floor_y, 9.0, float(s) * 15.6 - 0.8, float(s) * 15.6 + 0.8)
	K.rb(lm, "Stone", XP - 0.3, X0, 9.0, BASE, -16.7, 16.7)
	K.rb(lm, "Stone", XP - 0.5, XP - 0.3, 9.0, BASE - 0.3, -16.7, 16.7)
	K.wins(lm, "Stone", "Door", Vector3(X0, 0, 0), out, BAY_Z, floor_y, 5.0, 6.8, true, 0.45)
	K.rb(lm, "Door", X0 - 0.35, X0 - 0.3, 0.0, 0.5, -15.0, 15.0, 0.0)
	# Balcony slab and its balustrade.
	K.rb(lm, "Stone", XP - 0.3, X0, BASE, BASE + 0.4, -16.8, 16.8, 0.0)
	var by := BASE + 0.4
	LandmarkDetail.balustrade(lm, "Stone", Vector3(XP - 0.1, by, -16.5), Vector3(XP - 0.1, by, 16.5), 1.15, 4.1, 6)
	for s in [-1.0, 1.0]:
		LandmarkDetail.balustrade(lm, "Stone", Vector3(XP - 0.1, by, float(s) * 16.5), Vector3(X0 - 0.6, by, float(s) * 16.5), 1.15, 3.0, 6)

## Giant order: four Corinthian pink columns, three arched windows between,
## the broken entablature with OPERAN, panels and crests at the sides.
static func _giant_order(lm: LandmarkMesh) -> void:
	var out := Vector3(-1, 0, 0)
	var by := BASE + 0.4
	var cx := XP + 3.9
	for z in COL_Z:
		LandmarkDetail.column(lm, "Pink", Vector3(cx, by, float(z)), 0.62, 10.4, "corinthian", 0, 14)
		K.rb(lm, "Stone", cx - 0.9, cx + 0.9, by, by + 0.5, float(z) - 0.9, float(z) + 0.9, 0.0)
	var ey := by + 10.4
	K.rb(lm, "Stone", cx - 1.0, X0, ey, ey + 0.8, -15.0, 15.0)
	K.rb(lm, "Stone", cx - 1.0, X0, ey + 0.8, ey + 1.9, -15.0, 15.0)
	LandmarkDetail.cornice(lm, "Stone", Vector3(cx - 1.0, ey + 1.9, -15.2), Vector3(cx - 1.0, ey + 1.9, 15.2), out, 1.0, true)
	K.rb(lm, "Gilt", cx - 1.08, cx - 1.0, ey + 1.0, ey + 1.7, -2.6, 2.6, 0.0)
	# Arched windows between the columns, each over a panel and a crest.
	K.wins(lm, "Stone", "Glass", Vector3(X0, 0, 0), out, BAY_Z, by + 0.2, 4.6, 8.6, true, 0.45)
	for z in BAY_Z:
		K.rb(lm, "Stone", X0 - 0.2, X0, by + 9.1, by + 9.9, float(z) - 1.1, float(z) + 1.1)
		lm.disc("Gilt", Vector3(X0 - 0.3, by + 9.5, float(z)), out, 0.35, 8)
	# Side bays of the risalit: pilasters, blank panels with crests.
	for s in [-1.0, 1.0]:
		var sz: float = float(s)
		K.rb(lm, "Stone", X0 - 0.3, X0 + 0.9, BODY - 1.1, ATT, sz * (RISALIT_HW - 0.9) - 0.9, sz * (RISALIT_HW - 0.9) + 0.9)
		K.rb(lm, "Stone", X0 - 0.3, X0 + 0.9, BASE, BODY - 1.1, sz * (RISALIT_HW - 0.9) - 0.9, sz * (RISALIT_HW - 0.9) + 0.9)
		K.rb(lm, "Stone", X0 - 0.15, X0, 12.5, 20.0, sz * 17.0 - 1.9, sz * 17.0 + 1.9, 0.0)
		K.rb(lm, "Wall", X0 - 0.18, X0 - 0.14, 12.9, 19.6, sz * 17.0 - 1.5, sz * 17.0 + 1.5, 0.0)
		K.rb(lm, "Stone", X0 - 0.25, X0, 15.0, 17.0, sz * 17.0 - 1.1, sz * 17.0 + 1.1)

## Attic over the risalit: three oval (round) windows in relief panels
## between four statues, cornice, balustrade with corner piers and urns.
static func _attic(lm: LandmarkMesh) -> void:
	var out := Vector3(-1, 0, 0)
	var y0 := BODY + 0.3
	for z in BAY_Z:
		var c := Vector3(X0 - 0.2, 26.1, float(z))
		K.rb(lm, "Stone", X0 - 0.2, X0, 24.4, 27.8, float(z) - 3.6, float(z) + 3.6, 0.0)
		lm.disc("Glass", c + out * 0.1, out, 1.2, 14)
		LandmarkFhParts.ring(lm, "Stone", c + out * 0.05, out, 1.2, 1.7, 0.3, 14)
	for z in COL_Z:
		K.figure(lm, "Stone", Vector3(X0 - 1.6, y0, float(z)), 3.6)
	K.rb(lm, "Stone", X0 - 0.1, X0, 24.2, 27.8, -17.8, -13.8, 0.0)
	K.rb(lm, "Stone", X0 - 0.1, X0, 24.2, 27.8, 13.8, 17.8, 0.0)
	LandmarkDetail.cornice(lm, "Stone", Vector3(X0 - 0.15, ATT - 1.1, -RISALIT_HW - 0.2), Vector3(X0 - 0.15, ATT - 1.1, RISALIT_HW + 0.2),
		out, 1.1, true)
	LandmarkDetail.cornice(lm, "Stone", Vector3(X0 - 0.15, ATT - 1.1, -RISALIT_HW - 0.2), Vector3(-28.8, ATT - 1.1, -RISALIT_HW - 0.2),
		Vector3(0, 0, -1), 1.1, true)
	LandmarkDetail.cornice(lm, "Stone", Vector3(X0 - 0.15, ATT - 1.1, RISALIT_HW + 0.2), Vector3(-28.8, ATT - 1.1, RISALIT_HW + 0.2),
		Vector3(0, 0, 1), 1.1, true)
	var rail := Vector3(X0 + 0.3, ATT, 0)
	LandmarkDetail.balustrade(lm, "Stone", Vector3(rail.x, ATT, -RISALIT_HW + 0.3), Vector3(rail.x, ATT, RISALIT_HW - 0.3), 1.2, 4.7, 6)
	for s in [-1.0, 1.0]:
		LandmarkDetail.balustrade(lm, "Stone", Vector3(rail.x, ATT, float(s) * (RISALIT_HW - 0.3)),
			Vector3(-29.4, ATT, float(s) * (RISALIT_HW - 0.3)), 1.2, 4.0, 6)
	LandmarkDetail.balustrade(lm, "Stone", Vector3(-29.4, ATT, -RISALIT_HW + 0.3), Vector3(-29.4, ATT, RISALIT_HW - 0.3), 1.2, 4.7, 6)
	for s in [-1.0, 1.0]:
		K.urn(lm, "Stone", Vector3(X0 + 0.3, ATT + 1.2, float(s) * (RISALIT_HW - 0.3)), 1.6)
	# Windows in the risalit's side walls above the wing roofs.
	for s in [-1.0, 1.0]:
		var sz: float = float(s)
		K.wins(lm, "Stone", "Glass", Vector3(-41.0, 0, sz * RISALIT_HW), Vector3(0, 0, sz), [-6.0, 0.0, 6.0], 24.0, 1.7, 3.2, true, 0.25)

# --- Flanks and rear ---------------------------------------------------

## Both long flanks and the rear: ground arched windows in the base, tall
## framed windows on the piano nobile, small windows under the cornice,
## pilaster strips at the corners and either side of the stage house.
static func _flanks(lm: LandmarkMesh) -> void:
	var xs: Array = []
	var x := X0 + 4.0
	while x < X1 - 3.0:
		xs.append(x)
		x += PITCH
	var cx := (X0 + X1) * 0.5
	var offs: Array = xs.map(func(v: float) -> float: return v - cx)
	for s in [-1.0, 1.0]:
		var sz: float = float(s)
		var out := Vector3(0, 0, sz)
		# `right` of a wall facing +Z is +X; facing -Z it is -X.
		var o2: Array = offs if sz > 0.0 else offs.map(func(v: float) -> float: return -v)
		var p := Vector3(cx, 0, sz * (ZH + 0.3))
		K.wins(lm, "Stone", "Glass", p, out, o2, 2.0, 2.3, 4.6, true, 0.3)
		var pw := Vector3(cx, 0, sz * ZH)
		K.wins(lm, "Stone", "Glass", pw, out, o2, 11.9, 2.3, 5.0, false, 0.3)
		K.holes(lm, "Glass", pw, out, o2, 18.4, 1.5, 2.4, false)
		for ex in [X0 + 0.7, X1 - 0.7, STAGE_X0, STAGE_X1]:
			var zf := sz * ZH
			K.rb(lm, "Stone", float(ex) - 0.8, float(ex) + 0.8, BASE, BODY - 1.1, minf(zf, zf + sz * 0.3), maxf(zf, zf + sz * 0.3))
	# Rear (+X): two storeys of windows.
	var zs: Array = K.evenly(9, PITCH)
	var rear := Vector3(X1 + 0.3, 0, 0)
	K.wins(lm, "Stone", "Glass", rear, Vector3(1, 0, 0), zs, 2.0, 2.3, 4.6, true, 0.3)
	K.wins(lm, "Stone", "Glass", Vector3(X1, 0, 0), Vector3(1, 0, 0), zs, 11.9, 2.3, 5.0, false, 0.3)
	K.holes(lm, "Glass", Vector3(X1, 0, 0), Vector3(1, 0, 0), zs, 18.4, 1.5, 2.4, false)

## Stage house (the fly tower): arched windows on all four faces, round
## windows above, balustrade, urns, flagless.
static func _stage(lm: LandmarkMesh) -> void:
	var cxs := (STAGE_X0 + STAGE_X1) * 0.5
	var czs := (STAGE_Z0 + STAGE_Z1) * 0.5
	var offs: Array = K.evenly(4, 8.0)
	var zoffs: Array = K.evenly(4, 8.0)
	K.wins(lm, "Stone", "Glass", Vector3(cxs, 0, STAGE_Z1), Vector3(0, 0, 1), offs, 25.4, 2.6, 6.4, true, 0.3)
	K.wins(lm, "Stone", "Glass", Vector3(cxs, 0, STAGE_Z0), Vector3(0, 0, -1), offs, 25.4, 2.6, 6.4, true, 0.3)
	K.wins(lm, "Stone", "Glass", Vector3(STAGE_X1, 0, czs), Vector3(1, 0, 0), zoffs, 25.4, 2.6, 6.4, true, 0.3)
	K.wins(lm, "Stone", "Glass", Vector3(STAGE_X0, 0, czs), Vector3(-1, 0, 0), zoffs, 25.4, 2.6, 6.4, true, 0.3)
	for f in [[Vector3(cxs, 0, STAGE_Z1), Vector3(0, 0, 1)], [Vector3(cxs, 0, STAGE_Z0), Vector3(0, 0, -1)]]:
		K.holes(lm, "Glass", f[0], f[1], offs, 33.4, 1.4, 2.2, false)
	var y := STAGE
	var hb := 1.2
	var x0 := STAGE_X0 - 0.1
	var x1 := STAGE_X1 + 0.1
	# A solid pierced-look parapet (the balustrade is too far up to read as vases).
	K.rb(lm, "Stone", x0 - 0.2, x1 + 0.2, y, y + 0.35, STAGE_Z0 - 0.3, STAGE_Z1 + 0.3, 0.0)
	for e in [[x0 - 0.15, x1 + 0.15, STAGE_Z0 - 0.35, STAGE_Z0 - 0.05], [x0 - 0.15, x1 + 0.15, STAGE_Z1 + 0.05, STAGE_Z1 + 0.35],
			[x0 - 0.35, x0 - 0.05, STAGE_Z0, STAGE_Z1], [x1 + 0.05, x1 + 0.35, STAGE_Z0, STAGE_Z1]]:
		K.rb(lm, "Stone", float(e[0]), float(e[1]), y + 0.35, y + hb, float(e[2]), float(e[3]), 0.0)
		K.rb(lm, "Stone", float(e[0]) - 0.05, float(e[1]) + 0.05, y + hb - 0.2, y + hb, float(e[2]) - 0.05, float(e[3]) + 0.05, 0.0)
	for cx in [x0, x1]:
		for cz in [STAGE_Z0 - 0.1, STAGE_Z1 + 0.1]:
			K.urn(lm, "Stone", Vector3(float(cx), y + hb, float(cz)), 1.7)
	for ux in [cxs - 6.0, cxs + 6.0]:
		K.urn(lm, "Stone", Vector3(float(ux), y + hb, STAGE_Z0 - 0.1), 1.5)
		K.urn(lm, "Stone", Vector3(float(ux), y + hb, STAGE_Z1 + 0.1), 1.5)

# --- Roofs -------------------------------------------------------------

static func _roofs(lm: LandmarkMesh) -> void:
	# Wings, hall and ranges: low dark sheet-metal hips.
	for s in [-1.0, 1.0]:
		LandmarkFhUtil.hip(lm, "Roof", Vector3(-38.5, BODY, float(s) * 26.0), 29.0, 14.0, 2.0, 0.8)
	LandmarkFhUtil.hip(lm, "Roof", Vector3((HALL_X0 + STAGE_X0) * 0.5, BODY, 0.0), STAGE_X0 - HALL_X0, 2.0 * ZH, 3.2, 0.8)
	LandmarkFhUtil.hip(lm, "Roof", Vector3((STAGE_X0 + X1) * 0.5, BODY, 0.0), X1 - STAGE_X0, 2.0 * ZH, 3.0, 0.8)
	LandmarkFhUtil.hip(lm, "Roof", Vector3(-41.0, ATT, 0.0), 24.0, 2.0 * RISALIT_HW - 0.8, 1.8, 0.6)
	LandmarkFhUtil.hip(lm, "Roof", Vector3((STAGE_X0 + STAGE_X1) * 0.5, STAGE, (STAGE_Z0 + STAGE_Z1) * 0.5),
		STAGE_X1 - STAGE_X0 - 0.6, STAGE_Z1 - STAGE_Z0 - 0.6, 2.2, 0.5)
	# Auditorium drum with its cone, glazed roof lights.
	var dx := -8.0
	lm.frustum("Wall", Vector3(dx, 26.0, 0.0), 7.4, 7.4, 4.0, 24)
	lm.frustum("Stone", Vector3(dx, 29.8, 0.0), 7.7, 7.7, 0.5, 24)
	lm.frustum("Roof", Vector3(dx, 30.3, 0.0), 7.6, 2.2, 2.6, 24)
	for ang in 12:
		var a := TAU * float(ang) / 12.0
		K.rb(lm, "Glass", dx + cos(a) * 7.42 - 0.5, dx + cos(a) * 7.42 + 0.5, 27.2, 29.0, sin(a) * 7.42 - 0.5, sin(a) * 7.42 + 0.5, 0.0)
	for s in [-1.0, 1.0]:
		K.rb(lm, "Glass", -21.0, -14.0, 25.9, 26.6, float(s) * 13.0 - 1.4, float(s) * 13.0 + 1.4)
		K.rb(lm, "Glass", 16.0, 24.0, 25.8, 26.5, float(s) * 27.0 - 1.4, float(s) * 27.0 + 1.4)
	# Flagpole on the front attic roof, to the registry height.
	K.flag(lm, "Pole", "Awning", Vector3(-38.0, ATT + 1.6, 0.0), TOP - ATT - 1.6, Vector3(0, 0, 1), 3.0, 1.9)

# --- Operakällaren and the street ---------------------------------------

## The Operakällaren terrace wing along the +Z flank: granite arcade
## storey, balustraded terrace and cream awnings; the glazed veranda at the
## rear end.
static func _kallaren(lm: LandmarkMesh) -> void:
	var z1 := ZH + 3.6
	K.rb(lm, "Rust", -47.0, -13.0, 0.0, BASE - 0.6, ZH + 0.3, z1)
	K.rb(lm, "Stone", -47.4, -12.6, BASE - 0.6, BASE, ZH + 0.3, z1 + 0.4, 0.0)
	var out := Vector3(0, 0, 1)
	K.wins(lm, "Stone", "Door", Vector3(-30.0, 0, z1), out, K.evenly(6, 5.6), 0.4, 2.6, 5.4, true, 0.3)
	LandmarkDetail.balustrade(lm, "Stone", Vector3(-47.2, BASE, z1 + 0.3), Vector3(-12.8, BASE, z1 + 0.3), 1.1, 4.3, 6)
	for s in [-1.0, 1.0]:
		LandmarkDetail.balustrade(lm, "Stone", Vector3(-30.0 + float(s) * 17.2, BASE, ZH + 0.3),
			Vector3(-30.0 + float(s) * 17.2, BASE, z1 + 0.3), 1.1, 3.6, 6)
	for x in K.evenly(6, 5.7):
		K.awning(lm, "Awning", Vector3(-30.0 + float(x), 15.2, ZH + 0.1), out, 5.3, 3.4, 4.4)
	# Glazed veranda at the rear end of the flank.
	var vx0 := 40.0
	var vx1 := 58.0
	var vz := ZH + 6.0
	lm.quad("Glass", Vector3(vx0, 0.3, vz), Vector3(vx1, 0.3, vz), Vector3(vx1, 4.8, vz), Vector3(vx0, 4.8, vz), out)
	for ex in [vx0, vx1]:
		var n := Vector3(-1 if ex == vx0 else 1, 0, 0)
		lm.quad("Glass", Vector3(ex, 0.3, ZH), Vector3(ex, 0.3, vz), Vector3(ex, 4.8, vz), Vector3(ex, 4.8, ZH), n)
	var post := vx0
	while post <= vx1 + 0.1:
		lm.beam("Iron", Vector3(post, 0.0, vz + 0.05), Vector3(post, 5.0, vz + 0.05), 0.16, 0.16)
		post += 2.25
	lm.beam("Iron", Vector3(vx0, 4.9, vz + 0.05), Vector3(vx1, 4.9, vz + 0.05), 0.2, 0.2)
	var a := Vector3(vx0 - 0.3, 5.0, vz + 0.4)
	var b := Vector3(vx1 + 0.3, 5.0, vz + 0.4)
	var c := Vector3(vx1 + 0.3, 6.4, ZH)
	var d := Vector3(vx0 - 0.3, 6.4, ZH)
	var nrm := (Vector3(0, 1.4, 6.0 - 0.4)).cross(Vector3(1, 0, 0)).normalized()
	if nrm.y < 0.0:
		nrm = -nrm
	lm.quad("Roof", a, b, c, d, nrm)
	lm.quad("Roof", d, c, b, a, -nrm)

## Gustav Adolfs torg: the ornate candelabra lamp standards by the steps.
static func _street(lm: LandmarkMesh) -> void:
	for z in [-21.5, 21.5, -11.0, 11.0]:
		var base := Vector3(-65.4, 0.0, float(z))
		lm.frustum("Iron", base, 0.32, 0.22, 0.9, 8)
		lm.beam("Iron", base + Vector3(0, 0.9, 0), base + Vector3(0, 4.4, 0), 0.2, 0.2)
		for k in 3:
			var ang := TAU * float(k) / 3.0
			var arm := base + Vector3(0, 4.0, 0) + Vector3(cos(ang), 0, sin(ang)) * 0.7
			lm.beam("Iron", base + Vector3(0, 3.8, 0), arm + Vector3(0, 0.3, 0), 0.07, 0.07)
			lm.lathe("Lamp", arm + Vector3(0, 0.25, 0), LandmarkFhUtil.ball(0.26), 8)
		lm.lathe("Lamp", base + Vector3(0, 4.4, 0), LandmarkFhUtil.ball(0.34), 8)
