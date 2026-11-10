class_name CarModel
extends RefCounted

## Procedural parked cars: one cached mesh per kind and level of detail,
## built from its CarSpecs spec. The body is one loft (VehicleKit.body)
## with glass, lamps and trim as regions of it; wheels, mirrors, handles
## and plates are added near to. Paint is the instance colour (CarPaint);
## every other surface is a shared material. A car faces +X, centred on
## its footprint, wheels on y = 0 (metres).

static var _meshes := {}
static var _materials := {}

static func mesh(kind: String, far: bool = false) -> ArrayMesh:
	var id := kind + ("_far" if far else "")
	if _meshes.has(id):
		return _meshes[id]
	var s := CarSpecs.spec(kind)
	var lm := LandmarkMesh.new()
	lm.use("Paint", paint(kind))
	for key in ["Glass", "Trim", "Rubber", "Rim", "HeadLamp", "TailLamp", "Plate"]:
		lm.use(key, material(key))
	VehicleKit.body(lm, s, far)
	var r := float(s["wheel_r"])
	var tw := float(s["tyre_w"])
	for ax: float in [float(s["axle_f"]), float(s["axle_r"])]:
		var z := VehicleKit.half_width(s, ax) - tw * 0.5 - 0.02
		for side: float in [1.0, -1.0]:
			VehicleKit.wheel(lm, Vector3(ax, r, side * z), r, tw, side, far, int(s["spokes"]))
	if not far:
		_fittings(lm, s)
	var out := lm.to_array_mesh(false)
	_meshes[id] = out
	return out

## Mirrors, door handles, number plates and the roof aerial.
static func _fittings(lm: LandmarkMesh, s: Dictionary) -> void:
	var half := float(s["len"]) * 0.5
	var gh: PackedFloat32Array = s["gh"]
	var doors: PackedFloat32Array = s["doors"]
	var mx := gh[3] - 0.3
	var belt := VehicleKit.soft(s["belt"], mx, 0.1)
	var w := VehicleKit.half_width(s, mx)
	for side: float in [1.0, -1.0]:
		VehicleKit.blob(lm, "Paint", Vector3(mx, belt + 0.1, side * (w + 0.06)), Vector3(0.07, 0.06, 0.1))
		lm.box("Trim", Vector3(mx, belt + 0.05, side * (w - 0.03)), Vector3(0.06, 0.03, 0.12), Basis(), 0.0)
		for x: float in [doors[1] + 0.14, doors[0] + 0.14]:
			var hb := VehicleKit.soft(s["belt"], x, 0.1)
			lm.box("Trim", Vector3(x, hb - 0.09, side * (VehicleKit.half_width(s, x) * 0.985)),
				Vector3(0.17, 0.028, 0.03), Basis(), 0.0)
	for end: float in [1.0, -1.0]:
		var fl := VehicleKit.soft(s["floor"], end * half, 0.06)
		var top := VehicleKit.soft(s["belt"], end * half, 0.1)
		var y := lerpf(fl, top, 0.3 if end > 0.0 else 0.5)
		lm.box("Plate", Vector3(end * (half - 0.004), y, 0.0), Vector3(0.02, 0.11, 0.5), Basis(), 0.0)
	var roof_x := lerpf(gh[1], gh[2], 0.08)
	VehicleKit.blob(lm, "Trim", Vector3(roof_x, VehicleKit.soft(s["roof"], roof_x, 0.07) + 0.02, 0.0),
		Vector3(0.09, 0.035, 0.03), 4, 8)

## The body paint of `kind`: CarPaint with the kind's shut lines.
static func paint(kind: String) -> ShaderMaterial:
	var id := "Paint_" + kind
	if _materials.has(id):
		return _materials[id]
	var s := CarSpecs.spec(kind)
	var half := float(s["len"]) * 0.5
	var gh: PackedFloat32Array = s["gh"]
	var side := PackedVector4Array()
	var sill := float(s["clear"]) + 0.07
	for x: float in (s["doors"] as PackedFloat32Array):
		side.append(Vector4(x, sill, x, VehicleKit.soft(s["belt"], x, 0.1)))
	var doors: PackedFloat32Array = s["doors"]
	side.append(Vector4(doors[0], sill, doors[2], sill))
	var top := PackedVector4Array()
	var wf := VehicleKit.half_width(s, gh[3]) - 0.12
	top.append(Vector4(gh[3] + 0.05, 0.0, gh[3] + 0.02, wf))
	top.append(Vector4(gh[3] + 0.02, wf, half - 0.32, wf - 0.04))
	if gh[0] - 0.4 > -half:
		var wb := VehicleKit.half_width(s, gh[0]) - 0.14
		top.append(Vector4(gh[0] - 0.05, 0.0, gh[0] - 0.03, wb))
		top.append(Vector4(gh[0] - 0.03, wb, -half + 0.12, wb - 0.03))
	var m := ShaderMaterial.new()
	m.shader = CarPaint.shader()
	m.set_shader_parameter("seam_side", side)
	m.set_shader_parameter("seam_side_n", side.size())
	m.set_shader_parameter("seam_top", top)
	m.set_shader_parameter("seam_top_n", top.size())
	_materials[id] = m
	return m

## The shared material of a non-paint surface key.
static func material(key: String) -> StandardMaterial3D:
	if _materials.has(key):
		return _materials[key]
	var m := StandardMaterial3D.new()
	match key:
		"Glass":
			# Smooth, dark glass: a strong grazing (Fresnel) mirror of the sky
			# and the street, the cabin dark behind it face on.
			m.albedo_color = Color(0.03, 0.04, 0.05)
			m.roughness = 0.04
			m.metallic_specular = 0.6
		"Trim":
			m.albedo_color = Color(0.035, 0.035, 0.038)
			m.roughness = 0.5
		"Rubber":
			m.albedo_color = Color(0.025, 0.025, 0.025)
			m.roughness = 0.95
		"Rim":
			m.albedo_color = Color(0.62, 0.64, 0.66)
			m.metallic = 0.85
			m.roughness = 0.32
		"HeadLamp":
			# A clear lens over a bright reflector.
			m.albedo_color = Color(0.8, 0.83, 0.85)
			m.metallic = 0.6
			m.roughness = 0.12
			m.clearcoat_enabled = true
			m.clearcoat = 1.0
			m.clearcoat_roughness = 0.03
		"TailLamp":
			m.albedo_color = Color(0.42, 0.02, 0.018)
			m.roughness = 0.12
			m.clearcoat_enabled = true
			m.clearcoat = 1.0
			m.clearcoat_roughness = 0.03
		"Plate":
			m.albedo_color = Color(0.8, 0.8, 0.78)
			m.roughness = 0.5
	_materials[key] = m
	return m
