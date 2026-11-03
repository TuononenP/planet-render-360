# Landmark visual quality — shared tracker

> Follows the 2026-11-02 fidelity pass (commits a0ebff3, 9f2fb3e, 3d84150,
> 970b756): all 424 landmarks rebuilt from sources at >= 2x detail (median
> 5.9x), weathering shader on desktop Ultra, LandmarkDetail kit. Claim a task
> before starting it (`— @<agent>/<topic> <date>`), tick it only when its
> validation passes, and add one evidence line under it. Landmark files are
> `scripts/generation/landmark_*.gd`, `scripts/generation/landmarks/<batch>/`
> and `scripts/data/landmark_registry_*.gd`; class files stay <= 1000 lines.

## Done (2026-11-02 fidelity pass)

- [x] **L-0.1** Weathering shader: foot grime, rain streaks, ledge dirt, soffit occlusion, tone drift, anti-tiling, ashlar on limestone, metal runs (`LandmarkShader`, Ultra only)
  > `tests/landmark_shader_test.gd` OK; before/after sheets in session scratchpad.
- [x] **L-0.2** Rounded edges on every box >= 0.3 m (`LandmarkMesh.box` chamfer)
- [x] **L-0.3** Detail kit: columns, colonnades, cornices, balustrades, framed windows, recessed openings, arches (`LandmarkDetail`); richer domes, minarets, statues (`LandmarkKits`)
- [x] **L-0.4** All 424 landmarks and 10 archetypes rebuilt from published dimensions, >= 2x triangles each
  > Census: min 2.02x, median 5.9x, median 4.9k -> 31k tris, max 131k. Catalog OK except `riddarholmen` (see L-9.1).
- [x] **L-0.5** Registry heights and facings corrected from sources (commit 970b756)

## 1. Visual feedback loop (highest priority)

The rebuild agents could not render, so every model was judged by numbers only.

- [ ] **L-1.1** Reference images, 2 per landmark in `visual-plan/refs/landmarks/<type>/`: Commons photos (CC/PD only, author + licence in each folder's README) plus AI-made `ai_front.jpg` / `ai_quarter.jpg` from the user where no photo fits — @claude/loose-ends 2026-11-03 (partial)
  > Done: 406 Commons photos for 386 of 425 landmarks, each eyeballed (the Wikipedia lead image per landmark, a second photo for 37 of them); wrong-subject, detail-only, interior and engraving picks were dropped. AI-made `ai_front.jpg` from the user for 8 more (Chain Bridge, One WTC, Burj Al Arab, Chrysler, St Mary Axe, Sistine Chapel, Sheikh Zayed, Temppeliaukio; `SOURCE.md` each; Chrysler, Temppeliaukio, Sistine and Sheikh Zayed replaced by clearer second attempts). Missing: the 31 types in `visual-plan/refs/landmarks/MISSING.txt`. `visual-plan/refs/landmarks/README.md` has the status; `PROMPTS.md` has AI prompts with camera bearings for all 425 (`tools/landmark_ref_prompts.gd`).
  > No viewpoint (lat/lon/bearing) is recorded for Commons photos; judged by eye. L-1.3 should take real height/width from the registry and use images for silhouette and detail only.
  > Validation: every registry type has >= 1 image and a README entry.
- [ ] **L-1.2** (partial, @claude/loose-ends 2026-11-02: `tools/capture_landmarks.gd` shoots any landmark model from 4 bearings on a flat ground disc, `--all`, `--plain`, `--night`, writes sheets + `stats.tsv` (size, lowest y, tris) to `visual-plan/captures/<tag>/`; full run of all 425 models OK, no errors (`visual-plan/captures/all/`, `stats.tsv`); `tools/landmark_compare_sheets.py` builds reference-vs-render review pages (`captures/all/compare/page_NN.jpg`, 12 landmarks each). Still missing: ref-photo viewpoints and the real terrain) Capture tool: render each landmark from its ref viewpoint on the real terrain (Ultra, settled with `force_draw`, off-screen window), output side-by-side sheets
  > Validation: one windowed batch run produces sheets for all 424 without errors.
- [ ] **L-1.3** Silhouette score: segment the landmark in photo and render, compute IoU and a proportion check (height/width ratio, tower count)
  > Validation: scores land in a TSV; manual spot check of 20 agrees with the ranking.
- [ ] **L-1.4** Fix pass on the worst 50 by score, agents iterating with the capture tool until IoU improves
  > Validation: median IoU of the 50 rises; no landmark regresses; catalog test OK.

- [ ] **L-1.5** (user request 2026-11-03) Many landmarks read as too simple and not photorealistic, e.g. Buckingham Palace (a hollow box and a wall; the real facade has a central pavilion, Corinthian columns, the balcony, the Victoria Memorial and forecourt). Raise the plain-looking ones to photo level: more facade articulation and real materials (L-3), baked AO (L-2), forecourts (L-7). Candidates come from the L-1.4 review; Buckingham Palace first.
  > Validation: side-by-side with the reference reads as the same building at 200 m and 1 km; triangle budget stays within the catalog test.
- [ ] **L-1.6** (user request 2026-11-03) Extra accuracy for Angkor Wat: researched dimensions and layout (moat, west causeway with naga balustrades, cruciform terrace, west gopura, libraries, galleries, quincunx towers' true profile), courtyard and stone colours from photos.
  > Validation: dimensions listed in the code header with sources; side-by-side with the 2 Commons photos; `landmark_catalog_test` OK; `clear_m` covers the model.

## 2. Baked occlusion and ledge-aware weathering

- [ ] **L-2.1** Per-vertex ambient occlusion baked at build (hemisphere rays against the model's own merged mesh, cached per type)
  > Validation: arcade interiors, cornice undersides and courtyards visibly darker at 500 m+; build time per landmark < 50 ms.
- [ ] **L-2.2** Curvature/exposure channel: convex edges lighter (edge wear), concave darker
- [ ] **L-2.3** Rain streaks start under real ledges and sills (ledge mask from upward faces above, not noise)
  > Validation: streak origins line up with sills in close-up captures.
- [ ] **L-2.4** `LandmarkShader` reads the baked channels; lower tiers get the AO as a vertex-colour multiply
  > Validation: `landmark_shader_test` extended; Ultra/High captures compared.

## 3. Materials

- [ ] **L-3.1** New CC0 PBR sets (1K + 2K): marble (veined), granite, travertine, gold mosaic, glazed tile, copper sheet with seams, timber shingle
  > Validation: listed in `docs/data-source-register.md` with licence; calibration means added to `MaterialLibrary.PBR_SETS`.
- [ ] **L-3.2** Re-point landmarks to the right sets (granite columns, marble Taj/Lincoln, mosaic St Mark's, tiled Isfahan/Registan, copper roofs)
- [ ] **L-3.3** Landmark windows through the facade shader's interior mapping and night occupancy (replace flat `LandmarkMaterials.glass`)
  > Validation: night capture shows lit, varied windows on Westminster, Winter Palace, Empire State.

## 4. Hero sculpture assets

Procedural boxes and turned profiles stay crude for organic forms.

- [ ] **L-4.1** Authored meshes (Blender, `assets_src/blender/`, exported glb) for: Statue of Liberty, Christ the Redeemer, Leshan Buddha, Great Sphinx, Motherland Calls, Moai, Sydney Opera shells, Atomium, Lions (Chain Bridge, Lions Gate), quadrigas
  > Validation: each matches its ref silhouette (L-1.3 score) better than the procedural model; tri budget <= 40k each.
- [ ] **L-4.2** Loader path with procedural fallback (as `assets/eiffel.glb` does)

## 5. Level of detail and impostors

- [ ] **L-5.1** Two LODs per landmark (full, about 25%) chosen by screen size; phones and High tier use the lighter one up close
  > Validation: frame time on the heaviest site (Winter Palace, St Peter's) within the Ultra/High budgets; no pop at the switch distance in captures.
- [ ] **L-5.2** Baked octahedral impostor for skyline distances (> 3 km)
- [ ] **L-5.3** Re-spend the saved budget: raise detail on the 30 most-visited landmarks

## 6. Weather and season

- [ ] **L-6.1** Snow on landmark roofs, ledges and domes (reuse `RoofSnow` rules, slope-aware)
- [ ] **L-6.2** Rain: wet darkening, lower roughness, streaks stronger; puddles on forecourts
- [ ] **L-6.3** Climate-driven moss/lichen and dust (`ClimateModel`): green north faces in wet climates, dust in arid ones
  > Validation: weather captures (`capture_presets --weather`) for Helsinki winter, London rain, Cairo.

## 7. Site context

- [ ] **L-7.1** Forecourts from OSM: paving areas, steps, fountains, flagpoles, planters within the clear zone
- [ ] **L-7.2** Trees and lawns per site from OSM, people and benches at visitor sites
- [x] **L-7.3** Raise `clear_m` where models now exceed it (Brihadisvara, Canberra Parliament, Kerimäki) — @claude/loose-ends 2026-11-02
  > Measured model radius: Brihadisvara 233 m (clear 150 -> 235), Canberra 304 m (150 -> 305), Kerimäki 31.7 m (clear 47, already enough, unchanged). `landmark_catalog_test` OK.

## 8. Night lighting

- [ ] **L-8.1** Per-landmark lighting presets: Eiffel hourly sparkle, Empire State crown colours, floodlit domes, lit belfries, bridge cable lights
- [ ] **L-8.2** Light placement from the model (aim at towers and domes, not four generic spots)
  > Validation: `landmark_lights_test` extended; night captures for 10 presets.

## 9. Loose ends from the fidelity pass

- [x] **L-9.1** `riddarholmen` catalog failure: regional extra built by the core Stockholm class is not found by `is_bespoke` — @claude/loose-ends 2026-11-02
  > Test now skips the region-set check for `LocationData._regional_extras()` types (built by `LandmarkBuilder`'s own match). `landmark_catalog_test`: LANDMARK CATALOG OK, 425 landmarks.
- [ ] **L-9.2** Below-ground framing: Hoover Dam, Mont-Saint-Michel, Edinburgh Castle, Monks Mound ramp — @claude/loose-ends 2026-11-02 (partly done)
  > Census of all 425 models: only Hoover Dam (-221 m, crest at y=0), Mont-Saint-Michel (-45), Edinburgh (-60) and eight mosque/ruin sites (<= 3 m) dip below y=0; Monks Mound no longer does. MSM and Edinburgh are crag skirts meant to bury in the slope. Hoover: new registry key `base_drop_m` (221) lifts the model so the toe stands on the lowest ground (`TerrainBuilder._hero_y`, `LandmarkSites`); catalog test checks the key matches the model. Model-only capture (`tools/capture_landmarks.gd --types=hoover_dam`) shows the toe on the ground and the crest 221 m up. **Still not seen on the real DEM** (needs the Hoover coordinates run through the full app flow); tick after that.
- [ ] **L-9.3** Registry questions for the user (open, needs the user's answer; unchanged): Turku Cathedral 101 vs 86 m, Sydney Opera 65 vs 67 m, Uspenski bell tower 22 vs 40 m, Al-Aqsa 35 m (unsourced)
- [x] **L-9.4** Kit costs: lighter `LandmarkDetail.column`/`arch`/`balustrade` variants with a segment setting; `window` sill must not dip below its base — @claude/loose-ends 2026-11-02
  > `column(radial=20)`, `balustrade(radial=8)`, `arch(max_segs=25)` defaults reproduce the old geometry; `window` clamps sill and apron to y >= 0 on ground-floor windows. No caller switched to lighter settings yet (that belongs with L-5.1). Catalog, landmark, fidelity tests OK.
- [x] **L-9.5** Run the windowed screenshot tests (`tests/screenshot_test.gd`, `tests/world_cache_test.gd`) on the new models — @claude/loose-ends 2026-11-02
  > `world_cache_test` OK (cold 10.5 s, cached 1.4 s). `screenshot_test` exits 0 and writes its shots (no pass line is printed; shots not eyeballed). Both print the same exit-time leak warnings (7 texture RIDs, 3 objects), not compared against a pre-change run.
