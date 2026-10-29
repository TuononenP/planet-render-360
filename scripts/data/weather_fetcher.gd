class_name WeatherFetcher
extends Node

## Current weather from Open-Meteo: free, no key, direct from device.
## Optional dressing only — failure never blocks the 360 view.

signal succeeded(temp_c: float, label: String, cloud_cover: float, code: int)
signal failed(reason: String)

const URL_TEMPLATE := "https://api.open-meteo.com/v1/forecast?latitude=%.4f&longitude=%.4f&current=temperature_2m,weather_code,cloud_cover&timezone=auto"
const USER_AGENT := "PlanetRender360/0.1"

var _http: HTTPRequest
## The place's UTC offset from the last response (`timezone=auto`), for
## the true sun's local clock (T6.2); has_utc_offset is false until then.
var utc_offset_s := 0
var has_utc_offset := false

func _ready() -> void:
	_http = HTTPRequest.new()
	_http.timeout = 15.0
	add_child(_http)
	_http.request_completed.connect(_on_done)

static func label_for_code(code: int) -> String:
	match code:
		0: return "Clear"
		1: return "Mostly clear"
		2: return "Partly cloudy"
		3: return "Overcast"
		45, 48: return "Fog"
		51, 53, 55: return "Drizzle"
		61, 63, 65, 80, 81, 82: return "Rain"
		71, 73, 75, 77, 85, 86: return "Snow"
		95, 96, 99: return "Thunderstorm"
		_: return "Unknown"

static func parse_current(text: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(text)
	if parsed is Dictionary and parsed.has("current"):
		var cur: Dictionary = parsed["current"]
		var code := int(cur.get("weather_code", -1))
		var out := {
			"temp": float(cur.get("temperature_2m", 0.0)),
			"code": code,
			"label": label_for_code(code),
			"cloud": float(cur.get("cloud_cover", 0.0)),
		}
		if parsed.has("utc_offset_seconds"):
			out["utc_offset_s"] = int(parsed["utc_offset_seconds"])
		return out
	return {}

func fetch(lat: float, lon: float) -> void:
	var err := _http.request(URL_TEMPLATE % [lat, lon],
		["User-Agent: %s" % USER_AGENT, "Accept: application/json"])
	if err != OK:
		failed.emit("Weather request failed to start: %s" % err)

func _on_done(result: int, code: int, _h: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		failed.emit("Weather failed (result=%d code=%d)" % [result, code])
		return
	var parsed := parse_current(body.get_string_from_utf8())
	if parsed.is_empty():
		failed.emit("Weather response unreadable")
		return
	if parsed.has("utc_offset_s"):
		utc_offset_s = int(parsed["utc_offset_s"])
		has_utc_offset = true
	succeeded.emit(float(parsed["temp"]), str(parsed["label"]),
		float(parsed["cloud"]), int(parsed["code"]))
