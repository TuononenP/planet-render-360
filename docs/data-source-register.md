# Data-Source Register

Gate from the architecture plan: no source enters the fetch layer until its
entry here is complete. Hard constraints — direct device access only, no
self-hosted proxy, no account, no paid key or tier, attribution preserved.

Status: elevation, buildings/roads, map tiles, land cover, search, weather, and satellite imagery **verified and wired** (2026-10-27). CHELSA climate resolved as not wired (see its row).
The pipeline falls back to a deterministic procedural DEM when offline, so
an unverified source never blocks the app.

| Need | Candidate (from README) | Endpoint | Format | Licence / attribution | Direct mobile access? | Free, no key? | Fallback | Status |
|---|---|---|---|---|---|---|---|---|
| Elevation (DEM) | AWS Terrain Tiles (Terrarium) | `https://s3.amazonaws.com/elevation-tiles-prod/terrarium/{z}/{x}/{y}.png` | PNG, height = R*256 + G + B/256 − 32768 m | Attribution required; per-region credits incl. EU-DEM/Copernicus, USGS 3DEP, SRTM — full list in the Tilezen/Joerd attribution doc linked below | Yes — verified HTTP 200 from this machine, `image/png`, no auth headers (2026-10-27) | Yes — verified, no key/account | procedural DEM, then another qualifying DEM | **verified, wired in `DemFetcher`** |
| Buildings + roads | OpenStreetMap via Overpass API | `https://overpass-api.de/api/interpreter` (POST) | JSON (`out geom`) | © OpenStreetMap contributors (ODbL); attribution shown in-app | Yes — verified HTTP 200 with real Paris buildings/roads (2026-10-27); **availability varies: HTTP 502 observed under load the same day** | Yes — no key/account | on-device cache, then procedural dressing | **verified, wired in `OsmFetcher`** |
| Map tiles (picker) | OpenStreetMap raster tiles | `https://tile.openstreetmap.org/{z}/{x}/{y}.png` | PNG 256px | © OpenStreetMap contributors; attribution always visible bottom-right of the map | Yes — OSMF Tile Usage Policy reviewed (2026-10-27): identifying User-Agent, HTTPS URL, cache ≥7 days (we cache on device), no bulk/prefetch — only visible picker tiles are fetched | Yes — no key/account | blank map + pin until tiles arrive; cached tiles offline | **verified, wired in `TileFetcher`/`MapTileView`** |
| Land cover | OpenStreetMap polygons (same Overpass fetch as buildings) | see buildings row | JSON (`natural`/`landuse`/`leisure=park` ways) | © OpenStreetMap contributors | Yes, via the verified Overpass path; note the broader query is slower and failed once under load (fallback kept the app working) | Yes | elevation-based terrain colours | **wired in `OsmFetcher`/`TerrainBuilder`** — classes: water, forest, grass, field, urban |
| Satellite imagery (terrain drape) | Esri World Imagery | `https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}` | JPEG 256px tiles, 3x3 mosaic at zoom 16 | Esri terms of use for basemap services; attribution "Esri, Maxar, Earthstar Geographics" shown in-app | Yes — verified HTTP 200, `image/jpeg`, no auth (2026-10-27) | Yes — no key/account | vertex-colour terrain dressing (Fast preset skips the fetch) | **verified, wired in `SatelliteFetcher`** |
| Climate (optional) | CHELSA V2.1 (README) | `https://os.zhdk.cloud.switch.ch/chelsav2/GLOBAL/climatologies/…` | GeoTIFF, one file per variable/month | CC-BY 4.0 (Karger et al.) — attribution required | Verified reachable HTTP 200 (2026-10-27), but one variable (bio1) is a single 115 MB global GeoTIFF; no tiled/windowed API, and GDAL is not available on-device | Yes — no key/account | season control + live Open-Meteo weather dressing (both shipped) | **resolved: not wired — file size/format fail the direct-device test in practice; climate layer dropped per gate fallback order until a tiled CHELSA mirror exists** |
| Place search | Nominatim (OSMF) | `https://nominatim.openstreetmap.org/search?format=jsonv2&limit=1&q=…` | JSON | ODbL; © OpenStreetMap contributors | Yes — usage policy reviewed (2026-10-27): user-triggered search only, **no autocomplete**, ≤1 req/s (single in-flight request), identifying User-Agent, results cached on device. Endpoint is one switchable constant, as the policy requires. The project owner deliberately adopts this service under these restrictions. | Yes — no key/account | bundled MVP gazetteer (paris/interlaken/banff) + raw coordinates | **verified policy, wired in `SearchFetcher`** |
| Weather (optional) | Open-Meteo | `https://api.open-meteo.com/v1/forecast?latitude=…&longitude=…&current=temperature_2m,weather_code,cloud_cover` | JSON | Open-Meteo terms; weather data CC-BY — attribution in register/app credits | Yes — verified HTTP 200 live (Paris 16.4 °C, overcast) 2026-10-27 | Yes — no key/account | omit weather label/dressing | **verified, wired in `WeatherFetcher`** |

## Rules

1. If a source needs a proxy, account, or payment from the device, it is
   disqualified. Replace it; never add a server as the workaround.
2. Record the exact attribution text and show it in the in-app attribution
   panel fed by the fetchers actually used.
3. Record rate limits and cache on device aggressively enough to respect
   them. Cached areas must keep working offline.
4. A fetcher normalises into `LocationData` (height grid, water level,
   landmark candidates). Generation code never parses raw provider payloads.

## Verified evidence (2026-10-27)

- `curl -sI https://s3.amazonaws.com/elevation-tiles-prod/terrarium/10/518/352.png`
  → HTTP 200, `image/png`, 121,106 bytes, S3 metadata names the EU-DEM source.
- In-engine decode (`tests/dem_test.gd`): Paris tile z12/x2074/y1409 decoded,
  sampled window 25.8–70.1 m — plausible for central Paris.
- Far backdrop uses the same AWS source at zoom 8 (`DemFetcher.fetch_far`,
  whole tile sampled 64×64): Paris tile decoded in-engine, 33–193 m across
  ~100 km, converted with the detailed grid's centre/scale in the pipeline.
- Attribution source: https://raw.githubusercontent.com/tilezen/joerd/master/docs/attribution.md
- OSM raster tiles also probed (`tile.openstreetmap.org` → HTTP 200,
  `Access-Control-Allow-Origin: *`), but tile-usage policy for production
  apps is **not yet reviewed** — map tiles remain an open row above.
- Overpass probe (Paris, 300 m): HTTP 200, 27 buildings + 53 roads with
  names and `building:levels`. Later probes returned HTTP 502 under load —
  hence the fetcher's 30 s timeout, aggressive on-device cache, and
  procedural fallback. In-engine flow with a cached real response:
  `FLOW INFO: used_real_dem=true used_osm=true`.

## Export / device evidence (2026-10-27)

- macOS: `godot --headless --export-release "macOS"` → 61 MB zip containing
  `Planet Render 360.app` (ad-hoc signed; notarization needs a developer ID).
- Android: debug APK exported (31 MB, signed) and **run on the Pixel_10_Pro
  emulator** (Android 16): picker → loading → Paris 360° view completed,
  screenshots in `generated_images/screenshots/android-*.png`.
- iOS: initially blocked on the Team ID; resolved below once the owner's
  identity was used.

## iOS signing evidence (2026-10-27, updated)

- The owner's Apple Team ID and signing identities were used locally
  (kept out of this public repository; the build script reads the Team
  ID from the `APPLE_TEAM_ID` environment variable).
- Godot export generates the Xcode project; its own post-build fails, and
  the simulator cannot link (Godot's iOS simulator template is x86_64-only,
  this Mac's simulators are arm64). Device build is the working path.
- `tools/build_ios.sh` → **BUILD SUCCEEDED**: signed arm64
  `PlanetRender360.app` (107 MB) for the app's bundle ID, via automatic
  signing (Xcode created the managed provisioning profile). Signing
  identifiers are intentionally not recorded here.
- The owner's iPad Pro was `unavailable` at build time, so on-device
  install/run is the one remaining iOS check: connect/unlock it and run
  the `xcrun devicectl` command printed by the script.
