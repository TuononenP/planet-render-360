class_name LandmarkSetRussiaBalkans
extends RefCounted

## Builders of the russia_balkans landmark batch: one `match` arm per
## registry type of LandmarkRegistryRussiaBalkans. Returns false for a type it does
## not own so LandmarkBuilder tries the next set.

static func build(model: Node3D, type: String) -> bool:
	match type:
		"winter_palace": LandmarkRbWinterPalace.build(model)
		"st_isaacs_cathedral": LandmarkRbPetersburg.st_isaacs(model)
		"peter_paul_cathedral": LandmarkRbPetersburgChurches.peter_paul(model)
		"church_savior_on_blood": LandmarkRbPetersburgChurches.savior_on_blood(model)
		"ivan_the_great_bell_tower": LandmarkRbMoscow.ivan_great(model)
		"christ_the_saviour_cathedral": LandmarkRbMoscow.christ_saviour(model)
		"kyiv_st_sophia": LandmarkRbBalkans.kyiv_sophia(model)
		"palace_of_parliament_bucharest": LandmarkRbParliament.parliament(model)
		_:
			return false
	return true
