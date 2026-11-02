class_name LandmarkMaGulf
extends RefCounted

## Four Gulf landmarks in true metres: Burj Al Arab, the Makkah Royal
## Clock Tower (Abraj Al-Bait), Riyadh's Kingdom Centre and the Dubai
## Frame.

# --- Burj Al Arab ---

const ARAB_SLICE_M := 12.5
const ARAB_SLICES := 24

## Half-width of the V of wings at height y: the tower narrows to a
## slender mast-top.
static func _arab_tip(y: float) -> float:
	return 25.0 * (1.0 - 0.8 * pow(y / 300.0, 1.4))

## 321 m sail-shaped hotel on its island: two glazed wings in a V, the
## Teflon-coated sail bowed across the open side (-Z, the sea), the
## steel mast behind and the cantilevered helipad and restaurant.
static func burj_al_arab(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Sail", LandmarkMaterials.pbr("render", "#F6F4EE", 6.0))
	lm.use("Glass", LandmarkMaterials.glass("#3F5766"))
	lm.use("Mast", LandmarkMaterials.paint("#B9C1C7", 0.4, 0.6))
	lm.use("Island", LandmarkMaterials.pbr("concrete", "#BDB4A6", 4.0))
	lm.frustum("Island", Vector3(0, -6, 5), 72.0, 70.0, 6.5, 32)
	var rows: Array = []
	for k in ARAB_SLICES:
		var y := ARAB_SLICE_M * (k + 0.5)
		var tip := _arab_tip(y)
		for s in [-1.0, 1.0]:
			var a := Vector3(0, y, 8)
			var b := Vector3(s * tip, y, -22)
			var d := b - a
			lm.box("Glass", (a + b) * 0.5, Vector3(14, ARAB_SLICE_M, d.length()),
				Basis(Vector3.UP, atan2(d.x, d.z)))
	for k in ARAB_SLICES + 1:
		var y := ARAB_SLICE_M * k
		var f := y / 300.0
		var tip := _arab_tip(y)
		var bow := 20.0 * (1.0 - 0.6 * f)
		var row := PackedVector3Array()
		for i in 9:
			var u := -1.0 + 0.25 * i
			row.append(Vector3(u * tip, y, -24.0 - bow * (1.0 - u * u)))
		rows.append(row)
		if k > 0:
			for s in [-1.0, 1.0]:
				lm.beam("Mast", Vector3(s * _arab_tip(y - ARAB_SLICE_M), y - ARAB_SLICE_M, -24),
					Vector3(s * tip, y, -24), 1.2)
	lm.grid("Sail", rows, Vector3(0, 0, -1))
	lm.box("Mast", Vector3(0, 150, 12), Vector3(10, 300, 10))
	lm.spire("Mast", Vector3(0, 300, 12), 3.5, 21.0, 0.2, 8)
	lm.beam("Mast", Vector3(8, 208, -6), Vector3(20, 208, -6), 3.0)
	lm.disc("Island", Vector3(20, 210, -6), Vector3.UP, 12.0)
	lm.box("Glass", Vector3(-18, 200, -8), Vector3(24, 8, 14))
	lm.commit(model)
	model.rotation.y = deg_to_rad(-40.0)

# --- Abraj Al-Bait (Makkah Royal Clock Tower) ---

## 601 m clock tower on a 22 m mall podium among six hotel towers:
## stone shaft, 43 m clock faces on all four sides at 400 m, a gilded
## crown and the 71 m gold spire with its crescent.
static func abraj_al_bait(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#D9CDB4", 8.0))
	lm.use("Glass", LandmarkMaterials.glass("#3A4A52"))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.use("Clock", LandmarkMaterials.lit("#F4F0E6", 0.5))
	lm.use("Podium", LandmarkMaterials.pbr("concrete", "#C9C0AE", 6.0))
	lm.box("Podium", Vector3(0, 11, 0), Vector3(300, 22, 170))
	for s in [-1.0, 1.0]:
		for j in 3:
			var h: float = [200.0, 260.0, 230.0][j] if s < 0.0 else [230.0, 260.0, 200.0][j]
			var p := Vector3(s * 115.0, 0, -55.0 + 55.0 * j)
			lm.box("Stone", p + Vector3(0, h * 0.35, 0), Vector3(44, h * 0.7, 44))
			lm.box("Stone", p + Vector3(0, h * 0.85, 0), Vector3(34, h * 0.3, 34))
			lm.box("Glass", p + Vector3(0, h * 0.4, 21.2), Vector3(30, h * 0.7, 0.3))
			lm.box("Glass", p + Vector3(0, h * 0.4, -21.2), Vector3(30, h * 0.7, 0.3))
			LandmarkMaParts.dome(lm, "Gold", p + Vector3(0, h, 0), 11.0, 9.0, 12)
	lm.spire("Stone", Vector3(0, 22, 0), 26.0, 338.0, 23.0)
	lm.box("Stone", Vector3(0, 400, 0), Vector3(50, 80, 50))
	for d in [Vector3.RIGHT, Vector3.LEFT, Vector3.BACK, Vector3.FORWARD]:
		lm.disc("Gold", d * 25.15 + Vector3(0, 400, 0), d, 23.5, 32)
		lm.disc("Clock", d * 25.3 + Vector3(0, 400, 0), d, 21.5, 32)
	lm.spire("Gold", Vector3(0, 440, 0), 22.0, 60.0, 17.0)
	lm.box("Stone", Vector3(0, 515, 0), Vector3(22, 30, 22))
	LandmarkMaParts.dome(lm, "Gold", Vector3(0, 530, 0), 10.0, 20.0, 16, 0.3)
	LandmarkMaParts.needle(lm, "Gold", Vector3(0, 550, 0),
		PackedVector2Array([Vector2(0, 2.4), Vector2(30, 1.4), Vector2(36, 0.5)]), 8)
	LandmarkMaParts.sphere(lm, "Gold", Vector3(0, 588.5, 0), 2.4, 10, 6)
	LandmarkMaParts.crescent(lm, "Gold", Vector3(0, 594.5, 0), 7.0, 1.2)
	lm.commit(model)

# --- Kingdom Centre ---

const KC_TOP_M := 302.3
## Height where the parabolic opening starts / closes.
const KC_HOLE_Y := 200.0
const KC_HOLE_TOP := 290.0

## 302 m Riyadh tower: two glazed legs joined below the 90 m inverted-
## parabola opening, the sky bridge across the top and granite fins on
## the leg edges, on its mall podium.
static func kingdom_centre(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Glass", LandmarkMaterials.glass("#3D5F7A"))
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#E2DDD2", 6.0))
	lm.use("Steel", LandmarkMaterials.paint("#8E979E", 0.35, 0.6))
	lm.use("Podium", LandmarkMaterials.pbr("concrete", "#C2B8A6", 6.0))
	lm.box("Podium", Vector3(0, 8, 0), Vector3(96, 16, 66))
	lm.box("Glass", Vector3(0, KC_HOLE_Y * 0.5, 0), Vector3(72, KC_HOLE_Y, 32))
	var step := 4.0
	var y := KC_HOLE_Y
	while y < KC_HOLE_TOP:
		var t := (y + step * 0.5 - KC_HOLE_Y) / (KC_HOLE_TOP - KC_HOLE_Y)
		var hw := 26.0 * sqrt(maxf(1.0 - t, 0.0))
		for s in [-1.0, 1.0]:
			var w := 36.0 - hw
			lm.box("Glass", Vector3(s * (hw + w * 0.5), y + step * 0.5, 0), Vector3(w, step, 32))
		y += step
	lm.box("Steel", Vector3(0, (KC_HOLE_TOP + KC_TOP_M) * 0.5, 0),
		Vector3(72, KC_TOP_M - KC_HOLE_TOP, 32))
	for fx in [-33.5, 33.5]:
		lm.box("Stone", Vector3(fx, KC_TOP_M * 0.5, 0), Vector3(5, KC_TOP_M, 32.6))
	lm.commit(model)

# --- Dubai Frame ---

## 150 m picture frame, 93 m wide: two gold-clad legs joined by the
## glass-floored sky bridge at the top and a base bar, banded in gold.
static func dubai_frame(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Frame", LandmarkMaterials.pbr("concrete", "#C8A248", 3.0, 0.28, 0.7))
	lm.use("Glass", LandmarkMaterials.glass("#2E3A40"))
	lm.use("Plaza", LandmarkMaterials.pbr("pavement", "#CFC6B2", 5.0))
	lm.box("Plaza", Vector3(0, -1.0, 0), Vector3(170, 2, 60))
	for s in [-1.0, 1.0]:
		lm.box("Frame", Vector3(s * 40.5, 75, 0), Vector3(12, 150, 20))
		lm.box("Glass", Vector3(s * 40.5, 75, 10.1), Vector3(7, 130, 0.3))
		lm.box("Glass", Vector3(s * 40.5, 75, -10.1), Vector3(7, 130, 0.3))
		for i in 13:
			lm.box("Frame", Vector3(s * 40.5, 10.0 + 10.0 * i, 0), Vector3(12.6, 1.2, 20.6))
	lm.box("Frame", Vector3(0, 144, 0), Vector3(93, 12, 20))
	lm.box("Glass", Vector3(0, 144, 10.1), Vector3(70, 7, 0.3))
	lm.box("Glass", Vector3(0, 144, -10.1), Vector3(70, 7, 0.3))
	lm.box("Frame", Vector3(0, 3, 0), Vector3(93, 6, 20))
	lm.commit(model)
