class_name LandmarkSgBridges
extends RefCounted

## Bespoke historic Singapore River bridges (SG-4):
## - `cavenagh_bridge` (79 m span, way 534684103): 1869 white wrought-iron Ordish-Lefeuvre
##   stayed-suspension footbridge with iconic cast-iron portal towers & crest plaques.
## - `anderson_bridge` (70 m span, way 29377119): 1910 three white steel bowstring arches
##   with rusticated neoclassical stone abutment portals & arched walkways.
## - `elgin_bridge` (66 m span, way 474832236): 1929 three slender white concrete-encased
##   bowstring arches with vertical hangers & ornate bronze lamp standards.

static func cavenagh_bridge(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("WhiteIron", LandmarkMaterials.pbr("sheet_metal", "#F2F1EC", 2.0, 0.30, 0.72))
	lm.use("Deck", LandmarkMaterials.pbr("concrete", "#B8B2A6", 3.0))
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#C8C2B6", 3.0))
	lm.use("Lamp", LandmarkMaterials.lit("#FFE2A0", 2.2))

	var deck_y := 3.6
	# Timber/stone pedestrian deck spanning 79 m (-39.5..+39.5 m) & stone abutments.
	lm.box("Deck", Vector3(0.0, deck_y, 0.0), Vector3(79.0, 0.7, 9.2))
	for sx: float in [-39.5, 39.5]:
		lm.box("Stone", Vector3(sx, 0.0, 0.0), Vector3(7.0, 7.2, 11.2))
	# Pair of iconic white cast-iron portal towers at x = ±30.5 m (reaches 12.0 m).
	for sx: float in [-30.5, 30.5]:
		for sz: float in [-4.5, 4.5]:
			lm.box("WhiteIron", Vector3(sx, deck_y + 4.0, sz), Vector3(1.1, 8.2, 1.1))
			lm.frustum("Lamp", Vector3(sx, deck_y + 8.1, sz), 0.35, 0.25, 0.45, 8)
		# Ornate arch portal crossbeam with royal crest plaque.
		lm.box("WhiteIron", Vector3(sx, deck_y + 7.2, 0.0), Vector3(0.85, 1.2, 9.6))
		lm.box("WhiteIron", Vector3(sx, deck_y + 8.1, 0.0), Vector3(0.6, 0.9, 2.2))
	# Ordish-Lefeuvre diagonal rigid stays + suspension chains + white side balustrades.
	for sz: float in [-4.5, 4.5]:
		lm.box("WhiteIron", Vector3(0.0, deck_y + 0.85, sz), Vector3(78.0, 1.1, 0.22))
		for sx: float in [-30.5, 30.5]:
			var top := Vector3(sx, deck_y + 7.4, sz)
			for target_x: float in [0.0, sx * 0.5, sx * 0.25]:
				lm.beam("WhiteIron", top, Vector3(target_x, deck_y + 0.4, sz), 0.16, 0.16)
			lm.beam("WhiteIron", top, Vector3(sx * 1.28, deck_y + 0.2, sz), 0.20, 0.20)
	lm.commit(model)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(0.0, 4.0, 14.0), Vector3(0.0, 7.0, 0.0), 68.0, 1.2],
	])

static func anderson_bridge(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("WhiteSteel", LandmarkMaterials.pbr("sheet_metal", "#F2F0EA", 2.0, 0.30, 0.72))
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#D8D2C6", 3.0))
	lm.use("Deck", LandmarkMaterials.pbr("concrete", "#6A6C70", 3.0))
	lm.use("Lamp", LandmarkMaterials.lit("#FFE2A2", 2.2))

	var deck_y := 4.4
	# 70 m roadway deck (width 23 m) & monumental rusticated neoclassical stone portal piers at both ends.
	lm.box("Deck", Vector3(0.0, deck_y, 0.0), Vector3(70.0, 1.1, 22.8))
	for sx: float in [-34.0, 34.0]:
		lm.box("Stone", Vector3(sx, 2.4, 0.0), Vector3(6.5, 11.0, 24.4))
		# Twin neoclassical archway portals flanking the roadway.
		for sz: float in [-10.8, 0.0, 10.8]:
			lm.box("Stone", Vector3(sx, deck_y + 4.4, sz), Vector3(3.4, 8.8, 2.4))
			lm.frustum("Lamp", Vector3(sx, deck_y + 8.9, sz), 0.45, 0.32, 0.6, 8)
		lm.box("Stone", Vector3(sx, deck_y + 8.6, 0.0), Vector3(2.8, 1.4, 24.0))

	# Three parallel white steel bowstring arches (z = -10.8, 0.0, +10.8 m, rise 9.4 m -> 14.0 m top).
	for sz: float in [-10.8, 0.0, 10.8]:
		var segs := 18
		var prev := Vector3(-31.0, deck_y + 0.5, sz)
		for i in range(1, segs + 1):
			var t := float(i) / float(segs)
			var ax := lerpf(-31.0, 31.0, t)
			var ay := deck_y + 0.5 + 8.8 * sin(t * PI)
			var cur := Vector3(ax, ay, sz)
			lm.beam("WhiteSteel", prev, cur, 0.85, 0.95)
			if i < segs and i % 2 == 0:
				lm.beam("WhiteSteel", Vector3(ax, deck_y + 0.4, sz), cur, 0.34, 0.34)
			prev = cur
		# Overhead lateral wind-bracing struts between the three arches.
	for bx: float in [-14.0, 0.0, 14.0]:
		var t := (bx + 31.0) / 62.0
		var ay := deck_y + 0.5 + 8.8 * sin(t * PI)
		lm.beam("WhiteSteel", Vector3(bx, ay, -10.8), Vector3(bx, ay, 10.8), 0.45, 0.45)
	lm.commit(model)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(0.0, 4.5, 22.0), Vector3(0.0, 9.5, 0.0), 68.0, 1.3],
	])

static func elgin_bridge(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("White", LandmarkMaterials.pbr("concrete", "#EFECE4", 3.0))
	lm.use("Deck", LandmarkMaterials.pbr("concrete", "#686A6E", 3.0))
	lm.use("Bronze", LandmarkMaterials.pbr("sheet_metal", "#4C4438", 2.0, 0.35, 0.75))
	lm.use("Lamp", LandmarkMaterials.lit("#FFE2A0", 2.4))

	var deck_y := 4.4
	# 66 m wide roadway deck (25 m wide) & stone abutments.
	lm.box("Deck", Vector3(0.0, deck_y, 0.0), Vector3(66.0, 1.0, 24.8))
	for sx: float in [-33.0, 33.0]:
		lm.box("White", Vector3(sx, 1.5, 0.0), Vector3(6.0, 8.0, 25.8))
	# Three slender white concrete-encased bowstring arches with vertical hangers (reaches 12.0 m).
	for sz: float in [-11.8, 0.0, 11.8]:
		var segs := 16
		var prev := Vector3(-28.0, deck_y + 0.4, sz)
		for i in range(1, segs + 1):
			var t := float(i) / float(segs)
			var ax := lerpf(-28.0, 28.0, t)
			var ay := deck_y + 0.4 + 7.2 * sin(t * PI)
			var cur := Vector3(ax, ay, sz)
			lm.beam("White", prev, cur, 0.72, 0.78)
			if i < segs and i % 2 == 0:
				lm.beam("White", Vector3(ax, deck_y + 0.3, sz), cur, 0.24, 0.24)
			prev = cur
	# Ornate Italian bronze lamp standards along both parapets.
	for sx: float in [-22.0, 0.0, 22.0]:
		for sz: float in [-12.2, 12.2]:
			lm.beam("Bronze", Vector3(sx, deck_y + 0.5, sz), Vector3(sx, deck_y + 4.4, sz), 0.18, 0.18)
			lm.frustum("Lamp", Vector3(sx, deck_y + 4.4, sz), 0.36, 0.28, 0.55, 8)
	lm.commit(model)
