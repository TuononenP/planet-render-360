class_name BridgeSpecsCaribbeanIslands
extends RefCounted

## Capital bridge rows for the Caribbean islands (see BridgeSpec for the schema). Figures are
## sourced per row in `src`; conf 1 rows are kept as data but not built
## (BridgeSpec.MIN_BUILT_CONF).

static func rows() -> Array:
	return [
		{"id": "br_willemstad_queen_juliana_bridge", "cc": "CW", "name": "Queen Juliana Bridge", "wiki": "Queen Juliana Bridge",
			"aliases": ["koningin julianabrug", "brug di reina juliana"], "lat": 12.1113, "lon": -68.93195,
			"bearing": 113.7, "st": "girder", "spans": [150.0, 200.0, 150.0], "width": 20.0, "clear": 56.4,
			"material": "steel", "base": "sea", "tier": 2, "conf": 1,
			"src": "en Wikipedia (500 m, 56.4 m above water at apex, 4 lanes, steel rigid frame with inclined " +
				"legs, opened 1974), Structurae/brueckenweb (steel trapezoidal frame), OSM ways " +
				"27098493+30383830 for centre and bearing (498 m, west Otrobanda to east Punda); individual " +
				"spans and width NOT sourced (side/main split and 20 m guessed); inclined-leg rigid frame " +
				"approximated as a girder | verified: OSM way 30383830 re-measured: 497 m, bearing 293.8 " +
				"(reverse of listed 113.7), mid 12.11129,-68.93195 (correct). en Wikipedia: 500 m, 56.4 m " +
				"above water at apex, four lanes, rigid frame with inclined legs, steel, 1974; brueckenweb: " +
				"steel trapezoidal frame, deck height 56.4 m, 500 m; Structurae: rigid frame bridge with " +
				"inclined legs. No source gives the span lengths (150/200/150 is a guess; an LLM-generated " +
				"mirror says 200 m main span) or the deck width. | round 2: round 2: nl Wikipedia, en " +
				"Wikipedia, brueckenweb, Structurae snippets (details paywalled): only total 500 m, 56.4 m " +
				"clearance, 4 lanes, rigid frame with inclined legs; no span lengths or width."},
		{"id": "br_willemstad_queen_emma_bridge", "cc": "CW", "name": "Queen Emma Bridge", "wiki": "Queen Emma Bridge",
			"aliases": ["koningin emmabrug", "swinging old lady", "brug di ponton"], "lat": 12.1061, "lon": -68.93538,
			"bearing": 131.9, "st": "pontoon",
			"spans": [10.5, 10.5, 10.5, 10.5, 10.5, 10.5, 10.5, 10.5, 10.5, 10.5, 10.5, 10.5, 10.5, 10.5, 10.5, 10.5],
			"width": 9.8, "clear": 1.5, "material": "steel", "base": "sea", "tier": 2, "conf": 1,
			"src": "en Wikipedia (pontoon swing bridge, 167 m, 9.8 m wide, 1888 rebuilt 1939/2006), OSM way " +
				"30410363 for centre and bearing (152 m, Otrobanda to Punda); floating pontoon with a swing " +
				"hinge cannot be represented, nearest st girder with equal pontoon-length spans guessed; NOT " +
				"BUILT | verified: en Wikipedia: pontoon bridge, 167 m, 9.8 m wide, hinged on the Otrobanda " +
				"side with two propeller motors on the Punda end, 1888/1939/2006; nl Wikipedia: 168 m long, " +
				"9.8 m wide, floats on 16 pontoons, timber deck, pedestrian only since 1974; Structurae: 167 " +
				"m, 9.80 m, wooden deck on steel pontoons. OSM way 30410363 re-measured: 153 m, bearing " +
				"132.1, mid 12.10610,-68.93538 (correct; bridge:movable=swing). 16 pontoons of 168/16 = 10.5 " +
				"m is an equal split with no source for individual pontoon lengths. Re-typed girder -> " +
				"pontoon. | round 2: round 2: nl Wikipedia raw: 168 m, 9.8 m wide, 16 pontoons, but no " +
				"individual pontoon lengths; equal split is not sourced."},
		{"id": "br_bridgetown_chamberlain_bridge", "cc": "BB", "name": "Chamberlain Bridge", "wiki": "Chamberlain Bridge",
			"aliases": ["chamberlain bridge bridgetown"], "lat": 13.09611, "lon": -59.61411, "bearing": 1.2,
			"st": "bascule", "spans": [3.0, 5.7, 3.0], "width": 8.86, "clear": 2.0, "material": "steel",
			"base": "water", "tier": 3, "conf": 1,
			"src": "en Wikipedia (current 2005-06 composite FRP bascule replacing the 1872 swing bridge, 11.72 m " +
				"long, 8.86 m wide, coordinate 13.0961,-59.6141), OSM way 548393680 (drawbridge leaf, bearing " +
				"1.2); span split guessed, deck height guessed, FRP leaf modelled as steel; article " +
				"contradicts itself single/double leaf | verified: OSM way 548393680 re-measured: 13 m, " +
				"bearing 1.1, mid 13.09611,-59.61411 (correct). en Wikipedia: current 2005-06 FRP bascule, " +
				"single span 11.72 m, 8.86 m wide, ~1 m deep, built in four segments (the text also says " +
				"double-leaf), contiguous to the refurbished two-span 1861 coral-stone arch; so the full " +
				"crossing is the lift span plus masonry arches and the 3/5.7/3 split is a guess. | round 2: " +
				"round 2: Single 11.72 m FRP leaf plus masonry arches; 3/5.7/3 split a guess; not retried."},
		{"id": "br_bridgetown_charles_duncan_oneal_bridge", "cc": "BB", "name": "Charles Duncan O'Neal Bridge", "wiki": "Charles Duncan O'Neal Bridge",
			"aliases": ["charles duncan o'neil bridge", "oneal bridge bridgetown"], "lat": 13.09616, "lon": -59.61288,
			"bearing": 340.3, "st": "girder", "spans": [17.0, 17.0, 17.0], "width": 16.0, "clear": 3.0,
			"material": "concrete", "base": "water", "tier": 3, "conf": 1,
			"src": "en Wikipedia (one of two bridges over the Careenage, on the $10 note; Wikidata Q5077000), " +
				"OSM way 37934271 (4-lane primary, 51 m, bearing 340.3 south to north); span split, width and " +
				"deck height NOT sourced, all guessed; en Wikipedia says it carries no traffic, OSM maps a " +
				"4-lane primary road | verified: OSM way 37934271 not re-fetchable (API 429); first-pass " +
				"geometry kept. en Wikipedia: one of two Careenage bridges, 'does not take traffic' " +
				"(contradicting OSM primary road), no dimensions at all. | round 2: round 2: No dimensions " +
				"anywhere; en Wikipedia says no traffic vs OSM primary road."},
	]
