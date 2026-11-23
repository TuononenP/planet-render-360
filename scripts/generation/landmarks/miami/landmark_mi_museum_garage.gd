class_name LandmarkMiMuseumGarage
extends RefCounted

## Museum Garage & Fly's Eye Dome - Miami Design District (MI-6.5).
## Site: way:700376947 (25.813977, -80.194012), yaw_deg -2.8, footprint 124.2 x 36.0 m, 26.0 m.
##   - Seven-storey garage (roof exactly 26.0 m) with five sculptural front bays (+z):
##     WORKac pink perforated diagonal stair, J. Mayer H. red/blue/white striped XOX bay,
##     Clavel gold & crimson hanging cars, Nicolas Buffe dark/white arcade, K/R orange/chrome bars.
##   - Buckminster Fuller white geodesic Fly's Eye Dome (9.5 m sphere, porthole oculi) in the plaza.

const HEIGHT_M := 26.0
const BAY_W := 24.8
const FRONT_Z := 8.0

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#BAB8B1", 4.0))
	lm.use("Pink", LandmarkMaterials.paint("#F26FA8", 0.55, 0.05))
	lm.use("Red", LandmarkMaterials.paint("#D6262B", 0.5, 0.05))
	lm.use("Blue", LandmarkMaterials.paint("#2447B8", 0.5, 0.05))
	lm.use("White", LandmarkMaterials.paint("#F2F2F0", 0.5, 0.05))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.use("Dark", LandmarkMaterials.paint("#2B2D31", 0.6, 0.2))
	lm.use("Orange", LandmarkMaterials.paint("#F08A1C", 0.5, 0.1))
	lm.use("Chrome", LandmarkMaterials.paint("#D6DBE0", 0.2, 0.9))
	lm.use("Oculus", LandmarkMaterials.glass("#294052"))
	lm.use("FacadeLamp", LandmarkMaterials.lit("#FFE2B0", 1.6))

	lm.box("Concrete", Vector3(0.0, -0.1, 5.0), Vector3(124.2, 0.5, 26.0))
	# Garage core: floor slabs and roof slab (top = 26.0 m)
	lm.box("Concrete", Vector3(0.0, 12.7, -5.0), Vector3(124.2, 25.4, 26.0))
	lm.box("Concrete", Vector3(0.0, 25.7, -5.0), Vector3(124.2, 0.6, 26.0))
	lm.box("FacadeLamp", Vector3(0.0, 25.2, FRONT_Z + 0.25), Vector3(120.0, 0.12, 0.12))
	for b: int in 5:
		var cx := -49.6 + BAY_W * float(b)
		match b:
			0: _pink_bay(lm, cx)
			1: _xox_bay(lm, cx)
			2: _cars_bay(lm, cx)
			3: _arcade_bay(lm, cx)
			_: _bars_bay(lm, cx)
	# Fly's Eye Dome in Palm Court plaza
	var dc := Vector3(0.0, 0.0, 14.0)
	var prof := PackedVector2Array()
	for i: int in 13:
		var a := -PI * 0.5 + PI * float(i) / 12.0
		var r := maxf(cos(a), 0.02) * 4.75
		prof.append(Vector2(r, 4.75 + sin(a) * 4.75 * 0.0 + sin(a) * 4.75))
	lm.lathe("White", dc + Vector3(0, 0.0, 0), prof, 16, 1.0, 1.0, 0.0, true)
	for i: int in 20:
		var f := (float(i) + 0.5) / 20.0
		var yy := 1.0 - 2.0 * f
		var rr := sqrt(1.0 - yy * yy)
		var ang := float(i) * 2.399963
		var n := Vector3(cos(ang) * rr, yy, sin(ang) * rr)
		var pos := dc + Vector3(0, 4.75, 0) + n * 4.78
		if pos.y > 0.8:
			lm.disc("Oculus", pos, n, 0.65, 10)
	lm.commit(model)

	var warm := Color(1.0, 0.86, 0.62)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-40.0, 3.0, 24.0), Vector3(-30.0, 14.0, FRONT_Z), 50.0, 1.3, 70.0, warm],
		[Vector3(0.0, 3.0, 26.0), Vector3(0.0, 5.0, 14.0), 30.0, 1.2, 70.0, Color(0.8, 0.9, 1.0)],
		[Vector3(40.0, 3.0, 24.0), Vector3(30.0, 14.0, FRONT_Z), 50.0, 1.3, 70.0, warm],
	])

static func _pink_bay(lm: LandmarkMesh, cx: float) -> void:
	lm.box("Pink", Vector3(cx, 12.7, FRONT_Z + 0.2), Vector3(BAY_W, 25.0, 0.4), Basis(), 0.0)
	for i: int in 6:
		var x := cx - 9.0 + float(i) * 3.6
		for j: int in 5:
			lm.box("Concrete", Vector3(x, 3.0 + float(j) * 4.6, FRONT_Z + 0.45), Vector3(1.4, 1.4, 0.15), Basis(), 0.0)
	lm.beam("White", Vector3(cx - 11.0, 0.5, FRONT_Z + 1.2), Vector3(cx + 11.0, 24.0, FRONT_Z + 1.2), 1.4, 0.5)

static func _xox_bay(lm: LandmarkMesh, cx: float) -> void:
	var keys := ["Red", "White", "Blue"]
	for i: int in 12:
		var k: String = keys[i % 3]
		lm.box(k, Vector3(cx - 11.4 + float(i) * 2.07, 12.7, FRONT_Z + 0.3), Vector3(2.0, 25.0, 0.6), Basis(), 0.0)
	for j: int in 4:
		lm.box("White", Vector3(cx, 4.0 + float(j) * 6.0, FRONT_Z + 0.75), Vector3(BAY_W * 0.8, 0.7, 0.3), Basis(), 0.0)

static func _cars_bay(lm: LandmarkMesh, cx: float) -> void:
	lm.box("Dark", Vector3(cx, 12.7, FRONT_Z + 0.1), Vector3(BAY_W, 25.0, 0.2), Basis(), 0.0)
	var seed_i := 0
	for i: int in 4:
		for j: int in 3:
			var x := cx - 9.0 + float(i) * 6.0
			var y := 20.5 - float(j) * 7.0 - float(i % 2) * 2.0
			var key := "Gold" if (i + j) % 2 == 0 else "Red"
			lm.beam("Chrome", Vector3(x, y + 2.0, FRONT_Z + 1.6), Vector3(x, 25.2, FRONT_Z + 1.6), 0.1, 0.1)
			lm.box(key, Vector3(x, y, FRONT_Z + 1.6), Vector3(3.6, 1.3, 1.7), Basis(), 0.2)
			lm.box(key, Vector3(x, y + 0.9, FRONT_Z + 1.6), Vector3(2.0, 0.8, 1.5), Basis(), 0.2)
			seed_i += 1

static func _arcade_bay(lm: LandmarkMesh, cx: float) -> void:
	lm.box("Dark", Vector3(cx, 12.7, FRONT_Z + 0.2), Vector3(BAY_W, 25.0, 0.4), Basis(), 0.0)
	for i: int in 7:
		var x := cx - 10.8 + float(i) * 3.6
		lm.box("White", Vector3(x, 6.0, FRONT_Z + 0.9), Vector3(0.8, 12.0, 0.9), Basis(), 0.0)
		lm.box("White", Vector3(x + 1.8, 12.4, FRONT_Z + 0.9), Vector3(2.9, 0.8, 0.9), Basis(), 0.0)
		lm.box("White", Vector3(x, 19.0, FRONT_Z + 0.6), Vector3(0.5, 11.0, 0.5), Basis(), 0.0)

static func _bars_bay(lm: LandmarkMesh, cx: float) -> void:
	lm.box("Concrete", Vector3(cx, 12.7, FRONT_Z + 0.1), Vector3(BAY_W, 25.0, 0.2), Basis(), 0.0)
	for i: int in 24:
		var key := "Orange" if i % 2 == 0 else "Chrome"
		lm.box(key, Vector3(cx - 11.9 + float(i) * 1.04, 12.7, FRONT_Z + 0.7), Vector3(0.5, 25.0, 0.7), Basis(), 0.0)
