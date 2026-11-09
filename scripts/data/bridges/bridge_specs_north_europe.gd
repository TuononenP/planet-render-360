class_name BridgeSpecsNorthEurope
extends RefCounted

## Capital bridge rows for Northern Europe (see BridgeSpec for the schema). Figures are
## sourced per row in `src`; conf 1 rows are kept as data but not built
## (BridgeSpec.MIN_BUILT_CONF).

static func rows() -> Array:
	return [
		{"id": "br_stockholm_centralbron", "cc": "SE", "name": "Centralbron", "wiki": "Centralbron",
			"aliases": ["central bridge stockholm"], "lat": 59.3235, "lon": 18.0665, "bearing": 333.5, "st": "girder",
			"spans": [28.1, 33.7, 31.7, 31.7, 33.7, 30.1], "width": 21.8, "clear": 10.0, "material": "steel",
			"base": "water", "tier": 2, "conf": 1,
			"src": "en+sv Wikipedia (Soderstrom bridge 189 m, 6 continuous steel-girder spans on concrete piers, " +
				"max span 33.7 m, 21.8 m wide), en Wikipedia coordinate 59.3235,18.0668, OSM Centralbron ways " +
				"bearing 333.5 (23000196); individual spans other than the 33.7 m maximum split by estimate; " +
				"only the southern river crossing modelled, not the 1.2 km viaduct chain; clear estimated | " +
				"verified: en+sv Wikipedia state only the total (189 m), six continuous steel-girder spans " +
				"and the maximum span 33.7 m, no per-span list; OSM ways 23000196/4802609 (457 m, bearing " +
				"333.5/153.5) start at the south abutment, so the 6-span crossing is the 189 m at its south " +
				"end, centre 59.3235,18.0665 confirmed; width 21.8 (sv) vs 21.3 (en) | round 2: verify2: " +
				"searched and not found - sv Wikipedia re-read: 189 m, 21.8 m, six continuous steel-girder " +
				"spans, max 33.7 m; no per-span list in sv/en; not found elsewhere"},
		{"id": "br_stockholm_tranebergsbron", "cc": "SE", "name": "Tranebergsbron", "wiki": "Tranebergsbron",
			"aliases": ["traneberg bridge"], "lat": 59.33346, "lon": 17.99512, "bearing": 274.5, "st": "arch_deck",
			"spans": [181.0], "width": 27.0, "clear": 28.0, "rise": 25.0, "material": "concrete", "base": "water",
			"tier": 2, "conf": 2,
			"src": "en+sv Wikipedia (concrete arch span 181 m, 27 m wide, 32 m high, 25.2 m sail clearance, " +
				"450-580 m with viaducts), OSM way 5178978 (bearing 274.5, centre) agrees with Wikipedia " +
				"59.33361,17.995; only the main arch modelled, 2002 third parallel bridge not included in " +
				"width; deck height and arch rise estimated | verified: en+sv Wikipedia: 181 m concrete arch, " +
				"27 m wide (27.4 m for the two 1934 arches), sail clearance 25.2-26 m under the crown, '32 m " +
				"high' overall; OSM way 5178978 (453 m, bearing 274.5, mid 59.33346,17.99512) with shoreline " +
				"crossings at 130 m and 328 m of the way, i.e. water 198 m centred exactly on the way " +
				"midpoint; crown carries the deck so clear 28 (25.2 m clearance + arch thickness) and arch " +
				"rise about 25 m"},
		{"id": "br_stockholm_skeppsholmsbron", "cc": "SE", "name": "Skeppsholmsbron", "wiki": "Skeppsholmsbron",
			"aliases": ["skeppsholm bridge"], "lat": 59.32732, "lon": 18.07913, "bearing": 139.7, "st": "arch_deck",
			"spans": [33.0, 33.0, 33.0, 33.0, 33.0], "width": 9.5, "clear": 4.5, "rise": 2.5, "material": "iron",
			"base": "sea", "tier": 2, "conf": 1,
			"src": "en+sv Wikipedia (1861 forged-iron bridge, 5 bays, 165 m, 9.5 m wide), OSM way 4741923 " +
				"bearing 139.7; equal spans assumed, rise and clear estimated | verified: en+sv Wikipedia: " +
				"165 m, 5 bays/arches, 9.5 m wide (5.5 m roadway + 2x2 m paths), forged iron 1861; Structurae " +
				"calls it a girder bridge; no source states the five bays are equal; OSM way 4741923 (173 m) " +
				"shoreline crossings at 1.9 and 166 m = 164 m of water, centre 59.32732,18.07913 and bearing " +
				"139.7 confirmed | round 2: verify2: searched and not found - sv Wikipedia re-read: steel " +
				"five-bay bridge, 165 m, ~9.5 m; no source gives bay lengths or says they are equal"},
		{"id": "br_stockholm_danviksbron", "cc": "SE", "name": "Danviksbron", "wiki": "Danviksbro",
			"aliases": ["danvik bridge", "danviksbro"], "lat": 59.31362, "lon": 18.10476, "bearing": 118.9,
			"st": "bascule", "spans": [25.0, 37.0, 28.0], "width": 22.0, "clear": 4.5, "material": "steel",
			"base": "water", "tier": 3, "conf": 1,
			"src": "en+sv Wikipedia (single-leaf bascule 1956, 22 m wide, 12.5 m open clearance; older 15 m wide " +
				"leaf demolished 2023), OSM ways 16744539 (90 m, bearing 118.9); leaf 37 m taken from the " +
				"demolished sister leaf, side spans split from the OSM length, deck height estimated; heavy " +
				"counterweight not modelled | verified: sv Wikipedia: two single-leaf bascules side by side " +
				"(1922 Saltsjobanan + 1956 road bridge, 22 m wide, 12.5 m horizontal clearance, vertical " +
				"clearance 11.7-12.8 m when open); the 1922 37 m x 15 m leaf was demolished 2023; spans of " +
				"the remaining road bridge not given; OSM way 16744539 (90 m, bearing 118.9) confirmed | " +
				"round 2: verify2: searched and not found - sv Wikipedia re-read: 22 m wide (infobox 22 m/14 " +
				"m for the two leaves), 12.5 m clearance; no leaf or side-span lengths"},
		{"id": "br_stockholm_djurgardsbron", "cc": "SE", "name": "Djurgardsbron", "wiki": "Djurgårdsbron",
			"aliases": ["djurgårdsbron", "djurgarden bridge"], "lat": 59.33112, "lon": 18.09379, "bearing": 163.9,
			"st": "girder", "spans": [19.3, 19.4, 19.3], "width": 18.0, "clear": 3.5, "material": "iron", "base": "sea",
			"tier": 2, "conf": 1,
			"src": "en+sv Wikipedia (1897 three-span iron bridge, about 58 m, 18 m wide, 3.0 m sail clearance), " +
				"OSM way 23620161 bearing 163.9, agrees with Wikipedia 59.331,18.094; equal spans assumed | " +
				"verified: en+sv Wikipedia: three-span iron/steel bridge 1897, 18 m wide, about 58 m long " +
				"(the 58 m in sv is the 1977 reinforcement sections), sail clearance 3.0 m; no span split in " +
				"any source (Structurae snippet says three trusses); OSM way 23620161 (59 m, bearing 163.9) " +
				"shoreline crossings 2.8/58.8 m = 56 m water, centre confirmed | round 2: verify2: searched " +
				"and not found - sv Wikipedia re-read: no span split found"},
		{"id": "br_stockholm_vasabron", "cc": "SE", "name": "Vasabron", "wiki": "Vasabron",
			"aliases": ["vasa bridge stockholm"], "lat": 59.32742, "lon": 18.06413, "bearing": 140.7, "st": "arch_deck",
			"spans": [26.0, 29.5, 32.0, 32.0, 32.0, 29.5, 27.0], "width": 18.0, "clear": 5.0, "rise": 3.2,
			"material": "iron", "base": "water", "tier": 2, "conf": 1,
			"src": "en Wikipedia (1878 bridge, 7 arches, max span 32 m, 208 m, 18 m wide, cast iron/steel), OSM " +
				"way 28345891 (bearing 140.7, centre) agrees with Wikipedia 59.32722,18.06444; non-maximum " +
				"spans split by estimate; clear and rise estimated | verified: en Wikipedia: 1878 bridge 208 " +
				"m, 18 m wide, seven arches, maximum span 32 m; sv has only a disambiguation here; OSM way " +
				"28345891 (207 m, bearing 140.7), water crossing 8.9 to 206.7 m of the way = 198 m, centre " +
				"confirmed; only the 32 m maximum is sourced and the other six spans are estimates | round 2: " +
				"verify2: searched and not found - sv Wikipedia page is a stub/disambiguation; no span list " +
				"found"},
		{"id": "br_stockholm_essingebron", "cc": "SE", "name": "Essingebron", "wiki": "Essingebron",
			"aliases": ["essinge bridge"], "lat": 59.32339, "lon": 17.99904, "bearing": 40.1, "st": "girder",
			"spans": [55.0, 100.0, 55.0], "width": 18.0, "clear": 12.0, "material": "concrete", "base": "water",
			"tier": 3, "conf": 1,
			"src": "en+sv Wikipedia (three parallel bridges 1965-67; local bridge 200 m over water, max span 100 " +
				"m, 11 m wide), OSM Essingeleden way 4520745 (210 m, bearing 40.1) agrees with Wikipedia " +
				"59.32361,17.99889; side spans, motorway width, deck height and structure type (probably " +
				"concrete girder) estimated, one carriageway modelled | verified: sv+en Wikipedia: the LOCAL " +
				"bridge (Gamla Essinge Broväg) is 470 m between abutments, 200 m over water, max span 100 m, " +
				"11 m wide (8 m roadway), sail clearance 15.2 m (sv; en says 16 m horizontal); the modelled " +
				"Essingeleden carriageways (OSM ways 4520745/4520747, 211 m, bearing 40.1/220.3, water 192 m) " +
				"have no published span list; no source for the structure type | round 2: verify2: searched " +
				"and not found - sv Wikipedia re-read (Essingebron is the 1927 steel-arch predecessor " +
				"article; no span list for the Essingeleden carriageways)"},
		{"id": "br_stockholm_alviksbron", "cc": "SE", "name": "Alviksbron", "wiki": "Alviksbron",
			"aliases": ["alvik bridge"], "lat": 59.3266, "lon": 17.9864, "bearing": 122.9, "st": "girder",
			"spans": [130.0, 140.0, 130.0], "width": 14.0, "clear": 14.0, "material": "concrete", "base": "water",
			"tier": 3, "conf": 1,
			"src": "en Wikipedia (box girder, 400 m, 140 m central span, 24 m horizontal clearance, Tvarbanan " +
				"and path), OSM cycleway way 34175060 bearing 122.9 passes 10 m from Wikipedia " +
				"59.3266,17.9864; side spans split from total, width and deck height estimated | verified: " +
				"en+sv Wikipedia: prestressed concrete box girder, 400 m, central span 140 m, horizontal " +
				"clearance 24 m (sv segelfri hojd), cantilever-built (Freivorbau), two thin piers in the " +
				"water; OSM Tvarbanan way 120605994 and cycleway 34175060 give 259 m of water (shore " +
				"crossings 113-372 m), so [130,140,130] is not supported; side spans unknown; would be a " +
				"'haunched' type once the spans are found | round 2: verify2: searched and not found - sv " +
				"Wikipedia re-read: no side-span lengths"},
		{"id": "br_helsinki_pitkasilta", "cc": "FI", "name": "Pitkasilta", "wiki": "Pitkäsilta",
			"aliases": ["pitkäsilta", "langa bron", "long bridge helsinki"], "lat": 60.17637, "lon": 24.95011,
			"bearing": 177.3, "st": "masonry", "spans": [19.0, 19.0, 19.0], "width": 22.0, "clear": 5.0, "rise": 3.0,
			"material": "stone", "base": "sea", "tier": 2, "conf": 2,
			"src": "fi+en Wikipedia (1912 granite bridge, 3 arches of 16 m clear opening, 22 m wide), OSM ways " +
				"23952344 (57 m, bearing 177.3) = 3 x 16 m + piers, agrees with Wikipedia 60.17639,24.95; " +
				"piers 3 m assumed, clear and rise estimated | verified: fi Wikipedia infobox+text: three- " +
				"span granite vault, 'kolme vapaalta aukoltaan 16-metrista holvia' (three 16 m clear arches, " +
				"so equal), width 22 m, length 75 m incl. approach walls, 1912, designer Runar Eklund; OSM " +
				"ways 23952344/122869888 (57 m between abutments, bearing 177.3/357.2) mid 60.17637,24.95011; " +
				"pier thickness (3 m) and the deck/vault heights are estimates"},
		{"id": "br_helsinki_lauttasaaren_silta", "cc": "FI", "name": "Lauttasaaren silta", "wiki": "Lauttasaari bridge",
			"aliases": ["lauttasaari bridge", "drumso bro"], "lat": 60.16216, "lon": 24.89768, "bearing": 255.1,
			"st": "girder", "spans": [30.0, 46.2, 56.6, 56.6, 56.6, 41.0, 30.0], "width": 23.5, "clear": 12.0,
			"material": "steel", "base": "sea", "tier": 2, "conf": 1,
			"src": "fi+en Wikipedia (1969 composite steel-girder bridge with concrete deck, 317 m, 23.5 m, " +
				"longest span 56.6 m, deck over 12 m at the top), OSM way 4226243 (bearing 255.1, mid " +
				"60.16216,24.89768; Wikipedia 60.161,24.896 is a rounded point 130 m away); the other six " +
				"spans split by estimate | verified: fi Wikipedia: composite steel-beam bridge with " +
				"reinforced-concrete deck (+ former bascule leaf, now fixed), 317 m, 23.5 m, longest span " +
				"56.6 m, 'yli 12 m' deck height was for the 1935 predecessor; a Helsinki city decision text " +
				"gives 395 m length and 23.4 m usable width; OSM way 4226243 is 332 m (bearing 255.1, mid " +
				"60.16216,24.89768); only the 56.6 m span is sourced, six other spans estimated | round 2: " +
				"verify2: searched and not found - fi Wikipedia re-read: 317 m, 23.5 m, longest span 56.6 m " +
				"only; no other spans"},
		{"id": "br_helsinki_crusellinsilta", "cc": "FI", "name": "Crusell Bridge", "wiki": "Crusell Bridge",
			"aliases": ["crusellinsilta", "crusellbron"], "lat": 60.16036, "lon": 24.90818, "bearing": 158.0,
			"st": "stayed", "spans": [92.0, 51.5], "width": 24.8, "clear": 6.5, "tower": 49.0, "towers": [1],
			"pylon": "single", "material": "concrete", "base": "sea", "tier": 2, "conf": 2,
			"src": "en Wikipedia (asymmetric cable-stayed, total 173.5 m, main span 92 m, Jatkasaari-side 51.5 " +
				"m, 24.8 m wide, inclined steel pylon 49 m over sea), OSM ways 28639650 bearing 158.0 agree " +
				"with Wikipedia 60.16056,24.90833; the extra 30 m end span, the order of spans along the " +
				"bearing, single-pylon form and deck height are estimated | verified: fi Wikipedia: " +
				"asymmetric two-span cable-stayed bridge, total 173.5 m incl. approach, main span 92 m, " +
				"Jatkasaari span 51.5 m, width 24.8 m, tilted steel pylon top about 49 m over the sea, " +
				"vertical clearance 5.25 m (deck about 6.5 m with the girder), prestressed concrete girder; " +
				"en Wikipedia same figures; OSM way 28639650 (145 m, bearing 158.0, mid 60.16036,24.90818) " +
				"has its water crossing from 9.8 to 134.7 m = the 125 m bay, so the bridge proper is 92+51.5 " +
				"= 143.5 m and the earlier third 30 m span was the remainder of the 173.5 m, not a span; the " +
				"Ruoholahti end is north so the 92 m main span comes first"},
		{"id": "br_helsinki_isoisansilta", "cc": "FI", "name": "Isoisansilta", "wiki": "Isoisänsilta",
			"aliases": ["isoisänsilta", "farfarsbron", "grandfather bridge"], "lat": 60.18205, "lon": 24.98276,
			"bearing": 141.0, "st": "arch_through", "spans": [6.7, 144.3, 13.6], "width": 5.0, "clear": 8.0,
			"rise": 18.0, "material": "steel", "base": "sea", "tier": 3, "conf": 1,
			"src": "en Wikipedia (pedestrian/cycle bridge 2016, 170 m with 144 m main span, deck at least 4 m " +
				"wide), OSM cycleway ways 442579082 / 574607677 / 574607678 chain bearing 141; arch type, " +
				"rise, approach spans, width and clear estimated | verified: fi Wikipedia: orthotropic-deck " +
				"steel arch bridge with the deck hung from the arch by 22 hanger pairs, longest span 144.3 m " +
				"with adjacent spans 6.7 m and 13.6 m (which end is which is not given), width 4 m minimum " +
				"widening to two paths at the Kalasatama end, clearance 6.7 m; en says total about 170 m (the " +
				"listed spans sum 164.6 m); OSM cycleway chain 442579082 + 574607677/8 (bearing 140-141) " +
				"confirmed; arch rise unsourced | round 2: verify2: searched and not found - fi Wikipedia re- " +
				"read: spans 144.3 with neighbours 6.7 and 13.6 m, width 4 m, clearance 6.7 m; web search " +
				"found no source giving which end carries the 6.7 m span or the arch rise"},
		{"id": "br_helsinki_kulosaaren_silta", "cc": "FI", "name": "Kulosaaren silta", "wiki": "Kulosaaren silta",
			"aliases": ["kulosaarensilta", "kulosaari bridge", "brando bro"], "lat": 60.18626, "lon": 24.9853,
			"bearing": 102.7, "st": "girder", "spans": [30.0, 34.0, 35.0, 30.0, 35.0, 40.0, 42.0, 40.0, 35.0],
			"width": 32.0, "clear": 8.0, "material": "steel", "base": "sea", "tier": 3, "conf": 2,
			"src": "fi Wikipedia (1957 welded steel-girder grillage bridge, 321 m, 32 m wide, nine spans " +
				"30,34,35,30,35,40,42,40,35 m; demolition decided 2023, work from 2027 at earliest so it " +
				"still stands), OSM Kulosaarensilta way 219892295 bearing 102.7 agrees with Wikipedia " +
				"60.18625,24.98556; span order along the bearing and deck height assumed | verified: fi " +
				"Wikipedia: nine openings 30,34,35,30,35,40,42,40,35 m (321 m), 32 m wide, welded steel " +
				"girder grillage, 3+3 lanes, demolition decision 2023 (works 2027 at the earliest); OSM " +
				"eastbound carriageway 219892295 (263 m, bearing 102.7) crosses water from 56.6 to 251.8 m of " +
				"the way, consistent with the 40-42-40 m spans sitting over the channel when the list runs " +
				"west to east; the list direction is assumed to be Sorensen-to-Kulosaari"},
		{"id": "br_helsinki_kruunuvuorensilta", "cc": "FI", "name": "Kruunuvuorensilta", "wiki": "Crown Bridges",
			"aliases": ["kruunuvuori bridge", "crown bridge helsinki"], "lat": 60.1736, "lon": 25.0022,
			"bearing": 126.2, "st": "stayed", "spans": [200.0, 260.0], "width": 26.0, "clear": 20.0, "tower": 135.0,
			"towers": [1], "pylon": "single", "material": "steel", "base": "sea", "tier": 2, "conf": 1,
			"src": "fi Wikipedia (opened April 2026: 1191 m curved composite cable-stayed bridge, longest span " +
				"260 m, pylon 135 m, clearance up to 20 m, 17 stay pairs), OSM cycleway way 986936385 (1174 " +
				"m, bearing 126.2) and Wikipedia 60.17396,25.00244; only the stayed part modelled: side span, " +
				"width and horizontal curve not represented | verified: fi+en Wikipedia: Kruunuvuorensilta is " +
				"1191 m, a horizontally curved composite cable-stayed bridge, longest span 260 m, 17 stay " +
				"pairs, 135 m reinforced-concrete pylon between two islets, clearance up to 20 m, opened to " +
				"cyclists 18 April 2026; 72 m deck segments; OSM way 986936385 (1152 m, bearing 126.2, mid " +
				"60.17311,25.00217); span list and the curved plan are not published in the sources found | " +
				"round 2: verify2: searched and not found - fi Wikipedia re-read: no span list; curved plan " +
				"not representable"},
		{"id": "br_copenhagen_langebro", "cc": "DK", "name": "Langebro", "wiki": "Langebro",
			"aliases": ["long bridge copenhagen"], "lat": 55.67025, "lon": 12.57861, "bearing": 131.6, "st": "bascule",
			"spans": [106.0, 53.0, 95.0], "width": 30.0, "clear": 7.5, "material": "concrete", "base": "sea", "tier": 2,
			"conf": 1,
			"src": "en+da Wikipedia (1954 double-leaf bascule bridge by Kaj Gottlob, 35 m navigation width, 7 m " +
				"clearance), OSM cycleway way 1366539123 (253 m, bearing 131.6) and bascule ways; side-span " +
				"split, leaf length and width estimated | verified: da+en Wikipedia: 1954 double-leaf bascule " +
				"(dobbeltfaget klapbro) by Kaj Gottlob, 250 m long, 35 m navigation width, 7 m clearance; OSM " +
				"chain 107382796/176968797 (106 m) + movable way 706618534 (53 m) + 706618533 (95 m) = 254 m " +
				"at bearing 131.4, mid 55.67028,12.57868 matches the row within 10 m; the fixed sides are " +
				"really several short spans, not one 106/95 m span, and the leaf lengths are unpublished | " +
				"round 2: verify2: searched and not found - da Wikipedia re-read: 35 m navigation width, 7 m " +
				"clearance, no span lengths"},
		{"id": "br_copenhagen_lille_langebro", "cc": "DK", "name": "Lille Langebro", "wiki": "Lille Langebro",
			"aliases": ["little long bridge copenhagen"], "lat": 55.67114, "lon": 12.58005, "bearing": 116.6,
			"st": "girder", "spans": [33.0, 47.0, 45.0, 34.0], "width": 7.0, "clear": 6.0, "material": "steel",
			"base": "sea", "tier": 2, "conf": 1,
			"src": "en+da Wikipedia (2019 curved steel pedestrian/cycle double-swing bridge, 4 spans, 160-175 m, " +
				"7 m wide), OSM ways 706615520-2 and 303625173 (33+47+45+34 m, chord bearing 116.6, width 7); " +
				"curvature and swing spans not representable, clear estimated | verified: en Wikipedia (160 " +
				"m, 7 m wide, 5 spans, double-swing) and da Wikipedia (175 m, 4 spans, the two middle ones " +
				"swing sideways); OSM ways 706615522 (33 m) + 706615521 (47 m, movable) + 706615520 (45 m, " +
				"movable) + 303625173 (34 m) = 159 m, chord bearing 116.8, mid 55.67114,12.58005 confirmed; " +
				"two spans rotate and the plan is curved: the swing type has one moving span and no curve | " +
				"round 2: verify2: searched and not found - da Wikipedia re-read: 175 m, four spans, two " +
				"middle ones swing sideways; swing type has a single moving span"},
		{"id": "br_copenhagen_knippelsbro", "cc": "DK", "name": "Knippelsbro", "wiki": "Knippelsbro",
			"aliases": ["knippel bridge"], "lat": 55.67485, "lon": 12.58706, "bearing": 136.8, "st": "bascule",
			"spans": [38.5, 38.0, 38.5], "width": 27.4, "clear": 6.0, "material": "steel", "base": "sea", "tier": 2,
			"conf": 1,
			"src": "en+da Wikipedia (1937 bascule bridge by Kaj Gottlob, 115 m), OSM way 1694109 (bearing 136.8, " +
				"width tag 27.4), agrees with Wikipedia 55.6747,12.5872; span split and deck height estimated " +
				"| verified: da+en Wikipedia: 115 m long, 27.4 m wide (OSM width tag 27.4), 1937 bascule by " +
				"Kaj Gottlob, clearance under the closed bridge 5.4 m (da infobox); OSM way 1694109 (94 m, " +
				"bearing 136.8, mid 55.67485,12.58706) confirmed; leaf and side-span lengths not published in " +
				"sources found (Ingenioren 1938 article only) | round 2: verify2: searched and not found - da " +
				"Wikipedia re-read: 115 m, 27.4 m wide, clearance 5.4 m; no leaf or side-span lengths"},
		{"id": "br_copenhagen_inderhavnsbroen", "cc": "DK", "name": "Inderhavnsbroen", "wiki": "Inderhavnsbroen",
			"aliases": ["kissing bridge", "kyssebroen"], "lat": 55.67846, "lon": 12.59525, "bearing": 107.0,
			"st": "girder", "spans": [30.0, 60.0, 30.0, 30.0, 30.0], "width": 7.0, "clear": 5.0, "material": "steel",
			"base": "sea", "tier": 2, "conf": 1,
			"src": "en+da Wikipedia (180 m pedestrian/cycle bridge 2016 with retractable, folding sections), OSM " +
				"unnamed footway/cycleway ways 393218121/393218122 (bearing 107); retractable sections not " +
				"representable, span split, width and clear estimated | verified: da Wikipedia (180 m, " +
				"rullebro/retractable), competition sources (opening span 50 m, deck 7 m wide, horizontal " +
				"clearance 45 m); OSM ways 393218121/393218122 (137-139 m between 55.67856,12.59417 and " +
				"55.67833,12.59633, bearing 106.7/102.2) confirmed; the two sliding sections and the " +
				"mast/stay arrangement are not representable and the full span list is unpublished | round 2: " +
				"verify2: searched and not found - da Wikipedia re-read: 180 m only; no span list"},
		{"id": "br_copenhagen_cirkelbroen", "cc": "DK", "name": "Cirkelbroen", "wiki": "Circle Bridge",
			"aliases": ["circle bridge copenhagen", "five circles footbridge"], "lat": 55.67242, "lon": 12.5838,
			"bearing": 44.5, "st": "girder", "spans": [8.0, 8.0, 8.0, 8.0, 8.0], "width": 6.0, "clear": 3.0,
			"material": "steel", "base": "sea", "tier": 3, "conf": 1,
			"src": "en Wikipedia (40 m footbridge of five circular decks hung from masts, two decks swing), OSM " +
				"way 338137146 (40 m, bearing 44.5); mast-and-cable circles not representable, nearest girder " +
				"| verified: en Wikipedia: 40 m footbridge of five interconnected circular decks hung from " +
				"masts, two decks swing open; OSM way 338137146 (38 m, bearing 44.5, mid 55.67242,12.58380) " +
				"confirmed; circular decks with masts are not a girder | round 2: verify2: searched and not " +
				"found - not rechecked beyond round 1; circular decks and masts are not a girder"},
		{"id": "br_copenhagen_bryggebroen", "cc": "DK", "name": "Bryggebroen", "wiki": "Bryggebroen",
			"aliases": ["quay bridge copenhagen"], "lat": 55.66152, "lon": 12.56667, "bearing": 114.4, "st": "girder",
			"spans": [55.5, 79.0, 55.5], "width": 5.5, "clear": 5.0, "material": "steel", "base": "sea", "tier": 3,
			"conf": 1,
			"src": "en+da Wikipedia (2006 swing bridge for pedestrians and cyclists, 190 m, 5.5 m wide), OSM " +
				"ways 351687505/506 (79 m swing section, bearing 114.5) plus approach ways 419617574/580, " +
				"chain centre equals da Wikipedia 55.66139,12.56667; swing span not representable, side spans " +
				"from total, clear estimated | verified: en+da Wikipedia: 190 m swing bridge for pedestrians " +
				"and cyclists, 5.5 m wide, opened 2006; OSM movable ways 351687505/351687506 (79 m, bearing " +
				"114.5, mid 55.66134,12.56738) = the swing section; side spans only inferred from the 190 m " +
				"total; tried the new 'swing' type but the span list is not sourced | round 2: verify2: " +
				"searched and not found - da Wikipedia (short stub) re-read: no span list"},
		{"id": "br_riga_akmens_tilts", "cc": "LV", "name": "Akmens tilts", "wiki": "Stone Bridge, Riga",
			"aliases": ["stone bridge riga", "oktobra tilts"], "lat": 56.94462, "lon": 24.10129, "bearing": 48.1,
			"st": "girder", "spans": [50.6, 64.4, 75.1, 85.1, 75.1, 64.4, 50.6], "width": 33.5, "clear": 9.0,
			"material": "steel", "base": "water", "tier": 2, "conf": 2,
			"src": "lv Wikipedia (continuous 7-span steel plate girder 50.6+64.4+75.1+85.1+75.1+64.4+50.6 m, 503 " +
				"m with approaches, roadway 27.5 m plus footways), en Wikipedia 56.9445,24.1011, OSM way " +
				"4995172 bearing 48.1; deck height estimated | verified: lv Wikipedia (Akmens tilts (Riga)): " +
				"continuous seven-span steel beam 50.6+64.4+75.1+85.1+75.1+64.4+50.6 m, total 503.12 m with " +
				"approaches, 27.5 m carriageway plus two 3 m footways (33.5 m), eight 1.8-2.4 m deep plate " +
				"girders; OSM way 4995172 (520 m, bearing 48.1) crosses water from 6.9 to 495.5 m, centred " +
				"within 10 m of the row coordinate"},
		{"id": "br_riga_vansu_tilts", "cc": "LV", "name": "Vansu tilts", "wiki": "Vanšu Bridge",
			"aliases": ["vanšu tilts", "vanšu bridge", "shroud bridge"], "lat": 56.9512, "lon": 24.09588,
			"bearing": 70.3, "st": "stayed", "spans": [312.0, 283.0], "width": 28.4, "clear": 15.0, "tower": 109.0,
			"towers": [1], "pylon": "single", "material": "steel", "base": "water", "tier": 2, "conf": 1,
			"src": "en+lv Wikipedia (1981 single-pylon cable-stayed bridge in one plane, 595 m, stayed part 312 " +
				"m; reconstruction contract signed Jan 2026, works from 2027, so it still stands), OSM way " +
				"23692402 (665 m, bearing 70.3); span split, pylon height, width and clear estimated | " +
				"verified: lv+en Wikipedia: single-pylon cable-stayed 1981, longest span 312 m, total length " +
				"595 m (625 m with approaches), width 28.4 m (28), pylon height 109 m (infobox); en infobox " +
				"lists 2 spans; OSM way 23692402 (666 m, bearing 70.3) crosses water from 50.7 to 494.2 m; " +
				"whether the other 283 m is a second stayed span or a beam span is not stated; reconstruction " +
				"contract signed 16 Jan 2026 (works from 2027) so it still stands | round 2: verify2: " +
				"searched and not found - lv Wikipedia fetch returned a redirect stub; no second-span source " +
				"found"},
		{"id": "br_vilnius_zaliasis_tiltas", "cc": "LT", "name": "Green Bridge", "wiki": "Green Bridge (Vilnius)",
			"aliases": ["zaliasis tiltas", "žaliasis tiltas"], "lat": 54.69146, "lon": 25.27998, "bearing": 5.8,
			"st": "girder", "spans": [31.0, 41.0, 31.0], "width": 24.0, "clear": 8.0, "material": "concrete",
			"base": "water", "tier": 2, "conf": 1,
			"src": "lt+en Wikipedia (1952 bridge 102.9 m, 24 m wide, 15 m high), OSM Kalvarijų g. ways 168255991 " +
				"+ 530515767 (width 24, bearing 5.8) agree with Wikipedia 54.69139,25.27972; span layout, " +
				"type and deck height unknown, estimated; statues not modelled | verified: en+lt Wikipedia: " +
				"1952 bridge, 102.9 m long, 24 m wide, 15 m high (en); no span layout in en/lt Wikipedia or " +
				"search results; OSM Kalvariju g. ways 168255991 (51 m) + 530515767 (55 m), width 24, bearing " +
				"5.5-6.0 confirmed | round 2: verify2: searched and not found - lt Wikipedia articles fetched " +
				"(Green Bridge page is a redirect); no span layout found"},
		{"id": "br_vilnius_baltasis_tiltas", "cc": "LT", "name": "White Bridge", "wiki": "White Bridge (Vilnius)",
			"aliases": ["baltasis tiltas"], "lat": 54.69318, "lon": 25.27324, "bearing": 43.4, "st": "girder",
			"spans": [59.0, 59.0, 59.0, 59.0], "width": 6.0, "clear": 8.0, "material": "steel", "base": "water",
			"tier": 3, "conf": 1,
			"src": "lt+en Wikipedia (pedestrian bridge 1996, 240 m, 6 m wide, 11.4 m high), OSM way 4870120 (236 " +
				"m, bearing 43.4); structure type and spans not found, estimated | verified: lt Wikipedia: " +
				"pedestrian bridge opened 1996, 240 m long, 6 m wide, 11.4 m high, designed in St Petersburg; " +
				"no span layout found; OSM way 4870120 (237 m, bearing 43.4, mid 54.69318,25.27324) confirmed " +
				"| round 2: verify2: searched and not found - lt Wikipedia re-read: no span layout"},
		{"id": "br_vilnius_mindaugas_bridge", "cc": "LT", "name": "Mindaugas Bridge", "wiki": "Mindaugas Bridge",
			"aliases": ["karaliaus mindaugo tiltas", "mindaugo tiltas"], "lat": 54.689, "lon": 25.28826, "bearing": 8.8,
			"st": "girder", "spans": [26.0, 49.0, 26.0], "width": 19.7, "clear": 7.0, "material": "concrete",
			"base": "water", "tier": 3, "conf": 1,
			"src": "lt+en Wikipedia (2003 bridge, 101 m, 19.7 m wide, 3 lanes), OSM way 386060652 (102 m, width " +
				"19.7, bearing 8.8); span layout and deck height estimated | verified: lt+en Wikipedia: 2003 " +
				"bridge, 101 m long, 19.7 m wide, three traffic lanes; no span layout found; OSM way " +
				"386060652 (102 m, bearing 8.8, mid 54.68900,25.28826) confirmed | round 2: verify2: searched " +
				"and not found - lt Wikipedia article is a redirect; no span layout"},
		{"id": "br_vilnius_zvierynas_bridge", "cc": "LT", "name": "Zverynas Bridge", "wiki": "Žvėrynas Bridge",
			"aliases": ["žvėryno tiltas", "zveryno tiltas", "zverynas bridge"], "lat": 54.69047, "lon": 25.25885,
			"bearing": 93.1, "st": "truss", "spans": [34.4, 34.3, 34.4], "width": 11.35, "clear": 6.0, "rise": 7.0,
			"material": "steel", "base": "water", "tier": 3, "conf": 1,
			"src": "lt+en Wikipedia (1905-07 steel bridge on stone piers, 103.1 m, 11.35 m wide, 11 m high), OSM " +
				"way 4870067 (104 m, bearing 93.1) agrees with Wikipedia 54.69027,25.25889; steel truss/arch " +
				"form, spans and rise estimated | verified: lt+en Wikipedia: 1905-07 steel bridge on stone " +
				"piers, 103.1 m long, 11.35 m wide, 11 m high, en category 'Arch bridges in Lithuania'; the " +
				"steel superstructure form (arch or truss) and spans are not stated anywhere found; OSM way " +
				"4870067 (104 m, bearing 93.1, mid 54.69047,25.25885) confirmed | round 2: verify2: searched " +
				"and not found - lt Wikipedia Zveryno tiltas re-read: no span layout or structure form"},
		{"id": "br_vilnius_geleziniovilko_tiltas", "cc": "LT", "name": "Iron Wolf Bridge", "wiki": "Iron Wolf Bridge",
			"aliases": ["geležinio vilko tiltas", "gelezinio vilko tiltas"], "lat": 54.69529, "lon": 25.2639,
			"bearing": 178.0, "st": "girder", "spans": [65.0, 65.0, 65.0, 65.0], "width": 38.8, "clear": 10.0,
			"material": "concrete", "base": "water", "tier": 3, "conf": 1,
			"src": "lt+en Wikipedia (1979 reinforced-concrete bridge, 260 m, 38.8 m wide, 12 m high), OSM " +
				"Geležinio Vilko g. ways 4946802 + 4870109 (chain about 254 m, bearing 178) agree with " +
				"Wikipedia 54.69528,25.26389; spans estimated | verified: lt+en Wikipedia: 1979 reinforced- " +
				"concrete bridge, 260 m, 38.8 m wide, 12 m high; no span layout found; OSM Gelezinio Vilko g. " +
				"ways 4946802+4870109 chain (about 256 m, bearing 178) and cycle path 1274714415 (259 m, " +
				"bearing 178.0) confirmed | round 2: verify2: searched and not found - lt Wikipedia re-read: " +
				"no span layout"},
		{"id": "br_vilnius_valakampiu_tiltas", "cc": "LT", "name": "Valakampiai Bridge", "wiki": "Valakampiai Bridge",
			"aliases": ["valakampių tiltas", "valakupiai bridge"], "lat": 54.72594, "lon": 25.31138, "bearing": 44.3,
			"st": "girder", "spans": [55.0, 100.0, 46.6, 46.6, 46.6, 46.7], "width": 21.0, "clear": 14.0,
			"material": "concrete", "base": "water", "tier": 3, "conf": 1,
			"src": "lt+en Wikipedia (1972 prestressed concrete bridge 341.5 m, 21 m wide, 6 spans: 100 m over " +
				"the river, one on the left bank, four on the right), OSM O. Milašiaus g. + Kareivių g. ways " +
				"(124+213 m, bearing 44.3); order and sizes of the 5 shorter spans and deck height estimated " +
				"| verified: en+lt Wikipedia: 1972 prestressed ferroconcrete beams, 341.5 m, about 21 m wide, " +
				"six spans: 100 m over the river, one on the left bank, a four-span viaduct on the right " +
				"bank; the other five lengths and their order are not given (sum of the five = 241.5 m); OSM " +
				"O. Milasiaus g. 824495224 (214 m) + Kareiviu g. 5011306 (124 m) chain, bearing 44.3, footway " +
				"354661719 (338 m, mid 54.72588,25.31147) confirmed | round 2: verify2: searched and not " +
				"found - lt Wikipedia re-read: no lengths for the five shorter spans"},
		{"id": "br_riga_dienvidu_tilts", "cc": "LV", "name": "Dienvidu tilts", "wiki": "Southern Bridge",
			"aliases": ["southern bridge riga", "dienvidu bridge", "south bridge riga"], "lat": 56.9158, "lon": 24.1572,
			"bearing": 43.4, "st": "extradosed", "spans": [49.5, 77.0, 110.0, 110.0, 110.0, 110.0, 110.0, 77.0, 49.5],
			"width": 34.3, "clear": 11.5, "tower": 24.8, "towers": [2, 3, 4, 5, 6, 7], "material": "steel",
			"base": "water", "tier": 2, "conf": 2,
			"src": "BD&E article via bridgeweb.com/Latvian-link/2055 (9 spans: five of 110 m and one 77 m + one " +
				"49.5 m at each end = 803 m, six steel pylons on the piers, steel girders with a prestressed " +
				"concrete deck, stay cables mainly prestress the girder), lv Wikipedia (803 m, 7 'posmi' of " +
				"which the longest 110 m, 10 supports of which 6 carry pylons, width 34.28 m, pylon height " +
				"13.33 m over the road surface, clearance below 8.5 m), en Wikipedia (extradosed, 803 m, " +
				"34.28 m); OSM Dienvidu tilts ways 126047905/37732348 (801 m, bearing 43.4/223.4, mid " +
				"56.91575,24.15728) so centre and bearing re-measured; order of the 77 m and 49.5 m side " +
				"spans at each end assumed, deck height estimated from 8.5 m clearance + girder depth"},
	]
