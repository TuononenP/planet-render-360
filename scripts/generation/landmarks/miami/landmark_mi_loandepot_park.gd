class_name LandmarkMiLoandepotPark
extends RefCounted

## loanDepot park - Little Havana, Miami (MI-6.5).
## Site: relation:8736190 (25.778141, -80.219881), yaw_deg 0.2, 248 x 210 m, height 68.0 m,
## skyline_priority 2. Architects: Populous (2012).
##   - Concrete/stucco bowl and concourses, green turf (#2E6F38) with clay diamond basepaths.
##   - Three stacked white steel-truss arched retractable roof panels (y = 52..68.0 m)
##     parked over the west half on east-west runway tracks; panel crest exactly 68.0 m.
##   - Left-field operable glass curtain wall (east side) facing downtown.
##   - Four white cylindrical spiral pedestrian ramp drums at the corners; light banks (FieldLamp).

const HEIGHT_M := 68.0

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#D4D2CB", 5.0))
	lm.use("WhiteStucco", LandmarkMaterials.pbr("render", "#F2F2EE", 6.0))
	lm.use("Seat", LandmarkMaterials.paint("#2F4F7A", 0.55, 0.05))
	lm.use("Turf", LandmarkMaterials.paint("#2E6F38", 0.90, 0.0))
	lm.use("Clay", LandmarkMaterials.paint("#B5703F", 0.92, 0.0))
	lm.use("RoofWhite", LandmarkMaterials.paint("#F4F5F7", 0.40, 0.30))
	lm.use("Truss", LandmarkMaterials.paint("#DDE1E5", 0.40, 0.50))
	lm.use("Glass", LandmarkMaterials.glass("#2A5870"))
	lm.use("FieldLamp", LandmarkMaterials.lit("#FFF4D8", 2.6))

	lm.poly_prism("Concrete", _oct(124.0, 105.0, 20.0), -0.4, 1.0)
	lm.box("Turf", Vector3(0.0, 1.05, 0.0), Vector3(120.0, 0.1, 100.0))
	# Clay diamond: basepath square turned 45 degrees plus home dirt arc and mound
	var d := PackedVector2Array([Vector2(0, -27), Vector2(27, 0), Vector2(0, 27), Vector2(-27, 0)])
	lm.poly_prism("Clay", d, 1.08, 1.14)
	var dd := PackedVector2Array([Vector2(0, -23), Vector2(23, 0), Vector2(0, 23), Vector2(-23, 0)])
	lm.poly_prism("Turf", dd, 1.14, 1.2)
	lm.frustum("Clay", Vector3(0.0, 1.1, 0.0), 3.0, 3.0, 0.2, 12)
	for b: Vector2 in [Vector2(27, 0), Vector2(0, 27), Vector2(-27, 0), Vector2(0, -27)]:
		lm.box("WhiteStucco", Vector3(b.x, 1.3, b.y), Vector3(1.4, 0.2, 1.4), Basis(), 0.0)
	# Seating bowl, three decks
	for i: int in 9:
		var t := float(i) / 8.0
		_ring(lm, "Seat", lerpf(66.0, 98.0, t), lerpf(56.0, 84.0, t), 2.4, lerpf(3.0, 36.0, t), 1.8)
	_ring(lm, "Concrete", 100.0, 86.0, 3.0, 20.0, 12.0)
	# Exterior stucco screens (west, north, south solid; east is glass)
	for sz: float in [-1.0, 1.0]:
		lm.box("WhiteStucco", Vector3(0.0, 20.0, sz * 104.0), Vector3(220.0, 40.0, 2.4))
	lm.box("WhiteStucco", Vector3(-123.0, 20.0, 0.0), Vector3(2.4, 40.0, 180.0))
	lm.box("Glass", Vector3(123.0, 22.0, 0.0), Vector3(1.0, 34.0, 160.0))
	for k: int in 17:
		lm.box("Truss", Vector3(124.0, 22.0, -80.0 + 10.0 * float(k)), Vector3(0.5, 34.0, 0.6))
	# Corner spiral ramp drums
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			var rc := Vector3(sx * 112.0, -0.2, sz * 93.0)
			lm.frustum("WhiteStucco", rc, 12.0, 11.0, 38.0, 16)
			var prev := Vector3.ZERO
			for s: int in 41:
				var a := float(s) / 40.0 * TAU * 2.5 * sx
				var p := rc + Vector3(cos(a) * 12.6, 3.0 + float(s) * 0.82, sin(a) * 12.6)
				if s > 0:
					lm.beam("Truss", prev, p, 1.6, 0.6)
				prev = p
	# Runway tracks along east-west (x) on both long sides
	for sz: float in [-1.0, 1.0]:
		lm.box("Truss", Vector3(0.0, 51.4, sz * 100.0), Vector3(236.0, 1.2, 3.0))
		for cx: float in [-110.0, -66.0, -22.0, 22.0, 66.0, 110.0]:
			lm.box("Concrete", Vector3(cx, 25.5, sz * 100.0), Vector3(2.4, 51.0, 2.4))
		lm.box("FieldLamp", Vector3(0.0, 53.2, sz * 98.8), Vector3(120.0, 0.8, 0.3))
	# Three arched retractable roof panels stacked over the west side
	var tops := [68.0, 66.0, 64.0]
	for p: int in 3:
		var x0 := -112.0 + float(p) * 20.0
		var x1 := x0 + 18.0
		var r0 := PackedVector3Array()
		var r1 := PackedVector3Array()
		var peak: float = tops[p]
		for i: int in 11:
			var z := -100.0 + 20.0 * float(i)
			var y := 52.0 + (peak - 52.0) * (1.0 - pow(z / 100.0, 2.0))
			r0.append(Vector3(x0, y, z))
			r1.append(Vector3(x1, y, z))
		var rows: Array = [r0, r1]
		lm.grid("RoofWhite", rows, Vector3.UP)
		for xr: float in [x0, x1]:
			var prev := Vector3.ZERO
			for i: int in 11:
				var z := -100.0 + 20.0 * float(i)
				var y := 52.0 + (peak - 52.0) * (1.0 - pow(z / 100.0, 2.0)) - 1.2
				var q := Vector3(xr, y, z)
				if i > 0:
					lm.beam("Truss", prev, q, 0.8, 1.2)
				prev = q
	lm.commit(model)

	var white := Color(1.0, 0.96, 0.86)
	var blue := Color(0.55, 0.78, 1.0)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-30.0, 51.0, -98.0), Vector3(0.0, 1.5, 0.0), 120.0, 1.6, 85.0, white],
		[Vector3(30.0, 51.0, 98.0), Vector3(0.0, 1.5, 0.0), 120.0, 1.6, 85.0, white],
		[Vector3(60.0, 51.0, -98.0), Vector3(0.0, 1.5, 0.0), 120.0, 1.4, 85.0, white],
		[Vector3(150.0, 4.0, 0.0), Vector3(123.0, 22.0, 0.0), 60.0, 1.1, 80.0, blue],
	])

static func _oct(hx: float, hz: float, c: float) -> PackedVector2Array:
	return PackedVector2Array([Vector2(-hx + c, -hz), Vector2(hx - c, -hz), Vector2(hx, -hz + c),
		Vector2(hx, hz - c), Vector2(hx - c, hz), Vector2(-hx + c, hz), Vector2(-hx, hz - c),
		Vector2(-hx, -hz + c)])

static func _ring(lm: LandmarkMesh, key: String, hx: float, hz: float, thick: float,
		yc: float, h: float) -> void:
	for sz: float in [-1.0, 1.0]:
		lm.box(key, Vector3(0.0, yc, sz * hz), Vector3((hx - 6.0) * 2.0, h, thick))
	for sx: float in [-1.0, 1.0]:
		lm.box(key, Vector3(sx * hx, yc, 0.0), Vector3(thick, h, (hz - 6.0) * 2.0))
