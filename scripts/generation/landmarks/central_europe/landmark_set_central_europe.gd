class_name LandmarkSetCentralEurope
extends RefCounted

## Builders of the central europe landmark batch: one `match` arm per
## registry type of LandmarkRegistryCentralEurope. Returns false for a type it does
## not own so LandmarkBuilder tries the next set.

static func build(model: Node3D, type: String) -> bool:
	match type:
		"brandenburg_gate": LandmarkCeBerlin.gate(model)
		"reichstag": LandmarkCeBerlin.reichstag(model)
		"berlin_tv_tower": LandmarkCeBerlin.tv_tower(model)
		"cologne_cathedral": LandmarkCeGermany.cologne(model)
		"neuschwanstein": LandmarkCeGermany.neuschwanstein(model)
		"st_vitus_cathedral": LandmarkCeGothic.vitus(model)
		"st_stephens_vienna": LandmarkCeGothic.stephansdom(model)
		"hungarian_parliament": LandmarkCePalaces.parliament(model)
		"schonbrunn_palace": LandmarkCePalaces.schoenbrunn(model)
		"saint_basils": LandmarkCeKremlin.basil(model)
		"spasskaya_tower": LandmarkCeKremlin.spasskaya(model)
		"msu_main_building": LandmarkCeSoviet.msu(model)
		"ostankino_tower": LandmarkCeSoviet.ostankino(model)
		"motherland_calls": LandmarkCeSoviet.motherland(model)
		"hagia_sophia": LandmarkCeIstanbul.hagia_sophia(model)
		"blue_mosque": LandmarkCeIstanbul.blue_mosque(model)
		"galata_tower": LandmarkCeIstanbul.galata(model)
		_:
			return false
	return true
