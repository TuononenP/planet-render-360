# Round 2: tier exposure, canopy shade, cost cuts

Left: round 1 (High at 79ad687; for Fast, the re-capture after the
ground-roughness fix). Right: 45fcaef. Same capture setup as the parent
folder (lavapipe, Xvfb).

- **Fast (Mobile renderer):** exposure is 0.86x and contrast +0.05 on the
  same curve. Mapped tree crowns and forest cover now shade the ground,
  so forest slopes in the detailed area read darker and greener than
  their clearings.
- **High:** ground-cover tufts are brighter and flared and stay within
  half the radius, so the dark specks on the Interlaken meadow are gone.
  Cloud shadows and per-building tints on the distant city are now in
  the build.
- **Cost:** Paris High builders, timed headless: 62 s → 45 s (43 s before
  the upgrade). The texture arrays no longer pack roughness, the far city
  skips tangents, and roads read urban land from a raster. Shader work
  drops with distance.

Tests: full suite PASS except the pre-existing Turku (a); the extended
`render_upgrade_test` passes on the current tree.
