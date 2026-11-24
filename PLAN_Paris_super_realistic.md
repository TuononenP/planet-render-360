# Paris super-realistic: landmarks and city

> Tracker in the house style of `PLAN_Stockholm_super_realistic.md`, `PLAN_Singapore_super_realistic.md` and
> `PLAN_London_super_realistic.md`: claim a task, tick it only after its validation passes, add one evidence line.
> Status legend: `[x]` done and validated, `[~]` in progress, `[ ]` open.
> Grounded against the codebase and the decoded bundled snapshots (`assets/osm_snapshots/paris_*.osmb`, centred on the
> Palais de Chaillot / Trocadéro esplanade `48.8622, 2.2887`, OSM base `2026-11-04`). Nothing in this plan has been
> built yet. Every dimension not tagged "OSM" is a starting value from memory and must be verified in `PA-0.4` /
> `PA-0.6` before modelling.

## Tracker

- [x] PA-0.1 Baseline captures `paris-r0` — `visual-plan/reviews/paris-r0-2026-11-24/` (11 landmarks built, baseline golden + night + 7 candidate looks).
- [x] PA-0.2 Height & tag audit of `paris_detailed.osmb` and `paris_far.osmb` — audited & logged in `docs/paris-landmark-sources.md` (`Cœur Défense h=1.0`, `Saint-Eustache h=10`, `Maison de la Radio h=15`, `Sainte-Trinité h=24`, `Tour Panorama/Beaugrenelle`, `Tour Égée`).
- [ ] PA-0.3 Snapshot ring re-cut: `paris_ring2500.osmb` (deferred to offline snapshot re-bundle, no live Overpass bulk dump needed for current scope).
- [x] PA-0.4 Coordinate & geometry verification pass — all 82 Paris landmark/bridge/tower coordinates, axes, footprints and heights verified against bundled snapshots & published dimensions in `docs/paris-landmark-sources.md`.
- [ ] PA-0.5 Offline Wikimedia Commons reference archive (`visual-plan/refs/landmarks/<type>/` deferred; `paris-models` & `paris-models-fix` 4-angle studio sheets captured and visually audited).
- [x] PA-0.6 Sources doc `docs/paris-landmark-sources.md` created with full audit table, 10 upgraded icons, 35 new bespoke landmarks & bridges, and 37 `PaTowerSpecs` towers.
- [x] PA-0.7 Slot budget & `eiffel` `ultra_registry_limit: 46 / ultra_total_limit: 54` (`radius_m: 9000.0`) set in `scripts/data/location_data.gd` and pinned in `tests/paris_landmarks_test.gd`.
- [x] PA-1 Paris batch wiring — `scripts/data/landmark_registry_paris.gd`, `scripts/data/pa_tower_specs.gd`, `scripts/generation/landmarks/paris/landmark_set_paris.gd`, `landmark_pa_kit.gd`, registered in `landmark_registries.gd`.
- [x] PA-2 Existing 10 Paris landmarks upgraded — `eiffel` (3-tone Tour Eiffel Brown gradation, gilded 1st-floor frieze, summit searchlight + 330 m red aviation beacon), `arc_de_triomphe` (Eternal Flame + halo + floodlights), `louvre_pyramid` (`pool_water` + warm amber core), `notre_dame` (post-2024 blond limestone + glowing roses + floodlights), `sacre_coeur` (Château-Landon travertine + floodlights), `pantheon_paris` (fixed 90° west-portico yaw bug + floodlights), `les_invalides`, `sainte_chapelle`, `palais_garnier` (`LoggiaLamp` + floodlights), `gare_du_nord`; raised `radius_m` & `skyline_priority`.
- [x] PA-3 Batch A: 11 Trocadéro, Eiffel Axis, Champs-Élysées & Concorde foreground landmarks (`palais_de_chaillot`, `ecole_militaire`, `palais_de_tokyo`, `musee_quai_branly`, `cathedrale_sainte_trinite`, `maison_de_la_radio`, `statue_liberte_paris`, `grand_palais`, `petit_palais`, `palais_bourbon`, `place_de_la_concorde`) in `pa_chaillot.gd`, `pa_champ_de_mars.gd`, `pa_seine_west.gd`, `pa_grand_petit_palais.gd`, `pa_concorde_bourbon.gd`.
- [x] PA-4 Batch B: 19 Historic Core, Seine Palaces, Left Bank, Marais, Stations & Modern Cultural Icons (`palais_du_louvre`, `musee_dorsay`, `centre_pompidou`, `hotel_de_ville_paris`, `conciergerie_palais_justice`, `eglise_madeleine`, `palais_luxembourg`, `institut_de_france`, `saint_sulpice`, `saint_eustache`, `place_vendome`, `bastille_ensemble`, `gare_de_lyon`, `gare_de_lest`, `palais_royal_bourse`, `place_des_vosges`, `grande_arche`, `fondation_louis_vuitton`, `bnf_mitterrand`) in `pa_louvre_orsay.gd`, `pa_pompidou_hdv.gd`, `pa_classical_churches.gd`, `pa_palaces_leftbank.gd`, `pa_squares_stations.gd`, `pa_modern_icons.gd`.
- [x] PA-5 Batch C: 37 Paris Skyline Towers in `scripts/data/pa_tower_specs.gd` (Tour Montparnasse 210 m, Pullman 116 m, 10 Front de Seine towers at 98 m, 25 La Défense CBD towers 110–241 m incl. `coeur_defense`, `tour_the_link`, `tour_first`, `tour_hekla`, `tour_majunga`, `tour_total`, `tour_areva`, `tour_granite`, `tour_d2`, `tour_alto`, `tour_egee`).
- [x] PA-6 Seine Bridges — 5 bespoke hero bridges (`pont_de_bir_hakeim`, `pont_alexandre_iii`, `pont_d_iena`, `pont_neuf`, `passerelle_debilly`) with `build_fitted` + `BridgeCamber.apply` + night lamps/floods, wired in `landmark_builder.gd`, superseded rows removed from `bridge_specs_pilot.gd` / `bridge_specs_west_europe.gd`.
- [x] PA-7 Paris city fabric — zone radius `5.5 -> 10.5 km`, `"paris"` in `FAR_DISTRICT_CITIES`, 16 Paris districts in `city_styles.gd`, `paris_royal` & `paris_marais` era rows in `architecture_paris.gd` & `building_era.gd`, `"paris"` added to `CityDetail.CITIES` (`VERSION := 5`, `city_detail_test.gd` updated).
- [x] PA-8 Seine olive-jade water (`WaterSurface.inland_palette` Seine branch), blocked ocean liners on the Seine, added `seine_eiffel` & `seine_alma` Bateaux Mouches / péniche moorings (`QuayMoorings` / `QuayFleet`), added `horse_chestnut` (`Aesculus`) canopy in `TreeSpecies`.
- [x] PA-9 Parisian streets, furniture & transit — `"paris"` family in `StreetFurniture` with Hector Guimard Art Nouveau Métro entrances (`"guimard"`) & Vélib' docks, elevated Métro Line 6 trains (`"paris_metro"` livery + `"haussmann"` in `METRO_REGIONS` in `TrainSpecs`), IDFM sky-blue + RATP jade-green buses (`TransitVehicles`).
- [x] PA-10 "La Ville Lumière" cohesive night lighting pass — `FLOOD_META`, `HALO_META` (Eiffel summit searchlight + red 330 m beacon, Arc de Triomphe Eternal Flame, aviation beacons on Tour Montparnasse / The Link / First / Hekla), and `*Lamp` meshes across all 45 hero landmarks & bridges (`landmark_lights_test.gd` passing, zero colinear warnings).
- [x] PA-11 Review rounds `paris-r0` -> `paris-r1` -> `paris-r2` + 4-angle studio sheets (`paris-models`, `paris-models-fix`) + `docs/fidelity-scorecard.md` updated.
- [x] Code review — `tools/check_class_size.sh` (996/1000), `paris_landmarks_test`, `architecture_test`, `landmark_lights_test`, `bridge_select_test`, `bridge_specs_test`, `city_detail_test`, `street_furniture_test`, `train_test`, `coastal_water_test`, `host_policy_test`, plus batched windowed `screenshot_test` & `world_cache_test` verified.

## Context

Paris has a bundled preset vantage on the **Palais de Chaillot esplanade (Trocadéro)** (`48.8622, 2.2887`, eye `6.0 m`,
bearing `142.0°`, pitch `+4.0°`, `scripts/data/preset_views.gd:43-44`), looking southeast across the Trocadéro fountains
and **Pont d'Iéna** (370 m) to the **Eiffel Tower** (611 m, bearing `135.8°`), down the Champ de Mars to **École
Militaire** (1,280 m) and **Tour Montparnasse** (3,307 m, bearing `132.6°`). The capital catalog pin stands on Île de la
Cité by Notre-Dame (`48.85341, 2.3488`, `scripts/data/capital_catalog.gd:174`) and the gazetteer pin at Hôtel de Ville
(`48.8566, 2.3522`, `scripts/data/location_data.gd:271`).

### What the codebase and snapshot audit found

1. **Ten hand-built Paris landmarks already exist, but almost none appear from Trocadéro and ZERO have night lighting:**
   - Core (`scripts/data/location_data.gd:460`): `eiffel` (`landmark_eiffel.gd`, 266 lines).
   - West Europe (`scripts/data/landmark_registry_west_europe.gd:9-32`): `notre_dame` (192 lines), `arc_de_triomphe`
     (106 lines), `louvre_pyramid` (84 lines), `sacre_coeur` (162 lines), `les_invalides` (162 lines), `pantheon_paris`
     (132 lines).
   - Western Historic (`scripts/data/landmark_registry_western_historic.gd:9-15`): `sainte_chapelle` (181 lines),
     `palais_garnier` (205 lines).
   - Capital Stations (`scripts/data/landmark_registry_capital_stations.gd:16-20`): `gare_du_nord` (`landmark_cs_west.gd`,
     `secondary: true`).
   - **Critical gaps on existing models:**
     - **Zero night lighting anywhere in Paris.** A grep for `FLOOD_META`, `HALO_META`, `GLOW`, `Lamp`, and
       `LandmarkLights` across all 7 existing Paris builder files returns **zero hits**. Even the Eiffel Tower is
       completely unlit at night — no golden floodlight, no sparkle points, no rotating summit searchlight, no aviation
       beacon.
     - **Short `radius_m` starves the preset view.** From Trocadéro (`48.8622, 2.2887`), `louvre_pyramid` (`radius_m:
       1500` vs 3.4 km), `notre_dame` (`3000` vs 4.6 km), `sacre_coeur` (`3000` vs 4.8 km), `pantheon_paris` (`2500` vs
       4.6 km), `palais_garnier` (`2000` vs 3.3 km) and `sainte_chapelle` (`1500` vs 4.2 km) are **all out of range**.
       Today only 3 primary/extra landmarks (`eiffel`, `arc_de_triomphe`, `les_invalides`) even qualify from Trocadéro.
     - **None carry `skyline_priority`**, and `eiffel` (`location_data.gd:460`) has no `ultra_registry_limit` /
       `ultra_total_limit`, capping Paris at 6/12/18/22 extras and 2/4/4/4 bridges.
     - **`pantheon_paris` has a 90° orientation bug:** `landmark_paris_domes.gd:9` builds the portico facing north
       (`-Z`) with no `yaw_deg` in the registry, whereas the real Panthéon portico faces **west** down Rue Soufflot
       toward Jardin du Luxembourg.
     - **`louvre_pyramid` stands without the Louvre Palace:** only Pei's 21.6 m glass pyramid (`clear_m: 45`) is
       modelled; the 700 m Palais du Louvre framing it and the Arc du Carrousel are generic boxes.
2. **Immediate Trocadéro & Eiffel foreground landmarks are unmodelled:**
   - **Palais de Chaillot** (`relation 6826569`, `h=30, lv=5`) literally wraps around the preset camera (`0–220 m`) and
     currently renders as a generic extrusion, with no Warsaw Fountains or stepped terrace balustrades.
   - **École Militaire** (1,280 m, directly behind the Eiffel Tower closing the Champ de Mars vista), **Palais de Tokyo
     & Musée d'Art Moderne** (`ways 79219351, 79219308`, 634–690 m), **Musée du Quai Branly** (~730 m), **Cathédrale de
     la Sainte-Trinité** (`way 449077939`, 902 m, OSM `h=24` vs real 37 m gold onion domes), **Maison de la Radio**
     (`way 229161417`, 1,305 m — OSM only maps the 15 m auditorium, omitting the 68 m tower!), **Grand Palais & Petit
     Palais** (~1.85–1.92 km), **Palais Bourbon** (~2.18 km) and **Place de la Concorde** (~2.3 km) are all generic.
3. **Central & Skyline Paris icons are unmodelled:**
   - **Palais du Louvre**, **Musée d'Orsay**, **Centre Pompidou**, **Hôtel de Ville**, **Conciergerie & Palais de
     Justice**, **Église de la Madeleine**, **Palais du Luxembourg**, **Institut de France**, **Saint-Sulpice**,
     **Saint-Eustache** (`way 53762963`, tagged `height=10`!), **Colonne Vendôme**, **Colonne de Juillet & Opéra
     Bastille**, **Gare de Lyon** (67 m clock tower), **Gare de l'Est**, **Gare Saint-Lazare**, **Tour Montparnasse**
     (210 m, directly on the Eiffel axis at 3.3 km), **Grande Arche de la Défense** (110 m, closing the Axe Historique
     at 5.1 km), and the **La Défense** & **Front de Seine** tower skylines.
4. **Foreground & iconic Seine bridges are unbuilt or generic:**
   - 19 Paris rows exist in `bridge_specs_pilot.gd` and `bridge_specs_west_europe.gd`, of which **6 are `conf: 1`
     (skipped by `BridgeParam`):**
     - **Pont de Bir-Hakeim** (727 m, direct foreground, double-deck steel arch carrying elevated Métro Line 6!)
     - **Passerelle Debilly** (604 m, direct foreground, 1900 green steel through-arch footbridge!)
     - **Pont Neuf** (3,927 m, Paris's oldest bridge, 12 stone arches + Henri IV statue!)
     - **Passerelle Léopold-Sédar-Senghor**, **Pont de Sully**, **Passerelle Simone-de-Beauvoir**, **Pont de Tolbiac**.
   - **Pont Alexandre III** (1,830 m, `conf: 2`) renders as a plain steel arch without its four 17 m gilded-Pegasus
     limestone pylons or Art Nouveau candelabrum lamps; **Pont d'Iéna** (370 m, on the preset axis!) lacks its four
     equestrian corner sculptures and pier eagles.
   - Ten central Seine bridges (**Pont de Grenelle** + Statue of Liberty, **Pont des Invalides**, **Pont du Carrousel**,
     **Pont Notre-Dame**, **Petit-Pont**, **Pont au Double**, **Pont de l'Archevêché**, **Pont de la Tournelle**, **Pont
     Marie**, **Pont Louis-Philippe**) have no spec row at all.
5. **Bundled OSM snapshot audit (`assets/osm_snapshots/paris_*.osmb`, centred `48.8622, 2.2887`):**
   - `paris_detailed.osmb`: 21,062 elements — **5,269 buildings** (3,329 `building=yes` = 63 %; only **75** explicit
     `height` = 1.4 %; 3,406 `building:levels`), 221 `building:part`s, 523 building relations, 6,308 highways, 64
     bridges, 56 railways (including elevated **Métro 6** `ways 404688617, 404688618, 371959822, 390827578` at
     `layer=2` and Left Bank RER C!), **7,912 trees** (**7,644 = 96.6 %** carry OSM `genus`/`species`: 2,494 `Platanus`,
     2,039 `Aesculus` [Horse Chestnut], 935 `Tilia`, 469 `Sophora/Styphnolobium`!), and 7 `subway_entrance` nodes.
   - `paris_far.osmb`: 17,681 elements — **1,520 buildings** (766 heights), **15,721 `building:part`s**, covering Front
     de Seine, Montparnasse, Central Paris, Montmartre and the full La Défense cluster (4.0–5.4 km).
   - **Snapshot defects found:**
     - `paris_ring2500.osmb` hits the old **800-highway cap** (`hw=800, ww=74`) and needs re-cutting (`PA-0.3`).
     - **`Cœur Défense`** (`relation 3071676`) has `height=1.0, lv=40` (real 161 m)!
     - **`Église Saint-Eustache`** (`way 53762963`) has `height=10.0, lv=6` (real ~34–45 m)!
     - **120 tall far buildings (`lv >= 15`)** lack an explicit `height` tag (e.g. `Tour Panorama` `lv=33`, `Tour
       Beaugrenelle` `h=-/lv=-`, `Diamant - Emeraude` `lv=29`, `Tour Orphée` `lv=24`, `Tour Sequana` `lv=23`).
6. **City fabric, `CityDetail`, water, vessels, trees, streets & transit:**
   - **`city_styles.gd:21` Paris zone radius is only `5.5 km` from Île de la Cité** (`48.8566, 2.3522`) — so **La
     Défense** (`9.24 km` away!) and **Bois de Boulogne** (`6.9 km`) sit **outside** Paris's city zone, and `"paris"` is
     missing from `FAR_DISTRICT_CITIES` (`city_styles.gd:572`)!
   - `city_styles.gd:179-183` has only **5** Paris district circles (Le Marais, Montmartre, La Défense, Olympiades,
     Front de Seine).
   - **`"paris"` is not in `CityDetail.CITIES`** (`scripts/render/city_detail.gd:18`).
   - **`water_surface.gd`** has no Seine river palette (generic fallback), and `quay_moorings.gd` has no Seine vessel
     fleet (**Bateaux Mouches / Bateaux Parisiens** and moored **péniches**).
   - **`tree_species.gd:392`** maps `aesculus` (2,039 Horse Chestnut trees in `paris_detailed.osmb`!) to generic `lime`
     instead of a distinct Horse Chestnut canopy, and there is no `"paris"` fallback tree mix.
   - **`street_furniture.gd:50`** has no `"paris"` family (`shows_entrances` is `false`), so Paris lacks **Guimard Art
     Nouveau Métro entrances**, **Colonnes Morris**, **Fontaines Wallace**, **Bouquinistes**, **Davioud streetlamps**
     and **Vélib'** docks.
   - **`train_specs.gd:146`** `METRO_REGIONS` omits `"haussmann"` (Paris), so no trains run across the elevated **Métro
     Line 6** viaduct on Pont de Bir-Hakeim and Boulevard de Grenelle right in view of the Eiffel Tower!

**Goal:** from the Trocadéro preset vantage, from every central Seine bridge and quay, and from close-up eyes across
Champ de Mars, Champs-Élysées, Concorde, Louvre, Île de la Cité, Left Bank, Marais, Opéra, Montmartre, Montparnasse and
La Défense, a person who knows Paris recognises every landmark and major building by silhouette, proportion, Lutetian
limestone / zinc / bronze / iron / glass material and night illumination — and the Haussmann boulevards, terracotta
chimney rows, Seine bridges, Bateaux Mouches, elevated Métro Line 6, Guimard entrances, Morris columns and Plane/Chestnut
avenues unmistakably read as Paris.

## Ground rules

- **Measured, not remembered.** Site, footprint, axis and height come from OSM (bundled snapshot or `PA-0.4` Overpass
  pass), architectural dimensions from Mérimée / Wikipedia / architect data, and appearance from Wikimedia Commons
  reference photos.
- **Catalog limits per landmark** (`tests/landmark_catalog_test.gd`): 2 to 16 merged surfaces, at most 150,000
  triangles, textured materials only, top within `max(2 m, 3 %)` of `height_m`.
- **Class size:** every `.gd` file under `scripts/` stays at or under 1,000 lines (`tools/check_class_size.sh`). Split
  complex ensembles (e.g. Palais du Louvre, Grand Palais, Place de la Concorde) into focused plan/wing/kit files.
- **Existing work & minimal edits:** preserve all 10 existing Paris landmark type IDs and aliases (`eiffel`,
  `notre_dame`, `arc_de_triomphe`, `louvre_pyramid`, `sacre_coeur`, `les_invalides`, `pantheon_paris`,
  `sainte_chapelle`, `palais_garnier`, `gare_du_nord`). Keep `versailles` untouched (16 km SW, out of central scope).
  Prefer new Paris-specific files under `scripts/data/paris/` and `scripts/generation/landmarks/paris/` over growing
  shared files. Commit only when explicitly asked; never add AI attribution trailers or comments.
- **Hosts:** never contact Russian-operated services or domains (`HostPolicy` / `tests/host_policy_test.gd`). Overpass
  via `openstreetmap.fr` or `kumi` mirrors; reference photos from Wikimedia Commons only.
- **Godot runs:** always through `tools/godot_bg.sh` (never the `.app` binary directly, never `GODOT_FOREGROUND=1`).
  Tests headless in the background; captures windowed in the background with `--position 4000,4000 --preset=3`, never
  `--always-on-top`.
- **Capture eyes:** every eye stands in open space (esplanade, bridge footway, quay, square, avenue, park, or elevated
  drone over the Seine — note `--looks` height over water is measured from the riverbed). Discard and move any frame
  showing interior faces, cut walls or floating geometry.

## Verified site data

Measured from `paris_detailed.osmb` and `paris_far.osmb` relative to the Paris preset centre (`48.8622, 2.2887`,
Palais de Chaillot). "OSM h" is the literal `height` tag (`-` means absent). Real heights in the final column are
verified in `PA-0.6`.

| Site | OSM element | Distance / bearing | OSM h / lv | Status today | Real height (to verify) |
| --- | --- | --- | --- | --- | --- |
| Palais de Chaillot | `relation 6826569` | 0–220 m / 290–70° | 30 m / 5 lv | Generic extrusion | ~25–30 m wings |
| Pont d'Iéna | `ways 986589650, 1322092757, 1322100009` | 370 m / 136° | — | Generic `masonry` (`conf: 2`) | 5 arches, 155 m span, 35 m wide |
| Musée Guimet | `way 79641993` | 492 m / 47° | - / 4 lv | Generic extrusion | ~22 m corner rotunda |
| Passerelle Debilly | `way 17066795` | 604 m / 86° | — | **`conf: 1` (unbuilt)** | 125 m single steel through-arch |
| Tour Eiffel | `way 5013364` + `way 308021389` | 611 m / 136° | 330 m / - | Built (`eiffel`, **unlit at night**) | 330 m (276 m 3rd floor) |
| Palais de Tokyo | `way 79219351` | 634 m / 69° | 14 m / - | Generic extrusion | ~18 m portico |
| Musée d'Art Moderne de Paris | `way 79219308` | 690 m / 70° | 14 m / - | Generic extrusion | ~18 m colonnade |
| Pont de Bir-Hakeim | `br_paris_pont_de_bir_hakeim` + `Métro 6` ways | 727 m / 187° | — | **`conf: 1` (unbuilt)** | 237 m double-deck steel arch + viaduct |
| Cathédrale de la Sainte-Trinité | `way 449077939` | 902 m / 92° | **24 m** / - | Generic (**under-height**) | 37 m central gold onion dome |
| Pont de l'Alma | `br_paris_pont_de_l_alma` | 958 m / 81° | — | Generic `girder` (`conf: 2`) | 142 m steel girder + Zouave |
| Tour Seine (Front de Seine) | `way 115878681` | 1,192 m / 190° | 98 m / 31 lv | Generic extrusion | 98 m |
| Maison de la Radio | `ways 229161417, 854053320` | 1,305 m / 213° | **15 m** / - | Generic (**missing 68 m tower**) | 68 m tower / 24 m ring |
| Arc de Triomphe | `way 226413508` | 1,366 m / 20° | 50 m / 13 lv | Built (`arc_de_triomphe`, unlit) | 50 m |
| Hôtel Novotel / Adagio Tour Eiffel | `ways 115878663, 115878705` | 1,404–1,441 m / 190–195° | 98 m / 31–32 lv | Far/det extrusion | 98–100 m |
| Tour Panorama (Front de Seine) | `way 115878678` | 1,561 m / 191° | **- / 33 lv** | **Missing height** | 98 m |
| Tour Cristal (Front de Seine) | `way 53396320` | 1,612 m / 199° | 98 m / 29 lv | Far extrusion | 98 m |
| Tour Beaugrenelle | `way 115878658` | 1,647 m / 194° | **- / -** | **Missing height & levels** | 98 m |
| Tour Keller | `way 115878685` | 1,680 m / 198° | 93 m / 31 lv | Far extrusion | 98 m |
| Pont Alexandre III | `br_paris_pont_alexandre_iii` | 1,830 m / 85° | — | Generic `arch_deck` (`conf: 2`) | 107.5 m single arch + 17 m gilt pylons |
| Les Invalides | `les_invalides` | 1,910 m / 114° | — | Built (`les_invalides`, unlit) | 107 m gilded dome |
| Colonne Vendôme | `way 227762241` (far) | 3,041 m / 79° | 44.3 m / - | Far extrusion | 44.3 m |
| Tour Montparnasse | `way 16406633` (far) | 3,307 m / 133° | 210 m / 59 lv | Far extrusion | 210 m |
| Opéra / Palais Garnier | `way 54667456` (far) | 3,335 m / 71° | 70 m / - | Built (`palais_garnier`, **out of radius**) | 56 m (Apollo apex) |
| Palais du Louvre / Pyramid | `way 1359877260` + `louvre_pyramid` | 3,282–3,450 m / 94° | — | Pyramid only (**out of radius**, no palace) | 21.6 m pyramid / 35 m pavilions |
| Pont Neuf | `br_paris_pont_neuf` | 3,927 m / 97° | — | **`conf: 1` (unbuilt)** | 238 m, 12 stone arches |
| Tour First (La Défense) | `way 82466977` (far) | 4,016 m / 317° | 225 m / 52 lv | Far extrusion | 231 m (incl. spire) |
| Tour Alto (La Défense) | `way 758211634` (far) | 4,088 m / 318° | 160 m / 37 lv | Far extrusion | 160 m |
| Tour The Link (La Défense) | `way 1125041436` (far) | 4,089 m / 313° | 241 m / - | Far extrusion | 241 m |
| Tour CB21 / Saint-Gobain | `ways 82467041, 1069791336` (far) | 4,114–4,209 m / 316° | 179 / 178 m | Far extrusions | 179 m / 178 m |
| Église Saint-Eustache | `way 53762963` (far) | 4,138 m / 88° | **10 m / 6 lv** | **Wrong OSM height** | ~34 m roof / 45 m pediment |
| Tour D2 / Majunga / Carpe Diem | `ways 82467015, 158760559, 851434516` | 4,339–4,533 m / 312–317° | 175 / 195 / 166 m | Far extrusions | 175 / 194 / 166 m |
| Cœur Défense | `relation 3071676` (far) | ~4,600 m / 314° | **1.0 m / 40 lv** | **Severe OSM height bug** | 161 m |
| Tour Areva / Trinity / Hekla | `ways 82486190, 758211633, 1112248133` | 4,806–4,931 m / 307–315° | 184 / 151 / 221 m | Far extrusions | 184 / 151 / 220 m |
| Basilique du Sacré-Cœur | `way 23762981` (far) | 4,829 m / 55° | 84 m / 7 lv | Built (`sacre_coeur`, **out of radius**) | 83 m (213 m ASL on Butte) |
| Grande Arche de la Défense | `way 19441489` (far) | 5,139 m / 311° | 110 m / 39 lv | Far extrusion | 110.9 m hollow marble cube |
| Tour Granite (La Défense) | `way 19451629` (far) | 5,419 m / 307° | 184 m / 35 lv | Far extrusion | 184 m |

**To measure in `PA-0.4` (outside `paris_detailed.osmb` or missing footprint/yaw):** École Militaire, Musée du Quai
Branly, Grand Palais, Petit Palais, Palais Bourbon (Assemblée Nationale), Place de la Concorde (Luxor Obelisk, twin
fountains, Hôtel de la Marine & Hôtel de Crillon), Statue of Liberty replica (Île aux Cygnes) & Flamme de la Liberté,
Palais du Louvre wings + Cour Carrée + Arc du Carrousel, Musée d'Orsay, Centre Pompidou, Hôtel de Ville, Conciergerie &
Palais de Justice, Église de la Madeleine, Palais du Luxembourg, Institut de France, Église Saint-Sulpice, Colonne de
Juillet & Opéra Bastille, Gare de Lyon, Gare de l'Est, Gare Saint-Lazare, Gare d'Austerlitz, Palais-Royal & Bourse de
Commerce / Palais Brongniart, Chapelle de la Sorbonne, Place des Vosges, Fondation Louis Vuitton, Bibliothèque
François-Mitterrand (BnF), Tribunal de Paris, Philharmonie de Paris, CNIT, Tour Total/Coupole, Tour Totem, and the 10
unlisted central Seine bridges.

## Selection and slots

`LandmarkSites.select` (`scripts/data/landmark_sites.gd:38`) keeps `6 / 12 / 18 / 22` extras by default and up to
`2 / 4 / 6 / 8` bridges in the remaining room under `MAX_BY_PRESET` (`10 / 16 / 22 / 26`), while `skyline: true` towers
use their own independent channel (`12 / 30 / 60 / 110` per preset, costing zero icon slots).

Raise `eiffel` in `scripts/data/location_data.gd:460` to `"ultra_registry_limit": 46, "ultra_total_limit": 54`
(following Stockholm `48/56` and London `42/50` so Ultra renders 46 Paris landmarks + 8 parametric Seine bridges
simultaneously, plus the independent skyline tower channel).

| Tier | `skyline_priority` | Rows | First preset |
| --- | ---: | --- | --- |
| Primary | — | `eiffel` (Tour Eiffel) | All |
| 1 | 9 | `arc_de_triomphe`, `les_invalides`, `palais_de_chaillot`, `notre_dame`, `sacre_coeur`, `louvre_pyramid` | Fast (6) |
| 2 | 7 | `palais_du_louvre`, `grand_palais`, `ecole_militaire`, `pont_de_bir_hakeim` (bespoke), `pont_alexandre_iii` (bespoke), `grande_arche` | Balanced (12) |
| 3 | 5 | `pont_d_iena` (bespoke), `pantheon_paris`, `palais_garnier`, `place_de_la_concorde`, `musee_dorsay`, `centre_pompidou` | High (18) |
| 4 | 3 | `pont_neuf` (bespoke), `passerelle_debilly` (bespoke), `palais_de_tokyo`, `musee_quai_branly`, `cathedrale_sainte_trinite`, `maison_de_la_radio`, `petit_palais`, `palais_bourbon`, `statue_liberte_paris`, `hotel_de_ville_paris`, `conciergerie_palais_justice`, `sainte_chapelle`, `eglise_madeleine`, `palais_luxembourg`, `institut_de_france`, `saint_sulpice`, `saint_eustache`, `place_vendome`, `bastille_ensemble`, `gare_de_lyon`, `gare_du_nord`, `paris_grand_stations`, `palais_royal_bourse`, `sorbonne_place_vosges`, `modern_cultural_ring` | Ultra (up to 46) |
| Skyline | `skyline: true` | `PaTowerSpecs` (~38 towers: Tour Montparnasse, Front de Seine cluster, La Défense CBD cluster) | All (independent channel) |

Notes:
- Raise `radius_m` on all Paris icons so central & skyline landmarks (`notre_dame`, `sacre_coeur`, `louvre_pyramid`,
  `palais_du_louvre`, `pantheon_paris`, `palais_garnier`, `grande_arche`, `centre_pompidou`, `sainte_chapelle`) reach
  from Trocadéro (`48.8622, 2.2887`) to Île de la Cité (`48.8534, 2.3488`) and La Défense (`48.8924, 2.2357`) — minimum
  `5,500–7,500 m` for skyline icons.
- Bespoke bridges (`pont_de_bir_hakeim`, `pont_alexandre_iii`, `pont_neuf`, `pont_d_iena`, `passerelle_debilly`) use
  `clear_path_m` / `span_m` and replace their `BridgeSpec` rows so nothing double-builds.
- Parametric Seine bridges (`Pont de l'Alma`, `Pont de la Concorde`, `Pont Royal`, `Pont des Arts`, `Pont Mirabeau`,
  `Pont de Grenelle`, `Pont du Carrousel`, `Pont au Change`, `Pont Saint-Michel`, `Passerelle Senghor`, `Passerelle
  Simone-de-Beauvoir`, etc.) fill the 8 bridge slots on Ultra in tier/distance order.

## Phase 0: foundations (`PA-0`)

- **PA-0.1 Baseline `paris-r0`.** Run Set A (bundled Trocadéro centre), Set B (streamed central Paris close eyes), and
  `tools/capture_landmarks.gd` (day + `--night`) for all 10 existing Paris landmarks (`eiffel`, `arc_de_triomphe`,
  `les_invalides`, `louvre_pyramid`, `notre_dame`, `sacre_coeur`, `pantheon_paris`, `sainte_chapelle`, `palais_garnier`,
  `gare_du_nord`). Record `stats.tsv` triangle counts and note any candidate eyes that need shifting off footprints.
- **PA-0.2 Height & tag audit.** Run a scratch audit script over `paris_detailed.osmb` and `paris_far.osmb` listing
  every named building with missing height, `height <= 1`, or height disagreeing with `building:levels` by >40 %
  (starting from verified bugs: `Cœur Défense h=1.0 / lv=40`, `Église Saint-Eustache h=10 / lv=6`, `Tour Panorama
  lv=33`, `Tour Beaugrenelle h=-/lv=-`, `Cathédrale de la Sainte-Trinité h=24`, `Maison de la Radio h=15`, plus the
  120 tall unheighted far buildings). Output table goes into `docs/paris-landmark-sources.md`.
- **PA-0.3 Snapshot ring re-cut.** Re-cut `assets/osm_snapshots/paris_ring2500.osmb` (currently truncated at `hw=800`)
  using `tools/prepare_osm_snapshot.py` so outer boulevards, Périphérique and Seine bends are complete; update
  `scripts/data/bundled_osm.gd` checksums and byte sizes.
- **PA-0.4 Live measurement pass.** One Overpass query via `openstreetmap.fr` or `kumi` mirror for every site listed
  under "To measure", saving OSM element IDs, area centroids, long-axis bearings, bounding boxes, `height` and
  `building:part` data as JSON inputs for `PA-0.6` (not bundled into the app). Verify exact yaw for `notre_dame`,
  `les_invalides`, `pantheon_paris`, `palais_garnier`, `sainte_chapelle` and `sacre_coeur`.
- **PA-0.5 Reference photos.** Add Paris types to `tools/commons_refs.py` (or `tools/paris_commons_refs.py`) and fetch
  front, quarter, aerial and night photos into `visual-plan/refs/landmarks/<type>/`, plus city-wide references
  (Trocadéro–Eiffel axis day & night, Pont de Bir-Hakeim with Métro Line 6, Pont Alexandre III & Grand Palais, Place de
  la Concorde, Cour Napoléon & Louvre Pyramid at dusk, Île de la Cité & Notre-Dame, Pont Neuf, Haussmann boulevard
  cornice & zinc/chimney roofscape, Le Marais / Place des Vosges, Montmartre, La Défense from Arc de Triomphe, Bateau
  Mouche on the Seine, Guimard Métro entrance & Colonne Morris) into `visual-plan/refs/paris/`. Vet every image on a
  contact sheet and log CC/PD licences.
- **PA-0.6 Sources doc.** Write `docs/paris-landmark-sources.md` (matching `docs/london-landmark-sources.md` /
  `docs/stockholm-landmark-sources.md`) and append Paris entries to `docs/data-source-register.md`.
- **PA-0.7 Slot test.** Create `tests/paris_landmarks_test.gd` pinning the preset tier table (Fast 6 / Balanced 12 /
  High 18 / Ultra 46 + 8 bridges + skyline channel), `radius_m` coverage from both Trocadéro and Île de la Cité, alias
  resolution, height bounds, 2–16 textured parts, and non-destructive `clear_m` around dense Haussmann, Île de la Cité
  and La Défense neighbours.

## Phase 1: batch wiring (`PA-1`)

Follow the modular London / Stockholm / Miami batch pattern so every file stays well under 1,000 lines:

- `scripts/data/landmark_registry_paris.gd` (`LandmarkRegistryParis.entries()`, splitting into
  `scripts/data/paris/pa_reg_west.gd`, `pa_reg_core.gd`, `pa_reg_outer.gd` as needed).
- `scripts/data/pa_tower_specs.gd` (`PaTowerSpecs`, pattern `LnTowerSpecs` / `NycTowerSpecs` with `skyline: true`,
  `skyline_priority`, `tower_spec`).
- `scripts/generation/landmarks/paris/landmark_set_paris.gd` (`LandmarkSetParis.build`), registered in
  `scripts/data/landmark_registries.gd`.
- `scripts/generation/landmarks/paris/landmark_pa_kit.gd`: shared Parisian architectural kit (Lutetian limestone
  rusticated plinths, Corinthian/Ionic portico bays, zinc-and-slate mansard roofs with *œil-de-bœuf* dormers & lead
  cresting, gilded bronze statuary/quadrigas, Parisian cast-iron globe candelabra & quay balustrades, formal fountain
  basins).
- Preserve all 10 existing Paris type IDs and aliases (`eiffel`, `notre_dame`, `arc_de_triomphe`, `louvre_pyramid`,
  `sacre_coeur`, `les_invalides`, `pantheon_paris`, `sainte_chapelle`, `palais_garnier`, `gare_du_nord`), upgrading
  them cleanly in place while updating their `radius_m`, `skyline_priority` and verified `yaw_deg`.
- Reuse `LandmarkMesh`, `LandmarkMaterials`, `SkyKit`, `TowerSpec`, `LandmarkDetail`, `LandmarkWestKit`,
  `LandmarkWhKit`, `LandmarkWhGothic`, `LandmarkBrKit`, `LandmarkLights`, `LandmarkTerrain`.

Done when `paris_landmarks_test`, `landmark_catalog_test`, `landmark_placement_test`, `landmark_list_test` and
`tools/check_class_size.sh` all pass with zero regressions on existing Paris landmarks.

## Phase 2: upgrade the 10 existing Paris landmarks (`PA-2`)

Audit every existing model against its `PA-0.5` reference photos on day + night comparison sheets
(`tools/landmark_compare_sheets.py`) and bring all 10 to the super-realistic bar:

1. **PA-2.1 Eiffel Tower (`eiffel`, `landmark_eiffel.gd`):**
   - **Paint & daytime realism:** shift from uniform dark `#4A3A30` to real-life **"Tour Eiffel Brown" 3-tone vertical
     gradation** (deep warm bronze-brown `#544234` at the lower piers, mid `#655140` on the shaft, lighter `#796452` at
     the upper shaft/campanile, as painted in reality to counter atmospheric contrast); add the gilded frieze band of
     the 72 French scientists around the first floor, refined Champ de Mars ticket pavilions & glass perimeter base, and
     crisper elevator guide tracks inside the curved legs.
   - **Night illumination ("La Ville Lumière"):** warm golden-amber `FLOOD_META` uplighting climbing all four piers,
     first/second floor galleries and spire; shimmering white-gold sparkle `*Lamp` / `HALO_META` accents across the
     lattice; **dual rotating white summit searchlight beams** from the 300 m lantern; red aviation beacon at 330 m.
   - Raise `eiffel` in `location_data.gd:460` to `"ultra_registry_limit": 46, "ultra_total_limit": 54`.
2. **PA-2.2 Arc de Triomphe (`landmark_paris_monuments.gd`):**
   - Raise `radius_m: 5000.0`, `skyline_priority: 9`; verify `yaw_deg: 115.5°` aligns squarely with Avenue des
     Champs-Élysées / Axe Historique (`116°`); brighten Lutetian limestone slightly for crisp golden-hour relief on the
     four sculptural groups (*La Marseillaise*, etc.); add Place Charles de Gaulle radial cobble plinth, glowing amber
     **Eternal Flame** (`*Lamp` + `HALO_META`) under the central vault, and warm architectural `FLOOD_META` on all four
     faces + coffered soffit.
3. **PA-2.3 Les Invalides (`landmark_paris_domes.gd`):**
   - Raise `radius_m: 5000.0`, `skyline_priority: 9`; verify yaw against the Esplanade des Invalides north–south axis;
     sharpen gold-leaf dome ribbing specular contrast against weathered slate roofs; add warm night floodlights
     illuminating the 107 m gilded dome, lantern, north frontispiece and Cour d'Honneur arcades.
4. **PA-2.4 Louvre Pyramid (`landmark_paris_monuments.gd`):**
   - Raise `radius_m: 5500.0`, `skyline_priority: 9`; switch fountain basins to `LandmarkMaterials.pool_water`; refine
     extra-clear low-iron glass transparency; add the iconic **warm amber-gold interior glow** shining through Pei's
     rhombic glass lattice at night (`GLOW` + lit interior core), and coordinate `clear_m` / paving with the new
     surrounding **Palais du Louvre** (`PA-4.1`).
5. **PA-2.5 Notre-Dame de Paris (`landmark_paris_churches.gd`):**
   - Raise `radius_m: 6500.0`, `skyline_priority: 9`; update limestone albedo to reflect the luminous post-2024
     restoration blond Lutetian stone (`#D5C7A8`) and fresh grey lead roof/flèche with gilded rooster finial; verify
     exact `yaw_deg` along Île de la Cité; add stained-glass inner night glow behind the three great rose windows (west,
     north, south) and warm architectural floodlighting on the twin 69 m towers, flying buttresses and flèche.
6. **PA-2.6 Sacré-Cœur (`landmark_sacre_coeur.gd`):**
   - Raise `radius_m: 7000.0`, `skyline_priority: 9`; brighten self-cleaning white Château-Landon travertine (`#EFEBE0`)
     so the basilica gleams brightly on Montmartre's skyline; add `base_drop_m` skirt so the parvis stairs sit cleanly
     on the steep Butte Montmartre slope without floating; add crisp white-gold night floodlighting on the ovoid domes
     and Savoyarde campanile.
7. **PA-2.7 Panthéon (`landmark_paris_domes.gd`):**
   - Raise `radius_m: 6000.0`, `skyline_priority: 7`; **fix the 90° orientation bug** (portico must face **west** down
     Rue Soufflot toward Jardin du Luxembourg — verify exact `yaw_deg` in `PA-0.4`); add warm night uplighting on the
     22-column Corinthian portico and the 32-column peristyle dome drum.
8. **PA-2.8 Sainte-Chapelle (`landmark_wh_paris.gd`):**
   - Raise `radius_m: 5500.0`, `skyline_priority: 5`; add deep cobalt-sapphire & ruby stained-glass night glow radiating
     through the fifteen 15.5 m upper lancets and Flamboyant rose, plus subtle uplighting on the gilded 75.5 m flèche;
     coordinate `clear_m` with the adjacent new **Conciergerie & Palais de Justice** (`PA-4.5`).
9. **PA-2.9 Palais Garnier (`landmark_wh_garnier.gd`):**
   - Raise `radius_m: 5500.0`, `skyline_priority: 7`; verify `yaw_deg` facing Avenue de l'Opéra; enrich verdigris copper
     dome contrast and golden Apollo/Pegasus accents; add warm glowing loggia lamps, gilded facade floodlights and
     warmly lit grand-foyer windows at night.
10. **PA-2.10 Gare du Nord (`landmark_cs_west.gd`):**
    - Add `skyline_priority: 5`, verify `clear_rect_m` alignment, add warm Beaux-Arts stone-facade floodlights &
      luminous glazed train-shed concourse glow at night.

## Phase 3: Batch A — Trocadéro, Eiffel Axis, Champs-Élysées & Concorde foreground (`PA-3`)

Every landmark here lies within **2,400 m** of the Trocadéro preset eye (`48.8622, 2.2887`) and directly transforms the
opening Paris experience and every Eiffel / Seine panorama.

| ID | Type / File | Site | Must-have real-life features | Target tris |
| --- | --- | --- | --- | ---: |
| PA-3.1 | `palais_de_chaillot` (`pa_chaillot.gd`) | `relation 6826569` (0–220 m, wraps the preset eye!) | Twin curved 1937 Art Deco white-limestone wings framing the Parvis des Droits de l'Homme, monumental fluted pilasters, gilded rooftop inscriptions, bronze gilded statues along the terrace balustrade, stepped **Jardins du Trocadéro** & **Fontaine de Varsovie** long reflecting pool with water cannons (`pool_water` + lit night jets) | ~95,000 |
| PA-3.2 | `ecole_militaire` (`pa_ecole_militaire.gd`) | Champ de Mars SE end (`PA-0.4`, 1,280 m — directly behind Eiffel Tower!) | Ange-Jacques Gabriel's 18th-century classical limestone palace: central eight-column giant Corinthian portico, sculpted pediment, steep quadrangular slate pavilion dome (`Pavillon de l'Horloge`), flanking pavilions & Cour d'Honneur closing the Eiffel axial vista | ~65,000 |
| PA-3.3 | `palais_de_tokyo` (`pa_palais_tokyo.gd`) | `ways 79219351, 79219308` (634–690 m) | Twin symmetrical 1937 Art Deco travertine wings (Palais de Tokyo + Musée d'Art Moderne) joined by an open double colonnade framing a monumental stepped terrace, reflecting basin and bronze bas-reliefs overlooking the Seine | ~55,000 |
| PA-3.4 | `musee_quai_branly` (`pa_quai_branly.gd`) | Quai Jacques-Chirac (`PA-0.4`, 730 m) | Jean Nouvel's glazed acoustic garden screen, Patrick Blanc's lush green living-wall administration facade on the quay, and the signature cantilevered ochre/terracotta/burgundy museum boxes floating above pilotis | ~45,000 |
| PA-3.5 | `cathedrale_sainte_trinite` (`pa_sainte_trinite.gd`) | `way 449077939` (902 m, fixes `h=24 -> 37 m`) | Jean-Michel Wilmotte's crisp white Burgundy-limestone walls crowned by **five distinctive matte-gold onion domes** with Orthodox crosses rising above the Left Bank trees right beside Pont de l'Alma | ~35,000 |
| PA-3.6 | `maison_de_la_radio` (`pa_maison_radio.gd`) | `way 229161417` + full ring (`PA-0.4`, 1,305 m, fixes `h=15 -> 68 m`) | Henry Bernard's unmistakable 160 m-diameter circular brushed-aluminium ring on the Seine with radial ribs and its **68 m central rectangular broadcasting tower** | ~55,000 |
| PA-3.7 | `statue_liberte_paris` (`pa_liberte_cygnes.gd`) | Île aux Cygnes west tip (`PA-0.4`, 1,450 m) | 11.5 m dark bronze **Statue of Liberty** replica on its stepped granite pedestal facing west beside Pont de Grenelle (plus optional companion **Flamme de la Liberté** gilded bronze torch at Place de l'Alma) | ~18,000 |
| PA-3.8 | `grand_palais` (`pa_grand_palais.gd`) | Champs-Élysées / Seine (`PA-0.4`, 1,850 m) | Monumental 240 m Beaux-Arts limestone Ionic colonnade front with gilded mosaic frieze, corner **bronze quadriga chariots**, and the iconic **45 m arched sea-green steel-and-glass barrel-vault nave & central domed crossing** glowing warmly at night | ~115,000 |
| PA-3.9 | `petit_palais` (`pa_petit_palais.gd`) | Opposite Grand Palais (`PA-0.4`, 1,920 m) | Charles Girault's Beaux-Arts museum: gilded wrought-iron monumental entrance arch, sweeping Ionic colonnade, corner pavilions, central ribbed zinc-and-slate dome over the peristyle | ~60,000 |
| PA-3.10 | `palais_bourbon` (`pa_palais_bourbon.gd`) | Quai d'Orsay (`PA-0.4`, 2,180 m) | Assemblée Nationale riverfront: **12-column Corinthian temple portico**, triangular sculpted pediment, broad ceremonial stairs flanked by seated allegorical statues facing Place de la Concorde across the Seine | ~50,000 |
| PA-3.11 | `place_de_la_concorde` (`pa_concorde.gd`) | Place de la Concorde (`PA-0.4`, 2,300 m) | **23 m pink-granite Luxor Obelisk** with gleaming gilded pyramidion on its inscribed pedestal, twin dark-bronze & gold **Fontaine des Mers & Fontaine des Fleuves** with pools, 8 corner city-statue pavilions, and Gabriel's twin colonnaded **Hôtel de la Marine & Hôtel de Crillon** framing Rue Royale | ~105,000 |

## Phase 4: Batch B — Historic Core, Seine Palaces, Left Bank, Marais & Cultural Icons (`PA-4`)

Iconic Paris landmarks from 2.4 km to 7.8 km, defining every central Seine panorama, the Axe Historique and streamed
close-up exploration:

| ID | Type / File | Area / Site | Must-have real-life features | Target tris |
| --- | --- | --- | --- | ---: |
| PA-4.1 | `palais_du_louvre` (`pa_louvre_palace.gd` + `pa_louvre_wings.gd`) | Cour Napoléon & Cour Carrée (`PA-0.4`, 3.4 km) | Complete U-shaped **Richelieu, Sully & Denon limestone wings** (split cleanly so `louvre_pyramid` sits open in Cour Napoléon), steep slate mansard pavilions (`Pavillon de l'Horloge`, `Pavillon de Flore`, `Pavillon de Marsan`), Perrault's eastern Colonnade, and the **Arc de Triomphe du Carrousel** with bronze quadriga aligning the Axe Historique | ~135,000 |
| PA-4.2 | `musee_dorsay` (`pa_musee_orsay.gd`) | Quai Anatole-France (`PA-0.4`, 2.7 km) | Victor Laloux's 1900 Beaux-Arts station: rusticated arched limestone river facade, two iconic **giant gilded clocks** (backlit at night), bronze animal sculptures along the parvis, curved iron-and-glass barrel-vault roof | ~75,000 |
| PA-4.3 | `centre_pompidou` (`pa_pompidou.gd`) | Beaubourg (`PA-0.4`, 4.6 km) | Piano & Rogers's high-tech "inside-out" cultural centre: white steel exoskeleton with gerberettes & cross-bracing, iconic **diagonal transparent escalator tube ("caterpillar")** across the west piazza facade, and colour-coded external ducts (blue air, green water, yellow electric, red lifts/stairs) | ~95,000 |
| PA-4.4 | `hotel_de_ville_paris` (`pa_hotel_de_ville.gd`) | Place de l'Hôtel de Ville (`PA-0.4`, 4.6 km) | 110 m Neo-Renaissance limestone Paris City Hall: sculpted niche facade, steeply pitched blue-grey slate corner & central pavilions with ornate dormers, 50 m central clock belfry with gilded spire | ~85,000 |
| PA-4.5 | `conciergerie_palais_justice` (`pa_conciergerie.gd`) | Quai de l'Horloge, Île de la Cité (`PA-0.4`, 4.1 km) | Iconic medieval river silhouette beside Sainte-Chapelle: square **Tour de l'Horloge** (gilded blue-and-gold public clock), circular conical-slate **Tour César**, **Tour d'Argent** & **Tour Bonbec** rising directly from the Seine embankment, plus Palais de Justice Cour de Mai gilded iron gate | ~80,000 |
| PA-4.6 | `eglise_madeleine` (`pa_madeleine.gd`) | Place de la Madeleine (`PA-0.4`, 2.7 km) | Monumental classical Roman-Greek temple closing Rue Royale: 52 twenty-metre fluted Corinthian columns on a 7 m podium, steep front staircase, sculpted Last Judgement pediment, bronze doors | ~70,000 |
| PA-4.7 | `palais_luxembourg` (`pa_luxembourg.gd`) | Jardin du Luxembourg (`PA-0.4`, 3.8 km) | Salomon de Brosse's French Renaissance rusticated limestone palace (French Senate): central Medici ribbed slate dome & lantern, corner pavilions, formal Grand Bassin terrace overlooking the gardens | ~70,000 |
| PA-4.8 | `institut_de_france` (`pa_institut_france.gd`) | Quai de Conti (`PA-0.4`, 3.6 km) | Le Vau's curving Baroque limestone colonnade wings flanking a Corinthian portico and tall ribbed lead-and-gilt cupola aligned directly across Pont des Arts from the Louvre | ~60,000 |
| PA-4.9 | `saint_sulpice` (`pa_saint_sulpice.gd`) | 6e Arrondissement (`PA-0.4`, 3.6 km) | Servandoni's monumental two-storey Doric & Ionic columned west loggia, unmistakable **asymmetrical twin towers** (73 m tall north tower vs 68 m uncompleted south tower), plus Fontaine Saint-Sulpice in the forecourt | ~65,000 |
| PA-4.10 | `saint_eustache` (`pa_saint_eustache.gd`) | Les Halles (`way 53762963`, 4.1 km — fixes `h=10` bug!) | Monumental Gothic-structure / Renaissance-detail basilica: towering 33 m nave, flying buttresses, steep slate roof, crossing flèche and classical two-tier west portico overlooking Nelson Mandela garden | ~65,000 |
| PA-4.11 | `place_vendome` (`pa_vendome.gd`) | `way 227762241` (3.0 km) | **44.3 m green-bronze spiral Colonne Vendôme** topped by Napoleon statue on its granite pedestal, framed by the canted octagonal Mansart limestone-and-slate arcade pavilions | ~45,000 |
| PA-4.12 | `bastille_ensemble` (`pa_bastille.gd`) | Place de la Bastille (`PA-0.4`, 5.9 km) | **50.5 m green-bronze Colonne de Juillet** crowned by the gleaming gilded winged **Génie de la Liberté**, paired with Carlos Ott's sweeping curved glass-and-granite **Opéra Bastille** | ~65,000 |
| PA-4.13 | `gare_de_lyon` (`pa_gare_de_lyon.gd`) | 12e Arrondissement (`PA-0.4`, 6.2 km) | Ornate Beaux-Arts station facade crowned by the iconic **67 m Tour de l'Horloge** square limestone clock tower with four 6.5 m backlit white dials and slate dome lantern | ~65,000 |
| PA-4.14 | `paris_grand_stations` (`pa_stations.gd`) | `PA-0.4` (4.0–5.8 km) | Companion rows/builders for **Gare de l'Est** (grand arched rose-window train-shed facade), **Gare Saint-Lazare** (Beaux-Arts stone frontage & glass concourse) and **Gare d'Austerlitz** | ~85,000 |
| PA-4.15 | `palais_royal_bourse` (`pa_palais_royal.gd`) | 1er–2e (`PA-0.4`, 3.5–3.9 km) | **Palais-Royal** classical arcaded court with Daniel Buren's 260 black-and-white striped marble columns (`Colonnes de Buren`), plus **Bourse de Commerce** domed rotunda & **Palais Brongniart** 64-column Corinthian stock exchange | ~75,000 |
| PA-4.16 | `sorbonne_place_vosges` (`pa_sorbonne_vosges.gd`) | 5e & Marais (`PA-0.4`, 4.4–5.6 km) | **Chapelle Sainte-Ursule de la Sorbonne** (Lemercier's classical ribbed dome & Corinthian portico) and **Place des Vosges** (Henri IV's symmetrical Louis XIII red-brick, limestone-quoin & steep blue-slate arcaded square) | ~75,000 |
| PA-4.17 | `grande_arche` (`pa_grande_arche.gd`) | La Défense (`way 19441489`, 5.1 km, bearing `311°`) | Spreckelsen's **110.9 m hollow white Carrara-marble & dark-glass open cube** turned 6.33° to the Axe Historique, with its tensioned white PTFE **"Nuage" (Cloud) canopy**, sweeping marble grand stairs and exposed panoramic glass elevator tubes | ~50,000 |
| PA-4.18 | `modern_cultural_ring` (`pa_modern_culture.gd`) | Outer cultural ring (`PA-0.4`, 3.2–7.8 km) | **Fondation Louis Vuitton** (Frank Gehry's 12 translucent curving glass sails in Bois de Boulogne), **Bibliothèque François-Mitterrand (BnF)** (four 79 m L-shaped open-book glass/timber towers around sunken forest), **Tribunal de Paris** (Renzo Piano's 160 m stacked white-banded glass boxes), **CNIT** (218 m triangular white concrete vault shell at La Défense), **Philharmonie de Paris** (Jean Nouvel's metallic bird-tiled hall) | ~110,000 (split into individual rows/files as needed to stay <150k per row) |

## Phase 5: Batch C — Paris Skyline Towers (`PA-5`)

All skyline towers live in `scripts/data/pa_tower_specs.gd` (`skyline: true`, independent channel of 12/30/60/110 per
preset — zero icon slots consumed) using `SkyKit` / `TowerSpec` plus bespoke geometry arms where the silhouette is
non-prismatic.

Work in four steps:

1. **Height fixes first:** correct every missing/broken tall building from `PA-0.2` — notably **`Cœur Défense`**
   (`relation 3071676`, `h=1.0 -> 161 m`), **`Tour Panorama`** (`way 115878678`, `lv=33 -> 98 m`), **`Tour
   Beaugrenelle`** (`way 115878658`, `h=- -> 98 m`), and **`Tour First`** (`h=225 -> 231 m`).
2. **Tour Montparnasse (3,307 m, bearing `132.6°` — directly visible behind the Eiffel Tower!):**
   - `210 m` iconic dark bronze-tinted glass-and-anodised-aluminium almond-plan monolith (`way 16406633`), dense vertical
     structural mullions, recessed top observation deck parapet, red aviation `HALO_META` beacons, and vertical night
     office-window glow + subtle top cornice light.
3. **Front de Seine 1970s Cluster (1.19–1.75 km SSW of Trocadéro — directly framing the Eiffel Tower & Pont de
   Bir-Hakeim views!):**
   - ~12 signature 98–100 m modernist slabs/towers: **Tour Totem** (cantilevered stepped concrete/glass blocks), **Tour
     Cristal** (`way 53396320`, 98 m dark chamfered glass), **Hôtel Novotel Paris Tour Eiffel** (`way 115878663`, 98 m),
     **Tour Adagio** (`way 115878705`, 98 m), **Tour Seine** (`way 115878681`, 98 m), **Tour Panorama** (98 m), **Tour
     Beaugrenelle** (98 m), **Tour Keller** (`way 115878685`, 98 m), **Tour Mars**, **Tour Evasion 2000**, **Tour
     Avant-Seine**, **Tour Rive Gauche**, plus **Pullman Paris Montparnasse** (`way 18592415`, 116 m).
4. **La Défense CBD Skyline (4.0–5.4 km NW, bearings `307°–323°`, `radius_m: 8000` — visible directly along the Axe
   Historique through/past the Arc de Triomphe!):**
   - ~24 signature towers: **Tour The Link** (`way 1125041436`, `241 m` twin stepped terraced glass towers), **Tour
     First** (`way 82466977`, `231 m` tapering silver-blue glass + spire), **Tour Hekla** (`way 1112248133`, `220 m`
     Jean Nouvel bronze-and-amber faceted prism with sun-louvre brise-soleil), **Tour Majunga** (`way 158760559`,
     `194 m` layered vertical façade ribbons & sky-loggias), **Tour Total / Coupole** (`190 m` stacked hexagonal-stepped
     drums), **Tour Areva / Engie** (`way 82486190`, `184 m` monolithic black-granite & dark-glass slab), **Tour
     Granite** (`way 19451629`, `184 m` triangular crystalline glass wedge), **Tour CB21** (`way 82467041`, `179 m`
     cruciform glass), **Tour Saint-Gobain** (`way 1069791336`, `178 m` three stacked tilted glass cubes), **Tour D2**
     (`way 82467015`, `175 m` elliptical steel diagrid), **Tour Carpe Diem** (`way 851434516`, `166 m` diamond-faceted
     glass prow), **Tour Légende** (`way 19546127`, `165 m`), **Cœur Défense** (`relation 3071676`, `161 m` twin
     rounded-corner glass towers), **Tour Alto** (`way 758211634`, `160 m` upward-flaring curved fish-scale glass —
     bespoke lofted tower!), **Tour Ariane** (`way 19450182`, `152 m`), **Tour Trinity** (`way 758211633`, `151 m`
     offset glass volumes with external lifts), **Tour Les Poissons** (`way 82323076`, `150 m`), **Tour Dexia**
     (`142 m`), **Europlaza** (`135 m`), **Tour Défense 2000** (`134 m`), **Tour Eqho** (`131 m`), **Tour Franklin**
     (`120 m`), **Tour Séquoia** (`119 m`), **Tour Manhattan** (`110 m` S-curved curtain wall).

Add a clearance test in `tests/paris_landmarks_test.gd` (pattern `nyc_skyscraper_sites_test` / `london_landmarks_test`)
verifying no La Défense or Front de Seine tower's `clear_m` erases a neighbouring tower.

## Phase 6: Seine Bridges (`PA-6`)

The Seine's 37 bridges define Paris's foreground and central river vistas.

- **PA-6.1 Bespoke Pont de Bir-Hakeim (`pa_bridge_bir_hakeim.gd`, ~65,000 tris — DIRECT FOREGROUND, 727 m):**
  - Replaces the unbuilt `conf: 1` `br_paris_pont_de_bir_hakeim` row (`bridge_specs_west_europe.gd:171`).
  - Two-tier 237 m riveted blue-grey steel-arch bridge spanning both arms of the Seine across **Île aux Cygnes**: lower
    roadway + pedestrian promenades flanked by cast-iron arches and Art Nouveau bronze reliefs; iconic colonnaded upper
    **Métro Line 6 steel viaduct** carried on paired cast-iron piers; central stone belvedere on Île aux Cygnes crowned
    by the equestrian *"La France renaissante"* sculpture; warm Parisian globe lamps along both decks at night.
- **PA-6.2 Bespoke Pont Alexandre III (`pa_bridge_alexandre_iii.gd`, ~75,000 tris — 1,830 m):**
  - Replaces the generic `arch_deck` `br_paris_pont_alexandre_iii` row (`bridge_specs_pilot.gd:10`).
  - Single ultra-low sweeping `107.5 m` Beaux-Arts grey-blue steel arch (`40 m` wide) adorned with gilded bronze
    garlands, nymphs & coat-of-arms centrepieces; **four monumental 17 m limestone pylons** at the corners crowned by
    **gilded winged Pegasus / Fame statues** and seated allegorical figures; ornate black-and-gold Art Nouveau
    four-globe candelabrum lamps (`*Lamp` lit warm at night).
- **PA-6.3 Bespoke Pont Neuf (`pa_bridge_neuf.gd`, ~60,000 tris — 3,927 m):**
  - Replaces the unbuilt `conf: 1` `br_paris_pont_neuf` row (`bridge_specs_pilot.gd:29`).
  - Paris's oldest standing bridge (`238 m`): twelve warm-limestone semicircular arches (`7` north arm + `5` south arm)
    straddling the western tip of Île de la Cité; triangular cutwater piers topped by semicircular stone bastion
    balconies (*demi-lunes*) with benches; sculpted mascaron cornice; central terre-plein with the bronze equestrian
    statue of **Henri IV**; vintage cast-iron Parisian lamp posts.
- **PA-6.4 Bespoke Pont d'Iéna (`pa_bridge_iena.gd`, ~40,000 tris — DIRECT PRESET AXIS, 370 m):**
  - Replaces the generic `masonry` `br_paris_pont_d_iena` row (`bridge_specs_pilot.gd:19`).
  - Five equal `28 m` dressed-limestone elliptical arches (`155 m` long, `35 m` wide) linking Palais de Chaillot to the
    Eiffel Tower; sculpted Imperial Eagles on pier spandrels; **four monumental stone equestrian warrior statues**
    (Gallic, Roman, Arab, Greek) on abutment pedestals; dark-green Parisian balustrade lamps.
- **PA-6.5 Bespoke Passerelle Debilly (`pa_bridge_debilly.gd`, ~35,000 tris — DIRECT FOREGROUND, 604 m):**
  - Replaces the unbuilt `conf: 1` `br_paris_passerelle_debilly` row (`bridge_specs_west_europe.gd:183`).
  - 1900 Exposition Universelle `125 m` green-painted riveted steel through-arch pedestrian bridge (`8 m` wide) with
    flanking masonry piers faced in sea-green ceramic tiles and wrought-iron railing lamps linking Palais de Tokyo to
    Quai Branly.
- **PA-6.6 Upgrade & complete remaining Seine bridges (`bridge_specs_pilot.gd` & `bridge_specs_west_europe.gd`):**
  - Raise verified `conf: 1 -> 2`: **Passerelle Léopold-Sédar-Senghor**, **Pont de Sully**, **Pont de Tolbiac**, and
    **Passerelle Simone-de-Beauvoir** (candidate for a short bespoke lenticular double-wave steel builder!).
  - Tune existing `conf: 2` bridges: **Pont de l'Alma** (with Zouave flood-gauge statue on the north pier), **Pont de la
    Concorde**, **Pont Royal**, **Pont des Arts** (timber plank deck, dark-green iron railings & twin-globe lamps
    linking Louvre and Institut de France), **Pont Mirabeau**, **Pont Saint-Michel**, **Pont au Change**, **Pont
    d'Arcole**, **Pont d'Austerlitz**, **Pont du Garigliano**.
  - Add missing central Seine rows (measured in `PA-0.4`): **Pont de Grenelle**, **Pont des Invalides**, **Pont du
    Carrousel**, **Pont Notre-Dame**, **Petit-Pont**, **Pont au Double**, **Pont de l'Archevêché**, **Pont de la
    Tournelle**, **Pont Marie**, **Pont Louis-Philippe**.
  - Set `tier` priorities so Ultra's 8 parametric bridge slots favour the visible Seine sequence around the active eye.
- Validation: `bridge_specs_test`, `bridge_param_test`, `bridge_select_test`, `bridge_connection_test`,
  `bridge_arches_test`.

## Phase 7: Paris city fabric (`PA-7`)

Files: new `scripts/generation/architecture_cities_paris.gd` (called from `building_era.gd:408` via a one-line
dispatch), `scripts/generation/architecture_paris.gd`, `scripts/generation/city_styles.gd`,
`scripts/render/city_detail.gd`, `scripts/generation/roof_clutter.gd`, `scripts/generation/tower_looks.gd`,
`docs/architecture-styles.md`, `tests/architecture_test.gd`.

- **PA-7.1 Expand Paris zone & enable far-district styling (`city_styles.gd`):**
  - Widen Paris `ZONES` radius from `5.5 km -> 10.5 km` (`city_styles.gd:21`) so La Défense (`9.24 km`), Bois de
    Boulogne (`6.9 km`), Front de Seine and Bercy all sit inside Paris's city zone (while verifying `ArchitectureData`
    inner-suburb fallback compatibility).
  - Add `"paris"` to `FAR_DISTRICT_CITIES` (`city_styles.gd:572`) so La Défense glass towers, Front de Seine slabs,
    Montmartre faubourg roofs and Le Marais stone read accurately in `FarCityBuilder`.
- **PA-7.2 New & refined Parisian architectural rows (`architecture_paris.gd`):**
  - Refine **`haussmann`**: crisp warm Lutetian limestone (`#DDD0B2`, `#D5C5A3`, `#E2D6BC`), rusticated stone ground
    storeys with dark timber/brass shopfronts & striped Parisian café awnings, continuous wrought-iron 2nd-floor (*étage
    noble*) & 5th-floor balconies, tall French windows with black railings, standing-seam blue-grey **Parisian zinc
    mansards** (`#5C6773`, `#68737F`) with dormers.
  - Add **`paris_royal`**: 17th–18th c. Grand Siècle classical limestone with ground-floor arcades, giant pilasters and
    steep blue-black Angers slate mansards — for **Place Vendôme, Rue de Rivoli, Palais-Royal, Place de la Concorde,
    Île Saint-Louis & Saint-Germain**.
  - Add **`paris_marais`**: Le Marais & Place des Vosges aristocratic stone-and-brick (*brique et pierre*) hôtels
    particuliers, tall carriage gates (*portes cochères*) and shuttered limestone/render facades.
  - Refine **`paris_post_haussmann`** (Belle Époque bow windows, carved stone bay projections & corner cupolas of
    16e/Trocadéro/Passy/8e), **`paris_faubourg`**, **`paris_hbm`** (1920s–30s red/ochre brick perimeter ring),
    **`paris_modern`** (Front de Seine, La Défense, 13e/Bercy) and **`paris_pavillon`**.
- **PA-7.3 Expand `city_styles.gd` Paris districts (from 5 to ~18):**
  - Keep existing: Le Marais (`paris_marais`), Montmartre (`paris_faubourg`), La Défense (`paris_modern`), Olympiades
    (`paris_modern`), Front de Seine (`paris_modern`).
  - Add measured district circles: **Trocadéro & Passy (16e)** (`paris_post_haussmann`), **Champs-Élysées & Triangle
    d'Or (8e)** (`haussmann` / `paris_post_haussmann`), **Opéra & Grands Boulevards (2e–9e)** (`haussmann`), **Place
    Vendôme & Rue de Rivoli (1er)** (`paris_royal`), **Île de la Cité & Île Saint-Louis** (`paris_royal`),
    **Saint-Germain-des-Prés (6e)** (`paris_royal` / `paris_faubourg`), **Quartier Latin (5e)** (`paris_faubourg`),
    **Invalides & Gros-Caillou (7e)** (`haussmann`), **Montparnasse** (`paris_modern` core + `haussmann`), **Bastille &
    Canal Saint-Martin (10e–11e)** (`paris_faubourg`), **Paris Rive Gauche & Bercy (13e–12e)** (`paris_modern`), **HBM
    Outer Belt (Porte de Saint-Cloud / Porte d'Orléans / Porte de Clignancourt)** (`paris_hbm`).
- **PA-7.4 `paris_rule` in `architecture_cities_paris.gd`:**
  - Because 63 % of detailed Paris buildings are untyped `building=yes`, decide by local district circle first, then
    height/levels, footprint area, roof shape and `heritage` so Trocadéro/16e gets Belle Époque bow-window stone,
    Île Saint-Louis/Vendôme gets classical arcaded stone, Montmartre/Marais stays intimate pre-Haussmann, and tall
    modern slabs never sprout mansard roofs.
- **PA-7.5 Iconic Parisian roofscape (`roof_clutter.gd`):**
  - Add authentic ranks of **ochre terracotta Parisian chimney pots (`mitrons de cheminée`)** lined along stone chimney
    breasts on `haussmann`, `paris_post_haussmann`, `paris_royal` and `paris_faubourg` roofs — Paris's single most
    distinctive rooftop visual signature.
- **PA-7.6 Detail budget (`CityDetail.CITIES`):**
  - Add `"paris"` to `CityDetail.CITIES` (`scripts/render/city_detail.gd:18`, bump `VERSION`), unlocking High `450 m` /
    Ultra `900 m` roofline detail rings and `14,000` extruded buildings on desktop Ultra; benchmark with
    `tools/build_bench.gd` against Stockholm/London budgets.

Validation: `architecture_test`, `city_detail_test`, `roof_clutter_test`, `facade_relief_test`, `party_walls_test`.

## Phase 8: Seine water, embankments, vessels, municipal trees & atmosphere (`PA-8`)

- **PA-8.1 Seine river water & stone quays (`water_surface.gd`):**
  - Add a `seine(lat, lon)` box (`48.78..48.94, 2.18..2.46`) in `WaterSurface.inland_palette` tuned to the Seine's
    signature muted **olive-jade river green** with calm surface ripple and crisp golden-hour & night monument
    reflections.
  - Verify the iconic two-tier Lutetian-limestone **Berges de Seine** quay walls (upper parapet + lower cobbled port
    promenade) sit flush against the Seine water datum without floating gaps or stray coastal stairs.
- **PA-8.2 Seine vessels (`scripts/generation/vessels/`, `quay_moorings.gd`):**
  - Block ocean cruise liners / ro-pax ferries from spawning anywhere on the Seine.
  - Add two iconic Parisian river craft:
    - **Bateaux Mouches / Bateaux Parisiens**: low-bridge-clearance, wide, panoramic curved-glass sightseeing vessels
      with open aft upper deck and **twin bright warm-white bank-illuminating floodlights** at night.
    - **Moored Péniches (38 m Freycinet river barges)**: dark steel hulls with cream/green wheelhouses, brass portholes,
      deck planters & string-lit floating café terraces moored along Port de la Bourdonnais, Port de Suffren, Port des
      Champs-Élysées, Port de Solférino and Quai de Conti.
- **PA-8.3 Municipal Paris trees & formal gardens (`tree_species.gd`, `heritage_zones.gd`):**
  - `paris_detailed.osmb` already has **7,644 OSM-tagged trees (96.6 %)**: 2,494 `Platanus` (Plane), 2,039 `Aesculus`
    (Horse Chestnut — currently mapped to generic `lime`!), 935 `Tilia` (Lime), 469 `Sophora/Styphnolobium`.
  - Add a dedicated **`"horse_chestnut"`** species in `tree_species.gd` (broad, dense dome crown with dark palmate
    foliage and subtle spring cream candle blossoms) and map `"aesculus": "horse_chestnut"`.
  - Refine `"plane"` (`Platanus`) for tall boulevard avenues along the Seine quays & Champs-Élysées, and add a
    `"paris"` fallback tree mix (`plane 0.38`, `horse_chestnut 0.28`, `lime 0.20`, `oak 0.08`, `cypress 0.06`).
  - Keep formal sightlines clear of stray procedural trees via `tree_rect`: **Champ de Mars** central lawn, **Trocadéro
    Esplanade**, **Esplanade des Invalides**, **Cour Napoléon**, **Place de la Concorde**, **Place Vendôme**, and
    **Jardin des Tuileries** central gravel axis.
- **PA-8.4 Île-de-France atmosphere (`atmosphere_rig.gd`, `haze_rig.gd`):**
  - Verify Paris's UTC+1 (CET) / CEST solar clock and tune soft pearlescent-blue-silver Île-de-France atmospheric
    perspective so foreground warm Lutetian limestone, midground zinc mansards, and distant Montmartre / La Défense
    silhouettes separate cleanly at golden hour and noon.

Validation: `coastal_water_test`, `far_water_palette_test`, `vessel_models_test`, `canopy_vegetation_test`,
`tree_lod_test`, `sky_test`, `haze_test`.

## Phase 9: Parisian streets, street furniture, vehicles & transit (`PA-9`)

- **PA-9.1 Iconic Parisian street furniture (`street_furniture.gd` new `"paris"` family):**
  - Route `city == "haussmann"` (or `iso == "FR"` in Paris) to family `"paris"` and enable `shows_entrances("paris")`.
  - **Hector Guimard Art Nouveau Métro Entrance** (curved bottle-green cast-iron arch, side balustrades, glowing
    amber-red glass globe lanterns & `"METROPOLITAIN"` plaque) and **classic red `"M"` Val d'Osne pole** at mapped
    `railway=subway_entrance` nodes (7 in `paris_detailed.osmb`, dozens across central Paris).
  - **Colonne Morris** (bottle-green cylindrical poster tower with scalloped finial dome & warmly backlit poster drum)
    placed at boulevard intersections & cultural plazas.
  - **Fontaine Wallace** (bottle-green cast-iron four-caryatid drinking fountain) at `amenity=drinking_water` nodes &
    squares.
  - **Bouquinistes de Paris** (dark-green hinged metal bookstalls perched along the stone parapets of the central Seine
    quays — Quai de Conti, Quai Malaquais, Quai Voltaire, Quai de la Mégisserie, Quai de Montebello).
  - **Davioud Parisian Streetlamps** (fluted dark bronze-green cast-iron columns with hexagonal warm glass lanterns) and
    **Davioud curved wooden-slat park benches** along boulevards, Champ de Mars & Tuileries.
  - **Vélib' bikeshare docks** at `amenity=bicycle_rental` POIs (following Miami's bikeshare hook in
    `street_furniture.gd:113`).
- **PA-9.2 Elevated Paris Métro Line 6 & RER C (`train_specs.gd`):**
  - Add `"haussmann"` to `TrainSpecs.METRO_REGIONS` (`train_specs.gd:146`) with an authentic RATP white / jade-green /
    Île-de-France blue **MP 73 / MP 89** rubber-tyred metro livery (`paris_metro`) so live trains run across the
    elevated **Pont de Bir-Hakeim viaduct** and Passy/Grenelle (`ways 404688617, 404688618, 371959822, 390827578`) right
    in the Eiffel Tower foreground!
  - Add **`paris_rer`** double-deck blue/white/carmillon commuter EMU livery for **RER C** along the Left Bank
    Champ-de-Mars line (`ways 24868961, 862078775, 1185696933`) and main-line throats into Gare du Nord & Gare de Lyon.
- **PA-9.3 RATP / IDFM City Buses (`transit_vehicles.gd`, `car_specs.gd`):**
  - Upgrade Paris's bus livery from flat jade green (`transit_vehicles.gd:52`) to crisp **Île-de-France Mobilités white
    + sky-blue / RATP jade-green** low-floor urban bus with dark panoramic glass band and glowing amber route display at
    night.
- **PA-9.4 Parisian vehicle fleet & road markings (`car_fleet.gd`, `road_markings.gd`):**
  - Add a `"paris"` car fleet (compact European/French hatchbacks, dark sedans with illuminated green/red `"TAXI
    PARISIEN"` roof sign, and Parisian motor scooters); confirm right-hand traffic, wide Parisian white striped
    crosswalks (*passages piétons*) and yellow bus-lane markings.

Validation: `street_furniture_test`, `car_fleet_test`, `bus_stop_test`, `road_markings_test`, `train_test`,
`rail_viaduct_test`.

## Phase 10: "La Ville Lumière" night lighting (`PA-10`) & review rounds (`PA-11`)

- **PA-10 Cohesive Night Pass (`LandmarkLights`, `--preset=3`):**
  - Tune every Paris landmark, bridge, vessel and skyline tower together so night frames unmistakably read as *La Ville
    Lumière*:
    - **Eiffel Tower:** golden-amber architectural flood wash from ground to 276 m, sparkling white-gold lattice accents,
      **dual sweeping white summit searchlight beams**, red aviation beacon at 330 m.
    - **Trocadéro & Pont d'Iéna:** lit Warsaw Fountains water jets, Palais de Chaillot warm travertine uplights, warm
      Parisian bridge globes.
    - **Pont de Bir-Hakeim & Passerelle Debilly:** warm deck & colonnade lighting, lit Métro Line 6 train cabins crossing
      the Seine.
    - **Pont Alexandre III, Grand Palais & Concorde:** Art Nouveau four-globe candelabra + gilded Pegasus uplights,
      warmly glowing Grand Palais glass barrel vault, uplit Luxor Obelisk & lit Concorde fountains.
    - **Louvre & Orsay:** warm amber-gold light radiating from inside the **Louvre Pyramid**, uplit Palais du Louvre
      pavilions & Carrousel arch; glowing giant gilded clocks on **Musée d'Orsay**.
    - **Île de la Cité & Left Bank:** Notre-Dame warm blond limestone floodlights & glowing stained-glass rose windows;
      Sainte-Chapelle sapphire-ruby lancet glow; Conciergerie turrets reflecting on the Seine; Pont Neuf warm lamps;
      Les Invalides glowing gold dome; Panthéon illuminated peristyle; Institut de France uplit cupola.
    - **Montmartre, Opéra & Grands Boulevards:** luminous white **Sacré-Cœur** dome crown visible across Paris; Palais
      Garnier gilded loggia warmth; Hôtel de Ville & Place Vendôme warm floods; backlit **Colonnes Morris** & glowing
      red-amber **Guimard Métro** globes.
    - **Seine:** **Bateaux Mouches** twin floodlights sweeping the dark olive-jade river; string-lit moored péniches.
    - **Skyline:** **Tour Montparnasse** lit vertical bands, crown glow & red aviation beacons; **Grande Arche**
      illuminated inner marble frame; **La Défense** towers (The Link, First, Hekla, Majunga, D2, Alto, Carpe Diem,
      Granite) lit office windows & red aviation beacons.
- **PA-11 Review rounds, scorecard, docs & performance:**
  - Capture rounds `paris-r1`…`paris-rN` into `visual-plan/reviews/paris-rN-<date>/` at the frozen eyes. Lay every
    landmark's day & night model sheet beside its Wikimedia Commons reference photo (`tools/landmark_compare_sheets.py`)
    and beside an in-world eye; log mismatches, fix, and recapture.
  - Update `docs/fidelity-scorecard.md`, `docs/architecture-styles.md`, `docs/paris-landmark-sources.md` and README
    lists.
  - Performance: `tools/perf_baseline.gd` and `tools/build_bench.gd` on Paris at presets 2 and 3 (cold, cached, fly),
    verifying frame time at Trocadéro, Pont Alexandre III and Pont des Arts where the densest geometry is in view; run
    `lod_test`, `memory_budget_test`, `impostor_test`, `landmark_ultra_lod_test`.

## Captures and eyes

Two capture sets per round (bundled Trocadéro snapshot vs streamed central/skyline eyes):

**Set A — bundled Trocadéro / Eiffel / Seine centre (`--keep_centre`, uses `paris_*.osmb`):**
```
tools/godot_bg.sh --path . --script tools/capture_presets.gd --position 4000,4000 -- --tag=paris-rN
  --preset=3 --pin=48.8622,2.2887 --places=paris --times=golden,noon,night,late,roofs --keep_centre
  --looks="<Set A eyes>"
```

**Set B — streamed close eyes across central Paris & La Défense (no `--keep_centre`, live Overpass cached after first
run):** same command with `--tag=paris-rN-close` and Set B eyes.

**Model sheets:** `tools/capture_landmarks.gd --types=<types> --tag=pa_lm_rN` (day and `--night`), then
`python3 -I tools/landmark_compare_sheets.py --tag=pa_lm_rN`.

Candidate eyes (verify clear of footprints in `PA-0.1`, then freeze; format `lat,lon,height_m,bearing,pitch`):

| Set | Eye | Candidate | Shows |
| --- | --- | --- | --- |
| A | Preset vantage (Palais de Chaillot esplanade) | `48.8622,2.2887,6.0,142,4` | Trocadéro fountains, Pont d'Iéna, Eiffel Tower, Champ de Mars, École Militaire, Montparnasse |
| A | Trocadéro looking back at Palais de Chaillot | `48.8612,2.2899,4.0,318,8` | Palais de Chaillot twin curved Art Deco wings, terrace statues & fountains |
| A | Pont d'Iéna mid-span looking SE | `48.8598,2.2921,10.0,136,14` | Eiffel Tower piers/arches close-up, Pont d'Iéna statues, Seine & Bateaux Mouches |
| A | Pont de Bir-Hakeim looking NE | `48.8557,2.2876,12.0,55,8` | Bir-Hakeim double-deck viaduct, elevated Métro Line 6, Eiffel Tower, Palais de Tokyo |
| A | Champ de Mars lawn looking NW | `48.8550,2.2995,2.0,315,12` | Eiffel Tower full silhouette, Pont d'Iéna, Palais de Chaillot |
| A | Champ de Mars looking SE | `48.8560,2.2980,2.0,135,5` | École Militaire axial facade & Tour Montparnasse skyline |
| A | Quai Branly / Passerelle Debilly looking E | `48.8625,2.2968,10.0,88,4` | Passerelle Debilly, Palais de Tokyo, Cathédrale de la Sainte-Trinité gold domes, Pont de l'Alma |
| A | High Eiffel / Seine panorama | `48.8622,2.2887,160,105,-8` | Eiffel Tower, Invalides, Grand Palais, Concorde, Louvre, Notre-Dame, Montparnasse, Haussmann roofscape |
| A | High NW panorama toward La Défense | `48.8622,2.2887,150,322,-5` | Arc de Triomphe, Axe Historique, Grande Arche & La Défense tower cluster |
| B | Pont Alexandre III south approach | `48.8628,2.3135,4.0,5,6` | Pont Alexandre III gilded Pegasus pylons & lamps framing Grand Palais & Petit Palais |
| B | Place de la Concorde looking N & W | `48.8656,2.3212,2.5,296,5` | Luxor Obelisk, fountains, Champs-Élysées to Arc de Triomphe, Hôtel de la Marine & Madeleine |
| B | Cour Napoléon (Louvre Pyramid) | `48.8610,2.3347,2.5,95,8` | Louvre Pyramid & fountains framed by Palais du Louvre wings & Pavillon de l'Horloge |
| B | Pont des Arts mid-span | `48.8584,2.3376,10.0,198,6` | Institut de France cupola, Seine quays, bouquinistes, Pont Neuf & Île de la Cité |
| B | Pont de l'Archevêché / Quai de Montebello | `48.8515,2.3502,3.0,350,12` | Notre-Dame de Paris restored limestone, flying buttresses, flèche & Seine |
| B | Pont Neuf / Quai de la Mégisserie | `48.8576,2.3426,3.0,122,8` | Pont Neuf arches, Conciergerie medieval turrets & Sainte-Chapelle spire |
| B | Place de l'Opéra | `48.8707,2.3322,2.5,342,10` | Palais Garnier Beaux-Arts facade, gilded Apollo, Guimard Métro entrance & Haussmann boulevards |
| B | Rue Soufflot approaching Panthéon | `48.8466,2.3435,2.5,98,8` | Panthéon Corinthian portico (verifying fixed west orientation!) & peristyle dome |
| B | Place Beaubourg (Centre Pompidou) | `48.8607,2.3510,2.5,82,14` | Centre Pompidou exoskeleton, escalator caterpillar & coloured ducts |
| B | Square Louise-Michel (Montmartre) | `48.8848,2.3431,2.5,0,16` | Sacré-Cœur white travertine domes & stepped stairs |
| B | Esplanade de La Défense looking WNW | `48.8895,2.2440,8.0,296,10` | Grande Arche, Tour First, Tour The Link, Hekla, Majunga, Alto & D2 skyline |

## Order and size

1. **Phase 0 + Phase 1 + Phase 2 (`PA-0`, `PA-1`, `PA-2`) + `PA-3.1` (Palais de Chaillot) + `PA-6.1` (Pont de
   Bir-Hakeim) + `PA-6.4` (Pont d'Iéna) + `PA-6.5` (Passerelle Debilly).**
   Immediately transforms the Trocadéro preset vantage (day & night), lights the Eiffel Tower and all 10 existing icons,
   fixes Panthéon's 90° orientation, and resolves every missing foreground bridge.
2. **Rest of Phase 3 (`PA-3.2`–`PA-3.11`) + `PA-6.2` (Pont Alexandre III).**
   Completes the entire Eiffel–Champ de Mars–École Militaire–Grand Palais–Invalides–Concorde–Champs-Élysées corridor.
3. **Phase 4 (`PA-4` Historic Core & Icons) + `PA-6.3` (Pont Neuf) + `PA-6.6` (remaining Seine bridges).**
   Completes Palais du Louvre, Musée d'Orsay, Centre Pompidou, Hôtel de Ville, Conciergerie, Madeleine, Luxembourg,
   Institut de France, Saint-Sulpice, Saint-Eustache, Place Vendôme, Bastille, Gare de Lyon, Grande Arche and the modern
   cultural ring.
4. **Phase 5 (`PA-5` Skyline Towers).**
   Adds Tour Montparnasse, Front de Seine and La Défense (~38 towers) while fixing `Cœur Défense h=1.0` and all missing
   tall heights.
5. **Phase 7 (`PA-7` City Fabric) + Phase 8 (`PA-8` Seine/Boats/Trees/Atmosphere) + Phase 9 (`PA-9` Guimard/Morris/
   Wallace/Bouquinistes/Métro 6/RER/RATP).**
   Elevates every boulevard, roofscape, river quay and transit line between landmarks to the same super-realistic bar.
6. **Phase 10–11 (`PA-10` *La Ville Lumière* night pass, `PA-11` Review rounds, scorecard, perf).**
7. Every phase ends with its tests passing and a capture round, so work can stop or ship cleanly after any phase.

## Open decisions

| Decision | Recommendation |
| --- | --- |
| Raise `eiffel` `ultra_registry_limit` / `ultra_total_limit` to `46 / 54` | Yes — matches Stockholm (`48 / 56`) & London (`42 / 50`) so Ultra shows both Trocadéro/central Paris landmarks and 8 parametric Seine bridges |
| Widen Paris `CityStyles.ZONES` radius from `5.5 km -> 10.5 km` and add `"paris"` to `FAR_DISTRICT_CITIES` | Yes — otherwise La Défense (`9.24 km`) and Bois de Boulogne sit outside Paris's city zone and far districts never apply |
| Add `"paris"` to `CityDetail.CITIES` (`PA-7.6`) | Yes — after `PA-7.1`–`PA-7.5`, if `tools/build_bench.gd` stays within Stockholm/London build-time and peak-memory budgets |
| Re-cut `paris_ring2500.osmb` (`PA-0.3`) | Yes — currently truncates at 800 highways |
| Add a second curated Paris `PresetViews` vantage (e.g. Pont Alexandre III or Pont des Arts / Île de la Cité) & re-bake `assets/preset_thumbs/paris.jpg` | Only on explicit user request |
| Charles de Gaulle / Orly Airport terminals & Palace of Versailles upgrades | Out of scope (airports belong to the capital-airports pipeline; Versailles is 16 km SW and already modelled) |

## Verification

- Headless tests in the background after each phase:
  `tools/run_tests.sh landmark paris bridge architecture roof facade canopy tree water vessel car_fleet street train rail`
  (or individual tests via `tools/godot_bg.sh --headless --path . --script tests/<name>_test.gd`). Treat any
  `SCRIPT ERROR:` as a failure even on exit code 0.
- `tools/check_class_size.sh` after every added or edited class under `scripts/` (hard cap: 1,000 lines/file).
- `tools/godot_bg.sh --headless --path . --script tests/host_policy_test.gd` after any data or reference script change.
- Windowed tests (`tests/screenshot_test.gd`, `tests/world_cache_test.gd`) batched once at the end, in the background.
- **Done means:** every existing and new Paris landmark matches its Wikimedia Commons reference photo in silhouette,
  proportion, Lutetian limestone / zinc / iron / glass material and night illumination; Pont de Bir-Hakeim, Pont
  Alexandre III, Pont Neuf, Pont d'Iéna and Passerelle Debilly render as bespoke structures; Tour Montparnasse, Front de
  Seine and La Défense stand at true heights; Paris streets show district-accurate Haussmann, Belle Époque, Royal and
  Marais fabrics with terracotta chimney rows, Guimard Métro entrances, Morris columns, Wallace fountains, Bouquinistes,
  elevated Métro Line 6 trains, Bateaux Mouches, and Horse Chestnut / Plane avenues; all listed tests and
  `check_class_size.sh` pass; and performance stays within budget of `paris-r0`.
