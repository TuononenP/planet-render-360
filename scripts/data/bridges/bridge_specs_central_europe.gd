class_name BridgeSpecsCentralEurope
extends RefCounted

## Capital bridge rows for Central Europe (see BridgeSpec for the schema). Figures are
## sourced per row in `src`; conf 1 rows are kept as data but not built
## (BridgeSpec.MIN_BUILT_CONF).

static func rows() -> Array:
	return [
		{"id": "br_berlin_weidendammer_bridge", "cc": "DE", "name": "Weidendammer Bridge", "aliases": ["weidendammer brücke", "weidendammer brucke"],
			"lat": 52.52213, "lon": 13.38795, "bearing": 173.9, "st": "arch_deck", "spans": [16.3, 38.5, 15.5],
			"width": 22.5, "clear": 6.5, "rise": 2.8, "material": "steel", "base": "water", "tier": 3, "conf": 2,
			"src": "de Wikipedia (Stuetzweiten 16.3+38.5+15.5 m, 73 m long, 22.5 m wide, headroom 5.25 m), OSM " +
				"way 6228081 bearing; deck height and arch rise estimated | verified: de Wikipedia: three- " +
				"field deck bridge (Otto Stahn 1896, rebuilt 1923 with plate girders), Stuetzweiten " +
				"16.3+38.5+15.5 m cited from Mehlhorn Handbuch Bruecken, width 22.5 m, headroom 5.25 m; OSM " +
				"way geometry re-measured via api.openstreetmap.org way/full (centre and end-to-end bearing " +
				"agree) way 6228081 centre 52.52213,13.38795 brg 173.9, 70.7 m; deck height and rise still " +
				"estimates"},
		{"id": "br_berlin_moltke_bridge", "cc": "DE", "name": "Moltke Bridge", "aliases": ["moltkebrücke", "moltkebrucke"],
			"lat": 52.52187, "lon": 13.36877, "bearing": 312.9, "st": "masonry", "spans": [13.5, 24.6, 13.5],
			"width": 26.7, "clear": 6.0, "rise": 3.5, "material": "stone", "base": "water", "tier": 3, "conf": 1,
			"src": "de+en Wikipedia (78 m long, 26.7 m wide, three sandstone-faced arches, main opening 20.6 m, " +
				"south side arch 10.37 m); individual spans and pier size guessed, OSM way 34833363 bearing | " +
				"verified: de Wikipedia Moltkebruecke text vs infobox conflict (river openings 16.3/17/16.3 m " +
				"clear, 10.37 m side arches, steel structure inserted 1983-86 on stone piers; infobox span " +
				"20.6 m, 78 m long, 26.7 m wide); OSM way geometry re-measured via api.openstreetmap.org " +
				"way/full (centre and end-to-end bearing agree) way 34833363 brg 312.9 ok; spans not " +
				"resolvable | round 2: round 2: de Wikipedia text: five-arch Korbbogen vault, three river " +
				"openings 16.3/17/16.3 m, south segment arch 10.37 m (path underneath) and an equal BLIND " +
				"arch at the north end; infobox 'Spanne 20.6 m' (probably the 17 m central opening + ~3.6 m " +
				"pier) and 78 m length vs OSM deck way 34833363 92.2 m; the length conflict, the blind north " +
				"arch and unknown pier thickness leave the layout ambiguous (candidate: " +
				"12.2/19.9/20.6/19.9/12.2 with ~3.6 m piers, sum 84.8 m, unconfirmed)"},
		{"id": "br_berlin_schlossbruecke", "cc": "DE", "name": "Schlossbrücke", "aliases": ["schloßbrücke", "schlossbrucke", "schloßbrücke berlin"],
			"lat": 52.51762, "lon": 13.39855, "bearing": 84.4, "st": "masonry", "spans": [13.9, 14.4, 13.9],
			"width": 32.6, "clear": 3.7, "rise": 1.9, "material": "stone", "base": "water", "tier": 2, "conf": 1,
			"src": "de Wikipedia (Schinkel 1824, three arches 11.2+11.7+11.2 m clear, 56.3 m long, 32.6 m wide), " +
				"OSM ways 15971197/339201217 bearing; piers ~2.7 m, clear and rise estimated | verified: de " +
				"Wikipedia Schlossbruecke (Berlin-Mitte): three arches 11.2+11.7+11.2 m clear, 56.3 m long, " +
				"32.6 m wide; OSM way geometry re-measured via api.openstreetmap.org way/full (centre and " +
				"end-to-end bearing agree) ways 15971197 / 339201217 (50.3 m, brg 84.5); pier thickness not " +
				"stated, 34.1 m of openings + 2 piers = ~50 m implies piers ~5+ m, so first-pass spans too " +
				"short | round 2: round 2: de Wikipedia only (openings 11.2/11.7/11.2 m, 56.3 m long); OSM " +
				"deck ways 50.3 m, so (50.3-34.1)/2 = ~8 m piers or the 56.3 m includes abutments - pier " +
				"thickness not published in any source found (searches of de Wikipedia, OSM tags)"},
		{"id": "br_berlin_jannowitz_bridge", "cc": "DE", "name": "Jannowitz Bridge", "aliases": ["jannowitzbrücke", "jannowitzbrucke"],
			"lat": 52.51425, "lon": 13.4178, "bearing": 7.8, "st": "girder", "spans": [73.5], "width": 35.0,
			"clear": 5.0, "material": "steel", "base": "water", "tier": 3, "conf": 1,
			"src": "de Wikipedia (1954 multi-girder steel bridge with concrete deck, 73.5 m long, 35 m wide, " +
				"headroom 4.0 m, no pier in river), OSM way 25086766 bearing; deck height estimated | " +
				"verified: de Wikipedia Jannowitzbruecke: 1952-54 steel beam deck bridge on the old abutments " +
				"with a new Strompfeiler (80 m long construction); infobox says 73.5 m long, 35 m wide, " +
				"headroom 4.0 m, multi-girder steel with concrete deck; OSM way geometry re-measured via " +
				"api.openstreetmap.org way/full (centre and end-to-end bearing agree) way 25086766 brg 7.9 " +
				"ok; span layout unresolved | round 2: round 2: de Wikipedia infobox only (73.5 m, 35 m, " +
				"headroom 4.0 m); no span layout for the new central pier ('Strompfeiler') found in the de " +
				"article"},
		{"id": "br_berlin_marschallbruecke", "cc": "DE", "name": "Marschallbrücke", "aliases": ["marschallbrucke"],
			"lat": 52.51923, "lon": 13.38023, "bearing": 173.2, "st": "girder", "spans": [39.0, 18.0], "width": 19.0,
			"clear": 5.5, "material": "steel", "base": "water", "tier": 3, "conf": 2,
			"src": "de Wikipedia infobox (57 m long, main span 39 m, 19 m wide, headroom 4.5 m); second span = " +
				"57-39 assumed, OSM way 25945965 bearing | verified: de Wikipedia: 1999 rebuilt prestressed " +
				"concrete frame bridge (Rahmenbruecke) on masonry river piers, optically two fields, 57 m " +
				"useful length, main span 39 m, 19 m wide (15 m carriageway), headroom 4.5 m; Structurae " +
				"quote: girders 36 m and 21 m with the joint not over the pier (consistent with 39+18=57); " +
				"OSM way geometry re-measured via api.openstreetmap.org way/full (centre and end-to-end " +
				"bearing agree) way 25945965 brg 173.2, 60.3 m. Second span 18 m is the remainder of a two- " +
				"field structure"},
		{"id": "br_berlin_friedrichsbruecke", "cc": "DE", "name": "Friedrichsbrücke", "wiki": "Friedrichs Bridge",
			"aliases": ["friedrichsbrucke"], "lat": 52.52047, "lon": 13.40016, "bearing": 56.8, "st": "girder",
			"spans": [30.0], "width": 27.0, "clear": 5.5, "material": "concrete", "base": "water", "tier": 3, "conf": 2,
			"src": "de Wikipedia (prestressed concrete, single span 30 m, 69.3 m long, 12.5 m wide per infobox, " +
				"text mentions 27 m historic width); side spans and width unclear, OSM way 4610599 bearing | " +
				"verified: de Wikipedia Friedrichsbruecke: Spannbeton, einbogig, span 30 m, 69.3 m long, " +
				"headroom 4.5 m; rebuilt 1981-82 as prestressed concrete frame, widened north and south in " +
				"2012-14 'to the historic width of 27 m' (infobox 12.5 m outdated); OSM way geometry re- " +
				"measured via api.openstreetmap.org way/full (centre and end-to-end bearing agree) way " +
				"4610599 centre 52.52047,13.40016 brg 56.8"},
		{"id": "br_berlin_kronprinzenbruecke", "cc": "DE", "name": "Kronprinzenbrücke", "wiki": "Crown Prince Bridge",
			"aliases": ["kronprinzenbrucke"], "lat": 52.52194, "lon": 13.37577, "bearing": 60.6, "st": "girder",
			"spans": [15.61, 44.0, 15.61], "width": 22.6, "clear": 5.0, "material": "steel", "base": "water", "tier": 3,
			"conf": 2,
			"src": "de Wikipedia (Calatrava design, 3 spans 15.61+44.0+15.61 m = 75.22 m); width assumed ~22 m " +
				"from the old bridge, OSM ways 963861593/602 bearing | verified: de Wikipedia " +
				"Kronprinzenbruecke (Calatrava 1996): three-field steel continuous girder with steel-tube " +
				"arches, total 75.22 m, main 44.0 m, side 15.61 m, width 22.62 m; OSM way geometry re- " +
				"measured via api.openstreetmap.org way/full (centre and end-to-end bearing agree) way " +
				"963861593 78.4 m, brg 60.6; deck height estimated"},
		{"id": "br_berlin_boesebruecke", "cc": "DE", "name": "Bösebrücke", "aliases": ["bösebrücke", "boesebruecke", "bornholmer brücke", "bornholmer bruecke"],
			"lat": 52.55466, "lon": 13.39815, "bearing": 96.1, "st": "arch_tied", "spans": [25.5, 87.0, 25.5],
			"width": 27.0, "clear": 8.0, "rise": 12.0, "material": "steel", "base": "ground", "tier": 3, "conf": 2,
			"src": "de Wikipedia (steel riveted arch girders, 25.5+87+25.5 m = 138 m, useful width 27 m, arch " +
				"crown 12 m over the hung deck plate), OSM ways 48388758/9 bearing; deck height over the " +
				"railway estimated; crosses railway, not water | verified: de Wikipedia Boesebruecke: " +
				"Dreifeldtraeger 25.5/87.0/25.5 m = 138 m, Zweigelenkbogen with cantilever arms (upper chords " +
				"visible over the full 138 m), usable width 27.0 m (6+15+6), arch rise 12 m over the hung " +
				"deck plate, road level 56.6 m amsl; OSM way geometry re-measured via api.openstreetmap.org " +
				"way/full (centre and end-to-end bearing agree) ways 48388758/9 centre 52.55466,13.39815 brg " +
				"96.1; deck height over the railway estimated"},
		{"id": "br_berlin_gustav_heinemann_bridge", "cc": "DE", "name": "Gustav-Heinemann Bridge", "wiki": "Gustav Heinemann Bridge",
			"aliases": ["gustav-heinemann-brücke", "heinemann bridge berlin"], "lat": 52.52289, "lon": 13.37075,
			"bearing": 179.7, "st": "girder", "spans": [66.0], "width": 5.0, "clear": 5.5, "material": "steel",
			"base": "water", "tier": 3, "conf": 2,
			"src": "de Wikipedia (Max Dudler 2005, Vierendeel steel girder footbridge, 88 m long, 66 m span, 5 m " +
				"wide), OSM way 15405394; side spans = (88-66)/2 assumed | verified: de Wikipedia Gustav- " +
				"Heinemann-Bruecke (Berlin): Vierendeel steel beams, 88 m long, 5 m wide, span 66 m, " +
				"abgestuetzt on two concrete piers at the banks, headroom 4.5 m; OSM way geometry re-measured " +
				"via api.openstreetmap.org way/full (centre and end-to-end bearing agree) way 15405394 (89.3 " +
				"m, brg 179.7, OSM width 4); dropped the 11 m side spans"},
		{"id": "br_berlin_lessingbruecke", "cc": "DE", "name": "Lessingbrücke", "aliases": ["lessingbrucke"],
			"lat": 52.52272, "lon": 13.34204, "bearing": 8.8, "st": "arch_tied", "spans": [52.5], "width": 27.0,
			"clear": 6.4, "rise": 8.0, "material": "steel", "base": "water", "tier": 3, "conf": 1,
			"src": "de Wikipedia (steel tied-arch bridge, main span 52.5 m, 85 m long incl. skew approach, 27 m " +
				"wide, headroom 5.4 m), OSM ways 342085671/6 bearing; arch rise estimated; only the main arch " +
				"span listed | verified: de Wikipedia Lessingbruecke: Stabbogenbruecke (tied arch) over the " +
				"middle, 52.5 m span, 85 m long, 27 m wide, headroom 5.4 m, side arches rebuilt as look- " +
				"alike; OSM way geometry re-measured via api.openstreetmap.org way/full (centre and end-to- " +
				"end bearing agree) way 342085671 84.5 m brg 8.8; side-span lengths not sourced | round 2: " +
				"round 2: de Wikipedia + Structurae snippet confirm 52.5 m max span, 27 m wide; side-span " +
				"lengths and the 85 m total split not in any retrievable source (original 1903 bridge had " +
				"29.6 m centre opening; Stahlbau 1984 paper not accessible)"},
		{"id": "br_berlin_schillingbruecke", "cc": "DE", "name": "Schillingbrücke", "aliases": ["schillingbrucke"],
			"lat": 52.50921, "lon": 13.42928, "bearing": 28.5, "st": "masonry",
			"spans": [14.95, 14.95, 14.95, 14.95, 14.97], "width": 23.2, "clear": 5.7, "rise": 2.2, "material": "stone",
			"base": "water", "tier": 3, "conf": 2,
			"src": "de Wikipedia (five-arch brick vault bridge, 74.77 m long, 23.16 m wide, arch openings 12.55 " +
				"m, headroom 4.9 m), OSM way 29548009 bearing; equal pier-centre spans assumed, rise " +
				"estimated | verified: de Wikipedia Schillingbruecke: five-arch brick vault bridge, openings " +
				"12.55 m (single SPANNE value), 74.77 m long, 23.16 m wide (15 m + 2x4.1 m steel brackets " +
				"added 1912), headroom 4.9 m; OSM way geometry re-measured via api.openstreetmap.org way/full " +
				"(centre and end-to-end bearing agree) way 29548009 centre 52.50922,13.42927 brg 28.5, 71.5 " +
				"m; equal pier-centre spans (14.95 m) is an assumption from the single span figure"},
		{"id": "br_berlin_muehlendamm_bridge", "cc": "DE", "name": "Mühlendamm Bridge", "wiki": "Mühlendamm",
			"aliases": ["mühlendammbrücke", "muhlendammbrucke"], "lat": 52.51514, "lon": 13.40688, "bearing": 33.8,
			"st": "girder", "spans": [70.2, 44.0], "width": 45.2, "clear": 5.5, "material": "concrete", "base": "water",
			"tier": 3, "conf": 1,
			"src": "de Wikipedia (1968 prestressed concrete, 114.2 m long, max span 70.2 m, 45.2 m wide, " +
				"headroom 4.3 m); second span = remainder assumed, OSM bearing | verified: de Wikipedia " +
				"Muehlendammbruecke: two separate prestressed concrete parts, 114.2 m long, 45.2 m wide, " +
				"largest span 70.2 m, headroom 4.3 m; second span not stated; replacement planned | round 2: " +
				"round 2: de Wikipedia title/redirect could not be fetched; earlier infobox values only (70.2 " +
				"m max span, 114.2 m, 45.2 m); second span not sourced"},
		{"id": "br_berlin_admiralbruecke", "cc": "DE", "name": "Admiralbrücke", "aliases": ["admiralbrucke", "admiral bridge berlin"],
			"lat": 52.49528, "lon": 13.41515, "bearing": 7.3, "st": "arch_deck", "spans": [19.0], "width": 19.5,
			"clear": 4.8, "rise": 1.8, "material": "iron", "base": "water", "tier": 3, "conf": 2,
			"src": "de Wikipedia infobox (1882 riveted iron arch, span 19 m, ~33 m long, 19.5 m wide, headroom " +
				"4.35 m), OSM ways 659876880/4 bearing; rise estimated | verified: de Wikipedia " +
				"Admiralbruecke: riveted iron arch (Bogenbruecke), span 19 m, ca. 33 m long, 19.5 m wide " +
				"(2x4.6 m footways), headroom 4.35 m; OSM way geometry re-measured via api.openstreetmap.org " +
				"way/full (centre and end-to-end bearing agree) way 659876880 centre 52.49527,13.41508 brg " +
				"7.6; rise estimated"},
		{"id": "br_vienna_floridsdorfer_bridge", "cc": "AT", "name": "Floridsdorf Bridge", "aliases": ["floridsdorfer brücke", "floridsdorfer brucke"],
			"lat": 48.24695, "lon": 16.38383, "bearing": 55.1, "st": "girder", "spans": [78.0, 176.5, 78.0],
			"width": 31.4, "clear": 12.0, "material": "steel", "base": "water", "tier": 2, "conf": 1,
			"src": "de Wikipedia (steel Strombruecke 332.5 m long, 31.4 m wide; flood bridge 215 m separate), " +
				"OSM way 493217746 bearing; individual spans NOT sourced (3-span split guessed), deck height " +
				"guessed | verified: de Wikipedia Floridsdorfer Bruecke: Strombruecke steel 332.5 m long, " +
				"Flutbruecke 215 m, Kaibruecke 95 m, width 31.4 m (Strombruecke) / 37.4 m; Structurae lists a " +
				"steel box girder but its span table is not retrievable (403); span split still guessed | " +
				"round 2: round 2: de Wikipedia + web search (structurae 403): only totals (332.5 m " +
				"Strombruecke, 31.4 m wide); no Stuetzweiten published"},
		{"id": "br_vienna_brigittenauer_bridge", "cc": "AT", "name": "Brigittenau Bridge", "aliases": ["brigittenauer brücke", "brigittenauer brucke"],
			"lat": 48.2377, "lon": 16.3936, "bearing": 53.1, "st": "girder", "spans": [100.0, 155.0, 100.0],
			"width": 32.25, "clear": 12.0, "material": "steel", "base": "water", "tier": 2, "conf": 1,
			"src": "de Wikipedia (steel Strombruecke 355 m long, 32.25 m wide; flood bridge 275 m separate), OSM " +
				"way 41803391 bearing; span split and deck height guessed | verified: de Wikipedia " +
				"Brigittenauer Bruecke: Strombruecke 355 m, Flutbruecke 275 m, width 32.25 m, steel (ramps " +
				"prestressed concrete), Structurae box girder; span table not retrievable (403) | round 2: " +
				"round 2: de Wikipedia, Waagner-Biro reference page (355 m river span + 275 m flood bridge + " +
				"14 m piece, 32 m wide, plate girder) and structurae snippet (box girder: types conflict); no " +
				"span table"},
		{"id": "br_vienna_salztorbruecke", "cc": "AT", "name": "Salztorbrücke", "aliases": ["salztorbrucke", "stephaniebrücke"],
			"lat": 48.21432, "lon": 16.37493, "bearing": 64.4, "st": "girder", "spans": [18.0, 53.0, 18.0],
			"width": 18.0, "clear": 8.0, "material": "concrete", "base": "water", "tier": 3, "conf": 2,
			"src": "de Wikipedia (1961 prestressed concrete, 53 m main opening + 2x18 m side openings, 90-91 m " +
				"long, 12 m carriageway); total width and deck height estimated, OSM way 30062227 bearing | " +
				"verified: de Wikipedia Salztorbruecke: 1961 prestressed concrete frame bridge, 53 m main " +
				"opening over the Donaukanal, 18 m side openings, 90/91 m long, 4-lane 12 m carriageway, " +
				"headroom 6.4 m over the highest navigable water; partial closure from 10 Nov 2026, " +
				"demolition from 2028; OSM way geometry re-measured via api.openstreetmap.org way/full " +
				"(centre and end-to-end bearing agree) way 30062227 centre 48.21432,16.37493 brg 244.2 " +
				"(=64.2), 87.2 m; total width not sourced | round 2: round 2: total width 18 m from Wien " +
				"Geschichte Wiki 'Salztorbruecke' (Spannbetonbruecke, Breite 18 m), consistent with de " +
				"Wikipedia 12 m carriageway + 2 footways; de Wikipedia/Rathauskorrespondenz 1960: main " +
				"opening ~53 m + 2 x 18 m side openings = 89 m vs 90/91 m length (wien.gv.at: 91 m), slender " +
				"pendulum/tie walls so piers are thin; still standing (partial closure from 10 Nov 2026, " +
				"demolition from 2028); centre and bearing re-measured from OSM way 30062227 in round 1"},
		{"id": "br_vienna_schwedenbruecke", "cc": "AT", "name": "Schwedenbrücke", "aliases": ["schwedenbrucke", "swedes bridge vienna"],
			"lat": 48.21213, "lon": 16.37894, "bearing": 17.7, "st": "girder", "spans": [12.2, 55.4, 12.2],
			"width": 27.0, "clear": 8.0, "material": "concrete", "base": "water", "tier": 3, "conf": 2,
			"src": "de Wikipedia (1955 Leonhardt prestressed frame bridge, 27 m wide, spans 12.2+55.4+12.2 m), " +
				"OSM bearing; deck height estimated | verified: de Wikipedia Schwedenbruecke: 1955 " +
				"Rahmenbruecke 27 m wide, Stuetzweiten 12.2+55.4+12.2 m; Structurae (via search snippet) " +
				"gives 12.2+55.4+11.2 m, 78.8 m long (1 m disagreement on one side span; symmetric kept); OSM " +
				"way geometry re-measured via api.openstreetmap.org way/full (centre and end-to-end bearing " +
				"agree) ways 230483960/351751343 centre 48.21213,16.37894 brg 17.7, 72.3 m; width only from " +
				"de Wikipedia"},
		{"id": "br_vienna_aspernbruecke", "cc": "AT", "name": "Aspernbrücke", "aliases": ["aspernbrucke"],
			"lat": 48.21197, "lon": 16.38304, "bearing": 9.8, "st": "girder", "spans": [88.97], "width": 27.95,
			"clear": 8.0, "material": "steel", "base": "water", "tier": 3, "conf": 1,
			"src": "de Wikipedia (length 88.97 m, width 27.95 m, 925 t steel; single span assumed, structure " +
				"type not stated), OSM bearing; deck height estimated | verified: de Wikipedia Aspernbruecke: " +
				"1949-51 Leischner/Waagner-Biro, 88.97 m long, 27.95 m wide, 925 t steel; Structurae and " +
				"wien.gv.at give no static system or span; OSM bbox query was rate-limited so centre and " +
				"bearing not re-measured | round 2: round 2: de Wikipedia: 88.97 m, 27.95 m, 925 t; " +
				"structurae: steel Balkenbruecke; no span layout or static system published in any source " +
				"reachable"},
		{"id": "br_prague_cechuv_most", "cc": "CZ", "name": "Čech Bridge", "wiki": "Svatopluk Čech Bridge",
			"aliases": ["čechův most", "cechuv most"], "lat": 50.09299, "lon": 14.41713, "bearing": 337.0,
			"st": "arch_deck", "spans": [47.8, 53.1, 59.2], "width": 16.0, "clear": 9.0, "rise": 5.0,
			"material": "steel", "base": "water", "tier": 2, "conf": 2,
			"src": "cs Wikipedia (only steel arch bridge in Prague, 1908, 3 arches 47.8+53.1+59.2 m from the " +
				"right bank, 169 m long, 16 m wide), OSM way 127867974 bearing (travel direction reversed vs " +
				"source order: spans listed from the left/south end); deck height and rise estimated | " +
				"verified: cs Wikipedia Cechuv most: only steel arch bridge in Prague, 3 arches " +
				"47.8+53.1+59.2 m rising from the right bank (160.1 m), plus one 10 m concrete field added " +
				"1954-57 (169 m total), 16 m wide (10 m roadway), 24 ribs; OSM way geometry re-measured via " +
				"api.openstreetmap.org way/full (centre and end-to-end bearing agree) way 127867974: first " +
				"end (50.09226,14.41761) is the right (east) bank, travel brg 337.0, so 47.8 m span first is " +
				"correct; deck height and rise estimated"},
		{"id": "br_prague_palackeho_most", "cc": "CZ", "name": "Palacký Bridge", "aliases": ["palackého most", "palackeho most"],
			"lat": 50.07283, "lon": 14.41201, "bearing": 81.9, "st": "masonry",
			"spans": [31.2, 32.8, 34.4, 36.0, 34.4, 32.8, 31.2], "width": 13.9, "clear": 8.0, "rise": 4.0,
			"material": "stone", "base": "water", "tier": 2, "conf": 2,
			"src": "cs+en Wikipedia (7 arches, clear openings 27.2/28.8/30.4/32/30.4/28.8/27.2 m, 228.8 m long, " +
				"now 13.9 m wide), pier thickness 4.0 m derived (228.8-204.8)/6, OSM ways 28311614/476017586 " +
				"bearing; deck height and rise estimated | verified: cs Wikipedia Palackeho most: seven " +
				"vaults 32 (centre), 30.4, 28.8, 27.2 m clear (mirrored) = 204.8 m, 228.8 m long (piers 4.0 " +
				"m), 13.9 m wide after the post-war widening; OSM way geometry re-measured via " +
				"api.openstreetmap.org way/full (centre and end-to-end bearing agree) way 28311614 centre " +
				"50.07287,14.41200 brg 261.2 (=81.2), symmetric; deck height and rise estimated"},
		{"id": "br_prague_jiraskuv_most", "cc": "CZ", "name": "Jirásek Bridge", "aliases": ["jiráskův most", "jiraskuv most"],
			"lat": 50.07556, "lon": 14.41163, "bearing": 81.0, "st": "arch_deck",
			"spans": [51.7, 51.7, 51.8, 51.8, 51.8, 51.8], "width": 21.0, "clear": 9.0, "rise": 7.0,
			"material": "concrete", "base": "water", "tier": 2, "conf": 1,
			"src": "cs Wikipedia (reinforced concrete, 6 arches of 45-51 m, 310.6 m long, 21 m wide, piers 4.6 " +
				"m); equal split of the total, OSM way 171671978 bearing; rise and deck height estimated | " +
				"verified: cs Wikipedia Jiraskuv most: reinforced concrete, six arch fields of 45-51 m, five " +
				"piers 4.6 m wide, 310.6 m long, 21 m wide; OSM way geometry re-measured via " +
				"api.openstreetmap.org way/full (centre and end-to-end bearing agree) way 171671978 brg 80.9 " +
				"(OSM way only 197 m); individual spans unknown | round 2: round 2: cs Wikipedia + prague.eu " +
				"+ kudyznudy: six arch fields of 45-51 m, five 4.6 m piers, 310.6 m, 21 m wide; no per-field " +
				"spans (the row's equal 51.7 m pier-centre spans = 310.6/6 are consistent with mean clear " +
				"opening ~47.9 m + 4.6 m pier, but the 45-51 m spread per field is unknown)"},
		{"id": "br_prague_barrandov_bridge", "cc": "CZ", "name": "Barrandov Bridge", "aliases": ["barrandovský most", "barrandovsky most"],
			"lat": 50.03871, "lon": 14.40735, "bearing": 335.0, "st": "girder",
			"spans": [34.0, 61.0, 71.0, 72.0, 66.0, 45.0], "width": 47.0, "clear": 15.0, "material": "concrete",
			"base": "water", "tier": 2, "conf": 2,
			"src": "cs Wikipedia (span 34+61+71+72+66+45 m = 349 m, deck 15 m above the Vltava, width 40-55 m so " +
				"47 m used), OSM ways 73227632/121254586 bearing; deck is skewed 53 deg to the river | " +
				"verified: cs Wikipedia Barrandovsky most: reinforced/prestressed concrete, spans " +
				"34+61+71+72+66+45 m, 352 m long, deck 15 m above the Vltava, width 40-55 m (two parallel " +
				"carriageway structures, 47 m is a mean); OSM way geometry re-measured via " +
				"api.openstreetmap.org way/full (centre and end-to-end bearing agree) ways " +
				"73227632/121254586/983827589/983827591 brg 333-335; the source does not say which bank the " +
				"34 m span is on (pier positions may be mirrored by up to ~25 m)"},
		{"id": "br_prague_nusle_bridge", "cc": "CZ", "name": "Nusle Bridge", "aliases": ["nuselský most", "nuselsky most"],
			"lat": 50.06562, "lon": 14.43033, "bearing": 358.8, "st": "girder",
			"spans": [68.5, 115.5, 115.5, 115.5, 68.5], "width": 26.5, "clear": 42.5, "material": "concrete",
			"base": "ground", "tier": 2, "conf": 2,
			"src": "cs+en Wikipedia (haunched prestressed box girder, 485 m, 26.5 m wide, spans 2x68.5 + 3x115.5 " +
				"m, mean height 42.5 m above the valley), OSM ways 4083705/115927375; deck height is the mean " +
				"| verified: cs Wikipedia Nuselsky most: prestressed concrete box girder, 485 m long, spans " +
				"2x68.5 + 3x115.5 m, 26.5 m wide, mean height 42.5 m above the valley, four piers; OSM way " +
				"geometry re-measured via api.openstreetmap.org way/full (centre and end-to-end bearing " +
				"agree) ways 4083705/115927375 centre 50.06562,14.4305 brg 358.8 (OSM 585 m includes ramps); " +
				"girder depth looks constant so kept as girder, not haunched"},
		{"id": "br_prague_troja_bridge", "cc": "CZ", "name": "Troja Bridge", "aliases": ["trojský most", "trojsky most"],
			"lat": 50.11249, "lon": 14.43613, "bearing": 343.8, "st": "arch_tied", "spans": [200.4, 40.4],
			"width": 35.25, "clear": 11.0, "rise": 20.0, "material": "steel", "base": "water", "tier": 2, "conf": 2,
			"arch_spans": [0],
			"src": "cs+en Wikipedia (bowstring arch 2014, main span 200.4 m, 262 m long, total structure height " +
				"~34 m over water); width and deck height guessed, OSM way 173751818 bearing | verified: Mott " +
				"MacDonald design paper (events.scia.net): simply supported steel tied arch span 200.4 m, " +
				"rise 20.0 m (1/10), network hangers, prestressed concrete deck, adjoining Troja-side field " +
				"40.4 m (two-girder), overall width 35.25 m; Metrostav reference: fields 200.4 + 40.35 m, " +
				"264.31 m long, width 36.18 m; cs Wikipedia: 262 m long, structure ~34 m above navigation " +
				"level; OSM way geometry re-measured via api.openstreetmap.org way/full (centre and end-to- " +
				"end bearing agree) way 173751818 centre 50.11249,14.43613 brg 343.8 (travel south to north, " +
				"so the 40.4 m field is last); deck height ~11 m estimated"},
		{"id": "br_prague_legion_bridge", "cc": "CZ", "name": "Legion Bridge", "aliases": ["most legií", "most legii", "legií bridge"],
			"lat": 50.08133, "lon": 14.41048, "bearing": 87.7, "st": "masonry",
			"spans": [38.2, 38.2, 38.2, 38.2, 38.1, 38.2, 38.2, 38.2, 38.2], "width": 16.4, "clear": 8.5, "rise": 4.0,
			"material": "stone", "base": "water", "tier": 2, "conf": 1,
			"src": "OSM way 106518154 (344 m, bridge:structure=arch); cs Wikipedia gave no dimensions: spans, " +
				"width, rise all guessed | verified: cs Wikipedia Most Legii: nine very flat vaults of " +
				"differing span (7 elliptic, 2 segmental), granite blocks, 343.45 m, 16.4 m wide; prague.eu: " +
				"spans 34-42 m, seven piers + three abutments; OSM way geometry re-measured via " +
				"api.openstreetmap.org way/full (centre and end-to-end bearing agree) way 106518154 centre " +
				"50.08133,14.41048 brg 87.7; corrected type and material, still conf 1 | round 2: round 2: cs " +
				"Wikipedia + prague.eu: nine flat vaults of 34-42 m on seven piers, 343.45 m, 16.4 m wide; " +
				"per-vault spans and pier width not published"},
		{"id": "br_prague_manes_bridge", "cc": "CZ", "name": "Mánes Bridge", "aliases": ["mánesův most", "manesuv most"],
			"lat": 50.08953, "lon": 14.41277, "bearing": 106.3, "st": "arch_deck", "spans": [38.25, 41.8, 41.8, 38.25],
			"width": 16.0, "clear": 8.5, "rise": 4.1, "material": "concrete", "base": "water", "tier": 2, "conf": 2,
			"src": "cs+en Wikipedia (reinforced concrete with granite facing, 186 m long, 16 m wide); arch count " +
				"and spans guessed by equal split, OSM way 4820233 bearing | verified: TSK Praha tender " +
				"documentation (Mánesův most): four arches, outer 38.25 m, central 41.80 m, rise 4.25 / 4.00 " +
				"m, vault width 16 m, 15.55 m between railings; Structurae agrees (38.2, 2x41.8, 38.2); cs " +
				"Wikipedia: concrete, 186 m long, 16 m wide, four vault fields plus one small field; OSM way " +
				"geometry re-measured via api.openstreetmap.org way/full (centre and end-to-end bearing " +
				"agree) way 4820233 centre 50.08953,14.41277 brg 106.3 (way 195 m includes the small extra " +
				"field, so the arch chain may sit up to ~17 m off the way centre); deck height estimated"},
		{"id": "br_prague_stefanik_bridge", "cc": "CZ", "name": "Štefánik Bridge", "aliases": ["štefánikův most", "stefanikuv most"],
			"lat": 50.09432, "lon": 14.42688, "bearing": 171.3, "st": "arch_deck", "spans": [58.8, 64.4, 65.1],
			"width": 24.4, "clear": 10.0, "rise": 8.0, "material": "concrete", "base": "water", "tier": 2, "conf": 2,
			"src": "cs Wikipedia (reinforced concrete, 3 arches 58.8+64.4+65.1 m, 182 m long); width, deck " +
				"height and rise guessed, OSM way 128721101 bearing | verified: cs Wikipedia (3 reinforced- " +
				"concrete arches 58.8+64.4+65.1 m, 182 m) and virtualni.praha.eu/mosty/stefanikuv-most (three " +
				"segmental arches 59-65 m, deck width 24.4 m, 243 m with ramps); OSM ways 128721101/416051000 " +
				"centre+bearing 171 re-measured; the order of the three spans from the Letna end is not " +
				"stated in any source (max pier shift ~6 m); deck height and rise estimated"},
		{"id": "br_prague_libensky_most", "cc": "CZ", "name": "Libeň Bridge", "aliases": ["libeňský most", "libensky most"],
			"lat": 50.10333, "lon": 14.45958, "bearing": 88.6, "st": "arch_deck",
			"spans": [28.0, 38.5, 42.8, 42.8, 38.5], "width": 21.0, "clear": 8.0, "rise": 4.5, "material": "concrete",
			"base": "water", "tier": 2, "conf": 2,
			"src": "cs+en Wikipedia (five three-hinged concrete arches 28/38.5/42.8/42.8/38.5 m over the new " +
				"channel, 21 m wide); position of this arch group within the 326 m OSM way not known (way mid " +
				"used) | verified: cs Wikipedia: bridge no. V009 has five three-hinged plain-concrete arches " +
				"28+38.5+42.8+42.8+38.5 m over the new channel; en Wikipedia: five arches 28-43 m, 21 m wide, " +
				"tram on the deck; OSM stair nodes at the arch group ends (lon 14.4581 and 14.4610, ~207 m) " +
				"-> group centred at lon 14.45958; way 128964803 bearing 88.6; deck height and rise estimated"},
		{"id": "br_prague_vyton_rail_bridge", "cc": "CZ", "name": "Výtoň Railway Bridge", "aliases": ["výtoň railway bridge", "vyton railway bridge", "vyšehrad railway bridge"],
			"lat": 50.066964, "lon": 14.413443, "bearing": 255.5, "st": "truss", "spans": [72.0, 72.0, 72.0],
			"width": 8.1, "clear": 7.0, "rise": 10.0, "material": "steel", "base": "water", "tier": 3, "conf": 2,
			"src": "cs Wikipedia (1901 steel parabolic truss girders 3 x 72 m, 261 m with stone approach " +
				"arches), OSM ways 158905793/1327958388 bearing; width and deck height guessed | verified: cs " +
				"Wikipedia 'Vysehradsky zeleznicni most': 1900-01 rebuild with three parabolic truss girders " +
				"each 72 m (560 t each), two new stone piers in the river, width 8.1 m (two tracks), 261.05 m " +
				"with the stone viaduct arches; OSM way 158905793 (truss, 241 m) centre 50.0670,14.41366 " +
				"bearing 255.5 re-measured; truss height and deck height estimated | placement: centre moved " +
				"+16 m along the deck (water crossing says +21 m, mapped deck extent +11 m)"},
		{"id": "br_budapest_arpad_bridge", "cc": "HU", "name": "Árpád Bridge", "aliases": ["árpád híd", "arpad hid"],
			"lat": 47.5378, "lon": 19.0526, "bearing": 109.5, "st": "girder",
			"spans": [103.0, 102.0, 103.0, 102.0, 103.0, 102.0, 103.0, 102.0, 103.0], "width": 35.4, "clear": 10.0,
			"material": "steel", "base": "water", "tier": 2, "conf": 1,
			"src": "hu+en Wikipedia (928 m long plate-girder bridge with 103 m and 102 m openings, widened 1980s " +
				"to 35.4 m); alternating 103/102 order assumed (sum 928); deck height estimated, OSM tram " +
				"ways 454357840/59 bearing | verified: en Wikipedia List of bridges in Hungary (from Duna- " +
				"hidjaink pp.54-57) gives the layout as 82+103+103+82 m (Buda arm) and 76+102+76 m (Pest " +
				"arm), main 103 m, 928 m long, separated by the Margaret Island section; hu Wikipedia: 103 m " +
				"spans on the Buda side, width 35.4 m; so the first-pass nine alternating 103/102 spans (sum " +
				"923) are wrong and one continuous chain cannot be modelled | round 2: round 2: hu Wikipedia: " +
				"928 m, 103 and 102 m openings, Buda-side 103 m, 35.4 m wide, island section between the two " +
				"arms; en list gives 82+103+103+82 / 76+102+76; the two sources do not agree on a single " +
				"chain and the island gap cannot be modelled"},
		{"id": "br_budapest_petofi_bridge", "cc": "HU", "name": "Petőfi Bridge", "aliases": ["petőfi híd", "petofi hid"],
			"lat": 47.47868, "lon": 19.06313, "bearing": 54.5, "st": "truss", "spans": [112.0, 154.0, 112.0],
			"width": 25.6, "clear": 9.0, "rise": 6.5, "material": "steel", "base": "water", "tier": 2, "conf": 2,
			"src": "hu Wikipedia infobox (steel lattice girder, max span 154 m, 378 m long, 25.6 m wide; girder " +
				"depth 1/24 and 1/32 of the spans); side spans split evenly, depth treated as 4.8 m, deck " +
				"height estimated, OSM ways 54724406/333834867 bearing | verified: hu Wikipedia 'Petofi hid' " +
				"(via fetch): spans 112.0+154.0+112.0 m, 378 m long (514 m with ramps), width 25.6 m (2x10.2 " +
				"m carriageway + 2x2.6 m footways... as stated), steel lattice continuous girder with " +
				"variable depth (1/24 side spans, 1/32 mid-span, much deeper over the piers); OSM tram way " +
				"333834867/54724406 (420 m) centre 47.47868,19.06313 bearing 54.5 re-measured; deck height " +
				"estimated"},
		{"id": "br_budapest_rakoczi_bridge", "cc": "HU", "name": "Rákóczi Bridge", "aliases": ["rákóczi híd", "rakoczi hid", "lágymányosi híd", "lagymanyosi bridge"],
			"lat": 47.46877, "lon": 19.06736, "bearing": 92.0, "st": "girder",
			"spans": [57.95, 94.72, 94.72, 94.72, 94.72, 57.95], "width": 30.6, "clear": 9.0, "material": "steel",
			"base": "water", "tier": 2, "conf": 1,
			"src": "hu Wikipedia infobox (steel girder, max span 94.72 m, 494.8 m long, 30.6 m wide, formerly " +
				"Lagymanyosi Bridge); six-span split with 57.95 m end spans inferred, deck height estimated, " +
				"OSM ways 59552712/21 bearing | verified: hu Wikipedia 'Rakoczi hid' + mageba ref sheet: " +
				"steel girder, largest span 94.72 m, 494.8 m, 30.6 m wide, five piers/pylons; OSM ways " +
				"59552712/59552721 (494 m, mid 47.4688,19.0674, bearing 92.0) agree; the 57.95 m end spans " +
				"are only the remainder (494.8-4x94.72)/2 and Structurae calls the girder haunched, so the " +
				"span list is not independently sourced | round 2: round 2: hu Wikipedia + search: no span " +
				"table beyond 94.72 m max span / 494.8 m; end spans only a remainder"},
		{"id": "br_bern_kirchenfeld_bridge", "cc": "CH", "name": "Kirchenfeld Bridge", "aliases": ["kirchenfeldbrücke", "kirchenfeldbrucke"],
			"lat": 46.94544, "lon": 7.44866, "bearing": 169.7, "st": "arch_deck", "spans": [78.0, 78.0], "width": 13.2,
			"clear": 37.0, "rise": 22.0, "material": "iron", "base": "water", "tier": 2, "conf": 3,
			"src": "de Wikipedia infobox (1883 wrought-iron arch bridge, two arches span 78 m, springing-to- " +
				"crown 22 m, deck 37 m over the Aare, 13.2 m wide, 229 m with masonry approaches), OSM " +
				"bearing; coords agree with wiki within 35 m | verified: de Wikipedia infobox (2 openings, " +
				"span 78 m, Pfeilhoehe 22 m, Hoehe 37 m, 13.2 m wide, 229 m long, wrought-iron/steel arch; " +
				"coordinates 46.94575,7.44857); OSM way 312022667 (229 m) mid 46.94544,7.44865 bearing 349.7 " +
				"-> 169.7 re-measured, agrees"},
		{"id": "br_bern_lorraine_bridge", "cc": "CH", "name": "Lorraine Bridge", "aliases": ["lorrainebrücke", "lorrainebrucke"],
			"lat": 46.95281, "lon": 7.44317, "bearing": 47.9, "st": "arch_deck", "spans": [82.0], "width": 18.0,
			"clear": 37.5, "rise": 31.0, "material": "concrete", "base": "water", "tier": 2, "conf": 3,
			"src": "de Wikipedia (Maillart 1930 concrete box arch, 82.0 m clear span, rise 31.0 m, deck 37.5 m " +
				"over water, 18 m wide, 178 m long); approach arches omitted, OSM bearing | verified: de " +
				"Wikipedia 'Lorrainebruecke': 178 m long, 18 m wide, deck 37.5 m above the water, main arch " +
				"82.0 m clear span with 31.0 m rise (Maillart, unreinforced concrete boxes); OSM way 48846008 " +
				"(170 m) mid 46.95283,7.44322 bearing 227.7 -> 47.7 re-measured"},
		{"id": "br_bern_nydegg_bridge", "cc": "CH", "name": "Nydegg Bridge", "wiki": "Nydeggbrücke",
			"aliases": ["nydeggbrücke", "nydeggbrucke"], "lat": 46.94847, "lon": 7.45842, "bearing": 95.9,
			"st": "masonry", "spans": [19.5, 49.0, 19.5], "width": 12.2, "clear": 28.0, "rise": 22.0,
			"material": "stone", "base": "water", "tier": 2, "conf": 1,
			"src": "de Wikipedia (1844 stone bridge, main arch ~46 m, two side arches 16.5 m, central part 124.3 " +
				"m, ~200 m overall); piers, width, deck height and rise guessed, OSM bearing | verified: de " +
				"Wikipedia 'Nydeggbruecke': ~200 m long, 124.3 m between the pavilions, main arch just under " +
				"46 m (en: 45.9 m), side arches 16.5 m, width 12.2 m over the Aare / 15.6 m over the side " +
				"arches / 25.2 m at the approaches; pier thickness, deck height and rise not given | round 2: " +
				"round 2: de Wikipedia: main arch just under 46 m, side arches 16.5 m, 124.3 m between " +
				"pavilions of ~200 m total (so 46+2x16.5 does not fill the central part); width 12.2 m over " +
				"Aare; pier thickness and the remaining arches unknown"},
		{"id": "br_bern_untertor_bridge", "cc": "CH", "name": "Untertor Bridge", "wiki": "Untertorbrücke",
			"aliases": ["untertorbrücke", "untertorbrucke"], "lat": 46.94939, "lon": 7.45846, "bearing": 80.5,
			"st": "masonry", "spans": [17.5, 17.5, 17.5], "width": 7.5, "clear": 8.1, "rise": 5.0, "material": "stone",
			"base": "water", "tier": 3, "conf": 1,
			"src": "de Wikipedia infobox (stone arch bridge 15th c., three openings, 52.5 m long, 7.5 m wide, " +
				"height 8.1 m), OSM bearing; equal arches assumed, rise estimated | verified: de Wikipedia " +
				"infobox: 52.5 m long, 7.5 m wide, 3 openings, height 8.1 m; en Wikipedia: three slender tuff " +
				"arches, longest span 15.1 m, two piers in the water, 4.3 m clearance below -> the arches are " +
				"not equal, so the equal 17.5 m split is wrong | round 2: round 2: de Wikipedia infobox (3 " +
				"openings, 52.5 m, 7.5 m wide) + en (longest 15.1 m): the arches are unequal and the " +
				"individual spans are not published"},
		{"id": "br_bern_kornhaus_bridge", "cc": "CH", "name": "Kornhaus Bridge", "aliases": ["kornhausbrücke", "kornhausbrucke"],
			"lat": 46.95095, "lon": 7.44865, "bearing": 18.5, "st": "arch_deck",
			"spans": [36.0, 36.0, 115.0, 36.0, 36.0, 36.0], "width": 12.6, "clear": 48.0, "rise": 20.0,
			"material": "steel", "base": "water", "tier": 2, "conf": 1,
			"src": "de Wikipedia infobox (steel arch bridge 1898, 382 m, 12.5 m wide, 6 openings 115 m + 5 x 36 " +
				"m, 48 m high); order of the openings and arch rise guessed, OSM bearing | verified: de " +
				"Wikipedia 'Kornhausbruecke (Bern)': steel truss arches with raised deck, 6 openings, main " +
				"opening 115 m + five small arches (text 34 m each, infobox 36 m), 382 m long, 12.6 m wide " +
				"(infobox 12.5), deck 47.76 m above Aare low water; sequence of openings along the deck, arch " +
				"rise and the 382 m vs 295 m discrepancy are not explained | round 2: round 2: de Wikipedia " +
				"text: main opening 115 m + five small arches of 34 m (infobox 36 m), 382 m long, 12.6 m " +
				"wide, deck 47.76 m above low water; 115+5x34 = 285 m vs 382 m (and the order along the deck) " +
				"unexplained"},
		{"id": "br_warsaw_poniatowski_bridge", "cc": "PL", "name": "Poniatowski Bridge", "aliases": ["most poniatowskiego", "most księcia józefa poniatowskiego"],
			"lat": 52.23598, "lon": 21.04125, "bearing": 71.4, "st": "arch_deck",
			"spans": [46.5, 46.5, 80.0, 80.0, 80.0, 80.0, 46.5, 46.5], "width": 21.4, "clear": 10.0, "rise": 6.0,
			"material": "steel", "base": "water", "tier": 2, "conf": 1,
			"src": "en+pl Wikipedia (steel deck arch bridge, 8 spans, 506 m, 21.4 m wide, main span 80 m); " +
				"individual spans NOT sourced (4x80 + 4x46.5 assumed), rise and deck height guessed, OSM ways " +
				"237351914/303805844 bearing | verified: pl Wikipedia infobox 'Most Poniatowskiego': 8 steel " +
				"arch spans 32+55+68+80+68+58+58+38 m (sum 457 m, length 506 m, width 21.4 m, tram) - these " +
				"are the pre-war arches; the bridge was blown up in 1944 and rebuilt 1945-46 on the old piers " +
				"with different spans ('inna jest konstrukcja przesel'); the first-pass 4x46.5+4x80 split is " +
				"not supported and the order/pier-to-pier values are unverified | round 2: round 2: pl " +
				"Wikipedia infobox: 8 spans 32+55+68+80+68+58+58+38 m (506 m, 21.4 m) belong to the pre-1944 " +
				"arches; four arch spans (274 m) were blown up 1944 and the rebuilt 1946 spans have a " +
				"different construction, rebuilt layout not published"},
		{"id": "br_warsaw_swietokrzyski_bridge", "cc": "PL", "name": "Holy Cross Bridge", "aliases": ["most świętokrzyski", "most swietokrzyski", "swietokrzyski bridge"],
			"lat": 52.24182, "lon": 21.03411, "bearing": 54.4, "st": "stayed",
			"spans": [30.0, 40.0, 40.0, 180.0, 140.0], "width": 30.8, "clear": 12.0, "tower": 100.0, "towers": [4],
			"pylon": "single", "material": "steel", "base": "water", "tier": 2, "conf": 2,
			"src": "en Wikipedia (cable-stayed, 479 m, 30 m wide, main span 180 m, single 90 m tower on the east " +
				"bank, two piers near the west bank); other span lengths guessed, tower top above water " +
				"estimated, OSM ways 4937006/242607702 bearing (tagged suspension in OSM) | verified: pl " +
				"Wikipedia infobox 'Most Swietokrzyski': 7 spans 30+40+40+180+140+37+12 m = 479 m with the " +
				"viaduct, bridge itself 430 m (30+40+40+180+140), width 30.8 m; en Wikipedia: cable-stayed, " +
				"479 m, single pylon, main span 180 m, 30 m wide; OSM ways 242607702/4937006 (453-462 m) mid " +
				"52.2418,21.0341 bearing 54.4 (west to east) agree with the wiki coordinate 52.2417,21.0339; " +
				"pylon at the 180/140 junction (index 4) assumed from the span order west to east; tower top " +
				"above water and deck height estimated"},
		{"id": "br_warsaw_slasko_dabrowski_bridge", "cc": "PL", "name": "Silesian–Dąbrowa Bridge", "aliases": ["most śląsko-dąbrowski", "most slasko-dabrowski", "slasko-dabrowski bridge"],
			"lat": 52.24927, "lon": 21.02198, "bearing": 235.0, "st": "girder",
			"spans": [87.8, 87.8, 87.8, 87.8, 87.8, 87.8], "width": 20.7, "clear": 10.0, "material": "steel",
			"base": "water", "tier": 2, "conf": 1,
			"src": "en+pl Wikipedia (steel, 6 spans, 527 m, 20.7 m wide); span lengths and structure type NOT " +
				"sourced (equal split), OSM way 1028356267 bearing | verified: pl Wikipedia infobox: 6 spans, " +
				"527 m, 20.7 m wide (14.7 m carriageway + 2x3 m); a bridge-table snippet says plate girder, " +
				"475 m, longest span 79.25 m and a Polish article says a continuous five-span girder with an " +
				"orthotropic deck, so the equal 87.8 m split and the span count are contradictory; built " +
				"1947-49 on the piers of the Kierbedz bridge | round 2: round 2: pl Wikipedia infobox: 6 " +
				"spans, 527 m, 20.7 m wide, empty span field; another snippet gives plate girder 475 m / " +
				"longest 79.25 m; contradictory, no span table found"},
		{"id": "br_warsaw_gdanski_bridge", "cc": "PL", "name": "Gdańsk Bridge", "aliases": ["most gdański", "most gdanski", "gdanski bridge"],
			"lat": 52.261, "lon": 21.01034, "bearing": 64.0, "st": "truss",
			"spans": [67.75, 67.75, 67.75, 67.75, 67.75, 67.75], "width": 17.0, "clear": 11.0, "rise": 8.0,
			"material": "steel", "base": "water", "tier": 2, "conf": 1,
			"src": "en+pl Wikipedia (six-span steel truss, 406.5 m, 17 m wide, two decks); equal spans assumed, " +
				"truss depth and deck height guessed, OSM way 198517310 bearing | verified: pl Wikipedia " +
				"infobox: 6 spans, 406.5 m (406.53 m main bridge, two decks), steel truss on the 1908 Citadel " +
				"bridge piers, Ratynski 1957-59; individual spans, truss height and width are not given (17 m " +
				"is only the first-pass figure) | round 2: round 2: pl Wikipedia: six-span steel truss 406.53 " +
				"m main bridge, two decks, on the 1908 Citadel bridge piers; span list empty, width and truss " +
				"height not stated"},
		{"id": "br_warsaw_siekierki_bridge", "cc": "PL", "name": "Siekierki Bridge", "aliases": ["most siekierkowski", "siekierkowski bridge"],
			"lat": 52.2141, "lon": 21.092, "bearing": 43.6, "st": "stayed", "spans": [48.0, 77.0, 250.0, 77.0, 48.0],
			"width": 37.0, "clear": 15.0, "tower": 90.0, "towers": [2, 3], "material": "concrete", "base": "water",
			"tier": 2, "conf": 2,
			"src": "pl Wikipedia (cable-stayed 2002, spans 48+77+250+77+48 m, 500 m, width 33.4-40.4 m so 37 " +
				"used, two H-shaped pylons of ~90 m); deck height and tower top above water estimated, OSM " +
				"way 4925779 bearing | verified: pl Wikipedia infobox 'Most Siekierkowski': 5 spans " +
				"48+77+250+77+48 = 500 m, width 33.38-40.38 m (2x10.5 m carriageways, 3-5.19 m footways), " +
				"H-shaped pylons 90.00 and 90.06 m (Structurae/en: 87 m); OSM way 4925779 (667 m incl. ramps) " +
				"bearing 43.6 and wiki coordinate 52.2144,21.0925 agree with the row centre within 45 m; " +
				"tower top above water and deck height estimated (pylon height reference not stated)"},
		{"id": "br_warsaw_lazienki_bridge", "cc": "PL", "name": "Łazienki Bridge", "aliases": ["most łazienkowski", "most lazienkowski", "lazienkowski bridge"],
			"lat": 52.22533, "lon": 21.04927, "bearing": 71.6, "st": "girder", "spans": [76.5, 90.0, 90.0, 90.0, 76.5],
			"width": 27.5, "clear": 12.0, "material": "steel", "base": "water", "tier": 2, "conf": 2,
			"src": "pl Wikipedia (steel girder 1974, spans 76.5+3x90+76.5 m = 423 m, 27.5 m wide), OSM way " +
				"203622898 bearing; deck height estimated | verified: pl Wikipedia infobox 'Most " +
				"Lazienkowski': 5 spans 76.5+3x90+76.5 m = 423 m (424.5 m), width 27.5 m, continuous five- " +
				"span steel girder with orthotropic plate; OSM ways 203622898/513176330 bearing 71.6 and wiki " +
				"coordinate 52.22528,21.04917 agree with the row; deck height estimated"},
		{"id": "br_warsaw_grot_rowecki_bridge", "cc": "PL", "name": "Gen. Stefan Grot-Rowecki Bridge", "wiki": "General Stefan Grot-Rowecki Bridge",
			"aliases": ["most grota-roweckiego", "most toruński", "grota-rowecki bridge"], "lat": 52.28669,
			"lon": 20.99405, "bearing": 53.2, "st": "girder", "spans": [75.0, 90.0, 90.0, 90.0, 120.0, 120.0, 60.0],
			"width": 46.2, "clear": 11.0, "material": "steel", "base": "water", "tier": 2, "conf": 2,
			"src": "pl Wikipedia (7 spans 75+3x90+2x120+60 m = 645 m, 46.19 m wide), OSM ways 262572765/6 " +
				"bearing; span order along the bearing and deck height not verified | verified: pl Wikipedia " +
				"infobox 'Most gen. Stefana Grota-Roweckiego': 7 spans 75+3x90+2x120+60 m = 645 m, width " +
				"46.19 m, two structurally independent halves, built 1977-81 (rebuilt 2013-15), left-bank " +
				"(west) abutment first in the article; OSM way 262572765 (676 m, 52.28487,20.99007 -> " +
				"52.28851,20.99803) bearing 53.2 (west to east) re-measured; the span order west to east " +
				"follows the article's listing convention (left bank first) but no source states it; deck " +
				"height estimated"},
		{"id": "br_bratislava_snp_bridge", "cc": "SK", "name": "SNP Bridge", "wiki": "Most SNP",
			"aliases": ["most snp", "novy most bratislava", "ufo bridge", "most slovenského národného povstania"],
			"lat": 48.1384, "lon": 17.10458, "bearing": 178.2, "st": "stayed", "spans": [74.8, 303.0, 54.0],
			"width": 21.0, "clear": 19.0, "tower": 95.0, "towers": [2], "pylon": "single", "material": "steel",
			"base": "water", "tier": 1, "conf": 2,
			"src": "sk Wikipedia infobox (1972, 74.8+303+54 m = 430.8 m, 21 m wide, single A-frame pylon on the " +
				"Petrzalka bank, 95 m overall); tower top above water and deck height estimated, OSM ways " +
				"34325343/25737798 bearing | verified: sk Wikipedia 'Most SNP' infobox/text: spans " +
				"74.80+303+54 m = 430.8 m, width 21 m, single pylon 84.6 m, 95 m overall from the " +
				"foundations, steel; pedestrian level (under the road) measured 17.3 m above the water at " +
				"stage 321 cm -> road deck ~19 m; OSM ways 34325343/25737798 bearing 178.2 kept"},
		{"id": "br_bratislava_apollo_bridge", "cc": "SK", "name": "Apollo Bridge", "aliases": ["most apollo", "apollo most"],
			"lat": 48.13694, "lon": 17.12801, "bearing": 0.6, "st": "arch_tied", "spans": [231.0], "width": 32.0,
			"clear": 11.0, "rise": 36.0, "material": "steel", "base": "water", "tier": 2, "conf": 2,
			"src": "en+sk Wikipedia (steel arch 2005, span 231 m, arch height 36 m, 854 m with viaducts, 32 m " +
				"wide); the arch is not centred on the whole bridge (position along the way uncertain), deck " +
				"height estimated, OSM way 59577497 bearing | verified: sk Wikipedia 'Most Apollo': arch span " +
				"231 m, arch height 36 m, width 32 m, 20 piers, main bridge field 517 m, 835 m with viaducts " +
				"(en: 854 m); the arch alone is modelled at the sk Wikipedia coordinate 48.13694,17.12806 " +
				"(centre of the river crossing) instead of the 708 m OSM way mid; OSM way 46689592 near the " +
				"arch runs 180.6/0.6 degrees (the 6.6 bearing was the whole-way average); deck height " +
				"estimated"},
		{"id": "br_bratislava_lafranconi_bridge", "cc": "SK", "name": "Lafranconi Bridge", "wiki": "Lanfranconi Bridge",
			"aliases": ["most lafranconi", "lanfranconi bridge", "most lanfranconi"], "lat": 48.1425, "lon": 17.0753,
			"bearing": 6.6, "st": "haunched", "spans": [109.0, 109.0, 109.0, 109.0, 109.0, 109.0, 109.0], "width": 30.0,
			"clear": 12.0, "material": "concrete", "base": "water", "tier": 2, "conf": 1, "pier_depth": 11.0,
			"src": "en+sk Wikipedia (7 spans, 761-766 m, four lanes, 30 m wide); individual spans NOT sourced " +
				"(equal split), deck height guessed, OSM way 5070198 bearing | verified: sk Wikipedia 'Most " +
				"Lanfranconi': seven spans, 761 m (en: 766 m, 1134 m with viaducts), four-lane 30 m wide, " +
				"girder depth 11 m at the central pier tapering to 2.7 m at the ends = variable-depth " +
				"(haunched) concrete box; no individual span lengths found | round 2: round 2: sk/en " +
				"Wikipedia + Doprastav page: 761-766 m, 30 m wide, variable-depth box; no span table found " +
				"(doprastav page empty)"},
		{"id": "br_bratislava_stary_most", "cc": "SK", "name": "Old Bridge Bratislava", "wiki": "Starý most",
			"aliases": ["starý most", "stary most bratislava"], "lat": 48.13797, "lon": 17.11712, "bearing": 183.3,
			"st": "truss", "spans": [116.5, 116.5, 116.5, 116.5], "width": 14.0, "clear": 9.0, "rise": 6.0,
			"material": "steel", "base": "water", "tier": 2, "conf": 1,
			"src": "OSM ways 309710782/329700101 (466 m, truss, service/cycleway/tram); sk Wikipedia gives no " +
				"span data for the rebuilt 2016 bridge: spans, width and truss depth guessed | verified: sk " +
				"Wikipedia 'Stary most (Bratislava)': pre-2016 iron bridge 460 m on stone piers, rebuilt " +
				"2015-16 as a launched steel structure for trams (two old piers removed, one new pier built); " +
				"no span lengths, width or truss height published | round 2: round 2: sk Wikipedia: rebuilt " +
				"2015-16, no span lengths, width or truss height published"},
		{"id": "br_ljubljana_triple_bridge", "cc": "SI", "name": "Triple Bridge", "aliases": ["tromostovje", "three bridges ljubljana"],
			"lat": 46.05112, "lon": 14.50622, "bearing": 335.7, "st": "masonry", "spans": [13.0], "width": 21.0,
			"clear": 3.3, "rise": 1.6, "material": "stone", "base": "water", "tier": 1, "conf": 1,
			"src": "en+sl Wikipedia (central 1842 stone bridge flanked by two Plecnik concrete footbridges of " +
				"23.15 and 23.80 m arches); central span, overall width of the three decks and heights " +
				"guessed; modelled as one wide arch; OSM ways 453076140-2 bearing | verified: sl Wikipedia " +
				"'Tromostovje': central 1842 stone bridge (original cross-section 6.14 m with two 1.88 m " +
				"footways) plus two Plecnik concrete arch footbridges of 23.15 m and 23.80 m span, each 3.90 " +
				"m wide; the stone bridge span, total width, deck height and rise are not given and three " +
				"parallel decks cannot be modelled as one wide arch faithfully | round 2: round 2: sl " +
				"Wikipedia: central stone bridge + two Plecnik arch footbridges (23.15 and 23.80 m); three " +
				"parallel decks cannot be modelled as one arch"},
		{"id": "br_ljubljana_butchers_bridge", "cc": "SI", "name": "Butchers' Bridge", "aliases": ["mesarski most", "butchers bridge ljubljana"],
			"lat": 46.05173, "lon": 14.5088, "bearing": 163.7, "st": "girder", "spans": [31.0], "width": 14.0,
			"clear": 3.5, "material": "steel", "base": "water", "tier": 3, "conf": 1,
			"src": "en Wikipedia / OSM way 69808616 (31 m, pedestrian, width tag 14 m, bearing 163.7); span and " +
				"deck height from OSM only, structure assumed | verified: OSM way 69808616 (30.7 m, width tag " +
				"14 m, seamark clearance 5.5 m, bearing 163.7, mid 46.05173,14.50880) vs en Wikipedia " +
				"'Butchers' Bridge' (33 m long, 17.3 m wide, 2010 footbridge by Jurij Kobe with glass walking " +
				"belts); length and width disagree between sources and the structure type is not stated | " +
				"round 2: round 2: en Wikipedia / OSM only: 33 m x 17.3 m vs OSM 30.7 m / width tag 14 m; " +
				"type not stated"},
		{"id": "br_ljubljana_dragon_bridge", "cc": "SI", "name": "Dragon Bridge", "wiki": "Dragon Bridge (Ljubljana)",
			"aliases": ["zmajski most", "zmaj bridge"], "lat": 46.05195, "lon": 14.51041, "bearing": 344.0,
			"st": "arch_deck", "spans": [33.34], "width": 15.3, "clear": 5.5, "rise": 5.0, "material": "concrete",
			"base": "water", "tier": 2, "conf": 1,
			"src": "en+sl Wikipedia (1901 reinforced concrete arch, main span 33.34 m); width (~15.3 m from " +
				"memory) and rise/deck height estimated, OSM way 6993099 (Resljeva cesta, 38 m) bearing | " +
				"verified: en+sl Wikipedia: 1901 triple-hinged reinforced-concrete (Melan) arch, span 33.34 m " +
				"(confirmed by two sources); OSM way 6993099 (37.9 m, Resljeva cesta, mid 46.05195,14.51041, " +
				"bearing 344.0) re-measured and agrees; deck width, deck height and rise are not given by any " +
				"source found (15.3 m is unsourced) | round 2: round 2: en+sl Wikipedia (33.34 m triple- " +
				"hinged Melan arch); neither article gives width, rise or deck height (infobox empty)"},
		{"id": "br_zagreb_adriatic_bridge", "cc": "HR", "name": "Adriatic Bridge", "aliases": ["jadranski most", "adriatic bridge zagreb"],
			"lat": 45.7832, "lon": 15.95187, "bearing": 169.9, "st": "girder",
			"spans": [62.74, 62.74, 62.74, 62.74, 62.74], "width": 36.8, "clear": 9.0, "material": "concrete",
			"base": "water", "tier": 2, "conf": 1,
			"src": "en Wikipedia (1981 girder bridge over the Sava, main span 63 m, 313.7 m long, 36.8 m wide); " +
				"five equal spans assumed, deck height estimated, OSM way 157405572 bearing | verified: hr " +
				"Wikipedia 'Jadranski most': main section is a continuous structure with SEVEN spans " +
				"totalling 313.7 m (plus one 18.55 m span on the north viaduct and four spans totalling 78.4 " +
				"m on the south viaduct); no individual span lengths or width given; en Wikipedia main span " +
				"63 m, width 36.8 m; the first-pass five equal 62.74 m spans contradict the seven-span count " +
				"| round 2: round 2: hr/en Wikipedia: seven continuous spans totalling 313.7 m, 63 m max, " +
				"36.8 m wide; Gradjevinar/hrcak search found no span table"},
		{"id": "br_zagreb_homeland_bridge", "cc": "HR", "name": "Homeland Bridge", "aliases": ["domovinski most", "domovinski most zagreb"],
			"lat": 45.77103, "lon": 16.06863, "bearing": 130.2, "st": "extradosed",
			"spans": [48.0, 60.0, 60.0, 60.0, 60.0, 60.0, 60.0, 72.0, 120.0, 72.0, 60.0, 60.0, 48.0], "width": 34.0,
			"clear": 10.0, "tower": 26.5, "towers": [8, 9], "material": "concrete", "base": "water", "tier": 2,
			"conf": 1,
			"src": "hr Wikipedia (2007 prestressed concrete, 860 x 34 m, spans 48+6x60+72+120+72+2x60+48 m, " +
				"central part hung from two pairs of 16.5 m pylons = extradosed, not representable); sum is " +
				"840 m, OSM way 29274580 (890 m) bearing | verified: hr Wikipedia 'Domovinski most': " +
				"prestressed concrete, 860 x 34 m, spans 48+6x60+72+120+72+2x60+48 m (13 spans, sum 840 m), " +
				"central part hung from two pairs of 16.5 m pylons (extradosed, towers on the supports either " +
				"side of the 120 m span = indices 8 and 9, top = clear 10 + 16.5); OSM way 29274580 (890 m, " +
				"bearing 130.2 = NW to SE; hr wiki says the SE end joins Radnicka cesta); the direction in " +
				"which the span list is read (6x60 side first) is not stated and the 840 vs 860 m gap is " +
				"unexplained | round 2: round 2: hr Wikipedia is the only source for " +
				"48+6x60+72+120+72+2x60+48 m (sum 840 m vs 860 m stated); web search of " +
				"hrcak/Gradjevinar/Structurae found no second source and no statement of the reading " +
				"direction"},
	]
