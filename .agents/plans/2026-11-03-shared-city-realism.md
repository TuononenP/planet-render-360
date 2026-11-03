# Shared city realism — tracker

> Split from `/Users/petri.tuononen/.claude/plans/san-fransisco-should-be-graceful-liskov.md`.
> 2026-11-03. No commits or pushes. Preserve concurrent work and use off-screen background Godot runs.

## Approved scope (verbatim)

## Track G: shared generic work (do first)

- **G-1 SF review leftovers.** Verify each, then fix only what is still open:
  - `RoadWidths`:
    - widen only for `sidewalk=separate`;
    - cap the kerb at a parallel cycleway, path or tree row (Helsinki verges);
    - never narrower than the lanes;
    - skip when base ≥ `MAX_M`.
  - `ParkedCars`: facing follows the traffic side; skip trees, stops and tram rails.
  - `MarineLayer`: Compatibility fallback.
  - `LandmarkSites.bridge_spans`: only `kind == "Bridge"` entries cut bridge decks.
  - `BuildingEra.cues`: normalise `-` to `_` (Woolworth's `neo-gothic`).
  - World-cache fingerprint: recurse into `scripts/generation/landmarks/**`.
  - Each gets a test case in `parked_cars_test` / `osm_test` / `marine_layer_test` / `landmark_test`.
- **G-2 District-aware rules for every city arm.** Promote the SF pattern (`c["district"]` in `BuildingEra.cues`)
  into arms for `helsinki`, `espoo`, `stockholm` and `new_york`. Districts decide before the storey band, and the
  `_banded` fallback no longer decides by storeys alone for a city that has districts.
  - Pin cases in `architecture_test`.
- **G-3 Overhead wires** (Ultra): a new `scripts/generation/overhead_wires.gd`, wired from `StreetProps.build`.
  - Contact wire over every `railway=tram|light_rail` with `electrified=contact_line`.
  - Span wires to facade anchors, or to poles every ~30 m where no building stands within 12 m.
  - Trolleybus wire pairs where mapped (also covers SF-5.2).
  - A `span` lamp family: a lamp hung mid-span over streets (FI, SE), sharing the poles and anchors.
  - Thin tubes merged per chunk, front-facing winding (memory `mesh-helper-winding`), a draw-call budget check.
  - Test: `overhead_wires_test`.
- **G-4 Water colour per water body.** Replace the hard-coded sea `shallow_c`/`deep_c` (`water_shader.gd:151-158`)
  with parameters from a small table keyed by a lat/lon box:
  - tropical turquoise as today;
  - temperate harbour/estuary grey-green (New York Harbor, Thames);
  - brackish Baltic dark green-grey (Stockholm, Helsinki).
  - Shrink the 150 m shelf ramp on urban coasts with quays (`water_surface.gd:31`).
  - Pin it in a water test.
- **G-5 Roof metals.**
  - Fix `roof:material=copper` → a verdigris copper set; currently terracotta (`material_library.gd:79-81`).
  - Add a painted standing-seam sheet-metal roof set (black, grey, falu red), with `metal`, `metal_sheet` and `zinc`
    mapped to it. The Nordic rows take it as their pitched default.
  - Also gives NYC crowns copper.
- **G-6 Quays and boats.**
  - `QuayBuilder` takes its stone from `KerbBuilder.stone_for` (granite in Europe) and adds mooring bollards.
  - `MarinaBuilder` gets a quay-side mode: steamboats and houseboats along mapped quays (`man_made=quay` or the quay
    wall) within its radius on Ultra.
  - A simple ship mesh replaces the extruded box for `building=ship|boat` (af Chapman).
- **G-7 Furniture and lamps near the eye.** Street furniture is fetched around the origin but placed by distance from
  the origin (`street_furniture.gd:71-75`, `osm_query.gd:147`); centre the placement on `View360.spawn_xz`, as
  parked cars do.
  - New lamp and furniture kits: `nordic` (green bins, HSL/SL stops) and `nyc` (Type-F / Bishop's crook lamps,
    litter baskets).


## Claims and verification

- [ ] **G-1 SF review leftovers.** — unclaimed; use the approved scope above for files and checks.
- [ ] **G-2 District-aware rules for every city arm.** — unclaimed; use the approved scope above for files and checks.
- [ ] **G-3 Overhead wires** — unclaimed; use the approved scope above for files and checks.
- [ ] **G-4 Water colour per water body.** — @codex/harbour 2026-11-03; use the approved scope above for files and checks.
- [x] **G-5 Roof metals.** — @codex/hero 2026-11-03; dedicated patina/paint sets, slope-aligned seams, Fast gating and snow/cache checks. Seven focused headless tests plus four city captures and the close-up gallery pass; evidence in `visual-plan/reviews/helsinki-espoo-roof-metals-2026-11-03/`.
- [x] **G-6 Quays and boats.** — @codex/hero 2026-11-03; regional quay stone, Ultra bollards/alongside vessels and mapped ship hulls. Seven focused tests, current-tree quay/marina checks and four seasonal city captures; evidence in `visual-plan/reviews/helsinki-espoo-harbour-2026-11-03/`.
- [ ] **G-7 Furniture and lamps near the eye.** — unclaimed; use the approved scope above for files and checks.

## Critical files (source plan)


- **New:**
  - `scripts/generation/overhead_wires.gd`
  - `scripts/generation/architecture_cities_finland.gd` (if split)
  - city refs under `visual-plan/refs/`
  - the three trackers
  - landmark builders under `scripts/generation/landmarks/{finland_helsinki,sweden_stockholm,north_america}/`
- **Modified (shared):**
  - Eras and districts: `scripts/generation/building_era.gd`, `city_styles.gd`.
  - Rows: `architecture_cities_north.gd`, `architecture_cities_waterfront.gd`, `architecture_cities_americas.gd`.
  - Relief: `street_front.gd`, `facade_relief.gd`, `building_detail.gd`.
  - Streets: `street_props.gd`, `street_furniture.gd`, `rail_builder.gd`, `road_builder.gd`, `bridge_arches.gd`.
  - Water and quays: `water_shader.gd`, `water_surface.gd`, `quay_builder.gd`, `marina_builder.gd`.
  - Roofs and far field: `material_library.gd`, `far_city_builder.gd`.
  - Ground and nature: `ground_material.gd`, `bare_earth.gd`, `tree_species.gd`, `climate_model.gd`.
  - Data: `scripts/data/{road_widths,osm_tags,osm_query,far_city_fetcher,preset_views,location_data,landmark_sites}.gd`.
  - Screens and render: `scripts/screens/{place_card,view_link}.gd`, `scripts/render/{marine_layer,world_cache}.gd`.
  - Docs: `docs/architecture-styles.md`, `docs/fidelity-scorecard.md`.
- **Reuse:**
  - Patterns: the SF district cue and arm (`building_era.gd`); `ParkedCars` / `MarinaBuilder` MultiMesh builders;
    `ParkedCars.front_faces`.
  - Relief: `StreetFront._gable` (step, neck, bell); `FacadeRelief._deep_balcony`; the `panel` pattern; `roof_domes.gd`.
  - Tools: `capture_presets.gd` `--looks` / `--season` / `--audit`; `capture_landmarks.gd`.


## Verification (source plan)


- **Per task:** headless tests run in the background, plus `tools/check_class_size.sh` and `--import` after any new
  `class_name`.
  - Existing: `architecture_test`, `osm_test`, `parked_cars_test`, `marine_layer_test`, `preset_views_test`,
    `responsive_test`, `viewer_tools_test`, `climate_test`, `bare_earth_test`, `rail_square_test`,
    `street_furniture_test`, `street_lights_test`, `scenery_test`, `landmark_catalog_test`, `landmark_test`,
    `landmark_fidelity_test`, `fidelity_scorecard_test` (note Turku (a) already fails at HEAD).
  - New tests: wires, water colour table, roof metals, quay boats, far-tower parts, layer decks, partial ice,
    March-as-winter.
- **Per city round:** a windowed capture of `--places=<id>` (Helsinki and Espoo also `--season=winter`) through
  `tools/godot_bg.sh`.
  - Check `stats.json` against the refs.
  - Check the `BUILD timings` (Ultra cold ≤ 150 s) and the draw-call budget for wires and boats.
  - Write a review README and a scorecard §9 line.
- **End of each plan:** a windowed `world_cache_test` + `screenshot_test` batch. Pre-ratings are left for the human
  gate. Delete the scratch copies and check free disk space.

## Findings

| Task | Evidence | Finding / next action |
| --- | --- | --- |
| G-1 / G-2 / G-3 / G-4 / G-7 | [Helsinki/Espoo tracker](2026-11-03-helsinki-espoo-hero.md) | Finland-related portions implemented and checked; the broader Stockholm/New York portions remain open. G-5 and G-6 have separate completed evidence above. |
