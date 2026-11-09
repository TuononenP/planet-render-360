class_name BridgeSpecsAfricaEastSouth
extends RefCounted

## Capital bridge rows for East and Southern Africa (see BridgeSpec for the schema). Figures are
## sourced per row in `src`; conf 1 rows are kept as data but not built
## (BridgeSpec.MIN_BUILT_CONF).

static func rows() -> Array:
	return [
		{"id": "br_maputo_katembe_bridge", "cc": "MZ", "name": "Maputo-Katembe Bridge", "wiki": "Maputo–Katembe bridge",

			"aliases": ["ponte maputo-katembe", "maputo katembe bridge", "ponte de maputo a katembe", "maputo bay bridge"],
			"lat": -25.9729, "lon": 32.5576, "bearing": 196.2, "st": "susp", "spans": [260.0, 680.0, 285.0],
			"width": 25.6, "clear": 60.0, "tower": 138.0, "material": "steel", "base": "sea", "tier": 2, "conf": 2,
			"src": "en Wikipedia (680 m main span between 141 m concrete pylons, 25.6 m deck elements, ~60 m " +
				"high), Structurae snippet (1317.3 m between anchorages, hence side spans 318.65 m each, " +
				"assumed symmetric); UCT article says 20 m clearance, not used; OSM way 378386159 local " +
				"bearing 196 (whole way 190); only the suspended part modelled, the 1.1 km and 1.3 km " +
				"viaducts excluded | verified: Bridge Design & Engineering (bridgeweb.com/Making- " +
				"connections/4191): single-span double-hinged suspension bridge, centre span 680 m, side " +
				"spans 260 m and 285 m (total 1,225 m), girder 25.6 m wide x 3 m deep, towers 135 m (north) " +
				"and 136 m (south) planned, hangers 73 m at towers; ENR: main span 680 m, 60 m above sea " +
				"level; Structurae: pylons 141 m / 140 m, sag ~68 m; TheB1M 137 m towers and deck 60 m; GAUFF " +
				"140 m; en Wikipedia 680 m span, 3041 m total. The first pass's 318.65 m side spans came from " +
				"the 1317.3 m main-cable strand length and were wrong. Side-span order (260 north, 285 south) " +
				"is the article's mention order, not stated explicitly. Hanger length 73 m + 3 m minimum " +
				"agrees with tower 136-141 m over a 60 m deck. UCT's '20 m' clearance is contradicted by four " +
				"sources. OSM way 378386159 re-measured from the repo's bundled snapshot (ring2500): " +
				"suspended section runs straight at bearing 196.0-196.6 from node -25.96793,32.55918 to " +
				"-25.97698,32.55626 (way 3244 m incl. approaches, whole-way chord 189.7, so bearing 195.0 -> " +
				"196.2); main-span centre estimated at ~-25.9725,32.5577 from Wikipedia viaduct lengths (1097 " +
				"m + 680 m + 1264 m = 3041 m), within 50 m of the row centre, kept."},
		{"id": "br_khartoum_tuti_bridge", "cc": "SD", "name": "Tuti Bridge", "wiki": "Tuti Bridge",
			"aliases": ["tuti island bridge", "كبري توتي", "jisr tuti"], "lat": 15.6084, "lon": 32.5127,
			"bearing": 183.6, "st": "susp", "spans": [50.0, 210.0, 50.0], "width": 20.0, "clear": 12.0, "tower": 36.0,
			"material": "steel", "base": "water", "tier": 2, "conf": 2,
			"src": "en Wikipedia list of bridges in Sudan (50+210+50 m, 310 m, concrete pylons), Wikidata " +
				"Q652705 (210 m main span, 20 m width), OSM way 32685515 (213 m deck, bearing 183.6; " +
				"Wikipedia coord within 20 m); clear and tower estimated | verified: Spans 50+210+50 " +
				"confirmed by en Wikipedia list, A&A Consultants (210 m main span with a 50 m approach span " +
				"each side, 310 m total), Structurae (single-span two-tower suspension 210 m), Bridgemeister " +
				"(1x210 m); DLT Engineering: reinforced slab on transverse plate girders spanning 16 m " +
				"between longitudinal girders (cable planes 16 m apart, consistent with Wikidata Q652705 " +
				"width 20 m with footway cantilevers). OSM way 32685515 re-measured: 213 m, bearing 183.6, " +
				"mid 15.60843,32.51265 (Wikipedia coord 15.60834,32.51239 agrees). Pylon height not " +
				"published: tower 36 m is an estimate from ~21 m sag (span/10) + hanger/saddle margin over " +
				"the 12 m deck. Monash lists 230 m total (probably suspended length), not used."},
		{"id": "br_khartoum_mek_nimr_bridge", "cc": "SD", "name": "El Mek Nimr Bridge", "wiki": "El Mek Nimr Bridge",
			"aliases": ["mac nimir bridge", "mek nimr bridge", "كبري المك نمر", "al-mak nimir bridge"], "lat": 15.6125,
			"lon": 32.533, "bearing": 352.0, "st": "stayed", "spans": [55.0, 80.0, 55.0], "width": 22.0, "clear": 10.0,
			"tower": 40.0, "material": "steel", "base": "water", "tier": 2, "conf": 1,
			"src": "en Wikipedia list (cable-stayed 55+80+55 m, steel pylons, 2007), Wikidata Q259912 (22 m " +
				"wide); total length disagrees between sources (1165 / 642 / 523 m) and Wikipedia and " +
				"Wikidata coords differ by 200 m, so the position of the stayed part along the approaches is " +
				"unclear; OSM approach ways bearing 349-352; clear and tower guessed | verified: en Wikipedia " +
				"infobox: 642.5 m long, 2005-2007, no spans; Structurae: three-span cable-stayed with " +
				"composite deck; Wikipedia list 55+80+55 (1,165 m total), AidData 523 m. Length sources " +
				"disagree (523/642/1165) and the position of the stayed part within the approaches is unknown " +
				"(en Wikipedia coord 15.61389,32.53297 vs row centre 15.6125,32.533, 150 m apart). Nothing " +
				"independent for width, clearance or pylon height. | round 2: round 2: Length sources " +
				"disagree (523/642/1165 m) and stayed-part position among the approaches is unknown; no new " +
				"source for width/pylon found. Not retried."},
		{"id": "br_khartoum_omdurman_bridge", "cc": "SD", "name": "Omdurman Bridge", "wiki": "Omdurman Bridge",
			"aliases": ["white nile bridge khartoum", "كبري النيل الابيض", "jisr omdurman"], "lat": 15.6139,
			"lon": 32.491, "bearing": 299.2, "st": "truss", "spans": [74.0, 74.0, 74.0, 74.0, 74.0, 74.0, 74.0],
			"width": 8.0, "clear": 9.0, "rise": 8.0, "material": "steel", "base": "water", "tier": 3, "conf": 1,
			"src": "en Wikipedia list (steel truss, 7 x 74 m, 613 m incl. approaches, 1926, one swing span), " +
				"Wikidata coord 15.61379 32.49113 agrees with OSM way 108703840 (610 m, bearing 299.2); " +
				"width, clear and truss height guessed; has a swing span the builder cannot show | verified: " +
				"OSM way 108703840 re-measured: 610 m, bearing 299.2, mid 15.61389,32.49101 (correct; " +
				"Wikidata Q436067). en Wikipedia: Dorman Long 1924-26 steel truss, 613 m; Dorman Long table " +
				"(via search): 7 fixed spans + 1 swing span, 2,012 ft, 3,700 t; archive drawing mentions a " +
				"244 ft fixed span (~74 m); Sudan list 7 x 74 m. So there are 8 spans (the 7x74 row is " +
				"missing the swing span, remainder ~95 m) and the swing span position, width and truss height " +
				"are unknown; needs swing type with a 'moving' index. | round 2: round 2: 8 spans (7 fixed + " +
				"swing) with unknown swing position, width and truss height; no source found. Needs swing " +
				"type with moving index; left conf 1."},
		{"id": "br_khartoum_blue_nile_bridge", "cc": "SD", "name": "Blue Nile Road and Railway Bridge", "wiki": "Blue Nile Road and Railway Bridge",
			"aliases": ["blue nile bridge khartoum", "كبري النيل الأزرق", "blue nile railway bridge"], "lat": 15.6153,
			"lon": 32.544, "bearing": 350.7, "st": "truss", "spans": [66.0, 66.0, 66.0, 66.0, 66.0, 66.0, 66.0],
			"width": 12.0, "clear": 9.0, "rise": 8.0, "material": "steel", "base": "water", "tier": 3, "conf": 1,
			"src": "en Wikipedia list (steel truss 7 x 66 m, 560 m, road and rail, 1909 Cleveland Bridge), OSM " +
				"way 218220362 (570 m, bearing 350.7) agrees with Wikidata coord; the article calls it a " +
				"bascule bridge, which contradicts the list; width, clear and truss height guessed | " +
				"verified: OSM way 218220362 re-measured: 570 m, bearing 350.7, mid 15.61533,32.54398 " +
				"(correct). en Wikipedia: Cleveland Bridge 1907-09, 560 m, infobox says bascule, list says 7 " +
				"x 66 m truss; contradiction unresolved, no width or height found. | round 2: round 2: " +
				"Bascule vs truss contradiction unresolved; no width/height source."},
		{"id": "br_khartoum_kober_bridge", "cc": "SD", "name": "Kober Bridge", "wiki": "Kober Bridge",
			"aliases": ["cooper bridge khartoum", "armed forces bridge khartoum", "كوبرى كوبر"], "lat": 15.6169,
			"lon": 32.5548, "bearing": 350.0, "st": "girder",
			"spans": [64.0, 64.0, 64.0, 64.0, 64.0, 64.0, 64.0, 64.0, 64.0, 64.0, 64.0, 64.0], "width": 24.0,
			"clear": 10.0, "material": "concrete", "base": "water", "tier": 3, "conf": 1,
			"src": "en Wikipedia list (twin prestressed box girders, 767 m); article says opened 2014, list says " +
				"1972, so the current structure is unclear; Wikipedia/Wikidata coord agree; no OSM geometry " +
				"found, bearing assumed parallel to the Blue Nile bridge; spans split evenly, width and clear " +
				"guessed | verified: en Wikipedia: Kober (Armed Forces) Bridge, article says opened 23 Oct " +
				"2014 after rehabilitation, list says 1972, twin prestressed box girders 767 m; coord " +
				"15.61694,32.55472 agrees with row. OSM geometry not re-measurable (no way located); spans " +
				"split evenly and width unsourced. | round 2: round 2: No OSM way located, spans only an even " +
				"split; no new source."},
		{"id": "br_khartoum_al_mansheiya_bridge", "cc": "SD", "name": "Al Mansheiya Bridge", "wiki": "Al Mansheiya Bridge",
			"aliases": ["mansheya bridge", "كبري المنشية"], "lat": 15.599, "lon": 32.5896, "bearing": 83.8,
			"st": "girder", "spans": [50.0, 50.0, 50.0, 50.0, 50.0, 50.0, 50.0], "width": 8.25, "clear": 8.0,
			"material": "steel", "base": "water", "tier": 3, "conf": 1,
			"src": "en Wikipedia (350 m long, 8.25 m wide, opened 2006), Wikipedia coord matches OSM way " +
				"45097861 (372 m, bearing 83.8); span layout, material and clear guessed | verified: OSM way " +
				"45097861 re-measured: 372 m, bearing 83.8, mid 15.59902,32.58962 (correct). en Wikipedia: " +
				"350 m long, 8.25 m wide, opened 2006; no spans, type or material. | round 2: round 2: No " +
				"span layout or type source (350 m, 8.25 m wide only)."},
		{"id": "br_juba_nile_bridge", "cc": "SS", "name": "Juba Nile Bridge", "wiki": "Juba Nile Bridge",
			"aliases": ["juba bridge", "juba bailey bridge"], "lat": 4.8229, "lon": 31.6087, "bearing": 334.3,
			"st": "truss", "spans": [42.0, 42.0, 42.0, 42.0, 42.0, 42.0], "width": 9.0, "clear": 7.0, "rise": 3.0,
			"material": "steel", "base": "water", "tier": 3, "conf": 1,
			"src": "en Wikipedia (Bailey / Mabey Compact 200 truss, six 43 m spans, 258 m; two adjacent bridges " +
				"of 252 m), OSM way 624729861 (263 m, bearing 334.3) agrees with Wikipedia coord; width, " +
				"clear, truss height guessed; twin parallel bridges modelled as one | verified: Mabey case " +
				"study (Compact 200 repair, UNOPS): two adjacent 252 m bridges installed 2005 (Bailey " +
				"Replacement system), each a 3.15 m single-lane six-span bridge; so 6 spans of 42 m (equal " +
				"not stated), replacing the 1974 six x 43 m Bailey spans. OSM way 624729861 re-measured: 263 " +
				"m, bearing 334.3, mid 4.82290,31.60871 (correct). Width/height of truss unsourced (twin " +
				"single-lane trusses modelled as one). | round 2: round 2: Twin 252 m Bailey bridges, equal " +
				"42 m spans not stated; truss dimensions unsourced."},
		{"id": "br_juba_freedom_bridge", "cc": "SS", "name": "Freedom Bridge", "wiki": "Freedom Bridge (South Sudan)",
			"aliases": ["freedom bridge juba", "juba freedom bridge"], "lat": 4.8106, "lon": 31.6031, "bearing": 73.4,
			"st": "arch_tied", "spans": [30.0, 30.0, 30.0, 30.0, 30.0, 87.5, 87.5, 87.5, 87.5, 30.0, 30.0],
			"width": 12.9, "clear": 6.5, "rise": 14.0, "material": "steel", "base": "water", "tier": 3, "conf": 2,
			"arch_spans": [5, 6, 7, 8],
			"src": "en Wikipedia list (steel tied-arch / bow-string, 4 x 87 m, 560 m total, opened 2022), OSM " +
				"way 266430929 (601 m, bearing 73.4) agrees with Wikidata coord; width, clear and arch rise " +
				"guessed | verified: JICA Preparatory Survey Report on the Project for Construction of Nile " +
				"River Bridge (Feb 2012, openjicareport.jica.go.jp 12057949_01): bridge length 560 m = " +
				"approach 5@30 (west) + main 4@87.5 steel Langer (tied) arch + approach 2@30 (east) steel " +
				"plate I-girders, wall piers, lane 3.6 m, shoulder 0.75 m, sidewalk 2.5 m one side, girder " +
				"(bottom chord) depth 2.0 m, design flood EL 459.30 + 1.5 m clearance, dry/rainy-season water " +
				"level EL 455.65/456.65; JSCE project page pj20: 560 m, four Langer spans in the 350 m river " +
				"section, plate girders on land; JICA completion notice: 560 m steel arch; JICA South Sudan " +
				"notice 2019: width 12.9 m. Deck height 6.5 m above rainy-season water is derived from those " +
				"levels; rise 14 m is a Langer span/6 estimate. Spans ordered west -> east, matching OSM way " +
				"266430929 (601 m incl. approaches, bearing 73.4, west to east, mid 4.81061,31.60309); en " +
				"Wikipedia coord within 40 m."},
		{"id": "br_port_louis_saj_bridge", "cc": "MU", "name": "Sir Anerood Jugnauth Bridge", "wiki": "Sir Anerood Jugnauth Bridge",
			"aliases": ["saj bridge", "saj bridge mauritius", "a1-m1 link road bridge"], "lat": -20.2081, "lon": 57.473,
			"bearing": 87.9, "st": "extradosed", "spans": [100.0, 130.0, 100.0], "width": 25.0, "clear": 90.0,
			"tower": 106.0, "material": "concrete", "base": "ground", "tier": 3, "conf": 2,
			"src": "en Wikipedia (extradosed, ~330 m, ~120 m high), SYSTRA page via search snippet (100+130+100 " +
				"m, 25 m wide), Bouygues snippet (170 m main span, 90 m above valley) conflicts; OSM ways " +
				"1018525944 (bearing 87.9); extradosed type cannot be shown by the cable builder; clear and " +
				"tower guessed | verified: SYSTRA IBT project page (systra.com/ibt/?p=6860, the designer): " +
				"3-span extradosed concrete bridge with spans 100+130+100 m, 25 m wide dual carriageway, " +
				"single constant-depth box girder built by balanced cantilever with temporary stays, 90 m " +
				"deep gorge, slender ~100 m tall pylons; SYSTRA news 20 Mar 2024: 330 m bridge, 'asymmetrical " +
				"spans' needing temporary stays for the extra length of the side spans, 2 pylons; en " +
				"Wikipedia: ~330 m long, two pylons with 7 stays each, ~120 m above the valley floor " +
				"(Ministry); Bouygues snippet says main span 170 m and 90 m above the river, which conflicts " +
				"with the designer (80+170+80 would also sum to 330 but would not need extra temporary stays " +
				"on short side spans). Deck 90 m above valley; tower 106 m is an estimate between SYSTRA's " +
				"100 m and Wikipedia's 120 m (extradosed pylons normally rise 0.1 x main span above the " +
				"deck). OSM way 1018525944 (eastbound) re-measured: 364 m, bearing 87.9, mid " +
				"-20.20810,57.47298; Wikipedia coord -20.2082,57.4730 agrees."},
	]
