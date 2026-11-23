class_name LandmarkLnHungerfordBridge
extends RefCounted

## Hungerford Rail Bridge (John Hawkshaw, 1864) flanked by the twin Golden Jubilee
## Cable-Stayed Footbridges (Lifschutz Davidson Sandilands & WSP, 2002; OSM ways
## 4254121, 186931859, 151744359). 316 m span across the Thames beside the London Eye.
## Central dark-grey steel lattice-truss railway deck on brick cylinder piers, flanked
## closely on both sides by sleek white pedestrian decks suspended from outward-leaning
## 32 m white steel pylons and fan stay cables. Built along +X (`base: sea`).

const SPAN_TOTAL := 316.0
const HALF_L := 158.0
const DECK_Y := 10.2
const RAIL_HALF_W := 7.2
const FOOT_Z := 12.2
const PYLON_TOP := 32.0

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Truss", LandmarkMaterials.paint("#4B5158", 0.55, 0.55))
	lm.use("Steel", LandmarkMaterials.paint("#E6EAEF", 0.38, 0.6))
	lm.use("Cable", LandmarkMaterials.paint("#C8D0D8", 0.42, 0.72))
	lm.use("Brick", LandmarkLnKit.red_brick("#8C4838", 3.0))
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#B8B5AE", 3.5))
	lm.use("Deck", LandmarkMaterials.pbr("asphalt", "#3D4044", 4.0))
	lm.use("Lamp", LandmarkMaterials.lit("#F4F8FF", 1.4))
	_rail_truss_bridge(lm)
	_golden_jubilee_footbridges(lm)
	lm.commit(model)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-75.0, 12.0, 22.0), Vector3(-75.0, 24.0, 12.0), 55.0, 0.85, 50.0],
		[Vector3(0.0, 12.0, 22.0), Vector3(0.0, 24.0, 12.0), 55.0, 0.9, 50.0],
		[Vector3(75.0, 12.0, 22.0), Vector3(75.0, 24.0, 12.0), 55.0, 0.85, 50.0],
	])

static func _rail_truss_bridge(lm: LandmarkMesh) -> void:
	# Railway deck slab
	lm.box("Deck", Vector3(0.0, DECK_Y, 0.0), Vector3(SPAN_TOTAL, 0.9, RAIL_HALF_W * 2.0))
	# Three longitudinal steel Warren/lattice truss lines (sides + centre)
	var bays := 32
	var dx := SPAN_TOTAL / float(bays)
	var tr_h := 4.4
	for tz in [-RAIL_HALF_W, 0.0, RAIL_HALF_W]:
		var z := float(tz)
		lm.box("Truss", Vector3(0.0, DECK_Y + tr_h, z), Vector3(SPAN_TOTAL, 0.45, 0.45))
		lm.box("Truss", Vector3(0.0, DECK_Y - 0.3, z), Vector3(SPAN_TOTAL, 0.5, 0.5))
		for i in bays:
			var x0 := -HALF_L + float(i) * dx
			var x1 := x0 + dx
			lm.beam("Truss", Vector3(x0, DECK_Y, z), Vector3(x1, DECK_Y + tr_h, z), 0.26, 0.26)
			lm.beam("Truss", Vector3(x1, DECK_Y, z), Vector3(x0, DECK_Y + tr_h, z), 0.26, 0.26)
			lm.box("Truss", Vector3(x0, DECK_Y + tr_h * 0.5, z), Vector3(0.28, tr_h, 0.28))
	# Hawkshaw's iconic paired brick cylindrical piers (6 river piers)
	for i in 6:
		var px := lerpf(-126.0, 126.0, float(i) / 5.0)
		for pz in [-RAIL_HALF_W - 0.8, RAIL_HALF_W + 0.8]:
			lm.frustum("Brick", Vector3(px, -1.5, float(pz)), 2.5, 2.3, DECK_Y + 1.8, 12)
			lm.box("Concrete", Vector3(px, DECK_Y - 0.1, float(pz)), Vector3(5.2, 0.8, 5.2))
		lm.box("Brick", Vector3(px, DECK_Y * 0.45, 0.0), Vector3(3.2, DECK_Y, RAIL_HALF_W * 2.0))

static func _golden_jubilee_footbridges(lm: LandmarkMesh) -> void:
	for side in [-1.0, 1.0]:
		var sz := float(side)
		var dz := sz * FOOT_Z
		# Sleek white concrete-and-steel footbridge deck + lit handrail strip
		lm.box("Concrete", Vector3(0.0, DECK_Y - 0.4, dz), Vector3(SPAN_TOTAL, 0.65, 4.4))
		lm.box("Steel", Vector3(0.0, DECK_Y + 0.55, dz + sz * 2.1), Vector3(SPAN_TOTAL, 0.14, 0.14))
		lm.box("Steel", Vector3(0.0, DECK_Y + 0.55, dz - sz * 2.1), Vector3(SPAN_TOTAL, 0.14, 0.14))
		lm.box("Lamp", Vector3(0.0, DECK_Y + 0.15, dz + sz * 2.05), Vector3(SPAN_TOTAL - 4.0, 0.16, 0.12))
		# 6 outward-leaning white steel pylons & fan stay cables
		for i in 6:
			var px := lerpf(-126.0, 126.0, float(i) / 5.0)
			var base := Vector3(px, -1.0, dz + sz * 1.4)
			var top := Vector3(px, PYLON_TOP, dz + sz * 8.2)
			lm.frustum("Concrete", Vector3(px, -1.5, dz + sz * 1.4), 1.8, 1.6, DECK_Y + 1.2, 10)
			lm.beam("Steel", base, top, 0.95, 0.95)
			# Backstay down to pier collar
			lm.beam("Cable", top, Vector3(px, DECK_Y - 0.2, dz - sz * 2.4), 0.16, 0.16)
			# Fan of 4 forestays each side along deck
			for k in range(1, 5):
				var off := float(k) * 7.5
				for dir in [-1.0, 1.0]:
					var tx := clampf(px + float(dir) * off, -HALF_L + 2.0, HALF_L - 2.0)
					var anchor := top.lerp(base, float(k - 1) * 0.08)
					lm.beam("Cable", anchor, Vector3(tx, DECK_Y - 0.2, dz + sz * 2.0), 0.12, 0.12)
