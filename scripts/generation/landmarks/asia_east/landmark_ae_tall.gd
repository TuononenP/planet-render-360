class_name LandmarkAeTall
extends RefCounted

## Tall landmarks of Japan and Korea in true metres: Tokyo Skytree
## (634 m: a steel-pipe truss whose plan turns from the 68 m triangle of
## its three legs into a circle by 300 m, round the concrete
## shinbashira core; the Tembo Deck at 340-350 m, the Tembo Galleria at
## 445-450 m and the lattice gain tower), N Seoul Tower (236.7 m: the
## concrete shaft, a four-level glazed pod with the revolving
## restaurant, and the antenna mast with its platforms) and Lotte World
## Tower (555 m: a rounded square tapering like a brush, light seams
## down its four corners, mega-truss belts, curtain-wall bands and the
## open diagrid lantern of its crown).

# --- Tokyo Skytree ---

const SKYTREE_M := 634.0
const TRIPOD_M := 300.0
const TRUSS_TOP := 495.0
const TRUSS_PTS := 24
## Truss radius above the tripod: (height, radius).
static var SKYTREE_R := PackedVector2Array([Vector2(300, 14.0), Vector2(338, 14.5),
	Vector2(362, 11.5), Vector2(440, 8.4), Vector2(456, 7.2), Vector2(495, 5.0)])

static func skytree(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Frame", LandmarkMaterials.paint("#D3DDE6", 0.45, 0.4))
	lm.use("Deck", LandmarkMaterials.glass("#8CA3B3"))
	lm.use("Podium", LandmarkMaterials.pbr("concrete", "#C8C5BC", 4.0))
	# The three great leg pipes up the tripod's corners.
	var steps := 12
	for k in steps:
		var y0 := TRIPOD_M * k / steps
		var y1 := TRIPOD_M * (k + 1) / steps
		for i in 3:
			LandmarkAeParts.tube(lm, "Frame", _leg(i, maxf(y0, 1.5)), _leg(i, y1),
				3.2 - 1.4 * y0 / TRIPOD_M, 3.2 - 1.4 * y1 / TRIPOD_M, 12)
	# Diamond truss: diagonals both ways in every cell and a ring beam at
	# every level, from the triangle at the foot to the circle above.
	var levels := 34
	var prev := _truss_ring(1.5)
	for k in range(1, levels + 1):
		var y := TRUSS_TOP * float(k) / levels
		var cur := _truss_ring(y)
		var w := lerpf(1.1, 0.6, y / TRUSS_TOP)
		for j in TRUSS_PTS:
			var j1 := (j + 1) % TRUSS_PTS
			lm.beam("Frame", prev[j], cur[j1], w, w)
			lm.beam("Frame", prev[j1], cur[j], w, w)
			lm.beam("Frame", cur[j], cur[j1], w * 1.2, w)
		prev = cur
	# Shinbashira core, the Tembo Deck, the Galleria and the gain tower.
	lm.frustum("Podium", Vector3.ZERO, 5.0, 4.0, 375.0, 16)
	lm.frustum("Podium", Vector3(0, 300.0, 0), 11.0, 10.0, 40.0, 24)
	_deck(lm, 340.0, [Vector2(14.0, 0), Vector2(22.0, 3.0), Vector2(24.0, 8.0), Vector2(24.0, 14.0),
		Vector2(17.0, 19.0), Vector2(11.0, 20.0)], [4.5, 9.5, 14.5])
	lm.frustum("Podium", Vector3(0, 360.0, 0), 7.5, 6.0, 85.0, 20)
	_deck(lm, 443.0, [Vector2(7.0, 0), Vector2(12.5, 3.0), Vector2(13.0, 8.0), Vector2(8.0, 12.0)], [4.0, 8.0])
	_gain_tower(lm, TRUSS_TOP, SKYTREE_M)
	# Low triangular base building between the legs.
	var tri := PackedVector2Array()
	for i in 3:
		var a := TAU * i / 3.0 + PI * 0.5
		tri.append(Vector2(cos(a), sin(a)) * 30.0)
	lm.poly_prism("Podium", tri, 0.0, 9.0)
	lm.commit(model)

## Leg i of the tripod at height y: 39 m radius at the ground, 14 m at 300 m.
static func _leg(i: int, y: float) -> Vector3:
	var r := 14.0 + 25.0 * pow(1.0 - y / TRIPOD_M, 1.6)
	var a := TAU * i / 3.0 + PI * 0.5
	return Vector3(r * cos(a), y, r * sin(a))

## The truss ring at height y: points on the leg triangle low down,
## blended to a circle by the top of the tripod.
static func _truss_ring(y: float) -> PackedVector3Array:
	var out := PackedVector3Array()
	var R := 14.0 + 25.0 * pow(maxf(1.0 - y / TRIPOD_M, 0.0), 1.6)
	if y > TRIPOD_M:
		R = LandmarkMesh.profile_at(SKYTREE_R, y)
	var b := smoothstep(0.0, TRIPOD_M, y)
	for j in TRUSS_PTS:
		var th := TAU * float(j) / TRUSS_PTS + PI * 0.5
		var rel := fposmod(th - PI * 0.5, TAU / 3.0) - PI / 3.0
		var tri := R * 0.5 / cos(rel)
		var r := lerpf(tri, R, b)
		out.append(Vector3(r * cos(th), y, r * sin(th)))
	return out

## Observation deck: a glazed lathe from `prof` at y with frame rims at
## each floor offset in `floors`.
static func _deck(lm: LandmarkMesh, y: float, prof: Array, floors: Array) -> void:
	var p := PackedVector2Array()
	for v in prof:
		p.append(v)
	lm.lathe("Deck", Vector3(0, y, 0), p, 40)
	var rmax := 0.0
	for v in prof:
		rmax = maxf(rmax, (v as Vector2).x)
	for f in floors:
		lm.frustum("Frame", Vector3(0, y + float(f), 0), rmax + 0.25, rmax + 0.25, 0.5, 40)
	for i in 24:
		var a := TAU * float(i) / 24.0
		var d := Vector3(cos(a), 0, sin(a))
		lm.beam("Frame", d * (rmax + 0.1) + Vector3(0, y + 3.0, 0), d * (rmax + 0.1) + Vector3(0, y + float(floors[floors.size() - 1]) + 0.5, 0),
			0.35, 0.3, d.cross(Vector3.UP))

## The gain tower: a square lattice mast from y0 to the top, tapering,
## X-braced on each face, with antenna platforms.
static func _gain_tower(lm: LandmarkMesh, y0: float, y1: float) -> void:
	var cells := 10
	for k in cells:
		var a0 := lerpf(y0, y1 - 12.0, float(k) / cells)
		var a1 := lerpf(y0, y1 - 12.0, float(k + 1) / cells)
		var h0 := lerpf(4.5, 1.4, float(k) / cells)
		var h1 := lerpf(4.5, 1.4, float(k + 1) / cells)
		var c0 := [Vector3(-h0, a0, -h0), Vector3(h0, a0, -h0), Vector3(h0, a0, h0), Vector3(-h0, a0, h0)]
		var c1 := [Vector3(-h1, a1, -h1), Vector3(h1, a1, -h1), Vector3(h1, a1, h1), Vector3(-h1, a1, h1)]
		for f in 4:
			lm.lattice_panel("Frame", c0[f], c0[(f + 1) % 4], c1[f], c1[(f + 1) % 4], 0.3, 1)
			lm.beam("Frame", c0[f], c1[f], 0.6, 0.6)
		if k % 3 == 1:
			lm.frustum("Frame", Vector3(0, a0, 0), h0 * 1.7, h0 * 1.7, 0.8, 16)
	lm.lathe("Frame", Vector3(0, y1 - 12.0, 0), PackedVector2Array([Vector2(1.0, 0), Vector2(0.3, 12.0)]), 8)
	lm.frustum("Podium", Vector3(0, y0, 0), 3.2, 1.2, y1 - y0 - 14.0, 12)

# --- N Seoul Tower ---

const SEOUL_M := 236.7

static func n_seoul(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Shaft", LandmarkMaterials.pbr("concrete", "#D8D5CE", 4.0))
	lm.use("Pod", LandmarkMaterials.glass("#74899A"))
	lm.use("Mast", LandmarkMaterials.paint("#E6E6E2", 0.4, 0.5))
	# N Plaza base building round the foot.
	lm.frustum("Shaft", Vector3.ZERO, 16.0, 15.0, 6.0, 32)
	lm.frustum("Pod", Vector3(0, 6.0, 0), 13.5, 13.5, 4.0, 32)
	lm.frustum("Shaft", Vector3(0, 10.0, 0), 14.0, 14.0, 0.8, 32)
	lm.frustum("Shaft", Vector3(0, 0, 0), 6.2, 4.4, 100.0, 24)
	# Four fins up the shaft.
	for i in 4:
		var a := PI * 0.5 * i
		var d := Vector3(cos(a), 0, sin(a))
		lm.beam("Shaft", d * 6.0 + Vector3(0, 10.8, 0), d * 4.3 + Vector3(0, 95.0, 0), 0.8, 1.2, d.cross(Vector3.UP))
	# Observation pod: lower rim, four glazed floors, the crown.
	lm.lathe("Shaft", Vector3(0, 95.0, 0), PackedVector2Array([Vector2(4.4, 0), Vector2(10.5, 3.0),
		Vector2(17.0, 7.5)]), 32)
	lm.lathe("Pod", Vector3(0, 102.5, 0), PackedVector2Array([Vector2(17.5, 0), Vector2(17.5, 14.5),
		Vector2(15.0, 20.5), Vector2(9.0, 24.5), Vector2(4.0, 27.5)]), 32)
	for k in 5:
		lm.frustum("Mast", Vector3(0, 102.5 + 3.6 * k, 0), 17.8, 17.8, 0.5, 32)
	for i in 32:
		var a := TAU * float(i) / 32.0
		var d := Vector3(cos(a), 0, sin(a))
		lm.beam("Mast", d * 17.6 + Vector3(0, 102.5, 0), d * 17.6 + Vector3(0, 117.0, 0), 0.25, 0.3, d.cross(Vector3.UP))
	lm.frustum("Shaft", Vector3(0, 125.0, 0), 4.0, 3.4, 15.0, 20)
	# Antenna mast with its platforms.
	lm.lathe("Mast", Vector3(0, 140.0, 0), PackedVector2Array([Vector2(2.6, 0), Vector2(2.2, 30.0),
		Vector2(1.2, 70.0), Vector2(0.3, SEOUL_M - 140.0)]), 16)
	for p in [[165.0, 5.0], [178.0, 3.6], [190.0, 3.0], [205.0, 2.4], [218.0, 1.8]]:
		var py := float(p[0])
		var pr := float(p[1])
		lm.frustum("Mast", Vector3(0, py, 0), pr, pr, 1.2, 16)
		lm.frustum("Mast", Vector3(0, py + 1.2, 0), pr, pr * 0.85, 0.4, 16)
	lm.commit(model)

# --- Lotte World Tower ---

const LOTTE_M := 555.0
const LOTTE_PTS := 48
static var LOTTE_HW := PackedVector2Array([Vector2(0, 36.0), Vector2(0.1, 34.5),
	Vector2(0.3, 29.5), Vector2(0.5, 24.5), Vector2(0.75, 17.5), Vector2(0.9, 11.5),
	Vector2(0.97, 8.0), Vector2(1.0, 7.0)])

static func lotte(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Glass", LandmarkMaterials.glass("#8FA5B2"))
	lm.use("Frame", LandmarkMaterials.paint("#B7BEC3", 0.35, 0.8))
	lm.use("Beacon", LandmarkMaterials.lit("#CFE3F2", 0.9))
	lm.use("Podium", LandmarkMaterials.pbr("concrete", "#CBC7BE", 4.0))
	var rings: Array = []
	var slices := 48
	for k in slices + 1:
		rings.append(_lotte_ring(float(k) / slices, 1.0))
	LandmarkAeParts.loft(lm, "Glass", rings)
	# Mega-truss belts and curtain-wall bands every four floors.
	for f in [0.17, 0.34, 0.52, 0.7, 0.86]:
		LandmarkAeParts.loft(lm, "Frame", [_lotte_ring(f, 1.025), _lotte_ring(f + 5.0 / LOTTE_M, 1.025)], false)
	var y := 16.8
	while y < LOTTE_M * 0.9:
		var f := y / LOTTE_M
		LandmarkAeParts.loft(lm, "Frame", [_lotte_ring(f, 1.008), _lotte_ring(f + 0.5 / LOTTE_M, 1.008)], false)
		y += 16.8
	# Light seams down the four corners, from the foot to the lantern.
	for c in 4:
		var th := PI * 0.25 + PI * 0.5 * c
		var prev := _lotte_point(th, 0.02)
		for k in range(1, 25):
			var p := _lotte_point(th, 0.02 + 0.88 * float(k) / 24.0)
			lm.beam("Frame", prev, p, 1.6, 0.6, Vector3(cos(th), 0, sin(th)).cross(Vector3.UP))
			prev = p
	# The crown's open diagrid lantern over its last floors.
	var crown_rings := 4
	for k in crown_rings:
		var f0 := 0.9 + 0.1 * float(k) / crown_rings
		var f1 := 0.9 + 0.1 * float(k + 1) / crown_rings
		var r0 := _lotte_ring(f0, 1.03)
		var r1 := _lotte_ring(f1, 1.03)
		for j in range(0, LOTTE_PTS, 2):
			var j2 := (j + 2) % LOTTE_PTS
			lm.beam("Frame", r0[j], r1[j2], 0.5, 0.5)
			lm.beam("Frame", r0[j2], r1[j], 0.5, 0.5)
	# Lit slits down the four faces of the crown.
	var hw := LandmarkMesh.profile_at(LOTTE_HW, 0.96)
	for s in [-1.0, 1.0]:
		lm.box("Beacon", Vector3(s * hw, 536.0, 0), Vector3(1.4, 38.0, 6.0))
		lm.box("Beacon", Vector3(0, 536.0, s * hw), Vector3(6.0, 38.0, 1.4))
	lm.box("Podium", Vector3(0, 7.0, 0), Vector3(96.0, 14.0, 96.0))
	lm.commit(model)

## Rounded-square (superellipse) section at height fraction f.
static func _lotte_ring(f: float, grow: float) -> PackedVector3Array:
	var hw := LandmarkMesh.profile_at(LOTTE_HW, f) * grow
	var shape: Callable = func(th: float) -> float:
		return hw / pow(pow(absf(cos(th)), 3.5) + pow(absf(sin(th)), 3.5), 1.0 / 3.5)
	return LandmarkAeParts.ring(LOTTE_PTS, LOTTE_M * f, shape)

## The point on the superellipse at angle th and height fraction f,
## standing just proud of the glass.
static func _lotte_point(th: float, f: float) -> Vector3:
	var hw := LandmarkMesh.profile_at(LOTTE_HW, f) * 1.01
	var r := hw / pow(pow(absf(cos(th)), 3.5) + pow(absf(sin(th)), 3.5), 1.0 / 3.5)
	return Vector3(r * cos(th), LOTTE_M * f, r * sin(th))
