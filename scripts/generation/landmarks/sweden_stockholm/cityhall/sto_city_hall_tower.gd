class_name StoCityHallTower
extends RefCounted

## City Hall's tower (106 m) at the south-east corner, and Birger Jarl's
## cenotaph at its east foot. Heights from the front photo scaled by the
## 106 m total (shaft cornice at about 67 m, lantern columns to 86 m, the
## gilded cupola to 98 m, the mast and crowns to 106 m).
## - Shaft: 16.5 m square plain brick on a dark granite base, with slit
##   windows (a stair row on every face, a pair near the top), a tall
##   mullioned window and the narrow copper-capped bay at the foot of the
##   south face, slim poles at the corners above the cornice.
## - Stone cornice and the dark copper hipped base, the gallery with its
##   copper railing, the open lantern of twelve slim copper columns round
##   a bronze bell and a dark (night-lit) core, the entablature.
## - The gilded cupola: a stepped base, the onion, the ball and finial,
##   then the mast forking into the three small crowns of Tre Kronor.
## - Cenotaph: gilded sarcophagus on a stone plinth under a four-column
##   canopy with a copper hip.

const SHAFT_M := 67.0

static func build(lm: LandmarkMesh, c: Vector2, w: float, top: float) -> void:
	var t := Vector3(c.x, 0.0, c.y)
	_shaft(lm, t, w)
	_lantern(lm, t, w)
	_cupola(lm, t, top)
	_cenotaph(lm, Vector3(71.3, 0.0, 31.3))

static func _shaft(lm: LandmarkMesh, t: Vector3, w: float) -> void:
	lm.box("Granite", t + Vector3(0, 1.6, 0), Vector3(w + 1.4, 3.2, w + 1.4))
	lm.box("Brick", t + Vector3(0, SHAFT_M * 0.5, 0), Vector3(w - 0.4, SHAFT_M, w - 0.4))
	for f in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * f)
		var face := w * 0.5 - 0.2
		# Stair windows in a column, a pair near the belfry.
		for k in 5:
			lm.box("Windows", t + r * Vector3(0, 12.0 + 9.0 * float(k), face + 0.03), Vector3(0.55, 1.9, 0.06), r, 0.0)
		for s in [-1.6, 1.6]:
			lm.box("Windows", t + r * Vector3(float(s), 60.5, face + 0.03), Vector3(0.75, 2.8, 0.06), r, 0.0)
			lm.box("Stone", t + r * Vector3(float(s), 62.1, face + 0.06), Vector3(1.0, 0.25, 0.12), r, 0.0)
		# Shallow blind niche low on the face, a stone sill course above the base.
		lm.box("Stone", t + r * Vector3(0, 3.4, face + 0.1), Vector3(w - 0.2, 0.4, 0.3), r, 0.0)
	# The south face: tall window and the narrow bay with its copper needle.
	var south := Vector3(0, 0, 1)
	lm.box("Windows", t + south * (w * 0.5 + 0.02) + Vector3(0, 6.2, 0), Vector3(1.4, 5.2, 0.06), Basis(), 0.0)
	lm.box("Brick", t + south * (w * 0.5 + 0.2) + Vector3(0, 13.0, 0), Vector3(1.8, 20.0, 0.8))
	lm.box("Windows", t + south * (w * 0.5 + 0.62) + Vector3(0, 9.0, 0), Vector3(0.7, 2.6, 0.06), Basis(), 0.0)
	lm.lathe("Copper", t + south * (w * 0.5 + 0.2) + Vector3(0, 23.0, 0), PackedVector2Array([Vector2(1.5, 0.0),
		Vector2(0.0, 5.0)]), 4, 1.0, 0.7, PI * 0.25, false)
	lm.frustum("Gilt", t + south * (w * 0.5 + 0.2) + Vector3(0, 28.0, 0), 0.06, 0.02, 1.4, 4)
	# Cornice, dark copper hipped base and corner poles.
	lm.box("Stone", t + Vector3(0, SHAFT_M + 0.2, 0), Vector3(w + 1.6, 1.0, w + 1.6))
	lm.lathe("Copper", t + Vector3(0, SHAFT_M + 0.7, 0), PackedVector2Array([Vector2(0.7071 * (w + 1.6) * 1.0, 0.0),
		Vector2(0.7071 * (w - 4.4), 2.6)]), 4, 1.0, 1.0, PI * 0.25, false)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var p := t + Vector3(sx * (w * 0.5 + 0.4), SHAFT_M + 0.7, sz * (w * 0.5 + 0.4))
			lm.frustum("Copper", p, 0.16, 0.08, 7.5, 6)
			lm.lathe("Gilt", p + Vector3(0, 7.5, 0), PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.22, 0.2),
				Vector2(0.0, 0.5)]), 6)

static func _lantern(lm: LandmarkMesh, t: Vector3, w: float) -> void:
	var gy := SHAFT_M + 3.3
	var half := (w - 4.4) * 0.5
	lm.box("Stone", t + Vector3(0, gy + 0.2, 0), Vector3(half * 2.0 + 0.6, 0.4, half * 2.0 + 0.6))
	# Gallery railing: posts and two rails round the square.
	for f in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * f)
		for k in 12:
			lm.box("Copper", t + r * Vector3(-half + 0.2 + (half * 2.0 - 0.4) * float(k) / 11.0, gy + 0.95, half + 0.1),
				Vector3(0.1, 1.1, 0.1), r, 0.0)
		lm.box("Copper", t + r * Vector3(0, gy + 1.55, half + 0.1), Vector3(half * 2.0 + 0.2, 0.12, 0.12), r, 0.0)
		lm.box("Copper", t + r * Vector3(0, gy + 0.6, half + 0.1), Vector3(half * 2.0 + 0.2, 0.1, 0.1), r, 0.0)
	# Open lantern: columns round the bell; the ceiling lights at night.
	var ly := gy + 0.4
	var lh := 13.4
	lm.disc("HallLamp", t + Vector3(0, ly + lh - 0.05, 0), Vector3.DOWN, 4.6, 16)
	lm.disc("Stone", t + Vector3(0, ly + 0.02, 0), Vector3.UP, 4.6, 16)
	for k in 12:
		var a := TAU * float(k) / 12.0
		var p := t + Vector3(cos(a) * 4.5, ly, sin(a) * 4.5)
		lm.frustum("Copper", p, 0.3, 0.24, lh, 8)
		lm.box("Copper", p + Vector3(0, 0.15, 0), Vector3(0.7, 0.3, 0.7), Basis(Vector3.UP, -a), 0.0)
	lm.lathe("Bronze", t + Vector3(0, ly + 5.0, 0), PackedVector2Array([Vector2(0.2, 0.0), Vector2(1.1, 0.4),
		Vector2(1.35, 2.2), Vector2(1.0, 3.4), Vector2(0.0, 3.6)]), 12)
	var ey := ly + lh
	lm.frustum("Copper", t + Vector3(0, ey, 0), 5.2, 5.0, 0.9, 12)
	lm.frustum("Stone", t + Vector3(0, ey + 0.9, 0), 5.5, 5.5, 0.25, 12)

## The gilded cupola, mast and the three crowns, ending exactly at `top`.
static func _cupola(lm: LandmarkMesh, t: Vector3, top: float) -> void:
	var by := SHAFT_M + 3.3 + 0.4 + 13.4 + 1.15
	var prof := PackedVector2Array()
	for p in [Vector2(5.2, 0.0), Vector2(4.9, 0.5), Vector2(4.0, 1.4), Vector2(3.3, 2.4), Vector2(3.6, 3.6),
			Vector2(3.5, 4.8), Vector2(2.6, 6.2), Vector2(1.5, 7.6), Vector2(0.9, 8.6), Vector2(1.1, 9.2),
			Vector2(0.9, 9.8), Vector2(0.4, 10.6), Vector2(0.18, 11.8)]:
		prof.append(p)
	lm.lathe("Gilt", t + Vector3(0, by, 0), prof, 16)
	var my := by + 11.8
	var crown_r := 0.75
	var crown_h := crown_r * 1.5
	var fork := top - crown_h - 1.6
	lm.frustum("Gilt", t + Vector3(0, my, 0), 0.18, 0.1, fork - my, 6)
	for k in 3:
		var a := TAU * float(k) / 3.0 + PI * 0.5
		var off := Vector3(cos(a), 0, sin(a)) * 1.7
		lm.beam("Gilt", t + Vector3(0, fork, 0), t + off + Vector3(0, top - crown_h - 0.1, 0), 0.12, 0.12)
		_crown(lm, t + off + Vector3(0, top - crown_h, 0), crown_r)

## A small open crown: a gilt band with four points; 1.5 r tall.
static func _crown(lm: LandmarkMesh, base: Vector3, r: float) -> void:
	lm.frustum("Gilt", base, r, r * 1.15, r * 0.7, 12)
	for k in 4:
		var a := TAU * float(k) / 4.0
		lm.frustum("Gilt", base + Vector3(cos(a) * r, r * 0.7, sin(a) * r), r * 0.2, 0.0, r * 0.8, 4)
		lm.lathe("Gilt", base + Vector3(cos(a + PI * 0.25) * r * 1.1, r * 0.7, sin(a + PI * 0.25) * r * 1.1),
			PackedVector2Array([Vector2(0.0, 0), Vector2(r * 0.12, r * 0.12), Vector2(0.0, r * 0.24)]), 6)

## Birger Jarl's gilded cenotaph under its copper-roofed canopy.
static func _cenotaph(lm: LandmarkMesh, c: Vector3) -> void:
	lm.box("Stone", c + Vector3(0, 0.3, 0), Vector3(2.9, 0.6, 4.2))
	lm.box("Stone", c + Vector3(0, 1.0, 0), Vector3(2.4, 0.8, 3.6))
	lm.box("Gilt", c + Vector3(0, 1.75, 0), Vector3(1.6, 0.7, 2.8))
	lm.box("Gilt", c + Vector3(0, 2.2, 0), Vector3(1.3, 0.2, 2.5))
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			lm.frustum("Stone", c + Vector3(sx * 1.25, 0.6, sz * 1.9), 0.16, 0.14, 3.4, 8)
	lm.lathe("Copper", c + Vector3(0, 4.0, 0), PackedVector2Array([Vector2(2.2, 0.0), Vector2(0.0, 1.4)]), 4,
		0.8, 1.15, PI * 0.25, false)
