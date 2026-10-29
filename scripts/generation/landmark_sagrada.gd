class_name LandmarkSagrada
extends RefCounted

## Sagrada Família in true metres, as built in 2026: the Latin-cross
## basilica (nave toward the unbuilt Glory façade, apse to the NW),
## the four Nativity bell towers (NE, 98–107 m) and four Passion towers
## (SW, 107–112 m) with their spiralling louvres and Venetian-mosaic
## mitre pinnacles, the four Evangelist towers (135 m), the Tower of
## the Virgin Mary with its star (138 m) and the Tower of Jesus Christ
## with its four-armed cross (172.5 m, topped out 2026) over the
## crossing; the Passion portico's six inclined bone columns.
## Local frame: +X = Nativity (NE), -Z = apse (NW); turned 45° on build.

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#A99A82", 4.0))
	lm.use("NewStone", LandmarkMaterials.pbr("limestone", "#CFC6B6", 4.0))
	lm.use("Roof", LandmarkMaterials.pbr("limestone", "#8E8170", 3.0))
	lm.use("Openings", LandmarkMaterials.pbr("stone", "#2E2924", 3.0))
	lm.use("Mosaic", LandmarkMaterials.pbr("render", "#B8432F", 1.5, 0.35))
	lm.use("MosaicGold", LandmarkMaterials.gold())
	lm.use("Crown", LandmarkMaterials.lit("#F4F1E8", 0.25))
	_basilica(lm)
	var nativity := [98.0, 107.0, 107.0, 98.0]
	var passion := [107.0, 112.0, 112.0, 107.0]
	var zs := [-22.0, -9.5, 9.5, 22.0]
	for k in 4:
		var z: float = zs[k]
		_bell_tower(lm, Vector3(35.0, 0, z), nativity[k], "Stone")
		_bell_tower(lm, Vector3(-35.0, 0, z), passion[k], "NewStone")
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_great_tower(lm, Vector3(sx * 14.0, 0, sz * 14.0), 135.0, 6.2, "evangelist")
	_great_tower(lm, Vector3(0, 0, -32.0), 138.0, 6.8, "star")
	_great_tower(lm, Vector3(0, 0, 0), 172.5, 9.5, "cross")
	lm.commit(model)
	model.rotation.y = deg_to_rad(45.0)

## Five-aisle nave toward the Glory end (+Z), transept to the façades,
## the apse ring, stepped roofs with lantern pinnacles, façade masses.
static func _basilica(lm: LandmarkMesh) -> void:
	lm.box("NewStone", Vector3(0, 22.0, 32.0), Vector3(45.0, 44.0, 60.0))
	# Glory façade (under construction): five portals and the rose.
	for k in 5:
		lm.box("Openings", Vector3(-16.0 + float(k) * 8.0, 9.0, 62.05), Vector3(4.6, 18.0, 0.2))
	lm.disc("Openings", Vector3(0, 31.0, 62.1), Vector3.BACK, 6.0, 24)
	lm.gable("Roof", Vector3(0, 44.0, 32.0), 28.0, 60.0, 14.0)
	lm.box("Stone", Vector3(0, 22.0, 0), Vector3(66.0, 44.0, 30.0))
	lm.gable("Roof", Vector3(0, 44.0, 0), 28.0, 66.0, 14.0, Basis(Vector3.UP, PI * 0.5))
	# Apse: polygonal ring of chapels with small pinnacles.
	lm.lathe("Stone", Vector3(0, 0, -24.0), PackedVector2Array([Vector2(22.0, 0),
		Vector2(22.0, 30.0), Vector2(16.0, 46.0), Vector2(6.0, 56.0)]), 14, 1.0, 1.0, 0.0, false)
	for k in 7:
		var a := PI + PI * float(k) / 6.0
		var p := Vector3(cos(a) * 23.0, 0, -24.0 + sin(a) * 23.0)
		lm.frustum("Stone", p, 2.4, 2.0, 30.0, 8)
		lm.spire("Stone", p + Vector3(0, 30.0, 0), 2.0, 9.0, 0.0, 8)
	# Nave side walls: tall paired windows and buttress pinnacles.
	for sx in [-1.0, 1.0]:
		for k in 6:
			var z := 8.0 + float(k) * 8.5
			lm.box("Openings", Vector3(sx * 22.55, 26.0, z), Vector3(0.2, 22.0, 4.2))
			lm.frustum("Stone", Vector3(sx * 24.0, 0, z + 4.2), 1.4, 1.2, 46.0, 8)
			lm.spire("Mosaic", Vector3(sx * 24.0, 46.0, z + 4.2), 1.3, 7.0, 0.0, 8)
	# Façade masses: Nativity sculpted front, Passion with bone columns.
	lm.box("Stone", Vector3(34.0, 20.0, 0), Vector3(6.0, 40.0, 40.0))
	for k in 3:
		lm.box("Openings", Vector3(37.05, 8.0 + float(k) * 2.0, -12.0 + float(k) * 12.0),
			Vector3(0.2, 16.0, 6.0))
		lm.spire("Stone", Vector3(37.5, 30.0, -12.0 + float(k) * 12.0), 4.0, 16.0, 0.4, 8)
	lm.box("NewStone", Vector3(-34.0, 22.0, 0), Vector3(6.0, 44.0, 40.0))
	lm.box("NewStone", Vector3(-46.0, 22.0, 0), Vector3(3.0, 3.0, 44.0))
	for k in 6:
		var z := -17.5 + float(k) * 7.0
		lm.beam("NewStone", Vector3(-49.0, 0, z), Vector3(-44.5, 24.0, z * 0.8), 3.2, 3.2)
	lm.box("NewStone", Vector3(-43.0, 31.0, 0), Vector3(2.0, 18.0, 12.0))

## A façade bell tower: round, hollow-looking shaft with spiralling
## louvre slots, a parabolic taper and the mosaic mitre pinnacle.
static func _bell_tower(lm: LandmarkMesh, base: Vector3, h: float, key: String) -> void:
	var r := 3.7
	var shaft := h * 0.62
	lm.lathe(key, base, PackedVector2Array([Vector2(r * 1.15, 0), Vector2(r, shaft * 0.4),
		Vector2(r * 0.9, shaft), Vector2(r * 0.66, shaft + h * 0.08),
		Vector2(r * 0.36, shaft + h * 0.14), Vector2(r * 0.14, shaft + h * 0.18)]), 14)
	# Spiralling louvre slots (the "hollow" read of the towers).
	var n := int(shaft / 2.4)
	for k in n:
		var y := 30.0 + float(k) * (shaft - 32.0) / float(maxi(n, 1))
		if y < 30.0 or y > shaft - 2.0:
			continue
		var a := float(k) * 0.9
		var d := Vector3(cos(a), 0, sin(a))
		lm.box("Openings", base + d * (r - 0.05) + Vector3(0, y, 0), Vector3(1.6, 0.9, 0.35),
			Basis(Vector3.UP, -a + PI * 0.5) * Basis(Vector3.RIGHT, 0.4))
	# Mitre pinnacle: stem, gold boss, red-and-gold cross of mitres,
	# white balls crowning each arm.
	var p := base + Vector3(0, shaft + h * 0.18, 0)
	var top := h - (shaft + h * 0.18)
	lm.frustum("MosaicGold", p, 0.9, 0.7, top * 0.25, 8)
	lm.lathe("Mosaic", p + Vector3(0, top * 0.25, 0), PackedVector2Array([Vector2(0.6, 0),
		Vector2(2.2, top * 0.22), Vector2(2.4, top * 0.45), Vector2(0.4, top * 0.75)]), 4, 1.0, 1.0, 0.0, false)
	for s in 4:
		var d := Vector3(1, 0, 0).rotated(Vector3.UP, PI * 0.5 * float(s))
		var arm := p + Vector3(0, top * 0.55, 0) + d * 2.6
		lm.beam("MosaicGold", p + Vector3(0, top * 0.5, 0), arm, 0.9, 0.9)
		lm.lathe("Crown", arm, _ball(0.7), 8)
	lm.lathe("Crown", p + Vector3(0, top * 0.8, 0), _ball(1.0), 10)

## Evangelist / Mary / Jesus towers: square-to-round stepped bases,
## long ribbed parabolic shafts, then the crown of each.
static func _great_tower(lm: LandmarkMesh, base: Vector3, h: float, r: float, kind: String) -> void:
	var shaft := h * (0.80 if kind == "cross" else 0.86)
	lm.lathe("NewStone", base, PackedVector2Array([Vector2(r * 1.25, 0),
		Vector2(r * 1.2, 50.0), Vector2(r, 60.0), Vector2(r * 0.92, shaft * 0.7),
		Vector2(r * 0.62, shaft * 0.9), Vector2(r * 0.25, shaft)]), 12, 1.0, 1.0, 0.0, false)
	# Vertical ribs up the shaft.
	for k in 12:
		var a := TAU * (float(k) + 0.5) / 12.0
		var d := Vector3(cos(a), 0, sin(a))
		lm.beam("NewStone", base + d * r * 1.22 + Vector3(0, 50.0, 0),
			base + d * r * 0.62 + Vector3(0, shaft * 0.9, 0), 0.7, 0.9, d.cross(Vector3.UP))
	# Window bands (lit at dusk on the real towers).
	for k in 5:
		var y := 64.0 + float(k) * (shaft * 0.7 - 64.0) / 5.0
		lm.frustum("Openings", base + Vector3(0, y, 0), r * 0.97, r * 0.95, 1.2, 12)
	var top := base + Vector3(0, shaft, 0)
	match kind:
		"cross":
			var c := top + Vector3(0, h - shaft - 17.0, 0)
			lm.frustum("Crown", top, 2.4, 1.8, h - shaft - 17.0, 8)
			lm.box("Crown", c + Vector3(0, 8.5, 0), Vector3(2.6, 17.0, 2.6))
			for s in 2:
				lm.box("Crown", c + Vector3(0, 11.5, 0), Vector3(13.6, 2.6, 2.6),
					Basis(Vector3.UP, PI * 0.5 * float(s)))
		"star":
			lm.frustum("NewStone", top, 1.8, 1.4, h - shaft - 7.0, 8)
			var c := base + Vector3(0, h - 3.5, 0)
			for k in 12:
				var d := Vector3.UP.rotated(Vector3.BACK, TAU * float(k) / 12.0)
				lm.beam("Crown", c, c + d * 3.6, 0.9, 0.9)
			lm.lathe("Crown", c - Vector3(0, 1.2, 0), _ball(1.2), 10)
		_:
			lm.frustum("Crown", top, 2.0, 1.6, h - shaft - 5.0, 8)
			lm.lathe("Crown", base + Vector3(0, h - 5.0, 0), _ball(2.5), 10)

static func _ball(r: float) -> PackedVector2Array:
	var pr := PackedVector2Array()
	for k in 7:
		var t := PI * float(k) / 6.0
		pr.append(Vector2(sin(t) * r, r - cos(t) * r))
	return pr
