# Roads & Props Build Speed-Up + Zero-Leak Exit Plan

> **Scope:** Two focused engineering workstreams grounded in our live Metal 4.0 Helsinki/Interlaken telemetry (`task-438`, `task-449`) after landing `a34a4b00` (`facade_compose` 4.06 s → 0.49 s, `FAR-CANOPY` 3.05 s → 0.85 s, VRAM 9.5 GB → 3.6–4.0 GB):
> 1. **Workstream A — Speed Up `Roads` (5.4–6.3 s) + `PROPS` (4.1–5.6 s) + `GroundCover` (1.6–2.4 s):** Now the top build-time bottlenecks in Helsinki's 9.0 s parallel Ultra build.
> 2. **Workstream B — Close the Last ~10% of Exit Leaks (`8` `RendererRD` Textures / `20` Texture RIDs / `1,262` `ObjectDB` instances / `7` Resources):** Achieve a clean **0-leak exit** on desktop Forward+.
>
> **Invariants:**
> - **AC-12 (Zero visual regression):** No moved objects, no shifted hues, byte-identical serial vs. parallel build fingerprints.
> - **Class size (`AGENTS.md`):** Every GDScript file under `scripts/` stays **≤ 1000 lines** (`tools/check_class_size.sh`).
> - **Verification:** All agent-run Godot processes launch via `tools/godot_bg.sh`, never `.app` directly, never `GODOT_FOREGROUND=1`, off-screen captures use `--position 4000,4000` without `--always-on-top`.

---

## 0. Current Baseline Telemetry & Class-Size Budget

### 0.1 Live Metal 4.0 Baseline (Helsinki Ultra, `task-438` / `task-449`)

| Stage / Metric | Current Measured | Share of Critical Path | Target After Plan |
|---|---:|---:|---:|
| Parallel build total (Helsinki Ultra) | **9.0–9.2 s** | 100% | **≤ 5.0 s** |
| `Roads` (`_roads` + `decals` + `kerbs` + `rails`) | **6.4–7.0 s** (`roads: 5.4–6.3 s`) | ~75% | **≤ 2.8 s** |
| `Vegetation` total | **9.0–9.2 s** | 100% (critical path) | **≤ 4.5 s** |
| — `PROPS` (inside `Vegetation`, 14 serial sub-builders) | **4.1–5.6 s** (`barriers 1.2–1.7 s`, `cars 1.2–1.6 s`, `marina 0.95 s`, `ferries 0.55 s`, `plazas 0.27–0.47 s`, `wires 0.24–0.50 s`) | ~60% of Vegetation | **≤ 1.8 s** |
| — `GroundCover` (`cover` inside `Vegetation`) | **1.6–2.4 s** | ~25% of Vegetation | **≤ 0.5 s** |
| Exit leaks (`task-449`, real Metal window) | **1,262** `ObjectDB`, **20** `Texture` RIDs (8 `RendererRD`), **7** Resources | — | **0 / 0 / 0** |

### 0.2 Class-Size Budget (`scripts/` ≤ 1000 lines)

| File | Current Lines | Headroom | Plan Strategy |
|---|---:|---:|---|
| `scripts/generation/road_builder.gd` | 786 | 214 | Safe (recently shrunk from 998 via `RoadSurfaceSampler`); add sub-stage timing + keep new helpers in `road_builder.gd` or extracted pass. |
| `scripts/generation/street_props.gd` | 786 | 214 | Safe (~35 lines to dispatch independent prop builders on `WorkerThreadPool` in deterministic order). |
| `scripts/generation/marina_builder.gd` | 597 | 403 | Safe (profile/optimize only if still > 600 ms after parallelization). |
| `scripts/generation/vegetation_builder.gd` | 518 | 482 | Safe (~15 lines if overlapping `GroundCover` + `StreetProps`). |
| `scripts/generation/ground_cover.gd` | 442 | 558 | Safe (~45 lines for `MultiMesh.buffer` + row-parallel `plan()`). |
| `scripts/generation/parked_cars.gd` | 353 | 647 | Safe (~40 lines for `MultiMesh.buffer` + spatial early-out). |
| `scripts/render/static_caches.gd` | 196 | 804 | Safe (~25 lines for any remaining static caches found by `--verbose` audit). |

---

## 1. Workstream A — Speed Up `Roads`, `PROPS`, and `GroundCover`

### 1.1 `PROPS` Parallelization & Hot Sub-Builders (5.6 s → ≤ 1.8 s)

- **Root cause:** In `scripts/generation/street_props.gd`, all 14 prop sub-builders (`lamps`, `barriers`, `shore_railings`, `furniture`, `plazas`, `marina`, `ferries`, `quay`, `cars`, `trams`, `trains`, `aircraft`, `wires`, `utility_poles`, `snowbanks`, `beach`) execute **strictly serially** on a single thread inside the `Vegetation` stage, even though each reads immutable `data` + `ground` and emits its own independent `Node3D` subtree.
- **Key detail for determinism (AC-12):**
  - Each worker job builds into its own detached `Node3D` holder (`holders[idx] = Node3D.new()`).
  - After `WorkerThreadPool.wait_for_group_task_completion(group)`, attach `holders[0..N-1]` children to `root` in **exact original order**, preserving node names, sibling order, and build-bench fingerprint byte-identity!
  - Check thread-safety of shared static material/mesh caches touched by props (`StreetProps._mats`, `ParkedCars._meshes`, `StreetFurniture._meshes`, `UtilityPoles._meshes`/`_mats`, `VesselMaterials._cache`, `VesselPrototypes._meshes`, `CarModel._meshes`, `TramModel._meshes`) — either pre-seed materials before the group or guard cache dicts with a lightweight `Mutex` (and verify with `tests/parallel_build_test.gd` serial == parallel!).
  - Respect any data dependency (e.g., if `wires` depends on `pole_plan`, run `pole_plan` first, then fan out the rest).
- **`ParkedCars` (`cars = 1,230–1,579 ms`, `scripts/generation/parked_cars.gd`):**
  - In `ParkedCars.plan()`, skip roads whose segment AABB is outside `centre ± RADIUS_M` before subdividing slots (saves ~70% of road iterations in dense cities).
  - In `ParkedCars._instances()` (or `build()`), populate `MultiMesh.buffer` directly with a flat `PackedFloat32Array` instead of per-instance `set_instance_transform` / `set_instance_color` / `set_instance_custom_data`.
  - Pre-warm/cache `CarModel` meshes once per process (already in `_meshes`, guard with `Mutex` if parallelized).

### 1.2 `GroundCover` (`cover = 1,574–2,423 ms` → ≤ 0.5 s)

- **Root cause (`scripts/generation/ground_cover.gd`):**
  1. `GroundCover.plan()` scans a ~500 m × 500 m grid at 2.1 m spacing (~56,000 cells on Ultra) serially in GDScript, calling `VegetationMask` + `GroundTruth.height_at_world` + satellite photo sampling per cell.
  2. `GroundCover._chunk()` calls `mm.set_instance_transform(k, ...)` and `mm.set_instance_color(k, ...)` one by one in GDScript for every tuft/flower/shrub instance.
- **Concrete fixes:**
  1. **Direct `MultiMesh.buffer` upload:** Replace per-instance `set_instance_transform` / `set_instance_color` loops in `GroundCover._chunk()` with a single flat `PackedFloat32Array` (16 floats/instance: 3×4 transform + RGBA), matching our proven `FarCanopy` pattern (which delivered a 5–7× speedup).
  2. **Row-parallel `GroundCover.plan()`:** Partition grid rows into deterministic strips across `WorkerThreadPool.add_group_task` and merge per-kind lists in strip order so output order and hashes are **100% deterministic** (AC-12).
  3. **Fast-reject empty rows/cells:** Skip `GroundTruth.height_at_world` and photo sampling when `VegetationMask` already marks a cell as hard/blocked.

### 1.3 `Roads` Sub-Stage Profiling & Targeted Optimization (`roads = 5,436–6,290 ms` → ≤ 2.8 s)

- **Root cause (`scripts/generation/road_builder.gd`):**
  - `RoadBuilder._roads()` already runs its main road-ribbon loop in parallel across `CHUNKS` with native `RibbonDraper`, **yet** the total `_roads()` call still takes **5.4–6.3 s** in Helsinki!
  - Currently `_roads()` emits only a single `"roads"` timing bucket, hiding whether the time is spent in:
    - `setup` (`_Surface.new`, `RoadMarkings.shared_plan`, `BridgeStructures.prepare`, `OverheadWires._centre_grid`, `StreetProps._road_grid`),
    - `chunks` (parallel `_road()` loop — e.g. `surf.in_square()` `Geometry2D.is_point_in_polygon`, `_district_finish`, `RoadCrossingClip._runs`),
    - `join` (`_batch.join` merging `PackedVector3Array`s across chunks),
    - serial post-passes (`RoadTapers.lay`, `BridgeStructures.build`, `RoadMarkings.lay`, `RoadPaint.lay`, `RoadGlyphs.lay`), or
    - `commit` (`b.mesh()` `ArrayMesh` creation + `StairBuilder.lay`).
- **Two-step approach (profile first, then cut the top 2 buckets):**
  1. **Step A1 (Instrument):** Add a compact `ROADS sub ms { setup, chunks, join, tapers, bridges, markings, paint, glyphs, commit, stairs }` log line in `RoadBuilder._roads()` and measure on Helsinki Ultra & Interlaken Ultra.
  2. **Step A2 (Optimize top 2 buckets):**
     - If `chunks` dominates: accelerate `surf.in_square()` / `_district_finish` (pre-filter by road AABB before per-point polygon checks, and avoid `Dictionary.duplicate()` per clipped segment) and/or move the hottest per-road clipping/offsetting into native `RibbonDraper` (aligning with `PLAN_Ultra_speedup.md` P3.3).
     - If `markings` / `paint` / `glyphs` / `bridges` dominate: parallelize independent post-pass builders (each into its own batch dict, merged in deterministic order) or eliminate redundant `GroundTruth` / `surf.height()` calls by reusing pre-sampled road profiles.
     - If `join` dominates: pre-allocate merged `Packed*Array` sizes instead of incremental `append_array` reallocations.

---

## 2. Workstream B — Zero-Leak Exit Audit (1,262 ObjectDB / 20 Texture RIDs / 7 Resources → 0)

### 2.1 Root-Cause Discovery Strategy

In `task-449`, exiting after a full Metal 4.0 Helsinki Ultra build reported:
```
ERROR: 8 RID allocations of type 'N10RendererRD14TextureStorage7TextureE' were leaked at exit.
WARNING: 20 RIDs of type "Texture" were leaked.
WARNING: 1262 ObjectDB instances were leaked at exit (run with `--verbose` for details).
ERROR: 7 resources still in use at exit (run with --verbose for details).
```

Two distinct buckets can contribute to those numbers:
1. **Test-harness teardown vs. real app exit:** In `capture_shopfront_closeup.gd`, `quit(0)` was called directly while `main` and `View360` were still in the tree (not via `NOTIFICATION_WM_CLOSE_REQUEST`). We must audit **real app shutdown** (where `Main` receives `NOTIFICATION_WM_CLOSE_REQUEST` / `tree.quit()` cleanly) separately from ad-hoc scripts.
2. **Genuine engine/script-retained static references:**
   - Global shader parameter textures set via `RenderingServer.global_shader_parameter_set(...)` (e.g. `street_lamp_settle`, `street_heights`, or any other texture global still bound when `RenderingDevice::finalize` runs).
   - Static `var`s in `scripts/` still holding `Texture2D`, `ImageTexture`, `ShaderMaterial`, `ArrayMesh`, `Shader`, `Font`, or `Node` references not yet cleared in `StaticCaches.release_all()` (for example: `RoadBuilder._stone_deck`, `ShoreBankMesh`, `GroundMaterial`, `WaterShader`, `GrassCards`, `BuildingBuilder`, `Landmark*`, `DatePicker`, `UiTheme`, `CompassDial`, `MapTileView`, etc.).
   - Detached `Node`s or `RefCounted` cycles (e.g. a `Callable` lambda holding a `Node` or `RefCounted` owner that references the `Callable` back — like `WorldStreamer._parked` avoided with a bound method!).

### 2.2 Concrete Execution Steps

1. **Step B1 — Repeatable `--verbose` Exit-Leak Audit Script (`tests/exit_leak_audit.gd`):**
   - Launches `res://scenes/main.tscn` off-screen (`--position 4000,4000 --verbose`), loads Helsinki (cached), triggers `View360` + `WorldStreamer` + `WeatherDressing`, then shuts down via the exact app close path (`main.get_tree().root.propagate_notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)` + `quit(0)`).
   - Captures and parses every `Leaked instance:`, `Resource still in use:`, and `RID allocations` line from the `--verbose` output.
2. **Step B2 — Eliminate Every Reported Leak:**
   - Add every remaining static `Resource`/`Texture`/`Shader`/`Material`/`Mesh` cache found in the `--verbose` dump to `StaticCaches.release_all()` (and clear `RoadBuilder._stone_deck = null`, `LandmarkImpostor` static textures, etc.).
   - Break any `Callable`/signal reference cycle keeping `Node`/`RefCounted` instances alive past `tree_exited` (verify `View360._exit_tree()` disconnects/clears any external references and frees detached helper nodes).
   - Clear any remaining `RenderingServer.global_shader_parameter_set(..., null)` texture globals before `RenderingDevice::finalize`.
3. **Step B3 — Automated Zero-Leak Regression Gate:**
   - Assert in `tests/exit_leak_audit.gd` (or a small wrapper command) that `--verbose` exit logs contain **0** `ObjectDB instances were leaked`, **0** `RIDs of type "Texture" were leaked`, and **0** `resources still in use at exit`.

---

## 3. Phased Implementation Roadmap

### Phase 1 — Instrument `Roads` + Run `--verbose` Exit-Leak Audit (Discovery)
- Add sub-stage timing breakdown inside `RoadBuilder._roads()`.
- Run `tests/exit_leak_audit.gd` with `--verbose` off-screen (`tools/godot_bg.sh --path . --position 4000,4000 --verbose ...`) on Helsinki Ultra to capture BOTH:
  - exact `ROADS sub ms` breakdown, and
  - exact list of every remaining leaked `ObjectDB` instance, `Resource`, and `Texture` RID.

### Phase 2 — Close All Remaining Exit Leaks (Workstream B)
- Fix every leaked static cache / global shader texture / detached node / reference cycle identified in Phase 1.
- Re-run `tests/exit_leak_audit.gd --verbose` and confirm **0 ObjectDB leaks, 0 Texture RID leaks, 0 resources still in use**.

### Phase 3 — Parallelize `PROPS` & Accelerate `GroundCover` + `ParkedCars` (Workstream A1–A2)
- Parallelize independent `StreetProps` builders across `WorkerThreadPool` with deterministic holder attachment order + thread-safe cache guards.
- Switch `GroundCover._chunk()` and `ParkedCars` MultiMesh fills to direct `PackedFloat32Array` `mm.buffer` assignment, plus row-parallel `GroundCover.plan()` and AABB road early-out in `ParkedCars.plan()`.
- Verify serial == parallel byte-identical fingerprints (`tests/parallel_build_test.gd`) and `tests/ground_cover_test.gd` / `tests/parked_cars_test.gd` (or relevant prop tests).

### Phase 4 — Optimize Top 2 `Roads` Sub-Stages (Workstream A3)
- Apply targeted optimizations to the top 2 buckets revealed by Phase 1's `ROADS sub ms` profiling.
- Verify `tests/road_markings_test.gd`, `tests/bridge_joint_test.gd`, `tests/bridge_structures_test.gd`, `tests/road_bridge_decks_test.gd`, `tests/shoreline_test.gd`, and `tests/parallel_build_test.gd`.

### Phase 5 — Final Verification & Before/After Benchmark
- Run `tools/check_class_size.sh` (all classes ≤ 1000 lines).
- Run all relevant headless tests + one off-screen Metal 4.0 Helsinki Ultra benchmark + `--verbose` exit-leak check confirming:
  - Helsinki Ultra parallel build **≤ 5.0 s** (down from 9.0 s),
  - **0** leaked `ObjectDB` instances / `Texture` RIDs / resources at exit,
  - `WorldCache` save succeeds cleanly under the `6.0 GiB` VRAM ceiling.

---

## 4. Risks & Safeguards

1. **Thread-safety in parallelized `StreetProps`:** Several prop builders share static `_meshes` / `_mats` dictionaries. *Safeguard:* Audit every static dict touched by each prop builder before parallelizing, guard with `Mutex` (or pre-populate before the group), and verify determinism with `tests/parallel_build_test.gd` (serial vs. parallel).
2. **`MultiMesh.buffer` stride mismatch:** `ParkedCars` uses `use_custom_data = true` (which makes stride **20 floats/instance**: 12 transform + 4 color + 4 custom_data, vs. 16 floats when `use_custom_data = false`). *Safeguard:* Check `mm.use_colors` and `mm.use_custom_data` explicitly and add a unit test comparing `mm.get_instance_transform(k)` / `mm.get_instance_color(k)` / `mm.get_instance_custom_data(k)` against the legacy API.
3. **Engine-internal Godot 4.7 leaks:** If any single leaked RID/resource comes from Godot's own Metal 4.0 / Forward+ internals rather than project GDScript, document it explicitly with the `--verbose` stack/class name rather than adding fragile workarounds.
