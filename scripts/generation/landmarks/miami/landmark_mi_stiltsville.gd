class_name LandmarkMiStiltsville
extends RefCounted

## Stiltsville — Biscayne National Park / Biscayne Bay Safety Valve Flats (MI-10)
## Site: Shallow seagrass & sandbar flats south of Key Biscayne (25.650500, -80.181500, base: "sea").
## Historic vernacular maritime stilt community (1930s–1960s; 7 surviving houses preserved by NPS).
## Measured envelope & materials (Commons front/quarter/side, 160 x 140 m shoal cluster, H = 9.5 m):
##   - Sea-datum model (base: "sea", y = 0.0 m water surface): reinforced concrete & timber pilings
##     driven to y = -3.60 m seabed, rising to wraparound timber fishing decks at y = 3.1..3.6 m.
##   - Lower boat-landing catwalks (y = 0.85 m), mooring fender dolphins & wooden boarding stairs.
##   - All 7 surviving historic stilt houses across the flats:
##     1. Miami Springs Power Boat Club (centre, white clapboard + gable & lookout mast to exact 9.5 m)
##     2. A-Frame House (NW, steep triangular A-frame roof rising from deck to 8.7 m)
##     3. Baldwin, Sessions & Shaw House (NE, sky-blue clapboard, pink shutters, white porch — quarter.jpg)
##     4. Ellen / Mansard House (SW, warm orange walls, weathered grey mansard roof — front/side.jpg)
##     5. Bay Chateau / Hicks House (SE, pastel seafoam-mint clapboard, hipped shingle roof)
##     6. Jimmy Ellenburg House (far W, whitewashed bungalow & eastern fishing deck)
##     7. Leshaw House (S, cream cottage with hurricane skillion roof & solar navigation marker)

const HEIGHT_M := 9.5
const SEABED_Y := -3.6

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Piling", LandmarkMaterials.pbr("concrete", "#ACA89E", 2.4))
	lm.use("TimberDeck", LandmarkMaterials.pbr("wood", "#8F775A", 2.2))
	lm.use("WhiteWood", LandmarkMaterials.pbr("wood", "#ECE9E0", 2.2))
	lm.use("BlueWood", LandmarkMaterials.pbr("wood", "#4A79C8", 2.2))
	lm.use("CoralWood", LandmarkMaterials.pbr("wood", "#D96B2B", 2.2))
	lm.use("MintWood", LandmarkMaterials.pbr("wood", "#84BEAE", 2.2))
	lm.use("RoofShingle", LandmarkMaterials.pbr("slate", "#666C72", 2.0))
	lm.use("Glass", LandmarkMaterials.glass("#2A3D4A"))
	lm.use("Metal", LandmarkMaterials.paint("#C6CCD0", 0.42, 0.55))
	lm.use("NavLamp", LandmarkMaterials.lit("#FFE28A", 2.0))

	# 1. Miami Springs Power Boat Club — central anchor house reaching exact y = 9.50 m
	_build_boat_club_hero(lm, Vector3(0.0, 0.0, 0.0), 0.08)
	# 2. Iconic A-Frame Stilt House
	_build_aframe_house(lm, Vector3(-38.0, 0.0, -18.0), 0.28)
	# 3. Baldwin, Sessions & Shaw House (quarter.jpg: sky-blue cabin, coral shutters, white porch)
	_build_gable_stilt_house(lm, Vector3(36.0, 0.0, -22.0), -0.24, 12.6, 9.4, 3.4, 2.9, 1.9,
		"BlueWood", "CoralWood", true)
	# 4. Ellen / Mansard House (side.jpg & front.jpg: bright orange cabin, mansard overhang roof)
	_build_mansard_stilt_house(lm, Vector3(-30.0, 0.0, 30.0), 0.14, 14.2, 9.6, 3.3, "CoralWood", "WhiteWood")
	# 5. Bay Chateau / Hicks House (seafoam-mint hipped cottage)
	_build_hipped_stilt_house(lm, Vector3(40.0, 0.0, 26.0), -0.35, 11.8, 9.2, 3.3, "MintWood", "WhiteWood")
	# 6. Jimmy Ellenburg House (west shoal whitewashed fishing bungalow)
	_build_gable_stilt_house(lm, Vector3(-56.0, 0.0, 6.0), 0.20, 11.4, 8.6, 3.2, 2.7, 1.7,
		"WhiteWood", "BlueWood", false)
	# 7. Leshaw House (south channel low-slope cottage + channel marker piling)
	_build_hipped_stilt_house(lm, Vector3(8.0, 0.0, -44.0), -0.12, 11.0, 8.4, 3.1, "WhiteWood", "CoralWood")
	_build_channel_markers(lm)

	lm.commit(model)

	var warm := Color(1.0, 0.88, 0.64)
	model.set_meta(LandmarkLights.HALO_META, [
		[Vector3(0.0, 9.35, 0.0), 2.8, Color(1.0, 0.90, 0.65)],
		[Vector3(24.0, 4.65, -48.0), 2.6, Color(0.35, 1.0, 0.55)],
	])
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(0.0, 3.9, 9.5), Vector3(0.0, 7.2, 0.0), 55.0, 0.85, 28.0, warm],
		[Vector3(36.0, 3.7, -13.0), Vector3(36.0, 6.5, -22.0), 52.0, 0.75, 24.0, warm],
		[Vector3(-38.0, 3.6, -9.5), Vector3(-38.0, 6.8, -18.0), 52.0, 0.75, 24.0, warm],
		[Vector3(-30.0, 3.6, 39.0), Vector3(-30.0, 6.2, 30.0), 52.0, 0.75, 24.0, warm],
	])

static func _build_pilings_and_deck(lm: LandmarkMesh, orig: Vector3, b: Basis,
		dw: float, dl: float, deck_y: float, nx: int = 4, nz: int = 4, dock_side: float = 1.0) -> void:
	# Concrete/wood pilings into seabed (SEABED_Y = -3.6 m up to deck underside)
	for ix: int in nx:
		var lx := lerpf(-dw * 0.44, dw * 0.44, float(ix) / float(maxi(nx - 1, 1)))
		for iz: int in nz:
			var lz := lerpf(-dl * 0.44, dl * 0.44, float(iz) / float(maxi(nz - 1, 1)))
			var p := orig + b * Vector3(lx, 0.0, lz)
			lm.frustum("Piling", Vector3(p.x, SEABED_Y, p.z), 0.24, 0.21, deck_y - SEABED_Y - 0.15, 8)
		# Transverse timber stringer beam under deck row
		var s0 := orig + b * Vector3(lx, deck_y - 0.24, -dl * 0.48)
		var s1 := orig + b * Vector3(lx, deck_y - 0.24, dl * 0.48)
		lm.beam("TimberDeck", s0, s1, 0.24, 0.28, b.x)

	# Wraparound timber fishing deck slab + white wooden safety railings
	lm.box("TimberDeck", orig + b * Vector3(0.0, deck_y - 0.08, 0.0), Vector3(dw, 0.20, dl), b, 0.0)
	var hw := dw * 0.5 - 0.12
	var hl := dl * 0.5 - 0.12
	var corners: Array[Vector3] = [
		Vector3(-hw, 0.0, -hl), Vector3(hw, 0.0, -hl),
		Vector3(hw, 0.0, hl), Vector3(-hw, 0.0, hl),
	]
	for e: int in 4:
		var c0: Vector3 = corners[e]
		var c1: Vector3 = corners[(e + 1) % 4]
		for ry: float in [0.48, 0.96]:
			lm.beam("WhiteWood", orig + b * (c0 + Vector3(0.0, deck_y + ry, 0.0)),
				orig + b * (c1 + Vector3(0.0, deck_y + ry, 0.0)), 0.08, 0.08)
		var posts := 5
		for k: int in posts:
			var pt := c0.lerp(c1, float(k) / float(posts))
			lm.box("WhiteWood", orig + b * (pt + Vector3(0.0, deck_y + 0.52, 0.0)),
				Vector3(0.11, 1.04, 0.11), b, 0.0)

	# Lower timber boat-landing catwalk at y = 0.85 m + tall fender pilings + boarding stair
	var dz := dock_side * (dl * 0.5 + 2.2)
	lm.box("TimberDeck", orig + b * Vector3(0.0, 0.82, dz), Vector3(dw * 0.78, 0.18, 2.2), b, 0.0)
	for dx_f: float in [-0.36, -0.12, 0.12, 0.36]:
		var fp := orig + b * Vector3(dw * dx_f, 0.0, dz + dock_side * 1.15)
		lm.frustum("Piling", Vector3(fp.x, SEABED_Y, fp.z), 0.19, 0.17, 6.0, 8)
		var bp := orig + b * Vector3(dw * dx_f, 0.0, dz - dock_side * 0.95)
		lm.frustum("Piling", Vector3(bp.x, SEABED_Y, bp.z), 0.17, 0.16, 4.5, 8)
	# Angled timber boarding stair from lower dock (y = 0.90 m) up to main deck
	var st_a := orig + b * Vector3(-dw * 0.26, 0.90, dz - dock_side * 0.3)
	var st_b := orig + b * Vector3(dw * 0.08, deck_y, dock_side * (dl * 0.5 - 0.15))
	lm.beam("TimberDeck", st_a, st_b, 0.95, 0.18, b.z)
	lm.beam("WhiteWood", st_a + Vector3(0.0, 0.85, 0.0), st_b + Vector3(0.0, 0.85, 0.0), 0.07, 0.07)

static func _build_boat_club_hero(lm: LandmarkMesh, orig: Vector3, yaw: float) -> void:
	var b := Basis(Vector3.UP, yaw)
	var deck_y := 3.60
	_build_pilings_and_deck(lm, orig, b, 20.4, 15.2, deck_y, 5, 4, 1.0)

	# Main clubhouse cabin (14.6 x 10.2 m, y = 3.60..6.85 m) + covered porch posts
	lm.box("WhiteWood", orig + b * Vector3(0.0, deck_y + 1.62, -0.4), Vector3(14.6, 3.25, 10.2), b)
	var roof_b := b * Basis(Vector3.UP, PI * 0.5)
	lm.gable("RoofShingle", orig + b * Vector3(0.0, deck_y + 3.25, -0.4), 10.6, 15.2, 1.95, roof_b, 0.85, "WhiteWood")

	# Shaded porch corner columns supporting roof overhang
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			lm.box("WhiteWood", orig + b * Vector3(sx * 8.2, deck_y + 1.60, sz * 6.0),
				Vector3(0.16, 3.20, 0.16), b, 0.0)

	# Windows & storm shutters around clubhouse
	for wx: float in [-4.6, -1.5, 1.5, 4.6]:
		for sz: float in [-1.0, 1.0]:
			lm.box("Glass", orig + b * Vector3(wx, deck_y + 1.70, -0.4 + sz * 5.12),
				Vector3(1.25, 1.35, 0.14), b, 0.0)
			lm.box("BlueWood", orig + b * Vector3(wx + 0.85, deck_y + 1.70, -0.4 + sz * 5.16),
				Vector3(0.42, 1.38, 0.10), b, 0.0)

	# Rooftop lookout cupola & marine weather/beacon mast reaching exact HEIGHT_M = 9.50 m
	# Ridge is at 3.60 + 3.25 + 1.95 = 8.80 m; cupola straddles ridge (y = 8.15..9.05 m) + mast to 9.50 m
	lm.box("WhiteWood", orig + b * Vector3(0.0, 8.55, -0.4), Vector3(2.4, 0.90, 2.4), b)
	lm.spire("RoofShingle", orig + b * Vector3(0.0, 9.00, -0.4), 1.35, 0.36, 0.08, 4)
	var mast_xz := orig + b * Vector3(0.0, 0.0, -0.4)
	lm.beam("Metal", Vector3(mast_xz.x, 9.10, mast_xz.z), Vector3(mast_xz.x, HEIGHT_M, mast_xz.z),
		0.06, 0.06, Vector3.RIGHT, true)
	lm.frustum("NavLamp", Vector3(mast_xz.x, 9.26, mast_xz.z), 0.12, 0.12, 0.18, 8)

static func _build_aframe_house(lm: LandmarkMesh, orig: Vector3, yaw: float) -> void:
	# Iconic Stiltsville A-Frame House: steep triangular roof rising directly from deck to y = 8.75 m
	var b := Basis(Vector3.UP, yaw)
	var deck_y := 3.35
	_build_pilings_and_deck(lm, orig, b, 16.0, 12.6, deck_y, 4, 4, -1.0)
	lm.gable("RoofShingle", orig + b * Vector3(0.0, deck_y + 0.15, 0.0), 9.4, 11.2, 5.25, b, 0.45, "WhiteWood")
	for sz: float in [-1.0, 1.0]:
		lm.box("Glass", orig + b * Vector3(0.0, deck_y + 1.85, sz * 5.45), Vector3(4.2, 2.6, 0.22), b, 0.0)
		lm.box("Glass", orig + b * Vector3(0.0, deck_y + 3.75, sz * 5.45), Vector3(2.0, 1.2, 0.22), b, 0.0)

static func _build_gable_stilt_house(lm: LandmarkMesh, orig: Vector3, yaw: float,
		cw: float, cl: float, deck_y: float, wall_h: float, rise: float,
		wall_key: String, shutter_key: String, deep_porch: bool) -> void:
	var b := Basis(Vector3.UP, yaw)
	_build_pilings_and_deck(lm, orig, b, cw + 5.2, cl + 4.8, deck_y, 4, 4, 1.0)
	var z_off := -1.1 if deep_porch else 0.0
	lm.box(wall_key, orig + b * Vector3(0.0, deck_y + wall_h * 0.5, z_off), Vector3(cw, wall_h, cl), b)
	var roof_l := cl + (2.6 if deep_porch else 0.6)
	lm.gable("RoofShingle", orig + b * Vector3(0.0, deck_y + wall_h, 0.0), cw, roof_l, rise, b, 0.65, "WhiteWood")
	if deep_porch:
		for px_f: float in [-0.45, -0.15, 0.15, 0.45]:
			lm.box("WhiteWood", orig + b * Vector3(cw * px_f, deck_y + wall_h * 0.5, cl * 0.5 + 1.15),
				Vector3(0.15, wall_h, 0.15), b, 0.0)
	for wx_f: float in [-0.30, 0.30]:
		for sz: float in [-1.0, 1.0]:
			var fz := z_off + sz * (cl * 0.5 + 0.04)
			lm.box(shutter_key, orig + b * Vector3(cw * wx_f, deck_y + wall_h * 0.55, fz),
				Vector3(1.15, 1.35, 0.12), b, 0.0)

static func _build_mansard_stilt_house(lm: LandmarkMesh, orig: Vector3, yaw: float,
		cw: float, cl: float, deck_y: float, wall_key: String, trim_key: String) -> void:
	# Matches side.jpg & front.jpg: bright orange walls, white shutter bays, broad grey mansard hood roof
	var b := Basis(Vector3.UP, yaw)
	_build_pilings_and_deck(lm, orig, b, cw + 5.8, cl + 4.6, deck_y, 5, 4, 1.0)
	var wall_h := 2.65
	lm.box(wall_key, orig + b * Vector3(-1.2, deck_y + wall_h * 0.5, 0.0), Vector3(cw - 2.4, wall_h, cl), b)
	for k: int in 4:
		var wx := -cw * 0.42 + float(k) * 2.8
		for sz: float in [-1.0, 1.0]:
			lm.box(trim_key, orig + b * Vector3(wx, deck_y + 1.35, sz * (cl * 0.5 + 0.04)),
				Vector3(1.35, 1.50, 0.12), b, 0.0)
	# Mansard-hipped shingle roof overhanging front covered porch (+X side in side.jpg)
	for sz: float in [-1.0, 1.0]:
		lm.box("WhiteWood", orig + b * Vector3(cw * 0.5 + 0.4, deck_y + wall_h * 0.5, sz * (cl * 0.42)),
			Vector3(0.16, wall_h, 0.16), b, 0.0)
	lm.lathe("RoofShingle", orig + b * Vector3(0.0, deck_y + wall_h, 0.0), PackedVector2Array([
		Vector2(1.0, 0.0), Vector2(0.84, 1.45), Vector2(0.0, 1.70)]),
		4, (cw + 2.2) * 0.707, (cl + 1.8) * 0.707, PI * 0.25, false)

static func _build_hipped_stilt_house(lm: LandmarkMesh, orig: Vector3, yaw: float,
		cw: float, cl: float, deck_y: float, wall_key: String, shutter_key: String) -> void:
	var b := Basis(Vector3.UP, yaw)
	_build_pilings_and_deck(lm, orig, b, cw + 4.8, cl + 4.6, deck_y, 4, 4, -1.0)
	var wall_h := 2.75
	lm.box(wall_key, orig + b * Vector3(0.0, deck_y + wall_h * 0.5, 0.0), Vector3(cw, wall_h, cl), b)
	lm.lathe("RoofShingle", orig + b * Vector3(0.0, deck_y + wall_h, 0.0), PackedVector2Array([
		Vector2(1.0, 0.0), Vector2(0.45, 1.55), Vector2(0.0, 1.85)]),
		4, (cw + 1.4) * 0.707, (cl + 1.4) * 0.707, PI * 0.25, false)
	for wx_f: float in [-0.28, 0.28]:
		for sz: float in [-1.0, 1.0]:
			lm.box(shutter_key, orig + b * Vector3(cw * wx_f, deck_y + 1.45, sz * (cl * 0.5 + 0.04)),
				Vector3(1.10, 1.30, 0.12), b, 0.0)

static func _build_channel_markers(lm: LandmarkMesh) -> void:
	# Biscayne Channel wooden daymark piling & solar beacon + two small moored skiff hulls at docks
	var mp := Vector3(24.0, SEABED_Y, -48.0)
	lm.frustum("Piling", mp, 0.22, 0.18, 8.1, 8)
	lm.box("MintWood", Vector3(24.0, 3.8, -48.0), Vector3(1.1, 1.1, 0.14), Basis(Vector3.UP, 0.4), 0.0)
	lm.frustum("NavLamp", Vector3(24.0, 4.5, -48.0), 0.14, 0.14, 0.24, 8)

	# Small white open Fisherman skiff moored alongside Boat Club & Baldwin docks
	for skiff: Vector3 in [Vector3(2.5, 0.25, 11.8), Vector3(38.5, 0.25, -11.5)]:
		var sb := Basis(Vector3.UP, 0.18)
		lm.box("WhiteWood", skiff, Vector3(5.4, 0.68, 1.95), sb)
		lm.box("BlueWood", skiff + Vector3(0.0, 0.22, 0.0), Vector3(4.2, 0.35, 1.45), sb)
