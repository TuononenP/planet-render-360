class_name FtMainLibrary
extends RefCounted

## Turku Main Library (Turun pääkirjasto) — full two-building library block
## around Kirjastopiha (Library Courtyard) in true metres (+X ENE upstream,
## +Z SE toward Aurajoki, turned by registry yaw_deg = -35.5°):
##   (a) Old Library (Vanha kirjasto, 1903, Karl August Wrede): Dutch
##       Renaissance Revival palace (38 x 24 m, 2.5 storeys, eaves 11.6 m,
##       ridge 16.8 m, SW octagonal corner turret spirelet 18.4 m). Rusticated
##       grey granite plinth, red brick masonry with cream sandstone bands &
##       corner quoins, shaped stepped gables with finials on +Z/-X/+X,
##       arched riverside stone portal, steep terracotta roof with dormers
##       and copper cresting.
##   (b) New Main Library (Uusi pääkirjasto, 2007, JKMM Architects): L-shaped
##       contemporary block wrapping Kirjastopiha along Kauppiaskatu (-X,
##       19.5 x 34.5 m, H 13.8 m) and Linnankatu (-Z, 48.5 x 11.0 m, H 13.4 m).
##       Crisp cast-concrete frame, full-height courtyard/river glazed walls,
##       interior timber soffit & reading mezzanines with warm night glow,
##       plus a 2-storey glazed connecting bridge across the north courtyard.
## Surfaces: 10 merged PBR parts (Brick, Trim, Stone, Roof, Copper, Concrete,
## DarkMetal, Timber, Glass, Lamp).

const FOUND := -1.6

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	_materials(lm)
	_build_old_library(lm)
	_build_courtyard(lm)
	_build_new_library(lm)
	_build_glass_bridge(lm)
	lm.commit(model)
	_set_night_floods(model)

static func _materials(lm: LandmarkMesh) -> void:
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#984834", 2.4))
	lm.use("Trim", LandmarkMaterials.pbr("render", "#ECE4D2", 3.0))
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#848078", 2.5))
	lm.use("Roof", LandmarkMaterials.pbr("terracotta", "#7E4233", 2.4))
	lm.use("Copper", LandmarkFrKit.copper("#4B7A67"))
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#D8D4CA", 3.0))
	lm.use("DarkMetal", LandmarkMaterials.paint("#2B3035", 0.45, 0.55))
	lm.use("Timber", LandmarkMaterials.pbr("wood", "#B98856", 2.2, 0.65))
	lm.use("Glass", LandmarkMaterials.glass("#24323C"))
	lm.use("Lamp", LandmarkMaterials.lit("#FFEAC2", 1.35))

static func _build_old_library(lm: LandmarkMesh) -> void:
	# Rusticated granite plinth & main brick palace (38 x 24 m).
	LandmarkFrKit.rect(lm, "Stone", -19.5, 19.5, -12.5, 12.5, FOUND, 2.0)
	LandmarkFrKit.rect(lm, "Brick", -19.0, 19.0, -12.0, 12.0, 2.0, 11.6)
	# Dutch Renaissance horizontal sandstone stringcourses & eaves cornice.
	LandmarkFrParts.band(lm, "Trim", -19.0, 19.0, -12.0, 12.0, 2.0, 0.32, 0.16)
	LandmarkFrParts.band(lm, "Trim", -19.0, 19.0, -12.0, 12.0, 6.2, 0.42, 0.15)
	LandmarkFrParts.band(lm, "Trim", -19.0, 19.0, -12.0, 12.0, 6.8, 0.18, 0.12)
	LandmarkFrParts.cornice_ring(lm, "Trim", -19.0, 19.0, -12.0, 12.0, 11.0, 0.62)
	# Corner sandstone quoins on all four corners.
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			for k in 9:
				var qy := 2.4 + float(k) * 0.95
				var qw := 0.95 if k % 2 == 0 else 0.62
				lm.box("Trim", Vector3(sx * (19.0 - qw * 0.42), qy, sz * 12.04), Vector3(qw, 0.42, 0.18))
				lm.box("Trim", Vector3(sx * 19.04, qy, sz * (12.0 - qw * 0.42)), Vector3(0.18, 0.42, qw))
	# Steep terracotta hipped roof (11.6 -> 16.8 m) with copper ridge cresting.
	LandmarkFrKit.hip(lm, "Roof", -19.0, 19.0, -12.0, 12.0, 11.6, 5.2, 0.65)
	lm.beam("Copper", Vector3(-7.0, 16.95, 0.0), Vector3(7.0, 16.95, 0.0), 0.22, 0.24)
	for cx: float in [-7.0, 7.0]:
		lm.spire("Copper", Vector3(cx, 16.95, 0.0), 0.22, 0.95, 0.0, 6)
	# Three brick chimneys with sandstone caps.
	for cpos: Array in [[-11.0, -4.5], [11.0, -4.5], [12.5, 4.0]]:
		var cx: float = cpos[0]
		var cz: float = cpos[1]
		LandmarkFrKit.rect(lm, "Brick", cx - 0.75, cx + 0.75, cz - 0.75, cz + 0.75, 13.0, 17.3)
		LandmarkFrKit.rect(lm, "Trim", cx - 0.9, cx + 0.9, cz - 0.9, cz + 0.9, 17.15, 17.45)
	# Six gabled roof dormers on +Z and -Z slopes.
	for sz: float in [-1.0, 1.0]:
		for dx: float in [-12.2, 12.2]:
			var dz := sz * 9.8
			LandmarkFrKit.rect(lm, "Copper", dx - 1.15, dx + 1.15, dz - 1.1, dz + 1.1, 11.8, 14.1)
			LandmarkFrKit.gable(lm, "Copper", dx - 1.25, dx + 1.25, dz - 1.2, dz + 1.2, 14.1, 1.35, 0.2, "Trim", 0)
			LandmarkFrParts.opening(lm, "Trim", "Glass", Vector3(dx, 12.1, dz + sz * 1.12),
				Vector3(0, 0, sz), 1.3, 1.85, LandmarkFrParts.HEAD_ROUND, 0.14, 0.10, 1)
	# Central projecting riverside bay (+Z) with shaped Dutch-Renaissance stepped gable.
	LandmarkFrKit.rect(lm, "Stone", -6.9, 6.9, 11.8, 14.8, FOUND, 2.0)
	LandmarkFrKit.rect(lm, "Brick", -6.7, 6.7, 11.8, 14.6, 2.0, 12.0)
	LandmarkFrParts.band(lm, "Trim", -6.7, 6.7, 11.8, 14.6, 6.2, 0.42, 0.16)
	LandmarkFrParts.band(lm, "Trim", -6.7, 6.7, 11.8, 14.6, 11.4, 0.55, 0.18)
	LandmarkFrKit.gable(lm, "Roof", -6.7, 6.7, 11.2, 14.6, 12.0, 4.9, 0.35, "Brick", 0)
	_stepped_gable(lm, Vector3(0.0, 12.0, 14.65), Vector3.BACK, 13.4, 5.4)
	# Ornate riverside stone entrance portal & granite stair cascade (+Z).
	LandmarkFrKit.rect(lm, "Stone", -4.2, 4.2, 14.6, 16.0, FOUND, 1.1)
	LandmarkFrKit.rect(lm, "Stone", -4.8, 4.8, 16.0, 17.2, FOUND, 0.55)
	LandmarkFrParts.opening(lm, "Stone", "Glass", Vector3(0.0, 1.1, 14.6), Vector3.BACK, 3.0, 4.5,
		LandmarkFrParts.HEAD_ROUND, 0.45, 0.26, 1)
	for sx: float in [-2.2, 2.2]:
		LandmarkFrKit.rect(lm, "Trim", sx - 0.35, sx + 0.35, 14.55, 15.1, 1.1, 6.2)
	LandmarkFrParts.gable_wall(lm, "Trim", Vector3(0.0, 6.2, 15.05), Vector3.RIGHT, Vector3.BACK, 5.4, 1.5, 0.45)
	# Upper arched triple reading-room windows on riverside projection.
	for wx: float in [-3.4, 0.0, 3.4]:
		LandmarkFrParts.opening(lm, "Trim", "Glass", Vector3(wx, 7.2, 14.6), Vector3.BACK, 1.7, 3.4,
			LandmarkFrParts.HEAD_ROUND, 0.22, 0.14, 1)
	# Shaped stepped gables on courtyard (-X) and NE (+X) flanks.
	for sx: float in [-1.0, 1.0]:
		var gx := sx * 19.0
		var n := Vector3(sx, 0, 0)
		LandmarkFrKit.rect(lm, "Brick", gx - (0.0 if sx > 0 else 1.2), gx + (1.2 if sx > 0 else 0.0),
			-5.2, 5.2, 2.0, 11.8)
		LandmarkFrKit.gable(lm, "Roof", gx - (1.8 if sx > 0 else 1.2), gx + (1.2 if sx > 0 else 1.8),
			-5.2, 5.2, 11.8, 4.6, 0.3, "Brick", 1)
		_stepped_gable(lm, Vector3(gx + sx * 1.25, 11.8, 0.0), n, 10.4, 4.8)
		LandmarkFrParts.openings(lm, "Trim", "Glass", Vector3(gx + sx * 1.2, 2.7, -3.6),
			Vector3(gx + sx * 1.2, 2.7, 3.6), n, 3, 1.45, 2.6, LandmarkFrParts.HEAD_ROUND, 0.18, 0.12, 1)
		LandmarkFrParts.openings(lm, "Trim", "Glass", Vector3(gx + sx * 1.2, 7.1, -3.6),
			Vector3(gx + sx * 1.2, 7.1, 3.6), n, 3, 1.45, 2.9, LandmarkFrParts.HEAD_ROUND, 0.18, 0.12, 1)
	# Rhythmic 2-storey arched & mullioned windows along main +Z and -Z walls.
	for sz: float in [-1.0, 1.0]:
		var n := Vector3(0, 0, sz)
		var spans := [[-16.2, -8.2], [8.2, 16.2]] if sz > 0.0 else [[-16.2, 16.2]]
		for sp: Array in spans:
			var x0: float = sp[0]
			var x1: float = sp[1]
			var cnt := 3 if (x1 - x0) < 12.0 else 8
			LandmarkFrParts.openings(lm, "Trim", "Glass", Vector3(x0, 2.7, sz * 12.0),
				Vector3(x1, 2.7, sz * 12.0), n, cnt, 1.5, 2.7, LandmarkFrParts.HEAD_FLAT, 0.18, 0.12, 1)
			LandmarkFrParts.openings(lm, "Trim", "Glass", Vector3(x0, 7.1, sz * 12.0),
				Vector3(x1, 7.1, sz * 12.0), n, cnt, 1.5, 3.0, LandmarkFrParts.HEAD_ROUND, 0.18, 0.14, 1)
	# Octagonal SW corner turret with flared patinated copper spirelet (top 18.4 m).
	var tc := Vector3(-17.8, 0.0, 11.2)
	lm.frustum("Stone", Vector3(tc.x, FOUND, tc.z), 2.65, 2.55, 2.0 - FOUND, 8, PI / 8.0)
	lm.frustum("Brick", Vector3(tc.x, 2.0, tc.z), 2.45, 2.38, 10.6, 8, PI / 8.0)
	lm.frustum("Trim", Vector3(tc.x, 12.3, tc.z), 2.58, 2.62, 0.95, 8, PI / 8.0)
	LandmarkFrParts.ring_openings(lm, "Trim", "Glass", Vector3(tc.x, 7.8, tc.z), 2.42, 6, 0.72, 1.85,
		LandmarkFrParts.HEAD_ROUND, PI / 8.0)
	lm.lathe("Copper", Vector3(tc.x, 13.25, tc.z), PackedVector2Array([
		Vector2(2.75, 0.0), Vector2(1.95, 0.9), Vector2(0.85, 2.5),
		Vector2(0.28, 4.2), Vector2(0.06, 5.15)]), 8, 1.0, 1.0, PI / 8.0, false)

## Dutch-Renaissance shaped stepped brick gable with sandstone coping & finial.
static func _stepped_gable(lm: LandmarkMesh, base: Vector3, normal: Vector3, w: float, h: float) -> void:
	var n := normal.normalized()
	var r := Vector3.UP.cross(n).normalized()
	var basis := Basis(r, Vector3.UP, n)
	var steps := 5
	for i in steps:
		var t0 := float(i) / float(steps)
		var t1 := float(i + 1) / float(steps)
		var sw := lerpf(w, w * 0.22, t0)
		var sy := base.y + h * (t0 + t1) * 0.5
		var sh := h / float(steps)
		lm.box("Brick", Vector3(base.x, sy, base.z) - n * 0.18, Vector3(sw, sh, 0.42), basis)
		# Sandstone coping cap on each step shoulder.
		lm.box("Trim", Vector3(base.x, base.y + h * t1 + 0.08, base.z) - n * 0.12,
			Vector3(sw + 0.36, 0.18, 0.56), basis)
	# Central attic round-headed window & apex obelisk finial.
	LandmarkFrParts.opening(lm, "Trim", "Glass", base + Vector3(0, h * 0.18, 0.02), n, 1.8, 2.1,
		LandmarkFrParts.HEAD_ROUND, 0.18, 0.12, 1)
	lm.spire("Trim", base + Vector3(0, h + 0.16, -0.12), 0.24, 0.95, 0.0, 4)

static func _build_courtyard(lm: LandmarkMesh) -> void:
	# Kirjastopiha granite terrace between Old & New Libraries, opening to Aurajoki (+Z).
	LandmarkFrKit.rect(lm, "Stone", -36.6, -19.0, -13.5, 13.0, FOUND, 0.18)
	LandmarkFrKit.rect(lm, "Stone", -36.6, -19.0, 13.0, 15.2, FOUND, -0.25)
	# Courtyard cafe tables & warm bollard lamps.
	for cx: float in [-31.0, -25.5]:
		for cz: float in [-2.0, 3.5, 8.5]:
			lm.frustum("DarkMetal", Vector3(cx, 0.18, cz), 0.08, 0.06, 0.75, 6)
			lm.frustum("Timber", Vector3(cx, 0.93, cz), 0.65, 0.65, 0.07, 10)
	for lx: float in [-34.5, -21.0]:
		for lz: float in [-6.5, 6.5, 12.2]:
			lm.frustum("DarkMetal", Vector3(lx, 0.18, lz), 0.12, 0.10, 0.95, 8)
			lm.frustum("Lamp", Vector3(lx, 1.13, lz), 0.11, 0.11, 0.24, 8)

static func _build_new_library(lm: LandmarkMesh) -> void:
	# 2007 JKMM New Main Library: SW Kauppiaskatu wing (-56..-36.5, -23..11.5, H 13.8 m).
	LandmarkFrKit.rect(lm, "Stone", -56.4, -36.4, -23.4, 11.8, FOUND, 0.35)
	# Solid back/west & north concrete walls + deep architectural concrete roof fascia.
	LandmarkFrKit.rect(lm, "Concrete", -56.0, -36.5, -23.0, 11.5, 11.9, 13.8)
	LandmarkFrKit.rect(lm, "Concrete", -56.0, -54.4, -23.0, 11.5, 0.35, 12.0)
	LandmarkFrKit.rect(lm, "Concrete", -56.0, -36.5, -23.0, -21.6, 0.35, 12.0)
	# Interior warm birch/oak timber soffit & two reading mezzanine decks visible through glass.
	LandmarkFrKit.rect(lm, "Timber", -54.4, -37.2, -21.6, 10.9, 11.4, 11.9)
	LandmarkFrKit.rect(lm, "Timber", -54.0, -38.8, -21.0, 9.2, 4.3, 4.75)
	LandmarkFrKit.rect(lm, "Timber", -54.0, -39.4, -21.0, 8.6, 8.0, 8.45)
	# Warm night interior reading glow planes recessed behind courtyard (+X) and river (+Z) glazing.
	LandmarkFrKit.rect(lm, "Lamp", -38.4, -38.0, -19.5, 9.5, 1.1, 10.8)
	LandmarkFrKit.rect(lm, "Lamp", -53.2, -38.4, 9.5, 9.9, 1.1, 10.8)
	# Full-height glazed curtain walls facing Kirjastopiha (+X) and Aurajoki (+Z).
	LandmarkFrKit.rect(lm, "Glass", -36.75, -36.55, -21.6, 11.3, 0.45, 11.9)
	LandmarkFrKit.rect(lm, "Glass", -54.4, -36.6, 11.25, 11.45, 0.45, 11.9)
	# Deep rhythmic dark-metal mullions & transoms on courtyard & river glass walls.
	for k in 14:
		var mz := lerpf(-21.2, 11.0, float(k) / 13.0)
		lm.box("DarkMetal", Vector3(-36.52, 6.15, mz), Vector3(0.32, 11.5, 0.14))
	for k in 8:
		var mx := lerpf(-54.2, -36.7, float(k) / 7.0)
		lm.box("DarkMetal", Vector3(mx, 6.15, 11.42), Vector3(0.14, 11.5, 0.32))
	for ty: float in [4.5, 8.2]:
		lm.box("DarkMetal", Vector3(-36.52, ty, -5.1), Vector3(0.30, 0.18, 32.6))
		lm.box("DarkMetal", Vector3(-45.5, ty, 11.42), Vector3(17.8, 0.18, 0.30))
	# Kauppiaskatu west facade (-X): cast-concrete fins & horizontal ribbon glazing.
	for k in 11:
		var fz := lerpf(-21.5, 10.0, float(k) / 10.0)
		lm.box("Concrete", Vector3(-56.15, 6.2, fz), Vector3(0.55, 11.6, 0.42))
	for ry: float in [1.4, 5.2, 8.9]:
		LandmarkFrKit.rect(lm, "Glass", -56.12, -55.92, -21.2, 9.8, ry, ry + 2.3)
	# NW Linnankatu Wing (-36.5..12.0, -24.5..-13.5, H 13.4 m).
	LandmarkFrKit.rect(lm, "Stone", -36.5, 12.4, -24.8, -13.3, FOUND, 0.35)
	LandmarkFrKit.rect(lm, "Concrete", -36.5, 12.0, -24.5, -13.5, 11.6, 13.4)
	LandmarkFrKit.rect(lm, "Concrete", 10.6, 12.0, -24.5, -13.5, 0.35, 11.6)
	LandmarkFrKit.rect(lm, "Timber", -36.5, 10.6, -24.0, -14.0, 11.1, 11.6)
	LandmarkFrKit.rect(lm, "Lamp", -34.0, 9.5, -15.4, -15.0, 1.2, 10.4)
	LandmarkFrKit.rect(lm, "Glass", -36.5, 10.6, -13.75, -13.55, 0.45, 11.6)
	LandmarkFrKit.rect(lm, "Glass", -36.5, 10.6, -24.55, -24.35, 1.2, 11.2)
	for k in 17:
		var fx := lerpf(-35.5, 10.2, float(k) / 16.0)
		lm.box("DarkMetal", Vector3(fx, 6.0, -13.52), Vector3(0.14, 11.2, 0.28))
		lm.box("Concrete", Vector3(fx, 6.2, -24.62), Vector3(0.42, 11.2, 0.55))

static func _build_glass_bridge(lm: LandmarkMesh) -> void:
	# Two-storey glazed connecting bridge linking Old Library to New Library over north courtyard.
	LandmarkFrKit.rect(lm, "DarkMetal", -19.5, -8.5, -14.0, -10.4, 3.9, 4.35)
	LandmarkFrKit.rect(lm, "DarkMetal", -19.5, -8.5, -14.0, -10.4, 9.35, 9.8)
	LandmarkFrKit.rect(lm, "Timber", -19.2, -8.8, -13.7, -10.7, 4.35, 4.55)
	LandmarkFrKit.rect(lm, "Lamp", -18.5, -9.5, -12.4, -12.0, 4.7, 8.8)
	LandmarkFrKit.rect(lm, "Glass", -19.3, -8.7, -10.55, -10.40, 4.35, 9.35)
	LandmarkFrKit.rect(lm, "Glass", -19.3, -8.7, -14.00, -13.85, 4.35, 9.35)
	for k in 5:
		var bx := lerpf(-19.0, -9.0, float(k) / 4.0)
		lm.box("DarkMetal", Vector3(bx, 6.85, -10.42), Vector3(0.16, 5.1, 0.22))
		lm.box("DarkMetal", Vector3(bx, 6.85, -13.98), Vector3(0.16, 5.1, 0.22))

static func _set_night_floods(model: Node3D) -> void:
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(0.0, 1.5, 22.0), Vector3(0.0, 10.0, 14.0), 54.0, 0.85, 42.0, Color(1.0, 0.86, 0.64)],
		[Vector3(-22.0, 1.5, 19.0), Vector3(-17.8, 12.0, 11.2), 45.0, 0.80, 38.0, Color(1.0, 0.88, 0.68)],
		[Vector3(16.0, 1.5, 18.0), Vector3(12.0, 8.0, 12.0), 50.0, 0.65, 34.0, Color(1.0, 0.86, 0.66)],
		[Vector3(-28.0, 2.0, 6.0), Vector3(-37.0, 6.5, -4.0), 62.0, 0.70, 36.0, Color(1.0, 0.90, 0.74)],
	])
