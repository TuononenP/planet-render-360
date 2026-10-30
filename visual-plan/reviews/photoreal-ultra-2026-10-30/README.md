# Ultra photoreal render layer — 2026-10-30

Left: `main` (9b09d8b), Mobile renderer, Ultra. Right: branch
`photoreal-ultra`, Forward+, Ultra. Same place, same sun (15 July,
golden hour: Paris 13.1° at az 288°, Interlaken 11.3°), clear sky, cached
data, governor off, 960×600. Both are **software Vulkan (lavapipe)
under Xvfb**: the shading is real, but timings are CPU-bound and the look
still needs a check on a real GPU.

| Image | What changed |
|---|---|
| `paris-into-sun.jpg` | Sun-lit volumetric haze over the Tuileries axis; shade under the plane trees filled by sky and bounce light instead of near-black; 0.53° sun penumbrae; TAA edges. Eiffel Tower still legible (see tuning). |
| `paris-away-from-sun.jpg` | SSAO grounds building bases, eaves and courtyards; SDFGI bounce warms the shaded facades. |
| `paris-seine.jpg` | Softer penumbrae, cleaner edges; SSR on the Seine is subtle from 30 m (it refines the probe reflection; most visible near street level). |
| `interlaken-into-sun.jpg` | Forward-scattered sunlight over the ridge; green bounce light up the forested slope. |
| `interlaken-valley.jpg`, `interlaken-lake-side.jpg` | Bounce light in tree crowns, soft tree shadows on the meadow, no SDFGI leaks or dark patches on the DEM terrain. |
| `volumetric-tuning-before-after.jpg` | First pass (0.0012/m over 500 m, ambient fill) milked the far city and hid the Eiffel Tower; shipped 0.0004/m over 250 m, sun + bounce only. |
| `ssao-radius-2.5-5-10-off.jpg` | SSAO radius 2.5 / 5 / 10 m / off (top-left → bottom-right); 2.5 m was invisible at this eye height, 10 m ships. |

AC-12 check (same frames, Ultra vs High on Forward+): mean hue differs
by 0.5°, 0.4° and 1.4° across the three Paris views (bar: 2% = 7.2°);
ACES, sky, sun and exponential haze are the same on every tier
(`settings_test`).

Frame cost on lavapipe (CPU, 4 cores), per frame at 1.25 render scale:
Ultra Forward+ ≈ 6 s steady (≈14–16 s on the first SDFGI frames) vs
≈ 2.6–2.9 s for the old Ultra on Mobile — about 2.2× on this CPU path.
Real-GPU fps not measured (T8.4).

## Window recesses and roof variety (same day, second pass)

Left: branch before (109242d). Right: a99e752. Forward+, Ultra, same sun.

| Image | What changed |
|---|---|
| `window-recesses-closeup.jpg`, `window-recesses-roof-closeup.jpg` (2× crops) | Glass sits 0.25 m back in its reveal (deep parallax over a depth map read off the composed roughness map): from above the lintel hides the top of each pane, as a real recess does. Recesses are Ultra only. Walls now carry tangents on every tier, so the facade normal maps light correctly too. |
| `roof-variety-seine.jpg`, `roof-variety-courtyards.jpg` | Each real building's roof takes its own seeded tint (lightness ±12%, warm/cool ±5%) on the shared roof materials: neighbouring slate roofs read as separate roofs of different age and weathering, no extra materials or draw calls, same on every tier. Tints average 1 (facade_relief_test). |

Frame cost on lavapipe for these close views rose from ≈6 s to ≈9 s
(parallax is per-pixel on every Ultra facade); real-GPU cost unmeasured.
