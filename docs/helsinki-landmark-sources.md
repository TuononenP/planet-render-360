# Helsinki landmark batch — 2026-11-03

Models use true metres and merged textured surfaces. They approximate the buildings' exterior envelopes and visible details; no model has been photographically rated. Non-survey dimensions below must not be presented as verified real-world dimensions.

| Type | Model envelope / details | Evidence |
| --- | --- | --- |
| `kamppi_chapel` | 12.1 m tilted spruce vessel (sweeping 10.2 m rear to 12.1 m prow), oiled horizontal plank seams, grey concrete lobby wing with glazed doorway, 4 `FLOOD_META` spots | Owner: https://kampinkappeli.fi/en/index/architectureanddesign.html ; OSM tag `height=12.13`. |
| `lasipalatsi` | OSM way [8035238](https://www.openstreetmap.org/way/8035238) (3 levels, flat roof, 1936), outline simplified to 0.5 m about 60.170231, 24.936695, yaw 0, plus 24.0 m functionalist clock/chimney tower and `BIO REX` neon rooftop/marquee sign (`FLOOD_META` 4 spots). | Pale rendered functionalist block with glazed shopfront mullions, ribbon windows, illuminated vertical clock face and neon lettering (`height_m: 24.0`). |
| `amos_rex` | 6.35 m five asymmetric tilted concrete light-scoop cones with inclined steel-and-glass oculi, warm `Lamp` gallery glow, paver plaza, 5 `FLOOD_META` spots | Architect: https://jkmm.fi/work/amos-rex-museum/ . Registry point centres the Lasipalatsi courtyard domes. |
| `havis_amanda` | 5.0 m total, pink granite basin, sculpted multi-ring bronze mermaid, four spouting sea lions with parabolic jets, 4 `FLOOD_META` spots | City: https://tpr.hel.fi/TPRalusta/notification/info/3229/ . |
| `kappeli` | 10.0 m glazed cast-iron verandas and polygonal pavilions, warm `Lamp` interiors, Esplanade terrace and Espa Stage (*Espan lava*) pavilion on west axis (`clear_m: 34.0`), 4 `FLOOD_META` spots | City: https://tpr.hel.fi/TPRalusta/notification/info/605/ ; conservation engineer: https://www.wsp.com/fi-fi/news/2022/ravintola-kappeli-peruskorjataan-historiaa-vaalien . |
| `skywheel_helsinki` | 40 m tall upright wheel (`skyline_priority: 1`), twin rims/spokes, thirty blue-and-white gondolas plus wood-panelled sauna cabin and A-frame | Owner: https://skywheel.fi/en/home/ ; city: https://www.hel.fi/static/public/hela/Kaupunkiymparistolautakunta/Suomi/Paatos/2017/Kymp_2017-09-26_Kylk_8_Pk/1F1E3B1D-6999-C416-8934-5EE5BE000001/Katajanokanlaituri_2n_poikkeamishakemus_%28Skywheel%29.html . |
| `allas_sea_pool` | Raised timber boardwalks around three open pools, sauna building, rooftop terrace/stairs | Owner: https://allasseapool.fi/en/ . Pool/deck dimensions and centre approximate. |
| `stockmann_helsinki` | Stone department-store mass, repetitive framed windows, copper crown and entrance clock | Owner: https://www.stockmann.com/ . Envelope and height approximate; visual review pending. |
| `hakaniemi_market_hall` | Red brick, granite base, arched lower windows, paired gables, long grey roof | Owner: https://hakaniemenkauppahalli.fi/en/contact-information/ . City service API https://www.hel.fi/palvelukarttaws/rest/v4/unit/32359 gives 60.180073,24.951208. Envelope and roof heights approximate. |
| `government_palace_helsinki` | Courtyard wings, yellow render, Corinthian colonnade, pediment and dome | City: https://historia.hel.fi/en/alueet/southern/the-senate-square ; owner: https://www.senaatti.fi/ajankohtaista/uutiset/valtioneuvoston-linnassa-alkaa-mittava-peruskorjaus-syksylla/ . Envelope and height approximate. |
| `helsinki_university_main` | Courtyard wings, pale render, Ionic colonnade and pediment | Owner: https://www.helsinki.fi/en/about-us/university-helsinki/history ; architect drawing: https://blogs.helsinki.fi/hum-object-of-the-month/2022/04/21/c-l-engels-drawing-of-the-university-of-helsinki-main-building/ ; city service API https://www.hel.fi/palvelukarttaws/rest/v4/unit/75353 places entrance at 60.169487,24.950119. Registry centre is offset west into old main block. Envelope and height approximate. |

Overpass endpoints returned HTTP 406 or timed out during this run. No survey accuracy is asserted for the approximate envelopes/facings. Registry `clear_m` is tested against the complete generated footprint to prevent duplicated generic buildings within the bespoke model.

Headless verification logs: `/tmp/planet-helsinki-hero/helsinki-import.log`, `/tmp/planet-helsinki-hero/helsinki-test-direct.log`.

Harbour coordinate corrections after capture review (2026-11-03): direct
[OSM map API](https://api.openstreetmap.org/api/0.6/map?bbox=24.9555,60.1658,24.9605,60.1682)
places SkyWheel way 457949936 at 60.16670,24.95945. Pool ways 443717278–280
centre the Allas pool strip around 60.16696,24.95722; its long axis runs north–south.
The registry uses that pool-strip centre, a water base and a 76 m clear radius
covering the adjacent sauna/venue complex. The cached
mapped Kamppi chapel footprint centres near 60.16945,24.93592 (the owner’s published
11.5 m model height is retained; OSM's 12.13 m tag differs).


Kalasatama, malls and Suomenlinna composite (2026-11-11): OSM map API
footprints give Majakka (way 1076677105, height 134 m, 35 levels) at
60.187531,24.979657, Loisto (way 1075173606, 124 m) at 60.187331,24.980888,
Lumo One (120 m) at 60.187716,24.978914, Visio (way 1020243045, 98 m) at
60.186869,24.977701 and Horisontti (way 1164189703, 109 m) at
60.187586,24.978137; Redi podium (way 1449865954) centres 60.186915,24.979314.
Mall centres from OSM: Mall of Tripla 60.198376,24.930295 (relation 19097175),
Itis 60.212044,25.082692 (way 6188896), Iso Omena 60.161240,24.738512
(way 8034765), Sello 60.217948,24.812562 (way 36813140), Jumbo
60.291594,24.965678 (way 5052826). Mall model heights are roof heights of
the mall block, not surveyed totals. The mall models and the Redi podium
are extruded from these OSM outlines (Redi from its landuse=retail lot,
way 1449865954), Douglas-Peucker simplified to 2.5 m and stored about the
registry point in LandmarkFhMallFootprints; their outlines measure about
Tripla 337 × 154 m, Itis 541 × 138 m, Iso Omena 359 × 158 m, Sello
162 × 158 m, Jumbo 334 × 261 m and Redi 189 × 185 m. Clearance is a set of
40 m subsites inside each outline that reaches every point 6 m inside it
and stays within about 24 m of the outline. Suomenlinna components are separate
models: King's Gate at the mapped gate point 60.139581,24.989941 (see
SuomenlinnaSite), dry dock at 60.144900,24.984800 and Jetty Barracks
(Rantakasarmi, way 117426266) at 60.148833,24.985140; bastion fabric
between them remains with the mapped-OSM SuomenlinnaFortress system.
Kappeli gained its Esplanade terrace (steps, lamps, kerb) and Allas its
pool lane ropes and boardwalk benches from owner photographs; both stay
within their registered heights and clearances.

SkyWheel overlap follow-up (2026-11-03): way 457949936's four unique
footprint corners centre at 60.1667282,24.9594489, with its long axis
approximately north–south (`yaw_deg=-90.4`). The wheel now follows that
centre and axis. Allas way 443717281 is part of the venue's eastern end;
its centroid lies outside the previous 76 m replacement radius, leaving
an oversized generic block beside the wheel. The radius is now 105 m.
`tests/fixtures/helsinki_skywheel.json` retains the mapped wheel and nearby
building geometry (© OpenStreetMap contributors, ODbL); the Helsinki test
checks placement, orientation, removal of that duplicate venue, generic
wheel suppression and clearance from retained neighbouring buildings.

Lauttasaari (2026-11-12): `lauttasaari_church` follows the church complex
outline, way [8597256](https://www.openstreetmap.org/way/8597256) (entry
60.158735,24.869437, simplified to 1 m), with the bell tower at way
[404164145](https://www.openstreetmap.org/way/404164145) (OSM `height=61`,
1957; Swedish Wikipedia: about 61 m, crowned by a cross) 7.8 m east and
4.8 m north of the entry in the churchyard. Marja and Keijo Petäjä, 1958,
cast-in-place concrete (Finnish Wikipedia); hall height (8.5 m), strip
glazing and the tower's sound openings are estimates. `lauttasaari_manor`
follows way [29993853](https://www.openstreetmap.org/way/29993853) (60.159028,
24.879080; 1837 Empire main building, two storeys, OSM `roof:shape=hipped`);
the pale ochre render and grey roof are estimates. The demolished (2015)
water tower is not modelled. Outlines live in `LandmarkFhWestFootprints`,
entries in `LandmarkRegistryWestMetro`.


Inner-Helsinki districts (2026-11-12). Outlines were read through the OSM API
(api.openstreetmap.org map extracts; the Overpass instances were not answering) and
simplified to 0.4–1 m. They live in `LandmarkFhInnerFootprints` (Katajanokka, Kallio,
Jätkäsaari, Ruoholahti) or `LandmarkFhWestFootprints` (Munkkiniemi, Kuusisaari), with
entries in `LandmarkRegistryInnerHelsinki` and `LandmarkRegistryWestMetro`. Facade
colours and the massing below come from the Wikimedia Commons lead photographs of each
building's Wikipedia article. Heights marked "estimate" have no OSM or Wikipedia source.

- Katajanokka:
  - `enso_gutzeit_hq`: way [23192809](https://www.openstreetmap.org/way/23192809)
    (Alvar Aalto, 1961–62, six storeys, white Carrara marble, flat roof).
    - The fi.wikipedia article describes the square windows, the blank south-east face
      left for an extension, the recess toward Uspenski and the granite plinth.
    - The 24 m height and the set-back glazed top floor under a thin roof slab are
      estimated from the photograph.
    - This model replaces the generic block the 2026-11-03 rounds saw in front of Uspenski.
  - `merikasarmi`: way [23446530](https://www.openstreetmap.org/way/23446530), the
    Foreign Ministry's main wing of Engel's barracks (1816–38).
    - The ochre render, white column porticos, grey hipped roofs and chimneys are from
      the photograph.
    - The three storeys, 12.6 m eaves and 18 m chimney tops are estimates.
    - The 1838 wing and the 1980s extension stay generic.
  - `katajanokka_terminal`: way [23192841](https://www.openstreetmap.org/way/23192841).
    - The dark brick upper storeys over a pillared glazed ground floor are from the
      photograph.
    - OSM says two levels; the photograph shows three, and the 14 m height is an estimate.
  - Katajanokka Casino and Hotel Katajanokka (the former prison) stay generic.
- Kallio:
  - `kallio_library`: way [20010806](https://www.openstreetmap.org/way/20010806)
    (Karl Hård af Segerstad, 1912; OSM three levels).
    - The red brick, light stone quoins, red tiled mansard and chimneys are from the
      photograph.
    - The 19 m height is an estimate.
  - `kallio_virastotalo`: way [140493078](https://www.openstreetmap.org/way/140493078)
    (Kaija and Heikki Siren, 1965).
    - The fi.wikipedia article gives the 11-storey north–south tower among lower
      east–west wings; it is the outline's 20.6 × 78 m north–south arm.
    - OSM gives `building:colour=whitesmoke` and tiles.
    - The 40 m tower and 14.4 m wings are estimates.
  - `linnanmaki`: the Vuoristorata's mapped centreline, way
    [12118154](https://www.openstreetmap.org/way/12118154).
    - The coaster dates from 1951; en.wikipedia gives 24 m and 960 m of track. The
      height profile along the line is an estimate.
    - It also includes three towers with OSM heights:
      - Kingi: way [988146105](https://www.openstreetmap.org/way/988146105), 75 m.
      - Raketti: way [988146107](https://www.openstreetmap.org/way/988146107), 60 m.
      - Panoraama: way [988146106](https://www.openstreetmap.org/way/988146106), 53 m.
    - Clearance follows the coaster line and the three towers. The 1876 Vesilinna
      water tower, about 30 m from the line, stays.
- Jätkäsaari and Ruoholahti:
  - `clarion_hotel`: way [441505566](https://www.openstreetmap.org/way/441505566), with
    tower parts [458878736](https://www.openstreetmap.org/way/458878736) and
    [458878737](https://www.openstreetmap.org/way/458878737) (2016, 16 floors, 78 m).
    - The photograph shows the chequered grey towers, the glass atrium, the V-shaped
      pilotis and the sky bar.
    - The second tower's 66 m roof is estimated from the same photograph.
  - `west_terminal_2`: way [457955056](https://www.openstreetmap.org/way/457955056)
    (2017).
    - The glass hall under a white roof is simplified, and the 18 m height is an estimate.
  - `cable_factory`: way [14829369](https://www.openstreetmap.org/way/14829369)
    (Kaapelitehdas; OSM five levels).
    - The pale grey brick, red-brick top band of small windows and grey roof boxes are
      from the photograph.
    - The 22.4 m eaves and 28 m roof boxes are estimates.
  - `salmisaari_power_plant`, entered at the Salmisaari A boiler house, way
    [14829857](https://www.openstreetmap.org/way/14829857) (1953):
    - The boiler house has an 11-level part ([445475459](https://www.openstreetmap.org/way/445475459),
      modelled 42 m) and a 9-level part ([445475464](https://www.openstreetmap.org/way/445475464), 34 m).
    - The brick chimney is way [349596089](https://www.openstreetmap.org/way/349596089),
      114 m, `building:colour=#907777`.
    - The 150 m chimney is way [349596091](https://www.openstreetmap.org/way/349596091).
    - The two Lämpöakku heat-storage tanks are ways [349596073](https://www.openstreetmap.org/way/349596073)
      and [349596077](https://www.openstreetmap.org/way/349596077), 32 m (estimate).
    - Before, the chimneys rendered as generic 114 m and 150 m buildings.
  - Bunkkeri (way [89606822](https://www.openstreetmap.org/way/89606822)) is tagged
    `demolished:building`, `end_date=2025-09`, and is not modelled.
- Munkkiniemi and Kuusisaari:
  - `aalto_house`: way [27634542](https://www.openstreetmap.org/way/27634542)
    (Riihitie 20, 1936; OSM `ref:whc=1752-007`).
    - The whitewashed brick under a dark timber-clad upper volume is from the photograph.
    - The 8 m height is an estimate.
  - `studio_aalto`: way [27705480](https://www.openstreetmap.org/way/27705480)
    (Tiilimäki 20, 1955).
    - The white brick and the clerestory over the long outer wing are from the photograph.
    - The 7.4 m height is an estimate.
  - `didrichsen_art_museum`: way [31984997](https://www.openstreetmap.org/way/31984997)
    (Viljo Revell).
    - The glass between red-brick piers, pale fascia and stone terrace wall are from the
      photograph.
    - The 8.4 m height is an estimate.
  - `villa_gyllenberg`: way [97299146](https://www.openstreetmap.org/way/97299146).
    - The ochre render and red tiled hipped roof are from the photograph.
    - The 10 m height is an estimate. The modern gallery wing is folded into the outline.
  - Hotel Kalastajatorppa is not modelled: the mapped conference building (way
    [25824306](https://www.openstreetmap.org/way/25824306)) could not be matched to the
    photographed hotel wing.
  - Munkkiniemi Manor has no named OSM building.
  - Lehtisaari and Sompasaari are district fabric only. Sompasaari's skyline element, the
    Kruunuvuorensilta, is its own bridge model.


## Measured heights (H-0, 2026-11-19)

Registry `height_m` before the H-1/H-2 rebuilds against the City of Helsinki LoD2
3D city model (CC BY 4.0, ground to top), read by `tools/helsinki_measured_heights.gd`:
the LoD2 buildings whose centroid lies within the row's `clear_m` (at most 60 m).
"Nearest" is the row nearest the registry point; a large offset or a towered
landmark means the match must be checked by hand. Rebuilt models take the
measured value or a published figure; the per-landmark rows above record which.

| Type | Model m | LoD2 nearest m (offset m) | LoD2 tallest m | Diff m | Note |
| --- | --- | --- | --- | --- | --- |
| `helsinki_cathedral` | 62.0 | 58.9 (1) | 58.9 | +3.1 | LoD2 surface omits the cross; published 62 m to the cross |
| `uspenski_cathedral` | 50.0 | 48.2 (5) | 48.2 | +1.8 | agrees |
| `temppeliaukio_church` | 8.0 | 9.6 (5) | 9.6 | -1.6 | agrees |
| `st_johns_church_helsinki` | 74.0 | 75.2 (6) | 75.2 | -1.2 | agrees |
| `kallio_church` | 65.0 | 67.8 (7) | 67.8 | -2.8 | differs: re-measure |
| `national_museum_of_finland` | 58.0 | 64.7 (7) | 64.7 | -6.7 | differs: re-measure |
| `parliament_house_helsinki` | 35.0 | 36.8 (5) | 36.8 | -1.8 | agrees |
| `presidential_palace_helsinki` | 20.0 | 20.6 (14) | 20.6 | -0.6 | agrees |
| `ateneum` | 23.0 | 28.6 (1) | 28.6 | -5.6 | differs: re-measure |
| `finlandia_hall` | 24.0 | 33.9 (13) | 33.9 | -9.9 | differs: re-measure |
| `finnish_national_opera` | 32.0 | 34.0 (4) | 34.0 | -2.0 | agrees |
| `helsinki_music_centre` | 22.0 | 21.1 (7) | 21.1 | +0.9 | agrees |
| `kiasma` | 26.0 | 26.0 (5) | 26.0 | +0.0 | agrees |
| `oodi_library` | 20.0 | 23.6 (24) | 23.6 | -3.6 | differs: re-measure |
| `helsinki_central_station` | 48.5 | 2.9 (37) | 3.0 | +45.5 | rows within reach are canopies; tower published 48.5 m (no LoD2 match) |
| `lasipalatsi` | 12.8 | 12.5 (11) | 12.5 | +0.3 | agrees |
| `hotel_torni` | 69.5 | 58.2 (1) | 58.2 | +11.3 | published 69.5 m; LoD2 58.2 m roof: verify the tower top |
| `old_market_hall_helsinki` | 19.0 | 12.6 (1) | 30.8 | -11.8 | nearest row 12.6 m is the hall; model too tall |
| `national_library_of_finland` | 28.0 | 27.9 (5) | 27.9 | +0.1 | agrees |
| `sibelius_monument` | 8.5 | — | — | — | no LoD2 building within reach (monument, ride or out of bundle) |
| `suomenlinna_fortress` | 42.0 | 40.6 (1) | 40.6 | +1.4 | agrees |
| `helsinki_olympic_stadium` | 72.7 | 73.4 (6) | 73.4 | -0.7 | agrees |
| `majakka` | 134.0 | 129.1 (7) | 129.1 | +4.9 | differs: re-measure |
| `loisto` | 124.0 | 121.9 (8) | 121.9 | +2.1 | agrees |
| `lumo_one` | 120.0 | 117.3 (6) | 117.3 | +2.7 | agrees |
| `horisontti` | 109.0 | 108.2 (4) | 108.2 | +0.8 | agrees |
| `visio` | 98.0 | 93.9 (8) | 93.9 | +4.1 | differs: re-measure |
| `redi_shopping_centre` | 20.0 | 29.9 (16) | 29.9 | -9.9 | differs: re-measure |
| `mall_of_tripla` | 30.0 | 57.0 (22) | 57.0 | -27.0 | 57 m row is the Tripla tower block, mall roof lower |
| `suomenlinna_kings_gate` | 12.0 | — | — | — | no LoD2 building within reach (monument, ride or out of bundle) |
| `suomenlinna_dry_dock` | 8.0 | — | — | — | no LoD2 building within reach (monument, ride or out of bundle) |
| `suomenlinna_jetty_barracks` | 14.0 | 10.4 (3) | 10.4 | +3.6 | differs: re-measure |
| `kamppi_chapel` | 11.5 | 11.9 (1) | 11.9 | -0.4 | agrees |
| `amos_rex` | 6.3 | 11.4 (28) | 11.4 | -5.1 | nearest row is Lasipalatsi (28 m); domes 6.3 m |
| `havis_amanda` | 5.0 | — | — | — | no LoD2 building within reach (monument, ride or out of bundle) |
| `kappeli` | 10.8 | 3.0 (16) | 3.0 | +7.8 | nearest row is a kiosk; pavilion not matched |
| `skywheel_helsinki` | 40.0 | 3.6 (11) | 4.5 | +35.5 | wheel is not a building; published 40 m |
| `allas_sea_pool` | 7.0 | 8.6 (15) | 9.6 | -2.6 | differs: re-measure |
| `stockmann_helsinki` | 35.0 | 56.0 (11) | 56.0 | -21.0 | 56 m row may be the corner tower block: verify |
| `hakaniemi_market_hall` | 17.0 | 14.5 (10) | 14.5 | +2.5 | differs: re-measure |
| `government_palace_helsinki` | 26.0 | 26.1 (40) | 26.1 | -0.1 | nearest row 40 m away (courtyard block) |
| `helsinki_university_main` | 22.0 | 29.9 (28) | 29.9 | -7.9 | nearest row 28 m away: verify the building |
| `lauttasaari_church` | 61.0 | 42.5 (9) | 42.5 | +18.5 | free-standing bell tower not in LoD2: verify 61 m |
| `lauttasaari_manor` | 12.5 | 13.5 (4) | 13.5 | -1.0 | agrees |
| `aalto_house` | 8.0 | 7.7 (2) | 7.7 | +0.3 | agrees |
| `studio_aalto` | 7.4 | 9.6 (2) | 9.6 | -2.2 | differs: re-measure |
| `didrichsen_art_museum` | 8.4 | 8.3 (3) | 8.3 | +0.1 | agrees |
| `villa_gyllenberg` | 10.0 | 9.9 (5) | 9.9 | +0.1 | agrees |
| `enso_gutzeit_hq` | 24.0 | 25.1 (1) | 25.1 | -1.1 | agrees |
| `merikasarmi` | 18.0 | 20.2 (2) | 20.2 | -2.2 | differs: re-measure |
| `katajanokka_terminal` | 14.0 | 18.0 (6) | 18.0 | -4.0 | differs: re-measure |
| `kallio_library` | 19.0 | 18.7 (0) | 18.7 | +0.3 | agrees |
| `kallio_virastotalo` | 40.0 | 38.1 (13) | 38.1 | +1.9 | agrees |
| `linnanmaki` | 75.0 | — | — | — | no LoD2 building within reach (monument, ride or out of bundle) |
| `clarion_hotel` | 78.0 | 72.2 (5) | 72.2 | +5.8 | differs: re-measure |
| `west_terminal_2` | 18.0 | 23.4 (10) | 23.4 | -5.4 | differs: re-measure |
| `cable_factory` | 28.0 | — | — | — | no LoD2 building within reach (monument, ride or out of bundle) |
| `salmisaari_power_plant` | 150.0 | 45.2 (3) | 45.2 | +104.8 | 150 m is the chimney; plant hall 45 m |


## H-1 massing models (2026-11-20)

First multi-part models for rows that were one-box placeholders. Footprints, colours and bay
counts are from memory, not yet measured against photographs or LoD2; each model's class header
says so. Registry `height_m` equals the model's top.

| Type | Model m | Built | To check |
| --- | --- | --- | --- |
| `sederholm_house` | 11.0 | 2-storey render block, hip tile roof, chimney | footprint, roof form, render colour |
| `bock_house` | 16.0 | 4 storeys, rusticated ground floor, columned balcony | architect, facade, balcony position |
| `helsinki_city_hall` | 20.0 | 3 storeys, six-column portico, pediment | colour, bay count, portico width |
| `market_square_helsinki` | 9.0 | obelisk with gilt eagle, 27 stall tents, quay edge | stall layout, quay line |
| `katajanokka_casino` | 12.0 | white 2-storey pavilion, hip roof, lantern, veranda | massing, roof |
| `hotel_katajanokka` | 15.0 | cross plan, slate roofs, perimeter wall | arm lengths, wall outline |
| `olympia_terminal` | 14.0 | yellow functionalist block, glazed band, lettering band | length, lettering |
| `makasiiniterminaali` | 12.0 | hall with arched bays and clerestory | the real building form |
| `helsinki_observatory` | 16.0 | block with three domed drums | dome sizes, whether it has three |
| `german_church_helsinki` | 52.0 | brick nave, apse, west tower with copper spire | spire height, nave size |


## H-2 to H-4 massing models (2026-11-20)

All from memory on `landmark_fh_massing.gd`; each class header says so. Registry `height_m` equals
the model's top. Everything below is "to check" against photographs, OSM outlines and LoD2.

- **H-2:** National Theatre (round corner towers, granite, red hip roof, Kivi statue), Sokos (ribbon
  windows, roof sign), Postitalo (brick, higher end block), Sanomatalo (glass block on a frame),
  Kamppi Centre (glass podium, stone office slab), Tennispalatsi (four barrel vaults with round end
  windows), Forum, Swedish Theatre (pediment, low dome), Hotel Kämp, Rautatalo (dark bronze panels:
  the cladding is the least certain), Erottaja fire station (watchtower), Old Church (timber cross
  plan, spire), St Henry's (brick, spire), Mikael Agricola (97 m needle tower), Bank of Finland,
  House of Estates (portico, gilt relief), House of Nobility.
- **H-3:** Swimming Stadium, Bolt Arena, Ice Hall (barrel roof), Winter Garden, Kulttuuritalo (curved
  brick auditorium, copper wing), Ympyrätalo, Hanasaari, Pasila TV mast (146 m, banded), Korkeasaari
  timber tower, Löyly (faceted timber, terrace), Hietalahti hall, Sinebrychoff, Design Museum (clock
  tower), Ursa observatory (dome), Kalastajatorppa.
- **H-4:** Suomenlinna church (lighthouse lantern), Vesikko (sliced hull, conning tower), Lonna,
  Harmaja (tower, keeper's house), Valkosaari (NJK clubhouse), Klippan, Uunisaari, Kustaanmiekka
  (bastion polygon, battery).
- Known guesses: Hanasaari's present state (it may be demolished), Ympyrätalo's plan (modelled as a
  full ring), Kulttuuritalo's wing height, Rautatalo's finish, Observatory and Ursa dome sizes.

## Photo-checked pass, group D: centre (2026-11-20)

Sixteen types rebuilt against Commons photos (refs in `visual-plan/refs/landmarks/<type>/`, each with a
README) and measured outlines or heights. Model sheets in `visual-plan/captures/hel-r1-D/`, read by eye
(no side-by-side sheets: `tools/landmark_compare_sheets.py` needs PIL). No in-world capture from an
open-space eye was taken. Shared helper: `landmark_fh_d_kit.gd` (outline, brick bay, floodlight, sign).

| Type | Measured | Status |
|---|---|---|
| stockmann_helsinki | outline OSM 122595241, 39 m OSM, yaw 177 | improved |
| hotel_torni | 70 m OSM, roof 58.2 m LoD2 | improved (piers removed, canopy, floodlight) |
| temppeliaukio_church | outline OSM 124143121, 9 m (LoD2 9.6) | improved |
| st_johns_church_helsinki | matches photos | done (agent rating) |
| kamppi_centre | re-sited and yaw from OSM, 32 m LoD2 | improved |
| old_church_helsinki | re-sited 135 m, 24 m (LoD2 23.4); earlier yellow colour was wrong | improved |
| tennispalatsi | re-sited 70 m, 34 m OSM | improved; vault count and length approximate |
| forum_helsinki | outline, 38 m LoD2; earlier brick was wrong (black glass) | improved; corner cube a guess |
| swedish_theatre, hotel_kamp, rautatalo, house_of_estates | re-sited, yaw 87/-3 | improved; heights estimated; Rautatalo is verdigris copper, not bronze |
| erottaja_fire_station | re-sited, 27 m (LoD2 26.3) | improved; tower position approximate |
| bank_of_finland | re-sited | still crude (flat roof slab, pavilions barely project) |
| house_of_nobility_helsinki | re-sited | done (agent rating) |
| sinebrychoff_art_museum | re-sited 130 m (OSM 495923233) | improved; heights estimated |

Open: the `clear_m` values were not checked in-world for eating neighbours; 12 of 52 downloaded refs
were not viewed; Tennispalatsi and Sinebrychoff outlines came from live Overpass
(`overpass.openstreetmap.fr`) because the repo snapshots hold nothing. `ympyratalo` fails the
catalogue height check (32.5 expected, 34.6 built) and is not in this group.

## Photo-checked pass, group C: Rautatientori and Kaisaniemi (2026-11-20)

Fourteen types rebuilt against Commons refs (`visual-plan/refs/landmarks/<type>/`). Sheets in
`visual-plan/captures/hel-r1-C/compare_C/` (own side-by-side render; the shared tool needs PIL).
Tests were run in a scratch clone because other agents' parse errors blocked the shared registry.
Not verified: in-world capture, `clear_m`, whether the floodlight spots visibly light anything.

| Type | Measured | Status |
|---|---|---|
| helsinki_central_station | 48.5 m tower (published), LoD2 50.4 whole complex; slab 22.4 m estimated | improved; tower proportions not re-checked |
| ateneum | 28.6 m LoD2 (flagpole), eave 17.2 m estimated, yaw 178 | improved |
| finnish_national_theatre | OSM way 122595207, 60.172465/24.943834, yaw -3.1, 38 m LoD2 | rebuilt; stage house estimated |
| sokos_helsinki | OSM way 122595238, 60.170462/24.938511, yaw -7.2, 44.6 m | rebuilt; storey height scaled from photo |
| postitalo_helsinki | OSM way 122595218, 60.171565/24.938168, yaw -7.6, 43.8 m | rebuilt; tall wing depth estimated |
| sanomatalo | OSM way 122595236, 60.172444/24.937885, yaw -7.4, 39.5 m | rebuilt; only 2 refs |
| kiasma | 26.0 m LoD2 | partly rebuilt; prow still does not read as the curved shell |
| oodi_library | 23.6 m LoD2 | improved (timber, glass band) |
| helsinki_music_centre | 21.1 m LoD2 | improved |
| finlandia_hall | 33.9 m LoD2 | improved |
| national_museum_of_finland | 64.7 m LoD2 | improved (brown tile roofs, brick belfry) |
| lasipalatsi | colours only | clock tower (OSM 28775756) not modelled |
| amos_rex | paver colour only | mounds still domes; refs poorly matched |
| kamppi_chapel | 12.1 m (OSM 12.13) | paint only; tilted rim not modelled |

## H-5 bridges (2026-11-20)

Refs in `visual-plan/refs/landmarks/br_helsinki_*` (3-4 CC/PD photos each, README per folder). Before and
after frames in `visual-plan/reviews/hel-bridges-{before,after}-2026-11-20/`. Bridge tests passed in a
clean copy of HEAD plus these edits, not in the live tree.

- **Pitkäsilta:** `stone_hex` and `pocks` (shrapnel scars) added; the pocks are square, the stone still
  reads tan at golden hour.
- **Crusellinsilta:** `pylon: "twin"`, `lean: 8`, `stays: 10`, silver-grey steel; pylon blade thinner than
  the real one.
- **Isoisänsilta:** `conf` 1 to 2 (now built), arch on the 144.3 m span only, white, width 5.5, clearance
  6.7. Rise (18 m) and which end carries the 6.7 m span are estimated; real arch is one inclined blade.
- **Lauttasaaren silta:** `conf` 1 to 2, clearance 6.5, girder depth 1.7 m, three round columns per
  support. The seven span lengths are guesses.
- **Kulosaaren silta:** pale girder on five slim round columns, granite footings (boxes, real ones are
  rounded), clearance 9.5 m (scaled from a metro car, +/-20%).
- **Kruunuvuorensilta:** compared, unchanged; pylon colour unverified.
- Raising two rows to `conf 2` deliberately overrides "estimated, not built"; revert `conf` to undo.
- New optional row fields (documented in `bridge_spec.gd`): `steel_hex`, `stone_hex`, `concrete_hex`,
  `pocks`, `columns`, `plinth`, `depth`, `pylon: "twin"`, `stays`.
- Not verified: night looks, photo-beside-render sheet, run in the live tree.

## Photo-checked pass, group E: Töölö, Kallio, Pasila, east (2026-11-20)

Seventeen types, refs in `visual-plan/refs/landmarks/<type>/`, sheets in `visual-plan/captures/hel-r1-E/`
and `hel-r1-E-night/`. Tests ran in a private copy. No in-world capture from an open-space eye; night
lighting barely visible; the sheet tool picks one random ref photo per type, so no matched-bearing
comparison. Several `lat`/`lon` were corrected in `ENTRY` from OSM ways and need an in-world look.

| Type | Status |
|---|---|
| helsinki_olympic_stadium | improved: OSM outline, brown timber wall, tower 72.71 m (published); stand layout guessed |
| finnish_national_opera | improved: 34 m LoD2, glazed barrel-vault foyer; stage-tower height estimated |
| sibelius_monument | legacy generator, about 650 pipes, 8.5 m published; no close exterior photo |
| kallio_church | improved: spire removed (photos show a low green dome), 67.8 m LoD2 |
| kulttuuritalo | rebuilt, moved about 800 m to the OSM way, yaw -36.1; copper wing a guess |
| mall_of_tripla | glass fins, mushroom columns, red sign; mall height (30 m) unmeasured |
| linnanmaki | Rinkeli wheel (OSM node, 34 m), Taiga loop invented; still crude |
| redi_shopping_centre | recoloured weathering steel; podium 15 m estimated |
| hakaniemi_market_hall | rebuilt from OSM outline, yaw -53.7; front face a guess |
| kallio_library | recoloured only |
| helsinki_ice_hall | rebuilt, moved about 370 m, yaw -40.6; roof a low pyramid, not the barrel vault |
| bolt_arena | rebuilt; stand sizes and 28 m masts estimated |
| swimming_stadium_helsinki | rebuilt, moved about 150 m, yaw -10.7 |
| winter_garden_helsinki | rebuilt, moved about 450 m, yaw 205.6 |
| ympyratalo | rebuilt, moved about 320 m, OSM circle r 38.5 m, 9 storeys, 34.5 m |
| hanasaari_power_plant | rebuilt, moved about 700 m, yaw 48; still standing (Commons photos June and October 2026); chimneys 150 m and 97.7 m (OSM nodes), `height_m` 150 |
| pasila_link_tower | rebuilt, moved about 700 m; shaft 112 m, 146 m with mast; one photo of the tower |

`hanasaari` is no longer an open question: it is standing. `aerial2.jpg` in the stadium refs is a 1970s
view from before the renovation.

## Photo-checked pass, group G: Suomenlinna and islands (2026-11-20)

Twelve types, 3 refs each (`visual-plan/refs/landmarks/<type>/`), sheets and compare pages in
`visual-plan/captures/hel-r1-G/`. Shared helper `landmark_fh_g_kit.gd`. Catalogue test passed in a
private copy; hero test not run; no in-world capture.

| Type | Status |
|---|---|
| suomenlinna_church | OSM way 117426288, moved 160 m, yaw -62, 42 m published; fence simplified |
| suomenlinna_kings_gate | rebuilt as ashlar pier with rusticated arch (old pediment gate contradicted photos); yaw 191 from the OSM passage axis; heights estimated |
| suomenlinna_dry_dock | moved 170 m, about 124 x 27.5 m, yaw 21; rim raised since the model cannot dig; still crude |
| suomenlinna_jetty_barracks | OSM footprint 129.5 x 20 m, yaw 4, `clear_rect_m`; clock tower with lantern |
| vesikko_submarine | OSM way 123034962 (40.2 x 4 m), yaw 94; bow end not verified |
| harmaja_lighthouse | granite base, red/white/red iron tower; 20.4 m includes a 3 m mound; published 25 m unverified |
| valkosaari_pavilion | OSM way 115475357, yaw 42, green copper roof, turrets |
| klippan_villa | OSM way 115475359, yaw -15; wing layout simplified |
| uunisaari | OSM way 26936589 (50 x 16 m), yaw 153; red-brick hall, not timber |
| lonna_island | moved 490 m; depot cluster from OSM footprints, yaw 27; colour per building unverified; still crude |
| kustaanmiekka_bastions | shore battery (OSM 117478918), yaw 48; star trace simplified; still crude |
| suomenlinna_fortress | not checked against photos |

Resolved later on 2026-11-20: `suomenlinna_church` and `suomenlinna_fortress` marked the same church
within 30 m, so both rendered there. The fortress dispatch now builds the church class, the church
is no longer a separate registry row, and its reference folder is `suomenlinna_fortress`. Still open:
`SuomenlinnaGate` hard-codes a south-pointing gate axis while the OSM passage axis points NNE.

## Photo-checked pass, group F: Kalasatama, Kallio, west, Lauttasaari, Munkkiniemi (2026-11-20)

Twenty types; refs in `visual-plan/refs/landmarks/<type>/`, sheets in `visual-plan/captures/hel-r1-F/`
(day, with `compare/`) and `hel-r1-F-night/` (8 types). Catalogue test passed (1001 landmarks); hero
test was queued when the agent reported. Commons throttled the agent's IP, so some README author lines
were scraped from File pages, not the API: spot-check them. Two GFDL images were dropped. All yaws are 0
(outlines traced in the unrotated frame). Shared helper `landmark_fh_kala_parts.gd`.

- **Positions corrected:** Löyly about 1 km west (60.15218, 24.93044); Hietalahti hall 110 m north
  (60.16302, 24.92939); Kalastajatorppa 1 km north (60.1922, 24.8736) with `clear_offsets_m` for its two
  wings. Korkeasaari tower: no tower mapped in OSM, registry point kept.
- **Kalasatama towers** (majakka 134, loisto 124, lumo_one 120, horisontti 109, visio 98 m, OSM/Wikipedia):
  `building:part` footprints with the real ~13 degree rotation; LoD2 reads 129.1, 121.9, 117.3, 108.2,
  93.9 m (Majakka +4.9, Visio +4.1 here). Colours and bay widths estimated; which tower is which in
  group photos is a best reading.
- **kallio_virastotalo:** outline and LoD2 38.1 m, `height_m` 38.5.
- **korkeasaari_lookout_tower:** no 25 m timber tower could be confirmed; replaced by the 2002 "Kupla"
  timber sphere (about 10 m, `height_m` 10.5). Unverified.
- **clarion_hotel:** 78 m, LoD2 72.2 (+5.8); 66 m north roof estimated.
- **west_terminal_2:** `height_m` 18 to 23.4 (LoD2); gangways not modelled.
- **cable_factory:** photos show buff brick all round (red band removed); eaves 22.4 m and plant 28 m
  estimated, LoD2 up to 36 m.
- **salmisaari_power_plant:** brick, piers, chimney detail; coal gantry not modelled.
- **loyly_helsinki:** rebuilt from CityGML `100522546S` (6.95 m sauna lookout, 5.65 m twin sea-lobe crowns,
  3.55 m restaurant terrace), OSM ways `625576876`/`466092407`/`1307741294`/`625576877`/`1307741299`–`306`,
  HSY 2023 orthophoto and drone refs: ESE seaward orientation corrected, faceted 3D pine-lamella cloak,
  clear-glass railings, two-flight roof stairs + rooftop amphitheatre, five cowled flues to 8.6 m, four-tier
  overwater sun deck with avanto sea stairs, parasols and SSW pavilion, and `LandmarkStairCut` terrace hold
  shaving the 8.2 m LiDAR roof mound.
- **hietalahti_market_hall:** ridge 12.2 m; matches photos well.
- **hotel_kalastajatorppa:** two OSM wings, rough; 1936 restaurant not modelled.
- **lauttasaari_church / manor:** church improved (nave 17 m not separated from 10 m halls); manor colour
  only, `height_m` 13.5 (LoD2), pedimented porch not added (facing side unknown).
- **aalto_house, studio_aalto (9.2 m, LoD2 9.6), didrichsen, villa_gyllenberg:** legacy models moved
  into own classes and checked against the front photo.

## Photo-checked pass, group A: Senate Square, Kruununhaka, Market Square (2026-11-20)

Thirteen types; refs in `visual-plan/refs/landmarks/<type>/` (one CC BY 4.0 ref with unnamed author:
`government_palace_helsinki/aerial_1960s.jpg`; one with no stated author: `national_library_of_finland/
quarter.jpg`). Compare sheets (own script, front photo left) in `visual-plan/captures/hel-r1-A/compare/`
and `hel-r1-A2/compare/`. Hero test passed. No in-world capture, no night render (floodlight spots added
in code for five types, unrendered). Windows still read as black rectangles. Shared helper
`landmark_fh_empire.gd`. Many registry lat/lon were off and are corrected in `ENTRY`.

| Type | Status |
|---|---|
| helsinki_cathedral | unchanged (row in `location_data.gd`, model in `LandmarkCathedrals`); 62 m published, LoD2 58.9 omits the cross |
| government_palace_helsinki | rebuilt from OSM relation ring; LoD2 26.1 m confirms the position; rear rhythm estimated |
| helsinki_university_main | rebuilt from OSM relation, yaw -93, 22.4 m from the photo (the 29.9 m LoD2 hit is Tiedekulma) |
| national_library_of_finland | giant Corinthian order, 24.0 m from photo scale vs LoD2 27.9 m (3.9 m disagreement), yaw -93 |
| sederholm_house | OSM outline 18.4 x 11.8 m, gambrel roof, yaw 178 |
| bock_house | OSM outline, Ionic portico, 17 m (LoD2 17.6), yaw 180 |
| uspenski_cathedral | own class, model unchanged; main drum too squat; LoD2 48.2, published 50 m |
| enso_gutzeit_hq | own class, colour only; LoD2 25.1 m |
| presidential_palace_helsinki | pale yellow, six columns, iron fence; hip roof still tall; LoD2 20.6 m |
| helsinki_city_hall | OSM outline (was about 60 m off), 25 m to finial from photo (LoD2 only 18 m nearby) |
| market_square_helsinki | centred on the obelisk; quay, Cholera Basin, paving not modelled |
| old_market_hall_helsinki | recoloured; diamond brick and gable window missing; LoD2 12.6 m |
| havis_amanda | rewritten (basin, rock, sea lions); figure still crude |

Housekeeping: the agent fixed a parse error in `landmark_fh_linnanmaki.gd` (`var u: float`), and killed two
queued `golock` processes whose command line matched `landmark_catalog_test` or `helsinki_measured_heights`.
Catalogue failure it saw belongs to `katajanokka_terminal` (18.1 m built against 14 m expected).

## H-6 city fabric tells (2026-11-20)

Edits: `scripts/generation/architecture_cities_finland.gd` (window palette, `HARBOUR` render palette,
lighter `COMMERCIAL_STONE`), `HelsinkiNotable` table, `tests/helsinki_notable_test.gd`.
Before/after frames (Ultra, noon, open-space eyes, cloned trees): `visual-plan/reviews/hel-r1-fabric{,2,3}-{before,after}-2026-11-20/`.

- **Per-building facts:** nothing was overriding them. On the cached centre (1592 buildings) the register
  facade material reached the wall set in all 221 buildings carrying one; the LoD2 roof form was drawn as
  given in 867 of 867. `tools/helsinki_fabric_probe.gd` also reports `notable=3`.
- **HelsinkiNotable:** the table was empty. Three commercial-core stone fronts with no hand-built landmark
  were added: Pohjola (`way:17425472`), Pörssitalo (`way:123550797`, granite confirmed on fi.wikipedia),
  Uusi ylioppilastalo (`way:224711434`; the finish comes from a blog, imprecise). Old Student House facade
  colour not confirmed, so no row.
- **Windows:** the Helsinki rows take a five-type palette (casement, wide, sash, french, small) by look
  seed; material count unchanged.
- **Harbour render:** ochre, orange-brown, rust, cream, putty, sage (reference 02).
- **Still a tell:** commercial-core stone renders dark navy in shade and olive-tan close up (the lighter
  palette did not visibly change the looks captured; the stone photo set under sky light is the probable
  cause); the Market Square plaza and facades are bright; facades are per-storey tile repeats, so large
  uniform grids remain on strip fronts; the quay edge was left unchanged.
- **Not verified:** no numeric brightness/saturation comparison; the three notable fronts were never
  captured in-world; `helsinki_coverage_test`, `finland_hero_test`, `facade_panel_tone_test` had not run.

## Photo-checked pass, group B: South Harbour, Katajanokka, Kaivopuisto (2026-11-20)

Fifteen types; refs in `visual-plan/refs/landmarks/<type>/` (GFDL and FAL images skipped), sheets and
compare pages in `visual-plan/captures/hel-r1-B/` and `hel-r1-B-night/`. Catalogue and hero tests pass.
LoD2 was not read (probe failed to compile), so heights are photo estimates or published figures. No
in-world capture; night flood spots (`FLOOD_META` for Agricola, German Church, St Henry's, Observatory;
lit parts on Skywheel and Makasiini) are not visible in `--night` captures. Registry placement against
terrain not checked.

| Type | Corrected position / measured | Status |
|---|---|---|
| kappeli | moved 46 m; outline and axis OSM, yaw 177.1 | improved; heights estimated |
| allas_sea_pool | pools, saunas, main building OSM, yaw 90; `height_m` 12.0 | improved; deck outline estimated |
| skywheel_helsinki | height and yaw measured | improved; wheel and gondola sizes estimated |
| merikasarmi | outline OSM | improved; heights estimated |
| katajanokka_terminal | outline OSM; `height_m` 15.8 | improved; facade rhythm a guess (builds 18.1 m vs 14 m expected in group A's catalogue run: recheck) |
| katajanokka_casino | outline OSM, yaw -2.4 | improved; pilasters uncertain by a few metres |
| hotel_katajanokka | cross outline and wall OSM, yaw -39.5 | improved; annex rotation guessed |
| olympia_terminal | moved 220 m; outline OSM, yaw 53.3 | improved |
| makasiiniterminaali | moved about 150 m to the OSM node (no building mapped), yaw 51 | improved; all dimensions estimated |
| helsinki_observatory | moved 190 m; outline OSM, yaw -179.7 | improved |
| german_church_helsinki | moved 70 m; yaw 87 | improved; nave still small |
| st_henrys_cathedral | moved 130 m; yaw -101.4 | improved |
| mikael_agricola_church | moved 160 m; yaw -36.1; nave 11.55 m measured | improved |
| ursa_observatory | moved 380 m; drum 5.4 m (OSM), `height_m` 15 to 9.6 | done (agent rating) |
| design_museum_helsinki | outline OSM, yaw 86.3 | improved |

## H-7 harbour, transit and ground (2026-11-20)

Frames: `visual-plan/reviews/hel-h7-{before,after,final,final-metro,plaza,plaza2}-2026-11-20/` (per-object frames
for bus, commuter ferry, cruise ferry, icebreaker, market boat, tram). Tests run afterwards by the
main session: marina, landcover_ground, train, tram, vessel_models, kerb, architecture,
helsinki_notable pass; `harbour_traffic_test` was counting parts by name, which Godot rewrites to
`@MeshInstance3D@N` for repeated names, so it undercounted vessels (the planner placed 5 commuters, 5
icebreakers and 7 market boats). Parts now carry a `harbour_kind` meta and the test counts distinct
vessel positions per kind.

- **Wiring that was missing:** `HarbourVesselData` rows (commuter routes, cruise liveries, moored
  fleets, market boats) and `CommuterFerryModel` existed but nothing built them. Now
  `HarbourTraffic` (called from `HarbourFerries.build`) places the HSL 19 Suomenlinna ferry and
  JT-Line water buses (one berthed at Kauppatori, the rest under way with wakes), the five
  icebreakers rafted at Katajanokka (`IcebreakerModel`) and the Kauppatori market boats
  (`MarketBoatModel`). `MarinaBuilder.plan` claims those hulls first so small craft keep off them.
  `FerryLivery` dresses cruise ferries by terminal (Silja, Viking, Tallink, Eckero) through
  `QuayMoorings.liners` -> `LargeShips.geometry` -> `VesselPrototypes` -> `CruiseFerryModel`.
- **Small boats:** `MarinaBuilder.fleet_of` reads `HarbourVesselData.FLEET_PROFILES` (FI, or any
  Helsinki/Espoo/Turku place): wooden browns, navy and green hulls, 50% sailboats, fewer flybridge
  yachts; other places keep the old colours and shares.
- **Granite (`FinnishGranite`, gated on country FI or the Helsinki/Espoo/Turku zones):** ground
  palette `rock` pink-grey, `sett` and open paving (`urban`, `building`) as dark pink-grey granite
  (`#767070` paving, `#807977` sett; the shared `#8e887c` blew out to near white at noon on Senate
  Square, frames `hel-h7-plaza` vs `hel-h7-plaza2`), `RoadBuilder` sett and paving finishes,
  `KerbBuilder` granite kerb (paler), `ShoreApron` rock. `GroundMaterial.palette` takes per-class
  overrides; Stockholm's `ShoreApron.palette_overrides` rides the same hook (separate WIP).
- **Buses:** `HSL_BLUE` was entered as sRGB but BUS_PAINT rows are linear albedo, so the bus read
  cyan; now `Color(0, 0.17, 0.57)`.
- **Tests added/extended:** `harbour_traffic_test` (routes, icebreakers, market boats, liveries),
  `marina_test` (Finnish fleet), `landcover_ground_test` (granite overrides).
- **Not done / not verified:** quay edge stone (`quay_builder.gd` belongs to the city-fabric work);
  Katajanokka terminal ferry lettering is too small to read from the frames taken; tram route and
  destination boards are present (black display) but their text was not read; the Helsinki metro
  was not seen in-world (no surface metro track in the Kulosaari pin frame; `train_test` covers the
  model); transit buses were not found in the main build (only parked buses); the West terminals
  (3.5 km out) were not captured; the pale pink rock in `ground_model`-driven frames changed only
  slightly.

## Verification at the end of the 2026-11-20 pass

- **Refs:** all 104 Helsinki landmark types have local photos under `visual-plan/refs/landmarks/<type>/`;
  100 have three or more, four have two (`aalto_house`, `hotel_kalastajatorppa`, `lauttasaari_manor`,
  `sanomatalo`). Authors and licences are in each folder's README; a few author lines were scraped
  from File pages, spot-check them.
- **Tests (live tree):** harbour_traffic, helsinki_coverage, helsinki_notable, finland_hero,
  facade_panel_tone, inner_helsinki_coverage, helsinki_hero_landmarks and 36 of 37 tests in the
  bridge/architecture/building/tram/train/marina/vessel/kerb/ground/rock/host_policy group pass;
  `tools/check_class_size.sh` OK (largest class 996 of 1000 lines).
- **Not Helsinki, failing:** two `landmark_catalog_test` search rows ("Gröna Lund", "Viking Line
  Terminal", Stockholm) and `bridge_specs_test` (13 rows, all `br_turku_*`).
  `stockholm_hero_landmarks_test` and `landmark_fidelity_test` were failing in the middle of this
  pass on the Stockholm work in progress; they are not Helsinki's.
- **Test edits made to match rebuilt models:** `helsinki_coverage_test` (new heights, a
  `clear_rect_m` check with 9 m slack, Suomenlinna rows), `inner_helsinki_coverage_test` (new heights;
  `SPILL_M` for Linnanmäki's wheel and coaster and West Terminal 2's roof), `harbour_traffic_test`
  (counts vessels by position per `harbour_kind`, since Godot renames repeated part names).
  King's Gate `clear_m` is 32 so it covers its model radius.
- **Not done, needs the user:** the "photographic" call (side-by-side sheets in
  `visual-plan/reviews/hel-r6-final-2026-11-20/sheet_city_{1,2}.jpg` and the per-group compare sheets);
  in-world `clear_m` checks for the moved landmarks; night captures that show the new floodlights;
  `window_grids` still dark rectangles; screenshot_test and world_cache_test (need a window).
- **Final reruns (serialised, after killing hung runs):** `helsinki_coverage_test` OK (14 landmarks),
  `world_cache_test` OK, `finland_hero_test` OK. `helsinki_lod2_test` fails on the Turku LOD2 cells
  modified in the working tree (not Helsinki).
  `screenshot_test` exit 0 (19 shots, no script errors), run windowed off-screen.
- **Night and clearance checks (2026-11-20, after the first sign-off pass):** three open-space eyes (Senate
  Square, Kauppatori quay, Makasiini pier), Ultra, two hours after sunset, in
  `visual-plan/reviews/hel-night-final-2026-11-20/helsinki_look{0,1,2}.jpg`. The cathedral is floodlit, the
  SkyWheel, a ferry and a cruise ship are lit with reflections in the water, and office windows read as lit
  rows. Daylight harbour frame: `helsinki_vantage_noon.jpg`. `clear_m` against the City of Helsinki LoD2
  model for every bespoke Helsinki row without a rect, offsets or path (36 rows with those are covered by
  the rect checks in the coverage tests): only kiasma (2), old_market_hall_helsinki (1), allas_sea_pool (1)
  and national_museum_of_finland (1) have any building of 6 m or more with its centroid between the model
  radius + 6 m and `clear_m`, so no landmark clears a block of real neighbours.
- **H-7 tests on the live tree (resumed agent, 2026-11-20):** train, bus_stop, vessel_models, harbour_ferries,
  ship_builder, ship_mooring, ship_paint, tram and transit_layer all exit 0. Senate Square is mapped as slabs,
  not setts. Quay walls already build as dressed granite ashlar for Nordic cities. Not seen in-world: metro
  track, the HSL-blue buses in the main build, tram board text, cruise ferry lettering, the west terminals.
- **Transit and terminal frames (2026-11-20):** `visual-plan/reviews/hel-transit-final-2026-11-20/helsinki_look{0..5}.jpg`,
  six open-space eyes, Ultra, golden hour. Seen: an HSL-blue bus at Rautatientori (look1, blue and not cyan, so the
  linear-albedo fix holds in the main build) and small blue buses in front of the station and its clock tower (look2).
  Not seen: a tram with a readable board, the metro (the Kulosaari drone eye, look4, shows no train), the cruise
  ferry lettering, and West Terminal 2 (look0 shows a green glazed hall at the Jätkäsaari eye that I did not
  identify). Vehicles move, so a frame only catches them by luck; `tram_test`, `train_test` and
  `bus_stop_test` cover the models. `SuomenlinnaGate` axis (-0.18, 0, 0.984) is a bearing of 190 degrees, the same
  line as the OSM passage axis and the King's Gate yaw of 191, so that question is closed. `helsinki_lod2_test`
  passes again now that the Turku cells in the tree load.
- **Final-state retest and West Terminal 2 (2026-11-20, last pass):** `landmark_catalog_test`, `stockholm_hero_landmarks_test`
  and `landmark_fidelity_test` now pass (the earlier Stockholm failures were transient work in progress). `bridge_specs_test`
  still fails on Turku (`br_turku_kirjastosilta` and the other `br_turku_*` rows), not on Helsinki.
  `visual-plan/reviews/hel-west-final-2026-11-20/west_terminal_2_{vantage,h090,...}.jpg`: West Terminal 2 reads as the
  green-glazed hall with the pale ramp and a Tallink ship alongside, and the "TALLINK" hull lettering is readable in the
  vantage frame. So the green hall in the earlier Jatkasaari frame (`hel-transit-final` look0) was West Terminal 2. Still
  not caught in a frame: a tram board with readable text and a metro train.


## See-through rock fix (2026-11-20)

The grey ribbed arch at the left edge of `hel-r6-final-2026-11-20/helsinki_look8.jpg` (Kaivopuisto, eye
60.15550,24.95600, 50-70 m away) was not a landmark or bridge: it was `natural=bare_rock` outcrop mounds from
`RockOutcrops` (Kaivopuisto's bedrock, `class: rock` land polygons). `mound()` shrinks the outline toward its
centroid in three rings; on a banana- or horseshoe-shaped patch whose centroid lies outside it (here 93 points, 41 x 62 m,
and a 3800 m2 patch 80 x 200 m west of the eye, the long ribbon behind the Ursa dome in a bearing-310 look) the rings fold
over each other, so the single-sided skin shows only loose ribs. Fix: polygons that are not star-shaped about their
centroid, or that have holes, now go through `RockOutcrops.field()`, a height field over the outline (sunk boundary,
jittered interior points rising with distance from the edge, Delaunay triangles kept only where they lie on the rock).
Convex and star-shaped patches (Central Park, Stockholm scatter) still use `mound()`. Test: `tests/rock_outcrops_test.gd`.
Frames: `visual-plan/reviews/hel-rock-before-2026-11-20/` and `hel-rock-2026-11-20/` (looks 0-3 of the same eyes).

## Black building patches fix (2026-11-20)

Status: **not reproduced, no code changed.** The black masses in `hel-r6-final-2026-11-20/helsinki_look10.jpg`
(eye 60.16400,24.96000, 120 m, bearing 330, pitch -25; far blocks top right and top left, the cruise ship hull at the
bottom left) were pure zero pixels (0-4 per channel) with no haze lifted over them, even on blocks 1.6 km away, so they were
lit by nothing (a NaN or zero-ambient result), not a dark paint. Surfaces under the cursor were a merged `LodCell_*`
facade mesh (top right, 1.6-1.8 km), `LodCell_-3_0_*` (top left, 1.3 km) and `Marina/CruiseFerry_*` (ship, 270 m), all with
valid shaders and light colours (cream hull `#f0eee8`, facade tints 0.7-1.6).

Checked and ruled out, on the current tree at Ultra (`--preset=3`): the same eye with the r6 world centre forced
(60.17027,24.95278); the eye alone; the whole twelve-look r6 chain with the same recentres (`hel-blkr6-2026-11-20`, look10
has 1 black pixel); an eleven-rebuild chain; frames 1, 4, 15, 40, 100, 240 and 500 after the eye was placed (SDFGI is not
still converging); and the committed tree at `f8a8be46` in a separate worktree. A scan of every mesh surface in the built
world (3349 meshes) found no NaN or non-unit normals, no NaN tangents and no zero vertex colours on any building, landmark
or ship, so the Helsinki palette (all hex strings in `architecture_cities_finland.gd` parse), the native merge and the
far-city tier are clean. The r6 frames differ from every later run only by code that has since changed, so the patches were
a transient lighting state of the tree at 03:07 (the last twelve eyes of that round, and the Ultra SDFGI ambient, are the
suspects), not data in the Helsinki models.

If the black returns: the frame to compare is `hel-blkbld0-2026-11-20/helsinki_look0.jpg` (same eye, clean). Run the capture
with the street-level SDFGI toggles of the other black-surface checks first, and count pixels under 22/255 (a clean look10
has fewer than 10).

## Black smear fix (2026-11-20)

Water case: **a capture-tool defect, fixed in `tools/capture_presets.gd` (`_place_eye`).** The black slab in
`hel-r6-final-2026-11-20/helsinki_look0.jpg` (eye 60.16700,24.95530, 2 m, bearing 330, pitch 5) is the water seen from
below. `--looks` measured the height over `GroundTruth.height_at_world`, which over water is the carved bed; here the bed is
-10.44 and the water -8.41, so a 2 m eye sat 3 cm under the surface. The water shader is `cull_disabled` with an always-up
normal, so its underside lights like a top: the sunlit part reads as a pale band, the part in the shadow of the far
buildings as pure black (and the sky mirror showed inverted above the horizon). SSAO/SSIL off, SSR off and SDFGI
occlusion off left the slab; SDFGI off turned it flat grey-green (the unlit underside), and a vertical probe at 0-6 m ahead
stacked Water at -8.41 over Terrain at -10.44. The 7 m eye of `hel-diag1` looked down on the same water, hence no slab.
The app's own camera is not affected: walk and drone use `LandmarkTerrain.floor_y` (ground or water, whichever is higher).
Fix: `_place_eye` now measures from `max(height_at_world, water_level_at)`, the same datum. No shader, ground or light
setting changed. After: `hel-blk-fixed-2026-11-20/helsinki_look0.jpg`.

Park case (60.15550,24.95600): not reproduced. Four bearings at 2 m at Ultra, golden hour, show lit grass, a normal
shadow band under the pines and a readable path (`hel-blk-fixed-2026-11-20/helsinki_look1.jpg`, `hel-blk-base2-2026-11-20/`
looks 1-3). The `hel-diag1` look3/look4 frames show different trunks and a different eye; their darkness is consistent with
an eye against a rock outcrop or its base (the rock mesh work of the same day), not with a shader or light setting.
- **Round hel-r7-final (2026-11-20), the sign-off frames:** the round was re-run after the user reported a black slab
  on the water (look0), a see-through rock (look8) and black patches on buildings (look10) in `hel-r6-final`. Causes: look0
  was a capture-tool bug (eye height measured from the sea bed, so the 2 m eye sat under the water surface; fixed in
  `tools/capture_presets.gd`); look8 was bent rock polygons folded into a skin (fixed in `rock_outcrops.gd`, test
  `rock_outcrops_test`); look10 could not be reproduced (exactly-black pixels in the r6 frame, none in any later run, and
  none in r7). Frames and the two sheets, `sheet_city_{1,2}.jpg`, are in
  `visual-plan/reviews/hel-r7-final-2026-11-20/`; use these, not `hel-r6-final`, for the photographic call.


## Street life, Esplanadi and Mannerheimintie (2026-11-20)

Frames: `visual-plan/reviews/hel-street-before-2026-11-20/` (the user's four looks, old code),
`hel-street-b100-2026-11-20/` (same looks plus park eyes, `--look_ahead=100`, before the gravel grain, bench, lantern
and tram-stop changes), `hel-street-after100-2026-11-20/` (final, eight looks, `--look_ahead=100`) and
`hel-street-2026-11-20/` (the user's exact command on the new code, default `--look_ahead`).

**Why the street was bare: a capture-harness artefact.** `tools/capture_presets.gd` rebuilds the world 800 m *ahead*
of a look's eye (`LOOK_AHEAD_M`) so the view stays inside the detailed square. The street props are planned around the
world centre and stop at fixed radii: `OverheadWires` 600 m and its nearest-first 400-span cap (about 245-320 m in
Helsinki), `StreetFurniture` 400 m, `ParkedCars` 320 m, lamps 600 m. A 2 m eye 800 m from the centre sits outside all of
them, so look2/3/5 had no catenary, span lamps, signals, benches, tram or bus stops, although the data holds them
(484 embedded tram ways with `electrified=contact_line`, 65 benches, 131 bus and 72 tram stops, 46 signals in the
r1200 answer). With the world centred 100 m ahead (new `--look_ahead=metres` flag; default unchanged so other
agents' A/B captures stay comparable) the same eyes show the tram wires, poles, hung luminaires, signals, buses
and benches (`hel-street-b100` look1/look2, `hel-street-after100` look1/look7). Use `--look_ahead=100` for any
street-level look. A 1.2 cm contact wire is still near the sub-pixel limit at 30 m; it reads in the frames.

What existed already: `OverheadWires` (catenary, Finnish span-wire luminaires), `StreetProps` lamps (Finland's lit
park paths only in green cover), `StreetFurniture` (mapped benches, signals, bus stops, HSL stop sign),
`PlazaLife`, `GroundMaterial` palette overrides, `FinnishGranite`. Nothing was added to `OverheadWires`; no parallel
system was made.

Added (all gated on `FinnishGranite.applies` or the `nordic` furniture family, so other places are unchanged):
- **Park gravel.** `FinnishGranite.GRAVEL_HEX` `#9c6e56` (red-brown) and `palette_overrides` `path`; `park_way()` marks
  a footway/path with no `surface` tag lying in a grass polygon. `RoadBuilder`: the gravel finish takes that colour and
  the real `gravel` PBR set (it was the flagstone `pavement` set tinted, which read as pink slabs, `hel-street-b100`
  look4 against `hel-street-after100` look4); an unsurfaced park way becomes gravel (`_district_finish`, `_Surface.parks`).
  `GroundMaterial._paint_features`: compacted/gravel and park footways paint the `path` class under the ribbon.
  In the r1200 answer about twenty park ways are `surface=compacted` or `fine_gravel`; the other footways in parks are
  paved or sett by their tags and stay so.
- **Benches.** `StreetFurniture.park_spots`: one every 20 m on alternating sides along gravel footways in green cover,
  facing the path, 8 m clear of a mapped bench, at most 160, nearest first. New `bench_park` mesh (red-brown slats, black
  iron ends, raked back; `wood_red` material) is now the Finnish bench for mapped nodes too.
- **Lamps.** Lit park paths in Finland take the cast-iron `lantern` (it was the plain `post_top`) every 16 m
  (`PARK_LAMP_SPACING_M`, was 25 m). Stockholm keeps `post_top`.
- **Tram stops.** `data.tram_stops` become a green HSL tram-stop pole (`stop_tram`) on the nearest kerb, as a bus stop
  does.
- **Tool.** `capture_presets.gd --look_ahead=metres`.

Counts at Ultra (Helsinki, eye 60.16745,24.949, `--look_ahead=100`): 70 lanterns, 37 `post_top`, 50 park benches, 8
tram-stop poles; at Mannerheimintie/Kaisaniemenkatu: 85 lanterns, 127 `post_top`, up to 135 benches, 20 tram-stop poles.
Mesh nodes: +2 `MultiMeshInstance3D` (`Prop_lamp_lantern`, `Furniture_stop_tram`); `bench_park` replaces
`bench_wood` as one node; instance totals rise by at most 160 benches, about 35 lanterns and one pole per tram stop.
`tools/perf_baseline.gd` was not run (no per-item nodes were added).

Tests: `street_furniture_test` (park spots, `bench_park`, `stop_tram` meshes and placement), `road_markings_test`
(park lantern, no `post_top`), `landcover_ground_test` (gravel palette, `park_way`, class map under a compacted
footway in FI vs elsewhere) all pass; `plaza_life_test`, `helsinki_streets_test`, `tram_test`, `transit_layer_test`,
`kerb_test`, `ground_surface_test`, `finland_hero_test`, `street_lights_test` pass; `tools/check_class_size.sh` OK.

Still missing against `06_esplanadi`, `09_mannerheimintie_parliament`, `07_rautatientori`: the Runeberg statue plinth
and flower beds (no mapped furniture or data for them), trimmed linden alleys with the tall poplars, people, street
name and taxi/parking signs, tram shelters on the island platforms (stops are poles on the kerb, the carriageway's
edge, not the island), lamps along Pohjoisesplanadi's sett carpet (look0 shows none; lit footways off green cover take no lamp by design and
this was not traced further), the contact wire's thickness at a distance, and benches along paved or sett park paths
(only gravel ways get them).

## Facade tone fix (2026-11-20)

Problem: in `hel-r7-final` look2 the wall left of Pohjoisesplanadi rendered as a dark mossy green block, and several
central fronts read olive or flat grey where the real centre is ochre, cream and grey-pink render over granite.
Cause: the `stone` front (`helsinki_commercial`, `COMMERCIAL_STONE`) is drawn from the sandstone photo set, whose linear
mean is orange-brown; `FacadeMaterials._calib` takes target over mean per channel and clamps at 2.8x, so a grey target
needed blue x7.6 and got x2.8. The albedo came out olive-green (about 0.52, 0.64, 0.41) and under the blue shade light it
went black-green. The olive render fronts came from sage and olive entries in the `HARBOUR`, `PASTEL` and `JUGEND` palettes,
random place tones in `WallVariety` and a stucco speckle that read as pebble-dash.
Fix (all gated on Helsinki, other cities unchanged): `facade_materials.gd` (`_helsinki`, `_stone_calib` with 0.3 to 8x,
stone cache key keeps the HDR tint, `_look_key` carries a city prefix), `facade_textures.gd` (`distant_facades` uses the
same calibration; `smooth_photo` follows `FacadeComposer.smooth_plaster`), `facade_composer.gd` (`SMOOTH_PLASTER_CITIES`
stockholm and helsinki), `architecture_cities_finland.gd` (`HEL_PASTEL`, `HEL_JUGEND`, `HEL_EMPIRE`, grey-pink replaces the
sage in `HARBOUR`), `architecture_style.gd` (`HELSINKI_TONE` 0.12).
Result (`hel-facade4-2026-11-20`, final round `hel-r8-final-2026-11-20`): the stone front is neutral grey granite instead of
green-black, Senate Square fronts read ochre in sun and grey-khaki in shade without speckle.
Still wrong: shaded plaster reads grey-khaki, not warm cream (the Ultra shade ambient is strongly blue and no warm-bounce
term was added to `FacadeShader`), the stone front is still near charcoal in shade at 2 m, and some Market Square fronts
use shared distant materials that keep a khaki tone. Tests after the change: building_variety, building_fabric,
building_references, architecture, facade_shader, facade_panel_tone, facade_relief, facade_texture_cap, facade_lite_shader,
poi_facade, tower_facade_uv, inner_helsinki_coverage, helsinki_coverage and landmark_catalog all exit 0;
`tools/check_class_size.sh` OK (largest 996 of 1000 lines).

## Warm bounce on shaded fronts (2026-11-20)

Problem: the 'Still wrong' items of the facade tone fix. The Ultra shade ambient is blue, so a yellow or ochre albedo in
shade read olive-grey, and dark stone fronts and shop fascias read near-black. Real Helsinki fronts out of the sun stay warm
because sunlit paving and pale walls throw warm light back onto them (refs 05, 07, 13).
Fix (gated on Helsinki, other cities untouched): a `warm_bounce` uniform in `FacadeShader` and `FacadeLiteShader` adds an
emission `(wall + 0.12) * (1.0, 0.80, 0.58) * k * side * shade * sun_up`, with `k = FacadeTextures.HELSINKI_BOUNCE` (0.16),
`side = 1 - n.y` (walls, not roofs), `shade = 1 - smoothstep(-0.05, 0.35, dot(n, cloud_sun_dir))` (gone where the sun reaches the
wall, so sunlit faces are unchanged) and `sun_up` (gone at night). The 0.12 constant lifts a near-black albedo a little. The
material is marked in `FacadeTextures._facade_material_for` (meta `warm_bounce` when `look.city` is helsinki), in
`FacadeTextures.distant_facades` (region city; the distant look carries no city), in `FacadeMaterials.ground_for_building`, and
for POI shopfront fascias (`building_builder.gd` passes `city` into `shop_look` for Helsinki only); both shader builders copy the
meta to the uniform. `FacadeMaterials.facade_for_building` keys Helsinki materials with `|hel`. Lite (Balanced/High) draws
the same term from `base`; its night emission now adds to it instead of replacing.
Result (`hel-warm-2026-11-20`, same eyes as `hel-r8-final-2026-11-20` look2, look1, look4, look0 as its look0..look3): the
Market Square plaster fronts go from olive-grey to cream and pale ochre, the Pohjoisesplanadi ground floor goes from black to
dark brown, pilasters and stone trim read mid grey.
Still wrong: bounce ignores real cast shadows (a front shaded by a neighbour while facing the sun gets none), the Oodi wood
wall keeps black smears in the frame (they are present in the before frame too and come and go between runs), and the shop
fascia colour itself is dark brown, so it stays brown. The shore water build raised a script error in `shore_water.gd:24`
during the capture; it is not from this change.

## Capture note (2026-11-20)

`tools/capture_presets.gd` rebuilds the world 800 m ahead of each look's eye by default, and street props (catenary, lamps,
benches, stops) only reach 320 to 600 m from the world centre, so street-level eyes showed none of them. Use
`--look_ahead=100` for street-level looks; `hel-r8-final-2026-11-20` was shot that way and is the round to judge. In that
round look6 was captured separately (the main run produced no frame for it) and copied in.


## Water smears in aerial frames (2026-11-20)

`hel-r8-final-2026-11-20` look10/look11 (harbour from 120-150 m) showed dark charcoal specks and soft smears on the
water that `hel-r7-final` did not. They are the ambient gulls (`AmbientLife`, `AmbientBirds` MultiMesh), drawn black.
Gulls orbit within about 190 m of the world centre at 38-96 m above ground, so they are only near the eye when the world is
centred close to it. `--look_ahead=100` (the r8 flag) puts them 20 to 100 m from the eye; the r7 default of 800 m kept
them beyond their 750 m fade. A 1.4-1.8 m wingspan at 18-40 m under a 120 m eye, faded in by the 18-42 m alpha ramp, reads
as a dark soft smear; farther ones read as dark specks. The orbit phase follows shader `TIME`, so the exact smears of r8
do not recur: several captures of the same two eyes (default and 800 m look-ahead, 1280x800 and 1600x1000) showed only the
specks. The large smears are therefore attributed to a near gull by size and fade, not reproduced; the specks were
reproduced and fixed.

Root cause: `_get_bird_mesh()` winds its wing triangles downward (face normal -Y) while its vertex normals say up. With
`cull_disabled` the engine flips the normal on back faces, so a bird seen from above was lit as if from below and went
black against the sea. Dark inland tint (0.18) hid this on land; the coastal tint is white (0.84), so over the harbour the
flaw was most visible.

Fix: `AmbientLife.BIRD_CODE` fragment now sets `NORMAL` to world up in view space (`scripts/render/ambient_life.gd`,
three lines before `ALBEDO`), so both faces take top lighting. Birds seen from above are white gulls. No other city's look
changes except birds viewed from above, which were black before.

The bright dots are not birds: they stay with `AmbientBirds` hidden. They are the water shader's sun glitter
(`WaterShader` `spk`, `pow(ndh, 280)`), isolated facets of the long swell and wind-wave slopes catching the sun; they sit in
the same places before and after. Left as is.

Frames: `visual-plan/reviews/hel-smear-before-2026-11-20/` and `hel-smear-after-2026-11-20/` (look0 = eye 60.164,24.960
and look1 = eye 60.165,25.000, `--preset=3 --look_ahead=100`, default 1280x800): black specks before, white gulls after.
- `hel-r8-final-2026-11-20` look10 and look11 were re-shot after the gull-normal fix (`hel-r8-air-2026-11-20`) and copied in; the dark smears on the water are gone and the gulls read as white. `sheet_city_{1,2}.jpg` were rebuilt from the final set.

## Black streaks on walls (2026-11-20)

`visual-plan/reviews/hel-warm-2026-11-20/helsinki_look2.jpg` (eye 60.17380,24.93800, 2 m high, bearing 0) showed jagged black
streaks and blotches over the Oodi timber wall, and black on the lower half of the cars and the windows of the brick block
beyond. The same eye in `hel-r8-final-2026-11-20/helsinki_look4.jpg` has them too; a run on a cached world has none.

What they are: not the wall's material. With the street eye rebuilt fresh (`PR360_DISABLE_WORLD_CACHE=1`, a far look between
so the world is built again) about 12 of 28 frames were streaked and some were wholly black (wall mean 15 of 255 against 62
clean; `max(r,g,b) < 22` over the left 45 % of the frame, 67 k px clean, 175-275 k streaked, 495 k black). In a streaked frame
every one of these left the black unchanged: SDFGI, SSAO, SSIL, SSR, volumetric fog, TAA, the sun's shadow, the sun itself,
constant ambient, the sky reflection, and the wall's own material (`LandmarkShader` rain streaks, its albedo, its normal map,
or the plain `StandardMaterial3D` the shader replaces). A flat standard material or a constant roughness hid the wall's
streaks only because the black rides on the glossy pixels: a wall's roughness map, car paint and window glass are the smooth
surfaces, so the pattern follows the wood grain. Hiding the 60 km view probe (`ViewReflections`), or both it and the five
box-projected street probes, brought the wall back to a normal frame; hiding the street probes alone did not. A fresh capture
(UPDATE_ALWAYS for three frames, then UPDATE_ONCE again) with the camera at the eye cleared every bad frame (6 of 6) and the
result held after the mode went back to UPDATE_ONCE.

Cause: `tools/capture_presets.gd` `_place_eye` moves the camera rig to a look without telling the atmosphere rig, so the
view probe and the street probes stayed at the world's centre (100 m from the eye with `--look_ahead=100`, 30 m up) holding
the capture made as the new world appeared. That capture is taken while the world is still arriving and is bad in about
half the runs; whatever stands in it is what the glossy surfaces near the eye reflect. A walk, a flight and a stream swap
call `AtmosphereRig.set_probe_origin` whenever they move the rig (`view_walk.gd`, `view_drone.gd`, `stream_swap.gd`), so the
probes follow the eye and re-capture there; the capture tool was the one mover that did not. Why a capture made from the
centre is bad on some runs and good on others was not isolated (nudging `intensity`, as `_process` does after the debounce,
did not replace a bad capture either).

Fix: `_place_eye` calls `view._atmos.set_probe_origin(rig.position)` after it sets the rig position
(`tools/capture_presets.gd`). No game code changed, so no other city's look changes in play; capture frames of any `--looks`
eye, card or thumb now have reflections taken at the eye.

Check: the eye above, six fresh worlds in one run (`PR360_DISABLE_WORLD_CACHE=1`, a far look between each), near-black pixels
(`max(r,g,b) < 22`, left 45 % of the frame): before 67 k, 496 k, 497 k, 67 k, 497 k, 67 k (three of six wholly black; this run also had a three-frame UPDATE_ALWAYS re-capture after the debounce, which changed nothing); after
68.1 k, 68.9 k, 68.6 k, 68.1 k, 68.1 k, 68.5 k (the dark louvre band only). Frames:
`visual-plan/reviews/stk-f1-2026-11-20/` (before) and `stk-f2-2026-11-20/` (after), `helsinki_look{0,2,4,6,8,10}.jpg`.

## H-1…H-6 Landmark, Floodlight & Notable-Fabric Completion Pass (2026-11-23)

- **Three new H-1 Market Square / Esplanadi landmarks (`landmark_fh_centre_models.gd`):**
  - `swedish_embassy_helsinki` (`landmark_fh_swedish_embassy.gd`, `60.16797, 24.95475`, OSM way `17341313` / Torben Grut 1922 palazzo remodel of A. F. Granstedt 1839): 3-storey cream-ochre Renaissance palazzo front facing Pohjoisesplanadi/Kauppatori, rusticated ground arcade, loggia/balustrade crown to `18.5 m`, `clear_m: 18.0`, `secondary: true`, 6 parts, 13,554 tris, 3 `FLOOD_META` spots.
  - `supreme_court_helsinki` (`landmark_fh_supreme_court.gd`, `60.16807, 24.95547`, OSM way `17341314`, F. A. Sjöström 1883): 3-storey Neo-Renaissance palace east of the Swedish Embassy, warm buff render with rusticated base, pilastered piano nobile and pitched metal roof to `20.0 m`, `clear_m: 18.0`, `secondary: true`, 6 parts, 10,280 tris, 3 `FLOOD_META` spots.
  - `runeberg_statue` (`landmark_fh_runeberg_statue.gd`, `60.16750, 24.94760`, Walter Runeberg 1885): red-granite stepped plinth and pedestal with bronze Suomen neito figure at the base and J. L. Runeberg statue to `8.0 m`, planted octagonal bed on Esplanadi, `clear_m: 8.0`, `secondary: true`, 5 parts, 4,104 tris, 4 `FLOOD_META` spots.
- **Upgraded H-1…H-4 models (all PBR-textured via `LandmarkMaterials.*` and studio-captured day & night in `visual-plan/captures/{hel_r2_upgrades,hel_r2_night}/`):**
  `kiasma` (curved zinc chiasma shell + Mannerheim equestrian statue, 26.0 m), `bank_of_finland` (rusticated central bay, pilastered end pavilions, Snellman monument, 21.0 m), `amos_rex`, `kamppi_chapel`, `lasipalatsi` (24.0 m clock/chimney + Bio Rex neon), `old_market_hall_helsinki` (polychrome diamond brick + traceried gable arches, 19.0 m), `market_square_helsinki` (granite sett apron around Keisarinnankivi, quay steps & cast-iron bollards), `havis_amanda`, `uspenski_cathedral` (slimmer octagonal brick drum `r = 5.6 m` to 50.0 m cross), `kappeli` (+ Espa Stage), `helsinki_ice_hall` (suspended catenary roof + concrete cable ribs), `linnanmaki` (Vuoristorata timber lattice + Taiga blue steel track + Rinkeli wheel + Kingi/Panoraama/Raketti), `suomenlinna_dry_dock` (stepped granite basin walls + caisson gates), `lonna_island` (1880s brick mine-storage warehouses + timber sauna), `kustaanmiekka_bastions` (granite star-fort trace, earth traversal ramparts, coastal casemates & iron guns), `hotel_kalastajatorppa` (curved functionalist white wing + 1975 seaside travertine annexe + rotunda), `kallio_library` (1912 red-brick Jugend massing, arched reading-room windows & copper turret), `lauttasaari_manor` (1837 Empire hipped manor to 13.5 m, matching `west_metro_coverage_test.gd`).
- **Night floodlighting:** `LandmarkLights.FLOOD_META` added across 19 previously unlit landmarks (`helsinki_cathedral`, `enso_gutzeit_hq`, `presidential_palace_helsinki`, `merikasarmi`, `katajanokka_terminal`, `katajanokka_casino`, `hotel_katajanokka`, `oodi`, `helsinki_music_centre`, `finlandia_hall`, `national_museum_finland`, `sederholm_house`, `helsinki_old_church`, `finnish_national_opera`, `sibelius_monument`, `kallio_church`, `redi`, `mall_of_tripla`, `aalto_house`).
- **`HelsinkiNotable` & far-ring districts:** `scripts/data/helsinki_notable.gd` expanded from 3 to 25 verified central Helsinki OSM buildings (`tests/helsinki_notable_test.gd` verifies all 25 against `helsinki_detailed.osmb` / `helsinki_ring1600.osmb` and `HostPolicy`); `"helsinki"` added to `CityStyles.FAR_DISTRICT_CITIES`.
- **Reference sets & in-world capture:** 16 Helsinki/regional folders in `visual-plan/refs/landmarks/` populated/topped up to ≥ 3 CC/PD Commons photos; Ultra rounds `visual-plan/reviews/hel-r10-2026-11-23/` (`--look_ahead=100`, 12 open-space eyes) and `hel-r10-winter-2026-11-23/` verified.
