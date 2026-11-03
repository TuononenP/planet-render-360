class_name LandmarkSfTowers
extends RefCounted

## San Francisco's two skyline towers in true metres on LandmarkMesh,
## built about the tower's centre with y = 0 at the ground.

const SF_FLOORS := 60
const SF_FLOOR_M := 4.6
const SF_SHAFT_Y0 := 12.0
const SF_CROWN_Y := 288.0
const SF_TOP_M := 326.0
const SF_ARC := 5
const COIT_TOP_M := 64.0

## Salesforce Tower (2018, Pelli Clarke & Partners): a 326 m rounded
## square shaft tapering from about 50 m to 36 m across, 61 floors of
## blue-grey glass banded by aluminium spandrels and fine mullions, the
## lobby on slender inclined columns under a stone-rimmed canopy, and
## the open crown of aluminium fins that rises 38 m above the last floor
## round the lit "Day for Night" LED band.
static func salesforce_tower(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Glass", LandmarkMaterials.pbr("concrete", "#8BA5BA", 4.0, 0.22, 0.4))
	lm.use("Metal", LandmarkMaterials.paint("#AEB8BF", 0.4, 0.6))
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#B8B3A8", 3.0))
	lm.use("Light", LandmarkMaterials.lit("#E4EEFF", 0.7))
	# Floor rings: the shaft's plan at every slab level.
	var edge_y: Array[float] = []
	for i in SF_FLOORS + 1:
		edge_y.append(SF_SHAFT_Y0 + SF_FLOOR_M * float(i))
	for i in SF_FLOORS:
		var y0: float = edge_y[i]
		var vis := y0 + SF_FLOOR_M * 0.72
		var y1: float = edge_y[i + 1]
		_loft(lm, "Glass", _plan(y0, 0.0), _plan(vis, 0.0), y0, vis)
		_loft(lm, "Metal", _plan(vis, 0.22), _plan(y1, 0.22), vis, y1)
		_ledge(lm, "Metal", _plan(vis, 0.0), _plan(vis, 0.22), vis, Vector3.DOWN)
		_ledge(lm, "Metal", _plan(y1, 0.0), _plan(y1, 0.22), y1, Vector3.UP)
	_sf_mullions(lm, edge_y)
	# Lobby: glazed drum behind inclined columns, canopy slab and plinth.
	_loft(lm, "Glass", _plan(0.0, -1.0), _plan(SF_SHAFT_Y0, -1.0), 0.0, SF_SHAFT_Y0)
	var foot := _plan(0.0, 1.6)
	var head := _plan(SF_SHAFT_Y0 - 0.5, 0.2)
	for k in range(0, foot.size(), 2):
		var f := foot[k]
		var h := head[k]
		lm.beam("Metal", Vector3(f.x, 0.4, f.y), Vector3(h.x, SF_SHAFT_Y0 - 0.5, h.y), 0.8, 1.1)
	lm.poly_prism("Stone", _plan(0.0, 5.0), 0.0, 0.6)
	lm.poly_prism("Metal", _plan(SF_SHAFT_Y0, 1.6), SF_SHAFT_Y0 - 0.9, SF_SHAFT_Y0 + 0.1)
	# Crown: LED band, the dark service core and the fin screen.
	_loft(lm, "Light", _plan(SF_CROWN_Y, 0.1), _plan(SF_CROWN_Y + 3.2, 0.1), SF_CROWN_Y, SF_CROWN_Y + 3.2)
	lm.poly_prism("Glass", _plan(SF_CROWN_Y + 3.0, -3.5), SF_CROWN_Y, SF_TOP_M - 6.0)
	var top_ring := _plan(SF_TOP_M, 0.0)
	var base_ring := _plan(SF_CROWN_Y, 0.0)
	var pts := top_ring.size()
	for k in pts:
		for sub in 3:
			var t := float(sub) / 3.0
			var nk := (k + 1) % pts
			var b := base_ring[k].lerp(base_ring[nk], t)
			var u := top_ring[k].lerp(top_ring[nk], t)
			var out := Vector3(b.x, 0, b.y).normalized()
			var ytop := SF_TOP_M if (k * 3 + sub) % 2 == 0 else SF_TOP_M - 5.0
			var mid := Vector3((b.x + u.x) * 0.5, (SF_CROWN_Y + ytop) * 0.5, (b.y + u.y) * 0.5)
			lm.box("Metal", mid + out * 0.9, Vector3(0.28, ytop - SF_CROWN_Y, 2.6), Basis.looking_at(-out), 0.0)
	_loft(lm, "Metal", _plan(SF_TOP_M - 1.6, 0.4), _plan(SF_TOP_M, 0.4), SF_TOP_M - 1.6, SF_TOP_M)
	_ledge(lm, "Metal", _plan(SF_TOP_M, 0.0), _plan(SF_TOP_M, 0.4), SF_TOP_M, Vector3.UP)
	_ledge(lm, "Metal", _plan(SF_TOP_M - 1.6, 0.0), _plan(SF_TOP_M - 1.6, 0.4), SF_TOP_M - 1.6, Vector3.DOWN)
	lm.commit(model)

## Rounded-square plan at height y, grown by `off` metres: half-width
## 25 m at the foot easing in to 18 m at the crown, corner radius 11 m
## to 9 m. Always SF_ARC + 1 points per corner, counter-clockwise from +X.
static func _plan(y: float, off: float) -> PackedVector2Array:
	var k := clampf(y / SF_CROWN_Y, 0.0, 1.0)
	var hw := 25.0 - 7.0 * pow(k, 1.35) + off
	var r := maxf(11.0 - 2.0 * k + off, 0.5)
	var out := PackedVector2Array()
	for q in 4:
		var sx := 1.0 if (q == 0 or q == 3) else -1.0
		var sz := 1.0 if q < 2 else -1.0
		var c := Vector2(sx * (hw - r), sz * (hw - r))
		for j in SF_ARC + 1:
			var t := PI * 0.5 * (float(q) + float(j) / float(SF_ARC))
			out.append(c + Vector2(cos(t), sin(t)) * r)
	return out

## Faceted band between two plans (same point count) from ya to yb.
static func _loft(lm: LandmarkMesh, key: String, a: PackedVector2Array, b: PackedVector2Array,
		ya: float, yb: float) -> void:
	var n := a.size()
	for i in n:
		var j := (i + 1) % n
		var mid := (a[i] + a[j]) * 0.5
		var e := a[j] - a[i]
		var nn := Vector2(e.y, -e.x).normalized()
		if nn.dot(mid) < 0.0:
			nn = -nn
		var tilt := (mid.length() - ((b[i] + b[j]) * 0.5).length()) / maxf(yb - ya, 0.01)
		lm.quad(key, Vector3(a[i].x, ya, a[i].y), Vector3(a[j].x, ya, a[j].y),
			Vector3(b[j].x, yb, b[j].y), Vector3(b[i].x, yb, b[i].y), Vector3(nn.x, tilt, nn.y).normalized())

## Flat ring of quads between an inner and an outer plan at height y.
static func _ledge(lm: LandmarkMesh, key: String, inner: PackedVector2Array, outer: PackedVector2Array,
		y: float, normal: Vector3) -> void:
	var n := inner.size()
	for i in n:
		var j := (i + 1) % n
		lm.quad(key, Vector3(inner[i].x, y, inner[i].y), Vector3(inner[j].x, y, inner[j].y),
			Vector3(outer[j].x, y, outer[j].y), Vector3(outer[i].x, y, outer[i].y), normal)

## Mullions: eight slim aluminium members up each flat face, run in
## three-storey lengths so they follow the taper.
static func _sf_mullions(lm: LandmarkMesh, edge_y: Array[float]) -> void:
	var span := 3
	var cuts := 8
	for s in range(0, SF_FLOORS, span):
		var ra := _plan(edge_y[s], 0.14)
		var rb := _plan(edge_y[s + span], 0.14)
		for q in 4:
			var i0 := q * (SF_ARC + 1) + SF_ARC
			var i1 := ((q + 1) % 4) * (SF_ARC + 1)
			for m in range(1, cuts):
				var t := float(m) / float(cuts)
				var a := ra[i0].lerp(ra[i1], t)
				var b := rb[i0].lerp(rb[i1], t)
				lm.beam("Metal", Vector3(a.x, edge_y[s], a.y), Vector3(b.x, edge_y[s + span], b.y), 0.09, 0.2)

## Coit Tower (1933, Arthur Brown Jr. and Henry Howard): the 64 m
## unpainted-concrete Art Deco column on Telegraph Hill. The round lobby
## on its stepped terrace with four arched doors, the 24-flute shaft
## slimming upward, the open observation drum of eight arched
## loggias, the stepped cornice, slotted attic and flat cap.
static func coit_tower(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#D2CCBF", 2.5, 0.85))
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#A7A194", 3.0))
	lm.use("Dark", LandmarkMaterials.glass("#262B2F"))
	# Terrace: two stepped rings, then the lobby drum.
	lm.lathe("Stone", Vector3.ZERO, PackedVector2Array([Vector2(12.6, 0.0), Vector2(12.6, 0.7), Vector2(11.6, 0.7),
		Vector2(11.6, 1.4), Vector2(10.4, 1.4), Vector2(10.4, 2.0)]), 48, 1.0, 1.0, 0.0, false)
	var lobby_y := 2.0
	var lobby_top := 12.0
	lm.lathe("Concrete", Vector3(0, lobby_y, 0), PackedVector2Array([Vector2(8.8, 0.0), Vector2(8.8, lobby_top - lobby_y)]),
		48, 1.0, 1.0, 0.0, false)
	for k in 8:
		var a := TAU * float(k) / 8.0
		var d := Vector3(cos(a), 0, sin(a))
		var basis := Basis(Vector3.UP.cross(d).normalized(), Vector3.UP, d)
		if k % 2 == 0:
			# Arched door in a recessed frame.
			lm.box("Concrete", d * 8.9 + Vector3(0, lobby_y + 3.6, 0), Vector3(4.6, 7.2, 0.5), basis)
			lm.box("Dark", d * 9.2 + Vector3(0, lobby_y + 2.6, 0), Vector3(2.6, 5.2, 0.12), basis, 0.0)
			LandmarkDetail.arch(lm, "Concrete", d * 9.15 + Vector3(0, lobby_y + 5.2, 0), d, 2.6, 0.4, 0.3, 14)
			_arch_fill(lm, d * 9.2 + Vector3(0, lobby_y + 5.2, 0), d, 1.3)
		else:
			lm.box("Dark", d * 8.85 + Vector3(0, lobby_y + 6.0, 0), Vector3(1.0, 4.4, 0.16), basis, 0.0)
	lm.lathe("Concrete", Vector3(0, lobby_top, 0), PackedVector2Array([Vector2(9.3, 0.0), Vector2(9.3, 0.6),
		Vector2(8.4, 0.8), Vector2(8.4, 1.1), Vector2(5.4, 1.1)]), 48, 1.0, 1.0, 0.0, false)
	# Fluted shaft: 24 flutes, 4 points each, radius easing 4.9 -> 4.5.
	var shaft_y0 := lobby_top + 1.1
	var shaft_y1 := 49.0
	_fluted(lm, "Concrete", shaft_y0, shaft_y1, 4.9, 4.5, 24, 0.22)
	# Collar, observation drum with eight arched loggias, cornice.
	lm.lathe("Concrete", Vector3(0, shaft_y1, 0), PackedVector2Array([Vector2(4.6, 0.0), Vector2(5.5, 0.4),
		Vector2(5.5, 1.0), Vector2(5.9, 1.0), Vector2(5.9, 7.2)]), 48, 1.0, 1.0, 0.0, false)
	for k in 8:
		var a := TAU * (float(k) + 0.5) / 8.0
		var d := Vector3(cos(a), 0, sin(a))
		var basis := Basis(Vector3.UP.cross(d).normalized(), Vector3.UP, d)
		lm.box("Dark", d * 5.95 + Vector3(0, shaft_y1 + 3.5, 0), Vector3(1.9, 4.2, 0.2), basis, 0.0)
		LandmarkDetail.arch(lm, "Concrete", d * 5.95 + Vector3(0, shaft_y1 + 5.6, 0), d, 1.9, 0.3, 0.28, 12)
		_arch_fill(lm, d * 5.97 + Vector3(0, shaft_y1 + 5.6, 0), d, 0.95)
		# Pilaster between the loggias.
		var pa := TAU * float(k) / 8.0
		var pd := Vector3(cos(pa), 0, sin(pa))
		lm.box("Concrete", pd * 5.95 + Vector3(0, shaft_y1 + 3.6, 0), Vector3(1.1, 7.2, 0.5),
			Basis(Vector3.UP.cross(pd).normalized(), Vector3.UP, pd))
	var cor_y := shaft_y1 + 7.2
	lm.lathe("Concrete", Vector3(0, cor_y, 0), PackedVector2Array([Vector2(5.9, 0.0), Vector2(6.5, 0.3), Vector2(6.5, 0.9),
		Vector2(6.1, 1.0), Vector2(6.1, 1.6), Vector2(5.5, 1.6)]), 48, 1.0, 1.0, 0.0, false)
	# Attic: 16 slim slots, then the stepped cap to the 64 m top.
	var att_y := cor_y + 1.6
	lm.lathe("Concrete", Vector3(0, att_y, 0), PackedVector2Array([Vector2(5.1, 0.0), Vector2(5.1, 3.4)]), 32,
		1.0, 1.0, 0.0, false)
	for k in 16:
		var a := TAU * float(k) / 16.0
		var d := Vector3(cos(a), 0, sin(a))
		lm.box("Dark", d * 5.12 + Vector3(0, att_y + 1.7, 0), Vector3(0.45, 2.2, 0.1),
			Basis(Vector3.UP.cross(d).normalized(), Vector3.UP, d), 0.0)
	var cap_y := att_y + 3.4
	lm.lathe("Concrete", Vector3(0, cap_y, 0), PackedVector2Array([Vector2(5.1, 0.0), Vector2(5.8, 0.3), Vector2(5.8, 0.9),
		Vector2(4.4, 0.9), Vector2(4.4, 1.7), Vector2(3.0, 1.7), Vector2(3.0, COIT_TOP_M - cap_y), Vector2(0.0, COIT_TOP_M - cap_y)]),
		32, 1.0, 1.0, 0.0, false)
	lm.commit(model)

## Vertical-fluted cylinder from y0 to y1 whose radius eases from r0 to
## r1: `flutes` shallow grooves of depth `depth`, four ring points each.
static func _fluted(lm: LandmarkMesh, key: String, y0: float, y1: float, r0: float, r1: float, flutes: int,
		depth: float) -> void:
	var stages := 6
	var per := flutes * 4
	var rings: Array = []
	for s in stages + 1:
		var y := lerpf(y0, y1, float(s) / float(stages))
		var r := lerpf(r0, r1, float(s) / float(stages))
		var ring := PackedVector3Array()
		for k in per:
			var a := TAU * float(k) / float(per)
			var g := 0.5 + 0.5 * cos(a * float(flutes))
			var rr := r - depth * pow(1.0 - g, 1.5)
			ring.append(Vector3(cos(a) * rr, y, sin(a) * rr))
		rings.append(ring)
	for s in stages:
		var ra: PackedVector3Array = rings[s]
		var rb: PackedVector3Array = rings[s + 1]
		for k in per:
			var m := (k + 1) % per
			var mid := (ra[k] + ra[m]) * 0.5
			var n := Vector3(mid.x, 0.0, mid.z).normalized()
			lm.quad(key, ra[k], ra[m], rb[m], rb[k], n)

## Dark half-disc filling a round arch head of radius `rad` whose
## springing line is centred at `c` on a wall facing `n`.
static func _arch_fill(lm: LandmarkMesh, c: Vector3, n: Vector3, rad: float) -> void:
	var r := Vector3.UP.cross(n).normalized()
	for i in 8:
		var t0 := PI * float(i) / 8.0
		var t1 := PI * float(i + 1) / 8.0
		lm.tri("Dark", c, c + (r * cos(t0) + Vector3.UP * sin(t0)) * rad, c + (r * cos(t1) + Vector3.UP * sin(t1)) * rad,
			n, n, n, Vector2.ZERO, Vector2(cos(t0), sin(t0)) * rad, Vector2(cos(t1), sin(t1)) * rad)
