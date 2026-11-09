class_name BridgeSpecsWestEurope
extends RefCounted

## Capital bridge rows for Western Europe (see BridgeSpec for the schema). Figures are
## sourced per row in `src`; conf 1 rows are kept as data but not built
## (BridgeSpec.MIN_BUILT_CONF).

static func rows() -> Array:
	return [
		{"id": "br_london_southwark_bridge", "cc": "GB", "name": "Southwark Bridge", "wiki": "Southwark Bridge",
			"aliases": ["southwark bridge london"], "lat": 51.50886, "lon": -0.09407, "bearing": 200.1,
			"st": "arch_deck", "spans": [45.0, 48.0, 51.0, 48.0, 45.0], "width": 16.8, "clear": 8.5, "rise": 3.5,
			"material": "steel", "base": "sea", "tier": 2, "conf": 2,
			"src": "Historic England/search snippet (5 steel arches, centre 141 ft, others 131 and 123 ft clear, " +
				"800 ft overall, 55 ft wide), en Wikipedia; Nominatim/OSM way 2700151 bearing and centre; " +
				"piers 4 m assumed, rise and clear estimated | verified: Historic England list entries " +
				"1252452 (spans 123/131/141 ft clear) and 1385913 (approx 45/48/51 m on each side/centre) " +
				"agree once piers of ~7.8 m are added; en Wikipedia 55 ft wide (16.8 m), 800 ft overall; OSM " +
				"way 2700151 centre/bearing re-measured (51.50886,-0.09407, 200.2)"},
		{"id": "br_london_blackfriars_bridge", "cc": "GB", "name": "Blackfriars Bridge", "wiki": "Blackfriars Bridge",
			"aliases": ["blackfriars road bridge"], "lat": 51.5098, "lon": -0.1043, "bearing": 2.0, "st": "arch_deck",
			"spans": [52.2, 58.3, 61.4, 58.3, 52.2], "width": 32.0, "clear": 9.0, "rise": 5.0, "material": "iron",
			"base": "sea", "tier": 2, "conf": 2,
			"src": "en Wikipedia (5 wrought-iron arches, 923 ft, 105 ft wide; coordinate 51.5097,-0.1044), " +
				"Grace's Guide/Waymarking via search (arch spans 155/175/185/175/155 ft), OSM primary way " +
				"bearing 2.0; pier thickness 5 m added to reach 281 m; rise and clear estimated | verified: " +
				"OSM ways 227377667/444636138 etc re-measured: bridge runs lat 51.5085-51.5111 on bearing " +
				"~1.5, centre 51.5098,-0.1044 (matches); en Wikipedia 923 ft, 105 ft wide, 5 wrought-iron " +
				"arches"},
		{"id": "br_london_london_bridge", "cc": "GB", "name": "London Bridge", "wiki": "London Bridge",
			"aliases": ["london bridge thames", "london bridge 1973"], "lat": 51.50763, "lon": -0.08791,
			"bearing": 193.0, "st": "girder", "spans": [79.2, 103.6, 79.2], "width": 32.0, "clear": 10.0,
			"material": "concrete", "base": "sea", "tier": 2, "conf": 2,
			"src": "en Wikipedia infobox (1973 prestressed box girder, main span 104 m, 269 m, 32 m wide; " +
				"coordinate within 55 m of OSM), OSM way 8599345 bearing; side spans assumed equal, deck " +
				"height estimated (8.9 m headroom at HW) | verified: ICE project page and Grace's Guide: 3 " +
				"spans 260/340/260 ft (79.2/103.6/79.2 m), en Wikipedia main span 104 m, 32 m wide; OSM ways " +
				"849624791/3709270 bearing 192.5 and centre 51.5078,-0.0879 re-measured"},
		{"id": "br_london_lambeth_bridge", "cc": "GB", "name": "Lambeth Bridge", "wiki": "Lambeth Bridge",
			"aliases": ["lambeth bridge london"], "lat": 51.49455, "lon": -0.12301, "bearing": 279.6, "st": "arch_deck",
			"spans": [38.1, 45.4, 50.3, 45.4, 38.1], "width": 18.3, "clear": 8.5, "rise": 3.5, "material": "steel",
			"base": "sea", "tier": 2, "conf": 2,
			"src": "Historic England listing via search (1932 five steel arches 38.1/45.4/50.3/45.4/38.1 m, " +
				"236.5 m overall), Grace's Guide (roadway 36 ft + footways 12 ft), OSM way bearing; width is " +
				"a sum, rise and clear estimated | verified: Historic England listing arches " +
				"38.1/45.4/50.3/45.4/38.1 m; OSM ways 201619353 etc: deck 239 m centre 51.49452,-0.12302 " +
				"bearing 279.4 (matches); Grace's Guide width"},
		{"id": "br_london_vauxhall_bridge", "cc": "GB", "name": "Vauxhall Bridge", "wiki": "Vauxhall Bridge",
			"aliases": ["vauxhall bridge london"], "lat": 51.48777, "lon": -0.12744, "bearing": 306.0,
			"st": "arch_deck", "spans": [43.2, 47.9, 49.5, 47.9, 43.2], "width": 24.4, "clear": 10.5, "rise": 4.0,
			"material": "steel", "base": "sea", "tier": 2, "conf": 2,
			"src": "en Wikipedia (5 steel arches, 80 ft wide, 809 ft), search snippet (clear spans " +
				"39.6/43.9/45.4/43.9/39.6 m, 231.6 m with piers): spans scaled to that total; OSM bearing; " +
				"rise and clear estimated | verified: OSM way 749336136 (trunk, 263 m incl. approach) bearing " +
				"306.1, centre within 36 m of the row (Wikipedia coordinate 51.4875,-0.1275 agrees); en " +
				"Wikipedia 5 steel arches 80 ft wide"},
		{"id": "br_london_chelsea_bridge", "cc": "GB", "name": "Chelsea Bridge", "wiki": "Chelsea Bridge",
			"aliases": ["chelsea bridge london"], "lat": 51.48453, "lon": -0.14983, "bearing": 352.0, "st": "susp",
			"spans": [52.4, 107.3, 52.4], "width": 25.0, "clear": 10.5, "tower": 31.0, "material": "steel",
			"base": "sea", "tier": 2, "conf": 2,
			"src": "Historic England listing / Bridgemeister via search (self-anchored, centre 107.3 m, side " +
				"52.4 m), en Wikipedia (698 ft, 64 ft wide; Wikipedia main 332 ft disagrees), OSM way " +
				"bearing; tower height and deck height estimated | verified: Historic England list entry " +
				"1393009: central span 107.3 m, side spans 52.4 m, total 212.7 m, 25 m wide, six-lane roadway " +
				"(en Wikipedia 698 ft total, but 64 ft wide); OSM footways 316367189/191 bearing 352.9/353.2, " +
				"centre 51.4845,-0.1498 matches"},
		{"id": "br_london_albert_bridge", "cc": "GB", "name": "Albert Bridge", "wiki": "Albert Bridge, London",
			"aliases": ["albert bridge chelsea", "albert bridge london"], "lat": 51.48209, "lon": -0.16665,
			"bearing": 342.9, "st": "stayed", "spans": [49.5, 30.5, 56.4, 30.5, 49.5], "width": 12.5, "clear": 9.0,
			"tower": 27.0, "towers": [1, 4], "material": "iron", "base": "sea", "tier": 2, "conf": 2,
			"src": "en Wikipedia (Ordish-Lefeuvre, 710 ft, 41 ft wide, 384 ft 9 in between towers before 1973, " +
				"main 185 ft after the two 1973 piers); span split 30.5+56.4+30.5 inferred, side spans from " +
				"remainder, tower and clear estimated; hybrid cable system | verified: en Wikipedia " +
				"infobox/text: 710 ft long, 384 ft 9 in central span before 1973, 185 ft central span after " +
				"the two 1973 piers, 41 ft wide: 49.5/30.5/56.4/30.5/49.5 follows arithmetically (side spans " +
				"symmetrical, towers on supports 1 and 4); Historic England listing 'three-span combined " +
				"suspension/cable-stayed, four piers, towers paired' (its 241 m/139 m figures include the " +
				"north embankment section); OSM footway 536751573 bearing 162.8 -> 342.8, deck centre " +
				"~51.4823,-0.1667"},
		{"id": "br_london_battersea_bridge", "cc": "GB", "name": "Battersea Bridge", "wiki": "Battersea Bridge",
			"aliases": ["battersea bridge london"], "lat": 51.48108, "lon": -0.17247, "bearing": 150.6,
			"st": "arch_deck", "spans": [36.7, 46.9, 53.9, 46.9, 36.7], "width": 12.2, "clear": 8.5, "rise": 5.5,
			"material": "iron", "base": "sea", "tier": 3, "conf": 2,
			"src": "en Wikipedia (5 cast-iron arches, main 163 ft, 725.5 ft, 40 ft wide), OSM way 23017704 " +
				"bearing; side/intermediate split of the remainder estimated, rise and clear estimated | " +
				"verified: OSM way 23017704 (239 m incl. approaches) bearing 150.4, centre 51.48108,-0.17247 " +
				"matches; Historic England says 5 spans of unequal radii rising to a central apex; Grace's " +
				"Guide/Wikipedia 725.5 ft, main 163 ft, 40 ft wide; no source for the intermediate arch spans " +
				"| round 2: verify2: Grace's Guide (Engineering 1895 article): five arches, clear spans 113 " +
				"ft 6 in / 140 / 163 / 140 / 113 ft 6 in (34.6/42.7/49.7/42.7/34.6 m), rise above springing " +
				"8.5/13/18 ft, width between parapets 40 ft (12.2 m); en Wikipedia: main span 163 ft, length " +
				"725.5 ft (221.1 m), width 40 ft, headroom 38 ft 9 in at LAT; spans = clear + pier shares (4 " +
				"piers x 4.2 m) so the sum equals 221.1 m; centre/bearing from round-1 OSM way 23017704 " +
				"(150.4)"},
		{"id": "br_london_wandsworth_bridge", "cc": "GB", "name": "Wandsworth Bridge", "wiki": "Wandsworth Bridge",
			"aliases": ["wandsworth bridge london"], "lat": 51.46502, "lon": -0.18786, "bearing": 329.1, "st": "girder",
			"spans": [48.5, 100.0, 48.5], "width": 18.3, "clear": 9.0, "material": "steel", "base": "sea", "tier": 3,
			"conf": 1,
			"src": "en Wikipedia (1940 three-span steel cantilever, 650 ft, 60 ft wide), search (197-200 m " +
				"long); individual spans NOT found, 48.5/100/48.5 guessed, cantilever form simplified | " +
				"verified: OSM way 24951888 (217 m) bearing 328.9, centre 51.46486,-0.18771 (18 m from row); " +
				"Wikipedia 650 ft, 60 ft wide, 3-span steel cantilever; Structurae page has no span data; " +
				"individual spans not found | round 2: verify2: searched and not found - en Wikipedia and " +
				"Grace's Guide re-read (Grace's covers only the 1874 predecessor); web search found no span " +
				"list for the 1940 bridge"},
		{"id": "br_london_putney_bridge", "cc": "GB", "name": "Putney Bridge", "wiki": "Putney Bridge",
			"aliases": ["putney bridge london"], "lat": 51.46684, "lon": -0.21312, "bearing": 216.5, "st": "masonry",
			"spans": [38.6, 43.8, 48.4, 43.8, 38.6], "width": 22.9, "clear": 9.0, "rise": 6.0, "material": "stone",
			"base": "sea", "tier": 2, "conf": 2,
			"src": "Grace's Guide via search (5 arches 112/129/144/129/112 ft clear, 700 ft); piers ~4.5 m " +
				"added; WIDTH CONFLICT (en infobox 75 ft, body 43 ft); rise and clear estimated | verified: " +
				"OSM footways 292718364/369 230 m bearing 215.1/35.6, centre 51.46694,-0.21312 matches; " +
				"Grace's Guide/Engineering 1886 via search: arches 112/129/144/129/112 ft, en Wikipedia 700 " +
				"ft; width conflict 43 ft vs 75 ft (1930s widening) unresolved | round 2: verify2: Grace's " +
				"Guide (Engineering 1886) 'spans of the five arches: 112, 129, 144, 129 and 112 ft', 700 ft " +
				"long (also en Wikipedia 700 ft); en Wikipedia: 43 ft wide when opened 1886, widened in 1933 " +
				"to its present three carriageways, infobox 75 ft = 22.9 m (so the width conflict is the 1933 " +
				"widening, current deck 22.9 m); row spans = clear arch + 4.5 m pier shares, sum 213.2 m vs " +
				"213.4 m; centre/bearing from round-1 OSM footways (230 m, bearing 215.1, centre matches); " +
				"rise/clear estimated"},
		{"id": "br_london_hammersmith_bridge", "cc": "GB", "name": "Hammersmith Bridge", "wiki": "Hammersmith Bridge",
			"aliases": ["hammersmith bridge london"], "lat": 51.48846, "lon": -0.23017, "bearing": 33.2, "st": "susp",
			"spans": [45.7, 121.9, 45.7], "width": 13.1, "clear": 6.5, "tower": 23.0, "material": "iron", "base": "sea",
			"tier": 2, "conf": 2,
			"src": "en Wikipedia (Bazalgette 1887, main 400 ft, 700 ft, 43 ft wide; coordinate agrees with OSM " +
				"within 40 m), OSM cycleway ways bearing; side spans from remainder, tower and deck height " +
				"estimated (closed to motor traffic but standing) | verified: Structurae/en Wikipedia main " +
				"span 121.9 m (400 ft), 700 ft (Structurae 210 m) long, 43 ft wide; OSM cycleway ways 7587403 " +
				"+ 314914065: ends 51.48756,-0.23111 .. 51.48925,-0.22935 (incl. approaches), mid " +
				"51.4884,-0.2302 bearing 33.0 matches; side spans = (length - main)/2"},
		{"id": "br_paris_pont_de_la_concorde", "cc": "FR", "name": "Pont de la Concorde", "wiki": "Pont de la Concorde (Paris)",
			"aliases": ["concorde bridge paris"], "lat": 48.86341, "lon": 2.31962, "bearing": 25.9, "st": "masonry",
			"spans": [28.3, 31.3, 34.3, 31.3, 28.3], "width": 35.0, "clear": 8.0, "rise": 3.5, "material": "stone",
			"base": "water", "tier": 2, "conf": 2,
			"src": "fr+en Wikipedia (153 m, widened 1930-32 to 34-35 m), Britannica via search (5 arches, " +
				"openings 25 to 31 m); intermediate openings and 3.4 m piers ESTIMATED, rise and clear " +
				"estimated; OSM bearing | verified: Structurae (via search): five spans 25/28/31/28/25 m, 153 " +
				"m total; Britannica 5 arches 25-31 m, 155 m; fr Wikipedia 153 m x 34 m, evous.fr 35 m wide; " +
				"piers (153-137)/4 = 4 m so pier-centre spans = clear + 3.3 m; OSM ways re-measured: bearing " +
				"27.2, length 155, centre 48.86337,2.31959 (3 m from row)"},
		{"id": "br_paris_pont_royal", "cc": "FR", "name": "Pont Royal", "wiki": "Pont Royal",
			"aliases": ["pont royal paris"], "lat": 48.86023, "lon": 2.32959, "bearing": 26.1, "st": "masonry",
			"spans": [25.35, 26.97, 27.95, 26.97, 25.35], "width": 17.0, "clear": 9.0, "rise": 7.0, "material": "stone",
			"base": "water", "tier": 2, "conf": 2,
			"src": "fr Wikipedia (5 arches 20.8/22.42/23.40/22.42/20.8 m, piers 4.55 m, 110 m between abutment " +
				"faces, 17 m wide, vaults 1/3 lowered: 7.3 m rise on the central arch), OSM bearing; clear " +
				"estimated | verified: fr Wikipedia arches 20.8/22.42/23.40/22.42/20.8 m + piers 4.55 m (sum " +
				"132.4 matches OSM length 131); OSM ways re-measured: principal bearing 26.1 (row had 14.8), " +
				"centre 48.86023,2.32959"},
		{"id": "br_paris_pont_au_change", "cc": "FR", "name": "Pont au Change", "wiki": "Pont au Change",
			"aliases": ["pont au change paris"], "lat": 48.85671, "lon": 2.34694, "bearing": 25.9, "st": "masonry",
			"spans": [33.5, 36.0, 33.5], "width": 30.0, "clear": 8.0, "rise": 4.5, "material": "stone", "base": "water",
			"tier": 3, "conf": 2,
			"src": "fr Wikipedia infobox (103 m, 30 m wide), OSM way bearing; three equal arches ASSUMED, rise " +
				"and clear estimated | verified: Structurae (via search): 103 m long, 3 x 31 m spans, " +
				"masonry, 30 m wide; fr Wikipedia infobox 103 m x 30 m; piers (103-93)/2 = 5 m so spans " +
				"between supports (abutment faces at the ends) are 33.5/36/33.5 m; OSM bearing 23.6, centre " +
				"48.85663,2.34703 (consistent)"},
		{"id": "br_paris_pont_mirabeau", "cc": "FR", "name": "Pont Mirabeau", "wiki": "Pont Mirabeau",
			"aliases": ["mirabeau bridge paris"], "lat": 48.84666, "lon": 2.27558, "bearing": 302.4, "st": "arch_deck",
			"spans": [32.4, 93.0, 32.4], "width": 20.0, "clear": 9.0, "rise": 7.0, "material": "steel", "base": "water",
			"tier": 2, "conf": 2,
			"src": "en Wikipedia (main arch 93 m, side arches 32.4 m, 173 m, 20 m wide; coordinate matches OSM " +
				"within 10 m), OSM bearing; one rise value for all arches (main arch estimated), clear " +
				"estimated | verified: fr Wikipedia: main arch 93 m, two side arches 32.4 m, total 173 m (the " +
				"side arches continue over the quays), 20 m wide (12 m roadway + 2 x 4 m); OSM ways re- " +
				"measured bearing 303.2, centre 48.84663,2.27572 (matches)"},
		{"id": "br_paris_pont_de_bir_hakeim", "cc": "FR", "name": "Pont de Bir-Hakeim", "wiki": "Pont de Bir-Hakeim",
			"aliases": ["bir hakeim bridge", "pont de passy", "pont de bir hakeim"], "lat": 48.85571, "lon": 2.28757,
			"bearing": 323.1, "st": "arch_deck", "spans": [24.0, 42.0, 24.0, 33.0, 30.0, 54.0, 30.0], "width": 24.7,
			"clear": 9.5, "rise": 6.5, "material": "steel", "base": "water", "tier": 2, "conf": 1,
			"src": "en Wikipedia (237 m, 24.7 m; petit bras 24/42/24 m, grand bras 30/54/30 m), OSM ways bearing " +
				"(left bank to right bank); 33 m island span is the remainder to reach 237 m; Metro viaduct " +
				"above not modelled; rise and clear estimated | verified: en Wikipedia (citing AFGC): petit " +
				"bras half-arches/arch 24/42/24 m, grand bras 30/54/30 m, 237 m total, 24.7 m; the island " +
				"section (33 m) is the remainder, a masonry arch under the viaduct, and the Metro viaduct " +
				"dominates; OSM bearing 327.6 (4.5 deg off, within tolerance), centre matches | round 2: " +
				"verify2: searched and not found - fr Wikipedia re-read; Structurae snippet repeats 24/42/24 " +
				"and 30/54/30 but gives no figure for the island masonry arch (33 m is still the remainder)"},
		{"id": "br_paris_passerelle_debilly", "cc": "FR", "name": "Passerelle Debilly", "wiki": "Passerelle Debilly",
			"aliases": ["debilly footbridge"], "lat": 48.86256, "lon": 2.29693, "bearing": 332.4, "st": "arch_through",
			"spans": [125.0], "width": 8.0, "clear": 6.5, "rise": 7.0, "material": "steel", "base": "water", "tier": 3,
			"conf": 1,
			"src": "en Wikipedia (through arch, 125 m, 8 m), OSM way 17066795 bearing; span subdivision and arch " +
				"form unverified (may be several spans), rise and clear estimated | verified: fr Wikipedia " +
				"160 m x 8 m, en 125 m; Structurae search: side arches of 22.5 m are half arches, designed " +
				"Resal/Alby/Lion; OSM footway bearing 332.2, centre matches; span layout (central arch + two " +
				"half arches) not resolved | round 2: verify2: searched and not found - fr Wikipedia re-read: " +
				"no span split; 160 m vs 125 m conflict stays"},
		{"id": "br_paris_pont_de_sully", "cc": "FR", "name": "Pont de Sully", "wiki": "Pont de Sully",
			"aliases": ["pont sully paris"], "lat": 48.84977, "lon": 2.35796, "bearing": 245.4, "st": "arch_deck",
			"spans": [49.0, 52.0, 49.0], "width": 20.0, "clear": 9.0, "rise": 4.5, "material": "iron", "base": "water",
			"tier": 3, "conf": 1,
			"src": "fr Wikipedia (south arm 159 m: cast-iron arches 46/49/46 m, 20 m wide; north arm over the " +
				"small arm is not modelled), Nominatim/OSM bearing of the whole 344 m chain; centre of the " +
				"south arm derived by offset from the left-bank end; 3 m piers assumed, rise and clear " +
				"estimated | verified: fr Wikipedia: south arm 159 m with cast-iron arches 46/49/46 m, north " +
				"arm 46 + 2 x 15 m, 20 m wide; OSM ways bearing 245.6, whole chain centre 48.85012,2.35913 " +
				"(south-arm centre derived from the left-bank end checks with the row); whether 46/49/46 are " +
				"clear or centre spans is unresolved | round 2: verify2: searched and not found - fr " +
				"Wikipedia re-read: arches 46/49/46 m in a 159 m south arm (the 18 m remainder suggests thick " +
				"piers, unresolved whether 46/49/46 are openings); no second source"},
		{"id": "br_paris_pont_d_austerlitz", "cc": "FR", "name": "Pont d'Austerlitz", "wiki": "Pont d'Austerlitz",
			"aliases": ["pont austerlitz", "austerlitz bridge paris"], "lat": 48.84499, "lon": 2.36607,
			"bearing": 229.6, "st": "masonry", "spans": [34.76, 34.76, 34.76, 34.76, 34.76], "width": 30.0,
			"clear": 8.5, "rise": 5.0, "material": "stone", "base": "water", "tier": 3, "conf": 2,
			"src": "fr+en Wikipedia (five arches of 32 m opening, 173.8 m long, 30 m wide, masonry rebuild 1854 " +
				"on the old piers), OSM bearing; piers 2.76 m derived from the total; rise and clear " +
				"estimated | verified: fr Wikipedia: 173.8 m x 30 m, rebuilt in stone 1855 on the old five- " +
				"arch piers (Structurae search, Archives nationales: five arches of 32.5 m opening on the " +
				"original); en Wikipedia 5-arch history; OSM ways re-measured bearing 230.4, centre " +
				"48.84503,2.36603 (matches)"},
		{"id": "br_paris_pont_de_tolbiac", "cc": "FR", "name": "Pont de Tolbiac", "wiki": "Pont de Tolbiac",
			"aliases": ["tolbiac bridge paris"], "lat": 48.83286, "lon": 2.38092, "bearing": 230.3, "st": "masonry",
			"spans": [31.2, 34.2, 37.2, 34.2, 31.2], "width": 20.0, "clear": 9.5, "rise": 6.0, "material": "stone",
			"base": "water", "tier": 3, "conf": 1,
			"src": "fr+en Wikipedia (168 m, 20 m, five elliptical arches of 29/35/32 m openings; arrangement not " +
				"stated), OSM bearing; ordering 29/32/35/32/29 and 2.2 m piers assumed; rise and clear " +
				"estimated | verified: fr Wikipedia 168 m x 20 m, five elliptical arches of 29/35/32 m " +
				"openings; en Wikipedia says 28/35/32 m (conflict) and neither gives the order; OSM bearing " +
				"230.2, centre 48.83294,2.38106 matches | round 2: verify2: searched and not found - fr " +
				"Wikipedia re-read (29/35/32 m openings) and web search (en: 28/35/32; 'Les ponts de Paris': " +
				"29 to 35 m); order of the three sizes still unstated, 29/32/35/32/29 vs 29/35/32/35/29 both " +
				"fit 168 m"},
		{"id": "br_paris_pont_saint_michel", "cc": "FR", "name": "Pont Saint-Michel", "wiki": "Pont Saint-Michel",
			"aliases": ["pont saint michel paris"], "lat": 48.85402, "lon": 2.34459, "bearing": 213.8, "st": "masonry",
			"spans": [19.8, 22.4, 19.8], "width": 30.0, "clear": 8.0, "rise": 6.0, "material": "stone", "base": "water",
			"tier": 3, "conf": 2,
			"src": "en Wikipedia (1857, 62 m, 30 m wide, three 17.2 m arches; coordinate within 15 m of OSM), " +
				"OSM bearing; 3.5 m piers derived from 62 m; rise and clear estimated | verified: en " +
				"Wikipedia: 62 m long, 30 m wide, designed on three 17.2 m arches; fr Wikipedia: 62 m x 30 m, " +
				"three round (plein cintre) arches; piers (62-51.6)/2 = 5.2 m so spans between supports are " +
				"19.8/22.4/19.8; semicircular arches of 17.2 m give a visible rise of about 6 m above a part- " +
				"submerged springing; OSM bearing 215.4, centre 48.85405,2.34464"},
		{"id": "br_paris_pont_du_garigliano", "cc": "FR", "name": "Pont du Garigliano", "wiki": "Pont du Garigliano",
			"aliases": ["garigliano bridge paris"], "lat": 48.83932, "lon": 2.26838, "bearing": 304.6, "st": "girder",
			"spans": [58.0, 93.0, 58.0], "width": 26.0, "clear": 11.0, "material": "steel", "base": "water", "tier": 3,
			"conf": 2,
			"src": "en Wikipedia (1966, 209 m, 26 m, three spans 58/93/58 m, 11 m above the Seine), OSM way " +
				"16883675 bearing and centre | verified: fr Wikipedia: welded six-girder steel bridge, three " +
				"spans 58/93/58 m, 209 m; en Wikipedia 11 m above the Seine vs fr 18 m (conflict; 11 m kept); " +
				"OSM way re-measured bearing 304.5, centre 48.83932,2.26837 (matches)"},
		{"id": "br_paris_pont_de_l_alma", "cc": "FR", "name": "Pont de l'Alma", "wiki": "Pont de l'Alma",
			"aliases": ["alma bridge paris", "pont alma"], "lat": 48.8635, "lon": 2.30163, "bearing": 355.2,
			"st": "girder", "spans": [110.0, 31.5], "width": 42.0, "clear": 7.5, "material": "steel", "base": "water",
			"tier": 2, "conf": 2,
			"src": "Structurae/La Culture Generale via search (1974 steel girder bridge, 2 spans 110 + 31.5 m, " +
				"142.5 m, 42 m wide, single pier on the right bank); en/fr Wikipedia say 153 m; OSM bearing " +
				"left to right bank; deck height estimated | verified: Structurae and evous.fr: two spans 110 " +
				"+ 31.5 m, 142.5 m, 42 m wide, single pier near the right bank (en Wikipedia 153 m " +
				"disagrees); OSM bearing 356.8 (row 355.2) centre 48.86345,2.30152 matches"},
		{"id": "br_paris_passerelle_leopold_sedar_senghor", "cc": "FR", "name": "Passerelle Léopold-Sédar-Senghor", "wiki": "Passerelle Léopold-Sédar-Senghor",
			"aliases": ["passerelle senghor", "passerelle solferino", "passerelle leopold-sedar-senghor"],
			"lat": 48.86179, "lon": 2.32469, "bearing": 205.3, "st": "arch_deck", "spans": [106.0], "width": 15.0,
			"clear": 6.5, "rise": 8.0, "material": "steel", "base": "water", "tier": 3, "conf": 1,
			"src": "en Wikipedia (1999, single span 106 m, 15 m wide, Marc Mimram), OSM way 209826260 bearing; " +
				"two-level deck with superposed arches not representable, rise and clear estimated | " +
				"verified: fr Wikipedia/en Wikipedia single 106 m span, 15 m wide; two superposed decks and " +
				"arches not representable; OSM bearing 205.6, centre matches | round 2: verify2: searched and " +
				"not found - fr Wikipedia re-read: two superposed decks and arches not representable"},
		{"id": "br_dublin_hapenny_bridge", "cc": "IE", "name": "Ha'penny Bridge", "wiki": "Ha'penny Bridge",
			"aliases": ["halfpenny bridge", "wellington bridge dublin", "liffey bridge dublin"], "lat": 53.34632,
			"lon": -6.26311, "bearing": 160.5, "st": "arch_deck", "spans": [43.0], "width": 3.66, "clear": 5.0,
			"rise": 3.35, "material": "iron", "base": "sea", "tier": 2, "conf": 2,
			"src": "en Wikipedia (cast-iron arch, 43 m, 3.66 m wide, 3.35 m rise), OSM footway way 808122953 " +
				"bearing; deck height estimated | verified: en Wikipedia: cast-iron arch 43 m, 3.66 m wide; " +
				"OSM footway ways (3) bearing 160.4, centre 53.34633,-6.26312 (matches)"},
		{"id": "br_dublin_samuel_beckett_bridge", "cc": "IE", "name": "Samuel Beckett Bridge", "wiki": "Samuel Beckett Bridge",
			"aliases": ["beckett bridge dublin"], "lat": 53.3469, "lon": -6.24103, "bearing": 184.2, "st": "stayed",
			"spans": [95.0, 28.0], "width": 26.0, "clear": 6.0, "tower": 48.0, "towers": [1], "pylon": "single",
			"material": "steel", "base": "sea", "tier": 2, "conf": 1,
			"src": "search results (Calatrava, 120-124 m, longest span 95 m per Broer, pylon 48 m), OSM bearing; " +
				"swing bridge with off-centre pivot; width, back span, which bank carries the pylon, tower " +
				"base level and deck height are ESTIMATES | verified: Calatrava project page (via search): " +
				"pivot pier carrying the pylon 28 m from the SOUTH abutment; Broer database longest span 95 " +
				"m; Arch2o 123 m long; Structurae paper: 48 m above water, 25 forestay cables (harp); OSM " +
				"ways bearing 184.2 (southward), centre 53.34690,-6.24103; deck width still unsourced; spans " +
				"reordered so the 95 m span comes first when heading south | round 2: verify2: searched and " +
				"not found - en Wikipedia re-read: no deck width or span list; widths still estimated"},
		{"id": "br_dublin_o_connell_bridge", "cc": "IE", "name": "O'Connell Bridge", "wiki": "O'Connell Bridge",
			"aliases": ["oconnell bridge dublin", "carlisle bridge"], "lat": 53.34722, "lon": -6.25927,
			"bearing": 165.4, "st": "masonry", "spans": [13.5, 18.0, 13.5], "width": 45.0, "clear": 5.5, "rise": 3.0,
			"material": "stone", "base": "sea", "tier": 2, "conf": 1,
			"src": "en Wikipedia (3 arches, ~45 m long, ~50 m wide / 45 m between parapets), OSM bearing; " +
				"individual arch spans ESTIMATED, rise and clear estimated | verified: en Wikipedia: three " +
				"arches, ~45 m long, ~50 m wide; individual arch spans not found; OSM 10 ways union gives a " +
				"near-square footprint so principal bearing (153.5) is unreliable; unchanged | round 2: " +
				"verify2: searched and not found - en Wikipedia re-read: three arches, no individual spans"},
		{"id": "br_dublin_rosie_hackett_bridge", "cc": "IE", "name": "Rosie Hackett Bridge", "wiki": "Rosie Hackett Bridge",
			"aliases": ["rosie hackett bridge dublin"], "lat": 53.34764, "lon": -6.2573, "bearing": 174.0,
			"st": "girder", "spans": [48.0], "width": 26.0, "clear": 6.0, "material": "concrete", "base": "sea",
			"tier": 3, "conf": 2,
			"src": "en Wikipedia (single span, 48 m, 26 m wide, concrete), OSM bearing; deck height estimated | " +
				"verified: en Wikipedia: single span 48 m, 26 m wide; OSM ways 282571109/110, 376394519 " +
				"bearing 174.0 (row had 181.4), mid 53.34764,-6.25730"},
		{"id": "br_dublin_james_joyce_bridge", "cc": "IE", "name": "James Joyce Bridge", "wiki": "James Joyce Bridge",
			"aliases": ["james joyce bridge dublin"], "lat": 53.34661, "lon": -6.2826, "bearing": 190.3,
			"st": "arch_tied", "spans": [40.0], "width": 30.0, "clear": 5.0, "rise": 8.0, "material": "steel",
			"base": "sea", "tier": 3, "conf": 1,
			"src": "en Wikipedia (Calatrava, single span 40 m, 30 m wide, two outward-leaning arches), OSM " +
				"bearing; arch height and deck height estimated, width figure doubtful | verified: en " +
				"Wikipedia infobox 40 m x 30 m single span (two outward-leaning arches); width figure " +
				"unconfirmed; OSM bearing 190.2 matches | round 2: verify2: searched and not found - not " +
				"rechecked beyond round 1: 30 m width doubtful"},
		{"id": "br_dublin_millennium_bridge", "cc": "IE", "name": "Millennium Bridge Dublin", "wiki": "Millennium Bridge (Dublin)",
			"aliases": ["dublin millennium footbridge", "millennium bridge dublin"], "lat": 53.34602, "lon": -6.26506,
			"bearing": 168.7, "st": "girder", "spans": [41.0], "width": 4.0, "clear": 4.5, "material": "steel",
			"base": "sea", "tier": 3, "conf": 2,
			"src": "en Wikipedia (51 m long incl abutments, 41 m span, ~4 m wide), OSM footway way 31028727 " +
				"bearing; deck height estimated | verified: en Wikipedia 41 m span (51 m with abutments); OSM " +
				"footway bearing 168.6, centre 53.34602,-6.26506 matches"},
		{"id": "br_dublin_sean_heuston_bridge", "cc": "IE", "name": "Seán Heuston Bridge", "wiki": "Seán Heuston Bridge",
			"aliases": ["sean heuston bridge", "kings bridge dublin"], "lat": 53.3474, "lon": -6.29186,
			"bearing": 174.8, "st": "arch_deck", "spans": [30.0], "width": 8.9, "clear": 4.5, "rise": 3.0,
			"material": "iron", "base": "sea", "tier": 3, "conf": 2,
			"src": "en Wikipedia (cast iron, ~30 m single span, just under 9 m wide), OSM bearing; rise and deck " +
				"height estimated | verified: en Wikipedia: cast-iron, ~30 m, just under 9 m wide, infobox " +
				"one span; Buildings of Ireland (NIAH): single segmental cast-iron arch; Grace's Guide 98.5 " +
				"ft x 30 ft; OSM bearing 174.7, centre matches"},
		{"id": "br_amsterdam_python_bridge", "cc": "NL", "name": "Python Bridge", "wiki": "Python Bridge",
			"aliases": ["pythonbrug", "hoge brug amsterdam"], "lat": 52.37305, "lon": 4.94888, "bearing": 169.6,
			"st": "girder", "spans": [90.0], "width": 4.0, "clear": 6.0, "material": "steel", "base": "water",
			"tier": 3, "conf": 1,
			"src": "en Wikipedia (steel, main span 90 m), OSM way bearing/centre (81 m chain incl. ramps); width " +
				"and height ESTIMATED, form is a box with a looping ramp | verified: en Wikipedia main span " +
				"90 m; nl Wikipedia 93 m across the Spoorwegbassin, longer path because of the looping form, " +
				"max headroom 9.5 m; OSM name search found nothing ('Hoge brug' tagged differently) | round " +
				"2: verify2: searched and not found - nl Wikipedia re-read: 93 m over the Spoorwegbassin, max " +
				"headroom 9.5 m, looping ramp; width unsourced"},
		{"id": "br_luxembourg_adolphe_bridge", "cc": "LU", "name": "Adolphe Bridge", "wiki": "Adolphe Bridge",
			"aliases": ["pont adolphe", "adolphe brucke", "adolphe bridge luxembourg"], "lat": 49.60844, "lon": 6.12688,
			"bearing": 151.5, "st": "arch_deck", "spans": [27.0, 84.65, 27.0], "width": 18.0, "clear": 42.0,
			"rise": 31.0, "material": "stone", "base": "ground", "tier": 2, "conf": 2,
			"src": "en Wikipedia (1903, longest span 84.65 m, 153 m total, 17.2 m wide, 42 m over the valley), " +
				"search snippet; OSM bearing; only the main double arch modelled (tiered upper arch and " +
				"approach arches omitted), rise ESTIMATED | verified: fr Wikipedia: 153 m long, centre double " +
				"arch 84.65 m span, flèche 31 m, two side arches of 21.60 m opening, 17.2 m wide (18.7 m in " +
				"the infobox after the 2012-16 widening), 42 m above the valley; de Wikipedia: four 5.40 m " +
				"approach arches each side; single-span model leaves the side arches out so it stays undrawn " +
				"| round 2: verify2: de Wikipedia: 153 m long, double main arch 84.55 m (en/fr 84.65 m), four " +
				"5.40 m spandrel arches each side above it, flanked by 21.60 m double arches over the slopes, " +
				"deck 17.20 m between balustrades (fr infobox 18.7 m after the 2012-17 renovation added 0.75 " +
				"m), 42 m above the valley; fr Wikipedia: rise (fleche) 31 m, side arches 21.60 m; modelled " +
				"as three arches 21.6 m + 5.4 m pier = 27.0 / 84.65 / 27.0 (abutments beyond the side arches " +
				"omitted, 138.7 of 153 m); OSM way 26774765 (Pont Adolphe, 155 m, bearing 151.5, mid " +
				"49.60844,6.12688) re-measured"},
		{"id": "br_luxembourg_grand_duchess_charlotte_bridge", "cc": "LU", "name": "Grand Duchess Charlotte Bridge", "wiki": "Grand Duchess Charlotte Bridge",
			"aliases": ["pont grande-duchesse charlotte", "red bridge luxembourg", "pont rouge luxembourg"],
			"lat": 49.61778, "lon": 6.13176, "bearing": 257.3, "st": "girder", "spans": [60.45, 234.1, 60.45],
			"width": 25.07, "clear": 74.0, "material": "steel", "base": "ground", "tier": 2, "conf": 1,
			"src": "Structurae/Wikipedia list via search (355 m, main 234.1 m, 25.07 m wide, 74 m above the " +
				"Alzette), OSM way 9882486 bearing; box girder with inclined legs and variable depth " +
				"simplified; side spans = remainder split equally | verified: en Wikipedia: 355 m, three " +
				"elements 95.42 + 152.56 + 107.02 m, main span 234.10 m, rigid-frame batter-post legs " +
				"40.6/38.7 m long, 75 m above the Alzette, 26.58 m wide; OSM bearing 257.4 centre matches; " +
				"could fit 'haunched' with legs but leg feet stand on the valley slopes, not the valley floor " +
				"| round 2: verify2: searched and not found - web search: 355 m, main span 234.10 m, 26.58 m " +
				"after the 2018 renovation (25.07 m older), 75 m; en Wikipedia 3-element split " +
				"95.42+152.56+107.02 conflicts with a 60.45/234.1/60.45 reading; side spans remain unsourced"},
		{"id": "br_paris_pont_d_arcole", "cc": "FR", "name": "Pont d'Arcole", "wiki": "Pont d'Arcole",
			"aliases": ["pont arcole", "arcole bridge paris"], "lat": 48.85548, "lon": 2.35057, "bearing": 25.8,
			"st": "arch_deck", "spans": [80.0], "width": 20.0, "clear": 7.0, "rise": 4.0, "material": "steel",
			"base": "water", "tier": 3, "conf": 2,
			"src": "fr Wikipedia (single metal arch of 80 m, 20 m wide, 1856 design; en infobox 80 m; coordinate " +
				"within 20 m of Nominatim/OSM centre), OSM ways bearing; rise and clear estimated | verified: " +
				"fr Wikipedia: single metal arch of 80 m, 20 m wide; OSM way 474063681 (83 m) A " +
				"48.85514,2.35032 -> B 48.85582,2.35081 bearing 25.8, mid 48.85548,2.35057 (row had bearing " +
				"34.8, 9 deg off)"},
		{"id": "br_paris_passerelle_simone_de_beauvoir", "cc": "FR", "name": "Passerelle Simone-de-Beauvoir", "wiki": "Passerelle Simone-de-Beauvoir",
			"aliases": ["simone de beauvoir footbridge", "passerelle simone de beauvoir"], "lat": 48.83524,
			"lon": 2.37805, "bearing": 230.5, "st": "girder", "spans": [57.0, 190.0, 57.0], "width": 12.0, "clear": 8.0,
			"material": "steel", "base": "water", "tier": 3, "conf": 1,
			"src": "fr Wikipedia (304 m, 6-12 m wide, main span 190 m, lens 106 m + two 47 m cantilevers); side " +
				"spans = remainder split equally; two-level lenticular deck cannot be represented, deck " +
				"height estimated | verified: fr Wikipedia: 190 m span, lenticular arc-catenary structure, " +
				"304 m total; OSM re-measure failed (API throttled), not raised | round 2: verify2: searched " +
				"and not found - not rechecked; two-level lenticular deck not representable"},
		{"id": "br_lisbon_vasco_da_gama_bridge", "cc": "PT", "name": "Vasco da Gama Bridge", "wiki": "Vasco da Gama Bridge",
			"aliases": ["ponte vasco da gama", "vasco da gama bridge lisbon"], "lat": 38.7619, "lon": -9.0428,
			"bearing": 308.0, "st": "stayed", "spans": [203.0, 420.0, 203.0], "width": 30.0, "clear": 47.0,
			"tower": 150.0, "material": "concrete", "base": "sea", "tier": 1, "conf": 1,
			"src": "en+pt Wikipedia (coordinate 38.762,-9.043 / 38°45'43\"N 9°02'34\"W, 30 m wide, 420 m main), " +
				"Structurae/Britannica via search (side spans 203 m, 829 m cable-stayed section, pylons " +
				"148-155 m, deck 45-47 m above water), OSM motorway way 29104538 bearing (coarse chain); only " +
				"the cable-stayed section modelled (17.2 km total); about 10.1 km from the catalog point | " +
				"verified: en Wikipedia: main bridge 203/420/203 m (829 m total), pylons 150 m, navigation " +
				"clearance 45 m; pt Wikipedia 30 m wide; OSM way 29104538/344085225 and area 917157032 run 10 " +
				"km with no separate cable-stayed part, so the centre of the 829 m section could not be re- " +
				"measured; the Wikipedia coordinate (38.7619,-9.0428) sits at a node cluster of the area " +
				"outline but is not confirmed | round 2: verify2: searched and not found - pt Wikipedia " +
				"fetched; the centre of the 829 m cable-stayed section could not be separated from OSM's 10 " +
				"km way within the budget"},
		{"id": "br_madrid_puente_de_segovia", "cc": "ES", "name": "Puente de Segovia", "wiki": "Bridge of Segovia (Madrid)",
			"aliases": ["puente de segovia madrid", "bridge of segovia madrid"], "lat": 40.41403, "lon": -3.72308,
			"bearing": 271.4, "st": "masonry", "spans": [19.1, 19.1, 19.1, 19.1, 19.1, 19.1, 19.1, 19.1, 19.1],
			"width": 31.0, "clear": 10.0, "rise": 7.0, "material": "stone", "base": "water", "tier": 2, "conf": 1,
			"src": "en Wikipedia (Herrera 1582-84, nine spans), es sources via search (9 semicircular granite " +
				"arches, widest in the middle and decreasing, about 172 m by local guides vs 278 m by " +
				"Audiala, widened to 31 m); equal 19.1 m spans ASSUMED, rise and clear estimated; OSM way " +
				"bearing | verified: es Wikipedia: nine (once thirteen) arches, no span list in the article; " +
				"OSM bearing 271.3, centre matches; length 153 m (OSM) vs 172/278 m conflicting | round 2: " +
				"verify2: searched and not found - es Wikipedia re-read: nine semicircular arches, central " +
				"the widest and decreasing outward, no figures"},
		{"id": "br_amsterdam_magere_brug", "cc": "NL", "name": "Magere Brug", "wiki": "Magere Brug",
			"aliases": ["skinny bridge amsterdam", "magere brug amstel"], "lat": 52.36358, "lon": 4.90236,
			"bearing": 73.0, "st": "bascule", "spans": [28.0, 11.0, 28.0], "width": 4.0, "clear": 2.5,
			"material": "steel", "base": "water", "tier": 2, "conf": 1,
			"src": "en/nl Wikipedia articles found but infoboxes carry no dimensions; coordinate " +
				"52.36361,4.90250 agrees with OSM within 12 m, OSM bearing; double-leaf wooden drawbridge " +
				"with several openings: span split and width ESTIMATED (about 65-70 m overall), timber " +
				"modelled as steel | verified: nl/en Wikipedia: 1934 reconstruction, wooden double bascule " +
				"with several openings (9 openings in the 1871 version), no dimensions in articles; OSM name " +
				"search found no bridge ways | round 2: verify2: searched and not found - nl Wikipedia re- " +
				"read: no dimensions or opening layout"},
	]
