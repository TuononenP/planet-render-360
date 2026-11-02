# Data-Source Register

Gate from the architecture plan: no source enters the fetch layer until its
entry here is complete. Hard constraints — direct device access only, no
self-hosted proxy, no account, no paid key or tier, attribution preserved.

Status: elevation, buildings/roads, map tiles, land cover, search, weather, and satellite imagery **verified and wired** (2026-10-27). CHELSA climate wired 2026-10-30 via ranged GeoTIFF reads (see its row).
The pipeline falls back to a deterministic procedural DEM when offline, so
an unverified source never blocks the app.

| Need | Candidate (from README) | Endpoint | Format | Licence / attribution | Direct mobile access? | Free, no key? | Fallback | Status |
|---|---|---|---|---|---|---|---|---|
| Elevation (DEM) | AWS Terrain Tiles (Terrarium) | `https://s3.amazonaws.com/elevation-tiles-prod/terrarium/{z}/{x}/{y}.png` — same endpoint at zoom 14 (near mosaic), 12 (mid), 8 (far); T2.1 | PNG 256px, height = R*256 + G + B/256 − 32768 m; z14 ≈ 9.6 m/px at equator (≈6.3 m/px at Paris latitude) | Attribution required; per-region credits incl. EU-DEM/Copernicus ("Europe terrain data produced using Copernicus data and information funded by the European Union - EU-DEM layers"), USGS 3DEP, SRTM — full list in the Tilezen/Joerd attribution doc (`https://github.com/tilezen/joerd/blob/master/docs/attribution.md`); AWS Open Data page `https://registry.opendata.aws/terrain-tiles/` points to the same doc as the licence | Yes — z14 verified HTTP 200, `image/png`, no auth (2026-10-28): Paris tile `14/8299/5636` (78,499 bytes, S3 source tag `eudem_dem_5deg_n45e000.tif`) and Interlaken neighbour `14/8550/5783` both 200; decoded Paris window 27.2–61.1 m, consistent with the z12 reading | Yes — verified, no key/account; S3 static tiles, no published rate limit — still cache per tile (`user://cache`) and fetch mosaics in a bounded pool | tile failure → lower zoom for that cell → per-tile cache → procedural DEM (T2.1) | **verified, wired in `DemFetcher` (z12+z8); z14 mosaic gate passed for T2.1** |
| Buildings + roads | OpenStreetMap via Overpass API | Same endpoint(s) as wired (`OsmFetcher.ENDPOINTS`, POST) — **no new endpoint** for T2.3; richer tags + wider radius ride the existing query | JSON (`out geom` already returns all tags; T2.3 only parses more of them) | © OpenStreetMap contributors (ODbL); attribution shown in-app | Yes — same verified path; expanded tags confirmed present in live data (2026-10-28): 31 Paris ways returned `height` (4), `building:levels` (19), `roof:shape` (2); global taginfo counts confirm `building:colour` (107k), `roof:colour` (180k), `building:material`, `roof:material`, `roof:height`, `min_height`, `building:part` all in use. Note: `overpass-api.de` returns HTTP 406 to default curl UA — identifying `User-Agent` (as the fetcher sends) is required | Yes — no key/account; **rate limits:** shared free capacity, HTTP 502/429 under load already observed — keep `[timeout:30]`, the 5-endpoint retry chain, identifying UA, preset-scaled radius, and aggressive cache (T2.3/T2.5) | per-tag fallback: missing tag → existing default (`building:levels×3.2` → `height` → documented regional default, never global 10 m); query failure → on-device cache → procedural-absence-only dressing | **verified, wired in `OsmFetcher`; tag expansion gate passed for T2.3 (parse-only, no endpoint change)** |
| Map tiles (globe; picker fallback) | OpenStreetMap raster tiles | `https://tile.openstreetmap.org/{z}/{x}/{y}.png` | PNG 256px | © OpenStreetMap contributors; attribution always visible bottom-right of the map | Yes — OSMF Tile Usage Policy reviewed (2026-10-27): identifying User-Agent, HTTPS URL, cache ≥7 days (we cache on device), no bulk/prefetch — only visible picker tiles are fetched | Yes — no key/account | blank map + pin until tiles arrive; cached tiles offline | **verified, wired in `TileFetcher`/`MapTileView`** |
| Map tiles (picker, vector) | OpenFreeMap public instance (design system Map style) | TileJSON `https://tiles.openfreemap.org/planet` names the dated tile path (`/planet/<build>/{z}/{x}/{y}.pbf`, z0–14); fetched once, cached in `user://cache/vector/tiles_path.txt` for offline use | Mapbox Vector Tile v2, OpenMapTiles schema, served `Content-Encoding: gzip` (inflated in `VectorTileFetcher.inflate`); `Cache-Control: max-age=315360000` (immutable per build) | Attribution required: "OpenFreeMap © OpenMapTiles Data from OpenStreetMap" (openfreemap.org, checked 2026-11-01); shown as "© OpenStreetMap contributors · © OpenMapTiles" on the map chip and in full (plus "Terrain: AWS Terrain Tiles" for the hillshade) in the picker's attribution line; project MIT, data ODbL | Yes — HTTPS, identifying User-Agent, only visible tiles, cached on device (`VectorTileFetcher`) | Yes — public instance "completely free: no limits on the number of map views or requests… no registration… no API keys" (openfreemap.org, 2026-11-01) | map-land ground + cached tiles offline; `MapTileView.vector = false` restores the OSM raster path | **verified (TileJSON + z4/z9/z13/z14 tiles decoded against mapbox-vector-tile, 2026-11-01), wired in `VectorTileFetcher`/`VectorMapLayer`** |
| Hillshade (picker) | AWS Terrain Tiles (Terrarium) — same source as the Elevation row | same endpoint, at the vector tile's data zoom, only up to style zoom 12 (`MapStyle.SHADE_MAX_ZOOM`) | PNG 256px Terrarium | as the Elevation row | Yes — same verified path, own cache `user://cache/vector/dem_*.png` | Yes | no relief (flat map) | **wired in `VectorMapLayer`** |
| Land cover | OpenStreetMap polygons (same Overpass fetch as buildings) | see buildings row — **no new endpoint** for T2.4; new classes + `waterway`/`natural=tree`/`barrier` parse from the same payload (query adds key selectors only) | JSON (`natural`/`landuse`/`leisure`/`waterway` ways + relations + `natural=tree` nodes) | © OpenStreetMap contributors (ODbL); attribution shown in-app | Yes, via the verified Overpass path; note the broader query is slower and failed once under load (fallback kept the app working) | Yes — no key/account; same Overpass rate discipline as the buildings row | unmapped tag → documented in register (§ Land-cover tag mapping) + dropped (never misclassified); query failure → elevation-based terrain colours | **verified, wired in `OsmFetcher`** — 13 classes + multipolygon holes (T2.4, same endpoint; live evidence below) |
| Satellite imagery (terrain drape) | Esri World Imagery | `https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}` — same endpoint at zoom 17 (High) / 18 (Ultra) / 16 (Fast/Balanced); T2.2 | JPEG 256px tiles; service exposes levels 0–23 but true imagery resolution varies by area — Paris verified real (non-blank) at z17 + z18 | Esri Web Site and Service Terms of Use (`https://www.esri.com/en-us/legal/terms/web-site-service`): §2.2 grants free download/view/copy for own internal or **noncommercial** external purposes with proper attribution; §2.2.1 commercial use needs a separate Esri licence + fee; Esri may alter/discontinue free services at its discretion. In-app attribution text (from live service metadata 2026-10-28): "Source: Esri, Vantor, Earthstar Geographics, and the GIS User Community" (note: Maxar renamed to Vantor — update the app's credit string) | Yes — z17 + z18 verified HTTP 200, `image/jpeg`, no auth (2026-10-28): Paris `17/45092/66392` (21,034 bytes) and `18/90184/132784` (19,614 bytes) downloaded and confirmed varied imagery (pixel std ≈55, not blank/oversampled) | Yes — no key/account; **rate limits:** CloudFront-fronted (`Cache-Control: max-age=86400`), no published quota, but the service is meant for interactive use, not bulk download — cache every tile on device (`user://cache`), bounded pool, tier-sized mosaics only | tile failure → lower zoom for that cell → per-tile cache → vertex-colour terrain dressing (Fast preset skips the fetch) | **verified, wired in `SatelliteFetcher` (z16); z17/z18 gate passed for T2.2 — noncommercial-free; re-check licence before any paid/commercial release** |
| Climate | CHELSA V2.1 climatologies 1981–2010 (bio10 / bio11 / bio12 / bio18 / scd) | `https://os.zhdk.cloud.switch.ch/chelsav2/GLOBAL/climatologies/1981-2010/bio/CHELSA_<var>_1981-2010_V.2.1.tif` — **HTTP range requests** (`Accept-Ranges: bytes`, verified 206) | Global GeoTIFF 43200 × 20880 (30″ ≈ 1 km), uint16, one deflate strip per row, horizontal predictor; GDAL scale/offset per variable (temperatures K × 0.1 − 273.15). Per place: first IFD (16 KB) + 3 strip-table entries + 3 compressed rows (≈10–45 KB) per variable → 3 × 3 cell median | CC BY 4.0 — Karger, D.N. et al. (2017) *Climatologies at high resolution for the earth's land surface areas*, Sci. Data 4, 170122; credited in-app ("Climate: CHELSA V2.1 (Karger et al.)") | Yes — ~0.3–0.6 MB and ~3–4 s per place uncached, verified on Paris / Interlaken / Big Sur (2026-10-30); cached per place (`climate_v2_*.json`, 5 ms) | Yes — no key/account | latitude snow line / treeline / regional biome (ClimateModel fallbacks) | **verified, wired 2026-10-30 (`ClimateFetcher` → `LocationData.climate` → `ClimateModel`)** — supersedes the 2026-10-27 "not wired" decision, which assumed whole-file downloads |
| Climate (fallback) | Open-Meteo Historical Weather API — ERA5 / ERA5-Land daily, 2001–2010 (`temperature_2m_mean`, `precipitation_sum`) | `https://archive-api.open-meteo.com/v1/archive?latitude=…&longitude=…&start_date=2001-01-01&end_date=2010-12-31&daily=temperature_2m_mean,precipitation_sum&timezone=GMT` | JSON, ~3650 days; ~25 km reanalysis downscaled to the point's elevation by Open-Meteo. Monthly means → warmest / coldest 3-month means, annual and warmest-quarter precipitation; snow days ≈ days with a mean ≤ 0 °C | CC BY 4.0 — Open-Meteo; contains modified Copernicus Climate Change Service information; credited in-app ("Climate: ERA5 (Copernicus) via Open-Meteo") | Yes — ~18 KB gzipped, ~1.5–3 s; weighs ~50 Open-Meteo calls, so only used when CHELSA fails or runs past 14 s; cached per place like CHELSA | Yes — no key/account | latitude rules (ClimateModel) | **wired 2026-11-01 (`ClimateFetcher._fetch_fallback`)** — within 1 °C of CHELSA on Paris / Interlaken / Banff / Turku / Cairo, ~3.5 °C warm at Big Sur (coastal cell) |
| Land cover (raster, realism v3 R-2.2) | ESA WorldCover 10 m v200 (2021) | `https://esa-worldcover.s3.eu-central-1.amazonaws.com/v200/2021/map/ESA_WorldCover_10m_2021_v200_<N or S><lat3><E or W><lon3>_Map.tif` (3° tiles named by their SW corner) — **HTTP range requests** (`Accept-Ranges: bytes`, verified 206, anonymous) | Cloud-optimised GeoTIFF, EPSG:4326, 36000 × 36000 uint8 classes (10 tree, 20 shrub, 30 grass, 40 crop, 50 built, 60 bare, 70 snow/ice, 80 water, 90 wetland, 95 mangrove, 100 moss), Deflate, no predictor, 1024² tiles, overviews ×2 to 1125². Per place: IFD + tile tables (~16 KB) + ≤ 2×2 tiles for the ±1200 m window, one overview window for the far rings | CC BY 4.0 — “© ESA WorldCover project 2021 / Contains modified Copernicus Sentinel data (2021) processed by ESA WorldCover consortium”; credited in-app | Yes — spike 2026-11-01: HEAD 200, range GET 206, header parsed (Paris tile N48E000, 74 MB file, never downloaded whole) | Yes — public AWS Open Data bucket, no key/account | OSM land cover + today's photo-greenness heuristic (current behaviour) | **spike verified 2026-11-01, not wired** (planned `CogReader` + `LandcoverFetcher`, `.agents/plans/2026-11-01-city-realism-v3.md` R-2.2) |
| Tree canopy height (raster, realism v3 R-2.2) | Meta / WRI High Resolution Canopy Height Maps v2 (DINOv3 global, ml3) | `https://dataforgood-fb-data.s3.amazonaws.com/forests/v2/global/dinov3_global_chm_v2_ml3/chm/<quadkey>.tif` (zoom-10 Bing quadkey, computable from lat/lon; index `tiles.geojson` alongside) — **HTTP range requests** (verified 206, anonymous) | Cloud-optimised GeoTIFF, EPSG:3857, 32768 × 32768 uint8 canopy height (m), Deflate, no predictor, 512² tiles (mean ~28 KB); IFD1 is a 1-bit mask, overviews 16384…2048. Per place: header + tile tables (~33 KB) + ~3×3 tiles of the 8192² overview (~3 m/px) for the ±1200 m window | CC BY 4.0 — “Canopy height: © Meta and World Resources Institute (High Resolution Canopy Height Maps)”; credited in-app | Yes — spike 2026-11-01: range GET 206, all IFDs parsed (Paris tile `1202200110`, 179 MB file, never downloaded whole) | Yes — public AWS Open Data bucket, no key/account | WorldCover tree class, then OSM trees + park groves (current behaviour) | **spike verified 2026-11-01, not wired** (R-2.2) |
| Place search | Nominatim (OSMF) | `https://nominatim.openstreetmap.org/search?format=jsonv2&limit=1&q=…` | JSON | ODbL; © OpenStreetMap contributors | Yes — usage policy reviewed (2026-10-27): user-triggered search only, **no autocomplete**, ≤1 req/s (single in-flight request), identifying User-Agent, results cached on device. Endpoint is one switchable constant, as the policy requires. The project owner deliberately adopts this service under these restrictions. | Yes — no key/account | bundled MVP gazetteer (paris/interlaken/banff) + raw coordinates | **verified policy, wired in `SearchFetcher`** |
| Landmark markers + details | Wikipedia (GeoSearch + REST page summary) and Wikimedia Commons (lead photo) | Nearby: `https://en.wikipedia.org/w/api.php?action=query&format=json&formatversion=2&generator=geosearch&ggscoord=LAT\|LON&ggsradius=≤10000&ggslimit=500&ggsprimary=primary&prop=info\|description\|coordinates`; details: `https://{lang}.wikipedia.org/api/rest_v1/page/summary/{Title}`; photo: `https://commons.wikimedia.org/w/api.php?action=query&titles=File:X&prop=imageinfo&iiprop=url\|extmetadata&iiurlwidth=640` then the returned `thumburl` on `thumb.wikimedia.org` | JSON; photo JPEG/PNG/WebP. GeoSearch's coordinate `type` is almost always empty, so `WikiParse` keeps pages whose short description names a physical place (word allowlist/denylist) and ranks them by article `length` | Article text CC BY-SA 4.0 — "Text from Wikipedia · CC BY-SA 4.0" under every extract, plus a Data sources row. Photos only when the file is on Commons (`/wikipedia/commons/`; `/wikipedia/en/` uploads are often non-free logos — the Eiffel Tower's lead image is one), credited per photo with its Artist + LicenseShortName from `extmetadata` | Yes — verified 2026-11-01: GeoSearch 500 pages in 1.7–2.7 s (Paris, Zermatt, Turku; Matterhorn / Eiffel Tower / Turku Cathedral rank top), summary HTTP 200 (`Matterhorn`, `Eiffel_Tower`), imageinfo 200 with credit, `thumburl` 200 `image/jpeg` 145 KB. Note: thumbnails at non-standard widths (e.g. `640px-`) now return HTTP 400 — always use the `thumburl` the API returns | Yes — no key/account. Wikimedia etiquette: identifying User-Agent with contact URL (`WikiFetcher.USER_AGENT`), one request in flight per channel, nearby lookups only after the map settles (0.01° cell + 1 km radius steps), every answer cached on device (`wiki_*` keys, LRU) | no article → card shows name, kind and readouts with "No article found for this place."; offline → cached answers, else "You're offline. Details open when you're back online."; nearby failure → curated registry markers only | **verified, wired in `WikiFetcher` / `WikiParse` (2026-11-01)**. Rejected: Wikidata SPARQL ranked by sitelinks (31 s for Paris, returns languages/events/regions) |
| Weather (optional) | Open-Meteo | `https://api.open-meteo.com/v1/forecast?latitude=…&longitude=…&current=temperature_2m,weather_code,cloud_cover` | JSON | Open-Meteo terms; weather data CC-BY — attribution in register/app credits | Yes — verified HTTP 200 live (Paris 16.4 °C, overcast) 2026-10-27 | Yes — no key/account | omit weather label/dressing | **verified, wired in `WeatherFetcher`** |
| PBR textures (buildings/roads/terrain, Phase 4) | Poly Haven textures | Browse/search API `https://api.polyhaven.com/assets?t=textures`, per-asset files `https://api.polyhaven.com/files/{id}`, downloads `https://dl.polyhaven.org/file/ph-assets/Textures/…` — **build-time bundling into `assets/` (T4.3), not a runtime fetch** | Full PBR sets per asset: Diffuse/Albedo + nor_gl (OpenGL normal) + Rough (+ AO, Displacement, arm) in jpg/png/exr at 1k/2k/4k/8k | **CC0 1.0 Universal (public domain)** per `https://polyhaven.com/license`: any purpose incl. commercial, redistribution incl. in sold products; **attribution not required** (courtesy credit "Textures: Poly Haven (CC0)" recommended in app credits) | N/A (bundled at build time) — but verified reachable without key anyway (2026-10-28): asset list HTTP 200 (869 textures), `/files/aerial_beach_01` HTTP 200, 2k diffuse download HTTP 200 `image/jpeg` 457,152 bytes, real 2048×2048 JPEG | Yes — no key/account for API or downloads; no published rate limit — download each chosen set once at build time, commit to `assets/` with `.import`, never hot-link from the device | procedural textures (current `_speckle`/`_facades`/`_slate` path) if a set is missing | **verified, gate passed for T4.3 — nothing rejected (no proxy/account/key needed)** |

## Bundled PBR sets — T4.3 (2026-10-28)

13 photographic sets, 1k jpg (Diffuse + nor_gl OpenGL normal + Rough),
verified choice-by-choice against previews (two blind picks rejected:
`roof_slates_02` is wooden shingles, `beige_wall_001` is near-flat —
kept only as the smooth limestone base). Every file below downloaded
exact-size from `https://dl.polyhaven.org/file/ph-assets/Textures/jpg/1k/…`
(per-asset URLs in `https://api.polyhaven.com/files/{id}`). All CC0 1.0
(public domain, attribution not required; courtesy credit recommended).
39 files, ≈23 MB under `assets/textures/` as `<set>_{diff,nor,rough}.jpg`.
Render upgrade (2026-10-30): six terrain sets added the same way (18 files,
≈17 MB, 1k jpg, CC0), packed at runtime into the terrain layer arrays
(`TerrainTextures`).

| set | Poly Haven asset | diff / nor / rough bytes | use |
|---|---|---|---|
| limestone | `beige_wall_001` | 33074 / 153434 / 151256 | Haussmann facades; calibrated to PRD #D6C5A3 |
| stone | `old_sandstone_02` | 747284 / 1031253 / 546307 | rustic stone facades (`material=stone`) |
| render | `white_stucco` | 557550 / 932038 / 347861 | plaster/render facades, glacier ground |
| brick | `brick_wall_001` | 574381 / 295279 / 211093 | brick facades, chimneys |
| concrete | `concrete` | 543902 / 114447 / 215714 | concrete-panel facades/roofs |
| wood | `brown_planks_03` | 570668 / 516860 / 222197 | timber facades, shingle roofs |
| slate | `grey_roof_tiles_02` | 402212 / 570336 / 346538 | slate roofs; calibrated to PRD #46525E |
| terracotta | `clay_roof_tiles` | 878367 / 1101177 / 306665 | clay-tile roofs |
| membrane | `bitumen` | 451335 / 691370 / 272094 | flat-roof membrane |
| asphalt | `asphalt_01` | 739513 / 1237059 / 344964 | asphalt ground (roads consume in T4.4) |
| pavement | `concrete_pavement` | 926197 / 1184345 / 475799 | pavement/urban ground |
| grass | `grass_ground` | 876584 / 1310516 / 328190 | grass-class ground |
| rock | `brown_mud_rocks_01` | 887215 / 1400087 / 719533 | rock/quarry ground |
| cliff | `rock_face_03` | 927082 / 1146788 / 638904 | cliff faces and steep ground (terrain layer, biplanar) |
| forest | `forest_leaves_02` | 437891 / 577163 / 192523 | forest floor (terrain layer) |
| lawn | `leafy_grass` | 1195394 / 1466049 / 511385 | mown lawns, parks, meadows (terrain layer) |
| gravel | `gravel_floor` | 1327302 / 1538430 / 697340 | gravel paths, scree, quarries (terrain layer) |
| sand | `coast_sand_01` | 960614 / 1146826 / 383892 | beaches and sand (terrain layer) |
| snow | `snow_02` | 325497 / 1081858 / 146089 | climate snow over terrain (terrain layer) |

Glass is the documented absence: the API catalog (869 textures,
2026-10-28) returns 0 hits for "glass", so curtain-wall glass stays
procedural (`MaterialLibrary._compose_glass`) per the fallback order.
Runtime loading needs no `.import` (`Image.load_from_file` +
manual sRGB→linear, probe-verified); `.import` files generate on the
first clean editor import (blocked 2026-10-28 by an unrelated
`view_360.gd:427` parse error from another session's E-owned edit).

## Desktop-Ultra 2K PBR sets — Ultra pass Phase 6 (2026-11-02)

The 11 building, roof and street sets above, again at 2k (2048² jpg:
Diffuse + nor_gl + Rough), same Poly Haven assets, downloaded exact-size
from `https://dl.polyhaven.org/file/ph-assets/Textures/jpg/2k/…` (URLs from
`https://api.polyhaven.com/files/{id}`), CC0 1.0. 33 files, ≈82 MB under
`assets/textures/2k/<set>_{diff,nor,rough}.jpg`. Read only on desktop Ultra
builds (`MaterialLibrary.hi_res`, `PbrTextures.map_path`); everything else
keeps the 1k files. Excluded from the iOS export (`export_presets.cfg`).
Sets: limestone, stone, render, brick, concrete, wood, slate, terracotta,
membrane, asphalt, pavement.

Terrain layers (added the same day): lawn (`leafy_grass`), rock
(`brown_mud_rocks_01`), cliff (`rock_face_03`), forest (`forest_leaves_02`),
gravel (`gravel_floor`), sand (`coast_sand_01`), snow (`snow_02`) at 2k from
the same CDN, CC0 1.0, 21 files ≈75 MB. Every file verified as a 2048×2048
JPEG before bundling. `TerrainTextures` builds desktop Ultra's terrain arrays
from them at 2048 px, block-compressed (BC1 albedo, BC3 normal + roughness).
Only `grass` (the building-ground set, not a terrain layer) stays 1k.

## Foliage, bark and tree-impostor textures — T5.1 (2026-10-28)

Own procedural work, no third-party pixels: **CC0 1.0** (dedicated by
this project). 35 PNGs, ≈15 MB under `assets/textures/foliage/`:
`leaf_{broad,birch,olive,needle,pine,palm,cypress,twigs}.png` (1024²
RGBA atlases), `bark_{plane,furrowed,pine,birch,spruce,palm}[_n].png`
(512×1024 albedo + normal), `imp_<species>[_bare].png` (256×512
impostors rasterised from the species meshes). Regenerate with
`godot --headless --path . --script tools/gen_foliage_textures.gd`.
Fallback: FoliageTextures/TreeImpostor paint the same layouts at
reduced resolution at runtime if a file is missing.

## Street-life models and sign font — realism v3 R-1.5 (spike 2026-11-01, not bundled)

Candidates for R-2.5 street life and R-2.3 signs, checked by downloading
each pack (scratchpad only, nothing committed under `assets/` yet) and
reading its bundled `License.txt` and every GLB's mesh, material and
image tables. Bundle only the models a task uses, each with its
`License.txt`, under `assets/street_life/<pack>/`.

| pack | source | licence | contents (measured) | fit |
|---|---|---|---|---|
| Kenney Car Kit 3.1 | `https://kenney.nl/assets/car-kit` (download through the page's signed link, `kenney.nl/download-link/<id>`) | **CC0 1.0** (`License.txt`: "Creative Commons Zero, CC0"); attribution not required, courtesy credit "Models: Kenney (CC0)" | 50 GLB (+ FBX/OBJ): sedan, taxi, SUV, hatchback, van, truck, police, delivery, ambulance, fire truck, garbage truck, karts, tractors and separate wheels. 2,032–3,124 triangles per vehicle including its four wheel meshes (sedan 2,032, taxi 2,072, SUV 2,474), 1 material each on one shared 512² palette texture (`Textures/colormap.png`, external to the GLB) | Cars: one shared material, so MultiMesh per model × sector × ring batches cleanly. At ~2.2k triangles a car, 150 cars ≈ 330k triangles: needs a low LOD (Godot's import LODs or a box card) beyond ~120 m and stays off on Fast. Toy-like proportions: tint per region, keep them distant and parked. |
| Kenney City Kit Roads 2.2 | `https://kenney.nl/assets/city-kit-roads` (same download route) | **CC0 1.0** (`License.txt`) | 95 GLB: street lights (60–270 triangles), traffic lights (114–230), road signs (42–154), highway gantries (144–256), cones, barriers, a dumpster (234); one material each on a shared 512² palette | Signals, signs and bins from OSM nodes (R-2.5); light poles only where `StreetProps`' procedural lamps don't already stand |
| Quaternius Cars | `https://quaternius.com/packs/cars.html` | **CC0** (pack page) | 8 cars, FBX / OBJ / Blend only | Needs a Blender → GLB pass through `assets_src/blender`; keep as a fallback if Kenney's look reads too toy-like |
| Sign font (Latin) | Already bundled: `assets/fonts/InstrumentSans-Variable.ttf`, `IBMPlexMono-*.ttf` (the design system's families) | SIL OFL 1.1 (both families) | Latin + Latin Extended | Reuse for shop names and fascias; no new font needed. CJK and Hangul signs use the planned script-shaped pseudo-text (no font), so no CJK font ships. The OFL text is not yet next to the font files: add `assets/fonts/OFL.txt` when signs ship. |

## Land-cover tag mapping — T2.4 (2026-10-28)

Contract §2.6 classes as implemented in `OsmFetcher.land_class`. Order is
most-specific first (e.g. `leisure=pitch` on `landuse=meadow` → pitch).

| class | `natural` | `landuse` | `leisure` | other |
|---|---|---|---|---|
| water | water, bay | reservoir, basin | — | any `water=*` tag; `waterway=riverbank` (way or multipolygon) |
| wetland | wetland, mud | — | — | |
| glacier | glacier | — | — | |
| sand | beach, sand, dune | — | — | |
| rock | bare_rock, rock, scree, shingle | — | — | |
| forest | wood | forest | — | |
| orchard | — | orchard, vineyard | — | |
| grass | grassland, scrub, heath | meadow, grass, recreation_ground | park, garden | |
| field | — | farmland, farmyard | — | |
| cemetery | — | cemetery | — | |
| pitch | — | — | pitch | |
| quarry | — | quarry | — | |
| urban | — | residential, commercial, industrial, retail | — | |

Deliberately unmapped (return `""`, dropped — never forced into a wrong
class; seen live unless noted):

| tags | why unmapped |
|---|---|
| `natural=peak/saddle/ridge/arch/cave_entrance/volcano/spring/tree_row` | point/line features, not areas (`arch`, `ridge`, `tree_row` seen at Big Sur) |
| `natural=coastline`, `natural=tree` | mapped elsewhere: coastline → `waterways`, tree nodes → `trees` (T2.3) |
| `landuse=railway/construction/landfill/brownfield/greenfield/military` | no fitting class yet; revisit in T3.5 if shore/ground treatment needs them |
| `leisure=nature_reserve/sports_centre/swimming_pool/track` | reserves are boundary relations (skipped, not areas); the rest are built structures without a class |
| `amenity=grave_yard` | legacy tag on the unqueried `amenity` key; modern tagging is `landuse=cemetery` (mapped) |
| any mapped class present only as a *node* (e.g. node `leisure=pitch`) | nodes carry no polygon; no synthetic radius per the no-faked-fidelity rule |

Multipolygons / holes: one `relation["<key>"]["type"="multipolygon"]`
statement per land/water key (cap 100 each — areas are rarely relations:
8 MPs in a Big Sur coastal response). The `type=multipolygon` filter keeps
boundary/route relations server-side (measured: an unfiltered coastal query
dragged two 300–700-member nature-reserve boundaries, 2.8 MB total, that
parse skips — filtered query is 518 KB with identical land output). Outer
members are stitched end-to-end (open halves join; ≥3-post chains emit even
unjoined since consumers close rings implicitly); inner members become
contract-§2.6 `holes` on their containing outer. Old-style dual tagging
(tags on both outer way and relation) may emit overlapping duplicates —
samplers first-win, harmless.

Live evidence (2026-10-28, identifying UA, `out geom`):

- Coastal Big Sur (36.2377, −121.8156, 800 m): HTTP 200,
  91 land polygons — forest 23, grass 33, rock 25, sand 9, water 1 —
  **0 urban** (no urban-grey beach/rock); 8 multipolygons, 7 holed entries.
  Samples: sand (Pfeiffer Beach) at (36.23938, −121.8176); rock at
  (36.23732, −121.8163), (36.23907, −121.8201), (36.23718, −121.8165).
- Inland Big Sur golden point (36.2704, −121.8081, 800 m): HTTP 200,
  8 land polygons (forest 5, grass, pitch, urban), 2 holed entries.
- Tag census at the coast confirms the mapping end to end: `natural=beach`
  ×9 → sand ×9, `natural=bare_rock` ×25 (incl. 3 MPs) → rock ×25,
  `natural=coastline` ×10 + `waterway=stream` ×4 → waterways 14.

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
- Overpass mirror probe (2026-10-28, Interlaken, 150 m building query):
  `https://overpass.openstreetmap.fr/api/interpreter` → HTTP 200, 20
  buildings, ≈7 s, no key, global data (replication timestamp 2026-08-10,
  fine for buildings). Added as the first fallback in `OsmFetcher.ENDPOINTS`
  because the main instance answered the full 800 m query with HTTP 502
  "at capacity" during the same session (the retry chain is therefore 5
  attempts: main, OSM-FR, maps.mail.ru, private.coffee, and — since
  2026-10-31 — z.overpass-api.de in place of a second main attempt).
  `overpass.kumi.systems`, `z.`/`lz4.overpass-api.de` timed out from the
  probing host and are not wired.
- Overpass outage probe (2026-10-31, Interlaken, 150 m building query, 20 s
  budget): `overpass-api.de`, `maps.mail.ru`, `private.coffee`, `kumi`,
  `lz4.`, `overpass.osm.jp` timed out; `overpass.openstreetmap.fr` HTTP 200
  in 2.3 s; `z.overpass-api.de` HTTP 200 in 17.7 s (now the fifth endpoint,
  replacing the repeated main instance).
- OSM API fallback (same date): `GET https://api.openstreetmap.org/api/0.6/map?bbox=`
  → HTTP 200, 12 MB XML in 17 s for a 1.7 × 1.8 km box (no key; ODbL, same
  attribution). The API caps a request at 50 000 nodes (HTTP 400), so
  `OsmApiFallback.RADII_M` steps 1200 → 800 → 400 m. `OsmApiFallback`
  converts the XML to Overpass `out geom` JSON (0.3 s for 12 MB, float64
  coordinates) so `OsmParser` is unchanged. Live in-engine run (Interlaken,
  Overpass bypassed): 1200 m → 400, stepped to 800 m, 2225 buildings /
  988 roads in 6.7 s, cached under the `r800` key.
- Detailed-phase fallback order in `OsmFetcher`: every Overpass endpoint →
  cached payload at the same place (any radius, ≤150 m) → OSM API bbox →
  cached payload within 500 m (`OsmNearbyCache`) → procedural dressing.

## Verified evidence — data-source gate T0.4 (2026-10-28)

- DEM z14 (T2.1): `curl -sI …/terrarium/14/8299/5636.png` (Paris) → HTTP 200,
  `image/png`, 78,499 bytes, `x-amz-meta-x-imagery-sources: eudem/…`;
  `14/8550/5783` (Interlaken neighbour) → HTTP 200. Downloaded tile decodes
  to 27.2–61.1 m over central Paris, consistent with the wired z12 reading.
  Licence: AWS Open Data `terrain-tiles` page names the joerd attribution
  doc as the licence; per-region credit text copied into the DEM row above.
- Satellite z17/z18 (T2.2): `…/World_Imagery/…/tile/17/45092/66392` → HTTP 200
  `image/jpeg` 21,034 bytes; `…/tile/18/90184/132784` → HTTP 200 19,614 bytes.
  Both downloaded and confirmed real varied imagery (256×256, pixel std ≈55).
  Service metadata (`MapServer?f=json`) exposes LODs 0–23; copyright string
  read live: "Source: Esri, Vantor, Earthstar Geographics, and the GIS User
  Community". Terms: esri.com web-site-service §2.2 (free noncommercial +
  attribution) / §2.2.1 (commercial needs a licence) — recorded in the row.
- OSM expanded tags (T2.3/T2.4): live Overpass query (Paris bbox, 31 building
  ways) returned `height`, `building:levels`, `roof:shape`; taginfo confirms
  global use of `building:colour`, `roof:colour`, `building:material`,
  `roof:material`, `roof:height`, `min_height`, `building:part`. No new
  endpoint — `out geom` already returns all tags. Note: default curl UA gets
  HTTP 406 from `overpass-api.de`; the fetcher's identifying UA is required.
- PBR textures (T4.3): `api.polyhaven.com/assets?t=textures` → HTTP 200, no
  key, 869 textures; `/files/aerial_beach_01` → HTTP 200 with Diffuse,
  nor_gl, Rough, AO, Displacement maps at 1k–8k; 2k diffuse download →
  HTTP 200, real 2048×2048 JPEG. Licence page confirms CC0, no attribution
  required, redistribution allowed. Verdict: build-time bundle, not runtime.
- Rejections: none — every Phase 2/Phase 4 need is servable without a
  proxy, account, or key. The only licence caveat is Esri's
  noncommercial-only free grant (fine for this free app; re-check before any
  paid release).

### Phase 2 fetch-change traceability (T0.4 validation)

| Plan task | Register row | Verdict |
|---|---|---|
| T2.1 DEM mosaic z14+z12+z8 | Elevation (DEM) | same endpoint, z14 probed live |
| T2.2 satellite z17/18/16 | Satellite imagery | same endpoint, z17+z18 probed live |
| T3.7 far-field DEM rings (~25 m/px z12 to 9.5 km, ~100 m/px z10 to 33 km) + far imagery drapes (~12/50/200 m/px, z13/z11/z9 at mid-latitudes, to 9.5/33/60 km) — `FarFieldFetcher` | Elevation (DEM) + Satellite imagery | same endpoints and cache keys (`dem_v2_*`, `sat_v2_*`), zoom picked per latitude by target m/px; ~32 DEM + ≤~100 low-zoom imagery tiles per cold place, cached per tile, bounded pool of 8; same Esri credit string (pipeline adds it when only far drapes landed); incomplete layer → dropped → coarser ring / z8 grid / colour ramp |
| T5.4 far-city ring query (built-up `landuse` ways + multipolygons and `building` with height ≥ 50 m / levels ≥ 15, `around:12000`) — `FarCityFetcher` | Land cover + Buildings | same Overpass endpoints (mirror-first order so it never queues behind the detailed query), one request per place, `[timeout:30]`, identifying UA, cached as `osm_v2_<lat>_<lon>_farcity12000.json` (osm layer); measured live 2026-10-28: Paris 5.1 MB / 22 s (1129 landuse, 730 towers), Interlaken 0.8 MB / 7 s, Big Sur 13 KB / 7 s; failure → empty → imagery-only far city |
| Horizon labels query (named `natural=peak` to 45 km, `place=city|town|village` to 30 km, lake/reservoir `natural=water` to 20 km, `out tags center 1500`) — `HorizonFetcher` | Names for the skyline (peaks, towns, lakes: name, `ele`, position; no geometry) | same Overpass endpoints, mirror-first order, one request per place, `[timeout:30]`, identifying UA, issued only when the person turns horizon labels on, cached as `osm_v2_<lat>_<lon>_horizon45000.json` (osm layer); failure → empty → no labels; credit is the viewer's existing © OpenStreetMap contributors attribution |
| T2.3 OSM footprints + rich tags + wider radius | Buildings + roads | same endpoint, tags confirmed live |
| T2.4 land-cover classes + waterways + relations | Land cover | same endpoint, parse-only change |
| T4.3 PBR sets by class/region (Phase 4, gated here) | PBR textures | Poly Haven CC0, API+CDN probed live |

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

## Street furniture, kerbs and decals — Ultra pass Phase 7 (2026-11-02)

- **OSM street furniture nodes**: `amenity=bench|waste_basket`,
  `highway=traffic_signals|bus_stop` (+ `shelter=yes`), `barrier=bollard`
  within 450 m (`OsmQuery.FURNITURE_RADIUS_M`), the last statement of the
  detailed Overpass query. ODbL, same attribution as the rest of the map
  data. Cached payloads from before the change carry none; StreetFurniture
  then uses its sparse fill.
- **Furniture, kerb and decal geometry/textures**: own procedural work
  (`StreetFurniture`, `KerbBuilder`, `RoadDecals`), no third-party pixels
  or meshes — CC0 1.0 by this project. The plan's CC0 model downloads
  were not needed: true-metre procedural kits keep the regional variants
  (North American mast arms, Japanese horizontal heads, British black
  bins, Dutch red-brown bollards) cheap and import-free.

## Desktop-Ultra z18 inner imagery — Ultra pass Phase 6 (2026-11-02)

Same source as the main drape (Esri World Imagery tiles, see above), one
zoom finer: a 7×7 z18 mosaic round the viewpoint (≈700 m in Paris),
fetched beside the main mosaic on desktop Ultra only and blended over its
fine detail (`GroundMaterial.inner_map`). Same attribution, same tile
cache (`sat_v2_18_*`).

## Riddarholmen Church — Ultra pass Phase 8 (2026-11-02)

`riddarholmen`, 90 m to the tip of the 1841 cast-iron openwork spire:
Wikipedia "Riddarholmen Church" (height and spire history). Footprint and
placement from its OSM outline (way `building=church`, name
Riddarholmskyrkan): 62.7 × 39.9 m, nave axis 7.8° north of east, so the
model is ≈64 × 40 m, yaw −7.8°, and the registry point (59.32468 N,
18.06454 E) puts the model's centre on the outline's. Model `LandmarkStockholm.riddarholmen`, own work.
