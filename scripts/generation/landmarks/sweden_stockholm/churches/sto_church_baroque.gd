class_name StoChurchBaroque
extends RefCounted

## Roof and gable pieces for the Stockholm hero churches built in
## LandmarkSsRoyal2 (Storkyrkan, Katarina, Hedvig Eleonora), written from
## the reference photos (visual-plan/refs/landmarks/<type>/):
## - Storkyrkan's roof is two tiers: the nave's patinated green copper
##   roof stands on a clerestory, and the two aisle slopes below it are
##   dark sheet metal; the east end carries a tall attic gable with a
##   round-arched top between low side wedges.
## - Katarina's corner towers end in slender dark needle spires on a
##   white lantern stage.
## True metres, model +X along the nave, +Z south, Y up.

## The two-tier roof over x0..x1 (eaves at `eave`, aisle outer edge at
## +-hz): a clerestory of half width `nhz` and height `step` in the wall
## colour, dark `slate` aisle slopes from the eave up to it, and a
## `copper` gabled nave roof `rise` high on top, with its seams, ridge
## roll and the wall wedges that close the aisle roofs at both ends.
static func stepped_roof(lm: LandmarkMesh, slate: String, copper: String, wall: String, x0: float, x1: float,
		hz: float, eave: float, nhz: float, step: float, rise: float) -> void:
	var length := x1 - x0
	var cx := (x0 + x1) * 0.5
	lm.box(wall, Vector3(cx, eave + step * 0.5, 0), Vector3(length, step, 2.0 * nhz), Basis(), 0.0)
	var over := 0.5
	for s in [-1.0, 1.0]:
		var sg: float = s
		var lo := eave - over * step / (hz - nhz)
		lm.quad(slate, Vector3(x0 - over, lo, sg * (hz + over)), Vector3(x1 + over, lo, sg * (hz + over)),
			Vector3(x1 + over, eave + step, sg * nhz), Vector3(x0 - over, eave + step, sg * nhz),
			Vector3(0, hz - nhz, sg * step).normalized())
		for e in [x0, x1]:
			var xe: float = e
			var n := Vector3(1.0 if xe > cx else -1.0, 0, 0)
			lm.tri(wall, Vector3(xe, eave, sg * hz), Vector3(xe, eave, sg * nhz), Vector3(xe, eave + step, sg * nhz),
				n, n, n, Vector2.ZERO, Vector2(hz - nhz, 0), Vector2(hz - nhz, -step))
	var along := Basis(Vector3.UP, PI * 0.5)
	lm.gable(copper, Vector3(cx, eave + step, 0), 2.0 * nhz, length, rise, along, 0.3, wall)
	lm.box(copper, Vector3(cx, eave + step + rise + 0.15, 0), Vector3(length + 0.6, 0.4, 0.5), Basis(), 0.0)
	var seams := int(length / 1.6)
	for k in seams + 1:
		var x := x0 + length * float(k) / float(seams)
		for sz in [-1.0, 1.0]:
			lm.beam(copper, Vector3(x, eave + step - 0.05, float(sz) * (nhz + 0.3)),
				Vector3(x, eave + step + rise + 0.08, 0), 0.08, 0.1)

## The attic gable of a front facing `o`, standing on the eave line at
## `c` (centre): a slab `hw` half wide, `rect` tall, topped by a round
## arch of radius `hw` (so `rect + hw` high in all), a stone coping
## round the arch and the corner scrolls' piers, an oculus and a cross.
static func arched_gable(lm: LandmarkMesh, wall: String, trim: String, glass: String, gilt: String,
		c: Vector3, o: Vector3, hw: float, rect: float, thick: float = 1.2) -> void:
	var r := Vector3.UP.cross(o).normalized()
	var bas := Basis(r, Vector3.UP, o)
	lm.box(wall, c + Vector3.UP * rect * 0.5 - o * thick * 0.5, Vector3(2.0 * hw, rect, thick), bas, 0.0)
	var steps := 14
	var ctr := c + Vector3.UP * rect
	var prev := ctr + r * hw
	for side in [0, 1]:
		var f: Vector3 = o * 0.01 if side == 0 else -o * (thick + 0.01)
		var n: Vector3 = o if side == 0 else -o
		for k in steps:
			var t0 := PI * float(k) / float(steps)
			var t1 := PI * float(k + 1) / float(steps)
			lm.tri(wall, ctr + f, ctr + f + (r * cos(t0) + Vector3.UP * sin(t0)) * hw,
				ctr + f + (r * cos(t1) + Vector3.UP * sin(t1)) * hw, n, n, n, Vector2.ZERO,
				Vector2(cos(t0), sin(t0)) * hw, Vector2(cos(t1), sin(t1)) * hw)
	for k in steps:
		var t1 := PI * float(k + 1) / float(steps)
		var p := ctr + (r * cos(t1) + Vector3.UP * sin(t1)) * hw
		lm.beam(trim, prev - o * thick * 0.5, p - o * thick * 0.5, 0.5, thick + 0.5, o)
		prev = p
	lm.box(trim, c + Vector3.UP * 0.4 - o * thick * 0.5, Vector3(2.0 * hw + 1.0, 0.8, thick + 0.5), bas, 0.0)
	for s in [-1.0, 1.0]:
		lm.box(trim, c + r * float(s) * hw + Vector3.UP * (rect * 0.5 + 0.2) - o * thick * 0.5,
			Vector3(0.9, rect + 0.4, thick + 0.4), bas, 0.0)
	var oc := ctr + Vector3.UP * hw * 0.25 + o * 0.04
	lm.disc(glass, oc, o, hw * 0.3, 18)
	var ring := oc + r * (hw * 0.3 + 0.2)
	for k in 18:
		var a := TAU * float(k + 1) / 18.0
		var p2 := oc + (r * cos(a) + Vector3.UP * sin(a)) * (hw * 0.3 + 0.2)
		lm.beam(trim, ring, p2, 0.35, 0.3, o)
		ring = p2
	var top := ctr + Vector3.UP * hw - o * thick * 0.5
	lm.box(gilt, top + Vector3.UP * 1.3, Vector3(0.22, 2.6, 0.22), Basis(), 0.0)
	lm.box(gilt, top + Vector3.UP * 1.8, Vector3(1.3, 0.22, 0.22), bas, 0.0)

## A slender needle spire on a small stone-and-white lantern stage: the
## octagonal `copper`-key spire rises from radius `r` over `h`, to a gilt
## ball at the tip. `base` is the foot of the spire.
static func needle(lm: LandmarkMesh, key: String, gilt: String, base: Vector3, r: float, h: float) -> void:
	lm.lathe(key, base, PackedVector2Array([Vector2(r, 0), Vector2(r * 0.86, h * 0.1), Vector2(r * 0.48, h * 0.45),
		Vector2(r * 0.22, h * 0.8), Vector2(0.06, h)]), 8, 1.0, 1.0, PI / 8.0, false)
	lm.lathe(gilt, base + Vector3.UP * h, LandmarkFhUtil.ball(r * 0.2), 8)

## A horizontal run of rustication joints on an octagon or box face: used
## by Hedvig Eleonora, whose walls are channelled every `pitch` metres
## from y0 to y1 on the face from `a` along `r`, `length` wide facing `o`.
static func channels(lm: LandmarkMesh, key: String, a: Vector3, r: Vector3, o: Vector3, length: float, y0: float,
		y1: float, pitch: float, gap_w: float = 0.0) -> void:
	var bas := Basis(r, Vector3.UP, o)
	var n := int((y1 - y0) / pitch)
	# A door gap of `gap_w` at the middle splits each line in two.
	var runs: Array = [[0.0, length]] if gap_w <= 0.0 else [[0.0, (length - gap_w) * 0.5], [(length + gap_w) * 0.5, length]]
	for k in n + 1:
		var y := y0 + pitch * float(k)
		for run in runs:
			var x0: float = run[0]
			var x1: float = run[1]
			lm.box(key, a + r * (x0 + x1) * 0.5 + Vector3.UP * y + o * 0.42, Vector3(x1 - x0, 0.14, 0.08), bas, 0.0)

## A plain triangular pediment dressing on a gable end facing `o` whose
## eave line is centred at `c` (half width `hw`, `rise` to the apex):
## raking cornices, a horizontal one under it and an oval oculus in the
## field (Katarina's arms end this way, without scrolls or urns).
static func plain_pediment(lm: LandmarkMesh, trim: String, glass: String, c: Vector3, o: Vector3, hw: float,
		rise: float) -> void:
	var r := Vector3.UP.cross(o).normalized()
	var apex := c + Vector3.UP * rise + o * 0.25
	for s in [-1.0, 1.0]:
		lm.beam(trim, c + r * float(s) * (hw + 0.4) + o * 0.25 + Vector3.UP * 0.15, apex + Vector3.UP * 0.35, 0.7,
			0.5, o)
	lm.box(trim, c + o * 0.2 + Vector3.UP * 0.3, Vector3(2.0 * hw + 0.6, 0.6, 0.4), Basis(r, Vector3.UP, o), 0.0)
	var oc := c + Vector3.UP * rise * 0.38 + o * 0.06
	var orad := minf(rise * 0.2, 1.8)
	lm.disc(glass, oc, o, orad, 18)
	var prev := oc + r * (orad + 0.25)
	for k in 18:
		var t := TAU * float(k + 1) / 18.0
		var p := oc + (r * cos(t) + Vector3.UP * sin(t)) * (orad + 0.25)
		lm.beam(trim, prev, p, 0.35, 0.3, o)
		prev = p
