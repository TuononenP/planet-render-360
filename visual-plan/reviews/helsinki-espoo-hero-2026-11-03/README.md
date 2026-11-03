# Helsinki and Espoo hero implementation — 3 November 2026

Implemented the Finland systems and landmark batches from Plan A. Current visual pre-rating: **recognisable** in both seasons. The photographic target remains open; these are review candidates, not an accepted photographic result.

![Final summer and winter opening views](hero-comparison.jpg)

## Review candidates

| City | Summer | Winter | Main remaining tell |
| --- | --- | --- | --- |
| Helsinki | [R8, 21 June](../hki-r8-2026-11-03/) | [R9, 15 January](../hki-r9-winter-2026-11-03/) | Waterfront facades and quay edges remain simplified; the summer opening is brighter than the reference photos. Winter water/snow transitions are still procedural. |
| Espoo | [R8, 21 June](../espoo-r8-2026-11-03/) | [R9, 15 January](../espoo-r9-winter-2026-11-03/) | Keskustorni and the pool are recognisable, but surrounding blocks, banks and winter colour lack photographic detail. |

Each candidate includes the opening view, four cardinal directions, two closer views, noon and late views, a contact sheet and `stats.json`. Baselines are the matching `hki-r1*` / `espoo-r1*` folders; R6 is retained as intermediate evidence. R8 February winter captures are retained, but R9 January replaces them for the near-8° sun check. R7 had an incomplete concurrent-source snapshot and is excluded from the deliverable and ratings.

## Implementation

- Presets and licensed Commons references for both cities, with summer/winter reference separation and explicit capture dates.
- District and era rules, Finnish apartment/wood/modernist rows, Espoo zones and cores; granite plinths, turrets, glazed balconies and snow guards.
- Ultra tram/trolley wires and span lamps, Finnish street furniture, tram reservation beds, obstacle-aware parking and sidewalk limits; marine Compatibility fallback.
- Granite/lichen shores, canopy filtering, boreal maple/rowan mixes, Baltic water and calm ornamental pools.
- Climate-aware freezing March, snow on street objects, Ultra snowbanks, soft partial sea ice.
- Ten Helsinki and five Espoo bespoke landmarks. [Helsinki dimensions and sources](../../../docs/helsinki-landmark-sources.md), [Espoo dimensions and sources](../../../docs/espoo-landmark-sources.md). These models include explicitly documented approximate envelopes.

The harbour review exposed a consistent roughly 17 m sea-side Terrarium elevation offset. `CoastalDem` measures a low-spread northern coastal sample set and registers qualifying terrain before GroundTruth (Helsinki 17.07 m; Espoo 17.31 m). Raw cached tiles remain unchanged. This is measured coastal registration, not an asserted vertical-datum conversion. The final captures also include the concurrent canonical shoreline implementation; its work is not claimed as part of this pass.

## Measured capture budgets

| Candidate | Generation, cold geometry | Wire surfaces / budget | Golden sun | Opening luma / saturation / colourfulness |
| --- | ---: | ---: | ---: | --- |
| Helsinki summer | 23.242 s | 8 / 12 | 12.22° | 0.661 / 0.246 / 0.121 |
| Espoo summer | 15.323 s | 0 / 12 | 12.29° | 0.639 / 0.198 / 0.122 |
| Helsinki January | 13.245 s | 8 / 12 | 8.75° | 0.648 / 0.260 / 0.140 |
| Espoo January | 12.631 s | 0 / 12 | 8.69° | 0.722 / 0.165 / 0.102 |

These pipeline generation times exclude data fetch and meet the ≤150 s cold generation budget. Captures used Ultra, clear weather, Metal, 1280×800 and off-screen windowed background runs. Wire counts measure merged mesh surfaces, not profiler frame draw totals. No boat budget is claimed: the shared quay/boat task remains open.

The June late views have sun −6.14° and luma about 0.178 in both cities, showing white-night twilight. January late views are dark (sun −13.44°). Summer Espoo falls within the broad reference metric ranges; Helsinki is too bright. Winter saturation/colourfulness exceed the winter reference ranges in both cities. Reference photos differ in framing, season date and weather, so the metrics flag review questions rather than certify realism.

## Verification and limits

Twenty-four headless regression scripts passed, including architecture, climate, road/parking, marine, scenery, shoreline, both new landmark batches, catalog and fidelity geometry checks. The catalog contains 483 landmarks. [Exact test list and statuses](validation/headless-summary.txt). Marine-layer tests also passed explicitly with `gl_compatibility`.

The final off-screen windowed batch passed `world_cache_test` and `screenshot_test`; [UI screenshots](ui-screenshots/) are retained. World-cache cold load was 36.849 s and cached revisit 10.534 s: cache correctness and faster revisit passed, but the revisit exceeds the general 8 s target. Shader/parse failures were absent in the valid captures. Some tests and captures emit image-loading diagnostics or exit-time Texture/ObjectDB leak warnings; these logs are retained and are not represented as clean runs.

Tests and captures ran against an isolated source snapshot because other sessions were editing this tree. Shared raw data, assets and texture imports were reused; History, preferences and generated world caches were isolated. A snapshot-only environment guard disabled world scene saving during captures, and was unset for the real cache tests; it is not shipped in repository code. [Verified source hashes](validation/verified-source.sha256) and [files changed concurrently afterward](validation/concurrent-source-differences.txt) bound the verification claim. A final shared-tree headless editor import and class-size check passed; no class exceeds 1000 lines. The five-location global fidelity run timed out after three complete reports. Its water filter was then found to exclude per-body material copies; those reports are retained as before-filter diagnostics, not valid water failures. The filter now compares the water shader and asserts that an Ultra material copy is included while a bank material is excluded. The corrected Turku-only rerun passes water, building footprints/heights, roads and landmark bearing; its existing DEM check still fails (max 13.21 m / mean 3.20 m over 9 land points (bar ≤ 3 m)). Thus `fidelity_scorecard_test` is explicitly **failing**, separate from the 24 passing regression scripts. [Report](validation/global-scorecard/scorecard-turku-high.md).

## Remaining work

The photographic loop is still open. Highest-value visual work is waterfront facade proportions and roof detail, quay/pool perimeter geometry, land/material transitions, and winter colour matching. Human visual ratings have not been supplied. Shared G-5/G-6 and the Stockholm/New York city work remain on their separate trackers. The task-owned source copies and isolated user-data caches have been removed; free disk space was 5.9 GiB after cleanup. Diff/new-file backups remain in `/tmp/planet-helsinki-hero/`. No commits or pushes were made.
