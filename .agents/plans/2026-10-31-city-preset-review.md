# City preset review: style findings and improvement plan

Date: 2026-10-31. Source: 360° captures of every quick-pick preset (`LocationData.quick_picks()`), four headings each (N/E/S/W, 14:00, summer, Ultra, 1280×800), plus probes of the parsed data and per-stage build timings.

This file lists what each preset gets right, what reads wrong against the real place, and what to change. It complements the building-realism round-2 list (dormers, glass, roof tints, quoins, NYC cornices), which is not repeated here. Items marked **Done** were fixed in the same session.

## 1. Per-city findings

| Preset | Style region | What reads right | What reads wrong | Proposed change |
|---|---|---|---|---|
| Paris | `haussmann` | Cream limestone blocks, zinc mansards, Seine with arched bridges, Eiffel Tower on the horizon. The most recognisable preset. | The viewpoint sits on a roof above a wide, empty, near-white plaza. The block colour is uniform. | Spawn at street level on a boulevard (camera height ~1.7 m, or ~8 m for overview). Darken and texture open paving. Widen the stone palette (see round-2 list). |
| Alps (Interlaken) | `alpine` | Valley, forested slopes, lake haze, the Metropole tower. | Roofs were mostly orange terracotta (**Done**: now one finish in four or five). The meadow is a flat lime-green slab. | Chalets need visible timber upper storeys and balconies at distance; meadow colour variation and mown/unmown patches. |
| Banff | `mountain_lodge` (**Done**, was `north_america` brick) | Valley, forest, mountains at the right distance. | Mountains read as grassy-yellow hills; real Banff faces are grey limestone cliffs with snow. Many roofs come out near-white (satellite roof sample). | Raise rock exposure on steep high ground in the Rockies (slope + altitude above treeline). Clamp roof samples that read as white to the region's roof palette unless the roof is tagged. |
| Big Sur | `mountain_lodge` (**Done**) | Steep coastal hills, forest, golden dry grass (**Done**: dry-summer tint on unmapped ground). | The pin (36.2704, −121.8081) is inland; no ocean or coastline in view. Only 78 buildings. | Move the pin to the coast road, e.g. Bixby Creek Bridge (36.3715, −121.9020), so the view is the Pacific cliffs people recognise. |
| Tokyo | `tokyo` / `japan` | Dense low-rise sprawl, mid-rise towers on the horizon. | The pin (35.6762, 139.6503) is in Setagaya next to a park, so the view is lawns and wide gaps. Buildings are uniform white boxes. No signage, utility poles or narrow lots. | Move the pin to Shibuya Crossing (35.6595, 139.7005) or Shinjuku. Add vertical signboards, utility poles with wires, and narrow 3–8 storey mixed-use (zakkyo) buildings. |
| New York | `new_york` | Brick, stone and glass towers, rooftop water tank, park trees. | Flat roofs are bare. Walk-ups lack fire escapes at street level from the tested angles. | See round-2 list (water tanks, cornices). Add street trees in pits, yellow cabs, subway entrances. |
| Stockholm | `nordic` | — | Never finished building: hung in the world build (**Done**: see §2). | Render and review once the fix lands (§1a). |
| Monaco | `mediterranean` | Cream towers with green shutters, terracotta, steep hillside city. | The marina water shows blue/brown/green stripes. Same palette as Rome. | Investigate the harbour water (likely the water surface vs drape or class map at quays). Give Monaco/Riviera its own row: pastel pinks and ochres, Belle Époque hotels. |
| Dubai | `middle_east` | Twelve-lane highway and interchanges, tower cluster. | Ground was lawn-green on desert (**Done**: now sand). Towers are plain beige boxes; real Downtown/Business Bay is glass curtain wall. No Burj Khalifa in the tested angles. | Gulf city row: glass-dominant towers, setbacks and crowns. Pin to Downtown (25.1972, 55.2744) for the Burj Khalifa. |
| London | `london` | Brick and slate terraces, Big Ben on the skyline, Trafalgar fountains. | Nelson's Column rendered as a windowed brick tower (**Done**: now a column landmark; also Cleopatra's Needle as an obelisk). Low fences and hedges render as tall orange boards. | Render `barrier=fence`/`hedge`/`wall` by type and real height (hedges green, railings thin). |
| Rome | `rome` / `mediterranean` | Ochre and terracotta, some green shutters. | The view near Piazza Venezia looks suburban: wide lawns, sparse mid-rise blocks. Colosseum not visible from the tested angles. | Check building coverage in the centro storico (density looks too low for the real fabric). Add umbrella pines, domes and campaniles, sampietrini paving. |
| Seoul | `east_asia` | Dense apartment slabs. | Every tower is the same white slab with the same dense window grid. An overhead line crosses the view at camera height. | Vary tower height, colour bands and balcony glazing; add Seoul apartment numbering and rooftop signs. Check what the low line is (power line or tram wire placed at the camera). |
| Venice | `mediterranean` | — | Never finished building (**Done**: see §2). | Render and review once the fix lands (§1a). Needs its own style: see §3. |

### 1a. Venice and Stockholm after the hang fix

Both now reach the 360 view through the real app flow: Venice in 36 s (2,431 buildings, 3,271 roads, 754 trees) and Stockholm in 32 s (2,006 buildings, 5,380 roads, 906 trees, 112 far towers). Per-stage build times after the fix:

| Stage | Venice before | Venice after | Stockholm after |
|---|---|---|---|
| Ground model (`GroundTruth`) | never finished | 5.7 s | 2.0 s |
| Far terrain | 446 s | 6.2 s | 4.3 s |
| Water | 82 s | ~6.5 s | 22.6 s |
| Buildings, roads, vegetation | — | 5.2 s | 6.2 s |

Captures (four headings each, taken on-screen; the capture script must dismiss the first-launch onboarding globe or it photographs that instead):

**Venice.** The lagoon reads well (blue-green, correct shorelines). Everything else reads wrong:
- The spawn sits at the lagoon's mainland edge, so the views are open lagoon and wide quays/roads, with no dense island of canal houses, campanile or San Marco. The pin (45.4408, 12.3155) may be on the Mestre/Marghera side rather than in the old city.
- Buildings are generic cream/white Mediterranean blocks with orange roofs: no pastel stucco, pointed-arch windows or canal-side facades.
- Near ground is a very bright white paved slab with a grey line grid (reads like a runway or car park). Boundary roads are drawn across open water, and a lone white tower stands beside an empty paved area.

**Stockholm.** Water, waterfront and a church spire on the skyline are plausible. Otherwise:
- Generic nordic look: red-brick and glass blocks, cream blocks; no Gamla stan ochre/rust plaster and no copper-green roofs.
- A red-brick turreted building with blue conical roofs at the water's edge reads as a toy fortress (likely a castle landmark).
- Some tall blocks are pastel pink; a large flat brown area on the far shore looks like unfinished ground.

Both cities fall into generic rows today (`mediterranean`, `nordic`), so the style gaps in §3 apply. Stockholm's water stage (22.6 s) is the next thing to profile.

## 2. Venice and Stockholm hang (Done)

**Cause.** The world build tested points against water polygons by walking every vertex. Venice's lagoon is one polygon with ~15,000 vertices and 1,090 island holes (~70,000 more). Its bounding box covers the whole detailed grid, so every grid post walked ~85,000 vertices: about 5.5 billion interpreted operations in `GroundTruth._carve_polygons` alone. The far-terrain water test (`FarSampler._in_osm_water`, 446 s once the ground was fixed), bank sampling (`WaterBuilder._outside_samples`, 82 s) and shore aprons (`ShoreApron._apron_ring`) had the same pattern. Stockholm's archipelago water has the same shape.

**Fix.** `PolygonIndex` (`scripts/generation/polygon_index.gd`) buckets a polygon's edges, outer ring and holes, into horizontal bands. A point test walks only the edges near its row, and `posts_inside` scans a grid row by row. Results are identical to `WorldScale.point_in_polygon` (`tests/polygon_index_test.gd` checks 4,000 points and every post of a grid). `GroundTruth`, `FarSampler`, `WaterBuilder._outside_samples` and `ShoreApron._apron_ring` use it.

`WaterSurface.add_polygon` also used it after profiling: its per-sample and per-triangle hole tests over 1,090 islands took 77 s and now take 4.7 s.

**Timeout (Done).** A generation still running after 10 minutes (`Main.GENERATION_TIMEOUT_S`) is stopped: the fetch is cancelled, the running world build is asked to stop at its next stage boundary (a per-build `BuildAbort`, checked in `TerrainBuilder.build_world`), nothing partial is shown or cached, and the picker says "Stopped after 10 minutes: this place took too long to build. Try a spot nearby." Cancel on the loading screen also stops a running build. If a stage never returns, Explore is released after a grace period (`abort_grace_s`) instead of staying locked. Test: `tests/generation_timeout_test.gd`.

**Remaining.** A stage that never returns still occupies its thread until the app quits; finer-grained abort checks inside the long builders would close that. Other per-point polygon loops (`QuayBuilder`, `SettlementMap`) use the native `Geometry2D.is_point_in_polygon` and were not hot in the timings.

## 3. Style gaps: regions that need their own row

Several presets share one generic row, so they look alike. Proposed new rows, in priority order:

**Status (first pass done):** `venice` and `stockholm` now exist as city zones with their own rows and `*_modern` eras (`ArchitectureCitiesWaterfront`, `CityStyles.ZONES`, `BuildingEra.ERAS`; pinned in `tests/architecture_test.gd`). Re-captured: Stockholm now reads right (ochre and cream plaster, grey slate and copper-green roofs and spire, glass offices as modern blocks). Venice only improved a little: walls are pale blue-grey/pink with salmon roofs, but the pin sits on the Piazzale Roma/Tronchetto edge, so the views are still paved plaza and roads. The pin is now at Rialto (45.4375, 12.3358): the one usable capture (the other three headings came out identical, window not drawing) shows a dense canal city, 4,397 buildings, Grand Canal, terracotta roofs and a campanile, a big improvement. Seen in it: thin grey spikes on roofs, large grey-blue roofs, and a saturated green far lagoon. **Grey roofs: Done** (a grey satellite sample on a pitched roof in a terracotta-styled region now keeps the style's tiles, `FacadeMaterials`; re-captured, roofs read warm terracotta). **Spikes: Done.** Not chimneys (two party-stack fixes were tried and reverted): the data holds ~140 `building:part`s 4 m wide and 30–36 m tall, the mapped campanili of ~100 churches. `BuildingMasses.plan` now builds a tall slender part of a religious building as a brick shaft (red-brick colour tag, since the row's pale stone tint overrode the brick set) under a pointed roof; the skyline reads as campanili. **Green lagoon band: Done.** The far satellite colour is a muted teal, but the ground shader's excess-green test read teal shallows as vegetation and painted them lawn green; unmapped ground with high blue relative to green is no longer vegetation (`ground_shader.gd`). **Olive ground floors: Done** (the shared `stone` ground storey renders khaki; Venice and Stockholm now use a pale `render` ground storey). Last Venice capture (Rialto, one usable frame): pink and ochre palazzi with green shutters, white ground floors, the Grand Canal, campanile skyline. **Follow-up round (Done):** Venetian Gothic windows (`wn: gothic`: pointed arch head, central colonnette, `FacadeComposer`), bell-capped chimneys (`rv.chimney_cap: "bell"`, flared cone + tiled cap in `BuildingDetail._chimneys`; bell rows skip the plain party-wall stacks) and altane (`rv.altana` odds: a railed timber platform on posts over the roof, `BuildingDetail._altana`) are on the Venice rows; a headless probe builds them on 15/24 and 7/24 sample blocks respectively, though a 1280-px capture of roofs 60–150 m away cannot resolve them. The picket-fence material was half-metallic and mirrored the sky (pale slats across a canal): now matte painted iron. Open paving is darker everywhere (unmapped settled ground `#787368`→`#78736a`-ish 0.47 grey-beige, `urban` class 0.64→0.57, photo macro gain capped 1.18). The Rialto itself is data-faithful: `building=bridge` with 17 mapped parts (arcades, shops, ramps), so its "boxes" are the real arcades. Not re-checked: the other three headings and Stockholm after the ground-storey/paving changes (the capture tool still yields one usable frame per run). Still open for Venice: re-capture all four headings, altana roof details, Gothic window vocabulary (only tall `french` windows today), pale ground slab, and the orange boundary boards (fences/walls) along roads. The bullets below are the original wish list.

1. **Venice (`venice`).** Pastel stucco (salmon, ochre, rust, faded pink), Venetian Gothic pointed-arch windows and polifore, Istrian-stone trim, terracotta roofs with bell-shaped chimneys (camini a fumaiolo), roof terraces (altane), buildings standing directly in canals (no quay), fondamenta paving, gondola poles. Today it falls into `mediterranean` with Rome and Monaco.
2. **Stockholm / Nordic capitals (`stockholm`).** Gamla stan plaster in ochre, rust red, mustard and pale yellow; copper-green roofs and spires; narrow gabled fronts; stone quays. Today `nordic` mixes this with Finnish suburbs.
3. **Gulf city (`gulf`).** Glass curtain-wall towers with setbacks and lit crowns, sand-coloured low-rise, palm medians. Today `middle_east` serves Cairo, Istanbul and Dubai alike.
4. **Riviera (`riviera`).** Monaco/Nice: pastel Belle Époque hotels, balustrades, tiled roofs, marinas.
5. **Seoul (`seoul`).** Apartment-complex variety; hanok near palaces (Gyeongbokgung is 1.5 km from the pin).

The mountain row (`mountain_lodge`) and the alpine roof balance were added in this session.

## 4. Other areas for improvement

### Data
- **Overpass load.** First loads took 223 s (Banff) and 225 s (London, which also returned zero buildings once). Repeat loads are 5–45 s from cache.

### Viewpoints and presets
- Several pins land in parks or suburbs rather than the scene people picture: Tokyo, Rome, Big Sur, Dubai, Seoul. Pin each preset to a recognisable spot (§1).
- Spawn height: most views are from a rooftop. A street-level start (or a choice) would read more like the real place.
- The quick-pick grid has 3 columns, so 13 chips leave one chip alone on the last row. Add a 14th preset or change columns.

### Ground and water
- Unmapped ground is a blurry mix of photo and class colour with large lime patches (Tokyo parks, Rome lawns). Sharpen with procedural detail and lower photo trust at grazing angles.
- Open paving (plazas) is one bright slab; add paving joints, darker tone and street furniture.
- Monaco harbour stripes (§1).

### Street life and detail
- No people, cars, boats, signage or street clutter in any city. Even a few instanced, low-poly cars on major roads and boats in harbours/canals would add a lot of realism per triangle.

### Capture and review tooling
- The ad-hoc capture script used this session loads each preset, hides the HUD and saves four headings, waiting on `RenderingServer.frame_post_draw` per shot. macOS does not draw a covered or off-screen window at all, so captures went stale about half the time and every off-screen capture failed; a `SubViewport` does not help, because nothing is drawn while the window cannot draw. Preset reviews need either a short on-screen run the user agrees to, or a scheduled capture run when the machine is idle. Committing the capture script as `tools/capture_presets.gd` would at least make the runs repeatable.
