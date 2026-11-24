class_name LandmarkPaBridgeBirHakeim
extends RefCounted

## Pont de Bir-Hakeim (Louis Biette & Jean-Camille Formigé, 1905; 727 m from Trocadéro).
## 237 m two-tier riveted steel-arch bridge crossing both arms of the Seine over Île aux Cygnes:
## lower road/pedestrian deck (24.7 m wide), upper colonnaded steel viaduct carrying Paris Métro
## Line 6 along the central spine, masonry belvedere on Île aux Cygnes crowned by the bronze
## equestrian "La France renaissante" sculpture, and Parisian globe lamps on both tiers.
## Built along +X with y = 0 at Seine water datum (`base: sea`), lower deck 9.0 m, viaduct top 20.5 m.

const SPAN_TOTAL := 237.0
const HALF_L := SPAN_TOTAL * 0.5
const HALF_W := 12.35
const DECK_Y := 9.0
const VIADUCT_Y := 16.5

static func build(model: Node3D) -> void:
	build_fitted(model, DECK_Y, 0.0, 0.0)

static func build_fitted(model: Node3D, deck_m: float, tilt_m: float = 0.0, rise_m: float = 0.0) -> void:
	var deck_y := maxf(deck_m, 2.5)
	var via_y := deck_y + (VIADUCT_Y - DECK_Y)
	var most := maxf(BridgeSpec.DECK_GRADE * HALF_L - BridgeCamber.RAMP_STEEPEST * absf(tilt_m), 0.0) \
		/ BridgeCamber.LIFT_STEEPEST
	var camber_m := clampf(maxf(DECK_Y - deck_y, rise_m), 0.0, most)
	var lm := LandmarkMesh.new()
	lm.use("Steel", LandmarkMaterials.paint("#4B5B64", 0.48, 0.52))
	lm.use("DarkSteel", LandmarkMaterials.paint("#333F46", 0.54, 0.55))
	lm.use("Stone", LandmarkPaKit.lutetian("#D5C9AE", 3.2))
	lm.use("Deck", LandmarkMaterials.pbr("asphalt", "#3D4044", 4.0))
	lm.use("Pave", LandmarkMaterials.pbr("stone", "#A6A092", 3.0))
	lm.use("Bronze", LandmarkPaKit.bronze("#424A40"))
	lm.use("Gilt", LandmarkMaterials.gold())
	lm.use("Lamp", LandmarkMaterials.lit("#FFE2A6", 1.35))
	_lower_deck_and_arches(lm, deck_y)
	_central_island_belvedere(lm, deck_y, via_y)
	_metro_viaduct(lm, deck_y, via_y)
	BridgeCamber.apply(lm, HALF_L, deck_y, camber_m, tilt_m)
	lm.commit(model)
	var mid_y := deck_y + camber_m
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-68.0, 2.0, 18.0), Vector3(-68.0, mid_y + 4.0, 6.0), 62.0, 0.85, 55.0],
		[Vector3(0.0, 2.0, 20.0), Vector3(0.0, mid_y + 5.0, 4.0), 62.0, 0.95, 55.0],
		[Vector3(68.0, 2.0, 18.0), Vector3(68.0, mid_y + 4.0, 6.0), 62.0, 0.85, 55.0],
		[Vector3(-68.0, 2.0, -18.0), Vector3(-68.0, mid_y + 4.0, -6.0), 62.0, 0.85, 55.0],
		[Vector3(68.0, 2.0, -18.0), Vector3(68.0, mid_y + 4.0, -6.0), 62.0, 0.85, 55.0],
	])

static func _lower_deck_and_arches(lm: LandmarkMesh, deck_y: float) -> void:
	# Lower roadway & side pedestrian promenades
	lm.box("Deck", Vector3(0.0, deck_y - 0.25, 0.0), Vector3(SPAN_TOTAL, 0.65, HALF_W * 2.0 - 4.0))
	for sz in [-1.0, 1.0]:
		var fz := float(sz) * (HALF_W - 1.2)
		lm.box("Pave", Vector3(0.0, deck_y - 0.12, fz), Vector3(SPAN_TOTAL, 0.72, 2.4))
		var ez := float(sz) * (HALF_W + 0.08)
		lm.box("Steel", Vector3(0.0, deck_y - 0.35, ez), Vector3(SPAN_TOTAL, 1.0, 0.45))
		lm.box("DarkSteel", Vector3(0.0, deck_y + 1.15, ez), Vector3(SPAN_TOTAL, 0.22, 0.28))
		lm.box("Steel", Vector3(0.0, deck_y + 0.62, ez), Vector3(SPAN_TOTAL, 0.88, 0.14))
	# Two arms of steel cantilever arches flanking Île aux Cygnes (central masonry island x = -12..+12)
	var spans := [[-HALF_L + 3.0, -78.0], [-74.0, -14.0], [14.0, 62.0], [66.0, HALF_L - 3.0]]
	var y_crown := deck_y - 0.75
	var y_spring := maxf(1.2, deck_y - 5.8)
	for sp in spans:
		var x0 := float(sp[0])
		var x1 := float(sp[1])
		for z in [-HALF_W + 0.2, -5.2, 5.2, HALF_W - 0.2]:
			LandmarkPaKit.arch_rib(lm, "Steel", x0, x1, y_spring, y_crown, float(z), 10, 0.8, 0.55)
		for sz in [-1.0, 1.0]:
			var ez := float(sz) * (HALF_W - 0.05)
			for k in 6:
				var u := (float(k) + 0.5) / 6.0
				var sx := lerpf(x0 + 1.5, x1 - 1.5, u)
				var ay := y_spring + sin(PI * u) * (y_crown - y_spring)
				var sh := (deck_y - 0.6) - ay
				if sh > 0.35:
					lm.box("DarkSteel", Vector3(sx, ay + sh * 0.5, ez), Vector3(0.32, sh, 0.24))
	# River piers & shore abutments with Art Nouveau relief escutcheons
	var pier_h := maxf(deck_y + 0.4, 2.0)
	for px in [-HALF_L + 2.0, -76.0, 64.0, HALF_L - 2.0]:
		lm.box("Stone", Vector3(float(px), -1.2 + pier_h * 0.5, 0.0), Vector3(4.2, pier_h, HALF_W * 2.0 + 3.2))
		for sz in [-1.0, 1.0]:
			var cz := float(sz) * (HALF_W + 1.8)
			lm.frustum("Stone", Vector3(float(px), -1.2, cz), 2.3, 1.8, pier_h, 6)
			lm.box("Bronze", Vector3(float(px), deck_y - 1.2, cz + float(sz) * 1.2), Vector3(1.6, 2.8, 0.4))
			LandmarkPaKit.paris_lamp(lm, "DarkSteel", "Lamp",
				Vector3(float(px), deck_y + 1.2, float(sz) * (HALF_W + 0.15)), 4.1)

static func _central_island_belvedere(lm: LandmarkMesh, deck_y: float, via_y: float) -> void:
	# Monumental stone central pier sitting on Île aux Cygnes + triumphal stone arch for Métro 6
	var h := deck_y + 1.2
	lm.box("Stone", Vector3(0.0, -1.2 + h * 0.5, 0.0), Vector3(26.0, h, HALF_W * 2.0 + 6.0))
	# Twin monumental stone portal piers supporting the viaduct over the island
	for sz in [-1.0, 1.0]:
		lm.box("Stone", Vector3(0.0, deck_y + (via_y - deck_y) * 0.5, float(sz) * 4.9),
			Vector3(14.0, via_y - deck_y + 0.6, 2.2))
	lm.box("Stone", Vector3(0.0, via_y + 0.6, 0.0), Vector3(15.2, 1.8, 12.2))
	# Downstream semicircular belvedere terrace & "La France renaissante" equestrian statue
	lm.frustum("Stone", Vector3(0.0, -1.2, HALF_W + 4.8), 6.2, 6.2, h, 14)
	lm.box("Stone", Vector3(0.0, deck_y + 1.8, HALF_W + 6.4), Vector3(3.2, 3.6, 4.4))
	LandmarkPaKit.equestrian(lm, "Bronze", Vector3(0.0, deck_y + 3.6, HALF_W + 6.4), 0.95, 0.0, false)

static func _metro_viaduct(lm: LandmarkMesh, deck_y: float, via_y: float) -> void:
	# Signature colonnaded central steel viaduct carrying Métro Line 6 (7.8 m wide)
	lm.box("Steel", Vector3(0.0, via_y, 0.0), Vector3(SPAN_TOTAL, 1.45, 7.8))
	for sz in [-1.0, 1.0]:
		lm.box("DarkSteel", Vector3(0.0, via_y + 1.25, float(sz) * 3.85), Vector3(SPAN_TOTAL, 1.1, 0.24))
	# Paired colonnade of riveted cast-iron columns with decorative curved brackets every 7.5 m
	var col_h := via_y - deck_y - 0.7
	var n_bays := 28
	for i in n_bays:
		var x := lerpf(-HALF_L + 6.0, HALF_L - 6.0, float(i) / float(n_bays - 1))
		if absf(x) < 11.0:
			continue
		for sz in [-1.0, 1.0]:
			var cz := float(sz) * 3.55
			lm.frustum("DarkSteel", Vector3(x, deck_y, cz), 0.34, 0.28, col_h, 8)
			lm.box("Steel", Vector3(x, via_y - 0.95, cz), Vector3(0.85, 0.45, 0.85))
			# Decorative spandrel brace
			lm.beam("Steel", Vector3(x, via_y - 1.9, cz), Vector3(x + 1.6, via_y - 0.7, cz), 0.18, 0.16)
			lm.beam("Steel", Vector3(x, via_y - 1.9, cz), Vector3(x - 1.6, via_y - 0.7, cz), 0.18, 0.16)
		# Overhead traction portal & warm lamp every 4th bay (reaches 20.5 m)
		if i % 4 == 0:
			for sz in [-1.0, 1.0]:
				lm.frustum("DarkSteel", Vector3(x, via_y + 0.7, float(sz) * 3.85), 0.16, 0.12, 3.3, 6)
			lm.box("DarkSteel", Vector3(x, via_y + 3.85, 0.0), Vector3(0.24, 0.24, 7.9))
			lm.frustum("Lamp", Vector3(x, deck_y + col_h - 0.45, 0.0), 0.24, 0.28, 0.36, 8)
