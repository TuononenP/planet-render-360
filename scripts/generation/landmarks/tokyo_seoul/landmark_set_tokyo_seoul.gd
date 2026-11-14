class_name LandmarkSetTokyoSeoul
extends RefCounted

## Builders of the Tokyo / Seoul landmark batch: one `match` arm per
## registry type of LandmarkRegistryTokyoSeoul. Returns false for a type it
## does not own so LandmarkBuilder tries the next set.

static func build(model: Node3D, type: String) -> bool:
	match type:
		"shibuya_scramble_square": LandmarkTsShibuyaTowers.scramble_square(model)
		"shibuya_hikarie": LandmarkTsShibuyaTowers.hikarie(model)
		"shibuya_stream": LandmarkTsShibuyaTowers.stream(model)
		"shibuya_109": LandmarkTsShibuyaCrossing.shibuya_109(model)
		"qfront": LandmarkTsShibuyaCrossing.qfront(model)
		"king_sejong_statue": LandmarkTsStatues.king_sejong(model)
		"yi_sun_sin_statue": LandmarkTsStatues.yi_sun_sin(model)
		"gyeongbokgung_walls": LandmarkTsPalaceWalls.build(model)
		"heungnyemun": LandmarkTsGyeongbokgung.heungnyemun(model)
		"geunjeongjeon": LandmarkTsGyeongbokgung.geunjeongjeon(model)
		_:
			return false
	return true
