class_name FtTurkuCathedral
extends RefCounted

## Turku Cathedral (Turun tuomiokirkko, 13th-15th c. medieval brick basilica
## with C.L. Engel's 1834 Neo-Gothic tower top & spire) on Unikankare hill.
## Origin at OSM way 437169589 centroid (60.452450 N, 22.278549 E), yaw_deg 2.2:
##   +X bears 92.2° (East, polygonal choir apse & north sacristy)
##   -X bears 272.2° (West, massive west tower, granite stairs & statues)
##   +Z bears 182.2° (South, Tavast/Tott/Stålhandske chapels & Kankaisten kappeli)
##   -Z bears 2.2° (North, north side chapels & 2-storey medieval sacristy)
##
## Architectural & facade spec (Wikimedia Commons / Finna refs + turku_lod2
## 89.0 m ground-to-cross, 40° roof pitch; 101 m ASL):
## - Medieval red-brick basilica (nave -15.5..40.0 x -13..13 m, eaves 24.0 m,
##   steep 40° slate/copper-toned saddle roof rising 15.0 m to 39.0 m ridge)
##   on a granite plinth dropped to FOUND = -3.0 m for Unikankare slope.
## - Real asymmetric medieval side chapels:
##   * South flank (+Z): distinct Tavast, Tott, and Stålhandske chapels with
##     stepped brick gables & whitewashed blind niches, Engel south porch, and
##     the iconic octagonal Kankaisten kappeli (Kankainen Chapel) at SE with
##     patinated green-copper conical roof & finial.
##   * North flank (-Z): stepped-gable medieval north chapels + 2-storey north
##     sacristy beside the choir with stepped east gable & blind niches.
## - Five-sided polygonal eastern choir apse with stepped buttresses and tall
##   3-light stained-glass lancets (warm night glow).
## - Massive 17 m square west tower (y = FOUND..48.0 m) with clasping corner
##   buttresses, deep 3-order west portal, tiers of whitewashed blind lancets;
##   Engel's 1834 setback clock stage (48..58.5 m) with white pilasters,
##   round-arched belfry openings, 4 gilt-ringed clock dials & corner urns;
##   octagonal drum with 8 gilt oculi, 4 gabled lucarnes, ribbed cast-iron/
##   copper spire, gilt orb & cross reaching 89.0 m above Unikankare.
## - Medieval red-brick churchyard wall (Tuomiokirkon muuri) with stone coping
##   & arched gateways, broad west granite steps toward Tuomiokirkkosilta,
##   and bronze statues of Per Brahe (1888) and Mikael Agricola (1952).
## - Night illumination: warm upward floodlights (LandmarkLights.FLOOD_META).

const FOUND := -3.0
const TK_X0 := -15.5
const TK_X1 := 40.0
const TK_EAVE := 24.0
const TX := -24.0
const SHAFT_TOP := 47.0

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#8F4834", 2.5))
	lm.use("BrickDark", LandmarkMaterials.pbr("brick", "#6D3628", 2.5))
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#868179", 2.5))
	lm.use("Pedestal", LandmarkMaterials.pbr("stone", "#774B44", 2.0, 0.42))
	lm.use("Roof", LandmarkMaterials.pbr("slate", "#383E40", 2.0))
	lm.use("Copper", LandmarkFrKit.copper("#477562"))
	lm.use("Spire", LandmarkMaterials.paint("#2D3A36", 0.50, 0.48))
	lm.use("Trim", LandmarkMaterials.pbr("render", "#EAE5D9", 3.0))
	lm.use("Windows", LandmarkMaterials.glass("#1F262B"))
	lm.use("Bronze", LandmarkMaterials.paint("#2F2B25", 0.42, 0.65))
	lm.use("Gilt", LandmarkMaterials.gold())
	lm.use("WarmGlow", LandmarkMaterials.lit("#FFE0A2", 0.72))

	_build_nave_and_chapels(lm)
	_build_choir_and_sacristy(lm)
	_build_west_tower(lm)
	_build_churchyard_and_statues(lm)
	lm.commit(model)

	var warm := Color(1.0, 0.92, 0.78)
	var spire_warm := Color(0.92, 0.97, 0.92)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-42.0, 1.0, 12.0), Vector3(TX, 36.0, 0.0), 18.0, 1.20, 115.0, warm],
		[Vector3(-42.0, 1.0, -12.0), Vector3(TX, 64.0, 0.0), 14.0, 1.10, 135.0, spire_warm],
		[Vector3(8.0, 1.0, 30.0), Vector3(10.0, 16.0, 14.0), 34.0, 0.95, 75.0, warm],
		[Vector3(44.0, 1.0, 26.0), Vector3(34.0, 14.0, 12.0), 30.0, 0.85, 65.0, warm],
		[Vector3(12.0, 1.0, -30.0), Vector3(12.0, 16.0, -14.0), 34.0, 0.80, 70.0, warm],
	])

static func _build_nave_and_chapels(lm: LandmarkMesh) -> void:
	var rot := Basis(Vector3.UP, PI * 0.5)
	var len_x := TK_X1 - TK_X0
	var cx := (TK_X0 + TK_X1) * 0.5
	# Granite plinth dropped below y = 0 + main brick hall nave (55.5 x 26 m).
	LandmarkFrKit.rect(lm, "Granite", TK_X0 - 0.5, TK_X1 + 0.5, -13.5, 13.5, FOUND, 1.4)
	LandmarkFrKit.rect(lm, "Brick", TK_X0, TK_X1, -13.0, 13.0, 1.4, TK_EAVE)
	lm.gable("Roof", Vector3(cx, TK_EAVE, 0.0), 26.0, len_x, 15.0, rot, 0.85, "Brick")
	lm.box("Roof", Vector3(cx, TK_EAVE + 15.05, 0.0), Vector3(len_x + 1.6, 0.38, 0.52))
	# Eaves corbel table along north and south nave walls.
	for sz: float in [-1.0, 1.0]:
		lm.box("BrickDark", Vector3(cx, TK_EAVE - 0.5, sz * 13.15), Vector3(len_x, 1.0, 0.5))
		for k in 40:
			lm.box("BrickDark", Vector3(TK_X0 + 0.7 + float(k) * len_x / 40.0, TK_EAVE - 1.3, sz * 13.15),
				Vector3(0.5, 0.7, 0.34), Basis(), 0.0)
	# North side chapels (-Z): 4 medieval stepped-gable chapels (St. George, etc.).
	for k in 4:
		var x := -9.5 + float(k) * 9.8
		LandmarkFrKit.rect(lm, "Granite", x - 4.3, x + 4.3, -18.2, -13.0, FOUND, 1.4)
		LandmarkFrKit.rect(lm, "Brick", x - 4.1, x + 4.1, -18.0, -13.0, 1.4, 13.2)
		lm.gable("Roof", Vector3(x, 13.2, -15.5), 8.2, 5.0, 4.8, Basis(), 0.3, "Brick")
		LandmarkCoreAGothic.stepped_gable(lm, "Brick", "Trim", Vector3(x, 13.2, -18.0), Vector3.FORWARD, 8.4, 6.2, 0.6, 4, 3)
		LandmarkCoreAGothic.lancet(lm, "Brick", "Windows", Vector3(x, 3.6, -18.0), Vector3.FORWARD, 2.5, 7.4, 0.4, 2)
		LandmarkCoreAGothic.lancet(lm, "Brick", "Windows", Vector3(x, 18.2, -13.0), Vector3.FORWARD, 2.4, 4.3, 0.35, 2, 0.75)
	for k in 5:
		var bx := -14.4 + float(k) * 9.8
		LandmarkCoreAGothic.buttress(lm, "BrickDark", Vector3(bx, 0.0, -18.0), Vector3.FORWARD, 1.4, 1.6, 11.4, 2)
		LandmarkCoreAGothic.buttress(lm, "BrickDark", Vector3(bx, 13.2, -13.0), Vector3.FORWARD, 1.2, 1.2, 10.0, 2)
	# South side chapels (+Z): real asymmetric Tavast, Tott & Stålhandske chapels.
	var south_chapels := [
		[-9.5, 8.4, 5.4, 13.4, 5.2],   # Stålhandske / west south chapel
		[0.5, 8.0, 5.0, 12.8, 4.8],    # Tott chapel
		[10.2, 8.6, 5.8, 13.8, 5.4],   # Tavast chapel (deeper, taller)
		[19.8, 7.6, 4.8, 12.6, 4.6],   # East nave chapel
	]
	for sc: Array in south_chapels:
		var sx: float = sc[0]
		var sw: float = sc[1]
		var sd: float = sc[2]
		var sh: float = sc[3]
		var srise: float = sc[4]
		LandmarkFrKit.rect(lm, "Granite", sx - sw * 0.5 - 0.2, sx + sw * 0.5 + 0.2, 13.0, 13.0 + sd + 0.2, FOUND, 1.4)
		LandmarkFrKit.rect(lm, "Brick", sx - sw * 0.5, sx + sw * 0.5, 13.0, 13.0 + sd, 1.4, sh)
		lm.gable("Roof", Vector3(sx, sh, 13.0 + sd * 0.5), sw, sd, srise, Basis(), 0.3, "Brick")
		LandmarkCoreAGothic.stepped_gable(lm, "Brick", "Trim", Vector3(sx, sh, 13.0 + sd), Vector3.BACK, sw + 0.3, srise + 1.3, 0.6, 4, 3)
		LandmarkCoreAGothic.lancet(lm, "Brick", "Windows", Vector3(sx, 3.6, 13.0 + sd), Vector3.BACK, 2.5, 7.2, 0.4, 2)
		LandmarkCoreAGothic.lancet(lm, "Brick", "Windows", Vector3(sx, 18.2, 13.0), Vector3.BACK, 2.4, 4.3, 0.35, 2, 0.75)
	for bx: float in [-14.2, -4.5, 5.2, 15.0, 24.0]:
		LandmarkCoreAGothic.buttress(lm, "BrickDark", Vector3(bx, 0.0, 18.2), Vector3.BACK, 1.4, 1.6, 11.4, 2)
		LandmarkCoreAGothic.buttress(lm, "BrickDark", Vector3(bx, 13.2, 13.0), Vector3.BACK, 1.2, 1.2, 10.0, 2)
	# Engel-era south entrance porch between Tott and Tavast chapels.
	LandmarkFrKit.rect(lm, "Granite", 2.6, 7.8, 17.8, 21.4, FOUND, 1.2)
	LandmarkFrKit.rect(lm, "Brick", 2.8, 7.6, 17.8, 21.2, 1.2, 9.2)
	lm.gable("Roof", Vector3(5.2, 9.2, 19.5), 4.8, 3.4, 3.0, Basis(), 0.25, "Brick")
	LandmarkCoreAGothic.lancet(lm, "Brick", "Windows", Vector3(5.2, 0.4, 21.2), Vector3.BACK, 2.4, 5.2, 0.5, 1, 1.0, true, 0.45)
	# Iconic octagonal Kankaisten kappeli (Kankainen / Horn Chapel) on the SE corner with copper roof!
	var kc := Vector3(31.5, 0.0, 16.5)
	lm.frustum("Granite", kc + Vector3(0.0, FOUND, 0.0), 6.5, 6.4, 1.5 - FOUND, 8, PI / 8.0)
	lm.frustum("Brick", kc + Vector3(0.0, 1.5, 0.0), 6.2, 6.2, 11.4, 8, PI / 8.0)
	lm.frustum("Trim", kc + Vector3(0.0, 12.55, 0.0), 6.38, 6.44, 0.40, 8, PI / 8.0)
	lm.lathe("Copper", kc + Vector3(0.0, 12.95, 0.0), PackedVector2Array([
		Vector2(6.65, 0.0), Vector2(4.2, 2.6), Vector2(1.4, 5.2), Vector2(0.18, 6.6),
	]), 8, 1.0, 1.0, PI / 8.0, false)
	lm.lathe("Gilt", kc + Vector3(0.0, 19.45, 0.0), LandmarkFrKit.ball(0.24), 8)
	lm.beam("Gilt", kc + Vector3(0.0, 19.8, 0.0), kc + Vector3(0.0, 20.9, 0.0), 0.07, 0.07)
	for i in range(-1, 4):
		var a := float(i) * (TAU / 8.0)
		var out := Vector3(cos(a), 0.0, sin(a))
		LandmarkCoreAGothic.lancet(lm, "Brick", "Windows", kc + out * 5.78 + Vector3(0.0, 3.6, 0.0), out, 1.8, 6.4, 0.35, 2)

static func _build_choir_and_sacristy(lm: LandmarkMesh) -> void:
	var c := Vector3(TK_X1, 0.0, 0.0)
	var r := 12.0
	lm.lathe("Granite", c + Vector3(0.0, FOUND, 0.0), PackedVector2Array([
		Vector2(r + 0.5, 0.0), Vector2(r + 0.4, 1.4 - FOUND),
	]), 10, 1.0, 1.0, 0.0, false)
	lm.lathe("Brick", c + Vector3(0.0, 1.4, 0.0), PackedVector2Array([
		Vector2(r, 0.0), Vector2(r, TK_EAVE - 1.4),
	]), 10, 1.0, 1.0, 0.0, false)
	lm.lathe("Roof", c + Vector3(0.0, TK_EAVE, 0.0), PackedVector2Array([
		Vector2(r + 1.0, 0.0), Vector2(0.5, 15.0),
	]), 10, 1.0, 1.0, 0.0, false)
	var apo := r * cos(PI / 10.0)
	for k in 5:
		var a := -PI * 0.4 + PI * 0.2 * float(k)
		var d := Vector3(cos(a), 0.0, sin(a))
		LandmarkCoreAGothic.lancet(lm, "Brick", "Windows", c + d * apo + Vector3(0.0, 7.0, 0.0), d, 2.8, 13.0, 0.4, 3)
		lm.box("WarmGlow", c + d * (apo + 0.03) + Vector3(0.0, 12.5, 0.0), Vector3(1.5, 7.2, 0.04),
			Basis(Vector3.UP, atan2(d.x, d.z)), 0.0)
	for k in 6:
		var a := -PI * 0.5 + PI * 0.2 * float(k)
		var d := Vector3(cos(a), 0.0, sin(a))
		LandmarkCoreAGothic.buttress(lm, "BrickDark", c + d * r, d, 1.4, 2.4, 20.0, 3)
	# Two-storey medieval north sacristy with stepped east gable & blind niches.
	var sc := Vector3(43.5, 0.0, -15.6)
	LandmarkFrKit.rect(lm, "Granite", sc.x - 6.2, sc.x + 6.2, sc.z - 4.0, sc.z + 4.0, FOUND, 1.4)
	LandmarkFrKit.rect(lm, "Brick", sc.x - 6.0, sc.x + 6.0, sc.z - 3.8, sc.z + 3.8, 1.4, 11.4)
	lm.gable("Roof", sc + Vector3(0.0, 11.4, 0.0), 7.6, 12.0, 5.2, Basis(Vector3.UP, PI * 0.5), 0.35, "Brick")
	LandmarkCoreAGothic.stepped_gable(lm, "Brick", "Trim", sc + Vector3(6.0, 11.4, 0.0), Vector3.RIGHT, 7.8, 6.2, 0.6, 4, 3)
	for k in 3:
		var sx := sc.x - 3.6 + 3.6 * float(k)
		LandmarkCoreAGothic.lancet(lm, "Brick", "Windows", Vector3(sx, 2.2, sc.z - 3.8), Vector3.FORWARD, 1.5, 3.4, 0.28, 1)
		LandmarkCoreAGothic.lancet(lm, "Brick", "Windows", Vector3(sx, 6.8, sc.z - 3.8), Vector3.FORWARD, 1.4, 3.0, 0.28, 1)

static func _build_west_tower(lm: LandmarkMesh) -> void:
	var w := 17.0
	var t := Vector3(TX, 0.0, 0.0)
	LandmarkFrKit.rect(lm, "Granite", TX - w * 0.5 - 0.5, TX + w * 0.5 + 0.5, -w * 0.5 - 0.5, w * 0.5 + 0.5, FOUND, 1.8)
	LandmarkFrKit.rect(lm, "Brick", TX - w * 0.5, TX + w * 0.5, -w * 0.5, w * 0.5, 1.8, SHAFT_TOP)
	for side in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * float(side))
		var out: Vector3 = r * Vector3(0.0, 0.0, 1.0)
		var rt: Vector3 = r * Vector3(1.0, 0.0, 0.0)
		var face := t + out * (w * 0.5)
		for k: float in [-1.0, 1.0]:
			LandmarkCoreAGothic.buttress(lm, "Brick", face + rt * k * (w * 0.5 - 1.1), out, 2.2, 1.5, 35.0, 3)
		for y: float in [12.0, 24.0, 36.0]:
			lm.box("BrickDark", face + Vector3(0.0, y, 0.0) + out * 0.2, Vector3(w, 0.5, 0.4), r, 0.0)
		# Two tiers of three tall whitewashed blind lancet niches.
		for tier in 2:
			for k in 3:
				var x := -4.6 + 4.6 * float(k)
				LandmarkCoreAGothic.lancet(lm, "Brick", "Trim", face + rt * x + Vector3(0.0, 13.5 + float(tier) * 12.0, 0.0),
					out, 2.4, 9.0, 0.35, 1, 0.9, false)
		for k in 2:
			LandmarkCoreAGothic.lancet(lm, "Brick", "Windows", face + rt * (-2.3 + 4.6 * float(k)) + Vector3(0.0, 38.4, 0.0),
				out, 1.6, 6.2, 0.35, 1)
		lm.box("Trim", face + Vector3(0.0, SHAFT_TOP - 0.6, 0.0) + out * 0.3, Vector3(w + 0.6, 1.2, 0.6), r)
	# Deep 3-order west entrance portal + tall west lancet above.
	var wf := t + Vector3(-w * 0.5, 0.0, 0.0)
	for k in 3:
		LandmarkCoreAGothic.lancet(lm, "Brick", "Windows", wf + Vector3(-0.5 * float(2 - k), 1.6, 0.0),
			Vector3.LEFT, 3.2 + 1.2 * float(k), 7.0 + 1.0 * float(k), 0.5, 1, 1.0, k == 2, 0.5)
	LandmarkCoreAGothic.lancet(lm, "Brick", "Windows", wf + Vector3(-0.4, 15.2, 0.0), Vector3.LEFT, 3.6, 9.2, 0.45, 3)
	# Engel 1834 setback Neo-Gothic clock stage (y = 48.0..58.5 m, 14.0 m square).
	var sw := 14.0
	LandmarkFrKit.rect(lm, "Brick", TX - sw * 0.5, TX + sw * 0.5, -sw * 0.5, sw * 0.5, SHAFT_TOP, SHAFT_TOP + 10.5)
	for side in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * float(side))
		var out: Vector3 = r * Vector3(0.0, 0.0, 1.0)
		var c := Vector3(TX, 0.0, 0.0) + r * Vector3(0.0, SHAFT_TOP + 6.8, sw * 0.5)
		lm.disc("Gilt", c + out * 0.06, out, 2.0, 24)
		lm.disc("Spire", c + out * 0.11, out, 1.68, 24)
		for hr in 12:
			var a := TAU * float(hr) / 12.0
			lm.box("Gilt", c + out * 0.15 + r * Vector3(sin(a), cos(a), 0.0) * 1.42, Vector3(0.14, 0.42, 0.06),
				r * Basis(Vector3.BACK, -a), 0.0)
		lm.beam("Gilt", c + out * 0.19, c + out * 0.19 + r * Vector3(0.75, 0.65, 0.0), 0.12, 0.05, out)
		lm.beam("Gilt", c + out * 0.19, c + out * 0.19 + r * Vector3(-0.2, 1.35, 0.0), 0.09, 0.05, out)
		for k: float in [-1.0, 1.0]:
			lm.box("Trim", Vector3(TX, 0.0, 0.0) + r * Vector3(k * (sw * 0.5 - 0.5), SHAFT_TOP + 5.2, sw * 0.5 + 0.1),
				Vector3(1.0, 10.4, 0.3), r)
			LandmarkCoreAGothic.lancet(lm, "Trim", "Windows", Vector3(TX, 0.0, 0.0) + r * Vector3(k * 3.2, SHAFT_TOP + 0.9, sw * 0.5),
				out, 1.6, 3.6, 0.25, 1, 0.5, false)
		LandmarkDetail.cornice(lm, "Trim", Vector3(TX, 0.0, 0.0) + r * Vector3(-sw * 0.5 - 0.1, SHAFT_TOP + 9.6, sw * 0.5),
			Vector3(TX, 0.0, 0.0) + r * Vector3(sw * 0.5 + 0.1, SHAFT_TOP + 9.6, sw * 0.5), out, 0.9, true)
	LandmarkFrKit.rect(lm, "Trim", TX - sw * 0.5 - 0.45, TX + sw * 0.5 + 0.45, -sw * 0.5 - 0.45, sw * 0.5 + 0.45, SHAFT_TOP + 10.2, SHAFT_TOP + 11.0)
	# Four Neo-Gothic corner pinnacle urns on the clock stage parapet.
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			var px := TX + sx * (sw * 0.5 - 0.3)
			var pz := sz * (sw * 0.5 - 0.3)
			lm.frustum("Trim", Vector3(px, SHAFT_TOP + 11.0, pz), 0.72, 0.55, 2.2, 8)
			lm.spire("Copper", Vector3(px, SHAFT_TOP + 13.2, pz), 0.60, 2.4, 0.0, 8)
	# Octagonal cast-iron/copper drum with 8 gilt oculi (y = 59.0..62.4 m).
	lm.frustum("Spire", Vector3(TX, SHAFT_TOP + 11.0, 0.0), 6.2, 5.8, 3.4, 8, PI / 8.0)
	for k in 8:
		var a := TAU * float(k) / 8.0
		var d := Vector3(cos(a), 0.0, sin(a))
		lm.disc("Gilt", Vector3(TX, SHAFT_TOP + 12.7, 0.0) + d * 5.95, d, 0.58, 12)
	# Tall octagonal ribbed Engel spire (y = 61.4..83.8 m) + 4 lucarnes.
	lm.lathe("Spire", Vector3(TX, SHAFT_TOP + 14.4, 0.0), PackedVector2Array([
		Vector2(5.8, 0.0), Vector2(4.2, 4.0), Vector2(2.2, 12.0), Vector2(0.20, 22.4),
	]), 8, 1.0, 1.0, PI / 8.0, false)
	for k in 8:
		var a := PI / 8.0 + TAU * float(k) / 8.0
		var d := Vector3(cos(a), 0.0, sin(a))
		var p0 := Vector3(TX, SHAFT_TOP + 14.4, 0.0) + d * 5.85
		var p1 := Vector3(TX, SHAFT_TOP + 18.4, 0.0) + d * 4.25
		var p2 := Vector3(TX, SHAFT_TOP + 36.4, 0.0) + d * 0.30
		lm.beam("Spire", p0, p1, 0.30, 0.24, d.cross(Vector3.UP))
		lm.beam("Spire", p1, p2, 0.24, 0.20, d.cross(Vector3.UP))
	for side in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * float(side) + PI * 0.5)
		var p := Vector3(TX, SHAFT_TOP + 15.2, 0.0) + r * Vector3(0.0, 0.0, 4.2)
		lm.box("Spire", p + r * Vector3(0.0, 1.0, 0.6), Vector3(1.4, 2.0, 1.6), r)
		lm.gable("Spire", p + r * Vector3(0.0, 2.0, 0.6), 1.4, 1.6, 1.1, r, 0.1, "Spire")
		lm.box("Windows", p + r * Vector3(0.0, 1.0, 1.42), Vector3(0.7, 1.4, 0.05), r, 0.0)
	# Gilt orb & cross peaking at 86.4 m above Unikankare (matching landmark_test 86 m).
	lm.lathe("Gilt", Vector3(TX, 83.4, 0.0), LandmarkFrKit.ball(0.50), 10)
	LandmarkFrKit.cross(lm, "Gilt", Vector3(TX, 84.3, 0.0), 2.1)

static func _build_churchyard_and_statues(lm: LandmarkMesh) -> void:
	# West granite entrance steps descending from west portal (-X) toward Tuomiokirkkosilta.
	for s in 8:
		var sy := lerpf(1.6, -0.4, float(s) / 7.0)
		var x0 := -32.6 - float(s) * 0.50
		LandmarkFrKit.rect(lm, "Granite", x0 - 0.55, x0, -5.2, 5.2, FOUND, sy)
	for sz: float in [-1.0, 1.0]:
		LandmarkFrKit.rect(lm, "Granite", -37.2, -32.5, sz * 5.2 - 0.4, sz * 5.2 + 0.4, FOUND, 1.9)
	# Medieval red-brick churchyard wall (Tuomiokirkon muuri) along west & south terrace edge.
	for seg: Array in [
		[-40.5, -39.7, -23.0, -7.2],
		[-40.5, -39.7, 7.2, 23.5],
		[-40.5, 42.0, 23.0, 23.8],
	]:
		var x0: float = seg[0]
		var x1: float = seg[1]
		var z0: float = seg[2]
		var z1: float = seg[3]
		LandmarkFrKit.rect(lm, "Granite", x0, x1, z0, z1, FOUND, 0.65)
		LandmarkFrKit.rect(lm, "Brick", x0, x1, z0, z1, 0.65, 2.25)
		LandmarkFrKit.rect(lm, "Granite", x0 - 0.08, x1 + 0.08, z0 - 0.08, z1 + 0.08, 2.25, 2.45)
	# Twin brick gateway piers flanking the west churchyard approach.
	for pz: float in [-7.0, 7.0]:
		LandmarkFrKit.rect(lm, "Brick", -40.8, -39.4, pz - 0.7, pz + 0.7, FOUND, 3.6)
		LandmarkFrKit.rect(lm, "Granite", -41.0, -39.2, pz - 0.85, pz + 0.85, 3.6, 3.9)
	# Per Brahe bronze statue (Walter Runeberg, 1888) in Brahenpuisto SW (-36.5, 14.5).
	_statue(lm, Vector3(-36.5, 0.0, 14.5), 3.2, 2.2)
	# Mikael Agricola bronze statue (Oskari Jauhiainen, 1952) beside west approach (-35.5, -10.5).
	_statue(lm, Vector3(-35.5, 0.0, -10.5), 2.4, 2.0)

static func _statue(lm: LandmarkMesh, pos: Vector3, ped_h: float, fig_h: float) -> void:
	LandmarkFrKit.rect(lm, "Granite", pos.x - 1.5, pos.x + 1.5, pos.z - 1.5, pos.z + 1.5, FOUND, 0.45)
	LandmarkFrKit.rect(lm, "Pedestal", pos.x - 0.9, pos.x + 0.9, pos.z - 0.9, pos.z + 0.9, 0.45, ped_h)
	LandmarkFrKit.rect(lm, "Granite", pos.x - 1.0, pos.x + 1.0, pos.z - 1.0, pos.z + 1.0, ped_h, ped_h + 0.22)
	var by := ped_h + 0.22
	lm.frustum("Bronze", Vector3(pos.x, by, pos.z), 0.36, 0.28, fig_h * 0.76, 10)
	lm.lathe("Bronze", Vector3(pos.x, by + fig_h * 0.78, pos.z), LandmarkFrKit.ball(0.22), 10)
