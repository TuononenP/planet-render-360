class_name ShopLights
extends RefCounted

## Shopfront spill light (desktop Ultra, Phase 5 of the Ultra pass): lit
## shop windows throw a warm pool onto the pavement in front of them.
## StreetFront notes a point every SPACING_M along each street-facing shop
## storey near the eye (SHOP_RADIUS_M), a metre out from the glass at
## fascia height; the nearest MAX_LIGHTS get a small shadowless omni,
## faded out by distance, off by day and driven at night by
## CityLights.apply (they carry StreetLights.META). Buildings build on
## worker threads, so the points gather under a mutex.

const MAX_LIGHTS := 160
const SHOP_RADIUS_M := 200.0
const SPACING_M := 6.0
## Light energy at full night (Godot units, not physical).
const ENERGY := 0.9
const RANGE_M := 7.0
const FADE_BEGIN_M := 120.0
const FADE_LENGTH_M := 40.0
## Out from the shop glass, and up from the pavement (m).
const OUT_M := 1.0
const HEIGHT_M := 2.6
## Warm shop interior (~3000 K).
const COLOUR := Color(1.0, 0.80, 0.58)

static var _points: PackedVector3Array = PackedVector3Array()
static var _mutex := Mutex.new()

static func begin_build() -> void:
	_mutex.lock()
	_points = PackedVector3Array()
	_mutex.unlock()

## Forgets a cancelled build's points, so they never wait in the list.
static func discard() -> void:
	begin_build()

## Notes the spill points along one shop stretch: from `a` along `dir`
## for `len_m`, pushed out along the outward normal `n`, at `floor_y`
## (internal units) plus HEIGHT_M.
static func note(a: Vector2, dir: Vector2, n: Vector2, len_m: float, floor_y: float) -> void:
	var m := WorldScale.metres_to_units()
	var count := maxi(1, int(len_m / SPACING_M))
	var pts := PackedVector3Array()
	for k in count:
		var t := (float(k) + 0.5) * len_m / float(count)
		var p := a + dir * t * m + n * OUT_M * m
		pts.append(Vector3(p.x, floor_y + HEIGHT_M * m, p.y))
	_mutex.lock()
	_points.append_array(pts)
	_mutex.unlock()

## Adds the nearest MAX_LIGHTS noted points under one "ShopLights" node of
## `root` and forgets them. Returns the number added.
static func add(root: Node3D) -> int:
	_mutex.lock()
	var pts := _points
	_points = PackedVector3Array()
	_mutex.unlock()
	if pts.is_empty():
		return 0
	var order: Array = []
	for i in pts.size():
		order.append([Vector2(pts[i].x, pts[i].z).length_squared(), i])
	order.sort_custom(func(x: Array, y: Array) -> bool: return float(x[0]) < float(y[0]))
	var m := WorldScale.metres_to_units()
	var holder := Node3D.new()
	holder.name = "ShopLights"
	for j in mini(order.size(), MAX_LIGHTS):
		var omni := OmniLight3D.new()
		omni.position = pts[int(order[j][1])]
		omni.omni_range = RANGE_M * m
		omni.omni_attenuation = 1.6
		omni.light_color = COLOUR
		omni.light_energy = 0.0
		omni.shadow_enabled = false
		omni.distance_fade_enabled = true
		omni.distance_fade_begin = FADE_BEGIN_M * m
		omni.distance_fade_length = FADE_LENGTH_M * m
		omni.visible = false
		omni.set_meta(StreetLights.META, ENERGY)
		holder.add_child(omni)
	root.add_child(holder)
	return holder.get_child_count()
