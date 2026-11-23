class_name LandmarkMiCarlyleCardozo
extends RefCounted

## Leslie, The Carlyle & Cardozo Hotels — Ocean Drive 12th–13th St (MI-4A).
## Site: OSM ways 380861927 (1244 Leslie), 380861944 (1250 Carlyle), 380861903
## (1300 Cardozo), 25.783722, -80.130245, yaw_deg 8.2. Local +X = east (Ocean
## Drive), +Z = north. Measured envelope (Commons / MDPL front views):
##   - Footprint 40.4 m (X) x 88.0 m (Z); fronts at x = +8, terrace to x = +17.
##   - Leslie (z -44..-24, 11.0 m south): canary-yellow & white ziggurat front, eyebrows.
##   - The Carlyle (z -22..8, 3 storeys, 11.0 m): Kiehnel & Elliott (1939) curved
##     white & seafoam-mint Streamline Moderne front: half-round central bay with
##     horizontal bands, fluted vertical pylons, neon "CARLYLE" script glow,
##     green & white terrace umbrellas.
##   - Cardozo (z 10..44, 4 storeys): cream & coral-tan, rounded corners; its
##     crown parapet is the model top, exactly 15.5 m.

const HEIGHT_M := 15.5
const FRONT_X := 8.0

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("White", LandmarkMaterials.pbr("render", "#F8F7F1", 3.0))
	lm.use("Yellow", LandmarkMaterials.pbr("render", "#F8D23A", 3.0))
	lm.use("Mint", LandmarkMaterials.pbr("render", "#B9E3CC", 3.0))
	lm.use("Cream", LandmarkMaterials.pbr("render", "#F1E2BF", 3.0))
	lm.use("Tan", LandmarkMaterials.paint("#D9936E", 0.55, 0.05))
	lm.use("Glass", LandmarkMaterials.glass("#25353E"))
	lm.use("Neon", LandmarkMaterials.lit("#5CFFB0", 1.5))
	lm.use("Trunk", LandmarkMaterials.pbr("concrete", "#9A9588", 2.0))
	lm.use("Frond", LandmarkMaterials.paint("#2F6B35", 0.8, 0.0))
	lm.use("Green", LandmarkMaterials.paint("#2F7F55", 0.7, 0.0))
	lm.use("Walk", LandmarkMaterials.pbr("concrete", "#CDC7B9", 3.0))

	lm.box("Walk", Vector3(0.0, -0.15, 0.0), Vector3(34.0, 0.3, 88.0))
	_flat_front(lm, "Yellow", "White", -44.0, -24.0, 11.0, 3)
	_flat_front(lm, "Cream", "Tan", 10.0, 44.0, 14.4, 4)
	_leslie_crown(lm)
	_carlyle(lm)
	_cardozo_corners(lm)
	_terrace(lm)
	lm.commit(model)

	var mint := Color(0.7, 1.0, 0.85)
	var warm := Color(1.0, 0.9, 0.66)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(16.0, 1.5, -34.0), Vector3(FRONT_X, 7.0, -34.0), 40.0, 1.2, 34.0, warm],
		[Vector3(16.0, 1.5, -7.0), Vector3(FRONT_X + 2.0, 6.0, -7.0), 40.0, 1.2, 34.0, mint],
		[Vector3(16.0, 1.5, 27.0), Vector3(FRONT_X, 8.0, 27.0), 40.0, 1.2, 40.0, warm],
	])

static func _flat_front(lm: LandmarkMesh, wall: String, trim: String, z0: float, z1: float,
		h: float, floors: int) -> void:
	var zc := (z0 + z1) * 0.5
	lm.box(wall, Vector3(-1.0, (h - 0.3) * 0.5, zc), Vector3(18.0, h + 0.3, z1 - z0 - 0.3))
	lm.box(trim, Vector3(FRONT_X - 0.1, h - 0.3, zc), Vector3(0.5, 0.7, z1 - z0 - 0.3))
	var fh := h / float(floors)
	var bays := maxi(2, int((z1 - z0) / 3.4))
	for f in floors:
		var yc := float(f) * fh + fh * 0.5 + 0.2
		for i in bays:
			var z := lerpf(z0 + 1.2, z1 - 1.2, (float(i) + 0.5) / float(bays))
			lm.box("Glass", Vector3(FRONT_X + 0.03, yc, z), Vector3(0.1, 1.6, 1.3))
		if f > 0:
			LandmarkMiKit.deco_eyebrow(lm, trim, Vector2(FRONT_X, z0 + 0.2),
				Vector2(FRONT_X, z1 - 0.2), float(f) * fh + fh * 0.5 + 1.1, 0.45, 0.10, Vector2(1, 0))
	for i in bays + 1:
		lm.box(trim, Vector3(FRONT_X + 0.08, h * 0.5, lerpf(z0 + 0.2, z1 - 0.2, float(i) / float(bays))),
			Vector3(0.18, h, 0.22))

static func _leslie_crown(lm: LandmarkMesh) -> void:
	LandmarkMiKit.ziggurat_parapet(lm, "Yellow", "White", Vector2(FRONT_X - 0.4, -34.0),
		Vector2(0, 1), Vector2(1, 0), 11.0, 12.0, 0.5, 3, 0.5)
	# Cardozo crown parapet: its top is the model top (15.5 m).
	lm.box("Tan", Vector3(FRONT_X - 0.3, 14.95, 27.0), Vector3(0.5, 1.1, 34.0))
	lm.box("Cream", Vector3(FRONT_X - 0.3, HEIGHT_M - 0.1, 27.0), Vector3(0.8, 0.2, 34.2))

static func _carlyle(lm: LandmarkMesh) -> void:
	var zc := -7.0
	lm.box("White", Vector3(-2.0, 5.35, zc), Vector3(16.0, 11.0, 29.7))
		# Half-round central bay: banded cylinder, glass ribbons and eyebrow collars.
	var cx := FRONT_X - 2.0
	lm.frustum("White", Vector3(cx, -0.3, zc), 6.0, 6.0, 11.3, 20)
	for f in 3:
		var y := 0.6 + float(f) * 3.6
		lm.frustum("Glass", Vector3(cx, y, zc), 6.04, 6.04, 1.7, 20)
		lm.frustum("Mint", Vector3(cx, y + 1.85, zc), 6.45, 6.45, 0.16, 20)
		lm.frustum("White", Vector3(cx, y + 1.5, zc), 6.14, 6.14, 0.35, 20)
	lm.frustum("Mint", Vector3(cx, 10.9, zc), 6.5, 6.5, 0.45, 20)
	# Straight wings with ribbon windows and eyebrows to either side.
	for sz: float in [-1.0, 1.0]:
		var zw := zc + sz * 11.5
		for f in 3:
			var y := 1.3 + float(f) * 3.6
			lm.box("Glass", Vector3(6.03, y, zw), Vector3(0.1, 1.6, 5.0))
			LandmarkMiKit.deco_eyebrow(lm, "Mint", Vector2(6.0, zw - 3.5),
				Vector2(6.0, zw + 3.5), y + 1.15, 0.45, 0.10, Vector2(1, 0))
		# Fluted vertical pylon flanking the bay.
		for k in 3:
			lm.box("White", Vector3(FRONT_X - 1.9, 6.1, zc + sz * (6.9 + float(k) * 0.4)), Vector3(0.7, 12.2, 0.28))
	# Neon "CARLYLE" script glow: lit bars along the roof band of the bay.
	for k in 7:
		lm.box("Neon", Vector3(cx + 6.3, 11.6, zc - 3.0 + float(k) * 1.0), Vector3(0.1, 0.5 + 0.2 * float(k % 2), 0.55))
	var tube := PackedVector3Array([Vector3(cx + 6.4, 11.1, zc - 4.0), Vector3(cx + 6.4, 11.1, zc + 4.0)])
	LandmarkMiKit.neon_tube_line(lm, "Neon", tube, 0.07)

static func _cardozo_corners(lm: LandmarkMesh) -> void:
	for z: float in [10.3, 43.7]:
		lm.frustum("Cream", Vector3(FRONT_X - 0.6, -0.3, z), 1.2, 1.2, 14.7, 12)
	lm.box("Tan", Vector3(FRONT_X + 0.2, 7.0, 27.0), Vector3(0.4, 0.3, 33.0))

static func _terrace(lm: LandmarkMesh) -> void:
	for z: float in [-40.0, -30.0, -18.0, -10.0, -3.0, 4.0, 14.0, 22.0, 30.0, 38.0]:
		var u := Vector3(FRONT_X + 6.5, 0.0, z)
		lm.beam("Trunk", u, u + Vector3(0, 2.3, 0), 0.08, 0.08)
		lm.frustum("Green" if int(z) % 2 == 0 else "White", u + Vector3(0, 2.1, 0), 1.3, 0.06, 0.55, 8)
	for z: float in [-26.0, 8.5, 42.0]:
		LandmarkMiKit.royal_palm(lm, "Trunk", "Frond", Vector3(FRONT_X + 9.0, 0.0, z), 9.0, z)
