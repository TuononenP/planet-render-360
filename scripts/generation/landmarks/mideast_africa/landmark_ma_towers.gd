class_name LandmarkMaTowers
extends RefCounted

## Three tall concrete towers in true metres: Tehran's Milad Tower,
## the Cairo Tower and the Kuwait Towers.

# --- Milad Tower ---

## Head profile (radius, height above HEAD_Y): the ribbed bowl flaring to
## the 60 m widest floor at 280 m, the glazed floors and the crown at
## the 315 m roof.
const MILAD_HEAD_Y := 247.0
const MILAD_HEAD := [[8.5, 0.0], [13.0, 5.0], [19.5, 12.0], [25.5, 21.0], [29.5, 29.0], [30.0, 33.0],
	[29.6, 37.0], [27.5, 45.0], [23.5, 54.0], [17.0, 62.0], [11.0, 68.0]]

## 435 m telecommunications tower (2007): the six-storey octagonal lobby
## round the foot, its glazed slopes between concrete fins; the concrete
## shaft with three glass lift runs and the stair rib; the 12-floor steel
## head (widest 60 m at 280 m) on its radial bowl ribs, banded floors and
## the open observation terrace; the 120 m four-stage antenna mast with
## its service platforms.
static func milad(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Shaft", LandmarkMaterials.pbr("concrete", "#CFCBC2", 5.0))
	lm.use("Head", LandmarkMaterials.glass("#4A5C68"))
	lm.use("Mast", LandmarkMaterials.paint("#E8E8E6", 0.4, 0.4))
	lm.use("Rim", LandmarkMaterials.pbr("concrete", "#B9B4A8", 4.0))
	var rot := PI / 8.0
	# Lobby: octagonal base, glazed sloping storeys, corner fins.
	lm.frustum("Rim", Vector3.ZERO, 46.0, 46.0, 1.2, 8, rot)
	lm.frustum("Shaft", Vector3(0, 1.2, 0), 43.0, 42.0, 8.0, 8, rot)
	lm.lathe("Head", Vector3(0, 9.2, 0), PackedVector2Array([Vector2(41.0, 0), Vector2(34.0, 9.0),
		Vector2(26.0, 18.0), Vector2(19.0, 25.0)]), 8, 1.0, 1.0, rot, false)
	for i in 8:
		var a := rot + TAU * float(i) / 8.0
		var d := Vector3(cos(a), 0, sin(a))
		lm.beam("Rim", d * 44.0 + Vector3(0, 1.2, 0), d * 19.5 + Vector3(0, 35.0, 0), 2.4, 3.0, d.cross(Vector3.UP))
		var am := a + PI / 8.0
		var dm := Vector3(cos(am), 0, sin(am))
		LandmarkMaParts.arched_bays(lm, "Shaft", "Head", Vector3(cos(a), 0, sin(a)) * 43.0 + Vector3(0, 1.2, 0),
			Vector3(cos(a + PI / 4.0), 0, sin(a + PI / 4.0)) * 43.0 - Vector3(cos(a), 0, sin(a)) * 43.0, dm,
			2.0 * 43.0 * sin(PI / 8.0), 8.0, 4, 4.4, 4.0, 2.2, 0.5)
		for k in 3:
			var y := 9.2 + 6.2 * float(k + 1)
			var r := lerpf(41.0, 19.0, (y - 9.2) / 25.0)
			lm.beam("Rim", Vector3(cos(a), 0, sin(a)) * r + Vector3(0, y, 0),
				Vector3(cos(a + PI / 4.0), 0, sin(a + PI / 4.0)) * r + Vector3(0, y, 0), 0.6, 0.6)
	lm.frustum("Rim", Vector3(0, 34.2, 0), 20.0, 19.0, 1.0, 8, rot)
	# Shaft with its lift runs and stair rib.
	LandmarkMaParts.needle(lm, "Shaft", Vector3(0, 0, 0), PackedVector2Array([Vector2(0, 15.0),
		Vector2(40, 13.0), Vector2(120, 10.5), Vector2(200, 9.0), Vector2(MILAD_HEAD_Y, 8.5)]), 24)
	for i in 4:
		var a := PI * 0.5 * float(i)
		var d := Vector3(cos(a), 0, sin(a))
		var key := "Rim" if i == 3 else "Head"
		lm.beam(key, d * 13.6 + Vector3(0, 35, 0), d * 8.9 + Vector3(0, MILAD_HEAD_Y, 0), 3.0, 1.4, d.cross(Vector3.UP))
	# Head: the bowl and floors as one profile, ribs and floor rims.
	var hb := Vector3(0, MILAD_HEAD_Y, 0)
	var prof := PackedVector2Array()
	for q in MILAD_HEAD:
		prof.append(Vector2(float(q[0]), float(q[1])))
	lm.lathe("Head", hb, prof, 32)
	for i in 24:
		var a := TAU * float(i) / 24.0
		var d := Vector3(cos(a), 0, sin(a))
		for j in 5:
			var p0 := hb + d * (prof[j].x + 0.3) + Vector3(0, prof[j].y, 0)
			var p1 := hb + d * (prof[j + 1].x + 0.3) + Vector3(0, prof[j + 1].y, 0)
			lm.beam("Mast", p0, p1, 0.8, 0.6, d.cross(Vector3.UP))
	for y in [33.0, 37.0, 41.0, 45.0, 49.5, 54.0, 58.0, 62.0]:
		var r := LandmarkMesh.profile_at(PackedVector2Array([Vector2(33, 30.0), Vector2(37, 29.6),
			Vector2(45, 27.5), Vector2(54, 23.5), Vector2(62, 17.0), Vector2(68, 11.0)]), y)
		lm.frustum("Rim", hb + Vector3(0, y, 0), r + 0.5, r + 0.4, 0.7, 32)
	# Open observation terrace at 280 m: deck ring and railing posts.
	lm.frustum("Rim", hb + Vector3(0, 30.5, 0), 31.5, 31.5, 0.6, 32)
	for i in 48:
		var a := TAU * float(i) / 48.0
		lm.box("Mast", hb + Vector3(cos(a) * 31.2, 31.7, sin(a) * 31.2), Vector3(0.15, 1.2, 0.15), Basis(), 0.0)
	lm.frustum("Mast", hb + Vector3(0, 32.2, 0), 31.25, 31.25, 0.12, 32)
	# Crown and the four-stage antenna to 435 m.
	var top := hb + Vector3(0, 68, 0)
	lm.frustum("Rim", top, 12.0, 10.0, 2.0, 24)
	var stages := [[10.0, 5.2, 4.2], [32.0, 4.0, 3.0], [32.0, 2.8, 1.8], [44.0, 1.5, 0.15]]
	var y0 := top.y + 2.0
	for st in stages:
		var h := float(st[0])
		lm.frustum("Mast", Vector3(0, y0, 0), float(st[1]), float(st[2]), h, 16)
		lm.frustum("Rim", Vector3(0, y0 + h - 1.0, 0), float(st[2]) + 1.6, float(st[2]) + 1.6, 1.0, 16)
		for i in (12 if float(st[2]) > 1.0 else 0):
			var a := TAU * float(i) / 12.0
			lm.box("Mast", Vector3(cos(a) * (float(st[2]) + 1.4), y0 + h - 0.5, sin(a) * (float(st[2]) + 1.4)),
				Vector3(0.12, 1.0, 0.12), Basis(), 0.0)
		y0 += h
	lm.commit(model)

# --- Cairo Tower ---

const CAIRO_STRANDS := 20
const CAIRO_LOTUS_Y := 118.0
const CAIRO_HEAD_Y := 141.0

## Lattice radius at height y: a slim slightly tapering stem, then the
## lotus flaring under the head.
static func _cairo_r(y: float) -> float:
	if y <= CAIRO_LOTUS_Y:
		return lerpf(7.6, 7.0, y / CAIRO_LOTUS_Y)
	var t := (y - CAIRO_LOTUS_Y) / (CAIRO_HEAD_Y - CAIRO_LOTUS_Y)
	return 7.0 + 4.6 * t * t

## 187 m concrete tower on Gezira island (1961): a lattice of strands
## crossing in long diamonds round its core like a stylised lotus stem,
## the lotus crown of petal ribs opening under the head, the three-storey
## glazed restaurant head, the open observation deck at the top (roof
## 160 m) and the mast; the stone entrance pavilion at its foot.
static func cairo_tower(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Lattice", LandmarkMaterials.pbr("concrete", "#C4BCAC", 3.0))
	lm.use("Glass", LandmarkMaterials.glass("#3E4C54"))
	lm.use("Mast", LandmarkMaterials.paint("#9AA3AA", 0.4, 0.6))
	lm.use("Base", LandmarkMaterials.pbr("pavement", "#CFC6B2", 5.0))
	lm.box("Base", Vector3(0, 0.3, 0), Vector3(70, 0.6, 70))
	# Entrance pavilion: granite block with a battered portal.
	lm.box("Base", Vector3(0, 4.6, 0), Vector3(28, 8, 28))
	lm.box("Base", Vector3(0, 8.9, 0), Vector3(30, 0.6, 30))
	for d in [Vector3.RIGHT, Vector3.LEFT, Vector3.BACK, Vector3.FORWARD]:
		var r: Vector3 = Vector3.UP.cross(d)
		LandmarkMaParts.arched_bays(lm, "Base", "Glass", d * 14.0 - r * 14.0 + Vector3(0, 0.6, 0), r, d, 28.0, 8.0,
			3, 3.6, 3.6, 1.8, 0.6, "Lattice", 4)
	# Inner core and the lattice skin.
	LandmarkMaParts.needle(lm, "Glass", Vector3(0, 9.0, 0), PackedVector2Array([Vector2(0, 6.4),
		Vector2(CAIRO_LOTUS_Y - 9.0, 5.8), Vector2(CAIRO_HEAD_Y - 9.0, 6.6)]), 16)
	var segs := 44
	var twist := 2.0
	for k in segs:
		var y0 := 9.0 + (CAIRO_HEAD_Y - 9.0) * float(k) / segs
		var y1 := 9.0 + (CAIRO_HEAD_Y - 9.0) * float(k + 1) / segs
		var r0 := _cairo_r(y0)
		var r1 := _cairo_r(y1)
		for dir in [-1.0, 1.0]:
			for i in CAIRO_STRANDS:
				var a0: float = TAU * i / CAIRO_STRANDS + dir * twist * y0 / CAIRO_HEAD_Y
				var a1: float = TAU * i / CAIRO_STRANDS + dir * twist * y1 / CAIRO_HEAD_Y
				lm.beam("Lattice", Vector3(cos(a0) * r0, y0, sin(a0) * r0),
					Vector3(cos(a1) * r1, y1, sin(a1) * r1), 0.75, 0.5)
		if k % 6 == 0:
			lm.frustum("Lattice", Vector3(0, y0, 0), r0 + 0.2, r0 + 0.2, 0.5, 24)
	# Lotus petals opening round the top of the stem.
	for i in 16:
		var a := TAU * (float(i) + 0.5) / 16.0
		var d := Vector3(cos(a), 0, sin(a))
		var prev := d * 7.2 + Vector3(0, CAIRO_LOTUS_Y - 6.0, 0)
		for j in 5:
			var t := float(j + 1) / 5.0
			var y := lerpf(CAIRO_LOTUS_Y - 6.0, CAIRO_HEAD_Y, t)
			var p := d * (_cairo_r(y) + 0.6 + 1.6 * sin(PI * t)) + Vector3(0, y, 0)
			lm.beam("Lattice", prev, p, 1.6 * (1.0 - 0.5 * t) + 0.4, 0.4, d.cross(Vector3.UP))
			prev = p
	# Head: floor slab, glazed restaurant storeys, deck, roof.
	var hb := Vector3(0, CAIRO_HEAD_Y, 0)
	lm.frustum("Lattice", hb, 12.6, 13.4, 1.2, 32)
	lm.frustum("Glass", hb + Vector3(0, 1.2, 0), 13.0, 13.0, 9.6, 32)
	for i in 32:
		var a := TAU * float(i) / 32.0
		lm.box("Lattice", hb + Vector3(cos(a) * 13.1, 6.0, sin(a) * 13.1), Vector3(0.4, 9.6, 0.4), Basis(), 0.0)
	for y in [4.4, 7.6]:
		lm.frustum("Lattice", hb + Vector3(0, y, 0), 13.4, 13.4, 0.4, 32)
	lm.frustum("Lattice", hb + Vector3(0, 10.8, 0), 14.2, 14.2, 1.0, 32)
	# Open observation deck with its lattice parapet.
	var db := hb + Vector3(0, 11.8, 0)
	for i in 64:
		var a := TAU * float(i) / 64.0
		var b := TAU * float(i + 1) / 64.0
		lm.beam("Lattice", Vector3(cos(a) * 13.9, db.y, sin(a) * 13.9), Vector3(cos(b) * 13.9, db.y + 1.3,
			sin(b) * 13.9), 0.18, 0.18)
	lm.frustum("Lattice", db + Vector3(0, 1.3, 0), 14.0, 14.0, 0.25, 32)
	lm.frustum("Lattice", db, 7.5, 7.0, 5.0, 24)
	LandmarkMaParts.dome(lm, "Lattice", db + Vector3(0, 5.0, 0), 7.4, 2.2, 24)
	# Mast to 187 m.
	var mb := db + Vector3(0, 7.2, 0)
	lm.frustum("Mast", mb, 1.6, 1.2, 4.0, 12)
	LandmarkMaParts.needle(lm, "Mast", mb + Vector3(0, 4.0, 0), PackedVector2Array([Vector2(0, 1.0),
		Vector2(187.0 - mb.y - 4.0, 0.12)]), 8)
	for y in [8.0, 15.0]:
		lm.frustum("Mast", mb + Vector3(0, y, 0), 1.5, 1.5, 0.4, 12)
	lm.commit(model)

# --- Kuwait Towers ---

## Three slender towers on the Gulf shore (1979): the 187 m main tower
## with the restaurant-and-water sphere and the revolving observation
## sphere at 123 m, the 147 m second tower with its water sphere and the
## 113 m lighting needle. The spheres are clad in thousands of enamelled
## steel discs in spiral patterns of blue, green and grey; the deck bands
## are glazed.
static func kuwait_towers(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Shaft", LandmarkMaterials.pbr("concrete", "#D6D3CC", 4.0))
	lm.use("Sphere", LandmarkMaterials.pbr("render", "#3F8E9C", 2.0, 0.3, 0.2))
	lm.use("Needle", LandmarkMaterials.paint("#C9CED2", 0.35, 0.7))
	lm.use("Plinth", LandmarkMaterials.pbr("pavement", "#CFC6B2", 5.0))
	lm.use("DiscGreen", LandmarkMaterials.pbr("render", "#3E8C6A", 1.0, 0.25, 0.5))
	lm.use("DiscGrey", LandmarkMaterials.pbr("render", "#6F8798", 1.0, 0.25, 0.5))
	lm.use("Glass", LandmarkMaterials.glass("#2C3C46"))
	lm.box("Plinth", Vector3(5, 0.5, 0), Vector3(150, 1.0, 80))
	_kuwait_tower(lm, Vector3(22, 1, 0), 187.0, 80.0, 16.0, 123.0, 9.0)
	_kuwait_tower(lm, Vector3(-32, 1, 4), 147.0, 64.0, 12.5, 0.0, 0.0)
	_kuwait_tower(lm, Vector3(52, 1, 22), 113.0, 0.0, 0.0, 0.0, 0.0)
	# Entrance pavilion at the main tower's foot.
	lm.frustum("Plinth", Vector3(22, 1, 0), 16.0, 15.0, 5.0, 24)
	lm.frustum("Glass", Vector3(22, 1.4, 0), 15.2, 15.2, 3.4, 24)
	lm.frustum("Shaft", Vector3(22, 6, 0), 17.0, 16.0, 0.8, 24)
	lm.commit(model)

## One tower of height h (top) from `base`: a flared concrete shaft to a
## needle, up to two spheres (radius r1 at y1, r2 at y2) with their disc
## cladding and glazed deck bands.
static func _kuwait_tower(lm: LandmarkMesh, base: Vector3, h: float, y1: float, r1: float,
		y2: float, r2: float) -> void:
	var s := h / 187.0
	var top := h - base.y
	var shaft_h := 0.84 * top
	LandmarkMaParts.needle(lm, "Shaft", base, PackedVector2Array([Vector2(0, 7.5 * s), Vector2(6, 5.0 * s),
		Vector2(20 * s, 3.6 * s), Vector2(70 * s, 2.7 * s), Vector2(125 * s, 1.6 * s), Vector2(shaft_h, 0.8)]), 20)
	LandmarkMaParts.needle(lm, "Needle", base + Vector3(0, shaft_h, 0), PackedVector2Array([
		Vector2(0, 0.8), Vector2(top - shaft_h, 0.1)]), 8)
	for k in 3:
		lm.frustum("Needle", base + Vector3(0, shaft_h + 4.0 + 5.0 * float(k), 0), 0.9, 0.9, 0.4, 8)
	if r1 > 0.0:
		_kuwait_sphere(lm, base + Vector3(0, y1 - base.y, 0), r1, true)
	if r2 > 0.0:
		_kuwait_sphere(lm, base + Vector3(0, y2 - base.y, 0), r2, false)
	if r1 <= 0.0:
		# The lighting needle: lamp rings up its shaft.
		for k in 5:
			var y := top * (0.3 + 0.12 * float(k))
			lm.frustum("Needle", base + Vector3(0, y, 0), 2.4 - 0.3 * float(k), 2.4 - 0.3 * float(k), 0.6, 12)

## Sphere of radius r on centre c: the shell, a glazed band (the
## restaurant just above the equator when `upper_band`, else the
## revolving deck on it) and spirals of enamelled discs.
static func _kuwait_sphere(lm: LandmarkMesh, c: Vector3, r: float, upper_band: bool) -> void:
	LandmarkMaParts.sphere(lm, "Sphere", c, r, 32, 16)
	var by := r * (0.25 if upper_band else -0.15)
	var br := sqrt(r * r - by * by)
	lm.frustum("Glass", c + Vector3(0, by - r * 0.08, 0), br + 0.15, br + 0.15, r * 0.16, 32)
	lm.frustum("Shaft", c + Vector3(0, by + r * 0.08, 0), br + 0.6, br + 0.4, 0.5, 32)
	var rings := int(r * 0.9)
	for j in rings:
		var lat := -PI * 0.5 + PI * (float(j) + 0.5) / float(rings)
		var y := sin(lat) * r
		if absf(y - by) < r * 0.14:
			continue
		var rr := cos(lat) * r
		var n := maxi(int(TAU * rr / 2.4), 4)
		for i in n:
			var a := TAU * (float(i) + 0.37 * float(j)) / float(n)
			var dir := Vector3(cos(a) * cos(lat), sin(lat), sin(a) * cos(lat))
			var spiral := (i + j * 2) % 6
			var key := "DiscGreen" if spiral < 2 else ("DiscGrey" if spiral < 4 else "Sphere")
			lm.disc(key, c + dir * (r + 0.06), dir, 0.95, 6)
