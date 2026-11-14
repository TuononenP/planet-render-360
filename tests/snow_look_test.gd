extends SceneTree

## Headless: godot --headless --script tests/snow_look_test.gd
## The shared lying-snow look (ClimateModel.SNOW_GLSL): snow_albedo,
## snow_grit and snow_edge. Shaders do not compile under the headless
## renderer, so the helpers are mirrored here line for line and checked
## for what the look relies on: fresh snow bright but never one flat
## white, grain that settles to its mean before it could shimmer, age
## that greys it steadily, grit whose far average matches its near
## grains, and an edge slope that is the true world gradient. A guard
## fails if the GLSL no longer holds the lines this mirror copies.

const SNOW_COL := Vector3(0.90, 0.92, 0.95)

## Lines of SNOW_GLSL the mirror below reproduces.
const MIRRORED := [
	"vec3 q = fract(vec3(p.xyx) * 0.1031);",
	"q += dot(q, q.yzx + 33.33);",
	"float fine = mix(snow_noise(p / 0.4), 0.5, smoothstep(0.02, 0.12, pixel_m));",
	"float mid = mix(snow_noise(p / 2.6), 0.5, smoothstep(0.3, 2.0, pixel_m));",
	"float broad = mix(snow_noise(p / 11.0 + 3.7), 0.5, smoothstep(2.0, 10.0, pixel_m));",
	"vec3 c = snow_col * (0.95 + 0.05 * mid + 0.04 * fine);",
	"c *= mix(vec3(0.90, 0.95, 1.02), vec3(1.0), smoothstep(0.25, 0.65, broad));",
	"vec3 old = vec3(0.60, 0.59, 0.56) * (0.88 + 0.16 * mid + 0.08 * fine);",
	"float a = amount * smoothstep(0.2, 0.8, mix(snow_noise(p / 1.7 + 9.1), 0.5, smoothstep(0.3, 1.5, pixel_m)) + 0.15);",
	"float r = 0.12 + 0.14 * snow_hash(id + 8.9);",
	"float grain = (1.0 - smoothstep(r - aa, r + aa, length(fract(q) - ctr))) * step(snow_hash(id), 0.24 * a);",
	"float cover = mix(0.027 * a, grain, 1.0 - smoothstep(0.004, 0.015, pixel_m));",
	"vec2 g = vec2(d * sx - b * sy, a * sy - c * sx) / det * depth_m;",
	"g *= min(1.0, 0.85 / max(len, 1e-5));",
	"const float SNOW_ROUGH = 0.72;",
]

func _init() -> void:
	var failures: Array[String] = []
	for line in MIRRORED:
		if not ClimateModel.SNOW_GLSL.contains(line):
			failures.append("SNOW_GLSL changed (update this mirror): %s" % line)
	_albedo_checks(failures)
	_grit_checks(failures)
	_edge_checks(failures)
	if failures.is_empty():
		print("SNOW LOOK OK: bright never-flat albedo, grain settles with distance, age greys, grit average holds, edge slope exact")
		quit(0)
	else:
		for f in failures:
			printerr("SNOW LOOK FAIL: ", f)
		quit(1)

# --- Mirror of SNOW_GLSL -------------------------------------------------

static func _fract(x: float) -> float:
	return x - floorf(x)

static func _ss(e0: float, e1: float, x: float) -> float:
	var t := clampf((x - e0) / (e1 - e0), 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)

static func snow_hash(p: Vector2) -> float:
	var q := Vector3(_fract(p.x * 0.1031), _fract(p.y * 0.1031), _fract(p.x * 0.1031))
	var d := q.dot(Vector3(q.y, q.z, q.x) + Vector3(33.33, 33.33, 33.33))
	q += Vector3(d, d, d)
	return _fract((q.x + q.y) * q.z)

static func snow_noise(p: Vector2) -> float:
	var i := Vector2(floorf(p.x), floorf(p.y))
	var f := p - i
	var u := Vector2(f.x * f.x * (3.0 - 2.0 * f.x), f.y * f.y * (3.0 - 2.0 * f.y))
	var a := lerpf(snow_hash(i), snow_hash(i + Vector2(1, 0)), u.x)
	var b := lerpf(snow_hash(i + Vector2(0, 1)), snow_hash(i + Vector2(1, 1)), u.x)
	return lerpf(a, b, u.y)

static func snow_albedo(p: Vector2, pixel_m: float, age: float) -> Vector3:
	var fine := lerpf(snow_noise(p / 0.4), 0.5, _ss(0.02, 0.12, pixel_m))
	var mid := lerpf(snow_noise(p / 2.6), 0.5, _ss(0.3, 2.0, pixel_m))
	var broad := lerpf(snow_noise(p / 11.0 + Vector2(3.7, 3.7)), 0.5, _ss(2.0, 10.0, pixel_m))
	var c := SNOW_COL * (0.95 + 0.05 * mid + 0.04 * fine)
	c *= Vector3(0.90, 0.95, 1.02).lerp(Vector3.ONE, _ss(0.25, 0.65, broad))
	var old := Vector3(0.60, 0.59, 0.56) * (0.88 + 0.16 * mid + 0.08 * fine)
	return c.lerp(old, clampf(age, 0.0, 1.0))

static func snow_grit(c: Vector3, p: Vector2, pixel_m: float, amount: float) -> Vector3:
	var a := amount * _ss(0.2, 0.8, lerpf(snow_noise(p / 1.7 + Vector2(9.1, 9.1)), 0.5, _ss(0.3, 1.5, pixel_m)) + 0.15)
	var q := p * 25.0
	var id := Vector2(floorf(q.x), floorf(q.y))
	var ctr := Vector2(snow_hash(id + Vector2(1.7, 1.7)), snow_hash(id + Vector2(4.3, 4.3))) * 0.6 + Vector2(0.2, 0.2)
	var r := 0.12 + 0.14 * snow_hash(id + Vector2(8.9, 8.9))
	var aa := maxf(pixel_m * 25.0, 1e-3)
	var fq := q - id
	var grain := (1.0 - _ss(r - aa, r + aa, fq.distance_to(ctr))) * (1.0 if snow_hash(id) <= 0.24 * a else 0.0)
	var cover := lerpf(0.027 * a, grain, 1.0 - _ss(0.004, 0.015, pixel_m))
	var grit := Vector3(0.40, 0.33, 0.25) * (0.8 + 0.4 * snow_hash(id + Vector2(5.3, 5.3)))
	return c.lerp(grit, clampf(cover, 0.0, 1.0))

## snow_edge's slope from screen derivatives: (sx, sy) of the cover and
## the world xz Jacobian [[a, b], [c, d]] (dFdx/dFdy of x and z).
static func edge_slope(sx: float, sy: float, a: float, b: float, c: float, d: float, depth_m: float) -> Vector2:
	var det := a * d - b * c
	if absf(det) < 1e-9:
		return Vector2.ZERO
	var g := Vector2(d * sx - b * sy, a * sy - c * sx) / det * depth_m
	return g * minf(1.0, 0.85 / maxf(g.length(), 1e-5))

static func lum(c: Vector3) -> float:
	return c.dot(Vector3(0.2126, 0.7152, 0.0722))

# --- Checks ----------------------------------------------------------------

static func _stats(values: Array[float]) -> Vector2:
	var mean := 0.0
	for v in values:
		mean += v
	mean /= float(values.size())
	var var_sum := 0.0
	for v in values:
		var_sum += (v - mean) * (v - mean)
	return Vector2(mean, sqrt(var_sum / float(values.size())))

func _albedo_checks(failures: Array[String]) -> void:
	var near: Array[float] = []
	var far: Array[float] = []
	var old: Array[float] = []
	var half: Array[float] = []
	for j in 40:
		for i in 40:
			var p := Vector2(float(i) * 0.37 + 0.11, float(j) * 0.53 + 0.29)
			near.append(lum(snow_albedo(p, 0.005, 0.0)))
			far.append(lum(snow_albedo(p * 40.0, 20.0, 0.0)))
			old.append(lum(snow_albedo(p, 0.005, 1.0)))
			half.append(lum(snow_albedo(p, 0.005, 0.5)))
	var n := _stats(near)
	var f := _stats(far)
	if n.x < 0.82 or n.x > 0.95:
		failures.append("fresh snow should be bright (lum ~0.85-0.9), got %.3f" % n.x)
	if n.y < 0.004:
		failures.append("fresh snow near by must carry grain, std %.4f" % n.y)
	if f.y > 1e-4:
		failures.append("grain must settle to its mean far off (no shimmer), std %.5f" % f.y)
	if absf(f.x - n.x) > 0.03:
		failures.append("far snow must keep the near snow's mean: %.3f vs %.3f" % [f.x, n.x])
	var o := _stats(old)
	var h := _stats(half)
	if o.x < 0.5 or o.x > 0.68:
		failures.append("fully aged snow should be a grey buff (0.5-0.68), got %.3f" % o.x)
	if not (o.x < h.x and h.x < n.x):
		failures.append("age must grey snow steadily: %.3f, %.3f, %.3f" % [n.x, h.x, o.x])

func _grit_checks(failures: Array[String]) -> void:
	var base := Vector3(0.85, 0.86, 0.88)
	var none := snow_grit(base, Vector2(3.3, 7.1), 0.002, 0.0)
	if none.distance_to(base) > 1e-6:
		failures.append("no grit should leave the snow untouched")
	# Over a broad area the grains near by average to the far tint.
	var near_sum := 0.0
	var far_sum := 0.0
	var count := 0
	var grains := 0
	for j in 200:
		for i in 200:
			var p := Vector2(float(i) * 0.013 + 0.0021, float(j) * 0.017 + 0.0037)
			var cn := snow_grit(base, p, 0.002, 0.6)
			near_sum += lum(cn)
			far_sum += lum(snow_grit(base, p, 0.05, 0.6))
			if lum(cn) < lum(base) - 0.05:
				grains += 1
			count += 1
	var near_mean := near_sum / float(count)
	var far_mean := far_sum / float(count)
	if grains == 0:
		failures.append("grit should show distinct grains near by")
	if absf(near_mean - far_mean) > 0.012:
		failures.append("grit's far tint must match its near grains on average: %.4f vs %.4f" % [near_mean, far_mean])
	if lum(base) - far_mean > 0.05:
		failures.append("grit must stay sparse, darkening %.3f" % (lum(base) - far_mean))

func _edge_checks(failures: Array[String]) -> void:
	# Cover rising 2 per metre along world (0.6, 0.8); the screen axes
	# rotated and scaled against the world, as on a sloped view.
	var grad := Vector2(0.6, 0.8) * 2.0
	var jx := Vector2(0.004, 0.0015)   # world xz per screen pixel in x
	var jy := Vector2(-0.001, 0.006)   # ... in y
	var sx := grad.dot(jx)
	var sy := grad.dot(jy)
	var g := edge_slope(sx, sy, jx.x, jx.y, jy.x, jy.y, 0.05)
	if g.distance_to(grad * 0.05) > 1e-5:
		failures.append("snow_edge must recover the world slope: %s vs %s" % [g, grad * 0.05])
	var flat := edge_slope(0.0, 0.0, jx.x, jx.y, jy.x, jy.y, 0.05)
	if flat.length() > 1e-9:
		failures.append("flat cover has no lip")
	var steep := edge_slope(sx * 1000.0, sy * 1000.0, jx.x, jx.y, jy.x, jy.y, 0.05)
	if steep.length() > 0.85 + 1e-4:
		failures.append("the lip must stay a lip (slope <= 0.85), got %.3f" % steep.length())
	if edge_slope(1.0, 1.0, 0.0, 0.0, 0.0, 0.0, 0.05) != Vector2.ZERO:
		failures.append("a degenerate footprint must give no slope")
