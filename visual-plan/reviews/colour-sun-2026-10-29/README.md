# Facade/landmark colour fix, slate roofs, true sun — 2026-10-29

Captures: Paris spawn (48.8566, 2.3522), cached data, 1280×800, Godot
4.7.2 **Compatibility renderer under Xvfb** (no Vulkan in the capture
container), so absolute shading differs from the shipped Mobile
renderer; before/after pairs share the renderer and the 17:00 light.

| File | Top / left | Bottom / right |
|---|---|---|
| `facades-before-after-v0.jpg`, `-v1.jpg` | `75b1938` (before) | `12ac069` (colour fix) |
| `roofs-before-after.jpg` | `75b1938` | `12ac069` |
| `t62-paris-golden-hour-4yaw.jpg` | `b823bb0` (true sun), 4 yaws at the spawn golden hour | |

## Colour fix (double sRGB decode on facades and landmarks)

Median pixel samples, same building, same light (v1):

| Sample | Before | After | PRD AC-05 |
|---|---|---|---|
| Sunlit Haussmann facade | #BBAE88 | **#D2C5A3** | albedo #D6C5A3 (lit #EBDCBE) |
| Second facade | #B5A177 | #B6B4A1 | — |
| Sunlit slate slope | #606970 | **#5C6061** | #46525E base |
| Shaded slate slope | #2E4B68 | #364858 | — |

- Facades now land on the PRD limestone instead of a darker,
  over-saturated mustard (AC-05 "not orange").
- Sunlit slate is neutral grey; the shaded slope keeps a blue cast.
  A trial with the slate grey pull at 0.8 instead of 0.55 moved it only
  #364858 → #394B5B, so the remaining cast is sky light / sky
  reflection on the slope facing away from the sun, not the slate
  albedo. Kept at 0.55. Re-judge on the Mobile renderer (T8.2).
- Deliberate deviation: slate albedo is ≈#4D5358 rather than the PRD
  #46525E base — AC-05 needs a note in T8.3.

## T6.2 true sun

`tests/solar_test.gd` PASS (11 ephemeris references within 0.5°,
poles, frame, polar day/night rig states finite and non-black);
`tests/sky_test.gd` PASS (golden-hour reference grade at Paris 15 July,
sun 12.42° up at azimuth 288.45°). The capture spawns at 19:00: the
place's golden hour for a 15 July sun on today's Paris clock (UTC+1 from
Open-Meteo — the offset is today's, so DST on the season date is not
applied; known gap).
