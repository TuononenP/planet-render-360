class_name IcebreakerModel
extends RefCounted

## Finnish state icebreaker (Urho, Otso and Voima classes, 80-105 m): a
## short, very wide steel hull with a raked icebreaking stem and a rounded
## bilge, painted red with a black boot top; a white deckhouse forward of
## amidships stepping up to the bridge with wide wings, a black-topped
## funnel behind it, a lattice-free mast, and the open working deck aft
## with a crane. The ship's name on both bows in white. Metres, +X bow,
## waterline y = 0, centred on x = 0.
## `p`: length, beam, name, detail, maps, ultra.

const HULL_RED := "#a3281f"

static func spec(length: float, beam: float, detail: bool, ultra: bool) -> Dictionary:
	return {"length": length, "beam": beam, "freeboard": clampf(length * 0.085, 6.0, 9.5),
		"draft": clampf(length * 0.08, 5.5, 8.5), "entry": 0.22, "bow_pow": 1.6,
		"stern_w": 0.8, "flare": 0.14, "deadrise": 0.0, "stern_round": 0.7, "stern_tail": 0.12,
		"bow_rise": length * 0.01, "stem_rake": length * 0.05, "stern_rake": length * 0.006,
		"keel_lift": 0.6, "boot_m": 0.9, "lod": 0 if detail else 1, "ultra": ultra}

static func build(lm: LandmarkMesh, p: Dictionary) -> void:
	var length: float = p["length"]
	var beam: float = p["beam"]
	var detail: bool = p.get("detail", true)
	var maps: bool = p.get("maps", true)
	var s := spec(length, beam, detail, detail and bool(p.get("ultra", false)))
	var fb: float = s["freeboard"]
	VesselMaterials.register(lm, maps, VesselMaterials.paint(HULL_RED, maps), VesselMaterials.get_mat("antifoul", maps))
	ShipPaint.dress(lm, VesselMaterials.paint(HULL_RED, maps), length, fb, maps, Color("#1b1b1d"))
	ShipLights.register(lm, maps)
	lm.use("DeckSteel", VesselMaterials.get_mat("grey_deck", maps))
	lm.use("Black", VesselMaterials.get_mat("black", maps))
	lm.use("Lettering", ShipPaint.enamel(Color("#f2f0ea"), maps))
	HullLoft.loft(lm, s, {"hull": "Hull", "boot": "Boot", "bottom": "Bottom", "deck": "DeckSteel"})
	var y0 := fb + 0.02
	var w0 := beam * 0.7
	# The deckhouse forward of amidships, three tiers narrowing to the bridge.
	var front := length * 0.3
	var aft := -length * 0.04
	VesselForms.cabin(lm, (front + aft) * 0.5, front - aft, w0, y0, 3.0, 1.3, "White", 0.12, "Cabin0", "DeckSteel")
	var y1 := y0 + 3.05
	VesselForms.cabin(lm, (front + aft) * 0.5 - length * 0.01, front - aft - length * 0.05, w0 * 0.86, y1, 2.8, 1.3,
		"White", 0.12, "Cabin1", "DeckSteel")
	var y2 := y1 + 2.85
	var bridge_len := length * 0.1
	var bridge_x := front - length * 0.07
	VesselForms.cabin(lm, bridge_x, bridge_len, w0 * 0.78, y2, 2.4, 0.0, "White", 0.3, "Glass", "DeckSteel")
	var y3 := y2 + 2.45
	if detail:
		# Bridge wings reaching past the hull sides.
		lm.box("White", Vector3(bridge_x + 0.4, y2 + 0.9, 0), Vector3(bridge_len * 0.55, 0.12, beam * 1.02), Basis(), 0.0)
		HullLoft.rail(lm, "White", s, length * 0.3, length * 0.47, 1.1, 1.6, 0.0, 0.2, 0.06)
	# Funnel behind the house, a mast on the bridge roof.
	VesselKit.funnel(lm, Vector3(aft - length * 0.05, y1 + 2.7, 0), 5.5, beam * 0.1, 1.7, "White", "Black", detail)
	VesselKit.mast(lm, "White", Vector3(bridge_x - 0.5, y3, 0), 9.0, 0.22, detail)
	lm.box("Steel", Vector3(bridge_x - 0.5, y3 + 5.5, 0), Vector3(1.0, 0.18, 5.2), Basis(), 0.0)
	# The working deck aft: a crane and winch housings.
	var crane_x := -length * 0.26
	lm.box("White", Vector3(crane_x, y0 + 1.2, beam * 0.26), Vector3(2.0, 2.4, 2.0), Basis(), 0.0)
	lm.beam("Steel", Vector3(crane_x, y0 + 2.4, beam * 0.26), Vector3(crane_x - length * 0.1, y0 + 6.2, beam * 0.3), 0.35)
	lm.box("Steel", Vector3(-length * 0.38, y0 + 0.6, 0), Vector3(3.2, 1.2, beam * 0.3), Basis(), 0.0)
	var name := str(p.get("name", ""))
	if name != "":
		HullLettering.on_hull(lm, "Lettering", s, name, length * 0.2, fb * 0.62, minf(fb * 0.3, 2.2))
	if detail:
		ShipLights.nav(lm, bridge_x, y2 + 1.1, beam * 0.51 + 0.2, Vector3(bridge_x - 0.5, y3 + 9.0, 0),
			Vector3(-length * 0.5 + 0.4, fb + 0.8, 0))
		VesselForms.fittings(lm, s)
