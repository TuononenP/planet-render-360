class_name LandmarkSetAthens
extends RefCounted

## Builders of the athens landmark batch: one `match` arm per
## registry type of LandmarkRegistryAthens. Returns false for a type it does
## not own so LandmarkBuilder tries the next set.

static func build(model: Node3D, type: String) -> bool:
	match type:
		"erechtheion": LandmarkAtAcropolis.erechtheion(model)
		"propylaea": LandmarkAtAcropolis.propylaea(model)
		"temple_of_athena_nike": LandmarkAtAcropolis.athena_nike(model)
		"odeon_of_herodes_atticus": LandmarkAtTheatres.odeon(model)
		"theatre_of_dionysus": LandmarkAtTheatres.dionysus(model)
		"panathenaic_stadium": LandmarkAtTheatres.panathenaic(model)
		"temple_of_olympian_zeus": LandmarkAtAncient.olympieion(model)
		"hadrians_arch": LandmarkAtAncient.hadrians_arch(model)
		"temple_of_hephaestus": LandmarkAtAncient.hephaestus(model)
		"stoa_of_attalos": LandmarkAtAgora.stoa(model)
		"tower_of_the_winds": LandmarkAtAgora.tower_of_winds(model)
		"lysicrates_monument": LandmarkAtAgora.lysicrates(model)
		"philopappos_monument": LandmarkAtAgora.philopappos(model)
		"hellenic_parliament": LandmarkAtModern.parliament(model)
		"zappeion": LandmarkAtModern.zappeion(model)
		"academy_of_athens": LandmarkAtModern.academy(model)
		"lycabettus_chapel": LandmarkAtChurches.lycabettus(model)
		"athens_metropolitan_cathedral": LandmarkAtChurches.cathedral(model)
		_:
			return false
	return true
