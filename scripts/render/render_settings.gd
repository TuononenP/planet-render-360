class_name RenderSettings
extends RefCounted

## User-chosen render quality. One preset trades accuracy for time at
## every costly step: DEM grid resolution (terrain accuracy and mesh
## build time), how many OSM buildings / trees are placed (build time
## and draw cost), and the 360 view's render scale and shadows (frame
## time). High is the default preset.
## Held in memory in Main's RenderSettings instance and persisted as
## JSON in user://settings.json, like CacheStore's history.

enum Preset { FAST, BALANCED, HIGH, ULTRA }

const PATH := "user://settings.json"
const PRESET_NAMES: Array[String] = ["Fast", "Balanced", "High", "Ultra"]
const PRESET_BLURBS: Array[String] = [
	"Quickest — coarser terrain, fewer buildings and trees, no shadows.",
	"Balanced detail and speed.",
	"Recommended default — fine terrain, most buildings and trees, shadows.",
	"Maximum fidelity — finest terrain, most buildings and trees, shadows. Slowest to render; needs a fast device.",
]

var preset: int = Preset.HIGH

static func clamp_preset(value: int) -> int:
	return clampi(value, Preset.FAST, Preset.ULTRA)

static func preset_name(value: int) -> String:
	return PRESET_NAMES[clamp_preset(value)]

# --- Generation budgets (paid once, as loading/render time) ---

static func grid_size_for(value: int) -> int:
	return [32, 48, 64, 128][clamp_preset(value)]

static func far_grid_size_for(value: int) -> int:
	return [32, 48, 64, 128][clamp_preset(value)]

static func max_buildings_for(value: int) -> int:
	return [120, 240, 340, 700][clamp_preset(value)]

static func vegetation_count_for(value: int, urban: bool) -> int:
	if urban:
		return [70, 120, 170, 380][clamp_preset(value)]
	return [90, 170, 230, 500][clamp_preset(value)]

static func silhouette_count_for(value: int) -> int:
	return [24, 36, 46, 90][clamp_preset(value)]

static func procedural_buildings_for(value: int) -> int:
	return [40, 65, 90, 200][clamp_preset(value)]

# --- Frame budgets (paid every frame in the 360 view) ---

## Ceiling for QualityGovernor: it may step down from here under low
## FPS, and back up to here — never past the user's chosen ceiling.
static func render_scale_for(value: int) -> float:
	return [0.65, 0.85, 1.0, 1.25][clamp_preset(value)]

static func shadows_for(value: int) -> bool:
	return clamp_preset(value) > Preset.FAST

## Shadow reach (world units) and softness per preset; only Ultra
## pays for far, sharp shadows — the rest keep the tuned 600 / 1.8.
static func shadow_distance_for(value: int) -> float:
	return [600.0, 600.0, 600.0, 1000.0][clamp_preset(value)]

static func shadow_blur_for(value: int) -> float:
	return [1.8, 1.8, 1.8, 1.0][clamp_preset(value)]

## Human-readable cost summary for the settings screen, e.g.
## "48×48 terrain · up to 240 buildings · shadows on".
static func summary_for(value: int) -> String:
	var p := clamp_preset(value)
	return "%d×%d terrain · up to %d buildings · %d trees · shadows %s · %.0f%% render scale" % [
		grid_size_for(p), grid_size_for(p), max_buildings_for(p),
		vegetation_count_for(p, false), "on" if shadows_for(p) else "off",
		render_scale_for(p) * 100.0]

static func apply_preset(data: LocationData, value: int) -> void:
	data.quality_preset = clamp_preset(value)
	data.grid_size = grid_size_for(value)
	data.far_grid_size = far_grid_size_for(value)

func apply_to(data: LocationData) -> void:
	apply_preset(data, preset)

func load_settings() -> void:
	if not FileAccess.file_exists(PATH):
		return
	var f := FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if parsed is Dictionary:
		preset = clamp_preset(int(parsed.get("preset", Preset.HIGH)))

func save_settings() -> void:
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f == null:
		push_warning("RenderSettings: cannot write %s" % PATH)
		return
	f.store_string(JSON.stringify({"preset": clamp_preset(preset)}))

func set_preset(value: int) -> void:
	preset = clamp_preset(value)
	save_settings()
