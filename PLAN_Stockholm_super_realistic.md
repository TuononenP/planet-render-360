# Stockholm super-realistic: landmarks and city

> Tracker in the house style of `.agents/plans/2026-11-03-stockholm-hero.md`: claim a task, tick it only after its
> validation passes, add one evidence line. Status legend: `[x]` done and validated, `[~]` in progress, `[ ]` open.
> Decisions taken (the plan's recommendations): Tier A + B landmarks, Tier C only where the far layer reaches;
> keep the 26-slot Ultra cap with nearest-first selection; cliffs from open data if fetchable, else authored relief.

## Tracker

- [x] S-0.1 Baseline capture — `visual-plan/captures/sto_lm_base/` (29 types incl. City Hall, Riddarholmen,
  Västerbron, Central; `stats.tsv` triangle counts) and `visual-plan/reviews/sto-r5-2026-11-19/` (Ultra golden/noon/
  night, audit, ten looks). Eyes look0 and look8 stood in tree crowns and look3 on a roof: moved for later rounds.
- [x] S-0.2 Reference set — `tools/commons_refs.py` (Commons search with licence/subject filters, `--pin`, `--drop`,
  `--find`) fetched front/quarter/aerial (night where lit) for every Stockholm type that exists in the registry (77 with the
  Tier A/B/C and bridge types) into `visual-plan/refs/landmarks/<type>/`, each with 2-3+ documented photos (README row: URL,
  author, licence; Evert Taubes terrass, Waterfront and the two statues have two) and the city refs in
  `visual-plan/refs/stockholm/` (summer vantage from Mariaberget, Västerlånggatan, Strandvägen, Slussen/Guldbron, night
  skyline). The first automatic pass was about a third wrong (interiors, details, Copenhagen's Kastellet, maps, duplicates, a lion
  door-knocker); bad views were dropped, re-fetched or pinned by hand and re-checked on contact sheets, and the building agents
  replaced refs that showed the wrong building (Rosendal, Gothenburg's Taube statue). Weak views remain and are listed in the
  S-6 review (Vasa and Nordiska fronts, a few distant shots); JPGs are gitignored, READMEs are tracked.
- [x] S-0.3 Sources doc — `docs/stockholm-landmark-sources.md` (OSM ways, centroids, axis bearings, sizes, heights
  for 14 + 10 + 7 existing and 25 planned types, four parallel measurement passes) and a Stockholm section in
  `docs/data-source-register.md`. Registry corrections collected at the top of the doc and applied with their phases
  (City Hall 31 m west and no yaw, Grand Hôtel 27 m off with the yaw sign likely wrong, Söder Torn yaw -13.3,
  Katarinahissen 96.5, Klara 8.9 m east, Västerbron 16 m along the deck); Hötorg 61 m confirmed (OSM's 72 m is above
  sea level).
- [x] S-0.4 Landmark slots — registry split into `scripts/data/stockholm/sto_reg_*.gd` groups; `skyline_priority`
  only on ≥ 40 m skyline items; Hötorgsskraporna one grouped entry (five slabs with their own curtain walls in one
  model, `clear_offsets_m` from the mapped world positions); `stockholm_hero_landmarks_test` pins the rule and now
  checks 1k–150k triangles (Katarinahissen on a temporary 400 floor until S-1). 2026-11-19: hero test (25 types),
  placement, lights, gronalund and class-size pass; catalog test fails only on Helsinki types (not this work).
  `BUILD_VERSION` 305. Cap measurement (raising 26 on Ultra) not needed: nearest-first holds the cap.
- [x] S-0.5 Detail city — `"stockholm"` in `CityDetail.CITIES` (`VERSION` 3), pinned in `city_detail_test`
  (Kungsholmen centre and the Monteliusvägen eye). 2026-11-19, `build_bench` (new `stockholm` place, Ultra, serial,
  windowed): world 19.2 s with the profile on vs 19.3 s off, 3.83 GB peak either way, byte-identical fingerprint
  (1,848 real buildings, no impostors: the ring is data-limited, not cap-limited). The raised caps, the 900 m roofline
  ring and the LodRing boost act at view time, so the bench does not see them; cold time-to-view on a live Ultra run
  is still to be measured at the S-6 end check (≤ 150 s). Helsinki-only sources (orthophoto, HSY canopy, register
  trees) are gated by their own coverage and do not fire for Stockholm.
- [x] S-1 Placeholders rebuilt — 2026-11-20, five parallel batches, each with a four-view capture reviewed against its refs
  (`visual-plan/captures/sto_s1_towers`, `_palaces1`, `_palaces2`, `_churches`, `_central`, plus `_night` runs):
  towers (Hötorg five slabs with five curtain walls and podium, Katarinahissen, Söder Torn, Kastellet), palaces 1
  (Opera, Grand Hôtel with yaw 37.5 and a new position, Nationalmuseum as brick with sandstone bands), palaces 2
  (Riddarhuset with the curved säteri roof, Wrangel, Bonde), churches (Klara, Sofia as the photos show it: Greek cross
  with a copper spire, not a dome; Tyska kyrkan with nave, portal, gargoyles), Stockholm Central from its own model
  (Vasagatan front, glazed hall vault, nine platform canopies; moved out of the capital-station kit). Hero test
  (26 types), placement, lights, fidelity and class-size pass in the real tree. Known gaps: Hötorg night windows
  and Opera floodlight wash unconfirmed in the harness; Sofia spire plain, Tyska tower placement ±4-9 m,
  Kastellet knoll is a plinth; `Palaces._block` still used by a few older models.
- [x] S-2 Hero models to the bar — 2026-11-20, three batches with before/after captures compared against the refs
  (`visual-plan/captures/sto_s2_cityhall`, `sto_s2_a_before/after*`, `sto_s2_b_before/after*`, night folders): City Hall rebuilt
  across `landmark_stockholm.gd` and `cityhall/` (south arcade, Golden Hall windows, Borgargården arcade, tree-crown tower,
  cenotaph, terrace and Engelbrekt column, floodlights) and moved to the OSM centroid with yaw -7.5; Riddarholmen church with
  tracery lancets and the cast-iron spire, plus new `birger_jarls_torn`, `norstedts_building`, `evert_taubes_terrass`; Royal
  Palace, Storkyrkan, Katarina, Hedvig Eleonora, Riksdag recoloured and re-detailed from the photos, Library and Concert Hall
  rebuilt (`StoHeroLibrary`, `StoHeroConcert`); Västerbron rebuilt (asymmetric 204 + 168 m arches on a mid-river pier, X
  bracing, bents), Globen (portholes, Globentorget front, floods), Kaknäs (antenna balconies, lattice mast), Nordiska
  (sandstone, glazed ridge bands), Vasa (patina roofs, red masts), Eclipse (white lattice with swing carousel). Hero
  test (46 types), placement, lights, fidelity, landmark_test and class-size pass. Registry offsets for the palace and Riksdag
  were checked against the OSM outline and are the model frame, not errors. Gaps: Gröna Lund park is in the Tier B batch;
  floodlight wash is faint in the capture harness; the Taube statue is the generic figure; Vasa's refs front/quarter are
  entrance-queue shots (judged against the aerial).
- [x] S-3 Tier A — 2026-11-20, six parallel batches, each captured and reviewed against its Commons refs: Gamla stan (Slussen with
  the Guldbron and Stadsmuseet, Stortorget with Börshuset and the gabled houses, Skeppsbron row), Skeppsholmen (af Chapman as an
  authored full-rigged ship on water, Skeppsholmskyrkan, Moderna Museet from the OSM outline), Norrmalm A (Dramaten, both
  Kungstornen with the bridge, Kulturhuset with the glass obelisk and Sergels torg), Norrmalm B (Rosenbad, Sagerska huset,
  Arvfurstens palats, Stockholm Waterfront), Södermalm (Münchenbryggeriet from 29 OSM building parts with its chimney as a seat child,
  Högalidskyrkan, Fotografiska, Engelbrektskyrkan); Strömbron, Norrbro and Skeppsholmsbron with its crowns came with S-4. Slots:
  `LandmarkSites` takes a per-primary `ultra_total_limit`; Stockholm's City Hall entry sets 52 total / 48 registry
  (skyline items first, then nearest; High and every other city unchanged), `stockholm_hero_landmarks_test` pins it (43
  types pass), `bridge_select_test`, `nyc_tower_specs_test` and `landmark_fidelity_test` pass. Known gaps: sunken Sergels torg is at
  street level, Stadsmuseet has no photo, several heights are photo-scaled estimates (Sagerska 17.4 m, Arvfurstens 25 m, Dramaten
  37 m, Waterfront 42 m derived).
- [x] S-3 Tier B — 2026-11-20, four batches with captures reviewed against refs: Djurgården A (Bredablick, Hazelius gate,
  Waldemarsudde, Rosendal, ABBA museum, Liljevalchs, Cirkus: built from OSM tags and photos after the brief's descriptions
  proved wrong for five of them), Djurgården B (Sjöhistoriska, Tekniska museet, the Gröna Lund park with gate, pavilions,
  houses, Twister and Jetline), outer A (Kungliga biblioteket, Adolf Fredriks kyrka, Stadion with its OSM outline, Berwaldhallen),
  outer B (Skatteskrapan, Norra Tornen, Tele2 Arena, Viking Line and Värta terminals, Karl XII and Gustav II Adolf statues);
  Engelbrektskyrkan came with Tier A. 72 registry types pass `stockholm_hero_landmarks_test`; `landmark_test`, `landmark_catalog_test`
  (1,131 landmarks, after fixing the Gröna Lund and Viking Line alias collisions), placement, lights, fidelity, `gronalund_test` and class-size
  pass. Unverified heights are listed per type in the batch reports (Cirkus, Waldemarsudde, Rosendal, Liljevalchs, ABBA,
  terminals, statues are photo-scaled). Left out: Fyrtornet and Café Parken at Gröna Lund (no sources), Waldemarsudde gazebo and windmill.
- [x] S-3 Tier C — 2026-11-20: five outlying landmarks within the real reach (the code skips landmarks beyond
  `TerrainBuilder.LANDMARK_MAX_M` 9 km; the 12 km far layer carries OSM massing only): KTH main (3.0 km), Nya Karolinska with the
  Carolina Tower (3.5 km, skyline), Stockholm University Södra huset (4.7 km), Naturhistoriska riksmuseet (5.4 km), Strawberry
  Arena with Quality Hotel Friends (6.6 km, skyline). Excluded by distance and recorded in `docs/stockholm-landmark-sources.md`:
  Drottningholm (9.9 km), Victoria Tower and Kista Science Tower (11.2 km); Arlanda is outside the scene. Low Tier C items are
  built only when the scene centre moves toward them on Ultra (the preset's 48 icon slots go to skyline items and the nearest).
- [x] S-4 Bridges — 2026-11-20: all 18 Stockholm rows in `bridge_specs_north_europe.gd` are `conf 2` (the seven former `conf: 1`
  rows sourced from OSM polygons and Wikipedia, Centralbron's centre and bearing corrected to the Söderström crossing; ten new rows:
  Årstabroarna (old arch viaduct with its steel span, new red Foster bridge), Skanstullsbron, Johanneshovsbron, Sankt Eriksbron,
  Lidingöbron, Riksbron, Strömbron, Norrbro); bespoke Djurgårdsbron (four Norse-god granite columns with zinc gods, three-lamp
  candelabra, tram rails) and Skeppsholmsbron (gilded crowns) models; `tests/stockholm_bridges_test.gd` plus the `bridge_*` tests
  pass; Västerbron moved to the water-gap midpoint (59.32452, 18.02707). Per-row sources in `docs/stockholm-landmark-sources.md`.
  Not modelled: the old Årstabron lift span, Skanstull metro viaduct, Lilla Lidingöbron. `bridge_specs_test` closed for both Stockholm (`sto_bridge_stromsbron`) and Turku at `BUILD_VERSION` 321.
- [x] S-5.1 Södermalm cliffs — Lantmäteriet Markhöjdmodell 1 m (CC0) via Mapterhorn as `GroundModel` source `lm`, UrbanSmooth skipped on bare earth (`bare_earth.gd`, `ground_truth.gd`), Monteliusvägen eye retuned in `preset_views.gd`; `stockholm_cliff_test` (real-tile fixture: the eye stands on the cliff top, 25 m+ over Riddarfjärden) passes 2026-11-20. Live Ultra capture from the eye and closing hero-plan B-3 are done in the S-6 loop.
- [x] S-5.2 Shoreline — Stockholm-gated (`ShoreApron.stockholm(data)`): granite palette for ground paint, setts and paving
  (`shore_apron.gd`, `ground_material.gd`, `road_builder.gd`), darker granite quay ashlar (`quay_builder.gd`), dark
  bank fallback, `ShoreRailings.railed_body` lets railings run on non-tidal Mälaren/Baltic hard edges, granite skerry
  colour in `rock_outcrops.gd`; `tests/stockholm_shore_test.gd`, `shoreline_test`, `architecture_test`,
  `quay_moorings_test`, `marina_test` pass 2026-11-20. Before/after frames `visual-plan/reviews/s52-` / `s52b-` / `s52c-2026-11-20`:
  the Söder quay waterline reads grey granite instead of beige, the Riddarholmen front is about 13% darker but a light paving
  ribbon still shows at low sun. Open: the angular bank edges come from the shoreline patch geometry and are unchanged.
- [x] S-5.3 Fabric — Klara modernism, Kungsholmen/Södermalm stone city without the corner-dome chance, Djurgården villas, Gärdet funkis, Gamla stan roofscape, narrowed house->timber and 1965-89 panel rules, far-field carry-over; `stockholm_districts_test` and `architecture_test` pass 2026-11-20; documented in `docs/architecture-styles.md`.
- [x] S-5.4 Water traffic — Djurgården (line 82) and Waxholm boats, Viking/Silja liveries at Stadsgården and Värtahamnen (4.5 km reach), Strandvägen steamboat row, Söder Mälarstrand houseboats; new `tests/stockholm_harbour_test.gd` passes 2026-11-20 with `quay_moorings_test`, `harbour_ferries_test`. Note: the world ground is ±1.2 km, so Stadsgården is outside it from the Monteliusvägen preset centre (the wider radius only matters for offset eyes). `harbour_traffic_test` fails on untracked `harbour_traffic.gd` work that is not part of this plan.
- [x] S-5.5 Rail and street — blue SL C20 metro (`stockholm_metro`) on above-ground `railway=subway`, Tvärbanan/Lidingöbanan blue-white tram, vintage Djurgårdslinjen tram in its corridor, T-bana entrance sign, oak at Djurgården and lime avenues in Kungsträdgården/Humlegården via `HeritageZones` (`trees_only` flag), red SL buses verified; `tests/stockholm_transit_test.gd`, `train_test`, `tram_test`, `street_furniture_test` pass 2026-11-20.
- [x] S-5.6 Data — `stockholm_ring2500.osmb` re-cut: 1,375 highway ways (the 800-road cap is gone), README and `bundled_osm.gd` hash updated; `bundled_osm_test` now pins the manifest, hash and more than 800 ways, passes 2026-11-20.
- [x] S-5.7 Docs — `docs/architecture-styles.md` Stockholm rows and district/era paragraph, `docs/data-source-register.md` (Lantmäteriet bare earth, Stockholm sources), stale headers fixed 2026-11-20.
- [x] S-6 Hero loop and sign-off sheet — 2026-11-20 (agent pre-rating only; "photographic" stays the human gate). Round sto-r6 (Ultra,
  golden/noon/night plus a winter round, about 95 frames, 15 open-space eyes, seven bad frames discarded and redone, none inside
  a building): `visual-plan/reviews/sto-r6-2026-11-20/` (+ `-redo`, `-winter`, `-cold`) with the review README, a scorecard line in
  `docs/fidelity-scorecard.md` §9, and a follow-up shore/cliff round `s52d`/`s52e-2026-11-20` (granite cliff shading and outcrops,
  bevelled water corners). Hero-plan B-3 closed: the Monteliusvägen preset eye stands 38 m over Riddarfjärden on the cliff top.
  Cold Ultra time-to-view 23 s (build 12.6 s) against the ≤ 150 s target, on a busy machine. Final contact sheet of all 77 landmark and
  bridge types beside their references: `visual-plan/captures/sto_final/compare/page_00..12.jpg` with `page_NN.txt` and `index.tsv`
  (made by the new `tools/landmark_ref_sheet.gd`). End checks: windowed `world_cache_test` OK, windowed `screenshot_test` exit 0,
  all landmark, bridge, shore, transit, harbour, district, cliff, city-detail and class-size tests pass; `BUILD_VERSION` 308.
  Remaining tells for the human gate (README findings): Riddarholmen/Slussen banks are still flat pale slabs and the Slussen lock
  panes hard-edged, the Mariaberget face has no stair or houseboats, three moored ships are one repeated model, generic render walls
  read dark olive at Södermalm/Skeppsbron, the Sergels torg paving is buried at eye height and Kulturhuset is an opaque block, Strömbron is a
  bare deck, the Gustav II Adolf horse is a placeholder, specular glare at golden hour, moving water traffic and trams are not in
  the stills, and weak refs for Vasa/Nordiska fronts.
- [x] Code review — 2026-11-20, read-only agent review of every Stockholm change (findings in the session; fixed here): the
  Stockholm entries added since the realism pass are now `secondary` (aliases such as `fotografiska`, `3arena`, `stortorget`, `kulturhuset`
  only answer within `radius_m` of their site and never open as a place's primary; the 25 originals keep their behaviour and carry the city's
  Ultra budget 48 registry / 56 total, room for eight bridges, via `LandmarkRegistrySwedenStockholm`), `stockholm_hero_landmarks_test` resolves
  aliases at each entry's own coordinates and counts bridges by kind, the leaked scratchpad path and stale headers in the docs and `sto_reg_*` files
  are fixed, the dead placeholder floor is gone. `landmark_sites.gd` keeps the old caps for Fast, Balanced, High and every other city. Accepted
  risks: the shore/road palette statics are set per build (`_shore_aprons`, `_roads`), so concurrent builds of two cities could mix a sett colour;
  `hero tests` check only the first alias. Commit note: the Stockholm hunks share files with other work in this tree (`ground_material.gd`,
  `road_builder.gd`, `shore_apron.gd` call the untracked `FinnishGranite`; `location_data.gd` also carries Turku/Helsinki
  `ultra_registry_limit` lines; train/tram specs carry Helsinki hunks), so stage by hunk or land the Finnish classes first.

- [x] Round 7, open-issue pass — 2026-11-20, five parallel agents, captures and READMEs in `visual-plan/reviews/sto-r7-*-2026-11-20/`;
  `BUILD_VERSION` 312. All Stockholm-gated.
  - Banks and cliff: Riddarholmen island edge is mapped as ashlar quay wall with a dark waterline course and a setts strip
    (`stockholm_shore.gd`, `stockholm_quay.gd`), Slussen lock panes share one level with walled edges on a paved court, a granite stair
    on the Mariaberget face (`stockholm_cliff.gd`). Left: pale DEM ramps at building feet at a distance, no lock gates, a straight stair.
  - Ships and traffic: mapped hull-ships get varied liveries and the Mälaren steamer model (`malar_ships.gd`), the unmapped Söder quay gets
    a mixed fleet (`quay_fleet.gd`), Riddarfjärden and Saltsjön route boats, Djurgårdslinjen tram where no track is mapped
    (`vehicles/stockholm_tram.gd`). Left: route boats are placed with animated wakes, not driven; no mooring lines; no rails or wires on
    the synthetic tram line.
  - Walls and glare: Stockholm plaster palette (ochre, terracotta, rust, warm cream), softened stucco photo, specular cap on asphalt,
    paving, ground and glass, grey-brown bark. Left: the white Kungsholmen block, no timber house seen at Fjällgatan, cliff granite and
    quay stone still sparkle.
  - Landmarks: Sergels torg held level with visible triangle paving and translucent Kulturhuset glass, Strömbron with carriageway, balustrades,
    lamps and parapet piers (`orn` 8.7 in its spec row), Gustav II Adolf with a built horse and armoured king. Left: glass has no sky reflection,
    horse is faceted, neon is plausible lettering.
  - Evidence: Vasa and Nordiska exterior photos, Dramaten and Hötorg fronts replaced, `tests/stockholm_evidence_test.gd` checks every README
    row; heights re-checked against OSM, Wikidata and Wikipedia (no change; Sagerska, Arvfurstens, Dramaten, Waterfront and others stay
    photo-scaled and are listed as unverifiable); night frames of Hötorg and the Opera read.

- [x] Rounds 8-9, leftovers pass — 2026-11-20, `BUILD_VERSION` 314; combined Ultra frames in `visual-plan/reviews/sto-r10-final-2026-11-20/`,
  halo check in `sto-r12-halo-2026-11-20/`; windowed `world_cache_test` OK and `screenshot_test` exit 0, full headless sweep passes.
  Done: Riddarholmen plinth ground flattened, Slussen lock gates (`stockholm_locks.gd`), switchback Mariaberget stair, route boats that travel
  (`route_boat_driver.gd`), mooring lines and fenders, Djurgårdslinjen as embedded tram track, six distinct moored hull types
  (`malar_vessel_models.gd`), far curtain glass dulled (the white block was Norrmalm's far glass), Fjällgatan timber proven in render, glare cap pass
  for stone (`stockholm_glare.gd`), softer cliff granite and a warmer, less muted plaster palette, Kulturhuset sky-band glass, smoother Gustav II Adolf,
  Strömbron pier bands, ref photos fixed and undocumented files removed (`stockholm_evidence_test.gd` enforces it), `commons_refs.py` downloads via curl.
  Street-lamp halos (shared `street_lights.gd`, all cities) were big white discs at night: now a small faint gaussian bloom.
  Accepted residuals: granite plinth bevels (shared `ReliefKit.stone`, no city context) still catch the sun; Slussen lock gates sit dark under the
  water and the lock walls read as orange ashlar at golden hour; the horse is still faceted; two barques in the visible row; no sails on the barque;
  no frame shows the added Djurgårdslinjen track in the bundled snapshot world; Sagerska, Arvfurstens, Dramaten, Waterfront and eleven more heights
  have no source beyond OSM levels (derived estimates with error bars in `docs/stockholm-landmark-sources.md`); the "photographic" rating is a human gate.

- [x] Round 10, final residual pass — 2026-11-20, `BUILD_VERSION` 315; final combined Ultra frames in `visual-plan/reviews/sto-r14-final-2026-11-20/`,
  sweep of 40 headless tests plus windowed `world_cache_test` and `screenshot_test` (exit 0) at this version. Closed since the previous entry: lock gates
  readable with cooler grey ashlar and a granite sill (`sto-r13-slussen`), plinth bevel sparkle (the cause was the foundation plinth's snow shader,
  `sto-r13-plinth`), Gustav II Adolf as one smooth bronze skin (`sto_sdf_bronze.gd`, `sto-r13-statue`), barque with set sails and one barque per row, the added
  Djurgårdslinjen track shown on camera (`STOCKHOLM_TRAM_FORCE=1`, `sto-r13-ships`). Remaining, none fixable by code alone or deliberately left: the Slussen sill
  barely shows and one far pane keeps a sheer wall, the statue's anatomy is stout, the synthetic tram line is one track, 15 heights rest on derived estimates
  (no public source), and the "photographic" rating is a human gate.

- [x] Round 11, last residual pass and final verification — 2026-11-20, `BUILD_VERSION` 316; Slussen lock sill with battered, finer-coursed walls
  (`sto-r15-slussen`), Gustav II Adolf re-proportioned with a smooth bronze skin and a face (`sto-r15-statue`), Djurgårdslinjen as two tracks with heavier
  Stockholm wires and golden-hour and night tram frames (`sto-r15-tram`). Final run at 316 (`sto-r16-final-2026-11-20`): 40 headless tests, class-size, windowed
  `world_cache_test` OK and `screenshot_test` exit 0, night frame shows lamps as small points (halo fix holds). `stockholm_palette_test` compared Stockholm
  against Helsinki, which another change added to `FacadeComposer.SMOOTH_PLASTER_CITIES`; it now compares against Paris. Open by nature: one lock-island block keeps a
  sheer brown face, the tram wires stay thin under trees, 15 heights have no public source, and the "photographic" rating is a human gate.

- [x] Round 12, Slussen island caps — 2026-11-20, `BUILD_VERSION` 317 (`sto-r17-slussen`, final run `sto-r18-final-2026-11-20`): the brown sheer block
  on the lock island was a transition cap of the shore bank mesh, not a lock-pane wall; every hard wall and every cap up to 12 m in the Slussen box now gets
  the sill, stepped courses and fine cool ashlar (`stockholm_shore_test` asserts no sheer run over 2 m). Final run at 317: no test failed except two
  intermittent symptoms in Paris builds, neither reproducible: one `stockholm_shore_test` run logged two `SCRIPT ERROR` lines (Dictionary key `a`, Vector2 cast)
  and still reported ok, and one windowed `world_cache_test` run found the cached Paris world 44 nodes different from a fresh build. Eight shore-test runs
  under load and four `world_cache_test` runs alone were clean (the later three after the final edit). Root cause of the script errors found and fixed (round 13,
  `BUILD_VERSION` 318): the native `ShoreClassifier` read a shared `PackedByteArray` (`quayed`) from worker threads, whose copy-on-write raced and corrupted a
  segment dictionary; `quayed` is now a `std::vector<uint8_t>` copied in `setup()`, and `tests/shore_classifier_test.gd` repeats each native build 40 times
  against the script path (macOS libraries rebuilt; the Android and iOS libraries in `native/bin` still need a rebuild before they ship). The 44-node world-cache
  mismatch was not reproduced; it is most likely the same corruption in a second Paris build, and if it recurs the next suspects are the stage-level statics in
  `WorldBuildGraph`. Final run at 318 (`sto-r19-final-2026-11-20`): no failure, windowed `world_cache_test` OK and `screenshot_test` exit 0.

- [x] Accepted — 2026-11-20: the user accepted the Stockholm result as finished at `BUILD_VERSION` 318 (the human "photographic" gate). Left on record, not
  blocking: 15 landmark heights are derived estimates with no public source, the 44-node Paris `world_cache` mismatch was seen once and is probably the
  fixed shore-classifier race but is not confirmed, and the work is uncommitted.
- [x] Post-acceptance bridge regression fix — 2026-11-23, `BUILD_VERSION` 321: `sto_bridge_stromsbron.gd` pier `_bands` clamped to `y >= 0.0` (`BAND_H`) and balustrade/lamp tessellation trimmed below the 18,000 fitted-triangle ceiling; `bridge_specs_test`, `stockholm_bridges_test`, `stockholm_hero_landmarks_test`, and windowed `world_cache_test` / `screenshot_test` pass; `.agents/plans/2026-11-03-stockholm-hero.md` `B-8` synced (`native/bin/` macOS `.dylib`s rebuilt; Android/iOS cross-compile still required before mobile release).

## Context

Stockholm is rated "recognisable", not "photographic" (`docs/fidelity-scorecard.md` §9, rounds sto-r1…r4). The
November hero pass (`.agents/plans/2026-11-03-stockholm-hero.md`) added district fabrics, metal roofs, granite quays
and a batch of landmarks, but stopped at the human gate. An audit today found three reasons it still falls short:

1. **Landmarks are uneven.** 31 are built. About 14 are sourced, articulated models (Royal Palace, Storkyrkan, Katarina,
   Hedvig Eleonora, Globen, Kaknäs, Vasa, Nordiska, Stadsbiblioteket, Konserthuset, Riksdag, City Hall). About 13 are
   placeholders of 13–25 lines: Hötorgsskraporna (one glass box used five times), Opera, Grand Hôtel, Nationalmuseum,
   Riddarhuset (wrong roof: hip instead of its curved säteri roof), Wrangel, Bonde, Katarinahissen, Kastellet, Söder
   Torn, Klara, Sofia, Central Station. Most share `Palaces._block`, so they look alike.
2. **Many landmarks are missing**, including ones in the main views: Slussen/Guldbron, Stortorget, Skeppsbron row,
   Dramaten, Kulturhuset/Sergels torg, Kungstornen, Högalid, Engelbrekt, Stadion, Tele2 Arena, Waterfront, Norra
   Tornen. 7 of 8 Stockholm bridge rows are `conf: 1` and therefore never built.
3. **City-wide tells remain**: the Mariaberget cliff is flattened out of the terrain; the island banks are pale and
   angular; Norrmalm, Kungsholmen, central Södermalm and Djurgården have no district and all become ornate stone
   blocks with copper corner domes; no metro trains, Djurgården ferries or Waxholm boats; Stockholm lacks the raised
   detail budgets Helsinki, Espoo and Turku get.

There are also no reference photos in the tree (`visual-plan/refs/stockholm/` and the `sto-r*` review folders are
gone), so nothing can currently be checked against real life.

**Goal:** every Stockholm landmark is rebuilt or checked against real photos, the missing ones are added, and the city
around them stops giving the game away. "Photographic" stays a human rating; this plan gets every item to the point
where a side-by-side sheet against a real photo shows no wrong shape, missing signature feature or wrong material.

## Definition of done per landmark (the quality bar)

The bar is `landmark_fh_parliament.gd` (rebuilt from reference photos) and the Turku models
(`landmark_ft_samppalinna.gd`, `landmark_ft_paavo_nurmi.gd`). A landmark is done when all of these hold:

- **Refs:** 3+ Wikimedia Commons CC/PD photos (front, quarter, aerial; a night one where it is floodlit) in
  `visual-plan/refs/landmarks/<type>/` with a README row per file (URL, author, licence). No Russian hosts.
- **Measured:** OSM outline centroid, long-axis bearing, footprint size and height recorded in a new
  `docs/stockholm-landmark-sources.md` (format of `docs/turku-landmark-sources.md`); registry `lat/lon/yaw_deg/
  height_m/clear_*` corrected to match.
- **Spec header:** the builder file opens with a written facade spec (bay counts, storeys, roof form, materials,
  signature features) taken from the photos.
- **Model:** named sub-builders per element; repeated parts built once and `merge()`d; ≤ 16 surface keys; ≤ 150k
  triangles; correct roof form and material; real window rhythm; its signature features present (listed below).
- **Site:** stands on the right ground (`base`, `base_at_m`, `SEAT_META`), suppresses the mapped footprint cleanly
  (`clear_rect_m` / `model_rects_m`), no generic building poking through, forecourt or steps where the real one has
  them.
- **Night:** `FLOOD_META` rig or `"…Lamp"` keys where the real building is lit.
- **Evidence:** a `capture_landmarks.gd` four-view sheet plus `landmark_compare_sheets.py` page beside the refs, and
  one in-city `--looks` frame from open ground at eye height, both reviewed and free of the listed mismatches.

## Phases

### S-0 Baseline, refs and slots (do first; everything depends on it)

- **S-0.1 Baseline capture.** One background run each:
  `capture_landmarks.gd --types=<all 31 Stockholm types> --tag=sto_lm_base` (gives triangle counts in `stats.tsv`),
  and `capture_presets.gd --places=stockholm --preset=3 --audit --tag=sto-r5` with a `--looks` list of about ten
  open-space eyes (Monteliusvägen, Evert Taubes terrass, Strömbron, Skeppsbron quay, Stortorget, Sergels torg,
  Strandvägen quay, Slussen, Djurgårdsbron, Fjällgatan). River eyes use drone heights (memory
  `look-eye-height-over-water`).
- **S-0.2 Reference set.** Run `tools/landmark_ref_inventory.gd`; collect Commons photos for every existing and
  planned type; restore `visual-plan/refs/stockholm/` city refs (summer vantage, Gamla stan street, Strandvägen,
  Slussen, a night skyline). READMEs are tracked, JPGs are gitignored.
- **S-0.3 Sources doc.** `docs/stockholm-landmark-sources.md` with OSM way IDs and measurements for all types;
  sections in `docs/data-source-register.md` as for Riddarholmen (:547).
- **S-0.4 Landmark slots.** Ultra draws at most 26 registry extras (`LandmarkSites.MAX_BY_PRESET`, City Hall's
  `ultra_registry_limit` 26); Stockholm already has 31 and this plan adds about 30. Fix selection before adding:
  keep `skyline_priority` only for things truly on the skyline (spires, towers, Globen, Kaknäs, Västerbron), let
  low buildings (palaces, museums, squares) be chosen by distance from the eye, and measure the build-time and
  draw-call cost of raising the Stockholm cap. Update `stockholm_hero_landmarks_test.gd` to pin the new rule.
  Hötorgsskraporna become one grouped entry (pattern: Gröna Lund `clear_offsets_m`), freeing four slots.
- **S-0.5 Detail city.** Add `"stockholm"` to `CityDetail.CITIES` (`scripts/render/city_detail.gd:17`) after
  measuring cold time-to-view (target ≤ 150 s Ultra) and memory; this raises building caps and roofline detail.

### S-1 Rebuild the placeholders (highest visible gain)

One file per landmark under `scripts/generation/landmarks/sweden_stockholm/` (keeps every file far below 1000
lines); (`Palaces._block` is retired). Signature features to model:

| Type | Must show |
|---|---|
| `hotorg_1…5` | Five slabs with their five different curtain-wall patterns, blind end walls, rooftop plant, two-storey podium with the Sergelgången terraces and bridges. Use `SkyKit` so windows light at night. Verify height (registry 61 m vs published 72 m). |
| `royal_opera_stockholm` | Neo-baroque front: rusticated base, arched piano-nobile windows, giant pilasters, central risalit, attic balustrade with urns, copper roofs, fly tower, Operakällaren wing, Gustav Adolfs torg side. |
| `grand_hotel_stockholm` | Long quay front with awnings, copper mansard, central attic with flags, corner pavilions; the adjoining Bolinder palace as a separate mass. |
| `nationalmuseum_stockholm` | Stüler's Renaissance block: limestone, three-arch portal risalit, round-arched windows with medallions, corner pavilions, roof lanterns, quay stair. |
| `riddarhuset_stockholm` | Red brick with sandstone Corinthian pilasters and garlands, two-tier curved copper säteri roof with statues and chimneys, the two water-side pavilions, forecourt with the Gustav Vasa statue. |
| `wrangel_palace` | Two round towers to the water, the north tower with its conical roof, plastered ranges round a court. |
| `bonde_palace` | H-plan with wings to the street, pilasters and festoons, copper säteri roof. |
| `katarinahissen` | Lattice lift tower, glazed cab shaft, the long walkway to Mosebacke, Gondolen restaurant hung beneath it, KF-huset base. |
| `kastellet_stockholm` | Red-brick citadel on its granite knoll, round tower with battlements and flagpole, lower ranges. |
| `soder_torn` | Octagonal shaft with real storey rhythm, recessed top storeys and the openwork crown. |
| `klara_church`, `sofia_church_stockholm` | Klara: brick nave with traceried lancets, copper-clad spire stages checked against photos. Sofia: central-plan granite/brick with the correct dome-and-lantern crown and four corner turrets. |
| `tyska_kyrkan` | Add the ornate nave gables, south portal, gargoyles and copper spire detail; currently tower only. |
| `stockholm_central_station` | Replace the generic kit result with the real long Vasagatan front, central hall vault and the track sheds. |

### S-2 Bring the existing hero models to the bar

Checked against refs; only the differences are fixed.

- **City Hall** (`landmark_stockholm.gd`): Borgargården courtyard and its arcade, Blue Hall and Golden Hall window
  ranges, Birger Jarl cenotaph at the tower foot, the garden terrace with statues and the Engelbrekt column, the
  gilded sun and moon on the turret, floodlighting. Split the file if it nears the limit.
- **Riddarholmen church**: real traceried windows in place of flat glass boxes; add the island set as landmarks or
  fabric: Birger Jarls torn, the Norstedts building with its spire roof, Evert Taubes terrass.
- **Royal Palace, Storkyrkan, Riksdag, Nordiska, Vasa, Globen, Kaknäs, Katarina, Hedvig Eleonora, Library, Concert
  Hall, Västerbron, Gröna Lund**: ref comparison, then fix what differs. Known items: Gröna Lund has no park
  buildings and an approximate coaster profile; Västerbron needs its visual check, never done.

### S-3 Add the missing landmarks, in order of how often they are seen

- **Tier A (in the preset and waterfront views):** Slussen with Guldbron and Stadsmuseet; Stortorget (the gabled
  houses at nos. 18–22, Börshuset, the well; authored as a square like `landmark_ft_kauppatori.gd`); the Skeppsbron
  merchant-house row; Dramaten; Strömbron and Norrbro; Skeppsholmsbron with its gilded crown; af Chapman as an
  authored full-rigged ship (`TallShipDetails`, `base: "water"`); Skeppsholmen church and Moderna Museet;
  Stockholm Waterfront Congress; Kungstornen; Kulturhuset with Sergels torg (triangle paving, glass obelisk in the
  fountain); Rosenbad, Sagerska huset and Arvfurstens palats; Münchenbryggeriet; Högalidskyrkan (twin towers on
  the Södermalm skyline); Fotografiska.
- **Tier B (inner city, seen when moving):** Engelbrektskyrkan, Adolf Fredriks kyrka, Kungliga biblioteket,
  Stadion (1912), Skatteskrapan, Norra Tornen, Tele2 Arena (beside Globen), Skansen (Bredablick tower, Hazelius
  gate), Cirkus, Liljevalchs, ABBA museum, Waldemarsudde, Rosendal, Sjöhistoriska, Tekniska, Berwaldhallen,
  Viking Line and Värtahamnen terminals, Karl XII and Gustav II Adolf statues (`StatueBuilder`).
- **Tier C (outlying; only if the 12 km far layer reaches them):** Strawberry Arena, Victoria Tower, Kista Science
  Tower, Naturhistoriska, KTH, Stockholm University, Karolinska/NKS, Drottningholm. Arlanda is outside the Stockholm
  scene and is left out.

Each new one: registry entry in `landmark_registry_sweden_stockholm.gd`, dispatch arm in
`landmark_set_sweden_stockholm.gd`, own builder file, alias and height pinned in tests.

### S-4 Bridges

Source spans and structure for the seven `conf: 1` rows in `bridge_specs_north_europe.gd` (Centralbron,
Skeppsholmsbron, Danviksbron, Djurgårdsbron, Vasabron, Essingebron, Alviksbron) to reach `conf: 2` so
`BridgeParam` builds them; add rows for Årstabroarna (old arch viaduct and new red bridge), Skanstullsbron and
Johanneshovsbron, Sankt Eriksbron, Lidingöbron, Riksbron. Djurgårdsbron gets a bespoke model (the four Norse-god
columns and iron lamp standards) with `LandmarkBrKit`.

### S-5 The city around the landmarks

- **S-5.1 Södermalm cliffs.** Terrain comes from roof-contaminated Terrarium tiles, then `UrbanSmooth` flattens it.
  First choice: a Swedish bare-earth source in `GroundModel` if Lantmäteriet's open elevation data can be fetched
  without an account (the register's rule); otherwise a bundled inner-city height raster as for Helsinki; fallback:
  authored relief via `LandmarkTerrain.RELIEFS` and an `UrbanSmooth` exemption along mapped `natural=cliff`. Then
  re-seat the Monteliusvägen eye and close hero-plan B-3.
- **S-5.2 Shoreline.** Fix the pale angular banks (`shore_apron.gd:108-115` unknown-shore fallback); let
  `ShoreRailings` run on the non-tidal Mälaren hard edges (`shore_railings.gd:38`); granite skerry treatment for
  rocky shores (`rock_outcrops.gd`).
- **S-5.3 Fabric.** New district circles and rows: Norrmalm/Klara 1950s–60s modernism, Kungsholmen and Södermalm
  stone city without the 0.35 corner-dome chance, Djurgården villas and parkland, Gärdet funkis, Gamla stan roof
  variety (dormers, chimneys, black sheet metal). Fix the rules that turn every `house` into red timber and every
  1965–89 building into Million Programme panel (`building_era.gd:472-482`). Carry districts into the far field
  (`far_city_builder.gd:127`).
- **S-5.4 Water traffic.** Djurgården ferries and white Waxholm boats on their real routes (generalise
  `harbour_ferries.gd` beyond New York); Viking/Silja liveries at Stadsgården and Värtahamnen with a wider radius
  than 1.2 km (`quay_moorings.gd:11-15`); verify the Strandvägen steamboat row and Söder Mälarstrand houseboats.
- **S-5.5 Rail and street.** Tunnelbana trains on the above-ground sections (blue C20 look) in `train_specs.gd`;
  Tvärbanan and Lidingöbanan vehicles and the SL/Djurgården tram liveries in `tram_specs.gd`; T-bana entrance
  signs; red SL buses kept. Oak in the park mix for Djurgården, lime avenues in Kungsträdgården and Humlegården
  (`tree_species.gd`).
- **S-5.6 Data.** Re-cut the 2500 m road ring that hit the 800-road cap (`assets/osm_snapshots/README.md:55`).
- **S-5.7 Docs.** Update `docs/architecture-styles.md:105`, stale headers, and reconcile the shared tracker.

### S-6 Hero loop and sign-off

Capture rounds `sto-rN` (Ultra; golden, noon, night; one winter round) after each phase, a review README per round,
a scorecard line per round, and a final contact sheet of every landmark beside its reference for the human
"photographic" gate.

## Order and size

S-0 → S-1 → S-5.1/S-5.2 (they fix the preset frame) → S-2 → S-3 Tier A → S-4 → S-5.3–5.5 → S-3 Tier B → Tier C → S-6.
Roughly 60 landmark builds or rebuilds plus 12 bridges and six generic systems; each landmark is an independent
unit, so they can be done in batches of four or five with one capture run per batch.

## Critical files

- **Landmarks:** `scripts/data/landmark_registry_sweden_stockholm.gd`, `scripts/data/landmark_sites.gd`,
  `scripts/generation/landmarks/sweden_stockholm/*` (new file per landmark),
  `scripts/generation/landmark_stockholm.gd`, `landmarks/capital_stations/landmark_cs_central.gd`,
  `landmarks/bridges/*`, `scripts/data/bridges/bridge_specs_north_europe.gd`.
- **City:** `scripts/render/city_detail.gd`, `scripts/data/ground_model.gd`, `urban_smooth.gd`, `shore_apron.gd`,
  `shore_railings.gd`, `city_styles.gd`, `building_era.gd`, `architecture_cities_waterfront.gd` (split to
  `architecture_cities_stockholm.gd` near the limit), `harbour_ferries.gd`, `quay_moorings.gd`, `train_specs.gd`,
  `tram_specs.gd`, `tree_species.gd`, `scripts/data/preset_views.gd`.
- **Reuse, don't rewrite:** `LandmarkMesh` (`box`, `lathe`, `grid`, `merge`, `poly_prism`), `LandmarkDetail`
  (`column`, `colonnade`, `cornice`, `balustrade`, `pierced_face`, `arch`), `LandmarkKits.dome_on_drum`,
  `LandmarkFhParts` (`crow_gable`, `arcade`, `win_row`, `strips`, `slope_roof`), `LandmarkFrParts` (`dormer`,
  `chimney`, `roof_trim`), `LandmarkWestKit`, `LandmarkCoreBArchKit` (Gothic), `SkyKit` (lit tower facades),
  `LandmarkBrKit`, `LandmarkStationKit`, `StatueBuilder`, `PlazaLife`, `LandmarkLights.FLOOD_META`,
  `LandmarkTerrain.SEAT_META`, the three-church helpers in `landmark_ss_royal2.gd:46-200`.
- **Rules:** bump `WorldCache.BUILD_VERSION` per visual change (that file has uncommitted work of yours; touch only
  the constant); every file ≤ 1000 lines; UI text, if any, follows the design system; commit only when asked and
  only files this work edited.

## Verification

- **Per landmark batch (headless, background, via `tools/godot_bg.sh`):** `landmark_test`, `landmark_catalog_test`,
  `landmark_fidelity_test`, `landmark_placement_test`, `landmark_lights_test`, `stockholm_hero_landmarks_test`
  (extended: every Stockholm type, 1k–150k triangles, ≤ 16 parts, height ±1 m, nothing below ground),
  `gronalund_test`; `tools/check_class_size.sh`; `--import` after any new `class_name`.
- **Per city task:** `architecture_test`, `shoreline_test`, `bridge_arches_test` and the `bridge_*` tests,
  `street_lights_test`, `street_furniture_test`, `quay_moorings_test`, `marina_test`, `preset_views_test`, plus one
  new focused test per new behaviour (slot selection, Stockholm ferries, metro trains, new districts, cliff height
  at the preset eye).
- **Visual, batched, off-screen (`--position 4000,4000`, never on top):** `capture_landmarks.gd --types=… --tag=…`
  then `landmark_compare_sheets.py`; `capture_presets.gd --places=stockholm --preset=3 --looks=…` with eyes in open
  space only; any frame showing interior faces is discarded and the eye moved.
- **End:** windowed `world_cache_test` and `screenshot_test`, cold Ultra time-to-view ≤ 150 s measured on a quiet
  tree, disk space checked before each capture round. Skip the network tests (`tiles_test`, `exit_tile_test`,
  `dem_test`, `preset_snapshot_test`, `fidelity_scorecard_test`).

## Open decisions (recommendations in brackets)

1. Scope of new landmarks: Tier A+B, or Tier C too. [A and B; C only where the far layer already reaches.]
2. Landmark slot cap: raise Stockholm above 26 on Ultra or keep 26 with nearest-first selection. [Nearest-first
   first; raise only if measurement shows headroom.]
3. Cliff terrain source: national elevation data vs authored relief. [Try the open data; fall back to authored.]
