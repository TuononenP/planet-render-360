class_name GrassCards
extends RefCounted

## The pictures and card meshes GroundCover scatters: grass tufts, meadow
## seed heads, wildflower clumps and low shrubs. Painted once per kind,
## season and dryness at 256 px. Blades curve and taper, and each takes its
## own hue (yellow-green to blue-green, with a share of dead straw that
## grows with the season and a dry climate). Bases are dark and tips are
## light, with a pale midrib. Edges carry fractional alpha, so alpha to
## coverage smooths them under MSAA instead of letting them shimmer.
##
## Texture values are tints around the instance colour (GroundCover roots
## that in the ground photo): green blades sit at the old card's value and
## straw lifts red against green so it reads olive-tan on any lawn.

const N := 256
## Card width and height (m) per kind before instance scaling.
const SIZE := {"tuft": Vector2(0.7, 0.45), "seedhead": Vector2(0.6, 0.75),
	"flower": Vector2(0.6, 0.5), "shrub": Vector2(1.4, 1.1)}
## Dead-straw share of blades by season (spring, summer, autumn, winter).
const STRAW := [0.04, 0.07, 0.24, 0.34]
const DRY_STRAW := 0.12

## Three vertical quads at 60° around the root, base on the ground, tops
## flared outward so a tuft reads from above. Normals lean up a little.
static func card(kind: String) -> ArrayMesh:
	var sz: Vector2 = SIZE.get(kind, SIZE["tuft"])
	var w := sz.x
	var h := sz.y
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var uvs := PackedVector2Array()
	var idx := PackedInt32Array()
	for q in 3:
		var a := float(q) * PI / 3.0
		var dx := Vector3(cos(a), 0.0, sin(a)) * w * 0.5
		var side := Vector3(-sin(a), 0.0, cos(a))
		var nrm := (side + Vector3.UP * 0.5).normalized()
		# Alternate the flare side so the three tops spread like a tuft.
		var flare := side * h * (0.3 if q % 2 == 0 else -0.3)
		var k := verts.size()
		verts.append_array([-dx, dx, dx + Vector3(0, h, 0) + flare, -dx + Vector3(0, h, 0) + flare])
		norms.append_array([nrm, nrm, nrm, nrm])
		uvs.append_array([Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)])
		idx.append_array([k, k + 1, k + 2, k, k + 2, k + 3])
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = norms
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = idx
	var m := ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return m

## Share of dead blades for a season, more in a dry climate.
static func straw_share(season: int, dry: bool) -> float:
	return float(STRAW[clampi(season, 0, 3)]) + (DRY_STRAW if dry else 0.0)

## The card picture for `kind` (RGBA8 with mipmaps).
static func paint(kind: String, season: int, dry: bool) -> Image:
	var img := Image.create(N, N, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.3, 0.4, 0.2, 0.0))
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(kind) + season * 7 + (3 if dry else 0)
	if kind == "shrub":
		_shrub(img, rng)
	else:
		var straw := straw_share(season, dry)
		var blades := {"tuft": 64, "seedhead": 40, "flower": 40}.get(kind, 64) as int
		for b in blades:
			_blade(img, rng, rng.randf() < straw, 0.45 if kind == "tuft" else 0.55)
		if kind == "seedhead":
			for k in 7:
				_seed_stem(img, rng, season)
		elif kind == "flower":
			var palette := [Color(1.0, 0.92, 0.3), Color(1.0, 1.0, 0.95), Color(0.75, 0.45, 0.95),
				Color(0.95, 0.35, 0.35)]
			for k in 9:
				var c: Color = palette[rng.randi() % palette.size()]
				_disc(img, rng.randf_range(48.0, 208.0), rng.randf_range(16.0, 100.0), 8.0, c)
	img.generate_mipmaps()
	return img

## One curved, tapered blade from the base; `min_len` is its shortest
## length as a share of the card.
static func _blade(img: Image, rng: RandomNumberGenerator, dead: bool, min_len: float) -> void:
	var bx := 128.0 + rng.randfn(0.0, 30.0)
	var lean := rng.randf_range(-0.9, 0.9)
	var ln := rng.randf_range(min_len, 0.98) * float(N - 4)
	var base_w := rng.randf_range(3.0, 5.0)
	var v := rng.randf_range(0.7, 1.05)
	# Hue: yellow-green to blue-green, or straw for a dead blade.
	var hue := rng.randf()
	var tint := Color(0.92, 1.0, 0.5).lerp(Color(0.74, 1.0, 0.68), hue)
	if dead:
		tint = Color(1.0, 0.8, 0.58)
	var steps := int(ln)
	for t in steps:
		var f := float(t) / ln
		var y := float(N - 1) - float(t)
		# Curve: the lean grows with height, so tips arc over.
		var x := bx + lean * float(t) * f * 0.9
		var wd := maxf(base_w * (1.0 - f * f), 0.7)
		var shade := v * (0.6 + 0.48 * pow(f, 0.7))
		for px in range(int(floor(x - wd - 1.0)), int(ceil(x + wd + 1.0)) + 1):
			if px < 0 or px >= N or y < 0.0:
				continue
			var d := absf(float(px) - x)
			var a := clampf(wd - d + 0.5, 0.0, 1.0)
			if a <= 0.0:
				continue
			# Pale midrib, darker edges.
			var rib := 1.0 + 0.1 * (1.0 - smoothstep(0.0, maxf(wd * 0.5, 0.6), d)) - 0.1 * d / maxf(wd, 0.7)
			var s := clampf(shade * rib, 0.0, 1.0)
			_over(img, px, int(y), Color(tint.r * s, tint.g * s, tint.b * s), a)

## A thin stem topped with a nodding seed panicle (wild meadows).
static func _seed_stem(img: Image, rng: RandomNumberGenerator, season: int) -> void:
	var bx := 128.0 + rng.randfn(0.0, 26.0)
	var lean := rng.randf_range(-0.5, 0.5)
	var ln := rng.randf_range(0.7, 0.97) * float(N - 4)
	var top := Vector2.ZERO
	for t in int(ln):
		var f := float(t) / ln
		var y := float(N - 1) - float(t)
		var x := bx + lean * float(t) * f
		top = Vector2(x, y)
		var s := 0.7 + 0.3 * f
		_over(img, int(round(x)), int(y), Color(0.95 * s, 0.9 * s, 0.6 * s), 1.0)
	# Summer heads are green-gold, autumn heads bleached straw.
	var head := Color(0.95, 0.88, 0.55) if season >= LocationData.Season.AUTUMN else Color(0.9, 0.95, 0.6)
	for k in 14:
		var u := rng.randf()
		var p := top + Vector2(lean * 10.0 * u + rng.randf_range(-3.0, 3.0), u * 34.0)
		_disc(img, p.x, p.y, rng.randf_range(1.6, 2.8), head * rng.randf_range(0.85, 1.05))

## A rounded leafy mass.
static func _shrub(img: Image, rng: RandomNumberGenerator) -> void:
	for k in 900:
		var a := rng.randf() * TAU
		var r := sqrt(rng.randf()) * 0.46
		var cx := 128.0 + cos(a) * r * 256.0
		var cy := 148.0 + sin(a) * r * 200.0 * 0.9
		var v := 0.55 + 0.45 * rng.randf() * (1.0 - (cy / 256.0) * 0.4)
		_disc(img, cx, cy, 5.0 + rng.randf() * 6.0, Color(v * 0.9, v, v * 0.75, 1.0))

## Paints colour `c` over pixel (x, y) at coverage `a`.
static func _over(img: Image, x: int, y: int, c: Color, a: float) -> void:
	if x < 0 or y < 0 or x >= img.get_width() or y >= img.get_height():
		return
	var o := img.get_pixel(x, y)
	var rgb := Color(c.r, c.g, c.b).lerp(Color(o.r, o.g, o.b), (1.0 - a) * o.a)
	img.set_pixel(x, y, Color(rgb.r, rgb.g, rgb.b, maxf(o.a, a)))

## A soft-edged disc.
static func _disc(img: Image, cx: float, cy: float, r: float, c: Color) -> void:
	for y in range(int(cy - r - 1.0), int(cy + r + 1.0) + 1):
		for x in range(int(cx - r - 1.0), int(cx + r + 1.0) + 1):
			var a := clampf(r - Vector2(x - cx, y - cy).length() + 0.5, 0.0, 1.0)
			if a > 0.0:
				_over(img, x, y, Color(c.r, c.g, c.b), a)
