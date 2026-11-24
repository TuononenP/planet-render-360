class_name VeniceVesselModels
extends RefCounted

## Authentic Venetian lagoon & canal vessels (`VN-9.5`) on `LandmarkMesh`
## (`+X` bow, waterline `y = 0`, immersed hull `y < -0.05`):
##   - `gondola` (~10.8 m x 1.4 m): gloss-black lacquered asymmetric hull, gleaming
##     steel *ferro* prow ornament, red-velvet passenger seats, brass *cavallini*,
##     and standing gondolier silhouette in striped shirt & straw hat.
##   - `vaporetto` (~23.9 m x 4.2 m): ACTV Serie 80/90 public waterbus — white-and-navy
##     hull, low enclosed glass saloon with bright ACTV yellow stripe, forward open
##     viewing deck, raised wheelhouse & warm interior night lamps.
##   - `motoscafo` (~9.5 m x 2.3 m): classic varnished mahogany Venetian wooden water
##     taxi with cream cabin roof & chrome bow fittings.
##   - `topo_barge` (~12.0 m x 2.8 m): Venetian lagoon workboat / cargo delivery barge.

const ROUTES := [
	# ACTV Line 1 — Grand Canal (Ferrovia -> Rialto -> Accademia -> Salute -> San Marco)
	{"id": "actv_line1_lower", "model": "vaporetto", "length_m": 23.9, "beam_m": 4.2, "speed": 4.2,
		"points": [[45.4326, 12.3274], [45.4317, 12.3292], [45.4313, 12.3318], [45.4312, 12.3348],
			[45.4318, 12.3378], [45.4322, 12.3412]],
		"boats": [0.22, 0.62, 0.88]},
	{"id": "actv_line1_upper", "model": "vaporetto", "length_m": 23.9, "beam_m": 4.2, "speed": 4.0,
		"points": [[45.4408, 12.3216], [45.4418, 12.3264], [45.4412, 12.3318], [45.4388, 12.3356],
			[45.4366, 12.3324], [45.4342, 12.3275]],
		"boats": [0.20, 0.56, 0.84]},
	# ACTV Line 2 — Giudecca Canal & Bacino di San Marco
	{"id": "actv_line2_giudecca", "model": "vaporetto", "length_m": 23.9, "beam_m": 4.2, "speed": 5.2,
		"points": [[45.4282, 12.3215], [45.4278, 12.3276], [45.4274, 12.3335], [45.4292, 12.3388],
			[45.4312, 12.3428]],
		"boats": [0.24, 0.64]},
	# Gondolas gliding along the lower Grand Canal & Bacino di San Marco
	{"id": "venice_gondola_grand_canal", "model": "gondola", "length_m": 10.8, "beam_m": 1.45, "speed": 1.6,
		"points": [[45.4315, 12.3298], [45.4312, 12.3326], [45.4314, 12.3358], [45.4324, 12.3386]],
		"boats": [0.16, 0.44, 0.72, 0.90]},
	{"id": "venice_gondola_bacino", "model": "gondola", "length_m": 10.8, "beam_m": 1.45, "speed": 1.5,
		"points": [[45.4328, 12.3396], [45.4326, 12.3418], [45.4314, 12.3432], [45.4302, 12.3422]],
		"boats": [0.20, 0.52, 0.82]},
	# Mahogany wooden Venetian water taxis (motoscafi)
	{"id": "venice_motoscafo_canal", "model": "motoscafo", "length_m": 9.5, "beam_m": 2.3, "speed": 5.6,
		"points": [[45.4348, 12.3272], [45.4316, 12.3304], [45.4315, 12.3364], [45.4320, 12.3424]],
		"boats": [0.18, 0.52, 0.82]},
	# Venetian wooden workboat / cargo delivery barge (topo)
	{"id": "venice_topo_barge", "model": "topo_barge", "length_m": 12.0, "beam_m": 2.8, "speed": 3.4,
		"points": [[45.4286, 12.3250], [45.4282, 12.3315], [45.4298, 12.3372], [45.4316, 12.3446]],
		"boats": [0.35, 0.75]},
]

static func build(lm: LandmarkMesh, model: String, p: Dictionary) -> void:
	match model:
		"gondola":
			_gondola(lm, p)
		"vaporetto":
			_vaporetto(lm, p)
		"motoscafo":
			_motoscafo(lm, p)
		_:
			_topo_barge(lm, p)

static func _base_hull(lm: LandmarkMesh, length: float, beam: float, fb: float, draft: float,
		bow_rise: float, hull_hex: String, detail: bool, maps: bool, rough: float = 0.36) -> void:
	var s := {"length": length, "beam": beam, "freeboard": fb, "draft": draft, "entry": 0.35,
		"bow_pow": 1.65, "stern_w": 0.62, "flare": 0.12, "deadrise": 0.22, "bow_rise": bow_rise,
		"stem_rake": length * 0.06, "stern_rake": 0.16, "keel_lift": 0.78, "boot_m": 0.10,
		"lod": 0 if detail else 1, "ultra": false}
	VesselMaterials.register(lm, maps, VesselMaterials.paint(hull_hex, maps, rough, 0.08),
		VesselMaterials.get_mat("antifoul", maps))
	ShipLights.register(lm, maps)
	HullLoft.loft(lm, s, {"hull": "Hull", "boot": "Boot", "bottom": "Bottom", "deck": "Deck"})

static func _gondola(lm: LandmarkMesh, p: Dictionary) -> void:
	var length: float = maxf(float(p.get("length", 10.8)), 8.5)
	var beam: float = maxf(float(p.get("beam", 1.45)), 1.2)
	var detail: bool = bool(p.get("detail", true))
	var maps: bool = bool(p.get("maps", true))
	# Sleek gloss-black lacquered hull
	_base_hull(lm, length, beam, 0.42, 0.24, 0.72, "#151618", detail, maps, 0.18)
	lm.use("Ferro", ShipPaint.enamel(Color("#DCE2E6"), maps))
	lm.use("Velvet", ShipPaint.enamel(Color("#8E1E22"), maps))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.use("Gondolier", ShipPaint.enamel(Color("#F0EEE6"), maps))
	lm.use("Hat", ShipPaint.enamel(Color("#DEC27A"), maps))

	# Iconic curved steel *ferro* prow ornament (+X) with six comb teeth
	var bx := length * 0.48
	lm.beam("Ferro", Vector3(bx - 0.35, 0.65, 0.0), Vector3(bx + 0.18, 1.52, 0.0), 0.06, 0.14)
	lm.box("Ferro", Vector3(bx + 0.22, 1.42, 0.0), Vector3(0.32, 0.28, 0.05))
	for k in 5:
		lm.box("Ferro", Vector3(bx + 0.12, 0.82 + 0.11 * float(k), 0.0), Vector3(0.24, 0.05, 0.04))
	# Rising carved stern tail (-X)
	lm.beam("Hull", Vector3(-length * 0.42, 0.48, 0.0), Vector3(-length * 0.50, 1.05, 0.0), 0.14, 0.16)
	# Red-velvet passenger armchair & gold brass seahorse *cavallini* amidships
	lm.box("Velvet", Vector3(-0.3, 0.56, 0.0), Vector3(1.4, 0.34, beam * 0.78))
	lm.box("Velvet", Vector3(-0.92, 0.92, 0.0), Vector3(0.24, 0.58, beam * 0.78))
	for sz in [-beam * 0.44, beam * 0.44]:
		lm.box("Gold", Vector3(-0.1, 0.62, float(sz)), Vector3(0.7, 0.16, 0.06))
	# Standing gondolier silhouette on the stern platform + long wooden oar
	var gx := -length * 0.33
	lm.box("Hull", Vector3(gx, 0.88, 0.14), Vector3(0.30, 0.76, 0.32))
	lm.box("Gondolier", Vector3(gx, 1.52, 0.14), Vector3(0.32, 0.58, 0.38))
	lm.frustum("Hat", Vector3(gx, 1.98, 0.14), 0.26, 0.16, 0.14, 8)
	lm.beam("Hat", Vector3(gx + 0.15, 1.38, 0.35), Vector3(gx - 0.85, -0.08, 1.45), 0.06, 0.06)

static func _vaporetto(lm: LandmarkMesh, p: Dictionary) -> void:
	var length: float = maxf(float(p.get("length", 23.9)), 18.0)
	var beam: float = maxf(float(p.get("beam", 4.2)), 3.4)
	var detail: bool = bool(p.get("detail", true))
	var maps: bool = bool(p.get("maps", true))
	# ACTV Serie 80/90 Venetian public waterbus: navy lower hull, white superstructure, bright yellow band
	_base_hull(lm, length, beam, 1.05, 0.85, 0.32, "#243C58", detail, maps, 0.36)
	lm.use("White", ShipPaint.enamel(Color("#F3F1EA"), maps))
	lm.use("ActvYellow", ShipPaint.enamel(Color("#EDB926"), maps))
	lm.use("Glass", LandmarkMaterials.glass("#22323D"))
	lm.use("CabinLamp", LandmarkVnKit.warm_lamp("#FFE6A8", 1.9))

	var y0 := 1.06
	# White upper bulwark skirt & bright ACTV yellow stripe
	lm.box("White", Vector3(0.0, y0 + 0.38, 0.0), Vector3(length * 0.90, 0.76, beam * 0.94))
	lm.box("ActvYellow", Vector3(0.0, y0 + 0.14, 0.0), Vector3(length * 0.92, 0.26, beam * 0.97))
	# Aft & midships enclosed passenger saloon with continuous dark glass windows & warm night glow
	var cab_l := length * 0.54
	var cab_x := -length * 0.14
	lm.box("White", Vector3(cab_x, y0 + 1.32, 0.0), Vector3(cab_l, 1.25, beam * 0.86))
	lm.box("Glass", Vector3(cab_x, y0 + 1.38, 0.0), Vector3(cab_l - 0.5, 0.86, beam * 0.88))
	lm.box("CabinLamp", Vector3(cab_x, y0 + 1.36, 0.0), Vector3(cab_l - 1.2, 0.62, beam * 0.68))
	lm.box("White", Vector3(cab_x, y0 + 2.02, 0.0), Vector3(cab_l + 0.8, 0.18, beam * 0.90))
	lm.box("ActvYellow", Vector3(cab_x, y0 + 2.10, 0.0), Vector3(cab_l + 0.6, 0.14, beam * 0.92))
	# Raised mid-forward wheelhouse over the boarding deck
	var wx := length * 0.18
	lm.box("White", Vector3(wx, y0 + 1.95, 0.0), Vector3(3.4, 1.75, beam * 0.74))
	lm.box("Glass", Vector3(wx + 0.2, y0 + 2.25, 0.0), Vector3(3.0, 0.78, beam * 0.77))
	lm.box("White", Vector3(wx, y0 + 2.86, 0.0), Vector3(3.8, 0.16, beam * 0.80))
	# Navigation masthead lamp
	lm.frustum("White", Vector3(wx, y0 + 2.94, 0.0), 0.06, 0.04, 1.2, 6)
	lm.box("CabinLamp", Vector3(wx, y0 + 4.18, 0.0), Vector3(0.22, 0.22, 0.22))

static func _motoscafo(lm: LandmarkMesh, p: Dictionary) -> void:
	var length: float = maxf(float(p.get("length", 9.5)), 7.5)
	var beam: float = maxf(float(p.get("beam", 2.3)), 1.9)
	var detail: bool = bool(p.get("detail", true))
	var maps: bool = bool(p.get("maps", true))
	# Glossy varnished mahogany hull + cream-white salon roof + chrome windshield
	_base_hull(lm, length, beam, 0.78, 0.45, 0.30, "#6E351B", detail, maps, 0.16)
	lm.use("Cream", ShipPaint.enamel(Color("#F2ECE0"), maps))
	lm.use("Glass", LandmarkMaterials.glass("#243440"))
	lm.use("CabinLamp", LandmarkVnKit.warm_lamp("#FFE6A8", 1.7))

	var y0 := 0.80
	lm.box("Cream", Vector3(-0.4, y0 + 0.55, 0.0), Vector3(length * 0.46, 0.95, beam * 0.82))
	lm.box("Glass", Vector3(-0.3, y0 + 0.60, 0.0), Vector3(length * 0.42, 0.62, beam * 0.85))
	lm.box("Cream", Vector3(-0.4, y0 + 1.08, 0.0), Vector3(length * 0.50, 0.14, beam * 0.86))
	lm.box("CabinLamp", Vector3(-0.4, y0 + 0.62, 0.0), Vector3(length * 0.32, 0.42, beam * 0.62))

static func _topo_barge(lm: LandmarkMesh, p: Dictionary) -> void:
	var length: float = maxf(float(p.get("length", 12.0)), 9.0)
	var beam: float = maxf(float(p.get("beam", 2.8)), 2.2)
	var detail: bool = bool(p.get("detail", true))
	var maps: bool = bool(p.get("maps", true))
	_base_hull(lm, length, beam, 0.86, 0.52, 0.28, "#3C4E42", detail, maps, 0.48)
	lm.use("Wood", LandmarkVnKit.dark_wood("#7D5B3C", 1.8))
	lm.use("Tarp", ShipPaint.enamel(Color("#2D567A"), maps))
	lm.use("Cabin", ShipPaint.enamel(Color("#ECE8DD"), maps))

	var y0 := 0.88
	# Open cargo hold with crates/blue tarp + small aft steering cabin
	lm.box("Wood", Vector3(length * 0.08, y0 + 0.45, 0.0), Vector3(length * 0.46, 0.82, beam * 0.72))
	lm.box("Tarp", Vector3(length * 0.08, y0 + 0.92, 0.0), Vector3(length * 0.42, 0.24, beam * 0.68))
	lm.box("Cabin", Vector3(-length * 0.30, y0 + 0.78, 0.0), Vector3(2.2, 1.48, beam * 0.64))
