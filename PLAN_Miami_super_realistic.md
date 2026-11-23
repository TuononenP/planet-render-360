# Plan: Make Miami Super-Realistic — Landmarks, Major Buildings, and City

> Tracker in the house style of `PLAN_Turku_super_realistic.md` and `PLAN_Stockholm_super_realistic.md`:
> claim a task, tick it only after its automated and visual checks pass, and add one evidence line.
> Status legend: `[x]` done and validated · `[~]` in progress · `[ ]` open.
>
> Revision 2 (2026-11-20). Replaces the chat summary that was saved here. The first draft is kept at
> `~/.claude/plans/read-make-miami-super-concurrent-badger.md`; this file supersedes it.

## Tracker

- [x] **MI-0.1** Engine trace: how a Miami pin resolves today (zone, region, biome, fleet, water, clock, viaducts)
- [x] **MI-0.2** OSM audit per view centre (tag coverage, tower parts, beach, pools, lifeguard nodes, rail tags)
- [x] **MI-0.3** Reality check of late-2026 status for every building under construction, closed or demolished
- [x] **MI-0.4** Miami preset view + bundled OSM snapshots for centres A and C (decision 2)
- [x] **MI-0.5** Baseline capture round `miami-r0` at the 18 fixed eyes
- [x] **MI-0.6** Reference photo library (`visual-plan/refs/miami/` + `visual-plan/refs/landmarks/<type>/`)
- [x] **MI-0.7** `docs/miami-landmark-sources.md` with measured envelope per row
- [x] **MI-0.8** Slot plan per centre against the selection caps
- [x] **MI-1** Wiring: registry, landmark set, tower-spec table, kit, tests (empty batch builds green)
- [x] **MI-2A** Downtown bayfront icons (Freedom Tower, Kaseya Center, PAMM, Frost, Arsht, Bayfront Park + wheel)
- [x] **MI-2B** Downtown core icons (Miami Tower, Southeast Financial, Courthouse, InterContinental, One Thousand Museum, MiamiCentral, Ferguson Courthouse, Cultural Center)
- [x] **MI-2C** PortMiami (five terminal groups, cruise ships, gantry cranes, Port Boulevard bridge)
- [x] **MI-3A** Skyline towers: Downtown, Park West, Worldcenter, Edgewater (~32 rows)
- [x] **MI-3B** Skyline towers: Brickell, Brickell Key, south Brickell (~38 rows)
- [x] **MI-3C** Miami glazing family and balcony-band facade look
- [x] **MI-4A** Ocean Drive Deco strip (5th–15th St, ~24 named fronts)
- [x] **MI-4B** Collins and Washington Avenue Deco, Lincoln Road and City Center
- [x] **MI-4C** South Pointe, bay-side towers, Miami Beach Marina
- [x] **MI-4D** Mid-Beach (Fontainebleau, Eden Roc, Faena, Blue and Green Diamond)
- [x] **MI-5A** Road bridges and causeways (11 rows + Brickell Avenue Bridge bespoke)
- [x] **MI-5B** Elevated guideways: Metromover and Metrorail in concrete, with stations
- [x] **MI-5C** I-395 Signature Bridge, as far as it stands
- [x] **MI-6.1** `miami` zone, cores and ~28 district circles
- [x] **MI-6.2** `miami_rule` and 12 new architecture rows
- [x] **MI-6.3** `MiamiNotable` facade overrides (~120 OSM-keyed buildings)
- [x] **MI-6.4** Lot dressing: pools, docks, roof decks, parking podiums
- [x] **MI-6.5** Wynwood murals, Little Havana, Design District
- [x] **MI-7.1** Miami tree mix and five new species shapes
- [x] **MI-7.2** Beach: sand palette, dune, wet band, lifeguard towers, umbrellas
- [x] **MI-7.3** Water colour boxes: Biscayne Bay, Atlantic, Government Cut, Miami River
- [x] **MI-7.4** Boats: marinas, bay-island docks, river freighters
- [x] **MI-7.5** Flat terrain, seawalls, sky and clock
- [x] **MI-8** Streets and transport (rail liveries, fleet, street furniture, viaduct roads)
- [x] **MI-9** Night (neon, colour towers, fabric)
- [x] **MI-10** Outer centres E and F and far rows
- [x] **MI-11** Review rounds `miami-rN`, compare sheets, perf baseline, docs, sign-off

---

## What this revision changes

The first draft was written from one exploration pass. Checked against the repo on 2026-11-20, most of its
file and test names hold. These points were wrong or too thin and are fixed below:

1. **Beach support exists in part.** The draft said there is no beach system at all. In fact
   `OsmTags` maps `natural=beach|sand|dune` to the `sand` ground class (`scripts/data/osm_tags.gd:118`),
   `GroundMaterial` has a `sand` id with the `coast_sand_01` PBR set (`ground_material.gd:68,324`,
   `pbr_catalog.gd:37`), and `WaterSurface.sea_ramp_m` already keeps a long shallow shelf off beaches
   (`water_surface.gd:70`) with shore foam driven by `COLOR.b`. What is missing is the Miami sand colour, the
   dune strip, the wet-sand band, and every beach prop. MI-7.2 is therefore an audit plus additions, not a
   new surface system.
2. **Wrong paths.** `water_surface.gd` and `water_shader.gd` live in `scripts/generation/`, not
   `scripts/render/`. `TowerSpec` and `SkyKit` live in `scripts/generation/landmarks/north_america/`.
3. **Miami may not be "tropical" in the engine.** `TreeSpecies.biome_for` calls a place tropical only below
   23.5° latitude; Miami (25.8° N) falls to `mediterranean` (palm, olive, cypress, plane) unless climate data
   is loaded and its coldest month is ≥ 18 °C (`climate_model.gd:117`). Headless tests and cold starts can
   therefore plant olives and cypresses. The sea colour has the same split
   (`WaterSurface.temperate_sea`). MI-0.1 measures both paths; MI-7.1 and MI-7.3 pin Miami by zone so the
   result no longer depends on the climate fetch.
4. **Rail viaducts draw as London brick.** `rail_builder.gd:265` gives every viaduct `deck_brick` fascias
   (`VIADUCT_BRICK_HEX`). Metromover and Metrorail would be soot-brick arches today. MI-5B adds a
   zone-keyed concrete guideway.
5. **Ocean Drive cannot be ~24 registry rows.** The Ultra cap is 22 registry extras and 26 candidates in
   total. The draft's "one row per block with `model_rects_m`" still spends 5–10 slots on low fronts. This
   revision adds a second tier, `MiamiNotable` (pattern `HelsinkiNotable`, applied in
   `osm_parser.gd:357`), so most named fronts keep batched building performance and only the strongest
   silhouettes take a slot.
6. **Factual corrections to check in MI-0.3:** Panorama Tower stands in Brickell (1100 Brickell Bay Dr), not
   Downtown. The Tides is on Ocean Drive (1220), not Collins. The Mandarin Oriental on Brickell Key closed in
   2025 for demolition. The Deauville was demolished in 2022. Miami Seaquarium closed in 2025.
7. **Missing landmarks added:** Bacardi Building (blue azulejo tower and "jewel box"), Wilkie D. Ferguson
   Jr. Courthouse, Miami-Dade Cultural Center, MSC terminal at PortMiami, Villa Regina (Agam rainbow facade),
   The Palace, 500 Brickell, Solitair, Una, Five Park and its Canopy bridge, Art Deco Welcome Center,
   Española Way, Old City Hall, Wolfsonian, Blue and Green Diamond, Ermita de la Caridad, Stiltsville,
   Fly's Eye Dome and Museum Garage, the Miami Freedom Park stadium.
8. **Tower row tooling.** The NYC rows were generated from mapped OSM parts ("way:…: 4 parts, OSM top …"),
   but no generator is in `tools/` (only `tools/audit_new_york.gd`). MI-1 includes a small generator so 70
   rows are not typed by hand.
9. **Test runner note.** `tools/run_tests.sh` already skips `dem_test`, `fidelity_scorecard_test` and
   `preset_snapshot_test` as network tests and the windowed tests; no extra exclusions are needed.

Everything about Miami itself in this plan (heights, storeys, addresses, coordinates, feature lists, status)
is a starting value from memory. Nothing is modelled before MI-0.2, MI-0.3 and MI-0.7 replace it with
measured data.

---

## Context and what the audit found

A case-insensitive search for `miami`, `brickell`, `biscayne`, `south beach` and `wynwood` finds nothing in
`scripts/`, `tests/`, `tools/`, `site/` or `docs/`. A Miami view is 100 % generic:

1. **No landmarks.** No registry rows, no skyline tower specs, no bridge rows. `LandmarkRegistries.entries()`
   has NYC, Central Park, San Francisco and a general North America batch, none for Florida.
2. **No preset and no snapshot.** `PresetViews.ROWS` has 18 rows, none for Miami. Miami is not a capital, so
   `assets/osm_snapshots/` has no file for it and every load goes to live Overpass. Tests such as
   `nyc_skyscraper_sites_test` read `BundledOsm.read("new_york_detailed")`; Miami has nothing to read.
3. **No city style.** `CityStyles.ZONES` has no Miami row, so `zone_at` returns empty, `CityDetail.city_at`
   returns `""`, and buildings take the US `north_america` country row. `REGION_FLEET`, `TAXIS`, `TowerLooks`
   (`GULF` / `ASIA` / `EUROPE` only, so Miami falls back to the New York glass roll) and `building_era.gd`
   `match city` have no Miami case. Closest existing rows: `los_angeles` / `la_spanish`
   (`architecture_cities_new_world.gd:274-300`) and `havana` pastel rows (`HAVANA` palette, line 50).
4. **Vegetation and water depend on the climate fetch** (point 3 above). There is one `palm` species
   (11 m, 15 fronds) and one `sugar_palm`; no royal palm, coconut palm, banyan or mangrove.
5. **Sand renders, nothing else of a beach does.** No dune, no wet band tuned for a wide Atlantic beach, no
   lifeguard towers (`emergency=lifeguard` is not read anywhere), no umbrellas.
6. **Pools are water, not pool decks.** `leisure=swimming_pool` is recognised as artificial water
   (`osm_tags.gd:819`) and excluded from the far water mask. Whether a backyard pool draws as turquoise pool
   water or as sea-coloured water is unchecked.
7. **Harbour dressing is generic but present.** `CargoBerths` puts cargo ships on port quays and
   `QuayMoorings.liners` puts liners on plain quays; `LargeShips` commits them. `HarbourFerries` routes are
   Staten Island only. Nothing guarantees cruise ships at PortMiami's real berths.
8. **Local clock.** Without the weather service, `AtmosphereRig` uses `round(lon / 15)` = UTC−5. Miami is
   UTC−4 from March to November, so summer captures run one hour off until the offset arrives.

The machinery is data-driven and proven by the Stockholm, Turku, Tokyo/Seoul and NYC passes. Miami needs
rows in each table, three shared additions (concrete guideways, beach dressing, a balcony-band facade), and
bespoke builders for the icons.

**Intended outcome:** from Bayfront Park, Brickell Key, the MacArthur Causeway and Ocean Drive, a person who
knows Miami recognises each landmark and major tower by shape, proportion, material and night look, and the
fabric between them (pastel Deco, white balcony condos, palms, sand, bay water) reads as Miami.

---

## Decisions (defaults assumed until changed)

The first draft asked five questions that were not answered. The plan proceeds on the recommended answer for
each; changing one only moves tasks, it does not invalidate earlier work.

| # | Decision | Assumed | Effect if changed |
| --- | --- | --- | --- |
| 1 | Scope | Centres A–C in full, then D–F | Dropping D–F removes MI-4D and MI-10 |
| 2 | Offline data | Add a `miami` preset (centre A) and a `miami_beach` preset (centre C) with bundled snapshots | Without it MI-0.4 is skipped and every Miami test must be data-free (registry and model tests only) |
| 3 | Under-construction buildings | Build the real late-2026 state | "Build as finished" would add Waldorf Astoria at full height and all six bridge arches |
| 4 | Miami International Airport | Separate follow-up (`tools/capital_airports.py` is capitals-only) | Adds a manual airfield row to MI-10 |
| 5 | Guideways and beach dressing | Built generally, keyed by zone or tag, verified on Miami only | Miami-only code is smaller but helps no other city |

A new preset means a new card in the place picker. That is a UI change, so it follows the Planet Render 360
design system (`project/README.md` first); the card picture is baked with
`capture_presets.gd --bake-thumbs` like the others.

---

## Three-tier strategy

1. **Tier 1: bespoke models (~55 registry rows + ~8 bridges).** Icons and low complexes whose shape no
   parametric row can express. One builder file each under `scripts/generation/landmarks/miami/`.
2. **Tier 1S: skyline tower rows (~85 `TowerSpec` rows).** Named towers as data in `MiamiTowerSpecs*`,
   `skyline: true`, drawn from their mapped OSM parts plus a hand-set finish and crown. They use the skyline
   channel (110 slots on Ultra) and never take an icon's slot.
3. **Tier 2: `MiamiNotable` overrides (~120 buildings).** Named buildings that stay OSM extrusions but get
   their true material, colour, roof, storeys, year and, new for Miami, a `deco` block (parapet type, eyebrow
   lines, fin, sign text and colour). Most Ocean Drive, Collins, Lincoln Road, Calle Ocho and Coral Gables
   fronts live here.
4. **Tier 3: district fabric.** The `miami` zone, ~28 district circles, `miami_rule` and 12 architecture
   rows, so every other building takes the right type for its district, height and age.

---

## Definition of done

### Per Tier 1 model

All ten must hold (same bar as Turku):

1. **References:** 3+ CC BY / CC BY-SA / CC0 / PD photos in `visual-plan/refs/landmarks/<type>/` (front,
   quarter, aerial, night where lit), with URL, author and licence in its `README.md`. Fetch with
   `tools/commons_refs.py`. No Russian-operated host, ever (`HostPolicy`).
2. **Measured envelope:** footprint, centroid and long-axis `yaw_deg` from the OSM way or relation; heights
   from OSM `height` / parts, cross-checked with Wikidata P2048 and CTBUH; recorded in
   `docs/miami-landmark-sources.md`.
3. **Spec header:** the builder opens with plan dimensions, tier heights, bay and storey counts, roof form,
   materials and signature details counted from the photos.
4. **Signature features readable at 150 m:** every feature in the phase tables is geometry, not a texture
   on a box.
5. **Materials:** hues sampled from daylight photos through `LandmarkMaterials` (`pbr`, `paint`, `glass`,
   `lit`, `pool_water`); no flat paint on stone or stucco.
6. **Roof:** true form, plant screens, pool decks and helipads, checked in the `roofs` capture.
7. **Site:** `clear_m` / `clear_rect_m` / `model_rects_m` remove the duplicate OSM extrusion and nothing
   else; `tree_rect` keeps lawns and plazas clear; the model meets flat ground with no gap.
8. **Night:** `LandmarkLights.FLOOD_META`, `HALO_META`, `NIGHT_GLOW_META` or `lit` surfaces match the real
   lighting.
9. **Budgets:** one class per file, ≤ 1000 lines; 2–16 merged surfaces; ≤ 150,000 triangles; top within
   max(2 m, 3 %) of `height_m`; built under a "Model" node (`tests/landmark_catalog_test.gd`).
10. **Evidence:** one four-view studio sheet (`tools/capture_landmarks.gd` +
    `tools/landmark_compare_sheets.py`) and one in-world `--looks` frame from an open-space eye, both
    inspected.

### Per skyline row

1. Row comment names the OSM way or relation, part count and OSM top height.
2. `height_m` within 2 % of the sourced height; `yaw_deg` from the outline's long axis.
3. `clear_m` stops short of the nearest other building over 40 m (`miami_skyscraper_sites_test`).
4. ≤ 15,000 triangles (the NYC skyline budget).
5. Finish and crown match a daylight photo; one skyline capture shows it in place.

### Per `MiamiNotable` row

1. Keyed by a verified `way:<id>` / `relation:<id>` with name, address and source.
2. `tests/miami_notable_test.gd` proves every key exists in the bundled Miami snapshot and that the row wins
   over the district roll.

---

## Ground rules for the whole pass

- Model the city as it stands in late 2026 (decision 3).
- Selection caps (`scripts/data/landmark_sites.gd:15-26`), per preset Fast / Balanced / High / Ultra:
  candidates 10 / 16 / 22 / 26, registry extras 6 / 12 / 18 / 22, bridges 2 / 4 / 6 / 8, skyline towers
  12 / 30 / 60 / 110. A primary may raise the Ultra extras to 26 with `ultra_registry_limit`.
- Matching is by position: registry lat/lon is the OSM outline centroid and `yaw_deg` its long axis.
- **Name collision:** "freedom tower" is an alias of One World Trade Center
  (`scripts/data/location_data.gd:491`). Miami's tower is type `freedom_tower_miami` with aliases
  "freedom tower miami" and "miami news tower", never the bare name. A test pins both resolutions.
- The working tree holds a lot of the user's uncommitted work, including `city_styles.gd`,
  `architecture_style.gd`, `building_era.gd`, `marina_builder.gd`, `quay_moorings.gd`, `large_ships.gd`,
  `road_builder.gd`, `ground_material.gd`, `preset_views.gd`, `bundled_osm.gd`, `train_specs.gd`,
  `tram_specs.gd`, `station_trains.gd`, `atmosphere_rig.gd` and `city_detail.gd`. This plan edits many of
  them. Before each such edit run `git diff` on the file, add rows next to the existing ones, stage only own
  hunks by path, and commit only when asked. No AI attribution anywhere.
- Overpass through the openstreetmap.fr or kumi mirrors. No `.ru` / `.su` / `.рф` host.
- Godot only through `tools/godot_bg.sh`. Tests headless and in the background. Captures windowed, in the
  background, `--position 4000,4000`, `--preset=3`, batched per round. Eyes in open space only.
- `tools/check_class_size.sh` after every new or grown class.

---

## View centres and fixed eyes

The detailed world is about 2.4 km across (`LandcoverFetcher.EXTENT_M`; confirm
`WorldScale.DETAILED_EXTENT_M` in MI-0.1). Miami's sights span 15 km, so the pass works by view centre.
Registry rows show from any pin within their `radius_m`; centres only set priorities and capture eyes.

| # | Centre | Approx. pin | What must be right there |
| --- | --- | --- | --- |
| A | Downtown / Bayfront Park | 25.7743, -80.1855 | Downtown wall, Freedom Tower, arena, Museum Park, port |
| B | Brickell / river mouth | 25.7670, -80.1900 | Brickell canyon, river bascules, Brickell Key |
| C | South Beach / Lummus Park | 25.7810, -80.1300 | Ocean Drive strip, beach, South Pointe |
| D | Mid-Beach | 25.8180, -80.1220 | Fontainebleau, Eden Roc, Faena, Collins canyon |
| E | Vizcaya / Coconut Grove | 25.7444, -80.2105 | Villa and gardens, Dinner Key, Grove towers |
| F | Coral Gables | 25.7410, -80.2790 | Biltmore, Venetian Pool, City Hall, Miracle Mile |

**Fixed eyes** (`lat,lon,height_m,bearing,pitch`). Coordinates are starting values; MI-0.5 checks each one
stands on open ground or open water and corrects it once. The corrected list is then frozen and reused in
every round. Water eyes are drone eyes over the mapped water polygon, not heights over a riverbed.

| Eye | Where | lat, lon | h (m) | Bearing | Shows |
| --- | --- | --- | --- | --- | --- |
| A1 | Bayfront Park lawn | 25.77520, -80.18580 | 3 | 0 | Kaseya, One Thousand Museum, Park West wall |
| A2 | Bayfront Park lawn | 25.77520, -80.18580 | 3 | 265 | Southeast Financial, Miami Tower, 50 Biscayne |
| A3 | Bay off Bayfront | 25.77450, -80.17900 | 25 | 270 | Whole downtown wall, wheel, InterContinental |
| A4 | Museum Park baywalk | 25.78500, -80.18520 | 3 | 300 | PAMM, Frost sphere, Arsht behind |
| A5 | Biscayne Blvd median at NE 6th St | 25.78000, -80.18850 | 3 | 290 | Freedom Tower front |
| A6 | Biscayne Bay off Port Boulevard | 25.78120, -80.17950 | 30 | 115 | Terminals, cruise ships, cranes (moved 51 m clear of Terminal V) |
| B1 | Brickell Key north tip | 25.77000, -80.18500 | 3 | 320 | River mouth, Aston Martin, One Miami |
| B2 | Brickell Ave Bridge south approach | 25.76900, -80.19000 | 3 | 0 | Bascule, Tequesta column, downtown |
| B3 | S Miami Ave at SE 8th St | 25.76635, -80.19336 | 3 | 190 | Brickell canyon, City Centre, Metromover (moved onto roadway 18.5 m clear) |
| B4 | Bay off Brickell Bay Dr | 25.76000, -80.18820 | 4 | 345 | Four Seasons, Panorama, Jade (moved east of Jade footprint) |
| M1 | MacArthur Causeway, bay side | 25.77900, -80.16500 | 30 | 265 | Skyline from the east |
| M2 | Same point | 25.77900, -80.16500 | 30 | 150 | Port and Fisher Island |
| C1 | Lummus Park sand at 10th St | 25.78050, -80.12880 | 3 | 270 | Ocean Drive fronts over the dune |
| C2 | Ocean Drive at 8th St | 25.77850, -80.13100 | 2 | 10 | Colony, Pelican, Breakwater in sequence |
| C3 | Ocean Drive at 13th St | 25.78450, -80.12975 | 2.5 | 205 | Carlyle, Leslie, Cardozo, The Tides (moved onto Ocean Dr 26.9 m clear) |
| C4 | South Pointe pier | 25.76350, -80.12980 | 4 | 350 | Beach, South of Fifth towers |
| C5 | Lincoln Road at Lenox/Alton | 25.79055, -80.14015 | 3 | 285 | 1111 Lincoln Road (moved onto Lincoln Rd mall 9.8 m clear of cinema) |
| D1 | Beach at 44th St | 25.81800, -80.12050 | 3 | 290 | Fontainebleau curve, Eden Roc |
| E1 | Biscayne Bay off Vizcaya Barge | 25.74380, -80.20900 | 6 | 295 | Vizcaya villa, gardens and Stone Barge |
| F1 | Biltmore golf fairway south | 25.73930, -80.27980 | 4 | 22 | Biltmore Giralda tower, wings and lagoon pool |

Eyes E1 (bay off the Vizcaya barge) and F1 (Biltmore golf side) are added when MI-10 starts.

---

## Phases

### Phase 0: trace, data, references, slots

- **MI-0.1 Engine trace.** Write a scratch script (not committed) that builds a `LocationData` at pins A
  and C and prints: `CityStyles.zone_at`, `region_at`, `ArchitectureStyle.country_region_for`,
  `TreeSpecies.biome_for_data` with and without climate data, `WaterSurface.sea_palette`,
  `CarFleet` fleet id, `TrainSpecs.pick` for a `subway` and a `light_rail` viaduct way, the UTC offset, and
  `WorldScale.DETAILED_EXTENT_M`. Record the table in this file under "Evidence". This fixes the "before"
  for Phases 6–8.
- **MI-0.2 OSM audit.** One Overpass query per centre A–F (2.5 km radius). Counts of buildings with
  `height`, `building:levels`, `building:part`, `building:colour`, `building:material`, `roof:shape`,
  `start_date`; `natural=beach`, `natural=sand`, `leisure=swimming_pool`, `leisure=marina`,
  `man_made=pier`, `emergency=lifeguard`, tree nodes with `genus` / `species`; rail ways by
  `railway=subway|light_rail|monorail` with `bridge` values (this settles how Metromover is tagged).
  Per named tower: way id, part count, OSM top. Output `visual-plan/audits/miami-osm-audit.tsv`. Towers
  whose parts already give true massing get `BuildingReferences` / `LandmarkFidelity` evidence rows instead
  of a spec.
- **MI-0.3 Reality check.** For each of these, record the real late-2026 state with a dated source in the
  sources doc, then mark it build / build-partial / skip: Waldorf Astoria Residences, Okan Tower, Cipriani
  Residences, Baccarat Residences, 888 Brickell, St. Regis Residences, 1428 Brickell, One Brickell City
  Centre, Mandarin Oriental Brickell Key (closed for demolition), Hyatt Regency / Knight Center
  redevelopment, Raleigh and Shore Club redevelopments, I-395 Signature Bridge arches, SW 1st St bridge
  replacement, the new civil courthouse beside the 1928 one, Miami Seaquarium, Coconut Grove Playhouse,
  Miami Freedom Park stadium, MSC cruise terminal, Aria Reserve towers.
- **MI-0.4 Preset and snapshots** (decision 2). Add `miami` (pin A; opening eye A3-like from the bay
  toward the skyline, lowered to a safe quay if the bay eye fails the `clear` rule) and `miami_beach`
  (pin C; opening eye on Lummus Park toward the fronts) to `PresetViews.ROWS`. Fetch detailed (q12), far,
  ring 1600, ring 2500, POI and transit layers through a mirror, write them with
  `tools/prepare_osm_snapshot.py`, add rows to `BundledOsm.ENTRIES` and the table in
  `assets/osm_snapshots/README.md`, add the horizon layer (`tools/prepare_horizon_layer.py`). Check for hit
  output caps as the Stockholm ring did. Tests: `bundled_osm_test`, `preset_views_test`. Expected repo growth: about 6–8 MB.
- **MI-0.5 Baseline captures.** One batched run per centre A–C:
  `--tag=miami-r0 --preset=3 --pin=<centre> --times=golden,noon,night,late,roofs --looks="<eyes>"`.
  Inspect every frame; move any eye that sits in a mass; freeze the eye list in this file.
- **MI-0.6 References.** `visual-plan/refs/miami/` gets 18 city views matching the fixed eyes (for the
  compare sheets); each landmark gets its own folder. Image binaries stay gitignored, the README is tracked.
- **MI-0.7 Sources doc.** `docs/miami-landmark-sources.md` in the format of
  `docs/turku-landmark-sources.md`: type, tier, OSM id, centroid, yaw, height and its source, key
  dimensions, 2026 status, reference links. Every later task reads its numbers from here.
- **MI-0.8 Slot plan.** See "Slot budget" below; rewrite it with measured rows before any builder is
  started.

### Phase 1: wiring a Miami batch

New files:

- `scripts/data/landmark_registry_miami.gd` (`LandmarkRegistryMiami.entries()`), composed from group files
  under `scripts/data/miami/` as Stockholm does (`mia_reg_downtown.gd`, `mia_reg_port.gd`,
  `mia_reg_brickell.gd`, `mia_reg_beach.gd`, `mia_reg_midbeach.gd`, `mia_reg_grove_gables.gd`,
  `mia_reg_far.gd`).
- `scripts/generation/landmarks/miami/landmark_set_miami.gd` (`LandmarkSetMiami.build`, `match` on type;
  falls through to `MiamiTowerSpecs.spec_for(type)` then `TowerSpec.build`).
- `scripts/data/miami_tower_specs.gd` (`row()`, `entries()`, `spec_for()`, copied from
  `nyc_tower_specs.gd`) with area classes `miami_tower_specs_downtown.gd`, `_edgewater.gd`, `_brickell.gd`,
  `_beach.gd`, `_far.gd`. `radius_m` keeps the NYC rule `clamp(height × 22, 3000, 8000)`.
- `scripts/generation/landmarks/miami/landmark_mi_kit.gd`: only shapes used by two or more builders: Deco
  eyebrow, ziggurat parapet, vertical fin with sign, porthole row, balcony-slab stack, royal palm, neon
  tube line, barrel-tile roof strip.
- `tools/miami_tower_rows.py`: reads a decoded snapshot (`tools/osmb.py decode`), and for a list of way or
  relation ids prints a `MiamiTowerSpecs.row(...)` line with centroid, long-axis yaw, `poly` ops from the
  mapped parts in the model frame, OSM top, and the `clear_m` the nearest tall neighbour allows. Finish and
  crown are then set by hand.
- Both batches registered in `scripts/data/landmark_registries.gd` (`entries()` and `sets()`).
- Bridge rows in `scripts/data/bridges/bridge_specs_north_america.gd` (non-capital rows are allowed, as
  Turku's are in `bridge_specs_north_europe.gd`).

Tests (all headless):

- `tests/miami_landmarks_test.gd`, modelled on `stockholm_hero_landmarks_test.gd` and
  `turku_landmarks_test.gd`: `EXPECTED_TYPES`, `EXPECTED_BRIDGES`, coordinates inside the Miami box
  (25.60–26.00 N, −80.45 to −80.05 E), alias resolution including both Freedom Towers, heights, 2–16
  textured parts, nothing below ground, pinned Ultra selection for centres A, B and C.
- `tests/miami_tower_specs_test.gd` (pattern `nyc_tower_specs_test`).
- `tests/miami_skyscraper_sites_test.gd` (pattern `nyc_skyscraper_sites_test`, reading the bundled Miami
  snapshots; needs MI-0.4).

Reuse, do not re-invent: `LandmarkMesh`, `LandmarkMaterials`, `LandmarkDetail`, `LandmarkKits`, `SkyKit` and
the `TowerSpec` ops (`tier`, `notch`, `shape`, `poly`, `gap`, `louvre`, `pyramid`, `hip`, `solid`, `steps`,
`spire`, `box`, `dome`, `diagrid`, `slope`, `ribs`; plans `rect`, `chamfer`, `round`, `ellipse`, `hex`,
`tri`), `LandmarkBrKit` and `BridgeParam` (beam, arch, cable, movable, masonry), `LandmarkLights`,
`LandmarkWheel`, `CruiseLinerModel`, `MarinaBuilder`, `LandmarkImpostor`. Templates: tower = NYC rows; low
complex = `landmark_ft_paavo_nurmi.gd`; bespoke bridge = `landmark_fh_crown_bridge.gd`.

Exit: the empty batch loads, all three tests pass with empty expectation lists, class-size check passes.

### Phase 2: Downtown and bayfront icons (centre A)

"Looks like real life" means every listed feature is readable in the capture beside the reference photo.
Starting figures are to be replaced from the sources doc.

**MI-2A Bayfront**

| ID | Landmark | Start values | Must-have features | Approach, parts, budget |
| --- | --- | --- | --- | --- |
| 2A.1 | **Freedom Tower** | 600 Biscayne Blvd; 1925; ~78 m; 25.7802, −80.1896 | Giralda-style tower on a three-storey base; cream-yellow stucco; ornate cast-stone entrance with arched loggia; four diminishing belfry tiers with arched openings and urns; small copper-green cupola and finial; warm flood at night | Bespoke `landmark_mi_freedom_tower.gd`; tiers as `poly_prism`, `LandmarkDetail.arch / cornice / balustrade`; ~10 surfaces, ~45k triangles; type `freedom_tower_miami` |
| 2A.2 | **Kaseya Center** | 601 Biscayne; 1999 | White curved concrete drum on the bay; sweeping glass front toward the bay; large media-mesh screen toward Biscayne Blvd; stepped plaza; roof plant ring | Bespoke low complex (`lathe` drum, `grid` glass); screen as a `lit` panel; ~8 surfaces, ~40k |
| 2A.3 | **Pérez Art Museum Miami** | 1103 Biscayne; 2013 | Raised platform on slender columns; deep slatted timber-and-concrete canopy overhanging all sides; hanging vertical garden columns; three-level concrete and glass box; wide stair down to the bay | Bespoke; canopy as slat `beam` rows at two densities; garden tubes as green `beam`s; ~10 surfaces, ~60k |
| 2A.4 | **Frost Museum of Science** | 1101 Biscayne; 2017 | White planetarium sphere; four blocks around the open "Gulf Stream" aquarium cone with oculus; solar terrace | Bespoke; `lathe` sphere and cone; ~8 surfaces, ~35k |
| 2A.5 | **Adrienne Arsht Center** | 1300 Biscayne; 2006 | Two faceted stepped halls facing each other across the boulevard; pale stone and stepped glass curtains; footbridge; preserved 1929 Sears Deco tower | One row with `model_rects_m` for the two halls; Deco tower from the kit; ~12 surfaces, ~70k |
| 2A.6 | **Bayfront Park, Bayside, Skyviews wheel** | wheel ~60 m at 25.7783, −80.1862 | Observation wheel with white gondolas at the water's edge; Bayside's open pavilions and Miamarina; amphitheatre shell; laser tower; royal-palm baywalk; lawn clear of procedural trees | Wheel: registry row built by `LandmarkWheel.build` (already used for `big_wheel`); park through `tree_rect` and OSM surfaces; marina through `MarinaBuilder`; Bayside as a low bespoke row only if OSM parts are poor |
| 2A.7 | Bacardi Building | 2100 Biscayne; 1963 / 1973 | Blue-and-white azulejo mural on the tower's end walls; glass sides; the square "jewel box" annex with stained-glass walls raised on a core | Bespoke, small; mural as a procedural tile pattern in the building's colours (no copy of the artwork); ~6 surfaces, ~15k |

**MI-2B Downtown core**

| ID | Landmark | Start values | Must-have features | Approach |
| --- | --- | --- | --- | --- |
| 2B.1 | **Miami Tower** | 100 SE 2nd St; 1987; ~191 m; 47 fl | Three stepped glass tiers, flat back and curved bay front; white horizontal bands; tall garage podium with the Metromover station through it; whole tower colour-washed at night | `TowerSpec` `shape` tiers (`round` on one side via `poly`); night wash through `NIGHT_GLOW_META`, colour from a small table |
| 2B.2 | **Southeast Financial Center** | 200 S Biscayne; 1984; ~233 m; 55 fl | White granite and grey glass grid; south-east corner cut into a sawtooth of setbacks near the top; separate banking hall joined by a space-frame canopy over a palm court | `TowerSpec` with a `notch` series; annex and canopy (`diagrid`) as own parts |
| 2B.3 | **Miami-Dade County Courthouse** | 73 W Flagler; 1928; ~110 m | Grey-white terracotta; column-fronted base; stepped shaft; ziggurat pyramid top | `TowerSpec` tiers + `steps` + `pyramid`; `LandmarkDetail.colonnade` at the base |
| 2B.4 | **InterContinental Miami** | 100 Chopin Plaza; ~112 m | Travertine slab on a triangular podium at the bay; giant animated figure on the facade at night | Spec row (`tri` plan podium); night figure as a `lit` panel, static pose |
| 2B.5 | **One Thousand Museum** | 1000 Biscayne; 2019; ~216 m; 62 fl | White curving exoskeleton that splits and rejoins up the faces; dark glass behind; rooftop helipad | Skyline row; `TowerSpec` body + bespoke exoskeleton sweeps (`beam` chains along four mirrored curves); budget 15k triangles forces ~10 segments per curve, raise to an icon row if that reads badly |
| 2B.6 | **MiamiCentral + Government Center** | NW 1st Ave | Brightline station raised on V-shaped trusses over the streets; towers above; Stephen P. Clark Center slab; Metrorail and Metromover hub | Bespoke V-truss band (`beam`); towers as spec rows |
| 2B.7 | Wilkie D. Ferguson Jr. Courthouse | 400 N Miami Ave; 2007 | Twin curved glass slabs like two hulls joined by a glass atrium; grass mounds in the plaza | Spec row with two `poly` lofts |
| 2B.8 | Miami-Dade Cultural Center | 101 W Flagler; 1983 | Mediterranean-style raised plaza, three stucco blocks with clay-tile roofs and arcades | Evidence row or small bespoke |
| 2B.9 | Downtown heritage (Tier 2 first) | | Gesù Church (pink), Olympia Theater, Alfred I. duPont Building, Ingraham Building, Dade Commonwealth, Central Baptist, Scottish Rite Temple, Trinity Cathedral | `MiamiNotable` rows; bespoke only if still wrong in captures |

**MI-2C PortMiami**

| ID | Item | Must-have features | Approach |
| --- | --- | --- | --- |
| 2C.1 | Royal Caribbean Terminal A | "Crown of Miami": angular glass prow with an M profile from the water | Low bespoke row, `grid` loft |
| 2C.2 | Norwegian Terminal B | Pearl-white nautilus shell curves | Low bespoke row |
| 2C.3 | Virgin Terminal V | Palm-grove roof plane on slender columns | Low bespoke row |
| 2C.4 | Carnival and MSC terminals | Long glazed halls; the MSC terminal is the largest (status in MI-0.3) | One grouped row with `model_rects_m`, or evidence rows if OSM parts suffice |
| 2C.5 | Cruise ships | Three to five liners alongside the mapped north berths, bows the same way, fully lit at night | First check what `QuayMoorings.liners` already places at pin A. If the berths are missed, add a Miami berth list (OSM `man_made=pier` / quay ways) so `LargeShips` places `liner` entries there; stays "harbour dressing, not real vessels" |
| 2C.6 | Container port | Red-and-white ship-to-shore gantry cranes on the south side; container stacks | Check `CargoBerths` (needs port land behind the quay); add a crane row or prop only if none appears |
| 2C.7 | Port Boulevard Bridge | High fixed girder span with colour LED at night; low rail bascule beside it | Bridge row (MI-5A) |

Validation per task: catalog, placement and lights tests green; studio sheet and in-world frame beside the
reference photo; silhouette, proportion, colour and night frame recognisable; no frame from inside a mass.
Three of these icons take `skyline_priority` (Freedom Tower, Miami Tower, One Thousand Museum if promoted).

### Phase 3: skyline towers (centres A and B)

Each row: OSM id, footprint ops from mapped parts (`tools/miami_tower_rows.py`), height from the sources
doc, finish, crown. Priority 2 = defines the skyline, 1 = clearly visible, 0 = filler.

**MI-3A Downtown, Park West, Worldcenter, Edgewater (~32 rows)**

- Priority 2: Aston Martin Residences (~249 m, curved sail profile at the river mouth), Paramount Miami
  Worldcenter (~213 m, lit crown), Marquis (~207 m), 900 Biscayne Bay (~198 m), Wells Fargo Center
  (~197 m), Marinablue (~187 m, wave-cut top), Ten Museum Park (~178 m), Epic (~172 m), 50 Biscayne
  (~169 m), Vizcayne pair, One Miami pair at the river mouth, One Biscayne Tower (1972).
- Priority 1: Miami Center, Met 1, Natiivo, The Elser, Caoba, Bezel, Legacy, Miami World Tower, Downtown
  5th, Missoni Baia, Elysee, Aria Reserve pair, Paraiso Bay group, Biscayne Beach, Aria on the Bay,
  Quantum on the Bay pair, Opera Tower, Paramount Bay, 1800 Club.
- Status rows from MI-0.3: Waldorf Astoria (offset stacked cubes; build the cubes that stand), Okan Tower.

**MI-3B Brickell, Brickell Key, south Brickell (~38 rows)**

- Priority 2: Panorama Tower (~265 m, tallest; the anchor of the Brickell skyline), Four Seasons (~240 m),
  Brickell Flatiron (~224 m, curved glass wedge with rounded balconies), 830 Brickell (~221 m), SLS Lux,
  Infinity, Echo Brickell, Icon Brickell (three towers; podium columns with carved faces), Brickell City
  Centre (Reach, Rise, EAST) with the **Climate Ribbon** trellis as one bespoke low row, Brickell Arch /
  Espirito Santo Plaza (tall concave arch cut into the glass front), Solitair (diamond palm-trunk facade).
- Priority 1: SLS Brickell, Brickell Heights pair, 1010 Brickell, Brickell House, The Bond, Millecento,
  Axis pair, The Plaza pair, 500 Brickell pair (square portal between them), Mint, Wind, Ivy, Latitude,
  Brickell on the River pair, 1450 Brickell, 701 Brickell, 600 Brickell, Sabadell Financial Center,
  1221 Brickell, Jade at Brickell Bay, Una, Four Ambassadors (four 1968 slabs).
- Brickell Key: Asia, Carbonell, Two and Three Tequesta Point, Courvoisier. Mandarin Oriental per MI-0.3.
- South Brickell icons: **The Atlantis** (blue glass slab; five-storey square hole with red spiral stair
  and palm; yellow triangular balcony; red roof prism; four yellow balconies stacked on the south side),
  **Villa Regina** (rainbow-banded painted facade), **The Palace** (stepped red frame through a white
  slab), The Imperial, Santa Maria, Bristol Tower. The Atlantis is bespoke, the rest spec rows.
- Far-ring rows with large `radius_m`: South of Fifth group, Blue and Green Diamond, Fisher Island, Sunny
  Isles wall (Porsche Design Tower, Jade Signature, Muse, Turnberry Ocean Club), Coconut Grove towers.

**MI-3C Finish and balconies**

- `TowerLooks`: add a `MIAMI` key list (`"miami"`) and a `"miami"` palette, starting
  `lowe_blue` 0.35, `green_glass` 0.55, `silver_reflective` 0.75, `clear_fin` 0.90, `intl_bronze` 1.0
  (the 1980s bronze towers); tune against the skyline photo. Test: a new `tests/tower_looks_test.gd` (pattern
  `nyc_tower_looks_test`).
- **Balcony band:** Miami's signature is white slab edges wrapping glass. Check `facade_composer.gd`,
  `relief_kit.gd` and `modern_block_relief.gd` first (balconies exist for other rows). Add one look usable
  by procedural towers and by `TowerSpec` (`walls` finish id such as `balcony_white`): continuous white
  slab edge every floor, glass rail, shadowed recess, rounded or square corners. No per-tower balcony
  geometry.

Validation: `miami_tower_specs_test`, `miami_skyscraper_sites_test`, `landmark_ultra_lod_test`,
`impostor_test`; eyes A3, B1, B4 and M1 beside the skyline reference photos. Silhouette score from
`tools/landmark_silhouette_scores.py` recorded per round.

### Phase 4: Miami Beach (centres C and D)

**MI-4A Ocean Drive, 5th to 15th Street.** A data table `scripts/data/miami_deco_fronts.gd`
(`MiamiDecoFronts`), one row per hotel: OSM way, address, storeys, front width, palette (body, trim,
accent), parapet type (`ziggurat`, `stepped`, `flat`, `curved`), eyebrow lines per storey, fin or pylon
(position, height), corner (`square`, `round`), porthole rows, sign text, sign colour, neon colours, terrace
(awning colour, umbrella colour). Starting list, south to north, addresses to verify:

Park Central (640), Majestic (660), Avalon (700), Beacon (720), **Colony (736, blue neon fin)**, Starlite
(750), Pelican (826), Waldorf Towers (860, corner lantern), **Breakwater (940, tall central sign pylon)**,
Edison (960), Art Deco Welcome Center / Beach Patrol HQ (1001, on the park side, nautical Deco),
Clevelander (1020), Congress (1052), **Casa Casuarina (1116, Mediterranean mansion, tiled roof,
observatory)**, The Tides (1220, tallest on the strip), **Leslie (1244, yellow)**, **The Carlyle (1250,
three-bay curved white front)**, **Cardozo (1300, rounded corner)**, Cavalier (1320), Winter Haven (1400),
Crescent (1420), McAlpin (1424, pink and turquoise), The Betsy (1440, Georgian portico).

How they are drawn:

- A `deco` facade style driven by `MiamiNotable` + `MiamiDecoFronts`, so every front keeps its real OSM
  footprint and gets its palette, eyebrows, parapet and sign through the normal building path (batched).
  This needs a small hook in the facade path; find the cheapest point in `facade_composer.gd` /
  `facade_patterns.gd` and keep the new code in its own class (`deco_front.gd`).
- Registry rows only for the eight bold names above (strongest silhouettes and signs), grouped two per row
  where neighbours (`model_rects_m`), so the strip costs at most five icon slots at centre C.
- Terraces: awnings, umbrellas and tables on the Ocean Drive side on Ultra, from the table.

**MI-4B Collins, Washington, Lincoln Road, City Center**

| Item | Must-have features | Approach |
| --- | --- | --- |
| Delano (1685 Collins) | White; four-winged finned crown | Spec row + bespoke crown |
| National (1677 Collins) | Silver cupola tower; long narrow pool | Spec row + `dome` |
| Ritz Plaza / SLS (1701), Sagamore, Shelborne (1801), Setai tower, Loews (1601), Royal Palm, Essex House (1001), Marlin (1200) | Each crown and corner treatment | Spec rows or notable rows; Raleigh and Shore Club per MI-0.3 |
| Old City Hall (1130 Washington) | Nine-storey Mediterranean Revival tower with tiled top | Small bespoke or spec row |
| Wolfsonian, Post Office (rotunda), Temple Emanu-El (Byzantine dome), Española Way (pink Mediterranean street) | Colour and roof | `MiamiNotable` rows |
| **1111 Lincoln Road** | Open concrete card-house garage: thin slabs at uneven heights on wedge columns, no walls | Bespoke; slabs and V columns as boxes; ~6 surfaces, ~20k |
| **New World Center** | White Gehry box with a 30 m projection wall facing SoundScape Park; glass atrium with tumbling forms | Bespoke; wall as a `lit` panel at night |
| Convention Center | Long undulating aluminium-fin facade | Bespoke band of angled fins |
| **Holocaust Memorial** | Bronze reaching arm with climbing figures, in a round lily pond with a colonnade | Bespoke; arm as a tapered `lathe` with relief blobs; `pool_water` |
| Lincoln Road mall | Pedestrian street with Lapidus follies, palms, café umbrellas; Lincoln and Colony Theatres | Fabric + notable rows |
| Bass Museum, Fillmore, Miami City Ballet, City Hall | Colour and massing | Notable rows |

**MI-4C South Pointe and the bay side.** South Pointe Park (serpentine light pylons, lawn mound) and pier
with turtle-light masts, bespoke. Government Cut jetty. Skyline rows: Portofino Tower (stepped
Deco-postmodern crown), Continuum pair, Apogee, Murano Grande, Murano at Portofino, Icon South Beach,
Glass, One Ocean, Yacht Club; bay side: **Five Park** (tallest in Miami Beach) with the striped Canopy
footbridge over 5th Street (status in MI-0.3), Bentley Bay pair (curved sail fronts), Floridian, Mirador
pair, Waverly, Mondrian, Flamingo towers, Sunset Harbour pair. Miami Beach Marina through `MarinaBuilder`.

**MI-4D Mid-Beach.** **Fontainebleau** (white curved Lapidus slab, Tresor and Sorrento towers, lagoon
pool): bespoke with a `grid` curved slab and balcony bands. **Eden Roc** (white with the ship-funnel
crown and sign): spec row + bespoke crown. **Faena** (red-trim Saxony, the white perforated Faena Forum
drum, Faena House with wrapped balconies): one bespoke drum + two spec rows. Blue and Green Diamond
(twin 44-storey towers with diamond-cut tops): spec rows, far-ring priority 2. Soho Beach House,
Fontainebleau's neighbours along the Collins canyon: notable rows.

**Bay islands** (fabric, MI-6.4): Star, Palm, Hibiscus and the Venetian Islands with waterfront mansions,
pools, lawns, docks and yachts. Small rows: Flagler Memorial Island obelisk; Watson Island (Children's
Museum, Jungle Island, seaplane base, superyacht marina); Fisher Island towers.

Validation: eyes C1–C5 and D1, day, night and late; `miami_notable_test`; a new
`miami_deco_fronts_test` (every row has an OSM way in the snapshot, a palette of three colours, a parapet
type the builder knows, and sign text ≤ 16 characters).

### Phase 5: bridges, causeways, guideways

**MI-5A Bridge rows** in `bridge_specs_north_america.gd`, schema as the existing rows (`id`, `cc`, `name`,
`wiki`, `aliases`, `lat`, `lon`, `bearing`, `st`, `spans`, `width`, `clear`, `material`, `base`, `tier`,
`conf`, `src`). `conf` ≥ 2 with measured spans, or the row is data only (`BridgeSpec.MIN_BUILT_CONF`).
Ids `br_miami_*`.

| Bridge | Type (`st`) | Notes to measure |
| --- | --- | --- |
| MacArthur Causeway west bridge | girder, high fixed span | Long viaduct on piers; high span at the west end over the Intracoastal |
| MacArthur Causeway east bridge | girder, low | To Miami Beach at 5th St |
| Venetian Causeway | girder / movable | Twelve low spans between islands, two bascules, ball-topped balustrades; split into 2–3 rows by island gap |
| Port Boulevard Bridge | girder, high fixed | Colour LED at night; old low bascule beside it carries the rail spur |
| **Brickell Avenue Bridge** | movable (bascule) | Bespoke builder: bronze Tequesta Family on a tall column at the south-east corner, bronze relief panels on the piers, bridge-tender houses |
| Miami Avenue Bridge | movable | Twin-leaf bascule |
| SW 2nd Avenue Bridge | movable | |
| SW 1st Street Bridge | movable | Status in MI-0.3 |
| Flagler Street Bridge | movable | |
| Brickell Key Bridge | girder | Low, short |
| Rickenbacker / William Powell Bridge | girder, high | Far row, long concrete arc |
| Julia Tuttle Causeway | girder | Far row |

Selection: bridge cap 8 on Ultra. Centre A ranks Port, MacArthur west, Venetian; centre B ranks Brickell
Avenue, Miami Avenue, SW 2nd, Brickell Key, Port. Tests: `bridge_specs_test`, `bridge_param_test`,
`bridge_select_test`, pinned selection in `miami_landmarks_test`.

**MI-5B Elevated guideways.** The most Miami street-level structure, and the one the engine draws worst.

- In `rail_builder.gd` the viaduct fit is `{"deck": deck, "side": "deck_brick"}`. Add a look selector
  (own small class, `rail_viaduct_look.gd`) returning `brick` (today's default) or `concrete_guideway`
  by zone and rail class: Miami zone with `subway`, `light_rail` or `monorail` on a bridge.
- `concrete_guideway`: slim concrete box girder per track (twin for Metrorail, single or twin for
  Metromover from the mapped track count), single round or hammerhead piers every ~25–30 m, no arches, no
  ballast on Metromover (flat running slab with a centre guide beam), low parapet. Pier spacing and girder
  depth measured from photos in MI-0.6.
- Stations: where OSM maps `railway=station` / `public_transport=platform` on the viaduct, a platform slab
  with a simple canopy; Metromover stations are short (two-car) with a barrel or flat canopy.
- Keep the mechanism general so Singapore's MRT can adopt it later with one row (decision 5).
- Tests: extend `rail_viaduct_test` with a Miami case (concrete material, pier count from length, no
  `deck_brick` surface) and prove London's result is unchanged.

**MI-5C I-395 Signature Bridge.** Six arches fanning from one base ("the Fountain"). Build only the arches
standing per MI-0.3, as a bespoke builder with `clear_path_m` along I-395, tubular arch ribs and cable
fans. If none are complete, record it and skip.

### Phase 6: city fabric

Files: `scripts/generation/city_styles.gd`, a new `scripts/generation/architecture_cities_florida.gd`
(wired into the `BASE` and `REGIONS` merges in `architecture_data.gd`; `architecture_cities_new_world.gd`
is at 501 lines and twelve rows would crowd it), `building_era.gd`, `tower_looks.gd`,
`facade_patterns.gd`, `roof_clutter.gd`, `docs/architecture-styles.md`, `tests/architecture_test.gd`.

- **MI-6.1 Zone, cores, districts.** `ZONES` rows `["miami", "miami", lat, lon, radius_km]`: mainland core
  (25.775, −80.200, ~9), Miami Beach strip as two or three circles (South Beach, Mid-Beach, North Beach),
  Coral Gables, Key Biscayne. Order them so no circle swallows another city. `CORES["miami"]`: Downtown and
  Brickell. `DISTRICTS` (~28 circles, each `[city, era, lat, lon, radius_km, weight multiplier]`). District circles
  are soft: they only scale an era's weight in the last-resort seeded pick. So, as San Francisco's rule
  does, `miami_rule` must itself read the most local circle a building stands in, or Ocean Drive will not
  reliably turn Deco. Circles: Downtown, Park
  West / Worldcenter, Edgewater, Omni, Brickell, Brickell Key, south Brickell, Overtown, Wynwood, Midtown,
  Design District, Little Havana, Little Haiti, Allapattah, Health District, Upper East Side (MiMo),
  Coconut Grove centre, Grove residential, Coral Gables centre, Gables residential, South of Fifth, Deco
  District, Flamingo Park, Collins canyon, Mid-Beach, North Beach (MiMo), bay islands, Key Biscayne,
  PortMiami. Also add `"miami": "north_america"` to `REGION_FLEET`.
- **MI-6.2 `miami_rule` and rows.** A `"miami"` case in `building_era.gd` `match city` calling
  `ArchitectureCitiesFlorida.miami_rule(kind, c)` (pattern `tokyo_rule`): type from district + levels +
  `start_date` + footprint. New `REGIONS` rows, each with `BASE` link to `miami`:

  | Row | Where it applies | Look |
  | --- | --- | --- |
  | `mi_deco` | Deco District, Flamingo Park, ≤ 4 storeys, pre-1945 | Pastel stucco, eyebrows, stepped parapet, vertical fin, corner windows, flat roof |
  | `mi_mimo` | North Beach, Upper East Side, 1945–1970 | Cheese-hole screens, boomerang canopies, catwalk motels, delta-wing porte-cochère |
  | `mi_med_revival` | Coral Gables, Española Way, parts of the Grove | Stucco, barrel clay tile, arcades, wrought iron |
  | `mi_condo_tower` | ≥ 15 storeys residential near water | Glass with continuous white balcony slabs, parking podium with pool deck |
  | `mi_condo_slab` | 8–20 storeys, 1955–1985 | White slab with catwalks and breeze-block screens |
  | `mi_office_glass` | Cores, commercial ≥ 10 storeys | Blue-green or bronze curtain wall |
  | `mi_warehouse` | Wynwood, Allapattah | One-storey concrete block, roll-up doors, flat roof |
  | `mi_strip` | Arterial commercial, 1 storey | Strip mall with parking in front, pylon sign |
  | `mi_ranch` | Residential houses, 1 storey | Concrete-block house, white flat or low tile roof, carport |
  | `mi_bungalow` | Little Havana, older Grove | Small porch-front houses, some coral rock |
  | `mi_mansion` | Bay islands, Gables waterfront | Two-storey villa, tile or flat roof, pool and dock |
  | `mi_garage` | Podiums and stand-alone garages | Open concrete decks with screens |

  Palettes: `SOBE_PASTEL` (pink, mint, lemon, aqua, peach, white trim), `GABLES_STUCCO` (cream, ochre,
  salmon), `CONDO_WHITE`, `CBS_LOWRISE`. `architecture_test` pins one case per row and per district.
- **MI-6.3 `MiamiNotable`.** `scripts/data/miami_notable.gd`, copied from `HelsinkiNotable` (values fill
  only what the map leaves out; applied in `osm_parser.gd` beside the Helsinki call, gated on the Miami
  zone). About 120 rows: the Ocean Drive and Collins fronts, Lincoln Road, Washington Avenue, downtown
  heritage, Calle Ocho, Coral Gables centre, the Design District. `tests/miami_notable_test.gd`.
- **MI-6.4 Lot dressing.** First capture a bay-island lot and a Brickell podium and record what draws.
  Then, only where missing: pools from `leisure=swimming_pool` with the `pool_water` look and a pale deck
  rim (backyards, hotel decks, podium roofs); private docks with a boat on canal and bay lots (reuse
  `MarinaBuilder` pieces, capped per view); hedges and lawns; open-deck parking podiums under condo towers
  (`mi_garage` as the lower storeys of `mi_condo_tower`).
- **MI-6.5 Wynwood, Little Havana, Design District.** A mural facade key for `mi_warehouse` inside the
  Wynwood circle (procedural bold-colour panels and shapes; no copies of real works) and a small Wynwood
  Walls row. Calle Ocho: low fronts with awnings and painted signs; Tower Theater (Deco fin), Domino Park,
  the Bay of Pigs eternal flame as small rows. Design District: Museum Garage (collage facade), Palm Court
  with the Fly's Eye Dome. **loanDepot park** (white retractable-roof ballpark with a sliding glass wall):
  full bespoke row, `skyline_priority` so it shows from Brickell.
- **Roofs:** white cool roofs on flat commercial, orange barrel tile on Mediterranean, pool decks and
  mechanical screens on towers through `RoofClutter`.

Validation: `architecture_test`, `facade_relief_test`, `roof_clutter_test`, `party_walls_test`,
`building_terraces_test`; captures on Ocean Drive, in Brickell, Wynwood, Little Havana and on a bay island.

### Phase 7: palms, sand, water, sky

- **MI-7.1 Trees** (`tree_species.gd`, zone hook in `heritage_zones.gd` as `nyc_park` and `khmer` use
  `tree_mix`). Add a `"miami"` mix selected by zone so it no longer depends on the climate fetch, with
  street / park / shore settings. New `SPECIES` rows:

  | Species | Generator | Shape |
  | --- | --- | --- |
  | `royal_palm` | `palm` | 20 m straight grey column, green crownshaft, 15 long fronds; boulevards and Gables avenues |
  | `coconut_palm` | `palm` | 14 m leaning curved trunk, drooping fronds; beaches and waterfront |
  | `sabal_palm` | `palm` | 9 m, round fan crown, boot-jacked trunk; parks |
  | `live_oak` | `broad` | 12 m, very wide low crown; Grove and Gables streets |
  | `banyan` | `broad` | 16 m, huge crown with several aerial-root trunks (needs a small generator option) |
  | `royal_poinciana` | `broad` | Flat umbrella crown; red bloom tint in early summer |
  | `sea_grape` | `broad` | 4 m shrub-tree for dunes |
  | `mangrove` | `broad` | 5 m dense fringe on unbuilt bay shores |

  `GENUS` entries: roystonea, cocos, sabal, quercus virginiana (species-level check), ficus, delonix,
  coccoloba, rhizophora, bursera. Palms in regular rows along medians (Biscayne Blvd, Ocean Drive,
  Brickell Ave); check how median trees are placed today before adding anything, and keep the change in `vegetation_builder.gd` small. Tests: `canopy_vegetation_test`, `tree_lod_test`, a Miami
  case in the species test.
- **MI-7.2 Beach** (own class `beach_dressing.gd`, keyed on `natural=beach`, not on Miami).
  1. Audit at eye C1: sand colour, slope to the waterline, foam, how wide the mapped beach draws.
  2. Sand tint: South Beach is pale grey-white; the `coast_sand_01` mean is a warm brown. Add a per-zone or
     per-climate tint through `MaterialLibrary.ground_color("sand")` without changing other places.
  3. Wet-sand band and foam line at the waterline, reusing the shore distance already in `COLOR.b`.
  4. Dune strip on the landward edge: low mound, sea oats, sea grape, rope-and-post fence, crossover paths.
  5. Lifeguard towers on OSM `emergency=lifeguard` nodes: a prop set of eight variants (different roof
     forms and colour schemes, each with ramp and flag pole), picked by a stable hash of the node id.
  6. Ultra props: hotel umbrella and lounger rows by colour per stretch, volleyball courts, the serpentine
     promenade wall along Lummus Park.
  7. `tests/beach_test.gd`: props stay on sand, none in water or inside a footprint, counts capped per
     preset, deterministic for a seed.
- **MI-7.3 Water** (`scripts/generation/water_surface.gd` `sea_palette`, beside the NYC / London / Baltic
  boxes). Boxes: Biscayne Bay (shallow turquoise-green over sand and seagrass), the dredged ship channel
  and Government Cut (darker blue-green), Atlantic side (clear aqua nearshore to deep blue), Miami River
  (green-brown; check how river colour is chosen, it may not use `sea_palette`). Pin the palette for the
  Miami box so it does not depend on climate data. Tests: `coastal_water_test`, `far_water_palette_test`
  (the far rings must use the same palette or a seam shows).
- **MI-7.4 Boats.** Marinas (Miamarina, Miami Beach Marina, Dinner Key, Sunset Harbour, Island Gardens)
  through `MarinaBuilder`: mostly motor yachts and sportfishers rather than sailboats, except Dinner Key.
  Check `VesselPrototypes` for a sportfisher and a large motor yacht; add at most two prototypes. Small
  freighters along the upper river via `CargoBerths` if the quays qualify. Moving boats only if
  `HarbourTraffic` already supports generic routes; otherwise leave out.
- **MI-7.5 Terrain, sky, clock.** Miami is flat (0–4 m): check for false relief, that seawalls sit at the
  bay edge (`shore_apron.gd`), and that `--looks` heights over the bay are sane. Sky: bright haze over
  water, tall afternoon cumulus, strong sun glint; use existing weather codes before touching
  `atmosphere_rig.gd`. Clock: confirm captures get UTC−4 in summer (the capture tool's conditions path),
  and note the UTC−5 fallback in the evidence if it stays.

### Phase 8: streets and transport

- **MI-8.1 Rail vehicles.** `TrainSpecs.METRO_REGIONS` is Helsinki and Espoo only, so Metrorail viaducts
  may carry nothing or the wrong train (measured in MI-0.1). Add liveries `miami_metrorail` (silver body,
  white front, blue-green stripe), `miami_metromover` (white with blue band; two short cars; needs a
  short-car kind or `cars: 2` with a reduced length), `brightline` (white with yellow nose and band,
  `intercity` kind) and `tri_rail`. Extend `metro()` / `pick()` so the Miami region carries the metro on
  `subway` viaducts and the mover on the mover's class. Files have user WIP; add rows only.
- **MI-8.2 Road vehicles.** `REGION_FLEET["miami"] = "north_america"` (MI-6.1). Optional `TAXIS` row
  (yellow, low share). A slightly higher convertible / sports share inside the South Beach circle only if
  `SPORTS_SHARE` can be keyed by district without touching `vehicle_mover.gd`. Metrobus and Miami Beach
  trolley liveries if the bus spec table takes region rows.
- **MI-8.3 Street furniture** (`street_furniture.gd`, `street_props.gd`). US defaults already give
  cobra-head lamps and yellow centre lines. Add for the Miami zone: mast-arm signals where signals draw,
  concrete lamp poles on arterials, Ocean Drive café tables and umbrellas (shared with MI-4A), pink
  pavement tint on Lincoln Road and Ocean Drive sidewalks, bike-share docks. Each one is checked against a
  capture before it is added; nothing speculative.
- **MI-8.4 Roads.** Check that I-95, I-395 and SR 836 interchange decks draw as concrete viaducts with
  piers, that wide arterials and surface car parks read correctly, and that the causeway roads sit on fill
  at the right height over the bay. Fix only what is wrong.

Validation: `train_test`, `car_fleet_test`, `street_furniture_test`, `road_markings_test`,
`bus_stop_test`; captures at B3 (Metromover over the street) and C2.

### Phase 9: night

Half of Miami's identity is its night look. Each item below is checked in the `night` and `late` frames.

- **Neon:** Ocean Drive signs and outline tubes in their real colours, driven by `MiamiDecoFronts`
  (`lit` materials with per-row colour and energy); uplit palm trunks on Ocean Drive and Lincoln Road.
- **Colour towers:** Miami Tower wash (one colour per night, picked from a small list by date), Paramount
  crown, InterContinental figure, Kaseya screen, Port Boulevard Bridge LED, Skyviews wheel ring, Freedom
  Tower warm flood, One Thousand Museum crown, New World Center wall.
- **Fabric:** warm scattered condo windows with lit balcony edges, glowing pool decks and backyard pools,
  cruise ships fully lit (`ShipLights`), marina mast lights, causeway lamp lines reflected in the bay.
- Check the `GLOW` table and `dress()` in `landmark_lights.gd` for how a type opts in; add Miami types
  there rather than new mechanisms.

Validation: `landmark_lights_test`; night and late frames at every fixed eye; no blown-out bloom in
`stats.json` flags.

### Phase 10: outer centres and far rows

- **E, Vizcaya and Coconut Grove:** Vizcaya (Italian Renaissance villa with four corner towers and red
  tile; the **stone Barge** breakwater in the bay; tea house; formal parterres and mound): bespoke, with
  `tree_rect` for the gardens. Miami City Hall (white Pan Am Deco terminal at Dinner Key). Grove at Grand
  Bay (two twisting glass towers; `poly` ops with `k1` rotation per tier). Park Grove towers. Ermita de la
  Caridad (white conical shrine on the bay). Dinner Key sailboats.
- **F, Coral Gables:** Biltmore Hotel (Giralda tower ~96 m, terracotta roofs, the very large pool, golf
  course): bespoke, sharing the Giralda tier code with Freedom Tower through the kit. Venetian Pool
  (coral-rock lagoon, bridge, towers, `pool_water`). City Hall (curved colonnade and clock tower).
  Alhambra Water Tower. Douglas Entrance. Alhambra Towers. Miracle Mile fabric. University of Miami.
- **Key Biscayne and Virginia Key:** Cape Florida Lighthouse (white brick, black lantern), Miami Marine
  Stadium (folded concrete cantilever roof over the basin), Stiltsville (stilt houses in the bay, far row).
- **Far:** Hard Rock Stadium (four corner masts and open canopy), the Miami Freedom Park stadium per
  MI-0.3, Ancient Spanish Monastery, Opa-locka City Hall. Airport per decision 4.

### Phase 11: review rounds and wrap-up

- A capture round `miami-rN` after each phase at the fixed eyes; each landmark frame beside its reference
  (`tools/landmark_compare_sheets.py`, `tools/landmark_silhouette_scores.py`, `tools/capture_landmarks.gd`
  four-view sheets with `stats.tsv`). List mismatches in this file, fix, recapture until each model meets
  its definition of done.
- Docs: `docs/miami-landmark-sources.md`, `docs/architecture-styles.md` (new rows),
  `docs/fidelity-scorecard.md` entry, `docs/data-source-register.md` (snapshots, any new source), README
  landmark and bridge lists.
- Perf: `tools/perf_baseline.gd` at pins A and C before (after MI-0.4) and after, presets 2 and 3;
  `lod_test`, `memory_budget_test`, `impostor_test`, `landmark_ultra_lod_test`. No regression beyond noise.
  Adding `"miami"` to `CityDetail.CITIES` is out of scope unless perf has clear room; it also bumps
  `CityDetail.VERSION`.
- Windowed tests (`screenshot_test`, `world_cache_test`) once at the end, in the background.

---

## Slot budget (measured in MI-0.8)

`LandmarkRegistryMiami` sets `ULTRA_REGISTRY_LIMIT = 26` and `ULTRA_TOTAL_LIMIT = 34` on all 7 primary anchors so `LandmarkSites.select` allocates up to 26 registry extras AND all 8 bridge slots simultaneously on Ultra (18 / 6 / 60 on High), while all ~88 `MiamiTowerSpecs*` rows run on the separate 110-slot `skyline: true` channel:

| Centre | Primary (`icon: true`) | Registry extras in radius | Bridges in radius (cap 8) | Skyline rows in radius (cap 110) |
| --- | --- | --- | --- | --- |
| A Downtown (`25.7743, -80.1855`) | `freedom_tower_miami` (`78.0 m`) | `kaseya_center`, `pamm_miami`, `frost_science_miami`, `adrienne_arsht_center`, `skyviews_miami_wheel`, `bacardi_building_miami`, `miamicentral_station`, `miami_dade_cultural_center`, `i395_signature_bridge`, 4 PortMiami terminals, `brickell_city_centre_ribbon`, `brickell_avenue_bridge`, `atlantis_condominium`, `loandepot_park`, `wynwood_walls`, `tower_theater_miami`, `museum_garage_miami`, `flagler_memorial_monument` = **21 ≤ 26** | Port Blvd, MacArthur W, Venetian W, Brickell Ave, S Miami Ave, SW 2nd Ave, SW 1st St, Brickell Key = **8 ≤ 8** | **74 ≤ 110** |
| B Brickell (`25.7670, -80.1900`) | `miami_tower` (`191.0 m`) | `freedom_tower_miami`, `brickell_avenue_bridge`, `brickell_city_centre_ribbon`, `atlantis_condominium`, `skyviews_miami_wheel`, `kaseya_center`, `miamicentral_station`, `miami_dade_cultural_center`, `pamm_miami`, `frost_science_miami`, `adrienne_arsht_center`, `i395_signature_bridge`, `loandepot_park`, `tower_theater_miami`, `vizcaya_museum_gardens`, `ermita_de_la_caridad`, `portmiami_terminal_v` = **17 ≤ 26** | Brickell Ave, S Miami Ave, Brickell Key, SW 2nd Ave, SW 1st St, W Flagler, Port Blvd, Rickenbacker = **8 ≤ 8** | **75 ≤ 110** |
| C South Beach (`25.7810, -80.1300`) | `ocean_drive_breakwater_edison` (`24.0 m`) | `ocean_drive_colony_starlite`, `art_deco_welcome_center`, `casa_casuarina_versace`, `ocean_drive_carlyle_cardozo`, `old_city_hall_miami_beach`, `lincoln_road_1111`, `new_world_center_miami`, `miami_beach_convention_center`, `holocaust_memorial_miami_beach`, `south_pointe_pier_park`, `faena_forum_miami_beach`, `fontainebleau_miami_beach`, `flagler_memorial_monument`, 3 PortMiami terminals = **16 ≤ 26** | MacArthur E, Venetian E = **2 ≤ 8** | **34 ≤ 110** (19 Beach + 15 tall Downtown/Brickell skyline wall) |
| D Mid-Beach (`25.8180, -80.1220`) | `fontainebleau_miami_beach` (`110.0 m`) | `faena_forum_miami_beach`, `miami_beach_convention_center`, `holocaust_memorial_miami_beach`, `new_world_center_miami`, `lincoln_road_1111`, `flagler_memorial_monument` = **6 ≤ 26** | Julia Tuttle, Venetian E = **2 ≤ 8** | **24 ≤ 110** |
| E Vizcaya / Grove (`25.7444, -80.2105`) | `vizcaya_museum_gardens` (`21.5 m`) | `ermita_de_la_caridad`, `miami_city_hall_dinner_key`, `atlantis_condominium`, `miami_marine_stadium`, `seaquarium_golden_dome` = **5 ≤ 26** | Rickenbacker = **1 ≤ 8** | **42 ≤ 110** |
| F Coral Gables (`25.7410, -80.2790`) | `biltmore_hotel_coral_gables` (`96.0 m`) | `venetian_pool_coral_gables`, `alhambra_water_tower`, `coral_gables_city_hall`, `douglas_entrance_coral_gables`, `miami_city_hall_dinner_key` = **5 ≤ 26** | — | **6 ≤ 110** |

---

## Risks

| Risk | Sign | Response |
| --- | --- | --- |
| OSM in Miami lacks heights or parts for many towers | MI-0.2 shows < 60 % of the tower list with `height` or parts | Heights from Wikidata / CTBUH into the row; simple `shape` ops instead of `poly`; fewer priority-0 rows |
| Exoskeleton or Deco detail exceeds triangle budgets | Catalog test fails | Lower segment counts first; promote One Thousand Museum from skyline row to icon |
| Edits collide with the user's uncommitted work | `git diff` shows changes in the same hunk | Stop and ask before touching that hunk |
| Snapshot hits Overpass output caps | Missing highways or buildings at the ring edge | Re-cut with uncapped queries as the Stockholm ring was |
| Deco facade hook costs build time on every city | `build_bench` regression | Gate on the Miami zone before any per-building work |
| A reference or status source is on a blocked host | URL ends in a blocked domain | Use another source; never fetch it |
| Capture eye ends up inside a tower podium | Interior faces or cut walls in the frame | Discard, move the eye, refreeze the list |

---

## Order and size

1. **Phase 0 and 1** (trace, audit, snapshots, wiring): unblocks every test. Small code, mostly data.
2. **MI-2A, MI-2B, MI-3A, MI-3B, MI-3C, MI-5A, MI-5B**: the skyline from the bay and causeway. About
   15 builders of 200–700 lines, ~70 data rows, one generator tool, one rail look class.
3. **MI-7.1, MI-7.2, MI-4A–4C**: Miami Beach cannot read without palms and beach dressing, so those come
   first within this step.
4. **MI-2C, MI-6, MI-7.3–7.5, MI-8, MI-9**: port, fabric, water, transport, night.
5. **MI-4D, MI-10, MI-5C**: outer centres.
6. **MI-11** runs after every step.

Each step ends green and capturable, so the pass can stop after any of them.

---

## Verification

- Tests, headless and in the background:
  `tools/run_tests.sh miami landmark bridge architecture tower facade roof canopy tree water vessel train
  car_fleet street beach rail`; a single test with
  `tools/godot_bg.sh --headless --path . --script tests/<name>_test.gd`. A test also fails on any
  `SCRIPT ERROR:` line even with exit 0.
- `tools/check_class_size.sh` after every new or grown class.
- Captures, one batched background run per round and centre:
  `tools/godot_bg.sh --path . --script tools/capture_presets.gd --position 4000,4000 -- --tag=miami-rN
  --preset=3 --pin=25.7743,-80.1855 --places=miami --times=golden,noon,night,late,roofs
  --looks="lat,lon,height_m,bearing,pitch[,zoom];…"` (the same with the B and C pins). Add
  `--look_time=late` for a night set of the looks. Every frame is checked before use.
- Done means: every Tier 1 model and skyline row meets its definition of done, every listed test passes,
  the class-size check passes, and perf is within noise of the baseline.

---

## Critical files

- **New:** `scripts/data/landmark_registry_miami.gd`, `scripts/data/miami/mia_reg_*.gd`,
  `scripts/data/miami_tower_specs*.gd`, `scripts/data/miami_notable.gd`,
  `scripts/data/miami_deco_fronts.gd`, `scripts/generation/landmarks/miami/*`,
  `scripts/generation/architecture_cities_florida.gd`, `scripts/generation/deco_front.gd`,
  `scripts/generation/beach_dressing.gd`, `scripts/generation/rail_viaduct_look.gd`,
  `tools/miami_tower_rows.py`, `tests/miami_landmarks_test.gd`, `tests/miami_tower_specs_test.gd`,
  `tests/miami_skyscraper_sites_test.gd`, `tests/miami_notable_test.gd`,
  `tests/miami_deco_fronts_test.gd`, `tests/beach_test.gd`, `docs/miami-landmark-sources.md`,
  `assets/osm_snapshots/miami_*.osmb`, `assets/osm_snapshots/miami_beach_*.osmb`.
- **Edited, clean in git today:** `scripts/data/landmark_registries.gd`,
  `scripts/data/bridges/bridge_specs_north_america.gd`, `scripts/generation/architecture_data.gd`,
  `scripts/generation/tower_looks.gd`, `scripts/generation/tree_species.gd`,
  `scripts/data/heritage_zones.gd`, `scripts/generation/water_surface.gd`,
  `scripts/generation/rail_builder.gd`, `scripts/generation/vehicles/car_fleet.gd`,
  `scripts/render/landmark_lights.gd`, `scripts/generation/street_furniture.gd`
  (re-check with `git status` before each edit).
- **Edited, carrying the user's uncommitted work (rows only, own hunks only):**
  `scripts/generation/city_styles.gd`, `scripts/generation/building_era.gd`,
  `scripts/data/preset_views.gd`, `scripts/data/bundled_osm.gd`, `assets/osm_snapshots/README.md`,
  `scripts/data/osm_parser.gd`, `scripts/generation/vehicles/train_specs.gd`,
  `scripts/generation/quay_moorings.gd`, `scripts/generation/marina_builder.gd`,
  `scripts/generation/large_ships.gd`, `scripts/generation/ground_material.gd`,
  `scripts/generation/road_builder.gd`, `scripts/generation/vessel_prototypes.gd`.

---

## Evidence

One line per finished task: date, what was checked, where the proof is (test name, capture folder, sheet).

- **MI-0.1** (2026-11-23): Ran headless engine trace at Pin A (`25.7743, -80.1855`) and Pin C (`25.7810, -80.1300`): `DETAILED_EXTENT_M = 2400.0`, `zone_at = []`, `region_at = ""`, `country_region_for("US") = "north_america"`, `biome_for_data` = `"mediterranean"` without climate (`plane` 0.55, `stone_pine` 0.15) vs `"tropical"` with `t_cold_c=20.1`, `sea_palette` `shallow=(0.025,0.149,0.150)` cold vs `(0.020,0.185,0.190)` warm, `CarFleet.profile("US") = north_america`, `TrainSpecs.pick` = `{}` on `subway`/`monorail` viaducts, `RailBuilder` viaduct side = `deck_brick`, UTC fallback = `-5.0`.
- **MI-0.2** (2026-11-23): Audited 2.5 km discs around Centres A–F from BBBike `Miami.osm.pbf` (`2026-11-21T00:00:00Z`, 163,368 buildings, 996 parts; height tag coverage 72.2% Downtown, 83.7% Brickell, 44.6% South Beach, 95.3% Grove, 96.3% Gables; Metromover = `railway=monorail`, Metrorail = `railway=subway`; 5 `emergency=lifeguard` nodes); saved `visual-plan/audits/miami-osm-audit.tsv`.
- **MI-0.3** (2026-11-23): Verified November 2026 status with dated non-Russian sources for all 25 construction/demolition items (Mandarin Oriental imploded Apr 12, 2026 → `skip`; Five Park Canopy Bridge unbuilt in litigation Oct 2026 → `skip`; I-395 Signature Bridge 4 of 6 arches standing → `build-partial`; Cipriani 289.6 m, Aston Martin 249.0 m, 830 Brickell 220.7 m, Aria Reserve pair 197.8 m, St. Regis 192 m, Soto Courthouse 144.5 m, MSC Terminal AA, Nu Stadium completed → `build`; Waldorf Astoria 285 m & Okan 262 m & Baccarat 225 m → `build-partial`); recorded in `docs/miami-landmark-sources.md` §1.
- **MI-0.4** (2026-11-23): Added `miami` and `miami_beach` presets to `PresetViews.ROWS`, `PlaceCard.SKY_FOR`, and `LocationData.known_places()`; generated and packed all 14 `.osmb` layers (`detailed_extract`, `ring1600`, `ring2500` uncapped to 5000 highways, `poi`, `far`, `transit`, `horizon`) from Geofabrik `florida-latest.osm.pbf` (`2026-11-22T21:20:48Z`, 703 KB total); `preset_views_test`, `bundled_osm_test`, `transit_layer_test`, `host_policy_test` PASS.
- **MI-0.5** (2026-11-23): Captured `visual-plan/reviews/miami-r0-2026-11-23/` (`miami` + `miami_beach` golden/noon/night/late/roofs + all 18 fixed eyes, every frame inspected open-space) and pre-Miami perf baseline `visual-plan/reviews/miami-perf-before-2026-11-23/` (`p2 miami`: build 7.29 s, settle p95 8.7 ms, 881 meshes; `p3 miami`: build 7.95 s, settle p95 9.0 ms, 1272 meshes; `p3 miami_beach`: build 5.23 s, settle p95 9.5 ms, 1351 meshes); also reclassified USACE `deep_draft` `waterway=canal` bay shipping lines as `fairway` in `osm_tags.gd`.
- **MI-0.6** (2026-11-23): Fetched 18 CC/PD city views in `visual-plan/refs/miami/` and 3–4 CC/PD views across all 56 Miami landmark folders in `visual-plan/refs/landmarks/<type>/` via `tools/miami_commons_refs.py` (`README.md` tracked, zero `<3` folders, `host_policy_test` PASS).
- **MI-0.7** (2026-11-23): Authored `docs/miami-landmark-sources.md` with measured OSM IDs, centroids, `yaw_deg`, footprint envelopes, sourced heights, and late-2026 decisions for 45 Tier 1 icons, 73+ Tier 1S skyline towers, and 13 Miami bridges.
- **MI-0.8** (2026-11-23): Rewrote measured slot plan per centre A–F in `PLAN_Miami_super_realistic.md` (`ULTRA_REGISTRY_LIMIT = 26`, `ULTRA_TOTAL_LIMIT = 34`, max 21/26 icons, 8/8 bridges, 75/110 skyline towers).
- **MI-1** (2026-11-23): Wired `LandmarkRegistryMiami`, `scripts/data/miami/mia_reg_*.gd`, `MiamiTowerSpecs*`, `LandmarkMiKit`, `LandmarkSetMiami`, `LandmarkRegistries`, `tools/miami_tower_rows.py`, and `tests/miami_{landmarks,tower_specs,skyscraper_sites}_test.gd` — all 3 tests + `check_class_size.sh` PASS.
- **MI-3C** (2026-11-23): Added `"miami"` glazing roll to `TowerLooks`, `"balcony_band"` procedural condo facade to `FacadePatterns`/`FacadeComposer`, `"balcony_white"`/`"balcony_aqua"`/`"travertine_pier"`/`"coral_stucco"` finishes to `SkyKit`, and `tests/tower_looks_test.gd` — `tower_looks_test` & `nyc_tower_looks_test` PASS.
- **MI-2A/2B/2C, MI-4A..4D, MI-5C, MI-6.5, MI-10** (2026-11-23): Authored and wired all 51 bespoke Miami landmarks (`scripts/generation/landmarks/miami/landmark_mi_*.gd`, `LandmarkSetMiami`, `scripts/data/miami/mia_reg_*.gd`) including Downtown/Bayfront (10), Brickell & neighbourhood icons (6), PortMiami terminals (4), South Beach & Ocean Drive (11), Mid-Beach (3), Vizcaya/Coconut Grove/Coral Gables (8), and I-395 Signature Bridge (4 standing arches, 100.6 m) + Key Biscayne & Far (9); `miami_landmarks_test` PASS (51 icons, 13 bridges, Centres A–F selection), zero Miami failures in `landmark_catalog_test`, 51 studio sheets captured in `visual-plan/captures/miami_r1/` + 15 night sheets in `miami_r1_night/`.
- **MI-3A/3B, MI-4B/4C/4D skyline** (2026-11-23): Populated 114 `MiamiTowerSpecs*` rows across Downtown (30), Edgewater (15), Brickell (43), Miami Beach (20), and Far (6); `miami_tower_specs_test` (114/114 PASS) and `miami_skyscraper_sites_test` (114/114 PASS).
- **MI-5A/5B** (2026-11-23): Added 13 `br_miami_*` rows in `BridgeSpecsNorthAmerica` + bespoke `LandmarkMiBrickellBridge` (`bridge_specs_test` PASS: 358/358); added concrete guideways, hammerhead piers, monorail beam, and elevated stations in `RailViaductLook` (`rail_viaduct_test` PASS).
- **MI-4A Deco, MI-6.1..6.4** (2026-11-23): Added `ArchitectureCitiesFlorida` (12 rows + `miami_rule`), `miami` zone & 28 districts in `CityStyles`, `"miami"` in `ArchitectureStyle.MAPPED_FINISH_CITIES`, `MiamiDecoFronts` (37 rows) + `DecoFront` 3D relief (`miami_deco_fronts_test` PASS), `MiamiNotable` (129 rows wired in `OsmParser`, `miami_notable_test` PASS), and Miami `RoofClutter`; `architecture_test`, `facade_relief_test`, `roof_clutter_test` PASS.
- **MI-7.1..7.5** (2026-11-23): Added 8 Miami tree species & `"miami"` mix (`TreeSpecies`/`TreeGenerators`/`HeritageZones`, `canopy_vegetation_test` & `tree_lod_test` PASS), `BeachDressing` (pale sand, dune strip, 8 lifeguard towers, resort umbrellas, Lummus wall, `beach_test` PASS), Biscayne/Atlantic/Government Cut/Miami River palettes (`WaterSurface`, `far_water_palette_test` & `coastal_water_test` PASS), and PortMiami cruise berths & Miami/Dinner Key boat fleets (`QuayMoorings`/`MarinaBuilder`/`HarbourVesselData`, `vessel_models_test` PASS).
- **MI-8/MI-9** (2026-11-23): Added `mover` kind & `miami_metrorail`/`miami_metromover`/`brightline`/`tri_rail` liveries (`TrainSpecs`, `train_test` PASS), Miami fleet/taxis/sports share (`CarFleet`), Miami signals/drums/bikeshare (`StreetFurniture`), and cyan `miami_tower` glow (`LandmarkLights`, `landmark_lights_test` PASS).
- **MI-11** (2026-11-23): Captured `visual-plan/reviews/miami-r1-2026-11-23/` & `miami-r1-night-2026-11-23/` (20 eyes across Centres A–F, `stats.json` 0 flags), baked `assets/preset_thumbs/miami.jpg` & `miami_beach.jpg`, recorded post-Miami perf baseline `visual-plan/reviews/miami-perf-after-2026-11-23/` (`p2 miami` cold 16.42 s / cached 1.15 s / settle p95 9.3 ms; `p2 miami_beach` cold 10.99 s / cached 0.97 s / settle p95 9.4 ms; `p3 miami` cold 22.91 s / settle p95 10.3 ms; `p3 miami_beach` cold 32.37 s / settle p95 9.8 ms), updated `docs/architecture-styles.md`, `docs/data-source-register.md`, and `docs/fidelity-scorecard.md`; `check_class_size.sh` PASS (max 996/1000).
