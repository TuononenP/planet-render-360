class_name BridgeSpecsEastAsia
extends RefCounted

## Capital bridge rows for East Asia (see BridgeSpec for the schema). Figures are
## sourced per row in `src`; conf 1 rows are kept as data but not built
## (BridgeSpec.MIN_BUILT_CONF).

static func rows() -> Array:
	return [
		{"id": "br_tokyo_rainbow_bridge", "cc": "JP", "name": "Rainbow Bridge", "wiki": "Rainbow Bridge (Tokyo)",
			"aliases": ["tokyo port connector bridge", "レインボーブリッジ", "東京港連絡橋"], "lat": 35.6364, "lon": 139.7639,
			"bearing": 110.9, "st": "susp", "spans": [111.5, 570.0, 111.5], "width": 29.0, "clear": 63.0,
			"tower": 126.0, "material": "steel", "base": "sea", "tier": 1, "conf": 2,
			"src": "en Wikipedia infobox (main 570 m, 798 m, 49 m wide, roadway 52 m, towers 126 m), OSM api " +
				"ways (Daiba Route, axis 111 deg); side spans split evenly (798-570)/2; double-deck: modelled " +
				"at the 52 m upper-deck height | verified: ja Wikipedia infobox citing JASBC Bridge Yearbook " +
				"1994: span split 111.5+570.0+111.5, suspension-part width 29.0 m (49.0 m is the tower- " +
				"foundation width), girder underside TP 51.266 m, tower top TP 126 m; OSM motorway ways " +
				"316305907/8 (Daiba Route, 920 m incl. approaches, mid 35.63641,139.76394, bearing 110.9); " +
				"road surface = underside + ~12 m stiffening-truss depth (estimate, +-3 m)"},
		{"id": "br_tokyo_kachidoki_bridge", "cc": "JP", "name": "Kachidoki Bridge", "wiki": "Kachidoki Bridge",
			"aliases": ["kachidokibashi"], "lat": 35.6623, "lon": 139.7749, "bearing": 143.0, "st": "bascule",
			"spans": [97.2, 51.6, 97.2], "width": 22.0, "clear": 8.0, "material": "steel", "base": "sea", "tier": 2,
			"conf": 1,
			"src": "ja Wikipedia (246 m, 22 m wide, bascule 51.6 m, fixed tied arches 86.0 m), OSM api ways (143 " +
				"deg, 246 m); side = 86.0 arch + ~11.2 shore girder (inferred from 246 total); clear " +
				"estimated; the side tied arches are not drawn by the bascule builder | verified: Tokyo/JSCE " +
				"sources: 246.0 m, bascule 51.6 m, side tied arches 86.0 m; width disagrees (JSCE 22 m " +
				"effective vs Tokyo metropolitan 26.6 m, tourist page ~26 m); the remaining 22.4 m (2 x ~11.2 " +
				"m shore girders) is only a remainder; OSM ways 135195087 (247 m, 143.3 deg, mid " +
				"35.66228,139.77493) agree with row centre; a plain 97.2 m girder side would hide the " +
				"signature tied arches | round 2: round 2 (w_east_asia): JSCE AVC leaflet " +
				"kachidoki_yamashita_webup.pdf: 246.0 m, bascule 51.6 m, width 22 m, side spans 'through " +
				"steel tied arch'; Tokyo leaflet: 246.0 m x 26.6 m; Japan River Assoc. newsletter mentions a " +
				"44 m central span (disagrees). No source lists the side-span / shore-girder split, and JSCE " +
				"has no A5 sheet for it. Still unverified."},
		{"id": "br_tokyo_kiyosu_bridge", "cc": "JP", "name": "Kiyosu Bridge", "wiki": "Kiyosubashi",
			"aliases": ["kiyosubashi"], "lat": 35.6824, "lon": 139.7919, "bearing": 122.8, "st": "susp",
			"spans": [47.396, 91.44, 47.396], "width": 25.9, "clear": 7.0, "tower": 28.0, "material": "steel",
			"base": "sea", "tier": 2, "conf": 2,
			"src": "ja Wikipedia (186.3 m, 22.0 m wide), OSM api ways (suspension, axis 123 deg, 187 m); span " +
				"split 91.5 main = 300 ft design (Deutz model), sides from the total; self-anchored " +
				"suspension; clear and tower estimated | verified: EJEC (ej-hds.co.jp) seismic-design topic " +
				"page: 186.233 m = 47.396 + 91.440 + 47.396, 3-span continuous chain self-anchored stiffened " +
				"suspension; Tokyo official/Bridgemeister total width 25.9 m (22.0 m is the effective width); " +
				"ja Wikipedia 186.3 m, JSCE 186.2 m; OSM way 157238663 (187 m, 122.8 deg, mid " +
				"35.68241,139.79189) ; tower 28 m and clear 7 m remain estimates"},
		{"id": "br_tokyo_eitai_bridge", "cc": "JP", "name": "Eitai Bridge", "wiki": "Eitai Bridge",
			"aliases": ["eitaibashi"], "lat": 35.6763, "lon": 139.7875, "bearing": 104.5, "st": "arch_tied",
			"spans": [41.184, 100.584, 41.184], "width": 25.0, "clear": 7.0, "rise": 17.0, "material": "steel",
			"base": "sea", "tier": 2, "conf": 2, "arch_spans": [1],
			"src": "ja Wikipedia (184.7 m, 25.0 m, tied arch centre span + steel girder sides), OSM api ways " +
				"(axis 105 deg); span split and rise estimated; the arch builder draws an arch on every span " +
				"but only the centre span is an arch | verified: as-se.co.jp works page (steel 3-span " +
				"cantilever tied arch, centre 100.584 m, sides 41.184 m) with JSCE Twin Gate sheet (3-span " +
				"balanced tied arch, 185.2 m) and ja Wikipedia/asahi-net table (184.7 m, 25.0 m wide; 22 m is " +
				"the effective width); JCMA 2017 (first Japanese road bridge over 100 m span, arch between " +
				"P1-P2); OSM way 168663963 (186 m, 104.4 deg, mid 35.67634,139.78758); rise (~1/6 of span) " +
				"and clear are estimates"},
		{"id": "br_tokyo_shirahige_bridge", "cc": "JP", "name": "Shirahige Bridge", "wiki": "Shirahige Bridge",
			"aliases": ["shirahigebashi"], "lat": 35.72808, "lon": 139.80979, "bearing": 99.1, "st": "arch_tied",
			"spans": [44.196, 79.553, 44.196], "width": 22.14, "clear": 7.0, "rise": 12.0, "material": "steel",
			"base": "sea", "tier": 3, "conf": 1, "arch_spans": [1],
			"src": "ja Wikipedia (167.6 m, 24.1 m wide), OSM api way (arch, axis 98 deg); 3 equal spans, rise " +
				"and arch type assumed | verified: asahi-net Sumida bridge table: 168.8 m long, 22.1 m wide, " +
				"braced-rib tied arch (not 167.6 m / 24.1 m); span split still unsourced; OSM way 1042506369 " +
				"(169 m, 99.1 deg, mid 35.72808,139.80979) | round 2: round 2 (w_east_asia): JSCE A5-027 " +
				"(library.jsce.or.jp/jscelib/committee/2003/bridge/A5-027.htm): through braced-rib BALANCED " +
				"tied arch + truss girder, spans 44.196+79.553+44.196 m, 168.847 x 22.142 m (Tokyo leaflet: " +
				"168.8 x 22.8 m); OSM way 1042506369 (sidewalk on deck, 169.2 m, 99.06 deg, mid " +
				"35.72808,139.80979). Spans and width now sourced but 'balanced' arch has arch arms over the " +
				"side spans (plain-girder sides with arch_spans [1] would misrepresent them) and the 12 m " +
				"rise is unsourced"},
		{"id": "br_tokyo_tsukuda_ohashi", "cc": "JP", "name": "Tsukuda Ohashi", "wiki": "Tsukuda Ohashi",
			"aliases": ["tsukuda bridge"], "lat": 35.668, "lon": 139.7809, "bearing": 138.0, "st": "girder",
			"spans": [58.0, 88.0, 58.0], "width": 25.2, "clear": 6.0, "material": "steel", "base": "sea", "tier": 3,
			"conf": 1,
			"src": "ja Wikipedia (476.3 m with approaches, 3-span continuous steel box girder, 25.2 m), OSM api " +
				"ways (river crossing ~204 m, axis 138 deg); span split assumed; clear estimated (underside " +
				"matched to Kachidoki) | verified: ja Wikipedia infobox + asahi-net table: 3-span continuous " +
				"steel-deck box girder, 476.3 m with approaches, 25.2 m; OSM ways 131156028/051 (204-209 m " +
				"river crossing, 138.0 deg, mid 35.66791,139.78105); individual span lengths not found | " +
				"round 2: round 2 (w_east_asia): Tokyo leaflet " +
				"(kensetsu.metro.tokyo.lg.jp/content/000048924.pdf): 3-span continuous steel-deck box girder, " +
				"220.0 m long, 25.4 m wide (ja Wikipedia 476.3 m incl. approaches, 25.2 m); JSCE has no " +
				"sheet; no span split found in web searches. Row river crossing 204 m (OSM) vs 220 m " +
				"official."},
		{"id": "br_tokyo_nihonbashi", "cc": "JP", "name": "Nihonbashi Bridge", "wiki": "Nihonbashi",
			"aliases": ["nihonbashi"], "lat": 35.6841, "lon": 139.7745, "bearing": 14.0, "st": "masonry",
			"spans": [24.5, 24.5], "width": 27.3, "clear": 6.0, "rise": 3.5, "material": "stone", "base": "water",
			"tier": 2, "conf": 1,
			"src": "OSM api way (humpback, 48 m, axis 14 deg); length 49 m and two granite arches from memory of " +
				"en/ja Wikipedia (not re-read); width, rise, clear assumed; expressway overhead not modelled " +
				"| verified: Chuo city/serai: 20th bridge of 1911, two-span stone arch, 49 m long, ~27 m " +
				"wide; OSM bbox shows only expressway ways overhead (bridge deck way not separately matched); " +
				"arch spans/rise/clear unsourced | round 2: round 2 (w_east_asia): ja Wikipedia fetch for the " +
				"bridge article failed (Wikimedia error page) and web searches gave no arch spans, rise or " +
				"deck height; Chuo city: 1911 two-span stone arch, 49 m x ~27 m. Not in JSCE steel list " +
				"(stone bridge)."},
		{"id": "br_seoul_banpo_bridge", "cc": "KR", "name": "Banpo Bridge", "wiki": "Banpo Bridge",
			"aliases": ["banpo daegyo"], "lat": 37.516, "lon": 126.9957, "bearing": 160.0, "st": "girder",
			"spans": [55.0, 55.0, 55.0, 55.0, 55.0, 55.0, 55.0, 55.0, 55.0, 55.0, 55.0, 55.0, 55.0, 55.0, 55.0, 55.0, 55.0, 55.0, 55.0, 55.0],
			"width": 25.0, "clear": 14.0, "material": "concrete", "base": "water", "tier": 2, "conf": 1,
			"src": "en+ko Wikipedia (1490-1495 m, 25 m, double-deck over Jamsu Bridge), OSM api way 160 deg; " +
				"river crossing taken as ~1100 m, equal spans and clear assumed | verified: ko Wikipedia " +
				"infobox re-read (no span layout listed); no independent span table found (Seoul/namu pages " +
				"blocked or silent); OSM re-measure not repeated (rate-limited); ko: 1490 m, 25 m, steel box " +
				"girder; Seoul safety page quotes 1140 m; double-deck over Jamsu Bridge | round 2: round 2 " +
				"(w_east_asia): Korean web searches (Seoul safety pages news.seoul.go.kr/safe, " +
				"mediahub.seoul.go.kr, Korea archives Han River bridges, seoul.co.kr 1994/1997 articles) for " +
				"a Han River bridge table with span layouts found only opening years, total lengths and " +
				"widths; no span list for Banpo. Seongsu article gives 19.4 m width at 1,162 m for the 1979 " +
				"bridge (pre-1997 rebuild)."},
		{"id": "br_seoul_mapo_bridge", "cc": "KR", "name": "Mapo Bridge", "wiki": "Mapo Bridge",
			"aliases": ["mapo daegyo"], "lat": 37.5333, "lon": 126.9359, "bearing": 52.4, "st": "girder",
			"spans": [55.3, 55.3, 55.3, 55.3, 55.3, 55.3, 55.3, 55.3, 55.3, 55.3, 55.3, 55.3, 55.3, 55.3, 55.3, 55.3, 55.3, 55.3, 55.3],
			"width": 25.0, "clear": 12.0, "material": "concrete", "base": "water", "tier": 2, "conf": 1,
			"src": "en+ko Wikipedia (1390 m, girder, 25 m new bridge), OSM api way 52 deg; river crossing ~1050 " +
				"m, equal spans assumed | verified: ko Wikipedia infobox re-read (no span layout listed); no " +
				"independent span table found (Seoul/namu pages blocked or silent); OSM re-measure not " +
				"repeated (rate-limited); ko: 1390 m, steel box girder, new bridge 25 m + second bridge 22.75 " +
				"m | round 2: round 2 (w_east_asia): Korean web searches (Seoul safety pages " +
				"news.seoul.go.kr/safe, mediahub.seoul.go.kr, Korea archives Han River bridges, seoul.co.kr " +
				"1994/1997 articles) for a Han River bridge table with span layouts found only opening years, " +
				"total lengths and widths; no span list for Mapo. Seongsu article gives 19.4 m width at 1,162 " +
				"m for the 1979 bridge (pre-1997 rebuild)."},
		{"id": "br_seoul_seongsan_bridge", "cc": "KR", "name": "Seongsan Bridge", "wiki": "Seongsan Bridge",
			"aliases": ["seongsan daegyo"], "lat": 37.5519, "lon": 126.891, "bearing": 25.5, "st": "girder",
			"spans": [50.0, 50.0, 50.0, 50.0, 50.0, 50.0, 50.0, 50.0, 50.0, 50.0, 50.0, 50.0, 50.0, 50.0, 50.0, 50.0, 50.0, 50.0, 50.0, 50.0],
			"width": 27.0, "clear": 12.0, "material": "concrete", "base": "water", "tier": 2, "conf": 1,
			"src": "ko Wikipedia (1410 m, 27 m, truss-type like Seongsu per ko text), OSM api way 25.5 deg; " +
				"structure type and equal spans assumed (girder) | verified: ko Wikipedia infobox re-read (no " +
				"span layout listed); no independent span table found (Seoul/namu pages blocked or silent); " +
				"OSM re-measure not repeated (rate-limited); ko infobox: Gerber truss (not a plain girder), " +
				"1410 m, 27 m | round 2: round 2 (w_east_asia): Korean web searches (Seoul safety pages " +
				"news.seoul.go.kr/safe, mediahub.seoul.go.kr, Korea archives Han River bridges, seoul.co.kr " +
				"1994/1997 articles) for a Han River bridge table with span layouts found only opening years, " +
				"total lengths and widths; no span list for Seongsan. Seongsu article gives 19.4 m width at " +
				"1,162 m for the 1979 bridge (pre-1997 rebuild)."},
		{"id": "br_seoul_yanghwa_bridge", "cc": "KR", "name": "Yanghwa Bridge", "wiki": "Yanghwa Bridge",
			"aliases": ["yanghwa daegyo"], "lat": 37.5427, "lon": 126.9039, "bearing": 39.6, "st": "girder",
			"spans": [50.0, 50.0, 50.0, 50.0, 50.0, 50.0, 50.0, 50.0, 50.0, 50.0, 50.0, 50.0, 50.0, 50.0, 50.0, 50.0, 50.0, 50.0, 50.0, 50.0],
			"width": 34.0, "clear": 11.0, "material": "concrete", "base": "water", "tier": 2, "conf": 1,
			"src": "en+ko Wikipedia (1053 m; old 18 m + new 16.1 m decks side by side), OSM api way 39.6 deg; " +
				"equal spans assumed | verified: ko Wikipedia infobox re-read (no span layout listed); no " +
				"independent span table found (Seoul/namu pages blocked or silent); OSM re-measure not " +
				"repeated (rate-limited); ko: upper arch / lower girder, 1053 m, old 18 m + new 16.1 m decks " +
				"| round 2: round 2 (w_east_asia): Korean web searches (Seoul safety pages " +
				"news.seoul.go.kr/safe, mediahub.seoul.go.kr, Korea archives Han River bridges, seoul.co.kr " +
				"1994/1997 articles) for a Han River bridge table with span layouts found only opening years, " +
				"total lengths and widths; no span list for Yanghwa. Seongsu article gives 19.4 m width at " +
				"1,162 m for the 1979 bridge (pre-1997 rebuild)."},
		{"id": "br_seoul_seogang_bridge", "cc": "KR", "name": "Seogang Bridge", "wiki": "Seogang Bridge",
			"aliases": ["seogang daegyo"], "lat": 37.5421, "lon": 126.9283, "bearing": 27.5, "st": "girder",
			"spans": [60.0, 60.0, 60.0, 60.0, 60.0, 60.0, 150.0, 60.0, 60.0, 60.0, 60.0, 60.0, 60.0], "width": 29.0,
			"clear": 12.0, "material": "concrete", "base": "water", "tier": 2, "conf": 1,
			"src": "en+ko Wikipedia (1320 m, 29 m wide, 150 m Nielsen arch over Bamseom, rest concrete box " +
				"girder), OSM api way 27.5 deg; approach spans assumed; Nielsen arch NOT represented (arch " +
				"builder cannot show a single arch among girders) | verified: ko Wikipedia infobox re-read " +
				"(no span layout listed); no independent span table found (Seoul/namu pages blocked or " +
				"silent); OSM re-measure not repeated (rate-limited); ko infobox: steel-plate girder + " +
				"Nielsen arch, main span 150 m, 1320 m, 29 m, deck height 21 m | round 2: round 2 " +
				"(w_east_asia): Korean web searches (Seoul safety pages news.seoul.go.kr/safe, " +
				"mediahub.seoul.go.kr, Korea archives Han River bridges, seoul.co.kr 1994/1997 articles) for " +
				"a Han River bridge table with span layouts found only opening years, total lengths and " +
				"widths; no span list for Seogang. Seongsu article gives 19.4 m width at 1,162 m for the 1979 " +
				"bridge (pre-1997 rebuild)."},
		{"id": "br_seoul_wonhyo_bridge", "cc": "KR", "name": "Wonhyo Bridge", "wiki": "Wonhyo Bridge",
			"aliases": ["wonhyo daegyo"], "lat": 37.5281, "lon": 126.9477, "bearing": 56.2, "st": "girder",
			"spans": [50.0, 50.0, 50.0, 50.0, 50.0, 50.0, 50.0, 50.0, 50.0, 50.0, 50.0, 50.0, 50.0, 50.0, 50.0, 50.0, 50.0, 50.0, 50.0, 50.0, 50.0, 50.0],
			"width": 20.0, "clear": 12.0, "material": "concrete", "base": "water", "tier": 3, "conf": 1,
			"src": "en+ko Wikipedia (1470 m, 20 m wide), OSM api way 56 deg; river crossing ~1100 m, equal spans " +
				"assumed | verified: ko Wikipedia infobox re-read (no span layout listed); no independent " +
				"span table found (Seoul/namu pages blocked or silent); OSM re-measure not repeated (rate- " +
				"limited); ko: 1470 m, 20 m; one source mentions max span 100 m (PC box, free cantilever) but " +
				"no layout | round 2: round 2 (w_east_asia): Korean web searches (Seoul safety pages " +
				"news.seoul.go.kr/safe, mediahub.seoul.go.kr, Korea archives Han River bridges, seoul.co.kr " +
				"1994/1997 articles) for a Han River bridge table with span layouts found only opening years, " +
				"total lengths and widths; no span list for Wonhyo. Seongsu article gives 19.4 m width at " +
				"1,162 m for the 1979 bridge (pre-1997 rebuild)."},
		{"id": "br_seoul_dongjak_bridge", "cc": "KR", "name": "Dongjak Bridge", "wiki": "Dongjak Bridge",
			"aliases": ["dongjak daegyo"], "lat": 37.5108, "lon": 126.9819, "bearing": 8.7, "st": "arch_tied",
			"spans": [110.0, 110.0, 110.0, 110.0, 110.0, 110.0, 110.0, 110.0, 110.0], "width": 40.0, "clear": 12.0,
			"rise": 15.0, "material": "steel", "base": "water", "tier": 2, "conf": 1,
			"src": "en+ko Wikipedia (1330 m, 28.6 m road + 11.4 m rail, designed as Langer arch, Line 4 in " +
				"centre), OSM api way 8.7 deg (arch); span count, rise and arch type assumed | verified: ko " +
				"Wikipedia infobox re-read (no span layout listed); no independent span table found " +
				"(Seoul/namu pages blocked or silent); OSM re-measure not repeated (rate-limited); ko: rail " +
				"deck Langer arch plate girder, road deck girder/slab, 1330 m, 28.6 m road + 11.4 m rail; " +
				"arch count unknown | round 2: round 2 (w_east_asia): Korean web searches (Seoul safety pages " +
				"news.seoul.go.kr/safe, mediahub.seoul.go.kr, Korea archives Han River bridges, seoul.co.kr " +
				"1994/1997 articles) for a Han River bridge table with span layouts found only opening years, " +
				"total lengths and widths; no span list for Dongjak. Seongsu article gives 19.4 m width at " +
				"1,162 m for the 1979 bridge (pre-1997 rebuild)."},
		{"id": "br_seoul_hannam_bridge", "cc": "KR", "name": "Hannam Bridge", "wiki": "Hannam Bridge",
			"aliases": ["hannam daegyo"], "lat": 37.527, "lon": 127.0132, "bearing": 143.0, "st": "girder",
			"spans": [50.0, 50.0, 50.0, 50.0, 50.0, 50.0, 50.0, 50.0, 50.0, 50.0, 50.0, 50.0, 50.0, 50.0, 50.0, 50.0, 50.0, 50.0],
			"width": 51.2, "clear": 12.0, "material": "concrete", "base": "water", "tier": 2, "conf": 1,
			"src": "en+ko Wikipedia (919 m, 51.2 m / 12 lanes in two parallel decks), OSM api way 143 deg; equal " +
				"spans assumed | verified: ko Wikipedia infobox re-read (no span layout listed); no " +
				"independent span table found (Seoul/namu pages blocked or silent); OSM re-measure not " +
				"repeated (rate-limited); ko: 919 m, 51.2 m; original upstream bridge 3-span continuous plate " +
				"girders on 27 piers, 2001 downstream box girder | round 2: round 2 (w_east_asia): Korean web " +
				"searches (Seoul safety pages news.seoul.go.kr/safe, mediahub.seoul.go.kr, Korea archives Han " +
				"River bridges, seoul.co.kr 1994/1997 articles) for a Han River bridge table with span " +
				"layouts found only opening years, total lengths and widths; no span list for Hannam. Seongsu " +
				"article gives 19.4 m width at 1,162 m for the 1979 bridge (pre-1997 rebuild)."},
		{"id": "br_seoul_dongho_bridge", "cc": "KR", "name": "Dongho Bridge", "wiki": "Dongho Bridge",
			"aliases": ["dongho daegyo"], "lat": 37.5338, "lon": 127.0228, "bearing": 150.8, "st": "truss",
			"spans": [100.0, 100.0, 100.0, 100.0, 100.0, 100.0, 100.0, 100.0, 100.0, 100.0], "width": 35.0,
			"clear": 12.0, "rise": 10.0, "material": "steel", "base": "water", "tier": 3, "conf": 1,
			"src": "ko Wikipedia (1095 m, 35 m with 11 m rail in centre), OSM api way 150.8 deg (truss); span " +
				"count and truss height assumed | verified: ko Wikipedia infobox re-read (no span layout " +
				"listed); no independent span table found (Seoul/namu pages blocked or silent); OSM re- " +
				"measure not repeated (rate-limited); ko infobox: 1095 m, 35 m | round 2: round 2 " +
				"(w_east_asia): Korean web searches (Seoul safety pages news.seoul.go.kr/safe, " +
				"mediahub.seoul.go.kr, Korea archives Han River bridges, seoul.co.kr 1994/1997 articles) for " +
				"a Han River bridge table with span layouts found only opening years, total lengths and " +
				"widths; no span list for Dongho. Seongsu article gives 19.4 m width at 1,162 m for the 1979 " +
				"bridge (pre-1997 rebuild)."},
		{"id": "br_seoul_seongsu_bridge", "cc": "KR", "name": "Seongsu Bridge", "wiki": "Seongsu Bridge",
			"aliases": ["seongsu daegyo"], "lat": 37.5365, "lon": 127.035, "bearing": 7.3, "st": "truss",
			"spans": [120.0, 120.0, 120.0, 120.0, 120.0, 120.0, 120.0], "width": 35.0, "clear": 12.0, "rise": 10.0,
			"material": "steel", "base": "water", "tier": 2, "conf": 1,
			"src": "ko Wikipedia (1161 m, 35 m, Gerber truss with 120 m long spans, rebuilt 1997), OSM api way 7 " +
				"deg (truss); span count and truss height assumed | verified: ko Wikipedia infobox re-read " +
				"(no span layout listed); no independent span table found (Seoul/namu pages blocked or " +
				"silent); OSM re-measure not repeated (rate-limited); ko: rebuilt 1997 Gerber truss, 1161 m, " +
				"120 m units = 36 m anchor trusses + 48 m suspended truss; number of units unknown | round 2: " +
				"round 2 (w_east_asia): Korean web searches (Seoul safety pages news.seoul.go.kr/safe, " +
				"mediahub.seoul.go.kr, Korea archives Han River bridges, seoul.co.kr 1994/1997 articles) for " +
				"a Han River bridge table with span layouts found only opening years, total lengths and " +
				"widths; no span list for Seongsu. Seongsu article gives 19.4 m width at 1,162 m for the 1979 " +
				"bridge (pre-1997 rebuild)."},
		{"id": "br_seoul_yeongdong_bridge", "cc": "KR", "name": "Yeongdong Bridge", "wiki": "Yeongdong Bridge",
			"aliases": ["yeongdong daegyo"], "lat": 37.5283, "lon": 127.0562, "bearing": 23.9, "st": "girder",
			"spans": [50.0, 50.0, 50.0, 50.0, 50.0, 50.0, 50.0, 50.0, 50.0, 50.0, 50.0, 50.0, 50.0, 50.0, 50.0, 50.0, 50.0, 50.0, 50.0],
			"width": 25.0, "clear": 12.0, "material": "concrete", "base": "water", "tier": 3, "conf": 1,
			"src": "en+ko Wikipedia (1065 m, 25 m), OSM api way 24 deg; equal spans assumed | verified: ko " +
				"Wikipedia infobox re-read (no span layout listed); no independent span table found " +
				"(Seoul/namu pages blocked or silent); OSM re-measure not repeated (rate-limited); ko: 1065 " +
				"m, 25 m | round 2: round 2 (w_east_asia): Korean web searches (Seoul safety pages " +
				"news.seoul.go.kr/safe, mediahub.seoul.go.kr, Korea archives Han River bridges, seoul.co.kr " +
				"1994/1997 articles) for a Han River bridge table with span layouts found only opening years, " +
				"total lengths and widths; no span list for Yeongdong. Seongsu article gives 19.4 m width at " +
				"1,162 m for the 1979 bridge (pre-1997 rebuild)."},
		{"id": "br_seoul_cheongdam_bridge", "cc": "KR", "name": "Cheongdam Bridge", "wiki": "Cheongdam Bridge",
			"aliases": ["cheongdam daegyo"], "lat": 37.5269, "lon": 127.0646, "bearing": 13.6, "st": "girder",
			"spans": [100.0, 100.0, 100.0, 100.0, 100.0, 100.0, 100.0, 100.0, 100.0, 100.0], "width": 27.0,
			"clear": 13.0, "material": "concrete", "base": "water", "tier": 2, "conf": 1,
			"src": "en+ko Wikipedia (1211 m steel box girder, 27 m, subway on the underside), OSM api way 13.6 " +
				"deg; equal spans assumed | verified: ko Wikipedia infobox re-read (no span layout listed); " +
				"no independent span table found (Seoul/namu pages blocked or silent); OSM re-measure not " +
				"repeated (rate-limited); ko: 1211 m steel box girder, 27 m | round 2: round 2 (w_east_asia): " +
				"Korean web searches (Seoul safety pages news.seoul.go.kr/safe, mediahub.seoul.go.kr, Korea " +
				"archives Han River bridges, seoul.co.kr 1994/1997 articles) for a Han River bridge table " +
				"with span layouts found only opening years, total lengths and widths; no span list for " +
				"Cheongdam. Seongsu article gives 19.4 m width at 1,162 m for the 1979 bridge (pre-1997 " +
				"rebuild)."},
		{"id": "br_seoul_jamsil_bridge", "cc": "KR", "name": "Jamsil Bridge", "wiki": "Jamsil Bridge",
			"aliases": ["jamsil daegyo"], "lat": 37.5238, "lon": 127.0921, "bearing": 148.8, "st": "girder",
			"spans": [50.0, 50.0, 50.0, 50.0, 50.0, 50.0, 50.0, 50.0, 50.0, 50.0, 50.0, 50.0, 50.0, 50.0, 50.0, 50.0, 50.0, 50.0, 50.0, 50.0],
			"width": 25.0, "clear": 12.0, "material": "concrete", "base": "water", "tier": 3, "conf": 1,
			"src": "ko Wikipedia (1280 m, 25 m), OSM api way 149 deg; equal spans assumed | verified: ko " +
				"Wikipedia infobox re-read (no span layout listed); no independent span table found " +
				"(Seoul/namu pages blocked or silent); OSM re-measure not repeated (rate-limited); ko: 1280 " +
				"m, 25 m | round 2: round 2 (w_east_asia): Korean web searches (Seoul safety pages " +
				"news.seoul.go.kr/safe, mediahub.seoul.go.kr, Korea archives Han River bridges, seoul.co.kr " +
				"1994/1997 articles) for a Han River bridge table with span layouts found only opening years, " +
				"total lengths and widths; no span list for Jamsil. Seongsu article gives 19.4 m width at " +
				"1,162 m for the 1979 bridge (pre-1997 rebuild)."},
		{"id": "br_seoul_olympic_bridge", "cc": "KR", "name": "Olympic Bridge", "wiki": "Olympic Bridge",
			"aliases": ["올림픽대교", "olympic daegyo"], "lat": 37.5364, "lon": 127.1013, "bearing": 139.9, "st": "girder",
			"spans": [50.0, 50.0, 50.0, 50.0, 50.0, 50.0, 50.0, 50.0, 50.0, 50.0, 50.0, 50.0, 50.0, 50.0, 50.0, 50.0, 50.0, 50.0, 50.0, 50.0],
			"width": 32.0, "clear": 12.0, "material": "concrete", "base": "water", "tier": 3, "conf": 1,
			"src": "ko Wikipedia (1225 m, 32 m, four central pylons mentioned but structure not confirmed), OSM " +
				"api way 140 deg; modelled as girder, equal spans assumed | verified: ko Wikipedia infobox " +
				"re-read (no span layout listed); no independent span table found (Seoul/namu pages blocked " +
				"or silent); OSM re-measure not repeated (rate-limited); ko: 1225 m, 32 m, structure not " +
				"confirmed | round 2: round 2 (w_east_asia): Korean web searches (Seoul safety pages " +
				"news.seoul.go.kr/safe, mediahub.seoul.go.kr, Korea archives Han River bridges, seoul.co.kr " +
				"1994/1997 articles) for a Han River bridge table with span layouts found only opening years, " +
				"total lengths and widths; no span list for Olympic. Seongsu article gives 19.4 m width at " +
				"1,162 m for the 1979 bridge (pre-1997 rebuild)."},
		{"id": "br_seoul_gayang_bridge", "cc": "KR", "name": "Gayang Bridge", "wiki": "Gayang Bridge",
			"aliases": ["gayang daegyo"], "lat": 37.5697, "lon": 126.8614, "bearing": 31.0, "st": "girder",
			"spans": [110.0, 130.0, 150.0, 180.0, 150.0, 130.0, 110.0], "width": 29.0, "clear": 12.0,
			"material": "concrete", "base": "water", "tier": 3, "conf": 1,
			"src": "ko Wikipedia (1700 m, pier spacing 100-180 m, 16-29 m wide), OSM api way 31 deg; individual " +
				"spans assumed within the stated range | verified: ko Wikipedia infobox re-read (no span " +
				"layout listed); no independent span table found (Seoul/namu pages blocked or silent); OSM " +
				"re-measure not repeated (rate-limited); ko infobox: main span 100-180 m, 1700 m | round 2: " +
				"round 2 (w_east_asia): Korean web searches (Seoul safety pages news.seoul.go.kr/safe, " +
				"mediahub.seoul.go.kr, Korea archives Han River bridges, seoul.co.kr 1994/1997 articles) for " +
				"a Han River bridge table with span layouts found only opening years, total lengths and " +
				"widths; no span list for Gayang. Seongsu article gives 19.4 m width at 1,162 m for the 1979 " +
				"bridge (pre-1997 rebuild)."},
		{"id": "br_tokyo_ryogoku_bridge", "cc": "JP", "name": "Ryogoku Bridge", "wiki": "Ryōgoku Bridge",
			"aliases": ["ryogokubashi"], "lat": 35.6943, "lon": 139.7888, "bearing": 102.0, "st": "girder",
			"spans": [45.5, 73.5, 45.5], "width": 24.0, "clear": 7.0, "material": "steel", "base": "sea", "tier": 2,
			"conf": 1,
			"src": "ja Wikipedia (1932 bridge, 3-span Gerber steel plate girder, 164.5 m, 24.5 m wide), OSM api " +
				"ways (axis 101-102 deg, 170 m); span split assumed; clear estimated | verified: ja Wikipedia " +
				"infobox + Wikidata P2043 + asahi-net table: 3-span Gerber steel plate girder 164.5 m, width " +
				"24.0 m (first pass 24.5); span split not found; OSM re-measure rate-limited (429) | round 2: " +
				"round 2 (w_east_asia): Nihon Univ. inspection paper " +
				"(cit.nihon-u.ac.jp/kouendata/No.43/3_doboku/3-001.pdf): 'span' 164.5 m, cantilever (Gerber) " +
				"plate girder, 1932 (total length only); ja Wikipedia 3-span Gerber, 164.5 x 24.0 m; not in " +
				"JSCE A5 historic-steel list; Japanese searches found no 45.5+73.5+45.5 split. Span layout " +
				"still unverified."},
		{"id": "br_tokyo_azuma_bridge", "cc": "JP", "name": "Azuma Bridge", "wiki": "Azuma Bridge",
			"aliases": ["azumabashi"], "lat": 35.71011, "lon": 139.79893, "bearing": 125.0, "st": "arch_deck",
			"spans": [8.42, 38.405, 44.858, 38.405, 8.42], "width": 20.0, "clear": 7.0, "rise": 5.0,
			"material": "steel", "base": "sea", "tier": 3, "conf": 2, "arch_spans": [1, 2, 3],
			"src": "ja Wikipedia (1931 bridge, ~150 m, 20.0 m wide), OSM api way (humpback, axis 126 deg, 152 " +
				"m); 3 equal arch spans, rise and clear assumed | verified: MLIT Kanto sheet: 2-hinge steel " +
				"arch in 3 spans (asahi-net table calls it a tied arch; a second source says upper-deck " +
				"2-hinge arch); ja Wikipedia/asahi-net 150 m x 20 m; OSM way 54680197 (152 m, 125.0 deg " +
				"reverse of 305.0, mid 35.71011,139.79893); span split and rise not found | round 2: round 2 " +
				"(w_east_asia): JSCE historic steel bridges A5-028 " +
				"(library.jsce.or.jp/jscelib/committee/2003/bridge/A5-028.htm): upper-deck 2-hinge arch, RC " +
				"box-frame approaches, spans 8.420+38.405+44.858+38.405+8.420 m, 150.114 x 20.0 m; Tokyo " +
				"Metropolitan Bureau of Construction Sumida lighting leaflet " +
				"(kensetsu.metro.tokyo.lg.jp/content/000048924.pdf): steel solid-rib 2-hinge arch x3, 150.1 " +
				"m, width 23.4 m (current overall incl. footways; JSCE/ja Wikipedia 20.0 m used); MLIT Kanto " +
				"sheet also 3 two-hinge arches; OSM way 54680197 re-measured: 151.8 m, 305.05 deg (125.05 " +
				"reverse), mid 35.71011,139.79893; rise 5 m and clear 7 m estimated (arch rise/span ~1/9)"},
		{"id": "br_hong_kong_stonecutters_bridge", "cc": "HK", "name": "Stonecutters Bridge", "wiki": "Stonecutters Bridge",
			"aliases": ["昂船洲大橋", "ngong shuen chau bridge"], "lat": 22.3262, "lon": 114.118, "bearing": 129.7,
			"st": "stayed", "spans": [69.25, 70.0, 70.0, 79.75, 1018.0, 79.75, 70.0, 70.0, 69.25], "width": 53.3,
			"clear": 77.0, "tower": 298.0, "towers": [4, 5], "pylon": "single", "material": "steel", "base": "sea",
			"tier": 1, "conf": 2,
			"src": "en Wikipedia infobox (main 1018 m, 1596 m, 53.3 m wide, clearance below 73.5 m, towers 293.5 " +
				"m, two single-mast towers), OSM api ways (axis 129.7 deg, motorway carriageways); side spans " +
				"(1596-1018)/2 incl. approach piers; road surface ~76 m estimated | verified: Falbe-Hansen et " +
				"al. (AFGC 2004 paper, afgc.asso.fr 065): total 1596 m, main 1018 m, four back spans each " +
				"side 79.75+70+70+69.25 m, twin-box deck, tower concrete to +175 m then steel to +293 m plus " +
				"5 m glass top (~298 m; Wikidata P2048 298, zh Wikipedia 298); clearance 73.5 m (zh " +
				"Wikipedia, FX design); deck width 53.3 m (en Wikipedia, Wikidata lists 26 m per box); " +
				"Wikidata centre 22.32611,114.11833 matches row; OSM ways 151705898/9 (129.8/309.9 deg) are " +
				"truncated 1.2 km pieces, midpoint offset only along the axis"},
		{"id": "br_hong_kong_tsing_tsuen_bridge", "cc": "HK", "name": "Tsing Yi North Bridge", "wiki": "Tsing Yi North Bridge",
			"aliases": ["tsing tsuen bridge"], "lat": 22.36, "lon": 114.11, "bearing": 79.0, "st": "girder",
			"spans": [70.0, 110.0, 160.0, 110.0, 70.0], "width": 14.6, "clear": 20.0, "material": "concrete",
			"base": "sea", "tier": 3, "conf": 1,
			"src": "en Wikipedia (1015 m incl. approaches, main span 160 m), OSM api way (Tsing Tsuen Bridge, " +
				"axis 79 deg); side spans, width and clear assumed; material assumed | verified: zh Wikipedia " +
				"青荃橋 (aka Tsing Yi North Bridge; ICE 1989 Denton-Cox & Weir): main span 160 m, 1.015 km (or " +
				"1.5 km) long, deck 14.6 m wide, 17 m navigation clearance, ~300 m over the sea; span split " +
				"unsourced; OSM fetch failed (429) | round 2: round 2 (w_east_asia): zh Wikipedia 青荃橋 re- " +
				"read: main span 160 m (ICE), 14.6 m wide (7.3 m per direction, HK Daily News 1983), 17 m " +
				"navigation clearance (Marine Dept), 1.5 km overall of which ~300 m is over sea; no side-span " +
				"layout in any source, so [70,110,160,110,70] remains a guess."},
		{"id": "br_macau_sai_van_bridge", "cc": "MO", "name": "Sai Van Bridge", "wiki": "Sai Van Bridge",
			"aliases": ["ponte de sai van"], "lat": 22.1722, "lon": 113.5361, "bearing": 155.0, "st": "stayed",
			"spans": [100.0, 180.0, 100.0], "width": 28.0, "clear": 32.0, "tower": 110.0, "material": "concrete",
			"base": "sea", "tier": 2, "conf": 1,
			"src": "en Wikipedia (cable-stayed, main span 180 m, 2200 m total, 28 m wide, double-deck), OSM api " +
				"ways (axis 155 deg); side spans, tower height and clear assumed; pylon layout unverified | " +
				"verified: en + zh Wikipedia agree: 2200 m total (700 + 400 m approaches), main span 180 m, " +
				"28 m wide, double-deck harp stayed with two single-leg pylons; side-span layout of the " +
				"stayed section not found; OSM way 46510094 (155.2 deg, mid 22.17129,113.53678) agrees with " +
				"row within ~100 m | round 2: round 2 (w_east_asia): zh Wikipedia 西灣大橋 re-read: 2,200 m, 28 m " +
				"wide, 700 m + 400 m approaches, main span 180 m, harp stays, two 85 m twin-arch ('M') pylons " +
				"(the row's 110 m tower above water is therefore unconfirmed; 85 m may be above the deck); " +
				"side-span layout not stated anywhere."},
		{"id": "br_macau_nobre_de_carvalho_bridge", "cc": "MO", "name": "Governor Nobre de Carvalho Bridge", "wiki": "Governor Nobre de Carvalho Bridge",
			"aliases": ["macau-taipa bridge", "ponte governador nobre de carvalho"], "lat": 22.17601, "lon": 113.54631,
			"bearing": 168.3, "st": "girder",
			"spans": [73.8, 73.8, 73.8, 73.8, 73.8, 73.8, 73.8, 73.8, 73.8, 73.8, 73.8, 73.8, 73.8, 73.8, 73.8, 73.8, 73.8, 73.8, 73.8, 73.8, 73.8, 73.8, 73.8, 73.8, 73.8, 73.8, 73.8, 73.8, 73.8, 73.8, 73.8, 73.8, 73.8],
			"width": 9.2, "clear": 12.0, "material": "concrete", "base": "sea", "tier": 3, "conf": 1,
			"src": "en Wikipedia (girder, main span 73 m, 2436 m, 9.2 m wide), Wikipedia coordinate only " +
				"(Overpass/OSM api rate-limited); bearing ~130 deg estimated from the peninsula-Taipa line; " +
				"equal spans from main span, clear estimated | verified: OSM way 22988070 (2445 m, chord " +
				"bearing 348.3 deg i.e. 168.3 Macau->Taipa, mid 22.17601,113.54631); zh Wikipedia history " +
				"only; spans still an equal split | round 2: round 2 (w_east_asia): no new span source beyond " +
				"first pass and round 1 (equal 73.8 m split from 2436 m / main span 73 m); not re-searched."},
		{"id": "br_taipei_taipei_bridge", "cc": "TW", "name": "Taipei Bridge", "wiki": "Taipei Bridge",
			"aliases": ["taipei main bridge"], "lat": 25.0637, "lon": 121.5062, "bearing": 99.0, "st": "girder",
			"spans": [60.2, 60.2, 60.2, 60.2, 60.2, 60.2, 60.2, 60.2], "width": 44.0, "clear": 9.0,
			"material": "concrete", "base": "water", "tier": 2, "conf": 1,
			"src": "zh Wikipedia infobox (481.6 m, main span 62.3 m, 44 m wide, 1996 bridge; en infobox gives " +
				"16.8 m), OSM api ways (axis 97-101 deg); 8 equal spans from length/main span; clear " +
				"estimated | verified: zh Wikipedia 臺北大橋 infobox: 481.6 m long, main span 62.3 m, 44 m wide; " +
				"481.6/8 = 60.2 m is below the 62.3 m main span so the spans are not equal; OSM ways " +
				"50893540/311576788 (370 m, mid 25.0638,121.5047-ish) agree with row centre | round 2: round " +
				"2 (w_east_asia): zh Wikipedia 臺北大橋 re-read: 481.6 m, 44 m wide, 1996 bridge; searches for " +
				"the 1996 main bridge span layout (steel girder per en infobox, 16.8 m width there is a " +
				"different figure) returned nothing; spans cannot be equal (main span 62.3 m > 481.6/8)."},
		{"id": "br_taipei_zhongxiao_bridge", "cc": "TW", "name": "Zhongxiao Bridge", "wiki": "Zhongxiao Bridge",
			"aliases": ["chung-hsiao bridge"], "lat": 25.0518, "lon": 121.501, "bearing": 121.0, "st": "girder",
			"spans": [74.1, 74.1, 74.1, 74.1, 74.1, 74.1, 74.1], "width": 31.5, "clear": 10.0, "material": "concrete",
			"base": "water", "tier": 2, "conf": 2,
			"src": "zh Wikipedia (main bridge 519 m, main span 74.5 m, 31.5 m wide, prestressed concrete Lin-T " +
				"girders, Y piers), OSM api way (axis 120.5-121.6 deg); 7 equal spans; clear estimated | " +
				"verified: zh Wikipedia 忠孝橋 (cites Liao Yaoyu, Technologist journal 61): main bridge 519 m, " +
				"main span 74.5 m, 31.5 m wide, prestressed Lin-T girders with Y-shaped piers on identical " +
				"bays; 519/74.5 = 6.97 so 7 near-equal spans (spread < 2.5 m); OSM re-measure rate-limited, " +
				"first-pass OSM axis 120.5-121.6 kept"},
		{"id": "br_taipei_huazhong_bridge", "cc": "TW", "name": "Huazhong Bridge", "wiki": "Huazhong Bridge",
			"aliases": ["hua-chung bridge"], "lat": 25.0105, "lon": 121.4957, "bearing": 1.0, "st": "girder",
			"spans": [42.1, 42.1, 42.1, 42.1, 42.1, 42.1, 42.1, 42.1, 42.1, 42.1, 42.1, 42.1, 42.1, 42.1, 42.1, 42.1, 42.1, 42.1, 42.1, 42.1, 42.1, 42.1, 42.1, 42.1, 42.1, 42.1, 42.1, 42.1, 42.1, 42.1],
			"width": 24.5, "clear": 8.0, "material": "concrete", "base": "water", "tier": 3, "conf": 1,
			"src": "zh Wikipedia (main bridge 30 spans 1263 m, mainspan 48 m, 24.5 m wide, 1600 m with " +
				"approaches), OSM api way (axis 0.8-2.1 deg); centre set between OSM way centroid and " +
				"Wikipedia coordinate (200 m apart); equal spans; clear estimated | verified: zh Wikipedia " +
				"華中橋: main bridge 30 spans 29 piers 1263 m, main span 48 m, 24.5 m wide; 1263/30 = 42.1 m is " +
				"below the 48 m main span so spans are not equal; OSM ways 111812463/696115806 (1.4 km, mid " +
				"25.0120,121.4963) are longer than the main bridge | round 2: round 2 (w_east_asia): zh " +
				"Wikipedia 華中橋 re-read: main bridge 30 spans / 29 solid-wall piers, 1263 m, 24.5 m wide, 1600 " +
				"m with approaches; a Chinese search for the span layout returned nothing about this bridge; " +
				"main span 48 m vs mean 42.1 m so spans are not equal."},
		{"id": "br_taipei_huajiang_bridge", "cc": "TW", "name": "Huajiang Bridge", "wiki": "Huajiang Bridge",
			"aliases": ["hua-chiang bridge"], "lat": 25.0357, "lon": 121.4862, "bearing": 91.5, "st": "girder",
			"spans": [60.0, 60.0, 60.0, 60.0, 60.0, 60.0, 60.0, 60.0, 60.0], "width": 32.5, "clear": 10.0,
			"material": "steel", "base": "water", "tier": 3, "conf": 2,
			"src": "zh Wikipedia (1996 main bridge 9 spans 540 m, max span 60 m, 32.5 m wide, 3-span continuous " +
				"steel box girders), OSM api way (axis 91.3 deg); centre between OSM way centroid and " +
				"Wikipedia coordinate; equal spans; clear estimated | verified: zh Wikipedia 華江橋 (cites Liao " +
				"Yaoyu 2012): main bridge 9 spans on 10 piers, 540 m, max span 60 m (9 x 60 = 540 forces " +
				"equal spans), 32.5 m wide, 3-span continuous steel-deck box girders; the infobox 960 m/90 m " +
				"figures include approaches; OSM re-measure rate-limited, first-pass OSM axis 91.3 deg kept"},
		{"id": "br_pyongyang_okryu_bridge", "cc": "KP", "name": "Okryu Bridge", "wiki": "Ongryu Bridge",
			"aliases": ["ongryu bridge", "ongnyu bridge"], "lat": 39.0251, "lon": 125.7615, "bearing": 102.4,
			"st": "girder", "spans": [55.0, 55.0, 55.0, 55.0, 55.0, 55.0, 55.0, 55.0, 55.0, 55.0, 55.0, 55.0, 55.0],
			"width": 28.5, "clear": 9.0, "material": "concrete", "base": "water", "tier": 3, "conf": 1,
			"src": "ko Wikipedia (700 m, 28.5 m, 1960), OSM bundled snapshot/api way (axis 102.4 deg, 715 m); " +
				"equal spans, clear and material assumed | verified: Not independently re-checked: no span or " +
				"deck data found beyond ko Wikipedia 700 m / 28.5 m; relies on first-pass OSM axis 102.4 deg " +
				"| round 2: round 2 (w_east_asia): not re-checked beyond round 1: no accessible non-Russian " +
				"source with spans or deck data for Okryu Bridge."},
		{"id": "br_pyongyang_rungra_bridge", "cc": "KP", "name": "Rungra Bridge", "wiki": "Rungra Bridge",
			"aliases": ["rungna bridge", "ryongna bridge"], "lat": 39.0339, "lon": 125.765, "bearing": 100.4,
			"st": "girder",
			"spans": [50.0, 50.0, 50.0, 50.0, 50.0, 50.0, 50.0, 50.0, 50.0, 50.0, 50.0, 50.0, 50.0, 50.0, 50.0, 50.0, 50.0, 50.0],
			"width": 28.0, "clear": 9.0, "material": "concrete", "base": "water", "tier": 3, "conf": 1,
			"src": "ko Wikipedia (1070 m, 1988, 4 lanes), bundled OSM snapshot way (axis 100.4 deg, 900 m incl. " +
				"Rungra Island section); width, equal spans, clear and material assumed | verified: Not " +
				"independently re-checked: no span or deck data found beyond ko Wikipedia 1070 m; relies on " +
				"first-pass OSM axis 100.4 deg | round 2: round 2 (w_east_asia): not re-checked beyond round " +
				"1: no accessible non-Russian source with spans or deck data for Rungra Bridge."},
	]
