# Plan: Make Turku Super-Realistic — Landmarks, Major Buildings, and City

> Tracker in the house style of `PLAN_Helsinki_super_realistic.md` and `PLAN_Stockholm_super_realistic.md`:
> claim a task, tick it only after its automated and visual checks pass, and add one evidence line.
> Status legend: `[x]` done and validated · `[~]` in progress · `[ ]` open.

## Tracker

- [x] **T-0.1** Baseline model & in-world captures (`tku_lm_base` day/night 17-type studio sheets + `tku-r1` Ultra golden/noon/night in `visual-plan/reviews/tku-r1-2026-11-20/`; headless baseline tests green)
- [x] **T-0.2** Reference photo library (`visual-plan/refs/turku/` 13 CC/PD city views incl. TYKS hospital area + 34 Turku landmark CC/PD sets via `tools/turku_commons_refs.py`; `docs/fidelity-scorecard.md` §8 upgraded to full reference-backed scoring)
- [x] **T-0.3** Measured-envelope & height audit (`tools/turku_measured_heights.gd` headless against `turku_lod2` + OSM snapshots; 17 existing + 58 planned landmarks recorded in `docs/turku-landmark-sources.md`)
- [x] **T-0.4** Landmark slot & skyline selection (`ultra_registry_limit: 26` on `turku_cathedral`, modular `scripts/data/turku/tku_reg_*.gd` with `skyline: true` on tall spires/towers, `tools/audit_turku_selection.gd` 0 dropped `< 2.5 km` across 8 eyes)
- [x] **T-0.5** Curated Turku preset view (`PresetViews.ROWS` `"turku"` Aurajoki quay frame + `assets/preset_thumbs/turku.jpg`, `preset_views_test.gd` PASS, verified clear of masses in `tku-r1`/`tku-r2`)
- [x] **T-1** Rebuild the 12 schematic Turku landmarks to photo standard (12 dedicated `ft_*.gd` classes wired in `LandmarkSetFinlandTurku`, old stub files retired, `tku_t1` day/night + compare sheets & tests green)
- [x] **T-2** Verify & upgrade the 5 detailed/medium Turku models (`FtTurkuCathedral` w/ medieval chapels/statues, `FtTurkuCastle` w/ fieldstone/Renaissance Bailey, plus Kauppatori/Samppalinna/Paavo Nurmi night lighting; `tku_t2_t3a` compare sheets & tests green)
- [x] **T-3A** Major buildings & landmarks — Kauppatori, Yliopistonkatu & Commercial Core (all 14 bespoke `ft_*.gd` models wired in `tku_reg_centre.gd`, `tku_t2_t3a` + `turku_landmarks_test.gd` green)
- [x] **T-3B** Major buildings & landmarks — Aurajoki Waterfront, Vanha Suurtori to Forum Marinum (all 16 bespoke waterfront & maritime models incl. City Hall, Qwensel, Verdandi, Chappe, Rettig, Sibelius, WAM, Fuuga, Forum Marinum, Sigyn/Bore, crane wired & verified)
- [x] **T-3C** Major buildings & landmarks — Universities, TYKS Hospital Area, Kupittaa & Cultural Hills (all 16 models incl. TYKS Majakkasairaala over motorway/rail, T-sairaala, A/U-sairaala, Medisiina D, Kantasairaala pavilions, UTU, Kupittaa & Veritas wired & captured in `tku_tyks_t3`)
- [x] **T-3D** Major buildings & landmarks — Stations, Logomo, Port of Turku, Skyline Towers, Meyer Shipyard Cranes & Arenas (all 14 models incl. Logomo + bridge, Central/Bus/Kupittaa stations, Port terminals, If-torni, Ikituuri, Airiston Tähti, Pääskyvuori, Water Towers, Gatorade Center, Telakkaranta/Linnanfältti, Ruissalo, and `FtMeyerGantryCranes` twin 105 m Perno Goliath cranes wired & verified; 79 bespoke Turku landmarks total)
- [x] **T-4** Aurajoki, rail & archipelago bridges (6 missing bridges added in `bridge_specs_north_europe.gd` + 3 bespoke `LandmarkBrKit` bridges Auransilta/Kirjastosilta/Teatterisilta refactored to fitted `row` + `BridgeCamber.apply` + `FOOT_Y := 0.0` + Array-typed `FLOOD_META`; `bridge_specs_test.gd`, `bridge_arches_test.gd`, `turku_landmarks_test.gd` PASS)
- [x] **T-5.1** City-wide major building fidelity (`TurkuNotable` 180 verified OSM rows in `scripts/data/turku_notable.gd` + offline `turku_lod2` `start_year`/`use_code` enrichment for 26,540 buildings; `turku_notable_test.gd` & `turku_fabric_probe.gd` green)
- [x] **T-5.2** District circles, far-ring carry-over & Turku architectural styles (`turku_commercial`, `turku_jugend`, `turku_campus` in `architecture_cities_finland.gd`, 23 Turku district circles in `city_styles.gd`, `"turku"` in `CityStyles.FAR_DISTRICT_CITIES`; `architecture_test.gd` & `far_city_test.gd` PASS)
- [x] **T-5.3** Bare-earth terrain, seven hills, DEM check (a) fix & Turku aerial orthophoto (`OrthoSource` `"turku_2025"` CC BY 4.0 WMS + PNG decode + bare-earth `GroundModel` check (a) fix; `ortho_source_test.gd`, `host_policy_test.gd`, `fidelity_scorecard_test.gd` green)
- [x] **T-5.4** Aurajoki embankments, moored restaurant ships (*jokilaivat*), Föli water bus & Linnansatama Viking/Silja ferries (`aurajoki_east`/`aurajoki_west` `"restaurant_boat"` moorings, `turku_viking`/`turku_silja` liners, `foli_water_bus` & `ss_ukkopekka`; `quay_moorings_test.gd`, `marina_test.gd`, `vessel_models_test.gd` PASS)
- [x] **T-5.5** Transit, rail, Kakola funicular, streetscape & urban trees (`FtKakolaFunicular` wired with Array-typed `FLOOD_META`, Föli `#F5A800` bus paint in `transit_vehicles.gd`, VR trains verified; `train_test.gd`, `landmark_lights_test.gd`, `turku_landmarks_test.gd` PASS)
- [~] **T-6** Review rounds (`tku-r4-2026-11-23` Ultra golden/noon/night + all 13 open-space `--looks` + `tku-r4-winter-2026-11-23` snow/ice, `BUILD_VERSION = 321`), 78/79 Commons CC/PD landmark reference sets (`chappe_art_house` FOP-exempt) + full 79-landmark 14-page compare sheets (`visual-plan/captures/tku_t3_complete/compare/`) + night studio sheets (`tku_t3_night`), Fast/High/Ultra `perf_baseline.gd` (`tku-perf-final-2026-11-23`: cold 19.7 / 23.8 / 23.6 s ≤ budgets, peak 2.0 / 3.3 / 5.4 GB), `docs/fidelity-scorecard.md` §9 updated, all headless & windowed `world_cache_test`/`screenshot_test` gates green; **awaiting human AC-18 "photographic" sign-off only**

---

## Context & What the Audit Found

Turku already has strong data foundations in the engine: `"turku"` is enabled in `CityDetail.CITIES` (`scripts/render/city_detail.gd:17`), bundled OSM snapshots cover all rings (`assets/osm_snapshots/turku_*.osmb`), the City of Turku 3D CityGML model is bundled in `assets/city_models/turku_lod2/` (26,540 buildings across 101 GK23 cells), and live WFS layers wire street trees (`TurkuTrees`) and surveyed street/cobble polygons (`TurkuStreets`).

Despite that foundation, an audit of the codebase shows six concrete reasons Turku still looks procedural rather than like the real city:

1. **12 of the 17 existing Turku landmarks are 17–67 line schematic massing sketches, and 0 of 17 have been checked against photographs.**
   - `landmark_ft_churches.gd` packs three major churches into 171 lines: `turku_orthodox_church` (45 lines) invents **four** identical porticos on all four sides instead of Engel's single Doric portico facing Kauppatori; `mikaelinkirkko` (67 lines) and `martinkirkko` (43 lines) are plain boxes with simplified towers and no site stairs or floodlighting.
   - `landmark_ft_civic.gd` packs five landmarks into 164 lines (~30 lines each): `turku_main_library` (30 lines) omits the entire **2007 JKMM New Main Library** glass-and-concrete building and courtyard; `turku_city_theatre` (26 lines) omits its copper-clad stage/Sopukka expansion and pier rhythm; `turku_market_hall` (31 lines) lacks Nyström's ornate Eerikinkatu and Linnankatu brick-and-plaster gables; `turku_art_museum` (36 lines) lacks the Puolalanmäki granite terrace flights, corner pavilions' Jugend gable reliefs, and bronze busts; `vartiovuori_observatory` (25 lines) lacks Engel's north portico and rotunda balustrade.
   - `landmark_ft_historic.gd` packs four landmarks into 130 lines: `vanha_suurtori` (30 lines) builds Brinkkala as a lone yellow box while omitting **Old Town Hall (*Vanha Raatihuone*)**, **Hjelt House**, and **Juselius House** that form the square; `kakola_prison` (27 lines) builds a single H-block and omits the red-brick West Cellblock, polygonal Mental Hospital, granite perimeter wall, and funicular; `suomen_joutsen` (40 lines) stacks rectangular boxes for its hull with floating yard sticks and no rigging; `fori_ferry` (17 lines) is an orange box without prows, ramps, chain gear, or river landings.
   - Even the five stronger models — `turku_cathedral` (`landmark_cathedrals.gd`, 190 lines), `turku_castle` (`landmark_fr_turku.gd`, 215 lines), `turku_kauppatori` (468 lines), `samppalinnan_maauimala` (370 lines), and `paavo_nurmen_stadion` (361 lines) — have zero reference photos on disk and have never had a side-by-side photo check.

2. **Most of Turku's major buildings are completely missing and render as generic random-era extrusions.**
   - Around **Kauppatori** alone, **Hamburger Börs** (both the 2021 arched colonnade and 1894 Strandell Jugend wing), **Wiklund**, **Hansakortteli**, **KOP-kolmio**, **Åbo Svenska Teater**, **Turun Sanomat** (Alvar Aalto, 1930), and **Kivikukkaro** have no models and no facade overrides.
   - Along **Aurajoki**, **Turku City Hall**, **Aboa Vetus Ars Nova (Rettig Palace)**, **Chappe**, **Pinella**, **Sibelius Museum**, **Åbo Akademi Main Building & Book Tower**, **Verdandi / Pantern / Albatross / Hjelt** Jugend palaces, **Qwensel House**, **WAM (Wäinö Aaltonen Museum)**, **State Office Building**, **Fuuga (Music Hall)**, **S/S Bore**, **Sigyn**, **Forum Marinum**, and the **Crichton-Vulcan harbour crane** are all unmodelled.
   - Across the inner city and skyline, **University of Turku (Yliopistonmäki)**, **Turku Concert Hall**, **TYKS (U-, A-, T- & Majakka hospitals)**, **Kupittaa Science Park (BioCity, ElectroCity, DataCity, Intelligate I–III, ICT-City)**, **Veritas Stadion**, **Logomo & Logomon silta**, **Central Railway Station**, **Bus Station**, **Resurrection Chapel**, **St. Catherine's & Maaria medieval churches**, **Turku Synagogue**, **Betel Church**, **If-torni**, **Ikituuri**, **Airiston Tähti**, **Pääskyvuori Link Tower**, **Gatorade Center**, and the **Viking / Silja terminals** are missing.

3. **Rich building register attributes already downloaded in `build/turku_lod2_boxes/` are thrown away.**
   - Unlike Helsinki (`HelsinkiRegister`), Turku has no runtime building-register WFS wired, so undated OSM buildings fall back to random era rolls. Yet the 480 cached CityGML files in `build/turku_lod2_boxes/` already contain `yearOfConstruction` / `valmistunut` (~88% coverage in central Turku) and `bldg:function` / `käyttötarkoitus` (VTJ / RL2018 class codes), which `tools/prepare_turku_lod2.py` currently discards.
   - Furthermore, Turku has no `TurkuNotable` override table (equivalent to `HelsinkiNotable` in `scripts/data/helsinki_notable.gd`) to lock exact wall materials, colours, roofs, and plinths on the ~150 remaining named major buildings in the grid core.

4. **Landmark selection caps will drop central buildings unless configured.**
   - `turku_cathedral` (`scripts/data/location_data.gd:446`) does not set `ultra_registry_limit: 26`, and no Turku high-rises or spires use the separate `skyline: true` channel (110 slots on Ultra). Adding ~55 bespoke landmarks/major buildings without tuning `skyline: true` and `radius_m` would leave half of them unbuilt from riverfront views.

5. **Zero reference photos, no curated `PresetViews` row, and a recorded DEM check failure.**
   - `docs/fidelity-scorecard.md:261` lists Turku as `no-reference — geometry-only scoring`, `visual-plan/refs/turku/` does not exist, `PresetViews.ROWS` has no `"turku"` entry, and `docs/fidelity-scorecard.md:719-720` notes an open DEM spot-height check (a) failure on Turku.

6. **Signature Turku riverfront and harbour life is absent.**
   - `QuayMoorings.QUAY_ROWS` has no Aurajoki rows, so Turku's signature moored **restaurant ships (*jokilaivat*: Svarte Rudolf, Papa Joe, Donna, Cindy, Katarina, Esposito)** are missing.
   - `HarbourVesselData` has no **Viking Line** or **Tallink Silja** liveries at Linnansatama and no **Föli water bus** (*vesibussi*) or **S/S Ukkopekka** route toward Ruissalo/Naantali.
   - `CityStyles` has only 8 district circles for Turku, leaving the entire VI–VII commercial centre, Puolalanmäki/Kaskenmäki Jugend blocks, Yliopistonmäki campus, and Varissuo/Runosmäki/Pansio suburbs without dedicated districts.

---

## Three-Tier Strategy: Every Landmark AND Every Major Building Looks Like Real Life

To make **both** every landmark and every major building in Turku match reality without blowing draw-call or build-time budgets, every building in Turku is covered by one of three tiers:

1. **Tier 1 — Bespoke Photo-Sourced 3D Models (~76 models):**
   Every landmark, church, museum, theatre, major commercial block around Kauppatori, historic riverfront palace, university/hospital complex, station, stadium, museum ship, and skyline tower gets its own dedicated `.gd` builder class in `scripts/generation/landmarks/finland_turku/`, built to true OSM footprint + `turku_lod2` roof/eaves heights and verified side-by-side against Wikimedia Commons / Finna photos.
2. **Tier 2 — `TurkuNotable` Exact Facade & Roof Overrides (~150+ named major buildings):**
   Every prominent commercial, institutional, Jugend, Empire, and modernist block in central Turku that does not need custom sculpture geometry (bank palaces, corner apartment houses on Aurakatu, Linnankatu, Eerikinkatu, Yliopistonkatu, Humalistonkatu, Puutarhakatu, Kaskenkatu, Hämeenkatu, Itäinen/Läntinen Rantakatu, Kupittaa offices) gets an explicit OSM `way:<id>` / `relation:<id>` entry in `scripts/data/turku_notable.gd` specifying real photo-sampled wall material, hex colour, roof shape/material/colour, floor count, start year, and ground-floor shop/granite-plinth rules — overriding any probabilistic district roll while keeping native batched building performance.
3. **Tier 3 — Enriched `turku_lod2` + District Fabric (all 26,540 Turku buildings):**
   Offline re-extraction of `build/turku_lod2_boxes/` adds real `start_year` (`valmistunut` / `yearOfConstruction`) and `use` (`bldg:function` via `RegisterCodes`) into `turku_lod2` alongside measured height, storeys, roof shape, pitch, and ridge bearing. Paired with 18 calibrated Turku district circles in `CityStyles`, even ordinary background blocks match their real construction era, height, and roof silhouette.

---

## Definition of Done

### Per Bespoke Landmark / Major Building (Tier 1 Quality Bar)

The bar is `landmark_fh_parliament.gd`, `landmark_ft_kauppatori.gd`, and `landmark_ft_samppalinna.gd`. A Tier 1 model is done only when **all ten** hold:

1. **References:** 3+ CC BY / CC BY-SA / CC0 / PD photos from Wikimedia Commons or Finna.fi (`finna.fi`, Turku Museum Centre *Turun museokeskus* open photos) in `visual-plan/refs/landmarks/<type>/` (front, quarter, aerial/roof, plus night where floodlit), with URL, author, and licence recorded in `README.md` (tracked; image binaries gitignored). Strictly obey `HostPolicy` — never touch Russian domains or services.
2. **Measured envelope:** Footprint vertices, centroid, and long-axis `yaw_deg` measured from the OSM way/relation; eaves, ridge, and tower heights measured from `turku_lod2` (`HelsinkiLod2`) and published architectural sources, recorded in `docs/turku-landmark-sources.md`.
3. **Spec comment header:** Each builder file opens with a concise facade & massing spec (plan dimensions, wing heights, bay counts, storey counts, roof form/pitch, materials, signature details) counted from the reference photos.
4. **Signature features readable at 150 m:** Every feature listed in the Phase T-1…T-3 tables below is modelled in geometry, not approximated by a generic box.
5. **Materials & hues:** Stone, brick, render, timber, copper, slate, and glazing hues sampled from daylight reference photos via `LandmarkMaterials` (no flat untextured paint on masonry).
6. **Roof fidelity:** True roof form, pitch, dormers, skylights, chimneys, and rooftop plant (seen from Vartiovuori, Puolalanmäki, Kakolanmäki, and fly mode).
7. **Site & terrain seating:** Proper plinth/foundation drop (`found` below `y = 0` on sloped hills so uphill/downhill streets never expose gaps), `base_at_m`, `SEAT_META` for detached pavilions, `LandmarkStairCut` / `LandmarkTerrain` where needed, and tight `clear_m` / `clear_rect_m` / `model_rects_m` / `clear_offsets_m` that suppress duplicate OSM extrusions without deleting neighbouring historic houses.
8. **Night lighting:** `LandmarkLights.FLOOD_META`, `HALO_META`, or `"…Lamp"` / `SkyKit` lit window surfaces matching real-life Turku night illumination.
9. **Engine budgets:** One class per file under `scripts/generation/landmarks/finland_turku/` (≤ 1000 lines, enforced by `tools/check_class_size.sh`), 2–16 merged surface parts, 1k–150k triangles (small kiosks/ferry ≥ 300 tris), model top within `max(2 m, 3%)` of `height_m` (`tests/landmark_catalog_test.gd`).
10. **Visual evidence:** One 4-view studio sheet (`tools/capture_landmarks.gd` + `tools/landmark_compare_sheets.py` side-by-side with reference photos) AND one in-world `--looks` capture from an open-space eye, inspected for zero clipping, floating, or wrong orientation.

### Per `TurkuNotable` Major Building (Tier 2 Quality Bar)

1. Keyed by verified OSM `way:<id>` (plus `building:part` IDs where mapped) in `scripts/data/turku_notable.gd` with building name, street address, and Commons/Finna/CityGML source comment.
2. Verified against `turku_lod2` height/roof and a street-view/Commons photo so wall material (`brick`, `stone`, `render`, `glass`, `concrete`, `wood`), hex colour, `roof_shape`, `roof_material`, `roof_colour`, `levels`, and `start_year` match real life.
3. Covered by `tests/turku_notable_test.gd` verifying every row matches an existing building in `turku_detailed.osmb` / `turku_ring1600.osmb` and wins over district randomisation.

---

## Phases

### Phase T-0 — Baseline, Reference Library, Selection & Preset View

- **T-0.1 Baseline captures (batched, off-screen `--position 4000,4000`):**
  - Studio sheets for all 17 existing Turku landmark types (`tools/capture_landmarks.gd --types=<17 types> --tag=tku_lm_base`, day and `--night`), recording mesh/part/triangle counts in `stats.tsv`.
  - In-world captures (`tools/capture_presets.gd --places=turku --preset=3 --audit --tag=tku-r1 --times=golden,noon,night` plus winter weather) from **13 fixed open-space eyes**:
    1. Auransilta east quay looking upstream to Turku Cathedral & Pinella
    2. Läntinen Rantakatu at Qwensel / City Hall looking across Aurajoki
    3. Kauppatori central plaza looking toward Orthodox Church, Börs & Wiklund
    4. Vanha Suurtori cobbled square looking at Brinkkala & Old Town Hall
    5. Kirjastosilta / Old Main Library quay looking toward New Library, Chappe & Rettig
    6. Teatterisilta looking toward City Theatre, WAM & Samppalinna hill
    7. Martinsilta / Tervatori looking downstream to Föri, Kakola & Mikaelinkirkko spire
    8. Forum Marinum quay looking at Suomen Joutsen, Sigyn, Bore & harbour crane
    9. Linnanpuisto open lawn looking at Turku Castle (*Päälinna* & *Esilinna*)
    10. Puolalanmäki granite steps looking at Turku Art Museum & down Aurakatu
    11. Yliopistonmäki plaza between University Main Building & Feeniks Library
    12. TYKS Hospital Area (Hämeentie / Savitehtaankatu open ground) looking across Majakkasairaala over the motorway/railway deck, T-sairaala, Medisiina D & A-sairaala
    13. Drone eye (35 m ASL, `look-eye-height-over-water` rule) over the Aura mouth looking up the river corridor
- **T-0.2 Reference photo library:**
  - Create `visual-plan/refs/turku/` with 13 licensed Commons / Finna city-view photos matching the 13 eyes above, and update `docs/fidelity-scorecard.md` §2 to upgrade Turku from `no-reference — geometry-only scoring` to full reference-backed scoring.
  - Collect 3+ CC/PD Commons or Finna (`Turun museokeskus` CC BY 4.0) photos per landmark in `visual-plan/refs/landmarks/<type>/` using `tools/commons_refs.py` + `tools/landmark_ref_inventory.gd`.
- **T-0.3 Measured-height & footprint table:**
  - Write `tools/turku_measured_heights.gd` (or extend `helsinki_measured_heights.gd` for `turku:` LOD2 cells) to cross-check every existing and planned Turku building against `turku_lod2` (`measuredHeight`, `roof_h_m`, `pitch_deg`, `ridge_az_deg`, `storeys`) and OSM footprints; record the full table in `docs/turku-landmark-sources.md`.
- **T-0.4 Landmark slot & skyline channel configuration:**
  - Write `tools/audit_turku_selection.gd` testing `LandmarkSites.select()` from 8 Turku eyes at High and Ultra.
  - Add `"ultra_registry_limit": 26` to `turku_cathedral` in `scripts/data/location_data.gd:446`.
  - Route genuine tall spires, towers, chimneys, and high-rises (`mikaelinkirkko`, `martinkirkko`, `if_torni`, `airiston_tahti`, `ikituuri`, `paaskyvuori_tower`, `luolavuori_water_tower`, `iso_heikkila_water_tower`, `abo_akademi_book_tower`, `tyks_majakka`, `intelligate_towers`, `crichton_vulcan_crane`, `meyer_gantry_cranes`) through `"skyline": true` (110 slots on Ultra), freeing the 26 icon slots for low- and mid-rise palaces, squares, museums, and waterfront buildings within 1.5–2.5 km of the camera.
  - Split `scripts/data/landmark_registry_finland_turku.gd` into modular group registries under `scripts/data/turku/` (`tku_reg_centre.gd`, `tku_reg_aurajoki.gd`, `tku_reg_hills.gd`, `tku_reg_harbour.gd`, `tku_reg_skyline.gd`) so every file stays compact and clean.
- **T-0.5 Curated Turku opening preset (`PresetViews`):**
  - Add `"turku"` to `PresetViews.ROWS` (`scripts/data/preset_views.gd`): camera on open riverside quay near Auransilta / Läntinen Rantakatu (verified clear of trees, hulls, and walls), framing Aurajoki, Cathedral spire, historic embankments, and bridges at golden hour. Pin in `tests/preset_views_test.gd`.

---

### Phase T-1 — Rebuild the 12 Schematic Landmarks to Photo Standard

Split `landmark_ft_churches.gd`, `landmark_ft_civic.gd`, and `landmark_ft_historic.gd` into **one dedicated class file per landmark** under `scripts/generation/landmarks/finland_turku/ft_<name>.gd`, retiring the bundled multi-landmark stub files.

| Type | File | Real-Life Features That Must Be Readable |
|---|---|---|
| `turku_orthodox_church` | `ft_orthodox_church.gd` | Fix the 4-portico error: **single** south-east/Kauppatori-facing tetrastyle Doric portico with pediment, pale Empire yellow cylindrical rotunda + rectangular altar apse to the rear, green copper hemispherical dome on 12-window drum, gilt cross, flanking low Empire wings/wall along Kauppatori, `FLOOD_META`. |
| `mikaelinkirkko` | `ft_mikaelinkirkko.gd` | Lars Sonck's asymmetric red-brick Jugend/Neo-Gothic hall church: rough grey-granite plinth & portals, 77 m NW square-to-octagonal spire with clock dials, gabled belfry openings & 4 corner pinnacles, stair turrets with conical copper caps, stepped brick gables with white blind tracery, polygonal apse & sacristy, warm night floodlights. |
| `martinkirkko` | `ft_martinkirkko.gd` | 1933 Nordic Classicist / Functionalist pale-ochre basilica on Huovinkatu ridge: tall narrow nave with low side aisles, semicircular apse, stepped stone entrance terrace, freestanding-feel 52 m SW campanile with open columned belfry lantern, copper spirelet & cross, floodlighting. |
| `turku_art_museum` | `ft_art_museum.gd` | Gustaf Nyström's 1904 grey/reddish rough-granite National Romantic palace crowning Puolalanmäki: monumental multi-landing granite stair cascades down toward Aurakatu (`LandmarkStairCut` / `SEAT_META`), three-arch rusticated portal, bronze portrait herms of **Runeberg & Topelius** on granite pedestals, twin projecting pavilions with curved Jugend gables, glass roof clerestory, night floodlights. |
| `vartiovuori_observatory` | `ft_vartiovuori_observatory.gd` | C.L. Engel's 1819 Empire hilltop observatory: rusticated plinth seated cleanly on Vartiovuori crest, 4-column north portico overlooking the Cathedral & city, symmetric two-storey wings, central cylindrical observation tower with iron belvedere railing, tall casements & conical dark-metal dome, warm lighting. |
| `turku_market_hall` | `ft_market_hall.gd` | Gustaf Nyström's 1896 through-block hall (Eerikinkatu to Linnankatu, 118 m): polychrome red-brick & cream-plaster Neo-Renaissance end facades with stepped gables, pinnacles, coat-of-arms relief & arched carriage portals, 20+ rhythmic side window bays between brick pilasters, full-length raised clerestory lantern with interior warm glow at night. |
| `turku_main_library` | `ft_main_library.gd` | Full **two-building library block** around the Library Courtyard (*Kirjastopiha*): (1) Wrede's 1903 Dutch-Renaissance **Old Library** (*Vanha kirjasto*) in red brick & sandstone/plaster bands with shaped stepped gables, corner spirelet & riverside portal; (2) JKMM's 2007 **New Main Library** (*Uusi pääkirjasto*) along Linnankatu & Kauppiaskatu — crisp cast-concrete frame, full-height river/courtyard glass wall with interior reading mezzanine & timber soffit, glass connecting bridge, and courtyard café terrace. |
| `turku_city_theatre` | `ft_city_theatre.gd` | 1962 Luukkonen & Stenros riverside modernist theatre **plus** 2017 renovation/expansion: cantilevered white concrete riverside foyer canopy, deep rhythmic mullions with warm illuminated lobby interior, textured dark-brick/concrete auditorium flanks, tall white fly-tower, and the **patinated/burnished copper Sopukka & backstage wing** toward Volter Kilven katu. |
| `vanha_suurtori` | `ft_vanha_suurtori.gd` | Expand from lone Brinkkala box to the **complete 4-mansion Vanha Suurtori Empire ensemble** (`model_rects_m` clearing all four OSM ways): **Brinkkalan talo** (ochre Empire front, rusticated ground floor, wrought-iron **Christmas Peace balcony**), **Vanha Raatihuone** (Old Town Hall, warm red-ochre/terracotta 3-storey facade, triangular pediment with clock & ridge turret), **Hjeltin talo** (1830 pale Empire palace with pilastered piano nobile), and **Juseliuksen talo**, framing the cobblestone square. |
| `kakola_prison` | `ft_kakola.gd` | Full **Kakolanmäki hilltop complex** (`SEAT_META` per wing across the granite ridge): Lohrmann's 1853 **Granite Main Prison** (rusticated grey/pink granite coursed blocks, central church/admin projection, cell-window rhythm), 1911 **Red-Brick West Cellblock (*Länsiselli*)** with Jugend turrets/gables, **Kakola Mental Hospital (*Kakolan mielisairaala*)** castle-like granite polygon on the SW crag, surviving **granite perimeter walls** with watchtowers, and **Hotel Kakola** courtyard entrance. |
| `suomen_joutsen` | `ft_suomen_joutsen.gd` | True curved steel clipper hull (`lm.lathe` / lofted cross-sections, never stepped boxes!), red boot-top, gleaming white topsides with painted gunport/porthole band, figurehead & raked bowsprit with jibboom, teak forecastle/main/poop decks, charthouse, bridge wings, 4 white lifeboats on davits, 3 raked steel masts to 44 m with 5 yards each, standing & running rigging stays (`TallShipDetails`), gangway to Forum Marinum quay, and warm mast/hull floodlights. |
| `fori_ferry` | `ft_fori.gd` | Authentic 1904 **Föri** orange-and-white double-ended electric river ferry: flared symmetrical steel prows, hinged boarding ramps at both ends, white slatted passenger benches, side cabin with operator house, lifebuoys, roof mast with navigation/work lamps, **plus** the wooden/granite *Förin laiturit* landing stages on Tervatori and Läntinen Rantakatu. |

---

### Phase T-2 — Verify & Upgrade the 5 Existing Hero Models Against Photos

- **`turku_cathedral` (`landmark_cathedrals.gd` → split to `finland_turku/ft_turku_cathedral.gd`):**
  Compare side-by-side against aerial, west-front, south-flank, and choir Commons/Finna photos. Model the **real asymmetric medieval side chapels** (octagonal **Kankaisten kappeli** on the south-east with copper roof, **Tavast**, **Tott**, **Stålhandske** chapels, two-storey north sacristy), verify Engel's 1834 Neo-Gothic cast-iron/copper spire transitions, clock dial proportions & whitewashed blind niches, add the **medieval brick churchyard wall (*Tuomiokirkon muuri*)**, west granite stair down toward Tuomiokirkkosilta, **Per Brahe statue** (Walter Runeberg, 1888, in Brahenpuisto) and **Mikael Agricola statue** (Oskari Jauhiainen, 1952), and warm cathedral floodlights (`FLOOD_META`).
- **`turku_castle` (`landmark_fr_turku.gd` → split to `finland_turku/ft_turku_castle.gd`):**
  Verify plan and elevations against OSM way `466736288`, `turku_lod2`, and aerial photos: distinguish rough **medieval fieldstone granite** lower walls + **medieval red-brick vault gables/window surrounds** from **whitewashed Renaissance upper storeys**; refine the irregular polygonal **Renaissance Bailey (*Esilinna*)** wings, **Round Tower (*Pyöreä torni*)**, **Hexagonal & Pentagonal corner towers**, **Sture Church** tall lancets on the south wing, timber **defensive hoarding gallery** on the keep, east entrance gatehouse & cobble forecourt, and full night floodlighting.
- **`turku_kauppatori` (`landmark_ft_kauppatori.gd`):**
  Photo-check the three 2022 Schauman Arkkitehdit glulam-and-glass pavilions, *Kanttarelli* stage canopy, *Saaristohyppely* skerry fountain, red Taivassalo granite paving grid, cherry trees, candelabra light masts, and market stalls; tune glass reflectivity, wood warm-glow soffits at night, and edge alignment with surrounding streets.
- **`samppalinnan_maauimala` (`landmark_ft_samppalinna.gd`) & `paavo_nurmen_stadion` (`landmark_ft_paavo_nurmi.gd`):**
  Run studio compare sheets against reference photos; verify floodlight mast geometry/night illumination on Paavo Nurmi Stadium (including Wainö Aaltonen's **Paavo Nurmi runner statue** touchpoints if in approach plaza) and underwater pool glow / grandstand details at Samppalinna.

---

### Phase T-3 — Build All Missing Landmarks & Major Buildings (~59 New Tier 1 Models)

Every new model lives in its own file `scripts/generation/landmarks/finland_turku/ft_<name>.gd`, registered in `scripts/data/turku/tku_reg_*.gd` and dispatched via `LandmarkSetFinlandTurku`.

#### T-3A: Kauppatori Perimeter, Yliopistonkatu & Commercial Core (14 models)

Every single block facing Turku Market Square (*Kauppatori*) and the pedestrian core is hand-modelled so standing in the centre of Turku looks 100% real from 360°:

| Type | Building | Must-Read Real-Life Features |
|---|---|---|
| `hamburger_bors_turku` | Scandic Hamburger Börs (2021 + 1894) | **Dual architectural icon:** Schauman & Nordström's 2021 rhythmic light-stone/brick two-storey arched Kauppatori colonnade, recessed copper/bronze upper setbacks & rooftop terrace bar + Frithiof Strandell's preserved **1894 ornate Jugend/Neo-Renaissance corner palace** (onion corner turret, bay windows, decorative plasterwork) on Eerikinkatu/Kauppiaskatu. |
| `wiklund_turku` | Sokos Wiklund & Walo Rooftop | Full Kauppatori NE corner ensemble: 1957–63 modernist department-store podium with glazed street canopy & display windows, 9-storey white/grey hotel tower on Eerikinkatu/Brahenkatu with **Walo** rooftop glass pavilion & illuminated Wiklund signage band. |
| `hansakortteli` | Hansa Shopping Centre Block | Kauppatori west front (Aurakatu–Yliopistonkatu–Eerikinkatu–Kristiinankatu): **Antintalo** (1891 Neo-Renaissance facade on Eerikinkatu), **St. Erik's corner / Kultatalo** facades, glazed Hansa entrances, and interior skylit mall roofs seen from above. |
| `abo_svenska_teater` | Åbo Svenska Teater (1839) | Finland's oldest theatre (Gylich / Chiewitz) on the Eerikinkatu/Aurakatu corner of Kauppatori: pale-yellow Empire facade, rusticated arcade base, white Ionic pilasters, tall arched ballroom windows, Hansa glass-canopy link, copper hip roof. |
| `kop_kolmio_turku` | KOP-kolmio (Viljo Revell, 1964) | Sharp triangular modernist landmark at Aurakatu / Yliopistonkatu / Eerikinkatu: pale stone spandrels, continuous flush horizontal ribbon windows, recessed ground-floor pillar colonnade. |
| `turun_sanomat_building` | Turun Sanomat Building (Alvar Aalto, 1930) | Kauppiaskatu 5 functionalist masterpiece: white rendered 6-storey facade, flush strip windows, ground-floor giant press-display windows, asymmetric entrance canopy, rooftop pergola terrace. |
| `kivikukkaro` | Kivikukkaro (Aarne Ehojoki, 1975) | Yliopistonkatu / Kristiinankatu commercial palace: precast pale-stone/quartzite modular grid facade, recessed street arcade along *Kävelykatu*, stepped upper office levels. |
| `turku_synagogue` | Turku Synagogue (1912) | Hindersson & Krook's red-brick Art Nouveau / Byzantine synagogue on Brahenkatu/Puutori: octagonal drum, prominent green-copper dome with Star of David finial, arched entrance portico & corner turrets. |
| `puutori_ensemble` | Puutori & Puutorin Vessa (1933) | Paved square with **Puutorin Vessa** circular functionalist red-brick/white-trim rotunda café, surrounding cobbles, and Wäinö Aaltonen's ***Kun ystävyyssuhteet solmitaan*** bronze monument at Ystävyydenpuisto. |
| `betel_church_turku` | Betel Church (Frithiof Strandell, 1906) | Yliopistonkatu court church: whitewashed Jugend castle-like nave, steep red-tile roof, asymmetric square bell tower with flared black/copper spire & arched arcade approach from Yliopistonkatu. |
| `prima_albatross_aurakatu` | Aurakatu Jugend Palaces (*Albatross* & *Prima*) | Strandell's monumental stone-and-plaster Jugend apartment palaces climbing Aurakatu toward the Art Museum: corner towers, granite portals, asymmetrically grouped bay windows, steep metal/tile roofs. |
| `pantern_hjelt_kaskenkatu` | *Pantern* & Vartiovuori Jugend Front (Strandell) | Kaskenkatu 2 (*Pantern*, 1910) & Linnankatu corner: iconic pale-plaster & granite late-Jugend palace overlooking Vartiovuorenkatu / Auransilta with polygonal bay towers & mansard roofs. |
| `humalistonkatu_jugend` | Humalistonkatu Jugend Row | Signature National Romantic / Jugend stone blocks along Humalistonkatu (Turku's premier Art Nouveau boulevard leading to Central Station): asymmetric gables, granite owls/ornament plinths, turrets. |
| `turku_fire_station` | Turku Central Fire Station (*Keskuspaloasema*, 1916) | J. Eskil Hindersson's monumental red-brick Classicist/Jugend fire station on Eerikinkatu 35: curved 6-bay appliance garage doors, granite trim, steep tiled roofs, and tall brick hose-drying lookout tower! |

#### T-3B: Aurajoki Waterfront — Cathedral to Harbour Mouth (16 models)

Every signature building along both banks of the Aura River (*Itäinen Rantakatu*, *Läntinen Rantakatu*, *Piispankatu*, *Linnankatu*):

| Type | Building | Must-Read Real-Life Features |
|---|---|---|
| `turku_city_hall` | Turku City Hall (*Turun kaupungintalo*, 1885) | Aurakatu 2 at Auransilta: Sjöström's rich yellow-ochre Neo-Renaissance riverfront palace, rusticated base, Corinthian pilaster order, central pediment with gilded Turku coat-of-arms, wrought-iron balcony, rear courtyard wings. |
| `qwensel_house` | Qwensel House & Pharmacy Museum (~1700) | Läntinen Rantakatu 13 beside City Hall: pre-fire timber bourgeois manor house in ochre/buff clapboard with steep dark mansard/hipped roof, wooden courtyard outbuildings & herb garden. |
| `verdandi_house` | Verdandi House (*Verdandin talo*, 1898) | Strandell's Neo-Renaissance palace at Aurakatu 1 / Linnankatu across from City Hall: ornate plaster-and-stone rustication, corner domes/turrets, arched shopfronts, symmetric balconies. |
| `chappe_art_house` | Art House Chappe (JKMM, 2023) | Läntinen Rantakatu contemporary landmark wedged beside Old Library/Town Hall: sweeping dark patinated bronze/copper shingle facade, sculpted arched street-level picture windows, curved roofline. |
| `aboa_vetus_rettig` | Aboa Vetus Ars Nova (*Rettigin palatsi*, 1928) | Jung & Jung's baroque-classicist walled villa-palace on Itäinen Rantakatu: high granite-and-plaster street wall with grand wrought-iron gates, symmetrical mansard-roofed palace around honour court, modern museum entrance wing. |
| `pinella_porthan` | Pinella & Porthan Monument (1848 / 1864) | Porthaninpuisto riverside pavilion by Tuomiokirkkosilta: white neoclassical Doric columned portico facing Aurajoki, modern glass river terrace, and C.E. Sjöstrand's bronze **H.G. Porthan statue** on red granite pedestal. |
| `sibelius_museum` | Sibelius Museum (Woldemar Baeckman, 1968) | Piispankatu brutalist concrete jewel: low horizontal board-formed concrete walls, glazed atrium, and sweeping hyperbolic-paraboloid shell roof over the concert hall. |
| `abo_akademi_main` | Åbo Akademi Main Building & Cathedral Quarter | Charles Bassi's 1833 pale-yellow Empire main building at Tuomiokirkontori/Rothoviuksenkatu + adjacent historic Empire academy blocks (*katedraalikoulu* / *akatemiatalo*：**Academy Building / *Vanha Akatemiatalo***, Gjörwell 1815 — Finland's premier Gustavian neoclassical ceremonial hall!). |
| `abo_akademi_book_tower` | Åbo Akademi Book Tower (*Kirjatorni*, 1935) | Erik Bryggman's stark white functionalist library tower on Tuomiokirkonkatu (`skyline: true` / priority): crisp cubic massing, strip windows, recessed top terrace. |
| `wam_museum` | Wäinö Aaltonen Museum of Art (WAM, 1967) | Irma & Matti Aaltonen's white travertine modernist museum on Itäinen Rantakatu: stepped cubic gallery volumes following the river bend, panoramic sculpture terrace, monument sculptures on the quay. |
| `turku_state_office` | State Office Building (*Valtion virastotalo*, 1967) | Luukkonen & Stenros modernist civic block between City Theatre and WAM on Itäinen Rantakatu: elevated pilotis plinth, rhythmic precast white/grey facade grid, riverside plaza. |
| `fuuga_music_hall` | Turku Music Hall Fuuga (*Musiikkitalo Fuuga*) | PES-Architects' riverside concert hall beside City Theatre on Itäinen Rantakatu (verify current OSM footprint/construction state): warm copper/brass & glass curved foyer facing Aurajoki, sculpted auditorium mass, rooftop garden terrace. |
| `samppalinna_windmill` | Samppalinna Windmill & Restaurant (1860 / 1865) | Samppalinnanmäki crest overlooking Aurajoki: white octagonal wooden smock windmill with four lattice sails + ornate Swiss-style wooden pavilion restaurant (*Samppalinnan ravintola*) with veranda towers. |
| `forum_marinum` | Forum Marinum (*Kruununmakasiini* & *Linnanpuomi*) | Linnankatu 72 maritime museum complex: 1930s grey-stone Crown Granary & red-brick Harbour Customs building, open maritime yard with naval mines/anchors, and *Daphne* glass display pavilion. |
| `sigyn_bore_ships` | Museum Ships *Sigyn* (1887) & *S/S Bore* (1960) | `base: "water"` on Aurajoki at Forum Marinum: (1) wooden 3-masted barque **Sigyn** cradled in her white floating wooden dock (*Loke*); (2) classic 100 m passenger liner **S/S Bore** (white hull, buff raked funnel with Bore cross, promenade decks, lifeboats). |
| `crichton_vulcan_crane` | Aurajoki Harbour Crane (*Nosturi Numero 37*) | Iconic preserved shipyard jib/portal crane (`skyline: true`, ~38 m) on the west bank by Forum Marinum / Telakkaranta, steel lattice boom & cab, architectural night accent lighting. |

#### T-3C: Universities, TYKS Hospital Area, Kupittaa & Cultural Hills (16 models)

Special focus on the **TYKS Hospital Area (*Kantasairaala* — Kiinamyllynkatu / Savitehtaankatu / Hämeentie / Helsinginkatu)**: every major clinical, research, and historic hospital building, the motorway/railway bridge-deck supporting Majakkasairaala, enclosed pedestrian skybridges (*yhdyskäytävät*), ambulance/emergency bays, rooftop helipad, and campus parking structures are modelled and coordinated so the entire medical precinct reads as a real, cohesive university hospital campus from street level, the Helsinki motorway approach, and fly mode.

| Type | Building | Must-Read Real-Life Features |
|---|---|---|
| `utu_main_campus` | University of Turku Main Hill (*Yliopistonmäki*, 1954–59) | Aarne Ervi's celebrated modernist acropolis: **Main Building** (long horizontal travertine/concrete wing on pilotis, semicircular lecture auditorium), **Feeniks Library** (cube on glazed ground floor), **Natura**, central stone plaza, reflecting pool & Wäinö Aaltonen's *Genius Montis* sculpture. |
| `utu_agora_quantum` | Agora, Quantum, Educarium & Publicum | Modern university campus blocks along Vesilinnantie / Assistentinkatu: Agora's soaring diagonal glass atrium facade, brick-and-metal academic wings, **Vesilinna** water-tower hill massing. |
| `turku_school_economics` | Turku School of Economics (*Kauppakorkeakoulu*, 1950) | Rehtorinpellonkatu red-brick & white-trim modernist campus block with curved auditorium & glass entrance wing. |
| `turku_concert_hall` | Turku Concert Hall & Vocational Institute (1952) | Luukkonen's Aninkaistenmäki functionalist ensemble: white/cream rendered auditorium wedge raised over glazed foyer, rhythmic vertical relief ribs, paired with **Aninkaisten koulutalo** white modernist courtyard wings. |
| `tyks_majakka` | TYKS Majakkasairaala (*Lighthouse Hospital*, 2022) | `skyline: true` — Schauman Arkkitehdit's landmark hospital built on a massive concrete **structural deck spanning directly over Highway 1 (*Helsinginkatu*) and the Helsinki–Turku railway**: sculpted white/light-metal facade with warm coloured glass accents, glowing vertical "lighthouse" atrium/stairwell beacon at night, **rooftop H-marked helipad with perimeter approach lights**, and glazed pedestrian **skybridge (*yhdyskäytävä*)** linking across Savitehtaankatu into T-sairaala. |
| `tyks_t_hospital` | TYKS T-sairaala (2003–2013) & Emergency Precinct | Arkkitehtiryhmä Reino Koivula's expansive hospital complex along Hämeentie / Savitehtaankatu: curved glass-and-metal clinical wings, rhythmic vertical sun-shading louvers & coloured facade panels, soaring main entrance glass atrium with drop-off canopy, dedicated **ambulance/emergency bay**, **T-sairaalan pysäköintitalo** multi-storey parking deck, and enclosed skybridges linking toward Medisiina D and Majakkasairaala. |
| `tyks_a_u_hospitals` | TYKS A-sairaala (1938) & U-sairaala site | Kiinamyllynkatu medical hill: **A-sairaala** (Jussi Paatela & Uno Ullberg's protected white functionalist classic with curved end balconies, continuous ribbon windows, rooftop solarium terrace & landscaped approach) + **U-sairaala** (1968 concrete inpatient slab — verify current demolition/redevelopment footprint in OSM before modelling). |
| `tyks_medisiina_dentalia` | Medisiina D (2018), Medisiina A–C & Dentalia | University of Turku / TYKS medical teaching & research cluster on Kiinamyllynkatu: **Medisiina D** (contemporary glass, light-metal & timber-accented research hub with double-height lobby and campus plaza), **Medisiina A–C** mid-century brick/concrete lab wings, and **Dentalia**. |
| `tyks_kantasairaala_pavilions` | Historic Kantasairaala Pavilions & Mikro | Surviving historic red-brick, ochre-render, and modernist hospital pavilions along Kiinamyllynkatu / Kunnallissairaalantie (*Vanha lastenklinikka*, *Hallintorakennus*, *Mikro*, *Rakennus 14*), courtyard trees, internal hospital service lanes & clear emergency signage/lighting. |
| `kupittaa_biocity_electro` | BioCity, ElectroCity & DataCity | Kupittaa Science Park core on Tykistökatu / Lemminkäisenkatu: historic red-brick industrial Silo/factory structures fused with tall glass atria, skybridges, and rooftop tech penthouses. |
| `intelligate_ict_kupittaa` | Intelligate I–III, ICT-City & Joki | Modern glass-and-steel office towers flanking Kupittaa Station (`skyline: true`), **ICT-City** brick/glass courtyard block, and **Sokos Hotel Kupittaa**. |
| `veritas_stadion` | Veritas Stadion (Kupittaan jalkapallostadion) | Kupittaanpuisto football stadium: 1952 functionalist Olympic Tribune (*Olympiakatsomo*), 2003 2-tier glass-backed Main Stand with cantilevered steel truss roof, 2009/2023 end stands enclosing the green pitch, 4 corner floodlight masts (`FLOOD_META`). |
| `kupittaan_puisto_pavilions` | Kupittaa Park Pools & Pavilions | **Kupittaan maauimala** outdoor pools & slides, historic **Pyhän Henrikin lähde** (St. Henry's Spring octagonal pavilion), and **Kupittaan paviljonki**. |
| `resurrection_chapel` | Resurrection Chapel (*Ylösnousemuskappeli*, 1941) | Erik Bryggman's world-renowned chapel at Turku Cemetery: white rendered asymmetric hall opening through a glass wall to pine forest, stone entry loggia, freestanding round sandstone/rendered bell tower. |
| `st_catherine_church_turku` | St. Catherine's Church (*Pyhän Katariinan kirkko*, 14th c.) | Nummi medieval grey-fieldstone parish church: steep shingled/tiled saddle roof, brick-ornamented gables with blind crosses & niches, detached wooden/stone belfry. |
| `maaria_church_turku` | Maaria Church (*Maarian kirkko*, 15th c.) | Medieval fieldstone church with rich red-brick star/cross gable blind niches, porch, sacristy, and medieval stone churchyard gatehouse. |

#### T-3D: Stations, Logomo, Port of Turku, Skyline Towers & Arenas (13 models)

| Type | Building | Must-Read Real-Life Features |
|---|---|---|
| `logomo_and_bridge` | Logomo (1876) & Logomon silta (2021) | Red-brick arched VR locomotive roundhouse/workshop converted into cultural hub + the 455 m undulating dark-weathering-steel **Logomon silta** pedestrian bridge sweeping over the railyard from Ratapihankatu with integrated rib lighting! |
| `turku_central_station` | Turku Central Railway Station (1940) | Väinö Vähäkallio's yellow-brick functionalist main station facing Ratapihankatu / Humalistonkatu axis: tall glazed concourse hall, clock, granite steps, and platform canopies. |
| `turku_bus_station` | Turku Bus Station (*Linja-autoasema*, 1938) | Smedberg & Sora's functionalist gem at Aninkaistensilta: pale-ochre brick/render semicircular ticket rotunda, sweeping cantilevered departure platform canopy, neon/illuminated clock sign. |
| `kupittaa_station` | Kupittaa Railway Station (1995) | Steel-and-glass bridge-concourse station straddling the recessed dual-track main railway line at Science Park, escalators/lifts down to platforms. |
| `port_of_turku_terminals` | Viking Line & Tallink Silja Terminals (*Linnansatama*) | Port of Turku passenger terminals, elevated glass Skywalk boarding gangways reaching the ferry berths, marshalling lanes, and historic red-brick **Harbour Warehouse / Seamen's Mission** (confirming current OSM layout vs *Ferry Terminal Turku* works). |
| `if_torni_turku` | If-torni (Sampo/If Office Tower, 66 m) | `skyline: true` — Kupittaa/Itäharju's 17-storey heptagonal dark-granite & reflective-glass office tower + low courtyard wings, lit office floors via `SkyKit` & rooftop logo halo. |
| `ikituuri_turku` | Ikituuri (43 m, 2011) | `skyline: true` — Oval 12-storey copper-louver & solar-collector student tower at Pispalantie / Helsinginkatu junction, instantly recognisable gateway from Helsinki motorway. |
| `airiston_tahti` | Airiston Tähti & Majakkaranta Towers (58 m) | `skyline: true` — 18-storey white seaside residential tower at Korppolaismäki / Majakkaranta overlooking the Aura mouth & Airisto sound, glazed balcony stack & beacon crown. |
| `telakkaranta_linnanfaltti` | Telakkaranta Waterfront & Harppuuna Towers | Contemporary brick, corten, and white-terrace residential blocks on the Aura river mouth (east & west banks opposite Forum Marinum / Castle) + **Linnanfältti** modern wooden apartment quarter. |
| `paaskyvuori_tower` | Pääskyvuori Link Tower (*Pääskyvuoren linkkitorni*, 134 m) | `skyline: true` — Turku's tallest structure (1964): slender slip-formed concrete shaft, upper equipment platforms, steel lattice mast & red ICAO aviation obstruction lights (`HALO_META`) visible across the whole eastern horizon. |
| `turku_water_towers` | Luolavuori & Iso-Heikkilä Water Towers | `skyline: true` — Iconic mushroom/cylindrical hilltop water towers crowning Luolavuori and Iso-Heikkilä ridges on the skyline. |
| `gatorade_center_turku` | Gatorade Center (*Turkuhalli*, 1990) | Artukainen 11,820-seat arena: giant white cylindrical/oval bowl with external steel roof trusses, glazed entrance rotunda, and neighbouring **Turku Fair Centre (*Messukeskus*)** halls. |
| `ruissalo_villas_spa` | Ruissalo Spa, Botanical Glasshouses & Lace Villas | Representative Ruissalo icons when exploring west: **Turku University Botanical Garden** glass pyramids/domes, **Ruissalon Kylpylä** waterfront hotel, and **Villa Saaro / Honkapirtti** carpenter-Gothic lace veranda villas. |

---

### Phase T-4 — Aurajoki, Rail & Archipelago Bridges

1. **Upgrade key Aurajoki crossings from generic parametric girders to photo-accurate bespoke `LandmarkBrKit` models:**
   - **Auransilta (1907):** Single-span granite-clad Art Nouveau arch bridge with curved stone viewing balconies at mid-span and **four ornate Jugend bronze/iron multi-globe lamp standards**!
   - **Kirjastosilta (2013):** Sleek asymmetric white steel pedestrian bridge with glass balustrades and **under-deck colour-changing LED arch lighting** reflecting in Aurajoki at night!
   - **Teatterisilta (1997):** Broad wood-decked pedestrian plaza-bridge with white cable-stayed/mast lighting pylons and benches.
   - **Tuomiokirkkosilta (1956)**, **Myllysilta (2011)** (twin-pier slender white steel box girder with flared haunches), and **Martinsilta (1940)**: verify exact span splits, pier geometry, railing style, and clearance against photos in `bridge_specs_north_europe.gd:351-387`.
2. **Add missing Turku bridges (`conf: 2` in `bridge_specs_north_europe.gd` or bespoke):**
   - **Aninkaistensilta** & **Ratapihankatu / Koulukatu railway overpasses**
   - **Tuomaansilta** (upstream Aurajoki concrete/steel road bridge by Student Village)
   - **Halistensilta** & **Halistenkoski pedestrian weir bridge** (historic Aurajoki rapids & red-brick waterworks!)
   - **Aurajoen rautatiesilta** (steel truss railway bridge over Aurajoki upstream of Tuomaansilta)
   - **Hirvensalonsilta** (road bridge over Pitkäsalmi strait to Hirvensalo)
   - **Ukko-Pekan silta** (high steel arch bridge on the Naantali border, visible in far west views)

---

### Phase T-5 — City-Wide Major Buildings, Fabric, Terrain, Riverfront & Transit

#### T-5.1 Every Non-Landmark Major Building (`TurkuNotable` + Enriched `turku_lod2`)

- **Offline CityGML enrichment (`tools/prepare_turku_lod2.py` + `HelsinkiLod2`):**
  - Re-parse the 480 already-cached GML boxes in `build/turku_lod2_boxes/` (zero network calls) to append two compact columns to each `turku_lod2` row: `start_year` (from `bldg:yearOfConstruction` or `gen:stringAttribute[@name="valmistunut"]`, ~88% coverage in central Turku) and `use_code` (from `bldg:function` / `käyttötarkoitus`, mapped through `RegisterCodes`).
  - Also inspect `app:X3DMaterial` (`diffuseColor`) in the GML boxes: where non-grey curated wall/roof colours exist, validate whether they reflect real facade colours or generic CAD defaults before using them.
  - Update `HelsinkiLod2._enrich()` (`scripts/data/helsinki_lod2.gd:183`) so when `rows` carry `start_year` and `use_code`, `BuildingReferences.fill()` populates missing `start_year` and building `use` on every matched OSM footprint in Turku!
- **`TurkuNotable` curated override table (`scripts/data/turku_notable.gd`):**
  - Create `TurkuNotable` (mirroring `HelsinkiNotable` in `scripts/data/helsinki_notable.gd`, wired right beside it in the pipeline before register/LOD2 defaults).
  - Populate **~150+ verified OSM `way:<id>` rows** covering every major street-front building in central Turku not already built as a Tier 1 landmark:
    - All remaining perimeter and second-ring blocks around **Kauppatori** (Aurakatu 3–14, Eerikinkatu 6–22, Kauppiaskatu 1–13, Yliopistonkatu 14–34, Kristiinankatu, Brahenkatu).
    - Every riverfront block along **Läntinen Rantakatu** (1–37) and **Itäinen Rantakatu** (4–60), ensuring exact brick/ochre/white/stone alternation along the entire Aura River reflection!
    - Major Jugend, Nordic Classicist, and Functionalist blocks along **Linnankatu**, **Humalistonkatu**, **Puutarhakatu**, **Rauhankatu**, **Eskelinkatu**, **Kaskenkatu**, **Uudenmaankatu**, **Hämeenkatu**, and **Aninkaistenkatu**.
    - Major campus, hospital, and industrial buildings across the **TYKS Hospital Area** (secondary clinics, lab wings, parking decks, and staff/utility buildings along Kiinamyllynkatu, Savitehtaankatu, and Hämeentie), **Kupittaa**, **Itäharju** (historic brick factories / Prisma / K-Citymarket Kupittaa), **Iso-Heikkilä**, and **Linnansatama**.
  - Build a verification tool `tools/turku_fabric_probe.gd` that prints every building > 1,500 m² or ≥ 5 storeys within 1.5 km of Kauppatori and verifies 100% of them either have a Tier 1 bespoke model, a Tier 2 `TurkuNotable` row, or complete OSM + `turku_lod2` tags!

#### T-5.2 District Circles & Turku Architectural Styles (`city_styles.gd`, `architecture_cities_finland.gd`)

- Add dedicated Turku style rows in `ArchitectureCitiesFinland`:
  - `turku_commercial` (`DISTRICT_ONLY`): VI–VII commercial grid core — sharp, authentic contrast between 1895–1925 stone/plaster Jugend/Classicist blocks and 1955–1975 modernist ribbon-window commercial blocks (*Turun tauti*), shopfront ground floors (`g: [["shop", 5], ["stone", 1]]`), flat membrane or dark/copper sheet-metal roofs, zero spurious turrets on post-1930 buildings (`FinlandRelief.turret_fits` enforced via real `turku_lod2` `start_year`!).
  - `turku_jugend`: Puolalanmäki, Kaskenmäki, Humalistonkatu, Rauhankatu — warm buff/sand/ochre/terracotta plaster and rough granite plinths, casement bays, steep black/green/red sheet-metal and tile roofs.
  - `turku_campus`: Yliopistonmäki, Kupittaa Tiedepuisto — travertine/light render, red brick, copper and glass academic/research blocks.
- Expand `CityStyles` Turku district circles from 8 to ~20 covering:
  - VI & VII Commercial Core (`turku_commercial`)
  - Puolalanmäki & Humalistonkatu (`turku_jugend`), Kaskenmäki & Vartiovuori rims (`turku_jugend`)
  - Vanha Suurtori, Piispankatu & Tuomiokirkontori (`turku_empire`)
  - Port Arthur (*Portsa*), Luostarinmäki, Martti, Pajamäki, Raunistula, Pohjola, Nummenmäki (`turku_wood`)
  - Itäinen Keskusta, Iso-Heikkilä, Martinranta, Korppolaismäki (`turku_functional` / `turku_midrise`)
  - Yliopistonmäki, **TYKS Hospital Area (*Kantasairaala* / Kiinamyllynkatu / Savitehtaankatu)** & Kupittaa Science Park (`turku_campus`)
  - Telakkaranta, Linnanfältti, Herttuankulma, Kirstinpuisto (`turku_midrise`)
  - Varissuo, Runosmäki, Lauste, Halinen, Uittamo, Pansio/Perno (`turku_element`)
  - Ruissalo, Hirvensalo, Satava (`turku_villa`)
- Carry Turku district colours/roofs cleanly into `far_city_builder.gd` so the 12 km horizon ring matches the detailed core.

#### T-5.3 Bare-Earth Terrain, Seven Hills, DEM Fix & Orthophoto

- **Investigate and close the Turku DEM check (a) failure (`docs/fidelity-scorecard.md:719-720`):**
  - Run the 9-point DEM spot-height audit on Turku (`GroundModel` `"mml"` 2 m NLS bare-earth COG from Funet vs Terrarium fallback). Verify why check (a) previously failed (e.g., Terrarium building-roof bias before `"mml"` landed, datum offset near Aurajoki tidal reach, or `UrbanSmooth` flattening Turku's steep granite hills) and fix so max spot-height error is well within ≤ 3 m.
- **Preserve Turku's Seven Hills (*Seitsemän kukkulaa*):**
  - Verify `GroundModel` `"mml"` 2 m elevation cleanly resolves **Vartiovuori (~34 m)**, **Puolalanmäki (~29 m)**, **Samppalinnanmäki (~32 m)**, **Kakolanmäki (~42 m)**, **Yliopistonmäki/Vesilinna (~39 m)**, **Kerttulinmäki (~27 m)**, **Aninkaistenmäki**, and **Unikankare** without `UrbanSmooth` bulldozing their granite crags (`natural=bare_rock` / `natural=cliff` outcrops in pinkish-grey southwest-Finnish rapakivi/granite via `rock_outcrops.gd`).
- **Turku aerial orthophoto (`OrthoSource`):**
  - Check City of Turku open WMS (`opaskartta.turku.fi` / `turku.asiointi.fi` `Ilmakuva`, CC BY 4.0, keyless) or NLS Finland open ortho WMS/WMTS in `docs/data-source-register.md` first; if keyless, direct, and CC BY 4.0, add a `"turku_ortho"` source to `OrthoSource` (`scripts/data/ortho_source.gd`) for crisp z19 (0.15 m/px) ground imagery across Turku on High/Ultra, colour-matched to Esri z18!

#### T-5.4 Aurajoki Embankments, Restaurant Boats (*Jokilaivat*) & Harbour Vessels

- **Aurajoki granite quays & railings:**
  - Ensure `shore_apron.gd`, `quay_builder.gd`, and `shore_railings.gd` dress both banks of Aurajoki from Halistenkoski / Tuomiokirkkosilta to Forum Marinum with warm grey-reddish Finnish granite ashlar walls, stone mooring bollards, granite steps down to the water, and black iron chain/post railings where mapped.
  - Tune Aurajoki water optical tint (characteristic brownish-olive clay-rich river water transitioning to brackish dark Baltic green-blue in Airisto/Pitkäsalmi).
- **Aurajoki Restaurant Ships (`QuayMoorings.QUAY_ROWS` + vessel variant):**
  - Add `aurajoki_east` (Itäinen Rantakatu: Auransilta → Teatterisilta → Martinsilta) and `aurajoki_west` (Läntinen Rantakatu: Kristiinankatu → Martinsilta → Tervatori) to `QuayMoorings.QUAY_ROWS` (`scripts/generation/quay_moorings.gd:45`).
  - Add a `"restaurant_boat"` variant in `vessel_prototypes.gd` (converted historic Baltic coasters/steamers like *Svarte Rudolf*, *Papa Joe*, *Donna*, *Cindy*, *Katarina*, *Esposito* with dark/white iron hulls, timber sun-deck canopies, café tables, gangplanks, and warm string-lights at night!).
- **Linnansatama Cruise Ferries & Archipelago Water Buses (`HarbourVesselData`):**
  - Add Port of Turku terminal rows to `HarbourVesselData.CRUISE_LIVERIES` and `QuayMoorings.FERRY_PORTS` (`reach_m: 4500.0`):
    - **Viking Line Terminal** (`60.4352, 22.2195`): Viking red hull/band (*Viking Grace* / *Viking Glory* silhouette & livery).
    - **Tallink Silja Terminal** (`60.4338, 22.2235`): Silja white hull with dark-blue seal mark & `"SILJA LINE"` lettering (*Baltic Princess*).
  - Add **Föli Water Bus (*Vesibussi*, Martinsilta – Forum Marinum – Ruissalo)** (yellow/white Föli livery) and **S/S Ukkopekka** classic white archipelago steamer route to `HarbourVesselData.FERRY_ROUTES`.

#### T-5.5 Transit, Rail, Kakola Funicular & Streetscape

- **Föli yellow buses:** Verify `TransitVehicles.BUS_PAINT["turku"]` exact Föli warm yellow (`#F5A800`), white roof brow, and illuminated route display.
- **VR trains (`train_specs.gd`):** Ensure green-and-white VR InterCity double-deckers (`Ed`/`Edo`), Pendolino (`Sm3`/`Sm6`), and timber/freight wagons appear on the Helsinki–Turku–Harbour main line and railyard tracks.
- **Kakolan funikulaari:** Model the inclined steel rail track, lower Linnankatu glass pavilion, upper Kakolanmäki station, and angled dark-metal/glass funicular cabin on its real OSM way (`57933...` / funicular railway).
- **Aurajoki linden avenues & park flora (`TurkuTrees` + `tree_species.gd`):** Verify `TurkuTrees` places mature *Tilia × vulgaris* (*puistolehmus*) double rows along Itäinen & Läntinen Rantakatu, oaks (*Quercus robur*) on Ruissalo and Samppalinnanmäki, and pines on Vartiovuori/Kakolanmäki crags; pair with classic Turku riverside globe/lantern street lamps (`street_props.gd`).

---

### Phase T-6 — Review Rounds, Compare Sheets, Performance & Sign-Off

- Run batched off-screen capture rounds `tku-r2 … tku-rN` (`--position 4000,4000`, Ultra & High; golden, noon, night, and winter snow) after each major phase into `visual-plan/reviews/tku-rN-<date>/`, writing a review `README.md` with remaining tells after every round.
- Generate `landmark_compare_sheets.py` side-by-side contact sheets pairing every single Tier 1 Turku landmark & major building against its Wikimedia Commons / Finna reference photo from the matching bearing.
- Run `tools/perf_baseline.gd` and `tools/build_bench.gd` for Turku across Fast, High, and Ultra against the `docs/fidelity-scorecard.md:62-70` budgets (Ultra cold time-to-view ≤ 150 s, cached reopen fast, no memory blow-up).
- Present the final 13-vantage city compare sheet + full landmark/major-building contact sheet to the user for the human **"photographic"** gate (`docs/fidelity-scorecard.md` AC-18 — never self-certified by an agent).

---

## Execution Order

`T-0` → `T-1` (fix the 12 coarse models) → `T-5.1 & T-5.2` (`turku_lod2` year/class + `TurkuNotable` + districts, transforming thousands of buildings at once) → `T-2` (Cathedral, Castle, Kauppatori polish) → `T-3A` (Kauppatori 360° perimeter) → `T-3B` (Aurajoki waterfront) → `T-5.3–T-5.5` (hills, orthophoto, restaurant ships, Viking/Silja, funicular) → `T-4` (bridges) → `T-3C & T-3D` (universities, hospitals, stations, Logomo, skyline towers, arenas) → `T-6` (final review & sign-off).

Each phase ends green on tests and visually capturable, and Tier 1 landmarks can be built in parallel batches of 4–6 independent files per batch.

---

## Critical Files & Reuse Kits

- **New Turku landmark & major-building models (one file per building, ≤ 1000 lines):**
  `scripts/generation/landmarks/finland_turku/ft_<name>.gd`, dispatched by `scripts/generation/landmarks/finland_turku/landmark_set_finland_turku.gd`.
- **Registries & selection:**
  `scripts/data/turku/tku_reg_{centre,aurajoki,hills,harbour,skyline}.gd`, `scripts/data/landmark_registry_finland_turku.gd`, `scripts/data/landmark_registries.gd`, `scripts/data/location_data.gd:446`, `scripts/data/preset_views.gd`.
- **City-wide major buildings & open data:**
  `scripts/data/turku_notable.gd` (new), `tools/prepare_turku_lod2.py`, `scripts/data/helsinki_lod2.gd`, `scripts/data/ortho_source.gd`, `scripts/data/ground_model.gd`, `scripts/data/ground_model_fetcher.gd`.
- **Districts, bridges, riverfront & transit:**
  `scripts/generation/city_styles.gd`, `scripts/generation/architecture_cities_finland.gd`, `scripts/data/bridges/bridge_specs_north_europe.gd`, `scripts/generation/quay_moorings.gd`, `scripts/data/harbour_vessel_data.gd`, `scripts/generation/vessel_prototypes.gd`, `scripts/generation/vehicles/train_specs.gd`, `scripts/generation/vehicles/transit_vehicles.gd`.
- **Shared geometry kits (reuse, never duplicate):**
  `LandmarkMesh` (`box`, `lathe`, `frustum`, `gable`, `grid`, `merge`, `poly_prism`), `LandmarkDetail` (`column`, `colonnade`, `cornice`, `balustrade`, `pierced_face`, `arch`, `window`), `LandmarkFrKit`, `LandmarkFrParts` (`opening`, `openings`, `facade`, `buttress`, `band`, `cornice_ring`, `dormer`, `chimney`, `roof_trim`), `LandmarkFhParts` (`crow_gable`, `arcade`, `win_row`, `strips`, `slope_roof`), `LandmarkCoreAGothic` (`stepped_gable`, `lancet`, `buttress`), `SkyKit` (night-lit office/residential towers), `LandmarkBrKit`, `LandmarkStationKit`, `TallShipDetails`, `StatueBuilder`, `PlazaLife`, `LandmarkLights.FLOOD_META` / `HALO_META`, `LandmarkTerrain.SEAT_META`, `LandmarkStairCut`.
- **Working-tree & repository safety rules:**
  - Multiple shared files (`location_data.gd`, `preset_views.gd`, `architecture_cities_finland.gd`, `city_styles.gd`, `harbour_vessel_data.gd`, `quay_moorings.gd`, `train_specs.gd`, `transit_vehicles.gd`, `ground_model.gd`, `world_cache.gd`, etc.) currently carry uncommitted Helsinki/Stockholm changes in the working tree. Keep edits to shared files minimal and surgical, bump `WorldCache.BUILD_VERSION` per visual batch, never revert other cities' work, and never commit or push unless explicitly asked.
  - Every `.gd` file under `scripts/` must remain ≤ 1000 lines (`tools/check_class_size.sh`). Split `architecture_cities_finland.gd` into `architecture_cities_turku.gd` once Turku eras/styles approach the ceiling.
  - Follow the Planet Render 360 design system (`project/README.md`) for any UI label or credit string.

---

## Verification

- **Per landmark / major-building batch (headless, in background via `tools/godot_bg.sh --headless`):**
  - `tests/turku_landmarks_test.gd` (extended to cover all ~76 Turku types: registry presence, coordinates, alias resolution, 2–16 parts, 1k–150k triangles, height within `max(2 m, 3%)`, `SEAT_META` / clearance / non-clipping checks)
  - `tests/landmark_test.gd`, `tests/landmark_catalog_test.gd`, `tests/landmark_fidelity_test.gd`, `tests/landmark_placement_test.gd`, `tests/landmark_lights_test.gd`
  - `tools/check_class_size.sh` (and `tools/godot_bg.sh --headless --import` whenever adding a new `class_name`)
- **Per city / fabric / vessel / open-data task (headless, background):**
  - `tests/turku_open_data_test.gd`, new `tests/turku_notable_test.gd`, `tests/architecture_test.gd`, `tests/city_detail_test.gd`, `tests/shoreline_test.gd`, `tests/quay_moorings_test.gd`, `tests/marina_test.gd`, `tests/bridge_arches_test.gd`, `tests/train_test.gd`, `tests/preset_views_test.gd`, `tests/plaza_life_test.gd`
- **Visual verification (batched, off-screen `--position 4000,4000`, never `--always-on-top`, in background):**
  - Studio sheets: `tools/godot_bg.sh --path . --position 4000,4000 --script tools/capture_landmarks.gd -- --types=<batch> --tag=tku_batchN` + `--night`, followed by `python3 -I tools/landmark_compare_sheets.py --tag=tku_batchN`.
  - In-world looks: `tools/godot_bg.sh --path . --position 4000,4000 --script tools/capture_presets.gd -- --places=turku --preset=3 --tag=tku-rN --times=golden,noon,night --looks="<13 open-space eyes>"`. Inspect every frame before counting it; discard and relocate any eye inside a building, tree crown, or ship hull.
- **Final gate:**
  - Windowed `tests/world_cache_test.gd` and `tests/screenshot_test.gd` (batched once at the end, off-screen in background), `tools/perf_baseline.gd` on Turku Fast/High/Ultra, and human review of the side-by-side reference comparison sheets. (Skip live-network `tiles_test` / `exit_tile_test` during routine offline loops.)

---

## Open Decisions (Recommendations in Brackets)

1. **Evolving Turku construction sites (Fuuga Music Hall, TYKS U-sairaala & Joint Ferry Terminal at Linnansatama):** Model them in their completed/planned architectural form or strictly as current OSM footprints stand? **[Verify each against `turku_detailed.osmb` / current OSM before modelling: model Fuuga if its footprint is mapped, match TYKS U-sairaala's current standing/demolition state on Kiinamyllynkatu, and keep the existing separate Viking & Silja terminals at Linnansatama until OSM maps the 2027 joint terminal as active.]**
2. **Outer skyline scope (Gatorade Center, Meyer Turku shipyard cranes in Perno, Ukko-Pekan silta, Ruissalo villas):** Include all in Phase T-3D/T-4, or focus inner-city + Kupittaa + Harbour first? **[Include all, ordered last in T-3D: the Meyer cranes and Pääskyvuori tower anchor Turku's east–west horizon, and Ruissalo/Artukainen sit inside the 9.5 km Turku zone when moving the camera.]**
3. **Turku aerial orthophoto (`OrthoSource`):** Wire City of Turku WMS `Ilmakuva` at runtime (like HSY in Helsinki/Espoo) if keyless and CC BY 4.0? **[Yes — verify GetCapabilities/GetMap and licence in `docs/data-source-register.md` first; fall back cleanly to Esri z18 if rate-limited or unavailable.]**
