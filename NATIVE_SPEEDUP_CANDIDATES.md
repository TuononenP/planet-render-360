# Build speed-up candidates

Measured 2026-11-19. The question was whether converting more GDScript to native C++ would speed up world builds. The answer is that little is left for C++ to win: no remaining pure-arithmetic loop costs more than about 0.6 s in a release build. Seven build-time candidates and one runtime issue are listed below, ranked by what each could save.

## Status (2026-11-19)

The recommended order is done. Candidates 4–7 were not started: the plan ranks them below the recommended items, and the measurements below make them less attractive, not more.

| Step | Status | Outcome |
|---|---|---|
| Candidate 1, material resolution | ✅ Investigated, no code change | The cost is one-time cold work, not resolve logic. Memoising per look has nothing to save. See candidate 1. |
| Candidate 2, plinths | ✅ Done, native | `PlinthKernels`: arithmetic 45 µs → 5.3 µs per plinth. About 0.15 s saved over a Paris and a Helsinki build. |
| Candidate 3, far canopy probe pass | ✅ Done, native | `CanopyKernels`: 0.15–0.2 s saved per build in both cities, identical crowns. |
| Post-swap vehicle hitch | ✅ Confirmed and fixed | Main-thread `VehicleMover.attach` on Helsinki: 47.8 ms → 0.96 ms. The route walks now run in `compute_plans` on the worker. |
| Candidates 4–7 | ⬜ Not started | Not in the recommended order. |

### Release serial build, before and after

Release export of the project, native library loaded, world cache off, `WorldBuildGraph.force_serial`, frozen Ultra inputs for Paris and Helsinki, two runs each (before → after). The "before" build is `f8a8be46` with its older native library. The plinth timer exists only in the exported copies.

| Measure | Paris | Helsinki |
|---|---|---|
| Far canopy (`FAR-CANOPY` line) | 724 / 723 ms → 573 / 557 ms | 701 / 666 ms → 507 / 490 ms |
| Buildings stage | 7,341 / 7,243 ms → 7,092 / 7,091 ms | 2,634 / 2,598 ms → 2,565 / 2,562 ms |
| Vegetation stage | 4,465 / 4,428 ms → 4,245 / 4,407 ms | 2,357 / 2,394 ms → 2,244 / 2,214 ms |
| Serial total | 17.3 / 17.1 s → 16.8 / 16.6 s | 9.47 / 9.39 s → 9.30 / 8.94 s |

Plinth time summed over both builds (about 5,000 plinths): 649 / 633 ms → 490 / 481 ms.

Output is unchanged. The `tools/build_bench.gd` fingerprints of Paris and Helsinki (every top-level world child, 5,113 lines) are byte-identical before and after both kernels. `tests/plinth_kernels_test.gd` and `tests/canopy_kernels_test.gd` also compare each kernel with its script loop exactly, on random inputs.

What the numbers do not show: the parallel wall time was not re-measured. Neither kernel's stage is the slowest one (buildings in Paris, roads and landmarks in Helsinki), so the saving mostly shows up as less CPU, not a shorter wait. The plinth saving is about 2% of Paris's buildings stage.

`tools/build_bench.gd` gained a `helsinki` place so the Helsinki inputs can be fingerprinted. One of three baseline runs on the main working tree gave a different Paris fingerprint (Stairs, VegTreeSet and everything after them); the other two, and all runs on a clean worktree, agreed. The cause was not found, so compare a fingerprint with two baseline runs, not one.

## How this was measured

- Release export of the project (macOS, Apple silicon), native library loaded, world cache disabled (`PR360_DISABLE_WORLD_CACHE=1`).
- Frozen inputs for Helsinki and Paris at Ultra (preset 3), so every run builds the same data.
- Serial build (`WorldBuildGraph.force_serial = true`), so stages do not slow each other down. Temporary section timers were added to a copy of `building_builder.gd` and `road_builder.gd`; they are not in the repo.

Do not rank candidates from the editor binary's parallel stage timings. They read 3–5× larger than the loops cost alone. The terrain vertex loop printed 2,225 ms there and 200 ms in the release serial build.

### Release serial build, Ultra

| Stage | Paris | Helsinki | Main contents |
|---|---|---|---|
| Buildings | 6.4 s | 2.1 s | mapped loop 4.9 s / 1.7 s |
| Roads and landmarks | 4.0 s | 3.4 s | roads 2.3 s in both |
| Vegetation | 3.8 s | 2.2 s | props 1.8 s / 1.4 s, far canopy 0.7 s, tree plan 0.27 s / 0.25 s |
| Ground and water | 0.6 s | 0.7 s | terrain vertex loop 0.2 s |
| Far terrain | 0.4 s | 0.35 s | |
| **Total** | **15.2 s** | **8.8 s** | |

Stages normally run in parallel, so wall time is roughly the slowest stage plus contention. Helsinki took 3.5–3.8 s in parallel. Paris took 6.2 s in one run and 9.6 s in another, so its parallel total is noisy; compare serial numbers.

### Mapped-building loop by section (ms)

| Section | Paris | Helsinki |
|---|---|---|
| Facade material resolve | 937 | 330 |
| Roof material resolve | 835 | 24 |
| Plinths | 522 | 61 |
| Facade relief | 431 | 202 |
| Roofline detail | 358 | 75 |
| Walls | 264 | 110 |
| Trim and roof cap | 188 | 55 |
| Vertex tint | 183 | 60 |
| Party-wall cover | 173 | 11 |
| Mass planning | 118 | 42 |
| Ground storey and shop fronts | 97 | 118 |
| Roof forms | 89 | 394 |
| Enclosed check | 80 | 25 |
| Triangulation | 36 | 8 |
| Foundation sampling | 32 | 13 |
| **Loop total** | **4,878** | **1,733** |

## Candidates

### 1. Building material resolution

- **Cost:** Paris 1.8 s (facade 0.94 s, roof 0.84 s); Helsinki 0.35 s.
- **Where:** `FacadeMaterials.facade_for_building` (`scripts/generation/facade_materials.gd:125`) and `FacadeMaterials.roof_for_building` (`:411`), called per mass from `BuildingBuilder._extrude_polygon` (`scripts/generation/building_builder.gd:522-536`).
- **Nature:** Dictionary, string and material-cache logic. C++ is the wrong tool.
- **Approach:** memoise per look in script. Find out first why roof resolution costs 0.84 s in Paris and 0.02 s in Helsinki; the cause has not been identified.
- **Why first:** it is the largest single piece, and it sits on Paris's slowest stage.
- **Status: ✅ investigated, no code change.** The cost is not the resolve logic. In Paris, 5 of the roof calls take 867 ms between them and 78 of the facade calls take about 800 ms; every other call is cheap (about 14 µs for a facade and 7 µs for a roof on a cache hit, 106 ms for all 5,000 masses together). The slow roof calls are the first use of a PBR texture set: `PbrTextures._set_tex` decodes a set's maps, builds mipmaps and uploads them, about 170 ms a set, once per process. The slow facade calls are first-time look compositions (`FacadeComposer`), about 10 ms each. Helsinki's roofs are cheap because most of them are distant and share the regional roofs. So memoising per look can save at most 0.1 s, and the real cost is cold start, paid once per session. The only way to remove it from the buildings stage is to load the sets on an idle worker ahead of time, which loads sets a place may not use and costs memory on mobile; it was not done.

### 2. Plinths

- **Cost:** Paris 0.52 s; Helsinki 0.06 s.
- **Where:** `BuildingFoundation.plinth` (`scripts/generation/building_foundation.gd:172`).
- **Nature:** one quad and an optional coping per footprint edge, each with ground probes at both corners and the midpoint. Mostly arithmetic.
- **Approach:** a native batch that takes the ring, the footing and the edge grounds and returns the face and coping arrays. `ShoreSampler.edge_grounds` already reads the grounds natively for shoreline cities.
- **Estimated saving:** 0.3–0.4 s in Paris.
- **Status: ✅ done (native, `native/src/plinth_kernels.cpp`).** Measured before writing it: of Paris's 0.54 s, 0.38 s is mesh creation in `BuildingWalls._emit`, which has to stay for identical output, so only about 0.17 s was arithmetic. After: 45 µs → 5.3 µs per plinth, about 0.15 s over 5,000 plinths in a release build. `BuildingFoundation.plinth_arrays_script` stays as the fallback (`_native_plinth`), and `tests/plinth_kernels_test.gd` compares the two exactly.

### 3. Far canopy

- **Cost:** 0.6–0.7 s in both cities (80,000 crowns).
- **Where:** `FarCanopy.plan` (`scripts/generation/far_canopy.gd:73-124`), with `pixel` (`:188`) and `_vegetation_cells` (`:149`).
- **Nature:** up to 81 probes per cell, each reading a drape pixel through Dictionary lookups; most probes are rejected on darkness or greenness.
- **Approach:** a native probe pass that takes the drape byte arrays and UV parameters and returns position and pixel for surviving probes, next to `CityKernels.settlement_features`, which samples the same drapes. Height, species and size stay in script.
- **Limit:** the per-survivor work depends on `FarSampler._blend_height`, whose native twin is not bit-exact with the script, so only about half the time can move.
- **Estimated saving:** about 0.3 s.
- **Status: ✅ done (native, `native/src/canopy_kernels.cpp`).** The probe loop was 190–240 ms and `_blend_height` for the survivors about 400–470 ms, so about 0.2 s could move, as predicted. The kernel does the jitter, the drape pixel and the darkness test and returns the survivors; height, species and size stay in script. Saved 0.15–0.2 s per build in a release build with identical crowns. `FarCanopy._probes_script` stays as the fallback (`_native`), and `tests/canopy_kernels_test.gd` compares the two exactly.

### 4. Facade relief, roofline detail and walls

- **Cost:** relief 0.43 s / 0.20 s, detail 0.36 s / 0.08 s, walls 0.26 s / 0.11 s (Paris / Helsinki).
- **Where:** `FacadeRelief.add`, `BuildingDetail.add`, `BuildingWalls._walls` and `_quad` (`scripts/generation/building_walls.gd`).
- **Nature:** geometry emitters mixed with Dictionary parameters and node creation. Relief already writes through the native `QuadSink`.
- **Approach:** route wall quads through a `QuadSink`-style accumulator; move further relief pieces into the sink.
- **Estimated saving:** 0.1–0.3 s each.
- **Note:** roof forms cost 0.39 s in Helsinki although `RoofKernels` is native. The script wrapper around it has not been split further.
- **Status: ⬜ not started.**

### 5. Roads

- **Cost:** 2.3 s in both cities.
- **Where:** `RoadBuilder._roads` (`scripts/generation/road_builder.gd:220-289`).
- **Paris split:** per-road wrapper around the native ribbons 0.89 s, mesh creation 0.48 s, surface setup 0.42 s, bridge structures 0.21 s, paint 0.09 s, markings 0.07 s, glyphs 0.04 s, tapers 0.03 s.
- **Nature:** the ribbons themselves are already native (`RibbonDraper`). What remains is per-road script logic, engine mesh creation and setup. None of it is a clean kernel.
- **Approach:** profile `_road` and `_Surface.new` further before deciding. The marking, paint and glyph passes are too small to matter.
- **Status: ⬜ not started.**

### 6. Street props

- **Cost:** Paris 1.8 s; Helsinki 1.4 s.
- **Where:** `StreetProps.build` (`scripts/generation/street_props.gd`) and the builders it calls.
- **Paris buckets:** cars 0.57 s, marina 0.39 s, barriers 0.31 s, plazas 0.25 s, wires 0.13 s, trams 0.12 s.
- **Helsinki buckets:** marina 0.31 s, trains 0.28 s, barriers 0.26 s, trams 0.23 s, cars 0.11 s.
- **Nature:** a dozen buckets of 0.1–0.5 s, each with its own point tests against water, roads and rings. No single target.
- **Approach:** low priority. In a streamed build this is detail-layer work that runs after the swap.
- **Status: ⬜ not started.**

### 7. Vegetation grids, terrain mesh and far-terrain bands

- **Cost:** 0.1–0.3 s each.
- **Where and measured cost (Helsinki / Paris):**
  - Tree fill, `VegetationBuilder._fill_cover` (`scripts/generation/vegetation_builder.gd:273`): 128 ms / 107 ms, of which the forest-area loop is 78 ms.
  - Canopy trees, `CanopyVegetation.add`: 62 ms / 99 ms.
  - Ground cover, `GroundCover._scatter` (`scripts/generation/ground_cover.gd:293`): 213 ms / 259 ms.
  - Terrain mesh, `TerrainBuilder._terrain_mesh` (`scripts/generation/terrain_builder.gd:302`): vertex loop about 200 ms.
  - Far terrain, `FarTerrainBuilder.build_far`: about 350 ms for the whole stage.
- **Nature:** clean arithmetic loops, and the easiest to port.
- **Verdict:** not worth it. The saving is small and every port carries a byte-identity risk. These looked like the best targets in the debug log only because of the inflation described above.
- **Status: ⬜ not started.** The kernels above bear this out: each port saved 0.15–0.2 s of CPU.

## Post-swap vehicle hitch

- **Symptom:** the fourth frame after a streamed world swap is often the worst: up to 135 ms in `Debug_19.11.2026.txt`, 50–90 ms in the `ab-final-2026-11-19` perf run.
- **Suspected cause:** `VehicleMover._adopt` (`scripts/render/vehicle_mover.gd:205-273`) runs on the main thread in that frame. For each tram and train it walks the route in 5 m steps (`_span`), scans all street furniture for signals with a linear nearest-point search (`_signals`), and snaps stops the same way.
- **Status: ✅ confirmed as a main-thread cost and fixed.** Timed on the frozen Helsinki world (editor binary): with the plans precomputed, as in a stream, `VehicleMover.attach` still took 47.8 ms on the main thread, which is most of a 50–90 ms frame. Paris has no trams, so it costs nothing there. Not confirmed in a live streamed flight; the frame's renderer uploads were not isolated.
- **Fix:** `VehicleMover.motion()` now works out each train's run, stops, direction, signals and deck middle, and `compute_plans` calls it on the worker and stores the result in each plan entry. `_adopt` only reads it (and computes it itself when there is no plan). `attach` on the main thread: 47.8 ms → 0.96 ms. `compute_plans` grew from 96 ms to 148 ms, on the worker, in the landmarks stage. The motion fields of all 30 Helsinki trams hash identically before and after, and `tests/vehicle_mover_test.gd` checks planned against unplanned motion for trams and platform trains.
- **Approach:** first add a timer around `_adopt` and confirm it owns the frame. If it does, move `_span`, `_signals` and stop snapping into `compute_plans`, which already runs on a worker (`scripts/render/world_streamer.gd:937-940`). This is a threading change, not a C++ one.

## Recommended order

1. ✅ Material resolution, as a script-level caching change. Investigated: nothing to cache, see candidate 1.
2. ✅ Plinths and the far canopy probe pass, if native work is still wanted: roughly 0.3–0.5 s each. Done; each saved 0.15–0.2 s.
3. ✅ The vehicle hitch, after confirming the cause with a timer. Confirmed and fixed.

## Rules for any native kernel

- Output must stay byte-identical. Add a `tests/*_test.gd` parity test that compares native against the script path exactly, following `tests/tint_kernels_test.gd`, and compare `tools/build_bench.gd` fingerprints before and after.
- Keep the script fallback, gated with `ClassDB.class_exists` or `class_has_method`.
- Keep scripts at or under 1000 lines (`tools/check_class_size.sh`). `building_builder.gd`, `road_builder.gd` and `pipeline.gd` are near the limit.
- Rebuild iOS and Android with `tools/build_native.sh`; their libraries in `native/bin/` are older than the macOS one.
  Done for the two kernels above: macOS, iOS and Android libraries were rebuilt and carry both classes.
- Time the change in a release serial build on frozen inputs, before and after.
