class_name LandmarkIbSantiago
extends RefCounted

## Santiago de Compostela Cathedral in true metres, the Obradoiro front
## toward +Z (the registry yaw_deg turns it onto the real bearing: the
## front faces west, so +X is south).

const SAN_TOP := 75.0

## The pilgrim cathedral, origin at the middle of its 97 m length: the
## Obradoiro front (Casas Novoa, 1738-1750) of golden granite toward +Z,
## a glazed central body in two orders of columns stepping up to the
## statue of St James the pilgrim, between the Campanas and Carraca
## towers (about 75 m) with their stages of columns, balustrades,
## obelisk pinnacles and stone cupolas; the diamond-shaped double stair
## in front. Behind it the 22 m Romanesque nave with buttressed aisles
## and gallery windows, the transept with the Praterias portal on the
## south arm, the octagonal crossing tower, the apse with its ring of
## chapels, the 75 m Berenguela clock tower (Domingo de Andrade,
## 1676-1680) at the Quintana corner and, south of the western nave, the
## Renaissance cloister with the stepped pyramid of the Treasury tower.
static func santiago(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Light", LandmarkMaterials.pbr("limestone", "#CDBFA0", 3.0))
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#B6AE9E", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("stone", "#8C8A83", 3.0))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#3B3833", 3.0))
	lm.use("Gilt", LandmarkMaterials.gold())
	lm.use("Steps", LandmarkMaterials.pbr("pavement", "#B5AD9D", 3.0))
	lm.use("Glass", LandmarkMaterials.glass())
	_body(lm)
	_obradoiro(lm)
	for s in [-1.0, 1.0]:
		_front_tower(lm, Vector3(s * 19.0, 0, 42.25))
	_berenguela(lm, Vector3(24.0, 0, -9.5))
	_cloister(lm, Vector3(39.0, 0, 27.0))
	lm.commit(model)

## Nave, aisles, transept with the Praterias portal, crossing tower, apse
## and chapels.
static func _body(lm: LandmarkMesh) -> void:
	lm.box("Granite", Vector3(0, 10.5, 0), Vector3(20.0, 21.0, 80.0))
	lm.gable("Roof", Vector3(0, 21.0, 0), 20.0, 80.0, 5.0, Basis(), 0.5)
	for s in [-1.0, 1.0]:
		var sn := Vector3(s, 0, 0)
		lm.box("Granite", Vector3(s * 14.75, 6.5, 0), Vector3(9.5, 13.0, 76.0))
		LandmarkCeParts.hip(lm, "Roof", Vector3(s * 14.75, 13.0, 0), 9.5, 76.0, 1.6)
		for z in [-33.25, -23.75, -14.25, -4.75, 14.25, 23.75, 33.25]:
			LandmarkIbParts.buttress(lm, "Granite", Vector3(s * 19.5, 0, z), sn, 1.4, 1.4, 12.0)
			if z < 30.0:
				LandmarkDetail.window(lm, "Granite", "Glass", Vector3(s * 19.5, 6.5, z + 4.75), sn, 1.6, 4.0, true)
				LandmarkDetail.window(lm, "Granite", "Glass", Vector3(s * 10.0, 17.0, z + 4.75), sn, 1.4, 3.0, true)
		LandmarkIbParts.band(lm, "Granite", Vector3(s * 19.5, 0, 0), Vector3(0, 0, 1), sn, 76.0, 12.6, 0.6, 0.4)
		LandmarkIbParts.band(lm, "Granite", Vector3(s * 10.0, 0, 0), Vector3(0, 0, 1), sn, 80.0, 20.6, 0.8, 0.5)
	lm.box("Granite", Vector3(0, 10.5, 5.0), Vector3(62.0, 21.0, 18.0))
	lm.gable("Roof", Vector3(0, 21.0, 5.0), 18.0, 62.0, 4.5, Basis(Vector3.UP, PI * 0.5), 0.5)
	for s in [-1.0, 1.0]:
		var en := Vector3(s, 0, 0)
		var ef := Vector3(s * 31.0, 0, 5.0)
		var er := Vector3.UP.cross(en)
		lm.gable("Granite", ef + Vector3(0, 21.0, 0), 18.0, 0.8, 4.5, Basis(Vector3.UP, PI * 0.5), 0.0, "Granite")
		for z in [-2.6, 2.6]:
			LandmarkIbParts.portal(lm, "Granite", "Shadow", ef + Vector3(0, 0.3, z), er, en, 3.6, 7.0, 1, 0.8)
		LandmarkIbParts.band(lm, "Granite", ef, er, en, 14.0, 8.2, 0.8, 0.9)
		for z in [-6.0, 6.0]:
			LandmarkIbParts.buttress(lm, "Granite", ef + Vector3(0, 0, z), en, 1.6, 1.4, 19.0)
		for z in [-2.6, 2.6]:
			LandmarkDetail.window(lm, "Granite", "Glass", ef + Vector3(0, 13.0, z), en, 2.0, 4.6, true)
		LandmarkIbParts.rail(lm, "Granite", ef + en * 0.4 + Vector3(0, 21.0, -8.0), ef + en * 0.4 + Vector3(0, 21.0, 8.0), 1.0, 4.0, true)
	# Crossing tower: octagonal drum with arched windows, balustrade and
	# pinnacles, stone cupola and cross.
	var cc := Vector3(0, 0, 5.0)
	lm.frustum("Granite", cc + Vector3(0, 21.0, 0), 7.8, 7.8, 13.0, 8, PI / 8.0)
	SEuUtil.ring_openings(lm, "Shadow", cc + Vector3(0, 21.0, 0), 7.8, 8, 8, 4.0, 1.8, 6.0, false, PI / 8.0)
	lm.frustum("Granite", cc + Vector3(0, 33.8, 0), 8.4, 8.4, 0.6, 8, PI / 8.0)
	for i in 8:
		var a := PI / 8.0 + TAU * float(i) / 8.0 + PI / 8.0
		var d := Vector3(cos(a), 0, sin(a))
		LandmarkIbParts.buttress(lm, "Granite", cc + Vector3(0, 21.0, 0) + d * 7.6, d, 0.9, 0.9, 12.8)
		LandmarkIbParts.urn(lm, "Granite", cc + d * 8.0 + Vector3(0, 34.4, 0), 1.6)
	lm.frustum("Roof", cc + Vector3(0, 34.4, 0), 7.6, 1.0, 8.6, 8, PI / 8.0)
	lm.frustum("Granite", cc + Vector3(0, 43.0, 0), 1.2, 1.0, 1.0, 8)
	LandmarkCeParts.cross(lm, "Gilt", cc + Vector3(0, 44.0, 0), 2.6)
	# Apse and radiating chapels (east end, -Z).
	lm.frustum("Granite", Vector3(0, 0, -36.0), 13.0, 13.0, 21.0, 10, PI / 10.0)
	lm.frustum("Roof", Vector3(0, 21.0, -36.0), 13.8, 0.6, 7.0, 10, PI / 10.0)
	for a in [-72.0, -36.0, 0.0, 36.0, 72.0]:
		var ang := deg_to_rad(a)
		var d := Vector3(sin(ang), 0, -cos(ang))
		var p := Vector3(0, 0, -36.0) + d * 14.8
		var b := Basis(Vector3.UP, -ang)
		lm.box("Granite", p + Vector3(0, 5.0, 0), Vector3(6.4, 10.0, 6.4), b)
		lm.frustum("Roof", p + Vector3(0, 10.0, 0), 4.2, 0.4, 3.6, 8, ang)
		LandmarkDetail.window(lm, "Granite", "Glass", p + d * 3.2 + Vector3(0, 5.0, 0), d, 1.2, 3.4, true)
		var m := deg_to_rad(a + 18.0)
		var dm := Vector3(sin(m), 0, -cos(m))
		LandmarkDetail.window(lm, "Granite", "Glass", Vector3(0, 0, -36.0) + dm * 12.4 + Vector3(0, 15.0, 0), dm, 1.4, 3.6, true)

## The Obradoiro front: the central body in two orders of columns with
## its great glazed windows, the stepped crown with obelisks and the
## statue of St James, and the double stair.
static func _obradoiro(lm: LandmarkMesh) -> void:
	var zn := Vector3(0, 0, 1)
	lm.box("Light", Vector3(0, 23.0, 42.5), Vector3(25.0, 46.0, 12.0))
	lm.box("Light", Vector3(0, 3.0, 42.5), Vector3(27.0, 6.0, 12.6))
	var steps := [[25.0, 46.0, 49.5], [19.0, 49.5, 52.5], [13.0, 52.5, 55.5], [8.0, 55.5, 58.0]]
	for st in steps:
		var w: float = st[0]
		var y0: float = st[1]
		var y1: float = st[2]
		lm.box("Light", Vector3(0, (y0 + y1) * 0.5, 44.5), Vector3(w, y1 - y0, 8.0))
		lm.box("Light", Vector3(0, y1 + 0.2, 44.6), Vector3(w + 0.8, 0.4, 8.4))
		for sx in [-1.0, 1.0]:
			var ob := Vector3(float(sx) * (w * 0.5 - 0.3), y1 + 0.4, 48.4)
			lm.box("Light", ob + Vector3(0, 0.4, 0), Vector3(0.9, 0.8, 0.9))
			lm.spire("Light", ob + Vector3(0, 0.8, 0), 0.32, 3.4, 0.05)
			lm.lathe("Light", ob + Vector3(0, 4.2, 0), SEuUtil.dome(0.25, 0.4, 3), 8)
	lm.box("Light", Vector3(0, 58.5, 44.5), Vector3(5.0, 1.0, 6.0))
	LandmarkIbParts.statue(lm, "Light", "Light", Vector3(0, 59.0, 45.5), 1.0, 3.6, true)
	for sx in [-1.0, 1.0]:
		LandmarkKits.statue_figure(lm, "Light", Vector3(float(sx) * 3.4, 55.5, 48.3), 2.2)
	for x in [-9.0, 9.0]:
		lm.spire("Light", Vector3(x, 46.0, 46.5), 0.9, 7.0, 0.0)
	# Two orders of engaged columns on pedestals.
	for x in [-11.0, -8.5, -4.0, 4.0, 8.5, 11.0]:
		var xx: float = x
		lm.box("Light", Vector3(xx, 7.0, 49.2), Vector3(1.8, 2.0, 1.8))
		LandmarkDetail.column(lm, "Light", Vector3(xx, 8.0, 49.2), 0.62, 11.2, "corinthian", 0)
		lm.box("Light", Vector3(xx, 20.4, 49.2), Vector3(1.6, 1.4, 1.6))
		LandmarkDetail.column(lm, "Light", Vector3(xx, 21.1, 49.2), 0.55, 10.6, "corinthian", 0)
	for cy in [19.6, 32.6, 45.6]:
		lm.box("Light", Vector3(0, cy, 49.0), Vector3(26.4, 0.9, 1.8))
		LandmarkDetail.cornice(lm, "Light", Vector3(-13.2, cy + 0.45, 49.9), Vector3(13.2, cy + 0.45, 49.9), zn, 0.7, false)
	# The great windows lighting the Portico de la Gloria, the doors.
	LandmarkDetail.window(lm, "Light", "Glass", Vector3(0, 26.0, 48.5), zn, 6.4, 11.0, true, 0.4)
	for x in [-6.2, 6.2]:
		LandmarkDetail.window(lm, "Light", "Glass", Vector3(x, 26.5, 48.5), zn, 2.2, 7.0, true)
		LandmarkDetail.window(lm, "Light", "Glass", Vector3(x, 38.5, 48.5), zn, 2.0, 5.0, false)
		LandmarkIbParts.portal(lm, "Light", "Shadow", Vector3(x, 6.0, 48.5), Vector3.RIGHT, zn, 2.6, 5.6, 1, 0.4)
		LandmarkKits.statue_figure(lm, "Light", Vector3(x, 20.3, 49.4), 2.0)
	LandmarkIbParts.portal(lm, "Light", "Shadow", Vector3(0, 6.0, 48.5), Vector3.RIGHT, zn, 4.2, 8.6, 1, 0.5)
	LandmarkDetail.window(lm, "Light", "Glass", Vector3(0, 39.5, 48.5), zn, 3.6, 8.0, true)
	# The double stair: a landing at the door, two flights down either
	# side, balustrades.
	lm.box("Steps", Vector3(0, 3.0, 51.5), Vector3(24.0, 6.0, 5.0))
	LandmarkIbParts.rail(lm, "Light", Vector3(-12.0, 6.0, 53.8), Vector3(12.0, 6.0, 53.8), 1.1, 6.0, true)
	for s in [-1.0, 1.0]:
		SEuUtil.steps_up(lm, "Steps", Vector3(float(s) * 12.0, 0, 52.0), Vector3(float(s), 0, 0), 4.0, 0.62, 0.3, 20)
		lm.beam("Light", Vector3(float(s) * 12.0, 7.0, 54.1), Vector3(float(s) * 24.4, 1.0, 54.1), 0.4, 0.5)
		lm.box("Light", Vector3(float(s) * 24.4, 0.75, 54.1), Vector3(0.9, 1.5, 0.9))
		lm.lathe("Light", Vector3(float(s) * 24.4, 1.5, 54.1), SEuUtil.dome(0.4, 0.5, 4), 8)

## A front tower (12.5 m square, 75 m): base with windows and corner
## pilasters, two belfry stages each with arched openings between
## columns, balustrades with obelisks, the stone cupola and lantern.
static func _front_tower(lm: LandmarkMesh, t: Vector3) -> void:
	lm.box("Light", t + Vector3(0, 16.0, 0), Vector3(12.5, 32.0, 12.5))
	lm.box("Light", t + Vector3(0, 32.5, 0), Vector3(13.5, 1.0, 13.5))
	lm.box("Light", t + Vector3(0, 40.0, 0), Vector3(11.4, 14.0, 11.4))
	lm.box("Light", t + Vector3(0, 47.6, 0), Vector3(12.6, 1.2, 12.6))
	lm.box("Light", t + Vector3(0, 53.0, 0), Vector3(8.8, 10.0, 8.8))
	lm.box("Light", t + Vector3(0, 58.3, 0), Vector3(10.0, 0.6, 10.0))
	for k in 4:
		var r2 := Basis(Vector3.UP, PI * 0.5 * float(k))
		var out := r2 * Vector3(0, 0, 1)
		var right := r2 * Vector3(1, 0, 0)
		LandmarkDetail.window(lm, "Light", "Glass", t + out * 6.25 + Vector3(0, 11.0, 0), out, 1.6, 4.0, true)
		LandmarkDetail.window(lm, "Light", "Glass", t + out * 6.25 + Vector3(0, 23.0, 0), out, 1.6, 4.0, true)
		LandmarkIbParts.pilaster_row(lm, "Light", t + out * 6.25, right, out, 2, 11.3, 1.0, 0.4, 6.0, 32.0)
		LandmarkIbParts.rail(lm, "Light", t + out * 6.4 - right * 6.4 + Vector3(0, 33.0, 0),
			t + out * 6.4 + right * 6.4 + Vector3(0, 33.0, 0), 1.0, 6.4)
		# First belfry: three arches between engaged columns.
		for i in 3:
			LandmarkIbParts.portal(lm, "Light", "Shadow", t + out * 5.7 + right * (float(i - 1) * 3.6) + Vector3(0, 34.0, 0),
				right, out, 1.8, 8.0, 1, 0.3)
		for i in 2:
			LandmarkIbParts.post(lm, "Light", t + out * 6.1 + right * ((float(i) - 0.5) * 3.6) + Vector3(0, 33.6, 0), 0.32, 13.2, 8)
		LandmarkIbParts.rail(lm, "Light", t + out * 6.0 - right * 5.9 + Vector3(0, 48.2, 0),
			t + out * 6.0 + right * 5.9 + Vector3(0, 48.2, 0), 1.0, 5.9)
		# Second belfry: one arch, columns at the corners.
		LandmarkIbParts.portal(lm, "Light", "Shadow", t + out * 4.4 + Vector3(0, 49.5, 0), right, out, 2.4, 6.6, 1, 0.3)
		LandmarkIbParts.post(lm, "Light", t + (out + right) * 4.55 + Vector3(0, 48.2, 0), 0.3, 9.8, 8)
		var cn := (out + right) * 5.9
		lm.box("Light", t + cn + Vector3(0, 48.8, 0), Vector3(0.9, 1.2, 0.9))
		lm.spire("Light", t + cn + Vector3(0, 49.4, 0), 0.4, 4.6, 0.06)
		lm.lathe("Light", t + cn + Vector3(0, 54.0, 0), SEuUtil.dome(0.3, 0.45, 3), 8)
		var cn2 := (out + right) * 4.8
		lm.spire("Light", t + cn2 + Vector3(0, 58.6, 0), 0.3, 3.2, 0.04)
	lm.lathe("Light", t + Vector3(0, 58.6, 0), PackedVector2Array([Vector2(4.6, 0), Vector2(4.9, 1.2),
		Vector2(4.2, 3.0), Vector2(3.0, 5.0), Vector2(2.0, 6.8), Vector2(1.5, 8.0), Vector2(1.0, 9.0),
		Vector2(0.0, 9.8)]), 8, 1.0, 1.0, PI / 8.0)
	for i in 8:
		var a := TAU * float(i) / 8.0
		lm.beam("Light", t + Vector3(cos(a) * 4.7, 59.4, sin(a) * 4.7), t + Vector3(cos(a) * 1.9, 66.0, sin(a) * 1.9), 0.4, 0.3)
	lm.frustum("Light", t + Vector3(0, 68.4, 0), 1.1, 0.9, 3.0, 8)
	SEuUtil.ring_openings(lm, "Shadow", t + Vector3(0, 68.4, 0), 1.0, 8, 4, 0.6, 0.6, 1.8, false)
	lm.frustum("Light", t + Vector3(0, 71.4, 0), 1.3, 0.2, 1.8, 8)
	LandmarkCeParts.cross(lm, "Gilt", t + Vector3(0, 73.2, 0), SAN_TOP - 73.2)

## The Berenguela clock tower: a plain Gothic square shaft, Andrade's
## baroque stages with the four clock dials, balustrades with pinnacles,
## an octagonal belfry, the lantern and the stepped crown to 75 m.
static func _berenguela(lm: LandmarkMesh, t: Vector3) -> void:
	lm.box("Granite", t + Vector3(0, 19.0, 0), Vector3(10.0, 38.0, 10.0))
	lm.box("Granite", t + Vector3(0, 38.4, 0), Vector3(11.4, 0.8, 11.4))
	lm.box("Granite", t + Vector3(0, 43.0, 0), Vector3(9.0, 8.4, 9.0))
	lm.box("Granite", t + Vector3(0, 47.6, 0), Vector3(10.2, 0.8, 10.2))
	for k in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * float(k))
		var out := r * Vector3(0, 0, 1)
		var right := r * Vector3(1, 0, 0)
		LandmarkDetail.window(lm, "Granite", "Glass", t + out * 5.0 + Vector3(0, 28.0, 0), out, 1.2, 3.2, true)
		lm.disc("Light", t + out * 4.55 + Vector3(0, 43.2, 0), out, 2.0, 24)
		lm.disc("Gilt", t + out * 4.58 + Vector3(0, 43.2, 0), out, 0.3, 8)
		LandmarkIbParts.rail(lm, "Granite", t + out * 5.4 - right * 5.4 + Vector3(0, 38.8, 0),
			t + out * 5.4 + right * 5.4 + Vector3(0, 38.8, 0), 1.0, 5.4)
		LandmarkCeParts.pinnacle(lm, "Granite", t + (out + right) * 5.1 + Vector3(0, 38.8, 0), 0.8, 4.4)
		LandmarkCeParts.pinnacle(lm, "Granite", t + (out + right) * 4.6 + Vector3(0, 48.0, 0), 0.7, 3.8)
	lm.frustum("Granite", t + Vector3(0, 48.0, 0), 4.0, 3.8, 9.0, 8, PI / 8.0)
	SEuUtil.ring_openings(lm, "Shadow", t + Vector3(0, 48.0, 0), 3.9, 8, 8, 1.5, 1.4, 5.6, false, PI / 8.0)
	lm.frustum("Granite", t + Vector3(0, 57.0, 0), 4.4, 4.4, 0.6, 8, PI / 8.0)
	lm.frustum("Granite", t + Vector3(0, 57.6, 0), 3.2, 3.0, 4.0, 8, PI / 8.0)
	lm.frustum("Granite", t + Vector3(0, 61.6, 0), 3.4, 3.4, 0.4, 8, PI / 8.0)
	lm.lathe("Granite", t + Vector3(0, 62.0, 0), PackedVector2Array([Vector2(3.0, 0), Vector2(2.6, 2.2),
		Vector2(1.6, 4.4), Vector2(1.0, 5.4), Vector2(0.8, 7.0), Vector2(0.0, 9.6)]), 8, 1.0, 1.0, PI / 8.0, false)
	lm.lathe("Granite", t + Vector3(0, 71.6, 0), SEuUtil.dome(0.6, 0.8, 4), 8)
	LandmarkCeParts.cross(lm, "Gilt", t + Vector3(0, 72.4, 0), SAN_TOP - 72.4)

## The Renaissance cloister south of the nave: ranges round a court
## with arcades of round arches on its inner faces and a balustrade, the
## stepped pyramid of the Treasury tower at the south-east corner.
static func _cloister(lm: LandmarkMesh, c: Vector3) -> void:
	LandmarkIbUtil.ring_walls(lm, "Granite", c, 19.0, 19.0, 8.0, 0.0, 13.0)
	for k in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * float(k))
		var out := r * Vector3(0, 0, 1)
		var right := r * Vector3(1, 0, 0)
		var inner := c + out * 11.0
		for i in 6:
			var s := (float(i) - 2.5) * 3.6
			LandmarkIbParts.post(lm, "Granite", inner - out * 0.6 + right * (s - 1.8), 0.35, 5.2, 8)
			LandmarkIbParts.arch_ring(lm, "Granite", inner - out * 0.6 + right * s + Vector3(0, 5.2, 0), -out, 2.8, 0.4, 0.6, 7)
		LandmarkIbParts.rail(lm, "Granite", inner - out * 0.4 - right * 10.5 + Vector3(0, 13.0, 0),
			inner - out * 0.4 + right * 10.5 + Vector3(0, 13.0, 0), 1.0, 3.6, true)
		SEuUtil.face_row(lm, "Shadow", inner, right, -out, 8.0, 5, 4.0, 1.4, 3.0)
		LandmarkIbParts.window_row(lm, "Granite", "Glass", c + out * 19.0, right, out, 5.0, 5, 6.8, 1.4, 3.6)
		LandmarkIbParts.window_row(lm, "Granite", "Glass", c + out * 19.0, right, out, 10.0, 5, 6.8, 1.2, 2.4)
	var tt := c + Vector3(15.0, 0, -15.0)
	lm.box("Granite", tt + Vector3(0, 9.0, 0), Vector3(8.0, 18.0, 8.0))
	for j in 5:
		var w := 8.4 - 1.3 * float(j)
		lm.box("Granite", tt + Vector3(0, 18.4 + 1.6 * float(j), 0), Vector3(w, 0.8, w))
		lm.spire("Roof", tt + Vector3(0, 18.8 + 1.6 * float(j), 0), w * 0.5 - 0.2, 0.8, w * 0.5 - 0.65)
	lm.frustum("Granite", tt + Vector3(0, 26.8, 0), 0.6, 0.5, 1.4, 8)
