class_name LandmarkMiFontainebleau
extends RefCounted

## Fontainebleau Miami Beach — Mid-Beach MI-4D
## Site: 4441 Collins Ave, OSM way 447042031 (25.817904, -80.122330, yaw_deg = 7.6).
## Architect: Morris Lapidus (1954 Chateau Building) + Nichols Brosch Wurst Wolfe (Trésor & Sorrento).
## Measured envelope (160.6 x 217.9 m; +X East/Atlantic Ocean, -X West/Collins Ave, -Z North, +Z South):
##   - Chateau Building (y = 0..54.0 m): signature sweeping 17-storey white curved crescent slab
##     bowing convex toward North (-Z) and embracing the SE lagoon pool on its concave inner curve,
##     complete with aqua glass bands, curved balcony ribbons, north elevator spine & MiMo roof cupola.
##   - Trésor Tower (y = 0..110.0 m): 37-storey stepped white & aqua-glass luxury suite tower on the
##     west/north-west Collins Ave side, crowned by an elliptical penthouse drum and vertical silver
##     architectural fin pillars reaching exact y = 110.0 m.
##   - Sorrento Tower (y = 0..64.0 m): 18-storey white oceanfront wing tower on the south side (+Z)
##     with wrap-around balcony slabs and sloped MiMo rooftop clerestory screen.
##   - Oceanfront Lagoon Pool Oasis: Lapidus bow-tie patterned terrace, freeform/bow-tie turquoise
##     pool_water lagoon with island spas, white poolside cabanas, arched porte-cochère & royal palms.

const HEIGHT_M := 110.0
const ARC_CENTER := Vector2(-16.0, -18.0)
const ARC_R_IN := 58.5
const ARC_R_OUT := 75.0
const ARC_A0 := -0.24
const ARC_A1 := -2.18

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("WhiteStucco", LandmarkMaterials.pbr("render", "#F4F3EE", 3.6))
	lm.use("Travertine", LandmarkMaterials.pbr("limestone", "#E5DED0", 3.2))
	lm.use("BowtieDark", LandmarkMaterials.pbr("slate", "#2E343B", 2.4))
	lm.use("AquaGlass", LandmarkMaterials.glass("#1E5C6A"))
	lm.use("PoolWater", LandmarkMaterials.pool_water("#18BBD0", 0.07))
	lm.use("CrownMetal", LandmarkMaterials.pbr("sheet_metal", "#BAC2CA", 2.5, 0.34, 0.45))
	lm.use("PalmTrunk", LandmarkMaterials.pbr("concrete", "#A6A096", 2.0))
	lm.use("PalmFrond", LandmarkMaterials.pbr("grass", "#3B7A3A", 2.0))
	lm.use("NightLit", LandmarkMaterials.lit("#8CEBFF", 0.85))

	_build_terrace_and_bowtie_paving(lm)
	_build_chateau_curved_slab(lm)
	_build_porte_cochere_and_rotunda(lm)
	_build_tresor_tower(lm)
	_build_sorrento_tower(lm)
	_build_lagoon_pool_and_cabanas(lm)
	lm.commit(model)

	var warm := Color(1.0, 0.90, 0.74)
	var aqua := Color(0.38, 0.88, 1.0)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(18.0, 2.2, 8.0), Vector3(-14.0, 32.0, -76.0), 95.0, 1.20, 62.0, warm],
		[Vector3(-22.0, 2.2, -112.0), Vector3(-16.0, 30.0, -86.0), 72.0, 1.15, 58.0, warm],
		[Vector3(-72.0, 3.0, 12.0), Vector3(-46.0, 68.0, 8.0), 98.0, 1.25, 56.0, aqua],
		[Vector3(-12.0, 2.5, 16.0), Vector3(-46.0, 74.0, 8.0), 96.0, 1.15, 54.0, warm],
		[Vector3(24.0, 2.2, 34.0), Vector3(-4.0, 38.0, 68.0), 74.0, 1.10, 54.0, warm],
		[Vector3(38.0, 2.0, 18.0), Vector3(24.0, 1.4, 18.0), 48.0, 0.95, 65.0, aqua],
	])

static func _build_terrace_and_bowtie_paving(lm: LandmarkMesh) -> void:
	# Resort ground plinth (154 x 208 m, y = -0.35..1.20 m) keeping foundation >= -0.35 m
	var campus := TowerSpec.plan("round", 154.0, 208.0, 12.0, 0.0, 0.0)
	lm.poly_prism("Travertine", campus, -0.35, 1.20)
	# Morris Lapidus signature black-and-white bow-tie geometric tile inlays along the grand promenade
	for ix: int in 6:
		for iz: int in 9:
			var bx := -14.0 + float(ix) * 6.8
			var bz := -32.0 + float(iz) * 7.2
			var c := Vector3(bx, 1.22, bz)
			lm.tri("BowtieDark", c, c + Vector3(-1.8, 0.0, -0.95), c + Vector3(-1.8, 0.0, 0.95),
				Vector3.UP, Vector3.UP, Vector3.UP, Vector2.ZERO, Vector2(1.8, 0.0), Vector2(1.8, 1.9))
			lm.tri("BowtieDark", c, c + Vector3(1.8, 0.0, 0.95), c + Vector3(1.8, 0.0, -0.95),
				Vector3.UP, Vector3.UP, Vector3.UP, Vector2.ZERO, Vector2(1.8, 1.9), Vector2(1.8, 0.0))

static func _build_chateau_curved_slab(lm: LandmarkMesh) -> void:
	# Sweeping 17-storey Morris Lapidus Chateau Building (y = 1.2..50.6 m + MiMo crown to 54.0 m)
	var segs := 28
	var y_bot := 1.20
	var y_top := 50.60
	var in_glass: Array = []
	var out_glass: Array = []
	for iy: int in 2:
		var yv := y_bot if iy == 0 else y_top
		var r_in_row := PackedVector3Array()
		var r_out_row := PackedVector3Array()
		for i: int in segs + 1:
			var a := lerpf(ARC_A0, ARC_A1, float(i) / float(segs))
			var dir := Vector2(cos(a), sin(a))
			var p_in := ARC_CENTER + dir * (ARC_R_IN + 0.35)
			var p_out := ARC_CENTER + dir * (ARC_R_OUT - 0.35)
			r_in_row.append(Vector3(p_in.x, yv, p_in.y))
			r_out_row.append(Vector3(p_out.x, yv, p_out.y))
		in_glass.append(r_in_row)
		out_glass.append(r_out_row)
	# Concave inner curtain faces toward ARC_CENTER; convex outer curtain faces away from ARC_CENTER
	var hint_pt := Vector3(ARC_CENTER.x, 26.0, ARC_CENTER.y)
	lm.grid("AquaGlass", out_glass, hint_pt, true)
	var in_rev: Array = [in_glass[1], in_glass[0]]
	lm.grid("AquaGlass", in_rev, Vector3(0.0, -1.0, 0.0))
	# Ensure double-sided / inward-facing normal on the concave pool-facing arc
	var cap_poly := PackedVector2Array()
	for i: int in segs + 1:
		var a := lerpf(ARC_A0, ARC_A1, float(i) / float(segs))
		cap_poly.append(ARC_CENTER + Vector2(cos(a), sin(a)) * ARC_R_OUT)
	for i: int in segs + 1:
		var a := lerpf(ARC_A1, ARC_A0, float(i) / float(segs))
		cap_poly.append(ARC_CENTER + Vector2(cos(a), sin(a)) * ARC_R_IN)
	# Ground lobby solid podium & top roof slab
	lm.poly_prism("WhiteStucco", cap_poly, 1.20, 5.40)
	lm.poly_prism("WhiteStucco", cap_poly, 49.40, 50.80)

	# Concave inner wall quads with explicit inward-toward-pool normals + 15 horizontal spandrel ribbons
	for i: int in segs:
		var a0 := lerpf(ARC_A0, ARC_A1, float(i) / float(segs))
		var a1 := lerpf(ARC_A0, ARC_A1, float(i + 1) / float(segs))
		var d0 := Vector2(cos(a0), sin(a0))
		var d1 := Vector2(cos(a1), sin(a1))
		var p0 := ARC_CENTER + d0 * (ARC_R_IN + 0.30)
		var p1 := ARC_CENTER + d1 * (ARC_R_IN + 0.30)
		var n_in := -Vector3((d0.x + d1.x) * 0.5, 0.0, (d0.y + d1.y) * 0.5).normalized()
		lm.quad("AquaGlass", Vector3(p0.x, 5.4, p0.y), Vector3(p1.x, 5.4, p1.y),
			Vector3(p1.x, 49.4, p1.y), Vector3(p0.x, 49.4, p0.y), n_in)

	# 15 horizontal white spandrel & wrap-around balcony bands sweeping along the Chateau arc
	var band_poly := PackedVector2Array()
	for i: int in segs + 1:
		var a := lerpf(ARC_A0, ARC_A1, float(i) / float(segs))
		band_poly.append(ARC_CENTER + Vector2(cos(a), sin(a)) * (ARC_R_OUT + 0.65))
	for i: int in segs + 1:
		var a := lerpf(ARC_A1, ARC_A0, float(i) / float(segs))
		band_poly.append(ARC_CENTER + Vector2(cos(a), sin(a)) * (ARC_R_IN - 0.85))
	for fl: int in 15:
		var sy := 5.40 + float(fl + 1) * 2.92
		lm.poly_prism("WhiteStucco", band_poly, sy - 0.82, sy)

	# Solid white monumental end-wall piers (seen at both ends of Chateau in aerial.jpg)
	for end_a: float in [ARC_A0, ARC_A1]:
		var dir := Vector2(cos(end_a), sin(end_a))
		var tang := Vector2(-dir.y, dir.x)
		var mid := ARC_CENTER + dir * ((ARC_R_IN + ARC_R_OUT) * 0.5)
		var b := Basis(Vector3(dir.x, 0.0, dir.y), Vector3.UP, Vector3(tang.x, 0.0, tang.y))
		lm.box("WhiteStucco", Vector3(mid.x, 27.2, mid.y), Vector3(17.2, 52.0, 5.4), b, 0.04)

	# Central-north projecting white elevator/service tower spine & Lapidus MiMo rooftop cupola (to 54.0 m)
	var sp_a := -1.36
	var sp_dir := Vector2(cos(sp_a), sin(sp_a))
	var sp_tang := Vector2(-sp_dir.y, sp_dir.x)
	var sp_pos := ARC_CENTER + sp_dir * (ARC_R_OUT + 2.2)
	var sp_basis := Basis(Vector3(sp_tang.x, 0.0, sp_tang.y), Vector3.UP, Vector3(sp_dir.x, 0.0, sp_dir.y))
	lm.box("WhiteStucco", Vector3(sp_pos.x, 27.6, sp_pos.y), Vector3(11.5, 52.8, 7.6), sp_basis, 0.04)
	lm.box("AquaGlass", Vector3(sp_pos.x, 27.2, sp_pos.y) + Vector3(sp_tang.x * 4.2, 0.0, sp_tang.y * 4.2),
		Vector3(2.4, 46.5, 7.8), sp_basis, 0.0)
	# Lapidus MiMo curved penthouse screen & lit belvedere lantern (y = 50.8..54.0 m)
	var cup_pos := ARC_CENTER + sp_dir * ((ARC_R_IN + ARC_R_OUT) * 0.5)
	lm.lathe("WhiteStucco", Vector3(cup_pos.x, 50.8, cup_pos.y), PackedVector2Array([
		Vector2(8.6, 0.0), Vector2(8.6, 2.2), Vector2(6.2, 2.4), Vector2(6.0, 3.2), Vector2(0.0, 3.2)]), 18, 1.5, 0.85)
	lm.lathe("NightLit", Vector3(cup_pos.x, 51.2, cup_pos.y), PackedVector2Array([
		Vector2(7.8, 0.0), Vector2(7.8, 1.4)]), 18, 1.5, 0.85, 0.0, true, false)

static func _build_porte_cochere_and_rotunda(lm: LandmarkMesh) -> void:
	# Sweeping white MiMo arrival porte-cochère on NW driveway (quarter.jpg) + LIV nightclub rotunda (aerial.jpg)
	var pc_c := Vector3(-52.0, 5.8, -48.0)
	var pc_b := Basis(Vector3(0.76, 0.0, -0.65).normalized(), Vector3.UP, Vector3(0.65, 0.0, 0.76).normalized())
	lm.box("WhiteStucco", pc_c, Vector3(30.0, 1.35, 11.0), pc_b, 0.04)
	for sx: float in [-12.5, -4.2, 4.2, 12.5]:
		for sz: float in [-4.4, 4.4]:
			var col := pc_c + pc_b.x * sx + pc_b.z * sz
			lm.box("WhiteStucco", Vector3(col.x, 3.2, col.z), Vector3(0.95, 4.0, 0.95), pc_b, 0.02)
	# Circular LIV Nightclub & conference dome pavilion nestled between Chateau and Trésor (aerial.jpg)
	lm.frustum("WhiteStucco", Vector3(-42.0, 1.2, -24.0), 14.2, 13.8, 9.2, 24)
	lm.lathe("Travertine", Vector3(-42.0, 10.4, -24.0), PackedVector2Array([
		Vector2(13.2, 0.0), Vector2(10.5, 1.6), Vector2(0.0, 2.2)]), 24)

static func _build_tresor_tower(lm: LandmarkMesh) -> void:
	# 37-storey Trésor Tower on the west/north-west side (cx = -46.0, cz = 10.0) rising to exact 110.0 m
	var cx := -46.0
	var cz := 10.0
	# 4-storey curved-corner white podium garage & lobby base (y = 1.2..14.4 m)
	var pod := TowerSpec.plan("round", 32.0, 56.0, 8.0, cx, cz)
	lm.poly_prism("WhiteStucco", pod, 1.20, 14.40)
	for py: float in [4.6, 8.2, 11.6]:
		lm.box("AquaGlass", Vector3(cx, py, cz), Vector3(32.2, 1.7, 42.0), Basis(), 0.0)

	# Main 31-storey white & aqua-glass luxury tower shaft (y = 14.4..98.4 m, 28 balcony tiers)
	var core := TowerSpec.plan("round", 20.4, 45.0, 8.5, cx, cz)
	lm.poly_prism("AquaGlass", core, 14.40, 98.40)
	LandmarkMiKit.balcony_slab_stack(lm, "WhiteStucco", "", core, 14.40, 28, 3.0, 1.35, 0.34, 0.0)
	# Vertical white shear-wall piers framing the tower's broad faces
	for sz: float in [-13.5, 0.0, 13.5]:
		lm.box("WhiteStucco", Vector3(cx, 56.4, cz + sz), Vector3(22.8, 84.0, 1.45), Basis(), 0.02)

	# Stepped upper penthouse tier (y = 98.4..103.4 m) & elliptical crown drum (y = 103.4..105.6 m)
	var pent := TowerSpec.plan("round", 17.2, 36.0, 7.5, cx, cz - 2.5)
	lm.poly_prism("WhiteStucco", pent, 98.40, 103.40)
	lm.box("AquaGlass", Vector3(cx, 100.8, cz - 2.5), Vector3(17.5, 2.8, 24.0), Basis(), 0.0)
	var drum := TowerSpec.plan("ellipse", 13.6, 21.0, 20.0, cx, cz - 6.5)
	lm.poly_prism("WhiteStucco", drum, 103.40, 105.60)
	lm.poly_prism("NightLit", TowerSpec.plan("ellipse", 12.2, 19.2, 20.0, cx, cz - 6.5), 105.60, 106.40)

	# Signature ring of 10 vertical silver-grey architectural crown fin pillars reaching exact HEIGHT_M = 110.0 m
	for k: int in 10:
		var a := TAU * float(k) / 10.0
		var fx := cx + cos(a) * 5.8
		var fz := (cz - 6.5) + sin(a) * 9.2
		lm.box("CrownMetal", Vector3(fx, 107.80, fz), Vector3(0.78, 4.40, 1.15), Basis(), 0.0)

static func _build_sorrento_tower(lm: LandmarkMesh) -> void:
	# 18-storey Sorrento Tower on the south oceanfront side (cx = -2.0, cz = 68.0, top = 64.0 m)
	var cx := -2.0
	var cz := 68.0
	var pod := TowerSpec.plan("round", 50.0, 23.0, 5.5, cx, cz)
	lm.poly_prism("WhiteStucco", pod, 1.20, 8.80)
	var core := TowerSpec.plan("round", 46.0, 18.6, 5.0, cx, cz)
	lm.poly_prism("AquaGlass", core, 8.80, 59.80)
	LandmarkMiKit.balcony_slab_stack(lm, "WhiteStucco", "", core, 8.80, 17, 3.0, 1.25, 0.32, 0.0)
	for sx: float in [-14.0, 0.0, 14.0]:
		lm.box("WhiteStucco", Vector3(cx + sx, 34.3, cz), Vector3(1.35, 51.0, 20.8), Basis(), 0.02)
	# Sloped MiMo white clerestory penthouse fin rising to 64.0 m (visible center-back in aerial.jpg)
	lm.box("WhiteStucco", Vector3(cx + 3.0, 61.3, cz), Vector3(28.0, 3.0, 12.0), Basis(), 0.03)
	var tilt := Basis(Vector3.FORWARD, deg_to_rad(6.5))
	lm.box("WhiteStucco", Vector3(cx + 3.0, 62.9, cz), Vector3(26.0, 1.4, 12.4), tilt, 0.02)
	lm.box("AquaGlass", Vector3(cx + 3.0, 61.6, cz), Vector3(24.0, 2.1, 12.5), Basis(), 0.0)

static func _build_lagoon_pool_and_cabanas(lm: LandmarkMesh) -> void:
	# Iconic bow-tie / freeform turquoise lagoon pool (x = +2..+48 m, z = -14..+46 m)
	var pool := PackedVector2Array([
		Vector2(8.0, -14.0), Vector2(34.0, -16.0), Vector2(47.0, -4.0),
		Vector2(41.0, 14.0), Vector2(48.0, 32.0), Vector2(36.0, 46.0),
		Vector2(14.0, 44.0), Vector2(6.0, 28.0), Vector2(13.0, 13.0), Vector2(3.0, -2.0),
	])
	var rim := LandmarkMiKit._offset_poly(pool, 1.35)
	lm.poly_prism("WhiteStucco", rim, 1.20, 1.46)
	lm.poly_prism("PoolWater", pool, 1.24, 1.50)
	# Circular whirlpool spa islands & Arkadia adult pool (seen in front.jpg)
	for spa: Vector3 in [Vector3(13.5, 1.20, 14.0), Vector3(39.0, 1.20, 15.5), Vector3(54.0, 1.20, 16.0)]:
		var r_spa := 3.6 if spa.x < 50.0 else 7.5
		lm.frustum("WhiteStucco", spa, r_spa + 0.65, r_spa + 0.55, 0.42, 18)
		lm.disc("PoolWater", spa + Vector3(0.0, 0.44, 0.0), Vector3.UP, r_spa, 18)

	# Crisp white square-hipped poolside cabanas (front.jpg foreground) & oceanfront bar pavilion
	for k: int in 8:
		var cz := -10.0 + float(k) * 7.2
		var cpos := Vector3(-3.5, 1.20, cz)
		lm.box("WhiteStucco", cpos + Vector3(0.0, 1.55, 0.0), Vector3(4.2, 3.1, 4.2), Basis(), 0.02)
		lm.box("BowtieDark", cpos + Vector3(0.45, 1.45, 0.0), Vector3(3.4, 2.5, 3.5), Basis(), 0.0)
		lm.spire("WhiteStucco", cpos + Vector3(0.0, 3.10, 0.0), 2.35, 1.15, 0.08, 4)
	# Oceanfront Arkadia beach club pavilion on +X edge
	lm.box("WhiteStucco", Vector3(60.0, 3.2, 8.0), Vector3(11.0, 4.0, 28.0), Basis(), 0.03)
	lm.box("AquaGlass", Vector3(60.0, 3.0, 8.0), Vector3(11.2, 2.6, 24.0), Basis(), 0.0)

	# Groves of courtyard & oceanfront Royal Palms framing the pool oasis (front.jpg)
	var palms: Array[Vector3] = [
		Vector3(2.0, 1.2, -16.0), Vector3(2.5, 1.2, 0.0), Vector3(3.0, 1.2, 16.0),
		Vector3(2.5, 1.2, 32.0), Vector3(8.0, 1.2, 48.0), Vector3(26.0, 1.2, 50.0),
		Vector3(46.0, 1.2, 44.0), Vector3(52.0, 1.2, 28.0), Vector3(52.0, 1.2, -4.0),
		Vector3(42.0, 1.2, -20.0), Vector3(22.0, 1.2, -21.0), Vector3(66.0, 1.2, -18.0),
		Vector3(66.0, 1.2, 2.0), Vector3(66.0, 1.2, 22.0), Vector3(66.0, 1.2, 42.0),
		Vector3(-24.0, 1.2, -32.0), Vector3(-62.0, 1.2, -36.0), Vector3(-60.0, 1.2, -62.0),
	]
	for idx: int in palms.size():
		var h_p := 15.5 + float(idx % 4) * 1.4
		LandmarkMiKit.royal_palm(lm, "PalmTrunk", "PalmFrond", palms[idx], h_p, float(idx) * 0.9)
