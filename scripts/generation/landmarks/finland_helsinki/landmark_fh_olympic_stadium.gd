extends RefCounted

## Helsinki Olympic Stadium (Lindegren and Jäntti, 1938; renewed 2016-20), origin
## at the registry point, yaw 0 (the long axis runs north-south, +Z south).
##
## Measured: the 22-point outline of the outer wall is the OSM footprint
## (178 x 243 m); the tower stands at (-67.05, 74.3) on the south-west
## end of the west side and is 72.71 m (the length of Matti Järvinen's 1932
## javelin record; LoD2 reads 73.4 m); the south gate (Eteläportti) at
## (6, 150) and the row of five flagpoles on the south-west approach are
## OSM nodes. Estimates: the 22 m wall height, the storey split, the
## stand depths (45 m along the long sides, 30 m at the ends), the roof
## pitch and the Nurmi statue position (about 12 m south of the south front).
##
## From the photographs (visual-plan/refs/landmarks/helsinki_olympic_stadium/):
## - The ground storey is an open arcade of white concrete piers with the
##   dark concourse behind, under a projecting white band.
## - Above it the curved wall of the south-east, east and north ends is
##   clad in dark brown panels (renewal of 2016-20) with vertical joints;
##   the west side and the south-west main front stay white with two
##   ribbon-window bands, as in 1938.
## - The roof over the stands is a thin white-edged ring with a dark
##   underside, a ring of thin white masts and floodlights on the rim.
## - The tower is a white slab with a glazed stair slit up one end, a
##   lookout band under a wider cap and a mast.
##
## Paavo Nurmi's bronze (Wäinö Aaltonen) stands before the south front.

const FhP = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_parts.gd")

const ENTRY := {"type": "helsinki_olympic_stadium", "skyline": true, "name": "Helsinki Olympic Stadium", "lat": 60.18700, "lon": 24.92725,
	"radius_m": 5500.0, "wiki_title": "Helsinki Olympic Stadium", "height_m": 72.71, "clear_m": 135.0,
	"kind": "Stadium", "aliases": ["helsinki olympic stadium", "helsingin olympiastadion",
		"olympiastadion helsinki", "helsingfors olympiastadion"]}

const FOOT := [Vector2(-68.7, 78.4), Vector2(-88.6, -35.0), Vector2(-86.0, -68.8),
	Vector2(-75.7, -89.0), Vector2(-50.5, -110.8), Vector2(-18.6, -120.7), Vector2(10.4, -119.4),
	Vector2(27.1, -113.9), Vector2(38.7, -108.2), Vector2(52.4, -94.8), Vector2(64.5, -80.4),
	Vector2(70.4, -61.2), Vector2(89.4, 44.7), Vector2(86.2, 71.2), Vector2(72.9, 93.6),
	Vector2(45.0, 114.6), Vector2(23.6, 121.2), Vector2(0.8, 122.2), Vector2(-20.0, 118.0),
	Vector2(-39.5, 107.5), Vector2(-54.6, 91.8), Vector2(-58.6, 76.6)]
const TOWER := Vector2(-67.05, 74.3)
const WALL_H := 21.0
const STOREY := 9.0
const FLAGS := [Vector2(-50.5, 148.4), Vector2(-53.5, 133.2), Vector2(-56.5, 118.3), Vector2(-59.3, 103.1),
	Vector2(-62.0, 89.3)]

## The outline scaled toward the centre: x by s, z by a gentler factor, since
## the ends of the bowl are shallower than the long sides.
static func _sc(p: Vector2, s: float) -> Vector2:
	return Vector2(p.x * s, p.y * (1.0 - (1.0 - s) * 0.46))

## Outer wall edge i is clad in brown panels: the south-east curve, the east
## side and the north end; the west side and the south-west front stay white.
static func _brown(a: Vector2, b: Vector2) -> bool:
	var m := (a + b) * 0.5
	return not (m.x < -45.0 and m.y > -60.0) and not (m.y > 60.0 and m.x < -20.0)

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("limestone", "#ECE8DC", 4.0))
	lm.use("Brown", LandmarkMaterials.pbr("concrete", "#5E4030", 3.0, 0.55, 0.15))
	lm.use("Dark", LandmarkMaterials.pbr("concrete", "#3A3A3C", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("concrete", "#C9CCCC", 3.0, 0.5, 0.3))
	lm.use("Seat", LandmarkMaterials.pbr("concrete", "#56606B", 3.0))
	lm.use("Pitch", LandmarkMaterials.pbr("grass", "#5E8A44", 5.0))
	lm.use("Track", LandmarkMaterials.pbr("concrete", "#9A4A3A", 3.0))
	lm.use("Glass", LandmarkMaterials.glass("#2A3236"))
	lm.use("Steel", LandmarkMaterials.paint("#E4E6E6", 0.5, 0.4))
	lm.use("Bronze", LandmarkMaterials.pbr("concrete", "#5C4A30", 2.0, 0.4, 0.6))
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#8A8782", 3.0))
	lm.use("Lamp", LandmarkMaterials.lit("#FFF4D8", 1.6))
	var n := FOOT.size()
	var foot := PackedVector2Array(FOOT)
	lm.poly_prism("Dark", foot, 0.0, WALL_H, false)
	for i in n:
		_wall_edge(lm, foot, i)
		_stand(lm, foot, i)
	var rim := PackedVector2Array()
	for p in FOOT:
		rim.append(_sc(p, 0.46))
	# Track, pitch (about 68 x 105 m) and the pit between the seats.
	lm.poly_prism("Track", rim, 0.0, 1.2)
	var pitch := PackedVector2Array()
	for p in rim:
		pitch.append(Vector2(p.x * 0.74, p.y * 0.62))
	lm.poly_prism("Pitch", pitch, 1.2, 1.25)
	_roof(lm, foot)
	_tower(lm)
	_site(lm)
	lm.commit(model)

## One edge of the outer wall: the arcade and its band, then brown panels
## or white ribbon windows up to the parapet.
static func _wall_edge(lm: LandmarkMesh, foot: PackedVector2Array, i: int) -> void:
	var n := foot.size()
	var a := foot[i]
	var b := foot[(i + 1) % n]
	var out := FhP.edge_out(foot, i)
	var a3 := Vector3(a.x, 0, a.y)
	var b3 := Vector3(b.x, 0, b.y)
	# Arcade: piers 0.9 m wide every 5 m, dark concourse behind them.
	FhP.ribs(lm, "Wall", a3, b3, out, 0.0, STOREY, 5.0, 0.9, 0.7)
	FhP.band(lm, "Wall", a3, b3, out, STOREY - 0.2, 1.4, 0.9)
	var a_up := a3 + Vector3(0, STOREY + 1.2, 0) + out * 0.45
	var b_up := b3 + Vector3(0, STOREY + 1.2, 0) + out * 0.45
	var h := WALL_H - STOREY - 1.2
	if _brown(a, b):
		lm.quad("Brown", a_up, b_up, b_up + Vector3(0, h, 0), a_up + Vector3(0, h, 0), out)
		FhP.ribs(lm, "Dark", a_up, b_up, out, STOREY + 1.2, WALL_H, 6.0, 0.14, 0.1)
	else:
		lm.quad("Wall", a_up, b_up, b_up + Vector3(0, h, 0), a_up + Vector3(0, h, 0), out)
		for y in [STOREY + 2.4, STOREY + 7.0]:
			lm.quad("Glass", a_up + Vector3(0, y - STOREY - 1.2, 0) + out * 0.04, b_up + Vector3(0, y - STOREY - 1.2, 0) + out * 0.04,
				b_up + Vector3(0, y - STOREY + 0.4, 0) + out * 0.04, a_up + Vector3(0, y - STOREY + 0.4, 0) + out * 0.04, out)
			FhP.ribs(lm, "Wall", a_up + Vector3(0, y - STOREY - 1.2, 0), b_up + Vector3(0, y - STOREY - 1.2, 0), out, y - 0.0,
				y + 1.6, 2.4, 0.3, 0.1)
	FhP.band(lm, "Wall", a3, b3, out, WALL_H - 0.3, 1.0, 0.6)
	# Flagpole-thin mast and floodlight on the rim every 9 m.
	var steps := maxi(int(a.distance_to(b) / 6.5), 1)
	for k in steps:
		var p := a3.lerp(b3, (float(k) + 0.5) / float(steps)) + out * 0.3 + Vector3(0, WALL_H + 0.7, 0)
		lm.beam("Steel", p, p + Vector3(0, 6.0, 0), 0.14)
		lm.box("Lamp", p + Vector3(0, 6.1, 0) - out * 0.3, Vector3(0.7, 0.35, 0.35), Basis(Vector3.UP, atan2(out.x, out.z)))

## Tiered seating: stepped rows from the rim of the roof down to the track.
static func _stand(lm: LandmarkMesh, foot: PackedVector2Array, i: int) -> void:
	var n := foot.size()
	var a := foot[i]
	var b := foot[(i + 1) % n]
	var rows := 8
	for k in rows:
		var t0 := float(k) / float(rows)
		var t1 := float(k + 1) / float(rows)
		var s0 := lerpf(0.66, 0.46, t0)
		var s1 := lerpf(0.66, 0.46, t1)
		var y0 := lerpf(WALL_H - 3.0, 1.2, t0)
		var y1 := lerpf(WALL_H - 3.0, 1.2, t1)
		var p0 := _sc(a, s0)
		var p1 := _sc(b, s0)
		var r0 := _sc(a, s1)
		var r1 := _sc(b, s1)
		var mid := (r0 + r1) * 0.5
		lm.quad("Seat", Vector3(p0.x, y0, p0.y), Vector3(p1.x, y0, p1.y), Vector3(r1.x, y0, r1.y), Vector3(r0.x, y0, r0.y),
			Vector3.UP)
		lm.quad("Seat", Vector3(r0.x, y0, r0.y), Vector3(r1.x, y0, r1.y), Vector3(r1.x, y1, r1.y), Vector3(r0.x, y1, r0.y),
			-Vector3(mid.x, 0, mid.y).normalized())

## The roof ring over the stands: a sloping white plate with a dark underside
## and a white fascia, rising a little toward the pitch.
static func _roof(lm: LandmarkMesh, foot: PackedVector2Array) -> void:
	var n := foot.size()
	var y0 := WALL_H + 0.8
	var y1 := WALL_H + 4.2
	for i in n:
		var a := foot[i]
		var b := foot[(i + 1) % n]
		var qa := _sc(a, 0.62)
		var qb := _sc(b, 0.62)
		var mid := (qa + qb) * 0.5
		var d := Vector3(mid.x, 0, mid.y).normalized()
		lm.quad("Roof", Vector3(a.x, y0, a.y), Vector3(b.x, y0, b.y), Vector3(qb.x, y1, qb.y), Vector3(qa.x, y1, qa.y),
			Vector3.UP)
		lm.quad("Dark", Vector3(a.x, y0 - 0.3, a.y), Vector3(qa.x, y1 - 0.5, qa.y), Vector3(qb.x, y1 - 0.5, qb.y),
			Vector3(b.x, y0 - 0.3, b.y), Vector3.DOWN)
		lm.quad("Wall", Vector3(qa.x, y1, qa.y), Vector3(qb.x, y1, qb.y), Vector3(qb.x, y1 - 0.9, qb.y),
			Vector3(qa.x, y1 - 0.9, qa.y), -d)
		# Struts down to the wall every second edge.
		lm.beam("Steel", Vector3(qa.x, y1 - 0.9, qa.y), Vector3(a.x * 0.7, WALL_H - 3.0, a.y * 0.7), 0.35)

## The 72.71 m tower: slab shaft with a glazed stair slit up one end, the
## lookout band, the cap and the mast.
static func _tower(lm: LandmarkMesh) -> void:
	var t := TOWER
	var tb := Basis(Vector3.UP, -0.17)
	var c := Vector3(t.x, 0, t.y)
	lm.box("Wall", c + Vector3(0, 33.0, 0), Vector3(6.5, 66.0, 8.7), tb)
	for s in [-1.0, 1.0]:
		lm.box("Wall", c + tb * Vector3(s * 3.4, 33.0, 0), Vector3(0.6, 66.0, 9.2), tb)
	# Glazed stair slit along the east end of the south face and a narrow one
	# on the north face, with a floor line every 3.1 m.
	lm.box("Glass", c + tb * Vector3(2.0, 33.0, 4.4), Vector3(1.3, 62.0, 0.1), tb, 0.0)
	lm.box("Glass", c + tb * Vector3(-2.0, 33.0, -4.4), Vector3(1.3, 62.0, 0.1), tb, 0.0)
	for k in 19:
		for s in [-1.0, 1.0]:
			lm.box("Wall", c + tb * Vector3(2.0 * s, 4.5 + 3.1 * float(k), 4.4 * s), Vector3(1.4, 0.2, 0.14), tb, 0.0)
	# Top: a cantilevered ledge under a dark lookout window, the railing cage
	# round the roof terrace, and the dark steel mast on its white cone.
	lm.box("Wall", c + tb * Vector3(2.0, 59.2, 5.0), Vector3(6.0, 1.2, 2.2), tb)
	lm.box("Glass", c + tb * Vector3(2.0, 61.2, 4.45), Vector3(5.6, 2.8, 0.1), tb, 0.0)
	lm.box("Wall", c + Vector3(0, 66.2, 0), Vector3(7.0, 0.5, 9.2), tb)
	for k in 5:
		for s in [-1.0, 1.0]:
			lm.box("Steel", c + tb * Vector3(0, 66.7 + 0.7 * float(k), 4.4 * s), Vector3(7.0, 0.08, 0.08), tb, 0.0)
			lm.box("Steel", c + tb * Vector3(3.4 * s, 66.7 + 0.7 * float(k), 0), Vector3(0.08, 0.08, 9.0), tb, 0.0)
	for k in 7:
		for s in [-1.0, 1.0]:
			lm.box("Steel", c + tb * Vector3(-3.4 + 1.13 * float(k), 68.0, 4.4 * s), Vector3(0.08, 3.0, 0.08), tb, 0.0)
	lm.frustum("Wall", c + Vector3(0, 66.6, 0), 1.1, 0.4, 1.8, 8)
	lm.frustum("Dark", c + Vector3(0, 68.2, 0), 0.38, 0.07, 4.51, 6)
	lm.box("Lamp", c + Vector3(0, 66.35, 0), Vector3(7.1, 0.12, 9.3), tb)

## Flagpoles on the south-west approach and Nurmi's statue before the south front.
static func _site(lm: LandmarkMesh) -> void:
	for f in FLAGS:
		lm.beam("Steel", Vector3(f.x, 0.0, f.y), Vector3(f.x, 14.0, f.y), 0.18)
	var p := Vector3(10.0, 0.0, 134.0)
	lm.box("Granite", p + Vector3(0, 0.7, 0), Vector3(1.6, 1.4, 1.6))
	lm.frustum("Bronze", p + Vector3(-0.25, 1.4, 0), 0.2, 0.15, 1.0, 8)
	lm.frustum("Bronze", p + Vector3(0.25, 1.4, 0.2), 0.18, 0.12, 0.9, 8)
	lm.box("Bronze", p + Vector3(0, 2.15, 0.05), Vector3(0.6, 0.9, 0.35))
	lm.lathe("Bronze", p + Vector3(0, 2.6, 0.1), PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.14, 0.05),
		Vector2(0.17, 0.22), Vector2(0.0, 0.34)]), 10)
