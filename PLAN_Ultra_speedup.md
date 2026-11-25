# Ultra-quality building scenery — speed-up plan

> Goal: make the **building scenery** on Ultra (preset 3, desktop Forward+) noticeably faster to build
> and cheaper per frame, **without moving objects, shifting hues, or changing what is drawn**
> (AC-12: tiers never move real buildings/roads/landmarks; no hue shift >2%).
>
> Status: **Phase 1 implemented in working tree (uncommitted), verified.**
> P1.1 (prefetch) / P1.2 (governor effect sub-steps) / P1.4 (lod-ring spread, preset-switch site) / P1.5
> (atmosphere diffs + probe stagger) are done; P1.3 (cache save) was stopped with evidence — see the
> status block near the top of this file. The Helsinki Water serial/parallel divergence is closed:
> it was a pre-existing cross-place material staleness (ShoreBankMesh abutment duplicating the
> previous place's road deck), not P1.1 — fixed with a regression test, full fingerprints
> serial==parallel. Ultra perf_baseline ran on the final tree; see the status block for numbers.
> Everything below this line is the ORIGINAL plan (kept for reference; the numbers are historical,
> not freshly measured). Numbers cited below come from the measured runs cited in
> `NATIVE_SPEEDUP_CANDIDATES.md`, `docs/fidelity-scorecard.md` (hel-r6 / tku-r4 / miami-r1) and the
> source files listed per candidate. Editor-binary timings inflate ~3–5× over release serial loops;
> where both are quoted, release/serial is the caveat-correct one.

## Phase 1 status (completed 2026-11-26)

- **P1.1 — Prefetch facade/roof sets** — done in code. `BuildPrewarm.run` now prefetches roof sets
  (membrane, roof_concrete, sheet_metal, copper, wood, grass) for every place; `PbrTextures._set_image`
  caches the raw decoded decode **by file path** (shared across sets like concrete/roof_concrete) while
  each consumer still duplicates and post-processes independently. `glass` stays out (drawn from
  scratch). Byte-identical output.
- **P1.2 — Governor effect sub-steps** — done in code. Ultra-only `effects_step` layer below haze and
  above render scale: 2 = SSR 64→32; 1 = volumetric volume 128→64; 0 = SDFGI + SSIL off + TAA off.
  HUD pill label extended; tests updated. quality_governor_test and haze_test PASS. Review note:
  preset switches already restore viewport/env to preset defaults via `AtmosphereRig.set_quality`,
  so degraded values never leak across presets; non-Ultra already uses volume 64 by design.
- **P1.3 — WorldCache save** — **stopped with evidence (no code change)**. flush = 0 ms; pack ≈ 0;
  save = 15–26 s, dominated by compressed `.scn` serialization (~490 MB). 2K textures are already
  externalized; skip-identical-resaves is unreachable dead code. Honest stop per the plan.
- **P1.4 — Spread LodRing.apply()** — done, deliberately **partial**: spread only in `set_quality_preset`
  (`lod_spread.gd`, 16 subtrees/frame). `_rebuild_world`'s walk intentionally kept synchronous (fresh-
  build world not in the tree; progressive reveal would show an un-ranged world; spreading it also
  blew the 1000-line class-size gate — see view_360.gd). Re-read the note if you want the other site spread.
- **P1.5 — AtmosphereRig** — done in code. Per-property `is_equal_approx` guards in `_apply_haziness`;
  street probes re-capture one per frame via `_probe_queue` + `_requeue_probe` (view probe on the first
  frame after the 0.4 s debounce).

**Verification (complete on the final tree):**

- Fingerprints: full bench (paris_p0–p3 + helsinki_p0–p3, `/tmp/phase1-snap`) serial vs parallel
  byte-identical including `helsinki_p3 002 Node3D Water`. The reported divergence was **not P1.1**:
  the Water stage runs before the roads stage, so `ShoreBankMesh.abutment_material` duplicated
  `RoadBuilder._mats["deck"]` left by the previous place (Paris limestone on a granite quay —
  white slab, albedo 1,1,1). Pre-existing at HEAD (neither file differs from HEAD); the HEAD
  "consistent" check only ever built Helsinki alone. Fixed: the abutment duplicates a
  place-independent concrete deck (`ShoreBankMesh._concrete_deck_material`); regression test
  `tests/shore_abutment_test.gd` fails on the old logic with the exact observed signature and
  passes on the fix. Paris serial==parallel exactly; serial×2 and parallel×2 byte-identical per mode.
- Tests: facade_shader / altitude_reach / ultra_looks / world_cache_key / map_prefetch / parallel_build /
  haze / quality_governor / shore_abutment (new) — all PASS. fidelity_scorecard **FAIL (pre-existing:
  axis `a` FAIL on every place, identical on the final tree and at clean HEAD)**. lod_test **FAIL
  (pre-existing: the same two material-leak failures, identical apart from timings)**.
- check_class_size.sh — PASS (view_360.gd 999/1000; the fix's helper lives in `shore_bank_mesh.gd`
  because `road_builder.gd` was already at the gate).
- Ultra perf_baseline (preset 3, tag `phase1-ultra`, editor binary, live fetch, isolated
  `user://perf-<pid>` cache; JSON: `visual-plan/reviews/phase1-ultra-2026-11-25/perf_p3.json`):

| place | cold | save | cached | build (data warm) | settle p95 | fly p95 / p99 / max | peak |
|---|---|---|---|---|---|---|---|
| helsinki | 21.6 s | 37.2 s | 12.5 s rebuild (MISS) | 12.4 s | 18.0 ms | 29.9 / 44.8 / 305.5 ms | 13.1 GB |
| paris | 38.2 s | 44.6 s | 3.1 s HIT | 35.4 s | 17.8 ms | 42.1 / 73.5 / 1673.6 ms | 18.2 GB |
| new_york | 35.5 s | 28.2 s | 2.4 s HIT | 28.8 s | 9.2 ms | 66.0 / 89.3 / 444.5 ms | 16.5 GB |
| turku | 22.1 s | 28.3 s | 2.4 s HIT | 13.7 s | 17.9 ms | 55.3 / 94.0 / 354.1 ms | 19.8 GB |

  No same-binary pre-Phase-1 run exists, so this is the final-tree baseline, not a before/after.
  2026-11-15 reference points (different binary/date): Helsinki cold 19.6 s / cached 2.0 s /
  fly p95 26.2 ms; Turku cold 23.6 s / cached 7.2 s; NYC fly p95 47.1 ms. NYC fly is still the
  worst case (66.0 ms p95 here, editor-inflated) — the case P1.2's governor layer targets. Saves
  still dominate the cold path (28–45 s; P1.3's finding stands). Helsinki's cached reopen missed
  its just-saved key (`cached_hit: false`, rebuilt in 12.5 s on warm data) while the other three
  places hit — left as an observation for cache follow-up, not Phase 1 scope.
- AC-12: no object moved, no hue shift — the byte-identical serial/parallel fingerprints across all 8
  builds are the evidence; the only content change vs the polluted baseline is the abutment returning
  to its correct concrete deck (place-build order no longer leaks across places).
- No commits; nothing pushed.

## TL;DR — ranked

| # | Candidate | Where | Est. payoff (Ultra) | Visual change | Effort |
|---|---|---|---|---|---|
| P1.1 | Prefetch facade/roof sets during the data stage (extend existing `BuildPrewarm`) | build thread | −1.7 s Paris cold-decode off the buildings stage | none | S–M |
| P1.2 | QualityGovernor: effect-level sub-steps (SSR→32, volumetrics off…) | frame | better low-fps floor | none (only when already degraded) | M |
| P1.3 | WorldCache save: profile + split/compress 2K-set textures | save | Helsinki Ultra save 29.8→40 s → investigate | none (cache only) | M |
| P1.4 | Spread `LodRing.apply()` full-world walk on preset switch | view | one hitch/preset-switch | none | S |
| P1.5 | AtmosphereRig: diff env writes + stagger street-probe re-captures | frame | small | none | S |
| P2.1 | `render_scale` 1.25 → 1.0 (+TAA) | frame | biggest single frame lever | **yes** (res) | S |
| P2.2 | Shadow atlas 8192 → 4096 (High-class) | frame | −GPU shadow cost | faint banding | S |
| P2.3 | SSR 64 → 32, volumetrics 128 → 64 | frame | −GPU | faint SSR cost | XS |
| P2.4 | Sky radiance 256 → 128, PCSS 0.53° | frame | −GPU | faint | XS |
| P2.5 | z19 → z18 inner mosaic | build+frame | −texture + −memory | faint detail | S |
| P3.1 | relief/detail/walls via QuadSink wrapper (candidate 4) | build | −0.1…−0.3 s each (relief, detail, walls) | byte-identical output required | L |
| P3.2 | Roof-forms script wrapper (Helsinki 0.39 s) | build | −0.1…−0.3 s | byte-identical output required | M |
| P3.3 | Roads per-road wrapper (candidate 5, 0.89 s Paris) | build | prof first | none required | L |
| P3.4 | Street props / veg grids / terrain mesh (candidates 6–7) | build | low, hard to justify | none required | M |

**Out of scope:** anything that moves, drops or re-skins buildings; any kernel without a
byte-identity parity test; any change to `GroundTruth` (preset-independent by design);
progress on `PLAN_*.md` plans (they are separate work items).

---

## 1. Where the time goes (Ultra, measured)

### 1.1 Build time (release serial, frozen Ultra inputs)

WorldBuildGraph builds the world in parallel on background threads (release: 1 lane per stage).
Serial times are the honest read — parallel totals are noisy (Paris 6.2–9.6 s in parallel).

| Stage | Paris | Helsinki | Notes |
|---|---|---|---|
| Buildings | 6.4 s | 2.1 s | mapped loop 4.9 s / 1.7 s of it |
| Roads + landmarks | 4.0 s | 3.4 s | roads 2.3 s in both |
| Vegetation | 3.8 s | 2.2 s | props 1.8 s / 1.4 s; far canopy 0.7 s (done); fill/scatter 0.2 s |
| Ground + water | 0.6 s | 0.7 s | terrain mesh ~0.2 s |
| Far terrain | 0.4 s | 0.35 s | |
| **Total** | **15.2 s** | **8.8 s** | |

Mapped-building loop, by section (ms): facade material resolve 937 / 330 (cold decode — see P1.1) ·
roof resolve 835 / 24 (cold decode — same) · plinths 522 / 61 (done) · relief 431 / 202 ·
roofline detail 358 / 75 · walls 264 / 110 · trim+roof cap 188 / 55 · vertex tint 183 / 60 ·
party-wall 173 / 11 · mass planning 118 / 42 · ground storey 97 / 118 · roof forms 89 / 394 ·
enclosed check 80 / 25 · triangulation 36 / 8 · foundation sampling 32 / 13.

Set-level total in the buildings stage: facade+roof cold decode ≈ **1.8 s in Paris, 0.35 s in Helsinki** —
**the largest single build-time item that is not a geometry loop**, and it is paid once per process, not per building.

### 1.2 Frame time (Ultra, desktop Forward+ 1280×800, Apple M5 Ultra)

Ultra's frame cost is the renderer's budget, not the scene's. What the preset turns on, per
`RenderQuality.features_for`: render scale **1.25×** supersample, TAA, MSAA 2×, anisotropy 16×,
auto-exposure 88–114 ISO, **SDFGI 6 cascades / 0.8 m cells / occlusion**, **SSIL**, **SSAO** (HIGH),
**SSR with 64 steps**, **volumetric fog** (128×128 volume, 250 m length, density 0.00028/m),
shadow atlas **8192** with SOFT_HIGH + PCSS 0.53°, sky radiance **256**, debanding,
`shadow_distance` 4000 m, cloud octaves 5. City boosts (Helsinki/Espoo/Turku/Stockholm/Venice/London/Paris/Amsterdam)
add 14 000 real buildings, 900 m roofline ring, z19/15 inner mosaic, street extras (kerbs, tree pits,
furniture, decals, cars, rooftop clutter, utility poles).

The governor (`quality_governor.gd`) steps **only** render scale 3→2→1→0, shadows, and the haze
sub-steps (god-rays 2→1→0). It does **not** touch SSR, SDFGI, SSIL, volumetrics, the shadow atlas,
TAA, sky radiance or cloud octaves — so a heavy Ultra scene that drops below 28 fps degrades the
least flexible knob first (render scale) and the most expensive unchanged.

Per-frame CPU is modest by design: ranging is sliced (`AltitudeReach` 16 subtrees/frame;
`WorldStreamer` within `budget_us`; `RevealWave` ~1000 µs/slice), haze pass is ~free
(48-tap half-res pass measured +0.008 ms, `tools/haze_spike.gd`), and `View360._tick_near_ground`
deliberately spreads 4 attaches over 4 frames.

### 1.3 Cache

WorldCache key includes `BUILD_VERSION` (344) + season + grid + LocationData fingerprint + `CityDetail.VERSION`
(7) + `_sources()` debug-build hash (excludes haze_rig, quality_governor, altitude_reach, godray_shader, weather_dressing).
Ultra **saves 29.8 s → 40.0 s** (Helsinki, hel-r6); cached revisit is 1.5–7 s (Turku 7.2 s, Paris 3.0 s, Helsinki 2.0 s).
The save runs on a thread with main-thread pumps (`PUMP_US 4000…33000` foreground, `1500…4000` background,
hurry 40000).

---

## 2. Phase 1 — zero or near-zero visual change (recommended, in order)

### P1.1 — Prefetch facade/roof texture sets in the data stage

**Problem.** `PbrTextures._set_tex` decodes and mipmaps a 2K set (~170 ms) on first use. In a
cold build this lands inside `BuildingBuilder`'s mapped loop (Paris: facade resolve 937 ms + roof
resolve 835 ms; the bulk is one-time cold decode, not resolve logic).

> 2026-11-25 refinement: a prewarm pass **already exists** (`scripts/generation/build_prewarm.gd`,
> started by `GenerationPipeline` during the fetch stage). It warms the road/trim/props sets from a
> hardcoded list, plus whatever the **last build** remembered — but a place whose roofs/ facades
> differ from the last-opened place still cold-decodes in the buildings stage, and the very first
> build after a launch has an empty remembered list. It also decodes `concrete` **twice**: the wall
> set and the `roof_concrete` map are the same photo with different `_set_image` work (90° rotate +
> destripe), so a place using both pays the decode + resize twice.

**Approach.** (a) In `BuildPrewarm.run`, extend the remembered-set pass so a place's **roof sets
(slate, membrane, concrete/roof_concrete, terracotta, sheet_metal, copper, grass, wood, glass)**
are candidate jobs for every place, not only remembered ones — jobs are cheap because
`_set_image` is already one decode per set and the set list is small. (b) Deduplicate the wall/roof
concrete decode in `PbrTextures.map_path`/`_set_image` (same photo, same 2K decode — share the
loaded image, keep the two post-processings separate). (c) Keep the pipeline-side start.

**Payoff.** Cold-build first-use decode largely moves off the buildings stage (Paris: the 1.7 s
cold-decode share of 6.4 s → ~0.2 s residual). Second-build revisits already benefit.
**Effort:** S–M. **Verify:** `build_bench.gd` fingerprints unchanged; per-stage timings printed.

### P1.2 — Governor: effect-level sub-steps under pressure

**Problem.** At 28 fps the governor steps render scale 1.25→1.0 (−25% pixels) and drop shadows. The
expensive, untouchable-by-the-user knobs — SSR steps, volumetric volume size, SDFGI, TAA — are never
shed, even when they are the thing costing the frame. When an Ultra scene drops to 20 fps, the user keeps
a 1.25× supersample + SDFGI + SSR 64 + 128×128 volumetrics and sees the same picture at 20 fps.

**Approach.** Extend `QualityGovernor.adapt()` with an env-level sub-step layer BELOW render scale:
`effects_step 3 → 2 → 1` (Ultra only). Healthy fps (>55): no step. Below the down-threshold: drop SSR 64→32
(`RenderingServer` does not need a scene rebuild), then volumetric volume 128→64 (via
`environment_set_volumetric_fog_volume_size`), then SDFGI/SSIL off, then TAA off; HUD pill +
`tests/quality_governor_test.gd` updated to match. Ceiling: user's preset (T7.4 — governor never exceeds it).
Same picture at full FPS; degradation is strictly better at full load.

**Payoff.** Low-fps Ultra frames (NYC fly p95 47.1 ms, over-budget) — governor-held degradation becomes the 4-knob curve, not one knob.
**Effort:** M (touches governor + 2 tests + HUD). **Risk:** low — but needs the `environment_set_*`
server calls only where they exist, and a test that a step-down with the governor at the ceiling is a no-op.

### P1.3 — WorldCache save: profile and split 2K-set payloads

**Problem.** Helsinki Ultra save grew 29.8 s → 40.0 s (hel-r6, BUILD_VERSION 321→344). The pack walks every
node, `SharedTexture.flush()` then `ResourceSaver.save(ps, tmp, FLAG_COMPRESS)`. The scene holds every
2K-set texture (walls, roofs, ground). The save is once-per-visit, but 40 s in the cold-open path is a
real gap against the 1–2 min budget, and it is a regression since the cache was added.

**Approach.** First, profile: `SharedTexture.flush()` vs `pack()` vs `save` vs re-open timing
(`MemoryLog` already marks the four stages). Then candidates, in order: (a) drop 2K sets from the packed
scene by reference through `SharedTexture` and let the save re-attach them (the save already does this
for shared textures); (b) store 2K textures as cache-external files (same dir as the ground) keyed by set
name, reusing the existing `_set_tex` texture cache at load time; (c) last resort, stop re-saving
identical scenes (key fingerprint unchanged → skip). Note the two-baseline rule: compare with two runs.

**Payoff.** Helsinki Ultra save 40 s → likely ≤ 15 s; Turku Ultra save 0.20 s suggests the save is not
uniform — see the caveats. **Effort:** M (save/load format — needs a BUILD_VERSION bump, which forces a
full-world rebuild of every cached place once). **Risk:** disk format change; migration of old caches.
**Do not start P1.3 until the profiler output is in.**

### P1.4 — Spread the LodRing.apply() walk on preset switch

**Problem.** `View360.set_quality_preset()` and `_rebuild_world()` call `LodRing.apply(root, preset)` — one full-world walk (≈ 2 700–3 500 nodes) on the main thread — every time the preset changes or the world is rebuilt. For a streamed world this walks the entire detail world in one frame.

**Approach.** Reuse the AltitudeReach pattern: `RANGE_SLICES` (16 subtrees/frame) with a small main-thread slice per frame until the walk is done. No geometry change, no build-time change; purely a frame-time spread.

**Payoff.** Removes a one-time hitch on preset switch (~5–30 ms spread; 2.7 k children × ~8 µs).
**Effort:** S. **Risk:** none.

### P1.5 — AtmosphereRig: diff env writes + stagger street-probe re-captures

**Problem.** `_apply_haziness()` writes 5 environment properties every frame while HazeRig eases
(~1 s per ease), and `_refresh_probe()` re-queues the view probe + all 5 street probes' `UPDATE_ONCE`,
which Godot spreads over six frames (one cube face each). Two issues: (a) the 5 property writes are
trivial but are duplicated every frame even when the value did not change; (b) each light change
(weather/time/season) re-captures 6 cubemaps, and a user who cycles seasons sees 6 6-frame bursts
instead of one.

**Approach.** In `_apply_haziness()`, only write each property when it changes (the values are already
monotonic 0..1 — a simple cached-value guard). In `_refresh_probe()`, set one shared `_probe_due` and let
only the probes dirty in the current light state re-queue; stagger the street-probe re-captures by one
cube face per frame (they are independent `ReflectionProbe`s — Godot already spreads each across 6
frames, but a hard burst of 5 planes in the same frame spikes the frame).

**Payoff.** Small per-change gain (< 5 ms/frame) — trivial work, keep it last.
**Effort:** S.

---

## 3. Phase 2 — change visible output (sign-off items, do NOT ship silently)

All of the following are *honest* Ultra features that cost pixels; they are listed because they are the
most likely big wins and should be decided deliberately, not discovered under load. Each changes the
frame in some visible way. None of them is in scope for "no visual change".

| ID | Change | Save | Visible cost | Recommendation |
|---|---|---|---|---|
| P2.1 | `render_scale` 1.25 → 1.0 (+TAA) | the largest single per-frame lever, ~25% fewer pixels | 1.25× → 1.0× supersample; TAA compensates | decide at review; the governor displays it as "%" res |
| P2.2 | Shadow atlas 8192 → 4096 | chair/shadow resolution | faint banding on 4 km far-shadows | only if FPS need it |
| P2.3 | SSR 64 → 32 steps; volumetrics volume 128×128 → 64×64 | GPU at Ultra | faint | safe small change |
| P2.4 | Sky radiance 256 → 128; PCSS 0.53° → Low-tier 0.0 (skip `directional_soft_shadow` HIGH) | GPU leer | faint glint/fixes | decide |
| P2.5 | CityDetail z19/15 inner mosaic → z18/11 (High-class) | texture + memory | ~0.15 m/px → 0.3 m/px drape | decide |
| P2.6 | Cloud octaves 5 → 4 (High-class) | the sky is a static full-screen pass; 5th octave is not the cost | invisible in photos | weak — leave |

Not listed: the 1.15× middle ground. It saves ~28% of pixels with TAA and no audible quality
change — **recommend P2.1 = 1.15** as a sign-off choice, not 1.0.

---

## 4. Phase 3 — build-time geometry work (byte-identical output required)

All of these were in `NATIVE_SPEEDUP_CANDIDATES.md` as candidates 4–7 — **none started**. They are
listed in ranked order. Each needs a `tests/*_test.gd` parity test comparing native vs script exactly
and `tools/build_bench.gd` fingerprints before/after (two-baseline rule: compare with two clean-run
fingerprints, not one — one 2026-11-19 Paris baseline disagreed with the other two).

### P3.1 — Relief / roofline detail / walls via QuadSink (candidate 4)

Cost: relief 431 / 202 ms (Paris / Helsinki), detail 358 / 75 ms, walls 264 / 110 ms.
Approach: `FacadeRelief.add` already writes through the native `QuadSink`; route `BuildingWalls._walls`/`_quad`
through the same accumulator class (~0.1–0.3 s each). Target ceiling ~0.5–0.8 s total in Paris, byte-identical.

### P3.2 — Roof-forms script wrapper (Helsinki 0.39 s)

`RoofKernels.form_many` is native, but its script wrapper in `building_builder.gd` (~0.39 s in Helsinki,
0.09 s in Paris) has not been split. Same pattern as P3.1. Small win, but clean.

### P3.3 — Roads wrapper (candidate 5)

`RoadBuilder._roads` 2.3 s (Paris + Helsinki). Paris split: per-road wrapper 0.89 s, mesh creation
0.48 s, surface setup 0.42 s, bridge structures 0.21 s. **Profile first** — `_Surface.new`,
`_road`, `build_road_mesh` splits are not yet known. Do **not** kernel this without a profile: the
wrapper is not a clean arithmetic loop, and the phases with the most skid are the ones with the most logic.

### P3.4 — Vegetation misc (candidate 7) — low priority

Tree fill 108–128 ms, CanopyVegetation.add 62–99 ms, GroundCover scatter 213–259 ms, terrain mesh
~200 ms, far-terrain 350 ms. None is more than 0.26 s and every port carries byte-identity risk.
**Verdict: skip unless P1.1–P3.2 are done** — they were 0.15–0.2 s each, not 0.5 s.

---

## 5. Verification protocol

Every candidate in this document must pass, before it is "done":

1. **Fingerprints** — `tools/build_bench.gd` `snapshot` + `build` (serial) for Paris and Helsinki at Ultra;
   `parallel` for both; fingerprints byte-identical before/after, with **two** baseline runs
   (one 2026-11-19 run disagreed — treat one-run agreement as insufficient evidence).
2. **Tests** — `tests/facade_shader_test.gd`, `tests/quality_governor_test.gd`, `tests/haze_test.gd`,
   `tests/altitude_reach_test.gd`, `tests/ultra_looks_test.gd`, `tests/world_cache_key_test.gd`,
   `tests/fidelity_scorecard_test.gd` — plus new ones for any candidate that changes behavior
   (P1.2, P1.3, P1.4 all have existing tests to extend).
3. **Performance** — `tools/perf_baseline.gd` per place at Ultra, cold / cached / fly p95, one run per
   preset, **cold cache** (empty `user://worlds` folder). Reference baselines: Helsinki Ultra (hel-r6,
   60 s fly) cold 19.6 s, cached 2.0 s, fly p95 26.2 ms (2026-11-15: 26.7 s / 4.5 s / 23.4 ms); Turku Ultra
   (tku-r4, 20 s fly) cold 23.6 s, cached 7.2 s. NYC Ultra (2026-11-15) is the worst case: fly p95 47.1 ms.
   Compare before/after.
4. **Gates** — `tools/check_class_size.sh` (max 1000 lines/class; 998/1000 today at `road_builder.gd` —
   P3.3 and P3.1 both require care not to add lines here).
5. **AC-12** — confirm no object moved, no hue shift >2%. Screenshot before/after for any Phase 2 change.

---

## 6. Known suspects and weak spots (for the maintainer)

- **Ultra save regressing** (29.8 → 40.0 s between hel-r6 and tku-r4) with no stated cause. Profile before
  optimising — do not guess (P1.3).
- **Parallel build noisy** — Paris parallel total 6.2–9.6 s; the one known fingerprint disagreement
  (Stairs, VegTreeSet + all-after) was never found. Re-verify two-baseline before any fingerprint-driven decision.
- **Editor-binary timings** (3–5× inflation) — do not rank candidates from editor runs.
- **`world_cache.gd` `_sources()` debug-hash** — exclude `haze_rig.gd`, `quality_governor.gd`,
  `altitude_reach.gd`, `godray_shader.gd`, `weather_dressing.gd` from the key, which is why
  P1.2 and P1.4 don't invalidate cached worlds (good) but P1.3 must bump BUILD_VERSION.
- **AC-18** (photoreal) — Ultra's weakest scorecard axis ('photographic' vs 'recognisable') is a data/content
  problem (fabric/noise), not a speed problem; leave it to the data work.

## 7. Files referenced

| File | Relevant lines / contents |
|---|---|
| `scripts/generation/pipeline.gd` | Stage machine; stage overlap (fetchers in parallel) |
| `scripts/generation/world_build_graph.gd` | 7-stage parallel build; `_lanes`; streamed path |
| `scripts/generation/building_builder.gd` | Per-mass extrusion (`_extrude_polygon`); `_real_buildings`; parallel batching |
| `scripts/generation/far_city_builder.gd` | Bands R_IN 1230 / SPLIT 3500 / BANDS […12001] |
| `scripts/generation/pbr_textures.gd` | `_set_tex` / `_set_image` — ~170 ms first-use cold decode |
| `scripts/generation/material_library.gd` | `PBR_SETS` / `hi_res` / `_pbr_mats` cache / `full_detail_radius_m` |
| `scripts/generation/facade_shader.gd` | Ultra per-pixel shader (32-step parallax, interior trace) |
| `scripts/generation/facade_materials.gd` | `facade_for_building` / `roof_for_building` |
| `scripts/generation/building_walls.gd` | `_walls` / `_quad` — the P3.1 target |
| `scripts/generation/building_detail.gd` | `add` — the P3.1 target |
| `scripts/generation/facade_relief.gd` | `add` — the P3.1 target |
| `scripts/generation/building_foundation.gd` | `plinth` — native (done) |
| `scripts/generation/far_canopy.gd` | native probe pass (done) |
| `scripts/generation/road_builder.gd` | `_roads` — the P3.3 target |
| `scripts/generation/vegetation_builder.gd` | `_fill_cover` / `CanopyVegetation.add` |
| `scripts/generation/ground_cover.gd` | `_scatter` — candidate 7 |
| `scripts/render/render_settings.gd` | Budgets (Ultra 10 000 / 380-500 veg / 200 infill / 1.25× / 4000 m / z17 / 256 mesh posts) |
| `scripts/render/render_quality.gd` | Ultra extras (SDFGI/SSIL/SSR 64/volumetrics 128×128/TAA/8192 atlas/PCSS 0.53°/radiance 256/anisotropy 16/auto-exposure) |
| `scripts/render/quality_governor.gd` | Steps: haze 2→1→0, then render scale, then shadows — P1.2 target |
| `scripts/render/atmosphere_rig.gd` | `set_haziness` + `_apply_haziness` (P1.5 target); street probes (P1.5) |
| `scripts/render/haze_rig.gd` | 48-tap half-res pass (~free); not a target |
| `scripts/render/lod_ring.gd` | `apply`/`apply_child` + `RANGE_SLICES` (P1.4 target) |
| `scripts/render/world_cache.gd` | `save_async` / `pump_budget_us` / `pack` (P1.3 target) |
| `scripts/render/world_streamer.gd` | `_pump_ranging` budget (1000/6000/12000 µs) |
| `scripts/render/city_detail.gd` | `VERSION 7`; Ultra 14 000 bldgs / 900 m ring / z19-15 mosaic / street extras |
| `scripts/render/altitude_reach.gd` | `RANGE_SLICES 16`, boosted rings — P1.4 pattern |
| `scripts/screens/view_360.gd` | `build_location` (threaded); `_tick_near_ground` spread; `_rebuild_world` + `set_quality_preset` (P1.4 target) |
| `tools/build_bench.gd` | Serial/parallel fingerprints — the verification |
| `tools/perf_baseline.gd` | Cold/cached/fly per preset — the verification |
| `docs/fidelity-scorecard.md` | Ultra cold/cached/fly numbers; AC-14 bar |
| `NATIVE_SPEEDUP_CANDIDATES.md` | Candidates 1–3 done; 4–7 not started; fingerprint caveat |
