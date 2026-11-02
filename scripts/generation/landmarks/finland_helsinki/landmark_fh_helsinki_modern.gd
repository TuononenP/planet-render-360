class_name LandmarkFhHelsinkiModern
extends RefCounted

## Four modern buildings in true metres: Kiasma (Steven Holl, curved
## aluminium-and-glass volumes), the Oodi library (ALA, timber belly under
## a steel arch), Dipoli (Reima and Raili Pietilä, copper lobes on boulders)
## and the Heureka science centre. Footprints are the OpenStreetMap
## outlines in the model frame the registry yaw turns onto the map.

const FhU = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")
const FhP = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_parts.gd")

# --- Kiasma ---------------------------------------------------------------

## Holl's museum of contemporary art (1998), origin at the OSM footprint
## centre, front +Z (the registry yaw turns it onto Mannerheimintie): the
## straight glazed bar and the curved bar wrapped in sanded aluminium
## panels meeting at an angle (the "chiasma"), four storeys of windows in
## framed bands, and the curved roof of the long northern bar, highest at
## its back (26 m) and bowing down to its front and its northern prow.
static func kiasma(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Alu", LandmarkMaterials.pbr("concrete", "#B9BEC1", 3.0, 0.35, 0.6))
	lm.use("Glass", LandmarkMaterials.glass("#2F4F4A"))
	lm.use("Roof", LandmarkMaterials.pbr("concrete", "#8E9396", 3.0, 0.45, 0.5))
	lm.use("Plinth", LandmarkMaterials.pbr("stone", "#8A8780", 4.0))
	var foot := PackedVector2Array([Vector2(55.1, 18.5), Vector2(52.0, 29.3), Vector2(-21.6, 7.5),
		Vector2(-49.5, 19.8), Vector2(-63.3, -5.3), Vector2(-26.4, -11.8), Vector2(4.1, -12.8),
		Vector2(56.4, 2.2), Vector2(52.8, 15.9), Vector2(55.6, 16.7)])
	lm.poly_prism("Plinth", foot, 0.0, 0.8)
	lm.poly_prism("Alu", foot, 0.8, 19.0)
	# Window bands in aluminium frames, panel seams between them.
	for i in foot.size():
		var a := foot[i]
		var b := foot[(i + 1) % foot.size()]
		var l := a.distance_to(b)
		if l > 9.0:
			var o := FhP.edge_out(foot, i)
			var a3 := Vector3(a.x, 0, a.y)
			var b3 := Vector3(b.x, 0, b.y)
			FhP.pierce(lm, "Alu", "Glass", a3.lerp(b3, 0.04), a3.lerp(b3, 0.96), o, 0.8, 18.2, int(l * 0.92 / 4.2),
				4, Vector2(3.3, 2.6), 1.2, 4.4, 0.3)
			for y in [4.6, 9.0, 13.4, 17.8]:
				FhP.band(lm, "Roof", a3, b3, o, y, 0.18, 0.4)
			FhP.ribs(lm, "Roof", a3, b3, o, 0.8, 19.0, 4.2, 0.12, 0.35)
	# The curved roof of the northern bar: a shell bowing across its depth
	# and drooping toward the prow, closed down to the wall tops.
	var nx := 21
	var nz := 7
	var rows: Array = []
	for j in nz:
		var t := float(j) / float(nz - 1)
		var z := lerpf(-12.0, 3.0, t)
		var row := PackedVector3Array()
		for i in nx:
			var x := lerpf(-50.0, 50.0, float(i) / float(nx - 1))
			var y := 19.0 + 2.0 + 5.0 * (1.0 - t * t) - 4.0 * pow(maxf((x - 25.0) / 25.0, 0.0), 2.0)
			row.append(Vector3(x, y, z))
		rows.append(row)
	lm.grid("Roof", rows, Vector3.UP)
	for j in [0, nz - 1]:
		var row: PackedVector3Array = rows[j]
		var o := Vector3(0, 0, -1.0 if j == 0 else 1.0)
		for i in nx - 1:
			lm.quad("Alu", Vector3(row[i].x, 19.0, row[i].z), Vector3(row[i + 1].x, 19.0, row[i + 1].z),
				row[i + 1], row[i], o)
	for i in [0, nx - 1]:
		for j in nz - 1:
			var p0: Vector3 = (rows[j] as PackedVector3Array)[i]
			var p1: Vector3 = (rows[j + 1] as PackedVector3Array)[i]
			lm.quad("Alu", Vector3(p0.x, 19.0, p0.z), Vector3(p1.x, 19.0, p1.z), p1, p0, Vector3(signf(p0.x), 0, 0))
	# Roof seams across the curve.
	for i in range(1, nx - 1, 2):
		var prev: Vector3 = (rows[0] as PackedVector3Array)[i]
		for j in range(1, nz):
			var p: Vector3 = (rows[j] as PackedVector3Array)[i]
			lm.beam("Alu", prev + Vector3(0, 0.08, 0), p + Vector3(0, 0.08, 0), 0.18, 0.12, Vector3.RIGHT)
			prev = p
	# The southern bar's raised roof and the plinth on the Mannerheimintie side.
	lm.poly_prism("Roof", PackedVector2Array([Vector2(51.0, 27.6), Vector2(-19.5, 9.8), Vector2(-19.5, 3.5),
		Vector2(51.0, 3.5)]), 19.0, 22.5)
	FhU.blk(lm, "Plinth", 52.0, 0.0, 10.0, 6.0, 1.2, 36.0)
	lm.commit(model)

# --- Oodi ---------------------------------------------------------------

## Helsinki Central Library Oodi (ALA, 2018), origin at the OSM footprint
## centre, x along the 149 m long axis (north to south), front +Z on the
## Kansalaistori side: the glazed ground floor, the spruce-clad middle
## "bridge" whose belly sweeps up into the great canopy over the square,
## and the "book heaven" top floor in glass under its white, gently
## undulating roof, cantilevered over the balcony at the south end.
static func oodi(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Glass", LandmarkMaterials.glass("#2E3F44"))
	lm.use("Wood", LandmarkMaterials.pbr("wood", "#C5A06A", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("concrete", "#8A8D8E", 3.0, 0.5, 0.4))
	lm.use("Steel", LandmarkMaterials.paint("#E4E6E6", 0.45, 0.4))
	lm.use("Floor", LandmarkMaterials.pbr("concrete", "#9C9A94", 3.0))
	var foot := PackedVector2Array([Vector2(90.5, -8.2), Vector2(104.0, 12.5), Vector2(55.3, 24.8),
		Vector2(49.8, 26.1), Vector2(44.8, 26.3), Vector2(43.3, 26.2), Vector2(-45.4, 12.2),
		Vector2(-45.3, -19.6), Vector2(83.5, -19.1)])
	# Ground floor: glass behind the overhang, on a mullion grid.
	var low := PackedVector2Array([Vector2(88.0, -7.0), Vector2(98.0, 9.0), Vector2(74.8, 8.4),
		Vector2(45.1, 5.6), Vector2(38.0, 5.6), Vector2(32.1, 10.7), Vector2(26.2, 10.6),
		Vector2(20.5, 5.6), Vector2(-12.4, 11.0), Vector2(-45.4, 12.2), Vector2(-45.3, -19.6),
		Vector2(83.5, -19.1)])
	lm.poly_prism("Glass", low, 0.0, 5.6)
	for i in low.size():
		var a := low[i]
		var b := low[(i + 1) % low.size()]
		FhP.ribs(lm, "Steel", Vector3(a.x, 0, a.y), Vector3(b.x, 0, b.y), FhP.edge_out(low, i), 0.0, 5.6, 2.4, 0.12,
			0.15)
	# Middle floor: the timber volume, its slab, vertical spruce boards.
	lm.poly_prism("Floor", foot, 5.6, 6.2)
	lm.poly_prism("Wood", foot, 6.2, 12.4)
	for i in foot.size():
		var a := foot[i]
		var b := foot[(i + 1) % foot.size()]
		if a.distance_to(b) > 6.0:
			var o := FhP.edge_out(foot, i)
			FhP.ribs(lm, "Wood", Vector3(a.x, 0, a.y), Vector3(b.x, 0, b.y), o, 6.2, 12.4, 0.9, 0.18, 0.12)
	# The canopy: the timber belly sweeping up to the square between the
	# two entrances, a curved soffit under the overhang.
	var rows: Array = []
	for j in 6:
		var t := float(j) / 5.0
		var row := PackedVector3Array()
		for i in 17:
			var u := float(i) / 16.0
			var x := lerpf(-12.0, 74.0, u)
			var zf := lerpf(12.0, 26.0, clampf(1.0 - absf(x - 44.0) / 60.0, 0.0, 1.0)) - 0.2
			var z := lerpf(5.6, zf, t)
			var lift := sin(PI * u) * 4.6 * t * t
			row.append(Vector3(x, 5.6 + lift, z))
		rows.append(row)
	lm.grid("Wood", rows, Vector3.DOWN)
	# Top floor: glass walls set back behind slender posts, the white roof
	# undulating over it, the slab edge and the south balcony.
	var top := PackedVector2Array()
	var cen := FhP.centre(foot)
	for p in foot:
		top.append(cen + (p - cen) * 0.97)
	lm.poly_prism("Floor", foot, 12.4, 13.0)
	lm.poly_prism("Glass", top, 13.0, 18.4, false)
	for i in top.size():
		var a := top[i]
		var b := top[(i + 1) % top.size()]
		FhP.ribs(lm, "Steel", Vector3(a.x, 0, a.y), Vector3(b.x, 0, b.y), FhP.edge_out(top, i), 13.0, 18.4, 3.0,
			0.15, 0.15)
	var rr: Array = []
	for j in 9:
		var t := float(j) / 8.0
		var row := PackedVector3Array()
		for i in 25:
			var x := lerpf(-46.0, 104.0, float(i) / 24.0)
			var z := lerpf(-20.0, 26.5, t)
			var y := 18.6 + 0.7 * sin(x * 0.11) * sin(z * 0.16 + 0.8) + 0.4 * sin(x * 0.05 + 1.0)
			row.append(Vector3(x, y, z))
		rr.append(row)
	lm.grid("Steel", rr, Vector3.UP)
	lm.poly_prism("Roof", top, 18.3, 18.5)
	lm.box("Floor", Vector3(97.0, 12.7, 2.0), Vector3(14.0, 0.5, 18.0), Basis(Vector3.UP, -0.5))
	LandmarkDetail.balustrade(lm, "Steel", Vector3(102.0, 13.0, -5.0), Vector3(104.5, 13.0, 10.0), 1.1, 3.0)
	lm.commit(model)

# --- Dipoli ----------------------------------------------------------------

## Reima and Raili Pietilä's Dipoli (1966), origin at the OSM footprint
## centre (registry yaw 17), parts after the OSM 3D outline: the main
## hall block whose copper-clad roof climbs from boulder-and-concrete
## walls to 10 m, the 6 m west wing, the low south-east wings, the 6 m
## block of long rooflit bays (glazed skillion ridges) to the south-west,
## and the copper roof lanterns rising to 11 m.
static func dipoli(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("cliff", "#8A8478", 4.0))
	lm.use("Wood", LandmarkMaterials.pbr("wood", "#8E6B47", 3.0))
	lm.use("Copper", LandmarkMaterials.pbr("concrete", "#7A8A70", 2.5, 0.5, 0.45))
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#A3A19B", 3.0))
	lm.use("Glass", LandmarkMaterials.glass("#2A3236"))
	var main := PackedVector2Array([Vector2(11.3, -5.5), Vector2(14.3, -7.6), Vector2(20.1, -7.4),
		Vector2(29.2, -8.8), Vector2(38.9, -9.1), Vector2(44.9, -11.7), Vector2(41.5, -6.3), Vector2(39.8, -3.5),
		Vector2(39.1, 2.5), Vector2(41.6, 9.9), Vector2(34.5, 10.6), Vector2(32.7, 13.8), Vector2(26.6, 18.5),
		Vector2(24.6, 26.8), Vector2(20.5, 35.5), Vector2(21.4, 44.9), Vector2(16.8, 43.3), Vector2(12.7, 43.2),
		Vector2(7.4, 46.5), Vector2(4.4, 49.7), Vector2(1.7, 35.7), Vector2(-3.5, 27.3), Vector2(-8.3, 26.6),
		Vector2(-11.7, 26.8), Vector2(-17.3, 28.1), Vector2(-18.2, 25.5), Vector2(-23.8, 31.5), Vector2(-25.0, 37.3),
		Vector2(-25.3, 41.2), Vector2(-30.3, 41.0), Vector2(-32.6, 43.3), Vector2(-37.0, 38.6), Vector2(-43.3, 35.0),
		Vector2(-46.6, 35.0), Vector2(-45.1, 22.7), Vector2(-47.7, 9.8), Vector2(-36.7, 15.6), Vector2(-31.0, 16.8),
		Vector2(-25.4, 16.7), Vector2(-21.8, 16.5), Vector2(-17.4, 14.3), Vector2(-14.2, 12.7), Vector2(-11.9, 11.5),
		Vector2(-7.0, 9.3), Vector2(-4.2, 6.6), Vector2(-0.9, 3.4), Vector2(0.9, 1.1), Vector2(3.2, -1.9),
		Vector2(5.9, -0.1), Vector2(9.2, -0.2), Vector2(11.4, -3.1)])
	var west := PackedVector2Array([Vector2(-21.3, -7.2), Vector2(-21.8, 16.5), Vector2(-25.4, 16.7),
		Vector2(-31.0, 16.8), Vector2(-36.7, 15.6), Vector2(-39.0, 9.0), Vector2(-40.4, 9.0), Vector2(-39.1, 6.4),
		Vector2(-36.1, 5.7), Vector2(-36.1, -3.4), Vector2(-34.4, -3.4), Vector2(-34.4, -14.3), Vector2(-32.0, -14.3),
		Vector2(-32.0, -15.8), Vector2(-46.0, -15.8), Vector2(-46.0, -18.5), Vector2(-47.3, -18.5),
		Vector2(-47.3, -29.4), Vector2(-32.9, -26.6), Vector2(-21.4, -26.6)])
	var se := PackedVector2Array([Vector2(2.3, -37.0), Vector2(7.1, -39.9), Vector2(7.1, -22.0), Vector2(11.6, -21.9),
		Vector2(15.0, -22.1), Vector2(18.3, -25.3), Vector2(23.8, -19.7), Vector2(24.2, -17.7), Vector2(22.5, -15.6),
		Vector2(18.7, -12.0), Vector2(14.1, -11.9), Vector2(12.7, -8.4), Vector2(11.3, -5.5), Vector2(11.4, -3.1),
		Vector2(9.2, -0.2), Vector2(5.9, -0.1), Vector2(3.2, -1.9)])
	var east := PackedVector2Array([Vector2(17.0, -26.5), Vector2(30.1, -40.0), Vector2(31.7, -37.9),
		Vector2(31.5, -34.6), Vector2(33.8, -30.8), Vector2(37.1, -25.0), Vector2(41.4, -20.7), Vector2(36.7, -16.1),
		Vector2(34.8, -14.2), Vector2(30.9, -13.4), Vector2(31.4, -8.0), Vector2(21.3, -8.4), Vector2(14.3, -7.6),
		Vector2(12.7, -8.4), Vector2(14.1, -11.9), Vector2(18.7, -12.0), Vector2(22.5, -15.6), Vector2(24.2, -17.7)])
	# Each block: boulder-studded base, timber-and-glass band, copper roof.
	for blk in [[main, 3.2, 4.4, 9.4, 0.42], [west, 2.6, 3.6, 6.0, 0.7], [se, 2.2, 3.2, 5.0, 0.75],
			[east, 2.4, 3.4, 6.0, 0.72]]:
		var poly: PackedVector2Array = blk[0]
		var y0: float = blk[1]
		var y1: float = blk[2]
		lm.poly_prism("Stone", poly, 0.0, y0)
		lm.poly_prism("Wood", poly, y0, y1, false)
		for i in poly.size():
			var a := poly[i]
			var b := poly[(i + 1) % poly.size()]
			if a.distance_to(b) > 4.0:
				var o := FhP.edge_out(poly, i)
				var a3 := Vector3(a.x, 0, a.y)
				var b3 := Vector3(b.x, 0, b.y)
				FhU.openings(lm, "Glass", a3, b3, o, y0 + 0.15, maxi(int(a.distance_to(b) / 3.0), 1), 1.6,
					y1 - y0 - 0.35, false, 0.03)
				FhP.ribs(lm, "Wood", a3, b3, o, y0, y1, 1.2, 0.14, 0.1)
				# Boulders set proud of the wall foot.
				for k in maxi(int(a.distance_to(b) / 2.6), 1):
					var p := a3.lerp(b3, (float(k) + 0.5) / maxf(float(int(a.distance_to(b) / 2.6)), 1.0))
					lm.lathe("Stone", p + o * 0.3, FhU.ball(0.45 + 0.25 * sin(float(k) * 2.3 + float(i))), 7, 1.3, 1.0,
						float(k))
		FhP.slope_roof(lm, "Copper", poly, FhP.centre(poly), float(blk[4]), y1, float(blk[3]))
	# The rooflit block to the south-west: long bays under glazed ridges.
	var sw := PackedVector2Array([Vector2(-21.5, -37.0), Vector2(3.2, -37.0), Vector2(3.2, 1.1),
		Vector2(-17.4, 14.3), Vector2(-21.5, 14.3)])
	lm.poly_prism("Concrete", sw, 0.0, 5.5)
	for r in [[-20.15, 2.7, 6.0], [-12.9, 2.6, 12.0], [-5.25, 2.1, 8.0], [1.7, 3.0, 0.5]]:
		var x: float = r[0]
		var hw: float = float(r[1]) * 0.5
		FhU.wedge(lm, "Glass", "Copper", x - hw, x + hw, -36.6, float(r[2]), 5.5, 0.5, 1.0)
	FhU.wedge(lm, "Copper", "Copper", -21.8, -17.4, -7.2, 14.3, 5.5, 2.5, 2.5)
	# Copper roof lanterns and their glazed sides.
	for q in [[8.75, 10.0, 5.9, 4.6, 11.0], [19.15, 10.35, 5.9, 7.5, 11.0], [26.55, 9.45, 4.3, 5.1, 11.0],
			[31.7, -2.25, 3.4, 2.7, 10.5], [15.25, -15.7, 2.5, 2.4, 6.5], [25.9, -16.15, 3.0, 2.3, 6.5]]:
		var top: float = q[4]
		FhU.blk(lm, "Copper", float(q[0]), top - 2.2, float(q[1]), float(q[2]), 2.2, float(q[3]))
		FhU.blk(lm, "Glass", float(q[0]), top - 1.8, float(q[1]), float(q[2]) + 0.1, 1.0, float(q[3]) + 0.1)
	lm.commit(model)

# --- Heureka ---------------------------------------------------------------

## Heikkinen-Komonen's science centre in Tikkurila (1989), origin at the
## OSM footprint centre (registry yaw 15): the white exhibition bars on
## the 9.6 m column grid of the Pillar Hall round the 34 m concrete
## Cylinder Hall (20 m outside, glass roof lantern at 22 m), and the
## mirror-clad 17 m dome of the planetarium (2016) on the west.
static func heureka(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("render", "#E8E6E0", 3.0))
	lm.use("Drum", LandmarkMaterials.pbr("concrete", "#C9C7C0", 3.0))
	lm.use("Glass", LandmarkMaterials.glass("#2F4A55"))
	lm.use("Mirror", LandmarkMaterials.pbr("concrete", "#B8C0C6", 3.0, 0.15, 0.9))
	lm.use("Red", LandmarkMaterials.paint("#C23A32", 0.5, 0.2))
	lm.use("Yellow", LandmarkMaterials.paint("#E4B83A", 0.5, 0.2))
	lm.use("Blue", LandmarkMaterials.paint("#2E5FA8", 0.5, 0.2))
	# Exhibition bars [cx, cz, w, d, h].
	var bars := [[27.0, -4.0, 34.0, 80.0, 12.0], [-4.5, -4.5, 29.0, 79.0, 7.0], [8.0, 50.0, 72.0, 30.0, 10.0],
		[-32.0, -4.0, 26.0, 76.0, 8.0], [-22.0, -48.0, 28.0, 12.0, 7.0]]
	for b in bars:
		var cx: float = b[0]
		var cz: float = b[1]
		var w: float = b[2]
		var d: float = b[3]
		var h: float = b[4]
		FhU.blk(lm, "Wall", cx, 0.0, cz, w, h, d)
		FhP.box_band(lm, "Drum", cx, cz, w, d, h - 0.6, 0.6, 0.15)
		FhP.box_band(lm, "Drum", cx, cz, w, d, 0.0, 0.5, 0.1)
		for face in FhP.faces(cx, cz, w, d):
			var l := (face[0] as Vector3).distance_to(face[1])
			FhP.ribs(lm, "Drum", face[0], face[1], face[2], 0.5, h - 0.6, 9.6, 0.5, 0.25)
			FhU.openings(lm, "Glass", face[0], face[1], face[2], 2.0, maxi(int(l / 9.6), 1), 5.5, minf(h - 4.0, 3.2),
				false, 0.03)
	# Pillar Hall canopy columns on the 9.6 m module along the entrance side.
	for i in 8:
		lm.frustum("Drum", Vector3(-28.0 + 9.6 * float(i), 0.0, 68.0), 0.35, 0.35, 9.4, 12)
	lm.box("Wall", Vector3(5.6, 9.7, 67.0), Vector3(70.0, 0.6, 4.0))
	# The Cylinder Hall: concrete drum with pilasters, glazed clerestory ring,
	# flat glass roof and the central lantern.
	var rc := Vector3(7.9, 0.0, -15.6)
	lm.frustum("Drum", rc, 16.8, 16.8, 18.4, 40)
	for k in 24:
		var a := TAU * float(k) / 24.0
		var d := Vector3(cos(a), 0, sin(a))
		lm.box("Drum", rc + d * 16.95 + Vector3(0, 9.2, 0), Vector3(0.7, 18.4, 0.5), Basis.looking_at(d), 0.0)
	lm.frustum("Glass", rc + Vector3(0, 18.4, 0), 16.6, 16.6, 1.2, 40)
	lm.frustum("Drum", rc + Vector3(0, 19.6, 0), 17.2, 17.2, 0.4, 40)
	lm.lathe("Glass", rc + Vector3(0, 20.0, 0), PackedVector2Array([Vector2(16.8, 0), Vector2(8.0, 0.3),
		Vector2(0.0, 0.4)]), 40)
	lm.frustum("Glass", rc + Vector3(0, 20.0, 0), 2.7, 2.7, 1.8, 16)
	lm.frustum("Drum", rc + Vector3(0, 21.8, 0), 2.9, 2.9, 0.2, 16)
	# Mirror-clad planetarium dome on its drum, with seams.
	var mc := Vector3(-30.4, 0.0, -4.55)
	lm.frustum("Mirror", mc, 8.6, 8.6, 6.4, 32)
	lm.lathe("Mirror", mc + Vector3(0, 6.4, 0), FhU.dome_prof(8.6, 8.6, 12), 32)
	for k in 16:
		var a := TAU * float(k) / 16.0
		var d := Vector3(cos(a), 0, sin(a))
		var prof := FhU.dome_prof(8.66, 8.66, 8)
		for j in prof.size() - 2:
			lm.beam("Drum", mc + Vector3(0, 6.4, 0) + d * prof[j].x + Vector3(0, prof[j].y, 0),
				mc + Vector3(0, 6.4, 0) + d * prof[j + 1].x + Vector3(0, prof[j + 1].y, 0), 0.12, 0.08)
	# Coloured cubes on the east and south faces.
	lm.box("Red", Vector3(44.9, 8.5, -14.0), Vector3(3.0, 3.0, 3.0))
	lm.box("Yellow", Vector3(44.9, 6.0, 10.0), Vector3(3.0, 3.0, 3.0))
	lm.box("Blue", Vector3(44.9, 9.0, 28.0), Vector3(3.0, 3.0, 3.0))
	lm.box("Red", Vector3(30.0, 7.5, 65.9), Vector3(3.0, 3.0, 3.0))
	lm.box("Yellow", Vector3(10.0, 6.5, 65.9), Vector3(3.0, 3.0, 3.0))
	lm.commit(model)
