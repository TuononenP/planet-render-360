class_name StoGronaPark
extends RefCounted

## Gröna Lund, the park around the Eclipse tower (plan S-2): everything the
## Eclipse entry leaves out. Origin at the centre of the theatre block
## (StoGronaCoasters.ORIGIN, Eclipse-frame (22.9, -143.5)), +X east, +Z south,
## yaw 0. Photos: visual-plan/refs/landmarks/grona_lund_park/ (gate, Tyrol
## street, 2006 aerial, Twister, Jetline, Låga längan houses).
## - The main gate on Allmänna gränd (OSM entrance node 2493835586): a timber
##   temple front 11.6 m wide, mint-green board side panels, two cream
##   columns in front of white iron gates, a cream lettering band carrying
##   GRÖNA LUND in dark green script (lit), a cornice and a pediment with
##   mint tympanum, 8.2 m to the apex; it faces the street, north-west.
## - Two Tivoli pavilions: a square open pavilion on gilt and red-striped
##   column pairs with a deep overhanging flat roof, gilt finials and
##   globe lamp posts (the one beside the Tyrol street), and a small
##   octagonal kiosk with a red tile cone roof ringed with bulbs.
## - The old timber houses (StoGronaHouses) on the footprints they replace.
## - The Twister and Jetline coasters (StoGronaCoasters).
## Heights: the Twister's rail top is the registry height. The Fyrtornet and
## Café Parken named in the brief are not mapped in OSM and no photo of them
## is in Commons' Gröna Lund categories, so they are left out.

const GATE_AT := Vector2(32.1, -161.3)
## The gate's front (the lettering side) faces north-west, onto the street.
const GATE_YAW := 3.7005
const PAV_A_AT := Vector2(-2.0, -157.0)
const PAV_B_AT := Vector2(-38.0, -79.0)

static func materials() -> Dictionary:
	return {
		"Lattice": LandmarkMaterials.pbr("concrete", "#F2F0EA", 2.0, 0.6, 0.1),
		"Deck": LandmarkMaterials.pbr("wood", "#8B8070", 2.0),
		"RedRail": LandmarkMaterials.paint("#C02A2A"),
		"JetFrame": LandmarkMaterials.paint("#9CC9DD"),
		"JetTrack": LandmarkMaterials.paint("#4FA7A8"),
		"Mint": LandmarkMaterials.pbr("render", "#A9D3BF", 2.0),
		"Cream": LandmarkMaterials.pbr("render", "#EDE3C5", 2.0),
		"Sign": LandmarkMaterials.lit("#2E7D46", 0.5),
		"Lit": LandmarkMaterials.lit("#FFD9A0", 0.8),
		"RedWall": LandmarkMaterials.pbr("wood", "#843428", 2.0),
		"RoofRed": LandmarkMaterials.pbr("terracotta", "#92402B", 3.0),
		"RoofGrey": LandmarkMaterials.pbr("sheet_metal", "#6D7378", 3.0, 0.5, 0.4),
		"Gilt": LandmarkMaterials.gold(),
		"Glass": LandmarkMaterials.glass("#26303A"),
	}

static func use_all(lm: LandmarkMesh, mats: Dictionary) -> void:
	for k in mats:
		lm.use(str(k), mats[k] as Material)

static func build(model: Node3D) -> void:
	var mats := materials()
	var lm := LandmarkMesh.new()
	use_all(lm, mats)
	StoGronaHouses.add(lm, mats)
	StoGronaCoasters.add(lm)
	var g := GATE_AT - StoGronaCoasters.ORIGIN
	var gate := _gate(mats)
	lm.merge(gate, Transform3D(Basis(Vector3.UP, GATE_YAW), Vector3(g.x, 0.0, g.y)))
	_pavilion(lm, PAV_A_AT - StoGronaCoasters.ORIGIN)
	_kiosk(lm, PAV_B_AT - StoGronaCoasters.ORIGIN)
	lm.commit(model)
	var warm := Color(1.0, 0.88, 0.66)
	var toward := Vector3(sin(GATE_YAW), 0.0, cos(GATE_YAW))
	var gc := Vector3(g.x, 4.0, g.y)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[gc + toward * 14.0 + Vector3(-5.0, -2.8, 0.0), gc, 40.0, 0.7, 30.0, warm],
		[gc + toward * 14.0 + Vector3(5.0, -2.8, 0.0), gc, 40.0, 0.7, 30.0, warm],
	])

## The gate in its own frame, front (lettering) toward +Z.
static func _gate(mats: Dictionary) -> LandmarkMesh:
	var lm := LandmarkMesh.new()
	use_all(lm, mats)
	for sx in [-1.0, 1.0]:
		var s: float = sx
		lm.box("Mint", Vector3(s * 4.6, 2.2, 0.0), Vector3(2.0, 4.4, 0.5), Basis(), 0.0)
		# Dark framed poster boards on the panels.
		lm.box("RoofGrey", Vector3(s * 4.6, 2.4, 0.28), Vector3(1.0, 1.4, 0.06), Basis(), 0.0)
		lm.box("Lit", Vector3(s * 4.6, 2.4, 0.32), Vector3(0.8, 1.2, 0.03), Basis(), 0.0)
		# White iron gate leaves between the columns and the panels.
		for k in 6:
			var x: float = s * (2.3 + 0.26 * float(k))
			lm.beam("Lattice", Vector3(x, 0.0, 0.1), Vector3(x, 3.9, 0.1), 0.04, 0.04)
		# Column.
		lm.box("Cream", Vector3(s * 2.04, 0.15, 0.6), Vector3(0.8, 0.3, 0.8), Basis(), 0.0)
		lm.frustum("Cream", Vector3(s * 2.04, 0.3, 0.6), 0.32, 0.27, 3.9, 12)
		lm.box("Cream", Vector3(s * 2.04, 4.3, 0.6), Vector3(0.8, 0.25, 0.8), Basis(), 0.0)
	for k in 14:
		var x := -1.82 + 0.28 * float(k)
		lm.beam("Lattice", Vector3(x, 0.0, 0.1), Vector3(x, 3.9, 0.1), 0.04, 0.04)
	for y in [1.0, 3.9]:
		lm.beam("Lattice", Vector3(-3.6, float(y), 0.1), Vector3(3.6, float(y), 0.1), 0.06, 0.06)
	# Lettering band with GRÖNA LUND, the cornice and the pediment.
	lm.box("Cream", Vector3(0, 5.25, 0.2), Vector3(11.6, 1.7, 1.0), Basis(), 0.0)
	for i in 9:
		var x := -4.5 + 0.9 * float(i) if i < 5 else 1.2 + 0.95 * float(i - 5)
		lm.box("Sign", Vector3(x, 5.25, 0.75), Vector3(0.62, 0.95, 0.12), Basis(), 0.0)
	lm.box("Cream", Vector3(0, 6.25, 0.2), Vector3(12.2, 0.35, 1.3), Basis(), 0.0)
	lm.gable("Cream", Vector3(0, 6.42, 0.2), 12.0, 1.3, 1.75, Basis(), 0.2, "Mint")
	return lm

## Square open Tivoli pavilion: gilt and red column pairs, flat deep roof.
static func _pavilion(lm: LandmarkMesh, at: Vector2) -> void:
	var c := Vector3(at.x, 0.0, at.y)
	lm.box("Cream", c + Vector3(0, 0.15, 0), Vector3(9.2, 0.3, 9.2), Basis(), 0.0)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var p := c + Vector3(float(sx) * 3.9, 0.0, float(sz) * 3.9)
			lm.frustum("Gilt", p + Vector3(-0.33, 0.3, 0), 0.2, 0.2, 4.7, 10)
			lm.frustum("RedWall", p + Vector3(0.33, 0.3, 0), 0.2, 0.2, 4.7, 10)
			lm.lathe("Gilt", p + Vector3(0.0, 5.7, 0), LandmarkFhUtil.ball(0.28), 10)
	# Deep overhanging roof: dark patterned soffit, cream fascia, grey top.
	lm.box("RoofGrey", c + Vector3(0, 5.05, 0), Vector3(10.4, 0.1, 10.4), Basis(), 0.0)
	lm.box("Cream", c + Vector3(0, 5.4, 0), Vector3(10.4, 0.6, 10.4), Basis(), 0.0)
	lm.box("RoofGrey", c + Vector3(0, 5.8, 0), Vector3(10.6, 0.2, 10.6), Basis(), 0.0)
	lm.frustum("Cream", c + Vector3(0, 5.9, 0), 3.0, 1.2, 0.5, 8)
	# Globe lamp posts on the corners.
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var p := c + Vector3(float(sx) * 5.6, 0.0, float(sz) * 5.6)
			lm.beam("Gilt", p, p + Vector3.UP * 3.4, 0.12, 0.12)
			lm.lathe("Lit", p + Vector3.UP * 3.4, LandmarkFhUtil.ball(0.3), 8)

## Small octagonal kiosk: striped walls, red tile cone roof, ring of bulbs.
static func _kiosk(lm: LandmarkMesh, at: Vector2) -> void:
	var c := Vector3(at.x, 0.0, at.y)
	lm.frustum("Cream", c, 2.7, 2.7, 2.7, 8)
	lm.frustum("RedWall", c + Vector3.UP * 1.0, 2.75, 2.75, 0.9, 8, PI / 8.0)
	lm.frustum("RoofGrey", c + Vector3.UP * 2.7, 3.1, 3.1, 0.25, 8)
	lm.lathe("RoofRed", c + Vector3.UP * 2.95, PackedVector2Array([Vector2(3.4, 0), Vector2(0.15, 2.2)]), 8)
	lm.lathe("Gilt", c + Vector3.UP * 5.1, LandmarkFhUtil.ball(0.25), 8)
	for k in 8:
		var a := TAU * float(k) / 8.0
		lm.box("Lit", c + Vector3(cos(a) * 3.0, 2.55, sin(a) * 3.0), Vector3(0.22, 0.22, 0.22), Basis(), 0.0)
