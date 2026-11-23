class_name LandmarkMiFreedomTower
extends RefCounted

## Freedom Tower (Miami News & Metropolis Building) — Downtown Miami MI-2A.1
## Site: 600 Biscayne Blvd, OSM way 290629021 (25.780265, -80.189784, yaw_deg -1.3).
## Architect: Schultze & Weaver (1925), modelled after the Giralda of Seville.
## Measured envelope & tiers (Commons front/quarter/aerial/night, CTBUH/NPS 255 ft = 78.0 m):
##   - Footprint: 53.7 m (W-E along X) x 36.8 m (N-S along Z), +X facing East onto Biscayne Blvd.
##   - Base (y = 0..16.5 m): 3-storey cream-yellow stucco (#F2E4C6) Mediterranean Revival block
##     with rusticated cast-stone (#DFD3BE) plinth, arched ground loggia, ornate Spanish Baroque /
##     Churrigueresque sculpted east portal (broken scrolled pediment, twisted columns, coat of arms),
##     clay barrel-tile side-wing roofs, balustrade parapet & corner obelisk finials; 4th-storey
##     west attic setback (y = 16.5..20.5 m).
##   - Main Giralda bell-tower shaft (y = 16.5..48.0 m): 13.6 x 13.6 m square shaft centred on the
##     east front (cx = 17.8 m) with vertical stucco panel recesses, 8 storeys of 3-bay recessed
##     dark windows, bracketed cast-stone cornice, balustrade & 4 octagonal corner pavilion turrets.
##   - Diminishing Giralda belfry tiers (y = 48.0..70.5 m): square belfry tier (10.2 m, y = 48.0..57.5 m)
##     with paired arched openings & corner urns, octagonal lantern tier (6.8 m, y = 57.5..65.5 m)
##     with arched niches & roundels, and upper octagonal drum (4.9 m, y = 65.5..70.5 m).
##   - Crown (y = 70.5..78.0 m): ribbed patinated copper-green (#5E8E79) cupola dome, bronze
##     cupola lantern, and Spanish galleon weathervane finial reaching exact y = 78.0 m.

const HEIGHT_M := 78.0
const TOWER_X := 17.8

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stucco", LandmarkMaterials.pbr("render", "#F2E4C6", 3.5))
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#DFD3BE", 3.0))
	lm.use("Tile", LandmarkMaterials.pbr("terracotta", "#B85A3A", 2.2))
	lm.use("Copper", LandmarkMaterials.pbr("copper", "#5E8E79", 2.5))
	lm.use("Window", LandmarkMaterials.glass("#222B33"))
	lm.use("Bronze", LandmarkMaterials.paint("#4B3F31", 0.42, 0.65))
	lm.use("Gold", LandmarkMaterials.gold())

	_build_base(lm)
	_build_east_portal(lm)
	_build_main_shaft(lm)
	_build_giralda_crown(lm)
	lm.commit(model)

	var warm := Color(1.0, 0.86, 0.56)
	var amber := Color(1.0, 0.80, 0.46)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(38.0, 1.5, -14.0), Vector3(TOWER_X, 34.0, 0.0), 48.0, 1.25, 68.0, warm],
		[Vector3(38.0, 1.5, 14.0), Vector3(TOWER_X, 34.0, 0.0), 48.0, 1.25, 68.0, warm],
		[Vector3(TOWER_X, 17.2, -14.5), Vector3(TOWER_X, 52.0, -2.0), 44.0, 1.15, 62.0, warm],
		[Vector3(TOWER_X, 17.2, 14.5), Vector3(TOWER_X, 52.0, 2.0), 44.0, 1.15, 62.0, warm],
		[Vector3(4.0, 21.0, 0.0), Vector3(TOWER_X - 2.0, 54.0, 0.0), 46.0, 1.05, 58.0, warm],
		[Vector3(TOWER_X + 7.2, 48.6, 0.0), Vector3(TOWER_X, 66.0, 0.0), 42.0, 1.20, 36.0, amber],
		[Vector3(TOWER_X - 7.2, 48.6, 0.0), Vector3(TOWER_X, 66.0, 0.0), 42.0, 1.20, 36.0, amber],
	])

static func _build_base(lm: LandmarkMesh) -> void:
	var bx := 53.7
	var bz := 36.8
	var hx := bx * 0.5
	var hz := bz * 0.5
	# Rusticated limestone foundation & ground-floor arcade base (y = -0.35..5.0 m)
	lm.box("Stone", Vector3(0.0, 0.625, 0.0), Vector3(bx + 0.6, 1.95, bz + 0.6))
	lm.box("Stone", Vector3(0.0, 3.3, 0.0), Vector3(bx + 0.2, 3.4, bz + 0.2))
	# Main 3-storey Mediterranean Revival cream-yellow stucco body (y = 5.0..15.2 m)
	lm.box("Stucco", Vector3(0.0, 10.1, 0.0), Vector3(bx, 10.2, bz))
	# Projecting cast-stone stringcourse, modillion cornice, and roof balustrade (y = 14.8..16.5 m)
	lm.box("Stone", Vector3(0.0, 5.15, 0.0), Vector3(bx + 0.5, 0.42, bz + 0.5))
	lm.box("Stone", Vector3(0.0, 15.15, 0.0), Vector3(bx + 0.9, 0.72, bz + 0.9))
	lm.box("Stone", Vector3(0.0, 16.0, 0.0), Vector3(bx + 0.3, 1.0, bz + 0.3))
	lm.box("Stucco", Vector3(0.0, 16.15, 0.0), Vector3(bx - 1.2, 0.72, bz - 1.2))

	# Corner rusticated cast-stone pilasters & rooftop obelisk pinnacles on East front
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			lm.box("Stone", Vector3(sx * (hx - 0.9), 8.2, sz * (hz - 0.9)), Vector3(2.2, 14.8, 2.2))
			var px: float = sx * (hx - 0.7)
			var pz: float = sz * (hz - 0.7)
			lm.box("Stone", Vector3(px, 16.9, pz), Vector3(1.1, 0.8, 1.1))
			lm.spire("Stone", Vector3(px, 17.3, pz), 0.42, 1.85, 0.05, 4)
		if sx > 0.0:
			for sz in [-1.0, 1.0]:
				lm.beam("Bronze", Vector3(hx - 0.7, 17.3, sz * (hz - 3.6)),
					Vector3(hx - 0.7, 25.5, sz * (hz - 3.6)), 0.12, 0.12)

	# 4th-storey central-west editorial wing setback (y = 16.5..20.4 m) & clay barrel-tile roof strips
	lm.box("Stucco", Vector3(-5.5, 18.45, 0.0), Vector3(34.0, 3.9, 21.6))
	lm.box("Stone", Vector3(-5.5, 20.35, 0.0), Vector3(34.6, 0.45, 22.2))
	for sz in [-1.0, 1.0]:
		var out_z := Vector2(0.0, sz)
		var z_edge: float = sz * (hz - 0.8)
		LandmarkMiKit.barrel_tile_strip(lm, "Tile",
			Vector2(-hx + 2.2, z_edge), Vector2(hx - 2.2, z_edge), 16.45, 17.85, 4.4, out_z)
		LandmarkMiKit.barrel_tile_strip(lm, "Tile",
			Vector2(-22.2, sz * 10.6), Vector2(11.2, sz * 10.6), 20.4, 21.5, 3.6, out_z)
	LandmarkMiKit.barrel_tile_strip(lm, "Tile",
		Vector2(-hx + 0.8, -hz + 2.5), Vector2(-hx + 0.8, hz - 2.5), 16.45, 17.85, 4.4, Vector2(-1.0, 0.0))

	# East front (+X) ground-floor arched loggia bays & upper-floor windows flanking the central portal
	for sz in [-1.0, 1.0]:
		for k in 2:
			var wz: float = sz * (8.4 + float(k) * 5.2)
			lm.box("Window", Vector3(hx + 0.02, 2.85, wz), Vector3(0.32, 3.5, 2.6), Basis(), 0.0)
			lm.box("Stone", Vector3(hx + 0.18, 4.75, wz), Vector3(0.42, 0.45, 3.1))
			lm.box("Window", Vector3(hx - 0.04, 8.2, wz), Vector3(0.28, 3.4, 2.3), Basis(), 0.0)
			lm.box("Stone", Vector3(hx + 0.32, 6.35, wz), Vector3(0.75, 0.35, 2.9))
			lm.box("Stone", Vector3(hx + 0.28, 10.15, wz), Vector3(0.65, 0.42, 2.8))
			lm.box("Window", Vector3(hx - 0.04, 12.8, wz), Vector3(0.28, 2.4, 2.2), Basis(), 0.0)
			lm.box("Stone", Vector3(hx + 0.20, 14.15, wz), Vector3(0.45, 0.30, 2.6))

	# North (-Z) and South (+Z) side elevations: 8 bays of recessed windows across 3 storeys
	for sz in [-1.0, 1.0]:
		var fz: float = sz * hz
		for i in 8:
			var wx := -21.0 + float(i) * 6.0
			for fl in [2.9, 8.2, 12.8]:
				var wh := 2.4 if fl > 11.0 else 3.2
				lm.box("Window", Vector3(wx, fl, fz), Vector3(2.2, wh, 0.30), Basis(), 0.0)
				lm.box("Stone", Vector3(wx, fl + wh * 0.5 + 0.2, fz + sz * 0.12), Vector3(2.6, 0.28, 0.36))
			if i >= 5:
				lm.box("Stone", Vector3(wx + 3.0, 9.8, fz + sz * 0.14), Vector3(0.75, 10.2, 0.38))

	for k in 5:
		var wz := -12.0 + float(k) * 6.0
		for fl in [3.0, 8.2, 12.8]:
			lm.box("Window", Vector3(-hx, fl, wz), Vector3(0.30, 2.6, 2.2), Basis(), 0.0)

static func _build_east_portal(lm: LandmarkMesh) -> void:
	var px := 26.85
	for s in 4:
		var sw := 11.6 - float(s) * 0.7
		var sd := 2.6 - float(s) * 0.52
		lm.box("Stone", Vector3(px + sd * 0.5, 0.16 + float(s) * 0.22, 0.0), Vector3(sd, 0.24, sw), Basis(), 0.0)
	lm.box("Stone", Vector3(px + 0.48, 8.6, 0.0), Vector3(1.15, 15.6, 8.4))
	lm.box("Window", Vector3(px + 0.88, 3.6, 0.0), Vector3(0.45, 5.4, 3.6), Basis(), 0.0)
	lm.box("Bronze", Vector3(px + 0.96, 6.1, 0.0), Vector3(0.38, 1.1, 3.4), Basis(), 0.0)
	for sz in [-1.0, 1.0]:
		lm.frustum("Stone", Vector3(px + 1.12, 1.1, sz * 2.55), 0.38, 0.32, 5.6, 10)
		lm.frustum("Stone", Vector3(px + 1.05, 7.4, sz * 2.25), 0.32, 0.27, 5.2, 10)
		var oc := Vector3(px + 0.55, 10.2, sz * 5.2)
		lm.disc("Window", oc + Vector3(0.12, 0.0, 0.0), Vector3.RIGHT, 0.95, 16)
		lm.box("Stone", oc, Vector3(0.35, 2.35, 2.35))
	lm.box("Stone", Vector3(px + 1.18, 7.05, 0.0), Vector3(0.95, 0.75, 6.2))
	lm.box("Window", Vector3(px + 0.92, 10.6, 0.0), Vector3(0.38, 4.2, 2.5), Basis(), 0.0)
	lm.box("Stone", Vector3(px + 0.35, 17.6, 0.0), Vector3(1.0, 3.4, 6.2))
	lm.box("Stone", Vector3(px + 0.42, 19.6, 0.0), Vector3(0.9, 1.6, 3.4))
	lm.spire("Stone", Vector3(px + 0.42, 20.4, 0.0), 0.48, 1.35, 0.06, 4)

static func _build_main_shaft(lm: LandmarkMesh) -> void:
	var w := 13.6
	var hw := w * 0.5
	var y0 := 16.5
	var y1 := 48.0
	lm.box("Stucco", Vector3(TOWER_X, (y0 + y1) * 0.5, 0.0), Vector3(w, y1 - y0, w))
	lm.box("Stone", Vector3(TOWER_X, y0 + 0.55, 0.0), Vector3(w + 0.7, 1.1, w + 0.7))
	lm.box("Stone", Vector3(TOWER_X, 45.4, 0.0), Vector3(w + 0.65, 0.55, w + 0.65))
	lm.box("Stone", Vector3(TOWER_X, 46.65, 0.0), Vector3(w + 1.55, 0.95, w + 1.55))
	lm.box("Stone", Vector3(TOWER_X, 47.55, 0.0), Vector3(w + 0.85, 0.90, w + 0.85))

	for side in 4:
		var ang := float(side) * PI * 0.5
		var n3 := Vector3(sin(ang), 0.0, cos(ang))
		var t3 := Vector3(cos(ang), 0.0, -sin(ang))
		var basis := Basis(t3, Vector3.UP, n3)
		for sg: float in [-1.0, 1.0]:
			var cpos := Vector3(TOWER_X, 31.2, 0.0) + n3 * (hw + 0.08) + t3 * (sg * (hw - 0.75))
			lm.box("Stone", cpos, Vector3(1.5, 28.4, 0.32), basis)
		for m: float in [-1.65, 1.65]:
			var mpos := Vector3(TOWER_X, 31.4, 0.0) + n3 * (hw + 0.04) + t3 * m
			lm.box("Stone", mpos, Vector3(0.46, 26.8, 0.22), basis)
		for fl in 8:
			var wy := 19.2 + float(fl) * 3.32
			for b: float in [-3.3, 0.0, 3.3]:
				var wpos := Vector3(TOWER_X, wy, 0.0) + n3 * (hw + 0.01) + t3 * b
				lm.box("Window", wpos, Vector3(1.42, 1.95, 0.20), basis, 0.0)
				lm.box("Stone", wpos + Vector3(0.0, -1.10, 0.0) + n3 * 0.06,
					Vector3(1.62, 0.24, 0.24), basis, 0.0)

	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var tx: float = TOWER_X + sx * (hw - 0.85)
			var tz: float = sz * (hw - 0.85)
			lm.box("Stone", Vector3(tx, 49.35, tz), Vector3(1.85, 2.7, 1.85))
			lm.box("Window", Vector3(tx + sx * 0.88, 49.3, tz), Vector3(0.22, 1.5, 0.72), Basis(), 0.0)
			lm.box("Window", Vector3(tx, 49.3, tz + sz * 0.88), Vector3(0.72, 1.5, 0.22), Basis(), 0.0)
			lm.lathe("Copper", Vector3(tx, 50.7, tz), PackedVector2Array([
				Vector2(0.95, 0.0), Vector2(0.82, 0.45), Vector2(0.42, 0.85), Vector2(0.0, 1.05)]), 8, 1.0, 1.0, 0.0, false)
			lm.beam("Bronze", Vector3(tx, 51.75, tz), Vector3(tx, 52.65, tz), 0.08, 0.08)

static func _build_giralda_crown(lm: LandmarkMesh) -> void:
	var c2 := Vector2(TOWER_X, 0.0)
	LandmarkMiKit.giralda_tier(lm, "Stucco", "Stone", "Window", c2, 48.0, 9.5, 10.2, false, 2, true)
	for side in 4:
		var ang := float(side) * PI * 0.5
		var n3 := Vector3(sin(ang), 0.0, cos(ang))
		var t3 := Vector3(cos(ang), 0.0, -sin(ang))
		lm.box("Stone", Vector3(TOWER_X, 55.6, 0.0) + n3 * 5.25, Vector3(1.5, 2.0, 0.45), Basis(t3, Vector3.UP, n3))
		for k: float in [-2.6, 0.0, 2.6]:
			var p := Vector3(TOWER_X, 57.55, 0.0) + n3 * 5.05 + t3 * k
			lm.box("Stone", p + Vector3(0.0, 0.28, 0.0), Vector3(0.56, 0.56, 0.56))
			lm.spire("Stone", p + Vector3(0.0, 0.56, 0.0), 0.24, 1.45, 0.03, 4)

	LandmarkMiKit.giralda_tier(lm, "Stucco", "Stone", "Window", c2, 57.5, 8.0, 6.8, true, 1, false)
	for i in 8:
		var a := (float(i) + 0.5) * PI * 0.25
		var p := Vector3(TOWER_X + cos(a) * 3.55, 57.5, sin(a) * 3.55)
		lm.frustum("Stone", p + Vector3(0.0, 0.4, 0.0), 0.24, 0.20, 6.6, 8)
		lm.spire("Stone", p + Vector3(0.0, 8.05, 0.0), 0.22, 1.15, 0.03, 4)

	LandmarkMiKit.giralda_tier(lm, "Stucco", "Stone", "Window", c2, 65.5, 5.0, 4.9, true, 1, false)
	for i in 8:
		var a := (float(i) + 0.5) * PI * 0.25
		var p := Vector3(TOWER_X + cos(a) * 2.55, 70.55, sin(a) * 2.55)
		lm.spire("Stone", p, 0.16, 0.80, 0.03, 4)

	# Ribbed patinated copper-green cupola dome (y = 70.5..74.35 m)
	var dome_base := Vector3(TOWER_X, 70.5, 0.0)
	lm.lathe("Copper", dome_base, PackedVector2Array([
		Vector2(2.42, 0.0), Vector2(2.40, 0.65), Vector2(2.18, 1.55),
		Vector2(1.72, 2.45), Vector2(1.12, 3.25), Vector2(0.58, 3.85)]), 16)
	for i in 8:
		var a := float(i) * PI * 0.25
		var dir := Vector3(cos(a), 0.0, sin(a))
		lm.beam("Copper", dome_base + dir * 2.42 + Vector3(0.0, 0.2, 0.0),
			dome_base + dir * 1.65 + Vector3(0.0, 2.5, 0.0), 0.14, 0.14)
		lm.beam("Copper", dome_base + dir * 1.65 + Vector3(0.0, 2.5, 0.0),
			dome_base + dir * 0.58 + Vector3(0.0, 3.85, 0.0), 0.12, 0.12)

	# Bronze lantern & Spanish galleon weathervane finial reaching exact y = 78.0 m
	lm.frustum("Bronze", Vector3(TOWER_X, 74.35, 0.0), 0.66, 0.58, 1.35, 8)
	lm.lathe("Copper", Vector3(TOWER_X, 75.70, 0.0), PackedVector2Array([
		Vector2(0.68, 0.0), Vector2(0.45, 0.38), Vector2(0.12, 0.78), Vector2(0.0, 0.90)]), 8)
	lm.beam("Gold", Vector3(TOWER_X, 76.55, 0.0), Vector3(TOWER_X, HEIGHT_M, 0.0), 0.09, 0.09, Vector3.RIGHT, true)
	lm.lathe("Gold", Vector3(TOWER_X, 76.78, 0.0), PackedVector2Array([
		Vector2(0.05, 0.0), Vector2(0.24, 0.18), Vector2(0.05, 0.36)]), 10)
	lm.beam("Bronze", Vector3(TOWER_X - 0.55, 77.22, 0.0), Vector3(TOWER_X + 0.55, 77.22, 0.0), 0.06, 0.06)
	lm.beam("Bronze", Vector3(TOWER_X, 77.22, -0.55), Vector3(TOWER_X, 77.22, 0.55), 0.06, 0.06)
	lm.box("Gold", Vector3(TOWER_X, 77.62, 0.0), Vector3(0.92, 0.34, 0.12), Basis(), 0.0)
	lm.box("Gold", Vector3(TOWER_X - 0.05, 77.84, 0.0), Vector3(0.56, 0.32, 0.08), Basis(), 0.0)
