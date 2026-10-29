# Baseline capture pack — 2026-10-28 (plan T0.1)

Current-state evidence for the 5 golden locations, before any Phase 1+
redesign work. Companion machine-readable file: `metrics.json` (same rows).

## Metrics (default preset: High, 17:00 golden hour)

| Location | lat, lon | Centre DEM (m) | Relief (m) | vscale | OSM bldgs | OSM roads | Land polys | Satellite | Far DEM | Landmark | Seed | fps* |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Paris | 48.8566, 2.3522 | 41.4 | 45.2 | 0.3500 | 574 | 300 | 21 | yes | yes | eiffel | 42146 | 118.4 |
| Interlaken | 46.6863, 7.8632 | 568.0 | 961.3 | 0.0312 | 434 | 245 | 87 | yes | yes | none | 19900 | 118.2 |
| Banff | 51.1789, -115.5708 | 1401.0 | 233.0 | 0.1288 | 515 | 306 | 72 | yes | yes | none | 40130 | 118.2 |
| Big Sur | 36.2704, -121.8081 | 39.8 | 1012.3 | 0.0296 | 19 | 19 | 3 | yes | yes | none | 38091 | 117.6 |
| Turku | 60.4518, 22.2666 | 26.9 | 45.4 | 0.3500 | 284 | 554 | 51 | yes | yes | turku_cathedral | 43116 | 119.0 |

\* fps = mean `Engine.get_frames_per_second` over ~2.5 s at spawn on the
capture machine (Apple M3 Max, Metal, 3456×2168). This is a desktop
number, **not** the PRD AC-14 mid-tier-phone figure; phone fps is still
unmeasured. HUD readouts in the captures agree (e.g. Paris “High · 118 fps”).

Column notes:

- Centre DEM = pipeline `_dem_centre_m` (source-tile metres at grid centre);
  relief = `relief_metres` (mx−mn over the detailed grid); vscale = adaptive
  vertical scale (`30 / relief`, clamped 0.02–0.35) — the D1 squash this
  baseline freezes for A/B comparison in T1.3.
- OSM counts = `LocationData.buildings` / `.roads` sizes after generation
  (`used_real_dem` was true for all 5; satellite + far-DEM present for all 5).
- Seeds drive the procedural layers (infill, vegetation, silhouette ring);
  same seed + same code = same layout for pixel-diff gates (T1.1a).

## Captures

25 PNGs, 3456×2168, `<location>-{spawn,yaw000,yaw090,yaw180,yaw270}.png`:

- `spawn` = app spawn look (landmark-framed for Paris/Turku, yaw 0.6 otherwise).
- `yaw000/090/180/270` = rig yaw 0 / +90° / 180° / −90° at pitch −0.10,
  0.6 s settle each (PRD §8 “5 judging captures” pattern: AC-03/AC-07).
- Requested window was 1280×800 (the `screenshot_test.gd` desktop size) but
  the headed window kept its native 3456×2168 backing store on this display;
  recorded here honestly instead of downscaling evidence.

## Method and gaps (read before comparing)

- Path: `scenes/main.tscn` + `_start_generation` + `CameraRig.set_look`,
  i.e. the `tests/screenshot_test.gd` capture path, driven by an untracked
  `/tmp/baseline_capture.gd` script (kept out of the repo; screenshot_test
  itself was used read-only). Preset forced to High in-memory.
- Headless tried first: generation + metrics work headless, but captures are
  display-bound — `root.get_texture()` is null under the dummy rasterizer
  (`texture_2d_get` ERROR, `save_png` on null). All PNGs are from headed
  runs under hard timeouts (20 min full run, 10 min retries).
- Overpass flaked mid-run and recovered on retry: Banff failed twice
  (timeout `result=13` on all 4 endpoints), Big Sur once (`502`); final
  captures + counts above are all-real-data (no procedural-dressing rows).
- Turku's first-run 5 PNGs were byte-identical (stale compositor frames);
  re-run produced 5 distinct frames (md5-verified). All other locations'
  5 shots were distinct on the first attempt (md5-verified).
- Network state: live fetches (AWS Terrain Tiles, Esri, Overpass) with the
  warm `user://` cache; OSM retry counts above are post-recovery.

## Provenance

- `godot --version`: 4.7.2.stable.official.ed1daf0bf; display server macOS.
- git HEAD `4b95b44` with a **dirty tree** — this baseline pins the working
  tree, not a clean commit. Dirty at capture time:
  `generated_images/screenshots/03b-view360-desktop.png`,
  `scripts/data/osm_fetcher.gd`, `scripts/generation/pipeline.gd`,
  `scripts/generation/terrain_builder.gd`, `scripts/screens/map_picker.gd`,
  `scripts/screens/view_360.gd`, `tests/flow_test.gd`, `tests/osm_test.gd`,
  `visual-plan/PRD.md`, `visual-plan/best/*` (5 files),
  `visual-plan/reviews/accept-r1-look.md`,
  `visual-plan/reviews/accept-r1-shape.md`,
  plus untracked `.agents/plans/2026-10-28-real-location-fidelity-redesign.md`,
  `tests/leak_test.gd(.uid)`, `visual-plan/best/terrain_builder.gd`.
- Validation: `godot --headless --script tests/scenery_test.gd` → SCENERY OK
  (same session, after captures).
