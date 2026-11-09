class_name BridgeSpecsSouthAsia
extends RefCounted

## Capital bridge rows for South Asia (see BridgeSpec for the schema). Figures are
## sourced per row in `src`; conf 1 rows are kept as data but not built
## (BridgeSpec.MIN_BUILT_CONF).

static func rows() -> Array:
	return [
		{"id": "br_new_delhi_signature_bridge", "cc": "IN", "name": "Signature Bridge", "wiki": "Signature Bridge",
			"aliases": ["wazirabad signature bridge", "yamuna signature bridge"], "lat": 28.70545, "lon": 77.23385,
			"bearing": 109.0, "st": "stayed", "spans": [36.0, 36.0, 36.0, 36.0, 36.0, 36.0, 36.0, 36.0, 36.0, 251.0],
			"width": 35.2, "clear": 11.0, "tower": 165.0, "towers": [9], "pylon": "single", "material": "steel",
			"base": "water", "tier": 2, "conf": 2, "lean": -39.0,
			"src": "en Wikipedia + sbp.de/structurae snippets (251 m main, 36 m back span, 35.2 m wide, 575 m " +
				"main bridge, pylon 154 m above deck); OSM way 642711952 via Nominatim (bearing 109 west to " +
				"east, centre = pylon at Wikidata 28.7057,77.2324 shifted to chain midpoint); asymmetric " +
				"leaning cantilever-spar pylon cannot be represented; clear estimated | verified: " +
				"Construction World (constructionworld.in Signature-Move: main bridge 575 m + 100 m west " +
				"extension = 675 m, main span 251 m, side spans 36 m each, width 35.20 m, pylon 154 m above " +
				"deck, legs inclined 85 m at 63 deg then near-vertical); Bruggen 2018 'Design and " +
				"construction of the Yamuna Bridge' (SBP: main span 251 m, total 675 m, approach deck on " +
				"piers at 36 m intervals, tower ~150 m, two inclined legs bend mid-way, 35 m wide); Indian " +
				"Infrastructure (side spans total 324 m = 9 x 36 + 251 = 575 m); SBP/Wikidata 165 m above " +
				"ground; OSM bridge way 642711952 (607 m, 109.0 deg, 77.2308..77.2366) fits 324+251 east of " +
				"pylon foot at ~28.7053,77.2342 (Wikipedia infobox 77.2340, OSM man_made outline bump " +
				"77.2339-77.2345); centre = mid of 9x36+251 chain"},
		{"id": "br_new_delhi_old_yamuna_bridge", "cc": "IN", "name": "Old Yamuna Bridge", "wiki": "Old Yamuna Bridge",
			"aliases": ["lohe ka pul", "loha pul delhi", "bridge number 249"], "lat": 28.6637, "lon": 77.24875,
			"bearing": 64.9, "st": "truss",
			"spans": [61.72, 61.72, 61.72, 61.72, 61.72, 61.72, 61.72, 61.72, 61.72, 61.72, 61.72, 61.72], "width": 8.0,
			"clear": 14.0, "rise": 3.0, "material": "iron", "base": "water", "tier": 2, "conf": 1, "lower": 6.0,
			"src": "en Wikipedia (1866, 12 spans of 202.5 ft = 61.72 m, 804.67 m, double-deck truss: rail above, " +
				"road below); OSM way 77617246 via Nominatim (bearing 245 reversed to 65, centre agrees with " +
				"Wikidata); double-deck rail-dominated truss not representable; width, clear, truss depth " +
				"estimated | verified: en Wikipedia + Tribune (12 spans of 202.5 ft = 61.7 m, rail above " +
				"road); Asian Age gives 214 ft spans and 2 end spans 46 ft; end spans 34.5 ft (Tribune) vs 42 " +
				"ft (Wikipedia); total 804.7 m vs 930 m (Wikipedia infobox); no source for the roadway width " +
				"or truss height found; OSM road way 1305188982 (790 m, 64.9 deg, mid 28.66371,77.24873) and " +
				"rail way 77603110 (838 m, 64.7 deg) re-measured; re-typed as truss with a lower road deck " +
				"(rail on top, road 6 m below) | round 2: round 2: no new source for roadway width or truss " +
				"height; end-span lengths conflict"},
		{"id": "br_new_delhi_geeta_colony_bridge", "cc": "IN", "name": "Geeta Colony Bridge", "wiki": "Geeta Colony Bridge",
			"aliases": ["geeta colony flyover", "geeta colony yamuna bridge"], "lat": 28.65144, "lon": 77.26285,
			"bearing": 88.7, "st": "girder",
			"spans": [40.0, 40.0, 40.0, 40.0, 40.0, 40.0, 40.0, 40.0, 40.0, 40.0, 40.0, 40.0, 40.0, 40.0],
			"width": 27.1, "clear": 10.0, "material": "concrete", "base": "water", "tier": 3, "conf": 2,
			"src": "en Wikipedia (560 m in 14 segments of 40 m, 27.1 m wide); OSM way 1498119444 via Nominatim " +
				"(568 m, bearing 268.7 reversed to 88.7), Wikidata coordinate within 40 m; clear estimated | " +
				"verified: en Wikipedia text (560 m in fourteen 40 m segments, two 9 m roadways + footways, " +
				"27.1 m wide, T-girder prestressed concrete); NBMCW 2008 paper by B&S Engineering Consultants " +
				"titled for this bridge (paywalled, could not read); no second independent source found for " +
				"spans; OSM way 1498119444 (568 m, 268.7 reversed to 88.7, mid 28.65144,77.26286) re-measured " +
				"and agrees with row"},
		{"id": "br_new_delhi_new_nizamuddin_bridge", "cc": "IN", "name": "New Nizamuddin Bridge", "wiki": "New Nizamuddin Bridge",
			"aliases": ["indo-japanese friendship bridge", "nizamuddin yamuna bridge", "indo japan friendship bridge"],
			"lat": 28.6011, "lon": 77.2631, "bearing": 62.9, "st": "girder",
			"spans": [42.0, 42.0, 42.0, 42.0, 42.0, 42.0, 42.0, 42.0, 42.0, 42.0, 42.0, 42.0, 42.0], "width": 22.6,
			"clear": 10.0, "material": "concrete", "base": "water", "tier": 3, "conf": 2,
			"src": "en Wikipedia (551.2 m, 13 spans of 42 m, 22.6 m wide, prestressed concrete); OSM way " +
				"76834891 via Nominatim (600 m with approaches, bearing 242.7 reversed to 62.7), Wikidata " +
				"coordinate ~100 m SW, midpoint used; clear estimated | verified: en Wikipedia (551.2 m, 13 " +
				"spans of 42 m, 22.6 m wide = 15 m carriageway + 2 x 3 m cycle tracks, T-girder prestressed " +
				"concrete); JICA basic design study map (openjicareport 11281789: Nizamuddin 4-lane L=550 m) " +
				"supports the ~550 m length; OSM ways 76834878/76834908/682964516 (600 m incl. approaches, " +
				"62.8-63.0 deg) and footway 767622261 (560 m, 63.0 deg, mid 28.60153,77.26297) re-measured, " +
				"centre of carriageways about 28.6011,77.2631"},
		{"id": "br_new_delhi_barapullah_bridge", "cc": "IN", "name": "Bara Pulah Bridge", "wiki": "Bara Pulah Bridge",
			"aliases": ["barapullah bridge", "barah pula bridge", "barapula bridge"], "lat": 28.5842, "lon": 77.25335,
			"bearing": 193.6, "st": "masonry",
			"spans": [18.2, 18.2, 18.2, 18.2, 18.2, 18.2, 18.2, 18.2, 18.2, 18.2, 18.2], "width": 14.0, "clear": 6.0,
			"rise": 2.5, "material": "stone", "base": "water", "tier": 3, "conf": 1,
			"src": "en Wikipedia (c.1612-1628 Mughal bridge, 200 m, 12 piers and 11 arches; coordinate " +
				"28.5841,77.2533); OSM footway way 1314555167 via Nominatim (147 m visible, bearing 193.6); " +
				"equal arches assumed, width, clear and rise estimated; crosses the Barapullah drain | " +
				"verified: en Wikipedia (12 piers, 11 arches, 200 m); ASI 'Delhi and its Neighbourhood' 2001 " +
				"via search (over 195 m long, 14 m wide; ASI board now about 100 m); ASI restoration 2024-26 " +
				"as pedestrian bridge; arch spans still unknown (equal arches only assumed); OSM footway " +
				"1314555167 147 m visible | round 2: round 2: no new source for arch spans"},
		{"id": "br_colombo_new_kelani_bridge", "cc": "LK", "name": "New Kelani River Bridge", "wiki": "New Kelani river bridge",
			"aliases": ["new kelani bridge", "kelani extradosed bridge"], "lat": 6.95473, "lon": 79.88254,
			"bearing": 40.1, "st": "extradosed", "spans": [100.0, 180.0, 100.0], "width": 30.4, "clear": 12.0,
			"tower": 35.4, "material": "concrete", "base": "water", "tier": 2, "conf": 2,
			"src": "JCI report/mageba refsheet via search (100+180+100 m extradosed, 30.4 m, pylon 23.4 m above " +
				"deck), OSM way 97904988 via Nominatim (bearing 41.0, centre 60 m from Wikipedia coordinate); " +
				"extradosed not representable; clear estimated | verified: mageba Kelani reference sheet " +
				"(main span 180 m, outer spans 100 m each, two pylons); JCI 2022 report (jci-net.or.jp nr2022 " +
				"26.pdf: PC 3-span continuous box girder extradosed, bridge length 380 m, spans 100+180+100 " +
				"m, width 30.4 m, girder depth 3.3-5.6 m, pylon height 23.4 m above deck); OCAJI package 2 " +
				"(380 m main bridge, 1185 m total); Wikipedia infobox 6.95483,79.88228; first pass used the " +
				"old A1 New Kelani Bridge way 97904988 (80 m off); OSM Golden Gate Kalyani ways 815688815/816 " +
				"re-measured: river water polygon crosses at 770-905 m along the way, midpoint " +
				"6.95473,79.88254, bearing 40.1; deck height above water estimated 12 m"},
		{"id": "br_male_sinamale_bridge", "cc": "MV", "name": "Sinamale Bridge", "wiki": "Sinamalé Bridge",
			"aliases": ["china maldives friendship bridge", "sinamale bridge male", "ސިނަމާލެ ބުރިޖު"], "lat": 4.17297,
			"lon": 73.52278, "bearing": 65.7, "st": "haunched", "spans": [100.0, 180.0, 180.0, 140.0, 100.0, 60.0],
			"width": 20.3, "clear": 13.0, "material": "concrete", "base": "sea", "tier": 2, "conf": 1, "legs": 40.0,
			"src": "en Wikipedia (1.39 km over water, 20.3 m wide), AidData/CHEC via search (760 m main bridge, " +
				"six-span hybrid girder V-frame); OSM way 1157988101 (1377 m, bearing 245.7 reversed to " +
				"65.7); six equal spans and clear are estimates | verified: IABSE Nantes 2018 paper abstract " +
				"via search (main bridge six-span continuous V-pier rigid frame, 100+2x180+140+100+60 = 760 " +
				"m, concrete/steel hybrid girder, V piers) and AidData/China Daily (760 m main bridge, three " +
				"V-shaped piers); en Wikipedia (1.39 km over water, 20.3 m wide); OSM way 1157988102 (1388 m, " +
				"65.7 deg, mid 4.17297,73.52278); position of the 760 m main bridge along the 1.39 km viaduct " +
				"and the order of the spans (Male end or Hulhumale end) are NOT sourced, V-leg run and clear " +
				"estimated | round 2: round 2: web search for the 760 m main bridge span order returned " +
				"nothing relevant; Male-end vs Hulhumale-end order and position along the viaduct unsourced"},
	]
