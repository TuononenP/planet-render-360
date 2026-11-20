extends RefCounted

## Helpers for the central Helsinki landmark models built from an OpenStreetMap
## outline (true metres on LandmarkMesh, +X east, +Z south in the model frame
## the registry yaw turns onto the map): outline runs, mitred growth for
## cornices, brick curtain walls with real recessed window bays between
## piers, dormers and stacked sign letters.

const FhP = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_parts.gd")
const FhU = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")

## Flat x, z pairs to a polygon.
static func poly(flat: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in range(0, flat.size(), 2):
		out.append(Vector2(float(flat[i]), float(flat[i + 1])))
	return out

## [a, b, out] ground-level wall runs for every edge of `p`.
static func runs(p: PackedVector2Array) -> Array:
	var out: Array = []
	for i in p.size():
		var j := (i + 1) % p.size()
		out.append([Vector3(p[i].x, 0, p[i].y), Vector3(p[j].x, 0, p[j].y), FhP.edge_out(p, i)])
	return out

## `p` grown outward by `d` metres with mitred corners (cornices, plinths).
static func grow(p: PackedVector2Array, d: float) -> PackedVector2Array:
	var res := Geometry2D.offset_polygon(p, d, Geometry2D.JOIN_MITER)
	if res.is_empty():
		return p
	return res[0]

## A solid ring slab of the outline grown by `d`, from y to y + h.
static func slab(lm: LandmarkMesh, key: String, p: PackedVector2Array, d: float, y: float, h: float) -> void:
	lm.poly_prism(key, grow(p, d), y, y + h)

## A brick curtain over one run a..b: recessed window bays (`win` w x h, one
## per `pitch` metres) in `rows` storeys, with full-height piers between them.
## Runs shorter than `min_len` are left plain.
static func pier_run(lm: LandmarkMesh, wall: String, pier: String, glass: String, a: Vector3, b: Vector3,
		out: Vector3, y0: float, y1: float, pitch: float, pier_w: float, proj: float, win: Vector2,
		sill: float, storey: float, rows: int, depth: float = 0.35, min_len: float = 4.0) -> void:
	var run_len := a.distance_to(b)
	if run_len < min_len:
		return
	var n := maxi(int(round(run_len / pitch)), 1)
	FhP.pierce(lm, wall, glass, a, b, out, y0, y1 - y0, n, rows, win, sill, storey, depth)
	if pier_w > 0.0 and n > 1:
		var d := (b - a).normalized()
		var inset := 0.5 * pier_w
		FhP.strips(lm, pier, a + d * inset, b - d * inset, out, y0, y1 - y0, n + 1, pier_w, proj + depth)

## Dormers every `step` metres along a..b on a sloped roof that rises from
## `y` at the wall line by `slope` metres per metre inward: a small walled
## box with a glazed front and a flat cap.
static func dormers(lm: LandmarkMesh, wall: String, cap: String, glass: String, a: Vector3, b: Vector3,
		out: Vector3, y: float, step: float, slope: float, w: float = 1.4, h: float = 1.5,
		inset: float = 1.4) -> void:
	var n := maxi(int(a.distance_to(b) / step), 1)
	var o := out.normalized()
	var basis := Basis(Vector3.UP.cross(o).normalized(), Vector3.UP, o)
	for i in n:
		var p := a.lerp(b, (float(i) + 0.5) / float(n)) - o * inset
		var base_y := y + inset * slope
		lm.box(wall, p + Vector3(0, base_y + h * 0.5, 0), Vector3(w, h, 1.2), basis, 0.0)
		lm.box(cap, p + Vector3(0, base_y + h + 0.1, 0) + o * 0.1, Vector3(w + 0.3, 0.2, 1.5), basis, 0.0)
		lm.quad(glass, p + Vector3(0, base_y + 0.25, 0) + o * 0.62 - basis.x * (w * 0.5 - 0.2),
			p + Vector3(0, base_y + 0.25, 0) + o * 0.62 + basis.x * (w * 0.5 - 0.2),
			p + Vector3(0, base_y + h - 0.2, 0) + o * 0.62 + basis.x * (w * 0.5 - 0.2),
			p + Vector3(0, base_y + h - 0.2, 0) + o * 0.62 - basis.x * (w * 0.5 - 0.2), o)

## A vertical column of `n` letter blocks standing on a wall at ground point
## `p` facing `out`, from y0 up to y1.
static func letters(lm: LandmarkMesh, key: String, p: Vector3, out: Vector3, y0: float, y1: float, n: int,
		w: float = 0.8, depth: float = 0.3) -> void:
	var o := out.normalized()
	var basis := Basis(Vector3.UP.cross(o).normalized(), Vector3.UP, o)
	var pitch := (y1 - y0) / float(n)
	for i in n:
		lm.box(key, p + Vector3(0, y0 + pitch * (float(i) + 0.5), 0) + o * depth * 0.5,
			Vector3(w, pitch * 0.72, depth), basis, 0.0)

## A walled block on the outline `p`: stone plinth, wall to `eave`, a string
## course and cornice slab, and recessed window bays on every run longer than
## `min_len`. `o`: wall, trim, stone, glass (material keys), plinth (1.2),
## eave, course_y (-1 = none), cornice (0.7 tall, 0.5 out), bay (3.2), win
## (Vector2 w, h), sill (first sill above y0), y0 (plinth top by default),
## storey, rows, depth (0.3), pier_w (0 = none), pier_proj (0.25), min_len (4).
static func block(lm: LandmarkMesh, p: PackedVector2Array, o: Dictionary) -> void:
	var wall: String = o.get("wall", "Wall")
	var trim: String = o.get("trim", "Trim")
	var stone: String = o.get("stone", "Stone")
	var glass: String = o.get("glass", "Glass")
	var plinth: float = o.get("plinth", 1.2)
	var eave: float = o.get("eave", 12.0)
	lm.poly_prism(wall, p, 0.0, eave, false)
	if plinth > 0.0:
		slab(lm, stone, p, 0.2, 0.0, plinth)
	var ch: float = o.get("cornice", 0.7)
	if ch > 0.0:
		slab(lm, trim, p, o.get("cornice_out", 0.5), eave - ch, ch)
	var cy: float = o.get("course_y", -1.0)
	if cy > 0.0:
		slab(lm, trim, p, 0.25, cy, 0.4)
	var rows: int = o.get("rows", 0)
	if rows > 0:
		var y0: float = o.get("y0", plinth)
		for run in runs(p):
			var a: Vector3 = run[0]
			var b: Vector3 = run[1]
			if a.distance_to(b) < float(o.get("min_len", 4.0)):
				continue
			pier_run(lm, wall, o.get("pier", trim), glass, a, b, run[2], y0, eave - ch, o.get("bay", 3.2),
				o.get("pier_w", 0.0), o.get("pier_proj", 0.25), o.get("win", Vector2(1.2, 2.0)),
				o.get("sill", 0.9), o.get("storey", 3.6), rows, o.get("depth", 0.3), o.get("min_len", 4.0))

## Floodlight spots for LandmarkLights: [[lamp, aim, cone_deg, share, range_m, colour], ...]
## in model metres.
static func flood(model: Node3D, spots: Array) -> void:
	model.set_meta(LandmarkLights.FLOOD_META, spots)
