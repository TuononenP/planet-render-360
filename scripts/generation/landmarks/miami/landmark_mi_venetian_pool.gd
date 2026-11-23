class_name LandmarkMiVenetianPool
extends RefCounted

## Venetian Pool, Coral Gables (MI-10). OSM way 297000205 (25.745779, -80.273177, yaw 67.1).
## Phineas Paist / Denman Fink (1924): spring-fed coral-rock quarry lagoon, 51.7 x 58.0 m.
##   - Irregular oolitic coral-limestone cliffs and grotto ledges ringing a teal lagoon.
##   - Sand beach pocket, arched stone footbridge to a palm island, striped paline mooring posts.
##   - Spanish Revival stucco entry pavilions and loggias with clay barrel-tile roofs.
##   - Twin lookout towers reaching exactly 11.0 m.

const HEIGHT_M := 11.0
const LAGOON_RX := 15.5
const LAGOON_RZ := 20.0
const LAGOON_CX := -2.0
const LAGOON_CZ := -2.0

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Coral", LandmarkMaterials.pbr("limestone", "#CFC2A0", 3.0))
	lm.use("Stucco", LandmarkMaterials.pbr("render", "#EFE2C4", 3.0))
	lm.use("Tile", LandmarkMaterials.pbr("terracotta", "#B9582F", 2.4))
	lm.use("Water", LandmarkMaterials.pool_water("#18A8B8"))
	lm.use("Sand", LandmarkMaterials.pbr("gravel", "#E4D3A6", 3.0))
	lm.use("Deck", LandmarkMaterials.pbr("concrete", "#D8CDB4", 3.0))
	lm.use("PostRed", LandmarkMaterials.paint("#C42B2B", 0.6, 0.05))
	lm.use("PostWhite", LandmarkMaterials.paint("#F4F0E6", 0.6, 0.05))
	lm.use("Frond", LandmarkMaterials.paint("#3C7A36", 0.8, 0.0))
	lm.use("Wood", LandmarkMaterials.pbr("wood", "#6B4A30", 2.0))
	_build_lagoon(lm)
	_build_cliffs(lm)
	_build_bridge_island(lm)
	_build_posts(lm)
	_build_pavilions(lm)
	_build_towers(lm)
	lm.commit(model)

static func _lagoon_pt(a: float, k: float) -> Vector2:
	var wob := 1.0 + 0.10 * sin(a * 3.0 + 0.7) + 0.06 * sin(a * 5.0 + 2.0)
	return Vector2(LAGOON_CX + cos(a) * LAGOON_RX * wob * k, LAGOON_CZ + sin(a) * LAGOON_RZ * wob * k)

static func _build_lagoon(lm: LandmarkMesh) -> void:
	var poly := PackedVector2Array()
	var n := 28
	for i: int in n:
		poly.append(_lagoon_pt(TAU * float(i) / float(n), 1.0))
	lm.poly_prism("Water", poly, -0.40, -0.06)
	# Concrete / sand apron around the lagoon (low ring slab with the lagoon cut out by the water prism on top)
	var apron := PackedVector2Array()
	for i: int in n:
		var p := _lagoon_pt(TAU * float(i) / float(n), 1.14)
		apron.append(p)
	lm.poly_prism("Deck", apron, -0.45, -0.12, false)
	# Beach pocket on the south-east shore
	var beach := PackedVector2Array()
	for i: int in 9:
		var a := lerpf(0.15, 1.15, float(i) / 8.0)
		beach.append(_lagoon_pt(a, 1.10))
	for i: int in 9:
		var a := lerpf(1.15, 0.15, float(i) / 8.0)
		beach.append(_lagoon_pt(a, 0.86))
	lm.poly_prism("Sand", beach, -0.40, -0.02)

static func _build_cliffs(lm: LandmarkMesh) -> void:
	var n := 26
	for i: int in n:
		var a := TAU * float(i) / float(n)
		if a > 0.1 and a < 1.2:
			continue  # beach opening
		var p := _lagoon_pt(a, 1.20)
		var s := 0.5 + 0.5 * absf(sin(float(i) * 2.3))
		var h := 1.8 + 3.6 * s
		var r := 2.6 + 1.2 * absf(cos(float(i) * 1.7))
		lm.frustum("Coral", Vector3(p.x, -0.4, p.y), r * 1.15, r * 0.62, h, 7, a, 1.0, 0.85)
		# grotto ledge shelf
		var q := _lagoon_pt(a + 0.07, 1.04)
		lm.box("Coral", Vector3(q.x, 0.55 + 0.3 * s, q.y), Vector3(2.2, 0.35, 1.5),
			Basis(Vector3.UP, -a), -1.0)

static func _build_bridge_island(lm: LandmarkMesh) -> void:
	var ic := Vector2(LAGOON_CX + 2.0, LAGOON_CZ + 3.0)
	# Palm island
	lm.frustum("Sand", Vector3(ic.x, -0.4, ic.y), 3.6, 2.6, 0.55, 12)
	lm.frustum("Coral", Vector3(ic.x - 0.8, 0.1, ic.y + 0.5), 1.6, 0.9, 0.9, 7)
	for k: int in 3:
		var a := 1.1 + float(k) * 2.1
		var b := Vector3(ic.x + cos(a) * 1.3, 0.1, ic.y + sin(a) * 1.3)
		LandmarkMiKit.royal_palm(lm, "Coral", "Frond", b, 6.0 + float(k) * 0.8, a)
	# Stone arched footbridge from the west shore to the island
	var x0 := LAGOON_CX - 11.0
	var x1 := ic.x - 3.0
	var z := ic.y
	var span := x1 - x0
	var steps := 10
	var prev := Vector3(x0, 0.5, z)
	for i: int in steps + 1:
		var t := float(i) / float(steps)
		var arch_y := 0.3 + 1.7 * sin(PI * t)
		var cur := Vector3(lerpf(x0, x1, t), arch_y, z)
		if i > 0:
			lm.beam("Coral", prev + Vector3(0, 0.55, 0), cur + Vector3(0, 0.55, 0), 2.2, 0.5,
				Vector3(0, 0, 1))
			lm.beam("Coral", prev + Vector3(0, 1.15, 1.0), cur + Vector3(0, 1.15, 1.0), 0.28, 0.65,
				Vector3(0, 0, 1))
			lm.beam("Coral", prev + Vector3(0, 1.15, -1.0), cur + Vector3(0, 1.15, -1.0), 0.28, 0.65,
				Vector3(0, 0, 1))
		prev = cur
	# Piers and arch soffit
	for t: float in [0.0, 0.5, 1.0]:
		var px := lerpf(x0, x1, t)
		lm.box("Coral", Vector3(px, 0.0, z + 0.9), Vector3(0.7, 0.9, 0.4), Basis(), 0.0)
		lm.box("Coral", Vector3(px, 0.0, z - 0.9), Vector3(0.7, 0.9, 0.4), Basis(), 0.0)
	lm.box("Coral", Vector3(lerpf(x0, x1, 0.5), 0.0, z + 1.0), Vector3(span * 0.5, 0.5, 0.3), Basis(), 0.0)

static func _build_posts(lm: LandmarkMesh) -> void:
	var n := 7
	for i: int in n:
		var t := float(i) / float(n - 1)
		var a := lerpf(1.9, 3.5, t)
		var p := _lagoon_pt(a, 0.96)
		for s: int in 5:
			var key := "PostRed" if s % 2 == 0 else "PostWhite"
			lm.frustum(key, Vector3(p.x, -0.4 + float(s) * 0.62, p.y), 0.22, 0.20, 0.62, 8)
		lm.lathe("PostWhite", Vector3(p.x, 2.72, p.y), PackedVector2Array([
			Vector2(0.0, 0.0), Vector2(0.28, 0.0), Vector2(0.30, 0.12),
			Vector2(0.14, 0.26), Vector2(0.0, 0.30)]), 8)

static func _pavilion(lm: LandmarkMesh, c: Vector3, w: float, l: float, h: float, rot: float) -> void:
	var b := Basis(Vector3.UP, rot)
	lm.box("Stucco", c + b * Vector3(0, h * 0.5, 0), Vector3(w, h, l), b, 0.0)
	lm.gable("Tile", c + b * Vector3(0, h, 0), w, l, 1.6, b, 0.6, "Stucco")
	# arched loggia bays on the lagoon-facing side (+Z local)
	for k: int in 3:
		var ox := (float(k) - 1.0) * (w * 0.28)
		lm.box("Deck", c + b * Vector3(ox, h * 0.45, l * 0.5 + 0.05), Vector3(w * 0.18, h * 0.62, 0.2), b, 0.0)
		lm.box("Wood", c + b * Vector3(ox, h * 0.82, l * 0.5 + 0.1), Vector3(w * 0.18, 0.25, 0.2), b, 0.0)

static func _build_towers(lm: LandmarkMesh) -> void:
	for sx: float in [-1.0, 1.0]:
		var tx := sx * 15.0
		var tz := 22.5
		lm.box("Stucco", Vector3(tx, 4.0, tz), Vector3(3.4, 8.0, 3.4), Basis(), 0.0)
		lm.box("Coral", Vector3(tx, 8.1, tz), Vector3(4.0, 0.3, 4.0), Basis(), 0.0)
		for dx: float in [-1.0, 1.0]:
			for dz: float in [-1.0, 1.0]:
				lm.box("Stucco", Vector3(tx + dx * 1.5, 9.0, tz + dz * 1.5), Vector3(0.45, 1.6, 0.45), Basis(), 0.0)
		lm.frustum("Tile", Vector3(tx, 9.8, tz), 2.9, 0.0, 1.0, 4, PI * 0.25)
		lm.beam("PostWhite", Vector3(tx, 10.8, tz), Vector3(tx, HEIGHT_M, tz), 0.08, 0.08, Vector3.RIGHT, true)

static func _build_pavilions(lm: LandmarkMesh) -> void:
	_pavilion(lm, Vector3(0.0, -0.1, 24.0), 14.0, 5.0, 5.2, 0.0)
	_pavilion(lm, Vector3(-18.5, -0.1, 8.0), 5.0, 14.0, 4.6, -PI * 0.5)
	_pavilion(lm, Vector3(19.0, -0.1, -6.0), 5.0, 12.0, 4.4, PI * 0.5)
	# loggia connectors
	for sx: float in [-1.0, 1.0]:
		lm.box("Stucco", Vector3(sx * 9.0, 1.7, 24.0), Vector3(5.0, 3.4, 2.4), Basis(), 0.0)
		lm.gable("Tile", Vector3(sx * 9.0, 3.4, 24.0), 5.0, 2.4, 0.9, Basis(), 0.4, "Stucco")
