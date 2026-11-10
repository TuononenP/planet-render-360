class_name ShipHullKit
extends RefCounted

## Hull-side details of large steel ships (metres, +X bow, y = 0 at the
## waterline, `spec` as HullLoft): flush rows of hull windows, mooring
## chocks, anchor pockets with stowed anchors, shell-door outlines, a
## bulbous bow and a livery sweep. Everything sits a few centimetres
## proud of the HullLoft surface on both sides.

## Flush rectangular windows `w` x `h` every `pitch` m from x0 to x1 at
## centre height `y`. Each window samples its own stretch of a lit-cabin
## tile (uv0), so neighbours differ at night.
static func windows(lm: LandmarkMesh, spec: Dictionary, key: String, x0: float, x1: float,
		y: float, w: float, h: float, pitch: float) -> void:
	var n := maxi(int((x1 - x0) / pitch), 1)
	for i in n + 1:
		var x := lerpf(x0, x1, float(i) / float(n))
		for s in [-1.0, 1.0]:
			# Inside one cabin cell of the lit tile (ShipLights.CABIN_M), clear of its divider.
			var cell := floorf(x * 1.7 / ShipLights.CABIN_M) * ShipLights.CABIN_M
			_flush(lm, key, x, y, w, h, float(s), spec, Vector2(cell + (ShipLights.CABIN_M - w) * 0.5, y))

static func _flush(lm: LandmarkMesh, key: String, x: float, y: float, w: float, h: float,
		s: float, spec: Dictionary, uv0: Vector2 = Vector2.ZERO) -> void:
	var za := (HullLoft.side_z(spec, x - w * 0.5, y) + 0.05) * s
	var zb := (HullLoft.side_z(spec, x + w * 0.5, y) + 0.05) * s
	lm.quad(key, Vector3(x - w * 0.5, y - h * 0.5, za), Vector3(x + w * 0.5, y - h * 0.5, zb),
		Vector3(x + w * 0.5, y + h * 0.5, zb), Vector3(x - w * 0.5, y + h * 0.5, za), Vector3(0, 0, s), uv0)

## Oval Panama chocks just under the sheer at each x in `xs`.
static func chocks(lm: LandmarkMesh, spec: Dictionary, xs: Array, size: float) -> void:
	for x in xs:
		var y := HullLoft.sheer(spec, float(x)) - size * 0.9
		for s in [-1.0, 1.0]:
			_flush(lm, "Black", float(x), y, size * 1.6, size, float(s), spec)

## Hawse recess with a stowed stockless anchor, `size` m tall, at `x`.
static func anchor_pocket(lm: LandmarkMesh, spec: Dictionary, x: float, size: float) -> void:
	var y := HullLoft.sheer(spec, x) - size * 1.5
	for s in [-1.0, 1.0]:
		var z := (HullLoft.side_z(spec, x, y) + 0.04) * float(s)
		lm.disc("Black", Vector3(x, y + size * 0.15, z), Vector3(0, 0, s), size * 0.62, 16)
		var points := PackedVector2Array()
		for p in [Vector2(-0.07, 0.75), Vector2(0.07, 0.75), Vector2(0.07, 0.05), Vector2(0.42, 0.24),
				Vector2(0.3, -0.18), Vector2(-0.3, -0.18), Vector2(-0.42, 0.24), Vector2(-0.07, 0.05)]:
			points.append(Vector2(x, y) + (p as Vector2) * size)
		HullLoft.fin(lm, "Dark", points, size * 0.05, z + float(s) * size * 0.06)

## Shell door outline (`w` x `h`, centred at x, y): thin dark seams.
static func shell_door(lm: LandmarkMesh, spec: Dictionary, x: float, y: float, w: float, h: float) -> void:
	for s in [-1.0, 1.0]:
		var path: Array = []
		for c in [Vector2(-0.5, -0.5), Vector2(0.5, -0.5), Vector2(0.5, 0.5), Vector2(-0.5, 0.5), Vector2(-0.5, -0.5)]:
			var px := x + (c as Vector2).x * w
			var py := y + (c as Vector2).y * h
			path.append(Vector3(px, py, (HullLoft.side_z(spec, px, py) + 0.03) * float(s)))
		HullLoft.tube(lm, "Dark", path, 0.035, 4)

## Bulbous bow: an ellipsoid of revolution about x under the stem foot.
## `reach` is how far it stands ahead of the waterline stem.
static func bulb(lm: LandmarkMesh, spec: Dictionary, key: String, reach: float) -> void:
	var draft := float(spec["draft"])
	var tip := HullLoft.x0(spec) + HullLoft.body_length(spec)
	var centre := Vector3(tip - reach * 0.6, -draft * 0.6, 0)
	var ax := reach * 1.6
	var ry := draft * 0.3
	var rz := minf(float(spec["beam"]) * 0.09, ry * 0.9)
	var rows: Array = []
	for i in 9:
		var a := PI * 0.5 * float(i) / 8.0  # 0 at the hull, PI/2 at the tip
		var row := PackedVector3Array()
		var r := cos(a)
		for k in 13:
			var t := TAU * float(k) / 12.0
			row.append(centre + Vector3(sin(a) * ax, sin(t) * ry * maxf(r, 0.001), cos(t) * rz * maxf(r, 0.001)))
		rows.append(row)
	lm.grid(key, rows, centre, true)

## A livery band `width` m tall on both hull sides from x0 to x1, its
## centre at y0 (aft) rising to y1 (forward) along a smooth sweep.
static func livery(lm: LandmarkMesh, spec: Dictionary, key: String, x0: float, x1: float,
		y0: float, y1: float, width: float) -> void:
	var n := clampi(int((x1 - x0) / 2.0), 24, 160)
	for s in [-1.0, 1.0]:
		var lo := PackedVector3Array()
		var hi := PackedVector3Array()
		for i in n + 1:
			var t := float(i) / float(n)
			var x := lerpf(x0, x1, t)
			var y := lerpf(y0, y1, t * t * (3.0 - 2.0 * t))
			var w := width * (0.35 + 0.65 * t)
			var ya := y - w * 0.5
			var yb := y + w * 0.5
			lo.append(Vector3(x, ya, (HullLoft.side_z(spec, x, ya) + 0.1) * float(s)))
			hi.append(Vector3(x, yb, (HullLoft.side_z(spec, x, yb) + 0.1) * float(s)))
		lm.grid(key, [lo, hi], Vector3(0, 0, s))
