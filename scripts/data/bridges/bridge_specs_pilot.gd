class_name BridgeSpecsPilot
extends RefCounted

## Capital bridge rows for pilot (see BridgeSpec for the schema). Figures are
## sourced per row in `src`; conf 1 rows are kept as data but not built
## (BridgeSpec.MIN_BUILT_CONF).

static func rows() -> Array:
	return [
		{"id": "br_paris_pont_alexandre_iii", "cc": "FR", "name": "Pont Alexandre III", "wiki": "Pont Alexandre III",
			"aliases": ["pont alexandre-iii", "alexandre iii bridge", "pont alexandre 3"], "lat": 48.8636,
			"lon": 2.3136, "bearing": 4.5, "st": "arch_deck", "spans": [107.5], "width": 40.0, "clear": 8.0,
			"rise": 6.3, "material": "steel", "base": "water", "tier": 1, "conf": 2,
			"src": "en+fr Wikipedia (107.5 m span, 160 m total, 40 m wide, rise 1/17), OSM way bearing; clear " +
				"estimated | verified: fr Wikipedia (single 3-hinge steel arch 107.5 m, 160 m total, deck 40 " +
				"m by design (45 m incl. cornices), flèche 1/17), en Wikipedia (107.5 m, 40 m); OSM way " +
				"17067006 (bridge=yes, 149 m incl. abutments, brg 4.5, mid 48.86364,2.31354) agrees with row " +
				"centre within 25 m; clear 8 m and rise 6.3 m (=107.5/17) remain estimates"},
		{"id": "br_paris_pont_d_iena", "cc": "FR", "name": "Pont d'Iéna", "wiki": "Pont d'Iéna",
			"aliases": ["pont d'iena", "jena bridge", "pont de jena"], "lat": 48.8598, "lon": 2.2922, "bearing": 134.2,
			"st": "masonry", "spans": [31.0, 31.0, 31.0, 31.0, 31.0], "width": 35.0, "clear": 8.0, "rise": 3.35,
			"material": "stone", "base": "water", "tier": 2, "conf": 2,
			"src": "en+fr Wikipedia (5 arches of 28 m, 155 m, 35 m after 1935), Paris street dictionary rise " +
				"3.30 m / Structurae 3.40 m, OSM bearing; clear estimated, pier 3 m assumed | verified: fr " +
				"Wikipedia (155 m, 5 equal arches of 28 m clear, 4 piers, 35 m wide since 1935); OSM ways " +
				"986589650/1322092757 (156 m, brg 134.0-134.3, mid 48.85976,2.29201) agree with row centre " +
				"(15 m) and bearing; equal arches stated by source so 5x31 m pier-centre spans (3 m piers " +
				"assumed) stay"},
		{"id": "br_paris_pont_neuf", "cc": "FR", "name": "Pont Neuf", "wiki": "Pont Neuf",
			"aliases": ["pont neuf paris", "new bridge paris"], "lat": 48.8578, "lon": 2.3419, "bearing": 208.4,
			"st": "masonry", "spans": [20.7, 21.8, 22.8, 23.4, 22.8, 21.8, 20.7], "width": 20.5, "clear": 9.5,
			"rise": 6.0, "material": "stone", "base": "water", "tier": 1, "conf": 1,
			"src": "fr Wikipedia (right-bank arm: 7 arches 16.4-19.4 m, 154 m; width 20.5 m), OSM ways; modelled " +
				"ONLY the longer right-bank arm (7 arches), not the 5-arch left arm; piers ~4.3 m added to " +
				"arch openings; clear and rise estimated | verified: fr Wikipedia + web search: grand bras 7 " +
				"arches with openings 16.40-19.40 m (154 m), petit bras 5 arches 9-16.70 m (78 m), width " +
				"20.50 m; per-arch openings and pier thicknesses are not published in any source reachable, " +
				"so the 7-span list stays a derived estimate; OSM ways 53574163+557297166 (right arm, brg " +
				"208.0, mid 48.85785,2.34195) agree with row centre/bearing; also Structurae notes the grand- " +
				"bras arches were rebuilt 1870 as basket-handle profiles | round 2: round 2: fr Wikipedia " +
				"only: arch openings 16.4-19.4 m, pier thicknesses unpublished"},
		{"id": "br_paris_pont_des_arts", "cc": "FR", "name": "Pont des Arts", "wiki": "Pont des Arts",
			"aliases": ["passerelle des arts", "pont des arts paris"], "lat": 48.8584, "lon": 2.3376, "bearing": 18.5,
			"st": "arch_deck", "spans": [22.15, 22.15, 22.15, 22.15, 22.15, 22.15, 22.15], "width": 11.0, "clear": 8.0,
			"rise": 2.2, "material": "steel", "base": "water", "tier": 1, "conf": 2,
			"src": "en+fr Wikipedia (current 1984 bridge, 7 steel arches, 155 m, 11 m), OSM bearing; equal spans " +
				"assumed, rise and clear estimated | verified: fr+en Wikipedia (Arretche rebuild 1981-84, 7 " +
				"arches, 155 m, 11 m wide), Grace's Guide (present bridge: 7 arches of 22 m span, i.e. equal " +
				"arches), fr Wikipedia (original span of the Institut-side arch was used as the gauge for all " +
				"new arches); OSM way 454298362 (152 m, brg 18.5, mid 48.85846,2.33757) agrees with row " +
				"centre within 10 m; clear 8 m and rise 2.2 m estimated"},
		{"id": "br_budapest_elisabeth_bridge", "cc": "HU", "name": "Elisabeth Bridge", "wiki": "Elisabeth Bridge (Budapest)",
			"aliases": ["erzsébet híd", "erzsebet hid", "elizabeth bridge"], "lat": 47.491, "lon": 19.0492,
			"bearing": 242.3, "st": "susp", "spans": [44.3, 290.0, 44.3], "width": 27.1, "clear": 9.5, "tower": 45.0,
			"material": "steel", "base": "water", "tier": 2, "conf": 1,
			"src": "en+hu Wikipedia (290 m main, 378.6 m total, 27.1 m wide), OSM bearing; side spans split " +
				"evenly, tower and clear estimated | verified: en+hu Wikipedia + Wikidata Q699098 (main span " +
				"290 m, total 378.6 m, 27.1 m wide, 3 spans, suspension); the 44.3 m side spans are only " +
				"(378.6-290)/2, no source gives the side spans or pylon height (searched Wikipedia, " +
				"Bridgemeister, OPAC, Structurae snippets); OSM: footway 654470335 (399 m incl. ramps, brg " +
				"242.1, mid 47.49103,19.04921) and hu infobox coordinate 47.4908,19.0492 put the centre ~60 m " +
				"west of the first-pass lon 19.05; en title is 'Elisabeth Bridge (Budapest)' | round 2: round " +
				"2: no new source: side spans (378.6-290)/2 still derived, pylon height not published in any " +
				"retrievable source"},
		{"id": "br_budapest_liberty_bridge", "cc": "HU", "name": "Liberty Bridge", "wiki": "Liberty Bridge (Budapest)",
			"aliases": ["szabadság híd", "szabadsag hid", "freedom bridge", "ferenc jozsef bridge"], "lat": 47.4857,
			"lon": 19.055, "bearing": 52.8, "st": "truss", "spans": [78.1, 175.0, 78.1], "width": 20.1, "clear": 9.5,
			"rise": 12.0, "material": "steel", "base": "water", "tier": 1, "conf": 2,
			"src": "en+hu Wikipedia (333.6 m, 20.1 m), Structurae via search snippet (78.1+175+78.1), OSM " +
				"bearing; truss height and clear estimated | verified: hu Wikipedia (3-span Gerber cantilever " +
				"truss, 333.6 m, 20.1 m, largest span 170.75 m), en Wikipedia (cantilever truss with " +
				"suspended middle span, 333.6 m, 20.1 m), Structurae via search snippet (78.1+175+78.1, " +
				"suspended drop-in span 46.9 m); a Hungarian bridge list gives 79+179+79, so the main span is " +
				"uncertain by about 4 m; OSM ways 54236652/4381354 (335 m, brg 52.8, mid 47.4857,19.0549) " +
				"agree with row; truss height 12 m and clear 9.5 m estimated"},
		{"id": "br_budapest_margaret_bridge", "cc": "HU", "name": "Margaret Bridge", "wiki": "Margaret Bridge",
			"aliases": ["margit híd", "margit hid", "margaret bridge budapest"], "lat": 47.5141, "lon": 19.0429,
			"bearing": 281.6, "st": "arch_deck", "spans": [30.0, 83.4, 92.6, 97.8, 97.8, 92.6, 83.4, 30.0],
			"width": 25.0, "clear": 9.5, "rise": 7.0, "material": "steel", "base": "water", "tier": 2, "conf": 1,
			"src": "hu+en Wikipedia (6 openings 73.5/82.67/87.88 each arm + 2x20 m shore spans, 607.6 m, 25 m), " +
				"OSM; centre = chord midpoint of the two arms; spans = clear opening + ~9.94 m pier allowance " +
				"to reach 607.6 m; rise and clear estimated | verified: hu Wikipedia: two arms with a broken " +
				"axis meeting at the central pier (spurious 'straight' chain), 6 openings " +
				"73.5+82.67+87.88+87.88+82.67+73.5 m clear, 2x20 m shore spans, total 607.6 m, rebuilt 1948 " +
				"as 6-girder steel arches, deck 25 m after 2011; pier thicknesses not published so pier- " +
				"centre spans stay derived; a bent plan cannot be modelled by a straight chain | round 2: " +
				"round 2: hu Wikipedia: bent two-arm plan with clear openings and pier-centre spans derived; " +
				"cannot be a straight chain"},
		{"id": "br_london_westminster_bridge", "cc": "GB", "name": "Westminster Bridge", "wiki": "Westminster Bridge",
			"aliases": ["westminster bridge london"], "lat": 51.5009, "lon": -0.1218, "bearing": 92.5,
			"st": "arch_deck", "spans": [31.1, 36.5, 38.4, 40.2, 38.4, 36.5, 31.1], "width": 26.0, "clear": 8.5,
			"rise": 3.0, "material": "iron", "base": "sea", "tier": 1, "conf": 1,
			"src": "en Wikipedia (7 arches, 250 m, 26 m), Grace's Guide (arches 96-120 ft, 826.8 ft overall), " +
				"OSM bearing; individual spans derived: symmetric 96/108/114/120 ft clear + 3.6 m piers; rise " +
				"and clear estimated | verified: en Wikipedia (7 arches, 250 m, 26 m wide), Grace's Guide " +
				"(arches 96-120 ft), Structurae snippet (spans 28.96-35.05 m clear); web sources disagree on " +
				"length (810/820/827 ft) and width (84/85/88 ft) and no source lists the individual arch " +
				"spans; OSM way 216998718/920237496 (brg 91.3-92.6, mid 51.50089,-0.12178) agree with row " +
				"centre/bearing | round 2: round 2: web search: centre arch 120 ft with neighbours " +
				"115/104.5/94.5 ft in one old source vs Grace's Guide 96-120 ft; the symmetric 96/108/114/120 " +
				"ft split is not confirmed and pier thickness is not published"},
		{"id": "br_london_waterloo_bridge", "cc": "GB", "name": "Waterloo Bridge", "wiki": "Waterloo Bridge",
			"aliases": ["waterloo bridge london", "ladies bridge"], "lat": 51.508546, "lon": -0.116883,
			"bearing": 331.0, "st": "girder", "spans": [72.0, 75.0, 75.0, 75.0, 72.0], "width": 24.0, "clear": 9.0,
			"material": "concrete", "base": "sea", "tier": 2, "conf": 2,
			"src": "en Wikipedia (1230 ft, 80 ft wide), search snippets (c20society/waymarking/hagerty: 3x75 + " +
				"2x72 m, 24 m), OSM bearing; clear estimated | verified: Historic England listing (via " +
				"Waymarking): five spans, 'three spans of 75m between two of 72m', 24 m wide, reinforced " +
				"concrete box girders continuous over the two outer pairs; en Wikipedia (1230 ft incl. " +
				"approaches, 80 ft wide, main span 233 ft); OSM ways 200596577/948685545 (brg 330.5-331.0), " +
				"river chain mid ~51.5079,-0.1163 within 15 m of row; clear 9 m estimated | placement: centre " +
				"moved +69 m along the deck onto the middle of the mapped water crossing (offset measured in " +
				"the bundled OSM snapshot)"},
		{"id": "br_london_millennium_bridge", "cc": "GB", "name": "Millennium Bridge", "wiki": "Millennium Bridge, London",
			"aliases": ["london millennium footbridge", "wobbly bridge", "millennium footbridge"], "lat": 51.5096,
			"lon": -0.0986, "bearing": 182.3, "st": "lateral", "spans": [81.0, 144.0, 108.0], "width": 4.0,
			"clear": 8.5, "tower": 12.5, "material": "steel", "base": "sea", "tier": 1, "conf": 2,
			"src": "en Wikipedia (81/144/108 m north to south, 4 m deck, 325 m structure), OSM way (suspension, " +
				"bearing 2.3 south-to-north, reversed to travel north to south); lateral-suspension, piers " +
				"low: tower = pier-arm top estimated, clear estimated; NOT BUILT: its cables run beside the " +
				"deck, which the tower-and-cable builder cannot show | verified: en Wikipedia + Arup-derived " +
				"text (81/144/108 m north to south, 325 m structure, 4 m deck, two river piers), " +
				"bridgeinfo.broer.no (325 m, main span 144 m, 4 m); OSM ways 7225360+7225371 " +
				"(51.50814,-0.09869 to 51.51106,-0.09843 = 325 m, brg 2.3-3.2 south to north, mid " +
				"51.5096,-0.09856) agree with row (bearing 182.3 reversed = 2.3); span sum 333 m vs 325 m " +
				"total is unexplained; tower (pier-arm top) and clear (tourist site says ~10.8 m at high " +
				"tide) estimated"},
		{"id": "br_washington_arlington_memorial_bridge", "cc": "US", "name": "Arlington Memorial Bridge", "wiki": "Arlington Memorial Bridge",
			"aliases": ["memorial bridge", "arlington memorial bridge dc"], "lat": 38.8873, "lon": -77.0554,
			"bearing": 245.1, "st": "masonry",
			"spans": [59.4, 59.4, 59.4, 59.4, 59.4, 65.8, 59.4, 59.4, 59.4, 59.4, 59.4], "width": 28.7, "clear": 8.0,
			"rise": 6.0, "material": "stone", "base": "water", "tier": 2, "conf": 1,
			"src": "en Wikipedia (2163 ft), NCPC 2016 / ASCE via search snippets (94 ft wide; 10 arch spans " +
				"166-180 ft springline-to-springline; bascule trunnions 216 ft), OSM bearing; arches averaged " +
				"to (2163 ft - 216 ft)/10; material is granite-faced reinforced concrete; clear and rise " +
				"estimated | verified: en Wikipedia (2163 ft), NPS/Structurae snippets (bascule 216 ft/65.9 " +
				"m, 10 concrete arches, Structurae total 652 m, Hardesty says trunnions 214 ft); no source " +
				"gives the individual arch spans (166-180 ft springline-to-springline only) so the equal 59.4 " +
				"m pier spans stay averaged; HAER DC-7 (LoC) would hold the table; OSM way 468423958 (669 m, " +
				"brg 245.1, mid 38.88735,-77.05550) and cycleway 69200708 (brg 65.1) agree with row " +
				"centre/bearing | round 2: round 2: HAER DC-7A PDF (npshistory) covers only Watergate/Plaza; " +
				"NCPC/Hardesty give arch lengths 166-180 ft springline-to-springline, individual spans not " +
				"found"},
		{"id": "br_washington_francis_scott_key_bridge", "cc": "US", "name": "Francis Scott Key Bridge", "wiki": "Francis Scott Key Bridge (Washington, D.C.)",
			"aliases": ["key bridge", "francis scott key bridge dc", "key bridge georgetown"], "lat": 38.902,
			"lon": -77.07, "bearing": 20.0, "st": "arch_deck", "spans": [57.0, 62.2, 63.4, 62.2, 57.0], "width": 27.4,
			"clear": 25.9, "rise": 14.0, "material": "concrete", "base": "water", "tier": 2, "conf": 2,
			"src": "en Wikipedia (5 arches 187/204/208/204/187 ft, roadway 85 ft above average water, 70 ft " +
				"wide, citing Emery 1938), OSM bearing; rise estimated; width is original deck width | " +
				"verified: en Wikipedia 'Key Bridge (Washington, D.C.)' (five arches 208 ft centre, 204 ft " +
				"x2, 187 ft x2 per Emery 1938 + DC HPD 1995; roadway 85 ft = 25.9 m above average water " +
				"level; original deck 70 ft, rebuilt deck 90 ft wide with sidewalks widened; NBI sheet: out- " +
				"to-out 89.9 ft = 27.4 m, curb-to-curb 65.9 ft); the first pass used the original 70 ft, " +
				"today's deck is 27.4 m wide; rise 14 m estimated; geometry via Nominatim/OSM (OSM API rate- " +
				"limited): man_made=bridge way 435842740 outline axis 20.3 deg, 547 m incl. Georgetown-side " +
				"approach spans, centre 38.90269,-77.06975; the 5-arch river chain (302 m) sits toward the " +
				"Virginia end, so its centre is about 38.9016,-77.0702, within ~45 m of the row " +
				"(38.902,-77.07); bearing 20.0 agrees"},
		{"id": "br_berlin_oberbaumbruecke", "cc": "DE", "name": "Oberbaumbrücke", "wiki": "Oberbaum Bridge",
			"aliases": ["oberbaum bridge", "oberbaumbruecke"], "lat": 52.5017, "lon": 13.4456, "bearing": 37.9,
			"st": "masonry", "spans": [11.1, 23.2, 26.2, 29.2, 26.2, 23.2, 11.1], "width": 27.9, "clear": 6.0,
			"rise": 3.5, "material": "stone", "base": "water", "tier": 1, "conf": 2,
			"src": "de Wikipedia infobox (7 arches, 150 m, 27.9 m, span 22 m, clear height 4.5 m), OSM bearing; " +
				"brick-clad masonry with Calatrava steel centre; individual spans evenly distributed; clear " +
				"and rise estimated | verified: de Wikipedia infobox (seven arches, 150 m, 27.9 m wide, 22 m " +
				"span, clear height 4.5 m); Structurae snippet: arches masonry, piers concrete, steel only in " +
				"the movable (U-Bahn) span; no source lists the individual arches (the 22 m figure may be the " +
				"Calatrava centre field) so the evenly split spans stay an assumption; OSM way 4686104 (150 " +
				"m, brg 37.9, mid 52.50173,13.44568) and bridge outline way 288514442 (axis 39.1, centre " +
				"52.50169,13.44565) agree with row | round 2: round 2: de Wikipedia Oberbaumbruecke text " +
				"states the seven vault openings 7.5, 16, 19, 22, 19, 16, 7.5 m (sum 107 m, 22 m = Calatrava " +
				"steel centre field, matches infobox span) and infobox/OSM give 150 m overall, 27.9 m wide; " +
				"the six piers are therefore (150-107)/6 = ~7.2 m thick (de text: piers deliberately " +
				"oversized, concrete), spans set as opening + pier (end spans opening + half pier, sum 150 " +
				"m); centre and bearing already re-measured from OSM ways 4686104 / 288514442 in round 1"},
		{"id": "br_bangkok_rama_viii_bridge", "cc": "TH", "name": "Rama VIII Bridge", "wiki": "Rama VIII Bridge",
			"aliases": ["saphan phra ram 8", "สะพานพระราม 8", "rama 8 bridge"], "lat": 13.7694, "lon": 100.4965,
			"bearing": 118.5, "st": "stayed", "spans": [75.0, 50.0, 50.0, 300.0], "width": 29.2, "clear": 12.5,
			"tower": 160.0, "towers": [3], "material": "steel", "base": "water", "tier": 2, "conf": 2,
			"src": "en Wikipedia (300 m main, 475 m, single 160 m inverted-Y pylon on Thonburi bank), Roads & " +
				"Bridges via search snippet (50+50+75 m back spans, 29.2 m deck), OSM; spans listed west " +
				"(Thonburi) to east; clear estimated from 10.4 m wiki clearance | verified: Roads & Bridges " +
				"Aug 2003 'Soaring on the feet of an elephant' (475 m = 300 m main + two 50 m back spans + 75 " +
				"m anchor span, single 160 m pylon, main-span deck 29.2 m wide, anchor span 28.4 m), en " +
				"Wikipedia (300 m, 475 m, 160 m inverted-Y pylon on the Thonburi bank, 10.4 m clearance); " +
				"structure: light steel frame main span, concrete back spans; clear 12.5 m estimated; OSM " +
				"bridge outline way 965040447 (axis 117.6, centre 13.76933,100.49641, 397 m main portion) " +
				"agrees with row centre (7 m) and bearing 118.5; pylon on the west (Thonburi) bank so the 75 " +
				"m anchor span is the first span"},
		{"id": "br_bangkok_rama_ix_bridge", "cc": "TH", "name": "Rama IX Bridge", "wiki": "Rama IX Bridge",
			"aliases": ["saphan phra ram 9", "สะพานพระราม 9", "rama 9 bridge", "bhumibol bridge"], "lat": 13.6825,
			"lon": 100.5177, "bearing": 37.2, "st": "stayed", "spans": [46.8, 57.6, 61.2, 450.0, 61.2, 57.6, 46.8],
			"width": 33.0, "clear": 41.0, "tower": 128.0, "towers": [3, 4], "pylon": "single", "material": "steel",
			"base": "water", "tier": 2, "conf": 1,
			"src": "en Wikipedia (450 m main, 781.2 m, 33 m wide, clearance 41 m, height 87 m), Structurae via " +
				"search snippet (side spans 61.2+57.6+46.8), OSM bearing; tower = 41 m + 87 m assuming 87 m " +
				"is above deck; single-plane cables | verified: en Wikipedia (450 m main, 781.2 m, 33 m, " +
				"'height 87 m', clearance below 41 m), OPAC inspection report (450 m main span, two 166 m " +
				"side spans; the 46.8+57.6+61.2 m split of each side is only a Structurae snippet), no source " +
				"says whether the 87 m pylon height is above the deck; viaducts are 13x50 m; OSM way " +
				"150573914 (786 m, brg 217.2 NE-SW reversed = 37.2, mid 13.68244,100.51776) and outline way " +
				"956029043 (axis 37.7, centre 13.68217,100.51745) agree with row | round 2: round 2: web " +
				"search: OPAC says 450 m main + two 166 m side spans (46.8+57.6+61.2 = 165.6 m agrees in " +
				"total but only from a Structurae snippet); the 87 m height is not stated as above-deck"},
		{"id": "br_vienna_reichsbruecke", "cc": "AT", "name": "Reichsbrücke", "wiki": "Reichsbrücke",
			"aliases": ["reichsbruecke wien", "reichsbrücke wien", "reichs bridge"], "lat": 48.228, "lon": 16.4094,
			"bearing": 51.0, "st": "haunched", "spans": [133.0, 169.0, 150.0, 76.0], "width": 26.1, "clear": 15.0,
			"material": "concrete", "base": "water", "tier": 2, "conf": 1, "mid_depth": 5.5, "pier_depth": 8.8,
			"src": "de+en Wikipedia (1980 prestressed box girder, 865 m total, 26.1 m, 169 m Danube span, 76 m " +
				"Neue Donau span), Structurae/brueckenweb via search (main bridge ~528 m, max span 169), OSM " +
				"bearing; 150 m and 133 m spans are ESTIMATES to reach 528 m; clear estimated | verified: de " +
				"Wikipedia (third Reichsbruecke 1980: prestressed-concrete double-deck haunched box girder, " +
				"865 m total, max span 169 m over the Danube, 76 m over Neue Donau, roadway 26.1 m, girder " +
				"depth 8.8 m over the river pier to 5.5 m minimum), brueckenweb.de (Voutentraeger, 169 m, 864 " +
				"m), Structurae snippet (main bridge ~528 m); the 133/150 m neighbouring spans are still " +
				"estimates; OSM way 371685474 (864 m whole bridge, brg 231.0 = 51.0 reversed, mid " +
				"48.22814,16.40928) and outline way 372257310 (axis 51.0) agree with row centre/bearing, but " +
				"the row centre is the middle of the whole 864 m bridge while the span chain is only ~528 m " +
				"(the SW end at 48.22569,16.40475), so the chain is probably displaced ~150 m | round 2: " +
				"round 2: de Wikipedia: 865 m total = 528 m Stromtragwerk (Danube + island, only ONE river " +
				"pier) + 213 m over Neue Donau + 124 m over the motorway; max span 169 m (Danube), 76 m (Neue " +
				"Donau); the 133/150 m neighbours are not published and the chain-vs-centre displacement " +
				"stays unresolved"},
	]
