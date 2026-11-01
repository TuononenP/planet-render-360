# Render quality pass 3 — the items left open in passes 1 and 2

Same setup as `../render-quality-2026-10-30/`: High preset, Forward+,
17:00, fair weather, governor off, 960×600, software Vulkan (lavapipe)
under Xvfb, OSM from `api.openstreetmap.org` converted to the Overpass
shape. fps was not measured. Each artifact was traced before it was
changed: layers hidden one at a time, an object-ID pass (every mesh
surface a flat unshaded colour), a world-position pass, and an albedo pass
(sun off, flat white ambient, linear tonemap).

| Capture | Cause found | Change |
|---|---|---|
| `cmp_paris_courtyard_roof.jpg` | The "faint lines" were the courtyard block's own inset roof. Its mapped footprint has 243 vertices, stepping in and out by decimetres; every step became a narrow slope facet facing sideways that caught the sun as a pale fin. | `RoofGeometry.simplify_ring` (closed-ring Douglas–Peucker, 0.9 m) runs before the inset roof: that ring goes 243 → 19 vertices; all 874 inset rings in Paris take 144 ms. |
| `cmp_bixby_hillside.jpg` | Not albedo: the pale patches measured ~0.25 albedo in the albedo pass. Two things lit them white: the crag relief bent the lighting normal on any steep ground, grassy or not, and at exposure 1.45 a slope facing the low sun (~3.4× the light of flat ground) compressed to colourless white. | Relief, the cliff blend and the stone tint are held back by the imagery's greenness (near ground and far rings). Exposure 1.45 → 1.25. |
| `cmp_interlaken_mountains.jpg` | Forested mountainsides were frosted with pale speckle: the same relief and steep-face stone treatment applied to forest; the albedo pass showed smooth green there. | Same greenness gate in `FarSurface` and `GroundShader`. |
| `cmp_walls.jpg` | The orange "timber boxes" in Paris and Interlaken are OSM `barrier=wall`. They used the `stone` set, an orange sandstone photo (mean blue 0.049) multiplied by a near-white tint. | Walls use limestone calibrated to grey-beige masonry (`StreetProps.WALL_STONE`). |

**Roads:** no defect found. The violet footpaths in Interlaken run through
tree shade, where only blue skylight reaches them; main roads are neutral
with correct markings.

**Remaining:** the far-left Interlaken range (beyond the detailed ground)
still shows some pale mottling that is in the low-resolution far imagery
itself.
