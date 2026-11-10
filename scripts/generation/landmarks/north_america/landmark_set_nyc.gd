class_name LandmarkSetNyc
extends RefCounted

## Builders of LandmarkRegistryNyc: one arm per registry type. Returns false
## for a type it does not own so LandmarkBuilder tries the next set.

static func build(model: Node3D, type: String) -> bool:
	match type:
		"woolworth_building": LandmarkNycDowntown.woolworth(model)
		"forty_wall_street": LandmarkNycDowntown.forty_wall(model)
		"seventy_pine": LandmarkNycDowntown.seventy_pine(model)
		"eight_spruce": LandmarkNycDowntown.eight_spruce(model)
		"thirty_park_place": LandmarkNycDowntown.thirty_park_place(model)
		"three_wtc": LandmarkNycDowntown.three_wtc(model)
		"seven_wtc": LandmarkNycDowntown.seven_wtc(model)
		"municipal_building": LandmarkNycDowntown.municipal(model)
		"one_liberty_plaza": LandmarkNycDowntown.one_liberty(model)
		"twenty_eight_liberty": LandmarkNycDowntown.twenty_eight_liberty(model)
		"one_forty_broadway": LandmarkNycDowntown.one_forty_broadway(model)
		"fifty_six_leonard": LandmarkNycDowntown.fifty_six_leonard(model)
		"one_vanderbilt": LandmarkNycMidtown.one_vanderbilt(model)
		"bank_of_america_tower": LandmarkNycMidtown.bank_of_america(model)
		"metlife_building": LandmarkNycMidtown.metlife(model)
		"thirty_rockefeller": LandmarkNycMidtown.thirty_rock(model)
		"two_seventy_park": LandmarkNycMidtown.two_seventy_park(model)
		"four_thirty_two_park": LandmarkNycMidtown.four_thirty_two_park(model)
		"central_park_tower": LandmarkNycMidtown.central_park_tower(model)
		"thirty_hudson_yards": LandmarkNycMidtown.thirty_hudson_yards(model)
		"metlife_tower": LandmarkNycMidtown.metlife_tower(model)
		"citigroup_center": LandmarkNycMidtown.citigroup(model)
		_:
			return false
	return true
