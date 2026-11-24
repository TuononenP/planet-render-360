# Paris landmark & skyline sources

Evidence register for `PLAN_Paris_super_realistic.md` (`PA-0.2`, `PA-0.4`, `PA-0.6`). Coordinates, OSM IDs and
snapshot height anomalies were audited against `assets/osm_snapshots/paris_detailed.osmb` and
`assets/osm_snapshots/paris_far.osmb` (centred on the Palais de Chaillot / Trocadéro preset vantage `48.8622, 2.2887`,
OSM base `2026-11-04`).

## 1. Snapshot height & tag audit (`PA-0.2`)

- `paris_detailed.osmb`: 21,062 elements — 5,269 buildings (3,329 `building=yes` = 63 %, only 75 explicit `height` =
  1.4 %, 3,406 `building:levels`), 523 building relations, 221 `building:part`s, 64 bridges, 56 railways (incl. elevated
  **Métro Line 6** `ways 404688617, 404688618, 371959822, 390827578` and RER C), 7,912 trees (7,644 = 96.6 % with
  genus/species: 2,494 `Platanus`, 2,039 `Aesculus`, 935 `Tilia`, 469 `Sophora/Styphnolobium`), 7 `subway_entrance`s.
- `paris_far.osmb`: 17,681 elements — 1,520 buildings (766 heights), 15,721 `building:part`s.
- `paris_ring2500.osmb`: 800 highways (hits old cap; deferred to offline snapshot re-bundle).

### Notable OSM height / level anomalies fixed by bespoke models or `PaTowerSpecs`

| Building | OSM element | OSM `height` / `levels` | Real height | Fix |
| --- | --- | --- | ---: | --- |
| Cœur Défense | `relation 3071676` | `1.0 m` / `40 lv` | 161 m | `PaTowerSpecs` (`coeur_defense`) |
| Église Saint-Eustache | `way 53762963` | `10.0 m` / `6 lv` | 45 m | Bespoke (`saint_eustache`) |
| Maison de la Radio | `way 229161417` | `15.0 m` / `-` | 68 m | Bespoke (`maison_de_la_radio`) |
| Cathédrale de la Sainte-Trinité | `way 449077939` | `24.0 m` / `-` | 37 m | Bespoke (`cathedrale_sainte_trinite`) |
| Tour Panorama (Front de Seine) | `way 115878678` | `-` / `33 lv` | 98 m | `PaTowerSpecs` (`tour_panorama`) |
| Tour Beaugrenelle | `way 115878658` | `-` / `-` | 98 m | `PaTowerSpecs` (`tour_beaugrenelle`) |
| Tour Égée (La Défense) | `way 82486351` | `-` / `40 lv` | 155 m | `PaTowerSpecs` (`tour_egee`) |
| Tour First (La Défense) | `way 82466977` | `225 m` / `52 lv` | 231 m | `PaTowerSpecs` (`tour_first`) |
| Palais de Chaillot | `relation 6826569` | `30.0 m` / `5 lv` | 28 m | Bespoke (`palais_de_chaillot`) |

## 2. Existing 10 Paris landmarks (upgraded in `PA-2`)

| Type | Name | Lat, Lon | Height (m) | Yaw | Registry |
| --- | --- | --- | ---: | ---: | --- |
| `eiffel` | Eiffel Tower | `48.8584, 2.2945` | 330.0 | model `-44.4°` | `LocationData` (primary, `46/54` Ultra) |
| `arc_de_triomphe` | Arc de Triomphe | `48.8738, 2.2950` | 50.0 | `115.5°` | `LandmarkRegistryWestEurope` |
| `les_invalides` | Les Invalides | `48.8553, 2.3126` | 107.0 | `0.0°` | `LandmarkRegistryWestEurope` |
| `louvre_pyramid` | Louvre Pyramid | `48.8610, 2.3358` | 21.6 | `19.0°` | `LandmarkRegistryWestEurope` |
| `notre_dame` | Notre-Dame de Paris | `48.8530, 2.3499` | 96.0 | `15.0°` | `LandmarkRegistryWestEurope` |
| `sacre_coeur` | Sacré-Cœur | `48.8867, 2.3431` | 83.0 | `0.0°` | `LandmarkRegistryWestEurope` |
| `pantheon_paris` | Panthéon, Paris | `48.8462, 2.3464` | 83.0 | `-84.0°` (fixed west portico) | `LandmarkRegistryWestEurope` |
| `sainte_chapelle` | Sainte-Chapelle | `48.8554, 2.3450` | 75.5 | `10.0°` | `LandmarkRegistryWesternHistoric` |
| `palais_garnier` | Palais Garnier | `48.8719, 2.3317` | 56.0 | `-19.0°` | `LandmarkRegistryWesternHistoric` |
| `gare_du_nord` | Gare du Nord | `48.880218, 2.355021` | 39.4 | `17.1°` | `LandmarkRegistryCapitalStations` |

## 3. New Paris bespoke landmarks & bridges (`LandmarkRegistryParis`)

| Type | Name | Lat, Lon | Height (m) | Yaw | Priority |
| --- | --- | --- | ---: | ---: | ---: |
| `palais_de_chaillot` | Palais de Chaillot | `48.86225, 2.28858` | 28.0 | `-44.2°` | 9 |
| `ecole_militaire` | École Militaire | `48.8526, 2.3036` | 38.0 | `-44.2°` | 7 |
| `palais_de_tokyo` | Palais de Tokyo | `48.8643, 2.2971` | 20.0 | `-26.0°` | 3 |
| `musee_quai_branly` | Musée du Quai Branly | `48.8609, 2.2979` | 22.0 | `-18.0°` | 3 |
| `cathedrale_sainte_trinite` | Cathédrale de la Sainte-Trinité | `48.86188, 2.30101` | 37.0 | `0.0°` | 3 |
| `maison_de_la_radio` | Maison de la Radio et de la Musique | `48.8524, 2.2782` | 68.0 | `0.0°` | 3 |
| `statue_liberte_paris` | Statue of Liberty (Île aux Cygnes) | `48.8501, 2.2797` | 17.5 | `-142.0°` | 3 |
| `grand_palais` | Grand Palais | `48.8661, 2.3125` | 45.0 | `5.0°` | 7 |
| `petit_palais` | Petit Palais | `48.8660, 2.3146` | 35.0 | `-85.0°` | 3 |
| `palais_bourbon` | Palais Bourbon (Assemblée Nationale) | `48.8619, 2.3186` | 28.0 | `25.0°` | 3 |
| `place_de_la_concorde` | Place de la Concorde | `48.8656, 2.3212` | 26.5 | `25.0°` | 5 |
| `palais_du_louvre` | Palais du Louvre | `48.8610, 2.3358` | 36.0 | `19.0°` | 7 |
| `musee_dorsay` | Musée d'Orsay | `48.8600, 2.3266` | 32.0 | `18.0°` | 5 |
| `centre_pompidou` | Centre Pompidou | `48.8606, 2.3522` | 42.0 | `15.0°` | 5 |
| `hotel_de_ville_paris` | Hôtel de Ville de Paris | `48.8565, 2.3522` | 50.0 | `15.0°` | 3 |
| `conciergerie_palais_justice` | Conciergerie | `48.8560, 2.3456` | 47.0 | `14.0°` | 3 |
| `eglise_madeleine` | Église de la Madeleine | `48.8700, 2.3243` | 30.0 | `25.0°` | 3 |
| `palais_luxembourg` | Palais du Luxembourg | `48.8483, 2.3372` | 34.0 | `10.0°` | 3 |
| `institut_de_france` | Institut de France | `48.8573, 2.3371` | 40.0 | `18.0°` | 3 |
| `saint_sulpice` | Église Saint-Sulpice | `48.8509, 2.3348` | 73.0 | `98.0°` | 3 |
| `saint_eustache` | Église Saint-Eustache | `48.86348, 2.34517` | 45.0 | `16.0°` | 3 |
| `place_vendome` | Place Vendôme & Colonne Vendôme | `48.86746, 2.32944` | 44.3 | `20.0°` | 3 |
| `bastille_ensemble` | Colonne de Juillet & Opéra Bastille | `48.8531, 2.3691` | 50.5 | `0.0°` | 3 |
| `gare_de_lyon` | Paris-Gare-de-Lyon | `48.8448, 2.3735` | 67.0 | `42.0°` | 3 |
| `gare_de_lest` | Paris-Gare-de-l'Est | `48.8768, 2.3592` | 38.0 | `-8.0°` | 3 |
| `palais_royal_bourse` | Palais-Royal & Colonnes de Buren | `48.8636, 2.3371` | 26.0 | `19.0°` | 3 |
| `place_des_vosges` | Place des Vosges | `48.8556, 2.3655` | 28.0 | `12.0°` | 3 |
| `grande_arche` | Grande Arche de la Défense | `48.89245, 2.23569` | 110.9 | `32.0°` | 7 |
| `fondation_louis_vuitton` | Fondation Louis Vuitton | `48.8766, 2.2634` | 46.0 | `15.0°` | 3 |
| `bnf_mitterrand` | Bibliothèque François-Mitterrand | `48.8336, 2.3758` | 79.0 | `-42.0°` | 3 |
| `pont_de_bir_hakeim` | Pont de Bir-Hakeim | `48.85571, 2.28757` | 20.5 | `53.1°` | 7 |
| `pont_alexandre_iii` | Pont Alexandre III | `48.86360, 2.31360` | 24.5 | `94.5°` | 7 |
| `pont_d_iena` | Pont d'Iéna | `48.85980, 2.29220` | 13.5 | `44.2°` | 5 |
| `pont_neuf` | Pont Neuf | `48.85780, 2.34190` | 14.5 | `-61.6°` | 3 |
| `passerelle_debilly` | Passerelle Debilly | `48.86256, 2.29693` | 16.0 | `62.4°` | 3 |

## 4. Skyline towers (`PaTowerSpecs`, `skyline: true`)

37 towers across Tour Montparnasse (`210 m`), Pullman Montparnasse (`116 m`), Front de Seine (`10` towers at `98 m`),
and La Défense (`25` towers from `110 m` to `241 m`, anchored by Tour The Link, Tour First, Tour Hekla, Tour Majunga,
Tour Total, Tour Areva, Tour Granite, Tour CB21, Tour Saint-Gobain, Tour D2, Tour Carpe Diem, Cœur Défense & Tour Alto).

## 5. Sources

- OpenStreetMap contributors (`openstreetmap.fr` / bundled `paris_*.osmb` extract, ODbL 1.0)
- Base Mérimée (Ministère de la Culture, France) & published architectural dimensions (Wikipedia / Structurae)
- Wikimedia Commons reference imagery (CC BY / CC BY-SA / CC0 / PD; no Russian hosts per `HostPolicy`)
