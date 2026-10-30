# planet-render-360

> Render any point on the map as a 3D, 360-degree view.

## Summary

Enter coordinates or pick any location on a world map to generate an accurate 360-degree view of that place. Visuals don't need to be photorealistic, but they should be as close to reality as possible while still rendering smoothly in Godot on a mobile phone.

## Core Idea and Use Case

- Pick a location by entering coordinates or selecting it on a world map.
- Procedurally generate a 360-degree view of the location, using optimized techniques suitable for mobile.
- Analyze the location so landmarks (e.g., the Eiffel Tower) are rendered recognizably — ideally generated on the fly on the device.
- Implementation will likely use **Godot**, possibly with **Blender** for asset preparation.

## Core Requirements

- Use only freely available APIs and data sources without strict rate limits.
- Use accurate elevation from a digital elevation model (DEM) so terrain matches the real location.
- Use accurate terrain types and visuals (e.g., [Polyhaven](https://polyhaven.com/) CC0 resources).
- Generate views on the fly over the network using free public APIs, with attribution where required — e.g., OpenFreeMap, DEM sources, and CHELSA for modeling local climate patterns, especially in complex, mountainous, or remote terrain.
- Keep loading times reasonable (a few minutes at most). Show an informative, polished loading screen that visualizes what is happening and how far loading has progressed.
- Optionally render the current time of day, season, and even current weather (e.g., rain) if time allows.

## UI and UX

- Provide intuitive controls alongside a world map for selecting locations.
- Keep a history of recently viewed places.
- Support caching areas for faster repeat views (planned).
- Make the rendered 3D 360-degree view the main focus once loaded.
- Support full-screen mode with intuitive view controls.

## Platforms

Initial development targets **macOS** for easier development and testing, followed by **iOS** and **Android**.

## Development

Stack: Godot 4.7.2 (standard, non-.NET build) + GDScript, Blender offline
for assets, GDAL for dev-time geo data prep. No Flutter, no self-hosted
server, free with no paywall. Architecture:
[`.agents/plans/2026-10-27-planet-render-360-architecture.md`](.agents/plans/2026-10-27-planet-render-360-architecture.md),
data-source gate: [`docs/data-source-register.md`](docs/data-source-register.md).

Run: open the project in Godot 4.7.2, or from the repo root:

```sh
godot --path .            # run the app
godot --headless --script tests/smoke_test.gd   # contract checks
godot --headless --script tests/osm_test.gd     # OSM parser (offline fixture)
godot --headless --script tests/tiles_test.gd   # tile math + pool drain
godot --headless --script tests/progressive_map_test.gd # progressive map: preview first, detail centre-out
godot --headless --script tests/landmark_test.gd # landmark registry, models, placement
godot --headless --script tests/exit_tile_test.gd # exit button + stale-tile cancellation on far pans
godot --headless --script tests/search_test.gd  # place-search parser
godot --headless --script tests/weather_test.gd # weather parser
godot --headless --script tests/dem_test.gd     # live DEM decode (network once)
godot --headless --script tests/flow_test.gd    # picker -> loading -> 360 flow
godot --headless --script tests/responsive_test.gd # breakpoints + layout switching
godot --headless --script tests/zoom_search_test.gd # map/360 zoom, search predictions, time of day
godot --headless --script tests/sky_test.gd      # sky per season and time of day
godot --headless --script tests/solar_test.gd    # true sun position vs ephemeris
godot --headless --script tests/climate_test.gd  # CHELSA reader + climate model (CLIMATE_LIVE=1 for a live read)
godot --headless --script tests/scenery_test.gd  # building scale, terrain normals, water, landmark
godot --script tests/screenshot_test.gd         # capture UI screenshots (phone/tablet/desktop)
godot --script tests/world_cache_test.gd        # built-world cache: save, cached revisit, eviction (windowed)
```

Current MVP: map picker (tap/search/coordinates) → staged loading pipeline
→ 360° terrain view with real DEM draped in satellite imagery, drag-look,
landmarks, buildings, vegetation, time-of-day and season controls, and
live-weather dressing → on-device history/cache. All data sources are
settled in the data-source register behind the same `LocationData` contract.

## Project Structure

```text
planet-render-360/
├── project.godot              Godot 4.7 project (Forward+, 390×844 mobile-first frame)
├── export_presets.cfg         macOS / iOS / Android export presets
├── scenes/
│   └── main.tscn              Single root scene → scripts/main.gd
├── scripts/                   All app code (GDScript, ≤500 lines per class)
│   ├── main.gd                Screen manager: MapPicker → Loading → View360 (+ History, Settings)
│   ├── ui_theme.gd            Shared "Night Atlas" theme
│   ├── hud_style.gd           Smoked-glass HUD styling for the 360 view
│   ├── responsive.gd          Phone / tablet / desktop breakpoints
│   ├── data/                  Fetch layer: one fetcher per free public source
│   │   ├── location_data.gd       LocationData — the contract between fetch, generation and render
│   │   ├── dem_fetcher.gd         AWS Terrain Tiles (Terrarium) elevation mosaics
│   │   ├── far_field_fetcher.gd   Far DEM rings + imagery drapes past the detailed extent
│   │   ├── satellite_fetcher.gd   Esri World Imagery terrain drape
│   │   ├── osm_*.gd               Overpass query, fetch, parse, tag + ring geometry
│   │   ├── far_city_fetcher.gd    One aggregated Overpass call for the far city ring
│   │   ├── climate_fetcher.gd     CHELSA V2.1 climatologies via ranged GeoTIFF reads
│   │   ├── weather_fetcher.gd     Open-Meteo current weather
│   │   ├── search_fetcher.gd      Nominatim place search
│   │   ├── tile_fetcher.gd        OSM raster tiles for the picker map
│   │   ├── cache_store.gd         History + versioned, LRU-capped tile/area cache
│   │   └── offline_downloader.gd  "Download for offline" cache warmer
│   ├── generation/            World building from LocationData (true metres)
│   │   ├── pipeline.gd            Staged, cancellable 5-stage generation pipeline
│   │   ├── world_scale.gd         Unit conversions + render origin
│   │   ├── ground_truth.gd        One height / water / land-cover surface per place
│   │   ├── terrain_builder.gd     Assembles the world: far → terrain → water → buildings → roads → landmarks → vegetation
│   │   ├── far_*.gd               Far terrain rings and the far city
│   │   ├── building_*.gd, roof_*.gd, facade_*.gd, storey_composer.gd, architecture_*.gd
│   │   │                          OSM building extrusion, regional style, roofs and facades
│   │   ├── road_builder.gd, street_props.gd, water_*.gd, quay_builder.gd, shore_apron.gd
│   │   ├── tree_*.gd, vegetation_*.gd, foliage_textures.gd, climate_model.gd
│   │   ├── landmark_*.gd          Registry landmarks (Eiffel, Colosseum, Sagrada…) + OSM archetypes
│   │   └── material_library.gd, pbr_textures.gd, ground_*.gd, mesh_arrays.gd, mass_batch.gd
│   ├── render/                Runtime rendering
│   │   ├── camera_rig.gd          Drag-to-look 360° camera
│   │   ├── atmosphere_rig.gd      Sun, sky, haze, clouds, weather
│   │   ├── solar_position.gd      NOAA true solar position
│   │   ├── lod_ring.gd            Static LOD rings via visibility ranges
│   │   ├── quality_governor.gd    FPS-driven render-scale / shadow steps
│   │   ├── render_settings.gd     Fast / Balanced / High / Ultra presets
│   │   ├── render_quality.gd      Photoreal layer per tier
│   │   └── world_cache.gd         Built-world cache for fast revisits
│   └── screens/               UI screens (map picker, loading, 360 view, history, settings)
├── assets/                    Runtime assets: eiffel.glb, CC0 Poly Haven PBR sets, foliage atlases
├── assets_src/blender/        Blender sources (offline only, never shipped)
├── tests/                     Headless Godot test scripts (see Development above)
├── tools/                     check_class_size.sh, build_ios.sh, foliage texture generator
├── docs/                      Data-source register, world-model contract, fidelity scorecard,
│                              architecture styles, technical documentation PDF
├── .agents/plans/             Architecture and fidelity-redesign plans
├── visual-plan/               PRD, review captures and scorecards
└── generated_images/          Logo explorations, prototypes and screenshots
```

## Documentation

- [Technical documentation (PDF)](docs/technical-documentation.pdf) — architecture,
  data flow, pipeline, world model, rendering and caching, with diagrams.
  Source: [`docs/technical-documentation.html`](docs/technical-documentation.html),
  rebuilt with `node tools/build_docs_pdf.js`.
- [World-model contract](docs/world-model-contract.md) — `LocationData`, `GroundTruth`, builder signatures.
- [Data-source register](docs/data-source-register.md) — every external source, licence and fallback.
- [Fidelity scorecard](docs/fidelity-scorecard.md) — checks that prove the contract holds.
- [Architecture styles](docs/architecture-styles.md) — regional building styles.

## License

Distributed under the MIT License. See [LICENSE](LICENSE) for details.
