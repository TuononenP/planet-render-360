class_name FtSigynBoreShips
extends RefCounted

## Museum Ships Barque Sigyn (1887, Gothenburg) in her floating wooden drydock
## Loke & Passenger Liner S/S Bore (1960, Oskarshamn) moored at Forum Marinum
## quay on Aurajoki in true metres (+X ENE upstream along Aurajoki, y = 0 at
## waterline, base = "water", turned by yaw_deg = -34.0°):
##   - Registry anchor: 60.435500, 22.235500, height_m = 32.0, base = "water".
##   - Vessel 1 — Barque Sigyn (1887) + Floating Wooden Drydock Loke (offset
##     x = +48 m upstream toward Suomen Joutsen):
##     * White-and-timber floating pontoon drydock Loke (56 x 15.8 m) with
##       twin side wing walls, keel blocks, and wooden gangway.
##     * Curved wooden hull via HullLoft.loft (46.0 m hull, 54 m LOA with
##       bowsprit, 9.4 m beam, dark timber hull with white painted gunport
##       band & copper/red bottom), 3 raked wooden masts rising to 32.0 m
##       (square-rigged fore & main with 4 yards each, gaff-rigged mizzen),
##       deckhouses, standing shrouds & stays.
##   - Vessel 2 — S/S Bore (1960, classic 100 m Baltic steamship liner, offset
##     x = -34 m downstream toward Aura mouth):
##     * Sleek curved white steel liner hull via HullLoft.loft (99.8 m LOA,
##       15.2 m beam, 5.6 m freeboard, 2.2 m underwater draft, red boot-top,
##       raked clipper bow, cruiser stern, brass porthole rows).
##     * Tiered white promenade & boat-deck superstructure with recessed teak
##       promenade decks, panoramic bridge wings, 6 white lifeboats on davits,
##       iconic raked buff/yellow funnel with dark crown & Bore cross, radar
##       mast, and warm illuminated cabin & lounge windows at night.
## Surfaces: 11 merged PBR parts (HullWhite, HullDark, Boot, Deck, WoodLight,
## Mast, FunnelYellow, Dark, Glass, Brass, Lamp).

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

const SIGYN_SPEC := {
	"length": 46.0,
	"beam": 9.4,
	"freeboard": 3.6,
	"draft": 1.4,
	"entry": 0.32,
	"bow_pow": 1.9,
	"stern_w": 0.52,
	"stern_round": 0.75,
	"stern_tail": 0.20,
	"flare": 0.10,
	"bow_rise": 1.1,
	"stern_rise": 0.75,
	"stem_rake": 2.8,
	"stern_rake": 2.0,
	"boot_m": 0.9,
	"lod": 0,
	"ultra": false,
}

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	_materials(lm)
	# Build S/S Bore in local frame and merge downstream at x = -34 m.
	var bore_lm := LandmarkMesh.new()
	_materials(bore_lm)
	_build_ss_bore(bore_lm)
	lm.merge(bore_lm, Transform3D(Basis(), Vector3(-34.0, 0.0, 0.0)))
	# Build Barque Sigyn + Floating Dock Loke in local frame and merge upstream at x = +52 m.
	var sigyn_lm := LandmarkMesh.new()
	_materials(sigyn_lm)
	_build_loke_and_sigyn(sigyn_lm)
	lm.merge(sigyn_lm, Transform3D(Basis(), Vector3(52.0, 0.0, 0.0)))
	lm.commit(model)
	_set_night_floods(model)

static func _materials(lm: LandmarkMesh) -> void:
	lm.use("HullWhite", LandmarkMaterials.paint("#F2EFE8", 0.42, 0.12))
	lm.use("HullDark", LandmarkMaterials.pbr("wood", "#2D2722", 2.4, 0.68))
	lm.use("Boot", LandmarkMaterials.paint("#8C2620", 0.54, 0.08))
	lm.use("Deck", LandmarkMaterials.pbr("wood", "#9F7B52", 2.4, 0.72))
	lm.use("WoodLight", LandmarkMaterials.pbr("wood", "#C6AE8A", 2.4, 0.72))
	lm.use("Mast", LandmarkMaterials.pbr("wood", "#B89362", 2.2, 0.66))
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

static func _build_loke_and_sigyn(lm: LandmarkMesh) -> void:
	# Floating wooden drydock Loke (56 x 15.8 m) cradling the 1887 barque Sigyn.
	LandmarkFrKit.rect(lm, "Boot", -28.0, 28.0, -7.9, 7.9, -1.6, 0.35)
	LandmarkFrKit.rect(lm, "WoodLight", -28.0, 28.0, -7.9, 7.9, 0.35, 1.35)
	# Loke's characteristic white-painted twin floating wing walls.
	for sz: float in [-1.0, 1.0]:
		var z0 := 5.8 * sz if sz > 0.0 else -7.9
		var z1 := 7.9 if sz > 0.0 else -5.8
		LandmarkFrKit.rect(lm, "HullWhite", -27.5, 27.5, z0, z1, 1.35, 5.4)
		LandmarkFrKit.rect(lm, "Deck", -27.6, 27.6, z0 - 0.1, z1 + 0.1, 5.4, 5.65)
		# Diagonal timber keel shores bracing Sigyn's hull inside Loke.
		for k in 7:
			var sx := lerpf(-18.0, 18.0, float(k) / 6.0)
			lm.beam("Mast", Vector3(sx, 2.2, 5.8 * sz), Vector3(sx, 3.4, 3.8 * sz), 0.22, 0.22)
	# Barque Sigyn (1887) hull raised on keel blocks inside Loke (+2.4 m above waterline).
	var sigyn_hull := LandmarkMesh.new()
	_materials(sigyn_hull)
	HullLoft.loft(sigyn_hull, SIGYN_SPEC, {"hull": "HullDark", "boot": "Boot", "bottom": "Boot", "deck": "Deck"})
	lm.merge(sigyn_hull, Transform3D(Basis(), Vector3(0.0, 2.4, 0.0)))
	# Painted white gunport stripe along Sigyn's dark timber topsides.
	for sz: float in [-4.55, 4.55]:
		LandmarkFrKit.rect(lm, "HullWhite", -16.0, 16.0, sz - 0.10, sz + 0.10, 4.6, 5.35)
	# Deckhouses & raked bowsprit/jibboom (+X).
	LandmarkFrKit.rect(lm, "HullWhite", -14.0, -6.5, -2.2, 2.2, 6.0, 7.5)
	LandmarkFrKit.rect(lm, "HullWhite", 8.0, 13.5, -2.0, 2.0, 6.0, 7.4)
	lm.beam("Mast", Vector3(20.5, 6.6, 0.0), Vector3(31.5, 10.6, 0.0), 0.36, 0.36)
	# Three raked wooden masts of Barque Sigyn: Fore (+12.5 -> 29.5 m), Main (0 -> 32.0 m), Mizzen (-13 -> 26.5 m).
	var masts := [[12.5, 29.5, true], [0.0, 32.0, true], [-13.0, 26.5, false]]
	for m in masts:
		var mx: float = m[0]
		var top_y: float = m[1]
		var square: bool = m[2]
		lm.beam("Mast", Vector3(mx, 6.0, 0.0), Vector3(mx - 1.2, top_y, 0.0), 0.42, 0.42)
		# Fighting top & crosstrees.
		lm.box("Dark", Vector3(mx - 0.45, top_y * 0.52, 0.0), Vector3(1.6, 0.22, 3.2))
		if square:
			# 4 tapered square-rig yards on Fore and Main masts.
			for k in 4:
				var f := lerpf(0.42, 0.88, float(k) / 3.0)
				var yy := lerpf(6.0, top_y, f)
				var yx := mx - 1.2 * f
				var yw := lerpf(15.2, 6.8, float(k) / 3.0)
				lm.beam("Mast", Vector3(yx, yy, -yw * 0.5), Vector3(yx, yy, yw * 0.5), 0.18, 0.18)
		else:
			# Gaff & boom on Mizzen mast (barque rig).
			lm.beam("Mast", Vector3(mx - 0.2, 8.6, 0.0), Vector3(mx - 9.2, 9.2, 0.0), 0.18, 0.18)
			lm.beam("Mast", Vector3(mx - 0.5, 16.5, 0.0), Vector3(mx - 8.0, 20.5, 0.0), 0.16, 0.16)
		# Standing shrouds to Loke/Sigyn rail.
		for sz: float in [-4.4, 4.4]:
			lm.beam("Dark", Vector3(mx, 6.2, sz), Vector3(mx - 0.5, top_y * 0.54, 0.0), 0.06, 0.06)
			lm.beam("Dark", Vector3(mx - 0.8, 6.2, sz), Vector3(mx - 0.9, top_y * 0.82, 0.0), 0.05, 0.05)
	# Fore-and-aft stays linking bowsprit, Fore, Main, and Mizzen masts.
	lm.beam("Dark", Vector3(31.2, 10.5, 0.0), Vector3(11.4, 28.5, 0.0), 0.06, 0.06)
	lm.beam("Dark", Vector3(11.4, 28.5, 0.0), Vector3(-1.1, 31.2, 0.0), 0.06, 0.06)
	lm.beam("Dark", Vector3(-1.1, 31.2, 0.0), Vector3(-14.1, 25.8, 0.0), 0.06, 0.06)
	# Warm deck lamp glow along Loke drydock walkways.
	for sz: float in [-6.8, 6.8]:
		LandmarkFrKit.rect(lm, "Lamp", -22.0, 22.0, sz - 0.18, sz + 0.18, 5.65, 5.82)

static func _set_night_floods(model: Node3D) -> void:
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-34.0, 3.0, -14.0), Vector3(-34.0, 12.0, 0.0), 62.0, 0.85, 48.0, Color(1.0, 0.90, 0.72)],
		[Vector3(52.0, 3.0, -14.0), Vector3(52.0, 16.0, 0.0), 60.0, 0.85, 46.0, Color(1.0, 0.86, 0.62)],
		[Vector3(-38.0, 12.0, -10.0), Vector3(-38.5, 17.5, 0.0), 48.0, 0.75, 28.0, Color(1.0, 0.82, 0.50)],
	])
