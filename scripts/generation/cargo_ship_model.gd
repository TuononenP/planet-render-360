class_name CargoShipModel
extends RefCounted

## Cargo ships (80-300 m), by variant:
## - "container": fine-lined hull, container bays forward of an aft
##   accommodation block tall enough to see over the stacks;
## - "bulk": full-bodied hull, five to nine hatch holds and four cranes;
## - "tanker": full hull, red pipe deck, manifold, catwalk, hose crane;
## - "general": a small multipurpose ship with two holds and cranes.
## Steel hull paint (ShipPaint), a bulbous bow, anchor pockets, chocks,
## a forecastle with windlasses, the accommodation block with bridge
## wings, an integrated funnel, a radar mast and a foremast, lit cabins,
## navigation lights and deck floodlights. `h` is the top of the mast.
## +X bow, centred on x = 0.
const FUNNELS := ["#202225", "#b53a2c", "#1f5d99", "#e9b32e", "#e6e4db"]
const HATCHES := ["#2f6e3e", "#9c2b22", "#2b5d8a", "#c8792a"]
const VARIANTS := ["container", "bulk", "tanker", "general"]

static func spec(length: float, beam: float, variant: String, detail: bool, ultra: bool) -> Dictionary:
	var full := variant in ["bulk", "tanker"]
	var fb: float = length * float({"container": 0.036, "bulk": 0.03, "tanker": 0.028}.get(variant, 0.034))
	return {"length": length, "beam": beam, "freeboard": fb, "draft": length * (0.06 if full else 0.048),
		"entry": 0.13 if full else 0.24, "bow_pow": 2.7 if full else 1.8, "stern_w": 0.8,
		"flare": 0.03, "deadrise": 0.0, "bow_rise": fb * 0.35, "stern_rise": fb * 0.1,
		"stem_rake": length * 0.018, "stern_rake": length * 0.006, "keel_lift": 0.7,
		"deck_inset": 0.15, "boot_m": clampf(length * 0.006, 0.6, 1.6), "anchors": false,
		"lod": 0 if detail else 1, "ultra": ultra}

static func build(lm: LandmarkMesh, p: Dictionary) -> void:
	var length: float = p["length"]
	var beam: float = p["beam"]
	var h: float = p["height"]
	var detail: bool = p.get("detail", true)
	var maps: bool = p.get("maps", true)
	var seed_value: float = p.get("seed", 0.0)
	var ultra := detail and bool(p.get("ultra", false))
	var variant := str(p.get("variant", ""))
	if variant not in VARIANTS:
		variant = "general"
	var s := spec(length, beam, variant, detail, ultra)
	var fb: float = s["freeboard"]
	VesselMaterials.register(lm, maps, p["hull"], VesselMaterials.get_mat("antifoul", maps))
	ShipPaint.dress(lm, p["hull"], length, fb, maps)
	ShipLights.register(lm, maps)
	CargoDeckGear.register(lm, maps)
	var pick := int(absf(seed_value) * 97.0)
	lm.use("Funnel", ShipPaint.enamel(Color(FUNNELS[pick % FUNNELS.size()]), maps))
	lm.use("Hatch", ShipPaint.enamel(Color(HATCHES[pick % HATCHES.size()]), maps))
	lm.use("Black", VesselMaterials.get_mat("black", maps))
	lm.use("Orange", ShipPaint.enamel(Color("#e0651c"), maps))
	var deck_colour := "#6e2a22" if variant == "tanker" else "#7e8885"
	lm.use("DeckSteel", VesselMaterials.paint(deck_colour, maps, 0.8, 0.05))
	HullLoft.loft(lm, s, {"hull": "Hull", "boot": "Boot", "bottom": "Bottom", "deck": "DeckSteel"})
	var deck_y := fb
	# Accommodation block aft, its height set by what the bridge must see over.
	var tiers: int = int({"container": 7, "bulk": 5, "tanker": 5}.get(variant, 4))
	var tier_h := minf(2.8, (h * 0.72 - deck_y) / float(tiers + 1))
	var house_l := clampf(length * 0.065, 9.0, 20.0)
	var house_x := -length * 0.37 if variant != "container" else -length * 0.33
	var house_w := beam * 0.72
	var y := deck_y + 0.02
	for i in tiers:
		_tier(lm, house_x, house_l, house_w, y, tier_h, "Glass" if i == tiers - 1 else ShipLights.cabin_key(i), detail)
		y += tier_h
	y += 0.1
	var bridge_y := y - tier_h - 0.1
	if detail:
		VesselForms.cabin(lm, house_x + house_l * 0.5 - 2.5, 4.0, beam * 1.02, bridge_y, tier_h, 0.0, "White", 0.0, "Glass")
	else:
		lm.box("White", Vector3(house_x + house_l * 0.5 - 2.5, bridge_y + tier_h * 0.5, 0), Vector3(4.0, tier_h, beam * 1.02), Basis(), 0.0)
	var top_y := y
	# Funnel built into the aft end of the block; radar mast on the bridge.
	var fr := beam * 0.09
	var f_x := house_x - house_l * 0.5 + fr * 0.6
	var f_top := minf(top_y + tier_h * 1.8, h * 0.9)
	VesselKit.funnel(lm, Vector3(f_x, top_y - tier_h * 1.5, 0), f_top - top_y + tier_h * 1.5, fr, 1.6, "Funnel", "Black", detail)
	var mast_x := house_x + house_l * 0.2
	VesselKit.mast(lm, "White", Vector3(mast_x, top_y, 0), h - top_y, maxf(beam * 0.01, 0.15), detail)
	lm.box("Steel", Vector3(mast_x, top_y + (h - top_y) * 0.6, 0), Vector3(0.8, 0.2, 4.5), Basis(), 0.0)
	# Cargo spaces between the forecastle and the block.
	var x0 := house_x + house_l * 0.5 + 3.0
	var x1 := length * 0.4
	match variant:
		"container":
			CargoDeckGear.containers(lm, s, x0, x1, deck_y, seed_value, detail,
				clampi(int((h * 0.62 - deck_y) / CargoDeckGear.TIER_M), 2, 7))
		"tanker":
			CargoDeckGear.tanker(lm, s, x0, x1, deck_y, beam, detail)
		_:
			var holds := clampi(int((x1 - x0) / 22.0), 2, 9)
			CargoDeckGear.hatches(lm, s, x0, x1, deck_y, holds)
			var cranes := 4 if variant == "bulk" else 2
			var step := (x1 - x0) / float(holds)
			for k in cranes:
				var hold := int(round(float(k + 1) * float(holds) / float(cranes + 1)))
				CargoDeckGear.crane(lm, Vector3(x0 + float(hold) * step, deck_y, beam * 0.25 if k % 2 == 0 else -beam * 0.25),
					clampf(beam * 0.9, 12.0, 30.0), 1.0, detail)
	if not detail:
		return
	# Foremast, forecastle and stern mooring gear, hull details, lights.
	var fore := Vector3(length * 0.44, HullLoft.sheer(s, length * 0.44), 0)
	VesselKit.mast(lm, "Hatch", fore, maxf(h * 0.55 - fore.y, 6.0), 0.3, true)
	ShipHullKit.bulb(lm, s, "Bottom", length * 0.025)
	ShipHullKit.anchor_pocket(lm, s, length * 0.43, clampf(length * 0.012, 1.4, 3.5))
	ShipHullKit.chocks(lm, s, [length * 0.46, length * 0.38, -length * 0.42, -length * 0.475], 0.8)
	VesselForms.fittings(lm, s)
	for side in [-1.0, 1.0]:
		VesselEquipment.winch(lm, Vector3(length * 0.42, HullLoft.sheer(s, length * 0.42), float(side) * beam * 0.2), 0.9)
		VesselEquipment.winch(lm, Vector3(-length * 0.46, HullLoft.sheer(s, -length * 0.46), float(side) * beam * 0.28), 0.8)
	VesselKit.guard(lm, s, length * 0.4, length * 0.49, 1.1, 2.0, 0.05)
	VesselKit.guard(lm, s, -length * 0.49, house_x - house_l * 0.5, 1.1, 2.0, 0.05)
	VesselKit.guard(lm, s, house_x - house_l * 0.5, length * 0.4, 1.0, 3.0, 0.04)
	ShipLights.nav(lm, house_x + house_l * 0.5 - 2.5, bridge_y + tier_h * 0.85, beam * 0.51 + 0.25,
		fore + Vector3(0, maxf(h * 0.55 - fore.y, 6.0) - 0.4, 0),
		Vector3(-length * 0.5 + 0.3, HullLoft.sheer(s, -length * 0.49) + 1.0, 0), Vector3(mast_x, h - 0.4, 0))
	ShipLights.deck_lamps(lm, house_x - house_l * 0.5, house_x + house_l * 0.5, top_y - 0.3, house_w * 0.5 + 0.2, 4.0, 0.15)

## One flat-walled accommodation tier: steel walls, a window row on every
## face (cabin glass, or plain bridge glass on top) and a thin deck edge.
static func _tier(lm: LandmarkMesh, cx: float, l: float, w: float, y: float, th: float, key: String, detail: bool) -> void:
	lm.box("White", Vector3(cx, y + th * 0.5, 0), Vector3(l, th, w), Basis(), 0.0)
	VesselKit.windows(lm, cx - l * 0.5 + 1.0, cx + l * 0.5 - 1.0, w * 0.5, y + th * 0.38, y + th * 0.78, 1.6 if detail else 0.0, key)
	for end in [-1.0, 1.0]:
		lm.box(key, Vector3(cx + float(end) * (l * 0.5 + 0.01), y + th * 0.58, 0), Vector3(0.02, th * 0.4, w * 0.8), Basis(), 0.0)
	if detail:
		lm.box("White", Vector3(cx, y + th - 0.05, 0), Vector3(l + 0.4, 0.1, w + 0.4), Basis(), 0.0)
