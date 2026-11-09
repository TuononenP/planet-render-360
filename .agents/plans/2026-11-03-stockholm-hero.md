# Stockholm hero pass: tracker

> Plan written 2026-11-03 to make Stockholm one of the most realistic cities, in the shape of the SF pass
> (`2026-11-03-san-francisco-hero.md`).
>
> **Shared generic work** lives in `2026-11-03-shared-city-realism.md` (Track G), which these tasks depend on:
> - G-2: district-aware era rules
> - G-3: overhead wires and span lamps
> - G-4: Baltic water colour
> - G-5: copper and sheet-metal roofs
> - G-6: granite quays and boats along quays
> - G-7: lamp and furniture kits, placed around the eye
>
> **Rules**
> - Claim a task (`— @<agent>/<topic> <date>`); tick it only when its validation passes; add one evidence line.
> - Data-driven only. Generic fixes first. Tier-gated layers.
> - `BUILD_VERSION` bump per visual change. Classes ≤ 1000 lines.
> - Godot headless and in the background; windowed runs via `tools/godot_bg.sh --position 4000,4000`.
> - Back up the diff to the scratchpad (other sessions edit this tree). Delete scratch repo copies after use (the
>   disk filled once).
> - Commit only when asked.

## Context

The preset stays on Monteliusvägen (`scripts/data/preset_views.gd:73-77`: eye 6 m, `asl_m` 32, bearing 10°, pitch −9°;
City Hall at 335°, Riddarholmen at 28°, Gamla stan at 46°).

Ratings in `docs/fidelity-scorecard.md` §9 (:251, :278): recognisable. Tells: "Gamla stan reads as low generic blocks;
foreground waterfront blocks sit in the frame".

The audit of 2026-11-03 (latest capture `visual-plan/reviews/ultra-p8j-2026-11-03/stockholm_vantage.jpg`) found:

**Era assignment bug**
- Only two rows exist (`stockholm`, `stockholm_modern`; `architecture_cities_waterfront.gd:17-112`), and there are no
  Stockholm district circles.
- The `stockholm` rules arm (`building_era.gd:359-363`) returns "" for most buildings, so the weighted pick decides.
  Its distance band is 0–99 km.
- Result: an untagged Gamla stan block becomes a flat `stockholm_modern` slab about 24 % of the time, and a Million
  Programme block becomes old-town plaster about 76 % of the time.

**Roofs**
- `roof:material=copper` maps to terracotta (`material_library.gd:79-81`).
- `metal`, `metal_sheet` and `zinc` map to slate tiles.
- No painted standing-seam sheet metal (plåttak) exists, though it is the dominant Stockholm roof.

**Fabric with no row**
- Gamla stan narrow gabled plots (the step, neck and bell `gable` keys exist, used by Amsterdam, Edinburgh, Brussels).
- Södermalm wooden cottages.
- Östermalm and Strandvägen stone blocks with towers and copper domes (`roof_domes.gd` exists but no `rv` key reaches
  it).
- Swedish Grace, funkis lamellas, the Million Programme, Hammarby Sjöstad.

**The vantage frame**
- Riddarholmen reads as green patches.
- Three Söder Mälarstrand lamellas sit in the foreground; the real cliff hides them.
- Palette flagged as too saturated against the refs (`vantage-r4-2026-11-01/README.md:80`).
- Never re-captured after the shared apron, ground-ceiling and landmark-glass changes.

**Water**
- One turquoise sea.
- Quays are limestone (`quay_builder.gd`) with no bollards.
- Nothing moors along quays: `MarinaBuilder` uses piers only, so no Strandvägen steamboats, Riddarholmen hotel ships
  or houseboats.
- af Chapman is an extruded box.

**Bridges**
- `BridgeArches` puts masonry arches every 32 m on any deck over ≥ 45 m of water, including the Västerbron steel arches
  and Centralbron.

**Landmarks**
- 11 in `landmark_registry_sweden_stockholm.gd` plus core City Hall and Riddarholmen. The 11 aren't pinned in
  `landmark_test`.
- Missing: Tyska kyrkan (96 m spire, in the skyline), Riddarhuset, the Wrangel and Bonde palaces, Klara and Sofia
  churches, Hötorgsskraporna, Katarinahissen, Gröna Lund, Kastellet, Nationalmuseum, the Royal Opera, Grand Hôtel,
  Söder Torn, Västerbron.

**Streets**
- Generic `modern` lamps and the `europe` furniture kit.
- No span-wire lamps, no Gamla stan bracket lanterns, no setts.
- Spårväg City and the Djurgården line have rails but no catenary.

**Refs**
- Only 2 photos, both from the vantage (01 winter with snow, 02 overcast summer).
- No `PlaceCard.SKY_FOR` entry.

## Tasks

### B-1: Refs and baseline
- [x] Add 3 Commons CC/PD photos to `visual-plan/refs/stockholm/` (README rows): summer clear from the vantage (make it
      `01_`), a Gamla stan street (Västerlånggatan), Strandvägen with steamboats.
- [x] `PlaceCard.SKY_FOR["Stockholm"]`; pin it in `preset_views_test`. — Existing sky value pinned; headless test passed.
- [x] Baseline `sto-r1` (Ultra, golden hour; `--audit`; plus `--season=winter` against the snow ref) and a review
      README. Fill in the findings table. — `visual-plan/reviews/sto-r1-2026-11-03/` (+ winter); post-fabric, not a
      clean baseline. Findings table below filled from sto-r4.

### B-2: Stockholm fabric (needs G-2) — @codex/stockholm-fabric 2026-11-03
Done 2026-11-08: `architecture_test` passes (66 regions); skyline reads as Stockholm in sto-r4 (recognisable).
- [x] Stockholm arm in `BuildingEra._rules`, reading districts and year; storey bands on the eras. The weighted
      fallback must not put slabs in old districts. — `building_era.gd:104` onward.
- [x] Rows in `architecture_cities_waterfront.gd`, split into `architecture_cities_stockholm.gd` if it nears 1000 lines:
  - `stockholm_medieval`: Gamla stan and Riddarholmen narrow plots, steep pitch, step and bell `gable`, ochre, rust and
    yellow plaster, sheet-metal or copper roofs.
  - `stockholm_wood`: Mariaberget and Vita Bergen cottages, falu red and ochre timber.
  - `stockholm_stone`: Östermalm and Strandvägen stone ground floor, oriels, corner towers and copper domes. Add a new
    `rv` key `corner_dome` routed to `roof_domes.gd`.
  - `stockholm_grace`: 1920s classicism.
  - `stockholm_funkis`: Fredhäll and Söder Mälarstrand white and pale lamellas.
  - `stockholm_miljon`: Skärholmen, Tensta, Rinkeby slabs, precast `panel`.
  - `stockholm_eco`: Hammarby Sjöstad and Norra Djurgårdsstaden white render, timber and glass, big balconies.
- [x] Districts in `city_styles.gd` for each row. Pin cases in `architecture_test`. — `city_styles.gd:229`.
- [x] Tone the `STOCKHOLM_PLASTER` palette toward the refs.
- [x] Use G-5 sheet metal as the pitched-roof default (black, grey, falu red), copper on civic buildings and towers.
      — `roof_metals_test` passes.

### B-3: The vantage frame
- [x] Riddarholmen: find why it reads as green patches (land class, quay apron or missing buildings) and fix that
      generically. — Patches are gone in sto-r4 (buildings and the church spire read); the mapped paving evidence
      change fixed the shoreline class. The island bank is still pale and angular (see B-8).
- [ ] Foreground lamellas: restore the Mariaberget cliff lip (DEM smoothing at `asl_m` sites), or step the eye to the
      cliff edge with `--looks`. Update the `PresetViews` row comment with the OSM check. — Open. The lamellas no
      longer dominate, but the foreground is now the mapped road and grass instead of a cliff edge. On-path trial eyes
      (sto-r2, sto-r3) lose City Hall or leave the mapped footway. Needs a terrain/eye check; preset unchanged.

### B-4: Water, quays, boats (needs G-4, G-6) — @codex/stockholm-waterfront 2026-11-03
- [x] Baltic water colour from the G-4 table. — `WaterSurface.baltic` (`water_surface.gd:384`).
- [x] Granite quays with bollards and mooring rings (`QuayBuilder` stone from `KerbBuilder.stone_for`).
      — `quay_moorings_test` passes (bollards, wet side, tier and draw budget).
- [x] Boats moored along quays: Strandvägen steamboats, Riddarholmen hotel ships, Söder Mälarstrand houseboats.
      — Shared quay-mooring builder; a moored ship shows at Riddarholmen in sto-r4. The named Strandvägen and
      Söder Mälarstrand locations were not checked up close.
- [x] af Chapman and other `building=ship|boat` drawn as a ship mesh. — `ship_builder_test` passes.

### B-5: Bridges — @codex/stockholm-bridge 2026-11-03
- [x] Per-bridge structure in `BridgeArches`: steel arch, girder or masonry, from `bridge:structure` or a small
      registry. Only masonry gets the 32 m stone arches. — `bridge_arches_test` passes.
- [x] Västerbron landmark (twin ~204 m steel arches). — Registered and modelled; `landmark_test` passes.

### B-6: Landmarks
Run as one background agent batch in a scratch copy, deleted afterwards (memory `landmark-agent-batch-workflow`).
- [x] Tyska kyrkan, Riddarhuset, the Wrangel and Bonde palaces, Klara and Sofia churches, Hötorgsskraporna,
      Katarinahissen, Gröna Lund, Kastellet, Nationalmuseum, the Royal Opera, Grand Hôtel, Söder Torn.
      — `landmark_catalog_test` (504 entries), `landmark_test`, `landmark_fidelity_test` pass.
- [x] Pin the existing 11 Stockholm entries and the preset pin in `tests/landmark_test.gd`.

### B-7: Streets (needs G-3, G-7) — @codex/stockholm-streets 2026-11-03
- [x] Span-wire lamps over Stockholm streets; wall-bracket lanterns in the medieval district. — `street_lights_test`,
      `facade_relief_test` pass.
- [x] Granite setts on Gamla stan streets: a `sett` finish default for untagged roads in the medieval district.
- [x] Catenary on Spårväg City and the Djurgården line (`electrified=contact_line`). — Wire budget 4/12 on Ultra.
- [x] Nordic furniture kit (SL stops, bins). — `street_furniture_test` passes (`nordic_se` kit).

### B-8: Hero loop
- [x] Capture rounds `sto-rN` against the refs (summer, plus a winter round against the snow photo). — sto-r1 to
      sto-r4 (winter for r1 and r3).
- [x] Review README and scorecard §9 line per round. — READMEs per round; scorecard rounds r1 to r4.
- [ ] Target: photographic on Ultra. — Open. Agent pre-rating is still recognisable, and the human gate is pending.
      Remaining gaps: the pale angular island bank, the road and grass foreground (B-3), and an isolated cold time
      to view (206 s under load vs the 150 s target; the build graph itself took 58 s).

## Critical files

- **Rows, eras and districts:** `scripts/generation/architecture_cities_waterfront.gd` (or a new
  `architecture_cities_stockholm.gd`), `building_era.gd`, `city_styles.gd`.
- **Relief:** `facade_relief.gd`, `street_front.gd`, `building_detail.gd`, `roof_domes.gd`.
- **Roofs:** `material_library.gd`.
- **Water and bridges:** `quay_builder.gd`, `marina_builder.gd`, `bridge_arches.gd`, `water_shader.gd`.
- **Streets:** `street_props.gd`, `street_furniture.gd`, `road_builder.gd`.
- **Data:** `scripts/data/preset_views.gd`, `scripts/data/landmark_registry_sweden_stockholm.gd`.
- **Screens and docs:** `scripts/screens/place_card.gd`, `docs/architecture-styles.md`, `docs/fidelity-scorecard.md`.
- **New builders:** `scripts/generation/landmarks/sweden_stockholm/*`.

**Reuse**
- `StreetFront._gable` (step, neck, bell) and `roof_domes.gd`.
- The SF district cue and arm in `building_era.gd`.
- `MarinaBuilder` placement and meshes.
- `ParkedCars.front_faces` (winding, memory `mesh-helper-winding`).
- `capture_presets.gd` `--looks` / `--season` / `--audit`; `capture_landmarks.gd`.

## Verification

- **Per task:** headless in the background, plus `tools/check_class_size.sh` and `--import` after a new `class_name`.
  - Tests: `architecture_test`, `osm_test`, `preset_views_test`, `landmark_catalog_test`, `landmark_test`,
    `landmark_fidelity_test`, `scenery_test`, `street_lights_test`, `street_furniture_test`, `rail_square_test`.
  - New tests: quay boats, bridge structure, roof metals, the Stockholm arm.
- **Per round:** windowed `capture_presets.gd --places=stockholm` through `tools/godot_bg.sh`.
  - Check `stats.json` against the refs.
  - Check `BUILD timings` (Ultra cold ≤ 150 s) and the draw-call budget for boats and wires.
- **End:** windowed `world_cache_test` + `screenshot_test`; scorecard pre-rating for the human gate; delete scratch
  copies and check free disk space.

## Findings

| Area | Reads right | Reads wrong | Proposed change |
|---|---|---|---|
| Skyline | City Hall, the Riddarholmen spire and the moored ship identify the location. | Island blocks, shore and bridge approaches are simplified and angular; the bank is pale. | Inspect the island geometry and shore at close range. |
| Vantage | The intended City Hall and island are in frame. | Road, grass and trees fill the foreground instead of a cliff edge. | Terrain/eye check on the mapped footway, then recapture. |
| Performance | Wires 4/12, marina 14/20 draw calls. | Time to view 206 s under load (target 150 s). | Isolated cold timing. |


## Work in progress — @codex/stockholm 2026-11-03

- Three Commons references downloaded and attributed; `preset_views_test` passes. The `sto-r1` summer and winter shots are documented in `visual-plan/reviews/sto-r1-2026-11-03/README.md`; they are post-fabric, pre-landmark/street/bridge captures, not a clean baseline. Winter cache save was interrupted after the shots and audit due to disk exhaustion.
- B-2: seven district fabrics and dated/style rules, subdued plaster, metal roofs and a copper corner dome implemented; architecture checks pass. Visual validation remains open.
- B-5: structure/material tags and Västerbron/Centralbron registry prevent stone arches on steel, girder and unknown decks; focused bridge test passes. Västerbron is modelled; its visual validation remains open.
- B-6: Tyska kyrkan added; existing eleven registry entries and preset extras pinned by `landmark_test`. Other requested landmarks and visual validation remain open.
- B-7: Sweden uses Ultra span wires, contact-line wires, a Nordic green-bin/SL-stop kit and Gamla stan untagged setts. Wall brackets are implemented; complete visual validation remains open.
- Disk reached less than 300 MiB free while concurrent sessions wrote caches. Only this run's cache files were removed; do not run further captures until space is available. Other B-3/B-4/B-8 work and final windowed tests remain open.

- B-5 continuation: Västerbron model and registry entry added. A focused headless probe verified three merged parts and bounds of 602 × 51.25 × 26 m; the 204 m and 168 m main spans come from the linked structural study. The full landmark test passed after registration; visual validation remains pending.
- B-7 continuation: exposed medieval street fronts receive seeded wall-bracket lanterns on Ultra; `architecture_test`, `street_lights_test`, and `facade_relief_test` passed.
- The `sto-r2` candidate-view capture built in 97 s, then was stopped before images because disk space fell below 300 MiB. It must be recaptured before reviewing the view.

- `sto-r2` completed after disk space recovered: Ultra build to view 110 s, wires 4/12 and marina 14/20 surfaces. The new mapped ship appears; the island shore remains angular and pale. OSM has 23 building ways in the island bounding box, so the source is not simply missing buildings. Trial views north of the path improve framing but are off the mapped Monteliusvägen footway; do not promote them without a terrain/eye check. See `visual-plan/reviews/sto-r2-2026-11-03/README.md`.
- B-4: shared quay mooring and mapped ship builders now exist; wall-mounted mooring rings added. `quay_moorings_test`, `ship_builder_test` and `marina_test` pass, including a fix for piers wrongly vetoing their own berths. Visual review and the named-location checks remain open.
- `sto-r3` summer and winter captures are reviewed; the island bank and foreground road remain visibly wrong, and on-path eye trials do not yet retain the full intended view. The photographic target remains open. Disk space recovered to approximately 1.9 GiB, but concurrent builds still require care.
- B-6 continuation: the requested Stockholm landmarks are modelled, including a grouped Gröna Lund skyline with approximate coaster profile; final integrated visual review remains open. Generic separated-footprint clearance keeps buildings between the rides.
- Generic shoreline inference now recognizes mapped `unhewn_cobblestone`, `bricks` and `concrete:plates` as paving; native and script evidence tests pass. `sto-r4` remains recognisable rather than photographic, and its 206 s time to view exceeds the 150 s target under concurrent load. See its review for the remaining issues.
- End-test attempt (2026-11-03): `screenshot_test` passed. `world_cache_test` failed its identical-world check: the cold visit had far-city OSM data (724 towers), while the revisit rebuilt without it (0 towers), yielding 2,617 versus 2,566 nodes.

## Status — 2026-11-08

Everything that can be verified automatically is done and ticked above. Final check on the clean tree (branch `bundle-capital-osm-snapshots`):
- Headless, all pass: `architecture_test`, `osm_test`, `preset_views_test`, `landmark_catalog_test`, `landmark_test`, `landmark_fidelity_test`, `scenery_test`, `street_lights_test`, `street_furniture_test`, `rail_square_test`, `facade_relief_test`, `quay_moorings_test`, `ship_builder_test`, `marina_test`, `bridge_arches_test`, `roof_metals_test`; `tools/check_class_size.sh` OK (largest 859/1000).
- Windowed, both pass: `world_cache_test` (cold 30.6 s, cached revisit 5.7 s, identical world) and `screenshot_test`. The 2026-11-03 `world_cache_test` failure did not recur on a quiet tree. It tests Paris, not Stockholm, so it was most likely concurrent sessions changing the far-city OSM data mid-run.

Still open (needs a human or a new capture round, not more code):
- B-3 foreground: the cliff-edge framing at Monteliusvägen.
- B-8: the "photographic" rating and the human gate. Pre-rating stays recognisable.
- An isolated cold time-to-view measurement against the 150 s target.
- Close-up checks of the named Strandvägen and Söder Mälarstrand boat locations.
