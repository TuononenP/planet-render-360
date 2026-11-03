class_name PassengerVesselModel
extends RefCounted

## Classic coastal passenger ships, houseboat barges and moored tall ships.
## The hull is lofted (sheer line, flared raked stem, counter stern, boot
## stripe, portholes); the superstructure is stepped decks with window bands,
## a wheelhouse with raked glass, a banded funnel, masts and lifeboats on
## the boat deck. `h` is the top of the highest mast or funnel. +X bow.

const FUNNELS := ["#c9b98a", "#b53a2c", "#e4e0d2", "#2f4f6f"]

static func build(lm: LandmarkMesh, p: Dictionary) -> void:
	match str(p.get("variant", "classic")):
		"houseboat":
			_houseboat(lm, p)
		"tall_ship":
			_tall_ship(lm, p)
		_:
			_classic(lm, p)

static func _classic(lm: LandmarkMesh, p: Dictionary) -> void:
	var length: float = p["length"]
	var beam: float = p["beam"]
	var h: float = p["height"]
	var detail: bool = p.get("detail", true)
	var maps: bool = p.get("maps", true)
	var fb := clampf(h * 0.2, 1.1, 4.2)
	var spec := {"length": length, "beam": beam, "freeboard": fb, "draft": minf(beam * 0.3, 2.6),
		"entry": 0.27, "bow_pow": 1.8, "stern_w": 0.62, "flare": 0.07, "deadrise": 0.0,
		"bow_rise": fb * 0.55, "stern_rise": fb * 0.15, "stem_rake": length * 0.03,
		"stern_rake": length * 0.012, "keel_lift": 0.9, "lod": 0 if detail else 1}
	VesselMaterials.register(lm, maps, p["hull"], VesselMaterials.get_mat("antifoul", maps))
	lm.use("Boot", VesselMaterials.get_mat("red", maps))
	lm.use("Funnel", VesselMaterials.paint(str(p.get("funnel", FUNNELS[int(length) % FUNNELS.size()])), maps, 0.5, 0.05))
	lm.use("Black", VesselMaterials.get_mat("black", maps))
	lm.use("Orange", VesselMaterials.get_mat("orange", maps))
	lm.use("DeckSteel", VesselMaterials.get_mat("grey_deck", maps))
	HullLoft.loft(lm, spec, {"hull": "Hull", "boot": "Boot", "bottom": "Bottom", "deck": "DeckSteel"})
	var decks := 1 if length < 24.0 else (2 if length < 55.0 else 3)
	var total := maxf(h - fb, 1.0)
	var floor_h := minf(total * 0.62 / float(decks), 2.9)
	var y := fb + 0.02
	var roof_y := y
	var house_x := -length * 0.06
	var tier_len := length * 0.56
	var tier_w := beam * 0.74
	for tier in decks:
		var cx := house_x - tier * length * 0.02
		var l := tier_len - tier * length * 0.13
		var w := tier_w - tier * beam * 0.1
		roof_y = VesselKit.house(lm, cx, l, w, y, floor_h, true, 1.5 if detail else 0.0, 0.14)
		y = roof_y
	# Boat deck: lifeboats beside the second tier, rails round the top tier.
	var top_x := house_x - (decks - 1) * length * 0.02
	var top_l := tier_len - (decks - 1) * length * 0.13
	var top_w := tier_w - (decks - 1) * beam * 0.1
	if detail and decks >= 2:
		var boat_len := clampf(length * 0.08, 3.0, 7.0)
		var low_roof := fb + 0.02 + floor_h + 0.08
		var upper_half := (tier_w - beam * 0.1) * 0.5
		for s in [-1.0, 1.0]:
			for k in 2:
				VesselKit.lifeboat(lm, Vector3(top_x + (float(k) - 0.5) * (boat_len + 1.0) - length * 0.04,
					low_roof + 0.12, float(s) * (upper_half + boat_len * 0.16 + 0.08)), boat_len)
	# Wheelhouse on the forward end of the top tier, kept under the mast top.
	var wh_h := minf(minf(floor_h * 0.95, 2.4), h - roof_y - 0.25)
	var wh_x := top_x + top_l * 0.5 - length * 0.07
	var wh_w := top_w * 0.82
	var wh_l := length * 0.09
	if wh_h > 0.5:
		lm.box("White", Vector3(wh_x, roof_y + wh_h * 0.5, 0), Vector3(wh_l, wh_h, wh_w), Basis(), 0.02)
		lm.quad("Glass", Vector3(wh_x + wh_l * 0.5 + 0.015, roof_y + wh_h * 0.3, -wh_w * 0.46),
			Vector3(wh_x + wh_l * 0.5 + 0.015, roof_y + wh_h * 0.3, wh_w * 0.46),
			Vector3(wh_x + wh_l * 0.5 + 0.015, roof_y + wh_h * 0.85, wh_w * 0.46),
			Vector3(wh_x + wh_l * 0.5 + 0.015, roof_y + wh_h * 0.85, -wh_w * 0.46), Vector3.RIGHT)
		VesselKit.windows(lm, wh_x - wh_l * 0.4, wh_x + wh_l * 0.4, wh_w * 0.5, roof_y + wh_h * 0.3, roof_y + wh_h * 0.85, 0.0)
		lm.box("White", Vector3(wh_x, roof_y + wh_h + 0.05, 0), Vector3(wh_l + 0.5, 0.1, wh_w + 0.5), Basis(), 0.0)
	else:
		wh_h = 0.0
	# Funnel aft of the wheelhouse and two pole masts.
	var fr := clampf(beam * 0.11, 0.35, 1.5)
	var funnel_top := h * 0.97
	var f_base := Vector3(wh_x - wh_l * 0.5 - fr * 1.9 - length * 0.03, roof_y, 0)
	VesselKit.funnel(lm, f_base, maxf(funnel_top - roof_y, 0.8), fr, 1.55)
	var fore := Vector3(length * 0.3, HullLoft.sheer(spec, length * 0.3), 0)
	var main := Vector3(-length * 0.32, HullLoft.sheer(spec, -length * 0.32), 0)
	VesselKit.mast(lm, "Black", fore, maxf(h - fore.y, 1.0), maxf(beam * 0.02, 0.07))
	VesselKit.mast(lm, "Black", main, maxf(h * 0.78 - main.y, 1.0), maxf(beam * 0.018, 0.06))
	if detail:
		lm.beam("Black", fore + Vector3(0, h * 0.8 - fore.y, 0), Vector3(length * 0.46, HullLoft.sheer(spec, length * 0.46), 0), 0.04)
		lm.beam("Black", fore + Vector3(0, h * 0.8 - fore.y, 0), Vector3(wh_x, roof_y + wh_h, 0), 0.04)
		lm.box("Black", fore + Vector3(0, h * 0.62 - fore.y, 0), Vector3(0.1, 0.1, beam * 0.55), Basis(), 0.0)
		VesselKit.guard(lm, spec, length * 0.2, length * 0.46, 0.9, 1.4, 0.04)
		VesselKit.guard(lm, spec, -length * 0.46, -length * 0.3, 0.9, 1.4, 0.04)
		VesselKit.guard(lm, spec, -length * 0.3, length * 0.2, 0.9, 1.4, 0.04)
		# Portholes along the hull side.
		var n := int(length / 2.2)
		for i in n:
			var x := lerpf(-length * 0.38, length * 0.34, (float(i) + 0.5) / float(n))
			var py := fb * 0.52
			var pz := HullLoft.side_z(spec, x, py)
			for s in [-1.0, 1.0]:
				lm.disc("Black", Vector3(x, py, float(s) * (pz + 0.01)), Vector3(0, 0, float(s)), clampf(fb * 0.11, 0.1, 0.25), 8)

static func _houseboat(lm: LandmarkMesh, p: Dictionary) -> void:
	var length: float = p["length"]
	var beam: float = p["beam"]
	var h: float = p["height"]
	var maps: bool = p.get("maps", true)
	var fb := clampf(h * 0.18, 0.45, 0.9)
	var spec := {"length": length, "beam": beam, "freeboard": fb, "draft": minf(beam * 0.12, 0.8),
		"entry": 0.12, "bow_pow": 3.0, "stern_w": 0.95, "flare": 0.0, "deadrise": 0.0,
		"bow_rise": fb * 0.15, "keel_lift": 0.3, "lod": 0 if p.get("detail", true) else 1}
	VesselMaterials.register(lm, maps, p["hull"], VesselMaterials.get_mat("antifoul", maps))
	lm.use("Roof", VesselMaterials.get_mat("grey_deck", maps))
	HullLoft.loft(lm, spec, {"hull": "Hull", "boot": "Dark", "bottom": "Bottom", "deck": "Deck"})
	var y := fb + 0.03
	var wall := maxf(h - fb - beam * 0.14, 1.4)
	var l := length * 0.68
	var w := beam * 0.8
	lm.box("White", Vector3(-length * 0.04, y + wall * 0.5, 0), Vector3(l, wall, w), Basis(), 0.03)
	VesselKit.windows(lm, -length * 0.04 - l * 0.5 + 0.4, -length * 0.04 + l * 0.5 - 0.4, w * 0.5, y + wall * 0.3, y + wall * 0.8, 1.6 if p.get("detail", true) else 0.0)
	lm.gable("Roof", Vector3(-length * 0.04, y + wall, 0), w, l, beam * 0.14, Basis(Vector3.UP, PI * 0.5), 0.25)
	if p.get("detail", true):
		VesselKit.guard(lm, spec, length * 0.32, length * 0.46, 0.9, 1.0)
		lm.box("Dark", Vector3(-length * 0.18, y + wall + beam * 0.16, w * 0.15), Vector3(0.28, beam * 0.1, 0.28), Basis(), 0.0)

static func _tall_ship(lm: LandmarkMesh, p: Dictionary) -> void:
	var length: float = p["length"]
	var beam: float = p["beam"]
	var h: float = p["height"]
	var detail: bool = p.get("detail", true)
	var maps: bool = p.get("maps", true)
	var fb := clampf(length * 0.045, 1.2, 4.0)
	var spec := {"length": length, "beam": beam, "freeboard": fb, "draft": minf(beam * 0.4, 3.5),
		"entry": 0.3, "bow_pow": 1.7, "stern_w": 0.7, "flare": 0.1, "deadrise": 0.0,
		"bow_rise": fb * 0.6, "stern_rise": fb * 0.4, "stem_rake": length * 0.05,
		"stern_rake": length * 0.01, "keel_lift": 0.9, "lod": 0 if detail else 1}
	VesselMaterials.register(lm, maps, p["hull"], VesselMaterials.get_mat("antifoul", maps))
	lm.use("Sail", VesselMaterials.get_mat("canvas", maps))
	lm.use("Boot", VesselMaterials.get_mat("red", maps))
	HullLoft.loft(lm, spec, {"hull": "Hull", "boot": "Boot", "bottom": "Bottom", "deck": "Deck"})
	var deck_y := fb + 0.02
	lm.box("White", Vector3(-length * 0.34, deck_y + beam * 0.12, 0), Vector3(length * 0.2, beam * 0.24, beam * 0.6), Basis(), 0.03)
	VesselKit.windows(lm, -length * 0.42, -length * 0.26, beam * 0.3, deck_y + beam * 0.07, deck_y + beam * 0.18, 1.2)
	var masts := [0.28, -0.02, -0.3]
	for i in masts.size():
		var mx: float = length * float(masts[i])
		var mh: float = h * (0.82 if i == 1 else 0.7) if i < 2 else h * 0.55
		var mr := maxf(beam * 0.025, 0.1)
		VesselKit.mast(lm, "Steel", Vector3(mx, deck_y, 0), mh, mr)
		# Yards across the mast, each with a furled sail along it.
		var yards := 3 if i < 2 else 1
		for k in yards:
			var yy := deck_y + mh * (0.38 + 0.2 * float(k))
			var span := beam * (1.5 - 0.3 * float(k)) if i < 2 else beam * 0.9
			lm.beam("Steel", Vector3(mx, yy, -span * 0.5), Vector3(mx, yy, span * 0.5), maxf(beam * 0.012, 0.06))
			if i < 2:
				lm.beam("Sail", Vector3(mx + mr + 0.1, yy - mr, -span * 0.46), Vector3(mx + mr + 0.1, yy - mr, span * 0.46), maxf(beam * 0.05, 0.2))
	if detail:
		lm.beam("Steel", Vector3(length * 0.4, fb + beam * 0.05, 0), Vector3(length * 0.5, fb + beam * 0.2, 0), 0.12)
		VesselKit.guard(lm, spec, -length * 0.46, length * 0.46, 1.0, 1.2, 0.04)
