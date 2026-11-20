class_name StoDjurgAbba
extends RefCounted

## ABBA The Museum (Pop House, 2013) at Djurgårdsvägen 68. Origin at the
## centroid of OSM way 33275424 (38.9 x 38.1 m, bearing 156.8), +X along
## the 156.8 axis (registry yaw 66.8). Outline from the OSM polygon, listed
## below in this frame.
##
## Spec (visual-plan/refs/landmarks/abba_museum/; OSM tags: wood, sandybrown,
## three levels, flat grass roof, two basement levels; the brief's "1900s
## brick tram depot" is not what stands there):
## - A three-storey block clad in ochre timber panels on a recessed glazed
##   ground floor: steel-framed glass between slim posts every 3.3 m, a
##   dark glass entrance bay, a dark lettering board over the door.
## - Upper floors: ribbon windows (2.2 x 2.4 m) every 3.3 m between wide
##   ochre timber piers, a continuous dark steel balcony rail along each
##   floor level, a wide timber fascia band between the storeys.
## - Flat green roof behind a low timber parapet; four silver boots stand on
##   the roof corner (the museum's roof sculpture).
## Height: 3 storeys derived at 4 m (12 m) plus the 0.8 m boots: unverified.

const POLY := [Vector2(20.1, -17.1), Vector2(20.2, -0.5), Vector2(14.6, -0.5), Vector2(14.5, 17.1),
	Vector2(1.2, 17.2), Vector2(1.1, 21.3), Vector2(-14.3, 21.3), Vector2(-14.6, 2.6),
	Vector2(-18.5, 2.5), Vector2(-18.4, -16.7)]
const WALL := 11.4
const TOP := 12.8

static func build(model: Node3D) -> void:
	var mats := {
		"Timber": LandmarkMaterials.pbr("wood", "#C99B57", 1.8, 0.7),
		"Fascia": LandmarkMaterials.pbr("wood", "#B88541", 1.8, 0.7),
		"Frame": LandmarkMaterials.paint("#3C3D3F"),
		"Glass": LandmarkMaterials.glass("#5A6B73"),
		"Rail": LandmarkMaterials.paint("#2F3133", 0.5, 0.5),
		"Roof": LandmarkMaterials.pbr("grass", "#5B7545", 3.0),
		"Boot": LandmarkMaterials.paint("#D6D9DC", 0.3, 0.8),
	}
	var lm := LandmarkMesh.new()
	StoChurchKit.use_all(lm, mats)
	var poly := PackedVector2Array(POLY)
	lm.poly_prism("Timber", poly, 0.0, WALL)
	lm.poly_prism("Roof", poly, WALL, WALL + 0.15)
	var win := StoDjurgKit.unit(mats, 2.2, 2.4, false, 0.18)
	var shop := StoDjurgKit.unit(mats, 2.6, 3.4, false, 0.2)
	var area := 0.0
	for i in POLY.size():
		var p: Vector2 = POLY[i]
		var q: Vector2 = POLY[(i + 1) % POLY.size()]
		area += p.x * q.y - q.x * p.y
	for i in POLY.size():
		var p: Vector2 = POLY[i]
		var q: Vector2 = POLY[(i + 1) % POLY.size()]
		var d := q - p
		var out2 := Vector2(d.y, -d.x).normalized() * (1.0 if area > 0.0 else -1.0)
		_edge(lm, win, shop, Vector3(p.x, 0, p.y), Vector3(q.x, 0, q.y), Vector3(out2.x, 0, out2.y))
	_boots(lm)
	lm.commit(model)

static func _edge(lm: LandmarkMesh, win: LandmarkMesh, shop: LandmarkMesh, a: Vector3, b: Vector3, out: Vector3) -> void:
	var len := a.distance_to(b)
	var dir := (b - a) / len
	var basis := Basis(dir, Vector3.UP, out)
	# Parapet and the fascia bands between the storeys.
	lm.box("Fascia", a.lerp(b, 0.5) + out * 0.12 + Vector3(0, WALL - 0.3, 0), Vector3(len, 0.9, 0.3), basis, 0.0)
	lm.box("Fascia", a.lerp(b, 0.5) + out * 0.1 + Vector3(0, 4.0, 0), Vector3(len, 0.7, 0.22), basis, 0.0)
	lm.box("Fascia", a.lerp(b, 0.5) + out * 0.1 + Vector3(0, 7.7, 0), Vector3(len, 0.6, 0.22), basis, 0.0)
	if len < 4.5:
		return
	var n := maxi(int((len - 1.0) / 3.3), 1)
	var a2 := a + dir * 0.5
	var b2 := b - dir * 0.5
	StoDjurgKit.row(lm, shop, a2, b2, out, 0.35, n)
	StoDjurgKit.row(lm, win, a2, b2, out, 4.9, n)
	StoDjurgKit.row(lm, win, a2, b2, out, 8.5, n)
	# Balcony rails along the two upper floors.
	for y in [4.3, 8.0]:
		var pa := a + out * 0.55 + Vector3(0, y, 0)
		var pb := b + out * 0.55 + Vector3(0, y, 0)
		lm.beam("Rail", pa + Vector3(0, 1.0, 0), pb + Vector3(0, 1.0, 0), 0.06, 0.06)
		lm.beam("Rail", pa + Vector3(0, 0.5, 0), pb + Vector3(0, 0.5, 0), 0.04, 0.04)
		var posts := maxi(int(len / 1.6), 1)
		for k in posts + 1:
			var p := pa.lerp(pb, float(k) / float(posts))
			lm.box("Rail", p + Vector3(0, 0.5, 0), Vector3(0.05, 1.0, 0.05), basis, 0.0)

## The silver boots on the roof corner.
static func _boots(lm: LandmarkMesh) -> void:
	for i in 4:
		var x := 15.5 + float(i) * 0.9
		lm.box("Boot", Vector3(x, WALL + 0.55, -15.0), Vector3(0.38, 0.8, 0.55), Basis(), 0.0)
		lm.box("Boot", Vector3(x, WALL + 0.2, -15.15), Vector3(0.38, 0.3, 0.8), Basis(), 0.0)
		lm.box("Boot", Vector3(x, WALL + 1.0, -15.0), Vector3(0.34, 0.8, 0.34), Basis(), 0.0)
