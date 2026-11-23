class_name LandmarkMiConventionCenter
extends RefCounted

## Miami Beach Convention Center (Fentress Architects, 2018 renovation) - MI-4C.
## Site: way 76689875 (25.795391, -80.133136, yaw_deg 88.3). Modelled as a compact
## 180 x 110 m hero pavilion on the main Washington Ave / 19th St concourse, height_m = 26.0.
## Front (+Z) carries the silver-white undulating aluminium-fin wave facade (143 angled
## vertical fins whose depth and twist vary sinusoidally), cantilevered glass entrance
## canopies, a glazed grand concourse lobby, and a roof of solar arrays and mechanical bays
## reaching 26.0 m. CanopyLamp / FinLamp glow at night.

const HEIGHT_M := 26.0
const FRONT_Z := 50.0

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#D6D3CC", 5.0))
	lm.use("Glass", LandmarkMaterials.glass("#3F6070"))
	lm.use("Fin", LandmarkMaterials.paint("#DDE3E8", 0.28, 0.9))
	lm.use("Steel", LandmarkMaterials.paint("#6F7A80", 0.45, 0.7))
	lm.use("Solar", LandmarkMaterials.pbr("slate", "#1F2E44", 2.0, 0.22, 0.35))
	lm.use("CanopyLamp", LandmarkMaterials.lit("#FFE2B0", 0.9))
	lm.use("FinLamp", LandmarkMaterials.lit("#BFE6FF", 0.8))
	_body(lm)
	_fins(lm)
	_canopies(lm)
	_roof(lm)
	lm.commit(model)
	var cool := Color(0.78, 0.90, 1.0)
	var warm := Color(1.0, 0.85, 0.6)
	var spots: Array = []
	for x: float in [-60.0, -20.0, 20.0, 60.0]:
		spots.append([Vector3(x, 1.0, 76.0), Vector3(x, 8.0, 54.0), 55.0, 1.0, 40.0, cool])
	spots.append([Vector3(0.0, 6.0, 72.0), Vector3(0.0, 8.0, 58.0), 70.0, 0.9, 24.0, warm])
	model.set_meta(LandmarkLights.FLOOD_META, spots)

static func _body(lm: LandmarkMesh) -> void:
	lm.box("Concrete", Vector3(0.0, -0.15, 0.0), Vector3(180.0, 0.3, 110.0), Basis(), 0.0)
	lm.box("Concrete", Vector3(0.0, 7.0, -1.0), Vector3(176.0, 14.0, 98.0), Basis(), 0.1)
	# Glazed grand concourse lobby along the front
	lm.box("Glass", Vector3(0.0, 7.0, 50.2), Vector3(80.0, 14.0, 0.4), Basis(), 0.0)
	for k in 21:
		var x: float = -40.0 + 4.0 * float(k)
		lm.beam("Steel", Vector3(x, 0.0, 50.5), Vector3(x, 14.0, 50.5), 0.2, 0.3)

static func _fins(lm: LandmarkMesh) -> void:
	for k in 143:
		var x: float = -85.2 + 1.2 * float(k)
		if absf(x) < 12.0:
			continue
		var h: float = 12.5 + 1.5 * sin(x * 0.19)
		var d: float = 2.4 + 1.8 * sin(x * 0.11 + 1.0)
		var rot: float = 0.35 * sin(x * 0.11 + 1.7)
		lm.box("Fin", Vector3(x, 0.4 + h * 0.5, FRONT_Z + 0.3 + d * 0.5),
			Vector3(0.22, h, d), Basis(Vector3.UP, rot), 0.0)
		if k % 4 == 0:
			lm.box("FinLamp", Vector3(x, 0.25, FRONT_Z + 0.5), Vector3(0.3, 0.3, 0.3), Basis(), 0.0)

static func _canopies(lm: LandmarkMesh) -> void:
	for cx: float in [-55.0, 0.0, 55.0]:
		lm.box("Glass", Vector3(cx, 8.2, 56.0), Vector3(26.0, 0.25, 12.0), Basis(), 0.0)
		for sx: float in [-12.0, 12.0]:
			lm.beam("Steel", Vector3(cx + sx, 14.0, 50.5), Vector3(cx + sx, 8.1, 61.5), 0.2, 0.2)
		lm.beam("CanopyLamp", Vector3(cx - 12.5, 8.0, 62.0), Vector3(cx + 12.5, 8.0, 62.0), 0.25, 0.1)

static func _roof(lm: LandmarkMesh) -> void:
	# Tilted solar arrays on the main roof (roof plane y = 14)
	for r in 4:
		for c in 7:
			var x: float = -66.0 + 22.0 * float(c)
			var z: float = -36.0 + 14.0 * float(r)
			lm.box("Solar", Vector3(x, 15.2, z), Vector3(14.0, 0.12, 5.0), Basis(Vector3.RIGHT, -0.26), 0.0)
	# Mechanical bays: central bay tops out at exactly 26.0 m
	lm.box("Concrete", Vector3(0.0, 20.0, -20.0), Vector3(30.0, 12.0, 18.0), Basis(), 0.0)
	lm.box("Concrete", Vector3(-55.0, 18.0, -10.0), Vector3(24.0, 8.0, 16.0), Basis(), 0.0)
	lm.box("Concrete", Vector3(55.0, 19.0, -10.0), Vector3(24.0, 10.0, 16.0), Basis(), 0.0)
