class_name MotorYachtModel
extends RefCounted

## Motor yachts and day boats on a lofted V hull. Variants: "flybridge" (a
## saloon with an upper helm and radar arch, 14 m+), "sport" (saloon under
## a hardtop), "runabout" (open bowrider), "rib" (inflatable collar, centre
## console) and "console" (hard open boat). +X bow, hull centred on x = 0,
## waterline at y = 0. `detail` adds rails, mullions and fittings; without
## it the boat is a hull plus a few masses for far instances.

static func variant_for(length: float, pick: float) -> String:
	if length < 9.0:
		return "rib" if pick < 0.4 else ("console" if pick < 0.6 else "runabout")
	return "flybridge" if length >= 14.0 and pick < 0.7 else "sport"

static func build(lm: LandmarkMesh, p: Dictionary) -> void:
	var length: float = p["length"]
	var variant: String = p.get("variant", "sport")
	var detail: bool = p.get("detail", true)
	var small := variant in ["runabout", "rib", "console"]
	var spec := {"length": length, "beam": length * (0.34 if small else 0.27),
		"freeboard": length * (0.11 if small else 0.085), "draft": length * (0.06 if small else 0.07),
		"entry": 0.42, "bow_pow": 1.7, "stern_w": 0.9, "flare": 0.16, "deadrise": 1.0,
		"bow_rise": length * 0.025, "stem_rake": length * 0.05, "stern_rake": length * 0.03,
		"keel_lift": 0.7, "lod": 0 if detail else 1}
	VesselMaterials.register(lm, p.get("maps", true), p["hull"], VesselMaterials.get_mat("antifoul", p.get("maps", true)))
	var keys := {"hull": "Hull", "boot": "Dark" if not small else "Hull", "bottom": "Bottom", "deck": "White" if small else "Deck"}
	HullLoft.loft(lm, spec, keys)
	if small:
		_open_boat(lm, spec, variant, detail)
	else:
		_cruiser(lm, spec, variant, detail)

static func _cruiser(lm: LandmarkMesh, spec: Dictionary, variant: String, detail: bool) -> void:
	var length: float = spec["length"]
	var beam: float = spec["beam"]
	var fb: float = spec["freeboard"]
	var deck_y := fb + 0.02
	var x_aft := -length * 0.46
	# Swim platform and cockpit sole under the stern.
	lm.box("Deck", Vector3(x_aft + length * 0.03, fb * 0.45, 0), Vector3(length * 0.07, 0.06, beam * 0.62), Basis(), 0.0)
	# Saloon: white body, windscreen raked forward, hardtop overhanging.
	var sal_h := length * 0.12
	var sal_x0 := -length * 0.27
	var sal_x1 := length * 0.06
	var sal_w := beam * 0.76
	lm.box("White", Vector3((sal_x0 + sal_x1) * 0.5, deck_y + sal_h * 0.5, 0),
		Vector3(sal_x1 - sal_x0, sal_h, sal_w), Basis(), 0.02)
	for s in [-1.0, 1.0]:
		# Side windows in a continuous dark band, rising toward the bow.
		lm.quad("Glass", Vector3(sal_x0 + 0.2, deck_y + sal_h * 0.3, float(s) * (sal_w * 0.5 + 0.012)),
			Vector3(sal_x1 + 0.05, deck_y + sal_h * 0.3, float(s) * (sal_w * 0.5 + 0.012)),
			Vector3(sal_x1 + 0.05, deck_y + sal_h * 0.85, float(s) * (sal_w * 0.5 + 0.012)),
			Vector3(sal_x0 + 0.2, deck_y + sal_h * 0.85, float(s) * (sal_w * 0.5 + 0.012)), Vector3(0, 0, float(s)))
	# Wrap-around windscreen: a sloped dark pane ahead of the saloon.
	var wy := deck_y + sal_h
	lm.quad("Glass", Vector3(sal_x1 + length * 0.05, deck_y + sal_h * 0.35, -sal_w * 0.47),
		Vector3(sal_x1 + length * 0.05, deck_y + sal_h * 0.35, sal_w * 0.47),
		Vector3(sal_x1 - 0.02, wy - 0.02, sal_w * 0.5), Vector3(sal_x1 - 0.02, wy - 0.02, -sal_w * 0.5),
		Vector3(0.6, 0.8, 0).normalized())
	lm.box("White", Vector3(sal_x0 + length * 0.18, wy + 0.04, 0),
		Vector3(sal_x1 - sal_x0 + length * 0.1, 0.08, sal_w + 0.2), Basis(), 0.0)
	var top := wy + 0.08
	if variant == "flybridge":
		var fly_h := length * 0.07
		var fx0 := -length * 0.22
		var fx1 := length * 0.0
		lm.box("White", Vector3((fx0 + fx1) * 0.5, top + fly_h * 0.5, 0), Vector3(fx1 - fx0, fly_h, sal_w * 0.62), Basis(), 0.02)
		lm.quad("Glass", Vector3(fx1 + length * 0.025, top + fly_h * 0.15, -sal_w * 0.28),
			Vector3(fx1 + length * 0.025, top + fly_h * 0.15, sal_w * 0.28),
			Vector3(fx1 + 0.02, top + fly_h, sal_w * 0.3), Vector3(fx1 + 0.02, top + fly_h, -sal_w * 0.3),
			Vector3(0.6, 0.8, 0).normalized())
		lm.box("White", Vector3((fx0 + fx1) * 0.5 + 0.2, top + fly_h + 0.04, 0),
			Vector3(fx1 - fx0 + length * 0.07, 0.08, sal_w * 0.7), Basis(), 0.0)
		top += fly_h + 0.08
	# Radar arch aft of the helm.
	var arch_x := -length * 0.14 if variant == "flybridge" else -length * 0.1
	for s in [-1.0, 1.0]:
		lm.beam("Steel", Vector3(arch_x, top, float(s) * sal_w * 0.28), Vector3(arch_x - length * 0.02, top + length * 0.07, float(s) * sal_w * 0.28), 0.05 + length * 0.002)
	lm.beam("Steel", Vector3(arch_x - length * 0.02, top + length * 0.07, -sal_w * 0.28),
		Vector3(arch_x - length * 0.02, top + length * 0.07, sal_w * 0.28), 0.05 + length * 0.002)
	lm.lathe("White", Vector3(arch_x - length * 0.02, top + length * 0.07, 0),
		PackedVector2Array([Vector2(length * 0.014, 0), Vector2(length * 0.012, length * 0.014)]), 8, 1.0, 1.0, 0.0, true, true)
	if not detail:
		return
	# Hull-side window strip, foredeck hatch, bow pulpit and gunwale rails.
	var prev := Vector3.INF
	for i in 9:
		var x := lerpf(-length * 0.28, length * 0.2, float(i) / 8.0)
		var y := fb * 0.62
		var pt := Vector3(x, y, HullLoft.side_z(spec, x, y) + 0.01)
		if prev != Vector3.INF:
			for s in [-1.0, 1.0]:
				lm.quad("Glass", Vector3(prev.x, prev.y - fb * 0.1, prev.z * float(s)), Vector3(pt.x, pt.y - fb * 0.1, pt.z * float(s)),
					Vector3(pt.x, pt.y + fb * 0.1, pt.z * float(s)), Vector3(prev.x, prev.y + fb * 0.1, prev.z * float(s)), Vector3(0, 0, float(s)))
		prev = pt
	lm.box("White", Vector3(length * 0.26, deck_y + 0.07, 0), Vector3(length * 0.07, 0.14, beam * 0.3), Basis(), 0.02)
	VesselKit.guard(lm, spec, x_aft + length * 0.06, sal_x0 + 0.1, length * 0.03, 0.55)
	VesselKit.guard(lm, spec, sal_x1 + length * 0.1, length * 0.44, length * 0.035, 0.5)
	lm.beam("Steel", Vector3(length * 0.44, deck_y, 0), Vector3(length * 0.47, deck_y + length * 0.035, 0), 0.04)

static func _open_boat(lm: LandmarkMesh, spec: Dictionary, variant: String, detail: bool) -> void:
	var length: float = spec["length"]
	var beam: float = spec["beam"]
	var fb: float = spec["freeboard"]
	var deck_y := fb * 0.55
	var hull_hw := beam * 0.5
	if variant == "rib":
		# Inflatable collar: one continuous tube round the gunwale.
		var path: Array = []
		for i in range(0, 13):
			var x := lerpf(-length * 0.47, length * 0.40, float(i) / 12.0)
			path.append(Vector3(x, fb + 0.02, -(HullLoft.half(spec, x) - beam * 0.055)))
		for i in range(1, 6):
			var a := PI * float(i) / 6.0
			path.append(Vector3(length * 0.40 + length * 0.07 * sin(a), fb + 0.02, -(HullLoft.half(spec, length * 0.40) - beam * 0.055) * cos(a)))
		for i in range(12, -1, -1):
			var x := lerpf(-length * 0.47, length * 0.40, float(i) / 12.0)
			path.append(Vector3(x, fb + 0.02, HullLoft.half(spec, x) - beam * 0.055))
		HullLoft.tube(lm, "Dark", path, beam * 0.1, 8 if detail else 5)
	else:
		lm.box("White", Vector3(length * 0.2, deck_y + 0.15, 0), Vector3(length * 0.2, 0.1, hull_hw * 1.2), Basis(), 0.0)
	# Centre console with windscreen / T-top, bench seat aft.
	var cx := -length * 0.02
	lm.box("White", Vector3(cx, deck_y + length * 0.07, 0), Vector3(length * 0.14, length * 0.14, beam * 0.3), Basis(), 0.02)
	lm.quad("Glass", Vector3(cx + length * 0.08, deck_y + length * 0.12, -beam * 0.15),
		Vector3(cx + length * 0.08, deck_y + length * 0.12, beam * 0.15),
		Vector3(cx + length * 0.05, deck_y + length * 0.24, beam * 0.15),
		Vector3(cx + length * 0.05, deck_y + length * 0.24, -beam * 0.15), Vector3(0.7, 0.7, 0).normalized())
	lm.box("White", Vector3(-length * 0.28, deck_y + length * 0.05, 0), Vector3(length * 0.1, length * 0.1, beam * 0.55), Basis(), 0.02)
	if variant != "runabout":
		for s in [-1.0, 1.0]:
			lm.beam("Steel", Vector3(cx - length * 0.05, deck_y + length * 0.14, float(s) * beam * 0.15),
				Vector3(cx - length * 0.05, deck_y + length * 0.3, float(s) * beam * 0.15), 0.04)
		lm.box("White", Vector3(cx - length * 0.05, deck_y + length * 0.31, 0), Vector3(length * 0.2, 0.05, beam * 0.45), Basis(), 0.0)
	VesselKit.outboard(lm, Vector3(HullLoft.x0(spec) - 0.02, fb * 0.9, 0), length * 0.18)
	if detail:
		VesselKit.guard(lm, spec, length * 0.12, length * 0.42, length * 0.05, 0.4)
