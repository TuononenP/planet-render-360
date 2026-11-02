class_name LandmarkSetRomeLater
extends RefCounted

## Builders of the rome_later landmark batch: one `match` arm per
## registry type of LandmarkRegistryRomeLater. Returns false for a type it does
## not own so LandmarkBuilder tries the next set.

static func build(model: Node3D, type: String) -> bool:
	match type:
		"piazza_navona": LandmarkRmLBaroque.navona(model)
		"il_gesu": LandmarkRmLChurches.gesu(model)
		"sant_ivo_alla_sapienza": LandmarkRmLChurches.ivo(model)
		"spanish_steps": LandmarkRmLPiazzas.steps(model)
		"piazza_del_popolo": LandmarkRmLPiazzas.popolo(model)
		"capitoline_hill": LandmarkRmLHills.capitoline(model)
		"quirinal_palace": LandmarkRmLHills.quirinal(model)
		"santa_maria_maggiore": LandmarkRmLMajor.maggiore(model)
		"st_john_lateran": LandmarkRmLMajor.lateran(model)
		"st_paul_outside_the_walls": LandmarkRmLPaul.paul(model)
		"santa_maria_in_trastevere": LandmarkRmLPaul.trastevere(model)
		"palazzo_civilta_italiana": LandmarkRmLModern.civilta(model)
		"stadio_olimpico": LandmarkRmLModern.olimpico(model)
		"sistine_chapel": LandmarkRmLModern.sistine(model)
		_:
			return false
	return true
