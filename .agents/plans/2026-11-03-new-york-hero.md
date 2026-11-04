# New York hero pass: tracker

> Plan written 2026-11-03 to make New York one of the most realistic cities, in the shape of the SF pass
> (`2026-11-03-san-francisco-hero.md`). Realism v3 R-2.6 already targets "photographic" for New York.
>
> **Shared generic work** lives in `2026-11-03-shared-city-realism.md` (Track G), which these tasks depend on:
> - G-2: district-aware era rules
> - G-4: harbour water colour
> - G-5: copper crowns
> - G-7: furniture placed around the eye, and the NYC lamp kit
>
> **Rules**
> - Claim a task (`— @<agent>/<topic> <date>`); tick it only when its validation passes; add one evidence line.
> - Data-driven only. Generic fixes first. Tier-gated layers.
> - `BUILD_VERSION` bump per visual change. Classes ≤ 1000 lines.
> - Godot headless and in the background; windowed runs via `tools/godot_bg.sh --position 4000,4000`.
> - Back up the diff to the scratchpad (other sessions edit this tree). Delete scratch repo copies after use.
> - Commit only when asked.

## Context

The preset is Brooklyn Bridge Park Pier 1 looking at Lower Manhattan (`scripts/data/preset_views.gd:65-72`): origin
40.7060,-74.0040 (South Street Seaport), eye 40.70265,-73.99686 at 6 m, bearing 295° (reviewed 2026-11-04), pitch +3°. One WTC is in frame;
Liberty sits on the left edge.

Ratings (`docs/fidelity-scorecard.md` :250, :277): recognisable. Tells: "Water too cyan; backlit sun glare".
`ultra-p7f` `stats.json` flags close1 colourfulness at 0.103 against refs at 0.026–0.039.

The audit of 2026-11-03 found:

**Water**
- The East River is coastline, so it takes the sea branch's hard-coded tropical `shallow_c`
  (`water_shader.gd:154-158`).
- The sea shelf ramp is 150 m (`water_surface.gd:23,31`), so the whole foreground is cyan.

**Light**
- Captures run at the evening golden hour; the summer sunset sits at ~300°, straight behind the 298° look.
- The skyline is backlit and flat. Both refs are overcast.

**Far skyline**
- `far_city_fetcher.gd` (12 km, `CAP_TOWERS` 1500) fetches ways only: no relations, `building:part` or `roof:shape`.
- The cap was hit, and thinning is in id order. Missing in frame: Brookfield Place / 200–250 Vesey, 99 Hudson,
  Goldman Sachs, Brooklyn Tower.
- `far_city_builder.gd:156-184` builds flat-capped extrusions.
- The detailed extent (±1.2 km) cuts Battery Park City's west side.

**Bridges and elevated roads**
- Manhattan Bridge (`bridge=yes`, `layer` 2/3, no structure tag) reads as a low arched causeway: deck rise capped at 3 m
  (`road_builder.gd:29-37`, :378) plus `bridge_arches.gd`.
- FDR Drive (`layer=1` viaduct) sits on the ground; `layer` never becomes a deck height.
- An orange box sits at the Brooklyn Bridge's Brooklyn tower: check it.

**Fabric**
- Rows `new_york`, `nyc_brownstone`, `nyc_prewar` and `nyc_glass` (`architecture_cities_americas.gd:38-95`).
- The rules arm (`building_era.gd:364-372`) is height-only: ≥ 20 levels → glass. 77 tall buildings without
  `start_date` (Deco towers among them) go glass.
- Districts exist but the NY arm never reads them.
- `cues()` doesn't normalise `-`, so `neo-gothic` misses `neo_gothic` (Woolworth is saved only by `start_date`).
- No cast-iron, DUMBO loft, NYCHA, pencil or International Style rows; `nyc_glass` has empty relief.
- Water towers (`roof_clutter.gd:45`) also land on glass towers.
- No synthesized setbacks or copper crowns.
- `CAP_PARTS` is 2,200 against 2,003 parts in the payload: close to the limit.

**Pier 1 foreground**
- Grass tufts on the promenade paving; no pier-edge railing.
- No furniture: it is fetched and placed within ~400–450 m of the origin, not the eye (`street_furniture.gd:71-75`,
  `osm_query.gd:147`).
- Jane's Carousel and the ferry terminal are plain boxes.

**Street life**
- `ParkedCars` honours `oneway` already (`parked_cars.gd:60-61`, `facing()`), but has no yellow cabs.
- No subway entrances (`railway=subway_entrance` isn't fetched); `na` cobra lamps, no NYC poles.
- 6,563 mapped trees all collapse to the lime model (honey locust, callery pear, ginkgo, zelkova).

**Landmarks**
- In range: One WTC, Empire State, Liberty, Brooklyn Bridge, Chrysler.
- Missing as models: Manhattan Bridge, Woolworth / 40 Wall / 70 Pine / Municipal Building crowns (their OSM parts give
  the massing), Oculus (OSM says dome), Staten Island ferries.

## Tasks

### C-1: Light and refs — @codex/nyc 2026-11-03
- [x] An optional `hour` (or `light: "morning" | "overcast"`) field on `PresetViews` rows, honoured by the opening view
      and by `capture_presets.gd`. Set New York so Lower Manhattan is front-lit. Pin it in `preset_views_test`.
- [ ] Add Commons refs: golden-hour (morning) skyline from Pier 1, night skyline, a street-level FiDi or DUMBO photo.

### C-2: Water (needs G-4) — @codex/harbour 2026-11-03
- [x] Harbour/estuary grey-green from the G-4 table; a shorter shelf where the shore is a bulkhead or quay.
- [x] Re-capture and check `stats.json` colourfulness against the refs.

### C-3: Far skyline — @codex/far-city 2026-11-03
- [x] In `far_city_fetcher.gd`: include multipolygon relations, `building:part`, `roof:shape` and `roof:height`; pick
      the cap by height and nearness instead of id order, and raise it. Change the cache key so places refetch once.
- [x] In `far_city_builder.gd`: crowns, pyramids, spires and stepped setbacks from parts and roof tags. Reuse the
      detailed builder's roof-form code where possible.
- [x] Check Brookfield Place, 99 Hudson, Goldman Sachs and Brooklyn Tower in frame.

### C-4: Bridges and elevated roads — @codex/nyc 2026-11-03
- [x] Manhattan Bridge registry model: suspension, ~41 m deck, ~103 m towers, the Manhattan arch and colonnade. It
      must replace the OSM deck the way the Brooklyn Bridge does.
- [x] Generic: `bridge=yes` with `layer ≥ 1` over land becomes a deck height (~5 m per layer) on piers (FDR at South
      Street, BQE). `BridgeArches` only on masonry over water. Add a test.
- [x] Find what the orange box at the Brooklyn tower is, and fix it.

### C-5: Fabric (needs G-2, G-5) — @codex/nyc 2026-11-03
- [x] NY arm reads districts and year: pre-1945, heritage, or the FiDi prewar circle → `nyc_prewar`, even at 20+
      levels. Add FiDi, SoHo/Tribeca, DUMBO and LES circles. Normalise `-` to `_` in `cues()`.
- [x] Rows:
  - `nyc_castiron`: SoHo/Tribeca cast-iron fronts, tall windows, cornices.
  - `nyc_loft`: DUMBO brick warehouses.
  - `nyc_nycha`: red-brick towers in the park.
  - `nyc_pencil`: slender supertalls.
  - `nyc_glass` gains mullion and spandrel relief, plus an International Style black-glass variant on a podium or
    plaza.
- [x] Copper and verdigris crown material (G-5). Synthesized setbacks for prewar towers ≥ 20 levels with no parts.
- [x] Gate water towers to 6–20 storey prewar and walk-up roofs (`roof_clutter.gd`).
- [x] Check `CAP_PARTS` headroom (raise it, or prioritise by height).

### C-6: Pier 1 foreground (needs G-7) — @codex/nyc 2026-11-03
- [x] Pier-edge railing from the pier outline or a mapped `barrier`.
- [x] No grass tufts on the promenade: check `GroundCover` against pier and promenade polygons.
- [x] Furniture centred on the eye (G-7). Jane's Carousel and the Whitehall ferry terminal checked against OSM parts.

### C-7: Street life — @codex/nyc 2026-11-03
- [x] Yellow cabs: a taxi share in New York's `ParkedCars` paint, or a `taxi` kind with a roof sign.
- [x] Subway entrances: fetch `railway=subway_entrance`; a stair kiosk with green globe lamps.
- [x] Separate mapped entrance inspection: r32/r33 show High Street node `219785432` on dry pavement, with diffused split globes and railing infill. A descending terrain opening remains a photographic limitation.
- [x] NYC lamp family (Type-F / Bishop's crook) and NYC furniture kit (G-7).
- [x] Tree species rows: honey locust (Gleditsia), callery pear (Pyrus), ginkgo, zelkova, London plane; GENUS mapping;
      tree pits.

### C-8: Landmarks
One background agent batch in a scratch copy, deleted afterwards.
- [x] Hero crowns for Woolworth, 40 Wall, 70 Pine and the Municipal Building (respect their OSM parts), the Oculus,
      Staten Island ferries (harbour boats).
- [x] Check whether a small bearing nudge brings Liberty into the opening frame without losing One WTC.

### C-9: Hero loop
- [x] Capture rounds `nyc-rN` against the refs; review README and scorecard §9 line each round.
- [ ] Photographic on Ultra: human gate remains pending; the current pre-rating is recognisable.
- [ ] Complete-data Ultra cold load ≤150 s: r31 opened in 90 s with complete detailed/far responses, but the optional ring and POIs failed; the strict all-layer gate remains open.

## Critical files

- **Data:** `scripts/data/preset_views.gd`, `far_city_fetcher.gd`, `osm_query.gd`, `osm_tags.gd`, `location_data.gd`.
- **Far field and roads:** `scripts/generation/far_city_builder.gd`, `road_builder.gd`, `bridge_arches.gd`.
- **Buildings:** `building_era.gd`, `city_styles.gd`, `architecture_cities_americas.gd`, `roof_clutter.gd`,
  `facade_relief.gd`, `material_library.gd`.
- **Street level:** `parked_cars.gd`, `street_props.gd`, `street_furniture.gd`, `ground_cover.gd`, `tree_species.gd`.
- **Water:** `water_shader.gd`, `water_surface.gd`.
- **Screens, tools and docs:** `scripts/screens/view_conditions.gd`, `tools/capture_presets.gd`,
  `docs/fidelity-scorecard.md`, `docs/architecture-styles.md`.
- **New builders:** `scripts/generation/landmarks/north_america/*`.

**Reuse**
- The Brooklyn Bridge model (`landmark_suspension_bridges.gd:223`) as the Manhattan Bridge template.
- The SF district arm in `building_era.gd`.
- `ParkedCars` and `ParkedCars.front_faces`.
- `capture_presets.gd` `--looks` / `--audit`; `capture_landmarks.gd`.

## Verification

- **Per task:** headless in the background, plus `tools/check_class_size.sh` and `--import` after a new `class_name`.
  - Tests: `architecture_test`, `osm_test`, `preset_views_test`, `parked_cars_test`, `scenery_test`,
    `street_furniture_test`, `street_lights_test`, `landmark_catalog_test`, `landmark_test`, `landmark_fidelity_test`,
    `bridge_arches_test`, `fidelity_scorecard_test` (Turku (a) already fails at HEAD).
  - New tests: far-tower parts and cap order, layer decks, water colour table, NY arm, subway entrances.
- **Per round:** windowed `capture_presets.gd --places=new_york` through `tools/godot_bg.sh`.
  - Check `stats.json` colourfulness and saturation against the refs.
  - Check `BUILD timings` (Ultra cold ≤ 150 s) and far-city build time and triangle counts.
- **End:** windowed `world_cache_test` + `screenshot_test`; scorecard pre-rating for the human gate; delete scratch
  copies and check free disk space.

## Findings

| Area | Reads right | Reads wrong | Proposed change |
|---|---|---|---|
| C-1 / C-5 / C-6 / C-7 | 08:00 light, prewar FiDi rules, eye-centred furniture, wooden tank gating and tree/cab groundwork | r1 still has blue foamy water and blocky warm towers; skyline colourfulness above refs | Continue remaining tasks and capture again. Tests: preset views, OSM, furniture, parked cars and scenery passed; architecture test passed after the concurrent Stockholm relief update. |
| C-8 | Oculus model and focused test | Not yet checked against the actual mapped footprint or visually captured; crowns and ferries open; catalog test fails on concurrent Stockholm German Church search | Validate clearance and appearance before ticking. |

| C-2 | r3 water grey-green, less foam; coastal-water and shoreline tests pass | Vantage and close-up colourfulness remain above overcast references; surface appears smooth | Compare to a matching morning reference and tune remaining skyline/lighting. |
| C-3 | q3 live fetch returned 3,000 towers and 1,649 nested parts; far-city fixture tests pass | 148 s fetch alone does not prove cold-load target; 200 Vesey is mapped mainly as parts; 99 Hudson is present as an unnamed tall part | Check parent/part association and named geometry in the camera. Brooklyn Tower is southeast of Pier 1, outside the west-facing opening view. |
| C-4 / C-6 | Manhattan Bridge and shoreline rail in r2; geometry, furniture and land-deck tests pass | Bridge portal and alignment need closer visual audit; rail is inferred from coast and paved path | Capture bridge separately and inspect approach and adjacent OSM. |
| C-3 / C-5 / C-7 | Far-city parts and cap-order fixtures, architecture and building-fabric tests, tree species and tree-pit test pass; layer-deck and arch tests pass | q10 detailed OSM response ran out of server memory before furniture; r4 foliage has pale triangles | q11 moves furniture earlier and refetches; visually verify the result and foliage. |
| C-7 | q11 returned 408 eye-centred furniture nodes before its later memory failure; OSM, furniture, lamp and tree-pit tests pass | No subway entrance was mapped in this 450 m park-centred query; r5 still has pale foliage polygons | Inspect a mapped subway entrance separately and diagnose foliage. |
| C-4 | OSM near the Brooklyn-side tower includes St. Ann's Warehouse, an 8 m brick theatre (way 373709849), about 45 m from the tower area | This may explain a brick mass but does not establish the source of the reported orange box | Capture and identify the object before changing it. |
| C-3 / C-5 | The q11 map marks 2 World Trade Center as construction with a planned 373.7 m height and 2031 opening; both detailed and far parsers now exclude explicit construction footprints. Far-city and OSM fixture tests pass. | This avoids drawing the planned tower as already complete, but does not model the active construction site. | Compare the next skyline capture. |
| C-6 / C-8 | q11 identifies Jane's Carousel as a 7 m glass building, Whitehall Terminal as a 15 m mapped building, and the Oculus as a mapped station about 10 m from the model anchor. | Their visual appearance, Oculus alignment and replacement of its mapped dome still need close inspection. | Capture close views against the mapped outlines. |
| C-8 | Oculus anchor and 39° axis now follow OSM way 278033606; isolated capture `visual-plan/captures/nyc-oculus-wings2-2026-11-03/` and bounds test pass. The shell now has rising white wings and a central skylight. | The isolated shape is simplified and its in-world fit and mapped-footprint suppression remain to be checked. | Inspect a close in-world view. |
| C-3 / C-5 | One Manhattan Square's mapped 258 m part specifies mirror glass; the distant detailed and far-city paths now retain mapped glass instead of assigning masonry from residential use. Architecture and far-city tests pass. | r7 predates the material correction. | Recheck its bridge-side appearance in r8. |
| C-3 / C-8 | r8 bridge close-up shows the mapped glass facade; two elevated views show the Oculus replacement on the site with adjacent towers retained. | Oculus model remains simplified, and one camera intersects a facade. | Check a street-level view and remaining landmarks. |
| C-7 / C-9 | Eye-centred tree LOD is covered by `tree_eye_lod_test` and scenery tests; r9 removes the large nearby billboard triangles. | Detailed trees are very dark and cast strong shadows onto the river. | Investigate canopy lighting and shadow balance before the final review. |
| C-8 | A procedural Staten Island ferry is gated by a mapped terminal and a clear water berth; wet, dry and dimensions fixtures pass. r11 shows a distant orange silhouette. | Real-time vessel positions are not available, and the distant view cannot establish the model's close appearance. | Inspect the terminal and vessel at closer range. |
| C-8 | r13 close view shows the ferry clear of the nearby shoreline after the water-clearance margin was enlarged; harbour-ferry tests pass. | The water-side shoreline remains visibly angular; ferry placement is procedural, not a live position. | Continue the skyline and landmark review. |
| C-4 | The tall orange box behind the bridge in the original `ultra-p7f` `new_york_h000` is the mapped 258 m One Manhattan Square part (`way:611246737`, mirror glass). In r8 `new_york_h000` the same object is glass; architecture and far-city material tests pass. | Other orange masonry blocks remain in the skyline. | Assess remaining facade colours separately. |
| C-6 | r8 `new_york_h000` shows the paved promenade without the tufts seen in the original `ultra-p7f` view; `render_upgrade_test` covers mapped pier exclusion. | The shoreline rail is inferred from the parallel paved path and coast because no railing was mapped near the eye. | Check the remaining foreground features. |
| C-5 / C-8 | Distant detailed and far-city roofs now retain explicit copper tags; architecture and far-city tests pass. r14 shows historic stepped masses and a green pyramidal crown. | This does not establish the individual ornamental details requested for all four hero crowns. | Inspect each mapped crown and add the missing details without replacing its OSM parts. |
| C-1 | Added a clear 09:14 Pier 1 skyline photo with identified buildings, plus separate night and street references. | The 09:14 image is not verified as golden hour; the golden-hour photo found so far is from near DUMBO. | Continue looking for a verified Pier 1 golden-hour image. |
| C-8 | The mapped 70 Pine spire is already a narrow 26 m part; its observatory parts now default to glass based on the Skyscraper Museum reference. Civic Fame replaces only the Municipal Building's mapped gold statue box with a small figure. Focused crown and building-fabric tests pass; an actual q11 parse matches both target parts. | r16 is too distant to judge the lantern and predates Civic Fame. | Inspect close views and remaining crown details. |
| C-4 | r20 shows the Manhattan entrance connected to the approach, with a continuous curved opening; the bridge geometry test passes. | The portal and colonnade remain simplified; the approach looks excessively broad and vegetation is conspicuous near the deck. | Refine and visually compare the approach and entrance against references. |


## Continuation — 2026-11-04

[Combined review and validation](../../visual-plan/reviews/nyc-validation-2026-11-04/README.md).
No commits or pushes. Concurrent vessel and Suomenlinna work was preserved.

| Task | Evidence | Result |
| --- | --- | --- |
| C-1 | Clear-morning reference subset and r23/r26 comparisons | 08:00 retained. Night/street context exists; a verified golden-hour photo specifically from Pier 1 remains unfound, so the reference checkbox stays open. |
| Data / cache | `overpass_payload_test`, complete q12 live response (43.73 s, 22,372 elements), `world_cache_test` | Runtime-error replies retry; partial detailed/far caches remain explicitly available offline. Nested landmark sources invalidate cached worlds. |
| C-3 | `far_city_test`, r26 mapped audit and Jersey City close view; r27 Brooklyn close view | Stable OSM identities retained, including unnamed 99 Hudson part `way:1252090828` and Brooklyn Tower `way:1039403183`; Goldman Sachs is `way:259686624`. 200 Vesey gains eight parts instead of one, with detailed tags winning and duplicate far geometry suppressed. |
| C-4 | `manhattan_bridge_test`, `bridge_vegetation_test`, r26 look4 | Narrower connected central approach, separate upper roadways, source-sized round arch, Tuscan columns and clear bridge corridor. Model remains simplified. |
| C-5 | Architecture/building-fabric/material tests; r26 look0 | Existing NYC facade families verified. Distant glass/stone and explicit finishes survive LOD; Woolworth is pale glazed cladding rather than red brick. |
| C-6 | r26 look6/look10, r27 terminal close views, waterfront material test | Carousel is mapped as a 7 m glass pavilion with no parts; promenade has rail and bench. Whitehall keeps five mapped parts and source-backed steel/glass defaults. Shoreline and terminal detail remain stylized. |
| C-7 | `street_furniture_test`, live York Street node `3134691329` | Mapped entrance confirmed independently. York Street/High Street fallback captures did not provide acceptable kiosk close views; do not treat them as visual acceptance. Existing kiosk/globe tests pass. |
| C-8 | Crown/material tests, r26/r28/r30 crown looks, Oculus street view, ferry gallery | Crown ornament follows mapped rings/heights; 70 Pine lantern, Civic Fame and copper crowns retained. Oculus glazing replaces solid side panels. Concurrent ferry model reviewed without overwriting it. Fine landmark fidelity remains subject to the human review. |
| C-8 composition | r22 looks5–10 and `preset_views_test` | Bearings 293–298 compared. 295° is the nearest to 298° giving both subjects at least 2° of margin at 1280×800; 08:00 retained. |
| C-9 | r21–r28, Fast/High captures, full-data cached run and isolated cold run | Cached opening 14 s, generation 7.840 s, far city 530 ms / 276,362 triangles. Photographic quality and complete-data cold timing remain open. |
| C-9 follow-up | [r31 cold capture](../../visual-plan/reviews/nyc-r31-cold-2026-11-04/README.md), mirror probes and retry tests | Removed whitelist-only OSM-FR; 403 advances mirrors, 400 still stops. Empty-cache Ultra opened in 90 s with complete detailed/far responses; generation 8.176 s, far network/parse 73.792 s. Ring and POIs failed, so all-layer timing remains open. |
| C-7 follow-up | r32/r33 High Street close views, complete local q12 audit and street-furniture test | Mapped node `219785432` is visibly placed on dry pavement. Split white/green globes reduce bloom and railing infill is present. Missing-view evidence is resolved; true terrain excavation for descending stairs remains a photographic limitation. |
| Continuation | r34 cold run, r35 High Street close view and [reference notes](../../visual-plan/refs/new_york/README.md) | r34 opened in 103 s but far towers missed the build and POIs timed out. r35 connects globe lamps to their posts. A 06:39 golden-hour skyline photo is attributed to Fulton Ferry Landing near Pier 1; a verified Pier 1 photo remains open. |

The 27 focused/regression checks pass, as do windowed cache and screenshot checks.
The broad live scorecard run timed out at 180 s; its focused Turku rerun reproduces the
known DEM (a) failure while (b), (c), water/roads (d) and (e) pass. Class-size and diff
checks pass. Generated capture/test world caches were removed after review.


r29/r30 close inspection: thin raised crown parts inherited the full tower's storeys and masonry relief,
covering 70 Pine's glass lantern. Part-height storey resolution and glazed-part relief now retain the
lantern in r30 look0; the 66-storey-parent/two-metre-part regression, building-fabric and architecture
checks pass. Crown implementation is checked; photographic and human acceptance remain open.
