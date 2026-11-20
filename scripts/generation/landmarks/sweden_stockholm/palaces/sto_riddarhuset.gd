extends RefCounted

## Riddarhuset (House of Nobility, 1641-74), Gamla stan. Origin at the OSM
## footprint centre, long axis along +X (57.9 x 17.5 m), front toward -Z
## (the registry yaw -39.3 turns -Z onto the Riddarhustorget side, +Z onto
## the Riddarholmen canal).
##
## Facade (front.jpg, quarter.jpg, side.jpg):
## - Red-orange brick walls on a low sandstone base. Fourteen giant
##   Corinthian pilasters in sandstone run through both storeys, with a
##   doubled pair at each end, giving 13 bays of 4.1 m.
## - Per bay: a tall window with a flat cornice head on the lower storey, a
##   taller one above, a round window with a moulded ring over it, and a
##   stucco festoon hung between the two storeys. The centre bay is the door.
## - Above the capitals: architrave, a frieze with the gilded inscription,
##   and a dentilled cornice. The three centre bays carry a triangular
##   pediment.
## - The roof is the two-tier curved copper säteri roof: a bell-shaped lower
##   tier (steep at the eaves, rounding to a flat top) under a long green
##   copper upper box. On it stand the pediment statues, a pair of
##   green-and-gold obelisks with orbs and crowns at each end, and chimneys.
## - Two lower brick pavilions stand out from the water-side (rear) face,
##   which fills the OSM depth: 14.2 m body plus 3.3 m of pavilion.
##
## Forecourt (-Z): a red-granite balustrade with piers on three sides, the
## bronze Gustav Vasa statue on its pedestal (StatueBuilder), two granite
## obelisks and clipped yews.
##
## Sources: docs/stockholm-landmark-sources.md (way 8049544, 57.9 x 17.5,
## 25.5 m, built 1674), Commons photos in
## visual-plan/refs/landmarks/riddarhuset_stockholm/. Heights are scaled from
## the end view with the 17.5 m depth as the ruler: cornice top 17.9 m, roof
## deck 20.8 m, upper box 22.2 m, obelisk orbs and crowns to 25.5 m.

const Kit = preload("res://scripts/generation/landmarks/sweden_stockholm/palaces/sto_baroque_kit.gd")
const FhU = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")

const HW := 28.95
const ZF := -8.75
const ZR := 5.45
const ZC := (ZF + ZR) * 0.5
const D := ZR - ZF
const BASE_H := 1.3
const CAP_TOP := 14.2
const ARCH_TOP := 15.0
const FRIEZE_TOP := 16.4
const COR_TOP := 17.9
const BAYS := 13
const PITCH := 4.1
## Roof: eave half extents, then [inset, rise] rows of the curved tier.
const ROOF_PROF := [[0.0, 0.0], [0.5, 0.55], [1.3, 1.3], [2.2, 1.9], [3.2, 2.4], [4.2, 2.7], [5.0, 2.85], [5.4, 2.9]]
const DECK := COR_TOP + 2.9
const BOX_TOP := DECK + 1.4
## Rear pavilions.
const PAV_X := 16.0
const PAV_W := 9.6
const PAV_H := 12.0

static func build(model: Node3D) -> void:
	var mats := _materials()
	var lm := Kit.fresh(mats)
	var parts := {
		"win_lo": Kit.window(mats, "Frame", 1.5, 3.2),
		"win_hi": Kit.window(mats, "Frame", 1.5, 3.9),
		"door": Kit.window(mats, "Stone", 2.0, 3.6, true, 0.3),
		"pil": Kit.pilaster(mats, "Stone", CAP_TOP - BASE_H, 1.15, 0.4),
		"fest": Kit.festoon(mats, "Stone", 2.5, 0.8),
		"round": Kit.roundel(mats, "Stone", 0.62),
	}
	_body(lm)
	_facade(lm, parts)
	_ends(lm, parts)
	_pavilions(lm, parts)
	_roof(lm)
	_roof_top(lm)
	_forecourt(lm)
	lm.commit(model)

static func _materials() -> Dictionary:
	return {
		"Brick": LandmarkMaterials.pbr("brick", "#B8613F", 3.0),
		"Stone": LandmarkMaterials.pbr("limestone", "#B4AA95", 2.6),
		"Frame": LandmarkMaterials.pbr("render", "#E6E1D3", 2.5),
		"Copper": LandmarkMaterials.pbr("copper", "#5A8670", 2.0),
		"Glass": LandmarkMaterials.glass("#2A3236"),
		"Gold": LandmarkMaterials.gold(),
		"Bronze": LandmarkMaterials.pbr("copper", "#3E4346", 2.0, -1.0, 0.4),
		"Granite": LandmarkMaterials.pbr("stone", "#8C5C52", 2.5),
		"Paving": LandmarkMaterials.pbr("pavement", "#9A958B", 3.0),
		"Yew": LandmarkMaterials.pbr("forest", "#2C4630", 2.0),
		"Lamp": LandmarkMaterials.lit("#FFE2A8", 0.8),
	}

# --- Walls -------------------------------------------------------------

## Brick body, sandstone base, the entablature box with its gilded
## inscription band, the cornice on all four sides, and the pediment.
static func _body(lm: LandmarkMesh) -> void:
	FhU.blk(lm, "Brick", 0.0, 0.0, ZC, HW * 2.0, ARCH_TOP, D)
	FhU.blk(lm, "Stone", 0.0, 0.0, ZC, HW * 2.0 + 0.5, BASE_H, D + 0.5)
	FhU.blk(lm, "Stone", 0.0, CAP_TOP, ZC, HW * 2.0 + 0.8, FRIEZE_TOP - CAP_TOP, D + 0.8)
	var xe := HW + 0.4
	var zf := ZF - 0.4
	var zr := ZR + 0.4
	LandmarkDetail.cornice(lm, "Stone", Vector3(-xe - 1.5, FRIEZE_TOP, zf), Vector3(xe + 1.5, FRIEZE_TOP, zf),
		Vector3(0, 0, -1), 1.5)
	LandmarkDetail.cornice(lm, "Stone", Vector3(xe + 1.5, FRIEZE_TOP, zr), Vector3(-xe - 1.5, FRIEZE_TOP, zr),
		Vector3(0, 0, 1), 1.5)
	LandmarkDetail.cornice(lm, "Stone", Vector3(xe, FRIEZE_TOP, zf), Vector3(xe, FRIEZE_TOP, zr),
		Vector3(1, 0, 0), 1.5)
	LandmarkDetail.cornice(lm, "Stone", Vector3(-xe, FRIEZE_TOP, zr), Vector3(-xe, FRIEZE_TOP, zf),
		Vector3(-1, 0, 0), 1.5)
	# Gilded inscription on the long frieze, front and back.
	for s in [[zf - 0.02, -1.0], [zr + 0.02, 1.0]]:
		FhU.blk(lm, "Gold", 0.0, CAP_TOP + 0.62, float(s[0]), HW * 1.9, 0.26, 0.06)
	# Pediment over the three centre bays, set on the cornice.
	lm.gable("Stone", Vector3(0, COR_TOP, zf - 1.3), PITCH * 3.0, 1.0, 2.4, Basis(), 0.0, "Stone")

## Pilasters, windows, roundels and festoons on the front and the rear.
static func _facade(lm: LandmarkMesh, parts: Dictionary) -> void:
	for side in [[ZF, -1.0], [ZR, 1.0]]:
		var z: float = side[0]
		var out := Vector3(0, 0, float(side[1]))
		for i in BAYS + 1:
			var x := (float(i) - float(BAYS) * 0.5) * PITCH
			Kit.put(lm, parts["pil"], Vector3(x, BASE_H, z), out)
		for s in [-1.0, 1.0]:
			Kit.put(lm, parts["pil"], Vector3(float(s) * (HW - 0.7), BASE_H, z), out)
		for i in BAYS:
			var x := (float(i) - float(BAYS - 1) * 0.5) * PITCH
			var centre := i == BAYS / 2
			if centre and side[1] < 0.0:
				Kit.put(lm, parts["door"], Vector3(x, BASE_H, z), out)
			else:
				Kit.put(lm, parts["win_lo"], Vector3(x, 1.9, z), out)
			Kit.put(lm, parts["win_hi"], Vector3(x, 6.6, z), out)
			Kit.put(lm, parts["round"], Vector3(x, 12.1, z), out)
			Kit.put(lm, parts["fest"], Vector3(x, 6.0, z), out)

## The short ends: four pilasters, three bays of windows and roundels.
static func _ends(lm: LandmarkMesh, parts: Dictionary) -> void:
	for side in [HW, -HW]:
		var out := Vector3(signf(side), 0, 0)
		var x: float = side
		for t in [0.0, 0.34, 0.66, 1.0]:
			var z := lerpf(ZF + 0.6, ZR - 0.6, t)
			Kit.put(lm, parts["pil"], Vector3(x, BASE_H, z), out)
		for k in 3:
			var z := ZF + D * (float(k) + 0.5) / 3.0
			Kit.put(lm, parts["win_lo"], Vector3(x, 1.9, z), out)
			Kit.put(lm, parts["win_hi"], Vector3(x, 6.6, z), out)
			Kit.put(lm, parts["round"], Vector3(x, 12.1, z), out)
			Kit.put(lm, parts["fest"], Vector3(x, 6.0, z), out)

## The two water-side pavilions: brick, sandstone cornice, copper hip.
static func _pavilions(lm: LandmarkMesh, parts: Dictionary) -> void:
	var depth := 8.75 - ZR
	for s in [-1.0, 1.0]:
		var cx: float = float(s) * PAV_X
		var cz := ZR + depth * 0.5
		FhU.blk(lm, "Brick", cx, 0.0, cz, PAV_W, PAV_H, depth)
		FhU.blk(lm, "Stone", cx, 0.0, cz, PAV_W + 0.4, BASE_H, depth + 0.4)
		FhU.blk(lm, "Stone", cx, PAV_H, cz, PAV_W + 0.9, 0.9, depth + 0.9)
		for k in [-1.0, 1.0]:
			FhU.blk(lm, "Stone", cx + float(k) * (PAV_W * 0.5 - 0.5), BASE_H, cz + depth * 0.5 - 0.2, 0.9,
				PAV_H - BASE_H, 0.4)
		Kit.put(lm, parts["win_lo"], Vector3(cx, 1.9, ZR + depth), Vector3(0, 0, 1))
		Kit.put(lm, parts["win_hi"], Vector3(cx, 6.6, ZR + depth), Vector3(0, 0, 1))
		for e in [-1.0, 1.0]:
			Kit.put(lm, parts["win_lo"], Vector3(cx + float(e) * PAV_W * 0.5, 1.9, cz), Vector3(float(e), 0, 0))
			Kit.put(lm, parts["win_hi"], Vector3(cx + float(e) * PAV_W * 0.5, 6.6, cz), Vector3(float(e), 0, 0))
		Kit.hip(lm, "Copper", Vector3(cx, PAV_H + 0.9, cz), PAV_W * 0.5 + 0.5, depth * 0.5 + 0.5,
			[[0.0, 0.0], [0.8, 0.8], [2.0, 1.7], [2.8, 2.1]])

# --- Roof ----------------------------------------------------------------

## The bell-shaped lower tier, the long upper box and its cap.
static func _roof(lm: LandmarkMesh) -> void:
	var hx := HW + 0.4 + 1.5
	var hz := D * 0.5 + 0.4 + 1.5
	Kit.hip(lm, "Copper", Vector3(0, COR_TOP, ZC), hx, hz, ROOF_PROF)
	var top_x := hx - 5.4
	var top_z := hz - 5.4
	FhU.blk(lm, "Copper", 0.0, DECK, ZC, top_x * 2.0, BOX_TOP - DECK - 0.25, top_z * 2.0)
	FhU.blk(lm, "Copper", 0.0, BOX_TOP - 0.25, ZC, top_x * 2.0 + 0.5, 0.25, top_z * 2.0 + 0.5)
	# Round vents and a gilded rosette on the roof slopes, as in the photos.
	for sgn in [-1.0, 1.0]:
		lm.disc("Gold", Vector3(float(sgn) * 14.0, COR_TOP + 1.45, ZC - 6.6), Vector3(0, 0.55, -1), 0.5, 10)

## Statues, obelisks and chimneys on the upper box.
static func _roof_top(lm: LandmarkMesh) -> void:
	var y := BOX_TOP
	var zfront := ZC - 2.3
	# Centre statue on a green plinth, and the two on the roof shoulders.
	_statue(lm, Vector3(0, y, zfront), 1.0, 2.3)
	for s in [-1.0, 1.0]:
		_statue(lm, Vector3(float(s) * 6.2, COR_TOP + 1.1, ZF - 0.8), 1.0, 2.1)
	# Obelisks: a pair at each end, a statue between them.
	for e in [-1.0, 1.0]:
		var x: float = float(e) * 24.0
		for k in [-1.0, 1.0]:
			_obelisk(lm, Vector3(x, y, ZC + float(k) * 2.9))
		_statue(lm, Vector3(x - float(e) * 2.6, y, ZC), 0.8, 2.0)
	# Chimneys.
	for x in [-17.0, -9.5, 9.5, 17.0]:
		FhU.blk(lm, "Brick", float(x), y, ZC + 1.4, 1.2, 1.6, 1.2)
		FhU.blk(lm, "Stone", float(x), y + 1.6, ZC + 1.4, 1.5, 0.25, 1.5)

## A green copper obelisk on a plinth, gilded trophies, an orb and a crown.
static func _obelisk(lm: LandmarkMesh, base: Vector3) -> void:
	FhU.blk(lm, "Copper", base.x, base.y, base.z, 1.5, 0.6, 1.5)
	lm.frustum("Copper", base + Vector3(0, 0.6, 0), 0.62, 0.45, 2.0, 4, PI * 0.25)
	for k in 4:
		var a := PI * 0.5 * float(k)
		var d := Vector3(cos(a), 0, sin(a))
		lm.box("Gold", base + Vector3(0, 1.7, 0) + d * 0.37, Vector3(0.1, 1.0, 0.3), Basis(Vector3.UP, -a), 0.0)
	lm.lathe("Copper", base + Vector3(0, 2.6, 0), PackedVector2Array([Vector2(0.0, 0), Vector2(0.3, 0.08),
		Vector2(0.46, 0.35), Vector2(0.4, 0.62), Vector2(0.2, 0.84), Vector2(0.0, 0.9)]), 12)
	for k in 6:
		var a := TAU * float(k) / 6.0
		var d := Vector3(cos(a), 0, sin(a))
		lm.beam("Gold", base + Vector3(0, 3.45, 0) + d * 0.12, base + Vector3(0, 3.95, 0) + d * 0.34, 0.07)

## A bronze figure on a plinth, `h` tall.
static func _statue(lm: LandmarkMesh, base: Vector3, plinth: float, h: float) -> void:
	FhU.blk(lm, "Copper", base.x, base.y, base.z, 1.1, plinth, 1.1)
	LandmarkKits.statue_figure(lm, "Bronze", base + Vector3(0, plinth, 0), h)

# --- Forecourt -----------------------------------------------------------

## Paving, the granite balustrade, the Gustav Vasa statue, obelisks, yews
## and lamps.
static func _forecourt(lm: LandmarkMesh) -> void:
	var zb := ZF - 11.0
	var xb := 32.0
	FhU.blk(lm, "Paving", 0.0, 0.0, (ZF + zb) * 0.5 - 0.4, xb * 2.0, 0.08, ZF - zb - 0.8)
	# Balustrade along the street, with a gate gap, and the two returns.
	for seg in [[-xb, -2.6], [2.6, xb]]:
		LandmarkDetail.balustrade(lm, "Granite", Vector3(seg[0], 0.08, zb), Vector3(seg[1], 0.08, zb), 1.15, 4.0, 5)
	for s in [-1.0, 1.0]:
		LandmarkDetail.balustrade(lm, "Granite", Vector3(float(s) * xb, 0.08, zb), Vector3(float(s) * xb, 0.08, ZF - 0.5),
			1.15, 4.0, 5)
		FhU.blk(lm, "Granite", float(s) * 2.6, 0.08, zb, 0.9, 1.6, 0.9)
	# Gustav Vasa on his pedestal, facing the street.
	var statue := StatueBuilder.mesh({"x": 0.0, "z": ZF - 5.5, "statue": "statue", "statue_dir": 0.0,
		"size_x": 2.4, "size_z": 2.4}, 0.08)
	lm.merge(statue, Transform3D())
	# Two granite obelisks flanking him.
	for s in [-1.0, 1.0]:
		var ox: float = float(s) * 8.6
		FhU.blk(lm, "Granite", ox, 0.08, ZF - 4.5, 1.3, 0.7, 1.3)
		lm.frustum("Granite", Vector3(ox, 0.78, ZF - 4.5), 0.55, 0.3, 4.4, 4, PI * 0.25)
		lm.lathe("Granite", Vector3(ox, 5.18, ZF - 4.5), PackedVector2Array([Vector2(0.0, 0), Vector2(0.3, 0.05),
			Vector2(0.0, 0.5)]), 4)
	# Clipped yews: tall cones.
	for p in [[-13.5, -5.2], [-18.5, -4.8], [13.5, -5.2], [18.5, -4.8], [-4.8, -3.6], [4.8, -3.6]]:
		var c := Vector2(float(p[0]), ZF + float(p[1]))
		lm.lathe("Yew", Vector3(c.x, 0.08, c.y), PackedVector2Array([Vector2(0.0, 0), Vector2(1.6, 0), Vector2(1.7, 0.6),
			Vector2(1.3, 2.4), Vector2(0.8, 3.8), Vector2(0.0, 4.6)]), 10)
	# Lamp standards at the gate piers.
	for s in [-1.0, 1.0]:
		var lx: float = float(s) * 2.6
		lm.frustum("Bronze", Vector3(lx, 1.7, zb), 0.08, 0.05, 2.0, 6)
		lm.lathe("Lamp", Vector3(lx, 3.7, zb), PackedVector2Array([Vector2(0.0, 0), Vector2(0.26, 0.1),
			Vector2(0.3, 0.4), Vector2(0.22, 0.6), Vector2(0.0, 0.66)]), 8)
