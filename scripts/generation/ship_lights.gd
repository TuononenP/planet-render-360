class_name ShipLights
extends RefCounted

## Large ships at dusk and night, driven by CityLights like the city's
## lit rooms (energy 0 by day, raised as the sky darkens):
## - cabin glass: "Cabin0".."Cabin3", the vessel glass with a lit-cabin
##   emission tile (metre UVs) at four offsets, so stacked decks and
##   neighbouring ships do not repeat one pattern. By day the same tile
##   varies the panes (curtains, a lit lounge). Bridges keep plain "Glass":
##   a bridge is dark at night.
## - lamps: "Lamp" warm deck and floodlights, "NavRed" (port, -Z),
##   "NavGreen" (starboard, +Z) and "NavWhite" masthead / stern lights.
##   With +X the bow and +Y up, starboard is +Z.
## The shared VesselMaterials glass (yachts) is never marked.
const TILE_M := Vector2(32.0, 8.0)
const PX_M := 8
const CABIN_M := 1.6
const LIT := 0.55
const KEYS := ["Cabin0", "Cabin1", "Cabin2", "Cabin3"]
static var _cache := {}
static var _mutex := Mutex.new()

static func _lookup(key: String) -> Variant:
	_mutex.lock()
	var hit: Variant = _cache.get(key)
	_mutex.unlock()
	return hit

static func _store(key: String, value: Variant) -> Variant:
	_mutex.lock()
	if not _cache.has(key):
		_cache[key] = value
	var out: Variant = _cache[key]
	_mutex.unlock()
	return out

## Registers the cabin glass and lamp keys on `lm`.
static func register(lm: LandmarkMesh, maps: bool = true) -> void:
	for k in KEYS.size():
		lm.use(KEYS[k], cabin_glass(k, maps))
	lm.use("Lamp", lamp(Color(1.0, 0.78, 0.5), 1.4))
	lm.use("NavRed", lamp(Color(1.0, 0.08, 0.05), 3.0))
	lm.use("NavGreen", lamp(Color(0.1, 1.0, 0.35), 3.0))
	lm.use("NavWhite", lamp(Color(1.0, 0.97, 0.9), 3.0))

## The glass key for deck `i` of a stack.
static func cabin_key(i: int) -> String:
	return KEYS[posmod(i, KEYS.size())]

static func cabin_glass(k: int, maps: bool = true) -> StandardMaterial3D:
	var key := "cabin|%d|%d" % [k, int(maps)]
	var hit: Variant = _lookup(key)
	if hit != null:
		return hit
	var texs := _cabin_tile()
	var base := VesselMaterials.get_mat("glass", maps)
	var m := base.duplicate() as StandardMaterial3D
	m.albedo_color = Color.WHITE
	m.albedo_texture = texs["albedo"]
	m.uv1_scale = Vector3(1.0 / TILE_M.x, 1.0 / TILE_M.y, 1.0)
	# Whole-cabin shifts (8 m = five cells), so cells keep their place.
	m.uv1_offset = Vector3(0.25 * float(k), 0.37 * float(k), 0.0)
	CityLights.mark(m, texs["emit"])
	return _store(key, m)

## A lamp lens: its colour by day, glowing at `scale` x the pane energy at
## night (HDR, so it halos under glow).
static func lamp(colour: Color, scale: float) -> StandardMaterial3D:
	var key := "lamp|%s|%.2f" % [colour.to_html(false), scale]
	var hit: Variant = _lookup(key)
	if hit != null:
		return hit
	var m := StandardMaterial3D.new()
	m.albedo_color = colour.lerp(Color.WHITE, 0.35)
	m.roughness = 0.2
	m.emission_enabled = true
	m.emission = colour
	CityLights.mark_glow(m, scale)
	return _store(key, m)

## Day albedo and night emission for one TILE_M tile of cabin windows.
## Columns are cabins; every column spans the tile's height, so no window
## band is split between a lit and a dark cabin.
static func _cabin_tile() -> Dictionary:
	var hit: Variant = _lookup("tile")
	if hit != null:
		return hit
	var w := int(TILE_M.x) * PX_M
	var h := int(TILE_M.y) * PX_M
	var alb := Image.create(w, h, false, Image.FORMAT_RGB8)
	var emit := Image.create(w, h, false, Image.FORMAT_RGB8)
	alb.fill(Color("#263d4a"))
	emit.fill(Color.BLACK)
	var rng := RandomNumberGenerator.new()
	rng.seed = 90210
	var cell := int(CABIN_M * PX_M)
	for x0 in range(0, w, cell):
		var r := Rect2i(x0 + 1, 0, cell - 1, h)
		var day := rng.randf()
		if day < 0.18:
			alb.fill_rect(r, Color("#5f6a6c"))  # drawn curtains
		elif day < 0.26:
			alb.fill_rect(r, Color("#3d4a50"))
		else:
			alb.fill_rect(r, Color("#263d4a").lerp(Color("#1b2b35"), rng.randf()))
		alb.fill_rect(Rect2i(x0, 0, 1, h), Color("#d9d9d4"))  # cabin divider
		var hv := rng.randf()
		if hv < LIT:
			var k := rng.randf()
			var c := FacadePaint.WARM.lerp(FacadePaint.COOL, 0.8) if k > 0.85 \
				else FacadePaint.WARM.lerp(Color(1.0, 0.85, 0.6), k)
			var e := 0.45 + 0.55 * rng.randf()
			emit.fill_rect(r, Color(c.r * e, c.g * e, c.b * e))
	alb.generate_mipmaps()
	emit.generate_mipmaps()
	return _store("tile", {"albedo": ImageTexture.create_from_image(alb),
		"emit": ImageTexture.create_from_image(emit)})

## A small round lamp at `at` (radius `r`).
static func bulb(lm: LandmarkMesh, key: String, at: Vector3, r: float) -> void:
	lm.lathe(key, at - Vector3(0, r, 0), PackedVector2Array([Vector2(0.001, 0), Vector2(r, r * 0.4),
		Vector2(r, r * 1.6), Vector2(0.001, r * 2.0)]), 8, 1.0, 1.0, 0.0, true, false)

## Navigation lights: sidelights at the bridge-wing tips (`wing_x`,
## `wing_y`, half-span `wing_z`), a masthead light at `mast_top`, an
## after masthead light at `aft_top` (ships over 50 m) and a stern light.
static func nav(lm: LandmarkMesh, wing_x: float, wing_y: float, wing_z: float, mast_top: Vector3,
		stern: Vector3, aft_top: Vector3 = Vector3.INF) -> void:
	var r := clampf(wing_z * 0.03, 0.18, 0.4)
	bulb(lm, "NavRed", Vector3(wing_x, wing_y, -wing_z), r)
	bulb(lm, "NavGreen", Vector3(wing_x, wing_y, wing_z), r)
	bulb(lm, "NavWhite", mast_top, r)
	bulb(lm, "NavWhite", stern, r)
	if aft_top.is_finite():
		bulb(lm, "NavWhite", aft_top, r)

## Warm deck lamps every `step` m along x at height `y`, both sides at `z`.
static func deck_lamps(lm: LandmarkMesh, x0: float, x1: float, y: float, z: float, step: float, r: float = 0.12) -> void:
	var n := maxi(int(absf(x1 - x0) / step), 1)
	for i in n + 1:
		var x := lerpf(x0, x1, float(i) / float(n))
		for s in [-1.0, 1.0]:
			bulb(lm, "Lamp", Vector3(x, y, float(s) * z), r)
