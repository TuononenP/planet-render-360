# London super-realistic: landmarks and city

> Tracker in the house style of `PLAN_Stockholm_super_realistic.md` and `PLAN_Singapore_super_realistic.md`: claim a
> task, tick it only after its validation passes, add one evidence line. Status legend: `[x]` done and validated, `[~]`
> in progress, `[ ]` open.
> Grounded against the codebase and the decoded bundled snapshots (`assets/osm_snapshots/london_*.osmb`, centred on
> Queen's Walk by Westminster Bridge `51.5018, -0.1196`, OSM base `2026-11-02`). Nothing in this plan has been built
> yet. Every dimension not tagged "OSM" is a starting value from memory and must be verified in `LN-0.4` / `LN-0.6`
> before modelling.

## Tracker

- [x] LN-0.1 Baseline captures `london-r0` — captured `visual-plan/reviews/london-r0-2026-11-23/` & `visual-plan/captures/{ln_lm_base,ln_lm_base_night}/` (all 10 existing heroes).
- [x] LN-0.2 Height & tag audit of `london_detailed.osmb` and `london_far.osmb` — audited 137 detailed + 349 far anomalies (`National Theatre h=6.5`, `Somerset House lv=2`, `8 Bishopsgate h=-`), documented in `docs/london-landmark-sources.md`.
- [ ] LN-0.3 Snapshot repair: re-cut `london_ring1600.osmb` and `london_ring2500.osmb` (deferred — requires offline Overpass snapshot re-bundle; does not block visual fidelity inside detailed/streamed worlds).
- [x] LN-0.4 Site measurement pass — verified centroids & footprints for `County Hall`, `Portcullis House`, `Tattershall Castle`, and all 65 London landmarks in `docs/london-landmark-sources.md`.
- [ ] LN-0.5 Reference photos (`tools/commons_refs.py` / `tools/london_commons_refs.py`) — optional offline contact-sheet archive.
- [x] LN-0.6 Sources doc `docs/london-landmark-sources.md` created with verified OSM IDs, heights, and coordinates.
- [x] LN-0.7 Slot budget & `big_ben` `ultra_registry_limit: 42 / ultra_total_limit: 50` pinned in `tests/london_landmarks_test.gd` (`PASSED`).
- [x] LN-1 London batch wiring (`landmark_registry_london.gd`, `landmark_set_london.gd`, `landmark_ln_kit.gd`, `ln_tower_specs.gd`, `landmark_registries.gd`) — verified by `tests/london_landmarks_test.gd` (`65/65 OK`).
- [x] LN-2 Existing 10 landmarks upgraded (`big_ben` limestone + Ayrton Light + 10 paired night uplights; `london_eye` LED rim; `buckingham_palace` + Queen Victoria Memorial; `shard` + `st_mary_axe` night glow & beacon) — verified in `ln_lm_r1_night` & `london-r2`.
- [x] LN-3 Batch A: 13 Westminster, Whitehall & South Bank foreground landmarks (`county_hall`, `portcullis_house`, `whitehall_horse_guards`, `whitehall_court`, `admiralty_arch`, `trafalgar_square`, `royal_festival_hall`, `national_theatre`, `somerset_house`, `oxo_tower`, `methodist_central_hall`, `lambeth_palace`, `cleopatras_needle`) — built & verified in `london-r1`/`london-r2`.
- [x] LN-4 Batch B: 14 Central, East & West London major icons (`tate_modern`, `shakespeares_globe`, `bank_junction`, `monument_london`, `lloyds_building`, `st_pancras_station`, `british_museum`, `westminster_cathedral`, `battersea_power_station`, `bt_tower`, `royal_albert_hall`, `natural_history_museum`, `marble_wellington_arches`, `o2_arena`) — built & verified in `ln_lm_r1` & `london_landmarks_test`.
- [x] LN-5 Batch C: 25 London Skyline Towers (`LnTowerSpecs`: City of London cluster, Barbican, South Bank/Nine Elms, Canary Wharf with One Canada Square red beacon) — built & verified in `london-r1`/`london-r2`.
- [x] LN-6 Thames Bridges — bespoke `westminster_bridge` (Parliament-green 7-arch Gothic iron), `hungerford_golden_jubilee`, `millennium_bridge`; unbuilt `conf 1`/`lateral` pilot rows removed; `bridge_specs_test` & `bridge_select_test` `PASSED`.
- [x] LN-7 City fabric — 16 London districts in `city_styles.gd`, new `london_portland` & `london_warehouse` rows in `architecture_cities_europe.gd`, `"london"` added to `CityDetail.CITIES`; `architecture_test` & `city_detail_test` `PASSED`.
- [x] LN-8 Thames water & vessels — silty olive-brown tidal Thames palette (`water_surface.gd`), ocean cruise liners/ro-pax ferries blocked upstream of Tower Bridge (`quay_moorings.gd`, `quay_fleet.gd`); `coastal_water_test` `PASSED`.
- [x] LN-9 Streets & vehicles — red double-decker London bus (`bus_double` in `car_specs.gd` & `transit_vehicles.gd`), London Underground `roundel` in `street_furniture.gd`; `bus_stop_test`, `car_fleet_test`, `street_furniture_test` `PASSED`.
- [x] LN-10 Night lighting (`LandmarkLights` `FLOOD_META`, `HALO_META`, `GLOW`, `*Lamp` across London landmarks & bridges) — `landmark_lights_test` `PASSED`, verified in `london-r2` night frames.
- [x] LN-11 Review rounds `london-r1` & `london-r2`, `docs/fidelity-scorecard.md` updated.
- [x] Code review — `tools/check_class_size.sh` OK (`996/1000`), all headless suites & `host_policy_test` `PASSED`, no AI attribution.

## Context

London has a bundled preset vantage on Queen's Walk by Westminster Bridge (`51.5018, -0.1196`, eye `8.0 m`, bearing
`258°`, pitch `+3°`, `scripts/data/preset_views.gd:108-109`), looking across the Thames to the Palace of Westminster and
Elizabeth Tower ("Big Ben"), with the London Eye just behind and County Hall immediately to the east. The capital
catalog entry sits at Charing Cross (`51.50853, -0.12574`, `scripts/data/capital_catalog.gd:124`).

On `docs/fidelity-scorecard.md` (lines 295, 322, 513), London currently sits at **`recognisable`**:
- *"Palace, Big Ben and the Eye placed right; facades too clean"*
- *"Palace reads flat and dark from the low eye; backlit golden shot; bridge is plain stone, not green-and-red iron"*
- *"Westminster and bridge identify the scene; the river colour and building massing remain simplified."*

### What the codebase and snapshot audit found

1. **Ten hand-built landmarks already exist — a strong start, but uneven and incomplete:**
   - Core (`scripts/data/location_data.gd`): `big_ben` (Palace of Westminster, `landmark_westminster*.gd`, 677 lines),
     `tower_bridge` (`landmark_tower_bridge.gd`, 382 lines).
   - West Europe batch (`scripts/data/landmark_registry_west_europe.gd`): `london_eye` (205 lines), `st_pauls` (371
     lines), `westminster_abbey` (400 lines), `shard` & `st_mary_axe` (`landmark_london_towers.gd`, 333 lines),
     `tower_of_london` (518 lines), `buckingham_palace` (184 lines), `waterloo_station` (`landmark_waterloo*.gd`, 877
     lines).
   - **Known gaps on existing models:**
     - None of the 10 carry `skyline_priority` (so nearest-first selection can drop distant skyline icons like The
       Shard, 30 St Mary Axe or Tower Bridge once foreground landmarks are added).
     - `buckingham_palace` omits the Queen Victoria Memorial and its own comment (`landmark_london_palaces.gd:21-24`)
       notes its yaw is off by ~12° from The Mall's true bearing (`058°`).
     - `london_eye` has no night `*Lamp` / LED rim or capsule lighting; `shard` and `st_mary_axe` have no `LandmarkLights`
       `GLOW` or aviation beacons; `big_ben` reads flat/dark from the low riverside eye at golden hour.
2. **Foreground landmarks right beside the preset eye are unmodelled:**
   - **County Hall** (`relation 1789966`) stands **65 m** from the preset eye and renders as a generic commercial box.
   - **Portcullis House** (`way 256497249`, 362 m, directly opposite Big Ben), **Shell Centre** (`way 46250966`, 291 m),
     **Royal Festival Hall** (`way 5987419`, 478 m), **Whitehall Court** (`relation 5485985`, 507 m), **Horse Guards**
     (`way 133153176`, 612 m), **National Theatre** (`relation 2023676`, 691 m — tagged `height=6.5` in OSM!),
     **Trafalgar Square** (Nelson's Column, National Gallery, St Martin-in-the-Fields, Admiralty Arch, 822–925 m),
     **Somerset House** (`way 372841786`, 1,010 m — tagged `lv=2`, no height!), and **OXO Tower** (1,068 m) are all
     inside the detailed snapshot and currently generic extrusions.
3. **Foreground Thames bridges are missing or broken:**
   - **Westminster Bridge** (`br_london_westminster_bridge`, `bridge_specs_pilot.gd:89`) is right in the foreground of
     the preset view (144–231 m) but is `conf: 1`, so `BridgeParam` skips it and it renders as a plain stone road slab
     instead of the iconic seven-arch green-and-red iron Gothic bridge.
   - **Hungerford Bridge & Golden Jubilee Bridges** (401–612 m, directly beside the London Eye) have no spec at all.
   - **Millennium Bridge** (`br_london_millennium_bridge`, `bridge_specs_pilot.gd:114`) has `st: "lateral"` with note
     `NOT BUILT`, so the St Paul's–Tate Modern sightline has no bridge model.
   - Eleven other Thames bridges (`Waterloo`, `Southwark`, `Blackfriars`, `London`, `Lambeth`, `Vauxhall`, `Chelsea`,
     `Albert`, `Battersea`, `Putney`, `Hammersmith`) are already `conf: 2` in `bridge_specs_pilot.gd` /
     `bridge_specs_west_europe.gd`, while `Wandsworth` is `conf: 1`.
4. **Bundled OSM snapshot statistics (`assets/osm_snapshots/london_*.osmb`, centred `51.5018, -0.1196`):**
   - `london_detailed.osmb`: 20,880 elements — **3,241 buildings**, **3,114 `building:part`s**, **4,186 trees**, **491
     railways** (370 `rail`, 112 `subway`), **447 bridges**, **34 waters**, **46 historic**, **17 piers**.
   - Only **65** of 3,241 buildings (2 %) have an explicit `height` tag; **1,027** (32 %) have `building:levels`;
     **1,790** (55 %) are untyped `building=yes`.
   - **Ring truncation:** `london_ring1600.osmb` (`hw=800, ww=13`) and `london_ring2500.osmb` (`hw=800, ww=30`) both hit
     the old 800-highway cap and need re-cutting (`LN-0.3`).
   - `london_far.osmb` covers the City of London cluster (2.7–3.1 km: The Shard, 22 Bishopsgate, Heron Tower, Leadenhall
     Building, Tower 42, 30 St Mary Axe, 20 Fenchurch / Sky Garden, 8 Bishopsgate [`h=-, lv=51`]), BT Tower (2.5 km),
     Royal Albert Hall (4.0 km), and Canary Wharf (6.9–7.3 km: One Canada Square, HSBC, Citigroup, One Park Drive,
     Barclays).
5. **Slot budget is too tight for a hero city:**
   - `big_ben` (`location_data.gd:466`) has no `ultra_registry_limit` or `ultra_total_limit`, leaving London at the
     default 6/12/18/22 extras and 2/4/4/4 bridges. Following Stockholm (`stockholm_city_hall`, `location_data.gd:518`),
     raising `big_ben` to `ultra_registry_limit: 42, ultra_total_limit: 50` gives Ultra room for 42 landmarks + 8 Thames
     bridges without starving either.
6. **City fabric, detail budget, vehicles & street furniture:**
   - `city_styles.gd:184-189` has only **6** London districts (Belgravia, Kensington, Notting Hill, Bloomsbury, Canary
     Wharf, the City). Westminster/Whitehall, South Bank, Mayfair/St James's, Soho/Covent Garden, Strand/Holborn,
     Pimlico, Southwark/Borough, Clerkenwell/Shoreditch, Barbican and Greenwich all fall back to generic brick.
   - `"london"` is not in `CityDetail.CITIES` (`scripts/render/city_detail.gd:18`).
   - `CarFleet.TAXIS` already has `"cab_london"` black cabs, `TrainSpecs` already has three UK EMU liveries with yellow
     cab ends (`london_blue`, `london_grey`, `london_white`), `StreetFurniture` already has `"uk"` family, and
     `WaterSurface` already has a Thames harbour box (`51.43..51.57, -0.25..0.12`).
   - **Missing iconic London street cues:** no **red double-decker bus** model (buses use single-deck `CarModel "bus"`
     painted red), no **K6 red telephone box**, no **Royal Mail pillar box**, no **Underground roundel** at
     `subway_entrance` nodes, and no **Victorian Embankment dolphin lamps**.

**Goal:** from the Westminster preset vantage, from any central Thames bridge, and from close-up eyes across Westminster,
Whitehall, Trafalgar Square, South Bank, the City, Tower Bridge, Kensington and Canary Wharf, a person who knows London
recognises every landmark and major building by silhouette, proportion, stone/brick/glass material, bridge ironwork and
night look — and the streets, buses, cabs, embankments and river between them unmistakably read as London.

## Ground rules

- **Measured, not remembered.** Site, footprint, axis and height come from OSM (bundled snapshot or `LN-0.4` Overpass
  pass), architectural dimensions from Historic England / Wikipedia / architect data, and appearance from Wikimedia
  Commons reference photos.
- **Catalog limits per landmark** (`tests/landmark_catalog_test.gd`): 2 to 16 merged surfaces, at most 150,000
  triangles, textured materials only, top within `max(2 m, 3 %)` of `height_m`.
- **Class size:** every `.gd` file under `scripts/` stays at or under 1,000 lines (`tools/check_class_size.sh`). Split
  complex landmarks into plan/ranges/towers files (following `landmark_westminster*.gd` and `landmark_waterloo*.gd`).
- **Existing work & minimal edits:** preserve all existing landmark type IDs and aliases (`big_ben`, `tower_bridge`,
  `london_eye`, `st_pauls`, `shard`, `tower_of_london`, `buckingham_palace`, `westminster_abbey`, `st_mary_axe`,
  `waterloo_station`). Prefer new London-specific files over growing shared files. Commit only when explicitly asked;
  never add AI attribution trailers or comments.
- **Hosts:** never contact Russian-operated services or domains (`HostPolicy` / `tests/host_policy_test.gd`). Overpass
  via `openstreetmap.fr` or `kumi` mirrors; reference photos from Wikimedia Commons only.
- **Godot runs:** always through `tools/godot_bg.sh` (never the `.app` binary directly, never `GODOT_FOREGROUND=1`).
  Tests headless in the background; captures windowed in the background with `--position 4000,4000 --preset=3`, never
  `--always-on-top`.
- **Capture eyes:** every eye stands in open space (street, bridge footway, embankment, square, park, or elevated drone
  over the Thames — note `--looks` height over water is measured from the riverbed). Discard and move any frame showing
  interior faces, cut walls or floating geometry.

## Verified site data

Measured from `london_detailed.osmb` and `london_far.osmb` relative to the London preset centre (`51.5018, -0.1196`).
"OSM h" is the literal `height` tag (`-` means absent). Real heights in the final column are verified in `LN-0.6`.

| Site | OSM element | Distance / bearing | OSM h / lv | Status today | Real height (to verify) |
| --- | --- | --- | --- | --- | --- |
| County Hall | `relation 1789966` (+ ways `23484161`, `23484134`) | 65 m / 52° | 45 m / 6 lv | Generic box | ~36 m eaves / 45 m dome |
| Westminster Bridge | `ways 216998718, 920237496` | 144–231 m / 222–244° | — | `conf: 1` (unbuilt) | 7 arches, 250 m span |
| London Eye | `way 204068874` | 184 m / 359° | 136.5 m | Built (`london_eye`) | 135 m |
| Shell Centre | `way 46250966` | 291 m / 43° | 107 m / 27 lv | Generic extrusion | 107 m |
| New Scotland Yard | `way 31117060` | 336 m / 288° | - / 7 lv | Generic extrusion | ~30 m |
| Portcullis House | `way 256497249` | 362 m / 261° | - / 7 lv | Generic extrusion | ~32 m (to chimneys) |
| Elizabeth Tower / Palace of Westminster | `way 123557148` + palace parts | 364 m / 251° | 96 m | Built (`big_ben`) | 96 m (Victoria Tower 98.5 m) |
| Golden Jubilee / Hungerford Bridges | `ways 4254121, 4254120, 4254123, 186931859, 151744359` | 401–612 m / 338–12° | — | No spec | ~320 m span, 28 m pylons |
| Ministry of Defence | `way 30656117` | 439 m / 305° | - / 10 lv | Generic extrusion | ~36 m |
| Royal Festival Hall | `way 5987419` | 478 m / 22° | - / 6 lv | Generic extrusion | ~28 m |
| Whitehall Court | `relation 5485985` | 507 m / 321° | - / 8 lv | Generic extrusion | ~42 m turrets |
| Banqueting House | `way 140470549` | 537 m / 305° | - / 3 lv | Generic extrusion | ~23 m |
| Hayward Gallery | `way 25913653` | 562 m / 31° | - / - | Generic extrusion | ~18 m |
| Foreign Office (FCDO) | `relation 78291` | 573 m / 281° | - / 4 lv | Generic extrusion | ~28 m |
| Supreme Court (Middlesex Guildhall) | `way 39811548` | 609 m / 255° | - / 4 lv | Generic extrusion | ~24 m |
| Horse Guards | `way 133153176` | 612 m / 302° | - / - | Generic extrusion | ~28 m clock turret |
| Lambeth Palace | `relation 1403938` | 685 m / 181° | - / 4 lv | Generic extrusion | ~24 m Morton's Tower |
| National Theatre | `relation 2023676` | 691 m / 33° | **6.5 m** / - | **Wrong OSM height** | ~35 m flytowers |
| Charing Cross Station | `way 27038418` | 727 m / 335° | - / - | Generic extrusion | ~32 m Embankment Place |
| Cleopatra's Needle | `way 297331784` | 745 m / 356° | 22 m | Generic extrusion | 21 m obelisk + base |
| Methodist Central Hall | `way 185101970` | 746 m / 255° | - / - | Generic extrusion | 67 m dome |
| Admiralty Arch | `relation 17074208` | 822 m / 311° | - / 6 lv | Generic extrusion | ~28 m |
| Nelson's Column | `way 150920358` | 876 m / 319° | - / - | Generic extrusion | 51.6 m |
| St Martin-in-the-Fields | `way 30734422` | 925 m / 327° | - / - | Generic extrusion | 56 m spire |
| Savoy Hotel & Theatre | `ways 95199889, 490638255` | 928–932 m / 354–357° | - / - | Generic extrusion | ~38 m |
| Somerset House | `way 372841786` | 1,010 m / 8° | **- / 2 lv** | **Under-height** | ~28 m river terrace |
| OXO Tower Wharf | `ways 25298098, 1449888762` | 1,066 m / 47° | 60 m / 8 lv | Generic extrusion | 67 m tower |
| South Bank Tower | `way 28815418` | 1,076 m / 53° | 155 m / 41 lv | Far/det extrusion | 155 m |
| Millbank Tower | `way 24553530` | 1,143 m / 202° | 118 m / 33 lv | Far/det extrusion | 118 m |
| One Blackfriars | `way 389881291` | 1,228 m / 56° | 163 m / 52 lv | Far extrusion | 163 m |
| Westminster Cathedral | `way 10810446` (far) | 1,517 m / 243° | - / - | Far extrusion | 83 m campanile |
| The Shard | `way 31110737` (far) | 2,318 m / 83° | 310 m / 95 lv | Built (`shard`) | 309.6 m |
| BT Tower | `way 5022282` (far) | 2,546 m / 329° | 188.4 m / 37 lv | Far extrusion | 188.4 m (177 m roof) |
| 20 Fenchurch St (Walkie-Talkie) | `way 201247295` (far) | 2,711 m / 67° | 160 m / 37 lv | Far extrusion | 160 m |
| 8 Bishopsgate | `way 1136851840` (far) | 2,835 m / 62° | **- / 51 lv** | **Missing height** | 204 m |
| Tower 42 | `way 166431059` (far) | 2,888 m / 59° | 183 m / 47 lv | Far extrusion | 183 m |
| 22 Bishopsgate | `way 717332347` (far) | 2,896 m / 61° | 278 m / 61 lv | Far extrusion | 278 m |
| The Leadenhall Building | `way 309413981` (far) | 2,913 m / 62° | 224.5 m / 48 lv | Far extrusion | 224.5 m |
| 30 St Mary Axe (Gherkin) | `way 4959489` (far) | 3,061 m / 63° | 180 m / 41 lv | Built (`st_mary_axe`) | 180 m |
| Heron Tower (110 Bishopsgate) | `way 96937598` (far) | 3,117 m / 59° | 230.1 m / 46 lv | Far extrusion | 230 m |
| Royal Albert Hall | `way 372860405` (far) | 4,007 m / 269° | - / - | Far extrusion | 41 m dome |
| One Canada Square | `way 5986754` (far) | 6,944 m / 87° | 235 m / 50 lv | Far extrusion | 235 m |

**To measure in `LN-0.4` (outside `london_detailed.osmb` or missing footprint/yaw):** National Gallery, Cenotaph, HM
Treasury, Queen Victoria Memorial, Tate Modern (Bankside + Blavatnik), Shakespeare's Globe, Millennium Bridge abutment
joins, Monument to the Great Fire, Bank of England, Royal Exchange, Mansion House, Lloyd's Building, 52 Lime Street
(The Scalpel), Barbican Towers, St Pancras Renaissance Hotel & Station, British Museum, Natural History Museum, Albert
Memorial, Battersea Power Station, Marble Arch, Wellington Arch, Strata SE1, St George Wharf Tower, One Nine Elms,
Newfoundland, Landmark Pinnacle, The O2, Old Royal Naval College (Greenwich), HMS Belfast.

## Selection and slots

`LandmarkSites.select` (`scripts/data/landmark_sites.gd:38`) keeps `6 / 12 / 18 / 22` extras by default and up to
`2 / 4 / 6 / 8` bridges in the remaining room under `MAX_BY_PRESET` (`10 / 16 / 22 / 26`), while `skyline: true` towers
use their own independent channel (`12 / 30 / 60 / 110` per preset, costing zero icon slots).

Raise `big_ben` in `scripts/data/location_data.gd:466` to `"ultra_registry_limit": 42, "ultra_total_limit": 50`
(matching Stockholm's pattern so Ultra shows 42 landmarks + 8 Thames bridges simultaneously).

| Tier | `skyline_priority` | Rows | First preset |
| --- | ---: | --- | --- |
| Primary | — | `big_ben` (Palace of Westminster & Elizabeth Tower) | All |
| 1 | 9 | `london_eye`, `shard`, `st_pauls`, `tower_bridge`, `county_hall`, `westminster_abbey` | Fast (6) |
| 2 | 7 | `st_mary_axe`, `buckingham_palace`, `waterloo_station`, `westminster_bridge` (bespoke), `hungerford_golden_jubilee` (bespoke), `trafalgar_square` (Nelson's Column + National Gallery + St Martin) | Balanced (12) |
| 3 | 5 | `portcullis_house`, `whitehall_horse_guards`, `royal_festival_hall`, `national_theatre`, `somerset_house`, `tower_of_london` | High (18) |
| 4 | 3 | `tate_modern`, `shakespeares_globe`, `millennium_bridge` (bespoke), `oxo_tower`, `whitehall_court`, `admiralty_arch`, `methodist_central_hall`, `lambeth_palace`, `cleopatras_needle`, `bt_tower`, `westminster_cathedral`, `battersea_power_station`, `lloyds_building`, `bank_junction`, `monument_london`, `st_pancras_station`, `british_museum`, `royal_albert_hall`, `natural_history_museum`, `marble_wellington_arches`, `o2_arena` | Ultra (up to 42) |
| Skyline | `skyline: true` | `LnTowerSpecs` (~28 towers across City of London, South Bank/Blackfriars/Nine Elms, and Canary Wharf) | All (independent channel) |

Notes:
- Bespoke bridges (`westminster_bridge`, `hungerford_golden_jubilee`, `millennium_bridge`) use `clear_path_m` /
  `span_m` and replace their `BridgeSpec` rows (`br_london_westminster_bridge` and `br_london_millennium_bridge` are
  removed or gated so nothing double-builds).
- Parametric Thames bridges (`Waterloo`, `Lambeth`, `Blackfriars`, `Southwark`, `London`, `Vauxhall`, `Chelsea`,
  `Albert`) fill the 8 bridge slots on Ultra in distance/tier order.

## Phase 0: foundations (`LN-0`)

- **LN-0.1 Baseline `london-r0`.** Run Set A (bundled centre), Set B (streamed close eyes), and
  `tools/capture_landmarks.gd` (day + `--night`) for all 10 existing London landmarks (`big_ben`, `tower_bridge`,
  `london_eye`, `st_pauls`, `shard`, `tower_of_london`, `buckingham_palace`, `westminster_abbey`, `st_mary_axe`,
  `waterloo_station`). Record triangle counts (`stats.tsv`) and which candidate eyes need shifting to clear footprints.
- **LN-0.2 Height & tag audit.** Run a scratch audit script over `london_detailed.osmb` and `london_far.osmb` to list
  every named building with missing height, `height=0`, or height disagreeing with `building:levels` by >40 % (starting
  from known bugs: National Theatre `h=6.5`, Somerset House `lv=2`, 8 Bishopsgate `h=-, lv=51`, Westminster Cathedral
  `h=-`, Royal Albert Hall `h=-`). Output table goes into `docs/london-landmark-sources.md`.
- **LN-0.3 Snapshot ring re-cut.** Re-cut `assets/osm_snapshots/london_ring1600.osmb` and `london_ring2500.osmb` using
  `tools/prepare_osm_snapshot.py` (or the ring-recut pipeline used in `BK-0.6`) so both carry complete highways and
  waterways instead of truncating at 800 highways; update `scripts/data/bundled_osm.gd` checksums and sizes.
- **LN-0.4 Live measurement pass.** One Overpass query (openstreetmap.fr or kumi mirror) for all sites listed under
  "To measure", saving centroid, long-axis bearing, bbox, `height` and `building:part` data as JSON inputs for
  `LN-0.6` (not bundled into the app).
- **LN-0.5 Reference photos.** Add London types to `tools/commons_refs.py` (or `tools/london_commons_refs.py`) and
  fetch front, quarter, aerial and night views into `visual-plan/refs/landmarks/<type>/` and city-wide references
  (Westminster Thames panorama, Whitehall, Trafalgar Square, South Bank, City skyline from Waterloo Bridge, Tower Bridge
  at dusk, Georgian/Belgravia terrace, Victorian mansion block, Canary Wharf, London Plane avenue, double-deck bus &
  black cab) into `visual-plan/refs/london/`. Vet every photo on a contact sheet and log CC/PD licences.
- **LN-0.6 Sources doc.** Write `docs/london-landmark-sources.md` (format of `docs/stockholm-landmark-sources.md` /
  `docs/bangkok-landmark-sources.md`) and append London entries to `docs/data-source-register.md`.
- **LN-0.7 Slot test.** Create `tests/london_landmarks_test.gd` pinning the preset tier table (Fast 6 / Balanced 12 /
  High 18 / Ultra 42 + 8 bridges + skyline channel), `radius_m` coverage, alias resolution, height bounds, 2–16 textured
  parts, and non-destructive `clear_m` around dense Westminster and City neighbours.

## Phase 1: batch wiring (`LN-1`)

Follow the Stockholm / Bangkok / Miami modular batch pattern so no file approaches 1,000 lines:

- `scripts/data/landmark_registry_london.gd` (`LandmarkRegistryLondon.entries()`, splitting into
  `scripts/data/london/ln_reg_westminster.gd`, `ln_reg_central.gd`, `ln_reg_outer.gd` as needed).
- `scripts/data/ln_tower_specs.gd` (`LnTowerSpecs`, pattern `NycTowerSpecs` / `BkTowerSpecs` with `skyline: true`,
  `skyline_priority`, `tower_spec`).
- `scripts/generation/landmarks/london/landmark_set_london.gd` (`LandmarkSetLondon.build`), registered in
  `scripts/data/landmark_registries.gd`.
- `scripts/generation/landmarks/london/landmark_ln_kit.gd`: shared London architectural kit (Portland-stone rusticated
  plinths, Corinthian/Ionic portico bays, mansard slate roofs with dormer runs & chimney pots, Gothic crocket pinnacles,
  cast-iron Thames balustrades, Victorian lamp standards).
- Keep the 10 existing London types' IDs and aliases intact (either upgrading them in place in `west_europe/` and
  `scripts/generation/`, or cleanly delegating from `LandmarkSetLondon` while preserving `landmark_catalog_test` and
  `landmark_list_test`).
- Reuse `LandmarkMesh`, `LandmarkMaterials`, `SkyKit`, `TowerSpec`, `LandmarkDetail`, `LandmarkWestKit`,
  `LandmarkBrKit`, `LandmarkLights`, `LandmarkTerrain`.

Done when `london_landmarks_test`, `landmark_catalog_test`, `landmark_placement_test`, `landmark_list_test`, and
`tools/check_class_size.sh` all pass with zero regressions on existing London landmarks.

## Phase 2: upgrade the 10 existing London landmarks (`LN-2`)

Audit every existing model against its `LN-0.5` reference photos on day + night comparison sheets
(`tools/landmark_compare_sheets.py`) and upgrade to the super-realistic bar:

1. **LN-2.1 Palace of Westminster & Elizabeth Tower (`big_ben`, `landmark_westminster*.gd`):**
   - Address the scorecard critique (*"Palace reads flat and dark from the low eye"*): brighten/warm the Anston
     limestone PBR albedo and add subtle stone-course contrast so the riverside facade catches low golden-hour sun
     instead of going muddy; deepen the river terrace wall, bay-window mullions, Gothic fleches, Victoria Tower crown
     flagpole and pinnacles; add the **Ayrton Light** glowing white-amber above the belfry at night, crisp opal clock
     dials with bright night emission and dark iron hands/tracery, and warm riverside `FLOOD_META` uplights along the
     entire 265 m Thames front.
2. **LN-2.2 London Eye (`landmark_london_eye.gd`):**
   - Refine the boarding pier, Jubilee Gardens concrete tension block, and capsule glazing contrast; add signature
     night lighting (`*Lamp` rim ring + capsule halo accents + subtle coloured/warm LED wash via `LandmarkLights`).
3. **LN-2.3 Buckingham Palace + Queen Victoria Memorial (`landmark_london_palaces.gd`):**
   - Fix the ~12° yaw alignment to match The Mall (`058°`, measured in `LN-0.4`); add the **Queen Victoria Memorial**
     (stepped white marble plinth, curved fountain basins, gilded Winged Victory angel at 25 m) in the forecourt circle;
     sharpen Aston Webb's Portland-stone east front, Royal Standard flag, and warm night floodlighting.
4. **LN-2.4 The Shard (`landmark_london_towers.gd`):**
   - Enhance the crystal-clear extra-white low-iron glass reflection/tint, sharper fracture vents between the eight
     leaning shards, top open crown ribs, internal lit office/hotel floor bands at night, crown uplight, and red
     aviation `HALO_META` beacons at 309.6 m.
5. **LN-2.5 30 St Mary Axe / The Gherkin (`landmark_london_towers.gd`):**
   - Sharpen the alternating dark-and-light helical sky-garden bands behind the diamond steel diagrid, glazed conical
     lens cap at 180 m, ground-level plaza arcade, and night internal spiral glow.
6. **LN-2.6 Tower Bridge (`landmark_tower_bridge.gd`):**
   - Verify bascule clearance and shoreline abutment joins against the Thames water datum; sharpen Cornish granite vs
     Portland stone contrast, Victorian Gothic turrets, blue-and-white suspension chains, and rich night chain-necklace
     `*Lamp` beads + tower floodlights.
7. **LN-2.7 St Paul's Cathedral (`landmark_london_heritage.gd`):**
   - Verify triple-dome silhouette (peristyle colonnade, Stone Gallery, lead dome ribs, Golden Gallery, lantern, gilt
     ball & cross at 111 m), twin Baroque west towers, and warm Portland-stone night floodlighting so the dome reads
     clearly across the Thames from Bankside and Waterloo Bridge.
8. **LN-2.8 Westminster Abbey (`landmark_london_abbey.gd`):**
   - Check Hawksmoor's twin west towers, Henry VII Lady Chapel east fan-vaulted bay windows, flying buttresses, north
     rose window, and warm night uplighting.
9. **LN-2.9 Tower of London (`landmark_tower_of_london.gd`):**
   - Verify White Tower corner turrets & weathervanes, concentric curtain walls, Traitors' Gate on the Thames, moat
     step, and night floodlighting.
10. **LN-2.10 Waterloo Station (`landmark_waterloo*.gd`):**
    - Verify Victory Arch, glazed barrel-vault train sheds, night concourse glow, and seamless clearing against
      neighbouring South Bank blocks.

## Phase 3: Batch A — Westminster, Whitehall & South Bank foreground (`LN-3`)

Every landmark here lies within **1,200 m** of the bundled preset eye (`51.5018, -0.1196`) and transforms the primary
London experience directly.

| ID | Type / File | Site | Must-have real-life features | Target tris |
| --- | --- | --- | --- | ---: |
| LN-3.1 | `county_hall` (`ln_county_hall.gd`) | `relation 1789966` (65 m) | Ralph Knott's Edwardian Baroque crescent: rusticated granite plinth, giant curved Portland-stone Ionic colonnade facing the Thames, steeply pitched red-tile roof with tall stone chimneys & dormer windows, central fleche, warm night flood | ~65,000 |
| LN-3.2 | `portcullis_house` (`ln_portcullis_house.gd`) | `way 256497249` (362 m) | Hopkins Architects: 14 dark-bronze roof chimneys, pleated bronze pitched roof, dark-bronze framed bay windows over Portland-stone piers along Victoria Embankment | ~40,000 |
| LN-3.3 | `whitehall_horse_guards` (`ln_whitehall.gd`) | `ways 133153176, 140470549`, `rel 78291` | Horse Guards (William Kent's Palladian Portland-stone front, central clock cupola, archway onto Horse Guards Parade), Banqueting House (Inigo Jones's Palladian double-order facade), Cenotaph (Lutyens's stepped Portland-stone pylon with flags on Whitehall) | ~75,000 |
| LN-3.4 | `whitehall_court` (`ln_whitehall_court.gd`) | `relation 5485985` (507 m) | Iconic riverside skyline behind Victoria Embankment Gardens: French-château Portland stone, steeply pitched slate pavilions, conical corner turrets & tall chimneys | ~55,000 |
| LN-3.5 | `trafalgar_square` (`ln_trafalgar_square.gd`) | `ways 150920358, 30734422` + National Gallery (`LN-0.4`) | Nelson's Column (51.6 m fluted granite Corinthian column, bronze capital & Nelson statue, stepped plinth, four Landseer bronze lions), twin granite fountains, National Gallery (Wilkins's long Portland-stone Corinthian portico, central dome & side pepper-pot domes), St Martin-in-the-Fields (Gibbs's portico & 56 m tiered spire) | ~110,000 |
| LN-3.6 | `admiralty_arch` (`ln_admiralty_arch.gd`) | `relation 17074208` (822 m) | Aston Webb's curved Edwardian Portland-stone screen across The Mall with triple central ceremonial arches & Latin frieze | ~35,000 |
| LN-3.7 | `royal_festival_hall` (`ln_south_bank_arts.gd`) | `way 5987419` (478 m) | Grade I modernist Portland-stone & glass riverside facade, raised copper-clad curved auditorium roof ("egg in a box"), cantilevered riverside terraces | ~45,000 |
| LN-3.8 | `national_theatre` (`ln_national_theatre.gd`) | `relation 2023676` (691 m, fixes `h=6.5` bug!) | Denys Lasdun's iconic Brutalist horizontal concrete terraces, twin stepped 35 m flytowers, glazed foyers & warm night terrace lighting | ~55,000 |
| LN-3.9 | `somerset_house` (`ln_somerset_house.gd`) | `way 372841786` (1,010 m, fixes `lv=2` bug!) | William Chambers's grand 180 m Neoclassical Portland-stone river front, rusticated water-gate arcade above Victoria Embankment, central pediment & dome, Edmond J. Safra fountain courtyard | ~65,000 |
| LN-3.10 | `oxo_tower` (`ln_oxo_tower.gd`) | `ways 25298098, 1449888762` (1,066 m) | Art Deco white-and-brick wharf block crowned by the 67 m stepped tower with vertical backlit red-and-white **"OXO"** window cutouts on all four faces | ~30,000 |
| LN-3.11 | `methodist_central_hall` (`ln_central_hall.gd`) | `ways 185101970, 39811548` (609–746 m) | Beaux-Arts Portland-stone hall with massive 67 m lead-clad ribbed dome & lantern beside Westminster Abbey; optional companion Middlesex Guildhall (UK Supreme Court) | ~45,000 |
| LN-3.12 | `lambeth_palace` (`ln_lambeth_palace.gd`) | `relation 1403938` (685 m) | Tudor red-brick Morton's Tower gatehouse with twin octagonal turrets, Great Hall & chapel overlooking the Thames opposite Westminster | ~35,000 |
| LN-3.13 | `cleopatras_needle` (`ln_cleopatras_needle.gd`) | `way 297331784` (745 m) | 21 m pink granite Egyptian obelisk on stepped pedestal flanked by two bronze sphinxes on Victoria Embankment | ~12,000 |

## Phase 4: Batch B — Central, East & West London major icons (`LN-4`)

Iconic London landmarks from 1.2 km to 9.8 km, visible on skyline panoramas and in streamed close-up exploration:

| ID | Type / File | Area / Site | Must-have real-life features | Target tris |
| --- | --- | --- | --- | ---: |
| LN-4.1 | `tate_modern` (`ln_tate_modern.gd`) | Bankside (`LN-0.4`, ~1.7 km) | Giles Gilbert Scott's monumental brown-brick Bankside Power Station, tall slotted cathedral windows, 99 m fluted central brick chimney with lit Swiss-light glass crown, horizontal glass lightbeam roof, and Herzog & de Meuron's twisted brick-lattice Blavatnik pyramid | ~70,000 |
| LN-4.2 | `shakespeares_globe` (`ln_globe.gd`) | Bankside (`LN-0.4`, ~1.9 km) | 20-sided white lime-plaster & dark oak timber-framed open-air amphitheatre with pitched thatched roof | ~30,000 |
| LN-4.3 | `bank_junction` (`ln_bank_junction.gd`) | City (`LN-0.4`, ~2.5 km) | Royal Exchange (eight-column Corinthian portico, sculpted pediment, bell tower), Bank of England (Soane's blind Portland-stone screen wall & Herbert Baker's stepped upper block), Mansion House (Palladian portico) | ~85,000 |
| LN-4.4 | `monument_london` (`ln_monument.gd`) | City (`LN-0.4`, ~2.5 km) | Wren's 61.5 m fluted Portland-stone Doric column, viewing cage, and gilded flaming urn | ~22,000 |
| LN-4.5 | `lloyds_building` (`ln_lloyds.gd`) | City (`LN-0.4`, ~2.9 km) | Richard Rogers's high-tech stainless-steel "inside-out" building: six external cylindrical service towers with exposed ducts/lifts, glazed barrel-vaulted atrium roof, roof cranes | ~85,000 |
| LN-4.6 | `st_pancras_station` (`ln_st_pancras.gd`) | King's Cross (`LN-0.4`, ~3.0 km) | George Gilbert Scott's red-brick Victorian Gothic Renaissance Hotel (82 m clock tower, spires, pointed gables) fronting Barlow's 73 m single-span blue-grey iron-and-glass arched train shed | ~95,000 |
| LN-4.7 | `british_museum` (`ln_british_museum.gd`) | Bloomsbury (`LN-0.4`, ~2.0 km) | Robert Smirke's 44-column Ionic Portland-stone colonnade, sculpted pediment, forecourt railings, and Great Court tessellated glass dome | ~60,000 |
| LN-4.8 | `westminster_cathedral` (`ln_westminster_cathedral.gd`) | Victoria (`way 10810446`, 1.5 km) | Neo-Byzantine horizontal red-brick & Portland-stone striped nave, recessed entrance arch, and slender 83 m St Edward's Campanile with copper dome | ~55,000 |
| LN-4.9 | `battersea_power_station` (`ln_battersea.gd`) | Nine Elms (`LN-0.4`, ~2.5 km) | Iconic Grade II* Art Deco brick twin turbine halls with four 101 m white fluted concrete chimneys rising from corner wash-towers, lit at night | ~65,000 |
| LN-4.10 | `bt_tower` (`ln_bt_tower.gd`) | Fitzrovia (`way 5022282`, 2.5 km) | 188.4 m cylindrical glazed telecom tower: 16-storey curtain-wall shaft, open microwave-dish gallery, revolving restaurant drum with illuminated LED info-band, lattice mast | ~45,000 |
| LN-4.11 | `royal_albert_hall` (`ln_royal_albert_hall.gd`) | South Kensington (`way 372860405`, 4.0 km) | Elliptical red-brick & terracotta rotunda, continuous mosaic frieze, 41 m glazed wrought-iron dome; companion **Albert Memorial** gilded Gothic canopy across Kensington Gore | ~75,000 |
| LN-4.12 | `natural_history_museum` (`ln_nhm.gd`) | South Kensington (`LN-0.4`, ~3.9 km) | Waterhouse's Romanesque blue-grey & buff terracotta front, twin central portal towers, flanking corner pavilions & steeply pitched slate roofs | ~70,000 |
| LN-4.13 | `marble_wellington_arches` (`ln_arches.gd`) | Hyde Park (`LN-0.4`, ~2.6 km) | Marble Arch (Carrara marble triple triumphal arch) and Wellington Arch (Corinthian arch crowned by bronze Quadriga) | ~35,000 |
| LN-4.14 | `o2_arena` (`ln_o2_arena.gd`) | Greenwich Peninsula (`LN-0.4`, ~9.8 km) | 365 m diameter white PTFE cable-net dome suspended from twelve 100 m yellow inclined steel masts (`radius_m: 12000`) | ~40,000 |

## Phase 5: Batch C — London Skyline Towers (`LN-5`)

All skyline towers live in `scripts/data/ln_tower_specs.gd` (`skyline: true`, independent channel of 12/30/60/110 per
preset — zero icon slots consumed) using `SkyKit` / `TowerSpec` plus bespoke overrides where the geometry is
non-prismatic.

Work in three steps:

1. **Height fixes first:** correct every missing/wrong height from `LN-0.2` (notably **8 Bishopsgate** `way 1136851840`,
   currently `h=-, lv=51`, real height `204 m`; **Sky Gardens** Nine Elms `way 498824923`, `h=-, lv=36`).
2. **City of London Eastern Cluster (~2.7–3.1 km, bearings 59°–67° from Westminster — the signature east skyline):**
   - **22 Bishopsgate** (`278 m`, faceted glass prism, stepped top)
   - **The Leadenhall Building / "Cheesegrater"** (`224.5 m`, 10° raked south-facing glass wedge + external steel
     megastructure diagrid + yellow-accented north core — bespoke geometry via `SkyKit` / dedicated builder arm)
   - **20 Fenchurch Street / "Walkie-Talkie"** (`160 m`, top-heavy flaring curved facade with sun-louvre fins and
     glazed triple-height Sky Garden crown — bespoke curved-loft tower)
   - **110 Bishopsgate / Heron Tower** (`230 m`, stacked triple-height glass "villages", stainless steel diagrid, 28 m
     spire)
   - **52 Lime Street / "The Scalpel"** (`190 m`, sharply angled triangular metallic-and-glass bevel)
   - **8 Bishopsgate** (`204 m`, stepped cantilevered glass boxes)
   - **Tower 42** (`183 m`, cantilevered three-leaf chevron core with vertical steel ribs)
   - **Willis Building** (`125 m`, three stepped curved glass shells)
   - **Barbican Towers** (`Cromwell`, `Lauderdale`, `Shakespeare` — three `123 m` brutalist fluted-concrete triangular
     towers with rounded balcony projections, `ways 34038684, 34038685`)
3. **South Bank / Blackfriars / Nine Elms & Canary Wharf:**
   - **South Bank / Blackfriars / Nine Elms (1.0–2.5 km):** **One Blackfriars** (`163 m` curved vase-shaped glass
     silhouette), **Shell Centre** (`107 m` Portland-stone slab tower at 291 m), **South Bank Tower** (`155 m`),
     **Millbank Tower** (`118 m`), **St George Wharf Tower** (`181 m` cylindrical with helical wind-turbine crown),
     **Strata SE1** (`148 m` razor crown with three roof wind turbines), **One Nine Elms** (`200 m` & `161 m`).
   - **Canary Wharf (~6.9–7.3 km, bearing 87°–90°, `radius_m: 9500`):** **One Canada Square** (`235 m` stainless-steel
     cladding, pyramidal roof, flashing red aircraft warning beacon via `HALO_META`), **Landmark Pinnacle** (`233 m`),
     **Newfoundland** (`220 m` diamond-grid diagrid), **8 Canada Square / HSBC** (`200 m`), **25 Canada Square /
     Citigroup** (`200 m`), **One Park Drive** (`205 m` cylindrical terracotta/concrete grid), **1 Churchill Place /
     Barclays** (`156 m`).

Add a clearance test in `tests/london_landmarks_test.gd` (pattern `nyc_skyscraper_sites_test`) verifying no tower's
`clear_m` erases a neighbouring City or Canary Wharf tower.

## Phase 6: Thames Bridges (`LN-6`)

The Thames bridges define London's river foreground and mid-ground.

- **LN-6.1 Bespoke Westminster Bridge (`ln_westminster_bridge.gd`, ~45,000 tris):**
  - Replaces the unbuilt `conf: 1` `br_london_westminster_bridge` row (which currently causes the scorecard's *"bridge
    is plain stone, not green-and-red iron"* defect).
  - Seven elliptical cast-iron arches (`250 m` overall, `26 m` wide) painted **Parliament green** (matching the House of
    Commons leather benches) with gilt trefoil Gothic spandrel tracery, granite river piers with cutwaters, ornamental
    Gothic parapets, and ornate cast-iron globe lamp standards (`*Lamp` lit warm at night).
- **LN-6.2 Bespoke Hungerford & Golden Jubilee Bridges (`ln_hungerford_bridge.gd`, ~55,000 tris):**
  - Directly visible 400–600 m north of the preset eye beside the London Eye.
  - Central dark-grey steel lattice-truss railway bridge (Charing Cross line on Hawkshaw's brick cylinder piers) flanked
    closely on both sides by the twin **Golden Jubilee** cable-stayed footbridges with outward-leaning white steel
    pylons, fan stay cables, timber/steel decks, and crisp white night deck lighting.
- **LN-6.3 Bespoke Millennium Bridge (`ln_millennium_bridge.gd`, ~40,000 tris):**
  - Replaces the unbuilt `st: "lateral"` `br_london_millennium_bridge` row (`bridge_specs_pilot.gd:114`).
  - Foster + Arup's `325 m` (`81 / 144 / 108 m`) shallow lateral-suspension steel "blade of light": slim `4 m`
    aluminium deck, two sculptural concrete-and-steel Y-arm river piers, lateral steel cables sweeping below deck level
    with transverse steel arms, and continuous white handrail LED ribbon at night.
- **LN-6.4 Verify & tune the 11 existing `conf: 2` Thames bridges (`bridge_specs_pilot.gd` & `bridge_specs_west_europe.gd`):**
  - **Waterloo Bridge** (pale Portland-stone-clad concrete five-span box girder), **Blackfriars Bridge** (red-and-cream
    iron arches + red granite piers), **Southwark Bridge** (green-and-yellow steel arches), **London Bridge** (clean
    three-span concrete box girder), **Lambeth Bridge** (red-painted five-arch steel — matching House of Lords — with
    stone pineapple obelisks at both ends), **Vauxhall Bridge** (five steel arches with bronze pier statues),
    **Chelsea Bridge** (white/red self-anchored suspension), **Albert Bridge** (signature pastel pink, blue and white
    Ordish-Lefeuvre cable-stayed ironwork with 4,000 warm night bulbs — candidate for a short bespoke skin/lamp upgrade),
    **Battersea**, **Putney** and **Hammersmith** bridges.
  - Set `tier` priorities so Ultra's 8 parametric bridge slots go to Waterloo, Lambeth, Blackfriars, Southwark, London,
    Vauxhall, Chelsea and Albert (while Tower Bridge, Westminster, Hungerford/Golden Jubilee and Millennium render via
    their bespoke builders).
- Validation: `bridge_specs_test`, `bridge_param_test`, `bridge_select_test`, `bridge_connection_test`,
  `bridge_arches_test`.

## Phase 7: London city fabric (`LN-7`)

Files: new `scripts/generation/architecture_cities_london.gd` (called from `building_era.gd:424` via a one-line
dispatch), `scripts/generation/architecture_cities_europe.gd`, `scripts/generation/city_styles.gd`,
`scripts/render/city_detail.gd`, `scripts/generation/roof_clutter.gd`, `scripts/generation/tower_looks.gd`,
`docs/architecture-styles.md`, `tests/architecture_test.gd`.

- **LN-7.1 New London architectural rows:**
  - `london_portland`: Edwardian Baroque / Neoclassical pale **Portland stone** (`#DFD9C9`, `#D6CFC0`, `#E5E0D2`) with
    rusticated ground floors, giant pilasters/string courses, recessed sash bays, pitched Welsh-slate mansards with
    dormers — for **Whitehall, Westminster, Strand, Aldwych, Bank/City historic, Regent Street, Pall Mall**.
  - `london_warehouse`: Victorian industrial **stock/dark-red brick** warehouses with arched multi-pane cast-iron
    windows, loading-bay vertical slots, flat/pitched slate roofs — for **Southwark, Borough, Shad Thames, Clerkenwell,
    Shoreditch, Wapping**.
  - `london_brutalist`: board-marked raw concrete slabs & cantilevered walkways — for **Barbican & South Bank** post-war
    fabric.
  - Refine existing `london` (Victorian stock/red brick terraces), `london_georgian` (soot-warmed brown brick, hidden
    parapet roofs, black iron balconettes), `london_stucco` (Cubitt cream-white stucco porticos), `london_mansion` (red
    terracotta/brick mansion blocks), `london_council` and `london_modern` (City/Canary Wharf blue-grey/clear low-e
    curtain wall).
- **LN-7.2 Expand `city_styles.gd` London districts (from 6 to ~20):**
  - Keep existing: Belgravia (`london_stucco`), Kensington (`london_stucco`), Notting Hill (`london_stucco`), Bloomsbury
    (`london_georgian`), Canary Wharf (`london_modern`), the City core (`london_modern`).
  - Add measured district circles: **Whitehall & Westminster** (`london_portland`), **Strand, Aldwych & Holborn**
    (`london_portland`), **Mayfair & St James's** (`london_georgian` / `london_portland`), **Regent St & Piccadilly**
    (`london_portland`), **Soho & Covent Garden** (`london_georgian` + dense shopfronts), **Pimlico** (`london_stucco`),
    **Marylebone & Fitzrovia** (`london_mansion`), **South Bank** (`london_modern` / `london_brutalist`), **Southwark &
    Borough** (`london_warehouse`), **Shad Thames & Bermondsey** (`london_warehouse`), **Clerkenwell & Shoreditch**
    (`london_warehouse`), **Barbican** (`london_brutalist`), **Greenwich** (`london_georgian`).
  - Add `"london"` to `FAR_DISTRICT_CITIES` so the City, Canary Wharf, Westminster Portland stone and Kensington stucco
    read accurately even in the far layer.
- **LN-7.3 `london_rule` in `architecture_cities_london.gd`:**
  - Because 55 % of detailed London buildings are `building=yes`, decide by district first, then footprint area,
    levels, `start_date` and roof shape so large civic blocks in Westminster/Whitehall become `london_portland` instead
    of generic brick, terraced houses keep bay windows & Welsh slate, and Victorian pubs/high streets get dark-lacquer
    shopfronts (`SHOP_DARK` greens, oxblood, navy) with striped awnings.
- **LN-7.4 Roofscape & relief cues:**
  - Terracotta chimney pot clusters on `london` / `london_georgian` / `london_mansion` roofs in `RoofClutter`; slate
    mansards with dormer windows on `london_portland`.
- **LN-7.5 Detail budget (`CityDetail.CITIES`):**
  - Add `"london"` to `CityDetail.CITIES` (`scripts/render/city_detail.gd:18`, bump `VERSION`), giving High `450 m` /
    Ultra `900 m` roofline detail rings and `14,000` extruded buildings on desktop Ultra; benchmark with
    `tools/build_bench.gd` to confirm build time and peak memory stay within Stockholm/Bangkok figures.

Validation: `architecture_test`, `city_detail_test`, `roof_clutter_test`, `facade_relief_test`, `party_walls_test`.

## Phase 8: Thames water, embankments, vessels, parks & atmosphere (`LN-8`)

- **LN-8.1 Thames water & embankments (`water_surface.gd`):**
  - Tune the Thames estuary box (`51.43..51.57, -0.25..0.12`) to the real tidal Thames's silty olive-brown-grey colour
    with subtle tidal current shimmer (fixing the scorecard's *"river colour ... remain simplified"* note), and verify
    the granite Victoria & Albert Embankment quay walls, steps and 17 mapped piers sit cleanly above the water datum
    without floating gaps.
- **LN-8.2 Thames vessels (`scripts/generation/vessels/`):**
  - Add London river craft beside existing harbour boats: **Thames Clippers / Uber Boat** sleek white-and-blue high-speed
    catamarans, two-deck **Thames sightseeing riverboats**, and moored historic riverside ships (**HMS Belfast** grey
    cruiser silhouette near Tower Bridge, **Tattershall Castle** paddle-steamer pub at `way 31200563`, 361 m from the
    preset eye!).
- **LN-8.3 London trees & Royal Parks (`tree_species.gd`, `heritage_zones.gd`):**
  - Add a `"london"` tree mix (`plane 0.55`, `lime 0.18`, `oak 0.15`, `birch 0.07`, `willow 0.05` along water) so
    Victoria Embankment, Parliament Square, St James's Park, Green Park and Hyde Park are lined with tall, mottled-bark
    **London Planes** (`Platanus × acerifolia`) rather than generic European mixes.
  - Keep **Parliament Square**, **Horse Guards Parade** (`way 4256958`) and **Trafalgar Square** clear of stray
    procedural trees via `tree_rect`.
- **LN-8.4 Maritime British atmosphere (`atmosphere_rig.gd`, `haze_rig.gd`):**
  - Verify London's UTC+0 (GMT) / BST solar clock and tune temperate maritime aerial perspective: soft silver-blue
    horizon haze that separates Westminster foreground, Waterloo/St Paul's midground, and the City/Canary Wharf
    silhouettes cleanly without washing out golden-hour Portland stone.

Validation: `coastal_water_test`, `far_water_palette_test`, `vessel_models_test`, `canopy_vegetation_test`,
`tree_lod_test`, `sky_test`, `haze_test`.

## Phase 9: London streets, vehicles & transit (`LN-9`)

- **LN-9.1 Red Double-Decker Bus (`scripts/generation/vehicles/`):**
  - Build a dedicated **London double-decker bus** model (New Routemaster / TfL red `#C8102E`, curved swept front
    windscreen, two tiers of dark-tinted passenger windows, rear staircase glazing, warm lit interior cabins at night)
    and select it in `TransitVehicles` for `"london"` bus stops (replacing the single-deck `CarModel "bus"`).
- **LN-9.2 Black cabs & UK fleet (`car_fleet.gd`):**
  - Verify `cab_london` proportion, amber roof `"TAXI"` lamp at night, and raise taxi share slightly in Central London
    (Westminster, Whitehall, Strand, City) so black cabs and red double-deckers immediately anchor street-level frames.
- **LN-9.3 Iconic London street furniture (`street_furniture.gd` `"uk"` / `"london"` kit):**
  - **K6 Red Telephone Box** (Giles Gilbert Scott's domed red cast-iron booth with gridded glass panes, lit warmly at
    night) at mapped `amenity=telephone` nodes and heritage street corners.
  - **Royal Mail Red Pillar Box** at `amenity=post_box` nodes.
  - **London Underground Roundel** (red ring, blue bar, white disc on a dark pole, softly backlit at night) at mapped
    `railway=subway_entrance` nodes (6 already exist in `london_detailed.osmb`).
  - **Victorian Thames Embankment Dolphin Lamps** (cast-iron entwined-dolphin standards with opal globe lanterns) along
    Victoria & Albert Embankments and Queen's Walk.
  - Black cast-iron spearhead railings around Georgian squares and parks.
- **LN-9.4 Road markings & surface rail (`road_markings.gd`, `train_specs.gd`):**
  - Confirm left-hand traffic driving and bus-stop orientation; verify British white zig-zag zebra/pelican crossing
    markings, double-yellow kerb lines, and red bus lanes.
  - Verify `TrainSpecs` UK EMUs (`london_blue`, `london_grey`, `london_white`) on the Charing Cross / Waterloo /
    Blackfriars viaduct approaches (`london_detailed.osmb` has 370 `railway=rail` ways!), and confirm brick railway
    viaduct arches (`rail_builder.gd`) render cleanly across Southwark and Waterloo.

Validation: `car_fleet_test`, `bus_stop_test`, `street_furniture_test`, `road_markings_test`, `train_test`,
`rail_viaduct_test`.

## Phase 10: Night lighting (`LN-10`) & review rounds (`LN-11`)

- **LN-10 Night lighting (`LandmarkLights`, `--preset=3`):**
  - Tune every London landmark, bridge and skyline tower together in one dedicated night pass:
    - **Palace of Westminster:** warm amber flood wash along the Thames front, glowing opal clock dials on Elizabeth
      Tower, lit Ayrton Light lantern.
    - **London Eye:** luminous white/blue/purple LED rim & capsule glow reflecting on the Thames.
    - **Thames Bridges:** Westminster Bridge warm Victorian globe lamps + green arch uplights; Hungerford/Golden Jubilee
      crisp white stay-cable & deck lights; Millennium Bridge continuous white handrail ribbon; Tower Bridge warm
      suspension-chain necklace & Gothic tower floods; Albert Bridge 4,000-bulb pastel necklace.
    - **Cultural & Civic:** County Hall, National Gallery, Nelson's Column, Somerset House, St Paul's dome, Westminster
      Abbey, Buckingham Palace & Queen Victoria Memorial warm architectural floods; National Theatre flytower uplights;
      **OXO Tower** glowing red/white `"OXO"` letters.
    - **Skyline:** The Shard glass spire + red aviation `HALO_META` beacons; 30 St Mary Axe helical lit bands;
      Leadenhall external truss uplights; Walkie-Talkie lit Sky Garden crown; **One Canada Square** iconic flashing red
      pyramidal beacon; BT Tower illuminated crown band; Battersea Power Station uplit white chimneys.
    - **West End screens:** enable `screens` relief on Piccadilly Circus / Leicester Square / Oxford Street commercial
      fronts.
- **LN-11 Review rounds, scorecard, docs & performance:**
  - Capture rounds `london-r1`…`london-rN` into `visual-plan/reviews/london-rN-<date>/` at the frozen eyes. Lay every
    landmark's day & night model sheet beside its Wikimedia Commons reference photo (`tools/landmark_compare_sheets.py`)
    and beside an in-world eye; log mismatches, fix, and recapture.
  - Update `docs/fidelity-scorecard.md` (aiming to move London from `recognisable` -> `photorealistic` / highest house
    grade), `docs/architecture-styles.md`, `docs/london-landmark-sources.md`, and README lists.
  - Performance: `tools/perf_baseline.gd` and `tools/build_bench.gd` on London at presets 2 and 3 (cold, cached, fly),
    checking frame time at Westminster Bridge and Waterloo Bridge eyes where the highest triangle count is in view; run
    `lod_test`, `memory_budget_test`, `impostor_test`, `landmark_ultra_lod_test`.

## Captures and eyes

Two capture sets per round (bundled snapshot vs streamed close eyes):

**Set A — bundled Westminster / Thames centre (`--keep_centre`, uses `london_*.osmb`):**
```
tools/godot_bg.sh --path . --script tools/capture_presets.gd --position 4000,4000 -- --tag=london-rN
  --preset=3 --pin=51.5018,-0.1196 --places=london --times=golden,noon,night,late,roofs --keep_centre
  --looks="<Set A eyes>"
```

**Set B — streamed close eyes across London (no `--keep_centre`, live Overpass cached after first run):** same command
with `--tag=london-rN-close` and Set B eyes.

**Model sheets:** `tools/capture_landmarks.gd --types=<types> --tag=ln_lm_rN` (day and `--night`), then
`python3 -I tools/landmark_compare_sheets.py --tag=ln_lm_rN`.

Candidate eyes (verify clear of footprints in `LN-0.1`, then freeze; format `lat,lon,height_m,bearing,pitch`):

| Set | Eye | Candidate | Shows |
| --- | --- | --- | --- |
| A | Preset vantage (Queen's Walk) | `51.5018,-0.1196,8.0,258,3` | Palace of Westminster, Big Ben, Westminster Bridge, Thames |
| A | Westminster Bridge mid-span (north side) | `51.5009,-0.1218,12,268,6` | Big Ben, Portcullis House, Whitehall, Parliament front |
| A | Westminster Bridge looking NE | `51.5009,-0.1218,12,30,4` | County Hall, London Eye, Golden Jubilee Bridges, Shell Centre |
| A | Victoria Embankment looking south | `51.5038,-0.1233,1.7,192,6` | Big Ben, Westminster Bridge, County Hall, dolphin lamps, London Planes |
| A | Golden Jubilee Bridge mid-span east | `51.5060,-0.1202,14,175,2` | London Eye, County Hall, Big Ben, Westminster Bridge |
| A | Golden Jubilee Bridge looking NE | `51.5060,-0.1202,14,65,2` | Waterloo Bridge, Somerset House, Royal Festival Hall, National Theatre, City skyline |
| A | Trafalgar Square south terrace | `51.5076,-0.1281,2.0,350,8` | Nelson's Column, fountains, National Gallery, St Martin-in-the-Fields |
| A | Whitehall looking south | `51.5048,-0.1263,1.7,188,4` | Horse Guards, Banqueting House, Cenotaph, Big Ben in distance, red bus & black cab |
| A | Roof-height Thames panorama | `51.5018,-0.1196,150,55,-8` | South Bank, Waterloo, St Paul's, The Shard, City cluster, Canary Wharf |
| B | Waterloo Bridge mid-span east | `51.5085,-0.1169,14,72,2` | St Paul's, OXO Tower, One Blackfriars, The Shard, City cluster |
| B | Millennium Bridge south approach | `51.5082,-0.0987,2.0,2,8` | Millennium Bridge framing St Paul's Cathedral |
| B | Bankside looking south-west | `51.5082,-0.0995,2.0,195,8` | Tate Modern brick facade, chimney, Blavatnik pyramid & Shakespeare's Globe |
| B | Tower Bridge south-west embankment | `51.5046,-0.0792,2.0,55,6` | Tower Bridge, Tower of London, HMS Belfast |
| B | The Mall approaching Buckingham Palace | `51.5026,-0.1386,2.0,238,4` | Queen Victoria Memorial, Buckingham Palace east front, St James's trees |
| B | City of London (Bank Junction) | `51.5133,-0.0890,2.0,75,12` | Royal Exchange, Bank of England, Leadenhall, Gherkin, Walkie-Talkie |
| B | Canary Wharf (Westferry / Cabot Sq) | `51.5050,-0.0265,2.0,88,18` | One Canada Square, HSBC, Citigroup, Newfoundland |
| B | South Kensington (Exhibition / Kensington Gore) | `51.5021,-0.1774,2.0,180,8` | Royal Albert Hall & Albert Memorial |

## Order and size

1. **Phase 0 + Phase 1 + Phase 2 (`LN-0`, `LN-1`, `LN-2`) + `LN-6.1` (Westminster Bridge) + `LN-3.1` (County Hall).**
   Immediately resolves every defect called out in `docs/fidelity-scorecard.md` for the London preset vantage.
2. **Rest of Phase 3 (`LN-3.2`–`LN-3.13`) and `LN-6.2`–`LN-6.3` (Hungerford/Golden Jubilee & Millennium Bridges).**
   Completes the entire Westminster–Whitehall–Trafalgar–South Bank–St Paul's foreground.
3. **Phase 5 (`LN-5` Skyline Towers) + Phase 4 (`LN-4` Major Icons).** Makes the City of London, Bankside, Canary
   Wharf, St Pancras, Kensington and Battersea skylines unmistakable from every direction.
4. **Phase 7 (`LN-7` City Fabric) + Phase 8 (`LN-8` Thames/Trees/Vessels) + Phase 9 (`LN-9` Double-decker bus & street
   furniture).** Brings the streets between landmarks up to the same bar.
5. **Phase 10–11 (`LN-10` Night pass, `LN-11` Review rounds, scorecard, perf).**
6. Every phase ends with its tests passing and a capture round, so work can stop or ship cleanly after any phase.

## Open decisions

| Decision | Recommendation |
| --- | --- |
| Raise `big_ben` `ultra_registry_limit` / `ultra_total_limit` to `42 / 50` | Yes — matches Stockholm (`48 / 56`) so Ultra shows both foreground Westminster/South Bank icons and 8 Thames bridges |
| Add `"london"` to `CityDetail.CITIES` (`LN-7.5`) | Yes — after `LN-7.1`–`LN-7.3`, if `build_bench.gd` stays within Stockholm/Bangkok time and memory budgets |
| Re-cut `london_ring1600.osmb` and `london_ring2500.osmb` (`LN-0.3`) | Yes — both currently truncate at 800 highways |
| Add a second London `PresetViews` vantage (e.g. Waterloo Bridge or Tower Bridge) & re-bake `assets/preset_thumbs/london.jpg` | Only on explicit user request |
| Heathrow / London City Airport terminals | Out of scope (handled by the separate capital-airports pipeline) |

## Verification

- Headless tests in the background after each phase:
  `tools/run_tests.sh landmark london bridge architecture roof facade canopy tree water vessel car_fleet street train rail`
  (or individual tests via `tools/godot_bg.sh --headless --path . --script tests/<name>_test.gd`). Treat any
  `SCRIPT ERROR:` as a failure even on exit code 0.
- `tools/check_class_size.sh` after every added or edited class under `scripts/`.
- `tools/godot_bg.sh --headless --path . --script tests/host_policy_test.gd` after any data/reference script change.
- Windowed tests (`tests/screenshot_test.gd`, `tests/world_cache_test.gd`) batched once at the end, in the background.
- **Done means:** every existing and new London landmark matches its Wikimedia Commons reference photo in silhouette,
  proportion, material and night lighting; Westminster, Hungerford/Golden Jubilee and Millennium bridges render as
  bespoke structures; the City of London, South Bank and Canary Wharf skylines stand at true heights; London streets
  show Portland stone, brick/stucco districts, red double-decker buses, black cabs, London Planes and Thames vessels;
  all listed tests and `check_class_size.sh` pass; and performance stays within budget of `london-r0`.
