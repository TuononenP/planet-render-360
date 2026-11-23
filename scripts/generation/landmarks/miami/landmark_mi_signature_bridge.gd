class_name LandmarkMiSignatureBridge
extends RefCounted

## I-395 Signature Bridge ("The Fountain") — Late-2026 Construction Reality MI-5C & MI-0.3
## Site: I-395 over Biscayne Blvd & NE 2nd Ave (25.784500, -80.190500, yaw_deg = -3.0).
## Designers: HDR / Donald MacDonald Architects (height_m = 100.6 m / 330 ft).
## Verified November 2026 state (docs/miami-landmark-sources.md §1 & §2):
##   - 4 of the 6 precast concrete arches are standing & closed (Arches 1, 2, 4, and 5), fanning
##     outward from the central Fountain spring-point pedestal (y = 0..11.5 m):
##       * Arch 4 (Center-East flagship span over Biscayne Blvd): exact top y = 100.60 m (330 ft)
##       * Arch 2 (West-Northwest span over NE 2nd Ave): top y = 86.0 m
##       * Arch 5 (East-Southeast span over Biscayne Blvd): top y = 74.0 m
##       * Arch 1 (West-Southwest span over NE 2nd Ave): top y = 64.0 m
##   - Arches 3 & 6 are represented strictly by their angled precast starter pier stubs at the
##     central Fountain hub and outer thrust-block pedestals (unclosed in late 2026).
##   - Elevated segmental concrete I-395 twin box-girder highway decks (y = 14.5..17.5 m, 248 m span
##     along X) carried on widely spaced hammerhead T-piers leaving NE 2nd Ave & Biscayne Blvd open,
##     linked to the 4 standing arches by dense harp/fan stay-cable arrays & night-lit white LED strips.

const HEIGHT_M := 100.6
const DECK_BOT_Y := 14.5
const DECK_TOP_Y := 17.5
const HALF_SPAN_X := 124.0

static func build(model: Node3D, _row: Dictionary = {}) -> void:
	var lm := LandmarkMesh.new()
	lm.use("ArchPrecast", LandmarkMaterials.pbr("render", "#F2F0E8", 3.5, 0.72))
	lm.use("JointConcrete", LandmarkMaterials.pbr("concrete", "#B8B5AE", 3.0))
	lm.use("DeckConcrete", LandmarkMaterials.pbr("concrete", "#CAC7BF", 4.0))
	lm.use("RoadAsphalt", LandmarkMaterials.pbr("asphalt", "#2B2E32", 4.0))
	lm.use("FountainStone", LandmarkMaterials.pbr("limestone", "#DFD9CE", 3.2))
	lm.use("Cable", LandmarkMaterials.paint("#CED5DD", 0.30, 0.76))
	lm.use("ArchLamp", LandmarkMaterials.lit("#EAF4FF", 1.15))

	_build_fountain_hub_and_starter_piers(lm)
	_build_twin_viaduct_decks(lm)

	# Build the 4 standing asymmetric parabolic precast arches + dense stay-cable fans:
	# [p0_hub, p1_outer, exact_top_y, t_apex, deck_z]
	_build_standing_arch(lm, Vector3(2.5, 9.2, -2.2), Vector3(126.0, 6.2, -19.0), HEIGHT_M, 0.46, -15.5)
	_build_standing_arch(lm, Vector3(-2.5, 9.2, -3.2), Vector3(-122.0, 6.2, -36.0), 86.0, 0.46, -15.5)
	_build_standing_arch(lm, Vector3(3.2, 9.2, 3.2), Vector3(116.0, 6.2, 38.0), 74.0, 0.46, 15.5)
	_build_standing_arch(lm, Vector3(-3.2, 9.2, 3.2), Vector3(-110.0, 6.2, 34.0), 64.0, 0.46, 15.5)

	lm.commit(model)

	var cool := Color(0.88, 0.94, 1.0)
	var ice := Color(0.76, 0.88, 1.0)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(18.0, 2.5, -28.0), Vector3(56.0, 72.0, -10.0), 115.0, 1.30, 58.0, cool],
		[Vector3(96.0, 2.5, 8.0), Vector3(62.0, 76.0, -11.0), 115.0, 1.25, 58.0, cool],
		[Vector3(-18.0, 2.5, -28.0), Vector3(-56.0, 62.0, -18.0), 108.0, 1.20, 58.0, ice],
		[Vector3(18.0, 2.5, 28.0), Vector3(54.0, 52.0, 20.0), 98.0, 1.15, 56.0, cool],
		[Vector3(-18.0, 2.5, 28.0), Vector3(-50.0, 46.0, 18.0), 92.0, 1.15, 56.0, ice],
		[Vector3(0.0, 2.0, 0.0), Vector3(0.0, 12.0, 0.0), 42.0, 1.10, 65.0, cool],
	])

static func _build_fountain_hub_and_starter_piers(lm: LandmarkMesh) -> void:
	# Central concrete Fountain spring-point pedestal (y = -0.35..11.5 m) between twin viaducts
	var base_poly := TowerSpec.plan("chamfer", 24.0, 20.0, 5.5, 0.0, 0.0)
	lm.poly_prism("FountainStone", base_poly, -0.35, 3.60)
	var mid_poly := TowerSpec.plan("chamfer", 18.4, 15.2, 4.2, 0.0, 0.0)
	lm.poly_prism("FountainStone", mid_poly, 3.60, 8.40)
	var cap_poly := TowerSpec.plan("chamfer", 14.2, 12.0, 3.4, 0.0, 0.0)
	lm.poly_prism("ArchPrecast", cap_poly, 8.40, 11.50)

	# Arches 3 & 6 (unclosed in Nov 2026): starter pier pedestals rising from central Fountain hub
	# + outer thrust-block abutments waiting for future segment erection (docs/miami-landmark-sources.md §1)
	var stub3_a := Vector3(-1.8, 8.2, -5.2)
	var stub3_b := Vector3(-15.5, 19.8, -22.5)
	lm.beam("ArchPrecast", stub3_a, stub3_b, 3.6, 3.9, Vector3(0.82, 0.0, -0.57), true)
	lm.beam("JointConcrete", stub3_b - (stub3_b - stub3_a).normalized() * 1.1, stub3_b,
		3.75, 4.05, Vector3(0.82, 0.0, -0.57), true)
	_build_abutment_pad(lm, Vector3(-96.0, 0.0, -48.0), Vector3(-1.0, 0.0, -0.45).normalized())

	var stub6_a := Vector3(1.8, 8.2, 5.2)
	var stub6_b := Vector3(15.5, 19.2, 22.5)
	lm.beam("ArchPrecast", stub6_a, stub6_b, 3.6, 3.9, Vector3(-0.82, 0.0, 0.57), true)
	lm.beam("JointConcrete", stub6_b - (stub6_b - stub6_a).normalized() * 1.1, stub6_b,
		3.75, 4.05, Vector3(-0.82, 0.0, 0.57), true)
	_build_abutment_pad(lm, Vector3(98.0, 0.0, 48.0), Vector3(1.0, 0.0, 0.45).normalized())

static func _build_abutment_pad(lm: LandmarkMesh, pos: Vector3, dir_xz: Vector3) -> void:
	var tang := Vector3(-dir_xz.z, 0.0, dir_xz.x)
	var b := Basis(dir_xz, Vector3.UP, tang)
	lm.box("FountainStone", Vector3(pos.x, 2.225, pos.z), Vector3(12.4, 5.15, 7.6), b, 0.04)
	lm.box("JointConcrete", Vector3(pos.x, 5.65, pos.z) - dir_xz * 1.2, Vector3(8.6, 2.2, 5.8), b, 0.03)

static func _build_twin_viaduct_decks(lm: LandmarkMesh) -> void:
	# Twin elevated segmental box-girder highway decks (Westbound z = -15.5 m, Eastbound z = +15.5 m)
	# Span = 248.0 m along X (y = 14.5..17.5 m), leaving NE 2nd Ave (x = -92..-48) & Biscayne Blvd
	# (x = +48..+92) 100% open underneath!
	var span_x := HALF_SPAN_X * 2.0
	var deck_w := 16.8
	for sz: float in [-1.0, 1.0]:
		var dz := sz * 15.5
		# Trapezoidal segmental concrete box-girder spine (y = 14.5..17.0 m) + cantilevered deck slab (17.0..17.5 m)
		lm.box("DeckConcrete", Vector3(0.0, 15.75, dz), Vector3(span_x, 2.50, 11.4), Basis(), 0.04)
		lm.box("DeckConcrete", Vector3(0.0, 17.25, dz), Vector3(span_x, 0.50, deck_w), Basis(), 0.02)
		lm.box("RoadAsphalt", Vector3(0.0, 17.53, dz), Vector3(span_x - 0.4, 0.08, deck_w - 1.4), Basis(), 0.0)
		lm.box("ArchLamp", Vector3(0.0, 14.47, dz), Vector3(span_x - 4.0, 0.08, 0.45), Basis(), 0.0)

		# Open-post concrete safety rail parapets along both deck edges (matching front.jpg & side.jpg!)
		for edge_s: float in [-1.0, 1.0]:
			var rz := dz + edge_s * (deck_w * 0.5 - 0.28)
			lm.box("DeckConcrete", Vector3(0.0, 17.72, rz), Vector3(span_x, 0.44, 0.46), Basis(), 0.0)
			lm.box("DeckConcrete", Vector3(0.0, 18.48, rz), Vector3(span_x, 0.24, 0.48), Basis(), 0.0)
			for p_idx: int in 32:
				var px := -HALF_SPAN_X + 3.8 + float(p_idx) * ((span_x - 7.6) / 31.0)
				lm.box("DeckConcrete", Vector3(px, 18.15, rz), Vector3(0.65, 0.46, 0.44), Basis(), 0.0)

		# Widely spaced precast hammerhead T-piers keeping cross-streets completely unobstructed
		for px: float in [-112.0, -44.0, 44.0, 112.0]:
			lm.box("FountainStone", Vector3(px, 0.325, dz), Vector3(4.6, 1.35, 5.2), Basis(), 0.03)
			lm.box("JointConcrete", Vector3(px, 6.25, dz), Vector3(2.8, 10.5, 3.4), Basis(), 0.04)
			# Flared hammerhead pier cap (visible in front.jpg foreground!)
			lm.box("DeckConcrete", Vector3(px, 13.0, dz), Vector3(3.8, 3.0, 12.2), Basis(), 0.04)

static func _arch_center_y(t: float, y0: float, y1: float, y_max: float, t_apex: float) -> float:
	if t <= t_apex:
		var u := (t_apex - t) / maxf(t_apex, 0.001)
		return y_max - (y_max - y0) * u * u
	var u2 := (t - t_apex) / maxf(1.0 - t_apex, 0.001)
	return y_max - (y_max - y1) * u2 * u2

static func _build_standing_arch(lm: LandmarkMesh, p0: Vector3, p1: Vector3, top_h: float,
		t_apex: float, deck_z: float) -> void:
	# Grounded outer thrust-block abutment pedestal
	var plan_vec := Vector3(p1.x - p0.x, 0.0, p1.z - p0.z)
	var plan_dir := plan_vec.normalized()
	var side_n := Vector3(-plan_dir.z, 0.0, plan_dir.x)
	_build_abutment_pad(lm, Vector3(p1.x, 0.0, p1.z), plan_dir)

	# Segmental white precast concrete box-section arch rib whose crown top hits exact `top_h`:
	# Using segs = 26 and i_apex = 12 (t_apex = 12/26 ≈ 0.4615) places a ring vertex right at the crown!
	var segs := 26
	var i_apex := 12
	var t_ap := float(i_apex) / float(segs)
	var crown_h := 3.20
	var y_max := top_h - crown_h * 0.5
	var centers := PackedVector3Array()
	var ups := PackedVector3Array()
	var half_hs := PackedFloat32Array()
	var half_ws := PackedFloat32Array()

	for i: int in segs + 1:
		var t := float(i) / float(segs)
		var yc := _arch_center_y(t, p0.y, p1.y, y_max, t_ap)
		# Slight graceful outward lateral bow in plan
		var bow := sin(t * PI) * 2.4 * (1.0 if p1.z >= 0.0 else -1.0)
		var c := Vector3(lerpf(p0.x, p1.x, t), yc, lerpf(p0.z, p1.z, t)) + side_n * bow
		centers.append(c)
		var rib_h := lerpf(4.10, crown_h, sin(t * PI))
		var rib_w := lerpf(3.70, 3.00, sin(t * PI))
		half_hs.append(rib_h * 0.5)
		half_ws.append(rib_w * 0.5)

	for i: int in segs + 1:
		if i == i_apex:
			# Horizontal tangent at crown -> exact vertical normal so top vertex lands at exact `top_h`!
			ups.append(Vector3.UP)
		else:
			var prev_c: Vector3 = centers[maxi(i - 1, 0)]
			var next_c: Vector3 = centers[mini(i + 1, segs)]
			var tang := (next_c - prev_c).normalized()
			var up_v := side_n.cross(tang).normalized()
			if up_v.y < 0.0:
				up_v = -up_v
			ups.append(up_v)

	# Loft seamless 4-sided precast box arch + segmental joint collars + recessed night LED strips
	for i: int in segs:
		var c0: Vector3 = centers[i]
		var c1: Vector3 = centers[i + 1]
		var u0: Vector3 = ups[i] * half_hs[i]
		var u1: Vector3 = ups[i + 1] * half_hs[i + 1]
		var w0: Vector3 = side_n * half_ws[i]
		var w1: Vector3 = side_n * half_ws[i + 1]
		var key := "JointConcrete" if (i == i_apex or i % 5 == 2) else "ArchPrecast"

		lm.quad(key, c0 - w0 + u0, c0 + w0 + u0, c1 + w1 + u1, c1 - w1 + u1, (ups[i] + ups[i + 1]).normalized())
		lm.quad(key, c0 + w0 - u0, c0 - w0 - u0, c1 - w1 - u1, c1 + w1 - u1, -(ups[i] + ups[i + 1]).normalized())
		lm.quad(key, c0 + w0 + u0, c0 + w0 - u0, c1 + w1 - u1, c1 + w1 + u1, side_n)
		lm.quad(key, c0 - w0 - u0, c0 - w0 + u0, c1 - w1 + u1, c1 - w1 - u1, -side_n)

		# Signature night-lit white LED architectural strip along both lower soffit arrises
		for sg: float in [-0.78, 0.78]:
			var l0 := c0 + side_n * (half_ws[i] * sg) - u0 * 1.03
			var l1 := c1 + side_n * (half_ws[i + 1] * sg) - u1 * 1.03
			lm.beam("ArchLamp", l0, l1, 0.22, 0.14, side_n)

	# Dense harp/fan stay-cable curtain connecting the standing arch rib down to the I-395 viaduct deck
	var cables := 18
	var sign_x := 1.0 if p1.x >= 0.0 else -1.0
	var deck_edge_z := deck_z + (8.1 if p1.z >= 0.0 else -8.1)
	for k: int in cables:
		var frac := float(k) / float(cables - 1)
		var t_cab := lerpf(0.16, 0.86, frac)
		var f_idx := t_cab * float(segs)
		var idx0 := clampi(int(floor(f_idx)), 0, segs - 1)
		var alpha := f_idx - float(idx0)
		var arch_pt: Vector3 = centers[idx0].lerp(centers[idx0 + 1], alpha)
		var soffit_off: float = lerpf(half_hs[idx0], half_hs[idx0 + 1], alpha)
		var upper := arch_pt - Vector3(0.0, soffit_off * 0.85, 0.0)
		if upper.y <= DECK_TOP_Y + 2.5:
			continue
		var deck_x := sign_x * lerpf(16.0, 114.0, frac)
		var lower := Vector3(deck_x, DECK_TOP_Y + 0.35, deck_edge_z)
		lm.beam("Cable", upper, lower, 0.13, 0.13)
		lm.box("JointConcrete", lower, Vector3(0.55, 0.65, 0.55), Basis(), 0.0)
