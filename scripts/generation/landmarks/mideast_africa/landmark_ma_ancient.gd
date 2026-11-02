class_name LandmarkMaAncient
extends RefCounted

## Two ancient rock-cut monuments in true metres: Petra's Treasury
## (Al-Khazneh) and the Abu Simbel temples. The Great Sphinx is
## LandmarkMaSphinx.

# --- Petra, Al-Khazneh (the Treasury) ---

## 25.3 m wide, 39.1 m high Nabataean tomb facade (1st century) cut into
## the rose sandstone at the end of the Siq, built facing +Z (the
## registry yaw turns it to face east). Lower storey: a hexastyle
## Corinthian portico on a stepped base, the central four columns under
## a pediment with lion acroteria, the Dioscuri reliefs in the outer
## bays. Upper storey: the round tholos with its tent roof, Corinthian
## capital and solid urn, between two half-pavilions carrying the halves
## of a broken pediment, with dancing Amazon reliefs and four eagles.
## The cliff round it is layered in jutting sandstone strata.
static func petra(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Cliff", LandmarkMaterials.pbr("stone", "#B5755C", 6.0))
	lm.use("Facade", LandmarkMaterials.pbr("stone", "#D6A08A", 3.0))
	lm.use("Door", LandmarkMaterials.glass("#1E1612"))
	_petra_cliff(lm)
	# Recessed back plane of the facade and the stepped base.
	lm.box("Facade", Vector3(0, 19.5, -0.5), Vector3(26, 39, 1.0))
	for k in 3:
		lm.box("Facade", Vector3(0, 0.33 * float(k) + 0.165, 6.2 - 0.5 * float(k)),
			Vector3(24.4 - 0.4 * float(k), 0.33, 12.4 - float(k)))
	var y0 := 1.0
	# Lower storey: six Corinthian columns, the portico behind them.
	var cols: Array[float] = [-10.2, -6.1, -2.0, 2.0, 6.1, 10.2]
	for x in cols:
		LandmarkDetail.column(lm, "Facade", Vector3(x, y0, 4.2), 0.58, 12.4, "corinthian", 0)
	# Pronaos: the back wall with the great door, side chamber doors.
	_petra_door(lm, Vector3(0, y0, 0.0), 3.6, 8.2)
	for s in [-1.0, 1.0]:
		_petra_door(lm, Vector3(s * 6.6, y0, 0.0), 1.6, 4.4)
		# Outer bays closed by relief walls with a Dioscurus and horse.
		lm.box("Facade", Vector3(s * 8.15, y0 + 6.2, 3.2), Vector3(2.9, 12.4, 0.8))
		LandmarkKits.statue_figure(lm, "Facade", Vector3(s * 8.4, y0 + 1.0, 3.9), 3.6)
		lm.box("Facade", Vector3(s * 7.6, y0 + 1.6, 3.9), Vector3(0.9, 1.4, 0.7))
		lm.beam("Facade", Vector3(s * 7.3, y0 + 2.4, 3.9), Vector3(s * 7.1, y0 + 3.6, 3.9), 0.5, 0.5)
		# Pilasters at the facade's outer edges.
		lm.box("Facade", Vector3(s * 12.1, 19.5, 0.6), Vector3(1.4, 39, 1.4))
	# Entablature: architrave, the scrolled frieze, the cornice.
	var ey := y0 + 12.4
	lm.box("Facade", Vector3(0, ey + 0.6, 4.2), Vector3(23.6, 1.2, 1.9))
	lm.box("Facade", Vector3(0, ey + 1.55, 4.0), Vector3(23.6, 0.7, 1.7))
	for i in 24:
		var x := -11.25 + 22.5 * float(i) / 23.0
		lm.lathe("Facade", Vector3(x, ey + 1.55, 4.86), PackedVector2Array([Vector2(0.28, -0.0),
			Vector2(0.3, 0.06), Vector2(0.0, 0.1)]), 8)
	LandmarkDetail.cornice(lm, "Facade", Vector3(-11.8, ey + 1.9, 5.1), Vector3(11.8, ey + 1.9, 5.1),
		Vector3.BACK, 0.9, true)
	# Pediment over the central four columns, raking cornices, acroteria.
	var py := ey + 2.8
	lm.gable("Facade", Vector3(0, py, 4.3), 14.6, 1.6, 3.4, Basis(), 0.0, "Facade")
	for s in [-1.0, 1.0]:
		lm.beam("Facade", Vector3(s * 7.7, py, 5.2), Vector3(0, py + 3.6, 5.2), 0.5, 0.6)
		_petra_lion(lm, Vector3(s * 7.4, py, 4.6))
	lm.box("Facade", Vector3(0, py + 3.75, 4.6), Vector3(1.0, 1.1, 0.8))
	# Attic storey between the levels.
	var uy := py + 1.4
	lm.box("Facade", Vector3(0, uy + 0.9, 2.2), Vector3(24.6, 1.8, 2.4))
	lm.box("Facade", Vector3(0, uy + 1.95, 2.4), Vector3(25.0, 0.3, 2.8))
	var u0 := uy + 2.1
	# Upper storey: the tholos.
	var tc := Vector3(0, u0, 3.0)
	lm.frustum("Facade", tc, 3.9, 3.9, 0.5, 24)
	lm.frustum("Facade", tc, 2.9, 2.9, 9.0, 24)
	for i in 7:
		var a := PI * (-0.05 + 1.1 * float(i) / 6.0)
		LandmarkDetail.column(lm, "Facade", tc + Vector3(cos(a) * 3.5, 0.5, sin(a) * 3.5), 0.36, 8.2,
			"corinthian", 0)
	LandmarkKits.statue_figure(lm, "Facade", tc + Vector3(0, 0.5, 3.1), 3.4)
	var ty := u0 + 8.7
	lm.frustum("Facade", tc + Vector3(0, 8.7, 0), 4.0, 4.0, 1.1, 24)
	lm.frustum("Facade", tc + Vector3(0, 9.8, 0), 4.2, 4.3, 0.5, 24)
	# Tent roof, then the Corinthian capital and the urn.
	var rt := tc + Vector3(0, 10.3, 0)
	lm.lathe("Facade", rt, PackedVector2Array([Vector2(4.0, 0), Vector2(2.8, 1.0), Vector2(1.2, 2.6),
		Vector2(0.75, 3.2)]), 24)
	LandmarkDetail.column(lm, "Facade", rt + Vector3(0, 3.2, 0), 0.75, 2.4, "corinthian", 0)
	var urn := rt + Vector3(0, 5.6, 0)
	lm.lathe("Facade", urn, PackedVector2Array([Vector2(0.9, 0), Vector2(0.55, 0.36), Vector2(1.1, 0.96),
		Vector2(1.3, 1.56), Vector2(1.0, 2.16), Vector2(0.55, 2.52), Vector2(0.7, 2.76), Vector2(0.0, 3.1)]), 16)
	# Half-pavilions with the halves of the broken pediment.
	for s in [-1.0, 1.0]:
		for x in [5.4, 9.2, 11.1]:
			LandmarkDetail.column(lm, "Facade", Vector3(s * x, u0, 2.6), 0.42, 8.3, "corinthian", 0)
		LandmarkKits.statue_figure(lm, "Facade", Vector3(s * 7.3, u0 + 0.5, 2.4), 3.6, true)
		lm.box("Facade", Vector3(s * 8.3, u0 + 4.0, 1.4), Vector3(7.6, 8.0, 1.0))
		lm.box("Facade", Vector3(s * 8.3, ty + 0.55, 2.6), Vector3(7.4, 1.1, 1.6))
		lm.box("Facade", Vector3(s * 8.3, ty + 1.3, 2.7), Vector3(7.6, 0.4, 1.8))
		# Half gable rising toward the tholos.
		var lo := Vector3(s * 12.1, ty + 1.5, 2.7)
		var hi := Vector3(s * 4.6, ty + 4.1, 2.7)
		var foot := Vector3(s * 4.6, ty + 1.5, 2.7)
		var n := Vector3(0, 0, 1)
		for zz in [1.8, 3.6]:
			lm.tri("Facade", lo + Vector3(0, 0, zz - 2.7), hi + Vector3(0, 0, zz - 2.7), foot + Vector3(0, 0, zz - 2.7),
				n, n, n, Vector2.ZERO, Vector2(7.5, 2.6), Vector2(7.5, 0))
		lm.beam("Facade", lo + Vector3(0, 0.25, 0.6), hi + Vector3(0, 0.25, 0.6), 0.5, 0.6)
		lm.quad("Facade", lo + Vector3(0, 0, 0.9), hi + Vector3(0, 0, 0.9), hi + Vector3(0, 0, -0.9),
			lo + Vector3(0, 0, -0.9), Vector3(2.6 * s, 7.5, 0).normalized())
		lm.quad("Facade", foot + Vector3(0, 0, 0.9), hi + Vector3(0, 0, 0.9), hi + Vector3(0, 0, -0.9),
			foot + Vector3(0, 0, -0.9), Vector3(-s, 0, 0))
		_petra_eagle(lm, hi + Vector3(0, 0.1, 0))
		_petra_eagle(lm, lo + Vector3(s * -0.4, 0.1, 0))
	lm.commit(model)

## Sandstone cliff round the facade: the back mass and the side walls of
## the little plaza, built of offset strata so the rock reads layered.
static func _petra_cliff(lm: LandmarkMesh) -> void:
	for k in 9:
		var y0 := 4.5 * float(k)
		var y1 := minf(y0 + 4.5, 40.5)
		var j := sin(float(k) * 2.3) * 1.2
		var back := PackedVector2Array([Vector2(-13.0, -1.0), Vector2(-13.0, 9.0 - j),
			Vector2(-18.0 + j, 14.0), Vector2(-30.0, 16.0 + j), Vector2(-40.0 - j, 10.0), Vector2(-42.0, -16.0),
			Vector2(-34.0, -30.0 + j), Vector2(30.0, -32.0), Vector2(41.0 + j, -14.0), Vector2(40.0, 12.0 - j),
			Vector2(28.0, 17.0), Vector2(17.0 - j, 13.0), Vector2(13.0, 8.0 + j), Vector2(13.0, -1.0)])
		lm.poly_prism("Cliff", _jitter(back, k), y0, y1)
	# Rock over the facade: the overhang above the urn.
	lm.box("Cliff", Vector3(0, 39.9, -3.0), Vector3(30, 1.2, 4.0))

## Polygon `p` with each vertex nudged by a deterministic offset per
## stratum `k` (so the cliff's layers step in and out).
static func _jitter(p: PackedVector2Array, k: int) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in p.size():
		var v := p[i]
		if absf(absf(v.x) - 13.0) < 0.01 or v.y == -1.0:
			out.append(v)
			continue
		var a := float(i) * 1.7 + float(k) * 0.9
		out.append(v + Vector2(sin(a), cos(a * 1.3)) * 0.9)
	return out

## Doorway at `c` (bottom centre on the wall) w x h: architrave frame, a
## pediment-capped head, the dark opening.
static func _petra_door(lm: LandmarkMesh, c: Vector3, w: float, h: float) -> void:
	lm.box("Door", c + Vector3(0, h * 0.5, 0.02), Vector3(w, h, 0.1), Basis(), 0.0)
	for s in [-1.0, 1.0]:
		lm.box("Facade", c + Vector3(s * (w * 0.5 + 0.25), h * 0.5, 0.2), Vector3(0.5, h, 0.4))
	lm.box("Facade", c + Vector3(0, h + 0.3, 0.25), Vector3(w + 1.4, 0.6, 0.5))
	lm.gable("Facade", c + Vector3(0, h + 0.6, 0.3), w + 1.4, 0.6, 0.9, Basis(), 0.0, "Facade")

## Recumbent lion acroterion at the pediment's foot.
static func _petra_lion(lm: LandmarkMesh, p: Vector3) -> void:
	lm.box("Facade", p + Vector3(0, 0.45, 0), Vector3(1.6, 0.9, 0.8))
	lm.box("Facade", p + Vector3(-signf(p.x) * 0.9, 0.95, 0), Vector3(0.6, 0.8, 0.7))

## Eagle on a pediment peak: body, folded wings, head.
static func _petra_eagle(lm: LandmarkMesh, p: Vector3) -> void:
	lm.lathe("Facade", p, PackedVector2Array([Vector2(0.3, 0), Vector2(0.42, 0.4), Vector2(0.3, 0.9),
		Vector2(0.15, 1.1)]), 8, 1.0, 0.8)
	for s in [-1.0, 1.0]:
		lm.beam("Facade", p + Vector3(s * 0.25, 0.9, 0), p + Vector3(s * 0.7, 0.3, -0.1), 0.35, 0.12)
	LandmarkMaParts.sphere(lm, "Facade", p + Vector3(0, 1.25, 0.1), 0.18, 8, 4)

# --- Abu Simbel ---

## Terrace level in front of the temples.
const AS_G := 0.6

## Ramesses II's Great Temple (c. 1264 BC, moved 1964-68): a 38 m wide,
## 33 m high battered rock facade framed by torus mouldings, four seated
## 20 m colossi in double crowns (the one south of the door broken, its
## head and torso at its feet), Ra-Horakhty in his niche over the door,
## the inscription band, cavetto cornice and the frieze of 22 baboons;
## and, to the north (-Z), the Small Temple of Hathor and Nefertari,
## 28 m long, with six 10 m standing statues between seven buttresses.
## Both face east (+X), backed by the artificial hill.
static func abu_simbel(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Sandstone", LandmarkMaterials.pbr("stone", "#C79B64", 4.0))
	lm.use("Hill", LandmarkMaterials.pbr("stone", "#A9825A", 8.0))
	lm.use("Door", LandmarkMaterials.glass("#1A1510"))
	lm.use("Terrace", LandmarkMaterials.pbr("sand", "#D9BE8A", 8.0))
	var g := AS_G
	lm.box("Terrace", Vector3(14, g * 0.5, -45), Vector3(32, g, 160))
	_hill(lm, 0.0, 26.0, 19.7, 32.4, 60.0)
	# Great Temple facade: battered face, torus edges, cornice, baboons.
	lm.quad("Sandstone", Vector3(0.0, g, -19.0), Vector3(0.0, g, 19.0), Vector3(-3.0, 30.0, 19.0),
		Vector3(-3.0, 30.0, -19.0), Vector3(1, 0.1, 0).normalized())
	for s in [-1.0, 1.0]:
		lm.beam("Sandstone", Vector3(0.3, g, s * 19.0), Vector3(-2.7, 30.0, s * 19.0), 0.9, 0.9)
	lm.beam("Sandstone", Vector3(-2.6, 29.6, -19.4), Vector3(-2.6, 29.6, 19.4), 0.8, 0.8)
	_cavetto(lm, Vector3(-3.0, 30.0, 0), 39.0)
	for i in 22:
		_baboon(lm, Vector3(-2.4, 31.4, -18.4 + 36.8 * float(i) / 21.0))
	# Inscription band under the cornice and the dedication niche.
	lm.box("Sandstone", Vector3(-2.4, 27.8, 0), Vector3(0.4, 1.2, 34))
	for i in 34:
		lm.box("Door", Vector3(-2.18, 27.8, -16.5 + float(i)), Vector3(0.05, 0.8, 0.12), Basis(), 0.0)
	lm.box("Door", Vector3(-1.9, 21.0, 0), Vector3(0.4, 6.5, 3.4), Basis(), 0.0)
	_ra_horakhty(lm, Vector3(-1.6, 18.0, 0))
	for s in [-1.0, 1.0]:
		lm.box("Sandstone", Vector3(-1.2, 21.0, s * 2.0), Vector3(1.0, 7.0, 0.6))
	lm.box("Sandstone", Vector3(-1.2, 24.7, 0), Vector3(1.0, 0.6, 4.6))
	# Door with its jambs and lintel.
	lm.box("Door", Vector3(0.05, g + 3.6, 0), Vector3(0.4, 7.2, 4.4), Basis(), 0.0)
	for s in [-1.0, 1.0]:
		lm.box("Sandstone", Vector3(0.3, g + 3.8, s * 2.6), Vector3(0.8, 7.6, 0.8))
	lm.box("Sandstone", Vector3(0.3, g + 8.0, 0), Vector3(0.9, 0.9, 6.0))
	for z in [-15.0, -5.6, 5.6, 15.0]:
		_colossus(lm, Vector3(0.0, g, z), is_equal_approx(z, 5.6))
	# Small Temple of Hathor and Nefertari.
	var sz := -95.0
	_hill(lm, sz, 18.0, 15.0, 15.0, 30.0)
	lm.quad("Sandstone", Vector3(0.0, g, sz - 14.0), Vector3(0.0, g, sz + 14.0), Vector3(-1.4, 12.5, sz + 14.0),
		Vector3(-1.4, 12.5, sz - 14.0), Vector3(1, 0.1, 0).normalized())
	lm.box("Sandstone", Vector3(-1.0, 12.8, sz), Vector3(2.4, 0.9, 29))
	for i in 7:
		var z := sz - 13.5 + 4.5 * float(i)
		if i == 3:
			lm.box("Door", Vector3(0.05, g + 2.6, z), Vector3(0.4, 5.2, 2.6), Basis(), 0.0)
			lm.box("Sandstone", Vector3(0.3, g + 6.2, z), Vector3(0.8, 2.0, 3.0))
			continue
		var top := 12.2
		lm.box("Sandstone", Vector3(0.4, (g + top) * 0.5, z), Vector3(2.2 - 0.8 * float(i % 2), top - g, 1.6))
		# Hieroglyph column down each buttress face.
		for k in 8:
			lm.box("Door", Vector3(1.52 - 0.4 * float(i % 2), g + 1.6 + 1.2 * float(k), z), Vector3(0.04, 0.7, 0.5),
				Basis(), 0.0)
	for i in 6:
		var z := sz - 11.25 + 4.5 * float(i)
		var queen := i == 1 or i == 4
		LandmarkKits.statue_figure(lm, "Sandstone", Vector3(0.9, g, z), 9.6)
		var head := Vector3(0.9, g + 9.6, z)
		if queen:
			# Hathor crown: sun disc between cow horns, two plumes.
			lm.disc("Sandstone", head + Vector3(0.0, 0.7, 0), Vector3.RIGHT, 0.5, 12)
			for s in [-1.0, 1.0]:
				lm.beam("Sandstone", head + Vector3(0, 0.6, s * 0.3), head + Vector3(0, 1.6, s * 0.12), 0.12, 0.2)
		else:
			lm.lathe("Sandstone", head + Vector3(0, -0.1, 0), PackedVector2Array([Vector2(0.45, 0),
				Vector2(0.38, 0.4), Vector2(0.3, 0.8), Vector2(0.18, 1.1), Vector2(0.0, 1.2)]), 10)
	lm.commit(model)

## Stepped rock mound whose front (x ~ 0) is the temple face: layers
## narrowing from half-width `hw0` to `hw1` and shortening backwards, `h`
## high, `depth` m deep.
static func _hill(lm: LandmarkMesh, z0: float, hw0: float, hw1: float, h: float,
		depth: float) -> void:
	var n := 10
	for i in n:
		var hw := lerpf(hw0, hw1, float(i) / (n - 1))
		var front := -0.6 - 0.25 * i
		var back := -(depth - (depth - 18.0) * float(i) / (n - 1))
		var j := sin(float(i) * 1.9) * 1.2
		var poly := PackedVector2Array([Vector2(front, z0 - hw), Vector2(back * 0.6, z0 - hw - 2.0 + j),
			Vector2(back, z0 - hw * 0.5), Vector2(back - 2.0, z0 + j), Vector2(back, z0 + hw * 0.5),
			Vector2(back * 0.6, z0 + hw + 2.0 - j), Vector2(front, z0 + hw)])
		lm.poly_prism("Hill", poly, AS_G + (h - AS_G) * i / n, AS_G + (h - AS_G) * (i + 1) / n)

## Egyptian cavetto cornice `length` m along Z at the facade top.
static func _cavetto(lm: LandmarkMesh, base: Vector3, length: float) -> void:
	var rows: Array = []
	for q in [[0.0, 0.0], [0.15, 0.5], [0.5, 0.95], [1.1, 1.25], [1.6, 1.35], [1.6, 1.6], [0.0, 1.6]]:
		var off := Vector3(float(q[0]), float(q[1]), 0)
		rows.append(PackedVector3Array([base + off - Vector3(0, 0, length * 0.5),
			base + off + Vector3(0, 0, length * 0.5)]))
	lm.grid("Sandstone", rows, Vector3(1, 0.3, 0))

## Squatting baboon with raised forepaws, facing +X.
static func _baboon(lm: LandmarkMesh, p: Vector3) -> void:
	lm.box("Sandstone", p + Vector3(0, 0.25, 0), Vector3(0.9, 0.5, 1.2))
	lm.lathe("Sandstone", p + Vector3(0.1, 0.5, 0), PackedVector2Array([Vector2(0.38, 0), Vector2(0.42, 0.5),
		Vector2(0.3, 1.0), Vector2(0.0, 1.1)]), 8, 0.9, 1.0)
	LandmarkMaParts.sphere(lm, "Sandstone", p + Vector3(0.2, 1.55, 0), 0.3, 8, 4)
	for s in [-1.0, 1.0]:
		lm.beam("Sandstone", p + Vector3(0.3, 0.9, s * 0.3), p + Vector3(0.5, 1.6, s * 0.36), 0.16, 0.16)

## Falcon-headed Ra-Horakhty standing in the niche, sun disc on his head.
static func _ra_horakhty(lm: LandmarkMesh, p: Vector3) -> void:
	LandmarkKits.statue_figure(lm, "Sandstone", p, 5.4)
	lm.beam("Sandstone", p + Vector3(0, 4.8, 0), p + Vector3(0.5, 4.75, 0), 0.25, 0.22)
	lm.disc("Sandstone", p + Vector3(0.1, 5.9, 0), Vector3.RIGHT, 0.6, 12)

## Seated colossus 20 m tall (crown top) at the facade, face toward +X:
## throne, shins and feet, thighs with the hands on the knees, the
## pleated kilt, torso, nemes with lappets, false beard and the double
## crown, with a small family statue by each leg. `broken` drops the
## head and torso to the ground in front, as since the ancient quake.
static func _colossus(lm: LandmarkMesh, base: Vector3, broken: bool) -> void:
	lm.box("Sandstone", base + Vector3(-1.2, 4.6, 0), Vector3(3.6, 9.2, 7.4))
	for s in [-1.0, 1.0]:
		var lz: float = base.z + s * 1.55
		lm.box("Sandstone", Vector3(base.x + 4.6, base.y + 4.1, lz), Vector3(2.0, 8.2, 2.3))
		lm.box("Sandstone", Vector3(base.x + 6.0, base.y + 0.55, lz), Vector3(2.8, 1.1, 2.0))
		lm.box("Sandstone", Vector3(base.x + 2.6, base.y + 9.0, lz), Vector3(6.4, 1.8, 2.6))
		# Queen or prince standing by the leg.
		LandmarkKits.statue_figure(lm, "Sandstone", Vector3(base.x + 6.0, base.y + 1.1, base.z + s * 3.4), 4.6)
	# Kilt front panel between the thighs.
	lm.box("Sandstone", base + Vector3(3.8, 7.6, 0), Vector3(1.2, 3.0, 1.4))
	var tb := base + Vector3(0.9, 9.9, 0)
	if broken:
		# The fallen bust lying in front of the knees.
		lm.lathe("Sandstone", base + Vector3(9.5, 1.6, -0.5), PackedVector2Array([Vector2(1.5, 0),
			Vector2(2.2, 2.5), Vector2(1.6, 4.6), Vector2(0.9, 5.0)]), 10, 1.0, 0.7, 0.4)
		lm.box("Sandstone", base + Vector3(9.0, 1.2, 3.6), Vector3(3.4, 2.4, 3.2), Basis(Vector3.UP, 0.5))
		lm.box("Sandstone", tb + Vector3(0, 0.4, 0), Vector3(3.2, 0.8, 5.4))
		return
	lm.lathe("Sandstone", tb, PackedVector2Array([Vector2(2.4, 0), Vector2(2.2, 1.6), Vector2(2.6, 3.4),
		Vector2(2.9, 4.9), Vector2(1.6, 5.6)]), 14, 0.6, 1.0)
	for s in [-1.0, 1.0]:
		var sh := tb + Vector3(0.1, 4.8, s * 2.7)
		var el := tb + Vector3(1.4, 0.6, s * 2.1)
		lm.beam("Sandstone", sh, el, 1.3, 1.2)
		lm.beam("Sandstone", el, base + Vector3(5.2, 9.8, s * 1.7), 1.1, 0.9)
	# Head: nemes with its lappets, the face, false beard, double crown.
	var hb := tb + Vector3(0.3, 5.4, 0)
	lm.lathe("Sandstone", hb, PackedVector2Array([Vector2(2.3, 0), Vector2(2.1, 1.0), Vector2(1.7, 2.4),
		Vector2(1.2, 3.0)]), 12, 0.8, 1.0)
	for s in [-1.0, 1.0]:
		lm.box("Sandstone", hb + Vector3(1.1, -0.6, s * 1.5), Vector3(0.7, 3.0, 0.9))
	lm.box("Sandstone", hb + Vector3(1.4, 1.5, 0), Vector3(0.9, 2.4, 2.0))
	lm.box("Sandstone", hb + Vector3(1.75, 1.5, 0), Vector3(0.4, 0.7, 0.4))
	lm.box("Sandstone", hb + Vector3(1.6, -0.3, 0), Vector3(0.6, 1.4, 0.6))
	var cb := hb + Vector3(0, 2.9, 0)
	lm.frustum("Sandstone", cb, 1.6, 1.5, 0.9, 14)
	lm.lathe("Sandstone", cb + Vector3(0, 0.9, 0), PackedVector2Array([Vector2(1.1, 0), Vector2(1.0, 0.8),
		Vector2(0.75, 1.5), Vector2(0.45, 1.85), Vector2(0.0, 2.05)]), 14)
