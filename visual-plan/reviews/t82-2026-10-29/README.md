# T8.2 regression captures — 2026-10-29

Five golden locations × {spawn, yaw000, yaw090, yaw180, yaw270}, the T0.1
pattern (rig yaw 0 / +90° / 180° / −90° at pitch −0.10). High preset,
cached data, 1280×800, Godot 4.7.2 **Compatibility renderer under Xvfb**
(no Vulkan in the capture container — shading is not the shipped Mobile
renderer; compare layout, colour relations and light direction, not exact
tone). `cmp_<location>.jpg`: top row baseline
`visual-plan/baseline/2026-10-28/` (17:00, old fixed sun), bottom row
these captures. Scorecard for the same build:
`../scorecard-2026-10-29/`.

| Location | Spawn hour (place clock) | Generation, cached (s) | Draw calls (yaw270) |
|---|---|---|---|
| Paris | 19:00 | 52.7 | 407 |
| Interlaken | 19:00 | 26.6 | 328 |
| Banff | 18:00 | 30.0 | 324 |
| Big Sur | 18:00 | 13.3 | 181 |
| Turku | 19:00 → 20:00 when the real UTC offset arrived | 44.0 | 391 |

Generation times are windowed software GL on the container CPU, not the
§3.1 reference machine.

## What improved (vs. 2026-10-28)

- **AC-05 facades/roofs:** limestone reads pale stone instead of mustard
  (measured #BBAE88 → #D2C5A3 vs PRD #D6C5A3); slate roofs neutral grey.
- **AC-07 light:** the sun is the real one — Paris spawn shows the evening
  sun west-north-west beside the Eiffel Tower; every location opens at
  its own golden hour. Live weather drives cover (Paris overcast today).
- **AC-01/AC-04 layout:** true-scale fabric across the 2.4 km extent
  (T7.0/T7.1 since baseline), footprints IoU 0.81–1.00, heights 0.6 m
  taller (now on their data), Interlaken terrain registered to the OSM
  features.
- **Turku** now renders its real OSM fabric (null-node parse fix); Big Sur
  its real forest, river and roads instead of a beige plain.

## Regressions / open (each noted, none blocking a tick here)

- **AC-07 golden grade:** the sky in these runs is overcast by live
  weather, so the PRD warm-gradient grade is not shown; a clear-weather
  capture is needed for the AC-07 numeric sample (T8.3).
- **Light-grey road and plaza surfaces** read flat at the spawn in Paris
  (also in baseline); unchanged by this session.
- **Turku spawn hour shifts 19:00 → 20:00** once Open-Meteo's UTC offset
  lands (longitude fallback first). Expected by design; a cached offset
  per place would remove the shift.
- AC-14 phone fps still unmeasured (T8.4).
