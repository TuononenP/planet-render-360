class_name LandmarkMiFaenaForum
extends RefCounted

## Faena Forum — Mid-Beach MI-4D
## Site: 3300 Collins Ave, OSM way 639617563 (25.808134, -80.124057, yaw_deg = 8.8).
## Architect: OMA / Rem Koolhaas, Shohei Shigematsu & Jason Long (2016).
## Measured envelope (49.2 x 28.1 m, height_m = 22.0; +X East/Collins Ave, -X West/Indian Creek Dr):
##   - Cylindrical Drum (cx = +10.4 m, r = 13.5 m, y = 0..22.0 m): crisp white precast concrete
##     classical-modernist cylinder on Collins Ave with OMA's dramatic cantilevered wedge entry
##     undercut hovering over a curved black-granite reflecting pool and rose-pink grand amphitheatre
##     staircase, topped by a glazed central roof oculus.
##   - White Cube (cx = -13.2 m, 21.2 x 24.4 m, y = 0..22.0 m): paired orthogonal white precast block
##     linked via a glazed hyphen neck, with corner mechanical louvres and roof skylight.
##   - Facade Cutouts & Night Glow: rhythmic bands of faceted diamond, triangular, hexagonal and
##     arched-slit dark-glass geometric windows with warm golden interior glow at night.

const HEIGHT_M := 22.0
const DRUM_X := 10.4
const DRUM_R := 13.5
const CUBE_X := -13.2
const CUBE_W := 21.2
const CUBE_D := 24.4

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("WhitePrecast", LandmarkMaterials.pbr("render", "#F5F5F0", 3.4, 0.74))
	lm.use("Travertine", LandmarkMaterials.pbr("limestone", "#E3DDD0", 3.0))
	lm.use("RoseStair", LandmarkMaterials.pbr("terracotta", "#D68E7A", 2.4, 0.78))
	lm.use("DarkGranite", LandmarkMaterials.pbr("slate", "#21262B", 2.5, 0.34))
	lm.use("Glass", LandmarkMaterials.glass("#1A2730"))
	lm.use("ReflectPool", LandmarkMaterials.pool_water("#18303B", 0.05))
	lm.use("Steel", LandmarkMaterials.paint("#C9D0D7", 0.34, 0.62))
	lm.use("WarmGlow", LandmarkMaterials.lit("#FFD288", 0.82))
	lm.use("PalmFrond", LandmarkMaterials.pbr("grass", "#3E7C3B", 2.0))

	_build_plaza_and_reflecting_pool(lm)
	_build_cylindrical_drum(lm)
	_build_drum_geometric_windows(lm)
	_build_white_cube_and_neck(lm)
	lm.commit(model)

	var warm := Color(1.0, 0.86, 0.60)
	var cool := Color(0.90, 0.94, 1.0)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(27.0, 0.9, 6.0), Vector3(DRUM_X + 6.0, 12.0, 2.0), 38.0, 1.25, 56.0, warm],
		[Vector3(22.0, 0.9, -14.0), Vector3(DRUM_X + 4.0, 13.0, -6.0), 38.0, 1.10, 54.0, cool],
		[Vector3(DRUM_X + 7.5, 0.8, 3.0), Vector3(DRUM_X + 2.0, 6.0, 1.0), 22.0, 1.35, 62.0, warm],
		[Vector3(-27.0, 0.9, 0.0), Vector3(CUBE_X - 8.0, 12.5, 0.0), 36.0, 1.05, 54.0, cool],
		[Vector3(0.0, 0.9, 17.5), Vector3(-2.0, 12.5, 11.0), 38.0, 1.10, 56.0, cool],
	])

static func _skirt_y(a: float) -> float:
	# Cantilevered OMA wedge entry undercut facing Collins Ave / SE corner (a ≈ 0.22 rad)
	var da := wrapf(a - 0.22, -PI, PI)
	if absf(da) >= 2.25:
		return 0.32
	var u := cos(da * (PI * 0.5 / 2.25))
	return 0.32 + 6.10 * pow(maxf(u, 0.0), 1.45)

static func _build_plaza_and_reflecting_pool(lm: LandmarkMesh) -> void:
	# Travertine block plinth (48.8 x 27.6 m, y = -0.35..0.32 m)
	var plinth := TowerSpec.plan("round", 48.8, 27.6, 3.5, 0.0, 0.0)
	lm.poly_prism("Travertine", plinth, -0.35, 0.32)

	# Crescent black-granite reflecting pool hugging the cantilevered SE drum brow (front.jpg)
	var pool := PackedVector2Array()
	var segs := 18
	for i: int in segs + 1:
		var a := lerpf(-1.05, 1.35, float(i) / float(segs))
		pool.append(Vector2(DRUM_X + cos(a) * 14.3, sin(a) * 14.3))
	for i: int in segs + 1:
		var a := lerpf(1.35, -1.05, float(i) / float(segs))
		pool.append(Vector2(DRUM_X + cos(a) * 10.2, sin(a) * 10.2))
	lm.poly_prism("DarkGranite", LandmarkMiKit._offset_poly(pool, 0.28), 0.32, 0.46)
	lm.poly_prism("ReflectPool", pool, 0.34, 0.48)

	# Two curved white OMA plaza benches & perimeter slender palms (front.jpg / side.jpg, h < 16.5 m)
	for ba: float in [-0.72, 0.92]:
		var bp := Vector3(DRUM_X + cos(ba) * 15.2, 0.58, sin(ba) * 15.2)
		var bt := Basis(Vector3(-sin(ba), 0.0, cos(ba)), Vector3.UP, Vector3(cos(ba), 0.0, sin(ba)))
		lm.box("WhitePrecast", bp, Vector3(4.2, 0.48, 0.85), bt, 0.03)
	var palms: Array[Vector3] = [
		Vector3(22.6, 0.32, -10.8), Vector3(23.2, 0.32, 9.8),
		Vector3(1.5, 0.32, 12.6), Vector3(1.5, 0.32, -12.6),
		Vector3(-23.2, 0.32, 11.4), Vector3(-23.2, 0.32, -11.4),
	]
	for k: int in palms.size():
		LandmarkMiKit.royal_palm(lm, "Travertine", "PalmFrond", palms[k], 13.8 + float(k % 3) * 1.1, float(k))

static func _build_cylindrical_drum(lm: LandmarkMesh) -> void:
	var segs := 44
	var outer_rows: Array = []
	var ring_bot := PackedVector3Array()
	var ring_top := PackedVector3Array()
	var inner_bot := PackedVector3Array()
	for i: int in segs + 1:
		var a := TAU * float(i) / float(segs)
		var ca := cos(a)
		var sa := sin(a)
		var ys := _skirt_y(a)
		ring_bot.append(Vector3(DRUM_X + ca * DRUM_R, ys, sa * DRUM_R))
		ring_top.append(Vector3(DRUM_X + ca * DRUM_R, HEIGHT_M, sa * DRUM_R))
		inner_bot.append(Vector3(DRUM_X + ca * 6.4, 0.32, sa * 6.4))
	outer_rows.append(ring_bot)
	outer_rows.append(ring_top)
	lm.grid("WhitePrecast", outer_rows, Vector3(DRUM_X, 12.0, 0.0), true)

	# Smooth cantilevered white soffit sweeping inward from the wedge rim to the glazed foyer drum
	var soffit_rows: Array = [inner_bot, ring_bot]
	lm.grid("WhitePrecast", soffit_rows, Vector3(0.0, -1.0, 0.0))

	# Recessed ground-level glazed cylindrical foyer & warm golden interior lantern
	lm.frustum("Glass", Vector3(DRUM_X, 0.32, 0.0), 6.55, 6.55, 6.8, 28)
	lm.frustum("WarmGlow", Vector3(DRUM_X, 0.50, 0.0), 5.60, 5.60, 18.2, 24)

	# Rose-terracotta grand curved amphitheatre staircase under the cantilever (quarter.jpg)
	var steps := 14
	for s: int in steps:
		var t0 := float(s) / float(steps)
		var sy0 := 0.32 + t0 * 4.4
		var sy1 := 0.32 + (float(s + 1) / float(steps)) * 4.4
		var sx := DRUM_X + 11.4 - t0 * 4.8
		var sw := 5.6 - t0 * 1.1
		var b_st := Basis(Vector3(-0.22, 0.0, 0.975).normalized(), Vector3.UP, Vector3(0.975, 0.0, 0.22).normalized())
		lm.box("RoseStair", Vector3(sx, (sy0 + sy1) * 0.5, 1.8 - t0 * 0.8), Vector3(sw, sy1 - sy0 + 0.04, 0.42), b_st, 0.0)
	for sg: float in [-2.4, 0.0, 2.4]:
		lm.beam("Steel", Vector3(DRUM_X + 11.4, 1.25, 1.8 + sg * 0.95),
			Vector3(DRUM_X + 6.6, 5.65, 1.0 + sg * 0.78), 0.07, 0.07)

	# Flat concrete roof deck & central Pantheon-inspired glazed oculus topping at exact HEIGHT_M = 22.0 m
	lm.lathe("WhitePrecast", Vector3(DRUM_X, 21.65, 0.0), PackedVector2Array([
		Vector2(DRUM_R, 0.0), Vector2(DRUM_R, 0.35), Vector2(4.15, 0.35), Vector2(4.15, 0.05)]), 36)
	lm.disc("Glass", Vector3(DRUM_X, 21.82, 0.0), Vector3.UP, 4.18, 28)
	lm.disc("WarmGlow", Vector3(DRUM_X, 21.62, 0.0), Vector3.UP, 3.85, 24)

static func _build_drum_geometric_windows(lm: LandmarkMesh) -> void:
	# OMA constellation of faceted diamond, triangular, hexagonal & vertical-arch dark-glass cutouts (side.jpg)
	var cols := 24
	for i: int in cols:
		var a := TAU * float(i) / float(cols)
		# Skip hyphen junction zone toward Cube (-X around PI)
		if absf(wrapf(a - PI, -PI, PI)) < 0.42:
			continue
		var ys := _skirt_y(a)
		var n3 := Vector3(cos(a), 0.0, sin(a))
		var t3 := Vector3(-sin(a), 0.0, cos(a))
		var p_wall := Vector3(DRUM_X, 0.0, 0.0) + n3 * (DRUM_R + 0.04)
		for row: int in 4:
			var yc := 4.0 + float(row) * 4.4
			if yc - 1.8 < ys + 0.65 or yc + 1.8 > HEIGHT_M - 0.85:
				continue
			var key := "WarmGlow" if ((i * 3 + row) % 7 == 0) else "Glass"
			var pat := (i + row * 2) % 4
			if pat == 0:
				# Pointed diamond / hexagonal arch window
				_wall_poly(lm, key, p_wall + Vector3(0.0, yc, 0.0), t3, n3, [
					Vector2(0.0, 1.85), Vector2(1.05, 0.75), Vector2(1.05, -0.95),
					Vector2(0.0, -1.65), Vector2(-1.05, -0.95), Vector2(-1.05, 0.75)])
			elif pat == 1:
				# Right-pointing OMA acute triangle cutout
				_wall_poly(lm, key, p_wall + Vector3(0.0, yc, 0.0), t3, n3, [
					Vector2(-1.10, 1.15), Vector2(1.20, 0.0), Vector2(-1.10, -1.15)])
			elif pat == 2:
				# Paired vertical colonnade slits (seen on SE Collins Ave side in side.jpg)
				for sx: float in [-0.58, 0.58]:
					lm.box(key, p_wall + Vector3(0.0, yc, 0.0) + t3 * sx,
						Vector3(0.68, 2.85, 0.12), Basis(t3, Vector3.UP, n3), 0.0)
			else:
				# Trapezoidal / slanted quad cutout
				_wall_poly(lm, key, p_wall + Vector3(0.0, yc, 0.0), t3, n3, [
					Vector2(-1.0, 1.35), Vector2(1.05, 0.65), Vector2(1.05, -1.25), Vector2(-1.0, -0.75)])

static func _wall_poly(lm: LandmarkMesh, key: String, c: Vector3, tang: Vector3, nrm: Vector3,
		pts: Array) -> void:
	var p0_2: Vector2 = pts[0]
	var p0 := c + tang * p0_2.x + Vector3.UP * p0_2.y
	for k: int in range(1, pts.size() - 1):
		var pa_2: Vector2 = pts[k]
		var pb_2: Vector2 = pts[k + 1]
		var pa := c + tang * pa_2.x + Vector3.UP * pa_2.y
		var pb := c + tang * pb_2.x + Vector3.UP * pb_2.y
		lm.tri(key, p0, pa, pb, nrm, nrm, nrm, p0_2, pa_2, pb_2)

static func _build_white_cube_and_neck(lm: LandmarkMesh) -> void:
	# Recessed glazed hyphen neck linking Cube and Drum (x = -3.2..+0.2 m, y = 0.32..20.6 m)
	lm.box("Glass", Vector3(-1.6, 10.46, 0.0), Vector3(4.2, 20.28, 12.6), Basis(), 0.0)
	lm.box("WhitePrecast", Vector3(-1.6, 20.95, 0.0), Vector3(4.4, 0.70, 13.0), Basis(), 0.02)

	# Orthogonal White Cube (cx = -13.2 m, 21.2 x 24.4 m, y = 0.32..22.00 m exact)
	var h_cube := HEIGHT_M - 0.32
	lm.box("WhitePrecast", Vector3(CUBE_X, 0.32 + h_cube * 0.5, 0.0),
		Vector3(CUBE_W, h_cube, CUBE_D), Basis(), 0.0)
	lm.box("WarmGlow", Vector3(CUBE_X, 10.5, 0.0), Vector3(CUBE_W - 1.6, 17.5, CUBE_D - 1.6), Basis(), 0.0)
	# Cube rooftop skylight oculus flush below 22.00 m parapet
	lm.box("Glass", Vector3(CUBE_X, 21.96, 0.0), Vector3(7.4, 0.06, 7.4), Basis(), 0.0)

	# Geometric diamond & triangular window cutouts across North (-Z), South (+Z), and West (-X) faces
	for sz: float in [-1.0, 1.0]:
		var fz := sz * (CUBE_D * 0.5 + 0.04)
		var n_z := Vector3(0.0, 0.0, sz)
		var t_z := Vector3(-sz, 0.0, 0.0)
		for bx: int in 5:
			var wx := CUBE_X - 7.8 + float(bx) * 3.9
			for ry: int in 4:
				var wy := 4.2 + float(ry) * 4.3
				if bx == 4 and ry == 3:
					# Corner slatted mechanical louvres seen at top corner of Cube in side.jpg
					for lv: int in 2:
						lm.box("DarkGranite", Vector3(wx - 0.55 + float(lv) * 1.15, wy + 0.2, fz),
							Vector3(0.82, 3.3, 0.12), Basis(), 0.0)
					continue
				var k_mat := "WarmGlow" if ((bx + ry * 2) % 6 == 0) else "Glass"
				_wall_poly(lm, k_mat, Vector3(wx, wy, fz), t_z, n_z, [
					Vector2(0.0, 1.75), Vector2(1.05, 0.15), Vector2(0.0, -1.65), Vector2(-1.05, -0.15)])

	var fx := CUBE_X - CUBE_W * 0.5 - 0.04
	for bz: int in 5:
		var wz := -8.4 + float(bz) * 4.2
		for ry: int in 4:
			var wy := 4.2 + float(ry) * 4.3
			var k_w := "WarmGlow" if ((bz * 2 + ry) % 6 == 0) else "Glass"
			_wall_poly(lm, k_w, Vector3(fx, wy, wz), Vector3(0.0, 0.0, 1.0), Vector3(-1.0, 0.0, 0.0), [
				Vector2(0.0, 1.70), Vector2(1.05, 0.0), Vector2(0.0, -1.70), Vector2(-1.05, 0.0)])
