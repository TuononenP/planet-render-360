# SkyWheel overlap correction — 3 November 2026

SkyWheel now uses OSM way 457949936's centre (60.1667282, 24.9594489) and north–south wheel plane (yaw −90.4°). Allas's replacement radius grows from 76 m to 105 m so its eastern venue building, way 443717281, cannot remain as an oversized generic block beside the wheel. The neighbouring Enso-Gutzeit office remains outside the clearance. World cache build version is 106, invalidating previously generated worlds.

![Corrected wheel from the west](after-helsinki_look0.jpg)

[Before, west](before-helsinki_look0.jpg) · [After, west](after-helsinki_look0.jpg) · [Before, northwest](before-helsinki_look1.jpg) · [After, northwest](after-helsinki_look1.jpg)

The source already contained an earlier coordinate correction, so this fresh baseline does not reproduce the exact glass-block intersection in the supplied older screenshot. The follow-up corrects the remaining orientation/centre rounding and verifies that the duplicate Allas block is suppressed, rather than removing unrelated neighbouring buildings.

`helsinki_hero_landmarks_test` now uses a small OSM fixture to check the real secondary-landmark build path: centre within 1 m, wheel plane within 2°, no generic duplicate wheel, eastern Allas block cleared, adjacent Enso-Gutzeit office retained, and no wheel-footprint overlap with retained building polygons. Before the fix it fails the centre, axis and eastern-venue assertions; afterward it passes. Landmark geometry, catalog and preset tests also pass. Class-size and whitespace checks pass.

Captures are Ultra, clear summer, 21 June, with two additional views from the west and northwest. Both runs use `tools/godot_bg.sh --position 4000,4000` in background sessions. Tests run headless. Source, preferences and generated caches are isolated; world-cache saving is disabled with the existing `PR360_DISABLE_WORLD_CACHE=1` capture option. The task-owned source copy and user-data cache are removed after evidence is copied. Logs retain existing raw-image import and exit-time leak warnings. Broader terrain/water appearance is outside this focused correction.

No commits or pushes were made.
