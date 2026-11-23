# Miami Landmark & Major Building Sources — Measured Envelopes, Heights & Late-2026 Status

Models use true metres and merged textured surfaces (`LandmarkMesh`, `LandmarkMaterials`, `SkyKit`, `TowerSpec`).
Footprints, centroids, and axis bearings (`yaw_deg`) are measured from OpenStreetMap (`Miami.osm.pbf` / `south_florida.osm.pbf`, replication `2026-11-21T00:00:00Z` / `2026-11-23T00:00:00Z`, © OpenStreetMap contributors, ODbL) and bundled in `assets/osm_snapshots/miami_*.osmb` and `assets/osm_snapshots/miami_beach_*.osmb`.
Heights are cross-checked against OSM `height` / `building:part` tags (Miami-Dade LiDAR import), Wikidata `P2048`, CTBUH, and dated late-2026 construction records.

---

## 1. Late-2026 Reality Check (MI-0.3, as of November 2026)

| Item | Address / Location | Late-2026 Status | Height (m) | Decision | Dated Source |
| --- | --- | --- | --- | --- | --- |
| **Waldorf Astoria Residences Miami** | 300 N Biscayne Blvd (`way:1459955388`) | Under construction — 89 of 100 floors poured, 9th cube underway | `320.0` full / `285.0` standing | `build-partial` (Cubes 1–8 + partial 9th cube to 285 m) | Florida YIMBY (Aug 27, 2026) / Hilton (Nov 10, 2026) |
| **Okan Tower** | 555 N Miami Ave (`25.779700, -80.193200`) | Under construction — ~66 of 72 floors poured | `275.0` full / `262.0` standing | `build-partial` (262 m curved shaft) | Florida YIMBY (Apr 22, 2026) |
| **Cipriani Residences Miami** | 1420 S Miami Ave (`way:301823928`) | Topped out July 2026 at full 80-storey height | `289.6` | `build` (full height) | Florida YIMBY (Apr 21 / Jul 2026) |
| **Baccarat Residences Brickell** | 444 Brickell Ave / 77 SE 5th St (`25.768950, -80.189500`) | Under construction — ~65 of 75 floors | `258.5` full / `225.0` standing | `build-partial` (225 m) | Florida YIMBY (Mar 13, 2026) |
| **888 Brickell (Dolce & Gabbana)** | 888 Brickell Ave (`25.765400, -80.190800`) | Site cleared; vertical construction not started | `0.0` (`319.7` planned) | `skip` | The Real Deal (Oct 9, 2026) |
| **St. Regis Residences Brickell** | 1809 Brickell Ave (`25.753800, -80.196600`) | Topped out 50-storey single tower | `192.0` | `build` | Florida YIMBY (Jul 10, 2025; topped out 2026) |
| **The Residences at 1428 Brickell** | 1428 Brickell Ave (`25.759200, -80.191800`) | Under construction — ~30 of 70 floors | `262.4` full / `115.0` standing | `build-partial` (115 m) | Florida YIMBY (Feb 2025 / Sept 2026) |
| **One Brickell City Centre** | 700 Brickell Ave | Canceled Feb 2025; site listed for sale | `0.0` | `skip` | Florida YIMBY (Feb 14, 2025) |
| **Mandarin Oriental Brickell Key** | 500 Brickell Key Dr (`25.764564, -80.185204`) | Closed May 31, 2025; **imploded April 12, 2026** | `0.0` | `skip` (confirmed already removed from Nov 2026 OSM) | WLRN (Apr 12, 2026) |
| **Hyatt Regency / Knight Center** | 400 SE 2nd Ave (`way:992921584`) | 1982 hotel & convention hall still open; Riverbridge not started | `81.7` | `build` existing / `skip` Riverbridge | Florida YIMBY (Jun 20, 2024) |
| **The Raleigh redevelopment** | 1775 Collins Ave (`way:263592316`) | 1940 Deco shell standing; new condo tower not started | `30.0` | `build` Deco hotel / `skip` tower | Wikipedia / Miami Beach Commission (2026) |
| **Shore Club redevelopment** | 1901 Collins Ave (`25.795000, -80.128800`) | Mid-rise concrete rising (~40 m of 61 m) + Cromwell House | `40.0` (`61.0` full) | `build-partial` | Florida YIMBY (Nov 20, 2025) |
| **I-395 Signature Bridge** | I-395 / Biscayne Blvd (`25.784500, -80.190500`) | **4 of 6 arches standing** (Arches 1, 2, 4, 5 closed; 3 & 6 in base) | `100.6` max arch | `build-partial` (4 standing arches) | Florida YIMBY (Sept 2026) |
| **SW 1st Street Bridge** | SW 1st St over Miami River (`way:993098791`) | Replacement double-leaf bascule completed & open | `7.6` clear | `build` | FDOT / Hardesty & Hanover (Jan 2022) |
| **Osvaldo N. Soto Civil Courthouse** | 20 NW 1st Ave (`way:467888610`) | Completed & opened Nov 10, 2025 beside 1928 Courthouse | `144.5` | `build` | Tutor Perini / Miami-Dade County (Nov 10, 2025) |
| **Miami Seaquarium** | 4400 Rickenbacker Cswy (`way:480675688`) | Closed Oct 12, 2025; Golden Dome & stadiums still standing | `17.0` | `build` existing structures | WLRN (Jul 2025 / Oct 2025) |
| **Coconut Grove Playhouse** | 3500 Main Hwy (`way:436105620`) | Rear auditorium razed 2025; 1926 3-storey front preserved | `13.0` | `build-partial` (front block) | WLRN (Apr 14, 2026) |
| **Miami Freedom Park (*Nu Stadium*)** | 25.7955, -80.2640 | Completed & opened April 4, 2026 (26,700 seats) | `40.0` | `build` | Wikipedia / Inter Miami CF (Apr 4, 2026) |
| **MSC Miami Cruise Terminal** | Dodge Island East (`25.773500, -80.155500`) | Completed & opened April 5, 2025 (Terminals AA/AAA) | `26.0` | `build` | Miami-Dade PortMiami (Apr 5, 2025) |
| **Aria Reserve South & North** | 700–725 NE 24th St (`way:255191962`, `way:435730634`) | Both 62-storey towers completed (2025 & mid-2026) | `197.8` each | `build` both | Florida YIMBY (2025–2026) |
| **Five Park & Canopy Bridge** | 500 Alton Rd (`way:1180320017`) | Tower (158.2 m) complete; **Canopy Bridge unbuilt** (litigation Oct 2026) | `158.2` tower | `build` tower / `skip` bridge | The Real Deal (Oct 19, 2026) |
| **Aston Martin Residences** | 300 Biscayne Blvd Way (`way:995059087`) | Completed & opened April 2024 | `249.0` | `build` | The Real Deal (Apr 30, 2024) |
| **830 Brickell** | 830 Brickell Plaza (`way:995060605`) | Completed & opened October 2024 | `220.7` | `build` | Wikipedia (Oct 2024) |
| **Deauville Beach Resort** | 6701 Collins Ave | Imploded Nov 13, 2022; vacant oceanfront lot | `0.0` | `skip` | Wikipedia (Nov 13, 2022) |

---

## 2. Tier 1 Bespoke Landmarks & Icons (Phases MI-2, MI-3B, MI-4, MI-5C, MI-6.5, MI-10)

### MI-2A & MI-2B: Downtown Bayfront & Core

| Type | Landmark | OSM Way / Rel | Centroid (`lat, lon`) | `yaw_deg` | Footprint (m) | `height_m` | Height Source & Key Envelope Notes |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `freedom_tower_miami` | Freedom Tower | `way:290629021` | `25.780265, -80.189784` | `-1.3` | `53.7 × 36.8` | `78.0` | CTBUH/NPS 255 ft (`77.7 m`, OSM cupola tip `84.5 m` ASL); 3-storey `53.7×36.8 m` base (`16 m`), square + octagonal Giralda belfry tiers, cupola; `icon: true`, `skyline_priority: 3`. |
| `kaseya_center` | Kaseya Center | `way:25312625` | `25.781381, -80.187863` | `59.2` | `136.9 × 147.7` | `48.8` | OSM LiDAR `48.8 m`; white curved concrete arena drum, sweeping east glass curtain, west Biscayne LED media mesh, stepped plaza. |
| `pamm_miami` | Pérez Art Museum Miami | `way:484587327` | `25.786002, -80.186362` | `-25.2` | `69.7 × 50.2` | `22.0` | Herzog & de Meuron (2013); raised platform (`4.5 m`), 3-level concrete/glass pavilions under `75 × 56 m` slatted timber canopy at `22 m`, hanging garden columns, bayfront steps. |
| `frost_science_miami` | Phillip and Patricia Frost Museum of Science | `way:319426548` + `way:484587349` | `25.785151, -80.187850` | `-24.1` | `140.0 × 92.0` | `32.0` | Grimshaw (2017); `26.2 m` spherical white planetarium dome (`way:484587349`), Gulf Stream conical aquarium oculus, North & West wings (`32 m`). |
| `adrienne_arsht_center` | Adrienne Arsht Center for the Performing Arts | `way:314061996` + `way:199543159` | `25.787514, -80.189653` | `-3.5` | `119.8 × 108.6` (×2) | `48.0` | César Pelli (2006); Ziff Ballet Opera House (`48.0 m`, west) + Knight Concert Hall (east) linked by Carnival Arts Bridge over Biscayne Blvd + 1929 Sears Deco tower (`30 m`). |
| `skyviews_miami_wheel` | Skyviews Miami Observation Wheel & Bayside | `way:648127409` + `rel:7417722` | `25.778315, -80.186289` | `0.0` | `60.0` wheel + pavilions | `60.0` | 60 m (196 ft) 42-gondola wheel at Bayside waterfront (`LandmarkWheel` + white pavilion wings). |
| `bacardi_building_miami` | Bacardi Building & Jewel Box | `way:454144052` | `25.797335, -80.189586` | `-0.9` | `104.2 × 54.3` | `38.0` | Enrique Gutiérrez (1963) 8-storey tower (`38 m`) with blue-and-white tile end murals + Ignacio Carrera-Justiz (1973) cantilevered stained-glass square "Jewel Box" (`16 m`). |
| `miamicentral_station` | MiamiCentral (Brightline) | `way:1105389938` | `25.778577, -80.195789` | `-2.0` | `48.1 × 165.0` | `45.0` | SOM elevated concourse & platforms (`45 m` top) carried on signature white V-truss steel columns straddling NW 5th–8th St. |
| `miami_dade_cultural_center` | Miami-Dade Cultural Center | `way:648249520` | `25.774631, -80.196478` | `-1.8` | `87.8 × 83.6` | `24.0` | Philip Johnson (1983) raised travertine/stucco plaza with HistoryMiami, Main Library & Art Museum under clay barrel-tile hipped roofs and arcades. |

### MI-2C: PortMiami

| Type | Landmark | OSM Way / Rel | Centroid (`lat, lon`) | `yaw_deg` | Footprint (m) | `height_m` | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `portmiami_terminal_a` | Royal Caribbean Terminal A ("Crown of Miami") | `25.778600, -80.162800` | `25.778600, -80.162800` | `-64.0` | `165.0 × 62.0` | `36.0` | Broadway Malyan faceted angular glass "M" prow (`36 m`). |
| `portmiami_terminal_b` | Norwegian Cruise Line Terminal B ("Pearl of Miami") | `25.777700, -80.165600` | `25.777700, -80.165600` | `-64.0` | `158.0 × 58.0` | `30.0` | Bermello Ajamil pearl-white spiralling nautilus shell curves (`30 m`). |
| `portmiami_terminal_v` | Virgin Voyages Terminal V | `way:123899159` | `25.780120, -80.180182` | `21.0` | `80.8 × 175.4` | `22.0` | Arquitectonica faceted palm-grove canopy on Y-columns (`22 m`). |
| `portmiami_carnival_msc` | MSC Cruise Terminal AA & Carnival Terminal F | `25.773500, -80.155500` | `25.773500, -80.155500` | `-64.0` | `240.0 × 72.0` | `26.0` | Arquitectonica 4-level glazed MSC megaterminal (opened Apr 2025, `26 m`) + adjacent garage wing. |

### MI-3B & MI-6.5: Brickell, Wynwood, Little Havana & Design District Bespoke

| Type | Landmark | OSM Way / Rel | Centroid (`lat, lon`) | `yaw_deg` | Footprint (m) | `height_m` | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `brickell_city_centre_ribbon` | Brickell City Centre & Climate Ribbon | `way:813418718` | `25.767126, -80.193272` | `88.1` | `187.3 × 220.0` | `32.0` | Arquitectonica / Hugh Dutton undulating steel-and-glass Climate Ribbon canopy spanning three open retail blocks (`32 m` ribbon crest; towers Reach/Rise/EAST in `MiamiTowerSpecsBrickell`). |
| `atlantis_condominium` | The Atlantis on Brickell | `way:480909198` | `25.752831, -80.198498` | `52.2` | `92.6 × 13.9` | `64.0` | Arquitectonica (1982, 20 fl, `64 m`); blue glass grid, 5-storey skycourt cutout with red spiral stair, palm & whirlpool, yellow triangular balcony, red roof vault. |
| `loandepot_park` | loanDepot park | `relation:8736190` | `25.778141, -80.219881` | `0.2` | `248.0 × 210.0` | `68.0` | Populous (2012, OSM top `78.9 m` ASL / `~68 m` local arch); white retractable roof panels on long-span tracks, left-field sliding glass wall, corner cylindrical ramps; `skyline_priority: 2`. |
| `wynwood_walls` | Wynwood Walls | `way:435845377` | `25.801132, -80.195325` | `88.0` | `53.5 × 35.6` | `11.0` | Low warehouse pavilions with bold procedural geometric mural panels, courtyard palms & concrete portals. |
| `tower_theater_miami` | Tower Theater & Domino Park | `way:318008207` | `25.765480, -80.219667` | `88.8` | `41.4 × 17.6` | `18.0` | 1926 Art Deco cinema on Calle Ocho with stepped marquee, chrome/neon vertical fin (`18 m`) + Domino Park pavilion next door. |
| `museum_garage_miami` | Museum Garage & Fly's Eye Dome | `way:700376947` | `25.813977, -80.194012` | `-2.8` | `124.2 × 36.0` | `26.0` | Five-architect collage garage facade (WORKac pink ant-farm, J. Mayer H. puzzle, Clavel gold/red cars) + Fuller geodesic Fly's Eye Dome (`way:866731275`). |

### MI-4A..MI-4D: Miami Beach Bespoke

| Type | Landmark | OSM Way / Rel | Centroid (`lat, lon`) | `yaw_deg` | Footprint (m) | `height_m` | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `ocean_drive_colony_starlite` | Colony, Starlite & Pelican Block | `way:435587753` + `way:380861941` | `25.777602, -80.131563` | `11.4` | `38.5 × 42.0` | `16.5` | Grouped Ocean Drive 7th–8th St hero row (`model_rects_m`): Colony (`736`, white stucco, blue neon central fin & eyebrows) + Starlite (`750`, stepped spire). |
| `ocean_drive_breakwater_edison` | Hotel Breakwater & Edison Hotel | `way:380875541` + `way:380875540` | `25.780103, -80.131007` | `11.7` | `38.0 × 46.0` | `24.0` | Grouped Ocean Drive 9th–10th St primary (`icon: true`): Breakwater (`940`, tall blue/white central vertical sign pylon `24 m`, portholes, terrace umbrellas) + Edison (`960`, pastel mint/yellow ziggurat). |
| `art_deco_welcome_center` | Art Deco Welcome Center & Ocean Rescue HQ | `way:380875536` | `25.780279, -80.130344` | `11.7` | `35.8 × 30.0` | `11.5` | Robert Taylor (1934) Streamline Moderne nautical station on Lummus Park side (`1001 Ocean Dr`): ship-bridge rounded deck, portholes, mast. |
| `casa_casuarina_versace` | Villa Casa Casuarina (Versace Mansion) | `way:380875533` | `25.781988, -80.130662` | `11.7` | `32.8 × 23.6` | `16.5` | Alden Freeman (1930) Mediterranean Revival mansion (`1116 Ocean Dr`): coral-stucco courtyard, barrel-tile roofs, domed observatory tower (`16.5 m`), mosaic pool. |
| `ocean_drive_carlyle_cardozo` | The Carlyle, Leslie & Cardozo Block | `way:380861944` + `way:380861927` + `way:380861903` | `25.783722, -80.130245` | `8.2` | `40.4 × 88.0` | `15.5` | Grouped Ocean Drive 12th–13th St primary (`icon: true`, `model_rects_m`): Leslie (`1244`, bright yellow ziggurat), The Carlyle (`1250`, 3-bay curved white & seafoam Streamline Moderne), Cardozo (`1300`, rounded Streamline eyebrows). |
| `lincoln_road_1111` | 1111 Lincoln Road | `relation:12268481` | `25.790897, -80.140767` | `-1.3` | `51.6 × 45.5` | `34.0` | Herzog & de Meuron (2010): open-air raw concrete slab-and-wedge-column "card house" parking sculpture (`34 m`, 7 uneven floor heights, zero exterior walls). |
| `new_world_center_miami` | New World Center | `way:277037894` | `25.791678, -80.133445` | `88.5` | `90.8 × 43.6` | `31.0` | Frank Gehry (2011): white stucco box with `30 m` SoundScape outdoor projection wall, east glass atrium revealing curved titanium/white acoustic sails. |
| `miami_beach_convention_center` | Miami Beach Convention Center | `way:76689875` | `25.795391, -80.133136` | `88.3` | `360.0 × 210.0` | `26.0` | Fentress (2018 renovation): long undulating silver aluminium-fin wave facade, cantilevered glass entry canopies. |
| `holocaust_memorial_miami_beach` | Holocaust Memorial Miami Beach | `way:588999178` | `25.795187, -80.136413` | `89.6` | `46.0 × 46.0` | `14.0` | Kenneth Treister (1990): `13 m` patinated bronze reaching arm with sculpted figures rising from a circular black-granite reflection lily pond framed by a keystone colonnade. |
| `old_city_hall_miami_beach` | Miami Beach Old City Hall | `way:436108380` | `25.782624, -80.132643` | `-78.9` | `51.6 × 15.8` | `42.9` | Martin L. Hampton (1927, `1130 Washington Ave`): 9-storey Mediterranean Revival tower (`42.9 m`), barrel-tile cupola and arched loggia. |
| `south_pointe_pier_park` | South Pointe Pier & Park | `way:117915799` | `25.763836, -80.130242` | `32.9` | `147.1 × 17.7` | `12.0` | Hargreaves / William Lane (2014): 137 m concrete ocean pier over Government Cut jetty, angled turtle-safe light masts, shade canopy & viewing mound. |
| `fontainebleau_miami_beach` | Fontainebleau Miami Beach | `way:447042031` | `25.817904, -80.122330` | `7.6` | `160.6 × 217.9` | `110.0` | Morris Lapidus (1954) iconic sweeping white curved Chateau slab (`52 m`) + Trésor (`110 m`, 37 fl) and Sorrento (`65 m`, 18 fl) wing towers + bow-tie lagoon pool (`icon: true`). |
| `faena_forum_miami_beach` | Faena Forum & Faena Hotel | `way:639617563` + `way:436123285` | `25.808134, -80.124057` | `8.8` | `49.2 × 28.1` | `22.0` | OMA / Rem Koolhaas (2016): white cylindrical drum + cube (`22 m`) with arched geometric cutouts across from the 1948 Saxony/Faena Hotel (`56.3 m` spec row). |
| `flagler_memorial_monument` | Flagler Memorial Island Obelisk | `25.783600, -80.153600` | `25.783600, -80.153600` | `0.0` | `18.0 × 18.0` | `33.5` | Carl Fisher / Harryiller (1920): 110 ft (`33.5 m`) white limestone obelisk with four allegorical base sculptures on circular bay island. |

### MI-5A & MI-5C: Bespoke Bridges

| Type | Landmark | OSM Way / Rel | Centroid (`lat, lon`) | `yaw_deg` | Footprint (m) | `height_m` | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `brickell_avenue_bridge` | Brickell Avenue Bridge (Bespoke) | `way:992945519` | `25.770020, -80.190047` | `88.6` | `140.1 × 36.0` | `24.0` | 1995 twin-leaf bascule over Miami River (`clear: 7.6 m`) + Manuel Carbonell's 16 m bronze *Pillar of History / Tequesta Family* column at SE corner (`24 m` top), tender houses & pier reliefs. |
| `i395_signature_bridge` | I-395 Signature Bridge (Late-2026 State) | `25.784500, -80.190500` | `25.784500, -80.190500` | `-3.0` | `320.0 × 120.0` | `100.6` | HDR / Donald MacDonald "Fountain": **4 standing precast concrete arches** (Arches 1, 2, 4, 5 up to `100.6 m` / 330 ft) with cable stay fans over Biscayne Blvd / NE 2nd Ave (`skyline_priority: 2`). |

### MI-10: Outer Centres (Vizcaya, Coconut Grove, Coral Gables, Key Biscayne, Far)

| Type | Landmark | OSM Way / Rel | Centroid (`lat, lon`) | `yaw_deg` | Footprint (m) | `height_m` | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `vizcaya_museum_gardens` | Vizcaya Museum, Gardens & Stone Barge | `way:301895039` + `way:617992333` | `25.744391, -80.210480` | `52.3` | `140.0 × 120.0` | `21.5` | F. Burrall Hoffman / Paul Chalfin (1916): coral-stone Italian Renaissance villa (`21.5 m`, 4 corner belvedere towers, clay barrel tile), formal parterres (`tree_rect`), and sculpted stone Barge breakwater in Biscayne Bay (`icon: true`). |
| `miami_city_hall_dinner_key` | Miami City Hall (Pan Am Seaplane Terminal) | `25.728200, -80.233800` | `25.728200, -80.233800` | `42.5` | `46.0 × 32.0` | `14.5` | Delano & Aldrich (1934): Streamline Moderne white/blue Pan American Airways terminal with globe relief entrance & stepped parapet. |
| `ermita_de_la_caridad` | Ermita de la Caridad | `way:453575835` | `25.740879, -80.211352` | `-48.2` | `42.8 × 38.9` | `29.5` | Bernardo Fort-Brescia / Telesforo Cristobal (1973): 90 ft (`29.5 m`) white truncated conical concrete shrine on Biscayne Bay seawall. |
| `biltmore_hotel_coral_gables` | Biltmore Hotel Coral Gables | `relation:9351650` | `25.740792, -80.278457` | `-30.7` | `152.0 × 106.7` | `96.0` | Schultze & Weaver (1926): Mediterranean Revival resort wings with clay tile roofs, huge lagoon pool, and 315 ft (`96.0 m`) Giralda bell tower (`LandmarkMiKit.giralda_tier`, `icon: true`, `skyline_priority: 2`). |
| `venetian_pool_coral_gables` | Venetian Pool | `way:297000205` | `25.745779, -80.273177` | `67.1` | `51.7 × 58.0` | `11.0` | Phineas Paist / Denman Fink (1924): coral-rock quarry spring lagoon (`pool_water`), Venetian stone arch bridge, loggias & Spanish lookout towers. |
| `coral_gables_city_hall` | Coral Gables City Hall | `way:416557593` | `25.749252, -80.263457` | `41.0` | `34.1 × 46.7` | `22.0` | Phineas Paist (1928): semicircular oolitic-limestone Corinthian colonnade and 3-stage Spanish Baroque clock tower (`22 m`). |
| `alhambra_water_tower` | Alhambra Water Tower | `way:637373560` | `25.750237, -80.281568` | `87.9` | `14.0 × 14.0` | `40.0` | Denman Fink (1924): 131 ft (`40.0 m`) octagonal Moorish lighthouse-disguised water tower with frescoed stucco and copper dome. |
| `douglas_entrance_coral_gables` | Douglas Entrance (*La Puerta del Sol*) | `way:435375023` | `25.764887, -80.255528` | `-2.6` | `73.5 × 28.2` | `24.0` | Paist & Fink (1927): stone gateway arch straddling Tamiami Trail/8th St with Spanish bell tower (`24 m`) and tiled galleries. |
| `cape_florida_lighthouse` | Cape Florida Light | `way:305533830` | `25.666591, -80.155966` | `33.8` | `7.4 × 7.4` | `29.0` | 1825/1846 white conical brick lighthouse (`29.0 m` / 95 ft) with black iron lantern & keeper's cottage at Bill Baggs State Park. |
| `miami_marine_stadium` | Miami Marine Stadium | `way:477122363` | `25.742885, -80.169891` | `44.5` | `98.8 × 31.3` | `21.0` | Hilario Candela (1963): iconic 99 m folded-plate raw concrete hyperbolic-paraboloid cantilever roof facing Virginia Key rowing basin. |
| `stiltsville_biscayne_bay` | Stiltsville | `25.650500, -80.181500` | `25.650500, -80.181500` | `0.0` | `160.0 × 140.0` | `9.5` | Seven historic wood-and-concrete stilt houses standing over Biscayne Bay flats (`base: "sea"`, pilings to seabed). |
| `seaquarium_golden_dome` | Miami Seaquarium Golden Dome | `way:480675688` | `25.733273, -80.165292` | `1.9` | `42.0 × 42.0` | `17.0` | Buckminster Fuller (1960) gold-anodized aluminium geodesic dome on Virginia Key (standing shuttered in late 2026). |
| `hard_rock_stadium` | Hard Rock Stadium | `25.957960, -80.238860` | `25.957960, -80.238860` | `0.0` | `275.0 × 235.0` | `109.0` | HOK open-air canopy stadium with four corner white steel cable-stay spires (`109 m` / 357 ft, `skyline_priority: 1`). |
| `nu_stadium_freedom_park` | Nu Stadium (Miami Freedom Park) | `25.795500, -80.264000` | `25.795500, -80.264000` | `1.9` | `215.0 × 175.0` | `40.0` | MANICA / Arquitectonica (opened Apr 4, 2026): 26,700-seat soccer-specific stadium with sweeping white/pink-lit wraparound canopy. |
| `ancient_spanish_monastery` | Ancient Spanish Monastery | `25.929600, -80.154500` | `25.929600, -80.154500` | `0.0` | `58.0 × 44.0` | `16.0` | 12th-century Cistercian stone cloister from Sacramenia, Spain, reassembled in North Miami Beach (1953). |
| `opa_locka_city_hall` | Opa-locka Company Administration Building | `25.901600, -80.250800` | `25.901600, -80.250800` | `0.0` | `48.0 × 34.0` | `22.0` | Bernhardt Muller (1926): Moorish Revival fantasy palace with striped onion domes, minarets & keyhole arches. |

---

## 3. Tier 1S Skyline Spec Towers (`MiamiTowerSpecs*`, ~85 Rows)

All skyline rows use `skyline: true` (separate 110-slot Ultra channel in `LandmarkSites.select`) so they never consume Tier 1 icon slots.

### Downtown, Park West, Worldcenter & Edgewater (`MiamiTowerSpecsDowntown`, `MiamiTowerSpecsEdgewater`)

| Type | Name | OSM ID | Centroid (`lat, lon`) | `yaw_deg` | `height_m` | Pri | Source / Notes |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `waldorf_astoria_miami` | Waldorf Astoria Residences Miami | `way:1459955388` | `25.777466, -80.188944` | `-1.6` | `285.0` | `3` | Late-2026 standing height (89/100 fl, 9 offset glass cubes). |
| `okan_tower` | Okan Tower | `25.779700, -80.193200` | `25.779700, -80.193200` | `-1.7` | `262.0` | `2` | Late-2026 standing height (~66/72 fl tulip curve). |
| `aston_martin_residences` | Aston Martin Residences | `way:995059087` | `25.770752, -80.187954` | `-20.7` | `249.0` | `3` | OSM `249.0 m`, CTBUH 817 ft; curved glass sail at river mouth. |
| `southeast_financial_center` | Southeast Financial Center | `way:398246359` | `25.772260, -80.187644` | `88.4` | `233.0` | `3` | SOM (1984), OSM `233.0 m` (55 fl), sawtooth SE top setbacks + banking hall. |
| `one_thousand_museum` | One Thousand Museum | `relation:9396621` | `25.784212, -80.190210` | `-2.2` | `216.0` | `3` | Zaha Hadid (2019), OSM `216.0 m` (62 fl), white exoskeleton ribs & helipad. |
| `paramount_miami_worldcenter` | Paramount Miami Worldcenter | `way:992535952` | `25.782419, -80.191880` | `-0.8` | `213.4` | `2` | CTBUH 700 ft (`213.4 m`, OSM `210 m`), lit crown & rooftop deck. |
| `marquis_miami` | Marquis Miami | `way:483326775` | `25.785186, -80.190256` | `-80.6` | `207.0` | `2` | CTBUH 679 ft (`207.0 m`, 67 fl). |
| `900_biscayne_bay` | 900 Biscayne Bay | `way:319427738` | `25.783605, -80.190039` | `87.6` | `198.0` | `2` | CTBUH 650 ft (`198.0 m`, OSM `200.0 m`, 63 fl). |
| `aria_reserve_south` | Aria Reserve South | `way:255191962` | `25.799670, -80.185749` | `-89.7` | `197.8` | `2` | Completed 2025, 649 ft (`197.8 m`, 62 fl). |
| `aria_reserve_north` | Aria Reserve North | `way:435730634` | `25.800271, -80.185744` | `89.5` | `197.8` | `2` | Completed mid-2026, 649 ft (`197.8 m`, 62 fl). |
| `wells_fargo_center_miami` | Wells Fargo Center | `way:919062007` | `25.771264, -80.189572` | `86.8` | `197.0` | `2` | OSM `197.0 m` (47 fl), Met 2 glass tower. |
| `missoni_baia` | Missoni Baia | `way:954741754` | `25.799019, -80.185931` | `-1.8` | `197.8` | `1` | Asymptote (2023), 649 ft (`197.8 m`, 57 fl). |
| `elysee_miami` | Elysee Miami | `way:468023516` | `25.798523, -80.185638` | `89.3` | `197.8` | `1` | Arquitectonica (2021), 649 ft (`197.8 m`, 57 fl) telescoping 3-tier tower. |
| `casa_bella_miami` | Casa Bella by B&B Italia | `way:444351430` | `25.788613, -80.189549` | `-1.5` | `196.0` | `1` | OSM `196.0 m` (56 fl). |
| `miami_tower` | Miami Tower | `way:300232867` | `25.772259, -80.191520` | `-46.1` | `191.0` | `3` | I.M. Pei (1987), OSM `191.0 m` (47 fl), 3 stepped semicircular tiers, colour-washed at night (`icon: true`). |
| `marinablue` | MarinaBlue | `way:319427739` | `25.782465, -80.190061` | `87.3` | `187.0` | `2` | Arquitectonica (2008), OSM `187.0 m` (57 fl), curved wave-cut slab. |
| `gran_paraiso` | Gran Paraiso | `way:643553505` | `25.806176, -80.186709` | `88.2` | `185.0` | `1` | Edgewater Paraiso bayfront tower (55 fl). |
| `paraiso_bay` | Paraiso Bay | `way:643553506` | `25.806892, -80.186448` | `-34.9` | `183.0` | `1` | Edgewater (54 fl), circular facade motif. |
| `one_paraiso` | One Paraiso | `way:643553511` | `25.807187, -80.185632` | `88.6` | `183.0` | `1` | Edgewater (53 fl). |
| `epic_residences_miami` | Epic Residences & Hotel | `way:995059089` | `25.770489, -80.189494` | `88.7` | `183.0` | `2` | OSM `183.0 m` (54 fl) at Miami River mouth. |
| `ten_museum_park` | Ten Museum Park | `way:237435619` | `25.784660, -80.190150` | `-2.2` | `178.3` | `2` | Oppenheim (2007), OSM `178.3 m` (50 fl), interlocking spine & sky pools. |
| `aria_on_the_bay` | Aria on the Bay | `way:927927331` | `25.793403, -80.187012` | `12.0` | `177.0` | `1` | Arquitectonica (2018, 53 fl) curved balcony waves. |
| `natiivo_miami` | Natiivo Miami (Gale) | `way:463472271` | `25.780259, -80.191324` | `-1.6` | `179.0` | `1` | Arquitectonica (2024, 51 fl, 588 ft). |
| `miami_world_tower` | Miami World Tower | `way:1198194479` | `25.781524, -80.192501` | `88.7` | `176.5` | `1` | Completed 2024 (53 fl, 579 ft). |
| `50_biscayne` | 50 Biscayne | `way:587693106` | `25.774813, -80.188219` | `88.3` | `169.0` | `2` | OSM `168.9 m` (55 fl) facing Bayfront Park. |
| `paramount_bay` | Paramount Bay | `way:468023495` | `25.796792, -80.187679` | `0.2` | `168.5` | `1` | OSM `168.5 m` (47 fl). |
| `biscayne_beach` | Biscayne Beach | `way:1360151970` | `25.805033, -80.185847` | `-3.0` | `167.6` | `1` | OSM `167.6 m` (52 fl). |
| `vizcayne_north` | Vizcayne North Tower | `way:1105389913` | `25.776850, -80.188750` | `71.5` | `164.0` | `2` | Twin 49-storey bayfront towers (538 ft). |
| `vizcayne_south` | Vizcayne South Tower | `25.776350, -80.188800` | `25.776350, -80.188800` | `71.5` | `164.0` | `2` | Twin 49-storey bayfront towers (538 ft). |
| `quantum_on_the_bay` | Quantum on the Bay | `way:468023505` | `25.794387, -80.186919` | `-42.2` | `165.9` | `1` | OSM `165.9 m` (51/44 fl pair). |
| `muze_at_met` | Muze at Met Square | `way:952486635` | `25.771452, -80.188396` | `-1.0` | `166.0` | `1` | OSM `166.0 m` (42 fl). |
| `the_elser_miami` | The Elser Hotel & Residences | `way:952486637` | `25.778761, -80.189160` | `-1.4` | `165.0` | `1` | Sieger Suarez (49 fl) opposite Bayside. |
| `icon_bay_edgewater` | Icon Bay | `way:628377019` | `25.803591, -80.187266` | `88.9` | `161.0` | `1` | Arquitectonica (48 fl). |
| `opera_tower_miami` | Opera Tower | `way:468023506` | `25.792422, -80.187119` | `29.0` | `165.5` | `1` | Elliptical curved tower (56 fl, 543 ft). |
| `met_1_miami` | Met 1 | `way:436126818` | `25.771401, -80.187695` | `-2.0` | `160.0` | `1` | OSM `160.0 m` (40 fl). |
| `stephen_clark_center` | Stephen P. Clark Government Center | `relation:21170654` | `25.775611, -80.196669` | `88.0` | `155.0` | `1` | Hugh Stubbins (1985), 510 ft (`155.4 m`, OSM `160.0 m` ASL). |
| `one_biscayne_tower` | One Biscayne Tower | `way:375937493` | `25.774005, -80.188064` | `77.9` | `150.0` | `2` | 1972 white vertical-pier bayfront office tower, OSM `150.0 m` (39 fl). |
| `miami_center_citigroup` | Miami Center (Citigroup Center) | `way:300267002` | `25.772237, -80.186742` | `88.6` | `148.0` | `1` | Pietro Belluschi (1983), OSM `148.0 m` (34 fl). |
| `osvaldo_soto_courthouse` | Osvaldo N. Soto Miami-Dade Justice Center | `way:467888610` | `25.775735, -80.194563` | `-1.7` | `144.5` | `2` | HOK (opened Nov 2025), 474 ft (`144.5 m`, 25 fl). |
| `one_miami_east` | One Miami East Tower | `way:992801054` | `25.771577, -80.185873` | `-2.4` | `140.0` | `2` | Arquitectonica twin towers at river mouth (`140.0 m`, 44/45 fl). |
| `bezel_miami` | Bezel at Miami Worldcenter | `way:376446921` | `25.780761, -80.190904` | `-1.7` | `145.0` | `1` | 43 fl Worldcenter residential tower. |
| `flow_miami_caoba` | Caoba / Flow Miami | `way:741593664` | `25.780835, -80.192545` | `88.7` | `135.0` | `1` | OSM `135.0 m` (43 fl). |
| `intercontinental_miami` | InterContinental Miami | `way:300267003` | `25.772422, -80.185470` | `-3.0` | `122.0` | `2` | Pietro Belluschi (1982), travertine V-slab on triangular podium (`122.0 m`, 35 fl) + night LED dancer panel. |
| `miami_dade_courthouse` | Miami-Dade County Courthouse | `way:294683600` | `25.774587, -80.195136` | `89.0` | `110.0` | `2` | A. Ten Eyck Brown (1928), terracotta stepped ziggurat pyramid (`110.0 m`, 28 fl). |
| `ferguson_us_courthouse` | Wilkie D. Ferguson Jr. U.S. Courthouse | `way:373870718` | `25.777986, -80.194699` | `-2.2` | `77.7` | `1` | Arquitectonica (2007), twin curved glass hulls + central atrium (`77.7 m`, 14 fl). |
| `hyatt_regency_miami` | Hyatt Regency Miami & Knight Center | `way:992921584` | `25.770478, -80.190573` | `-47.6` | `81.7` | `1` | 1982 white stepped riverfront hotel (`81.7 m`, 24 fl) + Knight Center drum. |

### Brickell, Brickell Key & South Brickell (`MiamiTowerSpecsBrickell`)

| Type | Name | OSM ID | Centroid (`lat, lon`) | `yaw_deg` | `height_m` | Pri | Source / Notes |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `cipriani_residences_miami` | Cipriani Residences Miami | `way:301823928` | `25.759410, -80.193257` | `-76.8` | `289.6` | `3` | Topped out Jul 2026, 950 ft (`289.6 m`, 80 fl). |
| `panorama_tower` | Panorama Tower | `way:676817045` | `25.763170, -80.190280` | `14.1` | `264.6` | `3` | Moshe Cosicher (2017), CTBUH 868 ft (`264.6 m`, OSM `265.0 m`, 85 fl). |
| `four_seasons_miami` | Four Seasons Hotel & Tower Miami | `way:933174532` | `25.758713, -80.191435` | `12.4` | `240.0` | `3` | Gary Edward Handel (2003), OSM `240.0 m` (70 fl). |
| `baccarat_residences_brickell` | Baccarat Residences Brickell | `25.768950, -80.189500` | `25.768950, -80.189500` | `88.0` | `225.0` | `2` | Late-2026 standing height (~65/75 fl at river mouth). |
| `brickell_flatiron` | Brickell Flatiron | `way:954745204` | `25.764104, -80.192935` | `88.3` | `224.0` | `3` | Luis Revuelta (2019), 736 ft (`224.3 m`, 64 fl) curved glass flatiron wedge. |
| `830_brickell` | 830 Brickell | `way:995060605` | `25.766060, -80.192485` | `-79.0` | `220.7` | `3` | AS+GG (Oct 2024), OSM `220.0 m`, CTBUH 724 ft (`220.7 m`, 55 fl). |
| `echo_brickell` | Echo Brickell | `way:1071017393` | `25.758041, -80.192418` | `-76.9` | `194.0` | `2` | Carlos Ott (2017), OSM `194.0 m` (57 fl). |
| `st_regis_brickell` | St. Regis Residences Brickell | `way:480909183` | `25.753697, -80.196711` | `-37.1` | `192.0` | `2` | RAMSA (topped out 2026, 630 ft, 50 fl). |
| `mint_at_riverfront` | Mint at Riverfront | `way:465518927` | `25.769499, -80.195162` | `-1.2` | `192.3` | `1` | Revuelta (2009), OSM `192.3 m` (55 fl). |
| `plaza_on_brickell_i` | Plaza on Brickell Tower I | `way:300211766` | `25.765030, -80.190191` | `13.1` | `186.0` | `1` | Arquitectonica (2007, 56 fl, 610 ft). |
| `infinity_at_brickell` | Infinity at Brickell | `way:435234024` | `25.761122, -80.194284` | `87.1` | `186.4` | `2` | Borges (2008), OSM `186.4 m` (52 fl), dramatic top arch fin. |
| `citadel_1201_brickell` | 1201 Brickell Bay Drive | `way:1552890381` | `25.761194, -80.189291` | `12.2` | `188.0` | `1` | OSM `188.0 m` (47 fl). |
| `icon_brickell_north` | Icon Brickell North Tower | `way:296968438` | `25.769055, -80.188626` | `0.0` | `178.6` | `2` | Arquitectonica (2008), OSM `179.0 m` (58 fl). |
| `icon_brickell_south` | Icon Brickell South Tower | `way:296968436` | `25.768306, -80.188648` | `13.9` | `178.6` | `2` | Arquitectonica (2008), OSM `179.0 m` (58 fl). |
| `sls_lux_brickell` | SLS Lux Brickell | `way:954745216` | `25.765908, -80.192883` | `89.1` | `181.4` | `2` | Arquitectonica (2018, 57 fl, 595 ft). |
| `brickell_heights_east` | Brickell Heights | `way:954745215` | `25.765721, -80.193895` | `-2.4` | `169.0` | `1` | Arquitectonica, OSM `169.0 m` (49/46 fl pair). |
| `solitair_brickell` | Solitair Brickell | `way:954745212` | `25.766121, -80.194495` | `-1.4` | `169.0` | `2` | Add Inc (2018), OSM `169.0 m` (50 fl), palm-trunk diagrid balcony texture. |
| `jade_at_brickell_bay` | Jade Residences at Brickell Bay | `way:300492232` | `25.760319, -80.189586` | `-77.8` | `163.1` | `1` | Revuelta (2004), OSM `163.1 m` (48 fl), curved turquoise sail crown. |
| `santa_maria_brickell` | Santa Maria | `way:301776791` | `25.755446, -80.194962` | `-42.3` | `159.7` | `1` | Revuelta (1997), OSM `159.7 m` (51 fl), open sky-frame top. |
| `brickell_house` | Brickell House | `way:400594464` | `25.760320, -80.190344` | `-31.5` | `161.3` | `1` | Sieger Suarez (2014), OSM `161.3 m` (46 fl). |
| `1060_brickell` | 1060 Brickell Avenue | `way:283161497` | `25.763151, -80.191912` | `-78.2` | `160.7` | `1` | OSM `160.7 m` (45 fl). |
| `600_brickell_world_plaza` | 600 Brickell World Plaza | `way:300486578` | `25.767502, -80.191012` | `12.9` | `160.0` | `1` | RTKL (2011), OSM `160.0 m` (40 fl), notched glass portal top. |
| `1450_brickell` | 1450 Brickell | `way:301823926` | `25.758576, -80.193119` | `-76.4` | `154.6` | `1` | Nichols Brosch (2010), OSM `154.6 m` (40 fl), folded gold/blue curtain wall. |
| `espirito_santo_brickell_arch` | Brickell Arch (1395 Brickell) | `way:300510112` | `25.760677, -80.191714` | `-78.4` | `154.0` | `2` | Kohn Pedersen Fox (2004), OSM `154.0 m` (36 fl), giant concave glass arch facade. |
| `701_brickell` | 701 Brickell Avenue | `way:300193839` | `25.767088, -80.189719` | `12.7` | `150.0` | `1` | Arquitectonica (1986), OSM `150.0 m` (33 fl), octagonal stepped glass top. |
| `asia_brickell_key` | Asia on Brickell Key | `way:117631366` | `25.769191, -80.185772` | `88.1` | `147.0` | `2` | J. Scott Architecture (2008), OSM `147.0 m` (36 fl). |
| `three_tequesta_point` | Three Tequesta Point | `way:117635432` | `25.769383, -80.183711` | `24.8` | `146.0` | `2` | J. Scott (2001), OSM `146.0 m` (46 fl) at Brickell Key tip. |
| `brickell_on_the_river_north` | Brickell on the River North | `way:231873520` | `25.769600, -80.191948` | `88.2` | `147.0` | `1` | Cohen Freedman (2006), OSM `147.0 m` (42 fl). |
| `ivy_at_riverfront` | Ivy at Riverfront | `way:429421646` | `25.770414, -80.195204` | `-1.2` | `144.0` | `1` | Revuelta (2008), OSM `144.0 m` (45 fl). |
| `w_miami_icon` | W Miami (Icon Tower 3) | `way:296968437` | `25.768692, -80.189593` | `88.2` | `142.0` | `1` | Arquitectonica (2009), OSM `142.0 m` (50 fl). |
| `plaza_on_brickell_ii` | Plaza on Brickell Tower II | `way:300211767` | `25.764633, -80.190724` | `-76.2` | `143.0` | `1` | Arquitectonica (2007), OSM `143.0 m` (48 fl). |
| `bcc_reach_rise` | Brickell City Centre Reach & Rise | `25.767600, -80.193100` | `25.767600, -80.193100` | `88.1` | `152.0` | `2` | Arquitectonica (2016, 43 fl residential towers above Climate Ribbon). |
| `una_residences_brickell` | Una Residences | `way:474905113` | `25.749315, -80.201236` | `53.8` | `176.5` | `1` | AS+GG (2025), 579 ft (`176.5 m`, 47 fl) Riva-yacht curved glass tower. |
| `500_brickell_towers` | 500 Brickell East & West | `way:300221113` | `25.768386, -80.191028` | `13.5` | `130.0` | `2` | Arquitectonica (2008), twin 42-fl towers (`130.0 m`) linked by circular white roof roof-deck portal. |
| `two_tequesta_point` | Two Tequesta Point | `way:117631372` | `25.768685, -80.183174` | `-46.2` | `128.3` | `1` | OSM `128.3 m` (40 fl) on Brickell Key. |
| `axis_brickell` | Axis at Brickell Village | `way:300753073` | `25.763230, -80.194434` | `-1.2` | `127.0` | `1` | Arquitectonica (2008), OSM `127.0 m` (40 fl). |
| `wind_by_neo` | Wind | `way:995059976` | `25.770612, -80.194344` | `88.2` | `125.7` | `1` | Revuelta (2008), OSM `125.7 m` (41 fl). |
| `bristol_tower_brickell` | Bristol Tower | `way:301821630` | `25.752098, -80.199373` | `-85.4` | `124.3` | `1` | Revuelta (1993), OSM `124.3 m` (40 fl) circular balcony tower. |
| `carbonell_brickell_key` | Carbonell Condominium | `way:117631352` | `25.769250, -80.186947` | `-17.6` | `124.0` | `1` | J. Scott (2005), OSM `124.0 m` (40 fl) curved green-glass crown. |
| `the_palace_brickell` | The Palace | `way:301775188` | `25.756551, -80.192333` | `-25.0` | `121.6` | `2` | Arquitectonica (1981), OSM `121.6 m` (42 fl), stepped red masonry frame piercing white glass slab. |
| `1428_brickell_partial` | The Residences at 1428 Brickell | `25.759200, -80.191800` | `25.759200, -80.191800` | `-76.6` | `115.0` | `1` | Late-2026 standing height (~30/70 fl). |
| `villa_regina_brickell` | Villa Regina | `way:301776326` | `25.756212, -80.193510` | `-80.3` | `98.7` | `2` | Nicholas & Associates (1982), OSM `98.7 m` (30 fl), Yaacov Agam kinetic polychrome rainbow facade. |
| `the_imperial_brickell` | The Imperial at Brickell | `way:255188209` | `25.755944, -80.194186` | `51.4` | `96.0` | `1` | Arquitectonica (1983, 31 fl) red slab floating through blue glass prism. |

### Miami Beach & Far Skyline (`MiamiTowerSpecsBeach`, `MiamiTowerSpecsFar`)

| Type | Name | OSM ID | Centroid (`lat, lon`) | `yaw_deg` | `height_m` | Pri | Source / Notes |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `five_park_miami_beach` | Five Park Miami Beach | `way:1180320017` | `25.775273, -80.141172` | `50.6` | `158.2` | `3` | Arquitectonica (2024), 519 ft (`158.2 m`, 48 fl), tallest in Miami Beach. |
| `akoya_miami_beach` | Akoya | `way:303614090` | `25.845865, -80.119651` | `-0.2` | `150.0` | `1` | North Beach 47-fl oceanfront condo (492 ft). |
| `portofino_tower` | Portofino Tower | `way:117915459` | `25.767719, -80.134952` | `-2.1` | `151.2` | `3` | Sieger Architectural (1997), OSM `151.2 m` (44 fl), stepped Deco-postmodern crown. |
| `continuum_south_tower` | Continuum on South Beach South | `way:301906634` | `25.766812, -80.132863` | `-26.0` | `149.1` | `2` | Sieger Suarez (2002), OSM `149.1 m` (40 fl). |
| `blue_diamond_miami_beach` | Blue Diamond | `way:1436966471` | `25.823281, -80.121407` | `7.4` | `148.0` | `2` | Sieger Suarez (2000), OSM `148.0 m` (44 fl), illuminated diamond-octagon crown. |
| `green_diamond_miami_beach` | Green Diamond | `way:134913101` | `25.822463, -80.121563` | `7.4` | `148.0` | `2` | Sieger Suarez (2000), OSM `148.0 m` (44 fl), twin to Blue Diamond. |
| `continuum_north_tower` | Continuum on South Beach North | `way:301920897` | `25.767875, -80.132824` | `-73.9` | `130.0` | `2` | Sieger Suarez (2008), OSM `130.0 m` (37 fl). |
| `icon_south_beach` | Icon at South Beach | `way:481648934` | `25.773920, -80.141081` | `61.0` | `129.0` | `2` | Arquitectonica / Starck (2005), OSM `129.0 m` (42 fl) stepped bayfront tiers. |
| `murano_grande` | Murano Grande at Portofino | `way:117915438` | `25.772849, -80.140400` | `8.1` | `127.0` | `2` | Sieger Suarez (2003), OSM `127.0 m` (37 fl). |
| `murano_at_portofino` | Murano at Portofino | `way:237435613` | `25.768562, -80.137554` | `-31.3` | `122.5` | `1` | Sieger Suarez (2001, 37 fl, 402 ft). |
| `the_setai_tower` | The Setai Residences | `25.796800, -80.128100` | `25.796800, -80.128100` | `-1.5` | `118.0` | `2` | Alayo & Denniston (2004, 40 fl, 386 ft) teal-glass tower beside Deco hotel. |
| `waverly_south_beach` | The Waverly at South Beach | `way:827740921` | `25.784775, -80.143372` | `-1.4` | `110.0` | `1` | Arquitectonica (2001, 36 fl) with rooftop wave sculpture. |
| `south_pointe_tower` | South Pointe Tower | `way:263002505` | `25.767247, -80.134150` | `62.7` | `95.3` | `1` | OSM `95.3 m` (25 fl). |
| `apogee_south_beach` | Apogee South Beach | `way:117915448` | `25.767909, -80.136324` | `84.0` | `86.1` | `1` | Sieger Suarez (2008), OSM `86.1 m` (22 fl). |
| `bentley_bay_towers` | Bentley Bay North & South | `25.775800, -80.141900` | `25.775800, -80.141900` | `12.0` | `82.0` | `1` | Arquitectonica (2005, 25 fl twin curved sail towers at MacArthur landing). |
| `eden_roc_miami_beach` | Eden Roc Miami Beach | `way:135296603` | `25.819433, -80.122080` | `6.6` | `68.0` | `2` | Morris Lapidus (1955), ocean-liner funnel louvred crown + 21-fl Ocean Tower. |
| `faena_hotel_saxony` | Faena Hotel (Saxony) | `way:436123285` | `25.807420, -80.123340` | `-69.4` | `56.3` | `1` | Roy France (1948), OSM `56.3 m` white & red-trim Mid-Beach landmark. |
| `delano_south_beach` | Delano South Beach | `way:263592326` | `25.792103, -80.129350` | `-1.6` | `58.0` | `2` | Robert Swartburg (1947, 16 fl, `58 m`), white stepped tower with 4-winged Deco finned crown. |
| `national_hotel_miami_beach` | National Hotel Miami Beach | `way:263592327` | `25.791862, -80.129014` | `-1.7` | `52.0` | `2` | Roy France (1939, 13 fl, `52 m`), fluted silver Art Deco cupola dome. |
| `grove_at_grand_bay` | Grove at Grand Bay | `way:1529521451` | `25.730460, -80.236896` | `87.9` | `94.0` | `2` | BIG / Bjarke Ingels (2016, twin 20-fl twisting glass towers, `94 m`). |
| `park_grove_towers` | Park Grove | `way:749258403` | `25.729320, -80.238541` | `22.8` | `90.0` | `1` | OMA / Rem Koolhaas (2018–2020, three peanut-column organic towers, `90 m`). |
| `porsche_design_tower` | Porsche Design Tower | `25.948100, -80.120100` | `25.948100, -80.120100` | `0.0` | `195.4` | `2` | Sieger Suarez (2017, Sunny Isles cylindrical dark-glass tower, 641 ft, 60 fl). |
| `jade_signature_sunny_isles` | Jade Signature | `25.932800, -80.121100` | `25.932800, -80.121100` | `0.0` | `193.9` | `2` | Herzog & de Meuron (2018, Sunny Isles white structural blade slab, 636 ft, 57 fl). |
| `turnberry_ocean_club` | Turnberry Ocean Club | `25.947200, -80.120200` | `25.947200, -80.120200` | `0.0` | `197.8` | `2` | Carlos Zapata (2020, Sunny Isles cantilevered sky-pool slab, 649 ft, 54 fl). |
| `muse_sunny_isles` | Muse Sunny Isles | `25.935500, -80.120900` | `25.935500, -80.120900` | `0.0` | `197.8` | `1` | Carlos Ott / Sieger Suarez (2018, twisting sculpted balcony tower, 649 ft, 49 fl). |

---

## 4. Bridges (`BridgeSpecsNorthAmerica`, MI-5A)

| ID | Bridge | OSM Way / Rel | Centroid (`lat, lon`) | `bearing` | `st` | Total / Spans (m) | Width / Clear (m) | Conf | Source |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `br_miami_macarthur_west` | MacArthur Causeway West Bridge | `rel:13378650` / `way:38842400` | `25.78716, -80.18261` | `86.9` | `girder` | `605.9` (high ICW channel `46 m` + piers) | `34.0` / `19.8` (65 ft USCG) | `2` | USCG / FDOT Trooper Robert G. Smith Bridge (1997, 65 ft ICW vertical clearance) + OSM `way:38842400` |
| `br_miami_macarthur_east` | MacArthur Causeway East Bridge | `way:601014485` / E channel | `25.77450, -80.14580` | `115.0` | `girder` | `335.0` | `32.0` / `10.7` (35 ft USCG) | `2` | USCG / FDOT East Channel bridge (35 ft clearance) + OSM |
| `br_miami_port_boulevard` | PortMiami Bridge (Port Boulevard) | `way:42778597` | `25.77991, -80.18337` | `290.1` | `girder` | `771.7` | `26.0` / `19.8` (65 ft USCG) | `2` | FDOT / PortMiami 1991 twin high-level fixed girder (65 ft ICW clearance) + OSM `way:42778597` |
| `br_miami_venetian_west` | Venetian Causeway West Drawbridge | `way:39028112` | `25.78978, -80.18300` | `87.0` | `movable` | `401.5` | `14.6` / `4.6` | `2` | Historic Miami-Dade / USCG (1926/1999 bascule + concrete trestle spans, ball balustrades) + OSM |
| `br_miami_venetian_east` | Venetian Causeway East Drawbridge | `way:997041200` | `25.79122, -80.15222` | `80.5` | `movable` | `224.4` | `14.6` / `4.6` | `2` | USCG / Historic Venetian Causeway East bascule + OSM `way:997041200` |
| `br_miami_brickell_ave` | Brickell Avenue Bridge | `way:992945519` | `25.77002, -80.19005` | `1.4` | `movable` | `140.1` | `32.0` / `7.6` | `2` | FDOT SR 905 twin-leaf bascule (1995, 25 ft closed clearance) + OSM `way:992945519` |
| `br_miami_south_miami_ave` | South Miami Avenue Bridge | `way:992946537` | `25.76898, -80.19342` | `357.9` | `movable` | `76.9` | `20.0` / `6.7` | `2` | Miami-Dade twin-leaf bascule over Miami River + OSM `way:992946537` |
| `br_miami_sw_2nd_ave` | SW 2nd Avenue Bridge | `way:965031120` | `25.76884, -80.19760` | `178.0` | `movable` | `97.9` | `21.0` / `7.0` | `2` | FDOT twin-leaf bascule over Miami River + OSM `way:965031120` |
| `br_miami_sw_1st_st` | SW 1st Street Bridge | `way:993098791` | `25.77304, -80.20059` | `81.1` | `movable` | `79.9` | `19.5` / `7.6` | `2` | FDOT / Hardesty & Hanover 2022 twin-leaf bascule + OSM `way:993098791` |
| `br_miami_west_flagler` | West Flagler Street Bridge | `way:993098792` | `25.77411, -80.20203` | `264.0` | `movable` | `108.7` | `22.0` / `7.0` | `2` | FDOT twin-leaf bascule over Miami River + OSM `way:993098792` |
| `br_miami_brickell_key` | Brickell Key Bridge | `way:38997223` | `25.76557, -80.18704` | `85.4` | `girder` | `135.0` | `18.0` / `5.5` | `2` | Low fixed concrete girder to Brickell Key + OSM `way:38997223` |
| `br_miami_william_powell` | William M. Powell Bridge (Rickenbacker) | `way:42691106` | `25.74650, -80.18442` | `269.1` | `girder` | `1099.9` | `32.0` / `22.9` (75 ft USCG) | `2` | 1985 high-level segmental box-girder bridge (75.5 ft ICW clearance) + OSM `way:42691106` |
| `br_miami_julia_tuttle` | Julia Tuttle Causeway Bridge | `way:39034736` | `25.81079, -80.17653` | `270.6` | `girder` | `655.0` | `38.0` / `17.1` (56 ft USCG) | `2` | FDOT I-195 ICW girder bridge (56 ft clearance) + OSM `way:39034736` |
