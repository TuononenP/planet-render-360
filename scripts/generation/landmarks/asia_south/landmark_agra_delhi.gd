class_name LandmarkAgraDelhi
extends RefCounted

## Mughal and colonial-Delhi monuments in true metres: the Taj Mahal,
## the Qutub Minar and India Gate. Entrances face +Z (south).

const U = preload("res://scripts/generation/landmarks/asia_south/landmark_asia_south_util.gd")

## Taj Mahal (73 m to the finial): white marble tomb with chamfered
## corners and four iwans on a 7 m plinth, the onion dome on its drum,
## four corner kiosks, four slim minarets on the plinth corners and the
## red sandstone mosque and jawab either side.
static func taj_mahal(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#EFEBE0", 3.0))
	lm.use("Sandstone", LandmarkMaterials.pbr("stone", "#94503A", 3.0))
	lm.use("Recess", LandmarkMaterials.pbr("stone", "#5A5248", 3.0))
	lm.use("Gilt", LandmarkMaterials.gold())
	lm.box("Sandstone", Vector3(0, 0.25, 8.0), Vector3(280.0, 5.5, 110.0))
	lm.box("Marble", Vector3(0, 4.75, 0), Vector3(95.0, 4.5, 95.0))
	# Tomb: 57 m square, corners chamfered, 33 m to the parapet.
	var h := 28.5
	var c := 8.0
	var plan := PackedVector2Array([Vector2(-h + c, -h), Vector2(h - c, -h), Vector2(h, -h + c),
		Vector2(h, h - c), Vector2(h - c, h), Vector2(-h + c, h), Vector2(-h, h - c), Vector2(-h, -h + c)])
	lm.poly_prism("Marble", plan, 7.0, 40.0)
	for side in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * float(side))
		# Iwan: framed pointed-arch portal with a dark recess behind.
		U.arch_wall(lm, "Marble", b * Vector3(0, 7.0, h + 1.5), b, 23.0, 35.0, 3.0, 12.0, 24.0)
		lm.box("Recess", b * Vector3(0, 19.0, h + 0.2), Vector3(11.6, 24.0, 0.3), b)
		for sx in [-1.0, 1.0]:
			for y in [13.0, 28.0]:
				lm.box("Recess", b * Vector3(sx * 17.0, y, h + 0.2), Vector3(5.0, 10.0, 0.3), b)
		# The chamfered corner carries the same two-storey niches.
		var d := b * Vector3(h - c * 0.5, 0, h - c * 0.5)
		var nb := Basis(Vector3.UP, PI * 0.25 + PI * 0.5 * float(side))
		for y in [13.0, 28.0]:
			lm.box("Recess", d + Vector3(0, y, 0) + nb * Vector3(0, 0, 0.1), Vector3(5.0, 10.0, 0.3), nb)
		U.chhatri(lm, "Marble", "Marble", b * Vector3(21.0, 40.0, 21.0), 5.5, 4.0, 3.5)
		# Minaret on the plinth corner: octagonal base, tapering shaft, kiosk.
		var m := b * Vector3(41.0, 0, 41.0)
		_minaret(lm, m)
	# Drum, lotus petals, onion dome and gilt finial: 40 -> 73 m.
	lm.frustum("Marble", Vector3(0, 40.0, 0), 9.2, 8.8, 9.0, 32)
	lm.frustum("Marble", Vector3(0, 49.0, 0), 9.6, 8.6, 0.8, 32)
	U.onion(lm, "Marble", Vector3(0, 49.6, 0), 9.8, 18.4, 32)
	U.finial(lm, "Gilt", Vector3(0, 68.0, 0), 5.0, 0.6)
	# Mosque (west) and jawab (east): sandstone halls with three white domes.
	for sx in [-1.0, 1.0]:
		var x: float = 105.0 * sx
		lm.box("Sandstone", Vector3(x, 11.5, 8.0), Vector3(23.0, 17.0, 56.0))
		lm.box("Recess", Vector3(x - sx * 11.6, 9.0, 8.0), Vector3(0.3, 8.0, 40.0))
		for k in 3:
			var z := 8.0 + (float(k) - 1.0) * 18.0
			lm.box("Marble", Vector3(x, 21.0, z), Vector3(12.0, 2.0, 12.0))
			U.dome(lm, "Marble", Vector3(x, 22.0, z), 6.2, 6.5)
			U.finial(lm, "Gilt", Vector3(x, 28.3, z), 2.5, 0.3)
		for sz in [-1.0, 1.0]:
			U.chhatri(lm, "Sandstone", "Marble", Vector3(x, 20.0, 8.0 + sz * 25.0), 4.0, 3.0, 2.5)
	lm.commit(model)

static func _minaret(lm: LandmarkMesh, p: Vector3) -> void:
	lm.lathe("Marble", p + Vector3(0, 7.0, 0), PackedVector2Array([Vector2(6.5, 0), Vector2(6.5, 2.2),
		Vector2(4.4, 2.2), Vector2(4.4, 5.0)]), 8, 1.0, 1.0, PI / 8.0, false)
	lm.frustum("Marble", p + Vector3(0, 12.0, 0), 3.2, 2.7, 26.1, 16)
	for y in [20.0, 29.0]:
		lm.frustum("Marble", p + Vector3(0, y, 0), 4.0, 3.6, 0.9, 16)
	U.chhatri(lm, "Marble", "Marble", p + Vector3(0, 38.1, 0), 5.2, 3.2, 3.2)
	U.finial(lm, "Gilt", p + Vector3(0, 45.0, 0), 2.0, 0.25)

## Qutub Minar (72.5 m): five tapering fluted storeys (red sandstone
## below, marble above) with projecting balconies and a small cupola.
static func qutub_minar(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Red", LandmarkMaterials.pbr("stone", "#B2502E", 3.0))
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#E6DCC8", 3.0))
	lm.use("Plinth", LandmarkMaterials.pbr("stone", "#8C7B68", 3.0))
	lm.frustum("Plinth", Vector3(0, -1.0, 0), 11.0, 10.0, 2.2, 24)
	# y0, y1, base radius, top radius, key, flutes, relief
	var storeys := [[0.0, 29.0, 7.2, 5.9, "Red", 24, 0.9], [29.0, 46.0, 5.5, 4.5, "Red", 24, 0.7],
		[46.0, 58.0, 4.2, 3.4, "Red", 12, 0.9], [58.0, 67.0, 3.1, 2.5, "Marble", 16, 0.25],
		[67.0, 70.5, 2.3, 1.9, "Marble", 8, 0.2]]
	for s in storeys:
		var y0: float = s[0]
		var y1: float = s[1]
		var key: String = s[4]
		U.fluted_shaft(lm, key, Vector3(0, y0, 0), float(s[2]), float(s[3]), y1 - y0, int(s[5]),
			float(s[6]), 3, 3)
		# Balcony: stepped corbels under a railed ledge, at the storey head.
		var r: float = float(s[3]) + float(s[6])
		lm.lathe(key, Vector3(0, y1 - 2.6, 0), PackedVector2Array([Vector2(r, 0), Vector2(r + 0.8, 0.6),
			Vector2(r + 1.5, 1.2), Vector2(r + 1.5, 2.6), Vector2(r + 1.2, 2.6),
			Vector2(r + 1.2, 3.1)]), 24)
	U.dome(lm, "Marble", Vector3(0, 70.5, 0), 1.9, 2.0, 12, 4)
	lm.commit(model)

## India Gate (42 m): the 24 m wide red sandstone triumphal arch on a
## stepped base, a dark inscription band, the cornice and the shallow
## bowl of the eternal flame on top. The passage runs along Z.
static func india_gate(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#B07254", 3.0))
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#76675F", 3.0))
	lm.use("Names", LandmarkMaterials.pbr("stone", "#4A4440", 2.0))
	lm.box("Granite", Vector3(0, 0.75, 0), Vector3(40.0, 3.0, 24.0))
	lm.box("Granite", Vector3(0, 2.25, 0), Vector3(34.0, 1.5, 19.0))
	U.arch_wall(lm, "Stone", Vector3(0, 3.0, 0), Basis(), 26.0, 33.0, 9.1, 10.0, 22.0)
	for sz in [-1.0, 1.0]:
		lm.box("Names", Vector3(0, 28.0, sz * 4.6), Vector3(16.0, 3.0, 0.2))
		for sx in [-1.0, 1.0]:
			lm.box("Names", Vector3(sx * 9.0, 12.0, sz * 4.6), Vector3(5.0, 14.0, 0.2))
	lm.box("Stone", Vector3(0, 37.3, 0), Vector3(29.0, 2.6, 12.0))
	lm.box("Granite", Vector3(0, 38.9, 0), Vector3(27.0, 0.8, 10.5))
	lm.lathe("Granite", Vector3(0, 38.5, 0), PackedVector2Array([Vector2(2.5, 0), Vector2(5.0, 1.0),
		Vector2(6.3, 2.2), Vector2(6.6, 3.5)]), 24)
	lm.commit(model)
