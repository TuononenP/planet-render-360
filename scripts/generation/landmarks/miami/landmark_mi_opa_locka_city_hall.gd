class_name LandmarkMiOpaLockaCityHall
extends RefCounted

## Opa-locka Company Administration Building (historic City Hall) — Bernhardt Muller, 1926 (MI-10).
## 48 x 34 m Moorish Revival "Arabian Nights" palace: cream stucco, horseshoe arches, crenellated
## parapets, slender minarets and blue-and-white striped onion domes with crescent finials.
## Central dome + crescent finial reach y = 22.0 m.

const HEIGHT_M := 22.0
const DOME_PROF: Array[Vector2] = [
	Vector2(1.0, 0.0), Vector2(1.12, 0.22), Vector2(1.06, 0.5), Vector2(0.76, 0.84),
	Vector2(0.38, 1.18), Vector2(0.12, 1.48), Vector2(0.03, 1.66)]

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stucco", LandmarkMaterials.pbr("render", "#EBDCB8", 3.0))
	lm.use("White", LandmarkMaterials.paint("#F5F1E6", 0.6, 0.05))
	lm.use("Blue", LandmarkMaterials.paint("#1F5FA8", 0.45, 0.15))
	lm.use("Dark", LandmarkMaterials.paint("#2B2420", 0.8, 0.0))
	lm.use("Gold", LandmarkMaterials.paint("#D4AF37", 0.35, 0.8))
	lm.use("Tile", LandmarkMaterials.pbr("terracotta", "#B9683F", 2.0))

	_build_body(lm)
	_build_facade(lm)
	_build_tower_and_domes(lm)
	_build_minarets(lm)
	lm.commit(model)

static func _dome(lm: LandmarkMesh, base: Vector3, scale: float, ribs: int) -> void:
	var prof := PackedVector2Array()
	for p: Vector2 in DOME_PROF:
		prof.append(p * scale)
	lm.lathe("White", base, prof, 16, 1.0, 1.0, 0.0, true, true)
	# Blue stripes: rib beams following the dome profile
	for k: int in ribs:
		var a := float(k) / float(ribs) * TAU
		var d := Vector3(cos(a), 0.0, sin(a))
		var side := Vector3.UP.cross(d).normalized()
		for j: int in DOME_PROF.size() - 2:
			var p0 := DOME_PROF[j] * scale
			var p1 := DOME_PROF[j + 1] * scale
			lm.beam("Blue", base + d * (p0.x + 0.03) + Vector3(0, p0.y, 0),
				base + d * (p1.x + 0.03) + Vector3(0, p1.y, 0), 0.3 * scale, 0.05, side)

static func _crescent(lm: LandmarkMesh, c: Vector3, r: float) -> void:
	var prev := Vector3.ZERO
	for j: int in 9:
		var t := PI * 0.25 + PI * 1.5 * float(j) / 8.0
		var pt := c + Vector3(cos(t) * r, sin(t) * r, 0.0)
		if j > 0:
			lm.beam("Gold", prev, pt, 0.08, 0.08, Vector3(0, 0, 1))
		prev = pt

static func _merlons(lm: LandmarkMesh, a: Vector2, b: Vector2, y: float) -> void:
	var n := maxi(int(a.distance_to(b) / 1.4), 2)
	for i: int in n + 1:
		var p := a.lerp(b, float(i) / float(n))
		lm.box("Stucco", Vector3(p.x, y + 0.45, p.y), Vector3(0.7, 0.9, 0.7), Basis(), 0.0)

static func _build_body(lm: LandmarkMesh) -> void:
	lm.box("Stucco", Vector3(0.0, 0.3, 0.0), Vector3(48.0, 0.6, 34.0), Basis(), 0.0)
	# Main block x -16..16, z -10..10, 9 m high
	lm.box("Stucco", Vector3(0.0, 4.5, 0.0), Vector3(32.0, 9.0, 20.0), Basis(), 0.0)
	# Side wings x +-(16..24), z -10..8, 6.5 m
	for sx: float in [-1.0, 1.0]:
		lm.box("Stucco", Vector3(sx * 20.0, 3.25, -1.0), Vector3(8.0, 6.5, 18.0), Basis(), 0.0)
		_merlons(lm, Vector2(sx * 16.0, -10.0), Vector2(sx * 24.0, -10.0), 6.5)
		_merlons(lm, Vector2(sx * 16.0, 8.0), Vector2(sx * 24.0, 8.0), 6.5)
		_merlons(lm, Vector2(sx * 24.0, -10.0), Vector2(sx * 24.0, 8.0), 6.5)
		lm.box("White", Vector3(sx * 20.0, 6.65, -1.0), Vector3(8.4, 0.3, 18.4), Basis(), 0.0)
	# Parapet crenellation around main block
	lm.box("White", Vector3(0.0, 9.1, 0.0), Vector3(32.4, 0.3, 20.4), Basis(), 0.0)
	_merlons(lm, Vector2(-16.0, -10.0), Vector2(16.0, -10.0), 9.2)
	_merlons(lm, Vector2(-16.0, 10.0), Vector2(16.0, 10.0), 9.2)
	_merlons(lm, Vector2(-16.0, -10.0), Vector2(-16.0, 10.0), 9.2)
	_merlons(lm, Vector2(16.0, -10.0), Vector2(16.0, 10.0), 9.2)

static func _build_facade(lm: LandmarkMesh) -> void:
	# Front loggia (z 10..17) with horseshoe arches and terracotta flat roof
	lm.box("Stucco", Vector3(0.0, 0.8, 13.5), Vector3(26.0, 1.0, 7.0), Basis(), 0.0)
	lm.box("Stucco", Vector3(0.0, 5.4, 13.5), Vector3(26.0, 0.8, 7.0), Basis(), 0.0)
	lm.box("White", Vector3(0.0, 5.95, 13.5), Vector3(26.4, 0.3, 7.4), Basis(), 0.0)
	for i: int in 9:
		var x := -12.0 + float(i) * 3.0
		lm.frustum("White", Vector3(x, 1.3, 16.6), 0.28, 0.28, 3.0, 8)
		if i < 8:
			lm.box("Dark", Vector3(x + 1.5, 2.8, 16.55), Vector3(1.6, 2.6, 0.1), Basis(), 0.0)
			lm.disc("Dark", Vector3(x + 1.5, 4.1, 16.55), Vector3(0, 0, 1), 0.95, 14)
			lm.box("White", Vector3(x + 1.5, 4.9, 16.65), Vector3(2.2, 0.35, 0.3), Basis(), 0.0)
	_merlons(lm, Vector2(-13.0, 17.0), Vector2(13.0, 17.0), 6.1)
	# Upper-storey keyhole windows on the main block front
	for i: int in 7:
		var x := -12.0 + float(i) * 4.0
		if absf(x) < 5.0:
			continue
		lm.box("Dark", Vector3(x, 7.0, 10.05), Vector3(1.0, 1.7, 0.1), Basis(), 0.0)
		lm.disc("Dark", Vector3(x, 7.85, 10.05), Vector3(0, 0, 1), 0.5, 12)
	# Wing windows
	for sx: float in [-1.0, 1.0]:
		for k: int in 3:
			var x := sx * (17.5 + float(k) * 2.5)
			lm.box("Dark", Vector3(x, 3.2, 8.05), Vector3(1.0, 2.2, 0.1), Basis(), 0.0)
			lm.disc("Dark", Vector3(x, 4.3, 8.05), Vector3(0, 0, 1), 0.5, 12)

static func _build_tower_and_domes(lm: LandmarkMesh) -> void:
	# Central entrance tower: x -4.5..4.5, z 2..11 up to y = 14, big onion dome to 21, finial to 22.0
	lm.box("Stucco", Vector3(0.0, 7.0, 6.5), Vector3(9.0, 14.0, 9.0), Basis(), 0.0)
	lm.box("White", Vector3(0.0, 14.15, 6.5), Vector3(9.6, 0.3, 9.6), Basis(), 0.0)
	_merlons(lm, Vector2(-4.5, 11.0), Vector2(4.5, 11.0), 14.3)
	_merlons(lm, Vector2(-4.5, 2.0), Vector2(4.5, 2.0), 14.3)
	lm.box("Dark", Vector3(0.0, 3.0, 11.05), Vector3(2.8, 5.0, 0.1), Basis(), 0.0)
	lm.disc("Dark", Vector3(0.0, 5.5, 11.05), Vector3(0, 0, 1), 1.5, 16)
	lm.box("Dark", Vector3(0.0, 10.5, 11.05), Vector3(1.2, 2.2, 0.1), Basis(), 0.0)
	lm.disc("Dark", Vector3(0.0, 11.6, 11.05), Vector3(0, 0, 1), 0.6, 12)
	lm.frustum("Blue", Vector3(0.0, 14.3, 6.5), 3.7, 3.7, 0.6, 16)
	_dome(lm, Vector3(0.0, 14.9, 6.5), 4.0, 12)
	# DOME_PROF top at 1.66 * 4.0 = 6.64 -> y = 21.54; finial spire to exactly 22.0
	lm.spire("Gold", Vector3(0.0, 21.54, 6.5), 0.1, 0.46, 0.0, 6)
	_crescent(lm, Vector3(0.0, 21.5, 6.5), 0.28)
	# Rear/side corner pavilions with small domes
	for sx: float in [-1.0, 1.0]:
		lm.box("Stucco", Vector3(sx * 12.0, 6.5, -8.0), Vector3(5.0, 13.0, 5.0), Basis(), 0.0)
		lm.frustum("Blue", Vector3(sx * 12.0, 13.0, -8.0), 2.3, 2.3, 0.4, 14)
		_dome(lm, Vector3(sx * 12.0, 13.4, -8.0), 2.3, 8)
		lm.spire("Gold", Vector3(sx * 12.0, 17.2, -8.0), 0.07, 0.8, 0.0, 6)

static func _build_minarets(lm: LandmarkMesh) -> void:
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			var p := Vector3(sx * 21.5, 0.0, sz * 14.0)
			lm.frustum("Stucco", p + Vector3(0, 0.6, 0), 1.3, 0.95, 13.0, 10)
			lm.frustum("Blue", p + Vector3(0, 8.0, 0), 1.05, 1.05, 0.5, 10)
			lm.frustum("White", p + Vector3(0, 13.6, 0), 1.45, 1.45, 0.4, 10)
			lm.frustum("Stucco", p + Vector3(0, 14.0, 0), 0.95, 0.95, 1.2, 10)
			_dome(lm, p + Vector3(0, 15.2, 0), 1.0, 8)
			lm.spire("Gold", p + Vector3(0, 16.86, 0), 0.05, 0.9, 0.0, 6)
			lm.box("Dark", p + Vector3(0.0, 11.0, sz * 0.85), Vector3(0.3, 1.0, 0.1), Basis(), 0.0)
