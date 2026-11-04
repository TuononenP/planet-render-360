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
##   lod                0 curved near hull, 1 reduced distant hull
##   cockpit            optional Rect2: x range / half-width of an open well
##   cockpit_y          sole height above water
##   double_ended       mirror the entry shape at the stern
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
	if bool(spec.get("double_ended", false)):
		return 1.0 - pow(clampf((maxf(t, 1.0 - t) - (1.0 - e)) / e, 0.0, 1.0), _f(spec, "bow_pow", 1.9)) * (1.0 - _f(spec, "end_width", 0.35))
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
	if bool(spec.get("double_ended", false)):
		t = maxf(t, 1.0 - t)
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
	var near := int(spec.get("lod", 0)) == 0
	var ts: Array = STATIONS_LO.duplicate() if not near else []
	if near:
		for i in STATIONS_HI.size() - 1:
			var divisions := 4 if bool(spec.get("ultra", false)) else 2
			for k in divisions:
				ts.append(lerpf(float(STATIONS_HI[i]), float(STATIONS_HI[i + 1]), float(k) / float(divisions)))
		ts.append(1.0)
	var well: Rect2 = spec.get("cockpit", Rect2())
	if well.has_area():
		for x in [well.position.x, well.end.x]:
			var t := t_of(spec, x)
			if not ts.has(t):
				ts.append(t)
		ts.sort()
	var rows: Array = []
	for t in ts:
		var points := section(spec, float(t))
		if near and _f(spec, "deadrise", 0.0) < 0.95:
			points = _round_section(points, 10 if bool(spec.get("ultra", false)) else 6)
		var row := PackedVector3Array()
		for p in points:
			row.append((p as Vector3) + origin)
		rows.append(row)
	var centre := origin + Vector3(0, -float(spec["draft"]) * 0.3, 0)
	var skin_keys := keys.duplicate()
	if not near:
		skin_keys["boot"] = keys.get("hull", "Hull")
		skin_keys["bottom"] = keys.get("hull", "Hull")
	_skin(lm, spec, skin_keys, rows, centre)
	# Deck: a gently cambered surface inset from the sheer.
	var deck_rows: Array = []
	var port := PackedVector3Array()
	var star := PackedVector3Array()
	var inset := _f(spec, "deck_inset", 0.04)
	for r in rows:
		var row: PackedVector3Array = r
		var a := row[0]
		var b := row[row.size() - 1]
		var camber := Vector3(0, minf(absf(b.z - a.z) * 0.012, 0.15), 0)
		var margin := minf(inset, absf(b.z - a.z) * 0.2)
		var pa := Vector3(a.x, a.y, a.z + margin)
		var pb := Vector3(b.x, b.y, b.z - margin)
		var mid := (pa + pb) * 0.5 + camber
		if well.has_area():
			var hw := minf(well.size.y, absf(pb.z - pa.z) * 0.42)
			deck_rows.append(PackedVector3Array([pa, Vector3(pa.x, pa.y, -hw) + Vector3(0, 0, origin.z),
				Vector3(pb.x, pb.y, hw) + Vector3(0, 0, origin.z), pb]))
		else:
			deck_rows.append(PackedVector3Array([pa, mid, pb]))
		port.append(a)
		star.append(b)
	if near:
		for j in rows.size() - 1:
			var a: PackedVector3Array = rows[j]
			var b: PackedVector3Array = rows[j + 1]
			var da: PackedVector3Array = deck_rows[j]
			var db: PackedVector3Array = deck_rows[j + 1]
			_deck_quad(lm, str(keys.get("hull", "Hull")), a[0], b[0], db[0], da[0])
			_deck_quad(lm, str(keys.get("hull", "Hull")), a[a.size() - 1], b[b.size() - 1], db[db.size() - 1], da[da.size() - 1])
	if well.has_area():
		_open_deck(lm, spec, str(keys.get("deck", "Deck")), deck_rows, well, origin, ts)
	else:
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
	if near:
		lm.tri(str(keys.get("hull", "Hull")), c, first[first.size() - 1], first[0], Vector3.LEFT, Vector3.LEFT,
			Vector3.LEFT, Vector2.ZERO, Vector2(1, 0), Vector2(0, 1))
		var last: PackedVector3Array = rows[rows.size() - 1]
		var stem := Vector3.ZERO
		for p in last:
			stem += p
		stem /= float(last.size())
		lm.tri(str(keys.get("hull", "Hull")), stem, last[last.size() - 1], last[0], Vector3.RIGHT, Vector3.RIGHT,
			Vector3.RIGHT, Vector2.ZERO, Vector2(1, 0), Vector2(0, 1))
		for i in last.size() - 1:
			lm.tri(str(keys.get("hull", "Hull")), stem, last[i], last[i + 1], Vector3.RIGHT, Vector3.RIGHT,
				Vector3.RIGHT, Vector2.ZERO, Vector2(1, 0), Vector2(0, 1))
	return {"sheer": [port, star], "stations": rows}

## Dense samples follow an elliptical bilge instead of two planar panels.
static func _round_section(points: Array, samples: int) -> Array:
	var side: Array = points.slice(0, 4)
	var wl: Vector3 = points[3]
	var keel: Vector3 = points[5]
	for i in range(1, samples + 1):
		var a := PI * 0.5 * float(i) / float(samples)
		side.append(Vector3(lerpf(wl.x, keel.x, sin(a)), lerpf(wl.y, keel.y, sin(a)), wl.z * cos(a)))
	var out := side.duplicate()
	for i in range(side.size() - 2, -1, -1):
		var p: Vector3 = side[i]
		out.append(Vector3(p.x, p.y, -p.z))
	return out

## Normals come from the complete hull, so paint boundaries share them.
## Chines use one-sided tangents on either side of the crease.
static func _skin(lm: LandmarkMesh, spec: Dictionary, keys: Dictionary, rows: Array, centre: Vector3) -> void:
	var count: int = rows[0].size()
	var hard := _f(spec, "deadrise", 0.0) >= 0.95
	var normals: Array = []
	for j in rows.size():
		var row: PackedVector3Array = rows[j]
		var nr := PackedVector3Array()
		for i in count:
			var du := row[mini(i + 1, count - 1)] - row[maxi(i - 1, 0)]
			var dv: Vector3 = rows[mini(j + 1, rows.size() - 1)][i] - rows[maxi(j - 1, 0)][i]
			var n := du.cross(dv).normalized()
			if n.dot(row[i] - centre) < 0.0:
				n = -n
			nr.append(n)
		normals.append(nr)
	for j in rows.size() - 1:
		var r0: PackedVector3Array = rows[j]
		var r1: PackedVector3Array = rows[j + 1]
		for i in count - 1:
			var surface := "bottom"
			if i < 2 or i >= count - 3:
				surface = "hull"
			elif i == 2 or i == count - 4:
				surface = "boot"
			var key := str(keys.get(surface, "Hull"))
			var ns: Array[Vector3] = [normals[j][i], normals[j][i + 1], normals[j + 1][i + 1], normals[j + 1][i]]
			if hard:
				for k in 4:
					var ci := i if k in [0, 3] else i + 1
					var ri := j if k < 2 else j + 1
					if ci in [4, count - 5]:
						var tangent: Vector3 = rows[ri][i + 1] - rows[ri][i]
						var along: Vector3 = r1[ci] - r0[ci]
						var n := tangent.cross(along).normalized()
						ns[k] = n if n.dot(rows[ri][ci] - centre) > 0.0 else -n
			var uv0 := Vector2(r0[i].x, r0[i].y)
			var uv1 := Vector2(r0[i + 1].x, r0[i + 1].y)
			var uv2 := Vector2(r1[i + 1].x, r1[i + 1].y)
			var uv3 := Vector2(r1[i].x, r1[i].y)
			lm.tri(key, r0[i], r0[i + 1], r1[i + 1], ns[0], ns[1], ns[2], uv0, uv1, uv2)
			lm.tri(key, r0[i], r1[i + 1], r1[i], ns[0], ns[2], ns[3], uv0, uv2, uv3)

## A recessed well removes the centre deck rather than covering the cockpit.
static func _open_deck(lm: LandmarkMesh, spec: Dictionary, key: String, rows: Array, well: Rect2, origin: Vector3, ts: Array) -> void:
	var sole := _f(spec, "cockpit_y", float(spec["freeboard"]) * 0.5) + origin.y
	for i in rows.size() - 1:
		var a: PackedVector3Array = rows[i]
		var b: PackedVector3Array = rows[i + 1]
		var inside := (a[1].x + b[1].x) * 0.5 - origin.x > well.position.x \
			and (a[1].x + b[1].x) * 0.5 - origin.x < well.end.x
		_deck_quad(lm, key, a[0], b[0], b[1], a[1])
		_deck_quad(lm, key, a[2], b[2], b[3], a[3])
		if not inside:
			_deck_quad(lm, key, a[1], b[1], b[2], a[2])
			continue
		for k in [1, 2]:
			lm.quad("White", a[k], b[k], Vector3(b[k].x, sole, b[k].z), Vector3(a[k].x, sole, a[k].z),
				Vector3(0, 0, 1 if k == 1 else -1))
		_deck_quad(lm, "Deck", Vector3(a[1].x, sole, a[1].z), Vector3(b[1].x, sole, b[1].z),
			Vector3(b[2].x, sole, b[2].z), Vector3(a[2].x, sole, a[2].z))
		for k in 2:
			var row: PackedVector3Array = rows[i + k]
			var at_start := absf(float(ts[i + k]) - t_of(spec, well.position.x)) < 0.00001
			var at_end := absf(float(ts[i + k]) - t_of(spec, well.end.x)) < 0.00001
			if at_start or at_end:
				lm.quad("White", row[1], row[2], Vector3(row[2].x, sole, row[2].z), Vector3(row[1].x, sole, row[1].z),
					Vector3.RIGHT if at_start else Vector3.LEFT)

static func _deck_quad(lm: LandmarkMesh, key: String, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	lm.tri(key, a, b, c, Vector3.UP, Vector3.UP, Vector3.UP, Vector2(a.z, -a.x), Vector2(b.z, -b.x), Vector2(c.z, -c.x))
	lm.tri(key, a, c, d, Vector3.UP, Vector3.UP, Vector3.UP, Vector2(a.z, -a.x), Vector2(c.z, -c.x), Vector2(d.z, -d.x))

## Round tube along `path` (Array of Vector3), `r` radius, `seg` sides.
static func tube(lm: LandmarkMesh, key: String, path: Array, r: float, seg: int = 6, cap: bool = false) -> void:
	if path.size() < 2:
		return
	var rows: Array = []
	var normals: Array = []
	var closed := (path[0] as Vector3).distance_squared_to(path[path.size() - 1]) < 0.000001
	for i in path.size():
		var a: Vector3 = path[maxi(i - 1, 0)]
		var b: Vector3 = path[mini(i + 1, path.size() - 1)]
		if closed and i in [0, path.size() - 1]:
			a = path[path.size() - 2]
			b = path[1]
		var t := (b - a).normalized()
		var u := t.cross(Vector3.UP if absf(t.y) < 0.9 else Vector3.RIGHT).normalized()
		var v := t.cross(u)
		var row := PackedVector3Array()
		var nr := PackedVector3Array()
		for k in seg + 1:
			var ang := TAU * float(k % seg) / float(seg)
			var radial := u * cos(ang) + v * sin(ang)
			row.append((path[i] as Vector3) + radial * r)
			nr.append(radial)
		rows.append(row)
		normals.append(nr)
	var distance := 0.0
	for i in rows.size() - 1:
		var step := (path[i] as Vector3).distance_to(path[i + 1])
		for k in seg:
			var ua := Vector2(TAU * r * float(k) / float(seg), distance)
			var ub := Vector2(TAU * r * float(k + 1) / float(seg), distance)
			lm.tri(key, rows[i][k], rows[i][k + 1], rows[i + 1][k + 1], normals[i][k], normals[i][k + 1], normals[i + 1][k + 1], ua, ub, ub + Vector2(0, step))
			lm.tri(key, rows[i][k], rows[i + 1][k + 1], rows[i + 1][k], normals[i][k], normals[i + 1][k + 1], normals[i + 1][k], ua, ub + Vector2(0, step), ua + Vector2(0, step))
		distance += step
	if cap:
		for end in [0, path.size() - 1]:
			var n := ((path[0] as Vector3) - (path[1] as Vector3)).normalized() if end == 0 \
				else ((path[end] as Vector3) - (path[end - 1] as Vector3)).normalized()
			for k in seg:
				lm.tri(key, path[end], rows[end][k], rows[end][k + 1], n, n, n, Vector2.ZERO, Vector2(1, 0), Vector2(0, 1))

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
		var path: Array = []
		var mid_rail: Array = []
		for i in n + 1:
			var x := lerpf(xa, xb, float(i) / float(n))
			var z: float = (half(spec, x) - inset) * float(side)
			var y := sheer(spec, x) + y_off
			var top := Vector3(x, y + h, z)
			tube(lm, key, [Vector3(x, y, z), top], w * 0.5, 6)
			path.append(top)
			mid_rail.append(top - Vector3.UP * h * 0.5)
		tube(lm, key, path, w * 0.5, 8)
		if bool(spec.get("ultra", false)):
			tube(lm, key, mid_rail, w * 0.35, 8)
