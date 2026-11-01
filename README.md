# planet-render-360

> Render any point on the map as a 3D, 360-degree view.

## Summary

Planet Render 360 is a Godot 4.7.2 mobile-first app that lets you pick any point on Earth via map tap, place search, or coordinates and generates an accurate on-device 360° 3D view of that location. It fetches real-world data from only free public sources — AWS Terrain Tiles for elevation, Esri World Imagery for satellite draping, OpenStreetMap via Overpass for buildings and roads, CHELSA for climate, Open-Meteo for weather, OpenFreeMap vector tiles and Nominatim for the map and search, and Wikipedia with Wikimedia Commons for landmark details — unified behind a shared `LocationData` contract. A staged, cancellable pipeline builds a true-metre world of far-terrain rings, DEM terrain, water and shore, extruded buildings with regional roofs and facades, recognizable landmarks, roads, and climate-driven vegetation. Rendering uses a drag-to-look 360° camera with LOD rings, a quality governor, NOAA true solar positioning, and seasonal sky and weather dressing, backed by history and built-world caching for fast revisits. Visuals aim to stay as close to reality as possible while rendering smoothly on mobile, with a polished loading flow that keeps waits to a few minutes at most.

## Core Idea and Use Case

- Pick a location by entering coordinates or selecting it on a world map.
- Procedurally generate a 360-degree view of the location, using optimized techniques suitable for mobile.
- Analyze the location so landmarks (e.g., the Eiffel Tower) are rendered recognizably — ideally generated on the fly on the device.
- Built with **Godot**, with **Blender** for offline asset preparation.

## Core Requirements

- Use only freely available APIs and data sources without strict rate limits.
- Use accurate elevation from a digital elevation model (DEM) so terrain matches the real location.
- Use accurate terrain types and visuals (e.g., [Polyhaven](https://polyhaven.com/) CC0 resources).
- Generate views on the fly over the network using free public APIs, with attribution where required — e.g., OpenFreeMap, DEM sources, and CHELSA for modeling local climate patterns, especially in complex, mountainous, or remote terrain.
- Keep loading times reasonable (a few minutes at most). Show an informative, polished loading screen that visualizes what is happening and how far loading has progressed.
- Optionally render the current time of day, season, and even current weather (e.g., rain) if time allows.

## UI and UX

- Provide intuitive controls alongside a world map for selecting locations: a turning globe, a vector map with search (/, ⌘F or Ctrl+F), featured places, and landmark markers that open a Wikipedia summary and, where one exists, a free Commons photo. The selected place shows its elevation, local time and weather; Enter explores it.
- Keep a history of recently viewed places, with favourites.
- Cache built worlds and fetched areas for faster repeat views, and download a place for offline use.
- Make the rendered 3D 360-degree view the main focus once loaded.
- Support full-screen mode with intuitive view controls.
- History and Recents show the view as you left it, and reopening a place restores where you were looking.
- In the 360 view: tap the ground or hold W A S D to walk inside the built area; play the day as a time-lapse (T) or pick any calendar date for the sun's path; name the peaks, towns and lakes on the skyline (N); show a mini-map with the view cone (M); save a photo (P) or copy a link to the exact view (C) and paste it into search to reopen it; list the landmarks nearby (L).
- Viewer keys: arrows look (Shift for bigger steps), + / − zoom, [ ] move the time by 15 minutes (Shift: an hour), 1–4 pick the season, H hides the HUD, F toggles full screen, I shows or hides the controls sheet, Esc closes an open panel and otherwise steps back to the map (⌘Q / Ctrl+Q quits).
- When live data does not arrive, the view says so in plain words and shows what it uses instead.
- Settings: Night, Day or system theme, an accent that can follow the sun, Reduce motion, Solid panels and Increase contrast, layout, units, cache size, and render quality (Fast / Balanced / High / Ultra).

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
godot --headless --script tests/class_registry_test.gd # no global class_name outside scripts/
godot --headless --script tests/shutdown_guard_test.gd # threads and network handles tear down on quit
godot --headless --script tests/leak_test.gd    # no orphan nodes in any picker layout
godot --headless --script tests/osm_test.gd     # OSM parser (offline fixture)
godot --headless --script tests/osm_fallback_test.gd # Overpass fallbacks: OSM API bbox, nearby cache
godot --headless --script tests/tiles_test.gd   # tile math + pool drain
godot --headless --script tests/map_pan_test.gd # tiles follow the drag, no repeated queueing
godot --headless --script tests/progressive_map_test.gd # progressive map: preview first, detail centre-out
godot --headless --script tests/vector_map_test.gd # vector map: MVT decode, Map style rules, tile build
godot --headless --script tests/landmark_test.gd # landmark registry, models, placement
godot --headless --script tests/landmark_fidelity_test.gd # well-mapped OSM landmarks drawn from their own parts
godot --headless --script tests/landmark_info_test.gd # landmark markers, details and visits (Wikipedia fixtures)
godot --headless --script tests/landmark_list_test.gd # 360 view's nearby-landmarks list, panel flow, L key
godot --headless --script tests/monument_test.gd # memorial columns and obelisks become landmarks
godot --headless --script tests/wheel_ground_test.gd # observation wheels + restored ground
godot --headless --script tests/preset_views_test.gd # curated preset vantages and the generic eye
godot --headless --script tests/viewer_tools_test.gd # view links, camera per place, thumbnails, photo, time-lapse, dates, horizon labels, mini-map, walking
godot --headless --script tests/user_dir_test.gd # moving data from Godot's default user directory
godot --headless --script tests/exit_tile_test.gd # exit button + stale-tile cancellation on far pans
godot --headless --script tests/search_test.gd  # place-search parser
godot --headless --script tests/weather_test.gd # weather parser
godot --headless --script tests/dem_test.gd     # live DEM decode (network once)
godot --headless --script tests/flow_test.gd    # picker -> loading -> 360 flow
godot --headless --script tests/data_notes_test.gd # degraded-data notices: loading line, card, badge
godot --headless --script tests/generation_timeout_test.gd # a place that takes too long returns to the picker
godot --headless --script tests/build_guard_test.gd # no second world build while one runs
godot --headless --script tests/loading_building_test.gd # "Building the scene" progress after the fetch
godot --headless --script tests/responsive_test.gd # breakpoints + layout switching
godot --headless --script tests/settings_test.gd # render-quality presets, persistence, FPS ceiling
godot --headless --script tests/zoom_search_test.gd # map/360 zoom, search predictions, time of day
godot --headless --script tests/accent_sun_test.gd # Auto accent follows the sun
godot --headless --script tests/sky_test.gd      # sky per season, time of day and weather
godot --headless --script tests/solar_test.gd    # true sun position vs ephemeris
godot --headless --script tests/lightning_test.gd # thunderstorm lightning by weather, season, day
godot --headless --script tests/climate_test.gd  # CHELSA reader + climate model (CLIMATE_LIVE=1 for a live read)
godot --headless --script tests/world_scale_test.gd # true-metre lat/lon conversion at the golden locations
godot --headless --script tests/terrain_scale_test.gd # terrain relief at true scale, no vertical exaggeration
godot --headless --script tests/ground_index_test.gd # land-class and building grids match full scans
godot --headless --script tests/polygon_index_test.gd # banded point-in-polygon index (Venice lagoon)
godot --headless --script tests/scenery_test.gd  # building scale, terrain normals, water, landmark
godot --headless --script tests/arid_ground_test.gd # dry ground, not lawn, in arid places
godot --headless --script tests/building_fabric_test.gd # party walls, street roofs, courtyards, facade relief
godot --headless --script tests/architecture_test.gd # regional building styles by country and kind
godot --headless --script tests/facade_relief_test.gd # window recesses and roof variety
godot --headless --script tests/far_city_test.gd # far city only where the place is built up
godot --headless --script tests/lod_test.gd     # LOD rings keep every object in place at every preset
godot --headless --script tests/render_upgrade_test.gd # grade, lit windows at night, wall tints
godot --headless --script tests/parallel_build_test.gd # parallel world build matches the serial one
godot --headless --script tests/fidelity_scorecard_test.gd # golden locations vs source data (live when uncached)
godot --script tests/screenshot_test.gd         # capture UI screenshots (phone/tablet/desktop)
godot --script tests/world_cache_test.gd        # built-world cache: save, cached revisit, eviction (windowed)
tools/check_class_size.sh                       # every class under scripts/ at or under 1000 lines
```

On macOS, launch windowed runs through `tools/godot_bg.sh` (same arguments as
`godot`, or copy it to `~/.local/bin/godot`): it keeps the window behind your
editor and adds `--windowed` so the full-screen project setting does not take
over a Space.

Current MVP: onboarding → map home (globe, vector map, tap/search/coordinates,
landmark markers) → staged loading pipeline and parallel world build → 360°
terrain view with real DEM draped in satellite imagery, drag-look, landmarks,
buildings, vegetation, time-of-day, date and season controls, live-weather
dressing and the viewer tools (walk, time-lapse, horizon labels, mini-map,
photo, view links, nearby landmarks) → on-device history, favourites and
built-world cache. All data sources are settled in the data-source register
behind the same `LocationData` contract.

## Project Structure

```text
planet-render-360/
├── project.godot              Godot 4.7 project (Forward+, 390×844 mobile-first frame)
├── export_presets.cfg         macOS / iOS / Android export presets
├── scenes/
│   └── main.tscn              Single root scene → scripts/main.gd
├── scripts/                   All app code (GDScript, ≤1000 lines per class)
│   ├── main.gd                Screen manager: Onboarding → MapPicker → Loading → View360 (+ History, Settings)
│   ├── user_dir_migration.gd  First launch from the app's own user directory: brings the old data across
│   ├── ui_theme.gd            Design-system tokens and theme (Night / Day)
│   ├── ui_prefs.gd            Appearance, accessibility, units and cache choices applied app-wide
│   ├── accent_sun.gd          Auto accent that follows the sun at the place shown
│   ├── ui_icon.gd, brand.gd   Lucide icons and the logo files from the design system
│   ├── announcer.gd           Screen-reader announcements
│   ├── hud_style.gd           Smoked-glass HUD styling for the 360 view
│   ├── responsive.gd          Phone / tablet / desktop breakpoints
│   ├── data/                  Fetch layer: one fetcher per free public source
│   │   ├── location_data.gd       LocationData — the contract between fetch, generation and render
│   │   ├── dem_fetcher.gd         AWS Terrain Tiles (Terrarium) elevation mosaics
│   │   ├── far_field_fetcher.gd   Far DEM rings + imagery drapes past the detailed extent
│   │   ├── satellite_fetcher.gd   Esri World Imagery terrain drape
│   │   ├── osm_*.gd, overpass_request.gd
│   │   │                          Overpass query, fetch, parse, tags + ring geometry; OSM API and nearby-cache fallbacks
│   │   ├── far_city_fetcher.gd    One aggregated Overpass call for the far city ring
│   │   ├── climate_fetcher.gd     CHELSA V2.1 climatologies via ranged GeoTIFF reads
│   │   ├── weather_fetcher.gd     Open-Meteo current weather
│   │   ├── search_fetcher.gd      Nominatim place search
│   │   ├── vector_tile_fetcher.gd OpenFreeMap vector tiles + Terrarium hillshade for the map
│   │   ├── tile_fetcher.gd, tile_connection.gd
│   │   │                          OSM raster tiles (globe, picker fallback) over kept-alive connections
│   │   ├── wiki_fetcher.gd, wiki_parse.gd
│   │   │                          Wikipedia + Commons landmark markers, summaries and photos
│   │   ├── landmark_*.gd          Which landmarks a place builds, how well-mapped ones draw, where to stand to see one
│   │   ├── preset_views.gd        Curated opening view for each quick-pick place
│   │   ├── horizon_fetcher.gd     One Overpass call for the named peaks, towns and lakes (horizon labels)
│   │   ├── view_link.gd           Shareable view links + the camera state History keeps per place
│   │   ├── place_thumb.gd         The History / Recents picture of a place
│   │   ├── cache_store.gd         History + versioned, LRU-capped tile/area cache
│   │   └── offline_downloader.gd  "Download for offline" cache warmer
│   ├── map/                   Vector map in the design system Map style: MVT decode, style rules,
│   │                          line meshing, hillshade, labels
│   ├── generation/            World building from LocationData (true metres)
│   │   ├── pipeline.gd            Staged, cancellable fetch pipeline: elevation, imagery, buildings & landmarks, weather
│   │   ├── world_scale.gd         Unit conversions + render origin
│   │   ├── ground_truth.gd        One height / water / land-cover surface per place
│   │   ├── ground_index.gd, polygon_index.gd
│   │   │                          Fast land-class, building and point-in-polygon lookups
│   │   ├── terrain_builder.gd     Assembles the world: far → terrain → water → buildings → roads → landmarks → vegetation
│   │   ├── world_build_graph.gd, build_*.gd
│   │   │                          Runs the build stages in parallel; texture prewarm, stop requests
│   │   ├── data_notes.gd          Plain-language record of live data that did not arrive
│   │   ├── far_*.gd, settlement_map.gd, infill_planner.gd
│   │   │                          Far terrain rings and the far city, only where the place is built up
│   │   ├── building_*.gd, roof_*.gd, facade_*.gd, storey_composer.gd, architecture_*.gd
│   │   │                          OSM building extrusion, regional style, roofs and facades
│   │   ├── road_*.gd, street_*.gd, water_*.gd, quay_builder.gd, shore_apron.gd
│   │   ├── tree_*.gd, vegetation_*.gd, foliage_textures.gd, climate_model.gd
│   │   ├── landmark_*.gd          Registry landmarks (Eiffel, Colosseum, Sagrada…) + OSM archetypes
│   │   └── material_library.gd, pbr_textures.gd, ground_*.gd, mesh_arrays.gd, mass_batch.gd
│   ├── render/                Runtime rendering
│   │   ├── camera_rig.gd          Drag-to-look 360° camera
│   │   ├── atmosphere_rig.gd      Sun, sky, haze, clouds, weather
│   │   ├── sky_palette.gd, sky_shader.gd, weather_look.gd, lightning_rig.gd
│   │   │                          Sky grade and dome shader, weather light, thunderstorm lightning
│   │   ├── post_grade.gd, city_lights.gd, roof_snow.gd
│   │   │                          Tonemap and grade, lit windows at night, snow on roofs
│   │   ├── solar_position.gd      NOAA true solar position
│   │   ├── lod_ring.gd            Static LOD rings via visibility ranges
│   │   ├── quality_governor.gd    FPS-driven render-scale / shadow steps
│   │   ├── render_settings.gd     Fast / Balanced / High / Ultra presets
│   │   ├── render_quality.gd      Photoreal layer per tier
│   │   └── world_cache.gd         Built-world cache for fast revisits
│   └── screens/               UI screens (onboarding, map home with globe and landmark markers, loading,
│                              360 view, history, settings); the viewer's tools: view_tools, photo_mode,
│                              time_lapse, date_picker, horizon_labels, mini_map, view_walk, landmark_list
├── assets/                    Runtime assets: eiffel.glb, CC0 Poly Haven PBR sets, foliage atlases,
│                              brand logos, Lucide icons, fonts
├── assets_src/blender/        Blender sources (offline only, never shipped)
├── tests/                     Headless Godot test scripts (see Development above)
├── tools/                     check_class_size.sh, godot_bg.sh, build_macos.sh, build_ios.sh,
│                              build_ios_release.sh, build_docs_pdf.js, build_bench.gd (world-build
│                              bench), capture_presets.gd (golden-set captures), foliage texture generator
├── .github/workflows/         On-demand release build (macOS .dmg, iOS TestFlight)
├── docs/                      Data-source register, world-model contract, fidelity scorecard,
│                              architecture styles, technical documentation PDF
├── .agents/plans/             Architecture, fidelity, city-realism and build-speed plans
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
