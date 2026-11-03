# Helsinki and Espoo hero pass — tracker

> Implements `/Users/petri.tuononen/.claude/plans/san-fransisco-should-be-graceful-liskov.md`.
> Started 2026-11-03. Preserve concurrent work; no commits or pushes. Initial diff:
> `/tmp/planet-helsinki-hero/before.patch`. Tick only after validation; record capture evidence.

Shared scope: [Track G](2026-11-03-shared-city-realism.md). Stockholm and New York have separate pending trackers.

## Tasks

- [x] **HE-0** Generic fixes: sidewalk measurement barriers, one-way/traffic-side parking, obstacles, marine fallback, centre lines — @codex/hero 2026-11-03
- [x] **HE-1** Helsinki preset, Espoo gazetteer, licensed summer/winter references, baseline views — @codex/hero 2026-11-03
- [x] **HE-2** Finland architecture rows, era rules, districts, Espoo zone/preset, facade relief — @codex/hero 2026-11-03
- [x] **HE-3** Overhead wires, Nordic lamps/furniture, off-road tram beds — @codex/hero 2026-11-03
- [x] **HE-4** Granite shores, canopy filtering, boreal trees/biome, Baltic water — @codex/hero 2026-11-03
- [x] **HE-5** Climate-aware March, street snow/snowbanks, partial sea ice — @codex/hero 2026-11-03
- [x] **HE-6** Helsinki and Espoo landmark batches — claimed in landmark visual-quality tracker
- [ ] **HE-7** Summer/winter capture loop, scorecard pre-ratings, cold-build/wire budgets, final windowed tests — @codex/hero 2026-11-03

HE-7 implementation, capture evidence and regression checks are complete. The photographic target is still open; current pre-ratings are recognisable.

## Findings

| Round | City / season | Evidence | Findings / next action |
| --- | --- | --- | --- |
| Audit | Both | Approved source plan | Helsinki eras ignored distance; Espoo lacked a zone; tram wires, Finnish streets and winter context absent. |
| R1 | Both / summer + winter | `visual-plan/reviews/{hki,espoo}-r1*-2026-11-03/` | Baseline before Finland architecture and environmental work. |
| R3–R4 | Both | Measured sea-side DEM samples | Terrarium sea surface was about 17 m above sea datum. Source prepass now registers consistent northern coastal DEMs before GroundTruth; raw tiles remain unchanged. |
| R6 | Both / summer + winter | `visual-plan/reviews/{hki,espoo}-r6*-2026-11-03/` | Corrected Kamppi/SkyWheel/Allas coordinates, modern low-rise inference, calmer Baltic water. |
| R8 | Both / 21 June | [Final review](../../visual-plan/reviews/helsinki-espoo-hero-2026-11-03/README.md) | Combined with concurrent canonical shoreline work. Helsinki 8/12 wire surfaces, Espoo 0/12; generation 23.242 / 15.323 s. |
| R9 | Both / 15 January | Same review | Sun 8.75° / 8.69°, snow and partial ice. Buildings and shoreline detail still read procedural; photographic target open. |

## Verification

Headless jobs use background execution sessions; logs and status files live in
`/tmp/planet-helsinki-hero/verified/`. Tests used a stable source snapshot at
`/tmp/planet-helsinki-hero/verify/` to avoid concurrent script-registration races; the snapshot and private user-data cache were deleted after verification (5.9 GiB free).
Heavy assets, texture imports and raw fetch cache are reused. Captures have a separate
user-data directory so the user’s History and preferences are untouched.
Windowed captures use `tools/godot_bg.sh --position 4000,4000` in detached jobs.

The source-plan split is complete: shared Track G, Plan A, Stockholm and New York have separate trackers. The user selected continued Helsinki/Espoo visual refinement. Stockholm/New York stay pending.

## Review gate

Photographic ratings remain a human gate. Do not mark a city photographic without captured evidence.

## Approved Plan A scope (verbatim)

## Plan A: Helsinki and Espoo

**Context.** Four Helsinki rows exist (`architecture_cities_north.gd:182-225`). With no rules arm, the storey band
decides, so every 1–4 storey building, heritage building and house in the 5 km zone becomes ochre Empire, and 5–7
storeys is always Jugend. Espoo has no zone and gets generic `nordic` (falu-red timber houses). Neither city is a
preset or has city refs. The landmarks miss Kamppi Chapel, Amos Rex, Havis Amanda/Kappeli, SkyWheel, Stockmann,
Hakaniemi hall, the Senate Square set, Otaniemi Chapel, Aalto University, Tapiola Church and central tower, and Weegee.

- **A-1 Presets and refs.**
  - Helsinki row: Market Square harbour edge (~60.1675, 24.9530), looking NE to Uspenski, the Cathedral dome and
    Esplanadi. Chosen with `--looks`.
  - Espoo row: Tapiola pool facing the central tower (~60.1757, 24.8050). It lands with A-3, because a preset's
    origin must lie in its own city zone (`architecture_test.gd:188`).
  - `SKY_FOR` entries, and "Espoo, Finland" in `known_places`.
  - `visual-plan/refs/{helsinki,espoo}/` with 3 Commons photos each, including one winter photo.
  - Baselines `hki-r1` / `espoo-r1`, summer and `--season=winter`.
- **A-2 Helsinki fabric.** New rows, in a new `architecture_cities_finland.gd` if north grows too large:
  - `helsinki_classicism` (1920s pastel render; Töölö, Vallila);
  - `helsinki_wood` (Puu-Käpylä, Puu-Vallila, `NORDIC_WOOD`);
  - `helsinki_suburb` (1950s–60s lamellas);
  - `helsinki_element` (1965–89 precast `panel`, glazed balcony stacks);
  - `helsinki_midrise` (Jätkäsaari / Kalasatama 6–8 storeys).
  - Jugend gets a granite plinth, tall roofs and turrets.
  - Districts (Katajanokka, Eira, Kallio, Punavuori → Jugend; Töölö; Käpylä; Herttoniemi; Itäkeskus, Kontula →
    element; Jätkäsaari).
  - Widen the zone to ~9 km so the eastern suburbs are covered.
  - New relief keys: `glazed_balcony`, `turret`, `granite_plinth`, `snow_guard` (documented and pinned in tests).
- **A-3 Espoo zone.**
  - Zone `espoo` (~60.19, 24.77, ~9 km; check the overlap order with Helsinki), cores at Tapiola, Leppävaara,
    Matinkylä and Espoon keskus.
  - Rows:
    - `tapiola`: white modernist slabs, point towers, terraced houses in pine;
    - `otaniemi`: red brick and copper;
    - `espoo_modern`: Leppävaara, Matinkylä and Keilaniemi towers;
    - `kauniainen`: garden villas.
  - A rules arm (G-2) and districts. The Espoo preset row.
- **A-4 Nature.**
  - Kallio: a pink-grey granite rock class with lichen; rocky shores read as rock, not sand
    (`water_builder.gd:41`); pines weighted onto rock.
  - `BareEarth` also opens canopy bumps inside forest and park polygons.
  - Boreal street mix: lime, birch, maple (a new species row), rowan; no plane or spruce.
  - Treat Nordic places within ±1 °C of the boreal thresholds as boreal (pinned in `climate_test`).
- **A-5 Winter.**
  - March counts as winter where its mean is below 0 °C (season mapping in `view_link.gd`).
  - Snow on parked cars, furniture and kerbs (`SNOW_GLSL`).
  - Ploughed snowbanks along kerbs (Ultra).
  - Partial sea ice: fast ice near shore and in bays, fading to open water; `ICE_C` becomes a soft band.
  - Check the winter golden hour (sun 8°) and the white-night twilight.
- **A-6 Streets.** Tram catenary and span lamps (G-3) on Helsinki tram streets. Paved or grass bed for tram track off
  the road ribbon (`RailBuilder`, plus `GroundMaterial.class_map`). Fix the duplicate tram bridge deck.
- **A-7 Landmarks.** Two background agent batches, each in a scratch copy deleted afterwards:
  - Helsinki: the list above;
  - Espoo: the list above, with Tapiola's central tower as the `icon`.
- **A-8 Hero loop.** Summer and winter rounds until both cities rate photographic.
- **Tracker:** `.agents/plans/2026-11-03-helsinki-espoo-hero.md`.


Final verification: 24 focused headless scripts and both off-screen windowed checks pass. Global fidelity run timed out; corrected-filter Turku rerun fails only its existing DEM check. Water-material identity filtering was corrected and regression-asserted; thresholds are unchanged. Review contains exact statuses and source hashes.

Refinement continued: SkyWheel overlap correction verified in `visual-plan/reviews/skywheel-fix-2026-11-03/`; shared roof metals G-5 are complete, replacing copper-as-clay and slate-as-sheet-metal. Seven headless tests and fresh summer/winter captures pass; evidence: `visual-plan/reviews/helsinki-espoo-roof-metals-2026-11-03/`.

Roof-metal round: Helsinki generation 32.318 / 33.860 s (summer/winter), Espoo 4.433 / 4.761 s; wires 8/12 and 0/12. Photographic target remains open. Next concrete review targets: box-like mapped ships, Uspenski foreground mass/height, Espoo pool perimeter, winter colour.

Harbour round (G-6): mapped vessel footprints now produce oriented hulls and
deckhouses; Ultra adds alongside steam/houseboat dressing and bollards, with
regional quay stone. Seven focused scripts and current-tree quay/marina checks
pass. Summer/winter generation: Helsinki 36.975 / 36.635 s, Espoo 6.994 / 7.208 s.
Marina surfaces: 13/20 and 8/20; wires: 8/12 and 12/12. These are combined-tree
captures, with concurrent source differences recorded in the
[harbour review](../../visual-plan/reviews/helsinki-espoo-harbour-2026-11-03/README.md).
No photographic pre-rating is claimed. The Old Mint's default six-storey,
20.76 m mass is too tall: the owner's restoration drawings show two floors and
a pitched sheet-metal roof. Subsequent before/after inspection identified the
main block masking Uspenski as the adjacent Enso office. Its mapped white marble
tags were lost on untagged building parts. Small marina boats, the Espoo pool
perimeter and winter tone remain refinement targets.

Mint/Enso follow-up: the Mint now has source-backed approximate dimensions and
a dark metal roof; untagged building parts inherit the Enso office's mapped
white marble. The material cache preserves distinct pale marble tints. Both
cities were re-captured in summer and winter; all wire and marina budgets pass.
The terrain probe found 14.06 m at Uspenski's centre and 10.20 m at the lowest
footprint sample above the rendered sea datum, with no surveyed foundation
elevation to justify moving it. [Review and validation](../../visual-plan/reviews/helsinki-espoo-mint-enso-2026-11-03/README.md).
The office still partially obscures the cathedral from the opening eye; the
photographic target remains open.
