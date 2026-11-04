class_name CruiseLinerModel
extends RefCounted

## Cruise liner (140-330 m): a long lofted hull with a flared raked bow and
## a flat transom, a forecastle and mooring deck, a boat deck of lifeboats,
## then a stack of white decks stepping back at the bow and terracing aft.
## Each deck has a dark window band, balcony dividers (`detail`), a bridge
## with wings, a raked funnel in livery colours, a radar mast and a pool
## deck. `h` is the top of the highest mast. +X bow, centred on x = 0.

const FUNNELS := ["#c93a2b", "#1f5d99", "#e8e4d6", "#e9b32e", "#2c3a4f"]
const HULLS := ["#1c2a43", "#e9e8e2", "#1b1c1f", "#2a4c6e"]

static func hull_hex(seed_value: float) -> String:
	return HULLS[int(absf(seed_value)) % HULLS.size()]

static func build(lm: LandmarkMesh, p: Dictionary) -> void:
	var length: float = p["length"]
	var beam: float = p["beam"]
	var h: float = p["height"]
	var detail: bool = p.get("detail", true)
	var maps: bool = p.get("maps", true)
	var seed_value: float = p.get("seed", 0.0)
	var hull_h := length * 0.042
	var spec := {"length": length, "beam": beam, "freeboard": hull_h, "draft": length * 0.027,
		"entry": 0.17, "bow_pow": 1.9, "stern_w": 0.8, "flare": 0.1, "deadrise": 0.0,
		"bow_rise": hull_h * 0.3, "stem_rake": length * 0.022, "stern_rake": length * 0.004,
		"keel_lift": 0.8, "deck_inset": 0.2, "lod": 0 if detail else 1}
	spec["ultra"] = bool(p.get("ultra", false))
	VesselMaterials.register(lm, maps, p["hull"], VesselMaterials.get_mat("antifoul", maps))
	lm.use("Boot", VesselMaterials.get_mat("red", maps))
	lm.use("Orange", VesselMaterials.get_mat("orange", maps))
	lm.use("DeckSteel", VesselMaterials.get_mat("grey_deck", maps))
	lm.use("Pool", VesselMaterials.get_mat("pool", maps))
	lm.use("Black", VesselMaterials.get_mat("black", maps))
	lm.use("Funnel", VesselMaterials.paint(str(p.get("funnel", FUNNELS[int(absf(seed_value) * 3.0) % FUNNELS.size()])), maps, 0.5, 0.05))
	HullLoft.loft(lm, spec, {"hull": "Hull", "boot": "Boot", "bottom": "Bottom", "deck": "DeckSteel"})
	# Decks above the main deck, sized so the mast tops out at `h`.
	var dh := 2.9
	var super_top := h * 0.84
	var n := clampi(int(round((super_top - hull_h) / dh)), 3, 13)
	dh = (super_top - hull_h) / float(n)
	var y0 := hull_h + 0.02
	var front0 := length * 0.27
	var aft0 := -length * 0.44
	var ferry: bool = p.get("ferry", false)
	var deck_tops: Array[float] = []
	var fronts: Array[float] = []
	var afts: Array[float] = []
	var widths: Array[float] = []
	for i in n:
		var front := front0 - float(i) * length * 0.006
		var aft := aft0
		if not ferry and i >= int(n * 0.55):
			aft = aft0 + float(i - int(n * 0.55) + 1) * length * 0.04
		var w := beam * (0.975 if i == 0 else (0.86 if i == 1 else 0.95))
		if i >= n - 2:
			w = beam * 0.62
		fronts.append(front)
		afts.append(aft)
		widths.append(w)
		deck_tops.append(y0 + dh * float(i + 1))
	for i in n:
		var yb := y0 + dh * float(i)
		var l: float = fronts[i] - afts[i]
		var cx: float = (fronts[i] + afts[i]) * 0.5
		var w: float = widths[i]
		if detail:
			var cabin_width := w - (1.8 if bool(p.get("ultra", false)) and i >= 2 and i < n - 2 else 0.0)
			VesselForms.cabin(lm, cx, l, cabin_width, yb, dh, 3.0 if bool(p.get("ultra", false)) else 4.5, "White", 0.1)
			VesselForms.slab(lm, "White", Vector3(cx, yb + dh - 0.04, 0),
				Vector3(l + 0.3, 0.08, w + 0.3), minf(w * 0.08, 2.0))
		else:
			# Wall block; windows ride a band across its height.
			lm.box("White", Vector3(cx, yb + dh * 0.5, 0), Vector3(l, dh, w), Basis(), 0.0)
			if i >= 1:
				VesselKit.windows(lm, afts[i] + 1.5, fronts[i] - 1.0, w * 0.5, yb + dh * 0.28, yb + dh * 0.78, 0.0)
			lm.box("White", Vector3(cx, yb + dh - 0.04, 0), Vector3(l + 0.3, 0.08, w + 0.3), Basis(), 0.0)
		if detail and not ferry and i >= 2 and i < n - 2:
			for side in [-1.0, 1.0]:
				var z: float = float(side) * (w * 0.5 + 0.1)
				HullLoft.tube(lm, "Steel", [Vector3(afts[i] + 1.5, yb + dh * 0.4, z),
					Vector3(fronts[i] - 1.0, yb + dh * 0.4, z)], 0.035, 8)
			if bool(p.get("ultra", false)):
				for side in [-1.0, 1.0]:
					lm.box("White", Vector3(cx, yb + 0.05, float(side) * (w * 0.5 - 0.6)), Vector3(l - 3.0, 0.1, 1.2), Basis(), 0.0)
					lm.box("Glass", Vector3(cx, yb + 0.55, float(side) * (w * 0.5)), Vector3(l - 3.0, 0.85, 0.025), Basis(), 0.0)
					for seat in 6:
						var x := lerpf(afts[i] + 6.0, fronts[i] - 6.0, float(seat) / 5.0)
						VesselEquipment.chair(lm, Vector3(x, yb + 0.1, float(side) * (w * 0.5 - 0.35)))
			var count := int(l / (3.0 if bool(p.get("ultra", false)) else 4.5))
			for k in count + 1:
				var x := lerpf(afts[i] + 1.5, fronts[i] - 1.0, float(k) / float(maxi(count, 1)))
				for s in [-1.0, 1.0]:
					lm.box("White", Vector3(x, yb + dh * 0.5, float(s) * (w * 0.5 - (0.45 if bool(p.get("ultra", false)) else -0.12))),
						Vector3(0.07, dh * 0.84, 1.2 if bool(p.get("ultra", false)) else 0.28), Basis(), 0.0)
	# Forecastle gear and bow bulwark.
	if detail:
		VesselForms.fittings(lm, spec)
		if bool(p.get("ultra", false)):
			VesselEquipment.deck(lm, spec)
			VesselEquipment.ladder(lm, Vector3(aft0 - 0.2, hull_h, beam * 0.25), minf(dh * 2.0, 6.0), 0.65)
		HullLoft.rail(lm, "White", spec, length * 0.28, length * 0.49, 1.1, 2.5, 0.0, 0.25, 0.05)
		HullLoft.rail(lm, "White", spec, -length * 0.49, aft0 + 2.0, 1.1, 2.5, 0.0, 0.25, 0.05)
		lm.box("DeckSteel", Vector3(length * 0.4, hull_h + 0.5, 0), Vector3(3.0, 1.0, beam * 0.22), Basis(), 0.02)
		# Lifeboats along the boat deck ledge on both sides.
		var boat_len := clampf(length * 0.032, 6.0, 9.5)
		var count := clampi(int(length * 0.055), 4, 14)
		var ledge_z: float = widths[1] * 0.5 + boat_len * 0.16 + 0.1
		for s in [-1.0, 1.0]:
			for k in count:
				var x := lerpf(afts[1] + 12.0, fronts[1] - 12.0, float(k) / float(maxi(count - 1, 1)))
				VesselKit.lifeboat(lm, Vector3(x, deck_tops[0] + 0.05, float(s) * ledge_z), boat_len)
				for offset in [-0.3, 0.3]:
					VesselForms.davit(lm, Vector3(x + boat_len * float(offset), deck_tops[0], float(s) * (widths[1] * 0.5 - 0.15)),
						boat_len * 0.3, float(s) * (boat_len * 0.16 + 0.25))
	# Bridge wings across the front of the third deck from the top.
	var bi := maxi(n - 3, 1)
	var bridge_y: float = deck_tops[bi] - dh
	lm.box("White", Vector3(fronts[bi] - 3.0, bridge_y + dh * 0.5, 0), Vector3(6.0, dh, beam * 1.02), Basis(), 0.0)
	VesselKit.windows(lm, fronts[bi] - 5.5, fronts[bi] - 0.6, beam * 0.51, bridge_y + dh * 0.3, bridge_y + dh * 0.8, 0.0)
	lm.quad("Glass", Vector3(fronts[bi] + 0.02, bridge_y + dh * 0.28, -widths[bi] * 0.5),
		Vector3(fronts[bi] + 0.02, bridge_y + dh * 0.28, widths[bi] * 0.5),
		Vector3(fronts[bi] + 0.02, bridge_y + dh * 0.82, widths[bi] * 0.5),
		Vector3(fronts[bi] + 0.02, bridge_y + dh * 0.82, -widths[bi] * 0.5), Vector3.RIGHT)
	# Aft terraces carry the pool deck.
	var pool_i := int(n * 0.55)
	if not ferry and pool_i < n:
		var pool_y: float = deck_tops[pool_i - 1] + 0.05
		var pool_length := maxf(0.5, minf(length * 0.07, afts[pool_i] - afts[pool_i - 1] - 1.0))
		lm.box("Pool", Vector3((afts[pool_i] + afts[pool_i - 1]) * 0.5, pool_y + 0.03, 0), Vector3(pool_length, 0.06, beam * 0.3), Basis(), 0.0)
	# Funnel in livery colours abaft the bridge, raked radar mast ahead.
	var top_y: float = deck_tops[n - 1]
	var fr := beam * 0.1
	var f_top := minf(top_y + dh * 1.6, h * 0.97)
	VesselKit.funnel(lm, Vector3(length * 0.02, top_y - 0.1, 0), maxf(f_top - top_y + 0.1, 2.0), fr, 2.3, "Funnel", "Black", detail)
	var mast_x: float = fronts[n - 1] - 4.0
	VesselKit.mast(lm, "White", Vector3(mast_x, top_y, 0), h - top_y, maxf(beam * 0.012, 0.18), detail)
	lm.box("Steel", Vector3(mast_x, top_y + (h - top_y) * 0.6, 0), Vector3(1.2, 0.2, 6.0), Basis(), 0.0)
	if detail:
		var inset := beam * 0.5 - widths[n - 1] * 0.5 + 0.2
		HullLoft.rail(lm, "Steel", spec, afts[n - 1], fronts[n - 1], 1.1, 3.0, top_y - hull_h, inset, 0.04)
	if bool(p.get("ultra", false)):
		for side in [-1.0, 1.0]:
			VesselEquipment.vent(lm, Vector3(-length * 0.015, top_y, float(side) * beam * 0.2), 0.5)
			for i in 8:
				var x := lerpf(afts[n - 1] + 2.0, fronts[n - 1] - 6.0, float(i) / 7.0)
				VesselForms.slab(lm, "White", Vector3(x, top_y + 0.22, float(side) * beam * 0.2), Vector3(1.7, 0.14, 0.6), 0.15)
