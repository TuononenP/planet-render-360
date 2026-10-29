# Architecture styles — buildings by country and type

Why: every building used to share one Parisian window grid (French windows,
cornices, balcony rails, six bays), differing only in wall photo and tint, and
the regional defaults knew four Paris-centric classes. A Finnish apartment
block, a Cairo flat-roof house and a Tokyo mansion block rendered alike.

How it works (plan risk R5 — the table is data, reviewable, and never
outranks the map):

1. **Region** — `ArchitectureStyle.region_for(lat, lon)`: first match in the
   coarse, ordered box table `ArchitectureData.BOXES` (17 style regions, e.g.
   `nordic`, `middle_east`, `japan`, `north_america`). Borders are
   approximate; `tests/architecture_test.gd` pins 51 cities.
2. **Kind** — `ArchitectureStyle.kind_for`: OSM `building=*` value
   (`house`, `apartments`, `warehouse`, `barn`, `church` …), then a `use` hint
   (`amenity`/`shop`/`office`/`tourism`/`craft` on `building=yes`), then
   `building:levels`, footprint area and settlement density. Eight kinds:
   house, apartments, commercial, industrial, religious, civic, farm,
   outbuilding. A house is judged against neighbouring *houses* only when
   estimating an untagged height.
3. **Profile** — GENERIC ← base region (`alpine`→`central_europe`,
   `haussmann`→`france`→`central_europe`) ← region row, per kind: wall finishes
   + palettes, window pattern and bay width, roof shapes + pitch + finish,
   floor height, storey range, chimney/dormer/rooftop-plant odds, tower kind.
4. **Resolve** — `ArchitectureStyle.resolve` picks one look per building from
   its position hash (stable across runs), so a street is not a row of clones.
5. **Real data wins** — `building:material`, `building:colour`, `roof:*`,
   `height`, `building:levels`, `roof:height`, `religion`/`denomination` and
   the satellite roof sample are applied on top of (and replace) the style.

## What differs

| Area | Mechanism |
|---|---|
| Facade | `FacadeComposer` tiled patterns: `punched`, `strip`, `balcony`, `clapboard`, `industrial`, `adobe`, `curtain`, `tiles` (Japanese tiled front). One 512×128 storey cell (4 bays) repeats per real storey and bay, so windows keep their size on any wall; edges under half a bay show the blank margin only. A profile's `p` may be weighted (`[["punched", 6], ["balcony", 2], ["strip", 1]]`), so a street mixes fronts. Window vocabulary `wn` per region: `casement`, `french` (Paris, Mediterranean, Belle Époque), `sash` (UK, US), `wide` (Japanese/East Asian aluminium sliders), `small` (chalets, timber houses); `rl` = share of windows with a wrought-iron balconette. |
| Paris | `StoreyComposer.compose_haussmann`: rows = real storeys counted from the ground — rusticated shopfront ground floor with lacquer fascias and a carriage door, entresol, continuous balconies on the 2nd and 5th floors, balconettes, pedimented noble floor, dentil cornice, base grime; 2.4 m window pitch (PRD §4.2); zinc/slate mansards around #46525E. |
| Ground storey | Profile `g` (`shop`, `signage`, `render`, `stone`, weighted with `none`) gives tiled buildings a separate ground band (`StoreyComposer.compose_ground`, `FacadeMaterials.ground_for_building`): shopfronts with region fascia palettes (`gc`), Tokyo signage bands with hanging signs, a chalet's white rendered base under timber, a rusticated civic plinth. Not on distant blocks or at Fidelity 1. |
| Variation | Each building draws a deterministic variant (0–2) from its position hash: which bays carry shutters, blinds, lit or curtained panes, loggia/parapet/railing kind, Paris pediments, balconette rhythm and fascia colour — plus the palette tint and weighted pattern. |
| Glass | Curtain walls are sky-reflective blue-grey with aluminium mullions, transoms and light spandrels (no more black slabs); a `building:colour` on glass tints the hue, never darkens the albedo. Ribbon (`strip`) panes stay window-dark with a sky band. |
| Walls | Bundled CC0 sets (limestone, stone, render, brick, concrete, wood, glass) tinted from the region palette; brick/terracotta tints keep 60 % of their own chroma (calibrating a red photo toward red made pink mortar and stripes); clapboard rotates the plank photo; concrete and render contrast is softened at bay scale. |
| Roofs | Shape mix + pitch per region/kind, ridge along the footprint's own long side (`RoofGeometry`), eave overhang `ev` in metres (alpine chalets 1.3 m, Japan 0.6 m, Paris 0) dropping with the roof's own slope. The satellite sample gives the colour; the shape and style give the finish (a grey Paris mansard stays zinc/slate, not bitumen; red samples read terracotta). Flat membrane/concrete read weathered gravel grey; every roof tint is floored at linear luminance 0.075 (`FacadeMaterials.ROOF_MIN_LUMA`) so no roof renders near-black. |
| Heights | Tagged → levels × the kind's floor height → same-kind neighbour median (±15 %) → the kind's seeded storey range. |
| Roofline | `BuildingDetail`: chimneys, dormers, rooftop plant and water tanks, and worship towers (spire, bell, onion, minaret + dome, pagoda, shikhara) merged into one mesh per building. |
| Landmarks | Church archetypes take the regional stone/roof colour and tower style (`ArchitectureStyle.religious_look`). |
| Procedural infill | Region mix (e.g. 78 % apartments in Paris, 58 % houses + farms in the Alps), sized and rotated per kind. |
| Distant blocks | Regional shared materials (4 walls + 2 roofs) and silhouette height from the region's apartment fabric. |

## Budgets and guards

- Material caches are reset per build (`FacadeMaterials.begin_build`, which
  also resets `MaterialLibrary`): an overflow used to fall back to the Paris
  facade for every later city of a session; an overflow now reuses the first
  material of the same set + pattern family. Near facade materials are
  capped at 192, composed textures at 160, ground-storey materials at 48;
  variants collapse to one per look at Fidelity 1 (mobile memory).
- Classes: `FacadeMaterials` (resolution + caches + distant budget),
  `FacadeComposer` (tiled storeys), `StoreyComposer` (Paris, ground storeys,
  legacy glass), `RoofGeometry` (roof meshes + eaves); `MaterialLibrary`
  keeps the PBR sets, ground, water and foliage and never names the facade
  classes (one-way dependency, no class-load cycle).
- New classes name no other project class in signatures, and the pure ring
  helpers live in the leaf class `RingGeometry` (no `BuildingDetail` ↔
  `BuildingBuilder` cycle; see the plan's 2026-10-28 render-check row).
- Known limits: boxes are coarse near borders; mixed-style cities fall to
  their single region; photographic sets are not regional (a "wood" wall is
  one plank photo, tinted; terracotta is one high-contrast clay photo); no
  per-building facade bake yet (plan T7.x); eave undersides are open
  (one-sided roof faces); `tests/architecture_test.gd` pins the regional
  signatures (`_authenticity_checks`).
