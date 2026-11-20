class_name MalarVesselModels
extends RefCounted

## Two hull types for Stockholm's moored row beside PassengerVesselModel's
## (metres, +X bow, y = 0 at the waterline, `p` as that model's: length, beam,
## height (the funnel or mast top), hull, funnel, detail, maps, ultra):
## * "steam_yacht": an old steam yacht, a low slim hull with a clipper stem,
##   one short deckhouse and bridge, a tall funnel and two masts raked aft;
## * "archipelago": a plain white skärgårdsbåt, a long flat deckhouse under a
##   grey roof, a small wheelhouse forward and a stubby funnel.
## `spec` gives any of the row's models' hull (the numbers of the model
## that builds it), which ShipMooring needs to hang its lines from.
const MODELS := ["steam_yacht", "archipelago"]

static func build(lm: LandmarkMesh, p: Dictionary, model: String) -> void:
	var length: float = p["length"]
	var beam: float = p["beam"]
	var h: float = p["height"]
	var detail: bool = p.get("detail", true)
	var maps: bool = p.get("maps", true)
	var yacht := model == "steam_yacht"
	var s := spec(model, length, beam, h, detail)
	s["ultra"] = bool(p.get("ultra", false))
	var fb: float = s["freeboard"]
	VesselMaterials.register(lm, maps, p["hull"], VesselMaterials.get_mat("antifoul", maps))
	ShipPaint.dress(lm, p["hull"], length, fb, maps)
	ShipLights.register(lm, maps)
	lm.use("Funnel", VesselMaterials.paint(str(p.get("funnel", "#a8352a")), maps, 0.5, 0.05))
	lm.use("Black", VesselMaterials.get_mat("black", maps))
	lm.use("DeckSteel", VesselMaterials.get_mat("grey_deck", maps))
	HullLoft.loft(lm, s, {"hull": "Hull", "boot": "Boot", "bottom": "Bottom", "deck": "Deck"})
	var y := fb + 0.02
	var glass_key := ShipLights.cabin_key(0)
	if yacht:
		# One short deckhouse amidships, a bridge forward of it, the funnel
		# behind it and two thin masts, every spar leaning aft.
		var wall := clampf(h * 0.2, 1.8, 2.6)
		var hx := -length * 0.08
		var roof := VesselKit.house(lm, hx, length * 0.30, beam * 0.62, y, wall, true, 1.4 if detail else 0.0,
			0.14, "White", glass_key, "DeckSteel")
		var bx := length * 0.12
		VesselKit.house(lm, bx, length * 0.09, beam * 0.5, roof, wall * 0.7, true, 0.0, 0.1, "White", glass_key, "DeckSteel")
		var fr := clampf(beam * 0.085, 0.4, 0.9)
		var base := Vector3(hx - length * 0.1, roof, 0)
		var rake := h * 0.14
		var top := base + Vector3(-rake, h - roof - 0.2, 0)
		var split := base.lerp(top, 0.82)
		HullLoft.tube(lm, "Funnel", [base, split], fr, 14 if detail else 8, true)
		HullLoft.tube(lm, "Black", [split, top], fr * 0.96, 14 if detail else 8, true)
		for mast: Array in [[length * 0.30, h * 0.98], [-length * 0.36, h * 0.8]]:
			var mb := Vector3(float(mast[0]), HullLoft.sheer(s, float(mast[0])), 0)
			HullLoft.tube(lm, "Black", [mb, mb + Vector3(-float(mast[1]) * 0.1, float(mast[1]) - mb.y, 0)],
				maxf(beam * 0.022, 0.07), 6, true)
		if detail:
			VesselForms.fittings(lm, s)
			VesselKit.guard(lm, s, -length * 0.46, length * 0.34, 0.9, 1.4, 0.04)
	else:
		# One long flat deckhouse the length of the hull, its roof grey, a
		# small wheelhouse on the roof forward, a stubby funnel aft of it.
		var wall := clampf(h * 0.26, 1.9, 2.4)
		var hl := length * 0.64
		var hx := -length * 0.04
		var roof := VesselKit.house(lm, hx, hl, beam * 0.8, y, wall, true, 1.5 if detail else 0.0,
			0.18, "White", glass_key, "DeckSteel")
		var wx := hx + hl * 0.34
		var wh := clampf(h * 0.2, 1.4, 2.0)
		VesselKit.house(lm, wx, length * 0.1, beam * 0.5, roof, wh, true, 0.0, 0.1, "White", glass_key, "DeckSteel")
		var fr := clampf(beam * 0.1, 0.4, 0.8)
		VesselKit.funnel(lm, Vector3(hx - hl * 0.12, roof, 0), maxf(h - roof, 1.2), fr, 1.4, "Funnel", "Black", detail)
		if detail:
			VesselForms.fittings(lm, s)
			VesselKit.guard(lm, s, length * 0.3, length * 0.46, 0.9, 1.4, 0.04)
			VesselKit.guard(lm, s, -length * 0.46, -length * 0.36, 0.9, 1.4, 0.04)

## The hull `spec` (HullLoft) of `model`: "steam_yacht" and "archipelago" are
## built here, the others carry the numbers of PassengerVesselModel's classic
## steamer ("passenger"), houseboat, restaurant_boat and tall_ship.
static func spec(model: String, length: float, beam: float, h: float, detail: bool) -> Dictionary:
	var lod := 0 if detail else 1
	match model:
		"steam_yacht":
			var fb := clampf(h * 0.14, 0.9, 2.2)
			return {"length": length, "beam": beam, "freeboard": fb, "draft": minf(beam * 0.3, 2.2),
				"entry": 0.34, "bow_pow": 1.6, "stern_w": 0.3, "flare": 0.09, "deadrise": 0.0,
				"stern_round": 1.0, "stern_tail": 0.18, "bow_rise": fb * 0.8, "stern_rise": fb * 0.25,
				"stem_rake": length * 0.07, "stern_rake": length * 0.03, "keel_lift": 0.9, "lod": lod}
		"archipelago":
			var fb := clampf(h * 0.2, 1.0, 2.0)
			return {"length": length, "beam": beam, "freeboard": fb, "draft": minf(beam * 0.28, 2.0),
				"entry": 0.22, "bow_pow": 2.0, "stern_w": 0.55, "flare": 0.05, "deadrise": 0.0,
				"stern_round": 0.7, "bow_rise": fb * 0.4, "stern_rise": fb * 0.1,
				"stem_rake": length * 0.025, "keel_lift": 0.7, "lod": lod}
		"houseboat":
			var fb := clampf(h * 0.2, 0.55, 1.1)
			return {"length": length, "beam": beam, "freeboard": fb, "draft": minf(beam * 0.14, 0.9),
				"entry": 0.15, "bow_pow": 2.6, "stern_w": 0.92, "flare": 0.04, "deadrise": 0.0,
				"bow_rise": fb * 0.2, "keel_lift": 0.35, "lod": lod}
		"restaurant_boat":
			var fb := clampf(h * 0.22, 0.85, 1.45)
			return {"length": length, "beam": beam, "freeboard": fb, "draft": minf(beam * 0.16, 1.1),
				"entry": 0.20, "bow_pow": 2.2, "stern_w": 0.78, "flare": 0.06, "deadrise": 0.0,
				"stern_round": 0.85, "bow_rise": fb * 0.32, "stern_rise": fb * 0.14,
				"stem_rake": length * 0.03, "keel_lift": 0.45, "lod": lod}
		"tall_ship":
			var fb := clampf(length * 0.045, 1.2, 4.0)
			return {"length": length, "beam": beam, "freeboard": fb, "draft": minf(beam * 0.4, 3.5),
				"entry": 0.3, "bow_pow": 1.7, "stern_w": 0.5, "flare": 0.1, "deadrise": 0.0,
				"stern_round": 1.0, "stern_tail": 0.14, "bow_rise": fb * 0.6, "stern_rise": fb * 0.4,
				"stem_rake": length * 0.05, "stern_rake": length * 0.025, "keel_lift": 0.9, "lod": lod}
	var fb := clampf(h * 0.2, 1.1, 4.2)
	return {"length": length, "beam": beam, "freeboard": fb, "draft": minf(beam * 0.3, 2.6),
		"entry": 0.27, "bow_pow": 1.8, "stern_w": 0.4, "flare": 0.07, "deadrise": 0.0,
		"stern_round": 1.0, "stern_tail": 0.14, "bow_rise": fb * 0.55, "stern_rise": fb * 0.15,
		"stem_rake": length * 0.03, "stern_rake": length * 0.025, "keel_lift": 0.9, "lod": lod}
