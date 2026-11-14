class_name FerryVesselModel
extends RefCounted

## Double-ended municipal ferry. Kept separate from berth selection so
## model refinements cannot change the harbour traffic placement rules.
static func build() -> LandmarkMesh:
	var lm := LandmarkMesh.new()
	var length := HarbourFerries.LENGTH_M
	var beam := HarbourFerries.BEAM_M
	var orange := Color("#e0651c")
	VesselMaterials.register(lm, true, VesselMaterials.get_mat("orange"))
	lm.use("Hull", ShipPaint.hull(orange, length, 3.4))
	lm.use("Orange", ShipPaint.enamel(orange))
	lm.use("White", ShipPaint.enamel(Color("#ebe9e2")))
	var spec := {"length": length, "beam": beam, "freeboard": 3.4, "draft": 1.8,
		"entry": 0.27, "bow_pow": 1.65, "flare": 0.09, "bow_rise": 0.12,
		"stern_rise": 0.12, "double_ended": true, "end_width": 0.4, "lod": 0, "ultra": true}
	HullLoft.loft(lm, spec, {"hull": "Hull", "boot": "Dark", "bottom": "Bottom", "deck": "White"})
	for level in 3:
		var y := 3.7 + float(level) * 3.0
		var deck_len := length - 15.0 - float(level) * 6.0
		var width := beam - 3.0 - float(level) * 0.7
		VesselForms.cabin(lm, 0, deck_len - 3.0, width - 2.0, y, 2.7, 2.8, "Orange", 0.0)
		VesselForms.slab(lm, "White", Vector3(0, y + 2.73, 0), Vector3(deck_len + 0.4, 0.16, width + 0.4), 2.0)
		# Outer promenade posts carry the roof and handrail around each deck.
		for side in [-1.0, 1.0]:
			var z: float = float(side) * width * 0.48
			HullLoft.tube(lm, "White", [Vector3(-deck_len * 0.45, y + 1.0, z), Vector3(deck_len * 0.45, y + 1.0, z)], 0.045, 8)
			for i in 22:
				var x := lerpf(-deck_len * 0.45, deck_len * 0.45, float(i) / 21.0)
				HullLoft.tube(lm, "Orange", [Vector3(x, y, z), Vector3(x, y + 2.7, z)], 0.07, 8)
	for end in [-1.0, 1.0]:
		# Both boarding ends and pilothouses have the same dimensions.
		var x: float = float(end) * 25.0
		VesselForms.cabin(lm, x, 10.0, 9.0, 12.45, 2.4, 1.35, "White", 0.0)
		VesselForms.slab(lm, "White", Vector3(x, 14.9, 0), Vector3(10.3, 0.1, 9.3), 1.0)
		var bx: float = float(end) * length * 0.435
		VesselForms.slab(lm, "Dark", Vector3(bx, 3.52, 0), Vector3(5.0, 0.12, beam * 0.39), 0.4)
		for side in [-1.0, 1.0]:
			var z: float = float(side) * beam * 0.22
			HullLoft.tube(lm, "Orange", [Vector3(bx - 2.0, 3.6, z), Vector3(bx - 2.0, 5.0, z),
				Vector3(bx + 2.0, 5.0, z), Vector3(bx + 2.0, 3.6, z)], 0.08, 8)
			VesselForms.cleat(lm, Vector3(float(end) * 35.0, 3.6, float(side) * beam * 0.36), 0.6)
	for side in [-1.0, 1.0]:
		VesselKit.funnel(lm, Vector3(0, 12.5, float(side) * 4.4), 2.1, 0.6, 2.5, "Orange", "Dark", true)
	for side in [-1.0, 1.0]:
		for x in [-12.0, -5.0, 5.0, 12.0]:
			VesselForms.slab(lm, "White", Vector3(float(x), 12.85, float(side) * 5.4), Vector3(3.5, 0.25, 0.8), 0.2)
			VesselForms.slab(lm, "White", Vector3(float(x), 13.15, float(side) * 5.7), Vector3(3.5, 0.65, 0.15), 0.06)
		for x in [-28.0, 0.0, 28.0]:
			VesselEquipment.life_ring(lm, Vector3(float(x), 8.0, float(side) * 8.7), Vector3(0, 0, float(side)), 0.4)
	VesselEquipment.ladder(lm, Vector3(-14, 9.7, 6), 2.8, 0.65)
	return lm
