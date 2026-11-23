# Plan: make Helsinki look like the real city

## Context

The request is to make Helsinki "super realistic", with every landmark and major building
looking like it does in real life. `PLAN_Helsinki_super_realistic.md` in the repo root is
was empty, so this is a fresh plan, copied here as the tracker.

Helsinki is the app's default place (`PresetViews.DEFAULT_ID`), so it is the first thing
every user sees. It has had one hero pass (`.agents/plans/2026-11-03-helsinki-espoo-hero.md`,
HE-0…HE-6 done). Every review since rates it "recognisable", never "photographic"
(`docs/fidelity-scorecard.md:417-491`). `docs/helsinki-landmark-sources.md` states outright
that no model has been rated against photographs.


## Progress (tracker)

Legend: ✅ done · 🔄 in progress · ⬜ not started. Updated as work lands.

| Phase | Status | Notes |
|---|---|---|
| H-0 Baseline and tooling | ✅ | selection audit and fix, measured heights, 15 city-view refs, per-landmark refs (3–7 CC/PD photos with `README.md` per type under `visual-plan/refs/landmarks/`, incl. 9 regional `LandmarkRegistryFinlandHelsinki` sets + 3 new H-1 sets + `<3`-photo top-ups), in-world baseline & final capture rounds |
| H-1 Opening views | ✅ | all opening-view types built/upgraded incl. `swedish_embassy_helsinki`, `supreme_court_helsinki`, `runeberg_statue`, refined `uspenski_cathedral`, `old_market_hall_helsinki`, `market_square_helsinki`, `havis_amanda`, `kappeli` (+ Espa Stage), `skywheel_helsinki` (`skyline_priority: 1`), and `FLOOD_META` night lighting; day/night studio & compare sheets in `visual-plan/captures/{hel_r2_upgrades,hel_r2_night}/` |
| H-2 The centre | ✅ | Groups C & D complete; `kiasma` (curved zinc shell + Mannerheim statue), `bank_of_finland` (rusticated/pilastered front + Snellman statue), `amos_rex` (tilted concrete cones + oculi), `kamppi_chapel` (12.1 m tilted spruce vessel + lobby), and `lasipalatsi` (24 m tower + Bio Rex neon) upgraded with PBR materials & `FLOOD_META` |
| H-3 Töölö, Kallio, harbour districts, east | ✅ | Groups E & F complete; `helsinki_ice_hall`, `linnanmaki` (+ Taiga & Rinkeli), `hotel_kalastajatorppa`, `kallio_library`, and `lauttasaari_manor` (13.5 m) upgraded; `west_metro_coverage_test.gd` (`lauttasaari_manor` 13.5 m, `studio_aalto` 9.2 m) & `FLOOD_META` night lighting green |
| H-4 Suomenlinna and the islands | ✅ | Group G complete; `suomenlinna_dry_dock`, `lonna_island`, and `kustaanmiekka_bastions` rebuilt to PBR standard with `FLOOD_META`; `suomenlinna_test.gd` PASS |
| H-5 Bridges | ✅ | Pitkäsilta, Crusell, Isoisänsilta, Lauttasaari, Kulosaari updated; Kruunuvuorensilta verified within 1000-line/triangle budgets; `bridge_specs_test.gd` PASS |
| H-6 City fabric | ✅ | window palette, harbour render palette, `"helsinki"` in `CityStyles.FAR_DISTRICT_CITIES`, and `HelsinkiNotable` expanded to 25 verified central Helsinki OSM rows (`helsinki_notable_test.gd` & `far_city_test.gd` PASS) |
| H-7 Harbour, transit and ground | ✅ | Suomenlinna & JT-Line ferries, Viking/Silja/Tallink/Eckerö liveries, Katajanokka icebreakers, market boats, M100/M200/M300 metro, Artic trams, HSL blue buses, Finnish pink-grey granite & winter snow pass verified (`hel-r10-winter-2026-11-23`) |
| H-8 Review rounds and sign-off | 🔄 | rounds `hel-r10-2026-11-23` (`--preset=3 --look_ahead=100`, golden/noon/night, 12 open-space eyes) and `hel-r10-winter-2026-11-23`, studio/compare sheets (`hel_r2_upgrades`, `hel_r2_night`), `docs/fidelity-scorecard.md` §9 row, `perf_baseline`, and windowed `world_cache_test` / `screenshot_test` all PASS at `BUILD_VERSION = 321`; **the AC-18 "photographic" call is the user's and remains open** |

Final state, 2026-11-20: every Helsinki registry row builds a multi-part model, most from their own class (the Cathedral,
Sibelius Monument and a few others keep their legacy generators), rebuilt from
Commons photos and OSM/LoD2 measurements by seven parallel agents, then regression-tested. Agent
ratings are pre-ratings: model sheets read as recognisable but several are still crude (windows as
dark rectangles, simplified roofs), most night lighting has not been seen in a capture, and `clear_m`
for the moved landmarks has not been checked in-world. Side-by-side sheets for the user:
`visual-plan/reviews/hel-r6-final-2026-11-20/sheet_city_{1,2}.jpg` (twelve city views) and the
per-group compare sheets `visual-plan/captures/hel-r1-{A,B,C,D,E,F,G}/`. Performance against
2026-11-15 is recorded in `docs/fidelity-scorecard.md` (Helsinki round hel-r6).

## Definition of done, per landmark

A landmark is done only when all of these hold. This is the standard Parliament House meets.

1. **References:** 3+ Commons photos (front, quarter, aerial or roof; CC/PD only) in
   `visual-plan/refs/landmarks/<type>/` with author, licence and source in its `README.md`.
   Night photo too where the building is floodlit.
2. **Measured envelope:** footprint from the OSM way (stored outline, simplified ≤ 1 m),
   eaves/ridge/tower heights from `HelsinkiLod2` or a published figure. Anything still
   estimated is listed as such in `docs/helsinki-landmark-sources.md`.
3. **Signature features** from the tables below are readable in the capture at 150 m.
4. **Facade rhythm counted from the photo:** bay count, storey count, window proportions.
5. **Materials:** right stone/render/brick/copper set and hue sampled from the photos;
   no surface left as flat paint.
6. **Roof:** real form and finish (Helsinki is seen from above in fly mode).
7. **Site:** steps, forecourt, statues, flagpoles, and `clear_m` or `clear_offsets_m` that
   removes the duplicate OSM building without eating neighbours.
8. **Night:** `FLOOD_META` / `HALO_META` / "Lamp" parts matching the real lighting.
9. **Budgets:** 2–16 parts, ≤ 150k triangles, top within max(2 m, 3%) of `height_m`
   (`tests/landmark_catalog_test.gd`), class file ≤ 1000 lines.
10. **Evidence:** a compare sheet (photo beside render, same bearing) from the model tool and
    one in-world capture from an open-space eye, both checked by eye before ticking.

## Phases

Each phase ends tested and capturable, so the work can stop after any of them.

### H-0 Baseline and tooling (no visual change)

- ✅ Copy this plan into `PLAN_Helsinki_super_realistic.md` and use it as the tracker.
- ✅ **Measure landmark selection.** Run `tools/audit_landmark_placement.gd` /
  `capture_presets.gd --audit` from seven eyes (harbour opening, Senate Square, Töölönlahti,
  Kamppi, Hakaniemi, Kalasatama, Jätkäsaari) at High and Ultra. Record which registry rows
  build and which fall back to OSM boxes. Also establish whether streaming
  (`world_streamer.gd`) re-selects landmarks as the eye moves.
  - *Done 2026-11-19 with `tools/audit_helsinki_selection.gd` (registry slots from seven eyes,
    High and Ultra). Before: from the harbour eye on Ultra, Parliament, Kiasma, Oodi, the National
    Museum, Kallio Church, Temppeliaukio, Kamppi Chapel, Amos Rex, Merikasarmi and the
    Katajanokka terminal fell back to OSM boxes; five priority slots went to far towers.
    Streaming runs a fresh pipeline per stretch (`world_streamer.gd`), so selection re-runs
    round each new centre.*
- ✅ **Fix selection** based on that measurement. Preferred order:
  1. Set `ultra_registry_limit: 26` on the `helsinki_cathedral` row (existing knob,
     `landmark_sites.gd:58-60`).
  2. Move true towers to the skyline channel (`skyline: true`, 110 slots on Ultra) if it
     dispatches to bespoke builders: the five Kalasatama towers, Clarion, Salmisaari
     chimneys, Pasila link tower. Verify first; it was written for `NycTowerSpecs`.
  3. If central landmarks are still dropped, raise the caps for Helsinki only after timing
     the "Roads & landmarks" stage against the budget in `fidelity-scorecard.md:41-80`.
  - *Done: `ultra_registry_limit: 26` on the cathedral row; the skyline channel dispatches by
    type, so bespoke builders work there. `skyline: true` on Torni, Majakka, Loisto, Lumo One,
    Horisontti, Visio, Clarion, Salmisaari, Kallio Church, St John's, the National Museum and
    the Olympic Stadium; low-rise models (Havis Amanda, Kappeli, Amos Rex, Kamppi Chapel, new
    low-rise rows) see from 1.5 km (`radius_m`), Allas 2 km. After: on Ultra every central
    low-rise landmark within ~1.5 km of each of the seven eyes builds; caps were not raised.*
- ✅ **Baseline captures**, one batched background run at Ultra and one at High:
  - Model sheets for all Helsinki types (`tools/capture_landmarks.gd --types=…`, day and `--night`).
  - In-world: opening view, card view, and twelve `--looks` eyes in open space (Market
    Square quay, Senate Square, Esplanadi, Rautatientori, Kansalaistori, Mannerheimintie at
    Parliament, Hakaniementori, Töölönlahti path, Kaivopuisto shore, Katajanokka quay, a
    drone eye over South Harbour, a drone eye over Kruunuvuorenselkä). Eye height over water
    is measured from the seabed, so harbour views use drone eyes.
  - Summer golden, noon, night; winter (`helsinki_winter`, weather 73).
- 🔄 **Reference photos:** restore `visual-plan/refs/helsinki/` (the README is in commit
  `ed943f12`; three Commons photos) and widen it to ten city views matching the eyes above.
  Collect per-landmark sets for H-1 first, the rest phase by phase. Sources: Wikimedia
  Commons and Finna (CC BY / PD only). Run `tools/landmark_ref_inventory.gd` to track coverage.
- ✅ **Measured-height table:** for every Helsinki registry row, read eaves and top from
  `HelsinkiLod2` and the OSM way; record model height, measured height and difference in
  `docs/helsinki-landmark-sources.md`. Verify LOD2 covers each footprint before relying on it.
  - *Done: `tools/helsinki_measured_heights.gd`; table under "Measured heights (H-0)" in the
    sources doc, with the rows whose match needs a hand check flagged.*

### H-1 The opening views: Market Square, Senate Square, Katajanokka

These are in frame at launch, so they come first. One class file per landmark from here on
(pattern: `landmark_fh_parliament.gd`), using `LandmarkMesh`, `LandmarkDetail`, `LandmarkKits`,
`landmark_fh_util.gd` and `landmark_fh_parts.gd`.

| Landmark | State | Must be readable |
|---|---|---|
| Helsinki Cathedral | detailed, unchecked | Green central dome with gilt stars on the drum, four corner domes, four Corinthian porticos, twelve zinc apostles on the roof corners, white render, the great stair, two side pavilions, Alexander II statue |
| Government Palace | shared box | Long ochre front on the square's east side, central Corinthian portico with pediment and low dome, rusticated ground floor, courtyard wings |
| University Main Building | shared box | Mirror of the above on the west side, Ionic portico, plain pediment, no dome |
| National Library | detailed, unchecked | Ochre with white Corinthian half-columns all round, low central dome, rear Rotunda |
| Sederholm House, Bock House (new) | missing | South side of the square: low grey stone merchant house, Bock House's balcony and columns |
| Uspenski Cathedral | medium | Dark red brick, 13 gilt onion domes (centre plus twelve), green copper tent roofs, bell tower over the west door, granite rock base |
| Enso-Gutzeit HQ | coarse | White marble grid of square recessed windows, set-back top floor; fix the height so it stops masking Uspenski (measure against LOD2) |
| Presidential Palace | medium | Pale front, Ionic columns over a three-arched base, pediment, forecourt with iron railings and gates |
| City Hall and the Market Square row (new) | missing | Pale blue Empire front with central portico; Swedish Embassy (palazzo), Supreme Court |
| Market Square (new) | name-only life | Orange stall tents, Keisarinnankivi obelisk with gilt double eagle, granite quay steps, Cholera Basin |
| Old Market Hall | detailed, unchecked | Striped yellow and red brick, arched windows, long ridge lantern |
| Havis Amanda | coarse | Bronze nude on a granite pedestal, four sea lions spouting into the basin |
| Kappeli, Esplanadi (extend) | coarse | Glazed pavilions; add the Espa stage, Runeberg statue and lime avenues |
| Allas Sea Pool, SkyWheel | coarse | Blue-and-white gondolas with the one sauna cabin; three pools, timber decks |
| Merikasarmi, Katajanokka Terminal | coarse | Ochre Empire wings with white porticos; brick terminal |
| Katajanokka Casino, Hotel Katajanokka (new) | missing | White casino pavilion on the point; red-brick prison cross plan with perimeter wall |
| Olympia Terminal, Makasiiniterminaali (new) | missing | 1952 functionalist terminal, yellow render, Olympic-era lettering band |
| Observatory, Tähtitorninvuori (new) | missing | Engel's three-towered observatory on the hill closing the harbour view south |
| German Church (new) | missing | Red brick, slender copper spire, visible above Kaartinkaupunki |

### H-2 The centre: Rautatientori to Töölönlahti

| Landmark | State | Must be readable |
|---|---|---|
| Central Station | detailed, unchecked | Pink Hanko granite, the great arch with copper-framed glazing, the four Lyhdynkantajat giants holding globe lamps, 48.5 m clock tower with copper cap, platform roofs |
| Ateneum | medium | Stone palazzo, caryatids in the central bay, medallion busts, pediment group |
| National Theatre (new) | missing | Grey granite Jugend castle front, two round towers, red tile roof, Aleksis Kivi statue |
| Sokos, Postitalo, Sanomatalo (new) | missing | Functionalist ribbon-window block; brick-clad post office; all-glass media house |
| Kiasma | medium | Curved zinc-and-aluminium shell, glass west wall, Mannerheim equestrian statue in front |
| Oodi | medium | Spruce-clad swooping underside, cantilevered entrance canopy, white glass top floor, undulating roof |
| Music Centre | medium | Green patinated-copper mesh block, glass foyer, sloping lawn roof |
| Finlandia Hall | medium | White marble, black granite base, wedge-shaped auditorium tower, long foyer to the bay |
| Parliament House | done | Re-check only |
| National Museum | medium | Grey granite and soapstone, tall tower with copper spire, bear statue, new round annexe if built |
| Lasipalatsi, Amos Rex | coarse | White functionalist block with neon signs and the chimney; five tiled domes with oculi in the square |
| Kamppi Chapel | coarse | Flaring spruce drum, horizontal plank seams |
| Kamppi Centre, Tennispalatsi, Forum (new) | missing | Glass mall front and bus terminal; four barrel-vault roofs with round end windows |
| Stockmann | wrong | Sigurd Frosterus's red-brick block: vertical piers, copper roof, the clock on the Aleksanterinkatu corner, Three Smiths statue |
| Hotel Torni | detailed, unchecked | 69.5 m brick tower, stepped top |
| Swedish Theatre, Hotel Kämp, Rautatalo, Erottaja fire station (new) | missing | White rotunda at the Esplanadi head; brick fire station with its lookout tower |
| Old Church, St Henry's, Mikael Agricola, St John's | missing / medium | Agricola's 97 m needle spire; St John's twin 74 m spires; Engel's wooden church |
| Bank of Finland, House of Estates, Ritarihuone (new) | missing | Säätytalo's gilt pediment relief and Corinthian portico |
| Temppeliaukio | medium | Copper-wire dome with a ring of 180 skylights, rubble rock wall, low concrete entrance |

### H-3 Töölö, Kallio, harbour districts, east

Olympic Stadium (72 m white tower, canopy over the new stands, Paavo Nurmi statue), Swimming
Stadium, Bolt Arena, Ice Hall, Opera (white tile and glass on the bay), Sibelius Monument
(600 welded tubes plus the face), Kulttuuritalo (curved red-brick auditorium, copper office
wing), Winter Garden, Linnanmäki (add Taiga and the wheel), Kallio Church (granite tower
closing Siltasaarenkatu), Kallio Library, Hakaniemi Market Hall, the Ympyrätalo, Merihaka
slabs, Hanasaari (confirm what still stands), Pasila link tower and Tripla, Kalasatama
towers each with its own facade and crown, Redi, Korkeasaari lookout tower, Clarion, West
Terminal 2, Cable Factory, Salmisaari, Löyly (faceted timber cloak), Hietalahti Market Hall,
Sinebrychoff, Design Museum, Kaivopuisto's Ursa observatory and embassies, Hotel
Kalastajatorppa, the Aalto houses, Lauttasaari church and manor.

Each gets the same definition of done. Rows outside the 22–26 that can show at once are
still modelled, since landmark search and walking move the eye.

### H-4 Suomenlinna and the islands

Check `SuomenlinnaFortress` walls against photos; raise King's Gate, the dry dock and the
Jetty Barracks (74 lines for all three) to standard; add the church-lighthouse detail,
Kustaanmiekka bastions and guns, the submarine Vesikko, Lonna, Valkosaari (NJK pavilion),
Luoto (Klippan villa), Harmaja lighthouse, Uunisaari.

### H-5 Bridges

Compare the five `br_helsinki_*` rows (`bridge_specs_north_europe.gd:111-165`) and
Kruunuvuorensilta against photos. Pitkäsilta: granite arches with shrapnel scars. Crusell:
single leaning pylon. Isoisänsilta: white arch. `landmark_fh_crown_bridge.gd` is at 972 of
1000 lines and at its part and triangle ceilings, so any change there must be budget-neutral
or split out first.

### H-6 City fabric

- **Districts:** add circles in `city_styles.gd` for Kluuvi/Kamppi (commercial core),
  Kaartinkaupunki, Hakaniemi, Sörnäinen, Alppila, Pasila, Meilahti, Hermanni, Arabianranta,
  Kruunuvuorenranta, Hernesaari. Add a `helsinki_commercial` row in
  `architecture_cities_finland.gd` for the centre: stone and brick fronts, shop-window
  ground floors, flat or low copper roofs.
- **Per-building facts first:** check how often `HelsinkiRegister` facade material and
  `HelsinkiLod2` roof form actually reach the facade and roof choice; fix where they are
  overridden by the district roll.
- **Tells from the reviews:** waterfront facade brightness, window repetition
  (`wall_variety.gd`, `facade_composer.gd`), quay edge profile (`quay_builder.gd`).
- **Named major buildings without a model** get register-driven overrides (colour, material,
  storeys) rather than landmark slots: a small `HelsinkiNotable` data table keyed by OSM way.

### H-7 Harbour, transit and ground

- **Suomenlinna ferry** on its mapped route from Kauppatori, and the JT-Line water buses,
  extending `harbour_ferries.gd` (currently Staten Island only).
- **Cruise ferries:** Silja white with the seal mark, Viking red, Tallink, Eckerö, chosen by
  terminal (`cruise_ferry_model.gd`, `quay_moorings.gd`). Icebreaker fleet moored at Katajanokka.
- **Small boats:** Finnish fleet for `marina_builder.gd` (wooden boats, sailboats, fewer
  white motor yachts), market boats at Cholera Basin.
- **Metro:** orange M100/M200/M300 trains on the surface sections east of Sörnäinen
  (`train_specs.gd`). **Buses:** HSL blue and white (`transit_vehicles.gd:43-44`).
  **Trams:** route number and destination boards; Artic body proportions.
- **Granite:** pink-grey rock with lichen for `natural=bare_rock` and shore rock
  (`rock_outcrops.gd`, `ground_shader.gd:287-289`), plus the granite kerbs and setts of the centre.
- **Winter:** pull saturation and snow brightness toward the January reference.

`road_builder.gd`, `street_props.gd`, `vegetation_builder.gd`, `terrain_builder.gd`,
`ground_cover.gd` and `pipeline.gd` have uncommitted work in the tree. Edits there stay
minimal, and nothing of that work is staged or committed with this plan's changes.

### H-8 Review rounds and sign-off

Repeat the H-0 capture set after each phase into `visual-plan/reviews/hel-rN-<date>/`. Add a
row per round to `docs/fidelity-scorecard.md` with the biggest remaining tell. Agent grades
are pre-ratings only; the final side-by-side sheet (ten city views, every H-1 and H-2
landmark) goes to the user for the "photographic" call. Finish with `tools/perf_baseline.gd`
for Helsinki on all presets against the 2026-11-15 numbers.

## Files

- **New, one per landmark:** `scripts/generation/landmarks/finland_helsinki/landmark_fh_<name>.gd`.
- **Split when rebuilding:** `landmark_fh_hero_civic.gd`, `landmark_fh_hero_harbour.gd`,
  `landmark_fh_kalasatama.gd`, `landmark_fh_katajanokka.gd`, `landmark_fh_jatkasaari.gd`,
  `landmark_fh_lasipalatsi.gd`.
- **Wiring:** `landmark_set_finland_helsinki.gd` (dispatch), `landmark_registry_helsinki_hero.gd`,
  `landmark_registry_inner_helsinki.gd`, a new `landmark_registry_helsinki_centre.gd` listed in
  `landmark_registries.gd`; outlines in `landmark_fh_inner_footprints.gd` or a new footprint file.
- **Selection:** `scripts/data/location_data.gd:452` (cathedral row), `landmark_sites.gd` only if caps change.
- **Fabric:** `city_styles.gd`, `architecture_cities_finland.gd`, `building_era.gd`.
- **Harbour and transit:** `harbour_ferries.gd`, `cruise_ferry_model.gd`, `quay_moorings.gd`,
  `marina_builder.gd`, `vehicles/train_specs.gd`, `vehicles/tram_specs.gd`, `transit_vehicles.gd`.
- **Docs:** `docs/helsinki-landmark-sources.md`, `docs/fidelity-scorecard.md`,
  `docs/architecture-styles.md`, `PLAN_Helsinki_super_realistic.md`.
- **Tests:** extend `tests/helsinki_hero_landmarks_test.gd`, `inner_helsinki_coverage_test.gd`,
  `finland_hero_test.gd`; new `tests/helsinki_centre_landmarks_test.gd` and one test per new
  system (ferry route, liveries, metro).

## Verification

- After each landmark: `tools/run_tests.sh landmark` and `tools/run_tests.sh helsinki`
  through `tools/godot_bg.sh --headless`, in the background; `tools/check_class_size.sh`.
- Model sheets: `tools/godot_bg.sh --path . --script tools/capture_landmarks.gd --position 4000,4000 -- --types=<…> --tag=hel-rN`,
  then `python3 -I tools/landmark_compare_sheets.py --tag=hel-rN`.
- In-world: `tools/godot_bg.sh --path . --script tools/capture_presets.gd --position 4000,4000 -- --places=helsinki --preset=3 --tag=hel-rN --times=golden,noon,night --looks="…"`,
  batched once per phase with `screenshot_test.gd` and `world_cache_test.gd`. Every `--looks`
  frame is checked for an eye inside a mass before it counts.
- Skip `tiles_test` and `exit_tile_test` (live network).
- No commits unless asked; when asked, stage only this plan's files by path.

## Risks and open decisions

1. **Scale.** About 85 existing models plus roughly 45 new ones. Recommended order is
   H-0, H-1, H-2, then H-6/H-7 before H-3 to H-5, because fabric and harbour show in every frame.
2. **Landmark cap.** Recommended: raise Helsinki to 26 on Ultra with the existing knob and
   use the skyline channel for towers. Raising caps further costs build time; measured in H-0.
3. **Hanasaari, National Museum annexe, Bunkkeri and other changing sites** are modelled as
   they stand today; each is confirmed against OSM and a dated source before work.
4. **Dimensions and feature counts in the tables above are from memory** and are starting
   points. Each is verified against photos, OSM and LOD2 before modelling.
5. **Photographic is a human call.** Agent ratings never close the plan.
