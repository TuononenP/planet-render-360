class_name LandmarkMiMbOldCityHall
extends RefCounted

## Miami Beach Old City Hall (Martin L. Hampton, 1927) - MI-4C.
## Site: 1130 Washington Ave, way 436108380 (25.782624, -80.132643, yaw_deg -78.9),
## footprint 51.6 x 15.8 m, height_m = 42.9. Two-storey Mediterranean Revival civic base with a
## coral-stone arched loggia, rising into a slender 9-storey cream-buff stucco tower with
## cast-stone quoins, an arched belfry loggia, a clay barrel-tile octagonal cupola dome and a
## bronze finial at exactly 42.9 m. The belfry openings glow warmly (BelfryLamp) at night.

const HEIGHT_M := 42.9
const HW := 25.8
const HD := 7.9
const TX := -6.0

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stucco", LandmarkMaterials.pbr("render", "#E8D9B8", 4.0))
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#D9C7A0", 2.8))
	lm.use("Glass", LandmarkMaterials.glass("#26323A"))
	lm.use("Tile", LandmarkMaterials.pbr("terracotta", "#B5562F", 2.0))
	lm.use("Bronze", LandmarkMaterials.paint("#6A4E2A", 0.4, 0.8))
	lm.use("BelfryLamp", LandmarkMaterials.lit("#FFC878", 1.0))
	_base(lm)
	_loggia(lm)
	_tower(lm)
	_cupola(lm)
	lm.commit(model)
	var warm := Color(1.0, 0.82, 0.55)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(TX, 2.0, 22.0), Vector3(TX, 30.0, 0.0), 58.0, 1.2, 60.0, warm],
		[Vector3(-30.0, 2.0, 18.0), Vector3(-10.0, 10.0, HD), 60.0, 1.0, 40.0, warm],
		[Vector3(20.0, 2.0, 18.0), Vector3(10.0, 8.0, HD), 60.0, 1.0, 40.0, warm],
	])

static func _base(lm: LandmarkMesh) -> void:
	lm.box("Stucco", Vector3(0.0, 4.8, 0.0), Vector3(2.0 * HW, 9.6, 2.0 * HD), Basis(), 0.03)
	lm.box("Stone", Vector3(0.0, 9.85, 0.0), Vector3(2.0 * HW + 0.2, 0.5, 2.0 * HD + 0.4), Basis(), 0.0)
	LandmarkMiKit.barrel_tile_strip(lm, "Tile", Vector2(-HW, HD), Vector2(HW, HD), 10.1, 12.4, 7.0, Vector2(0.0, 1.0))
	LandmarkMiKit.barrel_tile_strip(lm, "Tile", Vector2(HW, -HD), Vector2(-HW, -HD), 10.1, 12.4, 7.0, Vector2(0.0, -1.0))
	for k in 9:
		var x: float = -20.0 + 5.0 * float(k)
		lm.box("Glass", Vector3(x, 8.0, HD + 0.05), Vector3(1.4, 1.8, 0.2), Basis(), 0.0)

static func _loggia(lm: LandmarkMesh) -> void:
	for k in 9:
		var x: float = -20.0 + 5.0 * float(k)
		lm.box("Glass", Vector3(x, 2.5, HD + 0.08), Vector3(2.6, 4.4, 0.2), Basis(), 0.0)
		lm.disc("Glass", Vector3(x, 4.7, HD + 0.2), Vector3.BACK, 1.3, 16)
		lm.box("Stone", Vector3(x + 2.5, 3.1, HD + 0.2), Vector3(1.0, 6.2, 0.5), Basis(), 0.0)
		var pts := PackedVector3Array()
		for j in 9:
			var th: float = PI * float(j) / 8.0
			pts.append(Vector3(x + cos(th) * 1.45, 4.7 + sin(th) * 1.45, HD + 0.3))
		for j in 8:
			lm.beam("Stone", pts[j], pts[j + 1], 0.25, 0.35, Vector3.BACK)
	lm.box("Stone", Vector3(-22.5, 3.1, HD + 0.2), Vector3(1.0, 6.2, 0.5), Basis(), 0.0)

static func _tower(lm: LandmarkMesh) -> void:
	lm.box("Stucco", Vector3(TX, 22.8, 0.0), Vector3(9.0, 26.4, 9.0), Basis(), 0.03)
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			for k in 20:
				var w: float = 1.0 if k % 2 == 0 else 0.7
				lm.box("Stone", Vector3(TX + sx * 4.5, 10.2 + 1.25 * float(k), sz * 4.5),
					Vector3(w, 1.1, w), Basis(), 0.0)
	for side in 4:
		var ang: float = float(side) * PI * 0.5
		var n3 := Vector3(sin(ang), 0.0, cos(ang))
		var t3 := Vector3(cos(ang), 0.0, -sin(ang))
		var basis := Basis(t3, Vector3.UP, n3)
		var c0 := Vector3(TX, 0.0, 0.0)
		for r in 6:
			var y: float = 13.0 + 3.0 * float(r)
			for off: float in [-1.5, 1.5]:
				lm.box("Glass", c0 + Vector3(0.0, y, 0.0) + n3 * 4.55 + t3 * off, Vector3(1.0, 1.8, 0.12), basis, 0.0)
		# Belfry loggia: three arched openings per face (y = 30.5..35.5)
		for off: float in [-2.6, 0.0, 2.6]:
			var pos := c0 + Vector3(0.0, 33.0, 0.0) + n3 * 4.55 + t3 * off
			lm.box("BelfryLamp", pos, Vector3(1.4, 4.0, 0.12), basis, 0.0)
			lm.disc("BelfryLamp", pos + Vector3(0.0, 2.0, 0.0) + n3 * 0.02, n3, 0.7, 12)
	lm.box("Stone", Vector3(TX, 36.2, 0.0), Vector3(10.2, 0.8, 10.2), Basis(), 0.0)

static func _cupola(lm: LandmarkMesh) -> void:
	lm.poly_prism("Stucco", TowerSpec.plan("chamfer", 6.0, 6.0, 1.8, TX, 0.0), 36.6, 39.0)
	lm.lathe("Tile", Vector3(TX, 39.0, 0.0), PackedVector2Array([
		Vector2(3.1, 0.0), Vector2(3.0, 0.6), Vector2(2.5, 1.7), Vector2(1.6, 2.6),
		Vector2(0.7, 3.2), Vector2(0.25, 3.5)]), 8, 1.0, 1.0, 0.0, false)
	lm.frustum("Bronze", Vector3(TX, 42.5, 0.0), 0.18, 0.0, 0.4, 8)
