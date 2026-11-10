class_name CruiseLinerModel
extends RefCounted

## Cruise liner (140-330 m): a long lofted steel hull (weathered plating,
## a thin boot-top, rows of hull windows, anchor pockets, mooring chocks
## and shell doors) with a short forecastle, then LinerSuperstructure's
## stack: lifeboat recess, balcony decks with a rounded front, the bridge
## with full-beam wings, terraced aft decks with a pool, sun decks, a
## raked funnel and a radar mast. `h` is the top of the mast. +X bow,
## centred on x = 0. Ferries are CruiseFerryModel.

const FUNNELS := ["#c93a2b", "#1f5d99", "#e8e4d6", "#e9b32e", "#2c3a4f"]
const HULLS := ["#1c2a43", "#e9e8e2", "#1b1c1f", "#2a4c6e"]
const SLIDES := ["#e9b32e", "#2f8fb0", "#d2452c"]

static func hull_hex(seed_value: float) -> String:
	return HULLS[int(absf(seed_value)) % HULLS.size()]

## The HullLoft spec of a liner `length` x `beam`.
static func spec(length: float, beam: float, detail: bool, ultra: bool) -> Dictionary:
	var hull_h := length * 0.042
	return {"length": length, "beam": beam, "freeboard": hull_h, "draft": length * 0.032,
		"entry": 0.17, "bow_pow": 1.9, "stern_w": 0.85, "flare": 0.1, "deadrise": 0.0,
		"bow_rise": hull_h * 0.3, "stem_rake": length * 0.022, "stern_rake": length * 0.004,
		"keel_lift": 0.8, "deck_inset": 0.2, "boot_m": clampf(length * 0.004, 0.4, 1.2),
		"anchors": false, "lod": 0 if detail else 1, "ultra": ultra}

static func build(lm: LandmarkMesh, p: Dictionary) -> void:
	var length: float = p["length"]
	var beam: float = p["beam"]
	var h: float = p["height"]
	var detail: bool = p.get("detail", true)
	var maps: bool = p.get("maps", true)
	var seed_value: float = p.get("seed", 0.0)
	var ultra := detail and bool(p.get("ultra", false))
	var s := spec(length, beam, detail, ultra)
	var hull_h: float = s["freeboard"]
	VesselMaterials.register(lm, maps, p["hull"], VesselMaterials.get_mat("antifoul", maps))
	ShipPaint.dress(lm, p["hull"], length, hull_h * 1.3, maps)
	ShipLights.register(lm, maps)
	lm.use("Orange", ShipPaint.enamel(Color("#e0651c"), maps))
	lm.use("DeckSteel", VesselMaterials.get_mat("grey_deck", maps))
	lm.use("Pool", VesselMaterials.get_mat("pool", maps))
	lm.use("Black", VesselMaterials.get_mat("black", maps))
	lm.use("Funnel", VesselMaterials.paint(str(p.get("funnel", FUNNELS[int(absf(seed_value) * 3.0) % FUNNELS.size()])), maps, 0.5, 0.05))
	lm.use("Slide", VesselMaterials.paint(SLIDES[int(absf(seed_value) * 7.0) % SLIDES.size()], maps, 0.3, 0.0))
	HullLoft.loft(lm, s, {"hull": "Hull", "boot": "Boot", "bottom": "Bottom", "deck": "DeckSteel"})
	var a := LinerSuperstructure.build(lm, p, s, {"y0": hull_h + 0.02, "top": h * 0.84,
		"front": length * 0.35, "aft": -length * 0.45, "terraces": true, "boats": true,
		"balconies": true, "pool": true, "slide": ultra, "funnel_x": -length * 0.1})
	var n: int = a["n"]
	var tops: Array = a["deck_tops"]
	var afts: Array = a["afts"]
	# A terrace pool aft.
	var pool_i := int(n * 0.55)
	if pool_i >= 1 and pool_i < n:
		var pool_length := maxf(0.5, minf(length * 0.07, float(afts[pool_i]) - float(afts[pool_i - 1]) - 1.0))
		lm.box("Pool", Vector3((float(afts[pool_i]) + float(afts[pool_i - 1])) * 0.5, float(tops[pool_i - 1]) + 0.08, 0),
			Vector3(pool_length, 0.06, beam * 0.3), Basis(), 0.0)
	if not detail:
		return
	# Hull: two rows of cabin windows, anchors, chocks and shell doors.
	ShipHullKit.windows(lm, s, "Cabin1", -length * 0.38, length * 0.3, hull_h * 0.52, 1.1, 0.75, 3.2)
	ShipHullKit.windows(lm, s, "Cabin2", -length * 0.38, length * 0.3, hull_h * 0.76, 1.1, 0.75, 3.2)
	ShipHullKit.anchor_pocket(lm, s, length * 0.43, clampf(length * 0.012, 1.4, 3.5))
	ShipHullKit.chocks(lm, s, [length * 0.455, length * 0.37, -length * 0.36, -length * 0.46], 0.9)
	for x in [length * 0.16, -length * 0.12]:
		ShipHullKit.shell_door(lm, s, float(x), hull_h * 0.3, 3.2, 2.4)
	# Forecastle: windlasses, mooring winches, bulwark rail and stern rail.
	VesselForms.fittings(lm, s)
	if ultra:
		VesselEquipment.deck(lm, s)
	for side in [-1.0, 1.0]:
		VesselEquipment.winch(lm, Vector3(length * 0.42, HullLoft.sheer(s, length * 0.42), float(side) * beam * 0.18), 0.9)
		VesselEquipment.winch(lm, Vector3(-length * 0.47, HullLoft.sheer(s, -length * 0.47), float(side) * beam * 0.3), 0.8)
	lm.box("DeckSteel", Vector3(length * 0.4, hull_h + 0.5, 0), Vector3(3.0, 1.0, beam * 0.22), Basis(), 0.02)
	HullLoft.rail(lm, "White", s, length * 0.36, length * 0.49, 1.1, 2.5, 0.0, 0.25, 0.05)
	HullLoft.rail(lm, "White", s, -length * 0.49, -length * 0.45, 1.1, 2.5, 0.0, 0.25, 0.05)
