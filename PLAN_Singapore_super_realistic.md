# Singapore super-realistic: landmarks and city

> Tracker in the house style of `PLAN_Stockholm_super_realistic.md`: claim a task, tick it only after its validation
> passes, add one evidence line. Status legend: `[x]` done and validated, `[~]` in progress, `[ ]` open.
> This file replaces the chat summary that was pasted here on 2026-11-19. The first draft of the plan lives outside
> the repo at `~/.claude/plans/read-make-singapore-super-composed-stonebraker.md`; this version supersedes it.
> Nothing has been built yet. Every number marked "to verify" is from memory and must be measured before modelling.

## Tracker

- [ ] SG-0.1 Clock fix (UTC+8) before any capture
- [ ] SG-0.2 Baseline captures r0 (centre set and close set)
- [ ] SG-0.3 Height audit of the bundled snapshot (zero and missing heights)
- [ ] SG-0.4 Live measurement pass for sites missing from the snapshot
- [ ] SG-0.5 Reference photos (`tools/commons_refs.py`)
- [ ] SG-0.6 Sources doc `docs/singapore-landmark-sources.md`
- [ ] SG-0.7 Slot table pinned in a test
- [ ] SG-1 Batch wiring (registry, set, kit, test, Marina Bay Sands moved)
- [ ] SG-2.1 Marina Bay Sands rebuild
- [ ] SG-2.2 Esplanade
- [ ] SG-2.3 Merlion Park
- [ ] SG-2.4 Singapore Flyer
- [ ] SG-2.5 ArtScience Museum
- [ ] SG-2.6 Helix Bridge
- [ ] SG-2.7 Fullerton Hotel and waterfront pavilions
- [ ] SG-2.8 Supertree Grove
- [ ] SG-2.9 Flower Dome and Cloud Forest
- [ ] SG-2.10 Marina Bay waterfront ground
- [ ] SG-3 Batch B Civic District (10 rows)
- [ ] SG-3 Batch C heritage districts and river (6 rows + second tier)
- [ ] SG-3 Batch D skyline towers (height fixes first, then specs)
- [ ] SG-4 Bridges
- [ ] SG-5 City fabric (rule, rows, districts, void decks, five-foot-ways, HDB cues, towers)
- [ ] SG-6 Trees, water, boats and port, atmosphere
- [ ] SG-7 Streets and transport
- [ ] SG-8 Night
- [ ] SG-9 Review rounds, scorecard, docs, performance
- [ ] Code review

## Context

Singapore's capital view is centred on the Padang side of City Hall (1.28967, 103.85007, `capital_catalog.gd:213`).
It is rendered almost entirely from generic rules:

- **One hand-built landmark.** Marina Bay Sands is an 80-line model (`landmark_sea_towers.gd:119`): painted
  "glass" (`LandmarkMaterials.paint`), three identical towers on a straight line, no podium, no night lighting.
- **Not modelled:** Merlion, Esplanade, Singapore Flyer, Helix Bridge, ArtScience Museum, Supertrees, the Gardens
  domes, the whole Civic District, the temples and mosques, and every named CBD tower.
- **Bridges:** seven rows in `bridge_specs_southeast_asia_au_nz.gd` (Cavenagh, Anderson, Elgin, Jubilee, Esplanade,
  Helix, Merdeka). Only Jubilee is built; the others are `conf 1`. Coleman, Read, Ord and Alkaff have no row at all.
- **City fabric:** five district circles (`city_styles.gd:239-243`) and a rule that turns every 1–4 storey building
  into a shophouse whatever its use (`building_era.gd:564-570`).
- **Environment:** the tropical tree mix is `palm 0.45 / tropical 0.55` for every setting (`tree_species.gd:196`),
  rail viaducts are London stock brick (`rail_builder.gd:47`), metro trains run only in Helsinki and Espoo
  (`train_specs.gd:118`), and the pre-weather clock guess is UTC+7 (`atmosphere_rig.gd:248`, `roundf(103.85 / 15)`).

**Goal:** from the centre view and from Marina Bay eyes, a person who knows Singapore recognises each landmark by
shape, proportion, material and night look, and the streets between them read as Singapore. "Photographic" stays a
human rating; this plan gets every item to the point where a side-by-side sheet against a real photo shows no wrong
shape, missing signature feature or wrong material.

## What the analysis changed

The first draft was checked against the code and against the decoded snapshot
(`assets/osm_snapshots/capital_sg_9128967_28385007_*.osmb`, OSM base 2026-11-03). Ten things differ from it.

1. **Many landmark sites are not in the bundled snapshot.** No element is named ArtScience Museum, Singapore Flyer,
   Supertree, Flower Dome, Cloud Forest, Sultan Mosque, Civilian War Memorial, Lim Bo Seng, Dalhousie, Marina Barrage,
   National Stadium, The Gateway, Parkview Square or The Concourse. Raffles Hotel, the National Gallery, the Merlion
   and the Coleman and Read bridges exist only as POI nodes. The draft's rule "site, footprint and axis from the
   bundled snapshot" cannot hold for these, so Phase 0 gains one live measurement pass (SG-0.4).
2. **The detailed square is 2,400 m wide, so it ends 1,200 m from the centre** (`WorldScale.DETAILED_EXTENT_M`).
   The Marina Bay Sands towers (1,342–1,369 m), Flyer, Supertrees, domes, Sultan Mosque, Pinnacle@Duxton, Guoco
   Tower and Capital Tower stand outside it and are seen across far-field ground. The Helix (1,150–1,204 m) and the
   Shoppes (1,167 m) sit on the edge.
3. **Close looks do not use the bundled snapshot.** `capture_presets.gd` rebuilds the world 800 m ahead of any look
   whose target is more than 300 m from the centre, and `BundledOsm.covers` matches the exact capital coordinates
   only. A Marina Bay look therefore builds from live Overpass data. The draft's claim that `--pin` keeps the
   snapshot in use is true for centre frames only. Captures are split into two sets (see "Captures and eyes").
4. **Slot arithmetic is tighter than the draft said.** Total candidates are 10/16/22/26 per preset
   (`LandmarkSites.MAX_BY_PRESET`), extras 6/12/18/22, and bridges get `min(2/4/6/8, total - extras)`. With the
   extras full that is 2/4/4/4 bridges, not 8. The ranking question in the draft is answered: extras sort by
   `skyline_priority` (higher first), then nearest. There is no `icon` ranking field.
5. **Nearest-first works against Marina Bay.** The Civic District rows are 110–420 m from the centre, the bay icons
   570–1,900 m. Without `skyline_priority` on the bay set, Fast and Balanced would fill with civic buildings and
   drop the Flyer and ArtScience Museum. The slot table below fixes the order.
6. **Dozens of well-known buildings have `height=0` or no height in OSM**, including UOB Plaza One and Two, the
   Republic Plaza tower (only its 43 m podium way), CapitaSpring, The Sail, all five Suntec towers, Asia Square
   Tower 1, South Beach Tower, Mandarin Oriental, Marina Bay Suites, St Andrew's Cathedral and Lau Pa Sat. Fixing
   these heights is cheap and changes the centre skyline more than any single new model, so it moves to Phase 0
   (audit) and leads Batch D.
7. **There is no elevated MRT near the centre.** All 42 `railway=subway` ways in the detailed layer are tunnels on
   layers -1 to -5. The viaduct and train work (draft SG-7.1) cannot show in the centre view; it is kept as the
   last, optional transport task and needs a live pin on an elevated stretch to be checked.
8. **The clock fix moves first.** Golden-hour, night and late captures depend on the UTC offset, and the guess is
   an hour off until the weather service answers. Fixing it before r0 keeps every round comparable.
9. **Most buildings are untyped.** 1,804 of the 2,244 buildings in the detailed layer are `building=yes`. The new
   Singapore rule cannot lean on the building tag; it has to use the district, footprint shape, levels and
   `start_date`.
10. **Stale references corrected:** `landmark_sites.gd` is in `scripts/data/`; the Singapore rule is at
    `building_era.gd:564`; `water_surface.gd` is in `scripts/generation/`; the Marina Bay Sands builder starts at
    `landmark_sea_towers.gd:119`; `build_bench` is `tools/build_bench.gd`, not a test. The tooling the draft did not
    use is added: `tools/commons_refs.py`, `tools/capture_landmarks.gd`, `tools/landmark_compare_sheets.py`,
    `tools/landmark_silhouette_scores.py`, `tools/audit_landmark_placement.gd`.

## Ground rules

- **Measured, not remembered.** Site, footprint, axis and height come from an OSM way (bundled snapshot or the
  SG-0.4 pass), dimensions from Wikipedia or architect data, look from reference photos. The catalog test's
  "should stand N m tall" message then pins the height.
- **Catalog limits per landmark** (`tests/landmark_catalog_test.gd`): 2 to 16 merged surfaces, at most 150,000
  triangles, textured materials only, top within max(2 m, 3 %) of `height_m`.
- **Class size:** every file under `scripts/` stays at or under 1,000 lines (`tools/check_class_size.sh`). One
  builder file per landmark or tight group.
- **The user's uncommitted work:** the tree has about 417 changed files, including `road_builder.gd`,
  `atmosphere_rig.gd`, `tram_specs.gd`, `train_specs.gd`, `transit_vehicles.gd`, `vessel_prototypes.gd`,
  `city_styles.gd`, `building_era.gd` and `architecture_style.gd`. Phases 5–7 and SG-0.1 touch some of these.
  Re-read each file before editing, keep edits minimal, stage only this plan's files by path, commit only when
  asked. New files are preferred over growing a file that has open changes.
- **Hosts:** no Russian-operated service or domain for references or data. Overpass through the
  openstreetmap.fr or kumi mirrors. Reference photos from Wikimedia Commons only.
- **Godot:** always through `tools/godot_bg.sh`; tests headless and in the background; captures windowed, in the
  background, `--position 4000,4000`, `--preset=3`, never `--always-on-top`.
- **Eyes:** every capture eye stands in open space. A frame showing interior faces, cut walls or geometry floating
  against the sky is discarded and the eye moved, not reported.
- **Networked tests** (`tiles_test`, `exit_tile_test`, and the ones `tools/run_tests.sh` already skips) stay out of
  routine runs.

## Verified site data

Measured from the decoded snapshot. Distance and bearing are from the view centre. "OSM h" is the mapped `height`
tag; a dash means none, 0 means the tag is literally 0. Real heights in the last column are from memory, to verify.

| Site | OSM element | Distance / bearing | Footprint bbox | OSM h | Real height (to verify) |
| --- | --- | --- | --- | --- | --- |
| Marina Bay Sands Tower 1 | way 116801004 (far layer) | 1,369 m / 124° | 76 × 77 m | 193 | 194 m roof, 207 m SkyPark top |
| Marina Bay Sands Tower 2 | way 172307472 (far) | 1,357 m / 119° | 72 × 76 m | 193 | same |
| Marina Bay Sands Tower 3 | way 172307471 (far) | 1,342 m / 115° | 45 × 57 m | 193 | same |
| SkyPark | way 116800998 (far) | 1,344 m / 118° | 159 × 317 m | 207 | 340 m long deck |
| The Shoppes (podium) | relation 2298319 | 1,167 m / 117° | 386 × 486 m | 15 | — |
| Crystal Pavilion North | way 172013197 | 1,071 m / 118° | 42 × 57 m | 14 | — |
| Apple Marina Bay Sands (glass sphere) | way 821764692 | 1,090 m / 130° | 33 × 33 m | 5 | about 30 m sphere |
| The Helix (main deck) | way 164881537 + 6 pod and ramp ways | 1,187 m / 100° | 22 × 185 m | — | 280 m long |
| Esplanade Concert Hall | way 256163011 | 567 m / 94° | 96 × 73 m | 35 | — |
| Esplanade Theatre | way 256163012 | 610 m / 84° | 78 × 107 m | 35 | — |
| Merlion Park | way 687917300 (park), cub node 6283080658 | 607 m / 130° | — | — | statue 8.6 m |
| The Fullerton Hotel | way 46595395 | 512 m / 139° | 79 × 128 m | 25 | about 37 m |
| One Fullerton | way 46595394 | 612 m / 135° | 77 × 164 m | 12 | — |
| Old Customs House | way 395113920 | 870 m / 155° | 62 × 22 m | 10 | — |
| Old City Hall (National Gallery) | way 46595597 | 212 m / 63° | 119 × 144 m | 25 | — |
| Old Supreme Court (National Gallery) | way 170960936 | 145 m / 87° | 93 × 102 m | 25 | dome about 60 m |
| Supreme Court (Foster) | way 46594825 | 131 m / 38° | 118 × 138 m | — | to measure |
| Victoria Theatre and Concert Hall | relation 3899820 | 220 m / 130° | 84 × 90 m | 15 | clock tower 54 m |
| St Andrew's Cathedral | way 155980025 | 385 m / 39° | 61 × 69 m | 0 | spire about 63 m |
| The Arts House | way 243427705 | 157 m / 134° | 52 × 68 m | 15 | — |
| Singapore Cricket Club | way 46594820 | 238 m / 110° | 75 × 54 m | 15 | — |
| Singapore Recreation Club | way 46594819 | 494 m / 56° | 86 × 58 m | — | — |
| The Cenotaph | way 256153714 | 422 m / 81° | 23 × 28 m | 1 | about 18 m |
| Asian Civilisations Museum | way 46595390 | 287 m / 149° | 118 × 124 m | 15 | — |
| Old Hill Street Police Station | relation 6955290 | 247 m / 298° | 136 × 97 m | 30 | — |
| Swissôtel The Stamford | way 172364975 | 542 m / 43° | 49 × 51 m | 226 | 226 m |
| Raffles City Tower | way 172364974 | 595 m / 33° | 43 × 43 m | 158 | — |
| Sri Mariamman Temple | way 300380459 | 950 m / 216° | 47 × 27 m | 10 | gopuram about 15 m |
| Buddha Tooth Relic Temple | way 47298635 | 1,111 m / 215° | 83 × 62 m | 30 | — |
| Thian Hock Keng | way 172272611 | 988 m / 197° | 66 × 79 m | 12 | — |
| Lau Pa Sat | way 45098520 | 995 m / 177° | 73 × 73 m | 0 | to measure |
| CHIJMES Hall | way 97666818 | 639 m / 19° | 44 × 33 m | 36 | — |
| Armenian Church | way 172368093 | 388 m / 349° | 29 × 24 m | 15 | — |
| Central Fire Station | way 172368086 | 298 m / 338° | 84 × 59 m | 20 | tower about 34 m |
| National Museum | way 32342169 | 785 m / 347° | 139 × 137 m | — | — |
| Cavenagh Bridge | way 534684103 | 426 m / 144° | 62 m long | — | — |
| Jubilee Bridge | way 315739150 + 2 | 528 m / 115° | 158 m long | — | — |

MBS tower centroids are 1.28270, 103.86024 / 1.28368, 103.86071 / 1.28459, 103.86102. Tower 1 to 2 is 120 m on
bearing 26°, Tower 2 to 3 is 106 m on bearing 19°: the row bends by about 7° and the spacing is uneven, which the
present model (three towers at ±105 m on one line) does not show.

**To measure in SG-0.4 (not in the snapshot):** ArtScience Museum, Singapore Flyer, the 12 Supertree Grove trees and
the OCBC Skyway, Flower Dome, Cloud Forest, the Merlion statue and jetty, Raffles Hotel, Parliament House, Sultan
Mosque, Civilian War Memorial, Lim Bo Seng Memorial, Dalhousie Obelisk, Clarke Quay godown blocks and canopies,
Anderson, Elgin, Esplanade, Coleman and Read bridges, The Gateway, Parkview Square, DUO, The Concourse, Marina
Barrage, National Stadium, Benjamin Sheares Bridge.

## Selection and slots

`LandmarkSites.select` (`scripts/data/landmark_sites.gd:39`) sorts registry extras by `skyline_priority`, then by
distance, and keeps 6/12/18/22 on Fast/Balanced/High/Ultra. Marina Bay Sands stays the primary and takes no slot.
Each row needs a `radius_m` that reaches the view centre, or it is never a candidate.

| Tier | `skyline_priority` | Rows | First preset that shows them |
| --- | --- | --- | --- |
| 1 | 9 | Esplanade, Merlion Park, Singapore Flyer, ArtScience Museum, National Gallery, Victoria Theatre | Fast (6) |
| 2 | 7 | Fullerton Hotel, St Andrew's Cathedral, Helix Bridge, Supreme Court, Supertree Grove, Gardens domes | Balanced (12) |
| 3 | 5 | Old Hill Street Police Station, Raffles Hotel, Arts House + Parliament, Sultan Mosque, Sri Mariamman, Lau Pa Sat | High (18) |
| 4 | 3 | Buddha Tooth Relic Temple, Clarke Quay, Civilian War Memorial, Padang ensemble | Ultra (22) |
| 5 | 0 | Thian Hock Keng, CHIJMES, Armenian Church, Central Fire Station, National Museum, Asian Civilisations Museum, Customs House | Only when a moved view brings them nearest |

Notes on this order:

- The Helix is built as a registry row with `clear_path_m`, so it takes an extras slot, not a bridge slot. Its
  `conf 1` BridgeSpec row is removed so it is not registered twice.
- From the Padang the Supertrees and domes stand behind Marina Bay Sands (same bearing, 400–550 m farther). They are
  ranked tier 2 for the Marina Bay eyes, not for the centre view. Confirm in r0 how much of them the centre view can
  see; if nothing, drop them to tier 3 and promote the Fullerton.
- Bridges get 2/4/4/4 slots. `_nearest_bridges` takes the most important `tier` first, then the span nearest the
  centre. Set tiers so the order is Cavenagh, Anderson, Elgin, Esplanade Bridge; Jubilee, Coleman and Read follow
  and are built only where room remains. Jubilee and Esplanade Bridge run 30 m apart on parallel bearings, so their
  clearances must not erase each other (`bridge_select_test`).
- Skyline towers use their own channel (`skyline: true`, 12/30/60/110 per preset, scored height over distance) and
  cost no icon slot.
- **Open decision:** the primary's `ultra_registry_limit` can lift Ultra extras from 22 to 26, but every extra above
  22 removes a bridge. Recommendation: leave it at 22.

## Phase 0: foundations

- **SG-0.1 Clock fix.** `atmosphere_rig.gd:248` guesses `roundf(lon / 15.0)`, which gives +7 for Singapore. Add a
  small per-country offset table consulted before the longitude guess (SG +8; add the other capitals whose legal
  time differs from the longitude zone only if they fall out of the same table for free). The file has open
  changes: edit only the guess. Done when `solar_test` (or a new case in it) pins +8 for Singapore and the weather
  service's offset still overrides the table.
- **SG-0.2 Baseline r0.** Run both capture sets (below) at `--preset=3` and keep the folders as the fixed
  reference. Record in the tracker which eyes had to move. Also run
  `tools/capture_landmarks.gd --types=marina_bay_sands` for the model sheet and `stats.tsv` triangle count.
- **SG-0.3 Height audit.** Write a short probe (scratch script over the decoded snapshot, or a headless `--script`
  through `tools/godot_bg.sh`) that lists every named building in the detailed and far layers with `height=0`, no
  height, or a height that disagrees with its `building:levels` by more than 40 %. For each, record what height the
  parser gives it today (check how `OsmTags._tag_metres` treats 0). Known cases to start from: UOB Plaza Tower 1
  (way 335167827) and Tower 2 (171999282), Republic Plaza (171999304), CapitaSpring (694047464), The Sail
  (1201220123, 325793782), Suntec Towers 1–5 (46595146, 46595147, 46595148, 102938119, 46595145), Asia Square
  Tower 1 (407941850), South Beach Tower (427064886) and Residences (427064883), Mandarin Oriental (46594816),
  Marina Bay Suites (1035285485), Hong Leong Building (47345013), Maybank Tower (106193386), Parkroyal Pickering
  (172271707). Suspect values to check: Guoco Tower part 393100845 says 180 m (the tower is about 290 m) and all
  three Marina Bay Financial Centre towers say 245 m (Tower 1 is lower). Output: a table in the sources doc.
- **SG-0.4 Live measurement pass.** One Overpass query through the openstreetmap.fr or kumi mirror for the sites
  listed under "To measure", saved as JSON beside the sources doc inputs (not bundled into the app). For each:
  element id, area centroid, long-axis bearing, bbox, `height` and `building:part` data. The Supertrees need the 12
  individual positions and the Skyway end points; the Flyer needs the wheel centre, the axle bearing and the
  terminal footprint; the Merlion needs the statue node and the jetty outline.
- **SG-0.5 Reference photos.** Add Singapore types to `SPECS` in `tools/commons_refs.py` and fetch front, quarter,
  aerial and night views into `visual-plan/refs/landmarks/<type>/` with README licence rows (CC BY, CC BY-SA, CC0 or
  public domain; JPGs stay gitignored). Review every fetched file on a contact sheet: the Stockholm pass found about
  a third of first-pass results wrong (interiors, details, other cities). City-wide references go to
  `visual-plan/refs/singapore/`: Padang panorama, Marina Bay by day and at night, Boat Quay, Chinatown shophouse row,
  Kampong Glam, an HDB estate, a rain-tree avenue.
- **SG-0.6 Sources doc.** `docs/singapore-landmark-sources.md` in the format of
  `docs/tokyo-seoul-landmark-sources.md`: type, OSM element, centroid, yaw, height, key dimensions, source links,
  and the SG-0.3 height table. Add a Singapore section to `docs/data-source-register.md` (the file has open
  changes: append only).
- **SG-0.7 Slot test.** In `tests/singapore_landmarks_test.gd` (created in SG-1), pin the tier table: the six
  tier-1 types are selected on Fast, tiers 1–2 on Balanced, and so on, and the four ranked bridges are chosen.

## Phase 1: batch wiring (SG-1)

New files, following the Tokyo/Seoul batch (`landmark_registry_tokyo_seoul.gd`, `landmark_set_tokyo_seoul.gd`,
`tests/tokyo_seoul_landmarks_test.gd`):

- `scripts/data/landmark_registry_singapore.gd` (`LandmarkRegistrySingapore.entries()`), split into
  `scripts/data/singapore/sg_reg_*.gd` groups if it nears the size limit, as Stockholm did.
- `scripts/generation/landmarks/singapore/landmark_set_singapore.gd` (`LandmarkSetSingapore.build`, one `match` arm
  per type, returns false for types it does not own).
- Both listed in `scripts/data/landmark_registries.gd` (`entries()` and `sets()`).
- `scripts/generation/landmarks/singapore/landmark_sg_kit.gd` only for shapes two or more builders share: lofted
  shell ribs, sunshade panel field, palm, lit ring.
- Move the `marina_bay_sands` row out of `landmark_registry_asia_south.gd:47` and the builder out of
  `landmark_sea_towers.gd:119-207` (with `_leg_z`, `_ship`, `_ship_hw` if nothing else uses them) and drop its arm
  from `landmark_set_asia_south.gd:38`. The type id stays, so aliases and docs keep working.
- `tests/singapore_landmarks_test.gd`: primary stays `marina_bay_sands`; each extra lies within its `radius_m` of
  the centre; alias resolution; each model's height in range; 2 to 16 textured parts; the named OSM ways in the
  site table are cleared and a named neighbour is kept (for example Raffles City Tower beside Swissôtel).

Kits to reuse, not re-invent: `LandmarkMesh` (`grid`, `lathe`, `poly_prism`, `beam`, `frustum`, `box`),
`LandmarkMaterials` (`glass`, `pbr`, `lit`, `pool_water`, `gold`), `SkyKit` and `TowerSpec`
(`landmarks/north_america/`), `LandmarkBrKit`, `LandmarkKits`, `LandmarkDetail`, `LandmarkAsiaSouthUtil`,
`LandmarkLights`, `LandmarkTerrain`, and the registry fields `model_rects_m`, `clear_rect_m`, `clear_path_m`,
`clear_offsets_m`, `base: water`, `base_drop_m`, `tree_clear_m`, `tree_rect`.

Done when: the new test, `landmark_catalog_test`, `landmark_placement_test`, `landmark_list_test` and
`tools/check_class_size.sh` pass, and Marina Bay Sands renders exactly as before the move (same triangle count in
`capture_landmarks` `stats.tsv`).

## Phase 2: Marina Bay icons

Each task lists the features that must be readable in the captures, the build approach, a triangle budget and the
file. Budgets are targets under the 150,000 ceiling; the Kruunuvuorensilta model sits at about 65,000 triangles and
16 parts, which is the practical reference for a bespoke bridge.

### SG-2.1 Marina Bay Sands rebuild (`landmark_sg_marina_bay_sands.gd`, about 110,000 triangles)

- **Towers:** three 55-storey towers at their measured centroids (offsets from Tower 2, the registry anchor),
  each turned to its own footprint axis, so the row bends and the gaps differ. Each tower is two slabs: a straight
  west slab and a curved east slab that splays at the base and meets it near level 23. The splay differs per tower
  (measure from the footprints: Tower 1 is 76 × 77 m, Tower 3 only 45 × 57 m).
- **Faces:** west face a real glass curtain wall with vertical fins (`SkyKit` facade material with storey UVs and
  shared night windows); east face stepped balconies with planters; narrow end walls in pale cladding.
- **Legs:** lofted with `LandmarkMesh.grid` along the measured curve, replacing the present 18 straight beams per
  tower. The atrium gap between the two slabs is open at the base.
- **SkyPark:** 340 m deck following the towers' bend (it is not a straight hull), 66.5 m cantilever past Tower 3 at
  the north end, tapered hull with a smooth soffit, infinity pool along the city side, palms and garden,
  observation deck on the cantilever. Top at 207 m (verify against the SkyPark way's `height=207`).
- **Podium:** low curved-roof blocks (Shoppes, theatres, expo) from relation 2298319 through `model_rects_m`; the
  two Crystal Pavilions and the Apple glass sphere on the water; event plaza steps down to the bay.
- **Registry:** anchor moved to the Tower 2 centroid, `yaw_deg` recomputed from the Tower 1 to Tower 3 chord,
  `clear_offsets_m` for the three tower ways and the SkyPark way, `clear_m` reduced from 190 so the Shoppes relation
  and the ArtScience site are not swept away.
- **Done when:** the centre view shows three separate towers with sky between them and the boat on top; the Merlion
  Park look shows the splayed legs, the glass west face and the cantilever; the night frame shows lit windows and a
  SkyPark edge line; the catalog test pins the height.

### SG-2.2 Esplanade (`landmark_sg_esplanade.gd`, about 110,000 triangles)

- Two rounded shells of different size (concert hall 96 × 73 m, theatre 78 × 107 m), lofted with `grid` from ways
  256163011 and 256163012, top near 35 m.
- The sunshade field: triangular aluminium shades whose opening angle varies with the face normal, flat near the top
  and beaked on the east and west flanks. One merged surface of folded triangle pairs per shell, about 50,000
  triangles each; this is the feature the model lives or dies on.
- Glass skin beneath the shades, the low linking podium, the waterfront outdoor theatre and its canopy.
- **Done when:** the spiked "durian" texture reads from the Padang (570 m) and from the bay, and the two shells are
  visibly different sizes.

### SG-2.3 Merlion Park (`landmark_sg_merlion.gd`, about 25,000 triangles)

- 8.6 m white Merlion on its wave base, facing east across the bay; scales as relief bands, mane, curled fish tail
  (`lathe` plus `grid`). The camera gets close, so most triangles go to the head.
- The water jet: a translucent swept strip arcing from the mouth into the bay with a splash ring.
- Stepped viewing jetty over the water (`base: water`), and the 2 m cub behind (node 6283080658).
- Site from SG-0.4. **Done when:** the statue is recognisable from the jetty eye with Marina Bay Sands behind it.

### SG-2.4 Singapore Flyer (`landmark_sg_flyer.gd`, about 45,000 triangles)

- 165 m tall, 150 m rim: a thin ladder-truss rim with cable spokes, not a solid spoked wheel; 28 capsules outside
  the rim; two-leg A-frame supports with stay cables; three-storey terminal with a round atrium.
- Needs a registry row: no element in the snapshot carries `attraction=big_wheel`, so `landmark_wheel.gd` never
  fires here. Reuse its wheel maths (`LandmarkWheel.DIAMETER_PER_HEIGHT`) rather than copying it.
- Rim lights as `*Lamp` parts. Site, axle bearing and terminal footprint from SG-0.4.
- **Done when:** from the centre view the wheel reads as a thin ring, not a disc, and stands the right side of the
  Esplanade.

### SG-2.5 ArtScience Museum (`landmark_sg_artscience.gd`, about 30,000 triangles)

- Ten "fingers" of different heights rising from a round base, smooth white skin, skylight tips, lily pond around
  it (`pool_water`), standing on the promenade below Marina Bay Sands. `grid`-lofted fingers on a ring.
- Site from SG-0.4; its clearance must not overlap the Shoppes relation.

### SG-2.6 Helix Bridge (`landmark_sg_helix.gd`, about 60,000 triangles)

- 280 m curved plan following way 164881537; two counter-wound stainless tubes joined by ring struts; glass and
  mesh canopy segments; four cantilevered viewing pods on the bay side (ways 164881553–164881555, 395120469,
  687965211); Y-shaped piers; LED line at night.
- Bespoke builder with `clear_path_m`, pattern `landmark_fh_crown_bridge.gd`. Helix tubes as swept `beam` segments
  with a fixed triangle budget per turn; reuse surface keys to stay inside 16 parts.
- Remove the `conf 1` Helix row from `bridge_specs_southeast_asia_au_nz.gd:68`.
- **Done when:** the double spiral reads from the Youth Olympic Park eye and the deck meets both banks
  (`bridge_connection_test` pattern).

### SG-2.7 Fullerton Hotel and waterfront pavilions (`landmark_sg_fullerton.gd`, about 40,000 triangles)

- Grey Aberdeen-granite palazzo on way 46595395 (79 × 128 m bbox) with giant Doric colonnades on all sides
  (`LandmarkDetail.colonnade`, `cornice`), warm flood at night. Height to verify (OSM says 25 m).
- One Fullerton, the Waterboat House, Clifford Pier and Customs House as a second, tier-5 row.

### SG-2.8 Supertree Grove (`landmark_sg_supertrees.gd`, about 80,000 triangles)

- One row for the grove. One parametric tree (concrete core, steel planting-skin trunk in magenta and bronze tones,
  inverted-umbrella canopy of splayed rods) instanced at the 12 measured positions with heights of 25–50 m.
- OCBC Skyway (128 m walkway at 22 m between two trees, `LandmarkBrKit.railing`); treetop bistro on the tallest.
- Canopy `*Lamp` parts for the purple and multicolour night glow. About 6,000 triangles per tree.

### SG-2.9 Flower Dome and Cloud Forest (`landmark_sg_gardens_domes.gd`, about 50,000 triangles)

- One row, two asymmetric glass shells: Flower Dome low and long, Cloud Forest taller and peaked. `grid` loft from
  the measured outlines, external white steel rib arches standing off the glass (`beam` arcs), real `glass`.

### SG-2.10 Marina Bay waterfront ground

- Not a landmark row. Check in r0 how the Promontory (way 116801285), NS Square (ways 1221351351, 1492514975, mapped
  as `building=construction`), the promenade loop and the Bayfront bridges render, and fix through surface handling
  and Phase 4 rows. NS Square must not rise as a generic building on the water.

**Validation for every Phase 2 task:** catalog, fidelity, placement and lights tests pass; a
`capture_landmarks` sheet (day and `--night`) is laid beside the reference photo with
`tools/landmark_compare_sheets.py`; silhouette, proportions, colour and night frame are recognisable; one in-world
look per landmark is taken from open space.

## Phase 3: Civic District, heritage and skyline

### Batch B: Civic District (within 600 m of the centre, so seen closest)

| ID | Row | Must-have features | Site |
| --- | --- | --- | --- |
| SG-3.1 | National Gallery | Former Supreme Court (green copper dome, Corinthian portico, pediment sculpture) joined to City Hall (long Corinthian colonnade and steps facing the Padang) by the gold filigree roof canopy and glass link | ways 170960936 + 46595597 |
| SG-3.2 | Supreme Court (Foster) | Glass and marble block under the flying-saucer disc | way 46594825 |
| SG-3.3 | Victoria Theatre and Concert Hall | Twin Palladian wings, central 54 m clock tower with dome, Raffles statue in front | relation 3899820 |
| SG-3.4 | St Andrew's Cathedral | White neo-Gothic nave, lancet windows, pinnacles, slim spire, in its lawn (`tree_rect` keeps the lawn open) | way 155980025, grounds way 46594828 |
| SG-3.5 | Arts House + Parliament House | Old Parliament with the elephant statue; the modern Parliament block behind | way 243427705; Parliament from SG-0.4 |
| SG-3.6 | Padang ensemble | Cricket Club, Recreation Club, Cenotaph, Lim Bo Seng Memorial; the lawn kept clear of procedural trees | ways 46594820, 46594819, 256153714 |
| SG-3.7 | Civilian War Memorial | Four tapering white pillars joined at the base, in War Memorial Park (way 460428718) | SG-0.4 |
| SG-3.8 | Raffles Hotel | White three-storey colonial front, verandas, red clay tile roofs, palm forecourt | SG-0.4 (POI node only today) |
| SG-3.9 | Old Hill Street Police Station | Six storeys, 927 shutters in rainbow bands | relation 6955290 |
| SG-3.10 | Swissôtel The Stamford + Raffles City | 226 m round aluminium-clad tower, twin lower towers, podium (TowerSpec, skyline row) | ways 172364975, 172364974, 39487263 |

The Dalhousie Obelisk and the Asian Civilisations Museum river front join SG-3.3 only if its part count allows;
otherwise the museum is its own tier-5 row.

### Batch C: heritage districts and river

- **SG-3.11 Sri Mariamman Temple** (way 300380459): polychrome sculpted gopuram over South Bridge Road with figure
  bands as coloured relief tiers; boundary wall with cow statues.
- **SG-3.12 Buddha Tooth Relic Temple** (way 47298635): red and white Tang-style hall, dark grey hip roofs in tiers.
- **SG-3.13 Sultan Mosque** (SG-0.4): two gold onion domes with the dark glass-bottle band, four corner minarets,
  cream walls (`LandmarkAsiaSouthUtil.onion`, `LandmarkKits.minaret`). About 1.7 km out: `radius_m` at least 2,500.
- **SG-3.14 Lau Pa Sat** (way 45098520): octagonal cast-iron market, filigree arches, clock tower, red tile roof.
- **SG-3.15 Clarke Quay** (SG-0.4): pastel godown blocks under the ETFE canopies along the river; Read Bridge. The
  snapshot's "Clarke Quay Central" is the mall across the river, not this site.
- **SG-3.16 Second tier**, in this order as slots and time allow: Thian Hock Keng (way 172272611), CHIJMES chapel
  (way 97666818), Armenian Church (way 172368093), Central Fire Station (way 172368086), National Museum dome
  (way 32342169).

### Batch D: skyline towers

Work in this order, because the first step fixes the most visible errors for the least effort.

1. **Height fixes.** For every building from the SG-0.3 audit, correct the rendered height. Prefer a `TowerSpec` row
   (it also gives a facade); where the building is plain, a height-only override is enough. Add
   `scripts/data/sg_tower_specs.gd` (`SgTowerSpecs`, pattern `NycTowerSpecs`: `row()` sets `skyline: true`,
   `skyline_priority` and `tower_spec`) and an arm in the Singapore set that builds a type from
   `SgTowerSpecs.spec_for(type)`, as `landmark_set_nyc.gd:9` does.
2. **Towers whose OSM parts already give the massing** get facade and colour evidence only, no spec: One Raffles
   Place (parts 325793773 at 283 m, 325793737 at 215 m, Tower 2 at 209 m), OCBC Centre (six parts at 76, 136 and
   188 m), Capital Tower (parts at 254, 229, 190 and 163 m), One Raffles Quay, Pinnacle@Duxton (sky-bridge
   relations 4714989 and 4714990 at 75 and 150 m).
3. **Spec towers with a signature shape,** nearest first: UOB Plaza One (octagonal, stepped), Republic Plaza
   (tapered, chamfered corners), CapitaSpring (facade peeled open at the mid-height garden), Ocean Financial Centre,
   The Sail (twin sail-shaped glass), Marina Bay Financial Centre 1–3, Marina One (dark blocks round a green carved
   heart), Guoco Tower, Oasia Hotel Downtown (red mesh with greenery), Parkroyal Collection Pickering (contour
   terraces with sky gardens), South Beach, Suntec City with the Fountain of Wealth (way 121874612), the Marina
   Centre hotel fan.
4. **Towers to measure first** (SG-0.4): DUO (concave honeycomb), The Gateway (two knife-edge trapezoids), Parkview
   Square (brown Art Deco), The Concourse.
5. **Far ring:** National Stadium dome, Marina Barrage and the Benjamin Sheares Bridge viaduct, with `radius_m` large
   enough to reach the centre view.

A tower test in the pattern of `nyc_skyscraper_sites_test` pins that no spec's `clear_m` erases a neighbouring tall
building; Raffles Place is as dense as Lower Manhattan.

**Out of scope:** Changi and Jewel (a separate task through the capital-airports pipeline), Sentosa, Jurong, the Zoo.

## Phase 4: bridges (SG-4)

- Raise the measured rows to `conf 2` with verified spans and the right structure type in
  `bridge_specs_southeast_asia_au_nz.gd`: **Cavenagh** (1869 wrought-iron footbridge, white, cast-iron portal
  towers; the row notes say its stayed-suspension hybrid is not representable in `BridgeParam`), **Anderson** (three
  white steel bowstring arches, stone abutment arches; row is `truss` today), **Elgin** (three slender concrete
  bowstring arches with hangers and lamp standards; row is `arch_deck` today), **Esplanade Bridge** (low
  seven-span arch deck).
- New rows for **Coleman**, **Read**, **Ord** (way 688756545) and **Alkaff** (painted in its multicolour scheme);
  sites from SG-0.4.
- Cavenagh and Anderson need short bespoke builders in the Singapore set, as the Helix does. They then take extras
  slots (tier 5) unless built through the bridge channel; decide per bridge when the builder exists.
- Set `tier` so the four bridge slots go to Cavenagh, Anderson, Elgin and Esplanade Bridge.
- Tests: `bridge_specs_test`, `bridge_param_test`, `bridge_select_test`, `bridge_connection_test`.

## Phase 5: city fabric (SG-5)

Files: `architecture_cities_asia.gd`, `building_era.gd`, `city_styles.gd`, `architecture_data.gd`,
`facade_patterns.gd`, `roof_clutter.gd`, `asia_fronts.gd`, `tower_looks.gd`, `docs/architecture-styles.md`,
`tests/architecture_test.gd`. Model: the Seoul and Tokyo rows and `ArchitectureCitiesEastAsia.seoul_rule`.
`building_era.gd` and `city_styles.gd` have open changes: put the rule in a new
`architecture_cities_singapore.gd` and call it from the existing `match` arm with a one-line edit.

- **SG-5.1 `singapore_rule`.** Replaces the three-line rule at `building_era.gd:564`. Because 80 % of buildings are
  `building=yes`, the rule decides by district first, then shape: `sg_shophouse` only inside a shophouse district
  or for a narrow terraced footprint of 1–4 levels; a large low footprint outside those districts is civic,
  commercial or industrial, not a shophouse. Religious buildings stop inheriting the `southeast_asia` pagoda and
  split by OSM `religion` (the detailed layer has 10 Christian, 5 Muslim, 5 Hindu, 1 Buddhist, 1 Taoist, 2 Chinese
  folk and 1 Jewish place of worship).
- **SG-5.2 New rows:** `sg_hdb_slab` (1960s–80s long slab, common corridors, colour band, block number),
  `sg_hdb_point` (1990s point blocks, bay windows, pitched cap roofs), `sg_hdb_new` (2000s 35–50 storey precast, sky
  gardens), `sg_condo` (glazed balconies, pool-deck podium), `sg_colonial` (white civic, verandas, clay tile),
  `sg_blackwhite` (bungalows), `sg_artdeco` (Tiong Bahru curved white flats), `sg_mall` (Orchard media-facade
  malls), `sg_industrial` (flatted factories), `sg_house` (terrace houses). The existing `singapore` row already
  describes an HDB slab with colour bands; keep it as the fallback.
- **SG-5.3 District circles** in `city_styles.gd` (5 to about 25): Boat Quay, Clarke Quay, Telok Ayer, Tanjong Pagar
  and Duxton, Ann Siang, Emerald Hill, Katong and Joo Chiat (Peranakan pastels), Tiong Bahru, Bugis and Bras Basah,
  Orchard, Marina Centre, Marina Bay and Downtown, Shenton Way, River Valley condo belt, Civic District, and the
  HDB towns reachable on walks (Toa Payoh, Queenstown, Kallang and Bendemeer, Tanjong Pagar Plaza). Centres and
  radii measured on the map, each pinned by a case in `architecture_test`.
- **SG-5.4 Void decks.** Open ground storey on columns for `sg_hdb_*` where OSM gives no `min_height` part: a new
  ground-floor mode beside `g: none|shop`, lift-core walls kept solid.
- **SG-5.5 Five-foot-way.** Recessed arcade at the ground storey of `shophouse` fronts (pilasters at every party
  wall, shadowed walkway, shop behind) in `facade_patterns.gd` and the relief path, inside the 300 m relief radius;
  timber-shutter upper storeys and ornate plaster in the Peranakan districts.
- **SG-5.6 HDB cues.** Block number on slab ends (generalise `AsiaFronts.danji_number` to "Blk NNN" from
  `addr:housenumber`), rooftop water tanks and lift motor rooms in `RoofClutter` (promised by the comment at
  `architecture_cities_asia.gd:118`), drying-pole racks as an Ultra relief key.
- **SG-5.7 Towers.** Singapore glazing mix in `tower_looks.gd` (more blue-green low-e glass, sky terraces with
  planting on post-2010 towers), green roofs through `roof_deck` evidence. The far layer carries 5,054
  `building:colour` and 2,944 `roof:shape` tags: confirm the far city uses them before adding rules.
- **SG-5.8 Detail budgets (open decision).** `CityDetail.CITIES` (`scripts/render/city_detail.gd:17`) gives
  Helsinki, Espoo, Turku and Stockholm raised detail budgets. Adding `"singapore"` needs a `VERSION` bump, a case in
  `city_detail_test` and a `tools/build_bench.gd` run showing build time and peak memory. Recommendation: do it,
  after SG-5.1–5.3, and only if the bench stays within the Stockholm figures.

Validation: `architecture_test` pins one case per new row and district; `asia_fronts_test`, `roof_clutter_test`,
`facade_relief_test`, `party_walls_test`, `building_terraces_test`; Chinatown, Kampong Glam and HDB looks.

## Phase 6: trees, water and atmosphere (SG-6)

- **SG-6.1 Trees** (`tree_species.gd`). A Singapore mix selected the way `khmer` and `nyc_park` are (a `tree_mix`
  rule in `heritage_zones.gd`), with street, park and forest splits instead of the single tropical mix. New species
  shapes: rain tree (very wide flat umbrella crown, the signature roadside tree), angsana, yellow flame, tembusu,
  sea almond, banyan, royal, coconut and fan palms. `GENUS` entries for Samanea, Pterocarpus, Peltophorum, Khaya,
  Ficus, Syzygium (Cocos and Roystonea already map to `palm`). The detailed layer has 369 mapped trees, 13 with a
  species tag, so the mix does almost all the work. Dense shrub belts on main-road verges and medians.
- **SG-6.2 Water** (`scripts/generation/water_surface.gd`). Palette for the Singapore Strait (green-grey), Marina
  Reservoir (calm, darker fresh water inside the barrage; mapped as `waterway=river` "Marina Reservoir") and the
  Singapore River (brown-green). Check in r0 what the water looks like today before changing anything.
- **SG-6.3 Boats and port.** Bumboats moored at Boat Quay and Clarke Quay (new small craft in the vessel set, beside
  `market_boat_model.gd`); an anchorage of cargo ships and tankers on the strait horizon south of Marina South
  (far-layer static ships, `cargo_ship_model.gd`); gantry cranes and stacks at Tanjong Pagar and Brani where the far
  layer maps port land (5 elements tagged `industrial=port` today), beside `cargo_berths.gd`. `vessel_prototypes.gd` and
  `large_ships.gd` have open changes: add new files.
- **SG-6.4 Atmosphere.** Humid-tropics haze from the climate class in `atmosphere_rig.gd`, `haze_rig.gd` and
  `sky_palette.gd`: whiter horizon, softer distance contrast, towering cumulus. `atmosphere_rig.gd` and
  `sky_palette.gd` have no humid or tropical branch today, so this is new behaviour and needs its own `haze_test` and `sky_test` cases.

Validation: `canopy_vegetation_test`, `tree_lod_test`, `climate_test`, `coastal_water_test`,
`far_water_palette_test`, `vessel_models_test`, `cargo_berths_test`, `sky_test`, `haze_test`.

## Phase 7: streets and transport (SG-7)

- **SG-7.1 Vehicles.** `car_fleet.gd` has no Singapore fleet (`default`, `north_america`, `japan`, `nordic`,
  `south_europe`, `europe`). Add `singapore`: light-coloured sedans, SUVs and MPVs, plus blue, yellow and red taxi
  liveries. A double-deck bus model with SBS Transit (red and white) and lush-green liveries in
  `transit_vehicles.gd` (open changes: keep to one added entry and a new model file).
- **SG-7.2 Street furniture.** `StreetFurniture.family` knows `na`, `japan`, `uk`, `nl` and `europe`. Add `sg`:
  green pedestrian railings, covered linkways at bus stops and MRT exits, green road signs with white text, bus-stop
  shelters, expressway planter boxes. ERP gantries only if toll points are mapped (no `barrier=toll_booth` in the snapshot).
- **SG-7.3 Road markings.** Check zig-zag crossing approach lines, yellow kerb lines and red bus-lane lines against
  `road_markings.gd`; add only what is missing. Singapore drives on the left: confirm traffic already does.
- **SG-7.4 MRT (optional, last).** Concrete viaduct fascia and round piers instead of `VIADUCT_BRICK_HEX` for
  non-UK rail bridges (`rail_builder.gd:47`); add `"singapore"` to `TrainSpecs.METRO_REGIONS` with a white, red and
  black livery. No elevated track lies inside the bundled area, so this shows only on a live pin (for example the
  East-West line east of Kallang) and is checked there.

Validation: `car_fleet_test`, `bus_stop_test`, `street_furniture_test`, `road_markings_test`; for SG-7.4
`rail_viaduct_test` and `train_test`; one main-road look.

## Phase 8: night (SG-8)

- Per landmark through `LandmarkLights` (`FLOOD_META`, `*Lamp`, the `GLOW` table): Marina Bay Sands warm tower
  uplight and a white SkyPark edge line; Supertrees purple and multicolour canopies; Flyer rim ring; Helix LED
  ribbons; Esplanade warm glow through the shells; ArtScience uplit white petals; Fullerton, National Gallery,
  Victoria Theatre and St Andrew's warm floods; Sultan Mosque domes; Merlion spotlit. Each builder adds its lamp
  parts when it is written; this phase tunes them together in one night round.
- CBD: crown lights and logo bands on the Raffles Place towers through their specs; Orchard and Bugis media facades
  by enabling the `screens` relief key on `sg_mall`.
- Captures need `--preset=3`: night lights are Ultra-only content.
- Stretch, on request only: a slow Marina Bay Sands light-beam fan from the SkyPark, desktop Ultra only.

Validation: `landmark_lights_test`, `street_screens_test`, night and late looks.

## Phase 9: review rounds and wrap-up (SG-9)

- Capture rounds r1…rN after each phase into `visual-plan/reviews/singapore-rN-<date>/` at the fixed eyes. For each
  landmark: reference photo beside the model sheet and beside one in-world look; list mismatches; fix; recapture.
  Do not delete a round folder that the tracker names as evidence.
- `docs/fidelity-scorecard.md` §9: a Singapore entry and a rating per round.
- `docs/architecture-styles.md`, `docs/singapore-landmark-sources.md`, README bridge and landmark lists.
- Performance: `tools/perf_baseline.gd` on Singapore before and after (cold, cached, fly) at presets 2 and 3;
  `lod_test`, `memory_budget_test`, `impostor_test`, `landmark_ultra_lod_test`. The Phase 2 budgets add up to about
  550,000 triangles within 2 km on Ultra; check the frame time at the Merlion Park eye, where most of them are in
  view at once.
- Optional, on request: a Singapore `PresetViews` row (Merlion Park vantage) and a re-baked capital thumbnail
  (`--capital-thumbs` overwrites `assets/capital_thumbs/singapore_singapore.jpg`).

## Captures and eyes

Two sets per round, because a look that re-centres the world leaves the bundled snapshot (analysis point 3).

**Set A, centre view (what a user sees on opening Singapore; bundled data).** Add `--keep_centre`:

```
tools/godot_bg.sh --path . --script tools/capture_presets.gd --position 4000,4000 -- --tag=singapore-rN
  --preset=3 --pin=1.28967,103.85007 --places=singapore --times=golden,noon,night,late,roofs --keep_centre
  --looks="<set A eyes>"
```

**Set B, close looks (world rebuilt ahead of each eye; live Overpass, cached after the first run).** Same command
without `--keep_centre`, a different `--tag` suffix, and the set B eyes. Fabric differences between A and B frames
of the same street are data differences, not regressions.

**Model sheets:** `tools/capture_landmarks.gd --types=<types> --tag=sg_lm_rN` and again with `--night`, then
`python3 -I tools/landmark_compare_sheets.py --tag=sg_lm_rN`.

Candidate eyes. Coordinates are derived from the snapshot or, where marked *, from memory. Each must be confirmed
clear of footprints in r0 and then frozen. Format: `lat,lon,height_m,bearing,pitch`.

| Set | Eye | Candidate | Shows |
| --- | --- | --- | --- |
| A | Padang centre, looking east | `1.29055,103.85293,1.7,100,4` | Esplanade, Flyer, Marina Bay Sands over the trees |
| A | Padang centre, looking west | `1.29055,103.85293,1.7,265,8` | National Gallery front, Supreme Court disc |
| A | Padang centre, looking north | `1.29055,103.85293,1.7,25,10` | St Andrew's spire, Swissôtel |
| A | Padang centre, looking south | `1.29055,103.85293,1.7,185,10` | Victoria Theatre, Raffles Place tower wall |
| A | Boat Quay river bend (drone eye over water) | `1.28770,103.84970,12,200,0` | shophouse row under the CBD towers, bumboats |
| A | Cavenagh Bridge approach | `1.28690,103.85215,1.7,150,3` | bridge, Fullerton Hotel |
| A | Roof-height skyline | `1.28967,103.85007,140,120,-8` | whole Marina Bay arc |
| B | Merlion Park jetty | `1.28640,103.85450,1.7,95,5` | Merlion, jet, Marina Bay Sands across the bay |
| B | Mid Marina Bay (drone eye) | `1.28500,103.85650,30,250,0` | CBD wall, Fullerton, Merlion |
| B | Esplanade waterfront * | `1.28850,103.85600,1.7,160,5` | shells close up, bay |
| B | Helix approach, Youth Olympic Park * | `1.28900,103.86020,1.7,175,5` | Helix, ArtScience, Marina Bay Sands |
| B | Supertree Grove lawn * | `1.28200,103.86400,1.7,0,25` | trees and Skyway |
| B | Chinatown, Pagoda St at South Bridge Rd | `1.28290,103.84520,1.7,200,10` | Sri Mariamman gopuram, shophouses |
| B | Kampong Glam, Bussorah St * | `1.30120,103.85960,1.7,330,10` | Sultan Mosque down the street axis |
| B | HDB estate, Toa Payoh * | measured in SG-0.4 | slabs, void decks, block numbers |

River and bay eyes use drone heights: a `--looks` height over a river is measured from the riverbed.

## Order and size

1. **Phase 0, then SG-1, then SG-2.1–2.5.** The clock fix, height audit and the five icons seen from the centre
   deliver most of the recognisability. About 5 builders of 300–700 lines each.
2. **Batch D step 1 (height fixes) and Batch B.** Both change the centre view directly.
3. **SG-2.6–2.10 and Phase 4 bridges.**
4. **Phase 5 fabric**, then Batch C and the rest of Batch D.
5. **Phases 6–8**, with SG-7.4 last.
6. Each phase ends with its tests passing and a capture round, so the pass can stop after any phase.

## Open decisions

| Decision | Recommendation |
| --- | --- |
| Raise `ultra_registry_limit` above 22 | No: each extra slot costs a bridge |
| Add Singapore to `CityDetail.CITIES` (SG-5.8) | Yes, if the bench stays within Stockholm's figures |
| Build the MRT viaduct and train work (SG-7.4) | Defer: nothing of it shows in the centre view |
| Re-cut the bundled snapshot so missing sites are in it | No for now: registry rows do not need the footprint; revisit if clearing leaves generic blocks standing on a landmark site |
| Preset vantage, thumbnail re-bake, light-beam show | Only on request |

## Verification

- Tests, headless and in the background: `tools/run_tests.sh landmark singapore bridge architecture asia_fronts roof
  facade canopy tree water vessel car_fleet street` after the relevant phase; a single test with
  `tools/godot_bg.sh --headless --path . --script tests/<name>_test.gd`. A test also fails on a `SCRIPT ERROR:` line
  even when it exits 0.
- `tools/check_class_size.sh` after every new or grown class.
- Windowed tests (`screenshot_test`, `world_cache_test`) once at the end, in the background.
- **Done means:** every Phase 2 and Batch B landmark is recognisable beside its reference photo by day and by
  night; the SG-0.3 buildings stand at their real heights; all listed tests and the class-size check pass; and
  performance is within noise of the r0 baseline.
