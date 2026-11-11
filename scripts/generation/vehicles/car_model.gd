class_name CarModel
extends RefCounted

## Procedural parked cars: one cached mesh per kind and level of detail,
## built from its CarSpecs spec. The body is one loft (VehicleKit.body)
## with glass, lamps and trim as regions of it; wheels, mirrors, handles
## and plates are added near to. Paint is the instance colour (CarPaint);
## every other surface is a shared material. A car faces +X, centred on
## its footprint, wheels on y = 0 (metres).

## Where the lamp's inner edge falls across the end face (share of the half
## width, the ring VehicleKit.body lofts), nose and tail.
const LAMP_K_F := 0.68
const LAMP_K_R := 0.45
## The bumper lip's reach, and the slats' pitch in the drawn openings (metres).
const LIP_M := 0.022
const SLAT_M := 0.016

static var _meshes := {}
static var _materials := {}

static func mesh(kind: String, far: bool = false) -> ArrayMesh:
	var id := kind + ("_far" if far else "")
	if _meshes.has(id):
		return _meshes[id]
	var s := CarSpecs.spec(kind)
	var lm := LandmarkMesh.new()
	lm.use("Paint", paint(kind))
	for key in ["Glass", "Trim", "Rubber", "Rim", "HeadLamp", "TailLamp", "Plate", "Sign", "Chrome", "Amber"]:
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

## Mirrors, door handles, a cab's roof sign, the aerial, roof rails, wipers
## and what stands on each end face (_end_face).
static func _fittings(lm: LandmarkMesh, s: Dictionary) -> void:
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
		_end_face(lm, s, end)
	if bool(s["sign"]):
		var sx := lerpf(gh[1], gh[2], 0.7)
		lm.box("Sign", Vector3(sx, VehicleKit.soft(s["roof"], sx, 0.07) + 0.06, 0.0),
			Vector3(0.14, 0.12, 0.34), Basis(), 0.02)
	_wipers(lm, s)
	if bool(s["rails"]):
		_rails(lm, s)
	var roof_x := lerpf(gh[1], gh[2], 0.08)
	VehicleKit.blob(lm, "Trim", Vector3(roof_x, VehicleKit.soft(s["roof"], roof_x, 0.07) + 0.02, 0.0),
		Vector3(0.09, 0.035, 0.03), 4, 8)

## The number plate in its frame, the lamps' lens detail, the bumper lip
## and (at the tail) the exhaust of end face `end` (+1 nose, -1 tail), each
## a few centimetres proud of the body.
static func _end_face(lm: LandmarkMesh, s: Dictionary, end: float) -> void:
	var front := end > 0.0
	var tp := 0.3 if front else 0.5
	var pf := VehicleKit.end_frame(s, end, 0.0, tp)
	var pp := VehicleKit.end_at(s, end, 0.0, tp)
	lm.box("Trim", pp + pf.x * 0.001, Vector3(0.016, 0.135, 0.545), pf, 0.0)
	lm.box("Plate", pp + pf.x * 0.004, Vector3(0.02, 0.11, 0.52), pf, 0.0)
	var lamp: Vector2 = s["lamp_f"] if front else s["lamp_r"]
	var tm := (lamp.x + lamp.y) * 0.5
	for side: float in [1.0, -1.0]:
		if front:
			# A projector: a dark ring round a bright lens, an indicator beyond.
			var k := side * 0.8
			var f := VehicleKit.end_frame(s, end, k, tm)
			var p := VehicleKit.end_at(s, end, k, tm)
			lm.disc("Trim", p + f.x * 0.004, f.x, 0.034, 14)
			lm.disc("HeadLamp", p + f.x * 0.008, f.x, 0.02, 12)
			var ki := side * 0.92
			var fi := VehicleKit.end_frame(s, end, ki, lerpf(lamp.x, lamp.y, 0.25))
			lm.box("Amber", VehicleKit.end_at(s, end, ki, lerpf(lamp.x, lamp.y, 0.25)) + fi.x * 0.004,
				Vector3(0.012, 0.03, 0.07), fi, 0.0)
		else:
			var ki := side * 0.82
			var ty := lerpf(lamp.x, lamp.y, 0.25)
			var fi := VehicleKit.end_frame(s, end, ki, ty)
			lm.box("Amber", VehicleKit.end_at(s, end, ki, ty) + fi.x * 0.004, Vector3(0.012, 0.03, 0.08), fi, 0.0)
			var kr := side * 0.6
			var fr := VehicleKit.end_frame(s, end, kr, ty)
			lm.box("Plate", VehicleKit.end_at(s, end, kr, ty) + fr.x * 0.004, Vector3(0.012, 0.03, 0.08), fr, 0.0)
	_lip(lm, s, end)
	if not front:
		var ep := VehicleKit.end_at(s, end, 0.6, 0.08)
		lm.beam("Chrome", ep + Vector3(0.08, 0.0, 0.0), ep + Vector3(-0.02, 0.0, 0.0), 0.05, 0.04, Vector3.UP, true)

## A bumper lip under the nose or tail, tapering out along the flank.
static func _lip(lm: LandmarkMesh, s: Dictionary, end: float) -> void:
	var base: Array[Vector3] = []
	var rows: Array = []
	for k: float in [0.0, 0.3, 0.6, 0.8, 0.92, 1.0]:
		base.append(VehicleKit.end_at(s, end, k, 0.0))
	var xs := end * (float(s["len"]) * 0.5 - (float(s["bulge_f"]) if end > 0.0 else float(s["bulge_r"])))
	var out: Array[float] = [1.0, 1.0, 1.0, 1.0, 1.0, 1.0]
	for i in 3:
		var x := xs - end * 0.1 * float(i + 1)
		var w := VehicleKit.half_width(s, x) * VehicleKit.lin(s["bulge"], 0.0)
		base.append(Vector3(x, VehicleKit.soft(s["floor"], x, 0.06), w))
		out.append(1.0 - float(i + 1) / 3.0)
	for row in 3:
		var t: float = [0.12, 0.06, 0.0][row]
		var reach: float = [0.0, 1.0, 0.8][row]
		var pts := PackedVector3Array()
		for i in base.size():
			var j := mini(i + 1, base.size() - 1)
			var h := maxi(i - 1, 0)
			var tan := base[j] - base[h]
			var n := Vector3(tan.z, 0.0, -tan.x).normalized() * end
			var p := base[i]
			if i < 6:
				p = VehicleKit.end_at(s, end, [0.0, 0.3, 0.6, 0.8, 0.92, 1.0][i], t)
			else:
				p = Vector3(p.x, lerpf(VehicleKit.soft(s["floor"], p.x, 0.06), VehicleKit.soft(s["belt"], p.x, 0.1), t), p.z)
			pts.append(p + n * (LIP_M * reach * out[i]))
		rows.append(pts)
	VehicleKit.skin(lm, rows, func(_r: int, _c: int) -> String: return "Trim", [], true, end > 0.0)

## Two wiper blades parked along the foot of the windscreen.
static func _wipers(lm: LandmarkMesh, s: Dictionary) -> void:
	var gh: PackedFloat32Array = s["gh"]
	var x := gh[3] - 0.13
	for side: float in [1.0, -1.0]:
		var a := Vector3(x, VehicleKit.roof_at(s, x, 0.06) + 0.006, side * 0.06)
		var b := Vector3(x - 0.01, VehicleKit.roof_at(s, x, 0.62) + 0.006, side * 0.62)
		lm.beam("Trim", a, b, 0.014, 0.008, Vector3.UP)

## Roof rails along a wagon's or SUV's roof.
static func _rails(lm: LandmarkMesh, s: Dictionary) -> void:
	var gh: PackedFloat32Array = s["gh"]
	var x0 := gh[1] + 0.3
	var x1 := gh[2] - 0.1
	var xm := lerpf(gh[1], gh[2], 0.45)
	for side: float in [1.0, -1.0]:
		var z := side * 0.5
		var pts: Array[Vector3] = []
		for x: float in [x0, xm, x1]:
			pts.append(Vector3(x, VehicleKit.roof_at(s, x, z) + 0.02, z))
		for i in 2:
			lm.beam("Trim", pts[i], pts[i + 1], 0.03, 0.028, Vector3.UP, i == 0)
		lm.box("Trim", pts[2] + Vector3(0.0, 0.0, 0.0), Vector3(0.03, 0.028, 0.03), Basis(), 0.0)

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
	m.set_shader_parameter("face", _face(s))
	m.set_shader_parameter("seam_side", side)
	m.set_shader_parameter("seam_side_n", side.size())
	m.set_shader_parameter("seam_top", top)
	m.set_shader_parameter("seam_top_n", top.size())
	m.set_shader_parameter("livery_y", float(s["livery_y"]))
	m.set_shader_parameter("livery_col", s["livery_col"])
	_materials[id] = m
	return m

## What CarPaint draws on the end faces, front rows then rear (see its
## `face`): the lamp rectangle (inner z, y low, y high, outer z), the upper
## grille (half width, y low, y high, slats) and the lower intake (the
## same), the plate recess (y, half height, half width) and the lines (the
## bumper split y, the bonnet edge y and its half width). Zero where a face
## has none.
static func _face(s: Dictionary) -> PackedVector4Array:
	var out := PackedVector4Array()
	for end: float in [1.0, -1.0]:
		var front := end > 0.0
		var lamp: Vector2 = s["lamp_f"] if front else s["lamp_r"]
		var span := lamp.y - lamp.x
		var lk := LAMP_K_F if front else LAMP_K_R
		var y0 := VehicleKit.end_at(s, end, 0.0, lamp.x).y
		var y1 := VehicleKit.end_at(s, end, 0.0, lamp.y).y
		var lm_t := (lamp.x + lamp.y) * 0.5
		out.append(Vector4(VehicleKit.end_at(s, end, lk, lm_t).z, y0, y1, VehicleKit.end_at(s, end, 1.0, lm_t).z))
		var gt: Vector2 = s["grille"]
		var grille := Vector4()
		var intake := Vector4()
		var lines := Vector4(VehicleKit.end_at(s, end, 0.0, lamp.x - 0.05).y, -1.0, 0.0, 0.0)
		if front:
			var g0 := VehicleKit.end_at(s, end, 0.0, lamp.x + 0.12 * span).y
			grille = Vector4(VehicleKit.end_at(s, end, lk, lamp.x).z - 0.03, g0, y1,
				maxf(2.0, roundf((y1 - g0) / SLAT_M * 0.7)))
			var i0 := VehicleKit.end_at(s, end, 0.0, gt.x).y
			var i1 := VehicleKit.end_at(s, end, 0.0, gt.y).y
			intake = Vector4(VehicleKit.end_at(s, end, 0.86, gt.y).z, i0, i1, maxf(2.0, roundf((i1 - i0) / 0.022)))
			lines = Vector4(VehicleKit.end_at(s, end, 0.0, (gt.y + lamp.x) * 0.5).y,
				VehicleKit.end_at(s, end, 0.0, 0.93).y, VehicleKit.end_at(s, end, 0.8, 0.93).z, 0.0)
		out.append(grille)
		out.append(intake)
		out.append(Vector4(VehicleKit.end_at(s, end, 0.0, 0.3 if front else 0.5).y, 0.0725, 0.285, 0.0))
		out.append(lines)
	return out

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
			m.albedo_color = Color(0.36, 0.39, 0.42)
			m.metallic = 0.6
			m.roughness = 0.08
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
		"Chrome":
			m.albedo_color = Color(0.7, 0.72, 0.74)
			m.metallic = 1.0
			m.roughness = 0.2
		"Amber":
			m.albedo_color = Color(0.9, 0.38, 0.03)
			m.roughness = 0.4
		"Sign":
			m.albedo_color = Color(0.9, 0.78, 0.25)
			m.roughness = 0.35
	_materials[key] = m
	return m
