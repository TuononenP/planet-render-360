class_name LandmarkBrMasonry
extends RefCounted

## Three stone bridges of the bridges batch in true metres, along +X:
## the Roman aqueduct over the Gardon (y = 0 at the river bed, bridge
## over land), and the single-arch crossings of Mostar and Venice
## (y = 0 at the water, LocationData `base: water`). Arches are solid
## masonry with their spandrels (LandmarkBrKit.arcade / extrude_xy).

## Pont du Gard: 275 m and 48.8 m high in three tiers of round arches in
## warm limestone: 6 river arches of 24 m on 6.4 m thick piers, 10 of the
## middle tier on 4.6 m thick piers, 35 small arches carrying the
## water channel under its cover slabs, the two banks rising as rock.
const PG_TOP_M := 48.8

static func pont_du_gard(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#D4BF98", 3.0))
	lm.use("Cap", LandmarkMaterials.pbr("stone", "#BDAA88", 3.0))
	lm.use("Rock", LandmarkMaterials.pbr("rock", "#8F8068", 4.0))
	LandmarkBrKit.arcade(lm, "Stone", LandmarkBrKit.pier_line(-71.0, 71.0, 6), -1.5, 22.0, 11.5, 1.0, 6.0, 3.2)
	var mid := LandmarkBrKit.pier_line(-118.35, 118.35, 10)
	for i in 10:
		var c := absf(mid[i] + mid[i + 1]) * 0.5
		var y0 := 22.0 if c < 71.0 else (3.0 if c < 95.0 else 12.0)
		LandmarkBrKit.arcade(lm, "Stone", PackedFloat32Array([mid[i], mid[i + 1]]), y0, 41.6, 30.5, 1.0, 4.6, 2.3)
	LandmarkBrKit.arcade(lm, "Stone", LandmarkBrKit.pier_line(-137.5, 137.5, 35), 41.6, 47.4, 44.0, 1.0, 3.3, 1.55, 8)
	lm.box("Cap", Vector3(0, 48.1, 0), Vector3(275.0, 1.4, 4.0))
	# Rising banks under the outer arches.
	for s in [-1.0, 1.0]:
		var poly := PackedVector2Array()
		for p in [Vector2(71, -2), Vector2(150, -2), Vector2(150, 46), Vector2(137.5, 41.6),
				Vector2(118.35, 25), Vector2(94.7, 9), Vector2(71, -1.5)]:
			poly.append(Vector2(s * p.x, p.y))
		LandmarkBrKit.extrude_xy(lm, "Rock", poly, -7.0, 7.0)
	lm.commit(model)

## Stari Most, Mostar: the 28.7 m single arch of white tenelija stone
## springing 8 m over the Neretva and rising to 19.8 m, 4 m wide, the
## humped cobbled roadway climbing to a 21 m crest, the two bank towers
## (round Halebija under a stone cone, square Tara under a hip roof).
const SM_SPAN := 28.7
const SM_SPRING_M := 8.0
const SM_RISE_M := 11.8
const SM_CREST_M := 21.0

static func stari_most(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#E3DDCE", 3.0))
	lm.use("Paving", LandmarkMaterials.pbr("pavement", "#B8B0A2", 2.0))
	lm.use("Roof", LandmarkMaterials.pbr("stone", "#A59C8D", 3.0))
	var r := SM_SPAN * 0.5
	var poly := PackedVector2Array([Vector2(-19.5, -1.0), Vector2(-r, -1.0)])
	poly.append_array(LandmarkBrKit.arch_pts(0.0, SM_SPRING_M, r, SM_RISE_M, 16))
	poly.append_array(PackedVector2Array([Vector2(r, -1.0), Vector2(19.5, -1.0)]))
	var prev := Vector3.ZERO
	for k in 27:
		var x := 19.5 - 1.5 * k
		var p := Vector2(x, _crest(x))
		poly.append(p)
		var v := Vector3(x, p.y + 0.15, 0)
		if k > 0:
			lm.beam("Paving", prev, v, 3.6, 0.3)
		prev = v
	LandmarkBrKit.extrude_xy(lm, "Stone", poly, -2.0, 2.0)
	for s in [-1.0, 1.0]:
		lm.box("Stone", Vector3(s * 17.0, 5.0, 0), Vector3(6.0, 12.0, 9.0))
	# Halebija (west): drum with a machicolation ring and a cone; Tara
	# (east): square keep under a hip roof.
	lm.frustum("Stone", Vector3(-23.5, 4.0, 0), 4.6, 4.2, 13.5, 14)
	lm.frustum("Stone", Vector3(-23.5, 17.5, 0), 5.0, 5.0, 1.2, 14)
	lm.frustum("Roof", Vector3(-23.5, 18.7, 0), 5.3, 0.3, 7.0, 14)
	lm.box("Stone", Vector3(23.5, 11.0, 0), Vector3(8.6, 14.0, 8.6))
	lm.spire("Roof", Vector3(23.5, 18.0, 0), 4.8, 6.5, 0.3)
	lm.commit(model)

## Humped roadway height at x (21 m at the crest, 12 m at the banks).
static func _crest(x: float) -> float:
	return SM_CREST_M - 0.0231 * x * x

## Rialto Bridge, Venice: the single segmental arch of Istrian stone
## (28.8 m span, 6.4 m rise) carrying the 22.9 m wide, 48 m long
## causeway with its three walkways (two outer, one central) between
## two rows of eight shops under shallow lead roofs.
const RI_DECK_M := 7.4

static func rialto(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#DDD6C6", 3.0))
	lm.use("Paving", LandmarkMaterials.pbr("pavement", "#C2BAAB", 2.0))
	lm.use("Render", LandmarkMaterials.pbr("render", "#D9C7A2", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("slate", "#707473", 2.0))
	lm.use("Shadow", LandmarkMaterials.paint("#3A302A", 0.9, 0.0))
	var poly := PackedVector2Array([Vector2(-24.0, -1.0), Vector2(-14.4, -1.0)])
	poly.append_array(LandmarkBrKit.arch_pts(0.0, 0.8, 14.4, 5.4, 16))
	poly.append_array(PackedVector2Array([Vector2(14.4, -1.0), Vector2(24.0, -1.0)]))
	for k in 17:
		var x := 24.0 - 3.0 * k
		poly.append(Vector2(x, _deck(x)))
	LandmarkBrKit.extrude_xy(lm, "Stone", poly, -11.4, 11.4)
	for k in 16:
		var xa := -24.0 + 3.0 * k
		var xb := xa + 3.0
		for zw in [[0.0, 4.4], [-9.5, 3.7], [9.5, 3.7]]:
			lm.beam("Paving", Vector3(xa, _deck(xa) + 0.1, zw[0]), Vector3(xb, _deck(xb) + 0.1, zw[0]),
				zw[1], 0.25)
		for z in [-11.2, 11.2]:
			lm.beam("Stone", Vector3(xa, _deck(xa) + 0.6, z), Vector3(xb, _deck(xb) + 0.6, z), 0.4, 1.2)
	# Two rows of eight shops stepping with the causeway.
	for row in [-1.0, 1.0]:
		var zc: float = row * 4.95
		for i in 8:
			var xc := -19.6 + 5.6 * i
			var floor_y := _deck(absf(xc) + 2.8)
			lm.box("Render", Vector3(xc, floor_y + 2.0, zc), Vector3(5.5, 4.6, 5.5))
			lm.gable("Roof", Vector3(xc, floor_y + 4.3, zc), 5.5, 5.5, 1.3, Basis(Vector3.UP, PI * 0.5), 0.3, "Render")
			for wx in [-1.4, 1.4]:
				for wz in [-2.78, 2.78]:
					lm.box("Shadow", Vector3(xc + wx, floor_y + 2.3, zc + wz), Vector3(1.3, 2.1, 0.2))
	lm.commit(model)

static func _deck(x: float) -> float:
	return RI_DECK_M - 4.4 * (x / 24.0) * (x / 24.0)
