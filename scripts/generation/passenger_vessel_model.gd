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
		"entry": 0.27, "bow_pow": 1.8, "stern_w": 0.4, "flare": 0.07, "deadrise": 0.0,
		"stern_round": 1.0, "stern_tail": 0.14,
		"bow_rise": fb * 0.55, "stern_rise": fb * 0.15, "stem_rake": length * 0.03,
		"stern_rake": length * 0.025, "keel_lift": 0.9, "lod": 0 if detail else 1}
	spec["ultra"] = bool(p.get("ultra", false))
	VesselMaterials.register(lm, maps, p["hull"], VesselMaterials.get_mat("antifoul", maps))
	ShipPaint.dress(lm, p["hull"], length, fb, maps)
	ShipLights.register(lm, maps)
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
		# Walkable deckhouse tops in grey non-slip paint, as on real boats:
		# white ones read as blank slabs from above.
		roof_y = VesselKit.house(lm, cx, l, w, y, floor_h, true, 1.5 if detail else 0.0, 0.14, "White",
			ShipLights.cabin_key(tier), "DeckSteel")
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
				for offset in [-0.3, 0.3]:
					VesselForms.davit(lm, Vector3(top_x + (float(k) - 0.5) * (boat_len + 1.0) - length * 0.04 + boat_len * float(offset),
						low_roof, float(s) * (upper_half + 0.04)), boat_len * 0.28, float(s) * boat_len * 0.16)
	# Wheelhouse on the forward end of the top tier, kept under the mast top.
	var wh_h := minf(minf(floor_h * 0.95, 2.4), h - roof_y - 0.25)
	var wh_x := top_x + top_l * 0.5 - length * 0.07
	var wh_w := top_w * 0.82
	var wh_l := length * 0.09
	if wh_h > 0.5:
		if detail:
			VesselForms.cabin(lm, wh_x, wh_l, wh_w, roof_y, wh_h, 0.8, "White", 0.3, "Glass", "DeckSteel")
			VesselForms.slab(lm, "DeckSteel", Vector3(wh_x - wh_h * 0.08, roof_y + wh_h + 0.05, 0),
				Vector3(wh_l + 0.5, 0.1, wh_w + 0.5), minf(wh_w * 0.12, wh_h * 0.4))
		else:
			lm.box("White", Vector3(wh_x, roof_y + wh_h * 0.5, 0), Vector3(wh_l, wh_h, wh_w), Basis(), 0.02)
			lm.quad("Glass", Vector3(wh_x + wh_l * 0.5 + 0.015, roof_y + wh_h * 0.3, -wh_w * 0.46),
				Vector3(wh_x + wh_l * 0.5 + 0.015, roof_y + wh_h * 0.3, wh_w * 0.46),
				Vector3(wh_x + wh_l * 0.5 + 0.015, roof_y + wh_h * 0.85, wh_w * 0.46),
				Vector3(wh_x + wh_l * 0.5 + 0.015, roof_y + wh_h * 0.85, -wh_w * 0.46), Vector3.RIGHT)
			VesselKit.windows(lm, wh_x - wh_l * 0.4, wh_x + wh_l * 0.4, wh_w * 0.5, roof_y + wh_h * 0.3, roof_y + wh_h * 0.85, 0.0)
			lm.box("DeckSteel", Vector3(wh_x, roof_y + wh_h + 0.05, 0), Vector3(wh_l + 0.5, 0.1, wh_w + 0.5), Basis(), 0.0)
	else:
		wh_h = 0.0
	# Funnel aft of the wheelhouse and two pole masts.
	var fr := clampf(beam * 0.11, 0.35, 1.5)
	var funnel_top := h * 0.97
	var f_base := Vector3(wh_x - wh_l * 0.5 - fr * 1.9 - length * 0.03, roof_y, 0)
	VesselKit.funnel(lm, f_base, maxf(funnel_top - roof_y, 0.8), fr, 1.55, "Funnel", "Black", detail)
	var fore := Vector3(length * 0.3, HullLoft.sheer(spec, length * 0.3), 0)
	var main := Vector3(-length * 0.32, HullLoft.sheer(spec, -length * 0.32), 0)
	VesselKit.mast(lm, "Black", fore, maxf(h - fore.y, 1.0), maxf(beam * 0.02, 0.07), detail)
	VesselKit.mast(lm, "Black", main, maxf(h * 0.78 - main.y, 1.0), maxf(beam * 0.018, 0.06), detail)
	if detail and wh_h > 0.0:
		ShipLights.nav(lm, wh_x, roof_y + wh_h * 0.55, wh_w * 0.5 + 0.12, Vector3(fore.x, h * 0.93, 0),
			Vector3(-length * 0.47, HullLoft.sheer(spec, -length * 0.47) + 0.6, 0),
			Vector3(main.x, h * 0.74, 0) if length > 50.0 else Vector3.INF)
	if detail:
		VesselForms.fittings(lm, spec)
		if bool(p.get("ultra", false)):
			VesselEquipment.deck(lm, spec)
			VesselEquipment.door(lm, Vector3(house_x - tier_len * 0.5, fb + 0.03, 0), minf(floor_h * 0.9, 1.9), minf(tier_w * 0.2, 0.9))
			VesselEquipment.ladder(lm, Vector3(house_x - tier_len * 0.5 - 0.12, fb, tier_w * 0.35), floor_h + 0.08, minf(0.65, beam * 0.16))
		lm.beam("Black", fore + Vector3(0, h * 0.8 - fore.y, 0), Vector3(length * 0.46, HullLoft.sheer(spec, length * 0.46), 0), 0.04)
		lm.beam("Black", fore + Vector3(0, h * 0.8 - fore.y, 0), Vector3(wh_x, roof_y + wh_h, 0), 0.04)
		lm.box("Black", fore + Vector3(0, h * 0.62 - fore.y, 0), Vector3(0.1, 0.1, beam * 0.55), Basis(), 0.0)
		VesselKit.guard(lm, spec, length * 0.2, length * 0.46, 0.9, 1.4, 0.04)
		VesselKit.guard(lm, spec, -length * 0.46, -length * 0.3, 0.9, 1.4, 0.04)
		VesselKit.guard(lm, spec, -length * 0.3, length * 0.2, 0.9, 1.4, 0.04)
		var boat_len := clampf(length * 0.08, 3.0, 7.0)
		var boat_mid := top_x - length * 0.04
		ClassicSteamerDetails.dress(lm, spec, {"house_x": house_x, "tier_len": tier_len, "tier_w": tier_w,
			"floor_h": floor_h, "decks": decks, "roof_y": roof_y, "wh_x": wh_x, "wh_l": wh_l,
			"wh_w": wh_w if wh_h > 0.0 else 0.0, "funnel": f_base, "fr": fr,
			"boat_x0": boat_mid - boat_len * 1.1 - 0.8, "boat_x1": boat_mid + boat_len * 1.1 + 0.8})
		# Portholes along the hull side.
		var n := int(length / 2.2)
		for i in n:
			var x := lerpf(-length * 0.38, length * 0.34, (float(i) + 0.5) / float(n))
			var py := fb * 0.52
			var pz := HullLoft.side_z(spec, x, py)
			for s in [-1.0, 1.0]:
				if bool(p.get("ultra", false)):
					VesselEquipment.porthole(lm, Vector3(x, py, float(s) * (pz + 0.02)), Vector3(0, 0, float(s)), clampf(fb * 0.11, 0.1, 0.25))
				else:
					lm.disc("Black", Vector3(x, py, float(s) * (pz + 0.01)), Vector3(0, 0, float(s)), clampf(fb * 0.11, 0.1, 0.25), 16)

static func _houseboat(lm: LandmarkMesh, p: Dictionary) -> void:
	var length: float = p["length"]
	var beam: float = p["beam"]
	var h: float = p["height"]
	var detail: bool = p.get("detail", true)
	var maps: bool = p.get("maps", true)
	var fb := clampf(h * 0.2, 0.55, 1.1)
	var spec := {"length": length, "beam": beam, "freeboard": fb, "draft": minf(beam * 0.14, 0.9),
		"entry": 0.15, "bow_pow": 2.6, "stern_w": 0.92, "flare": 0.04, "deadrise": 0.0,
		"bow_rise": fb * 0.2, "keel_lift": 0.35, "lod": 0 if detail else 1}
	spec["ultra"] = bool(p.get("ultra", false))
	VesselMaterials.register(lm, maps, p["hull"], VesselMaterials.get_mat("antifoul", maps))
	ShipLights.register(lm, maps)
	lm.use("Roof", VesselMaterials.get_mat("grey_deck", maps))
	HullLoft.loft(lm, spec, {"hull": "Hull", "boot": "Dark", "bottom": "Bottom", "deck": "Deck"})
	var y := fb + 0.03
	var wall := clampf(h - fb - beam * 0.14, 1.8, 3.0)
	var l := length * 0.58
	var w := beam * 0.78
	var cx := -length * 0.06
	var glass_key := ShipLights.cabin_key(0)
	if detail:
		VesselForms.cabin(lm, cx, l, w, y, wall, 1.35, "White", 0.0, glass_key, "Roof")
		lm.gable("Roof", Vector3(cx, y + wall, 0), w + 0.18, l + 0.2, beam * 0.12, Basis(Vector3.UP, PI * 0.5), 0.22, "White")
		VesselForms.fittings(lm, spec)
		# Wrap-around promenade guardrails (bow, sides and stern).
		VesselKit.guard(lm, spec, -length * 0.46, length * 0.46, 0.92, 1.4, 0.04)
		# Forward open terrace with canopy awning on dark stanchions (restaurant boat).
		var awn_x0 := cx + l * 0.5 + 0.15
		var awn_x1 := minf(length * 0.42, awn_x0 + length * 0.22)
		if awn_x1 - awn_x0 > 1.2:
			var awn_cx := (awn_x0 + awn_x1) * 0.5
			var awn_l := awn_x1 - awn_x0
			var awn_w := w * 0.92
			var awn_y := y + wall * 0.88
			lm.box("White", Vector3(awn_cx, awn_y, 0), Vector3(awn_l, 0.07, awn_w), Basis(), 0.0)
			for px in [awn_x0 + 0.12, awn_x1 - 0.12]:
				for sz in [-1.0, 1.0]:
					lm.beam("Dark", Vector3(px, y, sz * (awn_w * 0.46)), Vector3(px, awn_y, sz * (awn_w * 0.46)), 0.04)
		# Small aft wheelhouse/companionway + stove chimney + roof skylight.
		var ph_l := minf(l * 0.24, 2.6)
		var ph_w := w * 0.52
		var ph_h := clampf(wall * 0.52, 1.0, 1.5)
		var ph_x := cx - l * 0.34
		var roof_top := y + wall + beam * 0.12
		VesselForms.cabin(lm, ph_x, ph_l, ph_w, y + wall, ph_h, 0.9, "White", 0.12, glass_key, "Roof")
		lm.frustum("Dark", Vector3(cx + l * 0.18, roof_top, w * 0.18), 0.11, 0.11, 0.9, 8)
		lm.box("Dark", Vector3(cx + l * 0.02, roof_top + 0.08, 0), Vector3(l * 0.22, 0.16, w * 0.26), Basis(), 0.0)
		if bool(p.get("ultra", false)):
			VesselEquipment.deck(lm, spec)
			VesselEquipment.door(lm, Vector3(cx - l * 0.5, y, 0), wall * 0.8, w * 0.22)
			VesselEquipment.ladder(lm, Vector3(cx - l * 0.5 - 0.1, y, w * 0.3), wall, minf(0.6, w * 0.2))
		lm.box("Dark", Vector3(cx - l * 0.5 - 0.012, y + wall * 0.38, 0), Vector3(0.03, wall * 0.76, w * 0.2), Basis(), 0.0)
	else:
		lm.box("White", Vector3(cx, y + wall * 0.5, 0), Vector3(l, wall, w), Basis(), 0.03)
		VesselKit.windows(lm, cx - l * 0.5 + 0.4, cx + l * 0.5 - 0.4, w * 0.5, y + wall * 0.3, y + wall * 0.8, 0.0, glass_key)
		lm.gable("Roof", Vector3(cx, y + wall, 0), w, l, beam * 0.12, Basis(Vector3.UP, PI * 0.5), 0.22)

static func _tall_ship(lm: LandmarkMesh, p: Dictionary) -> void:
	var length: float = p["length"]
	var beam: float = p["beam"]
	var h: float = p["height"]
	var detail: bool = p.get("detail", true)
	var maps: bool = p.get("maps", true)
	var fb := clampf(length * 0.045, 1.2, 4.0)
	var spec := {"length": length, "beam": beam, "freeboard": fb, "draft": minf(beam * 0.4, 3.5),
		"entry": 0.3, "bow_pow": 1.7, "stern_w": 0.5, "flare": 0.1, "deadrise": 0.0,
		"stern_round": 1.0, "stern_tail": 0.14,
		"bow_rise": fb * 0.6, "stern_rise": fb * 0.4, "stem_rake": length * 0.05,
		"stern_rake": length * 0.025, "keel_lift": 0.9, "lod": 0 if detail else 1}
	spec["ultra"] = bool(p.get("ultra", false))
	VesselMaterials.register(lm, maps, p["hull"], VesselMaterials.get_mat("antifoul", maps))
	lm.use("Sail", VesselMaterials.get_mat("canvas", maps))
	lm.use("Boot", VesselMaterials.get_mat("red", maps))
	HullLoft.loft(lm, spec, {"hull": "Hull", "boot": "Boot", "bottom": "Bottom", "deck": "Deck"})
	var deck_y := fb + 0.02
	if detail:
		TallShipDetails.build(lm, spec, p, deck_y, h)
		return
	# Distant model: a deckhouse block, poles and yards with furled sails.
	lm.box("White", Vector3(-length * 0.34, deck_y + beam * 0.12, 0), Vector3(length * 0.2, beam * 0.24, beam * 0.6), Basis(), 0.03)
	VesselKit.windows(lm, -length * 0.42, -length * 0.26, beam * 0.3, deck_y + beam * 0.07, deck_y + beam * 0.18, 1.2)
	var masts := [0.28, -0.02, -0.3]
	for i in masts.size():
		var mx: float = length * float(masts[i])
		var mh: float = h * (0.82 if i == 1 else 0.7) if i < 2 else h * 0.55
		var mr := maxf(beam * 0.025, 0.1)
		VesselKit.mast(lm, "Steel", Vector3(mx, deck_y, 0), mh, mr, false)
		var yards := 3 if i < 2 else 1
		for k in yards:
			var yy := deck_y + mh * (0.38 + 0.2 * float(k))
			var span := beam * (1.5 - 0.3 * float(k)) if i < 2 else beam * 0.9
			lm.beam("Steel", Vector3(mx, yy, -span * 0.5), Vector3(mx, yy, span * 0.5), maxf(beam * 0.012, 0.06))
			if i < 2:
				lm.beam("Sail", Vector3(mx + mr + 0.1, yy - mr, -span * 0.46), Vector3(mx + mr + 0.1, yy - mr, span * 0.46), maxf(beam * 0.05, 0.2))
