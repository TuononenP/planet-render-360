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
## Tier names (plan Open Q2, settled in T7.4): the shipping names stay —
## they say what the user trades — and each tier shows its PRD fidelity
## level (FIDELITY) and §3.1 generation budget in the settings copy.
## Every tier is the same place, layout and hues (AC-12): tiers change
## LOD/texture/shadow cost and wait time, never which real buildings
## exist (past a cap they become impostors).
const PRESET_NAMES: Array[String] = ["Fast", "Balanced", "High", "Ultra"]
## PRD fidelity level per preset (docs/fidelity-scorecard.md §2).
const FIDELITY: Array[int] = [1, 2, 2, 3]
## §3.1 budgets: first build on broadband and a cached revisit.
const FIRST_BUILD: Array[String] = ["≤20 s", "≤45 s", "≤75 s", "~1–2 min"]
const REVISIT: Array[String] = ["≤3 s", "≤5 s", "≤5 s", "≤8 s"]
const PRESET_BLURBS: Array[String] = [
	"Fidelity 1 — quickest: coarser terrain mesh, nearby detail only, no shadows. First build ≤20 s, then cached.",
	"Fidelity 2 — balanced detail and speed, shadows. First build ≤45 s, then cached.",
	"Fidelity 2 — recommended: fine terrain, sharp satellite imagery, shadows. First build ≤75 s, then cached.",
	"Fidelity 3 — most faithful: finest terrain mesh, widest detail rings, far shadows. First build ~1–2 min, then cached; needs a fast device.",
]

var preset: int = Preset.HIGH

static func clamp_preset(value: int) -> int:
	return clampi(value, Preset.FAST, Preset.ULTRA)

static func preset_name(value: int) -> String:
	return PRESET_NAMES[clamp_preset(value)]

static func fidelity_for(value: int) -> int:
	return FIDELITY[clamp_preset(value)]

# --- Generation budgets (paid once, as loading/render time) ---

## DEM / GroundTruth posts per side over the 2400 m extent (9.4 m, near
## the z14 DEM's native 6–10 m/px). Preset-INDEPENDENT since T7.0/T7.1:
## every object sits on GroundTruth, so a per-preset grid moved
## buildings, trees and landmarks vertically on a preset switch (AC-12).
## The preset only sets the terrain MESH density (terrain_mesh_posts_for).
const GROUND_POSTS := 256

static func grid_size_for(_value: int) -> int:
	return GROUND_POSTS

## Terrain mesh vertices per side (a LOD knob over the same GroundTruth):
## 25 / 18.9 / 12.6 / 9.4 m spacing; v1 64 posts over 2400 m (38 m)
## flattened every street-scale slope.
static func terrain_mesh_posts_for(value: int) -> int:
	return [96, 128, 192, 256][clamp_preset(value)]

## z8 far-tile height grid: preset-independent too (the far rings and
## far landmark bases sample it); FarTerrainBuilder.RING_SEGS is the
## per-preset far mesh LOD.
static func far_grid_size_for(_value: int) -> int:
	return 128

## Esri World Imagery zoom per preset (contract §2.3, T2.2): 16 Fast/Balanced,
## 17 High and Ultra. T7.0: the mosaic must cover the 2400 m extent, and
## z18 over 2.4 km is 25–33 tiles a side (6400+ px, >120 MB) — past any
## mobile texture budget — so Ultra shares z17 and spends its time on
## the finer DEM grid instead.
static func satellite_zoom_for(value: int) -> int:
	return [16, 16, 17, 17][clamp_preset(value)]

## Largest mosaic side in tiles (15 × 256 = 3840 px ≤ the 4096 px
## mobile texture limit).
const SATELLITE_MAX_SPAN := 15

## Satellite mosaic span (tiles per side, odd so the viewpoint tile stays
## centred) covering the detailed extent plus one tile of slack for the
## viewpoint's offset inside its tile, at the place's latitude (tiles
## shrink with cos(lat)). Paris: z16 7, z17 13; Turku z17 hits the cap
## (≈2.3 km, the edge band fades to the far drape there).
static func satellite_span_for(value: int, lat: float = 0.0) -> int:
	var zoom := satellite_zoom_for(value)
	var tile_m := 156543.03392 * cos(deg_to_rad(lat)) / pow(2.0, float(zoom)) * 256.0
	var span := int(ceil((WorldScale.DETAILED_EXTENT_M + tile_m) / maxf(tile_m, 1.0)))
	if span % 2 == 0:
		span += 1
	return clampi(span, 3, SATELLITE_MAX_SPAN)

## Real OSM buildings placed, nearest first. T7.0: raised for the 2400 m
## extent (v1 caps covered ~250 m); past LodRing.MERGE_M they merge per
## material, so draw cost stays bounded. Past the cap the farthest real
## buildings become batched impostor masses (T7.3) — never dropped.
static func max_buildings_for(value: int) -> int:
	return [600, 1200, 2500, 6000][clamp_preset(value)]

static func vegetation_count_for(value: int, urban: bool) -> int:
	if urban:
		return [70, 120, 170, 380][clamp_preset(value)]
	return [90, 170, 230, 500][clamp_preset(value)]

static func procedural_buildings_for(value: int) -> int:
	return [40, 65, 90, 200][clamp_preset(value)]

# --- Frame budgets (paid every frame in the 360 view) ---

## Ceiling for QualityGovernor: it may step down from here under low
## FPS, and back up to here — never past the user's chosen ceiling.
static func render_scale_for(value: int) -> float:
	return [0.65, 0.85, 1.0, 1.25][clamp_preset(value)]

static func shadows_for(value: int) -> bool:
	return clamp_preset(value) > Preset.FAST

## Shadow reach (metres) and softness per preset; only Ultra pays for
## far, sharp shadows. T7.0: the v1 600 / 1000 units were 2400 / 4000 m
## on the 4 m-unit world; the same reach in metres.
static func shadow_distance_for(value: int) -> float:
	return [2400.0, 2400.0, 2400.0, 4000.0][clamp_preset(value)]

static func shadow_blur_for(value: int) -> float:
	return [1.8, 1.8, 1.8, 1.0][clamp_preset(value)]

## FBM octaves for the sky shader's cloud deck (AtmosphereRig): the
## per-pixel sky cost. Coverage and colour are identical at every tier;
## only fine edge detail changes.
static func cloud_octaves_for(value: int) -> int:
	return [3, 4, 5, 5][clamp_preset(value)]

## Human-readable cost summary for the settings screen: the tier, its
## time budget, then what it renders, e.g. "High · Fidelity 2 · first
## build ≤75 s, revisit ≤5 s · 192×192 terrain · …".
static func summary_for(value: int) -> String:
	var p := clamp_preset(value)
	return "%s · Fidelity %d · first build %s, revisit %s · %d×%d terrain · %d full-detail buildings (the rest as distant masses) · %d trees · shadows %s · %.0f%% render scale" % [
		preset_name(p), fidelity_for(p), FIRST_BUILD[p], REVISIT[p],
		terrain_mesh_posts_for(p), terrain_mesh_posts_for(p), max_buildings_for(p),
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
