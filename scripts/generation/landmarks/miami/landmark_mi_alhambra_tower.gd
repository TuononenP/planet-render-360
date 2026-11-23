class_name LandmarkMiAlhambraTower
extends RefCounted

## Alhambra Water Tower (MI-10). OSM way 637373560 (25.750237, -80.281568, yaw 87.9).
## Denman Fink (1924): 131 ft (40.0 m) octagonal Moorish lighthouse-disguised water tower.
##   - Flared coral-rock base and ochre/salmon stucco shaft with painted frieze bands.
##   - Slit windows, faux iron balconies, corbelled observation gallery.
##   - Ribbed copper dome with weathervane finial reaching exactly 40.0 m, circular hedge ring.

const HEIGHT_M := 40.0

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Coral", LandmarkMaterials.pbr("limestone", "#C9B48F", 3.0))
	lm.use("Ochre", LandmarkMaterials.pbr("render", "#E0A870", 3.5))
	lm.use("Salmon", LandmarkMaterials.pbr("render", "#E39C82", 3.5))
	lm.use("Frieze", LandmarkMaterials.paint("#2F6B8A", 0.7, 0.0))
	lm.use("Iron", LandmarkMaterials.paint("#222629", 0.5, 0.6))
	lm.use("Copper", LandmarkMaterials.pbr("copper", "#4F9A86", 2.6))
	lm.use("Slit", LandmarkMaterials.glass("#1E2A30"))
	lm.use("Hedge", LandmarkMaterials.paint("#2F5E2C", 0.9, 0.0))
	lm.use("Path", LandmarkMaterials.pbr("gravel", "#D9CCAA", 3.0))
	_build_garden(lm)
	_build_shaft(lm)
	_build_gallery_and_dome(lm)
	lm.commit(model)

static func _build_garden(lm: LandmarkMesh) -> void:
	lm.frustum("Path", Vector3(0, -0.4, 0), 7.0, 7.0, 0.4, 24)
	# circular hedge ring broken by four entry gaps
	var n := 32
	for i: int in n:
		if i % 8 == 0 or i % 8 == 7:
			continue
		var a := TAU * (float(i) + 0.5) / float(n)
		var b := Basis(Vector3.UP, -a - PI * 0.5)
		lm.box("Hedge", Vector3(cos(a) * 6.3, 0.55, sin(a) * 6.3), Vector3(1.4, 1.1, 0.9), b, 0.2)

static func _build_shaft(lm: LandmarkMesh) -> void:
	# flared coral-rock base
	lm.frustum("Coral", Vector3(0, -0.3, 0), 4.6, 3.5, 3.3, 8, PI / 8.0)
	lm.frustum("Coral", Vector3(0, 3.0, 0), 3.6, 3.6, 0.3, 8, PI / 8.0)
	# stucco shaft stages, alternating warm ochre and salmon, with frieze bands
	var y := 3.3
	var r := 3.4
	var stages := [[9.0, "Ochre", 3.0], [8.0, "Salmon", 2.85], [6.5, "Ochre", 2.7]]
	for st: Array in stages:
		var h: float = st[0]
		var r1: float = st[2]
		lm.frustum(str(st[1]), Vector3(0, y, 0), r, r1, h, 8, PI / 8.0)
		_frieze(lm, y + h, r1)
		_slits(lm, y, h, r, r1)
		r = r1
		y += h + 0.5
	# faux iron balconies at two levels
	_balcony(lm, 14.0, 3.4)
	_balcony(lm, 24.0, 3.2)
	# shaft top at y
	lm.frustum("Salmon", Vector3(0, y - 0.1, 0), 2.7, 2.7, 0.6, 8, PI / 8.0)

static func _frieze(lm: LandmarkMesh, y: float, r: float) -> void:
	lm.frustum("Frieze", Vector3(0, y, 0), r + 0.12, r + 0.12, 0.28, 8, PI / 8.0)
	lm.frustum("Coral", Vector3(0, y + 0.28, 0), r + 0.2, r + 0.2, 0.22, 8, PI / 8.0)

static func _slits(lm: LandmarkMesh, y0: float, h: float, r0: float, r1: float) -> void:
	for f: int in 8:
		var a := TAU * float(f) / 8.0
		var d := Vector3(cos(a), 0, sin(a))
		for k: int in 2:
			var t := 0.28 + 0.4 * float(k)
			var rr := lerpf(r0, r1, t) * cos(PI / 8.0) + 0.03
			lm.box("Slit", d * rr + Vector3(0, y0 + h * t, 0), Vector3(0.14, 1.5, 0.35),
				Basis(Vector3.UP, -a), 0.0)

static func _balcony(lm: LandmarkMesh, y: float, r: float) -> void:
	for f: int in 8:
		var a := TAU * (float(f) + 0.5) / 8.0 + PI / 8.0
		if f % 2 == 1:
			continue
		var d := Vector3(cos(a), 0, sin(a))
		var b := Basis(Vector3.UP, -a)
		lm.box("Iron", d * (r + 0.5) + Vector3(0, y, 0), Vector3(1.2, 0.12, 2.0), b, 0.0)
		lm.box("Iron", d * (r + 1.4) + Vector3(0, y + 0.55, 0), Vector3(0.08, 1.0, 2.0), b, 0.0)

static func _build_gallery_and_dome(lm: LandmarkMesh) -> void:
	# corbelled observation gallery: stepped brackets then wide deck
	lm.frustum("Coral", Vector3(0, 27.4, 0), 2.7, 3.9, 1.3, 8, PI / 8.0)
	lm.frustum("Coral", Vector3(0, 28.7, 0), 4.2, 4.2, 0.4, 8, PI / 8.0)
	for f: int in 8:
		var a := TAU * float(f) / 8.0
		lm.box("Coral", Vector3(cos(a) * 3.2, 27.9, sin(a) * 3.2), Vector3(0.5, 0.9, 0.5), Basis(Vector3.UP, -a), 0.0)
	# lantern drum with arched openings & iron railing
	lm.frustum("Ochre", Vector3(0, 29.1, 0), 3.0, 3.0, 4.6, 8, PI / 8.0)
	for f: int in 8:
		var a := TAU * float(f) / 8.0 + PI / 8.0
		var d := Vector3(cos(a), 0, sin(a))
		lm.box("Slit", d * 2.82 + Vector3(0, 31.4, 0), Vector3(0.14, 2.2, 1.0), Basis(Vector3.UP, -a), 0.0)
		lm.box("Iron", d * 4.05 + Vector3(0, 29.6, 0), Vector3(0.08, 0.9, 1.6), Basis(Vector3.UP, -a), 0.0)
	lm.frustum("Frieze", Vector3(0, 33.7, 0), 3.2, 3.2, 0.3, 8, PI / 8.0)
	lm.frustum("Coral", Vector3(0, 34.0, 0), 3.5, 3.5, 0.35, 8, PI / 8.0)
	# ribbed copper dome
	lm.lathe("Copper", Vector3(0, 34.35, 0), PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(3.4, 0.0), Vector2(3.5, 0.5), Vector2(3.0, 1.9),
		Vector2(2.1, 3.2), Vector2(1.0, 4.1), Vector2(0.3, 4.45)]), 16, 1.0, 1.0, 0.0, true, false)
	for f: int in 8:
		var a := TAU * float(f) / 8.0
		var d := Vector3(cos(a), 0, sin(a))
		lm.beam("Coral", Vector3(0, 38.7, 0) + d * 0.3, Vector3(0, 34.45, 0) + d * 3.5, 0.18, 0.12, Vector3.UP)
	# finial & weathervane to exactly 40.0 m
	lm.lathe("Iron", Vector3(0, 38.75, 0), PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.35, 0.05), Vector2(0.30, 0.25), Vector2(0.0, 0.40)]), 8)
	lm.beam("Iron", Vector3(0, 39.1, 0), Vector3(0, HEIGHT_M, 0), 0.07, 0.07, Vector3.RIGHT, true)
	lm.beam("Iron", Vector3(-0.7, 39.6, 0), Vector3(0.7, 39.6, 0), 0.05, 0.05, Vector3.UP)
