class_name LandmarkRegistrySingapore
extends RefCounted

## Registry entries for the Singapore hero city batch (`PLAN_Singapore_super_realistic.md`,
## `docs/singapore-landmark-sources.md`):
## - `SgRegBay`: primary `marina_bay_sands` + 10 Marina Bay icons
## - `SgRegCivic`: 10 Civic District & Padang icons
## - `SgRegHeritage`: 11 heritage/cultural/outer icons + 3 bespoke Singapore River bridges
## - `SgTowerSpecs`: 34 named skyline towers on the independent `skyline: true` channel.

static func entries() -> Array:
	var out: Array = []
	out.append_array(SgRegBay.entries())
	out.append_array(SgRegCivic.entries())
	out.append_array(SgRegHeritage.entries())
	out.append_array(SgTowerSpecs.entries())
	return out
