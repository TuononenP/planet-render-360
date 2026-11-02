class_name RoadDecals
extends RefCounted

## Street ironwork as decals (desktop Ultra, Phase 7 of the Ultra pass):
## cast-iron manhole covers in the lanes and gutter grates at the kerb of
## urban streets near the eye. Decals project onto the road ribbon below,
## so they add no geometry and follow its drape. Placement is a fixed
## walk along each road (a cover every MANHOLE_STEP_M, a grate every
## DRAIN_STEP_M alternating sides), hashed sideways by position, so the
## same street always gets the same ironwork; the nearest MAX_DECALS are
## kept. Leaf litter: a scatter of fallen leaves under each mapped
## street tree (OSM natural=tree) within LITTER_RADIUS_M, autumn-heavy.
## Painted procedurally (cover, grate and litter textures).

const RADIUS_M := 300.0
const MAX_DECALS := 700
const MANHOLE_STEP_M := 38.0
const DRAIN_STEP_M := 24.0
const MANHOLE_M := 0.8
const DRAIN_SIZE_M := Vector2(0.9, 0.42)
## Decal box depth: enough to reach a draped ribbon on a slope.
const DEPTH_M := 1.6
const FADE_BEGIN_M := 140.0
const FADE_LENGTH_M := 60.0
const TEX := 128
const LITTER_RADIUS_M := 250.0
const MAX_LITTER := 400
## Litter patch diameter (m), and its leaf density by season (0..1).
const LITTER_M := 4.5
const LITTER_BY_SEASON := [0.35, 0.25, 1.0, 0.5]

static var _cover: Texture2D
static var _grate: Texture2D
static var _litter: Texture2D

## Adds the decals under one "RoadDecals" node of `root` on desktop Ultra.
## Returns the number added.
static func build(root: Node3D, data: LocationData, ground: GroundTruth) -> int:
	if not RenderQuality.ultra_desktop(data.quality_preset):
		return 0
	var m := WorldScale.metres_to_units()
	var spots: Array = []  # [distance², position (x, z), yaw, kind]
	for line in data.roads:
		if not (line is Dictionary):
			continue
		var rd: Dictionary = line
		if bool(rd.get("tunnel", false)) or bool(rd.get("bridge", false)) or bool(rd.get("area", false)):
			continue
		var cls := str(rd.get("class", ""))
		if cls not in StreetProps.LIT:
			continue
		var pts: PackedVector2Array = rd.get("points", PackedVector2Array())
		if pts.size() < 2:
			continue
		var mid := pts[pts.size() / 2]
		if ground.land_class_at(mid.x, mid.y) != "urban":
			continue
		_walk(spots, pts, float(rd.get("width_m", 6.0)) * m, m, ground)
	if spots.is_empty():
		return 0
	spots.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) < float(b[0]))
	var holder := Node3D.new()
	holder.name = "RoadDecals"
	for i in mini(spots.size(), MAX_DECALS):
		var s: Array = spots[i]
		var p: Vector2 = s[1]
		var d := Decal.new()
		var manhole := str(s[3]) == "manhole"
		d.texture_albedo = cover_texture() if manhole else grate_texture()
		d.size = Vector3(MANHOLE_M, DEPTH_M, MANHOLE_M) * m if manhole \
			else Vector3(DRAIN_SIZE_M.x, DEPTH_M, DRAIN_SIZE_M.y) * m
		d.position = Vector3(p.x, ground.height_at_world(p.x, p.y), p.y)
		d.rotation.y = float(s[2])
		d.upper_fade = 0.1
		d.lower_fade = 0.1
		d.distance_fade_enabled = true
		d.distance_fade_begin = FADE_BEGIN_M * m
		d.distance_fade_length = FADE_LENGTH_M * m
		d.cull_mask = 0xFFFFF
		holder.add_child(d)
	_add_litter(holder, data, ground, m)
	root.add_child(holder)
	return holder.get_child_count()

## Fallen leaves under the nearest mapped trees (MAX_LITTER), opacity by
## season (LITTER_BY_SEASON), turned per tree.
static func _add_litter(holder: Node3D, data: LocationData, ground: GroundTruth, m: float) -> void:
	var r2 := pow(LITTER_RADIUS_M * m, 2.0)
	var near: Array = []
	for t in data.trees:
		if not (t is Dictionary):
			continue
		var p := Vector2(float(t.get("x", 0.0)), float(t.get("z", 0.0)))
		if p.length_squared() <= r2:
			near.append(p)
	near.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.length_squared() < b.length_squared())
	var share: float = LITTER_BY_SEASON[clampi(int(data.season), 0, 3)]
	for i in mini(near.size(), MAX_LITTER):
		var p: Vector2 = near[i]
		var d := Decal.new()
		d.texture_albedo = litter_texture()
		d.size = Vector3(LITTER_M, DEPTH_M, LITTER_M) * m
		d.position = Vector3(p.x, ground.height_at_world(p.x, p.y), p.y)
		d.rotation.y = _hash(p) * TAU
		d.albedo_mix = share
		d.upper_fade = 0.1
		d.lower_fade = 0.1
		d.distance_fade_enabled = true
		d.distance_fade_begin = FADE_BEGIN_M * m
		d.distance_fade_length = FADE_LENGTH_M * m
		holder.add_child(d)

## Walks one road, noting covers in the lanes and grates at the kerbs.
static func _walk(spots: Array, pts: PackedVector2Array, width_u: float, m: float,
		ground: GroundTruth) -> void:
	var r2 := pow(RADIUS_M * m, 2.0)
	var travelled := 0.0
	var next_cover := MANHOLE_STEP_M * 0.5 * m
	var next_drain := DRAIN_STEP_M * 0.3 * m
	var side := 1.0
	for i in pts.size() - 1:
		var a := pts[i]
		var b := pts[i + 1]
		var seg := a.distance_to(b)
		if seg < 0.001:
			continue
		var dir := (b - a) / seg
		var nrm := Vector2(-dir.y, dir.x)
		var yaw := atan2(-dir.y, dir.x)
		while next_cover <= travelled + seg or next_drain <= travelled + seg:
			var cover := next_cover <= next_drain
			var at := (next_cover if cover else next_drain) - travelled
			var c := a + dir * at
			var p: Vector2
			if cover:
				var h := _hash(c)
				p = c + nrm * (h - 0.5) * width_u * 0.5
				next_cover += MANHOLE_STEP_M * m * (0.8 + 0.4 * h)
			else:
				side = -side
				p = c + nrm * side * (width_u * 0.5 - 0.45 * m)
				next_drain += DRAIN_STEP_M * m
			if p.length_squared() > r2 or ground.water_at(p.x, p.y) > 0.0:
				continue
			spots.append([p.length_squared(), p, yaw, "manhole" if cover else "drain"])
		travelled += seg

static func _hash(p: Vector2) -> float:
	return fmod(absf(sin(p.x * 12.9898 + p.y * 78.233) * 43758.5453), 1.0)

## Round cast-iron cover: a rim ring, a chequer of raised bosses, a dark
## seat joint round the edge; transparent outside the disc.
static func cover_texture() -> Texture2D:
	if _cover != null:
		return _cover
	var img := Image.create(TEX, TEX, true, Image.FORMAT_RGBA8)
	var c := float(TEX) * 0.5
	for y in TEX:
		for x in TEX:
			var r := Vector2(x + 0.5 - c, y + 0.5 - c).length() / c
			if r > 1.0:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
				continue
			var v := 0.17
			if r > 0.93:
				v = 0.07   # seat joint
			elif r > 0.84:
				v = 0.22   # rim
			elif (x / 9 + y / 9) % 2 == 0:
				v = 0.24   # raised boss
			v *= 0.85 + 0.3 * _hash(Vector2(x, y))
			var a := 1.0 - smoothstep(0.96, 1.0, r)
			img.set_pixel(x, y, Color(v, v * 0.97, v * 0.93, a))
	img.generate_mipmaps()
	_cover = ImageTexture.create_from_image(img)
	return _cover

## Fallen leaves: small ochre, rust and brown ellipses scattered thicker
## toward the middle, transparent between them.
static func litter_texture() -> Texture2D:
	if _litter != null:
		return _litter
	var img := Image.create(TEX * 2, TEX * 2, true, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var cols := [Color(0.55, 0.36, 0.10), Color(0.45, 0.18, 0.06), Color(0.32, 0.22, 0.10), Color(0.60, 0.48, 0.16)]
	var n := TEX * 2
	for k in 900:
		var r := sqrt(rng.randf()) * 0.48
		var a := rng.randf() * TAU
		var c := Vector2(0.5 + cos(a) * r, 0.5 + sin(a) * r) * float(n)
		var col: Color = cols[rng.randi() % cols.size()]
		var ang := rng.randf() * TAU
		var ax := Vector2(cos(ang), sin(ang))
		for y in range(int(c.y) - 4, int(c.y) + 5):
			for x in range(int(c.x) - 4, int(c.x) + 5):
				if x < 0 or y < 0 or x >= n or y >= n:
					continue
				var q := Vector2(x, y) - c
				var u := q.dot(ax) / 3.6
				var v := q.dot(Vector2(-ax.y, ax.x)) / 1.8
				if u * u + v * v <= 1.0:
					img.set_pixel(x, y, col * (0.85 + 0.3 * rng.randf()))
	img.generate_mipmaps()
	_litter = ImageTexture.create_from_image(img)
	return _litter

## Gutter grate: dark slots between iron bars inside a frame.
static func grate_texture() -> Texture2D:
	if _grate != null:
		return _grate
	var w := TEX
	var h := TEX / 2
	var img := Image.create(w, h, true, Image.FORMAT_RGBA8)
	for y in h:
		for x in w:
			var frame := x < 6 or x >= w - 6 or y < 6 or y >= h - 6
			var slot := not frame and (x % 12) >= 5
			var v := 0.02 if slot else (0.2 if frame else 0.16)
			v *= 0.85 + 0.3 * _hash(Vector2(x, y))
			img.set_pixel(x, y, Color(v, v * 0.97, v * 0.93, 1.0))
	img.generate_mipmaps()
	_grate = ImageTexture.create_from_image(img)
	return _grate
