class_name LandmarkLnWestminsterBridge
extends RefCounted

## Westminster Bridge (Thomas Page & Charles Barry, 1862; OSM ways 216998718, 920237496).
## 250 m overall, 26 m wide, seven elliptical cast-iron arches painted Parliament green
## (matching the House of Commons leather benches) with gilt trefoil Gothic spandrel tracery,
## Cornish granite river piers with cutwaters, Gothic parapets, and ornate Victorian globe lamps.
## Built along +X with y = 0 at Thames water datum (`base: sea`), deck at 9.2 m, lamp tops 14.0 m.

const SPAN_TOTAL := 250.0
const HALF_L := 125.0
const HALF_W := 13.0
const DECK_Y := 9.2
const SPANS := [31.1, 36.5, 38.4, 40.2, 38.4, 36.5, 31.1]

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Green", LandmarkMaterials.paint("#1F5A3E", 0.48, 0.35))
	lm.use("DarkGreen", LandmarkMaterials.paint("#143B28", 0.55, 0.4))
	lm.use("Granite", LandmarkLnKit.granite("#827E78", 3.5))
	lm.use("Deck", LandmarkMaterials.pbr("asphalt", "#3B3D40", 4.0))
	lm.use("Pave", LandmarkMaterials.pbr("stone", "#9E9A90", 3.0))
	lm.use("Gilt", LandmarkMaterials.gold())
	lm.use("Lamp", LandmarkMaterials.lit("#FFE0A8", 1.3))
	_deck_and_parapets(lm)
	_arches_and_piers(lm)
	lm.commit(model)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(-60.0, 2.0, 18.0), Vector3(-60.0, 8.5, 11.0), 60.0, 0.8, 45.0],
		[Vector3(0.0, 2.0, 18.0), Vector3(0.0, 8.5, 11.0), 60.0, 0.85, 45.0],
		[Vector3(60.0, 2.0, 18.0), Vector3(60.0, 8.5, 11.0), 60.0, 0.8, 45.0],
		[Vector3(-60.0, 2.0, -18.0), Vector3(-60.0, 8.5, -11.0), 60.0, 0.8, 45.0],
		[Vector3(0.0, 2.0, -18.0), Vector3(0.0, 8.5, -11.0), 60.0, 0.85, 45.0],
		[Vector3(60.0, 2.0, -18.0), Vector3(60.0, 8.5, -11.0), 60.0, 0.8, 45.0],
	])

static func _deck_and_parapets(lm: LandmarkMesh) -> void:
	# Roadway & raised footways
	lm.box("Deck", Vector3(0.0, DECK_Y, 0.0), Vector3(SPAN_TOTAL, 0.65, HALF_W * 2.0 - 4.4))
	for sz in [-1.0, 1.0]:
		var fz := float(sz) * (HALF_W - 1.3)
		lm.box("Pave", Vector3(0.0, DECK_Y + 0.15, fz), Vector3(SPAN_TOTAL, 0.7, 2.6))
		# Outer green fascia cornice with gilt bead line
		var ez := float(sz) * (HALF_W + 0.1)
		lm.box("Green", Vector3(0.0, DECK_Y - 0.15, ez), Vector3(SPAN_TOTAL, 1.15, 0.45))
		lm.box("Gilt", Vector3(0.0, DECK_Y + 0.35, ez + float(sz) * 0.24), Vector3(SPAN_TOTAL, 0.16, 0.12))
		# Gothic cast-iron parapet rail + balusters
		lm.box("DarkGreen", Vector3(0.0, DECK_Y + 1.55, ez), Vector3(SPAN_TOTAL, 0.22, 0.32))
		lm.box("Green", Vector3(0.0, DECK_Y + 0.95, ez), Vector3(SPAN_TOTAL, 0.95, 0.16))

static func _arches_and_piers(lm: LandmarkMesh) -> void:
	var sum := 0.0
	for s in SPANS:
		sum += float(s)
	var scale := SPAN_TOTAL / sum
	var x := -HALF_L
	for i in SPANS.size():
		var w := float(SPANS[i]) * scale
		var x0 := x + 1.8
		var x1 := x + w - 1.8
		var y_crown := DECK_Y - 0.75
		var y_spring := 2.4 + (0.6 if i == 3 else (0.3 if i == 2 or i == 4 else 0.0))
		# Outer & inner elliptical cast-iron arch ribs
		for z in [-HALF_W + 0.15, -HALF_W * 0.45, HALF_W * 0.45, HALF_W - 0.15]:
			LandmarkLnKit.arch_rib(lm, "Green", x0, x1, y_spring, y_crown, float(z), 12, 0.75, 0.55)
		# Spandrel Gothic vertical struts & gilt rosettes on both river faces
		for sz in [-1.0, 1.0]:
			var ez := float(sz) * (HALF_W - 0.05)
			for k in 7:
				var u := (float(k) + 0.5) / 7.0
				var sx := lerpf(x0 + 1.2, x1 - 1.2, u)
				var ang := PI * u
				var ay := y_spring + sin(ang) * (y_crown - y_spring)
				var sh := (DECK_Y - 0.55) - ay
				if sh > 0.35:
					lm.box("DarkGreen", Vector3(sx, ay + sh * 0.5, ez), Vector3(0.28, sh, 0.24))
					if sh > 1.4:
						lm.box("Gilt", Vector3(sx, ay + sh * 0.55, ez + float(sz) * 0.14), Vector3(0.45, 0.45, 0.12))
		# River pier at x + w (except after final span)
		if i < SPANS.size() - 1:
			_pier(lm, x + w)
		x += w
	# Shore abutments at both ends
	for sx in [-1.0, 1.0]:
		lm.box("Granite", Vector3(float(sx) * (HALF_L - 1.5), DECK_Y * 0.5, 0.0), Vector3(4.5, DECK_Y + 0.6, HALF_W * 2.0 + 3.0))
		for sz in [-1.0, 1.0]:
			LandmarkLnKit.globe_lamp(lm, "DarkGreen", "Lamp",
				Vector3(float(sx) * (HALF_L - 2.0), DECK_Y + 1.5, float(sz) * (HALF_W + 0.1)), 3.3)

static func _pier(lm: LandmarkMesh, px: float) -> void:
	lm.box("Granite", Vector3(px, 3.2, 0.0), Vector3(3.6, 8.4, HALF_W * 2.0 + 2.4))
	for sz in [-1.0, 1.0]:
		var cz := float(sz) * (HALF_W + 1.6)
		# Pointed cutwater & fluted octagonal turret pier cap
		lm.frustum("Granite", Vector3(px, -1.0, cz), 2.2, 1.7, 8.6, 6)
		lm.box("Green", Vector3(px, DECK_Y - 0.1, cz), Vector3(3.2, 2.2, 2.2))
		lm.box("Gilt", Vector3(px, DECK_Y + 0.4, cz + float(sz) * 1.15), Vector3(1.1, 1.1, 0.18))
		# Victorian ornate globe lamp standard on each pier (top = 14.0 m)
		LandmarkLnKit.globe_lamp(lm, "DarkGreen", "Lamp", Vector3(px, DECK_Y + 1.4, float(sz) * (HALF_W + 0.15)), 3.4)
