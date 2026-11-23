class_name LandmarkBkRamaViii
extends RefCounted

## Rama VIII Bridge (`สะพานพระราม 8`) — Chao Phraya River, Bangkok BK-6.2
## Site: BridgeSpecsPilot `br_bangkok_rama_viii_bridge` (`13.7694, 100.4965`, `bearing: 118.5°`,
## `spans: [75.0, 50.0, 50.0, 300.0] = 475.0 m`, `width: 29.2 m`, `clear: 12.5 m`, `tower: 160.0 m`).
## Built along `+X` centred on `(0, 0, 0)` (`x = -237.5..+237.5 m`), `y = 0` at water level,
## Thonburi anchor spans on `-X` (`-237.5..-62.5 m`), single 160 m inverted-Y pylon at `x = -62.5 m`,
## and 300 m main Chao Phraya span on `+X` (`-62.5..+237.5 m`).
## Spec (Buckland & Taylor / Mott MacDonald, opened 2002, Commons `front.jpg` & `night.jpg`):
##   - Single 160.0 m inverted-Y concrete pylon on the Thonburi bank (`x = -62.5 m`): two inclined
##     octagonal concrete legs rising from river plinths outside the deck (`z = ±15.2 m`) with
##     signature gilded lotus-motif collar bands at `y = 28 m` (`front.jpg`), converging at `y = 58 m`
##     into a single slender octagonal shaft up to `y = 148 m`.
##   - Glazed octagonal lotus-bud observation pod (`y = 148..154 m`) + golden lotus flame finial to `160.0 m`.
##   - Asymmetric golden cable stays: **two planes** of 28 golden stays (`z = ±14.0 m`) supporting the
##     300 m main span, balanced by **one central plane** of 28 golden back-stays (`z = 0.0 m`) anchored
##     into the 75 m Thonburi anchor span (`front.jpg` & `night.jpg`).

const TOTAL_L := 475.0
const HALF_L := 237.5
const PYLON_X := -62.5
const WIDTH_M := 29.2
const CLEAR_M := 12.5
const TOWER_M := 160.0

static func build(model: Node3D, row: Dictionary) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#CAC4B8", 4.0))
	lm.use("SteelBox", LandmarkMaterials.paint("#5C646B", 0.55, 0.35))
	lm.use("Deck", LandmarkMaterials.pbr("asphalt", "#38393B", 4.0))
	lm.use("Paving", LandmarkMaterials.pbr("pavement", "#ABA496", 3.0))
	lm.use("Line", LandmarkMaterials.paint("#EAE7DE", 0.8, 0.0))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.use("Glass", LandmarkMaterials.glass("#263A46"))
	lm.use("Lamp", LandmarkMaterials.lit("#FFE494", 2.0))

	_deck_and_backspan_piers(lm, row)
	_inverted_y_pylon(lm)
	_asymmetric_golden_stays(lm)
	lm.commit(model)

	# Night golden floodlighting washing the 160 m inverted-Y pylon & golden cable fans (`night.jpg`)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(PYLON_X - 24.0, CLEAR_M + 2.0, -18.0), Vector3(PYLON_X, 92.0, 0.0), 55.0, 1.65, 130.0, Color(1.0, 0.84, 0.36)],
		[Vector3(PYLON_X + 28.0, CLEAR_M + 2.0, 18.0), Vector3(PYLON_X, 92.0, 0.0), 55.0, 1.65, 130.0, Color(1.0, 0.84, 0.36)],
		[Vector3(PYLON_X + 95.0, CLEAR_M + 1.5, 0.0), Vector3(PYLON_X + 35.0, 72.0, 0.0), 60.0, 1.35, 110.0, Color(1.0, 0.86, 0.42)],
	])

static func _deck_and_backspan_piers(lm: LandmarkMesh, row: Dictionary) -> void:
	var w := float(row.get("width", WIDTH_M))
	var c := float(row.get("clear", CLEAR_M))
	# Streamlined steel-composite main span (`PYLON_X..+HALF_L`, 2.4 m deep) + concrete back spans (`-HALF_L..PYLON_X`, 2.8 m deep)
	BridgeParam.slab(lm, -HALF_L, HALF_L, c, w)
	BridgeParam.markings(lm, -HALF_L, HALF_L, c, w)
	lm.box("Concrete", Vector3((-HALF_L + PYLON_X) * 0.5, c - 1.55, 0), Vector3(PYLON_X + HALF_L, 2.1, w * 0.84), Basis(), 0.0)
	lm.box("SteelBox", Vector3((PYLON_X + HALF_L) * 0.5, c - 1.35, 0), Vector3(HALF_L - PYLON_X, 1.7, w * 0.84), Basis(), 0.0)
	BridgeParam.rails(lm, "Gold", -HALF_L, HALF_L, c, w)

	# Back-span supports at xs = [-237.5, -162.5, -112.5] + eastern abutment at +237.5
	for px in [-162.5, -112.5]:
		LandmarkBrKit.tapered_box(lm, "Concrete", Vector3(px, 0.0, 0.0), 3.6, w * 0.62, 2.8, w * 0.54, c - 2.4)
	# Heavy Thonburi anchor block (`x = -233.5 m`) & Phra Nakhon abutment (`x = +234.5 m`)
	lm.box("Concrete", Vector3(-HALF_L + 4.5, (c - 1.2) * 0.5, 0), Vector3(9.0, c - 1.2, w * 0.92), Basis(), 0.0)
	lm.box("Concrete", Vector3(HALF_L - 3.0, (c - 1.2) * 0.5, 0), Vector3(6.0, c - 1.2, w * 0.90), Basis(), 0.0)

	# Deck street lamps every 32 m
	var n_lamps := 14
	for i in n_lamps:
		var lx := -HALF_L + 18.0 + (TOTAL_L - 36.0) * float(i) / float(n_lamps - 1)
		for sz in [-1.0, 1.0]:
			var z := float(sz) * (w * 0.5 - 0.35)
			lm.beam("SteelBox", Vector3(lx, c, z), Vector3(lx, c + 6.5, z), 0.14, 0.14)
			lm.box("Lamp", Vector3(lx, c + 6.6, z - float(sz) * 0.45), Vector3(0.35, 0.2, 0.75), Basis(), 0.0)

static func _inverted_y_pylon(lm: LandmarkMesh) -> void:
	# Octagonal water-level pile cap under the pylon (`x = -62.5 m`)
	lm.lathe("Concrete", Vector3(PYLON_X, 0.0, 0.0), PackedVector2Array([
		Vector2(21.5, 0.0), Vector2(20.8, 2.6), Vector2(0.0, 2.6)]), 8, 0.52, 1.0, PI / 8.0, false)

	# Two inclined octagonal concrete legs rising from `(PYLON_X, 2.4, ±15.6)` to merge at `(PYLON_X, 58.0, 0.0)`
	for sz in [-1.0, 1.0]:
		var s := float(sz)
		var segs := 6
		for k in segs:
			var t0 := float(k) / float(segs)
			var t1 := float(k + 1) / float(segs)
			var y0 := lerpf(2.2, 58.0, t0)
			var y1 := lerpf(2.2, 58.0, t1)
			var z0 := s * lerpf(15.6, 1.4, pow(t0, 0.92))
			var z1 := s * lerpf(15.6, 1.4, pow(t1, 0.92))
			var w0 := lerpf(5.4, 3.8, t0)
			var d0 := lerpf(4.4, 3.4, t0)
			lm.beam("Concrete", Vector3(PYLON_X, y0, z0), Vector3(PYLON_X, y1, z1), w0, d0, Vector3(0, 0, 1))
		# Signature gilded royal collar band wrapping each leg at `y = 27.5 m` (`front.jpg`)
		var z_band := s * lerpf(15.6, 1.4, pow((27.5 - 2.2) / 55.8, 0.92))
		lm.box("Gold", Vector3(PYLON_X, 27.5, z_band), Vector3(5.3, 3.2, 4.5))

	# Single tapering octagonal upper shaft (`y = 56.0..148.0 m`)
	lm.lathe("Concrete", Vector3(PYLON_X, 56.0, 0.0), PackedVector2Array([
		Vector2(4.2, 0.0), Vector2(3.6, 32.0), Vector2(3.1, 68.0), Vector2(2.75, 92.0)]),
		8, 1.12, 0.92, PI / 8.0, false)

	# Glazed lotus-bud observation pod (`y = 148.0..153.8 m`) + golden crown finial (`153.8..160.0 m`)
	lm.lathe("Gold", Vector3(PYLON_X, 147.6, 0.0), PackedVector2Array([
		Vector2(2.9, 0.0), Vector2(3.65, 0.9), Vector2(3.4, 1.2)]), 8, 1.0, 1.0, PI / 8.0, false)
	lm.lathe("Glass", Vector3(PYLON_X, 148.8, 0.0), PackedVector2Array([
		Vector2(3.35, 0.0), Vector2(3.75, 2.2), Vector2(2.6, 4.6), Vector2(1.4, 5.2)]), 12)
	for r_i in 8:
		var a := TAU * float(r_i) / 8.0
		var dir := Vector3(cos(a), 0, sin(a))
		lm.beam("Gold", Vector3(PYLON_X, 148.8, 0) + dir * 3.4,
			Vector3(PYLON_X, 154.0, 0) + dir * 1.35, 0.16, 0.16)
	lm.lathe("Gold", Vector3(PYLON_X, 153.8, 0.0), PackedVector2Array([
		Vector2(1.45, 0.0), Vector2(1.65, 1.1), Vector2(1.05, 2.8),
		Vector2(0.42, 4.5), Vector2(0.0, TOWER_M - 153.8)]), 10)

static func _asymmetric_golden_stays(lm: LandmarkMesh) -> void:
	# 28 pairs of golden stays in TWO planes over the 300 m main river span (`x = -26..+228 m`, `z = ±14.0 m`)
	var n_main := 28
	for i in n_main:
		var t := float(i) / float(n_main - 1)
		var y_top := lerpf(80.0, 145.5, t)
		var x_deck := lerpf(PYLON_X + 34.0, HALF_L - 8.0, t)
		for sz in [-1.0, 1.0]:
			var z_top := float(sz) * 1.35
			var z_deck := float(sz) * (WIDTH_M * 0.5 - 0.55)
			lm.beam("Gold", Vector3(PYLON_X + 1.2, y_top, z_top),
				Vector3(x_deck, CLEAR_M + 0.15, z_deck), 0.19, 0.19)

	# 28 golden back-stays in ONE central median plane (`z = 0.0 m`) anchored into the 75 m Thonburi back span (`x = -168..-234 m`)
	var n_back := 28
	for i in n_back:
		var t := float(i) / float(n_back - 1)
		var y_top := lerpf(80.0, 145.5, t)
		var x_back := lerpf(-164.0, -HALF_L + 3.5, t)
		lm.beam("Gold", Vector3(PYLON_X - 1.2, y_top, 0.0),
			Vector3(x_back, CLEAR_M + 0.25, 0.0), 0.21, 0.21)
