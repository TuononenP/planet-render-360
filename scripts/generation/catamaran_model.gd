class_name CatamaranModel
extends RefCounted

## Moored Mediterranean cruising catamaran: two separate displacement
## hulls, raised bridge deck, saloon, shaded aft cockpit and bow trampoline.
const BEAM_SHARE := 0.52
## Includes the hanging fenders outside the hulls.
const BERTH_BEAM_SHARE := 0.58

static func build(lm: LandmarkMesh, p: Dictionary) -> void:
	var length: float = p["length"]
	var detail: bool = p.get("detail", true)
	var ultra: bool = p.get("ultra", false)
	var maps: bool = p.get("maps", true)
	var beam := length * BEAM_SHARE
	VesselMaterials.register(lm, maps, p["hull"], VesselMaterials.get_mat("antifoul", maps))
	lm.use("Sail", VesselMaterials.get_mat("canvas", maps))
	var spec := {"length": length, "beam": length * 0.14, "freeboard": length * 0.075,
		"draft": length * 0.055, "entry": 0.42, "bow_pow": 1.65, "stern_w": 0.75,
		"bow_rise": length * 0.018, "stem_rake": length * 0.025, "flare": 0.1,
		"lod": 0 if detail else 1, "ultra": ultra}
	for side in [-1.0, 1.0]:
		var z: float = float(side) * length * 0.19
		var hull := HullLoft.loft(lm, spec, {"hull": "Hull", "boot": "Dark", "bottom": "Bottom", "deck": "White"}, Vector3(0, 0, z))
		if detail:
			var paths: Array = hull["sheer"]
			var outer: PackedVector3Array = paths[0 if side < 0.0 else 1]
			var rail: Array = []
			for i in outer.size():
				rail.append(outer[i] + Vector3.UP * length * 0.045)
				if i % 6 == 0:
					HullLoft.tube(lm, "Steel", [outer[i], rail[i]], 0.012, 6)
			HullLoft.tube(lm, "Steel", rail, 0.012, 8)
			VesselForms.slab(lm, "Deck", Vector3(-length * 0.44, length * 0.035, z),
				Vector3(length * 0.1, length * 0.015, length * 0.12), length * 0.025)
	# Crossbeams meet both hulls and carry the bridge deck above the tunnel.
	for x in [-0.3, -0.05, 0.16]:
		lm.box("White", Vector3(length * float(x), length * 0.082, 0),
			Vector3(length * 0.045, length * 0.03, beam * 0.87), Basis(), 0.02 if detail else 0.0)
	# The underside stays above water, leaving the tunnel between hulls open.
	if detail:
		VesselForms.slab(lm, "White", Vector3(-length * 0.12, length * 0.105, 0),
			Vector3(length * 0.61, length * 0.035, beam * 0.86), length * 0.035)
		VesselForms.slab(lm, "Deck", Vector3(-length * 0.12, length * 0.125, 0),
			Vector3(length * 0.59, length * 0.006, beam * 0.83), length * 0.03)
		VesselForms.cabin(lm, -length * 0.02, length * 0.34, beam * 0.73, length * 0.12, length * 0.1, length * 0.08, "White", 0.42)
		VesselForms.slab(lm, "White", Vector3(-length * 0.13, length * 0.226, 0),
			Vector3(length * 0.61, length * 0.012, beam * 0.82), length * 0.045)
		for side in [-1.0, 1.0]:
			var z: float = float(side) * beam * 0.32
			HullLoft.tube(lm, "Steel", [Vector3(-length * 0.4, length * 0.12, z), Vector3(-length * 0.4, length * 0.22, z)], 0.025, 10)
			VesselForms.slab(lm, "Canvas", Vector3(-length * 0.3, length * 0.145, z),
				Vector3(length * 0.18, length * 0.035, beam * 0.16), length * 0.025)
			VesselForms.hatch(lm, Vector3(length * 0.24, HullLoft.sheer(spec, length * 0.24) + 0.03, float(side) * length * 0.19), length * 0.06, length * 0.08)
	else:
		lm.box("White", Vector3(-length * 0.12, length * 0.105, 0), Vector3(length * 0.61, length * 0.035, beam * 0.86), Basis(), 0.0)
		VesselKit.house(lm, -length * 0.02, length * 0.34, beam * 0.73, length * 0.12, length * 0.1, true, 0.0)
	# Crossbeam and fine netting on the open foredeck.
	lm.box("Canvas", Vector3(length * 0.31, length * 0.1, 0), Vector3(length * 0.23, 0.015, length * 0.25), Basis(), 0.0)
	lm.beam("White", Vector3(length * 0.43, length * 0.1, -length * 0.19), Vector3(length * 0.43, length * 0.1, length * 0.19), length * 0.018)
	if ultra:
		for i in 14:
			var x := length * (0.195 + float(i) / 13.0 * 0.23)
			HullLoft.tube(lm, "Dark", [Vector3(x, length * 0.102, -length * 0.125), Vector3(x, length * 0.102, length * 0.125)], 0.004, 4)
		for i in 12:
			var z := length * (-0.125 + float(i) / 11.0 * 0.25)
			HullLoft.tube(lm, "Dark", [Vector3(length * 0.195, length * 0.102, z), Vector3(length * 0.425, length * 0.102, z)], 0.004, 4)
		VesselForms.slab(lm, "White", Vector3(-length * 0.19, length * 0.14, -beam * 0.35),
			Vector3(length * 0.06, length * 0.06, length * 0.07), length * 0.012)
		VesselEquipment.helm(lm, Vector3(-length * 0.21, length * 0.17, -beam * 0.35), 0.8)
		VesselEquipment.ladder(lm, Vector3(-length * 0.47, -length * 0.025, beam * 0.36), length * 0.14, length * 0.05)
	var rig_spec := {"length": length, "beam": beam, "freeboard": length * 0.1, "entry": 0.42, "anchors": false}
	SailYachtModel.rig(lm, p, rig_spec, length * 0.1, length * 1.05, length * 0.232)
	if detail:
		VesselForms.fittings(lm, rig_spec)
		HullLoft.tube(lm, "Steel", [Vector3(length * 0.43, length * 0.1, 0),
			Vector3(length * 0.43, length * 0.04, 0)], length * 0.004, 8)
		HullLoft.tube(lm, "Steel", [Vector3(length * 0.4, length * 0.055, 0),
			Vector3(length * 0.43, length * 0.04, 0), Vector3(length * 0.46, length * 0.055, 0)], length * 0.004, 8)
