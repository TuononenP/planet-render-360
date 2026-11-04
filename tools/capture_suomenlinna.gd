extends "res://tools/capture_presets.gd"

## Reproducible fortress review through the real app pipeline. Reuse
## cached map data for stable before/after comparisons; never bake thumbs.
## tools/godot_bg.sh --path . --script tools/capture_suomenlinna.gd --position 4000,4000 -- --tag=suomenlinna-fortress --preset=3 --season=summer --date=2026-06-21 --times=golden,noon,roofs
func _places(_filter: String, _landmark_types: String = "", _pin: String = "") -> Array:
	return [{"id": "suomenlinna", "name": "Suomenlinna", "lat": 60.1458, "lon": 24.9873}]

func _capture(main: Node, view: View360, place: Dictionary, times: PackedStringArray,
		audit: bool, settle_s: float = SETTLE_S) -> void:
	main._pipeline._osm.offline_mode = true
	await super._capture(main, view, place, times, audit, settle_s)
