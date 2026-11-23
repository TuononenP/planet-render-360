class_name LandmarkMiSeaquariumDome
extends RefCounted

## Miami Seaquarium Golden Dome — Virginia Key (MI-10)
## Site: 4400 Rickenbacker Causeway, OSM way 480675688 (25.733273, -80.165292, yaw_deg 1.9).
## Architect / System: R. Buckminster Fuller / Kaiser Aluminum stressed-skin geodesic dome (1960).
## Late-2026 state (MI-0.3): historic 1960 gold-anodized geodesic dome standing shuttered on site.
## Measured envelope & materials (42.0 x 42.0 m footprint, H = 17.0 m):
##   - Circular concrete amphitheatre & marine show-pool basin (r = 21.0 m, y = -0.40..4.8 m) with
##     shuttered perimeter concourse walls, raked aqua seating bleachers & turquoise circular pool.
##   - Five mid-century modern angled concrete pin-joint buttress piers around r = 20.4 m anchoring
##     the 5-fold icosahedral geodesic shell with open scalloped air-bays under the rim.
##   - Shimmering gold-anodized aluminium faceted geodesic dome (#D4AF37 metallic gold panels) +
##     exterior white tubular space-frame struts rising to exact zenith y = 17.0 m.

const HEIGHT_M := 17.0
const DOME_BASE_Y := 4.80
const SPHERE_R := 21.85
const SPHERE_CY := HEIGHT_M - SPHERE_R # -4.85 m so zenith sits at exact 17.00 m
const RINGS := 6

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("GoldAlum", LandmarkMaterials.paint("#D4AF37", 0.28, 0.82))
	lm.use("WhiteStrut", LandmarkMaterials.paint("#F0F2F5", 0.38, 0.35))
	lm.use("DarkAlum", LandmarkMaterials.paint("#7C6828", 0.52, 0.55))
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#C5C0B6", 3.5))
	lm.use("WhiteStucco", LandmarkMaterials.pbr("render", "#ECE9E0", 3.5))
	lm.use("PoolWater", LandmarkMaterials.pool_water("#2A8C96", 0.12))
	lm.use("SeatAqua", LandmarkMaterials.paint("#368B92", 0.54, 0.08))
	lm.use("Steel", LandmarkMaterials.paint("#454C52", 0.48, 0.58))

	_build_amphitheatre_base(lm)
	_build_five_buttress_piers(lm)
	_build_geodesic_golden_dome(lm)
	lm.commit(model)

	var warm := Color(1.0, 0.86, 0.56)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(24.0, 1.2, 0.0), Vector3(8.0, 13.0, 0.0), 56.0, 1.10, 38.0, warm],
		[Vector3(-24.0, 1.2, 0.0), Vector3(-8.0, 13.0, 0.0), 56.0, 1.10, 38.0, warm],
		[Vector3(0.0, 1.2, 24.0), Vector3(0.0, 13.0, 8.0), 56.0, 1.10, 38.0, warm],
		[Vector3(0.0, 1.2, -24.0), Vector3(0.0, 13.0, -8.0), 56.0, 1.10, 38.0, warm],
	])

static func _build_amphitheatre_base(lm: LandmarkMesh) -> void:
	# Circular concrete plaza apron (r = 21.2 m, y = -0.40..0.45 m)
	lm.frustum("Concrete", Vector3(0.0, -0.40, 0.0), 21.3, 21.1, 0.85, 32)
	# Perimeter whitewashed stucco concourse drum (r = 18.8 m, y = 0.45..3.55 m) + shuttered entry portals
	lm.frustum("WhiteStucco", Vector3(0.0, 0.45, 0.0), 18.9, 18.7, 3.10, 32)
	lm.frustum("Concrete", Vector3(0.0, 3.55, 0.0), 19.2, 19.0, 0.35, 32)

	# Central marine show pool tank & turquoise water surface (offset slightly toward -Z stage side)
	var pool_c := Vector3(0.0, 0.45, -3.2)
	lm.frustum("WhiteStucco", pool_c, 10.6, 10.4, 1.45, 28)
	lm.frustum("Concrete", pool_c + Vector3(0.0, 1.40, 0.0), 10.8, 10.8, 0.22, 28)
	lm.disc("PoolWater", pool_c + Vector3(0.0, 1.48, 0.0), Vector3.UP, 9.9, 28)
	# Stage performance platform on -Z edge of show pool
	lm.box("Concrete", Vector3(0.0, 1.65, -13.6), Vector3(13.5, 0.90, 4.2))

	# Semicircular raked concrete & aqua bleacher tiers wrapping the +Z spectator half (y = 1.6..4.9 m)
	for t: int in 6:
		var u := float(t) / 5.0
		var r_in := lerpf(11.4, 16.8, u)
		var ty := lerpf(1.75, 4.65, u)
		var segs := 14
		for s: int in segs:
			var a0 := -0.62 * PI + 1.24 * PI * (float(s) / float(segs))
			var a1 := -0.62 * PI + 1.24 * PI * (float(s + 1) / float(segs))
			var p0 := Vector2(sin(a0) * r_in, cos(a0) * r_in - 1.2)
			var p1 := Vector2(sin(a1) * r_in, cos(a1) * r_in - 1.2)
			var mid := (p0 + p1) * 0.5
			var tang := (p1 - p0).normalized()
			var out2 := Vector2( tang.y, -tang.x)
			var b := Basis(Vector3(tang.x, 0.0, tang.y), Vector3.UP, Vector3(out2.x, 0.0, out2.y))
			var sl := p0.distance_to(p1)
			lm.box("Concrete", Vector3(mid.x, ty - 0.22, mid.y), Vector3(sl + 0.12, 0.52, 0.95), b, 0.0)
			lm.box("SeatAqua", Vector3(mid.x, ty + 0.12, mid.y), Vector3(sl * 0.92, 0.20, 0.52), b, 0.0)

	# Shuttered perimeter entry portals & slatted louver screens around the drum
	for p: int in 5:
		var ang := (float(p) + 0.5) * TAU / 5.0
		var dir := Vector3(sin(ang), 0.0, cos(ang))
		var tang := Vector3(cos(ang), 0.0, -sin(ang))
		var pb := Basis(tang, Vector3.UP, dir)
		lm.box("Concrete", dir * 19.3 + Vector3(0.0, 2.0, 0.0), Vector3(4.6, 3.1, 1.4), pb)
		lm.box("Steel", dir * 19.95 + Vector3(0.0, 1.75, 0.0), Vector3(3.2, 2.4, 0.18), pb, 0.0)

static func _build_five_buttress_piers(lm: LandmarkMesh) -> void:
	# Kaiser Aluminum domes rest on 5 pentagonal pin-jointed concrete buttress piers around r = 20.2 m
	for i: int in 5:
		var ang := float(i) * TAU / 5.0
		var dir := Vector3(sin(ang), 0.0, cos(ang))
		var tang := Vector3(cos(ang), 0.0, -sin(ang))
		var pb := Basis(tang, Vector3.UP, dir)
		# Heavy outward-raked concrete buttress block + steel pin shoe receiving geodesic ring struts
		lm.box("Concrete", dir * 20.35 + Vector3(0.0, 1.65, 0.0), Vector3(2.4, 3.3, 2.8), pb)
		lm.beam("Concrete", dir * 21.1 + Vector3(0.0, 0.45, 0.0),
			dir * 18.35 + Vector3(0.0, DOME_BASE_Y + 0.10, 0.0), 1.35, 1.15, tang)
		lm.box("Steel", dir * 18.25 + Vector3(0.0, DOME_BASE_Y + 0.05, 0.0), Vector3(0.85, 0.55, 0.85), pb)

static func _build_geodesic_golden_dome(lm: LandmarkMesh) -> void:
	# True 5-fold icosahedral geodesic subdivision from zenith (k = 0 at y = 17.0 m) down to ring k = 6
	# (y = 4.80 m, r = 18.14 m), with 5*k vertices on ring k -> 180 flat gold-anodized diamond/triangle
	# stressed-skin panels + exterior white tubular space-frame struts!
	var theta_max := acos((DOME_BASE_Y - SPHERE_CY) / SPHERE_R) # polar angle at base (~0.978 rad)
	var rings: Array = []
	for k: int in RINGS + 1:
		var ring := PackedVector3Array()
		if k == 0:
			ring.append(Vector3(0.0, HEIGHT_M - 0.08, 0.0))
		else:
			var theta := theta_max * float(k) / float(RINGS)
			var ry := SPHERE_CY + cos(theta) * SPHERE_R
			var rr := sin(theta) * SPHERE_R
			var count := 5 * k
			# Slight half-step twist on odd rings gives crisp equilateral geodesic triangulation
			var phase := (PI / float(count)) if (k % 2 == 1) else 0.0
			for m: int in count:
				var a := phase + TAU * float(m) / float(count)
				ring.append(Vector3(sin(a) * rr, ry, cos(a) * rr))
		rings.append(ring)

	# Emit faceted gold-anodized panels & exterior white space-frame struts for every geodesic band
	var center := Vector3(0.0, SPHERE_CY, 0.0)
	for k: int in RINGS:
		var upper: PackedVector3Array = rings[k]
		var lower: PackedVector3Array = rings[k + 1]
		if k == 0:
			for m: int in 5:
				var a := upper[0]
				var b := lower[m]
				var c := lower[(m + 1) % 5]
				_emit_dome_tri(lm, a, b, c, center)
				_emit_strut(lm, a, b, center)
				_emit_strut(lm, b, c, center)
		else:
			# Subdivide each of the 5 icosahedral sectors cleanly between k vertices above & (k+1) below
			for sec: int in 5:
				var u0 := sec * k
				var l0 := sec * (k + 1)
				for j: int in k + 1:
					var lb := lower[(l0 + j) % lower.size()]
					var lc := lower[(l0 + j + 1) % lower.size()]
					var ua := upper[(u0 + mini(j, k - 1)) % upper.size()]
					if j == k:
						ua = upper[(u0 + k) % upper.size()]
					_emit_dome_tri(lm, ua, lb, lc, center)
					_emit_strut(lm, ua, lb, center)
					_emit_strut(lm, lb, lc, center)
					if j < k:
						var ub := upper[(u0 + j + 1) % upper.size()]
						_emit_dome_tri(lm, ua, lc, ub, center)
						_emit_strut(lm, lc, ub, center)

	# Perimeter scalloped tension ring & zenith ventilator cap reaching exact HEIGHT_M = 17.0 m
	var rim: PackedVector3Array = rings[RINGS]
	for i: int in rim.size():
		var p0 := rim[i]
		var p1 := rim[(i + 1) % rim.size()]
		lm.beam("WhiteStrut", p0, p1, 0.24, 0.28)
	lm.lathe("GoldAlum", Vector3(0.0, HEIGHT_M - 0.18, 0.0), PackedVector2Array([
		Vector2(0.85, 0.0), Vector2(0.45, 0.12), Vector2(0.0, 0.18)]), 10, 1.0, 1.0, 0.0, false)

static func _emit_dome_tri(lm: LandmarkMesh, a: Vector3, b: Vector3, c: Vector3, center: Vector3) -> void:
	var mid := (a + b + c) / 3.0
	var n := (b - a).cross(c - a).normalized()
	if n.dot(mid - center) < 0.0:
		n = -n
	var ua := Vector2(a.x, a.z)
	var ub := Vector2(b.x, b.z)
	var uc := Vector2(c.x, c.z)
	lm.tri("GoldAlum", a, b, c, n, n, n, ua, ub, uc)
	# Inner structural liner so viewing from below the scalloped rim shows an enclosed dome soffit
	var in_off := -n * 0.12
	lm.tri("DarkAlum", a + in_off, c + in_off, b + in_off, -n, -n, -n, ua, uc, ub)

static func _emit_strut(lm: LandmarkMesh, a: Vector3, b: Vector3, center: Vector3) -> void:
	var na := (a - center).normalized()
	var nb := (b - center).normalized()
	lm.beam("WhiteStrut", a + na * 0.09, b + nb * 0.09, 0.11, 0.11, (na + nb).normalized())
