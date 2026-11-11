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
the mall block, not surveyed totals. Suomenlinna components are separate
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
