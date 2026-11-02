class_name LandmarkRmAColumns
extends RefCounted

## Trajan's Column, the Column of Marcus Aurelius and the Pyramid of
## Cestius with the Porta San Paolo, in true metres.

# --- Trajan's Column ----------------------------------------------------

## 38.5 m: the 5.4 m pedestal (its die heaped with captured Dacian arms,
## eagles at the corners carrying laurel garlands, the door on the
## south-east with the dedication tablet held by two Victories), the
## laurel torus, the 3.7 m, 20-drum Carrara shaft with the 23-turn,
## 190 m Dacian frieze and the slit windows of the 185-step stair, the
## Doric capital with its egg-and-dart, the railed platform and the
## bronze St Peter that Sixtus V set up in 1587.
static func trajan(model: Node3D) -> void:
	var lm := RmAMesh.new()
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#D5CDBB", 3.0))
	lm.use("Relief", LandmarkMaterials.pbr("limestone", "#B3A892", 2.0))
	lm.use("Steps", LandmarkMaterials.pbr("limestone", "#BDB197", 3.0))
	lm.use("Bronze", LandmarkMaterials.paint("#5E6B4F", 0.5, 0.5))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#4F463A", 3.0))
	lm.box("Steps", Vector3(0, 0.2, 0), Vector3(7.6, 0.4, 7.6))
	# Pedestal: plinth mouldings, die, cornice.
	lm.box("Marble", Vector3(0, 0.6, 0), Vector3(6.0, 0.4, 6.0))
	lm.box("Marble", Vector3(0, 0.9, 0), Vector3(5.7, 0.2, 5.7))
	lm.box("Marble", Vector3(0, 2.9, 0), Vector3(5.4, 3.8, 5.4))
	lm.box("Marble", Vector3(0, 4.9, 0), Vector3(5.6, 0.2, 5.6))
	lm.box("Marble", Vector3(0, 5.2, 0), Vector3(5.9, 0.4, 5.9))
	for k in 4:
		var a := PI * 0.5 * float(k)
		var out := Vector3(sin(a), 0, cos(a))
		var right := Vector3.UP.cross(out)
		var face := out * 2.7
		if k == 0:
			# The door and the tablet with the dedication of AD 113.
			LandmarkDetail.window(lm, "Marble", "Shadow", face + Vector3(0, 2.05, 0), out, 1.0, 1.9, false, 0.2)
			RmADetail.panel(lm, "Marble", "Marble", face + Vector3(0, 3.95, 0), out, 2.4, 1.1, 0.08, 0.14)
			RmADetail.inscription(lm, "Shadow", face + Vector3(0, 3.95, 0) + out * 0.08, out, 2.2, 0.95, 6, 1.0)
			for s in [-1.0, 1.0]:
				RmADetail.victory(lm, "Relief", face + right * float(s) * 1.75 + Vector3(0, 3.9, 0), out, -float(s), 1.2)
				_trophy(lm, face + right * float(s) * 2.0 + Vector3(0, 1.4, 0), out, 0.9, float(k) + float(s))
		else:
			for i in 3:
				for j in 2:
					_trophy(lm, face + right * (-1.6 + 1.6 * float(i)) + Vector3(0, 1.6 + 1.3 * float(j), 0), out,
						1.2, float(k * 7 + i * 3 + j))
	# Corner eagles holding the laurel garlands.
	for k in 4:
		var a := PI * 0.25 + PI * 0.5 * float(k)
		var d := Vector3(sin(a), 0, cos(a))
		RmADetail.eagle(lm, "Relief", d * 3.9 + Vector3(0, 3.95, 0), d, 0.95)
		var a2 := a + PI * 0.5
		var d2 := Vector3(sin(a2), 0, cos(a2))
		var mid := (d + d2).normalized()
		RmADetail.garland(lm, "Relief", d * 4.0 + Vector3(0, 4.55, 0),
			d2 * 4.0 + Vector3(0, 4.55, 0), mid, 0.55, 0.22, 8)
	# Laurel torus at the foot of the shaft.
	_laurel_torus(lm, Vector3(0, 5.4, 0), 2.6, 1.0)
	_spiral_shaft(lm, Vector3(0, 6.4, 0), 27.3, 1.85, 1.6, 23.0, 43)
	_capital(lm, Vector3(0, 33.7, 0), 1.6, 4.6)
	# Platform railing and the drum carrying St Peter with his keys.
	_railing(lm, Vector3(0, 35.0, 0), 2.2)
	lm.lathe("Marble", Vector3(0, 35.0, 0), PackedVector2Array([Vector2(0.95, 0), Vector2(0.95, 0.1),
		Vector2(0.8, 0.2), Vector2(0.78, 0.4), Vector2(0.9, 0.45), Vector2(0.9, 0.55)]), 20)
	LandmarkKits.statue_figure(lm, "Bronze", Vector3(0, 35.55, 0), 2.95, true)
	lm.commit(model)

# --- Column of Marcus Aurelius ---------------------------------------

## 42 m: Domenico Fontana's 8.4 m pedestal of 1589 (the antique base is
## buried) with its moulded plinth, inscribed panels on all four sides
## and cornice, the laurel torus, the 29.6 m Doric shaft with the
## 21-turn Marcomannic frieze and its 56 slit windows, the capital,
## railed platform and the bronze St Paul.
static func marcus_aurelius(model: Node3D) -> void:
	var lm := RmAMesh.new()
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#D2CAB8", 3.0))
	lm.use("Relief", LandmarkMaterials.pbr("limestone", "#AFA48E", 2.0))
	lm.use("Steps", LandmarkMaterials.pbr("limestone", "#BDB197", 3.0))
	lm.use("Bronze", LandmarkMaterials.paint("#5E6B4F", 0.5, 0.5))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#4F463A", 3.0))
	lm.box("Steps", Vector3(0, 0.15, 0), Vector3(8.4, 0.3, 8.4))
	lm.box("Steps", Vector3(0, 0.5, 0), Vector3(7.2, 0.4, 7.2))
	lm.box("Marble", Vector3(0, 1.1, 0), Vector3(6.2, 0.8, 6.2))
	lm.box("Marble", Vector3(0, 1.6, 0), Vector3(5.9, 0.2, 5.9))
	lm.box("Marble", Vector3(0, 4.7, 0), Vector3(5.6, 6.2, 5.6))
	lm.box("Marble", Vector3(0, 7.9, 0), Vector3(5.85, 0.2, 5.85))
	LandmarkDetail.cornice(lm, "Marble", Vector3(-2.8, 7.9, 2.8), Vector3(2.8, 7.9, 2.8), Vector3.BACK, 0.5, true)
	LandmarkDetail.cornice(lm, "Marble", Vector3(2.8, 7.9, -2.8), Vector3(-2.8, 7.9, -2.8), Vector3.FORWARD, 0.5, true)
	LandmarkDetail.cornice(lm, "Marble", Vector3(2.8, 7.9, 2.8), Vector3(2.8, 7.9, -2.8), Vector3.RIGHT, 0.5, true)
	LandmarkDetail.cornice(lm, "Marble", Vector3(-2.8, 7.9, -2.8), Vector3(-2.8, 7.9, 2.8), Vector3.LEFT, 0.5, true)
	lm.box("Marble", Vector3(0, 8.2, 0), Vector3(5.6, 0.4, 5.6))
	for k in 4:
		var a := PI * 0.5 * float(k)
		var out := Vector3(sin(a), 0, cos(a))
		RmADetail.panel(lm, "Marble", "Marble", out * 2.8 + Vector3(0, 4.9, 0), out, 3.6, 3.6, 0.08, 0.2)
		RmADetail.inscription(lm, "Shadow", out * 2.88 + Vector3(0, 4.9, 0), out, 3.2, 3.2, 9, float(k))
	_laurel_torus(lm, Vector3(0, 8.4, 0), 2.5, 0.9)
	_spiral_shaft(lm, Vector3(0, 9.3, 0), 27.4, 1.95, 1.75, 21.0, 56)
	_capital(lm, Vector3(0, 36.7, 0), 1.75, 4.7)
	_railing(lm, Vector3(0, 38.0, 0), 2.25)
	lm.lathe("Marble", Vector3(0, 38.0, 0), PackedVector2Array([Vector2(0.9, 0), Vector2(0.9, 0.1),
		Vector2(0.78, 0.2), Vector2(0.76, 0.35), Vector2(0.85, 0.4)]), 20)
	LandmarkKits.statue_figure(lm, "Bronze", Vector3(0, 38.4, 0), 3.6, true)
	lm.commit(model)

## A heap of captured arms in relief at `c` on a face looking `out`:
## oval shields, a helmet, crossed spears and a cuirass.
static func _trophy(lm: LandmarkMesh, c: Vector3, out: Vector3, s: float, seed_v: float) -> void:
	var right := Vector3.UP.cross(out).normalized()
	var sq := Vector2(1.0, 0.25) if absf(out.z) > absf(out.x) else Vector2(0.25, 1.0)
	for i in 3:
		var f := sin(seed_v * 3.7 + float(i) * 2.1)
		var p := c + right * s * (-0.35 + 0.35 * float(i)) + Vector3(0, s * 0.1 * f, 0) + out * 0.02
		lm.disc("Relief", p + out * 0.06, out, s * 0.22, 10)
		RmADetail.ring_frame(lm, "Relief", p, out, s * 0.22, s * 0.05, 0.08, 10)
	for sd in [-1.0, 1.0]:
		lm.beam("Relief", c + right * float(sd) * s * 0.5 - Vector3(0, s * 0.4, 0) + out * 0.05,
			c - right * float(sd) * s * 0.4 + Vector3(0, s * 0.45, 0) + out * 0.05, s * 0.05, s * 0.05, out)
	lm.lathe("Relief", c + Vector3(0, s * 0.25, 0), PackedVector2Array([Vector2(s * 0.15, 0),
		Vector2(s * 0.14, s * 0.12), Vector2(s * 0.08, s * 0.22), Vector2(0, s * 0.25)]), 8, sq.x, sq.y)
	lm.lathe("Relief", c - Vector3(0, s * 0.42, 0), PackedVector2Array([Vector2(s * 0.18, 0),
		Vector2(s * 0.2, s * 0.15), Vector2(s * 0.16, s * 0.3)]), 8, sq.x, sq.y)

## The laurel-wreath torus at the foot of the shaft: the swelling roll
## and its crossed leaves bound in pairs.
static func _laurel_torus(lm: LandmarkMesh, base: Vector3, r: float, h: float) -> void:
	lm.lathe("Marble", base, PackedVector2Array([Vector2(r, 0), Vector2(r + 0.12, h * 0.15),
		Vector2(r + 0.18, h * 0.35), Vector2(r + 0.1, h * 0.55), Vector2(r * 0.85, h * 0.85),
		Vector2(r * 0.73, h)]), 40)
	var n := 48
	for i in n:
		var a := TAU * float(i) / float(n)
		var d := Vector3(cos(a), 0, sin(a))
		var t := Vector3(-sin(a), 0, cos(a))
		for s in [-1.0, 1.0]:
			lm.beam("Relief", base + d * (r + 0.14) + Vector3(0, h * 0.3, 0),
				base + d * (r + 0.16) + Vector3(0, h * 0.45, 0) + t * float(s) * 0.12, 0.13, 0.06, d)

## The column shaft from `base`, `h` tall, tapering r0..r1, with the
## spiral frieze of `turns` turns: a raised band with its fillet edges,
## the carved figures crowding the band and `windows` slits lighting the
## stair inside.
static func _spiral_shaft(lm: LandmarkMesh, base: Vector3, h: float, r0: float, r1: float,
		turns: float, windows: int) -> void:
	lm.lathe("Marble", base, PackedVector2Array([Vector2(r0, 0), Vector2(r0 * 0.99 + r1 * 0.01, h * 0.5),
		Vector2(r1, h)]), 40)
	var per := 28
	var n := int(turns * float(per))
	var band := h / turns
	for i in n:
		var f0 := float(i) / float(n)
		var f1 := float(i + 1) / float(n)
		var a0 := TAU * turns * f0
		var a1 := TAU * turns * f1
		var rr0 := lerpf(r0, r1, f0)
		var rr1 := lerpf(r0, r1, f1)
		var p0 := base + Vector3(cos(a0) * rr0, h * f0, sin(a0) * rr0)
		var p1 := base + Vector3(cos(a1) * rr1, h * f1, sin(a1) * rr1)
		var o0 := Vector3(cos(a0), 0, sin(a0))
		var o1 := Vector3(cos(a1), 0, sin(a1))
		# Fillet between the turns, the low relief ground of the band.
		lm.beam("Marble", p0 + o0 * 0.05, p1 + o1 * 0.05, 0.14, 0.12, Vector3.UP)
		lm.beam("Relief", p0 + o0 * 0.03 + Vector3(0, band * 0.5, 0), p1 + o1 * 0.03 + Vector3(0, band * 0.5, 0),
			band * 0.8, 0.08, Vector3.UP)
		# Figures: two to a segment, standing on the band's ground line.
		for k in 2:
			var t := (float(k) + 0.3) * 0.5
			var p := p0.lerp(p1, t)
			var o := o0.lerp(o1, t).normalized()
			var fh := band * (0.62 + 0.14 * absf(sin(float(i * 2 + k) * 1.93)))
			lm.box("Relief", p + o * 0.1 + Vector3(0, 0.1 + fh * 0.5, 0), Vector3(0.18, fh, 0.12),
				Basis(Vector3.UP, atan2(o.x, o.z)), 0.0)
	# Slit windows of the spiral stair, on the four quarters as it climbs.
	for k in windows:
		var f := (float(k) + 0.5) / float(windows)
		var a := PI * 0.5 * float(k) + 0.4
		var rr := lerpf(r0, r1, f) + 0.11
		var o := Vector3(cos(a), 0, sin(a))
		var c := base + o * rr + Vector3(0, h * f, 0)
		var t := Vector3(-sin(a), 0, cos(a))
		lm.quad("Shadow", c - t * 0.06 - Vector3(0, 0.3, 0), c + t * 0.06 - Vector3(0, 0.3, 0),
			c + t * 0.06 + Vector3(0, 0.3, 0), c - t * 0.06 + Vector3(0, 0.3, 0), o)

## Doric capital: necking, echinus carved with egg-and-dart, square
## abacus `w` wide; 1.3 m tall in all from `base`.
static func _capital(lm: LandmarkMesh, base: Vector3, r: float, w: float) -> void:
	lm.lathe("Marble", base, PackedVector2Array([Vector2(r, 0), Vector2(r + 0.08, 0.06),
		Vector2(r + 0.08, 0.14), Vector2(r, 0.2), Vector2(r + 0.35, 0.5), Vector2(r + 0.6, 0.8)]), 40)
	for i in 28:
		var a := TAU * float(i) / 28.0
		var d := Vector3(cos(a), 0, sin(a))
		lm.lathe("Relief", base + d * (r + 0.3) + Vector3(0, 0.3, 0), PackedVector2Array([Vector2(0.0, 0),
			Vector2(0.11, 0.08), Vector2(0.12, 0.2), Vector2(0.0, 0.3)]), 6, 1.0, 1.0, a)
	lm.box("Marble", base + Vector3(0, 1.05, 0), Vector3(w, 0.5, w))

## Iron railing round the top platform (radius r at the edge).
static func _railing(lm: LandmarkMesh, base: Vector3, r: float) -> void:
	var corners := [Vector3(-r, 0, -r), Vector3(r, 0, -r), Vector3(r, 0, r), Vector3(-r, 0, r)]
	for k in 4:
		var a: Vector3 = base + corners[k]
		var b: Vector3 = base + corners[(k + 1) % 4]
		lm.beam("Bronze", a + Vector3(0, 1.0, 0), b + Vector3(0, 1.0, 0), 0.05, 0.05)
		lm.beam("Bronze", a + Vector3(0, 0.15, 0), b + Vector3(0, 0.15, 0), 0.04, 0.04)
		for i in 12:
			var p := a.lerp(b, float(i) / 12.0)
			lm.beam("Bronze", p, p + Vector3(0, 1.0, 0), 0.03, 0.03)

# --- Pyramid of Cestius -----------------------------------------------

## The marble-faced tomb of Gaius Cestius (c. 12 BC), 29.6 m (100 Roman
## feet) square and 37 m high on its travertine footing, with the
## inscriptions high on the east and west faces, Alexander VII's 1663
## restoration line and door low on the west, the two re-erected column
## shafts at the west corners, and the Aurelian Wall running to the
## Porta San Paolo: two crenellated half-round brick towers either side
## of the gate, the travertine outer arch and the windowed upper gallery.
## Built square to its axes; yaw_deg turns it onto the street grid.
static func pyramid(model: Node3D) -> void:
	var lm := RmAMesh.new()
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#DDD7C9", 4.0))
	lm.use("Travertine", LandmarkMaterials.pbr("limestone", "#BFB290", 3.0))
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#93694E", 2.5))
	lm.use("Shadow", LandmarkMaterials.pbr("stone", "#4F463A", 3.0))
	lm.box("Travertine", Vector3(0, 0.55, 0), Vector3(30.4, 1.1, 30.4))
	lm.box("Travertine", Vector3(0, 1.25, 0), Vector3(30.0, 0.3, 30.0))
	lm.spire("Marble", Vector3(0, 1.4, 0), 14.8, 35.6)
	# Inscriptions on the sloping east and west faces, the 1663 line and door.
	var slope := atan2(35.6, 14.8)
	for sx in [-1.0, 1.0]:
		var n := Vector3(sx * sin(slope), cos(slope), 0)
		var up := Vector3(-sx * cos(slope), sin(slope), 0)
		_slope_text(lm, n, up, Vector3(sx * (14.8 - 23.0 / tan(slope)), 24.4, 0), 9.0, 2.2, 2, sx)
		_slope_text(lm, n, up, Vector3(sx * (14.8 - 16.0 / tan(slope)), 17.4, 0), 6.0, 1.2, 2, sx + 3.0)
	_slope_text(lm, Vector3(-sin(slope), cos(slope), 0),
		Vector3(cos(slope), sin(slope), 0), Vector3(-(14.8 - 4.2 / tan(slope)), 5.6, 0), 7.0, 0.8, 1, 9.0)
	lm.box("Marble", Vector3(-14.0, 1.4 + 1.5, 0), Vector3(1.6, 3.0, 2.4))
	LandmarkDetail.window(lm, "Travertine", "Shadow", Vector3(-14.8, 2.6, 0), Vector3.LEFT, 1.0, 2.2, false, 0.2)
	for sz in [-1.0, 1.0]:
		var cb := Vector3(-17.5, 0, sz * 13.0)
		lm.box("Travertine", cb + Vector3(0, 0.6, 0), Vector3(1.6, 1.2, 1.6))
		lm.lathe("Marble", cb + Vector3(0, 1.2, 0), PackedVector2Array([Vector2(0.75, 0), Vector2(0.78, 0.15),
			Vector2(0.62, 0.3), Vector2(0.58, 0.4), Vector2(0.55, 5.6), Vector2(0.53, 6.0)]), 20)
	# Aurelian Wall from the pyramid to the gate, with its merlons.
	var gate := Vector3(29.0, 0, -47.0)
	var w0 := Vector3(14.5, 0, -14.0)
	var w1 := gate + Vector3(-4.0, 0, 5.0)
	RmAUtil.ruin_wall(lm, "Brick", w0, w1, 3.6, 0.0, 9.0, 11.0, 2.4, 2.0)
	var wd := (w1 - w0).normalized()
	var wn := Vector3.UP.cross(wd).normalized()
	RmADetail.merlons(lm, "Brick", w0 + wd * 3.0 + wn * 1.5 + Vector3(0, 9.0, 0),
		w1 - wd * 1.0 + wn * 1.5 + Vector3(0, 9.0, 0), 1.0, 1.6, 0.6)
	lm.place(gate.x, gate.z, 166.0)
	for sx in [-1.0, 1.0]:
		var tc := Vector3(sx * 7.6, 0, 0)
		lm.frustum("Brick", tc, 5.2, 4.8, 13.0, 24)
		lm.frustum("Travertine", tc, 5.4, 5.3, 1.6, 24)
		lm.frustum("Travertine", tc + Vector3(0, 13.0, 0), 5.5, 5.5, 0.6, 24)
		lm.frustum("Brick", tc + Vector3(0, 13.6, 0), 5.1, 5.1, 0.6, 24)
		RmAUtil.merlons_ring(lm, "Brick", tc, 5.0, 14.2, 12, 1.4, 1.5, 0.8)
		for a in [0.3, 0.9, 1.5, 2.1, 2.7]:
			var dd := Vector3(cos(float(a)), 0, sin(float(a)))
			for y in [5.0, 9.2]:
				SEuUtil.opening(lm, "Shadow", tc + dd * 4.98 + Vector3(0, float(y), 0), Vector3.UP.cross(dd),
					Vector3.UP, 0.5, 1.8)
	RmAUtil.arch_wall(lm, "Brick", "Shadow", Vector3(0, 0, 2.0), Vector3.RIGHT, Vector3.BACK,
		-7.0, 7.0, 0.0, 11.0, [[-1.9, 3.2, 4.5, 0.0], [1.9, 3.2, 4.5, 0.0]], 4.0, 10)
	lm.box("Travertine", Vector3(0, 3.2, 2.3), Vector3(7.8, 6.4, 0.6))
	for s in [-1.0, 1.0]:
		LandmarkDetail.arch(lm, "Travertine", Vector3(float(s) * 1.9, 4.5, 2.6), Vector3.BACK, 3.2, 0.4, 0.2)
	LandmarkDetail.cornice(lm, "Travertine", Vector3(-7.0, 6.6, 2.0), Vector3(7.0, 6.6, 2.0), Vector3.BACK, 0.5, false)
	for i in 5:
		RmADetail.niche(lm, "Brick", "Shadow", Vector3(-4.8 + 2.4 * float(i), 7.6, 2.0), Vector3.BACK, 1.0, 1.6, 0.25, 0.3)
	lm.box("Travertine", Vector3(0, 11.3, 0), Vector3(14.6, 0.6, 4.6))
	RmADetail.merlons(lm, "Brick", Vector3(-6.6, 11.6, 1.9), Vector3(6.6, 11.6, 1.9), 1.0, 1.5, 0.6)
	lm.commit(model)

## Rows of letters on a sloping pyramid face: `n` the face normal, `up`
## its up-slope direction, `c` the centre of the text block.
static func _slope_text(lm: LandmarkMesh, n: Vector3, up: Vector3, c: Vector3, w: float, h: float,
		lines: int, seed_v: float) -> void:
	var right := up.cross(n).normalized()
	var lh := h / (float(lines) * 1.5)
	var pitch := lh * 0.8
	var p0 := c + n * 0.02
	for j in lines:
		var y := h * 0.5 - (float(j) + 0.5) * h / float(lines)
		var cols := int(w / pitch)
		for i in cols:
			if absf(sin(float(i) * 1.9 + float(j) * 2.3 + seed_v)) > 0.93:
				continue
			var p := p0 + right * (-w * 0.5 + pitch * (float(i) + 0.5)) + up * y
			lm.quad("Shadow", p - right * lh * 0.3 - up * lh * 0.5, p + right * lh * 0.3 - up * lh * 0.5,
				p + right * lh * 0.3 + up * lh * 0.5, p - right * lh * 0.3 + up * lh * 0.5, n)
