# planet-render-360

> Render any point on the map as a 3D, 360-degree view.

## Summary

Planet Render 360 is a Godot 4.7.2 mobile-first app that lets you pick any point on Earth via map tap, place search, or coordinates and generates an accurate on-device 360° 3D view of that location. It fetches real-world data from only free public sources — AWS Terrain Tiles for elevation, Esri World Imagery for satellite draping, OpenStreetMap via Overpass for buildings and roads, CHELSA for climate, and Open-Meteo for weather — unified behind a shared `LocationData` contract. A staged, cancellable pipeline builds a true-metre world of far-terrain rings, DEM terrain, water and shore, extruded buildings with regional roofs and facades, recognizable landmarks, roads, and climate-driven vegetation. Rendering uses a drag-to-look 360° camera with LOD rings, a quality governor, NOAA true solar positioning, and seasonal sky and weather dressing, backed by history and built-world caching for fast revisits. Visuals aim to stay as close to reality as possible while rendering smoothly on mobile, with a polished loading flow that keeps waits to a few minutes at most.

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
- History and Recents show the view as you left it, and reopening a place restores where you were looking.
- In the 360 view: tap the ground or hold W A S D to walk inside the built area; play the day as a time-lapse (T) or pick any calendar date for the sun's path; name the peaks, towns and lakes on the skyline (N); show a mini-map with the view cone (M); save a photo (P) or copy a link to the exact view (C) and paste it into search to reopen it.

## Platforms

Initial development targets **macOS** for easier development and testing, followed by **iOS** and **Android**.

### Building releases

Release builds run from GitHub Actions on demand: **Actions → Build → Run workflow**
([`.github/workflows/build.yml`](.github/workflows/build.yml)). Inputs:

- `platform`: `both`, `macos` or `ios`
- `macos_signing`: `adhoc` (no secrets needed) or `notarized` (Developer ID signed, notarized, stapled)
- `version`: the marketing version, e.g. `0.1.0`; the build number is the workflow run number
- `testflight`: upload the iOS build to TestFlight, or attach the `.ipa` to the run instead

The macOS `.dmg` is attached to the run as an artifact. Secrets live in the `release`
environment and are never committed:

| Secret | Used for |
| --- | --- |
| `APPLE_TEAM_ID` | iOS signing |
| `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_P8_BASE64` | App Store Connect API key (Admin role): iOS automatic signing, TestFlight upload, macOS notarization |
| `MACOS_SIGN_IDENTITY` | e.g. `Developer ID Application: Name (TEAMID)` |
| `MACOS_CERT_P12_BASE64`, `MACOS_CERT_PASSWORD` | the Developer ID certificate exported as `.p12` (`base64 -i cert.p12`) |

The first TestFlight upload also needs an App Store Connect app record for
`com.planetrender360.app`. The same scripts run locally:

```sh
tools/build_macos.sh               # ../build/macos/PlanetRender360.dmg (ad-hoc; set MACOS_SIGN_IDENTITY + ASC_* to notarize)
IOS_UPLOAD=0 tools/build_ios_release.sh  # ../build/ios/export/*.ipa (needs APPLE_TEAM_ID + ASC_*)
```

An ad-hoc macOS build opens on other Macs after `xattr -dr com.apple.quarantine "Planet Render 360.app"`.
Exported builds keep their data in `~/Library/Application Support/Planet Render 360/`.

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
godot --headless --script tests/vector_map_test.gd # vector map: MVT decode, Map style rules, tile build
godot --headless --script tests/landmark_test.gd # landmark registry, models, placement
godot --headless --script tests/landmark_list_test.gd # 360 view's nearby-landmarks list, panel flow, L key
godot --headless --script tests/viewer_tools_test.gd # view links, camera per place, thumbnails, photo, time-lapse, dates, horizon labels, mini-map, walking
godot --headless --script tests/exit_tile_test.gd # exit button + stale-tile cancellation on far pans
godot --headless --script tests/search_test.gd  # place-search parser
godot --headless --script tests/weather_test.gd # weather parser
godot --headless --script tests/dem_test.gd     # live DEM decode (network once)
godot --headless --script tests/flow_test.gd    # picker -> loading -> 360 flow
godot --headless --script tests/responsive_test.gd # breakpoints + layout switching
godot --headless --script tests/zoom_search_test.gd # map/360 zoom, search predictions, time of day
godot --headless --script tests/sky_test.gd      # sky per season, time of day and weather
godot --headless --script tests/solar_test.gd    # true sun position vs ephemeris
godot --headless --script tests/lightning_test.gd # thunderstorm lightning by weather, season, day
godot --headless --script tests/climate_test.gd  # CHELSA reader + climate model (CLIMATE_LIVE=1 for a live read)
godot --headless --script tests/scenery_test.gd  # building scale, terrain normals, water, landmark
godot --headless --script tests/building_fabric_test.gd # party walls, street roofs, courtyards, facade relief
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
│   │   ├── horizon_fetcher.gd     One Overpass call for the named peaks, towns and lakes (horizon labels)
│   │   ├── view_link.gd           Shareable view links + the camera state History keeps per place
│   │   ├── place_thumb.gd         The History / Recents picture of a place
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
│   └── screens/               UI screens (map picker, loading, 360 view, history, settings);
│                              the viewer's tools: view_tools, photo_mode, time_lapse, date_picker,
│                              horizon_labels, mini_map, view_walk
├── assets/                    Runtime assets: eiffel.glb, CC0 Poly Haven PBR sets, foliage atlases
├── assets_src/blender/        Blender sources (offline only, never shipped)
├── tests/                     Headless Godot test scripts (see Development above)
├── tools/                     check_class_size.sh, build_ios.sh, build_ios_release.sh, build_macos.sh, foliage texture generator
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
