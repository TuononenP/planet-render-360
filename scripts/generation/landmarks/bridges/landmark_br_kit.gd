class_name LandmarkBrKit
extends RefCounted

## Shared parts of the bridges batch, in true metres on LandmarkMesh,
## built along +X with y = 0 at the water: suspension cables with their
## hangers, trussed and plated decks, portal towers, stay fans, masonry
## arcades (solid spandrels) and approach viaducts.

## Steel, road and concrete materials every bridge draws with.
static func base_mats(lm: LandmarkMesh, steel_hex: String, concrete_hex: String = "#B9B3A8") -> void:
	lm.use("Steel", LandmarkMaterials.paint(steel_hex, 0.58, 0.35))
	lm.use("Deck", LandmarkMaterials.pbr("asphalt", "#3B3B3B", 4.0))
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", concrete_hex, 4.0))

## Square tube tapering from half-widths (hx0, hz0) at `base` to
## (hx1, hz1) `h` higher; the top is capped, the foot is buried.
static func tapered_box(lm: LandmarkMesh, key: String, base: Vector3, hx0: float, hz0: float,
		hx1: float, hz1: float, h: float) -> void:
	var sx: Array[float] = [-1.0, 1.0, 1.0, -1.0]
	var sz: Array[float] = [-1.0, -1.0, 1.0, 1.0]
	var up := Vector3(0, h, 0)
	for i in 4:
		var j := (i + 1) % 4
		var a := base + Vector3(sx[i] * hx0, 0, sz[i] * hz0)
		var b := base + Vector3(sx[j] * hx0, 0, sz[j] * hz0)
		var c := base + up + Vector3(sx[j] * hx1, 0, sz[j] * hz1)
		var d := base + up + Vector3(sx[i] * hx1, 0, sz[i] * hz1)
		var n := Vector3(sx[i] + sx[j], 0, sz[i] + sz[j]).normalized()
		lm.quad(key, a, b, c, d, n)
	lm.quad(key, base + up + Vector3(-hx1, 0, -hz1), base + up + Vector3(hx1, 0, -hz1),
		base + up + Vector3(hx1, 0, hz1), base + up + Vector3(-hx1, 0, hz1), Vector3.UP)

## Prism over an XY polygon (x along the bridge, y up) from z0 to z1:
## the way a masonry arch with its spandrels is one solid.
static func extrude_xy(lm: LandmarkMesh, key: String, poly: PackedVector2Array, z0: float,
		z1: float) -> void:
	var area := 0.0
	for i in poly.size():
		var p := poly[i]
		var q := poly[(i + 1) % poly.size()]
		area += p.x * q.y - q.x * p.y
	var sgn := 1.0 if area > 0.0 else -1.0
	var u := 0.0
	for i in poly.size():
		var p := poly[i]
		var q := poly[(i + 1) % poly.size()]
		var e := q - p
		if e.length() < 0.001:
			continue
		var n := Vector3(e.y, -e.x, 0).normalized() * sgn
		lm.quad(key, Vector3(p.x, p.y, z0), Vector3(q.x, q.y, z0), Vector3(q.x, q.y, z1),
			Vector3(p.x, p.y, z1), n, Vector2(u, 0))
		u += e.length()
	var idx := Geometry2D.triangulate_polygon(poly)
	for t in range(0, idx.size(), 3):
		var a := poly[idx[t]]
		var b := poly[idx[t + 1]]
		var c := poly[idx[t + 2]]
		for end in [0, 1]:
			var z: float = z1 if end == 1 else z0
			var n := Vector3(0, 0, 1.0 if end == 1 else -1.0)
			lm.tri(key, Vector3(a.x, a.y, z), Vector3(b.x, b.y, z), Vector3(c.x, c.y, z), n, n, n,
				Vector2(a.x, -a.y), Vector2(b.x, -b.y), Vector2(c.x, -c.y))

## Left-to-right points of an elliptical arch of half-span r and rise ry
## springing at y = spring, centred on cx (seg + 1 points).
static func arch_pts(cx: float, spring: float, r: float, ry: float, seg: int) -> PackedVector2Array:
	var out := PackedVector2Array()
	for k in seg + 1:
		var a := PI * (1.0 - float(k) / seg)
		out.append(Vector2(cx + r * cos(a), spring + ry * sin(a)))
	return out

## Row of arches between pier centres `piers` (x), as solid masonry of
## half-thickness hz: piers from y0, springing at `spring`, openings
## rising rise_k * half-span (capped to leave 1.2 m over the crown) and
## the wall carried up to `top`, centred on z = zc.
static func arcade(lm: LandmarkMesh, key: String, piers: PackedFloat32Array, y0: float, top: float,
		spring: float, rise_k: float, pier_w: float, hz: float, seg: int = 10, zc: float = 0.0) -> void:
	for i in piers.size() - 1:
		var xl := piers[i]
		var xr := piers[i + 1]
		var r := (xr - xl - pier_w) * 0.5
		var ry := minf(r * rise_k, top - 1.2 - spring)
		var poly := PackedVector2Array([Vector2(xl, y0), Vector2(xl + pier_w * 0.5, y0)])
		poly.append_array(arch_pts((xl + xr) * 0.5, spring, r, ry, seg))
		poly.append_array(PackedVector2Array([Vector2(xr - pier_w * 0.5, y0), Vector2(xr, y0),
			Vector2(xr, top), Vector2(xl, top)]))
		extrude_xy(lm, key, poly, zc - hz, zc + hz)

## Evenly spaced pier positions: n bays between x0 and x1.
static func pier_line(x0: float, x1: float, n: int) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	for i in n + 1:
		out.append(lerpf(x0, x1, float(i) / n))
	return out

## Cable of straight members through `pts`, `w` thick.
static func cable_poly(lm: LandmarkMesh, key: String, pts: PackedVector3Array, w: float) -> void:
	for i in pts.size() - 1:
		lm.beam(key, pts[i], pts[i + 1], w, w)

## Height of the main cable at x for the parameter set `p` (see
## suspension): a parabola between the towers tx0..tx1 from `top` down to
## `low` at mid-span, and a side span falling to `end0`/`end1` at e0/e1,
## sagging sag0/sag1 under its chord.
static func cable_y(p: Dictionary, x: float) -> float:
	var tx0: float = p["tx0"]
	var tx1: float = p["tx1"]
	var top: float = p["top"]
	if x >= tx0 and x <= tx1:
		var u := (x - (tx0 + tx1) * 0.5) / ((tx1 - tx0) * 0.5)
		return float(p["low"]) + (top - float(p["low"])) * u * u
	if x < tx0:
		var t := clampf((tx0 - x) / (tx0 - float(p["e0"])), 0.0, 1.0)
		return lerpf(top, float(p["end0"]), t) - float(p.get("sag0", 0.0)) * 4.0 * t * (1.0 - t)
	var t2 := clampf((x - tx1) / (float(p["e1"]) - tx1), 0.0, 1.0)
	return lerpf(top, float(p["end1"]), t2) - float(p.get("sag1", 0.0)) * 4.0 * t2 * (1.0 - t2)

## Main cables over the towers with hangers to the deck. Keys of `p`:
## tx0/tx1 tower x, e0/e1 cable end x, top, low, end0/end1, sag0/sag1
## (see cable_y), z cable half-spacing, deck_y, w cable width, step hanger
## spacing, hw hanger width, dz (z of the deck edge the hangers reach, else
## z), vee (inclined V hangers), side (hang the side spans too; or
## side0 / side1 for one side span only), round (wire cables as round
## tubes of diameter w, with a clamped cable band at every hanger),
## pair (two hanger ropes per band, this far apart along the cable),
## stack (a second cable this far above the first, as on Lisbon's).
static func suspension(lm: LandmarkMesh, key: String, p: Dictionary) -> void:
	var tx0: float = p["tx0"]
	var tx1: float = p["tx1"]
	var e0: float = p["e0"]
	var e1: float = p["e1"]
	var deck_y: float = p["deck_y"]
	var step: float = p["step"]
	var w: float = p["w"]
	var hw: float = p.get("hw", 0.3)
	var round_c: bool = p.get("round", false)
	var pair: float = p.get("pair", 0.0)
	var stack: float = p.get("stack", 0.0)
	var side0: bool = p.get("side0", p.get("side", false))
	var side1: bool = p.get("side1", p.get("side", false))
	for zs in [-1.0, 1.0]:
		var z: float = zs * float(p["z"])
		var dz: float = zs * float(p.get("dz", p["z"]))
		var pts := PackedVector3Array()
		for span in [[e0, tx0, 18], [tx0, tx1, 56], [tx1, e1, 18]]:
			var a: float = span[0]
			var b: float = span[1]
			var n: int = span[2]
			for k in n:
				var cx := lerpf(a, b, float(k) / n)
				pts.append(Vector3(cx, cable_y(p, cx), z))
		pts.append(Vector3(e1, cable_y(p, e1), z))
		var lifts: Array[float] = [0.0]
		if stack > 0.0:
			lifts.append(stack)
		for lift in lifts:
			var lp := PackedVector3Array()
			for q in pts:
				lp.append(q + Vector3(0, lift, 0))
			if round_c:
				LandmarkCoreBBridgeKit.tube(lm, key, lp, w * 0.5, 10)
			else:
				cable_poly(lm, key, lp, w)
		var x0: float = e0 if side0 else tx0
		var x1: float = e1 if side1 else tx1
		var x := x0 + step
		while x < x1 - step * 0.5:
			var cy := cable_y(p, x)
			if cy - deck_y > 2.0 and absf(x - tx0) > 6.0 and absf(x - tx1) > 6.0:
				if round_c:
					# Cable band: a split cast clamp round the cable.
					var bl := maxf(w * 1.2, 0.8)
					LandmarkCoreBBridgeKit.tube(lm, key, PackedVector3Array([
						Vector3(x - bl, cable_y(p, x - bl), z), Vector3(x + bl, cable_y(p, x + bl), z)]),
						w * 0.62, 8)
				if p.get("vee", false):
					lm.beam(key, Vector3(x, cy, z), Vector3(x - step * 0.5, deck_y, dz), hw, hw)
					lm.beam(key, Vector3(x, cy, z), Vector3(x + step * 0.5, deck_y, dz), hw, hw)
				elif pair > 0.0:
					for o in [-pair * 0.5, pair * 0.5]:
						lm.beam(key, Vector3(x + o, deck_y, dz), Vector3(x + o, cy, z), hw, hw)
				else:
					lm.beam(key, Vector3(x, deck_y, dz), Vector3(x, cy, z), hw, hw)
			x += step

## Warren truss side (chords and diagonals, a post every cell) in the
## plane z, from x0 to x1 between y0 and y1.
static func truss_side(lm: LandmarkMesh, key: String, x0: float, x1: float, y0: float, y1: float,
		z: float, cell: float, w: float) -> void:
	lm.beam(key, Vector3(x0, y1, z), Vector3(x1, y1, z), w * 1.4, w * 1.4)
	lm.beam(key, Vector3(x0, y0, z), Vector3(x1, y0, z), w * 1.4, w * 1.4)
	var n := maxi(int(round((x1 - x0) / cell)), 1)
	for k in n:
		var xa := lerpf(x0, x1, float(k) / n)
		var xb := lerpf(x0, x1, float(k + 1) / n)
		if k % 2 == 0:
			lm.beam(key, Vector3(xa, y0, z), Vector3(xb, y1, z), w, w)
		else:
			lm.beam(key, Vector3(xa, y1, z), Vector3(xb, y0, z), w, w)
		lm.beam(key, Vector3(xa, y0, z), Vector3(xa, y1, z), w * 0.7, w * 0.7)

## Level deck from x0 to x1, road top at y: asphalt slab over a lower
## plate and either a closed box girder (cell = 0) or two truss sides
## of the given cell length, `depth` deep overall.
static func deck_girder(lm: LandmarkMesh, x0: float, x1: float, y: float, half_w: float,
		depth: float, cell: float = 0.0) -> void:
	var mid := (x0 + x1) * 0.5
	var length := x1 - x0
	lm.box("Deck", Vector3(mid, y - 0.25, 0), Vector3(length, 0.5, half_w * 2.0))
	if cell > 0.0:
		var tz := half_w - 0.6
		for z in [-tz, tz]:
			truss_side(lm, "Steel", x0, x1, y - depth, y - 0.5, z, cell, 0.9)
		# Lower lateral bracing (an X in plan every cell), a cross frame
		# at every panel point and the road's crash barriers and railings.
		var n := maxi(int(round(length / cell)), 1)
		var yb := y - depth + 0.4
		for k in n:
			var xa := lerpf(x0, x1, float(k) / n)
			var xb := lerpf(x0, x1, float(k + 1) / n)
			lm.beam("Steel", Vector3(xa, yb, -tz), Vector3(xb, yb, tz), 0.5, 0.5)
			lm.beam("Steel", Vector3(xa, yb, tz), Vector3(xb, yb, -tz), 0.5, 0.5)
			lm.beam("Steel", Vector3(xa, yb, -tz), Vector3(xa, yb, tz), 0.7, 0.9)
			lm.beam("Steel", Vector3(xa, yb, -tz * 0.5), Vector3(xa, y - 0.6, -tz * 0.05), 0.4, 0.4)
			lm.beam("Steel", Vector3(xa, yb, tz * 0.5), Vector3(xa, y - 0.6, tz * 0.05), 0.4, 0.4)
		for z in [-half_w + 0.2, half_w - 0.2, -0.3, 0.3]:
			lm.box("Concrete", Vector3(mid, y + 0.45, z), Vector3(length, 0.9, 0.35), Basis(), 0.0)
		for z in [-half_w - 0.3, half_w + 0.3]:
			railing(lm, "Steel", Vector3(x0, y, z), Vector3(x1, y, z), 1.2, 4.0)
	else:
		lm.box("Steel", Vector3(mid, y - 0.5 - (depth - 0.5) * 0.5, 0),
			Vector3(length, depth - 0.5, half_w * 2.0 - 3.0))

## Sloping deck leg from (xa, ya) to (xb, yb) on concrete piers every
## `step` metres from y = -2 (an approach viaduct); half_w deck width.
static func viaduct(lm: LandmarkMesh, xa: float, ya: float, xb: float, yb: float, half_w: float,
		depth: float, step: float) -> void:
	var n := maxi(int(round(absf(xb - xa) / step)), 1)
	for k in n:
		var x0 := lerpf(xa, xb, float(k) / n)
		var x1 := lerpf(xa, xb, float(k + 1) / n)
		var y0 := lerpf(ya, yb, float(k) / n)
		var y1 := lerpf(ya, yb, float(k + 1) / n)
		var r := Basis(Vector3.BACK, atan2(y1 - y0, x1 - x0))
		var c := Vector3((x0 + x1) * 0.5, (y0 + y1) * 0.5, 0)
		var l := Vector2(x1 - x0, y1 - y0).length()
		lm.box("Deck", c + Vector3(0, -0.25, 0), Vector3(l + 0.2, 0.5, half_w * 2.0), r)
		lm.box("Concrete", c + Vector3(0, -depth * 0.5, 0), Vector3(l + 0.2, depth - 0.5, half_w * 2.0 - 2.0), r)
		var py: float = y1 - depth
		for z in [-half_w * 0.45, half_w * 0.45]:
			lm.box("Concrete", Vector3(x1, py * 0.5, z), Vector3(3.0, py, 3.0))

## Two-legged tower from y0 to `top`: legs at ±leg_z tapering from
## half-widths leg0 to leg1 (x, z), cross beams at the heights in
## `beams` (beam_h tall) and X bracing between them when braced.
static func portal_tower(lm: LandmarkMesh, key: String, x: float, y0: float, top: float,
		leg_z: float, leg0: Vector2, leg1: Vector2, beams: Array, beam_h: float,
		braced: bool = false, brace_w: float = 1.5) -> void:
	for s in [-1.0, 1.0]:
		tapered_box(lm, key, Vector3(x, y0, s * leg_z), leg0.x, leg0.y, leg1.x, leg1.y, top - y0)
	var prev := -1.0
	for b in beams:
		var by: float = b
		var f := (by - y0) / (top - y0)
		var inner := leg_z - lerpf(leg0.y, leg1.y, f)
		lm.box(key, Vector3(x, by, 0), Vector3(lerpf(leg0.x, leg1.x, f) * 2.0, beam_h, inner * 2.0))
		if braced and prev >= 0.0:
			lm.beam(key, Vector3(x, prev + beam_h * 0.5, -inner), Vector3(x, by - beam_h * 0.5, inner), brace_w, brace_w)
			lm.beam(key, Vector3(x, prev + beam_h * 0.5, inner), Vector3(x, by - beam_h * 0.5, -inner), brace_w, brace_w)
		prev = by

## Fan of n stays from a tower at tx to the deck on one side (dir = ±1):
## the lowest tower attachment y0 lands d0 from the tower, each higher
## one dd farther, up to y1.
static func stays(lm: LandmarkMesh, key: String, tx: float, dir: float, y0: float, y1: float,
		n: int, d0: float, dd: float, deck_y: float, z_top: float, z_deck: float, w: float) -> void:
	for i in n:
		var f := float(i) / maxf(n - 1, 1)
		lm.beam(key, Vector3(tx, lerpf(y0, y1, f), z_top),
			Vector3(tx + dir * (d0 + dd * i), deck_y, z_deck), w, w)

## Coarse stone figure of height h on a square plinth (the Charles
## Bridge saints); feet at `base`.
static func figure(lm: LandmarkMesh, key: String, base: Vector3, h: float) -> void:
	var prof := PackedVector2Array([Vector2(h * 0.2, 0), Vector2(h * 0.17, h * 0.45),
		Vector2(h * 0.2, h * 0.7), Vector2(h * 0.09, h * 0.78), Vector2(h * 0.08, h * 0.9),
		Vector2(0.0, h)])
	lm.lathe(key, base, prof, 8)

## Railing along a-b: posts every `step` metres, h tall, with a
## handrail and a middle rail.
static func railing(lm: LandmarkMesh, key: String, a: Vector3, b: Vector3, h: float, step: float) -> void:
	var n := maxi(int(round(a.distance_to(b) / step)), 1)
	for i in n + 1:
		var p := a.lerp(b, float(i) / n)
		lm.beam(key, p, p + Vector3(0, h, 0), 0.12, 0.12)
	lm.beam(key, a + Vector3(0, h, 0), b + Vector3(0, h, 0), 0.14, 0.1)
	lm.beam(key, a + Vector3(0, h * 0.5, 0), b + Vector3(0, h * 0.5, 0), 0.08, 0.08)

## Prism along X from x0 to x1 over a cross-section polygon (z, y): the
## way a box-girder deck or a pylon of constant section is one solid.
static func extrude_yz(lm: LandmarkMesh, key: String, poly: PackedVector2Array, x0: float, x1: float) -> void:
	var area := 0.0
	for i in poly.size():
		var p := poly[i]
		var q := poly[(i + 1) % poly.size()]
		area += p.x * q.y - q.x * p.y
	var sgn := 1.0 if area > 0.0 else -1.0
	var u := 0.0
	for i in poly.size():
		var p := poly[i]
		var q := poly[(i + 1) % poly.size()]
		var e := q - p
		if e.length() < 0.001:
			continue
		var n := Vector3(0, -e.x, e.y).normalized() * sgn
		lm.quad(key, Vector3(x0, p.y, p.x), Vector3(x0, q.y, q.x), Vector3(x1, q.y, q.x),
			Vector3(x1, p.y, p.x), n, Vector2(u, 0))
		u += e.length()
	var idx := Geometry2D.triangulate_polygon(poly)
	for t in range(0, idx.size(), 3):
		var a := poly[idx[t]]
		var b := poly[idx[t + 1]]
		var c := poly[idx[t + 2]]
		for x in [x0, x1]:
			var n := Vector3(1.0 if x == x1 else -1.0, 0, 0)
			lm.tri(key, Vector3(x, a.y, a.x), Vector3(x, b.y, b.x), Vector3(x, c.y, c.x), n, n, n,
				Vector2(a.x, -a.y), Vector2(b.x, -b.y), Vector2(c.x, -c.y))

## Cast-steel cable saddle on a tower top at `c` (its base), for a cable
## of diameter w running along X: a stepped bed and the curved cover the
## cable bends over.
static func saddle(lm: LandmarkMesh, key: String, c: Vector3, w: float) -> void:
	var l := w * 7.0
	lm.box(key, c + Vector3(0, w * 0.4, 0), Vector3(l, w * 0.8, w * 3.4))
	var prof := PackedVector2Array()
	for k in 9:
		var a := PI * float(k) / 8.0
		prof.append(Vector2(-cos(a) * l * 0.45, w * 0.8 + sin(a) * w * 1.6))
	var poly := PackedVector2Array([Vector2(-l * 0.5, w * 0.8)])
	poly.append_array(prof)
	poly.append(Vector2(l * 0.5, w * 0.8))
	for i in poly.size():
		poly[i] += Vector2(c.x, c.y)
	extrude_xy(lm, key, poly, c.z - w * 1.3, c.z + w * 1.3)

## Cable anchorage at the end x of a suspension bridge, the cables
## leaving towards -dir (the span): a massive concrete block `length`
## long and 2 half_w wide with its front face sloping up to `top` along
## the cables, a splay chamber house on the slope and a stepped plinth.
static func anchorage(lm: LandmarkMesh, key: String, x: float, dir: float, top: float, half_w: float,
		length: float) -> void:
	var poly := PackedVector2Array([Vector2(x, 0), Vector2(x + dir * length, 0),
		Vector2(x + dir * length, top * 0.8), Vector2(x + dir * length * 0.55, top),
		Vector2(x + dir * length * 0.15, top), Vector2(x, top * 0.55)])
	extrude_xy(lm, key, poly, -half_w, half_w)
	lm.box(key, Vector3(x + dir * length * 0.5, 1.5, 0), Vector3(length + 4.0, 3.0, half_w * 2.0 + 4.0))
	# Splay chamber roofs over the two cable entries and the top cornice.
	for s in [-1.0, 1.0]:
		lm.box(key, Vector3(x + dir * length * 0.3, top * 0.85, s * half_w * 0.6),
			Vector3(length * 0.3, top * 0.25, half_w * 0.6))
	lm.box(key, Vector3(x + dir * length * 0.35, top + 0.6, 0), Vector3(length * 0.42, 1.2, half_w * 2.0 + 1.0))

## Couchant stone lion of body length l at `base` (feet), facing `dir`
## (±X or ±Z): plinth-free body, haunch, forepaws, maned head, tail.
static func lion(lm: LandmarkMesh, key: String, base: Vector3, dir: Vector3, l: float) -> void:
	var f := dir.normalized()
	var s := Vector3.UP.cross(f).normalized()
	var bs := Basis(s, Vector3.UP, f)
	# Body: a lathed barrel lying along f.
	var body_c := base + Vector3(0, l * 0.2, 0)
	lm.beam(key, body_c - f * l * 0.32, body_c + f * l * 0.18, l * 0.34, l * 0.3, s)
	lm.box(key, body_c - f * l * 0.3 - Vector3(0, l * 0.04, 0), Vector3(l * 0.4, l * 0.3, l * 0.28), bs)
	# Forepaws stretched forward.
	for k in [-1.0, 1.0]:
		lm.box(key, base + f * l * 0.3 + s * k * l * 0.1 + Vector3(0, l * 0.05, 0),
			Vector3(l * 0.1, l * 0.1, l * 0.32), bs)
	# Mane and head, raised.
	var head := base + f * l * 0.3 + Vector3(0, l * 0.42, 0)
	lm.lathe(key, head - f * l * 0.05 - Vector3(0, l * 0.2, 0), PackedVector2Array([Vector2(l * 0.15, 0),
		Vector2(l * 0.2, l * 0.12), Vector2(l * 0.19, l * 0.24), Vector2(l * 0.12, l * 0.32),
		Vector2(0.0, l * 0.34)]), 10)
	lm.beam(key, head + f * l * 0.04, head + f * l * 0.17, l * 0.13, l * 0.12, s)
	# Tail curled along the flank.
	lm.beam(key, body_c - f * l * 0.45 - Vector3(0, l * 0.12, 0), body_c - f * l * 0.1 + s * l * 0.17 - Vector3(0, l * 0.18, 0),
		l * 0.04, l * 0.04)

## Lattice member a-b (a riveted tie or boom): two flat chords `w` apart
## across `side` joined by zig-zag lacing bars.
static func lattice_member(lm: LandmarkMesh, key: String, a: Vector3, b: Vector3, w: float,
		side: Vector3) -> void:
	var ax := (b - a).normalized()
	var o := (side - ax * side.dot(ax)).normalized() * w * 0.5
	var bar := maxf(w * 0.16, 0.15)
	lm.beam(key, a + o, b + o, bar * 1.6, w * 0.45, ax.cross(o))
	lm.beam(key, a - o, b - o, bar * 1.6, w * 0.45, ax.cross(o))
	var n := maxi(int(a.distance_to(b) / (w * 1.1)), 1)
	for k in n:
		var p := a.lerp(b, float(k) / n)
		var q := a.lerp(b, float(k + 1) / n)
		var sg := 1.0 if k % 2 == 0 else -1.0
		lm.beam(key, p + o * sg, q - o * sg, bar, bar * 0.6)
