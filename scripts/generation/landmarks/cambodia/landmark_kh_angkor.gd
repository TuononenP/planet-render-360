class_name LandmarkKhAngkor
extends RefCounted

## Angkor Thom and Ta Prohm in true metres: the Bayon's cluster of face
## towers, the South Gate with its naga causeway, and the galleries and
## gopuras of Ta Prohm among the silk-cotton roots.

const U = preload("res://scripts/generation/landmarks/cambodia/landmark_kh_util.gd")

## Bayon (43 m): three levels of gallery, the outer one with its gopuras, the
## raised inner one and the circular upper terrace, carrying 37 face towers
## round the tall central sanctuary tower. Built facing +X (east).
static func bayon(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#76705F", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("stone", "#5C574C", 3.0))
	lm.use("Dark", LandmarkMaterials.pbr("concrete", "#26231F", 2.0))
	# Outer gallery: wall ranges 4.5 m high with a flat stone roof.
	_gallery(lm, 0.0, 78.0, 70.0, 4.0, 5.0)
	# Inner gallery on a raised platform, and the upper terrace above it.
	lm.box("Stone", Vector3(0, 3.0, 0), Vector3(84.0, 6.0, 74.0))
	_gallery(lm, 6.0, 40.0, 35.0, 4.0, 5.0)
	lm.box("Stone", Vector3(0, 6.5, 0), Vector3(76.0, 1.0, 66.0))
	lm.frustum("Stone", Vector3(0, 7.0, 0), 30.0, 27.0, 8.0, 28)
	lm.frustum("Roof", Vector3(0, 15.0, 0), 27.6, 27.6, 0.5, 28)
	# Axial stairs up from the east and west gopuras.
	for s in [-1.0, 1.0]:
		var b := Basis(Vector3.UP, PI * 0.5 * s)
		U.stair(lm, "Stone", b * Vector3(0, 0.0, 42.0), b, 9.0, 8, 0.6, 0.75)
	# Face towers: outer gallery roof (5 m), inner (11 m), terrace (15.5 m).
	for sx in [-1.0, 0.0, 1.0]:
		for sz in [-1.0, 0.0, 1.0]:
			if sx != 0.0 or sz != 0.0:
				U.face_tower(lm, "Stone", "Dark", Vector3(sx * 78.0, 5.0, sz * 70.0), 4.2, 12.0)
	for sx in [-1.0, 0.0, 1.0]:
		for sz in [-1.0, 0.0, 1.0]:
			if sx != 0.0 or sz != 0.0:
				U.face_tower(lm, "Stone", "Dark", Vector3(sx * 40.0, 11.0, sz * 35.0), 4.6, 15.0)
	for i in 4:
		var x := -26.0 + 17.3 * float(i)
		for sz in [-1.0, 1.0]:
			U.face_tower(lm, "Stone", "Dark", Vector3(x, 11.0, sz * 35.0), 4.4, 14.0)
	for i in 12:
		var a := TAU * (float(i) + 0.5) / 12.0
		var ring := Vector3(cos(a) * 21.5, 15.5, sin(a) * 21.5)
		U.face_tower(lm, "Stone", "Dark", ring, 4.8, 15.0)
	# Central sanctuary: a round tower of ringed storeys under a lotus top.
	var prof := PackedVector2Array([Vector2(10.5, 0), Vector2(10.5, 2.0), Vector2(9.6, 2.4),
		Vector2(9.6, 8.0), Vector2(10.3, 8.4), Vector2(10.3, 9.8), Vector2(8.8, 10.2),
		Vector2(8.8, 15.0), Vector2(9.4, 15.4), Vector2(9.4, 16.6), Vector2(7.6, 17.2),
		Vector2(7.4, 21.0), Vector2(7.8, 21.4), Vector2(6.0, 23.5), Vector2(4.2, 25.0),
		Vector2(2.2, 27.0), Vector2(0.0, 28.0)])
	lm.lathe("Stone", Vector3(0, 15.5 - 0.5, 0), prof, 24)
	for i in 8:
		var a := TAU * float(i) / 8.0
		lm.box("Dark", Vector3(cos(a) * 9.7, 20.0, sin(a) * 9.7), Vector3(2.4, 4.2, 0.3),
			Basis(Vector3.UP, PI * 0.5 - a))
	lm.commit(model)

## Rectangular gallery of four roofed ranges round (0,0): wall ranges of
## height `h` and thickness `t` with dark window bands, floor at `y`.
static func _gallery(lm: LandmarkMesh, y: float, hx: float, hz: float, t: float, h: float) -> void:
	for s in [-1.0, 1.0]:
		lm.box("Stone", Vector3(0, y + h * 0.5, s * (hz - t * 0.5)), Vector3(hx * 2.0, h, t))
		lm.box("Roof", Vector3(0, y + h + 0.3, s * (hz - t * 0.5)), Vector3(hx * 2.0 + 0.8, 0.6, t + 0.8))
		lm.box("Stone", Vector3(s * (hx - t * 0.5), y + h * 0.5, 0), Vector3(t, h, hz * 2.0 - t * 2.0))
		lm.box("Roof", Vector3(s * (hx - t * 0.5), y + h + 0.3, 0), Vector3(t + 0.8, 0.6, hz * 2.0 - t * 2.0))
		var nx := int(hx / 5.0)
		for i in nx:
			var x := -hx + 2.5 + (hx * 2.0 - 5.0) * float(i) / float(nx - 1)
			lm.box("Dark", Vector3(x, y + h * 0.55, s * (hz + 0.02)), Vector3(2.0, h * 0.5, 0.12))
		var nz := int(hz / 5.0)
		for i in nz:
			var z := -hz + 2.5 + (hz * 2.0 - 5.0) * float(i) / float(nz - 1)
			lm.box("Dark", Vector3(s * (hx + 0.02), y + h * 0.55, z), Vector3(0.12, h * 0.5, 2.0))

## South Gate of Angkor Thom (23 m): the 8 m laterite city wall pierced by
## the gate, three-towered (central four-faced tower), elephant trunks
## beside the passage, and the 100 m causeway lined with 54 devas on one
## side and 54 asuras on the other holding the naga balustrade, its
## seven-headed fans toward the moat's far bank. Gate faces +Z (south).
static func south_gate(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Laterite", LandmarkMaterials.pbr("stone", "#7E5A44", 3.0))
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#7D7767", 3.0))
	lm.use("Dark", LandmarkMaterials.pbr("concrete", "#22201C", 2.0))
	lm.use("Naga", LandmarkMaterials.pbr("stone", "#6C675A", 3.0))
	# City wall and the gate block.
	U.wall_run(lm, "Laterite", "Stone", Vector3(-72.0, 0, 0), Vector3(-9.0, 0, 0), 8.0, 7.0, 0.3)
	U.wall_run(lm, "Laterite", "Stone", Vector3(9.0, 0, 0), Vector3(72.0, 0, 0), 8.0, 7.0, 0.3)
	for sx in [-1.0, 1.0]:
		lm.box("Stone", Vector3(sx * 5.4, 4.25, 0), Vector3(7.2, 8.5, 9.0))
	lm.box("Stone", Vector3(0, 7.4, 0), Vector3(3.6, 2.2, 9.0))
	lm.box("Dark", Vector3(0, 3.2, 4.45), Vector3(3.2, 6.4, 0.2))
	lm.box("Dark", Vector3(0, 3.2, -4.45), Vector3(3.2, 6.4, 0.2))
	lm.box("Stone", Vector3(0, 8.7, 0), Vector3(19.0, 0.5, 9.8))
	# Three-headed elephants beside the passage: trunks to the ground.
	for sx in [-1.0, 1.0]:
		for k in 3:
			var x: float = sx * (4.2 + 1.7 * float(k))
			lm.beam("Naga", Vector3(x, 7.4, 4.7), Vector3(x, 0.4, 5.3), 0.8, 0.8)
			lm.box("Naga", Vector3(x, 7.6, 4.9), Vector3(1.4, 1.4, 0.8))
	# Central four-faced tower and the two lower flanking towers.
	U.face_tower(lm, "Stone", "Dark", Vector3(0, 8.7, 0), 6.0, 14.3)
	for sx in [-1.0, 1.0]:
		U.face_tower(lm, "Stone", "Dark", Vector3(sx * 7.4, 8.7, 0), 3.4, 8.0)
	# Causeway over the moat with the deva and asura balustrades.
	var z0 := 4.6
	var clen := 96.0
	lm.box("Laterite", Vector3(0, -2.0, z0 + clen * 0.5), Vector3(11.0, 4.8, clen))
	for sx in [-1.0, 1.0]:
		var x: float = sx * 5.0
		lm.beam("Naga", Vector3(x, 1.5, z0 + 1.0), Vector3(x, 1.5, z0 + clen - 2.0), 0.6, 0.6)
		U.naga_fan(lm, "Naga", Vector3(x, 1.5, z0 + clen - 1.5), Basis(), 7, 2.8)
		for i in 54:
			var z := z0 + 2.0 + (clen - 6.0) * float(i) / 53.0
			lm.box("Naga", Vector3(x, 1.2, z), Vector3(0.9, 2.0, 0.7))
			lm.box("Stone", Vector3(x, 2.6, z), Vector3(0.6, 0.6, 0.6))
	lm.commit(model)

## Ta Prohm (18 m): the three inner galleried enclosures round the cruciform
## central sanctuary, the face-towered east gopura, corner towers, and
## a few dark masses of silk-cotton trees and their roots clasping the
## walls. Built facing +X (east).
static func ta_prohm(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#7C7160", 3.0))
	lm.use("Laterite", LandmarkMaterials.pbr("stone", "#86593E", 3.0))
	lm.use("Dark", LandmarkMaterials.pbr("concrete", "#25221E", 2.0))
	lm.use("Root", LandmarkMaterials.pbr("rock", "#4D4438", 3.0))
	lm.use("Moss", LandmarkMaterials.pbr("forest", "#4E5C34", 4.0))
	# Three galleried enclosures stepping out from the sanctuary.
	_gallery_ta(lm, 15.0, 19.0, 0.0, 4.8)
	_gallery_ta(lm, 30.0, 40.0, 0.0, 4.4)
	_gallery_ta(lm, 52.0, 62.0, 0.0, 4.0)
	lm.box("Stone", Vector3(0, 1.2, 0), Vector3(13.0, 2.4, 13.0))
	U.prasat(lm, "Stone", "Stone", "Dark", Vector3(0, 2.4, 0), 3.0, 12.0, 3, 0.3)
	for s in [-1.0, 1.0]:
		lm.box("Stone", Vector3(s * 5.0, 2.0, 0), Vector3(3.0, 4.0, 4.4))
		lm.box("Stone", Vector3(0, 2.0, s * 5.0), Vector3(4.4, 4.0, 3.0))
	# Corner towers of the inner two enclosures, gopuras east and west.
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			U.prasat(lm, "Stone", "Stone", "Dark", Vector3(sx * 15.0, 4.8, sz * 19.0), 1.8, 6.0, 2, 0.35)
			U.prasat(lm, "Stone", "Stone", "Dark", Vector3(sx * 30.0, 4.4, sz * 40.0), 2.2, 7.5, 2, 0.35)
	for sx in [-1.0, 1.0]:
		var gb := Vector3(sx * 52.0, 0, 0)
		lm.box("Stone", gb + Vector3(0, 2.5, 0), Vector3(12.0, 5.0, 8.0))
		lm.box("Dark", gb + Vector3(sx * 0.0, 2.2, 4.05), Vector3(3.0, 4.2, 0.2))
		U.face_tower(lm, "Stone", "Dark", gb + Vector3(0, 5.0, 0), 5.2, 13.5)
		for sz in [-1.0, 1.0]:
			lm.box("Stone", gb + Vector3(0, 2.0, sz * 9.0), Vector3(8.0, 4.0, 8.0))
			U.prasat(lm, "Stone", "Stone", "Dark", gb + Vector3(0, 4.0, sz * 9.0), 1.7, 5.5, 2, 0.35)
	# Silk-cotton tree masses clasping the east gopura and the walls.
	_tree(lm, Vector3(52.0, 0, 7.0), 2.6, 15.0)
	_tree(lm, Vector3(30.0, 4.4, -40.0), 2.0, 11.0)
	_tree(lm, Vector3(-52.0, 0, -6.0), 2.2, 13.0)
	_tree(lm, Vector3(-18.0, 0, 28.0), 1.9, 12.0)
	lm.commit(model)

## Roofed gallery ring (stone ranges with a slab roof) at half-sizes hx,hz.
static func _gallery_ta(lm: LandmarkMesh, hx: float, hz: float, y: float, h: float) -> void:
	var t := 3.2
	for s in [-1.0, 1.0]:
		lm.box("Stone", Vector3(0, y + h * 0.5, s * (hz - t * 0.5)), Vector3(hx * 2.0, h, t))
		lm.box("Laterite", Vector3(0, y + h + 0.3, s * (hz - t * 0.5)), Vector3(hx * 2.0 + 0.6, 0.6, t + 0.6))
		lm.box("Stone", Vector3(s * (hx - t * 0.5), y + h * 0.5, 0), Vector3(t, h, hz * 2.0 - t * 2.0))
		lm.box("Laterite", Vector3(s * (hx - t * 0.5), y + h + 0.3, 0), Vector3(t + 0.6, 0.6, hz * 2.0 - t * 2.0))

## Silk-cotton mass: a swollen dark trunk with buttress roots spreading to
## the ground and a mossy bulge where it clasps the stone.
static func _tree(lm: LandmarkMesh, base: Vector3, r: float, h: float) -> void:
	lm.lathe("Root", base, PackedVector2Array([Vector2(r * 1.3, 0), Vector2(r, h * 0.25),
		Vector2(r * 1.15, h * 0.5), Vector2(r * 0.8, h * 0.75), Vector2(r * 1.0, h * 0.9),
		Vector2(r * 0.4, h)]), 9)
	for i in 7:
		var a := TAU * float(i) / 7.0 + 0.4
		var d := Vector3(cos(a), 0, sin(a))
		lm.beam("Root", base + d * r * 0.5 + Vector3(0, h * 0.42, 0), base + d * r * 3.4 + Vector3(0, 0.2, 0),
			r * 0.5, r * 0.4, Vector3.UP)
	lm.lathe("Moss", base + Vector3(0, h * 0.6, 0), PackedVector2Array([Vector2(r * 0.9, 0),
		Vector2(r * 1.8, h * 0.12), Vector2(r * 1.4, h * 0.26), Vector2(r * 0.6, h * 0.34)]), 9)
