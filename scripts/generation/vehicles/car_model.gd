class_name CarModel
extends RefCounted

## Procedural parked cars: one cached mesh per kind and level of detail,
## built from its CarSpecs spec. The body is one loft (VehicleKit.body)
## with glass and trim as regions of it (and the far mesh's lamps); the
## wheels, and near to the lamp clusters, mirrors (CarParts), handles and
## plates are added. Paint is the instance colour (CarPaint);
## every other surface is a shared material. A car faces +X, centred on
## its footprint, wheels on y = 0 (metres).

## The bumper lip's reach, and the slats' pitch in the drawn openings (metres).
const LIP_M := 0.022
const SLAT_M := 0.016

static var _meshes := {}
static var _materials := {}

static func mesh(kind: String, far: bool = false) -> ArrayMesh:
	if kind == "tuk_tuk":
		return TukTukModel.mesh(far)
	var id := kind + ("_far" if far else "")
	if _meshes.has(id):
		return _meshes[id]
	var s := CarSpecs.spec(kind)
	var lm := LandmarkMesh.new()
	lm.use("Paint", paint(kind, far))
	# Near to, the glass shows the cabin behind it; far off it is dark.
	lm.use("Glass", material("Glass" if not far and bool(s["cabin"]) else "GlassDark"))
	for key in ["Trim", "Rubber", "Rim", "HeadLamp", "TailLamp", "Plate", "Sign", "Chrome", "Amber", "Board",
			"Drl", "TailGlow", "Cabin", "Grille", "RimDark", "RimGun"]:
		lm.use(key, material(key))
	VehicleKit.body(lm, s, far)
	var r := float(s["wheel_r"])
	var tw := float(s["tyre_w"])
	for ax: float in [float(s["axle_f"]), float(s["axle_r"])]:
		# Out under the flare, the tyre's face near flush with the arch.
		var z := VehicleKit.half_width(s, ax) + float(s["flare"]) * 0.6 - tw * 0.5 - 0.025
		for side: float in [1.0, -1.0]:
			CarParts.wheel(lm, Vector3(ax, r, side * z), r, tw, side, far, int(s["spokes"]), bool(s["twin"]),
					bool(s["dark_wheels"]), bool(s["sport"]))
	if not far:
		_fittings(lm, s)
		CarDetails.front(lm, s)
		CarDetails.rear(lm, s)
		if bool(s["cabin"]):
			CarDetails.interior(lm, s)
	var out := lm.to_array_mesh(false)
	_meshes[id] = out
	return out

## The near body's glass alone, for a shadow-only batch: see-through
## materials cast no shadow, so sunlight came in at the windows and
## striped the road beside the car. Null when the kind has no glass.
static func glass_shadow_mesh(kind: String) -> ArrayMesh:
	var id := kind + "_glass_shadow"
	if _meshes.has(id):
		return _meshes[id]
	var src := mesh(kind)
	var out: ArrayMesh = null
	for si in src.get_surface_count():
		if src.surface_get_name(si) != "Glass":
			continue
		out = ArrayMesh.new()
		out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, src.surface_get_arrays(si))
		out.surface_set_material(0, material("GlassDark"))
	_meshes[id] = out
	return out

## Mirrors, door handles, a cab's roof sign, the aerial, roof rails, wipers
## and what stands on each end face (_end_face).
static func _fittings(lm: LandmarkMesh, s: Dictionary) -> void:
	var gh: PackedFloat32Array = s["gh"]
	var doors: PackedFloat32Array = s["doors"]
	for side: float in [1.0, -1.0]:
		CarParts.mirror(lm, s, side)
		# One handle for a two-door car (its rear and middle cuts coincide).
		for x: float in ([doors[0] + 0.14] if doors[0] == doors[1] else [doors[1] + 0.14, doors[0] + 0.14]):
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
	if bool(s["mid_engine"]):
		CarDetails.engine(lm, s)
	if bool(s["split"]):
		_split(lm, s)
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
	var tp := float(s["plate_t"]) if front else 0.5
	var pf := VehicleKit.end_frame(s, end, 0.0, tp)
	var pp := VehicleKit.end_at(s, end, 0.0, tp)
	lm.box("Trim", pp + pf.x * 0.001, Vector3(0.016, 0.135, 0.545), pf, 0.0)
	lm.box("Plate", pp + pf.x * 0.004, Vector3(0.02, 0.11, 0.52), pf, 0.0)
	CarDetails.plate_text(lm, pp + pf.x * 0.0155, pf, int(float(s["len"]) * 100.0) + (0 if front else 3))
	CarParts.lamps(lm, s, end, float(s["lamp_k"]) if front else float(s["lamp_k_r"]))
	_lip(lm, s, end)
	if not front:
		# An exhaust tip each side, set in the diffuser where there is one.
		var et := maxf(float(s["valance_r"]) * 0.5, 0.08)
		for side: float in [1.0, -1.0]:
			var ep := VehicleKit.end_at(s, end, side * 0.6, et)
			CarParts.exhaust(lm, ep, end)

## A bumper lip under the nose or tail, tapering out along the flank.
static func _lip(lm: LandmarkMesh, s: Dictionary, end: float) -> void:
	var base: Array[Vector3] = []
	var rows: Array = []
	for k: float in [0.0, 0.3, 0.6, 0.8, 0.92, 1.0]:
		base.append(VehicleKit.end_at(s, end, k, 0.0))
	var xs := end * (float(s["len"]) * 0.5 - (float(s["bulge_f"]) if end > 0.0 else float(s["bulge_r"])))
	var out: Array[float] = [1.0, 1.0, 1.0, 1.0, 1.0, 1.0]
	# The lip runs back along the flank only as far as the arch allows.
	var oh := float(s["front_oh"]) if end > 0.0 else float(s["len"]) * 0.5 + float(s["axle_r"])
	var step := clampf((oh - float(s["arch_r"]) - 0.06) / 3.0, 0.02, 0.1)
	for i in 3:
		var x := xs - end * step * float(i + 1)
		var fl := VehicleKit.soft(s["floor"], x, 0.06)
		var belt := VehicleKit.soft(s["belt"], x, 0.1)
		base.append(Vector3(x, fl, VehicleKit.side_w(s, x, VehicleKit.half_width(s, x), 0.0, fl, belt)))
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
				p = VehicleKit.rake(s, Vector3(p.x, lerpf(VehicleKit.soft(s["floor"], p.x, 0.06),
					VehicleKit.soft(s["belt"], p.x, 0.1), t), p.z))
			pts.append(p + n * (LIP_M * reach * out[i]))
		rows.append(pts)
	VehicleKit.skin(lm, rows, func(_r: int, _c: int) -> String: return "Trim", [], true, end > 0.0)

## Two wipers parked along the foot of the windscreen: a satin blade lying
## on the glass a few centimetres up it, and a dark arm beside it from a
## pivot on the scuttle. Sized to the screen's width (a bus's are long).
static func _wipers(lm: LandmarkMesh, s: Dictionary) -> void:
	var gh: PackedFloat32Array = s["gh"]
	var w := VehicleKit.half_width(s, gh[3])
	var gb := minf(w * VehicleKit.lin(s["bulge"], 1.0) - 0.03 - float(s["shelf"]), w * VehicleKit.lin(s["gh_w"], gh[3]))
	var f := clampf(gb / 0.77, 1.0, 1.6)
	# The blade rides where the screen has risen a few centimetres off its foot.
	var foot := VehicleKit.roof_on_mesh(s, gh[3], gb * 0.4)
	var xb := gh[3]
	while xb > gh[2] and VehicleKit.roof_on_mesh(s, xb, gb * 0.4) - foot < 0.045 * f:
		xb -= 0.005
	var xa := xb
	while xa > gh[2] and VehicleKit.roof_on_mesh(s, xa, gb * 0.4) - foot < 0.08 * f:
		xa -= 0.005
	for side: float in [1.0, -1.0]:
		var blade: Array[Vector3] = []
		# Eight short pieces follow a strongly curved screen; five straight
		# ones left gaps and steps on a coupe's.
		for k in 9:
			blade.append(_on_glass(s, xb, side * gb * lerpf(0.08, 0.8, float(k) / 8.0), 0.011 * f))
		for k in 8:
			var n := _glass_n(s, xb, blade[k].z)
			lm.beam("Trim", blade[k], blade[k + 1], 0.022 * f, 0.014 * f, n, k == 0 or k == 7)
		# The pivot stands on the glass's foot, not past it: on a low nose the
		# bonnet falls away there and the stub would float over it.
		var pivot := _on_glass(s, gh[3] - 0.012, side * gb * 0.84, 0.012 * f)
		var mid := _on_glass(s, xa, side * gb * 0.42, 0.008 * f)
		var tip := _on_glass(s, xa, side * gb * 0.12, 0.008 * f)
		lm.beam("Trim", pivot, mid, 0.016 * f, 0.012 * f, _glass_n(s, xa, mid.z), true)
		lm.beam("Trim", mid, tip, 0.012 * f, 0.01 * f, _glass_n(s, xa, tip.z), true)
		lm.disc("Trim", pivot, _glass_n(s, gh[3] - 0.012, pivot.z), 0.022 * f, 8)

## A point `lift` off the near loft's glass at (`x`, `z`).
static func _on_glass(s: Dictionary, x: float, z: float, lift: float) -> Vector3:
	return Vector3(x, VehicleKit.roof_on_mesh(s, x, z), z) + _glass_n(s, x, z) * lift

## The glass's normal at (`x`, `z`), from roof_on_mesh().
static func _glass_n(s: Dictionary, x: float, z: float) -> Vector3:
	var e := 0.01
	var dx := (VehicleKit.roof_on_mesh(s, x + e, z) - VehicleKit.roof_on_mesh(s, x - e, z)) / (2.0 * e)
	var dz := (VehicleKit.roof_on_mesh(s, x, z + e) - VehicleKit.roof_on_mesh(s, x, z - e)) / (2.0 * e)
	return Vector3(-dx, 1.0, -dz).normalized()

## A bus's centre pillar down the windscreen, from the sign band to the foot.
static func _split(lm: LandmarkMesh, s: Dictionary) -> void:
	var gh: PackedFloat32Array = s["gh"]
	var x0 := float(s["board_x"])
	var pts: Array[Vector3] = []
	for k in 6:
		pts.append(_on_glass(s, lerpf(x0, gh[3], float(k) / 5.0), 0.0, 0.012))
	for k in 5:
		lm.beam("Trim", pts[k], pts[k + 1], 0.07, 0.024, Vector3(0, 0, 1), k == 0 or k == 4)

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
static func paint(kind: String, far: bool = false) -> ShaderMaterial:
	var id := "Paint_" + kind + ("_far" if far else "")
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
	m.set_shader_parameter("face", _face(s, far))
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
## has none, and near to where the opening is modelled (CarDetails.front).
static func _face(s: Dictionary, far: bool) -> PackedVector4Array:
	var out := PackedVector4Array()
	for end: float in [1.0, -1.0]:
		var front := end > 0.0
		var lamp: Vector2 = s["lamp_f"] if front else s["lamp_r"]
		var span := lamp.y - lamp.x
		var lk := float(s["lamp_k"]) if front else float(s["lamp_k_r"])
		var y1 := VehicleKit.end_at(s, end, 0.0, lamp.y).y
		# The lamps are modelled (CarParts.lamps; the far loft's own lamp
		# quads), so no lamp opening is drawn.
		out.append(Vector4())
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
		if not far:
			intake = Vector4()
			if float(s["len"]) <= 8.0:
				grille = Vector4()
		out.append(grille)
		out.append(intake)
		out.append(Vector4(VehicleKit.end_at(s, end, 0.0, float(s["plate_t"]) if front else 0.5).y, 0.0725, 0.285, 0.0))
		out.append(lines)
	return out

## A faint self-light on a wheel part. Under a night sky the ambient light
## on the wheels is nil and a metal only mirrors the black street, so the
## wheel would fill as a flat black disc; this keeps tyre and spokes readable.
## Negligible against the daylight on them.
static func _night_fill(m: StandardMaterial3D, tint: Color, energy: float) -> void:
	m.emission_enabled = true
	m.emission = tint
	m.emission_energy_multiplier = energy

## The shared material of a non-paint surface key.
static func material(key: String) -> StandardMaterial3D:
	if _materials.has(key):
		return _materials[key]
	var m := StandardMaterial3D.new()
	match key:
		"Glass":
			# Tinted glass over the modelled cabin: premultiplied, so the
			# grazing (Fresnel) mirror of the sky and street stays at full
			# strength while the cabin shows through face on.
			m.albedo_color = Color(0.02, 0.03, 0.035, 0.64)
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m.blend_mode = BaseMaterial3D.BLEND_MODE_PREMULT_ALPHA
			m.roughness = 0.04
			m.metallic_specular = 0.6
		"GlassDark":
			# Far off (and on the bus): smooth, dark glass, the cabin dark behind it.
			m.albedo_color = Color(0.03, 0.04, 0.05)
			m.roughness = 0.04
			m.metallic_specular = 0.6
		"Cabin":
			# Upholstery, carpet and the door cards: dark, matt.
			m.albedo_color = Color(0.055, 0.052, 0.05)
			m.roughness = 0.9
		"Grille":
			m.albedo_color = Color(0.1, 0.1, 0.105)
			m.metallic = 0.6
			m.roughness = 0.35
		"Trim":
			m.albedo_color = Color(0.03, 0.03, 0.033)
			m.roughness = 0.65
			m.metallic_specular = 0.25
		"Rubber":
			m.albedo_color = Color(0.045, 0.045, 0.047)
			m.roughness = 0.95
			_night_fill(m, Color(0.5, 0.5, 0.52), 0.02)
		"Rim":
			# Not fully metal: a mirror of a dark night street is black, and
			# the wheel must still read by what little light falls on it.
			m.albedo_color = Color(0.62, 0.64, 0.66)
			m.metallic = 0.55
			m.roughness = 0.36
			_night_fill(m, Color(0.62, 0.64, 0.66), 0.06)
		"HeadLamp":
			# A clear lens over a bright reflector.
			m.albedo_color = Color(0.62, 0.65, 0.68)
			m.metallic = 0.45
			m.roughness = 0.1
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
		"Drl":
			# A daytime light guide: milky white, a little lit.
			m.albedo_color = Color(0.86, 0.88, 0.9)
			m.roughness = 0.3
			m.emission_enabled = true
			m.emission = Color(0.9, 0.93, 1.0)
			m.emission_energy_multiplier = 0.25
		"TailGlow":
			m.albedo_color = Color(0.75, 0.06, 0.05)
			m.roughness = 0.2
			m.emission_enabled = true
			m.emission = Color(0.8, 0.05, 0.03)
			m.emission_energy_multiplier = 0.15
		"RimGun":
			# A black wheel's machined faces: gunmetal, so its spokes read.
			m.albedo_color = Color(0.4, 0.41, 0.43)
			m.metallic = 0.3
			m.roughness = 0.4
			_night_fill(m, Color(0.4, 0.41, 0.43), 0.06)
		"RimDark":
			# The dark of a two-tone alloy: its barrel and the spokes' flanks.
			m.albedo_color = Color(0.07, 0.07, 0.075)
			m.metallic = 0.3
			m.roughness = 0.38
			_night_fill(m, Color(0.3, 0.3, 0.32), 0.04)
		"Board":
			# A bus's destination sign, dark by day (TransitVehicles lights it).
			m.albedo_color = Color(0.025, 0.025, 0.025)
			m.roughness = 0.55
	_materials[key] = m
	return m
