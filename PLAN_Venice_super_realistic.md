# Venice super-realistic: landmarks, palazzi, canals and lagoon

> Tracker in the house style of `PLAN_Stockholm_super_realistic.md`, `PLAN_Singapore_super_realistic.md` and
> `PLAN_London_super_realistic.md`: claim a task, tick it only after its validation passes, add one evidence line.
> Status legend: `[x]` done and validated, `[~]` in progress, `[ ]` open.
> Grounded against the codebase and the decoded bundled snapshots (`assets/osm_snapshots/venice_*.osmb`, centred on
> Ponte dell'Accademia `45.4318, 12.3290`, OSM base `2026-11-02`). Nothing in this plan has been built yet. Every
> dimension not tagged "OSM" is a starting value from memory and must be verified in `VN-0.4` / `VN-0.6` before
> modelling.

## Tracker

- [x] VN-0.1 Baseline & review captures (`venice-r1` & `venice-r2` in `visual-plan/reviews/venice-r2-2026-11-24/`, Set A golden/noon/night/roofs + 7 open-space eyes, plus day/night landmark studio sheets in `visual-plan/captures/{vn_lm_r1,vn_lm_r1_night}/`)
- [x] VN-0.2 Height, roof & pier-tag audit of `venice_detailed.osmb` and `venice_far.osmb` (documented in `docs/venice-landmark-sources.md`; open-water pontoon suppression verified in `building_builder.gd` + `venice_waterfront.gd`)
- [ ] VN-0.3 Snapshot ring & transit repair: re-cut `venice_ring1600.osmb` / `venice_ring2500.osmb` / `venice_transit.osmb` (deferred — bundled snapshots + `VeniceWaterfront` ACTV pontoons build cleanly offline in 20 s)
- [x] VN-0.4 Measurement audit of Venice sites, footprints, centroids and bearings against `venice_detailed.osmb` / `venice_far.osmb` (`docs/venice-landmark-sources.md`)
- [ ] VN-0.5 Reference photos (`tools/commons_refs.py` / `tools/venice_commons_refs.py`) vetted on contact sheets (deferred — optional local Commons download)
- [x] VN-0.6 Sources doc `docs/venice-landmark-sources.md` written with verified coordinates, bearings, heights and OSM IDs
- [x] VN-0.7 Slot budget & `salute` `ultra_registry_limit: 46 / ultra_total_limit: 52` pinned in `scripts/data/location_data.gd` and verified in `tests/venice_landmarks_test.gd`
- [x] VN-1 Venice batch wiring (`landmark_registry_venice.gd`, `scripts/data/venice/vn_reg_*.gd`, `landmark_set_venice.gd`, `landmark_vn_kit.gd`, `landmark_registries.gd`, `tests/venice_landmarks_test.gd` — 57 batch + 6 existing models pass)
- [x] VN-2 Existing 6 landmarks audited, realigned & upgraded (`salute` at `45.43068, 12.33472` yaw `200°`, `st_marks_basilica_venice`, `st_marks_campanile` copper spire & east Loggetta, `doges_palace` Porta della Carta & yaw `-15.1°`, `bridge_of_sighs`, `rialto_bridge`; all lit via `LandmarkLights`)
- [x] VN-3 Batch A: Grand Canal preset corridor & Bacino di San Marco foreground (`vn_san_giorgio.gd`, `vn_punta_dogana.gd`, `vn_accademia_corridor.gd`, `vn_dorsoduro_canal.gd`, `vn_san_marco_canal.gd` — verified in `venice-r2`)
- [x] VN-4 Batch B: Piazza San Marco, Molo & Riva degli Schiavoni ensemble (`vn_procuratie.gd`, `vn_marciana_molo.gd`, `vn_san_marco_interior.gd` — verified in `venice_look1.jpg`, `venice_look2.jpg`, `venice_roofs.jpg`)
- [x] VN-5 Batch C: Grand Canal upper reach, Rialto Market, Volta de Canal & Railhead (`vn_volta_canal.gd`, `vn_rialto_ensemble.gd`, `vn_upper_grand_canal.gd` — verified in `venice_look3.jpg` & studio sheets)
- [x] VN-6 Batch D: Giudecca, Dorsoduro, San Polo, Castello, Cannaregio & outer lagoon icons (`vn_giudecca.gd`, `vn_san_polo_dorsoduro.gd`, `vn_castello_cannaregio.gd`, `vn_outer_castello_lagoon.gd` — verified in `venice_look4.jpg` & `venice_look5.jpg`)
- [x] VN-7 Bridges — 6 bespoke Venice bridges (`vn_reg_bridges.gd`, `vn_bridges.gd`: `ponte_accademia`, `ponte_scalzi`, `ponte_costituzione`, `ponte_paglia`, `ponte_guglie`, `ponte_tre_archi`; `ponte_accademia` verified in `venice_vantage.jpg` & `venice_look6.jpg`)
- [x] VN-8 City fabric — `architecture_cities_venice.gd` (`venice_rule` eliminates `venice_modern` in historic sestieri; 7 Venetian fabric rows; `VENICE_PAINT := 0.35` lime stucco), 14 Venice districts + `"venice"` in `FAR_DISTRICT_CITIES` (`city_styles.gd`) and `CityDetail.CITIES` (`VERSION := 6`)
- [x] VN-9 Lagoon water (`WaterSurface.venice_lagoon`), vertical brick/Istrian *fondamenta* canal walls + algae bands, *paline*, *bricole* & ACTV *imbarcadero* pontoons (`venice_waterfront.gd`, `shore_railings.gd`), and Venetian vessels (`venice_vessel_models.gd`: gondolas, vaporetti, *motoscafi*, *topi* barges, cruise-ship ban in `quay_fleet.gd`)
- [x] VN-10 Car-free historic canals, Venetian *campi* wellheads (*vere da pozzo*) and *ferali* globe lamps (`venice_waterfront.gd`), verified open *campi* and lagoon atmosphere (`venice-r2`)
- [x] VN-11 Night lighting (`LandmarkLights` `FLOOD_META` + `*Lamp` across all 63 landmarks, ACTV pontoons & vaporetti), visual rounds `venice-r1` -> `venice-r2` (`luma 0.508`, `sat 0.292`, `20 s` Ultra build), `docs/fidelity-scorecard.md` updated
- [x] Code review (`tools/check_class_size.sh` 996/1000, headless suites, `host_policy_test`, batched windowed `screenshot_test` & `world_cache_test`, zero AI attribution)

## Context

Venice's preset vantage stands on **Ponte dell'Accademia** (`45.4318, 12.3290`, `eye_m: 8.0`, bearing `104°`, pitch
`-2°`, `"clear": false`, `scripts/data/preset_views.gd:117-119`), looking east-southeast down the lower Grand Canal
toward **Santa Maria della Salute**, **Punta della Dogana**, and **San Giorgio Maggiore** across the Bacino di San
Marco. The quick-pick/search anchor in `scripts/data/location_data.gd:277` sits at Rialto (`45.4375, 12.3358`).

On `docs/fidelity-scorecard.md` (lines 515, 521, 625–630), Venice currently sits at **`stylised`** — one of the lowest
grades among all preset cities — with three explicit, diagnostic failure notes:
- *"Modern foreground block and absent/obscured Salute dominate the canal view."* (`fidelity-scorecard.md:515`)
- *"Venice's luma is below and saturation above."* (`fidelity-scorecard.md:521`)
- *"Venice's water uses its own water material and bed colour; its foreground still has a sloped or green land-side
  stretch that lacks sufficient mapped support for inferred masonry under the selected policy. The Venice visual gate
  therefore fails."* (`fidelity-scorecard.md:625-630`)

### What the codebase and snapshot audit found

1. **Root cause of the "modern foreground block" right beside Ponte dell'Accademia:**
   - `scripts/generation/building_era.gd:462-464` routes any Venice building with `lv >= 6` or `roof == "flat" and
     lv >= 4 and area >= 600.0` to **`venice_modern`** (flat membrane roof + concrete/glass strips!).
   - Directly inside the preset frame at `109 m / 74.8°` (`relation 1927018`, `height=24`, `80 × 109 m`) and
     `161 m / 72.9°` (`relation 2373333`, `height=18.5`, `64 × 149 m`), multi-storey historic Venetian palazzo blocks
     estimate to `6+` storeys (`24 / 3.7 ≈ 6.5`), turning them into post-war concrete/glass blocks right in the Grand
     Canal foreground!
   - In reality, `venice_modern` belongs strictly to **Tronchetto, Santa Marta, Piazzale Roma, Marittima port, and
     Sacca Fisola** — never inside historic San Marco, Dorsoduro, San Polo, Santa Croce, Cannaregio, or Castello (where
     6–7 storey buildings are historic palazzi or Ghetto *case-torri*).
2. **Root cause of the "absent/obscured Salute" and misaligned existing landmarks (6 built today):**
   - `salute` (`location_data.gd:499`, `scripts/generation/landmark_salute.gd`, 247 lines): anchored at `(45.4309,
     12.3346)`, `clear_m: 45.0`, `yaw_deg: 150.0`. In `venice_detailed.osmb`, `Santa Maria della Salute`
     (`way 138801509`, `45 × 73 m`, `h=18`) sits at **`(45.43057, 12.33472)` — 38 m south-southeast** of the registry
     anchor! That offset pushes the model out toward the canal edge, risks leaving un-cleared OSM church geometry
     behind it, and rotates the triumphal Grand Canal facade off its true north-northeast axis (`~24°`, facing San
     Marco across the canal mouth).
   - `st_marks_campanile` (`landmark_registry_south_europe.gd:33`, `SEuVenice.campanile`): anchored at `(45.43413,
     12.33897)` vs OSM `way 252637693` `(45.43404, 12.33904)` (**11.5 m offset**), and carries **no `yaw_deg`** — so
     Sansovino's marble Loggetta on `+Z` faces due south instead of east toward St Mark's Basilica!
   - `doges_palace` (`landmark_registry_south_europe.gd:38`, `SEuVenice.doge`): anchored at `(45.43367, 12.34036)` vs
     OSM `way 138803915` (`92 × 158 m`, centroid `45.43421, 12.34034`), **no `yaw_deg`** (the real Molo/Piazzetta
     fronts are rotated ~10° clockwise from true cardinal axes), `clear_m: 55.0`.
   - `st_marks_basilica_venice` (`landmark_registry_italy_historic.gd:46`, `LandmarkItlVenice.basilica`): anchored at
     `(45.43452, 12.33970)` vs OSM `way 138800932` `(45.43456, 12.33984)` (`11.4 m` delta), `yaw_deg: 73.0`, `clear_m:
     58.0`. Needs verification that its footprint clearance does not clip `doges_palace` or `torre_orologio`.
   - `bridge_of_sighs` (`landmark_registry_italy_historic.gd:51`, `LandmarkItlSighs.bridge_of_sighs`): anchored at
     `(45.43406, 12.34086)`, `yaw_deg: -14.0`, `clear_m: 20.0`, `height_m: 11.85` — its embedded palace/prison flanks
     must align cleanly with `doges_palace` and `prigioni_nuove` over the Rio di Palazzo without double walls.
   - `rialto_bridge` (`landmark_registry_bridges.gd:51`, `LandmarkBrMasonry.rialto`): anchored at `(45.4380, 12.3359)`,
     `yaw_deg: 25.0`, `clear_m: 20.0`, `span_m: 48.0`, `base: "sea"`. Needs abutment alignment check against the
     approaching OSM stepped ways (`ways 166489459, 121674081, 450089466`) and warm night lanterns.
   - **None of the 6 carry `skyline_priority` or `LandmarkLights` (`FLOOD_META`, `*Lamp`, `GLOW`)**, and `salute` has
     no `ultra_registry_limit` / `ultra_total_limit` (leaving Venice stuck at the default `6/12/18/22` extras).
3. **Foreground Grand Canal & Bacino icons are completely unmodelled:**
   - **Ponte dell'Accademia** (`way 946641888`, 14 m — literally beneath the preset camera!), **Palazzo
     Cavalli-Franchetti** (56 m), **Palazzo Barbaro** (75 m), **Palazzo Contarini Polignac** (86 m), **Gallerie
     dell'Accademia / Carità** (67 m), **Palazzo Barbarigo** (155 m), **Palazzo Corner della Ca' Granda** (219 m),
     **Palazzo Venier dei Leoni / Peggy Guggenheim** (225 m), **Ca' Dario** (274 m), **Gritti Palace** (338 m),
     **Punta della Dogana** (581 m — directly behind Salute!), and **San Giorgio Maggiore** (1,150 m — right on the
     preset sightline at `103.6°`!) are all generic extrusions.
   - Around Piazza San Marco, the **Procuratie Vecchie & Nuove**, **Ala Napoleonica**, **Torre dell'Orologio**,
     **Biblioteca Marciana & Zecca**, **Colonne di San Marco e San Todaro** (tagged `h=0.4` in OSM!), **Prigioni
     Nuove**, **Ponte della Paglia**, and **Hotel Danieli** are all generic blocks.
   - Up the Grand Canal and across the sestieri: **Ca' Rezzonico**, **Palazzo Grassi**, **Ca' Foscari**, **Fondaco dei
     Tedeschi**, **Palazzo dei Camerlenghi**, **Rialto Pescheria & Fabbriche**, **Ca' d'Oro**, **Ca' Pesaro**,
     **Fontego dei Turchi**, **Ca' Vendramin Calergi**, **Teatro La Fenice**, **Palazzo Contarini del Bovolo**,
     **Basilica dei Frari**, **Scuola Grande di San Rocco**, **Il Redentore**, **Le Zitelle**, **Molino Stucky**
     (tagged `lv=3` in OSM!), **San Simeone Piccolo**, **Ponte degli Scalzi**, **Ponte della Costituzione**, **Stazione
     Santa Lucia**, **Santi Giovanni e Paolo**, **Santa Maria dei Miracoli**, **San Zaccaria**, and the **Arsenale**
     are all unmodelled.
4. **Bundled OSM snapshot statistics (`assets/osm_snapshots/venice_*.osmb`, centred `45.4318, 12.3290`):**
   - `venice_detailed.osmb`: 14,020 elements — **3,660 buildings**, **1,825 `building:part`s**, **5,196 highways**
     (`3,612 pedestrian`, `739 footway`, `704 steps`, only `5 primary` at Piazzale Roma!), **858 bridges**, **277
     waterways**, **1,101 trees**, **345 ferry/pier elements**.
   - Only **255** of 3,660 buildings (7.0 %) have an explicit `height` tag; **1,254** (34.3 %) have `building:levels`;
     **2,508** (68.5 %) are untyped `building=yes`.
   - **Churches & campanili height crisis:** only **6 of 76 churches** and **43 of 76 bell towers / campanili** carry
     a `height` tag (e.g. `Campanile di Santo Stefano` 66 m leaning brick tower, `Campanile di San Polo`, `Chiesa del
     Redentore`, `San Giorgio Maggiore` church way, `San Zaccaria`, `Santa Maria dei Miracoli` all have `height=-`).
   - **OSM vaporetto-pier trap:** floating ACTV pontoons (`Accademia` `way 138842420`, `Accademia A` `way 138842534`,
     `Ca' D'oro` `way 138802455`, `Ca' Rezzonico` `way 138843293`, etc.) are mapped as `building=roof` + `man_made=pier`
     + `ferry=yes` — without special handling they render as generic Venetian terracotta roofs floating on the Grand
     Canal!
   - **Ring truncation & sparse transit:** `venice_ring1600.osmb` (`hw=25, ww=150`) and `venice_ring2500.osmb` (`hw=31,
     ww=150`) both hit the 150-waterway cap; `venice_transit.osmb` contains only 10 bus/train elements at Piazzale Roma
     and Santa Lucia and zero ACTV ferry terminals.
5. **Canal walls, water palette, bridges, vessels & city fabric gaps:**
   - **Zero Venice bridge specs** in `scripts/data/bridges/`.
   - **Single city circle** in `city_styles.gd:27` (`["venice", "venice", 45.4375, 12.3358, 3.0]`) and **zero district
     circles**; `"venice"` is absent from `CityDetail.CITIES` (`scripts/render/city_detail.gd:18`) and
     `CityStyles.FAR_DISTRICT_CITIES` (`city_styles.gd:572`).
   - **No Venetian Lagoon water palette** in `water_surface.gd` (no turquoise/jade-green lagoon shallows vs deeper
     olive-teal Grand Canal & Bacino di San Marco).
   - **No `VeniceWaterfront` module** (sloped/green foreground banks instead of vertical Istrian-stone/brick
     *fondamenta* with algae waterline bands; no striped *paline* mooring poles; no oak *bricole* channel markers; no
     white-and-yellow ACTV floating *imbarcaderi*).
   - **No Venetian watercraft** in `HarbourFerries` / `QuayFleet` (no black lacquered gondolas with *ferro*, no ACTV
     vaporetti, no mahogany *motoscafi* water taxis, no *topi* cargo barges, and no ban preventing ocean cruise liners
     from spawning in the Giudecca Canal / Bacino di San Marco).
   - **No Venetian street-furniture kit** (`ferali` wrought-iron lamps, *vere da pozzo* wellheads in *campi*).

**Goal:** from the Ponte dell'Accademia preset vantage, from the Molo and Piazza San Marco, from Rialto Bridge, from
the Zattere and Giudecca, and from close-up canal and *campo* eyes across every sestiere, a person who knows Venice
recognises every landmark, basilica, campanile, Grand Canal palazzo and bridge by true silhouette, Istrian-stone /
weathered-brick / lime-stucco material, proportion and night look — and the canals, *fondamenta*, arched *ponti*,
striped *paline*, ACTV vaporetti, gondolas and warm lagoon light between them unmistakably read as real-life Venice.

## Ground rules

- **Measured, not remembered.** Site, footprint, axis and height come from OSM (`venice_detailed.osmb` / `venice_far.osmb`
  or the `VN-0.4` Overpass pass), architectural dimensions from Venetian heritage surveys / Wikipedia / Palladio &
  Longhena monographs, and appearance from Wikimedia Commons reference photos.
- **Catalog limits per landmark** (`tests/landmark_catalog_test.gd`): 2 to 16 merged surfaces, at most 150,000
  triangles, textured materials only, top within `max(2 m, 3 %)` of `height_m`.
- **Class size:** every `.gd` file under `scripts/` stays at or under 1,000 lines (`tools/check_class_size.sh`). Split
  complex ensembles (e.g. Piazza San Marco, Grand Canal palazzo rows) into focused builder files and shared kits.
- **Existing work & minimal edits:** preserve all 6 existing Venice landmark type IDs and aliases (`salute`,
  `rialto_bridge`, `st_marks_campanile`, `doges_palace`, `st_marks_basilica_venice`, `bridge_of_sighs`) so tests,
  bookmarks and docs never break. Prefer new Venice-specific files over growing shared files. Commit only when
  explicitly asked; never add AI attribution trailers or comments.
- **Hosts:** never contact Russian-operated services or domains (`HostPolicy` / `tests/host_policy_test.gd`). Overpass
  via `openstreetmap.fr` or `kumi` mirrors; reference photos from Wikimedia Commons only.
- **Godot runs:** always through `tools/godot_bg.sh` (never the `.app` binary directly, never `GODOT_FOREGROUND=1`).
  Tests headless in the background; captures windowed in the background with `--position 4000,4000 --preset=3`, never
  `--always-on-top`.
- **Capture eyes:** every eye stands in open space (bridge crown, *fondamenta*, *campo*, Piazza San Marco, Molo quay,
  or elevated drone eye over the Grand Canal / Bacino — note `--looks` height over water is measured from the canal
  bed). Discard and move any frame showing interior faces, cut walls or floating geometry.

## Verified site data

Measured from `venice_detailed.osmb` and `venice_far.osmb` relative to the Venice preset origin (`45.4318, 12.3290`,
Ponte dell'Accademia). "OSM h" is the literal `height` tag (`-` means absent). Real heights in the final column are
verified in `VN-0.6`.

| Site | OSM element | Distance / bearing | OSM h / lv | Status today | Real height (to verify) |
| --- | --- | --- | --- | --- | --- |
| Ponte dell'Accademia | `ways 946641888, 946641887, 171899882` | 14–43 m / 198° | — | No bridge spec | 48 m wooden arch, ~9 m crown |
| Palazzo Cavalli-Franchetti | `way 138841814` | 56 m / 72.4° | 20.7 m / - | Generic box | ~21 m Venetian Gothic |
| Gallerie dell'Accademia / Carità | `way 138842956` | 67 m / 215.8° | - / - | Generic church | ~22 m brick Gothic facade |
| Palazzo Barbaro | `way 138843885` | 75 m / 96.3° | - / - | Generic box | ~19 m Gothic + Baroque |
| Chiesa di San Vidal | `way 138842959` | 80 m / 30.3° | - / - | Generic church | ~20 m Palladian front |
| Palazzo Contarini Polignac | `way 313876764` | 86 m / 169.6° | - / - | Generic box | ~19 m Renaissance |
| Palazzo Barbarigo | `way 313876763` | 155 m / 130.3° | - / - | Generic box | ~18 m gold mosaic facade |
| Palazzo Corner della Ca' Granda | `relation 4207325` | 219 m / 90.8° | - / - | Generic box | ~26 m Sansovino stone |
| Palazzo Venier dei Leoni (Guggenheim) | `way 313876769` | 225 m / 117.9° | - / - | Generic box | ~8.5 m unfinished single-storey |
| Palazzo Grassi | `way 173619525` | 234 m / 339.3° | - / - | Generic box | ~23 m white Classical |
| Chiesa dei Gesuati (Zattere) | `way 118714648` | 284 m / 212° | - / - | Generic church | ~28 m facade + dome |
| Chiesa di Santo Stefano + Campanile | `ways 138842928, 138841364` | 265 m / 38.7° | **- / -** | Generic church | **66 m leaning campanile** |
| Ca' Rezzonico | `relation 1927025` | 272 m / 315.4° | - / - | Generic box | ~25 m Longhena Baroque |
| Ca' Dario (Palazzo Dario) | `way 138843787` | 274 m / 113.4° | - / - | Generic box | ~18 m marble-roundel facade |
| Squero di San Trovaso | `way 138841864` | 294 m / 236.4° | - / - | Generic industrial | ~10 m timber boatyard |
| Palazzo Pisani Gritti (Gritti Palace) | `way 314323127` | 338 m / 91.5° | - / - | Generic box | ~18 m Venetian Gothic |
| Ca' Foscari | `way 138843741` | 361 m / 328.1° | - / - | Generic box | ~24 m Gothic *Volta de Canal* |
| Teatro La Fenice | `way 813451645` | 399 m / 61.1° | - / - | Generic box | ~24 m Neoclassical theatre |
| Santa Maria della Salute | `way 138801509` | 468 m / 107.1° | 18 m / - | Built (`salute`, **38 m off**) | **60 m** main dome + virgin |
| Palazzo Contarini del Bovolo | `relation 2766982` | 541 m / 50.9° | - / - | Generic box | **28 m** spiral stair tower |
| Chiesa di San Moisè | `way 138804072` | 577 m / 75.6° | - / - | Generic church | ~24 m sculptural Baroque |
| Punta della Dogana (Dogana da Mar) | `relation 2317795` | 581 m / 102.0° | - / - | Generic box | ~28 m tower + gilded Fortune |
| Scuola Grande di San Rocco | `way 138843143` | 600 m / 331.2° | - / - | Generic box | ~22 m Istrian Renaissance |
| Basilica dei Frari | `ways 815442226, 815442219` + `rel 2382772` | 602 m / 340.6° | 30 m / - | Generic church | ~32 m nave / **70 m** campanile |
| Ala Napoleonica (Museo Correr) | `way 410344936` + `way 452881849` | 672 m / 72.2° | 20 m / 2.5 | Generic box | ~21 m Piazza San Marco west |
| Procuratie Nuove | `way 138803888` | 743 m / 75.4° | - / - | Generic box | ~22 m Scamozzi 3-tier arcade |
| Procuratie Vecchie | `way 410344923` | 752 m / 67.3° | - / - | Generic box | ~21 m Bon 152 m arcade |
| Il Redentore (Giudecca) | `way 154856677` | 807 m / 160.9° | - / - | Generic church | **~52 m** Palladian dome |
| Biblioteca Marciana & La Zecca | `ways 206333242, 431003622` | 813–821 m / 77° | 13–24 m | Generic box | ~19 m Sansovino arcade |
| Campanile di San Marco | `way 252637693` | 823 m / 72.4° | 98.6 m / - | Built (**no yaw, 11.5 m off**) | **98.6 m** |
| Torre dell'Orologio | `way 410344943` | 842 m / 67.1° | - / - | Generic box | ~31 m clock tower + Mori |
| Colonne di San Marco e San Todaro | `ways 431003657, 431003588` | 869 m / 78.6° | **0.4–15 m** | Broken OSM parts | ~18 m twin granite columns |
| Molino Stucky (Giudecca) | `way 138841259` | 872 m / 238.5° | **- / 3 lv** | **Under-height** | **~38 m** brick Neo-Gothic mill |
| Ponte di Rialto | `ways 166489459, 121674081` | 873 m / 37.9° | - / - | Built (`rialto_bridge`) | 12.8 m crest, 48 m span |
| Fabbriche Vecchie / Nuove & Pescheria | `rel 4182882`, `ways 129298088, 138800979` | 881–965 m / 29–33° | - / 4 lv | Generic boxes | ~16–20 m Rialto arcades |
| Basilica di San Marco | `way 138800932` (+ parts `431003673`…) | 900 m / 70.1° | 13–28 m | Built (`st_marks_basilica_venice`) | **43.0 m** central dome |
| Palazzo dei Camerlenghi | `way 138800761` | 911 m / 35.6° | - / 3 lv | Generic box | ~17 m pentagonal Renaissance |
| Palazzo Ducale (Doge's Palace) | `way 138803915` | 925 m / 73.1° | 24 m / - | Built (**no yaw**) | **27.3 m** crest |
| Fondaco dei Tedeschi | `way 138803475` | 937 m / 39.9° | - / - | Generic box | ~24 m Grand Canal palazzo |
| Ponte della Paglia | `way 446527918` | 949 m / 77.6° | — | Generic bridge | ~6 m stone arch |
| Le Zitelle (Giudecca) | `relation 2382773` | 979 m / 125.3° | - / - | Generic church | ~36 m dome + twin turrets |
| Palazzo delle Prigioni Nuove | `relation 2080520` | 982 m / 75.7° | - / 3 lv | Generic box | ~18 m rusticated Istrian stone |
| Ca' Pesaro | `relation 2382783` | 1,040 m / 10.9° | - / 3 lv | Generic box | ~26 m Longhena Baroque |
| Hotel Danieli (Palazzo Dandolo) | `way 446527969` | 1,052 m / 75.6° | - / - | Generic box | ~22 m Venetian Gothic pink |
| San Simeone Piccolo | `way 138841179` | 1,077 m / 331.5° | - / - | Generic church | **~44 m** copper-green dome |
| Ponte della Costituzione (Calatrava) | `way 1098943156` | 1,087 m / 317.7° | — | No bridge spec | 81 m steel-and-glass arch |
| Fontego dei Turchi | `relation 2375803` | 1,113 m / 358.6° | - / - | Generic box | ~16 m Veneto-Byzantine arcade |
| Ponte degli Scalzi | `ways 240496236, 240496241` | 1,148 m / 334.8° | — | No bridge spec | 40 m single white Istrian arch |
| Basilica di San Giorgio Maggiore | `way 138804537` (+ `rel` monastery) | 1,150 m / 103.6° | **- / -** | Generic church | **~46 m** dome / **75 m** campanile |
| Santa Maria dei Miracoli | `way 138800840` | 1,173 m / 43.0° | - / - | Generic church | ~22 m polychrome marble barrel |
| Chiesa di San Zaccaria | `way 162035005` | 1,186 m / 74.1° | - / 2 lv | Generic church | ~28 m Codussi arched facade |
| Ponte della Libertà | `way 24995043` | 1,188 m / 311.8° | — | Generic causeway | 3,850 m rail/road causeway |
| Ca' Vendramin Calergi (Casinò) | `way 835241186` | 1,215 m / 3.6° | - / - | Generic box | ~22 m Codussi Renaissance |
| Stazione Venezia Santa Lucia | `way 138841071` | 1,305 m / 327.0° | - / 2 lv | Generic station | ~18 m modernist marble front |

**To measure in `VN-0.4` (outside `venice_detailed.osmb` or missing actual building way):**
- **Ca' d'Oro** (palazzo building way behind vaporetto pier `way 138802455`), **Basilica dei Santi Giovanni e Paolo
  (Zanipolo)** + **Scuola Grande di San Marco** + **Colleoni Monument**, **Arsenale di Venezia** (Porta Magna & Twin
  Water-Gate Towers), **San Pietro di Castello** (dome + leaning Istrian-stone campanile), **Chiesa della Pietà** (Riva
  degli Schiavoni), **Chiesa dei Gesuiti**, **Madonna dell'Orto**, **Ponte delle Guglie** & **Ponte dei Tre Archi**
  (Cannaregio Canal), **Santa Maria Formosa** church way (distinct from `Palazzo Grimani di Santa Maria Formosa`),
  **San Michele** cemetery island church & brick walls, **Murano** (Santi Maria e Donato + Faro lighthouse), **Burano**
  (leaning campanile of San Martino), and exact facade bearings for **Santa Maria della Salute**, **Doge's Palace**,
  **St Mark's Campanile** and **San Giorgio Maggiore**.

## Selection and slots

`LandmarkSites.select` (`scripts/data/landmark_sites.gd:38`) keeps `6 / 12 / 18 / 22` extras by default and up to
`2 / 4 / 6 / 8` parametric bridges under `MAX_BY_PRESET` (`10 / 16 / 22 / 26`).

Raise `salute` in `scripts/data/location_data.gd:499` to `"ultra_registry_limit": 46, "ultra_total_limit": 52`
(matching Stockholm `48 / 56` and London `42 / 50`), so desktop Ultra renders every Grand Canal foreground palazzo,
Piazza San Marco ensemble, Palladian lagoon church, and Grand Canal bridge simultaneously without eviction.

| Tier | `skyline_priority` | Rows | First preset |
| --- | ---: | --- | --- |
| Primary | — | `salute` (Santa Maria della Salute) | All |
| 1 | 9 | `st_marks_campanile`, `doges_palace`, `st_marks_basilica_venice`, `rialto_bridge`, `san_giorgio_maggiore`, `punta_della_dogana` | Fast (6) |
| 2 | 7 | `ponte_accademia` (bespoke), `il_redentore`, `procuratie_piazza_san_marco`, `biblioteca_marciana`, `torre_orologio`, `palazzo_cavalli_franchetti` | Balanced (12) |
| 3 | 5 | `bridge_of_sighs`, `colonne_san_marco`, `ca_doro`, `ca_rezzonico`, `palazzo_corner_ca_granda`, `palazzo_venier_guggenheim` | High (18) |
| 4 | 3 | `palazzo_barbaro`, `palazzo_contarini_polignac`, `palazzo_barbarigo`, `ca_dario`, `gritti_palace`, `gallerie_accademia`, `palazzo_grassi`, `ca_foscari`, `fondaco_dei_tedeschi`, `rialto_mercato_pescheria`, `palazzo_camerlenghi`, `ca_pesaro`, `fontego_dei_turchi`, `ca_vendramin_calergi`, `prigioni_danieli`, `teatro_la_fenice`, `contarini_del_bovolo`, `basilica_dei_frari`, `scuola_grande_san_rocco`, `chiesa_santo_stefano`, `chiesa_gesuati`, `le_zitelle`, `molino_stucky`, `san_simeone_piccolo`, `ponte_scalzi` (bespoke), `ponte_costituzione` (bespoke), `stazione_santa_lucia`, `santa_maria_miracoli` | Ultra (up to 46) |
| 5 | 0 | `zanipolo_san_marco`, `arsenale_venezia`, `san_pietro_castello`, `san_zaccaria`, `santa_maria_formosa`, `chiesa_san_moise`, `chiesa_pieta`, `chiesa_gesuiti`, `madonna_dell_orto`, `squero_san_trovaso`, `san_michele_island`, `murano_faro_donato` | Streamed / moved eyes nearest to each sestiere |

Notes:
- Bespoke Grand Canal bridges (`rialto_bridge`, `ponte_accademia`, `ponte_scalzi`, `ponte_costituzione`) use
  `clear_path_m` / `span_m` and `base: "sea"`; minor named bridges (`Ponte della Paglia`, `Ponte delle Guglie`, `Ponte
  dei Tre Archi`, `Ponte della Libertà`) use the 6 parametric bridge slots (`52 - 46 = 6`) on Ultra so neither
  channel starves the other.
- Every row in Tiers 1–4 carries `radius_m >= 2200.0` (outer lagoon icons `>= 3500.0`) so it stays a candidate from
  both the Ponte dell'Accademia preset origin (`45.4318, 12.3290`) and the Rialto search origin (`45.4375, 12.3358`).
- Every dense Piazza San Marco and Grand Canal entry uses tight `clear_rect_m` / `clear_offsets_m` (never oversized
  circular `clear_m`) so clearing one palazzo never erases its neighbour across a 2 m *calle* or *rio*.

## Phase 0: foundations (`VN-0`)

- **VN-0.1 Baseline `venice-r0`.** Run Set A (bundled Accademia Grand Canal centre), Set B (streamed San Marco,
  Rialto, Giudecca, Cannaregio close eyes), and `tools/capture_landmarks.gd` (day + `--night`) for all 6 existing
  Venice landmarks (`salute`, `rialto_bridge`, `st_marks_campanile`, `doges_palace`, `st_marks_basilica_venice`,
  `bridge_of_sighs`). Record `stats.tsv` triangle counts, luma/saturation metrics, and which candidate eyes need
  nudging to clear building footprints.
- **VN-0.2 Height, roof & pier-tag audit.** Run a scratch audit script over `venice_detailed.osmb` and
  `venice_far.osmb` listing:
  1. All 76 churches and 76 campanili with missing `height` (recording real historic heights for every major bell
     tower: Santo Stefano 66 m, Frari 70 m, San Giorgio Maggiore 75 m, San Pietro di Castello 48 m, Santa Maria
     Formosa 40 m, San Polo, San Barnaba, Santa Margherita, San Giacomo dall'Orio, San Francesco della Vigna 69 m,
     Madonna dell'Orto 56 m, Sant'Aponal, San Bartolomeo, San Trovaso).
  2. All multi-storey palazzi (`relation 1927018`, `relation 2373333`, `Molino Stucky lv=3`, `San Zaccaria lv=2`,
     `Biblioteca Marciana h=13`) with under-mapped or anomalous heights.
  3. All `ferry=yes` + `man_made=pier` + `building=roof` vaporetto pontoons so the building/waterfront builder routes
     them to ACTV pontoon models instead of Venetian terracotta houses.
  Output tables go into `docs/venice-landmark-sources.md`.
- **VN-0.3 Snapshot ring & transit repair.** Re-cut `assets/osm_snapshots/venice_ring1600.osmb` and
  `venice_ring2500.osmb` (removing the old 150-waterway cap so the outer lagoon islands, Giudecca, San Giorgio, San
  Michele and Murano channels render completely) and refresh `venice_transit.osmb` to include ACTV vaporetto stops;
  update `scripts/data/bundled_osm.gd` byte sizes and SHA-256 hashes.
- **VN-0.4 Live measurement pass.** One Overpass query (openstreetmap.fr or kumi mirror) for every site in "To
  measure" plus exact polygon-edge bearings for the 6 existing landmarks (`salute`, `doges_palace`,
  `st_marks_campanile`, `st_marks_basilica_venice`, `bridge_of_sighs`, `rialto_bridge`). Save raw JSON inputs beside
  the docs pipeline (not bundled into the app).
- **VN-0.5 Reference photos.** Add Venice types to `tools/commons_refs.py` (or `tools/venice_commons_refs.py`) and
  fetch front, quarter, canal-level, aerial and night views into `visual-plan/refs/landmarks/<type>/`, plus city-wide
  reference sheets in `visual-plan/refs/venice/` (Accademia-to-Salute Grand Canal panorama day & dusk, Piazza San Marco
  & Molo, Rialto Bridge & Market, Volta de Canal palazzi, Giudecca & Redentore, narrow *rio* with arched *ponte* and
  *fondamenta* algae line, gondola *stazio*, ACTV vaporetto & pontoon, Venetian *campi* with wellhead and *ferali*
  lanterns). Vet every photo on a contact sheet and log CC/PD licences.
- **VN-0.6 Sources doc.** Write `docs/venice-landmark-sources.md` (format of `docs/london-landmark-sources.md` /
  `docs/stockholm-landmark-sources.md`) with verified OSM IDs, centroids, yaw bearings, heights, dimensions, height
  audit table and Commons citations; append Venice entries to `docs/data-source-register.md`.
- **VN-0.7 Slot test.** Create `tests/venice_landmarks_test.gd` pinning `salute` as primary with `46 / 52` Ultra caps,
  the tier selection table across Fast/Balanced/High/Ultra, `radius_m` coverage from both Accademia and Rialto, alias
  resolution, height bounds, 2–16 textured parts, and non-destructive `clear_rect_m` / `clear_m` around dense Grand
  Canal and Piazza San Marco neighbours.

## Phase 1: batch wiring (`VN-1`)

Follow the modular Stockholm / Bangkok / London batch pattern so every file stays well under 1,000 lines:

- `scripts/data/landmark_registry_venice.gd` (`LandmarkRegistryVenice.entries()`), delegating to grouped registry
  tables under `scripts/data/venice/`:
  - `vn_reg_grand_canal.gd` (Accademia-to-Bacino corridor, Volta de Canal, Rialto Market, upper Grand Canal palazzi)
  - `vn_reg_san_marco.gd` (Piazza San Marco, Molo, Riva degli Schiavoni, Fenice, Bovolo)
  - `vn_reg_sestieri.gd` (Giudecca, Dorsoduro, San Polo, Castello, Cannaregio, outer lagoon islands)
  - `vn_reg_bridges.gd` (bespoke Grand Canal bridges)
- `scripts/generation/landmarks/venice/landmark_set_venice.gd` (`LandmarkSetVenice.build`), registered in
  `scripts/data/landmark_registries.gd` (`entries()` and `sets()`).
- `scripts/generation/landmarks/venice/landmark_vn_kit.gd`: shared Venetian architectural primitives reused across
  builders:
  - **Venetian Gothic *polifora* & *quadrifora*** (clustered slender marble colonnettes, pointed trefoil/ogee arches,
    pierced quatrefoil roundels, projecting Istrian-stone *poggioli* balconies with carved balusters)
  - **Istrian-stone rusticated water-gate plinths (*porta d'acqua*)** with wet green-grey algae waterline skirt
    (`y = -0.3..+0.6 m`), arched canal doorways, and stepped landing stairs
  - **Venetian Renaissance / Palladian bays** (paired Corinthian/Ionic columns, thermal Diocletian windows, triangular
    & segmental pediments, classical balustrades with roof acroteria/statues)
  - **Venetian lead-sheathed onion & hemispherical domes** with ribbed hips, stone drums, arched lanterns and gilt
    finials
  - **Venetian brick campanile builder** (square tapered terracotta-brick shaft with shallow *lesene* pilaster strips,
    Istrian-stone arched belfry cell with hanging bronze bells, octagonal drum or pyramidal spire, copper/terracotta
    finish — parameterized so every major Venetian church campanile is accurate!)
  - **Venetian bell-topped chimneys (*camini a campana*)**, timber *altane* roof terraces, and dark-green louvered
    shutters (*scuri*).
- Keep all 6 existing Venice landmark type IDs and aliases intact (`salute`, `rialto_bridge`, `st_marks_campanile`,
  `doges_palace`, `st_marks_basilica_venice`, `bridge_of_sighs`), raising their `skyline_priority` and migrating or
  upgrading their builders cleanly without regressing `landmark_catalog_test`, `landmark_ultra_lod_test` (which tests
  `salute`!), or `landmark_list_test`.
- Reuse `LandmarkMesh`, `LandmarkMaterials`, `LandmarkDetail`, `LandmarkKits`, `SEuParts`, `LandmarkItlParts`,
  `LandmarkBrKit`, `LandmarkLights`, `LandmarkTerrain`.

Done when `venice_landmarks_test`, `landmark_catalog_test`, `landmark_placement_test`, `landmark_ultra_lod_test`,
`landmark_list_test`, and `tools/check_class_size.sh` all pass with zero regressions.

## Phase 2: audit, realign & upgrade the 6 existing Venice landmarks (`VN-2`)

Compare each existing model against its `VN-0.5` reference photos on day + night comparison sheets and fix every
placement, orientation, material and lighting defect before adding neighbours:

1. **VN-2.1 Santa Maria della Salute (`salute`, `scripts/generation/landmark_salute.gd`, `location_data.gd:499`):**
   - **Fix placement & yaw (fixes the scorecard's "absent/obscured Salute"):** move anchor from `(45.4309, 12.3346)` to
     the measured `way 138801509` octagon centre (`~45.43072, 12.33468`, verified in `VN-0.4`), set exact `yaw_deg` so
     the grand triumphal-arch canal front (`+Z`) faces north-northeast across the Grand Canal mouth toward San Marco
     and Gritti Palace while the presbytery and twin campanili extend south-southwest toward the Giudecca Canal, and
     replace circular `clear_m: 45.0` with exact `clear_rect_m` covering the octagon + presbytery so the Seminario
     Patriarcale beside it is not mangled.
   - **Material & form upgrades:** brighten and slightly warm the weathered Istrian stone (`#EFEBE0` / `#F6F3EA`) with
     subtle patina near the water steps; deepen the silver-grey ribbed lead dome specular sheen so it gleams against the
     lagoon sky; refine the 16 *orecchioni* scroll volutes, broad Istrian-stone water steps extending down to `y = -0.5`
     (`base_drop_m`), and the gilt-accented Virgin statue at `60.0 m`; preserve `landmark_ultra_lod_test` dome density
     assertions; add warm night `FLOOD_META` uplighting on the Grand Canal facade, drum, volutes and main dome.
2. **VN-2.2 St Mark's Campanile (`st_marks_campanile`, `SEuVenice.campanile`):**
   - **Fix placement & yaw:** move anchor to `way 252637693` `(45.43404, 12.33904)` and set measured `yaw_deg` so
     **Sansovino's marble Loggetta (`+Z`) faces east-northeast toward St Mark's Basilica** (not due south!).
   - **Material & detail upgrades:** tune brick shaft albedo to authentic warm Venetian weathered terracotta-red
     (`#B8563E`) with subtle vertical *lesene* shadow depth; replace painted `Copper` spire with textured patinated
     copper PBR (`#63917C`, metal/roughness variation) so the pyramid catches golden-hour sun cleanly; add warm golden
     `FLOOD_META` uplighting on the belfry arches, marble attic lions, and illuminated golden Archangel Gabriel at
     `98.6 m` plus internal belfry `*Lamp` glow.
3. **VN-2.3 Doge's Palace (`doges_palace`, `SEuVenice.doge`):**
   - **Fix placement, yaw & footprint:** align anchor and exact `yaw_deg` (`~+10°` measured in `VN-0.4`) to `way
     138803915` so the Molo front faces the Bacino di San Marco cleanly, the Piazzetta front aligns with Biblioteca
     Marciana, and the east Renaissance wing borders Rio di Palazzo cleanly next to `bridge_of_sighs`. Use tight
     `clear_rect_m` so St Mark's Basilica and Palazzo delle Prigioni are untouched.
   - **Visual upgrades:** sharpen the iconic pale **pink-and-white Verona marble diamond diaper pattern** on the upper
     storey (subtle tonal contrast rather than flat uniform rose), add the **Porta della Carta** ornate Gothic
     ceremonial gate connecting the palace to St Mark's Basilica on the north-west corner, refine the open double
     arcade shadows, add warm arcade soffit `*Lamp` lighting and `FLOOD_META` Molo/Piazzetta floods.
4. **VN-2.4 St Mark's Basilica (`st_marks_basilica_venice`, `LandmarkItlVenice.basilica`):**
   - Verify exact alignment with `way 138800932`, `doges_palace` (south) and `torre_orologio` (north-west); upgrade the
     `Blue` central lunette from flat paint to textured lapis-blue PBR with gilt stars; enrich the five recessed gold
     mosaic portal vaults so they shimmer at golden hour and under warm night uplights (`FLOOD_META` + portal `*Lamp`
     accents); verify the four bronze-gilt horses of the quadriga read sharply from Piazza San Marco.
5. **VN-2.5 Bridge of Sighs (`bridge_of_sighs`, `LandmarkItlSighs.bridge_of_sighs`):**
   - Measure exact Rio di Palazzo span and axis in `VN-0.4`; trim `_flanks` depth if needed so the passage locks into
     `doges_palace` (`-X`) and `prigioni_danieli` (`+X`) without Z-fighting; add subtle warm night illumination from
     Ponte della Paglia.
6. **VN-2.6 Rialto Bridge (`rialto_bridge`, `LandmarkBrMasonry.rialto`):**
   - Verify exact anchor, `yaw_deg` and bank landings against `ways 166489459, 121674081` and the Grand Canal banks so
     the abutment stairs meet Riva del Vin and Riva del Ferro seamlessly without water gaps (`bridge_connection_test`
     pattern); refine the weathered white Istrian-stone balustrades, spandrel bas-relief carvings (Annunciation /
     Gabriel & Mary + Venice patron saints), central triumphal arch pediment, stepped lead shop roofs, warm golden
     arcade shopfront `*Lamp` glow and arch-underside `FLOOD_META` reflections on the Grand Canal at night.

## Phase 3: Batch A — Grand Canal preset corridor & Bacino foreground (`VN-3`)

Every landmark here lies directly in or flanking the **Ponte dell'Accademia preset sightline (0–1,150 m along bearing
104°)** and transforms the primary Venice experience from `stylised` to photographic realism.

| ID | Type / File | Site | Must-have real-life features | Target tris |
| --- | --- | --- | --- | ---: |
| VN-3.1 | `san_giorgio_maggiore` (`vn_san_giorgio.gd`) | `way 138804537` + monastery `way 138800498` (1,150 m, `103.6°`) | **Direct preset horizon anchor:** Palladio's dazzling white Istrian-stone interlocking twin temple fronts (giant Composite columns on high plinths, triangular pediment, wall niches with statues), brick nave & high ribbed lead dome with lantern (`~46 m`), **75 m** red-brick square campanile with white Istrian-stone belfry & conical spire, Benedictine monastery cloister wing & small boat harbour with twin white lighthouse towers on the Bacino edge | ~85,000 |
| VN-3.2 | `punta_della_dogana` (`vn_punta_dogana.gd`) | `relation 2317795` (581 m, `102.0°`) | **Directly behind Salute in the preset view:** dramatic triangular promontory customs house (*Dogana da Mar*), white rusticated Istrian-stone classical arcades on both Grand Canal and Giudecca Canal faces, pedimented front with Venetian Lion relief, square corner watchtower crowned by two bronze Atlases supporting a **gilded bronze sphere** and turning **gilded Fortune weathervane** (`~28 m`), terracotta pitched roofs | ~50,000 |
| VN-3.3 | `palazzo_cavalli_franchetti` (`vn_accademia_north.gd`) | `way 138841814` (56 m, `72.4°`) | **Immediate left foreground of preset eye:** sumptuous 15th-c. / Neo-Gothic pink-ochre Venetian palazzo, two tiers of elaborate 5-bay pointed *polifora* lancet arcades with pierced quatrefoils & projecting Istrian balconies, steep Gothic cornice, canal garden terrace & striped red-white *paline* | ~45,000 |
| VN-3.4 | `palazzo_barbaro` (`vn_accademia_north.gd`) | `way 138843885` (75 m, `96.3°`) | Twin-palazzo Grand Canal ensemble directly beside Cavalli-Franchetti: older 1425 Gothic wing (warm salmon-ochre plaster, trefoil *quadrifora*, corner Istrian quoins) paired with the 1694 Baroque wing (white stone pilasters, arched *piano nobile* windows, pedimented central bay) | ~38,000 |
| VN-3.5 | `palazzo_contarini_polignac` (`vn_accademia_south.gd`) | `way 313876764` (86 m, `169.6°`) | **Immediate right foreground of preset eye:** Lombardo-style early Venetian Renaissance white-and-ochre Istrian marble front, paired 5-arch *piano nobile* loggias, inset circular porphyry & verde antico marble medallions, sculpted pilasters, stepped terracotta cornice | ~38,000 |
| VN-3.6 | `gallerie_accademia` (`vn_gallerie_accademia.gd`) | `way 138842956` (67 m, `215.8°`) | Former Scuola Grande & Chiesa di Santa Maria della Carità directly behind the preset eye: tall Gothic red-brick church facade with white Istrian lancet windows and terracotta pinnacles, plus the flanking Palladian convent facade and Campo della Carità frontage | ~42,000 |
| VN-3.7 | `palazzo_barbarigo` (`vn_dorsoduro_canal.gd`) | `way 313876763` (155 m, `130.3°`) | Unmistakable Grand Canal facade covered in gleaming **19th-century Murano gold-and-polychrome glass mosaics** (two rich figurative panels over arched ground-floor *porta d'acqua* and flanked by round-arched Renaissance windows with Istrian balconies) | ~30,000 |
| VN-3.8 | `palazzo_corner_ca_granda` (`vn_corner_granda.gd`) | `relation 4207325` (219 m, `90.8°`) | Jacopo Sansovino's monumental High Renaissance white Istrian-stone palazzo on the north bank: heavy rusticated ground floor with triple water-gate arches, two upper tiers of paired Ionic & Corinthian columns framing deep round-arched bays and oval attic windows | ~50,000 |
| VN-3.9 | `palazzo_venier_guggenheim` (`vn_dorsoduro_canal.gd`) | `way 313876769` (225 m, `117.9°`) | **Peggy Guggenheim Collection:** iconic unfinished 18th-century white Istrian-stone single-storey *palazzo non finito* with heavy rusticated basement, lion-head keystones, projecting waterfront terrace with marble parapet and lush garden cypresses/shrubs rising behind the low white wall | ~32,000 |
| VN-3.10 | `ca_dario` (`vn_dorsoduro_canal.gd`) | `way 138843787` (274 m, `113.4°`) | Venice's beloved asymmetrical, subtly **leaning** Renaissance jewel-box palazzo (`11 × 27 m`): slender 4-storey polychrome marble front studded with circular Istrian, red porphyry and green serpentine roundels, asymmetric stacked 4-arch loggias on the left, tall terracotta bell-chimneys | ~28,000 |
| VN-3.11 | `gritti_palace` (`vn_san_marco_canal.gd`) | `way 314323127` (338 m, `91.5°`) | **Palazzo Pisani Gritti** directly facing the Salute across the canal: burnt-terracotta/salmon Gothic Venetian facade with stacked Istrian-stone pointed *polifora* windows, carved marble cresting, floating timber canal-side dining terrace with cream parasols & warm terrace lamps | ~38,000 |
| VN-3.12 | `palazzo_ferro_fini_bauer` (`vn_san_marco_canal.gd`) | `relation 19801771` (382 m, `89.3°`) | Twin-front Venetian Gothic + Renaissance palazzo (Veneto Regional Council) and adjacent Palazzo Contarini Fasan ("Desdemona's House" with delicate lacy Gothic wheel-tracery balconies) framing the final stretch into the Bacino di San Marco | ~40,000 |
| VN-3.13 | `san_vidal_chiesa` (`vn_accademia_north.gd`) | `way 138842959` (80 m, `30.3°`) | Andrea Tirali's crisp white Istrian-stone Palladian church facade opening onto Campo San Vidal directly north of Ponte dell'Accademia | ~22,000 |
| VN-3.14 | `san_gregorio_abbazia` (`vn_dorsoduro_canal.gd`) | `way 138800410` (407 m, `110°`) | Former Gothic brick abbey immediately west of Santa Maria della Salute: distinctive red-brick stepped-gable apse, pointed Gothic portal onto the canal, and walled cloister garden — keeps Salute's immediate left flank faithful in the preset shot | ~26,000 |

## Phase 4: Batch B — Piazza San Marco, Molo & Riva degli Schiavoni (`VN-4`)

Completes the world's most famous public square and lagoon waterfront (670–1,050 m east-northeast of Accademia):

| ID | Type / File | Site | Must-have real-life features | Target tris |
| --- | --- | --- | --- | ---: |
| VN-4.1 | `procuratie_piazza_san_marco` (`vn_procuratie.gd`) | `ways 410344923, 138803888, 410344936` (672–752 m) | Continuous 3-sided Istrian-stone ceremonial enclosure of Piazza San Marco: **Procuratie Vecchie** (north, 152 m, 50 ground arches + double upper arcades + crenellated ogee parapet), **Procuratie Nuove** (south, Scamozzi's 3-tier Doric/Ionic/Corinthian arcade with pedimented windows), and **Ala Napoleonica / Museo Correr** (west, monumental attic with classical emperors' statues & triumphal central arch), plus Caffè Florian / Quadri warm arcade lamps | ~110,000 |
| VN-4.2 | `biblioteca_marciana` (`vn_marciana.gd`) | `ways 206333242, 431003622` (813–821 m) | Jacopo Sansovino's supreme Venetian Renaissance masterpiece facing Doge's Palace across the Piazzetta: 21-bay two-tier Doric & Ionic Istrian-stone arcades, richly carved swagged frieze, rooftop balustrade lined with **classical statues & obelisks**, and the adjoining heavily rusticated **La Zecca** (Old Mint) facing the Molo | ~65,000 |
| VN-4.3 | `torre_orologio` (`vn_torre_orologio.gd`) | `way 410344943` (842 m, `67.1°`) | Mauro Codussi's **St Mark's Clocktower** at the Mercerie entrance: wide archway, dazzling **deep-blue & gold astronomical zodiac clock dial**, gilt Madonna & Child niche, winged Lion of St Mark on a starred blue field, and the rooftop terrace with the **bronze bell flanked by two dark-bronze *Mori* bell-ringers** | ~45,000 |
| VN-4.4 | `colonne_san_marco` (`vn_colonne_molo.gd`) | `ways 431003657, 431003588` (869 m, `78.6°`) | The monumental twin grey-and-pink Egyptian granite **Piazzetta Columns** on octagonal stepped Istrian pedestals (`~18 m` overall), crowned by the **bronze Winged Lion of St Mark** (east) and **marble St Theodore standing on the dragon-crocodile** (west), framing the ceremonial water entrance to Venice | ~28,000 |
| VN-4.5 | `prigioni_danieli` (`vn_riva_schiavoni.gd`) | `rel 2080520`, `way 446527969` (982–1,052 m) | **Palazzo delle Prigioni Nuove** (heavily rusticated grey-white Istrian stone ground arcade + pedimented barred windows linking seamlessly to the Bridge of Sighs) and **Hotel Danieli (Palazzo Dandolo)** (iconic rose-pink 14th-c. Venetian Gothic facade with stacked marble *polifora* loggias and gilded cornice on Riva degli Schiavoni) | ~65,000 |
| VN-4.6 | `teatro_la_fenice` & `contarini_del_bovolo` (`vn_san_marco_interior.gd`) | `way 813451645` (399 m), `rel 2766982` (541 m) | Two iconic San Marco interior rows: **Teatro La Fenice** (Neoclassical pale Istrian-stone four-column Corinthian portico facing Campo San Fantin with gilt phoenix emblem and pediment) and **Palazzo Contarini del Bovolo** (famous **28 m cylindrical external spiral staircase tower** — *Scala del Bovolo* — of stacked Istrian-stone round arches topped by an open belvedere dome!) | ~55,000 |

## Phase 5: Batch C — Grand Canal upper reach, Volta de Canal, Rialto & Railhead (`VN-5`)

Covers the dramatic S-curve of the Grand Canal from Accademia north through Volta de Canal, Rialto Market, Ca' d'Oro,
and on to Piazzale Roma / Stazione Santa Lucia (200–1,305 m):

| ID | Type / File | Site | Must-have real-life features | Target tris |
| --- | --- | --- | --- | ---: |
| VN-5.1 | `ca_rezzonico` (`vn_volta_canal.gd`) | `relation 1927025` (272 m, `315.4°`) | Baldassare Longhena's grand Baroque white Istrian-stone palazzo on the west bank: rusticated water-gate arcade, two tall floors of paired columns & deep arched bays with balconies, oval mezzanine windows, wide cornice | ~45,000 |
| VN-5.2 | `palazzo_grassi` (`vn_volta_canal.gd`) | `way 173619525` (234 m, `339.3°`) | Giorgio Massari's crisp white Neoclassical Istrian-stone palazzo facing San Samuele on the east bank: three-bay central portico, pedimented upper windows, smooth ashlar grandeur | ~35,000 |
| VN-5.3 | `ca_foscari` (`vn_volta_canal.gd`) | `way 138843741` (361 m, `328.1°`) | Iconic **Volta de Canal** focal point (seen down the straight reach from Accademia and Rialto!): tall 4-storey brick-and-Istrian Venetian Gothic palazzo with majestic eight-bay pointed marble *polifora* & quatrefoil frieze, flanked by Palazzo Giustinian | ~50,000 |
| VN-5.4 | `fondaco_dei_tedeschi` (`vn_rialto_ensemble.gd`) | `way 138803475` (937 m, `39.9°`) | Massive ochre-stucco Renaissance palazzo immediately north-east of Rialto Bridge: five wide Istrian-stone water-gate arches, regular grid of white-framed windows, crenellated marble roof parapet & rooftop wooden viewing terrace | ~45,000 |
| VN-5.5 | `palazzo_camerlenghi` (`vn_rialto_ensemble.gd`) | `way 138800761` (911 m, `35.6°`) | Jewel-like pentagonal white Istrian-stone Renaissance treasury right at the west foot of Rialto Bridge: tall round-arched windows framed by polychrome marble roundels, pilasters and classical entablatures curving along the canal bend | ~35,000 |
| VN-5.6 | `rialto_mercato_pescheria` (`vn_rialto_ensemble.gd`) | `rel 4182882`, `ways 129298088, 138800979` (881–965 m) | **Fabbriche Vecchie & Nuove** (long arched Istrian-and-ochre market colonnades curving along the Grand Canal) plus the **1907 Neo-Gothic Pescheria** (open red-brick & white-marble fish-market loggia with carved capitals, pointed arcades & timber roof truss) and **San Giacomo di Rialto** portico + 24-hour clock | ~75,000 |
| VN-5.7 | `ca_doro` (`vn_upper_grand_canal.gd`) | Real building way from `VN-0.4` (~1,050 m, `21.5°`, NOT pier `138802455`) | **Venice's supreme Flamboyant Gothic palazzo:** asymmetric lacework white-and-pink marble facade — five-arch open water loggia, two upper tiers of intricate quatrefoil & trefoil Gothic colonnades with delicate marble balustrades, pink Verona marble checkerboard right wing, and the famous scalloped Venetian cresting along the roofline | ~65,000 |
| VN-5.8 | `ca_pesaro` (`vn_upper_grand_canal.gd`) | `relation 2382783` (1,040 m, `10.9°`) | Longhena's bold Baroque palace on the west bank: deeply diamond-rusticated Istrian ground storey, richly sculpted paired Corinthian columns, deep-set shadow arches, dramatic projecting balustrades | ~48,000 |
| VN-5.9 | `fontego_dei_turchi` & `ca_vendramin_calergi` (`vn_upper_grand_canal.gd`) | `rel 2375803` (1,113 m), `way 835241186` (1,215 m) | Two iconic upper-canal opposites: **Fontego dei Turchi** (Veneto-Byzantine 10-arch ground arcade + 18-arch upper loggia flanked by twin crenellated corner towers in pale grey-white stone) and **Ca' Vendramin Calergi / Casinò di Venezia** (Codussi's luminous white Istrian-stone Renaissance facade with paired arched *bifore* windows and Corinthian columns) | ~65,000 |
| VN-5.10 | `san_simeone_piccolo` & `stazione_santa_lucia` (`vn_railhead.gd`) | `ways 138841179, 138841071` (1,077–1,305 m) | **San Simeone Piccolo** (unmistakable tall patinated **copper-green elongated dome** with lantern over a Neoclassical white Corinthian temple portico facing the station across the Grand Canal, `~44 m`) and **Stazione Venezia Santa Lucia** (clean modernist travertine-marble rail terminus facade with winged bronze Venetian Lion reliefs, cantilevered concrete arrival canopy & broad steps to the Grand Canal) | ~65,000 |

## Phase 6: Batch D — Giudecca, Dorsoduro, San Polo, Castello, Cannaregio & outer lagoon (`VN-6`)

Makes every sestiere and the Giudecca / Lagoon skyline equally recognizable from close-up walks and elevated panoramas:

| ID | Type / File | Area / Site | Must-have real-life features | Target tris |
| --- | --- | --- | --- | ---: |
| VN-6.1 | `il_redentore` (`vn_giudecca.gd`) | Giudecca (`way 154856677`, 807 m, `160.9°`) | Andrea Palladio's monumental votive church overlooking the Giudecca Canal: broad Istrian-stone steps, interlocking white temple pediments with giant Corinthian half-columns, high lead-clad ribbed dome (`~52 m`) flanked by **two slender white conical-spired campanili** | ~60,000 |
| VN-6.2 | `le_zitelle` (`vn_giudecca.gd`) | Giudecca (`rel 2382773`, 979 m, `125.3°`) | Palladian white-and-ochre church facing the Bacino: triangular pediment, thermal window, large central dome (`~36 m`) framed symmetrically by two delicate white corner bell turrets | ~38,000 |
| VN-6.3 | `molino_stucky` (`vn_giudecca.gd`) | Giudecca (`way 138841259`, 872 m, `238.5°`, fixes `lv=3` bug!) | Ernst Wullekopf's colossal **1895 red-brick Neo-Gothic flour mill** (`139 × 192 m`, `~38 m`): crenellated stepped Flemish gables, towering corner brick keep, white-trimmed arched factory window grids, bold **"MOLINO STUCKY"** rooftop sign facing the Zattere | ~70,000 |
| VN-6.4 | `basilica_dei_frari` (`vn_san_polo.gd`) | San Polo (`way 815442226` + `rel 2382772`, 602 m) | Venice's monumental Franciscan Gothic red-brick basilica: tripartite curved-gable Istrian-trimmed facade with rose oculi, polygonal brick apse, and **Venice's second-tallest campanile (70 m)** with white stone belfry & octagonal drum | ~65,000 |
| VN-6.5 | `scuola_grande_san_rocco` (`vn_san_polo.gd`) | San Polo (`way 138843143`, 600 m) | Bartolomeo Bon & Scarpagnino's sumptuous white Istrian-stone & polychrome-marble Renaissance confraternity facade right beside the Frari, with fluted projecting columns, paired arched *bifore* windows and pedimented attic | ~42,000 |
| VN-6.6 | `chiesa_santo_stefano` (`vn_dorsoduro_san_marco.gd`) | San Marco (`ways 138842928, 138841364`, 265 m) | Gothic brick church with sculpted Istrian Flamboyant portal, keel-shaped roof, and its **famous 66 m visibly leaning (~2 m tilt!) red-brick campanile** rising prominently behind Campo Santo Stefano | ~45,000 |
| VN-6.7 | `chiesa_gesuati` & `squero_san_trovaso` (`vn_dorsoduro_san_marco.gd`) | Zattere / Dorsoduro (`ways 118714648, 138841864`, 284–294 m) | **Santa Maria del Rosario (Gesuati)** (Massari's bright white Palladian Corinthian church facade + dome + twin small campanili dominating the Zattere promenade) and **Squero di San Trovaso** (Venice's iconic Dolomite-style **dark-timber alpine wooden gondola boatyard** with pitched eaves and wooden slipway sloping into the Rio di San Trovaso) | ~50,000 |
| VN-6.8 | `santa_maria_miracoli` (`vn_castello_cannaregio.gd`) | Cannaregio (`way 138800840`, 1,173 m) | Pietro Lombardo's luminous Renaissance **marble jewel-box church**: entire exterior clad in veined white, pink and grey marble panels, semicircular curved facade pediment, round-arched blind arcades, lead barrel-vault roof and delicate cupola | ~42,000 |
| VN-6.9 | `san_zaccaria` & `chiesa_pieta` (`vn_castello_cannaregio.gd`) | Castello (`way 162035005`, 1,186 m + Pietà `VN-0.4`) | **San Zaccaria** (Codussi's towering 5-tier Istrian-stone arched Renaissance facade with semicircular lunette crown) and **Chiesa della Pietà** (Vivaldi's bright white Palladian facade facing Riva degli Schiavoni) | ~55,000 |
| VN-6.10 | `chiesa_san_moise` & `santa_maria_formosa` (`vn_castello_cannaregio.gd`) | San Marco / Castello (`way 138804072`, 577 m + `VN-0.4`) | **San Moisè** (Tremignon's exuberantly sculpted multi-tier Baroque stone facade near Piazza San Marco) and **Santa Maria Formosa** (twin Renaissance & Baroque white stone fronts + 40 m Baroque onion-domed campanile) | ~50,000 |
| VN-6.11 | `zanipolo_san_marco` (`vn_zanipolo.gd`) | Castello (`VN-0.4`, ~1.5 km) | **Basilica dei Santi Giovanni e Paolo** (huge Gothic red-brick Pantheon of the Doges + white-drummed dome), **Scuola Grande di San Marco** (Lombardo's trompe-l'oeil marble arched facade with semicircular gables), and Verrocchio's **Bartolomeo Colleoni equestrian bronze statue** on its tall Corinthian marble pedestal | ~85,000 |
| VN-6.12 | `arsenale_venezia` (`vn_arsenale.gd`) | Castello (`VN-0.4`, ~1.9 km) | Historic Venetian Republic shipyard entrance: **Porta Magna** (1460 classical Istrian triumphal arch guarded by four marble Greek Lions), **Twin crenellated red-brick Water-Gate Towers (*Torri dell'Arsenale*)** flanking the canal mouth with white stone bands, and crenellated brick perimeter walls | ~60,000 |
| VN-6.13 | `san_pietro_castello` (`vn_outer_lagoon.gd`) | Castello (`VN-0.4`, ~2.5 km) | Venice's former Cathedral: white Palladian facade, tall dome, and **Venice's iconic leaning all-white Istrian-stone campanile (48 m)** | ~45,000 |
| VN-6.14 | `gesuiti_madonna_orto_outer` (`vn_outer_lagoon.gd`) | Cannaregio / Lagoon (`VN-0.4`, ~1.6–2.6 km) | **Chiesa dei Gesuiti** (Baroque travertine facade), **Madonna dell'Orto** (Gothic brick tripartite facade + **56 m** cupola-crowned campanile), **San Michele** red-brick cemetery island perimeter & Codussi's white marble church, and **Murano Faro** white Istrian-stone lagoon lighthouse | ~65,000 |
| VN-6.15 | **Venetian Campanile height & silhouette pass** (`building_masses.gd` / `venice_campanili` override table) | Detailed & far layers | Apply the verified `VN-0.2` height overrides to the 33 un-heighted brick campanili in `venice_detailed.osmb` so Venice's iconic forest of ~75 slim red-brick bell towers with white stone belfries and pyramidal/onion spires punctuates every roofline panorama (not flat 12 m boxes) | procedural |

## Phase 7: Bridges — Grand Canal icons & 858 minor Venetian *ponti* (`VN-7`)

Venice is defined by its 400+ canal crossings (`858` bridge ways in `venice_detailed.osmb`), yet `scripts/data/bridges/`
currently has **zero** Venice rows.

- **VN-7.1 Bespoke Ponte dell'Accademia (`vn_ponte_accademia.gd`, ~38,000 tris):**
  - **Stands directly under the Venice preset eye (`45.4318, 12.3290`, `way 946641888`)!**
  - Eugenio Miozzi's iconic 1933 **48 m single-span arched wooden-and-steel footbridge**: dark weathered oak timber
    arch ribs bound by dark steel tension ties and cross-bracing, sweeping timber-planked stepped approaches on both
    banks, dark-iron vertical-bar railings with warm timber handrails, and subtle under-arch / handrail warm lamps at
    night. Note: keep bridge crown geometry cleanly below the `8.0 m` preset eye height (`eye_m: 8.0`) so the camera
    stands unobstructed on the wooden crest looking down the Grand Canal!
- **VN-7.2 Bespoke Ponte degli Scalzi (`vn_ponte_scalzi.gd`, ~30,000 tris):**
  - Miozzi's 1934 **40 m single-span flattened white Istrian-stone arch** in front of Stazione Santa Lucia (`ways
    240496236, 240496241`): clean bright stone archivolt, stepped stone approaches, white stone balustrades, and
    warm-white night arch uplights.
- **VN-7.3 Bespoke Ponte della Costituzione / Calatrava Bridge (`vn_ponte_costituzione.gd`, ~42,000 tris):**
  - Santiago Calatrava's 2008 **81 m low-profile red-oxide steel & laminated-glass arch** linking Piazzale Roma to
    Santa Lucia (`way 1098943156`): sweeping curved steel ribs, radial transverse fins, illuminated translucent glass
    parapets and glowing deck strips (`*Lamp` crisp white LED bands at night).
- **VN-7.4 Parametric named Venetian bridges (`scripts/data/bridges/bridge_specs_south_east_europe.gd` or new
  `bridge_specs_venice.gd`):**
  - **Ponte della Paglia** (`way 446527918`, white Istrian stone arch right in front of the Bridge of Sighs on Riva
    degli Schiavoni).
  - **Ponte delle Guglie** (Cannaregio Canal, stone arch flanked by four corner marble obelisk *guglie* pinnacles).
  - **Ponte dei Tre Archi** (Cannaregio Canal, Venice's sole surviving triple-arch stone bridge).
  - **Ponte della Libertà** (`way 24995043`, 3,850 m brick/stone multi-arch rail & road causeway connecting Piazzale
    Roma to Mestre across the lagoon).
- **VN-7.5 Authentic Venetian minor canal *ponti* (`bridge_builder.gd` / `bridge_landings.gd` Venice profile):**
  - Give Venice's 858 small pedestrian canal bridges (`highway=steps|footway|pedestrian` + `bridge=yes`, span `< 22 m`)
    an authentic arched silhouette: modest segmental arch soffit (clearing canal boats below!), weathered red-brick
    spandrels with white **Istrian-stone arch ring & stepped treads**, and dark wrought-iron or carved Istrian-stone
    parapets instead of flat grey concrete road decks.
- Validation: `bridge_specs_test`, `bridge_param_test`, `bridge_select_test`, `bridge_connection_test`,
  `bridge_arches_test`.

## Phase 8: Venice city fabric & sestieri (`VN-8`)

Files: new `scripts/generation/architecture_cities_venice.gd` (dispatched from `building_era.gd:462` via a one-line
call), `scripts/generation/architecture_cities_waterfront.gd`, `scripts/generation/city_styles.gd`,
`scripts/render/city_detail.gd`, `scripts/generation/facade_patterns.gd`, `scripts/generation/roof_clutter.gd`,
`docs/architecture-styles.md`, `tests/architecture_test.gd`.

- **VN-8.1 Fix `venice_modern` misclassification (`architecture_cities_venice.gd`):**
  - Replace the 4-line rule at `building_era.gd:462-466` with `ArchitectureCitiesVenice.venice_rule(kind, c)`:
    - `venice_modern` is permitted **ONLY** inside the `venice_modern` district circles (Tronchetto, Santa Marta,
      Piazzale Roma, Marittima port, Sacca Fisola, Sant'Elena outer flats) or with explicit `start_date >= 1946`
      outside the historic sestieri.
    - Inside historic Venice, 5–7 storey footprints route to `venice_grand_canal` / `venice_palazzo` (or `venice_ghetto`
      in the Ghetto district), permanently eliminating the "modern foreground block" reported on the fidelity
      scorecard!
    - Intercept `ferry=yes` + `man_made=pier` + `building=roof` polygons (like `Accademia`, `Ca' D'oro`, `Ca'
      Rezzonico` pontoons) so `BuildingBuilder` skips them as Venetian terracotta buildings and `VeniceWaterfront`
      (`VN-9.4`) renders them as authentic ACTV floating *imbarcaderi*.
- **VN-8.2 Recalibrate Venetian lime-stucco palette (fixes scorecard's "luma below, saturation above"):**
  - Introduce `VENICE_PAINT := 0.35` (matching `STOCKHOLM_PAINT` in `architecture_cities_waterfront.gd:36`) so per-
    building tinting never stacks orange-on-orange into muddy dark terracotta.
  - Shift `VENETIAN` stucco hues toward sun-washed Venetian lime plaster: luminous warm cream, pale peach-ochre,
    faded antique rose, bleached salmon, weathered warm limestone, and muted burnt sienna (`#E6CBB0`, `#DFB796`,
    `#D49A7C`, `#E9D9BE`, `#E4C79B`, `#C98468`, `#DCD0BC`, `#E2BFA8`), paired with crisp pale **Istrian stone**
    (`#EDE7D8`) string courses, water-table plinths, window surrounds and quoins, and weathered warm-terracotta
    *coppi* barrel-tile roofs (`#9E6850`, `#AE765A`, `#8D5B46`, `#B58468`).
- **VN-8.3 New Venetian architectural fabric rows (`architecture_cities_venice.gd`):**
  - `venice_grand_canal`: 3–5 storey monumental palazzi with prominent central grouped arched *polifore* / *trifore*
    windows on the *piano nobile*, crisp white Istrian-stone balconies & quoins, higher floor height (`4.2 m`), tall
    rusticated ground *porta d'acqua* arches.
  - `venice_san_marco`: ceremonial Istrian-stone & pale-stucco arcaded blocks around San Marco & Mercerie with ground-
    floor shop arcades and cream/burgundy canvas café awnings.
  - `venice_palazzo` (Dorsoduro / San Polo / Santa Croce): classic 3–4 storey faded-stucco townhouses & minor palazzi
    with dark-green louvered shutters (`#354F38`), Istrian window sills, bell-topped chimneys (`chimney_cap: "bell"`),
    and timber *altane* roof decks (`altana: 0.35`).
  - `venice_ghetto`: Cannaregio Ghetto **5–7 storey** narrow warm-ochre/cream plaster *case-torri* tenements with lower
    floor heights (`2.8 m`), dense shuttered casements, and pitched terracotta roofs.
  - `venice_arsenale`: Castello / Giudecca industrial **exposed weathered red-brick** shipyard sheds, fortified walls,
    arched multi-pane factory windows and long gabled terracotta roofs.
  - `venice_burano`: vivid fisherman-house pastel & saturated plaster palette (cobalt, butter yellow, coral red,
    emerald, lavender, magenta — used only on Burano island when streamed!).
  - `venice_lido`: early-20th-century Venetian Liberty / Art Nouveau stucco villas with pitched tile roofs and garden
    setbacks (used only on Lido di Venezia).
  - Keep `venice` as the default historic fallback and `venice_modern` strictly for Tronchetto / Piazzale Roma / Santa
    Marta / Marittima.
- **VN-8.4 Expand `city_styles.gd` Venice districts (from 1 circle to 14 measured districts):**
  - **Grand Canal belt** (3–4 overlapping circles along the S-curve from Salute/Accademia through Volta de Canal &
    Rialto to Ca' d'Oro/San Stae -> `venice_grand_canal`), **San Marco & Mercerie** (`venice_san_marco`), **Dorsoduro &
    Zattere** (`venice_palazzo`), **San Polo & Rialto** (`venice_palazzo`), **Santa Croce** (`venice_palazzo`),
    **Cannaregio** (`venice_palazzo`), **Ghetto di Venezia** (`venice_ghetto`), **Castello West** (`venice_palazzo`),
    **Arsenale & San Pietro** (`venice_arsenale`), **Giudecca East/Central** (`venice_palazzo` / `venice_arsenale`),
    **Piazzale Roma / Tronchetto / Santa Marta / Marittima** (`venice_modern`), **Sacca Fisola** (`venice_modern`),
    **Murano** (`venice_arsenale`), **Burano** (`venice_burano`), **Lido** (`venice_lido`).
  - Add `"venice"` to `FAR_DISTRICT_CITIES` (`city_styles.gd:572`) so the Grand Canal palazzi, Giudecca brick and
    historic terracotta roofs read coherently into the far ring.
- **VN-8.5 Venetian facade & roof relief details (`facade_patterns.gd`, `roof_clutter.gd`):**
  - Enhance the Venetian Gothic `wn: "gothic"` facade pattern with a prominent central 3-bay/4-bay *polifora* grouping
    on `venice_grand_canal` *piano nobile* floors, visible Istrian-stone sill brackets, and subtle lower-wall damp/salt
    weathering near `y = 0..1.5 m`.
  - Confirm iconic funnel/bell-shaped Venetian chimneys (`chimney_cap: "bell"`) and wooden rooftop *altane* platforms
    render densely across the Accademia & San Marco roofscapes (`roofs` capture time).
- **VN-8.6 Detail budget (`CityDetail.CITIES`):**
  - Add `"venice"` to `CityDetail.CITIES` (`scripts/render/city_detail.gd:18`, bump `VERSION`), enabling wider High/Ultra
    roofline detail rings (`450 m / 900 m`) and raised building caps (`14,000` on desktop Ultra — easily covering all
    3,660 detailed Venice buildings with full pitched roofs, shutters, chimneys and *altane*!). Verify via
    `tools/build_bench.gd` against Stockholm/London figures.

Validation: `architecture_test`, `city_detail_test`, `roof_clutter_test`, `facade_relief_test`, `party_walls_test`.

## Phase 9: Lagoon water, *fondamenta* canal walls, waterfront props & Venetian vessels (`VN-9`)

Directly closes the remaining fidelity-scorecard visual gate failure (*"foreground still has a sloped or green
land-side stretch"*) and brings Venice's canals alive.

- **VN-9.1 Venetian Lagoon & Grand Canal water palette (`scripts/generation/water_surface.gd`):**
  - Add `venice_lagoon(lat, lon)` geographic box (`45.36..45.50, 12.24..12.44`):
    - **Grand Canal & inner *rii* (`inland_palette`):** luminous opaque **Venetian jade/olive-teal** (`deep:
      (0.068, 0.142, 0.128)`, `shallow: (0.118, 0.205, 0.172)`), low sheltered chop (`wave_amp: 0.48`), rich crisp
      Fresnel sky and palazzo reflections (`near_rough: 0.10`, `spec: 0.26`).
    - **Bacino di San Marco, Giudecca Canal & outer lagoon (`sea_palette`):** deeper **Adriatic blue-green teal**
      (`shallow: (0.028, 0.128, 0.124)`, `deep: (0.012, 0.068, 0.082)`, `far_rough: 0.14`) with gentle lagoon ripple
      and realistic shallow-sandbar shift toward the Lido and Murano.
- **VN-9.2 Vertical Venetian *fondamenta* canal walls (`scripts/generation/venice_waterfront.gd`, pattern
  `BangkokWaterfront`):**
  - Walk all shoreline segments inside historic Venice (`radius <= 1,650 m` around the historic islands + Giudecca +
    San Giorgio):
    - Build vertical **weathered red-brick & Istrian-stone ashlar canal retaining walls** extending from `y = -0.6 m` up
      to quay coping (`+1.15 m`), **eliminating every sloped/green land-side gap along the Grand Canal and inner *rii***
      (directly solving `fidelity-scorecard.md:625-630`!).
    - Lay a dark **olive-green wet tidal algae band** (`y = -0.05..+0.42 m`) along every canal wall and palazzo plinth
      waterline — Venice's single strongest visual realism cue at canal level.
    - Top non-building quay stretches (*fondamenta*, Riva degli Schiavoni, Zattere, Molo) with pale **trachyte
      *masegni* grey paving slabs** + white Istrian-stone coping curb and stepped Istrian-stone water landings (*rive*).
    - Suppress modern metal harbour crash-railings along historic Venetian *fondamenta* (real Venetian quays famously
      have open stone edges with low Istrian stone curbs, except at select narrow bridge turns).
- **VN-9.3 Striped Venetian *paline* & lagoon *bricole* (`venice_waterfront.gd`):**
  - Place clusters of **spiral-striped painted wooden *paline* mooring poles** (Venetian crimson/white, deep
    navy/white, emerald/white, gold/white with turned finials) along the Grand Canal palazzo water-gates (`2–4 m` off
    palazzo fronts, clear of boat channels and bridges).
  - Place iconic **3-pile weathered oak *bricole*** navigation markers (bound at the top with iron bands, occasional
    yellow/red channel cap) marking the navigable channels across the **Bacino di San Marco**, **Giudecca Canal**, and
    lagoon approaches toward San Giorgio and San Michele.
- **VN-9.4 ACTV floating *imbarcadero* vaporetto pontoons (`venice_waterfront.gd`):**
  - At mapped `ferry=yes` / `man_made=pier` stations (including **Accademia**, **Salute**, **Giglio**, **San Marco
    Vallaresso / Giardinetti / San Zaccaria**, **Ca' Rezzonico**, **San Tomà**, **Rialto**, **Ca' d'Oro**, **San
    Giorgio**, **Zattere**, **Redentore**, **Ferrovia / Piazzale Roma**): build authentic **white-and-yellow ACTV
    floating steel-and-timber pontoons** with curved white shelter canopy, bright yellow line-sign fascia band, dark
    rubber fender tires, hinged shore gangway, and warm overhead `PierLamp` globes at night.
- **VN-9.5 Authentic Venetian vessel fleet (`scripts/generation/venice_vessel_models.gd`, wired into `HarbourFerries` &
  `QuayFleet`):**
  - **`gondola` (~10.8 m × 1.4 m):** unmistakable sleek **gloss-black lacquered asymmetric hull**, rising stern,
    gleaming brushed-steel multi-toothed ***ferro*** prow ornament, red-velvet passenger seats with gold brass seahorse
    *cavallini* & scrollwork, wooden *forcola* oarlock, and standing gondolier silhouette with striped shirt & straw
    hat! Placed both **moored in iconic *stazi* rows** (Molo San Marco facing San Giorgio, Accademia, Santa Maria del
    Giglio, Rialto, Bacino Orseolo) with bobbing blue canvas covers and **gliding gently** along the Grand Canal edges
    and Bacino.
  - **`vaporetto` (~23.9 m × 4.2 m, ACTV Serie 80 / 90):** unmistakable Venetian public waterbus — white-and-navy hull,
    low-slung enclosed glass passenger saloon with bright **ACTV yellow roof/window stripe**, open forward viewing
    deck, midships boarding gates, raised wheelhouse, warm lit interior windows + navigation lights at night. Runs
    animated routes (`RouteBoatDriver`) along **Line 1 (Grand Canal: Ferrovia -> Rialto -> Accademia -> Salute -> San
    Marco -> San Giorgio)** and **Line 2 (Giudecca Canal & Bacino)**.
  - **`motoscafo` (~9.5 m × 2.3 m):** classic varnished **mahogany wooden Venetian water taxi** with cream-white
    glazed cabin, chrome bow fittings, and crisp white V-wake running the Grand Canal and Bacino.
  - **`topo_barge` (~12.0 m × 2.8 m):** traditional dark-timber / painted lagoon utility & delivery cargo boat with
    wooden crates / hydraulic crane arm along the inner canals and Rialto Erberia market quay.
  - **Post-2021 Venice Cruise-Ship Ban (`quay_fleet.gd` / `quay_moorings.gd`):** block ocean cruise liners and large
    ro-pax ferries from spawning inside the Grand Canal, Bacino di San Marco, and Giudecca Canal (mirroring London's
    upstream Thames block in `QuayFleet.hotel_water`), preserving the authentic low-scale Venetian lagoon horizon.

Validation: `coastal_water_test`, `far_water_palette_test`, `vessel_models_test`, `marina_test`, `shoreline` tests.

## Phase 10: Car-free historic streetscape, Venetian furniture, gardens & atmosphere (`VN-10`)

- **VN-10.1 Strictly car-free historic Venice (`car_fleet.gd` / road traffic gate):**
  - Confirm that zero cars, buses, or road traffic signals spawn anywhere inside historic Venice's pedestrian islands,
    bridges or *campi* (`3,612 pedestrian`, `739 footway`, `704 steps` in `venice_detailed.osmb`), confining road
    vehicles strictly to **Piazzale Roma, Tronchetto, and Ponte della Libertà** (Italian `"south_europe"` fleet +
    ACTV orange/white buses & Mestre red tram at Piazzale Roma).
- **VN-10.2 Venetian street furniture kit (`street_furniture.gd`, family `"venice"`):**
  - **Venetian *ferali* street lamps:** ornate dark-iron wall-mounted bracket lanterns along narrow *calli* and dark
    cast-iron pedestal globe lamps (single and triple-globe standards along Riva degli Schiavoni, Zattere, Molo, and
    Piazza San Marco) casting warm amber pools (`2700 K`) at night.
  - **Carved Istrian-stone *vere da pozzo* (wellheads):** iconic octagonal/cylindrical carved stone wellheads on
    stepped bases placed at the centres of mapped historic *campi* (Campo Santo Stefano, Campo Santa Margherita, Campo
    San Polo, Campo San Barnaba, Campo San Giacomo, Campo Santi Giovanni e Paolo).
  - **Piazza & *campo* café seating:** neat clusters of cream-canopy outdoor tables/chairs under the Procuratie arcades
    (Caffè Florian / Quadri) and major *campi* without blocking footways.
  - **Dark-green cast-iron Venetian litter bins** and stone benches along Zattere, Riva degli Schiavoni and Giardini.
- **VN-10.3 Venetian *trachyte masegni* paving (`road_builder.gd` / paved area materials):**
  - Ensure historic *calli*, *campi* and *fondamenta* use warm pale grey-taupe rectangular **Euganean trachyte
    *masegni* stone paving** (with Piazza San Marco's iconic geometric white Istrian-stone linear inlay stripes!), never
    black asphalt.
- **VN-10.4 Venetian gardens & trees (`tree_species.gd`, `heritage_zones.gd`):**
  - Add a `"venice"` tree mix (`cypress 0.25`, `holm_oak 0.25`, `plane 0.20`, `pine_umbrella 0.15`, `olive_fig 0.15`) so
    Venice's walled palazzo gardens (Giardini Reali by San Marco, Peggy Guggenheim sculpture garden, Giardini della
    Biennale, San Giorgio Maggiore cloister, Giudecca orchards) feature authentic **Italian cypresses, stone pines,
    holm oaks and plane trees** rather than northern conifers.
  - Keep **Piazza San Marco**, **Piazzetta San Marco**, **Campo Santo Stefano**, **Campo San Polo**, and **Campo
    Santa Margherita** completely clear of stray procedural trees via `tree_rect`.
- **VN-10.5 Adriatic lagoon atmosphere & golden Venetian light (`atmosphere_rig.gd`, `haze_rig.gd`, `sky_palette.gd`):**
  - Verify Italy's `UTC+1` (CET) / `UTC+2` (CEST) solar clock.
  - Tune the Adriatic maritime aerial haze so golden-hour sun warms Venice's Istrian stone and pale rose/ochre stucco
    with soft pearlescent lagoon mist separating the Accademia foreground, Salute/Dogana midground, and San Giorgio
    Maggiore / distant Alps/Dolomites horizon — lifting Venice's dark luma and taming excess saturation (`fidelity-
    scorecard.md:521`).

Validation: `car_fleet_test`, `street_furniture_test`, `canopy_vegetation_test`, `tree_lod_test`, `sky_test`,
`haze_test`.

## Phase 11: Night lighting (`VN-11.1`) & review rounds (`VN-11.2`)

- **VN-11.1 Dedicated Venice night pass (`LandmarkLights`, `--preset=3`):**
  - Venice at dusk and night is famous for **warm incandescent golden stone reflections shimmering across dark
    jade-black canals** — never harsh neon:
    - **Grand Canal icons:** warm architectural uplights on **Santa Maria della Salute** (Grand Canal portico, drum
      volutes, ribbed dome), **Punta della Dogana** tower & gilded Fortune, **Ponte di Rialto** arch soffit & warm
      arcade shop glow, **Ponte dell'Accademia** handrail lamps, **Ponte della Costituzione** glowing glass steps &
      parapets, and subtle warm *piano nobile* chandelier-window glow inside **Ca' d'Oro, Ca' Rezzonico, Ca' Foscari,
      Palazzo Cavalli-Franchetti, Palazzo Barbarigo, Gritti Palace** and **Palazzo Corner**.
    - **Piazza San Marco & Bacino:** warm golden uplight wash across **St Mark's Basilica** mosaic portals & domes,
      **Doge's Palace** double Gothic arcades, **St Mark's Campanile** belfry cell & Archangel Gabriel, **Torre
      dell'Orologio** backlit blue-and-gold zodiac clock dial, **Procuratie** continuous warm arcade glow, **Biblioteca
      Marciana**, and **San Giorgio Maggiore** dazzling white temple front & red-brick campanile glowing across the
      dark Bacino di San Marco!
    - **Giudecca & outer churches:** warm facade floods on **Il Redentore**, **Le Zitelle**, **Gesuati**, **Frari**,
      and **Molino Stucky** rooftop sign.
    - **Canal life at night:** glowing warm **ACTV *imbarcadero* pontoon lanterns**, illuminated **vaporetto** cabin
      windows & red/green/white navigation lights, warm **ferali** globe reflections along Riva degli Schiavoni and
      Zattere.
- **VN-11.2 Review rounds, scorecard, docs & performance:**
  - Capture rounds `venice-r1`…`venice-rN` into `visual-plan/reviews/venice-rN-<date>/` at the frozen eyes below. Lay
    every landmark's day & night model sheet beside its Wikimedia Commons reference photo
    (`tools/landmark_compare_sheets.py`) and beside an in-world eye; log every shape, proportion, material, alignment
    or water-edge mismatch, fix, and recapture.
  - Update `docs/fidelity-scorecard.md` (aiming to move Venice from `stylised` -> `photographic` with the shoreline
    visual gate passing and luma/saturation metrics inside reference bounds), `docs/architecture-styles.md`,
    `docs/venice-landmark-sources.md`, and README lists.
  - Performance: run `tools/perf_baseline.gd` and `tools/build_bench.gd` on Venice at presets 2 and 3 (cold, cached,
    fly), specifically profiling frame time at the **Ponte dell'Accademia** and **Molo San Marco** eyes where the
    highest landmark + vessel + canal-wall triangle count is in view; run `lod_test`, `memory_budget_test`,
    `impostor_test`, `landmark_ultra_lod_test`.

## Captures and eyes

Two capture sets per round (bundled Accademia snapshot vs streamed close eyes across all sestieri):

**Set A — bundled Grand Canal & Bacino centre (`--keep_centre`, uses `venice_*.osmb`):**
```
tools/godot_bg.sh --path . --script tools/capture_presets.gd --position 4000,4000 -- --tag=venice-rN
  --preset=3 --pin=45.4318,12.3290 --places=venice --times=golden,noon,night,late,roofs --keep_centre
  --looks="<Set A eyes>"
```

**Set B — streamed close eyes across Venice (no `--keep_centre`, live Overpass cached after first run):** same command
with `--tag=venice-rN-close` and Set B eyes.

**Model sheets:** `tools/capture_landmarks.gd --types=<types> --tag=vn_lm_rN` (day and `--night`), then
`python3 -I tools/landmark_compare_sheets.py --tag=vn_lm_rN`.

Candidate eyes (confirm every eye is clear of footprints in `VN-0.1`, then freeze; format
`lat,lon,height_m,bearing,pitch`; note over-water drone eyes use height above canal bed):

| Set | Eye | Candidate | Shows |
| --- | --- | --- | --- |
| A | Preset vantage (Ponte dell'Accademia) | `45.4318,12.3290,8.0,104,-2` | Grand Canal, Cavalli-Franchetti, Barbaro, Polignac, Guggenheim, Salute, Dogana, San Giorgio Maggiore |
| A | Lower Grand Canal drone (off Guggenheim) | `45.4314,12.3324,10,108,2` | Salute close-up, Gritti Palace, Punta della Dogana, San Giorgio Maggiore, vaporetti & *paline* |
| A | Accademia looking NW (Volta de Canal) | `45.4318,12.3290,8.0,322,0` | Ca' Rezzonico, Palazzo Grassi, Ca' Foscari curve |
| A | Molo San Marco looking WSW | `45.4332,12.3401,2.2,248,4` | Piazzetta Columns, Biblioteca Marciana, Salute & Punta della Dogana across the Bacino, moored gondolas |
| A | Piazza San Marco centre looking E | `45.4341,12.3379,2.0,82,8` | St Mark's Basilica, Campanile & Loggetta, Torre dell'Orologio, Procuratie Vecchie & Nuove, *masegni* stripes |
| A | Riva degli Schiavoni / Ponte della Paglia | `45.4336,12.3409,2.8,10,8` | Bridge of Sighs spanning between Doge's Palace & Prigioni Nuove, Rio di Palazzo |
| A | Bacino di San Marco drone looking N | `45.4308,12.3406,18,350,2` | Molo skyline: Doge's Palace, Campanile, Basilica domes, Marciana, Danieli, Riva degli Schiavoni |
| A | Bacino looking SE toward San Giorgio | `45.4326,12.3402,4.0,140,3` | San Giorgio Maggiore Palladian front, dome & campanile across turquoise Bacino with *bricole* & gondolas |
| A | Rialto Bridge north approach (Grand Canal drone) | `45.4388,12.3363,12,205,-2` | Rialto Bridge, Fondaco dei Tedeschi, Palazzo dei Camerlenghi, Fabbriche, Pescheria |
| A | Zattere promenade looking S across Giudecca | `45.4290,12.3282,2.2,152,4` | Il Redentore, Giudecca Canal, ACTV vaporetto, *bricole* |
| A | Roof-height Grand Canal & Bacino panorama | `45.4318,12.3290,130,80,-12` | Entire S-curve, terracotta roofscape, bell-chimneys, 75 campanili, San Marco, Giudecca, Lagoon |
| B | Upper Grand Canal off Ca' d'Oro | `45.4408,12.3330,10,115,4` | Ca' d'Oro marble lacework, Ca' Pesaro, Fontego dei Turchi |
| B | Campo dei Frari / San Rocco | `45.4366,12.3257,2.0,60,12` | Basilica dei Frari facade & 70 m campanile, Scuola Grande di San Rocco |
| B | Ferrovia / Grand Canal west | `45.4409,12.3220,10,140,2` | Ponte degli Scalzi, San Simeone Piccolo green dome, Stazione Santa Lucia, Ponte della Costituzione |
| B | Campo Santi Giovanni e Paolo | `45.4394,12.3413,2.0,65,10` | Zanipolo, Scuola Grande di San Marco, Colleoni equestrian statue, canal bridge |
| B | Arsenale water-gate approach | `45.4345,12.3496,3.0,35,8` | Twin brick Arsenale Water-Gate Towers & Porta Magna |
| B | Inner *rio* & *campo* street-level eye (San Trovaso / Santa Margherita) | `45.4304,12.3264,1.8,240,3` | Squero di San Trovaso timber boatyard, arched brick/Istrian *ponte*, algae waterline, *ferali* lamps |

## Order and size

1. **Phase 0 + Phase 1 + Phase 2 (`VN-0`, `VN-1`, `VN-2`) + `VN-7.1` (Ponte dell'Accademia) + `VN-8.1`–`VN-8.2` (fix
   `venice_modern` + stucco luma/saturation) + `VN-9.1`–`VN-9.2` (lagoon water + *fondamenta* vertical canal walls).**
   Immediately resolves all three root defects logged in `docs/fidelity-scorecard.md` (modern foreground block,
   misplaced Salute, sloped/green foreground bank, and dark/over-saturated walls).
2. **Phase 3 (`VN-3` Grand Canal corridor & San Giorgio Maggiore & Punta della Dogana) + `VN-9.3`–`VN-9.5` (*paline*,
   *bricole*, ACTV pontoons, gondolas & vaporetti).** Makes the entire preset Grand Canal & Bacino vista genuinely
   photographic.
3. **Phase 4 (`VN-4` Piazza San Marco & Molo) + Phase 5 (`VN-5` Volta de Canal, Rialto Market, Ca' d'Oro, Railhead) +
   `VN-7.2`–`VN-7.5` (Scalzi, Calatrava & minor *ponti*).**
4. **Phase 6 (`VN-6` Giudecca, Frari, Castello, Arsenale, outer lagoon & 75 campanili) + remaining Phase 8 (`VN-8.3`–
   `VN-8.6` sestieri districts & `CityDetail.CITIES`) + Phase 10 (`VN-10` car-free Venice, *ferali*, *vere da pozzo*,
   gardens & Adriatic haze).**
5. **Phase 11 (`VN-11` Night lighting pass, review rounds, scorecard upgrade, performance verification).**
6. Every phase ends with its tests passing and a capture round, so work can stop or ship cleanly after any phase.

## Open decisions

| Decision | Recommendation |
| --- | --- |
| Raise `salute` `ultra_registry_limit` / `ultra_total_limit` to `46 / 52` | Yes — matches Stockholm (`48 / 56`) and London (`42 / 50`), giving Ultra all Grand Canal palazzi, Piazza San Marco, and Palladian churches plus 6 parametric bridge slots |
| Add `"venice"` to `CityDetail.CITIES` (`VN-8.6`) | Yes — after `VN-8.1`–`VN-8.4`, provided `tools/build_bench.gd` stays within Stockholm/London build-time and memory budgets |
| Re-cut `venice_ring1600.osmb`, `venice_ring2500.osmb`, `venice_transit.osmb` (`VN-0.3`) | Yes — both rings currently truncate at 150 waterways and `venice_transit.osmb` lacks ACTV vaporetto piers |
| Add a second Venice `PresetViews` vantage (e.g. Molo San Marco or Rialto Bridge) & re-bake `assets/preset_thumbs/venice.jpg` | Only on explicit user request |
| Venice Marco Polo Airport & Mestre mainland industrial zone | Out of scope (historic lagoon islands, Giudecca, San Giorgio, San Michele, Murano, Burano and Lido only) |

## Verification

- Headless tests in the background after each phase:
  `tools/run_tests.sh landmark venice bridge architecture roof facade canopy tree water vessel marina car_fleet street`
  (or individual tests via `tools/godot_bg.sh --headless --path . --script tests/<name>_test.gd`). Treat any
  `SCRIPT ERROR:` line as a failure even on exit code 0.
- `tools/check_class_size.sh` after every added or edited class under `scripts/`.
- `tools/godot_bg.sh --headless --path . --script tests/host_policy_test.gd` after any data or reference-script change.
- `tools/godot_bg.sh --headless --path . --script tests/landmark_ultra_lod_test.gd` after any `salute` edit.
- Windowed tests (`tests/screenshot_test.gd`, `tests/world_cache_test.gd`) batched once at the end, in the background.
- **Done means:** every existing and new Venice landmark matches its Wikimedia Commons reference photo in silhouette,
  proportion, Istrian-stone/brick/marble/stucco material and night lighting; Ponte dell'Accademia, Rialto, Scalzi and
  Calatrava render as bespoke bridges and the 858 minor *ponti* read as arched stone/brick crossings; the Salute,
  Doge's Palace, St Mark's Campanile and Basilica sit at verified coordinates and bearings; vertical *fondamenta* walls
  with algae waterlines close the shoreline visual gate; gondolas, ACTV vaporetti, *motoscafi*, *paline* and *bricole*
  populate jade-teal Venetian water with zero ocean cruise ships in the canals; historic Venice is car-free with
  *ferali* lamps and *vere da pozzo* wellheads; all listed tests and `check_class_size.sh` pass; and performance stays
  within budget of `venice-r0`.
