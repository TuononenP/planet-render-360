class_name LandmarkSetAsiaEast
extends RefCounted

## Builders of the asia east landmark batch: one `match` arm per
## registry type of LandmarkRegistryAsiaEast. Returns false for a type it does
## not own so LandmarkBuilder tries the next set.

static func build(model: Node3D, type: String) -> bool:
	match type:
		"supreme_harmony": LandmarkAeChina.supreme_harmony(model)
		"temple_of_heaven": LandmarkAeChina.temple_of_heaven(model)
		"great_wall_badaling": LandmarkAeFort.great_wall(model)
		"potala_palace": LandmarkAeFort.potala(model)
		"oriental_pearl": LandmarkAeShanghai.pearl(model)
		"shanghai_tower": LandmarkAeShanghai.shanghai_tower(model)
		"shanghai_wfc": LandmarkAeShanghai.swfc(model)
		"jin_mao": LandmarkAeShanghai.jin_mao(model)
		"cctv_hq": LandmarkAeTowers.cctv(model)
		"canton_tower": LandmarkAeTowers.canton(model)
		"bank_of_china_hk": LandmarkAeTowers.bank_of_china(model)
		"taipei_101": LandmarkAeTowers.taipei_101(model)
		"tokyo_skytree": LandmarkAeTall.skytree(model)
		"n_seoul_tower": LandmarkAeTall.n_seoul(model)
		"lotte_world_tower": LandmarkAeTall.lotte(model)
		"kinkakuji": LandmarkAeJapan.kinkakuji(model)
		"himeji_castle": LandmarkAeJapan.himeji(model)
		"itsukushima_torii": LandmarkAeJapan.torii(model)
		_:
			return false
	return true
