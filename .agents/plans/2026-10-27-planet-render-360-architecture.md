# Planet Render 360 — High-Level Architecture Plan

## Goal

Build a mobile-first app that takes any coordinate or map pick and renders a recognizable, smooth 360° 3D view of that place on device. Development starts on macOS; release targets are iOS and Android. The workspace today is greenfield: only `README.md`, `LICENSE`, `AGENTS.md`, and `.gitignore` (already set up for Godot and Blender) exist, so this plan makes the founding stack and structure decisions. Non-photorealistic but geographically faithful output is acceptable; smooth mobile frame rates and a loading time of at most a few minutes are hard requirements from the README. Two further hard constraints: the app must not require any self-hosted server, and the app is free with no paywall.

## Success Criteria

- A user can enter coordinates or tap a world map, and within a few minutes sees a full-screen 360° view they can look around in.
- Terrain height, land cover, water, roads, and major landmarks at the picked point recognizably match the real location.
- The view runs smoothly on a mid-range phone (target: stable 30 fps minimum, 60 fps goal) without overheating-level sustained load.
- Repeat visits to a cached area load in seconds and work offline.
- All runtime data comes from free sources with attribution shown in-app; no paid API key is required to run the app.
- The app runs with no self-hosted server: the device talks directly to free public sources, and every feature works without any first-party backend, account, or hosted proxy.
- The app is free with no paywall: no purchase, subscription, in-app purchase, locked features, or paid tiers. Every feature is available to every user.
- The same project exports to macOS for development and to iOS and Android for release.

## Stack Recommendation (Answer in Brief)

| Layer | Pick | Role |
|---|---|---|
| 3D runtime | Godot 4.x (latest stable 4.x) | The app itself: scene, rendering, input, UI, networking |
| Primary language | GDScript | All gameplay/app logic; typed GDScript for hot paths |
| Performance escape hatch | C# or C++ via GDExtension, only where profiling proves need | DEM decoding, mesh building, procedural generation |
| Asset authoring | Blender (offline only) | Landmark and prop models, terrain material work; never runs on device |
| Asset interchange | glTF / GLB | Blender → Godot import format |
| Geo data processing (dev tooling) | GDAL (CLI/library, offline and/or build-time) | Reproject, clip, resample DEM and raster data while preparing test fixtures and any bundled base data |
| Map picker (in-app) | Godot-native 2D map built from raster/vector tiles | Location selection inside Godot |
| UI | Godot UI (Control nodes) | Map picker, search, history, settings, loading, and 360° overlays |
| Data transport | HTTPS + JSON / binary tiles | All remote fetching from Godot, directly to free public sources |
| Backend | None | No self-hosted server, proxy, account system, or first-party API |
| Monetisation | None | Free app, no paywall, no in-app purchases or subscriptions |

### Decided: no Flutter

Godot owns the whole app — UI, map picker, and 3D view. Flutter and Dart are not used in any phase. This keeps one runtime, one language, the smallest binary, and a single export/store pipeline, and avoids a Dart↔GDScript bridge and platform-view compositing overhead on the 3D surface. All screens — including search, history, and settings — are built with Godot UI. Reintroducing Flutter would be a new architecture decision requiring an explicit plan revision, not a phase in this plan.

### Decided: no self-hosted server, no paywall

There is no first-party backend in any phase: no server, hosted proxy, cache tier, account system, or API operated for this app. The device fetches directly from free public sources, caches on device, and works offline for cached areas. If a candidate source cannot be used directly from a mobile client under its free terms, it is rejected in the Phase 0 register and replaced with a source that can — a server is never the workaround. Operating cost is therefore zero by construction, which is what makes the second half sustainable: the app is free with no paywall, meaning no app purchase, subscription, in-app purchase, feature unlocks, or paid tiers, and no paid data provider whose cost would create pressure for one. All bundled and downloaded content and all features are available to every user.

### What else to pick (and what not to)

- **Renderer:** Godot's Mobile renderer for release builds (Vulkan/Metal-class devices), with Compatibility as the fallback for older devices and the iOS Simulator. Validate both early; do not design materials that only work in the desktop Forward+ renderer.
- **Blender pipeline:** Blender is a build-time tool only. Models are baked, decimated, and texture-atlased in Blender, exported as GLB, and imported by Godot. No Blender files ship in the app; `.blend` sources live in the repo under an assets directory, exported GLBs beside them.
- **GDAL:** used on the developer machine (and optionally in CI) to prepare DEM/raster fixtures and any small bundled base dataset. It is not embedded in the mobile app; on-device decoding uses small purpose-built GDScript/C++ decoders for the few formats actually fetched at runtime.
- **Not picked:** no Flutter/Dart, no self-hosted server in any phase (no backend, proxy, or cache tier — the device fetches public data directly), no user accounts, no second game engine, no web view as the primary map or 3D surface, no paid map/DEM/weather provider, and no monetisation of any kind (no paywall, in-app purchases, subscriptions, or paid tiers).

## Approach

### System shape

```text
┌──────────────────────────── On device (Godot app) ────────────────────────────┐
│  UI layer          Map picker · coordinate entry · history · loading screen   │
│  Session layer     Location request → job pipeline → progress state machine   │
│  Data layer        Fetchers (DEM, land cover, vector features, weather)       │
│                    → normalisers → on-disk tile/area cache                    │
│  Generation layer  Terrain mesh builder · water/roads/buildings · landmarks   │
│                    · vegetation scatter · sky/lighting/weather state          │
│  Render layer      360° camera rig · LOD/streaming · quality scaler          │
└───────────────────────────────────────────────────────────────────────────────┘
        │ HTTPS (free public sources, attribution preserved)
        ▼
  DEM tiles · map/vector tiles · land-cover/climate data · (optional) weather

  Offline (developer machine): Blender ──GLB──▶ Godot import
                                 GDAL ──▶ test fixtures / bundled base data
```

### Key design decisions

1. **One Godot project is the whole app.** Scenes: `MapPicker`, `Loading`, `View360`, plus settings/history as UI overlays. This keeps macOS development and iOS/Android export on Godot's documented export paths and avoids any cross-runtime bridge.
2. **Location generation is a staged, cancellable job pipeline.** Each stage (fetch DEM → fetch features → build terrain → place landmarks → dress scene → finalise lighting) reports progress to the polished loading screen the README requires, can be cancelled when the user picks a new place, and writes intermediate results into the area cache so a retry resumes instead of restarting.
3. **Tile-based world model.** The world is addressed by standard web-map tile coordinates at a small set of zoom levels. Terrain is built per tile patch around the viewpoint with distance-based LOD rings; far terrain is lower resolution and cheaper materials. This bounds memory and draw calls on phones regardless of which location is picked.
4. **Data contracts before visuals.** Each external source gets one fetcher module with a fixed internal output type (height grid, land-cover grid, feature list with geometry + tags, landmark candidates). Generation code never parses raw provider JSON/GeoTIFF itself, so a provider swap touches one module.
5. **Landmarks are data-driven, not hand-placed.** Recognisable structures come from tagged map features (name, type, height where available) matched to a small library of procedural/Blender-made archetypes (tower, dome, bridge, stadium, generic block). Famous bespoke landmarks are modelled in Blender only when an archetype cannot read recognisably; the library grows one landmark at a time, driven by test locations.
6. **Cache is a first-class layer.** Downloaded tiles and generated patches are stored on disk keyed by tile + zoom + data version, with a size cap and LRU eviction. History entries reference cached areas. Offline revisit of a cached area must work with networking disabled.
7. **Quality scales to the device.** A runtime quality governor picks terrain resolution, scatter density, shadow use, and render scale from device capability and measured frame time, targeting the Success Criteria frame rates. Desktop/macOS defaults may be prettier; mobile budgets win every conflict.
8. **Attribution and licensing are UI, not comments.** Every data source used for the current view is listed on an attribution screen/panel fed by the fetchers actually used, satisfying the README's attribution requirement by construction.

### Repository layout (proposed)

```text
project.godot                 Godot project (repo root or godot/ — settle in Phase 0)
scenes/  scripts/             UI, session, generation, render code (GDScript)
data/                         Fetchers, normalisers, cache, data contracts
assets_src/blender/           .blend sources (landmarks, props)
assets/                       Exported GLB, textures, materials imported by Godot
tools/                        GDAL-based fixture/base-data preparation scripts
tests/                        Headless Godot tests + golden-location fixtures
docs/                         Architecture (this plan), data-source register, ADRs
```

### Data sources (register to be confirmed in Phase 0)

The README already names OpenFreeMap, DEM sources, and CHELSA as candidates. Phase 0 turns that into a written register: for each source — endpoint, format, licence/attribution text, rate limits, CORS/redirect behaviour from a mobile client, whether it is free with no paid key or tier required, and a fallback source. A source that needs a self-hosted proxy, an account, or any payment to use from the device is disqualified, however good its data is. No source enters the fetch layer until its register entry is complete. Elevation accuracy, land-cover typing, and landmark tags are the three data needs; weather and season/time-of-day dressing are optional layers behind the same fetcher pattern.

### Phasing

| Phase | Outcome |
|---|---|
| 0. Foundations | Godot project skeleton, export presets proven to a real iOS and Android device, data-source register, tile/cache contracts, golden test locations chosen (flat, coastal, mountainous, dense-urban, landmark) |
| 1. Terrain MVP | Map picker + coordinate entry → DEM fetch → terrain/water/sky → 360° look-around; loading pipeline with progress; cache v1 |
| 2. Dressed world | Land cover materials, roads, buildings, vegetation scatter, landmark archetypes; quality governor; history |
| 3. Fidelity & options | Bespoke Blender landmarks for golden locations, time-of-day/season, live weather dressing, offline area download management |

## Steps

1. **Phase 0 — Foundations.** Create the Godot 4.x project with Mobile renderer + Compatibility fallback; add Android and iOS export presets and prove one build each on a physical device. Write the data-source register for DEM, map/vector, land-cover/climate candidates named in the README, verifying licence, attribution, and rate-limit terms per source. Define tile addressing, data contracts, and cache key/version format. Pick five golden locations and capture reference expectations for each.
2. **Phase 0 — Asset pipeline proof.** Model one simple landmark in Blender, export GLB, import into Godot, and display it in a test scene on a phone. Use GDAL tooling to clip/resample one DEM fixture for a golden location and load it in a desktop test scene.
3. **Phase 1 — Terrain MVP.** Implement fetchers + normalisers behind the contracts, the staged job pipeline with progress/cancel, per-tile terrain mesh building with LOD rings, water plane from elevation/coast data, sky + sun, and the 360° camera rig (touch drag + device-motion look where available). Ship cache v1 (disk, size-capped, LRU).
4. **Phase 1 — Map picker & shell UI.** Godot-native world map from tile imagery/vector tiles with tap-to-pick, coordinate entry with validation, and the loading screen wired to real pipeline stages. Attribution panel lists sources used for the current view.
5. **Phase 2 — Dressed world.** Land-cover-driven terrain materials and texture set (CC0 sources per the README), roads and waterways as geometry/ decals, extruded buildings from feature footprints + heights, vegetation scatter by land cover + climate data, and landmark archetypes matched from feature tags.
6. **Phase 2 — Performance & history.** Quality governor (resolution/scatter/shadow/render-scale steps driven by frame time), recently-viewed history backed by the cache, and full-screen view mode. Profile on a mid-range Android device and a recent iPhone; fix budgets before adding fidelity.
7. **Phase 3 — Fidelity & ambience.** Bespoke Blender landmark models for golden locations where archetypes fail the recognisability check, time-of-day and season controls, optional current-weather fetch + dressing (rain/fog/snow states), and explicit offline download/manage-storage UI.

## Validation Plan

- **Export gate (every phase):** project exports and installs on one physical Android device and one physical iPhone from a clean checkout; macOS editor run is not a substitute.
- **Golden locations (Phases 1–3):** for each of the five golden locations, generate the view and compare against recorded expectations: terrain silhouette/elevation profile sanity (spot heights vs DEM), water/land placement, road/building presence, landmark recognisability by human review with reference imagery.
- **Performance gate (Phases 2+):** on the designated mid-range Android device, each golden location holds ≥30 fps sustained in the 360° view with the quality governor active; record frame-time traces per location in `tests/` artefacts.
- **Loading gate:** cold generation of a golden location completes within the README's few-minutes budget on a typical broadband connection, with progress advancing at every pipeline stage and cancel returning to the picker within a second.
- **Cache/offline gate:** with networking disabled, revisiting a cached golden location loads in seconds and renders identically; exceeding the cache size cap evicts oldest areas without corrupting retained ones.
- **Data-contract tests:** headless Godot tests feed recorded fixture responses through fetchers/normalisers and assert output types and value ranges (heights, land-cover classes, feature geometry), so provider format drift fails tests, not users.
- **Attribution check:** the attribution panel for a generated view lists exactly the sources whose data was used; verified manually per golden location at each phase exit.
- **No-server gate:** a release build's network traffic goes only to the public sources in the register — no first-party host is contacted, and all golden locations generate with no backend running. Any new endpoint needs a register entry before it ships.
- **No-paywall audit:** store listings and exported builds contain no purchase, subscription, in-app purchase, or feature gating; every screen and feature is reachable in a fresh install with no payment or account.

## Risks / Open Questions

- **Free-source terms may block direct device access.** If a chosen DEM/map source forbids direct mobile-client access, lacks CORS, rate-limits per-IP in a way phones cannot respect, or requires a paid key, it cannot be used — a self-hosted proxy is not an allowed fallback. Mitigation: the Phase 0 register must settle this per source before any code depends on it; the fallback is always another qualifying free source, reduced fidelity from an already-qualified source, or dropping that data layer, in that order.
- **DEM resolution vs. recognisability.** Free global DEMs may be too coarse for near-field terrain in flat or dense-urban areas. Mitigation: golden locations include those cases in Phase 0 so the gap is measured before Phase 1 commits to a terrain approach.
- **Landmark coverage.** Tag completeness for famous structures varies by region; some landmarks will have no usable footprint/height data. Mitigation: archetype library plus a curated bespoke list for golden locations; worldwide bespoke coverage is a non-goal.
- **Godot UI limits.** Search, history, and settings must stay usable in Godot UI without Flutter. Mitigation: keep those screens simple list/form layouts, reuse shared Control themes, and validate text input and accessibility on device in Phase 1.
- **Store/export friction.** Godot iOS export requires macOS + Xcode and a valid signing setup; Android requires the documented SDK/JDK toolchain. Phase 0 proves both on real devices precisely so this risk retires first.
- **Open question — project root layout:** Godot project at repo root vs. a `godot/` subdirectory (matters once `tools/` and `assets_src/` grow). Reversible in Phase 0; default to repo root unless the fixture/tooling tree argues otherwise.
- **Open question — minimum device floor:** the oldest Android/iOS versions and GPU tiers the Compatibility fallback must cover. Decide in Phase 0 from the test devices actually available; it drives renderer and material choices.

## Sources

- https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html
- https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_ios.html
- https://docs.godotengine.org/en/stable/tutorials/rendering/renderers.html
- https://www.khronos.org/gltf/
- https://gdal.org/en/stable/
- https://maplibre.org/maplibre-gl-js/docs/
- https://wiki.openstreetmap.org/wiki/Develop
