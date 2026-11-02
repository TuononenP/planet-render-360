class_name LandmarkEahTemples
extends RefCounted

## Japanese temples in true metres: the Todai-ji Great Buddha Hall (48.7 m:
## the 57 x 50 m two-tier hipped timber hall on its stone platform, grey
## tiles, gilt ridge horns, curved front gable), Kiyomizu-dera's main hall
## (30 m to the ridge: the hip-roofed bark-thatch hall and its 13 m wooden
## stage on a grid of 120 pillars, y = 0 at the pillar feet) and the
## Senso-ji precinct at Asakusa (53 m to the pagoda finial: the Kaminarimon
## lantern gate, the Nakamise shop street, the two-storey Hozomon, the main
## hall and the five-storey pagoda west of it). Halls face south (+Z); the
## Senso-ji model is turned a quarter circle so its 425 m axis runs along X
## (registry span_m), which is how the 110 m-wide strip of mapped buildings
## it replaces is cleared.

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
	# Two-course stone platform and the central stair.
	LandmarkEahParts.slab(lm, "Stone", Vector3(-35.0, -1.5, -31.0), Vector3(35.0, 1.3, 31.0))
	LandmarkEahParts.slab(lm, "Stone", Vector3(-30.5, 1.3, -27.0), Vector3(30.5, 2.8, 27.0))
	LandmarkEahParts.stairs(lm, "Stone", 0.0, 31.0, 0.0, 9.0, 8, 0.35, 0.5)
	var yf := 2.8
	# Lower storey: 7 x 7 bays of columns round a plastered core, a wooden
	# door in each of the three middle bays, lattice windows either side.
	LandmarkEahParts.colonnade(lm, "Timber", Vector2.ZERO, Vector2(46.0, 39.0), yf, 9.4, 7, 7, 0.6, 10)
	lm.box("Plaster", Vector3(0, yf + 4.7, 0), Vector3(40.0, 9.4, 33.0))
	for i in 7:
		var bx := -18.0 + 6.0 * i
		var door := absi(i - 3) <= 1
		lm.box("Timber" if door else "Shadow", Vector3(bx, yf + (3.7 if door else 4.4), 16.56),
			Vector3(4.6 if door else 2.0, 7.2 if door else 4.6, 0.16))
	LandmarkEahParts.slab(lm, "Timber", Vector3(-24.0, yf + 9.4, -21.0), Vector3(24.0, yf + 10.4, 21.0))
	# Lower (skirt) roof, 57 x 50.5 m at the eaves, then the upper storey.
	var y1 := yf + 10.4
	LandmarkAeParts.hip_roof(lm, "Tile", Vector3(0, y1, 0), Vector2(57.0, 50.5), Vector2(34.0, 27.0), 5.0, 1.0)
	var y2 := y1 + 5.0
	LandmarkEahParts.colonnade(lm, "Timber", Vector2.ZERO, Vector2(33.0, 26.0), y2, 9.0, 7, 6, 0.5, 10)
	lm.box("Plaster", Vector3(0, y2 + 4.5, 0), Vector3(30.0, 9.0, 23.0))
	for i in 7:
		lm.box("Shadow", Vector3(-12.0 + 4.0 * i, y2 + 4.6, 11.56), Vector3(1.6, 4.4, 0.16))
	LandmarkEahParts.slab(lm, "Timber", Vector3(-17.5, y2 + 9.0, -14.0), Vector3(17.5, y2 + 10.0, 14.0))
	# Great upper roof (hip below, gable above), ridge roll and gilt horns.
	var y3 := y2 + 10.0
	LandmarkEahParts.irimoya(lm, "Tile", "Plaster", Vector3(0, y3, 0), Vector2(49.0, 42.0),
		Vector2(34.0, 14.0), 10.4, 6.6, 1.0)
	var ridge := y3 + 17.0
	LandmarkEahParts.slab(lm, "Tile", Vector3(-18.0, ridge, -0.9), Vector3(18.0, ridge + 0.8, 0.9))
	for s in [-1.0, 1.0]:
		LandmarkEahParts.horn(lm, "Gold", Vector3(s * 17.5, ridge + 0.4, 0), TODAIJI_M - ridge - 0.4, -s, 0.6)
	# Curved front gable (karahafu) over the middle bays.
	lm.gable("Tile", Vector3(0, y1, 21.5), 14.0, 9.0, 3.4, Basis(), 0.5, "Plaster")
	lm.box("Gold", Vector3(0, y1 + 1.7, 26.4), Vector3(8.0, 0.35, 0.3))
	lm.commit(model)

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
	# The kakezukuri: a grid of pillars to the ground tied by two levels of
	# beams each way, the hillside block behind them.
	var rows := [20.0, 17.0, 14.0, 11.0, 8.0, 4.5, 1.0, -2.5]
	for r in rows:
		var z: float = r
		var xmax := 9.0 if z > 17.5 else 15.0
		for i in range(-5, 6):
			var x := 3.0 * i
			if absf(x) <= xmax:
				lm.frustum("Wood", Vector3(x, -0.5, z), 0.4, 0.34, yf + 0.5, 8, PI / 8.0)
		for y in [4.6, 8.9]:
			lm.beam("Wood", Vector3(-xmax, y, z), Vector3(xmax, y, z), 0.42, 0.42)
	for i in range(-5, 6):
		var x := 3.0 * i
		var zmax := 20.0 if absf(x) <= 9.0 else 17.0
		for y in [6.7, 11.0]:
			lm.beam("Wood", Vector3(x, y, -2.5), Vector3(x, y, zmax), 0.42, 0.42)
	LandmarkAeParts.batter(lm, "Stone", 0, -9.4, 34.0, 11.8, 33.0, 11.0, -1.0, yf)
	# Stage deck (19.2 x 10 m) and hall floor, stage rails.
	LandmarkEahParts.slab(lm, "Wood", Vector3(-9.6, yf - 0.4, 10.0), Vector3(9.6, yf, 20.2))
	LandmarkEahParts.slab(lm, "Wood", Vector3(-16.3, yf - 0.5, -14.6), Vector3(16.3, yf, 10.0))
	LandmarkEahParts.slab(lm, "Wood", Vector3(-9.6, yf + 0.9, 19.9), Vector3(9.6, yf + 1.05, 20.1))
	for s in [-1.0, 1.0]:
		LandmarkEahParts.slab(lm, "Wood", Vector3(s * 9.5 - 0.1, yf + 0.9, 10.0), Vector3(s * 9.5 + 0.1, yf + 1.05, 20.0))
		for k in 7:
			lm.box("Wood", Vector3(-9.0 + 3.0 * k, yf + 0.5, 20.0), Vector3(0.2, 1.0, 0.2))
	# Hall core (9 x 7 bays), front porch columns, doors.
	lm.box("Plaster", Vector3(0, yf + 3.0, -3.0), Vector3(26.1, 6.0, 20.3))
	for i in 10:
		LandmarkEahParts.column(lm, "Wood", Vector3(-13.05 + 2.9 * i, yf, 10.0), 3.7, 0.3)
	for i in 5:
		lm.box("Shadow", Vector3(-5.8 + 2.9 * i, yf + 2.2, 7.22), Vector3(1.9, 4.2, 0.1))
	# Skirt roof, bracket band and the main hip roof (ridge at 30 m).
	LandmarkAeParts.hip_roof(lm, "Bark", Vector3(0, yf + 3.7, -3.0), Vector2(36.0, 28.7), Vector2(26.1, 20.3), 2.6, 0.9)
	LandmarkEahParts.slab(lm, "Wood", Vector3(-13.6, yf + 6.0, -13.7), Vector3(13.6, yf + 6.8, 7.7))
	LandmarkAeParts.hip_roof(lm, "Bark", Vector3(0, yf + 6.8, -3.0), Vector2(33.0, 25.0), Vector2(18.0, 2.5), 10.2, 0.8)
	# Wing galleries either side of the stage.
	for s in [-1.0, 1.0]:
		var wx: float = s * 13.05
		LandmarkEahParts.slab(lm, "Plaster", Vector3(wx - 3.15, yf, 10.2), Vector3(wx + 3.15, yf + 4.2, 18.0))
		LandmarkAeParts.hip_roof(lm, "Bark", Vector3(wx, yf + 4.4, 14.1), Vector2(8.4, 10.0), Vector2(1.0, 4.0), 3.6, 0.7)
	lm.commit(model)

# --- Senso-ji, Asakusa ---

const SENSOJI_M := 53.0
## Natural frame: south +Z, origin on the registry point; the axis the
## gates stand on is x = SENSO_AXIS_X, Kaminarimon at z = SENSO_Z0 and the
## rest 312 m (Hozomon) and 402 m (main hall) north of it.
const SENSO_AXIS_X := 25.0
const SENSO_Z0 := 207.5

static func senso_ji(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#9C9488", 3.0))
	lm.use("Pave", LandmarkMaterials.pbr("pavement", "#B7ADA0", 4.0))
	lm.use("Lacquer", LandmarkMaterials.paint("#B3281D", 0.6, 0.0))
	lm.use("Tile", LandmarkMaterials.pbr("slate", "#4B5054", 1.5))
	lm.use("Plaster", LandmarkMaterials.pbr("render", "#EDE8DC", 3.0))
	lm.use("Shop", LandmarkMaterials.pbr("render", "#E3D6BD", 3.0))
	lm.use("Wood", LandmarkMaterials.paint("#5C3F2D", 0.8, 0.0))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.use("Shadow", LandmarkMaterials.paint("#26221F", 0.9, 0.0))
	lm.use("Lantern", LandmarkMaterials.lit("#C2261C", 0.35))
	var ax := SENSO_AXIS_X
	_street(lm, ax)
	_kaminarimon(lm, Vector2(ax, SENSO_Z0))
	_hozomon(lm, Vector2(ax, SENSO_Z0 - 312.8))
	_hondo(lm, Vector2(ax, SENSO_Z0 - 401.7))
	_pagoda(lm, Vector2(ax - 58.0, SENSO_Z0 - 385.0))
	var holder := Node3D.new()
	holder.name = "Axis"
	holder.rotation.y = -PI * 0.5
	model.add_child(holder)
	lm.commit(holder)

## Paving of the approach and the forecourt, and the Nakamise: two rows of
## roofed shops (54 east, 35 west) with red piers every 3.3 m.
static func _street(lm: LandmarkMesh, ax: float) -> void:
	var z_end := SENSO_Z0 - 313.0
	LandmarkEahParts.slab(lm, "Pave", Vector3(ax - 4.5, 0.0, z_end), Vector3(ax + 4.5, 0.4, SENSO_Z0 + 4.0))
	LandmarkEahParts.slab(lm, "Pave", Vector3(ax - 28.0, 0.0, SENSO_Z0 - 420.0), Vector3(ax + 28.0, 0.4, z_end))
	for s in [-1.0, 1.0]:
		var x0: float = ax + s * 4.5
		var x1: float = ax + s * 11.5
		var za := SENSO_Z0 - 304.0
		var zb := SENSO_Z0 - 12.0
		LandmarkEahParts.slab(lm, "Shop", Vector3(minf(x0, x1), 0.0, za), Vector3(maxf(x0, x1), 4.4, zb))
		lm.gable("Tile", Vector3((x0 + x1) * 0.5, 4.4, (za + zb) * 0.5), 7.0, zb - za, 2.0, Basis(), 0.5, "Shop")
		LandmarkEahParts.slab(lm, "Shadow", Vector3(x0 - 0.04 * s - 0.05, 0.2, za + 0.5), Vector3(x0 - 0.04 * s + 0.05, 3.2, zb - 0.5))
		var n := int((zb - za) / 3.3)
		for k in n + 1:
			lm.box("Lacquer", Vector3(x0 - 0.15 * s, 2.1, za + 3.3 * k), Vector3(0.3, 4.2, 0.45))

static func _kaminarimon(lm: LandmarkMesh, c: Vector2) -> void:
	LandmarkEahParts.slab(lm, "Stone", Vector3(c.x - 6.2, -0.5, c.y - 3.6), Vector3(c.x + 6.2, 0.8, c.y + 3.6))
	LandmarkEahParts.colonnade(lm, "Lacquer", c, Vector2(10.2, 5.0), 0.8, 5.0, 3, 2, 0.4)
	LandmarkEahParts.slab(lm, "Lacquer", Vector3(c.x - 5.9, 5.8, c.y - 2.8), Vector3(c.x + 5.9, 6.5, c.y + 2.8))
	for s in [-1.0, 1.0]:
		lm.box("Shadow", Vector3(c.x + s * 3.7, 3.0, c.y), Vector3(2.8, 4.4, 4.4))
	LandmarkEahParts.irimoya(lm, "Tile", "Plaster", Vector3(c.x, 6.5, c.y), Vector2(15.0, 9.2),
		Vector2(9.0, 3.0), 2.7, 2.1, 0.6)
	LandmarkEahParts.slab(lm, "Tile", Vector3(c.x - 4.8, 11.3, c.y - 0.5), Vector3(c.x + 4.8, 11.7, c.y + 0.5))
	_lantern(lm, Vector3(c.x, 1.6, c.y + 0.4), 3.9, 1.65)

static func _hozomon(lm: LandmarkMesh, c: Vector2) -> void:
	LandmarkEahParts.slab(lm, "Stone", Vector3(c.x - 11.0, -0.5, c.y - 5.0), Vector3(c.x + 11.0, 0.9, c.y + 5.0))
	LandmarkEahParts.colonnade(lm, "Lacquer", c, Vector2(19.2, 7.2), 0.9, 8.1, 6, 2, 0.5)
	for s in [-1.0, 1.0]:
		var x0: float = c.x + s * 3.0
		var x1: float = c.x + s * 9.6
		LandmarkEahParts.slab(lm, "Lacquer", Vector3(minf(x0, x1), 0.9, c.y - 3.4), Vector3(maxf(x0, x1), 9.0, c.y + 3.4))
		lm.box("Shadow", Vector3(c.x + s * 6.3, 4.4, c.y + 3.46), Vector3(4.4, 5.0, 0.12))
	LandmarkEahParts.slab(lm, "Lacquer", Vector3(c.x - 3.0, 7.4, c.y - 3.4), Vector3(c.x + 3.0, 9.0, c.y + 3.4))
	LandmarkAeParts.hip_roof(lm, "Tile", Vector3(c.x, 9.0, c.y), Vector2(25.6, 11.8), Vector2(15.4, 5.6), 2.4, 0.8)
	LandmarkEahParts.slab(lm, "Lacquer", Vector3(c.x - 7.2, 11.4, c.y - 2.6), Vector3(c.x + 7.2, 16.4, c.y + 2.6))
	for i in 3:
		lm.box("Shadow", Vector3(c.x - 4.2 + 4.2 * i, 13.9, c.y + 2.66), Vector3(1.6, 2.8, 0.12))
	LandmarkEahParts.slab(lm, "Wood", Vector3(c.x - 7.8, 16.4, c.y - 3.0), Vector3(c.x + 7.8, 16.9, c.y + 3.0))
	LandmarkEahParts.irimoya(lm, "Tile", "Plaster", Vector3(c.x, 16.9, c.y), Vector2(24.0, 10.4),
		Vector2(15.0, 3.5), 2.9, 2.4, 0.7)
	LandmarkEahParts.slab(lm, "Tile", Vector3(c.x - 7.5, 22.2, c.y - 0.55), Vector3(c.x + 7.5, 22.7, c.y + 0.55))
	_lantern(lm, Vector3(c.x, 3.4, c.y + 0.4), 3.75, 1.35)

static func _hondo(lm: LandmarkMesh, c: Vector2) -> void:
	LandmarkEahParts.slab(lm, "Stone", Vector3(c.x - 18.0, -0.5, c.y - 16.0), Vector3(c.x + 18.0, 1.2, c.y + 16.0))
	LandmarkEahParts.stairs(lm, "Stone", c.x, c.y + 20.0, 0.0, 7.0, 4, 0.3, 0.9)
	LandmarkEahParts.colonnade(lm, "Lacquer", c, Vector2(32.0, 29.0), 1.2, 9.6, 7, 6, 0.5)
	lm.box("Lacquer", Vector3(c.x, 6.0, c.y), Vector3(30.0, 9.6, 27.0))
	for i in 5:
		lm.box("Shadow", Vector3(c.x - 8.8 + 4.4 * i, 4.6, c.y + 13.56), Vector3(3.6, 6.4, 0.12))
	LandmarkEahParts.slab(lm, "Wood", Vector3(c.x - 17.2, 10.8, c.y - 15.5), Vector3(c.x + 17.2, 11.9, c.y + 15.5))
	LandmarkEahParts.irimoya(lm, "Tile", "Plaster", Vector3(c.x, 11.9, c.y), Vector2(43.0, 37.0),
		Vector2(24.0, 12.0), 8.0, 7.7, 1.0)
	LandmarkEahParts.slab(lm, "Tile", Vector3(c.x - 12.5, 27.6, c.y - 0.8), Vector3(c.x + 12.5, 28.2, c.y + 0.8))
	for s in [-1.0, 1.0]:
		LandmarkEahParts.horn(lm, "Gold", Vector3(c.x + s * 12.0, 28.0, c.y), 1.7, -s, 0.4)
	# Front porch under its own gable, with the great lantern.
	for s in [-1.0, 1.0]:
		LandmarkEahParts.column(lm, "Lacquer", Vector3(c.x + s * 6.5, 1.2, c.y + 20.0), 7.4, 0.45)
	LandmarkEahParts.slab(lm, "Wood", Vector3(c.x - 7.2, 8.6, c.y + 12.0), Vector3(c.x + 7.2, 9.1, c.y + 20.8))
	lm.gable("Tile", Vector3(c.x, 9.1, c.y + 16.5), 15.0, 9.0, 3.2, Basis(), 0.6, "Plaster")
	_lantern(lm, Vector3(c.x, 3.4, c.y + 19.2), 4.5, 1.75)

## Red paper lantern of height h, radius r at the belly, hung from base.
static func _lantern(lm: LandmarkMesh, base: Vector3, h: float, r: float) -> void:
	lm.lathe("Lantern", base, PackedVector2Array([Vector2(r * 0.55, 0), Vector2(r * 0.9, h * 0.12),
		Vector2(r, h * 0.5), Vector2(r * 0.9, h * 0.88), Vector2(r * 0.55, h)]), 14)
	lm.frustum("Shadow", base + Vector3(0, -0.15, 0), r * 0.5, r * 0.5, 0.15, 10)
	lm.frustum("Shadow", base + Vector3(0, h, 0), r * 0.5, r * 0.5, 0.15, 10)

const PAGODA_W := [7.6, 6.9, 6.2, 5.6, 5.0]
const PAGODA_EAVE := [15.0, 13.6, 12.2, 10.9, 9.7]
const PAGODA_H := [6.0, 5.4, 4.9, 4.6, 4.2]
const PAGODA_RISE := [3.0, 2.8, 2.6, 2.4, 2.4]

## The five-storey pagoda: 5 m platform, five red storeys under grey tile
## hip roofs, gilt sorin spire to 53 m.
static func _pagoda(lm: LandmarkMesh, c: Vector2) -> void:
	LandmarkEahParts.slab(lm, "Stone", Vector3(c.x - 10.0, -0.5, c.y - 10.0), Vector3(c.x + 10.0, 5.0, c.y + 10.0))
	LandmarkEahParts.stairs(lm, "Stone", c.x, c.y + 14.5, 0.0, 5.0, 10, 0.5, 0.45)
	var y := 5.0
	for i in 5:
		var w: float = PAGODA_W[i]
		var h: float = PAGODA_H[i]
		lm.box("Lacquer", Vector3(c.x, y + h * 0.5, c.y), Vector3(w, h, w))
		for n in [Vector3(0, 0, 1), Vector3(0, 0, -1), Vector3(1, 0, 0), Vector3(-1, 0, 0)]:
			var nv: Vector3 = n
			var size := Vector3((w - 2.2) * absf(nv.z) + 0.14 * absf(nv.x), h - 1.8,
				(w - 2.2) * absf(nv.x) + 0.14 * absf(nv.z))
			lm.box("Plaster", Vector3(c.x, y + h * 0.5, c.y) + nv * (w * 0.5 + 0.02), size)
		y += h
		var nxt: float = PAGODA_W[i + 1] if i < 4 else 1.0
		LandmarkAeParts.hip_roof(lm, "Tile", Vector3(c.x, y, c.y), Vector2(PAGODA_EAVE[i], PAGODA_EAVE[i]),
			Vector2(nxt + 0.8, nxt + 0.8), PAGODA_RISE[i], 0.9)
		y += PAGODA_RISE[i]
	# Sorin: pedestal, bowl, nine rings on the mast, flame, jewel.
	lm.box("Gold", Vector3(c.x, y + 0.25, c.y), Vector3(1.8, 0.5, 1.8))
	lm.lathe("Gold", Vector3(c.x, y + 0.5, c.y), PackedVector2Array([Vector2(1.2, 0), Vector2(1.4, 0.35),
		Vector2(0.9, 0.9), Vector2(0.3, 1.2)]), 12)
	lm.frustum("Gold", Vector3(c.x, y + 1.7, c.y), 0.18, 0.12, SENSOJI_M - y - 2.2, 8)
	for k in 9:
		lm.frustum("Gold", Vector3(c.x, y + 2.2 + 0.58 * k, c.y), 1.15 - 0.07 * k, 1.15 - 0.07 * k, 0.12, 12)
	lm.lathe("Gold", Vector3(c.x, y + 7.0, c.y), PackedVector2Array([Vector2(0.55, 0), Vector2(0.6, 0.5),
		Vector2(0.3, 1.1), Vector2(0.05, 1.6)]), 10)
	LandmarkAeParts.ball(lm, "Gold", Vector3(c.x, SENSOJI_M - 0.4, c.y), 0.4, 10, 6)
