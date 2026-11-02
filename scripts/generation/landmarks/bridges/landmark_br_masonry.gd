class_name LandmarkBrMasonry
extends RefCounted

## Three stone bridges of the bridges batch in true metres, along +X:
## the Roman aqueduct over the Gardon (y = 0 at the river bed, bridge
## over land), and the single-arch crossings of Mostar and Venice
## (y = 0 at the water, LocationData `base: water`). Arches are solid
## masonry with their spandrels (LandmarkBrKit.arcade / extrude_xy).

## Pont du Gard: 275 m and 48.8 m high in three tiers of round arches in
## warm limestone. Lower tier 142 m long, 22 m high and 6.4 m thick: six
## arches of 15.5 to 24.5 m (the 24.5 m one over the river), springing
## from an impost band. Middle tier 242 m, 20 m high, 4.6 m thick:
## eleven arches, six over the lower ones and five more on the rising
## banks. Top tier 275 m, 7.4 m high, 3 m thick: 35 small arches carrying
## the 1.2 m water channel under its cover slabs. Rows of projecting
## stones (left for the scaffolding) stud the piers, and Henri Pitot's
## road bridge of 1743-47 runs against the downstream (-Z) face of the
## lower tier on the same arches.
const PG_TOP_M := 48.8
const PG_LOWER_SPANS: Array[float] = [15.5, 19.2, 24.5, 21.5, 19.2, 15.5]
const PG_LOWER_PIER := 4.4
const PG_LOWER_TOP := 21.9
const PG_MID_TOP := 41.6
const PG_LOWER_SPRING := 8.0
const PG_MID_SPRING := 30.5

static func pont_du_gard(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#D4BF98", 3.0))
	lm.use("Cap", LandmarkMaterials.pbr("stone", "#BDAA88", 3.0))
	lm.use("Rock", LandmarkMaterials.pbr("rock", "#8F8068", 4.0))
	# Lower tier pier centres from the spans (2.3 m end piers).
	var lower := PackedFloat32Array([-71.0 + 2.3 - PG_LOWER_PIER * 0.5])
	for sp in PG_LOWER_SPANS:
		lower.append(lower[lower.size() - 1] + sp + PG_LOWER_PIER)
	LandmarkBrKit.arcade(lm, "Stone", lower, 0.0, PG_LOWER_TOP, PG_LOWER_SPRING, 1.0, PG_LOWER_PIER, 3.2, 14)
	# Pitot's road bridge against the downstream face: same arches, its
	# roadway at 19.6 m between parapets.
	LandmarkBrKit.arcade(lm, "Stone", lower, 0.0, 19.6, PG_LOWER_SPRING, 1.0, PG_LOWER_PIER, 2.6, 14, -5.8)
	lm.box("Cap", Vector3(0, 19.75, -5.8), Vector3(142.0, 0.3, 4.6))
	lm.box("Cap", Vector3(0, 20.3, -8.2), Vector3(142.0, 1.4, 0.5))
	_pg_details(lm, lower, PG_LOWER_SPRING, [3.2, -8.4], PG_LOWER_PIER, true)
	# Middle tier: over the lower piers, then two arches on the left bank
	# and three on the right.
	var mid := PackedFloat32Array([-116.0, -93.5])
	mid.append_array(lower)
	mid.append_array(PackedFloat32Array([89.3, 107.6, 126.0]))
	for i in mid.size() - 1:
		var c := (mid[i] + mid[i + 1]) * 0.5
		var y0 := PG_LOWER_TOP if absf(c) < 71.0 else (4.0 if absf(c) < 95.0 else 13.0)
		LandmarkBrKit.arcade(lm, "Stone", PackedFloat32Array([mid[i], mid[i + 1]]), y0, PG_MID_TOP, PG_MID_SPRING,
			1.0, 3.6, 2.3, 12)
	_pg_details(lm, mid, PG_MID_SPRING, [-2.3, 2.3], 3.6, false)
	lm.box("Cap", Vector3(5.0, PG_LOWER_TOP + 0.2, 0), Vector3(242.0, 0.4, 5.2))
	# Top tier: 35 arches, the channel walls and the cover slabs.
	LandmarkBrKit.arcade(lm, "Stone", LandmarkBrKit.pier_line(-137.5, 137.5, 35), PG_MID_TOP, 46.0, 44.0, 1.0, 3.0,
		1.55, 8)
	lm.box("Cap", Vector3(0, PG_MID_TOP + 0.2, 0), Vector3(275.0, 0.4, 3.8))
	for z in [-1.15, 1.15]:
		lm.box("Stone", Vector3(0, 46.9, z), Vector3(275.0, 1.8, 0.75))
	for k in 91:
		var sx := -136.5 + 3.0 * float(k)
		lm.box("Cap", Vector3(sx, 48.3, 0), Vector3(2.9, 1.0, 3.3))
	# Rising banks under the outer arches.
	for s in [-1.0, 1.0]:
		var poly := PackedVector2Array()
		for p in [Vector2(71, 0), Vector2(150, 0), Vector2(150, 46), Vector2(137.5, 41.6),
				Vector2(118.35, 25), Vector2(94.7, 9), Vector2(71, 0.5)]:
			poly.append(Vector2(s * p.x, p.y))
		LandmarkBrKit.extrude_xy(lm, "Rock", poly, -9.0, 7.0)
	lm.commit(model)

## Pier details of one tier (pier centres `piers`, piers pier_w wide)
## on the wall faces at z in `faces`: the impost band at the springing, the arch-ring archivolts on
## both faces and the projecting scaffolding stones; `cutwaters` adds the
## lower tier's pointed upstream pier noses.
static func _pg_details(lm: LandmarkMesh, piers: PackedFloat32Array, spring: float, faces: Array,
		pier_w: float, cutwaters: bool) -> void:
	for face in faces:
		var f: float = face
		var sz := signf(f)
		lm.box("Cap", Vector3((piers[0] + piers[piers.size() - 1]) * 0.5, spring - 0.3, f + sz * 0.2),
			Vector3(piers[piers.size() - 1] - piers[0], 0.6, 0.4))
		for i in piers.size() - 1:
			var r := (piers[i + 1] - piers[i] - pier_w) * 0.5
			var c := (piers[i] + piers[i + 1]) * 0.5
			var ring := LandmarkBrKit.arch_pts(c, spring, r + 0.6, r + 0.6, 12)
			for k in ring.size() - 1:
				lm.beam("Stone", Vector3(ring[k].x, ring[k].y, f + sz * 0.15),
					Vector3(ring[k + 1].x, ring[k + 1].y, f + sz * 0.15), 1.2, 0.3, Vector3(0, 0, 1))
		for i in range(1, piers.size() - 1):
			for y in [spring - 4.0, spring + 2.0, spring + 6.5]:
				for dx in [-1.0, 1.0]:
					lm.box("Stone", Vector3(piers[i] + dx * 0.9, y, f + sz * 0.35), Vector3(0.6, 0.6, 0.7), Basis(), 0.0)
	if cutwaters:
		for i in range(1, piers.size() - 1):
			var x := piers[i]
			var hz: float = faces[0]
			lm.poly_prism("Stone", PackedVector2Array([Vector2(x - pier_w * 0.5, hz), Vector2(x, hz + 3.0),
				Vector2(x + pier_w * 0.5, hz)]), 0.0, 4.0)
			lm.spire("Stone", Vector3(x, 4.0, hz + 1.0), 1.6, 1.5, 0.3, 4)

## Stari Most, Mostar: the 28.7 m single arch of white tenelija stone
## springing from abutments 6.53 m over the summer Neretva, a 0.32 m
## moulding at the springing and a 12.02 m rise, 4 m wide, the humped
## roadway of stepped stone ribs between parapets climbing to a 21 m
## crest, the abutments with their wing walls, and the bank towers
## (UNESCO: Halebija on the right / west bank, a square keep under a hip
## roof; Tara on the left / east bank, the semicircular tower about 20 m
## high, rounded toward the river).
const SM_SPAN := 28.7
const SM_SPRING_M := 6.85
const SM_RISE_M := 12.0
const SM_CREST_M := 21.0

static func stari_most(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#E3DDCE", 3.0))
	lm.use("Paving", LandmarkMaterials.pbr("pavement", "#B8B0A2", 2.0))
	lm.use("Roof", LandmarkMaterials.pbr("stone", "#A59C8D", 3.0))
	var r := SM_SPAN * 0.5
	var arch := LandmarkBrKit.arch_pts(0.0, SM_SPRING_M, r, SM_RISE_M, 20)
	var poly := PackedVector2Array([Vector2(-19.5, 0.0), Vector2(-r, 0.0)])
	poly.append_array(arch)
	poly.append_array(PackedVector2Array([Vector2(r, 0.0), Vector2(19.5, 0.0)]))
	var prev := Vector3.ZERO
	for k in 27:
		var x := 19.5 - 1.5 * k
		var p := Vector2(x, _crest(x))
		poly.append(p)
		var v := Vector3(x, p.y + 0.15, 0)
		if k > 0:
			lm.beam("Paving", prev, v, 3.0, 0.3)
		prev = v
	LandmarkBrKit.extrude_xy(lm, "Stone", poly, -2.0, 2.0)
	# Arch ring (archivolt) on both faces and the springing moulding.
	var ring := LandmarkBrKit.arch_pts(0.0, SM_SPRING_M, r + 0.5, SM_RISE_M + 0.5, 20)
	for f in [-2.0, 2.0]:
		var sz := signf(f)
		for k in ring.size() - 1:
			lm.beam("Stone", Vector3(ring[k].x, ring[k].y, f + sz * 0.06), Vector3(ring[k + 1].x, ring[k + 1].y,
				f + sz * 0.06), 1.0, 0.12, Vector3(0, 0, 1))
		for s in [-1.0, 1.0]:
			lm.box("Stone", Vector3(s * (r + 2.4), SM_SPRING_M - 0.16, f), Vector3(5.0, 0.32, 0.3))
	# Stepped ribs across the roadway and the parapets.
	var x := -19.0
	while x < 19.0:
		lm.box("Paving", Vector3(x, _crest(x) + 0.36, 0), Vector3(0.14, 0.12, 3.0), Basis(), 0.0)
		x += 0.6
	for k in 26:
		var xa := -19.5 + 1.5 * k
		var xb := xa + 1.5
		for z in [-1.75, 1.75]:
			lm.beam("Stone", Vector3(xa, _crest(xa) + 0.6, z), Vector3(xb, _crest(xb) + 0.6, z), 0.5, 1.1)
			lm.beam("Stone", Vector3(xa, _crest(xa) + 1.2, z), Vector3(xb, _crest(xb) + 1.2, z), 0.6, 0.12)
	# Abutments with their wing walls up the banks.
	for s in [-1.0, 1.0]:
		lm.box("Stone", Vector3(s * 17.0, 6.0, 0), Vector3(6.0, 12.0, 9.0))
		for z in [-4.0, 4.0]:
			lm.box("Stone", Vector3(s * 19.5, 6.0, z), Vector3(10.0, 12.0, 1.2))
	_halebija(lm, -23.5)
	_tara(lm, 23.5)
	lm.commit(model)

## Humped roadway height at x (21 m at the crest, 12 m at the banks).
static func _crest(x: float) -> float:
	return SM_CREST_M - 0.0231 * x * x

## Halebija: square keep of rough stone on the west bank, string courses,
## loopholes and a hip roof of stone slabs.
static func _halebija(lm: LandmarkMesh, x: float) -> void:
	lm.box("Stone", Vector3(x, 1.5, 0), Vector3(9.6, 3.0, 9.6))
	lm.box("Stone", Vector3(x, 10.5, 0), Vector3(8.6, 15.0, 8.6))
	for y in [8.0, 13.0, 17.6]:
		lm.box("Stone", Vector3(x, y, 0), Vector3(8.9, 0.3, 8.9))
	for y in [10.0, 15.0]:
		for f in [-1.0, 1.0]:
			lm.box("Roof", Vector3(x + f * 4.32, y, 0), Vector3(0.1, 1.2, 0.5), Basis(), 0.0)
			lm.box("Roof", Vector3(x, y, f * 4.32), Vector3(0.5, 1.2, 0.1), Basis(), 0.0)
	lm.spire("Roof", Vector3(x, 18.0, 0), 5.0, 5.2, 0.3)

## Tara: the semicircular tower on the east bank, its round face to the
## river (-X), flat back, battered base, string courses, gun ports and a
## stone-slab roof (a half cone on a half hip).
static func _tara(lm: LandmarkMesh, x: float) -> void:
	var r := 5.0
	var top := 19.0
	var half := PackedVector2Array()
	for k in 13:
		var a := PI * 0.5 + PI * float(k) / 12.0
		half.append(Vector2(x + 1.5 + cos(a) * r, sin(a) * r))
	half.append(Vector2(x + 4.5, -r))
	half.append(Vector2(x + 4.5, r))
	lm.poly_prism("Stone", half, 3.0, top)
	var base := PackedVector2Array()
	for p in half:
		base.append(Vector2(x + 1.5 + (p.x - x - 1.5) * 1.12, p.y * 1.12))
	lm.poly_prism("Stone", base, 0.0, 3.0)
	for y in [8.0, 13.5, top - 0.3]:
		var ring := PackedVector2Array()
		for p in half:
			ring.append(Vector2(x + 1.5 + (p.x - x - 1.5) * 1.04, p.y * 1.04))
		lm.poly_prism("Stone", ring, y, y + 0.3)
	for y in [10.5, 16.0]:
		for k in 5:
			var a := PI * 0.5 + PI * (float(k) + 0.5) / 5.0
			lm.box("Roof", Vector3(x + 1.5 + cos(a) * (r + 0.02), y, sin(a) * (r + 0.02)), Vector3(0.4, 0.9, 0.4),
				Basis(Vector3.UP, -a), 0.0)
	# Roof: half cone over the round face, a lean-to over the back.
	var cone := PackedVector2Array([Vector2(r + 0.4, 0), Vector2(0.3, 6.7)])
	lm.lathe("Roof", Vector3(x + 1.5, top, 0), cone, 16, 1.0, 1.0, PI * 0.5, false, true)

## Rialto Bridge, Venice (Antonio da Ponte, 1591): the single segmental
## arch of Istrian stone (28.8 m span, 22.9 m wide, 48 m long) with its
## moulded archivolt, carrying three stepped walkways (the central Ruga
## between the shops and one along each balustrade) up two ramps to the
## central portico, whose arches open both along the Ruga and to the
## canal under a pedimented roof; 24 shops in all, six a side on each
## ramp, each with an arch to the Ruga and an arched opening to the outer
## walkway, under lead roofs stepping with the ramp.
const RI_DECK_M := 7.4
const RI_HALF_W := 11.45
const RI_RUGA := 2.2
const RI_ROW := 7.7
const RI_PORTICO := 4.5
const RI_SHOP_W := 3.25

static func rialto(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#DDD6C6", 3.0))
	lm.use("Paving", LandmarkMaterials.pbr("pavement", "#C2BAAB", 2.0))
	lm.use("Render", LandmarkMaterials.pbr("render", "#D9C7A2", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("slate", "#707473", 2.0))
	lm.use("Shadow", LandmarkMaterials.paint("#3A302A", 0.9, 0.0))
	var poly := PackedVector2Array([Vector2(-24.0, 0.0), Vector2(-14.4, 0.0)])
	poly.append_array(LandmarkBrKit.arch_pts(0.0, 0.8, 14.4, 5.4, 20))
	poly.append_array(PackedVector2Array([Vector2(14.4, 0.0), Vector2(24.0, 0.0)]))
	for k in 17:
		var x := 24.0 - 3.0 * k
		poly.append(Vector2(x, _deck(x) - 0.3))
	LandmarkBrKit.extrude_xy(lm, "Stone", poly, -RI_HALF_W, RI_HALF_W)
	# Archivolt and the springing imposts on both canal faces.
	var ring := LandmarkBrKit.arch_pts(0.0, 0.8, 15.0, 6.0, 20)
	for f in [-RI_HALF_W, RI_HALF_W]:
		var sz := signf(f)
		for k in ring.size() - 1:
			lm.beam("Stone", Vector3(ring[k].x, ring[k].y, f + sz * 0.12), Vector3(ring[k + 1].x, ring[k + 1].y,
				f + sz * 0.12), 1.1, 0.24, Vector3(0, 0, 1))
		lm.box("Stone", Vector3(0, 6.6, f + sz * 0.3), Vector3(1.1, 1.6, 0.6))
		for s in [-1.0, 1.0]:
			lm.box("Stone", Vector3(s * 18.0, 0.9, f + sz * 0.15), Vector3(7.0, 0.3, 0.3))
		# Cornice under the balustrade, following the hump.
		for k in 16:
			var xa := -24.0 + 3.0 * k
			lm.beam("Stone", Vector3(xa, _deck(xa) - 0.45, f + sz * 0.15), Vector3(xa + 3.0, _deck(xa + 3.0) - 0.45,
				f + sz * 0.15), 0.3, 0.35)
	# Stepped walkways: the Ruga and the two outer ones.
	for lane in [[0.0, RI_RUGA], [RI_ROW + 1.85, 1.75], [-RI_ROW - 1.85, 1.75]]:
		var zc: float = lane[0]
		var hw: float = lane[1]
		for s in [-1.0, 1.0]:
			var x := 0.0 if absf(zc) > 1.0 else RI_PORTICO
			while x < 24.0:
				var step := 0.9
				var y := _deck(x + step * 0.5)
				lm.box("Paving", Vector3(s * (x + step * 0.5), y - 0.2, zc), Vector3(step, 0.4, hw * 2.0))
				x += step
	lm.box("Paving", Vector3(0, RI_DECK_M - 0.2 + 0.05, 0), Vector3(RI_PORTICO * 2.0, 0.4, RI_RUGA * 2.0))
	# Balustrades along both edges.
	for z in [-RI_HALF_W + 0.25, RI_HALF_W - 0.25]:
		for k in 16:
			var xa := -24.0 + 3.0 * k
			LandmarkDetail.balustrade(lm, "Stone", Vector3(xa, _deck(xa), z), Vector3(xa + 3.0, _deck(xa + 3.0), z),
				1.05, 3.0)
	for s in [-1.0, 1.0]:
		for row in [-1.0, 1.0]:
			for i in 6:
				_ri_shop(lm, s * (RI_PORTICO + RI_SHOP_W * (float(i) + 0.5)), row)
	_ri_portico(lm)
	lm.commit(model)

static func _deck(x: float) -> float:
	return RI_DECK_M - 4.4 * (x / 24.0) * (x / 24.0)

## One shop at x on the shop row on side `row` (±Z): stone walls on a
## floor stepped to the ramp, an arch to the Ruga and an arched opening
## to the outer walkway with their dark interiors, a lead roof.
static func _ri_shop(lm: LandmarkMesh, xc: float, row: float) -> void:
	var fy := _deck(absf(xc) + RI_SHOP_W * 0.5)
	var h := 4.1
	var depth := RI_ROW - RI_RUGA
	var zc: float = row * (RI_RUGA + RI_ROW) * 0.5
	lm.box("Render", Vector3(xc, fy + h * 0.5, zc), Vector3(RI_SHOP_W - 0.1, h, depth))
	for face in [RI_RUGA, RI_ROW]:
		var fz: float = row * face
		var nz: float = row * (1.0 if face > 5.0 else -1.0)
		lm.box("Shadow", Vector3(xc, fy + 1.3, fz + nz * 0.02), Vector3(1.9, 2.6, 0.1), Basis(), 0.0)
		LandmarkDetail.arch(lm, "Stone", Vector3(xc, fy + 2.6, fz), Vector3(0, 0, nz), 1.9, 0.3, 0.18)
		for s in [-1.0, 1.0]:
			lm.box("Stone", Vector3(xc + s * (RI_SHOP_W * 0.5 - 0.15), fy + h * 0.5, fz + nz * 0.08),
				Vector3(0.3, h, 0.16))
		lm.box("Stone", Vector3(xc, fy + h - 0.15, fz + nz * 0.15), Vector3(RI_SHOP_W, 0.3, 0.3))
	lm.gable("Roof", Vector3(xc, fy + h, zc), depth, RI_SHOP_W, 0.9, Basis(Vector3.UP, PI * 0.5), 0.25, "Render")

## Central portico at the crest: corner piers, the round arches along the
## Ruga and to the canal, a cornice and the pedimented roof (13 m).
static func _ri_portico(lm: LandmarkMesh) -> void:
	var y0 := RI_DECK_M
	var eave := 11.2
	for sx in [-1.0, 1.0]:
		var x: float = sx * RI_PORTICO
		# Ruga-facing walls with the passage arch (z = ±2.2).
		var poly := PackedVector2Array([Vector2(-RI_ROW, y0), Vector2(-RI_RUGA, y0), Vector2(-RI_RUGA, 8.4)])
		for k in range(1, 10):
			var a := PI * (1.0 - float(k) / 10.0)
			poly.append(Vector2(RI_RUGA * cos(a), 8.4 + RI_RUGA * sin(a)))
		poly.append_array(PackedVector2Array([Vector2(RI_RUGA, 8.4), Vector2(RI_RUGA, y0), Vector2(RI_ROW, y0),
			Vector2(RI_ROW, eave), Vector2(-RI_ROW, eave)]))
		LandmarkBrKit.extrude_yz(lm, "Render", poly, minf(x, x - sx * 0.8), maxf(x, x - sx * 0.8))
		LandmarkDetail.arch(lm, "Stone", Vector3(x, 8.4, 0), Vector3(sx, 0, 0), RI_RUGA * 2.0, 0.35, 0.2)
	for sz in [-1.0, 1.0]:
		var z: float = sz * RI_ROW
		var poly := PackedVector2Array([Vector2(-RI_PORTICO, y0), Vector2(-2.6, y0), Vector2(-2.6, 8.0)])
		for k in range(1, 10):
			var a := PI * (1.0 - float(k) / 10.0)
			poly.append(Vector2(2.6 * cos(a), 8.0 + 2.6 * sin(a)))
		poly.append_array(PackedVector2Array([Vector2(2.6, 8.0), Vector2(2.6, y0), Vector2(RI_PORTICO, y0),
			Vector2(RI_PORTICO, eave), Vector2(-RI_PORTICO, eave)]))
		LandmarkBrKit.extrude_xy(lm, "Render", poly, minf(z, z - sz * 0.8), maxf(z, z - sz * 0.8))
		LandmarkDetail.arch(lm, "Stone", Vector3(0, 8.0, z), Vector3(0, 0, sz), 5.2, 0.4, 0.22)
		# Pilasters framing the arch, and the cornice.
		for px in [-3.6, 3.6]:
			lm.box("Stone", Vector3(px, (y0 + eave) * 0.5, z + sz * 0.12), Vector3(0.6, eave - y0, 0.24))
		LandmarkDetail.cornice(lm, "Stone", Vector3(-RI_PORTICO - 0.3, eave - 0.5, z), Vector3(RI_PORTICO + 0.3,
			eave - 0.5, z), Vector3(0, 0, sz), 0.5, true)
	lm.box("Shadow", Vector3(0, eave - 0.2, 0), Vector3(RI_PORTICO * 2.0 - 1.6, 0.2, RI_ROW * 2.0 - 1.6), Basis(), 0.0)
	lm.gable("Roof", Vector3(0, eave, 0), RI_PORTICO * 2.0, RI_ROW * 2.0, 1.6, Basis(), 0.3, "Render")
