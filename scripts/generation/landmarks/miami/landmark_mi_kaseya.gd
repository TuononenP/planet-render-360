class_name LandmarkMiKaseya
extends RefCounted

## Kaseya Center (formerly AmericanAirlines Arena) — Downtown Miami Bayfront MI-2A.2
## Site: 601 Biscayne Blvd, OSM way 25312625 (25.781381, -80.187863, yaw_deg 59.2).
## Architect: Arquitectonica & 360 Architecture (1999).
## Envelope & materials (Commons front/quarter/night, OSM LiDAR 48.8 m, footprint 136.9 x 147.7 m):
##   - Orientation at yaw_deg = 59.2: +Z/-X faces West onto Biscayne Blvd (Freedom Tower side),
##     -Z/+X faces East/NE onto Biscayne Bay and the PortMiami ship channel.
##   - Plinth (y = 0..4.5 m): stepped travertine/concrete waterfront plaza with wide grand stairs
##     toward Biscayne Blvd (+Z) and sweeping waterside dining terraces (-Z).
##   - Arena drum (y = 4.5..44.0 m): white elliptical concrete drum wrapped by Arquitectonica's
##     sweeping curved white fin shells rising to 47.6 m on the West/SE flanks.
##   - East bayfront lobe: 4-tier blue-green curtain-wall atrium, wrap-around white balcony slabs
##     and freestanding circular glass pavilion under a cantilevered white canopy.
##   - West Biscayne Blvd front (+Z): multi-storey glazed concourse + curved LED media-mesh screen
##     (lit #3CA8FF, energy 0.75) under a deep cantilevered white Brise-Soleil roof overhang.
##   - Rooftop mechanical plant ring & elliptical roof dome reaching exact y = 48.8 m.

const HEIGHT_M := 48.8

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("White", LandmarkMaterials.pbr("render", "#F2F1EC", 4.5))
	lm.use("Travertine", LandmarkMaterials.pbr("limestone", "#E2DAC9", 3.5))
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#CBC7BE", 4.0))
	lm.use("Glass", LandmarkMaterials.glass("#265260"))
	lm.use("Steel", LandmarkMaterials.paint("#DCE1E5", 0.42, 0.55))
	lm.use("Roof", LandmarkMaterials.pbr("roof_concrete", "#E7E6E0", 6.0))
	lm.use("LedMesh", LandmarkMaterials.lit("#3CA8FF", 0.75))
	lm.use("WarmLamp", LandmarkMaterials.lit("#FFBE68", 0.55))
	lm.use("PalmTrunk", LandmarkMaterials.pbr("concrete", "#B8B2A6", 2.0))
	lm.use("PalmFrond", LandmarkMaterials.pbr("grass", "#386B2E", 2.0))

	_build_plaza_plinth(lm)
	_build_arena_drum_and_shells(lm)
	_build_west_blvd_facade(lm)
	_build_east_bayfront_lobes(lm)
	_build_roof_and_crown(lm)
	lm.commit(model)

	var cool := Color(0.76, 0.88, 1.0)
	var warm := Color(1.0, 0.88, 0.68)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-32.0, 5.2, 68.0), Vector3(-8.0, 26.0, 44.0), 56.0, 1.15, 75.0, cool],
		[Vector3(32.0, 5.2, 68.0), Vector3(8.0, 26.0, 44.0), 56.0, 1.15, 75.0, cool],
		[Vector3(-58.0, 5.2, 0.0), Vector3(-38.0, 28.0, 0.0), 54.0, 1.0, 68.0, warm],
		[Vector3(58.0, 5.2, -18.0), Vector3(36.0, 26.0, -14.0), 54.0, 1.05, 68.0, warm],
		[Vector3(0.0, 5.2, -68.0), Vector3(0.0, 24.0, -42.0), 58.0, 1.10, 72.0, warm],
	])

static func _build_plaza_plinth(lm: LandmarkMesh) -> void:
	# Rounded stepped travertine & concrete podium filling the 136.9 x 147.7 m site (y = -0.35..4.5 m)
	var base_poly := TowerSpec.plan("round", 134.0, 144.0, 24.0, 0.0, 1.0)
	lm.poly_prism("Concrete", base_poly, -0.35, 1.6)
	var mid_poly := TowerSpec.plan("round", 126.0, 134.0, 22.0, 0.0, 0.0)
	lm.poly_prism("Travertine", mid_poly, 1.6, 3.1)
	var top_poly := TowerSpec.plan("round", 118.0, 124.0, 20.0, 0.0, -1.0)
	lm.poly_prism("Travertine", top_poly, 3.1, 4.5)

	# Wide ceremonial grand stairs facing Biscayne Blvd (+Z)
	for s in 9:
		var t := float(s) / 9.0
		var sy0 := t * 4.5
		var sy1 := (float(s + 1) / 9.0) * 4.5
		var z_front := lerpf(73.5, 60.5, t)
		var sw := lerpf(56.0, 46.0, t)
		lm.box("Travertine", Vector3(0.0, (sy0 + sy1) * 0.5, (z_front + 59.0) * 0.5),
			Vector3(sw, sy1 - sy0 + 0.04, z_front - 59.0), Basis(), 0.0)

	# Bayfront terrace stairs (-Z) & plaza royal palms along the Biscayne Blvd forecourt
	for s in 6:
		var sy := 0.75 * float(s + 1)
		lm.box("Travertine", Vector3(12.0, sy * 0.5, -63.0 + float(s) * 1.3),
			Vector3(38.0, sy, 2.2), Basis(), 0.0)
	for i in 6:
		var px := -35.0 + float(i) * 14.0
		LandmarkMiKit.royal_palm(lm, "PalmTrunk", "PalmFrond", Vector3(px, 1.6, 68.5), 14.5, float(i) * 0.9)

static func _build_arena_drum_and_shells(lm: LandmarkMesh) -> void:
	# Core elliptical glazed & concrete bowl (rx = 50 m, rz = 56 m, y = 4.5..39.5 m)
	var core_poly := TowerSpec.plan("ellipse", 98.0, 108.0, 32.0, 0.0, 0.0)
	lm.poly_prism("Glass", core_poly, 4.5, 36.5)
	for fl in [9.5, 15.0, 20.5, 26.0, 31.5]:
		lm.poly_prism("Travertine", TowerSpec.plan("ellipse", 99.0, 109.0, 32.0, 0.0, 0.0), fl - 0.35, fl + 0.35)
	lm.poly_prism("White", TowerSpec.plan("ellipse", 96.0, 106.0, 32.0, 0.0, 0.0), 36.5, 42.0)

	# Arquitectonica's signature sweeping curved white concrete outer shell walls:
	# Left/West-North shell sweeping from y = 39 m up to a 47.6 m prow fin (+Z/-X corner, see quarter.jpg)
	_curved_shell_wall(lm, -0.58 * PI, 0.36 * PI, 52.5, 58.5, 4.5, 38.5, 47.6, 2.6)
	# Right/South-West shell wrapping the opposite flank from +Z around +X (y = 4.5..41.5 m)
	_curved_shell_wall(lm, -0.08 * PI, 0.36 * PI, 52.0, 58.0, 4.5, 41.2, 36.5, 2.4, true)

static func _curved_shell_wall(lm: LandmarkMesh, a0: float, a1: float, rx: float, rz: float,
		y_base: float, h_start: float, h_end: float, thick: float, mirror_x: bool = false) -> void:
	var segs := 18
	for i in segs:
		var t0 := float(i) / float(segs)
		var t1 := float(i + 1) / float(segs)
		var tm := (t0 + t1) * 0.5
		var ang0 := lerpf(a0, a1, t0)
		var ang1 := lerpf(a0, a1, t1)
		var sx := -1.0 if mirror_x else 1.0
		var p0 := Vector2(sx * sin(ang0) * rx, cos(ang0) * rz)
		var p1 := Vector2(sx * sin(ang1) * rx, cos(ang1) * rz)
		var top_y := lerpf(h_start, h_end, pow(tm, 1.15))
		var edge := p1 - p0
		var seg_l := edge.length()
		var tang := edge / maxf(seg_l, 0.01)
		var out2 := Vector2(p0.x / (rx * rx), p0.y / (rz * rz)).normalized()
		var basis := Basis(Vector3(tang.x, 0.0, tang.y), Vector3.UP, Vector3(out2.x, 0.0, out2.y))
		var mid := (p0 + p1) * 0.5
		lm.box("White", Vector3(mid.x, (y_base + top_y) * 0.5, mid.y),
			Vector3(seg_l + 0.35, top_y - y_base, thick), basis, 0.04)
		# Horizontal slot ribbon cutouts near the prow (seen in aerial.jpg & quarter.jpg)
		if tm > 0.68 and i % 3 == 1:
			lm.box("Glass", Vector3(mid.x + out2.x * (thick * 0.48), top_y - 7.5, mid.y + out2.y * (thick * 0.48)),
				Vector3(seg_l * 0.88, 1.35, 0.30), basis, 0.0)

static func _build_west_blvd_facade(lm: LandmarkMesh) -> void:
	# Biscayne Blvd (+Z) grand glazed concourse grid + glowing curved LED media-mesh screen
	var segs := 12
	var rx := 49.8
	var rz := 56.2
	for i in segs:
		var t0 := -0.32 + 0.64 * (float(i) / float(segs))
		var t1 := -0.32 + 0.64 * (float(i + 1) / float(segs))
		var p0 := Vector2(sin(t0 * PI) * rx, cos(t0 * PI) * rz)
		var p1 := Vector2(sin(t1 * PI) * rx, cos(t1 * PI) * rz)
		var mid := (p0 + p1) * 0.5
		var seg_l := p0.distance_to(p1)
		var tang := (p1 - p0).normalized()
		var out2 := Vector2(mid.x / (rx * rx), mid.y / (rz * rz)).normalized()
		var basis := Basis(Vector3(tang.x, 0.0, tang.y), Vector3.UP, Vector3(out2.x, 0.0, out2.y))
		# Vertical travertine mullion piers framing the warm-lit concourse
		lm.box("Travertine", Vector3(p0.x, 20.5, p0.y), Vector3(0.85, 32.0, 1.2), basis, 0.0)
		lm.box("WarmLamp", Vector3(mid.x - out2.x * 0.8, 16.5, mid.y - out2.y * 0.8),
			Vector3(seg_l * 0.82, 20.0, 0.35), basis, 0.0)
		# Curved LED media-mesh screen across the central 8 bays (y = 14.5..32.5 m)
		if i >= 2 and i < 10:
			lm.box("LedMesh", Vector3(mid.x + out2.x * 0.95, 23.5, mid.y + out2.y * 0.95),
				Vector3(seg_l - 0.35, 17.5, 0.28), basis, 0.0)
			lm.box("Steel", Vector3(mid.x + out2.x * 0.82, 14.5, mid.y + out2.y * 0.82),
				Vector3(seg_l, 0.45, 0.55), basis, 0.0)
			lm.box("Steel", Vector3(mid.x + out2.x * 0.82, 32.5, mid.y + out2.y * 0.82),
				Vector3(seg_l, 0.45, 0.55), basis, 0.0)

static func _build_east_bayfront_lobes(lm: LandmarkMesh) -> void:
	# Sweeping East/Bayfront (-Z/+X) blue-green glass lobe, wrap-around balcony slabs & canopy (front.jpg)
	var lobe_poly := TowerSpec.plan("ellipse", 48.0, 34.0, 20.0, 18.0, -40.0)
	lm.poly_prism("Glass", lobe_poly, 4.5, 24.5)
	LandmarkMiKit.balcony_slab_stack(lm, "White", "Glass", lobe_poly, 4.5, 4, 4.8, 1.8, 0.32, 1.05)

	# Cylindrical bayfront glass rotunda + floating white gull-wing canopy & warm sandstone-toned pavilion
	var rot_c := Vector3(-16.0, 4.5, -46.0)
	lm.frustum("Glass", rot_c, 10.5, 10.5, 16.5, 20)
	for ry in [9.8, 15.0, 20.8]:
		lm.frustum("White", Vector3(rot_c.x, ry, rot_c.z), 11.1, 11.1, 0.42, 20)
	# Sweeping white open-air bayfront plaza canopy on slender steel columns
	var can_poly := TowerSpec.plan("round", 46.0, 22.0, 8.0, 8.0, -52.0)
	lm.poly_prism("White", can_poly, 17.2, 18.1)
	for cx in [-10.0, 2.0, 14.0, 26.0]:
		for cz in [-60.0, -45.0]:
			lm.frustum("Steel", Vector3(cx, 4.5, cz), 0.38, 0.34, 12.8, 10)
	# Angled warm travertine-clad waterfront practice/club wing on the NE flank (seen right side of front.jpg)
	var wing_b := Basis(Vector3.UP, -0.22)
	lm.box("Travertine", Vector3(42.0, 11.5, -34.0), Vector3(28.0, 14.0, 22.0), wing_b)
	lm.box("Glass", Vector3(55.8, 11.2, -31.0), Vector3(1.2, 11.5, 16.5), wing_b, 0.0)

static func _build_roof_and_crown(lm: LandmarkMesh) -> void:
	# Deep cantilevered white Brise-Soleil roof overhang around the arena perimeter (y = 41.8..43.4 m)
	var brim_outer := TowerSpec.plan("ellipse", 118.0, 128.0, 36.0, 0.0, 1.5)
	lm.poly_prism("White", brim_outer, 42.0, 43.2)
	# Radial steel Brise-Soleil outrigger struts under the cantilevered brow
	for i in 24:
		var a := TAU * float(i) / 24.0
		var p_in := Vector3(sin(a) * 48.0, 39.2, cos(a) * 53.0 + 1.0)
		var p_out := Vector3(sin(a) * 58.0, 42.1, cos(a) * 63.0 + 1.5)
		lm.beam("Steel", p_in, p_out, 0.42, 0.42)

	# Low-slope elliptical white arena roof dome (y = 43.2..47.4 m)
	lm.lathe("Roof", Vector3(0.0, 43.2, 0.0), PackedVector2Array([
		Vector2(49.0, 0.0), Vector2(42.0, 1.8), Vector2(30.0, 3.2),
		Vector2(16.0, 4.0), Vector2(0.0, 4.3)]), 28, 0.96, 1.06)

	# Rooftop elliptical mechanical plant screen ring reaching exact HEIGHT_M = 48.8 m
	var mech_outer := TowerSpec.plan("ellipse", 46.0, 52.0, 24.0, 0.0, 0.0)
	lm.poly_prism("Steel", mech_outer, 45.2, HEIGHT_M)
	lm.poly_prism("Concrete", TowerSpec.plan("ellipse", 42.0, 48.0, 24.0, 0.0, 0.0), 45.2, 48.3)
