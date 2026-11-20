class_name MarketBoatModel
extends RefCounted

## A Kauppatori market boat (7-12 m): a varnished wooden fishing cutter
## moored at the quay, a small wheelhouse forward, the open deck aft stacked
## with fish crates and shaded by a canvas awning on poles, as the stalls on
## the Helsinki market quay sell fish and produce straight off the water.
## Metres, +X bow, waterline y = 0, centred on x = 0.
## `p`: length, hull (hex), awning (hex), detail, maps.

const HULLS := ["#7a4a26", "#2f4a3a", "#1c2b46", "#8a2a22", "#d8d2bd", "#6a3d1f"]
const AWNINGS := ["#e8e3d3", "#c8472f", "#2a5aa8", "#e0b43a", "#3d7a4e"]

static func build(lm: LandmarkMesh, p: Dictionary) -> void:
	var length: float = p["length"]
	var beam := length * 0.3
	var detail: bool = p.get("detail", true)
	var maps: bool = p.get("maps", true)
	var fb := maxf(length * 0.13, 1.0)
	var s := {"length": length, "beam": beam, "freeboard": fb, "draft": length * 0.07, "entry": 0.32,
		"bow_pow": 1.8, "stern_w": 0.62, "flare": 0.1, "deadrise": 0.25, "bow_rise": length * 0.03,
		"stem_rake": length * 0.03, "stern_rake": 0.1, "keel_lift": 0.8, "boot_m": 0.12,
		"lod": 0 if detail else 1, "ultra": false}
	VesselMaterials.register(lm, maps, VesselMaterials.paint(str(p.get("hull", HULLS[0])), maps, 0.45, 0.02),
		VesselMaterials.get_mat("antifoul", maps))
	lm.use("Awning", ShipPaint.enamel(Color(str(p.get("awning", AWNINGS[0]))), maps))
	ShipLights.register(lm, maps)
	HullLoft.loft(lm, s, {"hull": "Hull", "boot": "Boot", "bottom": "Bottom", "deck": "Deck"})
	var y0 := fb + 0.02
	# Wheelhouse forward, open working deck aft.
	var house_x := length * 0.2
	VesselForms.cabin(lm, house_x, length * 0.22, beam * 0.62, y0, 1.7, 0.0, "White", 0.3, "Glass", "Roof")
	var awning_y := y0 + 2.1
	var a0 := -length * 0.4
	var a1 := length * 0.04
	if detail:
		for x in [a0, a1]:
			for z in [-1.0, 1.0]:
				HullLoft.tube(lm, "Steel", [Vector3(float(x), y0, float(z) * beam * 0.34),
					Vector3(float(x), awning_y, float(z) * beam * 0.34)], 0.03, 5)
		# Crates and a scale table in the shade.
		for i in 4:
			lm.box("Deck", Vector3(a0 + 0.6 + float(i) * 0.7, y0 + 0.2, (-0.2 if i % 2 == 0 else 0.25) * beam),
				Vector3(0.55, 0.35, 0.4), Basis(), 0.0)
	# The awning: a canvas roof sloping down to the sides, the deeper side lower.
	lm.box("Awning", Vector3((a0 + a1) * 0.5, awning_y + 0.1, 0), Vector3(a1 - a0 + 0.4, 0.06, beam * 0.86),
		Basis(), 0.0)
	lm.box("Awning", Vector3((a0 + a1) * 0.5, awning_y - 0.12, beam * 0.45), Vector3(a1 - a0 + 0.4, 0.3, 0.05), Basis(), 0.0)
	lm.box("Awning", Vector3((a0 + a1) * 0.5, awning_y - 0.12, -beam * 0.45), Vector3(a1 - a0 + 0.4, 0.3, 0.05), Basis(), 0.0)
