# Helsinki landmark batch — 2026-11-03

Models use true metres and merged textured surfaces. They approximate the buildings' exterior envelopes and visible details; no model has been photographically rated. Non-survey dimensions below must not be presented as verified real-world dimensions.

| Type | Model envelope / details | Evidence |
| --- | --- | --- |
| `kamppi_chapel` | 11.5 m timber vessel, flaring elliptical walls, plank seams, low stone entrance | Owner: https://kampinkappeli.fi/en/index/architectureanddesign.html (height and spruce exterior). Envelope width/depth approximate. |
| `amos_rex` | Five asymmetric concrete light scoops with circular glazed oculi on Lasipalatsi square | Architect: https://jkmm.fi/work/amos-rex-museum/ . Heights and radii approximate. Registry point centres the outdoor square, not the historic museum's previous address. |
| `havis_amanda` | 5 m total, pink granite basin, bronze figure, four sea lions, pedestal fish | City: https://tpr.hel.fi/TPRalusta/notification/info/3229/ . Anatomy is procedural and approximate. |
| `kappeli` | Glazed verandas, green iron framework, polygonal pavilions, roof lantern | City: https://tpr.hel.fi/TPRalusta/notification/info/605/ ; conservation engineer: https://www.wsp.com/fi-fi/news/2022/ravintola-kappeli-peruskorjataan-historiaa-vaalien . Envelope approximate. |
| `skywheel_helsinki` | 40 m tall upright wheel, twin rims/spokes, thirty upright blue gondolas and A-frame | Owner: https://skywheel.fi/en/home/ ; city: https://www.hel.fi/static/public/hela/Kaupunkiymparistolautakunta/Suomi/Paatos/2017/Kymp_2017-09-26_Kylk_8_Pk/1F1E3B1D-6999-C416-8934-5EE5BE000001/Katajanokanlaituri_2n_poikkeamishakemus_%28Skywheel%29.html . Frame/rim dimensions approximate within published height. |
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
