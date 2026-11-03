# San Francisco hero pass — tracker

> Approved plan 2026-11-03 (user: SF should be one of the most authentic cities). Vantage Hyde St on
> Russian Hill, full hero pass, clear golden-hour default with an optional marine layer. Same rules as
> realism v3: claim a task (`— @<agent>/<topic> <date>`), tick it only when its validation passes, add one
> evidence line. Data-driven only (rows, eras, districts, registry); generic fixes first; tier-gated layers;
> `BUILD_VERSION` bump per visual change; classes ≤ 1000 lines.
>
> The SF landmark batch (`landmark_registry_san_francisco.gd`, `landmarks/san_francisco/`: Salesforce,
> Coit, Ferry Building, Alcatraz, Sutro, Bay Bridge west/east) is owned by the landmark visual-quality
> plan (`2026-11-02-landmark-visual-quality.md`); this tracker only consumes it and adds the gaps.

## Tasks

### Phase 1 — preset, refs, baseline (no build-output change)
- [x] **SF-1.1** Vantage from `--looks` candidates on Hyde St (Greenwich–Chestnut), north to Alcatraz — @claude/sf-hero 2026-11-03
  > DONE: 6 candidates (`visual-plan/reviews/sf-looks-2026-11-03/`); Greenwich lifted the eye over a 12-storey block, Hyde & Lombard
  > (37.80195,-122.41960, 5 m, 352°, −5°) frames the street down to the bay; `"clear": false` (the flats are the framing).
- [x] **SF-1.2** `PresetViews` row (appended), `PlaceCard.SKY_FOR`, tests — @claude/sf-hero 2026-11-03
  > DONE: row 14 appended (origin 37.8040,-122.4195), SKY_FOR dusk; preset_views, architecture, responsive tests OK.
- [x] **SF-1.3** `visual-plan/refs/san_francisco/` (README + Commons photos) — @claude/sf-hero 2026-11-03
  > DONE: 01 Hyde at Chestnut north (CC BY 3.0), 02 Alcatraz from Hyde (CC BY-SA 3.0), 03 cable car in fog (CC BY 2.0).
- [x] **SF-1.4** Baseline capture r1 + review README + scorecard §9 row + findings table — @claude/sf-hero 2026-11-03
  > DONE: rounds sf-r1…r6 (`visual-plan/reviews/sf-*-2026-11-03/`), README in sf-r6, scorecard §9 round sf-r6
  > (recognisable), findings below.

### Phase 2 — buildings
- [x] **SF-2.1** Wood/render oriels take the wall's paint; cornice cap per bay stack; contrasting trim — @claude/sf-hero 2026-11-03
  > DONE: `FacadeRelief.oriel_paint` (wall colour tag, else the look's paint; flat colour, outside the PBR cap), `trim_for` (frame
  > colour) for cap, cornice band and corbel. Painted siding (wood + clapboard) keeps 25 % of the plank photo's contrast
  > (`FacadeComposer.SIDING_CONTRAST`). Seen in sf-r1: white-trimmed painted bays.
- [x] **SF-2.2** `BuildingEra` SF rules rebalanced (houses by year/district; pre-war towers) — @claude/sf-hero 2026-11-03
  > DONE: cue `district` (most local circle); SF arm: ≥9 levels pre-1950/heritage/Nob Hill → sf_prewar (≤30), else sf_tower;
  > Chinatown walk-ups; houses by district, heritage → Victorian, else weighted by distance band. architecture_test pins 13 cases.
- [x] **SF-2.3** Rows `sf_stucco`, `sf_prewar`, `sf_chinatown`; pastel Edwardian palette; `sf_tower` relief — @claude/sf-hero 2026-11-03
  > DONE: rows + eras in `ArchitectureCitiesAmericas` / `BuildingEra`; Edwardian is pastel render only (wood + punched windows
  > read as the raw plank photo).
- [x] **SF-2.4** SF district circles — @claude/sf-hero 2026-11-03
  > DONE: 15 circles (Pacific Heights, Noe/Castro, Russian Hill, North Beach, Marina, Sunset, Richmond, Nob Hill, Union Sq,
  > Chinatown, SoMa/Rincon, Mission Bay + the 3 old ones).
- [x] **SF-2.5** Relief keys `garage` (door + side stair) and `cornice` (bracketed, flat-roofed fronts) — @claude/sf-hero 2026-11-03
  > DONE: `StreetFront._garage` / `_cornice`, `has_garage` (bays start above the garage storey); keys documented in
  > ArchitectureData and pinned in architecture_test RELIEF_KEYS. (`false_front` became `cornice`: the flat Italianate front.)

### Phase 3 — hillside buildings
- [ ] **SF-3.1** Ground per wall side: uphill ground floor above ground, downhill plinth, stoop at the door
  > DEFERRED: not visible as a tell from the Hyde St frames (row houses step down; ground floors show); shared building code.

### Phase 4 — landmarks
- [ ] **SF-4.1** Wire the SF batch into `landmark_test` + preset pin; landmark captures
- [x] **SF-4.2** SF City Hall, Palace of Fine Arts — @claude/sf-hero 2026-11-03
  > DONE: `LandmarkSfCivic.city_hall` (granite wings, Polk St portico, colonnaded drum, ribbed dome, lantern; 93.7 m,
  > yaw −9) and `LandmarkSfPalace.build` (rotunda, curved peristyles, exhibition hall; 49.4 m, yaw −99, span 270 m),
  > positions from OSM; refs in `visual-plan/refs/landmarks/{sf_city_hall,palace_of_fine_arts}/`. landmark_catalog
  > (445), landmark, landmark_fidelity tests OK. Sheets: `visual-plan/captures/sf-civic/`.
- [ ] **SF-4.3** Golden Gate `yaw_deg` check (deck bearing ~352°)

### Phase 5 — streets and transit
- [x] **SF-5.1** Cable cars: `cable_tram=cable` draws a concrete bed and the cable slot — @claude/sf-hero 2026-11-03
  > DONE: `OsmTags._rail_entry` `cable`, `RailBuilder` track bed (paved road material, layer 7.0) + slot rails 30 mm apart;
  > osm_test, rail_square_test OK. The NA 1435 mm default is not needed: SF's trams carry `gauge`.
- [ ] **SF-5.2** Overhead wires (Ultra) along `electrified=contact_line` trams and trolleybus wires
- [x] **SF-5.3** Parked cars along kerbs (Ultra desktop, MultiMesh) — @claude/sf-hero 2026-11-03
  > DONE: `RoadWidths` (kerb-to-kerb width from footway=sidewalk lines either side; Hyde 6 → ~12 m), parking tags
  > (`OsmTags.parking_sides`, a tagged lane widens the road), `ParkedCars` (sedans/hatches/SUVs/vans with a raked glasshouse,
  > pitched with the street, junctions clear, 320 m). `parked_cars_test`. Found: `StreetProps._box`/`TreeMeshLibrary._card`/
  > `_tube` wind CCW about the outward normal, which Godot culls as back faces (cars read as hollow boxes); the cars reverse
  > their triangles (`ParkedCars.front_faces`). Street furniture and marina boats share the helpers with cull_back.
- [x] **SF-5.4** Paved sidewalks: `sidewalk` sides paint an urban band (3 m; 7 m to the building line in a city zone) — @claude/sf-hero 2026-11-03
  > DONE: `OsmTags.sidewalk_sides`, `GroundMaterial._sidewalks`; the verges along Hyde St read as lawn under street trees.

### Phase 6 — marine layer fog
- [x] **SF-6.1** Marine layer — @claude/sf-hero 2026-11-03
  > DONE (seen in `sf-r6-fog-2026-11-03/`: the bay and Alcatraz fade down Hyde St, the street stays legible): Godot's height fog is distance-independent (it fogs the kerb in front of the eye) and volumetric fog reaches
  > 250 m (never the bay), so `MarineLayer` draws the slab: an inside-out box round the camera whose shader measures each
  > view ray's length inside [sea, sea + 160 m] before the depth buffer, patchy and drifting. `AtmosphereRig.set_coast`
  > (View360: sea = `render_y(0)`, coastal = a mapped coastline) shows it in fog weather and thins the air fog;
  > `marine_layer_test`. Forward+/Mobile only.

### Phase 7 — vegetation
- [x] **SF-7.1** Monterey cypress, Metrosideros, eucalyptus — @claude/sf-hero 2026-11-03
  > DONE: species rows (broad generator; flat-topped wind-sheared cypress, tall open grey-green eucalyptus, dense dark
  > Metrosideros), GENUS rows (hesperocyparis, eucalyptus, corymbia, metrosideros, lophostemon, ficus, pittosporum, …),
  > `cupressus macrocarpa`; `dry_coast` mixes now lead with them (California-wide, no city gate). osm_test.
  > Data gap: only 4 trees are mapped along Hyde St (413 in the extent, none with genus); the policy plants real trees only.

### Phase 8 — far field
- [ ] **SF-8.1** Far-city radius ~18 km across open water (Oakland)
  > DEFERRED: `FarCityFetcher.RADIUS_M` is one cached Overpass request for every place; Oakland is off the opening look.

### Phase 9 — hero loop
- [ ] **SF-9.1** Capture rounds to "photographic" on Ultra; scorecard §9 lines

## Findings

| Area | Reads right | Reads wrong | Proposed change |
|---|---|---|---|
| Street | Paved sidewalks, measured 12 m street, cable beds and slots, parked cars | No street trees (4 mapped) | Canopy raster (R-2.4) |
| Fabric | Pastel Edwardians, painted bays, cornices, garages | Flat-lit tiled walls, one repeated shop band | Ground-floor variety (entries) |
| Bay | Water, Angel Island, fog layer | Alcatraz a green lump (far drape over the model's rock) | Cut the far drape under `base: water` landmarks (landmark plan) |
| Wires | — | No trolleybus wires on cross streets | SF-5.2 |

## Data notes

- OSM (Overpass, 2026-11-03): Hyde St runs 37.80014,-122.41926 (Greenwich) → 37.80200,-122.41963 (Lombard)
  → 37.80480,-122.42019 (Bay), bearing ~351°; Alcatraz from Hyde & Lombard ~353°, 2.8 km.
- Cable-car tracks are `railway=tram`, `gauge=1067`, `electrified=no` (crossovers `service=crossover`,
  turntables `railway=turntable`); Muni E/F and the Central Subway are 1435 mm `contact_line`.
