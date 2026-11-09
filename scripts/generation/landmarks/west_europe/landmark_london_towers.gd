class_name LandmarkLondonTowers
extends RefCounted

## The two City / Southwark glass towers in true metres, y = 0 at street
## level: The Shard and 30 St Mary Axe.
##
## The Shard (309.6 m, Renzo Piano, 2012; 95 storeys, 72 of them
## habitable, view levels 68-72 with the open deck at 244.3 m, the 66 m
## steel spire above). The plan is the surveyed OSM outline (way
## 31110737, 21 vertices, 3,730 m2, built from the registry point
## 4.5 m east and 10.4 m south of the model origin): an irregular kite
## about 75 x 99 m. Every glass shard is a plane through a base edge and
## the spire tip, so the tower narrows linearly (about 21 m across at
## the 244 m deck) and each shard leans at its own angle. Short plan
## edges (under 8 m) are the dark fracture vents between shards. Above
## about 250 m each shard ends in its own slanting cut, so the glass
## splinters apart round the open steel spire. The mullion grid is
## 2 m wide and runs down the fall line of each shard, with a spandrel
## line every 3.9 m.
##
## 30 St Mary Axe, "the Gherkin" (180 m, Foster + Partners, 2003; 41
## storeys of 4.15 m): circular plan 49 m at the foot, 56.5 m at its
## belly (OSM outline 56.5 m), tapering to a 16.8 m top floor under the
## 14 m glass lens. Its skin is a flat-panelled 36-sided polygon (every
## panel flat except the lens) on a fully triangulated steel diagrid:
## 18 nodes a ring, a ring every two storeys (8.3 m), diagonals
## rising half a node pitch a level in both hands, a hoop at each node
## level. Six light wells spiral 5 degrees a storey up the facade and
## are interrupted by a firebreak every sixth floor.

const FLOOR_PITCH := 3.9
const SHARD_H := 309.6
const DECK_Y := 244.3
const SHARD_CENTRE := Vector2(4.48, 10.39)
const FLOOR_H := 4.15
const NODE_H := 8.3
const LENS_BASE := 166.0
static func _gherkin_table() -> PackedVector2Array:
	return PackedVector2Array([Vector2(0.0, 24.5), Vector2(6.0, 25.3),
	Vector2(20.0, 27.0), Vector2(40.0, 28.0), Vector2(60.0, 28.25), Vector2(80.0, 27.3),
	Vector2(100.0, 25.0), Vector2(120.0, 21.5), Vector2(140.0, 16.8), Vector2(152.0, 13.2),
	Vector2(160.0, 10.6), Vector2(166.0, 8.4)])


# --- The Shard ---------------------------------------------------------

## Surveyed plan (x east, z south, metres from the registry point), with
## the collinear runs merged and the south-east notch closed.
static func _plan() -> PackedVector2Array:
	return PackedVector2Array([Vector2(26.8, 61.1), Vector2(3.2, 39.7),
		Vector2(-35.3, 14.1), Vector2(-34.6, 12.7), Vector2(-24.7, -9.3), Vector2(-26.2, -12.1),
		Vector2(-2.6, -32.8), Vector2(17.1, -22.7), Vector2(15.9, -19.5), Vector2(32.2, -5.1),
		Vector2(29.3, 1.6), Vector2(29.5, 8.3), Vector2(38.7, 15.6), Vector2(26.6, 31.1),
		Vector2(35.8, 42.0)])

static func shard(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Glass", LandmarkMaterials.glass("#A9C2CF"))
	lm.use("GlassB", LandmarkMaterials.glass("#8FABBA"))
	lm.use("Dark", LandmarkMaterials.glass("#26323A"))
	lm.use("Fins", LandmarkMaterials.paint("#C9D1D6", 0.3, 0.85))
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#A9A59C", 4.0))
	var base: Array[Vector2] = []
	for p in _plan():
		base.append(p - SHARD_CENTRE)
	for k in base.size():
		_facet(lm, base, k)
	_shard_base(lm, base)
	_shard_deck_and_spire(lm, base)
	lm.commit(model)

## Point on the plane through base point b and the spire tip, at height
## fraction t (0 foot, 1 tip).
static func _spt(b: Vector2, t: float) -> Vector3:
	return Vector3(b.x * (1.0 - t), t * SHARD_H, b.y * (1.0 - t))

## Height fraction at which a shard ends, at its left (side 0) or right
## (side 1) ridge: 0.81-0.97, a different value for every ridge end so
## neighbouring shards split apart toward the top.
static func _top(k: int, side: int) -> float:
	var f := fposmod(sin(float(k * 2 + side) * 12.9898 + 4.1) * 43758.5453, 1.0)
	return 0.81 + 0.16 * f

## One shard between base vertices k and k + 1.
static func _facet(lm: LandmarkMesh, base: Array[Vector2], k: int) -> void:
	var b0: Vector2 = base[k]
	var b1: Vector2 = base[(k + 1) % base.size()]
	var edge := b0.distance_to(b1)
	var vent := edge < 8.0
	var ta := _top(k, 0)
	var tb := _top(k, 1)
	var mat := "Dark" if vent else ("Glass" if k % 2 == 0 else "GlassB")
	var nrm := (_spt(b1, 0.0) - _spt(b0, 0.0)).cross(_spt(b0.lerp(b1, 0.5), 0.6) - _spt(b0, 0.0)).normalized()
	var mid := _spt(b0.lerp(b1, 0.5), 0.3)
	if nrm.dot(Vector3(mid.x, 0.0, mid.z)) < 0.0:
		nrm = -nrm
	var strips := 3 if vent else 8
	for s in strips:
		var u0 := float(s) / float(strips)
		var u1 := float(s + 1) / float(strips)
		var p00 := _spt(b0.lerp(b1, u0), 0.0)
		var p10 := _spt(b0.lerp(b1, u1), 0.0)
		var p11 := _spt(b0.lerp(b1, u1), lerpf(ta, tb, u1))
		var p01 := _spt(b0.lerp(b1, u0), lerpf(ta, tb, u0))
		lm.quad(mat, p00, p10, p11, p01, nrm)
		var off := Vector3(nrm.x, 0.0, nrm.z).normalized() * 0.15
		lm.quad("Dark", p00 - off, p10 - off, p11 - off, p01 - off, -nrm)
	if vent:
		# Open winter-garden vents: a louvre fin across the slot every 4 floors.
		var yv := 15.6
		while yv < 0.88 * SHARD_H:
			var tv := yv / SHARD_H
			lm.beam("Fins", _spt(b0, tv) + nrm * 0.12, _spt(b1, tv) + nrm * 0.12, 0.3, 0.2)
			yv += 15.6
		return
	var along := Vector3(b1.x - b0.x, 0.0, b1.y - b0.y).normalized()
	# Spandrel line every floor (every shard ends in its own cut).
	var y := FLOOR_PITCH
	while y < 0.97 * SHARD_H:
		var t := y / SHARD_H
		if t >= maxf(ta, tb):
			break
		var lo := 0.0
		var hi := 1.0
		if t > minf(ta, tb):
			if tb > ta:
				lo = (t - ta) / (tb - ta)
			else:
				hi = (ta - t) / (ta - tb)
		if hi - lo > 0.03:
			var p0 := _spt(b0.lerp(b1, lo), t) + nrm * 0.09
			var p1 := _spt(b0.lerp(b1, hi), t) + nrm * 0.09
			var w := 0.16
			# Thicker slab lines for the view levels 68, 69 and 72.
			if absf(y - 224.0) < 2.0 or absf(y - 231.4) < 2.0 or absf(y - 243.8) < 2.0:
				w = 0.42
			lm.beam("Fins", p0, p1, w, 0.12, nrm.cross(p1 - p0))
		y += FLOOR_PITCH
	_mullions(lm, b0, b1, ta, tb, nrm, along, edge)
	# The view galleries: darker glazing over levels 68-72.
	var ya := 225.0 / SHARD_H
	var yb := 243.5 / SHARD_H
	var goff := nrm * 0.07
	lm.quad("Dark", _spt(b0, ya) + goff, _spt(b1, ya) + goff, _spt(b1, yb) + goff,
		_spt(b0, yb) + goff, nrm)

## Mullions 2 m apart down the fall line of the shard, each running up
## until it meets a ridge or the shard's cut.
static func _mullions(lm: LandmarkMesh, b0: Vector2, b1: Vector2, ta: float, tb: float,
		nrm: Vector3, along: Vector3, edge: float) -> void:
	var slope := nrm.cross(along).normalized()
	if slope.y < 0.0:
		slope = -slope
	var e2 := Vector2(along.x, along.z)
	var al := -b0.dot(e2)
	var count := int(edge / 2.0)
	for m in count:
		var w0 := (float(m) + 0.5) * edge / float(count)
		var t := 0.0
		var t_end := 0.0
		while t < 0.99:
			t += 0.002
			var u := (w0 - t * al) / ((1.0 - t) * edge)
			if u < 0.0 or u > 1.0 or t > lerpf(ta, tb, u):
				break
			t_end = t
		if t_end < 0.01:
			continue
		var q0 := _spt(b0.lerp(b1, w0 / edge), 0.003) + nrm * 0.1
		var y_end := t_end * SHARD_H
		var q1 := q0 + slope * ((y_end - q0.y) / slope.y)
		lm.beam("Fins", q0, q1, 0.12, 0.12, along)

## Ground floor: dark glazed lobby band, entrance canopies on the long
## faces, and the paved plaza round the foot.
static func _shard_base(lm: LandmarkMesh, base: Array[Vector2]) -> void:
	var n := base.size()
	for k in n:
		var b0: Vector2 = base[k]
		var b1: Vector2 = base[(k + 1) % n]
		var edge := b0.distance_to(b1)
		if edge < 12.0:
			continue
		var nrm := (_spt(b1, 0.0) - _spt(b0, 0.0)).cross(_spt(b0.lerp(b1, 0.5), 0.6) - _spt(b0, 0.0)).normalized()
		var mid := _spt(b0.lerp(b1, 0.5), 0.3)
		if nrm.dot(Vector3(mid.x, 0.0, mid.z)) < 0.0:
			nrm = -nrm
		var th := 9.0 / SHARD_H
		var off := nrm * 0.06
		lm.quad("Dark", _spt(b0.lerp(b1, 0.04), 0.0) + off + Vector3(0, 0.2, 0),
			_spt(b0.lerp(b1, 0.96), 0.0) + off + Vector3(0, 0.2, 0), _spt(b0.lerp(b1, 0.96), th) + off,
			_spt(b0.lerp(b1, 0.04), th) + off, nrm)
		if edge > 28.0:
			var out := Vector3(nrm.x, 0.0, nrm.z).normalized()
			var dir := Vector3(b1.x - b0.x, 0.0, b1.y - b0.y).normalized()
			var c := _spt(b0.lerp(b1, 0.5), 8.5 / SHARD_H) + out * 2.4
			lm.box("Fins", c, Vector3(edge * 0.6, 0.45, 5.0), Basis(dir, Vector3.UP, dir.cross(Vector3.UP)))
			for side in [-1.0, 1.0]:
				var s: float = side
				var cp := c + dir * s * edge * 0.28 + out * 2.0
				lm.box("Fins", Vector3(cp.x, 4.1, cp.z), Vector3(0.4, 8.2, 0.4), Basis(), 0.0)
	var plaza := PackedVector2Array()
	for p in base:
		plaza.append(p * 1.22)
	lm.poly_prism("Concrete", plaza, 0.0, 0.25)

## The open-air deck on level 72 and the steel spire above it: a faceted
## mast with three rings of struts fanning out to the splintered shards.
static func _shard_deck_and_spire(lm: LandmarkMesh, base: Array[Vector2]) -> void:
	var tc := DECK_Y / SHARD_H
	var deck := PackedVector2Array()
	for p in base:
		deck.append(p * (1.0 - tc) * 0.97)
	lm.poly_prism("Concrete", deck, DECK_Y - 0.6, DECK_Y)
	var prof := PackedVector2Array([Vector2(1.7, 0.0), Vector2(1.3, 14.0), Vector2(0.85, 34.0),
		Vector2(0.45, 50.0), Vector2(0.25, 60.0), Vector2(0.1, 66.0)])
	lm.lathe("Fins", Vector3(0, SHARD_H - 66.0, 0), prof, 8, 1.0, 1.0, 0.0, false)
	for i in 6:
		var a := TAU * float(i) / 6.0
		var d := Vector3(cos(a), 0, sin(a))
		lm.beam("Fins", d * 4.4 + Vector3(0, DECK_Y, 0), d * 0.55 + Vector3(0, 283.0, 0), 0.3, 0.3)
		for y in [256.0, 269.0]:
			var yy: float = y
			var a2 := a + TAU / 6.0
			var r := lerpf(4.4, 0.55, (yy - DECK_Y) / (283.0 - DECK_Y))
			lm.beam("Fins", d * r + Vector3(0, yy, 0), Vector3(cos(a2), 0, sin(a2)) * r + Vector3(0, yy, 0), 0.22, 0.22)

# --- 30 St Mary Axe ----------------------------------------------------

static func _gr(y: float) -> float:
	return LandmarkMesh.profile_at(_gherkin_table(), y)

## Diagrid node k on level m: nodes sit on the corners of the 36-sided
## skin, a half pitch (10 degrees) round on every odd level.
static func _gnode(m: int, k: int, off: float) -> Vector3:
	var y := maxf(NODE_H * float(m), 0.35)
	var th := deg_to_rad(float(2 * k + (m % 2)) * 10.0)
	var r := _gr(y) + off
	return Vector3(cos(th) * r, y, sin(th) * r)

static func gherkin(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Glass", LandmarkMaterials.glass("#6D8A96"))
	lm.use("Lens", LandmarkMaterials.glass("#8DAAB8"))
	lm.use("Well", LandmarkMaterials.glass("#1F2E34"))
	lm.use("Frame", LandmarkMaterials.paint("#AEB6BC", 0.35, 0.8))
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#A9A59C", 4.0))
	# Flat-panelled 36-sided skin, a ring every storey.
	var prof := PackedVector2Array()
	for j in 41:
		var y := FLOOR_H * float(j)
		prof.append(Vector2(_gr(y), y))
	lm.lathe("Glass", Vector3.ZERO, prof, 36, 1.0, 1.0, 0.0, false, false)
	_g_diagrid(lm)
	_g_wells(lm)
	_g_lens(lm)
	lm.frustum("Concrete", Vector3.ZERO, 38.0, 38.0, 0.3, 48)
	lm.frustum("Concrete", Vector3(0, 0.3, 0), 31.0, 31.0, 0.2, 48)
	lm.commit(model)

## Diagonals both hands between nodes two storeys apart, and a hoop at
## every node level.
static func _g_diagrid(lm: LandmarkMesh) -> void:
	for m in 20:
		var wd := lerpf(0.9, 0.45, float(m) / 20.0)
		for k in 18:
			var a := _gnode(m, k, 0.28)
			var th := deg_to_rad(float(2 * k + (m % 2)) * 10.0)
			for sgn in [-1.0, 1.0]:
				var s: float = sgn
				var th2 := th + s * deg_to_rad(10.0)
				var y2 := NODE_H * float(m + 1)
				var r2 := _gr(y2) + 0.28
				var b := Vector3(cos(th2) * r2, y2, sin(th2) * r2)
				lm.beam("Frame", a, b, wd, wd + 0.1)
	for m in 21:
		var y := maxf(NODE_H * float(m), 0.35)
		var r := _gr(y) + 0.3
		var hw := lerpf(0.7, 0.45, float(m) / 20.0)
		for i in 36:
			var t0 := deg_to_rad(10.0 * float(i))
			var t1 := deg_to_rad(10.0 * float(i + 1))
			lm.beam("Frame", Vector3(cos(t0) * r, y, sin(t0) * r), Vector3(cos(t1) * r, y, sin(t1) * r),
				hw, 0.5, Vector3.UP)

## Six dark light-well bands, each rotating 5 degrees a storey, in stacks
## of five storeys with a plain firebreak storey between.
static func _g_wells(lm: LandmarkMesh) -> void:
	var width := deg_to_rad(16.0)
	var cos5 := cos(deg_to_rad(5.0))
	for i in 6:
		var a0 := TAU * float(i) / 6.0
		for s in 7:
			var f0 := s * 6
			var f1 := mini(f0 + 5, 40)
			var rows: Array = []
			for f in range(f0, f1 + 1):
				var y := FLOOR_H * float(f)
				var row := PackedVector3Array()
				for c in 5:
					var th := a0 + deg_to_rad(5.0) * float(f) + (float(c) / 4.0 - 0.5) * width
					var local := fposmod(th, deg_to_rad(10.0)) - deg_to_rad(5.0)
					var r := _gr(y) * cos5 / cos(local) + 0.1
					row.append(Vector3(cos(th) * r, y, sin(th) * r))
				rows.append(row)
			if rows.size() >= 2:
				lm.grid("Well", rows, Vector3(0, FLOOR_H * float(f0 + f1) * 0.5, 0), true)

## The glass lens over the top-floor bar, ribbed in line with the diagrid.
static func _g_lens(lm: LandmarkMesh) -> void:
	var rb := _gr(LENS_BASE)
	var lens := PackedVector2Array()
	var pts: Array[Vector2] = []
	for i in 10:
		var s := 0.97 * float(i) / 9.0
		var p := Vector2(rb * sqrt(1.0 - s * s), LENS_BASE + 14.0 * s)
		lens.append(p)
		pts.append(p)
	lm.lathe("Lens", Vector3.ZERO, lens, 36)
	for k in 18:
		var th := deg_to_rad(float(k) * 20.0)
		var d := Vector3(cos(th), 0, sin(th))
		for i in 9:
			lm.beam("Frame", d * (pts[i].x + 0.15) + Vector3(0, pts[i].y, 0),
				d * (pts[i + 1].x + 0.15) + Vector3(0, pts[i + 1].y, 0), 0.3, 0.3)
	for ring in [3, 6]:
		var p: Vector2 = pts[ring]
		for k in 36:
			var t0 := deg_to_rad(10.0 * float(k))
			var t1 := deg_to_rad(10.0 * float(k + 1))
			lm.beam("Frame", Vector3(cos(t0), 0, sin(t0)) * (p.x + 0.15) + Vector3(0, p.y, 0),
				Vector3(cos(t1), 0, sin(t1)) * (p.x + 0.15) + Vector3(0, p.y, 0), 0.3, 0.3, Vector3.UP)
	LandmarkWestKit.tube(lm, "Frame", Vector3(0, pts[9].y - 0.2, 0), Vector3(0, 180.0, 0), 0.35, 8)
