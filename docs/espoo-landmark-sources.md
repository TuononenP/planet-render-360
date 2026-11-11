# Espoo hero landmark geometry

Reviewed 2026-11-03. Geometry uses true metres and the existing photographic
material library. The buildings represent the completed historic architecture;
current construction scaffolding is not modelled.

| Type | Position / footprint | Distinctive geometry and dimensional confidence |
| --- | --- | --- |
| `otaniemi_chapel` | OSM way [4266572](https://www.openstreetmap.org/way/4266572), centre 60.18939, 24.83731. Long walls run approximately 16.4 degrees east of north. | Brick side walls, timber roof structure, south glass altar, external cross, enclosed approach court, open timber bell frame. Hall footprint approx. 16 by 23 m from OSM; roof and belfry heights are photo estimates (6.2 and 8 m). |
| `aalto_university_main` | OSM building part 1094327789 at 60.18635, 24.82982, auditorium pin 60.18629, 24.82999. | Dark brick campus wings and open courts, copper fan auditorium and curved outdoor stepped theatre. Auditorium fan approximately 27 m across from OSM; campus wings are simplified. Roof height 21.1 m is an estimate, not a surveyed dimension. |
| `tapiola_church` | OSM way [10051865](https://www.openstreetmap.org/way/10051865); sanctuary at 60.17774, 24.80959, 15.8 degree panel axes. | Sanctuary cube, low courtyard parish wings, exposed concrete panel joints, high strip windows and separate low entrance/bell portal. Sanctuary footprint approx. 25 m square from OSM. Height 16.7 m is a photo estimate. |
| `tapiola_central_tower` | OSM way [8057475](https://www.openstreetmap.org/way/8057475), 60.17700, 24.80464, model long axis yaw −74.6 degrees. | 13 storeys, enamel panel grid and continuous window bands, recessed rooftop restaurant. City source gives 49 m; footprint approximately 28 by 18 m follows OSM, minor lobby projections simplified. |
| `weegee` | OSM way [129693803](https://www.openstreetmap.org/way/129693803), 60.17861, 24.79417; long axis yaw −131.6 degrees. | Original printing house's eight modules, eight circular ventilation pylons and radial roof stays, glass upper storey. City source specifies 27 by 27 m structural modules, 3 m diameter pylons and a 4 m projection above the roof. Roof level 10 m is an estimate. The later school extension is outside the model. |

Primary architectural sources:

- [Aalto University, Architecture on campus](https://www.aalto.fi/en/campus/architecture-on-aalto-universitys-campus): Undergraduate Centre completed 1964; protected Alvar Aalto building.
- [Alvar Aalto Foundation, Espoo campus](https://visit.alvaraalto.fi/en/destinations/espoo/): separate courtyard wings and stepped auditorium; red brick, black granite, copper.
- [Aalto University, Otaniemi architecture](https://www.aalto.fi/fi/uutiset/otaniemen-arkkitehtuurin-merkkiteoksia): chapel's timber roof and glazed south altar with outdoor cross.
- [Espoo parishes, Tapiola architecture](https://www.espoonseurakunnat.fi/kirkot-ja-tilat/kirkot/tapiolan-kirkko/arkkitehtuuri): Ruusuvuori's concrete church, completed 1965, expanded 1992.
- [City of Espoo, WeeGee history and architecture](https://www.espoo.fi/en/history-and-architecture-weegee-house): 1964/1967 printing house, modular roof structure and ventilation pylons.
- [City of Espoo, Keskustorni illumination](https://www.sttinfo.fi/tiedote/69844995/espoon-tapiolan-keskustornin-julkisivuun-heijastetaan-suuri-mediataideteos?publisherId=3385): Ervi's 1961 tower, 49 m and 13 floors.
- [Aalto University entrance plan](https://www.aalto.fi/sites/default/files/2022-05/Otakaari_1_Otsv%C3%A4ngen_1.pdf): connected wing/courtyard layout.

OSM geometry was retrieved from `api.openstreetmap.org/api/0.6/map` and
`/way/8057475/full` on the review date (Overpass was unavailable). OSM contributors,
[ODbL](https://www.openstreetmap.org/copyright). Registry heights explicitly marked
as estimates above need visual calibration against the final terrain captures.

Validation: `tests/espoo_hero_landmarks_test.gd` checks registry heights, clearance,
finite vertices, 1k–150k triangles, merged material parts and textured materials.

## Keilaniemi and Tapiola centre (2026-11-12)

Outlines are OSM ways retrieved through Overpass on 2026-11-12, simplified
to 0.5–1 m and stored about each registry point in
`LandmarkFhWestFootprints` (registry: `LandmarkRegistryWestMetro`).
OSM contributors, [ODbL](https://www.openstreetmap.org/copyright).

| Type | Position / footprint | Geometry and confidence |
| --- | --- | --- |
| `finago_tower` | Way [24474639](https://www.openstreetmap.org/way/24474639), 60.174882, 24.830781; slab about 38 × 60 m with projecting ends. | CJN 1976, 83.6 m, 20 storeys (Wikipedia fi/en). White Sipoo limestone piers and blue-tinted glass are documented; pier rhythm (1.6 m) and the solid plant storey are photo estimates. |
| `kone_building` | Way [8057422](https://www.openstreetmap.org/way/8057422), 60.172155, 24.828705; 28 × 36 m four-sided plan. | 2001, OSM `height=72.6 m`, 16 levels (Finnish list of tallest buildings: 73.0 m, 18 floors). Glass colour, mullion and band rhythm are estimates. |
| `keilalampi` | Way [1025465177](https://www.openstreetmap.org/way/1025465177), 60.174005, 24.829972; 89 × 95 m. | CJN 1994 extension ("Valovirta"): three storeys, steel frame, cone-shaped glass roof (Wikipedia fi/en). 13 m eaves and the 13 m-radius, 22.4 m-high cone are estimates. |
| `espoo_cultural_centre` | Way [41728416](https://www.openstreetmap.org/way/41728416), 60.177892, 24.804577; 77 × 128 m. | Sipinen 1989, Tapiolasali (800) and Louhisali (300). Light cladding, 13 m foyer wings and the 21 m hall block are estimates; sources give no facade or height data. |
| `mantytorni` | Way [129693784](https://www.openstreetmap.org/way/129693784), 60.179173, 24.811752. | Ervi 1954, 11 storeys, 31 m, slip-formed concrete, a French balcony per flat (Wikipedia fi). White colour is an estimate. |
| `tapiola_hip_flask_houses` | Ways [129693702](https://www.openstreetmap.org/way/129693702) (entry, 60.175407, 24.795376), 129693693, 129693699, 129693710. | Revell 1959–61, four 9-storey hexagonal blocks about 30 m (Wikipedia fi/en); horizontal Mineriitti cladding, window bands, teak grids and top-storey canopies are documented; OSM `building:colour=white`. |

The 1965 Tapiola swimming hall is not modelled: the old hall was demolished
by August 2025 (Wikipedia fi) although OSM still maps way 8057439. The
Keilaniemi residential towers ("Espoon Skyline", way 1394571373) are still
`construction` and Keilaniemen Portti's OSM outline (way 1394235254) is not a
usable footprint, so neither is modelled.

Validation: `tests/west_metro_coverage_test.gd` checks heights, outline
clearance (every point 6 m inside), spill, neighbour clearance, extras and
the Keilaniemi zone/district.

## Niittykumpu metro centre (2026-11-12)

Outlines are OSM ways retrieved through Overpass on 2026-11-12, stored in
`LandmarkFhWestFootprints` (the mall's in `LandmarkFhMallFootprints`).

| Type | Position / footprint | Geometry and confidence |
| --- | --- | --- |
| `niittyhuippu` | Way [403119916](https://www.openstreetmap.org/way/403119916), 60.170240, 24.764026; 43 × 32 m octagon. | SRV 2017, 24 storeys, residents' roof terrace; Finnish Wikipedia gives 90 m (also its list of tallest buildings), OSM `height=78 m`; the model uses 90 m. OSM gives `building:colour=white` and `roof:shape=butterfly`. It stands over the Niitty mall. Balcony and window bands are estimates. |
| `niittytori_tower` | Way [426363234](https://www.openstreetmap.org/way/426363234), 60.170501, 24.762190. | 12 storeys (Wikipedia fi, OSM), white (OSM). Height 38 m is an estimate. |
| `niitty_shopping_centre` | Way [408574589](https://www.openstreetmap.org/way/408574589), 60.170331, 24.763399; 165 × 119 m. | Metro-centre mall, 3 levels (OSM), opened 2017 over the station. Height 14 m and facade colours are estimates; built by the shared `LandmarkFhMalls` mall block. |
| `niittytaival_tower` | Way [791678773](https://www.openstreetmap.org/way/791678773), 60.170304, 24.772865. | 16 storeys, completed 2020, OSM `building:colour=#2e211b`; glazed balconies on both long faces (listings: "lasitettu parveke"), whose ~1.3 m deep stacks the OSM outline traces as the proud middle runs; 16th-floor sauna and lounge with terraces (listing). Height 50.5 m, bay count, window and balcony detail are estimates. |
| `olari_church` | Way [46707972](https://www.openstreetmap.org/way/46707972), 60.172126, 24.759892. | Käpy and Simo Paavilainen 1981, red brick (Wikipedia fi, OSM); brick pilasters and full-height very narrow windows on the Merituulentie front, plan wrapping a mound round a small courtyard. Heights (9.5 m walls, 13 m hall block) are estimates. |

The 8–10-storey 2015–23 blocks round the station follow the new 0.6 km
`espoo_modern` Niittykumpu district.
