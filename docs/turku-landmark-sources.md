# Turku Landmark & Major Building Sources — Measured Envelopes & Heights

Models use true metres and merged textured surfaces (`LandmarkMesh` / `LandmarkMaterials`).
Footprints, centroids, and axis bearings are measured from OpenStreetMap (`api.openstreetmap.org/api/0.6/map` and bundled `assets/osm_snapshots/turku_*.osmb`, © OpenStreetMap contributors, ODbL).
Measured building heights, roof rises, pitches, roof shapes, storey counts, and footprint areas are audited against the City of Turku 3D CityGML LoD2 bundle (`assets/city_models/turku_lod2/`, © City of Turku, CC BY 4.0) via:

```bash
tools/godot_bg.sh --headless --path . --script tools/turku_measured_heights.gd
```

> Note on LoD2 vs published/registry heights: CityGML `measuredHeight` reflects the city 3D mesh bounding height (from lowest terrain contact to highest roof/spire vertex). On hilltop sites (`vartiovuori_observatory`) or ships (`suomen_joutsen`) LoD2 can exceed local plinth-to-top height; on spires (`turku_cathedral`, `mikaelinkirkko`, `martinkirkko`) thin crosses/finials can be truncated in LoD2. Always cross-check against published architectural heights and reference photographs (`visual-plan/refs/landmarks/<type>/`).

---

## 1. Existing 17 Turku Landmarks (Phases T-1 & T-2)

| Type | OSM Way / Rel | Centroid (`lat, lon`) | `yaw_deg` | OSM Footprint (m) | Registry `height_m` | LoD2 `height_m` | LoD2 Roof (`shape`, `roof_h`, `pitch`) | LoD2 Storeys / Area | Notes & Multi-Building Envelope |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `turku_cathedral` | `way:437169589` | `60.452450, 22.278549` | `2.2` | — | `101.0` | `89.0` | `gabled`, 82.9 m, 40° | 2 st / 3,386 m² | Core landmark; Engel 1834 spire + cross reaches ~101 m ASL / ~85–90 m local; `clear_m=52.0`. |
| `turku_castle` | `way:466736288` | `60.435350, 22.228750` | `-1.4` | — | `38.0` | `41.8` | `gabled`, 34.6 m, 40° | 4 st / 6,063 m² | Main Keep (*Päälinna*) + Renaissance Bailey (*Esilinna*); LoD2 `prt=103371526B`. |
| `mikaelinkirkko` | `way:34204417` | `60.448717, 22.247918` | `-34.4` | `55.0 × 35.7` | `77.0` | `75.3` | `gabled`, 73.5 m, 48° | 1 st / 1,848 m² | Lars Sonck (1905); OSM parts: nave 21.5 m, side aisles 14.6 m; NW copper spire 77 m (`skyline: true`). |
| `martinkirkko` | `way:48988447` | `60.440857, 22.254405` | `-33.7` | — | `52.0` | `49.2` | `gabled`, 40.8 m, 32° | 1 st / 1,120 m² | Sora & Wahlroos (1933); pale-ochre basilica & 52 m SW campanile (`skyline: true`). |
| `turku_orthodox_church` | `way:26491333` | `60.452285, 22.266010` | `-34.8` | `29.6 × 22.4` | `27.0` | `30.4` | `complex`, 19.9 m, 36° | 1 st / 2,425 m² | C.L. Engel (1845); OSM parts: rotunda `way:465777788` 20.8×20.7 m (h=21 m), lantern `way:465777786` 4.2×4.1 m (h=27.5 m), single SE Doric portico facing Kauppatori. |
| `turku_kauppatori` | `way:621404185` + rel `14681388` | `60.451692, 22.266896` | `-35.3` | Plaza + 3 pavilions | `11.0` | — | — | — | 2022 *Saariston sydän* square & Schauman Arkkitehdit glulam-and-glass pavilions (`way:1086675768/70/71`). |
| `turku_art_museum` | `way:26491362` | `60.454107, 22.261774` | `-34.7` | `39.4 × 32.7` | `22.0` | `22.5` | `gabled`, 10.8 m, 35° | 2 st / 1,032 m² | Gustaf Nyström (1904) on Puolalanmäki; corner towers 4.7×4.7 m at ±14 m; granite terrace stairs down toward Aurakatu. |
| `vartiovuori_observatory` | `way:17037200` | `60.448699, 22.276653` | `0.5` | `29.3 × 33.5` | `18.0` | `26.0` | `hipped`, 15.3 m, 12° | 2 st / 1,309 m² | C.L. Engel (1819); OSM parts: central rotunda `way:317221112` 14.1×14.1 m (h=15 m), wings 7.5 m; LoD2 26.0 m includes hilltop slope drop. |
| `turku_market_hall` | `way:9166246` | `60.449761, 22.266060` | `54.9` | `118.8 × 17.4` | `13.0` | `10.8` | `gabled`, 4.7 m, 18° | 1 st / 2,080 m² | Gustaf Nyström (1896); OSM `height=11.5`, clerestory 9.5 m, side bays 4–7 m. Note: `clear_m=62` overlaps neighbouring 23–30 m blocks at 46–52 m — prefer `clear_rect_m`. |
| `turku_main_library` | `way:29900658` + `44173779` | `60.450810, 22.272273` | `-35.5` | Old `41.8 × 42.7`; New `59.9 × 47.9` | `18.0` | `19.9` | `mansard`, 12.4 m, 31° | 2 st / 2,333 m² | Two-building block: Old Library (`way:29900658`, 1903 Wrede, LoD2 19.9 m) + courtyard wing (`way:521256933`, LoD2 10.7 m) + Uutistori (`way:714092993`, 49.1×13.0 m at `-34E,-9N`) + 2007 JKMM New Main Library (`way:44173779`, 4 lv at `-57E,-54N`). |
| `turku_city_theatre` | `way:9167060` | `60.445939, 22.264207` | `-31.2` | `94.6 × 88.3` | `22.0` | `28.0` | `flat`, 0.0 m | 4 st / 6,175 m² | Luukkonen & Stenros (1962) + 2017 copper Sopukka expansion; LoD2 fly-tower measures 28.0 m (`prt=102725984D`). |
| `kakola_prison` | `way:315938833` | `60.444429, 22.247103` | `-32.0` | — | `24.0` | `21.8` | `hipped`, 6.3 m, 23° | 4 st / 2,583 m² | Ernst Lohrmann (1853) Granite Main Prison (`prt=100924242P`) + adjacent wing at d=43 m (LoD2 9.4 m, 930 m²) + Länsiselli & SW Mental Hospital on Kakolanmäki ridge. |
| `vanha_suurtori` | `way:23370371` + `23370368` | `60.450508, 22.275468` | `-59.0` | Brinkkala `36.8 × 35.7`; Raatihuone `15.2 × 18.9` | `15.0` | `12.6` | `hipped`, 7.7 m, 21° | 2 st / 950 m² | 4-mansion Empire square: Brinkkala (`way:23370371`), Old Town Hall (*Vanha Raatihuone*, `way:23370368` at `+33.5E,-0.4N`, 3.5 lv), Hjelt/Juselius blocks (`rel:12990219/25/26` at `-24E..-7E,-30N` to `+36E,-29N`, 2–3 lv). |
| `suomen_joutsen` | `way:178299341` | `60.436330, 22.237154` | `-33.9` | — | `44.0` | `50.0` | `flat` (mesh bbox) | 3 st / 1,131 m² | 1902 white 3-masted full-rigged museum ship moored at Forum Marinum (`base=water`); published mast height ~44 m. |
| `fori_ferry` | `way:57933176` | `60.441137, 22.247901` | `-35.5` | — | `5.5` | — | — | — | 1904 orange-and-white double-ended Aurajoki cable ferry (`base=water`, not in LoD2). |
| `samppalinnan_maauimala` | `way:133733723` et al. | `60.445725, 22.265774` | `-79.5` | Pool + grandstand | `12.0` | `5.9` | `complex`, 3.6 m, 25° | 68 m² (kiosk) | 1955 Sandelin / 2017 LEMMETTI outdoor swimming stadium; 10 m diving tower + grandstand. |
| `paavo_nurmen_stadion` | `way:24206308` + rel `9244078` | `60.442548, 22.260900` | `-42.0` | Track + grandstand | `19.6` | — | — | — | 1989 Nurmela–Raimoranta–Tasa two-tier grandstand + wing canopy (CityGML `103248831E`). |

---

## 2. Planned Tier 1 Landmarks & Major Buildings (Phase T-3A..T-3D)

### T-3A: Kauppatori Perimeter, Yliopistonkatu & Commercial Core

| Type | Building | OSM Way / Rel | Centroid (`lat, lon`) | `yaw_deg` | OSM Footprint (m) | LoD2 `height_m` (tallest) | LoD2 Roof / Storeys / Area |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `hamburger_bors_turku` | Scandic Hamburger Börs (Uusi + Vanha Börs) | `way:1074264772` + `way:687986076` | `60.451003, 22.268695` | `54.9` | `55.9 × 62.6` + `23.5 × 22.9` | `34.8` | `flat`, 10 st / 2,871 m² (Uusi 9 lv, Vanha 3 lv) |
| `wiklund_turku` | Sokos Wiklund & Walo Rooftop | `way:465777801` | `60.451915, 22.268961` | `-35.2` | `68.3 × 62.4` | `38.0` | `flat`, 8 st / 4,310 m² |
| `hansakortteli` | Hansakortteli (Kultatalo & Antintalo) | `way:315581388` + `way:315581685` | `60.451114, 22.265069` | `-34.7` | `59.5 × 32.6` + `60.8 × 15.8` | `29.7` | `flat`, 3–6 st / 5,204 m² |
| `abo_svenska_teater` | Åbo Svenska Teater (1839) | `way:1043097294` | `60.450751, 22.265913` | `-35.0` | `36.6 × 33.7` | `18.3` (`25.6`) | `complex`, 9.0 m, 36°, 3 st / 2,867 m² |
| `kop_kolmio_turku` | KOP-kolmio (Viljo Revell, 1964) | `way:315833855` | `60.450129, 22.266445` | `54.9` | `77.5 × 56.8` | `30.5` | `flat`, 8–10 st / 4,766 m² |
| `turun_sanomat_building` | Turun Sanomat Building (Alvar Aalto, 1930) | Kauppiaskatu 5 | `60.450500, 22.269900` | `-35.0` | — | `21.5` (`23.0`) | `hipped`/flat, 6 st (verify exact parcel way) |
| `kivikukkaro` | Kivikukkaro (Aarne Ehojoki, 1975) | `way:100310223` | `60.450635, 22.260871` | `-34.7` | `48.7 × 66.0` | `21.2` | `flat`, 4 st / 2,839 m² |
| `turku_synagogue` | Turku Synagogue (1912) | `way:90081643` | `60.455739, 22.266577` | `54.8` | `23.0 × 15.5` | `16.2` | `mansard`, 8.1 m, 25°, 2 st / 401 m² |
| `puutori_ensemble` | Puutori & Puutorin Vessa (1933) | `way:90081603` + `way:1044040680` | `60.455219, 22.269088` | `56.9` | `10.2 × 11.0` (rotunda) | `6.1` | Rotunda 1 st; surrounding square 49 × 96 m |
| `betel_church_turku` | Betel Church (Frithiof Strandell, 1906) | `way:28190211` | `60.451191, 22.261149` | `-35.6` | `33.5 × 22.7` | `30.7` | `gabled`, 19.8 m, 40°, 2 st / 577 m² |
| `prima_albatross_aurakatu` | Aurakatu Jugend Palaces (*Albatross* & *Prima*) | Aurakatu 14–16 | `60.453550, 22.262750` | `-35.0` | — | `24.6` | `hipped`, 5.6 m, 31°, 5 st / 1,381 m² |
| `pantern_hjelt_kaskenkatu` | *Pantern* (Kaskenkatu 2) | Kaskenkatu 2 | `60.448800, 22.271800` | `-35.0` | — | — | Verify parcel on Kaskenkatu 2 |
| `humalistonkatu_jugend` | Humalistonkatu Jugend Row | Humalistonkatu | `60.451750, 22.259150` | `55.0` | — | `20.4` (`33.1`) | `complex`, 5 st / 4,063 m² |
| `turku_fire_station` | Turku Central Fire Station (1916) | Eerikinkatu 35 | `60.448350, 22.258250` | `-35.0` | — | `16.0` (`27.7`) | Brick block + hose-drying lookout tower |

### T-3B: Aurajoki Waterfront — Cathedral to Harbour Mouth

| Type | Building | OSM Way / Rel | Centroid (`lat, lon`) | `yaw_deg` | OSM Footprint (m) | LoD2 `height_m` (tallest) | LoD2 Roof / Storeys / Area |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `turku_city_hall` | Turku City Hall (*Kaupungintalo*, 1885) | `way:22495091` | `60.448815, 22.268519` | `-29.5` | `46.6 × 28.0` | `14.7` | `hipped`, 11.2 m, 18°, 2.5 st / 1,543 m² |
| `qwensel_house` | Qwensel House & Pharmacy Museum (~1700) | `way:34203891` | `60.448595, 22.267682` | `55.9` | `27.4 × 23.2` | `8.8` (`10.3`) | `hipped`, 4.7 m, 42°, 1 st / 445 m² |
| `verdandi_house` | Verdandi House (*Verdandin talo*, 1898) | `way:90775544` | `60.449565, 22.268936` | `53.8` | `71.3 × 38.5` | `27.4` (`29.5`) | `hipped`, 23.2 m, 26°, 4 st / 2,148 m² |
| `chappe_art_house` | Art House Chappe (JKMM, 2023) | `way:90775548` / Länt. Rantakatu | `60.450050, 22.271600` | `55.0` | — | `15.0` (`19.1`) | `hipped`, 6.6 m, 26°, 2 st / 797 m² |
| `aboa_vetus_rettig` | Aboa Vetus Ars Nova (*Rettigin palatsi*, 1928) | `way:88509262` | `60.449744, 22.273596` | `56.3` | `66.1 × 44.1` | `19.8` | `complex`, 13.0 m, 9°, 2 st / 1,744 m² |
| `pinella_porthan` | Pinella & Porthan Monument | `way:525031933` | `60.451471, 22.274998` | `-64.3` | `33.9 × 10.4` | `7.8` | `skillion`, 5.4 m, 11°, 2 st / 276 m² |
| `sibelius_museum` | Sibelius Museum (1968) | `way:27312132` | `60.453687, 22.277556` | `-66.2` | `51.5 × 30.4` | `7.1` | `flat`, 1–2 st / 2,403 m² (hypar shell roof) |
| `abo_akademi_main` | Åbo Akademi Main & Academy Building | `way:28173891` + `way:27031838` | `60.451192, 22.278324` | `-27.6` | `47.3 × 14.0` | `13.7` (`20.9`) | `gabled`, 13.3 m, 29°, 3 st / 976 m² |
| `abo_akademi_book_tower` | Åbo Akademi Book Tower (*Kirjatorni*, 1935) | Tuomiokirkonkatu | `60.453050, 22.276800` | `26.8` | — | `13.3` | Verify tower parcel (`skyline: true`) |
| `wam_museum` | Wäinö Aaltonen Museum of Art (WAM, 1967) | `rel:14702073` | `60.444952, 22.260236` | `-34.3` | `80.0 × 45.7` | `16.2` | `flat`, 2 st / 2,862 m² |
| `turku_state_office` | State Office Building (*Valtion virastotalo*, 1967) | `rel:14723442` | `60.445066, 22.262381` | `-31.0` | `113.6 × 51.2` | `34.9` | `flat`, 9 st / 7,433 m² |
| `fuuga_music_hall` | Turku Music Hall Fuuga | `way:1204040702` | `60.445684, 22.262024` | `58.8` | `43.1 × 116.5` | — | **Mapped in OSM** (`b=civic`); post-LoD2 construction, model from PES-Architects envelope |
| `samppalinna_windmill` | Samppalinna Windmill & Restaurant | `way:88333834` | `60.443996, 22.260161` | `52.9` | `13.1 × 13.0` | `25.7` | `gabled`, 21.1 m, 45° / 585 m² |
| `forum_marinum` | Forum Marinum (*Kruununmakasiini* & *Linnanpuomi*) | Linnankatu 72 | `60.436800, 22.236150` | `-34.0` | — | `15.8` | `gabled`, 9.9 m, 21°, 2 st / 2,318 m² |
| `sigyn_bore_ships` | Museum Ships *Sigyn* & *S/S Bore* | Forum Marinum quay | `60.435500, 22.235500` | `-34.0` | — | — | `base=water`; *Bore* 100 m LOA, *Sigyn* in *Loke* dock |
| `crichton_vulcan_crane` | Aurajoki Harbour Crane (*Nosturi 37*) | Telakkaranta | `60.435750, 22.238350` | — | — | — | Published ~38 m portal crane (`skyline: true`) |

### T-3C: Universities, TYKS Hospital Area, Kupittaa & Cultural Hills

| Type | Building | OSM Way / Rel | Centroid (`lat, lon`) | `yaw_deg` | OSM Footprint (m) | LoD2 `height_m` (tallest) | LoD2 Roof / Storeys / Area |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `utu_main_campus` | University of Turku Main Hill (*Yliopistonmäki*) | `way:34025118` / `34025081` / `28173749` | `60.454162, 22.284697` | `23.8` | Main `42.3×43.6`, Feeniks `61.6×22.4`, Natura `138.7×39.6` | `14.1` | `flat`, 3–4 st / 2,512 m² |
| `utu_agora_quantum` | Agora, Quantum, Educarium & Publicum | `way:218869876` / `34024258` / `34103482` | `60.455393, 22.285383` | `-65.9` | Agora `82.7×26.2`, Quantum `146.6×51.3`, Educarium `65.8×102.0` | `23.6` | `flat`, 4–6 st / 2,216 m² (Educarium OSM `h=19.5`) |
| `turku_school_economics` | Turku School of Economics | Rehtorinpellonkatu 3 | `60.455250, 22.287750` | `-66.0` | — | `36.6` | `hipped` / flat |
| `turku_concert_hall` | Turku Concert Hall (1952) | `way:96558882` | `60.455720, 22.270634` | `-35.2` | `58.2 × 55.6` | `23.1` | `gabled`, 14.3 m, 16°, 3 st |
| `tyks_majakka` | TYKS Majakkasairaala (2022) | Over Highway 1 & rail | `60.452580, 22.293950` | `-34.0` | — | `46.4` | `flat`, 8 st / 10,037 m² (`skyline: true`, rooftop helipad) |
| `tyks_t_hospital` | TYKS T-sairaala (2003–13) | Hämeentie / Savitehtaankatu | `60.451750, 22.292150` | `-34.0` | — | `29.9` | `gabled`/flat, 7 st / 3,287 m² |
| `tyks_a_u_hospitals` | TYKS A-sairaala (1938) & U-sairaala (1968) | `way:29050045` (U-sairaala) | `60.453506, 22.289779` | `-19.7` | `191.4 × 47.4` (U-sairaala) | `51.1` | **U-sairaala still mapped in OSM** (`flat`, 13 st / 8,646 m²) |
| `tyks_medisiina_dentalia` | Medisiina D (2018), A–C & Dentalia | Kiinamyllynkatu 10 | `60.450950, 22.290950` | `-34.0` | — | `10.9` | Verify Medisiina D parcel (post-LoD2 2018 wing ~24 m) |
| `tyks_kantasairaala_pavilions` | Historic Kantasairaala Pavilions & Mikro | Kiinamyllynkatu | `60.450400, 22.287900` | `-34.0` | — | `22.5` | `gabled`, 3 st / 1,247 m² |
| `kupittaa_biocity_electro` | BioCity, ElectroCity & DataCity | Tykistökatu | `60.449400, 22.292200` | `-34.0` | — | `35.8` | `flat`, 7 st / 5,474 m² |
| `intelligate_ict_kupittaa` | Intelligate I–III & ICT-City | Joukahaisenkatu | `60.449150, 22.296600` | `-34.0` | — | `30.8` | `flat`, 6 st / 9,879 m² (`skyline: true`) |
| `veritas_stadion` | Veritas Stadion | Kupittaanpuisto | `60.442600, 22.291350` | `-34.0` | — | `11.8` | `gabled`, 9.6 m, 17° / 2,622 m² + floodlight masts |
| `kupittaan_puisto_pavilions` | Kupittaa Park Pools & Pavilions | Kupittaanpuisto | `60.444650, 22.287600` | — | — | — | Outdoor pools & St. Henry's Spring pavilion |
| `resurrection_chapel` | Resurrection Chapel (Erik Bryggman, 1941) | Hautausmaantie 21 | `60.433750, 22.307500` | — | — | — | Outside LoD2 central tile; verify OSM on build |
| `st_catherine_church_turku` | St. Catherine's Church (14th c.) | Kirkkotie 46 | `60.462250, 22.293450` | — | — | `20.5` | `gabled`, 17.6 m, 58° / 495 m² |
| `maaria_church_turku` | Maaria Church (15th c.) | Maunu Tavastin katu 2 | `60.473350, 22.293100` | — | — | `24.3` | `gabled`, 19.4 m, 59° / 697 m² |

### T-3D: Stations, Logomo, Port of Turku, Skyline Towers & Arenas

| Type | Building | OSM Way / Rel | Centroid (`lat, lon`) | `yaw_deg` | OSM Footprint (m) | LoD2 `height_m` (tallest) | LoD2 Roof / Storeys / Area |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `logomo_and_bridge` | Logomo (1876) & Logomon silta (2021) | `way:157394020` | `60.456985, 22.258005` | `-33.2` | `166.5 × 93.9` | `22.7` | `complex`, 15.7 m, 24°, 3 st / 14,302 m² |
| `turku_central_station` | Turku Central Railway Station (1940) | `way:315580344` | `60.455677, 22.260744` | `-34.3` | `50.9 × 16.1` | `22.9` | `gabled`/flat, 3–4 st / 1,232 m² |
| `turku_bus_station` | Turku Bus Station (1938) | `way:38659318` | `60.457073, 22.268170` | `86.1` | `64.6 × 27.3` | — | Semicircular functionalist rotunda + departure canopy |
| `kupittaa_station` | Kupittaa Railway Station (1995) | `way:986922992` | `60.450350, 22.297450` | `-34.8` | `101.3 × 94.8` | `15.3` | `flat`, 1 st / 598 m² bridge-concourse |
| `port_of_turku_terminals` | Viking Line & Tallink Silja Terminals | Linnansatama | `60.434800, 22.221500` | — | — | `15.6` | `gabled`, 10°, 2 st / 3,076 m² (keep separate Viking & Silja terminals) |
| `if_torni_turku` | If-torni (66 m, 17 st) | Itäharju | `60.447850, 22.302750` | — | — | — | Published 66 m (`skyline: true`); verify exact OSM way |
| `ikituuri_turku` | Ikituuri (43 m, 2011) | Pispalantie 12 | `60.458150, 22.294350` | — | — | — | Published 43 m oval copper tower (`skyline: true`) |
| `airiston_tahti` | Airiston Tähti (58 m, 18 st) | `way:315922782` | `60.427970, 22.237072` | `34.0` | `67.1 × 33.5` | `57.4` | `flat`, 16–18 st, OSM `h=58` (`skyline: true`) |
| `telakkaranta_linnanfaltti` | Telakkaranta & Linnanfältti | Aura mouth | `60.436600, 22.241200` | — | — | `27.0` | `flat`, 7 st / 466 m² |
| `paaskyvuori_tower` | Pääskyvuori Link Tower (134 m) | `way:788703093` | `60.447051, 22.332216` | `32.9` | `23.0 × 17.4` | `106.1` | Concrete shaft 106.1 m in LoD2; OSM `h=134.6` with mast (`skyline: true`) |
| `turku_water_towers` | Luolavuori / Vesilinna / Juhannuskukkula Water Towers | `way:770661224` / `28173746` | `60.459139, 22.256609` | `-89.2` | `62.2 × 35.7` | `29.4` | `flat`, 4–6 st (`skyline: true`) |
| `gatorade_center_turku` | Gatorade Center (*Turkuhalli*, 1990) | Artukainen | `60.456200, 22.186950` | — | — | `36.0` | `hipped`, 10.9 m, 10° / 84,159 m² (arena + Fair Centre) |
| `ruissalo_villas_spa` | Ruissalo Spa & Botanical Garden | Ruissalo | `60.433150, 22.173850` | — | — | `14.1` | `gabled`, 13.6 m, 35° / 2,553 m² |

---

## 3. Aurajoki Bridges (`BridgeSpecsNorthEurope`, `conf: 2`)

- **Tuomiokirkkosilta** (OSM ways `4306348` / `27734777`): 3-span concrete girder, 50 m, bearing `143.7°`.
- **Kirjastosilta** (OSM way `103351226`): single-span white steel pedestrian arch deck, 56 m, width 5 m, bearing `123.2°`.
- **Auransilta** (OSM ways `90088650` / `90088646` / `90088671`): 1907 single-span stone/steel arch deck, 45 m, width 17.5 m, bearing `144.5°`.
- **Teatterisilta** (OSM way `105064411`): single-span steel pedestrian girder, 65 m, width 6 m, bearing `150.7°`.
- **Myllysilta** (OSM ways `531029806` / `1579901611` / `206891995`): 3-span steel box-girder, 94 m, width 20 m, bearing `145.4°`.
- **Martinsilta** (OSM way `4306342`): 3-span concrete girder, 104 m, width 18 m, bearing `145.2°`.
- **Auransilta, Kirjastosilta & Teatterisilta fitted specs (2026-11-23):** `bridge_specs_north_europe.gd` synced to bespoke geometry (`br_turku_kirjastosilta` span `59.8 m`, width `5.0 m`, `orn: 3.8`; `br_turku_auransilta` span `45.2 m`, width `17.5 m`, `orn: 6.1`; `br_turku_teatterisilta` span `66.2 m`, width `6.4 m`, `orn: 9.3`), builders refactored to `build(model, row := {})` with `FOOT_Y := 0.0`, `BridgeCamber.apply`, and Array-typed `LandmarkLights.FLOOD_META` (`bridge_specs_test.gd` & `turku_landmarks_test.gd` PASS).

## Phase T-3D Addition & Reference Library Completion (2026-11-23)

- **`meyer_gantry_cranes`** (`FtMeyerGantryCranes`, `scripts/data/turku/tku_reg_skyline.gd`, `skyline: true`, `secondary: true`): `60.457800, 22.124800`, `yaw_deg: 38.1°`, `height_m: 105.0`, `radius_m: 9500.0`, `clear_m: 16.0`. Measured from OSM `way:366690301` (366 × 80 m Perno building dock) and `way:673162242` (155.5 m crane rail span, 739 m track): twin Konecranes/Meyer blue-and-white Goliath portal cranes (1200 t at 105.0 m and 600 t at 97.5 m) with ICAO `HALO_META` beacons and dock `FLOOD_META` spots (8 parts, 7,360 tris).
- **Reference photo coverage:** 44 additional Turku landmark folders in `visual-plan/refs/landmarks/<type>/` populated with 3+ Wikimedia Commons CC BY / CC BY-SA / CC0 / PD photos and tracked `README.md` provenance (`78/79` Turku types documented on disk; `chappe_art_house`, opened 2023, has no free-licensed exterior Commons/Finna photo under Finnish freedom-of-panorama rules). Side-by-side compare pages for all 79 Turku landmarks generated in `visual-plan/captures/tku_t3_complete/compare/page_00..13.jpg`.
