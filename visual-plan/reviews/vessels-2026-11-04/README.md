# Realistic ships and boats — 4 November 2026

All existing vessel families now use smoother near hulls, shaped cabins and marine materials. The additional detail requested in the second pass is enabled on desktop Ultra: helms, winches, ladders, framed portholes, rope runs, ratlines, double rails and liner balconies with furniture. High retains the lighter first-pass forms; existing far meshes retain their triangle counts.

[Whole fleet](fleet-sheet.jpg) · [Before / first pass / Ultra comparison](comparison.jpg) · [Catamaran deck](after/catamaran_deck.jpg) · [Monaco near catamaran](../vessel-catamaran-near-2026-11-04/monaco_catamaran_deck_0.jpg)

## Behaviour

- Hull normals are shared across paint boundaries. Chines and transoms retain deliberate edges; near hulls close the stem, transom and deck margins. Open cockpits expose a recessed sole. Tube normals also meet across closed loops.
- Gelcoat, metal, rubber, canvas, teak and glazing use separate marine finishes. Teak has narrow boards and caulk; glass no longer inherits an architectural concrete texture. Instance paint and live snow remain separate.
- Coastal Mediterranean marinas select deterministic 10–22 m sailing catamarans among the sailing berths. They have two hulls, an open tunnel, supported bridge deck, shaded cockpit, helm, foredeck netting and rigging. Their reservation includes the 0.58-length beam of hulls and fenders, plus clearance; outer-hull samples reject obstructions. Inland lakes and non-Mediterranean regions retain their existing selection.
- Monaco generated ten catamarans: five near and five far. Region fixtures also cover the French Riviera, Mallorca and Croatia. These are procedural scenery, rather than reconstructions or live vessel positions.
- Existing builder signatures, the 250 m near/far threshold, quality gates and instancing remain. World-cache build version is 172. The extra Ultra pass uses bounded larger near budgets; distant budgets remain fixed. No commits or pushes were made.

## Geometry and batching

| Model | Original near | First pass | Final Ultra | Far |
| --- | ---: | ---: | ---: | ---: |
| Sport cruiser | 872 | 3,262 | 7,852 | 332 |
| Flybridge yacht | 1,250 | 4,498 | 10,044 | 390 |
| Sailing yacht | 1,432 | 4,374 | 11,176 | 480 |
| Catamaran | New | — | 13,702 | 644 |
| Rigid inflatable | 1,244 | 3,908 | 7,558 | 720 |
| Runabout | 748 | 2,532 | 5,366 | 404 |
| Centre console | 776 | 2,708 | 5,606 | 432 |
| Houseboat | 646 | 2,144 | 6,826 | 274 |
| Passenger ship | 3,824 | 8,094 | 22,652 | 636 |
| Tall ship | 2,302 | 5,090 | 12,580 | 638 |
| Cruise liner | 14,584 | 33,640 | 94,170 | 936 |
| Staten Island ferry | 1,620 | 8,000 | 16,142 | Ultra only |

The exhaustive eight-kind near/far fleet plus one pontoon uses **80 surfaces**, meeting the existing limit. The original seven-kind fleet alone used 99. Identical materials are merged; far fittings share a small palette. Captured marina totals were Monaco 74, Helsinki 56, New York 42 and Stockholm 39. Individual liner geometry remains outside the instanced fleet ceiling.

## Cost comparison

Three paired runs use the same 700-boat legacy fleet, Forward+, an Apple M3 Max and a 960 × 640 viewport. Catamarans have separate geometry measurements and are excluded from that fixed A/B fleet. Materials are warmed before prototype timing.

- Median creation of the fourteen legacy near/far prototypes: 88.70 ms before, 199.65 ms after.
- Median forced-draw frame loop: 8.33 ms before, 8.84 ms after.
- The loop remains display-paced even after requesting disabled VSync. Metal GPU timestamps return zero on this setup. These measurements are a rendering smoke test and generation-cost comparison, not an uncapped GPU/FPS claim.

[Raw paired measurements](performance/) · [Source hashes and summary](summary.json)

## Verification and visual evidence

Nine headless suites passed: vessel models, catamaran marina, mapped ship builder, marina placement, quay moorings, harbour ferries, roof snow, parallel build and world-cache keys. Class size and whitespace checks passed. Tests cover near budgets, fixed far costs, the exhaustive draw ceiling, outward finite normals, shared paint-boundary normals, recessed cockpit floors, Ultra/High separation, catamaran tunnel clearance and full-beam berth rejection.

[Validation logs and exit codes](validation/) retain the headless import warning about the existing unset Blender path. Capture shutdown reports Texture/ObjectDB leak warnings from the application capture harness; no script errors or rejected frames occurred in the completed runs.

Matching local model views cover bow, stern, elevated side, deck inspections and far variants; representative sailing yachts and houseboats also have winter views. The raw capture JPEGs remain local under the repository ignore rules; the curated comparison, fleet sheet, catamaran deck and Monaco close-up are included for review. The new catamaran has no original-model comparison. Final studio views use the final source hashes above.

[Summer harbour integration](../vessel-harbours-ultra-2026-11-04/) covers Helsinki, Stockholm, Monaco and New York; [winter integration](../vessel-harbours-ultra-winter-2026-11-04/) covers Helsinki and Stockholm. The final [Monaco near-model review](../vessel-catamaran-near-2026-11-04/) prioritizes near catamarans and uses overcast light to expose deck details. Earlier sunny Monaco close-ups selected the largest far catamarans and are retained as far-variant evidence.

The four-city run preceded the final catamaran bridge-support/anchor refinements and closed-tube seam correction; the final studio and Monaco near review include those corrections. The nine focused suites and final source hashes cover the completed tree. Existing unrelated captures were preserved. All Godot jobs used the no-activation wrapper in background execution sessions; windowed jobs ran off-screen at 4000,4000. World-cache saving was disabled for city captures.
