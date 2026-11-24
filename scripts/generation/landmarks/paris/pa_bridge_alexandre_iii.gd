class_name LandmarkPaBridgeAlexandreIII
extends RefCounted

## Pont Alexandre III (Resal, Alby, Cassien-Bernard & Cousin, 1900; 1,830 m from Trocadéro).
## Paris's most ornate Beaux-Arts bridge: single sweeping 107.5 m low steel arch (40 m wide),
## gilded bronze garlands & river-nymph centrepieces, four 17 m limestone abutment pylons
## crowned by gilded winged Pegasus / Fame statues, and 32 ornate black-and-gold Art Nouveau
## four-globe candelabra. Built along +X, y = 0 at Seine datum, deck 8.0 m, Pegasus tips 24.5 m.

const SPAN_TOTAL := 152.0
const ARCH_SPAN := 107.5
const HALF_L := SPAN_TOTAL * 0.5
const HALF_W := 20.0
const DECK_Y := 8.0

static func build(model: Node3D) -> void:
	build_fitted(model, DECK_Y, 0.0, 0.0)

static func build_fitted(model: Node3D, deck_m: float, tilt_m: float = 0.0, rise_m: float = 0.0) -> void:
	var deck_y := maxf(deck_m, 2.5)
	var most := maxf(BridgeSpec.DECK_GRADE * HALF_L - BridgeCamber.RAMP_STEEPEST * absf(tilt_m), 0.0) \
		/ BridgeCamber.LIFT_STEEPEST
	var camber_m := clampf(maxf(DECK_Y - deck_y, rise_m), 0.0, most)
	var lm := LandmarkMesh.new()
	lm.use("Steel", LandmarkMaterials.paint("#5C666E", 0.46, 0.55))
	lm.use("Stone", LandmarkPaKit.lutetian("#DFD4BA", 3.4))
	lm.use("Deck", LandmarkMaterials.pbr("asphalt", "#3D4044", 4.0))
	lm.use("Pave", LandmarkMaterials.pbr("stone", "#B2AA9B", 3.0))
	lm.use("Iron", LandmarkPaKit.bronze("#232726"))
	lm.use("Gilt", LandmarkMaterials.gold())
	lm.use("Lamp", LandmarkMaterials.lit("#FFE4AA", 1.55))
	_deck_and_arch(lm, deck_y)
	_pylons_and_pegasus(lm, deck_y)
	_candelabra(lm, deck_y)
	BridgeCamber.apply(lm, HALF_L, deck_y, camber_m, tilt_m)
	lm.commit(model)
	var mid_y := deck_y + camber_m
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-58.0, deck_y + 2.0, 26.0), Vector3(-58.0, deck_y + 15.0, 20.0), 56.0, 1.0, 48.0],
		[Vector3(58.0, deck_y + 2.0, 26.0), Vector3(58.0, deck_y + 15.0, 20.0), 56.0, 1.0, 48.0],
		[Vector3(-58.0, deck_y + 2.0, -26.0), Vector3(-58.0, deck_y + 15.0, -20.0), 56.0, 1.0, 48.0],
		[Vector3(58.0, deck_y + 2.0, -26.0), Vector3(58.0, deck_y + 15.0, -20.0), 56.0, 1.0, 48.0],
		[Vector3(0.0, 2.0, 28.0), Vector3(0.0, mid_y - 0.5, 20.0), 68.0, 0.9, 55.0],
		[Vector3(0.0, 2.0, -28.0), Vector3(0.0, mid_y - 0.5, -20.0), 68.0, 0.9, 55.0],
	])

static func _deck_and_arch(lm: LandmarkMesh, deck_y: float) -> void:
	lm.box("Deck", Vector3(0.0, deck_y - 0.25, 0.0), Vector3(SPAN_TOTAL, 0.65, HALF_W * 2.0 - 8.0))
	for sz in [-1.0, 1.0]:
		var fz := float(sz) * (HALF_W - 2.0)
		lm.box("Pave", Vector3(0.0, deck_y - 0.14, fz), Vector3(SPAN_TOTAL, 0.72, 4.0))
		var ez := float(sz) * (HALF_W + 0.08)
		lm.box("Steel", Vector3(0.0, deck_y - 0.35, ez), Vector3(SPAN_TOTAL, 1.1, 0.5))
		lm.box("Gilt", Vector3(0.0, deck_y + 0.15, ez + float(sz) * 0.26), Vector3(ARCH_SPAN, 0.26, 0.16))
		lm.box("Iron", Vector3(0.0, deck_y + 1.18, ez), Vector3(SPAN_TOTAL, 0.24, 0.36))
		lm.box("Steel", Vector3(0.0, deck_y + 0.62, ez), Vector3(SPAN_TOTAL, 0.88, 0.18))
	# Sweeping ultra-low single steel arch (107.5 m clear span, 6.3 m rise)
	var x0 := -ARCH_SPAN * 0.5
	var x1 := ARCH_SPAN * 0.5
	var y_crown := deck_y - 0.75
	var y_spring := maxf(1.2, y_crown - 6.0)
	for z in [-HALF_W + 0.2, -12.0, -4.0, 4.0, 12.0, HALF_W - 0.2]:
		LandmarkPaKit.arch_rib(lm, "Steel", x0, x1, y_spring, y_crown, float(z), 18, 0.95, 0.6)
	# Ornate gilded bronze spandrel garlands & central nymph escutcheons on both river faces
	for sz in [-1.0, 1.0]:
		var ez := float(sz) * (HALF_W + 0.18)
		lm.box("Gilt", Vector3(0.0, y_crown - 0.15, ez + float(sz) * 0.22), Vector3(5.6, 2.2, 0.55))
		for k in 14:
			var u := (float(k) + 0.5) / 14.0
			var sx := lerpf(x0 + 3.0, x1 - 3.0, u)
			var ay := y_spring + sin(PI * u) * (y_crown - y_spring)
			var sh := (deck_y - 0.65) - ay
			if sh > 0.35:
				lm.box("Steel", Vector3(sx, ay + sh * 0.5, float(sz) * (HALF_W - 0.05)), Vector3(0.32, sh, 0.24))
				if sh > 1.1:
					lm.box("Gilt", Vector3(sx, ay + sh * 0.55, ez), Vector3(0.85, 0.65, 0.18))

static func _pylons_and_pegasus(lm: LandmarkMesh, deck_y: float) -> void:
	var abut_h := maxf(deck_y + 0.5, 2.0)
	for sx in [-1.0, 1.0]:
		var ax := float(sx) * (ARCH_SPAN * 0.5 + 11.0)
		lm.box("Stone", Vector3(ax, -1.2 + abut_h * 0.5, 0.0), Vector3(22.0, abut_h, HALF_W * 2.0 + 4.0))
		# Monumental 17 m Beaux-Arts pylons at all four bridge corners
		var px := float(sx) * (ARCH_SPAN * 0.5 + 4.5)
		for sz in [-1.0, 1.0]:
			var pz := float(sz) * (HALF_W + 0.8)
			# Rusticated pedestal + fluted shaft + sculpted cornice (rises 12.2 m above deck)
			lm.box("Stone", Vector3(px, deck_y + 1.8, pz), Vector3(5.6, 3.6, 5.6))
			lm.box("Stone", Vector3(px, deck_y + 7.2, pz), Vector3(4.2, 7.6, 4.2))
			lm.box("Stone", Vector3(px, deck_y + 11.4, pz), Vector3(5.2, 1.2, 5.2))
			lm.box("Gilt", Vector3(px, deck_y + 7.5, pz + float(sz) * 2.15), Vector3(1.6, 2.8, 0.22))
			# Seated stone allegorical statue at pylon foot
			lm.box("Stone", Vector3(px + float(sx) * 3.4, deck_y + 1.6, pz), Vector3(1.8, 3.2, 1.8))
			# Crowning gilded winged Pegasus & Fame sculpture (tips reach deck_y + 16.5 = 24.5 m!)
			var facing := PI * 0.5 if sx > 0 else -PI * 0.5
			LandmarkPaKit.equestrian(lm, "Gilt", Vector3(px, deck_y + 12.0, pz), 1.0, facing, true)

static func _candelabra(lm: LandmarkMesh, deck_y: float) -> void:
	for sz in [-1.0, 1.0]:
		var ez := float(sz) * (HALF_W + 0.1)
		for i in 11:
			var lx := lerpf(-ARCH_SPAN * 0.48, ARCH_SPAN * 0.48, float(i) / 10.0)
			LandmarkPaKit.candelabrum(lm, "Iron", "Lamp", Vector3(lx, deck_y + 1.1, ez), 5.2)
