class_name LandmarkGtOlympia
extends RefCounted

## The Altis of Olympia in true metres, front to the east (+X), north to
## -Z: the ruined Temple of Zeus with its fallen columns, the Heraion and
## the Philippeion. y = 0 is the ground of the Altis.

const ZEUS_Y := 1.65
const ZEUS_COLS := 10.53
const ZEUS_R := 1.12
const ZEUS_X := 30.65
const ZEUS_Z := 12.6

## Temple of Zeus (472-456 BC, architect Libon of Elis), origin at its
## centre: the three unequal steps of the krepis under a 64.1 x 27.7 m
## stylobate with the ramp up to the east front; the peristyle of 6 x 13
## Doric columns 10.5 m high and 2.2 m across with 20 flutes, of which
## one (the north-west column re-erected in 2004) stands again, the
## rest are fluted stumps; the cella and its porches distyle in antis,
## the two rows of seven inner columns and the black limestone floor of
## the statue of Zeus; and the columns thrown down by the 6th-century
## earthquakes lying where they fell, drum after drum with the capital
## at the end. The Heraion and the Philippeion are drawn a little nearer
## than they stand.
static func olympia(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Poros", LandmarkMaterials.pbr("limestone", "#D5C49D", 2.5))
	lm.use("Block", LandmarkMaterials.pbr("stone", "#AA9D85", 3.0))
	lm.use("Marble", LandmarkMaterials.pbr("limestone", "#E4DDCC", 2.5))
	lm.use("Black", LandmarkMaterials.pbr("stone", "#3E3B37", 2.5))
	LandmarkGtUtil.steps(lm, "Poros", Vector2.ZERO, Vector2(64.1, 27.7), ZEUS_Y, 3, 0.55, 0.7)
	_ramp(lm, Vector3(32.0, 0, 0), Vector3(44.0, 0, 0), ZEUS_Y, 8.0)
	var dx := ZEUS_X * 2.0 / 12.0
	var dz := ZEUS_Z * 2.0 / 5.0
	for i in 13:
		for s in [-1.0, 1.0]:
			var p := Vector3(-ZEUS_X + dx * float(i), ZEUS_Y, s * ZEUS_Z)
			if s < 0.0 and i == 1:
				LandmarkGtUtil.doric_column(lm, "Poros", p, ZEUS_R, ZEUS_COLS, 20)
			else:
				LandmarkGtUtil.fluted(lm, "Poros", p, p + Vector3(0, 0.3 + 0.9 * LandmarkGtUtil.hash01(i * 2 + int(s), 11), 0),
					ZEUS_R, ZEUS_R, 20)
	for j in range(1, 5):
		for s in [-1.0, 1.0]:
			var q := Vector3(s * ZEUS_X, ZEUS_Y, -ZEUS_Z + dz * float(j))
			LandmarkGtUtil.fluted(lm, "Poros", q, q + Vector3(0, 0.3 + 0.8 * LandmarkGtUtil.hash01(j * 5 + int(s), 13), 0),
				ZEUS_R, ZEUS_R, 20)
	# Cella walls and porch antae in courses; the porch columns' stumps.
	for w in [[-23.5, 23.5, -7.3, -5.7], [-23.5, 23.5, 5.7, 7.3], [-16.0, -14.4, -5.7, 5.7], [14.4, 16.0, -5.7, 5.7]]:
		LandmarkGtUtil.courses(lm, "Block", w[0], w[1], ZEUS_Y, ZEUS_Y + 1.3, w[2], w[3], 2, 2.2)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var pc := Vector3(sx * 22.5, ZEUS_Y, sz * 2.4)
			LandmarkGtUtil.fluted(lm, "Poros", pc, pc + Vector3(0, 0.6 + 0.4 * LandmarkGtUtil.hash01(int(sx + 2.0 * sz + 4.0), 2), 0),
				1.0, 1.0, 20)
	# Inner colonnades (two rows of seven) and the statue base floor.
	for k in 7:
		for sz in [-1.0, 1.0]:
			var pin := Vector3(-11.0 + 3.6 * float(k), ZEUS_Y, sz * 3.9)
			LandmarkGtUtil.fluted(lm, "Poros", pin, pin + Vector3(0, 0.4, 0), 0.55, 0.55, 20)
	LandmarkGtUtil.block(lm, "Black", 4.0, 13.5, ZEUS_Y, ZEUS_Y + 0.12, -3.3, 3.3)
	LandmarkGtUtil.block(lm, "Marble", 6.2, 12.6, ZEUS_Y + 0.12, ZEUS_Y + 0.7, -3.3, 3.3)
	# Fallen flank columns: drums in a row, capital at the far end.
	for i in 13:
		for s in [-1.0, 1.0]:
			if s < 0.0 and (i % 3 == 1 or i == 1):
				continue
			_fallen(lm, -ZEUS_X + dx * float(i) + 0.5 * (LandmarkGtUtil.hash01(i, 5) - 0.5), s, i)
	_heraion(lm, Vector3(-22.0, 0, -100.0))
	_philippeion(lm, Vector3(-3.0, 0, -77.0))
	lm.commit(model)

## One flank column lying as the earthquake dropped it, outward from the
## stylobate edge along Z (`s` the side): six fluted drums and the
## capital (echinus and square abacus) at the end.
static func _fallen(lm: LandmarkMesh, x: float, s: float, salt: int) -> void:
	var z: float = s * (ZEUS_Z + 3.6)
	var drift := 0.0
	for k in 6:
		var r0 := lerpf(ZEUS_R, ZEUS_R * 0.85, float(k) / 6.0)
		var z0: float = z + s * (1.55 * float(k) + 0.2 * LandmarkGtUtil.hash01(salt * 7 + k, 9))
		drift += 0.25 * (LandmarkGtUtil.hash01(salt * 11 + k, 19) - 0.5)
		LandmarkGtUtil.fluted(lm, "Poros", Vector3(x + drift, r0, z0), Vector3(x + drift, r0, z0 + s * 1.4),
			r0, r0 - 0.03, 20)
	var zc: float = z + s * 10.2
	LandmarkGtUtil.cylinder(lm, "Poros", Vector3(x + drift, 1.35, zc), Vector3(x + drift, 1.35, zc + s * 0.8),
		0.95, 1.35, 16)
	lm.box("Poros", Vector3(x + drift, 1.45, zc + s * 1.15), Vector3(2.9, 2.9, 0.6))

## Ramp from the ground at `foot` up `rise` to the stylobate edge over
## `top` (both on the axis), `w` wide.
static func _ramp(lm: LandmarkMesh, top: Vector3, foot: Vector3, rise: float, w: float) -> void:
	var dir := (foot - top).normalized()
	var side := dir.cross(Vector3.UP).normalized() * w * 0.5
	var t := top + Vector3(0, rise, 0)
	lm.quad("Poros", t - side, t + side, foot + side, foot - side, Vector3.UP)
	for sg in [-1.0, 1.0]:
		var sv: Vector3 = side * float(sg)
		lm.tri("Block", top + sv, t + sv, foot + sv, sv, sv, sv, Vector2.ZERO, Vector2(0, -rise),
			Vector2(top.distance_to(foot), 0))
	lm.quad("Block", top - side, top + side, t + side, t - side, -dir)

## Heraion at `c`: archaic Doric temple 50 x 18.75 m, 6 x 16 columns of
## 5.2 m; the columns re-erected on the north flank stand to their
## capitals or part way, the rest are fluted stumps of every height; the
## cella's orthostat footing and its inner column stubs.
static func _heraion(lm: LandmarkMesh, c: Vector3) -> void:
	LandmarkGtUtil.block(lm, "Block", c.x - 26.0, c.x + 26.0, 0.0, 0.3, c.z - 10.4, c.z + 10.4)
	LandmarkGtUtil.steps(lm, "Block", Vector2(c.x, c.z), Vector2(50.0, 18.75), 0.9, 2, 0.3, 0.4)
	var dx := 48.4 / 15.0
	var dz := 17.15 / 5.0
	var tall := {6: 5.2, 7: 3.4, 8: 5.2, 9: 2.2, 10: 5.2}
	for i in 16:
		for s in [-1.0, 1.0]:
			var p := c + Vector3(-24.2 + dx * float(i), 0.9, s * 8.57)
			var up: float = tall[i] if (s < 0.0 and tall.has(i)) else 0.3 + 1.1 * LandmarkGtUtil.hash01(i, 21 + int(s))
			LandmarkGtUtil.doric_column(lm, "Poros", p, 0.52, 5.2, 20, up)
	for j in range(1, 5):
		for s in [-1.0, 1.0]:
			var q := c + Vector3(s * 24.2, 0.9, -8.57 + dz * float(j))
			LandmarkGtUtil.fluted(lm, "Poros", q, q + Vector3(0, 0.3 + 0.9 * LandmarkGtUtil.hash01(j, 33 + int(s)), 0),
				0.52, 0.52, 20)
	for w in [[-19.0, 19.0, -3.6, -2.6], [-19.0, 19.0, 2.6, 3.6], [-19.0, -18.0, -2.6, 2.6]]:
		LandmarkGtUtil.courses(lm, "Block", c.x + w[0], c.x + w[1], 0.9, 1.9, c.z + w[2], c.z + w[3], 2, 1.6)
	for k in 8:
		for sz in [-1.0, 1.0]:
			LandmarkGtUtil.fluted(lm, "Poros", c + Vector3(-14.0 + 3.8 * float(k), 0.9, sz * 1.7),
				c + Vector3(-14.0 + 3.8 * float(k), 1.3, sz * 1.7), 0.4, 0.4, 16)

## Philippeion at `c`: Philip II's circular Ionic shrine, 15.2 m across
## on three steps, 18 columns; three re-erected with their architrave
## and frieze in 2005, the rest fluted stubs; the cella wall footing.
static func _philippeion(lm: LandmarkMesh, c: Vector3) -> void:
	LandmarkGtUtil.ring_steps(lm, "Marble", c, 7.6, 0.75, 3, 0.25, 0.3, 40)
	var ring := 6.6
	for k in 18:
		var a := TAU * float(k) / 18.0
		var p := c + Vector3(cos(a) * ring, 0.75, sin(a) * ring)
		if k in [3, 4, 5]:
			LandmarkDetail.column(lm, "Marble", p, 0.36, 5.2, "ionic", 24)
		else:
			LandmarkGtUtil.fluted(lm, "Marble", p, p + Vector3(0, 0.25 + 0.5 * LandmarkGtUtil.hash01(k, 2), 0), 0.36, 0.36, 24)
	var ey := 0.75 + 5.2
	for k in [3, 4]:
		var a0 := TAU * float(k) / 18.0
		var a1 := TAU * float(k + 1) / 18.0
		var p0 := c + Vector3(cos(a0) * ring, ey, sin(a0) * ring)
		var p1 := c + Vector3(cos(a1) * ring, ey, sin(a1) * ring)
		var dir := (p1 - p0).normalized()
		var out := Vector3(cos((a0 + a1) * 0.5), 0, sin((a0 + a1) * 0.5))
		var bas := Basis(dir, Vector3.UP, out)
		var mid := (p0 + p1) * 0.5
		var run := p0.distance_to(p1) + 0.9
		for f in 3:
			lm.box("Marble", mid + Vector3(0, 0.12 + 0.2 * float(f), 0) + out * 0.03 * float(f),
				Vector3(run, 0.2, 0.75 + 0.06 * float(f)), bas, 0.0)
		lm.box("Marble", mid + Vector3(0, 0.95, 0), Vector3(run, 0.5, 0.7), bas)
		LandmarkDetail.cornice(lm, "Marble", p0 - dir * 0.45 + Vector3(0, 1.2, 0) + out * 0.35,
			p1 + dir * 0.45 + Vector3(0, 1.2, 0) + out * 0.35, out, 0.35, true)
	lm.lathe("Block", c + Vector3(0, 0.75, 0), PackedVector2Array([Vector2(4.4, 0), Vector2(4.4, 0.8),
		Vector2(3.8, 0.8), Vector2(3.8, 0)]), 40, 1.0, 1.0, 0.0, false, false)
