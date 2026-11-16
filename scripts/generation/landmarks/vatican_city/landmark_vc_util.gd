class_name LandmarkVcUtil
extends RefCounted

## Helpers shared by the Vatican City builders (true metres on
## LandmarkMesh): world offsets turned into a yawed model's frame,
## boxes at any world angle, trees, and a concave niche dome.

## Model-frame position of the point `de` metres east and `dn` metres
## north of the model origin, for a model the registry turns by
## `yaw_deg` (the model's +X then points `-yaw_deg` anticlockwise from east).
static func local(de: float, dn: float, yaw_deg: float, y: float = 0.0) -> Vector3:
	var a := deg_to_rad(yaw_deg)
	return Vector3(de * cos(a) - dn * sin(a), y, -(de * sin(a) + dn * cos(a)))

## Box `w` (along `ang_deg` anticlockwise from east) by `d`, `h` tall on
## the ground, centred `de`/`dn` from the origin, drawn in a model that
## the registry turns by `yaw_deg`.
static func rbox(lm: LandmarkMesh, key: String, de: float, dn: float, yaw_deg: float,
		y0: float, w: float, h: float, d: float, ang_deg: float) -> Vector3:
	var c := local(de, dn, yaw_deg, y0 + h * 0.5)
	lm.box(key, c, Vector3(w, h, d), Basis(Vector3.UP, deg_to_rad(ang_deg + yaw_deg)))
	return c

## Quad wound so its face looks toward `toward`.
static func quad_facing(lm: LandmarkMesh, key: String, a: Vector3, b: Vector3, c: Vector3,
		d: Vector3, toward: Vector3) -> void:
	var n := (b - a).cross(d - a)
	if n.dot(toward) < 0.0:
		lm.quad(key, a, d, c, b, -n.normalized())
	else:
		lm.quad(key, a, b, c, d, n.normalized())

## Concave half-dome over a semicircular exedra of radius `r` whose
## diameter lies on `c` (ground y of the springing) facing +Z; the dome
## curves away to -Z. Seen from inside (from +Z).
static func niche_dome(lm: LandmarkMesh, key: String, c: Vector3, r: float, rings: int = 6,
		seg: int = 14) -> void:
	for j in rings:
		var p0 := PI * 0.5 * float(j) / float(rings)
		var p1 := PI * 0.5 * float(j + 1) / float(rings)
		for i in seg:
			var t0 := PI * float(i) / float(seg)
			var t1 := PI * float(i + 1) / float(seg)
			var P := func(p: float, t: float) -> Vector3:
				return c + Vector3(cos(p) * cos(t) * r, sin(p) * r, -cos(p) * sin(t) * r)
			var mid: Vector3 = P.call((p0 + p1) * 0.5, (t0 + t1) * 0.5)
			quad_facing(lm, key, P.call(p0, t0), P.call(p0, t1), P.call(p1, t1), P.call(p1, t0),
				c - mid)

## Semicircular wall of radius `r` and thickness `t` over the northern
## half (-Z) of a circle at `c`, `h` tall: `n` straight segments, the
## inner face toward the centre.
static func half_ring(lm: LandmarkMesh, key: String, c: Vector3, r: float, h: float, t: float,
		n: int = 16) -> void:
	for i in n:
		var a0 := PI * float(i) / float(n)
		var a1 := PI * float(i + 1) / float(n)
		var p0 := c + Vector3(cos(a0) * r, 0, -sin(a0) * r)
		var p1 := c + Vector3(cos(a1) * r, 0, -sin(a1) * r)
		var mid := (p0 + p1) * 0.5
		var d := p1 - p0
		lm.box(key, mid + Vector3(0, h * 0.5, 0), Vector3(d.length() + 0.15, h, t),
			Basis(Vector3.UP, atan2(-d.z, d.x)), 0.0)

## Umbrella (stone) pine: bare trunk and a flat dark crown.
static func pine(lm: LandmarkMesh, trunk: String, crown: String, base: Vector3, h: float) -> void:
	lm.frustum(trunk, base, h * 0.035, h * 0.022, h * 0.68, 6)
	lm.lathe(crown, base + Vector3(0, h * 0.6, 0), PackedVector2Array([Vector2(0.0, 0.0),
		Vector2(h * 0.26, h * 0.06), Vector2(h * 0.33, h * 0.2), Vector2(h * 0.22, h * 0.4),
		Vector2(0.0, h * 0.4)]), 10, 1.0, 1.0, 0.0, true, false)

## Italian cypress: a slim dark spire.
static func cypress(lm: LandmarkMesh, key: String, base: Vector3, h: float) -> void:
	lm.lathe(key, base, PackedVector2Array([Vector2(h * 0.07, 0.0), Vector2(h * 0.12, h * 0.35),
		Vector2(h * 0.09, h * 0.8), Vector2(0.0, h)]), 7, 1.0, 1.0, 0.0, true, false)

## Windows of a plain wall face (as LandmarkRmLUtil.block draws its front)
## for blocks whose other faces need openings too: `c` is the footprint
## centre, the face looks `out`, `w` wide and `d` deep across it.
static func face_windows(lm: LandmarkMesh, wall: String, c: Vector3, out: Vector3, w: float,
		h: float, d: float, floors: int, bays: int, win: Vector2) -> void:
	var along := Vector3.UP.cross(out)
	var floor_h := h / float(floors)
	var origin := c + out * d * 0.5 - along * w * 0.5
	LandmarkRmLKit.windows(lm, wall, "Shadow", "Trim", origin, along, out, w, h - 0.6, bays, floors,
		win, maxf((floor_h - win.y) * 0.45, 1.0), floor_h, 0)
