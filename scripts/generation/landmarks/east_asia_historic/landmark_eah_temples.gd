class_name LandmarkEahTemples
extends RefCounted

## Japanese temple halls in true metres: the Todai-ji Great Buddha Hall
## (48.7 m: the 1709 hall, 57.5 x 50.5 m at the eaves, seven bays across
## the front; a hipped (yosemune) main roof with gilt shibi over a
## skirt roof (mokoshi) broken at the centre by the kara-hafu that crowns
## the Buddha's viewing window, three-stepped bracket sets, the gilt
## bronze octagonal lantern before it) and Kiyomizu-dera's main hall
## (30 m to the ridge: the 9 x 7-bay hall, 36 x 31 m overall, under a
## hipped bark-shingle roof with gabled wings either side of the stage,
## its 13 m kakezukuri stage on a grid of keyaki pillars tied by nuki
## beams, y = 0 at the pillar feet). Halls face south (+Z).

# --- Todai-ji Daibutsuden ---

const TODAIJI_M := 48.7

static func todaiji(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#9C9488", 3.0))
	lm.use("Plaster", LandmarkMaterials.pbr("render", "#EDE8DC", 3.0))
	lm.use("Timber", LandmarkMaterials.paint("#6E4E3A", 0.8, 0.0))
	lm.use("Tile", LandmarkMaterials.pbr("slate", "#4B5054", 1.5))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.use("Shadow", LandmarkMaterials.paint("#26221F", 0.9, 0.0))
	# Two-course stone platform, the front stair and the stone path.
	LandmarkEahParts.slab(lm, "Stone", Vector3(-35.0, 0.0, -31.0), Vector3(35.0, 1.3, 31.0))
	LandmarkEahParts.slab(lm, "Stone", Vector3(-30.5, 1.3, -27.0), Vector3(30.5, 2.8, 27.0))
	LandmarkEahParts.stairs(lm, "Stone", 0.0, 31.0, 0.0, 9.0, 4, 0.33, 0.6)
	LandmarkEahParts.slab(lm, "Stone", Vector3(-4.5, 0.0, 31.0), Vector3(4.5, 0.15, 60.0))
	var yf := 2.8
	# Lower storey: 7 x 7 bays of columns round a plastered core; the
	# three middle front bays carry the great doors, lattice windows (renji
	# mado) in the others; nuki tie beams and three-stepped bracket sets.
	LandmarkEahParts.colonnade(lm, "Timber", Vector2.ZERO, Vector2(46.0, 39.0), yf, 9.4, 7, 7, 0.6, 12)
	lm.box("Plaster", Vector3(0, yf + 4.7, 0), Vector3(44.6, 9.4, 37.6))
	LandmarkEahDetail.ring_beams(lm, "Timber", Vector3.ZERO, Vector2(46.0, 39.0), yf + 9.0, 0.6, 0.45)
	LandmarkEahDetail.ring_beams(lm, "Timber", Vector3.ZERO, Vector2(46.0, 39.0), yf + 6.4, 0.4, 0.35)
	LandmarkEahDetail.bays(lm, "Timber", "Shadow", Vector3(0, yf, 0), Vector2(44.6, 37.6), 6.2, 7, 7,
		func(face: int, i: int) -> int: return 1 if face == 0 and absi(i - 3) <= 1 else 2)
	LandmarkAeParts.brackets(lm, "Timber", Vector3(0, yf + 9.4, 0), 46.0, 39.0, 0.9, 2.0)
	# Skirt roof (mokoshi), 57.5 x 50.5 m at the eaves.
	var y1 := yf + 10.4
	var e1 := Vector2(57.5, 50.5)
	LandmarkAeParts.hip_roof(lm, "Tile", Vector3(0, y1, 0), e1, Vector2(34.0, 27.0), 5.0, 1.0)
	LandmarkAeParts.eave_fascia(lm, "Timber", Vector3(0, y1, 0), e1, 1.0, 0.5, Vector2(46.0, 39.0), 0.9)
	LandmarkAeParts.hip_ridges(lm, "Tile", Vector3(0, y1, 0), e1, Vector2(34.0, 27.0), 5.0, 1.0, 0.55)
	# Kara-hafu over the viewing window (kanso mado) at the centre front.
	LandmarkEahDetail.karahafu(lm, "Tile", "Plaster", "Timber", Vector3(0, y1 + 1.4, 25.6), Vector3(0, 0, 1),
		16.0, 3.6, 6.0, "Gold")
	LandmarkEahDetail.lattice(lm, "Timber", "Shadow", Vector3(0, y1 + 2.4, 25.65), Vector3(0, 0, 1), 7.0, 1.5, 12, 1)
	# Upper storey: 7 x 6 bays of columns round a plastered core with a
	# lattice window in each bay, bracket sets under the great roof.
	var y2 := y1 + 5.0
	LandmarkEahParts.colonnade(lm, "Timber", Vector2.ZERO, Vector2(33.0, 26.0), y2, 9.0, 7, 6, 0.5, 12)
	lm.box("Plaster", Vector3(0, y2 + 4.5, 0), Vector3(31.8, 9.0, 24.8))
	LandmarkEahDetail.ring_beams(lm, "Timber", Vector3.ZERO, Vector2(33.0, 26.0), y2 + 8.6, 0.55, 0.4)
	LandmarkEahDetail.bays(lm, "Timber", "Shadow", Vector3(0, y2, 0), Vector2(31.8, 24.8), 7.6, 7, 6,
		func(_face: int, _i: int) -> int: return 2)
	LandmarkAeParts.brackets(lm, "Timber", Vector3(0, y2 + 9.0, 0), 33.0, 26.0, 1.0, 1.8)
	# Great hipped roof, ridge with its tile courses and gilt shibi.
	var y3 := y2 + 10.0
	var e3 := Vector2(49.0, 42.0)
	var t3 := Vector2(26.0, 1.6)
	LandmarkAeParts.hip_roof(lm, "Tile", Vector3(0, y3, 0), e3, t3, 16.6, 1.2)
	LandmarkAeParts.eave_fascia(lm, "Timber", Vector3(0, y3, 0), e3, 1.2, 0.55, Vector2(33.0, 26.0), 1.0)
	LandmarkAeParts.hip_ridges(lm, "Tile", Vector3(0, y3, 0), e3, t3, 16.6, 1.2, 0.7)
	var ridge := y3 + 16.6
	LandmarkEahDetail.ridge(lm, "Tile", -13.2, 13.2, ridge - 0.2, 0.0, 1.8, 1.4)
	for s in [-1.0, 1.0]:
		_shibi(lm, "Gold", Vector3(s * 12.6, ridge + 1.1, 0), TODAIJI_M - ridge - 1.1, -s)
	_octagonal_lantern(lm, Vector3(0, 0.0, 40.0))
	lm.commit(model)

## Shibi: the gilt kite's-tail ridge end, `h` tall, a curved fin
## sweeping up and back from the ridge with a scaled edge.
static func _shibi(lm: LandmarkMesh, key: String, base: Vector3, h: float, inward: float) -> void:
	var prev := base
	for i in 6:
		var t := float(i + 1) / 6.0
		var p := base + Vector3(-inward * h * 0.35 * t * t, h * t, 0)
		lm.beam(key, prev, p, lerpf(1.6, 0.7, t), lerpf(1.0, 0.5, t), Vector3.FORWARD)
		lm.box(key, (prev + p) * 0.5 + Vector3(inward * lerpf(0.8, 0.4, t), 0, 0), Vector3(0.25, h / 6.0, 0.25), Basis(), 0.0)
		prev = p

## The gilt bronze octagonal lantern (4.6 m) on its stone pedestal.
static func _octagonal_lantern(lm: LandmarkMesh, at: Vector3) -> void:
	lm.lathe("Stone", at, PackedVector2Array([Vector2(1.3, 0), Vector2(1.3, 0.4), Vector2(0.9, 0.6),
		Vector2(0.35, 0.7), Vector2(0.3, 1.8), Vector2(0.7, 2.0)]), 8, 1.0, 1.0, PI / 8.0, false)
	var y := at.y + 2.0
	lm.frustum("Gold", Vector3(at.x, y, at.z), 0.7, 0.7, 1.5, 8, PI / 8.0)
	for k in 8:
		var a := PI * 0.25 * k
		var n := Vector3(cos(a), 0, sin(a))
		lm.box("Shadow", Vector3(at.x, y + 0.75, at.z) + n * 0.66, Vector3(0.45, 1.1, 0.06), Basis(Vector3.UP, PI * 0.5 - a), 0.0)
	lm.lathe("Gold", Vector3(at.x, y + 1.5, at.z), PackedVector2Array([Vector2(1.2, 0), Vector2(1.0, 0.25),
		Vector2(0.4, 0.7), Vector2(0.15, 0.9)]), 8, 1.0, 1.0, PI / 8.0, false)
	LandmarkAeParts.ball(lm, "Gold", Vector3(at.x, y + 2.25, at.z), 0.3, 10, 6)

# --- Kiyomizu-dera main hall ---

const KIYOMIZU_M := 30.0

static func kiyomizu(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wood", LandmarkMaterials.pbr("wood", "#5E4632", 2.0))
	lm.use("Plaster", LandmarkMaterials.pbr("render", "#E9E3D5", 3.0))
	lm.use("Bark", LandmarkMaterials.pbr("wood", "#4B3E33", 1.5))
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#8C867A", 3.0))
	lm.use("Shadow", LandmarkMaterials.paint("#26221F", 0.9, 0.0))
	var yf := 13.0
	# The kakezukuri: a grid of keyaki pillars to the ground on stone
	# footings, tied by four levels of nuki each way (two in each
	# direction, staggered), the hillside block behind them.
	var rows := [20.0, 17.0, 14.0, 11.0, 8.0, 4.5, 1.0, -2.5]
	for r in rows:
		var z: float = r
		var xmax := 9.0 if z > 17.5 else 15.0
		for i in range(-5, 6):
			var x := 3.0 * i
			if absf(x) <= xmax:
				lm.frustum("Wood", Vector3(x, 0.4, z), 0.4, 0.36, yf - 0.4, 16 if z > 17.5 else 8, PI / 8.0)
				lm.frustum("Stone", Vector3(x, 0.0, z), 0.62, 0.55, 0.4, 8, PI / 8.0)
		for y in [3.4, 6.6, 9.8]:
			lm.beam("Wood", Vector3(-xmax - 0.6, y, z), Vector3(xmax + 0.6, y, z), 0.24, 0.5, Vector3.UP)
	for i in range(-5, 6):
		var x := 3.0 * i
		var zmax := 20.0 if absf(x) <= 9.0 else 17.0
		for y in [5.0, 8.2, 11.4]:
			lm.beam("Wood", Vector3(x, y, -2.5), Vector3(x, y, zmax + 0.6), 0.24, 0.5, Vector3.UP)
	LandmarkAeParts.batter(lm, "Stone", 0, -9.4, 34.0, 11.8, 33.0, 11.0, 0.0, yf)
	# Stage deck (19.2 x 10 m) of planks on joists, hall floor, and the
	# railing with its posts and capped corner posts.
	LandmarkEahParts.slab(lm, "Wood", Vector3(-9.6, yf - 0.6, 10.0), Vector3(9.6, yf - 0.3, 20.2))
	for k in 24:
		lm.box("Wood", Vector3(-9.2 + 0.8 * k, yf - 0.15, 15.1), Vector3(0.76, 0.3, 10.2), Basis(), 0.0)
	LandmarkEahParts.slab(lm, "Wood", Vector3(-16.3, yf - 0.5, -14.6), Vector3(16.3, yf, 10.0))
	LandmarkEahDetail.railing(lm, "Wood", Vector3(-9.5, yf, 20.0), Vector3(9.5, yf, 20.0), 1.05, 1.2, 0.18)
	for s in [-1.0, 1.0]:
		LandmarkEahDetail.railing(lm, "Wood", Vector3(s * 9.5, yf, 10.2), Vector3(s * 9.5, yf, 20.0), 1.05, 1.2, 0.18)
		lm.lathe("Bark", Vector3(s * 9.5, yf + 1.1, 20.0), PackedVector2Array([Vector2(0.14, 0), Vector2(0.18, 0.12),
			Vector2(0.1, 0.3), Vector2(0.0, 0.42)]), 8)
	# Hall core (9 x 7 bays): front row of columns, lattice shutters
	# (shitomi-do) in the front bays, nuki and bracket band.
	lm.box("Plaster", Vector3(0, yf + 3.0, -3.0), Vector3(26.1, 6.0, 20.3))
	for i in 10:
		LandmarkEahParts.column(lm, "Wood", Vector3(-13.05 + 2.9 * i, yf, 10.0), 3.7, 0.3)
		LandmarkEahParts.column(lm, "Wood", Vector3(-13.05 + 2.9 * i, yf, 7.25), 6.0, 0.3)
	LandmarkEahDetail.bays(lm, "Wood", "Shadow", Vector3(0, yf, -3.0), Vector2(26.1, 20.3), 5.4, 9, 7,
		func(face: int, i: int) -> int: return 1 if face == 0 and absi(i - 4) <= 2 else 2)
	LandmarkEahDetail.ring_beams(lm, "Wood", Vector3(0, 0, -3.0), Vector2(26.4, 20.6), yf + 5.6, 0.4, 0.3)
	# Skirt roof, bracket band and the main hip roof (ridge at 30 m).
	var sc := Vector3(0, yf + 3.7, -3.0)
	LandmarkAeParts.hip_roof(lm, "Bark", sc, Vector2(36.0, 28.7), Vector2(26.1, 20.3), 2.6, 0.9)
	LandmarkAeParts.eave_fascia(lm, "Wood", sc, Vector2(36.0, 28.7), 0.9, 0.3, Vector2(26.1, 20.3), 0.7)
	LandmarkAeParts.brackets(lm, "Wood", Vector3(0, yf + 6.0, -3.0), 26.1, 20.3, 0.8, 1.45)
	var mc := Vector3(0, yf + 6.95, -3.0)
	LandmarkAeParts.hip_roof(lm, "Bark", mc, Vector2(33.0, 25.0), Vector2(18.0, 2.5), 9.6, 0.8)
	LandmarkAeParts.eave_fascia(lm, "Wood", mc, Vector2(33.0, 25.0), 0.8, 0.35, Vector2(26.1, 20.3), 0.7)
	LandmarkAeParts.hip_ridges(lm, "Bark", mc, Vector2(33.0, 25.0), Vector2(18.0, 2.5), 9.6, 0.8, 0.4)
	LandmarkEahDetail.ridge(lm, "Bark", -9.4, 9.4, mc.y + 9.35, -3.0, 1.0, KIYOMIZU_M - mc.y - 9.35)
	# Gabled (irimoya) wing galleries either side of the stage.
	for s in [-1.0, 1.0]:
		var wx: float = s * 13.05
		LandmarkEahParts.slab(lm, "Plaster", Vector3(wx - 3.15, yf, 10.2), Vector3(wx + 3.15, yf + 4.2, 18.0))
		for k in 3:
			LandmarkEahParts.column(lm, "Wood", Vector3(wx - 3.0 + 3.0 * k, yf, 18.1), 4.2, 0.22)
		LandmarkEahDetail.lattice(lm, "Wood", "Shadow", Vector3(wx, yf + 2.4, 18.05), Vector3(0, 0, 1), 4.4, 2.2, 8, 2)
		LandmarkEahDetail.lattice(lm, "Wood", "Shadow", Vector3(wx - s * 3.2, yf + 2.4, 14.1), Vector3(-s, 0, 0), 5.6, 2.2, 10, 2)
		var wc := Vector3(wx, yf + 4.4, 14.1)
		LandmarkEahParts.irimoya_z(lm, "Bark", "Plaster", wc, Vector2(8.4, 10.0), Vector2(3.0, 5.6), 2.0, 1.8, 0.7)
		LandmarkAeParts.eave_fascia(lm, "Wood", wc, Vector2(8.4, 10.0), 0.7, 0.25, Vector2(6.3, 7.8), 0.7)
	lm.commit(model)
