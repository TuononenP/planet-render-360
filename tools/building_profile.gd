extends "res://tools/shoreline_capture.gd"

## Frozen-input building benchmark. With --bench-only it reports time to
## build and pack the world without capturing frames. Use --script-sampler
## to compare the original settlement sampler against the native kernel.
## Example (windowed for representative rendering-server costs):
## tools/godot_bg.sh --path . --script tools/building_profile.gd --position 4000,4000 \
##   -- --inputs=/tmp/pr360-shore-inputs --places=paris,helsinki --presets=2 --bench-only
func _run() -> void:
	if OS.get_cmdline_user_args().has("--script-sampler"):
		SettlementMap._native = false
	print("BUILDING PROFILE native_settlement=", SettlementMap._native)
	await super._run()
