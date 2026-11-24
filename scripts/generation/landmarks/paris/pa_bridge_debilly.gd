class_name LandmarkPaBridgeDebilly
extends RefCounted

## Passerelle Debilly (Jean Résal & Amédée Alby, 1900 Exposition Universelle; 604 m from Trocadéro).
## 125 m single-span bottle-green riveted steel through-arch pedestrian bridge (8 m wide) linking
## Palais de Tokyo to Quai Branly, with two masonry piers faced in sea-green ceramic tiles,
## curved steel lattice arch ribs rising to 16.0 m above the Seine, and warm walkway lamps.
## Built along +X with y = 0 at Seine datum (`base: sea`), deck 7.0 m, arch crown 16.0 m.

const SPAN_TOTAL := 125.0
const MAIN_ARCH := 75.0
const HALF_L := SPAN_TOTAL * 0.5
const HALF_W := 4.0
const DECK_Y := 7.0

static func build(model: Node3D) -> void:
	build_fitted(model, DECK_Y, 0.0, 0.0)

static func build_fitted(model: Node3D, deck_m: float, tilt_m: float = 0.0, rise_m: float = 0.0) -> void:
	var deck_y := maxf(deck_m, 2.5)
	var most := maxf(BridgeSpec.DECK_GRADE * HALF_L - BridgeCamber.RAMP_STEEPEST * absf(tilt_m), 0.0) \
		/ BridgeCamber.LIFT_STEEPEST
	var camber_m := clampf(maxf(DECK_Y - deck_y, rise_m), 0.0, most)
	var lm := LandmarkMesh.new()
	lm.use("Green", LandmarkPaKit.paris_green("#295E4A"))
	lm.use("DarkGreen", LandmarkPaKit.paris_green("#1B3F31"))
	lm.use("Tile", LandmarkPaKit.verdigris("#5F9480"))
	lm.use("Stone", LandmarkPaKit.lutetian("#D5C9AE", 3.0))
	lm.use("Deck", LandmarkMaterials.pbr("wood", "#7A634A", 2.4))
	lm.use("Lamp", LandmarkMaterials.lit("#FFE4AE", 1.35))
	# Timber pedestrian boardwalk & wrought-iron balustrades
	lm.box("Deck", Vector3(0.0, deck_y - 0.15, 0.0), Vector3(SPAN_TOTAL, 0.45, HALF_W * 2.0 - 0.6))
	for sz in [-1.0, 1.0]:
		var ez := float(sz) * HALF_W
		lm.box("Green", Vector3(0.0, deck_y - 0.35, ez), Vector3(SPAN_TOTAL, 0.8, 0.35))
		lm.box("DarkGreen", Vector3(0.0, deck_y + 1.15, ez), Vector3(SPAN_TOTAL, 0.16, 0.22))
		lm.box("Green", Vector3(0.0, deck_y + 0.60, ez), Vector3(SPAN_TOTAL, 0.85, 0.12))
	# Central 75 m rising through-arch (springing from masonry river piers at x = +/-37.5, peaking at 16.0 m)
	var arch_crown := deck_y + 9.0
	var arch_spring := maxf(1.5, deck_y - 4.2)
	for sz in [-1.0, 1.0]:
		var ez := float(sz) * (HALF_W + 0.15)
		LandmarkPaKit.arch_rib(lm, "Green", -MAIN_ARCH * 0.5, MAIN_ARCH * 0.5, arch_spring, arch_crown, ez, 18, 0.95, 0.55)
		LandmarkPaKit.arch_rib(lm, "DarkGreen", -MAIN_ARCH * 0.5, MAIN_ARCH * 0.5,
			arch_spring - 1.1, arch_crown - 1.1, ez, 18, 0.45, 0.42)
		# Vertical suspension hangers & spandrel struts
		for k in 15:
			var u := (float(k) + 0.5) / 15.0
			var hx := lerpf(-MAIN_ARCH * 0.46, MAIN_ARCH * 0.46, u)
			var hy := arch_spring + sin(PI * u) * (arch_crown - arch_spring)
			var dy := hy - deck_y
			if absf(dy) > 0.35:
				lm.box("DarkGreen", Vector3(hx, (hy + deck_y) * 0.5, ez), Vector3(0.22, absf(dy), 0.22))
		# Side approach half-arches
		for sx in [-1.0, 1.0]:
			var sx0 := float(sx) * (MAIN_ARCH * 0.5 + 1.5)
			var sx1 := float(sx) * (HALF_L - 1.5)
			LandmarkPaKit.arch_rib(lm, "Green", minf(sx0, sx1), maxf(sx0, sx1),
				arch_spring, deck_y - 0.55, ez, 8, 0.65, 0.45)
	# Overhead wind bracing across the arch crown
	for k in 7:
		var u := lerpf(0.24, 0.76, float(k) / 6.0)
		var bx := lerpf(-MAIN_ARCH * 0.5, MAIN_ARCH * 0.5, u)
		var by := arch_spring + sin(PI * u) * (arch_crown - arch_spring) - 0.4
		lm.box("DarkGreen", Vector3(bx, by, 0.0), Vector3(0.35, 0.35, HALF_W * 2.0 + 0.3))
	# Two iconic ceramic-tiled masonry river piers + warm walkway globe lamps
	var pier_h := maxf(deck_y + 1.4, 2.5)
	for sx in [-1.0, 1.0]:
		var px := float(sx) * (MAIN_ARCH * 0.5)
		lm.box("Stone", Vector3(px, -1.2 + pier_h * 0.5, 0.0), Vector3(3.4, pier_h, HALF_W * 2.0 + 2.6))
		lm.box("Tile", Vector3(px, deck_y - 1.4, 0.0), Vector3(3.55, 3.6, HALF_W * 2.0 + 2.75))
		for sz in [-1.0, 1.0]:
			LandmarkPaKit.paris_lamp(lm, "DarkGreen", "Lamp",
				Vector3(px, deck_y + 1.2, float(sz) * (HALF_W + 0.15)), 3.8)
			LandmarkPaKit.paris_lamp(lm, "DarkGreen", "Lamp",
				Vector3(float(sx) * 18.0, deck_y + 1.2, float(sz) * (HALF_W + 0.15)), 3.6)
	BridgeCamber.apply(lm, HALF_L, deck_y, camber_m, tilt_m)
	lm.commit(model)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(0.0, 2.0, 14.0), Vector3(0.0, deck_y + 5.0, 4.0), 68.0, 0.9, 45.0],
		[Vector3(0.0, 2.0, -14.0), Vector3(0.0, deck_y + 5.0, -4.0), 68.0, 0.9, 45.0],
	])
