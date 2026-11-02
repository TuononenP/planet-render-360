class_name LandmarkEahDetail
extends RefCounted

## Mid-scale timber and plaster details for the east-Asia historic batch,
## in true metres on LandmarkMesh: lattice door and window bays, tie
## beams (nuki), ridge rolls with end tiles, the triangular chidori-hafu
## dormer gable and the curved kara-hafu of Japanese roofs, castle
## windows with bars, stone-drop bays (ishi-otoshi) and plain railings.
## Every part is built from sharp boxes and beams so long runs stay cheap.

## Lattice (koshi) panel w x h centred at `c` on a wall facing `n` (an
## axis-aligned unit vector): dark backing, a frame, `bars` vertical and
## `rails` horizontal bars proud of it.
static func lattice(lm: LandmarkMesh, frame: String, back: String, c: Vector3, n: Vector3, w: float,
		h: float, bars: int = 6, rails: int = 3) -> void:
	var r := Vector3.UP.cross(n).normalized()
	var basis := Basis(r, Vector3.UP, n)
	var f := clampf(w * 0.08, 0.08, 0.25)
	lm.box(back, c + n * 0.03, Vector3(w, h, 0.06), basis, 0.0)
	for s in [-1.0, 1.0]:
		lm.box(frame, c + r * (w - f) * 0.5 * float(s) + n * 0.08, Vector3(f, h, 0.16), basis, 0.0)
		lm.box(frame, c + Vector3(0, (h - f) * 0.5 * float(s), 0) + n * 0.08, Vector3(w, f, 0.16), basis, 0.0)
	for i in bars:
		var x := (float(i) + 1.0) / float(bars + 1) - 0.5
		lm.box(frame, c + r * x * (w - f) + n * 0.1, Vector3(f * 0.35, h - f, 0.06), basis, 0.0)
	for j in rails:
		var y := (float(j) + 1.0) / float(rails + 1) - 0.5
		lm.box(frame, c + Vector3(0, y * (h - f), 0) + n * 0.12, Vector3(w - f, f * 0.35, 0.06), basis, 0.0)

## Bays round a rectangular wall (size x, z centred on c, from c.y up h):
## `nx` bays on the long faces and `nz` on the short ones; `fill` picks a
## lattice (true) or a plain panel per bay through `pick(face, i) -> int`
## (0 plain wall, 1 lattice door full height, 2 lattice window upper half).
static func bays(lm: LandmarkMesh, frame: String, back: String, c: Vector3, size: Vector2, h: float,
		nx: int, nz: int, pick: Callable) -> void:
	for face in 4:
		var n: Vector3 = [Vector3.BACK, Vector3.FORWARD, Vector3.RIGHT, Vector3.LEFT][face]
		var run := size.x if face < 2 else size.y
		var off := size.y * 0.5 if face < 2 else size.x * 0.5
		var cnt := nx if face < 2 else nz
		var along := Vector3(absf(n.z), 0, absf(n.x))
		var bay := run / float(cnt)
		for i in cnt:
			var kind: int = pick.call(face, i)
			if kind == 0:
				continue
			var p := c + n * off + along * (bay * (float(i) + 0.5) - run * 0.5)
			var bw := bay * 0.82
			if kind == 1:
				lattice(lm, frame, back, p + Vector3(0, h * 0.46, 0), n, bw, h * 0.86, 5, 4)
			else:
				lattice(lm, frame, back, p + Vector3(0, h * 0.66, 0), n, bw, h * 0.4, 6, 1)

## Tie beams (nuki / fang) round a rectangle at height y.
static func ring_beams(lm: LandmarkMesh, key: String, c: Vector3, size: Vector2, y: float, h: float,
		d: float) -> void:
	for s in [-1.0, 1.0]:
		lm.box(key, Vector3(c.x, y, c.z + s * size.y * 0.5), Vector3(size.x + d, h, d), Basis(), 0.0)
		lm.box(key, Vector3(c.x + s * size.x * 0.5, y, c.z), Vector3(d, h, size.y - d), Basis(), 0.0)

## Ridge roll along X from x0 to x1 at height y (bottom), z = cz: a
## stack of tile courses `h` high, `w` wide, with raised end tiles.
static func ridge(lm: LandmarkMesh, key: String, x0: float, x1: float, y: float, cz: float, w: float,
		h: float) -> void:
	var mx := (x0 + x1) * 0.5
	var run := absf(x1 - x0)
	lm.box(key, Vector3(mx, y + h * 0.3, cz), Vector3(run, h * 0.6, w), Basis(), 0.0)
	lm.box(key, Vector3(mx, y + h * 0.75, cz), Vector3(run - w * 0.4, h * 0.3, w * 0.8), Basis(), 0.0)
	lm.box(key, Vector3(mx, y + h * 0.95, cz), Vector3(run - w * 0.6, h * 0.12, w * 0.45), Basis(), 0.0)
	for s in [-1.0, 1.0]:
		var ex: float = (x1 if s > 0.0 else x0)
		lm.box(key, Vector3(ex - s * w * 0.3, y + h * 0.7, cz), Vector3(w * 0.6, h * 1.4, w * 1.3), Basis(), 0.0)

## Chidori-hafu: a triangular dormer gable standing on a roof slope with
## its plastered face toward `n` (axis-aligned), base centre `c` at the
## eave line, `w` wide, `rise` high, running `depth` back into the roof;
## bargeboards and a pendant board (in `orn` when set, e.g. gilt).
static func chidori(lm: LandmarkMesh, roof: String, face: String, trim: String, c: Vector3, n: Vector3,
		w: float, rise: float, depth: float, orn: String = "") -> void:
	var b := Basis(Vector3.UP.cross(n).normalized(), Vector3.UP, n)
	lm.gable(roof, c - n * depth * 0.5, w, depth, rise, b, 0.35, face)
	var r := b.x
	var apex := c + Vector3(0, rise, 0) + n * 0.05
	for s in [-1.0, 1.0]:
		var foot := c + r * (w * 0.5 + 0.4) * float(s) - Vector3(0, 0.1, 0) + n * 0.05
		lm.beam(trim, foot, apex, 0.32, 0.22, n)
	lm.box(trim if orn == "" else orn, apex - Vector3(0, 0.45, 0) + n * 0.1, Vector3(0.7, 0.6, 0.12), b, 0.0)
	# Lattice of the gable face: a horizontal tie and a king post.
	lm.box(trim, c + Vector3(0, rise * 0.25, 0) + n * 0.06, Vector3(w * 0.75, 0.14, 0.08), b, 0.0)
	lm.box(trim, c + Vector3(0, rise * 0.55, 0) + n * 0.06, Vector3(0.14, rise * 0.6, 0.08), b, 0.0)

## Kara-hafu: the undulating cusped gable (convex in the middle, upswept
## at the ends) facing `n`, base centre `c`, `w` wide, `rise` high,
## `depth` deep into the roof; plastered tympanum and a thick bargeboard.
static func karahafu(lm: LandmarkMesh, roof: String, face: String, trim: String, c: Vector3, n: Vector3,
		w: float, rise: float, depth: float, orn: String = "") -> void:
	var r := Vector3.UP.cross(n).normalized()
	var seg := 14
	var pts: Array[Vector3] = []
	for i in seg + 1:
		var t := float(i) / float(seg) * 2.0 - 1.0
		var y := rise * (0.5 + 0.5 * cos(PI * t)) + rise * 0.18 * pow(absf(t), 6.0)
		pts.append(c + r * t * w * 0.5 + Vector3(0, y, 0))
	var front := PackedVector3Array()
	var back := PackedVector3Array()
	for p in pts:
		front.append(p + n * 0.3)
		back.append(p - n * depth)
	lm.grid(roof, [back, front], Vector3.UP)
	for i in seg:
		lm.beam(trim, front[i] - Vector3(0, 0.2, 0), front[i + 1] - Vector3(0, 0.2, 0), 0.45, 0.3, n)
		var base_a := Vector3(pts[i].x, c.y, pts[i].z)
		var base_b := Vector3(pts[i + 1].x, c.y, pts[i + 1].z)
		lm.quad(face, base_a, base_b, pts[i + 1] - Vector3(0, 0.35, 0), pts[i] - Vector3(0, 0.35, 0), n)
	lm.box(trim if orn == "" else orn, c + Vector3(0, rise - 0.6, 0) + n * 0.32, Vector3(0.8, 0.7, 0.14), Basis(r, Vector3.UP, n), 0.0)

## Castle window bay w x h at `c` on a wall facing `n`: dark opening
## with a frame and `bars` square bars (renji-mado).
static func castle_window(lm: LandmarkMesh, frame: String, dark: String, c: Vector3, n: Vector3,
		w: float, h: float, bars: int = 5) -> void:
	var r := Vector3.UP.cross(n).normalized()
	var basis := Basis(r, Vector3.UP, n)
	lm.box(dark, c + n * 0.04, Vector3(w, h, 0.08), basis, 0.0)
	lm.box(frame, c + n * 0.1 - Vector3(0, h * 0.5 + 0.08, 0), Vector3(w + 0.4, 0.16, 0.24), basis, 0.0)
	lm.box(frame, c + n * 0.1 + Vector3(0, h * 0.5 + 0.06, 0), Vector3(w + 0.3, 0.12, 0.2), basis, 0.0)
	for i in bars:
		var x := (float(i) + 0.5) / float(bars) - 0.5
		lm.box(frame, c + r * x * w + n * 0.1, Vector3(0.1, h, 0.1), basis, 0.0)

## Stone-drop bay (ishi-otoshi): a battered box jutting from a keep
## corner or face at y, `w` wide, `h` high, `out` deep, facing n.
static func ishi_otoshi(lm: LandmarkMesh, key: String, c: Vector3, n: Vector3, w: float, h: float,
		out: float) -> void:
	var r := Vector3.UP.cross(n).normalized()
	var top := c + n * out * 0.5
	lm.box(key, top + Vector3(0, h * 0.25, 0), Vector3(w, h * 0.5, out), Basis(r, Vector3.UP, n), 0.0)
	lm.quad(key, c + r * w * 0.5 - Vector3(0, h * 0.5, 0), c - r * w * 0.5 - Vector3(0, h * 0.5, 0),
		c - r * w * 0.5 + n * out, c + r * w * 0.5 + n * out, (n - Vector3.UP).normalized())

## Plain railing from a to b on the deck: posts every `pitch`, a top rail
## and a mid rail (`h` high).
static func railing(lm: LandmarkMesh, key: String, a: Vector3, b: Vector3, h: float, pitch: float,
		post: float = 0.14) -> void:
	var dl := a.distance_to(b)
	var n := maxi(int(round(dl / pitch)), 1)
	for i in n + 1:
		var p := a.lerp(b, float(i) / float(n))
		lm.box(key, p + Vector3(0, h * 0.5, 0), Vector3(post, h, post), Basis(), 0.0)
	lm.beam(key, a + Vector3(0, h, 0), b + Vector3(0, h, 0), post * 1.2, post * 0.9, Vector3.UP)
	lm.beam(key, a + Vector3(0, h * 0.5, 0), b + Vector3(0, h * 0.5, 0), post * 0.8, post * 0.6, Vector3.UP)

## Railing round a rectangle (size centred on c, at c.y).
static func railing_loop(lm: LandmarkMesh, key: String, c: Vector3, size: Vector2, h: float,
		pitch: float, post: float = 0.14) -> void:
	var hx := size.x * 0.5
	var hz := size.y * 0.5
	var pts := [Vector3(-hx, 0, -hz), Vector3(hx, 0, -hz), Vector3(hx, 0, hz), Vector3(-hx, 0, hz)]
	for i in 4:
		railing(lm, key, c + pts[i], c + pts[(i + 1) % 4], h, pitch, post)

## Studded double door (Chinese gate leaf pair) w x h at c facing n:
## leaves, frame, and `rows` x `cols` gilt studs per leaf.
static func studded_door(lm: LandmarkMesh, leaf: String, stud: String, c: Vector3, n: Vector3, w: float,
		h: float, rows: int = 9, cols: int = 9) -> void:
	var r := Vector3.UP.cross(n).normalized()
	var basis := Basis(r, Vector3.UP, n)
	lm.box(leaf, c + n * 0.05, Vector3(w, h, 0.1), basis, 0.0)
	for s in [-1.0, 1.0]:
		var lc := c + r * w * 0.25 * float(s)
		for i in rows:
			for j in cols:
				var p := lc + r * ((float(j) + 0.5) / float(cols) - 0.5) * w * 0.4 \
					+ Vector3(0, ((float(i) + 0.5) / float(rows) - 0.5) * h * 0.85, 0)
				lm.box(stud, p + n * 0.13, Vector3(0.12, 0.12, 0.08), basis, 0.0)
