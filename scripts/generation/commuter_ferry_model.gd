class_name CommuterFerryModel
extends RefCounted

## Harbour commuter ferries and water buses (20-40 m), as on Helsinki's
## Suomenlinna and island routes. Metres, +X bow, waterline y = 0.
## - "suomenlinna": the HSL line 19 ferry (M/S Suomenlinna II class): a
##   steel monohull in white with the blue band at the sheer, an open
##   foredeck for the island's service vehicles behind a bow bulwark, a
##   glazed main saloon, an upper saloon with an open sun deck aft, the
##   wheelhouse forward on top and a short funnel; the route name
##   "SUOMENLINNA – SVEABORG" on both sides.
## - "water_bus": a JT-Line style water bus: lower, one saloon with a
##   long window band, an open upper deck with benches and rails, a small
##   wheelhouse, the line's name on the hull.
## `row` is a HarbourVesselData.FERRY_ROUTES row (length_m, beam_m, hull,
## band, lettering).

static func spec(row: Dictionary) -> Dictionary:
	var length := float(row.get("length_m", 30.0))
	var beam := float(row.get("beam_m", 8.0))
	var big := str(row.get("model", "")) == "suomenlinna"
	return {"length": length, "beam": beam, "freeboard": 2.4 if big else 1.6, "draft": 2.4 if big else 1.4,
		"entry": 0.3, "bow_pow": 1.8, "stern_w": 0.86, "flare": 0.08, "deadrise": 0.1,
		"bow_rise": 0.5 if big else 0.35, "stem_rake": length * 0.04, "stern_rake": 0.3,
		"stern_round": 0.6, "keel_lift": 0.85, "boot_m": 0.35, "lod": 0, "ultra": true}

static func build(row: Dictionary, maps: bool = true) -> LandmarkMesh:
	var lm := LandmarkMesh.new()
	var s := spec(row)
	var length: float = s["length"]
	var beam: float = s["beam"]
	var fb: float = s["freeboard"]
	var big := str(row.get("model", "")) == "suomenlinna"
	var hull := Color(str(row.get("hull", "#f2f1ec")))
	var band := Color(str(row.get("band", "#0072c6")))
	VesselMaterials.register(lm, maps, VesselMaterials.get_mat("white", maps))
	ShipPaint.dress(lm, VesselMaterials.paint(hull.to_html(false), maps), length, fb, maps, band.darkened(0.25))
	ShipLights.register(lm, maps)
	lm.use("Band", ShipPaint.enamel(band, maps))
	lm.use("DeckSteel", VesselMaterials.get_mat("grey_deck", maps))
	lm.use("Black", VesselMaterials.get_mat("black", maps))
	HullLoft.loft(lm, s, {"hull": "Hull", "boot": "Boot", "bottom": "Bottom", "deck": "DeckSteel"})
	# The band along the sheer, and the route name below it amidships.
	_band(lm, s, fb - 0.55, 0.5)
	var letters := str(row.get("lettering", ""))
	if letters != "":
		var h := clampf(fb * 0.32, 0.45, 0.8)
		var w := HullLettering.width(letters, h)
		var room := length * 0.62
		if w > room:
			h *= room / w
		HullLettering.on_hull(lm, "Band", s, letters, -length * 0.06, fb * 0.42, h)
	var deck_h := 2.4
	var y0 := fb + 0.02
	if big:
		# Open foredeck behind a bow bulwark; the saloon from amidships aft.
		var front := length * 0.16
		var aft := -length * 0.44
		var w0 := beam - 1.2
		VesselForms.cabin(lm, (front + aft) * 0.5, front - aft, w0, y0, deck_h, 1.3, "White", 0.1, "Cabin0", "DeckSteel")
		HullLoft.rail(lm, "White", s, length * 0.2, length * 0.48, 1.1, 1.2, 0.0, 0.12, 0.06)
		var y1 := y0 + deck_h + 0.05
		VesselForms.slab(lm, "DeckSteel", Vector3((front + aft) * 0.5, y1, 0), Vector3(front - aft + 0.6, 0.14, w0 + 0.5), 1.0)
		# Upper saloon forward, an open sun deck aft of it.
		var f2 := front - 1.0
		var a2 := -length * 0.18
		VesselForms.cabin(lm, (f2 + a2) * 0.5, f2 - a2, w0 - 0.8, y1 + 0.07, deck_h - 0.1, 1.3, "White", 0.12, "Cabin1", "DeckSteel")
		_rails(lm, a2, aft + 0.4, (w0 + 0.4) * 0.5, y1 + 0.07)
		for k in 3:
			var bx := a2 - 2.5 - float(k) * 3.0
			if bx > aft + 1.0:
				for side in [-1.0, 1.0]:
					lm.box("Steel", Vector3(bx, y1 + 0.5, float(side) * w0 * 0.25), Vector3(0.5, 0.45, w0 * 0.35), Basis(), 0.0)
		# Wheelhouse on top, forward, with the funnel behind it.
		var y2 := y1 + 0.07 + deck_h - 0.1 + 0.05
		VesselForms.cabin(lm, f2 - 2.6, 4.2, w0 * 0.62, y2, 2.0, 0.0, "White", 0.3, "Glass", "DeckSteel")
		VesselKit.funnel(lm, Vector3(f2 - 7.2, y2 - 0.05, 0), 2.1, 0.75, 1.6, "Band", "Black", true)
		VesselKit.mast(lm, "White", Vector3(f2 - 3.2, y2 + 2.0, 0), 3.2, 0.09, true)
		lm.box("Steel", Vector3(f2 - 3.2, y2 + 4.0, 0), Vector3(0.3, 0.1, 2.2), Basis(), 0.0)
		ShipLights.nav(lm, f2 - 2.6, y2 + 1.4, w0 * 0.31 + 0.15, Vector3(f2 - 3.2, y2 + 5.1, 0),
			Vector3(-length * 0.5 + 0.4, fb + 1.0, 0), Vector3(f2 - 7.2, y2 + 2.3, 0))
		for side in [-1.0, 1.0]:
			VesselEquipment.life_ring(lm, Vector3(-length * 0.2, y1 - 1.0, float(side) * (w0 * 0.5 + 0.05)),
				Vector3(0, 0, float(side)), 0.35)
	else:
		# One long saloon, an open upper deck on its roof, a small wheelhouse.
		var front := length * 0.3
		var aft := -length * 0.4
		var w0 := beam - 0.9
		VesselForms.cabin(lm, (front + aft) * 0.5, front - aft, w0, y0, deck_h - 0.2, 1.1, "White", 0.18, "Cabin2", "DeckSteel")
		var y1 := y0 + deck_h - 0.2 + 0.05
		VesselForms.slab(lm, "DeckSteel", Vector3((front + aft) * 0.5, y1, 0), Vector3(front - aft + 0.4, 0.12, w0 + 0.3), 0.8)
		_rails(lm, front - 3.2, aft + 0.3, (w0 + 0.1) * 0.5, y1 + 0.06)
		for k in 4:
			var bx := front - 5.0 - float(k) * 2.2
			if bx > aft + 1.0:
				lm.box("Steel", Vector3(bx, y1 + 0.45, 0), Vector3(0.45, 0.4, w0 * 0.7), Basis(), 0.0)
		VesselForms.cabin(lm, front - 1.6, 3.0, w0 * 0.55, y1 + 0.06, 1.9, 0.0, "White", 0.3, "Glass", "DeckSteel")
		VesselKit.mast(lm, "White", Vector3(front - 1.8, y1 + 1.96, 0), 1.8, 0.07, true)
		HullLoft.rail(lm, "Steel", s, front + 0.6, length * 0.48, 0.9, 1.5, 0.0, 0.1, 0.035)
		ShipLights.nav(lm, front - 1.6, y1 + 1.3, w0 * 0.28 + 0.12, Vector3(front - 1.8, y1 + 3.7, 0),
			Vector3(-length * 0.5 + 0.3, fb + 0.6, 0), Vector3(aft + 1.0, y1 + 1.0, 0))
	VesselForms.fittings(lm, s)
	return lm

## A painted band `w` m tall at `y` along the whole hull, both sides.
static func _band(lm: LandmarkMesh, s: Dictionary, y: float, w: float) -> void:
	var length: float = s["length"]
	for side in [-1.0, 1.0]:
		var lo := PackedVector3Array()
		var hi := PackedVector3Array()
		for i in 33:
			var x := lerpf(-length * 0.47, length * 0.45, float(i) / 32.0)
			var ya := y - w * 0.5
			var yb := y + w * 0.5
			lo.append(Vector3(x, ya, (HullLoft.side_z(s, x, ya) + 0.04) * float(side)))
			hi.append(Vector3(x, yb, (HullLoft.side_z(s, x, yb) + 0.04) * float(side)))
		lm.grid("Band", [lo, hi], Vector3(0, 0, side))

## Open-deck railing (posts and a top rail) along both sides from x0 aft to x1.
static func _rails(lm: LandmarkMesh, x0: float, x1: float, z: float, y: float) -> void:
	for side in [-1.0, 1.0]:
		var zz := float(side) * z
		HullLoft.tube(lm, "White", [Vector3(x0, y + 1.0, zz), Vector3(x1, y + 1.0, zz)], 0.04, 6)
		HullLoft.tube(lm, "White", [Vector3(x0, y + 0.5, zz), Vector3(x1, y + 0.5, zz)], 0.025, 6)
		var n := maxi(int(absf(x0 - x1) / 1.4), 1)
		for i in n + 1:
			var x := lerpf(x0, x1, float(i) / float(n))
			HullLoft.tube(lm, "White", [Vector3(x, y, zz), Vector3(x, y + 1.0, zz)], 0.03, 6)
	HullLoft.tube(lm, "White", [Vector3(x1, y + 1.0, -z), Vector3(x1, y + 1.0, z)], 0.04, 6)
