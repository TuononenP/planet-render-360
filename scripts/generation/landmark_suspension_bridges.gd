class_name LandmarkSuspensionBridges
extends RefCounted

## The two great suspension bridges in true metres, built along +X with
## y = 0 at the water (LocationData `base: water`): towers, main cables
## sagging between them and down to the anchorages, vertical suspenders
## and the stiffened deck. RoadBuilder leaves the OSM deck out of their
## span (LandmarkSites.outside_spans), so this deck is the road.

## Golden Gate Bridge (1937): 1280 m main span and 343 m side spans; the
## two Art Deco towers 227 m above the water, each two cellular steel
## legs (16.5 x 10 m at the base) stepping in above each of the four
## portal struts, X-braced below the deck; the 0.92 m main cables 27.4 m
## apart on the 7.6 m deep Warren stiffening truss with its 67 m
## clearance, suspender pairs every 15.24 m (50 ft), lamp standards on
## the rail, the elliptical fender round the south pier (−X), all in
## International Orange.
const GG_MAIN := 1280.0
const GG_SIDE := 343.0
const GG_TOWER_M := 227.0
const GG_DECK_M := 67.0
const GG_HALF_W := 13.7
const GG_TRUSS_M := 7.62
const GG_SUSP := 15.24
## Leg stages [y0, y1, along x, across z]; each steps in over a strut.
const GG_STAGES := [[12.0, 104.0, 16.5, 10.0], [104.0, 144.0, 14.5, 9.0],
	[144.0, 180.0, 12.5, 8.0], [180.0, 221.0, 10.5, 7.0]]

static func golden_gate(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Orange", LandmarkMaterials.paint("#C0362C", 0.6, 0.3))
	lm.use("Deck", LandmarkMaterials.pbr("asphalt", "#3B3B3B", 4.0))
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#B9B3A8", 4.0))
	lm.use("Cable", LandmarkMaterials.paint("#B8352B", 0.5, 0.35))
	lm.use("Lamp", LandmarkMaterials.lit("#FFC77A", 1.2))
	var tx := GG_MAIN * 0.5
	var end := tx + GG_SIDE
	for s in [-1.0, 1.0]:
		_gg_tower(lm, float(s) * tx, s < 0.0)
	_gg_cables(lm, tx, end)
	_gg_deck(lm, end)
	# Anchorage housings at both ends: stepped concrete blocks with the
	# Art Deco pylons either side of the roadway.
	for s in [-1.0, 1.0]:
		var ax: float = s * (end + 18.0)
		lm.box("Concrete", Vector3(ax, (GG_DECK_M + 6.0) * 0.5, 0), Vector3(36.0, GG_DECK_M + 6.0, 44.0))
		lm.box("Concrete", Vector3(ax, 3.0, 0), Vector3(40.0, 6.0, 48.0))
		for k in 5:
			var y := 10.0 + 12.0 * k
			lm.box("Concrete", Vector3(ax, y, 0), Vector3(36.8, 0.8, 44.8))
		for side in [-1.0, 1.0]:
			var pz: float = side * (GG_HALF_W + 4.5)
			var pb := Vector3(float(s) * (end - 2.0), GG_DECK_M, pz)
			lm.box("Concrete", pb + Vector3(0, 7.0, 0), Vector3(7.0, 14.0, 5.0))
			lm.box("Concrete", pb + Vector3(0, 15.0, 0), Vector3(5.6, 2.0, 4.0))
			for f in [-1.0, 1.0]:
				for k in 3:
					lm.box("Concrete", pb + Vector3(float(f) * 3.6, 7.0, -1.6 + 1.6 * k), Vector3(0.4, 12.0, 0.6))
	lm.commit(model)

## One tower: concrete pier (and the south pier's fender), the two legs
## in four set-back stages with Art Deco fluting, four portal struts
## above the deck faced with vertical fins, X-bracing below the deck,
## saddle housings and beacons on top.
static func _gg_tower(lm: LandmarkMesh, x: float, south: bool) -> void:
	# Pier: a rounded-end slab 12 m above the water.
	var pier := PackedVector2Array()
	for k in 17:
		var a := PI * float(k) / 16.0
		pier.append(Vector2(x + cos(a) * 17.0, 26.0 + sin(a) * 17.0))
	for k in 17:
		var a := PI + PI * float(k) / 16.0
		pier.append(Vector2(x + cos(a) * 17.0, -26.0 + sin(a) * 17.0))
	lm.poly_prism("Concrete", pier, 0.0, 12.0)
	if south:
		# Elliptical fender wall round the south pier (155 x 300 ft).
		var n := 40
		for k in n:
			var a0 := TAU * float(k) / n
			var a1 := TAU * float(k + 1) / n
			var p0 := Vector3(x + cos(a0) * 24.0, 0, sin(a0) * 46.0)
			var p1 := Vector3(x + cos(a1) * 24.0, 0, sin(a1) * 46.0)
			var d := p1 - p0
			lm.box("Concrete", (p0 + p1) * 0.5 + Vector3(0, 7.0, 0), Vector3(d.length() + 0.3, 14.0, 3.0),
				Basis(Vector3.UP, atan2(-d.z, d.x)))
	for side in [-1.0, 1.0]:
		var z: float = side * GG_HALF_W
		for st in GG_STAGES:
			var y0 := float(st[0])
			var y1 := float(st[1])
			var dx := float(st[2])
			var dz := float(st[3])
			var c := Vector3(x, (y0 + y1) * 0.5, z)
			lm.box("Orange", c, Vector3(dx, y1 - y0, dz))
			# Set-back ledge and the vertical fluting on all four faces.
			lm.box("Orange", Vector3(x, y1 - 0.4, z), Vector3(dx + 0.8, 0.8, dz + 0.8))
			for f in [-1.0, 1.0]:
				for k in 3:
					lm.box("Orange", c + Vector3(float(f) * (dx * 0.5 + 0.2), 0, (k - 1) * dz * 0.3),
						Vector3(0.5, y1 - y0 - 3.0, 0.9))
				for k in 2:
					lm.box("Orange", c + Vector3((k - 0.5) * dx * 0.45, 0, float(f) * (dz * 0.5 + 0.2)),
						Vector3(1.2, y1 - y0 - 3.0, 0.5))
	# Portal struts between the legs: each under a set-back, the top one
	# capping the tower, faced with vertical Art Deco fins and stepped.
	var struts := [[GG_DECK_M - 5.0, 8.0], [100.0, 7.0], [140.0, 7.0], [176.0, 7.0], [216.0, 9.0]]
	for i in struts.size():
		var sy := float(struts[i][0])
		var sh := float(struts[i][1])
		var st: Array = GG_STAGES[mini(maxi(i - 1, 0), 3)] if i > 0 else GG_STAGES[0]
		var sdx := float(st[2]) - 3.0
		var gap := GG_HALF_W * 2.0 - float(st[3])
		lm.box("Orange", Vector3(x, sy, 0), Vector3(sdx, sh, gap))
		lm.box("Orange", Vector3(x, sy + sh * 0.5 + 0.5, 0), Vector3(sdx - 1.6, 1.0, gap - 2.0))
		if i == 0:
			continue
		var fins := int(gap / 1.8)
		for f in [-1.0, 1.0]:
			for k in fins:
				var fz := -gap * 0.5 + gap * (float(k) + 0.5) / fins
				var tall := sh - (0.0 if k % 2 == 0 else 1.2)
				lm.box("Orange", Vector3(x + float(f) * (sdx * 0.5 + 0.25), sy - (sh - tall) * 0.5, fz),
					Vector3(0.5, tall, 0.7))
	# X-bracing between the legs below the deck, on both faces.
	for f in [-1.0, 1.0]:
		var bx: float = x + f * 5.0
		lm.lattice_panel("Orange", Vector3(bx, 14.0, -GG_HALF_W + 5.0), Vector3(bx, 14.0, GG_HALF_W - 5.0),
			Vector3(bx, GG_DECK_M - 10.0, -GG_HALF_W + 5.0), Vector3(bx, GG_DECK_M - 10.0, GG_HALF_W - 5.0), 1.4, 2)
	# Saddle housings over the cables, and the aircraft beacons.
	for side in [-1.0, 1.0]:
		var z: float = side * GG_HALF_W
		lm.box("Orange", Vector3(x, 223.0, z), Vector3(9.0, 4.0, 6.0))
		lm.lathe("Orange", Vector3(x, 225.0, z), PackedVector2Array([Vector2(1.0, 0), Vector2(0.96, 0.8),
			Vector2(0.7, 1.6), Vector2(0.0, GG_TOWER_M - 225.0)]), 12, 4.4, 2.9)
		lm.box("Lamp", Vector3(x, GG_TOWER_M - 0.3, z), Vector3(0.6, 0.6, 0.6), Basis(), 0.0)

## Main cables tower to tower and down to the anchorages, cable bands
## and the suspender rope pairs every 15.24 m.
static func _gg_cables(lm: LandmarkMesh, tx: float, end: float) -> void:
	var top := GG_TOWER_M - 3.0
	var low := GG_DECK_M + 3.0
	var anchor := GG_DECK_M + 4.0
	for side in [-1.0, 1.0]:
		var z: float = side * GG_HALF_W
		LandmarkCoreBBridgeKit.tube(lm, "Cable", LandmarkCoreBBridgeKit.sag_points(Vector3(-tx, top, z),
			Vector3(tx, top, z), top - low, 84), 0.46, 10)
		for s in [-1.0, 1.0]:
			LandmarkCoreBBridgeKit.tube(lm, "Cable", LandmarkCoreBBridgeKit.sag_points(Vector3(s * tx, top, z),
				Vector3(s * end, anchor, z), 18.0, 24), 0.46, 10)
		var x := -end + GG_SUSP * 0.5
		while x < end:
			var cy := _cable_y(x, tx, end, top, low, anchor, 18.0)
			if cy - GG_DECK_M > 2.0 and absf(absf(x) - tx) > 6.0:
				for o in [-0.3, 0.3]:
					lm.beam("Cable", Vector3(x + float(o), GG_DECK_M + 0.6, z), Vector3(x + float(o), cy, z), 0.12, 0.12)
				lm.box("Cable", Vector3(x, cy, z), Vector3(1.4, 1.2, 1.2))
				lm.box("Orange", Vector3(x, GG_DECK_M + 0.8, z), Vector3(1.0, 0.6, 0.6), Basis(), 0.0)
			x += GG_SUSP

## Deck: roadway and raised sidewalks, the two Warren stiffening trusses
## under the rails, floor beams and the lateral X-bracing, the rail with
## its posts and the lamp standards.
static func _gg_deck(lm: LandmarkMesh, end: float) -> void:
	var length := end * 2.0
	lm.box("Deck", Vector3(0, GG_DECK_M + 0.2, 0), Vector3(length, 0.4, GG_HALF_W * 2.0 - 6.0))
	for side in [-1.0, 1.0]:
		lm.box("Concrete", Vector3(0, GG_DECK_M + 0.35, float(side) * (GG_HALF_W - 1.6)), Vector3(length, 0.7, 3.2))
	var n := int(length / GG_TRUSS_M)
	var pitch := length / n
	var yb := GG_DECK_M - GG_TRUSS_M
	for side in [-1.0, 1.0]:
		var z: float = side * GG_HALF_W
		var bottom := PackedVector3Array()
		var top := PackedVector3Array()
		for k in n + 1:
			var x := -end + pitch * k
			bottom.append(Vector3(x, yb, z))
			top.append(Vector3(x, GG_DECK_M - 0.4, z))
		LandmarkCoreBBridgeKit.truss(lm, "Orange", bottom, top, 1.0, 0.55, Vector3(0, 0, 1), true, false)
		lm.box("Orange", Vector3(0, yb, z), Vector3(length, 1.0, 1.0))
		lm.box("Orange", Vector3(0, GG_DECK_M - 0.4, z), Vector3(length, 1.0, 1.0))
		# Rail and posts on the outer edge.
		var rz: float = side * (GG_HALF_W + 0.2)
		lm.box("Orange", Vector3(0, GG_DECK_M + 1.3, rz), Vector3(length, 0.15, 0.25), Basis(), 0.0)
		lm.box("Orange", Vector3(0, GG_DECK_M + 0.8, rz), Vector3(length, 0.1, 0.15), Basis(), 0.0)
		for k in n:
			var x := -end + pitch * (k + 0.5)
			lm.beam("Orange", Vector3(x, GG_DECK_M + 0.6, rz), Vector3(x, GG_DECK_M + 1.3, rz), 0.15, 0.15)
			if k % 6 == 3:
				LandmarkCoreBBridgeKit.lamp(lm, "Orange", "Lamp", Vector3(x, GG_DECK_M + 0.7, side * (GG_HALF_W - 0.6)),
					7.5, Vector3(0, 0, -side * 1.2))
	# Floor beams at every panel point and lateral X-bracing below.
	for k in n + 1:
		var x := -end + pitch * k
		lm.beam("Orange", Vector3(x, GG_DECK_M - 1.2, -GG_HALF_W), Vector3(x, GG_DECK_M - 1.2, GG_HALF_W), 0.6, 1.6)
		if k < n and k % 2 == 0:
			var x1 := x + pitch * 2.0
			lm.beam("Orange", Vector3(x, yb, -GG_HALF_W), Vector3(minf(x1, end), yb, GG_HALF_W), 0.4, 0.4)
			lm.beam("Orange", Vector3(x, yb, GG_HALF_W), Vector3(minf(x1, end), yb, -GG_HALF_W), 0.4, 0.4)

## Brooklyn Bridge (1883): 486.3 m main span and 283.5 m side spans.
## The granite-and-limestone towers rise 84.3 m above the water on
## 18 x 42.7 m bases; above the roadway (36.3 m at the towers) three
## piers carry the two pointed Gothic arches, 10.3 m wide with ~14 m
## radius arcs, their crowns 35.7 m (117 ft) over the road, under the
## cornice and parapet. Four 0.4 m main cables, suspenders every 2.3 m
## and the diagonal stays fanning from each tower top web the spans; six
## stiffening trusses carry the two roadways and the raised promenade
## down the middle, 41 m over the river at mid-span, and the deck falls
## to the masonry anchorages (27 m) 283.5 m beyond each tower.
const BB_MAIN := 486.3
const BB_SIDE := 283.5
const BB_TOWER_M := 84.3
const BB_DECK_M := 41.0
const BB_TOWER_DECK_M := 36.3
const BB_END_DECK_M := 27.0
const BB_TOWER := Vector2(18.0, 42.7)
const BB_ARCH_W := 10.3
const BB_ARCH_R := 14.0
const BB_ARCH_TOP := 72.0
const BB_TRUSS_M := 5.2

static func brooklyn(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#B5A894", 3.0))
	lm.use("Steel", LandmarkMaterials.paint("#8C8778", 0.55, 0.4))
	lm.use("Deck", LandmarkMaterials.pbr("asphalt", "#3B3B3B", 4.0))
	lm.use("Shadow", LandmarkMaterials.paint("#2A2A28", 0.9, 0.0))
	lm.use("Boards", LandmarkMaterials.pbr("wood", "#8A7458", 2.0))
	lm.use("Lamp", LandmarkMaterials.lit("#FFD9A0", 1.0))
	var tx := BB_MAIN * 0.5
	var end := tx + BB_SIDE
	for s in [-1.0, 1.0]:
		_bb_tower(lm, float(s) * tx)
		_bb_anchorage(lm, float(s) * (end + 20.0))
	_bb_deck_build(lm, tx, end)
	_bb_cables(lm, tx, end)
	lm.commit(model)

## Roadway height: 41 m at mid-span, 36.3 m at the towers (a parabola),
## falling straight to the anchorages.
static func _bb_deck(x: float, end: float) -> float:
	var tx := BB_MAIN * 0.5
	var ax := absf(x)
	if ax <= tx:
		var u := ax / tx
		return lerpf(BB_DECK_M, BB_TOWER_DECK_M, u * u)
	return lerpf(BB_TOWER_DECK_M, BB_END_DECK_M, clampf((ax - tx) / (end - tx), 0.0, 1.0))

## One masonry tower: water table and base, three stepped piers, the
## pointed arches with hood mouldings and soffits, the attic, cornice
## and parapet, and the cable saddles on top.
static func _bb_tower(lm: LandmarkMesh, x: float) -> void:
	var hx := BB_TOWER.x * 0.5
	var hz := BB_TOWER.y * 0.5
	var td := BB_TOWER_DECK_M
	# Base: plinth (water table), shaft and string course to the road.
	lm.box("Granite", Vector3(x, 2.5, 0), Vector3(BB_TOWER.x + 2.0, 5.0, BB_TOWER.y + 2.0))
	lm.box("Granite", Vector3(x, 5.4, 0), Vector3(BB_TOWER.x + 1.2, 0.8, BB_TOWER.y + 1.2))
	lm.box("Granite", Vector3(x, (5.0 + td) * 0.5, 0), Vector3(BB_TOWER.x, td - 5.0, BB_TOWER.y))
	lm.box("Granite", Vector3(x, td - 1.0, 0), Vector3(BB_TOWER.x + 0.8, 1.2, BB_TOWER.y + 0.8))
	# Recessed panels on the long faces of the base.
	for f in [-1.0, 1.0]:
		for k in 3:
			lm.box("Shadow", Vector3(x + float(f) * (hx + 0.02), (6.0 + td) * 0.5, (k - 1) * 14.0),
				Vector3(0.1, td - 12.0, 6.0), Basis(), 0.0)
	var oz := BB_ARCH_W * 0.5 + 4.0
	var spring := BB_ARCH_TOP - sqrt(BB_ARCH_R * BB_ARCH_R - pow(BB_ARCH_R - BB_ARCH_W * 0.5, 2.0))
	# Three piers in stages, each a little slimmer [y0, y1, x depth, inset].
	var stages := [[td, 52.0, BB_TOWER.x, 0.0], [52.0, BB_ARCH_TOP, BB_TOWER.x - 1.0, 0.5]]
	for st in stages:
		var y0 := float(st[0])
		var y1 := float(st[1])
		var dx := float(st[2])
		var ins := float(st[3])
		for pz in [-1.0, 0.0, 1.0]:
			var z0: float
			var z1: float
			if pz == 0.0:
				z0 = -oz + BB_ARCH_W * 0.5
				z1 = -z0
			else:
				z0 = float(pz) * (oz + BB_ARCH_W * 0.5)
				z1 = float(pz) * (hz - ins)
			lm.box("Granite", Vector3(x, (y0 + y1) * 0.5, (z0 + z1) * 0.5), Vector3(dx, y1 - y0, absf(z1 - z0)))
			# Pilaster strips framing each pier face.
			for f in [-1.0, 1.0]:
				for e in [z0, z1]:
					var ez: float = e - signf(e - (z0 + z1) * 0.5) * 0.6
					lm.box("Granite", Vector3(x + float(f) * (dx * 0.5 + 0.2), (y0 + y1) * 0.5, ez),
						Vector3(0.4, y1 - y0 - 1.0, 1.2))
		lm.box("Granite", Vector3(x, y1 - 0.4, 0), Vector3(dx + 0.8, 0.8, (hz - ins) * 2.0 + 0.8))
	# Pointed arch heads: soffit, spandrels on both faces, hood moulding.
	var dx2 := BB_TOWER.x - 1.0
	for s in [-1.0, 1.0]:
		var cz: float = s * oz
		var arc := _bb_arch_arc(cz, spring)
		for f in [-1.0, 1.0]:
			var fx: float = x + f * dx2 * 0.5
			var nrm := Vector3(f, 0, 0)
			for half in 2:
				var corner := Vector3(fx, BB_ARCH_TOP, cz + (-1.0 if half == 0 else 1.0) * BB_ARCH_W * 0.5)
				var pts: PackedVector3Array = arc[half]
				for i in pts.size() - 1:
					var a := Vector3(fx, pts[i].y, pts[i].z)
					var b := Vector3(fx, pts[i + 1].y, pts[i + 1].z)
					lm.tri("Granite", corner, a, b, nrm, nrm, nrm, Vector2(corner.z, -corner.y),
						Vector2(a.z, -a.y), Vector2(b.z, -b.y))
				# Hood moulding over the arch.
				for i in pts.size() - 1:
					var a := Vector3(fx + f * 0.3, pts[i].y + 0.5, pts[i].z)
					var b := Vector3(fx + f * 0.3, pts[i + 1].y + 0.5, pts[i + 1].z)
					lm.beam("Granite", a, b, 0.7, 0.6, Vector3(1, 0, 0))
		for half in 2:
			var pts: PackedVector3Array = arc[half]
			for i in pts.size() - 1:
				var p0 := pts[i]
				var p1 := pts[i + 1]
				var inward := Vector3(0, -(p0.y + p1.y) * 0.5 + spring, -((p0.z + p1.z) * 0.5 - cz)).normalized()
				lm.quad("Granite", Vector3(x - dx2 * 0.5, p0.y, p0.z), Vector3(x + dx2 * 0.5, p0.y, p0.z),
					Vector3(x + dx2 * 0.5, p1.y, p1.z), Vector3(x - dx2 * 0.5, p1.y, p1.z), inward)
	# Attic over the arches, the reentrant panels, cornice and parapet.
	var top_dx := BB_TOWER.x - 2.0
	var attic := BB_TOWER_M - 4.0
	lm.box("Granite", Vector3(x, (BB_ARCH_TOP + attic) * 0.5, 0), Vector3(dx2, attic - BB_ARCH_TOP, (hz - 0.5) * 2.0))
	for f in [-1.0, 1.0]:
		for k in 4:
			lm.box("Shadow", Vector3(x + float(f) * (dx2 * 0.5 + 0.02), (BB_ARCH_TOP + attic) * 0.5 + 0.5,
				-15.0 + 10.0 * k), Vector3(0.1, attic - BB_ARCH_TOP - 4.0, 3.0), Basis(), 0.0)
	var cy := attic
	for f in [-1.0, 1.0]:
		LandmarkDetail.cornice(lm, "Granite", Vector3(x + float(f) * dx2 * 0.5, cy, -hz + 0.5),
			Vector3(x + float(f) * dx2 * 0.5, cy, hz - 0.5), Vector3(f, 0, 0), 1.6)
		LandmarkDetail.cornice(lm, "Granite", Vector3(x - dx2 * 0.5, cy, float(f) * (hz - 0.5)),
			Vector3(x + dx2 * 0.5, cy, float(f) * (hz - 0.5)), Vector3(0, 0, f), 1.6)
	lm.box("Granite", Vector3(x, cy + 2.4, 0), Vector3(top_dx, 1.6, BB_TOWER.y - 3.0))
	# Cable saddle housings, the cables riding over the tower top.
	for cz in [-12.0, -4.0, 4.0, 12.0]:
		lm.box("Granite", Vector3(x, BB_TOWER_M - 0.7, float(cz)), Vector3(top_dx - 2.0, 1.4, 2.4))

## The two halves (springing to crown) of a pointed arch centred at z =
## cz: each a PackedVector3Array of (0, y, z) points.
static func _bb_arch_arc(cz: float, spring: float) -> Array:
	var hs := BB_ARCH_W * 0.5
	var off := BB_ARCH_R - hs
	var tmax := acos(off / BB_ARCH_R)
	var out: Array = []
	for half in 2:
		var sgn := -1.0 if half == 0 else 1.0
		var centre := cz - sgn * off
		var pts := PackedVector3Array()
		for k in 9:
			var t := tmax * float(k) / 8.0
			pts.append(Vector3(0, spring + BB_ARCH_R * sin(t), centre + sgn * BB_ARCH_R * cos(t)))
		out.append(pts)
	return out

## A masonry anchorage: plinth, battered block with arched vaults on its
## long faces, pilasters, cornice and parapet.
static func _bb_anchorage(lm: LandmarkMesh, x: float) -> void:
	var h := BB_END_DECK_M
	lm.box("Granite", Vector3(x, 1.5, 0), Vector3(42.0, 3.0, 38.0))
	lm.box("Granite", Vector3(x, h * 0.5, 0), Vector3(40.0, h, 36.0))
	for f in [-1.0, 1.0]:
		for k in 3:
			var vx := x - 12.0 + 12.0 * k
			lm.box("Shadow", Vector3(vx, 5.5, float(f) * 18.02), Vector3(6.0, 9.0, 0.1), Basis(), 0.0)
			lm.disc("Shadow", Vector3(vx, 10.0, float(f) * 18.03), Vector3(0, 0, f), 3.0, 12)
			LandmarkDetail.arch(lm, "Granite", Vector3(vx, 10.0, float(f) * 18.0), Vector3(0, 0, f), 6.0)
		for k in 5:
			lm.box("Granite", Vector3(x - 20.0 + 10.0 * k, h * 0.5, float(f) * 18.3), Vector3(1.6, h - 2.0, 0.6))
		LandmarkDetail.cornice(lm, "Granite", Vector3(x - 20.0, h - 1.5, float(f) * 18.0),
			Vector3(x + 20.0, h - 1.5, float(f) * 18.0), Vector3(0, 0, f), 1.4)
	lm.box("Granite", Vector3(x, h + 0.6, 0), Vector3(40.0, 1.2, 36.0))

## Deck: two roadways and the raised boardwalk promenade on six
## stiffening trusses that follow the deck's rise, floor beams, the
## promenade rails and lamps.
static func _bb_deck_build(lm: LandmarkMesh, tx: float, end: float) -> void:
	var step := 7.5
	var n := int(end * 2.0 / step)
	var pts: Array[float] = []
	for k in n + 1:
		pts.append(-end + end * 2.0 * k / n)
	var truss_z := [-13.0, -8.5, -4.0, 4.0, 8.5, 13.0]
	for tz in truss_z:
		var z: float = tz
		var bottom := PackedVector3Array()
		var top := PackedVector3Array()
		for x in pts:
			var y := _bb_deck(x, end)
			bottom.append(Vector3(x, y - 0.6, z))
			top.append(Vector3(x, y + BB_TRUSS_M - 0.6, z))
		var w := 0.45 if absf(z) > 10.0 or absf(z) < 5.0 else 0.3
		LandmarkCoreBBridgeKit.truss(lm, "Steel", bottom, top, 0.7, w, Vector3(0, 0, 1), true, true)
	for k in n:
		var xa := pts[k]
		var xb := pts[k + 1]
		var ya := _bb_deck(xa, end)
		var yb := _bb_deck(xb, end)
		var r := Basis(Vector3.BACK, atan2(yb - ya, xb - xa))
		var c := Vector3((xa + xb) * 0.5, (ya + yb) * 0.5, 0)
		var seg := Vector3(xb - xa + 0.05, 0.4, 0)
		# Roadways either side, boardwalk on top in the middle.
		for side in [-1.0, 1.0]:
			lm.box("Deck", c + Vector3(0, 0.1, float(side) * 8.5), seg + Vector3(0, 0, 8.6), r, 0.0)
		lm.box("Boards", c + Vector3(0, BB_TRUSS_M - 0.4, 0), seg + Vector3(0, -0.2, 8.0), r, 0.0)
		lm.beam("Steel", Vector3(xa, ya - 1.0, -13.2), Vector3(xa, ya - 1.0, 13.2), 0.4, 0.9)
		# Promenade rails, a lamp every 30 m.
		for side in [-1.0, 1.0]:
			var rz: float = side * 4.2
			lm.beam("Steel", Vector3(xa, ya + BB_TRUSS_M + 0.6, rz), Vector3(xb, yb + BB_TRUSS_M + 0.6, rz), 0.08, 0.08)
			if k % 4 == 0 and absf(absf(xa) - tx) > 12.0:
				LandmarkCoreBBridgeKit.lamp(lm, "Steel", "Lamp", Vector3(xa, ya + BB_TRUSS_M - 0.2, rz), 3.6,
					Vector3(0, 0, -float(side) * 0.6))

## Four main cables, the close-set suspenders and the diagonal stays
## fanning from the tower tops.
static func _bb_cables(lm: LandmarkMesh, tx: float, end: float) -> void:
	var top := BB_TOWER_M - 1.0
	var low := BB_DECK_M + BB_TRUSS_M + 1.0
	var anchor := BB_END_DECK_M + 2.0
	for cz in [-12.0, -4.0, 4.0, 12.0]:
		var z: float = cz
		LandmarkCoreBBridgeKit.tube(lm, "Steel", LandmarkCoreBBridgeKit.sag_points(Vector3(-tx, top, z),
			Vector3(tx, top, z), top - low, 48), 0.22, 8)
		for s in [-1.0, 1.0]:
			LandmarkCoreBBridgeKit.tube(lm, "Steel", LandmarkCoreBBridgeKit.sag_points(Vector3(s * tx, top, z),
				Vector3(s * (end + 2.0), anchor, z), 8.0, 20), 0.22, 8)
		var x := -end + 2.3
		while x < end:
			var cy := _cable_y(x, tx, end + 2.0, top, low, anchor, 8.0)
			var dy := _bb_deck(x, end) + BB_TRUSS_M - 0.6
			if absf(absf(x) - tx) > 10.0 and cy - dy > 0.8:
				lm.beam("Steel", Vector3(x, dy, z), Vector3(x, cy, z), 0.07, 0.07)
			x += 2.3
		for s in [-1.0, 1.0]:
			for k in range(1, 15):
				for dirn in [-1.0, 1.0]:
					var dx: float = s * tx + dirn * 11.0 * k
					if absf(dx) > end:
						continue
					lm.beam("Steel", Vector3(s * tx + dirn * 9.0, top - 1.5, z),
						Vector3(dx, _bb_deck(dx, end) + BB_TRUSS_M - 0.6, z), 0.1, 0.1)

## Height of a main cable at x: a parabola between the towers (±tx) down
## to `low` at mid-span, and a sagging side span to the anchorage (±end,
## `anchor`), `side_sag` below its chord.
static func _cable_y(x: float, tx: float, end: float, top: float, low: float, anchor: float,
		side_sag: float) -> float:
	var ax := absf(x)
	if ax <= tx:
		var u := ax / tx
		return low + (top - low) * u * u
	var t := clampf((ax - tx) / (end - tx), 0.0, 1.0)
	return lerpf(top, anchor, t) - side_sag * 4.0 * t * (1.0 - t)
