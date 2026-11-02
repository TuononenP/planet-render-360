class_name LandmarkIbUtil
extends RefCounted

## Helpers shared by the Iberia landmark builders (true metres on
## LandmarkMesh): flat window panes, pilaster rows, balustrades,
## horseshoe and wedge-striped round arches, a hipped spire and a
## grid of simple tree crowns. Every helper takes the material KEYS to
## draw with; the caller registers them with lm.use.

## Row of `n` flat rectangular window panes along a wall face: `o` is
## the face centre at ground level, `right` the wall direction, `out`
## the face normal; panes are w x h on pitch `pitch`, sill at y.
static func panes(lm: LandmarkMesh, key: String, o: Vector3, right: Vector3, out: Vector3,
		y: float, n: int, pitch: float, w: float, h: float) -> void:
	var nrm := right.cross(Vector3.UP).normalized()
	var r := right if nrm.dot(out) > 0.0 else -right
	for i in n:
		var s := (float(i) - float(n - 1) * 0.5) * pitch
		var c := o + right * s + out * 0.07 + Vector3(0, y, 0)
		var up := Vector3(0, h, 0)
		lm.quad(key, c - r * (w * 0.5), c + r * (w * 0.5), c + r * (w * 0.5) + up,
			c - r * (w * 0.5) + up, out)

## Row of `n` pilasters (w wide, d deep) along a wall face from y0 to
## y1; those closer than `gap` to the face centre are left out (a
## projecting centre piece stands there).
static func pilasters(lm: LandmarkMesh, key: String, o: Vector3, right: Vector3, out: Vector3,
		n: int, pitch: float, w: float, d: float, y0: float, y1: float, gap: float = 0.0) -> void:
	var basis := Basis(right, Vector3.UP, right.cross(Vector3.UP).normalized())
	for i in n:
		var s := (float(i) - float(n - 1) * 0.5) * pitch
		if absf(s) < gap:
			continue
		lm.box(key, o + right * s + out * (d * 0.5) + Vector3(0, (y0 + y1) * 0.5, 0),
			Vector3(w, y1 - y0, d), basis)

## Balustrade from a to b (both at its base), h tall, facing `out`:
## plinth, rail, a core carrying a row of dark baluster slits on the
## outer face and a taller pedestal every `pedestal` metres.
static func balustrade(lm: LandmarkMesh, stone: String, dark: String, a: Vector3, b: Vector3,
		out: Vector3, h: float = 1.6, pedestal: float = 7.0) -> void:
	var d := b - a
	var length := d.length()
	var dir := d / length
	var basis := Basis(dir, Vector3.UP, dir.cross(Vector3.UP).normalized())
	var mid := (a + b) * 0.5
	lm.box(stone, mid + Vector3(0, 0.25, 0), Vector3(length, 0.5, 0.8), basis)
	lm.box(stone, mid + Vector3(0, h * 0.5, 0), Vector3(length, h - 0.6, 0.5), basis)
	lm.box(stone, mid + Vector3(0, h - 0.2, 0), Vector3(length, 0.4, 0.9), basis)
	var n := maxi(int(length / 1.4), 1)
	for i in n:
		var p := a + d * ((float(i) + 0.5) / float(n)) + out * 0.27
		lm.quad(dark, p - dir * 0.2 + Vector3(0, 0.6, 0), p + dir * 0.2 + Vector3(0, 0.6, 0),
			p + dir * 0.2 + Vector3(0, h - 0.5, 0), p - dir * 0.2 + Vector3(0, h - 0.5, 0), out)
	var m := maxi(int(length / pedestal), 1)
	for i in m + 1:
		lm.box(stone, a.lerp(b, float(i) / float(m)) + Vector3(0, (h + 0.5) * 0.5, 0),
			Vector3(1.0, h + 0.5, 1.0), basis)

## Flat horseshoe-arch recess w wide and h tall standing on `o` (bottom
## centre), facing right x up: a rectangle topped by an arc that
## swells past the half-circle and narrows to a throat at the spring.
static func horseshoe(lm: LandmarkMesh, key: String, o: Vector3, right: Vector3, up: Vector3,
		w: float, h: float) -> void:
	var r := w * 0.5 / 0.94
	var cy := h - r
	var n := right.cross(up).normalized()
	var pts: Array[Vector3] = []
	var steps := 8
	for k in steps + 1:
		var a := deg_to_rad(-20.0 + 220.0 * float(k) / float(steps))
		pts.append(o + right * (r * cos(a)) + up * (cy + r * sin(a)))
	# Rectangle up to the spring, a fan over the arc and the triangle
	# between the arc ends and the arc centre.
	var spring := o + up * (cy + r * sin(deg_to_rad(-20.0)))
	lm.quad(key, o - right * (w * 0.5), o + right * (w * 0.5), spring + right * (w * 0.5),
		spring - right * (w * 0.5), n)
	var c := o + up * cy
	for k in pts.size() - 1:
		lm.tri(key, c, pts[k], pts[k + 1], n, n, n, Vector2(0, 0), Vector2(1, 0), Vector2(1, 1))
	lm.tri(key, c, pts[0], pts[steps], n, n, n, Vector2(0, 0), Vector2(1, 0), Vector2(1, 1))

## Wedge-striped arch ring around the centre `c` (an arc from th0 to th1
## degrees in the plane of `u_dir` x up), inner radius r_in, `thick`
## deep radially and `depth` across (along `w_dir`); wedges alternate
## between the keys `a` and `b` (the red-and-white voussoirs).
static func wedge_arch(lm: LandmarkMesh, a: String, b: String, c: Vector3, u_dir: Vector3,
		w_dir: Vector3, r_in: float, thick: float, depth: float, th0: float, th1: float,
		n: int, extrados: bool = false) -> void:
	var hw := w_dir * (depth * 0.5)
	var r_out := r_in + thick
	for k in n:
		var key := a if k % 2 == 0 else b
		var t0 := deg_to_rad(lerpf(th0, th1, float(k) / float(n)))
		var t1 := deg_to_rad(lerpf(th0, th1, float(k + 1) / float(n)))
		var d0 := u_dir * cos(t0) + Vector3(0, sin(t0), 0)
		var d1 := u_dir * cos(t1) + Vector3(0, sin(t1), 0)
		var mid := (d0 + d1).normalized()
		lm.quad(key, c + d0 * r_in + hw, c + d1 * r_in + hw, c + d1 * r_out + hw,
			c + d0 * r_out + hw, w_dir)
		lm.quad(key, c + d1 * r_in - hw, c + d0 * r_in - hw, c + d0 * r_out - hw,
			c + d1 * r_out - hw, -w_dir)
		lm.quad(key, c + d0 * r_in - hw, c + d1 * r_in - hw, c + d1 * r_in + hw,
			c + d0 * r_in + hw, -mid)
		if extrados:
			lm.quad(key, c + d0 * r_out - hw, c + d1 * r_out - hw, c + d1 * r_out + hw,
				c + d0 * r_out + hw, mid)

## Grid of `nx` x `nz` low round tree crowns (orange trees, hedge
## clumps) centred on `c`, `r` wide and h high on pitch (px, pz).
static func tree_grid(lm: LandmarkMesh, key: String, c: Vector3, nx: int, nz: int, px: float,
		pz: float, r: float, h: float) -> void:
	for i in nx:
		for j in nz:
			var p := c + Vector3((float(i) - float(nx - 1) * 0.5) * px, 0,
				(float(j) - float(nz - 1) * 0.5) * pz)
			lm.lathe(key, p, PackedVector2Array([Vector2(0.15, 0), Vector2(0.15, h * 0.35),
				Vector2(r, h * 0.45), Vector2(r * 0.8, h * 0.85), Vector2(0.0, h)]), 6)

## Rectangle of four walls round a courtyard: outer half sizes (hx, hz)
## centred on c, wall thickness t, height h from y0; `key` draws them.
static func ring_walls(lm: LandmarkMesh, key: String, c: Vector3, hx: float, hz: float,
		t: float, y0: float, h: float) -> void:
	var cy := y0 + h * 0.5
	lm.box(key, c + Vector3(0, cy, hz - t * 0.5), Vector3(hx * 2.0, h, t))
	lm.box(key, c + Vector3(0, cy, -hz + t * 0.5), Vector3(hx * 2.0, h, t))
	lm.box(key, c + Vector3(hx - t * 0.5, cy, 0), Vector3(t, h, hz * 2.0 - t * 2.0))
	lm.box(key, c + Vector3(-hx + t * 0.5, cy, 0), Vector3(t, h, hz * 2.0 - t * 2.0))

## Eight-sided lantern cap on a stage: shaft r, h tall, then a cone.
static func lantern(lm: LandmarkMesh, wall: String, cap: String, base: Vector3, r: float,
		h: float, cone_h: float) -> void:
	lm.frustum(wall, base, r, r * 0.92, h, 8)
	lm.frustum(cap, base + Vector3(0, h, 0), r * 1.15, 0.0, cone_h, 8)
