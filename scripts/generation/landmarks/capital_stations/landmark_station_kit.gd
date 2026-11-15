class_name LandmarkStationKit
extends RefCounted

## Parts shared by the railway station models (the hand-built capital
## termini and the `station` archetype), in true metres on LandmarkMesh:
## the arched train shed with its ribs and glazed lantern, the glazed
## lunette end screen, round-headed openings, ridge-and-furrow platform
## roofs, clock dials, forecourt canopies and the square clock tower with
## its cap. Horizontal unit vectors: `along` runs down a shed, `out` is a
## wall's outward normal.

## Points of a shed arch across `span` (springing `wall_h` up, crown
## `rise` above it) at `c`, from the -side springing to the +side one.
static func arch_points(c: Vector3, side: Vector3, span: float, wall_h: float, rise: float,
		seg: int = 12) -> PackedVector3Array:
	var pts := PackedVector3Array()
	for k in seg + 1:
		var t := PI * float(k) / float(seg)
		pts.append(c - side * cos(t) * span * 0.5 + Vector3.UP * (wall_h + sin(t) * rise))
	return pts

## Arched train shed from ground centre `c0` running `length` along
## `along`: side walls `wall_h` tall, a barrel roof of `rise` whose middle
## `glazed` share is glass, a steel rib every `bay` metres on columns,
## both faces of the roof drawn (it is seen from the platforms), and the
## end screens as glazed lunettes where `ends` asks (0 none, 1 far end,
## 2 near end, 3 both).
static func shed(lm: LandmarkMesh, roof: String, rib: String, glass: String, c0: Vector3, along: Vector3,
		span: float, length: float, wall_h: float, rise: float, bay: float = 9.0, glazed: float = 0.45,
		ends: int = 3, seg: int = 12) -> void:
	var dir := along.normalized()
	var side := dir.cross(Vector3.UP).normalized()
	var a := arch_points(c0, side, span, wall_h, rise, seg)
	var run := dir * length
	for k in seg:
		var mid := (float(k) + 0.5) / float(seg)
		var key := glass if absf(mid - 0.5) < glazed * 0.5 else roof
		var p0 := a[k]
		var p1 := a[k + 1]
		var up := ((p0 + p1) * 0.5 - (c0 + Vector3.UP * wall_h)).normalized()
		lm.quad(key, p0, p0 + run, p1 + run, p1, up)
		lm.quad(key, p1, p1 + run, p0 + run, p0, -up)
	# Side walls (the platform sides stay open below the eaves on piers).
	for s in [-1.0, 1.0]:
		var foot: Vector3 = c0 + side * span * 0.5 * float(s)
		lm.box(rib, foot + run * 0.5 + Vector3.UP * (wall_h - 0.6), Vector3(0.5, 1.2, 0.5) + _abs(dir) * length,
			Basis(), 0.0)
	var n := maxi(int(length / bay), 1)
	for i in n + 1:
		var o := run * float(i) / float(n)
		for k in seg:
			lm.beam(rib, a[k] + o - Vector3.UP * 0.25, a[k + 1] + o - Vector3.UP * 0.25, 0.35, 0.6, dir)
		for s in [-1.0, 1.0]:
			var foot2: Vector3 = c0 + o + side * span * 0.5 * float(s)
			lm.box(rib, foot2 + Vector3.UP * wall_h * 0.5, Vector3(0.6, wall_h, 0.6), Basis(), 0.0)
	if ends & 1:
		lunette(lm, rib, glass, c0 + run + Vector3.UP * wall_h, dir, span, rise, seg)
	if ends & 2:
		lunette(lm, rib, glass, c0 + Vector3.UP * wall_h, -dir, span, rise, seg)

static func _abs(v: Vector3) -> Vector3:
	return Vector3(absf(v.x), absf(v.y), absf(v.z))

## Glazed lunette under an arch springing at `c` (centre of the springing
## line) facing `out`: glass fan, the arch frame and radiating mullions.
static func lunette(lm: LandmarkMesh, frame: String, glass: String, c: Vector3, out: Vector3, span: float,
		rise: float, seg: int = 12, bars: int = 7) -> void:
	var n := out.normalized()
	var side := n.cross(Vector3.UP).normalized()
	var a := arch_points(c - Vector3.UP * 0.0, side, span, 0.0, rise, seg)
	for k in seg:
		lm.tri(glass, c, a[k], a[k + 1], n, n, n, Vector2.ZERO, Vector2(1, 0), Vector2(0, 1))
		lm.tri(glass, c, a[k + 1], a[k], -n, -n, -n, Vector2.ZERO, Vector2(1, 0), Vector2(0, 1))
		lm.beam(frame, a[k] + n * 0.1, a[k + 1] + n * 0.1, 0.5, 0.4, n)
	lm.beam(frame, a[0] + n * 0.1, a[seg] + n * 0.1, 0.45, 0.4, n)
	for b in bars:
		var x := (float(b) + 1.0) / float(bars + 1) * 2.0 - 1.0
		var top := c + side * x * span * 0.5 + Vector3.UP * rise * sqrt(maxf(1.0 - x * x, 0.0))
		lm.beam(frame, c + side * x * span * 0.5 + n * 0.12, top + n * 0.12, 0.18, 0.25, n)
	for t in [0.35, 0.7]:
		var hw: float = span * 0.5 * sqrt(1.0 - t * t)
		lm.beam(frame, c - side * hw + Vector3.UP * rise * t + n * 0.12,
			c + side * hw + Vector3.UP * rise * t + n * 0.12, 0.16, 0.25, n)

## Round-headed opening `w` wide and `h` to the crown standing on `foot`
## (bottom centre on the wall face) facing `out`: glass, an archivolt
## frame, glazing bars and a transom at the springing.
static func arch_window(lm: LandmarkMesh, frame: String, glass: String, foot: Vector3, out: Vector3, w: float,
		h: float, bars: int = 3, fw: float = -1.0) -> void:
	var n := out.normalized()
	var r := Vector3.UP.cross(n).normalized()
	var hw := w * 0.5
	var spring := maxf(h - hw, 0.1)
	var f := fw if fw > 0.0 else clampf(w * 0.08, 0.15, 0.9)
	# Glass and frame stand well clear of the wall face: at a grazing view
	# from a few hundred metres a closer pane flickers into the wall.
	var g := foot + n * 0.12
	lm.quad(glass, g - r * hw, g + r * hw, g + r * hw + Vector3.UP * spring, g - r * hw + Vector3.UP * spring, n)
	var cen := g + Vector3.UP * spring
	var prev := cen + r * hw
	var seg := 10
	for k in range(1, seg + 1):
		var t := PI * float(k) / float(seg)
		var p := cen + r * hw * cos(t) + Vector3.UP * hw * sin(t)
		lm.tri(glass, cen, prev, p, n, n, n, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO)
		lm.beam(frame, prev + (prev - cen).normalized() * f * 0.5 + n * 0.2,
			p + (p - cen).normalized() * f * 0.5 + n * 0.2, f, 0.3, n)
		prev = p
	for s in [-1.0, 1.0]:
		lm.box(frame, foot + r * (hw + f * 0.5) * float(s) + n * 0.25 + Vector3.UP * spring * 0.5,
			Vector3(f, spring, 0.3), Basis(r, Vector3.UP, n), 0.0)
	for b in bars:
		var x := ((float(b) + 1.0) / float(bars + 1) * 2.0 - 1.0) * hw
		var top := spring + sqrt(maxf(hw * hw - x * x, 0.0))
		lm.box(frame, foot + r * x + n * 0.18 + Vector3.UP * top * 0.5, Vector3(0.14, top, 0.14),
			Basis(r, Vector3.UP, n), 0.0)
	lm.box(frame, foot + n * 0.18 + Vector3.UP * spring, Vector3(w, 0.18, 0.16), Basis(r, Vector3.UP, n), 0.0)

## `count` round-headed openings evenly along a..b, sills `y` up.
static func arch_row(lm: LandmarkMesh, frame: String, glass: String, a: Vector3, b: Vector3, out: Vector3,
		y: float, count: int, w: float, h: float, bars: int = 1) -> void:
	for i in count:
		var p := a.lerp(b, (float(i) + 0.5) / float(count))
		arch_window(lm, frame, glass, Vector3(p.x, y, p.z), out, w, h, bars)

## Clock dial of radius `r` at `c` facing `out`: lit face, moulded ring,
## hour marks and the two hands.
static func clock(lm: LandmarkMesh, dial: String, trim: String, c: Vector3, out: Vector3, r: float) -> void:
	var n := out.normalized()
	var right := Vector3.UP.cross(n).normalized()
	var basis := Basis(right, Vector3.UP, n)
	lm.disc(dial, c + n * 0.06, n, r, 24)
	LandmarkFhParts.ring(lm, trim, c + n * 0.02, n, r, r * 1.18, 0.2, 24)
	for k in 12:
		var t := TAU * float(k) / 12.0
		lm.box(trim, c + n * 0.1 + (right * cos(t) + Vector3.UP * sin(t)) * r * 0.85,
			Vector3(r * 0.08, r * 0.08, 0.05), basis, 0.0)
	lm.beam(trim, c + n * 0.12, c + n * 0.12 + (right * 0.5 + Vector3.UP * 0.6).normalized() * r * 0.55,
		r * 0.07, 0.04, n)
	lm.beam(trim, c + n * 0.14, c + n * 0.14 + (right * -0.7 + Vector3.UP * 0.2).normalized() * r * 0.8,
		r * 0.05, 0.04, n)

## Flat forecourt canopy along a..b standing out `depth` from the wall
## (out the outward normal) at height `h`, on slim posts at its front.
static func canopy(lm: LandmarkMesh, roof: String, post: String, a: Vector3, b: Vector3, out: Vector3,
		depth: float, h: float, posts: int = 0) -> void:
	var o := out.normalized()
	var dir := (b - a).normalized()
	var basis := Basis(dir, Vector3.UP, dir.cross(Vector3.UP).normalized())
	var m := (a + b) * 0.5 + o * depth * 0.5 + Vector3.UP * h
	lm.box(roof, m, Vector3(a.distance_to(b), 0.45, depth), basis)
	var n := posts if posts > 0 else maxi(int(a.distance_to(b) / 7.0), 1) + 1
	for i in n:
		var p := a.lerp(b, float(i) / float(maxi(n - 1, 1))) + o * (depth - 0.5)
		lm.box(post, p + Vector3.UP * h * 0.5, Vector3(0.3, h, 0.3), Basis(), 0.0)

## Ridge-and-furrow platform roof over a `w` (across) by `l` (along +Z of
## `basis`) rectangle with eaves at `c`: `n` glazed ridges side by side.
static func ridge_furrow(lm: LandmarkMesh, glass: String, roof: String, c: Vector3, w: float, l: float,
		n: int, rise: float, basis: Basis = Basis()) -> void:
	var step := w / float(n)
	for i in n:
		var x := -w * 0.5 + step * (float(i) + 0.5)
		lm.gable(glass, c + basis.x * x, step, l, rise, basis, 0.0, roof)
		lm.box(roof, c + basis.x * x + basis.y * (rise + 0.1), Vector3(0.3, 0.25, l), basis, 0.0)

## Square clock tower `w` wide on `base`: shaft to `shaft_h`, a cornice,
## a clock on every face just below it, and its cap `cap_h` tall:
## "pyramid", "pavilion" (a truncated, steep hip with a lantern), "dome",
## "spire" or "flat" (a parapet and flagpole).
static func clock_tower(lm: LandmarkMesh, wall: String, trim: String, roof: String, dial: String, glass: String,
		base: Vector3, w: float, shaft_h: float, cap: String, cap_h: float, yaw: float = 0.0) -> void:
	var basis := Basis(Vector3.UP, yaw)
	lm.box(wall, base + Vector3.UP * shaft_h * 0.5, Vector3(w, shaft_h, w), basis)
	lm.box(trim, base + Vector3.UP * (shaft_h - 0.4), Vector3(w + 0.8, 0.8, w + 0.8), basis)
	lm.box(trim, base + Vector3.UP * 0.6, Vector3(w + 0.5, 1.2, w + 0.5), basis)
	for i in 4:
		var n := basis * Vector3(sin(PI * 0.5 * float(i)), 0, cos(PI * 0.5 * float(i)))
		clock(lm, dial, trim, base + n * w * 0.5 + Vector3.UP * (shaft_h - w * 0.55), n, w * 0.3)
		var r := Vector3.UP.cross(n)
		LandmarkFhUtil.openings(lm, glass, base + n * w * 0.5 - r * w * 0.25, base + n * w * 0.5 + r * w * 0.25, n,
			shaft_h * 0.35, 2, w * 0.14, shaft_h * 0.3, true, 0.05)
	var top := base + Vector3.UP * shaft_h
	match cap:
		"pyramid":
			LandmarkFhUtil.hip(lm, roof, top, w + 0.6, w + 0.6, cap_h)
		"pavilion":
			LandmarkFhUtil.hip(lm, roof, top, w + 0.6, w + 0.6, cap_h * 0.6, 0.45)
			lm.box(trim, top + Vector3.UP * (cap_h * 0.6 + cap_h * 0.12), Vector3(w * 0.35, cap_h * 0.24, w * 0.35), basis)
			LandmarkFhUtil.hip(lm, roof, top + Vector3.UP * cap_h * 0.84, w * 0.4, w * 0.4, cap_h * 0.16)
		"dome":
			lm.lathe(roof, top, LandmarkFhUtil.dome_prof(w * 0.5, cap_h * 0.8), 16)
			lm.frustum(trim, top + Vector3.UP * cap_h * 0.8, w * 0.06, w * 0.02, cap_h * 0.2, 8)
		"spire":
			lm.spire(roof, top, w * 0.5 + 0.3, cap_h)
		_:
			LandmarkFhUtil.merlons(lm, trim, top + basis * Vector3(-w * 0.5, 0, w * 0.5), top + basis * Vector3(w * 0.5, 0, w * 0.5),
				1.2, 0.6, 0.9, 0.3)
			lm.box(trim, top + Vector3.UP * cap_h * 0.5, Vector3(0.15, cap_h, 0.15), basis, 0.0)

## A walled block w (X) by d (Z) centred (cx, cz) from y0, `h` to the
## eaves: windows on every face (`pitch`-metre storeys, one opening per
## `bay` metres, arched on the ground floor when `arched`), a cornice and
## its roof: "flat", "hip" (rise `rh`), "mansard" (steep 70% then flat),
## "gable_x" / "gable_z" (ridge along X / Z) or "barrel" (ridge along X).
static func block(lm: LandmarkMesh, wall: String, trim: String, glass: String, roof: String, cx: float, cz: float,
		w: float, d: float, y0: float, h: float, roof_kind: String = "flat", rh: float = 0.0, bay: float = 4.2,
		pitch: float = 4.5, arched: bool = false) -> void:
	lm.box(wall, Vector3(cx, y0 + h * 0.5, cz), Vector3(w, h, d))
	# The cornice stops just under the roof line: a face coplanar with the
	# block's top would flicker against it.
	lm.box(trim, Vector3(cx, y0 + h - 0.4, cz), Vector3(w + 0.7, 0.7, d + 0.7))
	lm.box(trim, Vector3(cx, y0 + 0.5, cz), Vector3(w + 0.4, 1.0, d + 0.4))
	var rows := maxi(int((h - 1.5) / pitch), 1)
	for face in LandmarkFhParts.faces(cx, cz, w, d):
		var a: Vector3 = face[0]
		var b: Vector3 = face[1]
		var o: Vector3 = face[2]
		var n := maxi(int(a.distance_to(b) / bay), 1)
		var inset := (b - a).normalized() * minf(bay * 0.25, a.distance_to(b) * 0.1)
		var p0 := a + inset + Vector3.UP * y0
		var p1 := b - inset + Vector3.UP * y0
		if arched and h >= 7.0:
			arch_row(lm, trim, glass, p0 + o * 0.02, p1 + o * 0.02, o, y0 + 0.9, n, minf(bay * 0.55, 3.0),
				minf(pitch * 1.1, h * 0.45), 1)
			LandmarkFhUtil.window_grid(lm, glass, p0 - Vector3.UP * y0, p1 - Vector3.UP * y0, o,
				y0 + pitch * 1.35, maxi(rows - 1, 0), pitch, n, minf(bay * 0.4, 1.8), pitch * 0.55)
		else:
			LandmarkFhUtil.window_grid(lm, glass, p0 - Vector3.UP * y0, p1 - Vector3.UP * y0, o,
				y0 + 1.3, rows, pitch, n, minf(bay * 0.4, 1.8), pitch * 0.55)
	var top := Vector3(cx, y0 + h, cz)
	match roof_kind:
		"hip":
			hip_roof(lm, roof, top, w + 0.6, d + 0.6, rh)
		"mansard":
			# Lifted a hair so the roof's base cap does not lie on the block's top.
			LandmarkFhUtil.hip(lm, roof, top + Vector3.UP * 0.03, w + 0.4, d + 0.4, rh - 0.03, 0.55)
		"gable_x":
			LandmarkFhUtil.ridge_x(lm, roof, wall, top, w, d, rh)
		"gable_z":
			LandmarkFhUtil.ridge_z(lm, roof, wall, top, w, d, rh)
		"barrel":
			LandmarkFhHelsinkiCity._barrel(lm, roof, top - Vector3(w * 0.5, 0, 0), top + Vector3(w * 0.5, 0, 0),
				d * 0.5 + 0.3, rh)

## A true hipped roof over a `w` (X) by `d` (Z) rectangle with eaves at
## `c`: four sloping planes meeting on a ridge along the long side (a
## pyramid when square), `rise` tall.
static func hip_roof(lm: LandmarkMesh, key: String, c: Vector3, w: float, d: float, rise: float) -> void:
	var half := absf(w - d) * 0.5
	var ax := Vector3(half, 0, 0) if w >= d else Vector3(0, 0, half)
	var r0 := c + Vector3.UP * rise - ax
	var r1 := c + Vector3.UP * rise + ax
	var a := c + Vector3(-w * 0.5, 0, -d * 0.5)
	var b := c + Vector3(w * 0.5, 0, -d * 0.5)
	var e := c + Vector3(w * 0.5, 0, d * 0.5)
	var f := c + Vector3(-w * 0.5, 0, d * 0.5)
	var nn := Vector3(0, d * 0.5, -rise).normalized()
	var ns := Vector3(0, d * 0.5, rise).normalized()
	var nw := Vector3(-rise, w * 0.5, 0).normalized()
	var ne := Vector3(rise, w * 0.5, 0).normalized()
	if w >= d:
		# Ridge along X: long planes north and south, hip ends east and west.
		lm.quad(key, a, b, r1, r0, nn)
		lm.quad(key, e, f, r0, r1, ns)
		lm.tri(key, f, a, r0, nw, nw, nw, Vector2.ZERO, Vector2(d, 0), Vector2(d * 0.5, rise))
		lm.tri(key, b, e, r1, ne, ne, ne, Vector2.ZERO, Vector2(d, 0), Vector2(d * 0.5, rise))
	else:
		# Ridge along Z: long planes west and east, hip ends north and south.
		lm.quad(key, f, a, r0, r1, nw)
		lm.quad(key, b, e, r1, r0, ne)
		lm.tri(key, a, b, r0, nn, nn, nn, Vector2.ZERO, Vector2(w, 0), Vector2(w * 0.5, rise))
		lm.tri(key, e, f, r1, ns, ns, ns, Vector2.ZERO, Vector2(w, 0), Vector2(w * 0.5, rise))

## Materials every station model uses: Walls and Trim (`wall_set` tinted
## `wall` / `trim`), Roof, Glass, Steel (painted iron), Dial and Gilt.
static func mats(lm: LandmarkMesh, wall_set: String, wall: String, trim: String, roof_set: String,
		roof: String, steel: String = "#4E5A60") -> void:
	lm.use("Walls", LandmarkMaterials.pbr(wall_set, wall, 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", trim, 3.0))
	lm.use("Roof", LandmarkMaterials.pbr(roof_set, roof, 2.0))
	lm.use("Glass", LandmarkMaterials.glass("#2A3236"))
	lm.use("Steel", LandmarkMaterials.paint(steel))
	lm.use("Dial", LandmarkMaterials.lit("#F2EEE0", 0.35))
	lm.use("Gilt", LandmarkMaterials.gold())

## A statue on a plinth (rooftop figures), `h` tall standing on `base`.
static func statue(lm: LandmarkMesh, key: String, base: Vector3, h: float) -> void:
	lm.box(key, base + Vector3.UP * h * 0.12, Vector3(h * 0.35, h * 0.24, h * 0.35))
	lm.lathe(key, base + Vector3.UP * h * 0.24, PackedVector2Array([Vector2(h * 0.14, 0), Vector2(h * 0.12, h * 0.4),
		Vector2(h * 0.1, h * 0.55), Vector2(h * 0.05, h * 0.6), Vector2(h * 0.07, h * 0.68), Vector2(0, h * 0.76)]), 8)
