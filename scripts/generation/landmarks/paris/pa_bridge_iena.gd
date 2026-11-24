class_name LandmarkPaBridgeIena
extends RefCounted

## Pont d'Iéna (Corneille Lamandé, 1814; widened 1937; 370 m on the Trocadéro–Eiffel axis).
## 155 m long, 35 m wide dressed-limestone Napoleonic bridge of five equal 28 m elliptical arches,
## carved Imperial Eagles on the four pier spandrels, four monumental equestrian warrior statues
## (Gallic, Roman, Arab, Greek) on abutment pedestals, and dark-green Parisian balustrade lamps.
## Built along +X with y = 0 at Seine datum (`base: sea`), deck 8.0 m, equestrian tops 13.5 m.

const SPAN_TOTAL := 178.0
const ARCH_SPAN_TOTAL := 155.0
const HALF_L := SPAN_TOTAL * 0.5
const HALF_ARCH := ARCH_SPAN_TOTAL * 0.5
const HALF_W := 17.5
const DECK_Y := 8.0

static func build(model: Node3D) -> void:
	build_fitted(model, DECK_Y, 0.0, 0.0)

static func build_fitted(model: Node3D, deck_m: float, tilt_m: float = 0.0, rise_m: float = 0.0) -> void:
	var deck_y := maxf(deck_m, 2.5)
	var most := maxf(BridgeSpec.DECK_GRADE * HALF_L - BridgeCamber.RAMP_STEEPEST * absf(tilt_m), 0.0) \
		/ BridgeCamber.LIFT_STEEPEST
	var camber_m := clampf(maxf(DECK_Y - deck_y, rise_m), 0.0, most)
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkPaKit.lutetian("#DDD1B5", 3.4))
	lm.use("Ashlar", LandmarkPaKit.ashlar("#C1B498", 3.2))
	lm.use("Deck", LandmarkMaterials.pbr("asphalt", "#3D4044", 4.0))
	lm.use("Pave", LandmarkMaterials.pbr("stone", "#B4AC9D", 3.0))
	lm.use("Iron", LandmarkPaKit.paris_green("#203D31"))
	lm.use("Lamp", LandmarkMaterials.lit("#FFE4AE", 1.35))
	_deck_and_arches(lm, deck_y)
	_abutments_and_statues(lm, deck_y)
	BridgeCamber.apply(lm, HALF_L, deck_y, camber_m, tilt_m)
	lm.commit(model)
	var mid_y := deck_y + camber_m
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-42.0, 2.0, 24.0), Vector3(-42.0, mid_y - 0.6, 17.0), 62.0, 0.85, 48.0],
		[Vector3(42.0, 2.0, 24.0), Vector3(42.0, mid_y - 0.6, 17.0), 62.0, 0.85, 48.0],
		[Vector3(-42.0, 2.0, -24.0), Vector3(-42.0, mid_y - 0.6, -17.0), 62.0, 0.85, 48.0],
		[Vector3(42.0, 2.0, -24.0), Vector3(42.0, mid_y - 0.6, -17.0), 62.0, 0.85, 48.0],
	])

static func _deck_and_arches(lm: LandmarkMesh, deck_y: float) -> void:
	lm.box("Deck", Vector3(0.0, deck_y - 0.25, 0.0), Vector3(SPAN_TOTAL, 0.65, HALF_W * 2.0 - 7.0))
	for sz in [-1.0, 1.0]:
		var fz := float(sz) * (HALF_W - 1.75)
		lm.box("Pave", Vector3(0.0, deck_y - 0.14, fz), Vector3(SPAN_TOTAL, 0.72, 3.5))
		var ez := float(sz) * (HALF_W + 0.05)
		# Dressed cornice & solid limestone parapet wall
		lm.box("Stone", Vector3(0.0, deck_y - 0.35, ez), Vector3(SPAN_TOTAL, 1.05, 0.65))
		lm.box("Stone", Vector3(0.0, deck_y + 0.62, ez), Vector3(SPAN_TOTAL, 1.05, 0.48))
		lm.box("Ashlar", Vector3(0.0, deck_y + 1.22, ez), Vector3(SPAN_TOTAL, 0.18, 0.62))
	# Five equal 28 m limestone elliptical arches (31 m centre-to-centre, 3 m piers)
	var span := 31.0
	var y_crown := deck_y - 0.8
	var y_spring := maxf(1.2, y_crown - 3.6)
	var pier_h := maxf(deck_y + 0.3, 2.0)
	for i in 5:
		var x0 := -HALF_ARCH + float(i) * span + 1.5
		var x1 := x0 + 28.0
		for z in [-HALF_W + 0.25, -8.5, 0.0, 8.5, HALF_W - 0.25]:
			LandmarkPaKit.arch_rib(lm, "Stone", x0, x1, y_spring, y_crown, float(z), 10, 1.15, 0.9)
		# Solid stone spandrel wall fills above arch haunches
		for sz in [-1.0, 1.0]:
			var ez := float(sz) * (HALF_W - 0.1)
			for side in [-1.0, 1.0]:
				var sx := (x0 + x1) * 0.5 + float(side) * 10.2
				lm.box("Stone", Vector3(sx, (y_spring + y_crown) * 0.5 + 0.35, ez), Vector3(7.2, 2.6, 0.7))
		if i < 4:
			var px := -HALF_ARCH + float(i + 1) * span
			lm.box("Ashlar", Vector3(px, -1.2 + pier_h * 0.5, 0.0), Vector3(3.2, pier_h, HALF_W * 2.0 + 1.6))
			for sz in [-1.0, 1.0]:
				var cz := float(sz) * (HALF_W + 0.95)
				lm.frustum("Ashlar", Vector3(px, -1.2, cz), 1.85, 1.55, pier_h, 6)
				# Carved Imperial Eagle relief tablet on each pier face
				lm.box("Stone", Vector3(px, deck_y - 1.9, cz + float(sz) * 0.85), Vector3(2.4, 2.2, 0.36))
				LandmarkPaKit.paris_lamp(lm, "Iron", "Lamp", Vector3(px, deck_y + 1.25, float(sz) * (HALF_W + 0.05)), 4.1)

static func _abutments_and_statues(lm: LandmarkMesh, deck_y: float) -> void:
	var abut_h := maxf(deck_y + 0.3, 2.0)
	var abut_l := HALF_L - HALF_ARCH + 2.5
	for sx in [-1.0, 1.0]:
		var ax := float(sx) * (HALF_ARCH + abut_l * 0.5 - 2.5)
		lm.box("Ashlar", Vector3(ax, -1.2 + abut_h * 0.5, 0.0), Vector3(abut_l, abut_h, HALF_W * 2.0 + 2.4))
		var st_x := float(sx) * (HALF_ARCH - 1.5)
		for sz in [-1.0, 1.0]:
			var pz := float(sz) * (HALF_W + 0.45)
			# Monumental stone pedestal & equestrian warrior statue at each of the four corners (top 13.5 m)
			lm.box("Stone", Vector3(st_x, deck_y + 1.25, pz), Vector3(4.2, 2.5, 2.6))
			LandmarkPaKit.equestrian(lm, "Stone", Vector3(st_x, deck_y + 2.5, pz), 0.78,
				PI * 0.5 if sx < 0 else -PI * 0.5, false)
			LandmarkPaKit.paris_lamp(lm, "Iron", "Lamp",
				Vector3(st_x - float(sx) * 3.8, deck_y + 1.25, float(sz) * (HALF_W + 0.05)), 4.1)
