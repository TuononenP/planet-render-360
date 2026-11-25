# Singapore Landmark & Major Building Sources

Measured from the bundled OSM snapshots (`assets/osm_snapshots/capital_sg_9128967_28385007_detailed.osmb` & `far.osmb`, centred on Padang / City Hall `1.28967, 103.85007`, OSM base `2026-11-03`) cross-checked with URA / CTBUH / Wikipedia architectural dimensions. No Russian-operated hosts (`HostPolicy`).

## 1. Primary & Marina Bay Hero Icons (`sg_reg_bay.gd`)

| Type | Name | OSM Element | Centroid (lat, lon) | Footprint (m) | Height (m) | Key Features |
| --- | --- | --- | --- | --- | ---: | --- |
| `marina_bay_sands` | Marina Bay Sands | `w116801004`, `w172307472`, `w172307471`, `w116800998`, `r2298319`, `w172013197`, `w821764692` | `1.28368, 103.86071` | 340 × 90 + podium | 207.0 | 3 bent 55-storey splayed towers (~7° bend, 120 m / 106 m spacing), 340 m SkyPark hull + 66.5 m N cantilever + 150 m infinity pool, Shoppes, Crystal Pavilion North, Apple glass dome sphere |
| `esplanade_singapore` | Esplanade – Theatres on the Bay | `w256163011`, `w256163012`, `w97582570` | `1.28953, 103.85582` | 96×73 + 78×107 | 35.0 | Twin asymmetric rounded shells covered in normal-graded triangular aluminium durian sunshades over tinted glass, linking podium, waterfront outdoor theatre |
| `merlion_park` | Merlion Park | `w687917300`, `n6283080658` | `1.28678, 103.85450` | 38 × 26 jetty | 8.6 | 8.6 m white sculpted Merlion statue on wave plinth facing east, translucent arcing water jet + splash ring, stepped bay jetty, 2 m Merlion Cub |
| `singapore_flyer` | Singapore Flyer | OSM bayfront site | `1.28930, 103.86313` | 150 m dia wheel | 165.0 | 150 m slender open ladder-truss rim, tension cable spokes, 28 exterior glass capsules, twin inclined A-frame legs, 3-storey circular-atrium terminal |
| `artscience_museum` | ArtScience Museum | Marina Bay promenade | `1.28627, 103.85927` | 72 × 72 | 60.0 | 10 asymmetric upward-curving white lotus petals with glazed skylight tips, circular reflective lily pond |
| `helix_bridge` | Helix Bridge | `w164881537` + 4 pods | `1.28765, 103.86052` | 280 × 12 curved | 14.0 | Curved 280 m stainless-steel counter-wound DNA double-helix tubes, radial struts, fritted-glass canopies, 4 cantilevered bay viewing pods, Y-piers, LED ribbons |
| `fullerton_hotel` | The Fullerton Hotel | `w46595395` | `1.28618, 103.85309` | 128 × 80 | 37.0 | 1928 Aberdeen-grey granite neoclassical palazzo, giant Doric colonnades on all four facades, pedimented porticoes, rooftop lighthouse |
| `fullerton_waterfront` | Fullerton Heritage Waterfront | `w46595394`, `w395113920`, `w406900756` | `1.28480, 103.85395` | 172 × 32 + piers | 18.0 | One Fullerton promenade, curved Art Deco Waterboat House, arched Clifford Pier with red lanterns, Customs House |
| `supertree_grove` | Supertree Grove & OCBC Skyway | Gardens by the Bay | `1.28200, 103.86390` | 160 × 120 grove | 50.0 | 12 flared vertical-garden Supertrees (25–50 m), concrete cores, magenta/bronze trellis trunks, inverted-umbrella canopies, 128 m OCBC Skyway at 22 m |
| `gardens_by_the_bay_domes` | Flower Dome & Cloud Forest | Gardens by the Bay | `1.28410, 103.86540` | 190 × 110 pair | 58.0 | Low seashell Flower Dome (38 m) & peaked Cloud Forest (58 m with inner green mountain core), crisp external white steel arch ribs over glass |
| `marina_barrage` | Marina Barrage | Marina Channel | `1.28050, 103.87100` | 350 × 65 | 24.0 | 350 m dam with 9 steel crest-gate bays, sweeping spiral Green Roof lawn ramp, visitor pavilion |

## 2. Civic District & Heritage Icons (`sg_reg_civic.gd` & `sg_reg_heritage.gd`)

| Type | Name | OSM Element | Centroid (lat, lon) | Height (m) | Notes |
| --- | --- | --- | --- | ---: | --- |
| `national_gallery_sg` | National Gallery Singapore | `w170960936`, `w46595597` | `1.29015, 103.85150` | 60.0 | Former Supreme Court green copper dome + Former City Hall 18-column Corinthian colonnade + gold filigree roof veil |
| `supreme_court_sg` | Supreme Court of Singapore | `w46594825` | `1.29060, 103.85080` | 46.0 | Foster + Partners translucent marble/glass atrium under cantilevered perforated-aluminium flying-saucer disc |
| `victoria_theatre_sg` | Victoria Theatre & Concert Hall | `r3899820` | `1.28824, 103.85155` | 54.0 | Twin cream Palladian wings, central 54 m clock tower + dome, Raffles bronze statue & Dalhousie Obelisk |
| `st_andrews_cathedral_sg` | St Andrew's Cathedral | `w155980025`, `w46594828` | `1.29230, 103.85225` | 63.0 | Fixes OSM `h=0`; white madras-chunam neo-Gothic nave, lancets, buttresses, slim 63 m spire, open green lawn |
| `arts_house_parliament_sg` | The Arts House & Parliament House | `w243427705` | `1.28885, 103.85060` | 28.0 | 1827 white neoclassical Old Parliament + elephant statue + modern Parliament block with bronze prism roof |
| `padang_ensemble_sg` | Padang Ensemble | `w46594820`, `w46594819`, `w256153714` | `1.29055, 103.85293` | 18.0 | Cricket Club, Recreation Club, Cenotaph, Lim Bo Seng Memorial + open Padang cricket green (`tree_rect`) |
| `civilian_war_memorial_sg` | Civilian War Memorial | `w460428718` | `1.29320, 103.85465` | 67.0 | Four identical tapering 67 m white concrete pillars around reflecting pool |
| `raffles_hotel_sg` | Raffles Hotel | Beach Rd | `1.29490, 103.85445` | 24.0 | White 3-storey neo-Renaissance colonial hotel, cast-iron porte-cochère, verandas, green shutters, red tile roofs |
| `old_hill_street_police_sg` | Old Hill Street Police Station | `r6955290` | `1.29075, 103.84805` | 30.0 | Six-storey white arcaded neoclassical building with 927 rainbow-banded timber louvred shutters |
| `asian_civilisations_museum_sg` | Asian Civilisations Museum | `w46595390` | `1.28744, 103.85139` | 22.0 | 1867 white Palladian riverfront building + modern reflective glass/titanium wing |
| `sri_mariamman_temple_sg` | Sri Mariamman Temple | `w300380459` | `1.28275, 103.84525` | 18.0 | 6-tier polychrome sculpted Dravidian gopuram on South Bridge Rd, boundary wall with Nandi figures |
| `buddha_tooth_relic_sg` | Buddha Tooth Relic Temple | `w47298635` | `1.28145, 103.84434` | 34.0 | Crimson-and-white Tang-dynasty palace hall with dark-grey upturned tiered roofs |
| `thian_hock_keng_sg` | Thian Hock Keng Temple | `w172272611` | `1.28095, 103.84750` | 14.0 | 1840 Hokkien courtyard temple with swallowtail ceramic roofs & porcelain dragon ridges |
| `sultan_mosque_sg` | Sultan Mosque (Masjid Sultan) | Kampong Glam | `1.30232, 103.85905` | 32.0 | Twin golden onion domes with dark glass-bottle base bands, four corner minarets, cream walls |
| `lau_pa_sat_sg` | Lau Pa Sat | `w45098520` | `1.28068, 103.85047` | 24.0 | Fixes OSM `h=0`; 1894 Victorian octagonal cast-iron market, filigree arches, central clock tower, red roof |
| `clarke_quay_sg` | Clarke Quay | Singapore River | `1.29060, 103.84650` | 18.0 | Pastel 19th-century riverfront godowns under translucent blue/white ETFE jellyfish tensile canopies |
| `chijmes_sg` | CHIJMES Hall | `w97666818` | `1.29514, 103.85192` | 36.0 | 1904 crisp white neo-Gothic chapel with spire, buttresses, rose window & cloisters |
| `armenian_church_sg` | Armenian Church | `w172368093` | `1.29315, 103.84940` | 20.0 | 1835 white neoclassical Doric rotunda chapel & cross spire |
| `central_fire_station_sg` | Central Fire Station | `w172368086` | `1.29230, 103.84915` | 34.0 | 1908 red-brick and white-plaster "Blood and Bandage" firehouse with 34 m striped hose tower |
| `national_museum_sg` | National Museum of Singapore | `w32342169` | `1.29659, 103.84849` | 30.0 | 1887 neo-Palladian museum crowned by silver fish-scale rotunda dome |
| `national_stadium_sg` | National Stadium (Sports Hub) | Kallang | `1.30430, 103.87420` | 82.0 | 310 m diameter free-spanning white/silver retractable dome visible across Marina Bay |

## 3. Bespoke & Parametric Bridges (`sg_reg_bridges.gd` & `bridge_specs_southeast_asia_au_nz.gd`)

- **Bespoke:** `helix_bridge` (280 m), `cavenagh_bridge_sg` (79 m, `w534684103`), `anderson_bridge_sg` (70 m, `w29377119`), `elgin_bridge_sg` (66 m, `w474832236`).
- **Parametric (`conf: 2`):** `Esplanade Bridge` (261 m, 7 low arches), `Jubilee Bridge` (220 m, balanced cantilever), `Coleman Bridge` (75 m), `Read Bridge` (48 m), `Ord Bridge` (52 m, `w688756545`), `Alkaff Bridge` (55 m, multicolour truss), `Benjamin Sheares Bridge` (high concrete viaduct), `Merdeka Bridge` (610 m).

## 4. OSM Height Anomaly Audit (`SG-0.3`, Fixed via `SgTowerSpecs` & `SingaporeNotable`)

| Building | OSM Element | OSM Tag | Verified Height | Fix Channel |
| --- | --- | --- | ---: | --- |
| UOB Plaza Tower 1 | `w335167827` | `h=0` | 280.0 m | `SgTowerSpecs` |
| UOB Plaza Tower 2 | `w171999282` | `h=0` | 162.0 m | `SgTowerSpecs` |
| Republic Plaza | `w171999304` | `h=0` / 43 m podium | 280.0 m | `SgTowerSpecs` |
| CapitaSpring | `w694047464` | `h=0` | 280.0 m | `SgTowerSpecs` |
| Guoco Tower | `w393100845` | `h=180` (wrong) | 283.7 m | `SgTowerSpecs` |
| CapitaGreen | `w393100853` | `h=-, lv=40` | 242.0 m | `SgTowerSpecs` |
| MBFC Towers 1–3 | `w116905040/42/41` | all `h=245` | 192 / 239 / 245 m | `SgTowerSpecs` |
| The Sail @ Marina Bay | `w325793782` | `h=-` | 245 / 215 m | `SgTowerSpecs` |
| Asia Square Tower 1 | `w407941850` | `h=0` | 229.0 m | `SgTowerSpecs` |
| Marina Bay Suites | `w1035285485` | `h=-` | 239.0 m | `SgTowerSpecs` |
| Suntec Towers 1–5 | `w46595145–48`, `w102938119` | `h=0` / `-` | 177 m × 4, 78 m | `SgTowerSpecs` |
| South Beach Tower & Res | `w427064886`, `w427064883` | `h=0` | 190 / 192 m | `SgTowerSpecs` |
| Maybank Tower / BOC | `w106193386`, `w106193390` | `h=0` | 175 / 168 m | `SgTowerSpecs` |
| One George St / OUE | `w47300930`, `w986973996` | `h=0` | 153 / 88 m | `SgTowerSpecs` |
| 18 Robinson / Hong Leong | `w424896147`, `w47345013` | `h=-` | 180 / 158 m | `SgTowerSpecs` |
| State Courts Towers | `w699163980` | `h=0` | 178.0 m | `SgTowerSpecs` |
| Parkroyal Pickering / Marina Bay | `w172271707`, `w742205653` | `h=0` | 89 / 82 m | `SgTowerSpecs` |
| Mandarin Oriental | `w46594816` | `h=0` | 78.0 m | `SgTowerSpecs` |
| St Andrew's Cathedral | `w155980025` | `h=0` | 63.0 m | Bespoke (`st_andrews_cathedral_sg`) |
| Lau Pa Sat | `w45098520` | `h=0` | 24.0 m | Bespoke (`lau_pa_sat_sg`) |
| Peninsula Plaza / Grand Park / Clarke Quay Central / Carlton / Marina Sq / Yue Hwa / Great Eastern / Furama / The Arcade / Ascott | `w46594832` etc. | `h=0` / `-` | 30–130 m | `SingaporeNotable` |
