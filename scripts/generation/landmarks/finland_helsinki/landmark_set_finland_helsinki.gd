class_name LandmarkSetFinlandHelsinki
extends RefCounted

## Builders of the finland_helsinki landmark batch: one `match` arm per
## registry type of LandmarkRegistryFinlandHelsinki. Returns false for a type it does
## not own so LandmarkBuilder tries the next set.

const CentreModels = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_centre_models.gd")
const SuomenlinnaChurch = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_suomenlinna_church.gd")

static func build(model: Node3D, type: String) -> bool:
	match type:
		"otaniemi_chapel": LandmarkFhEspoo.otaniemi_chapel(model)
		"aalto_university_main": LandmarkFhAaltoMain.build(model)
		"tapiola_church": LandmarkFhEspoo.tapiola_church(model)
		"tapiola_central_tower": LandmarkFhEspoo.keskustorni(model)
		"weegee": LandmarkFhEspoo.weegee(model)
		"finago_tower": LandmarkFhKeilaniemi.finago(model)
		"kone_building": LandmarkFhKeilaniemi.kone(model)
		"keilalampi": LandmarkFhKeilaniemi.keilalampi(model)
		"espoo_cultural_centre": LandmarkFhTapiola.cultural_centre(model)
		"mantytorni": LandmarkFhTapiola.mantytorni(model)
		"tapiola_hip_flask_houses": LandmarkFhTapiola.hip_flask_houses(model)
		"niittyhuippu": LandmarkFhNiittykumpu.niittyhuippu(model)
		"niittytori_tower": LandmarkFhNiittykumpu.niittytori(model)
		"niitty_shopping_centre": LandmarkFhMalls.niitty(model)
		"niittytaival_tower": LandmarkFhNiittykumpu.niittytaival(model)
		"olari_church": LandmarkFhNiittykumpu.olari_church(model)
		"vare": LandmarkFhVare.vare(model)
		"aalto_university_metro_station": LandmarkFhVare.station(model)
		"harald_herlin_learning_centre": LandmarkFhOtaniemi.herlin(model)
		"otaniemi_water_tower": LandmarkFhOtaniemi.water_tower(model)
		"otahalli": LandmarkFhOtaniemi.otahalli(model)
		"otaniemi_power_plant": LandmarkFhOtaniemi.power_plant(model)
		"parliament_house_helsinki": LandmarkFhParliament.build(model)
		"dipoli": LandmarkFhDipoli.build(model)
		"heureka_science_centre": LandmarkFhHelsinkiModern.heureka(model)
		"lasipalatsi": LandmarkFhLasipalatsi.lasipalatsi(model)
		"suomenlinna_fortress": SuomenlinnaChurch.build(model)
		"kruunuvuorensilta": LandmarkFhCrownBridge.build(model)
		"itis_shopping_centre": LandmarkFhMalls.itis(model)
		"iso_omena": LandmarkFhMalls.iso_omena(model)
		"sello_shopping_centre": LandmarkFhMalls.sello(model)
		"jumbo_shopping_centre": LandmarkFhMalls.jumbo(model)
		"hanko_water_tower": LandmarkFhHelsinkiMonuments.hanko(model)
		"espoo_cathedral": LandmarkFhRegionalChurches.espoo(model)
		"porvoo_cathedral": LandmarkFhRegionalChurches.porvoo(model)
		_:
			return CentreModels.build(model, type)
	return true
