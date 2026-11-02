class_name LandmarkNaBuildings
extends RefCounted

## Two grand buildings in true metres: the White House in Washington
## and Mexico City's Palacio de Bellas Artes.

const WHITE_HOUSE_TOP_M := 21.0
const BELLAS_ARTES_TOP_M := 52.0

## White House (1792-1800, James Hoban): the 51.2 x 26 m Aquia sandstone
## block, painted white, of eleven bays on the long fronts and three
## storeys (ground floor, State Floor, Second Floor) under the dentilled
## cornice, the vase balustrade and the low hipped roof of the 1927
## third floor with its chimneys; State Floor windows under alternating
## triangular and segmental pediments; the North Portico (1829, -Z) of
## unfluted Ionic columns under a pediment; the bowed South Portico
## (1824, +Z) of six Ionic columns round the Blue Room, with the Truman
## Balcony and the curved flights of steps; and the low West and East
## Wings joined by colonnades.
static func white_house(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("limestone", "#EDEBE4", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("slate", "#6C7074", 3.0))
	lm.use("Windows", LandmarkMaterials.glass("#2A3236"))
	lm.use("Trim", LandmarkMaterials.paint("#F4F3EF", 0.55, 0.05))
	var hx := 25.9
	var hz := 12.95
	lm.box("Wall", Vector3(0, 7.5, 0), Vector3(hx * 2.0, 15.0, hz * 2.0))
	# Rusticated ground floor joints and the State Floor string course.
	for q in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * q)
		var face: float = hz if q % 2 == 0 else hx
		var span: float = hx * 2.0 if q % 2 == 0 else hz * 2.0
		for k in 4:
			lm.box("Wall", r * Vector3(0, 0.9 + 0.95 * k, face + 0.02), Vector3(span, 0.08, 0.08), r, 0.0)
		lm.box("Wall", r * Vector3(0, 4.4, face + 0.15), Vector3(span + 0.3, 0.4, 0.3), r, 0.0)
	# Windows: eleven bays on the long fronts, five on the ends.
	for q in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * q)
		var long := q % 2 == 0
		var face: float = hz if long else hx
		var bays := 11 if long else 5
		var span: float = (hx * 2.0 if long else hz * 2.0) - 4.0
		for i in bays:
			var x := -span * 0.5 + span * (float(i) + 0.5) / float(bays)
			var n := r * Vector3(0, 0, 1)
			var central := long and absf(float(i) - 5.0) < 1.5
			if q == 0 and central:
				continue # the South Portico's bow covers the middle bays
			LandmarkDetail.window(lm, "Trim", "Windows", r * Vector3(x, 2.2, face), n, 1.3, 2.0, false, 0.18)
			LandmarkDetail.window(lm, "Trim", "Windows", r * Vector3(x, 7.0, face), n, 1.5, 3.4, false, 0.2)
			LandmarkDetail.window(lm, "Trim", "Windows", r * Vector3(x, 12.2, face), n, 1.4, 2.4, false, 0.18)
			# State Floor pediments, triangular and segmental by turns.
			var pc := r * Vector3(x, 9.55, face + 0.3)
			if i % 2 == 0:
				lm.gable("Trim", pc, 2.4, 0.4, 0.6, Basis(r.x, Vector3.UP, r.z), 0.1, "Trim")
			else:
				var prev := pc + r.x * 1.2
				for k in 6:
					var t := PI * float(k + 1) / 6.0
					var p := pc + r.x * cos(t) * 1.2 + Vector3(0, sin(t) * 0.45, 0)
					lm.beam("Trim", prev, p, 0.22, 0.4, r.z)
					prev = p
	# Cornice with dentils, vase balustrade, the hipped roof.
	for q in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * q)
		var face: float = hz if q % 2 == 0 else hx
		var half: float = hx if q % 2 == 0 else hz
		LandmarkDetail.cornice(lm, "Wall", r * Vector3(-half - 1.0, 15.0, face), r * Vector3(half + 1.0, 15.0, face),
			r * Vector3(0, 0, 1), 1.0, true)
		LandmarkNaParts.balusters(lm, "Wall", r * Vector3(-half, 16.0, face + 0.3), r * Vector3(half, 16.0, face + 0.3),
			1.0, 0.4, 4.7, true)
	LandmarkNaParts.hip(lm, "Roof", Vector3(0, 16.0, 0), Basis(), hx - 1.2, hz - 1.2, 0.72, 3.2)
	for cx in [-20.0, -10.0, 10.0, 20.0]:
		for cz in [-5.0, 5.0]:
			lm.box("Wall", Vector3(cx, 19.8, cz), Vector3(1.4, 2.4, 1.6))
			lm.box("Trim", Vector3(cx, 21.0 - 0.15, cz), Vector3(1.7, 0.3, 1.9), Basis(), 0.0)
	# Third-floor dormers on the roof slopes.
	for x in [-16.0, -8.0, 0.0, 8.0, 16.0]:
		for s in [-1.0, 1.0]:
			var dc := Vector3(x, 17.4, s * (hz - 2.6))
			lm.box("Roof", dc, Vector3(1.8, 1.6, 1.4))
			lm.box("Windows", dc + Vector3(0, 0, s * 0.72), Vector3(1.0, 1.0, 0.05), Basis(), 0.0)
	_wh_north_portico(lm, hz)
	_wh_south_portico(lm, hz)
	_wh_wings(lm, hx)
	lm.commit(model)

## North Portico: four Ionic columns across the front, two more down
## each side, entablature and pediment, over the entrance (-Z).
static func _wh_north_portico(lm: LandmarkMesh, hz: float) -> void:
	lm.box("Wall", Vector3(0, 0.3, -hz - 5.2), Vector3(17.0, 0.6, 10.4))
	for k in 4:
		lm.box("Wall", Vector3(0, 0.3 - 0.075 * k, -hz - 10.6 - 0.4 * k), Vector3(12.0, 0.6 - 0.15 * k, 0.4), Basis(), 0.0)
	var cols: Array[Vector3] = []
	for x in [-6.9, -2.3, 2.3, 6.9]:
		cols.append(Vector3(x, 0.6, -hz - 9.4))
	for x in [-6.9, 6.9]:
		for z in [-hz - 6.2, -hz - 3.0]:
			cols.append(Vector3(x, 0.6, z))
	for c in cols:
		LandmarkDetail.column(lm, "Trim", c, 0.75, 13.2, "ionic", 0)
	lm.box("Wall", Vector3(0, 14.4, -hz - 5.2), Vector3(16.4, 1.2, 10.4))
	LandmarkDetail.cornice(lm, "Wall", Vector3(-8.8, 15.0, -hz - 10.4), Vector3(8.8, 15.0, -hz - 10.4),
		Vector3.FORWARD, 1.0, true)
	lm.gable("Roof", Vector3(0, 16.0, -hz - 5.2), 17.2, 10.4, 3.2, Basis(), 0.4, "Wall")
	for s in [-1.0, 1.0]:
		lm.beam("Wall", Vector3(s * 9.0, 16.0, -hz - 10.6), Vector3(0, 19.2, -hz - 10.6), 0.6, 0.7, Vector3.UP)
	lm.box("Windows", Vector3(0, 3.0, -hz - 0.05), Vector3(2.0, 3.8, 0.2))
	LandmarkDetail.arch(lm, "Trim", Vector3(0, 4.9, -hz), Vector3.FORWARD, 2.0, 0.35, 0.25)
	# The lantern hanging in the porch.
	lm.beam("Trim", Vector3(0, 14.0, -hz - 5.2), Vector3(0, 11.5, -hz - 5.2), 0.06, 0.06)
	lm.lathe("Trim", Vector3(0, 10.4, -hz - 5.2), PackedVector2Array([Vector2(0.1, 0.0), Vector2(0.45, 0.3),
		Vector2(0.5, 0.8), Vector2(0.2, 1.1)]), 8)

## South Portico: the rusticated bow of the ground floor with its arched
## openings, the Blue Room's bowed wall, six Ionic columns, the Truman
## Balcony (1948), the entablature and balustrade, and the two curved
## flights of steps down to the South Lawn (+Z).
static func _wh_south_portico(lm: LandmarkMesh, hz: float) -> void:
	var c := Vector3(0, 0, hz)
	lm.frustum("Wall", c, 9.8, 9.8, 4.4, 32)
	lm.frustum("Wall", c + Vector3(0, 4.4, 0), 7.8, 7.8, 10.6, 32)
	for k in 5:
		var a := PI * (float(k) + 0.5) / 5.0
		var d := Vector3(cos(a), 0, sin(a))
		LandmarkDetail.window(lm, "Trim", "Windows", c + d * 9.8 + Vector3(0, 2.2, 0), d, 1.6, 2.6, true, 0.2)
	for k in 3:
		var a := PI * (float(k) + 1.0) / 4.0
		var d := Vector3(cos(a), 0, sin(a))
		LandmarkDetail.window(lm, "Trim", "Windows", c + d * 7.8 + Vector3(0, 7.0, 0), d, 1.5, 3.6, false, 0.2)
		LandmarkDetail.window(lm, "Trim", "Windows", c + d * 7.8 + Vector3(0, 12.3, 0), d, 1.4, 2.4, false, 0.18)
	for k in 6:
		var a := PI * (float(k) + 0.5) / 6.0
		LandmarkDetail.column(lm, "Trim", c + Vector3(cos(a), 0, sin(a)) * 9.0 + Vector3(0, 4.4, 0), 0.62, 10.6,
			"ionic", 0)
	# Truman Balcony at the Second Floor, railing on its rim.
	lm.frustum("Wall", c + Vector3(0, 10.0, 0), 8.6, 8.6, 0.3, 32)
	LandmarkNaParts.ring_rail(lm, "Trim", c + Vector3(0, 10.3, 0), 8.4, 1.0, 0.25)
	lm.frustum("Wall", c + Vector3(0, 15.0, 0), 10.0, 10.0, 1.0, 32)
	LandmarkNaParts.ring(lm, "Wall", c + Vector3(0, 16.0, 0), 9.7, 0.6, 0.3, 32)
	LandmarkNaParts.ring_posts(lm, "Wall", c + Vector3(0, 16.0, 0), 9.7, 0.9, 120, 0.16, 0.16)
	LandmarkNaParts.ring(lm, "Wall", c + Vector3(0, 16.9, 0), 9.7, 0.6, 0.2, 32)
	# Curved double flight from the portico floor down each side.
	for s in [-1.0, 1.0]:
		for k in 20:
			var t := float(k) / 19.0
			var a := lerpf(0.35, 1.25, t)
			var d := Vector3(cos(a) * float(s), 0, sin(a))
			var top := 4.4 - 0.21 * float(k)
			lm.box("Wall", c + d * 12.0 + Vector3(0, top * 0.5, 0), Vector3(3.2, top, 0.62),
				Basis.looking_at(d.cross(Vector3.UP)), 0.0)

## West and East Wings with their colonnades along the South Lawn side.
static func _wh_wings(lm: LandmarkMesh, hx: float) -> void:
	for s in [-1.0, 1.0]:
		var link := Vector3(s * (hx + 6.0), 0, 2.0)
		lm.box("Wall", link + Vector3(0, 2.6, -1.2), Vector3(12.0, 5.2, 3.6))
		for k in 5:
			LandmarkNaParts.column_lite(lm, "Trim", link + Vector3(-4.8 + 2.4 * k, 0, 1.8), 0.3, 4.6, 0.0, 10)
		lm.box("Wall", link + Vector3(0, 4.9, 0.6), Vector3(12.4, 0.6, 3.6))
		var c := Vector3(s * (hx + 26.0), 0, 0)
		lm.box("Wall", c + Vector3(0, 4.75, 0), Vector3(26.0, 9.5, 22.0))
		LandmarkNaParts.hip(lm, "Roof", c + Vector3(0, 9.5, 0), Basis(), 13.5, 11.5, 0.75, 1.8)
		for fz in [-1.0, 1.0]:
			LandmarkDetail.pierced_face(lm, "Wall", "Windows", c + Vector3(-13.0 * fz, 0, fz * 11.0),
				Vector3(fz, 0, 0), Vector3(0, 0, fz), 26.0, 9.2, 7, 2, Vector2(1.3, 2.0), 1.4, 4.4, 0.25)
			LandmarkDetail.cornice(lm, "Wall", c + Vector3(-13.2, 9.5, fz * 11.25), c + Vector3(13.2, 9.5, fz * 11.25),
				Vector3(0, 0, fz), 0.6, false)

## Palacio de Bellas Artes (1904-1934, Adamo Boari, Federico Mariscal):
## the white Carrara-marble Art Nouveau body on its beige Yautepec
## marble stylobate, its main front (+Z) facing south onto Avenida
## Juárez, the Alameda Central along its west side. The front: the projecting central portal with its
## great arch, bronze doors and the "Harmony" group by Leonardo
## Bistolfi on top, between paired columns; arcaded wings with arched
## windows below and a colonnaded storey above; the dentilled cornice
## and balustrade. On the roof the two smaller tiled domes over the
## corner pavilions and the great central dome of orange and yellow
## tile gores between white ribs, its drum of paired pilasters and
## oculi, and the glass crown with the bronze eagle to 52 m. Agustí
## Querol's four Pegasus groups stand on the plaza.
static func bellas_artes(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#E7E4DD", 3.0))
	lm.use("Dome", LandmarkMaterials.pbr("brick", "#C77035", 3.0))
	lm.use("Yellow", LandmarkMaterials.pbr("brick", "#D9A93A", 3.0))
	lm.use("Tile", LandmarkMaterials.pbr("slate", "#3A8C98", 2.5))
	lm.use("Windows", LandmarkMaterials.glass("#2A3236"))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.use("Bronze", LandmarkMaterials.paint("#4B4033", 0.5, 0.5))
	lm.use("Base", LandmarkMaterials.pbr("limestone", "#CDBF9F", 3.0))
	lm.box("Base", Vector3(0, 0.75, 0), Vector3(102.0, 1.5, 76.0))
	lm.box("Marble", Vector3(0, 12.75, 0), Vector3(95.4, 22.5, 69.4))
	# Front steps across the portal.
	for k in 5:
		lm.box("Base", Vector3(0, 0.75 - 0.15 * k, 38.2 + 0.4 * k), Vector3(40.0 - 2.0 * k, 1.5 - 0.3 * k, 0.4),
			Basis(), 0.0)
	# Window bays on every face: arched ground floor, square upper floor
	# between pairs of engaged columns.
	for q in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * q)
		var long := q % 2 == 0
		var face: float = 34.7 if long else 47.7
		var span: float = 92.0 if long else 66.0
		var bays := 13 if long else 9
		var n := r * Vector3(0, 0, 1)
		for i in bays:
			var x := -span * 0.5 + span * (float(i) + 0.5) / float(bays)
			if q == 0 and absf(x) < 15.0:
				continue # the central portal
			LandmarkDetail.window(lm, "Marble", "Windows", r * Vector3(x, 6.0, face), n, 2.4, 5.2, true, 0.3)
			LandmarkDetail.window(lm, "Marble", "Windows", r * Vector3(x, 15.4, face), n, 2.0, 3.6, false, 0.3)
			for s in [-1.0, 1.0]:
				var px: float = x + float(s) * span / float(bays) * 0.5
				LandmarkNaParts.column_lite(lm, "Marble", r * Vector3(px - float(s) * 0.55, 11.4, face + 0.5), 0.36,
					9.4, 1.0, 8)
		lm.box("Marble", r * Vector3(0, 11.2, face + 0.3), Vector3(span + 2.0, 0.6, 0.6), r)
		LandmarkDetail.cornice(lm, "Marble", r * Vector3(-span * 0.5 - 1.4, 22.5, face + 0.2),
			r * Vector3(span * 0.5 + 1.4, 22.5, face + 0.2), n, 1.5, true)
		LandmarkNaParts.balusters(lm, "Marble", r * Vector3(-span * 0.5, 24.0, face), r * Vector3(span * 0.5, 24.0, face),
			1.2, 0.45, 6.0, true)
	_ba_portal(lm)
	# Corner pavilions' attic and their tiled domes.
	for sx in [-1.0, 1.0]:
		var p := Vector3(sx * 38.0, 24.0, 0)
		lm.box("Marble", p + Vector3(0, 3.0, 0), Vector3(20.0, 6.0, 60.0))
		lm.frustum("Marble", p + Vector3(0, 6.0, 0), 8.6, 8.6, 1.0, 32)
		lm.frustum("Marble", p + Vector3(0, 7.0, 0), 8.3, 8.3, 3.0, 32)
		LandmarkNaParts.ring_posts(lm, "Marble", p + Vector3(0, 7.0, 0), 8.4, 3.0, 16, 0.5, 0.4)
		lm.lathe("Tile", p + Vector3(0, 10.0, 0), LandmarkKits._dome_profile(8.8, 8.0, 10), 32)
		for i in 8:
			var a := TAU * float(i) / 8.0
			var d := Vector3(cos(a), 0, sin(a))
			var prof := LandmarkKits._dome_profile(8.95, 8.1, 8)
			for j in 7:
				lm.beam("Marble", p + Vector3(0, 10.0, 0) + d * prof[j].x + Vector3(0, prof[j].y, 0),
					p + Vector3(0, 10.0, 0) + d * prof[j + 1].x + Vector3(0, prof[j + 1].y, 0), 0.4, 0.25,
					d.cross(Vector3.UP))
		lm.frustum("Gold", p + Vector3(0, 17.6, 0), 0.9, 0.6, 0.8, 12)
		lm.frustum("Gold", p + Vector3(0, 18.4, 0), 0.5, 0.15, 2.4, 8)
	_ba_dome(lm, Vector3(0, 24.0, 0))
	# The four Pegasus groups on the plaza in front.
	for x in [-30.0, -18.0, 18.0, 30.0]:
		_pegasus(lm, Vector3(x, 0, 44.0))
	lm.commit(model)

## The central portal: a projecting pavilion with the great arch, its
## glazed screen and bronze doors, paired Corinthian columns either side
## and the "Harmony" sculpture group on the attic above.
static func _ba_portal(lm: LandmarkMesh) -> void:
	var z := 34.7
	lm.box("Marble", Vector3(0, 13.0, z + 1.8), Vector3(28.0, 23.0, 3.6))
	lm.box("Windows", Vector3(0, 8.0, z + 3.62), Vector3(10.0, 13.0, 0.1))
	for x in [-3.4, 0.0, 3.4]:
		lm.box("Bronze", Vector3(x, 3.6, z + 3.7), Vector3(2.6, 4.2, 0.2))
	for k in 3:
		lm.box("Marble", Vector3(0, 6.0 + 4.0 * k, z + 3.66), Vector3(10.0, 0.3, 0.2), Basis(), 0.0)
	LandmarkDetail.arch(lm, "Marble", Vector3(0, 14.5, z + 3.6), Vector3.BACK, 10.0, 1.2, 0.6)
	for s in [-1.0, 1.0]:
		for k in 2:
			LandmarkDetail.column(lm, "Marble", Vector3(s * (8.4 + 2.2 * k), 1.5, z + 4.6), 0.75, 17.0, "corinthian", 0)
		lm.box("Marble", Vector3(s * 9.5, 19.4, z + 4.6), Vector3(4.6, 1.8, 2.2))
	LandmarkDetail.cornice(lm, "Marble", Vector3(-14.5, 22.5, z + 3.6), Vector3(14.5, 22.5, z + 3.6), Vector3.BACK, 1.6, true)
	lm.box("Marble", Vector3(0, 26.0, z + 1.8), Vector3(22.0, 3.5, 3.0))
	# Harmony: the central figure between the groups of the passions.
	LandmarkKits.statue_figure(lm, "Marble", Vector3(0, 27.75, z + 2.4), 5.0, true)
	for x in [-7.0, -4.0, 4.0, 7.0]:
		LandmarkKits.statue_figure(lm, "Marble", Vector3(x, 27.75, z + 2.4), 3.4)

## The central dome: drum with paired pilasters and oculi, the shell in
## alternating orange and yellow tile gores between white ribs, and the
## glass crown under the bronze eagle.
static func _ba_dome(lm: LandmarkMesh, b: Vector3) -> void:
	lm.frustum("Marble", b, 16.4, 16.4, 1.2, 48)
	lm.frustum("Marble", b + Vector3(0, 1.2, 0), 15.5, 15.5, 7.8, 48)
	for k in 16:
		var a := TAU * float(k) / 16.0
		var d := Vector3(cos(a), 0, sin(a))
		for s in [-1.0, 1.0]:
			var pa := a + float(s) * 0.035
			lm.box("Marble", b + Vector3(cos(pa), 0, sin(pa)) * 15.7 + Vector3(0, 5.1, 0), Vector3(0.6, 7.8, 0.5),
				Basis.looking_at(Vector3(cos(pa), 0, sin(pa))))
		var wa := a + TAU / 32.0
		var wd := Vector3(cos(wa), 0, sin(wa))
		lm.disc("Windows", b + wd * 15.56 + Vector3(0, 5.2, 0), wd, 1.2, 12)
		for i in 12:
			var t0 := TAU * float(i) / 12.0
			var t1 := TAU * float(i + 1) / 12.0
			var tv := wd.cross(Vector3.UP)
			lm.beam("Marble", b + wd * 15.62 + Vector3(0, 5.2, 0) + (tv * cos(t0) + Vector3.UP * sin(t0)) * 1.35,
				b + wd * 15.62 + Vector3(0, 5.2, 0) + (tv * cos(t1) + Vector3.UP * sin(t1)) * 1.35, 0.3, 0.25, wd)
	lm.lathe("Marble", b + Vector3(0, 9.0, 0), PackedVector2Array([Vector2(15.5, 0.0), Vector2(16.3, 0.5),
		Vector2(16.5, 1.0), Vector2(15.6, 1.1)]), 48)
	# Shell gores: 16 sectors alternately orange and yellow.
	var sh := b + Vector3(0, 10.0, 0)
	var prof := LandmarkKits._dome_profile(15.4, 11.0, 12)
	var gores := 16
	for g in gores:
		var key := "Dome" if g % 2 == 0 else "Yellow"
		var rows: Array = []
		for j in prof.size() - 1:
			var row := PackedVector3Array()
			for i in 5:
				var a := TAU * (float(g) + float(i) / 4.0) / float(gores)
				row.append(sh + Vector3(cos(a) * prof[j].x, prof[j].y, sin(a) * prof[j].x))
			rows.append(row)
		lm.grid(key, rows, sh, true)
	var rp := LandmarkKits._dome_profile(15.6, 11.15, 12)
	for g in gores:
		var a := TAU * float(g) / float(gores)
		var d := Vector3(cos(a), 0, sin(a))
		for j in rp.size() - 2:
			lm.beam("Marble", sh + d * rp[j].x + Vector3(0, rp[j].y, 0), sh + d * rp[j + 1].x + Vector3(0, rp[j + 1].y, 0),
				0.5, 0.3, d.cross(Vector3.UP))
	# Glass crown, its ribs, and the bronze eagle.
	var cr := sh + Vector3(0, prof[prof.size() - 2].y, 0)
	lm.frustum("Marble", cr, 3.4, 3.2, 0.8, 24)
	lm.lathe("Windows", cr + Vector3(0, 0.8, 0), PackedVector2Array([Vector2(3.0, 0.0), Vector2(2.8, 1.6),
		Vector2(1.8, 2.8), Vector2(0.6, 3.4)]), 16)
	LandmarkNaParts.ring_posts(lm, "Gold", cr + Vector3(0, 0.8, 0), 3.0, 2.0, 16, 0.12, 0.12)
	var e := cr + Vector3(0, 4.2, 0)
	lm.frustum("Bronze", e - Vector3(0, 0.1, 0), 0.7, 0.5, 0.6, 10)
	lm.lathe("Bronze", e + Vector3(0, 0.5, 0), PackedVector2Array([Vector2(0.35, 0.0), Vector2(0.5, 0.6),
		Vector2(0.3, 1.2), Vector2(0.18, 1.5), Vector2(0.0, 1.7)]), 10, 1.0, 1.4)
	for s in [-1.0, 1.0]:
		var root := e + Vector3(float(s) * 0.3, 1.0, 0)
		for nz in [-1.0, 1.0]:
			lm.tri("Bronze", root, e + Vector3(float(s) * 2.4, BELLAS_ARTES_TOP_M - e.y, -0.3), e + Vector3(float(s) * 2.0, 0.7, -0.2),
				Vector3(0, 0, nz), Vector3(0, 0, nz), Vector3(0, 0, nz), Vector2.ZERO, Vector2(2.0, 0), Vector2(2.0, -1.0))

## A rearing bronze Pegasus on its marble pedestal at `b` (Querol, 1900s).
static func _pegasus(lm: LandmarkMesh, b: Vector3) -> void:
	lm.box("Marble", b + Vector3(0, 1.4, 0), Vector3(3.0, 2.8, 4.6))
	lm.box("Marble", b + Vector3(0, 2.95, 0), Vector3(3.4, 0.3, 5.0))
	var h := b + Vector3(0, 3.1, 0)
	# Body rearing up on the hind legs, then the neck and head.
	lm.beam("Bronze", h + Vector3(0, 1.2, -0.9), h + Vector3(0, 2.2, 0.6), 0.9, 1.0)
	for s in [-1.0, 1.0]:
		lm.beam("Bronze", h + Vector3(float(s) * 0.25, 0.9, -0.6), h + Vector3(float(s) * 0.25, 0.0, -0.8), 0.18, 0.18)
		lm.beam("Bronze", h + Vector3(float(s) * 0.25, 2.4, 0.4), h + Vector3(float(s) * 0.25, 2.2, 1.2), 0.16, 0.16)
	lm.beam("Bronze", h + Vector3(0, 2.6, 0.5), h + Vector3(0, 3.7, 0.9), 0.4, 0.35)
	lm.box("Bronze", h + Vector3(0, 3.8, 1.2), Vector3(0.35, 0.4, 0.8))
	for s in [-1.0, 1.0]:
		var root := h + Vector3(float(s) * 0.3, 2.0, 0)
		for nz in [-1.0, 1.0]:
			lm.tri("Bronze", root, h + Vector3(float(s) * 2.0, 3.8, -0.6), h + Vector3(float(s) * 1.6, 1.6, -0.9),
				Vector3(0, 0, nz), Vector3(0, 0, nz), Vector3(0, 0, nz), Vector2.ZERO, Vector2(2.0, 0), Vector2(2.0, -1.0))
