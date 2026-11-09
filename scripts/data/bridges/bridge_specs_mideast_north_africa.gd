class_name BridgeSpecsMideastNorthAfrica
extends RefCounted

## Capital bridge rows for the Middle East and North Africa (see BridgeSpec for the schema). Figures are
## sourced per row in `src`; conf 1 rows are kept as data but not built
## (BridgeSpec.MIN_BUILT_CONF).

static func rows() -> Array:
	return [
		{"id": "br_cairo_qasr_el_nil_bridge", "cc": "EG", "name": "Qasr El Nil Bridge", "wiki": "Qasr El Nil Bridge",
			"aliases": ["kasr el nil bridge", "khedive ismail bridge", "kobri qasr el nil"], "lat": 30.04372,
			"lon": 31.22994, "bearing": 83.1, "st": "arch_deck", "spans": [54.6, 54.6, 54.6, 54.6, 54.6, 54.6, 54.6],
			"width": 20.0, "clear": 10.0, "rise": 4.0, "material": "steel", "base": "water", "tier": 2, "conf": 1,
			"src": "en Wikipedia + egy.com (1933, 7 spans, 382 m, 20 m wide, 67 m swing section); OSM bearing " +
				"and centre; equal spans, clear, rise and arch type guessed; swing section and Gezira island " +
				"gap not modelled | verified: en Wikipedia/Structurae: swing bridge with arch spans, 1933; " +
				"egy.com: 382 m, 20 m wide, 67 m swing section, 7 or 8 spans (sources disagree); OSM ways " +
				"671616073/688630289 (457 m, brg 83.1, mid 30.04372,31.22994) confirmed; individual spans not " +
				"found | round 2: round 2: Spans not found; swing section not modelled."},
		{"id": "br_cairo_imbaba_bridge", "cc": "EG", "name": "Imbaba Bridge", "wiki": "Imbaba Bridge",
			"aliases": ["kobri imbaba", "imbaba railway bridge"], "lat": 30.07503, "lon": 31.22551, "bearing": 114.3,
			"st": "truss", "spans": [70.7, 70.7, 70.7, 70.7, 70.7, 70.7, 70.7], "width": 25.0, "clear": 12.0,
			"rise": 12.0, "material": "steel", "base": "water", "tier": 3, "conf": 1,
			"src": "en Wikipedia (1912-24 Baume-Marpent, 495 m), travel sources (6 fixed + 1 swing span), OSM " +
				"bearing/centre; equal spans, width, clear and truss height guessed; swing span, rail plus " +
				"cantilevered roadways not representable | verified: 1923 plan (INIST corpus): 490 m, seven " +
				"spans = six identical fixed spans + one swing span, ~20.2 m wide; Structurae: only railway " +
				"bridge; OSM ways 28829744 (rail, 501 m, brg 114.4, mid 30.07503,31.22551) and tertiary road " +
				"ways confirmed; swing span length unknown | round 2: round 2: Swing span length unknown; " +
				"rail plus cantilevered roadways."},
		{"id": "br_cairo_rod_el_farag_axis_bridge", "cc": "EG", "name": "Rod El Farag Axis Bridge", "wiki": "Rod El Farag Axis Bridge",
			"aliases": ["tahya misr bridge", "long live egypt bridge"], "lat": 30.1025, "lon": 31.2371,
			"bearing": 115.8, "st": "stayed", "spans": [120.0, 300.0, 120.0], "width": 67.3, "clear": 16.0,
			"tower": 92.0, "towers": [1, 2], "material": "concrete", "base": "water", "tier": 2, "conf": 2,
			"src": "en Wikipedia (540 m, 67.3 m wide, 92 m towers, 2019), PTI write-up (300 m main span, ~14 m " +
				"above river), OSM El-Dabaa Axis carriageways (centre, bearing); side spans split evenly; " +
				"tower height may be measured from the foundation | verified: en Wikipedia 540 m long, 67.3 m " +
				"wide (85 m at east side span), towers 92 m; Arab Contractors: navigation opening up to 300 " +
				"m, 400 m long and 14 m above water; side spans of 120 m are only the remainder of 540 m; OSM " +
				"El-Dabaa axis ways 777164352/777164356 confirmed | round 2: PTI Journal 2021 V17 N1 Award of " +
				"Excellence (post-tensioning.org PDF): total 540 m, main span 300 m composite steel girder, " +
				"continuous concrete box side spans 2 x 120 m, width 67 m at midspan (84 m at east entrance), " +
				"double H-shaped pylons 76 m above deck / 92 m above water => deck about 16 m above water; " +
				"Wikipedia 67.3 m width, Arab Contractors 14 m above river (clear set 16 from PTI). OSM El- " +
				"Dabaa Axis ways 777164352 (618 m, brg 295.4 reverse 115.4, mid 30.10273,31.23711) and " +
				"777164356 (531 m, brg 116.5, mid 30.10235,31.23706) re-measured: centre and bearing agree. " +
				"Pylons are twin H frames, modelled as stayed with default portal pylons."},
		{"id": "br_baghdad_14th_of_july_bridge", "cc": "IQ", "name": "14th of July Bridge", "wiki": "14th of July Bridge",
			"aliases": ["jisr 14 tammuz", "july 14 bridge"], "lat": 33.296, "lon": 44.3999, "bearing": 352.5,
			"st": "susp", "spans": [83.82, 167.64, 83.82], "width": 20.0, "clear": 12.0, "tower": 45.0,
			"material": "steel", "base": "water", "tier": 2, "conf": 1,
			"src": "en Wikipedia + Bridgemeister (self-anchored, 83.8+167.6+83.8 m, 1964), OSM bearing; width, " +
				"clear and tower height guessed | verified: en Wikipedia/Structurae: self-anchored " +
				"suspension, 167.64 m with 83.82 m side spans, Steinman design; width and tower height not " +
				"found; OSM ways 4082481/4082482 (668 m, brg 352.6) confirmed | round 2: round 2: Search: " +
				"spans 83.82+167.64+83.82 (Wikipedia, Bridgemeister); no width or tower height."},
		{"id": "br_baghdad_al_aimmah_bridge", "cc": "IQ", "name": "Al-Aimmah Bridge", "wiki": "Al-Aimmah Bridge",
			"aliases": ["adhamiyah bridge", "jisr al-aimma"], "lat": 33.37496, "lon": 44.35535, "bearing": 127.8,
			"st": "stayed", "spans": [66.25, 182.5, 60.0, 61.25], "width": 29.5, "clear": 12.0, "tower": 67.7,
			"towers": [1], "pylon": "single", "material": "steel", "base": "water", "tier": 2, "conf": 1,
			"src": "Structurae snippet (66.25+182.5+60+61.25 m, 370 m, 29.5 m wide, pylon 55.7 m), en Wikipedia " +
				"(21 m wide), OSM bearing; pylon position among the spans and clear guessed | verified: en " +
				"Wikipedia: cable-stayed, 4 spans, main 182.5 m, 370 m, 21 m wide, pylon 55.7 m; Structurae: " +
				"29.5 m wide; OSM way 4295613 (721 m, brg 128.0, mid 33.37496,44.35535) confirmed; pylon " +
				"position and widths disagree | round 2: round 2: Structurae snippet confirms spans " +
				"66.25+182.5+60+61.25, width 29.5 m (2 x 10.5 m), pylon 55.7 m, harp (en Wikipedia 21 m). " +
				"Still unknown: which support carries the pylon (likely support 2, end of the 182.5 m span, " +
				"if the 60+61.25 spans are the back spans) and the deck height; unchanged."},
		{"id": "br_baghdad_al_sarafiya_bridge", "cc": "IQ", "name": "Al-Sarafiya Bridge", "wiki": "Al-Sarafiya Bridge",
			"aliases": ["sarafiya bridge", "jisr al-sarafiya"], "lat": 33.35369, "lon": 44.37263, "bearing": 94.4,
			"st": "arch_tied", "spans": [150.0, 150.0, 150.0], "width": 14.0, "clear": 12.0, "rise": 25.0,
			"material": "steel", "base": "water", "tier": 2, "conf": 1,
			"src": "en Wikipedia (rebuilt, reopened 2008), Structurae (steel tied arch, 1941), blog (~450 m); " +
				"OSM bearing/centre; spans, width, clear and rise all guessed | verified: en Wikipedia: " +
				"rebuilt 2008 after the 2007 collapse; OSM way 4493480 (706 m, brg 94.4) confirmed; no " +
				"dimensions found | round 2: round 2: No dimensions found."},
		{"id": "br_tehran_tabiat_bridge", "cc": "IR", "name": "Tabiat Bridge", "wiki": "Tabiat Bridge",
			"aliases": ["pol-e tabiat", "nature bridge"], "lat": 35.7542, "lon": 51.4202, "bearing": 265.1,
			"st": "truss", "spans": [68.0, 94.0, 68.0, 39.0], "width": 9.5, "clear": 10.0, "rise": 4.0,
			"material": "steel", "base": "ground", "tier": 2, "conf": 1,
			"src": "en Wikipedia (270 m), Divisare (68+94+68+39 m east to west, width 6-13 m), OSM way " +
				"bearing/centre (Wikipedia list lon 51.354 is wrong, article 51.4205 is right); clear and " +
				"truss depth guessed; curved three-level space truss on tree columns not representable | " +
				"verified: en Wikipedia 270 m; Divisare spans 68+94+68+39; OSM way 327418796 (272 m, brg 85.1 " +
				"or 265.1) confirmed; curved three-level space truss not representable | round 2: round 2: " +
				"Curved space truss not representable."},
		{"id": "br_jerusalem_chords_bridge", "cc": "IL", "name": "Chords Bridge", "wiki": "Chords Bridge",
			"aliases": ["bridge of strings", "gesher hamitarim", "jerusalem chords bridge"], "lat": 31.78837,
			"lon": 35.20035, "bearing": 56.0, "st": "stayed", "spans": [160.0, 40.0], "width": 14.82, "clear": 8.0,
			"tower": 118.0, "towers": [1], "pylon": "single", "material": "steel", "base": "ground", "tier": 2,
			"conf": 1,
			"src": "en Wikipedia + Structurae snippet (160 m span, 360 m total, 14.82 m wide, 118 m mast), OSM " +
				"light-rail way bearing; tilted side-spar mast is not on the centre line, back span and clear " +
				"guessed | verified: en Wikipedia: side-spar cable-stayed, 160 m main span, 118 m mast, 14.82 " +
				"m wide; OSM ways 75517167/255019640 (200-209 m, brg 55.9, mid 31.78836,35.20044) confirmed; " +
				"tilted mast off the axis and back span not representable | round 2: round 2: Tilted mast off " +
				"axis not representable."},
		{"id": "br_amman_abdoun_bridge", "cc": "JO", "name": "Abdoun Bridge", "wiki": "Abdoun Bridge",
			"aliases": ["wadi abdoun bridge", "kamal shair bridge"], "lat": 31.95156, "lon": 35.89456, "bearing": 38.6,
			"st": "stayed", "spans": [63.0, 132.0, 132.0, 63.0, 27.0], "width": 20.0, "clear": 45.0, "tower": 105.0,
			"towers": [1, 2, 3], "material": "concrete", "base": "ground", "tier": 2, "conf": 1,
			"src": "en Wikipedia + list (417 m, 2 main spans 132-134 m, 3 Y pylons, 45 m clearance), L&T (60 m " +
				"pylons), OSM Queen Noor Street bearing; side spans, width, pylon height above water guessed " +
				"| verified: en Wikipedia: cable-stayed, 417 m, two main spans ~132-134 m, three Y pylons, 45 " +
				"m clearance; OSM way 150411216 (463 m, brg 38.4, mid 31.95154,35.89461) confirmed; side " +
				"spans, width and pylon height not found | round 2: round 2: Side spans, width and pylon " +
				"height not found."},
		{"id": "br_amman_ten_arches_bridge", "cc": "JO", "name": "Ten Arches Bridge", "wiki": "Ten Arches Bridge",
			"aliases": ["al josour al ashara", "jisr al ashara"], "lat": 31.93928, "lon": 35.95597, "bearing": 0.5,
			"st": "masonry", "spans": [7.941, 7.941, 7.941, 7.941, 7.941, 7.941, 7.941, 7.941, 7.941, 7.941],
			"width": 3.8, "clear": 14.5, "rise": 6.0, "material": "stone", "base": "ground", "tier": 3, "conf": 1,
			"src": "en Wikipedia (79.41 m, 3.8 m wide, 14.5 m high, 10 upper / 8 lower arches, 1904), OSM way; " +
				"two-tier arcade modelled as one tier, rise guessed | verified: en Wikipedia: viaduct 79.41 " +
				"m, 3.8 m wide, 14.5 m high, ten upper and eight lower limestone arches, main span 8.15 m " +
				"(more than the 7.94 m pitch of the row); OSM way 149945677 (82 m, brg 0.5) confirmed | round " +
				"2: round 2: Two-tier arcade; main span 8.15 m vs 7.94 pitch; not retried."},
		{"id": "br_abu_dhabi_sheikh_zayed_bridge", "cc": "AE", "name": "Sheikh Zayed Bridge", "wiki": "Sheikh Zayed Bridge",
			"aliases": ["sheikh zayed bridge abu dhabi"], "lat": 24.42418, "lon": 54.48532, "bearing": 99.5,
			"st": "arch_through", "spans": [235.0], "width": 61.0, "clear": 15.0, "rise": 45.0, "material": "steel",
			"base": "sea", "tier": 1, "conf": 1,
			"src": "en Wikipedia (842 m, principal arch 235 m, ~60 m above water), web snippets (61 m wide), OSM " +
				"carriageway bearing; wave-shaped multi-arch deck simplified to one arch, clear and rise " +
				"guessed | verified: en Wikipedia: 842 m, wave-shaped arches (Zaha Hadid), principal arch 235 " +
				"m, 61 m wide; OSM ways 407685949/91207495 (890 m, brg 99.5 or 279.6, mid 24.42402,54.48529) " +
				"confirmed | round 2: round 2: Wave-shaped multi-arch not representable by one arch."},
		{"id": "br_rabat_mohammed_vi_bridge", "cc": "MA", "name": "Mohammed VI Bridge", "wiki": "Mohammed VI Bridge",
			"aliases": ["pont mohammed vi", "bouregreg bridge"], "lat": 33.93904, "lon": -6.75961, "bearing": 0.6,
			"st": "stayed", "spans": [183.0, 376.0, 183.0], "width": 30.4, "clear": 100.0, "tower": 192.0,
			"towers": [1, 2], "material": "concrete", "base": "water", "tier": 2, "conf": 2,
			"src": "en Wikipedia + list (183+376+183 m, 952 m with approaches, 30 m wide, towers 197.45 m, " +
				"opened 2016), OSM carriageways bearing/centre; deck height taken from infobox clearance " +
				"below 100 m (uncertain) | verified: Structurae (fr) and Wikipedia list: three-span semi-harp " +
				"cable-stayed, 183+376+183 m, total 951.66-954.3 m, 30.40 m wide, pylons 197.45 / 186.06 m; " +
				"Terrasol sheet and en infobox: deck ~100 m high (reference level unclear); OSM ways " +
				"289729592/289729595 (958 m viaduct, brg 0.6) carry the whole 952 m structure, but the OSM " +
				"pylon pier way 430532993 (height 200, 33.94073,-6.75979) is 320 m north of the way centre, " +
				"so the stayed chain (pylons 376 m apart, mid 33.93904) is shifted ~130 m north of the first- " +
				"pass centre; Bouregreg river crosses the way 220 m from its north end"},
		{"id": "br_tunis_rades_la_goulette_bridge", "cc": "TN", "name": "Rades-La Goulette Bridge", "wiki": "Radès–La Goulette bridge",
			"aliases": ["rades la goulette bridge", "pont de rades la goulette"], "lat": 36.8074, "lon": 10.26079,
			"bearing": 174.8, "st": "extradosed", "spans": [70.0, 120.0, 70.0], "width": 23.5, "clear": 20.0,
			"tower": 45.0, "towers": [1, 2], "material": "concrete", "base": "water", "tier": 2, "conf": 2,
			"src": "en Wikipedia (70+120+70 m, 23.5 m wide, deck 20 m, towers 45 m, 2009), OSM bearing/centre; " +
				"extradosed design not representable as a stayed bridge | verified: Terrasol project sheet " +
				"and Wikipedia list: three-span continuous extradosed concrete box girder 70+120+70 m (260 " +
				"m), balanced cantilever; en infobox 23.5 m wide (webmanagercenter 23 m); MEED: 20 m " +
				"clearance over the La Goulette canal; techno-science: deck 20 m above sea level held by two " +
				"towers 45 m high; OSM way 177034410 (978 m viaduct, N to S, brg 174.9) crosses the La " +
				"Goulette canal water polygon between 365 and 555 m from its north end, so the 260 m " +
				"extradosed chain centre moved ~30 m north of the way centre to 36.8074,10.26079"},
	]
