class_name LandmarkAmhMaya
extends RefCounted

## Three Mesoamerican pyramids in true metres: the Pyramid of the Sun
## at Teotihuacan, the Temple of the Inscriptions with the Palace tower
## at Palenque and Tikal's Temple I (the Pyramid of the Magician is in
## LandmarkAmhUxmal). Stairways are built facing the way noted on each
## model and the registry yaw turns them onto the real bearing.

const SUN_TOP_M := 65.5
const INSCRIPTIONS_TOP_M := 27.2
const TIKAL_TOP_M := 47.0

## Heights of the five stepped bodies of the Pyramid of the Sun.
const SUN_TIERS := [16.0, 14.0, 13.0, 12.0, 10.5]

## Pyramid of the Sun: about 225 m square at the foot and 65.5 m
## high, five sloped bodies of volcanic rubble (the 1905-10 Batres
## reconstruction) under pale stucco cornices with a terrace between
## each, the broad west stairway (+Z) of 248 steps climbing in a flight
## per body between its side balustrades (alfardas), and in front the
## two-body talud-tablero Adosada platform with its own stair. The
## temple that crowned it is lost; the summit is a bare platform.
static func sun_pyramid(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#8A735F", 4.0))
	lm.use("Stucco", LandmarkMaterials.pbr("render", "#C9B898", 4.0))
	lm.use("Steps", LandmarkMaterials.pbr("limestone", "#A99880", 3.0))
	var bx := 112.5
	var bz := 111.0
	var y := 0.0
	var tread := 65.5 / 248.0
	# Adosada: two talud-tablero bodies (to 6.4 m) against the west face.
	var ad := Vector3(0, 0, bz + 9.0)
	var t1 := LandmarkAmhParts.talud_tablero(lm, "Stone", "Stucco", ad, 39.0, 13.0, 1.2, 2.0, 0.6, 6.5)
	var t2 := LandmarkAmhParts.talud_tablero(lm, "Stone", "Stucco", ad + Vector3(0, t1, -1.0), 34.0,
		11.0, 1.0, 1.8, 0.5, 6.5)
	var ad_top := t1 + t2
	lm.box("Stucco", ad + Vector3(0, ad_top + 0.05, -1.0), Vector3(66.0, 0.1, 21.0), Basis(), 0.0)
	var na := int(round(ad_top / tread))
	LandmarkAmhParts.stair(lm, "Steps", Vector3.ZERO, Basis(), 22.0, bz + 24.6, 0.0, bz + 19.0, ad_top,
		bz + 15.0, na, 0.04)
	LandmarkAmhParts.rails(lm, "Stucco", Vector3.ZERO, Basis(), 22.0, bz + 24.6, 0.0, bz + 19.0,
		ad_top - 0.1, 1.8, 1.0)
	for k in SUN_TIERS.size():
		var h: float = SUN_TIERS[k]
		var slope := h - 0.9
		LandmarkAmhParts.slab(lm, "Stone", Vector3(0, y, 0), slope, bx, bz, bx - slope, bz - slope,
			false)
		# Cornice lip flaring out of the top of the slope, a moulded
		# string course below it and the terrace pavement behind.
		LandmarkAmhParts.slab(lm, "Stucco", Vector3(0, y + slope, 0), 0.9, bx - slope, bz - slope,
			bx - slope + 0.35, bz - slope + 0.35)
		LandmarkAmhParts.slab(lm, "Stucco", Vector3(0, y + slope - 1.6, 0), 0.35, bx - slope + 1.6,
			bz - slope + 1.6, bx - slope + 1.75, bz - slope + 1.75, false)
		var w := 38.0 - 4.0 * float(k)
		var foot_z := bz + 0.15
		var foot_y := y
		if k == 0:
			foot_y = ad_top
			foot_z = bz - ad_top + 0.15
		var n := int(round((y + h - foot_y) / tread))
		var head_z := bz - h + 1.4
		LandmarkAmhParts.stair(lm, "Steps", Vector3.ZERO, Basis(), w, foot_z, foot_y, head_z, y + h,
			head_z - 4.5, n, 0.04)
		LandmarkAmhParts.rails(lm, "Stucco", Vector3.ZERO, Basis(), w, foot_z, foot_y, head_z,
			y + h - 0.2, 2.6, 1.6)
		# Landing at the head of the flight, with the balustrade heads.
		lm.box("Steps", Vector3(0, y + h - 0.15, head_z - 6.0), Vector3(w + 5.2, 0.3, 4.0))
		for s in [-1.0, 1.0]:
			lm.box("Stucco", Vector3(s * (w * 0.5 + 1.3), y + h + 0.3, head_z - 0.6),
				Vector3(2.6, 0.9, 2.6))
		bx = bx - slope + 0.35 - 9.4
		bz = bz - slope + 0.35 - 9.4
		y += h
	# Summit platform: a low kerb round the floor of the lost temple.
	for q in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * float(q))
		var span := bx if q % 2 == 0 else bz
		var depth := bz if q % 2 == 0 else bx
		lm.box("Stucco", Vector3(0, y - 0.2, 0) + r * Vector3(0, 0, depth - 1.0),
			Vector3(2.0 * span - 2.0, 0.4, 1.2), r)
	lm.commit(model)

## Temple of the Inscriptions: the eight-stepped pyramid (60 x 42.5 m)
## with its central stair between broad balustrades, under the temple
## (25.5 x 10.5 m): a front gallery behind five doorways and six
## piers bearing stucco figures, three doorways through the medial wall
## to the shrine rooms, the corbel vault seen through the doors, the
## sloping mansard frieze with its stucco panels and the stub of the
## perforated roof comb, 27.2 m above the plaza. The stair faces north
## (-Z). Beside it, to the north-east, the Palace galleries and tower.
static func inscriptions(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#B9B09A", 3.0))
	lm.use("Steps", LandmarkMaterials.pbr("limestone", "#CBC2AA", 3.0))
	lm.use("Stucco", LandmarkMaterials.pbr("render", "#D5CBB0", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("limestone", "#9E9580", 3.0))
	lm.use("Door", LandmarkMaterials.glass("#1F2528"))
	var tiers := 8
	var pyr_h := INSCRIPTIONS_TOP_M - 9.4
	var th := pyr_h / float(tiers)
	var front := Basis(Vector3.UP, PI)
	for k in tiers:
		var hx := 30.0 - 2.0 * float(k)
		var hz := 21.25 - 1.66 * float(k)
		var y := th * float(k)
		# Each body: a battered face up to a projecting apron moulding.
		LandmarkAmhParts.slab(lm, "Stone", Vector3(0, y, 0), th - 0.45, hx, hz, hx - 0.35, hz - 0.35)
		LandmarkAmhParts.slab(lm, "Stucco", Vector3(0, y + th - 0.45, 0), 0.45, hx - 0.2, hz - 0.2,
			hx - 0.3, hz - 0.3)
	# Stair: 69 steps between balustrades, a landing near the head.
	LandmarkAmhParts.stair(lm, "Steps", Vector3.ZERO, front, 9.6, 21.85, 0.0, 8.1, pyr_h, 5.0, 69, 0.03)
	LandmarkAmhParts.rails(lm, "Stone", Vector3.ZERO, front, 9.6, 21.85, 0.0, 8.1, pyr_h, 1.8, 1.5)
	for s in [-1.0, 1.0]:
		lm.box("Stucco", front * Vector3(s * 5.7, 0.5, 22.3), Vector3(2.0, 1.0, 1.4), front)
	_inscriptions_temple(lm, Vector3(0, pyr_h, 2.5))
	_palace_tower(lm, Vector3(38.0, 0, -64.0))
	lm.commit(model)

## The summit temple at `tc` (floor centre), its front facing -Z.
static func _inscriptions_temple(lm: LandmarkMesh, tc: Vector3) -> void:
	var front := Basis(Vector3.UP, PI)
	var hw := 12.75
	var hd := 5.25
	lm.box("Stone", tc + Vector3(0, 0.2, 0), Vector3(2.0 * hw + 1.0, 0.4, 2.0 * hd + 1.0))
	var fl := tc + Vector3(0, 0.4, 0)
	# Rear rooms block and end walls; the front gallery 3 m deep.
	lm.box("Stone", fl + Vector3(0, 2.0, 1.75), Vector3(2.0 * hw, 4.0, 7.0))
	for s in [-1.0, 1.0]:
		lm.box("Stone", fl + Vector3(s * (hw - 0.6), 2.0, -3.6), Vector3(1.2, 4.0, 3.3))
	LandmarkAmhParts.corbel_vault(lm, "Stone", "", fl + Vector3(0, 0, -3.25), front, 2.0 * hw - 2.4,
		3.0, 2.6, 1.4)
	for i in 3:
		LandmarkAmhParts.opening(lm, "Door", fl + Vector3(-7.2 + 7.2 * float(i), 1.3, -1.78), Basis(),
			1.4, 2.6, 0.1)
	# Six piers between five doorways, each with its framed stucco figure.
	for i in 6:
		var x := -11.0 + 4.4 * float(i)
		lm.box("Stone", fl + Vector3(x, 2.0, -4.6), Vector3(1.9, 4.0, 1.1))
		var pf := fl + Vector3(x, 0, -5.2)
		lm.box("Stucco", pf + Vector3(0, 3.55, 0), Vector3(1.8, 0.3, 0.1), Basis(), 0.0)
		lm.box("Stucco", pf + Vector3(0, 0.2, 0), Vector3(1.8, 0.3, 0.1), Basis(), 0.0)
		for sx in [-0.8, 0.8]:
			lm.box("Stucco", pf + Vector3(sx, 1.85, 0), Vector3(0.2, 3.4, 0.1), Basis(), 0.0)
		LandmarkKits.statue_figure(lm, "Stucco", pf + Vector3(0, 0.35, -0.05), 1.7, i % 2 == 0)
	lm.box("Stone", fl + Vector3(0, 3.6, -4.6), Vector3(2.0 * hw, 0.8, 1.2))
	# Medial moulding, the sloping mansard frieze with stucco panels over
	# the piers, upper moulding and the flat roof.
	var m := fl + Vector3(0, 4.0, 0)
	lm.box("Stucco", m + Vector3(0, 0.2, 0), Vector3(2.0 * hw + 0.9, 0.4, 2.0 * hd + 0.9))
	LandmarkNaParts.hip(lm, "Roof", m + Vector3(0, 0.4, 0), Basis(), hw + 0.3, hd + 0.3, 0.8, 2.2)
	for i in 6:
		var x := -11.0 + 4.4 * float(i)
		var pc := m + Vector3(x, 1.5, -hd - 0.05)
		lm.box("Stucco", pc, Vector3(2.4, 1.6, 0.5), Basis(Vector3.RIGHT, -0.5))
		lm.box("Stucco", pc + Vector3(0, 0.1, -0.35), Vector3(0.8, 0.8, 0.4),
			Basis(Vector3.RIGHT, -0.5))
	var r := m + Vector3(0, 2.6, 0)
	lm.box("Stucco", r + Vector3(0, 0.2, 0),
		Vector3(2.0 * (hw + 0.3) * 0.8 + 0.6, 0.4, 2.0 * (hd + 0.3) * 0.8 + 0.6))
	lm.box("Roof", r + Vector3(0, 0.55, 0),
		Vector3(2.0 * (hw + 0.3) * 0.8, 0.3, 2.0 * (hd + 0.3) * 0.8))
	# Roof comb stub: a perforated wall on the medial line.
	var cb := r + Vector3(0, 0.7, 0)
	var cw := 18.5
	lm.box("Stone", cb + Vector3(0, 0.15, 0), Vector3(cw + 0.4, 0.3, 1.2))
	lm.box("Stone", cb + Vector3(0, 1.85, 0), Vector3(cw, 0.3, 0.9))
	for i in 10:
		var x := -cw * 0.5 + 0.2 + (cw - 0.4) * float(i) / 9.0
		lm.box("Stone", cb + Vector3(x, 1.0, 0), Vector3(0.45, 1.4, 0.9))
	for i in 9:
		var x := -cw * 0.5 + (cw - 0.4) * (float(i) + 0.5) / 9.0 + 0.2
		lm.box("Stone", cb + Vector3(x, 1.0, 0), Vector3(1.6, 0.25, 0.7))

## The Palace platform corner with its two galleries (pier fronts,
## mansard roofs) and the four-storey square tower (7.5 m platform,
## 14 m of tower with open bays and a hipped crown), the platform stair
## facing the temple.
static func _palace_tower(lm: LandmarkMesh, pc: Vector3) -> void:
	LandmarkAmhParts.slab(lm, "Stone", pc, 7.3, 30.0, 20.0, 29.4, 19.4)
	lm.box("Stucco", pc + Vector3(0, 7.5, 0), Vector3(59.4, 0.4, 39.4))
	LandmarkAmhParts.stair(lm, "Steps", pc, Basis(Vector3.UP, -PI * 0.5), 10.0, 34.0, 0.0, 29.0, 7.3,
		26.0, 26, 0.03)
	LandmarkAmhParts.rails(lm, "Stone", pc, Basis(Vector3.UP, -PI * 0.5), 10.0, 34.0, 0.0, 29.0, 7.3,
		1.2, 1.2)
	for gz in [-12.0, 12.0]:
		var out: float = 1.0 if gz > 0.0 else -1.0
		var r := Basis(Vector3.UP, 0.0 if out > 0.0 else PI)
		var g := pc + Vector3(0, 7.7, gz)
		lm.box("Stone", g + Vector3(0, 1.9, -out * 1.33), Vector3(46.0, 3.8, 3.85))
		LandmarkAmhParts.corbel_vault(lm, "Stone", "Door", g + Vector3(0, 0, out * 1.8), r, 45.0, 2.4,
			2.4, 1.2)
		for i in 9:
			lm.box("Stone", g + Vector3(-22.4 + 5.6 * float(i), 1.9, out * 2.75),
				Vector3(1.5, 3.8, 1.0))
		lm.box("Stone", g + Vector3(0, 3.4, out * 2.75), Vector3(46.0, 0.8, 1.0))
		lm.box("Stucco", g + Vector3(0, 4.0, 0), Vector3(47.0, 0.4, 7.0))
		LandmarkNaParts.hip(lm, "Roof", g + Vector3(0, 4.2, 0), Basis(), 23.4, 3.4, 0.7, 1.6)
		lm.box("Stucco", g + Vector3(0, 5.9, 0), Vector3(33.4, 0.3, 5.0))
	var sizes := [8.0, 7.2, 6.4, 5.6]
	var y := 7.7
	for k in 4:
		var s: float = sizes[k]
		var tc := pc + Vector3(-4.0, y, 3.0)
		# Corner piers with an open bay between on every face.
		for cx in [-1.0, 1.0]:
			for cz in [-1.0, 1.0]:
				lm.box("Stone", tc + Vector3(cx * s * 0.36, 1.6, cz * s * 0.36),
					Vector3(s * 0.28, 3.2, s * 0.28))
		lm.box("Stone", tc + Vector3(0, 1.6, 0), Vector3(s * 0.5, 3.2, s * 0.5))
		lm.box("Door", tc + Vector3(0, 1.4, 0), Vector3(s * 0.55, 2.6, s * 0.55), Basis(), 0.0)
		lm.box("Stone", tc + Vector3(0, 3.15, 0), Vector3(s, 0.5, s))
		lm.box("Stucco", tc + Vector3(0, 3.6, 0), Vector3(s + 0.8, 0.4, s + 0.8))
		y += 3.5
	LandmarkNaParts.hip(lm, "Roof", pc + Vector3(-4.0, y + 0.3, 3.0), Basis(), 3.4, 3.4, 0.45, 1.9)

## Tikal, Temple I (Temple of the Great Jaguar): the nine-tiered
## pyramid (33 m), every body in the Peten manner with inset corners and
## a projecting apron moulding, the steep central stair, the shrine of
## three rooms in tandem behind a single doorway with its sapodilla
## lintel, and the tall roof comb of two parallel walls with a vaulted
## hollow between, stepped back in three stages and carrying the
## king's seated figure between scrolls on its front, to 47 m. Built
## facing +Z; the real stair faces west onto the Great Plaza.
static func tikal_temple_i(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#B8AE97", 3.0))
	lm.use("Steps", LandmarkMaterials.pbr("limestone", "#C8BFA8", 3.0))
	lm.use("Stucco", LandmarkMaterials.pbr("render", "#D3CAB1", 3.0))
	lm.use("Door", LandmarkMaterials.glass("#1F2528"))
	lm.use("Wood", LandmarkMaterials.pbr("wood", "#6B4E35", 2.0))
	var py := 33.0
	var th := py / 9.0
	for k in 9:
		var hx := 16.0 - float(k)
		var hz := 18.0 - 1.33 * float(k)
		var y := th * float(k)
		var inset := 1.1
		# Two crossed bodies leave the corners inset.
		LandmarkAmhParts.slab(lm, "Stone", Vector3(0, y, 0), th, hx, hz - inset, hx - 0.4,
			hz - inset - 0.5)
		LandmarkAmhParts.slab(lm, "Stone", Vector3(0, y, 0), th, hx - inset, hz, hx - inset - 0.4,
			hz - 0.5)
		# Apron moulding: a band leaning out over the lower face.
		var ay := y + th * 0.52
		var ax := hx - 0.4 * 0.52
		var az := hz - 0.5 * 0.52
		LandmarkAmhParts.slab(lm, "Stucco", Vector3(0, ay, 0), 0.55, ax, az - inset, ax + 0.3,
			az - inset + 0.3)
		LandmarkAmhParts.slab(lm, "Stucco", Vector3(0, ay, 0), 0.55, ax - inset, az, ax - inset + 0.3,
			az + 0.3)
		lm.box("Stucco", Vector3(0, ay + 0.6, 0),
			Vector3(2.0 * (ax - inset) + 0.6, 0.1, 2.0 * az + 0.6), Basis(), 0.0)
	# Basal platform with its three steps toward the plaza.
	LandmarkAmhParts.slab(lm, "Stone", Vector3.ZERO, 0.9, 17.4, 19.4, 17.2, 19.2)
	LandmarkAmhParts.stair(lm, "Steps", Vector3.ZERO, Basis(), 12.0, 20.6, 0.0, 19.4, 0.9, 18.6, 3)
	LandmarkAmhParts.stair(lm, "Steps", Vector3.ZERO, Basis(), 8.4, 18.7, 0.9, 6.2, py, 3.0, 64)
	LandmarkAmhParts.rails(lm, "Stone", Vector3.ZERO, Basis(), 8.4, 18.7, 0.9, 6.2, py, 1.8, 1.6)
	lm.box("Stone", Vector3(0, py + 0.45, -0.9), Vector3(13.8, 0.9, 10.4))
	var sc := Vector3(0, py + 0.9, -1.8)
	_tikal_shrine(lm, sc)
	_tikal_comb(lm, sc + Vector3(0, 7.4, 0))
	lm.commit(model)

## The summit shrine at `sc` (floor centre): walls with a basal
## moulding, the doorway and its wooden lintel, the medial moulding,
## the upper frieze with its apron and the overhanging cornice.
static func _tikal_shrine(lm: LandmarkMesh, sc: Vector3) -> void:
	lm.box("Stone", sc + Vector3(0, 2.65, 0), Vector3(11.6, 5.3, 7.4))
	lm.box("Stucco", sc + Vector3(0, 0.25, 0), Vector3(12.0, 0.5, 7.8))
	LandmarkAmhParts.opening(lm, "Door", sc + Vector3(0, 1.6, 3.7), Basis(), 2.1, 3.2, 0.3)
	lm.box("Door", sc + Vector3(0, 1.4, 1.5), Vector3(1.6, 2.8, 4.0), Basis(), 0.0)
	for j in 3:
		lm.box("Wood", sc + Vector3(0, 3.3 + 0.18 * float(j), 3.72), Vector3(2.9, 0.16, 0.25), Basis(),
			0.0)
	for sx in [-1.0, 1.0]:
		lm.box("Stone", sc + Vector3(sx * 1.35, 1.6, 3.75), Vector3(0.5, 3.2, 0.15), Basis(), 0.0)
	lm.box("Stucco", sc + Vector3(0, 3.95, 0), Vector3(12.2, 0.4, 8.0))
	LandmarkAmhParts.slab(lm, "Stone", sc + Vector3(0, 4.15, 0), 1.25, 5.9, 3.8, 6.15, 4.05)
	lm.box("Stucco", sc + Vector3(0, 5.7, 0), Vector3(12.6, 0.6, 8.4))
	lm.box("Stone", sc + Vector3(0, 6.7, 0), Vector3(9.6, 1.4, 6.0))

## The roof comb from `cb` (its foot on the shrine roof): three stages
## of twin walls, each wall pierced by a row of vents between its ribs,
## the vaulted hollow between them, set-back mouldings, and on the front
## the seated king framed by scrolls.
static func _tikal_comb(lm: LandmarkMesh, cb: Vector3) -> void:
	var stages := [[8.6, 2.1, 3.6], [7.4, 2.0, 3.0], [6.2, 1.6, 2.4]]
	var y := 0.0
	for st in stages:
		var w: float = st[0]
		var h: float = st[1]
		var d: float = st[2]
		for s in [-1.0, 1.0]:
			var z: float = s * (d * 0.5 - 0.35)
			lm.box("Stone", cb + Vector3(0, y + h * 0.15, z), Vector3(w, h * 0.3, 0.7))
			lm.box("Stone", cb + Vector3(0, y + h * 0.85, z), Vector3(w, h * 0.3, 0.7))
			var ribs := int(w / 1.4)
			for i in ribs + 1:
				var x := -w * 0.5 + 0.3 + (w - 0.6) * float(i) / float(ribs)
				lm.box("Stone", cb + Vector3(x, y + h * 0.5, z), Vector3(0.6, h * 0.4, 0.7))
		lm.box("Door", cb + Vector3(0, y + h * 0.5, 0), Vector3(w - 0.4, h * 0.4, d - 1.4), Basis(),
			0.0)
		for sx in [-1.0, 1.0]:
			lm.box("Stone", cb + Vector3(sx * (w * 0.5 - 0.35), y + h * 0.5, 0),
				Vector3(0.7, h, d - 1.2))
		lm.box("Stucco", cb + Vector3(0, y + h - 0.1, 0), Vector3(w + 0.8, 0.2, d + 0.6))
		y += h
	lm.box("Stone", cb + Vector3(0, y - 0.05, 0), Vector3(6.4, 0.1, 2.6), Basis(), 0.0)
	# Armature stones: rows of tenons that held the comb's stucco relief.
	var ty := 0.0
	for st in stages:
		var w: float = st[0]
		var h: float = st[1]
		var d: float = st[2]
		for s in [-1.0, 1.0]:
			for k in 2:
				var n := int(w / 0.8)
				for i in n:
					var x := -w * 0.5 + 0.8 * (float(i) + 0.5)
					lm.box("Stone",
						cb + Vector3(x, ty + h * (0.3 + 0.4 * float(k)), s * (d * 0.5 + 0.12)),
						Vector3(0.25, 0.25, 0.25), Basis(), 0.0)
		ty += h
	# The seated king on the front of the first two stages.
	var f := cb + Vector3(0, 0.2, 1.85)
	lm.box("Stucco", f + Vector3(0, 0.35, 0.1), Vector3(3.2, 0.7, 0.5))
	lm.box("Stucco", f + Vector3(0, 0.95, 0.15), Vector3(2.6, 0.5, 0.6))
	lm.box("Stucco", f + Vector3(0, 1.75, 0.15), Vector3(1.4, 1.3, 0.5))
	for sx in [-1.0, 1.0]:
		lm.beam("Stucco", f + Vector3(sx * 0.7, 2.3, 0.2), f + Vector3(sx * 1.3, 1.5, 0.45), 0.35, 0.35)
	lm.box("Stucco", f + Vector3(0, 2.75, 0.2), Vector3(0.8, 0.8, 0.6))
	lm.box("Stucco", f + Vector3(0, 3.4, 0.15), Vector3(1.8, 0.5, 0.5))
	lm.box("Stucco", f + Vector3(0, 3.85, 0.05), Vector3(2.6, 0.4, 0.4))
	for sx in [-1.0, 1.0]:
		for j in 3:
			var c := f + Vector3(sx * (2.4 + 0.25 * float(j)), 0.9 + 1.0 * float(j), 0.1)
			lm.box("Stucco", c, Vector3(0.9, 0.25, 0.3), Basis(), 0.0)
			lm.box("Stucco", c + Vector3(sx * 0.35, 0.3, 0), Vector3(0.25, 0.6, 0.3), Basis(), 0.0)
			lm.box("Stucco", c + Vector3(0, 0.5, 0), Vector3(0.6, 0.2, 0.3), Basis(), 0.0)
