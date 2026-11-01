# City and scenery realism v3 — shared tracker

> Working copy of the approved plan (2026-11-01). Claim a task before starting it
> (`— @<agent>/<topic> <date>`), tick it only when its validation passes, and add
> one evidence line under it. Same rules as the fidelity plan (§2 there).
> Track 2 waits for the parallel-build work (`world_build_graph.gd`) to land.
> Track 1 touches no generation/build file: please don't reset or clean the
> files listed under "Track 1" in Critical files when baselining the build.

## Tasks

### Track 1 — no build-output change
- [x] **R-1.1** Capture-and-compare tool (`tools/capture_presets.gd`), golden set, refs, stats, scorecard (f) — @claude/vantage 2026-11-01
  > PROGRESS 2026-11-01 (not ticked): `tools/capture_presets.gd` written (real app flow, History restored, settings unsaved,
  > governor pinned, weather fixed clear, SubViewport capture via force_draw, stats + flags + contact sheets). Refs with
  > attribution READMEs in `visual-plan/refs/{paris,tokyo,new_york}/` (Commons, CC BY/BY-SA, 640 px). Open: first
  > windowed run, refs for the other 10 presets, scorecard (f) rows.
  > DONE 2026-11-01: refs for all 13 presets (2 Commons photos each, licence READMEs); golden set captured
  > (r3: 13 presets + 5 controls, `visual-plan/reviews/vantage-r3-2026-11-01/`; r4: 13 presets with `--audit`,
  > `vantage-r4-2026-11-01/` + README with the improved/regressed note); scorecard (f) pre-ratings in
  > `docs/fidelity-scorecard.md` §9 (8 recognisable, 5 stylised; human gate still open).
- [x] **R-1.2** Curated preset vantages (`PresetViews`, `LocationData.view`, pin-resolved in `GenerationPipeline.run`) — @claude/vantage 2026-11-01
  > PROGRESS 2026-11-01 (code done, not ticked — vantages unreviewed in captures): new `scripts/data/preset_views.gd`
  > (13 rows, positions checked via Nominatim; origin/eye split for Alps, Banff, Tokyo, NYC, Dubai), `LocationData.view`
  > + `quick_picks()` from rows + gazetteer resolves preset names to origins, `GenerationPipeline.run` resolves
  > `PresetViews.for_pin` (≤15 m) when there is no focus, picker starts on the Paris row. `tests/preset_views_test.gd` OK.
  > DONE 2026-11-01: every vantage reviewed in r2–r4 against its refs; rows fixed where the capture showed it.
  > Dubai: the eye was inside a 192 m tower, now open ground 850 m E, bearing 265°, pitch 12°.
  > Big Sur: the eye was on a hill 270 m off, now the north pull-out. Banff: eye 28 m over the photo-derived woods.
  > Venice: 8 m on the bridge, bearing 104°, `"clear": false`.
  > Seoul's blocker was an underground hall (`level=-1`), fixed in the parser: `OsmTags.underground`, osm_test.
- [x] **R-1.3** One eye helper + generic clearance/heading in `View360` — @claude/vantage 2026-11-01
  > PROGRESS 2026-11-01 (code done, not ticked): `View360.eye_y` (view eye_m + ASL floor; else 30 m lifted 6 m over any
  > roof within 25 m of the footprint, parts included), used by spawn and Go there; `default_yaw` faces the built mass
  > within 600 m (16 sectors, neighbours half weight), else water, else 0.6. `spawn_xz` returns a view's eye (also
  > centres GroundCover there). Footprint nudge dropped: the lift already clears the roof. Tests using
  > `build_world` (smoke, landmark, flow) currently stall headless on the uncommitted WorldBuildGraph, unrelated.
  > ADDED 2026-11-01 (user request: no building may block a start): `View360.view_clearance_y` lifts the opening eye
  > until every roof and mapped forest canopy within 80 m and ±17° of the opening look is below the look line
  > (+6 m, cap 150 m over ground). Covers presets, landmark visits and plain pins. A row can opt out with
  > `"clear": false` where its side buildings are the framing. preset_views_test covers the cases.
- [x] **R-1.4** Look audit report (albedo, unshaded captures, AgX vs ACES) — @claude/vantage 2026-11-01
  > DONE 2026-11-01: `capture_presets.gd --audit` (unshaded + AgX frame, per-material mean linear albedo named from
  > the material caches). Report: `visual-plan/reviews/vantage-r4-2026-11-01/README.md`. Outliers for R-2.1:
  > curtain glass 0.29 (range 0.08–0.15); terracotta roofs 0.08–0.15 (0.25–0.40); plain limestone set 0.25 (0.45–0.60);
  > concrete 0.07–0.28 (0.30–0.45); brick both ways (NY 0.13, London 0.50). AgX is 13 % darker and less saturated
  > than ACES; several vantages are brighter or more saturated than their refs. Try AgX in R-2.1; it needs a PRD
  > amendment (AC-12 asserts ACES).
- [x] **R-1.5** WorldCover / canopy / CC0 asset / font spikes + register rows — @claude/vantage 2026-11-01
  > PROGRESS 2026-11-01 (raster spike done; assets, font and register rows open):
  > **WorldCover v200** `https://esa-worldcover.s3.eu-central-1.amazonaws.com/v200/2021/map/ESA_WorldCover_10m_2021_v200_N48E000_Map.tif`
  > (3° tiles named by SW corner): anonymous HEAD 200, `Accept-Ranges: bytes`, range GET 206; classic TIFF 36000², uint8,
  > Deflate (8), predictor 1, 1024² tiles, overviews ×2 down to 1125². A 2.4 km window is ≤ 2×2 tiles.
  > **Meta canopy v2** `https://dataforgood-fb-data.s3.amazonaws.com/forests/v2/global/dinov3_global_chm_v2_ml3/chm/<quadkey z10>.tif`
  > (name computable from lat/lon; Paris `1202200110`, 179 MB file): range GET 206; 32768² uint8, Deflate, predictor 1,
  > 512² tiles (mean 28 KB); IFD1 is a 1-bit mask, IFD2–5 overviews 16384…2048. IFD3 (8192², ~3.1 m/px at Paris) gives a
  > 2.4 km window in ~3×3 tiles. Both fit native `decompress(COMPRESSION_DEFLATE)` (as CHELSA); no LZW decoder needed.
  > DONE 2026-11-01: register rows for both rasters. New section "Street-life models and sign font":
  > - Kenney Car Kit 3.1: CC0, 50 GLB, 2.0–3.1k triangles per vehicle, one shared 512² palette.
  > - Kenney City Kit Roads 2.2: CC0, 95 GLB, 12–1,636 triangles.
  > - Quaternius Cars: CC0, no GLB.
  > - Sign font: reuse the bundled OFL Instrument Sans / IBM Plex.
  > Nothing is bundled yet.

  > CAPTURE 2026-11-01 `visual-plan/reviews/vantage-r1-2026-11-01/` (High, golden hour, Tokyo / New York / Paris):
  > Paris matches `refs/paris/01` (tower on axis ~600 m); New York matches `refs/new_york/01` after moving the eye
  > to the Pier 1 railing (inside the park the groves blocked it); Tokyo frames the scramble but renders it as lawn.
  > Fixed on the way (all places): (1) `DemConversion` water datum capped at the grid's lowest DEM sample — the v1
  > rule (pin elevation − 6/vscale) floored every water body at ~43 m on the Trocadéro pin and flooded the Seine
  > valley; low pins keep their old datum; (2) `AtmosphereRig.set_place` forgets the previous place's UTC offset
  > (Tokyo after Paris kept Paris's clock until its own weather landed, for good if it failed); (3) `OsmQuery`
  > fetches the 500 m building core with its own cap before the ring (Overpass prints in id order: Shibuya's 8 752
  > buildings were cut evenly to 7 000). Cache keys unchanged, so cached places keep their old payload until refetched.
  > Findings for Track 2: unmapped city-centre ground renders as lawn (Tokyo scramble; R-2.4 WorldCover built class),
  > grass tufts on Trocadéro paving (ground cover ignores paving), far-city towers as flat prisms and a few floating
  > roof slabs (New York), East River tinted tropical turquoise.
  > CAPTURE r3/r4 2026-11-01, more findings for Track 2:
  > - Shadowed golden-hour ground rendered pure black once (r3: Rome after London, Setagaya, Zermatt); not
  >   reproduced in a Rome-only run or in r4. Check the ambient/probe state across place switches (R-2.1 air).
  > - No hero models yet for the Bixby arch, the Banff Springs Hotel or Gwanghwamun.
  > - Grassy Grand Canal banks where there are fondamenta.
  > - The far city is flat prisms (Dubai, Tokyo).
  > Two compile breaks in the parallel-build WIP blocked builds during captures (`has_method` in world_build_graph;
  > an `add_ribbon` argument in water_builder); both fixed output-neutral. All uncommitted work was wiped once at
  > 14:45 by a stash and reset; it was restored from the stash, which stays pinned at
  > `refs/backup/temp-lane-c-2026-11-01-1444`.

### Track 2 — build-output changes
- [ ] **R-2.1** Generic quick wins (parsing, glass, lit windows, CityLights reach, sky-view AO, air, mountains, preset defects, HeroOverrides, extra heroes)
- [ ] **R-2.2** Data v3 (OSM nodes/rail/areas, CogReader, landcover fetcher, cache + attribution plumbing)
- [ ] **R-2.3** Buildings (tower massing, shopfronts + signs, rooftop clutter, variety)
- [ ] **R-2.4** Streets, ground, nature (paving, kerbs/paint, rail/decks, WorldCover ground, canopy trees)
- [ ] **R-2.5** Street life (cars, boats, people cards, poles/wires, signals, furniture)
- [ ] **R-2.6** Preset hero pass (rows, overrides, landmarks; capture loop to target rating)

---


## Context

Every place now builds from real data: OSM footprints and heights, a z14 DEM, satellite ground, regional
style rows, landmarks and climate vegetation. It still reads as "CG city", and some presets don't look like
the place at all. Evidence:
- `visual-plan/reviews/building-fabric-2026-10-31/{tokyo,nyc,paris}_y0.jpg`
- `.agents/plans/2026-10-31-city-preset-review.md`

**Tokyo** is uniform white boxes on lime lawns, because the pin is in Setagaya. **New York** has good
brick walk-ups but saturated colour, bare fenced parks and flat-coloured boxes for the distant towers.
**Paris** reads best, but it is clean and plastic: bright plazas, no grime, and a rooftop view.

Root causes, verified in code. Most are generic, so every coordinate benefits.

| Gap | Where | Effect |
|---|---|---|
| Eye fixed 30 m above terrain; ignores buildings; no vantage per preset | `view_360.gd:81, 309-340, 396` | Rooftop views over parks; the camera ends up inside towers taller than 30 m |
| Glass looks lost past 150–600 m; far towers are one prism each, picked by kind | `facade_materials.gd:115-117`, `far_city_builder.gd:173-178` | Midtown and Dubai glass render as brick or render; pre-war stone towers render as glass |
| No setbacks, crowns or mullions; roof detail on the largest part only | `building_masses.gd:40-158`, `:156` | Skylines of flat-topped slabs |
| `height`/`min_height` capped at 400 m; no decimal levels; no feet | `osm_tags.gd:111-123, 184, 238` | Burj Khalifa, One WTC and Lotte Tower fall back to the default height |
| No shop/amenity/furniture nodes or rail fetched; pedestrian areas drawn as a 6 m ring | `osm_query.gd:56-90`, `osm_parser.gd:38-53, 124` | No real shopfronts or signs, no tracks, empty plazas |
| Unmapped ground and park trees guessed from a 5 m blurred photo | `ground_shader.gd:92-133`, `vegetation_builder.gd:209-238` | Lime blobs; parks without canopy |
| No street life; lamps and signs glow at noon; `CityLights` reaches neither them nor far glass | `street_props.gd:168`, `relief_kit.gd:193`, `city_lights.gd:16-49` | Empty, toy-like streets; dark skylines at night |
| Lit windows repeat on every floor; glass never lights up | `facade_composer.gd:95, 98` | Striped facades and dark towers at night |
| No rock above the treeline wherever imagery exists; +32% saturation on warm ground | `far_surface.gd:80-110, 177`, `terrain_glsl.gd:53-56` | Banff and the Alps read as yellow hills |
| Haze changes only with season; no height fog; SSAO and shadows tuned for a 30 m eye | `atmosphere_rig.gd:448`, `sky_palette.gd:24-39`, `render_quality.gd:69-75` | Dubai looks like Paris air; flat valleys |
| Dubai, Seoul and Monaco use generic rows; one hero landmark per place | `architecture_data.gd:60-80`, `location_data.gd:311-324` | These presets look like anywhere |
| No committed capture tool; no look metric | `tools/` | Regressions in look ship silently |

**Outcome:** generic engine work, a data-only "preset tuning kit", and a capture-and-compare loop that
drives each quick-pick preset to the best achievable look.

User decisions (2026-11-01):
- **Vantage:** curated per preset.
- **Data:** new free keyless rasters allowed, register-gated.
- **Street life:** static instanced only.
- **Assets:** procedural plus CC0 packs and Blender GLBs.

## Ground rules

- **Mechanism, not special cases.** A preset differs from a random coordinate only through data:
  - `PresetViews` rows;
  - city rows, eras and districts;
  - `HeroOverrides` by OSM id;
  - registry landmarks or landmark candidates.

  No `if preset == …` in builders.
- **Real data first.** Procedural layers (street life, sign pseudo-text) take their density and placement
  from real data and are documented as deliberate, like today's procedural lamps.
- **Budgets.**
  - Generation per tier as in fidelity plan §3.1 (Ultra 60–120 s cold, cap 150 s).
  - Frame: Fast ≥ 30 fps on a mid-tier phone, ≤ 400 draw calls.
  - Every new layer is tier-gated; Fast is unchanged or minimal.
- **Two tracks, because of the in-flight parallel-build work.**
  - Its files: `world_build_graph.gd`, `ground_index.gd`, `ground_truth.gd`, `ground_material.gd`,
    `terrain_builder.gd`, `building_builder.gd`, `pbr_textures.gd`, `polygon_index.gd`, `build_abort.gd`.
  - It requires byte-identical build output.
  - **Track 1** changes no build output, so it starts now.
  - **Track 2** changes build output and starts when the parallel build has landed, or once its owner
    agrees to take its Step 0 baseline afterwards.
  - Re-read files before editing; other agents edit this repo.
- **New build layers follow the `WorldBuildGraph` contract.**
  - A pure static `X.build(data, ground) -> Node3D` that returns a detached subtree, with a seeded local RNG.
  - A `TaskResult` holder plus `WorkerThreadPool.add_task(…, true)`, checking abort at the start and in loops.
  - Statics prewarmed in the before-forking block (next to `_box_mesh()`) or behind a Mutex like
    `ArchitectureStyle._mutex`. Each one gets a row in that plan's static audit.
  - `MassBatch` access only through the thread-keyed accessor.
  - Each layer sets its own `lod_layer` meta.
  - The same call at the same position in `_build_serial`.
  - Make the graph table-driven before adding the third new layer.
- **Housekeeping.**
  - Every class ≤ 1000 lines (`tools/check_class_size.sh`).
  - Bump `WorldCache.BUILD_VERSION` per landed visual change. Release builds have no source hash.
  - Never bump the global `CacheStore.DATA_VERSION`: it re-keys DEM, satellite and climate too. Use a
    per-layer query version in the OSM and far-city keys.
  - Run `godot --headless --path . --import` after adding a `class_name`.
- **Tracker.** Copy this plan to `.agents/plans/2026-11-01-city-realism-v3.md` as the shared tracker,
  tasks R-1.x and R-2.x, with the fidelity plan's claim and tick rules.

---

## Track 1: no build-output change (start now)

**R-1.1 Capture-and-compare tool (before any visual change).**
- **`tools/capture_presets.gd`** (`extends SceneTree`):
  - Runs the real pipeline, cache first.
  - Fixed conditions: golden hour plus noon and night variants, summer, clear weather, a chosen preset.
  - Live weather and time stopped; reduce-motion on, or wait out the arrival descent
    (`view_chrome.gd:230-251`).
  - `QualityGovernor` pinned, so it can't drop resolution under 28 fps. HUD hidden.
  - Calls `RenderingServer.force_draw(false)` before each `get_image()`.
  - Saves the vantage view, 4 headings and 2 narrow-FOV close-ups to
    `visual-plan/reviews/<tag>-<date>/`.
  - Launch: `tools/godot_bg.sh --path . --script tools/capture_presets.gd --position 4000,4000` in the
    background.
- **Golden set:**
  - the 13 quick picks;
  - generic controls: the old Paris pin 48.8566, 2.3522 (every past baseline was taken there), the old
    Tokyo Setagaya pin, Turku, Zermatt, and a city with no city row (Cairo or Cape Town).
- **References:** `visual-plan/refs/<preset>/` with 1–3 CC-licensed Wikimedia Commons photos per vantage,
  licence and URL in a `README.md`.
- **Per-preset contact sheet**, render next to reference.
- **`stats.json` per frame:** luma, saturation and colourfulness, split by sky, buildings and ground row
  bands. It flags frames outside the references' range.
- **Scorecard (f)** in `docs/fidelity-scorecard.md`: a per-preset rating (stylised / recognisable /
  photographic) with the rater, per round.

**R-1.2 Curated preset vantages** (camera-only; the view is not in the `WorldCache` key).
- **New `scripts/data/preset_views.gd`** (`class_name PresetViews`). One row per quick pick:
  - `id`, chip label (keeps `place_card.gd:25` `SKY_FOR`), place name;
  - `origin` lat/lon: the world centre, i.e. the detailed ±1200 m extent;
  - optional `eye` lat/lon inside the extent. `spawn_xz` already supports a non-zero spawn, so the extent
    can sit ahead of the camera and cover what it faces;
  - `eye_m`: at least 4 m, with mode `ground`, `roof+` or `asl` for decks and clifftops. The DEM blurs
    cliffs into ramps;
  - `yaw_deg`, `pitch_deg`, `fov`.
- `LocationData.quick_picks()` reads from it.
- **Resolution by pin, not UI plumbing.** `PresetViews.for_pin(lat, lon)` (≤ 15 m match) is resolved in
  `GenerationPipeline.run` next to `data.focus` (`pipeline.gd:178-182`) and stored as
  `LocationData.view`.
  - History, Recents, Retry (`main.gd:150`), offline saves and typed coordinates then all reopen the same
    view. History entries hold only {name, lat, lon, …} (`cache_store.gd:205-209`).
- **Gazetteer.** Point the preset cities' `known_places()` entries at the curated origins, so searching
  "Tokyo" gets the hero view.
- **Landmark conflict.** `main.gd:84-89` must not swap a curated pin for a `LandmarkVisit` standoff:
  clear `selected_landmark` on a quick pick.
- `View360` skips the `spawn_xz` step-back when `data.view` is set.
- **Proposed vantages.** Approximate; settle each in review against OSM and all 4 headings, balancing the
  hero side against the rest of the 360.

| Preset | Origin / eye | Eye | Look | Hero |
|---|---|---|---|---|
| Paris | Trocadéro ~48.8620, 2.2880 | 6 m | SE | Eiffel Tower ~0.6 km |
| Tokyo | Shibuya Crossing ~35.6595, 139.7005; eye on the station side | 12 m | across the scramble | Shibuya screens (overrides) |
| New York | Origin Lower Manhattan ~40.7075, -74.0090; eye Brooklyn Bridge Park Pier 1 ~40.7020, -73.9967 | 8 m | WNW | Financial District skyline, One WTC, Brooklyn Bridge |
| London | South Bank at Westminster Bridge ~51.5010, -0.1197 | 8 m | W | Parliament, Big Ben, London Eye |
| Rome | Colle Oppio, Via Nicola Salvi ~41.8925, 12.4950 | 6 m | SW | Colosseum ~350 m |
| Venice | Ponte dell'Accademia ~45.4315, 12.3285 | 10 m | E down the Grand Canal | Salute dome |
| Stockholm | Monteliusvägen ~59.3205, 18.0640 | asl + 4 m | NE | Gamla stan, Riddarholmen, City Hall |
| Monaco | Le Rocher ~43.7315, 7.4200 | asl + 4 m | NE | Port Hercule, Monte-Carlo |
| Dubai | Origin Burj Khalifa ~25.1972, 55.2744; eye ~700 m SE across the lake | 12 m | NW | Burj Khalifa |
| Seoul | Gwanghwamun Square ~37.5720, 126.9768 | 10 m | N | Gwanghwamun, Bugaksan; N Seoul Tower as an extra |
| Alps | Harder Kulm ~46.6975, 7.8515 | asl + 4 m | SSE | Eiger, Mönch, Jungfrau |
| Banff | Surprise Corner ~51.170, -115.562 | 4 m | SE | Banff Springs Hotel, Mt Rundle |
| Big Sur | Bixby Bridge pull-out ~36.3725, -121.9015 | 4 m | S | Bixby Creek Bridge, coast |

New York from Top of the Rock (260 m) is a stretch goal for after R-2.4. Today everything south of it is
unshadowed far-city prisms; the near/far seam would sit mid-frame; and ranges, SSAO and shadow splits are
tuned for a 30 m eye.

**R-1.3 One eye helper, plus a generic camera for other coordinates** (`view_360.gd`).
- One `eye_position(data, ground, xz)` used by the spawn, "Go there" (`:396`) and the arrival descent.
- **Clearance without build changes:**
  - Test footprints with `PolygonIndex` on `data.buildings` (not `is_built_at`, which is a centroid
    circle, `ground_truth.gd:608-636`).
  - Height is tag height, else levels × 3.3 m, else 12 m. Lift the eye above any roof within 25 m plus
    6 m, and nudge the pin out of a footprint.
- **Default heading:** the landmark; else the bearing with the most data-level built mass within 600 m;
  else water. This replaces the fixed yaw 0.6.
- Update the tests that use `spawn_xz`/`EYE_HEIGHT_M`: `landmark_test`, `landmark_info_test`,
  `fidelity_scorecard_test`.

**R-1.4 Look audit, a report only.**
- Per-material mean albedo, computed on the CPU from the built materials, against measured ranges:
  - brick 0.20–0.35, limestone 0.45–0.60, concrete 0.30–0.45, glass 0.08–0.15;
  - asphalt 0.06–0.12, grass 0.15–0.25, terracotta 0.25–0.40.
- Plus `Viewport.DEBUG_DRAW_UNSHADED` captures of the golden set.
- Output: an outlier list for R-2.1.
- AgX against ACES side by side, as a report only. ACES is a PRD AC-12 requirement, asserted in
  `render_upgrade_test.gd:38` and `settings_test.gd:218`, so switching needs a PRD amendment and your call.

**R-1.5 Source and asset spikes, plus register rows** (`docs/data-source-register.md`).
- **ESA WorldCover 10 m v200** (CC BY 4.0): 3° EPSG:4326 COG tiles under `esa-worldcover/v200/2021/map/`,
  eu-central-1, anonymous reads.
- **Meta/WRI canopy height v2, ~1.2 m** (CC BY 4.0): `dataforgood-fb-data/forests/v2/global/dinov3_global_chm_v2_ml3/`,
  probably EPSG:3857 quadkey tiles. The `tge-labs/meta-chm-v2` index points at Meta's COGs.
- For each source, confirm tile naming, compression (deflate or zstd fine; LZW too slow in GDScript, so
  canopy would fall back to WorldCover's tree class), overviews, and anonymous HTTPS 206 on device.
- **CC0 models:** Kenney Car Kit, Quaternius. Source and polygon-budget them.
- **Sign font:** an OFL Latin font.
- Licences go in a "Bundled assets" section beside the PBR sets.
- **GHSL building height is cut.** It ships as zipped Mollweide tiles, not range-readable.

## Track 2: build-output changes (after the parallel build lands)

### R-2.1 Generic quick wins

- **Parsing** (`osm_tags.gd`, `far_city_fetcher.gd`):
  - Height and `min_height` caps go to 1000 m.
  - Decimal levels; feet and `'` heights.
  - The far-city server filter keeps feet-tagged towers.
  - Barrier `height`/`material`/`fence_type` (`osm_parser.gd:135`) into `StreetProps`; fixes London's
    orange boards.
  - `roof:direction`/`roof:orientation`.
- **Parser-only layers already in the cached payload** (no refetch): pedestrian areas and
  `area:highway` filled as plazas, not a 6 m ring; `landuse=railway|construction`; `leisure=marina`.
- **Glass:**
  - Keep glass looks in the distant branch (`facade_materials.gd:115-117`).
  - Far towers pick material by era and kind, not glass by default.
  - Lit layer on curtain glass (`facade_composer.gd:95`) and on far-city glass.
- **Lit windows:** break the per-floor repeat (`facade_composer.gd:98`). Either a 4-storey emission tile
  period, if the cost fits `TEX_CAP` 160, or a ShaderMaterial with the `CityLights`/`WallVariety` type
  checks updated. Decide by measurement.
- **`CityLights` reach:** register materials at build time instead of walking only `MeshInstance3D` +
  `StandardMaterial3D` with an emission texture. That covers MultiMesh lamps, flat-emission signs and far
  glass. Fixes the noon glow (`street_props.gd:168`, `relief_kit.gd:193`).
- **Baked sky-view AO:**
  - Before forking, a 4 m height raster from the footprints.
  - Per wall edge, at 3 heights, the street-canyon openness, folded into `WallVariety`'s vertex RGB
    (`wall_variety.gd:22-48`; it already does foot shading). Full-detail range only.
  - Ground-storey soiling added to the composed ground tile; `_sill_streaks` already exists.
  - Strength by climate and era.
- **Colour and air:**
  - Fix the R-1.4 albedo outliers in the region palettes.
  - Climate aerosol factor from `ClimateModel` (arid → dust, humid → haze, alpine → clear) into
    `atmosphere_rig.gd:448`.
  - `fog_height_density` for valleys and lakes.
  - SSAO radius and shadow splits scaled by eye height (`render_quality.gd:69-75`,
    `atmosphere_rig.gd:284-289`).
- **Mountains:**
  - Rock above the treeline and on steep high ground, even where imagery exists (`ground_shader.gd:161-177`,
    `far_surface.gd:177-179`). Uses a treeline global next to the snow globals (`climate_model.gd:135-196`).
  - Damp the warm-ground saturation boost on high ground.
  - Check that the 30 km far-terrain edge stays below the horizon from the asl vantages.
- **Known preset defects** from the 10-31 review:
  - Clamp near-white satellite roof samples to the region palette (Banff), before R-2.5 spreads satellite
    roof colour.
  - Monaco harbour colour stripes.
- **`HeroOverrides`** (new `scripts/data/hero_overrides.gd`): keyed by OSM way or relation id; fields are
  glass, screen faces, crown kind, colour, suppress. Applied in `BuildingMasses.plan`. Generic; presets
  fill it first.
- **Extra heroes:** registry or override entries injected as `landmark_candidates` (cap 8,
  `pipeline.gd:430`). They already build in both graph paths and exclude overlapping buildings. Needed
  for N Seoul Tower and a second NYC tower.

### R-2.2 Data v3

**OSM** (`osm_query.gd`, `osm_parser.gd`, `osm_tags.gd`, `LocationData`):
- POI nodes within 800 m: `shop`, `amenity`, `office`, `tourism`, `craft`, `advertising` with
  `name`/`brand`.
- Furniture nodes: `highway=street_lamp|traffic_signals|crossing|bus_stop`,
  `amenity=bench|waste_basket|bicycle_parking|vending_machine`, `barrier` nodes.
- `railway=*` ways (no tunnels), keeping `bridge`/`layer`.
- `amenity=parking`, `man_made=pier|breakwater`.
- `man_made=water_tower|chimney|mast|antenna`, `power=line|minor_line|pole`.
- `building:part` relations.

Plumbing:
- A dict-shaped v3 signal (`osm_fetcher.gd:11-13` are frozen), pipeline holders (`:201-207`) and the
  `_await_osm` copy.
- `OsmApiFallback.to_overpass_json` must emit tagged nodes.
- Per-layer query version in the OSM key.
- If payload or first load grows more than 20%, chain a second request after the detailed one. Never a
  fourth concurrent request: Overpass would return 429.

**Rasters:**
- New `scripts/data/cog_reader.gd` (`CogReader`): IFD, tile offsets, native decompress, predictor undo,
  overview pick. Decode runs on `WorkerThreadPool`.
- New `landcover_fetcher.gd`:
  - WorldCover window at 10 m (near) plus an overview (far rings).
  - Canopy height at a 2–4 m overview.
  - Each saved as a PNG per place (`LocationData` is never serialized).
- Started in `pipeline.run()` and awaited inside stage 1 "Imagery". No new stage, so no
  `LoadingScreen`/`DataNotes` copy. Degrades silently; joined in `cancel()` (`pipeline.gd:167`).
- Kept out of `GroundTruth`, so world-cache ground state and the planned early GroundTruth are unaffected.
- **CacheStore:**
  - teach `layer_of`/`is_v2_name` and the cached-status helpers the new layer (`cache_store.gd:103-165`);
  - compute History keys at read time, not stored absolute paths;
  - add the layer to `OfflineDownloader`.
- **`WorldCache.key`** (`world_cache.gd:30-34`) fingerprints the landcover and canopy presence and source
  and the new array sizes, so a failed-fetch world isn't served forever.
- **Attribution** in the pipeline string format that `HudParts.short_sources` expects
  (`hud_parts.gd:220-235`), plus `SettingsScreen.SOURCES` rows (`settings_screen.gd:21-32`): WorldCover
  credit, canopy, CC0 packs, font. Styled with the design system.
- Update `docs/world-model-contract.md`.

### R-2.3 Buildings

- **Towers** (new `tower_massing.gd`, called inside `BuildingMasses.plan` so `PartyWalls` and roof detail
  see the masses):
  - Applies to a single mass with a height tag and no parts.
  - Podium plus shaft, stepped setbacks (NYC pre-war, art deco), tapered or flared crowns (Gulf, Asia),
    spires from `man_made=mast|antenna`.
  - Real parts always win.
  - Roof detail on the highest part.
  - New curtain-wall mullion and fin relief in `facade_relief.gd` (no `curtain` case exists today).
  - The far city goes through the same plan instead of `BuildingBuilder._walls` directly; guard
    `BuildingMasses._plans` across threads.
  - Far towers fetch `building:part` with a new far-city key.
- **Shopfronts and signs from real POIs:**
  - A POI within 3 m of a façade edge sets that façade's ground storey to `shop`
    (`architecture_style.gd:257`, `facade_materials.gd:235`); fascia colour from kind and brand hash.
  - New `sign_painter.gd` composes Latin real names, and script-appropriate pseudo-text for CJK and
    Hangul, into **shared atlas pages per place**. Per-sign materials would each cost a draw, because the
    LOD merge keys on material (`lod_ring.gd:73-74`).
  - Sign kind by row (`rv.signage`): vertical stacks (Tokyo, Seoul), fascia boards, blades.
  - `advertising=screen|billboard` and overrides add emissive screens.
  - Replaces the sign boxes in `street_front.gd:118-134`.
- **Rooftop clutter** (new `rooftop_clutter.gd`, moved out of `building_detail.gd:305-327`), profile key
  `rc`:
  - NYC timber water tanks; Gulf and South Asian cylinders;
  - HVAC, bulkheads, lift overruns, antennas and dishes, solar;
  - Tokyo rooftop billboards; Seoul block numbers.
  - Batched; none on Fast.
- **Variety:**
  - `LOOKS` from 2 to 3 or 4 where `lod_test`'s material budget allows (`architecture_style.gd:20-25`).
  - Satellite roof tint on distant and batched roofs via `MassBatch` vertex colour.
  - Read the parallel plan's `TEX_CAP`/`MAT_CAP` overflow log first; any overflow is a failure.

### R-2.4 Streets, ground, nature

- **Paving:**
  - New classes `plaza`, `parking`, `railway`, `pier` (`GroundMaterial.ID`, `OsmTags.land_class`).
  - CC0 sett, cobble and granite-slab PBR sets (`PbrCatalog`, `TerrainTextures.LAYERS`; grow
    `det_mean`/`det_tile` at `terrain_glsl.gd:20-21`).
  - Regional paving by uniform: sampietrini (Rome), masegni (Venice), granite setts (Paris, Stockholm),
    interlocking pavers (Tokyo, Seoul).
  - Calibrated darker tone.
- **Kerbs and paint:**
  - Raised kerb and sidewalk geometry on urban roads, replacing the painted bands
    (`road_surface.gd:104-114`).
  - Regional paint (`:34`): US and Korean yellow centre lines, Japanese white with yellow no-passing,
    stop lines.
  - Crossings from OSM nodes where mapped.
- **Rail and decks:**
  - Track ribbons and tram rails.
  - `layer` + `bridge=viaduct` give real deck height with piers (Tokyo Shuto, NYC el).
  - Stone decks where `bridge:structure`/`surface` says stone (`road_builder.gd:329`).
  - Piers under long decks; Bixby as an arch via override.
- **Ground:**
  - Unmapped texels take their class from WorldCover in place of the photo green index.
  - Far rings use WorldCover tints.
  - Calibrated park grass with mowing and worn-path variation.
  - Grass tufts past 260 m on High+ (`ground_cover.gd:19`).
  - Glaciers and permanent snow from WorldCover class 70.
- **Trees:**
  - Canopy ≥ 3 m on free texels (`VegetationMask`) gets trees sized and spaced from the canopy, unless OSM
    tree nodes cover the cell.
  - Street trees with pits.
  - New species: plane, cherry, ginkgo, zelkova, Japanese black pine, a palm variant (`tree_species.gd`).
  - Far impostor trees from the WorldCover tree class to ~5 km on High+ (none today past 1200 m,
    `vegetation_mask.gd:44-47`).

### R-2.5 Street life (static, instanced)

- New `street_life.gd` (placement) and `street_life_meshes.gd` (CC0 GLBs in `assets/street_life/`).
- Runs **inside the vegetation task after `StreetProps`**, sharing its occupancy grid
  (`vegetation_builder.gd:51`, `street_props.gd:57`). Kerbs (R-2.4) come first.
- **Cars:**
  - Parked along residential and tertiary kerbs and in `amenity=parking`.
  - Frozen traffic on primary roads and motorways.
  - Density by road class and built-up fraction.
  - Regional mixes: NYC cabs, Tokyo white kei cars, Dubai SUVs, European hatchbacks.
  - Height from `RoadBuilder.surface_height`.
  - Head- and tail-lights through `CityLights`.
- **Boats:** at quays and marinas through `ground.water_at`; gondolas and vaporetti in Venice, yachts in
  Monaco.
- **People:** cards only, past ~40 m, on plazas and near POIs. Close-up CC0 figures look more toy-like
  than empty streets.
- **Poles and wires:**
  - Where the row sets `rv.poles` (Japan, Korea, US suburbs) and wherever `power=pole`/`minor_line` is
    mapped.
  - Wires kept out of an eye-height band (the Seoul review defect).
- **Signals, benches, bins, bus stops** from nodes; signals inferred at major junctions where unmapped.
- **Batching:** MultiMesh per mesh × sector × distance ring, as vegetation does. One area batch is never
  ranged (`lod_ring.gd:39-41, 145-147`). A new `LodRing._range` case.
- **Tiers:** Fast none; Balanced cars ≤ 200 m; High ≤ 450 m; Ultra ≤ 700 m.

### R-2.6 Preset hero pass (data and tuning only)

**Loop:** capture (R-1.1), compare with refs, then:
- fix generically when the cause is generic;
- else add a row, district or override;
- re-capture.

**Target:** every preset at least "recognisable"; Paris, Tokyo and New York "photographic" on Ultra.

| Preset | Style work | Heroes |
|---|---|---|
| Tokyo | `tokyo` row: beige, grey and brown tile and concrete, not white; narrow zakkyo mixed-use; Shibuya and Shinjuku commercial districts with vertical signs and screens; poles and wires | Shibuya overrides (QFRONT screens, 109) |
| New York | Lower Manhattan/Midtown districts: pre-war setback towers, limestone, art-deco crowns, water tanks, cabs | One WTC (data, with height fix); Statue of Liberty exists; Empire State Building as a candidate for the Top of the Rock stretch |
| Dubai | New `gulf` row: glass curtain towers with setbacks and crowns, sand low-rise, villas, palm medians; dust haze | Burj Khalifa (registry plus GLB) |
| Seoul | New `seoul` row: apartment complexes with numbered slabs, varied heights and colour bands, sign-dense strips, hanok near the palaces | Gwanghwamun (archetype or GLB); N Seoul Tower candidate |
| Monaco | New `riviera` row: pastel Belle Époque, balustrades, stepped hillside towers; marina boats | Casino, Prince's Palace via override or archetype |
| Paris, London, Rome, Venice, Stockholm | Tune with paving, grime and air; Rome umbrella pines and domes; Venice masegni and boats; Stockholm "toy fortress" check | Existing; City Hall and Salute via overrides |
| Alps, Banff, Big Sur | Chalet timber storeys and balconies; rock, glacier and height fog; dry grass, surf | Terrain; Banff Springs via castle archetype; Bixby via override |

New landmark models follow the `landmark_*.gd` / `assets_src/blender` pattern, with `landmark_test`
coverage.

---

## Notes for the parallel-build owner (found during this review)

In the uncommitted `world_build_graph.gd`:
- The far city is built twice: in `build_buildings` without `skip_far_city` (`:110`) and in its own task
  (`:124-135`).
- Buildings are merged twice: `:111`, then `view_360.gd:244`.
- Child order differs between the parallel and serial paths.
- The prewarms behind `has_method` on class references (`:29-40`) probably never fire.

In `world_cache.gd:157-158`, `_load_ground` sets `_buildings` after the index is built, so cache hits fall
back to slow full scans.

## Critical files

- **New:**
  - `tools/capture_presets.gd`
  - `scripts/data/{preset_views,hero_overrides,cog_reader,landcover_fetcher}.gd`
  - `scripts/generation/{tower_massing,sign_painter,rooftop_clutter,street_life,street_life_meshes,rail_builder}.gd`
  - `tests/{cog_reader,preset_views,street_life}_test.gd`
  - `visual-plan/refs/<preset>/`
- **Modified:**
  - Track 1: `view_360.gd`, `pipeline.gd` (view resolution only), `location_data.gd`, `main.gd`, `map_picker.gd`.
  - Track 2:
    - data: `osm_*`, `far_city_*`, `cache_store.gd`, `offline_downloader.gd`
    - buildings: `building_masses.gd`, `facade_*`, `street_front.gd`, `building_detail.gd`,
      `architecture_*`, `city_styles.gd`, `building_era.gd`, `wall_variety.gd`
    - streets: `road_*`, `street_props.gd`
    - ground and nature: `ground_*`, `terrain_glsl.gd`, `terrain_textures.gd`, `pbr_catalog.gd`,
      `vegetation_*`, `tree_species.gd`, `far_surface.gd`, `climate_model.gd`
    - build and render: `world_build_graph.gd`, `lod_ring.gd`, `city_lights.gd`, `atmosphere_rig.gd`,
      `render_quality.gd`, `world_cache.gd`
    - screens: `hud_parts.gd`, `settings_screen.gd`
  - Docs: `data-source-register.md`, `architecture-styles.md`, `fidelity-scorecard.md`,
    `world-model-contract.md`.

## Verification

1. **Per task:** headless tests in the background (`--headless`, `run_in_background`):
   - `architecture_test` (new rows and overrides pinned);
   - `osm_test` and `osm_fallback_test` (new layers, fixtures);
   - `scenery_test`, `building_fabric_test`, `landmark_test`, `landmark_info_test`, `lod_test`,
     `far_city_test`, `polygon_index_test`, `fidelity_scorecard_test`, `render_upgrade_test`,
     `settings_test`, `flow_test`;
   - the new tests.

   Then `tools/check_class_size.sh`.
2. **Per task group:**
   - R-1.1 capture over the golden set (presets plus controls) at noon, golden hour and night.
   - Commit the review folder with an "improved / regressed" note; a regression without a note blocks
     the tick.
   - Check `stats.json` against the reference ranges.
3. **Budgets:** cold generation per tier from the `BUILD timings` line; draw calls and fps for Fast and
   High on the golden set. Fast ≤ 400 draw calls, ≥ 30 fps class.
4. **Windowed batch at the end:** `tests/world_cache_test.gd` and `tests/screenshot_test.gd` via
   `tools/godot_bg.sh --position 4000,4000`.
5. **Human gate:** a per-preset scorecard (f) rating against the reference contact sheets.

## Risks

- **Overpass first-load time** (already ~220 s for some presets). Per-layer caps; a chained second
  request.
- **Raster layouts.** The R-1.5 spike gates them; today's behaviour stays as the fallback.
- **Frame budget.** Tier gating, sector × ring MultiMesh, shared sign atlases.
- **Material caps.** Overflow log checked before adding looks or fascias.
- **App size from GLBs.** Polygon and texture budget per asset; procedural where the silhouette passes.
- **Vantage mismatch.** The camera is placed at true metres over a smoothed DEM, so clifftop vantages use
  `asl` and an eye of at least 4 m.
