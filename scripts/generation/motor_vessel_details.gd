class_name MotorVesselDetails
extends RefCounted

## Near motor craft: moulded saloons, open helms and recessed cockpits.
## The reduced models remain in MotorYachtModel for distant fleets.

static func cruiser(lm: LandmarkMesh, spec: Dictionary, variant: String) -> void:
	var length: float = spec["length"]
	var beam: float = spec["beam"]
	var fb: float = spec["freeboard"]
	var y := fb + 0.02
	var h := length * 0.12
	var width := beam * 0.76
	VesselForms.cabin(lm, -length * 0.105, length * 0.39, width, y, h, length * 0.065, "White", 0.48)
	VesselForms.slab(lm, "White", Vector3(-length * 0.12, y + h + 0.04, 0),
		Vector3(length * 0.41, 0.1, width * 1.06), width * 0.2)
	# Aft cockpit seating and low bathing platform stay inside the hull length.
	VesselForms.slab(lm, "Deck", Vector3(-length * 0.465, fb * 0.55, 0), Vector3(length * 0.065, 0.08, beam * 0.73), beam * 0.12)
	for side in [-1.0, 1.0]:
		VesselForms.slab(lm, "Canvas", Vector3(-length * 0.36, fb * 0.83, float(side) * beam * 0.24),
			Vector3(length * 0.12, length * 0.035, beam * 0.18), beam * 0.06)
	var top := y + h + 0.09
	if variant == "flybridge":
		# Low coamings around an open upper helm, rather than a second cabin.
		for side in [-1.0, 1.0]:
			VesselForms.slab(lm, "White", Vector3(-length * 0.1, top + length * 0.015, float(side) * width * 0.36),
				Vector3(length * 0.25, length * 0.03, width * 0.08), width * 0.035)
		VesselForms.cabin(lm, -length * 0.025, length * 0.07, width * 0.64, top, length * 0.04, 0.7, "White", 0.6)
		VesselForms.slab(lm, "Canvas", Vector3(-length * 0.15, top + length * 0.018, 0),
			Vector3(length * 0.06, length * 0.036, width * 0.55), width * 0.06)
		if bool(spec.get("ultra", false)):
			VesselEquipment.helm(lm, Vector3(-length * 0.075, top + length * 0.018, 0), clampf(length * 0.045, 0.7, 1.2))
		top += length * 0.07
	var arch_x := -length * 0.17
	for side in [-1.0, 1.0]:
		HullLoft.tube(lm, "Steel", [Vector3(arch_x, y + h, float(side) * width * 0.4),
			Vector3(arch_x - length * 0.02, top + length * 0.045, float(side) * width * 0.35)], length * 0.0035, 8)
	VesselForms.slab(lm, "White", Vector3(arch_x, top + length * 0.045, 0),
		Vector3(length * 0.17, 0.1, width * 0.85), width * 0.12)
	lm.lathe("White", Vector3(arch_x, top + length * 0.045 + 0.05, 0),
		PackedVector2Array([Vector2(length * 0.016, 0), Vector2(length * 0.018, length * 0.01), Vector2(length * 0.01, length * 0.022)]), 12)
	HullLoft.tube(lm, "Steel", [Vector3(arch_x, top + length * 0.05, width * 0.2),
		Vector3(arch_x, top + length * 0.11, width * 0.2)], length * 0.0015, 6)
	# Hull windows follow the actual flared skin at both their upper/lower edges.
	for side in [-1.0, 1.0]:
		for i in 12:
			var a := lerpf(-length * 0.25, length * 0.22, float(i) / 12.0)
			var b := lerpf(-length * 0.25, length * 0.22, float(i + 1) / 12.0)
			var lo := fb * 0.45
			var hi := fb * 0.65
			lm.quad("Glass", Vector3(a, lo, float(side) * (HullLoft.side_z(spec, a, lo) + 0.008)),
				Vector3(b, lo, float(side) * (HullLoft.side_z(spec, b, lo) + 0.008)),
				Vector3(b, hi, float(side) * (HullLoft.side_z(spec, b, hi) + 0.008)),
				Vector3(a, hi, float(side) * (HullLoft.side_z(spec, a, hi) + 0.008)), Vector3(0, 0, float(side)))
	VesselForms.hatch(lm, Vector3(length * 0.25, HullLoft.sheer(spec, length * 0.25) + 0.04, 0), length * 0.075, beam * 0.3)
	VesselKit.guard(lm, spec, -length * 0.43, -length * 0.29, length * 0.035, 0.8)
	VesselKit.guard(lm, spec, length * 0.08, length * 0.46, length * 0.035, 0.8)
	VesselForms.fittings(lm, spec)
	if bool(spec.get("ultra", false)):
		VesselEquipment.deck(lm, spec)
		VesselEquipment.ladder(lm, Vector3(-length * 0.32, fb * 0.65, beam * 0.21), maxf(0.6, y + h - fb * 0.65), beam * 0.14)
		for side in [-1.0, 1.0]:
			VesselForms.slab(lm, "Canvas", Vector3(length * 0.14, HullLoft.sheer(spec, length * 0.14) + 0.05, float(side) * beam * 0.16),
				Vector3(length * 0.08, 0.1, beam * 0.27), beam * 0.05)
			VesselForms.slab(lm, "Canvas", Vector3(-length * 0.4, fb * 0.95, float(side) * beam * 0.24),
				Vector3(length * 0.025, length * 0.055, beam * 0.18), beam * 0.035)

static func open_boat(lm: LandmarkMesh, spec: Dictionary, variant: String) -> void:
	var length: float = spec["length"]
	var beam: float = spec["beam"]
	var fb: float = spec["freeboard"]
	var y: float = spec["cockpit_y"]
	var ultra := bool(spec.get("ultra", false))
	if variant == "rib":
		var path: Array = []
		for i in 25:
			var x := lerpf(-length * 0.46, length * 0.4, float(i) / 24.0)
			path.append(Vector3(x, HullLoft.sheer(spec, x), -HullLoft.half(spec, x) + beam * 0.06))
		for i in range(1, 13):
			var a := PI * float(i) / 12.0
			path.append(Vector3(length * 0.4 + length * 0.07 * sin(a), HullLoft.sheer(spec, length * 0.4),
				-(HullLoft.half(spec, length * 0.4) - beam * 0.06) * cos(a)))
		for i in range(23, -1, -1):
			var x := lerpf(-length * 0.46, length * 0.4, float(i) / 24.0)
			path.append(Vector3(x, HullLoft.sheer(spec, x), HullLoft.half(spec, x) - beam * 0.06))
		HullLoft.tube(lm, "Dark", path, beam * 0.095, 16 if ultra else 9, true)
	# Bowrider has twin helms and a broad windshield; other craft a console.
	var width := beam * (0.72 if variant == "runabout" else 0.32)
	VesselForms.cabin(lm, length * 0.04, length * 0.16, width, y + length * 0.02, length * 0.16, 0.55, "White", 0.45)
	for side in [-1.0, 1.0]:
		VesselForms.slab(lm, "Canvas", Vector3(-length * 0.15, y + length * 0.07, float(side) * beam * 0.18),
			Vector3(length * 0.09, length * 0.04, beam * 0.2), beam * 0.06)
		HullLoft.tube(lm, "Steel", [Vector3(-length * 0.15, y, float(side) * beam * 0.18),
			Vector3(-length * 0.15, y + length * 0.05, float(side) * beam * 0.18)], 0.025, 6)
	VesselForms.slab(lm, "Canvas", Vector3(-length * 0.31, y + length * 0.04, 0),
		Vector3(length * 0.095, length * 0.045, beam * 0.56), beam * 0.08)
	VesselForms.slab(lm, "Canvas", Vector3(length * 0.29, fb + 0.03, 0),
		Vector3(length * 0.12, length * 0.025, beam * 0.44), beam * 0.1)
	if variant != "runabout":
		for side in [-1.0, 1.0]:
			HullLoft.tube(lm, "Steel", [Vector3(-length * 0.02, y + length * 0.1, float(side) * width * 0.46),
				Vector3(-length * 0.02, y + length * 0.31, float(side) * width * 0.46)], 0.025, 8)
		VesselForms.slab(lm, "Canvas", Vector3(-length * 0.015, y + length * 0.315, 0),
			Vector3(length * 0.24, 0.06, beam * 0.52), beam * 0.09)
	VesselKit.outboard(lm, Vector3(HullLoft.x0(spec) - 0.02, fb * 0.9, 0), length * 0.18, true)
	VesselForms.fittings(lm, spec)
	if ultra:
		VesselEquipment.helm(lm, Vector3(-length * 0.048, y + length * 0.08, 0), clampf(length * 0.1, 0.55, 1.1))
		VesselEquipment.life_ring(lm, Vector3(-length * 0.32, fb * 0.85, -beam * 0.47), Vector3.FORWARD, beam * 0.075)
		VesselEquipment.ring(lm, "Dark", Vector3(-length * 0.24, y + 0.018, beam * 0.12), Vector3.UP, length * 0.009, 0.006)
		for side in [-1.0, 1.0]:
			HullLoft.tube(lm, "Steel", [Vector3(-length * 0.26, fb, float(side) * beam * 0.43),
				Vector3(-length * 0.27, fb + length * 0.06, float(side) * beam * 0.43)], 0.025, 10)
		VesselEquipment.ladder(lm, Vector3(-length * 0.48, -length * 0.035, beam * 0.2), fb + length * 0.035, beam * 0.17)
		for side in [-1.0, 1.0]:
			VesselForms.slab(lm, "Canvas", Vector3(-length * 0.195, y + length * 0.115, float(side) * beam * 0.18),
				Vector3(length * 0.03, length * 0.1, beam * 0.2), beam * 0.04)
