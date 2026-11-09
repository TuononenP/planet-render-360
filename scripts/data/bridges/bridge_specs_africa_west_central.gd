class_name BridgeSpecsAfricaWestCentral
extends RefCounted

## Capital bridge rows for West and Central Africa (see BridgeSpec for the schema). Figures are
## sourced per row in `src`; conf 1 rows are kept as data but not built
## (BridgeSpec.MIN_BUILT_CONF).

static func rows() -> Array:
	return [
		{"id": "br_bamako_martyrs_bridge", "cc": "ML", "name": "Martyrs Bridge", "wiki": "Martyrs Bridge (Bamako)",
			"aliases": ["pont des martyrs", "pont de badalabougou"], "lat": 12.63045, "lon": -7.99211, "bearing": 150.5,
			"st": "girder",
			"spans": [44.0, 44.0, 44.0, 44.0, 44.0, 44.0, 44.0, 44.0, 44.0, 44.0, 44.0, 44.0, 44.0, 44.0, 44.0, 44.0, 44.0, 44.0, 44.0, 44.0],
			"width": 12.0, "clear": 10.0, "material": "concrete", "base": "water", "tier": 2, "conf": 1,
			"src": "en/fr Wikipedia (1957, Niger crossing, coord 12.6303,-7.9919), Structurae (precast concrete " +
				"T-girders on RC piers); OSM way 198734582 (Nominatim) 879 m and bearing; span count/lengths, " +
				"width (2 lanes + 2 footways ~12 m) and clearance estimated | verified: OSM way 198734582 re- " +
				"measured: 883 m, bearing 150.5, mid 12.63045,-7.99211 (unchanged; Wikidata Q3397394 coord " +
				"within 70 m). en/fr Wikipedia give no spans or width (only 1957, Niger crossing); Structurae " +
				"snippet = T-section girder, precast concrete beams on RC piers, no dimensions seen. Span " +
				"count/lengths, width, clearance remain unsourced. | round 2: round 2: Web search (Structurae " +
				"snippets, en/fr Wikipedia) again gave no span list or width."},
		{"id": "br_bamako_king_fahd_bridge", "cc": "ML", "name": "King Fahd Bridge", "wiki": "King Fahd Bridge",
			"aliases": ["pont roi fahd", "pont du roi-fahd", "pont fahd bamako"], "lat": 12.62388, "lon": -8.00495,
			"bearing": 144.6, "st": "girder",
			"spans": [48.2, 48.2, 48.2, 48.2, 48.2, 48.2, 48.2, 48.2, 48.2, 48.2, 48.2, 48.2, 48.2, 48.2, 48.2, 48.2],
			"width": 24.0, "clear": 12.0, "material": "concrete", "base": "water", "tier": 2, "conf": 1,
			"src": "Structurae snippet (prestressed box girder, 771 m, 16 spans, 24 m wide, 2x3 lanes), OSM way " +
				"444978590 772 m bearing 144.6, en/fr Wikipedia coord 12.62361,-8.00478; equal spans assumed " +
				"(771/16), clearance estimated | verified: OSM way 444978590 re-measured: 774 m, bearing " +
				"144.6, mid 12.62384,-8.00502 (correct). en/fr Wikipedia (opened 1992 / 1993 in fr) give no " +
				"dimensions; Structurae (search snippets) only confirm prestressed concrete box girder, no " +
				"span list reachable. 16 equal spans is just 771/16, no source says the spans are equal, and " +
				"24 m width is not independently confirmed. | round 2: round 2: Web search again gave only " +
				"prestressed concrete deck (Structurae); no span list/width."},
		{"id": "br_bamako_sino_malian_friendship_bridge", "cc": "ML", "name": "Sino-Malian Friendship Bridge", "wiki": "Pont de l'amitié sino-malienne",
			"aliases": ["pont de l'amitié sino-malienne", "third bridge bamako", "troisieme pont bamako"],
			"lat": 12.64276, "lon": -7.9264, "bearing": 155.6, "st": "girder",
			"spans": [49.3, 49.3, 49.3, 49.3, 49.3, 49.3, 49.3, 49.3, 49.3, 49.3, 49.3, 49.3, 49.3, 49.3, 49.3, 49.3, 49.3, 49.3, 49.3, 49.3, 49.3, 49.3, 49.3, 49.3, 49.3, 49.3, 49.3, 49.3, 49.3, 49.3, 49.3, 49.3, 49.3],
			"width": 24.0, "clear": 12.0, "material": "concrete", "base": "water", "tier": 2, "conf": 1,
			"src": "fr Wikipedia (2011, 1616-1627 m, 24 m, reinforced concrete and steel; no en article), OSM " +
				"way 149144269 1627 m bearing 155.6 (curved, 29 nodes); spans not found (equal assumed, may " +
				"include approach viaduct; a Chinese source says the trunk is 1.45 km), structure type and " +
				"clearance guessed | verified: OSM way 149144269 re-measured: 29-node curved way, chord 1622 " +
				"m, bearing 155.6 (first seg 150.0, last 154.5), mid 12.64276,-7.92640 (correct). fr " +
				"Wikipedia: 1627 m, 24 m wide, reinforced concrete and steel, 2011; no span list, no type, no " +
				"en article. Spans/type/clearance unsourced; length may include approach viaduct. | round 2: " +
				"round 2: fr Wikipedia only (1627 m, 24 m); no span list; not retried."},
		{"id": "br_niamey_kennedy_bridge", "cc": "NE", "name": "Kennedy Bridge", "wiki": "Kennedy Bridge (Niamey)",
			"aliases": ["pont kennedy", "kennedy bridge niamey"], "lat": 13.50528, "lon": 2.10461, "bearing": 45.7,
			"st": "girder",
			"spans": [50.7, 50.7, 50.7, 50.7, 50.7, 50.7, 50.7, 50.7, 50.7, 50.7, 50.7, 50.7, 50.7, 50.7],
			"width": 11.0, "clear": 10.0, "material": "concrete", "base": "water", "tier": 2, "conf": 1,
			"src": "en Wikipedia (1970), Structurae (girder, 710 m), repo OSM snapshot way 31276135 745 m " +
				"bearing 45.7; spans, width and clearance not found (estimated) | verified: OSM way 31276135 " +
				"re-measured: 746 m, bearing 225.5 (reverse of listed 45.7, same line), mid 13.50528,2.10460 " +
				"(correct). Wikidata Q1101213 length 710 m, 1970-12-19; en/fr Wikipedia give no spans or " +
				"width (fr infobox says 'pont transbordeur', clearly wrong). 710 vs 746 m means the 14x50.7 " +
				"split is not credible; spans, width, clearance unsourced. | round 2: round 2: 710 vs 746 m " +
				"length mismatch, no spans/width."},
		{"id": "br_niamey_seyni_kountche_bridge", "cc": "NE", "name": "General Seyni Kountche Bridge", "wiki": "Pont Général Seyni Kountché",
			"aliases": ["pont general seyni kountche", "third bridge niamey", "troisieme pont niamey"], "lat": 13.51869,
			"lon": 2.05953, "bearing": 4.1, "st": "girder",
			"spans": [58.0, 58.0, 58.0, 58.0, 58.0, 58.0, 58.0, 58.0, 58.0, 58.0, 58.0, 58.0, 58.0, 58.0, 58.0, 58.0],
			"width": 24.0, "clear": 12.0, "material": "concrete", "base": "water", "tier": 2, "conf": 1,
			"src": "fr Wikipedia (928 m, reinforced concrete, opened 2021, coord 13.5217,2.0597; no en article), " +
				"AidData (main bridge 928 m, 4 lanes), OSM polygon way 1099929428 926 m axis 4.1; type, " +
				"spans, width and clearance not found (guessed) | verified: OSM way 1099929428 is a closed " +
				"bridge polygon (bridge:structure=beam, 32 nodes); axis length ~926 m previously measured, fr " +
				"Wikipedia 928 m reinforced concrete, opened 2021-02-18, coord 13.52167,2.05964 (within 300 m " +
				"of row centre; row centre taken from the polygon axis). No span list or width found. | round " +
				"2: round 2: No span list or width in fr Wikipedia/AidData."},
		{"id": "br_monrovia_gabriel_tucker_bridge", "cc": "LR", "name": "Gabriel Tucker Bridge", "wiki": "Gabriel Tucker Bridge",
			"aliases": ["gabriel johnson tucker bridge", "people's bridge"], "lat": 6.32001, "lon": -10.8019,
			"bearing": 349.8, "st": "haunched", "spans": [53.34, 106.68, 106.68, 106.68, 53.34], "width": 14.0,
			"clear": 9.0, "material": "concrete", "base": "sea", "tier": 3, "conf": 2,
			"src": "Structurae snippet (426.72 m, 5 spans 53.34+3x106.68+53.34, 14.02 m, prestressed concrete; " +
				"listed as Johnson Street Bridge), en Wikipedia coord 6.3194,-10.8022, OSM way 141275374 434 " +
				"m bearing 349.8; clearance estimated; 1:2 span ratio suggests variable-depth balanced " +
				"cantilever boxes which the builder cannot show | verified: Structurae record 'Johnson Street " +
				"Bridge (Monrovia, 1978)' (alt. Gabriel Johnson Tucker Bridge) re-found via search: 5 spans " +
				"53.34+3x106.68+53.34 = 426.72 m, prestressed concrete box girder, haunched girder, balanced " +
				"cantilever, 1975-78; this is the only source for spans/width (14.02 m) so not raised. OSM " +
				"way 141275374 re-measured: 437 m, bearing 349.8, mid 6.32002,-10.80193 (correct). Clearance " +
				"7 m still an estimate (navigable channel, could be higher). Retyped girder -> haunched " +
				"(balanced cantilever, matches the 1:2 side/main ratio); pier_depth/mid_depth defaults. | " +
				"round 2: Structurae (search snippet, entry 'Johnson Street Bridge' alias Gabriel Johnson " +
				"Tucker Bridge, 1975-78): prestressed concrete box girder, haunched girder, balanced " +
				"cantilever, 5 spans, deck depth 1.83-4.78 m, deck width 14.021 m: independently matches " +
				"round-1 span layout 53.34+3x106.68+53.34 (175+3x350+175 ft, 426.72 m; OSM way 141275374 is " +
				"437 m incl. abutments) and 14.0 m width; centre/bearing from OSM way 141275374 (brg 349.8, " +
				"mid 6.32002,-10.80193) re-measured in round 1. Individual span lengths come from the round-1 " +
				"source only (Structurae page itself 403 / paywalled); clear raised 7 -> 9 m as an estimate " +
				"(deck over a tidal creek channel, 4.78 m girder at piers), uncertainty about +-3 m."},
		{"id": "br_banjul_denton_bridge", "cc": "GM", "name": "Denton Bridge", "wiki": "Denton Bridge (The Gambia)",
			"aliases": ["denton bridge banjul"], "lat": 13.46788, "lon": -16.62805, "bearing": 94.4, "st": "girder",
			"spans": [42.0, 42.0, 42.0, 42.0, 42.0], "width": 20.0, "clear": 5.0, "material": "concrete", "base": "sea",
			"tier": 3, "conf": 1,
			"src": "en Wikipedia (girder, 210 m, 20 m, 4 lanes, 1986, coord 13.46786,-16.62797), Structurae " +
				"(continuous girder 210 m), OSM ways 92036154/109369546 214 m bearing 94.4; span layout, " +
				"material and clearance not found (estimated) | verified: OSM ways 92036154/109369546 re- " +
				"measured: 213 m each (twin carriageways), bearing 94.4 / 274.8, mid 13.46785,-16.62805 " +
				"(correct); en Wikipedia: girder bridge 210 m x 20 m, 4 lanes, 1986, crosses Tanbi wetland; " +
				"an older 9 m-wide bridge 25 m north is decommissioned. No span layout, material or clearance " +
				"found. | round 2: round 2: No span layout source."},
	]
