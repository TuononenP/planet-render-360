class_name LandmarkFhUtil
extends RefCounted

## Helpers shared by the finland_helsinki landmark builders (true metres
## on LandmarkMesh, +X east, +Z south): base-anchored blocks, gabled and
## hipped roofs, rows of windows and columns, arched openings, onion
## domes, crosses and steps. Footprints are traced from OpenStreetMap
## outlines in the model frame the registry yaw_deg turns onto the map.

## Box standing on y0 (not centred), turned by `yaw` about +Y.
static func blk(lm: LandmarkMesh, key: String, cx: float, y0: float, cz: float, w: float,
		h: float, d: float, yaw: float = 0.0) -> void:
	lm.box(key, Vector3(cx, y0 + h * 0.5, cz), Vector3(w, h, d), Basis(Vector3.UP, yaw))

## Gabled roof, ridge along X (long side `lx`, depth `dz`), eaves at c.
static func ridge_x(lm: LandmarkMesh, key: String, gable_key: String, c: Vector3, lx: float,
		dz: float, rise: float, over: float = 0.4) -> void:
	lm.gable(key, c, dz, lx, rise, Basis(Vector3.UP, PI * 0.5), over, gable_key)

## Gabled roof, ridge along Z (width `wx`, long side `lz`), eaves at c.
static func ridge_z(lm: LandmarkMesh, key: String, gable_key: String, c: Vector3, wx: float,
		lz: float, rise: float, over: float = 0.4) -> void:
	lm.gable(key, c, wx, lz, rise, Basis(), over, gable_key)

## Hip roof over a w (X) x l (Z) rectangle at `base` (eave level); `top`
## is the ridge/top size as a fraction of the eave size (0 = pyramid).
static func hip(lm: LandmarkMesh, key: String, base: Vector3, w: float, l: float, h: float,
		top: float = 0.0) -> void:
	lm.lathe(key, base, PackedVector2Array([Vector2(1.4142, 0), Vector2(1.4142 * top, h)]),
		4, w * 0.5, l * 0.5, PI * 0.25, false)

## Quarter-ellipse dome profile (radius, y), flat-topped at the apex.
static func dome_prof(r: float, h: float, steps: int = 10) -> PackedVector2Array:
	var p := PackedVector2Array()
	for i in steps + 1:
		var a := PI * 0.5 * float(i) / float(steps)
		p.append(Vector2(r * cos(a), h * sin(a)))
	p[steps] = Vector2(0.0, h)
	return p

## Onion dome: bulge 1.0 r at ~28% of its height, drawn in to a point.
static func onion(lm: LandmarkMesh, key: String, base: Vector3, r: float, h: float,
		seg: int = 12) -> void:
	var p := PackedVector2Array([Vector2(r * 0.55, 0), Vector2(r * 0.92, h * 0.1),
		Vector2(r, h * 0.28), Vector2(r * 0.92, h * 0.46), Vector2(r * 0.6, h * 0.64),
		Vector2(r * 0.3, h * 0.8), Vector2(r * 0.1, h * 0.94), Vector2(0, h)])
	lm.lathe(key, base, p, seg)

## Orthodox cross (three bars) standing on `base`, h tall.
static func cross(lm: LandmarkMesh, key: String, base: Vector3, h: float) -> void:
	lm.box(key, base + Vector3(0, h * 0.5, 0), Vector3(h * 0.05, h, h * 0.05))
	lm.box(key, base + Vector3(0, h * 0.74, 0), Vector3(h * 0.4, h * 0.05, h * 0.05))
	lm.box(key, base + Vector3(0, h * 0.88, 0), Vector3(h * 0.26, h * 0.05, h * 0.05))

## Flat recess w wide and h tall, round-headed when `round_top`, standing
## on `o` (bottom centre) facing `out` (horizontal unit vector).
static func opening(lm: LandmarkMesh, key: String, o: Vector3, out: Vector3, w: float,
		h: float, round_top: bool = true) -> void:
	var right := Vector3.UP.cross(out).normalized()
	var hw := w * 0.5
	var rise := hw if round_top else 0.0
	var m := o + Vector3.UP * (h - rise)
	lm.quad(key, o - right * hw, o + right * hw, m + right * hw, m - right * hw, out)
	if round_top:
		var prev := m + right * hw
		for k in range(1, 7):
			var a := PI * float(k) / 6.0
			var p := m + right * (hw * cos(a)) + Vector3.UP * (hw * sin(a))
			lm.tri(key, m, prev, p, out, out, out, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO)
			prev = p

## `n` openings along a wall run p0..p1 (ground points) facing `out`,
## starting y metres up.
static func openings(lm: LandmarkMesh, key: String, p0: Vector3, p1: Vector3, out: Vector3,
		y: float, n: int, w: float, h: float, round_top: bool = true, off: float = 0.08) -> void:
	for i in n:
		var t := (float(i) + 0.5) / float(n)
		opening(lm, key, p0.lerp(p1, t) + Vector3(0, y, 0) + out * off, out, w, h, round_top)

## `rows` x `n` rectangular windows on a wall run p0..p1 facing `out`:
## rows start y0 up and repeat every `pitch` metres.
static func window_grid(lm: LandmarkMesh, key: String, p0: Vector3, p1: Vector3, out: Vector3,
		y0: float, rows: int, pitch: float, n: int, w: float, h: float, off: float = 0.08) -> void:
	for r in rows:
		openings(lm, key, p0, p1, out, y0 + pitch * float(r), n, w, h, false, off)

## `n` columns on a straight line a..b (base points), shafts tapering 15%.
static func columns(lm: LandmarkMesh, key: String, a: Vector3, b: Vector3, n: int, h: float,
		r: float, seg: int = 12) -> void:
	for i in n:
		var t := float(i) / float(maxi(n - 1, 1))
		lm.frustum(key, a.lerp(b, t), r, r * 0.85, h, seg)

## Steps rising toward the wall: the top step meets the wall point `c`
## (ground level), the flight runs out along the horizontal unit `dir`.
static func steps(lm: LandmarkMesh, key: String, c: Vector3, dir: Vector3, width: float,
		tread: float, riser: float, n: int) -> void:
	var basis := Basis(Vector3.UP, atan2(dir.x, dir.z))
	for k in n:
		var depth := tread * float(k + 1)
		var hgt := riser * float(n - k)
		lm.box(key, c + dir * depth * 0.5 + Vector3(0, hgt * 0.5, 0), Vector3(width, hgt, depth), basis)

## Evenly spaced merlons/pinnacles along a wall top from p0 to p1.
static func merlons(lm: LandmarkMesh, key: String, p0: Vector3, p1: Vector3, step: float,
		w: float, h: float, thick: float) -> void:
	var count := maxi(int(p0.distance_to(p1) / step), 1)
	var basis := Basis(Vector3.UP, atan2(p1.x - p0.x, p1.z - p0.z))
	for i in count:
		var p := p0.lerp(p1, (float(i) + 0.5) / float(count))
		lm.box(key, p + Vector3(0, h * 0.5, 0), Vector3(thick, h, w), basis)

## Square tower shaft w x d from y0 to y1 with a pyramidal spire of
## height `spire_h` on top (a hip with `top` fraction left flat).
static func tower(lm: LandmarkMesh, wall: String, roof: String, cx: float, cz: float, w: float,
		d: float, y0: float, y1: float, spire_h: float) -> void:
	blk(lm, wall, cx, y0, cz, w, y1 - y0, d)
	hip(lm, roof, Vector3(cx, y1, cz), w * 1.04, d * 1.04, spire_h)

## Mono-pitch wedge over x0..x1, z0..z1 from yb: the z0 wall stands h0 tall,
## the z1 wall h1 tall, the roof slopes between (walls `key`, roof `roof`).
static func wedge(lm: LandmarkMesh, key: String, roof: String, x0: float, x1: float, z0: float,
		z1: float, yb: float, h0: float, h1: float) -> void:
	var a := Vector3(x0, yb, z0)
	var b := Vector3(x1, yb, z0)
	var c := Vector3(x1, yb, z1)
	var d := Vector3(x0, yb, z1)
	lm.quad(key, a, b, b + Vector3(0, h0, 0), a + Vector3(0, h0, 0), Vector3(0, 0, -1))
	lm.quad(key, c, d, d + Vector3(0, h1, 0), c + Vector3(0, h1, 0), Vector3(0, 0, 1))
	lm.quad(key, d, a, a + Vector3(0, h0, 0), d + Vector3(0, h1, 0), Vector3(-1, 0, 0))
	lm.quad(key, b, c, c + Vector3(0, h1, 0), b + Vector3(0, h0, 0), Vector3(1, 0, 0))
	lm.quad(roof, a + Vector3(0, h0, 0), b + Vector3(0, h0, 0), c + Vector3(0, h1, 0),
		d + Vector3(0, h1, 0), Vector3(0, z1 - z0, h0 - h1).normalized())

## Rows of windows along the wall run a..b (XZ points) facing away from the
## interior point `inside`.
static func wall_run(lm: LandmarkMesh, key: String, a: Vector2, b: Vector2, inside: Vector2,
		y0: float, rows: int, pitch: float, n: int, w: float, h: float, off: float = 0.08) -> void:
	var d := b - a
	var o2 := Vector2(d.y, -d.x).normalized()
	if o2.dot((a + b) * 0.5 - inside) < 0.0:
		o2 = -o2
	window_grid(lm, key, Vector3(a.x, 0, a.y), Vector3(b.x, 0, b.y), Vector3(o2.x, 0, o2.y),
		y0, rows, pitch, n, w, h, off)

## Window rows on all four faces of the axis-aligned box centred (cx, cz),
## w (X) by d (Z), from y0: `nx` windows across the Z faces, `nz` across the
## X faces, `rows` rows `pitch` apart, windows `ww` x `wh`.
static func box_windows(lm: LandmarkMesh, key: String, cx: float, cz: float, w: float, d: float,
		y0: float, rows: int, pitch: float, nx: int, nz: int, ww: float, wh: float) -> void:
	var hx := w * 0.5
	var hz := d * 0.5
	var mx := w * 0.12
	var mz := d * 0.12
	for s in [-1.0, 1.0]:
		window_grid(lm, key, Vector3(cx - hx + mx, 0, cz + s * hz), Vector3(cx + hx - mx, 0, cz + s * hz),
			Vector3(0, 0, s), y0, rows, pitch, nx, ww, wh)
		window_grid(lm, key, Vector3(cx + s * hx, 0, cz - hz + mz), Vector3(cx + s * hx, 0, cz + hz - mz),
			Vector3(s, 0, 0), y0, rows, pitch, nz, ww, wh)

## Sphere profile (radius, y) from the bottom pole to the top, r tall/2.
static func ball(r: float) -> PackedVector2Array:
	var pr := PackedVector2Array()
	for k in 9:
		var t := PI * float(k) / 8.0
		pr.append(Vector2(sin(t) * r, r - cos(t) * r))
	return pr
