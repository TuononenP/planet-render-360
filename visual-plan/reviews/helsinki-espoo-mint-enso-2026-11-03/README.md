# Helsinki and Espoo — Mint and Enso refinement, 3 November 2026

The Old Mint now uses its mapped footprint and a source-backed, approximate
two-storey profile instead of an inferred six-storey block. The Enso office's
parts inherit the building's mapped white marble finish; the stone fallback
and material cache retain that colour. The initial diagnosis was wrong: the
large block in front of Uspenski is the Enso office, while the Old Mint stands
to its right.

![Corrected harbour opening](helsinki-summer/helsinki_vantage.jpg)

[Before, same opening](before/helsinki_vantage.jpg) ·
[After, elevated harbour view](helsinki-summer/helsinki_look0.jpg) ·
[Winter opening](helsinki-winter/helsinki_vantage.jpg)

## What changed

- `BuildingReferences` matches OSM identity `way:23192814` and fills missing
  Mint height, levels, date and roof facts. The footprint, position and mapped
  wall colour remain authoritative. Explicit map height/levels and mapped
  building parts take precedence; the unmodified raw OSM cache is reparsed.
- The [owner's restoration report](https://www.senaatti.fi/app/uploads/2017/05/3168-2013_Mustonen_Hki_Rahapaja_Kunnostusraportti_web.pdf)
  shows the two-level facade and metal roof. Measurements from its 1:200 A3
  elevations yield a rounded 11.5 m main-ridge height and 2.5 m roof rise;
  the height carries 1 m uncertainty and is not a surveyed dimension. The
  dark grey roof colour is an approximation of the report's NCS S 7502-G.
- Blank part-level colour/material now inherit the parent building's tags;
  explicit part tags still win. For white marble, the existing limestone set
  is calibrated to a pale neutral finish. This is a stone-texture fallback,
  not a marble scan. Its high-range cache key distinguishes pale tints without
  lifting the existing material cap.

## Uspenski ground check

The same cached terrain and shoreline pipeline sampled the cathedral centre at
14.06 m and the lowest point of the current 25 m half-width footprint sample
at 10.20 m above the rendered sea datum; the placement then sinks the model
0.3 m. These are data-derived render heights, not a site survey. The
[parish describes the cathedral's rocky setting](https://hos.fi/kirkot/uspenskin-katedraali/),
but that does not establish a precise foundation elevation. Raising the model
without corroborating terrain and a supporting foundation could leave it
floating, so its ground placement remains unchanged. The [probe log](validation/ground-probe.log)
also records smaller sample widths.

## Captures and budgets

| City / season | Opening | Generation | Wire surfaces | Marina surfaces | Luma / saturation / colourfulness |
| --- | --- | ---: | ---: | ---: | --- |
| Helsinki / summer | [View](helsinki-summer/helsinki_vantage.jpg) | 35.112 s | 8 / 12 | 13 / 20 | 0.643 / 0.254 / 0.122 |
| Helsinki / winter | [View](helsinki-winter/helsinki_vantage.jpg) | 36.311 s | 8 / 12 | 13 / 20 | 0.639 / 0.263 / 0.141 |
| Espoo / summer | [View](espoo-summer/espoo_vantage.jpg) | 6.463 s | 12 / 12 | 8 / 20 | 0.639 / 0.199 / 0.122 |
| Espoo / winter | [View](espoo-winter/espoo_vantage.jpg) | 6.574 s | 12 / 12 | 8 / 20 | 0.723 / 0.165 / 0.102 |

Generation excludes source fetching and meets the 150 s target. Opening sun
elevations are 12.22° / 12.29° in June and 8.75° / 8.69° in January. Each
directory contains cardinal views, roof and twilight captures, close-ups,
reference sheets and `stats.json`. The second Helsinki eye is elevated 25 m
for the facade review.

The office reads pale rather than ochre in the opening, and the Mint is lower;
the office still hides much of Uspenski from this eye. Its procedural facade,
the small boats, Espoo's pool perimeter and winter brightness still differ from
the photographs. The four views remain **recognisable** pre-ratings, with the
photographic target and human review open.

## Verification

Seven focused headless scripts passed for the reference and facade changes:
`building_references_test`, `building_fabric_test`, `architecture_test`,
`osm_test`, `parallel_build_test`, `world_cache_key_test` and
`roof_metals_test`. After the marble cache-key change, the relevant reference,
architecture, parallel-build and cache-key checks were repeated, and
`lod_test` passed: materials grew from 25 to 30 when the fixture grew from
100 to 400 buildings. The reference and building-fabric tests also pass on the
current shared tree. Class-size and whitespace checks pass.

The tests cover mapped-tag/part priority, two storeys, roof and total height,
source/uncertainty metadata, unrelated and part-model exclusions, material
inheritance and distinct pale marble cache entries. [Logs and statuses](validation/)
retain existing raw-image import warnings and the headless editor's missing
Blender-path message. The OSM test also logs its intentional invalid-JSON
case. All Godot runs used the background wrapper; windowed
captures used `--position 4000,4000` and disabled world-cache saving.

The source snapshot was isolated from subsequent script edits and used a copy
of the native binaries; assets and raw fetch caches were shared. Its
[before/after source hashes](capture-source-differences.json) identify the nine
changed or added files, including the cache-version file. Raw caches were not frozen, so
the pair is useful visual evidence, not a strictly controlled pixel comparison.
[Later shared-tree differences](later-tree-differences.json) are recorded;
they were preserved. The user’s History and preferences were not used.

No commits or pushes were made.

After validation, the task-owned source snapshot, private user-data directory
and downloaded report intermediates were removed. The disk had 4.4 GiB free
immediately afterward; shared assets and raw user caches were preserved.
