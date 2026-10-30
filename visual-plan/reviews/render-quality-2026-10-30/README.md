# Render quality pass — 2026-10-30

Top: `main` at 7d8f1c3. Bottom: this change. High preset, Forward+, golden
hour (17:00), fair weather (code 1, 25% cover), governor off, 960×600.
Captured with **software Vulkan (lavapipe) under Xvfb**: the shading is
real, fps is not (not measured here, nor on a phone).

**Data caveat.** Overpass was unreachable from the capture container, so
OSM came from `api.openstreetmap.org`, converted to the Overpass `out geom`
JSON the parser reads (same tags, geometry and cache keys). DEM, imagery,
far-field and climate were live. Counts and layout can differ slightly from
an Overpass fetch.

| Capture | What changed |
|---|---|
| `cmp_interlaken_yaw180.jpg` | Untagged buildings in a small town no longer default to 8–9 storey slabs: the regional default is capped by the place's own tagged median (`BuildingHeights`). Wall tints are capped at clean-white albedo (0.72) so facades stop clipping. The lawn is darker and richer, with lush/sun-dried patches; ground cover is tinted to match and open lawns no longer scatter dark shrubs. Forest and rock read darker and warmer (`t_dehaze`). |
| `cmp_interlaken_yaw90.jpg` | Same, looking along the meadow. Dark confetti tufts are gone. |
| `cmp_paris_yaw90.jpg` | Lawn leaf green instead of mint-lime, sun glare and aureole through the cloud. |
| `cmp_paris_roof.jpg` | Large courtyard (concave) blocks get a chamfered roof that follows their eave instead of an apex fan from one point, which sheared into spokes with a serrated edge. U-shaped blocks, whose interior point falls in the courtyard, used to get no pitched roof at all. |

**Not fixed / not verified**

- At Bixby Bridge the near hillside still shows pale chalky patches; they did
  not move with the albedo cap, so the source is elsewhere.
- Faint thin light lines remain near some courtyard roof edges in the Paris
  close-up; the roof mesh for that block checks out (all vertices inside the
  footprint), so they come from something else.
- Nice (OSM from the API) did not finish building within 9 minutes at
  far-city, on `main` as well as here. Cause not found; the sea was not
  captured for that reason.
- Water, roads and the sea were not changed. A narrower river foam band was
  tried at Bixby; the creek there is a sky mirror, not foam, so it was reverted.
