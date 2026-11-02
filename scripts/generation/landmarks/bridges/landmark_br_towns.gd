class_name LandmarkBrTowns
extends RefCounted

## Two town bridges of the bridges batch in true metres, along +X with
## y = 0 at the river (LocationData `base: water`): Prague's Charles
## Bridge with its gate towers and saints and Florence's Ponte Vecchio
## with its overhanging shops and the Vasari Corridor. Their arches are
## solid masonry (LandmarkBrKit.arcade).

## Charles Bridge: 516 m on 16 arches on piers with pointed cutwaters
## both sides and timber ice guards upstream (+Z, the Vltava flows north),
## the 9.5 m cobbled roadway 10 m over the river between sandstone
## parapets carrying thirty baroque statues and groups over the piers
## and the 1866 pseudo-Gothic lamps; at the east (+X) end Peter Parler's
## Old Town Bridge Tower (47 m over the bank: pointed gate, sculpted east
## face, gallery, corner turrets, steep roof), at the west end the gate
## between the 43.5 m Lesser Town Bridge Tower (north) and the 29 m
## Romanesque Judith Tower (south).
const CB_HALF := 258.0
const CB_DECK_M := 10.0
const CB_HALF_W := 4.85

static func charles(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#B9B09C", 3.0))
	lm.use("Paving", LandmarkMaterials.pbr("pavement", "#9C9588", 2.0))
	lm.use("Statue", LandmarkMaterials.pbr("stone", "#4A453E", 2.0))
	lm.use("Roof", LandmarkMaterials.pbr("slate", "#56625C", 2.0))
	lm.use("Wood", LandmarkMaterials.pbr("wood", "#5B4632", 2.0))
	var piers := LandmarkBrKit.pier_line(-CB_HALF, CB_HALF, 16)
	LandmarkBrKit.arcade(lm, "Stone", piers, 0.0, CB_DECK_M, 0.5, 0.7, 9.5, 5.2, 12)
	for i in range(1, 16):
		var x := piers[i]
		# Cutwaters: the long upstream nose, a shorter one downstream, both
		# capped with stone pyramids.
		lm.poly_prism("Stone", PackedVector2Array([Vector2(x - 4.75, 5.1), Vector2(x, 10.8),
			Vector2(x + 4.75, 5.1)]), 0.0, 7.0)
		lm.spire("Stone", Vector3(x, 7.0, 6.9), 2.9, 2.6, 0.4, 4)
		lm.poly_prism("Stone", PackedVector2Array([Vector2(x - 4.75, -5.1), Vector2(x, -8.6),
			Vector2(x + 4.75, -5.1)]), 0.0, 6.0)
		lm.spire("Stone", Vector3(x, 6.0, -6.2), 2.4, 2.0, 0.3, 4)
		_ice_guard(lm, x)
	# Arch rings on both faces.
	for f in [-5.2, 5.2]:
		var sz := signf(f)
		for i in 16:
			var r := (piers[i + 1] - piers[i] - 9.5) * 0.5
			var ring := LandmarkBrKit.arch_pts((piers[i] + piers[i + 1]) * 0.5, 0.5, r + 0.7, minf(r * 0.7, CB_DECK_M - 1.7) + 0.7, 12)
			for k in ring.size() - 1:
				lm.beam("Stone", Vector3(ring[k].x, ring[k].y, f + sz * 0.1), Vector3(ring[k + 1].x, ring[k + 1].y,
					f + sz * 0.1), 1.2, 0.2, Vector3(0, 0, 1))
		lm.box("Stone", Vector3(0, CB_DECK_M - 0.35, f + sz * 0.15), Vector3(2.0 * CB_HALF, 0.5, 0.3))
	lm.box("Paving", Vector3(0, CB_DECK_M + 0.1, 0), Vector3(2.0 * CB_HALF, 0.2, 9.0))
	for z in [-CB_HALF_W, CB_HALF_W]:
		lm.box("Stone", Vector3(0, CB_DECK_M + 0.55, z), Vector3(2.0 * CB_HALF, 1.1, 0.5))
		lm.box("Stone", Vector3(0, CB_DECK_M + 1.2, z), Vector3(2.0 * CB_HALF, 0.2, 0.7))
		var sz := signf(z)
		for i in range(1, 16):
			# Statue (every third a group of two) on its pedestal over the pier.
			var sx := piers[i]
			var base := Vector3(sx, CB_DECK_M, z + sz * 0.6)
			lm.box("Statue", base + Vector3(0, 1.2, 0), Vector3(2.4, 2.4, 2.2))
			lm.box("Statue", base + Vector3(0, 0.25, 0), Vector3(2.8, 0.5, 2.6))
			lm.box("Statue", base + Vector3(0, 2.5, 0), Vector3(2.7, 0.3, 2.5))
			if i % 3 == 0:
				LandmarkKits.statue_figure(lm, "Statue", base + Vector3(-0.5, 2.65, 0), 3.4, true)
				LandmarkKits.statue_figure(lm, "Statue", base + Vector3(0.7, 2.65, 0.1), 2.6)
			else:
				LandmarkKits.statue_figure(lm, "Statue", base + Vector3(0, 2.65, 0), 3.4, i % 2 == 0)
			# Lamp standard midway to the next pier.
			if i < 15:
				var lx := (piers[i] + piers[i + 1]) * 0.5
				var lb := Vector3(lx, CB_DECK_M + 1.3, z)
				lm.frustum("Statue", lb, 0.16, 0.1, 3.2, 8)
				lm.lathe("Statue", lb + Vector3(0, 3.2, 0), PackedVector2Array([Vector2(0.1, 0), Vector2(0.32, 0.3),
					Vector2(0.3, 0.9), Vector2(0.12, 1.1), Vector2(0.04, 1.5), Vector2(0.0, 1.6)]), 6)
	_old_town_tower(lm, 250.0)
	_lesser_town_gate(lm, -CB_HALF)
	lm.commit(model)

## Timber ice guard upstream of the pier at x: a wedge of piles
## with a sloping plank deck pointing into the current.
static func _ice_guard(lm: LandmarkMesh, x: float) -> void:
	for p in [Vector2(0, 22.0), Vector2(-2.0, 18.0), Vector2(2.0, 18.0), Vector2(-3.4, 14.0), Vector2(3.4, 14.0)]:
		lm.frustum("Wood", Vector3(x + p.x, 0, p.y), 0.25, 0.22, 2.6, 6)
	for s in [-1.0, 1.0]:
		lm.beam("Wood", Vector3(x, 2.4, 22.0), Vector3(x + s * 3.4, 2.4, 14.0), 0.35, 0.35)
		lm.beam("Wood", Vector3(x + s * 3.4, 2.4, 14.0), Vector3(x + s * 4.0, 2.4, 11.2), 0.35, 0.35)
	lm.beam("Wood", Vector3(x, 2.6, 22.0), Vector3(x, 1.5, 11.5), 0.5, 0.3)

## Old Town Bridge Tower at x over the roadway: legs round the pointed
## 8.4 m gate, the tower block with string courses, blind tracery
## panels and the sculpture tier on the river-facing and city faces,
## the gallery on corbels with corner turrets and the steep hip roof.
static func _old_town_tower(lm: LandmarkMesh, x: float) -> void:
	var hx := 6.25
	var hz := 7.2
	var crown := LandmarkCoreBBridgeKit.pointed_arch(lm, "Stone", x, 2.0 * hx, 0.0, 8.4, 6.7, 15.0)
	for sz in [-1.0, 1.0]:
		var z0 := 4.2
		lm.box("Stone", Vector3(x, crown * 0.5, sz * (z0 + hz) * 0.5), Vector3(2.0 * hx, crown, hz - z0))
	var top := 36.0
	lm.box("Stone", Vector3(x, (crown + top) * 0.5, 0), Vector3(2.0 * hx, top - crown, 2.0 * hz))
	for fx in [-1.0, 1.0]:
		var fxx: float = x + fx * hx
		for y in [crown + 0.3, 27.0, 31.5]:
			lm.box("Stone", Vector3(fxx + fx * 0.15, y, 0), Vector3(0.3, 0.4, 2.0 * hz + 0.3))
		# Blind tracery: framed pointed panels in two tiers.
		for tier in [[27.4, 31.1], [31.9, 35.6]]:
			for pz in [-4.8, -1.6, 1.6, 4.8]:
				var y0: float = tier[0]
				var y1: float = tier[1]
				for s in [-1.0, 1.0]:
					lm.box("Stone", Vector3(fxx + fx * 0.12, (y0 + y1) * 0.5, pz + s * 1.3), Vector3(0.24, y1 - y0, 0.25))
				lm.beam("Stone", Vector3(fxx + fx * 0.12, y1 - 0.9, pz - 1.3), Vector3(fxx + fx * 0.12, y1, pz), 0.24, 0.25)
				lm.beam("Stone", Vector3(fxx + fx * 0.12, y1, pz), Vector3(fxx + fx * 0.12, y1 - 0.9, pz + 1.3), 0.24, 0.25)
		# Sculpture tier over the gate: a seated king either side of the
		# bridge's patron, under canopies.
		for pz in [-3.2, 0.0, 3.2]:
			lm.box("Stone", Vector3(fxx + fx * 0.6, crown + 1.2, pz), Vector3(1.2, 0.5, 1.6))
			LandmarkKits.statue_figure(lm, "Stone", Vector3(fxx + fx * 0.6, crown + 1.45, pz), 2.6)
			lm.spire("Stone", Vector3(fxx + fx * 0.6, crown + 4.4, pz), 0.8, 1.6, 0.0, 4)
	# Gallery on corbels with a pierced parapet, corner turrets, roof.
	lm.box("Stone", Vector3(x, top + 0.3, 0), Vector3(2.0 * hx + 1.6, 0.6, 2.0 * hz + 1.6))
	for fx in [-1.0, 1.0]:
		for k in 9:
			var cz := lerpf(-hz, hz, float(k) / 8.0)
			lm.box("Stone", Vector3(x + fx * (hx + 0.4), top - 0.5, cz), Vector3(0.8, 1.0, 0.5))
		lm.box("Stone", Vector3(x + fx * (hx + 0.7), top + 1.1, 0), Vector3(0.25, 1.0, 2.0 * hz + 1.4))
	for sz in [-1.0, 1.0]:
		lm.box("Stone", Vector3(x, top + 1.1, sz * (hz + 0.7)), Vector3(2.0 * hx + 1.4, 1.0, 0.25))
	lm.box("Stone", Vector3(x, top + 4.0, 0), Vector3(2.0 * hx - 1.2, 8.0, 2.0 * hz - 1.2))
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var cx: float = x + sx * (hx - 0.6)
			var cz: float = sz * (hz - 0.6)
			lm.frustum("Stone", Vector3(cx, top - 1.0, cz), 1.2, 1.5, 1.0, 10)
			lm.frustum("Stone", Vector3(cx, top, cz), 1.5, 1.5, 11.0, 10)
			lm.frustum("Stone", Vector3(cx, top + 11.0, cz), 1.7, 1.7, 0.4, 10)
			lm.spire("Roof", Vector3(cx, top + 11.4, cz), 1.7, 5.6, 0.0, 8)
	lm.spire("Roof", Vector3(x, top + 8.0, 0), 6.2, 12.4, 0.5)
	lm.frustum("Roof", Vector3(x, top + 20.4, 0), 0.25, 0.05, 0.6, 6)

## The Lesser Town bridgehead at x (the bridge's west end): the 43.5 m
## Lesser Town Bridge Tower north of the road (-Z), the 29 m Judith Tower
## south of it, and the crenellated gate over the roadway between them.
static func _lesser_town_gate(lm: LandmarkMesh, x: float) -> void:
	# Lesser Town Bridge Tower: square, string courses, steep tented roof
	# with corner turrets and dormer gables.
	var tx: float = x - 6.0
	var tz := -10.6
	var h := 43.5 - 13.0
	lm.box("Stone", Vector3(tx, (CB_DECK_M + h) * 0.5, tz), Vector3(10.0, CB_DECK_M + h, 10.0))
	for y in [CB_DECK_M + 9.0, CB_DECK_M + 18.0, CB_DECK_M + h - 0.3]:
		lm.box("Stone", Vector3(tx, y, tz), Vector3(10.4, 0.4, 10.4))
	var rt := CB_DECK_M + h
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var cx: float = tx + sx * 4.6
			var cz: float = tz + sz * 4.6
			lm.frustum("Stone", Vector3(cx, rt - 0.8, cz), 0.9, 0.9, 3.0, 8)
			lm.spire("Roof", Vector3(cx, rt + 2.2, cz), 1.0, 4.0, 0.0, 8)
		lm.gable("Roof", Vector3(tx + sx * 3.2, rt + 1.0, tz), 3.0, 2.4, 1.8, Basis(), 0.2, "Stone")
	lm.spire("Roof", Vector3(tx, rt, tz), 5.4, 12.0, 0.3)
	lm.frustum("Roof", Vector3(tx, rt + 12.0, tz), 0.2, 0.05, 1.0, 6)
	# Judith Tower: lower, Romanesque, hip roof.
	var jx: float = x - 2.0
	var jz := 9.2
	var jh := 29.0 - 8.0
	lm.box("Stone", Vector3(jx, (CB_DECK_M + jh) * 0.5, jz), Vector3(9.0, CB_DECK_M + jh, 8.4))
	for y in [CB_DECK_M + 7.0, CB_DECK_M + 14.0]:
		lm.box("Stone", Vector3(jx, y, jz), Vector3(9.3, 0.35, 8.7))
	lm.spire("Roof", Vector3(jx, CB_DECK_M + jh, jz), 5.0, 8.0, 0.4)
	# Gate over the road between them: pointed arch, crenellated wall.
	var crown := LandmarkCoreBBridgeKit.pointed_arch(lm, "Stone", x - 4.0, 3.0, 0.0, 9.4, 7.2, CB_DECK_M + 4.0)
	lm.box("Stone", Vector3(x - 4.0, (crown + CB_DECK_M + 13.0) * 0.5, 0), Vector3(3.0, CB_DECK_M + 13.0 - crown, 11.0))
	for k in 6:
		lm.box("Stone", Vector3(x - 4.0, CB_DECK_M + 13.6, -4.4 + 1.76 * k), Vector3(3.0, 1.2, 0.9))
	for sz in [-1.0, 1.0]:
		lm.box("Stone", Vector3(x - 4.0, (CB_DECK_M + 4.0) * 0.5, sz * 5.0), Vector3(3.0, CB_DECK_M + 4.0, 0.6))

## Ponte Vecchio: three segmental arches in rusticated stone (the 30 m
## main arch, two of 27 m, rising 4.4 and 3.5 m) on piers with pointed
## cutwaters both sides, the 9 m causeway between two rows of two- and
## three-storey shops in ochre, rose and cream under terracotta roofs,
## their street fronts closed by wooden shutter boxes (madielle) and
## their back rooms (retrobotteghe) jettied over the Arno on timber
## brackets; the open central terrace with Romanelli's bronze bust of
## Cellini (1900) on its fountain, and over the east shops the Vasari
## Corridor (1565), carried over the terrace on three arches.
const PV_DECK_M := 9.0
const PV_PIERS: Array[float] = [-51.0, -18.0, 18.0, 51.0]

static func ponte_vecchio(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#B3A689", 3.0))
	lm.use("Ochre", LandmarkMaterials.pbr("render", "#D9AB62", 3.0))
	lm.use("Rose", LandmarkMaterials.pbr("render", "#CC8A68", 3.0))
	lm.use("Cream", LandmarkMaterials.pbr("render", "#DFD0A8", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("terracotta", "#A94F33", 3.0))
	lm.use("Wood", LandmarkMaterials.pbr("wood", "#6B4F36", 2.0))
	lm.use("Shadow", LandmarkMaterials.paint("#32291F", 0.9, 0.0))
	lm.use("Bronze", LandmarkMaterials.paint("#4E5643", 0.45, 0.7))
	LandmarkBrKit.arcade(lm, "Stone", PackedFloat32Array([PV_PIERS[1], PV_PIERS[2]]), 0.0, PV_DECK_M, 3.3,
		4.4 / 15.0, 6.0, 11.0, 14)
	for i in [0, 2]:
		LandmarkBrKit.arcade(lm, "Stone", PackedFloat32Array([PV_PIERS[i], PV_PIERS[i + 1]]), 0.0, PV_DECK_M, 3.3,
			3.5 / 13.5, 6.0, 11.0, 14)
	for f in [-11.0, 11.0]:
		var sz := signf(f)
		for i in 3:
			var r := (PV_PIERS[i + 1] - PV_PIERS[i] - 6.0) * 0.5
			var rise := 4.4 if i == 1 else 3.5
			var ring := LandmarkBrKit.arch_pts((PV_PIERS[i] + PV_PIERS[i + 1]) * 0.5, 3.3, r + 0.7, rise + 0.7, 14)
			for k in ring.size() - 1:
				lm.beam("Stone", Vector3(ring[k].x, ring[k].y, f + sz * 0.12), Vector3(ring[k + 1].x, ring[k + 1].y,
					f + sz * 0.12), 1.3, 0.24, Vector3(0, 0, 1))
		for px in [PV_PIERS[1], PV_PIERS[2]]:
			lm.poly_prism("Stone", PackedVector2Array([Vector2(px - 3.0, f), Vector2(px, f + sz * 4.0),
				Vector2(px + 3.0, f)]), 0.0, 3.6)
			lm.spire("Stone", Vector3(px, 3.6, f + sz * 1.35), 2.2, 2.4, 0.2, 4)
		lm.box("Stone", Vector3(0, PV_DECK_M - 0.3, f + sz * 0.2), Vector3(102.0, 0.6, 0.4))
	var rng := RandomNumberGenerator.new()
	rng.seed = 1345
	var walls: Array[String] = ["Ochre", "Rose", "Cream"]
	for row in [-1.0, 1.0]:
		var x := -48.0
		while x < 48.0:
			var bw := minf(rng.randf_range(4.2, 6.4), 48.0 - x)
			var xc := x + bw * 0.5
			x += bw
			if absf(xc) < 7.0:
				continue
			# East shops (-Z) stay low, the Vasari Corridor runs over them.
			var h := 7.0 if row < 0.0 else (6.8 if rng.randf() < 0.5 else 10.4)
			_pv_shop(lm, xc, bw, h, row, walls[rng.randi() % 3], rng.randf())
	_pv_corridor(lm)
	# Terrace: west parapet, the Cellini fountain and bust on the east.
	for z in [-11.0, 11.0]:
		lm.box("Stone", Vector3(0, PV_DECK_M + 0.55, z), Vector3(14.0, 1.1, 0.5))
	lm.box("Stone", Vector3(0, PV_DECK_M + 0.6, -10.6), Vector3(3.2, 1.2, 1.6))
	lm.box("Stone", Vector3(0, PV_DECK_M + 2.2, -10.9), Vector3(1.4, 2.0, 1.0))
	lm.box("Stone", Vector3(0, PV_DECK_M + 3.3, -10.9), Vector3(1.7, 0.3, 1.3))
	lm.lathe("Bronze", Vector3(0, PV_DECK_M + 3.45, -10.9), PackedVector2Array([Vector2(0.5, 0), Vector2(0.45, 0.35),
		Vector2(0.18, 0.5), Vector2(0.17, 0.62), Vector2(0.22, 0.72), Vector2(0.23, 0.92), Vector2(0.14, 1.08),
		Vector2(0.0, 1.12)]), 12, 1.0, 0.8)
	lm.commit(model)

## One shop of width bw at xc on row ±Z: the block on the bridge, the
## jettied back room on brackets, shutter boxes on the street front,
## shuttered windows to the river, eaves brackets and the roof.
static func _pv_shop(lm: LandmarkMesh, xc: float, bw: float, h: float, row: float, key: String,
		roll: float) -> void:
	var zc: float = row * 8.8
	var w := bw - 0.15
	lm.box(key, Vector3(xc, PV_DECK_M + h * 0.5, zc), Vector3(w, h, 11.2))
	lm.gable("Roof", Vector3(xc, PV_DECK_M + h, zc), 11.2, w, 1.6, Basis(Vector3.UP, PI * 0.5), 0.5, key)
	# Street front: madielle (wooden shutter box) under a stone lintel.
	var sf: float = row * 3.2
	lm.box("Wood", Vector3(xc, PV_DECK_M + 1.5, sf - row * 0.15), Vector3(w - 1.2, 2.6, 0.3))
	for k in 3:
		lm.box("Wood", Vector3(xc - (w - 1.2) * 0.33 + (w - 1.2) * 0.33 * k, PV_DECK_M + 1.5, sf - row * 0.32),
			Vector3(0.12, 2.5, 0.06), Basis(), 0.0)
	lm.box("Stone", Vector3(xc, PV_DECK_M + 3.0, sf - row * 0.1), Vector3(w - 0.6, 0.35, 0.3))
	# Back room jettied out over the river on its brackets.
	var out := 0.8 + roll * 1.4
	var bf: float = row * (14.4 + out * 0.5)
	lm.box(key, Vector3(xc, PV_DECK_M + 0.5 + (h - 1.0) * 0.5, bf), Vector3(w - 0.4, h - 1.0, out))
	for bx in [-0.32, 0.0, 0.32]:
		lm.beam("Wood", Vector3(xc + w * bx, PV_DECK_M - 3.4, row * 11.2), Vector3(xc + w * bx, PV_DECK_M + 0.4,
			row * (14.4 + out)), 0.35, 0.5, Vector3(1, 0, 0))
	var face: float = row * (14.4 + out)
	for fy in range(1, int(h / 3.2) + 1):
		var wy := PV_DECK_M + 3.2 * fy - 1.0
		if wy + 1.0 > PV_DECK_M + h - 0.4:
			break
		for wx in ([0.0] if w < 5.0 else [-1.2, 1.2]):
			var cx: float = xc + wx
			lm.box("Shadow", Vector3(cx, wy, face + row * 0.02), Vector3(0.9, 1.5, 0.08), Basis(), 0.0)
			for s in [-1.0, 1.0]:
				lm.box("Wood", Vector3(cx + s * 0.75, wy, face + row * 0.06), Vector3(0.5, 1.6, 0.08), Basis(), 0.0)
			lm.box("Stone", Vector3(cx, wy - 0.85, face + row * 0.08), Vector3(1.2, 0.12, 0.2), Basis(), 0.0)
	# Street-side upper windows.
	if h > 8.0:
		lm.box("Shadow", Vector3(xc, PV_DECK_M + 5.4, sf - row * 0.02), Vector3(1.0, 1.4, 0.08), Basis(), 0.0)
	# Eaves brackets on the river side.
	var nb := maxi(int(w / 1.2), 2)
	for k in nb:
		var ex := xc - w * 0.5 + w * (float(k) + 0.5) / nb
		lm.box("Wood", Vector3(ex, PV_DECK_M + h - 0.2, row * (14.4 + out + 0.2)), Vector3(0.15, 0.25, 0.5), Basis(), 0.0)

## Vasari Corridor over the east shops: its walls and roof, the street
## and river windows, and the three arches over the central terrace.
static func _pv_corridor(lm: LandmarkMesh) -> void:
	var y := PV_DECK_M + 7.0
	lm.box("Ochre", Vector3(0, y + 1.7, -6.2), Vector3(104.0, 3.4, 3.4))
	lm.gable("Roof", Vector3(0, y + 3.4, -6.2), 3.4, 104.0, 0.9, Basis(Vector3.UP, PI * 0.5), 0.4, "Ochre")
	lm.box("Stone", Vector3(0, y + 0.1, -6.2), Vector3(104.0, 0.2, 3.6))
	for wx in range(-48, 49, 4):
		if absf(wx) < 8.0:
			continue
		for fz in [-4.48, -7.92]:
			var nz := 1.0 if fz > -6.2 else -1.0
			lm.box("Shadow", Vector3(wx, y + 1.9, fz + nz * 0.02), Vector3(0.9, 1.1, 0.06), Basis(), 0.0)
			lm.box("Stone", Vector3(wx, y + 1.9, fz + nz * 0.06), Vector3(1.2, 1.4, 0.06), Basis(), 0.0)
	# Three big windows over the terrace, toward the river views.
	for wx in [-4.6, 0.0, 4.6]:
		for fz in [-4.48, -7.92]:
			var nz := 1.0 if fz > -6.2 else -1.0
			lm.box("Shadow", Vector3(wx, y + 1.9, fz + nz * 0.03), Vector3(3.0, 1.8, 0.08), Basis(), 0.0)
	# Arcade over the terrace: four stone piers, three round arches.
	for px in [-7.0, -2.35, 2.35, 7.0]:
		LandmarkDetail.column(lm, "Stone", Vector3(px, PV_DECK_M, -6.2), 0.45, 4.6, "tuscan", 0)
	lm.box("Stone", Vector3(0, PV_DECK_M + 5.8, -6.2), Vector3(14.6, 2.4, 3.0))
	for ax in [-4.675, 0.0, 4.675]:
		for fz in [-4.7, -7.7]:
			var nz := 1.0 if fz > -6.2 else -1.0
			LandmarkDetail.arch(lm, "Stone", Vector3(ax, PV_DECK_M + 4.6, fz), Vector3(0, 0, nz), 3.8, 0.35, 0.2)
