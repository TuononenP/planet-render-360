class_name HullLoft
extends RefCounted

## Lofted vessel hulls (metres; +X bow, y = 0 at the waterline, centred on
## x = 0). A hull is a set of cross sections from the transom to the stem,
## each running sheer -> boot-top -> waterline -> bilge -> keel -> bilge ...
## -> sheer, joined by LandmarkMesh.grid so the sides, flared bow, rounded
## bilge and raked stem are smooth surfaces rather than boxes.
##
## `spec` keys (all optional but length / beam / freeboard / draft):
##   length, beam       overall, over the raked stem and transom
##   freeboard          waterline to sheer amidships
##   draft              waterline to keel amidships
##   entry              share of the length that tapers to the stem (0.3)
##   bow_pow            bow fullness; larger is bluffer (1.9)
##   stern_w            transom width share of the beam (0.8)
##   flare              waterline half-beam is this much narrower than the sheer (0.08)
##   deadrise           0 round bilge .. 1 hard-chine V (0)
##   bow_rise           extra sheer height at the stem (m)
##   stern_rise         extra sheer height at the transom (m)
##   stem_rake          the stem's sheer overhangs the waterline by this (m)
##   stern_rake         the transom's sheer sits this far aft of its waterline (m)
##   keel_lift          0..1 how far the keel rises at the ends (0.85)
##   lod                0 full stations, 1 about half
const TIP := 0.03
const STATIONS_HI := [0.0, 0.02, 0.06, 0.12, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.78, 0.85, 0.9, 0.94, 0.97, 1.0]
const STATIONS_LO := [0.0, 0.06, 0.2, 0.4, 0.6, 0.78, 0.9, 0.97, 1.0]
## How far each section point follows the stem / transom rake (keel to sheer).
const RAKE_W := [1.0, 0.7, 0.4, 0.35, 0.15, 0.0]

static func _f(spec: Dictionary, key: String, fallback: float) -> float:
	return float(spec.get(key, fallback))

static func x0(spec: Dictionary) -> float:
	return -float(spec["length"]) * 0.5 + _f(spec, "stern_rake", 0.0)

static func body_length(spec: Dictionary) -> float:
	return float(spec["length"]) - _f(spec, "stem_rake", 0.0) - _f(spec, "stern_rake", 0.0)

static func t_of(spec: Dictionary, x: float) -> float:
	return clampf((x - x0(spec)) / maxf(body_length(spec), 0.001), 0.0, 1.0)

## Waterplane / deck outline width share (1 amidships) at `t`.
static func plan(spec: Dictionary, t: float) -> float:
	var e := _f(spec, "entry", 0.3)
	var w := 1.0
	if t > 1.0 - e:
		var k := (t - (1.0 - e)) / e
		w = 1.0 - pow(k, _f(spec, "bow_pow", 1.9)) * (1.0 - TIP)
	var tail := 0.1
	if t < tail:
		var k := 1.0 - t / tail
		w = minf(w, lerpf(1.0, _f(spec, "stern_w", 0.8), k * k))
	return w

## Half-beam at the sheer at `x`.
static func half(spec: Dictionary, x: float) -> float:
	return float(spec["beam"]) * 0.5 * plan(spec, t_of(spec, x))

## Sheer height above the waterline at `x`.
static func sheer(spec: Dictionary, x: float) -> float:
	var t := t_of(spec, x)
	return float(spec["freeboard"]) + _f(spec, "bow_rise", 0.0) * pow(t, 3.0) \
		+ _f(spec, "stern_rise", 0.0) * pow(1.0 - t, 3.0)

## Hull side (half-width) at height `y` above the waterline at `x`.
static func side_z(spec: Dictionary, x: float, y: float) -> float:
	var t := t_of(spec, x)
	var hb := half(spec, x)
	var wl := hb * (1.0 - _f(spec, "flare", 0.08) * (0.4 + 0.6 * t))
	return lerpf(wl, hb, clampf(y / maxf(sheer(spec, x), 0.01), 0.0, 1.0))

static func keel_y(spec: Dictionary, t: float) -> float:
	var e := _f(spec, "entry", 0.3)
	var lift := _f(spec, "keel_lift", 0.85)
	var bow := 0.0
	if t > 1.0 - e * 0.9:
		bow = pow((t - (1.0 - e * 0.9)) / (e * 0.9), 1.5)
	var stern := pow(maxf(0.0, 1.0 - t / 0.2), 2.0) * 0.35
	return -float(spec["draft"]) * (1.0 - lift * bow - stern)

## The section at `t` as 11 points (port sheer .. keel .. starboard sheer).
static func section(spec: Dictionary, t: float) -> Array:
	var length := float(spec["length"])
	var x := x0(spec) + t * body_length(spec)
	var hb := half(spec, x)
	var sh := sheer(spec, x)
	var flare := _f(spec, "flare", 0.08) * (0.4 + 0.6 * t)
	var z_wl := hb * (1.0 - flare)
	var ky := keel_y(spec, t)
	var dead := _f(spec, "deadrise", 0.0)
	var boot := minf(0.04 * length + 0.05, sh * 0.25)
	var rake := 0.0
	var e := _f(spec, "entry", 0.3)
	if t > 1.0 - e:
		rake = _f(spec, "stem_rake", 0.0) * pow((t - (1.0 - e)) / e, 2.0)
	var back := 0.0
	if t < 0.1:
		back = -_f(spec, "stern_rake", 0.0) * pow(1.0 - t / 0.1, 2.0)
	var pts := [
		Vector3(0, sh, hb), Vector3(0, sh * 0.5, lerpf(z_wl, hb, 0.5)),
		Vector3(0, boot, z_wl), Vector3(0, 0.0, z_wl),
		Vector3(0, ky * lerpf(0.62, 0.12, dead), z_wl * lerpf(0.82, 0.96, dead)),
		Vector3(0, ky, 0.0)]
	var out: Array = []
	for i in 6:
		var p: Vector3 = pts[i]
		p.x = x + (rake + back) * float(RAKE_W[i])
		pts[i] = p
	# Port side runs sheer -> keel, starboard mirrors it back up.
	for i in 6:
		var p: Vector3 = pts[i]
		out.append(Vector3(p.x, p.y, -p.z))
	for i in range(4, -1, -1):
		out.append(pts[i])
	return out

## Builds the hull into `lm`. `keys` names the surfaces: hull (topsides),
## boot (the stripe at the waterline), bottom, deck. `origin` offsets the
## whole hull (lifeboats, tenders). Returns {"sheer": [port, starboard]
## PackedVector3Array paths, "stations": the section rows}.
static func loft(lm: LandmarkMesh, spec: Dictionary, keys: Dictionary, origin: Vector3 = Vector3.ZERO) -> Dictionary:
	var ts: Array = STATIONS_LO if int(spec.get("lod", 0)) > 0 else STATIONS_HI
	var rows: Array = []
	for t in ts:
		var row := PackedVector3Array()
		for p in section(spec, float(t)):
			row.append((p as Vector3) + origin)
		rows.append(row)
	var centre := origin + Vector3(0, -float(spec["draft"]) * 0.3, 0)
	_band(lm, str(keys.get("hull", "Hull")), rows, 0, 2, centre)
	_band(lm, str(keys.get("boot", "Boot")), rows, 2, 3, centre)
	_band(lm, str(keys.get("bottom", "Bottom")), rows, 3, 7, centre)
	_band(lm, str(keys.get("boot", "Boot")), rows, 7, 8, centre)
	_band(lm, str(keys.get("hull", "Hull")), rows, 8, 10, centre)
	# Deck: a gently cambered surface inset from the sheer.
	var deck_rows: Array = []
	var port := PackedVector3Array()
	var star := PackedVector3Array()
	var inset := _f(spec, "deck_inset", 0.04)
	for r in rows:
		var row: PackedVector3Array = r
		var a := row[0]
		var b := row[10]
		var camber := Vector3(0, minf(absf(b.z - a.z) * 0.012, 0.15), 0)
		var pa := Vector3(a.x, a.y, a.z + inset)
		var pb := Vector3(b.x, b.y, b.z - inset)
		var mid := (pa + pb) * 0.5 + camber
		deck_rows.append(PackedVector3Array([pa, mid, pb]))
		port.append(a)
		star.append(b)
	lm.grid(str(keys.get("deck", "Deck")), deck_rows, Vector3.UP)
	# Transom.
	var first: PackedVector3Array = rows[0]
	var c := Vector3.ZERO
	for p in first:
		c += p
	c /= float(first.size())
	for i in first.size() - 1:
		lm.tri(str(keys.get("hull", "Hull")), c, first[i + 1], first[i], Vector3.LEFT, Vector3.LEFT,
			Vector3.LEFT, Vector2.ZERO, Vector2(1, 0), Vector2(0, 1))
	return {"sheer": [port, star], "stations": rows}

static func _band(lm: LandmarkMesh, key: String, rows: Array, c0: int, c1: int, centre: Vector3) -> void:
	var cut: Array = []
	for r in rows:
		var row: PackedVector3Array = r
		cut.append(row.slice(c0, c1 + 1))
	lm.grid(key, cut, centre, true)

## Round tube along `path` (Array of Vector3), `r` radius, `seg` sides.
static func tube(lm: LandmarkMesh, key: String, path: Array, r: float, seg: int = 6) -> void:
	if path.size() < 2:
		return
	var rows: Array = []
	for i in path.size():
		var a: Vector3 = path[maxi(i - 1, 0)]
		var b: Vector3 = path[mini(i + 1, path.size() - 1)]
		var t := (b - a).normalized()
		var u := t.cross(Vector3.UP if absf(t.y) < 0.9 else Vector3.RIGHT).normalized()
		var v := t.cross(u)
		var row := PackedVector3Array()
		for k in seg + 1:
			var ang := TAU * float(k) / float(seg)
			row.append((path[i] as Vector3) + (u * cos(ang) + v * sin(ang)) * r)
		rows.append(row)
	lm.grid(key, rows)

## Flat slab: polygon `pts` in the XY plane extruded +-`half_t` in Z (keels,
## rudders, outboard legs).
static func fin(lm: LandmarkMesh, key: String, pts: PackedVector2Array, half_t: float, z: float = 0.0) -> void:
	var idx := Geometry2D.triangulate_polygon(pts)
	for t in range(0, idx.size(), 3):
		for s in [-1.0, 1.0]:
			var a := pts[idx[t]]
			var b := pts[idx[t + 1]]
			var c := pts[idx[t + 2]]
			var n := Vector3(0, 0, s)
			lm.tri(key, Vector3(a.x, a.y, z + s * half_t), Vector3(b.x, b.y, z + s * half_t),
				Vector3(c.x, c.y, z + s * half_t), n, n, n, a, b, c)
	var area := 0.0
	for i in pts.size():
		area += pts[i].cross(pts[(i + 1) % pts.size()])
	for i in pts.size():
		var p := pts[i]
		var q := pts[(i + 1) % pts.size()]
		var e := (q - p).normalized()
		var n := Vector3(e.y, -e.x, 0) * (1.0 if area > 0.0 else -1.0)
		lm.quad(key, Vector3(p.x, p.y, z - half_t), Vector3(q.x, q.y, z - half_t),
			Vector3(q.x, q.y, z + half_t), Vector3(p.x, p.y, z + half_t), n)

## Posts + top rail along the sheer between `xa` and `xb`, `h` above the deck.
static func rail(lm: LandmarkMesh, key: String, spec: Dictionary, xa: float, xb: float,
		h: float, step: float, y_off: float = 0.0, inset: float = 0.06, w: float = 0.04) -> void:
	var n := maxi(int(absf(xb - xa) / maxf(step, 0.1)), 1)
	for side in [-1.0, 1.0]:
		var prev := Vector3.INF
		for i in n + 1:
			var x := lerpf(xa, xb, float(i) / float(n))
			var z: float = (half(spec, x) - inset) * float(side)
			var y := sheer(spec, x) + y_off
			var top := Vector3(x, y + h, z)
			lm.beam(key, Vector3(x, y, z), top, w)
			if prev != Vector3.INF:
				lm.beam(key, prev, top, w)
			prev = top
