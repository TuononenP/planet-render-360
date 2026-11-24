class_name LandmarkPaBridgeNeuf
extends RefCounted

## Pont Neuf (Baptiste Androuet du Cerceau & Guillaume Marchant, 1578–1607; 3.9 km E of Trocadéro).
## Paris's oldest standing bridge: 238 m long, 20.5 m wide dressed warm-limestone bridge of 12 arches
## (7 across the grand bras + 5 across the petit bras) straddling the western tip of Île de la Cité,
## with triangular cutwaters topped by semicircular bastion balconies (demi-lunes), sculpted mascaron
## cornice, central terre-plein carrying the bronze equestrian statue of Henri IV, and Parisian lamps.
## Built along +X with y = 0 at Seine datum (`base: sea`), deck 9.0 m, Henri IV statue top 14.5 m.

const SPAN_TOTAL := 238.0
const HALF_L := SPAN_TOTAL * 0.5
const HALF_W := 10.25
const DECK_Y := 9.0

static func build(model: Node3D) -> void:
	build_fitted(model, DECK_Y, 0.0, 0.0)

static func build_fitted(model: Node3D, deck_m: float, tilt_m: float = 0.0, rise_m: float = 0.0) -> void:
	var deck_y := maxf(deck_m, 2.5)
	var most := maxf(BridgeSpec.DECK_GRADE * HALF_L - BridgeCamber.RAMP_STEEPEST * absf(tilt_m), 0.0) \
		/ BridgeCamber.LIFT_STEEPEST
	var camber_m := clampf(maxf(DECK_Y - deck_y, rise_m), 0.0, most)
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkPaKit.lutetian("#D8C9A8", 3.2))
	lm.use("Ashlar", LandmarkPaKit.ashlar("#B9AA8B", 3.0))
	lm.use("Deck", LandmarkMaterials.pbr("asphalt", "#3D4044", 4.0))
	lm.use("Pave", LandmarkMaterials.pbr("stone", "#B2A896", 3.0))
	lm.use("Bronze", LandmarkPaKit.bronze("#3B453C"))
	lm.use("Iron", LandmarkPaKit.paris_green("#21382E"))
	lm.use("Lamp", LandmarkMaterials.lit("#FFE2A6", 1.35))
	_deck_and_arches(lm, deck_y)
	_henri_iv_terre_plein(lm, deck_y)
	BridgeCamber.apply(lm, HALF_L, deck_y, camber_m, tilt_m)
	lm.commit(model)
	var mid_y := deck_y + camber_m
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-64.0, 2.0, 18.0), Vector3(-64.0, mid_y - 0.5, 10.0), 62.0, 0.85, 50.0],
		[Vector3(0.0, 2.0, 22.0), Vector3(0.0, mid_y + 1.5, 10.0), 60.0, 0.95, 52.0],
		[Vector3(64.0, 2.0, 18.0), Vector3(64.0, mid_y - 0.5, 10.0), 62.0, 0.85, 50.0],
		[Vector3(-64.0, 2.0, -18.0), Vector3(-64.0, mid_y - 0.5, -10.0), 62.0, 0.85, 50.0],
		[Vector3(64.0, 2.0, -18.0), Vector3(64.0, mid_y - 0.5, -10.0), 62.0, 0.85, 50.0],
	])

static func _deck_and_arches(lm: LandmarkMesh, deck_y: float) -> void:
	lm.box("Deck", Vector3(0.0, deck_y - 0.25, 0.0), Vector3(SPAN_TOTAL, 0.65, HALF_W * 2.0 - 5.2))
	for sz in [-1.0, 1.0]:
		var fz := float(sz) * (HALF_W - 1.3)
		lm.box("Pave", Vector3(0.0, deck_y - 0.14, fz), Vector3(SPAN_TOTAL, 0.72, 2.6))
		var ez := float(sz) * (HALF_W + 0.05)
		# Heavy projecting Renaissance mascaron cornice & stone parapet
		lm.box("Ashlar", Vector3(0.0, deck_y - 0.45, ez + float(sz) * 0.25), Vector3(SPAN_TOTAL, 0.85, 0.95))
		lm.box("Stone", Vector3(0.0, deck_y + 0.60, ez), Vector3(SPAN_TOTAL, 1.05, 0.52))
	# 7 grand-bras arches (-116..-14) + 5 petit-bras arches (+22..+116)
	var pier_h := maxf(deck_y + 0.25, 2.0)
	var y_crown := deck_y - 0.95
	var y_spring := maxf(1.2, y_crown - 5.2)
	var groups := [[-116.0, -14.0, 7], [22.0, 116.0, 5]]
	for grp in groups:
		var gx0 := float(grp[0])
		var gx1 := float(grp[1])
		var n := int(grp[2])
		var step := (gx1 - gx0) / float(n)
		for i in n:
			var ax0 := gx0 + float(i) * step + 1.5
			var ax1 := gx0 + float(i + 1) * step - 1.5
			for z in [-HALF_W + 0.2, 0.0, HALF_W - 0.2]:
				LandmarkPaKit.arch_rib(lm, "Stone", ax0, ax1, y_spring, y_crown, float(z), 8, 1.1, 0.9)
			if i < n - 1:
				var px := gx0 + float(i + 1) * step
				lm.box("Ashlar", Vector3(px, -1.2 + pier_h * 0.5, 0.0), Vector3(3.2, pier_h, HALF_W * 2.0 + 1.4))
				# Signature semicircular bastion balconies (demi-lunes) over triangular cutwaters
				for sz in [-1.0, 1.0]:
					var bz := float(sz) * (HALF_W + 1.6)
					lm.frustum("Ashlar", Vector3(px, -1.2, bz), 2.4, 2.1, pier_h, 8)
					lm.frustum("Stone", Vector3(px, deck_y + 0.05, bz), 2.5, 2.5, 1.05, 10)
					LandmarkPaKit.paris_lamp(lm, "Iron", "Lamp", Vector3(px, deck_y + 1.1, bz + float(sz) * 1.4), 4.0)

static func _henri_iv_terre_plein(lm: LandmarkMesh, deck_y: float) -> void:
	# Central masonry island abutment between the two arms (x = -14..+22)
	var h := deck_y + 0.5
	lm.box("Ashlar", Vector3(4.0, -1.2 + h * 0.5, 0.0), Vector3(36.0, h, HALF_W * 2.0 + 3.0))
	# Downstream semicircular promontory & bronze equestrian statue of King Henri IV (top 14.5 m)
	lm.frustum("Ashlar", Vector3(4.0, -1.2, HALF_W + 5.0), 7.5, 7.5, h, 14)
	lm.box("Stone", Vector3(4.0, deck_y + 1.4, HALF_W + 4.8), Vector3(3.4, 2.8, 5.0))
	LandmarkPaKit.equestrian(lm, "Bronze", Vector3(4.0, deck_y + 2.8, HALF_W + 4.8), 0.72, 0.0, false)
	# Shore abutments
	for sx in [-1.0, 1.0]:
		lm.box("Ashlar", Vector3(float(sx) * (HALF_L - 1.5), -1.2 + h * 0.5, 0.0),
			Vector3(4.0, h, HALF_W * 2.0 + 2.0))
