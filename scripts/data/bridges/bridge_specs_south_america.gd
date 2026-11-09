class_name BridgeSpecsSouthAmerica
extends RefCounted

## Capital bridge rows for South America (see BridgeSpec for the schema). Figures are
## sourced per row in `src`; conf 1 rows are kept as data but not built
## (BridgeSpec.MIN_BUILT_CONF).

static func rows() -> Array:
	return [
		{"id": "br_buenos_aires_puente_de_la_mujer", "cc": "AR", "name": "Puente de la Mujer", "wiki": "Puente de la Mujer",
			"aliases": ["woman's bridge", "puente de la mujer buenos aires"], "lat": -34.60802, "lon": -58.36513,
			"bearing": 84.4, "st": "swing", "spans": [25.0, 102.5, 32.5], "width": 6.2, "clear": 6.0,
			"material": "steel", "base": "water", "tier": 1, "conf": 1, "moving": 1,
			"src": "es Wikipedia (170 m = 25+32.5 fixed + 112.5 swing span, 6.2 m wide, mast 34-39 m), OSM " +
				"snapshot bearing/centre (agrees with wiki coords ~20 m); swing span with inclined " +
				"counterweight mast cannot be represented; clear and tower estimated | verified: en Wikipedia " +
				"+ EcuRed + Wikidata Q2336867 (length 160 m): fixed spans 25 and 32.5 m + swing span 102.5 m " +
				"(es Wikipedia says 112.5 m, sums to the 170 m of its infobox; 160 m in Wikidata/OSM way " +
				"307155462 = 163 m favours 102.5); OSM way 307155462 (bridge=movable, swing) centre " +
				"-34.60802,-58.36513, bearing 264.4 E->W = 84.4 W->E; the order of the 25 m / 32.5 m fixed " +
				"spans along the deck is not established, the pivot is at the mast foot not the span centre, " +
				"inclined mast not modelled | round 2: round 2: es Wikipedia re-read: 170 m, 6.20 m wide, " +
				"fixed spans 25 and 32.5 m + 112.5 m swing span, 800 t, ~39 m inclined mast; single-mast " +
				"cable-stayed swing footbridge is not representable by the swing type and span order is " +
				"unsourced"},
		{"id": "br_buenos_aires_puente_pueyrredon", "cc": "AR", "name": "Puente Pueyrredón", "wiki": "Puente Pueyrredón",
			"aliases": ["puente pueyrredon", "pueyrredon bridge", "puente pueyrredon viejo"], "lat": -34.6569,
			"lon": -58.37349, "bearing": 315.5, "st": "bascule", "spans": [26.928, 38.0, 26.928], "width": 16.94,
			"clear": 5.8, "material": "steel", "base": "water", "tier": 2, "conf": 2,
			"src": "es Wikipedia (1931 Ottanelli bascule, 91.86 m, spans 26.93/38/26.93, 12 m roadway + 2x2.47 m " +
				"footways, girder underside +6.1 m), coords from wiki; bearing ESTIMATED (no OSM geometry " +
				"reachable); clear estimated | verified: es Wikipedia technical sheet (spans " +
				"26.928/38.00/26.928 = 91.856 m between abutment axes, roadway 12.00 + 2x2.47 m footways, " +
				"pavement +7.47 m and girder soffit +6.10 m on Riachuelo zero; Ottanelli bascule 1931, still " +
				"standing, reopened 2010); OSM roads/footways on the bridge (bearing 315.5/135.5, NOT 205: " +
				"first pass bearing was wrong) and Riachuelo bank crossings along the axis (87 m bank to " +
				"bank, centre moved 15 m NW to the middle of the banks); clear = 5.8 estimated (road is 7.47 " +
				"m over Riachuelo zero, mean water per es Avellaneda article is ~2.9 m above zero, so 4.6-7 " +
				"m)"},
		{"id": "br_buenos_aires_puente_bosch", "cc": "AR", "name": "Puente Bosch", "aliases": ["puente carlos bosch", "puente balanceador bosch"],
			"lat": -34.65753, "lon": -58.37821, "bearing": 347.7, "st": "bascule", "spans": [16.0, 20.5, 16.5],
			"width": 10.0, "clear": 4.5, "material": "steel", "base": "water", "tier": 3, "conf": 2,
			"src": "es Wikipedia (1908 riveted bascule, spans 16/20.5/16.5 m, 6.2 m carriageway, 4.1 m vehicle " +
				"limit), coords from wiki; bearing, footway width and deck height ESTIMATED | verified: es " +
				"Wikipedia 'Puente Bosch' (1908 riveted bascule with Warren top trusses; spans 16 m south, " +
				"20.5 m centre, 16.5 m north, girder axis spacing 9.3/9.4/10.9 m, carriageway 6.2 m, 4.1 m " +
				"height limit); OSM ways 1323956691/305429230/305429231 (bearing 167.7 N->S, centre " +
				"-34.65753,-58.37821), Riachuelo bank crossings 52 m apart vs 53 m of spans; spans order = " +
				"south first so bearing 347.7; width 10.0 from the girder spacing (carriageway 6.2 m); clear " +
				"4.5 estimated"},
		{"id": "br_buenos_aires_puente_victorino_de_la_plaza", "cc": "AR", "name": "Puente Victorino de la Plaza", "aliases": ["puente velez sarsfield", "puente vélez sarsfield"],
			"lat": -34.66077, "lon": -58.38823, "bearing": 356.2, "st": "bascule", "spans": [19.5, 25.4, 19.5],
			"width": 15.44, "clear": 4.3, "material": "iron", "base": "water", "tier": 3, "conf": 2,
			"src": "es Wikipedia (1916, 64.4 m, spans 19.5/25.4/19.5 m, 12 m roadway + 2x1.72 m footways, girder " +
				"underside +4.67 m; double Scherzer bascule), coords from wiki; bearing and clear ESTIMATED | " +
				"verified: es Wikipedia technical sheet (1916 double-leaf Scherzer bascule, through trusses, " +
				"64.40 m between abutment axes = 19.50+25.40+19.50, roadway 12.00 + 2x1.72 m footways, " +
				"pavement +6.07 m, girder soffit +4.67 m on Riachuelo zero); OSM way 445253049 (bearing " +
				"356.2, 92 m with approaches) and Riachuelo banks 68 m apart along the axis, centre moved 7 m " +
				"N; clear 4.3 estimated (6.07 m over zero minus mean water 1.9-2.9 m)"},
		{"id": "br_buenos_aires_puente_nicolas_avellaneda", "cc": "AR", "name": "Puente Nicolás Avellaneda", "wiki": "Puente Nicolás Avellaneda",
			"aliases": ["puente nicolas avellaneda", "avellaneda lift bridge"], "lat": -34.63802, "lon": -58.35571,
			"bearing": 134.5, "st": "lift", "spans": [60.0], "width": 17.0, "clear": 22.0, "tower": 54.0,
			"material": "steel", "base": "water", "tier": 2, "conf": 1, "moving": 0,
			"src": "en+es Wikipedia (1940 vertical-lift bridge, 60 m lift span, clearance 21 m down / 43 m " +
				"raised, 1650 m with viaducts); lift span with towers cannot be represented, width, bearing, " +
				"tower height ESTIMATED; coords from wiki | verified: en Wikipedia (60 m lift section, 57 m " +
				"tall, clearance 21 m down / 43 m up; Grace's Guide says 65 m), es Wikipedia (navigation " +
				"width 60 m, roadway 12 m + 2.5 m footways, clearance 21 m over mean water = 23.9 m over " +
				"Riachuelo zero), city tourism page (towers nearly 50 m); OSM way 28739006 (bearing 135 on " +
				"the river section, 681 m with approaches; the first pass bearing 160 was wrong); Riachuelo " +
				"is 118 m bank to bank on the axis so fixed side spans of about 29 m flank the 60 m lift span " +
				"but are not sourced | round 2: round 2: no new source for the flanking fixed spans; lift " +
				"type with unsourced side spans stays at 1"},
		{"id": "br_buenos_aires_puente_transbordador", "cc": "AR", "name": "Puente Transbordador Nicolás Avellaneda", "aliases": ["puente transbordador", "buenos aires transporter bridge"],
			"lat": -34.63847, "lon": -58.35625, "bearing": 134.5, "st": "lift", "spans": [77.5], "width": 8.0,
			"clear": 3.0, "tower": 52.0, "material": "steel", "base": "water", "tier": 2, "conf": 1, "moving": 0,
			"src": "es Wikipedia (1914 transporter bridge, 77.5 m upper girders, 43.52 m clearance, restored " +
				"2017-20); hanging gondola cannot be represented; width, rise, bearing ESTIMATED; coords from " +
				"wiki | verified: es Wikipedia + CIC restoration paper (digital.cic.gba.gob.ar, " +
				"Magallanes/Fornas/Marchese): 77.5 m free span, height 52 m, gondola 8x12 m, upper girder " +
				"clearance 43.52 m; Structurae lists 103.6 m main span (overall); bearing parallel to the " +
				"adjacent 1940 bridge (OSM 135); gondola hangs at water level so a lift deck would be a " +
				"fictitious floor | round 2: round 2: transporter bridge cannot be represented with a lift " +
				"deck; unchanged"},
		{"id": "br_brasilia_juscelino_kubitschek_bridge", "cc": "BR", "name": "Juscelino Kubitschek Bridge", "wiki": "Juscelino Kubitschek bridge",
			"aliases": ["ponte jk", "ponte juscelino kubitschek", "jk bridge"], "lat": -15.82405, "lon": -47.82992,
			"bearing": 151.3, "st": "arch_through", "spans": [240.0, 240.0, 240.0], "width": 24.0, "clear": 18.0,
			"rise": 43.0, "material": "steel", "base": "water", "tier": 1, "conf": 1,
			"src": "en+pt Wikipedia (3 steel arches of 240 m, 1200 m with approaches, 24 m deck, arch top ~61 " +
				"m); the three arches cross the deck diagonally so a through arch is only the nearest form; " +
				"bearing, clear ESTIMATED; coords from wiki | verified: pt+en Wikipedia (3 asymmetric arches " +
				"of 240 m on four submerged supports, 24 m deck + 2x1.5 m footways, 1.2 km with approaches, " +
				"top 62 m); OSM trunk ways 44076466/44076498 (twin one-way carriageways, 1.19 km, bearing " +
				"151.3 SE / 331.2 NW, mid -15.82405,-47.82992): the first pass bearing 100 was wrong by about " +
				"50 degrees and the centre 70 m off; the three arches lean in different planes and cross the " +
				"deck diagonally, so no existing type draws them faithfully | round 2: round 2: pt Wikipedia " +
				"already read in round 1; no existing type draws the three diagonal-crossing arches; " +
				"unchanged"},
		{"id": "br_paramaribo_jules_wijdenbosch_bridge", "cc": "SR", "name": "Jules Wijdenbosch Bridge", "wiki": "Jules Wijdenbosch Bridge",
			"aliases": ["jules wijdenboschbrug", "wijdenbosch brug", "surinamebrug"], "lat": 5.8062, "lon": -55.16381,
			"bearing": 83.9, "st": "stayed", "spans": [77.5, 155.0, 77.5], "width": 12.0, "clear": 20.0, "tower": 52.0,
			"material": "concrete", "base": "water", "tier": 2, "conf": 1,
			"src": "en Wikipedia (1504 m total incl. approaches, longest span 155 m, 2 lanes, 2000); structure " +
				"type, side spans, width, towers, clear ESTIMATED; coords from wiki; bearing estimated | " +
				"verified: en+nl Wikipedia (concrete road bridge, 1504 m, longest span 155 m, 2 lanes, height " +
				"52 m, opened 2000); OSM way 4383404 (1490 m, bearing 263.9 E->W = 83.9 W->E, mid " +
				"5.8062,-55.16381); no source states the structure type (first pass 'stayed' is a guess, a " +
				"concrete box-girder 'haunched' form is more likely given the Ballast Nedam concrete design " +
				"and no cable-stay mention anywhere), side spans and width unsourced | round 2: round 2: nl " +
				"Wikipedia raw (1504 m, height 52 m, 2 lanes, no span or type data) and web search (only " +
				"mirrors of the same text, Structurae/troon.org not retrievable); structure type and span " +
				"layout still unsourced"},
		{"id": "br_georgetown_demerara_harbour_bridge", "cc": "GY", "name": "Demerara Harbour Bridge", "wiki": "Demerara Harbour Bridge",
			"aliases": ["demerara river bridge", "old demerara bridge"], "lat": 6.77192, "lon": -58.18744,
			"bearing": 275.0, "st": "pontoon",
			"spans": [30.34, 30.34, 30.34, 30.34, 30.34, 30.34, 30.34, 30.34, 30.34, 30.34, 30.34, 30.34, 30.34, 30.34, 30.34, 30.34, 30.34, 30.34, 30.34, 30.34, 30.34, 30.34, 30.34, 30.34, 30.34, 30.34, 30.34, 30.34, 30.34, 30.34, 30.34, 30.34, 30.34, 30.34, 30.34, 30.34, 30.34, 30.34, 30.34, 30.34, 30.34, 30.34, 30.34, 30.34, 30.34, 30.34, 30.34, 30.34, 30.34, 30.34, 30.34, 30.34, 30.34, 30.34, 30.34, 30.34, 30.34, 30.34, 30.34, 30.34, 30.34],
			"width": 9.0, "clear": 5.0, "material": "steel", "base": "water", "tier": 2, "conf": 1,
			"src": "en Wikipedia (floating pontoon bridge, 1978, 1851 m, high-level span 7.9 m clearance, closed " +
				"5 Oct 2025, replaced by the new bridge, old one left in place); pontoon cannot be " +
				"represented, width and bearing ESTIMATED | verified: en Wikipedia: floating pontoon bridge, " +
				"61 spans, 1851 m (6074 ft), high-level span 32 m wide / 7.9 m clear, retractor spans open " +
				"77.4 m; closed 5 Oct 2025 and replaced by the New Demerara River Bridge (~2.8 km, cable- " +
				"stayed centre ~570 m, ~2 km north, opened 5 Oct 2025, spans/pylon figures in the press " +
				"conflict) which has no usable span source; pontoon units assumed equal (1851/61), width and " +
				"bearing (275) still unmeasured | round 2: round 2: not re-examined; pontoon unit spacing and " +
				"width unmeasured"},
		{"id": "br_asuncion_puente_heroes_del_chaco", "cc": "PY", "name": "Puente Héroes del Chaco", "aliases": ["puente heroes del chaco", "puente bicentenario", "puente asuncion chaco'i"],
			"lat": -25.2428, "lon": -57.5917, "bearing": 316.4, "st": "stayed", "spans": [95.0, 260.0, 95.0],
			"width": 30.0, "clear": 30.0, "tower": 108.0, "material": "concrete", "base": "water", "tier": 2, "conf": 1,
			"src": "es Wikipedia (2024, cable-stayed section 600 m, 35 m wide), abc.com.py/lanacion.com.py via " +
				"search (300 m main span, 150 m side spans, 130 m pylons, 92 stays central plane); clear and " +
				"bearing ESTIMATED; coords from wiki, not checked against OSM | verified: Global Highways 'We " +
				"can be Heroes' (via search snippet): 450 m cable-stayed section = 260 m main + 2x95 m sides, " +
				"two diamond-shaped towers (Chaco'i tower 108 m), deck 28.44 m; en/es Wikipedia say 600 m " +
				"cable-stayed section, 300 m main span, 35 m wide; infrapppworld 603 m x 32 m; OSM ways " +
				"823191050/51 (2.4 km trunk incl. viaduct, bearing 316.4 / 136.8, wikidata Q97486298) pass " +
				"through the wiki coordinate, so centre kept and bearing corrected from 295 | round 2: round " +
				"2: web search confirms Global Highways/feasibility-study figures (450 m cable-stayed " +
				"section, 260 m main span, 94.5-95 m side spans, 2 towers) against en/es Wikipedia (600 m, " +
				"300 m main span); deck width still conflicts (28.44 / 30 / 32 / 35 m) and Global Highways " +
				"page returned 403; spans agree across two sources but width does not, so left at 1"},
		{"id": "br_lima_puente_de_piedra", "cc": "PE", "name": "Puente de Piedra", "wiki": "Puente de Piedra",
			"aliases": ["stone bridge lima", "puente de piedra lima"], "lat": -12.04327, "lon": -77.02971,
			"bearing": 9.8, "st": "masonry", "spans": [18.7, 18.7, 18.7, 18.7, 18.7, 18.7], "width": 11.0, "clear": 8.0,
			"rise": 5.0, "material": "stone", "base": "water", "tier": 1, "conf": 1,
			"src": "en+es Wikipedia (1610, 112 m, widened 1902, lowered 2010), OSM snapshot centre/bearing (113 " +
				"m); arch count (6), equal spans, width, rise and clear ESTIMATED | verified: OSM way " +
				"304547414 (114 m, bearing 189.7 N->S = 9.7 S->N, mid -12.04327,-77.02971) confirms " +
				"centre/bearing; es Wikipedia infobox 112 m long, 6 m clearance, calls it a beam bridge; a " +
				"bridge list gives 115 m with 4 semicircular arches (6 originally), so the arch count (4 vs " +
				"6) and spans are unresolved | round 2: round 2: es Wikipedia infobox re-read (112 m, 6 m " +
				"clearance); arch count and spans unresolved"},
		{"id": "br_lima_puente_balta", "cc": "PE", "name": "Puente Balta", "wiki": "Balta Bridge",
			"aliases": ["balta bridge", "puente de hierro lima"], "lat": -12.0436, "lon": -77.02313, "bearing": 0.8,
			"st": "arch_deck", "spans": [29.2, 29.2, 29.2, 29.2, 29.2], "width": 12.0, "clear": 9.0, "rise": 3.5,
			"material": "iron", "base": "water", "tier": 2, "conf": 1,
			"src": "en+es Wikipedia (5 arches, 3 central cast-iron on stone piers, 1869-1919, one bank arch " +
				"removed 1971, remodelled 2005), OSM snapshot centre/bearing (146 m); span split, width, rise " +
				"and clear ESTIMATED | verified: es+en Wikipedia: three cast-iron arches on stone piers " +
				"(1869-1919), first right-bank arch removed 1971; no span lengths found in any source and the " +
				"current arch count is unclear; centre/bearing not re-measured (OSM API rate-limited), left " +
				"from the snapshot | round 2: round 2: es Wikipedia re-read: five arches of which the three " +
				"central are cast iron on stone piers, first right-bank arch removed 1971; no span lengths " +
				"found"},
		{"id": "br_lima_puente_del_ejercito", "cc": "PE", "name": "Puente del Ejército", "aliases": ["puente del ejercito", "puente ejercito lima"],
			"lat": -12.0388, "lon": -77.0434, "bearing": 35.0, "st": "arch_tied", "spans": [105.05], "width": 20.0,
			"clear": 8.0, "rise": 14.0, "material": "steel", "base": "water", "tier": 3, "conf": 1,
			"src": "es Wikipedia (1936 tied-arch bridge, 2010 twin tied-arch bridges 105.05 m long, 9.1 m wide " +
				"each); rise, clear, bearing (parallel to Puente Santa Rosa in snapshot) ESTIMATED; coords " +
				"from wiki | verified: es Wikipedia: the 1936 60 m tied-arch bridge was replaced in the 1960s " +
				"by an arch-less deck, and in 2010 two independent parallel tied-arch bridges (105.05 m long, " +
				"9.10 m wide each) were built either side of it, so the crossing is three parallel decks (one " +
				"without arches); a single 20 m wide tied arch is not what stands | round 2: round 2: not re- " +
				"examined; three parallel decks remain"},
		{"id": "br_santiago_puente_pio_nono", "cc": "CL", "name": "Puente Pío Nono", "aliases": ["puente pio nono"],
			"lat": -33.436, "lon": -70.63533, "bearing": 5.0, "st": "girder", "spans": [45.0], "width": 18.0,
			"clear": 5.0, "material": "concrete", "base": "water", "tier": 3, "conf": 1,
			"src": "es Wikipedia (1983, replaced 1892 iron bridge, 4 lanes) and annex of Mapocho bridges (~45 " +
				"m); width, clear, bearing ESTIMATED; coords from wiki | verified: es Wikipedia annex of " +
				"Mapocho bridges (~45 m, four one-way lanes, coord -33.435997,-70.635331) and article (1983 " +
				"concrete bridge, old 1892 iron bridge moved 100 m west as Puente Vicente Huidobro); no span " +
				"layout, width or deck height in any source | round 2: round 2: no new source for " +
				"span/width/height"},
		{"id": "br_santiago_puente_purisima", "cc": "CL", "name": "Puente Purísima", "aliases": ["puente purisima"],
			"lat": -33.43517, "lon": -70.63887, "bearing": 5.0, "st": "truss", "spans": [40.0], "width": 25.0,
			"clear": 5.0, "rise": 6.0, "material": "iron", "base": "water", "tier": 3, "conf": 1,
			"src": "es Wikipedia annex of Mapocho bridges (~40 m, 4 lanes); width, clear, bearing ESTIMATED; " +
				"coords from annex | verified: es Wikipedia 'Puente Purísima': two side-by-side 1889-90 Lever " +
				"Murphy iron Whipple through-truss road bridges (Loreto bridge moved next to it in 1980), " +
				"national monument, ~1006 m2 total deck area, annex ~40 m long four lanes; the first pass " +
				"'concrete girder' was wrong; width 25 m = area/length estimate, truss height 6 m estimated | " +
				"round 2: round 2: no new source for width/height"},
	]
