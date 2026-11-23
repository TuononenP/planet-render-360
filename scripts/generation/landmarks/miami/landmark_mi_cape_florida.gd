class_name LandmarkMiCapeFlorida
extends RefCounted

## Cape Florida Light & Keeper's Cottage — Bill Baggs Cape Florida State Park (MI-10)
## Site: Southern tip of Key Biscayne, OSM way 305533830 (25.666591, -80.155966, yaw_deg 33.8).
## Built 1825, rebuilt & raised 1846/1855 to 95 ft (29.0 m) — oldest standing structure in Miami-Dade.
## Measured envelope & materials (Commons front/quarter/side, NPS/USCG 95 ft = 29.0 m):
##   - Conical whitewashed brick lighthouse shaft centred at origin: base r = 3.60 m tapering
##     smoothly to r = 2.10 m at y = 24.20 m, with corbelled brick cornice & 4 vertical window bays.
##   - Cantilevered black cast-iron watch gallery deck (r = 2.75 m at y = 24.20..24.55 m) on scroll
##     brackets with iron stanchion railing.
##   - Black iron decagonal lantern room (y = 24.55..28.10 m) housing a warm glowing Fresnel lens
##     (BeaconLamp + HALO_META), ventilator ball & lightning rod reaching exact y = 29.0 m.
##   - Adjacent 2-storey red-brick Keeper's Cottage with two-tier white timber wrap-around veranda,
##     green storm shutters, pitched slate-shingle gable roof, chimneys & detached brick kitchen.

const HEIGHT_M := 29.0
const COTTAGE_X := -12.8
const COTTAGE_Z := -3.6

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("WhiteBrick", LandmarkMaterials.pbr("brick", "#F2F0EA", 2.4))
	lm.use("RedBrick", LandmarkMaterials.pbr("brick", "#9B4838", 2.2))
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#DDD5C4", 2.8))
	lm.use("Iron", LandmarkMaterials.paint("#1E2226", 0.46, 0.68))
	lm.use("WhiteWood", LandmarkMaterials.pbr("wood", "#F0EEE8", 2.4))
	lm.use("RoofSlate", LandmarkMaterials.pbr("slate", "#565B60", 2.2))
	lm.use("Shutter", LandmarkMaterials.paint("#2E523B", 0.64, 0.08))
	lm.use("Glass", LandmarkMaterials.glass("#334B58"))
	lm.use("BeaconLamp", LandmarkMaterials.lit("#FFE394", 2.6))
	lm.use("PalmFrond", LandmarkMaterials.pbr("grass", "#386B2E", 2.0))

	_build_plinth_and_walk(lm)
	_build_lighthouse_shaft(lm)
	_build_gallery_and_lantern(lm)
	_build_keepers_cottage(lm)
	lm.commit(model)

	var warm := Color(1.0, 0.88, 0.64)
	model.set_meta(LandmarkLights.HALO_META, [
		[Vector3(0.0, 26.25, 0.0), 5.6, Color(1.0, 0.90, 0.62)],
	])
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(7.5, 0.8, 7.5), Vector3(0.0, 15.0, 0.0), 46.0, 1.05, 36.0, warm],
		[Vector3(-6.5, 0.8, 8.0), Vector3(0.0, 16.0, 0.0), 46.0, 1.05, 36.0, warm],
		[Vector3(6.5, 0.8, -7.5), Vector3(0.0, 15.0, 0.0), 46.0, 0.95, 36.0, warm],
		[Vector3(COTTAGE_X, 0.8, COTTAGE_Z + 9.5), Vector3(COTTAGE_X, 5.0, COTTAGE_Z), 52.0, 0.85, 24.0, warm],
	])

static func _build_plinth_and_walk(lm: LandmarkMesh) -> void:
	# Circular limestone coastal plinth around the lighthouse base & brick path to cottage
	lm.frustum("Stone", Vector3(0.0, -0.35, 0.0), 5.6, 5.3, 0.65, 24)
	lm.frustum("Stone", Vector3(0.0, 0.30, 0.0), 4.25, 3.85, 0.38, 24)
	# Brick walkway linking lighthouse entry (+Z/-X) to Keeper's Cottage veranda
	var walk_dir := Vector2(COTTAGE_X + 4.8, COTTAGE_Z + 1.8) - Vector2(-2.6, 2.2)
	var walk_len := walk_dir.length()
	var dn := walk_dir / maxf(walk_len, 0.01)
	var basis := Basis(Vector3(dn.x, 0.0, dn.y), Vector3.UP, Vector3(-dn.y, 0.0, dn.x))
	var mid := (Vector2(-2.6, 2.2) + Vector2(COTTAGE_X + 4.8, COTTAGE_Z + 1.8)) * 0.5
	lm.box("RedBrick", Vector3(mid.x, 0.02, mid.y), Vector3(walk_len, 0.36, 1.85), basis)

	# Coastal palms framing the dune clearing
	LandmarkMiKit.royal_palm(lm, "Stone", "PalmFrond", Vector3(6.2, 0.1, -4.4), 10.5, 0.4)
	LandmarkMiKit.royal_palm(lm, "Stone", "PalmFrond", Vector3(-4.8, 0.1, 6.6), 9.2, 1.7)
	LandmarkMiKit.royal_palm(lm, "Stone", "PalmFrond", Vector3(COTTAGE_X - 6.8, 0.0, COTTAGE_Z + 5.6), 11.2, 2.5)

static func _build_lighthouse_shaft(lm: LandmarkMesh) -> void:
	# Conical whitewashed brick tower: r = 3.60 m at y = 0.68 m tapering to r = 2.10 m at y = 24.20 m,
	# with corbelled brick rings flaring beneath the cast-iron gallery deck.
	lm.lathe("WhiteBrick", Vector3.ZERO, PackedVector2Array([
		Vector2(3.76, 0.55),
		Vector2(3.60, 0.95),
		Vector2(3.22, 6.50),
		Vector2(2.85, 12.20),
		Vector2(2.48, 17.80),
		Vector2(2.14, 23.10),
		Vector2(2.10, 23.55),
		Vector2(2.26, 23.85),
		Vector2(2.46, 24.20),
	]), 24)

	# Entry portal at ground level (+Z ocean/path side) with 3 limestone steps & arched lintel
	for s: int in 3:
		var sy := 0.14 + float(s) * 0.18
		var sz := 4.45 - float(s) * 0.32
		lm.box("Stone", Vector3(0.0, sy, sz), Vector3(1.85 - float(s) * 0.12, 0.20, 0.46), Basis(), 0.0)
	lm.box("WhiteBrick", Vector3(0.0, 1.85, 3.55), Vector3(1.58, 2.55, 0.62))
	lm.box("Stone", Vector3(0.0, 3.18, 3.62), Vector3(1.76, 0.28, 0.68))
	lm.box("WhiteWood", Vector3(0.0, 1.75, 3.82), Vector3(1.06, 2.18, 0.14), Basis(), 0.0)
	lm.disc("Glass", Vector3(0.0, 2.68, 3.88), Vector3(0.0, 0.0, 1.0), 0.46, 12)

	# 4 stacked stair-landing windows spiralling gently / alternating faces up the conical brick shaft
	var win_heights: Array[float] = [6.2, 11.4, 16.6, 21.0]
	var win_angles: Array[float] = [0.0, 0.5 * PI, PI, 1.5 * PI]
	for k: int in 4:
		var wy: float = win_heights[k]
		var ang: float = win_angles[k]
		var t := (wy - 0.95) / (23.55 - 0.95)
		var r_at := lerpf(3.60, 2.10, t)
		var n3 := Vector3(sin(ang), 0.0, cos(ang))
		var t3 := Vector3(cos(ang), 0.0, -sin(ang))
		var wb := Basis(t3, Vector3.UP, n3)
		var wpos := Vector3(0.0, wy, 0.0) + n3 * (r_at - 0.02)
		lm.box("Glass", wpos, Vector3(0.66, 1.18, 0.18), wb, 0.0)
		lm.box("Iron", wpos + Vector3(0.0, -0.64, 0.0) + n3 * 0.06, Vector3(0.82, 0.12, 0.24), wb, 0.0)
		lm.box("Stone", wpos + Vector3(0.0, 0.65, 0.0) + n3 * 0.05, Vector3(0.82, 0.14, 0.22), wb, 0.0)

static func _build_gallery_and_lantern(lm: LandmarkMesh) -> void:
	# Cast-iron gallery deck (y = 24.20..24.52 m, r = 2.78 m) + 12 iron scroll brackets
	lm.frustum("Iron", Vector3(0.0, 24.20, 0.0), 2.52, 2.78, 0.18, 20)
	lm.frustum("Iron", Vector3(0.0, 24.38, 0.0), 2.78, 2.76, 0.14, 20)
	for i: int in 12:
		var a := TAU * float(i) / 12.0
		var dir := Vector3(cos(a), 0.0, sin(a))
		var side := Vector3(-sin(a), 0.0, cos(a))
		lm.beam("Iron", dir * 2.12 + Vector3(0.0, 23.45, 0.0),
			dir * 2.70 + Vector3(0.0, 24.22, 0.0), 0.10, 0.16, side)

	# Gallery cast-iron balustrade around r = 2.68 m (y = 24.52..25.58 m)
	var gr := 2.68
	var segs := 20
	for i: int in segs:
		var a0 := TAU * float(i) / float(segs)
		var a1 := TAU * float(i + 1) / float(segs)
		var p0 := Vector3(cos(a0) * gr, 24.52, sin(a0) * gr)
		var p1 := Vector3(cos(a1) * gr, 24.52, sin(a1) * gr)
		lm.beam("Iron", p0, p0 + Vector3(0.0, 1.06, 0.0), 0.05, 0.05)
		lm.beam("Iron", p0 + Vector3(0.0, 1.04, 0.0), p1 + Vector3(0.0, 1.04, 0.0), 0.06, 0.06)
		lm.beam("Iron", p0 + Vector3(0.0, 0.54, 0.0), p1 + Vector3(0.0, 0.54, 0.0), 0.04, 0.04)

	# Decagonal black iron lantern parapet base (y = 24.52..25.48 m, r = 1.80 m)
	lm.lathe("Iron", Vector3(0.0, 24.52, 0.0), PackedVector2Array([
		Vector2(1.84, 0.0), Vector2(1.80, 0.88), Vector2(1.86, 0.96)]), 10, 1.0, 1.0, 0.0, false)

	# Decagonal lantern glazing (y = 25.48..27.14 m) + 10 helical/vertical iron astragals
	lm.lathe("Glass", Vector3(0.0, 25.48, 0.0), PackedVector2Array([
		Vector2(1.70, 0.0), Vector2(1.70, 1.66)]), 10, 1.0, 1.0, 0.0, false)
	for i: int in 10:
		var a := TAU * float(i) / 10.0
		var a_next := TAU * float(i + 1) / 10.0
		var d0 := Vector3(cos(a) * 1.73, 0.0, sin(a) * 1.73)
		var d1 := Vector3(cos(a_next) * 1.73, 0.0, sin(a_next) * 1.73)
		lm.beam("Iron", d0 + Vector3(0.0, 25.48, 0.0), d0 + Vector3(0.0, 27.14, 0.0), 0.07, 0.07)
		# Diagonal lattice bars characteristic of 19th-century USCG lanterns (visible in front.jpg)
		lm.beam("Iron", d0 + Vector3(0.0, 25.50, 0.0), d1 + Vector3(0.0, 27.12, 0.0), 0.04, 0.04)
		lm.beam("Iron", d1 + Vector3(0.0, 25.50, 0.0), d0 + Vector3(0.0, 27.12, 0.0), 0.04, 0.04)

	# Glowing warm stepped Fresnel lens inside lantern room (y = 25.66..26.92 m)
	lm.lathe("BeaconLamp", Vector3(0.0, 25.66, 0.0), PackedVector2Array([
		Vector2(0.72, 0.0), Vector2(1.06, 0.30), Vector2(1.16, 0.63),
		Vector2(1.06, 0.96), Vector2(0.72, 1.26), Vector2(0.0, 1.30)]), 14)

	# Upper lantern cornice ring, conical iron cupola roof, ventilator ball & lightning rod to exact 29.0 m
	lm.lathe("Iron", Vector3(0.0, 27.12, 0.0), PackedVector2Array([
		Vector2(1.76, 0.0), Vector2(2.04, 0.14), Vector2(1.88, 0.24),
		Vector2(0.96, 0.72), Vector2(0.28, 1.02)]), 10, 1.0, 1.0, 0.0, false)
	lm.lathe("Iron", Vector3(0.0, 28.12, 0.0), PackedVector2Array([
		Vector2(0.10, 0.0), Vector2(0.26, 0.16), Vector2(0.26, 0.28),
		Vector2(0.08, 0.42), Vector2(0.0, 0.45)]), 12)
	lm.beam("Iron", Vector3(0.0, 28.50, 0.0), Vector3(0.0, HEIGHT_M, 0.0), 0.05, 0.05, Vector3.RIGHT, true)

static func _build_keepers_cottage(lm: LandmarkMesh) -> void:
	# Reconstructed 2-storey red-brick Keeper's Cottage + two-tier white wooden porch & brick kitchen
	var cx := COTTAGE_X
	var cz := COTTAGE_Z
	var w := 8.4
	var l := 10.6
	lm.box("Stone", Vector3(cx, 0.10, cz), Vector3(w + 3.8, 0.90, l + 3.8))
	lm.box("RedBrick", Vector3(cx, 3.65, cz), Vector3(w, 6.20, l))
	lm.gable("RoofSlate", Vector3(cx, 6.75, cz), w, l, 2.35, Basis(), 0.55, "RedBrick")

	# Twin red-brick end chimneys rising above ridge
	for sz: float in [-1.0, 1.0]:
		var chz := cz + sz * (l * 0.5 - 0.55)
		lm.box("RedBrick", Vector3(cx, 8.20, chz), Vector3(0.95, 3.60, 0.75))
		lm.box("Stone", Vector3(cx, 10.05, chz), Vector3(1.10, 0.18, 0.90))

	# Two-tier white timber wrap-around veranda on +X (facing lighthouse) and +Z fronts
	var pw := w + 3.4
	var pl := l + 3.4
	lm.box("WhiteWood", Vector3(cx + 0.85, 0.62, cz + 0.85), Vector3(pw - 1.5, 0.22, pl - 1.5))
	lm.box("WhiteWood", Vector3(cx + 0.85, 3.72, cz + 0.85), Vector3(pw - 1.5, 0.22, pl - 1.5))
	# Sloping porch shed roofs along +X and +Z
	LandmarkMiKit.barrel_tile_strip(lm, "RoofSlate",
		Vector2(cx + w * 0.5 + 2.45, cz - l * 0.5), Vector2(cx + w * 0.5 + 2.45, cz + l * 0.5 + 2.45),
		6.15, 6.68, 2.55, Vector2(1.0, 0.0))
	LandmarkMiKit.barrel_tile_strip(lm, "RoofSlate",
		Vector2(cx - w * 0.5, cz + l * 0.5 + 2.45), Vector2(cx + w * 0.5 + 2.45, cz + l * 0.5 + 2.45),
		6.15, 6.68, 2.55, Vector2(0.0, 1.0))

	# Veranda square timber posts, handrails & front steps toward lighthouse walk
	var post_x := cx + w * 0.5 + 2.30
	var post_z := cz + l * 0.5 + 2.30
	for k: int in 5:
		var pz := lerpf(cz - l * 0.5 + 0.3, post_z, float(k) / 4.0)
		lm.box("WhiteWood", Vector3(post_x, 3.42, pz), Vector3(0.18, 5.55, 0.18), Basis(), 0.0)
	for k: int in 4:
		var px := lerpf(cx - w * 0.5 + 0.3, post_x, float(k) / 3.0)
		lm.box("WhiteWood", Vector3(px, 3.42, post_z), Vector3(0.18, 5.55, 0.18), Basis(), 0.0)
	for ry: float in [1.45, 4.55]:
		lm.beam("WhiteWood", Vector3(post_x, ry, cz - l * 0.5 + 0.3), Vector3(post_x, ry, post_z), 0.10, 0.10)
		lm.beam("WhiteWood", Vector3(cx - w * 0.5 + 0.3, ry, post_z), Vector3(post_x, ry, post_z), 0.10, 0.10)
	for s: int in 3:
		lm.box("WhiteWood", Vector3(post_x + 0.35 + float(s) * 0.32, 0.15 + float(2 - s) * 0.16, cz + 1.4),
			Vector3(0.36, 0.18, 1.80), Basis(), 0.0)

	# Cottage windows & green storm shutters on +X and +Z faces
	for fl_y: float in [2.15, 5.15]:
		for wz_off: float in [-3.0, 0.0, 3.0]:
			var wx := cx + w * 0.5 + 0.02
			var wz := cz + wz_off
			lm.box("Glass", Vector3(wx, fl_y, wz), Vector3(0.16, 1.45, 0.92), Basis(), 0.0)
			for sg: float in [-1.0, 1.0]:
				lm.box("Shutter", Vector3(wx + 0.05, fl_y, wz + sg * 0.68), Vector3(0.10, 1.48, 0.42), Basis(), 0.0)

	# Detached single-storey red-brick summer kitchen behind cottage (-Z)
	var kx := cx - 1.2
	var kz := cz - 8.2
	lm.box("RedBrick", Vector3(kx, 1.65, kz), Vector3(4.6, 3.30, 3.8))
	lm.gable("RoofSlate", Vector3(kx, 3.30, kz), 4.6, 3.8, 1.25, Basis(), 0.35, "RedBrick")
	lm.box("RedBrick", Vector3(kx - 1.9, 2.65, kz), Vector3(0.75, 4.80, 0.75))
