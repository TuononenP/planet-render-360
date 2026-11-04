# Suomenlinna fortress review — 2026-11-04

The main connected islands now use mapped bastion, casemate and curtain-wall
footprints with stone faces and grass-covered earthworks. Occupied halls and
homes retain building rendering, with restrained historic defaults underneath
explicit mapped tags. The church's compressed adjacent fortress is removed;
King's Gate and the small white southern beacon occupy their real sites.

Primary references are the user's four photographs. Placement, provenance and
estimated dimensions are recorded in [the source notes](../../../docs/suomenlinna-sources.md).

## Visual checks

- [Southern aerial, Ultra summer](../suomenlinna-fortress-final-2026-11-04/suomenlinna_look6.jpg):
  angular masonry defenses and grass banks replace residential extrusions.
- [Gate from the south, High summer](../suomenlinna-gate-2026-11-04/suomenlinna_look0.jpg):
  arch/reveals, classical stone surround and waterfront terrace. The local
  terrain correction prevents the DEM from burying the entrance.
- [Close wall view, Ultra summer](../suomenlinna-fortress-final-2026-11-04/suomenlinna_look2.jpg):
  masonry, battered walls, grass banks and retained historic buildings.
- [Harbour view, before](../suomenlinna-2026-11-04/suomenlinna_vantage.jpg)
  and [after](../suomenlinna-fortress-final-2026-11-04/suomenlinna_look5.jpg):
  corresponding eye/bearing; lighting differs between capture dates.
- [Southern aerial, High winter](../suomenlinna-fortress-winter-2026-11-04/suomenlinna_look0.jpg):
  live snow on ramparts and paths, retaining recognizable fortress geometry.

The full summer fortress batch contains 42,754 triangles in 8 shared material
batches. Captures reuse cached map data, disable world-cache reuse, and run
through the real app pipeline in offscreen windows. See `stats.json` in each
capture directory for camera and rendering conditions. No thumbnails, settings
or history were saved.

## Verification

Passed headlessly through `tools/godot_bg.sh`:

- `suomenlinna_test.gd`: defense metadata, occupied buildings, nested/orphan
  parts, courtyard roofs, tagged heights/roofs/colours, gate terrain clearance,
  beacon identity and unique shoreline ownership.
- `osm_test.gd`, `architecture_test.gd`, `building_references_test.gd`,
  `height_inference_test.gd`.
- `landmark_catalog_test.gd`, `landmark_placement_test.gd`, `finland_hero_test.gd`.
- `world_cache_key_test.gd`, `shoreline_test.gd`, `parallel_build_test.gd`.
- `tools/check_class_size.sh` and `git diff --check`.

Final test logs are in `validation/`. The earlier architecture failure was
isolated to a concurrent material change; the final full architecture run passes.
Windowed captures finish successfully with no script errors; Godot reports
texture/ObjectDB cleanup warnings on shutdown.

## Reproduce

```sh
PR360_DISABLE_WORLD_CACHE=1 tools/godot_bg.sh --path . \
  --script tools/capture_suomenlinna.gd --position 4000,4000 -- \
  --tag=suomenlinna-fortress-final --preset=3 --season=summer \
  --date=2026-06-21 --times=golden,noon,roofs \
  '--looks=60.143416,24.974975,31,59,0;60.1368,24.9920,95,335,-28;60.13927,24.98985,8,3,-5'
```

Run in the background. For the winter comparison, use `--preset=2`,
`--season=winter` and `--date=2026-01-15` with a separate tag.
