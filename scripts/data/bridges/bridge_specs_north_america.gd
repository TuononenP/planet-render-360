class_name BridgeSpecsNorthAmerica
extends RefCounted

## Capital bridge rows for North America and Central America (see BridgeSpec for the schema). Figures are
## sourced per row in `src`; conf 1 rows are kept as data but not built
## (BridgeSpec.MIN_BUILT_CONF).

static func rows() -> Array:
	return [
		{"id": "br_washington_frederick_douglass_memorial_bridge", "cc": "US", "name": "Frederick Douglass Memorial Bridge", "wiki": "Frederick Douglass Memorial Bridge",
			"aliases": ["south capitol street bridge", "douglass bridge anacostia"], "lat": 38.86847, "lon": -77.0056,
			"bearing": 297.3, "st": "arch_tied", "spans": [138.0, 164.6, 138.0], "width": 37.3, "clear": 15.0,
			"rise": 36.0, "material": "steel", "base": "water", "tier": 2, "conf": 2,
			"src": "en Wikipedia (1444 ft, longest span 541 ft), web search: ASCE/AECOM/Roads&Bridges " +
				"(452.5+540+452.5 ft, 122.5 ft wide, hexagonal steel box arches, deck hung from hangers); OSM " +
				"South Capitol St ways centre (38.86847,-77.0056) bearing 297.3 agree with Wikipedia " +
				"38.8684,-77.0056; clear and arch crown height over deck estimated | verified: ENR (enr.com " +
				"award of merit: three steel arches, 540 ft main span with 452 ft side spans, 1,445 ft, " +
				"arches rise 168 ft above water) and AISC Prize Bridge profile via search (same spans, 1,444 " +
				"ft); en Wikipedia (1444 ft, three sets of parallel through arches, six lanes + path); " +
				"earlier pass cited ASCE/AECOM for 122.5 ft width (not re-read); pre-construction design gave " +
				"42 ft vertical clearance under the fixed span so road about 15 m over water and arch crown " +
				"about 36 m above deck (168 ft = 51 m over water); OSM South Capitol St bridge ways " +
				"910656490/1 (454 m, 297.3/117.3 deg, mid 38.86852,-77.00558) agree with row"},
		{"id": "br_washington_chain_bridge", "cc": "US", "name": "Chain Bridge", "wiki": "Chain Bridge (Potomac River)",
			"aliases": ["chain bridge potomac"], "lat": 38.92993, "lon": -77.11424, "bearing": 258.0, "st": "girder",
			"spans": [52.4, 52.4, 52.4, 52.4, 52.4, 52.4, 52.4, 52.4], "width": 13.6, "clear": 18.0,
			"material": "steel", "base": "water", "tier": 3, "conf": 2,
			"src": "en Wikipedia (1938 continuous steel girder on 1870s piers, 3 lanes); bridge-inventory " +
				"records via search (8 main spans, max span 52.4 m, 421.5 m, deck 44.6 ft); equal spans = " +
				"421.5/8; OSM way 413 m bearing 258.0, mid agrees with Wikipedia 38.93,-77.1144; clear " +
				"estimated | verified: bridgelookup/bridgecondition inventory via search (8 main spans, max " +
				"span 171.9 ft = 52.4 m, length 1382.9 ft = 421.5 m, deck 44.6 ft = 13.6 m wide, 3 lanes); " +
				"Structurae (haunched twin girders on 1870s piers); Arlington Historical Society (1938 steel " +
				"girder, 5 ft higher than the old bridge); since max span 52.4 m x 8 = 419 m against 421.5 m " +
				"overall the spans are effectively equal (differences under 2.5 m in total); OSM ways " +
				"26708895 (413 m, 258.0 deg, mid 38.92992,-77.11425) and footway 61433253 (421 m) re-measured " +
				"and agree with row; the first pass's '44.6 ft' was the deck width, not the height; clear 18 " +
				"m still an estimate"},
		{"id": "br_washington_theodore_roosevelt_bridge", "cc": "US", "name": "Theodore Roosevelt Bridge", "wiki": "Theodore Roosevelt Bridge",
			"aliases": ["roosevelt bridge potomac", "theodore roosevelt memorial bridge"], "lat": 38.8925,
			"lon": -77.0583, "bearing": 77.8, "st": "girder",
			"spans": [42.3, 57.0, 67.7, 67.7, 67.7, 67.7, 67.7, 57.0, 42.3], "width": 29.8, "clear": 14.0,
			"material": "steel", "base": "water", "tier": 2, "conf": 1,
			"src": "en Wikipedia (haunched steel girder 1964, 7 lanes); bridgelookup inventory (1762 ft, max " +
				"span 222 ft, deck 97.8 ft) via search; individual spans GUESSED, symmetric around the max " +
				"span to sum 537 m; OSM way bearing 77.8; clear estimated | verified: searches found no " +
				"source for the individual spans (Structurae record gated); OSM ways 50560692 (431 m, 77.8 " +
				"deg, mid 38.89249,-77.05828) and 6058637 (475 m, 257.8) re-measured, row centre and bearing " +
				"agree; the haunched girder spans stay guessed | round 2: round 2: Structurae (haunched steel " +
				"girder, 1964; span data paywalled), Wikipedia, DDOT library; no span lengths found"},
		{"id": "br_washington_duke_ellington_bridge", "cc": "US", "name": "Duke Ellington Bridge", "wiki": "Duke Ellington Bridge",
			"aliases": ["calvert street bridge"], "lat": 38.92336, "lon": -77.04891, "bearing": 275.3,
			"st": "arch_deck", "spans": [44.5, 44.5, 44.5], "width": 25.6, "clear": 39.0, "rise": 14.0,
			"material": "concrete", "base": "ground", "tier": 3, "conf": 1,
			"src": "en Wikipedia (three 146 ft arches, 825 ft long, roadway 60 ft + 2x12 ft footways, 128 ft " +
				"high); length 825 ft does not equal 3 arches so approach arches are omitted; OSM Calvert St " +
				"way bearing 275.3; rise estimated | verified: en Wikipedia re-read (three 146 ft arches, " +
				"western over Cathedral Ave, central over the parkway, eastern over Rock Creek; 825 ft long, " +
				"128 ft high, roadway 60 ft + footways) and OSM Calvert Street way 24792765 (236 m, 275.3 " +
				"deg, mid 38.92336,-77.04891) agree with row; no second source for arch rise or the approach " +
				"arches (825 ft is more than three arches) | round 2: round 2: Structurae snippet (three " +
				"limestone-faced concrete arches of ~146 ft), LoC HAER DC-23 listing (triple arch, Modjeski " +
				"Masters & Chase, 1933-35), Wikipedia (roadway 60 ft + 2x12 ft); arch rise and the 387 ft of " +
				"approach beyond the three arches (825 ft total) still unsourced, left at 1"},
		{"id": "br_washington_taft_bridge", "cc": "US", "name": "Taft Bridge", "wiki": "Taft Bridge",
			"aliases": ["william howard taft bridge", "connecticut avenue bridge"], "lat": 38.9212, "lon": -77.0502,
			"bearing": 335.6, "st": "arch_deck", "spans": [31.0, 52.0, 52.0, 52.0, 52.0, 52.0, 31.0], "width": 20.0,
			"clear": 41.0, "rise": 12.0, "material": "concrete", "base": "ground", "tier": 2, "conf": 1,
			"src": "Streets of Washington/Clio via search (7 arches: five of 150 ft, two of 82 ft, deck 136 ft " +
				"above creek floor, roadway 52 ft); sources disagree on length (901/1068/1157/1341 ft); order " +
				"of arches and piers (+6 m) GUESSED; OSM Connecticut Ave ways bearing 335.6 | verified: en " +
				"Wikipedia re-read (unreinforced concrete arches, 325.5 m between abutments, 1897-1907); no " +
				"source for arch order; OSM Connecticut Avenue ways 24792770 + 1212403787 (208 + 201 m, 335.6 " +
				"deg) agree with the row centre and bearing; arch layout still a guess | round 2: round 2: " +
				"searched HAER DC-6 / LoC / NPS Rock Creek parkway poster / Streets of Washington; NPS " +
				"nomination gives deck ~52 ft wide and five of seven arches over Rock Creek; no per-arch " +
				"spans in any retrievable source (loc.gov blocked); arch order still a guess"},
		{"id": "br_washington_whitney_young_memorial_bridge", "cc": "US", "name": "Whitney Young Memorial Bridge", "wiki": "Whitney Young Memorial Bridge",
			"aliases": ["east capitol street bridge"], "lat": 38.8898, "lon": -76.96431, "bearing": 270.1,
			"st": "girder",
			"spans": [38.7, 38.7, 38.7, 38.7, 38.7, 38.7, 38.7, 38.7, 38.7, 38.7, 38.7, 38.7, 38.7, 38.7, 38.7],
			"width": 26.0, "clear": 9.0, "material": "steel", "base": "water", "tier": 3, "conf": 1,
			"src": "en Wikipedia (plate girder, 1910 ft/580 m (text says 1800 ft), 15 spans on 14 piers, 86 ft " +
				"wide); equal spans GUESSED; OSM ways bearing 270.1, agree with Wikipedia 38.88976,-76.96498; " +
				"clear estimated | verified: en Wikipedia re-read (plate girder, 15 spans on 14 piers, 1800 " +
				"ft in the text but 1910 ft in the infobox, 82-86 ft wide); equal spans still unsupported; " +
				"OSM not re-measured (API rate-limited) | round 2: round 2: Wikipedia mirrors / DDOT photo " +
				"archive: plate girder by J.E. Greiner, 15 spans on 14 piers, 1800 ft (infobox 1910 ft), 82 " +
				"ft roadway; no per-span lengths found, equal spans unsupported"},
		{"id": "br_washington_francis_case_memorial_bridge", "cc": "US", "name": "Francis Case Memorial Bridge", "wiki": "Francis Case Memorial Bridge",
			"aliases": ["francis case bridge"], "lat": 38.88056, "lon": -77.03098, "bearing": 232.0, "st": "girder",
			"spans": [96.2, 96.2, 96.2, 96.2, 96.2], "width": 30.3, "clear": 12.0, "material": "steel", "base": "water",
			"tier": 3, "conf": 1,
			"src": "en Wikipedia (steel beam, 1578 ft, 99.4 ft wide, two spans splitting to three on the north " +
				"side); five equal spans GUESSED; OSM Case ways bearings 226-237, Wikipedia coordinate used " +
				"for the centre; clear estimated | verified: en Wikipedia re-read (steel beam, two spans " +
				"splitting to three on the north side, eight lanes plus path); span lengths unsourced; OSM " +
				"not re-measured (API rate-limited) | round 2: round 2: no new source for span lengths found; " +
				"unchanged"},
		{"id": "br_washington_woodrow_wilson_bridge", "cc": "US", "name": "Woodrow Wilson Bridge", "wiki": "Woodrow Wilson Bridge",
			"aliases": ["wilson bridge potomac"], "lat": 38.79314, "lon": -77.03092, "bearing": 87.7, "st": "bascule",
			"spans": [85.0, 82.0, 85.0], "width": 76.0, "clear": 21.0, "material": "steel", "base": "water", "tier": 2,
			"conf": 1,
			"src": "en Wikipedia / Hardesty&Hanover / Structurae via search (twin bridges 6736 ft total, bascule " +
				"trunnions 270 ft apart, 70 ft clearance closed, ~249 ft total width of both decks); bascule " +
				"position along the bridge and side spans GUESSED (centre = OSM chain midpoint); twin decks " +
				"merged into one; OSM bearing 87.7; 11.4 km from the catalog point | verified: Wikipedia " +
				"article text could not be fetched; row not re-checked beyond the first-pass sources; twin " +
				"bascule decks merged into one and the bascule position along the bridge is unknown; 11.4 km " +
				"from catalog point | round 2: round 2: not re-examined; twin-deck merge and bascule position " +
				"remain unresolved"},
		{"id": "br_panama_city_bridge_of_the_americas", "cc": "PA", "name": "Bridge of the Americas", "wiki": "Bridge of the Americas",
			"aliases": ["puente de las américas", "puente de las americas"], "lat": 8.9431, "lon": -79.565,
			"bearing": 247.2, "st": "arch_through", "spans": [344.0], "width": 18.0, "clear": 61.3, "rise": 45.0,
			"material": "steel", "base": "sea", "tier": 1, "conf": 1,
			"src": "en Wikipedia (main span 344 m, 14 spans 1654 m total, 61.3 m clearance, cantilever with " +
				"suspended tied-arch span); Wikipedia width 10.4 m looks wrong for 4 lanes, 18 m ESTIMATED; " +
				"arch rise guessed; centre interpolated on OSM way (bearing 247.2) at the Wikipedia point " +
				"8.94306,-79.565; cantilever approach trusses not modelled | verified: en Wikipedia re-read " +
				"(cantilever with suspended tied arch, main span 344 m of which 259 m is the tied arch, 14 " +
				"spans 1654 m abutment to abutment, width 10.4 m, high point 117 m above sea level); OSM way " +
				"147612377 (1112 m, 247.2 deg) agrees with the bearing; the cantilever approach spans and " +
				"real deck width are not sourced | round 2: round 2: not re-examined; cantilever approaches " +
				"and real deck width still unsourced"},
		{"id": "br_ottawa_alexandra_bridge", "cc": "CA", "name": "Alexandra Bridge", "wiki": "Alexandra Bridge",
			"aliases": ["pont alexandra", "interprovincial bridge ottawa"], "lat": 45.4305, "lon": -75.7051,
			"bearing": 297.7, "st": "truss", "spans": [97.77, 97.77, 172.21, 97.77, 97.77], "width": 18.89,
			"clear": 20.0, "rise": 22.0, "material": "steel", "base": "water", "tier": 2, "conf": 1,
			"src": "en Wikipedia (steel truss cantilever, 5 spans, main cantilever span 172.21 m, 563.27 m, " +
				"18.89 m wide, 1901); Heritage Ottawa via search; side spans = (563.27-172.21)/4 inferred; " +
				"OSM ways 399+178 m bearing 297.7 (centre within 60 m of Wikipedia 45.4302,-75.7045); clear " +
				"and truss height estimated | verified: en Wikipedia (5 spans, 563.27 m, main cantilever span " +
				"172.21 m, 18.89 m wide, height 28.95 m) and searches: no source lists the four other spans, " +
				"so the (563.27-172.21)/4 split is an inference, not a source; OSM ways 39571207 + 406523334 " +
				"(396 + 178 m, 297.7 deg) agree with the row centre and bearing | round 2: round 2: Heritage " +
				"Ottawa (heritageottawa.org node 1637) says one short truss + five truss sections of nearly " +
				"identical 247 ft and a 555 ft 9 in joined cantilever span; CSCE historic-site page gives " +
				"clear span 320 m and 818 m between abutments; a 1917 CPR summary (churcher.crcml.org) lists " +
				"138/247 ft through trusses and plate-girder spans. The sources conflict with each other and " +
				"with Wikipedia's 563 m / 5 spans; no consistent span layout, so the (563.27-172.21)/4 split " +
				"stays unsourced"},
		{"id": "br_ottawa_macdonald_cartier_bridge", "cc": "CA", "name": "Macdonald-Cartier Bridge", "wiki": "Macdonald-Cartier Bridge",
			"aliases": ["pont macdonald-cartier", "macdonald cartier bridge"], "lat": 45.43705, "lon": -75.70307,
			"bearing": 290.5, "st": "girder", "spans": [88.39, 141.43, 159.1, 141.43, 88.39], "width": 29.8,
			"clear": 13.0, "material": "steel", "base": "water", "tier": 2, "conf": 2,
			"src": "en Wikipedia (618 m, 1965, six lanes; infobox box-girder truss vs body box girder); equal " +
				"spans, width, clear GUESSED; OSM ways 658 m bearing 290.5 agree with Wikipedia " +
				"45.4367,-75.7025 | verified: en Wikipedia re-read (618 m continuous steel box girder, six " +
				"lanes, infobox says girder truss); spans and width unsourced; OSM not re-measured (API rate- " +
				"limited) | round 2: round 2: archived Transport Canada bridge listing (bac- " +
				"lac.wayback.archive-it.org/web/20071222081253/http://www.tc.gc.ca/programs/surface/bridges/m " +
				"acdonaldcartier.htm): five span continuous steel box girder with concrete deck, spans " +
				"88.39+141.43+159.10+141.43+88.39 m = 618.74 m (matches Wikipedia 618 m), roadway 25.60 m + " +
				"two sidewalks of 2.13 m = 29.9 m, deck 12.19 m (40 ft) above the Ottawa River (clear set to " +
				"13 as a hedge); OSM motorway ways 621115407/1443195673 (659 m incl. abutment ends, " +
				"290.5/110.5 deg, mid 45.43697-45.43708,-75.70304..-75.70310) and footways re-measured, " +
				"centre and bearing confirmed"},
		{"id": "br_santo_domingo_duarte_bridge", "cc": "DO", "name": "Puente Duarte", "wiki": "Duarte Bridge",
			"aliases": ["puente juan pablo duarte", "duarte bridge santo domingo"], "lat": 18.48629, "lon": -69.88304,
			"bearing": 94.9, "st": "susp", "spans": [111.25, 175.5, 111.25], "width": 17.0, "clear": 20.0,
			"tower": 55.0, "material": "steel", "base": "water", "tier": 2, "conf": 1,
			"src": "en Wikipedia (steel suspension, single suspended span 175.5 m, towers 55 m); total 398 m " +
				"from the OSM way (bearing 94.9, mid agrees with Wikipedia 18.4863,-69.8827), side spans " +
				"split evenly; width and clear GUESSED; type not cross-checked | verified: en Wikipedia re- " +
				"read (steel suspension bridge, single suspended span 175.5 m, towers 55 m, opened 1955); OSM " +
				"way 28036981 (398 m, 94.9 deg, mid 18.48629,-69.88304) agrees with row; side spans, width " +
				"and deck height unsourced | round 2: round 2: es Wikipedia (Puente Juan Pablo Duarte, citing " +
				"Structurae) gives only the 175.5 m suspended span and 55 m towers; side spans, width, deck " +
				"height unsourced"},
		{"id": "br_santo_domingo_juan_bosch_bridge", "cc": "DO", "name": "Puente Juan Bosch", "wiki": "Puente Juan Bosch",
			"aliases": ["puente profesor juan bosch", "juan bosch bridge"], "lat": 18.48655, "lon": -69.8818,
			"bearing": 95.2, "st": "stayed", "spans": [116.75, 116.75, 180.0, 116.75, 116.75], "width": 30.0,
			"clear": 16.0, "tower": 63.0, "towers": [2, 3], "material": "concrete", "base": "water", "tier": 2,
			"conf": 1,
			"src": "EcuRed/Acento/inmobiliario.do via search (cable-stayed, 647.1 m, central span 180 m, five " +
				"spans, 2 towers 63 m, 30-33.5 m wide, 2001); side-span lengths and tower positions GUESSED " +
				"((647-180)/4 each); OSM way 647 m bearing 95.2; tower top and clear estimated | verified: " +
				"EcuRed/elCaribe via search (cable-stayed concrete, 647.1 m total = main bridge 346.9 m + 233 " +
				"m east viaduct + 68.2 m west viaduct, five spans with 180 m central, towers 63 m, deck up to " +
				"35 m over river, 30 m wide); the other four span lengths are not given (EcuRed's side-span " +
				"figures are inconsistent); OSM ways 28036976/28037109 (647 m, 95.2 deg, mid " +
				"18.48644,-69.88181) agree with row centre and bearing | round 2: round 2: es Wikipedia " +
				"'Puente Juan Bosch' (citing Structurae/ropdigital) gives main bridge spans " +
				"36+47.5+180+47.5+36 = 347 m (not the 116.75 guess), viaducts of 25 m precast spans (east 233 " +
				"m, west 68.2 m; its '15 spans' count does not match 233+68.2 m), deck width 33.5 m (EcuRed " +
				"30 m), deck up to 35 m above the river (row clear 16 conflicts), towers 63 m. The row layout " +
				"is wrong but the viaduct spans and deck height are inconsistent between sources, so no " +
				"conf-2 replacement; a correct main-bridge-only layout would be spans [36,47.5,180,47.5,36] " +
				"with towers [2,3] and tower 63"},
		{"id": "br_san_juan_teodoro_moscoso_bridge", "cc": "PR", "name": "Teodoro Moscoso Bridge", "wiki": "Teodoro Moscoso Bridge",
			"aliases": ["puente teodoro moscoso"], "lat": 18.4237, "lon": -66.0249, "bearing": 14.9, "st": "girder",
			"spans": [17.0, 17.0, 17.0, 17.0, 30.1, 30.1, 30.1, 30.1, 30.1, 30.1, 30.1, 30.1, 30.1, 30.1, 30.1, 30.1, 30.1, 30.1, 30.1, 30.1, 30.1, 30.1, 30.1, 30.1, 30.1, 30.1, 30.1, 30.1, 30.1, 30.1, 30.1, 30.1, 30.1, 30.1, 30.1, 30.1, 30.1, 30.1, 30.1, 30.1, 30.1, 30.1, 30.1, 30.1, 30.1, 30.1, 30.1, 30.1, 30.1, 30.1, 30.1, 30.1, 30.1, 30.1, 30.1, 30.1, 30.1, 30.1, 30.1, 30.1, 30.1, 30.1, 30.1, 30.1, 30.1, 30.1, 30.1, 30.1, 30.1, 23.5, 23.5, 23.5, 23.5, 23.5, 23.5, 23.5, 23.5],
			"width": 28.0, "clear": 8.0, "material": "concrete", "base": "water", "tier": 3, "conf": 1,
			"src": "en Wikipedia (low-level trestle, 2.25 km); Structurae via search (77 spans: 8 x 23.5, 65 x " +
				"30.1, 4 x 17 m, precast girders, 2+2 lanes); ORDER of span groups, width and clear GUESSED; " +
				"OSM Pinero expressway way bearing 14.9 | verified: en Wikipedia re-read (2.25 km low-level " +
				"trestle girder bridge over San Jose Lagoon, four lanes); OSM Pinero expressway ways 59592740 " +
				"(1823 m, 14.9 deg) and 59592719 (2037 m) agree with the bearing; the Structurae span groups " +
				"and their order are still unsourced guesses | round 2: round 2: es Wikipedia page is short " +
				"and gives no span groups; span group order stays unsourced"},
	]
