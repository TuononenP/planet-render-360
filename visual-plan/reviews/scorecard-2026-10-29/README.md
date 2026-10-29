# Fidelity scorecard run — High — 2026-10-29

Produced by `tests/fidelity_scorecard_test.gd` (T8.1; sample rules v1
2026-10-29), headless in the cloud container, cached data where present
and live OSM/DEM/satellite otherwise. One report per location:
`scorecard-<location>-high.md`.

| Location | (a) DEM | (b) footprints | (c) heights | (d) water | (d) roads | (e) landmark |
|---|---|---|---|---|---|---|
| Paris | PASS 1.28 m | PASS IoU 1.00 | PASS 0.00 m | PASS 5/5 | PASS 5/5 | PASS 0.04° |
| Interlaken | PASS 5.87 m | PASS IoU 0.81 | PASS | PASS 5/5 | PASS 5/5 | N-A |
| Banff | PASS 0.29 m | PASS IoU 1.00 | BLOCKED (no tagged sample) | PASS 5/5 | PASS 5/5 | N-A |
| Big Sur | PASS 1.03 m | PASS IoU 0.89 | PASS 0.00 m | PASS 5/5 | PASS 5/5 | N-A |
| Turku | **FAIL 3.19 m** (bar 3) | PASS IoU 0.95 | PASS 0.24 m | PASS 5/5 | PASS 5/5 | PASS 0.03° |

Not automated, recorded in every report: (e) apparent height + AC-06
silhouette and the AC-14 counters need a windowed run; (f) is the signed
human rating (Paris PENDING, others NO-REFERENCE).

## Defects the scorecard found and fixed this session

1. **Fountains / small ponds buried** (Paris (d) 2/5) — sub-post water
   bodies sat under the terrain; WaterBuilder now rests them 6 cm above
   their ground (commit "Rest sub-post water bodies just above their
   ground").
2. **Turku had no OSM data** — a null way node in the Overpass response
   aborted the parse, every endpoint was retried until 503; parser fixed
   and covered fail-closed in `osm_test.gd`.
3. **Terrain ~1% compressed toward the centre** (Interlaken (a) 8.3 m)
   — GroundTruth now samples the DEM per post at its true position
   (`DemRegistration`); Interlaken max 8.31 → 5.87 m, every other point
   ≤ 0.1 m.
4. **Every building 0.6 m short** (Big Sur (c) 3.2 m, Paris median
   0.87 m) — the foundation sink ate the height; heights now stand above
   the ground (medians 0.00 m).

## Open

- **Turku (a)** — (0, 400) reads −3.19 m on a steep bank (≈16 m drop
  over 40 m) in a location the scorecard classes as flat (3 m bar): the
  3×3 smoothing on a 9.4 m grid. Kept as FAIL, no bar change; options:
  per-location bar from measured relief, or slope-aware smoothing.
- **Interlaken (0, −400)** −5.87 m (passes the 8 m bar) is the Aare
  bank inside the carved channel's bilinear reach.
- **Banff (c)** — no sampled building carries height/levels tags.
- **(c) outliers** — buildings with taller `building:part` masses read
  the tallest part (e.g. Paris levels 4.6 → 23.0 m); medians are robust.
