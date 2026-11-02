class_name LandmarkChWawel
extends RefCounted

## Wawel Cathedral for the Wawel castle model, in true metres: the
## Gothic basilica (consecrated 1364) north of the castle with its axis
## on X (west front -X), buttresses and traceried lancets, the Clock
## Tower at the south west corner (Gothic, finished 1522, Baroque helm
## with corner statues, the tallest point of the hill, 56 m), the
## Sigismund Tower at the north west (bell of 1520, helm of 1899), the
## Silver Bells Tower by the choir, and the domed side chapels: the
## gilded Sigismund Chapel (Berrecci, 1519-33) and its twin, the Vasa
## Chapel, to the south. Draws on the castle model's material keys.

const C := Vector3(0, 0, -32.0)

static func cathedral(lm: LandmarkMesh) -> void:
	_body(lm)
	_clock_tower(lm, C + Vector3(-24.0, 0, 13.0))
	_sigismund_tower(lm, C + Vector3(-24.0, 0, -14.0))
	_silver_tower(lm, C + Vector3(22.0, 0, 12.0))
	_chapels(lm)

## Nave and choir under copper roofs, the polygonal east end,
## buttresses, lancets with tracery, the west portal.
static func _body(lm: LandmarkMesh) -> void:
	var c := C
	lm.box("Stone", c + Vector3(-4.5, 8.5, 0), Vector3(49.0, 17.0, 20.0))
	lm.gable("Copper", c + Vector3(-4.5, 17.0, 0), 20.0, 49.0, 9.5, Basis(Vector3.UP, PI * 0.5), 0.6, "Stone")
	lm.box("Stone", c + Vector3(25.5, 8.5, 0), Vector3(11.0, 17.0, 20.0))
	lm.gable("Copper", c + Vector3(25.5, 17.0, 0), 20.0, 11.0, 9.5, Basis(Vector3.UP, PI * 0.5), 0.6, "Stone")
	lm.frustum("Stone", c + Vector3(31.0, 0, 0), 11.0, 11.0, 17.0, 8, PI / 8.0)
	lm.lathe("Copper", c + Vector3(31.0, 17.0, 0), PackedVector2Array([Vector2(11.6, 0), Vector2(0.0, 10.0)]), 8,
		1.0, 1.0, PI / 8.0, false)
	for sz in [-1.0, 1.0]:
		var n := Vector3(0, 0, sz)
		LandmarkDetail.cornice(lm, "Stone", c + Vector3(-29.0, 16.4, sz * 10.0), c + Vector3(31.0, 16.4, sz * 10.0), n,
			0.6, false)
		for i in 9:
			var x := -24.0 + 6.5 * i
			LandmarkChParts.buttress(lm, "Stone", c + Vector3(x, 0, sz * 10.0), n, 1.3, 2.0, 15.0, 3)
			if i < 8:
				LandmarkChParts.lancet(lm, "Stone", "Windows", c + Vector3(x + 3.25, 5.0, sz * 10.0), n, 2.2, 9.0, 1, 0.3)
	for k in [-1, 0, 1]:
		var a := PI * 0.25 * float(k)
		var d := Vector3(cos(a), 0, sin(a))
		LandmarkChParts.lancet(lm, "Stone", "Windows", c + Vector3(31.0, 5.0, 0) + d * 10.15, d, 2.2, 9.0, 1, 0.3)
	for k in [-2, -1, 0, 1]:
		var a := PI / 8.0 + PI * 0.25 * float(k)
		var d := Vector3(cos(a), 0, sin(a))
		LandmarkChParts.buttress(lm, "Stone", c + Vector3(31.0, 0, 0) + d * 10.6, d, 1.3, 2.0, 15.0, 3)
	# West front: portal under a wimperg, rose window, gable.
	var w := c + Vector3(-29.0, 0, 0)
	LandmarkChParts.lancet(lm, "Stone", "Windows", w + Vector3(-0.1, 0.3, 0), Vector3.LEFT, 3.2, 7.0, 1, 0.4)
	LandmarkChParts.wimperg(lm, "Stone", w + Vector3(-0.1, 7.0, 0), Vector3.LEFT, 4.6, 3.6, 0.35)
	lm.disc("Windows", w + Vector3(-0.05, 12.0, 0), Vector3.LEFT, 2.2, 20)
	var prev := w + Vector3(-0.2, 12.0, 2.4)
	for k in 16:
		var a := TAU * float(k + 1) / 16.0
		var q := w + Vector3(-0.2, 12.0 + sin(a) * 2.4, cos(a) * 2.4)
		lm.beam("Stone", prev, q, 0.4, 0.35, Vector3.LEFT)
		prev = q

## Clock Tower: Gothic square shaft with stone dressings and the clock,
## a Baroque top storey with corner statues, the double-swelled helm,
## lantern and finial reaching 56 m.
static func _clock_tower(lm: LandmarkMesh, p: Vector3) -> void:
	var hw := 5.0
	lm.box("Brick", p + Vector3(0, 17.0, 0), Vector3(hw * 2.0, 34.0, hw * 2.0))
	for y in [11.0, 22.0]:
		LandmarkChParts.band(lm, "Stone", y, hw, hw, 0.5, 0.25, p)
	LandmarkChParts.band(lm, "Stone", 33.4, hw, hw, 0.8, 0.5, p)
	for f in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * f)
		var n := b.z
		var face := p + b * Vector3(0, 0, hw)
		for s in [-1.0, 1.0]:
			lm.box("Stone", face + b * Vector3(s * (hw - 0.4), 17.0, 0.1), Vector3(0.8, 34.0, 0.3), b)
		LandmarkChParts.lancet(lm, "Stone", "Windows", face + Vector3(0, 13.0, 0), n, 1.4, 5.0, 0, 0.25)
		lm.disc("Stone", face + Vector3(0, 27.0, 0.12), n, 2.0, 24)
		lm.disc("Gilt", face + Vector3(0, 27.0, 0.18), n, 1.6, 24)
		lm.beam("Windows", face + Vector3(0, 27.0, 0.24), face + b * Vector3(0.9, 27.6, 0.24), 0.12, 0.04, n)
	# Baroque belfry storey with pilasters, arched openings, statues.
	var y := 34.2
	lm.box("Wall", p + Vector3(0, y + 3.5, 0), Vector3(8.6, 7.0, 8.6))
	for f in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * f)
		var n := b.z
		for s in [-1.0, 1.0]:
			lm.box("Stone", p + b * Vector3(s * 3.6, y + 3.5, 4.35), Vector3(0.6, 7.0, 0.3), b)
		LandmarkChParts.arched_window(lm, "Stone", "Windows", p + b * Vector3(0, y + 1.2, 4.3), n, 1.8, 4.6, 0.25)
		LandmarkDetail.cornice(lm, "Stone", p + b * Vector3(-4.3, y + 6.6, 4.3), p + b * Vector3(4.3, y + 6.6, 4.3), n,
			0.6, false)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var sp := p + Vector3(sx * 4.6, y + 7.2, sz * 4.6)
			lm.box("Stone", sp + Vector3(0, 0.3, 0), Vector3(0.8, 0.6, 0.8))
			LandmarkKits.statue_figure(lm, "Stone", sp + Vector3(0, 0.6, 0), 2.0, sx > 0.0)
	# Helm: bell, waist, lantern, small onion and finial.
	var hb := p + Vector3(0, y + 7.2, 0)
	lm.lathe("Copper", hb, PackedVector2Array([Vector2(4.6, 0), Vector2(4.4, 0.8), Vector2(3.6, 2.2),
		Vector2(2.2, 3.4), Vector2(1.5, 4.2)]), 16)
	lm.frustum("Wall", hb + Vector3(0, 4.2, 0), 1.3, 1.2, 2.6, 8)
	for k in 8:
		var a := TAU * float(k) / 8.0
		lm.frustum("Stone", hb + Vector3(cos(a) * 1.35, 4.2, sin(a) * 1.35), 0.12, 0.1, 2.6, 6)
	lm.lathe("Copper", hb + Vector3(0, 6.8, 0), LandmarkKits.onion_profile(1.2, 2.6), 12)
	LandmarkChParts.finial(lm, "Gilt", hb + Vector3(0, 9.4, 0), LandmarkChPoland.WAWEL_TOP - hb.y - 9.4, 0.3)

## Sigismund Tower: tall square stone shaft with corner buttresses,
## lancets and the belfry, the Renaissance helm with lantern.
static func _sigismund_tower(lm: LandmarkMesh, p: Vector3) -> void:
	var hw := 5.5
	lm.box("Stone", p + Vector3(0, 16.0, 0), Vector3(hw * 2.0, 32.0, hw * 2.0))
	LandmarkChParts.band(lm, "Wall", 32.0, hw, hw, 0.8, 0.4, p)
	lm.box("Stone", p + Vector3(0, 35.9, 0), Vector3(9.6, 6.2, 9.6))
	LandmarkChParts.band(lm, "Wall", 39.0, 4.8, 4.8, 0.6, 0.4, p)
	for f in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * f)
		var n := b.z
		var face := p + b * Vector3(0, 0, hw)
		for s in [-1.0, 1.0]:
			LandmarkChParts.buttress(lm, "Stone", face + b * Vector3(s * (hw - 0.7), 0, 0), n, 1.2, 1.4, 26.0, 3)
		LandmarkChParts.lancet(lm, "Wall", "Windows", face + Vector3(0, 8.0, 0), n, 1.6, 5.5, 0, 0.25)
		for x in [-1.5, 1.5]:
			LandmarkChParts.lancet(lm, "Wall", "Windows", face + b * Vector3(x, 20.0, 0), n, 1.4, 5.5, 0, 0.25)
		for x in [-2.1, 2.1]:
			LandmarkChParts.arched_window(lm, "Wall", "Windows", p + b * Vector3(x, 33.4, 4.8), n, 2.0, 4.4, 0.25)
	var hb := p + Vector3(0, 39.6, 0)
	lm.lathe("Copper", hb, PackedVector2Array([Vector2(6.2, 0), Vector2(6.8, 1.0), Vector2(6.0, 3.0),
		Vector2(3.8, 6.0), Vector2(2.5, 8.0)]), 16)
	lm.frustum("Stone", hb + Vector3(0, 8.0, 0), 2.2, 2.0, 3.0, 8)
	for k in 8:
		var a := TAU * float(k) / 8.0
		LandmarkChParts.arched_window(lm, "Stone", "Windows", hb + Vector3(cos(a), 0, sin(a)) * 2.05 + Vector3(0, 8.4, 0),
			Vector3(cos(a), 0, sin(a)), 0.6, 1.8, 0.15, 4)
	lm.lathe("Copper", hb + Vector3(0, 11.0, 0), PackedVector2Array([Vector2(2.6, 0), Vector2(1.6, 1.2),
		Vector2(0.5, 2.5)]), 12)
	LandmarkChParts.finial(lm, "Gilt", hb + Vector3(0, 13.5, 0), 1.6, 0.5)

## Silver Bells Tower by the choir: square Gothic base, octagonal
## belfry and the slim pointed helm of 1769.
static func _silver_tower(lm: LandmarkMesh, p: Vector3) -> void:
	lm.box("Stone", p + Vector3(0, 9.0, 0), Vector3(6.4, 18.0, 6.4))
	LandmarkChParts.band(lm, "Wall", 12.0, 3.2, 3.2, 0.5, 0.2, p)
	lm.frustum("Wall", p + Vector3(0, 18.0, 0), 3.3, 3.2, 8.0, 8, PI / 8.0)
	for k in 8:
		var a := PI * 0.25 * k
		var d := Vector3(cos(a), 0, sin(a))
		LandmarkChParts.arched_window(lm, "Stone", "Windows", p + d * 3.0 + Vector3(0, 19.5, 0), d, 0.9, 3.4, 0.18)
	lm.frustum("Stone", p + Vector3(0, 26.0, 0), 3.6, 3.6, 0.5, 8, PI / 8.0)
	lm.lathe("Copper", p + Vector3(0, 26.5, 0), PackedVector2Array([Vector2(3.6, 0), Vector2(2.4, 2.5),
		Vector2(0.9, 8.0), Vector2(0.1, 14.0)]), 8, 1.0, 1.0, PI / 8.0, false)
	LandmarkChParts.finial(lm, "Gilt", p + Vector3(0, 40.5, 0), 1.6, 0.3)

## Side chapels: the gilded Sigismund Chapel (square, drum with oculi,
## ribbed and scaled dome, lantern) and the Vasa Chapel beside it, the
## rest with copper domes.
static func _chapels(lm: LandmarkMesh) -> void:
	var c := C
	_chapel(lm, c + Vector3(-14.0, 0, 14.0), 4.0, 14.0, 3.0)
	for x in [-16.0, -2.0, 14.0]:
		_chapel(lm, c + Vector3(x, 0, -13.2), 3.2, 11.0, 2.2)
	_chapel(lm, c + Vector3(15.0, 0, 13.5), 3.5, 13.0, 2.5)
	for sc in [[2.0, "Gilt"], [-6.5, "Copper"]]:
		var sg := c + Vector3(float(sc[0]), 0, 15.75)
		var dk: String = sc[1]
		lm.box("Stone", sg + Vector3(0, 8.5, 0), Vector3(8.0, 17.0, 11.5))
		for f in [0, 1, 3]:
			var b := Basis(Vector3.UP, PI * 0.5 * f)
			var hw := 5.75 if f == 0 else 4.0
			var face := sg + b * Vector3(0, 0, hw)
			for s in [-1.0, 1.0]:
				lm.box("Wall", face + b * Vector3(s * 2.6, 8.5, 0.15), Vector3(0.7, 15.0, 0.3), b)
			LandmarkChParts.arched_window(lm, "Wall", "Windows", face + Vector3(0, 9.0, 0), b.z, 1.4, 3.4, 0.2)
			LandmarkDetail.cornice(lm, "Wall", face + b * Vector3(-hw + 0.1, 16.4, 0), face + b * Vector3(hw - 0.1, 16.4, 0),
				b.z, 0.6, false)
		lm.frustum("Stone", sg + Vector3(0, 17.0, 0), 4.6, 4.6, 6.0, 8, PI / 8.0)
		for k in 8:
			var a := PI * 0.25 * k
			var d := Vector3(cos(a), 0, sin(a))
			lm.disc("Windows", sg + d * 4.28 + Vector3(0, 20.0, 0), d, 0.8, 12)
		lm.frustum("Wall", sg + Vector3(0, 22.6, 0), 4.9, 5.0, 0.4, 16)
		var prof := PackedVector2Array([Vector2(4.6, 0), Vector2(4.7, 1.0), Vector2(4.4, 2.8), Vector2(3.6, 5.0),
			Vector2(2.4, 7.0), Vector2(1.3, 8.4), Vector2(0.9, 9.0)])
		lm.lathe(dk, sg + Vector3(0, 23.0, 0), prof, 24)
		for k in 16:
			var a := TAU * float(k) / 16.0
			for j in prof.size() - 1:
				var p0 := sg + Vector3(cos(a) * (prof[j].x + 0.08), 23.0 + prof[j].y, sin(a) * (prof[j].x + 0.08))
				var p1 := sg + Vector3(cos(a) * (prof[j + 1].x + 0.08), 23.0 + prof[j + 1].y, sin(a) * (prof[j + 1].x + 0.08))
				lm.beam(dk, p0, p1, 0.18, 0.1)
		# Lantern with its colonnettes, cupola and finial.
		var lb := sg + Vector3(0, 32.0, 0)
		lm.frustum("Stone", lb, 1.0, 0.9, 2.8, 8)
		for k in 8:
			var a := TAU * float(k) / 8.0
			lm.frustum("Stone", lb + Vector3(cos(a), 0, sin(a)) * 1.05, 0.1, 0.09, 2.8, 6)
		lm.frustum("Stone", lb + Vector3(0, 2.8, 0), 1.3, 1.3, 0.3, 12)
		lm.lathe(dk, lb + Vector3(0, 3.1, 0), PackedVector2Array([Vector2(1.3, 0), Vector2(1.0, 0.4),
			Vector2(0.5, 1.4), Vector2(0.06, 2.2)]), 12)
		LandmarkChParts.finial(lm, "Gilt", lb + Vector3(0, 5.3, 0), 1.8, 0.3)

## Square chapel of half-width `half` with a drum-less copper dome.
static func _chapel(lm: LandmarkMesh, p: Vector3, half: float, h: float, dome_h: float) -> void:
	lm.box("Stone", p + Vector3(0, h * 0.5, 0), Vector3(half * 2.0, h, half * 2.0))
	LandmarkChParts.band(lm, "Wall", h - 0.8, half, half, 0.8, 0.3, p)
	for f in 4:
		var b := Basis(Vector3.UP, PI * 0.5 * f)
		LandmarkChParts.arched_window(lm, "Wall", "Windows", p + b * Vector3(0, h * 0.45, half), b.z, 1.2, 3.0, 0.2)
	lm.lathe("Copper", p + Vector3(0, h, 0), LandmarkChParts.swell(half * 1.05, dome_h * 2.4), 16)
	LandmarkChParts.finial(lm, "Gilt", p + Vector3(0, h + dome_h * 2.4, 0), 1.6, 0.3)
