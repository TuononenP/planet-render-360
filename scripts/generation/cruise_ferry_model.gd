class_name CruiseFerryModel
extends RefCounted

## Ro-pax cruise ferry (100-230 m), as on the Baltic routes: a tall
## windowless car-deck hull (ventilation louvres, shell doors), a bow
## visor seam, a stern ramp on the transom, a bulbous bow, one row of
## crew windows high in the hull and a livery sweep rising toward the
## bow. On top, LinerSuperstructure without balconies or pool: window
## decks, lifeboat recess, bridge wings, sun decks stepping down aft and
## the funnel well aft in the livery colour. Generic seeded liveries, no
## company marks. `h` is the top of the mast. +X bow, centred on x = 0.

const LIVERIES := ["#1f5d99", "#c93a2b", "#2a7a4b", "#1c2a43", "#d8a21e"]

static func livery_hex(seed_value: float) -> String:
	return LIVERIES[int(absf(seed_value) * 5.0) % LIVERIES.size()]

## The HullLoft spec of a ferry `length` x `beam`.
static func spec(length: float, beam: float, detail: bool, ultra: bool) -> Dictionary:
	var fb := clampf(length * 0.07, 7.0, 16.0)
	return {"length": length, "beam": beam, "freeboard": fb, "draft": clampf(length * 0.032, 3.5, 7.0),
		"entry": 0.2, "bow_pow": 2.2, "stern_w": 0.95, "flare": 0.06, "deadrise": 0.0,
		"bow_rise": length * 0.012, "stem_rake": length * 0.025, "stern_rake": length * 0.002,
		"keel_lift": 0.8, "deck_inset": 0.2, "boot_m": clampf(length * 0.005, 0.5, 1.1),
		"anchors": false, "lod": 0 if detail else 1, "ultra": ultra}

static func build(lm: LandmarkMesh, p: Dictionary) -> void:
	var length: float = p["length"]
	var beam: float = p["beam"]
	var h: float = p["height"]
	var detail: bool = p.get("detail", true)
	var maps: bool = p.get("maps", true)
	var ultra := detail and bool(p.get("ultra", false))
	var livery := Color(str(p.get("livery", livery_hex(float(p.get("seed", 0.0))))))
	var s := spec(length, beam, detail, ultra)
	var fb: float = s["freeboard"]
	VesselMaterials.register(lm, maps, p["hull"], VesselMaterials.get_mat("antifoul", maps))
	ShipPaint.dress(lm, p["hull"], length, fb * 1.1, maps, livery.darkened(0.2))
	ShipLights.register(lm, maps)
	lm.use("Orange", ShipPaint.enamel(Color("#e0651c"), maps))
	lm.use("Livery", ShipPaint.enamel(livery, maps))
	lm.use("Funnel", ShipPaint.enamel(livery, maps))
	lm.use("DeckSteel", VesselMaterials.get_mat("grey_deck", maps))
	lm.use("Black", VesselMaterials.get_mat("black", maps))
	HullLoft.loft(lm, s, {"hull": "Hull", "boot": "Boot", "bottom": "Bottom", "deck": "DeckSteel"})
	LinerSuperstructure.build(lm, p, s, {"y0": fb + 0.02, "top": maxf(h * 0.84, fb + 9.0),
		"front": length * 0.3, "aft": -length * 0.38, "terraces": true, "boats": true,
		"balconies": false, "pool": false, "slide": false, "funnel_x": -length * 0.27})
	ShipHullKit.livery(lm, s, "Livery", -length * 0.48, length * 0.44, fb * 0.3, fb * 0.78, clampf(fb * 0.2, 1.2, 3.0))
	if not detail:
		return
	ShipHullKit.bulb(lm, s, "Bottom", length * 0.02)
	# Car decks: louvres and shell doors; crew windows high in the hull.
	ShipHullKit.windows(lm, s, "Black", -length * 0.4, length * 0.28, fb * 0.5, 2.2, 0.9, 9.0)
	ShipHullKit.windows(lm, s, "Cabin3", -length * 0.34, length * 0.3, fb * 0.9, 0.9, 0.6, 3.0)
	for x in [length * 0.22, -length * 0.06, -length * 0.3]:
		ShipHullKit.shell_door(lm, s, float(x), fb * 0.3 + 1.5, 3.5, 3.0)
	ShipHullKit.anchor_pocket(lm, s, length * 0.41, clampf(length * 0.011, 1.2, 2.8))
	ShipHullKit.chocks(lm, s, [length * 0.45, length * 0.36, -length * 0.36, -length * 0.47], 0.8)
	_visor(lm, s)
	_ramp(lm, s)
	VesselForms.fittings(lm, s)
	for side in [-1.0, 1.0]:
		VesselEquipment.winch(lm, Vector3(length * 0.4, HullLoft.sheer(s, length * 0.4), float(side) * beam * 0.18), 0.8)
		for x in [-length * 0.42, -length * 0.46]:
			VesselEquipment.winch(lm, Vector3(float(x), HullLoft.sheer(s, float(x)), float(side) * beam * 0.3), 0.8)
	HullLoft.rail(lm, "White", s, length * 0.31, length * 0.49, 1.1, 2.5, 0.0, 0.25, 0.05)
	HullLoft.rail(lm, "White", s, -length * 0.49, -length * 0.38, 1.1, 2.5, 0.0, 0.25, 0.05)

## The bow visor's seam: down the bow behind the stem, then forward to
## the stem just above the waterline, on both sides.
static func _visor(lm: LandmarkMesh, s: Dictionary) -> void:
	var length: float = s["length"]
	var xv := length * 0.41
	var low := 2.2
	var tip := HullLoft.x0(s) + HullLoft.body_length(s)
	for side in [-1.0, 1.0]:
		var path: Array = []
		var top := HullLoft.sheer(s, xv) - 0.2
		for i in 6:
			var y := lerpf(top, low, float(i) / 5.0)
			path.append(Vector3(xv, y, (HullLoft.side_z(s, xv, y) + 0.04) * float(side)))
		for i in range(1, 6):
			var x := lerpf(xv, tip - 0.6, float(i) / 5.0)
			path.append(Vector3(x, low, (HullLoft.side_z(s, x, low) + 0.04) * float(side)))
		HullLoft.tube(lm, "Black", path, 0.05, 4)

## The stern ramp: a raised steel panel on the transom with its hinge.
static func _ramp(lm: LandmarkMesh, s: Dictionary) -> void:
	var length: float = s["length"]
	var beam: float = s["beam"]
	var fb: float = s["freeboard"]
	var x := -length * 0.5 - 0.08
	var w := beam * 0.42
	var y0 := 1.6
	var y1 := fb * 0.72
	lm.box("DeckSteel", Vector3(x, (y0 + y1) * 0.5, 0), Vector3(0.18, y1 - y0, w), Basis(), 0.0)
	for k in 5:
		var y := lerpf(y0 + 0.6, y1 - 0.6, float(k) / 4.0)
		lm.box("Black", Vector3(x - 0.1, y, 0), Vector3(0.04, 0.08, w * 0.94), Basis(), 0.0)
	HullLoft.tube(lm, "Black", [Vector3(x - 0.12, y0, -w * 0.5), Vector3(x - 0.12, y0, w * 0.5)], 0.18, 8)
