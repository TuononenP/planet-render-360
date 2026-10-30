# World Model Contract v2

> Frozen by **T0.3** (plan: `.agents/plans/2026-10-28-real-location-fidelity-redesign.md`
> §4). This is the shared contract for Phases 1–8. Per the plan's
> contract-first rule (§2.2), any change to `LocationData` fields,
> `GenerationPipeline` stage order, or `RenderSettings.Preset` semantics
> requires a Phase 0 contract task first, and all consuming roles must
> re-read this document before editing.
>
> Status terms: **v1** = code as of 2026-10-28 (squashed vertical scale,
> 220-unit world, AABB buildings). **v2** = this contract, implemented
> across Phases 1–2 and consumed by Phases 3–7. §7 lists every v1
> deprecation with its removal phase.
>
> Companion docs: [data-source register](data-source-register.md) (every
> fetch traces to a `verified` row) · [fidelity scorecard](fidelity-scorecard.md)
> (checks a–f that prove the contract holds).

## 0. Conventions used in this document

- **Owner** = the role (§2.1) that may edit the producer; **consumers** =
  roles/classes that read the value and must be updated when it changes.
- All v2 geometry is in **true metres** (§1). A field marked `(m)` is
  metres; `(m ASL)` is metres above sea level as decoded from the source
  tile; `(render Y)` is metres relative to the render origin (§1.3).
- `scripts/generation/ground_truth.gd` does not exist yet (verified
  2026-10-28); it is created in T1.4. `scripts/generation/world_scale.gd`
  is created in T1.2. Until those land, v1 code paths stay as-is.

## 1. Units and the WorldScale convention

### 1.1 One unit is one metre

v2 eliminates the two v1 scale fictions:

- v1 `OsmFetcher.WORLD_SCALE = 0.25` / `TerrainBuilder.METRES_TO_WORLD`
  (220 world units ≈ 880 m) is replaced by identity: **1 internal unit =
  1 metre** end-to-end (fixes D1/D2).
- v1 adaptive vertical squash (`pipeline.gd::_fetch_dem`,
  `vscale = clampf(30.0 / relief, 0.02, 0.35)`) is replaced by identity:
  **1 m of relief = 1 unit of height**. Vertical exaggeration, if ever
  wanted, is a *view* option in `AtmosphereRig`/`CameraRig`, never baked
  into world data (plan invariant 1).

Axes (unchanged from v1 `OsmFetcher.local_xz`): **+X = east, +Z = south**
(north = −Z). `x = east_m`, `z = −north_m`.

### 1.2 Horizontal extent

- `WorldScale.DETAILED_EXTENT_M := 2400.0` — the detailed (near-field)
  world is 2400 m across by default (Phase 1 default; per-preset values
  land in Phase 7, plan Open Q1). Replaces v1 `WORLD_SIZE = 220.0`.
- Far terrain continues as concentric DEM rings (z12 mid → z8 far, to
  ≥9 km) in T3.3; the v1 flat apron + silhouette ring remain only as a
  sub-horizon gap filler.

### 1.3 Render-origin rebasing

Metre coordinates far from the origin lose float precision in shaders.
`WorldScale` (new `scripts/generation/world_scale.gd`, owner **B**) owns
all conversions and the render origin:

| API | Signature | Notes |
|---|---|---|
| `xz_from_latlon` | `static func xz_from_latlon(lat: float, lon: float, c_lat: float, c_lon: float) -> Vector2` | Metre XZ relative to centre `(c_lat, c_lon)`; replaces `OsmFetcher.local_xz` (T1.2) |
| `latlon_from_xz` | `static func latlon_from_xz(x: float, z: float, c_lat: float, c_lon: float) -> Vector2` | Inverse, for attribution/UV round-trips |
| `set_origin` | `func set_origin(lat: float, lon: float, elevation_m: float) -> void` | Called once per place by the pipeline |
| `to_render` | `func to_render(metre_pos: Vector3) -> Vector3` | `metre_pos − origin` (horizontal + `origin_elevation_m` on Y) |
| `DETAILED_EXTENT_M` | `const DETAILED_EXTENT_M := 2400.0` | §1.2 |

- The pipeline sets the origin at the viewpoint (`lat`, `lon`,
  `centre_elevation_m`). Builders emit metre geometry; the caller (or a
  single root offset) applies `to_render`, so the camera always works
  near the float sweet spot.
- Origin updates, if ever needed mid-session (teleport), move in whole
  steps and re-emit the world — no per-frame origin drift.

## 2. LocationData fields (extended for Phase 2)

Owner of the file: **A**. Every field below lists its v2 type, producer,
and consumers. Fields marked **new** do not exist in v1 and are added by
the named task; unmarked fields exist in v1 and change meaning/units as
stated (see §7 for the deprecation schedule).

### 2.1 Identity and framing (unchanged semantics)

| Field | Type | Producer → consumers | Notes |
|---|---|---|---|
| `place_name` | `String` | pipeline → UI, builders | Unchanged |
| `latitude`, `longitude` | `float` | pipeline → fetchers, WorldScale | Viewpoint; degrees. Unchanged |
| `quality_preset` | `int` (`RenderSettings.Preset`) | pipeline ← settings → all builders | Unchanged until T7.4 redefines tiers as fidelity tiers |
| `seed_value` | `int` | pipeline → builders | Deterministic fallback RNG only. Unchanged |
| `attribution` | `String` | pipeline ← fetchers → UI | Unchanged; every source needs a register row |
| `season` | `int` (`Season`) | UI → builders | Unchanged until T6.3 wires it into materials/scatter |

### 2.2 Elevation (v2: true metres ASL)

| Field | Type | Producer → consumers | Notes |
|---|---|---|---|
| `heights` | `PackedFloat32Array`, `grid_size²` | DemFetcher via pipeline → **GroundTruth only** (T1.4) | **Unit change (T1.3):** absolute **m ASL** as decoded (bilinear from the T2.1 mosaic), sampled over `DETAILED_EXTENT_M`. No squash. Builders must not read it directly after T1.4 (grep gate) |
| `grid_size` | `int` | RenderSettings → DemFetcher, GroundTruth | Unchanged |
| `relief_metres` | `float` | pipeline → builders, scorecard | Unchanged; now consistent with `heights` by construction |
| `centre_elevation_m` **(new)** | `float` | pipeline → GroundTruth, WorldScale | m ASL at the viewpoint; render-Y datum (§1.3). Added T1.3 |
| `display_heights` | `PackedFloat32Array` | TerrainBuilder (lazy) → builders | **Deprecated:** becomes `GroundTruth` construction in T1.4; field removed then (§7) |
| `water_level` | `float` | pipeline → builders | **Unit change (T1.3):** m ASL. Removed as a global once `GroundTruth.water_at` lands (T1.4/T3.4); per-point water wins |
| `far_heights` | `PackedFloat32Array`, `far_grid_size²` | DemFetcher via pipeline → FarTerrainBuilder | **Unit change (T1.3):** m ASL |
| `far_grid_size` | `int` | RenderSettings → DemFetcher | Unchanged |
| `far_extent` | `float` | pipeline → FarTerrainBuilder | **Deprecated (world units):** replaced by `far_extent_m`, removed T3.3 |
| `far_extent_m` **(new)** | `float` | pipeline → FarTerrainBuilder | Metres spanned by the far tile. Added T1.3 alongside the unit cutover |
| `far_centre_frac` | `Vector2` | DemFetcher → FarTerrainBuilder | Unchanged (0..1 fraction) |
| `dem_source` **(new)** | `Dictionary` | DemFetcher → scorecard (F), B | `{zoom_near, zoom_mid, zoom_far, span_near, metres_per_px, tile_count}`. Added T2.1 |
| `dem_rings` **(new)** | `Array[Dictionary]` | FarFieldFetcher via pipeline → FarTerrainBuilder | Far-field DEM windows, finest first: `{zoom, origin_px: Vector2, width, height, heights: PackedFloat32Array, reach_m}` — m ASL in row-major Web-Mercator pixels at `zoom`; `origin_px` = global px of the window's top-left pixel corner (pixel centres at +0.5). Default layers ~12.5 m/px (z13 mid-latitudes) to 4 km, ~25 m/px (z12) to 9.5 km, ~100 m/px (z10) to 33 km, zoom picked per latitude by target m/px. All-or-nothing per layer; empty when the DEM is procedural, offline-uncached, or under `legacy_squash`. Builders fall back ring → coarser ring → `far_heights`. Added T3.7 |

### 2.3 Satellite imagery

| Field | Type | Producer → consumers | Notes |
|---|---|---|---|
| `satellite_texture` | `Texture2D` | SatelliteFetcher → terrain material | Unchanged type; resolution follows the T2.2 preset→zoom map |
| `satellite_image` | `Image` | SatelliteFetcher → BuildingBuilder (roof sampling, T4.3) | Unchanged type; matches mosaic resolution in v2 |
| `satellite_origin_px` | `Vector2` | SatelliteFetcher → builders | Unchanged (global pixels at `satellite_zoom`) |
| `satellite_zoom` | `int` | pipeline ← RenderSettings → SatelliteFetcher | v2 values: 16 Fast/Balanced, 17 High, 18 Ultra (T2.2) |
| `satellite_metres_per_px` **(new)** | `float` | SatelliteFetcher → B, C | Derived from zoom + latitude; UV/alignment math uses this, not magic spans. Added T2.2 |
| `satellite_source` **(new)** | `Dictionary` | SatelliteFetcher → scorecard (F) | `{zoom, span, tile_count, metres_per_px, source_zoom, source_span}`; empty when the fetch failed or Fast skipped it. Added by amendment 2026-10-28 (T2.x closure W1) |
| `far_drapes` **(new)** | `Array[Dictionary]` | FarFieldFetcher via pipeline → FarTerrainBuilder | Far-field Esri imagery windows, finest first: `{zoom, origin_px: Vector2, size_px: Vector2i, texture: Texture2D (mipmapped), reach_m}`; UV = (global_pixel(lat, lon, zoom) − origin_px) / size_px, the same Mercator mapping as `TerrainBuilder.satellite_uv`. Default ~12 m/px (z13) to 9.5 km, ~50 m/px (z11) to 33 km, ~200 m/px (z9) to 60 km. Empty on Fast (like the near drape) or when unavailable → colour-ramp fallback (rock by slope, snow by altitude+latitude+season, forest/meadow below treeline). `FarTerrainBuilder.far_albedo_at(data, nrm, h_asl, water, x, z)` returns the linear far albedo the rings render (drape, else ramp) — the near-ground edge band fades to it. Added T3.7 |

### 2.4 Buildings (v2: full footprints + rich tags, T2.3)

`buildings: Array` of `Dictionary`, one per OSM building. Producer:
OsmFetcher (**A**). Consumers: BuildingBuilder (**C**), RoadBuilder
(avoidance), VegetationBuilder (exclusion), scorecard checks (b)/(c)
(**F**). All XZ/size values in **metres** after the T1.2 unit cutover.

| Key | Type | Required | Notes |
|---|---|---|---|
| `footprint` **(new)** | `PackedVector2Array` | yes (v2) | Full OSM polygon in metre XZ (rotation, L/T/courtyard shapes preserved). AABB keys below stay as the corrupt-geometry fallback only |
| `x`, `z` | `float` | yes | Polygon centroid, metre XZ (v1: world units) |
| `size_x`, `size_z` | `float` | yes | AABB size in **metres** (v1: world units); fallback path only |
| `height` | `float` | yes | **Metres** (unchanged unit); resolution order in T4.2: `height` tag → `levels × regional floor height` → estimate → documented regional default — never a global 10 m |
| `height_source` **(new)** | `String` | yes | `tag_height` \| `levels` \| `estimate` \| `default`; scorecard (c) stratifies on this |
| `levels` **(new)** | `int` | no | `building:levels`, 0 = untagged |
| `min_height_m` **(new)** | `float` | no | `min_height` tag (arcades, pilotis); 0 = ground |
| `colour` **(new)** | `String` | no | `building:colour` raw tag; MaterialLibrary resolves |
| `material` **(new)** | `String` | no | `material` tag (`brick`, `glass`, …) |
| `roof_shape` | `String` | no | v1 key kept; v2 honours `flat/gabled/hipped/mansard/pyramidal/dome` (T4.2) |
| `roof_colour`, `roof_material` **(new)** | `String` | no | `roof:colour`, `roof:material` tags |
| `roof_height_m` **(new)** | `float` | no | `roof:height` tag; 0 = unknown |
| `parts` **(new)** | `Array` | no | `building:part` sub-polygons, same height/colour keys; empty = single mass |
| `name` | `String` | no | v1 key kept |

### 2.5 Roads (v2: attributed centrelines, T2.3; geometry T4.4)

`roads: Array` of `Dictionary` (v1: bare `PackedVector2Array` per road).
Producer: OsmFetcher (**A**). Consumer: RoadBuilder (**C**), scorecard
(d) (**F**).

| Key | Type | Notes |
|---|---|---|
| `points` | `PackedVector2Array` | Centreline in metre XZ (v1: the whole element was this, in world units) |
| `width_m` **(new)** | `float` | From `width` tag, else `lanes × 3.0`, else class default table |
| `lanes` **(new)** | `int` | 0 = untagged |
| `surface` **(new)** | `String` | `asphalt`, `sett`, `gravel`, …; "" = unknown |
| `bridge`, `tunnel` **(new)** | `bool` | From `bridge`/`tunnel` tags |
| `layer` **(new)** | `int` | `layer` tag; 0 default |
| `class` **(new)** | `String` | `motorway` … `footway` (the `highway` value) |

Migration: builders accept a bare `PackedVector2Array` element (v1) as
`{points, width_m: 6.0, class: "unclassified"}` until T4.4 removes the
v1 shape (§7).

### 2.6 Land cover, water, trees (T2.3/T2.4)

`land_polygons: Array` of `Dictionary`. Producer: OsmFetcher (**A**).
Consumers: VegetationBuilder (**D**), WaterBuilder (**B**),
TerrainBuilder (**B**), scorecard (d) (**F**).

| Key | Type | Notes |
|---|---|---|
| `class` | `String` | v1 set `water/forest/grass/field/urban` **plus** T2.4: `wetland/sand/rock/glacier/orchard/cemetery/pitch/quarry`. Unmapped tags are documented in the register, never silently dropped |
| `points` | `PackedVector2Array` | Polygon ring in metre XZ (v1: world units) |
| `holes` **(new)** | `Array[PackedVector2Array]` | Inner rings / multipolygon holes; empty = solid |

New top-level fields:

| Field | Type | Producer → consumers | Notes |
|---|---|---|---|
| `waterways` **(new)** | `Array` of `{points: PackedVector2Array, width_m: float, class: String}` | OsmFetcher → WaterBuilder, GroundTruth carve | `waterway` lines (river/stream/canal) + coastline ways; metre XZ. Added T2.3, meshed T3.4 |
| `trees` **(new)** | `Array` of `{x: float, z: float}` | OsmFetcher → VegetationBuilder | Real `natural=tree` nodes, metre XZ. Added T2.3, planted T5.1 |
| `barriers` **(new)** | `Array` of `{points: PackedVector2Array, class: String}` | OsmFetcher → Phase-4/5 consumer (unclaimed) | Linear `barrier=*` features (fence, wall, hedge, …), metre XZ; `class` = raw tag value. Added by amendment 2026-10-28 (T2.x closure W1); pipeline wiring landed (closure W2, 2026-10-28) |

### 2.7 Landmarks

| Field | Type | Producer → consumers | Notes |
|---|---|---|---|
| `landmark_type` | `String` | pipeline ← `LocationData.landmarks()` registry | Unchanged until T5.2 true-placement work |
| `has_landmark_site`, `landmark_lat`, `landmark_lon` | `bool`, `float`, `float` | pipeline → builders | Unchanged (degrees) |
| `landmark_candidates` | `Array` of `Dictionary` | OsmFetcher → LandmarkBuilder (**D**) | **Unit change (T1.2):** `x/z/size_x/size_z` become metres; keys otherwise unchanged (`archetype/name/height`, height already metres) |

> **Amendment 2026-10-28 (T2.x closure W1, Phase-0 contract task):** §2
> gains two fields the T2.3 exit review found parsed-but-homeless:
> `satellite_source` (§2.3, SatelliteFetcher provenance dict) and
> `barriers` (§2.6, linear `barrier=*` features). Both live on
> `LocationData` (owner **A**); producer/consumer columns are in the
> tables above. `dem_source` (§2.2) and `satellite_metres_per_px`
> (§2.3) were already specified here — closure W1 only lands them on
> `LocationData` (they sat on `GenerationPipeline` pending this move)
> and closure W2 (owner **E**) rewires the pipeline + sole test reader
> (`tests/dem_test.gd: pipe.dem_source`) onto them.

> **Amendment 2026-10-28 (T5.4 far city, @C+B/farcity):** §2.6 gains
> two far-ring fields, producer `FarCityFetcher` (one cached Overpass
> request per place, 12 km `around`) via pipeline stage 2
> (`_await_far_city`, bounded 30 s, absence = empty arrays):
> `far_landuse: Array` of `{class: residential|commercial|industrial|
> retail, points: PackedVector2Array, holes: Array}` and `far_towers:
> Array` of `{footprint, x, z, height, levels, kind}` (real buildings
> ≥ 50 m or ≥ 15 levels), metre XZ. Consumers: `SettlementMap` →
> `FarCityBuilder` (far fabric + the only source of far towers) and
> `InfillPlanner` (T4.5 settlement evidence). Empty = the far city
> continues from the far imagery drapes alone.

> **Amendment 2026-10-30 (§2.7 climate):** `LocationData.climate:
> Dictionary` — CHELSA V2.1 1981–2010 normals at the viewpoint (3 × 3
> cell median): `t_warm_c`, `t_cold_c` (warmest / coldest quarter mean,
> °C), `precip_mm`, `precip_warm_mm`, `snow_days`, `source`. Producer
> `ClimateFetcher` via the pipeline (`_await_climate`, bounded 15 s,
> absence = `{}`). Sole interpreter `ClimateModel` (snow line per season,
> treeline, biome, summer dryness, snow uniforms); consumers FarSurface,
> GroundMaterial, TreeSpecies/VegetationBuilder, WorldCache key. Empty =
> latitude fallbacks (invariant 3: real data first, rules only on absence).

## 3. GroundTruth API (new, T1.4)

One smoothed/carved height + water + land-cover surface, built once per
place from DEM + OSM polygons + waterways. It replaces the v1
`TerrainBuilder._heights` / `display_heights` lazy path and every
per-builder height recomputation (plan invariant 2).

- File: `scripts/generation/ground_truth.gd` (does not exist yet).
  Owner: **B**. Consumers: **every builder**, `View360` spawn height.
- Construction: `GroundTruth.new(data: LocationData)` builds the surface
  synchronously from `data` (DEM + polygons + waterways); the pipeline
  constructs it once after fetch stages complete and passes it to every
  builder. Construction cost is a pipeline stage with real progress
  (§3.1 of the plan).
- After T1.4, no builder reads `data.heights` / `data.display_heights`
  directly (grep gate in test, per T1.4 validation).

| API | Signature | Semantics |
|---|---|---|
| `height_at_world` | `func height_at_world(x: float, z: float) -> float` | Final render Y (**metres**, origin-relative, §1.3) at metre XZ: smoothed DEM, flattened only where OSM says so (building pads, roads), water-carved channels applied. Clamped to the detailed extent |
| `water_at` | `func water_at(x: float, z: float) -> float` | Water depth in **metres** at XZ; `0.0` = dry. Covers water polygons, waterway lines (width-aware), and DEM sinks below sea datum |
| `land_class_at` | `func land_class_at(x: float, z: float) -> String` | v2 land class (§2.6, incl. `""` = unknown) at XZ; builders use it for material choice, scatter rules, and exclusion (no trees on roads/buildings/water) |
| `slope_at` | `func slope_at(x: float, z: float) -> float` | Slope gradient (rise over run, `0.0` = flat) from true-metre heights; drives normals, drape tint cap, and snow/vegetation rules |
| `extent_m` | `var extent_m: float` | Half-extent in metres of the detailed surface (`DETAILED_EXTENT_M / 2`) |
| `is_inside` | `func is_inside(x: float, z: float) -> bool` | Whether XZ is on the detailed surface (else sample the far-ring surface) |

Sampling rules: bilinear interpolation between grid posts; outside →
nearest-edge value (never NaN); all samplers are pure reads (no lazy
mutation — the v1 `display_heights` lazy-fill race is gone).

## 4. Builder input/output signatures (v2 target)

Common rules: every builder takes `(data: LocationData, ground:
GroundTruth)` first, emits metre-space `Node3D` subtrees (the caller
applies the render origin, §1.3), samples ground/water/cover **only**
through `GroundTruth`, and runs procedural fallback strictly on
absence of real data for its layer (plan invariant 3, no-faked-fidelity
rule). Material construction lives in `MaterialLibrary`, never inline.

| Builder (owner) | v2 signature | Output | Lands in |
|---|---|---|---|
| `TerrainBuilder` (B) | `static func build_world(data: LocationData, ground: GroundTruth) -> Node3D` | Orchestrator root: detailed mesh + child-builder subtrees. Target ≤ ~350 lines | T1.1c + T1.4 |
| `FarTerrainBuilder` (B) | `static func build_far(data: LocationData, ground: GroundTruth) -> Node3D` | DEM-ring meshes + skirts + gap-filler apron | T1.1b, geometry T3.3 |
| `WaterBuilder` (B) | `static func build_water(data: LocationData, ground: GroundTruth) -> Node3D` | Water surfaces, banks/quays; no water data → empty node + logged note | T1.1b, real water T3.4 |
| `BuildingBuilder` (C) | `static func build_buildings(data: LocationData, ground: GroundTruth, mats: MaterialLibrary) -> Node3D` | True-footprint extrusions (§2.4) + absence-only infill (T4.5) | T1.1c, fidelity T4.1–T4.3 |
| `RoadBuilder` (C) | `static func build_roads(data: LocationData, ground: GroundTruth, mats: MaterialLibrary) -> Node3D` | Ribbon geometry on `GroundTruth` (≤0.05 m offset), bridges/tunnels honoured | T1.1c, fidelity T4.4 |
| `MaterialLibrary` (C) | `class MaterialLibrary extends RefCounted` — `func facade_material(style: String, storeys: int) -> Material`, `func roof_material(kind: String, colour_hint: Color) -> Material`, `func ground_material(class: String) -> Material`, `func water_material() -> Material` (+ PBR sets in T4.3) | Shared `Material` resources (≤6 distant facade/roof materials, PRD §6); no nodes | T1.1a, PBR T4.3 |
| `VegetationBuilder` (D) | `static func build_vegetation(data: LocationData, ground: GroundTruth, mats: MaterialLibrary) -> Node3D` | `MultiMeshInstance3D` scatter from cover + real trees (§2.6); 0 trees on roads/buildings/water | T1.1c, fidelity T5.1 |
| `LandmarkBuilder` (D) | `static func build(type: String) -> Node3D` (kept); `static func build_archetype(archetype: String, height_m: float, footprint_m: Vector2) -> Node3D` | Model at origin, true scale; **placement by the caller via WorldScale** — no internal clamp or apparent-size rescale after T5.2 | exists; true placement T5.2, GLB pass T5.3 |

`RenderSettings` (owner **E**) keeps sizing grids/budgets per preset; it
gains the preset→(DEM zoom, satellite zoom, OSM radius, LOD radii) maps
in T2.2/T7.4 but never moves geometry (plan invariant 5: preset changes
layout by 0, hue by ≤2%).

## 5. Cache key v2 (implemented T2.5)

v1 keys are unversioned and unstructured: `dem_{z}_{x}_{y}.png`
(`dem_fetcher.gd`), `sat_{z}_{x}_{y}.jpg` (`satellite_fetcher.gd`),
`osm3_{lat×1000}_{lon×1000}.json` (`osm_fetcher.gd`); no size cap, no
per-layer invalidation.

v2 key grammar (all under `user://cache/`):

```text
dem_v<V>_<z>_<x>_<y>.png          # one Terrarium tile (T2.1 mosaics fetch many)
sat_v<V>_<z>_<x>_<y>.jpg          # one Esri tile (T2.2 mosaics fetch many)
osm_v<V>_<lat_q>_<lon_q>_r<radius_m>.json   # one Overpass area response
```

- `<V>` = `CacheStore.DATA_VERSION` (`const DATA_VERSION := 2`, owner
  **A**; single source — fetchers format keys through it, never inline).
- Area quantisation for OSM stays `round(deg × 1000)`; the radius suffix
  keeps preset-scaled queries (T2.3) from colliding.
- Invalidation: bump `DATA_VERSION` (global) or delete one layer prefix
  (per-layer refresh). v1 files are **ignored, never migrated** — a v2
  client missing a v2 key refetches (§7).
- `CacheStore` (owner **A**, with **E** for history plumbing) enforces
  an LRU size cap and per-layer invalidation; history entries reference
  v2 keys. Offline revisit of a cached place renders identically with
  networking disabled (T2.5 validation).

## 6. Pipeline staging (unchanged order, extended content)

`GenerationPipeline` stage order is frozen (owner **E**, staging only);
v2 extends what each stage fetches/builds, within the §3.1 tier budgets:

1. Fetching elevation — T2.1 mosaic (+ far ring, overlapped as today).
2. Mapping land cover — T2.2 satellite drape + T2.3 OSM area query
   (overlapped as today).
3. Placing landmarks — OSM await + `GroundTruth` construction (new, T1.4).
4. Adding vegetation — builders run in dependency order (terrain →
   water → buildings/roads → vegetation → landmarks).
5. Finalizing lighting — bake steps (AO/atlas/impostors on High/Ultra,
   Phase 7) → first frame.

Cancel returns to the picker within 1 s at any point; progress is real
per-stage work (items done/total, elapsed), never a fake timer — the
1–2 minute Ultra budget must be legible (plan §3.1, R6).

## 7. v1 deprecations and removal phases

"Removed" = symbol deleted or converted to the v2 meaning; the named
task's validation must fail if the v1 behaviour survives. Read "T1.x"
as "during that task, before its tick".

| # | v1 symbol / behaviour | v1 meaning | v2 replacement | Removed in |
|---|---|---|---|---|
| V1 | `GenerationPipeline._fetch_dem` adaptive squash (`vscale = 30/relief`) | Relief remapped to ~30 units everywhere (D1) | Identity metres + `centre_elevation_m` (§2.2); `legacy_squash` flag (default off) kept for A/B until T3.1, then deleted | T1.3 |
| V2 | `LocationData.heights` as squashed world units | World-space heights | Absolute m ASL (§2.2) | T1.3 |
| V3 | `LocationData.water_level` as world units | Global world-space plane | m ASL now; per-point `GroundTruth.water_at` wins from T1.4; global removed | T1.4 |
| V4 | `OsmFetcher.WORLD_SCALE` (0.25) | Metres→world factor (D2) | `WorldScale.xz_from_latlon`, identity (§1) | T1.2 |
| V5 | `TerrainBuilder.METRES_TO_WORLD` | Same factor, consumer side | `WorldScale` (§1) | T1.2 |
| V6 | `TerrainBuilder.WORLD_SIZE` (220.0) | Detailed extent in world units | `WorldScale.DETAILED_EXTENT_M` = 2400 m (§1.2) | T1.2 |
| V7 | All v1 XZ/size fields in world units (buildings, roads, land, candidates) | 0.25 m/unit | True metres (§2.4–§2.7) | T1.2 (unit cutover) |
| V8 | `LocationData.display_heights` lazy path (`_heights`) | Builders share a lazily-mutated array | `GroundTruth` built once (§3) | T1.4 |
| V9 | `LocationData.far_extent` (world units) | Far span in world units | `far_extent_m` (§2.2) | T3.3 |
| V10 | `SatelliteFetcher` fixed `SPAN=3`, z16 | ~1.2 km drape at all tiers (D7) | Preset→zoom/span map, z16/17/18 (§2.3) | T2.2 |
| V11 | `DemFetcher` single-tile 144 px window (`ZOOM=12`) | Coarse source at every grid (D3) | z14 near mosaic + z12 mid + z8 far (§2.2) | T2.1 |
| V12 | `OsmFetcher` `RADIUS_M=420`, `out geom 900`, narrow tag set | Small, tag-poor fetch (D8) | Preset-scaled radius (≥800 m detailed), tiered queries, full tags (§2.4–§2.6) | T2.3 |
| V13 | Roads as bare `PackedVector2Array` | Unattributed centreline | Attributed road dicts (§2.5); v1 shape accepted with defaults until removal | T4.4 |
| V14 | Buildings as AABB-only (no `footprint`) | Rotated/L-shaped fabric lost (D5) | Full `footprint` polygons (§2.4); AABB keys stay permanently as the corrupt-geometry fallback | T2.3 (fallback stays) |
| V15 | `landmark_world_pos` clamp (≤95 u) + `sqrt` apparent-size rescale | Framing-corrected placement (D10) | True metre offset/scale via WorldScale (§4); camera handles framing | T5.2 |
| V16 | Synthetic `_river_path` S-curve river | Procedural river over/under real data (D9) | Real water (§2.6) or gated absence-only fallback with a user-visible note | T3.4 |
| V17 | Procedural Haussmann infill + silhouette ring alongside real data | Additive filler contradicting OSM (D9) | Absence-only, style-matched infill (T4.5); data-driven far continuation (T5.4) | T4.5 / T5.4 |
| V18 | Unversioned cache keys (`dem_…`, `sat_…`, `osm3_…`) | No version, no cap, collisions across radii | Cache key v2 + LRU + per-layer invalidation (§5); v1 files ignored | T2.5 |
| V19 | `LandmarkBuilder` callers passing world-unit footprints | `footprint: Vector2` in world units | `footprint_m: Vector2` in metres (§4) | T5.2 |

> **Amendment 2026-10-28 (T2.x closure W1):** §2.3 `satellite_source`
> and §2.6 `barriers` are additive only — no v1 symbol is renamed or
> removed, so no V-row is added here. The transitional
> `GenerationPipeline.dem_source` / `.satellite_source` /
> `.satellite_metres_per_px` holders (documented in `pipeline.gd` as
> "held here until the v2 field move") are deleted by closure W2
> (owner **E**), which rewires the pipeline to write the new
> `LocationData` fields and migrates the sole reader
> (`tests/dem_test.gd: pipe.dem_source`).

## 8. Conformance gates (how we know the contract holds)

- **Contracts before visuals:** fetchers normalise into §2 shapes;
  generation never parses provider payloads (grep gate from Phase 2
  exit onwards).
- **One ground truth:** after T1.4, no builder reads `data.heights` /
  `data.display_heights` directly (grep gate); probe test — building,
  tree, and terrain agree within 0.05 m at 50 points/location.
- **True scale:** `world_scale_test.gd` (T1.2) asserts lat/lon offsets →
  metre XZ within 0.5 m at golden locations; DEM spot heights match
  source metres (scorecard a).
- **Layout-stable tiers:** preset switch moves 0 objects, hue ≤2%
  (plan invariant 5, asserted T7.1/T7.4).
- **No faked fidelity:** every fallback is absence-gated in the same
  task that adds it (§2.2 of the plan); a location with no water
  renders no river.
- **Budgets:** generation fits the §3.1 tier budget (Ultra 60–120 s
  cold is a pass); every class ≤1000 lines
  (`tools/check_class_size.sh`); `tests/smoke_test.gd` stays green.
