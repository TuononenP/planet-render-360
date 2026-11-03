# Helsinki and Espoo — roof-metal refinement, 3 November 2026

Shared G-5 now uses dedicated copper-patina and painted standing-seam PBR sets. Copper tags no longer select clay tiles. Nordic metal tags and pitched defaults no longer select slate courses. Otaniemi uses copper on flat and sloping roofs. This is a material refinement; the photographic goal is still open.

![Previous roof finishes behind; corrected finishes in front](gallery-summer.png)

The back row approximates the former finish resolution (copper→terracotta; sheet→slate), with the same geometry and lighting as the corrected front row. From left: copper, charcoal, grey, falu red. A [snow-overlay check](gallery-winter.png) uses the same lighting to isolate snow compatibility. Actual January solar conditions are in the separate city captures.

## Material behaviour

- Bundled ambientCG Metal058C and Metal014 colour, OpenGL normal and roughness maps at 1K and 2K; CC0 source URLs and hashes are recorded in `assets/textures/roof_metals.sources.json` and the data-source register. Both upstream assets are authored procedural PBR materials, not photographic scans.
- Painted sheet albedo is neutralized with contrast reduced to 25%, retaining grain without the bare metal's large oxidation patches. Copper retains its patina variation. Calibration means are measured after processing.
- Six 0.6 m standing pans over a 3.6 m repeat. Folds run down the roof slope using the existing UV frame and add no roof geometry or additional material pass. Composed normals are capped at 1024²; Ultra retains 2K colour/roughness.
- OSM material/colour tags take priority; red imagery colours a sheet roof without changing it to terracotta. Known copper accepts green imagery. Untagged flat Nordic sheet profiles retain membrane.
- Fast near and distant roofs avoid normal/roughness maps. Other tiers use the composed normals; the existing two-material distant roof budget remains.
- Existing per-building tint and snow overlay work on the new sets. Generated maps and roof metadata survive a packed-scene save/load round trip.

## Verification

Seven focused headless scripts pass: `roof_metals_test`, `osm_test`, `architecture_test`, `roof_snow_test`, `render_upgrade_test`, `parallel_build_test`, `world_cache_key_test`. The new material test checks tag priority, colour separation, patina and flat roofs, six tiled folds, source calibration, Fast gating, snow attachment/removal and packed-scene persistence. Logs and statuses are in [validation](validation/).

All Godot work ran in background sessions; windowed captures used `tools/godot_bg.sh --position 4000,4000`. The capture project isolates History, preferences and world caches, reusing only raw fetch cache, source assets and imported textures. Capture world saving is disabled with the existing environment option. Existing image-import warnings and exit-time leak warnings remain in logs; these are not represented as clean logs.

The source snapshot also includes concurrent shoreline, marina and city work. City captures are combined-worktree evidence, not an isolated material A/B comparison. The gallery isolates the material change. Verified source/asset hashes bound the evidence; later concurrent edits are recorded separately. No photographic grade is claimed and no commits or pushes were made.


## City review candidates

| City / season | Capture | Cold generation | Wire surfaces / budget | Sun | Opening luma / saturation / colourfulness |
| --- | --- | ---: | ---: | ---: | --- |
| Helsinki / summer | [Views](../helsinki-roof-metals-summer-2026-11-03/) | 32.318 s | 8 / 12 | 12.22° | 0.648 / 0.248 / 0.124 |
| Helsinki / winter | [Views](../helsinki-roof-metals-winter-2026-11-03/) | 33.860 s | 8 / 12 | 8.75° | 0.645 / 0.257 / 0.148 |
| Espoo / summer | [Views](../espoo-roof-metals-summer-2026-11-03/) | 4.433 s | 0 / 12 | 12.29° | 0.636 / 0.200 / 0.122 |
| Espoo / winter | [Views](../espoo-roof-metals-winter-2026-11-03/) | 4.761 s | 0 / 12 | 8.69° | 0.721 / 0.165 / 0.101 |

Generation excludes source fetch and meets the 150 s limit. June late views retain twilight at about −6.14° solar elevation; January golden views reach about 8.7°. The summer Helsinki opening remains brighter than the two nonwinter references; winter saturation/colourfulness remain above the winter references. Espoo summer falls within its broad reference ranges. Geometry, facade detail, pool/quay edges and winter colour still prevent a photographic pre-rating.


The current Helsinki opening still shows simplified white ship masses and a
foreground block masking much of Uspenski. These are concrete targets for
the next data/geometry review, alongside Espoo's coarse pool perimeter.
This refinement does not resolve those remaining silhouette and placement tells.

Task-owned scratch source, isolated user-data caches and downloaded archives were removed after verification; 7.4 GiB was free after cleanup. Reports and source/asset backups remain.
