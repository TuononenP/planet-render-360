# Third-party notices

The [MIT License](LICENSE) covers this project's source code and its own
artwork (the logo, the app icon, the preset and capital thumbnails and the
procedural landmark models). The data, fonts, icons, textures and models
below keep the licences their authors gave them. The same list, with links,
is in the app under Settings → About and Settings → Data sources.

## Bundled with the app

| What | Where | Licence |
| --- | --- | --- |
| OpenStreetMap extracts (buildings, roads, shores) for the preset origins and the capital cities | `assets/osm_snapshots/` | © OpenStreetMap contributors, [ODbL 1.0](https://opendatacommons.org/licenses/odbl/1-0/). See below. |
| OpenMapTiles-schema vector tiles from OpenFreeMap, and Terrarium elevation tiles from AWS Terrain Tiles, packed for offline use | `assets/map/` | Vector tiles: © OpenStreetMap contributors (ODbL), © OpenMapTiles, [OpenFreeMap](https://openfreemap.org/). Elevation: [Mapzen/Tilezen attribution](https://github.com/tilezen/joerd/blob/master/docs/attribution.md) (EU-DEM / Copernicus, USGS 3DEP, SRTM and others). |
| Capital city names and coordinates | `scripts/data/capital_catalog.gd` | [GeoNames](https://www.geonames.org/about.html), CC BY 4.0 |
| Photographic PBR textures | `assets/textures/` | [Poly Haven](https://polyhaven.com/license), CC0 |
| Generic passenger car pack, by Comrade1280, modified | `assets/vehicles/` | CC BY 4.0, [source](https://sketchfab.com/3d-models/generic-passenger-car-pack-20f9af9b8a404d5cb022ac6fe87f21f5). Full note in `assets/vehicles/LICENSE.txt`. |
| Instrument Sans | `assets/fonts/` | SIL Open Font License 1.1. Copyright 2022 The Instrument Sans Project Authors. Text: `licenses/instrument-sans-OFL.txt` |
| IBM Plex Mono | `assets/fonts/` | SIL Open Font License 1.1. Copyright © 2017 IBM Corp. with Reserved Font Name "Plex". Text: `licenses/ibm-plex-mono-OFL.txt` |
| Lucide icons | `assets/icons/` | ISC License, with the Feather-derived icons under MIT. Text: `licenses/lucide-LICENSE.txt` |
| Godot Engine | the engine the app is built with | MIT License. The text is shown in Settings → About. Third-party components of the engine are listed in Godot's own copyright notices. |

The fonts and icon licences are also shipped inside the app and shown under
Settings → About → Fonts and icons.

### The OpenStreetMap extracts

`assets/osm_snapshots/` holds extracts of OpenStreetMap data. They are a
database taken from OpenStreetMap, and this repository publishes them under
the same Open Database Licence (ODbL 1.0) that applies to the source data:
you may copy, adapt and use them if you credit "© OpenStreetMap
contributors" and keep any adapted version under the ODbL. The README in
that folder gives each file's query and timestamp.

The 3D scenes the app draws from this data are produced works. They need
only the credit, which the app shows on the map and under Settings → Data
sources. The MIT License for the code does not relicense these files.

## Fetched while the app runs, not bundled

These are requested from their publishers on your device and are not
redistributed with the app. Their terms apply to that use.

| What | Source and licence |
| --- | --- |
| Satellite imagery | Esri World Imagery (Esri, Vantor, Earthstar Geographics), under the [Esri web site and services terms](https://www.esri.com/en-us/legal/terms/web-site-service) |
| Map tiles | OpenStreetMap tile service, under the [tile usage policy](https://operations.osmfoundation.org/policies/tiles/) |
| Buildings, roads, shores and place search | OpenStreetMap through Overpass servers and [Nominatim](https://operations.osmfoundation.org/policies/nominatim/), ODbL |
| Land cover | © ESA WorldCover project 2021, contains modified Copernicus Sentinel data, CC BY 4.0 |
| Tree canopy height | © Meta and World Resources Institute, source imagery © 2016 Vantor, CC BY 4.0 |
| Climate | CHELSA V2.1 (Karger et al.), CC BY 4.0; fallback ERA5 (Copernicus) through Open-Meteo, CC BY 4.0 |
| Weather | [Open-Meteo](https://open-meteo.com/en/license), CC BY 4.0 |
| Landmark details and photos | Wikipedia (CC BY-SA 4.0) and Wikimedia Commons (each photo credited by its licence) |

## Not affiliated

The landmarks, city names and place names in the app describe real places.
The models are the project's own drawings of them. The project is not
affiliated with or endorsed by the owners or operators of those places, or
by any of the services named above.
