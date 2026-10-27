# Visual target — 360 scenery (from prototype `refs/view360-paris.jpg`)

Reference: warm low-poly Paris panorama at golden hour — dense cream
Haussmann blocks with dark slate mansard roofs, the Seine curving through,
rows of green trees, the Eiffel Tower as the silhouette landmark, soft
hazy horizon, sky grading peach → pale blue.

## Diagnosis of the current build (why it reads wrong)

1. **Scale is broken.** OSM footprints arrive in world units (metres ×
   0.25) but building heights are multiplied by 0.6 instead of 0.25, so
   every building is ~2.4× too tall — slabs, not city blocks. The camera
   sits 22 world units (≈88 m) up and looks down on them.
2. **Terrain is flat-lit and bleached.** All vertex normals point up, the
   palette keys off absolute height (Paris lands in pale dry grass), and
   sky-ambient + sun overexpose it to near-white.
3. **No city fabric.** Plain wall boxes, slab roofs, no windows, sparse
   cone trees, roads floating as dark planks.
4. **No horizon.** The 220-unit terrain disc ends in a brown void band;
   no far ground, no aerial haze. (Fixed: flat apron + real zoom-8 DEM
   far terrain to 9 km; the earlier procedural ridge ring is removed.)

## Acceptance criteria (checked on captured screenshots)

- Paris: ground reads as warm city pavement/greenery, never near-white;
  buildings at believable 4–7 storey proportions with window grids and
  sloped dark roofs; no building taller than ~2× its neighbours except
  the landmark.
- Camera near eye level over the rooftops; horizon sits in the upper
  third with haze, not a hard terrain edge.
- Eiffel-type landmark reads as four legs + platforms + spire, not
  stacked cylinders; generic places get a slimmer tower.
- Trees are two species (broadleaf on trunks, pines), varied green,
  dense enough to line streets/parks without covering buildings.
- Interlaken/Banff: slope shading shows relief (rock on steeps, snow
  only on high cold tops is out of scope — rock/grass/dry by slope and
  height), water a deep blue plane, far ground fades into fog.
- Performance guard: nearest ~260 real buildings only, shared materials
  (≤6 facade/roof materials total), no per-building unique resources.

## Palette (linear-ish Godot colours)

- Limestone facades: cream (0.87,0.82,0.70), sand (0.82,0.74,0.60),
  pale rose (0.85,0.76,0.68); roofs slate (0.30,0.34,0.40) ± variation.
- Urban ground (0.62,0.59,0.53); grass (0.45,0.58,0.36); forest
  (0.26,0.40,0.24); dry (0.70,0.63,0.45); rock (0.48,0.46,0.43).
- Water (0.16,0.36,0.48); far ground blends toward the horizon colour.
