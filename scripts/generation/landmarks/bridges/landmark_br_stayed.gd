class_name LandmarkBrStayed
extends RefCounted

## The cable-stayed bridges of the bridges batch in true metres, along +X
## on the shared LandmarkBrKit parts: Millau's seven-mast viaduct over a
## valley, the Oresund Bridge's free-standing pylon pairs and Rotterdam's
## bent-pylon Erasmus Bridge, the last two with y = 0 at the water.

## Millau Viaduct (y = 0 at the Tarn valley floor, bridge over land): 2460 m
## in eight spans (204 + 6 x 342 + 204 m) carried on seven concrete
## piers of 77.6 to 245 m (the tallest 25 m across and 17 m along the
## bridge at its foot) whose top 90 m split along the bridge into two
## flexible columns ending 16 m apart, four bearings under the 32 m wide,
## 4.2 m deep aerofoil steel box deck with its 3 m wind screens, and on
## each pier an 87 m steel mast, an inverted Y with 38 m legs, holding
## eleven pairs of stays a side in the central plane; the mast tips stand
## 343 m over the valley.
const MI_PIER_X: Array[float] = [-1026.0, -684.0, -342.0, 0.0, 342.0, 684.0, 1026.0]
const MI_PIER_H: Array[float] = [94.5, 245.0, 221.0, 144.2, 136.4, 111.9, 77.6]
const MI_DECK_M := 256.0
const MI_DEPTH := 4.2
const MI_MAST_M := 87.0
const MI_LEG_M := 38.0
const MI_HALF_W := 16.0

static func millau(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	LandmarkBrKit.base_mats(lm, "#E6E7E5", "#D3D0C8")
	var under := MI_DECK_M - MI_DEPTH
	for i in MI_PIER_X.size():
		_millau_pier(lm, MI_PIER_X[i], under - MI_PIER_H[i], under, MI_PIER_H[i])
		_millau_mast(lm, MI_PIER_X[i])
	# Aerofoil box: flat road top, sloping webs to the 15 m soffit.
	var d := MI_DECK_M
	LandmarkBrKit.extrude_yz(lm, "Steel", PackedVector2Array([Vector2(-MI_HALF_W, d - 0.3),
		Vector2(-MI_HALF_W + 0.6, d - 1.1), Vector2(-7.5, d - MI_DEPTH), Vector2(7.5, d - MI_DEPTH),
		Vector2(MI_HALF_W - 0.6, d - 1.1), Vector2(MI_HALF_W, d - 0.3)]), -1230.0, 1230.0)
	lm.box("Deck", Vector3(0, d - 0.15, 0), Vector3(2460.0, 0.3, MI_HALF_W * 2.0 - 1.0))
	# Central reserve (the stay anchorages) and crash barriers.
	lm.box("Concrete", Vector3(0, d + 0.4, 0), Vector3(2460.0, 0.8, 4.0))
	for z in [-11.5, 11.5]:
		lm.box("Concrete", Vector3(0, d + 0.45, z), Vector3(2460.0, 0.9, 0.4), Basis(), 0.0)
	# Wind screens: posts every 6 m with the three transparent panels'
	# rails, 3 m tall along both edges.
	for z in [-MI_HALF_W + 0.4, MI_HALF_W - 0.4]:
		LandmarkBrKit.railing(lm, "Steel", Vector3(-1230.0, d, z), Vector3(1230.0, d, z), 3.0, 6.0)
		lm.beam("Steel", Vector3(-1230.0, d + 2.2, z), Vector3(1230.0, d + 2.2, z), 0.1, 0.1)
		lm.beam("Steel", Vector3(-1230.0, d + 0.8, z), Vector3(1230.0, d + 0.8, z), 0.1, 0.1)
	for s in [-1.0, 1.0]:
		lm.box("Concrete", Vector3(s * 1238.0, d - 8.0, 0), Vector3(16.0, 16.0, 36.0))
		lm.box("Concrete", Vector3(s * 1238.0, d - 0.6, 0), Vector3(17.0, 1.2, 37.0))
	lm.commit(model)

## One pier at x from its foot at y0 to the deck soffit at `under`: a
## footing, the shaft (two halves round a narrower core, the groove that
## continues the split) and the two columns spreading to 16 m apart under
## their bearings.
static func _millau_pier(lm: LandmarkMesh, x: float, y0: float, under: float, h: float) -> void:
	var k := h / 245.0
	var hx0 := 5.5 + 3.0 * k
	var hz0 := 8.0 + 4.5 * k
	var fork := minf(90.0, h * 0.6)
	var split := under - fork
	var f := (split - y0) / (under - y0)
	var hxs := lerpf(hx0, 5.0, f)
	var hzs := lerpf(hz0, 7.0, f)
	lm.box("Concrete", Vector3(x, y0 + 1.5, 0), Vector3(hx0 * 2.0 + 6.0, 3.0, hz0 * 2.0 + 6.0))
	LandmarkBrKit.tapered_box(lm, "Concrete", Vector3(x, y0 + 3.0, 0), hx0 * 0.85, hz0 - 0.6, hxs * 0.85,
		hzs - 0.6, split - y0 - 3.0)
	for sx in [-1.0, 1.0]:
		var c0 := Vector3(x + sx * hx0 * 0.5, y0 + 3.0, 0)
		var c1 := Vector3(x + sx * hxs * 0.5, split, 0)
		_slab(lm, "Concrete", c0, c1, Vector2(hx0 * 0.5 - 0.4, hz0), Vector2(hxs * 0.5 - 0.4, hzs))
		var t := Vector3(x + sx * 8.0, under - 1.0, 0)
		_slab(lm, "Concrete", c1, t, Vector2(hxs * 0.5 - 0.4, hzs), Vector2(2.0, 5.0))
		lm.box("Concrete", t + Vector3(0, 0.4, 0), Vector3(4.8, 0.8, 10.6))
		for bz in [-3.0, 3.0]:
			lm.box("Steel", t + Vector3(0, 0.95, bz), Vector3(1.6, 0.3, 1.6))

## Inverted-Y mast over the pier at x and its stay fans.
static func _millau_mast(lm: LandmarkMesh, x: float) -> void:
	var d := MI_DECK_M
	var knee := d + MI_LEG_M
	for sx in [-1.0, 1.0]:
		_slab(lm, "Steel", Vector3(x + sx * 8.0, d, 0), Vector3(x + sx * 1.4, knee, 0), Vector2(1.4, 1.6),
			Vector2(1.2, 1.4))
	lm.box("Steel", Vector3(x, knee + 1.0, 0), Vector3(5.6, 2.0, 3.2))
	LandmarkBrKit.tapered_box(lm, "Steel", Vector3(x, knee, 0), 2.6, 1.6, 1.1, 0.9, d + MI_MAST_M - knee)
	for dir in [-1.0, 1.0]:
		for i in 11:
			var ty := lerpf(d + 48.0, d + MI_MAST_M - 4.0, float(i) / 10.0)
			var dx: float = dir * (32.0 + 13.6 * i)
			for z in [-0.35, 0.35]:
				lm.beam("Steel", Vector3(x + dir * 1.0, ty, z), Vector3(x + dx, d + 0.9, z), 0.22, 0.22)
			lm.box("Steel", Vector3(x + dx, d + 0.9, 0), Vector3(1.2, 0.6, 1.4))

## Four-sided member between two horizontal rectangles centred at a and
## b with half-sizes ha and hb (x, z): a leaning column or leg.
static func _slab(lm: LandmarkMesh, key: String, a: Vector3, b: Vector3, ha: Vector2, hb: Vector2) -> void:
	var sx: Array[float] = [-1.0, 1.0, 1.0, -1.0]
	var sz: Array[float] = [-1.0, -1.0, 1.0, 1.0]
	for i in 4:
		var j := (i + 1) % 4
		var p0 := a + Vector3(sx[i] * ha.x, 0, sz[i] * ha.y)
		var p1 := a + Vector3(sx[j] * ha.x, 0, sz[j] * ha.y)
		var q1 := b + Vector3(sx[j] * hb.x, 0, sz[j] * hb.y)
		var q0 := b + Vector3(sx[i] * hb.x, 0, sz[i] * hb.y)
		lm.quad(key, p0, p1, q1, q0, Vector3(sx[i] + sx[j], 0, sz[i] + sz[j]).normalized())
	lm.quad(key, b + Vector3(-hb.x, 0, -hb.y), b + Vector3(hb.x, 0, -hb.y), b + Vector3(hb.x, 0, hb.y),
		b + Vector3(-hb.x, 0, hb.y), Vector3.UP)

## Oresund Bridge, cable-stayed section: 490 m main span and 301 m side
## spans (1092 m) between four free-standing concrete pylons of 204 m in
## two pairs (no cross beam over the road, one under the deck), tapering
## from 9.4 x 12.5 m to 4.7 x 6.2 m, their stays in a harp (parallel) in
## two planes to outriggers on the 23.5 m two-level truss (motorway over
## railway) 57 m over the sound, side-span piers, and the first of the
## 140 m approach truss spans on their piers.
const OR_MAIN := 490.0
const OR_SIDE := 301.0
const OR_TOWER_M := 204.0
const OR_DECK_M := 67.0
const OR_HALF_W := 11.75
const OR_PYLON_Z := 17.5
const OR_STAYS := 8
const OR_STAY_DX := 30.0
const OR_STAY_DY := 16.0

static func oresund(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	LandmarkBrKit.base_mats(lm, "#B4BABC", "#D2D1CC")
	var tx := OR_MAIN * 0.5
	var end := tx + OR_SIDE
	for s in [-1.0, 1.0]:
		var x: float = s * tx
		lm.box("Concrete", Vector3(x, 5.0, 0), Vector3(22.0, 10.0, OR_PYLON_Z * 2.0 + 16.0))
		for sz in [-1.0, 1.0]:
			# Pentagonal pylon: vertical outer faces, the point inward.
			var rot: float = 0.0 if sz < 0.0 else PI
			lm.lathe("Concrete", Vector3(x, 10.0, sz * OR_PYLON_Z), PackedVector2Array([Vector2(7.0, 0),
				Vector2(5.2, OR_DECK_M - 10.0), Vector2(3.6, OR_TOWER_M - 12.0), Vector2(3.5, OR_TOWER_M - 10.0)]),
				5, 0.75, 1.0, rot + PI * 0.5, false)
			lm.frustum("Concrete", Vector3(x, OR_TOWER_M - 0.5, sz * OR_PYLON_Z), 3.5, 3.0, 0.5, 5, rot + PI * 0.5,
				0.75, 1.0)
			# Harp stays both ways from the pylon to the outriggers.
			for dir in [-1.0, 1.0]:
				for i in OR_STAYS:
					var ty := OR_DECK_M + OR_STAY_DY * (i + 1)
					var dx: float = dir * OR_STAY_DX * (i + 1)
					lm.beam("Steel", Vector3(x + dir * 1.5, ty, sz * (OR_PYLON_Z - 1.0)),
						Vector3(x + dx, OR_DECK_M - 1.0, sz * (OR_HALF_W + 1.4)), 0.32, 0.32)
					lm.beam("Steel", Vector3(x + dx, OR_DECK_M - 1.5, sz * (OR_HALF_W - 0.6)),
						Vector3(x + dx, OR_DECK_M - 1.5, sz * (OR_HALF_W + 1.8)), 1.0, 1.4)
		# The one cross beam, under the deck.
		lm.box("Concrete", Vector3(x, OR_DECK_M - 14.0, 0), Vector3(7.0, 6.0, OR_PYLON_Z * 2.0))
		for off in [140.0, 220.0]:
			_or_pier(lm, s * (tx + off), OR_DECK_M - 10.0)
		# Approach truss spans falling to the shore.
		for k in 3:
			var xa: float = s * (end + 140.0 * k)
			var xb: float = s * (end + 140.0 * (k + 1))
			_or_pier(lm, xb, OR_DECK_M - 10.0 - 7.0 * (k + 1))
			_or_truss(lm, minf(xa, xb), maxf(xa, xb), OR_DECK_M - 7.0 * (k + 0.5))
		_or_pier(lm, s * end, OR_DECK_M - 10.0)
	_or_truss(lm, -end, end, OR_DECK_M)
	lm.commit(model)

## Two-level truss from x0 to x1, road top at y: Warren sides, the
## railway's sealed box and tracks in the lower level.
static func _or_truss(lm: LandmarkMesh, x0: float, x1: float, y: float) -> void:
	LandmarkBrKit.deck_girder(lm, x0, x1, y, OR_HALF_W, 10.0, 20.0)
	var mid := (x0 + x1) * 0.5
	lm.box("Concrete", Vector3(mid, y - 9.3, 0), Vector3(x1 - x0, 0.8, 13.0))
	for rz in [-4.2, -2.7, 2.7, 4.2]:
		lm.box("Steel", Vector3(mid, y - 8.8, rz), Vector3(x1 - x0, 0.2, 0.12), Basis(), 0.0)

## Approach / side-span pier at x up to `top`: a tapered shaft with a
## splayed head on an ice-protected footing.
static func _or_pier(lm: LandmarkMesh, x: float, top: float) -> void:
	lm.lathe("Concrete", Vector3(x, 0, 0), PackedVector2Array([Vector2(8.0, 0), Vector2(8.0, 3.0),
		Vector2(5.5, 6.0)]), 16, 0.7, 1.4)
	LandmarkBrKit.tapered_box(lm, "Concrete", Vector3(x, 6.0, 0), 3.0, 5.0, 2.4, 4.2, top - 9.0)
	_slab(lm, "Concrete", Vector3(x, top - 3.0, 0), Vector3(x, top, 0), Vector2(2.4, 4.2), Vector2(3.0, 11.0))

## Erasmus Bridge, Rotterdam ("The Swan"): 802 m with the 139 m pale-blue
## steel pylon on the south bank, two legs straddling the road joining
## into the single mast bent back over the river, 16 pairs of stays to
## both edges of the 284 m main span and two bundles of backstays to the
## deck behind it, the 33.8 m box deck 12.5 m clear over the Nieuwe Maas,
## and at the south end the 89 m bascule over the shipping channel.
const ER_PYLON_X := -5.0
const ER_TOP_M := 139.0
const ER_DECK_M := 15.0
const ER_HALF_W := 16.9
const ER_MAST: Array[Vector2] = [Vector2(-5.0, 40.0), Vector2(-8.0, 78.0), Vector2(-13.0, 110.0),
	Vector2(-19.0, ER_TOP_M - 0.6)]
const ER_BASCULE: Array[float] = [-360.0, -271.0]

static func erasmus(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	LandmarkBrKit.base_mats(lm, "#C6CED3")
	# Pylon foot in the river and its two legs over the deck.
	lm.box("Concrete", Vector3(ER_PYLON_X, (ER_DECK_M - 3.4) * 0.5, 0), Vector3(16.0, ER_DECK_M - 3.4, 40.0))
	for sz in [-1.0, 1.0]:
		_slab(lm, "Steel", Vector3(ER_PYLON_X, ER_DECK_M - 3.4, sz * (ER_HALF_W + 2.0)),
			Vector3(ER_MAST[0].x, ER_MAST[0].y, sz * 1.8), Vector2(4.4, 2.2), Vector2(2.8, 1.8))
	for i in ER_MAST.size() - 1:
		var w := lerpf(5.6, 3.0, float(i) / (ER_MAST.size() - 1))
		var a := Vector3(ER_MAST[i].x, ER_MAST[i].y, 0)
		var b := Vector3(ER_MAST[i + 1].x, ER_MAST[i + 1].y, 0)
		lm.beam("Steel", a, b, w, w * 0.75, Vector3(1, 0, 0), true)
		# Stay anchor plates down the mast's front edge.
		lm.beam("Steel", a + Vector3(w * 0.5, 0, 0), b + Vector3(w * 0.5, 0, 0), 0.5, 1.2, Vector3(1, 0, 0))
	lm.lathe("Steel", Vector3(ER_MAST[3].x, ER_MAST[3].y, 0), PackedVector2Array([Vector2(1.6, 0),
		Vector2(0.4, 0.6), Vector2(0.0, 0.6)]), 8)
	# 16 pairs of stays to the main span, two bundles of backstays.
	for i in 16:
		var ty := lerpf(70.0, 135.0, float(i) / 15.0)
		var dx := ER_PYLON_X + 22.0 + 16.2 * i
		for sz in [-1.0, 1.0]:
			lm.beam("Steel", Vector3(_mast_x(ty), ty, 0), Vector3(dx, ER_DECK_M + 0.4, sz * (ER_HALF_W - 1.2)), 0.35, 0.35)
			lm.box("Steel", Vector3(dx, ER_DECK_M + 0.4, sz * (ER_HALF_W - 1.2)), Vector3(1.2, 0.8, 0.8))
	for sz in [-1.0, 1.0]:
		for j in 4:
			var ty := lerpf(118.0, 137.0, float(j) / 3.0)
			lm.beam("Steel", Vector3(_mast_x(ty), ty, sz * 0.4), Vector3(ER_PYLON_X - 92.0 - float(j), ER_DECK_M + 0.5,
				sz * (2.6 + 0.3 * j)), 0.4, 0.4)
		lm.box("Concrete", Vector3(ER_PYLON_X - 93.5, ER_DECK_M + 0.8, sz * 3.0), Vector3(5.0, 1.6, 2.4))
	_er_deck(lm, -401.0, ER_BASCULE[0])
	_er_deck(lm, ER_BASCULE[0] + 0.3, ER_BASCULE[1] - 0.3)
	_er_deck(lm, ER_BASCULE[1], 401.0)
	# Bascule basements either side of the channel and the counterweight
	# pit's housing; approach piers of the other spans.
	for bx in ER_BASCULE:
		lm.box("Concrete", Vector3(bx, (ER_DECK_M - 3.4) * 0.5, 0), Vector3(14.0, ER_DECK_M - 3.4, 38.0))
		lm.box("Concrete", Vector3(bx, ER_DECK_M - 3.0, 0), Vector3(15.0, 0.8, 39.0))
	lm.box("Steel", Vector3(ER_BASCULE[0] + 9.0, ER_DECK_M - 5.0, 0), Vector3(14.0, 3.0, 30.0))
	for x in [-71.0, -137.0, -203.0, -394.0, 300.0, 350.0, 396.0]:
		for sz in [-1.0, 1.0]:
			lm.frustum("Concrete", Vector3(x, 0, sz * 8.0), 2.4, 2.0, ER_DECK_M - 3.4, 16)
		lm.box("Concrete", Vector3(x, ER_DECK_M - 4.0, 0), Vector3(4.0, 1.2, 26.0))
	lm.commit(model)

## Box-girder deck from x0 to x1: sloping-web box, road and tram tracks,
## footways and cycle paths with railings, and lamp standards.
static func _er_deck(lm: LandmarkMesh, x0: float, x1: float) -> void:
	var d := ER_DECK_M
	LandmarkBrKit.extrude_yz(lm, "Steel", PackedVector2Array([Vector2(-ER_HALF_W, d - 0.4),
		Vector2(-ER_HALF_W + 1.4, d - 1.4), Vector2(-9.0, d - 3.3), Vector2(9.0, d - 3.3),
		Vector2(ER_HALF_W - 1.4, d - 1.4), Vector2(ER_HALF_W, d - 0.4)]), x0, x1)
	var mid := (x0 + x1) * 0.5
	lm.box("Deck", Vector3(mid, d - 0.15, 0), Vector3(x1 - x0, 0.3, ER_HALF_W * 2.0 - 0.6))
	for rz in [-1.9, -0.5, 0.5, 1.9]:
		lm.box("Steel", Vector3(mid, d + 0.05, rz), Vector3(x1 - x0, 0.1, 0.1), Basis(), 0.0)
	for z in [-11.0, -3.0, 3.0, 11.0]:
		lm.box("Concrete", Vector3(mid, d + 0.15, z), Vector3(x1 - x0, 0.3, 0.5), Basis(), 0.0)
	for sz in [-1.0, 1.0]:
		LandmarkBrKit.railing(lm, "Steel", Vector3(x0, d, sz * (ER_HALF_W - 0.2)), Vector3(x1, d, sz * (ER_HALF_W - 0.2)),
			1.2, 2.5)
		var n := int((x1 - x0) / 30.0)
		for k in range(1, n):
			var lx := lerpf(x0, x1, float(k) / n)
			lm.frustum("Steel", Vector3(lx, d, sz * 11.0), 0.16, 0.1, 8.0, 8)
			lm.beam("Steel", Vector3(lx, d + 8.0, sz * 11.0), Vector3(lx, d + 8.2, sz * 9.5), 0.2, 0.2)

## x of the bent mast at height y.
static func _mast_x(y: float) -> float:
	for i in ER_MAST.size() - 1:
		if y <= ER_MAST[i + 1].y:
			return lerpf(ER_MAST[i].x, ER_MAST[i + 1].x, (y - ER_MAST[i].y) / (ER_MAST[i + 1].y - ER_MAST[i].y))
	return ER_MAST[ER_MAST.size() - 1].x
