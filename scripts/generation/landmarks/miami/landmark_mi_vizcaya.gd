class_name LandmarkMiVizcaya
extends RefCounted

## Vizcaya Museum, Formal Gardens & Stone Barge — MI-10 Centre E (Coconut Grove).
## F. Burrall Hoffman / Paul Chalfin (1916). Footprint 140 x 120 m, height 21.5 m.
## Frame: +X = Biscayne Bay (east), +Z = south gardens.
##   - Main Villa (x -30..10, z -17..17, y 0..16.5): coral-stone / ochre stucco Italian
##     Renaissance block, central courtyard loggia, east bayfront terrace & sea steps,
##     four corner belvedere towers with clay-tile hipped roofs reaching 21.5 m.
##   - South parterre gardens: box-hedge broderies, central fountain basin, casino mound.
##   - Stone Barge breakwater east of the terrace (y 0..6.8 m): curved prows, obelisks,
##     balustrade, herm/mermaid sculpture, lattice Tea House.

const HEIGHT_M := 21.5
const VX := -20.0
const VHX := 20.0
const VHZ := 17.0

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stucco", LandmarkMaterials.pbr("render", "#E3B77E", 3.5))
	lm.use("Coral", LandmarkMaterials.pbr("limestone", "#D9C4A0", 3.0))
	lm.use("Tile", LandmarkMaterials.pbr("terracotta", "#B5573A", 2.2))
	lm.use("Window", LandmarkMaterials.glass("#26313A"))
	lm.use("Hedge", LandmarkMaterials.paint("#2F5A32", 0.9, 0.0))
	lm.use("Gravel", LandmarkMaterials.pbr("gravel", "#D6C9A8", 3.0))
	lm.use("Water", LandmarkMaterials.pool_water("#3E7C86"))
	lm.use("Wood", LandmarkMaterials.pbr("wood", "#6E8A6A", 2.0))
	_build_villa(lm)
	_build_towers(lm)
	_build_terrace(lm)
	_build_gardens(lm)
	_build_barge(lm)
	lm.commit(model)
	var warm := Color(1.0, 0.84, 0.52)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(30.0, 1.5, -18.0), Vector3(VX + 10.0, 10.0, 0.0), 40.0, 1.2, 60.0, warm],
		[Vector3(30.0, 1.5, 18.0), Vector3(VX + 10.0, 10.0, 0.0), 40.0, 1.2, 60.0, warm],
		[Vector3(-10.0, 1.5, 36.0), Vector3(-10.0, 8.0, 0.0), 40.0, 1.0, 60.0, warm],
	])

static func _hip_roof(lm: LandmarkMesh, cx: float, cz: float, hx: float, hz: float,
		eaves: float, ridge: float, depth: float) -> void:
	LandmarkMiKit.barrel_tile_strip(lm, "Tile", Vector2(cx - hx, cz - hz), Vector2(cx + hx, cz - hz), eaves, ridge, depth, Vector2(0.0, -1.0))
	LandmarkMiKit.barrel_tile_strip(lm, "Tile", Vector2(cx - hx, cz + hz), Vector2(cx + hx, cz + hz), eaves, ridge, depth, Vector2(0.0, 1.0))
	LandmarkMiKit.barrel_tile_strip(lm, "Tile", Vector2(cx - hx, cz - hz), Vector2(cx - hx, cz + hz), eaves, ridge, depth, Vector2(-1.0, 0.0))
	LandmarkMiKit.barrel_tile_strip(lm, "Tile", Vector2(cx + hx, cz - hz), Vector2(cx + hx, cz + hz), eaves, ridge, depth, Vector2(1.0, 0.0))

static func _build_villa(lm: LandmarkMesh) -> void:
	var bx := VHX * 2.0
	var bz := VHZ * 2.0
	# Coral-stone rusticated plinth and ochre stucco body
	lm.box("Coral", Vector3(VX, 1.9, 0.0), Vector3(bx + 1.0, 4.8, bz + 1.0))
	lm.box("Stucco", Vector3(VX, 9.7, 0.0), Vector3(bx, 10.8, bz))
	lm.box("Coral", Vector3(VX, 15.6, 0.0), Vector3(bx + 1.2, 0.9, bz + 1.2))
	lm.box("Coral", Vector3(VX, 16.2, 0.0), Vector3(bx + 0.4, 0.6, bz + 0.4))
	# Window bays on north/south/east/west faces, two storeys
	for sz: float in [-1.0, 1.0]:
		for i: int in 9:
			var wx := VX - 16.0 + float(i) * 4.0
			for wy: float in [7.4, 12.2]:
				lm.box("Window", Vector3(wx, wy, sz * (VHZ + 0.03)), Vector3(1.5, 2.6, 0.2), Basis(), 0.0)
				lm.box("Coral", Vector3(wx, wy + 1.5, sz * (VHZ + 0.1)), Vector3(2.0, 0.3, 0.3), Basis(), 0.0)
	for i: int in 6:
		var wz := -12.5 + float(i) * 5.0
		for wy: float in [7.4, 12.2]:
			lm.box("Window", Vector3(VX + VHX + 0.03, wy, wz), Vector3(0.2, 2.6, 1.6), Basis(), 0.0)
			lm.box("Window", Vector3(VX - VHX - 0.03, wy, wz), Vector3(0.2, 2.6, 1.6), Basis(), 0.0)
	# Courtyard loggia: glazed arched openings along the south ground floor
	for i: int in 7:
		var lx := VX - 12.0 + float(i) * 4.0
		lm.box("Window", Vector3(lx, 3.4, VHZ + 0.06), Vector3(2.2, 3.4, 0.2), Basis(), 0.0)
		lm.box("Coral", Vector3(lx + 2.0, 3.4, VHZ + 0.3), Vector3(0.7, 4.0, 0.6))
	# Central hipped clay-tile roof with ridge
	_hip_roof(lm, VX, 0.0, VHX - 6.0, VHZ - 3.0, 16.5, 19.0, 5.0)
	lm.box("Stucco", Vector3(VX, 18.0, 0.0), Vector3(bx - 14.0, 3.0, bz - 8.0))
	lm.box("Tile", Vector3(VX, 19.6, 0.0), Vector3(bx - 13.0, 0.6, bz - 7.0))

static func _build_towers(lm: LandmarkMesh) -> void:
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			var tx := VX + sx * (VHX - 3.0)
			var tz := sz * (VHZ - 3.0)
			lm.box("Stucco", Vector3(tx, 17.0, tz), Vector3(6.4, 1.0, 6.4))
			lm.box("Stucco", Vector3(tx, 17.75, tz), Vector3(5.6, 2.5, 5.6))
			lm.box("Window", Vector3(tx, 17.9, tz + sz * 2.82), Vector3(2.0, 1.6, 0.15), Basis(), 0.0)
			lm.box("Window", Vector3(tx + sx * 2.82, 17.9, tz), Vector3(0.15, 1.6, 2.0), Basis(), 0.0)
			lm.box("Coral", Vector3(tx, 19.15, tz), Vector3(6.4, 0.5, 6.4))
			lm.spire("Tile", Vector3(tx, 19.4, tz), 3.3, 2.1, 0.0, 4)

static func _build_terrace(lm: LandmarkMesh) -> void:
	# Grand east bayfront terrace, balustrade and sea steps
	var tx := VX + VHX + 7.0
	lm.box("Coral", Vector3(tx, 1.4, 0.0), Vector3(14.0, 3.4, 34.0))
	lm.box("Coral", Vector3(tx + 7.0, 2.1, 0.0), Vector3(0.5, 1.0, 34.0), Basis(), 0.0)
	for i: int in 17:
		var z := -16.0 + float(i) * 2.0
		lm.box("Coral", Vector3(tx + 6.9, 2.4, z), Vector3(0.45, 1.4, 0.45))
	for k: int in 5:
		var w := 14.0 - float(k) * 1.2
		lm.box("Coral", Vector3(tx + 8.5 + float(k) * 1.1, 0.5 + float(4 - k) * 0.0, 0.0),
			Vector3(1.2, 1.0 + float(4 - k) * 0.0, w), Basis(), 0.0)
	# Sea-facing portico / loggia attached to the east face
	for i: int in 5:
		var z := -8.0 + float(i) * 4.0
		lm.box("Coral", Vector3(VX + VHX + 1.5, 5.4, z), Vector3(1.0, 5.4, 0.9))
	lm.box("Coral", Vector3(VX + VHX + 1.5, 8.4, 0.0), Vector3(1.6, 0.7, 18.0))

static func _build_gardens(lm: LandmarkMesh) -> void:
	# Gravel parterre floor
	lm.box("Gravel", Vector3(-20.0, 0.0, 38.0), Vector3(60.0, 0.3, 36.0), Basis(), 0.0)
	# Box-hedge broderies: four quartered beds with border and cross hedges
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			var cx := -20.0 + sx * 14.0
			var cz := 38.0 + sz * 8.0
			lm.box("Hedge", Vector3(cx, 0.5, cz - 7.0), Vector3(20.0, 1.0, 0.8), Basis(), 0.0)
			lm.box("Hedge", Vector3(cx, 0.5, cz + 7.0), Vector3(20.0, 1.0, 0.8), Basis(), 0.0)
			lm.box("Hedge", Vector3(cx - 9.6, 0.5, cz), Vector3(0.8, 1.0, 14.0), Basis(), 0.0)
			lm.box("Hedge", Vector3(cx + 9.6, 0.5, cz), Vector3(0.8, 1.0, 14.0), Basis(), 0.0)
			for j: int in 3:
				var off := -4.0 + float(j) * 4.0
				lm.box("Hedge", Vector3(cx + off, 0.4, cz), Vector3(0.6, 0.8, 9.0), Basis(), 0.0)
				lm.box("Hedge", Vector3(cx, 0.4, cz + off), Vector3(14.0, 0.8, 0.6), Basis(), 0.0)
	# Central fountain basin
	lm.frustum("Coral", Vector3(-20.0, 0.0, 38.0), 4.2, 4.0, 1.0, 20)
	lm.frustum("Water", Vector3(-20.0, 0.9, 38.0), 3.7, 3.7, 0.12, 20)
	lm.lathe("Coral", Vector3(-20.0, 0.9, 38.0), PackedVector2Array([
		Vector2(0.9, 0.0), Vector2(0.5, 1.2), Vector2(1.1, 1.8), Vector2(0.3, 2.4), Vector2(0.0, 2.6)]), 12)
	# Casino mound pavilion at south end
	lm.frustum("Coral", Vector3(-20.0, -0.3, 60.0 - 6.0), 9.0, 6.0, 4.3, 16)
	lm.box("Stucco", Vector3(-20.0, 6.6, 54.0), Vector3(7.0, 2.6, 7.0))
	lm.box("Coral", Vector3(-20.0, 8.1, 54.0), Vector3(8.0, 0.5, 8.0))
	lm.spire("Tile", Vector3(-20.0, 8.35, 54.0), 4.2, 2.2, 0.0, 4)

static func _build_barge(lm: LandmarkMesh) -> void:
	# Ship-shaped coral-limestone breakwater with prows N and S (x 38..62)
	var hull := PackedVector2Array([
		Vector2(40.0, -26.0), Vector2(55.0, -22.0), Vector2(63.0, -12.0), Vector2(65.0, 0.0),
		Vector2(63.0, 12.0), Vector2(55.0, 22.0), Vector2(40.0, 26.0), Vector2(36.0, 14.0),
		Vector2(36.0, -14.0)])
	lm.poly_prism("Coral", hull, -0.4, 3.4)
	var inner := PackedVector2Array([
		Vector2(41.5, -22.0), Vector2(54.0, -19.0), Vector2(60.0, -10.0), Vector2(61.5, 0.0),
		Vector2(60.0, 10.0), Vector2(54.0, 19.0), Vector2(41.5, 22.0), Vector2(39.0, 12.0),
		Vector2(39.0, -12.0)])
	lm.poly_prism("Gravel", inner, 3.4, 3.7)
	# Balustrade around deck edge
	for i: int in hull.size():
		var a := hull[i]
		var b := hull[(i + 1) % hull.size()]
		var d := b - a
		var n := maxi(int(d.length() / 1.6), 1)
		for j: int in n:
			var p := a + d * ((float(j) + 0.5) / float(n))
			lm.box("Coral", Vector3(p.x, 4.0, p.y), Vector3(0.45, 1.2, 0.45), Basis(), 0.0)
		lm.beam("Coral", Vector3(a.x, 4.7, a.y), Vector3(b.x, 4.7, b.y), 0.4, 0.3)
	# Curved prow obelisks and mermaid herms
	for sz: float in [-1.0, 1.0]:
		lm.box("Coral", Vector3(57.0, 4.4, sz * 20.0), Vector3(1.6, 1.4, 1.6))
		lm.spire("Coral", Vector3(57.0, 5.1, sz * 20.0), 0.7, 1.7, 0.0, 4)
		lm.box("Coral", Vector3(62.0, 4.4, sz * 8.0), Vector3(1.2, 1.4, 1.2))
		lm.frustum("Coral", Vector3(62.0, 5.1, sz * 8.0), 0.45, 0.3, 1.5, 8)
	lm.box("Coral", Vector3(64.0, 4.6, 0.0), Vector3(1.6, 1.8, 1.6))
	lm.spire("Coral", Vector3(64.0, 5.5, 0.0), 0.8, 1.3, 0.0, 4)
	# Central stone throne/exedra with obelisk top reaching 6.8 m
	lm.box("Coral", Vector3(48.0, 4.2, 0.0), Vector3(4.0, 1.0, 10.0))
	for sz: float in [-1.0, 1.0]:
		lm.box("Coral", Vector3(48.0, 5.4, sz * 4.0), Vector3(1.4, 2.6, 1.4))
		lm.spire("Coral", Vector3(48.0, 6.7, sz * 4.0), 0.55, 0.1, 0.0, 4)
	# Lattice Tea House pavilion on the barge, west end
	lm.box("Coral", Vector3(43.5, 3.7, 0.0), Vector3(5.0, 0.4, 5.0), Basis(), 0.0)
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			lm.beam("Wood", Vector3(43.5 + sx * 2.2, 3.9, sz * 2.2), Vector3(43.5 + sx * 2.2, 6.2, sz * 2.2), 0.2, 0.2)
	for k: int in 4:
		var o := -1.5 + float(k) * 1.0
		lm.beam("Wood", Vector3(43.5 + o, 6.0, -2.3), Vector3(43.5 + o, 6.0, 2.3), 0.1, 0.1)
	lm.spire("Tile", Vector3(43.5, 6.2, 0.0), 3.2, 0.6, 0.0, 4)
