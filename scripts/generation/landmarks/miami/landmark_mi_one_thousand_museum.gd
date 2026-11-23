class_name LandmarkMiOneThousandMuseum
extends RefCounted

## One Thousand Museum (1000 Biscayne Blvd) — Miami MI-2B
## Architect: Zaha Hadid Architects (completed 2019), 62 storeys, height_m = 216.0.
## Site: OSM relation 9396621, centroid 25.784212, -80.190210, yaw_deg = -2.2 (+X East to Biscayne Bay).
## Envelope:
##   - Perforated white GFRC concrete & dark-glass podium (46.0 x 32.0 m, y = 0.0..18.0 m)
##     with horizontal louvred garage bands and west rooftop lap pool terrace.
##   - Sculpted crystalline dark-glass shaft (y = 18.0..194.0 m) with recessed curved balcony slabs,
##     rising into the double-height glazed aquatic sky-lounge crown (y = 194.0..213.5 m).
##   - Signature white GFRC curving exoskeleton (#F3F2EE): 4 mirrored pairs of wide sculptural
##     columns at the base that split, weave at mid-height, and flare into organic teardrop
##     arches framing the aquatic crown.
##   - Cantilevered circular rooftop helipad disc (y = 214.5..216.0 m) with white "H" & net ring.

const HEIGHT_M := 216.0

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	var kit := SkyKit.new(lm)
	kit.wall("Shaft", "black_glass", 3.1, 3.25)
	lm.use("Exo", LandmarkMaterials.pbr("render", "#F3F2EE", 3.5, 0.42))
	lm.use("Podium", LandmarkMaterials.pbr("concrete", "#E6E4DE", 3.5))
	lm.use("DarkMetal", LandmarkMaterials.paint("#22262C", 0.42, 0.48))
	lm.use("Helipad", LandmarkMaterials.pbr("asphalt", "#34383E", 3.0, 0.86))
	lm.use("Glass", LandmarkMaterials.glass("#182A3A"))
	lm.use("Pool", LandmarkMaterials.pool_water("#28AAC4"))
	lm.use("CrownLamp", LandmarkMaterials.lit("#FFF2D6", 1.15))

	_podium(lm)
	_shaft_and_crown(lm, kit)
	_exoskeleton(lm)
	_helipad(lm)
	lm.commit(model)

	var spots: Array = [
		[Vector3(29.0, 1.5, -14.0), Vector3(6.5, 108.0, 0.0), 52.0, 1.35, 225.0, Color(0.96, 0.95, 1.0)],
		[Vector3(29.0, 1.5, 14.0), Vector3(6.5, 108.0, 0.0), 52.0, 1.35, 225.0, Color(0.96, 0.95, 1.0)],
		[Vector3(-27.0, 1.5, 0.0), Vector3(2.0, 105.0, 0.0), 50.0, 1.15, 220.0, Color(0.95, 0.94, 0.98)],
		[Vector3(4.5, 19.2, 18.5), Vector3(4.5, 115.0, 2.0), 48.0, 1.15, 215.0, Color(0.96, 0.95, 1.0)],
		[Vector3(4.5, 19.2, -18.5), Vector3(4.5, 115.0, -2.0), 48.0, 1.15, 215.0, Color(0.96, 0.95, 1.0)],
		[Vector3(16.0, 194.5, 0.0), Vector3(5.0, 211.0, 0.0), 58.0, 1.10, 32.0, Color(1.0, 0.91, 0.74)],
	]
	model.set_meta(LandmarkLights.FLOOD_META, spots)
	model.set_meta(LandmarkLights.HALO_META, [
		[Vector3(5.0, HEIGHT_M, 0.0), 2.4, Color(1.0, 0.16, 0.10)],
	])

static func _podium(lm: LandmarkMesh) -> void:
	# 46.0 x 32.0 m podium centred at x = 0, z = 0; tower shaft rises over the +X (Biscayne) half.
	lm.box("DarkMetal", Vector3(0.0, 0.25, 0.0), Vector3(46.0, 0.50, 32.0), Basis(), 0.04)
	# Ground level recessed dark-glass lobby & retail vitrines (y = 0.5..5.4 m)
	lm.box("Glass", Vector3(0.5, 2.95, 0.0), Vector3(43.8, 4.90, 29.8), Basis(), 0.0)
	# Sculpted white GFRC ground colonnade & Biscayne porte-cochere portal on +X
	lm.box("Exo", Vector3(22.4, 5.15, 0.0), Vector3(1.4, 0.75, 31.6), Basis(), 0.05)
	for sz in [-1.0, 1.0]:
		var s: float = float(sz)
		lm.box("Exo", Vector3(0.0, 2.95, s * 15.55), Vector3(45.6, 4.90, 0.90), Basis(), 0.04)
		lm.beam("Exo", Vector3(22.5, 0.0, s * 9.8), Vector3(21.8, 5.4, s * 6.4), 1.55, 1.15, Vector3.RIGHT)
	lm.box("Exo", Vector3(-22.55, 2.95, 0.0), Vector3(0.90, 4.90, 31.4), Basis(), 0.04)

	# Perforated white GFRC garage levels (y = 5.4..17.4 m) with horizontal louvred shadow bands
	lm.box("DarkMetal", Vector3(0.0, 11.4, 0.0), Vector3(45.0, 12.0, 31.0), Basis(), 0.0)
	var bands := 7
	var bh := 12.0 / float(bands)
	for i in bands:
		var yc := 5.4 + (float(i) + 0.52) * bh
		lm.box("Podium", Vector3(0.0, yc, 0.0), Vector3(45.8, bh * 0.66, 31.8), Basis(), 0.03)
	# Corner sculpted GFRC rounded/chamfered piers tying podium into tower base
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			lm.box("Exo", Vector3(float(sx) * 22.1, 9.0, float(sz) * 15.1),
				Vector3(1.8, 18.0, 1.8), Basis(), 0.14)

	# Podium rooftop terrace slab & white parapet (y = 17.4..18.35 m) + west amenity lap pool
	lm.box("Exo", Vector3(0.0, 17.75, 0.0), Vector3(46.0, 0.70, 32.0), Basis(), 0.05)
	for sz in [-1.0, 1.0]:
		lm.box("Exo", Vector3(0.0, 18.28, float(sz) * 15.75), Vector3(46.0, 0.50, 0.50), Basis(), 0.02)
	lm.box("Exo", Vector3(-22.75, 18.28, 0.0), Vector3(0.50, 0.50, 31.0), Basis(), 0.02)
	lm.box("Exo", Vector3(-13.5, 18.18, 0.0), Vector3(13.6, 0.30, 8.8), Basis(), 0.02)
	lm.box("Pool", Vector3(-13.5, 18.35, 0.0), Vector3(12.2, 0.06, 7.4), Basis(), 0.0)

static func _shaft_dims(t: float) -> Vector3:
	# Returns Vector3(width_x, depth_z, cut) at normalized height t in 0..1 (y = 18..194 m).
	var swell := sin(t * PI) * 1.4
	var taper := lerpf(1.0, 0.88, pow(t, 1.35))
	var w := 29.6 * taper + swell * 0.8
	var d := 24.4 * taper + swell
	var cut := lerpf(3.4, 4.6, t)
	return Vector3(w, d, cut)

static func _crystal_plan(w: float, d: float, cut: float, cx: float) -> PackedVector2Array:
	var hx := w * 0.5
	var hz := d * 0.5
	var bx := 1.15
	var bz := 0.95
	return PackedVector2Array([
		Vector2(cx - hx + cut, -hz),
		Vector2(cx, -hz - bz),
		Vector2(cx + hx - cut, -hz),
		Vector2(cx + hx, -hz + cut),
		Vector2(cx + hx + bx, 0.0),
		Vector2(cx + hx, hz - cut),
		Vector2(cx + hx - cut, hz),
		Vector2(cx, hz + bz),
		Vector2(cx - hx + cut, hz),
		Vector2(cx - hx, hz - cut),
		Vector2(cx - hx - bx, 0.0),
		Vector2(cx - hx, -hz + cut),
	])

static func _shaft_and_crown(lm: LandmarkMesh, kit: SkyKit) -> void:
	var cx := 5.0
	var y0 := 18.0
	var y_crown := 194.0
	var tiers := 11
	for i in tiers:
		var t0 := float(i) / float(tiers)
		var t1 := float(i + 1) / float(tiers)
		var d0 := _shaft_dims(t0)
		var d1 := _shaft_dims(t1)
		var p0 := _crystal_plan(d0.x, d0.y, d0.z, cx)
		var p1 := _crystal_plan(d1.x, d1.y, d1.z, cx)
		kit.loft("Shaft", p0, p1, lerpf(y0, y_crown, t0), lerpf(y0, y_crown, t1))

	# Recessed white residential balcony slabs every 2 storeys (tucked inside exoskeleton envelope)
	var bal_count := 26
	for b in bal_count:
		var tb := (float(b) + 0.5) / float(bal_count)
		var yb := lerpf(21.0, 191.5, tb)
		var dm := _shaft_dims(tb)
		var bpoly := _crystal_plan(dm.x + 1.35, dm.y + 1.35, dm.z * 0.92, cx)
		lm.poly_prism("Podium", bpoly, yb - 0.24, yb, true)

	# Double-height glazed Aquatic Sky-Lounge Crown (y = 194.0..209.2 m)
	var dc0 := _shaft_dims(1.0)
	var p_low := _crystal_plan(dc0.x, dc0.y, dc0.z, cx)
	var p_mid := _crystal_plan(dc0.x * 0.93, dc0.y * 0.93, dc0.z * 0.95, cx)
	var p_top := _crystal_plan(dc0.x * 0.82, dc0.y * 0.82, dc0.z * 0.90, cx)
	lm.poly_prism("Glass", p_low, 194.0, 202.5, false)
	lm.poly_prism("Glass", p_mid, 202.5, 209.2, true)
	# Warm glowing sky-lounge ceiling & indoor aquatic pool band visible through crown glass
	lm.poly_prism("Pool", _crystal_plan(dc0.x * 0.76, dc0.y * 0.76, 3.2, cx), 194.4, 194.9, true)
	lm.poly_prism("CrownLamp", _crystal_plan(dc0.x * 0.86, dc0.y * 0.86, 3.6, cx), 201.8, 202.35, true)
	lm.poly_prism("CrownLamp", _crystal_plan(dc0.x * 0.78, dc0.y * 0.78, 3.4, cx), 208.3, 208.9, true)
	lm.poly_prism("Exo", p_top, 209.2, 210.4, true)

	# Sculpted organic corner crown crests rising to y = 213.5 m around the recessed roof bowl
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var c0 := Vector3(cx + float(sx) * 9.8, 209.0, float(sz) * 7.8)
			var c1 := Vector3(cx + float(sx) * 8.4, 213.5, float(sz) * 6.6)
			lm.beam("Exo", c0, c1, 2.6, 1.5, Vector3(float(sx), 0.0, float(sz)), true)
			# Parabolic dip beam bridging between crests along each face
			lm.beam("Exo", c1, Vector3(cx + float(sx) * 9.0, 211.2, 0.0), 1.35, 1.05, Vector3(float(sx), 0.0, 0.0), true)
			lm.beam("Exo", c1, Vector3(cx, 211.2, float(sz) * 7.2), 1.35, 1.05, Vector3(0.0, 0.0, float(sz)), true)

static func _exoskeleton(lm: LandmarkMesh) -> void:
	var cx := 5.0
	var segs := 22
	# 1) Four continuous sculpted chamfer-corner structural columns (y = 0.0..209.5 m)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var pts := PackedVector3Array()
			var widths := PackedFloat32Array()
			for j in segs + 1:
				var u := float(j) / float(segs)
				var y := lerpf(0.0, 209.5, u)
				var x: float
				var z: float
				if y < 18.0:
					var up := y / 18.0
					var dm0 := _shaft_dims(0.0)
					x = lerpf(cx + float(sx) * 16.4, cx + float(sx) * (dm0.x * 0.5 - 1.2), smoothstep(0.0, 1.0, up))
					z = lerpf(float(sz) * 14.6, float(sz) * (dm0.y * 0.5 - 1.0), smoothstep(0.0, 1.0, up))
				else:
					var ut := clampf((y - 18.0) / (194.0 - 18.0), 0.0, 1.0)
					var dm := _shaft_dims(ut)
					var k := lerpf(1.0, 0.84, maxf(0.0, (y - 194.0) / 15.5))
					x = cx + float(sx) * (dm.x * 0.5 - dm.z * 0.42 + 0.65) * k
					z = float(sz) * (dm.y * 0.5 - dm.z * 0.42 + 0.65) * k
				pts.append(Vector3(x, y, z))
				widths.append(lerpf(2.35, 1.25, u))
			var n_corner := Vector3(float(sx), 0.0, float(sz)).normalized()
			for j in segs:
				lm.beam("Exo", pts[j], pts[j + 1], widths[j], 1.15, n_corner, true)

	# 2) Mirrored weaving inner exoskeleton rib pairs on all 4 faces (+X, -X, +Z, -Z)
	# Each pair rises from wide podium legs, converges to kiss at y ~ 128 m, splits into an
	# X-weave & teardrop frame around the upper residential & aquatic crown levels!
	var faces := [
		[Vector3(1.0, 0.0, 0.0), Vector3(0.0, 0.0, 1.0), true],
		[Vector3(-1.0, 0.0, 0.0), Vector3(0.0, 0.0, 1.0), true],
		[Vector3(0.0, 0.0, 1.0), Vector3(1.0, 0.0, 0.0), false],
		[Vector3(0.0, 0.0, -1.0), Vector3(1.0, 0.0, 0.0), false],
	]
	for f in faces:
		var out_n: Vector3 = f[0]
		var tang: Vector3 = f[1]
		var is_x: bool = f[2]
		var half_span_base := 7.6 if is_x else 8.8
		var half_corner := 9.2 if is_x else 11.4
		for side_s in [-1.0, 1.0]:
			var sgn: float = float(side_s)
			var chain := PackedVector3Array()
			var w_arr := PackedFloat32Array()
			for j in segs + 1:
				var u := float(j) / float(segs)
				var y := lerpf(0.0, 211.2, u)
				# Lateral offset weaves inward to kiss at u = 0.60 (y ~ 127 m), flares into crown teardrop, rejoins at top
				var lat: float
				if u < 0.60:
					var k0 := u / 0.60
					lat = lerpf(half_span_base * 0.72, 0.58, pow(k0, 1.35))
				elif u < 0.88:
					var k1 := (u - 0.60) / 0.28
					lat = lerpf(0.58, half_corner * 0.82, sin(k1 * PI * 0.5))
				else:
					var k2 := (u - 0.88) / 0.12
					lat = lerpf(half_corner * 0.82, 0.0, smoothstep(0.0, 1.0, k2))
				var face_d: float
				if y < 18.0:
					var up := y / 18.0
					var dm0 := _shaft_dims(0.0)
					var target_d := (dm0.x * 0.5 + 1.25) if is_x else (dm0.y * 0.5 + 1.05)
					var pod_d := (22.6 - cx * out_n.x) if is_x else 15.85
					face_d = lerpf(pod_d, target_d, smoothstep(0.0, 1.0, up))
				else:
					var ut := clampf((y - 18.0) / (194.0 - 18.0), 0.0, 1.0)
					var dm := _shaft_dims(ut)
					var k_top := lerpf(1.0, 0.83, maxf(0.0, (y - 194.0) / 17.2))
					var base_d := (dm.x * 0.5 + 1.20) if is_x else (dm.y * 0.5 + 1.02)
					face_d = base_d * k_top
				var pos := Vector3(cx, y, 0.0) + out_n * face_d + tang * (sgn * lat)
				chain.append(pos)
				w_arr.append(lerpf(2.25, 1.05, u))
			var beam_side := tang
			for j in segs:
				lm.beam("Exo", chain[j], chain[j + 1], w_arr[j], 0.92, beam_side, true)

			# Lower bifurcation strut from rib (y ~ 56 m) out to corner column (y ~ 96 m)
			var p_split := chain[6]
			var dm_br := _shaft_dims(0.44)
			var d_br := (dm_br.x * 0.5 + 0.5) if is_x else (dm_br.y * 0.5 + 0.4)
			var p_join := Vector3(cx, 96.0, 0.0) + out_n * d_br + tang * (sgn * half_corner * 0.94)
			lm.beam("Exo", p_split, p_join, 1.15, 0.80, beam_side, true)

			# Podium base parabolic portal tie arch at y = 17.8 m
			lm.beam("Exo", chain[2], Vector3(cx, 18.2, 0.0) + out_n * ((chain[2] - Vector3(cx, 0.0, 0.0)).dot(out_n)),
				1.25, 0.85, Vector3.UP, true)

static func _helipad(lm: LandmarkMesh) -> void:
	# Cantilevered circular rooftop helipad centred at (5.0, y = 214.5..216.0, 0.0)
	var hc := Vector3(5.0, 0.0, 0.0)
	lm.frustum("Exo", hc + Vector3(0.0, 210.0, 0.0), 6.8, 8.6, 4.4, 20)
	lm.frustum("Exo", hc + Vector3(0.0, 214.4, 0.0), 8.6, 11.8, 0.75, 24)
	lm.frustum("Helipad", hc + Vector3(0.0, 215.15, 0.0), 11.8, 11.7, 0.50, 24)

	# Crisp white "H" landing pad emblem & perimeter touch-down ring at y = 215.68 m
	var hy := 215.68
	for sx in [-1.0, 1.0]:
		lm.box("Exo", hc + Vector3(float(sx) * 2.4, hy, 0.0), Vector3(0.85, 0.08, 6.2), Basis(), 0.0)
	lm.box("Exo", hc + Vector3(0.0, hy, 0.0), Vector3(4.8, 0.08, 0.85), Basis(), 0.0)

	# Perimeter safety net ring & outriggers reaching exact HEIGHT_M = 216.0 m + marker lamps
	var seg := 20
	var r_in := 11.65
	var r_out := 13.05
	for i in seg:
		var a0 := TAU * float(i) / float(seg)
		var a1 := TAU * float(i + 1) / float(seg)
		var d0 := Vector3(cos(a0), 0.0, sin(a0))
		var d1 := Vector3(cos(a1), 0.0, sin(a1))
		var q0 := hc + d0 * r_out + Vector3(0.0, 215.94, 0.0)
		var q1 := hc + d1 * r_out + Vector3(0.0, 215.94, 0.0)
		lm.beam("DarkMetal", q0, q1, 0.12, 0.12, Vector3.UP)
		lm.beam("DarkMetal", hc + d0 * r_in + Vector3(0.0, 215.45, 0.0), q0, 0.14, 0.10, Vector3.UP)
		var b_mark := Basis(Vector3.UP, -a0)
		lm.box("Exo", hc + d0 * 9.4 + Vector3(0.0, hy, 0.0), Vector3(0.35, 0.07, 1.45), b_mark, 0.0)
		if i % 5 == 0:
			lm.box("CrownLamp", hc + d0 * 11.35 + Vector3(0.0, 215.74, 0.0), Vector3(0.28, 0.14, 0.28), Basis(), 0.0)
