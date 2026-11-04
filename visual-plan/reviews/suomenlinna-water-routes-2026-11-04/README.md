# Navigation routes on water — 2026-11-04

The dark bands were OSM `waterway=fairway` and `waterway=link` navigation
routes being treated as physical channels. They created separate water bodies,
carved artificial beds and used different shading from the surrounding sea.

Navigation routes now retain their map geometry with zero physical channel
width. Both the shoreline model and legacy ribbon renderer also reject these
classes when older parsed data still carries a positive width. Real rivers,
canals, streams, ditches and drains keep their existing widths and rendering.
The built-world cache version is incremented so revisits receive the correction.

[Before](../suomenlinna-fortress-final-2026-11-04/suomenlinna_look6.jpg) ·
[After](suomenlinna_look0.jpg)

The matching aerial capture confirms that the dark route bands are gone.
The shoreline model's water-body count drops from 267 to 47, with zero
shoreline diagnostics in the corrected capture.

Passed: `navigation_waterways_test.gd`, `osm_test.gd`, `shoreline_test.gd`,
`coastal_water_test.gd`, `world_cache_key_test.gd`, the class-size check and
`git diff --check`. Validation and capture logs are in `validation/`.
The capture helper's signature was updated to match its current parent tool.

```sh
PR360_DISABLE_WORLD_CACHE=1 tools/godot_bg.sh --path . \
  --script tools/capture_suomenlinna.gd --position 4000,4000 -- \
  --tag=suomenlinna-water-routes --preset=3 --season=summer \
  --date=2026-06-21 --times=noon '--looks=60.1368,24.9920,95,335,-28'
```

Run in the background. The captures reuse the same cached map data.
