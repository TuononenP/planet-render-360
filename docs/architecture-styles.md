# Architecture styles — buildings by country and type

Why: every building used to share one Parisian window grid (French windows,
cornices, balcony rails, six bays), differing only in wall photo and tint, and
the regional defaults knew four Paris-centric classes. A Finnish apartment
block, a Cairo flat-roof house and a Tokyo mansion block rendered alike.

How it works (plan risk R5 — the table is data, reviewable, and never
outranks the map):

1. **Region** — `ArchitectureStyle.region_for(lat, lon, country)`: a **city
   zone** first (`CityStyles.ZONES`, centre + radius km: Paris intra-muros →
   `haussmann`, `london`, `amsterdam`, `berlin`, `barcelona`, `rome`,
   `venice`, `stockholm`, `new_york` (Manhattan + inner Brooklyn + inner Queens), `chicago`,
   `san_francisco`, `tokyo`, `hong_kong`, `singapore`, `seoul`, `dubai`
   (Downtown, Deira, Marina), `monaco`, `interlaken`, `banff`), else the
   first match in the coarse, ordered box table `ArchitectureData.BOXES` (17
   country style regions, e.g. `nordic`, `middle_east`, `japan`,
   `north_america`). **The real country decides near borders:** the map
   query asks Overpass which country the viewpoint stands in (`is_in` →
   the `admin_level=2` area's `ISO3166-1` code, `LocationData.country`).
   With a known code, a box that lists ISO codes applies only to those
   countries, and one without only where its region is among the country's
   `ArchitectureData.COUNTRIES` regions; when no box fits, the country's own
   region wins. Kehl reads German rather than French, Saint-Louis French
   rather than Swiss, Nice and Monaco Mediterranean, Zagreb and Ljubljana
   Central European rather than Italian, Lesbos Greek, Vladivostok Russian,
   Tijuana Latin American, Nuuk Nordic. With no code (offline, the OSM API
   fallback, a payload cached before the query asked) the boxes decide as
   before.
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
| Venice (`venice`: faded salmon / ochre / rust stucco, Istrian-stone trim, Venetian Gothic pointed windows with a colonnette, terracotta roofs, bell-topped chimneys, altane roof terraces, 3–4 storeys) | `venice_modern` ≥6 levels or big flat-roofed blocks (post-war edge) |
| Stockholm (`stockholm`: Gamla stan ochre, rust and cream plaster, copper-green / slate / tile roofs, 4–6 storeys) | `stockholm_modern` ≥9 levels, big flat-roofed blocks or post-war cues (Million Programme, glass offices) |
| New York (`new_york`, brick walk-ups + fire escapes) | `nyc_brownstone` rowhouses; `nyc_prewar` dated or heritage towers and the Financial District; `nyc_castiron` SoHo/Tribeca, `nyc_loft` DUMBO, `nyc_nycha` LES housing towers; `nyc_pencil` slender supertalls, `nyc_international` dated mid-century commercial towers, and `nyc_glass` contemporary towers. |
| Chicago (`chicago`, brick 2-/3-flats) | `chicago_greystone`; `chicago_tower` ≥12 levels |
| San Francisco (`san_francisco`, Edwardian flats 1906–1925: pastel stucco, white-trimmed bays, bracketed cornices, garages under) | `sf_victorian` 1850–1905, heritage houses, Haight / Alamo Sq / Mission / Pacific Heights / Noe Valley (painted clapboard, bays, stoops); `sf_stucco` 1926–1955, Marina / Sunset / Richmond (pastel stucco over a garage, side stair, some tile); `sf_prewar` ≥9 levels pre-1950, heritage or Nob Hill / Union Sq, ≤30 levels (buff brick, terracotta, granite); `sf_chinatown` walk-ups in Chinatown (brick and render, fire escapes, red/green/gold awnings and signs); `sf_tower` ≥9 levels otherwise, FiDi / SoMa / Mission Bay (glass). SF's structural rules also read the most local district circle a building stands in. |
| Tokyo (`tokyo`, dense 3–8 storey mixed) | `tokyo_house` (dark kawara roofs); `tokyo_tower` ≥15 levels |
| Hong Kong (`hong_kong`, 20–40 storey slender towers) | `hk_tenement` 1900–1969 / ≤9 levels (shophouse pattern, signage); `hk_office` |
| Singapore (`singapore`, HDB slabs with colour bands) | `sg_shophouse` 1840–1959 / ≤4 levels; `sg_tower` ≥30 levels |
| Seoul (`seoul`, 12–25 storey white apartment-complex slabs; signed commercial streets) | `seoul_villa` 1970–2005 / 2–6 levels (red-brick walk-ups, green-painted flat roofs, water tanks); `seoul_hanok` pre-1960, heritage houses, Bukchon / Ikseon-dong / Seochon (white plaster and dark timber on granite, deep eaves, grey giwa hipped roofs); `seoul_tower` ≥20 levels, Yeouido / Teheran-ro / Jongno (glass) |
| Dubai (`dubai`, 6–15 storey sand-render blocks with balconies and shops) | `dubai_tower` ≥20 levels, Sheikh Zayed Road / Downtown / Business Bay / Marina (blue-silver curtain walls); `dubai_heritage` pre-1970, Al Fahidi / Al Shindagha (coral stone and gypsum, small screened openings, flat roofs); `dubai_villa` houses, Jumeirah (pale render, parapet or hipped terracotta) |
| Monaco (`monaco`, Belle Époque: pastel stucco, French windows, louvred shutters, balconettes, terracotta or slate mansards) | `monaco_old` pre-1860, heritage ≤5 levels, Le Rocher (Genoese ochre/rose houses, green shutters); `monaco_tower` ≥1960 or ≥10 levels, Fontvieille / Larvotto (white render, deep terraces) |
| Interlaken (`interlaken`, Bernese chalets: dark spruce over a white base, half-hipped roofs, 1.4 m eaves, balconies) | `interlaken_hotel` 1860–1930, big or ≥5-level commercial, Höheweg (cream render, slate mansards, balconettes); `interlaken_modern` ≥1955 or ≥6 levels |
| Banff (`banff`, Banff Avenue: log, river rock and Rundle stone fronts, steep metal gables) | `banff_heritage` 1885–1949 or heritage (Rundle stone, verdigris copper roofs, dormers); `banff_house` (clapboard cottages) |
| Copenhagen (`copenhagen`, brick and rendered 5-storey blocks, dormered red tile) | `copenhagen_old` pre-1860, Nyhavn (painted plaster townhouses, steep tile); `copenhagen_modern` ≥7 levels, Ørestad |
| Oslo (`oslo`, bygårder: 4–5 storey render and brick, hipped slate) | `oslo_wood` 1–2 levels / heritage, Damstredet (painted clapboard); `oslo_modern` ≥7 levels, Bjørvika |
| Helsinki (`helsinki`, Jugend: grey-green render on granite, steep tile / black metal, 5–7 storeys) | `helsinki_empire` 1810–1880, Kruununhaka (ochre render, white pilasters, low black roofs); `helsinki_functional` 1930–1989, Töölö (light render, flat); `helsinki_modern` ≥10 levels, Kalasatama |
| Edinburgh (`edinburgh`, sandstone tenements, slate, chimney rows) | `edinburgh_old` pre-1767, 6–12 levels, Royal Mile (rubble, crow-step gables); `edinburgh_georgian` 1767–1850, New Town (ashlar terraces); `edinburgh_modern` |
| Dublin (`dublin`, Georgian red brick, 4 storeys over a basement, parapet slate) | `dublin_victorian` 1–2 level brick cottages; `dublin_modern` ≥6 levels, Docklands |
| Brussels (`brussels`, maisons de maître: pale render or brick on bluestone, French windows, slate mansards) | `brussels_old` pre-1860, Grand-Place (stone guild houses, step / bell gables); `brussels_modern` ≥6 levels, European Quarter |
| St Petersburg (`st_petersburg`, 5–6 storey pastel stucco round courtyard wells, low painted metal roofs) | `spb_imperial` 1703–1839 (palaces); `spb_soviet` 8–18 levels beyond 4 km (panel); `spb_modern` |
| Madrid (`madrid`, ensanche: render and brick, iron balcony per bay, miradores, zinc mansards) | `madrid_austrias` pre-1860 (red brick and granite, slate spires); `madrid_modern` ≥9 levels, AZCA / Cuatro Torres |
| Lisbon (`lisbon`, azulejo and pastel fronts, iron balconies, terracotta) | `lisbon_pombaline` 1756–1830, Baixa (uniform ochre, mansards); `lisbon_alfama` pre-1755 (small stacked houses); `lisbon_modern` ≥7 levels, Parque das Nações |
| Milan (`milan`, eclectic and Liberty palazzi: ochre and grey render on ceppo stone) | `milan_rational` 1930–1979, 8–14 levels (brick, klinker, stone); `milan_modern` ≥15 levels, Porta Nuova / CityLife |
| Florence (`florence`, Renaissance palazzi: intonaco over pietra forte, green shutters, deep eaves) | `florence_umbertino` 1865–1949 on the viali; `florence_modern` |
| Istanbul (`istanbul`, post-1950 pastel apartment blocks with balconies) | `istanbul_pera` 1860–1949, Beyoğlu (Levantine stone, cumba bays); `istanbul_wood` pre-1923, Fener-Balat (painted timber, projecting storeys); `istanbul_tower` ≥13 levels, Levent |
| Athens (`athens`, polykatoikia: white concrete, deep balcony per floor, awnings, solar heaters) | `athens_neoclassical` 1834–1940, 1–3 levels, Plaka (ochre and pastel, pediments, tile) |
| Vienna (`vienna`, Gründerzeit Zinshäuser: 5–6 storeys, ornate render) | `vienna_baroque` pre-1848, Innere Stadt; `vienna_gemeindebau` 1919–1934 (Red Vienna superblocks); `vienna_modern` ≥8 levels, Donau City |
| Prague (`prague`, historicist and Art Nouveau blocks, steep red tile with towers) | `prague_old` pre-1850, Staré Město / Malá Strana (Baroque pastel, bell gables); `prague_panel` 1955–1995 beyond 3.5 km |
| Budapest (`budapest`, eclectic bérházak: grey and ochre render, 4–6 storeys) | `budapest_castle` 1686–1849, 1–3 levels (Baroque houses); `budapest_panel` 1955–1995 beyond 3.5 km |
| Munich (`munich`, Gründerzeit and Jugendstil, pastel render, steep red tile) | `munich_altstadt` pre-1860 (gabled burgher houses); `munich_modern` ≥7 levels |
| Kyoto (`kyoto`, height-capped beige and brown mid-rise) | `kyoto_machiya` 1–2 levels / heritage, Gion / Higashiyama / Nishijin (timber lattice, kawara, deep eaves) |
| Shanghai (`shanghai`, 12–30 storey tiled residential towers) | `shanghai_shikumen` 2–3 levels / heritage (grey brick banded red); `shanghai_bund` 1900–1949 (stone banks); `shanghai_walkup` 4–8 levels; `shanghai_tower` ≥10-level commercial, Lujiazui |
| Beijing (`beijing`, 1990s+ tiled residential compounds) | `beijing_hutong` 1 level / heritage, Nanluoguxiang / Shichahai / Qianmen (grey brick, curved grey tile); `beijing_brick` 1950–1989, 3–6 levels; `beijing_tower` CBD |
| Bangkok (`bangkok`, condominium towers) | `bangkok_shophouse` 2–5 levels (weathered concrete rows, shutters, signs); `bangkok_tower` Silom / Sathorn / Sukhumvit |
| Mumbai (`mumbai`, monsoon-stained RCC blocks with grilles and water tanks) | `mumbai_gothic` 1850–1929, Fort (Victorian Gothic and Indo-Saracenic stone); `mumbai_deco` 1930–1955, Marine Drive; `mumbai_tower` ≥16 levels, Lower Parel |
| Cairo (`cairo`, concrete frames infilled with unplastered red brick, 6–12 storeys) | `cairo_khedival` 1860–1952, Downtown (eclectic stone); `cairo_islamic` pre-1850, al-Muizz (limestone, mashrabiya); `cairo_tower` |
| Cape Town (`cape_town`, Victorian houses with iron verandahs) | `cape_town_bokaap` heritage houses, Bo-Kaap (bright flat-roofed cottages); `cape_town_modern` ≥4 levels, CBD |
| Toronto (`toronto`, brick apartment blocks and strips) | `toronto_victorian` 1–3 levels (bay-and-gable houses); `toronto_tower` ≥15 levels (glass condos) |
| Montreal (`montreal`, plexes with outside staircases) | `montreal_old` pre-1881, Vieux-Montréal (greystone, mansards); `montreal_tower` ≥7 levels |
| Boston (`boston`, brick walk-ups) | `boston_backbay` 1800–1899, Back Bay / Beacon Hill (brick and brownstone bow fronts, mansards, stoops); `boston_tripledecker` 3 levels beyond 2.5 km (clapboard, stacked porches); `boston_tower` |
| Washington (`washington`, painted brick rowhouses with bays and turrets) | `washington_federal` civic / commercial 1790–1959 (limestone classicism); `washington_modern` ≥5 levels (the 130 ft cap) |
| Los Angeles (`los_angeles`, stucco dingbats and ranch houses) | `la_spanish` 1915–1945 (white stucco, red barrel tile); `la_tower` ≥7 levels, Downtown |
| Mexico City (`mexico_city`, Porfirian and Art Deco Roma / Condesa, water tanks on the roofs) | `cdmx_colonial` pre-1881, Centro Histórico (tezontle stone, Baroque portals); `cdmx_modern` ≥8 levels, Reforma |
| Rio de Janeiro (`rio`, Copacabana: 8–14 storey white slabs, a balcony per flat) | `rio_colonial` pre-1900, Centro (pastel fronts, iron balconies, tile); `rio_tower` ≥15 levels |
| Buenos Aires (`buenos_aires`, French academic stone, balconettes, slate mansards, corner domes) | `ba_chorizo` 1–2 levels / heritage, San Telmo (casas chorizo); `ba_tower` ≥13 levels, Puerto Madero |
| Sydney (`sydney`, interwar brick flats and Federation houses) | `sydney_terrace` 1840–1914, 1–3 levels, Paddington / Surry Hills (iron-lace verandahs, corrugated iron); `sydney_tower` CBD |
| Melbourne (`melbourne`, interwar brick) | `melbourne_terrace` 1850–1914, Fitzroy / Carlton (boom-style polychrome brick on bluestone, iron lace); `melbourne_tower` CBD |

Cities without hand-written era rules in `BuildingEra._rules` (all those
after Banff above) use its data-driven `_banded` rule: era rows may end in a
storey band `[min, max]` and a heritage flag, so a heritage building goes to
the city's heritage era and an untagged one to the first era whose band
holds its levels; an era with no band is reached only by its year, style tag
or district. Their rows live in `ArchitectureCitiesNorth`, `…South`,
`…Central`, `…World` and `…NewWorld`, each with its own `ERAS` merged into
`BuildingEra.ERAS`.

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
list in the row, one gable picked per building), `garage` (0..1 odds of a
street-level garage door with the entry stair beside it; the bays then start
above it), `cornice` (0..1 odds of a bracketed cornice along a flat-roofed
street front). Bays on painted fronts (`wood`, `render`) take the wall's own
paint with trim-coloured caps; stone fronts keep stone bays. Examples: Haussmann
balconies on storeys 2 + 5, balconette 0.6, café awnings 0.5, string course;
NYC walk-up fire escape 0.8; brownstone stoop 0.95; Barcelona balconette
0.9; Plattenbau deep balcony 0.7; SF oriel 0.85–0.9, cornice 0.5–0.7, garage
0.2–0.9 (stucco rowhouses); HK tenement signage
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


Finnish fabric uses `ArchitectureCitiesFinland`: Helsinki's Empire centre, Jugend belts,
1920s classicism, wooden Käpylä/Vallila, forest-suburb lamellas, 1965–89 precast panels,
and contemporary courtyard blocks. Espoo uses Tapiola modernism, Otaniemi brick/copper,
modern centres and Kauniainen villas. The east-centred Helsinki zone precedes Espoo: Munkkivuori stays Helsinki while
Tapiola and Otaniemi lie outside its radius; eastern Helsinki remains covered.

Relief keys: `glazed_balcony` (probability) builds a deep balcony with glass fronts and
vertical aluminium mullions; `turret` (probability) adds one steep-roofed corner tower
on an exposed street front; `granite_plinth` (boolean) adds rough grey/pink granite
courses at the base; `snow_guard` (boolean) adds eave rails and roof-ladder rungs on
pitched roofs. They share the existing facade/roof detail distance and quality gates.

Street and seasonal context for the Finland hero pass: separately mapped sidewalks
can widen a carriageway only up to mapped tree/cycle/path verges; an ordinary
`sidewalk=both` does not imply extra carriageway. Parked vehicles respect mapped
one-way direction and the country's traffic side. Desktop Ultra draws electrified
contact wires and Finnish span lamps in at most twelve material surfaces, Nordic
stop signs, glass balcony stacks and ploughed snowbanks. Lower tiers retain the
existing distance-limited facade relief and post-top lamps.

March uses a place's monthly climate mean when available, otherwise a quarterly
seasonal estimate. Sub-zero March stays winter. Sea ice uses a soft cold-quarter
band and a near-shore/shallow-water proxy rather than freezing the entire sea.
The Baltic colour box darkens coastal water. Above 60°N, the bare-earth filter
also removes canopy-sized bumps inside mapped forest/park cover; the shared shoreline model uses directed OSM
coastlines to keep land and water on their mapped sides. This correction does not claim a geoid conversion or change the source
DEM's stated vertical reference.

The capture loop additionally found a coherent positive northern sea-surface
bias. `scripts/data/coastal_dem.gd` registers it from consistent OSM open-sea
samples before the single GroundTruth build; confidence guards and measured
values are documented in `docs/data-source-register.md`. Tidal polygons share
the sea datum and sea/ice shader flags. Baltic swell and chop are reduced to
keep sheltered harbour water below the quays. Visual reference/capture images
are excluded from Godot's asset import with `visual-plan/.gdignore`; tools read
them directly as images.


Nordic roof metals (G-5, 2026-11-03): `copper` is a separate verdigris PBR set;
`metal`, `metal_sheet`, `metal sheet`, `steel` and `zinc` map to `sheet_metal`.
Nordic pitched defaults use charcoal/grey/falu-red sheet metal, and Otaniemi's
copper roofs use the copper set on flat as well as sloped roofs. Red imagery
tints a sheet roof's paint without turning its finish into clay tiles; known
copper also accepts green imagery as patina. Untagged flat Nordic sheet
profiles still use membrane. Both new sets retain roof tinting and snow.
Standing seams use normal maps aligned to the existing slope UVs, adding no
mesh surfaces. See the data-source register and `roof_metals_test`.

When a mapped building has parts, blank part-level facade colour and material
inherit the parent tags; a part's explicit tags still win. White marble uses
the existing limestone texture as a pale stone fallback with colour calibrated
to the mapped tag. This preserves the Enso office's white facade without
claiming the texture is a marble scan. Calibrated marble colours use a
high-range material-cache key so distinct pale finishes do not collide; the
existing material cap can still reuse a family fallback when full.

Harbour dressing (G-6): quay stone follows `KerbBuilder.stone_for`. Ultra adds
merged mooring bollards to finalized hard banks and up to 24 alongside steamers,
houseboats and large yachts within the marina's 800 m eye radius. These berths
require mapped water, a dry bank, hull clearance and shared boat occupancy;
natural shores and ornamental pools are excluded. Long (170 m+), straight
mapped quays on tidal water with a clear fairway also berth up to two procedural
cruise liners (140-300 m, `QuayMoorings.liners`, up to 1200 m from the eye,
never beside lake water). Vessels are lofted hulls (`HullLoft`) with per-type
models: `CruiseLinerModel`, `PassengerVesselModel` (classic coastal ship,
houseboat, tall ship), `MotorYachtModel` (flybridge, sport, runabout, RIB,
console) and `SailYachtModel`, sharing `VesselMaterials`/`VesselKit`. Marina
boats are MultiMesh prototypes (`VesselPrototypes`); those beyond 250 m use
reduced `_far` meshes without rails, rigging and mullions, and the combined
marina surface budget is `MarinaBuilder.MAX_DRAW_CALLS`. Mapped
`building=ship|boat|houseboat` features pick a model by type and length (>= 100 m
is a liner, sailing types a yacht or tall ship, other `boat` features a yacht or
day boat, anything else a coastal passenger ship) at every tier; those
individual building-layer meshes are outside the marina budget. Untagged vessels
use a generic hull colour and height. Snow covers decks/roofs in mapped meshes,
instanced quay boats and liners.

Stockholm districts distinguish Gamla stan and Riddarholmen medieval fabric, Mariaberget and Vita Bergen timber, Östermalm stone, Swedish Grace, funkis, Million Programme and contemporary waterfront blocks. Mapped dates and architecture tags take precedence over these district defaults; pitched roofs use painted sheet metal, with copper for civic roofs.
