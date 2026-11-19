# Turku landmark & bridge batch — 2026-11-19

Models use true metres and merged textured surfaces (`LandmarkMesh` / `LandmarkMaterials`). Footprints, centroids and axis bearings were measured directly from OpenStreetMap map API extracts (`api.openstreetmap.org/api/0.6/map`).

## Landmarks (`LandmarkRegistryFinlandTurku` + core updates)

| Type | OSM Way | Centroid (lat, lon) | `yaw_deg` | Height (m) | Notes |
| --- | --- | --- | --- | --- | --- |
| `turku_cathedral` | 437169589 | 60.452450, 22.278549 | 2.2 | 101.0 | Core landmark realigned to OSM nave centroid & bearing; `clear_m=52.0`. |
| `turku_castle` | 466736288 | 60.435350, 22.228750 | -1.4 | 38.0 | Existing `finland_regions` entry; verified against OSM way 466736288. |
| `mikaelinkirkko` | 34204417 | 60.448717, 22.247918 | -34.4 | 77.0 | Lars Sonck (1905) red-brick Neo-Gothic hall church & 77 m copper spire. |
| `martinkirkko` | 48988447 | 60.440857, 22.254405 | -33.7 | 52.0 | Sora & Wahlroos (1933) pale-ochre functionalist church & 52 m tower. |
| `turku_orthodox_church` | 26491333 | 60.452285, 22.266010 | -34.8 | 27.0 | C.L. Engel (1845) yellow neoclassical rotunda & copper dome on Kauppatori (OSM `height=27`). |
| `turku_art_museum` | 26491362 | 60.454107, 22.261774 | -34.7 | 22.0 | Gustaf Nyström (1904) grey-granite National Romantic museum on Puolalanmäki. |
| `vartiovuori_observatory` | 17037200 | 60.448699, 22.276653 | 0.5 | 18.0 | C.L. Engel (1819) neoclassical observatory with central cylindrical rotunda. |
| `turku_market_hall` | 9166246 | 60.449761, 22.266060 | 54.9 | 13.0 | Gustaf Nyström (1896) 116 m red-brick market hall with skylight monitor (OSM `height=11.5`). |
| `turku_main_library` | 29900658 | 60.450810, 22.272273 | -35.5 | 18.0 | Karl August Wrede (1903) Dutch Renaissance brick-and-plaster Old Library on Aurajoki. |
| `turku_city_theatre` | 9167060 | 60.445939, 22.264207 | -31.2 | 22.0 | Luukkonen & Stenros (1962) white modernist riverside theatre & fly-tower. |
| `kakola_prison` | 315938833 | 60.444429, 22.247103 | -32.0 | 24.0 | Ernst Lohrmann (1853) grey-granite former prison complex on Kakolanmäki. |
| `vanha_suurtori` | 23370371 | 60.450508, 22.275468 | -59.0 | 15.0 | Brinkkala Mansion (1829) pale-yellow Empire facade & Christmas Peace balcony. |
| `suomen_joutsen` | 178299341 | 60.436330, 22.237154 | -33.9 | 44.0 | 1902 white 3-masted full-rigged museum ship moored at Forum Marinum (`base=water`). |
| `fori_ferry` | 57933176 | 60.441137, 22.247901 | -35.5 | 5.5 | 1904 orange-and-white double-ended Aurajoki cable ferry (`base=water`). |

## Aurajoki Bridges (`BridgeSpecsNorthEurope`, `conf: 2`)

- **Tuomiokirkkosilta** (OSM ways 4306348 / 27734777): 3-span concrete girder, 50 m, bearing 143.7°.
- **Kirjastosilta** (OSM way 103351226): single-span white steel pedestrian arch deck, 56 m, width 5 m, bearing 123.2°.
- **Auransilta** (OSM ways 90088650 / 90088646 / 90088671): 1907 single-span stone/steel arch deck, 45 m, width 17.5 m, bearing 144.5°.
- **Teatterisilta** (OSM way 105064411): single-span steel pedestrian girder, 65 m, width 6 m, bearing 150.7°.
- **Myllysilta** (OSM ways 531029806 / 1579901611 / 206891995): 3-span steel box-girder, 94 m, width 20 m, bearing 145.4°.
- **Martinsilta** (OSM way 4306342): 3-span concrete girder, 104 m, width 18 m, bearing 145.2°.
