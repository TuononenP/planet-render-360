class_name TukTukModel
extends RefCounted

## Thai three-wheeled motorized auto-rickshaw (`รถตุ๊กตุ๊ก` / Tuk-Tuk, `BK-9.2`).
## Built in true metres (+X forward, origin on ground at mid-wheelbase, length 2.84 m,
## width 1.34 m, height 1.82 m) so `ParkedCars` can batch `"tuk_tuk"` alongside four-wheel
## `CarModel` kinds with `MultiMesh` instance colours (royal blue, emerald green, crimson)
## while keeping a true single steerable front wheel, open passenger sides with chrome
## safety rails, raked front windscreen with `"TAXI"` header sign, and yellow-trimmed
## canvas roof canopy.

const LENGTH_M := 2.84
const WIDTH_M := 1.34
const HEIGHT_M := 1.82

static var _meshes: Dictionary = {}

static func mesh(far: bool = false) -> ArrayMesh:
	var key := "tuk_tuk_far" if far else "tuk_tuk"
	if _meshes.has(key):
		return _meshes[key]
	var lm := LandmarkMesh.new()
	lm.use("Paint", CarModel.paint("kei", far))
	lm.use("Canopy", LandmarkMaterials.pbr("render", "#E8B923", 1.5, 0.82))
	lm.use("Stripe", LandmarkMaterials.pbr("render", "#1E7B46", 1.5, 0.80))
	lm.use("Chrome", CarModel.material("Chrome"))
	lm.use("Trim", CarModel.material("Trim"))
	lm.use("Cabin", CarModel.material("Cabin"))
	lm.use("Rubber", CarModel.material("Rubber"))
	lm.use("Rim", CarModel.material("Rim"))
	lm.use("Glass", CarModel.material("GlassDark" if far else "Glass"))
	lm.use("HeadLamp", CarModel.material("Drl"))
	lm.use("TailLamp", CarModel.material("TailGlow"))
	lm.use("Sign", CarModel.material("Sign"))
	lm.use("Plate", CarModel.material("Plate"))

	_chassis_and_body(lm, far)
	_wheels(lm, far)
	_canopy_and_rails(lm, far)
	var out := lm.to_array_mesh(false)
	_meshes[key] = out
	return out

static func _chassis_and_body(lm: LandmarkMesh, far: bool) -> void:
	# Underframe + rear passenger tub + front mudguard cowling (+X forward)
	lm.box("Trim", Vector3(-0.10, 0.24, 0.0), Vector3(2.35, 0.10, 1.12))
	lm.box("Paint", Vector3(-0.62, 0.50, 0.0), Vector3(1.52, 0.48, 1.30))
	for sz in [-1.0, 1.0]:
		var s := float(sz)
		lm.box("Paint", Vector3(-0.88, 0.46, s * 0.64), Vector3(0.86, 0.44, 0.08))
		lm.box("Chrome", Vector3(-0.88, 0.24, s * 0.67), Vector3(0.92, 0.05, 0.05))
	lm.box("Cabin", Vector3(-0.84, 0.58, 0.0), Vector3(0.56, 0.16, 1.12))
	lm.box("Cabin", Vector3(-1.12, 0.84, 0.0), Vector3(0.14, 0.42, 1.12))
	lm.box("Cabin", Vector3(0.20, 0.58, 0.0), Vector3(0.38, 0.14, 0.52))

	var apron_b := Basis(Vector3.FORWARD, deg_to_rad(10.0))
	lm.box("Paint", Vector3(0.76, 0.64, 0.0), Vector3(0.14, 0.68, 1.08), apron_b)
	lm.box("Chrome", Vector3(0.84, 0.64, 0.0), Vector3(0.05, 0.34, 0.46), apron_b)
	var screen_b := Basis(Vector3.FORWARD, deg_to_rad(18.0))
	lm.box("Paint", Vector3(0.66, 1.24, 0.0), Vector3(0.07, 0.58, 1.10), screen_b)
	lm.box("Glass", Vector3(0.67, 1.25, 0.0), Vector3(0.09, 0.44, 0.94), screen_b)
	lm.box("Sign", Vector3(0.60, 1.62, 0.0), Vector3(0.18, 0.14, 0.48))
	lm.box("Plate", Vector3(-1.39, 0.42, 0.0), Vector3(0.03, 0.13, 0.36))

	lm.box("Paint", Vector3(1.08, 0.46, 0.0), Vector3(0.54, 0.16, 0.30))
	if not far:
		lm.beam("Chrome", Vector3(0.84, 0.84, 0.0), Vector3(1.08, 0.26, 0.0), 0.05, 0.05)
	for sz in [-1.0, 1.0]:
		var s := float(sz)
		lm.box("HeadLamp", Vector3(0.85, 0.72, s * 0.36), Vector3(0.08, 0.15, 0.15))
		lm.box("Chrome", Vector3(0.83, 0.72, s * 0.36), Vector3(0.06, 0.18, 0.18))
		lm.box("TailLamp", Vector3(-1.39, 0.52, s * 0.48), Vector3(0.05, 0.12, 0.18))

static func _wheels(lm: LandmarkMesh, far: bool) -> void:
	var segs := 8 if far else 12
	_wheel_disc(lm, Vector3(1.08, 0.25, 0.0), 0.25, 0.13, segs)
	for sz in [-1.0, 1.0]:
		_wheel_disc(lm, Vector3(-0.88, 0.26, float(sz) * 0.58), 0.26, 0.15, segs)

static func _wheel_disc(lm: LandmarkMesh, c: Vector3, r: float, w: float, segs: int) -> void:
	var sub := LandmarkMesh.new()
	sub.use("Rubber", CarModel.material("Rubber"))
	sub.use("Rim", CarModel.material("Rim"))
	sub.frustum("Rubber", Vector3(0, -w * 0.5, 0), r, r, w, segs)
	sub.frustum("Rim", Vector3(0, -w * 0.54, 0), r * 0.56, r * 0.56, w * 1.08, maxi(segs - 2, 6))
	lm.merge(sub, Transform3D(Basis(Vector3.RIGHT, PI * 0.5), c))

static func _canopy_and_rails(lm: LandmarkMesh, far: bool) -> void:
	lm.box("Canopy", Vector3(-0.24, 1.70, 0.0), Vector3(1.94, 0.10, 1.24))
	lm.box("Canopy", Vector3(-0.24, 1.77, 0.0), Vector3(1.76, 0.08, 1.06))
	lm.box("Stripe", Vector3(-0.24, 1.62, 0.0), Vector3(1.98, 0.07, 1.28))
	var back_b := Basis(Vector3.FORWARD, deg_to_rad(-11.0))
	lm.box("Canopy", Vector3(-1.26, 1.26, 0.0), Vector3(0.08, 0.84, 1.20), back_b)
	lm.box("Glass", Vector3(-1.27, 1.30, 0.0), Vector3(0.10, 0.36, 0.78), back_b)
	if far:
		return
	for sz in [-1.0, 1.0]:
		var z := float(sz) * 0.59
		lm.beam("Chrome", Vector3(0.56, 0.94, z), Vector3(0.54, 1.64, z), 0.035, 0.035)
		lm.beam("Chrome", Vector3(-0.22, 0.72, z), Vector3(-0.22, 1.64, z), 0.035, 0.035)
		lm.beam("Chrome", Vector3(-1.14, 0.76, z), Vector3(-1.20, 1.64, z), 0.035, 0.035)
		lm.beam("Chrome", Vector3(0.12, 0.74, z), Vector3(0.56, 0.74, z), 0.035, 0.035)
	lm.beam("Chrome", Vector3(-1.42, 0.28, -0.62), Vector3(-1.42, 0.28, 0.62), 0.055, 0.055)
