class_name LandmarkFhHelsinkiModern
extends RefCounted

## Three modern buildings in true metres: Kiasma (Steven Holl, curved
## aluminium-and-glass volumes), the Oodi library (ALA, timber belly under
## a steel arch) and the Heureka science centre (Dipoli has its own
## LandmarkFhDipoli). Footprints are the OpenStreetMap
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

## Helsinki Central Library Oodi (ALA Architects, 2018), origin at the OSM
## footprint centre, x along the 149 m long axis, front +Z on the
## Kansalaistori side (the registry yaw turns it onto the map). Three
## storeys: the glazed ground floor pulled back under the great canopy
## (the spruce belly swooping up from the glass to a lip 8 m up between
## the two entrances and down to the ground at both ends), the timber
## middle floor with its dark louvre band, and "book heaven" on top, a band
## of milky glass in white fins under the white roof, whose edge rises and
## falls in a long wave (about 20 m at its highest).

const OODI_FRONT := [Vector2(-45.4, 12.2), Vector2(43.3, 26.2), Vector2(44.8, 26.3), Vector2(49.8, 26.1),
	Vector2(55.3, 24.8), Vector2(104.0, 12.5)]
const OODI_BACK := [Vector2(-45.3, -19.6), Vector2(83.5, -19.1), Vector2(90.5, -8.2), Vector2(104.0, 12.5)]
const OODI_STEPS := 75

## Footprint z of the front edge at x.
static func _oodi_zf(x: float) -> float:
	for i in OODI_FRONT.size() - 1:
		var a: Vector2 = OODI_FRONT[i]
		var b: Vector2 = OODI_FRONT[i + 1]
		if x <= b.x:
			return lerpf(a.y, b.y, clampf((x - a.x) / maxf(b.x - a.x, 0.001), 0.0, 1.0))
	return (OODI_FRONT[OODI_FRONT.size() - 1] as Vector2).y

## The canopy: (recess under it, height of its lip, top of the glass wall)
## at x, zero at both ends and full between the two entrances.
static func _oodi_cave(x: float) -> Vector3:
	var b := smoothstep(-6.0, 18.0, x) * (1.0 - smoothstep(56.0, 80.0, x))
	var lip := 8.2 * pow(b, 0.55)
	return Vector3(11.0 * b, lip, minf(4.8, lip * 0.62))

## Top of the timber floor (the sill of the glass band) at x.
static func _oodi_sill(x: float) -> float:
	var u := (x + 45.4) / 149.4
	var wave := 0.6 * sin(5.2 * u) + 0.4 * sin(11.0 * u + 1.1) + 0.5 * smoothstep(0.65, 1.0, u)
	return 12.2 + 1.1 * wave

## `n` + 1 points evenly by length along the polyline.
static func _oodi_resample(poly: Array, n: int) -> PackedVector2Array:
	var total := 0.0
	for i in poly.size() - 1:
		total += (poly[i] as Vector2).distance_to(poly[i + 1])
	var out := PackedVector2Array()
	var seg := 0
	var acc := 0.0
	for k in n + 1:
		var want := total * float(k) / float(n)
		while seg < poly.size() - 2 and acc + (poly[seg] as Vector2).distance_to(poly[seg + 1]) < want:
			acc += (poly[seg] as Vector2).distance_to(poly[seg + 1])
			seg += 1
		var a: Vector2 = poly[seg]
		var b: Vector2 = poly[seg + 1]
		out.append(a.lerp(b, clampf((want - acc) / maxf(a.distance_to(b), 0.001), 0.0, 1.0)))
	return out

static func oodi(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Glass", LandmarkMaterials.lit("#B99B66", 0.2))
	lm.use("Wood", LandmarkMaterials.pbr("wood", "#CC913F", 3.0))
	lm.use("Louvre", LandmarkMaterials.pbr("wood", "#4A3524", 2.0))
	lm.use("Frit", LandmarkMaterials.lit("#BFCBCE", 0.1))
	lm.use("Roof", LandmarkMaterials.pbr("concrete", "#E4E6E6", 3.0, 0.4, 0.3))
	lm.use("Steel", LandmarkMaterials.paint("#F0F1F1", 0.4, 0.3))
	lm.use("Sky", LandmarkMaterials.glass("#3E5560"))
	var n := OODI_STEPS
	var fr := PackedVector2Array()
	for i in n + 1:
		var x := lerpf(-45.4, 104.0, float(i) / float(n))
		fr.append(Vector2(x, _oodi_zf(x)))
	var bk := _oodi_resample(OODI_BACK, n)
	# The footprint as a closed ring: the front west to east, the back and
	# the ends coming home.
	var ring := PackedVector2Array(fr)
	for i in range(n - 1, -1, -1):
		ring.append(bk[i])
	for k in range(1, 8):
		ring.append(bk[0].lerp(fr[0], float(k) / 8.0))
	var hint := Vector3(30.0, 9.0, -3.0)
	# The front: glass line, the swooping belly, the lip and the wall above.
	var r0 := PackedVector3Array()
	var r1 := PackedVector3Array()
	var r2 := PackedVector3Array()
	var r3 := PackedVector3Array()
	var r4 := PackedVector3Array()
	var r5 := PackedVector3Array()
	var r6 := PackedVector3Array()
	var g0 := PackedVector3Array()
	var g1 := PackedVector3Array()
	for p in fr:
		var cv := _oodi_cave(p.x)
		var sill := _oodi_sill(p.x)
		var zg := p.y - cv.x
		r0.append(Vector3(p.x, cv.z, zg))
		r1.append(Vector3(p.x, cv.z + (cv.y - cv.z) * 0.25, p.y - cv.x * 0.5625))
		r2.append(Vector3(p.x, cv.z + (cv.y - cv.z) * 0.5, p.y - cv.x * 0.25))
		r3.append(Vector3(p.x, cv.z + (cv.y - cv.z) * 0.75, p.y - cv.x * 0.0625))
		r4.append(Vector3(p.x, cv.y, p.y))
		r5.append(Vector3(p.x, (cv.y + sill) * 0.5, p.y))
		r6.append(Vector3(p.x, sill, p.y))
		g0.append(Vector3(p.x, 0.0, zg))
		g1.append(Vector3(p.x, cv.z, zg))
		if cv.z > 1.2 and (int(round((p.x + 45.4) / 2.0)) % 2 == 0):
			lm.box("Steel", Vector3(p.x, cv.z * 0.5, zg + 0.08), Vector3(0.14, cv.z, 0.16), Basis(), 0.0)
	lm.grid("Wood", [r0, r1, r2, r3, r4, r5, r6], hint, true)
	lm.grid("Glass", [g0, g1], hint, true)
	# Back and end walls, vertical timber.
	for k in range(n, ring.size()):
		var a := ring[k]
		var b := ring[(k + 1) % ring.size()]
		var o := FhP.edge_out(ring, k)
		lm.quad("Wood", Vector3(a.x, 0, a.y), Vector3(b.x, 0, b.y), Vector3(b.x, _oodi_sill(b.x), b.y),
			Vector3(a.x, _oodi_sill(a.x), a.y), o)
	for k in ring.size():
		var a := ring[k]
		var b := ring[(k + 1) % ring.size()]
		var o := FhP.edge_out(ring, k)
		var sa := _oodi_sill(a.x)
		var sb := _oodi_sill(b.x)
		var ta := sa + 5.4
		var tb := sb + 5.4
		var lip_a := _oodi_cave(a.x).y if k < n else 0.0
		var lip_b := _oodi_cave(b.x).y if k < n else 0.0
		var la := lip_a + 0.33 * (sa - lip_a)
		var lb := lip_b + 0.33 * (sb - lip_b)
		var oo := Vector3(o.x, 0, o.z)
		var a3 := Vector3(a.x, 0, a.y)
		var b3 := Vector3(b.x, 0, b.y)
		# The dark louvre band running with the lip.
		lm.quad("Louvre", a3 + oo * 0.07 + Vector3(0, la, 0), b3 + oo * 0.07 + Vector3(0, lb, 0),
			b3 + oo * 0.07 + Vector3(0, lb + 1.0, 0), a3 + oo * 0.07 + Vector3(0, la + 1.0, 0), o)
		# Slab edge, then the milky glass band and the roof fascia.
		lm.quad("Steel", a3 + oo * 0.08 + Vector3(0, sa - 0.3, 0), b3 + oo * 0.08 + Vector3(0, sb - 0.3, 0),
			b3 + oo * 0.08 + Vector3(0, sb + 0.1, 0), a3 + oo * 0.08 + Vector3(0, sa + 0.1, 0), o)
		lm.quad("Frit", a3 + Vector3(0, sa, 0), b3 + Vector3(0, sb, 0), b3 + Vector3(0, tb - 0.5, 0),
			a3 + Vector3(0, ta - 0.5, 0), o)
		lm.quad("Steel", a3 + oo * 0.1 + Vector3(0, ta - 0.55, 0), b3 + oo * 0.1 + Vector3(0, tb - 0.55, 0),
			b3 + oo * 0.1 + Vector3(0, tb, 0), a3 + oo * 0.1 + Vector3(0, ta, 0), o)
		lm.box("Steel", Vector3(a.x, (sa + ta) * 0.5 - 0.2, a.y) + oo * 0.06, Vector3(0.14, ta - sa - 0.6, 0.16),
			Basis(), 0.0)
		# Timber battens up the wall above the lip.
		var tl := Vector3(a.x, lip_a, a.y)
		var tt := Vector3(a.x, sa, a.y)
		lm.beam("Wood", tl + oo * 0.04 + Vector3(0, 0.2, 0), tt + oo * 0.04 - Vector3(0, 0.2, 0), 0.07, 0.07,
			Vector3.UP.cross(oo))
	# The white roof: a shallow swell across the width, edge following the wave.
	var rr: Array = []
	for j in 9:
		var t := float(j) / 8.0
		var row := PackedVector3Array()
		for i in n + 1:
			var p := bk[i].lerp(fr[i], t)
			var camber := 0.45 * sin(PI * t) * (0.7 + 0.3 * sin(0.09 * p.x))
			row.append(Vector3(p.x, _oodi_sill(p.x) + 5.4 + camber, p.y))
		rr.append(row)
	lm.grid("Roof", rr, Vector3.UP)
	# Rooflights along the ridge.
	for k in 9:
		var i := int(round((float(k) * 14.0 + 10.0) / 149.4 * float(n)))
		var p := bk[i].lerp(fr[i], 0.5)
		var y := _oodi_sill(p.x) + 5.4 + 0.45 * (0.7 + 0.3 * sin(0.09 * p.x)) + 0.15
		lm.box("Sky", Vector3(p.x, y, p.y), Vector3(4.2, 0.4, 2.2), Basis(Vector3.UP, 0.12), 0.0)
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
