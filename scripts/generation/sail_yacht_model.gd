class_name SailYachtModel
extends RefCounted

## Bermuda-sloop sailing yacht on a lofted hull with a fin keel and spade
## rudder: coachroof with port windows, sprayhood, cockpit coamings, a
## tapered mast with spreaders, boom with a stowed mainsail, a roller-furled
## genoa and standing rigging. +X bow, centred on x = 0, waterline y = 0.
## `rig()` is shared with PassengerVesselModel's tall ships (masts + yards).

static func build(lm: LandmarkMesh, p: Dictionary) -> void:
	var length: float = p["length"]
	var detail: bool = p.get("detail", true)
	var maps: bool = p.get("maps", true)
	var spec := {"length": length, "beam": length * 0.31, "freeboard": length * 0.055,
		"draft": length * 0.06, "entry": 0.4, "bow_pow": 1.6, "stern_w": 0.78, "flare": 0.14,
		"deadrise": 0.2, "bow_rise": length * 0.02, "stern_rise": length * 0.004, "stem_rake": length * 0.025,
		"stern_rake": length * 0.03, "keel_lift": 0.8, "lod": 0 if detail else 1}
	VesselMaterials.register(lm, maps, p["hull"], VesselMaterials.get_mat("antifoul", maps))
	lm.use("Sail", VesselMaterials.get_mat("canvas", maps))
	HullLoft.loft(lm, spec, {"hull": "Hull", "boot": "Dark", "bottom": "Bottom", "deck": "Deck"})
	var fb: float = spec["freeboard"]
	var beam: float = spec["beam"]
	var deck_y := fb + 0.02
	# Fin keel with a bulb, and a spade rudder.
	var d := length * 0.17
	HullLoft.fin(lm, "Bottom", PackedVector2Array([Vector2(length * 0.06, -length * 0.04),
		Vector2(-length * 0.06, -length * 0.04), Vector2(-length * 0.03, -d), Vector2(length * 0.02, -d)]), length * 0.012)
	lm.box("Bottom", Vector3(-length * 0.005, -d - length * 0.01, 0), Vector3(length * 0.14, length * 0.035, length * 0.035), Basis(), 0.0)
	HullLoft.fin(lm, "Bottom", PackedVector2Array([Vector2(-length * 0.42, -length * 0.02),
		Vector2(-length * 0.45, -length * 0.02), Vector2(-length * 0.455, -length * 0.1), Vector2(-length * 0.43, -length * 0.1)]), length * 0.006)
	# Coachroof with a window strip each side and a sloped front.
	var roof_h := length * 0.06
	var cx0 := -length * 0.2
	var cx1 := length * 0.17
	var cw := beam * 0.58
	lm.box("White", Vector3((cx0 + cx1) * 0.5, deck_y + roof_h * 0.5, 0), Vector3(cx1 - cx0, roof_h, cw), Basis(), 0.03)
	lm.quad("White", Vector3(cx1, deck_y, -cw * 0.5), Vector3(cx1, deck_y, cw * 0.5),
		Vector3(cx1, deck_y + roof_h, cw * 0.5), Vector3(cx1, deck_y + roof_h, -cw * 0.5), Vector3.RIGHT)
	for s in [-1.0, 1.0]:
		lm.box("Glass", Vector3((cx0 + cx1) * 0.5 + length * 0.02, deck_y + roof_h * 0.55, float(s) * (cw * 0.5 + 0.006)),
			Vector3(cx1 - cx0 - length * 0.1, roof_h * 0.34, 0.015), Basis(), 0.0)
	# Sprayhood and cockpit coamings.
	lm.box("Dark", Vector3(cx0 - length * 0.015, deck_y + roof_h + length * 0.012, 0), Vector3(length * 0.05, length * 0.035, cw * 0.8), Basis(), 0.02)
	for s in [-1.0, 1.0]:
		lm.box("White", Vector3(-length * 0.31, deck_y + length * 0.015, float(s) * beam * 0.32),
			Vector3(length * 0.2, length * 0.03, 0.05), Basis(), 0.0)
	lm.box("Deck", Vector3(-length * 0.31, deck_y + 0.04, 0), Vector3(length * 0.2, 0.05, beam * 0.55), Basis(), 0.0)
	var mast_x := length * 0.09
	var mast_h := length * 1.3
	rig(lm, p, spec, mast_x, mast_h, deck_y + roof_h)
	if detail:
		VesselKit.guard(lm, spec, length * 0.17, length * 0.43, length * 0.04, 0.4, 0.02)
		VesselKit.guard(lm, spec, -length * 0.43, length * 0.15, length * 0.04, 0.5, 0.02)

## Mast, boom with stowed main, furled genoa, spreaders and stays.
static func rig(lm: LandmarkMesh, p: Dictionary, spec: Dictionary, mast_x: float, mast_h: float, base_y: float) -> void:
	var length: float = p["length"]
	var detail: bool = p.get("detail", true)
	var mr := maxf(length * 0.008, 0.03)
	VesselKit.mast(lm, "Steel", Vector3(mast_x, base_y - length * 0.05, 0), mast_h + length * 0.05, mr)
	var top := Vector3(mast_x, base_y - length * 0.05 + mast_h + length * 0.05, 0)
	# Boom and the mainsail flaked on it under a cover.
	var bh := base_y + length * 0.08
	var bw := maxf(length * 0.008, 0.04)
	lm.beam("Steel", Vector3(mast_x - mr, bh, 0), Vector3(-length * 0.4, bh + length * 0.01, 0), bw * 2.0)
	lm.box("Sail", Vector3(mast_x - length * 0.25, bh + length * 0.02, 0), Vector3(length * 0.5, length * 0.03, length * 0.022), Basis(), 0.01)
	# Roller-furled genoa on the forestay.
	var bow := Vector3(length * 0.46, HullLoft.sheer(spec, length * 0.46), 0)
	var head := top - Vector3(0, mast_h * 0.06, 0)
	lm.beam("Sail", bow + Vector3(0, length * 0.02, 0), bow.lerp(head, 0.85), maxf(length * 0.011, 0.04), -1.0, Vector3.FORWARD)
	lm.beam("Steel", bow.lerp(head, 0.85), head, maxf(length * 0.004, 0.02))
	if not detail:
		return
	# Backstay and the shrouds over two spreader pairs.
	lm.beam("Steel", head, Vector3(-length * 0.48, HullLoft.sheer(spec, -length * 0.48), 0), maxf(length * 0.003, 0.018))
	for frac in [0.38, 0.7]:
		var sy: float = base_y + (top.y - base_y) * float(frac)
		var half_span := length * 0.07 * (1.0 - float(frac) * 0.4)
		for s in [-1.0, 1.0]:
			var tip := Vector3(mast_x, sy, float(s) * half_span)
			lm.beam("Steel", Vector3(mast_x, sy, 0), tip, maxf(length * 0.004, 0.025))
			var chain := Vector3(mast_x, HullLoft.sheer(spec, mast_x), float(s) * (HullLoft.half(spec, mast_x) - 0.05))
			lm.beam("Steel", tip, chain, maxf(length * 0.0025, 0.015))
			lm.beam("Steel", tip, Vector3(mast_x, sy + (top.y - sy) * 0.55, 0), maxf(length * 0.0025, 0.015))
	lm.beam("Steel", top, top + Vector3(0, length * 0.04, 0), maxf(length * 0.003, 0.02))
