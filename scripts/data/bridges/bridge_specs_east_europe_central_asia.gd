class_name BridgeSpecsEastEuropeCentralAsia
extends RefCounted

## Capital bridge rows for Eastern Europe and Central Asia (see BridgeSpec for the schema). Figures are
## sourced per row in `src`; conf 1 rows are kept as data but not built
## (BridgeSpec.MIN_BUILT_CONF).

static func rows() -> Array:
	return [
		{"id": "br_kyiv_paton_bridge", "cc": "UA", "name": "Paton Bridge", "wiki": "Paton Bridge",
			"aliases": ["міст патона", "paton bridge kyiv", "evgeny paton bridge"], "lat": 50.42724, "lon": 30.58208,
			"bearing": 65.2, "st": "girder",
			"spans": [17.5, 58.0, 58.0, 58.0, 58.0, 58.0, 58.0, 58.0, 58.0, 58.0, 58.0, 58.0, 87.0, 87.0, 87.0, 87.0, 58.0, 58.0, 58.0, 58.0, 58.0, 58.0, 58.0, 58.0, 58.0, 17.5],
			"width": 27.5, "clear": 18.0, "material": "steel", "base": "water", "tier": 2, "conf": 2,
			"src": "en Wikipedia (1543 m, all-welded steel) + Structurae via search snippet (26 spans: 2x17.5, " +
				"20x58, 4x87; width 28 m) + Kyivrada (deck 18 m over water); OSM way centre/bearing; " +
				"arrangement of the 87 m spans in the middle assumed symmetrical | verified: Paton Welding " +
				"Journal 2021 no.7 (Poznyakov et al., patonpublishinghouse.com): total 1542.2 m, right bank " +
				"2x5x58, navigable 58+4x87+58, left bank 2x4x58 (plus 2x17.5 end spans = 1543 m, Structurae); " +
				"uk Wikipedia: 26 spans, 29 m blocks, carriageway 21 m + 2x3 m footways (Structurae 28 m); " +
				"OSM ways 9451696/45985363 centre 50.42724,30.58208 brg 65.2 (1544 m) confirmed; right bank " +
				"(west) end first; deck height 18 m from en infobox clearance_below only"},
		{"id": "br_moscow_bolshoy_kamenny", "cc": "RU", "name": "Bolshoy Kamenny Bridge", "wiki": "Bolshoy Kamenny Bridge",
			"aliases": ["большой каменный мост", "great stone bridge moscow", "bolshoi kamenny bridge"], "lat": 55.7466,
			"lon": 37.61225, "bearing": 155.2, "st": "arch_deck", "spans": [42.5, 105.0, 42.5], "width": 40.0,
			"clear": 10.0, "rise": 8.4, "material": "steel", "base": "water", "tier": 2, "conf": 2,
			"src": "en Wikipedia + Structurae via search snippet (1938 bridge: six parallel steel box arches, " +
				"105 m main arch, two 42.5 m side arches, 40 m wide, 487 m with ramps); OSM carriageway " +
				"bearing 155.2, centre agrees with Wikipedia coordinate within 20 m; clear and rise estimated " +
				"| verified: en Wikipedia: 105 m main arch 8.4 m high, two 42.5 m embankment side arches, six " +
				"parallel box arches, 40 m wide, 487 m with ramps; ru Wikipedia infobox 105 m / 487 m / 40 m; " +
				"OSM way 25132487 (474 m incl. ramps) mid 55.74653,37.61228 brg 155.2 agrees with row"},
		{"id": "br_kyiv_pivnichnyi_bridge", "cc": "UA", "name": "Pivnichnyi Bridge", "wiki": "Pivnichnyi Bridge",

			"aliases": ["північний міст", "moskovskyi bridge", "moscow bridge kyiv", "north bridge kyiv", "московський міст"],
			"lat": 50.490779, "lon": 30.536351, "bearing": 64.5, "st": "stayed",
			"spans": [42.0, 63.0, 63.0, 63.0, 63.0, 63.63, 300.0, 84.51], "width": 31.4, "clear": 20.0, "tower": 119.0,
			"towers": [7], "pylon": "portal", "material": "steel", "base": "water", "tier": 2, "conf": 2,
			"src": "en Wikipedia (cable-stayed 1976, A-pylon 119 m on Trukhaniv Island, 816 m Dnipro section, " +
				"31.4 m wide) + Structurae via search snippet (spans 84.51-300-63.63-4x63-42, pylon 125 m in " +
				"table); OSM way bearing 64.5 and centre agree with Wikipedia coordinate; pylon assumed at " +
				"east end of the 300 m span (on the island), span order along the bearing inferred; clear " +
				"estimated | verified: uk Wikipedia: single-pylon cable-stayed, 300 m stayed span, 816 m " +
				"Dnipro section, 31.4 m wide, 119 m A-pylon, right-bank part is a flyover with 63 m spans; en " +
				"Wikipedia: pylon on Trukhaniv Island; Structurae snippet gives the span list " +
				"84.51-300-63.63-4x63-42; OSM way 23145427 (West to East, 50.48912,30.53090 -> " +
				"50.49218,30.54096, ~790 m, brg 64.5, centre 50.49065,30.53593) ends at the Trukhaniv west " +
				"shore, so the pylon is at the EAST end of the 300 m span and the list runs east to west; " +
				"order reversed to west to east | placement: centre moved +33 m along the deck onto the " +
				"middle of the mapped water crossing (offset measured in the bundled OSM snapshot)"},
		{"id": "br_kyiv_pivdennyi_bridge", "cc": "UA", "name": "Pivdennyi Bridge", "wiki": "Pivdennyi Bridge (Kyiv)",
			"aliases": ["південний міст", "south bridge kyiv", "southern bridge kyiv"], "lat": 50.39481, "lon": 30.5888,
			"bearing": 94.6, "st": "stayed",
			"spans": [80.5, 90.0, 271.0, 63.0, 60.0, 58.7, 79.0, 79.0, 79.0, 79.0, 79.0, 79.0, 79.0, 50.5],
			"width": 41.5, "clear": 21.2, "tower": 140.0, "towers": [2], "pylon": "portal", "material": "concrete",
			"base": "water", "tier": 2, "conf": 1,
			"src": "en Wikipedia (metro/road bridge 1990, 135 m concrete pylon) + Structurae via search snippet " +
				"(14 spans 80.5-90-271-63-60-58.7-7x79-50.5, 41.5 m wide); OSM way bearing 94.6; conf 1 " +
				"because a metro deck shares the structure, which side the pylon stands on is not known and " +
				"clear/tower above water are guesses | verified: uk Wikipedia: 1256 m, main span 270-271 m, " +
				"41 m wide, pylon 133-135 m, road surface 21.2 m over water, metro line on the bridge; OSM " +
				"way 756191580 (1195 m, brg 94.6, mid 50.39481,30.58880) agrees; span order along the bearing " +
				"still unverified | round 2: round 2: uk Wikipedia raw: 1256 m, main span 270, width 41 m, " +
				"pylon 133 m, deck 21.2 m over water, 'a precast beam flyover leads from the right (west) " +
				"bank to the 271 m navigation span' (consistent with spans 80.5+90 then 271 along bearing " +
				"94.6). Searches found no source for which side of the 271 span the single pylon stands on " +
				"(row has towers [2] = west end of the main span) nor the east spans; so unchanged."},
		{"id": "br_kyiv_metro_bridge", "cc": "UA", "name": "Kyiv Metro Bridge", "wiki": "Kyiv Metro Bridge",
			"aliases": ["міст метро", "metro bridge kyiv", "moscow metro bridge kyiv"], "lat": 50.44258,
			"lon": 30.56442, "bearing": 66.2, "st": "girder", "spans": [114.0, 114.0, 114.0, 114.0, 114.0, 114.0],
			"width": 28.9, "clear": 20.0, "material": "concrete", "base": "water", "tier": 2, "conf": 1,
			"src": "en Wikipedia (683 m long, 28.9 m wide, 20 m above the river, two parts via Venetsiiskyi " +
				"Island); OSM way bearing 66.2; conf 1: metro deck dominates, arched contour, true span " +
				"layout not found so equal spans were assumed | verified: uk Wikipedia: arch-cantilever " +
				"concrete, six spans of 117 and 87 m plus two incomplete end spans, 682.64 m, 28 m wide, " +
				"metro deck 9.4 m + 2x7 m roads; individual span order not given; OSM geometry not re- " +
				"measured (API rate limit) | round 2: round 2: uk sites (kyivpastfuture, vandrivka, bigkyiv): " +
				"six arch-cantilever spans of 117 and 87 m plus two incomplete end spans, 682.64 m, 28 m; " +
				"order and structure type (arch vs haunched box) unresolved; an oktv page says main span 143 " +
				"m."},
		{"id": "br_yerevan_victory_bridge", "cc": "AM", "name": "Victory Bridge", "wiki": "Victory Bridge, Yerevan",
			"aliases": ["haghtanak bridge", "հաղթանակի կամուրջ", "victory bridge yerevan"], "lat": 40.17479,
			"lon": 44.49971, "bearing": 135.6, "st": "arch_deck", "spans": [27.0, 27.0, 27.0, 27.0, 27.0, 27.0, 27.0],
			"width": 25.0, "clear": 34.0, "rise": 10.0, "material": "concrete", "base": "water", "tier": 2, "conf": 1,
			"src": "Armeniapedia/visityerevan (200 m, 25 m wide, 34 m high), en Wikipedia mirror (seven arches), " +
				"OSM snapshot way (189 m, bearing 135.6); conf 1: arch layout, rise and deck height over the " +
				"Hrazdan not found, equal spans assumed | verified: Wikipedia, visityerevan, Structurae " +
				"snippet: 200 m, 25 m wide, 34 m high, seven arches faced in basalt, reinforced concrete; " +
				"arch layout (main triple arch on two triple props) unclear; OSM ways 474678584/483000270 " +
				"(190/169 m, brg 135) agree with centre | round 2: round 2: Not retried; arch layout (triple " +
				"arch on triple props) unresolved from round 1."},
		{"id": "br_moscow_krymsky_bridge", "cc": "RU", "name": "Krymsky Bridge", "wiki": "Krymsky Bridge",
			"aliases": ["крымский мост", "crimean bridge moscow", "crimea bridge moscow"], "lat": 55.73392,
			"lon": 37.599, "bearing": 120.3, "st": "susp", "spans": [47.25, 168.0, 47.25], "width": 38.4, "clear": 10.0,
			"tower": 39.0, "material": "steel", "base": "water", "tier": 2, "conf": 2,
			"src": "en Wikipedia + Structurae/Monash/mageba sheet via search snippets (168 m main span, 688 m " +
				"with approaches, 38.4 m wide, 262.5 m suspended deck, pylons 28.7 m); side spans = " +
				"(262.5-168)/2; OSM way 538432984 bearing 120.3, centre agrees with Wikipedia coordinate " +
				"within 30 m; clear and tower-over-water estimated | verified: en Wikipedia explicitly: 47.25 " +
				"+ 168 + 47.25 m, 262.5 m bridge, 668 m with ramps, 38.4 m wide (24.5 carriageway + 3.9 + " +
				"2x5); ru Wikipedia: pylons 27 m, chains 297 m, three spans; OSM way 538432984 (252 m, brg " +
				"120.3, mid 55.73392,37.59900) confirmed"},
		{"id": "br_moscow_bolshoy_ustinsky", "cc": "RU", "name": "Bolshoy Ustinsky Bridge", "wiki": "Bolshoy Ustinsky Bridge",
			"aliases": ["большой устьинский мост", "ustinsky bridge moscow", "bolshoi ustinsky bridge"],
			"lat": 55.74704, "lon": 37.63875, "bearing": 38.5, "st": "arch_deck", "spans": [50.5, 134.0, 50.5],
			"width": 40.0, "clear": 11.0, "rise": 8.95, "material": "steel", "base": "water", "tier": 2, "conf": 2,
			"src": "Structurae via search snippet (1938 steel arch bridge, six parallel arches 50.5+134+50.5 m, " +
				"40 m wide, 478 m with ramps; deck replaced 1999-2000, arches kept) + all-andorra (arch rise " +
				"8.95 m); OSM way 161280352 (240 m = the three spans) bearing 38.5 and centre; clear " +
				"estimated, side-span rise assumed equal to the main arch | verified: en Wikipedia: span " +
				"formula 50.5+134.0+50.5 m, six parallel steel arches, 40 m wide, 478 m long; ru Wikipedia: " +
				"134 m main arch, rise 8.95 m, 40.0 m wide, single-span arch type; OSM way 161280352 (240 m, " +
				"brg 38.5, mid 55.74704,37.63875) confirmed"},
		{"id": "br_moscow_novospassky_bridge", "cc": "RU", "name": "Novospassky Bridge", "wiki": "Novospassky Bridge",
			"aliases": ["новоспасский мост", "novospassky most"], "lat": 55.72869, "lon": 37.65389, "bearing": 52.0,
			"st": "girder", "spans": [44.46, 52.37, 44.46], "width": 24.4, "clear": 9.0, "material": "steel",
			"base": "water", "tier": 3, "conf": 2,
			"src": "en Wikipedia mirrors (rebuilt c.2000 as plate-girder spans 44.46+52.37+44.46 m, 24.4 m wide, " +
				"502 m with ramps); OSM way 160412247 bearing 52.0, centre of the carriageway way (ramps " +
				"included, river span in its middle); clear estimated, figures come from Wikipedia-derived " +
				"text only | verified: ru Wikipedia: three-span steel beam, 44.46+52.37+44.46 m (since 2000), " +
				"24.4 m wide, 502 m total, navigation clearance 8.6 m; en Wikipedia same; OSM way 160412247 " +
				"(301 m incl ramps, brg 52.0, mid 55.72868,37.65389) confirmed"},
		{"id": "br_moscow_borodinsky_bridge", "cc": "RU", "name": "Borodinsky Bridge", "wiki": "Borodinsky Bridge",
			"aliases": ["бородинский мост", "borodino bridge moscow"], "lat": 55.7454, "lon": 37.57337, "bearing": 87.5,
			"st": "girder", "spans": [40.9, 45.5, 40.9], "width": 42.6, "clear": 9.0, "material": "steel",
			"base": "water", "tier": 3, "conf": 2,
			"src": "en Wikipedia + Structurae snippets (1912 piers 40.9+45.5+40.9 m, widened to 42.6 m in 1952, " +
				"arches/deck replaced by a plate-girder structure in 2001); OSM footway way 112394485 bearing " +
				"87.5; conf 1: current spans assumed to follow the retained piers, clear estimated | " +
				"verified: ru Wikipedia: three-span steel beam bridge on the retained 1912 piers, spans " +
				"40.9+45.5+40.9 m (main span 45.5 m), width 42.6 m since 1952, rebuilt as orthotropic plate " +
				"girder in 1999-2001 with arch-shaped fascias; en Wikipedia same; OSM carriageway ways " +
				"28673852/23387630 (347-349 m, brg 87.6/267.6, mid 55.74533-55.74547, 37.57336) and footways; " +
				"centre set to the mean of the carriageway and footway ways"},
		{"id": "br_moscow_patriarshy_bridge", "cc": "RU", "name": "Patriarshy Bridge", "wiki": "Patriarshy Bridge",
			"aliases": ["патриарший мост", "patriarchy bridge moscow", "patriarshiy bridge"], "lat": 55.74355,
			"lon": 37.60823, "bearing": 123.6, "st": "girder", "spans": [49.0, 105.0, 49.0], "width": 10.0,
			"clear": 9.0, "material": "steel", "base": "water", "tier": 3, "conf": 1,
			"src": "en Wikipedia + search snippets (2004 steel box footbridge, first part 203 m, 10 m wide, very " +
				"shallow steel box arch with decorative lattice); OSM footway way 19028223 bearing 123.6 (235 " +
				"m incl. canal part); conf 1: span split (105 m centre) is a guess, shallow arch modelled as " +
				"girder | verified: ru Wikipedia: single-span balanced-cantilever footbridge decorated as an " +
				"arch, 203 m long, span 105 m, navigation width 54 m, height of span in the navigation " +
				"channel 12.5 m; OSM way 19028223 (235 m, brg 123.6) confirmed; side spans 49 m are only the " +
				"remainder of 203 m; would suit st haunched | round 2: round 2: ru Wikipedia raw: single-span " +
				"balanced cantilever, 203 m long, 105 m span, 54 m navigation width, 12.5 m high (source is a " +
				".ru site cruiseinform, not used); side-span layout and deck width not stated."},
		{"id": "br_moscow_bagration_bridge", "cc": "RU", "name": "Bagration Bridge", "wiki": "Bagration Bridge",
			"aliases": ["мост багратион", "bagration pedestrian bridge"], "lat": 55.74731, "lon": 37.54504,
			"bearing": 327.1, "st": "truss", "spans": [214.0], "width": 16.0, "clear": 14.0, "rise": 12.0,
			"material": "steel", "base": "water", "tier": 3, "conf": 1,
			"src": "en Wikipedia + travel-site snippets (1997 two-level glazed pedestrian bridge, 214 m, 16 m " +
				"wide, ~14 m above the river; closed for repair 2025-26); OSM way 23370355 bearing 327.1 (214 " +
				"m); conf 1: span arrangement, structure and height guessed | verified: ru Wikipedia: steel " +
				"truss of triangular cross-section 147+49 m long, 12 m high, 214 m total length, 16 m wide, " +
				"14 m over the Moskva, two-level glazed gallery; OSM way 23370355 (214 m, brg 327.1) " +
				"confirmed; truss enclosed by glazing and the 147/49 split plus end part are not " +
				"representable | round 2: round 2: Enclosed truss, 147+49 m not representable."},
		{"id": "br_tbilisi_bridge_of_peace", "cc": "GE", "name": "Bridge of Peace", "wiki": "Bridge of Peace",
			"aliases": ["მშვიდობის ხიდი", "peace bridge tbilisi", "mshvidobis khidi"], "lat": 41.69298, "lon": 44.80826,
			"bearing": 267.4, "st": "truss", "spans": [115.0, 36.0], "width": 5.6, "clear": 8.0, "rise": 6.0,
			"material": "steel", "base": "water", "tier": 2, "conf": 1,
			"src": "en Wikipedia (2010 pedestrian bridge, ~150 m, ~5 m wide, steel and glass canopy shell by De " +
				"Lucchi) + OSM ways 125589004 (115 m) and 784030759 (36 m), bearing 267.4; conf 1: glass " +
				"shell cannot be represented, span split follows the OSM ways, height guessed | verified: " +
				"Wikipedia, Structurae, Cimolai: steel and glass shell, 150-160 m, footbridge 2.4-4.8 m wide " +
				"with 12-22 m roof, 115 m roof section; OSM ways 125589004/784030759 confirmed; width and " +
				"span split not agreed between sources | round 2: round 2: Glass shell not representable; " +
				"sources disagree on width."},
		{"id": "br_tbilisi_baratashvili_bridge", "cc": "GE", "name": "Baratashvili Bridge", "wiki": "Baratashvili Bridge",
			"aliases": ["ბარათაშვილის ხიდი", "nikoloz baratashvili bridge", "metekhi bridge tbilisi"], "lat": 41.69683,
			"lon": 44.80828, "bearing": 82.8, "st": "girder", "spans": [37.0, 76.0, 37.0], "width": 22.0, "clear": 9.0,
			"material": "concrete", "base": "water", "tier": 3, "conf": 1,
			"src": "en Wikipedia (1966 cantilever bridge, 150 m) + Tbilisi Architecture Archive snippet (three " +
				"spans on two piers); OSM ways 78333943/28357360 (133 m) bearing 82.8; conf 1: span split, " +
				"width and clear guessed | verified: en Wikipedia 150 m cantilever 1966; Tbilisi Architecture " +
				"Archive designers Kavlashvili/Kurtishvili/Kartsivadze; OSM ways 78333943/28357360 (133 m, " +
				"brg 82.8) confirmed; no span or width figures found | round 2: round 2: No span or width " +
				"figures found; not retried."},
		{"id": "br_yerevan_davtashen_bridge", "cc": "AM", "name": "Davtashen Bridge", "wiki": "Davtashen Bridge",
			"aliases": ["դավթաշենի կամուրջ", "davtashen bridge yerevan"], "lat": 40.20922, "lon": 44.4936,
			"bearing": 145.9, "st": "girder", "spans": [48.0, 80.0, 80.0, 80.0, 64.0], "width": 32.0, "clear": 92.0,
			"material": "steel", "base": "ground", "tier": 2, "conf": 2,
			"src": "en Wikipedia list of bridges in Armenia (steel beam, orthotropic deck, 48+3x80+64 m, twin " +
				"bridges, 496 m total, 32 m wide) + Wikipedia infobox (92 m above the Hrazdan); OSM way " +
				"41261023 (496 m, w=32) bearing 145.9, centre = way centre (gorge section assumed mid-way); " +
				"deck height from Wikipedia, base ground because the span is over a deep gorge | verified: en " +
				"Wikipedia: 496 m, 32 m wide, 92 m above the Hrazdan; Wikipedia list of bridges in Armenia: " +
				"steel beam, orthotropic deck, 48+3x80+64 m twin bridges; OSM way 41261023 (496 m, w=32, brg " +
				"145.9) confirmed; the Hrazdan crosses the way 292 m from its NW end (way centre 248 m), so " +
				"the 352 m steel chain (river under the middle 80 m span) is centred ~300 m along the way, " +
				"moved 50 m SE of the way centre"},
		{"id": "br_ulaanbaatar_yarmag_bridge", "cc": "MN", "name": "Yarmag Bridge", "wiki": "Yarmag Bridge",
			"aliases": ["ярмагийн гүүр"], "lat": 47.88736, "lon": 106.86409, "bearing": 179.2, "st": "girder",
			"spans": [25.0, 25.0, 25.0, 25.0, 25.0, 25.0, 25.0, 25.0, 25.0, 25.0], "width": 20.5, "clear": 7.0,
			"material": "concrete", "base": "water", "tier": 3, "conf": 1,
			"src": "en Wikipedia + UB Post snippets (new bridge opened 2 Nov 2018, 250.2 m, 20.5 m wide, 77 " +
				"precast box girders, beside the old Yarmag bridge); OSM Chinggis Avenue ways " +
				"28937449/653884076 (258 m) bearing 179.2; conf 1: span layout, clear guessed (equal 25 m " +
				"spans), whether the 20.5 m is the new bridge alone is unclear | verified: en Wikipedia/UB " +
				"Post: 250.2 m, 20.5 m wide, precast box girders; OSM ways 28937449/653884076 (258-261 m, brg " +
				"179.2) confirmed; span layout not found | round 2: round 2: No span layout found."},
		{"id": "br_moscow_smolensky_metro_bridge", "cc": "RU", "name": "Smolensky Metro Bridge", "wiki": "Smolensky Metro Bridge",
			"aliases": ["смоленский метромост", "smolensky metro bridge moscow"], "lat": 55.74818, "lon": 37.57431,
			"bearing": 85.2, "st": "arch_through", "spans": [19.225, 20.5, 19.225, 150.0, 19.225, 19.225],
			"width": 12.0, "clear": 9.0, "rise": 11.0, "material": "steel", "base": "water", "tier": 3, "conf": 1,
			"src": "en Wikipedia + Structurae snippet (1937 metro bridge, two 150 m steel arches 11 m high, " +
				"19.2-20.5 m concrete arches either side) + OSM subway ways 98180710 (287 m) bearing 85.2, " +
				"Wikipedia coordinate shifted 10 m so the chain centre is correct; conf 1: rail-only bridge, " +
				"order of the small spans along the bearing unknown, deck width and clear estimated | " +
				"verified: ru Wikipedia: two 150 m steel arches (rise 11.04 m, 9.5 m apart) plus five " +
				"reinforced concrete arches, full formula 19.225+20.5+19.225+150.0+19.225+19.225 m; OSM " +
				"subway way 98180710 (287 m, brg 85.2, mid 55.74818,37.57446) confirmed; formula direction vs " +
				"bearing and deck width not given | round 2: round 2: ru Wikipedia raw: formula " +
				"19.225+20.5+19.225+150+19.225+19.225, track gap 3.55 m, arches 9.5 m apart, rise 11.04 m, " +
				"Smolenskaya (east, left-bank) approach built into a substation; but formula direction vs " +
				"bearing 85.2 not stated and deck width not given."},
		{"id": "br_astana_qaraotkel_bridge", "cc": "KZ", "name": "Qaraötkel Bridge", "wiki": "Qaraötkel Bridge",
			"aliases": ["karaotkel bridge", "ramstore bridge", "ramstor bridge", "қараөткел көпірі"], "lat": 51.15181,
			"lon": 71.42815, "bearing": 220.3, "st": "arch_tied", "spans": [180.0], "width": 50.0, "clear": 8.0,
			"rise": 60.0, "material": "steel", "base": "water", "tier": 2, "conf": 1,
			"src": "en Wikipedia + Structurae/mageba snippets (steel arch, 180 m, 50 m wide, arch ~60 m high, " +
				"opened 2008; ONE inclined arch from abutment to opposite abutment carrying a hung deck); OSM " +
				"way 23983613 (139 m carriageway) bearing 220.3; conf 1: single skewed arch cannot be drawn " +
				"as a symmetric tied arch, OSM length (139 m) disagrees with 180 m | verified: " +
				"Structurae/Wikipedia/mageba: steel through arch, 180 m span, 50 m wide, arch ~60 m high; OSM " +
				"way 23983613 (139 m, brg 220.3) confirmed; single inclined arch geometry not representable " +
				"and OSM length disagrees | round 2: round 2: Single skewed arch not representable; OSM " +
				"length mismatch."},
	]
