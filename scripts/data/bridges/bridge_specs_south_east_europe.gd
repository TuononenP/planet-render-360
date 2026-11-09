class_name BridgeSpecsSouthEastEurope
extends RefCounted

## Capital bridge rows for South-eastern Europe (see BridgeSpec for the schema). Figures are
## sourced per row in `src`; conf 1 rows are kept as data but not built
## (BridgeSpec.MIN_BUILT_CONF).

static func rows() -> Array:
	return [
		{"id": "br_rome_ponte_sant_angelo", "cc": "IT", "name": "Ponte Sant'Angelo", "wiki": "Ponte Sant'Angelo",
			"aliases": ["pons aelius", "aelian bridge", "bridge of angels", "ponte castel sant'angelo"], "lat": 41.9019,
			"lon": 12.46646, "bearing": 356.3, "st": "masonry", "spans": [25.4, 25.4, 25.4, 25.4, 25.4], "width": 9.0,
			"clear": 9.0, "rise": 6.0, "material": "stone", "base": "water", "tier": 1, "conf": 2,
			"src": "en+it Wikipedia (135 m, 5 arches, 3 Roman, outer two 1893), OSM snapshot way (125 m, axis " +
				"176.3 reversed to travel north to castle), Wikidata coord 41.9018,12.46645; individual " +
				"spans, width, clear and rise estimated | verified: OSM way re-measured via " +
				"api.openstreetmap.org/api/0.6/map: bridge way 25752465 mid 41.90189,12.46646 axis 176.3 (row " +
				"bearing is the reverse, 356.3, toward the castle), 126 m. Platner 1929 via " +
				"ancientromelive.org: 3 Roman arches of 18.39 m clear, Roman width 10.95 m; en Wikipedia: end " +
				"arches rebuilt similar to Roman ones, 135 m; laboratorioroma.it Ponti sul Tevere PDF: 135 m " +
				"x 9 m, 3 Roman arches + 2 symmetric ones (1882-93). Five equal arches => pier-centre span = " +
				"18.4 clear + ~7 m pier = 25.4 (pier thickness estimated); clear/rise estimated."},
		{"id": "br_rome_ponte_vittorio_emanuele_ii", "cc": "IT", "name": "Ponte Vittorio Emanuele II", "wiki": "Ponte Vittorio Emanuele II",
			"aliases": ["ponte vittorio emanuele secondo", "ponte vittorio"], "lat": 41.90115, "lon": 12.46435,
			"bearing": 135.1, "st": "masonry", "spans": [34.0, 40.0, 34.0], "width": 20.0, "clear": 11.0, "rise": 5.0,
			"material": "stone", "base": "water", "tier": 2, "conf": 1,
			"src": "en+it Wikipedia (3 arches, 108-110 m, 20 m wide), OSM snapshot bearing, Wikidata coord " +
				"41.90111,12.46444; individual spans split by estimate, clear and rise estimated | verified: " +
				"OSM way re-measured via api.openstreetmap.org/api/0.6/map: way 25752479 mid " +
				"41.90115,12.46435 brg 315.3 (row 135.1 is the reverse), 111 m. it/en Wikipedia and " +
				"laboratorioroma PDF: 3 arches, 108-110 m; no span split or width published; split 34/40/34 " +
				"and width 20 are guesses. | round 2: round2: searched for the arch span split and found " +
				"none: it/de/en Wikipedia raw wikitext (infobox luce/hluce empty, text gives only arch count, " +
				"total length and width), laboratorioroma 'I ponti sul Tevere' PDF, turismoroma.it snippets, " +
				"Sovrintendenza Capitolina snippets, Structurae (403 to fetch). No source publishes the " +
				"individual spans, so the split stays an estimate."},
		{"id": "br_rome_ponte_principe_amedeo_savoia_aosta", "cc": "IT", "name": "Ponte Principe Amedeo Savoia Aosta", "wiki": "Ponte Principe Amedeo Savoia Aosta",
			"aliases": ["ponte amedeo savoia aosta", "ponte principe amedeo"], "lat": 41.89975, "lon": 12.46346,
			"bearing": 86.8, "st": "masonry", "spans": [32.0, 48.0, 32.0], "width": 20.0, "clear": 11.0, "rise": 5.0,
			"material": "stone", "base": "water", "tier": 3, "conf": 1,
			"src": "it Wikipedia (3 marble-faced masonry arches, 2 ship-shaped piers), OSM snapshot way (112 m, " +
				"bearing 86.8, 3 lanes), Wikidata coord 41.8997,12.4633; span split, width, clear, rise " +
				"guessed | verified: OSM way re-measured via api.openstreetmap.org/api/0.6/map: way 25752503 " +
				"mid 41.89975,12.46346 brg 86.7, 112 m (3 lanes). it Wikipedia infobox: 109.7 m x 20 m, 3 " +
				"marble-faced arches, 2 ship-shaped piers; en Wikipedia: 109.7 x 20; laboratorioroma: 109 x " +
				"20. Span split 32/48/32 remains a guess. | round 2: round2: searched for the arch span split " +
				"and found none: it/de/en Wikipedia raw wikitext (infobox luce/hluce empty, text gives only " +
				"arch count, total length and width), laboratorioroma 'I ponti sul Tevere' PDF, " +
				"turismoroma.it snippets, Sovrintendenza Capitolina snippets, Structurae (403 to fetch). No " +
				"source publishes the individual spans, so the split stays an estimate."},
		{"id": "br_rome_ponte_palatino", "cc": "IT", "name": "Ponte Palatino", "wiki": "Ponte Palatino",
			"aliases": ["palatine bridge rome"], "lat": 41.88909, "lon": 12.47921, "bearing": 94.8, "st": "girder",
			"spans": [31.0, 31.0, 31.0, 31.0, 31.0], "width": 18.4, "clear": 11.0, "material": "steel", "base": "water",
			"tier": 2, "conf": 1,
			"src": "en+it Wikipedia (5 spans, 4 masonry piers with metal deck, 155 m), OSM snapshot bearing " +
				"94.8; equal spans, width and clear estimated | verified: OSM way re-measured via " +
				"api.openstreetmap.org/api/0.6/map: way 24695045 mid 41.88914,12.47920 brg 95.6, 163 m. de/it " +
				"Wikipedia infobox: 155-155.5 m long, 18.4 m wide, five openings; de: wrought-iron lattice " +
				"girders on 4 masonry piers set at different angles to the deck axis (so spans are probably " +
				"not equal). Equal 31 m spans are an assumption. | round 2: round2: searched for the arch " +
				"span split and found none: it/de/en Wikipedia raw wikitext (infobox luce/hluce empty, text " +
				"gives only arch count, total length and width), laboratorioroma 'I ponti sul Tevere' PDF, " +
				"turismoroma.it snippets, Sovrintendenza Capitolina snippets, Structurae (403 to fetch). No " +
				"source publishes the individual spans, so the split stays an estimate. de Wikipedia adds: " +
				"five parallel wrought-iron lattice girders per span on 4 masonry piers set at different " +
				"angles to the deck axis, so equal 31 m spans remain an assumption."},
		{"id": "br_rome_ponte_fabricio", "cc": "IT", "name": "Ponte Fabricio", "wiki": "Pons Fabricius",
			"aliases": ["pons fabricius", "ponte dei quattro capi", "fabrician bridge"], "lat": 41.89108,
			"lon": 12.47825, "bearing": 40.8, "st": "masonry", "spans": [31.0, 31.0], "width": 5.8, "clear": 11.0,
			"rise": 8.0, "material": "stone", "base": "water", "tier": 2, "conf": 2,
			"src": "it Wikipedia (2 arches of 24.5 m, 61.8 m long, 6 m wide, 62 BC), OSM snapshot bearing; clear " +
				"and rise estimated, pier 6.5 m assumed | verified: OSM way re-measured via " +
				"api.openstreetmap.org/api/0.6/map: way 4951306 mid 41.89108,12.47824 brg 41.2, 65 m incl. " +
				"ramps. en Wikipedia: 2 arches spanning 80 ft (24.5 m), 62 m x 5.5 m; fr Wikipedia: arches " +
				"24.50 m clear, 62 m, 5.50 m; it Wikipedia: 61.8 m x 6 m, two flattened arches of 24.5 m on a " +
				"median pier with a 6 m flood opening; laboratorioroma: 57 m x 6. Pier-centre span 31 = 24.5 " +
				"+ ~6.5 pier (62 m total). Clear and rise estimated."},
		{"id": "br_rome_ponte_cestio", "cc": "IT", "name": "Ponte Cestio", "wiki": "Pons Cestius",
			"aliases": ["pons cestius", "cestius bridge"], "lat": 41.89004, "lon": 12.47732, "bearing": 17.3,
			"st": "masonry", "spans": [26.1, 28.2, 26.1], "width": 8.2, "clear": 10.0, "rise": 4.0, "material": "stone",
			"base": "water", "tier": 3, "conf": 2,
			"src": "it Wikipedia (rebuilt 1889 as 3 arches, 80.4 m), OSM snapshot bearing; spans, width, clear " +
				"and rise guessed | verified: OSM way re-measured via api.openstreetmap.org/api/0.6/map: way " +
				"381223151 mid 41.89004,12.47732 brg 17.2, 79 m. fr Wikipedia: central arch 23.65 m clear " +
				"(original), two new side arches of 21.40 m; en Wikipedia: 80.4 m, 3 arches (central " +
				"original, side arches of equal span); it Wikipedia: three arches of equal span, 80.4 m; " +
				"width 8.2 m is the Roman width (fr/en), laboratorioroma.it gives 8 m (rebuilt width not " +
				"independently stated: moderate doubt). Pier-centre = clear + ~4 m pier, scaled to 80.4 m " +
				"total."},
		{"id": "br_rome_ponte_milvio", "cc": "IT", "name": "Ponte Milvio", "wiki": "Ponte Milvio",
			"aliases": ["milvian bridge", "mulvian bridge", "ponte molle", "pons milvius"], "lat": 41.93551,
			"lon": 12.46696, "bearing": 341.7, "st": "masonry", "spans": [22.7, 22.7, 22.7, 22.7, 22.7, 22.7],
			"width": 7.9, "clear": 9.0, "rise": 5.0, "material": "stone", "base": "water", "tier": 2, "conf": 1,
			"src": "en Wikipedia (6 spans, main span 18.55 m, 136 m, 8.75 m wide), OSM way via " +
				"api.openstreetmap.org (axis 161.7, centre; OSM length 169 m includes ramps); equal spans = " +
				"136/6 assumed, clear and rise estimated | verified: OSM way re-measured via " +
				"api.openstreetmap.org/api/0.6/map: way 113077526 mid 41.93551,12.46696 brg 341.7, 170 m " +
				"incl. ramps (bridge proper 136 m; centre may be offset a few m). en/fr/it Wikipedia: 6 " +
				"arches, 136 m, longest span 18.55 m; width 8.75 (en) vs 7 (it); Roman central three arches + " +
				"Valadier end arches (1805) not stated equal. | round 2: round2: searched for the arch span " +
				"split and found none: it/de/en Wikipedia raw wikitext (infobox luce/hluce empty, text gives " +
				"only arch count, total length and width), laboratorioroma 'I ponti sul Tevere' PDF, " +
				"turismoroma.it snippets, Sovrintendenza Capitolina snippets, Structurae (403 to fetch). No " +
				"source publishes the individual spans, so the split stays an estimate. laboratorioroma/it: " +
				"only the three central arches are Roman, Valadier rebuilt the end arches in 1805 (no equal- " +
				"span statement)."},
		{"id": "br_rome_ponte_sisto", "cc": "IT", "name": "Ponte Sisto", "wiki": "Ponte Sisto",
			"aliases": ["sistine bridge", "pons aurelius"], "lat": 41.89235, "lon": 12.47077, "bearing": 47.9,
			"st": "masonry", "spans": [21.0, 33.0, 33.0, 21.0], "width": 11.0, "clear": 10.0, "rise": 6.0,
			"material": "stone", "base": "water", "tier": 2, "conf": 1,
			"src": "it Wikipedia (108 m, 11 m), en Wikipedia (oculus above pier, 1473-79), OSM way (axis 47.9, " +
				"centre; 102 m); arch count 4 and individual spans estimated, clear and rise estimated | " +
				"verified: OSM way re-measured via api.openstreetmap.org/api/0.6/map: way 24609539 mid " +
				"41.89235,12.47077 brg 47.7, 102 m. it Wikipedia infobox 108 m x 11 m 4 arches; de 105 m x 20 " +
				"m; laboratorioroma 108 x 11; turismoroma: four travertine-faced arches with central oculus. " +
				"Spans 21/33/33/21 are a guess. | round 2: round2: searched for the arch span split and found " +
				"none: it/de/en Wikipedia raw wikitext (infobox luce/hluce empty, text gives only arch count, " +
				"total length and width), laboratorioroma 'I ponti sul Tevere' PDF, turismoroma.it snippets, " +
				"Sovrintendenza Capitolina snippets, Structurae (403 to fetch). No source publishes the " +
				"individual spans, so the split stays an estimate."},
		{"id": "br_rome_ponte_garibaldi", "cc": "IT", "name": "Ponte Garibaldi", "wiki": "Ponte Garibaldi",
			"aliases": ["ponte giuseppe garibaldi"], "lat": 41.89107, "lon": 12.47451, "bearing": 2.5,
			"st": "arch_deck", "spans": [60.2, 60.2], "width": 23.0, "clear": 11.0, "rise": 5.0, "material": "concrete",
			"base": "water", "tier": 3, "conf": 2,
			"src": "en Wikipedia (120 m, 1884-88, A. Vescovali), OSM way (axis 2.5, centre; 123 m); spans, " +
				"width, clear, rise guessed | verified: OSM way re-measured via " +
				"api.openstreetmap.org/api/0.6/map: way 25752804 mid 41.89108,12.47444 brg 184.0 (row 2.5 is " +
				"the reverse), 123 m. it Wikipedia infobox 120.4 m x 23 m, central pier; laboratorioroma PDF: " +
				"121 x 23 m, after 1953-56 the two original metal spans were rebuilt in reinforced concrete, " +
				"now two lowered arches; de Wikipedia: central pier + two smaller travertine-faced piers, 120 " +
				"m; en: 120 m. Equal 60.2 m spans from the single central pier; clear and rise (5) estimated."},
		{"id": "br_rome_ponte_sublicio", "cc": "IT", "name": "Ponte Sublicio", "wiki": "Ponte Sublicio",
			"aliases": ["sublician bridge", "pons sublicius"], "lat": 41.88324, "lon": 12.4752, "bearing": 136.2,
			"st": "masonry", "spans": [31.0, 43.0, 31.0], "width": 20.0, "clear": 11.0, "rise": 5.0,
			"material": "stone", "base": "water", "tier": 3, "conf": 1,
			"src": "it Wikipedia (3 arches, 105 m long, 20 m wide, 1918), OSM way (axis 136.2, centre; 116 m); " +
				"span split, clear, rise estimated | verified: OSM way re-measured via " +
				"api.openstreetmap.org/api/0.6/map: way 24694986 mid 41.88328,12.47515 brg 136.4, 104 m. en " +
				"Wikipedia 105.55 m x 20 m; laboratorioroma/it 3 masonry arches 105 x 20 (Piacentini " +
				"1914-17). Split 31/43/31 unverified. | round 2: round2: searched for the arch span split and " +
				"found none: it/de/en Wikipedia raw wikitext (infobox luce/hluce empty, text gives only arch " +
				"count, total length and width), laboratorioroma 'I ponti sul Tevere' PDF, turismoroma.it " +
				"snippets, Sovrintendenza Capitolina snippets, Structurae (403 to fetch). No source publishes " +
				"the individual spans, so the split stays an estimate."},
		{"id": "br_rome_ponte_cavour", "cc": "IT", "name": "Ponte Cavour", "wiki": "Ponte Cavour",
			"aliases": ["cavour bridge rome"], "lat": 41.90498, "lon": 12.47429, "bearing": 95.4, "st": "masonry",
			"spans": [22.0, 22.0, 22.0, 22.0, 22.0], "width": 20.5, "clear": 11.0, "rise": 4.5, "material": "stone",
			"base": "water", "tier": 3, "conf": 1,
			"src": "it Wikipedia (5 travertine-faced arches, 110 m, 20 m wide), OSM way (axis 95.4, centre; 106 " +
				"m); equal spans assumed, clear and rise estimated | verified: OSM way re-measured via " +
				"api.openstreetmap.org/api/0.6/map: way 25752430 mid 41.90498,12.47429 brg 95.4, 106 m. en " +
				"Wikipedia 110.1 m x 20.5 m; laboratorioroma 112 x 20, five travertine-faced masonry arches. " +
				"Equality of the five spans not stated by any source. | round 2: round2: searched for the " +
				"arch span split and found none: it/de/en Wikipedia raw wikitext (infobox luce/hluce empty, " +
				"text gives only arch count, total length and width), laboratorioroma 'I ponti sul Tevere' " +
				"PDF, turismoroma.it snippets, Sovrintendenza Capitolina snippets, Structurae (403 to fetch). " +
				"No source publishes the individual spans, so the split stays an estimate. turismoroma.it: " +
				"five semicircular (a tutto sesto) travertine-faced arches, 112 x 20 m; equality not stated."},
		{"id": "br_rome_ponte_umberto_i", "cc": "IT", "name": "Ponte Umberto I", "wiki": "Ponte Umberto I",
			"aliases": ["ponte umberto primo", "umberto bridge rome"], "lat": 41.90266, "lon": 12.47134,
			"bearing": 156.5, "st": "masonry", "spans": [28.0, 50.0, 28.0], "width": 20.0, "clear": 11.0, "rise": 5.0,
			"material": "stone", "base": "water", "tier": 3, "conf": 1,
			"src": "it Wikipedia (3 arches, 106 m, 1885-95), OSM way (axis 156.5, centre; 104 m); width, spans, " +
				"clear, rise guessed | verified: OSM way re-measured via api.openstreetmap.org/api/0.6/map: " +
				"way 25752439 mid 41.90267,12.47138 brg 156.5, 105 m. it Wikipedia infobox 105.65 m x 20 m, 3 " +
				"arches; en 105 m; laboratorioroma 106 x 20, 3 arches. Span split guessed. | round 2: round2: " +
				"searched for the arch span split and found none: it/de/en Wikipedia raw wikitext (infobox " +
				"luce/hluce empty, text gives only arch count, total length and width), laboratorioroma 'I " +
				"ponti sul Tevere' PDF, turismoroma.it snippets, Sovrintendenza Capitolina snippets, " +
				"Structurae (403 to fetch). No source publishes the individual spans, so the split stays an " +
				"estimate."},
		{"id": "br_rome_ponte_testaccio", "cc": "IT", "name": "Ponte Testaccio", "wiki": "Ponte Testaccio",
			"aliases": ["testaccio bridge"], "lat": 41.87541, "lon": 12.47049, "bearing": 62.6, "st": "arch_deck",
			"spans": [96.0], "width": 31.3, "clear": 12.0, "rise": 9.0, "material": "concrete", "base": "water",
			"tier": 3, "conf": 2,
			"src": "it Wikipedia (single arch, 122 m overall, 1938-48), OSM way (axis 62.6, centre; 98 m, 6 " +
				"lanes); span, width, clear, rise estimated | verified: OSM way re-measured via " +
				"api.openstreetmap.org/api/0.6/map: way 23339492 mid 41.87541,12.47049 brg 62.4, 99 m, 6 " +
				"lanes. de Wikipedia infobox: single arch, Spannweite 96 m, 122 m long, 32 m wide; en/it " +
				"Wikipedia: 122 m x 31.3 m; laboratorioroma: one reinforced-concrete arch, 122 x 31. Clear " +
				"and rise (9 m) estimated."},
		{"id": "br_rome_ponte_dell_industria", "cc": "IT", "name": "Ponte dell'Industria", "wiki": "Ponte dell'Industria",
			"aliases": ["ponte di ferro", "iron bridge rome", "ponte dell industria"], "lat": 41.87191, "lon": 12.47195,
			"bearing": 74.1, "st": "girder", "spans": [36.0, 59.0, 36.0], "width": 7.4, "clear": 10.0,
			"material": "steel", "base": "water", "tier": 3, "conf": 1,
			"src": "it Wikipedia (3 metal girder spans, about 131 m), OSM way (axis 74.1, centre; 123 m); span " +
				"split, width, clear estimated | verified: OSM way re-measured via " +
				"api.openstreetmap.org/api/0.6/map: way 989002276 mid 41.87191,12.47195 brg 74.0, 123 m. en " +
				"Wikipedia 131.2 m x 7.25 m; laboratorioroma 131 x 7.5: iron and cast-iron arches/girders on " +
				"cast-iron tube piers filled with concrete; span split unknown. | round 2: round2: searched " +
				"for the arch span split and found none: it/de/en Wikipedia raw wikitext (infobox luce/hluce " +
				"empty, text gives only arch count, total length and width), laboratorioroma 'I ponti sul " +
				"Tevere' PDF, turismoroma.it snippets, Sovrintendenza Capitolina snippets, Structurae (403 to " +
				"fetch). No source publishes the individual spans, so the split stays an estimate. it/en " +
				"Wikipedia: three metal girder openings (type confirmed), 131.2 x 7.25 m; the bridge was " +
				"restored and widened 2023-25 (en Wikipedia), so the current width may differ; span split " +
				"unpublished."},
		{"id": "br_rome_ponte_duca_d_aosta", "cc": "IT", "name": "Ponte Duca d'Aosta", "wiki": "Ponte Duca d'Aosta",
			"aliases": ["duca d'aosta bridge"], "lat": 41.93115, "lon": 12.46085, "bearing": 117.4, "st": "arch_deck",
			"spans": [30.0, 104.0, 30.0], "width": 30.0, "clear": 14.0, "rise": 10.0, "material": "concrete",
			"base": "water", "tier": 3, "conf": 2,
			"src": "it Wikipedia (concrete clad in travertine, 222.3 m long, 30 m wide, 3 shallow arches, " +
				"central 100 m intrados), OSM way (axis 117.4, 221 m); wiki figure for side spans (25 m) " +
				"inconsistent with total, side spans derived from total; clear, rise estimated | verified: " +
				"OSM way re-measured via api.openstreetmap.org/api/0.6/map: way 26445338 mid " +
				"41.93115,12.46085 brg 117.5, 222 m. it Wikipedia: three flattened arches, centre arch 100 m " +
				"intrados line, the other two 25 m (flood vents resting on the banks); laboratorioroma: " +
				"single 100 m reinforced-concrete arch, 222 x 30; en Wikipedia 220 m x 30 m. Modelled as " +
				"pier-centre 30/104/30 (clear + ~4-5 m piers); the extra ~58 m of approach masonry at each " +
				"end is excluded. Clear and rise estimated."},
		{"id": "br_rome_ponte_flaminio", "cc": "IT", "name": "Ponte Flaminio", "wiki": "Ponte Flaminio",
			"aliases": ["flaminio bridge rome"], "lat": 41.93626, "lon": 12.47172, "bearing": 172.4, "st": "arch_deck",
			"spans": [51.0, 51.0, 51.0, 51.0, 51.0], "width": 27.0, "clear": 13.0, "rise": 7.0, "material": "concrete",
			"base": "water", "tier": 3, "conf": 1,
			"src": "it Wikipedia (5 arches, 254.94 m, 27 m wide, concrete clad in travertine), OSM way (axis " +
				"172.4, centre; 262 m); equal spans assumed, clear and rise estimated | verified: OSM way re- " +
				"measured via api.openstreetmap.org/api/0.6/map: way 22801763 mid 41.93626,12.47167 brg " +
				"172.5, 264 m. it Wikipedia 254.94 m x 27 m, 5 arches; laboratorioroma PDF 292 m x 40 m with " +
				"a 52 m lowered central arch. Remaining span lengths unpublished. | round 2: round2: searched " +
				"for the arch span split and found none: it/de/en Wikipedia raw wikitext (infobox luce/hluce " +
				"empty, text gives only arch count, total length and width), laboratorioroma 'I ponti sul " +
				"Tevere' PDF, turismoroma.it snippets, Sovrintendenza Capitolina snippets, Structurae (403 to " +
				"fetch). No source publishes the individual spans, so the split stays an estimate. " +
				"laboratorioroma gives 292 x 40 m with a 52 m lowered central arch vs it Wikipedia 254.94 x " +
				"27 m, five arches; the two sources disagree on length and width, other four spans " +
				"unpublished."},
		{"id": "br_rome_ponte_risorgimento", "cc": "IT", "name": "Ponte del Risorgimento", "wiki": "Ponte del Risorgimento",
			"aliases": ["ponte risorgimento", "risorgimento bridge"], "lat": 41.9187, "lon": 12.47077, "bearing": 82.7,
			"st": "arch_deck", "spans": [100.0], "width": 20.5, "clear": 12.0, "rise": 10.0, "material": "concrete",
			"base": "water", "tier": 3, "conf": 2,
			"src": "OSM way (axis 82.7, centre; 129 m); single 100 m Hennebique concrete arch (1911) and 20 m " +
				"width from memory, not verified in this session; clear, rise estimated | verified: OSM way " +
				"re-measured via api.openstreetmap.org/api/0.6/map: way 25266221 mid 41.91871,12.47077 brg " +
				"263.1 (footway 82.7 is the reverse), 102 m. it Wikipedia (Ponte del Risorgimento (Roma)): " +
				"single Hennebique arch, inscription 'unica arcata di 100 metri di corda con freccia di 10 " +
				"metri', 20.95 m wide, 159 m with approaches; laboratorioroma: one arch over 100 m, 20 m " +
				"wide. Clear estimated."},
		{"id": "br_rome_ponte_giacomo_matteotti", "cc": "IT", "name": "Ponte Giacomo Matteotti", "wiki": "Ponte Giacomo Matteotti",
			"aliases": ["ponte matteotti", "matteotti bridge rome"], "lat": 41.91438, "lon": 12.47067, "bearing": 81.5,
			"st": "masonry", "spans": [42.0, 54.0, 42.0], "width": 20.1, "clear": 12.0, "rise": 6.0,
			"material": "stone", "base": "water", "tier": 3, "conf": 1,
			"src": "it Wikipedia (travertine-faced arches, about 138 m long, about 20 m wide), OSM way (axis " +
				"81.5, centre; 135 m); 3 arches and split estimated, clear, rise estimated | verified: OSM " +
				"way re-measured via api.openstreetmap.org/api/0.6/map: way 24187372 mid 41.91436,12.47073 " +
				"brg 260.7 (row 81.5 is the reverse), 120 m. it/en Wikipedia 138.6 m x 20.1 m, three arches " +
				"on two piers with circular openings; laboratorioroma 138 x 20. Individual spans unpublished. " +
				"| round 2: round2: searched for the arch span split and found none: it/de/en Wikipedia raw " +
				"wikitext (infobox luce/hluce empty, text gives only arch count, total length and width), " +
				"laboratorioroma 'I ponti sul Tevere' PDF, turismoroma.it snippets, Sovrintendenza Capitolina " +
				"snippets, Structurae (403 to fetch). No source publishes the individual spans, so the split " +
				"stays an estimate."},
		{"id": "br_rome_ponte_giuseppe_mazzini", "cc": "IT", "name": "Ponte Giuseppe Mazzini", "wiki": "Ponte Giuseppe Mazzini",
			"aliases": ["ponte mazzini", "mazzini bridge rome"], "lat": 41.89606, "lon": 12.466, "bearing": 46.8,
			"st": "masonry", "spans": [30.0, 46.0, 30.0], "width": 17.0, "clear": 11.0, "rise": 5.0,
			"material": "stone", "base": "water", "tier": 3, "conf": 1,
			"src": "it Wikipedia (3 wide masonry arches faced in travertine, 106.15 m, 17 m wide), OSM way (axis " +
				"46.8, centre; 106 m); split estimated, clear, rise estimated | verified: OSM way re-measured " +
				"via api.openstreetmap.org/api/0.6/map: way 24609537 mid 41.89606,12.46600 brg 46.5, 106 m. " +
				"it Wikipedia 106.15 m x 17 m, three wide arches; laboratorioroma 106 x 17. Individual spans " +
				"unpublished. | round 2: round2: searched for the arch span split and found none: it/de/en " +
				"Wikipedia raw wikitext (infobox luce/hluce empty, text gives only arch count, total length " +
				"and width), laboratorioroma 'I ponti sul Tevere' PDF, turismoroma.it snippets, " +
				"Sovrintendenza Capitolina snippets, Structurae (403 to fetch). No source publishes the " +
				"individual spans, so the split stays an estimate."},
		{"id": "br_rome_ponte_regina_margherita", "cc": "IT", "name": "Ponte Regina Margherita", "wiki": "Ponte Regina Margherita",
			"aliases": ["ponte margherita", "margherita bridge rome"], "lat": 41.90973, "lon": 12.47237,
			"bearing": 73.9, "st": "masonry", "spans": [28.0, 46.0, 28.0], "width": 20.5, "clear": 11.0, "rise": 5.0,
			"material": "stone", "base": "water", "tier": 3, "conf": 1,
			"src": "OSM way (axis 73.9, centre; 102 m, 4 lanes); arch count, spans, width from memory/guess, not " +
				"verified; clear, rise estimated | verified: OSM way re-measured via " +
				"api.openstreetmap.org/api/0.6/map: way 33281525 mid 41.90973,12.47238 brg 71.4, 101 m. it " +
				"Wikipedia 103.1 m x 20.95 m, 3 travertine-faced arches; en ~110 m; laboratorioroma 111 x 20. " +
				"Split guessed. | round 2: round2: searched for the arch span split and found none: it/de/en " +
				"Wikipedia raw wikitext (infobox luce/hluce empty, text gives only arch count, total length " +
				"and width), laboratorioroma 'I ponti sul Tevere' PDF, turismoroma.it snippets, " +
				"Sovrintendenza Capitolina snippets, Structurae (403 to fetch). No source publishes the " +
				"individual spans, so the split stays an estimate."},
		{"id": "br_rome_ponte_della_musica", "cc": "IT", "name": "Ponte della Musica", "wiki": "Ponte della Musica",
			"aliases": ["ponte della musica armando trovajoli", "music bridge rome"], "lat": 41.92657, "lon": 12.45982,
			"bearing": 74.1, "st": "arch_tied", "spans": [189.0], "width": 20.0, "clear": 10.0, "rise": 15.0,
			"material": "steel", "base": "water", "tier": 3, "conf": 1,
			"src": "OSM ways (axis 74.1, centre; 205 m); span, width, rise guessed from memory (a long steel " +
				"pedestrian/tram arch bridge), not verified; may not be a single span | verified: OSM way re- " +
				"measured via api.openstreetmap.org/api/0.6/map: way 220022254 mid 41.92653,12.45984 brg " +
				"74.1, 205 m incl. stairs/ramps. laboratorioroma PDF: steel deck 190 m long, 22 m wide mid, " +
				"14 m at ends, carried by two lowered steel arches that hold the stairs; single 189 m span, " +
				"rise and arch type unconfirmed. | round 2: round2: searched for the arch span split and " +
				"found none: it/de/en Wikipedia raw wikitext (infobox luce/hluce empty, text gives only arch " +
				"count, total length and width), laboratorioroma 'I ponti sul Tevere' PDF, turismoroma.it " +
				"snippets, Sovrintendenza Capitolina snippets, Structurae (403 to fetch). No source publishes " +
				"the individual spans, so the split stays an estimate."},
		{"id": "br_belgrade_branko_s_bridge", "cc": "RS", "name": "Branko's Bridge", "wiki": "Branko's Bridge",
			"aliases": ["brankov most", "branko bridge belgrade", "most brankov"], "lat": 44.81476, "lon": 20.44808,
			"bearing": 85.9, "st": "haunched", "spans": [81.5, 261.0, 81.5], "width": 29.0, "clear": 13.0,
			"material": "steel", "base": "water", "tier": 2, "conf": 2, "mid_depth": 4.5, "pier_depth": 9.0,
			"src": "en+sr Wikipedia (continuous steel box girder 81.5+261+81.5 m downstream, 450 m with " +
				"approaches; carriageways 10.5 m + footways, two parallel structures, width about 29 m " +
				"derived), OSM ways via api.openstreetmap.org (beam bridges, axis 85.9, centre 20.4481; " +
				"Wikipedia coord 44.81472,20.44833); NOT BUILT: variable-depth box girder, width and clear " +
				"estimated | verified: OSM way 198825796 (bridge) mid 44.81476,20.44808, roadway way " +
				"1360181825 brg 86.1 (matches row 85.9); Wikipedia coord 44.81472,20.44833. en Wikipedia: " +
				"continuous steel box girder, main span 261 m, side spans 81 m, 450 m; sr Wikipedia: original " +
				"1956 MAN girder 75+261+75 m, roadway 12 m + 2x3 m footways, 1979 downstream structure " +
				"81.5+261+81.5 m (10.5 m carriageway, 2 x 0.7 m, 2.25 m footway); two parallel structures " +
				"sharing piers => ~29 m. Girder depths (pier 9 / mid 4.5 m) and clear 13 estimated."},
		{"id": "br_belgrade_gazela_bridge", "cc": "RS", "name": "Gazela Bridge", "wiki": "Gazela Bridge",
			"aliases": ["most gazela", "gazela most"], "lat": 44.8031, "lon": 20.44, "bearing": 126.5, "st": "girder",
			"spans": [71.0, 190.0, 71.0], "width": 27.5, "clear": 22.8, "material": "steel", "base": "water", "tier": 2,
			"conf": 1,
			"src": "en+sr Wikipedia (332 m long, 27.5 m wide, 22.8 m height at span centre), OSM way (axis " +
				"126.5, centre of a 664 m approach-inclusive way); span split 71+190+71 from memory, not " +
				"verified; centre approximate; variable-depth box | verified: OSM way 23789021 mid " +
				"44.80301,20.44014 brg 126.2 (639 m with approaches). en/sr Wikipedia: 332 m x 27.5 m, 22.8 m " +
				"at span centre, shallow steel frame with diagonal steel-concrete struts, infobox main span " +
				"250 m; Springer/Structurae abstract (doi 10.1007/978-3-658-03714-7_8): river frame 332 m, " +
				"250 m main span, inclined piers 63 m from the end piers, 2 x 66.8 m approach beams. Would " +
				"fit haunched with legs, but spans do not add up (63+206+63 vs 250), so left at conf 1. | " +
				"round 2: round2: sr Wikipedia (Газела (мост)) gives only 332 m x 27.5 m, 22.8 m at span " +
				"centre; Springer/Structurae abstracts: river frame 332 m, main span 250 m (Wikipedia/Monash " +
				"list 260 m), inclined piers 63.023 m from the end piers, frame 15.3 m high, 2 x 66.8 m " +
				"approach beams. (332-250)/2 = 41 m side spans with leg feet 63 m from the end piers would be " +
				"consistent, but no source states the side spans or the leg geometry, and the sources " +
				"disagree on 250 vs 260 m. Not raised."},
		{"id": "br_belgrade_ada_bridge", "cc": "RS", "name": "Ada Bridge", "wiki": "Ada Bridge",
			"aliases": ["most na adi", "ada ciganlija bridge", "most preko ade"], "lat": 44.7959, "lon": 20.42615,
			"bearing": 351.3, "st": "stayed", "spans": [200.0, 376.0], "width": 45.04, "clear": 22.0, "tower": 200.0,
			"towers": [1], "pylon": "single", "material": "steel", "base": "water", "tier": 1, "conf": 2,
			"src": "en+sr Wikipedia (main span 376 m, post-tensioned concrete back span 200 m, single 200 m " +
				"pylon, deck 45.04 m wide, 964-996 m with 388 m approach excluded), OSM cable-stayed ways " +
				"(axis 171.3, reversed), Wikipedia coord 44.795,20.4267; which bank carries the pylon and " +
				"deck height are estimated | verified: en Wikipedia: cable-stayed, single 200 m pylon on the " +
				"tip of Ada Ciganlija, main span 376 m, width 45.04 m, 996 m total; infobox/Structurae span " +
				"list 80-120-2x80-376-250 (back span 250) vs Ponting/Mageba/roadtraffic-technology " +
				"'counterbalanced by a 200 m back span', Ponting width 45.2 m; OSM re-measure failed " +
				"(api.openstreetmap.org 429 repeatedly), first-pass OSM axis 171.3 and Wikipedia coord " +
				"44.795,20.4267 (about 60 m from row centre) not re-checked. Row geometry (200 + 376, pylon " +
				"on support 1, bearing 351.3 toward New Belgrade) is plausible and may be raised to 2 by a " +
				"re-check. | round 2: round2: Ponting (the designer) project page ponting.si/en/projects/ada- " +
				"bridge-over-sava-in-belgrade-53.html: 965 m long, 'two main spans of 200 m and 376 m and one " +
				"200 m high pylon', composite deck 45.20 m wide and 4.50 m deep (en Wikipedia 45.04 m; " +
				"Structurae conference paper abstract and roadtraffic-technology also give 376 m main + 200 m " +
				"back span, so the 250 m in the Wikipedia infobox is the odd one out). OSM re-measure from " +
				"api.openstreetmap.org/api/0.6/map bbox: bridge relation 1946825 (length=964, Q1272855), " +
				"carriageways 593948550/593948551 and tram 144000331 axis 351.4-351.5 / 171.2; Sava water " +
				"polygon (rel 535556) has its south bank at lat 44.7953 and north bank at 44.7981, so the " +
				"pylon sits on the south bank tip of Ada Ciganlija at about 44.7951, the 376 m main span runs " +
				"north to 44.7985 and the 200 m back span south to 44.7933 (matches the OSM deck start). " +
				"Deck-spans centre (288 m from the south start) = 44.7959, 20.42615 (mean of tram and " +
				"carriageway lines). Deck height 22 m is an estimate (+-3)."},
		{"id": "br_belgrade_pancevo_bridge", "cc": "RS", "name": "Pancevo Bridge", "wiki": "Pančevo Bridge",
			"aliases": ["pančevo bridge", "pancevacki most", "pančevački most"], "lat": 44.82933, "lon": 20.49209,
			"bearing": 7.4, "st": "truss", "spans": [162.1, 162.1, 162.1, 162.1, 162.1, 162.1, 162.1], "width": 18.0,
			"clear": 14.0, "rise": 14.0, "material": "steel", "base": "water", "tier": 2, "conf": 1,
			"src": "en+sr Wikipedia (steel bridge 1526.4 m, 1134.7 m over the river bed, main span 162 m, 18 m " +
				"wide), OSM way (axis 7.4, centre); seven equal spans = 1134.7/7 assumed, truss height and " +
				"clear estimated | verified: OSM ways 41169825/208544235 (rail truss, 1089 m) and 23428571 " +
				"mid 44.82933,20.4920 brg 7.4/187.4 agree with row; en/sr Wikipedia: steel 1526.4 m, 1134.7 m " +
				"over the river bed, main span 162 m, 18 m wide, pier height 18 m. Truss spans differ along " +
				"the river; seven equal 162.1 m spans is a guess. | round 2: round2: sr/en Wikipedia give " +
				"only 1526.4 m total, 18 m wide; searches (sr/en) found no span table for the truss units; " +
				"OSM ways 41169825/208544235/23428571 have no pier nodes. Seven equal spans stays a guess."},
		{"id": "br_sarajevo_latin_bridge", "cc": "BA", "name": "Latin Bridge", "wiki": "Latin Bridge",
			"aliases": ["latinska cuprija", "latinska ćuprija", "princip bridge"], "lat": 43.85763, "lon": 18.42894,
			"bearing": 163.9, "st": "masonry", "spans": [9.2, 9.5, 10.8, 9.7], "width": 5.5, "clear": 4.0, "rise": 2.0,
			"material": "stone", "base": "water", "tier": 2, "conf": 1,
			"src": "web search snippet of ancient-history-sites.com (four arches 6.2/6.8/8.4/7.0 m clear, piers " +
				"3.0/2.4/2.4 m, 39.2 m long), OSM way (axis 163.9, Wikidata Q1277685); pier-centre spans " +
				"derived, width, clear, rise guessed | verified: OSM way 242640790 mid 43.85763,18.42893 axis " +
				"342.7 (row 163.9 is the reverse), 35 m. islamicartsmagazine.com: 40 m, 4 visible arches of " +
				"an original 5; structurae: semi-circular arches, two round pier openings; en/bs Wikipedia " +
				"infobox has no dimensions. | round 2: round2: bs/en Wikipedia raw: four arches on three " +
				"piers (a fifth walled in during the 19th-c. river regulation), two relieving oculi; no " +
				"dimensions. Only source of the span list remains ancient-history-sites.com (clear " +
				"6.2/6.8/8.4/7.0 m, left-to-right order unspecified, 39.2 m long); islamicartsmagazine 40 m. " +
				"No source for deck width (5.5 is a guess). Not raised."},
		{"id": "br_skopje_stone_bridge", "cc": "MK", "name": "Stone Bridge Skopje", "wiki": "Stone Bridge (Skopje)",
			"aliases": ["kameni most", "kamen most", "stone bridge skopje", "dusan bridge"], "lat": 41.99712,
			"lon": 21.43324, "bearing": 47.9, "st": "masonry",
			"spans": [17.82, 17.82, 17.82, 17.82, 17.82, 17.82, 17.82, 17.82, 17.82, 17.82, 17.82, 17.82], "width": 6.0,
			"clear": 7.0, "rise": 4.0, "material": "stone", "base": "water", "tier": 1, "conf": 1,
			"src": "en+mk Wikipedia (12 arches, 214 m / 213.85 m, 6 m wide), OSM way (axis 47.9, centre, 218 m, " +
				"Wikidata Q1780883); equal spans assumed, clear and rise estimated | verified: OSM way " +
				"411079115 mid 41.99712,21.43324 axis 227.7 (row 47.9 is the reverse), 219 m. en Wikipedia: " +
				"12 semicircular arches, 214 m x 6 m; mk Wikipedia: 213.85 m, 6-6.33 m wide, originally 13 " +
				"arches; web search: accounts range from 8 to 14 openings, piers of unequal size. | round 2: " +
				"round2: en/mk Wikipedia and web search: 12 semicircular arches, 214 m x 6 m; no per-arch " +
				"spans, accounts disagree on arch count (8-14) and note unequal piers. Not raised."},
		{"id": "br_skopje_art_bridge", "cc": "MK", "name": "Art Bridge Skopje", "wiki": "Art Bridge",
			"aliases": ["most na umetnosta", "мост на уметноста"], "lat": 41.99569, "lon": 21.4359, "bearing": 23.1,
			"st": "girder", "spans": [27.7, 27.6, 27.7], "width": 10.6, "clear": 5.0, "material": "steel",
			"base": "water", "tier": 3, "conf": 1,
			"src": "en+mk Wikipedia (83 m long, 9.2 m wide, 12 m at central part), OSM way (axis 23.1, centre, " +
				"79 m); span count and split, clear and structure guessed | verified: OSM way 177049423 mid " +
				"41.99570,21.43590 brg 22.9 (matches). en Wikipedia: pedestrian bridge, 83 m x 9.2 m (12 m at " +
				"centre part). | round 2: round2: Structurae (via search snippet): deck arch bridge with two- " +
				"hinged STEEL arches on reinforced-concrete piers, 3 spans, 83 m x 9.2 m (12 m at centre), " +
				"pedestrian only, completed April 2013 -> the row's st 'girder' is probably wrong " +
				"(arch_deck). No span lengths or arch rise found, so neither type nor spans can be raised."},
		{"id": "br_podgorica_millennium_bridge", "cc": "ME", "name": "Millennium Bridge Podgorica", "wiki": "Millennium Bridge (Podgorica)",
			"aliases": ["most milenijum", "millennium bridge moraca"], "lat": 42.44514, "lon": 19.25837,
			"bearing": 112.2, "st": "stayed", "spans": [33.0, 140.0], "width": 24.5, "clear": 12.0, "tower": 69.0,
			"towers": [1], "pylon": "single", "material": "steel", "base": "water", "tier": 2, "conf": 1,
			"src": "en Wikipedia (cable-stayed, main span 140 m, 173 m total, pylon 57 m above roadbed, 2 lanes " +
				"+ walkways each way), OSM way (axis 112.2, centre); pylon bank, width and deck height " +
				"guessed | verified: OSM way 736842994 mid 42.44508,19.25834 brg 111.9 (matches). en " +
				"Wikipedia: 173 m, main span 140 m, pylon 57 m above roadbed; Ponting project page: 181 m, " +
				"max span 150 m, width 25.4 m, inclined pylon with back stays to counterweights; structurae " +
				"24.2 m; no OSM pylon feature. | round 2: round2: Ponting project page (designer) via search: " +
				"inclined pylon 57 m, asymmetric cable-stayed, main stays in one central plane, max span 150 " +
				"m, length 181 m, width 25.4 m; Structurae 173 m / 140 m / 24.2 m; no back-span length " +
				"published (back stays go to a counterweight/entrance plateau). Sources disagree on span and " +
				"width; the 33 m back span is derived. Not raised."},
		{"id": "br_podgorica_blazo_jovanovic_bridge", "cc": "ME", "name": "Blazo Jovanovic Bridge", "wiki": "Most Blaža Jovanovića",
			"aliases": ["most blaza jovanovica", "most blaža jovanovića"], "lat": 42.44021, "lon": 19.25797,
			"bearing": 110.3, "st": "girder", "spans": [38.4, 38.4, 38.4], "width": 22.35, "clear": 8.0,
			"material": "concrete", "base": "water", "tier": 3, "conf": 1,
			"src": "sr Wikipedia (115.2 m long, 22.35 m wide), OSM way (axis 110.3, centre, 139 m); structure, " +
				"spans and clear guessed | verified: OSM way 197753115 mid 42.44025,19.25799 brg 291.7 (row " +
				"110.3 is the reverse), 139 m incl. approaches. sr Wikipedia: 115.2 m x 22.35 m, built " +
				"1948-50, design Branko Zezelj; no span layout found. | round 2: round2: sr Wikipedia only " +
				"(115.2 m x 22.35 m, 1948-50); no span layout found in searches. Not raised."},
		{"id": "br_sofia_lions_bridge", "cc": "BG", "name": "Lions' Bridge Sofia", "wiki": "Lions' Bridge, Sofia",
			"aliases": ["lavov most", "лъвов мост", "lions bridge sofia"], "lat": 42.70493, "lon": 23.32388,
			"bearing": 12.5, "st": "masonry", "spans": [13.0, 13.0], "width": 18.1, "clear": 4.0, "rise": 2.0,
			"material": "stone", "base": "water", "tier": 3, "conf": 2,
			"src": "bg Wikipedia (26 m long, 18.1 m wide, two 10 m openings), en Wikipedia (stone arch, 32 m, 18 " +
				"m), OSM ways (axis 12.5, 26 m), Wikipedia coord 42.70493,23.3239; piers and clear estimated " +
				"| verified: OSM tram ways 96629980/96629849 mid 42.70491,23.32389 brg 12.7 (matches row " +
				"12.5), 26 m. bg Wikipedia: 26 m x 18.1 m, 'two openings of 10 m'; en Wikipedia 32 m x 18 m " +
				"(Kiradzhiev). Pier-centre 13 m each; clear and rise estimated."},
	]
