# London Landmark Sources & Site Measurements

Verified coordinates, OSM element IDs, footprints, bearings, and heights for `PLAN_London_super_realistic.md`.
Distances and bearings are measured from the bundled London preset vantage on Queen's Walk by Westminster Bridge
(`51.5018, -0.1196`, `scripts/data/preset_views.gd:108`) unless noted otherwise.

## 1. Bundled OSM Snapshot Audit (`LN-0.2`)

Decoded from `assets/osm_snapshots/london_*.osmb` (base `2026-11-02`):

- `london_detailed.osmb`: 20,880 elements — 3,241 buildings, 3,114 `building:part`s, 4,186 trees, 491 railways (370
  `rail`, 112 `subway`), 447 bridges, 34 waters, 46 historic, 17 piers.
- Explicit height coverage: 65 / 3,241 buildings (2.0 %); `building:levels`: 1,027 (31.7 %); untyped `building=yes`:
  1,790 (55.2 %).
- Ring truncation: `london_ring1600.osmb` (`hw=800, ww=13`) and `london_ring2500.osmb` (`hw=800, ww=30`) both hit the
  800-highway cap.

### Notable height & tag anomalies fixed by this plan

| Site | OSM Element | Dist / Brg | Snapshot Tags | Real Height | Fix |
| --- | --- | --- | --- | --- | --- |
| County Hall | `relation 1789966` | 65 m / 52° | `h=45, lv=6` | ~36 m eaves / 45 m fleche | Bespoke `county_hall` |
| National Theatre | `relation 2023676` | 691 m / 33° | `h=6.5` (wrong) | 35 m flytowers | Bespoke `national_theatre` |
| Somerset House | `way 372841786` | 1,010 m / 8° | `h=-, lv=2` | 28 m river terrace | Bespoke `somerset_house` |
| Methodist Central Hall | `way 185101970` | 746 m / 255° | `h=-, lv=-` | 67 m dome | Bespoke `methodist_central_hall` |
| Horse Guards | `way 133153176` | 612 m / 302° | `h=-, lv=-` | 28 m clock turret | Bespoke `whitehall_horse_guards` |
| Nelson's Column | `way 150920358` | 876 m / 319° | `h=-, lv=-` | 51.6 m | Bespoke `trafalgar_square` |
| St Martin-in-the-Fields | `way 30734422` | 925 m / 327° | `h=-, lv=-` | 56 m spire | Bespoke `trafalgar_square` |
| Westminster Cathedral | `way 10810446` | 1,517 m / 243° | `h=-, lv=-` | 83 m campanile | Bespoke `westminster_cathedral` |
| 8 Bishopsgate | `way 1136851840` | 2,835 m / 62° | `h=-, lv=51` | 204 m | `LnTowerSpecs` `eight_bishopsgate` |
| Royal Albert Hall | `way 372860405` | 4,007 m / 269° | `h=-, lv=-` | 41 m dome | Bespoke `royal_albert_hall` |

## 2. Existing 10 London Landmarks (Upgraded in `LN-2`)

| Type | Name | Lat, Lon | Height | Yaw | Source |
| --- | --- | --- | ---: | ---: | --- |
| `big_ben` | Palace of Westminster & Elizabeth Tower | `51.5007, -0.1246` | 96.0 m | 6.2° | OSM `way 123557148`, Historic England |
| `tower_bridge` | Tower Bridge | `51.5055, -0.0754` | 65.0 m | 95.0° | Historic England / Wikipedia |
| `london_eye` | London Eye | `51.5033, -0.1196` | 135.0 m | -10.0° | OSM `way 204068874`, Marks Barfield |
| `st_pauls` | St Paul's Cathedral | `51.5138, -0.0984` | 111.0 m | -5.5° | Historic England |
| `shard` | The Shard | `51.5045, -0.0865` | 309.6 m | 0.0° | OSM `way 31110737`, Renzo Piano |
| `tower_of_london` | Tower of London | `51.5081, -0.0759` | 27.5 m | 0.0° | Historic Royal Palaces |
| `buckingham_palace` | Buckingham Palace + Queen Victoria Memorial | `51.5014, -0.1419` | 24.0 m | -32.0° | Royal.uk / Historic England |
| `westminster_abbey` | Westminster Abbey | `51.4994, -0.1273` | 69.0 m | 5.0° | Historic England |
| `st_mary_axe` | 30 St Mary Axe (The Gherkin) | `51.5145, -0.0803` | 180.0 m | 0.0° | OSM `way 4959489`, Foster + Partners |
| `waterloo_station` | London Waterloo Station | `51.5031, -0.1132` | 27.0 m | 0.0° | OSM `way 4245075` |

## 3. New Bespoke Landmarks & Bridges (`LN-3`, `LN-4`, `LN-6`)

| Type | Name | Lat, Lon | Height | Yaw | OSM / Architectural Reference |
| --- | --- | --- | ---: | ---: | --- |
| `county_hall` | County Hall | `51.5019, -0.1188` | 45.0 m | -78.0° | OSM `relation 1789966` (Ralph Knott, 1922) |
| `westminster_bridge` | Westminster Bridge | `51.5009, -0.1218` | 14.0 m | 2.5° | OSM `ways 216998718, 920237496` (Thomas Page, 1862; 7 green iron arches, 250 m) |
| `hungerford_golden_jubilee` | Hungerford & Golden Jubilee Bridges | `51.50621, -0.12031` | 32.0 m | 26.0° | OSM `ways 4254121, 186931859, 151744359` (Hawkshaw 1864 + Lifschutz Davidson 2002) |
| `millennium_bridge` | Millennium Bridge | `51.5096, -0.0986` | 16.0 m | 92.3° | OSM `ways 7225360, 7225371` (Foster + Arup 2000; 81/144/108 m lateral suspension) |
| `portcullis_house` | Portcullis House | `51.5015, -0.1247` | 32.0 m | 6.0° | OSM `way 256497249` (Hopkins Architects, 2001) |
| `whitehall_horse_guards` | Horse Guards & Banqueting House | `51.5047, -0.1270` | 28.0 m | -101.0° | OSM `ways 133153176, 140470549` (William Kent 1759; Inigo Jones 1622) |
| `whitehall_court` | Whitehall Court | `51.5056, -0.1243` | 42.0 m | -76.0° | OSM `relation 5485985` (Archer & Green, 1884) |
| `trafalgar_square` | Trafalgar Square (Nelson's Column & National Gallery) | `51.5080, -0.1281` | 51.6 m | -10.0° | OSM `ways 150920358, 30734422` (Railton 1843; Wilkins 1838; Gibbs 1726) |
| `admiralty_arch` | Admiralty Arch | `51.5068, -0.1287` | 28.0 m | 56.0° | OSM `relation 17074208` (Aston Webb, 1912) |
| `royal_festival_hall` | Royal Festival Hall | `51.5058, -0.1167` | 28.0 m | 124.0° | OSM `way 5987419` (Robert Matthew & Leslie Martin, 1951) |
| `national_theatre` | Royal National Theatre | `51.5071, -0.1142` | 35.0 m | -22.0° | OSM `relation 2023676` (Denys Lasdun, 1976) |
| `somerset_house` | Somerset House | `51.5110, -0.1173` | 28.0 m | -22.0° | OSM `way 372841786` (William Chambers, 1796) |
| `oxo_tower` | OXO Tower Wharf | `51.5084, -0.1085` | 67.0 m | -8.0° | OSM `ways 25298098, 1449888762` (Albert Moore, 1929) |
| `methodist_central_hall` | Methodist Central Hall Westminster | `51.5001, -0.1298` | 67.0 m | 5.0° | OSM `way 185101970` (Lanchester & Rickards, 1912) |
| `lambeth_palace` | Lambeth Palace | `51.4956, -0.1199` | 24.0 m | 5.0° | OSM `relation 1403938` (Morton's Tower, 1495) |
| `cleopatras_needle` | Cleopatra's Needle | `51.5086, -0.1204` | 21.0 m | -22.0° | OSM `way 297331784` (1450 BC / erected 1878) |
| `tate_modern` | Tate Modern (Bankside) | `51.5076, -0.0994` | 99.0 m | -4.0° | Giles Gilbert Scott 1963 / Herzog & de Meuron 2000 & 2016 |
| `shakespeares_globe` | Shakespeare's Globe | `51.5081, -0.0972` | 15.0 m | 0.0° | Theo Crosby / Pentagram, 1997 |
| `bank_junction` | Royal Exchange & Bank of England | `51.5136, -0.0880` | 30.0 m | 10.0° | William Tite 1844; John Soane / Herbert Baker |
| `monument_london` | Monument to the Great Fire of London | `51.5101, -0.0860` | 61.5 m | 0.0° | Christopher Wren & Robert Hooke, 1677 |
| `lloyds_building` | Lloyd's Building | `51.5131, -0.0823` | 88.0 m | -14.0° | Richard Rogers, 1986 |
| `st_pancras_station` | St Pancras Renaissance Hotel & Station | `51.5300, -0.1257` | 82.0 m | -18.0° | George Gilbert Scott 1873; W. H. Barlow 1868 |
| `british_museum` | British Museum | `51.5194, -0.1270` | 26.0 m | -18.0° | Robert Smirke 1852; Foster + Partners Great Court 2000 |
| `westminster_cathedral` | Westminster Cathedral | `51.4961, -0.1397` | 83.0 m | 26.0° | OSM `way 10810446` (John Francis Bentley, 1903) |
| `battersea_power_station` | Battersea Power Station | `51.4816, -0.1445` | 101.0 m | -15.0° | Giles Gilbert Scott, 1933–1955 |
| `bt_tower` | BT Tower | `51.5215, -0.1389` | 188.4 m | 0.0° | OSM `way 5022282` (Eric Bedford, 1965) |
| `royal_albert_hall` | Royal Albert Hall & Albert Memorial | `51.5009, -0.1774` | 41.0 m | 0.0° | OSM `way 372860405` (Fowke & Scott, 1871) |
| `natural_history_museum` | Natural History Museum | `51.4967, -0.1764` | 58.0 m | 0.0° | Alfred Waterhouse, 1881 |
| `marble_wellington_arches` | Marble Arch & Wellington Arch | `51.5025, -0.1508` | 21.0 m | -38.0° | Decimus Burton 1830 (Wellington Arch at Hyde Park Corner) |
| `o2_arena` | The O2 (Millennium Dome) | `51.5030, 0.0032` | 95.0 m | 0.0° | Richard Rogers, 1999 |

## 4. London Skyline Towers (`LnTowerSpecs`, `skyline: true`)

| Type | Name | Lat, Lon | Height | Cluster |
| --- | --- | --- | ---: | --- |
| `twenty_two_bishopsgate` | 22 Bishopsgate | `51.5146, -0.0828` | 278.0 m | City of London |
| `heron_tower` | 110 Bishopsgate (Heron Tower) | `51.5162, -0.0810` | 230.1 m | City of London |
| `leadenhall_building` | The Leadenhall Building (Cheesegrater) | `51.5138, -0.0822` | 224.5 m | City of London |
| `eight_bishopsgate` | 8 Bishopsgate | `51.5137, -0.0837` | 204.0 m | City of London |
| `the_scalpel` | 52 Lime Street (The Scalpel) | `51.5130, -0.0816` | 190.0 m | City of London |
| `tower_42` | Tower 42 | `51.5153, -0.0840` | 183.0 m | City of London |
| `walkie_talkie` | 20 Fenchurch Street (Walkie-Talkie) | `51.5112, -0.0836` | 160.0 m | City of London |
| `willis_building` | Willis Building | `51.5132, -0.0812` | 125.0 m | City of London |
| `barbican_cromwell` | Cromwell Tower (Barbican) | `51.5205, -0.0928` | 123.0 m | Barbican |
| `barbican_lauderdale` | Lauderdale Tower (Barbican) | `51.5198, -0.0965` | 123.0 m | Barbican |
| `barbican_shakespeare` | Shakespeare Tower (Barbican) | `51.5208, -0.0947` | 123.0 m | Barbican |
| `one_blackfriars` | One Blackfriars | `51.5078, -0.1047` | 163.0 m | South Bank |
| `south_bank_tower` | South Bank Tower | `51.5077, -0.1072` | 155.0 m | South Bank |
| `shell_centre` | Shell Centre Tower | `51.5037, -0.1167` | 107.0 m | South Bank |
| `millbank_tower` | Millbank Tower | `51.4923, -0.1257` | 118.0 m | Westminster |
| `strata_se1` | Strata SE1 | `51.4930, -0.0998` | 148.0 m | Elephant & Castle |
| `st_george_wharf` | St George Wharf Tower | `51.4851, -0.1277` | 181.0 m | Vauxhall |
| `one_nine_elms` | One Nine Elms (City Tower) | `51.4835, -0.1292` | 200.0 m | Nine Elms |
| `one_canada_square` | One Canada Square | `51.5049, -0.0195` | 235.0 m | Canary Wharf |
| `landmark_pinnacle` | Landmark Pinnacle | `51.5030, -0.0258` | 233.0 m | Canary Wharf |
| `newfoundland_cw` | Newfoundland (Canary Wharf) | `51.5047, -0.0250` | 220.0 m | Canary Wharf |
| `one_park_drive` | One Park Drive | `51.5016, -0.0151` | 205.0 m | Canary Wharf |
| `citigroup_cw` | 25 Canada Square (Citigroup) | `51.5042, -0.0182` | 200.0 m | Canary Wharf |
| `hsbc_cw` | 8 Canada Square (HSBC) | `51.5054, -0.0175` | 199.5 m | Canary Wharf |
| `barclays_cw` | 1 Churchill Place (Barclays) | `51.5056, -0.0145` | 156.0 m | Canary Wharf |
