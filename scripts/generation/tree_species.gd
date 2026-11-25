class_name TreeSpecies
extends RefCounted

## Species table + climate/land-cover species mix for T5.1 vegetation.
## Every size is in true metres (scaled by WorldScale.metres_to_units()
## at instancing), so trees are right before and after the metre
## cutover. Geometry generators live in TreeMeshLibrary.
##
## gen "broad": trunk + main/secondary branches + leaf-card clusters on
##   a crown ellipsoid (bole = clear-trunk fraction, crown_r = crown
##   radius / height, leader = how far the trunk runs into the crown,
##   up = branch elevation bias, droop = tip droop).
## gen "conifer": whorls of drooping branch cards on a cone/column.
## gen "palm": curved ringed trunk + arching V-folded fronds.

const SPECIES := {
	"plane": {"gen": "broad", "h": 20.0, "h_var": 0.25, "bole": 0.30, "crown_r": 0.33,
		"leader": 0.35, "branches": 7, "trunk_r": 0.34, "up": 0.55, "droop": 0.0,
		"clusters": 58, "card": 3.4, "leaf": "broad", "bark": "plane",
		"tint": "broad", "evergreen": false},
	"lime": {"gen": "broad", "h": 18.0, "h_var": 0.2, "bole": 0.22, "crown_r": 0.27,
		"leader": 0.8, "branches": 9, "trunk_r": 0.30, "up": 0.6, "droop": 0.15,
		"clusters": 62, "card": 3.0, "leaf": "broad", "bark": "furrowed",
		"tint": "lime", "evergreen": false},
	# Parisian Horse Chestnut (Aesculus hippocastanum — 2,039 mapped trees around Champ de Mars & Trocadéro):
	# broad, dense rounded canopy with deep palmate foliage and warm autumn amber.
	"horse_chestnut": {"gen": "broad", "h": 19.0, "h_var": 0.22, "bole": 0.24, "crown_r": 0.36,
		"leader": 0.45, "branches": 8, "trunk_r": 0.36, "up": 0.52, "droop": 0.12,
		"clusters": 66, "card": 3.3, "leaf": "broad", "bark": "furrowed",
		"tint": "broad", "evergreen": false},
	"honey_locust": {"gen": "broad", "h": 17.0, "h_var": 0.2, "bole": 0.38, "crown_r": 0.38,
		"leader": 0.35, "branches": 7, "trunk_r": 0.24, "up": 0.52, "droop": 0.1,
		"clusters": 40, "card": 2.3, "leaf": "birch", "bark": "furrowed", "tint": "birch", "evergreen": false},
	"callery_pear": {"gen": "broad", "h": 11.0, "h_var": 0.2, "bole": 0.25, "crown_r": 0.24,
		"leader": 0.85, "branches": 8, "trunk_r": 0.19, "up": 0.7, "droop": 0.05,
		"clusters": 48, "card": 2.2, "leaf": "broad", "bark": "furrowed", "tint": "broad", "evergreen": false},
	"ginkgo": {"gen": "broad", "h": 17.0, "h_var": 0.2, "bole": 0.3, "crown_r": 0.23,
		"leader": 0.9, "branches": 8, "trunk_r": 0.25, "up": 0.72, "droop": 0.05,
		"clusters": 45, "card": 2.4, "leaf": "broad", "bark": "furrowed", "tint": "birch", "evergreen": false},
	"zelkova": {"gen": "broad", "h": 16.0, "h_var": 0.2, "bole": 0.3, "crown_r": 0.4,
		"leader": 0.4, "branches": 9, "trunk_r": 0.3, "up": 0.6, "droop": 0.05,
		"clusters": 55, "card": 2.5, "leaf": "broad", "bark": "furrowed", "tint": "broad", "evergreen": false},
	"oak": {"gen": "broad", "h": 17.0, "h_var": 0.25, "bole": 0.22, "crown_r": 0.42,
		"leader": 0.25, "branches": 6, "trunk_r": 0.45, "up": 0.35, "droop": 0.05,
		"clusters": 60, "card": 3.4, "leaf": "broad", "bark": "furrowed",
		"tint": "oak", "evergreen": false},
	"birch": {"gen": "broad", "h": 16.0, "h_var": 0.25, "bole": 0.25, "crown_r": 0.19,
		"leader": 0.95, "branches": 11, "trunk_r": 0.17, "up": 0.65, "droop": 0.55,
		"clusters": 80, "card": 2.0, "leaf": "birch", "bark": "birch",
		"tint": "birch", "evergreen": false},
	"maple": {"gen": "broad", "h": 16.0, "h_var": 0.2, "bole": 0.25, "crown_r": 0.33,
		"leader": 0.65, "branches": 8, "trunk_r": 0.28, "up": 0.5, "droop": 0.1,
		"clusters": 58, "card": 2.8, "leaf": "broad", "bark": "furrowed",
		"tint": "broad", "evergreen": false},
	"rowan": {"gen": "broad", "h": 9.0, "h_var": 0.2, "bole": 0.22, "crown_r": 0.31,
		"leader": 0.7, "branches": 7, "trunk_r": 0.16, "up": 0.5, "droop": 0.15,
		"clusters": 42, "card": 2.0, "leaf": "birch", "bark": "furrowed",
		"tint": "broad", "evergreen": false},
	"olive": {"gen": "broad", "h": 7.0, "h_var": 0.2, "bole": 0.28, "crown_r": 0.48,
		"leader": 0.2, "branches": 5, "trunk_r": 0.28, "up": 0.45, "droop": 0.1,
		"clusters": 40, "card": 2.2, "leaf": "olive", "bark": "furrowed",
		"tint": "olive", "evergreen": true},
	"tropical": {"gen": "broad", "h": 16.0, "h_var": 0.3, "bole": 0.35, "crown_r": 0.45,
		"leader": 0.3, "branches": 7, "trunk_r": 0.32, "up": 0.4, "droop": 0.05,
		"clusters": 60, "card": 3.4, "leaf": "broad", "bark": "plane",
		"tint": "tropical", "evergreen": true},
	"scots_pine": {"gen": "broad", "h": 21.0, "h_var": 0.2, "bole": 0.62, "crown_r": 0.17,
		"leader": 0.85, "branches": 9, "trunk_r": 0.28, "up": 0.3, "droop": 0.0,
		"clusters": 40, "card": 2.4, "leaf": "pine", "bark": "pine",
		"tint": "pine", "evergreen": true},
	"stone_pine": {"gen": "broad", "h": 14.0, "h_var": 0.2, "bole": 0.58, "crown_r": 0.52,
		"leader": 0.15, "branches": 7, "trunk_r": 0.32, "up": 0.75, "droop": 0.0,
		"clusters": 48, "card": 2.8, "leaf": "pine", "bark": "pine",
		"tint": "pine", "evergreen": true, "flat_top": true},
	"spruce": {"gen": "conifer", "h": 25.0, "h_var": 0.25, "crown_base": 0.05,
		"base_r": 0.18, "whorl": 0.85, "per_whorl": 6, "pitch": -0.12, "droop": 0.35,
		"trunk_r": 0.32, "leaf": "needle", "bark": "spruce", "tint": "spruce",
		"evergreen": true, "column": false},
	"cypress": {"gen": "conifer", "h": 14.0, "h_var": 0.2, "crown_base": 0.04,
		"base_r": 0.1, "whorl": 0.5, "per_whorl": 5, "pitch": 1.0, "droop": 0.0,
		"trunk_r": 0.2, "leaf": "cypress", "bark": "furrowed", "tint": "cypress",
		"evergreen": true, "column": true},
	"palm": {"gen": "palm", "h": 11.0, "h_var": 0.3, "fronds": 15, "frond_len": 4.2,
		"trunk_r": 0.22, "leaf": "palm", "bark": "palm", "tint": "palm",
		"evergreen": true},
	# Pacific-coast summer-dry trees (dry_coast): the broad, flat-topped,
	# wind-sheared Monterey cypress of the headlands and parks; tall, open,
	# grey-green eucalyptus; and the dense dark evergreen street tree of
	# coastal California and the Cape (Metrosideros, Lophostemon, Ficus).
	"monterey_cypress": {"gen": "broad", "h": 18.0, "h_var": 0.25, "bole": 0.22, "crown_r": 0.55,
		"leader": 0.2, "branches": 6, "trunk_r": 0.42, "up": 0.3, "droop": 0.0,
		"clusters": 52, "card": 3.2, "leaf": "cypress", "bark": "furrowed",
		"tint": "cypress", "evergreen": true, "flat_top": true},
	"eucalyptus": {"gen": "broad", "h": 30.0, "h_var": 0.3, "bole": 0.45, "crown_r": 0.24,
		"leader": 0.7, "branches": 7, "trunk_r": 0.42, "up": 0.65, "droop": 0.35,
		"clusters": 44, "card": 2.6, "leaf": "olive", "bark": "plane",
		"tint": "eucalyptus", "evergreen": true},
	# Khmer open woodland (the Angkor park): the tall, clear-boled
	# dipterocarps (Dipterocarpus alatus, chheuteal) with small high
	# crowns, the buttressed pale silk-cotton / spung trees of the temple
	# courts (Ceiba, Tetrameles; bare in the dry season) and the sugar
	# palm (Borassus flabellifer, a stiff round fan crown on a tall stem).
	"dipterocarp": {"gen": "broad", "h": 30.0, "h_var": 0.25, "bole": 0.52, "crown_r": 0.28,
		"leader": 0.45, "branches": 8, "trunk_r": 0.5, "up": 0.55, "droop": 0.0,
		"clusters": 62, "card": 3.6, "leaf": "broad", "bark": "furrowed",
		"tint": "dipterocarp", "evergreen": true, "flat_top": true},
	"silk_cotton": {"gen": "broad", "h": 28.0, "h_var": 0.25, "bole": 0.5, "crown_r": 0.36,
		"leader": 0.3, "branches": 6, "trunk_r": 0.62, "up": 0.3, "droop": 0.05,
		"clusters": 44, "card": 3.4, "leaf": "broad", "bark": "plane",
		"tint": "silk_cotton", "evergreen": false, "flat_top": true},
	"sugar_palm": {"gen": "palm", "h": 17.0, "h_var": 0.25, "fronds": 24, "frond_len": 2.5,
		"trunk_r": 0.3, "leaf": "palm", "bark": "palm", "tint": "sugar_palm",
		"evergreen": true},
	"metrosideros": {"gen": "broad", "h": 9.0, "h_var": 0.25, "bole": 0.2, "crown_r": 0.5,
		"leader": 0.3, "branches": 6, "trunk_r": 0.3, "up": 0.45, "droop": 0.05,
		"clusters": 56, "card": 2.6, "leaf": "broad", "bark": "furrowed",
		"tint": "evergreen", "evergreen": true},
	# South Florida / Miami subtropical coastal & avenue flora: straight grey
	# Cuban royal palms with smooth green crownshafts, leaning coconut palms,
	# round-crowned sabal palmettos, wide spreading live oaks and banyans with
	# aerial prop trunks, scarlet-blooming royal poincianas, dune sea grapes
	# and coastal mangroves on arching prop-root stilts.
	"royal_palm": {"gen": "palm", "h": 20.0, "h_var": 0.2, "fronds": 16, "frond_len": 4.6,
		"trunk_r": 0.28, "lean_k": 0.015, "crownshaft": 2.1, "leaf": "palm", "bark": "plane",
		"tint": "palm", "evergreen": true},
	"coconut_palm": {"gen": "palm", "h": 14.0, "h_var": 0.28, "fronds": 14, "frond_len": 4.8,
		"trunk_r": 0.21, "lean_k": 0.22, "droop_k": 0.36, "leaf": "palm", "bark": "palm",
		"tint": "palm", "evergreen": true},
	"sabal_palm": {"gen": "palm", "h": 9.0, "h_var": 0.22, "fronds": 20, "frond_len": 2.4,
		"trunk_r": 0.24, "lean_k": 0.04, "leaf": "palm", "bark": "furrowed",
		"tint": "sugar_palm", "evergreen": true},
	"live_oak": {"gen": "broad", "h": 12.0, "h_var": 0.22, "bole": 0.20, "crown_r": 0.56,
		"leader": 0.22, "branches": 7, "trunk_r": 0.44, "up": 0.28, "droop": 0.12,
		"clusters": 62, "card": 3.2, "leaf": "olive", "bark": "furrowed",
		"tint": "evergreen", "evergreen": true},
	"banyan": {"gen": "broad", "h": 16.0, "h_var": 0.25, "bole": 0.24, "crown_r": 0.58,
		"leader": 0.25, "branches": 8, "trunk_r": 0.58, "up": 0.32, "droop": 0.15,
		"clusters": 68, "card": 3.5, "aerial_roots": 6, "leaf": "broad", "bark": "plane",
		"tint": "tropical", "evergreen": true},
	"royal_poinciana": {"gen": "broad", "h": 11.0, "h_var": 0.2, "bole": 0.32, "crown_r": 0.58,
		"leader": 0.18, "branches": 7, "trunk_r": 0.30, "up": 0.65, "droop": 0.05,
		"clusters": 54, "card": 3.0, "leaf": "birch", "bark": "plane",
		"tint": "poinciana", "evergreen": true, "flat_top": true},
	"sea_grape": {"gen": "broad", "h": 4.2, "h_var": 0.25, "bole": 0.14, "crown_r": 0.55,
		"leader": 0.25, "branches": 5, "trunk_r": 0.16, "up": 0.4, "droop": 0.05,
		"clusters": 36, "card": 2.0, "leaf": "broad", "bark": "plane",
		"tint": "tropical", "evergreen": true},
	"mangrove": {"gen": "broad", "h": 5.2, "h_var": 0.25, "bole": 0.26, "crown_r": 0.50,
		"leader": 0.3, "branches": 6, "trunk_r": 0.18, "up": 0.45, "droop": 0.08,
		"clusters": 42, "card": 2.2, "aerial_roots": 7, "leaf": "olive", "bark": "furrowed",
		"tint": "tropical", "evergreen": true},
	# Southeast Asian & Bangkok urban/temple/canal trees (BK-8.1):
	# rain tree (Samanea saman, wide flat umbrella), mahogany, Burmese rosewood (pradu),
	# tamarind (Sanam Luang ring), golden shower (Cassia fistula, yellow in dry season),
	# sacred bodhi fig, frangipani, areca palm, mango & banana (reuses royal_palm, banyan, coconut_palm).
	"rain_tree": {"gen": "broad", "h": 15.5, "h_var": 0.22, "bole": 0.34, "crown_r": 0.62,
		"leader": 0.18, "branches": 8, "trunk_r": 0.42, "up": 0.68, "droop": 0.05,
		"clusters": 64, "card": 3.4, "leaf": "broad", "bark": "furrowed",
		"tint": "tropical", "evergreen": true, "flat_top": true},
	"mahogany": {"gen": "broad", "h": 16.0, "h_var": 0.20, "bole": 0.32, "crown_r": 0.36,
		"leader": 0.65, "branches": 8, "trunk_r": 0.34, "up": 0.55, "droop": 0.05,
		"clusters": 58, "card": 3.0, "leaf": "broad", "bark": "furrowed",
		"tint": "tropical", "evergreen": true},
	"pradu": {"gen": "broad", "h": 15.0, "h_var": 0.22, "bole": 0.30, "crown_r": 0.46,
		"leader": 0.35, "branches": 7, "trunk_r": 0.34, "up": 0.45, "droop": 0.28,
		"clusters": 60, "card": 3.1, "leaf": "broad", "bark": "furrowed",
		"tint": "pradu", "evergreen": true},
	"tamarind": {"gen": "broad", "h": 13.5, "h_var": 0.18, "bole": 0.28, "crown_r": 0.42,
		"leader": 0.40, "branches": 8, "trunk_r": 0.36, "up": 0.48, "droop": 0.18,
		"clusters": 62, "card": 2.4, "leaf": "birch", "bark": "furrowed",
		"tint": "tamarind", "evergreen": true},
	"golden_shower": {"gen": "broad", "h": 11.5, "h_var": 0.20, "bole": 0.30, "crown_r": 0.38,
		"leader": 0.45, "branches": 7, "trunk_r": 0.24, "up": 0.50, "droop": 0.22,
		"clusters": 52, "card": 2.5, "leaf": "birch", "bark": "plane",
		"tint": "golden_shower", "evergreen": true},
	"bodhi": {"gen": "broad", "h": 17.0, "h_var": 0.24, "bole": 0.24, "crown_r": 0.52,
		"leader": 0.30, "branches": 8, "trunk_r": 0.48, "up": 0.42, "droop": 0.12,
		"clusters": 64, "card": 3.2, "leaf": "broad", "bark": "plane",
		"tint": "tropical", "evergreen": true},
	"frangipani": {"gen": "broad", "h": 6.2, "h_var": 0.20, "bole": 0.32, "crown_r": 0.50,
		"leader": 0.22, "branches": 5, "trunk_r": 0.18, "up": 0.58, "droop": 0.0,
		"clusters": 36, "card": 2.0, "leaf": "broad", "bark": "plane",
		"tint": "tropical", "evergreen": true, "flat_top": true},
	"areca_palm": {"gen": "palm", "h": 8.5, "h_var": 0.22, "fronds": 14, "frond_len": 2.8,
		"trunk_r": 0.15, "leaf": "palm", "bark": "palm", "tint": "tamarind", "evergreen": true},
	"mango": {"gen": "broad", "h": 11.5, "h_var": 0.22, "bole": 0.25, "crown_r": 0.46,
		"leader": 0.35, "branches": 7, "trunk_r": 0.30, "up": 0.45, "droop": 0.12,
		"clusters": 54, "card": 2.8, "leaf": "broad", "bark": "furrowed",
		"tint": "tropical", "evergreen": true},
	"banana": {"gen": "palm", "h": 4.8, "h_var": 0.20, "fronds": 10, "frond_len": 2.4,
		"trunk_r": 0.14, "leaf": "palm", "bark": "palm", "tint": "tamarind", "evergreen": true},
	# Singapore Garden City signature species (SG-6.1): yellow flame (Peltophorum),
	# heritage tembusu (Cyrtophyllum, spreading rugged crown), sea almond (Terminalia, tiered whorls).
	"yellow_flame": {"gen": "broad", "h": 15.0, "h_var": 0.20, "bole": 0.30, "crown_r": 0.52,
		"leader": 0.24, "branches": 8, "trunk_r": 0.36, "up": 0.58, "droop": 0.08,
		"clusters": 60, "card": 3.0, "leaf": "birch", "bark": "furrowed",
		"tint": "golden_shower", "evergreen": true, "flat_top": true},
	"tembusu": {"gen": "broad", "h": 18.0, "h_var": 0.22, "bole": 0.28, "crown_r": 0.50,
		"leader": 0.42, "branches": 8, "trunk_r": 0.46, "up": 0.44, "droop": 0.12,
		"clusters": 64, "card": 3.2, "leaf": "broad", "bark": "furrowed",
		"tint": "tropical", "evergreen": true},
	"sea_almond": {"gen": "broad", "h": 14.0, "h_var": 0.20, "bole": 0.34, "crown_r": 0.54,
		"leader": 0.65, "branches": 9, "trunk_r": 0.30, "up": 0.25, "droop": 0.04,
		"clusters": 58, "card": 3.1, "leaf": "broad", "bark": "plane",
		"tint": "tropical", "evergreen": true, "flat_top": true},
}

## Season tints (sRGB), applied over the near-neutral leaf atlases:
## [spring, summer, autumn, winter]. Winter on deciduous species is the
## bare-branch mesh, so its entry is the evergreen winter shade.
const TINTS := {
	"broad": [Color(0.50, 0.66, 0.30), Color(0.36, 0.50, 0.24), Color(0.86, 0.56, 0.22), Color(0.3, 0.4, 0.22)],
	"lime": [Color(0.54, 0.70, 0.30), Color(0.38, 0.54, 0.24), Color(0.90, 0.74, 0.28), Color(0.3, 0.4, 0.22)],
	"oak": [Color(0.52, 0.64, 0.30), Color(0.33, 0.46, 0.22), Color(0.70, 0.46, 0.20), Color(0.3, 0.4, 0.22)],
	"birch": [Color(0.58, 0.74, 0.32), Color(0.44, 0.60, 0.26), Color(0.95, 0.80, 0.28), Color(0.3, 0.4, 0.22)],
	"olive": [Color(0.52, 0.58, 0.42), Color(0.48, 0.54, 0.38), Color(0.48, 0.53, 0.38), Color(0.45, 0.50, 0.37)],
	"tropical": [Color(0.30, 0.50, 0.20), Color(0.27, 0.46, 0.18), Color(0.30, 0.46, 0.20), Color(0.27, 0.44, 0.18)],
	"pine": [Color(0.34, 0.46, 0.25), Color(0.30, 0.42, 0.22), Color(0.30, 0.41, 0.22), Color(0.26, 0.36, 0.21)],
	"spruce": [Color(0.24, 0.37, 0.22), Color(0.21, 0.34, 0.20), Color(0.21, 0.33, 0.20), Color(0.19, 0.29, 0.19)],
	"cypress": [Color(0.24, 0.37, 0.20), Color(0.22, 0.35, 0.19), Color(0.22, 0.34, 0.19), Color(0.20, 0.31, 0.18)],
	"palm": [Color(0.40, 0.54, 0.25), Color(0.38, 0.52, 0.24), Color(0.40, 0.52, 0.25), Color(0.38, 0.50, 0.24)],
	"eucalyptus": [Color(0.46, 0.54, 0.42), Color(0.43, 0.51, 0.40), Color(0.43, 0.50, 0.40), Color(0.41, 0.48, 0.38)],
	"dipterocarp": [Color(0.38, 0.52, 0.22), Color(0.33, 0.48, 0.20), Color(0.40, 0.48, 0.22), Color(0.44, 0.46, 0.24)],
	"silk_cotton": [Color(0.46, 0.60, 0.26), Color(0.40, 0.55, 0.24), Color(0.62, 0.56, 0.26), Color(0.3, 0.4, 0.22)],
	"sugar_palm": [Color(0.36, 0.48, 0.26), Color(0.34, 0.46, 0.25), Color(0.38, 0.46, 0.26), Color(0.42, 0.46, 0.28)],
	"pradu": [Color(0.36, 0.54, 0.22), Color(0.31, 0.49, 0.20), Color(0.34, 0.50, 0.21), Color(0.32, 0.47, 0.20)],
	"tamarind": [Color(0.42, 0.60, 0.26), Color(0.37, 0.55, 0.23), Color(0.40, 0.56, 0.25), Color(0.38, 0.52, 0.24)],
	"golden_shower": [Color(0.86, 0.72, 0.18), Color(0.38, 0.54, 0.22), Color(0.40, 0.54, 0.23), Color(0.78, 0.66, 0.20)],
	"poinciana": [Color(0.56, 0.52, 0.24), Color(0.78, 0.28, 0.16), Color(0.36, 0.52, 0.22), Color(0.34, 0.48, 0.22)],
	"evergreen": [Color(0.24, 0.38, 0.19), Color(0.21, 0.34, 0.17), Color(0.21, 0.34, 0.17), Color(0.20, 0.32, 0.17)],
}

## Bark colour behind impostor bark pixels (impostors store luminance).
const BARK_TINT := {
	"plane_grey": Color(0.30, 0.28, 0.25), "birch_grey": Color(0.40, 0.385, 0.36),
	"furrowed_grey": Color(0.22, 0.205, 0.185),
	"plane": Color(0.62, 0.60, 0.48), "furrowed": Color(0.40, 0.35, 0.30),
	"pine": Color(0.55, 0.36, 0.24), "birch": Color(0.80, 0.79, 0.75),
	"spruce": Color(0.38, 0.30, 0.25), "palm": Color(0.48, 0.42, 0.33),
}

## Stockholm's avenues show greyer, darker bark than the shared kinds: the cream camouflage of the planes,
## the white of the birches and the furrowed tan all read as pale poles in the low sun. A species name
## plus GREY_SUFFIX is that species with the darker bark kind (spec).
const GREY_SUFFIX := "_grey"
const GREY_BARK := {"plane": "plane_grey", "birch": "birch_grey", "furrowed": "furrowed_grey"}

## Stockholm's species for a mix pick: the same tree with the darker bark where it has a pale one.
static func stockholm_species(sp: String) -> String:
	if sp.ends_with(GREY_SUFFIX) or not GREY_BARK.has(str(spec(sp).get("bark", ""))):
		return sp
	return sp + GREY_SUFFIX

static func names() -> Array:
	return SPECIES.keys()

static func spec(name: String) -> Dictionary:
	if SPECIES.has(name):
		return SPECIES[name]
	var base := name.trim_suffix(GREY_SUFFIX)
	if base != name and GREY_BARK.has(str(SPECIES.get(base, {}).get("bark", ""))):
		return _grey_spec(base)
	return SPECIES["lime"]

static var _grey: Dictionary = {}
static var _grey_mutex := Mutex.new()

## `base` with Stockholm's darker bark (a copy; the shared species is untouched).
static func _grey_spec(base: String) -> Dictionary:
	_grey_mutex.lock()
	if not _grey.has(base):
		var d: Dictionary = (SPECIES[base] as Dictionary).duplicate()
		d["bark"] = GREY_BARK[str(d["bark"])]
		_grey[base] = d
	var out: Dictionary = _grey[base]
	_grey_mutex.unlock()
	return out

static func is_evergreen(name: String) -> bool:
	return bool(spec(name).get("evergreen", false))

static func tint(name: String, season: int) -> Color:
	var row: Array = TINTS.get(str(spec(name).get("tint", "broad")), TINTS["broad"])
	return row[LocationData.clamp_season(season)]

## Per-species autumn phenology profile: (deciduous 0/1, onset offset, crimson weight).
static func autumn_meta(name: String) -> Vector3:
	if is_evergreen(name):
		return Vector3.ZERO
	var base := name.trim_suffix(GREY_SUFFIX)
	match base:
		"birch", "horse_chestnut", "ginkgo":
			return Vector3(1.0, -0.14, 0.05)
		"maple", "rowan":
			return Vector3(1.0, -0.05, 0.80)
		"oak":
			return Vector3(1.0, 0.14, 0.25)
		"silk_cotton":
			return Vector3(0.5, 0.0, 0.0)
	return Vector3(1.0, 0.0, 0.15)

## Approximate share of deciduous trees in a biome's forest canopy (for FarSurface).
static func deciduous_share_for_biome(biome: String) -> float:
	match biome:
		"tropical", "miami", "khmer", "arid":
			return 0.0
		"mediterranean", "dry_coast":
			return 0.20
		"alpine":
			return 0.28
		"boreal":
			return 0.38
	return 0.68

## Biome for a place: coarse climate from the architecture region,
## latitude, and the viewpoint altitude (metres ASL).
## Biome for a place: the CHELSA climate class (ClimateModel) where the
## climate is known, keeping the regional species flavour where climate
## and region agree it is temperate (alpine / east Asian mixes); the
## regional + latitude rule below otherwise.
static func biome_for_data(data: LocationData) -> String:
	var regional := biome_for(data.latitude, data.longitude, data.centre_elevation_m, data.country)
	var climatic := ClimateModel.biome(data)
	if climatic == "":
		return regional
	if climatic == "temperate" and regional in ["alpine", "east_asia"]:
		return regional
	# Summer-dry climates outside the Mediterranean basin (California,
	# central Chile, the Cape, SW Australia): live oak, pine and cypress
	# rather than the olive / stone pine / palm of the Old World mix.
	if climatic == "mediterranean" and regional not in ["mediterranean", "arid"]:
		return "dry_coast"
	return climatic

static func biome_for(lat: float, lon: float, altitude_m: float, country: String = "") -> String:
	var region := ArchitectureStyle.country_region_for(lat, lon, country)
	var alat := absf(lat)
	if alat < 23.5 or (region == "southeast_asia" and alat < 18.0):
		return "tropical"
	if region == "alpine" or altitude_m > 900.0:
		return "alpine"
	if region == "nordic" or alat > 58.0:
		return "boreal"
	if region in ["east_asia", "japan"]:
		return "east_asia"
	if region == "middle_east":
		return "arid"
	if region == "mediterranean" or alat < 36.0:
		return "mediterranean"
	return "temperate"

## Weighted species mix for a biome + setting ("street" = OSM tree
## nodes/parks in a built-up place, "forest", "park", "rural").
static func bangkok_mix(setting: String, denotation: String = "", district: String = "") -> Array:
	if district == "bangkok_thonburi":
		return [["tropical", 0.45], ["coconut_palm", 0.30], ["banyan", 0.15], ["palm", 0.10]]
	if setting == "street" or denotation == "avenue":
		return [["tropical", 0.55], ["live_oak", 0.25], ["royal_poinciana", 0.15], ["palm", 0.05]]
	if setting == "park":
		return [["tropical", 0.45], ["royal_poinciana", 0.20], ["banyan", 0.15], ["royal_palm", 0.20]]
	return [["tropical", 0.50], ["banyan", 0.25], ["royal_poinciana", 0.15], ["palm", 0.10]]

static func mix(biome: String, setting: String) -> Array:
	match biome:
		"tropical":
			return [["palm", 0.45], ["tropical", 0.55]]
		"singapore":
			# Garden City (SG-6.1): wide-umbrella rain tree avenues, angsana/pradu, yellow flame,
			# heritage tembusu & banyan in parks, sea almond & coconut palms on the coast.
			if setting == "street":
				return [["rain_tree", 0.38], ["pradu", 0.18], ["yellow_flame", 0.14], ["mahogany", 0.12],
					["royal_palm", 0.10], ["areca_palm", 0.08]]
			if setting == "shore":
				return [["sea_almond", 0.32], ["coconut_palm", 0.28], ["rain_tree", 0.20], ["mangrove", 0.12],
					["royal_palm", 0.08]]
			if setting == "forest":
				return [["tembusu", 0.28], ["banyan", 0.24], ["tropical", 0.22], ["rain_tree", 0.16],
					["areca_palm", 0.10]]
			return [["rain_tree", 0.30], ["tembusu", 0.20], ["banyan", 0.16], ["yellow_flame", 0.12],
				["royal_palm", 0.12], ["frangipani", 0.10]]
		"miami":
			if setting == "street":
				return [["royal_palm", 0.34], ["coconut_palm", 0.16], ["sabal_palm", 0.14], ["live_oak", 0.16],
					["royal_poinciana", 0.10], ["banyan", 0.06], ["sea_grape", 0.04]]
			if setting == "shore":
				return [["coconut_palm", 0.34], ["sea_grape", 0.24], ["sabal_palm", 0.18], ["mangrove", 0.16],
					["royal_palm", 0.08]]
			if setting == "forest":
				return [["live_oak", 0.26], ["sabal_palm", 0.20], ["coconut_palm", 0.18], ["mangrove", 0.16],
					["banyan", 0.12], ["royal_poinciana", 0.08]]
			return [["royal_palm", 0.24], ["coconut_palm", 0.22], ["sabal_palm", 0.16], ["live_oak", 0.14],
				["banyan", 0.12], ["royal_poinciana", 0.08], ["sea_grape", 0.04]]
		"nyc_park":
			# Central Park: American elms (the vase-shaped zelkova form, the
			# same family) along the Mall and drives, oaks, London planes,
			# maples, lindens and honey locusts, a few pines.
			return [["zelkova", 0.24], ["oak", 0.24], ["plane", 0.16], ["maple", 0.14], ["lime", 0.1],
				["honey_locust", 0.06], ["scots_pine", 0.04], ["birch", 0.02]]
		"amsterdam":
			# Amsterdam Grachtengordel & Vondelpark: iconic Dutch elms (vase-
			# shaped zelkova family), common limes along canal quays, and planes.
			return [["zelkova", 0.52], ["lime", 0.30], ["plane", 0.14], ["oak", 0.04]]
		"stockholm_park":
			# Royal Djurgården: the old oaks of the hunting park, lime,
			# birch, maple, and spruce and pine on the rocky ground.
			if setting == "street":
				return [["lime", 0.35], ["oak", 0.3], ["maple", 0.15], ["birch", 0.1], ["rowan", 0.1]]
			return [["oak", 0.4], ["lime", 0.12], ["birch", 0.16], ["maple", 0.08], ["spruce", 0.12],
				["scots_pine", 0.12]]
		"lime_avenue":
			# The lime-lined walks of Kungsträdgården and Humlegården.
			return [["lime", 0.78], ["zelkova", 0.12], ["maple", 0.06], ["birch", 0.04]]
		"khmer":
			return [["dipterocarp", 0.35], ["sugar_palm", 0.22], ["tropical", 0.2], ["silk_cotton", 0.15],
				["palm", 0.08]]
		"arid":
			return [["palm", 0.4], ["olive", 0.3], ["cypress", 0.2], ["plane", 0.1]]
		"mediterranean":
			if setting == "forest":
				return [["stone_pine", 0.45], ["olive", 0.15], ["oak", 0.25], ["cypress", 0.15]]
			if setting == "street":
				return [["plane", 0.55], ["lime", 0.1], ["stone_pine", 0.15], ["palm", 0.1], ["cypress", 0.1]]
			return [["stone_pine", 0.3], ["olive", 0.25], ["cypress", 0.2], ["plane", 0.15], ["palm", 0.1]]
		"dry_coast":
			if setting == "forest":
				return [["oak", 0.35], ["monterey_cypress", 0.2], ["eucalyptus", 0.2], ["scots_pine", 0.15],
					["cypress", 0.1]]
			if setting == "street":
				return [["metrosideros", 0.3], ["plane", 0.25], ["palm", 0.12], ["lime", 0.1], ["oak", 0.08],
					["eucalyptus", 0.05], ["cypress", 0.05], ["monterey_cypress", 0.05]]
			return [["oak", 0.35], ["monterey_cypress", 0.2], ["eucalyptus", 0.15], ["scots_pine", 0.15],
				["cypress", 0.1], ["plane", 0.05]]
		"boreal":
			if setting == "forest":
				return [["spruce", 0.42], ["scots_pine", 0.33], ["birch", 0.25]]
			if setting == "street":
				return [["lime", 0.4], ["birch", 0.3], ["maple", 0.2], ["rowan", 0.1]]
			return [["birch", 0.4], ["spruce", 0.25], ["scots_pine", 0.2], ["lime", 0.15]]
		"alpine":
			if setting == "forest":
				return [["spruce", 0.65], ["scots_pine", 0.1], ["lime", 0.15], ["birch", 0.1]]
			if setting == "street":
				return [["lime", 0.45], ["plane", 0.2], ["oak", 0.1], ["birch", 0.1], ["spruce", 0.15]]
			return [["spruce", 0.4], ["lime", 0.25], ["oak", 0.15], ["birch", 0.2]]
		"east_asia":
			if setting == "street":
				return [["plane", 0.45], ["lime", 0.3], ["scots_pine", 0.15], ["oak", 0.1]]
			return [["oak", 0.3], ["lime", 0.25], ["scots_pine", 0.25], ["spruce", 0.2]]
	if setting == "forest":
		return [["oak", 0.35], ["lime", 0.2], ["spruce", 0.2], ["scots_pine", 0.1], ["birch", 0.15]]
	if setting == "street":
		return [["plane", 0.5], ["lime", 0.3], ["oak", 0.1], ["birch", 0.1]]
	return [["oak", 0.3], ["lime", 0.3], ["plane", 0.2], ["birch", 0.2]]

## OSM genus (Latin, lowercased) → the nearest modelled species.
const GENUS := {
	"platanus": "plane", "tilia": "lime", "quercus": "oak", "fagus": "oak",
	"castanea": "oak", "carpinus": "oak", "juglans": "oak",
	"acer": "lime", "aesculus": "horse_chestnut", "ulmus": "zelkova", "fraxinus": "lime",
	"robinia": "lime", "prunus": "lime", "sorbus": "lime", "malus": "lime",
	"celtis": "lime", "styphnolobium": "lime", "sophora": "lime", "gleditsia": "honey_locust",
	"pyrus": "callery_pear", "magnolia": "lime", "ginkgo": "ginkgo", "zelkova": "zelkova",
	"liquidambar": "oak", "liriodendron": "plane", "paulownia": "plane", "catalpa": "plane",
	"betula": "birch", "populus": "birch", "salix": "birch", "alnus": "birch",
	"olea": "olive", "ceratonia": "olive",
	"pinus": "scots_pine", "picea": "spruce", "abies": "spruce",
	"pseudotsuga": "spruce", "larix": "spruce", "tsuga": "spruce",
	"cupressus": "cypress", "juniperus": "cypress", "thuja": "cypress",
	"hesperocyparis": "monterey_cypress", "eucalyptus": "eucalyptus", "corymbia": "eucalyptus",
	"metrosideros": "metrosideros", "lophostemon": "metrosideros", "ficus": "banyan",
	"pittosporum": "metrosideros", "tristaniopsis": "metrosideros", "arbutus": "olive",
	"taxus": "cypress", "sequoia": "spruce", "sequoiadendron": "spruce",
	"cedrus": "stone_pine",
	"phoenix": "palm", "washingtonia": "palm", "trachycarpus": "palm",
	"cocos": "coconut_palm", "roystonea": "royal_palm", "sabal": "sabal_palm", "syagrus": "palm",
	"delonix": "royal_poinciana", "coccoloba": "sea_grape",
	"rhizophora": "mangrove", "avicennia": "mangrove", "laguncularia": "mangrove",
	"conoarpus": "mangrove", "conocarpus": "mangrove",
	"bursera": "tropical", "swietenia": "mahogany",
	"samanea": "rain_tree", "albizia": "rain_tree", "pterocarpus": "pradu",
	"peltophorum": "yellow_flame", "khaya": "mahogany", "syzygium": "tembusu",
	"terminalia": "sea_almond", "cyrtophyllum": "tembusu", "fagraea": "tembusu",
	"tamarindus": "tamarind", "cassia": "golden_shower", "plumeria": "frangipani",
	"mangifera": "mango", "musa": "banana", "dypsis": "areca_palm",
}

## Boreal overrides of GENUS (Helsinki's register: Acer, Sorbus and the
## small flowering street trees are common).
const BOREAL_GENUS := {
	"acer": "maple", "sorbus": "rowan", "crataegus": "rowan",
	"laburnum": "rowan", "syringa": "rowan", "amelanchier": "rowan",
}

## Species for a mapped tree from its OSM tags (genus / species /
## leaf_type / leaf_cycle), or "" when they say nothing usable. Umbrella
## pines get their own model; an evergreen broadleaf in a dry-summer
## climate is the olive-like holm/live oak form.
static func species_from_tags(tags: Dictionary, biome: String) -> String:
	var genus := str(tags.get("genus", "")).to_lower()
	if genus == "" and tags.has("species"):
		genus = str(tags["species"]).get_slice(" ", 0).to_lower()
	if genus == "quercus" and str(tags.get("species", "")).to_lower().contains("virginiana"):
		return "live_oak"
	if genus == "pinus" and str(tags.get("species", "")).contains("pinea"):
		return "stone_pine"
	if genus == "cupressus" and str(tags.get("species", "")).contains("macrocarpa"):
		return "monterey_cypress"
	# Northern streets: maples and rowans have their own models.
	if biome == "boreal" and BOREAL_GENUS.has(genus):
		return BOREAL_GENUS[genus]
	if GENUS.has(genus):
		return GENUS[genus]
	var leaf := str(tags.get("leaf_type", ""))
	if leaf == "needleleaved":
		return conifer_for(biome)
	if leaf == "broadleaved":
		if str(tags.get("leaf_cycle", "")) == "evergreen" and biome in ["mediterranean", "dry_coast", "arid"]:
			return "olive"
		return "oak" if biome != "boreal" else "birch"
	return ""

static func conifer_for(biome: String) -> String:
	match biome:
		"mediterranean", "miami":
			return "stone_pine"
		"dry_coast", "arid":
			return "cypress"
	return "spruce"

## The biome mix narrowed to the forest's mapped leaf_type: conifers
## only for needleleaved, broadleaves only for broadleaved; "mixed" or
## unmapped keep the biome's own mix.
static func mix_for_leaf(biome: String, setting: String, leaf_type: String) -> Array:
	var base := mix(biome, setting)
	if leaf_type != "needleleaved" and leaf_type != "broadleaved":
		return base
	var want_conifer := leaf_type == "needleleaved"
	var out: Array = []
	for e in base:
		var sp := str(e[0])
		var conifer := str(spec(sp).get("gen", "")) == "conifer" or sp in ["scots_pine", "stone_pine", "monterey_cypress"]
		if conifer == want_conifer:
			out.append(e)
	if out.is_empty():
		out.append([conifer_for(biome) if want_conifer else ("birch" if biome == "boreal" else "oak"), 1.0])
	return out

## Deterministic weighted pick (u in [0, 1)).
static func pick(mix_rows: Array, u: float) -> String:
	var total := 0.0
	for r in mix_rows:
		total += float(r[1])
	var acc := 0.0
	for r in mix_rows:
		acc += float(r[1]) / total
		if u < acc:
			return str(r[0])
	return str(mix_rows[mix_rows.size() - 1][0])

## Altitude response: above the local treeline nothing grows; within
## 300 m below it conifers dominate and shrink.
static func treeline_m(lat: float) -> float:
	var alat := absf(lat)
	return clampf(2300.0 - maxf(alat - 40.0, 0.0) * 55.0, 600.0, 3900.0)
