# Amsterdam Landmark & LoD2.2 Sources

Source register for the Amsterdam landmark batch (`PLAN_Amsterdam_super_realistic.md`, `LandmarkRegistryAmsterdam`,
`LandmarkSetAmsterdam`, `AmsTowerSpecs`), Amsterdam 3DBAG LoD2.2 true-3D building meshes (`assets/city_models/amsterdam_lod2_meshes/`),
and Amsterdam bridges (`AmsBridges`, `BridgeSpecsWestEurope`, `AmsterdamCanalBridges`).

## 1. Open Data & True-3D LoD2.2 Building Meshes

- **3DBAG LoD 2.2** (TU Delft & 3DGI, CC BY 4.0, `api.3dbag.nl`): 17,598 true-3D LoD2.2 buildings across 9 × 1 km RD New
  (`EPSG:28992`) cells (`120_486`..`122_488`) covering central Amsterdam (Dam Square, Grachtengordel, Jordaan, Centraal,
  Oosterdok, Museumplein, Amstel, Plantage, Overhoeks), compiled by `tools/prepare_amsterdam_lod2_meshes.py` into compact
  zstd `.lod2m` v2 cells (`1,705,771` triangles, `17.62 MB` zstd).
- **PDOK Luchtfoto Actueel_orthoHR** (Kadaster / PDOK, CC BY 4.0, `service.pdok.nl`): 9 × 1 km 8 cm aerial orthophoto tiles
  in `EPSG:28992`, sampled per building roof centroid to classify real-life roof colour and material (`terracotta`,
  `metal`, `copper`, `bitumen`).
- **AHN 0.5 m DTM** (Rijkswaterstaat, CC0): bare-earth elevation model (`GroundModel` `"ahn"`, 0.5 m road RMS).
- **OSM bundled snapshots**: `assets/osm_snapshots/capital_nl_14237403_18488969_*.osmb` centred on `52.37403, 4.88969`
  (12,811 buildings in `detailed`, 85.3 % with BAG `height`, 95.8 % with `start_date`, 472 mapped `houseboat`s, 499 bridges).

## 2. Height & Tag Audit Highlights (`capital_nl_14237403_18488969_detailed.osmb` & `_far.osmb`)

66 named buildings in `detailed` lacked explicit `height` tags and were resolved via bespoke models or `AmsTowerSpecs`:
- `Magna Plaza` (`way 57861220`, `lv=3`, `h=-`) → 38.0 m (`magna_plaza`)
- `Koninklijk Paleis` (`rel 3580875`, `lv=5`, `h=-`) → 51.75 m (`royal_palace_amsterdam`)
- `De Nieuwe Kerk` (`way 747911438`, `h=15` part only) → 60.0 m (`nieuwe_kerk_amsterdam`)
- `Nationaal Monument` (`way 168680619`, `h=-`) → 22.0 m (`nationaal_monument_dam`)
- `De Bijenkorf` (`way 23582490`, `lv=6`, `h=-`) → 34.0 m (`de_bijenkorf_amsterdam`)
- `Westertoren` (`way 99203577`, `h=-`) → 86.0 m (`westerkerk`)
- `Beurs van Berlage` (`way 57858502`, `lv=2`, `h=-`) → 40.0 m (`beurs_van_berlage`)
- `Oude Kerk` (`way 57857592`, `h=-`) → 67.0 m (`oude_kerk_amsterdam`)
- `Koepelkerk` (`way 22100190`, `h=-`) → 36.0 m (`koepelkerk_amsterdam`)
- `Noorderkerk` (`way 220961710`, `h=-`) → 34.0 m (`noorderkerk`)
- `De Waag` (`way 57857390`, `h=-`) → 28.0 m (`waag_amsterdam`)
- `Munttoren` (`way 57862728`, `h=-`) → 40.0 m (`munttoren`)
- `Sint-Nicolaasbasiliek` (`way 174996833`, `lv=3`, `h=-`) → 58.0 m (`sint_nicolaasbasiliek`)
- `Amsterdam Centraal` (`way 57856845`, `lv=1`, `h=-`) → 45.0 m (`amsterdam_centraal`, upgraded from 24-line stub)
- `Stopera` (`ways 268782345, 751591420`, `h=-`) → 28.0 m (`stopera_amsterdam`)
- `Montelbaanstoren` (`way 57864086`, `h=-`) → 48.0 m (`montelbaanstoren`)
- `Stadsschouwburg` (`way 57863115`, `h=-`) → 28.0 m (`stadsschouwburg_amsterdam`)
- `Amstel Tower` (`far` ways `1302940796` `h=75` / `603451493` `h=6, lv=30`) → 103.0 m (`amstel_tower`)

## 3. Landmark Registry Summary (66 Total)

- **Central Foreground (`AmsRegCentre`, 19 rows):** `royal_palace_amsterdam` (51.75 m, primary), `westerkerk` (86.0 m,
  primary), `amsterdam_centraal` (45.0 m, primary), `nieuwe_kerk_amsterdam` (60.0 m), `magna_plaza` (38.0 m),
  `oude_kerk_amsterdam` (67.0 m), `beurs_van_berlage` (40.0 m), `nationaal_monument_dam` (22.0 m),
  `de_bijenkorf_amsterdam` (34.0 m), `sint_nicolaasbasiliek` (58.0 m), `zuiderkerk` (61.2 m), `munttoren` (40.0 m),
  `waag_amsterdam` (28.0 m), `koepelkerk_amsterdam` (36.0 m), `montelbaanstoren` (48.0 m), `scheepvaarthuis` (35.0 m),
  `noorderkerk` (34.0 m), `de_krijtberg` (53.0 m), `schreierstoren` (20.0 m).
- **Museumplein, South Ring, Amstel & East (`AmsRegCulture`, 16 rows):** `rijksmuseum` (60.0 m, primary),
  `van_gogh_museum` (20.0 m), `stedelijk_museum` (22.0 m), `concertgebouw` (26.0 m), `pathe_tuschinski` (36.0 m),
  `de_bazel` (37.5 m), `stadsschouwburg_amsterdam` (28.0 m), `heineken_experience` (26.0 m), `vondelkerk` (50.0 m),
  `stopera_amsterdam` (28.0 m), `hart_amstelhof` (20.0 m), `theater_carre` (26.0 m), `amstel_hotel` (28.0 m),
  `portugese_synagoge` (24.0 m), `tropenmuseum` (48.0 m), `molen_de_gooyer` (33.8 m sail tip).
- **IJ Waterfront, Harbour, Stadiums & Bespoke Bridges (`AmsRegWaterfront`, 16 rows):** `nemo_amsterdam` (32.0 m),
  `scheepvaartmuseum` (30.0 m + VOC *Amsterdam*), `eye_filmmuseum` (22.0 m), `adam_toren` (100.0 m),
  `muziekgebouw_bimhuis` (24.0 m), `oba_oosterdok` (42.0 m), `het_schip` (28.0 m), `pontsteiger` (90.0 m),
  `silodam` (34.0 m), `gashouder_amsterdam` (24.0 m), `olympisch_stadion_amsterdam` (46.0 m),
  `johan_cruijff_arena` (75.0 m), `magere_brug` (68 m span), `blauwbrug` (62 m span), `torensluis` (42 m span),
  `python_bridge` (92 m span).
- **Skyline Towers (`AmsTowerSpecs`, 15 `skyline: true` rows):** `rembrandttoren` (150 m), `mondriaantoren` (123 m),
  `amstel_tower` (103 m), `breitnertoren` (95 m), `hotel_okura_amsterdam` (78 m), `zuidas_valley` (100 m),
  `zuidas_symphony` (105 m), `zuidas_ito` (100 m), `zuidas_vinoly` (95 m), `zuidas_abn_amro` (105 m),
  `zuidas_the_rock` (91 m), `zuidas_wtc` (105 m), `zuidas_new_amsterdam` (92 m), `overhoeks_ytowers` (110 m),
  `dreeftoren_two` (132 m).
- **Parametric `conf: 2` Bridges (`BridgeSpecsWestEurope`, 4 rows):** `br_amsterdam_berlagebrug`,
  `br_amsterdam_jan_schaeferbrug`, `br_amsterdam_hogesluis`, `br_amsterdam_torontobrug`.
