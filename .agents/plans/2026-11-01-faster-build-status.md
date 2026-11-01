# Faster Build: Status Board (2026-11-01)

> **Plan:** `/Users/petri.tuononen/.claude/plans/implement-ingeniuous-and-clever-groovy-pancake.md`.
> The shared tracker `.agents/plans/2026-10-28-real-location-fidelity-redesign.md` is a
> different file. An old stash (`refs/backup/temp-lane-c-2026-11-01-1444`) overwrote it with
> this plan; never restore that file from the stash.
>
> **Rule:** tick a box only with evidence named next to it. A comment in the code is not
> evidence.

## Result

The world from `TerrainBuilder.build_world` is **byte-identical** to the pre-work build
(`f022358`) on Paris, Venice, Zermatt and Big Sur × Fast/Balanced/High/Ultra. That holds for
both the serial and the parallel build. The parallel build is now the default
(`WorldBuildGraph.force_serial = false`).

**How identity was checked:** `tools/build_bench.gd` freezes each place's `LocationData`
(images included), builds it windowed in a `f022358` worktree and in this tree, and diffs
SHA-256 hashes of every top-level child. Each hash covers:
- transforms and metas
- every mesh surface's arrays
- MultiMesh buffers
- every material property, with texture bytes

All 10,299 fingerprint lines match. The PBR cap fallback (serial rebuild) never fired on this
set.

Ground + world build time on this machine (16 cores), from the same frozen data:

| Place | Preset | Before | Serial now | Parallel now |
|---|---|---|---|---|
| Paris | Fast / Bal / High / Ultra | 23.8 / 19.6 / 20.8 / 24.8 s | 17.0 / 16.4 / 17.6 / 19.2 s | 10.9 / 11.8 / 11.6 / 12.1 s |
| Venice | Fast / Bal / High / Ultra | 40.1 / 29.9 / 35.0 / 41.8 s | 29.2 / 25.1 / 29.2 / 35.1 s | 17.2 / 10.5 / 11.3 / 17.3 s |
| Zermatt | Fast / Bal / High / Ultra | 5.5 / 5.1 / 6.4 / 8.7 s | 2.7 / 3.6 / 4.6 / 6.1 s | 1.3 / 2.0 / 2.5 / 3.6 s |
| Big Sur | Fast / Bal / High / Ultra | 5.2 / 3.2 / 4.5 / 6.7 s | 3.2 / 2.5 / 3.4 / 4.7 s | 2.3 / 1.1 / 1.9 / 3.1 s |

That is 1.7–4.2× overall. GroundTruth is not in these figures when it was already built during
the fetch (3.5).

## Phase 0: Bench and fingerprint

- [x] **0.1 Bench:** `tools/build_bench.gd` has three modes: `snapshot`, `build` (serial) and
  `parallel`. `BENCH_DUMP=<child>` prints that child's material properties. The old synthetic
  bench and its empty `bench-baseline.txt` were replaced.
- [x] **0.2 Real baseline:** a `f022358` worktree vs this tree, on the frozen snapshots.
- [x] **Timings:** `BuildAbort.ms` per stage, printed as `BUILD timings {…} total=… serial|parallel`.

## Phase 1: Exact hot-spot fixes

All of these are covered by the V1 fingerprints.

- [x] **1.1** No-imagery `land_color`: inclusive outer-ring bounds pre-reject.
- [x] **1.2** GroundMaterial gain and ceiling read `data.satellite_image` (no GPU read-back).
- [x] **1.3** GroundTruth:
  - DEM tables filled from `DemRegistration.grid_index`, which is separable
  - blur interior unrolled
  - `GroundIndex` land-class and building grids
  - `PolygonIndex.contains` single-ring path
- [x] **1.4** Far terrain:
  - Mercator U/V computed once per vertex
  - climate values computed once per build
  - GroundTruth's water index reused
  - z8 bounds reject with a 1-unit margin
- [x] **1.5** Roads: fused bilinear + triangle height sample.
- [x] **1.6** Buildings:
  - winding computed once per ring
  - infill early exit
  - batch tangents skipped
  - roof tangents memoised
  - distant roof hint skipped
  - facade wall-layer and storey-base memos, cleared per build
  - native `Transform3D * PackedVector3Array` for roofline details
- [x] **1.7** SettlementMap: per-row/column UVs, float64 features.
- [x] **1.8** Water: clip once; `water_at` before `land_class_at`.
- [x] **Fixed or reverted from the earlier attempt:**
  - zeroed far-ring normals
  - drape-coloured rings
  - float64 DEM tables
  - float32 settlement features
  - the unsafe "never wet" shortcut
  - roof depth search
  - per-call key sorts
  - placeholder allocations
  - lost loading-bar phases
- [x] **V3** `tests/ground_index_test.gd`: 41,691 probes (random points, cell edges, vertices,
  points past the extent) agree with the full scans.

## Phase 2: Parallel build (`WorldBuildGraph`, **on**)

- [x] Seven stages run as WorkerThreadPool tasks: far, terrain, water, buildings + far city,
  roads, landmarks and vegetation. They are adopted in the serial child order.
- [x] **Shared caches:**
  - The facade caches stay with the buildings task, so their serial order holds.
  - `PbrTextures` cache keys round tint and repeat, so each key's values are resolved by
    serial stage rank.
  - Far, terrain and water see the previous build's cache, as they do serially.
  - Past the 64-entry cap the build is rebuilt serially.
  - The earlier aux and private-cache machinery was removed.
- [x] Stopping the build returns an empty world. The progress step only advances
  (`BuildAbort.mark_done`).
- [x] `tests/parallel_build_test.gd`: serial and parallel give identical worlds; a second
  parallel build gives the same; a stop returns an empty world; progress ends past Vegetation.
- [x] **V1 parallel:** 16/16 identical (see Result).
- [x] **2.4** `BuildAbort.STEPS` weights retuned to the parallel run (Paris High: distant terrain ~3 s, buildings to ~11.6 s); `loading_building_test` OK.

## Phase 3: Network wait and cache (all done)

- [x] **3.1** `BuildPrewarm` (verified: 18 set images loaded) fills two caches on WorkerThreadPool during the fetch: the
  `TerrainTextures` arrays and the always-used PBR set images (albedo only on Fast). It is
  skipped when a cached world is found, and waited for before `finished`. `TerrainTextures`
  saves use a temp name per thread.
- [x] **3.5** GroundTruth is built on WorkerThreadPool right after OSM lands, during the
  far-city and climate waits. `main` passes it to `build_location`.
- [x] **3.6** Composed facade textures are reused across builds, keyed by the **exact** composer
  inputs (`FacadeTextures.composed`), not by the per-build caches' rounded keys. Those caches
  and their caps are unchanged.
  - `end_build` keeps only what that build used, and the shown world references those
    textures anyway, so nothing extra stays resident.
  - V1: serial and parallel are still 16/16 identical across the sequential bench, where later
    presets and places reuse stored compositions.
- [x] **3.7** `WorldCache.prefetch` starts loading the newest cached world for the place,
  preset and season at `run()`. `load_world` adopts it when the key matches; unused
  prefetches are collected without blocking.

## Phase 4: Main-thread tail

- [x] **4.1** The world is packed on the build thread (`WorldCache.pack`), not on the main
  thread before the view shows.
- [x] **4.2** A cached world is instanced on a Thread that the view joins on exit.

## Not part of this work (other agents, in the same tree)

Commit these separately:
- `PresetViews` (`scripts/data/preset_views.gd`, `location_data.gd`, `pipeline.gd`
  `data.view`, camera code in `view_360.gd`)
- the `osm_query` / `osm_parser` / `osm_tags` changes
- the `dem_conversion.gd` water datum: this changes worlds and needs a `BUILD_VERSION` bump
- `atmosphere_rig.gd`

## Verification run (2026-11-01)

- **Headless suite:** 45/45 pass with the parallel build on, including `ground_index_test` and
  `parallel_build_test`.
- **`tools/check_class_size.sh`:** OK.
- **Windowed `world_cache_test`:**
  - OK: identical cached world, background save.
  - Cold 16.9 s vs cached revisit 3.9 s.
  - The prefetched world was ready in 8 ms.
- **Windowed `screenshot_test`:** shots taken. The first Paris view frame is black at capture
  time in the `f022358` baseline as well, so that is the test's capture timing, not this
  work.

## After the landmark merge (2026-11-01)

- **Snapshots:** all 16 re-taken with the merged pipeline (LandmarkSites candidates included).
- **Serial vs parallel:** the `build` and `parallel` fingerprints match on 16/16 rows.
  - Landmarks change worlds, so the comparison with `f022358` no longer applies.
  - What must hold is parallel == serial, and it does.
- **Visual check:** the real app flow was driven to Paris with the parallel build. The view
  opened after 4.2 s, served from the world cache, and rendered correctly: Seine, Haussmann
  blocks, trees, Eiffel Tower, La Défense, 78 fps on High.
  - A winter season change then rebuilt the world in parallel in 19.4 s and rendered
    correctly: at 19:00 that is night, with lit windows.
- **Headless suite:** 47/47, including `landmark_fidelity_test`.
