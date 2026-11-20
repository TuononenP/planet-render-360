extends RefCounted

## oodi_library. Registry entry and model in one file.

const FhU = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")
const FhP = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_parts.gd")

const ENTRY := {"type": "oodi_library", "name": "Oodi Central Library", "lat": 60.17394, "lon": 24.93798,
	"radius_m": 5000.0, "wiki_title": "Helsinki Central Library Oodi", "height_m": 23.6, "clear_m": 112.0,
	"yaw_deg": 87.0, "kind": "Library", "aliases": ["oodi central library", "helsinki central library oodi",
		"helsingin keskustakirjasto oodi", "oodi helsinki"]}

## From the Commons photos (visual-plan/refs/landmarks/oodi_library/): honey
## spruce cladding, a milky-glass top band with a wavy edge, the belly
## sweeping up over the glazed ground floor. Measured: the outline (OSM way
## 596937289) and the 23.6 m top (LoD2); estimated: the wave amplitude and
## the 6 m band height (the photo shows about a quarter of the height).
##
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
## Height of the milky-glass "book heaven" band.
const BAND := 6.0

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
	return 15.3 + 1.5 * wave

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

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Glass", LandmarkMaterials.lit("#D2B27A", 0.25))
	lm.use("Wood", LandmarkMaterials.pbr("wood", "#E2A24C", 3.0))
	lm.use("Louvre", LandmarkMaterials.pbr("wood", "#4A3524", 2.0))
	lm.use("Frit", LandmarkMaterials.lit("#E4EAEA", 0.12))
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
		var ta := sa + BAND
		var tb := sb + BAND
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
			row.append(Vector3(p.x, _oodi_sill(p.x) + BAND + camber, p.y))
		rr.append(row)
	lm.grid("Roof", rr, Vector3.UP)
	# Rooflights along the ridge.
	for k in 9:
		var i := int(round((float(k) * 14.0 + 10.0) / 149.4 * float(n)))
		var p := bk[i].lerp(fr[i], 0.5)
		var y := _oodi_sill(p.x) + BAND + 0.45 * (0.7 + 0.3 * sin(0.09 * p.x)) + 0.15
		lm.box("Sky", Vector3(p.x, y, p.y), Vector3(4.2, 0.4, 2.2), Basis(Vector3.UP, 0.12), 0.0)
	lm.commit(model)
