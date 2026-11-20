class_name FtTurkuSchoolEconomics
extends RefCounted

## Turku School of Economics (Turun kauppakorkeakoulu, 1950 & 2001/2010 wings,
## Rehtorinpellonkatu 3) in true metres (+X ENE along Rehtorinpellonkatu,
## +Z SSE toward Ylioppilastalo, turned by registry yaw_deg = -66.0°):
##   - 1950 Main Red-Brick & White-Trim Modernist Block (68 x 18 m, 4 storeys,
##     eaves 15.6 m, low hipped copper/metal roof 18.8 m): rough grey granite
##     plinth, warm red-brick facades with crisp white-rendered horizontal
##     window bands & eaves cornice, rhythmic lecture-room casements.
##   - Signature Curved Auditorium Wing projecting +Z on the east end
##     (radius 13.5 m, H = 13.6 m): fluted red-brick drum with vertical tall
##     slit windows and cantilevered white cornice ring.
##   - Contemporary Glass Entrance Atrium & Library Wing projecting -X/+Z
##     (32 x 22 m, H = 16.4 m): double-height glazed lobby with cantilevered
##     metal entrance canopy, warm interior atrium glow, and brick/metal
##     upper seminar wing.
## Surfaces: 8 merged PBR parts (Brick, Granite, WhiteTrim, RoofMetal,
## DarkMetal, Timber, Glass, Lamp).

const FOUND := -2.6

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	_materials(lm)
	_build_main_brick_block(lm)
	_build_curved_auditorium(lm)
	_build_glass_entrance_wing(lm)
	lm.commit(model)
	_set_night_floods(model)

static func _materials(lm: LandmarkMesh) -> void:
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#984A38", 2.4))
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#7E7A72", 2.5))
	lm.use("WhiteTrim", LandmarkMaterials.pbr("render", "#EFECE4", 3.0))
	lm.use("RoofMetal", LandmarkMaterials.pbr("sheet_metal", "#4C5854", 2.4))
	lm.use("DarkMetal", LandmarkMaterials.paint("#2A3036", 0.44, 0.55))
	lm.use("Timber", LandmarkMaterials.pbr("wood", "#BC8A52", 2.0, 0.62))
	lm.use("Glass", LandmarkMaterials.glass("#223442"))
	lm.use("Lamp", LandmarkMaterials.lit("#FFECC2", 1.5))

static func _build_main_brick_block(lm: LandmarkMesh) -> void:
	# 1950 4-storey red-brick modernist campus block (68 x 18 m, eaves 15.6 m, ridge 18.8 m).
	LandmarkFrKit.rect(lm, "Granite", -34.4, 34.4, -9.4, 9.4, FOUND, 1.8)
	LandmarkFrKit.rect(lm, "Brick", -34.0, 34.0, -9.0, 9.0, 1.8, 15.6)
	LandmarkFrParts.band(lm, "WhiteTrim", -34.0, 34.0, -9.0, 9.0, 1.75, 0.32, 0.14)
	LandmarkFrParts.cornice_ring(lm, "WhiteTrim", -34.0, 34.0, -9.0, 9.0, 15.05, 0.58)
	# Low hipped patinated metal roof (15.6 -> 18.8 m).
	LandmarkFrKit.hip(lm, "RoofMetal", -34.0, 34.0, -9.0, 9.0, 15.6, 3.2, 0.55)
	# Rhythmic horizontal white-trimmed window bands across 4 storeys.
	for lv in 4:
		var wy := 2.6 + float(lv) * 3.15
		for sz: float in [-1.0, 1.0]:
			LandmarkFrKit.rect(lm, "Glass", -31.8, 31.8, sz * 9.0 - 0.14, sz * 9.0 + 0.14, wy, wy + 1.65)
			LandmarkFrKit.rect(lm, "WhiteTrim", -32.0, 32.0, sz * 9.0 - 0.22, sz * 9.0 + 0.22, wy - 0.20, wy)
			LandmarkFrKit.rect(lm, "WhiteTrim", -32.0, 32.0, sz * 9.0 - 0.22, sz * 9.0 + 0.22, wy + 1.65, wy + 1.82)
			for k in 17:
				var mx := lerpf(-31.5, 31.5, float(k) / 16.0)
				lm.box("WhiteTrim", Vector3(mx, wy + 0.82, sz * 9.10), Vector3(0.18, 1.7, 0.14))
	# Glazed vertical stair tower on north (-Z) facade.
	LandmarkFrKit.rect(lm, "Brick", -3.8, 3.8, -11.6, -9.0, FOUND, 16.8)
	LandmarkFrKit.rect(lm, "Glass", -2.2, 2.2, -11.75, -11.4, 2.2, 15.6)
	lm.box("Lamp", Vector3(0.0, 9.0, -10.5), Vector3(3.6, 12.0, 1.4))

static func _build_curved_auditorium(lm: LandmarkMesh) -> void:
	# Signature curved red-brick auditorium wing projecting +Z on the east end.
	var cx := 22.0
	var cz := 9.0
	lm.frustum("Granite", Vector3(cx, FOUND, cz), 13.8, 13.8, 1.8 - FOUND, 20)
	lm.frustum("Brick", Vector3(cx, 1.8, cz), 13.5, 13.5, 11.4, 20)
	lm.frustum("WhiteTrim", Vector3(cx, 13.0, cz), 14.0, 14.0, 0.58, 20)
	lm.frustum("RoofMetal", Vector3(cx, 13.58, cz), 13.6, 11.2, 1.2, 20)
	# Tall vertical slit windows & white vertical fins curving around the auditorium drum.
	for i in 9:
		var a := PI * 0.12 + PI * 0.76 * float(i) / 8.0
		var wx := cx + cos(a) * 13.52
		var wz := cz + sin(a) * 13.52
		lm.box("Glass", Vector3(wx, 7.6, wz), Vector3(0.24, 7.8, 1.1), Basis(Vector3.UP, -a))
		lm.box("WhiteTrim", Vector3(cx + cos(a + 0.14) * 13.62, 7.6, cz + sin(a + 0.14) * 13.62),
			Vector3(0.32, 8.6, 0.24), Basis(Vector3.UP, -(a + 0.14)))

static func _build_glass_entrance_wing(lm: LandmarkMesh) -> void:
	# Contemporary glass entrance atrium & library wing on west/south side (-34..+2, +9..+28).
	LandmarkFrKit.rect(lm, "Granite", -34.0, 2.0, 9.0, 28.0, FOUND, 0.45)
	# Double-height glazed atrium lobby with warm timber soffit & interior glow.
	LandmarkFrKit.rect(lm, "Glass", -18.0, 1.5, 9.0, 26.5, 0.45, 15.8)
	LandmarkFrKit.rect(lm, "Timber", -18.4, 1.8, 9.0, 27.0, 15.4, 16.0)
	LandmarkFrKit.rect(lm, "WhiteTrim", -18.6, 2.0, 9.0, 27.2, 16.0, 16.5)
	lm.box("Lamp", Vector3(-8.2, 7.5, 17.8), Vector3(16.0, 11.0, 13.0))
	for i in 6:
		var mx := lerpf(-17.5, 1.0, float(i) / 5.0)
		lm.box("DarkMetal", Vector3(mx, 8.2, 26.6), Vector3(0.22, 15.4, 0.26))
	# Cantilevered entrance drop-off canopy facing Rehtorinpellonkatu (+Z).
	LandmarkFrKit.rect(lm, "DarkMetal", -14.5, -1.5, 26.5, 32.0, 4.4, 4.85)
	lm.box("Lamp", Vector3(-8.0, 4.32, 29.2), Vector3(11.0, 0.10, 0.45))
	for px: float in [-13.0, -3.0]:
		lm.frustum("DarkMetal", Vector3(px, 0.45, 31.2), 0.22, 0.22, 4.0, 8)
	# Flanking red-brick seminar wing on -X (-34..-18, +9..+26).
	LandmarkFrKit.rect(lm, "Brick", -34.0, -18.0, 9.0, 26.0, 0.45, 15.8)
	LandmarkFrParts.cornice_ring(lm, "WhiteTrim", -34.0, -18.0, 9.0, 26.0, 15.3, 0.55)
	for lv in 4:
		var wy := 2.2 + float(lv) * 3.25
		LandmarkFrKit.rect(lm, "Glass", -34.15, -33.85, 11.0, 24.0, wy, wy + 1.65)
		LandmarkFrKit.rect(lm, "Glass", -32.2, -19.8, 25.86, 26.14, wy, wy + 1.65)

static func _set_night_floods(model: Node3D) -> void:
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-8.0, 2.0, 38.0), Vector3(-8.0, 9.0, 24.0), 58.0, 0.90, 42.0, Color(1.0, 0.90, 0.72)],
		[Vector3(24.0, 2.0, 32.0), Vector3(22.0, 8.0, 20.0), 56.0, 0.80, 38.0, Color(1.0, 0.86, 0.66)],
	])
