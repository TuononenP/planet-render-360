class_name LandmarkRmLUtil
extends RefCounted

## Helpers shared by the later-Rome landmark builders (true metres on
## LandmarkMesh): obelisks, pilaster rows, pediments, plain palazzo
## blocks, domes on drums, round-arched campanili and stair flights.
## The helpers assume the material keys the builders register in common:
## "Stone", "Trim", "Shadow", "Dome", "Gold" (plus a wall key passed to
## block() and tower()).

## Egyptian obelisk of `h` metres standing on `base`, `hw` the half
## width at the foot: a shaft tapering to 0.72 hw and a pyramidion.
static func obelisk(lm: LandmarkMesh, key: String, base: Vector3, h: float, hw: float) -> void:
	lm.spire(key, base, hw, h * 0.93, hw * 0.72)
	lm.spire(key, base + Vector3(0, h * 0.93, 0), hw * 0.72, h * 0.07)

## Row of `n` pilasters (w wide, `proj` deep) of height h on a wall
## facing `out` (+/-X or +/-Z): `c` is the wall face centre at ground.
static func pilasters(lm: LandmarkMesh, key: String, c: Vector3, out: Vector3, n: int,
		pitch: float, h: float, w: float, proj: float) -> void:
	var along := Vector3.UP.cross(out)
	var size := Vector3(w, h, proj) if absf(out.z) > 0.5 else Vector3(proj, h, w)
	for i in n:
		var s := (float(i) - float(n - 1) * 0.5) * pitch
		lm.box(key, c + along * s + out * proj * 0.5 + Vector3(0, h * 0.5, 0), size)

## Triangular pediment on a +Z facing entablature: `c` is the centre of
## its base, w wide, `rise` high, `depth` front to back.
static func pediment(lm: LandmarkMesh, key: String, c: Vector3, w: float, rise: float,
		depth: float = 1.6, face_key: String = "") -> void:
	lm.gable(key, c, w, depth, rise, Basis(), 0.0, face_key if face_key != "" else key)

## Palazzo block facing `out` (+/-X or +/-Z): `c` is the footprint
## centre at ground level, w along the facade, h tall, d deep. A plinth,
## string courses at every floor, quoined corners, a moulded crowning
## cornice and `floors` rows of `bays` framed windows cut into the front
## (heads per LandmarkRmLKit.windows `head`); a hipped roof in
## `roof_key` when given.
static func block(lm: LandmarkMesh, wall: String, c: Vector3, w: float, h: float, d: float,
		out: Vector3, floors: int, bays: int, win_w: float = 1.3, win_h: float = 2.3,
		roof_key: String = "", head: int = 0) -> void:
	var along := Vector3.UP.cross(out)
	var size := Vector3(w, h, d) if absf(out.z) > 0.5 else Vector3(d, h, w)
	lm.box(wall, c + Vector3(0, h * 0.5, 0), size)
	lm.box("Trim", c + Vector3(0, 0.45, 0), Vector3(size.x + 1.0, 0.9, size.z + 1.0))
	lm.box("Trim", c + Vector3(0, h - 0.3, 0), Vector3(size.x + 0.9, 0.6, size.z + 0.9))
	var floor_h := h / float(floors)
	for f in range(1, floors):
		lm.box("Trim", c + Vector3(0, floor_h * float(f), 0), Vector3(size.x + 0.9, 0.4, size.z + 0.9))
	var o := c + out * d * 0.5
	var origin := o - along * w * 0.5
	LandmarkRmLKit.windows(lm, wall, "Shadow", "Trim", origin, along, out, w, h - 0.6, bays, floors,
		Vector2(win_w, win_h), maxf((floor_h - win_h) * 0.45, 1.0), floor_h, head)
	var ch := clampf(h * 0.05, 0.7, 1.6)
	LandmarkDetail.cornice(lm, "Trim", origin + Vector3(0, h, 0) + out * 0.4 - along * 0.4,
		origin + Vector3(0, h, 0) + out * 0.4 + along * (w + 0.4), out, ch, false)
	for s in [0.0, 1.0]:
		var side := along * (-1.0 if s < 0.5 else 1.0)
		LandmarkRmLKit.quoins(lm, "Trim", origin + along * w * s + out * 0.35, out, side, 0.9, h - 0.6)
	if roof_key != "":
		LandmarkRmLKit.hip_roof(lm, roof_key, c + Vector3(0, h + ch * 0.6, 0), size.x, size.z,
			minf(size.x, size.z) * 0.16, 0.3)

## Drum with window openings and pilasters, cornice, ribbed dome,
## columned lantern and a gilded ball and cross; the cross ends `top_h`
## above `base`. The dome profile is round, or pointed when `pointed`.
static func dome_stack(lm: LandmarkMesh, base: Vector3, r: float, drum_h: float, dome_h: float,
		lantern_h: float, top_h: float, bays: int = 8, ribs: int = 8, pointed: bool = false) -> void:
	var ph := PI / float(bays)
	lm.frustum("Stone", base, r, r, drum_h, 32)
	SEuUtil.ring_openings(lm, "Shadow", base, r, 32, bays, drum_h * 0.2, r * 0.17, drum_h * 0.55, false, 0.0)
	SEuUtil.column_ring(lm, "Trim", base, r + 0.1, bays, drum_h * 0.96, 0.32, 6, ph)
	lm.frustum("Trim", base + Vector3(0, drum_h, 0), r * 1.07, r * 1.07, 0.9, 32)
	var y0 := drum_h + 0.9
	var shell := SEuUtil.ogive(r * 0.99, dome_h, 10) if pointed else SEuUtil.dome(r * 0.99, dome_h, 10)
	lm.lathe("Dome", base + Vector3(0, y0, 0), shell, 32)
	for k in ribs:
		var a := TAU * float(k) / float(ribs)
		for j in shell.size() - 2:
			lm.beam("Trim", base + Vector3(cos(a) * shell[j].x, y0 + shell[j].y, sin(a) * shell[j].x),
				base + Vector3(cos(a) * shell[j + 1].x, y0 + shell[j + 1].y, sin(a) * shell[j + 1].x), 0.5, 0.4)
	var ly := y0 + dome_h
	var lr := r * 0.2
	lm.frustum("Stone", base + Vector3(0, ly, 0), lr * 1.5, lr * 1.5, 0.7, 12)
	lm.frustum("Shadow", base + Vector3(0, ly + 0.7, 0), lr * 0.8, lr * 0.8, lantern_h - 1.7, 8)
	SEuUtil.column_ring(lm, "Trim", base + Vector3(0, ly + 0.7, 0), lr, 8, lantern_h - 1.7, 0.22, 6)
	lm.lathe("Dome", base + Vector3(0, ly + lantern_h - 1.0, 0), SEuUtil.dome(lr * 1.35, 1.6, 4), 12)
	var fy := ly + lantern_h + 0.5
	SEuUtil.finial(lm, "Gold", base + Vector3(0, fy, 0), maxf(top_h - fy, 1.0))

## Round-arched tower on a square plan, centred on `base`: `tiers` are
## (height, half width) pairs from the ground up, each ringed by a
## cornice band on a frieze of small corbels and, from the second tier
## on, open on all four faces in an arcade of real round-arched openings
## (two or three a face, with archivolts and a colonnette between
## each pair); capped by a pyramid reaching `total_h`.
static func tower(lm: LandmarkMesh, wall: String, base: Vector3, tiers: PackedVector2Array,
		total_h: float, cap_key: String = "Dome") -> void:
	var y := 0.0
	for t in tiers.size():
		var th := tiers[t].x
		var hw := tiers[t].y
		var inset := 0.4 if t >= 1 else 0.0
		lm.box(wall, base + Vector3(0, y + th * 0.5, 0), Vector3((hw - inset) * 2.0, th, (hw - inset) * 2.0))
		lm.box("Trim", base + Vector3(0, y + th, 0), Vector3(hw * 2.0 + 0.6, 0.5, hw * 2.0 + 0.6))
		for f in 4:
			var out := Vector3(0, 0, 1).rotated(Vector3.UP, PI * 0.5 * float(f))
			var r := Vector3.UP.cross(out)
			# Corbel frieze under the cornice.
			var cn := int(hw * 2.0 / 0.7)
			for k in cn:
				lm.box("Trim", base + out * (hw + 0.1) + r * (-hw + 0.7 * (float(k) + 0.5)) + Vector3(0, y + th - 0.45, 0),
					Vector3(0.3, 0.4, 0.2), Basis(r, Vector3.UP, out), 0.0)
			if t >= 1:
				var n := 3 if hw > 3.0 else 2
				var span := hw * 1.25 / float(n)
				var o := base + out * (hw - inset) - r * hw + Vector3(0, y, 0)
				LandmarkRmLKit.arcade(lm, wall, "Shadow", o, r, out, hw * 2.0, th - 0.2, n, span, th * 0.55, inset,
					th * 0.15)
				LandmarkRmLKit.archivolts(lm, "Trim", o, r, out, hw * 2.0, n, span, th * 0.55, inset, 0.25)
				for k in n:
					var cx := -hw + hw * 2.0 / float(n) * (float(k) + 0.5)
					LandmarkRmLKit.column_lite(lm, "Trim", base + out * (hw - inset * 0.5) + r * cx + Vector3(0, y + th * 0.15, 0),
						0.14, th * 0.4)
		y += th + 0.5
	lm.spire(cap_key, base + Vector3(0, y, 0), tiers[tiers.size() - 1].y + 0.3, total_h - y, 0.0, 4)

## Wide flight of steps rising toward -Z from height y0 at `z_bottom` to
## y1 at `z_top`; the boxes are solid down to the ground (x centred).
static func flight(lm: LandmarkMesh, key: String, x: float, width: float, z_bottom: float,
		z_top: float, y0: float, y1: float, n: int) -> void:
	var depth := (z_bottom - z_top) / float(n)
	for k in n:
		var hgt := lerpf(y0, y1, float(k + 1) / float(n))
		lm.box(key, Vector3(x, hgt * 0.5, z_bottom - depth * (float(k) + 0.5)),
			Vector3(width, hgt, depth))

## Coarse horse standing on `base`, head toward +Z: body, legs, neck
## and head, 3.9 m to the ears.
static func horse(lm: LandmarkMesh, key: String, base: Vector3) -> void:
	lm.box(key, base + Vector3(0, 2.0, 0), Vector3(1.0, 1.4, 3.0))
	for sx in [-0.35, 0.35]:
		for sz in [-1.1, 1.1]:
			lm.box(key, base + Vector3(sx, 0.65, sz), Vector3(0.3, 1.3, 0.3))
	lm.beam(key, base + Vector3(0, 2.4, 1.2), base + Vector3(0, 3.5, 1.7), 0.6, 0.5)
	lm.box(key, base + Vector3(0, 3.55, 2.1), Vector3(0.4, 0.6, 0.9))
