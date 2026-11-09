class_name LandmarkLondonAbbey
extends RefCounted

## Westminster Abbey (69 m to the west tower pinnacles) in true metres,
## y = 0 at street level, fitted to the OSM footprint: 160 m from the west
## door porch (-80 m) to the Henry VII Chapel apse (+80 m); origin = the
## footprint centre, nave along X with the west front at -X, north at -Z,
## the cloister south (+Z). (The real axis points about 5 deg south of
## east; the registry carries no yaw for it.)
## Key dimensions: crossing centre at x = +4.6 m; ten nave bays of 5.4 m;
## aisle walls at z = +-13 m (17 m to the parapet); clerestory faces at
## +-7 m, eaves 31 m (the 31 m vault), lead ridge 37.5 m; transepts 31 m
## wide and 69 m long with the north front's rose window over Solomon's
## porch; double flying buttresses on piers at every bay; the polygonal
## chevet and radiating chapels; Henry VII's Chapel (x 46 - 80 m, 22 m
## across over its turrets, five canted oriels a side, ogee-capped
## turret-buttresses); Hawksmoor's west towers (12 x 11 m, 69 m with
## pinnacles) either side of the great west window and porch; the
## octagonal Chapter House (20 m across the flats) and the Great Cloister
## (47 x 39 m round a 32 x 26 m garth).

const XC := 4.6
const AISLE_H := 17.0
const AISLE_Z := 13.0
const CLER_Z := 7.0
const EAVE := 31.0
const RIDGE := 37.5

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#BDAF8F", 3.5))
	lm.use("Lead", LandmarkMaterials.pbr("slate", "#6E757A", 2.5))
	lm.use("Glass", LandmarkMaterials.glass("#2A3338"))
	lm.use("Gilt", LandmarkMaterials.gold())
	_body(lm)
	for sz in [-1.0, 1.0]:
		var s: float = sz
		_nave_side(lm, s)
		_transept_side(lm, s, -1.0)
		_transept_side(lm, s, 1.0)
		_transept_front(lm, s)
		_henry_side(lm, s)
	_crossing_lantern(lm)
	_chevet(lm)
	_henry_vii(lm)
	_west(lm)
	_cloister(lm)
	_chapter_house(lm)
	lm.commit(model)

## Masses and roofs: aisles, transept, clerestory, the two crossing
## lead roofs and the lean-to aisle roofs with their parapets.
static func _body(lm: LandmarkMesh) -> void:
	var rot := Basis(Vector3.UP, PI * 0.5)
	lm.box("Stone", Vector3(-16.95, 8.5, 0), Vector3(95.9, AISLE_H, 26.0), Basis(), 0.0)
	lm.box("Stone", Vector3(XC, 8.5, 0), Vector3(31.0, AISLE_H, 69.0), Basis(), 0.0)
	lm.box("Stone", Vector3(-22.25, 24.0, 0), Vector3(106.5, 14.0, 14.0), Basis(), 0.0)
	lm.box("Stone", Vector3(XC, 24.0, 0), Vector3(15.0, 14.0, 69.0), Basis(), 0.0)
	lm.gable("Lead", Vector3(-22.25, EAVE, 0), 14.8, 106.5, RIDGE - EAVE, rot, 0.5, "Stone")
	lm.gable("Lead", Vector3(XC, EAVE, 0), 14.8, 69.0, RIDGE - EAVE, Basis(), 0.5, "Stone")
	for sz in [-1.0, 1.0]:
		var s: float = sz
		for seg in [[-64.9, -10.9], [20.1, 31.0]]:
			var x0: float = seg[0]
			var x1: float = seg[1]
			lm.quad("Lead", Vector3(x0, AISLE_H, s * AISLE_Z), Vector3(x1, AISLE_H, s * AISLE_Z),
				Vector3(x1, 21.5, s * CLER_Z), Vector3(x0, 21.5, s * CLER_Z), Vector3(0, 6.0, s * 4.5).normalized())
			LandmarkWestKit.rail(lm, "Stone", Vector3(x0, AISLE_H, s * AISLE_Z), Vector3(x1, AISLE_H, s * AISLE_Z), 1.1, 1.0)
		LandmarkWestKit.rail(lm, "Stone", Vector3(-75.5, EAVE, s * CLER_Z), Vector3(31.0, EAVE, s * CLER_Z), 1.0, 1.1)
		LandmarkWestKit.rail(lm, "Stone", Vector3(XC - 7.5, EAVE, s * 34.5), Vector3(XC - 7.5, EAVE, s * 13.0), 1.0, 1.1)
		LandmarkWestKit.rail(lm, "Stone", Vector3(XC + 7.5, EAVE, s * 34.5), Vector3(XC + 7.5, EAVE, s * 13.0), 1.0, 1.1)
		for q in [-1.0, 1.0]:
			var qx: float = q
			var xa := XC + qx * 15.5
			var xb := XC + qx * 7.5
			lm.quad("Lead", Vector3(xa, AISLE_H, -34.5), Vector3(xa, AISLE_H, 34.5), Vector3(xb, 21.5, 34.5),
				Vector3(xb, 21.5, -34.5), Vector3(qx * 4.5, 8.0, 0).normalized())
			LandmarkWestKit.rail(lm, "Stone", Vector3(xa, AISLE_H, s * 13.0), Vector3(xa, AISLE_H, s * 34.5), 1.1, 1.0)

## String course, one pier with its pinnacle and the two flyers on a nave
## or choir aisle wall at x on side `s`.
static func _pier(lm: LandmarkMesh, x: float, s: float) -> void:
	LandmarkWestKit.buttress(lm, "Stone", Vector3(x, 0, s * AISLE_Z), Vector3(0, 0, s), 1.5, 3.4, 20.0, 2)
	LandmarkWestKit.pinnacle(lm, "Stone", Vector3(x, 20.0, s * 13.75), 0.5, 5.0)
	LandmarkWestKit.flyer(lm, "Stone", Vector3(x, 20.0, s * 14.0), Vector3(x, 27.5, s * 7.1), 0.7, 5)
	LandmarkWestKit.flyer(lm, "Stone", Vector3(x, 17.5, s * 14.2), Vector3(x, 23.0, s * 7.1), 0.6, 4)

## The ten nave bays on side `s`: aisle lancets, clerestory lancets,
## piers and flyers.
static func _nave_side(lm: LandmarkMesh, s: float) -> void:
	var n := Vector3(0, 0, s)
	for k in 11:
		_pier(lm, -64.9 + 5.4 * float(k), s)
	for k in 10:
		var x := -64.9 + 5.4 * (float(k) + 0.5)
		LandmarkWestKit.lancet(lm, "Stone", "Glass", Vector3(x, 2.4, s * AISLE_Z), n, 3.0, 9.6, true)
		LandmarkWestKit.lancet(lm, "Stone", "Glass", Vector3(x, 23.0, s * CLER_Z), n, 2.4, 6.5, true)
	for seg in [[20.1, 31.0, 2]]:
		var x0: float = seg[0]
		var x1: float = seg[1]
		var cnt: int = seg[2]
		for k in cnt + 1:
			_pier(lm, lerpf(x0, x1, float(k) / float(cnt)), s)
		for k in cnt:
			var x := lerpf(x0, x1, (float(k) + 0.5) / float(cnt))
			LandmarkWestKit.lancet(lm, "Stone", "Glass", Vector3(x, 2.4, s * AISLE_Z), n, 3.0, 9.6, true)
			LandmarkWestKit.lancet(lm, "Stone", "Glass", Vector3(x, 23.0, s * CLER_Z), n, 2.4, 6.5, true)
	lm.box("Stone", Vector3(-37.9, 13.3, s * 13.1), Vector3(54.0, 0.4, 0.3), Basis(), 0.0)

## East or west (`q`) face of the transept arm on side `s`: aisle
## lancets, clerestory lancets, piers and flyers.
static func _transept_side(lm: LandmarkMesh, s: float, q: float) -> void:
	var xa := XC + q * 15.5
	var xc := XC + q * 7.5
	var out := Vector3(q, 0, 0)
	for k in 4:
		var z := 13.0 + 5.375 * float(k + 1)
		LandmarkWestKit.buttress(lm, "Stone", Vector3(xa, 0, s * z), out, 1.5, 3.4, 20.0, 2)
		LandmarkWestKit.pinnacle(lm, "Stone", Vector3(xa + q * 0.75, 20.0, s * z), 0.5, 5.0)
		if k < 3:
			LandmarkWestKit.flyer(lm, "Stone", Vector3(xa + q * 1.0, 20.0, s * z), Vector3(xc + q * 0.1, 27.5, s * z), 0.7, 5)
			LandmarkWestKit.flyer(lm, "Stone", Vector3(xa + q * 1.2, 17.5, s * z), Vector3(xc + q * 0.1, 23.0, s * z), 0.6, 4)
	for k in 4:
		var zm := 13.0 + 5.375 * (float(k) + 0.5)
		LandmarkWestKit.lancet(lm, "Stone", "Glass", Vector3(xa, 2.4, s * zm), out, 3.0, 9.6, true)
		if k < 3:
			LandmarkWestKit.lancet(lm, "Stone", "Glass", Vector3(xc, 23.0, s * zm), out, 2.4, 6.5, true)

## Transept front on side `s` (north = -Z has Solomon's porch): central
## gable with the rose window, lancet band, flanking aisle bays and the
## two octagonal stair turrets.
static func _transept_front(lm: LandmarkMesh, s: float) -> void:
	var n := Vector3(0, 0, s)
	var zf := s * 34.5
	LandmarkWestKit.rose(lm, "Stone", "Glass", Vector3(XC, 27.6, zf + s * 0.05), n, 3.9, 16)
	for k in 5:
		LandmarkWestKit.lancet(lm, "Stone", "Glass", Vector3(XC - 4.4 + 2.2 * float(k), 15.2, zf), n, 1.5, 6.0, false)
	LandmarkWestKit.pinnacle(lm, "Stone", Vector3(XC, RIDGE, zf), 0.7, 4.0)
	for q in [-1.0, 1.0]:
		var qx: float = q
		LandmarkWestKit.lancet(lm, "Stone", "Glass", Vector3(XC + qx * 11.5, 3.0, zf), n, 2.8, 9.0, true)
		var tc := Vector3(XC + qx * 14.0, 0, s * 33.0)
		lm.frustum("Stone", tc, 2.5, 2.3, 33.0, 8, PI / 8.0)
		lm.spire("Lead", tc + Vector3(0, 33.5, 0), 2.4, 6.0, 0.0, 8)
		lm.lathe("Gilt", tc + Vector3(0, 39.5, 0), LandmarkWestKit.ball(0.3), 6)
		for j in 3:
			LandmarkWestKit.lancet(lm, "Stone", "Glass", tc + Vector3(0, 6.0 + 9.0 * float(j), 0) + n * 2.45, n, 0.9, 3.0, false, 0.2)
	if s < 0.0:
		# Solomon's porch: three portals under a gable.
		lm.box("Stone", Vector3(XC, 5.25, zf + s * 1.6), Vector3(14.0, 10.5, 3.2), Basis(), 0.0)
		lm.gable("Stone", Vector3(XC, 10.5, zf + s * 1.6), 14.0, 3.2, 3.6, Basis(), 0.0, "Stone")
		for px in [-4.6, 0.0, 4.6]:
			var pp: float = px
			var big := pp == 0.0
			LandmarkWestKit.portal(lm, "Stone", "Lead", Vector3(XC + pp, 0, zf + s * 3.2), n, 3.4 if big else 2.4,
				8.0 if big else 6.4, 3, true)
		LandmarkWestKit.pinnacle(lm, "Stone", Vector3(XC - 7.2, 10.5, zf + s * 3.0), 0.5, 3.6)
		LandmarkWestKit.pinnacle(lm, "Stone", Vector3(XC + 7.2, 10.5, zf + s * 3.0), 0.5, 3.6)
	else:
		for px in [-4.0, 0.0, 4.0]:
			var pp: float = px
			LandmarkWestKit.lancet(lm, "Stone", "Glass", Vector3(XC + pp, 3.0, zf), n, 2.4, 9.0, true)

## Crossing lantern: a stone stage with lancets under a lead roof.
static func _crossing_lantern(lm: LandmarkMesh) -> void:
	LandmarkWestKit.blk(lm, "Stone", XC, 31.0, 0, 10.0, 9.0, 10.0)
	for s in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * float(s))
		var n: Vector3 = b * Vector3(0, 0, 1)
		LandmarkWestKit.lancet(lm, "Stone", "Glass", Vector3(XC, 33.4, 0) + n * 5.0, n, 2.2, 5.4, true)
	LandmarkWestKit.hip(lm, "Lead", Vector3(XC, 40.0, 0), 10.6, 10.6, 6.5, 0.0)
	lm.lathe("Gilt", Vector3(XC, 46.3, 0), LandmarkWestKit.ball(0.5), 8)
	for q in [Vector2(-1, -1), Vector2(-1, 1), Vector2(1, -1), Vector2(1, 1)]:
		LandmarkWestKit.pinnacle(lm, "Stone", Vector3(XC + q.x * 4.8, 40.0, q.y * 4.8), 0.4, 3.2)

## Chevet: the ambulatory polygon with radiating chapels, the apse of the
## central vessel and its flyers, and the link to the Lady Chapel.
static func _chevet(lm: LandmarkMesh) -> void:
	var c := Vector3(30.0, 0, 0)
	lm.lathe("Stone", c, PackedVector2Array([Vector2(13.5, 0), Vector2(13.5, AISLE_H)]), 12, 1.0, 1.0, 0.0, false)
	lm.lathe("Lead", c + Vector3(0, AISLE_H, 0), PackedVector2Array([Vector2(13.8, 0), Vector2(7.6, 4.5)]), 12,
		1.0, 1.0, 0.0, false)
	lm.lathe("Stone", c, PackedVector2Array([Vector2(7.2, 0), Vector2(7.2, EAVE)]), 8, 1.0, 1.0, 0.0, false)
	lm.lathe("Lead", c + Vector3(0, EAVE, 0), PackedVector2Array([Vector2(7.6, 0), Vector2(0.0, 7.0)]), 8,
		1.0, 1.0, 0.0, false)
	for k in 6:
		var a := deg_to_rad(-75.0 + 30.0 * float(k))
		var d := Vector3(cos(a), 0, sin(a))
		LandmarkWestKit.lancet(lm, "Stone", "Glass", c + d * 13.05 + Vector3(0, 2.4, 0), d, 2.6, 9.0, true)
	for k in 4:
		var a := deg_to_rad(-67.5 + 45.0 * float(k))
		var d := Vector3(cos(a), 0, sin(a))
		LandmarkWestKit.lancet(lm, "Stone", "Glass", c + d * 6.65 + Vector3(0, 22.8, 0), d, 2.0, 6.0, true)
	for k in 7:
		var a := deg_to_rad(-90.0 + 30.0 * float(k))
		var d := Vector3(cos(a), 0, sin(a))
		LandmarkWestKit.pinnacle(lm, "Stone", c + d * 13.9 + Vector3(0, 15.0, 0), 0.55, 5.0)
		LandmarkWestKit.flyer(lm, "Stone", c + d * 13.6 + Vector3(0, 15.5, 0), c + d * 6.8 + Vector3(0, 26.0, 0), 0.7, 5)
		LandmarkWestKit.buttress(lm, "Stone", c + d * 13.2, d, 1.4, 2.6, 15.0, 1)
	for a_deg in [-75.0, -45.0, 45.0, 75.0]:
		var ad: float = a_deg
		var a := deg_to_rad(ad)
		var d := Vector3(cos(a), 0, sin(a))
		var cc := c + d * 15.2
		lm.lathe("Stone", cc, PackedVector2Array([Vector2(3.2, 0), Vector2(3.2, 13.0)]), 6, 1.0, 1.0, a - PI / 6.0, false)
		lm.lathe("Lead", cc + Vector3(0, 13.0, 0), PackedVector2Array([Vector2(3.5, 0), Vector2(0.0, 3.8)]), 6,
			1.0, 1.0, a - PI / 6.0, false)
		LandmarkWestKit.lancet(lm, "Stone", "Glass", cc + d * 2.75 + Vector3(0, 2.6, 0), d, 1.6, 7.0, false, 0.2)
	# East-transept chapels and the passage to Henry VII's Chapel.
	for sz in [-1.0, 1.0]:
		var s: float = sz
		lm.box("Stone", Vector3(27.0, 7.0, s * 16.4), Vector3(10.0, 14.0, 6.2), Basis(), 0.0)
		lm.gable("Lead", Vector3(27.0, 14.0, s * 16.4), 6.4, 10.0, 2.6, Basis(Vector3.UP, PI * 0.5), 0.3, "Stone")
		LandmarkWestKit.lancet(lm, "Stone", "Glass", Vector3(27.0, 3.5, s * 19.5), Vector3(0, 0, s), 2.6, 7.0, true)
	lm.box("Stone", Vector3(45.0, 7.0, 0), Vector3(4.0, 14.0, 12.4), Basis(), 0.0)

## Henry VII's Chapel body: parapeted aisle walls, clerestory, lead
## roof, the five-sided east end and the Lady Chapel apse cone.
static func _henry_vii(lm: LandmarkMesh) -> void:
	lm.box("Stone", Vector3(59.5, 7.5, 0), Vector3(27.0, 15.0, 18.6), Basis(), 0.0)
	lm.box("Stone", Vector3(59.5, 18.5, 0), Vector3(27.0, 7.0, 12.4), Basis(), 0.0)
	lm.gable("Lead", Vector3(59.5, 22.0, 0), 12.6, 27.0, 3.5, Basis(Vector3.UP, PI * 0.5), 0.4, "Stone")
	var apse := PackedVector2Array()
	var apse2 := PackedVector2Array()
	for k in 6:
		var a := deg_to_rad(-90.0 + 36.0 * float(k))
		apse.append(Vector2(73.0 + cos(a) * 7.8, sin(a) * 7.8))
		apse2.append(Vector2(73.0 + cos(a) * 5.6, sin(a) * 5.6))
	lm.poly_prism("Stone", apse, 0.0, 15.0, true)
	lm.poly_prism("Stone", apse2, 15.0, 22.0, false)
	lm.lathe("Lead", Vector3(73.0, 22.0, 0), PackedVector2Array([Vector2(5.9, 0), Vector2(0.0, 3.6)]), 10,
		1.0, 1.0, deg_to_rad(18.0), false)
	for k in 5:
		var a := deg_to_rad(-72.0 + 36.0 * float(k))
		var d := Vector3(cos(a), 0, sin(a))
		LandmarkWestKit.lancet(lm, "Stone", "Glass", Vector3(73.0, 3.4, 0) + d * 7.4, d, 2.2, 8.0, true, 0.2)
		LandmarkWestKit.lancet(lm, "Stone", "Glass", Vector3(73.0, 16.4, 0) + d * 5.3, d, 1.8, 4.6, false, 0.2)
	LandmarkWestKit.pinnacle(lm, "Stone", Vector3(80.3, 15.0, 0), 0.7, 4.6)
	for k in range(1, 5):
		var a := deg_to_rad(-90.0 + 36.0 * float(k))
		lm.frustum("Stone", Vector3(73.0 + cos(a) * 8.0, 0, sin(a) * 8.0), 1.1, 1.0, 20.0, 8, PI / 8.0)
		lm.lathe("Lead", Vector3(73.0 + cos(a) * 8.0, 20.0, sin(a) * 8.0), LandmarkWestKit.ogee_prof(1.4, 3.4), 8)
		lm.lathe("Gilt", Vector3(73.0 + cos(a) * 8.0, 23.4, sin(a) * 8.0), LandmarkWestKit.ball(0.25), 6)

## One side of Henry VII's Chapel: five canted oriel windows, the six
## ogee-capped octagonal turret-buttresses, clerestory lancets, the
## pierced parapet and the small flyers.
static func _henry_side(lm: LandmarkMesh, s: float) -> void:
	var n := Vector3(0, 0, s)
	for k in 6:
		var x := 46.0 + 5.4 * float(k)
		var tp := Vector3(x, 0, s * 10.4)
		lm.frustum("Stone", tp, 1.15, 1.05, 21.0, 8, PI / 8.0)
		lm.lathe("Lead", tp + Vector3(0, 21.0, 0), LandmarkWestKit.ogee_prof(1.5, 3.4), 8)
		lm.lathe("Gilt", tp + Vector3(0, 24.4, 0), LandmarkWestKit.ball(0.25), 6)
		for y in [8.0, 15.0]:
			var yy: float = y
			lm.frustum("Stone", tp + Vector3(0, yy, 0), 1.3, 1.3, 0.35, 8, PI / 8.0)
		LandmarkWestKit.flyer(lm, "Stone", Vector3(x, 19.0, s * 10.0), Vector3(x, 22.5, s * 6.3), 0.6, 4)
	for k in 5:
		var xm := 46.0 + 5.4 * (float(k) + 0.5)
		_oriel(lm, xm, s)
		LandmarkWestKit.lancet(lm, "Stone", "Glass", Vector3(xm, 16.4, s * 6.2), n, 2.4, 5.0, true)
	LandmarkWestKit.rail(lm, "Stone", Vector3(46.0, 15.0, s * 9.3), Vector3(73.0, 15.0, s * 9.3), 1.2, 0.9)

## Canted oriel bay of the Lady Chapel at x on side `s`: three faces of
## panel-traceried glass between stone mullions and transoms.
static func _oriel(lm: LandmarkMesh, x: float, s: float) -> void:
	var pts := [Vector3(x - 1.6, 0, s * 9.3), Vector3(x - 1.1, 0, s * 10.4), Vector3(x + 1.1, 0, s * 10.4),
		Vector3(x + 1.6, 0, s * 9.3)]
	var poly := PackedVector2Array()
	for p in pts:
		var pv: Vector3 = p
		poly.append(Vector2(pv.x, pv.z))
	lm.poly_prism("Stone", poly, 0.0, 14.6, true)
	for e in 3:
		var a: Vector3 = pts[e]
		var b: Vector3 = pts[e + 1]
		var along := (b - a).normalized()
		var nn := along.cross(Vector3.UP).normalized() * s
		var a0 := a + along * 0.18 + nn * 0.04
		var b0 := b - along * 0.18 + nn * 0.04
		lm.quad("Glass", a0 + Vector3(0, 2.6, 0), b0 + Vector3(0, 2.6, 0), b0 + Vector3(0, 12.8, 0), a0 + Vector3(0, 12.8, 0), nn)
		var cnt := 3 if e == 1 else 2
		for m in cnt:
			var p := a0.lerp(b0, float(m) / float(cnt - 1) if cnt > 1 else 0.5)
			lm.beam("Stone", p + Vector3(0, 2.6, 0), p + Vector3(0, 12.8, 0), 0.14, 0.18, along)
		for t in 4:
			lm.beam("Stone", a0 + Vector3(0, 2.8 + 3.3 * float(t), 0), b0 + Vector3(0, 2.8 + 3.3 * float(t), 0), 0.14, 0.18, Vector3.UP)

## West front: the porch with its portal, the great west window under
## the nave gable and Hawksmoor's two towers.
static func _west(lm: LandmarkMesh) -> void:
	var rot := Basis(Vector3.UP, PI * 0.5)
	var w := Vector3(-1, 0, 0)
	lm.box("Stone", Vector3(-77.7, 4.3, 0), Vector3(4.4, 8.6, 10.0), Basis(), 0.0)
	lm.gable("Lead", Vector3(-77.7, 8.6, 0), 10.0, 4.4, 2.6, rot, 0.3, "Stone")
	LandmarkWestKit.portal(lm, "Stone", "Lead", Vector3(-79.9, 0, 0), w, 3.8, 7.4, 4, true)
	for sz in [-1.0, 1.0]:
		var s: float = sz
		LandmarkWestKit.pinnacle(lm, "Stone", Vector3(-79.5, 8.6, s * 4.6), 0.4, 3.0)
	LandmarkWestKit.lancet(lm, "Stone", "Glass", Vector3(-75.55, 11.8, 0), w, 6.0, 17.0, true, 0.5)
	lm.gable("Stone", Vector3(-75.2, EAVE, 0), 10.6, 0.8, 8.8, rot, 0.0, "Stone")
	LandmarkWestKit.pinnacle(lm, "Stone", Vector3(-75.2, 39.8, 0), 0.6, 3.6)
	for sz in [-1.0, 1.0]:
		var s: float = sz
		_tower(lm, Vector3(-70.9, 0, s * 10.5), s)

## One west tower with its centre `c` (ground): stages with lancets,
## string courses, the octagonal corner turrets, the parapet and the four
## corner pinnacles (69 m).
static func _tower(lm: LandmarkMesh, c: Vector3, s: float) -> void:
	var w := Vector3(-1, 0, 0)
	var o := Vector3(0, 0, s)
	LandmarkWestKit.blk(lm, "Stone", c.x, 0, c.z, 12.0, 62.0, 11.0)
	for y in [33.0, 48.0]:
		var yy: float = y
		lm.box("Stone", c + Vector3(0, yy, 0), Vector3(12.5, 0.5, 11.5), Basis(), 0.0)
	lm.box("Stone", c + Vector3(0, 62.2, 0), Vector3(12.8, 0.8, 11.8), Basis(), 0.0)
	for f in [[w, 6.0], [o, 5.5]]:
		var n: Vector3 = f[0]
		var off: float = f[1]
		var r := Vector3.UP.cross(n).normalized()
		LandmarkWestKit.lancet(lm, "Stone", "Glass", c + n * off + Vector3(0, 9.0, 0), n, 2.4, 14.0, true)
		LandmarkWestKit.lancet(lm, "Stone", "Glass", c + n * off + Vector3(0, 25.0, 0), n, 2.0, 6.4, true)
		LandmarkWestKit.lancet(lm, "Stone", "Glass", c + n * off + Vector3(0, 35.5, 0), n, 2.0, 9.0, false)
		for q in [-1.9, 1.9]:
			var qq: float = q
			LandmarkWestKit.lancet(lm, "Stone", "Glass", c + n * off + r * qq + Vector3(0, 50.0, 0), n, 1.5, 10.0, false)
	for q in [Vector2(-1, -1), Vector2(-1, 1), Vector2(1, -1), Vector2(1, 1)]:
		var cp := c + Vector3(q.x * 6.0, 0, q.y * 5.5)
		lm.frustum("Stone", cp, 1.3, 1.15, 64.0, 8, PI / 8.0)
		for y in [20.0, 33.0, 48.0]:
			var yy: float = y
			lm.frustum("Stone", cp + Vector3(0, yy, 0), 1.5, 1.5, 0.4, 8, PI / 8.0)
		LandmarkWestKit.pinnacle(lm, "Stone", cp + Vector3(0, 64.0, 0), 0.75, 5.0)
	LandmarkWestKit.rail(lm, "Stone", c + Vector3(-6.0, 62.6, -5.5), c + Vector3(6.0, 62.6, -5.5), 1.4, 0.9)
	LandmarkWestKit.rail(lm, "Stone", c + Vector3(-6.0, 62.6, 5.5), c + Vector3(6.0, 62.6, 5.5), 1.4, 0.9)
	LandmarkWestKit.rail(lm, "Stone", c + Vector3(-6.0, 62.6, -5.5), c + Vector3(-6.0, 62.6, 5.5), 1.4, 0.9)
	LandmarkWestKit.rail(lm, "Stone", c + Vector3(6.0, 62.6, -5.5), c + Vector3(6.0, 62.6, 5.5), 1.4, 0.9)
	LandmarkWestKit.pinnacle(lm, "Stone", c + Vector3(-6.0, 62.6, 0), 0.5, 2.6)
	LandmarkWestKit.pinnacle(lm, "Stone", c + Vector3(0, 62.6, s * 5.5), 0.5, 2.6)

## The Great Cloister south of the nave: four walks with traceried
## windows to the garth under lean-to lead roofs.
static func _cloister(lm: LandmarkMesh) -> void:
	var x0 := -49.6
	var x1 := -3.0
	var z0 := 17.1
	var z1 := 55.8
	var gx0 := -42.5
	var gx1 := -10.0
	var gz0 := 23.5
	var gz1 := 49.5
	# Walks: [centre x, centre z, size x, size z, direction of the garth].
	var walks := [[(x0 + gx0) * 0.5, (z0 + z1) * 0.5, gx0 - x0, z1 - z0, Vector3(1, 0, 0)],
		[(gx1 + x1) * 0.5, (z0 + z1) * 0.5, x1 - gx1, z1 - z0, Vector3(-1, 0, 0)],
		[(gx0 + gx1) * 0.5, (z0 + gz0) * 0.5, gx1 - gx0, gz0 - z0, Vector3(0, 0, 1)],
		[(gx0 + gx1) * 0.5, (gz1 + z1) * 0.5, gx1 - gx0, z1 - gz1, Vector3(0, 0, -1)]]
	for wk in walks:
		var cx: float = wk[0]
		var cz: float = wk[1]
		var sx: float = wk[2]
		var sz: float = wk[3]
		var d: Vector3 = wk[4]
		lm.box("Stone", Vector3(cx, 3.2, cz), Vector3(sx, 6.4, sz), Basis(), 0.0)
		# Taller outer wall strip and the pent roof falling to the garth.
		var half := Vector3(sx * 0.5, 0, sz * 0.5)
		var inner := Vector3(cx, 0, cz) + Vector3(d.x * half.x, 0, d.z * half.z)
		var outer := Vector3(cx, 0, cz) - Vector3(d.x * half.x, 0, d.z * half.z)
		var along := Vector3(d.z, 0, d.x).normalized()
		var len_along := absf(along.x) * sx + absf(along.z) * sz
		lm.box("Stone", outer + Vector3(0, 8.0, 0) + d * 0.5, Vector3(absf(d.x) * 1.0 + absf(d.z) * len_along, 3.2, absf(d.z) * 1.0 + absf(d.x) * len_along), Basis(), 0.0)
		var ha := along * len_along * 0.5
		lm.quad("Lead", outer + Vector3(0, 9.6, 0) - ha, outer + Vector3(0, 9.6, 0) + ha, inner + Vector3(0, 6.4, 0) + ha,
			inner + Vector3(0, 6.4, 0) - ha, (Vector3.UP * (half.x * absf(d.x) + half.z * absf(d.z)) * 2.0 + d * 3.2).normalized())
		var cnt := int(len_along / 3.4)
		for k in cnt:
			var p := inner + along * ((float(k) + 0.5) / float(cnt) - 0.5) * len_along
			LandmarkWestKit.lancet(lm, "Stone", "Glass", p + Vector3(0, 0.8, 0), d, 2.0, 4.6, true, 0.25)
		LandmarkWestKit.rail(lm, "Stone", outer + Vector3(0, 9.6, 0) - ha, outer + Vector3(0, 9.6, 0) + ha, 0.9, 1.2)

## The octagonal Chapter House off the east walk (flats on the axes,
## 20 m across): eight corner buttresses with pinnacles, tall traceried
## windows on seven faces, the shallow lead roof and the vestibule.
static func _chapter_house(lm: LandmarkMesh) -> void:
	var ch := Vector3(25.6, 0, 40.3)
	lm.frustum("Stone", ch, 10.8, 10.8, 18.5, 8, PI / 8.0)
	lm.lathe("Lead", ch + Vector3(0, 18.5, 0), PackedVector2Array([Vector2(11.2, 0), Vector2(0.0, 5.0)]), 8,
		1.0, 1.0, PI / 8.0, false)
	for k in 8:
		var a := TAU * float(k) / 8.0 + PI / 8.0
		var d := Vector3(cos(a), 0, sin(a))
		LandmarkWestKit.buttress(lm, "Stone", ch + d * 10.2, d, 1.6, 2.8, 17.0, 2)
		LandmarkWestKit.pinnacle(lm, "Stone", ch + d * 11.2 + Vector3(0, 17.0, 0), 0.6, 4.2)
		if k != 4:
			var f := Vector3(cos(a - PI / 8.0), 0, sin(a - PI / 8.0))
			LandmarkWestKit.lancet(lm, "Stone", "Glass", ch + f * 9.95 + Vector3(0, 4.0, 0), f, 4.2, 12.0, true)
	LandmarkWestKit.blk(lm, "Stone", 7.0, 0, 41.0, 20.0, 9.0, 7.0)
	lm.box("Lead", Vector3(7.0, 9.1, 41.0), Vector3(20.4, 0.3, 7.4), Basis(), 0.0)
