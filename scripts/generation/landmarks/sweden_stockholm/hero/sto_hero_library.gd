class_name StoHeroLibrary
extends RefCounted

## Stockholm Public Library (Stadsbiblioteket, Gunnar Asplund, 1924-1928)
## on Sveavägen. True metres, origin at ground level (Sveavägen) at the
## footprint centre, front toward +Z (the registry yaw_deg turns it onto
## its real compass facing). 31 m to the rotunda's coping.
##
## From the photos (visual-plan/refs/landmarks/stockholm_public_library/):
## - Burnt-orange rendered cube, 48.4 x 50 m, 20 m high, in three window
##   storeys of plain square windows deep in their reveals: a row of small
##   squares under the grey stone coping (11 bays), a row of tall
##   windows (1.35 x 2.6 m) below it, and low squares near the ground. The
##   front is one bay in eleven (4.4 m) with the portal in the middle bay;
##   the front's tall row stops each side of it.
## - The 30 m cylinder of the rotunda stands on the roof (11 m above it):
##   plain orange drum on a stepped ring, twenty tall narrow windows in
##   one band at three-quarters height, a projecting grey stone coping,
##   flat roof.
## - The Egyptian-style portal: a tall tapering opening (5.4 m wide, 9 m
##   high, entrance floor 5 m above the street) framed in grey granite, a
##   dark glazed door set back in it, reached by one broad flight of 29
##   shallow steps up between the two shop wings.
## - The shop wings along Sveavägen: two-storey ochre blocks (7 m) with
##   shop windows under red awnings and a railed roof terrace, joined to the
##   cube's front on both sides of the flight.
## Sources: biblioteket.stockholm.se (rotunda 26 m inside, 24 m to the
## ceiling); OSM way 31990167 (block 48.5 x 49.9 m), building part
## 101343771 (rotunda 30 m outside) and the shop wings 39087434/39087435.

const TOP := 31.0
const BLOCK_H := 20.0
const HX := 24.2
const HZ := 25.0
const SKIN := 0.4
const BAYS := 11
const ROT_C := Vector3(-0.2, 0.0, 2.0)
const ROT_R := 15.0
const WING_H := 7.0

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Render", LandmarkMaterials.pbr("render", "#DC8F4A", 3.0))
	lm.use("Coping", LandmarkMaterials.pbr("stone", "#8E8A80", 2.5))
	lm.use("Plinth", LandmarkMaterials.pbr("stone", "#908D83", 2.5))
	lm.use("Windows", LandmarkMaterials.glass("#2A3236"))
	lm.use("Door", LandmarkMaterials.pbr("concrete", "#2A2622", 2.0, 0.5, 0.2))
	lm.use("Wing", LandmarkMaterials.pbr("render", "#C8AC5E", 3.0))
	lm.use("Awning", LandmarkMaterials.paint("#A82F3A", 0.8, 0.0))
	lm.use("Roof", LandmarkMaterials.pbr("concrete", "#7C7A74", 2.0, 0.85))
	lm.use("Dark", LandmarkMaterials.paint("#2A2A2A", 0.6, 0.4))
	_block(lm)
	_portal(lm)
	_rotunda(lm)
	_wings(lm)
	lm.commit(model)

## The cube: a solid core, the window skins row by row, the stone coping.
static func _block(lm: LandmarkMesh) -> void:
	var cx := HX - SKIN
	var cz := HZ - SKIN
	lm.box("Render", Vector3(0, (BLOCK_H - 0.5) * 0.5, 0), Vector3(2.0 * cx, BLOCK_H - 0.5, 2.0 * cz), Basis(), 0.0)
	lm.box("Plinth", Vector3(0, 0.5, 0), Vector3(2.0 * HX + 0.4, 1.0, 2.0 * HZ + 0.4))
	lm.box("Coping", Vector3(0, BLOCK_H - 0.25, 0), Vector3(2.0 * HX + 0.8, 0.5, 2.0 * HZ + 0.8), Basis(), 0.0)
	# [window bottom, skin height, window w, window h] per row.
	var rows := [[16.7, 2.2, 1.3, 1.2], [12.3, 3.6, 1.35, 2.6], [6.5, 2.2, 1.3, 1.2], [2.6, 2.2, 1.2, 1.2]]
	var pitch := 2.0 * HX / float(BAYS)
	for ri in rows.size():
		var row: Array = rows[ri]
		var sill := 0.5
		var y0: float = float(row[0]) - sill
		var win := Vector2(float(row[2]), float(row[3]))
		# Back and both sides: every bay of every row.
		_skin(lm, Vector3(HX, y0, -HZ), Vector3.LEFT, Vector3.FORWARD, 2.0 * HX, float(row[1]), BAYS, win, sill)
		var bays_z := int(round(2.0 * HZ / pitch))
		_skin(lm, Vector3(HX, y0, HZ), Vector3.FORWARD, Vector3.RIGHT, 2.0 * HZ, float(row[1]), bays_z, win, sill)
		_skin(lm, Vector3(-HX, y0, -HZ), Vector3.BACK, Vector3.LEFT, 2.0 * HZ, float(row[1]), bays_z, win, sill)
		# Front: five bays either side of the portal bay; the low rows
		# only in the bays beside it.
		if ri == 0 or ri == 1:
			_skin(lm, Vector3(-HX, y0, HZ), Vector3.RIGHT, Vector3.BACK, 5.0 * pitch, float(row[1]), 5, win, sill)
			_skin(lm, Vector3(pitch * 0.5, y0, HZ), Vector3.RIGHT, Vector3.BACK, 5.0 * pitch, float(row[1]), 5, win, sill)
		elif ri == 2:
			_skin(lm, Vector3(-pitch * 1.5, y0, HZ), Vector3.RIGHT, Vector3.BACK, pitch, float(row[1]), 1, win, sill)
			_skin(lm, Vector3(pitch * 0.5, y0, HZ), Vector3.RIGHT, Vector3.BACK, pitch, float(row[1]), 1, win, sill)

## One window skin: from `a` (bottom left seen from outside) along `r`.
static func _skin(lm: LandmarkMesh, a: Vector3, r: Vector3, o: Vector3, length: float, h: float, bays: int,
		win: Vector2, sill: float) -> void:
	var origin := a - o * SKIN
	LandmarkDetail.pierced_face(lm, "Render", "Windows", origin, r, o, length, h, bays, 1, win, sill, h, SKIN)

## The tapering granite portal and the flight up to it.
static func _portal(lm: LandmarkMesh) -> void:
	var y0 := 5.0
	var h := 9.2
	var w0 := 5.6
	var w1 := 4.8
	var z := HZ + 0.05
	var n := Vector3.BACK
	# Dark recess with the glazed door, tapering with the jambs.
	lm.quad("Door", Vector3(-w0 * 0.5 + 0.9, y0, z), Vector3(w0 * 0.5 - 0.9, y0, z),
		Vector3(w1 * 0.5 - 0.9, y0 + h, z), Vector3(-w1 * 0.5 + 0.9, y0 + h, z), n)
	lm.quad("Windows", Vector3(-w0 * 0.5 + 1.0, y0 + 3.0, z + 0.03), Vector3(w0 * 0.5 - 1.0, y0 + 3.0, z + 0.03),
		Vector3(w1 * 0.5 - 1.0, y0 + h - 0.2, z + 0.03), Vector3(-w1 * 0.5 + 1.0, y0 + h - 0.2, z + 0.03), n)
	for s in [-1.0, 1.0]:
		lm.beam("Plinth", Vector3(s * (w0 * 0.5 - 0.45), y0, z + 0.3), Vector3(s * (w1 * 0.5 - 0.45), y0 + h, z + 0.3),
			0.9, 0.7, Vector3(1, 0, 0))
	lm.box("Plinth", Vector3(0, y0 + h + 0.45, z + 0.3), Vector3(w1 + 0.4, 0.9, 0.7))
	lm.box("Coping", Vector3(0, y0 + h + 1.1, z + 0.35), Vector3(w1 + 1.0, 0.4, 0.9))
	# The landing and the long flight down to Sveavägen.
	lm.box("Plinth", Vector3(0, y0 * 0.5, HZ + 1.5), Vector3(10.0, y0, 3.0))
	LandmarkFhUtil.steps(lm, "Plinth", Vector3(0, 0, HZ + 3.0), Vector3.BACK, 10.0, 0.9, y0 / 29.0, 29)

## The drum: stepped ring, plain orange wall, twenty tall windows, the
## projecting stone coping and the flat roof.
static func _rotunda(lm: LandmarkMesh) -> void:
	var c := ROT_C
	var r := ROT_R
	lm.frustum("Render", c + Vector3(0, BLOCK_H - 0.5, 0), r + 0.7, r, 1.3, 48)
	lm.frustum("Render", c + Vector3(0, BLOCK_H + 0.8, 0), r, r, TOP - BLOCK_H - 1.5, 48)
	lm.frustum("Coping", c + Vector3(0, TOP - 0.7, 0), r + 0.7, r + 0.7, 0.7, 48)
	lm.frustum("Coping", c + Vector3(0, TOP - 1.2, 0), r + 0.25, r + 0.7, 0.5, 48)
	var n := 20
	for k in n:
		var a := TAU * (float(k) + 0.5) / float(n)
		var d := Vector3(cos(a), 0, sin(a))
		LandmarkDetail.window(lm, "Render", "Windows", c + d * (r + 0.02) + Vector3(0, 23.3, 0), d, 1.0, 3.9, false, 0.3)

## The two shop wings: ochre blocks with shop windows under red awnings,
## a roof terrace with its rail, one joined to the cube on each side of
## the flight.
static func _wings(lm: LandmarkMesh) -> void:
	var wings := [PackedVector2Array([Vector2(5.0, HZ), Vector2(34.0, HZ), Vector2(35.5, 54.0), Vector2(5.3, 54.7)]),
		PackedVector2Array([Vector2(-42.4, HZ), Vector2(-5.0, HZ), Vector2(-5.6, 54.8), Vector2(-42.2, 56.2)])]
	for poly in wings:
		var pg: PackedVector2Array = poly
		lm.poly_prism("Wing", pg, 0.0, WING_H)
		var cen := LandmarkFhParts.centre(pg)
		var inner := PackedVector2Array()
		for p in pg:
			inner.append(cen + (p - cen) * 0.98)
		lm.poly_prism("Roof", inner, WING_H, WING_H + 0.12)
		for i in pg.size():
			var j := (i + 1) % pg.size()
			var a := Vector3(pg[i].x, 0, pg[i].y)
			var b := Vector3(pg[j].x, 0, pg[j].y)
			var o := LandmarkFhParts.edge_out(pg, i)
			var len := a.distance_to(b)
			var basis := Basis(Vector3.UP.cross(o).normalized(), Vector3.UP, o)
			var m := (a + b) * 0.5
			lm.box("Coping", m + Vector3(0, WING_H - 0.2, 0) + o * 0.1, Vector3(len + 0.2, 0.4, 0.4), basis)
			if o.z < -0.5:
				continue
			# Shop fronts, with the awning over them on the street side.
			var nb := int(len / 4.0)
			for k in nb:
				var p := a.lerp(b, (float(k) + 0.5) / float(nb)) + o * 0.04
				lm.box("Windows", p + Vector3(0, 2.2, 0), Vector3(3.2, 2.6, 0.06), basis, 0.0)
				lm.box("Plinth", p + Vector3(0, 0.55, 0) + o * 0.06, Vector3(3.5, 0.5, 0.2), basis, 0.0)
				lm.box("Wing", p + Vector3(0, 5.2, 0) + o * 0.05, Vector3(2.4, 1.4, 0.06), basis, 0.0)
			if o.z > 0.5:
				lm.box("Awning", m + Vector3(0, 4.5, 0) + o * 0.7, Vector3(len - 0.4, 0.12, 1.5), basis, 0.0)
				var rail_a := a + Vector3(0, WING_H + 0.9, 0)
				var rail_b := b + Vector3(0, WING_H + 0.9, 0)
				lm.beam("Dark", rail_a, rail_b, 0.1, 0.1)
				var posts := int(len / 2.5)
				for k in posts + 1:
					var p2 := rail_a.lerp(rail_b, float(k) / float(posts))
					lm.box("Dark", p2 - Vector3(0, 0.45, 0), Vector3(0.08, 0.9, 0.08), Basis(), 0.0)
