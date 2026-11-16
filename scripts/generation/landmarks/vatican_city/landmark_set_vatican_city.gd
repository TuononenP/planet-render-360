class_name LandmarkSetVatican
extends RefCounted

## Builders of the Vatican City landmark batch: one `match` arm per
## registry type of LandmarkRegistryVatican. Returns false for a type it does
## not own so LandmarkBuilder tries the next set.

static func build(model: Node3D, type: String) -> bool:
	match type:
		"apostolic_palace": LandmarkVcPalace.palace(model)
		"paul_vi_audience_hall": LandmarkVcHall.audience(model)
		"governorate_palace": LandmarkVcHall.governorate(model)
		"vatican_gardens": LandmarkVcGrounds.gardens(model)
		"leonine_wall": LandmarkVcGrounds.tower(model)
		_:
			return false
	return true
