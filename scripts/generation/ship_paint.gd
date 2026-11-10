class_name ShipPaint
extends RefCounted

## Weathered steel paint for large ships (liners, ferries, passenger and
## cargo ships). Yachts keep VesselMaterials' glossy gelcoat.
##
## hull(): one texture spans the whole hull. HullLoft gives the hull sides
## (x, y) metre UVs (y = 0 at the waterline); uv1_scale / uv1_offset map
## them to u = stern 0 .. bow 1 and v = TOP_M above the water (row 0)
## down to BELOW_M under it, so features land at true heights:
## - albedo: a near-white multiplier (plate mottling, seam shadows), so a
##   texture serves every hull colour of that length;
## - detail (MIX by alpha): waterline grime, rust weeping from the hawse
##   pipes and mooring chocks, overboard discharge stains, fender scuffs
##   and white draught marks, in their own colours;
## - normal: strake seams, staggered butt welds and the dished plating
##   between frames ("hungry horse") that catches low sun.
## enamel(): matte marine enamel for superstructures (no clearcoat).
const TOP_M := 24.0
const BELOW_M := 4.0
const TEX_W := 2048
const TEX_H := 192
## Strake height, plate length between butt welds and frame spacing (m).
const PLATE_M := 2.5
const BUTT_M := 10.0
const FRAME_M := 0.7
## Superstructure streak tile (m).
const ENAMEL_TILE_M := 8.0
const GRIME := Color(0.17, 0.18, 0.12)
const RUST := Color(0.40, 0.19, 0.08)
const STAIN := Color(0.30, 0.27, 0.22)
static var _cache := {}
static var _mutex := Mutex.new()

static func _lookup(key: String) -> Variant:
	_mutex.lock()
	var hit: Variant = _cache.get(key)
	_mutex.unlock()
	return hit

## Stores `value` unless another thread won the race; returns the winner.
static func _store(key: String, value: Variant) -> Variant:
	_mutex.lock()
	if not _cache.has(key):
		_cache[key] = value
	var out: Variant = _cache[key]
	_mutex.unlock()
	return out

## Hull topsides in `colour` for a hull `length` m long whose sheer stands
## `freeboard` m above the water.
static func hull(colour: Color, length: float, freeboard: float, maps: bool = true) -> StandardMaterial3D:
	var key := "hull|%s|%d|%d|%d" % [colour.to_html(false), roundi(length), roundi(freeboard), int(maps)]
	var hit: Variant = _lookup(key)
	if hit != null:
		return hit
	var texs := textures(length, freeboard, maps)
	var m := StandardMaterial3D.new()
	m.albedo_color = colour
	m.albedo_texture = texs["albedo"]
	m.roughness = 0.52
	m.metallic = 0.06
	m.uv1_scale = Vector3(1.0 / maxf(length, 1.0), -1.0 / (TOP_M + BELOW_M), 1.0)
	m.uv1_offset = Vector3(0.5, TOP_M / (TOP_M + BELOW_M), 0.0)
	m.detail_enabled = true
	m.detail_blend_mode = BaseMaterial3D.BLEND_MODE_MIX
	m.detail_albedo = texs["detail"]
	if maps:
		m.normal_enabled = true
		m.normal_texture = texs["normal"]
		m.normal_scale = 0.7
	return _store(key, m)

## Painted steel superstructure: matte enamel with faint weeping streaks.
## Marked for snow like the gelcoat white it replaces.
static func enamel(colour: Color, maps: bool = true) -> StandardMaterial3D:
	var key := "enamel|%s|%d" % [colour.to_html(false), int(maps)]
	var hit: Variant = _lookup(key)
	if hit != null:
		return hit
	var m := StandardMaterial3D.new()
	m.albedo_color = colour
	m.roughness = 0.46
	m.metallic = 0.0
	if maps:
		m.albedo_texture = _streaks()
		m.uv1_scale = Vector3.ONE / ENAMEL_TILE_M
	RoofVariety.mark(m)
	return _store(key, m)

## Corrugated container steel in `colour`: vertical ribs every 0.28 m on
## box faces (metre UVs, u along the face), a little rust and dirt.
static func corrugated(colour: Color, maps: bool = true) -> StandardMaterial3D:
	var key := "corrugated|%s|%d" % [colour.to_html(false), int(maps)]
	var hit: Variant = _lookup(key)
	if hit != null:
		return hit
	var m := StandardMaterial3D.new()
	m.albedo_color = colour
	m.roughness = 0.62
	m.metallic = 0.05
	m.albedo_texture = _ribs()["albedo"]
	m.uv1_scale = Vector3(1.0 / 1.12, 1.0 / 2.6, 1.0)
	if maps:
		m.normal_enabled = true
		m.normal_texture = _ribs()["normal"]
		m.normal_scale = 0.8
	return _store(key, m)

## One 1.12 m x 2.6 m tile of corrugation: four ribs, a dirty foot.
static func _ribs() -> Dictionary:
	var hit: Variant = _lookup("ribs")
	if hit != null:
		return hit
	var w := 64
	var h := 128
	var alb := Image.create(w, h, false, Image.FORMAT_RGB8)
	var bump := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for x in w:
		var rib := 0.5 + 0.5 * sin(TAU * 4.0 * float(x) / float(w))
		for y in h:
			var foot := clampf(float(y - h * 3 / 4) / float(h / 4), 0.0, 1.0)
			var c := (0.9 + 0.1 * rib) * (1.0 - 0.18 * foot)
			alb.set_pixel(x, y, Color(c, c * 0.98, c * 0.96))
			bump.set_pixel(x, y, Color(rib, rib, rib))
	alb.generate_mipmaps()
	bump.bump_map_to_normal_map(4.0)
	bump.generate_mipmaps(true)
	return _store("ribs", {"albedo": ImageTexture.create_from_image(alb),
		"normal": ImageTexture.create_from_image(bump)})

## Re-points a large ship's Hull, Boot and White keys (after
## VesselMaterials.register) at weathered steel and matte enamel. The hull
## colour comes from the material the caller painted.
static func dress(lm: LandmarkMesh, hull_mat: Material, length: float, freeboard: float, maps: bool,
		boot: Color = Color("#a3281f"), white: Color = Color("#ebe9e2")) -> void:
	var colour := Color("#2d3b4a")
	if hull_mat is StandardMaterial3D:
		colour = (hull_mat as StandardMaterial3D).albedo_color
	lm.use("Hull", hull(colour, length, freeboard, maps))
	lm.use("Boot", hull(boot, length, freeboard, maps))
	lm.use("White", enamel(white, maps))

## The hull texture set for a length / freeboard bucket (10 m / 2 m).
static func textures(length: float, freeboard: float, maps: bool) -> Dictionary:
	var l := maxi(roundi(length / 10.0), 1) * 10
	var fb := maxi(roundi(freeboard / 2.0), 1) * 2
	var key := "tex|%d|%d|%d" % [l, fb, int(maps)]
	var hit: Variant = _lookup(key)
	if hit != null:
		return hit
	return _store(key, _build(float(l), float(fb), maps))

static func _row(y: float) -> int:
	return clampi(int((TOP_M - y) * float(TEX_H) / (TOP_M + BELOW_M)), 0, TEX_H - 1)

static func _col(x: float, length: float) -> int:
	return clampi(int((x / length + 0.5) * float(TEX_W)), 0, TEX_W - 1)

static func _build(length: float, freeboard: float, maps: bool) -> Dictionary:
	var px_m := float(TEX_W) / length
	var py_m := float(TEX_H) / (TOP_M + BELOW_M)
	# Per-column frame dishing and per-row strake profile; plating is
	# separable, so a height is ax[x] * by[y] plus the seams.
	var ax := PackedFloat32Array()
	ax.resize(TEX_W)
	for x in TEX_W:
		var m := float(x) / px_m
		ax[x] = sin(PI * fposmod(m, FRAME_M) / FRAME_M)
	var by := PackedFloat32Array()
	by.resize(TEX_H)
	var strake := PackedInt32Array()
	strake.resize(TEX_H)
	var seam := PackedByteArray()
	seam.resize(TEX_H)
	for y in TEX_H:
		var m := TOP_M - float(y) / py_m
		var k := floori(m / PLATE_M)
		strake[y] = k
		by[y] = sin(PI * fposmod(m, PLATE_M) / PLATE_M)
		seam[y] = 1 if floori((m - 1.0 / py_m) / PLATE_M) != k else 0
	var alb := PackedByteArray()
	alb.resize(TEX_W * TEX_H * 3)
	var ht := PackedByteArray()
	ht.resize(TEX_W * TEX_H * 3)
	var butt_px := maxi(int(BUTT_M * px_m), 4)
	for y in TEX_H:
		var off := (butt_px / 2) if strake[y] % 2 != 0 else 0
		var fy := float(y)
		for x in TEX_W:
			var weld := (x + off) % butt_px == 0
			var mottle := 0.035 * sin(float(x) * 0.0131 + fy * 0.071) * sin(float(x) * 0.0047 - fy * 0.023) \
				+ 0.015 * sin(float(x) * 0.093 + fy * 0.31)
			var a := 0.95 + mottle
			var h := 0.5 - 0.1 * ax[x] * by[y]
			if seam[y] == 1:
				a -= 0.07
				h = 0.22
			elif weld:
				a -= 0.035
				h = 0.72
			var i := (y * TEX_W + x) * 3
			var c := clampi(int(a * 255.0), 0, 255)
			alb[i] = c
			alb[i + 1] = c
			alb[i + 2] = c
			var hc := clampi(int(h * 255.0), 0, 255)
			ht[i] = hc
			ht[i + 1] = hc
			ht[i + 2] = hc
	var albedo := Image.create_from_data(TEX_W, TEX_H, false, Image.FORMAT_RGB8, alb)
	albedo.generate_mipmaps()
	var detail := _detail(length, freeboard, px_m)
	detail.fix_alpha_edges()
	detail.generate_mipmaps()
	var out := {"albedo": ImageTexture.create_from_image(albedo),
		"detail": ImageTexture.create_from_image(detail), "normal": null}
	if maps:
		var bump := Image.create_from_data(TEX_W, TEX_H, false, Image.FORMAT_RGB8, ht)
		bump.convert(Image.FORMAT_RGBA8)
		bump.bump_map_to_normal_map(3.0)
		bump.generate_mipmaps(true)
		out["normal"] = ImageTexture.create_from_image(bump)
	return out

## The weathering layer, in absolute colours over the tinted plating.
static func _detail(length: float, freeboard: float, px_m: float) -> Image:
	var img := Image.create(TEX_W, TEX_H, false, Image.FORMAT_RGBA8)
	img.fill(Color(GRIME.r, GRIME.g, GRIME.b, 0.0))
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%d|%d" % [roundi(length), roundi(freeboard)])
	# Waterline grime: a ragged band, densest at the water.
	var low := _row(-0.3)
	for x in TEX_W:
		var top := 0.55 + 0.3 * sin(float(x) * 0.021) * sin(float(x) * 0.0067) + rng.randf() * 0.12
		var r0 := _row(top)
		for y in range(r0, low + 1):
			var k := float(y - r0) / float(maxi(low - r0, 1))
			img.set_pixel(x, y, Color(GRIME.r, GRIME.g, GRIME.b, 0.2 + 0.45 * k))
	# Fender scuffs amidships, between the waterline and the quay edge.
	for i in int(length / 12.0):
		var x := _col(rng.randf_range(-0.32, 0.3) * length, length)
		var y := _row(rng.randf_range(0.9, minf(3.6, freeboard * 0.6)))
		img.fill_rect(Rect2i(x, y, int(rng.randf_range(1.5, 5.0) * px_m), rng.randi_range(2, 4)),
			Color(0.12, 0.12, 0.12, rng.randf_range(0.12, 0.28)))
	# Rust weeping from the hawse pipes and the mooring chocks.
	for source in [[0.43, freeboard - 2.2, 5.0], [0.465, freeboard - 0.6, 3.0],
			[-0.455, freeboard - 0.7, 3.0], [0.2, freeboard - 0.5, 2.0], [-0.2, freeboard - 0.5, 2.0]]:
		_streak(img, rng, _col(float(source[0]) * length, length), float(source[1]), float(source[2]), RUST, 0.55, 3)
	# Overboard discharges: grey-brown stains running to the water.
	var n := int(length / 15.0)
	for i in n:
		var x := lerpf(-0.36, 0.32, (float(i) + rng.randf()) / float(maxi(n, 1))) * length
		_streak(img, rng, _col(x, length), rng.randf_range(1.6, maxf(2.0, freeboard * 0.45)), 2.5, STAIN, 0.35, 2)
	# Draught marks at bow and stern: 0.1 m ticks every 0.2 m.
	for fx in [0.47, -0.47]:
		var x := _col(float(fx) * length, length)
		var y := -1.0
		while y < minf(4.0, freeboard * 0.6):
			img.fill_rect(Rect2i(x, _row(y + 0.1), 4 if roundi(y * 5.0) % 5 == 0 else 2, 1), Color(0.92, 0.92, 0.9, 0.9))
			y += 0.2
	return img

## A streak from (`col`, `y0` m) running `run_m` metres down, fading.
static func _streak(img: Image, rng: RandomNumberGenerator, col: int, y0: float, run_m: float,
		colour: Color, alpha: float, width: int) -> void:
	var r0 := _row(y0)
	var r1 := _row(maxf(y0 - run_m * rng.randf_range(0.7, 1.3), -0.2))
	for y in range(r0, r1 + 1):
		var k := float(y - r0) / float(maxi(r1 - r0, 1))
		var w := maxi(1, int(round(float(width) * (1.0 - 0.6 * k))))
		var x0 := col - w / 2 + (1 if rng.randf() < 0.15 else 0)
		for dx in w:
			var x := clampi(x0 + dx, 0, TEX_W - 1)
			var a := alpha * (1.0 - k) * (0.6 + 0.4 * rng.randf())
			if a > img.get_pixel(x, y).a:
				img.set_pixel(x, y, Color(colour.r, colour.g, colour.b, a))

## Enamel streak tile: near-white with faint weeping under deck edges.
static func _streaks() -> Texture2D:
	var hit: Variant = _lookup("streaks")
	if hit != null:
		return hit
	var size := 256
	var img := Image.create(size, size, true, Image.FORMAT_RGB8)
	img.fill(Color(1, 1, 1))
	var rng := RandomNumberGenerator.new()
	rng.seed = 7151
	for i in 70:
		var x := rng.randi_range(0, size - 1)
		var y0 := rng.randi_range(0, size - 1)
		var run := rng.randi_range(20, 110)
		var depth := rng.randf_range(0.03, 0.09)
		for k in run:
			var c := 1.0 - depth * (1.0 - float(k) / float(run))
			img.set_pixel(x, (y0 + k) % size, Color(c, c, c * 0.99))
	img.generate_mipmaps()
	return _store("streaks", ImageTexture.create_from_image(img))
