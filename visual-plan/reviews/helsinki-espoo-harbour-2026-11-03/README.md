# Helsinki and Espoo — harbour refinement, 3 November 2026

Shared G-6 now supplies regional quay stone, Ultra mooring bollards and
alongside steam/houseboat dressing. Mapped `building=ship|boat|houseboat`
features use oriented hulls and stepped deckhouses instead of apartment
extrusion. This completes the shared harbour task; both cities remain
**recognisable** in this pre-review, with the photographic target open.

![Mapped vessel and bollards beside Kanavaranta, summer](../harbour-summer-2026-11-03/helsinki_look0.jpg)

[Winter at the same eye](../harbour-winter-2026-11-03/helsinki_look0.jpg) ·
[Harbour overview](../harbour-summer-2026-11-03/helsinki_roofs.jpg) ·
[Wheel clearance](../harbour-summer-2026-11-03/helsinki_h090.jpg)

## Behaviour

- Quay material follows `KerbBuilder.stone_for`, keeping European granite
  separate from North American concrete. Cached materials are keyed by colour
  so visiting another region does not recolour an existing scene.
- Ultra places up to 24 alongside vessels within the marina's 800 m eye radius.
  Mapped quays/retaining walls or finalized hard banks qualify; dry walls,
  natural shores, ornamental pools, shallow water and obstructed hulls reject
  berths. Existing pontoons and boats share occupancy with the new fleet.
- Mapped vessels use the actual oriented footprint for length, beam and bow,
  and the local rendered water datum. Explicit height wins, followed by levels
  or a bounded length-based fallback. Mast heights do not affect neighbouring
  building estimates. Tagged sailing types get masts; missing type uses a
  generic motor-vessel silhouette. These are simple procedural models, not
  reconstructions of individual ships.
- All tiers retain mapped hulls; Ultra adds rails and quay dressing, while Fast
  avoids detail normal maps. Deck/cabin materials support snow in both mapped
  meshes and instanced quay boats. No third-party boat assets were added.
- The 20-surface marina budget includes pontoons and all four instanced boat
  types. Individual mapped building-layer vessels and the merged bollard mesh
  are outside that budget.

## Captures and budgets

| City / season | Views | Generation | Marina surfaces | Wire surfaces | Opening luma / saturation / colourfulness |
| --- | --- | ---: | ---: | ---: | --- |
| Helsinki / summer | [21 June](../harbour-summer-2026-11-03/helsinki_vantage.jpg) | 36.975 s | 13 / 20 | 8 / 12 | 0.642 / 0.259 / 0.128 |
| Helsinki / winter | [15 January](../harbour-winter-2026-11-03/helsinki_vantage.jpg) | 36.635 s | 13 / 20 | 8 / 12 | 0.649 / 0.250 / 0.146 |
| Espoo / summer | [21 June](../harbour-summer-2026-11-03/espoo_vantage.jpg) | 6.994 s | 8 / 20 | 12 / 12 | 0.639 / 0.204 / 0.124 |
| Espoo / winter | [15 January](../harbour-winter-2026-11-03/espoo_vantage.jpg) | 7.208 s | 8 / 20 | 12 / 12 | 0.722 / 0.169 / 0.104 |

Generation excludes fetching and meets the 150 s target. End-to-end summer
loads were 188 / 78 s, and winter 45 / 15 s. January opening sun elevations
are 8.75° / 8.69°. The full directories include cardinal views, close-ups,
overviews, late views, reference sheets and `stats.json`. The optional
Kanavaranta eye applies only to Helsinki; the tool's out-of-area Espoo sample
was excluded from the delivered images and statistics.

Helsinki's mapped vessel now has a nautical silhouette, and bollards are visible
at the quay. Small pier boats still look simplified. The wheel remains clear
of the building. The Enso office still masks much of Uspenski. Espoo's pool has
no harbour vessels, but its perimeter and adjoining building masses remain
coarse. Winter frames are brighter and more colourful than the references;
the differing weather and ice cover also limit direct image-stat comparisons.
None of these frames earns a photographic pre-rating.

## Verification and evidence bounds

Seven focused headless scripts pass: `ship_builder_test`, `quay_moorings_test`,
`marina_test`, `osm_test`, `architecture_test`, `shoreline_test` and
`parallel_build_test`. New cases cover rotated map envelopes, bow selection,
height priority, rendered water datum, outward normals, parser normalization,
quality gating, deterministic alongside berths, pool/dry-wall vetoes, bollards
and material/draw budgets. Serial and parallel output agree. Current-tree quay
and marina checks also pass. Class-size and whitespace checks pass.

All Godot jobs ran in background execution sessions; captures used
`tools/godot_bg.sh --position 4000,4000`. Source scripts and user preferences
were isolated. Raw fetch cache, assets, imported textures and the native binary
were shared. World-cache saving was disabled with the existing capture option.
The native debug library's modification time predates both capture rounds.

These images represent the combined tree at the GDScript snapshot, with world
cache version 126, rather than an isolated G-6 A/B comparison. The shared tree
continued changing; [source hashes](source-hashes.json) and
[later differences](concurrent-differences.json) bound this evidence. In
particular, later mooring rings, shore railings and marina-mask changes are not
demonstrated by these images. They were preserved; current-tree import and
quay/marina tests check integration. The current cache version has advanced
through concurrent changes.

[Validation logs](validation/) retain existing raw-image import warnings and
the editor's missing Blender-path error. The first shared-tree import caught
a concurrent Västerbron typing error; the author's correction was present
before the successful rerun. No script parse errors remain in that rerun.
The first winter capture exhausted disk space and was rejected; its log is
retained. The replacement round completed and every delivered JPEG decoded
successfully. No commits or pushes were made.

After copying the evidence, the task-owned source snapshot, private user-data
directory and downloaded reference intermediates were removed; 1.9 GiB was
free. Raw user caches and shared assets were preserved. Diff/source backups
remain under `/tmp/pr360-harbour/`.

## Next concrete correction

The cached Old Mint (`Vanha rahapaja`, OSM way 23192814) has no height/levels
tags and resolves to six storeys / 20.76 m. The owner's restoration elevations
show two floors and a pitched sheet-metal roof: see printed pages 14–15 of
[Senaatti's restoration report](https://www.senaatti.fi/app/uploads/2017/05/3168-2013_Mustonen_Hki_Rahapaja_Kunnostusraportti_web.pdf).
This supports a source-backed building-data correction. No exact surveyed
height or new building override is asserted in this round. The diagnostic log
is included alongside the validation evidence.

Later before/after inspection corrected the initial identification: the
dominant foreground block is the Enso office, not the Old Mint. The Mint is
the separate building to its right; its missing dimensions still need the
source-backed correction described above.
