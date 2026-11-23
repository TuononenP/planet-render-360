# Bangkok Landmark & Skyline Sources — Measured Envelopes & Heights (BK-0.5)

Footprints, polygon centroids, long-axis bearings, and distances from the Bangkok capital origin (`13.75398, 100.50144`, Bangkok City Hall / Lan Khon Mueang) were measured from the bundled OpenStreetMap snapshots (`assets/osm_snapshots/capital_th_10375398_28050144_*.osmb`) and bounded Overpass `out geom` queries on `overpass.openstreetmap.fr` (2026-11-23, © OpenStreetMap contributors, ODbL). No Russian-operated host was contacted (`HostPolicy`).

Reference photographs (3–4 CC BY / CC BY-SA / CC0 / public-domain views per landmark plus 7 city fabric views) are documented in `visual-plan/refs/landmarks/<type>/README.md` and `visual-plan/refs/bangkok/README.md` (`tools/bangkok_commons_refs.py`; JPEGs gitignored).

**Yaw convention:** models built with their long axis along `+X` use `yaw_deg = axis_bearing_deg - 90` (mod 180); models built facing `+Z` along their main entrance axis set `yaw_deg` accordingly (documented in each builder's spec header).

---

## 1. Existing 4 Registry Landmarks (Upgraded in BK-4)

| Type | OSM Way / Rel | Centroid (`lat, lon`) | Axis (°) | OSM Footprint (m) | Distance & Bearing | Registry `height_m` | Published / Source Height & Notes |
| --- | --- | --- | ---: | --- | --- | ---: | --- |
| `grand_palace_bangkok` | `way:23482754` (outer wall); `way:23482988` (Phra Si Rattana Chedi); `rel:18593471` (Chakri Maha Prasat); `way:82541999` (Dusit Maha Prasat); `way:205631558` (Amarin); `way:82543520` (Borom Phiman); `way:23482991..98` (8 prangs) | Compound `13.750128, 100.491684` (registry `13.75101, 100.49188` between Wat Phra Kaew & Middle Court) | `171` (wall N–S), `87` (halls E–W) | `624.9 × 442.2` (compound) | `1,139 m @ 248°` | `45.0` | Primary (`icon: true`). Phra Si Rattana Chedi ~40 m, Prasat Phra Thep Bidon & Chakri spires ~45 m (Royal Household Bureau / Fine Arts Dept). `clear_m=220` + outer wall `clear_path_m`. |
| `wat_pho` | `way:23630142` (Viharn Phranorn); `way:23630098` (Phra Ubosot); `way:783589706..09` (4 Great Chedis); `way:783589714` (Phra Mondop) | Compound `13.74650, 100.49265` (registry `13.74668, 100.49237`) | `71` (E–W compound axis) | Viharn `64.3 × 28.2`, Ubosot `48.9 × 31.9`, Chedis `15.6 × 15.6` | `1,274 m @ 230°` | `42.0` | Four Phra Maha Chedi Si Rajakarn are 42 m tall (Wat Pho official guide / Fine Arts Dept); Reclining Buddha inside Viharn Phranorn is 46 m long × 15 m high. |
| `wat_arun` | `way:23482275` (Central Prang); `way:23482282` (Ordination Hall); `way:23482283` (Phra Viharn); `way:23482289` (Mondop) | `13.743699, 100.488892` (registry `13.7437, 100.4889`) | `162` / `72` (river axis) | Prang `34.2 × 34.2` (terrace ~`79 × 79`), Ubosot `35.6 × 18.4` | `1,775 m @ 230°` | `70.0` | Fine Arts Department 1980s photogrammetric survey gives ~67–70 m (older tourist sources quote up to 79–82 m); registry 70.0 m retained (`skyline_priority: 2`). |
| `hua_lamphong` | `rel:18050303` (station + shed; headhouse front at `13.7377, 100.5172`) | `13.740186, 100.516845` (headhouse `13.7385, 100.5169`) | `8` / `138.7` (registry yaw) | `493.4 × 103.7` (overall), headhouse ~`155 × 129` | `2,488 m @ 136°` | `26.2` | Mario Tamagno & Annibale Rigotti (1916); Italian Neo-Renaissance half-barrel vault ~26.2 m high. Capital-stations entry kept in place. |

---

## 2. Centre Set — Lan Khon Mueang & Ratchadamnoen (BK-2)

| Type | OSM Way / Rel | Centroid (`lat, lon`) | Axis (°) | OSM Footprint (m) | Distance & Bearing | `height_m` | Source & Architectural Notes |
| --- | --- | --- | ---: | --- | --- | ---: | --- |
| `giant_swing` | `way:178353988` (`man_made=ceremonial_gate`) | `13.751811, 100.501275` | `151` (transverse to Bamrung Mueang Rd; frame runs N–S ~`7°`) | `10.5 × 10.4` (plinth) | `242 m @ 184°` | `21.15` | BMA / Fine Arts Department (2007 Golden Teak reconstruction): 21.15 m tall vermilion teak pillars leaning inward on white stepped stone plinth, carved gilt-edged crossbar. |
| `democracy_monument` | `way:178329973` (`historic=monument`, `Q1186076`) | `13.756688, 100.501852` | `29` (avenue axis `102°`) | `58.2 × 58.1` (island) | `305 m @ 8°` | `24.0` | Mevissen & Corrado Feroci / Sitthidej Saenghirun (1939–40): four curved Art Deco wing pylons 24 m high at 24 m radius around central 3 m constitution turret + two gilt *phan* bowls, naga fountains. |
| `loha_prasat` | `way:103097698` + `way:560754640` (Maha Chetsadabodin Pavilion) + `way:560594892` (plaza) | `13.754813, 100.504163` | `15` | `39.5 × 38.9` (`48 × 48` box) | `309 m @ 73°` | `36.0` | Wat Ratchanatdaram (begun 1846 under Rama III; spires gilded 2014–17): 36 m tall, 3 concentric stepped square colonnaded tiers carrying 37 metallic/gilt spires (24 + 12 + 1 central). |
| `wat_suthat` | `way:88335184` (Viharn Luang) + `way:1320430710` (cloister) + `way:88335204` (Phra Ubosot) | `13.750680, 100.500990` (Viharn `13.751044, 100.501071`, Ubosot `13.750323, 100.500906`) | `7` (Viharn N–S), `96` (Ubosot E–W) | Viharn `47.6 × 31.8`, Cloister `62.2 × 47.3`, Ubosot `73.7 × 23.0` | `370 m @ 188°` | `34.0` | Royal temple of the first grade (1807–47): monumental Viharn Luang (~34 m roof ridge, double terrace with 28 Chinese stone pagodas) inside Buddha-lined *phra rabiang*, plus 72 m Phra Ubosot behind. |
| `mahakan_fort` | `way:103022352` (`historic=fort`) + city wall along Khlong Rop Krung | `13.755597, 100.505518` | `175` | `39.3 × 37.0` (fort) + ~`180 m` wall | `476 m @ 68°` | `19.0` | Built 1783 under Rama I: whitewashed octagonal 3-tier masonry fort (~19 m to octagonal lantern roof finial, ~14 m parapet) with pointed-lotus battlements and surviving ~180 m crenellated city wall. |
| `golden_mount` | `way:243936903` (summit terrace) + `way:88359228` | `13.753852, 100.506676` | `86` | `58.5 × 47.6` (summit; hill base ~`130 × 115`) | `566 m @ 91°` | `77.0` | Wat Saket *Phu Khao Thong* (Rama III–Rama V): ~58–60 m wooded artificial hill encircled by 344-step white spiral stair, topped by square white pavilion terrace and golden bell chedi reaching ~77 m (`skyline_priority: 3`). |

> Note: **Bangkok City Hall** (`rel:2380281`, centroid `13.753684, 100.501717`, `126.2 × 96.0 m` courtyard block, `45 m @ 138°` from the capital pin) is styled first via `bangkok_civic` + mapped/rule 5 storeys in BK-3.6, and promoted to bespoke if E2a requires it.

---

## 3. Second Ring & Outer Landmarks (BK-5 & BK-11)

| Type | OSM Way / Rel | Centroid (`lat, lon`) | Axis (°) | OSM Footprint (m) | Distance & Bearing | `height_m` | `radius_m` | Notes & Sources |
| --- | --- | --- | ---: | --- | --- | ---: | ---: | --- |
| `wat_ratchabophit` | `way:138947464` | `13.749209, 100.497129` | `93` | `130.7 × 124.3` | `707 m @ 221°` | `43.0` | `3500` | Rama V (1869): circular *phra rabiang* cloister in five-colour *Benjarong* porcelain round a 43 m gilded Sri Lankan-style bell chedi, axial viharn & ubosot. |
| `wat_bowonniwet` | `way:1401843958` (chedi) + `way:134003265` (Phra Ubosot) | `13.760357, 100.499845` | `122` / `169` | Ubosot `30.8 × 30.8` (T-plan), Chedi `16.9 × 16.8` | `729 m @ 346°` | `50.0` | `3500` | Dhammayuttika royal monastery (Rama III–IV): 50 m gilded bell chedi on square terrace between T-plan Phra Ubosot with Chinese-influenced gables and Viharn Phraศาสดา. |
| `wat_ratchapradit` | `way:342337807` | `13.749658, 100.495571` | `88` | `93.1 × 64.3` | `796 m @ 233°` | `35.0` | `3500` | Rama IV (1864): grey-white marble-clad ubosot on raised terrace flanked by Khmer prang towers and central *Phra Maha Chedi* (~35 m). |
| `bangkok_city_pillar` | `way:127290889` (`San Lak Mueang`) | `13.752564, 100.494031` | `179` | `16.6 × 16.2` | `816 m @ 259°` | `27.0` | `3500` | Founded 1782 by Rama I (rebuilt 1982): whitewashed cruciform *prasat* sanctuary crowned by an Ayutthaya-style white *prang* spire (~27 m) inside walled court. |
| `ministry_of_defence_bangkok` | `way:1481381668` / `rel:1307598` (`Q59773454`) | `13.751769, 100.494106` | `84` | `209.7 × 131.7` | `830 m @ 253°` | `22.0` | `3500` | Joachim Grassi (1882–84): 3-storey yellow Neo-Palladian courtyard ministry with green shutters, central pedimented portico, hipped red-tile roof, and historic bronze cannon forecourt. |
| `national_museum_bangkok` | `way:83608613` (Siwamokhaphiman) + `way:190739714` (Buddhaisawan Chapel) | `13.757735, 100.492112` | `114` | `52.0 × 27.2` + `39.7 × 20.1` | `1,085 m @ 292°` | `26.0` | `3500` | Front Palace (*Wang Na*, 1782): whitewashed Thai royal halls with multi-tiered orange-and-green roofs, gilt gables, and red-and-gold salas along Sanam Luang. |
| `phra_sumen_fort` | `way:107936513` (`historic=fort`, `height=32`) | `13.763998, 100.495730` | `137` | `47.0 × 45.4` | `1,275 m @ 331°` | `24.5` | `3500` | Built 1783 under Rama I in Santichaiprakarn Park: whitewashed octagonal 2-tier crenellated masonry bastion with heptagonal/octagonal timber-and-tile roofed watchtower (~24.5 m; OSM `height=32` overstates). |
| `thammasat_dome` | `way:134106801` | `13.757443, 100.489970` | `15` | `116.8 × 38.9` | `1,299 m @ 287°` | `28.0` | `3500` | Mew Aphaiwong (1936): long 3-storey cream riverside wing crowned by the iconic central four-sided pointed "pencil-tip" (*Dome*) spire (~28 m). |
| `santa_cruz_church` | `way:304092134` (`Q19884805`) | `13.738909, 100.493746` | `17` | `46.7 × 15.5` | `1,873 m @ 206°` | `36.0` | `3500` | Annibale Rigotti & Mario Tamagno (1916) in Kudi Chin: cream/pale-terracotta Italian Renaissance revival church with central red-domed octagonal campanile (~36 m) facing the Chao Phraya. |
| `wat_kalayanamit` | `way:342355805` (viharn `way:783759507`) | `13.740050, 100.491350` | `39` | `37.9 × 32.3` (viharn) | `1,876 m @ 215°` | `42.0` | `3500` | Founded 1825: towering riverside Viharn Luang (~42 m ridge, among the tallest Thai temple halls in Bangkok) flanked by smaller Chinese-gable ubosot and riverside *kuti* pavilions. |
| `wat_benchamabophit` | `way:31987500` (`Marble Temple`) | `13.766575, 100.514040` | `24` | `53.5 × 44.2` | `1,955 m @ 44°` | `28.0` | `3500` | Prince Naris (1899): cruciform white Carrara marble ordination hall with four-tiered orange-glazed roofs, gilded *chofa* gables, marble courtyard & cloister, red-and-white cast-iron canal bridges. |
| `wat_prayun` | `way:30753271` (`Phra Borommathat Maha Chedi`) | `13.737368, 100.495376` | `6` | `41.7 × 41.6` | `1,962 m @ 200°` | `60.5` | `3500` | Rama III (1828, UNESCO Cultural Heritage Award): gleaming white 60.5 m Sri Lankan bell chedi ringed by a circular *vihara khot* porch of 18 small chedis + *Khao Mo* turtle pond garden. |
| `chinatown_gate_wat_traimit` | `way:342811168` (Mondop) + `way:342812020` (Chinatown Gate) | `13.737746, 100.513646` | `81` | Mondop `58.0 × 34.8`, Gate `13.1 × 5.1` (offset `-73 E, -62 N` m) | `2,238 m @ 144°` | `52.0` | `3500` | Grouped row: 4-storey white marble & gilt *Phra Maha Mondop* (~52 m, 2009) housing the Golden Buddha, paired with the red-and-gold Odeon Circle ceremonial *paifang* gate (1999). |
| `ananta_samakhom` | `way:31987148` + `node:358479765` (Rama V statue) | `13.771718, 100.513038` | `107` | `102.9 × 49.5` | `2,339 m @ 32°` | `49.5` | `3500` | Mario Tamagno & Annibale Rigotti (1908–15): white Carrara marble Italian Renaissance/Neoclassical throne hall (112.5 × 49.5 m, 49.5 m central patinated copper dome + 6 subsidiary domes) facing the Royal Plaza & King Chulalongkorn equestrian monument. |
| `san_chao_pho_suea` | `way:1481450245` | `13.753804, 100.498306` | `96` | `41.5 × 24.6` | `339 m @ 267°` | `11.0` | `300` | Teochew Tiger God Shrine (1834) on Thanon Tanao: ornate red-and-gold Chinese temple roof with ceramic dragon ridge, lantern courtyard & gilded entrance gate (`radius_m=300` so local walks show it without taking a capital-eye slot). |
| `king_prajadhipok_museum` | `way:229966092` | `13.756076, 100.506471` | `22` | `49.5 × 26.6` | `592 m @ 67°` | `16.0` | `450` | Former Soteuk / John Sampson & Son department store (1906) at Phan Fa Bridge: 3-storey cream Neoclassical corner block with rounded corner turret cupola (`radius_m=450`). |
| `wat_mangkon_kamalawat` | `way:301157259` | `13.743447, 100.509436` | `29` | `134.4 × 70.5` | `1,457 m @ 144°` | `15.0` | `1400` | Largest Chinese Buddhist temple in Bangkok (1871, Charoen Krung Rd): sweeping green-and-gold glazed tile roofs with twin dragons & courtyard halls (`radius_m=1400` for Chinatown views). |

---

## 4. Chao Phraya River Bridges (BK-6)

| ID / Type | OSM Way | Crossing (`lat, lon`) | Bearing (°) | Spans (m) | Width / Clear (m) | Status & Source |
| --- | --- | --- | ---: | --- | --- | --- |
| `br_bangkok_pinklao_bridge` | `way:25715010` | `13.76188, 100.49108` | `142.5` | `83 + 110 + 83` (276 m) | `32.2` / `13.5` | Existing `conf: 2` (`tier: 3`, concrete box girder, 1,482 m from eye). |
| `br_bangkok_pok_klao_bridge` | `way:836977240` + `way:824773646` (Sky Park) | `13.73921, 100.49865` | `37.0` / `18.8` | `65 + 100 + 65` (230 m) | `37.7` / `11.0` | Parallel to Memorial Bridge (1984) with central Chao Phraya Sky Park planted viaduct (2020) in the gap (`tier: 2`, `conf: 2`, 1,672 m). |
| `br_bangkok_memorial_bridge` | `way:25706395` | `13.73945, 100.49773` | `18.8` | `78 + 78 + 78` (234 m) | `16.68` / `8.7` | Existing `conf: 2` (`tier: 2`, 1932 dark-green steel through-truss, 1,683 m). |
| `br_bangkok_rama_viii_bridge` | `way:965040447` | `13.76940, 100.49650` | `118.5` | `75 + 50 + 50 + 300` (475 m) | `29.2` / `12.5` | Bespoke `landmark_bk_rama_viii.gd` (or upgraded spec, 1,767 m): single 160 m Thonburi inverted-Y concrete pylon, golden lotus observation pod finial, asymmetric golden cable fans, lit gold at night. |
| `br_bangkok_taksin_bridge` | `way:156261465` | `13.71942, 100.51220` | `103.8` | `66 + 92 + 66` | `26.0` / `14.0` | Existing `conf: 2` (`tier: 2`, 4,020 m). |
| `br_bangkok_krung_thon_bridge` | `way:28510028` | `13.78107, 100.50244` | `294.6` | `58+58+64+64+58+58` | `17.0` / `8.5` | Existing `conf: 2` (`tier: 3`, 3,015 m). |
| `br_bangkok_rama_iii_bridge` | `way:154773964` | `13.70112, 100.49237` | `121.8` | `125 + 226 + 125` | `23.0` / `33.0` | Existing `conf: 2` (`tier: 3`, 5,960 m). |
| `br_bangkok_rama_vii_bridge` | `way:852446176` | `13.81415, 100.51393` | `36.5` | `85 + 120 + 85` | `29.1` / `8.9` | Existing `conf: 2` (`tier: 3`, 6,830 m). |
| `br_bangkok_rama_ix_bridge` | `way:150573914` | `13.68250, 100.51770` | `37.2` | `46.8+57.6+61.2+450+...` | `33.0` / `41.0` | Single-plane yellow cable-stayed bridge (1987, 8,140 m; pylons 87 m above deck = 128 m ASL). |
| `br_bangkok_rama_vi_bridge` | `way:23958080` | `13.81347, 100.51549` | `47.5` | `77+84+120+84+77` | `10.0` / `10.0` | Existing `conf: 1` (cantilever rail truss, 6,790 m). |
| `br_bangkok_bhumibol_bridge` | `rel` industrial ring | `13.66528, 100.53944` | `40.0` | `326` / `398` main | `30.0` / `45.0` | Existing `conf: 1` (10.7 km, outside 9 km landmark reach). |

---

## 5. Skyline Towers (BK-11)

| Tower | OSM Way / Rel | Centroid (`lat, lon`) | Axis (°) | Footprint (m) | Distance & Bearing | Height (m) | Notes & Treatment |
| --- | --- | --- | ---: | --- | --- | ---: | --- |
| Magnolias Waterfront (ICONSIAM) | `way:680736465` | `13.727514, 100.510502` | `169` | `78.6 × 53.4` | `3,105 m @ 162°` | `318.0` | OSM `height=317.95`, 70 lv; tapered white-and-bronze spire (`skyline: true`). |
| Residences at Mandarin Oriental | `way:680739268` | `13.727901, 100.510937` | `44` | `67.3 × 46.2` | `3,079 m @ 161°` | `272.2` | OSM `height=272.2`, 52 lv; warm champagne-gold riverside tower beside ICONSIAM (`skyline: true`). |
| The River South Tower | `way:445340031` (`part:445340025`) | `13.721318, 100.510374` | `101` | `163.1 × 97.5` | `3,762 m @ 165°` | `265.6` | OSM `height=265.64`, 73 lv; curved blue-silver glass tower (`skyline: true`). |
| State Tower | `way:25805374` | `13.721650, 100.516923` | `19` | `128.0 × 87.7` | `3,969 m @ 155°` | `247.2` | CTBUH / Wikipedia 247.2 m, 68 lv (2001): neoclassical cream massing with 30 m golden Lebua rooftop dome & balconies (`skyline: true`). |
| Jewelry Trade Center | `way:342271323` | `13.723000, 100.520079` | `170` | `79.6 × 27.6` | `3,994 m @ 150°` | `220.7` | CTBUH 220.7 m, 59 lv (1996): stepped silver-blue glass crown on Silom Rd (`skyline: true`). |
| Baiyoke Tower II | `rel:18728185` (`parts:443491485..87`) | `13.754634, 100.540535` | `22` | `90.6 × 56.5` | `4,228 m @ 89°` | `304.0` | OSM parts 284 / 295 / 304 m (328 m to antenna tip), 85 lv (1997): tan/white stepped octagonal hotel with gold parapet bands & lattice spire (`skyline: true`). |
| Sathorn Unique Tower | `way:321722223` | `13.717310, 100.515152` | `110` | `66.4 × 35.5` | `4,343 m @ 160°` | `185.0` | Unfinished 1997 ghost tower, OSM `building:levels=49` (~185 m): weathered raw grey concrete frame, open floor slabs, unglazed circular balconies (`skyline: true`). |
| King Power MahaNakhon | `way:4446511xx..2xx` (14+ parts) | `13.723560, 100.528350` | `160` | ~`55 × 55` | `4,470 m @ 140°` | `314.2` | OSM `building:part` massing already carries the helical pixel-ribbon cutouts to 314.2 m; enhance glass curtain & lit pixel recesses (`skyline: true`). |
| Empire Tower | `way:32004527` | `13.720330, 100.530145` | `65` | `120.2 × 51.6` | `4,865 m @ 140°` | `226.8` | CTBUH 226.8 m, 58 lv (1999) at Sathorn–Naradhiwas junction: grey-granite & blue-glass stepped office complex (`skyline: true`). |
| One City Centre (OCC) | `way:1222766567` | `13.741961, 100.546209` | `10` | `48.4 × 44.5` | `5,022 m @ 105°` | `275.8` | OSM `height=275.76`, 61 lv (2023): crisp pale-blue diagrid/mullion office tower on Phloen Chit (`skyline: true`). |
| *Excluded OSM bad height:* Sindhorn Residences | `way:402124521` | `13.738703, 100.544004` | `98` | `75.1 × 52.7` | `4,906 m @ 110°` | *126 m (OSM mistakenly tags `height=314` on 36 lv)* | Identified in BK-0.5 (`addr:housename=Sindhorn Residences`, `building:levels=36`); clamp/correct in height overrides rather than building a false 314 m supertall. |
