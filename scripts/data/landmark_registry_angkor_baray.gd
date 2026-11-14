class_name LandmarkRegistryAngkorBaray
extends RefCounted

## Siem Reap batch B: the Eastern Baray temples (Pre Rup, East Mebon), the
## Jayatataka baray island Neak Pean and the Bayon-period Ta Som and
## Banteay Kdei. See LandmarkSetAngkorBaray for the builders.

static func entries() -> Array:
	return [
		{"type": "pre_rup", "name": "Pre Rup",
			"lat": 13.4350, "lon": 103.9206, "radius_m": 4500.0,
			"wiki_title": "Pre Rup", "height_m": 25.9, "clear_m": 85.0, "tree_clear_m": 55.0,
			"kind": "Temple mountain",
			"aliases": ["pre rup", "prasat pre rup", "pre rup temple", "ប្រាសាទប្រែរូប"]},
		{"type": "east_mebon", "name": "East Mebon",
			"lat": 13.4466, "lon": 103.9202, "radius_m": 4500.0,
			"wiki_title": "East Mebon", "height_m": 18.3, "clear_m": 85.0, "tree_clear_m": 60.0,
			"kind": "Temple",
			"aliases": ["east mebon", "eastern mebon", "mebon oriental", "ប្រាសាទមេបុណ្យខាងកើត"]},
		{"type": "ta_som", "name": "Ta Som",
			"lat": 13.4645, "lon": 103.9132, "radius_m": 4500.0,
			"wiki_title": "Ta Som", "height_m": 17.0, "clear_m": 145.0, "tree_clear_m": 15.0,
			"kind": "Temple", "aliases": ["ta som", "prasat ta som", "ta som temple", "ប្រាសាទតាសោម"]},
		{"type": "neak_pean", "name": "Neak Pean",
			"lat": 13.4632, "lon": 103.8948, "radius_m": 4500.0,
			"wiki_title": "Neak Pean", "height_m": 9.6, "clear_m": 70.0, "tree_clear_m": 45.0,
			"kind": "Island temple",
			"aliases": ["neak pean", "neak poan", "neak pean temple", "entwined serpents", "នាគព័ន្ធ"]},
		{"type": "banteay_kdei", "name": "Banteay Kdei",
			"lat": 13.4300, "lon": 103.8986, "radius_m": 4500.0,
			"wiki_title": "Banteay Kdei", "height_m": 13.8, "clear_m": 170.0, "tree_clear_m": 25.0,
			"kind": "Temple",
			"aliases": ["banteay kdei", "banteay kdey", "citadel of chambers", "ប្រាសាទបន្ទាយក្តី"]},
	]
