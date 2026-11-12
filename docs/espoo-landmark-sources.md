# Espoo hero landmark geometry

Reviewed 2026-11-03. Geometry uses true metres and the existing photographic
material library. The buildings represent the completed historic architecture;
current construction scaffolding is not modelled.

| Type | Position / footprint | Distinctive geometry and dimensional confidence |
| --- | --- | --- |
| `otaniemi_chapel` | OSM way [4266572](https://www.openstreetmap.org/way/4266572), centre 60.18939, 24.83731. Long walls run approximately 16.4 degrees east of north. | Brick side walls, timber roof structure, south glass altar, external cross, enclosed approach court, open timber bell frame. Hall footprint approx. 16 by 23 m from OSM; roof and belfry heights are photo estimates (6.2 and 8 m). |
| `aalto_university_main` | OSM relation [4148](https://www.openstreetmap.org/relation/4148) (outer way 4252946, courtyard ways 4252947 and 4252949), retrieved 2026-11-12 and simplified to 0.5 m; pinned at the centre of the auditorium fan, 60.185614, 24.827572, yaw 0, with 22 clearance subsites over the wings. The earlier pin sat on the east block (way 1094327789), about 140 m from the auditorium. | Whole complex from the OSM outline with both closed courtyards open: red brick, black granite course, three storeys of windows, copper fascias, copper roofs with bitumen on the low blocks (aerial imagery), round roof lights, Student Hub lanterns (way 514232691), the observatory dome (way 1574125268) and the glazed south entrance with its copper canopy. Auditorium A is fitted to the OSM step rings (ways 1042625817, 1573287436–8, 26390331): circle residual under 0.4 m, edges at 49° and 145°, step radii 11.8, 15.4, 19.3 and 23.4 m and the 33.9 m rear rim. Docomomo Finland places the open-air seats on the lower steps and clerestory strips on the upper ones under a copper velarium. Heights are estimates: rim 21.1 m, roof steps 9/12/15/18 m (the OSM 3/4/5/7-level tags), seats to 4.75 m, wing eaves 11.8 m (sources give 2–4 storeys; one eave for all wings). Brick flanks slope from 1.2 m at the stage to the eave at 30 m, matching the aerial view. |
| `tapiola_church` | OSM way [10051865](https://www.openstreetmap.org/way/10051865); sanctuary at 60.17774, 24.80959, 15.8 degree panel axes. | Sanctuary cube, low courtyard parish wings, exposed concrete panel joints, high strip windows and separate low entrance/bell portal. Sanctuary footprint approx. 25 m square from OSM. Height 16.7 m is a photo estimate. |
| `tapiola_central_tower` | OSM way [8057475](https://www.openstreetmap.org/way/8057475), 60.17700, 24.80464, model long axis yaw −74.6 degrees. | 13 storeys, enamel panel grid and continuous window bands, recessed rooftop restaurant. City source gives 49 m; footprint approximately 28 by 18 m follows OSM, minor lobby projections simplified. |
| `weegee` | OSM way [129693803](https://www.openstreetmap.org/way/129693803), 60.17861, 24.79417; long axis yaw −131.6 degrees. | Original printing house's eight modules, eight circular ventilation pylons and radial roof stays, glass upper storey. City source specifies 27 by 27 m structural modules, 3 m diameter pylons and a 4 m projection above the roof. Roof level 10 m is an estimate. The later school extension is outside the model. |

Primary architectural sources:

- [Aalto University, Architecture on campus](https://www.aalto.fi/en/campus/architecture-on-aalto-universitys-campus): Undergraduate Centre completed 1964; protected Alvar Aalto building.
- [Alvar Aalto Foundation, Espoo campus](https://visit.alvaraalto.fi/en/destinations/espoo/): separate courtyard wings and stepped auditorium; red brick, black granite, copper.
- [Docomomo Finland, Helsinki University of Technology](https://en.docomomo.fi/projects/helsinki-university-of-technology/): the lower steps of the auditorium "amphitheatre" are open-air seating, the upper steps clerestory strip windows under a copper velarium; three- and four-storey wings; granite, red brick and copper.
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

Otaniemi (2026-11-12). Outlines were read through the OSM API and simplified to 0.7 m,
in `LandmarkFhWestFootprints`, with entries in `LandmarkRegistryWestMetro`.

- `vare`: way [941553968](https://www.openstreetmap.org/way/941553968) (Verstas
  Architects, completed 2018).
  - fi.wikipedia gives the metro-centre street level and three teaching floors.
  - Built by `LandmarkFhVare`, the model covers the whole Väre block of OSM building
    relation [12696772](https://www.openstreetmap.org/relation/12696772): Väre, the School
    of Business (way [941553966](https://www.openstreetmap.org/way/941553966)) and the A Bloc
    mall (way [941553969](https://www.openstreetmap.org/way/941553969)), the last two as extra
    outlines cleared through extra `clear_offsets_m`.
  - Typology from Street View panoramas of the east, north and bus-loop fronts (2019–2026,
    supplied by the user) and the Commons photographs "A-Bloc in February 2025", "A-Bloc on
    a rainy afternoon in May 2024", "A-Bloc and Väre in February 2025" and "Aalto University
    School of Business entrance at Väre", matched to the OSM parts:
    - Parts tagged three levels (Väre L, E, K, J, G, M, R, Q; School of Business T, V, Y;
      A Bloc N and way 815467161): two storeys of red-brown brick with a close rhythm of tall
      slot windows under a two-storey box of silver glass with aluminium mullions.
    - Block-sized parts with no level tag (F, O, P, U) and A Bloc's way 815467162: taller
      all-brick blocks with rows of slots over a glazed or perforated-metal ground storey; the
      A Bloc block has the band of vertical brick louvres seen from the square.
    - The School of Business atrium (X), A Bloc's mall hall (way 522627432) and its link (way
      815467164): dark curtain walls in black frames; the mall hall's face to
      Korkeakouluaukio carries the yellow graphic and metro entrance A (node
      [4050038154](https://www.openstreetmap.org/node/4050038154)) under a black canopy with
      the red station sign and the metro sign pole.
    - A Bloc's block A on the square (way 815467163): brick piers under a band of silver glass.
    - The station's entrance hall (way [402618641](https://www.openstreetmap.org/way/402618641)):
      glass under a deep black canopy with a warm perforated soffit, the red sign over the
      Otaniementie door (node 5026528602), as in "Entrance to Aalto University metro station".
    - The two-storey parts between the blocks (ways 522627431, 941553970, 522627430):
      recessed, dark-framed glass.
    - The one-storey glass part S under a black metal roof, and the black metal skillion
      (way [941553972](https://www.openstreetmap.org/way/941553972)) as the stepped wedge
      climbing onto it.
  - Which untagged parts are tall brick blocks or dark halls, the 9 m brick base, 17.5 m glass
    tops, 20–21.5 m tall blocks, 19 m School of Business atrium, 11.5 m mall hall, 10 m
    connectors, the perforated ground storeys and the yellow graphic's shapes are estimates.
- `aalto_university_metro_station`: the Tietotie entrance pavilion, way
  [408595707](https://www.openstreetmap.org/way/408595707) (`building=transportation`, one
  level; entrance B, node [4104851062](https://www.openstreetmap.org/node/4104851062)), entry at
  its outline centroid. The station itself is underground (Länsimetro, 2017).
  - Granite plinth, full-height glazing in black frames, the black standing-seam back wall and
    steep folded roof and the large glazed diamond across a corner are from the Commons
    photograph "Aalto University metro station entrance by the VTT building in Otaniemi (Jan 2017)".
  - The 4.4 m eaves, 7.5 m crown, the corner chosen for the diamond and its size are estimates.

- `harald_herlin_learning_centre`: way [4252948](https://www.openstreetmap.org/way/4252948)
  (Alvar Aalto's university library, 1970; OSM two levels).
  - The red brick on a black granite course, two long window bands with slim mullions and
    the entrance canopy on blue-green tiled columns are from the Commons photographs
    "Otaniemi campus library" and "Backside of the library of the Helsinki University of
    Technology".
  - The canopy stands on the south front at the OSM main entrance (node
    [301814925](https://www.openstreetmap.org/node/301814925)); its 6.4 m depth and four
    columns are estimates.
  - The 9.5 m eaves and 11.5 m roof lights are estimates.

Aalto's campus beyond the main building (2026-11-12). Wikidata lists three Alvar Aalto
works in Otaniemi: the main building (already `aalto_university_main`), Otahalli and the
water tower. Dipoli is by Reima Pietilä and Raili Paatelainen (OSM `architect`), and the
chapel is by Kaija and Heikki Siren.

- `dipoli`: way [4252954](https://www.openstreetmap.org/way/4252954) and its
  building:parts 1573787789–816 (heights 4–11 m, the lanterns `building:material=copper`),
  in `LandmarkFhDipoli`; Reima Pietilä and Raili Paatelainen, 1966, Aalto University's
  main building since its 2017 renovation.
  - The tall dark weathered-copper fascias of horizontal boards leaning out over the glass,
    the warm timber soffits, the timber-framed glazing with dark-stained panels, the heaps of
    pink-red granite boulders against the walls and the steel pinecone at the Käpyovi
    entrance (OSM node [1433646676](https://www.openstreetmap.org/node/1433646676)) are from
    Commons photographs ("Dipoli building, Aalto University", "Dipoli11", "Dipoli,1",
    "Dipoli September 2025").
  - Glass heights (2.6–5.2 m), fascia heights, the fascia lean and the boulder layout are
    estimates.

- `otaniemi_water_tower`: way [26608571](https://www.openstreetmap.org/way/26608571)
  and its building:parts (Aalto, 1971).
  - Twelve blade columns 0–34 m, the twelve-sided tank 34–57 m and a 1 m roof, so 58 m.
  - A central shaft to 35 m and a seven-storey, 28 m free-form office (part
    [1574135819](https://www.openstreetmap.org/way/1574135819)).
  - fi.wikipedia gives 52 m and en.wikipedia 45 m; the model follows the OSM parts.
  - Board-marked natural concrete is from fi.wikipedia and the Commons photograph.
- `otahalli`: way [4259272](https://www.openstreetmap.org/way/4259272) (Aalto, 1952,
  built for the Helsinki Olympics; OSM four levels).
  - The white hall with its clerestory band over three-storey wings is from the photograph.
  - The hall rectangle inside the outline, the 10.5 m wings and the 16.5 m ridge are
    estimates.
  - The 1971 Aalto annexe (way [131232174](https://www.openstreetmap.org/way/131232174))
    stays generic.
- `otaniemi_power_plant`: way [24408439](https://www.openstreetmap.org/way/24408439)
  (brick).
  - The steel chimney is way [26314304](https://www.openstreetmap.org/way/26314304),
    75 m, `material=metal`. It used to render as a generic 75 m box.
  - The 14 m hall height is an estimate; no source credits the plant to Aalto.
