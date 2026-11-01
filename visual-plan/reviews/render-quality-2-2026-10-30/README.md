# Render quality pass 2 — sea, and the Nice build that never finished

Follow-up to `../render-quality-2026-10-30/`. Same setup: High preset,
Forward+, 17:00, fair weather, governor off, 960×600, software Vulkan
(lavapipe) under Xvfb; OSM from `api.openstreetmap.org` converted to the
Overpass JSON shape (Overpass was unreachable). fps was not measured.

## Nice never finished building (fixed)

`WaterSurface.add_polygon` triangulates a water body with
`Geometry2D.triangulate_delaunay`. For a bay clipped to the 2.4 km extent
(long collinear edges, a regular interior lattice) Godot's Delaunay
degenerates: 2,401 points took **381 s and returned 247,934 triangles**
(a valid triangulation has ~4,700). The generation thread looked hung
after `FAR-TERRAIN built`; on `main` the view never appeared.

- Points are now nudged deterministically before triangulating: 2 cm on the
  shoreline, a fifth of a cell inside. The same points take 40 ms and give
  4,671 triangles.
- A polygon part gets at most `MAX_INTERIOR_POINTS` (4,000) interior samples.
- Nice now builds in ~30 s. `tests/render_upgrade_test.gd` builds a 2400×665 m
  bay and fails without the fix (37,004 triangles).

## The sea (`cmp_nice_sea.jpg`)

Top is Nice after the Delaunay fix only (the first time its sea could be
rendered); bottom is this change.

- **Swell aliasing:** the sea grid is 12.5 m, the displaced swell was 46 m and
  27 m (~2 samples per wave), so vertices sheared into rows of dashes toward
  the horizon. Displaced swell is now 118 m and 74 m.
- **Brown strips:** the DEM has no seabed, so the terrain mesh sits at sea
  level and swell troughs below the datum showed ground through the water.
  The swell is lifted so it only rises from the datum (damped to zero at the
  shore).
- **Colour:** the open sea has its own palette (turquoise over the shelf, deep
  blue beyond) and the shelf gradient spans ~150 m instead of a river's 30 m.
  Rivers and lakes keep their colours.

## Still open

- Faint thin light lines across a Paris courtyard next to the spawn roof
  (cause not found; the roof mesh itself is clean).
- Bixby Bridge: pale dry-ground patches that stay near-white. Lowering the
  ground albedo cap did not change them, so they read as sunlit pale ground
  at grazing light rather than a wrong albedo; not changed further.
- Roads and mountains were not changed in this pass.
