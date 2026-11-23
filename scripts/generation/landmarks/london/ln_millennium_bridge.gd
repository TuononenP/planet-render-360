class_name LandmarkLnMillenniumBridge
extends RefCounted

## London Millennium Footbridge (Foster + Partners, Anthony Caro & Arup, 2000;
## OSM ways 7225360, 7225371). 325 m (81 / 144 / 108 m) lateral-suspension steel
## "blade of light" connecting St Paul's Cathedral to Tate Modern.
## Slim 4 m aluminium deck, two sculpted concrete-and-steel Y-arm river piers,
## eight lateral tension cables flanking the deck with transverse steel arms, and
## continuous white handrail LED ribbon at night. Built along +X (`base: sea`).

const SPAN_TOTAL := 325.0
const HALF_L := 162.5
const DECK_Y := 10.6
const PIER_X0 := -81.5
const PIER_X1 := 62.5
const TOP_H := 16.0

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Steel", LandmarkMaterials.paint("#D4DAE0", 0.35, 0.72))
	lm.use("Cable", LandmarkMaterials.paint("#A8B2BC", 0.4, 0.78))
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#C8C4BC", 3.2))
	lm.use("Deck", LandmarkMaterials.paint("#9EA6AE", 0.5, 0.55))
	lm.use("Lamp", LandmarkMaterials.lit("#F0F6FF", 1.5))
	_deck_and_arms(lm)
	_y_piers(lm)
	_lateral_cables(lm)
	lm.commit(model)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(PIER_X0, 4.0, 12.0), Vector3(PIER_X0, 12.0, 0.0), 50.0, 0.8, 36.0],
		[Vector3(PIER_X1, 4.0, 12.0), Vector3(PIER_X1, 12.0, 0.0), 50.0, 0.8, 36.0],
	])

static func _deck_y(x: float) -> float:
	# Gentle shallow arch rising slightly toward mid-river
	var u := clampf(x / HALF_L, -1.0, 1.0)
	return DECK_Y + (1.0 - u * u) * 1.4

static func _deck_and_arms(lm: LandmarkMesh) -> void:
	var segs := 36
	for i in segs:
		var x0 := lerpf(-HALF_L, HALF_L, float(i) / float(segs))
		var x1 := lerpf(-HALF_L, HALF_L, float(i + 1) / float(segs))
		var p0 := Vector3(x0, _deck_y(x0), 0.0)
		var p1 := Vector3(x1, _deck_y(x1), 0.0)
		lm.beam("Deck", p0, p1, 0.45, 4.0)
		for sz in [-1.0, 1.0]:
			var s := float(sz)
			lm.beam("Steel", p0 + Vector3(0.0, 1.05, s * 2.05), p1 + Vector3(0.0, 1.05, s * 2.05), 0.14, 0.14)
			lm.beam("Lamp", p0 + Vector3(0.0, 0.85, s * 2.0), p1 + Vector3(0.0, 0.85, s * 2.0), 0.14, 0.1)
		# Transverse steel arms every ~9 m carrying the lateral cables
		var xm := (x0 + x1) * 0.5
		var ym := _deck_y(xm)
		lm.box("Steel", Vector3(xm, ym - 0.18, 0.0), Vector3(0.38, 0.34, 8.2))

static func _y_piers(lm: LandmarkMesh) -> void:
	for px in [PIER_X0, PIER_X1]:
		var x := float(px)
		var dy := _deck_y(x)
		# Elliptical concrete river pier base
		lm.frustum("Concrete", Vector3(x, -1.5, 0.0), 2.8, 2.2, 7.5, 12)
		# Sculptural angled steel Y-arms flaring outward to saddle height (TOP_H)
		for sz in [-1.0, 1.0]:
			var s := float(sz)
			lm.beam("Steel", Vector3(x, 5.5, 0.0), Vector3(x, TOP_H, s * 4.4), 1.15, 0.95)
			lm.beam("Steel", Vector3(x, 5.5, 0.0), Vector3(x, dy - 0.3, s * 2.0), 0.75, 0.75)

static func _lateral_cables(lm: LandmarkMesh) -> void:
	# Three spans: [-HALF_L .. PIER_X0], [PIER_X0 .. PIER_X1], [PIER_X1 .. HALF_L]
	var spans := [[-HALF_L, PIER_X0, 1.6], [PIER_X0, PIER_X1, 2.6], [PIER_X1, HALF_L, 2.0]]
	for sp in spans:
		var x0: float = sp[0]
		var x1: float = sp[1]
		var sag: float = sp[2]
		var segs := 14
		for sz in [-1.0, 1.0]:
			var z := float(sz) * 4.1
			for i in segs:
				var u0 := float(i) / float(segs)
				var u1 := float(i + 1) / float(segs)
				var ax0 := lerpf(x0, x1, u0)
				var ax1 := lerpf(x0, x1, u1)
				var y0 := lerpf(TOP_H, TOP_H, u0) - 4.0 * sag * u0 * (1.0 - u0)
				var y1 := lerpf(TOP_H, TOP_H, u1) - 4.0 * sag * u1 * (1.0 - u1)
				if x0 == -HALF_L:
					y0 = lerpf(DECK_Y + 0.4, TOP_H, u0) - 2.0 * sag * u0 * (1.0 - u0)
					y1 = lerpf(DECK_Y + 0.4, TOP_H, u1) - 2.0 * sag * u1 * (1.0 - u1)
				elif x1 == HALF_L:
					y0 = lerpf(TOP_H, DECK_Y + 0.4, u0) - 2.0 * sag * u0 * (1.0 - u0)
					y1 = lerpf(TOP_H, DECK_Y + 0.4, u1) - 2.0 * sag * u1 * (1.0 - u1)
				lm.beam("Cable", Vector3(ax0, y0, z), Vector3(ax1, y1, z), 0.28, 0.28)
