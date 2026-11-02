class_name LandmarkNaFrontenac
extends RefCounted

## Quebec City's Château Frontenac in true metres; the river front is
## +Z (the registry turns it to face the St Lawrence).

const TOP_M := 79.9
const TOWER_WALLS_M := 56.0
const STOREY_M := 3.6

## Château Frontenac (Bruce Price 1893, Maxwell wings 1908-24, central
## tower 1924): the Châteauesque horseshoe of steep green copper roofs
## on Glenboig brick walls over a grey ashlar base, the long river wing
## (+Z) and the two wings swept back from it round the courtyard, every
## storey of windows in real openings, corbelled eaves, two tiers of
## stone-gabled dormers, tall chimneys and ridge cresting; round
## turrets with conical caps at the corners; and the 17-storey central
## tower under its steep hipped roof with dormers and corner bartizans,
## to 79.9 m.
static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#B09A74", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#CFC6B2", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("slate", "#5F8B78", 2.0))
	lm.use("Windows", LandmarkMaterials.glass("#2A3236"))
	lm.use("Iron", LandmarkMaterials.paint("#2F3A36", 0.6, 0.4))
	_wing(lm, Vector3(0, 0, 4.0), Vector2(94.0, 22.0), 38.0, 18.0, true)
	_wing(lm, Vector3(-42.0, 0, -32.0), Vector2(20.0, 56.0), 34.0, 15.0, false)
	_wing(lm, Vector3(42.0, 0, -32.0), Vector2(20.0, 56.0), 34.0, 15.0, false)
	_tower(lm, Vector3(0, 0, 8.0))
	# Round turrets at the wing corners, with conical copper caps.
	for p in [Vector3(-47.0, 0, 15.0), Vector3(47.0, 0, 15.0), Vector3(-52.0, 0, -58.0),
			Vector3(52.0, 0, -58.0), Vector3(-14.0, 0, 15.6), Vector3(14.0, 0, 15.6)]:
		_turret(lm, p, 4.2, 44.0, 15.0)
	lm.commit(model)

## One storeyed wing at `c` (size X x Z): ashlar base, brick walls with
## a real window opening per bay and storey on every face, string
## courses, corbelled eaves, the steep hipped copper roof with two tiers
## of dormers on the long slopes, chimneys and ridge cresting. `front`
## leaves the inner (-Z) face of the river wing to the courtyard.
static func _wing(lm: LandmarkMesh, c: Vector3, size: Vector2, walls: float, rise: float, front: bool) -> void:
	var skin := 0.3
	lm.box("Brick", c + Vector3(0, walls * 0.5, 0), Vector3(size.x - skin * 2.0, walls, size.y - skin * 2.0))
	var storeys := floori((walls - 1.0) / STOREY_M)
	for q in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * q)
		var long := q % 2 == 0
		var span: float = size.x if long else size.y
		var face: float = size.y * 0.5 if long else size.x * 0.5
		var n := r * Vector3(0, 0, 1)
		var right := r * Vector3(-1, 0, 0)
		var o := c + n * (face - skin) - right * span * 0.5
		var bays := maxi(3, floori(span / 4.2))
		# Ground storeys in grey ashlar, the rest in brick.
		LandmarkDetail.pierced_face(lm, "Trim", "Windows", o, right, n, span, STOREY_M * 2.0, bays, 2,
			Vector2(1.4, 2.2), 0.9, STOREY_M, skin)
		LandmarkDetail.pierced_face(lm, "Brick", "Windows", o + Vector3(0, STOREY_M * 2.0, 0), right, n, span,
			walls - STOREY_M * 2.0, bays, storeys - 2, Vector2(1.2, 2.0), 0.9, STOREY_M, skin)
		var basis := Basis(right, Vector3.UP, n)
		# String courses at the base top and two thirds up.
		for y in [STOREY_M * 2.0, STOREY_M * float(floori(storeys * 0.66))]:
			lm.box("Trim", o + right * span * 0.5 + n * (skin + 0.12) + Vector3(0, y, 0),
				Vector3(span + 0.4, 0.35, 0.3), basis, 0.0)
		# Corbelled eaves: a row of stone corbels under the cornice.
		var nc := int(span / 1.1)
		for k in nc:
			lm.box("Trim", o + right * span * (float(k) + 0.5) / float(nc) + n * (skin + 0.25)
				+ Vector3(0, walls - 0.9, 0), Vector3(0.35, 0.7, 0.5), basis, 0.0)
		lm.box("Trim", o + right * span * 0.5 + n * (skin + 0.35) + Vector3(0, walls - 0.3, 0),
			Vector3(span + 0.8, 0.6, 0.8), basis, 0.0)
	var hx := size.x * 0.5 + 0.8
	var hz := size.y * 0.5 + 0.8
	var k := 0.3
	LandmarkNaParts.hip(lm, "Roof", c + Vector3(0, walls, 0), Basis(), hx, hz, k, rise)
	# Ridge cresting along the flat top.
	var top := c + Vector3(0, walls + rise, 0)
	var rl := (hx if size.x > size.y else hz) * k * 2.0
	var along := Vector3.RIGHT if size.x > size.y else Vector3.BACK
	lm.beam("Iron", top - along * rl * 0.5 + Vector3(0, 0.6, 0), top + along * rl * 0.5 + Vector3(0, 0.6, 0), 0.1, 0.1)
	var ncr := int(rl / 0.8)
	for i in ncr + 1:
		var p := top - along * rl * 0.5 + along * rl * float(i) / float(ncr)
		lm.box("Iron", p + Vector3(0, 0.35, 0), Vector3(0.06, 0.7, 0.06), Basis(), 0.0)
	# Dormers: two tiers on both long slopes (and the short ones).
	for q in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * q)
		var long := (q % 2 == 0) == (size.x > size.y)
		var half: float = (hx if q % 2 == 0 else hz)
		var face: float = (hz if q % 2 == 0 else hx)
		for tier in 2:
			var t := 0.18 + 0.36 * float(tier)
			var fd: float = face * (1.0 - t * (1.0 - k))
			var hw: float = half * (1.0 - t * (1.0 - k)) - 2.5
			var nd := maxi(1, floori(hw * 2.0 / (5.0 + 2.0 * tier))) if long else 1
			if not long and tier == 1:
				continue
			for i in nd:
				var x := -hw + hw * 2.0 * (float(i) + 0.5) / float(nd)
				_dormer(lm, c + r * Vector3(x, walls + rise * t, fd - 0.6), r, 1.0 - 0.25 * tier)
	# Tall chimneys rising through the slopes.
	var nch := maxi(2, floori(maxf(size.x, size.y) / 16.0))
	for i in nch:
		var t := (float(i) + 0.5) / float(nch) - 0.5
		var p := c + (along * t * maxf(size.x, size.y) * 0.75)
		for s in [-1.0, 1.0]:
			var off: Vector3 = along.cross(Vector3.UP) * float(s) * minf(size.x, size.y) * 0.2
			lm.box("Brick", p + off + Vector3(0, walls + rise * 0.7, 0), Vector3(1.6, rise * 0.8, 1.2))
			lm.box("Trim", p + off + Vector3(0, walls + rise * 1.1 + 0.2, 0), Vector3(2.0, 0.4, 1.6), Basis(), 0.0)
			for f in 2:
				lm.frustum("Brick", p + off + Vector3(-0.4 + 0.8 * f, walls + rise * 1.1 + 0.4, 0), 0.25, 0.2, 0.8, 6)
	if front:
		# Porte-cochère arches on the courtyard side of the river wing.
		for x in [-24.0, 24.0]:
			LandmarkDetail.arch(lm, "Trim", c + Vector3(x, 3.4, -size.y * 0.5), Vector3.FORWARD, 4.8, 0.7, 0.5)

## A dormer at `p` (foot of its front on the slope) facing r's +Z:
## stone front with a window, a steep gable and a finial.
static func _dormer(lm: LandmarkMesh, p: Vector3, r: Basis, s: float) -> void:
	var w := 2.6 * s
	var h := 3.2 * s
	lm.box("Trim", p + Vector3(0, h * 0.5, 0) - r.z * 1.0, Vector3(w, h, 2.2), r)
	lm.box("Windows", p + Vector3(0, h * 0.45, 0) + r.z * 0.12, Vector3(w * 0.5, h * 0.6, 0.06), r, 0.0)
	lm.box("Trim", p + Vector3(0, h * 0.13, 0) + r.z * 0.2, Vector3(w * 0.7, 0.18, 0.3), r, 0.0)
	lm.gable("Roof", p + Vector3(0, h, 0) - r.z * 1.0, w, 2.2, w * 0.9, Basis(r.x, Vector3.UP, r.z), 0.15, "Trim")
	lm.frustum("Iron", p + Vector3(0, h + w * 0.9, 0) + r.z * 0.1, 0.06, 0.02, 0.9, 4)

## A round turret of radius rr at `p`: brick drum with ringed windows
## and string courses, a corbelled cornice, the conical copper cap and
## its finial.
static func _turret(lm: LandmarkMesh, p: Vector3, rr: float, walls: float, cap: float) -> void:
	lm.frustum("Trim", p, rr + 0.15, rr + 0.15, STOREY_M * 2.0, 20)
	lm.frustum("Brick", p + Vector3(0, STOREY_M * 2.0, 0), rr, rr, walls - STOREY_M * 2.0, 20)
	var floors := floori(walls / STOREY_M)
	for f in floors:
		for i in 4:
			var a := TAU * (float(i) + 0.5 * float(f % 2)) / 4.0 + 0.4
			var d := Vector3(cos(a), 0, sin(a))
			var b := Basis.looking_at(-d)
			var c := p + d * (rr + 0.05) + Vector3(0, STOREY_M * float(f) + 1.9, 0)
			lm.box("Windows", c, Vector3(0.9, 1.6, 0.1), b, 0.0)
			lm.box("Trim", c + Vector3(0, -0.9, 0) + d * 0.1, Vector3(1.2, 0.2, 0.3), b, 0.0)
			lm.box("Trim", c + Vector3(0, 0.9, 0) + d * 0.08, Vector3(1.2, 0.2, 0.25), b, 0.0)
	LandmarkNaParts.ring(lm, "Trim", p + Vector3(0, STOREY_M * 2.0, 0), rr + 0.1, 0.4, 0.4, 20)
	lm.lathe("Trim", p + Vector3(0, walls - 1.2, 0), PackedVector2Array([Vector2(rr, 0.0), Vector2(rr + 0.3, 0.5),
		Vector2(rr + 0.5, 1.0), Vector2(rr + 0.5, 1.2)]), 20)
	lm.lathe("Roof", p + Vector3(0, walls, 0), PackedVector2Array([Vector2(rr + 0.8, 0.0),
		Vector2(rr * 0.75, cap * 0.35), Vector2(rr * 0.35, cap * 0.75), Vector2(0.0, cap)]), 20)
	lm.frustum("Iron", p + Vector3(0, walls + cap - 0.3, 0), 0.12, 0.03, 2.2, 6)

## The 1924 central tower at `c`: ashlar base, 15 brick storeys of
## windows, the corbelled cornice, corner bartizans with conical caps,
## and the steep hipped roof with three tiers of dormers and the
## finial to 79.9 m.
static func _tower(lm: LandmarkMesh, c: Vector3) -> void:
	var sx := 24.0
	var sz := 22.0
	var skin := 0.3
	lm.box("Brick", c + Vector3(0, TOWER_WALLS_M * 0.5, 0), Vector3(sx - skin * 2.0, TOWER_WALLS_M, sz - skin * 2.0))
	for q in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * q)
		var span: float = sx if q % 2 == 0 else sz
		var face: float = sz * 0.5 if q % 2 == 0 else sx * 0.5
		var n := r * Vector3(0, 0, 1)
		var right := r * Vector3(-1, 0, 0)
		var o := c + n * (face - skin) - right * span * 0.5
		# The river face rises clear of the wing from the ground.
		var y0 := 0.0 if q == 0 else 38.0
		LandmarkDetail.pierced_face(lm, "Brick", "Windows", o + Vector3(0, y0, 0), right, n, span,
			TOWER_WALLS_M - y0, 5, floori((TOWER_WALLS_M - y0) / STOREY_M), Vector2(1.3, 2.1), 0.9, STOREY_M, skin)
		var basis := Basis(right, Vector3.UP, n)
		for k in 3:
			lm.box("Trim", o + right * span * 0.5 + n * (skin + 0.12) + Vector3(0, 38.0 + 6.0 * k, 0),
				Vector3(span + 0.4, 0.35, 0.3), basis, 0.0)
		var nc := int(span / 1.0)
		for k in nc:
			lm.box("Trim", o + right * span * (float(k) + 0.5) / float(nc) + n * (skin + 0.3)
				+ Vector3(0, TOWER_WALLS_M - 1.0, 0), Vector3(0.35, 0.9, 0.6), basis, 0.0)
		lm.box("Trim", o + right * span * 0.5 + n * (skin + 0.4) + Vector3(0, TOWER_WALLS_M - 0.3, 0),
			Vector3(span + 1.0, 0.6, 1.0), basis, 0.0)
	# Corner bartizans corbelled out from the top storeys.
	for qx in [-1.0, 1.0]:
		for qz in [-1.0, 1.0]:
			var p := c + Vector3(qx * (sx * 0.5 + 0.4), TOWER_WALLS_M - 9.0, qz * (sz * 0.5 + 0.4))
			lm.lathe("Trim", p - Vector3(0, 2.5, 0), PackedVector2Array([Vector2(0.3, 0.0), Vector2(1.2, 1.2),
				Vector2(2.0, 2.5)]), 16)
			lm.frustum("Brick", p, 2.0, 2.0, 9.0, 16)
			for i in 3:
				var a := TAU * float(i) / 3.0 + atan2(qz, qx) - TAU / 3.0
				var d := Vector3(cos(a), 0, sin(a))
				lm.box("Windows", p + d * 2.02 + Vector3(0, 4.5, 0), Vector3(0.7, 1.8, 0.1), Basis.looking_at(-d), 0.0)
			lm.lathe("Roof", p + Vector3(0, 9.0, 0), PackedVector2Array([Vector2(2.5, 0.0), Vector2(1.6, 3.0),
				Vector2(0.7, 6.0), Vector2(0.0, 8.0)]), 16)
			lm.frustum("Iron", p + Vector3(0, 16.8, 0), 0.1, 0.03, 1.6, 6)
	var hx := sx * 0.5 + 0.9
	var hz := sz * 0.5 + 0.9
	var k := 0.16
	var rise := TOP_M - 2.6 - TOWER_WALLS_M
	LandmarkNaParts.hip(lm, "Roof", c + Vector3(0, TOWER_WALLS_M, 0), Basis(), hx, hz, k, rise)
	for q in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * q)
		var half: float = hx if q % 2 == 0 else hz
		var face: float = hz if q % 2 == 0 else hx
		for tier in 3:
			var t := 0.12 + 0.25 * float(tier)
			var fd: float = face * (1.0 - t * (1.0 - k))
			var hw: float = half * (1.0 - t * (1.0 - k)) - 2.2
			var nd := 3 - tier
			for i in nd:
				var x := 0.0 if nd == 1 else -hw + hw * 2.0 * float(i) / float(nd - 1)
				_dormer(lm, c + r * Vector3(x * 0.7, TOWER_WALLS_M + rise * t, fd - 0.6), r, 1.0 - 0.2 * tier)
	var tp := c + Vector3(0, TOWER_WALLS_M + rise, 0)
	lm.box("Roof", tp + Vector3(0, 0.3, 0), Vector3(hx * k * 2.0, 0.6, hz * k * 2.0))
	lm.frustum("Iron", tp + Vector3(0, 0.6, 0), 0.25, 0.04, TOP_M - tp.y - 0.6, 6)
