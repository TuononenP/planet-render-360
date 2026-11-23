# Bangkok super-realistic: landmarks and city

> Tracker in the house style of `PLAN_Stockholm_super_realistic.md`: claim a task, tick it only after its
> validation passes, add one evidence line. Status legend: `[x]` done and validated, `[~]` in progress, `[ ]` open.
> This file replaces the chat summary that stood here. It is the first draft
> (`~/.claude/plans/read-make-bangkok-super-rustling-jellyfish.md`, 2026-11-19) checked against the code and the
> bundled OSM snapshot on 2026-11-20 and expanded. Nothing is implemented yet.
> Heights, counts and dates of real buildings in this plan are starting values from memory unless a row says
> "OSM"; each is verified in BK-0.5 before it is modelled. OSM ids, distances and bearings are measured from the
> bundled snapshot (view centre 13.75398, 100.50144; bearings clockwise from north).

## Tracker

- [x] BK-0.1 Scene truth: what the capital view draws beyond 1.2 km (river, far blocks, landmark radius) — probed in `visual-plan/reviews/bangkok-bk01-stream-2026-11-23/`; Decision 1 resolved to Option (c) streamed river worlds (`13.7455, 100.4905`).
- [x] BK-0.2 Baseline capture round `bangkok-r0` at the fixed eyes — captured `visual-plan/reviews/bangkok-r0-2026-11-23/` (`E1`–`E11`) and `visual-plan/captures/bk_lm_base/` (4 existing heroes).
- [x] BK-0.3 Slot budget wired and pinned by test — Fast 6 / Balanced 12 / High 18 / Ultra 22 icons + 4 bridges + 9 skyline towers pinned in `tests/bangkok_landmarks_test.gd` (`PASSED`).
- [x] BK-0.4 Reference photos per landmark — 108 Wikimedia Commons CC/PD photos downloaded & vetted via `tools/bangkok_commons_refs.py` into `visual-plan/refs/bangkok/` and 29 `visual-plan/refs/landmarks/<type>/` folders.
- [x] BK-0.5 Sources doc with measured sites — `docs/bangkok-landmark-sources.md` and Bangkok section in `docs/data-source-register.md`.
- [x] BK-0.6 Snapshot repair (2500 m ring re-cut, completeness check) — re-cut `assets/osm_snapshots/capital_th_10375398_28050144_ring2500.osmb` (`820` highways, `158` waterways, sha256 `0854dc58…c4`), manifest & `bundled_osm.gd` updated.
- [x] BK-1 Bangkok batch wiring, kit additions, test file — `landmark_mse_kit2.gd`, `landmark_registry_thailand_bangkok.gd`, `landmark_set_thailand_bangkok.gd`, wired in `landmark_registries.gd`, verified by `tests/bangkok_landmarks_test.gd`.
- [x] BK-2 Centre set (Giant Swing, Wat Suthat, Democracy Monument, Loha Prasat, Golden Mount, Mahakan Fort) — 6 builders built & visually verified day/night in `visual-plan/captures/bk_bk2/` & `bk_bk2_night/`.
- [x] BK-3 Old-town fabric (districts, rule, height cap, temple halls, chedis, City Hall, Ratchadamnoen blocks) — 16 districts, `bangkok_rule`, `16/20 m` caps, Thai tiered-roof temple halls, `man_made=stupa` (`StupaBuilder`), City Hall reference, `"bangkok"` in `CityDetail.CITIES`; `tests/bangkok_fabric_test.gd` (`PASSED`) & `bangkok-r1` reviewed.
- [x] BK-4 Existing landmarks to the bar (Grand Palace, Wat Pho, Wat Arun, Hua Lamphong) — upgraded in place (`138.6k`, `113.8k`, `55.8k`, `31.4k` tris) and verified day/night in `visual-plan/captures/bk_bk456/` & `bk_bk456_night/`.
- [x] BK-5 Second ring of landmarks (Sanam Luang set, royal wats, forts, Thonburi bank) — 13 builders built & verified day/night in `visual-plan/captures/bk_bk456/` & `bk_bk456_night/`.
- [x] BK-6 River bridges and canal bridges — bespoke `Rama VIII`, emerald `Memorial`, planted `Phra Pok Klao` Sky Park, `Phra Pinklao`, `Rama IX` colour, and generic `BangkokCanalBridges`; `bridge_specs`/`param`/`select`/`arches` tests `PASSED`.
- [x] BK-7 River, canals, boats — silty olive-brown Chao Phraya & khlong palette (`water_surface.gd`/`water_builder.gd`), `BangkokWaterfront` floodwalls/balustrades/floating piers, `BangkokVesselModels` + `HarbourFerries` (longtail, express, ferry, Saen Saep, dinner cruise, rice barge); verified in `bangkok-r2-river` & water/vessel tests (`PASSED`).
- [x] BK-8 Trees and atmosphere — 10 Thai tree species + `bangkok_mix` (`<= 4%` street palms), Sanam Luang open central oval lawn + tamarind perimeter ring, humid `TROPICAL_SKY` haze & monsoon clouds; `canopy_vegetation`/`tree_lod`/`climate`/`haze`/`sky` tests `PASSED`.
- [x] BK-9 Streets and vehicles — Thai fleet, 5 Bangkok taxi liveries, `TukTukModel`, 5-livery BMTA/Thai Smile buses, square TH concrete utility poles (buried on Ratchadamnoen & Grand Palace), `BangkokStreetLife`, yellow centre lines; vehicle/street tests `PASSED` & `bk_cars` captured.
- [x] BK-10 Night — `FLOOD_META` / `*Lamp` rigs across all 26 landmarks, Yaowarat & Khao San neon (`screens`/`sign_stack`), pier/vendor/kinnari/dinner-cruise lamps; `landmark_lights` & `street_screens` tests `PASSED`, verified in `bangkok-r2` & `bangkok-r2-river` night frames.
- [x] BK-11 Outer landmarks and skyline (Dusit, Chinatown, towers) — 4 bespoke outer landmarks (`wat_benchamabophit`, `ananta_samakhom`, `chinatown_gate_wat_traimit`, `wat_mangkon_kamalawat`), 9 `BkTowerSpecs` skyline towers, bogus `way:402124521` clamped, `tower_looks.gd:10` fixed; verified in `visual-plan/captures/bk_bk11/` & `bk_bk11_night/`.
- [x] BK-12 BTS, expressways (only if a walk or preset reaches them) — skipped per plan scope (no BTS lies within 3.2 km of the capital eye and no Siam/Silom/Sukhumvit preset was requested).
- [x] BK-13 Review loop, scorecard, perf, docs — `bangkok-r2` & `bangkok-r2-river` reviewed (`visual-plan/reviews/bangkok-r2-2026-11-23/README.md`), `docs/fidelity-scorecard.md` & `docs/architecture-styles.md` updated, `build_bench` High `7.87 s` / Ultra `9.31 s` (within budget).
- [x] Code review — `tools/check_class_size.sh` OK (`996/1000`), all headless suites + batched windowed `world_cache_test` & `screenshot_test` `PASSED`, no Russian hosts (`host_policy_test`), no leftover `/tmp/bk_*` files, no AI attribution.

## BK-0.1 Scene Truth Findings & Decision 1 (2026-11-23)

- Probed at `13.75398, 100.50144` and streamed river origin `13.7455, 100.4905` (`visual-plan/reviews/bangkok-bk01-stream-2026-11-23/`).
- Between 1.2 km and 2.5 km the capital view draws far blocks + far canopy + registry landmarks (`Grand Palace`, `Wat Pho`, `Wat Arun`, river bridges); moving to the river (`13.7455, 100.4905`) streams full detailed shoreline, river width (~220 m), banks, piers, and buildings cleanly with `Wat Arun`, `Wat Pho`, and `Grand Palace` seated on dry banks.
- **Decision 1:** Option **(c)** — keep `13.75398, 100.50144` as the bundled capital snapshot and rely on streamed river worlds (`13.7455, 100.4905`) for `E10`–`E12` river captures and gameplay.

## What the audit found (2026-11-20)

### The scene is smaller than the first draft assumed

- **Detailed layer ends at 1,200 m** (`OsmFetcher.DETAILED_RADIUS_M`, `scripts/data/osm_fetcher.gd:109`). The
  bundled detailed snapshot holds 7,529 buildings, none farther than 1,292 m.
- **The Chao Phraya is outside it.** The nearest point of the river centreline is 1,406 m from the eye. The
  detailed layer has no river polygon at all; the rings carry the river only as `waterway=river` centrelines
  (11 ways in the 1,600 m ring, 22 in the 2,500 m ring).
- **Distances from the eye:** Grand Palace compound centre 1,139 m (it straddles the edge: east wall about
  890 m, west wall about 1,390 m), Wat Pho 1,274 m, Wat Arun 1,774 m, Rama VIII Bridge 1,767 m, Memorial Bridge
  1,683 m, Phra Pinklao Bridge 1,482 m, Wat Benchamabophit 1,969 m, Wat Traimit 2,239 m, Ananta Samakhom
  2,347 m, Hua Lamphong 2,488 m, MahaNakhon 4,470 m.
- **Consequence:** the "river panorama" (Wat Arun, Wat Pho, palace from mid-river) is not in the detailed world
  of the capital view. A capture eye on the river would stand among far-layer blocks with a centreline river.
  This is the first open decision below; BK-0.1 measures what is drawn there today.
- **Far layer** (to about 12 km): 4,345 landuse polygons and about 1,660 distinct tall or tagged buildings and
  parts, almost all beyond 3.4 km. Between 1.2 km and about 3 km the city is generic far blocks from landuse.

### What OSM gives inside the detailed ring

| Tag | Count | Meaning for the plan |
| --- | ---: | --- |
| `building` | 7,529 | 3,828 `yes`, 1,417 `house`, 1,255 `commercial`, 283 `retail`, 86 `terrace` |
| `building=temple` | 433 | Individual wat halls. 57 named, 51 with levels. This, not `place_of_worship`, is the key |
| `amenity=place_of_worship` | 20 | 11 Buddhist, 2 Muslim, 2 Hindu, 2 Taoist, 1 Christian; too few to drive anything |
| `man_made=stupa` | 64 | Chedis and prangs are mapped one by one (the eight palace prangs, Wat Pho chedis) |
| `man_made=tower` | 57 | Includes the palace wall forts and bell towers |
| `building:levels` | 2,152 | 5,381 buildings (71 %) have no levels; tallest tagged is 27 |
| `height` | 8 | No measured heights. The height rule decides how the old town looks |
| `building:part` | 28 | No part models; landmarks must be bespoke |
| `roof:shape` / `building:colour` | 8 / 30 | Negligible |
| `natural=tree` | 2,020 | With `denotation` (589 urban, 374 avenue, 273 street, 72 garden); no species |
| `waterway=canal` | 33 | Plus 29 `natural=water` polygons; all the old-town khlongs are present |
| `barrier=wall` / `city_wall` | 134 / 4 | Palace wall (`w23482754`, `barrier=city_wall`) and wat compound walls |
| `historic` | 55 | 15 manor, 12 monument, 10 castle (palace halls), 4 city gate, 1 fort |
| `railway` | 7 | 2 subway (underground MRT), 4 construction. No BTS within 1.2 km (nearest about 3.2 km) |
| `man_made=pier` | 1 | Piers are on the river, outside the ring |

- **Rings:** the 2,500 m ring hit both caps (800 highways, 150 waterways), so it is thinned the way Stockholm's
  was before its re-cut. The 1,600 m ring is complete (392 highways, 67 waterways).
- **POI layer:** 767 nodes within 800 m (84 restaurants, 59 cafes, 60 artworks).

### What the code does with it today

- **Temples:** `building=temple` becomes kind `religious` and takes the `southeast_asia` religious profile
  (`architecture_regions.gd:253`): cream render, one hipped terracotta roof, `tw: pagoda`. The 433 halls
  therefore read as plain hipped boxes. `ArchitectureStyle._tower` gives any Buddhist-tagged building a pagoda.
  `LandmarkArchetypes.temple` is reached only by ranked OSM landmark candidates, not by ordinary halls.
- **Chedis:** `man_made=stupa` is not in the detailed query (`osm_query.gd:191` asks for
  `tower|lighthouse|windmill|pier`), so the 64 mapped chedis draw nothing unless they are also buildings.
- **Fabric:** `city_styles.gd` has the city row (centre 13.7563, 100.5018, 12 km), two cores (Siam,
  Rattanakosin) and three districts at lines 412-414 (Silom/Sathorn and Sukhumvit as `bangkok_tower`, Chinatown
  as `bangkok_shophouse`). The view centre has no district. Era rows (`architecture_cities_world.gd:102-106`)
  send apartments from 1990 on to the 20-45 storey `bangkok` condo row. There is no `bangkok_rule` in
  `building_era.gd`; only Tokyo and Seoul have rules.
- **Landmarks:** `grand_palace_bangkok` (primary, `icon: true`, 45 m, `clear_m` 220) and `wat_pho` (42 m) in
  `landmark_registry_mainland_se_asia.gd`; `wat_arun` (70 m, `radius_m` 2500) in `landmark_registry_asia_south.gd`
  with its builder at `landmarks/asia_south/landmark_sea_temples.gd:208` (already cream-white `#EDE7D6`, so the
  first draft's "rebuild white, not grey" is a material and detail upgrade, not a colour fix); `hua_lamphong`
  (26.2 m, yaw 138.7) in the capital stations registry, builder `landmark_cs_asia.gd:188`.
- **Bridges:** ten spec rows. Memorial, Taksin, Krung Thon and Rama VIII are `conf: 2`; Rama VI is `conf: 1`
  (never built); the other five need their `conf` read in BK-6.
- **Vehicles:** `TH` is absent from `CarFleet.COUNTRY_FLEET`, `bangkok` from `REGION_FLEET`, `TAXIS` and
  `BUS_PAINT`, so Bangkok gets the default fleet, a default taxi and a hashed bus colour. `CarSpecs` has
  `pickup`, `sedan`, `van`, `minivan`; no motorbike and no three-wheeler.
- **Trees:** Bangkok is biome `tropical`, whose mix is 45 % palm and 55 % generic tropical
  (`tree_species.gd`, `mix`). Old-town streets are almost all broadleaf, so palms are heavily over-drawn.
- **Detail budget:** `CityDetail.CITIES` is Helsinki, Espoo, Turku, Stockholm. Bangkok has default caps.
- **Tests:** `architecture_test.gd:30,64` pins the point 13.7563, 100.5018 to region `bangkok`. That point is
  beside the Democracy Monument, so a Rattanakosin district changes what this test must expect.
  `heritage_zone_test.gd:89-92` pins Bangkok as outside every heritage zone, so the old-town height cap goes in
  a district rule, not in `HeritageZones`.
- **Side bug:** `tower_looks.gd:10` lists `se_asia` and `kuala`; real region names are `southeast_asia` and
  `kuala_lumpur`. `bangkok` is listed by name, so Bangkok is unaffected. Fix it with a one-line test, outside
  this pass's critical path.

### Corrections to the first draft

| First draft | Finding | Change |
| --- | --- | --- |
| "2.4 km world", river eyes as routine captures | Detailed world is 1.2 km; river at 1.4 km | BK-0.1 plus decision 1; river work is gated on it |
| Wat archetype keyed on `place_of_worship` + `religion=buddhist` | 20 such ways against 433 `building=temple` | BK-3.4 keys on `building=temple` |
| Chedis come with the archetype | 64 chedis mapped as `man_made=stupa`, not fetched | BK-3.5 adds the tag to the query and a chedi prop |
| Canal bridges as conf-2 bridge spec rows | Capital bridges are picked nearest-first; canal bridges at 520-850 m would take every bridge slot from Rama VIII and Memorial | BK-6.3 styles them through the generic OSM bridge path |
| Raise the Ultra registry limit for Bangkok | Icons and bridges share `MAX_BY_PRESET` (26 on Ultra); 26 icons leaves no bridge | Keep 22 icons, 4 bridges (BK-0.3) |
| Bespoke MahaNakhon from stacked boxes | OSM has it as 14+ `building:part` ways (258-314 m) with the pixel massing | BK-11 uses the mapped parts, adds facade only |
| BTS viaducts as a normal phase | No BTS within 3.2 km of the eye | BK-12, optional |
| Bangkok City Hall not mentioned | It is the nearest building (`r2380281`, 45 m, 114 x 137 m) and fills the north side of the plaza | BK-3.6 |
| Line numbers for `city_styles.gd` districts 381-383 | Now 412-414 (file has uncommitted work) | Plan cites symbols; re-grep before editing |
| `scripts/render/water_surface.gd`, `vehicle_mover.gd` under generation | `scripts/generation/water_surface.gd`, `scripts/render/vehicle_mover.gd`, `scripts/render/world_cache.gd` | Paths corrected below |
| Wat Arun "grey today" | Already cream-white | BK-4.3 reworded |

## Goal and quality bar

From the City Hall plaza and from the other fixed eyes, a person who knows Bangkok recognises each landmark by
silhouette, proportion, colour, material and night look, and the streets and canals between them read as the old
royal city: low, cream and yellow, temple roofs and spires above the roofline, not condo towers.

A landmark is done when all of these hold (same bar as Stockholm: `landmark_fh_parliament.gd`,
`landmark_ft_samppalinna.gd`, `landmark_ft_paavo_nurmi.gd`):

- **Refs:** 3+ Wikimedia Commons CC/PD photos (front, quarter, aerial; night where it is floodlit) in
  `visual-plan/refs/landmarks/<type>/` with a README row per file (URL, author, licence).
- **Measured:** OSM outline centroid, long-axis bearing, footprint and height in `docs/bangkok-landmark-sources.md`;
  registry `lat/lon/yaw_deg/height_m/clear_*` match it.
- **Spec header:** the builder file opens with a written spec (bays, tiers, roof form, colours, signature
  features) taken from the photos, citing the OSM ids.
- **Model:** named sub-builders; repeated parts built once and merged; 2-16 surface keys; at most 150,000
  triangles (`tests/landmark_catalog_test.gd:12,90`); PBR-textured parts; top within max(2 m, 3 %) of `height_m`.
- **Site:** right ground (`base`, `base_at_m`, `SEAT_META`), mapped footprints suppressed cleanly
  (`clear_rect_m` / `model_rects_m`), named neighbours kept, trees cleared only where they would stand in it.
- **Night:** `FLOOD_META` rig or `...Lamp` keys where the real one is lit.
- **Evidence:** a `capture_landmarks.gd` four-view sheet, a `landmark_compare_sheets.py` page beside the refs, and
  one in-city `--looks` frame from open ground, all reviewed.

## Ground rules

- Data before modelling: site, footprint and axis from the snapshot (`python3 tools/osmb.py decode ...`),
  dimensions from Wikipedia, the Fine Arts Department or the architect, look from the reference photos.
- One builder file per landmark or tight group, every class at or under 1000 lines (`tools/check_class_size.sh`).
- No Russian-operated hosts. Overpass through openstreetmap.fr or kumi mirrors.
- Bump `WorldCache.BUILD_VERSION` (`scripts/render/world_cache.gd:24`, now 305) with each visual change.
- Many files this pass touches have uncommitted work of yours (`city_styles.gd`, `building_era.gd`,
  `landmark_builder.gd`, `road_builder.gd`, `osm_parser.gd`, `atmosphere_rig.gd`, `transit_vehicles.gd`,
  `train_specs.gd`, vessel files and more). Edits there stay minimal; if a change is large, work in a worktree.
  Commit only when asked, staging own files by path, no attribution lines.
- No depiction of living persons. Royal portrait arches are gilded frames with an emblem.
- Levers shared with the Singapore plan (tropical tree shapes, humid haze, concrete rail viaducts, a
  religion-aware temple fallback) are built once, region-keyed. Check what has landed before starting each.
- Any UI text follows the design system; none is expected in this pass.

## Slot budget (BK-0.3)

`LandmarkSites.select` sorts registry extras by `skyline_priority`, then nearest first, and takes
6 / 12 / 18 / 22 per preset. Bridges then fill what is left under 10 / 16 / 22 / 26 total, at most 2 / 4 / 6 / 8,
so 2 / 4 / 4 / 4 in practice. Skyline towers have their own 12 / 30 / 60 / 110 channel. An entry is a candidate
only when the eye is within its `radius_m`.

| Preset | Registry extras drawn from the City Hall eye |
| --- | --- |
| Fast (6) | Golden Mount*, Wat Arun*, Giant Swing, Democracy Monument, Loha Prasat, Wat Suthat |
| Balanced (12) | + Mahakan Fort, Wat Ratchabophit, Wat Bowonniwet, City Pillar Shrine, Ministry of Defence, Wat Pho |
| High (18) | + Wat Ratchapradit, Thammasat dome, National Museum, Phra Sumen Fort, Santa Cruz Church, Wat Kalayanamit |
| Ultra (22) | + Wat Prayun, Wat Benchamabophit, Chinatown Gate with Wat Traimit (one grouped row), Ananta Samakhom |

- `*` carries `skyline_priority` (Golden Mount 3, Wat Arun 2). Everything else needs no priority: nearest-first
  already ranks the centre set first.
- Hua Lamphong (2,488 m) falls outside 22 from this eye; it still shows from eyes nearer to it.
- `ultra_registry_limit` on the Grand Palace stays unset, so four bridge slots remain.
- Bridge slots, nearest first among capital bridges: Phra Pinklao (1,482 m), Memorial (1,683 m), Phra Pok Klao,
  Rama VIII (1,767 m). Rama VIII is fourth, so it shows from Balanced up and not on Fast.
- `tests/bangkok_landmarks_test.gd` pins the four lists. If BK-0.1 moves the working eye to the river, the
  table is recomputed for that eye and pinned as a second case.

## Fixed look eyes (BK-0.2)

All eyes stand in open space: plaza, lawn, road median, canal bank or open water. Coordinates are starting
values from OSM features; BK-0.2 confirms each frame and moves any eye that stands in a tree crown, on a roof or
inside a mass. Water eyes are drone heights (see the look-eye-over-water note).

| Eye | Lat, lon | Height | Looks at |
| --- | --- | --- | --- |
| E1 City Hall plaza | 13.75398, 100.50144 | 1.7 m | S 184° to the Giant Swing (242 m) and Wat Suthat |
| E2 Plaza, turned | 13.75398, 100.50144 | 1.7 m | N to City Hall; E 73° to Loha Prasat (309 m) |
| E3 Ratchadamnoen median | 13.7569, 100.5003 | 1.7 m | E 102° along the avenue to the Democracy Monument |
| E4 Mahakan Fort park | 13.75538, 100.50552 | 1.7 m | SE to the Golden Mount (about 210 m); W to Loha Prasat |
| E5 Khlong Rop Krung bank, Phan Fa | 13.7562, 100.5058 | 1.7 m | Canal, Phan Fa Lilat Bridge, fort wall |
| E6 Khlong Khu Mueang Doem, Pi Kun Bridge | 13.74970, 100.49635 | 1.7 m | Canal, Wat Ratchabophit, Wat Ratchapradit |
| E7 Sanam Luang centre | 13.75523, 100.49309 | 1.7 m | S 190° to the palace wall and spires |
| E8 Bamrung Mueang Rd by the Swing | 13.7520, 100.5008 | 1.7 m | Shophouse fabric and the Swing from the west |
| E9 Drone over the plaza | 13.75398, 100.50144 | 120 m | W 250° to the palace spires and Wat Arun; roofscape |
| E10 Mid-river off Tha Tien | 13.7455, 100.4905 | 30 m | W to Wat Arun, E to Wat Pho and the palace (gated on decision 1) |
| E11 Mid-river off Phra Arthit | 13.7640, 100.4935 | 30 m | N to Rama VIII Bridge (gated on decision 1) |
| E12 Odeon Circle | 13.7377, 100.5131 | 1.7 m | Chinatown Gate, Wat Traimit (BK-11) |

## Phases

### BK-0 Baseline, truth and slots (do first)

- **BK-0.1 Scene truth.** One capture and one probe from the exact capital coordinates on High and Ultra:
  1. What stands between 1.2 km and 2.5 km: far blocks only, or streamed detail when the eye moves there
     (`PLAN-endless-walk-fly-ahead-streaming.md`)?
  2. How the river draws from its centreline (width, banks, colour) and whether Wat Arun and Wat Pho stand on
     dry ground at the right bank.
  3. Whether the Grand Palace's west half (beyond 1.2 km) has buildings under the model or bare ground.
  4. Which eye the app opens at for Bangkok and what it looks at.
  Output: a short findings block in this file and a decision on open decision 1.
- **BK-0.2 Baseline round.** `visual-plan/reviews/bangkok-r0-<date>/`: `capture_presets.gd` at E1-E9 (and E10-E11
  to record the current river state), `--preset=3`, `--times=golden,noon,night`, `--pin=13.75398,100.50144`; and
  `capture_landmarks.gd --types=grand_palace_bangkok,wat_pho,wat_arun,hua_lamphong --tag=bk_lm_base` for
  triangle counts. One README listing what each frame shows wrong.
- **BK-0.3 Slots.** Apply the budget table: add `skyline_priority` to `wat_arun`, give new rows a `radius_m`
  that covers the City Hall eye, and write the selection cases in the new test.
- **BK-0.4 Reference set.** `python3 -I tools/commons_refs.py --only=<types>` for every existing and planned
  type, then a contact-sheet pass. Expect about a third wrong on the first fetch (interiors, details, namesakes),
  as in Stockholm; drop and re-pin by hand. Add `visual-plan/refs/bangkok/` city refs: Bamrung Mueang shophouses,
  Ratchadamnoen Klang, a khlong, the river at Tha Tien, Yaowarat by night, an aerial of Rattanakosin.
- **BK-0.5 Sources doc.** `docs/bangkok-landmark-sources.md` in the `docs/turku-landmark-sources.md` table format
  (Type | OSM way | Centroid | yaw_deg | Footprint | Height | Source | Notes) and a Bangkok section in
  `docs/data-source-register.md`. Seed it with the rows in "Measured sites" below, then fill the gaps
  (Wat Suthat halls, Democracy Monument, Wat Bowonniwet, Thammasat dome, State Tower are not found by name yet).
- **BK-0.6 Snapshot repair.**
  1. Re-cut `capital_th_10375398_28050144_ring2500.osmb` with the highway cap raised (Stockholm 2026-11-19
     recipe in `assets/osm_snapshots/README.md`) and the waterway cap raised for this file; record counts and
     the manifest hash in `bundled_osm.gd` and the README.
  2. Compare the detailed layer's building count with a fresh Overpass count inside 1,200 m to see whether a
     building cap thinned it.
  3. Decide here whether `man_made=stupa` is re-fetched into the bundled detailed layer (needed by BK-3.5).

### BK-1 Batch wiring

- New `scripts/data/landmark_registry_thailand_bangkok.gd` (`LandmarkRegistryThailandBangkok.entries()`) and
  `scripts/generation/landmarks/thailand_bangkok/landmark_set_thailand_bangkok.gd`, both added to
  `scripts/data/landmark_registries.gd` (`entries()` and `sets()`). Builders are
  `landmarks/thailand_bangkok/landmark_bk_<name>.gd`. Run `--import` after each new `class_name`.
- The four existing rows keep their type ids and registries and are upgraded in place.
- Shared Thai shapes. Already in `landmark_mse_kit.gd` (419 lines) and `landmark_mse_util.gd` (211):
  `redent_ring`, `redent_lathe`, `thai_column`, `small_chedi`, `gable_trim`, `eave_border`, `thai_roof`,
  `thai_window`, `peristyle`, `plinth`, `seated_buddha`, `redent_chedi`, `redent_prang`, `sema_wall`,
  `thai_hall`, `swept_roof`, `tiered_roof`, `prasat_spire`, `bell_chedi`, `prang`, `crenel_run`, `crenel_ring`,
  `stairs`, `cloister`. New ones go in `landmark_mse_kit2.gd`:
  `mondop` (square pavilion with a stepped pyramidal spire), `yaksha` (5-6 m guardian giant with tiered crown
  and club), `chinese_guardian` (stone figure, Wat Pho and Wat Suthat), `chinese_pagoda` (stone ballast pagoda),
  `naga_rail`, `royal_umbrella` (tiered chatra), `kinnari_lamp`, `bai_sema` (boundary stone in its niche),
  `reclining_buddha`, `fort_tier` (polygonal crenellated drum).
- `tests/bangkok_landmarks_test.gd`, modelled on `tests/tokyo_seoul_landmarks_test.gd` and
  `tests/stockholm_hero_landmarks_test.gd`: every Bangkok type is registered and inside a Bangkok box; each
  builds 2-16 textured parts between 1,000 and 150,000 triangles; height within tolerance; nothing below ground;
  aliases resolve through `LocationData.landmark_for`; the primary stays the Grand Palace; the four preset lists
  of the slot table; named OSM ways are cleared and a named neighbour is kept.

Reuse, do not rewrite: `LandmarkMesh` (`lathe`, `grid`, `poly_prism`, `beam`, `spire`, `gable`, `lattice_panel`,
`merge`), `LandmarkMaterials` (`pbr`, `gold`, `glass`, `paint`, `lit`), `LandmarkDetail` (`colonnade`, `cornice`,
`balustrade`, `pierced_face`, `arch`), `LandmarkKits` (`statue_figure`, `dome_on_drum`), `StatueBuilder`,
`LandmarkBrKit`, `SkyKit`, `LandmarkLights` (`scripts/render/landmark_lights.gd`), `LandmarkTerrain`
(`SEAT_META`, `RELIEFS`), `landmark_stair_cut.gd`, `PlazaLife`.

### BK-2 Centre set: what the plaza eye sees

Each row is one builder and one registry entry. Do them as one batch with one capture run.

| ID | Type | OSM, site | Must show | Approach, budget |
| --- | --- | --- | --- | --- |
| BK-2.1 | `giant_swing` | `w178353988` `man_made=ceremonial_gate`, 242 m at 184°, on the Bamrung Mueang traffic island | Two round teak pillars about 21 m (verify 21.15 m) leaning slightly inward, each with two short raking side posts, all vermilion red on a white octagonal stone plinth with steps; carved, gilded-edged crossbar with upturned finials; no swing seat | `lathe` pillars with entasis, `beam` struts, crossbar from `gable` profiles; about 150 lines, under 15k triangles; `clear_m` about 8 so the island stays; `tree_clear_m` small |
| BK-2.2 | `wat_suthat` | Halls not named in OSM; compound about 320-470 m at 195-202°; find the viharn and ubosot ways in BK-0.5 | Tall viharn on a two-level terrace with a four-tier roof and porches on both ends; stone Chinese pagodas (28) and figures on the terrace; square cloister lined with gilt Buddhas; behind it the very long ubosot (verify 72 m); white walls, orange and green tile, gilded gables | `thai_hall` twice, `cloister`, `chinese_pagoda` instanced; one row with `model_rects_m` for the two halls and the cloister; 16 keys is tight, share tile and trim keys; about 400 lines, 80-110k triangles |
| BK-2.3 | `democracy_monument` | Roundabout ways named "Democracy Monument Circle" at 270-340 m, 1-15°; the monument itself not found by name; locate | Four folded wing pylons about 24 m around a round turret that carries the constitution on two gold offering bowls; relief panels at the wing bases; six sword-bearing gates on the turret; naga-head fountains; low stepped round base in the avenue | `grid` wing blades with a concave inner face, `lathe` turret, `gold` bowls; about 250 lines, under 40k triangles; `clear_m` about 20, roads kept |
| BK-2.4 | `loha_prasat` | `w103097698`, 48 x 48 m, 309 m at 73°; tagged 1 level, so it draws as a one-storey box today | Square stepped building of three diminishing tiers with 37 slender spires (verify count and 36 m height): gilded since 2017 over white walls, open arcades on every level, central spire tallest; in front the Maha Chetsadabodin pavilion plaza and the Rama III statue | One spire mesh instanced on three rings, arcades with `pierced_face`; pavilion and plaza as a seated child; about 300 lines, 70-100k triangles; the wat's own viharn and ubosot stay as temple halls (BK-3.4) |
| BK-2.5 | `golden_mount` | `w243936903` (58 x 49 m top structure) and `w88359228`, 566 m at 91° | Artificial hill (verify about 60 m to the terrace, about 77 m to the chedi tip) with white retaining walls and a stair spiralling up, tree-covered slopes, a square white terrace building with red-tiled eaves, the gold bell chedi and four small corner chedis | The hill is part of the model (a flat DEM will not have it): stepped `lathe` mound with a grass and tree-card skin, swept `grid` for the spiral wall, `bell_chedi` on top; `tree_clear_m` keeps mapped trees off the model; about 350 lines, under 90k triangles; `skyline_priority` 3 |
| BK-2.6 | `mahakan_fort` | `w103022352` `historic=fort`, 38 x 40 m, 476 m at 68°; park `w560595626` | White octagonal fort of three stepped tiers with pointed-leaf crenellations, small roofed tower on top, cannon in the embrasures; the surviving run of crenellated city wall (verify about 180 m) along the canal | `fort_tier` drums, `crenel_run` for the wall along the OSM wall way with `clear_path_m`; about 200 lines, under 40k triangles |

Validation: `bangkok_landmarks_test`, `landmark_catalog_test`, `landmark_placement_test`, `landmark_lights_test`,
class-size check; sheets for the six types; E1-E5 frames by day and night.

### BK-3 Old-town fabric: stop the giveaways

This phase changes more of the frame than any landmark. It can run in parallel with BK-2.

- **BK-3.1 Districts.** Add circles to `CityStyles.DISTRICTS` (re-grep the line; the file has open changes).
  Old town first, each with a style and a height ceiling:

  | District | Centre (approx.) | Radius | Style row |
  | --- | --- | --- | --- |
  | Rattanakosin inner (palace, Sanam Luang, ministries) | 13.7520, 100.4940 | 0.7 km | `bangkok_civic` |
  | Sao Chingcha, Phraeng Phuthon, Bamrung Mueang | 13.7525, 100.5000 | 0.5 km | `bangkok_oldtown` |
  | Ratchadamnoen Klang (a strip: three small circles) | 13.7566, 100.5015 | 0.25 km | `bangkok_ratchadamnoen` |
  | Banglamphu, Khao San | 13.7600, 100.4975 | 0.5 km | `bangkok_oldtown` with signage |
  | Wang Burapha, Pahurat, Saphan Lek | 13.7450, 100.5010 | 0.5 km | `bangkok_shophouse` |
  | Pom Prap, Nang Loeng | 13.7570, 100.5100 | 0.6 km | `bangkok_shophouse` |
  | Yaowarat, Sampheng (replaces the present Chinatown row) | 13.7400, 100.5080 | 1.0 km | `bangkok_shophouse` with gold-shop fronts |

  Outer districts (Dusit, Thonburi canal side, Kudi Chin, Talat Noi, Bang Rak, Hua Lamphong, Siam, Pratunam,
  Silom/Sathorn, Sukhumvit) follow in BK-11 and are data-only additions. Carry districts into the far field
  (`far_city_builder.gd`) so the 1.2-3 km belt is low and warm, not condo-grey.
- **BK-3.2 `bangkok_rule`** in `ArchitectureCitiesWorld` (pattern `ArchitectureCitiesEastAsia.seoul_rule`, hooked
  in `BuildingEra._rules`): a building with no levels inside an old-town district is 2-4 storeys by footprint
  (narrow terraced plot under 6 m wide is a shophouse; `house` is a 2-storey house; large footprints are civic
  or temple); apartments reach the condo row only outside the old-town districts or with 8+ mapped levels.
- **BK-3.3 Height truth.** Inside Rattanakosin's inner and outer zones cap guessed heights at 16 m and 20 m
  (the conservation ceilings; verify the figures) while mapped levels and heights win. 71 % of buildings have no
  levels, so this cap is what lets spires stand above the roofline. Test: no generated building within 700 m of
  the eye exceeds the cap unless OSM says so (nine mapped buildings have 8+ levels, for example the Queen's
  Gallery at 8 and Krung Thai Bank at 27, 1,144 m away).
- **BK-3.4 Temple halls.** For `building=temple` in Thailand (433 in view) replace the hipped box with a Thai hall
  look, done in the ordinary building path so it costs no landmark slot: white or cream rendered walls, steep
  two- or three-tier gabled roof along the long axis in orange tile with green borders, deep eaves, gilded
  gable ends with a simple chofa finial, low base. Implementation choice in order of preference: (a) a
  `religious` profile for a new `bangkok_wat` style row plus a roof-form option in the roof builder; (b) for
  halls over about 300 m², a call into `LandmarkMseKit.thai_hall` as a mapped-landmark replacement. Drop the
  automatic `pagoda` tower for Thai Buddhist halls. Mosques, churches, Chinese shrines (`religion=taoist`) and
  the Hindu Devasathan (`w629260929`, 208 m) keep their own religion's look. Check triangle and draw-call cost
  with 433 halls; share one material set.
- **BK-3.5 Chedis.** Add `stupa` to the `man_made` selector in `OsmQuery.build_query` (and bump the query version
  check `is_current`), parse it in `OsmParser` as a small prop, and draw a white or gold bell chedi or prang
  sized from the mapped outline (64 in view). The bundled detailed snapshot needs a re-cut or a small side file
  for this tag (BK-0.6). Chedis inside a hand-built landmark's clear area are skipped.
- **BK-3.6 Bangkok City Hall** (`r2380281`, 114 x 137 m, 45 m from the eye): the first building anyone sees.
  A cream late-modern block of about 4-5 storeys round courts with a central entrance front, flagpoles and the
  BMA emblem (verify from refs). Start as fabric with mapped levels and the `bangkok_civic` row; promote to a
  small bespoke model only if E2 shows a miss. Keep the plaza (Lan Khon Mueang) open, paved and treeless in the
  middle, with its lamp standards.
- **BK-3.7 Ratchadamnoen Klang blocks.** The avenue's matching 1939-48 blocks (`w1434802191` Rattanakosin
  Exhibition Hall and `w1434802192` Ratchadamnoen Art Center, both 4 levels, are two of them): uniform cream
  streamline fronts, flat roofs behind parapets, vertical fins, rounded corners at the cross streets, ground
  arcade. `bangkok_ratchadamnoen` row with `fix: true` and a fixed 4 storeys. Median with kinnari lamp posts
  and clipped trees (BK-9).
- **BK-3.8 Style rows** in `architecture_cities_world.gd` (parents at line 65, eras 102-106, rows from 261):
  - `bangkok_oldtown`: 2-3 storey Rattanakosin shophouse rows; pastel yellow, cream, pale green; tall louvred
    timber shutters, arched fanlights, stucco pilasters; clay-tile hipped or gabled roof with a deep eave; shop
    below with a fabric awning.
  - `bangkok_civic`: yellow or cream neo-classical ministries, 2-3 storeys, red or green tiled hipped roofs,
    white trim.
  - `bangkok_wat`: the temple hall profile of BK-3.4.
  - Refine `bangkok_shophouse` (4-5 storey concrete rows: stained render, caged balconies, roof water tanks,
    projecting vertical signboards) and keep `bangkok` and `bangkok_tower` for the new city.
  - Later, with BK-11: `bangkok_timber` (canal-side timber houses, corrugated roofs), `bangkok_mall`,
    `bangkok_hotel_river`.
- **BK-3.9 Roofs and clutter.** `RoofClutter` already lists `bangkok` in `ASIA`; add steel water tanks, dishes
  and tin lean-tos to flat shophouse roofs only, none on tiled old-town roofs or temple halls.
- **BK-3.10 Detail budget.** Measure adding `"bangkok"` to `CityDetail.CITIES` (`scripts/render/city_detail.gd:17`)
  with `tools/build_bench.gd` (add a `bangkok` place): accept if cold Ultra time-to-view stays at or under 150 s
  and peak memory under the Stockholm figure (3.83 GB).

Validation: `architecture_test` (new district and rule cases; update the pinned point at lines 30 and 64),
`asia_fronts_test`, `roof_clutter_test`, `facade_relief_test`, `party_walls_test`, `heritage_zone_test` (must
still pass unchanged), a new `bangkok_fabric_test` (height cap, temple hall look, no pagoda on a Thai hall,
chedi props present); E1, E2, E8 and E9 frames.

### BK-4 Existing landmarks to the bar

Ref comparison first, then fix only what differs.

- **BK-4.1 Grand Palace and Wat Phra Kaew** (`landmark_mse_bangkok.gd` 187 lines, `landmark_mse_chakri.gd` 111;
  compound `w23482754`, 503 x 630 m box):
  - Outer wall: white, crenellated, about 1.9 km round, with its gates and the named forts mapped as
    `man_made=tower` (Mani Prakan, Sanchorn Chaiwing, Singkhornkhan, Anantakhiri, Khan Kuenphet, Phadet
    Datsakon). Built along the OSM way as a seated child with `clear_path_m`; this is what E7 sees.
  - Wat Phra Kaew: gold bell chedi (Phra Si Rattana, `w23482988`), mondop with green-gold mosaic, the
    cruciform Pantheon with its prang crown, the ubosot with blue-gold glass mosaic and garuda frieze, the eight
    prangs along the east side (mapped `w23482991`-`w23482998`), the two gilded Phra Suwannachedi
    (`w229771456`, `w229771457`) carried by demon and monkey figures, twelve yaksha at the gates, the belfry.
  - Middle Court: Chakri Maha Prasat (cream Italianate body, three green-orange spired roofs), Dusit Maha
    Prasat (white cruciform, gilded spire), the Amarin group (`w205631558`), Borom Phiman (`w82543520`), lawns
    with clipped trees.
  - Part budget: the compound will exceed 16 keys if every colour gets one. Split into two registry-seated
    models (wat and Middle Court) sharing one entry through `model_rects_m`, or atlas the mosaics into one
    tiled PBR key. Decide after counting keys in the present builder.
  - The west half lies beyond 1,200 m: confirm with BK-0.1 that the model and its clear area still behave.
- **BK-4.2 Wat Pho** (`landmark_mse_wat_pho.gd` 104 lines; 1,274 m at 230°, just outside the detailed ring):
  the reclining Buddha (verify 46 m long, 15 m high) seen through the viharn's open doors and windows, head to
  the south, gold body, dark soles with pearl inlay as a tiled key; the four great chedis in green, white,
  yellow and blue tile; rows of small chedis (verify 91); Chinese stone giants at the gates; the ubosot with its
  double marble balustrade and cloisters. `reclining_buddha` from kit2, openings with `pierced_face`.
- **BK-4.3 Wat Arun** (`landmark_sea_temples.gd:208`, file 342 lines): keep the cream-white body; add finer
  redent steps, the porcelain and shell mosaic as a speckled PBR key, the demon and monkey caryatid bands, the
  four Indra-on-Erawan niches, the steep stairs, four corner prangs and four mondops to ref proportions, the
  riverside ubosot with its two yaksha, the gate pavilions and the pier. Pin the height with a cited source
  (registry 70 m; published figures run from about 67 m to 82 m) and `base` on the river terrace. Move the
  builder to its own file if the shared one passes about 700 lines.
- **BK-4.4 Hua Lamphong** (`landmark_cs_asia.gd:188`, about 25 lines today; registry yaw 138.7,
  `clear_rect_m` set): half-barrel vault front with the stained-glass lunette and clock, twin low wings with
  arcades, cream and pale yellow, the steel train shed behind, the fountain forecourt with the elephant
  monument. Own file `landmark_bk_hua_lamphong.gd`; the capital-stations dispatch keeps the type id.

Validation: the catalog and Bangkok tests, `capture_landmarks.gd` sheets for the four types against the BK-0.2
baseline sheets, E7 and E9 frames; E10 if decision 1 allows.

### BK-5 Second ring (600-1,300 m)

- **BK-5.1 Sanam Luang set.** Sanam Luang (`w23630232`, 302 x 589 m, 913 m) stays an open oval lawn with its ring
  of tamarind trees (`tree_rect` keeps the middle empty). Rows: City Pillar Shrine (`w127290889`, 817 m at 259°:
  white cruciform shrine with a prang spire), Ministry of Defence (`w1481381668`, 830 m: long yellow
  neo-Palladian front with a portico and the cannon forecourt), Thammasat dome building (pointed "pencil-tip"
  roof; auditorium `w83608615` is the neighbour), National Museum (Front Palace halls and the Buddhaisawan
  chapel). Saranrom Palace (`r16017576`) and the National Theatre stay fabric unless a capture shows a miss.
- **BK-5.2 Royal wats.** Wat Ratchabophit (`w138947464`, 135 x 131 m, 707 m at 221°: circular cloister round a
  gold chedi, walls in five-colour Benjarong tile), Wat Ratchapradit (`w342337807`, 796 m), Wat Bowonniwet
  (about 729 m at 349°: gold chedi between two viharns), Wat Mahathat, Wat Thepthidaram, Wat Chana Songkhram
  (`w178329976`). First two and Bowonniwet get rows; the rest rely on BK-3.4 and BK-3.5.
- **BK-5.3 Forts and gates.** Phra Sumen Fort (1,276 m at 331°: white hexagonal fort with a pointed-roof tower
  in the river park), the four mapped `historic=city_gate` ways.
- **BK-5.4 Thonburi bank** (gated on decision 1): Santa Cruz Church (cream church, reddish octagonal dome),
  Wat Kalayanamit (very tall viharn), Wat Prayun (white bell chedi, verify 60 m), Wat Rakhang. One row each for
  the first three.
- **BK-5.5 Small things that sell the place.** San Chao Pho Suea (Tiger God Shrine, 358 m at 271°: red Chinese
  shrine front), the Devasathan beside the Swing, the King Prajadhipok Museum (`w229966092`, 592 m), Khao San
  Road as a signage-heavy guesthouse strip (`w23610119`).

### BK-6 Bridges

- **BK-6.1 Audit** the ten rows (`bridge_specs_southeast_asia_au_nz.gd:94-210`, `bridge_specs_pilot.gd:176,190`):
  read `conf`, type, spans and colour for each against sources. Known today: Memorial, Taksin, Krung Thon and
  Rama VIII are `conf: 2`; Rama VI is `conf: 1`.
- **BK-6.2 The four that can show** from the old town:
  - **Rama VIII**: one inverted-Y pylon (verify 160 m) on the Thonburi bank, asymmetric fans of gold cables (two
    planes over the river, one back-stay plane), gold lotus finial, lit gold at night. If `BridgeParam` cannot
    express it, write `landmark_bk_rama_viii.gd` with `clear_path_m` on the pattern of
    `landmark_fh_crown_bridge.gd` and drop the spec row. Mind that model's lessons: 16 parts, about 65k
    triangles, reuse surface keys, budget triangles per stay.
  - **Memorial (Phra Phuttha Yodfa)**: dark green steel through-truss with the former bascule centre span,
    the King Rama I monument at the east foot.
  - **Phra Pok Klao**: three plain concrete decks beside it, the middle one planted as the Chao Phraya Sky Park.
  - **Phra Pinklao**: plain concrete girder bridge.
- **BK-6.3 Canal bridges, without spec rows.** Phan Fa Lilat (521 m), Makkhawan Rangsan, Chaloem Wan Chat
  (682 m), Pi Kun (728 m), Saphan Hok (844 m, a white lifting footbridge), Chang Rongsi, Ubon Rat, Phanuphan,
  Saphan Han (1,108 m) and Wisukam Narumeman are short white bridges with marble or cast balustrades and bronze
  lamp standards. Give the generic OSM bridge deck a `bangkok` look for bridges over `waterway=canal` in the
  old-town districts (white balustrade, lamp posts at the four corners). They must not become capital-bridge
  rows, or they take the slots of the river bridges.
- **BK-6.4 Farther bridges** (Taksin with the BTS in the gap, Krung Thon, Rama IX with yellow stays, Bhumibol 1
  and 2, Rama III, Rama VII, Rama VI): verify data and colour only; they show from other eyes.
- Tests: `bridge_specs_test`, `bridge_param_test`, `bridge_select_test`, `bridge_arches_test`; a case that the
  City Hall eye's four bridge slots are the four river bridges.

### BK-7 River, canals, boats

- **BK-7.1 Khlongs** (all inside the detailed ring): Khlong Khu Mueang Doem ("Khlong Lot", 13 ways), Khlong Rop
  Krung (10 ways, nearest 460 m), Khlong Lot Wat Ratchanatda (nearest 248 m), Khlong Lot Wat Ratchabophit,
  Khlong Maha Nak, Khlong Bawon Rangsi. Each should draw as green-brown still water of true width (8-20 m)
  between vertical concrete or masonry walls, with a white balustrade and a footpath on the bank
  (`quay_builder.gd`, `quay_details.gd`, `shore_railings.gd`; see the low-quay notes for the array and unit
  pitfalls). Check that a canal mapped only as a line gets a width, and that polygons and lines of the same
  canal do not double.
- **BK-7.2 Water colour** (`scripts/generation/water_surface.gd`, `water_shader.gd`): a Chao Phraya palette
  (opaque silty brown-green, low clarity, choppy from boat wakes) and a darker green-brown for khlongs. No
  turquoise. Pin both in `far_water_palette_test`.
- **BK-7.3 River truth** (gated on decision 1): the river's real width here is about 200-250 m. Whatever BK-0.1
  finds, the banks need the palace-side quay wall, the piers (Tha Chang, Tha Tien, Tha Maharaj, Phra Arthit) as
  pontoons with pitched-roof shelters, and Wat Arun's terrace at the water.
- **BK-7.4 Boats** (`vessel_prototypes.gd`, `vessel_forms.gd`, `passenger_vessel_model.gd`,
  `market_boat_model.gd`, `harbour_ferries.gd`): longtail boat (long narrow hull, raised bow with garlands, car
  engine on a pivot with a long propeller shaft, striped awning), Chao Phraya Express Boat (long white hull,
  coloured flag at the stern), cross-river ferry, a tug with a train of rice barges, hotel shuttle boats. Small
  craft on Khlong Maha Nak (Saen Saep boats start at Phan Fa Lilat pier, 520 m from the eye, so this one is in
  view). Water hyacinth clumps near banks as an Ultra decal.

Validation: `shoreline_test`, `quay_moorings_test`, `vessel_models_test`, `far_water_palette_test`; E5 and E6
frames; E10 and E11 if allowed.

### BK-8 Trees and atmosphere

- **BK-8.1 Tree mix** (`tree_species.gd`: `mix`, `SPECIES`, `GENUS`; `tree_generators.gd`): a `bangkok` or
  `tropical_city` mix keyed by setting and by the mapped `denotation`:
  - `avenue` and `street` (647 trees): rain tree (wide flat umbrella), mahogany, Burmese rosewood (pradu),
    tamarind; palms at most 5 %.
  - Sanam Luang ring: tamarind only.
  - `garden` and temple courts: frangipani, bodhi and banyan, potted clipped topiary (tako dat) as a prop.
  - Parks (Saranrom `w23486019`, Mahakan, Rommaninat): rain tree, golden shower (yellow in the dry season),
    royal and areca palms about 20 %.
  - Thonburi yards (BK-11): mango, banana, coconut.
  Reuse Singapore's shapes if they have landed.
- **BK-8.2 Atmosphere** (`scripts/render/atmosphere_rig.gd`, `sky_palette.gd`, `haze_rig.gd`,
  `scripts/generation/climate_model.gd`): humid-tropics haze with a warmer smog tint in the dry months,
  towering cumulus in the wet months, a soft orange low sun. `atmosphere_rig.gd` has open changes of yours; add
  data rows, not structure.

Validation: `canopy_vegetation_test`, `tree_lod_test`, `climate_test`, `haze_test`, `sky_test`.

### BK-9 Streets and vehicles

- **BK-9.1 Fleet** (`scripts/generation/vehicles/car_fleet.gd`): add `"TH"` to `COUNTRY_FLEET` or a `bangkok`
  row to `REGION_FLEET` with a Thai mix (pickups, white and silver sedans, vans); `TAXIS["bangkok"]` with the
  real liveries (hot pink, green over yellow, blue, orange, yellow) and a higher share (about 0.12).
  Left-hand traffic is already handled by country.
- **BK-9.2 Tuk-tuk**: a three-wheeler does not fit `CarSpecs`' four-wheel parameters. A small own model class
  (`vehicles/tuk_tuk_model.gd`): single front wheel, open sides, blue or green body, yellow or striped canopy,
  chrome rails. Parked near temples and markets and in moving traffic at a small share.
- **BK-9.3 Motorbikes**: parked rows on pavements and a motorbike-taxi stand prop (riders with orange vests) at
  junctions; moving motorbikes only if `VehicleMover` (`scripts/render/vehicle_mover.gd`, open changes) takes a
  new kind without structural edits.
- **BK-9.4 Buses** (`transit_vehicles.gd`, `BUS_PAINT`; open changes): a `bangkok` entry. One colour is not
  enough for Bangkok (cream-red, blue-white, orange, yellow, new blue electric), so extend the lookup to accept
  a list picked per stop hash, keeping single colours working. 13 mapped bus stops are in view.
- **BK-9.5 Overhead cables** (`utility_poles.gd`, `overhead_wires.gd`; JP and KR poles exist): add TH with
  square concrete poles, thick multi-strand bundles, transformers and coiled slack. Dense in the shophouse
  districts; none on Ratchadamnoen Klang and round the palace, where cables are buried.
- **BK-9.6 Street furniture** (`street_props.gd`, `street_furniture.gd`, `plaza_life.gd`): vendor carts with
  umbrellas and plastic stools on wide pavements and at markets; blue street-name signs; red-and-white kerbs;
  gilded kinnari lamp posts and flag bunting on Ratchadamnoen; spirit houses in forecourts of larger buildings;
  potted bougainvillea on medians. `street_props.gd` has open changes: add through data tables.
- **BK-9.7 Road markings**: compare `road_markings.gd` with refs (yellow centre lines, zebra crossings; 283
  crossings carry `crossing:markings`); add only what is missing.

Validation: `car_fleet_test`, `bus_stop_test`, `street_furniture_test`, `plaza_life_test`,
`street_lights_test`, `road_markings_test`; a `capture_cars.gd` sheet for the tuk-tuk and taxis; E3 and E8.

### BK-10 Night

- Per landmark (`scripts/render/landmark_lights.gd`): Golden Mount chedi brilliant gold above a dark hill; Loha
  Prasat gold spires; Democracy Monument warm white with the gold bowls; Giant Swing red under white flood; the
  palace wall wash and gold spires; Wat Arun warm gold on white; Wat Pho chedis; Rama VIII cables gold.
- Fabric: fluorescent-lit open shopfronts, bare-bulb vendor carts, the avenue's lamp rows; Yaowarat neon
  (dense vertical red, gold and green signboards) and Khao San signage through the signage and `screens` relief
  keys of their districts.
- Canals and river: pier lamps, lit dinner-cruise boats as `...Lamp` hulls.

Validation: `landmark_lights_test`, `street_screens_test`, night and late frames at every eye.

### BK-11 Outer landmarks and skyline

- **Dusit:** Wat Benchamabophit (1,969 m: Carrara marble, four-tier orange roofs, cloister, canal bridges),
  Ananta Samakhom Throne Hall (2,347 m: white marble, large copper dome with six small ones, Royal Plaza with
  the equestrian statue), Makkhawan Rangsan Bridge.
- **Chinatown:** Wat Traimit (2,239 m: white and gold four-storey mondop) with the Chinatown Gate on Odeon
  Circle as one grouped row; Wat Mangkon Kamalawat.
- **Towers** through the skyline channel (`skyline: true` rows in a `BkTowerSpecs` data class, pattern
  `scripts/data/nyc_tower_specs*.gd`, facades with `SkyKit`). OSM already gives:

  | Tower | OSM | Height (OSM) | Distance, bearing | Work |
  | --- | --- | --- | --- | --- |
  | Magnolias Waterfront (ICONSIAM) | `w680736465` | 317.95 m | 3,105 m, 162° | Taper and facade |
  | Residences at Mandarin Oriental | `w680739268` | 272.2 m | 3,079 m | Facade |
  | The River | `w445340031`, part `w445340025` | 265.64 m | 3,762 m | Facade |
  | Baiyoke Tower II | parts `w443491485-7`, `r18728185` | 284 / 295 / 304 m | 4,214 m, 89° | Tan cladding, gold crown, mast |
  | MahaNakhon | 14+ parts `w4446511xx`-`w4446512xx` | 258-314.2 m | 4,470 m | Glass and the pixel ribbon as facade evidence only |
  | Sathorn Unique | `w321722223` | 49 levels | 4,343 m, 160° | Bare concrete ghost-tower look |
  | One City Centre | `w1222766567` | 275.76 m | 5,022 m | Glass |
  | Unnamed 314 m | `w402124521` | 314 m | 4,906 m | Identify first |

  State Tower (gold dome), King Power Rangnam, Jewelry Trade Center and Empire Tower are not found by name;
  locate them in BK-0.5. Fix the `tower_looks.gd:10` names here.
- **Outer districts** of BK-3.1 and the `bangkok_timber`, `bangkok_mall`, `bangkok_hotel_river` rows.
- Sappaya-Sapasathan (parliament) and Victory Monument as far rows only if an eye sees them.

### BK-12 BTS and expressways (optional)

No elevated rail lies within 3.2 km of the capital eye, and the 2,500 m ring holds only 11 motorway ways. Do
this only if a preset, walk or review eye reaches Siam, Silom or Sukhumvit: heavy concrete box-girder viaducts
on T piers over the road median (`rail_builder.gd`, `rail_decks.gd`, which today face decks in brick), station
boxes with side stairs, BTS and MRT liveries in `train_specs.gd`, tollway decks with noise walls. Share the
concrete viaduct work with Singapore.

### BK-13 Review loop and sign-off

- A capture round `bangkok-rN` after each phase at the fixed eyes (Ultra; golden, noon, night), a review README
  per round listing mismatches per landmark, fixes, recapture.
- `docs/fidelity-scorecard.md` Bangkok entry per round; `docs/architecture-styles.md` row (line 142);
  `docs/bangkok-landmark-sources.md`; `docs/data-source-register.md`.
- Perf: `tools/perf_baseline.gd` and `tools/build_bench.gd` for Bangkok before and after (cold, cached, fly) at
  presets 2 and 3; `lod_test`, `memory_budget_test`, `impostor_test`; no regression beyond noise. Stage timings
  from the editor binary overstate loops; rank any hot spot from a release serial build.
- Final contact sheet of every landmark beside its reference for the human "photographic" gate.
- On request only: a Bangkok `PresetViews` row, a capture preset with a `THUMB_LOOKS` entry, a re-baked
  `assets/capital_thumbs/bangkok_thailand.jpg`, airports through the capital-airports pipeline.

## Measured sites (seed for the sources doc)

| Feature | OSM | Centroid | Box (m) | Distance, bearing |
| --- | --- | --- | --- | --- |
| Bangkok City Hall | `r2380281` | 13.75368, 100.50172 | 114 x 137 | 45 m, 138° |
| Devasathan (Brahmin temple) | `w629260929` | n/a | n/a | 208 m |
| Giant Swing | `w178353988` | 13.75181, 100.50128 | 11 x 10 | 242 m, 184° |
| Khlong Lot Wat Ratchanatda | `w784180152` | 13.75536, 100.49964 | line | 248 m |
| Ratchadamnoen Art Center | `w1434802192` | 13.75609, 100.50277 | 100 x 41 | 276 m, 31° |
| Loha Prasat | `w103097698` | 13.75481, 100.50416 | 48 x 48 | 309 m, 73° |
| Rattanakosin Exhibition Hall | `w1434802191` | 13.75587, 100.50380 | 104 x 43 | 331 m, 51° |
| San Chao Pho Suea market | `w1004865014` | 13.75403, 100.49813 | 62 x 59 | 358 m, 271° |
| Mahakan Fort | `w103022352` | 13.75560, 100.50552 | 38 x 40 | 476 m, 68° |
| Queen's Gallery (8 levels) | `w205637198` | 13.75655, 100.50510 | 39 x 37 | 488 m, 54° |
| Phan Fa Lilat Bridge | `w169343049`, `w169343042` | 13.7562, 100.5057 | 27 x 16 | 521 m, 61° |
| Golden Mount | `w243936903`, `w88359228` | 13.75385, 100.50668 | 58 x 49 | 566 m, 91° |
| King Prajadhipok Museum | `w229966092` | 13.75608, 100.50647 | 34 x 46 | 592 m, 67° |
| Wat Ratchabophit | `w138947464` | 13.74921, 100.49713 | 135 x 131 | 707 m, 221° |
| Pi Kun Bridge | `w178354005` | 13.74970, 100.49635 | 17 m | 728 m, 229° |
| Wat Ratchapradit | `w342337807` | 13.74966, 100.49557 | 93 x 66 | 796 m, 233° |
| City Pillar Shrine | `w127290889` | 13.75256, 100.49403 | 16 x 17 | 817 m, 259° |
| Ministry of Defence | `w1481381668` | 13.75177, 100.49411 | 255 x 145 | 830 m, 253° |
| Saranrom Palace | `r16017576` | 13.75023, 100.49475 | 52 x 92 | 835 m, 240° |
| Saranrom Park | `w23486019` | 13.74829, 100.49540 | 178 x 207 | 910 m, 226° |
| Sanam Luang | `w23630232` | 13.75523, 100.49309 | 302 x 589 | 913 m, 279° |
| Thammasat Auditorium | `w83608615` | 13.75654, 100.49197 | 60 x 94 | 1,063 m, 286° |
| Grand Palace compound | `w23482754` | 13.75013, 100.49168 | 503 x 630 | 1,139 m, 248° |

Registry coordinates today: Grand Palace 13.75101, 100.49188 (about 100 m north of the compound centroid; it
may be aimed at Wat Phra Kaew, check); Wat Pho 13.74668, 100.49237; Wat Arun 13.7437, 100.4889; Hua Lamphong
13.7377, 100.5172.

## Order and size

1. **BK-0, BK-1** (foundation). Small, but BK-0.1 can reshape the rest.
2. **BK-2 and BK-3 together**: six builders of 150-400 lines plus the fabric rule set. After this the plaza view
   is right, which is the view the app opens on. Natural first stopping point.
3. **BK-4, BK-6.2, BK-7** in the form decision 1 allows: the palace, Wat Pho, Wat Arun and the river.
4. **BK-5, BK-8, BK-9, BK-10**: second ring, trees, streets, night.
5. **BK-11**, then **BK-12** if wanted, then **BK-13** sign-off.

About 30 landmark builds or rebuilds, 4 bridges, about 10 style rows and districts, 5 generic systems (temple
halls, chedi props, canal banks, Thai vehicles, Thai poles). Every phase ends with tests passing and a capture
round, so the pass can stop after any of them.

## Risks

- **River outside the detailed world** (decision 1). Highest impact on scope.
- **433 temple halls and 64 chedis** may cost build time and draw calls; measure in BK-3.4 before polishing.
- **Part and triangle ceilings** on the palace compound and Wat Suthat; plan the key list before modelling.
- **Shared files with open changes**; conflicts are likely in `city_styles.gd`, `building_era.gd`,
  `osm_parser.gd` and `landmark_builder.gd`. Use a worktree for BK-3.
- **Query change for `man_made=stupa`** touches the Overpass query for every place and the bundled-snapshot
  validity check; keep it additive and confirm other bundled snapshots still validate.
- **Pinned tests** (`architecture_test` Bangkok point, `heritage_zone_test`) must be updated deliberately, not
  loosened.
- **Golden Mount hill** is a model, not terrain; check that roads and mapped trees around it are not buried and
  that its foot meets the ground without a seam.

## Critical files

- **New:** `scripts/data/landmark_registry_thailand_bangkok.gd`,
  `scripts/generation/landmarks/thailand_bangkok/landmark_set_thailand_bangkok.gd` and `landmark_bk_*.gd`,
  `scripts/generation/landmarks/mainland_se_asia/landmark_mse_kit2.gd`,
  `scripts/generation/vehicles/tuk_tuk_model.gd`, `tests/bangkok_landmarks_test.gd`,
  `tests/bangkok_fabric_test.gd`, `docs/bangkok-landmark-sources.md`.
- **Changed, landmarks:** `scripts/data/landmark_registries.gd`, `landmark_registry_mainland_se_asia.gd`,
  `landmark_registry_asia_south.gd`, `landmark_registry_capital_stations.gd`, `landmark_mse_bangkok.gd`,
  `landmark_mse_chakri.gd`, `landmark_mse_wat_pho.gd`, `landmarks/asia_south/landmark_sea_temples.gd`,
  `landmarks/capital_stations/landmark_cs_asia.gd`, `scripts/data/bridges/bridge_specs_southeast_asia_au_nz.gd`,
  `bridge_specs_pilot.gd`.
- **Changed, city:** `city_styles.gd`, `architecture_cities_world.gd`, `building_era.gd`,
  `architecture_style.gd` (`_tower`), `far_city_builder.gd`, `roof_clutter.gd`, `tower_looks.gd`,
  `scripts/data/osm_query.gd`, `osm_parser.gd`, `osm_tags.gd`, `tree_species.gd`, `water_surface.gd`,
  `quay_builder.gd`, `vessel_prototypes.gd`, `vehicles/car_fleet.gd`, `vehicles/transit_vehicles.gd`,
  `utility_poles.gd`, `overhead_wires.gd`, `street_props.gd`, `scripts/render/city_detail.gd`,
  `scripts/render/landmark_lights.gd`, `scripts/render/world_cache.gd` (`BUILD_VERSION` only),
  `assets/osm_snapshots/` (ring re-cut) with `scripts/data/bundled_osm.gd`.

## Verification

- **Tests, headless and in the background** through `tools/godot_bg.sh`:
  `tools/godot_bg.sh --headless --path . --script tests/<name>_test.gd`, or `tools/run_tests.sh <filters>`.
  Per landmark batch: `landmark_test`, `landmark_catalog_test`, `landmark_fidelity_test`,
  `landmark_placement_test`, `landmark_lights_test`, `bangkok_landmarks_test`. Per city task: the tests named in
  its phase plus one focused new test per new behaviour. `tools/godot_bg.sh --headless --path . --import` after
  a new `class_name`; note that a parse error can still exit 0, so read the log. `tools/check_class_size.sh`
  after every new or grown class.
- **Skip the network tests** (`tiles_test`, `exit_tile_test`, `dem_test`, `preset_snapshot_test`,
  `fidelity_scorecard_test`).
- **Model sheets:** `tools/godot_bg.sh --path . --script tools/capture_landmarks.gd --position 4000,4000 --
  --types=<a,b> --tag=bangkok-rN [--night]`, then `python3 -I tools/landmark_compare_sheets.py --tag=bangkok-rN`;
  read `stats.tsv` for triangle counts.
- **In-city frames, one batched background run per round:**
  `tools/godot_bg.sh --path . --script tools/capture_presets.gd --position 4000,4000 -- --tag=bangkok-rN
  --preset=3 --pin=13.75398,100.50144 --times=golden,noon,night --looks="lat,lon,height_m,bearing,pitch[,zoom];..."`.
  `--pin` at the exact capital coordinates keeps the bundled snapshot in use. Never `--always-on-top`. Check
  every frame before using it: interior faces, cut walls or geometry floating against the sky mean the eye is
  inside a mass, so discard the frame and move the eye. Check free disk before each round and do not delete a
  capture folder that a review README names as the reference.
- **End:** windowed `world_cache_test` and `screenshot_test`, batched once, in the background.
- **Done means:** every BK-2 and BK-4 landmark is recognisable beside its reference by day and night, the plaza
  view shows a low cream old town with temple roofs and spires above it, all listed tests and the class-size
  check pass, and perf is within noise of the BK-0.2 baseline.

## Open decisions (recommendation in brackets)

1. **The river is outside the capital view's detailed world.** Options: (a) keep the City Hall eye as the only
   detailed scene and treat Wat Arun, Wat Pho and the bridges as far objects; (b) bundle a second detailed
   snapshot at a river origin (about 13.7462, 100.4905 off Tha Tien) and use it for river captures and, if you
   ask later, a preset view; (c) rely on walk and fly streaming to bring detail to the river.
   [Run BK-0.1 first. If streaming already gives detail there, (c); otherwise (b), because the river panorama is
   the picture people know.]
2. **Bangkok City Hall:** fabric with mapped levels, or a bespoke model. [Fabric first; it sits 45 m away, so
   promote it if E2 shows a miss.]
3. **Temple halls:** styled in the ordinary building path, or kit-built replacements for the large ones.
   [Both: profile for all 433, kit hall for footprints over about 300 m², after measuring cost.]
4. **`man_made=stupa` in the global query:** accept the query and snapshot change. [Yes; it is additive and
   also helps Singapore, Yangon and other Buddhist cities.]
5. **Existing rows** stay in their current registries and are upgraded in place. [Yes.]
6. **Bangkok in `CityDetail.CITIES`.** [Yes if BK-3.10 measures within budget.]
7. **Skyline and BTS last; airports a separate task; royal arches without portraits; preset view and thumbnail
   re-bake only on request.** [Yes to all, as in the first draft.]
