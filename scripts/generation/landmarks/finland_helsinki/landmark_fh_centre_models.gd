extends RefCounted

## Helsinki landmarks kept one per file, each script holding its registry
## row (`const ENTRY`) and its model (`static func build(model)`), so a
## landmark's position, clearance and geometry are read and reviewed in one
## place. LandmarkRegistryFinlandHelsinki lists the entries and
## LandmarkSetFinlandHelsinki dispatches the types here.
## Sources per landmark: docs/helsinki-landmark-sources.md.

const MODELS: Array = [
	preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_government_palace.gd"),
	preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_university_main.gd"),
	preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_national_library.gd"),
	preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_uspenski.gd"),
	preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_enso.gd"),
	preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_presidential_palace.gd"),
	preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_old_market_hall.gd"),
	preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_havis_amanda.gd"),
	preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_kappeli.gd"),
	preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_allas.gd"),
	preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_skywheel.gd"),
	preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_merikasarmi.gd"),
	preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_katajanokka_terminal.gd"),
	preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_central_station.gd"),
	preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_ateneum.gd"),
	preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_kiasma.gd"),
	preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_oodi.gd"),
	preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_music_centre.gd"),
	preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_finlandia_hall.gd"),
	preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_national_museum.gd"),
	preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_amos_rex.gd"),
	preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_kamppi_chapel.gd"),
	preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_stockmann.gd"),
	preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_torni.gd"),
	preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_st_johns.gd"),
	preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_temppeliaukio.gd"),
	preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_sederholm_house.gd"),
	preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_bock_house.gd"),
	preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_city_hall.gd"),
	preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_market_square.gd"),
	preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_katajanokka_casino.gd"),
	preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_hotel_katajanokka.gd"),
	preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_olympia_terminal.gd"),
	preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_makasiiniterminaali.gd"),
	preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_observatory.gd"),
	preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_german_church.gd"),
	preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_national_theatre.gd"),
	preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_sokos.gd"),
	preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_postitalo.gd"),
	preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_sanomatalo.gd"),
	preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_kamppi_centre.gd"),
	preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_tennispalatsi.gd"),
	preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_forum.gd"),
	preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_swedish_theatre.gd"),
	preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_hotel_kamp.gd"),
	preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_rautatalo.gd"),
	preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_erottaja_fire_station.gd"),
	preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_old_church.gd"),
	preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_st_henrys.gd"),
	preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_mikael_agricola_church.gd"),
	preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_bank_of_finland.gd"),
	preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_house_of_estates.gd"),
	preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_house_of_nobility.gd"),
	preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_olympic_stadium.gd"),
	preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_opera.gd"),
	preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_sibelius.gd"),
	preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_linnanmaki.gd"),
	preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_kallio_church.gd"),
	preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_kallio_library.gd"),
	preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_hakaniemi_market_hall.gd"),
	preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_kallio_virastotalo.gd"),
	preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_majakka.gd"),
	preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_loisto.gd"),
	preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_lumo_one.gd"),
	preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_horisontti.gd"),
	preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_visio.gd"),
	preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_redi.gd"),
	preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_tripla.gd"),
	preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_clarion.gd"),
	preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_west_terminal.gd"),
	preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_cable_factory.gd"),
	preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_salmisaari.gd"),
	preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_lauttasaari_church.gd"),
	preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_lauttasaari_manor.gd"),
	preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_aalto_house.gd"),
	preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_studio_aalto.gd"),
	preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_didrichsen.gd"),
	preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_villa_gyllenberg.gd"),
	preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_kings_gate.gd"),
	preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_dry_dock.gd"),
	preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_jetty_barracks.gd"),
	preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_swimming_stadium.gd"),
	preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_bolt_arena.gd"),
	preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_ice_hall.gd"),
	preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_winter_garden.gd"),
	preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_kulttuuritalo.gd"),
	preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_ympyratalo.gd"),
	preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_hanasaari.gd"),
	preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_pasila_tower.gd"),
	preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_korkeasaari_tower.gd"),
	preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_loyly.gd"),
	preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_hietalahti_market_hall.gd"),
	preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_sinebrychoff.gd"),
	preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_design_museum.gd"),
	preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_ursa_observatory.gd"),
	preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_kalastajatorppa.gd"),
	preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_vesikko.gd"),
	preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_lonna.gd"),
	preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_harmaja.gd"),
	preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_valkosaari.gd"),
	preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_klippan.gd"),
	preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_uunisaari.gd"),
	preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_kustaanmiekka.gd"),
	preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_swedish_embassy.gd"),
	preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_supreme_court.gd"),
	preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_runeberg_statue.gd"),
	preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_three_smiths.gd"),
	preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_mannerheim_statue.gd"),
	preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_eino_leino.gd"),
	preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_topelius_statue.gd"),
	preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_lonnrot_monument.gd"),
	preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_paasikivi_monument.gd"),
	# @models-end
]

static var _by_type: Dictionary = {}

static func entries() -> Array:
	var out: Array = []
	for m: GDScript in MODELS:
		out.append(m.ENTRY)
	return out

## Builds `type` into `model`; false when no file here owns it.
static func build(model: Node3D, type: String) -> bool:
	if _by_type.is_empty():
		for m: GDScript in MODELS:
			_by_type[str(m.ENTRY["type"])] = m
	var script: GDScript = _by_type.get(type)
	if script == null:
		return false
	script.build(model)
	return true
