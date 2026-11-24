# Amsterdam super-realistic: landmarks and city

> Tracker in the house style of `PLAN_Stockholm_super_realistic.md`, `PLAN_Singapore_super_realistic.md` and
> `PLAN_London_super_realistic.md`: claim a task, tick it only after its validation passes, add one evidence line.
> Status legend: `[x]` done and validated, `[~]` in progress, `[ ]` open.
> Grounded against the codebase and the decoded bundled snapshots (`assets/osm_snapshots/capital_nl_14237403_18488969_*.osmb`,
> centred on Singel / Torensluis `52.37403, 4.88969`). Nothing in this plan has been built yet. Every dimension not
> tagged "OSM" is a starting value from memory and must be verified in `AMS-0.4` / `AMS-0.6` before modelling.

## Tracker

- [x] AMS-0.1 Clock fix (CET UTC+1 for NL in `atmosphere_rig.gd:250`) — `solar_test.gd` `PASSED` (Amsterdam `+1.0`, London `0.0`).
- [x] AMS-0.2 Baseline & review captures — `visual-plan/reviews/amsterdam-r1-2026-11-24/` & `amsterdam-r2-2026-11-24/` (day, night, roofs, close looks) + `assets/preset_thumbs/amsterdam.jpg`.
- [x] AMS-0.3 Height & tag audit of `capital_nl_*_detailed.osmb` and `_far.osmb` — 66 unheighted central monuments & split `far` towers documented in `docs/amsterdam-landmark-sources.md`.
- [x] AMS-0.4 Site measurement pass — all 66 landmarks & 4 parametric bridges positioned and verified in `docs/amsterdam-landmark-sources.md`.
- [x] AMS-0.5 True-3D 3DBAG LoD2.2 + PDOK Actueel_orthoHR aerial roof colour bundle (`tools/prepare_amsterdam_lod2_meshes.py`, `scripts/data/rd_new.gd`, `turku_lod2_meshes.gd`, `lod2_mesh_builder.gd`) — 17,598 buildings / 9×1 km RD New cells (`17.62 MB` zstd), 10,468 LoD2.2 buildings rendered live in `amsterdam-r2`.
- [x] AMS-0.6 Sources doc `docs/amsterdam-landmark-sources.md` created.
- [x] AMS-0.7 Slot budget matching Stockholm (`ultra_registry_limit: 48 / ultra_total_limit: 56`) pinned in `tests/amsterdam_landmarks_test.gd` (`PASSED`).
- [x] AMS-1 Batch wiring (`landmark_registry_amsterdam.gd`, `scripts/data/amsterdam/ams_reg_*.gd`, `ams_tower_specs.gd`, `landmark_set_amsterdam.gd`, `landmark_ams_kit.gd`, `landmark_registries.gd`, `amsterdam_centraal` migrated) — `amsterdam_landmarks_test.gd` `66/66 OK`.
- [x] AMS-2.1–2.10 All 10 Central Foreground Icons (`ams_dam_ensemble.gd`, `ams_churches_towers.gd`, `ams_centraal_and_east.gd`: Royal Palace, Nieuwe Kerk, Nationaal Monument, De Bijenkorf, Magna Plaza, Westerkerk & 86 m Westertoren Imperial Crown, Beurs van Berlage, Oude Kerk, Munttoren, Zuiderkerk, Waag, Koepelkerk, Noorderkerk, De Krijtberg, full 3-shed Amsterdam Centraal rebuild, Sint-Nicolaasbasiliek, Schreierstoren, Montelbaanstoren, Scheepvaarthuis) — verified in `amsterdam-r1`/`r2`.
- [x] AMS-3.1–3.6 All Cultural, Waterfront, Outer Heritage & Skyline Icons (`ams_museumplein.gd`, `ams_amstel_and_east.gd`, `ams_ij_waterfront.gd`, `ams_tower_specs.gd`: Rijksmuseum, Van Gogh, Stedelijk Bathtub, Concertgebouw, Tuschinski, De Bazel, Stadsschouwburg, Heineken, Vondelkerk, Stopera, H'ART, Carré, Amstel Hotel, Portugese Synagoge, Tropenmuseum, Molen De Gooyer, NEMO, Scheepvaartmuseum + VOC *Amsterdam*, EYE, A'DAM Toren, Muziekgebouw/Bimhuis, OBA, Het Schip, Pontsteiger, Silodam, Gashouder, Olympisch Stadion, Johan Cruijff ArenA, 15 Amstel/Omval & Zuidas skyline towers).
- [x] AMS-4.1–4.3 Bridges: bespoke `ams_bridges.gd` (Magere Brug + 1,200 night fairy lights, Blauwbrug + Imperial Crowns, Torensluis, Python Bridge), 4 `conf: 2` `BridgeSpecsWestEurope` rows (Berlagebrug, Jan Schaeferbrug, Hogesluis, Torontobrug), and `amsterdam_canal_bridges.gd` (brick arched canal bridges + arch fairy lights) — `bridge_specs_test.gd` `PASSED`.
- [x] AMS-5.1–5.4 City fabric & detail budget: 16 Amsterdam districts (`city_styles.gd`), `amsterdam_houseboats.gd` (472 mapped *woonarken* & *woonschepen*), `"amsterdam"` added to `CityDetail.CITIES` (`VERSION 7`, 14,000 Ultra buildings / 900 m detail ring, `0` impostors in `amsterdam-r2`), `PresetViews` Dam Square vantage + `PlaceCard.SKY_FOR["Amsterdam"]` — `city_detail_test.gd`, `preset_views_test.gd`, `architecture_test.gd` `PASSED`.
- [x] AMS-6.1–6.3 Canals, water, vessels & trees: dark olive-green Amsterdam canal palette (`water_surface.gd`), brick canal quay walls + *rondvaartboten* & GVB IJ ferries (`amsterdam_waterfront.gd`), Dutch elm & lime canal `tree_mix` (`heritage_zones.gd`, `tree_species.gd`) — `coastal_water_test.gd` `PASSED`.
- [x] AMS-7.1–7.2 Streets, transit & street life: Dutch *klinker* paving (`road_builder.gd`), GVB blue-and-white trams (`tram_specs.gd`), NS yellow-and-blue trains (`train_specs.gd`), parked Dutch bicycle rows & Bloemenmarkt (`amsterdam_street_life.gd`) — `tram_test.gd`, `train_test.gd` `PASSED`.
- [x] AMS-8 Night lighting: Royal Palace `FLOOD_META` Dam Square uplights, canal-bridge arch *brugverlichting*, Magere Brug fairy-light outline, `*Lamp` crowns & night-only houseboat/canal-boat windows — `landmark_lights_test.gd` `PASSED`.
- [x] AMS-9 & Code review: `tools/check_class_size.sh` OK (`996/1000`), all headless suites & `host_policy_test.gd` `PASSED`, zero script errors in `amsterdam-r2`, no AI attribution.

## Context

Amsterdam's capital view is centred on Singel beside Torensluis (`52.37403, 4.88969`, `scripts/data/capital_catalog.gd:17`),
just 56 m north-west of Magna Plaza, 149 m north-west of the Royal Palace on Dam Square, 407 m east of Westerkerk, and
925 m south-west of Amsterdam Centraal. `tools/capture_presets.gd:89` also has a test coordinate slightly south on Singel
(`52.3717, 4.8897`), and `scripts/data/preset_views.gd` has no Amsterdam preset vantage yet.

Amsterdam already benefits from three strong foundations in the engine:
- **0.5 m national DTM** (`GroundModel` AHN CC0, `docs/data-source-register.md:676`: roads at 0.5 m RMS).
- **Dutch gable relief basics** (`architecture_cities_europe.gd:176-227`, `street_front.gd:15-16`): dark Dutch brick,
  white sashes, step/neck/bell gables with hoist beams and stoops, plus `amsterdam_school` and `amsterdam_modern` rows.
- **NL street-furniture family** (`street_furniture.gd:66-78`): red-brown bollards (*Amsterdammertjes*).

### What the codebase and snapshot audit found

Measured against the decoded bundled snapshots (`assets/osm_snapshots/capital_nl_14237403_18488969_*.osmb`):

1. **Only one hand-built landmark exists in the entire city — and it is a 24-line stub:**
   - `amsterdam_centraal` (`scripts/generation/landmarks/capital_stations/landmark_cs_west.gd:51-74`, registered as
     `secondary: true` in `landmark_registry_capital_stations.gd:21-25`): red brick range, twin towers, stepped gable,
     two train sheds. Missing: the third (2015 glass IJ-side) canopy, the east Royal Pavilion, detailed Cuypers dormers,
     stone relief gables, clock/wind-vane faces, and night lighting.
   - **Not modelled at all:** Koninklijk Paleis (149 m from centre!), De Nieuwe Kerk (136 m), Magna Plaza (56 m!),
     Nationaal Monument & De Bijenkorf (303–320 m), Westerkerk & 87 m Westertoren (407 m), Beurs van Berlage (462 m),
     Oude Kerk (570 m), Koepelkerk, Noorderkerk, Waag, Zuiderkerk, Munttoren, Sint-Nicolaasbasiliek, Montelbaanstoren,
     Scheepvaarthuis, Stopera, Rijksmuseum, Van Gogh Museum, Stedelijk Museum, Concertgebouw, NEMO, Scheepvaartmuseum,
     EYE Filmmuseum, A'DAM Toren, Het Schip, Pontsteiger, Molen De Gooyer, and every Amstel/Zuidas tower.
2. **Zero bridges are built — despite 499 mapped bridges in `detailed`:**
   - Only two Amsterdam rows exist in `scripts/data/bridges/bridge_specs_west_europe.gd`: `br_amsterdam_magere_brug`
     (line 407) and `br_amsterdam_python_bridge` (line 323). Both are **`conf: 1`**, so `BridgeParam` skips both!
   - Blauwbrug, Torensluis (56 m from the view centre!), Berlagebrug, Jan Schaeferbrug, Hogesluis and Torontobrug have
     no row at all.
   - `BridgeArches.MIN_WET_M := 45.0` (`scripts/generation/bridge_arches.gd:17`) skips every single narrow 12–30 m
     Amsterdam canal bridge, leaving all ~400+ historic Grachtengordel bridges as flat grey concrete slabs (`#a39d92`).
3. **Bundled OSM snapshot statistics (`capital_nl_14237403_18488969_*.osmb`, centred `52.37403, 4.88969`):**
   - `detailed.osmb`: 21,266 elements — **12,811 buildings** (**10,925 [85.3 %]** have explicit BAG `height`, **12,271
     [95.8 %]** have `start_date`, 399 `roof:shape`, 20 `building:colour`), 477 `building:part`s, 4,113 highways (incl.
     **411 `cycleway`**), 563 waterways, 793 railways (**327 `tram`**, **308 `rail`**, 30 `subway`), **1,408 trees**
     (only 23 with species/genus tags, mostly *Ulmus hollandica* & *Platanus*), **499 bridges**, and **472–475 mapped
     `building=houseboat`** elements!
   - `far.osmb`: 8,243 elements — 287 buildings, **7,252 `building:part`s** (covering Museumplein parts, NEMO, A'DAM
     Toren, Rembrandttoren, Mondriaantoren, Breitnertoren, Amstel Tower, Okura, WTC/Zuidas parts, Johan Cruijff ArenA).
   - **Ring cap hits:** `ring2500.osmb` (`hw=800, ww=150`) hit the 800-highway and 150-waterway caps; `ring1600.osmb`
     (`hw=612, ww=150`) hit the 150-waterway cap.
4. **Building budget starves Amsterdam's dense canal fabric:**
   - `"amsterdam"` is **not** in `CityDetail.CITIES` (`scripts/render/city_detail.gd:18`). Desktop Ultra caps real
     buildings at 10,000 (`render_settings.gd:183`), pushing **2,811 real canal houses** to impostors; High caps at
     2,500 (pushing 10,311 to impostors!), and gable/stoop relief stops at 300 m instead of 900 m.
5. **66 named central buildings have no `height` tag in `detailed`:**
   - Because BAG imports sometimes skip monumental buildings, `Koninklijk Paleis` (`lv=5`), `Magna Plaza` (`lv=3`),
     `Nationaal Monument` (`lv=-`), `De Bijenkorf` (`lv=6`), `Westertoren` (`lv=-`), `Beurs van Berlage` (`lv=2`!),
     `Koepelkerk`, `Oude Kerk`, `Noorderkerk`, `Waag`, `Munttoren`, `Sint-Nicolaasbasiliek` (`lv=3`), `Centraal Station`
     (`lv=1`), `Stopera`, `Montelbaanstoren` and `Stadsschouwburg` all lack explicit `height` in OSM.
6. **472 mapped canal houseboats render as brick apartment boxes:**
   - `building_builder.gd:426` lists `"houseboat"` in `WATER_OK_KINDS` so they are not culled as water overlaps, which
     causes all 472 canal *woonboten* to extrude through generic Amsterdam brick-house rules straight out of the water.
7. **Iconic Amsterdam street, transit & water cues are missing:**
   - **No red cycleways:** 411 mapped `highway=cycleway` ways render as generic grey (`RoadBuilder.FINISH_HEX`).
   - **No GVB trams or NS trains:** `TramSpecs.pick` (`tram_specs.gd:190`) and `TrainSpecs` have no `"amsterdam"` / `NL`
     branch, so 327 tramways and 308 rail ways use generic liveries instead of GVB blue-and-white trams and NS
     yellow-and-blue EMUs.
   - **No canal water palette or Amsterdam vessels:** `water_surface.gd:81-99` has no Amsterdam box; no *rondvaartboten*
     (glass-roofed canal boats), no GVB IJ ferries, no moored *sloepen*, and no brick canal quay walls.
   - **No bicycle street life:** zero parked Dutch bicycles along canal bridge railings or racks.
   - **Pre-weather clock is 1 hour off:** `atmosphere_rig.gd:250` computes `roundf(4.88969 / 15.0) = 0` (UTC+0) instead
     of CET (`UTC+1`), shifting golden hour and dusk by an hour before weather responds.
8. **Slot budget & primary landmark:**
   - Amsterdam has no primary landmark in `location_data.gd` and no `ultra_registry_limit` boost, capping Ultra at the
     default 22 extras + 4 bridges — far too tight for a city with ~40 historic monuments + 8 notable bridges.

**Goal:** from Singel/Torensluis, Dam Square, any Grachtengordel bridge, Centraal/IJ waterfront, the Amstel, Museumplein,
Oosterdok, Overhoeks and Zuidas, a person who knows Amsterdam recognises every landmark and church spire by silhouette,
brick/sandstone/copper material and night look — and the gabled canal houses, brick arched bridges with fairy lights,
houseboats, Dutch elms, red cycleways, parked bikes, blue-and-white GVB trams and dark reflective canals unmistakably
read as Amsterdam.

## Ground rules

- **Measured, not remembered.** Site, footprint, axis and height come from OSM (bundled snapshot or `AMS-0.4` Overpass
  pass), architectural dimensions from Rijksmonumentenregister / Wikipedia / architect data, and appearance from
  Wikimedia Commons reference photos.
- **Catalog limits per landmark** (`tests/landmark_catalog_test.gd`): 2 to 16 merged surfaces, at most 150,000
  triangles, textured materials only, top within `max(2 m, 3 %)` of `height_m`.
- **Class size:** every `.gd` file under `scripts/` stays at or under 1,000 lines (`tools/check_class_size.sh`). Split
  complex landmarks and registries into focused files (`scripts/data/amsterdam/ams_reg_*.gd`, one builder per major
  landmark or tight historic group).
- **Existing work & minimal edits:** keep `amsterdam_centraal`'s type ID and aliases intact so existing tests and docs
  keep working. Re-read any shared file before editing (there are open local changes on `building_builder.gd`,
  `building_detail.gd`, `roofline_detail.gd`, `shore_railings.gd`, `city_detail_test.gd`, etc.); prefer new
  Amsterdam-specific modules over growing shared files. Commit only when explicitly asked; never add AI attribution.
- **Hosts:** never contact Russian-operated services or domains (`HostPolicy` / `tests/host_policy_test.gd`). Overpass
  through `openstreetmap.fr` or `kumi` mirrors; reference photos from Wikimedia Commons only.
- **Godot runs:** always through `tools/godot_bg.sh` (never the `.app` binary directly, never `GODOT_FOREGROUND=1`).
  Tests headless in the background; captures windowed in the background with `--position 4000,4000 --preset=3`, never
  `--always-on-top`.
- **Capture eyes:** every eye stands in open space (square, canal quay, bridge deck, or elevated drone over a canal/IJ —
  note `--looks` height over water is measured from the riverbed). Discard and move any frame showing interior faces,
  cut walls or floating geometry.

## Verified site data

Measured from `capital_nl_14237403_18488969_detailed.osmb` and `_far.osmb` relative to the capital centre (`52.37403,
4.88969`). "OSM h" is the literal `height` tag (`-` means absent). Real heights in the last column are starting values to
verify in `AMS-0.4` / `AMS-0.6`.

| Site | OSM element | Distance / bearing | Footprint bbox | OSM h / lv | Status today | Real height (to verify) |
| --- | --- | --- | --- | --- | --- | --- |
| Torensluis | `way 7371422` (deck) | 56 m / 360° | 42 × 28 m | — | Flat slab | Brick 3-arch bridge + terrace |
| Magna Plaza | `way 57861220` | 56 m / 138° | 55 × 81 m | - / 3 lv | **Under-height box** | ~38 m turrets / 24 m eaves |
| De Nieuwe Kerk | `way 747911438` (part) | 136 m / 100° | 72 × 48 m | 15 m / - | **Low generic part** | ~60 m crossing spire |
| Koninklijk Paleis | `rel 3580875` | 149 m / 130° | 66 × 82 m | - / 5 lv | **Missing height** | 51.75 m cupola weathervane |
| Huis Bartolotti | `way 174193863` | 202 m / 271° | 30 × 12 m | 21.8 m / - | Generic canal row | 21.8 m Dutch Renaissance |
| Nationaal Monument | `way 168680619` | 303 m / 116° | 37 × 37 m | - / - | **Missing height** | 22 m travertine pylon |
| De Bijenkorf | `way 23582490` | 320 m / 98° | 101 × 103 m | - / 6 lv | **Missing height** | ~34 m corner towers |
| Westerkerk & Westertoren | `ways 99205257, 99203577` | 407 m / 278° | 60 × 46 m + 12 × 12 m | 35.2 m / `-` | **Tower unheighted** | **85–87 m** Imperial Crown |
| Beurs van Berlage | `way 57858502` | 462 m / 76° | 129 × 136 m | - / **2 lv** | **Severely under-height** | 40 m clock tower / 25 m halls |
| Koepelkerk (Ronde Lutherse) | `way 22100190` | 518 m / 33° | 39 × 47 m | - / - | **Missing height** | ~36 m copper dome |
| Oude Kerk | `way 57857592` | 570 m / 86° | 82 × 64 m | - / - | **Missing height** | **67 m** Baroque spire |
| De Krijtberg | near `way 74041978` | 585 m / 192° | to verify | - / - | Generic church | ~53 m twin spires |
| Noorderkerk | `way 220961710` | 662 m / 340° | 40 × 47 m | - / - | **Missing height** | ~34 m central lantern |
| Waag (Nieuwmarkt) | `way 57857390` | 735 m / 101° | 26 × 30 m | - / - | **Missing height** | ~28 m central turret |
| Zuiderkerk | `way 114120359` | 800 m / 121° | 47 × 51 m | 61.2 m / - | Generic extrusion | **61.2 m** sandstone spire |
| Munttoren | `way 57862728` | 811 m / 163° | 8 × 7 m | - / - | **Missing height** | ~40 m open lantern spire |
| Sint-Nicolaasbasiliek | `way 174996833` | 822 m / 71° | 44 × 55 m | - / 3 lv | **Under-height box** | **58 m** green copper dome |
| Schreierstoren | `way 57859248` | 890 m / 73° | 13 × 24 m | 20 m / 3 lv | Generic box | ~20 m round brick tower |
| Pathé Tuschinski | `ways 267116754, 267116768` | 901 m / 159° | 48 × 66 m | 38.2 m / - | Generic box | ~36 m Art Deco turrets |
| Amsterdam Centraal | `way 57856845` + `451533147` | 925 m / 53° | 368 × 362 m | - / 1 lv | **24-line stub** | **45 m** twin towers, 3 sheds |
| Scheepvaarthuis (Amrâth) | `way 57863677` | 981 m / 88° | 65 × 100 m | 30 m / - | Generic box | ~35 m ship-prow roof |
| Stopera (Opera & Ballet) | `ways 268782345, 751591420` | 1,058 m / 132° | 122 × 133 m | - / - | **Missing height** | ~28 m curved marble drum |
| De Bazel | `way 114542356` | 1,065 m / 171° | 50 × 107 m | 37.5 m / 10 lv | Generic extrusion | 37.5 m banded granite/brick |
| Montelbaanstoren | `way 57864086` | 1,106 m / 102° | 12 × 12 m | - / - | **Missing height** | **48 m** clock spire |
| Blauwbrug | `ways 38322374, 773860192` | 1,146 m / 138° | 45 × 19 m | — | Flat slab | 3-arch stone/iron crown bridge |
| Paleis van Justitie (IJdock) | `way 174454540` | 1,152 m / 18° | 66 × 68 m | 42 m / - | Generic extrusion | 42 m contemporary glass/brick |
| Stadsschouwburg | `way 57863115` | 1,197 m / 206° | 79 × 105 m | - / - | **Missing height** | ~28 m neo-Renaissance theatre |
| A'DAM Toren | `way 44824385` (far) | 1,395 m / 38° | 52 × 61 m | 79 m / - | Far extrusion | **100 m** to rooftop crown |
| NEMO Science Museum | `ways 1390692763, 1390692772` (far) | 1,537 m / 89° | 42 × 76 m | 26.5 m / - | Far parts | ~32 m green copper ship prow |
| Rijksmuseum | `way 517791046` (far part) | 1,589 m / 191° | to measure | 7 m (pavilion) | **Main hall absent** | **~60 m** twin towers, 150 m front |
| Muziekgebouw & Bimhuis | `ways 755464129, 755504271` (far) | 1,653 m / 73° | 112 × 79 m | 24 m / - | Far extrusion | 24 m + cantilevered black box |
| Van Gogh Museum | `ways 754324684, 754324681` (far) | 1,832 m / 199° | 38 × 36 m | 18 m / - | Far parts | ~20 m Rietveld + Kurokawa |
| Stedelijk Museum | `ways 754299898, 754299888` (far) | 1,904 m / 201° | 48 × 58 m | 14 m / - | Far parts | ~22 m brick + white Bathtub |
| Het Concertgebouw | `ways 754269603, 754269611` (far) | 2,102 m / 200° | 75 × 69 m | 24 m / - | Far parts | ~26 m pediment + gold lyre |
| Tropenmuseum | `ways 750932751, 750932747` (far) | 2,560 m / 119° | 20 × 24 m (parts) | 27 m / 3 lv | Far parts | ~48 m octagonal tower |
| Hotel Okura | `way 753577537` (far) | 2,809 m / 174° | 36 × 31 m | 78 m / - | Far extrusion | 78 m slab tower |
| Rembrandttoren | `ways 754399963–754399973` (far) | 3,713 m / 150° | 46 × 46 m | 150 m (spire) | Far parts | **150 m** (135 m roof) |
| Amstel Tower | `ways 1302940796, 603451493` (far) | 3,724 m / 148° | 58 × 53 m | 75 / 6 m (30 lv) | **Split height** | **103 m** |
| Breitnertoren | `way 754399978` (far) | 3,766 m / 151° | 21 × 34 m | 93 m / 25 lv | Far extrusion | 95 m |
| Mondriaantoren | `way 754399960` (far) | 3,834 m / 150° | 31 × 24 m | 115 m / 31 lv | Far extrusion | **123 m** |
| WTC Amsterdam (Zuidas) | `ways 754856619, 754856620` (far) | 3,935 m / 197° | 34 × 23 m | 98 / 96 m | Far parts | 105 m |
| New Amsterdam / Valley / ITO | `way 108894129` + `754717737` (far) | 4,207–4,251 m / 195° | 61 × 67 m | 92 / 24 m | Partial far | 92–105 m Zuidas cluster |
| Johan Cruijff ArenA | `rel 1458682` (far) | 7,523 m / 152° | 229 × 236 m | 75 m / - | Far extrusion | 75 m arched truss roof |

**To measure via live Overpass in `AMS-0.4` (outside `detailed` or incomplete in `far`):**
Rijksmuseum full footprint & passage axis, Van Gogh / Stedelijk / Concertgebouw full outlines, EYE Filmmuseum,
Het Scheepvaartmuseum + *Amsterdam* berth, OBA Oosterdok, Magere Brug (exact span, width & piers), H'ART / Amstelhof,
Koninklijk Theater Carré, Amstel Hotel, Portugese Synagoge, American Hotel, Heineken Experience, Vondelkerk, Molen De
Gooyer, Het Schip, Pontsteiger, Silodam, Gashouder (Westergas), Olympisch Stadion, Zuidas towers (Valley, Symphony
Towers, Viñoly, ABN AMRO HQ, The Rock), Pythonbrug, Jan Schaeferbrug, Berlagebrug, Hogesluis, Torontobrug and
Nieuwe Amstelbrug.

## Selection and slots

Following Stockholm (`LandmarkRegistrySwedenStockholm`: `48 / 56`) and London (`big_ben`: `42 / 50`), designate
Amsterdam's primary anchors (`royal_palace_amsterdam`, `westerkerk`, `amsterdam_centraal`, `rijksmuseum`) with
**`ultra_registry_limit: 46, ultra_total_limit: 54`**. That gives Ultra room for **46 bespoke landmarks + 8 bridges**
without either starving the other, while Fast/Balanced/High stay cleanly ranked via `skyline_priority` and nearest-first
tie-breaking (`LandmarkSites.select`, `scripts/data/landmark_sites.gd:39`). Skyline towers (`AmsTowerSpecs`) use the
separate `skyline: true` channel (12/30/60/110 per preset) and consume zero landmark slots.

| Tier | `skyline_priority` | Rows | First preset that shows them |
| --- | --- | --- | --- |
| 1 | 9 | Koninklijk Paleis (primary), Westerkerk & Westertoren, Amsterdam Centraal, De Nieuwe Kerk, Magna Plaza, Oude Kerk, Rijksmuseum | Fast (primary + 6) |
| 2 | 7 | Beurs van Berlage, Nationaal Monument & Dam Square, Sint-Nicolaasbasiliek, Zuiderkerk, Munttoren, NEMO Science Museum | Balanced (12) |
| 3 | 5 | Waag, Koepelkerk, Montelbaanstoren, Scheepvaarthuis, Stopera, EYE Filmmuseum & A'DAM Toren | High (18) |
| 4 | 3 | Noorderkerk, De Krijtberg, Schreierstoren, De Bazel, Pathé Tuschinski, Stadsschouwburg & American Hotel, Het Scheepvaartmuseum + VOC *Amsterdam*, Muziekgebouw & Bimhuis, OBA Oosterdok, Van Gogh Museum, Stedelijk Museum, Het Concertgebouw, H'ART / Amstelhof, Koninklijk Theater Carré, Amstel Hotel, Portugese Synagoge, Heineken Experience, Vondelkerk, Molen De Gooyer, Tropenmuseum, Het Schip, Pontsteiger, Silodam, Gashouder, Olympisch Stadion, Johan Cruijff ArenA | Ultra (up to 46) |
| Bridges | 7 / 5 / 3 | Bespoke: Magere Brug, Blauwbrug, Torensluis, Pythonbrug (`clear_path_m` / `span_m`); Parametric `conf: 2`: Berlagebrug, Jan Schaeferbrug, Hogesluis, Torontobrug, Nieuwe Amstelbrug, Nesciobrug | 2 / 4 / 6 / 8 bridge slots |

Notes:
- Generic historic canal bridges (~400+ in Grachtengordel/Jordaan) are styled by `amsterdam_canal_bridges.gd` (pattern
  `bangkok_canal_bridges.gd`) and take **zero** landmark or bridge slots.
- Every outer icon (Museumplein, Oosterdok, Overhoeks, Amstel, Harbour) carries `radius_m >= 4500.0` (6,500–9,000 m for
  Zuidas/Omval/ArenA) so it enters candidacy from the capital centre view as well as close-up walks.

## Phase 0: foundations

- **AMS-0.1 Clock fix.** `scripts/render/atmosphere_rig.gd:250` guesses `roundf(lon / 15.0)`, which yields `UTC+0` for
  Amsterdam (`4.89° E`) instead of `CET` (`UTC+1`). Add a lightweight per-country/box pre-weather offset override
  consulted before the longitude guess (`NL`/`BE`/`LU`/`FR`/`ES` +1, `SG` +8 — weather service's live offset still wins
  once loaded). Pin Amsterdam `+1` in `tests/solar_test.gd`.
- **AMS-0.2 Baseline r0.** Capture Set A (bundled centre `--keep_centre`) and Set B (close looks) at `--preset=3` into
  `visual-plan/reviews/amsterdam-r0-<date>/`, plus `tools/capture_landmarks.gd --types=amsterdam_centraal` (day &
  `--night`) for the pre-upgrade model sheet and `stats.tsv` baseline. Record any candidate eyes that needed adjustment.
- **AMS-0.3 Height & tag audit.** Run a scratch audit over `capital_nl_14237403_18488969_detailed.osmb` and `_far.osmb`
  listing all 66 named `detailed` buildings missing `height` and any `far` towers with split/contradictory part heights
  (e.g. `Amstel Tower` way 603451493 `h=6, lv=30` vs way 1302940796 `h=75`). Record the full table in
  `docs/amsterdam-landmark-sources.md`. Note whether `ring1600`/`ring2500` cap hits cause visible road/canal gaps in r0
  (snapshot re-cut deferred unless r0 shows missing outer canals).
- **AMS-0.4 Live Overpass measurement pass.** One script querying `openstreetmap.fr` or `kumi` mirror for every site in
  the "To measure" list above. Record OSM ID, area centroid, long-axis yaw (`yaw_deg`), bbox, `height`, and
  `building:part` hierarchy; save raw JSON beside sources inputs (not bundled).
- **AMS-0.5 Reference photos.** Create `tools/amsterdam_commons_refs.py` (pattern `tools/miami_commons_refs.py` /
  `tools/commons_refs.py`) fetching Wikimedia Commons front, quarter, aerial and night views (CC BY, CC BY-SA, CC0 or
  PD only) into `visual-plan/refs/landmarks/<type>/` with README licence tables, plus city-wide street/canal refs in
  `visual-plan/refs/amsterdam/` (Herengracht/Keizersgracht gables, Brouwersgracht, Dam Square, Reguliersgracht Seven
  Bridges day & night, houseboats, red cycleway, GVB tram, NS train, Amsterdammertjes, Bloemenmarkt). Review contact
  sheets and discard off-subject results.
- **AMS-0.6 Sources doc.** Create `docs/amsterdam-landmark-sources.md` (format of `docs/london-landmark-sources.md`)
  with verified OSM IDs, coordinates, yaws, real heights, key proportions, and Commons links. Append an Amsterdam
  section to `docs/data-source-register.md`.
- **AMS-0.7 Slot & placement test.** Pin the tier selection table, `46 / 54` Ultra limits, primary anchors, and ranked
  bridges in `tests/amsterdam_landmarks_test.gd` (created in `AMS-1`).

## Phase 1: batch wiring (AMS-1)

New files following London (`landmark_registry_london.gd`, `landmark_set_london.gd`) and Stockholm (`scripts/data/stockholm/`):

- `scripts/data/landmark_registry_amsterdam.gd` aggregating split sub-registries under `scripts/data/amsterdam/`:
  - `ams_reg_centre.gd` (Dam Square, Canal Ring, Centraal, historic towers & churches)
  - `ams_reg_culture.gd` (Museumplein, South Canal Ring, Amstel, Jewish Quarter)
  - `ams_reg_waterfront.gd` (IJ, Oosterdok, Overhoeks, Harbour, Stadiums, bespoke bridges)
  - `ams_tower_specs.gd` (`AmsTowerSpecs`, pattern `LnTowerSpecs` / `NycTowerSpecs`: `skyline: true` rows for Omval,
    Zuidas, Overhoeks/IJdock)
- `scripts/generation/landmarks/amsterdam/landmark_set_amsterdam.gd` (`LandmarkSetAmsterdam.build`, returning `false`
  for unowned types, delegating skyline rows to `AmsTowerSpecs.spec_for(type)`).
- `scripts/generation/landmarks/amsterdam/landmark_ams_kit.gd`: shared Dutch architectural primitives — Bentheimer
  sandstone stringcourses & quoins, crow-step / neck / bell gables with scrolled *klauwstukken* & finials, Cuypers
  arched brick window bays, Dutch Baroque octagonal wooden/copper spire lanterns, golden Imperial Crown finial, and
  brick canal-bridge arch vaults.
- Register `LandmarkRegistryAmsterdam.entries()` and `LandmarkSetAmsterdam.build` in `scripts/data/landmark_registries.gd`.
- Migrate `amsterdam_centraal` from `landmark_registry_capital_stations.gd:21-25` & `landmark_cs_west.gd:51-74` into the
  Amsterdam batch, keeping exact `type: "amsterdam_centraal"` and all aliases unchanged.
- `tests/amsterdam_landmarks_test.gd`: checks primary anchors, slot counts across all 4 presets, `radius_m` reachability,
  alias resolution, catalog limits (2–16 textured surfaces, ≤150k tris, height within tolerance), and neighbouring
  building preservation (`clear_rect_m` / `clear_offsets_m` never erase adjacent icons like Nieuwe Kerk beside Royal
  Palace or Anne Frank Huis beside Westerkerk).

Done when: `amsterdam_landmarks_test`, `landmark_catalog_test`, `landmark_placement_test`, `landmark_list_test` and
`tools/check_class_size.sh` pass, and `amsterdam_centraal` renders identically before its `AMS-2.9` rebuild.

## Phase 2: Dam Square, Canal Ring & Centraal foreground icons (0–1,150 m)

These 10 tasks cover every monument immediately visible from the capital view centre and central walks. Every builder
stays ≤1,000 lines, 2–16 textured surfaces, ≤150,000 triangles, with `*Lamp` / floodlight hooks ready for `AMS-8`.

### AMS-2.1 Koninklijk Paleis / Royal Palace (`ams_royal_palace.gd`, ~75,000 tris)
- Jacob van Campen's 1655 former Town Hall on Dam Square (`rel 3580875`, 149 m SE of centre): pale weathered Bentheimer
  sandstone (`#CFC3A8`) neoclassical quadrangle (~80 × 63 m around two inner light courts).
- Twin double-storey Corinthian/Composite pilaster orders across both Dam and Nieuwezijds Voorburgwal fronts, sunken
  rusticated basement with seven arched entry bays on Dam Square, bold projecting cornice & hipped dark-slate roof.
- Sculpted triangular central pediments front and back (relief tympanum bands + rooftop bronze Atlas, Peace, Prudence
  and Justice silhouettes).
- Iconic octagonal **cupola tower** rising above the Dam pediment to **51.75 m**: rusticated square drum, open columned
  bell lantern, dome, and gilded cog-ship weathervane.

### AMS-2.2 De Nieuwe Kerk (`ams_nieuwe_kerk.gd`, ~45,000 tris)
- Late-Gothic cruciform basilica immediately north of the Royal Palace (`way 747911438`, 136 m E of centre): buff
  sandstone and dark brick walls, high-pitched dark-slate nave and transept roofs, polygonal apse chapels, stepped
  buttresses, tall pointed Gothic tracery windows.
- Slender neo-Gothic needle **crossing spire (flèche)** rising to ~60 m above the slate roof ridge.
- Careful `clear_rect_m` so the Palace–Nieuwe Kerk narrow alley (*Mozes en Aäronstraat*) stays crisp without mutual
  overlap.

### AMS-2.3 Nationaal Monument & Dam Square Ensemble (`ams_dam_square.gd`, ~40,000 tris)
- **Nationaal Monument** (`way 168680619`, 303 m): J.J.P. Oud's 1956 22 m white travertine conical obelisk pylon, relief
  niche sculptures, circular terraced steps, curved travertine urn wall behind, and flanking sculpted stone lions.
- **De Bijenkorf** (`way 23582490`, 320 m): monumental 1914 cream-sandstone & terracotta department store with twin
  peaked corner pavilions, tall pedimented window bays, mansard slate roofs, and bronze ground-floor arcade canopies.
- Optional companion row/wing for **Grand Hotel Krasnapolsky**'s classic cream stucco hotel front facing the monument.

### AMS-2.4 Magna Plaza (`ams_magna_plaza.gd`, ~45,000 tris)
- Literally **56 m** from the capital centre (`way 57861220`) — the very first landmark seen on opening Amsterdam!
- C.H. Peters' 1899 neo-Gothic / Dutch neo-Renaissance former Main Post Office: rich red brick banded with pale cream
  sandstone, arched ground-floor loggia, ornate central gable dormer, and the unmistakable skyline of **conical and
  pear-shaped slate-and-copper corner turrets** (~38 m).

### AMS-2.5 Westerkerk & Westertoren (`ams_westerkerk.gd`, ~70,000 tris)
- Hendrick de Keyser's 1631 Protestant hall church on Prinsengracht (`ways 99205257, 99203577`, 407 m W of centre):
  double-transept red brick & sandstone Renaissance nave, tall stepped/scrolled gable ends, high slate roofs, arched
  clerestory windows.
- **Westertoren (85–87 m)** — the defining vertical spire of the Grachtengordel: heavy square brick base rising to
  three stepped white Bentheimer sandstone octagonal stages, open columned carillon belfry, four black-and-gold clock
  dials, lead-grey bulbous cap, and the vivid **royal-blue & gilded Imperial Crown of Maximilian I** at the apex.
- Keep `clear_m` tight around the nave so **Anne Frank Huis** (`Prinsengracht 263`, immediately north) remains intact.

### AMS-2.6 Beurs van Berlage (`ams_beurs_van_berlage.gd`, ~55,000 tris)
- H.P. Berlage's 1903 Dutch rationalist landmark on Damrak (`way 57858502`, 462 m NE; currently `lv=2` in OSM!): long
  unplastered deep red-orange brick halls with crisp pale sandstone lintels, stringcourses, and stepped corner gablets.
- Signature **40 m SW corner clock tower** with recessed brick corner slits, clock dials, sandstone loggia, and green
  patinated copper pyramid roof; three pitched iron-and-glass hall roofs behind.

### AMS-2.7 Oude Kerk (`ams_oude_kerk.gd`, ~55,000 tris)
- Amsterdam's oldest building (1306) in De Wallen (`way 57857592`, 570 m E): broad Gothic red-brick hall church
  surrounded by low timber-and-brick *koster* houses tucked between buttresses, tall pointed arched windows, and steep
  grey slate roofs.
- Ornate **67 m west tower**: brick shaft transitioning to Hendrick de Keyser's multi-tiered wooden-and-lead Baroque
  spire with two open octagonal carillon lanterns, black-and-gold clock dials, onion dome, and gilded weathervane.

### AMS-2.8 Historic Canal Towers & Churches (`ams_historic_towers.gd` & `ams_historic_churches.gd`, ~20–35k tris each)
- **Munttoren** (`way 57862728`, 811 m S, ~40 m): medieval brick polygonal base + 19th-century stepped-gable guardhouse
  + Hendrick de Keyser's 1620 open white-and-slate octagonal clock lantern & bulbous spire at Muntplein.
- **Zuiderkerk** (`way 114120359`, 800 m SE, 61.2 m): brick Renaissance hall church + famous white-sandstone square-to-
  octagonal stepped tower (iconic down the Groenburgwal canal vista).
- **Waag** (`way 57857390`, 735 m E, ~28 m): 1488 medieval red-brick Sint Antoniespoort gatehouse on Nieuwmarkt with
  five cylindrical turrets capped in steep dark-slate cones.
- **Koepelkerk / Ronde Lutherse Kerk** (`way 22100190`, 518 m N, ~36 m): circular brick drum crowned by its ribbed
  **green patinated copper dome** and cupola lantern on Singel.
- **Noorderkerk** (`way 220961710`, 662 m NW, ~34 m): Greek-cross red-brick church with four equal gables and central
  copper/slate bell turret on Noordermarkt.
- **De Krijtberg** (`585 m S`, ~53 m): neo-Gothic red-brick canal church squeezed between Singel townhouses with twin
  slender pointed slate spires.

### AMS-2.9 Amsterdam Centraal Full Rebuild (`ams_centraal_station.gd`, ~115,000 tris)
- Replaces the 24-line stub in `landmark_cs_west.gd` with Cuypers' full 306 m island terminal (`way 57856845`, 925 m NE):
  - Red brick & Bentheimer sandstone banding across the entire symmetrical facade, central triumphal stepped gable
    pavilion with arched entries and sculpted relief panels, flanked by the **45 m twin towers** (west clock dial, east
    gilded wind-direction compass dial) with open lanterns and slate spires.
  - Steep slate-roofed intermediate ranges with stone-framed dormers, end pavilions, and the ornate **East Royal
    Pavilion** (*Koninklijke Wachtkamer*) with its pyramidal roof and carriage arch.
  - All **three** train/transit sheds behind: the wide 1889 south cast-iron & glass arched train shed (`Middenkap`), the
    1922 north arched train shed, and the **2015 Benthem Crouwel curving glass-and-steel IJ-side bus-station & ferry
    canopy** overlooking the water, plus IJboulevard waterfront promenade edge.

### AMS-2.10 East Waterfront Historic Ensemble (`ams_east_waterfront_historic.gd`, ~30–45k tris each)
- **Sint-Nicolaasbasiliek** (`way 174996833`, 822 m NE, 58 m): neo-Baroque sandstone-and-brick basilica facing Centraal
  with twin front bell towers, central rose window, pedimented portico, and dominant **58 m octagonal green-copper
  crossing dome** + lantern.
- **Schreierstoren** (`way 57859248`, 890 m NE, 20 m): 1487 stout semicircular red-brick corner defence tower with steep
  conical slate roof overlooking Oosterdok.
- **Montelbaanstoren** (`way 57864086`, 1,106 m E, 48 m): 1516 weathered brick semicircular defensive bastion crowned by
  Hendrick de Keyser's 1606 ornate multi-tiered wooden-and-slate clock spire on Oudeschans.
- **Scheepvaarthuis / Grand Hotel Amrâth** (`way 57863677`, 981 m E, ~35 m): 1916 cradle of the Amsterdam School on
  Prins Hendrikkade — dramatic acute **ship-prow** triangular plan, sculpted dark brick & granite base, leaded-glass
  bays, wave-motif terracotta trim, and steep hipped tiled roof with corner turret.

**Validation for every Phase 2 task:** `amsterdam_landmarks_test`, `landmark_catalog_test`, `landmark_placement_test`
and `landmark_lights_test` pass; day & `--night` `capture_landmarks.gd` model sheets compared against Wikimedia Commons
refs via `tools/landmark_compare_sheets.py`; one open-space in-world look per landmark.

## Phase 3: Cultural icons, IJ waterfront, outer heritage & skyline towers

### Batch B: Museumplein & South Canal Ring (`AMS-3.1`–`AMS-3.2`)

| ID | Row | Must-have real-life features | Budget |
| --- | --- | --- | --- |
| AMS-3.1a | **Rijksmuseum** (`ams_rijksmuseum.gd`) | Cuypers' 1885 150 m twin-courtyard neo-Gothic/Dutch-Renaissance brick-and-sandstone palace, **open vaulted bicycle/pedestrian passage through the centre**, twin 60 m slate-spired central towers, four corner pavilions, ceramic tile friezes, north/south formal forecourt & Museumplein reflection pond (`tree_rect` keeps lawn open) | ~110k |
| AMS-3.1b | **Van Gogh Museum** (`ams_van_gogh_museum.gd`) | Rietveld's crisp white/grey geometric cantilevered main volume + Kurokawa's elliptical dark-stone & titanium wing + curved structural-glass entrance pavilion | ~35k |
| AMS-3.1c | **Stedelijk Museum** (`ams_stedelijk_museum.gd`) | 1895 red-brick & sandstone neo-Renaissance building fused with Benthem Crouwel's dramatic cantilevered pure-white **"Bathtub" (*De Badkuip*)** wing facing Museumplein | ~40k |
| AMS-3.1d | **Het Concertgebouw** (`ams_concertgebouw.gd`) | 1888 Dutch neoclassical cream-stone & red-brick hall with Corinthian pedimented facade, gilded rooftop **Apollo lyre**, curved side gables, and modern glazed Van Baerlestraat foyer | ~45k |
| AMS-3.2a | **Pathé Tuschinski** (`ams_tuschinski.gd`) | 1921 Art Deco / Amsterdam School cinema on Reguliersbreestraat: glazed green-and-cream ceramic facade, twin ornate corner turrets with gilded caps, recessed arched entry canopy | ~30k |
| AMS-3.2b | **De Bazel** (`ams_de_bazel.gd`) | 1926 monumental horizontal-banded granite & dark-brick fortress (`way 114542356`, 37.5 m) spanning a full Vijzelstraat block with recessed top storeys | ~30k |
| AMS-3.2c | **Stadsschouwburg & American Hotel** (`ams_leidseplein.gd`) | 1894 red-brick & sandstone neo-Renaissance theatre with arched balcony loggia on Leidseplein (`way 57863115`), paired with Willem Kromhout's 1902 Jugendstil brick-and-turret **American Hotel** (Café Americain) beside it | ~45k |
| AMS-3.2d | **Heineken Experience & Vondelkerk** (`ams_south_heritage.gd`) | 1867 red-brick brewery with central stepped clock gable & green copper brewhouse roof; Cuypers' polychrome brick neo-Gothic **Vondelkerk** with octagonal crossing lantern & spire | ~40k |

### Batch C: Amstel River & Jewish Cultural Quarter (`AMS-3.3`)

- **Stopera (Stadhuis & Nationale Opera en Ballet)** (`ams_stopera.gd`, ~45k tris): curved white-marble & glass
  riverside opera drum fronting the Amstel (`ways 268782345, 751591420`) paired with the stepped brick-and-stone city
  hall wing and Waterlooplein plaza edge.
- **Amstel Riverside Palaces** (`ams_amstel_palaces.gd`, ~45k tris):
  - **H'ART Museum (Amstelhof, 1681)**: long symmetrical classical Dutch brick facade with white window frames, central
    pediment and courtyard garden.
  - **Koninklijk Theater Carré (1887)**: neoclassical cream-and-brick circus theatre with giant pilasters, pedimented
    entry, and copper rooftop domes overlooking the Amstel.
  - **InterContinental Amstel Hotel (1867)**: palatial Second-Empire sandstone/stucco facade with mansard slate roofs,
    corner pavilions and riverside terrace steps.
- **East Heritage Pack** (`ams_east_heritage.gd`, ~45k tris):
  - **Portugese Synagoge (1675)**: monumental austere red-brick & sandstone cube with tall arched windows, wooden
    cornice, and low perimeter courtyard wings.
  - **Tropenmuseum (1926)**: grand Dutch neo-Renaissance red-brick & sandstone palace with its dominant 48 m octagonal
    corner tower and copper lantern.
  - **Molen De Gooyer (1814)**: Amsterdam's iconic 26.6 m octagonal dark-timber thatched *stellingmolen* windmill with
    elevated wooden gallery deck, rotating cap, and four latticed wooden sails on the Funenkade canal!

### Batch D: IJ Waterfront, Oosterdok, Overhoeks & Iconic Modernism (`AMS-3.4`–`AMS-3.5`)

- **NEMO Science Museum** (`ams_nemo.gd`, ~45k tris): Renzo Piano's unmistakable **oxidised green-copper ship-prow**
  rising 32 m out of the IJtunnel (`ways 1390692763, 1390692772`), stepped public rooftop piazza descending to the
  water, glazed rooftop café, and perforated porthole facade.
- **Het Scheepvaartmuseum & VOC Ship *Amsterdam*** (`ams_scheepvaartmuseum.gd`, ~65k tris): Daniel Stalpaert's 1656
  square classical sandstone-and-brick *'s Lands Zeemagazijn* with pitched slate roofs, pedimented gables, modern
  diamond-grid geodesic glass courtyard canopy, plus the full-scale moored **1749 three-masted VOC East Indiaman
  *Amsterdam*** replica (dark timber hull, gilded stern gallery, three rigged masts & furled sails) alongside the quay!
- **EYE Filmmuseum & A'DAM Toren (Overhoeks)** (`ams_overhoeks.gd`, ~60k tris):
  - **EYE Filmmuseum**: Delugan Meissl's stark cantilevered **faceted white aluminium-panelled origami** shell hovering
    above the IJ north bank with panoramic glazed waterfront foyer steps.
  - **A'DAM Toren** (`way 44824385`, 100 m): former Shell tower rotated 45° to the IJ — vertical precast white ribs &
    dark recessed glazing, cantilevered steel-and-glass observation crown (`A'DAM Lookout`), and the silhouette of the
    rooftop **Over The Edge** swing cantilevered over the north-south lip!
- **Muziekgebouw aan 't IJ, Bimhuis & OBA Oosterdok** (`ams_ij_cultural.gd`, ~45k tris): sweeping glass waterfront roof
  canopy over Muziekgebouw (`way 755464129`) with the dramatic **cantilevered corrugated-black-steel Bimhuis box**
  jutting out above the pier; Jo Coenen's pale-stone & glass **OBA Oosterdok** central library.
- **Harbour & Amsterdam-School Icons** (`ams_west_icons.gd`, ~50k tris):
  - **Het Schip (1919)**: Michel de Klerk's exuberant sculptural Amsterdam-School brick housing block with its sharp
    acute ship-prow spire and wavy rooflines.
  - **Pontsteiger (2018)**: 90 m shimmering golden-bronze twin-legged **archway gatehouse tower** straddling its own IJ
    water pier with a 60 m cantilevered sky-bridge span!
  - **Silodam (2002)**: MVRDV's colourful stacked shipping-container mosaic pier housing block standing on stilts in the IJ.
  - **Gashouder (Westergas, 1902)**: circular red-brick & exposed iron-truss drum in Westerpark.
- **Far-Ring Stadiums** (`ams_stadiums.gd`, tier 5, ~50k tris):
  - **Olympisch Stadion (1928)**: Jan Wils' red-brick Amsterdam-School oval bowl with the iconic **46 m concrete-and-brick
    Marathon Tower** & Olympic flame cauldron.
  - **Johan Cruijff ArenA** (`rel 1458682`, 75 m): oval bowl crowned by its signature dual curved steel-arch roof trusses
    and retractable centre roof panels.

### Batch E: Skyline Towers (`scripts/data/amsterdam/ams_tower_specs.gd`, `skyline: true`, zero icon slots)

Built via `TowerSpec` / `SkyKit` (with bespoke overrides where silhouette demands it, like MVRDV's *Valley*):
1. **Amstel / Omval Cluster** (3.7 km SE, clearly visible from central roof views & Amstel):
   - **Rembrandttoren** (150 m spire / 135 m roof, Empire-State-inspired stepped grey granite & turquoise glass)
   - **Mondriaantoren** (123 m stepped turquoise-glass & pale-stone facade)
   - **Breitnertoren** (95 m chamfered dark curtain-wall tower)
   - **Amstel Tower** (103 m — also fixes OSM split height `h=6 / h=75`)
   - **Hotel Okura** (78 m pale modernist hospitality slab)
2. **Zuidas Business District Cluster** (3.9–4.3 km S):
   - **Valley** (~100 m — MVRDV's three jagged stepped-stone peaks carved around a planted central canyon; short bespoke
     builder or stepped multi-mass spec)
   - **Symphony Towers** (105 m iconic orange-terracotta brick twin towers)
   - **ITO Tower** (100 m articulated gridded stone & glass)
   - **Viñoly Tower** (95 m crisp dark curtain wall)
   - **ABN AMRO HQ** (105 m stepped granite/glass headquarters)
   - **The Rock** (91 m rugged cantilevered stone-and-glass mass)
   - **WTC Amsterdam** (105 m blue-glass stepped towers) & **New Amsterdam** (92 m)
3. **Overhoeks / IJdock / Zuidoost**: **Y-Towers / Maritim** (110 m), **Paleis van Justitie** (`way 174454540`, 42 m),
   **Dreeftoren II** (132 m).

Pin a neighbour-clearance check in `tests/amsterdam_landmarks_test.gd` (pattern `nyc_skyscraper_sites_test`) so no
Zuidas or Omval tower erases its neighbour.

## Phase 4: bridges (AMS-4)

Bridges are a signature part of Amsterdam's visual identity — both the famous monumental crossings and the hundreds of
everyday brick canal arches.

- **AMS-4.1 Bespoke Monumental Bridges** (registry rows with `span_m` / `clear_path_m`, `deck_ends: true`, removing the
  unbuilt `conf: 1` rows for `br_amsterdam_magere_brug` and `br_amsterdam_python_bridge` from
  `bridge_specs_west_europe.gd:323,407` so they are never double-registered):
  - **Magere Brug** (`ams_magere_brug.gd`, ~30k tris): Amsterdam's most photographed bridge across the Amstel — 1934
    **white-painted double-leaf wooden Dutch bascule drawbridge** (*ophaalbrug*) with overhead balance frames,
    counterweight beams, timber-pile multi-opening approach trestles, dark timber deck planks, and **1,200 warm golden
    fairy-light bulbs** (`*Lamp`) tracing the portal frames and arches at night!
  - **Blauwbrug** (`ams_blauwbrug.gd`, ~35k tris): 1883 Paris-inspired 3-arch stone & cast-iron bridge over the Amstel
    (`ways 38322374, 773860192`) with sculpted ship-prow stone cutwaters, royal-blue & gold **Imperial Crown lantern
    columns**, ornate wrought-iron balustrades, and globe lamps.
  - **Torensluis** (`ams_torensluis.gd`, ~20k tris): standing **56 m** from the capital centre (`way 7371422`) — 1648
    broadest brick arched bridge in Amsterdam over Singel, featuring three brick arch vaults, barred medieval dungeon
    openings in the piers, sandstone coping, black wrought-iron railings, and the Multatuli bust terrace.
  - **Pythonbrug / Hoge Brug** (`ams_python_bridge.gd`, ~25k tris): West 8's 2001 bright **vermilion-red undulating
    sinusoidal steel truss** footbridge arching over Spoorwegbassin (Eastern Docklands).
- **AMS-4.2 Parametric `BridgeSpec` (`conf: 2`) Rows** in `bridge_specs_west_europe.gd` (verified in `AMS-0.4`):
  **Berlagebrug** (1932 Amsterdam-School brick/granite bascule bridge), **Jan Schaeferbrug** (2001 steel arch),
  **Hogesluis** (historic 5-arch brick Amstel bridge), **Torontobrug**, **Nieuwe Amstelbrug (Ceintuurbaanbrug)**, and
  **Nesciobrug** (far east suspension footbridge). Rank tiers so the 8 Ultra bridge slots prioritize the central Amstel
  and IJ crossings.
- **AMS-4.3 Generic Brick Arched Canal Bridges (`scripts/generation/amsterdam_canal_bridges.gd`, pattern `bangkok_canal_bridges.gd`):**
  - Hooks into `RoadBuilder` for every generic OSM `bridge=yes` crossing inside historic Amsterdam districts (where
    `BridgeArches.MIN_WET_M := 45.0` currently leaves them as flat concrete slabs!).
  - Adds **hump-backed red-brown Dutch brick spandrel walls** with 1–3 vaulted brick arch openings down to below the
    waterline, pale Bentheimer sandstone arch keystones & stringcourse coping, **dark Amsterdam-green/charcoal
    wrought-iron balustrades**, and **classic corner canal lamp posts** — plus warm arch underside **fairy-light bulb
    chains** (`*Lamp`, enabled in `AMS-8`) that make the iconic *Reguliersgracht Seven Bridges* night view shine!
  - Uses **zero** bridge or landmark slots.

Validation: `bridge_specs_test`, `bridge_param_test`, `bridge_select_test`, `bridge_connection_test`, plus canal-bridge
close-up captures at Torensluis, Reguliersgracht, Blauwbrug and Magere Brug.

## Phase 5: city fabric, canal houses, houseboats & detail budget (AMS-5)

Files: new `scripts/generation/architecture_cities_amsterdam.gd`, new `scripts/generation/amsterdam_houseboats.gd`,
minimal hooks in `building_era.gd`, `city_styles.gd`, `architecture_cities_europe.gd`, `street_front.gd`,
`building_builder.gd`, `city_detail.gd`, `docs/architecture-styles.md`, `tests/architecture_test.gd`,
`tests/city_detail_test.gd`.

- **AMS-5.1 `amsterdam_rule` & Period Rows (`architecture_cities_amsterdam.gd`):**
  - Unlike cities where buildings lack era tags, **95.8 %** of Amsterdam's `detailed` buildings (12,271 / 12,811) carry
    exact Dutch BAG `start_date` years! Use `start_date` + district + footprint width to dispatch cleanly:
    - `amsterdam_golden_age` (<1750): narrow 4.5–6.5 m canal plots, tall step/neck/spout gables, dark charcoal/claret
      brick, hoist beams, steep clay-tile/slate roofs, *hardsteen* stoops.
    - `amsterdam_canal` (1750–1860): slightly wider patrician Herengracht/Keizersgracht houses, bell & classical cornice
      (*lijstgevel*) gables, ornate sandstone trim, white multi-pane sashes.
    - `amsterdam_19c` (1860–1910): Oud-Zuid / De Pijp / Plantage eclectic Dutch neo-Renaissance brick with horizontal
      cream sandstone bands, mansard/hipped slate roofs, bay windows.
    - `amsterdam_school` (1910–1945): Rivierenbuurt / Spaarndammerbuurt / Plan Zuid sculpted brick blocks, banded
      casements, rounded corners, steep terracotta roofs.
    - `amsterdam_postwar` (1946–1989): modernist brick/concrete gallery flats (outer rings).
    - `amsterdam_docklands` / `amsterdam_modern` (≥1990): Eastern Docklands (Java/KNSM/Borneo) contemporary varied-brick
      & timber narrow waterfront townhouses; Zuidas/Oosterdok glass-and-brick blocks.
  - Keep religious buildings (21 churches + synagogues) out of generic canal-house gable rules.
- **AMS-5.2 Expand District Circles (`city_styles.gd:200-204`):**
  - Grow from 5 circles to ~16 measured districts: **Oude Centrum / De Wallen**, **Grachtengordel-West**,
    **Grachtengordel-Zuid**, **Jordaan** (intimate 2–4 storey artisan brick + spout gables), **Nieuwmarkt / Lastage**,
    **Plantage**, **Museumkwartier / Oud-Zuid**, **De Pijp**, **Oud-West**, **Rivierenbuurt**, **Spaarndammerbuurt**,
    **Oostelijke Eilanden / Eastern Docklands**, **Oosterdok / IJdock**, **Overhoeks / NDSM**, **Amstelkwartier /
    Omval**, and **Zuidas**. Pin every district in `tests/architecture_test.gd`.
- **AMS-5.3 Canal-House Gable & Facade Relief Upgrades (`street_front.gd`, `architecture_cities_europe.gd`):**
  - Add **spout gable (*tuitgevel*)** and **classical cornice gable (*lijstgevel*)** alongside existing `step`, `neck`
    and `bell` gables; enrich gables with pale Bentheimer sandstone coping, decorative scrolled claw pieces
    (*klauwstukken*), attic shutter doors, and projecting iron **hoist beams (*hijsbalken*) with hooks**.
  - Expand `DUTCH` brick palette with authentic Amsterdam tonal variety: dark soot-charcoal (*zwart*), deep claret-brown,
    weathered red-orange, warm ochre, and occasional heritage dark-green painted timber (*grachtengroen* `#1b3828`).
  - Refine elevated *bel-etage* blue-limestone (*hardsteen*) stoops with black iron handrails, crisp white window frames
    with transoms/muntins, and subtle canal-terrace eaves-height rhythm.
- **AMS-5.4 472 Mapped Canal Houseboats (`scripts/generation/amsterdam_houseboats.gd`):**
  - Intercept `building=houseboat` / `building=boat` inside Amsterdam in `building_builder.gd` so they stop extruding
    as multi-storey brick buildings in water!
  - Build two realistic Dutch archetypes matched to each footprint's exact OSM polygon & length/width:
    1. **Modern *Woonark* (~65 %):** dark concrete/steel pontoon hull rising ~0.45 m above waterline, low 1-storey
       (~2.9 m) timber/zinc/painted-cladding superstructure, wide panoramic canal-side windows with white/anthracite
       frames, flat gravel/green roof with low handrail, planter boxes & potted greenery, warm interior glow at night.
    2. **Historic *Woonschip* (~35 %):** converted riveted dark-iron Dutch river barge with tapered bow/stern, wooden
       cabin superstructure, brass/white portholes & small wheelhouse, timber deck railing.
- **AMS-5.5 Detail Budget (`scripts/render/city_detail.gd`):**
  - Add `"amsterdam"` to `CityDetail.CITIES` and bump `VERSION` `4 → 5`.
  - Immediately raises Ultra `max_buildings` from 10,000 → **14,000** (rendering **all 12,811** mapped Amsterdam buildings
    with zero impostor drop-offs!), High from 2,500 → **4,000**, extends roofline/gable/stoop `near_radius` from 300 m →
    **900 m** (Ultra) / **450 m** (High), and activates z19 inner orthophoto. Verify build time and peak RAM against
    Stockholm/London in `tools/build_bench.gd` and update `tests/city_detail_test.gd`.

Validation: `architecture_test`, `facade_relief_test`, `roof_realism_test`, `roof_clutter_test`, `party_walls_test`,
`building_terraces_test`, `city_detail_test`, plus canal-front & houseboat captures along Prinsengracht, Brouwersgracht,
Herengracht and Jordaan.

## Phase 6: canals, water, vessels & Dutch elm foliage (AMS-6)

- **AMS-6.1 Canal & IJ Water Palette (`scripts/generation/water_surface.gd`):**
  - Add an `amsterdam` regional branch (`52.30..52.43, 4.78..5.02`): deep reflective dark olive-green / bottle-green
    Dutch canal water (`shallow` and `deep` calibrated so brick gables, elms and fairy lights reflect crisply rather than
    washing out to bright cyan), with slightly choppier brackish steel-green on the wider IJ channel.
- **AMS-6.2 Brick Canal Quay Walls & Unrailed Quays (`scripts/generation/amsterdam_waterfront.gd`, `shore_railings.gd`):**
  - Pattern `bangkok_waterfront.gd`: dress inland canal shorelines in Amsterdam with weathered **red-brown Dutch brick
    retaining walls**, dark damp waterline algae band, pale Belgian bluestone/granite coping slabs, and iron mooring
    rings.
  - Exclude classic historic canal quays in `shore_railings.gd` (`railed_body`) from receiving tall modern promenade
    fences — real Amsterdam canals have open brick edges lined with low *Amsterdammertjes*, trees and bikes (not 1.1 m
    guardrails).
- **AMS-6.3 Amsterdam Vessels (`vessel_prototypes.gd` / `ams_vessels.gd`, `quay_moorings.gd`, `quay_fleet.gd`):**
  - **Glass-topped *rondvaartboten*** (classic low-slung Amsterdam canal tour boats in navy-blue/white, burgundy/cream,
    and green/cream liveries with curved panoramic glass roofs) moored at Damrak, Rokin, Prins Hendrikkade & Amstel quays
    and in canal berths.
  - **Open Dutch *sloepen*** (classic dark-hulled timber-trimmed pleasure boats) tucked along Herengracht, Keizersgracht
    and Prinsengracht quay rows (`QuayMoorings.QUAY_ROWS`).
  - **Double-ended GVB IJ ferries** (crisp white & royal-blue roll-on/roll-off commuter ferries) at Centraal IJ-side,
    Buiksloterweg and NDSM ferry piers.
  - Block large ocean cruise liners from inland canals (restricting liners strictly to Passenger Terminal Amsterdam on
    the IJ east of Centraal).
- **AMS-6.4 Canal Elms & Lime Trees (`tree_species.gd`, `heritage_zones.gd`):**
  - Add `Ulmus` (*Ulmus × hollandica*, Dutch elm) to `GENUS` and an `"amsterdam"` `tree_mix` (`trees_only: true` zone
    covering Centrum, Grachtengordel, Jordaan & Vondelpark) heavily weighted to **Dutch elms (~55 %)** and **common
    limes (*Tilia*, ~30 %)** plus plane trees (*Platanus*, ~15 %), tuned with airy vase-shaped crowns that frame canal
    gables rather than smothering them.

Validation: `coastal_water_test`, `far_water_palette_test`, `vessel_models_test`, `canopy_vegetation_test`,
`tree_lod_test`.

## Phase 7: streets, red cycleways, bicycles, trams & trains (AMS-7)

- **AMS-7.1 Dutch Brick-Red Cycleways & *Klinker* Paving (`road_builder.gd`, `road_markings.gd`):**
  - Add a `"cycleway_nl"` finish (`#96463B` weathered terracotta/brick-red asphalt) applied to `highway=cycleway` (411
    mapped ways in `detailed`!) when `country == "NL"`, complete with crisp white dashed lane dividers and cycle-lane
    markings.
  - Warm reddish-brown Dutch *klinker* brick-paver tint (`_sett_hex` / `_paving_hex`) on historic canal-side residential
    quays and Jordaan lanes.
- **AMS-7.2 GVB Blue-and-White Trams (`scripts/generation/vehicles/tram_specs.gd`):**
  - Add `"amsterdam"` branch in `TramSpecs.pick` for the 327 mapped tramways: 5-section low-floor `modern5`
    (Combino/15G silhouette) in crisp white with GVB royal-blue (`#0057A8`) nose, lower skirt and upper accent stripe.
- **AMS-7.3 NS Yellow-and-Blue Trains (`scripts/generation/vehicles/train_specs.gd`):**
  - Add `"amsterdam"` / `NL` branch for the 308 mapped rail ways at Centraal: iconic Dutch Railways bright yellow
    (`#FFC917`) EMU body with dark navy-blue (`#003082`) continuous window band and white passenger doors.
- **AMS-7.4 Amsterdam Street Life (`scripts/generation/amsterdam_street_life.gd`, pattern `bangkok_street_life.gd`):**
  - **Parked Dutch bicycle rows (*fietsen*):** clusters of 4–10 slim classic black/dark *omafietsen* and occasional front-
    box *bakfietsen* parked tightly along canal bridge railings, `amenity=bicycle_parking` racks, and canal kerbs (the
    single most instantly recognisable Amsterdam street-level texture!).
  - **Outdoor canal-side café terraces** at Spui, Damstraat, Noordermarkt, Leidseplein and Amstel.
  - **Bloemenmarkt floating flower-stall greenhouses** moored along Singel between Muntplein and Koningsplein.
- **AMS-7.5 Dutch Street Furniture & Fleet (`street_furniture.gd`, `car_fleet.gd`):**
  - Refine `"nl"` `bollard_red` into the unmistakable tapered dark maroon-brown (`#5A1E1B`) cast-iron **Amsterdammertje**
    with domed cap and subtle three-cross relief band.
  - Add GVB blue-and-white tram/bus stop poles (`stop_gvb`), Dutch blue-and-white `M` metro entrance totems (`metro_nl`),
    and historic dark-green/black Amsterdam **Ritter** canal lantern street lamps.
  - Add `"netherlands"` compact/EV European hatchback mix + blue-plate Amsterdam taxi accent in `car_fleet.gd`.

Validation: `road_markings_test`, `tram_test`, `train_test`, `car_fleet_test`, `bus_stop_test`, `street_furniture_test`,
plus street-level captures along Prinsengracht, Damrak, Spui and Centraal Station forecourt.

## Phase 8: night lighting (AMS-8)

Amsterdam at night is defined by warm golden reflections across dark canals:

- **Canal bridge arch fairy-lights (*brugverlichting*):** warm incandescent bulb chains (`*Lamp`, warm amber `#FFCA74`)
  tracing the underside of every historic brick canal arch (`amsterdam_canal_bridges.gd`) and the full double-bascule
  white timber frame of **Magere Brug** (~1,200-bulb impression via instanced emissive bulb rows).
- **Landmark floodlights & `*Lamp` crowns (`scripts/render/landmark_lights.gd`):**
  - **Dam Square:** warm sandstone uplights on Koninklijk Paleis, pediment & cupola; subtle warm accent on Nieuwe Kerk &
    Nationaal Monument.
  - **Church spires:** illuminated open belfries and golden crowns on **Westertoren**, **Oude Kerk**, **Zuiderkerk**,
    **Munttoren** and **Montelbaanstoren**; green dome flood on **Sint-Nicolaasbasiliek** & **Koepelkerk**.
  - **Waterfront & Culture:** warm facade wash + lit clock/wind-vane dials on **Amsterdam Centraal**; glowing arched
    underpass & twin towers on **Rijksmuseum**; green-uplit prow on **NEMO**; stark white uplighting on **EYE
    Filmmuseum**; glowing red/white crown & aviation beacon on **A'DAM Toren**; crown lights & beacons on
    **Rembrandttoren**, **Mondriaantoren** and **Zuidas** towers.
- **Warm canal-house & houseboat windows:** ensure `amsterdam_houseboats.gd` carries warm night window emissives
  mirroring the gabled canal fronts above them.
- All night captures run at `--preset=3` (night lighting is desktop Ultra content).

Validation: `landmark_lights_test`, plus night & late captures across Set A and Set B eyes (especially Reguliersgracht
Seven Bridges, Magere Brug, Dam Square, Westerkerk and IJ waterfront).

## Phase 9: review rounds, scorecard, docs & performance (AMS-9)

- Run structured visual review rounds `amsterdam-r1`…`rN` into `visual-plan/reviews/amsterdam-rN-<date>/` at the frozen
  eyes after each major phase. Never delete a round folder referenced as tracker evidence.
- Compare every major landmark model sheet (`capture_landmarks.gd` day + `--night`) side-by-side against its Wikimedia
  Commons reference via `tools/landmark_compare_sheets.py` and score silhouettes (`tools/landmark_silhouette_scores.py`);
  log mismatches, fix, and recapture.
- Update `docs/fidelity-scorecard.md` with an Amsterdam section and per-round ratings.
- Update `docs/architecture-styles.md`, `docs/amsterdam-landmark-sources.md` and `README.md` landmark/bridge lists.
- Performance & memory verification:
  - `tools/build_bench.gd` before and after `AMS-5.4` (`CityDetail.CITIES` boost to 14,000 buildings / 900 m detail ring)
    confirming build time and peak RAM stay within Stockholm/London budgets.
  - `tools/perf_baseline.gd` on Amsterdam (cold, cached, fly) at presets 2 and 3; `lod_test`, `memory_budget_test`,
    `impostor_test`, `landmark_ultra_lod_test`. Check frame time at Dam Square and Centraal/IJ eyes where the densest
    landmark clusters sit in view together.
- Optional, on request: add an Amsterdam `PresetViews` row (e.g. Reguliersgracht/Keizersgracht or Dam Square) and re-bake
  `assets/capital_thumbs/amsterdam_netherlands.jpg` (`--capital-thumbs`).

## Captures and eyes

Two capture sets per round (Set A tests the bundled snapshot at the capital centre; Set B re-centres live Overpass for
outer districts like Museumplein, Amstel, Oosterdok, Overhoeks and Zuidas):

**Set A — bundled centre view (`--keep_centre`):**

```
tools/godot_bg.sh --path . --script tools/capture_presets.gd --position 4000,4000 -- --tag=amsterdam-rN
  --preset=3 --pin=52.37403,4.88969 --places=amsterdam --times=golden,noon,night,late,roofs --keep_centre
  --looks="<set A eyes>"
```

**Set B — close looks (live Overpass, cached after first run):** same command without `--keep_centre`, `--tag=amsterdam-rN-close`,
and Set B eyes.

**Model sheets:** `tools/capture_landmarks.gd --types=<types> --tag=ams_lm_rN` and again with `--night`, then
`python3 -I tools/landmark_compare_sheets.py --tag=ams_lm_rN`.

Candidate eyes (`lat,lon,height_m,bearing,pitch`; verify clear of footprints in `AMS-0.2` and freeze):

| Set | Eye | Candidate | Shows |
| --- | --- | --- | --- |
| A | Singel / Torensluis centre, SE | `52.37435,4.88970,1.7,132,8` | Torensluis, Magna Plaza, Royal Palace cupola |
| A | Dam Square east, looking west | `52.37295,4.89330,1.7,276,8` | Royal Palace, Nieuwe Kerk, Nationaal Monument foreground |
| A | Dam Square west, looking east | `52.37310,4.89200,1.7,95,8` | Nationaal Monument, De Bijenkorf, Krasnapolsky |
| A | Prinsengracht / Westermarkt, looking S | `52.37545,4.88355,1.7,175,18` | Westerkerk, 87 m Westertoren crown, canal houseboats & elms |
| A | Damrak quay, looking SE | `52.37620,4.89570,1.7,155,10` | Beurs van Berlage tower, GVB trams, canal tour boats |
| A | Stationsplein, looking NNE | `52.37750,4.89940,1.7,25,10` | Amsterdam Centraal full facade, twin towers, red cycleway |
| A | Open Havenfront, looking SE | `52.37745,4.90010,1.7,135,10` | Sint-Nicolaasbasiliek dome, Schreierstoren, Scheepvaarthuis |
| A | Groenburgwal bridge, looking N | `52.36885,4.89955,2.5,5,10` | Iconic Monet canal view framing Zuiderkerk spire & brick bridge |
| A | Roof-height skyline panorama | `52.37403,4.88969,110,95,-8` | Grachtengordel gables, church spires, Centraal, IJ & Amstel skyline |
| B | Amstel bank north of Magere Brug | `52.36420,4.90220,2.5,165,4` | Magere Brug white bascule & night lights, Carré, Amstel Hotel |
| B | Blauwbrug / Amstel approach | `52.36700,4.90040,2.5,145,6` | Blauwbrug Imperial Crowns, Stopera marble drum, H'ART |
| B | Reguliersgracht / Keizersgracht | `52.36460,4.89640,2.5,200,2` | "Seven Bridges" aligned brick arches & fairy lights at night |
| B | Museumplein south lawn, looking NNE | `52.35780,4.88360,1.7,28,8` | Rijksmuseum towers & central passage, Stedelijk Bathtub, Van Gogh |
| B | Oosterdok promenade (drone over water) | `52.37520,4.91080,14,125,0` | NEMO green ship prow, Scheepvaartmuseum + VOC *Amsterdam* |
| B | Centraal IJ ferry pier, looking N | `52.38085,4.90080,3.0,8,8` | EYE Filmmuseum origami shell, A'DAM Toren crown, GVB IJ ferry |
| B | Amstel / Omval & Zuidas drone | `52.35300,4.90600,65,165,-4` | Rembrandttoren, Mondriaantoren, Breitnertoren, Zuidas horizon |

## Order and size

1. **Phase 0 (`AMS-0.1`–`0.7`), then `AMS-1`, then `AMS-2.1`–`2.9`.** Fixing the UTC+1 clock, building the Dam Square
   ensemble, Magna Plaza, Westerkerk/Westertoren, Beurs van Berlage, Oude Kerk, the canal towers and the full Amsterdam
   Centraal rebuild delivers immediate recognisability right from the opening view.
2. **Phase 5 (`AMS-5.1`–`5.4`) + `AMS-4.3` + `AMS-6.1`–`6.2`.** Adding `"amsterdam"` to `CityDetail.CITIES` (14,000
   buildings / 900 m gables), converting the 472 houseboats from brick boxes to *woonboten*, styling the ~400 brick
   arched canal bridges, and setting the dark olive canal water + brick quay walls transforms the entire city fabric in
   one stroke.
3. **Phase 3 (`AMS-3.1`–`3.6`) & `AMS-4.1`–`4.2`.** Museumplein, Amstel, IJ Waterfront (NEMO, Scheepvaartmuseum, EYE,
   A'DAM), Magere Brug, Blauwbrug, Torensluis, Pythonbrug and the Amstel/Zuidas skyline towers.
4. **Phases 6.3–6.4, 7 & 8.** Elms, *rondvaartboten* & IJ ferries, red cycleways, parked bikes, GVB trams, NS trains,
   and the full canal-bridge & landmark night pass.
5. **Phase 9 (`AMS-9`).** Review rounds, scorecard, performance baseline and code review. Each phase ends with passing
   tests and a capture round, so work can pause cleanly after any phase.

## Open decisions

| Decision | Recommendation |
| --- | --- |
| Primary anchors & Ultra slot limits (`46 / 54`) | Adopt `46 / 54` on `royal_palace_amsterdam`, `westerkerk`, `amsterdam_centraal`, `rijksmuseum` (same proven pattern as Stockholm `48 / 56` and London `42 / 50`) |
| Add `"amsterdam"` to `CityDetail.CITIES` (`AMS-5.4`) | Yes — `detailed` holds 12,811 buildings (vs 10,000 default Ultra cap); gate on `build_bench.gd` staying within Stockholm/London figures |
| Re-cut `ring1600` / `ring2500` snapshots (`hw=800 / ww=150` cap hits) | Defer until `AMS-0.2` r0 shows whether outer canal lines visibly truncate; live streaming already covers close-up Set B walks |
| Add an Amsterdam `PresetViews` vantage & re-bake capital thumbnail | Optional, on request — best candidates: Dam Square or Reguliersgracht/Keizersgracht Seven Bridges |
| Align `tools/capture_presets.gd:89` (`52.3717, 4.8897`) with `capital_catalog.gd:17` (`52.37403, 4.88969`) | Keep `capture_presets.gd` untouched unless asked, and pass `--pin=52.37403,4.88969` explicitly in capture commands so Set A always hits the bundled snapshot |

## Verification

- Headless tests (in the background via `tools/godot_bg.sh` / `tools/run_tests.sh`):
  `tools/run_tests.sh solar landmark amsterdam bridge architecture facade roof party building_terraces city_detail water vessel canopy tree road tram train car_fleet bus_stop street host_policy`
  after each relevant phase. Treat any `SCRIPT ERROR:` line as a failure even if exit code is 0.
- `tools/check_class_size.sh` after every new or expanded `.gd` file under `scripts/`.
- Windowed tests (`tests/screenshot_test.gd`, `tests/world_cache_test.gd`) batched once at the end, in the background.
- **Done means:** every Phase 2 and Phase 3 landmark is recognisable beside its Wikimedia Commons reference photo by day
  and by night; all 472 houseboats, ~400 brick canal bridges, red cycleways, GVB trams, NS trains, elms and dark
  reflective canals read unmistakably as Amsterdam; all listed tests and `check_class_size.sh` pass; and performance stays
  within noise of `amsterdam-r0`.
