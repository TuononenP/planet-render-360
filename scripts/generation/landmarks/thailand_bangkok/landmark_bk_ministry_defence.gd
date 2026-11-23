class_name LandmarkBkMinistryDefence
extends RefCounted

## Ministry of Defence (`ศาลาว่าการกลาโหม`) — Bangkok BK-5.1
## Site: OSM relation 1307598 / way 1481381668, centroid 13.75173, 100.49475
## (`height_m: 22.0`, `yaw_deg: -6.0`, west portico & cannon forecourt facing `-X` across Sanam Chai Rd).
## Spec (Joachim Grassi, 1882–84, Italian Neo-Palladian courtyard ministry, Commons `front.jpg`):
##   - 3-storey butter-yellow stucco rectangular courtyard block (`156 × 126 m` around twin inner courts,
##     `15.6 m` eaves, pale-cream hipped tile roof to `19.4 m`), crisp white Classical pilasters &
##     cornices, and rhythmic emerald-green louvred shutters (`#23533A`) on all 3 storeys.
##   - Projecting central Neo-Palladian west frontispiece (`-X`) with yellow Doric portico,
##     arched 3rd-floor windows, triangular Classical pediment with gilded Siam arms (`20.4 m`),
##     and central forecourt flagpole reaching `22.0 m`.
##   - Manicured green lawn forecourt (`-X`) displaying 12 historic bronze cannons (`Phraya Tani`
##     and companions) mounted on stepped crimson carriages (`front.jpg`).

const K = preload("res://scripts/generation/landmarks/capital_stations/landmark_station_kit.gd")

const HEIGHT_M := 22.0

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Yellow", LandmarkMaterials.pbr("render", "#F2E27E", 3.0))
	lm.use("White", LandmarkMaterials.pbr("limestone", "#F7F5EE", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("slate", "#B9B4AA", 2.5))
	lm.use("Shutter", LandmarkMaterials.pbr("wood", "#23533A", 2.0))
	lm.use("Glass", LandmarkMaterials.glass("#22302B"))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.use("Grass", LandmarkMaterials.pbr("grass", "#4A7838", 4.0))
	lm.use("Carriage", LandmarkMaterials.pbr("wood", "#7C2422", 2.0))
	lm.use("Bronze", LandmarkMaterials.pbr("copper", "#4E5D4A", 2.0, 0.42, 0.72))

	_courtyard_wings(lm)
	_west_portico_frontispiece(lm)
	_cannon_forecourt(lm)
	lm.commit(model)

	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-96.0, 1.8, -28.0), Vector3(-76.0, 12.0, -18.0), 55.0, 1.20, 44.0, Color(1.0, 0.92, 0.72)],
		[Vector3(-96.0, 1.8, 0.0), Vector3(-76.0, 15.0, 0.0), 52.0, 1.35, 44.0, Color(1.0, 0.92, 0.72)],
		[Vector3(-96.0, 1.8, 28.0), Vector3(-76.0, 12.0, 18.0), 55.0, 1.20, 44.0, Color(1.0, 0.92, 0.72)],
	])

static func _courtyard_wings(lm: LandmarkMesh) -> void:
	# Four outer 3-storey Neo-Palladian ranges (`18 m` deep, `15.4 m` eaves) + central cross-wing
	var h := 15.4
	var rh := 3.6
	# West & East ranges (`x = ±68.0 m`, `124 m` N-S)
	for sx in [-1.0, 1.0]:
		var cx := float(sx) * 68.0
		_palladian_range(lm, cx, 0.0, 18.0, 124.0, h, rh)
	# North, Center & South ranges (`z = -53, 0, +53 m`, `118 m` E-W)
	for cz in [-53.0, 0.0, 53.0]:
		_palladian_range(lm, 0.0, cz, 118.0, 18.0, h, rh if cz != 0.0 else 2.8)

static func _palladian_range(lm: LandmarkMesh, cx: float, cz: float, w: float, d: float, h: float, rh: float) -> void:
	lm.box("Yellow", Vector3(cx, h * 0.5, cz), Vector3(w, h, d))
	for y in [0.55, 5.2, 10.2, h - 0.35]:
		lm.box("White", Vector3(cx, y, cz), Vector3(w + 0.45, 0.55, d + 0.45))
	K.hip_roof(lm, "Roof", Vector3(cx, h, cz), w + 1.1, d + 1.1, rh)

	# Reusable green-shuttered Neo-Palladian window unit (`bay = 4.6 m`) on long exterior faces
	for face in LandmarkFhParts.faces(cx, cz, w, d):
		var a: Vector3 = face[0]
		var b: Vector3 = face[1]
		var out: Vector3 = face[2]
		var span := a.distance_to(b)
		if span < 22.0:
			continue
		var nb := int(span / 4.8)
		var right := (b - a).normalized()
		var fb := Basis(right, Vector3.UP, out)
		for i in nb + 1:
			var pp := a.lerp(b, float(i) / float(nb)) + out * 0.14
			lm.box("White", pp + Vector3(0, h * 0.5, 0), Vector3(0.46, h - 0.4, 0.28), fb, 0.0)
		for i in nb:
			var wp := a.lerp(b, (float(i) + 0.5) / float(nb))
			for sy in [2.6, 7.6, 12.6]:
				lm.box("White", wp + out * 0.10 + Vector3(0, sy, 0), Vector3(1.85, 2.85, 0.18), fb, 0.0)
				lm.box("Glass", wp + out * 0.15 + Vector3(0, sy, 0), Vector3(1.35, 2.35, 0.12), fb, 0.0)
				for side in [-1.0, 1.0]:
					lm.box("Shutter", wp + out * 0.20 + right * (float(side) * 0.92) + Vector3(0, sy, 0),
						Vector3(0.52, 2.35, 0.10), fb, 0.0)

static func _west_portico_frontispiece(lm: LandmarkMesh) -> void:
	# Raised 3-storey central pavilion (`x = -77.5 m`, `28 m` wide) + Classical pediment + Doric porte-cochère
	var pc := Vector3(-74.0, 0.0, 0.0)
	lm.box("Yellow", pc + Vector3(0, 8.6, 0), Vector3(12.0, 17.2, 28.0))
	lm.box("White", pc + Vector3(0, 17.0, 0), Vector3(12.8, 0.7, 28.8))
	var pb := Basis(Vector3.UP, -PI * 0.5)
	lm.gable("Roof", pc + Vector3(0, 17.35, 0), 28.4, 12.6, 3.2, Basis(), 0.3, "Yellow")
	lm.box("Gold", pc + Vector3(-6.45, 18.5, 0), Vector3(0.22, 1.6, 4.2))
	# Projecting 2-storey colonnaded yellow portico (`x = -80..-88 m`)
	lm.box("Yellow", Vector3(-84.0, 9.8, 0.0), Vector3(8.6, 1.3, 20.0))
	lm.box("White", Vector3(-84.0, 10.6, 0.0), Vector3(9.2, 0.45, 20.6))
	for iz in 6:
		var cz := -8.5 + 3.4 * float(iz)
		lm.frustum("Yellow", Vector3(-87.6, 0.0, cz), 0.48, 0.42, 9.2, 10)
		lm.frustum("Yellow", Vector3(-81.2, 0.0, cz), 0.48, 0.42, 9.2, 10)
	K.arch_row(lm, "White", "Shutter", Vector3(-80.1, 0, -11.0), Vector3(-80.1, 0, 11.0),
		Vector3(-1, 0, 0), 11.4, 5, 2.4, 4.4, 1)
	ignore_unused(pb)

static func ignore_unused(_v: Variant) -> void:
	pass

static func _cannon_forecourt(lm: LandmarkMesh) -> void:
	# Forecourt manicured lawns (`x = -89..-106 m`) + 22.0 m flagpole + 12 historic bronze cannons
	lm.box("Grass", Vector3(-97.5, 0.06, -34.0), Vector3(16.0, 0.12, 48.0))
	lm.box("Grass", Vector3(-97.5, 0.06, 34.0), Vector3(16.0, 0.12, 48.0))
	# Central white flagpole pedestal & 22.0 m mast
	lm.box("White", Vector3(-95.0, 0.9, 0.0), Vector3(2.2, 1.8, 2.2))
	lm.beam("White", Vector3(-95.0, 1.8, 0.0), Vector3(-95.0, HEIGHT_M, 0.0), 0.16, 0.16)
	lm.frustum("Gold", Vector3(-95.0, HEIGHT_M - 0.35, 0.0), 0.16, 0.02, 0.35, 8)

	# Reusable historic bronze cannon on stepped red timber garrison carriage (`front.jpg`)
	var can := LandmarkMesh.new()
	for k in ["White", "Carriage", "Bronze"]:
		can.use(k, LandmarkMaterials.gold())
	can.box("White", Vector3(0, 0.12, 0), Vector3(3.4, 0.24, 1.8))
	can.box("Carriage", Vector3(0.2, 0.55, 0), Vector3(2.4, 0.62, 1.05))
	can.box("Carriage", Vector3(0.65, 0.92, 0), Vector3(1.3, 0.32, 0.92))
	can.beam("Bronze", Vector3(1.2, 1.12, 0), Vector3(-1.55, 1.24, 0), 0.42, 0.42)
	for i in 6:
		var z_n := -52.0 + 7.2 * float(i)
		var z_s := 16.0 + 7.2 * float(i)
		lm.merge(can, Transform3D(Basis(), Vector3(-97.5, 0.0, z_n)))
		lm.merge(can, Transform3D(Basis(), Vector3(-97.5, 0.0, z_s)))
