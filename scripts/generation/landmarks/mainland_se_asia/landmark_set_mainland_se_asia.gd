class_name LandmarkSetMainlandSeAsia
extends RefCounted

## Builders of the mainland_se_asia landmark batch: one `match` arm per
## registry type of LandmarkRegistryMainlandSeAsia. Returns false for a type it does
## not own so LandmarkBuilder tries the next set.

static func build(model: Node3D, type: String) -> bool:
	match type:
		"grand_palace_bangkok":
			LandmarkMseBangkok.grand_palace(model)
		"wat_pho":
			LandmarkMseBangkok.wat_pho(model)
		"wat_chaiwatthanaram":
			LandmarkMseThai.chaiwatthanaram(model)
		"wat_rong_khun":
			LandmarkMseThai.rong_khun(model)
		"temple_of_literature_hanoi":
			LandmarkMseVietnam.temple_of_literature(model)
		"one_pillar_pagoda":
			LandmarkMseVietnam.one_pillar_pagoda(model)
		"hue_ngo_mon_gate":
			LandmarkMseVietnam.ngo_mon(model)
		"saigon_notre_dame":
			LandmarkMseVietnam.saigon_notre_dame(model)
		"pha_that_luang":
			LandmarkMseStupas.pha_that_luang(model)
		"ananda_temple_bagan":
			LandmarkMseStupas.ananda(model)
		_:
			return false
	return true
