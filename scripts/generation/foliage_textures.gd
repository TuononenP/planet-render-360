class_name FoliageTextures
extends RefCounted

## Procedural foliage + bark textures for the T5.1 tree species
## (TreeMeshLibrary). Leaf atlases are painted leaf by leaf (ovate,
## lanceolate, needle sprays, pine tufts, palm leaflets, scale foliage,
## bare twigs) with real alpha gaps, so alpha-tested cards read as
## clumpy foliage instead of a speckled disc. Bark sets are tileable
## albedo + normal (FastNoiseLite seamless noise, native and fast).
##
## Own work, no third-party pixels: tools/gen_foliage_textures.gd paints
## every set at full resolution into assets/textures/foliage/*.png (CC0,
## docs/data-source-register.md). At runtime the PNG is loaded; a
## missing file falls back to painting the same set at half resolution
## (identical layout, softer) so the build never depends on the asset.
##
## Colour convention: leaf atlases are near-neutral luminance (tinted
## per species/season by the material), bark sets carry real colour.

const DIR := "res://assets/textures/foliage/"
const LEAF_KINDS: Array[String] = ["broad", "birch", "olive", "needle",
	"pine", "palm", "cypress", "twigs"]
const BARK_KINDS: Array[String] = ["plane", "furrowed", "pine", "birch",
	"spruce", "palm"]
const LEAF_SIZE := 1024
const BARK_SIZE := Vector2i(512, 1024)

static var _textures: Dictionary = {}

## Leaf atlas texture (RGBA, coverage-preserving mipmaps).
static func leaf(kind: String) -> Texture2D:
	return _cached("leaf_" + kind, func() -> Image: return paint_leaf(kind, 0.5), true)

## Bark albedo / normal textures (tileable, mipmapped).
static func bark_albedo(kind: String) -> Texture2D:
	return _cached("bark_" + kind, func() -> Image: return paint_bark(kind, 0.5)[0], false)

static func bark_normal(kind: String) -> Texture2D:
	return _cached("bark_" + kind + "_n", func() -> Image: return paint_bark(kind, 0.5)[1], false)

static func _cached(name: String, painter: Callable, alpha_cut: bool) -> Texture2D:
	if _textures.has(name):
		return _textures[name] as Texture2D
	var img: Image = null
	var path := DIR + name + ".png"
	if FileAccess.file_exists(path):
		img = Image.load_from_file(path)
	if img == null or img.is_empty():
		img = painter.call()
	if img.get_format() != Image.FORMAT_RGBA8:
		img.convert(Image.FORMAT_RGBA8)
	img.generate_mipmaps()
	if alpha_cut:
		preserve_coverage(img, 0.5)
	var tex := ImageTexture.create_from_image(img)
	_textures[name] = tex
	return tex

## Alpha-tested foliage thins out with distance because box-filtered
## mip alpha drops below the cut. Rescale each mip's alpha so the
## fraction of texels passing `cut` matches the base level (histogram
## pick, one pass per level — cheap enough for runtime).
static func preserve_coverage(img: Image, cut: float) -> void:
	if not img.has_mipmaps():
		return
	var data := img.get_data()
	var w := img.get_width()
	var h := img.get_height()
	var target := _coverage(data, 0, w * h, cut)
	var levels := img.get_mipmap_count()
	for lv in range(1, levels + 1):
		var off := img.get_mipmap_offset(lv)
		var lw := maxi(w >> lv, 1)
		var lh := maxi(h >> lv, 1)
		var n := lw * lh
		var hist := PackedInt32Array()
		hist.resize(256)
		for i in n:
			hist[data[off + i * 4 + 3]] += 1
		# Smallest alpha a_t such that count(alpha >= a_t) ~= target * n.
		var want := int(target * float(n))
		var acc := 0
		var a_t := 255
		while a_t > 1:
			acc += hist[a_t]
			if acc >= want:
				break
			a_t -= 1
		var scale := (cut * 255.0) / maxf(float(a_t), 1.0)
		if scale <= 1.0:
			continue
		for i in n:
			var ai := off + i * 4 + 3
			data[ai] = mini(int(float(data[ai]) * scale), 255)
	img.set_data(w, h, true, Image.FORMAT_RGBA8, data)

static func _coverage(data: PackedByteArray, off: int, n: int, cut: float) -> float:
	var c := 0
	var t := int(cut * 255.0)
	for i in n:
		if data[off + i * 4 + 3] >= t:
			c += 1
	return float(c) / float(maxi(n, 1))

# --- Leaf atlas painting ------------------------------------------------

## Tiny RGBA float canvas; painting writes opaque texels (alpha edges
## come from the supersampled downscale at the end).
class Canvas:
	var w: int
	var h: int
	var px: PackedFloat32Array
	func _init(width: int, height: int, bg: Color) -> void:
		w = width
		h = height
		px.resize(w * h * 4)
		for i in w * h:
			px[i * 4] = bg.r
			px[i * 4 + 1] = bg.g
			px[i * 4 + 2] = bg.b
			px[i * 4 + 3] = 0.0
	func put(x: int, y: int, c: Color) -> void:
		if x < 0 or y < 0 or x >= w or y >= h:
			return
		var i := (y * w + x) * 4
		px[i] = c.r
		px[i + 1] = c.g
		px[i + 2] = c.b
		px[i + 3] = 1.0
	func to_image(out_w: int, out_h: int) -> Image:
		var bytes := PackedByteArray()
		bytes.resize(w * h * 4)
		for i in px.size():
			bytes[i] = clampi(int(px[i] * 255.0), 0, 255)
		var img := Image.create_from_data(w, h, false, Image.FORMAT_RGBA8, bytes)
		if out_w != w or out_h != h:
			img.resize(out_w, out_h, Image.INTERPOLATE_LANCZOS)
		return img

## One leaf blade: base at (bx, by), pointing along `ang`, length `ln`,
## half-width `hw`. shape: 0 ovate, 1 lanceolate, 2 needle-thin.
static func _blade(cv: Canvas, bx: float, by: float, ang: float, ln: float,
		hw: float, lum: float, hue: float, shape: int) -> void:
	var d := Vector2(cos(ang), sin(ang))
	var n := Vector2(-d.y, d.x)
	var ex := bx + d.x * ln
	var ey := by + d.y * ln
	var x0 := int(floor(minf(bx, ex) - hw))
	var x1 := int(ceil(maxf(bx, ex) + hw))
	var y0 := int(floor(minf(by, ey) - hw))
	var y1 := int(ceil(maxf(by, ey) + hw))
	for y in range(maxi(y0, 0), mini(y1, cv.h - 1) + 1):
		for x in range(maxi(x0, 0), mini(x1, cv.w - 1) + 1):
			var p := Vector2(float(x) - bx, float(y) - by)
			var u := p.dot(d) / ln
			if u < 0.0 or u > 1.0:
				continue
			var prof: float
			match shape:
				0:
					prof = pow(sin(PI * clampf(u * 0.92 + 0.04, 0.0, 1.0)), 0.75) * (1.0 - 0.25 * u)
				1:
					prof = pow(sin(PI * u), 1.1)
				_:
					prof = 1.0 - u * 0.6
			var v := p.dot(n) / maxf(hw * prof, 0.01)
			if absf(v) > 1.0:
				continue
			# Folded blade: one half catches more light; midrib + rim darker.
			var l := lum * (0.88 + 0.12 * signf(v)) * (1.0 - 0.18 * absf(v) * absf(v))
			if absf(v) < 0.09 and shape != 2:
				l *= 0.82
			cv.put(x, y, Color(l * (0.9 + hue), l, l * (0.78 - hue)))

## Thick stroke for twigs/rachis/needles.
static func _stroke(cv: Canvas, a: Vector2, b: Vector2, wa: float, wb: float,
		c: Color) -> void:
	var len := a.distance_to(b)
	var steps := maxi(int(len * 1.5), 1)
	for s in steps + 1:
		var t := float(s) / float(steps)
		var p := a.lerp(b, t)
		var rad := lerpf(wa, wb, t) * 0.5
		var ri := int(ceil(rad))
		for dy in range(-ri, ri + 1):
			for dx in range(-ri, ri + 1):
				if dx * dx + dy * dy <= rad * rad + 0.25:
					cv.put(int(p.x) + dx, int(p.y) + dy, c)

## Paints one leaf atlas. `res` 1.0 = full LEAF_SIZE (tool), 0.5 runtime.
static func paint_leaf(kind: String, res: float = 1.0) -> Image:
	var out := int(float(LEAF_SIZE) * res)
	var ss := out * 2  # supersample 2x, Lanczos down for soft alpha edges
	var s := float(ss) / 1024.0  # layout constants below are in 1024-space
	var cv := Canvas.new(ss, ss, Color(0.55, 0.55, 0.5))
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(kind) & 0x7fffffff
	match kind:
		"broad", "birch", "olive":
			_paint_clumps(cv, rng, s, kind)
		"needle":
			_paint_needle_spray(cv, rng, s)
		"pine":
			_paint_pine_tufts(cv, rng, s)
		"palm":
			_paint_palm_frond(cv, rng, s)
		"cypress":
			_paint_scale_foliage(cv, rng, s)
		"twigs":
			_paint_twigs(cv, rng, s)
	return cv.to_image(out, out)

## Broadleaf cluster card: 6-8 sub-clumps on twigs from the lower
## centre, leaves alternate along each twig; open gaps between clumps.
static func _paint_clumps(cv: Canvas, rng: RandomNumberGenerator, s: float, kind: String) -> void:
	var twig := Color(0.36, 0.30, 0.24)
	var leaf_len := 40.0 if kind == "broad" else (30.0 if kind == "birch" else 48.0)
	var leaf_hw := 13.0 if kind == "broad" else (10.0 if kind == "birch" else 6.0)
	var shape := 0 if kind != "olive" else 1
	var clumps := 11 if kind != "birch" else 13
	var root := Vector2(512, 980) * s
	for c in clumps:
		# Clump centres fill a lumpy disc; short stems point at the root.
		var a := rng.randf_range(0.0, TAU)
		var rr := sqrt(rng.randf()) * 300.0
		var centre := Vector2(512, 480) + Vector2(cos(a), sin(a) * 0.9) * rr
		var tip := centre * s
		_stroke(cv, tip.lerp(root, 0.35), tip, 6.0 * s, 2.5 * s, twig)
		var cr := rng.randf_range(115.0, 165.0) * s
		var leaves := int(rng.randf_range(95.0, 125.0) * (1.4 if kind == "olive" else 1.0))
		for i in leaves:
			# Leaves on short shoots radiating out of the clump centre.
			var ang := rng.randf_range(0.0, TAU)
			var dist := sqrt(rng.randf()) * cr
			var base := tip + Vector2(cos(ang), sin(ang)) * dist * 0.85
			var la := ang + rng.randf_range(-0.6, 0.6)
			if kind == "birch":
				la = lerpf(la, PI * 0.5, 0.45)  # pendulous
			# Inner leaves sit in shade.
			var lum := rng.randf_range(0.62, 1.0) * lerpf(0.78, 1.0, dist / cr)
			_blade(cv, base.x, base.y, la, leaf_len * s * rng.randf_range(0.8, 1.2),
				leaf_hw * s * rng.randf_range(0.85, 1.15), lum,
				rng.randf_range(-0.05, 0.05), shape)

## Spruce/fir branch plume: u = along the branch (trunk at left), side
## shoots sweep forward and droop, each densely set with short needles.
static func _paint_needle_spray(cv: Canvas, rng: RandomNumberGenerator, s: float) -> void:
	var stem := Color(0.33, 0.27, 0.21)
	var a := Vector2(10, 512) * s
	var b := Vector2(1010, 560) * s
	_stroke(cv, a, b, 9.0 * s, 3.0 * s, stem)
	var x := 40.0
	while x < 980.0:
		var t := x / 1000.0
		var p := Vector2(x, lerpf(512.0, 560.0, t)) * s
		for side in [-1.0, 1.0]:
			var ln := (470.0 * (1.0 - 0.6 * t) * rng.randf_range(0.8, 1.0)) * s
			var ang: float = side * rng.randf_range(0.75, 1.0) + rng.randf_range(-0.1, 0.25)
			var dir := Vector2(cos(ang), sin(ang))
			var tip := p + dir * ln
			_stroke(cv, p, tip, 4.0 * s, 1.5 * s, stem)
			# Needles along the shoot, both sides, angled forward.
			var k := 0.0
			while k < 1.0:
				var q := p.lerp(tip, k)
				for ns in [-1.0, 1.0]:
					var na: float = ang + ns * rng.randf_range(0.7, 1.1)
					var nl := rng.randf_range(24.0, 34.0) * s * (1.0 - 0.4 * k)
					var lum := rng.randf_range(0.55, 0.95)
					_stroke(cv, q, q + Vector2(cos(na), sin(na)) * nl, 2.6 * s, 1.4 * s,
						Color(lum * 0.95, lum, lum * 0.9))
				k += 5.0 * s / maxf(ln, 1.0)
		x += rng.randf_range(30.0, 40.0)

## Pine tufts: brushes of long paired needles at shoot tips.
static func _paint_pine_tufts(cv: Canvas, rng: RandomNumberGenerator, s: float) -> void:
	var stem := Color(0.45, 0.32, 0.22)
	var root := Vector2(512, 1000) * s
	for t in 17:
		var ca := rng.randf_range(0.0, TAU)
		var c := (Vector2(512, 470) + Vector2(cos(ca), sin(ca)) * sqrt(rng.randf()) * 330.0) * s
		_stroke(cv, root.lerp(c, 0.55), c, 8.0 * s, 4.0 * s, stem)
		var up := (c - root).normalized()
		var base_ang := atan2(up.y, up.x)
		for n in 130:
			var ang := base_ang + rng.randf_range(-1.6, 1.6)
			var ln := rng.randf_range(70.0, 125.0) * s
			var o := c + up * rng.randf_range(-30.0, 10.0) * s
			var lum := rng.randf_range(0.55, 1.0)
			_stroke(cv, o, o + Vector2(cos(ang), sin(ang)) * ln, 3.0 * s, 1.6 * s,
				Color(lum * 0.92, lum, lum * 0.86))

## Palm frond (u = along the rachis): long leaflets both sides.
static func _paint_palm_frond(cv: Canvas, rng: RandomNumberGenerator, s: float) -> void:
	var rachis := Color(0.62, 0.58, 0.42)
	_stroke(cv, Vector2(0, 512) * s, Vector2(1020, 512) * s, 12.0 * s, 4.0 * s, rachis)
	var x := 60.0
	while x < 1000.0:
		var t := x / 1000.0
		var env := pow(sin(PI * clampf(t * 0.95 + 0.05, 0.0, 1.0)), 0.6)
		for side in [-1.0, 1.0]:
			var ln := 470.0 * env * rng.randf_range(0.85, 1.0)
			var ang: float = side * rng.randf_range(0.55, 0.75)
			_blade(cv, x * s, 512.0 * s, ang, ln * s, 15.0 * s,
				rng.randf_range(0.65, 1.0), rng.randf_range(-0.03, 0.05), 1)
		x += rng.randf_range(13.0, 17.0)

## Cypress/thuja scale foliage: dense overlapping flat sprays with a
## ragged outline and a few see-through holes.
static func _paint_scale_foliage(cv: Canvas, rng: RandomNumberGenerator, s: float) -> void:
	for i in 2600:
		var ang := rng.randf_range(0.0, TAU)
		var r := sqrt(rng.randf()) * 470.0
		var c := Vector2(512, 512) + Vector2(cos(ang), sin(ang)) * r
		if r > 380.0 and rng.randf() < 0.5:
			continue
		var lum := rng.randf_range(0.5, 1.0) * lerpf(1.0, 0.8, 1.0 - r / 470.0)
		_blade(cv, c.x * s, c.y * s, rng.randf_range(-PI, PI) * 0.4 - PI * 0.5,
			rng.randf_range(28.0, 44.0) * s, rng.randf_range(7.0, 11.0) * s, lum,
			rng.randf_range(-0.03, 0.04), 2)

## Bare winter twigs: recursive forks from the lower centre.
static func _paint_twigs(cv: Canvas, rng: RandomNumberGenerator, s: float) -> void:
	_twig_fork(cv, rng, Vector2(512, 1010) * s, -PI * 0.5, 330.0 * s, 16.0 * s, 0)

static func _twig_fork(cv: Canvas, rng: RandomNumberGenerator, p: Vector2, ang: float,
		ln: float, wd: float, depth: int) -> void:
	if depth > 7 or ln < 6.0:
		return
	var mid := p + Vector2(cos(ang), sin(ang)) * ln * 0.5 \
		+ Vector2(rng.randf_range(-1, 1), rng.randf_range(-1, 1)) * ln * 0.08
	var end := mid + Vector2(cos(ang), sin(ang)) * ln * 0.5
	var lum := rng.randf_range(0.35, 0.5)
	var c := Color(lum * 1.1, lum, lum * 0.85)
	_stroke(cv, p, mid, wd, wd * 0.85, c)
	_stroke(cv, mid, end, wd * 0.85, wd * 0.7, c)
	var kids := 2 if depth < 2 else rng.randi_range(2, 3)
	for k in kids:
		var na := ang + rng.randf_range(-0.75, 0.75)
		_twig_fork(cv, rng, end if k == 0 else mid.lerp(end, rng.randf_range(0.3, 0.9)),
			na, ln * rng.randf_range(0.62, 0.78), maxf(wd * 0.68, 2.0), depth + 1)

# --- Bark ----------------------------------------------------------------

## [albedo, normal] tileable bark set; `res` 1.0 = BARK_SIZE.
static func paint_bark(kind: String, res: float = 1.0) -> Array:
	var w := int(float(BARK_SIZE.x) * res)
	var h := int(float(BARK_SIZE.y) * res)
	var n1 := FastNoiseLite.new()
	n1.seed = hash(kind) & 0xffff
	n1.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	n1.fractal_octaves = 4
	var n2 := FastNoiseLite.new()
	n2.seed = (hash(kind) >> 8) & 0xffff
	n2.noise_type = FastNoiseLite.TYPE_CELLULAR
	n2.cellular_return_type = FastNoiseLite.RETURN_DISTANCE2_SUB
	match kind:
		"furrowed", "spruce":
			n1.frequency = 0.004 / res
			n2.frequency = (0.03 if kind == "furrowed" else 0.06) / res
		"plane":
			n1.frequency = 0.012 / res
			n2.frequency = 0.012 / res
		"pine":
			n1.frequency = 0.008 / res
			n2.frequency = 0.022 / res
		_:
			n1.frequency = 0.01 / res
			n2.frequency = 0.03 / res
	var a := n1.get_seamless_image(w, h)
	var c := n2.get_seamless_image(w, h)
	var alb := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var bump := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(kind)
	for y in h:
		for x in w:
			var f := a.get_pixel(x, y).r
			var cell := c.get_pixel(x, y).r
			var col: Color
			var ht: float
			var u := float(x) / float(w)
			var v := float(y) / float(h)
			match kind:
				"furrowed":
					# Vertical ridges broken into plates; deep dark furrows.
					var ridge := absf(sin((u * 9.0 + f * 1.6) * TAU * 0.5))
					ht = clampf(ridge * 1.2 - 0.15 + cell * 0.35, 0.0, 1.0)
					col = Color(0.30, 0.26, 0.22).lerp(Color(0.52, 0.48, 0.42), ht)
				"spruce":
					ht = clampf(cell * 1.4 + f * 0.3, 0.0, 1.0)
					col = Color(0.26, 0.20, 0.16).lerp(Color(0.50, 0.40, 0.33), ht)
				"pine":
					var plate := clampf(cell * 1.6, 0.0, 1.0)
					ht = plate
					col = Color(0.28, 0.20, 0.15).lerp(Color(0.68, 0.42, 0.26), plate * (0.7 + f * 0.5))
				"plane":
					# Camouflage: cream, olive and grey patches.
					var pick := f + cell * 0.25
					if pick > 0.62:
						col = Color(0.80, 0.77, 0.62)
					elif pick > 0.45:
						col = Color(0.62, 0.62, 0.50)
					else:
						col = Color(0.48, 0.47, 0.40)
					ht = pick
				"birch":
					col = Color(0.86, 0.85, 0.81).lerp(Color(0.70, 0.69, 0.66), f)
					ht = 0.8
					# Horizontal lenticels + dark scars.
					var band := absf(sin(v * 260.0 + f * 9.0))
					if band > 0.985 and cell > 0.35:
						col = Color(0.18, 0.16, 0.15)
						ht = 0.2
					elif f > 0.78:
						col = Color(0.14, 0.13, 0.12)
						ht = 0.35
				"palm":
					var ring := absf(sin(v * 70.0 * PI + f * 2.0))
					ht = clampf(pow(ring, 3.0) * 0.8 + cell * 0.2, 0.0, 1.0)
					col = Color(0.36, 0.31, 0.24).lerp(Color(0.60, 0.53, 0.42), ht)
				_:
					ht = f
					col = Color(0.4, 0.33, 0.26)
			col = col * (0.9 + 0.2 * f)
			col.a = 1.0
			alb.set_pixel(x, y, col)
			bump.set_pixel(x, y, Color(ht, ht, ht, 1.0))
	bump.bump_map_to_normal_map(6.0 if kind != "birch" else 2.0)
	return [alb, bump]
