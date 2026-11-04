# New York hero continuation — 2026-11-04

The implementation pass improves the existing New York scene; the agent pre-rating remains **recognisable**, with the photographic human gate pending. Keep the opening at 08:00. Bearing 295° gives Liberty a visible left margin while retaining One WTC.

## Review evidence

- [Baseline r21](../nyc-r21-2026-11-04/README.md): current-tree capture before this pass, using the old partial detailed response.
- [r26 opening and close views](../nyc-r26-2026-11-04/README.md): corrected facade resolution, pale Woolworth cladding, glass-sided Oculus, bridge entrance, carousel and Pier 1 rail/bench. [Mapped identities and part audit](../nyc-r26-2026-11-04/mapped-audit.json).
- [r27 waterfront](../nyc-r27-waterfront-2026-11-04/README.md): source-backed Whitehall glass/steel finishes and Brooklyn Tower view. The terminal keeps its five mapped parts; adjacent structures and angular shoreline remain visibly simplified.
- [r30 lantern and crown detail](../nyc-r30-lantern-2026-11-04/README.md): closest views verified the 70 Pine lantern after fixing part-level storeys and inherited masonry relief.
- [r28 crowns](../nyc-r28-crowns-2026-11-04/README.md): targeted 40 Wall, 70 Pine, Municipal Building and Woolworth views.
- [Ferry gallery](../nyc-ferry-2026-11-04/README.md): concurrently refined double-ended hull, pilothouses and passenger decks; berth tests pass. Vessel changes from the other work were preserved.
- [Fast and High](../nyc-tiers-2026-11-04/README.md): opening/bank captures completed, with 9 s / 11 s cached load/build times.

The wider query completes clipped edge buildings by exact OSM identity, preserving detailed tags and suppressing duplicate far geometry. In particular, 200 Vesey gains eight mapped parts instead of one. Named/unnamed targets are identified as 200 Vesey `way:277919047`, Goldman Sachs / 30 Hudson `way:259686624`, 99 Hudson tall part `way:1252090828`, and Brooklyn Tower `way:1039403183`.

## Lighting and performance

| Capture | Conditions / references | Vantage colourfulness |
| --- | --- | --- |
| r21 baseline | Clear summer, 08:00; old overcast comparison | 0.1370 |
| r26 | Clear summer, 08:00; clear autumn morning photo | 0.1290 |
| r27 waterfront | Clear summer, 08:00; clear autumn morning photo | 0.1292 |
| Morning reference | Pier 1, 2023-10-05 09:14 | 0.1780 |
| r24 | Overcast summer, 08:00; existing overcast photos | 0.0665 |
| Overcast references | Root comparison set | 0.026–0.039 |

The clear-morning comparison does not support globally desaturating the scene. The single reference differs in date/time and is diagnostic rather than an acceptance range. The overcast comparison still exceeds its reference range. Geometry simplification, facade repetition, shoreline terrain and coarse reflections prevent a photographic rating.

A complete live q12 detailed response returned 22,372 elements in 43.73 s (16,196,642 bytes); parsing yields 1,900 buildings. The final healthy cached opening took 14 s, including a 7.840 s parallel generation phase. Far city took 530 ms for 276,362 triangles / 302 meshes. These counters do not establish rendering FPS or a draw-call acceptance limit.

The isolated empty-cache run opened in 53 s but received HTTP 403 responses for far city, ring and POIs and used reduced map geometry. It **does not pass** the full-data ≤150 s cold-load target. The first cold attempt was invalidated by disk exhaustion. Only task-created cache/world files were removed to recover space.

## Verification

- 26 checks pass in [the regression batch](tests.json); the live five-city fidelity scorecard exceeded its 180 s execution budget.
- The additional waterfront-material test passes, bringing focused/regression passes to 27. Final payload, crown, far-city, architecture and building-fabric reruns pass after the last related changes; their logs are in this directory.
- [Both windowed checks pass](windowed-tests.json). Cache test: first visit 59.081 s, identical cached revisit 4.714 s, budget eviction verified. Screenshot test completed its phone/desktop capture sequence.
- [Focused Turku scorecard](scorecard/scorecard-turku-high.md): reproduces the previously recorded DEM (a) failure; building footprint/height, water/road presence and landmark checks pass.
- [Class-size check](class-size.log): largest class 806/1000 lines. `git diff --check` passes.
- Godot runs used the background wrapper; windowed captures/tests used `--position 4000,4000`. Nonfatal texture/ObjectDB exit warnings remain in several capture logs; no new leak-free claim is made.

## Remaining gates

1. Photographic quality and the final human rating.
2. Complete-data cold load within 150 s under healthy source availability.
3. A verified golden-hour Commons photograph specifically from Pier 1. Existing morning, night and street sources remain attributed; the DUMBO golden-hour image is not relabelled as Pier 1.
4. An acceptable close in-world subway entrance inspection. The live mapped York Street node is confirmed, but the two fallback capture attempts are rejected as visual evidence.

Reproduce normal captures with `tools/godot_bg.sh --path . --script tools/capture_presets.gd --position 4000,4000 -- --tag=nyc-review --preset=3 --places=new_york --refs=morning`. Omit `--refs=morning` and add `--weather=3` for overcast. `--cold-cache` isolates data caches; `--pin=lat,lon` supports separate mapped-site inspections. Run these in the background.
