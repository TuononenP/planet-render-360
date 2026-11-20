class_name ForiShuttle
extends Node3D

## Smoothly shuttles the Föri double-ended ferry vessel along its local +X/-X
## crossing axis between the two stationary Aurajoki landing stages, following
## Föri's real seasonal operating schedule and driving its vessel night lights:
##   - Summer (May–Sep, months 5..9): 06:15 – 23:00 (6.25 <= hour < 23.0)
##   - Winter (Oct–Apr, months 1..4, 10..12): 06:15 – 21:00 (6.25 <= hour < 21.0)
##   - Inside schedule: shuttles between -travel_half_m and +travel_half_m
##     (~90 s full round trip with 11 s boarding pauses); warm cabin, mast &
##     deck lights turn on automatically at dusk/night via CityLights.night_amount.
##   - Outside schedule: moored stationary at the west landing (-travel_half_m)
##     with ALL vessel lights OFF (even at night).
## Survives WorldCache PackedScene save/load natively; starts at x = 0.0 on
## frame 0 when operating so studio captures & screenshot tests frame it mid-river.

@export var travel_half_m: float = 26.85
@export var cross_sec: float = 34.0
@export var pause_sec: float = 11.0

const OPEN_HOUR := 6.25
const SUMMER_CLOSE_HOUR := 23.0
const WINTER_CLOSE_HOUR := 21.0
const LAMP_NIGHT_ENERGY := 2.4
const DECK_LIGHT_ENERGY := 1.6

var _elapsed: float = 0.0
var _lamp_mat: StandardMaterial3D
var _deck_light: OmniLight3D

func _ready() -> void:
	_cache_lights()
	apply_state(0.0, CityLights.hour, CityLights.month, CityLights.night_amount)

func _process(delta: float) -> void:
	if Engine.is_editor_hint() or delta <= 0.0:
		return
	var active := is_operating(CityLights.hour, CityLights.month)
	if active:
		_elapsed += delta
	apply_state(_elapsed, CityLights.hour, CityLights.month, CityLights.night_amount)

## Real Föri operating schedule: Summer (May–Sep) 06:15–23:00, Winter (Oct–Apr) 06:15–21:00.
static func is_operating(hour_f: float, month_num: int) -> bool:
	var h := fposmod(hour_f, 24.0)
	var is_summer := month_num >= 5 and month_num <= 9
	var close_h := SUMMER_CLOSE_HOUR if is_summer else WINTER_CLOSE_HOUR
	return h >= OPEN_HOUR and h < close_h

## Updates vessel position and night lighting for the given clock & night factor.
func apply_state(elapsed_sec: float, hour_f: float, month_num: int, night_amt: float) -> void:
	var active := is_operating(hour_f, month_num)
	position.x = sample_x(elapsed_sec) if active else -travel_half_m
	var glow := clampf(night_amt, 0.0, 1.0) if active else 0.0
	if _lamp_mat == null:
		_cache_lights()
	if _lamp_mat != null:
		_lamp_mat.emission_energy_multiplier = glow * LAMP_NIGHT_ENERGY
	if _deck_light != null:
		_deck_light.visible = glow > 0.02
		_deck_light.light_energy = glow * DECK_LIGHT_ENERGY

## Returns the vessel's local X offset (metres) while operating at `elapsed_sec`.
## Starts at the midpoint of the first crossing so sample_x(0.0) == 0.0.
func sample_x(elapsed_sec: float) -> float:
	var period := 2.0 * (cross_sec + pause_sec)
	if period <= 0.0 or cross_sec <= 0.0:
		return 0.0
	var t := fposmod(elapsed_sec + cross_sec * 0.5, period)
	if t < cross_sec:
		return lerpf(-travel_half_m, travel_half_m, _smooth(t / cross_sec))
	t -= cross_sec
	if t < pause_sec:
		return travel_half_m
	t -= pause_sec
	if t < cross_sec:
		return lerpf(travel_half_m, -travel_half_m, _smooth(t / cross_sec))
	return -travel_half_m

func _cache_lights() -> void:
	var lamp_node := get_node_or_null("ForiLamp") as MeshInstance3D
	if lamp_node != null and lamp_node.mesh != null and lamp_node.mesh.get_surface_count() > 0:
		var m := lamp_node.mesh.surface_get_material(0) as StandardMaterial3D
		if m != null:
			_lamp_mat = m.duplicate() as StandardMaterial3D
			lamp_node.set_surface_override_material(0, _lamp_mat)
	_deck_light = get_node_or_null("ForiDeckLight") as OmniLight3D

static func _smooth(u: float) -> float:
	var c := clampf(u, 0.0, 1.0)
	return c * c * (3.0 - 2.0 * c)
