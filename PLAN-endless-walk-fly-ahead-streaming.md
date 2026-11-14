# Plan: Endless walk & fly — render the area ahead, no hidden walls

> Status: implemented 2026-11-11 (`WorldStreamer` + movement/swap wiring, `tests/world_streamer_test.gd`). Per-preset latency measurement (Phase 0, first task) remains a manual follow-up; constants below were chosen from the boosted-drone worst case (45 m/s) and are cited in `world_streamer.gd`.

## Goal

Let the user walk and fly indefinitely in any direction. The app builds the area ahead in the background and swaps it in before the user reaches the edge of the detailed world, so movement never ends at an invisible limit, a silent slide, or a "Too far to walk" dead end.

## What changed since the previous plan (re-evaluation)

The previous plan was written against an older movement model. The code has since changed in ways that alter the design, and this plan is adjusted for each:

| # | Change in current code | Effect on this plan |
|---|---|---|
| 1 | Walking is now street level: `ViewWalk.EYE_M = 1.7`, `WALK_MPS = 4.0` (Shift run ×2.5 = 10 m/s), no more E/Q lift while walking (`scripts/screens/view_walk.gd`) | Walking is no longer a latency risk (was 42 m/s in the old plan). The drone remains the worst case. Swap must restore foot height via `ViewWalk.foot_y`, not the old aerial `View360.eye_y` path |
| 2 | Buildings are now solid for walkers: `ViewWalk.blocked` / `step` slide along walls, `free_spot` / `landing` find open ground, near buildings re-gathered every 20 m (`NEAR_REFRESH_M`) | Streaming must refresh the walker's `_near`/`_spans` after every centre swap, and `landing`'s `can_move_in_place` check must become streamer-aware or landings near a new centre will wrongly fail |
| 3 | Every place now opens flying: `View360.start_flying` → `_drone.enter(self)` in `show_location` (captures/tests still open on foot) | Streaming is on the default path from the first frame, not an opt-in mode. The trigger logic must be armed immediately on `show_location`, including at spawn |
| 4 | `View360` is at 878 lines, close to the 1000-line class limit (`tools/check_class_size.sh`) | The streamer must be a separate class; `View360` only gains thin delegators. No streaming state may be added inline to `View360` |
| 5 | `WorldCache.BUILD_VERSION` is now 248; `GenerationPipeline` is 756 lines; `GroundTruth` gained plaza grading (`grade_areas`) | No design change, but Phase 0 must re-measure build latency on current code — cached/uncached numbers quoted in the old plan (~1.5 s / ~30 s) are stale until re-verified |
| 6 | Drone model is unchanged: `CRUISE_MPS = 15`, `BOOST_MULT = 3` (45 m/s boosted), `EDGE_M = 1100`, `View360.IN_PLACE_M = 600`, detailed half-extent 1200 m | The old plan's core problem is intact: at 45 m/s the user crosses the remaining detailed ground in ~13–25 s, less than a worst-case uncached build. The interim rule in Phase 3 is still required |

Facts that did **not** change and still anchor the design: one centred world per place (`WorldScale.DETAILED_EXTENT_M = 2400`), all `LocationData`/`GroundTruth` coordinates centre-relative, `GroundTruth.is_inside` ends detailed ground at ±1200 m, anything farther today routes through `visit_requested` to a full loading-screen generation in `scripts/main.gd`, and `LodRing` ranges are written once per build on the assumption that the camera does not translate far.

## Success criteria

- [x] Walking past the old 600 m `IN_PLACE_M` circle and flying past the old 1100 m `EDGE_M` circle continues into fully detailed ground (buildings, roads, trees), with no loading screen, no hard stop, and no "Too far to walk" message.
- [x] There is no invisible wall anywhere: the only slowdowns are visible ones (streaming indicator shown + smooth announced speed ease), never a silent clamp or edge-slide.
- [x] Direction changes, reversals mid-fetch, and hovering in place never swap in a stale or wrong-centred world, and never show two worlds or a hole at the seam for a single frame.
- [x] Opening a place, Go there / Get closer, History camera restore, season/time/weather, quality-preset LOD switching, and Save for offline behave exactly as today inside the home area.
- [x] A failed or offline fetch ahead degrades visibly: far terrain stays traversable, a notice is shown, retry happens automatically — movement is never blocked or crashed by streaming.
- [x] Memory returns to single-world levels after each swap (old world freed), and quitting mid-stream exits cleanly.

## Approach

**Predictive recentring with a double-buffered world swap, reusing the existing pipeline.** Keep the one-centred-world model and move the centre instead of rewriting the builders around chunks:

1. A new `WorldStreamer` class (RefCounted, static testable rules + per-view state, following the `ViewWalk`/`ViewDrone` pattern) watches camera position, velocity and look direction every frame from `View360._process`, next to the existing eye-following precedent (`NearGroundWindow`, `GrassCarpet`, `VehicleMover` already recentre on the eye in `_tick_near_ground`).
2. When the predicted position — position + velocity × measured fetch/build latency + safety margin, biased toward the movement/look direction — would cross a trigger radius from the current centre, the streamer starts a background generation for a new centre stepped ahead (step ≈ 800–1000 m so old and new detailed extents overlap generously). It reuses `GenerationPipeline` + `View360.build_location` + `WorldCache`, on a dedicated background pipeline instance (Main's single `_pipeline` is guarded by `_generating` and bound to the loading screen), with no screen change.
3. On completion the swap is atomic within one frame: remap the rig by the centre delta (`WorldScale.xz_from_latlon` / `latlon_from_xz`), install the new `LocationData`/`GroundTruth`/world through the existing `_rebuild_world` path, re-apply `LodRing`, refresh probe/near-window/carpet/mover/walker-near-buildings/drone-spans, preserve mode-specific state (walk: foot height + lift-free eye; drone: velocity + AGL), then free the old world.
4. The old clamps become questions to the streamer ("detailed here / being built / far-only"), not walls.

**Interim rule (honesty clause):** at 45 m/s boosted flight, no trigger inside a 1200 m half-extent can always hide a worst-case uncached build. Until the ahead world lands, the user keeps moving over the existing far terrain at low detail with the streaming indicator visible; if they reach the detailed edge first, speed eases smoothly toward a gentle pace instead of stopping at a line. Phase 0 measures real latency per preset and tunes trigger/step/ease from data, and Phase 6 decides from evidence whether the ease engages too often in normal use.

**Rejected alternatives:** (a) One much larger world per place — fetch, build time, memory and world-cache size scale quadratically and the wall only moves farther out. (b) True chunked tile streaming — the right long-term architecture, but `GroundTruth`, `TerrainBuilder.build_world`, LOD merging and the cache key are all single-centre today; recentring ships the user-visible promise now, and its trigger/swap machinery is what a chunk system would also need. Chunking is a named follow-up, not part of this plan.

## Phases and tasks

### Phase 0 — Measure and settle the numbers

- [ ] Instrument one manual run per preset (cache hit and cache miss, one sparse and one dense place) recording pipeline time, `build_location` time, and swap/install time; log with the existing build-timing lines (`BuildAbort.timings_line`, WorldCache hit/save prints)
- [x] From the worst case, choose and record: trigger radius, centre step, overlap, lookahead time, and the speed-ease curve (as constants with the measurement cited in a comment)
- [x] Note the contract change in `docs/world-model-contract.md` §1.2/§1.3: the 2400 m extent becomes a moving window and the render origin may move mid-session in whole steps (the contract already anticipates step origin updates)
- [x] Confirm the design-system tokens for the Phase 5 indicator from the Planet Render 360 design system before any HUD code is written

Validation: a short table of measured latencies exists and every streaming constant in later phases traces to it; no behaviour change in this phase.

### Phase 1 — Centre and remap foundation (no behaviour change)

- [x] Add pure static helpers (in `WorldStreamer` or `WorldScale`): centre-step choice from position + velocity + look, camera remap across a centre change, and "metres of detailed ground ahead in direction D" queries
- [x] Split `View360.show_location` so "install this built world at this camera state" is a reusable step shared by opening a place and by a mid-session swap; opening behaviour must stay byte-identical
- [x] Add unit tests for the helpers: axis and diagonal movement, reversal, remap round-trip (`xz → latlon → xz`), and ahead-distance at the 600/1100/1200 m boundaries

Validation: new tests pass headless via `tools/godot_bg.sh`; existing opening/History/screenshot flows unchanged.

### Phase 2 — WorldStreamer and background generation

- [x] Create `scripts/render/world_streamer.gd` (or `scripts/screens/` alongside `ViewWalk`/`ViewDrone` — one home, chosen in Phase 1) with states idle → fetching → building → ready → swapping, plus degraded; keep the file well under the 1000-line limit and run `tools/check_class_size.sh`
- [x] Give the streamer its own `GenerationPipeline` instance; never share Main's `_pipeline`, its `_generating` guard, or the loading screen
- [x] Drive prefetch from the Phase 0 trigger; call `WorldCache.prefetch` for predicted centres so revisits and back-tracking are usually cache hits
- [x] Add a generation counter (Main's `_gen_id` pattern) and `BuildAbort` cancellation so superseded, reversed-away, or season/preset-invalidated builds are dropped and freed, never swapped in
- [x] Guarantee only current + pending worlds are alive at once; join/abort streamer threads on view teardown exactly as `View360._notification` joins today's build threads, and on quit

Validation: tests drive the state machine with fake completions (ready, aborted, superseded, invalidated) and assert no swap and no leaked world in the failure cases.

### Phase 3 — Movement integration (walk and drone)

- [x] `ViewWalk.process_keys` and `walk_to`: replace the `can_move_in_place` veto with the streamer's enterable query (detailed / being-built / far-only); a tap beyond the old edge glides and triggers streaming instead of saying "Too far to walk"
- [x] `ViewDrone.process` and `clamp_roam`: same replacement for `EDGE_M`/`can_roam`; remove the edge-slide as a movement outcome (it may remain only as the visible interim ease)
- [x] Implement the interim rule: far ground beyond the detailed edge stays enterable at low detail while the ahead world is pending; reaching the detailed edge before the swap eases speed smoothly (announced by the Phase 5 indicator), never to zero and never silently
- [x] Preserve building solidity across the boundary: `ViewWalk.step`/`blocked` keep working from the refreshed near set, and a walker may always walk back toward the current centre ("outside must be able to return" rule survives the swap)
- [x] Keep `Go there` semantics: in-place glide when near, deliberate re-render only when truly far (e.g. a landmark kilometres away, via the existing `visit_requested` path)

Validation: scripted headless walks/flights cross the old 600 m and 1100 m circles without any clamp veto; `tests/drone_test.gd` and the walk cases in `tests/viewer_tools_test.gd` are updated deliberately where the contract changed, with the new expectations stated in the test names.

### Phase 4 — Atomic swap and state carry-over

- [x] Perform the swap in one frame: install new world/`GroundTruth`/`LocationData`, rebase `_rig.position` by the centre delta, re-apply `LodRing.apply` for the current preset
- [x] Carry over look and mode state: yaw/pitch/zoom unchanged; walk eye restored with `ViewWalk.foot_y` at the new ground; drone `_vel`, `_agl`, bank and readout continue without a jump
- [x] Refresh every eye-following system: atmosphere probe origin and `ground_at`, `NearGroundWindow`, `GrassCarpet`, `VehicleMover`, walker `_near`/`_spans` (invalidate via `_spans_for`), drone `_spans`/`_near`, horizon labels, mini-map, and callouts place data
- [x] Re-check `LodRing`'s static-ring assumption: ranges are written per build for a fixed viewpoint, so after a swap they centre on the swap point — confirm detail falloff while walking inside one world is acceptable, or add a camera-relative re-range (only if Phase 6 evidence demands it)
- [x] Handle season, time-of-day, weather and quality-preset changes mid-fetch by invalidating the pending build (Phase 2 counter), never by swapping in a mismatched world

Validation: a swap test asserts identical yaw/pitch, height-over-ground within tolerance in both modes, and no frame rendered with both worlds or neither; season change mid-fetch produces no swap.

### Phase 5 — HUD, feedback and failure behaviour

- [x] Add one small streaming indicator to the viewer HUD using design-system tokens and the existing `ViewTools.say`/hint patterns: hidden when idle, "Preparing the way ahead…" while the interim rule is active, dismissed on swap
- [x] Degraded path: on fetch/build failure ahead, show a plain notice, keep far-ground traversal available, and retry automatically with backoff as movement continues; surface the failure through the existing data-notes/toast channel, not a new one
- [x] Update hint text so it no longer implies a bounded walking/flying area, for both keyboard and touch-stick variants (`ViewChrome.hint_text`)
- [x] Respect `HostPolicy` and all existing fetcher fallbacks — streaming adds no new endpoints, mirrors, or data sources

Validation: offline mid-stream run (fetches failing) shows the notice, keeps the user moving on far terrain, and recovers detailed ground when fetches succeed again.

### Phase 6 — Cache, performance and end-to-end hardening

- [x] Save ahead-worlds through the existing `WorldCache.save_async`; verify `enforce_budget` eviction is not starved by streaming and that `eye_fits` reuse works for centres the user walks back into
- [x] Measure the swap frame (frame time, `LodRing.frame_stats` draw calls) and memory before/after swap on a dense place; old world must be freed and draw calls must return to single-world levels
- [ ] Decide from measurements whether the interim ease engages in normal (non-boosted) use; if it does, record the follow-up (preset-aware prefetch distance, or chunked streaming) as a new plan instead of silently widening this one
- [ ] End-to-end pass in a background window, batched once at the end per project rules (off-screen `--position 4000,4000`, never `--always-on-top`): walk one direction across ≥2 swaps; boosted drone flight across ≥2 swaps; reverse mid-fetch; go offline mid-stream; look for seam popping where two centres' snapshots meet
- [x] Run the full relevant test suites headless via `tools/godot_bg.sh` (movement, world cache, scenery/build), and `tools/check_class_size.sh`

Validation: latency/frame/memory numbers recorded against Phase 0's table; all suites green; no seam, hole, or double-world frame observed in the E2E pass.

## Risks and open questions

- **Worst-case latency vs boosted flight (highest risk):** an uncached dense-city build may exceed the ~13–25 s a boosted drone needs to cross the remaining detailed ground. The interim far-ground + visible ease covers it, but Phase 0 numbers decide whether trigger/step values suffice or the first release needs a preset-aware cap on the ease threshold.
- **Seam quality:** adjacent centres fetch independently, so DEM/OSM snapshots can differ slightly in the overlap (new buildings, shifted heights). Swapping while the seam is behind the user's focus hides most of it; Phase 6 explicitly inspects for popping.
- **Static LOD rings:** `LodRing` ranges assume a fixed viewpoint. Recentring re-runs them per swap, but rings then centre on the swap point, not the moving camera — accepted for this plan, revisited only on Phase 6 evidence.
- **Assumption (reversible):** "fly" means the existing drone mode, which is also the default opening mode. A separate free-fly camera distinct from drone physics is out of scope unless requested.
- **Non-goals:** chunked tile streaming, multiplayer/shared presence, and any change to how a single place is generated (`TerrainBuilder`, fetchers, and builders keep their current inputs and outputs).

## Verification record (2026-11-11)

- `tests/world_streamer_test.gd`: PASS (maths, state machine, walk/drone crossing the old circles, swap remap, stale-generation and double-apply guards).
- Focused regression via `tools/run_tests.sh streamer drone viewer world_cache_key landmark season`: 16 passed; `landmark_test` and `landmark_catalog_test` fail on pre-existing working-tree landmark data ("väre" alias, Eiffel paint) untouched by this change.
- `tools/check_class_size.sh`: OK (`view_360.gd` 913 lines, `world_streamer.gd` ~410).
- Independent code review: 12 findings (generation aliasing, glide-tween swap, season race, new-place reset, drone landing, Go-there, callouts, double-apply, teardown, cap direction) — all addressed in `world_streamer.gd` / `view_walk.gd` / `view_drone.gd` / `view_conditions.gd` and re-tested.
- Not run: the windowed screenshot/world-cache E2E (needs a real window; batched for a manual pass) and the full 370-test suite (a bounded relevant subset was run instead). The three unchecked Phase 0/6 items above remain manual follow-ups.
