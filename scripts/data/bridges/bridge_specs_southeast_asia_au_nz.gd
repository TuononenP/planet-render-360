class_name BridgeSpecsSoutheastAsiaAuNz
extends RefCounted

## Capital bridge rows for South-east Asia, Australia and New Zealand (see BridgeSpec for the schema). Figures are
## sourced per row in `src`; conf 1 rows are kept as data but not built
## (BridgeSpec.MIN_BUILT_CONF).

static func rows() -> Array:
	return [
		{"id": "br_singapore_cavenagh_bridge", "cc": "SG", "name": "Cavenagh Bridge", "wiki": "Cavenagh Bridge",
			"aliases": ["cavenagh bridge singapore"], "lat": 1.28657, "lon": 103.85235, "bearing": 150.4, "st": "susp",
			"spans": [9.15, 60.96, 9.14], "width": 9.45, "clear": 3.5, "tower": 10.0, "material": "steel",
			"base": "water", "tier": 2, "conf": 1,
			"src": "en Wikipedia (79.25 m total, 60.96 m main; Ordish-Lefeuvre stayed-suspension hybrid, article " +
				"calls it cable-stayed), OSM pedestrian way 62 m bearing 150.4; side-span split, deck width " +
				"(wiki says 9.45 m, doubtful) 4 m, pylon height and clear estimated; hybrid system not " +
				"represented | verified: Wikipedia and OSM relation tag both give width 9.45 m, main span " +
				"60.96 m, length 79.25 m; OSM way 534684103 62 m bearing 150.5 mid 1.28657,103.85235 confirms " +
				"centre/bearing; stays conf 1 (Ordish-Lefeuvre stayed-suspension hybrid, single 60.96 m span, " +
				"not representable) | round 2: round 2: nothing new; Ordish-Lefeuvre stayed-suspension hybrid " +
				"not representable"},
		{"id": "br_singapore_anderson_bridge", "cc": "SG", "name": "Anderson Bridge", "wiki": "Anderson Bridge (Singapore)",
			"aliases": ["anderson bridge singapore"], "lat": 1.2872, "lon": 103.85302, "bearing": 128.6, "st": "truss",
			"spans": [21.5, 27.0, 21.5], "width": 23.0, "clear": 4.5, "rise": 3.0, "material": "steel", "base": "water",
			"tier": 2, "conf": 1,
			"src": "en Wikipedia (70 m, 23 m wide, 1910, three-span steel), OSM way 'Fullerton Road' 70 m " +
				"bearing 128.6; span split, truss depth and clear guessed | verified: OSM ways 29377119 / " +
				"448084959 (70 m, bearing 128.8 / 309.0, mid 1.2873,103.8530) confirm centre/bearing; " +
				"Wikipedia 70 m x 23 m, 'three large girders' (Structurae calls it a through truss, Roots " +
				"says steel arches encased in concrete); no source gives the span split or the structure type " +
				"| round 2: round 2: Roots.sg (Singapore River Bridges): span 204 ft (61.2 m), two roadways " +
				"of 31.5 ft; sources disagree on type (Pratt truss girder / bowstring arch / three steel " +
				"arches) and Wikipedia gives 70 m x 23 m; no span split"},
		{"id": "br_singapore_elgin_bridge", "cc": "SG", "name": "Elgin Bridge", "wiki": "Elgin Bridge (Singapore)",
			"aliases": ["elgin bridge singapore"], "lat": 1.28907, "lon": 103.8493, "bearing": 32.5, "st": "arch_deck",
			"spans": [18.5, 29.0, 18.5], "width": 25.0, "clear": 4.5, "rise": 3.0, "material": "steel", "base": "water",
			"tier": 2, "conf": 1,
			"src": "en Wikipedia (1929, 25 m wide, 'arch bridge' but also described as box girder; length given " +
				"as 46 m), OSM way 'North Bridge Road' 66 m bearing 32.5; three-arch split and rise guessed | " +
				"verified: OSM ways 474832236 / 21998973 (66 m, bearing 212.7 = 32.7 reversed, mid " +
				"1.28904,103.84934) confirm centre/bearing; sources conflict on size (Wikipedia/Structurae 46 " +
				"m x 25 m, Roots ~140 ft = 42.7 m river span; Wikipedia calls it both arch and box girder, " +
				"Roots/NLB: three steel bowstring arches encased in concrete); span split unsourced | round " +
				"2: round 2: not searched beyond round 1 (type and sizes conflict)"},
		{"id": "br_singapore_jubilee_bridge", "cc": "SG", "name": "Jubilee Bridge", "wiki": "Jubilee Bridge, Singapore",
			"aliases": ["jubilee bridge singapore"], "lat": 1.28796, "lon": 103.85444, "bearing": 10.9,
			"st": "haunched", "spans": [59.0, 95.0, 59.0], "width": 6.0, "clear": 6.0, "material": "concrete",
			"base": "water", "tier": 3, "conf": 2, "mid_depth": 1.5, "pier_depth": 3.5,
			"src": "en Wikipedia (balanced cantilever pedestrian bridge, 95 m main span, 220 m, 6 m wide), OSM " +
				"way 212 m bearing 10.9; side spans = (220-95)/2 assumed, clear estimated | verified: " +
				"Wikipedia (main span 95 m, 220 m, 6 m wide; cites Structurae/Footbridge 2017 paper), " +
				"Structurae data via search snippet (59-95-59 m, girder 1.5-3.5 m deep), Arup project page " +
				"(deck 1.5 m at midspan, 3.5 m over the columns), trendsideas (220 m, 6 m wide, precast post- " +
				"tensioned deck on two blade pylons deepening over the pylons); OSM Jubilee Bridge ways chain " +
				"1.28699,103.85442 to 1.28888,103.85476, 210 m, straight part bearing 10.5-11.1; " +
				"centre/bearing unchanged; clear (6 m) still an estimate"},
		{"id": "br_singapore_esplanade_bridge", "cc": "SG", "name": "Esplanade Bridge", "wiki": "Esplanade Bridge",
			"aliases": ["esplanade bridge singapore"], "lat": 1.28796, "lon": 103.85418, "bearing": 11.4,
			"st": "arch_deck", "spans": [37.3, 37.3, 37.3, 37.3, 37.3, 37.3, 37.3], "width": 46.0, "clear": 4.0,
			"rise": 2.0, "material": "concrete", "base": "sea", "tier": 3, "conf": 1,
			"src": "en Wikipedia (7 spans, 261 m; width 46 m in infobox but 70 m in text; low concrete arches), " +
				"OSM ways 292 m bearing 11.4; equal spans, rise, clear guessed | verified: OSM Esplanade " +
				"Drive ways 1313321640+35037536+763010995 chain 293 m, bearing 190.9 (=10.9), centre " +
				"1.28796,103.85418 confirm centre/bearing; Wikipedia 261 m (infobox 280 m, width 46 m infobox " +
				"/ 70 m text, 7 spans), Structurae search snippet 260 m with 7 arches; equal spans not stated " +
				"by a source | round 2: round 2: not searched beyond round 1; equal spans still not stated by " +
				"a source"},
		{"id": "br_singapore_helix_bridge", "cc": "SG", "name": "Helix Bridge", "wiki": "Helix Bridge",
			"aliases": ["double helix bridge", "the helix singapore"], "lat": 1.2876, "lon": 103.86052, "bearing": 1.3,
			"st": "girder", "spans": [56.0, 56.0, 56.0, 56.0, 56.0], "width": 6.5, "clear": 6.0, "material": "steel",
			"base": "sea", "tier": 2, "conf": 1,
			"src": "en Wikipedia (280 m pedestrian bridge, stainless-steel double helix); OSM 292 m bearing 1.3; " +
				"helical tube structure cannot be represented, spans/width/clear guessed | verified: " +
				"Structurae lists it as a stainless-steel double-helix pedestrian bridge, OSM 'The Helix' way " +
				"164881537 186 m bearing 175.7; helical tube structure still not representable | round 2: " +
				"round 2: nothing new; double-helix tube not representable"},
		{"id": "br_singapore_merdeka_bridge", "cc": "SG", "name": "Merdeka Bridge", "wiki": "Merdeka Bridge, Singapore",
			"aliases": ["merdeka bridge singapore"], "lat": 1.3042, "lon": 103.86865, "bearing": 57.5, "st": "girder",
			"spans": [24.384, 24.384, 24.384, 24.384, 24.384, 24.384, 24.384, 24.384, 24.384, 24.384, 24.384, 24.384, 24.384, 24.384, 24.384, 24.384, 24.384, 24.384, 24.384, 24.384, 24.384, 24.384, 24.384, 24.384, 24.384],
			"width": 19.8, "clear": 6.0, "material": "concrete", "base": "sea", "tier": 3, "conf": 2,
			"src": "en Wikipedia (prestressed beam, 80 ft main span, 2000 ft total, 65 ft wide, 1956); equal " +
				"spans assumed; coordinate and bearing unverified (Wikipedia has no exact coordinate) | " +
				"verified: OSM footways 364594971 / 392795670 (565-567 m) and Nicoll Highway 786122938 run " +
				"bearing 237.5 = 57.5 reversed, mid 1.30420,103.86865 (old bearing 90 was wrong); " +
				"Roots.sg/SG101: 610 m, completed 1956, pre-stressed; Wikipedia main span 80 ft, 65 ft wide; " +
				"equal 24.384 m spans still an assumption (OSM bridge only 565 m) | round 2: round 2: NLB " +
				"Infopedia SIP_493_2005-01-19 and a contemporary contractor advertisement: 25 spans of 80 ft " +
				"each = 2000 ft (609.6 m; heritage board 610 m) so the equal 24.384 m spans are sourced; " +
				"width 65 ft = 19.8 m (SG Mandarin terms database, en Wikipedia); girder type from " +
				"Wikipedia/Roots (pre-stressed beams); centre/bearing from round 1 OSM measurement (footways " +
				"364594971/392795670, bearing 237.5 = 57.5 reversed, mid 1.30420,103.86865); OSM bridge " +
				"section is 565 m of the 610 m so the centre may sit up to ~20 m off. Deck height 6 m " +
				"estimated"},
		{"id": "br_bangkok_memorial_bridge", "cc": "TH", "name": "Memorial Bridge", "wiki": "Memorial Bridge (Bangkok)",

			"aliases": ["phra phutthayotfa bridge", "saphan phut", "สะพานพุทธ", "สะพานพุทธยอดฟ้า", "memorial bridge bangkok"],
			"lat": 13.73945, "lon": 100.49773, "bearing": 18.8, "st": "truss", "spans": [78.0, 78.0, 78.0],
			"width": 16.68, "clear": 8.7, "rise": 7.0, "material": "steel", "base": "water", "tier": 2, "conf": 2,
			"src": "en Wikipedia (678 m incl approaches, main span 78 m, 1932, 7.3 m clearance), coordinate from " +
				"Wikipedia/OSM, bearing ~100 deg estimated from the N-S river (OSM way 25706395 runs 18.6 deg " +
				"along the approach, not across the river); side spans and width guessed; lift/bascule " +
				"geometry approximated | verified: Wikipedia: main span 78 m, 678 m incl. approaches; side " +
				"spans/width not sourced; OSM footway 754202320 (321 m, bearing 18.7) is an approach, not " +
				"across the river; bascule geometry approximated | round 2: round 2: JICA 2009 DRR inspection " +
				"sheet (openjicareport.jica.go.jp 11988862_02.pdf Ap-182): Memorial Bridge 3-span steel " +
				"truss, 78+78+78 = 234 m, carriageway width 10.00 m, 1932; th wiki (สะพานพระพุทธยอดฟ้า): " +
				"steel bridge 229.76 m long, 16.68 m wide, soffit 7.50 m above water (deck ~8.7), carriageway " +
				"10 m; en wiki: double-leaf bascule mechanism now unused, so drawn as fixed truss; OSM way " +
				"25706395 (300 m, bearing 18.8) crosses the Chao Phraya (river node 13.73931,100.49766), " +
				"centre placed on the river crossing; the old 100 deg bearing was wrong (river bends here, " +
				"bridge runs N-S). Truss height estimated"},
		{"id": "br_bangkok_pinklao_bridge", "cc": "TH", "name": "Phra Pinklao Bridge", "wiki": "Phra Pin-klao Bridge",
			"aliases": ["pinklao bridge", "saphan pinklao", "สะพานพระปิ่นเกล้า"], "lat": 13.76188, "lon": 100.49108,
			"bearing": 142.5, "st": "girder", "spans": [83.0, 110.0, 83.0], "width": 32.2, "clear": 13.5,
			"material": "concrete", "base": "water", "tier": 3, "conf": 2,
			"src": "en Wikipedia (110 m main span, 658 m total, 11.5 m clearance), OSM way 616 m runs 142.7 deg " +
				"incl. approaches, bearing 135 estimated; other span lengths and width guessed | verified: " +
				"Wikipedia: main span 110 m, 658 m; no independent source for the other spans or width found " +
				"(th wiki redirect only) | round 2: round 2: JICA 2009 DRR inspection sheet " +
				"(openjicareport.jica.go.jp 11988862_02.pdf Ap-174): Pinklao Bridge 3-span continuous PC box " +
				"girder 83+110+83 = 276 m, width 32.21 m, 1973; wiki 110 m main span and 11.5 m clearance " +
				"(deck = clearance + ~2 m box depth); OSM ways 25715010/25715011 (614 m incl approaches, " +
				"bearing 142.5 / 322.7) cross the river at 13.7619,100.4911 (waterway nodes " +
				"13.76190,100.49108); the first pass had 5 spans, 658 m is the total with approaches"},
		{"id": "br_bangkok_taksin_bridge", "cc": "TH", "name": "Taksin Bridge", "wiki": "Taksin Bridge",
			"aliases": ["sathon bridge", "saphan taksin", "สะพานตากสิน", "king taksin bridge"], "lat": 13.71942,
			"lon": 100.5122, "bearing": 103.8, "st": "girder", "spans": [66.0, 92.0, 66.0], "width": 26.0,
			"clear": 14.0, "material": "concrete", "base": "water", "tier": 2, "conf": 2,
			"src": "en Wikipedia (92 m main span, 1791 m total, 12 m clearance, 1982), OSM Krung Thonburi Rd " +
				"ways 596 m bearing ~104-105; span pattern, deck width incl. the BTS gap guessed | verified: " +
				"Wikipedia: main span 92 m, 1791 m, 6 lanes + Skytrain; no independent span list or width " +
				"found | round 2: round 2: JICA 2009 DRR inspection sheet (openjicareport.jica.go.jp " +
				"11988862_02.pdf Ap-206): Taksin Bridge 3-span continuous PC box girder 66+92+66 = 224 m, " +
				"width 12.85 x 2 (twin decks), V-shaped piers, 1982; wiki 92 m main span, 12 m clearance " +
				"(deck ~ +2 m); width = 2 x 12.85 (BTS viaduct in the gap is not modelled); OSM ways " +
				"156261465 / 139497771 (bearing 103.8 / 283.9) with Chao Phraya centreline at lon " +
				"100.5121-100.5122 (the old centre 100.511 lay ~120 m west of the river, on the Thonburi " +
				"approach); 224 m deck = 0.00207 deg lon between 100.5111 and 100.5132"},
		{"id": "br_bangkok_rama_iii_bridge", "cc": "TH", "name": "Rama III Bridge", "wiki": "Rama III Bridge",
			"aliases": ["new krungthep bridge", "สะพานพระราม 3", "saphan phra ram 3"], "lat": 13.70112,
			"lon": 100.49237, "bearing": 121.8, "st": "haunched", "spans": [125.0, 226.0, 125.0], "width": 23.0,
			"clear": 33.0, "material": "concrete", "base": "water", "tier": 3, "conf": 2, "mid_depth": 5.0,
			"pier_depth": 14.0,
			"src": "en Wikipedia (cantilever, 226 m main span, 1864 m, 23 m wide, 32 m clearance), OSM Rama III " +
				"Rd bearing 122; variable-depth cantilever not representable, side spans guessed | verified: " +
				"th Wikipedia infobox (main span 226 m, side spans 125 m, 6 lanes 23 m wide, 34 m above mean " +
				"sea level, box girder), en Wikipedia (cantilever, 226 m main span, 23 m wide, 32 m clearance " +
				"below); OSM Rama III Rd ways 154773964/154773961 (bearing 122.2 / 304.7 = 124.7 reversed), " +
				"wayseg of 476 m at the Wikipedia coordinate gives centre 13.70114,100.49237 bearing 121.6; " +
				"clear 33 = mean of 32/34; depths estimated"},
		{"id": "br_bangkok_krung_thon_bridge", "cc": "TH", "name": "Krung Thon Bridge", "wiki": "Krung Thon Bridge",
			"aliases": ["sang hi bridge", "สะพานกรุงธน"], "lat": 13.78107, "lon": 100.50244, "bearing": 294.6,
			"st": "truss", "spans": [58.0, 58.0, 64.0, 64.0, 58.0, 58.0], "width": 17.0, "clear": 8.5, "rise": 6.5,
			"material": "steel", "base": "water", "tier": 3, "conf": 2,
			"src": "en Wikipedia (6 spans, steel superstructure on concrete piers, 64 m main span, 648.9 m, 7.5 " +
				"m clearance), coordinate Wikipedia; bearing, width, truss form estimated | verified: th " +
				"Wikipedia: steel superstructure of 6 spans, 366.2 m (64 m and 58 m spans; 3x64+3x58=366), " +
				"7.5 m clearance, 4 lanes + 2x2.5 m footpaths, total 648.9 m; order of the 64/58 m spans not " +
				"sourced; OSM footway 1484304793 bearing 294.9 | round 2: round 2: Thai DOH bridge page " +
				"(web.archive.org roadmaintenance.thaigov.net/bridge_eng_krungthon.html): 6 steel spans " +
				"58-58-64-64-58-58, clear height 7.50 m; JICA 2009 DRR inspection sheet " +
				"(openjicareport.jica.go.jp 11988862_02.pdf Ap-145): 6-span steel truss, total 360 m, span " +
				"58+58+64+64+58+58, width 12.00 m, girder height ~8.5 m; th wiki: 4 lanes + 2x2.5 m footpaths " +
				"so width 12+5=17; deck = clearance 7.5 + floor ~1; OSM way 28510028 (ถนนราชวิถี, 424 m incl " +
				"ends, mid 13.78107,100.50244 sits on the Chao Phraya centreline) bearing 294.6 (old 280 was " +
				"15 deg off)"},
		{"id": "br_bangkok_rama_vii_bridge", "cc": "TH", "name": "Rama VII Bridge", "wiki": "Rama VII Bridge",
			"aliases": ["สะพานพระราม 7", "saphan phra ram 7"], "lat": 13.81415, "lon": 100.51393, "bearing": 36.5,
			"st": "girder", "spans": [85.0, 120.0, 85.0], "width": 29.1, "clear": 8.9, "material": "concrete",
			"base": "water", "tier": 3, "conf": 2,
			"src": "en Wikipedia (120 m main span, 933 m, 6 lanes, 8.9 m clearance); structure type not stated " +
				"(may be cable-stayed), span pattern, width and bearing estimated | verified: th Wikipedia " +
				"(continuous prestressed concrete box girder, 3 river spans 85+120+85 = 290 m, 29.10 m wide = " +
				"2x14.55, 8.90 m above water, total 933.19 m) and en Wikipedia (120 m main span, 933.19 m, " +
				"8.9 m, 6 lanes); OSM Wong Sawang Rd ways 852446176 (bearing 36.3) / 140391504 (216.3), " +
				"wayseg 290 m centred on the Wikipedia coordinate gives 13.81415,100.51393 bearing 36.5 (old " +
				"bearing 80 wrong, centre moved ~65 m)"},
		{"id": "br_bangkok_rama_vi_bridge", "cc": "TH", "name": "Rama VI Bridge", "wiki": "Rama VI Bridge",
			"aliases": ["สะพานพระราม 6", "saphan phra ram 6"], "lat": 13.81347, "lon": 100.51549, "bearing": 47.5,
			"st": "truss", "spans": [77.0, 84.0, 120.0, 84.0, 77.0], "width": 10.0, "clear": 10.0, "rise": 14.0,
			"material": "steel", "base": "water", "tier": 3, "conf": 1,
			"src": "en Wikipedia (5-span through truss, 77+83+120+..., 441.44 m, 1927; last two spans assumed " +
				"mirror of the first two), coordinate Wikipedia; bearing, width, clear, truss height " +
				"estimated | verified: en Wikipedia: 5 through-truss spans 77+83+120+83+77 = 440 m, 441.44 m, " +
				"railway only since 1992; OSM railway way 23958080 (Southern Line 1927, bearing 227.5 = 47.5 " +
				"reversed) segment of 441 m at the Wikipedia coordinate gives centre 13.81347,100.51549 (old " +
				"bearing 80 wrong); no width or truss height source | round 2: round 2: th wiki (สะพานพระราม " +
				"6): spans approx 77, 84, 120, 84, 77 m (442.08 m), 10 m wide, 10 m above water; built as a " +
				"cantilever truss (variable depth) which the truss type cannot draw; no truss-height source"},
		{"id": "br_bangkok_bhumibol_bridge", "cc": "TH", "name": "Bhumibol Bridge", "wiki": "Bhumibol Bridge",
			"aliases": ["industrial ring road bridge", "สะพานภูมิพล", "mega bridge bangkok"], "lat": 13.66528,
			"lon": 100.53944, "bearing": 40.0, "st": "stayed", "spans": [188.0, 326.0, 188.0], "width": 30.0,
			"clear": 45.0, "tower": 173.0, "material": "steel", "base": "water", "tier": 2, "conf": 1,
			"src": "en Wikipedia (two cable-stayed crossings, main spans 326 and 398 m, 702 m and 582 m, diamond " +
				"pylons; infobox height 50 m inconsistent), modelled the 398 m / 702 m crossing; side spans, " +
				"pylon height, clear, width, bearing guessed | verified: Wikipedia/Structurae search snippet: " +
				"Bhumibol 1 has 326 m main span, 702 m total and 173 m pylon; Bhumibol 2 has the 398 m span " +
				"and 582 m total (the first pass had paired 398 m with 702 m); side spans (702-326)/2 are a " +
				"remainder, pylon datum unknown; OSM not remeasured | round 2: round 2: JICA 2009 DRR sheets " +
				"(openjicareport.jica.go.jp 11988862_02.pdf Ap-245/Ap-260): Industrial Ring Road North " +
				"(=Bhumibol 1) 50.6+74.5+326+74.5+50.6 = 578.3 m; South (=Bhumibol 2) 68.6+83.5+398+83.5+68.6 " +
				"= 702.3 m, both composite I-girder cable-stayed, width 35.9-55.2 m (varies); this confirms " +
				"the first pass pairing 398 m with 702 m (round 1 note was wrong). OSM relations: Bhumibol 1 " +
				"at 13.66656,100.53810, Bhumibol 2 at 13.65767,100.54004, neither near the row coordinate " +
				"13.66528,100.53944 (Wikipedia point between them). Tower height (Wikipedia 173 m vs infobox " +
				"50 m) and which pylon datum not sourced; deck width range too wide; not re-measured"},
		{"id": "br_hanoi_long_bien_bridge", "cc": "VN", "name": "Long Bien Bridge", "wiki": "Long Biên Bridge",
			"aliases": ["cầu long biên", "cau long bien", "paul doumer bridge"], "lat": 21.04333, "lon": 105.85889,
			"bearing": 100.0, "st": "truss",
			"spans": [88.5, 88.5, 88.5, 88.5, 88.5, 88.5, 88.5, 88.5, 88.5, 88.5, 88.5, 88.5, 88.5, 88.5, 88.5, 88.5, 88.5, 88.5, 88.5],
			"width": 13.5, "clear": 14.0, "rise": 9.0, "material": "steel", "base": "water", "tier": 1, "conf": 1,
			"src": "en+vi Wikipedia (19 steel spans on 20 piers, 1682 m river part of 2290 m, 13.5 m wide, " +
				"rebuilt in parts after 1972); individual spans, clear, truss depth and bearing estimated; " +
				"rail in centre and two lanes, cantilever trusses | verified: vi Wikipedia: 2290 m over the " +
				"river, 19 steel spans on 20 piers, 13.5 m wide; en: 19 spans; individual span lengths (not " +
				"equal: rebuilt after 1972 bombing) not found | round 2: round 2: no span table found for the " +
				"post-1972 rebuilt spans (vi/en Wikipedia only give 19 spans on 20 piers); not re-searched " +
				"further"},
		{"id": "br_hanoi_chuong_duong_bridge", "cc": "VN", "name": "Chuong Duong Bridge", "wiki": "Chương Dương Bridge",
			"aliases": ["cầu chương dương", "cau chuong duong"], "lat": 21.03802, "lon": 105.86125, "bearing": 100.0,
			"st": "girder", "spans": [89.28, 89.28, 89.28, 89.28, 89.28, 89.28, 89.28, 89.28, 89.28, 89.28, 89.28],
			"width": 17.4, "clear": 16.0, "material": "steel", "base": "water", "tier": 2, "conf": 1,
			"src": "en+vi Wikipedia (1211-1213 m, width 7.4 + 2x5 m, steel/concrete girders, 1985); span count, " +
				"clear and bearing estimated | verified: vi Wikipedia: 1211 m, 21 main spans = 11 steel spans " +
				"(triangulated 89.28 m girders) + 10 concrete spans (7 Hanoi side, 3 Long Bien side), 7.4 + " +
				"2x5 m wide; modelled the 11 steel spans only; structure type (deck vs through truss) and OSM " +
				"axis not verified | round 2: round 2: only the vi Wikipedia figures (11 steel x 89.28 m + 10 " +
				"concrete spans; 7.4 + 2x5 m wide) exist; concrete span lengths and structure type not found"},
		{"id": "br_hanoi_thang_long_bridge", "cc": "VN", "name": "Thang Long Bridge", "wiki": "Thăng Long Bridge",
			"aliases": ["cầu thăng long", "cau thang long", "vietnam-soviet friendship bridge"], "lat": 21.09981,
			"lon": 105.78666, "bearing": 4.0, "st": "truss",
			"spans": [112.0, 112.0, 112.0, 112.0, 112.0, 112.0, 112.0, 112.0, 112.0, 112.0, 112.0, 112.0, 112.0, 112.0, 112.0],
			"width": 19.5, "clear": 25.0, "rise": 2.0, "material": "steel", "base": "water", "tier": 2, "conf": 2,
			"lower": 14.1,
			"src": "vi+en Wikipedia (1688 m river part = 15 steel spans of 112 m in five 3-span continuous " +
				"trusses, two levels with rail below, road 21 m); road rides on top of the truss and rail " +
				"deck dominates, so the through-truss model is wrong; bearing and clear estimated | verified: " +
				"vi + en Wikipedia: river part 1688 m = 15 continuous steel truss spans of 112 m in 5 units " +
				"of 3, road deck 19.5 m wide (16.5 m carriageway + 2x1.5 m footways), rail deck below the " +
				"road, 14.10 m between upper and lower chord axes; OSM rail bridge way 45767098 (Bac Hong - " +
				"Van Dien line, 1763 m, bearing 4.0, mid 21.09981,105.78666) and road trunk ways bearing " +
				"184.1 / 4.0 (old centre ~270 m south); the road rides on the top chord so rise is only a " +
				"parapet (2 m); clear 25 m above water is an estimate (navigation level +11.10 m)"},
		{"id": "br_hanoi_nhat_tan_bridge", "cc": "VN", "name": "Nhat Tan Bridge", "wiki": "Nhật Tân Bridge",
			"aliases": ["cầu nhật tân", "cau nhat tan", "vietnam-japan friendship bridge"], "lat": 21.09278,
			"lon": 105.8208, "bearing": 23.8, "st": "stayed", "spans": [150.0, 300.0, 300.0, 300.0, 300.0, 150.0],
			"width": 33.2, "clear": 22.0, "tower": 111.0, "towers": [1, 2, 3, 4, 5], "material": "steel",
			"base": "water", "tier": 1, "conf": 2,
			"src": "en+vi Wikipedia (5 pylons, 6 spans 150+4x300+150 per span list, 33.2-33.8 m wide, opened " +
				"2015), JSCE Tanaka award doc (pylon max 111 m); coordinates agree within 140 m but bearing " +
				"unverified (estimated), clear estimated; pylon height measured from pier cap, treated as " +
				"above water | verified: JSCE Tanaka-award paper (six-span continuous composite cable-stayed " +
				"bridge with five A-shaped RC pylons, 1500 m, central span 300 m, max pylon 111 m), en " +
				"Wikipedia/vi Wikipedia span list 150+4x300+150 and width 33.2-33.8 m, Hanoi Times 33.2 m; " +
				"Wikidata coordinate 21.092811,105.820706; OSM Cau Nhat Tan ways 251794091/251794092, 1500 m " +
				"chord at the Wikidata point gives centre 21.09278,105.8208 bearing 23.8 (old 10.0 was " +
				"wrong); pylon height 111 m is not tied to a datum and deck clear 22 m is an estimate"},
		{"id": "br_hanoi_vinh_tuy_bridge", "cc": "VN", "name": "Vinh Tuy Bridge", "wiki": "Vĩnh Tuy Bridge",
			"aliases": ["cầu vĩnh tuy", "cau vinh tuy"], "lat": 21.00443, "lon": 105.87622, "bearing": 55.0,
			"st": "girder", "spans": [80.0, 135.0, 135.0, 135.0, 135.0, 135.0, 135.0, 135.0, 135.0, 135.0, 135.0, 80.0],
			"width": 38.5, "clear": 18.0, "material": "concrete", "base": "water", "tier": 2, "conf": 1,
			"src": "en+vi Wikipedia (continuous prestressed box girder, 135 m record cantilever span, 3778 m " +
				"incl approaches, 38.5 m wide, twin bridge since 2023); river-part span pattern, clear and " +
				"bearing guessed | verified: vi Wikipedia: 3778 m, 38.5 m wide, main section 990 m, record " +
				"135 m cantilever span; Vinaconex (phase 2): 8 major cantilever spans totalling 955 m, " +
				"longest 135 m; phase 1 span list not found | round 2: round 2: VnExpress (via search): stage " +
				"1 deck 19.25 m wide (twin since stage 2, so 38.5 m for both), PC box girder continuous; " +
				"stage 2 = 53 spans (44 Super-T, 3 cantilever, 6 hollow-slab); stage 1 span list not found"},
		{"id": "br_hanoi_thanh_tri_bridge", "cc": "VN", "name": "Thanh Tri Bridge", "wiki": "Thanh Trì Bridge",
			"aliases": ["cầu thanh trì", "cau thanh tri"], "lat": 20.99414, "lon": 105.90168, "bearing": 40.0,
			"st": "girder",
			"spans": [128.5, 128.5, 128.5, 128.5, 128.5, 128.5, 128.5, 128.5, 128.5, 128.5, 128.5, 128.5, 128.5, 128.5, 128.5, 128.5, 128.5, 128.5, 128.5, 128.5, 128.5, 128.5, 128.5, 128.5],
			"width": 33.1, "clear": 30.0, "material": "concrete", "base": "water", "tier": 2, "conf": 1,
			"src": "en+vi Wikipedia (prestressed box girder cantilever, 3084 m main bridge, 33.1 m wide, height " +
				"30 m); equal spans, clear and bearing guessed | verified: en Wikipedia: 3084 m main bridge " +
				"as 33 spans of 93.5 m; vi Wikipedia: 3084 m, 33.1 m wide, 130 m record cantilever (Vinh Tuy " +
				"article) - the two disagree; not verified | round 2: round 2: vi Wikipedia (Cầu Thanh Trì): " +
				"main bridge 3084 m, 33.1 m wide, 6 lanes, no span list; VnExpress (via search): cantilever " +
				"span 130 m; contradicts en 33 x 93.5 m; web search found no span plan"},
		{"id": "br_phnom_penh_monivong_bridge", "cc": "KH", "name": "Monivong Bridge", "wiki": "Monivong Bridge",
			"aliases": ["preah monivong bridge", "ស្ពានព្រះមុនីវង្ស"], "lat": 11.53114, "lon": 104.93301,
			"bearing": 67.8, "st": "girder", "spans": [75.0, 118.0, 75.0], "width": 28.0, "clear": 12.0,
			"material": "concrete", "base": "water", "tier": 3, "conf": 1,
			"src": "en Wikipedia (269.5 m over the Bassac, 2 x 14 m wide, coordinate Wikipedia); equal spans, " +
				"clear and bearing estimated | verified: en Wikipedia: 269.5 m, 2 x 14 m wide; no independent " +
				"span list found | round 2: round 2: en Wikipedia List of bridges in Cambodia: Monivong " +
				"Bridge prestressed box girder, twin bridges, 75+118+75 = 269 m (118 m main span); OSM ways " +
				"171993033 / 371629160 (274-275 m, bearing 67.8 / 248.0) give the twin carriageways, centre " +
				"11.53114,104.93301 (old bearing 95 was 27 deg off). The two decks are ~44 m apart centre to " +
				"centre (old 1960s bridge + 2009 twin?) so a single 28 m deck would be wrong; width, deck " +
				"height, box depth unsourced"},
		{"id": "br_phnom_penh_chroy_changvar_bridge", "cc": "KH", "name": "Chroy Changvar Bridge", "wiki": "Chroy Changvar Bridge",

			"aliases": ["japanese bridge phnom penh", "kizuna bridge phnom penh", "cambodian-japanese friendship bridge"],
			"lat": 11.5815, "lon": 104.9318, "bearing": 85.0, "st": "girder",
			"spans": [59.1, 59.1, 59.1, 59.1, 59.1, 59.1, 59.1, 59.1, 59.1, 59.1, 59.1, 59.1], "width": 18.0,
			"clear": 10.0, "material": "steel", "base": "water", "tier": 3, "conf": 1,
			"src": "en Wikipedia (709 m over the Tonle Sap, built 1963 with Japanese aid, reopened 1994; no " +
				"coordinates given); position, span pattern, width and bearing estimated from the city map | " +
				"verified: en Wikipedia: 709 m, no spans/width/coordinate; no independent source found | " +
				"round 2: round 2: en Wikipedia List of bridges in Cambodia: Chroy Changvar I (1966, rebuilt " +
				"1995) is a steel box girder with main span 65+135+65 and 711 m total, Chroy Changvar II " +
				"(2014) prestressed box girder with 135 m spans (x3), coordinates 11 35 14.2N 104 55 18.5E; " +
				"the first-pass 12 x 59.1 m pattern contradicts this (the 135 m spans dominate); two parallel " +
				"bridges, widths and approach spans not found, OSM not measured"},
		{"id": "br_manila_jones_bridge", "cc": "PH", "name": "Jones Bridge", "wiki": "Jones Bridge",
			"aliases": ["william a. jones memorial bridge", "puente de jones"], "lat": 14.59583, "lon": 120.97733,
			"bearing": 150.5, "st": "masonry", "spans": [35.0, 45.0, 35.0], "width": 16.7, "clear": 9.0, "rise": 3.5,
			"material": "concrete", "base": "water", "tier": 2, "conf": 1,
			"src": "en Wikipedia (three arches, 115 m, 16.7 m wide, 7.5 m clearance below), OSM footway ways 141 " +
				"m bearing 150.5; arch split, rise and clear guessed; concrete arched girder | verified: en " +
				"Wikipedia: three spans, 16.70 m wide, 1945 girder bridge replaced the 1919 arches (mainspan " +
				"field '300m' looks like feet); span split not sourced | round 2: round 2: en Wikipedia: 3 " +
				"spans, 115 m, 16.70 m wide, 7.5 m clearance at mean tide (JICA MMUTIS 1999); span split not " +
				"found; DPWH detailed bridge inventory (dpwh.gov.ph/dpwh/gis/dbi) returns HTTP 403, so no " +
				"span table; not raised"},
		{"id": "br_manila_quezon_bridge", "cc": "PH", "name": "Quezon Bridge", "wiki": "Quezon Bridge",
			"aliases": ["quezon bridge manila"], "lat": 14.5955, "lon": 120.98208, "bearing": 25.0, "st": "girder",
			"spans": [66.0, 73.0, 74.0, 73.0, 66.0], "width": 22.5, "clear": 8.0, "material": "concrete",
			"base": "water", "tier": 3, "conf": 1,
			"src": "en Wikipedia (arch/prestressed girder, 447 m incl approaches, 22.5 m, 1939), OSM Quezon Blvd " +
				"352 m; spans, clear and bearing (OSM axis is the boulevard) guessed | verified: en Wikipedia " +
				"infobox: 8 spans (the first pass used 5), 22.5 m wide | round 2: round 2: en Wikipedia: 8 " +
				"spans, 447 m (DPWH), 22.5 m wide; arch+PSC girder; span lengths not found; DPWH detailed " +
				"bridge inventory (dpwh.gov.ph/dpwh/gis/dbi) returns HTTP 403, so no span table; not raised"},
		{"id": "br_manila_macarthur_bridge", "cc": "PH", "name": "MacArthur Bridge", "wiki": "MacArthur Bridge (Manila)",
			"aliases": ["macarthur bridge manila", "santa cruz bridge"], "lat": 14.59681, "lon": 120.98042,
			"bearing": 10.0, "st": "girder", "spans": [29.0, 29.0, 29.0, 29.0], "width": 17.85, "clear": 7.5,
			"material": "concrete", "base": "water", "tier": 3, "conf": 1,
			"src": "en Wikipedia (reinforced-concrete beam bridge, 116 m, 17.85 m wide), OSM Padre " +
				"Burgos/MacArthur ways bearing 9.9; equal spans and clear guessed | verified: en Wikipedia " +
				"infobox: 3 spans (the first pass used 4), 17.85 m wide | round 2: round 2: en Wikipedia: 3 " +
				"spans, 116 m, 17.85 m wide; equal spans not stated; DPWH detailed bridge inventory " +
				"(dpwh.gov.ph/dpwh/gis/dbi) returns HTTP 403, so no span table; not raised"},
		{"id": "br_manila_ayala_bridge", "cc": "PH", "name": "Ayala Bridge", "wiki": "Ayala Bridge",
			"aliases": ["puente de ayala", "ayala bridge manila"], "lat": 14.59128, "lon": 120.98642, "bearing": 15.0,
			"st": "truss", "spans": [40.0, 62.0, 40.0], "width": 23.5, "clear": 8.5, "rise": 6.0, "material": "steel",
			"base": "water", "tier": 3, "conf": 1,
			"src": "en Wikipedia (steel truss, 142 m, 23.5 m wide); span split, truss height, clear, bearing " +
				"guessed | verified: en Wikipedia infobox: 2 spans (the first pass used 3), 23.5 m wide, " +
				"steel truss | round 2: round 2: en Wikipedia: 2 spans, 142 m, 23.5 m wide, steel truss; " +
				"spans likely [71,71] but not stated; DPWH detailed bridge inventory " +
				"(dpwh.gov.ph/dpwh/gis/dbi) returns HTTP 403, so no span table; not raised"},
		{"id": "br_manila_mabini_bridge", "cc": "PH", "name": "Mabini Bridge", "wiki": "Mabini Bridge",
			"aliases": ["nagtahan bridge", "mabini bridge manila"], "lat": 14.5958, "lon": 121.0014, "bearing": 175.0,
			"st": "girder", "spans": [67.0, 67.0, 67.0], "width": 26.4, "clear": 8.0, "material": "concrete",
			"base": "water", "tier": 3, "conf": 1,
			"src": "en Wikipedia (concrete, 201 m, 26.4 m wide, built 1945, Wikidata coordinate); span split, " +
				"clear and bearing guessed | verified: en Wikipedia infobox: 17 spans (the first pass used " +
				"3), 26.4 m wide | round 2: round 2: en Wikipedia: 17 spans, 201 m, 26.4 m wide; per-span " +
				"lengths not found (the Nagtahan Link Bridge is a separate 2160 m crossing); DPWH detailed " +
				"bridge inventory (dpwh.gov.ph/dpwh/gis/dbi) returns HTTP 403, so no span table; not raised"},
		{"id": "br_manila_binondo_intramuros_bridge", "cc": "PH", "name": "Binondo-Intramuros Bridge", "wiki": "Binondo–Intramuros Bridge",
			"aliases": ["binondo intramuros bridge", "binondo–intramuros bridge"], "lat": 14.59531, "lon": 120.97474,
			"bearing": 174.7, "st": "arch_tied", "spans": [70.0], "width": 21.65, "clear": 8.5, "rise": 13.0,
			"material": "steel", "base": "water", "tier": 2, "conf": 2,
			"src": "en Wikipedia (steel tied arch 'bowstring' with inclined arches, 70 m main span, 680 m incl " +
				"approach viaducts, 21.65 m, opened 2022), OSM 477 m bearing 160.9; arch count and rise " +
				"guessed, only the main span modelled | verified: en Wikipedia: main span 70 m, 21.65 m wide; " +
				"arch count and rise not independently sourced | round 2: round 2: DPWH / Philippine press " +
				"(Portcalls, Manila Bulletin, DPWH news 25411): main bridge 70 m long, 21 m wide (Sec. " +
				"Mercado: four lanes 21.65 m wide) carried by two basket-handle tied steel arches, 680 m with " +
				"approach viaducts; arch rise not published (13 m = f/L ~1/5, estimated); OSM man_made=bridge " +
				"polygon 991039647 + arch footways 1301623821 / 1046833117 (72 m, bearing 174.8 / 354.3) " +
				"between lat 14.59499 and 14.59565, centre 14.59531,120.97474 on the Pasig centreline " +
				"(14.59528) - the old bearing 160.9 came from the curved approach viaduct"},
		{"id": "br_manila_guadalupe_bridge", "cc": "PH", "name": "Guadalupe Bridge", "wiki": "Guadalupe Bridge",
			"aliases": ["guadalupe bridge manila", "edsa guadalupe bridge"], "lat": 14.56847, "lon": 121.046,
			"bearing": 355.0, "st": "girder", "spans": [38.1, 38.2, 38.1], "width": 46.5, "clear": 9.0,
			"material": "concrete", "base": "water", "tier": 3, "conf": 1,
			"src": "en Wikipedia (EDSA over Pasig: outer girder bridges 114.44 m x 18.7 m each + inner 135 m x " +
				"9.1 m); outer bridge modelled with width of all three, spans, clear, bearing guessed | " +
				"verified: en Wikipedia: outer bridges 18.7 m wide each, inner 9.1 m, MRT tied-arch above 135 " +
				"m long | round 2: round 2: en Wikipedia: outer girder bridges 18.7 m wide each, 114.44 m; " +
				"span lengths not found; DPWH detailed bridge inventory (dpwh.gov.ph/dpwh/gis/dbi) returns " +
				"HTTP 403, so no span table; not raised"},
		{"id": "br_jakarta_kota_intan_bridge", "cc": "ID", "name": "Kota Intan Bridge", "wiki": "Kota Intan Bridge",
			"aliases": ["jembatan kota intan", "jembatan jungkit", "dutch drawbridge jakarta"], "lat": -6.13125,
			"lon": 106.81054, "bearing": 90.0, "st": "bascule", "spans": [8.5, 13.0, 8.5], "width": 4.43, "clear": 3.0,
			"material": "iron", "base": "water", "tier": 3, "conf": 1,
			"src": "en Wikipedia (oldest bridge in Indonesia, 1628 Dutch double-leaf drawbridge over Kali " +
				"Besar), dimensions ~30 x 4.5 m from general knowledge not a fetched source; spans, clear and " +
				"bearing estimated | verified: en Wikipedia gives no dimensions; none found | round 2: round " +
				"2: id Wikipedia has no dimensions; Indonesian press (goodnewsfromindonesia.id, merdeka.com) " +
				"give ~30 m length, 4.43 m width, a double-leaf drawbridge of two equal sides on a wooden " +
				"deck; span layout, deck height and bearing still unsourced, OSM not measured"},
		{"id": "br_bandar_seri_begawan_sungai_kebun_bridge", "cc": "BN", "name": "Sungai Kebun Bridge", "wiki": "Raja Isteri Pengiran Anak Hajah Saleha Bridge",

			"aliases": ["raja isteri pengiran anak saleha bridge", "jambatan sungai kebun", "sungai kebun bridge brunei"],
			"lat": 4.876528, "lon": 114.949944, "bearing": 70.0, "st": "stayed",
			"spans": [30.0, 87.0, 300.0, 160.0, 45.0], "width": 24.0, "clear": 25.0, "tower": 157.0, "towers": [3],
			"pylon": "single", "material": "concrete", "base": "water", "tier": 2, "conf": 1,
			"src": "en Wikipedia (single-tower cable-stayed over the Brunei River, 622 m, 300 m main span, tower " +
				"height 157 m, Wikipedia coordinate); span split, width, clear and bearing guessed | " +
				"verified: Wikipedia: 622 m, 300 m main span, single 157 m pylon; web search listing: " +
				"concrete box girder deck with span sequence 30+87+300+160+45 (=622 m) - orientation relative " +
				"to the pylon assumed (pylon between the 300 m and 160 m spans); width and clear unsourced | " +
				"round 2: round 2: search found only 622 m and 157 m tower (Wikipedia, Structurae media " +
				"page); span layout 30+87+300+160+45, deck width, lane count and clearance not confirmed by " +
				"any fetched source; not raised"},
		{"id": "br_canberra_commonwealth_avenue_bridge", "cc": "AU", "name": "Commonwealth Avenue Bridge", "wiki": "Commonwealth Avenue Bridge",
			"aliases": ["commonwealth avenue bridge canberra"], "lat": -35.29299, "lon": 149.12702, "bearing": 7.4,
			"st": "girder", "spans": [56.4, 64.0, 73.2, 64.0, 56.4], "width": 27.0, "clear": 6.0,
			"material": "concrete", "base": "water", "tier": 2, "conf": 2,
			"src": "en Wikipedia (two parallel prestressed box-girder bridges, 310 m, main span 240 ft, 1963), " +
				"OSM snapshot way bearing 6.8, cross-extent 27 m; span pattern and clear guessed | verified: " +
				"PCI Journal table 185-210-240-210-185 ft (= 56.4+64.0+73.2+64.0+56.4 = 314 m), en Wikipedia " +
				"(five continuous box-girder spans, 185 to 240 ft, 310 m), NCA/Rendel 310 m; OSM Commonwealth " +
				"Avenue ways 4878920 (324 m, bearing 187.4) and cycleway 4878929, bridge from " +
				"-35.29154,149.12725 to -35.29443,149.12679, centre -35.29299,149.12702 (old centre 140 m " +
				"north); width 27 m = twin carriageways from OSM, no printed source; clear 6 m estimated"},
	]
