# Architecture styles — buildings by country and type

Why: every building used to share one Parisian window grid (French windows,
cornices, balcony rails, six bays), differing only in wall photo and tint, and
the regional defaults knew four Paris-centric classes. A Finnish apartment
block, a Cairo flat-roof house and a Tokyo mansion block rendered alike.

How it works (plan risk R5 — the table is data, reviewable, and never
outranks the map):

1. **Region** — `ArchitectureStyle.region_for(lat, lon)`: a **city zone**
   first (`CityStyles.ZONES`, centre + radius km: Paris intra-muros →
   `haussmann`, `london`, `amsterdam`, `berlin`, `barcelona`, `rome`,
   `new_york` (Manhattan + inner Brooklyn + inner Queens), `chicago`,
   `san_francisco`, `tokyo`, `hong_kong`, `singapore`), else the first match
   in the coarse, ordered box table `ArchitectureData.BOXES` (17 country
   style regions, e.g. `nordic`, `middle_east`, `japan`, `north_america`).
   City rows inherit from their country via `BASE`;
   `ArchitectureStyle.country_region(region)` / `country_region_for(lat,
   lon)` give the country region back for callers that key off the broad
   region (vegetation, street lamps). `tests/architecture_test.gd` pins 64
   places. Small boxes come before the country boxes that contain them:
   `mountain_lodge` (`ArchitectureMountain`: Banff / Lake Louise / Canmore,
   Jasper, Whistler, Big Sur, Lake Tahoe, Aspen, Jackson Hole) gives timber
   and fieldstone lodges under steep, wide-eaved dark metal roofs instead of
   the `north_america` brick it inherits from. Alpine roofs favour dark
   timber, slate and brown-grey over terracotta (one finish in four or five).
   Tall slender `historic=monument|memorial` buildings (Nelson's Column) are
   not styled as buildings at all: the parser turns them into `column` /
   `obelisk` landmarks (`OsmParser._monument_landmarks`,
   `LandmarkMonuments.column` / `obelisk`).
2. **Kind** — `ArchitectureStyle.kind_for`: OSM `building=*` value
   (`house`, `apartments`, `warehouse`, `barn`, `church` …), then a `use` hint
   (`amenity`/`shop`/`office`/`tourism`/`craft` on `building=yes`), then
   `building:levels`, footprint area and settlement density. Eight kinds:
   house, apartments, commercial, industrial, religious, civic, farm,
   outbuilding. A house is judged against neighbouring *houses* only when
   estimating an untagged height.
3. **Era** — inside a city, `BuildingEra.refine` picks a sub-style row
   (era / building type) per building from real cues first: (1)
   `building:architecture`, (2) `start_date` year in an era's range (several
   matches → structural rules, then the narrowest range), (3) structural
   rules per city on `building:levels` (or tagged height / 3.2 m),
   `roof:shape`, footprint, `heritage`, and distance from the city core
   (`CityStyles.CORES`, carried in the build ctx by
   `BuildingHeights._height_context`), and only then (4) a seeded weighted
   pick (`BuildingEra.ERAS` weights, ×0.12 outside an era's distance band,
   × a `CityStyles.DISTRICTS` multiplier inside a named district such as
   the Marais, Belgravia, Park Slope, Chinatown).
4. **Profile** — GENERIC ← BASE chain (era → city → country →
   `central_europe` …, up to 6 deep) ← row, per kind: wall finishes
   + palettes, window pattern and bay width, roof shapes + pitch + finish,
   floor height, storey range, chimney/dormer/rooftop-plant odds, tower kind,
   3D relief (`rv`).
5. **Resolve** — `ArchitectureStyle.resolve(b, region, density, seed, area,
   ctx)` picks one look per building from its position hash (stable across
   runs), so a street is not a row of clones. Inside a city zone every
   material pick (wall set + tint, shutter, pattern, variant, fascia, roof
   finish) is coupled to one of `LOOKS` (2) seeds per era/kind so a city's
   eras stay inside the per-place material budget (lod_test T7.2); roof
   shape, storeys and relief keep the full per-building seed, and
   WallVariety's vertex tint keeps neighbours apart.
6. **Real data wins** — `building:material`, `building:colour`, `roof:*`,
   `height`, `building:levels`, `roof:height`, `religion`/`denomination` and
   the satellite roof sample are applied on top of (and replace) the style.

## Cities and eras

| City (row) | Eras (rows) — cue highlights |
|---|---|
| Paris (`haussmann`) | `haussmann` 1850–1914 / 5–8 levels / mansard; `paris_post_haussmann` 1895–1914, Art Nouveau (same facade, more balconies + bow windows); `paris_faubourg` pre-1850, heritage ≤5 levels or ≤4 levels (render, shutters, steep tile/slate, 2.0 m bays); `paris_hbm` 1915–1949, Art Deco, or 6–8 levels beyond 4.5 km (red/ochre brick, flat); `paris_modern` ≥1950, ≥9 levels, or flat + ≥7 levels (concrete/glass, strip/panel/balcony); `paris_pavillon` houses (millstone/render, tiles, quoins) |
| London (`london`, Victorian terraces) | `london_georgian` 1714–1839 (brown brick, parapets, stucco ground floor); `london_stucco` 1825–1860 + Belgravia/Kensington/Notting Hill; `london_mansion` 1880–1914 or ≥5 levels + ≥350 m² (red brick + stone); `london_council` 1945–1985 or ≥8 levels; `london_modern` ≥1986, ≥10 levels, City commercial (glass) |
| Amsterdam (`amsterdam`, canal houses: dark brick, white sashes, step/neck/bell gables) | `amsterdam_school` 1910–1945 (sculpted brick); `amsterdam_modern` ≥1946 or ≥7 levels |
| Berlin (`berlin`, Gründerzeit: pastel render, ornate, Erker, 5 storeys) | `berlin_plattenbau` 1960–1990 or ≥9 levels away from Mitte (panel); `berlin_modern` ≥1991 |
| Barcelona (`barcelona`, Eixample: ochre stone, iron balcony every bay, flat) | `barcelona_gothic` pre-1860 / small old plots near the core; `barcelona_modern` |
| Rome (`rome`: ochre/sienna render, green shutters, hipped terracotta) | `rome_palazzina` 1945–1990 or ≥5 levels beyond 3.5 km (deep balconies); `rome_modern` |
| New York (`new_york`, brick walk-ups + fire escapes) | `nyc_brownstone` 1840–1899 / houses / small 3–4 levels; `nyc_prewar` 1900–1945, Art Deco, 10–19 levels; `nyc_glass` ≥1950 or ≥20 levels |
| Chicago (`chicago`, brick 2-/3-flats) | `chicago_greystone`; `chicago_tower` ≥12 levels |
| San Francisco (`san_francisco`, Edwardian stucco bays) | `sf_victorian` (painted timber, clapboard, bay windows); `sf_tower` ≥9 levels |
| Tokyo (`tokyo`, dense 3–8 storey mixed) | `tokyo_house` (dark kawara roofs); `tokyo_tower` ≥15 levels |
| Hong Kong (`hong_kong`, 20–40 storey slender towers) | `hk_tenement` 1900–1969 / ≤9 levels (shophouse pattern, signage); `hk_office` |
| Singapore (`singapore`, HDB slabs with colour bands) | `sg_shophouse` 1840–1959 / ≤4 levels; `sg_tower` ≥30 levels |

Profile keys added for cities: `fix` (storey range is the typology's real
range, no density stretch), `sh` may be a palette (one shutter / band colour
per building), and `rv` (below). New roof shapes in `r` rows: `gambrel`
(US barns, Dutch colonial), `skillion` (modern houses), `half-hipped`
(German / Bernese houses), `saltbox` (New England), `round` (barrel-roof
sheds).

## 3D relief (`rv` → `look["relief"]`)

Read by the geometry track (FacadeRelief / StreetFront / RooflineDetail). A
row's `rv` replaces its parent's. All keys optional:
`balcony_rows` Array[int] (storeys from ground = 0 with continuous
balconies), `balconette` / `deep_balcony` / `awning` / `fire_escape` /
`stoop` / `signage` / `oriel` (0..1 odds), `awning_colours` [sRGB hex],
`string_course` / `quoins` (bool), `gable` `""|step|neck|bell` (a weighted
list in the row, one gable picked per building). Examples: Haussmann
balconies on storeys 2 + 5, balconette 0.6, café awnings 0.5, string course;
NYC walk-up fire escape 0.8; brownstone stoop 0.95; Barcelona balconette
0.9; Plattenbau deep balcony 0.7; SF oriel 0.85–0.9; HK tenement signage
0.85. The look also carries `city` (city key or "") and `era` (the row key
used).

## Street fabric

`PartyWalls` indexes every real mass's edges once per build. Where a
neighbour's wall stands against an edge (lines within 0.8 m, anti-parallel),
the wall is skipped up to the neighbour's top. Above a lower neighbour it is
a blank firewall: plain render or brick, with the per-building tint. Only the
exposed stretches carry the windowed facade, cornice and relief. Exposed
stretches within 9 m of a road count as street fronts. `FacadeRelief`
places string courses, balconies, balconettes, deep balconies, sills, quoins
and bay windows on the facade's own storey rows and window bays; for Paris
these follow `StoreyComposer.paris_rows`, which is shared with the painted
facade. `StreetFront` places awnings, stoops, vertical signs, fire escapes
and step, neck or bell gables. All of it sits within 300 m of the viewpoint
on every tier and is tagged `lod_detail`. Geometry and materials go through
`ReliefKit`: one mesh per building, a fixed set of materials (stone per
finish, alpha-cut wrought iron, canvas per colour, lit signs).

## What differs

| Area | Mechanism |
|---|---|
| Facade | `FacadeComposer` tiled patterns: `punched`, `strip`, `balcony`, `clapboard`, `industrial`, `adobe`, `curtain`, `tiles` (Japanese tiled front), plus `FacadePatterns`: `panel` (prefab panel grid, ribbon-ish windows; `sp` ≥ 0.5 paints an HDB colour band), `ornate` (moulded surrounds, pediments, string course), `brownstone` (tall 2-over-2 sashes, heavy lintels), `shophouse` (arched shuttered French windows between pilasters). Windows sit centred in each bay cell. One 512×128 storey cell (4 bays) repeats per real storey and bay, so windows keep their size on any wall; edges under half a bay show the blank margin only. A profile's `p` may be weighted (`[["punched", 6], ["balcony", 2], ["strip", 1]]`), so a street mixes fronts. Window vocabulary `wn` per region: `casement`, `french` (Paris, Mediterranean, Belle Époque), `sash` (UK, US), `wide` (Japanese/East Asian aluminium sliders), `small` (chalets, timber houses); `rl` = share of windows with a wrought-iron balconette. |
| Paris | `StoreyComposer.compose_haussmann`: rows = real storeys counted from the ground — rusticated shopfront ground floor with lacquer fascias and a carriage door, entresol, continuous balconies on the 2nd and 5th floors, balconettes, pedimented noble floor, dentil cornice, base grime; 2.4 m window pitch (PRD §4.2); zinc/slate mansards around #46525E. |
| Ground storey | Profile `g` (`shop`, `signage`, `render`, `stone`, weighted with `none`) gives tiled buildings a separate ground band (`StoreyComposer.compose_ground`, `FacadeMaterials.ground_for_building`): shopfronts with region fascia palettes (`gc`), Tokyo signage bands with hanging signs, a chalet's white rendered base under timber, a rusticated civic plinth. Not on distant blocks or at Fidelity 1. |
| Variation | Each building draws a deterministic variant (0–2) from its position hash: which bays carry shutters, blinds, lit or curtained panes, loggia/parapet/railing kind, Paris pediments, balconette rhythm and fascia colour — plus the palette tint and weighted pattern. |
| Glass | Curtain walls are sky-reflective blue-grey with aluminium mullions, transoms and light spandrels (no more black slabs); a `building:colour` on glass tints the hue, never darkens the albedo. Ribbon (`strip`) panes stay window-dark with a sky band. |
| Walls | Bundled CC0 sets (limestone, stone, render, brick, concrete, wood, glass) tinted from the region palette; brick/terracotta tints keep 60 % of their own chroma (calibrating a red photo toward red made pink mortar and stripes); clapboard rotates the plank photo; concrete and render contrast is softened at bay scale. |
| Roofs | Shape mix + pitch per region/kind: flat, gabled, hipped, mansard (near-vertical ≈70° lower slope, flat terrasson), pyramidal, dome, gambrel, half-hipped, saltbox, skillion, round (barrel) (`RoofGeometry`, `RoofForms`). On parcel-like rings a party edge keeps a vertical gable and the ridge runs wall to wall along the street, so a terrace reads as one roof; `gable` relief turns the ridge front to back. Courtyard blocks (OSM relations with inner rings) slope to both eaves around their holes. Otherwise the ridge runs along the footprint's own long side, eave overhang `ev` in metres (alpine chalets 1.3 m, Japan 0.6 m, Paris 0) dropping with the roof's own slope. The satellite sample gives the colour; the shape and style give the finish (a grey Paris mansard stays zinc/slate, not bitumen; red samples read terracotta). Flat membrane/concrete read weathered gravel grey; every roof tint is floored at linear luminance 0.075 (`FacadeMaterials.ROOF_MIN_LUMA`) so no roof renders near-black. |
| Heights | Tagged → levels × the kind's floor height → same-kind neighbour median (±15 %) → the kind's seeded storey range (`BuildingMasses`). A `height` total includes the roof; `building:levels` counts only the storeys under it, so the roof (`roof:height`, else `roof:levels` × floor height, else the shape's rise) stands on top. `min_height` / `building:min_level` lift a part's base (no street storey on a raised part). |
| Roofline | `BuildingDetail`: chimneys, dormers, rooftop plant and water tanks, and worship towers (spire, bell, onion, minaret + dome, pagoda, shikhara) merged into one mesh per building. `RooflineDetail`: broad coped stacks with rows of clay pots on party walls at the ridge (the Paris roofscape), and dormers on the facade's own window axes (every bay on a Paris mansard, every other bay elsewhere) with glazed fronts and hipped caps. |
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
- Known limits: boxes are coarse near borders; cities outside the 12 zones
  fall to their single country region; era cues are only as good as OSM's
  `start_date` / `building:architecture` coverage (untagged buildings take
  the distance / district weighted pick); within a city a place shows at
  most `LOOKS` palette tints per era (material budget); photographic sets are not regional (a "wood" wall is
  one plank photo, tinted; terracotta is one high-contrast clay photo); no
  per-building facade bake yet (plan T7.x); eave undersides are open
  (one-sided roof faces); party gables apply only to parcel-like rings
  (irregular and courtyard masses keep sloping to every eave); `tests/architecture_test.gd` pins the regional
  signatures (`_authenticity_checks`).
