class_name LandmarkBkDemocracyMonument
extends RefCounted

## Democracy Monument (อนุสาวรีย์ประชาธิปไตย) — Bangkok BK-2.3
## Site: OSM way 178329973, centroid 13.756688, 100.501852, Ratchadamnoen Klang roundabout.
## Spec (Mevissen & Corrado Feroci / Sitthidej Saenghirun, 1939-40, symbolic 24 June 1932 numbers):
##   - Circular stepped limestone roundabout plinth (~54 m diameter, 3 low steps) with 75 perimeter
##     buried-cannon chain bollards.
##   - Four iconic Art Deco wing pylons 24.0 m high standing radially at 24.0 m outer radius:
##     vertical inner face toward the central turret, curved/stepped outer parabolic profile
##     sweeping from ~7.2 m radial width at the relief pedestal up to a narrow ~1.6 m rounded crest,
##     fluted Art Deco side ribs, and bronze bas-relief sculpture panels at each wing's pedestal.
##   - Central octagonal/cylindrical white shrine turret (~8.6 m to cornice) pierced by 6 red-and-gilt
##     sword doors, crowned by two stacked golden *phan waen fa* offering bowls supporting the 1932
##     Constitution palm-leaf manuscript casket (~11.8 m central height).
##   - Four Naga-head Art Deco fountains spouting outward into water basins between the wings.

const K = preload("res://scripts/generation/landmarks/mainland_se_asia/landmark_mse_kit.gd")

const HEIGHT_M := 24.0

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Cream", LandmarkMaterials.pbr("render", "#EFE8D6", 3.0))
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#DAD3C5", 3.0))
	lm.use("Bronze", LandmarkMaterials.pbr("concrete", "#5B4A38", 2.0, 0.45, 0.55))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.use("Red", LandmarkMaterials.pbr("concrete", "#8E221B", 2.0, 0.55, 0.1))
	lm.use("Water", LandmarkMaterials.pool_water("#3E5E66", 0.12))

	_base_island(lm)
	_central_turret(lm)
	_four_wings(lm)
	_fountains(lm)
	lm.commit(model)

	var spots: Array = [
		[Vector3(0.0, 2.2, 9.0), Vector3(0.0, 9.5, 0.0), 42.0, 1.2, 24.0, Color(1.0, 0.86, 0.55)],
		[Vector3(0.0, 2.2, -9.0), Vector3(0.0, 9.5, 0.0), 42.0, 1.2, 24.0, Color(1.0, 0.86, 0.55)],
	]
	for i in 4:
		var a := PI * 0.25 + PI * 0.5 * float(i)
		var dir := Vector3(cos(a), 0, sin(a))
		spots.append([dir * 12.5 + Vector3(0, 1.8, 0), dir * 20.5 + Vector3(0, 15.0, 0),
			50.0, 1.25, 34.0, Color(1.0, 0.93, 0.80)])
	model.set_meta(LandmarkLights.FLOOD_META, spots)

static func _base_island(lm: LandmarkMesh) -> void:
	lm.frustum("Stone", Vector3.ZERO, 27.5, 27.0, 0.45, 36)
	lm.frustum("Stone", Vector3(0, 0.45, 0), 23.8, 23.3, 0.45, 36)
	lm.frustum("Stone", Vector3(0, 0.90, 0), 17.6, 17.2, 0.45, 32)
	lm.frustum("Stone", Vector3(0, 1.35, 0), 9.0, 8.6, 0.55, 24)
	for i in 40:
		var a := TAU * float(i) / 40.0
		lm.frustum("Bronze", Vector3(cos(a) * 26.2, 0.45, sin(a) * 26.2), 0.19, 0.14, 0.62, 6)

static func _central_turret(lm: LandmarkMesh) -> void:
	var y0 := 1.90
	# Moulded circular pedestal + slender Art Deco hexagonal/cylindrical turret drum
	lm.lathe("Cream", Vector3(0, y0, 0), PackedVector2Array([
		Vector2(4.2, 0.0), Vector2(4.2, 0.65), Vector2(3.55, 0.85),
		Vector2(3.25, 1.25), Vector2(3.15, 5.20), Vector2(3.48, 5.50),
		Vector2(3.38, 6.10), Vector2(2.65, 6.45)]), 18)
	# Six vertical Art Deco pilaster ribs & six red sword-relief doors at 60 degrees
	for i in 6:
		var a := TAU * float(i) / 6.0
		var b := Basis(Vector3.UP, a)
		lm.box("Red", b * Vector3(0, y0 + 3.15, 3.16), Vector3(1.02, 3.35, 0.18), b, 0.0)
		lm.box("Cream", b * Vector3(0, y0 + 3.20, 3.10), Vector3(1.38, 3.65, 0.14), b, 0.0)
		lm.beam("Gold", b * Vector3(0, y0 + 1.65, 3.28), b * Vector3(0, y0 + 4.55, 3.28), 0.15, 0.09, b.x)
		var b_rib := Basis(Vector3.UP, a + PI / 6.0)
		lm.box("Stone", b_rib * Vector3(0, y0 + 3.35, 3.18), Vector3(0.38, 4.10, 0.24), b_rib, 0.0)
	# Two golden stacked offering bowls (phan waen fa) + Constitution palm-leaf box on top
	var py := y0 + 6.45
	lm.lathe("Gold", Vector3(0, py, 0), PackedVector2Array([
		Vector2(1.55, 0.0), Vector2(1.05, 0.35), Vector2(0.62, 0.72),
		Vector2(1.88, 1.32), Vector2(2.05, 1.52), Vector2(1.18, 1.72),
		Vector2(0.75, 2.02), Vector2(1.78, 2.52), Vector2(1.90, 2.72),
		Vector2(1.28, 2.88)]), 16)
	lm.box("Gold", Vector3(0, py + 3.10, 0), Vector3(1.75, 0.44, 0.78))
	lm.spire("Gold", Vector3(0, py + 3.32, 0), 0.80, 0.26, 0.42, 4)

static func _four_wings(lm: LandmarkMesh) -> void:
	# Build one Art Deco wing pylon along +X (inner vertical face at x ~ 17.0 m facing the turret,
	# outer parabolic stepped spine sweeping from x = 24.4 m at pedestal to x = 18.7 m at y = 24.0 m)
	# matching the iconic gull-wing silhouette in Commons photos.
	var wing := LandmarkMesh.new()
	for k in ["Cream", "Stone", "Bronze", "Gold"]:
		wing.use(k, LandmarkMaterials.gold())
	var y0 := 0.90
	# Wide sculpted pedestal block at base (x = 16.8..24.5 m, y = 0.9..4.5 m) with reliefs
	wing.box("Cream", Vector3(20.65, y0 + 1.80, 0), Vector3(7.7, 3.6, 3.5))
	wing.box("Stone", Vector3(20.65, y0 + 0.30, 0), Vector3(8.1, 0.6, 3.9))
	wing.box("Stone", Vector3(20.55, y0 + 3.55, 0), Vector3(7.5, 0.32, 3.65))
	for sz in [-1.0, 1.0]:
		var fz: float = float(sz) * 1.78
		wing.box("Cream", Vector3(20.5, y0 + 1.95, fz), Vector3(5.6, 2.35, 0.22), Basis(), 0.0)
		wing.box("Bronze", Vector3(20.5, y0 + 1.88, float(sz) * 1.90), Vector3(5.0, 1.95, 0.14), Basis(), 0.0)

	# Main central curved Art Deco fin blade (y = 4.5..24.0 m):
	# Inner edge rises almost vertically (x = 17.0 -> 17.15 m), outer edge curves gracefully inward
	# from x = 24.2 m at pedestal to x = 18.65 m at the 24.0 m tip!
	var segs := 16
	var y_start := y0 + 3.6
	var blade_h := HEIGHT_M - y_start
	for j in segs:
		var t0 := float(j) / float(segs)
		var t1 := float(j + 1) / float(segs)
		var tm := (t0 + t1) * 0.5
		var ya := y_start + blade_h * t0
		var yb := y_start + blade_h * t1
		var x_in := lerpf(16.95, 17.15, tm)
		var x_out := lerpf(24.15, 18.65, pow(tm, 0.88))
		var thick := lerpf(2.35, 1.05, tm)
		wing.box("Cream", Vector3((x_in + x_out) * 0.5, (ya + yb) * 0.5, 0),
			Vector3(x_out - x_in, yb - ya + 0.05, thick))
		# Outer spine stepped Art Deco vertical buttresses (3 stepped tiers stopping at 52%, 74%, 90%)
		if tm < 0.52:
			wing.box("Stone", Vector3(x_out - 0.55, (ya + yb) * 0.5, 0),
				Vector3(1.1, yb - ya + 0.03, thick + 0.52), Basis(), 0.0)
		if tm < 0.74:
			wing.box("Stone", Vector3(lerpf(x_in + 1.2, x_out - 0.8, 0.55), (ya + yb) * 0.5, 0),
				Vector3(0.85, yb - ya + 0.03, thick + 0.34), Basis(), 0.0)
		if tm < 0.91:
			wing.box("Stone", Vector3(x_in + 0.65, (ya + yb) * 0.5, 0),
				Vector3(0.65, yb - ya + 0.03, thick + 0.20), Basis(), 0.0)
	# Rounded/gilt Art Deco cap cleanly at HEIGHT_M = 24.0 m
	wing.box("Gold", Vector3(17.90, HEIGHT_M - 0.12, 0), Vector3(1.55, 0.24, 1.08))

	for i in 4:
		var angle := PI * 0.25 + PI * 0.5 * float(i)
		lm.merge(wing, Transform3D(Basis(Vector3.UP, angle), Vector3.ZERO))

static func _fountains(lm: LandmarkMesh) -> void:
	for i in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * float(i))
		lm.box("Stone", b * Vector3(0, 1.45, 13.0), Vector3(5.8, 0.65, 3.2), b)
		lm.box("Water", b * Vector3(0, 1.79, 13.0), Vector3(5.1, 0.06, 2.5), b, 0.0)
		lm.box("Cream", b * Vector3(0, 2.08, 11.0), Vector3(1.3, 1.25, 1.5), b)
		K.outline_prism(lm, "Gold", b * Vector3(0, 2.70, 11.1), b, K.flame_outline(1.1, 0.85), 0.28)
