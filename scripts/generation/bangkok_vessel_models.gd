class_name BangkokVesselModels
extends RefCounted

## Authentic Thai river & khlong vessels (`BK-7.4` & `BK-10`) on `LandmarkMesh`
## (`+X` bow, waterline `y = 0`, immersed hull `y < -0.05`, outward winding):
##   - `longtail` (`Ruea Hang Yao`, ~11.5 m): slender wooden hull, raised upturned bow
##     with silk/marigold garlands, striped awning, pivoted rear car engine & 3.6 m propeller shaft.
##   - `chao_phraya_express` (~26 m): long white passenger boat, open-sided window cabin,
##     coloured stern route flag (orange/yellow/blue), forward wheelhouse.
##   - `cross_river_ferry` (~16.5 m): broad double-ended white-and-green Tha Tien shuttle ferry.
##   - `saen_saep_boat` (~17 m): low-slung Khlong Saen Saep canal express boat with blue splash tarps.
##   - `rice_barge` (~20 m): deep round-bellied dark-teak Ayutthaya cargo barge (`Ruea Iam Chun`).
##   - `dinner_cruise` (~36 m): 2-deck illuminated Chao Phraya dinner cruise ship (`CruiseLamp` night bands).

const ROUTES := [
	# Khlong Saen Saep Express Boat starting at Phan Fa Lilat Pier (520 m from capital eye — visible in E5!)
	{"id": "saen_saep_phan_fa", "model": "saen_saep_boat", "length_m": 16.8, "beam_m": 3.1, "speed": 4.2,
		"points": [[13.75602, 100.50618], [13.75565, 100.50765], [13.75498, 100.51020], [13.75462, 100.51340]],
		"boats": [0.08, 0.55]},
	# Chao Phraya Express Boat (Orange Flag) running past Wat Arun, Tha Tien, Tha Chang & Rama VIII Bridge
	{"id": "chao_phraya_orange", "model": "chao_phraya_express", "length_m": 26.0, "beam_m": 5.2, "speed": 5.8,
		"flag": "#E86A1E",
		"points": [[13.7385, 100.4962], [13.7435, 100.4902], [13.7485, 100.4882], [13.7545, 100.4876],
			[13.7615, 100.4908], [13.7685, 100.4958]],
		"boats": [0.18, 0.48, 0.82]},
	# Longtail tourist boats plying between Wat Arun, Tha Tien & Khlong Bangkok Yai
	{"id": "chao_phraya_longtail_a", "model": "longtail", "length_m": 11.5, "beam_m": 2.1, "speed": 6.8,
		"points": [[13.7422, 100.4908], [13.7458, 100.4894], [13.7505, 100.4884], [13.7565, 100.4882]],
		"boats": [0.22, 0.64]},
	# Tha Tien <-> Wat Arun cross-river shuttle ferry
	{"id": "wat_arun_shuttle", "model": "cross_river_ferry", "length_m": 16.5, "beam_m": 6.0, "speed": 3.2,
		"points": [[13.7455, 100.4898], [13.7443, 100.4895]],
		"boats": [0.50]},
	# Illuminated Chao Phraya dinner cruise ship + traditional rice barge on outer channel
	{"id": "chao_phraya_dinner_cruise", "model": "dinner_cruise", "length_m": 36.0, "beam_m": 8.4, "speed": 3.8,
		"points": [[13.7410, 100.4922], [13.7468, 100.4891], [13.7535, 100.4879], [13.7635, 100.4926]],
		"boats": [0.35]},
	{"id": "chao_phraya_rice_barge", "model": "rice_barge", "length_m": 21.0, "beam_m": 5.8, "speed": 2.8,
		"points": [[13.7660, 100.4945], [13.7580, 100.4888], [13.7475, 100.4889], [13.7405, 100.4932]],
		"boats": [0.44]},
]

static func build(lm: LandmarkMesh, model: String, p: Dictionary) -> void:
	match model:
		"longtail":
			_longtail(lm, p)
		"chao_phraya_express":
			_express_boat(lm, p)
		"cross_river_ferry":
			_cross_ferry(lm, p)
		"saen_saep_boat":
			_saen_saep(lm, p)
		"dinner_cruise":
			_dinner_cruise(lm, p)
		_:
			_rice_barge(lm, p)

static func _base_hull(lm: LandmarkMesh, length: float, beam: float, fb: float, draft: float,
		bow_rise: float, hull_hex: String, detail: bool, maps: bool) -> Dictionary:
	var s := {"length": length, "beam": beam, "freeboard": fb, "draft": draft, "entry": 0.34,
		"bow_pow": 1.7, "stern_w": 0.68, "flare": 0.10, "deadrise": 0.22, "bow_rise": bow_rise,
		"stem_rake": length * 0.05, "stern_rake": 0.12, "keel_lift": 0.75, "boot_m": 0.12,
		"lod": 0 if detail else 1, "ultra": false}
	VesselMaterials.register(lm, maps, VesselMaterials.paint(hull_hex, maps, 0.42, 0.04),
		VesselMaterials.get_mat("antifoul", maps))
	ShipLights.register(lm, maps)
	HullLoft.loft(lm, s, {"hull": "Hull", "boot": "Boot", "bottom": "Bottom", "deck": "Deck"})
	return s

static func _longtail(lm: LandmarkMesh, p: Dictionary) -> void:
	var length: float = maxf(float(p.get("length", 11.5)), 8.0)
	var beam: float = float(p.get("beam", 0.0))
	if beam <= 0.0:
		beam = length * 0.19
	var detail: bool = bool(p.get("detail", true))
	var maps: bool = bool(p.get("maps", true))
	var fb := 0.68
	# Keep hull length `length * 0.80` shifted forward so hull + trailing propeller shaft equals `length`
	_base_hull(lm, length, beam, fb, 0.45, 0.62, "#244D7A", detail, maps)
	lm.use("Awning", ShipPaint.enamel(Color("#E3B42B"), maps))
	lm.use("Garland", ShipPaint.enamel(Color("#E04A26"), maps))
	var y0 := fb + 0.02
	# Raised bow stem post (`+X`) draped with colorful marigold/silk garlands
	var bow_x := length * 0.46
	lm.beam("Hull", Vector3(bow_x - 0.5, y0 + 0.35, 0), Vector3(bow_x + 0.15, y0 + 1.15, 0), 0.14, 0.18)
	if detail:
		lm.box("Garland", Vector3(bow_x - 0.02, y0 + 0.92, 0), Vector3(0.24, 0.28, 0.32), Basis(), 0.0)
	# Striped passenger awning amidships (`-0.24 L .. +0.18 L`)
	var a0 := -length * 0.24
	var a1 := length * 0.18
	lm.gable("Awning", Vector3((a0 + a1) * 0.5, y0 + 1.25, 0), beam * 0.92, a1 - a0, 0.26,
		Basis(Vector3.UP, PI * 0.5), 0.05, "Awning")
	if detail:
		for x in [a0 + 0.2, (a0 + a1) * 0.5, a1 - 0.2]:
			for sz in [-1.0, 1.0]:
				lm.beam("Steel", Vector3(float(x), y0, float(sz) * beam * 0.38),
					Vector3(float(x), y0 + 1.25, float(sz) * beam * 0.38), 0.04, 0.04)
		for bi in 4:
			lm.box("Deck", Vector3(a0 + 0.6 + float(bi) * (a1 - a0 - 1.2) / 3.0, y0 + 0.22, 0),
				Vector3(0.38, 0.22, beam * 0.68), Basis(), 0.0)
		# Pivoted stern car engine block & long angled propeller shaft (`Hang Yao`)
		var eng_x := -length * 0.34
		lm.box("Steel", Vector3(eng_x, y0 + 0.36, 0), Vector3(0.68, 0.52, 0.46), Basis(), 0.0)
		lm.beam("Steel", Vector3(eng_x - 0.25, y0 + 0.32, 0), Vector3(-length * 0.495, -0.04, 0), 0.06, 0.06)

static func _express_boat(lm: LandmarkMesh, p: Dictionary) -> void:
	var length: float = maxf(float(p.get("length", 26.0)), 16.0)
	var beam: float = float(p.get("beam", 0.0))
	if beam <= 0.0:
		beam = length * 0.20
	var detail: bool = bool(p.get("detail", true))
	var maps: bool = bool(p.get("maps", true))
	var fb := 1.25
	_base_hull(lm, length, beam, fb, 1.1, 0.42, "#F2F0E8", detail, maps)
	lm.use("Roof", ShipPaint.enamel(Color("#2D5F8B"), maps))
	lm.use("Flag", ShipPaint.enamel(Color(str(p.get("flag", "#E86A1E"))), maps))
	var y0 := fb + 0.02
	# Long low open-sided passenger saloon + raised forward wheelhouse + stern route flag
	VesselForms.cabin(lm, -length * 0.03, length * 0.72, beam * 0.82, y0, 1.95, 0.6, "White", 0.24, "Glass", "Roof")
	if detail:
		VesselForms.cabin(lm, length * 0.24, length * 0.16, beam * 0.68, y0 + 1.95, 1.35, 0.0, "White", 0.35, "Glass", "Roof")
		var stern_x := -length * 0.44
		lm.beam("Steel", Vector3(stern_x, y0, 0), Vector3(stern_x - 0.2, y0 + 2.8, 0), 0.06, 0.06)
		lm.box("Flag", Vector3(stern_x - 0.65, y0 + 2.45, 0), Vector3(0.95, 0.62, 0.05), Basis(), 0.0)

static func _cross_ferry(lm: LandmarkMesh, p: Dictionary) -> void:
	var length: float = maxf(float(p.get("length", 16.5)), 12.0)
	var beam: float = float(p.get("beam", 0.0))
	if beam <= 0.0:
		beam = length * 0.36
	var detail: bool = bool(p.get("detail", true))
	var maps: bool = bool(p.get("maps", true))
	var fb := 1.15
	_base_hull(lm, length, beam, fb, 0.95, 0.22, "#EAE8E0", detail, maps)
	lm.use("GreenRoof", ShipPaint.enamel(Color("#2D7A53"), maps))
	var y0 := fb + 0.02
	VesselForms.cabin(lm, 0.0, length * 0.74, beam * 0.84, y0, 2.1, 0.0, "White", 0.28, "Glass", "GreenRoof")
	if detail:
		VesselForms.cabin(lm, 0.0, 3.2, beam * 0.44, y0 + 2.1, 1.45, 0.0, "White", 0.35, "Glass", "GreenRoof")

static func _saen_saep(lm: LandmarkMesh, p: Dictionary) -> void:
	var length: float = maxf(float(p.get("length", 16.8)), 12.0)
	var beam: float = float(p.get("beam", 0.0))
	if beam <= 0.0:
		beam = length * 0.19
	var detail: bool = bool(p.get("detail", true))
	var maps: bool = bool(p.get("maps", true))
	var fb := 0.82
	_base_hull(lm, length, beam, fb, 0.65, 0.28, "#DFDDD4", detail, maps)
	lm.use("TarpBlue", ShipPaint.enamel(Color("#1F5AA6"), maps))
	var y0 := fb + 0.02
	# Low-clearance flat canal roof (passes under Phan Fa & Ratchathewi canal bridges!) + blue splash tarps
	lm.box("White", Vector3(0, y0 + 1.28, 0), Vector3(length * 0.76, 0.12, beam * 0.88), Basis(), 0.0)
	if detail:
		for sz in [-1.0, 1.0]:
			var z := float(sz) * beam * 0.41
			lm.box("TarpBlue", Vector3(0, y0 + 0.82, z), Vector3(length * 0.72, 0.52, 0.05), Basis(), 0.0)
			for ix in [-0.32, -0.10, 0.12, 0.34]:
				lm.beam("Steel", Vector3(ix * length, y0, z), Vector3(ix * length, y0 + 1.28, z), 0.04, 0.04)

static func _rice_barge(lm: LandmarkMesh, p: Dictionary) -> void:
	var length: float = maxf(float(p.get("length", 21.0)), 14.0)
	var beam: float = float(p.get("beam", 0.0))
	if beam <= 0.0:
		beam = length * 0.28
	var detail: bool = bool(p.get("detail", true))
	var maps: bool = bool(p.get("maps", true))
	var fb := 1.45
	_base_hull(lm, length, beam, fb, 1.35, 0.48, "#5A3824", detail, maps)
	lm.use("Hatch", ShipPaint.enamel(Color("#40484F"), maps))
	var y0 := fb + 0.02
	# Curved dark cargo hold hatch coaming + traditional aft teak cabin
	lm.gable("Hatch", Vector3(length * 0.04, y0, 0), beam * 0.74, length * 0.56, 1.15,
		Basis(Vector3.UP, PI * 0.5), 0.0, "Hatch")
	if detail:
		VesselForms.cabin(lm, -length * 0.32, length * 0.16, beam * 0.62, y0, 1.65, 0.0, "Hull", 0.22, "Glass", "Hatch")

static func _dinner_cruise(lm: LandmarkMesh, p: Dictionary) -> void:
	var length: float = maxf(float(p.get("length", 36.0)), 24.0)
	var beam: float = float(p.get("beam", 0.0))
	if beam <= 0.0:
		beam = length * 0.23
	var detail: bool = bool(p.get("detail", true))
	var maps: bool = bool(p.get("maps", true))
	var fb := 1.85
	_base_hull(lm, length, beam, fb, 1.5, 0.45, "#F6F4EE", detail, maps)
	lm.use("Gold", LandmarkMaterials.gold())
	lm.use("CruiseLamp", LandmarkMaterials.lit("#FFE49B", 2.2))
	var y0 := fb + 0.02
	VesselForms.cabin(lm, -length * 0.02, length * 0.76, beam * 0.84, y0, 2.35, 0.8, "White", 0.35, "Cabin0", "White")
	if detail:
		VesselForms.cabin(lm, -length * 0.05, length * 0.58, beam * 0.76, y0 + 2.4, 2.15, 0.6, "White", 0.40, "Cabin1", "White")
		# Glowing warm golden fairy-light strips along sheer & upper sun deck (`BK-10` lit dinner-cruise hulls!)
		for sz in [-1.0, 1.0]:
			lm.box("CruiseLamp", Vector3(-length * 0.02, y0 + 2.32, float(sz) * beam * 0.43),
				Vector3(length * 0.76, 0.12, 0.08), Basis(), 0.0)
			lm.box("CruiseLamp", Vector3(-length * 0.05, y0 + 4.52, float(sz) * beam * 0.39),
				Vector3(length * 0.58, 0.12, 0.08), Basis(), 0.0)
