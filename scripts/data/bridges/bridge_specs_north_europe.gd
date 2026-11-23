class_name BridgeSpecsNorthEurope
extends RefCounted

## Capital bridge rows for Northern Europe (see BridgeSpec for the schema). Figures are
## sourced per row in `src`; conf 1 rows are kept as data but not built
## (BridgeSpec.MIN_BUILT_CONF).

static func rows() -> Array:
	return [
		{"id": "br_stockholm_centralbron", "cc": "SE", "name": "Centralbron", "wiki": "Centralbron",
			"aliases": ["central bridge stockholm"], "lat": 59.32182, "lon": 18.06771, "bearing": 162.4, "st": "girder",
			"spans": [28.1, 33.7, 31.7, 31.7, 33.7, 30.1], "width": 21.8, "clear": 10.0, "material": "steel",
			"base": "water", "tier": 2, "conf": 2,
			"src": "sv+en Wikipedia (Soderstrom crossing 189 m, six continuous steel-girder spans on concrete " +
				"piers, max span 33.7 m, 21.8 m wide); S-4 OSM re-measure (overpass.openstreetmap.fr): " +
				"man_made=bridge polygon way 653647513 is 184.4 x 26.9 m at bearing 162.4, area centroid " +
				"59.32182,18.06771, with deck ways 5788351 / 261818767 across Soderstrom; the earlier centre " +
				"59.3235,18.0665 and bearing 333.5 were the 457 m viaduct way 23000196 beside Riddarholmen, not " +
				"this crossing; OSM bridge:structure beam; spans other than the 33.7 m maximum split by " +
				"estimate (no source lists them), sum 189.0 vs OSM 184.4 (2.5%); clear estimated"},
		{"id": "br_stockholm_tranebergsbron", "cc": "SE", "name": "Tranebergsbron", "wiki": "Tranebergsbron",
			"aliases": ["traneberg bridge"], "lat": 59.33346, "lon": 17.99512, "bearing": 274.5, "st": "arch_deck",
			"spans": [181.0], "width": 27.0, "clear": 28.0, "rise": 25.0, "material": "concrete", "base": "water",
			"tier": 2, "conf": 2,
			"src": "en+sv Wikipedia (concrete arch span 181 m, 27 m wide, 32 m high, 25.2 m sail clearance, " +
				"450-580 m with viaducts), OSM way 5178978 (bearing 274.5, centre) agrees with Wikipedia " +
				"59.33361,17.995; only the main arch modelled, 2002 third parallel bridge not included in " +
				"width; deck height and arch rise estimated | verified: en+sv Wikipedia: 181 m concrete arch, " +
				"27 m wide (27.4 m for the two 1934 arches), sail clearance 25.2-26 m under the crown, '32 m " +
				"high' overall; OSM way 5178978 (453 m, bearing 274.5, mid 59.33346,17.99512) with shoreline " +
				"crossings at 130 m and 328 m of the way, i.e. water 198 m centred exactly on the way " +
				"midpoint; crown carries the deck so clear 28 (25.2 m clearance + arch thickness) and arch " +
				"rise about 25 m"},
		{"id": "br_stockholm_skeppsholmsbron", "cc": "SE", "name": "Skeppsholmsbron", "wiki": "Skeppsholmsbron",
			"aliases": ["skeppsholm bridge"], "lat": 59.32732, "lon": 18.07913, "bearing": 139.7, "st": "arch_deck",
			"spans": [33.0, 33.0, 33.0, 33.0, 33.0], "width": 9.5, "clear": 4.5, "rise": 2.5, "material": "iron",
			"base": "sea", "tier": 2, "conf": 2, "orn": 3.6, "steel_hex": "#4A4F5A", "concrete_hex": "#7A746C",
			"src": "sv+en Wikipedia (1861 forged-iron bridge by Motala Verkstad, five bays, 165 m, 9.5 m wide: " +
				"5.5 m roadway + 2 x 2 m footways; gilded royal crowns on the railing at the midpoint); OSM " +
				"(overpass.openstreetmap.fr) polygon way 660513753 172.8 x 10.3 m at bearing 139.8, roadway " +
				"way 4741923 172.3 m bearing 139.5 width=5, centre 59.32732,18.07913; spans equal by estimate " +
				"(sum 165 vs OSM 172.3, 4.2%), rise and clear estimated | S-4 photo check (visual-plan/refs/" +
				"landmarks/skeppsholmsbron): dark blue-grey shallow arched plate girder on five granite-faced " +
				"piers with cutwaters, cross-lattice railings, slim lamp standards on the east side, and a " +
				"gilded royal crown on each railing at the midpoint (built by StoBridgeSkeppsholm)"},
		{"id": "br_stockholm_danviksbron", "cc": "SE", "name": "Danviksbron", "wiki": "Danviksbro",
			"aliases": ["danvik bridge", "danviksbro"], "lat": 59.31362, "lon": 18.10476, "bearing": 118.9,
			"st": "bascule", "spans": [25.0, 37.0, 28.0], "width": 38.0, "clear": 4.5, "material": "steel",
			"base": "water", "tier": 3, "conf": 2,
			"src": "sv Wikipedia (two single-leaf bascules side by side, 1 m apart: 1922 Saltsjobanan/street leaf " +
				"14-15 m wide, 37 m long, and the 1956 road leaf 22 m wide; rebuilt north leaf due autumn " +
				"2026), OSM (overpass.openstreetmap.fr) polygon way 1164920061 91.7 x 38.3 m at bearing " +
				"118.4 and ways 16744539 (90 m, bearing 118.9) / 39236686 / 203474482: width 38 m is both " +
				"leaves (22 + 1 + 15) and agrees with the polygon; the 37 m leaf is the sourced span, the side " +
				"spans split the remaining 53 m of the 90 m way by estimate (sum 90.0 vs OSM 91.7, 1.9%); deck " +
				"height estimated, the concrete counterweight is not modelled"},
		{"id": "br_stockholm_djurgardsbron", "cc": "SE", "name": "Djurgardsbron", "wiki": "Djurgårdsbron",
			"aliases": ["djurgårdsbron", "djurgarden bridge"], "lat": 59.33112, "lon": 18.09379, "bearing": 163.9,
			"st": "arch_deck", "spans": [19.3, 19.4, 19.3], "width": 18.0, "clear": 4.5, "rise": 2.0,
			"material": "iron", "base": "sea", "tier": 2, "conf": 2, "orn": 7.2, "steel_hex": "#8F9AA3",
			"concrete_hex": "#8A857C",
			"src": "sv+en Wikipedia (1896-97 three-span iron/steel bridge by Carl Fraenell, architect Erik " +
				"Josephson for the abutments and candelabras, 18 m wide, about 58 m, sail clearance 3.0 m; four " +
				"granite columns carry the Norse gods Heimdall, Frigg (north abutment) and Freyja, Thor (south " +
				"abutment) by Rolf Adlersparre in copper-galvanised zinc; tram rails of Djurgardslinjen), OSM " +
				"(overpass.openstreetmap.fr) polygon way 421206372 63.2 x 19.3 m bearing 163.0, deck way " +
				"23620161 58.5 m bearing 163.8 mid 59.33112,18.09379; equal spans assumed (sum 58.0 vs OSM " +
				"58.5, 0.9%) | S-4 photo check (visual-plan/refs/landmarks/djurgardsbron): three shallow " +
				"segmental arched plate girders in pale blue-grey with Warren web diagonals, two round granite " +
				"drum piers, pierced cast-iron railings, 3-lamp candelabra standards, four tapering granite " +
				"columns with dark zinc gods at the abutment corners (built by StoBridgeDjurgard)"},
		{"id": "br_stockholm_vasabron", "cc": "SE", "name": "Vasabron", "wiki": "Vasabron",
			"aliases": ["vasa bridge stockholm"], "lat": 59.32742, "lon": 18.06413, "bearing": 140.7, "st": "arch_deck",
			"spans": [26.0, 29.5, 32.0, 32.0, 32.0, 29.5, 27.0], "width": 18.0, "clear": 5.0, "rise": 3.2,
			"material": "iron", "base": "water", "tier": 2, "conf": 2,
			"src": "en Wikipedia (1878 cast-iron/steel bridge, seven arches, max span 32 m, 208 m, 18 m wide); " +
				"OSM (overpass.openstreetmap.fr) polygon way 386722951 209.2 x 24.3 m bearing 140.2 (bridge:" +
				"structure arch) and deck way 28345891 207 m bearing 140.7, centre 59.32742,18.06413; only the " +
				"32 m maximum is sourced, the other six spans are split by estimate (sum 208.0 vs OSM 209.2, " +
				"0.6%); clear and rise estimated"},
		{"id": "br_stockholm_essingebron", "cc": "SE", "name": "Essingebron", "wiki": "Essingebron",
			"aliases": ["essinge bridge"], "lat": 59.32339, "lon": 17.99904, "bearing": 40.1, "st": "girder",
			"spans": [56.0, 100.0, 56.0], "width": 30.0, "clear": 19.2, "depth": 4.0, "material": "concrete",
			"base": "water", "tier": 3, "conf": 2,
			"src": "sv Wikipedia (Essingeleden motorway bridges 1966-67: 212 m of bridge in 56 + 100 + 56 m " +
				"spans, both carriageways together 30 m wide, sail clearance 15.2 m; the local bridge beside " +
				"them is a separate 11 m deck), OSM (overpass.openstreetmap.fr) polygon way 653639359 469.9 m " +
				"including ramps and ways 4520745 / 4520747 (about 211 m, bearing 40.1 / 220.3, bridge:" +
				"structure beam); sum 212.0 vs OSM 211 (0.5%); deck 19.2 m = 15.2 m clearance + 4.0 m girder, " +
				"which keeps the high deck of the real bridge"},
		{"id": "br_stockholm_alviksbron", "cc": "SE", "name": "Alviksbron", "wiki": "Alviksbron",
			"aliases": ["alvik bridge"], "lat": 59.3266, "lon": 17.9864, "bearing": 122.9, "st": "haunched",
			"spans": [50.0, 80.0, 140.0, 80.0, 50.0], "width": 14.0, "clear": 27.5, "pier_depth": 8.0,
			"mid_depth": 3.2, "material": "concrete", "base": "water", "tier": 3, "conf": 2,
			"concrete_hex": "#9C5B47", "steel_hex": "#BDB8AE",
			"src": "sv Wikipedia (Tvarbanan tram bridge 2000, 400 m, prestressed concrete box girder, 140 m " +
				"central span, sail clearance 24 m, cantilever-built, two piers in the water, main piers " +
				"clad in red brick), OSM (overpass.openstreetmap.fr) cycleway way 34175060 bearing 122.9 " +
				"passes 10 m from 59.3266,17.9864 and Tvarbanan way 120605994 crosses 259 m of water; the " +
				"140 m main span and the 400 m total are sourced, the 80 + 50 m side spans are estimated so the " +
				"outer piers stand at the shores (sum 400 vs 400); girder 3.2 m at mid-span deepening to 8 m " +
				"over the piers (haunched), deck 27.5 m = 24 m clearance + mid-span depth"},
		{"id": "br_stockholm_arstabron_ost", "cc": "SE", "name": "Ostra Arstabron", "wiki": "Årstabroarna",
			"aliases": ["östra årstabron", "arstabron", "årstabron", "arsta bridge", "arsta bridges", "arstabroarna",
				"årstabroarna"],
			"lat": 59.30828, "lon": 18.04298, "bearing": 34.7, "st": "masonry",
			"spans": [30.15, 30.15, 30.15, 30.15, 30.15, 30.15, 30.15, 30.15, 30.15, 30.15, 30.15, 30.15, 30.15,
				30.15, 30.15, 30.15, 30.15, 30.15, 30.15, 30.15], "width": 9.0, "clear": 27.0, "rise": 13.0,
			"material": "concrete", "base": "water", "tier": 2, "conf": 2, "concrete_hex": "#A9A398",
			"src": "sv+en Wikipedia (1923-29 railway viaduct by Cyrillus Johansson / Ernst Nilsson: 20 cast-concrete " +
				"arches plus a steel truss-arch span of about 150 m south of Arsta holmar, 753 m, 9 m wide, 26 m " +
				"clearance south of the islets, state-listed since 1986), OSM (overpass.openstreetmap.fr) rail " +
				"way 7271220 (Vastra stambanan, 811.3 m between 59.31073,18.04627 and 59.30472,18.03817, " +
				"bearing 34.7) and polygon way 506568450 811.6 m: the 753 m bridge sits centred on that way " +
				"(28 m of embankment each end), the 20 arches take the northern 603 m (30.15 m each, piers 4.2 " +
				"m, round arches) and the steel span the southern 150 m (br_stockholm_arstabron_ost_stal); the " +
				"two together are 753 vs OSM 811 (7.2%, the way includes the embankments); the lift span's two " +
				"pylons are not modelled, deck height from the 26 m clearance"},
		{"id": "br_stockholm_arstabron_ost_stal", "cc": "SE", "name": "Ostra Arstabron steel span",
			"wiki": "Årstabroarna", "aliases": ["östra årstabron steel arch", "arstabron steel arch"],
			"lat": 59.30548, "lon": 18.03921, "bearing": 34.7, "st": "arch_deck",
			"spans": [25.0, 100.0, 25.0], "width": 9.0, "clear": 27.0, "rise": 14.0, "arch_spans": [1],
			"material": "steel", "base": "water", "tier": 2, "conf": 2, "steel_hex": "#6F7C78",
			"src": "en+sv Wikipedia (steel truss-arch span over the southern passage: en 100 m span with 26 m " +
				"clearance and 75 m navigable width, sv a steel truss section of about 150 m), OSM rail way " +
				"7271220 as br_stockholm_arstabron_ost (this span is its southern 150 m: 25 + 100 + 25 m, the 100 " +
				"m arch the sourced figure, the 25 m end spans the remainder of sv's 150 m); arch rise " +
				"estimated"},
		{"id": "br_stockholm_arstabron_vast", "cc": "SE", "name": "Vastra Arstabron", "wiki": "Årstabroarna",
			"aliases": ["västra årstabron", "new arsta bridge", "nya årstabron", "arsta bridge red"],
			"lat": 59.30780, "lon": 18.04202, "bearing": 34.8, "st": "haunched",
			"spans": [65.5, 78.0, 78.0, 78.0, 78.0, 78.0, 78.0, 78.0, 78.0, 78.0, 65.5], "width": 19.5,
			"clear": 28.4, "pier_depth": 4.4, "mid_depth": 2.4, "material": "concrete", "base": "water",
			"tier": 2, "conf": 2, "steel_hex": "#8A3A2C", "concrete_hex": "#8A3A2C",
			"src": "sv+en Wikipedia (Norman Foster / Ove Arup rail and path bridge, opened 2005: 833 m, 19.5 m " +
				"wide, ten piers 78 m apart on rock, hollow prestressed concrete with a double-curved " +
				"underside, 26 m clearance, concrete pigmented falu red), OSM (overpass.openstreetmap.fr) rail " +
				"way 111499867 812.9 m, bearing 34.8, polygon way 494907429; nine inner 78 m spans and two end " +
				"spans of 65.5 m make the 833 m (sum 833.0 vs OSM 812.9, 2.5%), girder 2.4 m at mid-span " +
				"deepening to 4.4 m at the piers (estimated), deck 28.4 m = 26 m clearance + girder"},
		{"id": "br_stockholm_skanstullsbron", "cc": "SE", "name": "Skanstullsbron", "wiki": "Skanstullsbron",
			"aliases": ["skanstull bridge", "skanstullbron"], "lat": 59.30375, "lon": 18.07899, "bearing": 162.0,
			"st": "girder", "spans": [18.3, 18.3, 18.3, 18.3, 18.3, 18.3, 18.3, 106.0, 112.0, 118.0, 18.3, 18.3,
				18.3, 18.3, 18.3, 18.3], "width": 20.0, "clear": 36.5, "depth": 4.5, "material": "concrete",
			"base": "water", "tier": 3, "conf": 2,
			"src": "sv Wikipedia (1944-47 concrete road and rail viaduct by David Dahl: 574 m, 16 bays, the " +
				"central three 118, 112 and 106 m, sail clearance 32 m), OSM (overpass.openstreetmap.fr) " +
				"carriageway ways 41517933 (559.4 m, bearing 341.9) and 14870059 (bearing 162.1), bridge:" +
				"structure beam; the thirteen end bays split the remaining 238 m equally (18.3 m each, seven " +
				"north, six south) and the order of the three long spans is assumed; sum 574.0 vs OSM 559.4 " +
				"(2.6%); width 20 m from the 10 m carriageway spacing plus footways, deck 36.5 m = 32 m " +
				"clearance + 4.5 m girder; the parallel metro viaduct is not modelled"},
		{"id": "br_stockholm_johanneshovsbron", "cc": "SE", "name": "Johanneshovsbron", "wiki": "Johanneshovsbron",
			"aliases": ["johanneshov bridge", "johanneshovsbron"], "lat": 59.30362, "lon": 18.07752,
			"bearing": 152.5, "st": "girder", "spans": [51.0, 51.0, 51.0, 51.0, 55.7, 51.0, 51.0, 51.0, 51.0],
			"width": 17.9, "clear": 35.1, "depth": 3.1, "material": "concrete", "base": "water", "tier": 3,
			"conf": 2,
			"src": "sv Wikipedia (1984 continuous prestressed concrete box girder, 756 m with approaches, 17.9 m " +
				"wide, 32.0 m clearance at mean high water, normal span 51 m and largest 55.7 m), OSM " +
				"(overpass.openstreetmap.fr) ways 14869710 (465.3 m, bearing 152.5) and 148002251 (457.3 m, " +
				"bearing 332.3), bridge:structure beam, polygon way 394544399 830.5 m incl. ramps; the water " +
				"bridge is eight 51 m spans and the 55.7 m span (sum 463.7 vs OSM 462.4-465.3, 0.3%), the " +
				"position of the long span is assumed; deck 35.1 m = 32 m clearance + 3.1 m girder"},
		{"id": "br_stockholm_sankt_eriksbron", "cc": "SE", "name": "Sankt Eriksbron", "wiki": "Sankt Eriksbron",
			"aliases": ["s:t eriksbron", "st eriksbron", "saint eriks bridge", "sankt eriksbron"],
			"lat": 59.33736, "lon": 18.03488, "bearing": 22.5, "st": "girder", "spans": [40.0, 40.0, 40.0, 26.75],
			"width": 24.0, "clear": 15.5, "lower": 5.8, "material": "steel", "base": "water", "tier": 3,
			"conf": 2,
			"src": "sv Wikipedia (1903-06 bridge of three 40 m arch spans and four 26.75 m truss spans, 226.8 m, " +
				"rebuilt 1934-37 as a steel plate-girder bridge of which four of the seven spans remain " +
				"visible, 15.5 m clearance, metro deck added 1944 under the road, clearance 9.2 m under it), " +
				"OSM (overpass.openstreetmap.fr) ways 155195596 / 4491048 (151 m, bearing 22.4 / 202.9, " +
				"bridge:structure beam) and polygon way 668431615 153.1 x 24.1 m at bearing 22.5; the " +
				"visible spans are the three 40 m ones over the water and one 26.75 m over the rail yard " +
				"(order along the bearing assumed; sum 146.75 vs OSM 151.3, 3.0%); `lower` 5.8 m is the " +
				"metro deck (soffit 9.2 m over the water)"},
		{"id": "br_stockholm_lidingobron", "cc": "SE", "name": "Lidingobron", "wiki": "Lidingöbron",
			"aliases": ["lidingöbron", "lidingo bridge", "nya lidingöbron", "lidingobron"], "lat": 59.36031,
			"lon": 18.11022, "bearing": 47.9, "st": "girder",
			"spans": [34.0, 34.0, 34.0, 34.0, 68.0, 73.5, 73.5, 73.5, 73.5, 73.5, 73.5, 73.5, 73.5, 68.0,
				34.0, 34.0, 34.0, 34.0], "width": 24.0, "clear": 15.0, "depth": 2.5, "material": "steel",
			"base": "sea", "tier": 3, "conf": 2, "steel_hex": "#A4554A",
			"src": "sv Wikipedia (Lidingobron 1968-71 welded steel box girders on eleven piers, ten in the " +
				"water: 997 m, 724 m of it over water, 24 m wide, ten spans with a 73.5 m maximum, sail " +
				"clearance 12.5 m, originally bright red with a yellow stripe, now faded), OSM " +
				"(overpass.openstreetmap.fr) polygon way 401800914 1003.1 m at bearing 47.9 and ways 23427017 " +
				"(703.7 m) / 254115692; the ten water spans are 68 + 8 x 73.5 + 68 = 724 m, the concrete " +
				"approaches two 136 m runs of four 34 m spans (estimated), sum 996.0 vs OSM 1003.1 (0.7%); " +
				"deck 15 m on a 2.5 m girder puts the soffit at the sourced 12.5 m"},
		{"id": "br_stockholm_riksbron", "cc": "SE", "name": "Riksbron", "wiki": "Riksbron",
			"aliases": ["riks bridge", "riksbron stockholm"], "lat": 59.32821, "lon": 18.06708, "bearing": 152.6,
			"st": "arch_deck", "spans": [52.0], "width": 13.5, "clear": 2.6, "rise": 1.3, "material": "concrete",
			"base": "water", "tier": 3, "conf": 2,
			"src": "en Wikipedia (1931 concrete portal frame with central hinge by Axel Bjorkman and K A " +
				"Wickert, architect Ragnar Ostberg: 44 m long, 13.5 m wide, 7.5 m carriageway between two 3 m " +
				"footways), OSM (overpass.openstreetmap.fr) polygon way 411977807 52.1 x 15.3 m, bearing " +
				"152.6, bridge:structure arch, footway way 141844586 52.0 m: the model spans the 52 m between " +
				"the mapped abutments (44 m opening + abutment returns, 0.0% of OSM); rise and deck height " +
				"estimated"},
		{"id": "br_stockholm_stromsbron", "cc": "SE", "name": "Stromsbron", "wiki": "Strömbron",
			"aliases": ["strömbron", "strom bridge", "stromsbron"], "lat": 59.32881, "lon": 18.07311, "bearing": 6.6,
			"st": "girder", "spans": [12.7, 12.7, 12.7, 12.7, 12.7, 12.7, 12.7, 12.7, 12.7, 12.7, 12.7],
			"width": 20.0, "clear": 2.8, "orn": 8.7, "depth": 1.1, "material": "steel", "base": "water", "tier": 2,
			"conf": 2, "steel_hex": "#8E968F", "concrete_hex": "#A7A59E",
			"src": "sv+en Wikipedia (1946 provisional bridge over Norrstrom, 140 m long, 20 m wide concrete deck " +
				"on steel girders on concrete plinths founded on timber piles), OSM (overpass.openstreetmap.fr) " +
				"polygon way 389548369 142.2 x 21.7 m at bearing 6.4 and deck ways 959169606 (137.6 m) / " +
				"1337078899 / 35969580, centre 59.32881,18.07311; eleven equal spans counted from the photo " +
				"(visual-plan/refs/landmarks/stromsbron: low flat grey-green girder deck on pyramidal " +
				"concrete plinths, light railings and white lamp poles), sum 139.7 vs OSM 137.6 (1.5%), deck " +
				"at quay level"},
		{"id": "br_stockholm_norrbro", "cc": "SE", "name": "Norrbro", "wiki": "Norrbro",
			"aliases": ["norr bridge", "north bridge stockholm"], "lat": 59.32882, "lon": 18.06932,
			"bearing": 149.1, "st": "masonry", "spans": [18.3, 18.3, 18.3], "width": 19.0, "clear": 5.5,
			"rise": 4.0, "material": "stone", "base": "water", "tier": 2, "conf": 2, "stone_hex": "#A89F8D",
			"src": "sv+en Wikipedia (Erik Palmstedt's granite bridge 1787-1807 between Gustav Adolfs torg and " +
				"Helgeandsholmen: northern part three stone arches finished 1797, a slab part over " +
				"Helgeandsholmen, a single arch over Stallkanalen 1806, 190 m in all, 19 m wide), OSM " +
				"(overpass.openstreetmap.fr) polygon way 411977811 55.3 x 19.7 m at bearing 149.1 and deck " +
				"ways 120287587 (54.9 m); the three-arch northern part over Norrstrom is modelled as three " +
				"equal 18.3 m spans (sum 54.9 vs OSM 54.9), the 19 m southern arch over Stallkanalen " +
				"(polygon way 411977816) is not; deck and arch heights estimated"},
		{"id": "br_helsinki_pitkasilta", "cc": "FI", "name": "Pitkasilta", "wiki": "Pitkäsilta",
			"aliases": ["pitkäsilta", "langa bron", "long bridge helsinki"], "lat": 60.17637, "lon": 24.95011,
			"bearing": 177.3, "st": "masonry", "spans": [19.0, 19.0, 19.0], "width": 22.0, "clear": 5.0, "rise": 3.0,
			"material": "stone", "base": "sea", "tier": 2, "conf": 2, "stone_hex": "#8E8681", "pocks": 90,
			"src": "fi+en Wikipedia (1912 granite bridge, 3 arches of 16 m clear opening, 22 m wide), OSM ways " +
				"23952344 (57 m, bearing 177.3) = 3 x 16 m + piers, agrees with Wikipedia 60.17639,24.95; " +
				"piers 3 m assumed, clear and rise estimated | verified: fi Wikipedia infobox+text: three- " +
				"span granite vault, 'kolme vapaalta aukoltaan 16-metrista holvia' (three 16 m clear arches, " +
				"so equal), width 22 m, length 75 m incl. approach walls, 1912, designer Runar Eklund; OSM " +
				"ways 23952344/122869888 (57 m between abutments, bearing 177.3/357.2) mid 60.17637,24.95011; " +
				"pier thickness (3 m) and the deck/vault heights are estimates | H-5 photo check " +
				"(visual-plan/refs/landmarks/br_helsinki_pitkasilta): warm grey-brown granite ashlar (stone_hex), " +
				"three low segmental arches, pointed cutwaters, a solid parapet over a string course, 1918 " +
				"shrapnel and bullet pocks across the spandrels and parapet (pocks)"},
		{"id": "br_helsinki_lauttasaaren_silta", "cc": "FI", "name": "Lauttasaaren silta", "wiki": "Lauttasaari bridge",
			"aliases": ["lauttasaari bridge", "drumso bro"], "lat": 60.16216, "lon": 24.89768, "bearing": 255.1,
			"st": "girder", "spans": [30.0, 46.2, 56.6, 56.6, 56.6, 41.0, 30.0], "width": 23.5, "clear": 6.5,
			"depth": 1.7, "material": "steel", "base": "sea", "tier": 2, "conf": 2, "steel_hex": "#D6D6D1",
			"concrete_hex": "#8E908E", "columns": 3,
			"src": "fi+en Wikipedia (1969 composite steel-girder bridge with concrete deck, 317 m, 23.5 m, " +
				"longest span 56.6 m, deck over 12 m at the top), OSM way 4226243 (bearing 255.1, mid " +
				"60.16216,24.89768; Wikipedia 60.161,24.896 is a rounded point 130 m away); the other six " +
				"spans split by estimate | verified: fi Wikipedia: composite steel-beam bridge with " +
				"reinforced-concrete deck (+ former bascule leaf, now fixed), 317 m, 23.5 m, longest span " +
				"56.6 m, 'yli 12 m' deck height was for the 1935 predecessor; a Helsinki city decision text " +
				"gives 395 m length and 23.4 m usable width; OSM way 4226243 is 332 m (bearing 255.1, mid " +
				"60.16216,24.89768); only the 56.6 m span is sourced, six other spans estimated | round 2: " +
				"verify2: searched and not found - fi Wikipedia re-read: 317 m, 23.5 m, longest span 56.6 m " +
				"only; no other spans | H-5 photo check (visual-plan/refs/landmarks/br_helsinki_lauttasaaren_silta): " +
				"a low, slender off-white girder deck on round grey columns standing in the water, deck about 5 m over " +
				"it (the 12 m was the 1935 bridge), so clear is 6.5 m, the girder a slim 1.7 m and the row is built (conf 2) with its spans still " +
				"estimated; the photos suggest closer pier pairs than the seven spans here"},
		{"id": "br_helsinki_crusellinsilta", "cc": "FI", "name": "Crusell Bridge", "wiki": "Crusell Bridge",
			"aliases": ["crusellinsilta", "crusellbron"], "lat": 60.16036, "lon": 24.90818, "bearing": 158.0,
			"st": "stayed", "spans": [92.0, 51.5], "width": 24.8, "clear": 6.5, "tower": 49.0, "towers": [1],
			"pylon": "twin", "lean": 8.0, "stays": 10, "steel_hex": "#A9AEB1", "material": "concrete",
			"base": "sea", "tier": 2, "conf": 2,
			"src": "en Wikipedia (asymmetric cable-stayed, total 173.5 m, main span 92 m, Jatkasaari-side 51.5 " +
				"m, 24.8 m wide, inclined steel pylon 49 m over sea), OSM ways 28639650 bearing 158.0 agree " +
				"with Wikipedia 60.16056,24.90833; the extra 30 m end span, the order of spans along the " +
				"bearing, single-pylon form and deck height are estimated | verified: fi Wikipedia: " +
				"asymmetric two-span cable-stayed bridge, total 173.5 m incl. approach, main span 92 m, " +
				"Jatkasaari span 51.5 m, width 24.8 m, tilted steel pylon top about 49 m over the sea, " +
				"vertical clearance 5.25 m (deck about 6.5 m with the girder), prestressed concrete girder; " +
				"en Wikipedia same figures; OSM way 28639650 (145 m, bearing 158.0, mid 60.16036,24.90818) " +
				"has its water crossing from 9.8 to 134.7 m = the 125 m bay, so the bridge proper is 92+51.5 " +
				"= 143.5 m and the earlier third 30 m span was the remainder of the 173.5 m, not a span; the " +
				"Ruoholahti end is north so the 92 m main span comes first | H-5 photo check (visual-plan/refs/" +
				"landmarks/br_helsinki_crusellinsilta): the pylon is two separate inclined steel blades standing " +
				"on the deck between the cycle path and the tram lanes, leaning away from the main span about " +
				"8 m over their height (pylon twin, lean 8), silver-grey, with about ten stays a side fanning to " +
				"the deck edges (stays), not one mast on the centre line"},
		{"id": "br_helsinki_isoisansilta", "cc": "FI", "name": "Isoisansilta", "wiki": "Isoisänsilta",
			"aliases": ["isoisänsilta", "farfarsbron", "grandfather bridge"], "lat": 60.18205, "lon": 24.98276,
			"bearing": 141.0, "st": "arch_through", "spans": [6.7, 144.3, 13.6], "width": 5.5, "clear": 6.7,
			"rise": 18.0, "arch_spans": [1], "steel_hex": "#EFF0EC", "material": "steel", "base": "sea",
			"tier": 3, "conf": 2,
			"src": "en Wikipedia (pedestrian/cycle bridge 2016, 170 m with 144 m main span, deck at least 4 m " +
				"wide), OSM cycleway ways 442579082 / 574607677 / 574607678 chain bearing 141; arch type, " +
				"rise, approach spans, width and clear estimated | verified: fi Wikipedia: orthotropic-deck " +
				"steel arch bridge with the deck hung from the arch by 22 hanger pairs, longest span 144.3 m " +
				"with adjacent spans 6.7 m and 13.6 m (which end is which is not given), width 4 m minimum " +
				"widening to two paths at the Kalasatama end, clearance 6.7 m; en says total about 170 m (the " +
				"listed spans sum 164.6 m); OSM cycleway chain 442579082 + 574607677/8 (bearing 140-141) " +
				"confirmed; arch rise unsourced | round 2: verify2: searched and not found - fi Wikipedia re- " +
				"read: spans 144.3 with neighbours 6.7 and 13.6 m, width 4 m, clearance 6.7 m; web search " +
				"found no source giving which end carries the 6.7 m span or the arch rise | H-5 photo check " +
				"(visual-plan/refs/landmarks/br_helsinki_isoisansilta): a white painted steel arch over the " +
				"144.3 m span only (arch_spans), thin hangers to a white orthotropic deck girder, white railings; " +
				"the 6.7 m clearance is the sourced figure, so clear is 6.7 and the row is built (conf 2) with " +
				"the arch rise and the end-span order still estimated"},
		{"id": "br_helsinki_kulosaaren_silta", "cc": "FI", "name": "Kulosaaren silta", "wiki": "Kulosaaren silta",
			"aliases": ["kulosaarensilta", "kulosaari bridge", "brando bro"], "lat": 60.18626, "lon": 24.9853,
			"bearing": 102.7, "st": "girder", "spans": [30.0, 34.0, 35.0, 30.0, 35.0, 40.0, 42.0, 40.0, 35.0],
			"width": 32.0, "clear": 9.5, "material": "steel", "base": "sea", "tier": 3, "conf": 2,
			"steel_hex": "#CFCFC6", "concrete_hex": "#8D908D", "stone_hex": "#6E655E", "columns": 5, "plinth": 1.6,
			"src": "fi Wikipedia (1957 welded steel-girder grillage bridge, 321 m, 32 m wide, nine spans " +
				"30,34,35,30,35,40,42,40,35 m; demolition decided 2023, work from 2027 at earliest so it " +
				"still stands), OSM Kulosaarensilta way 219892295 bearing 102.7 agrees with Wikipedia " +
				"60.18625,24.98556; span order along the bearing and deck height assumed | verified: fi " +
				"Wikipedia: nine openings 30,34,35,30,35,40,42,40,35 m (321 m), 32 m wide, welded steel " +
				"girder grillage, 3+3 lanes, demolition decision 2023 (works 2027 at the earliest); OSM " +
				"eastbound carriageway 219892295 (263 m, bearing 102.7) crosses water from 56.6 to 251.8 m of " +
				"the way, consistent with the 40-42-40 m spans sitting over the channel when the list runs " +
				"west to east; the list direction is assumed to be Sorensen-to-Kulosaari | H-5 photo check " +
				"(visual-plan/refs/landmarks/br_helsinki_kulosaaren_silta): the welded plate girders and the deck " +
				"fascia are pale grey-cream, carried on rows of slim round dark-grey columns standing on dark " +
				"granite footings about 2 m over the water (columns, plinth), not on slab piers; the deck top " +
				"reads about 9 to 11 m over the water in the side photo, so clear is 9.5 (scale from a 3.7 m metro car)"},
		{"id": "br_copenhagen_langebro", "cc": "DK", "name": "Langebro", "wiki": "Langebro",
			"aliases": ["long bridge copenhagen"], "lat": 55.67025, "lon": 12.57861, "bearing": 131.6, "st": "bascule",
			"spans": [106.0, 53.0, 95.0], "width": 30.0, "clear": 7.5, "material": "concrete", "base": "sea", "tier": 2,
			"conf": 1,
			"src": "en+da Wikipedia (1954 double-leaf bascule bridge by Kaj Gottlob, 35 m navigation width, 7 m " +
				"clearance), OSM cycleway way 1366539123 (253 m, bearing 131.6) and bascule ways; side-span " +
				"split, leaf length and width estimated | verified: da+en Wikipedia: 1954 double-leaf bascule " +
				"(dobbeltfaget klapbro) by Kaj Gottlob, 250 m long, 35 m navigation width, 7 m clearance; OSM " +
				"chain 107382796/176968797 (106 m) + movable way 706618534 (53 m) + 706618533 (95 m) = 254 m " +
				"at bearing 131.4, mid 55.67028,12.57868 matches the row within 10 m; the fixed sides are " +
				"really several short spans, not one 106/95 m span, and the leaf lengths are unpublished | " +
				"round 2: verify2: searched and not found - da Wikipedia re-read: 35 m navigation width, 7 m " +
				"clearance, no span lengths"},
		{"id": "br_copenhagen_lille_langebro", "cc": "DK", "name": "Lille Langebro", "wiki": "Lille Langebro",
			"aliases": ["little long bridge copenhagen"], "lat": 55.67114, "lon": 12.58005, "bearing": 116.6,
			"st": "girder", "spans": [33.0, 47.0, 45.0, 34.0], "width": 7.0, "clear": 6.0, "material": "steel",
			"base": "sea", "tier": 2, "conf": 1,
			"src": "en+da Wikipedia (2019 curved steel pedestrian/cycle double-swing bridge, 4 spans, 160-175 m, " +
				"7 m wide), OSM ways 706615520-2 and 303625173 (33+47+45+34 m, chord bearing 116.6, width 7); " +
				"curvature and swing spans not representable, clear estimated | verified: en Wikipedia (160 " +
				"m, 7 m wide, 5 spans, double-swing) and da Wikipedia (175 m, 4 spans, the two middle ones " +
				"swing sideways); OSM ways 706615522 (33 m) + 706615521 (47 m, movable) + 706615520 (45 m, " +
				"movable) + 303625173 (34 m) = 159 m, chord bearing 116.8, mid 55.67114,12.58005 confirmed; " +
				"two spans rotate and the plan is curved: the swing type has one moving span and no curve | " +
				"round 2: verify2: searched and not found - da Wikipedia re-read: 175 m, four spans, two " +
				"middle ones swing sideways; swing type has a single moving span"},
		{"id": "br_copenhagen_knippelsbro", "cc": "DK", "name": "Knippelsbro", "wiki": "Knippelsbro",
			"aliases": ["knippel bridge"], "lat": 55.67485, "lon": 12.58706, "bearing": 136.8, "st": "bascule",
			"spans": [38.5, 38.0, 38.5], "width": 27.4, "clear": 6.0, "material": "steel", "base": "sea", "tier": 2,
			"conf": 1,
			"src": "en+da Wikipedia (1937 bascule bridge by Kaj Gottlob, 115 m), OSM way 1694109 (bearing 136.8, " +
				"width tag 27.4), agrees with Wikipedia 55.6747,12.5872; span split and deck height estimated " +
				"| verified: da+en Wikipedia: 115 m long, 27.4 m wide (OSM width tag 27.4), 1937 bascule by " +
				"Kaj Gottlob, clearance under the closed bridge 5.4 m (da infobox); OSM way 1694109 (94 m, " +
				"bearing 136.8, mid 55.67485,12.58706) confirmed; leaf and side-span lengths not published in " +
				"sources found (Ingenioren 1938 article only) | round 2: verify2: searched and not found - da " +
				"Wikipedia re-read: 115 m, 27.4 m wide, clearance 5.4 m; no leaf or side-span lengths"},
		{"id": "br_copenhagen_inderhavnsbroen", "cc": "DK", "name": "Inderhavnsbroen", "wiki": "Inderhavnsbroen",
			"aliases": ["kissing bridge", "kyssebroen"], "lat": 55.67846, "lon": 12.59525, "bearing": 107.0,
			"st": "girder", "spans": [30.0, 60.0, 30.0, 30.0, 30.0], "width": 7.0, "clear": 5.0, "material": "steel",
			"base": "sea", "tier": 2, "conf": 1,
			"src": "en+da Wikipedia (180 m pedestrian/cycle bridge 2016 with retractable, folding sections), OSM " +
				"unnamed footway/cycleway ways 393218121/393218122 (bearing 107); retractable sections not " +
				"representable, span split, width and clear estimated | verified: da Wikipedia (180 m, " +
				"rullebro/retractable), competition sources (opening span 50 m, deck 7 m wide, horizontal " +
				"clearance 45 m); OSM ways 393218121/393218122 (137-139 m between 55.67856,12.59417 and " +
				"55.67833,12.59633, bearing 106.7/102.2) confirmed; the two sliding sections and the " +
				"mast/stay arrangement are not representable and the full span list is unpublished | round 2: " +
				"verify2: searched and not found - da Wikipedia re-read: 180 m only; no span list"},
		{"id": "br_copenhagen_cirkelbroen", "cc": "DK", "name": "Cirkelbroen", "wiki": "Circle Bridge",
			"aliases": ["circle bridge copenhagen", "five circles footbridge"], "lat": 55.67242, "lon": 12.5838,
			"bearing": 44.5, "st": "girder", "spans": [8.0, 8.0, 8.0, 8.0, 8.0], "width": 6.0, "clear": 3.0,
			"material": "steel", "base": "sea", "tier": 3, "conf": 1,
			"src": "en Wikipedia (40 m footbridge of five circular decks hung from masts, two decks swing), OSM " +
				"way 338137146 (40 m, bearing 44.5); mast-and-cable circles not representable, nearest girder " +
				"| verified: en Wikipedia: 40 m footbridge of five interconnected circular decks hung from " +
				"masts, two decks swing open; OSM way 338137146 (38 m, bearing 44.5, mid 55.67242,12.58380) " +
				"confirmed; circular decks with masts are not a girder | round 2: verify2: searched and not " +
				"found - not rechecked beyond round 1; circular decks and masts are not a girder"},
		{"id": "br_copenhagen_bryggebroen", "cc": "DK", "name": "Bryggebroen", "wiki": "Bryggebroen",
			"aliases": ["quay bridge copenhagen"], "lat": 55.66152, "lon": 12.56667, "bearing": 114.4, "st": "girder",
			"spans": [55.5, 79.0, 55.5], "width": 5.5, "clear": 5.0, "material": "steel", "base": "sea", "tier": 3,
			"conf": 1,
			"src": "en+da Wikipedia (2006 swing bridge for pedestrians and cyclists, 190 m, 5.5 m wide), OSM " +
				"ways 351687505/506 (79 m swing section, bearing 114.5) plus approach ways 419617574/580, " +
				"chain centre equals da Wikipedia 55.66139,12.56667; swing span not representable, side spans " +
				"from total, clear estimated | verified: en+da Wikipedia: 190 m swing bridge for pedestrians " +
				"and cyclists, 5.5 m wide, opened 2006; OSM movable ways 351687505/351687506 (79 m, bearing " +
				"114.5, mid 55.66134,12.56738) = the swing section; side spans only inferred from the 190 m " +
				"total; tried the new 'swing' type but the span list is not sourced | round 2: verify2: " +
				"searched and not found - da Wikipedia (short stub) re-read: no span list"},
		{"id": "br_riga_akmens_tilts", "cc": "LV", "name": "Akmens tilts", "wiki": "Stone Bridge, Riga",
			"aliases": ["stone bridge riga", "oktobra tilts"], "lat": 56.94462, "lon": 24.10129, "bearing": 48.1,
			"st": "girder", "spans": [50.6, 64.4, 75.1, 85.1, 75.1, 64.4, 50.6], "width": 33.5, "clear": 9.0,
			"material": "steel", "base": "water", "tier": 2, "conf": 2,
			"src": "lv Wikipedia (continuous 7-span steel plate girder 50.6+64.4+75.1+85.1+75.1+64.4+50.6 m, 503 " +
				"m with approaches, roadway 27.5 m plus footways), en Wikipedia 56.9445,24.1011, OSM way " +
				"4995172 bearing 48.1; deck height estimated | verified: lv Wikipedia (Akmens tilts (Riga)): " +
				"continuous seven-span steel beam 50.6+64.4+75.1+85.1+75.1+64.4+50.6 m, total 503.12 m with " +
				"approaches, 27.5 m carriageway plus two 3 m footways (33.5 m), eight 1.8-2.4 m deep plate " +
				"girders; OSM way 4995172 (520 m, bearing 48.1) crosses water from 6.9 to 495.5 m, centred " +
				"within 10 m of the row coordinate"},
		{"id": "br_riga_vansu_tilts", "cc": "LV", "name": "Vansu tilts", "wiki": "Vanšu Bridge",
			"aliases": ["vanšu tilts", "vanšu bridge", "shroud bridge"], "lat": 56.9512, "lon": 24.09588,
			"bearing": 70.3, "st": "stayed", "spans": [312.0, 283.0], "width": 28.4, "clear": 15.0, "tower": 109.0,
			"towers": [1], "pylon": "single", "material": "steel", "base": "water", "tier": 2, "conf": 1,
			"src": "en+lv Wikipedia (1981 single-pylon cable-stayed bridge in one plane, 595 m, stayed part 312 " +
				"m; reconstruction contract signed Jan 2026, works from 2027, so it still stands), OSM way " +
				"23692402 (665 m, bearing 70.3); span split, pylon height, width and clear estimated | " +
				"verified: lv+en Wikipedia: single-pylon cable-stayed 1981, longest span 312 m, total length " +
				"595 m (625 m with approaches), width 28.4 m (28), pylon height 109 m (infobox); en infobox " +
				"lists 2 spans; OSM way 23692402 (666 m, bearing 70.3) crosses water from 50.7 to 494.2 m; " +
				"whether the other 283 m is a second stayed span or a beam span is not stated; reconstruction " +
				"contract signed 16 Jan 2026 (works from 2027) so it still stands | round 2: verify2: " +
				"searched and not found - lv Wikipedia fetch returned a redirect stub; no second-span source " +
				"found"},
		{"id": "br_vilnius_zaliasis_tiltas", "cc": "LT", "name": "Green Bridge", "wiki": "Green Bridge (Vilnius)",
			"aliases": ["zaliasis tiltas", "žaliasis tiltas"], "lat": 54.69146, "lon": 25.27998, "bearing": 5.8,
			"st": "girder", "spans": [31.0, 41.0, 31.0], "width": 24.0, "clear": 8.0, "material": "concrete",
			"base": "water", "tier": 2, "conf": 1,
			"src": "lt+en Wikipedia (1952 bridge 102.9 m, 24 m wide, 15 m high), OSM Kalvarijų g. ways 168255991 " +
				"+ 530515767 (width 24, bearing 5.8) agree with Wikipedia 54.69139,25.27972; span layout, " +
				"type and deck height unknown, estimated; statues not modelled | verified: en+lt Wikipedia: " +
				"1952 bridge, 102.9 m long, 24 m wide, 15 m high (en); no span layout in en/lt Wikipedia or " +
				"search results; OSM Kalvariju g. ways 168255991 (51 m) + 530515767 (55 m), width 24, bearing " +
				"5.5-6.0 confirmed | round 2: verify2: searched and not found - lt Wikipedia articles fetched " +
				"(Green Bridge page is a redirect); no span layout found"},
		{"id": "br_vilnius_baltasis_tiltas", "cc": "LT", "name": "White Bridge", "wiki": "White Bridge (Vilnius)",
			"aliases": ["baltasis tiltas"], "lat": 54.69318, "lon": 25.27324, "bearing": 43.4, "st": "girder",
			"spans": [59.0, 59.0, 59.0, 59.0], "width": 6.0, "clear": 8.0, "material": "steel", "base": "water",
			"tier": 3, "conf": 1,
			"src": "lt+en Wikipedia (pedestrian bridge 1996, 240 m, 6 m wide, 11.4 m high), OSM way 4870120 (236 " +
				"m, bearing 43.4); structure type and spans not found, estimated | verified: lt Wikipedia: " +
				"pedestrian bridge opened 1996, 240 m long, 6 m wide, 11.4 m high, designed in St Petersburg; " +
				"no span layout found; OSM way 4870120 (237 m, bearing 43.4, mid 54.69318,25.27324) confirmed " +
				"| round 2: verify2: searched and not found - lt Wikipedia re-read: no span layout"},
		{"id": "br_vilnius_mindaugas_bridge", "cc": "LT", "name": "Mindaugas Bridge", "wiki": "Mindaugas Bridge",
			"aliases": ["karaliaus mindaugo tiltas", "mindaugo tiltas"], "lat": 54.689, "lon": 25.28826, "bearing": 8.8,
			"st": "girder", "spans": [26.0, 49.0, 26.0], "width": 19.7, "clear": 7.0, "material": "concrete",
			"base": "water", "tier": 3, "conf": 1,
			"src": "lt+en Wikipedia (2003 bridge, 101 m, 19.7 m wide, 3 lanes), OSM way 386060652 (102 m, width " +
				"19.7, bearing 8.8); span layout and deck height estimated | verified: lt+en Wikipedia: 2003 " +
				"bridge, 101 m long, 19.7 m wide, three traffic lanes; no span layout found; OSM way " +
				"386060652 (102 m, bearing 8.8, mid 54.68900,25.28826) confirmed | round 2: verify2: searched " +
				"and not found - lt Wikipedia article is a redirect; no span layout"},
		{"id": "br_vilnius_zvierynas_bridge", "cc": "LT", "name": "Zverynas Bridge", "wiki": "Žvėrynas Bridge",
			"aliases": ["žvėryno tiltas", "zveryno tiltas", "zverynas bridge"], "lat": 54.69047, "lon": 25.25885,
			"bearing": 93.1, "st": "truss", "spans": [34.4, 34.3, 34.4], "width": 11.35, "clear": 6.0, "rise": 7.0,
			"material": "steel", "base": "water", "tier": 3, "conf": 1,
			"src": "lt+en Wikipedia (1905-07 steel bridge on stone piers, 103.1 m, 11.35 m wide, 11 m high), OSM " +
				"way 4870067 (104 m, bearing 93.1) agrees with Wikipedia 54.69027,25.25889; steel truss/arch " +
				"form, spans and rise estimated | verified: lt+en Wikipedia: 1905-07 steel bridge on stone " +
				"piers, 103.1 m long, 11.35 m wide, 11 m high, en category 'Arch bridges in Lithuania'; the " +
				"steel superstructure form (arch or truss) and spans are not stated anywhere found; OSM way " +
				"4870067 (104 m, bearing 93.1, mid 54.69047,25.25885) confirmed | round 2: verify2: searched " +
				"and not found - lt Wikipedia Zveryno tiltas re-read: no span layout or structure form"},
		{"id": "br_vilnius_geleziniovilko_tiltas", "cc": "LT", "name": "Iron Wolf Bridge", "wiki": "Iron Wolf Bridge",
			"aliases": ["geležinio vilko tiltas", "gelezinio vilko tiltas"], "lat": 54.69529, "lon": 25.2639,
			"bearing": 178.0, "st": "girder", "spans": [65.0, 65.0, 65.0, 65.0], "width": 38.8, "clear": 10.0,
			"material": "concrete", "base": "water", "tier": 3, "conf": 1,
			"src": "lt+en Wikipedia (1979 reinforced-concrete bridge, 260 m, 38.8 m wide, 12 m high), OSM " +
				"Geležinio Vilko g. ways 4946802 + 4870109 (chain about 254 m, bearing 178) agree with " +
				"Wikipedia 54.69528,25.26389; spans estimated | verified: lt+en Wikipedia: 1979 reinforced- " +
				"concrete bridge, 260 m, 38.8 m wide, 12 m high; no span layout found; OSM Gelezinio Vilko g. " +
				"ways 4946802+4870109 chain (about 256 m, bearing 178) and cycle path 1274714415 (259 m, " +
				"bearing 178.0) confirmed | round 2: verify2: searched and not found - lt Wikipedia re-read: " +
				"no span layout"},
		{"id": "br_vilnius_valakampiu_tiltas", "cc": "LT", "name": "Valakampiai Bridge", "wiki": "Valakampiai Bridge",
			"aliases": ["valakampių tiltas", "valakupiai bridge"], "lat": 54.72594, "lon": 25.31138, "bearing": 44.3,
			"st": "girder", "spans": [55.0, 100.0, 46.6, 46.6, 46.6, 46.7], "width": 21.0, "clear": 14.0,
			"material": "concrete", "base": "water", "tier": 3, "conf": 1,
			"src": "lt+en Wikipedia (1972 prestressed concrete bridge 341.5 m, 21 m wide, 6 spans: 100 m over " +
				"the river, one on the left bank, four on the right), OSM O. Milašiaus g. + Kareivių g. ways " +
				"(124+213 m, bearing 44.3); order and sizes of the 5 shorter spans and deck height estimated " +
				"| verified: en+lt Wikipedia: 1972 prestressed ferroconcrete beams, 341.5 m, about 21 m wide, " +
				"six spans: 100 m over the river, one on the left bank, a four-span viaduct on the right " +
				"bank; the other five lengths and their order are not given (sum of the five = 241.5 m); OSM " +
				"O. Milasiaus g. 824495224 (214 m) + Kareiviu g. 5011306 (124 m) chain, bearing 44.3, footway " +
				"354661719 (338 m, mid 54.72588,25.31147) confirmed | round 2: verify2: searched and not " +
				"found - lt Wikipedia re-read: no lengths for the five shorter spans"},
		{"id": "br_riga_dienvidu_tilts", "cc": "LV", "name": "Dienvidu tilts", "wiki": "Southern Bridge",
			"aliases": ["southern bridge riga", "dienvidu bridge", "south bridge riga"], "lat": 56.9158, "lon": 24.1572,
			"bearing": 43.4, "st": "extradosed", "spans": [49.5, 77.0, 110.0, 110.0, 110.0, 110.0, 110.0, 77.0, 49.5],
			"width": 34.3, "clear": 11.5, "tower": 24.8, "towers": [2, 3, 4, 5, 6, 7], "material": "steel",
			"base": "water", "tier": 2, "conf": 2,
			"src": "BD&E article via bridgeweb.com/Latvian-link/2055 (9 spans: five of 110 m and one 77 m + one " +
				"49.5 m at each end = 803 m, six steel pylons on the piers, steel girders with a prestressed " +
				"concrete deck, stay cables mainly prestress the girder), lv Wikipedia (803 m, 7 'posmi' of " +
				"which the longest 110 m, 10 supports of which 6 carry pylons, width 34.28 m, pylon height " +
				"13.33 m over the road surface, clearance below 8.5 m), en Wikipedia (extradosed, 803 m, " +
				"34.28 m); OSM Dienvidu tilts ways 126047905/37732348 (801 m, bearing 43.4/223.4, mid " +
				"56.91575,24.15728) so centre and bearing re-measured; order of the 77 m and 49.5 m side " +
				"spans at each end assumed, deck height estimated from 8.5 m clearance + girder depth"},
		{"id": "br_turku_tuomiokirkkosilta", "cc": "FI", "name": "Tuomiokirkkosilta", "wiki": "Tuomiokirkkosilta",
			"aliases": ["cathedral bridge turku", "domkyrkobron"], "lat": 60.452268, "lon": 22.274896,
			"bearing": 143.7, "st": "girder", "spans": [16.0, 18.0, 16.0], "width": 24.0, "clear": 4.2,
			"material": "concrete", "base": "water", "tier": 2, "conf": 2,
			"src": "fi Wikipedia (Tuomiokirkkosilta, widened 1956 reinforced-concrete three-span bridge over Aurajoki, " +
				"about 50 m long, ~24 m wide), OSM ways 4306348/27734777 (47.4-50.0 m, bearing 143.6/323.8, " +
				"mid 60.452268,22.274896)"},
		{"id": "br_turku_kirjastosilta", "cc": "FI", "name": "Kirjastosilta", "wiki": "Kirjastosilta",
			"aliases": ["library bridge turku", "biblioteksbron"], "lat": 60.449458, "lon": 22.272091,
			"bearing": 123.2, "st": "arch_deck", "spans": [59.8], "width": 5.0, "clear": 4.0, "rise": 3.5, "orn": 3.8,
			"material": "steel", "base": "water", "tier": 2, "conf": 2,
			"src": "fi Wikipedia (Kirjastosilta, 2013 white steel pedestrian bridge over Aurajoki, single ~56 m span, " +
				"5 m wide), OSM way 103351226 (59.8 m, width 5 m, bearing 303.2, mid 60.449458,22.272091)"},
		{"id": "br_turku_auransilta", "cc": "FI", "name": "Auransilta", "wiki": "Auransilta",
			"aliases": ["aurasilta", "aura bridge", "aurabron"], "lat": 60.448548, "lon": 22.269742,
			"bearing": 144.5, "st": "arch_deck", "spans": [45.2], "width": 17.5, "clear": 4.5, "rise": 4.2, "orn": 6.1,
			"material": "stone", "base": "water", "tier": 2, "conf": 2,
			"src": "fi Wikipedia (Auransilta, 1907 single-span steel/granite arch bridge across Aurajoki, ~45 m span, " +
				"17.5 m wide), OSM ways 90088650/90088646/90088671 (45.2 m, bearing 144.5, mid 60.448548,22.269742)"},
		{"id": "br_turku_teatterisilta", "cc": "FI", "name": "Teatterisilta", "wiki": "Teatterisilta",
			"aliases": ["theatre bridge turku", "teaterbron"], "lat": 60.447032, "lon": 22.264301,
			"bearing": 150.7, "st": "girder", "spans": [66.2], "width": 6.4, "clear": 4.5, "orn": 9.3,
			"material": "steel", "base": "water", "tier": 2, "conf": 2,
			"src": "fi Wikipedia (Teatterisilta, 1997 single-span steel pedestrian bridge by Turku City Theatre, ~65 m), " +
				"OSM way 105064411 (66.3 m, bearing 330.7, mid 60.447032,22.264301)"},
		{"id": "br_turku_myllysilta", "cc": "FI", "name": "Myllysilta", "wiki": "Myllysilta",
			"aliases": ["mill bridge turku", "kvarnbron"], "lat": 60.445174, "lon": 22.257903,
			"bearing": 145.4, "st": "girder", "spans": [22.0, 50.0, 22.0], "width": 20.0, "clear": 5.2,
			"material": "steel", "base": "water", "tier": 2, "conf": 2,
			"src": "fi Wikipedia (Myllysilta, 2011 replacement steel box-girder bridge over Aurajoki, ~94 m total, " +
				"~20 m wide), OSM ways 531029806/1579901611/206891995 (94.0-94.4 m, bearing 325.4, mid 60.445174,22.257903)"},
		{"id": "br_turku_martinsilta", "cc": "FI", "name": "Martinsilta", "wiki": "Martinsilta",
			"aliases": ["st. martin's bridge turku", "martinsbron"], "lat": 60.444341, "lon": 22.255718,
			"bearing": 145.2, "st": "girder", "spans": [24.0, 56.0, 24.0], "width": 18.0, "clear": 5.5,
			"material": "concrete", "base": "water", "tier": 2, "conf": 2,
			"src": "fi Wikipedia (Martinsilta, 1940 reinforced-concrete girder bridge over Aurajoki, ~104.5 m), " +
				"OSM way 4306342 (104.6 m, bearing 145.2, mid 60.444341,22.255718)"},
		{"id": "br_turku_tuomaansilta", "cc": "FI", "name": "Tuomaansilta", "wiki": "Tuomaansilta",
			"aliases": ["tuomaan silta", "thomas bridge turku", "tomasbron"], "lat": 60.458810, "lon": 22.277528,
			"bearing": 80.8, "st": "girder", "spans": [28.0, 55.2, 28.0], "width": 22.0, "clear": 5.8,
			"material": "concrete", "concrete_hex": "#B8B6AE", "columns": 3, "base": "water", "tier": 2, "conf": 2,
			"src": "fi Wikipedia (Tuomaansilta, 1999 concrete/steel road bridge over Aurajoki, 22 m wide, ~110 m deck), " +
				"OSM ways 4238871/4238874 + cycleways 26490790/482768026 (111.2 m, bearing 80.8, mid 60.458810,22.277528)"},
		{"id": "br_turku_halistensilta", "cc": "FI", "name": "Halistensilta", "wiki": "Halistensilta",
			"aliases": ["halisten silta", "halisbron"], "lat": 60.464742, "lon": 22.304102,
			"bearing": 10.5, "st": "girder", "spans": [30.0, 37.3, 37.4, 30.0], "width": 12.5, "clear": 7.5,
			"material": "concrete", "concrete_hex": "#B4B2AA", "columns": 2, "base": "water", "tier": 3, "conf": 2,
			"src": "fi Wikipedia (Halistensilta crossing Aurajoki at Halistenkoski rapids), " +
				"OSM way 4451067 (134.7 m, 2 lanes, bearing 10.5, mid 60.464742,22.304102)"},
		{"id": "br_turku_aurajoen_rautatiesilta", "cc": "FI", "name": "Aurajoen rautatiesilta",
			"wiki": "Aurajoen rautatiesilta", "aliases": ["aura river railway bridge", "rantarata bridge turku"],
			"lat": 60.460771, "lon": 22.279379, "bearing": 105.5, "st": "truss",
			"spans": [42.0, 54.0, 53.2, 42.0], "arch_spans": [1, 2], "width": 8.5, "clear": 7.5, "rise": 7.5,
			"material": "steel", "steel_hex": "#6E757A", "base": "water", "tier": 3, "conf": 2,
			"src": "Rantarata steel truss railway bridge over Aurajoki upstream of Tuomaansilta, " +
				"OSM way 1327879940 (191.2 m, bearing 105.5/285.5, mid 60.460771,22.279379)"},
		{"id": "br_turku_hirvensalonsilta", "cc": "FI", "name": "Hirvensalonsilta", "wiki": "Hirvensalonsilta",
			"aliases": ["hirvensalo bridge", "hirvensalobron"], "lat": 60.422780, "lon": 22.236390,
			"bearing": 172.0, "st": "girder", "spans": [45.0, 58.0, 64.0, 58.0, 45.0], "width": 21.0, "clear": 10.0,
			"material": "concrete", "concrete_hex": "#C4C2BA", "columns": 3, "base": "sea", "tier": 2, "conf": 2,
			"src": "fi Wikipedia (Hirvensalonsilta, 1993 4-lane road bridge over Pitkäsalmi strait, 6300 m2 deck, " +
				"8 m vertical clearance, 60°25'22\"N 22°14'11\"E)"},
		{"id": "br_turku_aninkaistensilta", "cc": "FI", "name": "Aninkaistensilta", "wiki": "Aninkaistensilta",
			"aliases": ["aningaisbron", "aninkainen bridge"], "lat": 60.458812, "lon": 22.267903,
			"bearing": 146.4, "st": "girder", "spans": [28.0, 37.5, 37.6, 28.0], "width": 35.0, "clear": 6.5,
			"material": "concrete", "concrete_hex": "#BDBBB2", "columns": 4, "base": "ground", "tier": 2, "conf": 2,
			"src": "fi Wikipedia (Aninkaistensilta over Turku railyard, 130 m long, 35 m wide), " +
				"OSM ways 4265033/4265032 + cycleways 35012132/27955401 (131.1 m, bearing 146.4, mid 60.458812,22.267903)"},
		{"id": "br_turku_ukko_pekan_silta", "cc": "FI", "name": "Ukko-Pekan silta", "wiki": "Ukko-Pekan silta",
			"aliases": ["ukko-pekka bridge", "ukko-pekka-bron", "naantalinsalmen silta"],
			"lat": 60.462220, "lon": 22.020830, "bearing": 258.0, "st": "arch_deck",
			"spans": [33.0, 45.0, 55.0, 45.0, 33.0], "width": 8.0, "clear": 13.0, "rise": 8.5,
			"material": "concrete", "concrete_hex": "#C8C4BA", "base": "sea", "tier": 3, "conf": 2, "view": 4500.0,
			"src": "fi Wikipedia (Ukko-Pekan silta, 1934 concrete arch bridge over Naantalinsalmi via Raumakari, " +
				"211 m total, 45 m arch spans, 11 m vertical clearance, 60°27'44\"N 22°01'15\"E)"},
	]
