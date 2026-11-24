class_name FtSigynBoreShips
extends RefCounted

## Museum Passenger Liner S/S Bore (1960, Oskarshamn) moored at Forum Marinum
## quay on Aurajoki in true metres (+X ENE upstream along Aurajoki, y = 0 at
## waterline, base = "water", turned by yaw_deg = -34.0°):
##   - Registry anchor: 60.435500, 22.235500, height_m = 26.8, base = "water".
##   - S/S Bore (1960, classic 100 m Baltic steamship liner, offset x = -34 m
##     downstream toward Aura mouth):
##     * Sleek curved white steel liner hull via HullLoft.loft (99.8 m LOA,
##       15.2 m beam, 5.6 m freeboard, 2.2 m underwater draft, red boot-top,
##       raked clipper bow, cruiser stern, brass porthole rows).
##     * Tiered white promenade & boat-deck superstructure with recessed teak
##       promenade decks, panoramic bridge wings, 6 white lifeboats on davits,
##       iconic raked buff/yellow funnel with dark crown & Bore cross, radar
##       mast, and warm illuminated cabin & lounge windows at night.

const BORE_SPEC := {
	"length": 99.8,
	"beam": 15.2,
	"freeboard": 5.6,
	"draft": 2.2,
	"entry": 0.30,
	"bow_pow": 1.85,
	"stern_w": 0.58,
	"stern_round": 0.90,
	"stern_tail": 0.18,
	"flare": 0.12,
	"bow_rise": 1.4,
	"stern_rise": 0.65,
	"stem_rake": 4.2,
	"stern_rake": 3.0,
	"boot_m": 1.25,
	"lod": 0,
	"ultra": false,
}

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	_materials(lm)
	# Build S/S Bore in local frame and merge at her Forum Marinum berth (x = -34 m).
	var bore_lm := LandmarkMesh.new()
	_materials(bore_lm)
	_build_ss_bore(bore_lm)
	lm.merge(bore_lm, Transform3D(Basis(), Vector3(-34.0, 0.0, 0.0)))
	lm.commit(model)
	_set_night_floods(model)

static func _materials(lm: LandmarkMesh) -> void:
	lm.use("HullWhite", LandmarkMaterials.paint("#F2EFE8", 0.42, 0.12))
	lm.use("Boot", LandmarkMaterials.paint("#8C2620", 0.54, 0.08))
	lm.use("Deck", LandmarkMaterials.pbr("wood", "#9F7B52", 2.4, 0.72))
	lm.use("FunnelYellow", LandmarkMaterials.paint("#E4AE38", 0.45, 0.15))
	lm.use("Dark", LandmarkMaterials.paint("#22262A", 0.48, 0.48))
	lm.use("Glass", LandmarkMaterials.glass("#223442"))
	lm.use("Brass", LandmarkMaterials.gold())
	lm.use("Lamp", LandmarkMaterials.lit("#FFE6B2", 1.5))

static func _build_ss_bore(lm: LandmarkMesh) -> void:
	# 1960 classic Baltic steamship liner S/S Bore (99.8 m LOA, 15.2 m beam).
	HullLoft.loft(lm, BORE_SPEC, {"hull": "HullWhite", "boot": "Boot", "bottom": "Boot", "deck": "Deck"})
	# Promenade deck superstructure (x = -34..26, z = -7.0..7.0, y = 5.6..8.6).
	LandmarkFrKit.rect(lm, "HullWhite", -33.0, 24.0, -6.9, 6.9, 5.5, 8.6)
	LandmarkFrKit.rect(lm, "Deck", -34.0, 26.0, -7.1, 7.1, 8.6, 8.85)
	# Upper boat-deck & saloon superstructure (x = -26..20, z = -5.8..5.8, y = 8.85..11.8).
	LandmarkFrKit.rect(lm, "HullWhite", -25.0, 19.0, -5.8, 5.8, 8.85, 11.8)
	LandmarkFrKit.rect(lm, "Deck", -26.0, 20.0, -6.0, 6.0, 11.8, 12.05)
	# Bridge & officers' house (+X forward, x = 4..18, y = 12.05..14.8) with cantilevered bridge wings.
	LandmarkFrKit.rect(lm, "HullWhite", 4.0, 17.5, -5.2, 5.2, 12.05, 14.8)
	LandmarkFrKit.rect(lm, "HullWhite", 12.0, 16.5, -8.2, 8.2, 12.2, 14.6)
	LandmarkFrKit.rect(lm, "Glass", 17.46, 17.64, -4.6, 4.6, 13.0, 14.3)
	LandmarkFrKit.rect(lm, "Lamp", 16.6, 17.2, -4.2, 4.2, 13.1, 14.1)
	# Rhythmic illuminated promenade & cabin window rows along both flanks of S/S Bore.
	for sz: float in [-1.0, 1.0]:
		for k in 16:
			var wx := lerpf(-30.0, 21.0, float(k) / 15.0)
			lm.box("Glass", Vector3(wx, 7.2, 6.96 * sz), Vector3(1.8, 1.15, 0.12))
			if k % 2 == 0:
				lm.box("Lamp", Vector3(wx, 7.2, 6.72 * sz), Vector3(1.5, 0.92, 0.10))
		for k in 12:
			var wx := lerpf(-22.0, 16.0, float(k) / 11.0)
			lm.box("Glass", Vector3(wx, 10.4, 5.86 * sz), Vector3(1.9, 1.15, 0.12))
			lm.box("Lamp", Vector3(wx, 10.4, 5.62 * sz), Vector3(1.6, 0.92, 0.10))
		# Hull porthole line.
		for k in 18:
			var px := lerpf(-38.0, 32.0, float(k) / 17.0)
			lm.disc("Brass", Vector3(px, 4.1, 7.52 * sz), Vector3(0, 0, sz), 0.26, 8)
			lm.disc("Dark", Vector3(px, 4.1, 7.55 * sz), Vector3(0, 0, sz), 0.18, 8)
		# 3 white lifeboats per side on boat deck davits (6 total).
		for bx: float in [-18.0, -8.5, 1.0]:
			lm.box("HullWhite", Vector3(bx, 12.85, 6.3 * sz), Vector3(5.8, 1.15, 1.75))
			lm.beam("Dark", Vector3(bx - 2.2, 11.9, 5.8 * sz), Vector3(bx - 2.2, 13.7, 6.4 * sz), 0.14, 0.14)
			lm.beam("Dark", Vector3(bx + 2.2, 11.9, 5.8 * sz), Vector3(bx + 2.2, 13.7, 6.4 * sz), 0.14, 0.14)
	# Iconic raked buff/yellow S/S Bore funnel with black crown band & Bore cross (x = -4.5, y = 12..21.5).
	var rake := Basis(Vector3.FORWARD, -0.14)
	lm.box("FunnelYellow", Vector3(-4.5, 16.0, 0.0), Vector3(6.4, 8.2, 3.6), rake)
	lm.box("Dark", Vector3(-5.1, 20.4, 0.0), Vector3(6.2, 1.45, 3.65), rake)
	# Bore cross emblem on both sides of the funnel.
	for sz: float in [-1.85, 1.85]:
		lm.box("Dark", Vector3(-4.4, 16.2, sz), Vector3(0.45, 2.2, 0.08), rake)
		lm.box("Dark", Vector3(-4.4, 16.2, sz), Vector3(2.2, 0.45, 0.08), rake)
	# Forward signal/radar mast & aft ensign staff.
	lm.beam("HullWhite", Vector3(14.0, 14.8, 0.0), Vector3(12.2, 26.8, 0.0), 0.34, 0.34)
	lm.beam("HullWhite", Vector3(12.8, 22.8, -3.4), Vector3(12.8, 22.8, 3.4), 0.14, 0.14)
	lm.beam("HullWhite", Vector3(-42.0, 6.2, 0.0), Vector3(-43.5, 14.5, 0.0), 0.18, 0.18)

static func _set_night_floods(model: Node3D) -> void:
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-34.0, 3.0, -14.0), Vector3(-34.0, 12.0, 0.0), 62.0, 0.85, 48.0, Color(1.0, 0.90, 0.72)],
		[Vector3(-38.0, 12.0, -10.0), Vector3(-38.5, 17.5, 0.0), 48.0, 0.75, 28.0, Color(1.0, 0.82, 0.50)],
	])
