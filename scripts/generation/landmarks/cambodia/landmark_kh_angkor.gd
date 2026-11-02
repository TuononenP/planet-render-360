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
	# Outer gallery: wall ranges 4.5 m high with a flat stone roof, and the
	# pillared half-gallery outside it that shelters the bas-reliefs.
	_gallery(lm, 0.0, 78.0, 70.0, 4.0, 5.0)
	_pillars(lm, 80.2, 72.2, 3.2, 4.0)
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

## Pillared half-gallery round (0,0) at half-sizes hx, hz: square
## sandstone pillars `step` apart with capitals, `h` tall, under a
## lean-to stone roof sloping off the gallery wall.
static func _pillars(lm: LandmarkMesh, hx: float, hz: float, step: float, h: float) -> void:
	for s in [-1.0, 1.0]:
		var nx := int(hx * 2.0 / step)
		for i in nx + 1:
			var x := -hx + hx * 2.0 * float(i) / float(nx)
			lm.box("Stone", Vector3(x, h * 0.5, s * hz), Vector3(0.6, h, 0.6))
			lm.box("Roof", Vector3(x, h - 0.15, s * hz), Vector3(0.9, 0.3, 0.9), Basis(), 0.0)
		var nz := int(hz * 2.0 / step)
		for i in range(1, nz):
			var z := -hz + hz * 2.0 * float(i) / float(nz)
			lm.box("Stone", Vector3(s * hx, h * 0.5, z), Vector3(0.6, h, 0.6))
			lm.box("Roof", Vector3(s * hx, h - 0.15, z), Vector3(0.9, 0.3, 0.9), Basis(), 0.0)
		lm.quad("Roof", Vector3(-hx - 0.6, h, s * (hz + 0.6)), Vector3(hx + 0.6, h, s * (hz + 0.6)),
			Vector3(hx - 2.2, h + 1.0, s * (hz - 2.2)), Vector3(-hx + 2.2, h + 1.0, s * (hz - 2.2)))
		lm.quad("Roof", Vector3(s * (hx + 0.6), h, -hz - 0.6), Vector3(s * (hx + 0.6), h, hz + 0.6),
			Vector3(s * (hx - 2.2), h + 1.0, hz - 2.2), Vector3(s * (hx - 2.2), h + 1.0, -hz + 2.2))

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

## South Gate of Angkor Thom (23 m): the 8 m laterite city wall with its
## parapet, pierced by the 3.5 x 7 m gate passage; the gate block with the
## three-headed elephant of Indra at each corner, trunks plucking lotuses,
## the central four-faced tower and two lower flanking face towers; and
## the causeway over the moat lined with 54 devas on the left and 54 asuras
## on the right (seen from outside) hauling the naga, its seven-headed hood
## rearing at the outer end. The moat is not modelled: the causeway is a
## raised bank at ground level. Gate faces +Z (south).
static func south_gate(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Laterite", LandmarkMaterials.pbr("stone", "#7E5A44", 3.0))
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#7D7767", 3.0))
	lm.use("Dark", LandmarkMaterials.pbr("concrete", "#22201C", 2.0))
	lm.use("Naga", LandmarkMaterials.pbr("stone", "#6C675A", 3.0))
	# City wall with its parapet.
	for sx in [-1.0, 1.0]:
		U.wall_run(lm, "Laterite", "Stone", Vector3(sx * 72.0, 0, 0), Vector3(sx * 9.0, 0, 0), 8.0, 7.0, 0.3)
		lm.box("Laterite", Vector3(sx * 40.5, 8.8, 3.2), Vector3(63.0, 1.4, 0.6))
		lm.box("Stone", Vector3(sx * 40.5, 9.55, 3.2), Vector3(63.4, 0.2, 0.9), Basis(), 0.0)
	# Gate block: two piers either side of the 3.5 m x 7 m passage with a
	# corbelled head, moulded base and cornice.
	for sx in [-1.0, 1.0]:
		lm.box("Stone", Vector3(sx * 5.4, 4.25, 0), Vector3(7.2, 8.5, 9.0))
		lm.box("Stone", Vector3(sx * 5.4, 0.3, 0), Vector3(7.8, 0.6, 9.6))
		for q in 3:
			lm.box("Stone", Vector3(sx * (1.75 + 0.25 * float(q) + 0.12), 7.2 + 0.4 * float(q), 0),
				Vector3(0.5, 0.4, 9.0), Basis(), 0.0)
	lm.box("Stone", Vector3(0, 8.0, 0), Vector3(3.6, 1.0, 9.0))
	lm.box("Dark", Vector3(0, 3.5, 4.45), Vector3(3.5, 7.0, 0.2), Basis(), 0.0)
	lm.box("Dark", Vector3(0, 3.5, -4.45), Vector3(3.5, 7.0, 0.2), Basis(), 0.0)
	lm.box("Stone", Vector3(0, 8.7, 0), Vector3(19.0, 0.5, 9.8))
	lm.box("Stone", Vector3(0, 8.35, 0), Vector3(18.4, 0.2, 9.4), Basis(), 0.0)
	# Three-headed elephants at the four corners, Indra seated on the
	# middle head; the trunks reach down to pluck lotuses.
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			for k in 3:
				var x: float = sx * (4.4 + 1.6 * float(k))
				var zf: float = sz * 4.7
				var head := Vector3(x, 6.6, zf)
				lm.box("Naga", head + Vector3(0, 0.3, 0), Vector3(1.4, 1.5, 1.0))
				for se in [-1.0, 1.0]:
					lm.box("Naga", head + Vector3(se * 0.75, 0.4, 0), Vector3(0.12, 1.3, 0.9), Basis(), 0.0)
				lm.beam("Naga", head + Vector3(0, -0.2, sz * 0.4), Vector3(x, 2.4, zf + sz * 0.9), 0.62, 0.62)
				lm.beam("Naga", Vector3(x, 2.4, zf + sz * 0.9), Vector3(x, 0.5, zf + sz * 0.7), 0.42, 0.42)
				lm.frustum("Naga", Vector3(x, 0.0, zf + sz * 0.7), 0.5, 0.25, 0.5, 6)
				for se in [-1.0, 1.0]:
					lm.beam("Naga", head + Vector3(se * 0.35, -0.3, sz * 0.4), head + Vector3(se * 0.4, -0.7, sz * 1.0),
						0.14, 0.14)
			LandmarkKits.statue_figure(lm, "Naga", Vector3(sx * 6.0, 7.5, sz * 4.8), 1.3)
	# Central four-faced tower and the two lower flanking towers.
	U.face_tower(lm, "Stone", "Dark", Vector3(0, 8.7, 0), 6.0, 14.3)
	for sx in [-1.0, 1.0]:
		U.face_tower(lm, "Stone", "Dark", Vector3(sx * 7.4, 8.7, 0), 3.4, 8.0)
	# Causeway: a raised laterite bank with moulded edges.
	var z0 := 4.6
	var clen := 96.0
	lm.box("Laterite", Vector3(0, 0.5, z0 + clen * 0.5), Vector3(14.0, 1.0, clen))
	for sx in [-1.0, 1.0]:
		lm.box("Stone", Vector3(sx * 7.0, 0.9, z0 + clen * 0.5), Vector3(0.6, 0.2, clen), Basis(), 0.0)
	# Devas (west, left from outside) and asuras (east): 54 figures a side
	# hauling the naga, whose hood fans out at the far end.
	for sx in [-1.0, 1.0]:
		var x: float = sx * 5.05
		var nb := Vector3(x, 2.7, z0 + 1.5)
		var ne := Vector3(x, 2.7, z0 + clen - 2.5)
		lm.beam("Naga", nb, ne, 0.55, 0.55)
		lm.beam("Naga", nb + Vector3(0, 0.3, 0), ne + Vector3(0, 0.3, 0), 0.2, 0.15, Vector3.RIGHT)
		U.naga_fan(lm, "Naga", Vector3(x, 1.0, z0 + clen - 1.5), Basis(), 7, 3.6)
		for i in 54:
			var z := z0 + 3.0 + (clen - 7.0) * float(i) / 53.0
			_tug_figure(lm, Vector3(sx * 5.6, 1.0, z), sx, sx < 0.0)
	lm.commit(model)

## One giant of the causeway, 2.6 m tall on its block at `base`, leaning
## back toward the gate (-Z) as it hauls the naga at chest height; `side`
## says which side it stands on (it faces the roadway). Devas wear the
## conical mukuta crown, asuras a domed helmet over a scowling brow.
static func _tug_figure(lm: LandmarkMesh, base: Vector3, side: float, deva: bool) -> void:
	lm.box("Stone", base + Vector3(0, 0.2, 0), Vector3(1.0, 0.4, 0.9), Basis(), 0.0)
	var lean := Basis(Vector3.RIGHT, -0.12)
	lm.box("Naga", base + Vector3(side * 0.15, 0.85, 0), Vector3(0.75, 0.9, 0.55), lean)
	lm.box("Naga", base + Vector3(side * 0.15, 1.6, -0.05), Vector3(0.9, 0.6, 0.55), lean)
	var head := base + Vector3(side * 0.15, 2.25, -0.12)
	lm.box("Naga", head, Vector3(0.62, 0.7, 0.6), lean)
	lm.box("Dark", head + Vector3(-side * 0.32, 0.05, 0), Vector3(0.04, 0.12, 0.36), lean, 0.0)
	if deva:
		lm.spire("Naga", head + Vector3(0, 0.35, 0), 0.26, 0.7, 0.05)
	else:
		lm.lathe("Naga", head + Vector3(0, 0.3, 0), PackedVector2Array([Vector2(0.36, 0),
			Vector2(0.34, 0.18), Vector2(0.2, 0.32), Vector2(0.0, 0.36)]), 6)
		lm.box("Naga", head + Vector3(-side * 0.3, 0.18, 0), Vector3(0.1, 0.12, 0.5), Basis(), 0.0)
	for dz in [-0.3, 0.3]:
		lm.beam("Naga", base + Vector3(side * 0.15, 1.75, dz * 0.6), base + Vector3(-side * 0.55, 1.7, dz),
			0.2, 0.2)

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
		lm.beam("Root", base + d * r * 0.5 + Vector3(0, h * 0.42, 0), base + d * r * 3.4 + Vector3(0, r * 0.32, 0),
			r * 0.5, r * 0.4, Vector3.UP)
	lm.lathe("Moss", base + Vector3(0, h * 0.6, 0), PackedVector2Array([Vector2(r * 0.9, 0),
		Vector2(r * 1.8, h * 0.12), Vector2(r * 1.4, h * 0.26), Vector2(r * 0.6, h * 0.34)]), 9)
