class_name LandmarkAfhKairouan
extends RefCounted

## The Great Mosque of Kairouan (Mosque of Uqba, 836 / 862) in true
## metres. Origin at the centre of the 73 x 126 m enclosure, qibla
## (mihrab) wall to the south (+Z). Ochre stone walls 1.9 m thick with
## massive sloping buttresses, 4.25 m corner towers and round-topped
## merlons; the 67 x 52 m courtyard ringed by a double arcade on reused
## marble columns; the 13-arch portico before the prayer hall with its
## domed porch; the 70.6 x 37.5 m hypostyle hall under a flat roof with
## the raised T of nave and qibla aisle and the two ribbed domes (over
## the nave entrance and over the mihrab); the 31.5 m three-tier minaret
## in the middle of the north side; the domed gate porches Bab Lalla
## Rihana (east) and Bab al-Ma (west).

const HW := 36.5
const HD := 63.0
const CX := 26.0
const CZ0 := -52.0
const CZ1 := 14.0
const HALL_Z0 := 25.0
const GAL_H := 6.0

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#D0BA8F", 4.0))
	lm.use("Roof", LandmarkMaterials.pbr("render", "#E2D8C4", 4.0))
	lm.use("Court", LandmarkMaterials.pbr("pavement", "#DCCFB4", 5.0))
	lm.use("Column", LandmarkMaterials.pbr("limestone", "#E6DFD2", 2.0))
	lm.use("Dark", LandmarkMaterials.glass("#2A241C"))
	lm.box("Court", Vector3(0, -0.3, 0), Vector3(HW * 2.0 + 3.0, 0.6, HD * 2.0 + 3.0))
	lm.lathe("Column", Vector3(0, 0, (CZ0 + CZ1) * 0.5), PackedVector2Array([Vector2(1.6, 0), Vector2(1.6, 0.5),
		Vector2(1.3, 0.55), Vector2(1.3, 0.2), Vector2(0.0, 0.2)]), 16)
	_walls(lm)
	_galleries(lm)
	_hall(lm)
	_minaret(lm, Vector3(0, 0, -57.65))
	_gate(lm, Vector3(HW, 0, 38.0), Vector3(1, 0, 0))
	_gate(lm, Vector3(-HW, 0, -26.0), Vector3(-1, 0, 0))
	lm.commit(model)

static func _walls(lm: LandmarkMesh) -> void:
	var t := 1.9
	# Sides: 0 north, 1 south, 2 west, 3 east.
	for s in [-1.0, 1.0]:
		var top := 9.0
		lm.box("Stone", Vector3(s * (HW - t * 0.5), top * 0.5, 0), Vector3(t, top, HD * 2.0))
		_merlons(lm, Vector3(s * (HW - t * 0.5), top, -HD + 4.0), Vector3(s * (HW - t * 0.5), top, HD - 4.0))
		for z in range(-55, 56, 8):
			_buttress(lm, Vector3(s * HW, 0, float(z)), Vector3(s, 0, 0), top)
	lm.box("Stone", Vector3(0, 4.5, -HD + t * 0.5), Vector3(HW * 2.0, 9.0, t))
	lm.box("Stone", Vector3(0, 5.25, HD - t * 0.5), Vector3(HW * 2.0, 10.5, t))
	_merlons(lm, Vector3(-HW + 4.0, 9.0, -HD + t * 0.5), Vector3(-6.0, 9.0, -HD + t * 0.5))
	_merlons(lm, Vector3(6.0, 9.0, -HD + t * 0.5), Vector3(HW - 4.0, 9.0, -HD + t * 0.5))
	_merlons(lm, Vector3(-HW + 4.0, 10.5, HD - t * 0.5), Vector3(HW - 4.0, 10.5, HD - t * 0.5))
	for x in range(-28, 29, 8):
		_buttress(lm, Vector3(float(x), 0, -HD), Vector3(0, 0, -1), 9.0)
		if absf(float(x)) > 5.0:
			_buttress(lm, Vector3(float(x), 0, HD), Vector3(0, 0, 1), 10.5)
	# Corner towers, 4.25 m square, with their own merlons.
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var top := 12.0 if sz > 0.0 else 10.5
			var c := Vector3(sx * (HW - 1.6), 0, sz * (HD - 1.6))
			LandmarkAfhParts.tapered(lm, "Stone", Transform3D(Basis(), c), 0.0, top, 4.6, 4.6, 4.25, 4.25)
			lm.box("Stone", c + Vector3(0, top - 0.3, 0), Vector3(4.6, 0.4, 4.6))
			for e in 4:
				var rot := Basis(Vector3.UP, PI * 0.5 * float(e))
				var a: Vector3 = c + rot * Vector3(-1.8, 0, 1.9) + Vector3(0, top, 0)
				var b: Vector3 = c + rot * Vector3(1.8, 0, 1.9) + Vector3(0, top, 0)
				_merlons(lm, a, b)
	# Small gates into the court and the hall.
	for s in [-1.0, 1.0]:
		var out := Vector3(s, 0, 0)
		for z in [-43.0, -11.0, 5.0, 45.0]:
			LandmarkAfhDetail.niche(lm, "Stone", "Dark", Vector3(s * HW, 0, z), out, 2.4, 4.2, "horseshoe",
				0.4, 0.3, false)
	# The mihrab's projection from the qibla wall.
	lm.box("Stone", Vector3(0, 5.25, HD + 1.3), Vector3(7.6, 10.5, 2.6))

## Massive buttress against the wall at `p` (wall face point), sloping
## from 2.4 m deep at the foot to 0.7 m under the merlons, with a capped
## offset course halfway.
static func _buttress(lm: LandmarkMesh, p: Vector3, out: Vector3, top: float) -> void:
	var basis := Basis(Vector3.UP, atan2(out.x, out.z))
	var xf := Transform3D(basis, p)
	LandmarkAfhParts.tapered(lm, "Stone", Transform3D(basis, p + out * 1.2), 0.0, top * 0.5, 2.6, 2.4, 2.4, 1.6)
	LandmarkAfhParts.tapered(lm, "Stone", Transform3D(basis, p + out * 0.8), top * 0.5, top - 0.6, 2.2, 1.6,
		1.9, 0.8)
	LandmarkAfhParts.tapered(lm, "Stone", xf, top * 0.5 - 0.3, top * 0.5, 2.8, 3.6, 2.8, 3.6)

## Round-topped merlons every 1.6 m along a..b on the wall top.
static func _merlons(lm: LandmarkMesh, a: Vector3, b: Vector3) -> void:
	var n := maxi(int(a.distance_to(b) / 1.6), 1)
	var d := (b - a).normalized()
	var basis := Basis(d, Vector3.UP, d.cross(Vector3.UP))
	for i in n:
		var p := a.lerp(b, (float(i) + 0.5) / float(n))
		lm.box("Stone", p + Vector3(0, 0.3, 0), Vector3(0.8, 0.6, 0.6), basis, 0.0)
		lm.lathe("Stone", p + Vector3(0, 0.6, 0), LandmarkMaParts.dome_profile(0.4, 0.4, 3), 6, 1.0, 0.75)

## The double arcade round the court: horseshoe arches on reused marble
## columns, the outer row carrying the gallery roof; the portico before
## the prayer hall has thirteen arches with the domed porch in the middle.
static func _galleries(lm: LandmarkMesh) -> void:
	for s in [-1.0, 1.0]:
		var x: float = s * CX
		var out := Vector3(-s, 0, 0)
		LandmarkAfhDetail.arcade(lm, "Stone", "Column", Vector3(x, 0, CZ0), Vector3(x, 0, CZ1), out, 20,
			3.2, GAL_H, 0.9, 0.24)
		LandmarkAfhDetail.arcade(lm, "Stone", "Column", Vector3(x + s * 4.6, 0, CZ0), Vector3(x + s * 4.6, 0, CZ1),
			out, 20, 3.2, GAL_H - 0.4, 0.7, 0.22)
		lm.box("Roof", Vector3(s * (CX + 4.8), GAL_H + 0.25, (CZ0 + CZ1) * 0.5), Vector3(9.8, 0.5, CZ1 - CZ0 + 0.6))
		lm.quad("Dark", Vector3(s * (HW - 1.95), 0.02, CZ0), Vector3(s * (HW - 1.95), 0.02, CZ1),
			Vector3(s * (HW - 1.95), 4.5, CZ1), Vector3(s * (HW - 1.95), 4.5, CZ0), out)
		# North gallery either side of the minaret.
		var x0: float = s * 6.0
		var x1: float = s * CX
		LandmarkAfhDetail.arcade(lm, "Stone", "Column", Vector3(x0, 0, CZ0), Vector3(x1, 0, CZ0), Vector3(0, 0, 1),
			6, 3.2, GAL_H, 0.9, 0.24)
		lm.box("Roof", Vector3(s * 16.0, GAL_H + 0.25, (CZ0 - HD) * 0.5), Vector3(20.0, 0.5, HD + CZ0 + 0.6))
		lm.quad("Dark", Vector3(x0, 0.02, -HD + 1.95), Vector3(x1, 0.02, -HD + 1.95), Vector3(x1, 4.5, -HD + 1.95),
			Vector3(x0, 4.5, -HD + 1.95), Vector3(0, 0, 1))
		# Portico: six arches each side of the porch.
		LandmarkAfhDetail.arcade(lm, "Stone", "Column", Vector3(s * 3.6, 0, CZ1), Vector3(x1, 0, CZ1),
			Vector3(0, 0, -1), 6, 3.6, 7.0, 1.0, 0.26)
		LandmarkAfhDetail.arcade(lm, "Stone", "Column", Vector3(s * 3.6, 0, CZ1 + 5.0), Vector3(x1, 0, CZ1 + 5.0),
			Vector3(0, 0, -1), 6, 3.4, 7.0, 0.8, 0.24)
	lm.box("Roof", Vector3(0, 7.25, (CZ1 + HALL_Z0) * 0.5), Vector3(CX * 2.0, 0.5, HALL_Z0 - CZ1))
	lm.quad("Dark", Vector3(-CX, 0.02, HALL_Z0 - 0.05), Vector3(CX, 0.02, HALL_Z0 - 0.05),
		Vector3(CX, 5.0, HALL_Z0 - 0.05), Vector3(-CX, 5.0, HALL_Z0 - 0.05), Vector3(0, 0, -1))
	# The porch: a square base with the central horseshoe arch on paired
	# columns, then a ribbed dome on a dodecagonal drum with 16 windows.
	var pc := Vector3(0, 0, CZ1 + 2.6)
	for s in [-1.0, 1.0]:
		lm.box("Stone", pc + Vector3(s * 2.9, 3.5, 0), Vector3(1.4, 7.0, 5.6))
		for k in 2:
			LandmarkAfhDetail.drum_column(lm, "Column", pc + Vector3(s * 2.0, 0, -2.6 + 0.6 * float(k)), 0.25, 4.0, 1, 8)
	lm.box("Stone", pc + Vector3(0, 6.2, 0), Vector3(4.4, 1.6, 5.6))
	LandmarkAfhDetail.niche(lm, "Stone", "Dark", pc + Vector3(0, 0, -2.8), Vector3(0, 0, -1), 3.6, 5.4,
		"horseshoe", 0.4, 0.3, false)
	_ribbed_dome(lm, pc + Vector3(0, 7.0, 0), 2.4, 12, 1.6, 16, 0.0)

## Hypostyle hall: 17 aisles of 8 bays under a flat lime-washed roof; the
## central nave and the qibla aisle rise above it in a T, with the
## ribbed domes over the nave's entrance and over the mihrab.
static func _hall(lm: LandmarkMesh) -> void:
	var d := HD - 1.9 - HALL_Z0
	var zc := HALL_Z0 + d * 0.5
	lm.box("Stone", Vector3(0, 4.75, zc), Vector3(HW * 2.0 - 3.8, 9.5, d))
	lm.box("Roof", Vector3(0, 9.65, zc), Vector3(HW * 2.0 - 3.6, 0.3, d + 0.2))
	# Parapet round the roof terrace.
	for s in [-1.0, 1.0]:
		lm.box("Stone", Vector3(0, 10.2, HALL_Z0 + 0.15 + (d - 0.3) * (0.5 + float(s) * 0.5)),
			Vector3(HW * 2.0 - 3.8, 0.8, 0.3))
	# Raised nave and qibla aisle.
	lm.box("Stone", Vector3(0, 10.4, zc), Vector3(7.0, 1.6, d))
	lm.box("Roof", Vector3(0, 11.3, zc), Vector3(7.3, 0.2, d + 0.3))
	lm.box("Stone", Vector3(0, 10.4, HD - 1.9 - 3.4), Vector3(HW * 2.0 - 3.8, 1.6, 6.8))
	lm.box("Roof", Vector3(0, 11.3, HD - 1.9 - 3.4), Vector3(HW * 2.0 - 3.6, 0.2, 7.1))
	# Aisle lines on the roof: a low ridge over each arcade.
	for k in range(1, 9):
		for s in [-1.0, 1.0]:
			var x: float = s * (3.5 + 3.95 * float(k) - 3.95)
			if k > 1:
				lm.box("Roof", Vector3(x, 9.9, zc - 3.4), Vector3(0.6, 0.2, d - 6.8), Basis(), 0.0)
	# Clerestory windows of the raised nave and the hall's north front.
	for s in [-1.0, 1.0]:
		for k in 6:
			var z := HALL_Z0 + 2.5 + 4.0 * float(k)
			LandmarkAfhDetail.niche(lm, "Stone", "Dark", Vector3(s * 3.5, 9.9, z), Vector3(s, 0, 0), 0.8, 0.9,
				"round", 0.15, 0.12, false)
	for i in 14:
		var x := -HW + 4.6 + 4.9 * float(i)
		if absf(x) < 4.5:
			continue
		LandmarkAfhDetail.niche(lm, "Stone", "Dark", Vector3(x, 7.9, HALL_Z0), Vector3(0, 0, -1), 1.1, 1.4,
			"horseshoe", 0.2, 0.15, false)
	# Dome over the entrance of the nave (Bab el-Bahou, 862).
	_ribbed_dome(lm, Vector3(0, 11.4, HALL_Z0 + 3.0), 3.4, 8, 2.0, 20, 2.0)
	# Mihrab dome (836): square base with five niches on three faces,
	# octagonal drum, ribbed shell.
	_ribbed_dome(lm, Vector3(0, 11.4, HD - 1.9 - 4.0), 4.0, 8, 2.6, 24, 3.0)
	var mb := Vector3(0, 11.4, HD - 1.9 - 4.0)
	for e in 3:
		var out: Vector3 = [Vector3(1, 0, 0), Vector3(-1, 0, 0), Vector3(0, 0, -1)][e]
		var right := Vector3.UP.cross(out).normalized()
		for i in 5:
			LandmarkAfhDetail.niche(lm, "Stone", "Dark", mb + out * 4.6 + right * (float(i) - 2.0) * 1.6
				+ Vector3(0, 0.5, 0), out, 0.9, 1.9, "horseshoe", 0.16, 0.14, false)

## A square base `base_h` tall, a drum of `sides` faces with a window in
## each, and a ribbed dome of radius r with `ribs` ribs, at `at`.
static func _ribbed_dome(lm: LandmarkMesh, at: Vector3, r: float, sides: int, drum_h: float, ribs: int,
		base_h: float) -> void:
	if base_h > 0.0:
		lm.box("Stone", at + Vector3(0, base_h * 0.5, 0), Vector3(r * 2.3, base_h, r * 2.3))
		LandmarkAfhParts.merlon_ring(lm, "Stone", at + Vector3(0, base_h, 0), r * 1.15, r * 1.15, 0.5, 0.6)
	var top := at + Vector3(0, base_h, 0)
	lm.frustum("Stone", top, r * 1.06, r * 1.03, drum_h, sides, PI / float(sides))
	var wins := 16 if sides == 12 else sides
	for i in wins:
		var a := TAU * (float(i) + 0.5) / float(wins)
		var out := Vector3(cos(a), 0, sin(a))
		LandmarkAfhDetail.niche(lm, "Stone", "Dark", top + out * r * 0.98 + Vector3(0, drum_h * 0.2, 0), out,
			minf(0.7, r * 1.6 / float(wins) * 2.0), drum_h * 0.6, "round", 0.1, 0.1, false)
	lm.box("Stone", top + Vector3(0, drum_h + 0.1, 0), Vector3(r * 2.1, 0.2, r * 2.1), Basis(), 0.0)
	var dome_b := top + Vector3(0, drum_h, 0)
	lm.lathe("Roof", dome_b, LandmarkMaParts.dome_profile(r, r * 0.9, 6), ribs * 2)
	for i in ribs:
		var a := TAU * float(i) / float(ribs)
		var prev := dome_b + Vector3(cos(a) * r, 0, sin(a) * r)
		for k in range(1, 6):
			var t := PI * 0.5 * float(k) / 5.0
			var p := dome_b + Vector3(cos(a) * r * cos(t), r * 0.9 * sin(t), sin(a) * r * cos(t))
			lm.beam("Roof", prev, p, 0.2, 0.16)
			prev = p
	lm.frustum("Stone", dome_b + Vector3(0, r * 0.88, 0), 0.25, 0.15, 0.4, 6)

## Square minaret of three tapering tiers: 10.7 m wide at the foot,
## tier 1 to 19.2 m and tier 2 to 27.3 m each crowned by round-topped
## merlons, tier 3 a lantern with a blind arcade under a small ribbed
## dome at 31.5 m. Stacked windows face the court (south), arrow-loops
## the other sides; the door is framed by reused Roman friezes.
static func _minaret(lm: LandmarkMesh, b: Vector3) -> void:
	var xf := Transform3D(Basis(), b)
	LandmarkAfhParts.tapered(lm, "Stone", xf, 0.0, 19.2, 10.7, 10.7, 9.4, 9.4)
	lm.box("Stone", b + Vector3(0, 19.4, 0), Vector3(10.0, 0.4, 10.0))
	LandmarkAfhParts.tapered(lm, "Stone", xf, 19.2, 27.0, 6.6, 6.6, 5.8, 5.8)
	lm.box("Stone", b + Vector3(0, 27.15, 0), Vector3(6.4, 0.3, 6.4))
	LandmarkAfhParts.tapered(lm, "Stone", xf, 27.0, 29.4, 4.0, 4.0, 3.8, 3.8)
	lm.box("Stone", b + Vector3(0, 29.5, 0), Vector3(4.3, 0.2, 4.3))
	lm.lathe("Roof", b + Vector3(0, 29.6, 0), LandmarkMaParts.dome_profile(1.85, 1.6, 5), 16)
	for i in 8:
		var a := TAU * float(i) / 8.0
		var prev := b + Vector3(cos(a) * 1.9, 29.6, sin(a) * 1.9)
		for k in range(1, 5):
			var t := PI * 0.5 * float(k) / 4.0
			var p := b + Vector3(cos(a) * 1.9 * cos(t), 29.6 + 1.62 * sin(t), sin(a) * 1.9 * cos(t))
			lm.beam("Roof", prev, p, 0.14, 0.1)
			prev = p
	lm.frustum("Stone", b + Vector3(0, 31.1, 0), 0.15, 0.05, 0.4, 6)
	var faces: Array[Vector3] = [Vector3(0, 0, 1), Vector3(1, 0, 0), Vector3(0, 0, -1), Vector3(-1, 0, 0)]
	for f in 4:
		var out: Vector3 = faces[f]
		var right := Vector3.UP.cross(out).normalized()
		_merlons(lm, b + out * 4.75 - right * 4.4 + Vector3(0, 19.6, 0), b + out * 4.75 + right * 4.4 + Vector3(0, 19.6, 0))
		_merlons(lm, b + out * 2.95 - right * 2.6 + Vector3(0, 27.3, 0), b + out * 2.95 + right * 2.6 + Vector3(0, 27.3, 0))
		if f == 0:
			for y in [3.2, 8.4, 13.6]:
				var hw := lerpf(5.35, 4.7, float(y) / 19.2)
				LandmarkAfhDetail.niche(lm, "Stone", "Dark", b + out * hw + Vector3(0, y, 0), out, 1.1, 2.2,
					"horseshoe", 0.24, 0.2)
			LandmarkAfhDetail.niche(lm, "Stone", "Dark", b + out * 3.15 + Vector3(0, 21.6, 0), out, 1.0, 2.2,
				"horseshoe", 0.22, 0.18)
		else:
			for y in [4.0, 9.5, 15.0]:
				var hw := lerpf(5.35, 4.7, float(y) / 19.2)
				LandmarkAfhDetail.niche(lm, "Stone", "Dark", b + out * hw + Vector3(0, y, 0), out, 0.35, 1.6,
					"rect", 0.18, 0.14, false)
			LandmarkAfhDetail.niche(lm, "Stone", "Dark", b + out * 3.15 + Vector3(0, 22.0, 0), out, 0.35, 1.5,
				"rect", 0.16, 0.12, false)
		# Lantern: three blind arches per face.
		for u in [-1.1, 0.0, 1.1]:
			LandmarkAfhDetail.niche(lm, "Stone", "Dark", b + out * 1.98 + right * float(u) + Vector3(0, 27.6, 0), out,
				0.7, 1.4, "horseshoe", 0.12, 0.1, false)
	# Door framed by reused Roman lintels.
	var door := b + Vector3(0, 0, 5.35)
	LandmarkAfhDetail.niche(lm, "Stone", "Dark", door, Vector3(0, 0, 1), 1.6, 3.0, "rect", 0.4, 0.3, false)
	lm.box("Column", door + Vector3(0, 3.6, 0.3), Vector3(3.4, 0.6, 0.5))

## Projecting gate porch on the outer wall at `p`, facing `out`: a deep
## horseshoe arch in an alfiz with a blind arcade frieze over it,
## buttressed corners, merlons and a ribbed dome on squinches.
static func _gate(lm: LandmarkMesh, p: Vector3, out: Vector3) -> void:
	var right := Vector3.UP.cross(out).normalized()
	var basis := Basis(right, Vector3.UP, out)
	var c := p + out * 2.0
	lm.box("Stone", c + Vector3(0, 5.25, 0), Vector3(8.0, 10.5, 4.0), basis)
	for s in [-1.0, 1.0]:
		lm.box("Stone", c + right * 4.3 * float(s) + out * 0.6 + Vector3(0, 4.5, 0), Vector3(1.2, 9.0, 3.0), basis)
	var face := c + out * 2.0
	LandmarkAfhDetail.niche(lm, "Stone", "Dark", face, out, 3.0, 5.6, "horseshoe", 0.45, 0.35, false)
	LandmarkAfhDetail.alfiz(lm, "Stone", face, out, 4.8, 6.6, 0.3, 0.2)
	for i in 5:
		LandmarkAfhDetail.niche(lm, "Stone", "Dark", face + right * (float(i) - 2.0) * 1.3 + Vector3(0, 7.4, 0), out,
			0.8, 1.8, "horseshoe", 0.14, 0.12, false)
	var top := Vector3(0, 10.5, 0)
	_merlons(lm, c + top + out * 1.7 - right * 3.6, c + top + out * 1.7 + right * 3.6)
	for s in [-1.0, 1.0]:
		_merlons(lm, c + top + right * 3.7 * float(s) - out * 1.6, c + top + right * 3.7 * float(s) + out * 1.6)
	_ribbed_dome(lm, c + Vector3(0, 10.5, 0), 1.7, 8, 1.0, 12, 0.0)
