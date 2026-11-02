class_name LandmarkFrTimber
extends RefCounted

## Finnish timber landmarks in true metres, in the frame of the real plan
## (+X east, +Z south, turned onto the map by yaw_deg): Kerimaki Church,
## Petajavesi Old Church, Sibelius' Ainola and Hvittrask. Plans follow the
## OpenStreetMap footprints.

## Kerimaki Church (Kerimaen kirkko), Anders Fredrik Granstedt, 1847: the
## world's largest wooden church (about 3,000 seats), a short-armed double
## cross 45 m long and 42 m wide and 27 m high, the dome over the crossing
## on four wooden pillars, 37 m to the top of the cross. Pale-yellow
## vertical boarding with white corner pilasters, cornices and window
## frames in three rows, pedimented gables with lunettes on every arm,
## doors with pediments, the green roofs, the octagonal drum with its
## windows, the cupola, lantern and cross. The 42 m belfry beside it is
## left out. Long axis along X.
const KERIMAKI_TOP := 37.0
const KERIMAKI_EAVE := 13.0

static func kerimaki(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("wood", "#E0D3A2", 2.0))
	lm.use("Trim", LandmarkMaterials.pbr("wood", "#EFEBDD", 2.0))
	lm.use("Roof", LandmarkMaterials.pbr("concrete", "#5E8566", 2.5, 0.55, 0.3))
	lm.use("Glass", LandmarkMaterials.glass("#20282C"))
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#8A857A", 3.0))
	lm.use("Gilt", LandmarkMaterials.gold())
	var e := KERIMAKI_EAVE
	# Double cross: the crossing (26 x 26 m), the stepped inner corners and
	# the four arms, all to the same eaves, with granite plinths.
	LandmarkFrKit.rect(lm, "Stone", -22.8, 22.8, -11.3, 11.3, 0.0, 1.0)
	LandmarkFrKit.rect(lm, "Stone", -13.3, 13.3, -21.3, 21.3, 0.0, 1.0)
	LandmarkFrKit.rect(lm, "Stone", -17.3, 17.3, -17.3, 17.3, 0.0, 1.0)
	LandmarkFrKit.rect(lm, "Wall", -17.0, 17.0, -17.0, 17.0, 1.0, e)
	LandmarkFrKit.rect(lm, "Wall", -22.5, 22.5, -11.0, 11.0, 1.0, e)
	LandmarkFrKit.rect(lm, "Wall", -13.0, 13.0, -21.0, 21.0, 1.0, e)
	# Arms' roofs: E-W ridge across the whole length, N-S ridge across the
	# width (rise 14 to the 27 m ridges), low hips over the stepped corners.
	LandmarkFrKit.gable(lm, "Roof", -22.5, 22.5, -11.0, 11.0, e, 14.0, 0.8, "Wall", 1)
	LandmarkFrKit.gable(lm, "Roof", -13.0, 13.0, -21.0, 21.0, e, 14.0, 0.8, "Wall", 0)
	LandmarkFrParts.roof_trim(lm, "Trim", -22.5, 22.5, -11.0, 11.0, e, 14.0, 0.8, 1, 0.35)
	LandmarkFrParts.roof_trim(lm, "Trim", -13.0, 13.0, -21.0, 21.0, e, 14.0, 0.8, 0, 0.35)
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			LandmarkFrKit.hip(lm, "Roof", minf(sx * 13.0, sx * 17.0), maxf(sx * 13.0, sx * 17.0),
				minf(sz * 11.0, sz * 17.0), maxf(sz * 11.0, sz * 17.0), e, 3.0, 0.6)
	# Boarding battens, corner pilasters and the eave cornices.
	var faces := [[Vector3(-22.5, 1.0, -11.0), Vector3(-22.5, 1.0, 11.0), Vector3.LEFT],
		[Vector3(22.5, 1.0, 11.0), Vector3(22.5, 1.0, -11.0), Vector3.RIGHT],
		[Vector3(13.0, 1.0, -21.0), Vector3(-13.0, 1.0, -21.0), Vector3.FORWARD],
		[Vector3(-13.0, 1.0, 21.0), Vector3(13.0, 1.0, 21.0), Vector3.BACK]]
	for f in faces:
		LandmarkFrParts.battens(lm, "Wall", f[0], f[1], f[2], e - 1.6, 0.7, 0.07)
	for sx2: float in [-1.0, 1.0]:
		for sz2: float in [-1.0, 1.0]:
			LandmarkFrParts.battens(lm, "Wall", Vector3(sx2 * 17.0, 1.0, sz2 * 11.0), Vector3(sx2 * 22.5, 1.0, sz2 * 11.0),
				Vector3(0, 0, sz2), e - 1.6, 0.7, 0.07)
			LandmarkFrParts.battens(lm, "Wall", Vector3(sx2 * 13.0, 1.0, sz2 * 21.0), Vector3(sx2 * 13.0, 1.0, sz2 * 17.0),
				Vector3(sx2, 0, 0), e - 1.6, 0.7, 0.07)
	LandmarkFrParts.corner_strips(lm, "Trim", -22.5, 22.5, -11.0, 11.0, 1.0, e - 0.6, 0.9, 0.14)
	LandmarkFrParts.corner_strips(lm, "Trim", -13.0, 13.0, -21.0, 21.0, 1.0, e - 0.6, 0.9, 0.14)
	LandmarkFrParts.corner_strips(lm, "Trim", -17.0, 17.0, -17.0, 17.0, 1.0, e - 0.6, 0.9, 0.14)
	LandmarkFrParts.cornice_ring(lm, "Trim", -22.5, 22.5, -11.0, 11.0, e - 0.6, 0.6)
	LandmarkFrParts.cornice_ring(lm, "Trim", -13.0, 13.0, -21.0, 21.0, e - 0.6, 0.6)
	# Three rows of white-framed windows on every wall of the cross.
	for row in 3:
		var y := 1.8 + 3.6 * float(row)
		var wh := 2.4 if row < 2 else 1.8
		LandmarkFrParts.openings(lm, "Trim", "Glass", Vector3(-22.5, y, -9.0), Vector3(-22.5, y, 9.0), Vector3.LEFT, 4,
			1.3, wh, LandmarkFrParts.HEAD_FLAT, 0.18, 0.1, 1)
		LandmarkFrParts.openings(lm, "Trim", "Glass", Vector3(22.5, y, -9.0), Vector3(22.5, y, 9.0), Vector3.RIGHT, 4,
			1.3, wh, LandmarkFrParts.HEAD_FLAT, 0.18, 0.1, 1)
		LandmarkFrParts.openings(lm, "Trim", "Glass", Vector3(-11.0, y, -21.0), Vector3(11.0, y, -21.0), Vector3.FORWARD,
			5, 1.3, wh, LandmarkFrParts.HEAD_FLAT, 0.18, 0.1, 1)
		LandmarkFrParts.openings(lm, "Trim", "Glass", Vector3(-11.0, y, 21.0), Vector3(11.0, y, 21.0), Vector3.BACK,
			5, 1.3, wh, LandmarkFrParts.HEAD_FLAT, 0.18, 0.1, 1)
		for sx3: float in [-1.0, 1.0]:
			for sz3: float in [-1.0, 1.0]:
				LandmarkFrParts.opening(lm, "Trim", "Glass", Vector3(sx3 * 19.75, y, sz3 * 11.0), Vector3(0, 0, sz3), 1.3,
					wh, LandmarkFrParts.HEAD_FLAT, 0.18, 0.1, 1)
				LandmarkFrParts.opening(lm, "Trim", "Glass", Vector3(sx3 * 13.0, y, sz3 * 19.0), Vector3(sx3, 0, 0), 1.3,
					wh, LandmarkFrParts.HEAD_FLAT, 0.18, 0.1, 1)
	# Pedimented doors and lunettes in the four gables.
	for g in [[Vector3(-22.5, 1.0, 0), Vector3.LEFT, Vector3.BACK], [Vector3(22.5, 1.0, 0), Vector3.RIGHT, Vector3.BACK],
			[Vector3(0, 1.0, -21.0), Vector3.FORWARD, Vector3.RIGHT], [Vector3(0, 1.0, 21.0), Vector3.BACK, Vector3.RIGHT]]:
		var gc: Vector3 = g[0]
		var gn: Vector3 = g[1]
		var ga: Vector3 = g[2]
		LandmarkFrParts.opening(lm, "Trim", "Glass", gc - Vector3(0, 1.0, 0) + gn * 0.01, gn, 2.4, 3.6,
			LandmarkFrParts.HEAD_FLAT, 0.3, 0.2, 1)
		lm.box("Trim", gc + Vector3(0, 3.3, 0) + gn * 0.3, Vector3(3.8, 0.35, 0.6), Basis(ga, Vector3.UP, gn))
		lm.gable("Trim", gc + Vector3(0, 3.5, 0) + gn * 0.3, 3.8, 0.6, 1.0, Basis(ga, Vector3.UP, gn), 0.1, "Trim")
		LandmarkFrParts.opening(lm, "Trim", "Glass", gc + Vector3(0, e + 3.0, 0) + gn * 0.02, gn, 2.6, 1.6,
			LandmarkFrParts.HEAD_ROUND, 0.2, 0.12, 2)
	# Central drum with eight windows between pilasters, the cupola,
	# lantern, ball and cross over the crossing.
	var c := Vector3(0.0, 27.0, 0.0)
	lm.frustum("Wall", c - Vector3(0, 1.0, 0), 5.0, 5.0, 1.0, 8, PI / 8.0)
	lm.frustum("Wall", c, 5.0, 4.8, 4.0, 8, PI / 8.0)
	LandmarkFrParts.ring_openings(lm, "Trim", "Glass", c + Vector3(0, 0.9, 0), 4.85 * cos(PI / 8.0), 8, 1.3, 2.2,
		LandmarkFrParts.HEAD_ROUND, 0.0, 0.16)
	for k in 8:
		var a := TAU * float(k) / 8.0 + PI / 8.0
		lm.box("Trim", c + Vector3(cos(a) * 4.92, 2.0, sin(a) * 4.92), Vector3(0.4, 4.0, 0.4), Basis(Vector3.UP, -a))
	lm.frustum("Trim", c + Vector3(0, 4.0, 0), 5.5, 5.4, 0.7, 8, PI / 8.0)
	lm.lathe("Roof", c + Vector3(0, 4.7, 0), PackedVector2Array([Vector2(5.4, 0), Vector2(5.2, 0.9),
		Vector2(4.6, 1.8), Vector2(3.5, 2.6), Vector2(2.0, 3.1), Vector2(1.2, 3.3)]), 8, 1.0, 1.0, PI / 8.0)
	lm.frustum("Wall", c + Vector3(0, 8.0, 0), 1.3, 1.2, 0.8, 8, PI / 8.0)
	lm.frustum("Roof", c + Vector3(0, 7.9, 0), 1.45, 1.4, 0.15, 8, PI / 8.0)
	lm.lathe("Gilt", c + Vector3(0, 8.8, 0), LandmarkFrKit.ball(0.2), 8)
	LandmarkFrKit.cross(lm, "Gilt", c + Vector3(0, 8.8, 0), 1.2)
	lm.commit(model)

## Petajavesi Old Church (Petajaveden vanha kirkko), Jaakko Klemetinpoika
## Leppanen, 1763-64 (UNESCO 1994): the log church of a symmetrical Greek
## cross with arms about 17 x 7 m, hand-hewn logs in traditional corner
## joints, high steep shingle-covered hipped roofs crossing over a small
## octagonal lantern, small windows (enlarged 1821), and the log bell
## tower of 1821 by Erkki Leppanen joined to the west end by a short
## passage, its octagonal belfry under a bell-shaped shingle roof.
const PETAJA_TOP := 21.5

static func petajavesi(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Log", LandmarkMaterials.pbr("wood", "#6E5846", 1.8))
	lm.use("Shingle", LandmarkFrKit.shingle("#54483E"))
	lm.use("Ochre", LandmarkMaterials.pbr("wood", "#8E4A32", 1.8))
	lm.use("Glass", LandmarkMaterials.glass("#20282C"))
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#7C776D", 3.0))
	var eave := 5.8
	# The cross: east-west arm and north-south arm, logs to the eaves on a
	# fieldstone footing, with log courses and corner joints.
	LandmarkFrKit.rect(lm, "Stone", -1.8, 17.5, -4.9, 4.6, 0.0, 0.5)
	LandmarkFrKit.rect(lm, "Stone", 3.0, 12.4, -9.5, 9.5, 0.0, 0.5)
	LandmarkFrKit.rect(lm, "Log", -1.4, 17.1, -4.5, 4.2, 0.5, eave)
	LandmarkFrKit.rect(lm, "Log", 3.3, 12.0, -9.1, 9.1, 0.5, eave)
	for w in [[Vector3(-1.4, 0.5, -4.5), Vector3(3.3, 0.5, -4.5), Vector3.FORWARD],
			[Vector3(12.0, 0.5, -4.5), Vector3(17.1, 0.5, -4.5), Vector3.FORWARD],
			[Vector3(-1.4, 0.5, 4.2), Vector3(3.3, 0.5, 4.2), Vector3.BACK],
			[Vector3(12.0, 0.5, 4.2), Vector3(17.1, 0.5, 4.2), Vector3.BACK],
			[Vector3(3.3, 0.5, -9.1), Vector3(12.0, 0.5, -9.1), Vector3.FORWARD],
			[Vector3(3.3, 0.5, 9.1), Vector3(12.0, 0.5, 9.1), Vector3.BACK],
			[Vector3(17.1, 0.5, -4.5), Vector3(17.1, 0.5, 4.2), Vector3.RIGHT],
			[Vector3(-1.4, 0.5, -4.5), Vector3(-1.4, 0.5, 4.2), Vector3.LEFT],
			[Vector3(3.3, 0.5, 4.2), Vector3(3.3, 0.5, 9.1), Vector3.LEFT],
			[Vector3(3.3, 0.5, -9.1), Vector3(3.3, 0.5, -4.5), Vector3.LEFT],
			[Vector3(12.0, 0.5, 4.2), Vector3(12.0, 0.5, 9.1), Vector3.RIGHT],
			[Vector3(12.0, 0.5, -9.1), Vector3(12.0, 0.5, -4.5), Vector3.RIGHT]]:
		LandmarkFrParts.log_courses(lm, "Log", w[0], w[1], w[2], eave - 0.5, 0.32)
	LandmarkFrParts.log_corners(lm, "Log", -1.4, 17.1, -4.5, 4.2, 0.5, eave, 0.32, 0.3)
	LandmarkFrParts.log_corners(lm, "Log", 3.3, 12.0, -9.1, 9.1, 0.5, eave, 0.32, 0.3)
	# Steep shingle hips, their ridges and the eave boards.
	LandmarkFrKit.hip(lm, "Shingle", -1.4, 17.1, -4.5, 4.2, eave, 8.6, 0.8)
	LandmarkFrKit.hip(lm, "Shingle", 3.3, 12.0, -9.1, 9.1, eave, 8.6, 0.8)
	lm.beam("Ochre", Vector3(3.9, eave + 8.65, -0.15), Vector3(11.4, eave + 8.65, -0.15), 0.25, 0.2)
	lm.beam("Ochre", Vector3(7.65, eave + 8.65, -4.6), Vector3(7.65, eave + 8.65, 4.6), 0.25, 0.2)
	for hp in [[-2.2, 17.9, -5.3, 5.0], [2.5, 12.8, -9.9, 9.9]]:
		var hx0: float = hp[0]
		var hx1: float = hp[1]
		var hz0: float = hp[2]
		var hz1: float = hp[3]
		for e in [[Vector3(hx0, eave, hz0), Vector3(hx1, eave, hz0)], [Vector3(hx1, eave, hz0), Vector3(hx1, eave, hz1)],
				[Vector3(hx1, eave, hz1), Vector3(hx0, eave, hz1)], [Vector3(hx0, eave, hz1), Vector3(hx0, eave, hz0)]]:
			lm.beam("Ochre", e[0] as Vector3 - Vector3(0, 0.12, 0), e[1] as Vector3 - Vector3(0, 0.12, 0), 0.25, 0.1,
				Vector3.UP)
	# Octagonal lantern on the crossing.
	var c := Vector3(7.65, eave + 8.6, -0.15)
	lm.frustum("Log", c, 1.9, 1.8, 2.0, 8, PI / 8.0)
	for k in 8:
		var a := TAU * float(k) / 8.0 + PI / 8.0
		LandmarkFrParts.opening(lm, "", "Glass", c + Vector3(cos(a), 0, sin(a)) * 1.72 + Vector3(0, 0.5, 0),
			Vector3(cos(a), 0, sin(a)), 0.5, 1.0)
	lm.lathe("Shingle", c + Vector3(0, 2.0, 0), PackedVector2Array([Vector2(2.4, 0), Vector2(1.6, 0.9),
		Vector2(0.9, 1.9), Vector2(0.15, 2.8)]), 8, 1.0, 1.0, PI / 8.0, false)
	lm.box("Ochre", c + Vector3(0, 5.0, 0), Vector3(0.12, 0.7, 0.12))
	# Windows in the arm ends and long sides with plank frames; the doors.
	for k in 2:
		var y := 1.6 + 2.0 * float(k)
		LandmarkFrParts.opening(lm, "Ochre", "Glass", Vector3(17.1, y, -0.15), Vector3.RIGHT, 1.1, 1.4,
			LandmarkFrParts.HEAD_FLAT, 0.14, 0.12, 1)
		LandmarkFrParts.opening(lm, "Ochre", "Glass", Vector3(7.65, y, 9.1), Vector3.BACK, 1.1, 1.4,
			LandmarkFrParts.HEAD_FLAT, 0.14, 0.12, 1)
		LandmarkFrParts.opening(lm, "Ochre", "Glass", Vector3(7.65, y, -9.1), Vector3.FORWARD, 1.1, 1.4,
			LandmarkFrParts.HEAD_FLAT, 0.14, 0.12, 1)
		for sz: float in [-1.0, 1.0]:
			var wz: float = 4.2 if sz > 0.0 else -4.5
			for wx: float in [0.9, 14.6]:
				LandmarkFrParts.opening(lm, "Ochre", "Glass", Vector3(wx, y, wz), Vector3(0, 0, sz), 1.1, 1.4,
					LandmarkFrParts.HEAD_FLAT, 0.14, 0.12, 1)
	LandmarkFrParts.opening(lm, "Ochre", "Ochre", Vector3(7.65, 0.5, 9.1), Vector3.BACK, 1.3, 2.1,
		LandmarkFrParts.HEAD_FLAT, 0.16, 0.12)
	LandmarkFrParts.opening(lm, "Ochre", "Ochre", Vector3(7.65, 0.5, -9.1), Vector3.FORWARD, 1.3, 2.1,
		LandmarkFrParts.HEAD_FLAT, 0.16, 0.12)
	# Passage and the bell tower: log base, octagonal belfry with its
	# openings, bell-shaped shingle roof and a small spire.
	LandmarkFrKit.house(lm, "Log", "Shingle", -7.2, -1.4, -2.8, 2.3, 0.0, 3.4, 2.2, 0.4, 1)
	LandmarkFrParts.log_courses(lm, "Log", Vector3(-7.1, 0.0, 2.3), Vector3(-1.4, 0.0, 2.3), Vector3.BACK, 3.4, 0.32)
	LandmarkFrParts.log_courses(lm, "Log", Vector3(-7.1, 0.0, -2.8), Vector3(-1.4, 0.0, -2.8), Vector3.FORWARD, 3.4, 0.32)
	LandmarkFrKit.rect(lm, "Stone", -17.5, -6.7, -5.8, 5.1, 0.0, 0.5)
	LandmarkFrKit.rect(lm, "Log", -17.1, -7.1, -5.4, 4.7, 0.5, 9.0)
	LandmarkFrParts.log_corners(lm, "Log", -17.1, -7.1, -5.4, 4.7, 0.5, 9.0, 0.32, 0.3)
	for w2 in [[Vector3(-17.1, 0.5, -5.4), Vector3(-7.1, 0.5, -5.4), Vector3.FORWARD],
			[Vector3(-17.1, 0.5, 4.7), Vector3(-7.1, 0.5, 4.7), Vector3.BACK],
			[Vector3(-17.1, 0.5, -5.4), Vector3(-17.1, 0.5, 4.7), Vector3.LEFT]]:
		LandmarkFrParts.log_courses(lm, "Log", w2[0], w2[1], w2[2], 8.5, 0.32)
	LandmarkFrKit.hip(lm, "Shingle", -17.1, -7.1, -5.4, 4.7, 9.0, 3.4, 0.8)
	LandmarkFrParts.opening(lm, "Ochre", "Ochre", Vector3(-12.1, 0.5, 4.7), Vector3.BACK, 1.4, 2.2,
		LandmarkFrParts.HEAD_FLAT, 0.16, 0.12)
	LandmarkFrParts.opening(lm, "Ochre", "Glass", Vector3(-17.1, 4.0, -0.35), Vector3.LEFT, 1.0, 1.3,
		LandmarkFrParts.HEAD_FLAT, 0.14, 0.12, 1)
	var bt := Vector3(-12.1, 12.4, -0.35)
	lm.frustum("Log", bt, 3.4, 3.1, 3.4, 8, PI / 8.0)
	for k in 8:
		var a2 := TAU * float(k) / 8.0
		var on := Vector3(cos(a2), 0, sin(a2))
		LandmarkFrParts.opening(lm, "Ochre", "Glass", bt + on * 3.05 + Vector3(0, 0.7, 0), on, 1.0, 1.9,
			LandmarkFrParts.HEAD_ROUND, 0.12, 0.1)
	lm.lathe("Shingle", bt + Vector3(0, 3.4, 0), PackedVector2Array([Vector2(4.2, 0), Vector2(3.6, 0.9),
		Vector2(2.6, 1.6), Vector2(2.0, 2.4), Vector2(1.4, 3.6), Vector2(0.14, 5.2)]), 8, 1.0, 1.0, PI / 8.0, false)
	lm.lathe("Ochre", bt + Vector3(0, 8.4, 0), LandmarkFrKit.ball(0.25), 8)
	lm.box("Ochre", bt + Vector3(0, 8.9, 0), Vector3(0.14, 0.4, 0.14))
	lm.commit(model)

## Ainola (Lars Sonck, 1903-04, upper floor 1911), Jarvenpaa: the home of
## Jean Sibelius, a two-storey log villa of planed pine (about 5 km of
## logs from Suolahti) clad in vertical boards painted white with green
## window frames and dark green bargeboards, under a varied steep roof of
## red clay tiles (1932, replacing the shingles); the large open entrance
## porch, the round-log veranda and balconies on the west and the south
## gable, and the chimney stacks of its eleven tiled stoves.
const AINOLA_TOP := 12.5

static func ainola(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Log", LandmarkMaterials.pbr("wood", "#EAE4D2", 1.8))
	lm.use("Roof", LandmarkMaterials.pbr("terracotta", "#8E4533", 2.5))
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#8F4631", 2.0))
	lm.use("Trim", LandmarkMaterials.pbr("wood", "#3F6B50", 1.8))
	lm.use("Posts", LandmarkMaterials.pbr("wood", "#7A5638", 1.8))
	lm.use("Glass", LandmarkMaterials.glass("#20282C"))
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#7E786D", 3.0))
	LandmarkFrKit.rect(lm, "Stone", -9.8, 9.8, -4.3, 8.2, 0.0, 0.7)
	LandmarkFrKit.rect(lm, "Log", -9.6, 9.6, -4.1, 8.0, 0.7, 6.0)
	LandmarkFrKit.hip(lm, "Roof", -9.6, 9.6, -4.1, 8.0, 6.0, 4.4, 0.8)
	LandmarkFrParts.corner_strips(lm, "Log", -9.6, 9.6, -4.1, 8.0, 0.7, 6.0, 0.25, 0.06)
	for f in [[Vector3(-9.6, 0.7, 8.0), Vector3(9.6, 0.7, 8.0), Vector3.BACK],
			[Vector3(-9.6, 0.7, -4.1), Vector3(-4.8, 0.7, -4.1), Vector3.FORWARD],
			[Vector3(4.8, 0.7, -4.1), Vector3(9.6, 0.7, -4.1), Vector3.FORWARD],
			[Vector3(-9.6, 0.7, -4.1), Vector3(-9.6, 0.7, 8.0), Vector3.LEFT],
			[Vector3(9.6, 0.7, -4.1), Vector3(9.6, 0.7, 8.0), Vector3.RIGHT]]:
		LandmarkFrParts.battens(lm, "Log", f[0], f[1], f[2], 5.3, 0.45, 0.05)
	# Eave boards (dark green) round the main roof.
	for e in [[Vector3(-10.4, 5.9, -4.9), Vector3(10.4, 5.9, -4.9)], [Vector3(10.4, 5.9, -4.9), Vector3(10.4, 5.9, 8.8)],
			[Vector3(10.4, 5.9, 8.8), Vector3(-10.4, 5.9, 8.8)], [Vector3(-10.4, 5.9, 8.8), Vector3(-10.4, 5.9, -4.9)]]:
		lm.beam("Trim", e[0] as Vector3, e[1] as Vector3, 0.25, 0.08, Vector3.UP)
	# Entrance bay on the north side with its own gable and the open porch.
	LandmarkFrKit.rect(lm, "Log", -4.8, 4.8, -8.0, -4.1, 0.7, 5.4)
	LandmarkFrKit.gable(lm, "Roof", -4.8, 4.8, -8.0, -4.1, 5.4, 3.0, 0.6, "Log", 0)
	LandmarkFrParts.roof_trim(lm, "Trim", -4.8, 4.8, -8.0, -4.1, 5.4, 3.0, 0.6, 0, 0.2)
	LandmarkFrParts.battens(lm, "Log", Vector3(-4.8, 0.7, -8.0), Vector3(4.8, 0.7, -8.0), Vector3.FORWARD, 4.7, 0.45, 0.05)
	LandmarkFrKit.rect(lm, "Stone", -2.2, 2.2, -10.4, -8.0, 0.0, 0.5)
	for s: float in [-1.0, 1.0]:
		lm.box("Posts", Vector3(s * 1.9, 1.95, -10.1), Vector3(0.3, 2.9, 0.3))
	LandmarkFrKit.gable(lm, "Roof", -2.3, 2.3, -10.5, -8.0, 3.4, 1.5, 0.2, "Log", 0)
	LandmarkFrParts.opening(lm, "Trim", "Posts", Vector3(0, 0.5, -8.0), Vector3.FORWARD, 1.2, 2.2,
		LandmarkFrParts.HEAD_FLAT, 0.15, 0.1)
	LandmarkFrParts.openings(lm, "Trim", "Glass", Vector3(-4.8, 2.0, -8.0), Vector3(4.8, 2.0, -8.0), Vector3.FORWARD, 4,
		0.9, 1.5, LandmarkFrParts.HEAD_FLAT, 0.12, 0.1, 1)
	LandmarkFrParts.opening(lm, "Trim", "Glass", Vector3(0, 6.0, -8.0), Vector3.FORWARD, 1.0, 1.2,
		LandmarkFrParts.HEAD_FLAT, 0.12, 0.1, 1)
	# Veranda on the garden side: round-log posts, balustrade, lean-to roof.
	LandmarkFrKit.rect(lm, "Stone", -6.5, 6.5, 8.0, 11.2, 0.0, 0.6)
	for k in 6:
		var x := -6.0 + 2.4 * float(k)
		lm.frustum("Posts", Vector3(x, 0.6, 11.0), 0.16, 0.14, 3.0, 8)
	lm.box("Posts", Vector3(0, 1.1, 11.0), Vector3(12.6, 0.14, 0.14))
	for k2 in 25:
		lm.box("Posts", Vector3(-6.0 + 0.5 * float(k2), 0.85, 11.0), Vector3(0.06, 0.5, 0.06), Basis(), 0.0)
	lm.quad("Roof", Vector3(-6.8, 3.6, 11.4), Vector3(6.8, 3.6, 11.4), Vector3(6.8, 4.9, 8.0), Vector3(-6.8, 4.9, 8.0),
		Vector3(0, 3.0, 1.3).normalized())
	lm.beam("Trim", Vector3(-6.8, 3.55, 11.4), Vector3(6.8, 3.55, 11.4), 0.2, 0.08, Vector3.UP)
	# Balcony on the west gable: round-log posts and rail.
	LandmarkFrKit.rect(lm, "Posts", -11.6, -9.6, 0.0, 4.0, 3.4, 3.6)
	for z: float in [0.2, 2.0, 3.8]:
		lm.frustum("Posts", Vector3(-11.4, 0.7, z), 0.13, 0.12, 2.7, 8)
	LandmarkFrParts.railing(lm, "Posts", Vector3(-11.5, 3.6, 0.1), Vector3(-11.5, 3.6, 3.9), 1.0, 0.5, 0.08)
	# White-framed windows (green sashes) with glazing bars, both storeys.
	for k in 4:
		var x2 := -6.0 + 4.0 * float(k)
		LandmarkFrParts.opening(lm, "Trim", "Glass", Vector3(x2, 1.4, 8.0), Vector3.BACK, 1.5, 1.8,
			LandmarkFrParts.HEAD_FLAT, 0.14, 0.1, 2)
		LandmarkFrParts.opening(lm, "Trim", "Glass", Vector3(x2, 4.3, 8.0), Vector3.BACK, 1.1, 1.3,
			LandmarkFrParts.HEAD_FLAT, 0.12, 0.1, 1)
	for x3: float in [-7.4, 7.4]:
		LandmarkFrParts.opening(lm, "Trim", "Glass", Vector3(x3, 1.4, -4.1), Vector3.FORWARD, 1.3, 1.7,
			LandmarkFrParts.HEAD_FLAT, 0.14, 0.1, 2)
	for sx: float in [-1.0, 1.0]:
		for z2: float in [-1.5, 5.2]:
			LandmarkFrParts.opening(lm, "Trim", "Glass", Vector3(sx * 9.6, 1.4, z2), Vector3(sx, 0, 0), 1.3, 1.7,
				LandmarkFrParts.HEAD_FLAT, 0.14, 0.1, 2)
		LandmarkFrParts.opening(lm, "Trim", "Glass", Vector3(sx * 9.6, 4.2, 1.9), Vector3(sx, 0, 0), 1.1, 1.3,
			LandmarkFrParts.HEAD_FLAT, 0.12, 0.1, 1)
	# Dormers on the main roof and the tall brick chimney stacks.
	LandmarkFrParts.dormer(lm, "Log", "Roof", "Glass", Vector3(0, 7.1, 7.4), Vector3.BACK, 2.2, 1.5, 1.6)
	LandmarkFrParts.dormer(lm, "Log", "Roof", "Glass", Vector3(-5.5, 7.1, -3.5), Vector3.FORWARD, 1.6, 1.3, 1.4)
	for x4: float in [-5.5, 5.5]:
		LandmarkFrParts.chimney(lm, "Brick", Vector3(x4, 4.4, 2.0), 12.5, 1.5)
	lm.commit(model)

## Hvittrask (Gesellius, Lindgren and Saarinen, 1901-03), Kirkkonummi: the
## National Romantic studio-home above Lake Vittrask in grey natural
## stone and dark logs: massive granite lower storeys, log upper floors
## with board gables under steep red-tile roofs with dormers, tall stone
## chimneys and the round stair tower; the south wing was Saarinen's, the
## north wing (burnt 1922) rebuilt 1929-36 to Eero Saarinen's plans.
## The long axis (X) of the real plan runs north-north-east.
const HVITTRASK_TOP := 14.5

static func hvittrask(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#8C877C", 3.0))
	lm.use("Log", LandmarkMaterials.pbr("wood", "#785A44", 1.8))
	lm.use("Roof", LandmarkMaterials.pbr("terracotta", "#8F4A34", 2.5))
	lm.use("Trim", LandmarkMaterials.pbr("render", "#E9E5D8", 2.0))
	lm.use("Glass", LandmarkMaterials.glass("#20282C"))
	# West block (x -25.4..-7, z -9.1..9.1): stone storey, logs, steep roof.
	_hv_block(lm, -25.4, -7.0, -9.1, 9.1, 3.2, 7.4, 6.2, 0)
	# Long middle range (x -7..25.4, z -8.2..1.8) with the east gable.
	_hv_block(lm, -7.0, 25.4, -8.2, 1.8, 3.0, 6.6, 5.0, 1)
	# South wing at the east end with its gable to the lake.
	_hv_block(lm, 19.0, 25.4, 1.8, 9.1, 3.0, 6.4, 3.4, 0)
	# Board gables with a window at the ends.
	LandmarkFrParts.battens(lm, "Log", Vector3(-24.4, 7.4, 9.1), Vector3(-8.0, 7.4, 9.1), Vector3.BACK, 1.0, 0.5, 0.06)
	LandmarkFrParts.opening(lm, "Trim", "Glass", Vector3(-16.2, 8.6, 9.1), Vector3.BACK, 1.6, 2.2,
		LandmarkFrParts.HEAD_ROUND, 0.16, 0.1, 1)
	LandmarkFrParts.opening(lm, "Trim", "Glass", Vector3(-16.2, 8.6, -9.1), Vector3.FORWARD, 1.6, 2.2,
		LandmarkFrParts.HEAD_ROUND, 0.16, 0.1, 1)
	LandmarkFrParts.opening(lm, "Trim", "Glass", Vector3(25.4, 7.4, -3.2), Vector3.RIGHT, 1.4, 1.8,
		LandmarkFrParts.HEAD_ROUND, 0.16, 0.1, 1)
	LandmarkFrParts.opening(lm, "Trim", "Glass", Vector3(22.2, 7.0, 9.1), Vector3.BACK, 1.2, 1.6,
		LandmarkFrParts.HEAD_ROUND, 0.16, 0.1, 1)
	# Dormers on the long south roof, round stair tower, stone chimneys.
	for k in 5:
		var x := -2.0 + 6.0 * float(k)
		lm.box("Log", Vector3(x, 8.2, 0.4), Vector3(2.2, 2.6, 2.0))
		LandmarkFrKit.gable(lm, "Roof", x - 1.1, x + 1.1, -0.6, 1.4, 9.5, 1.2, 0.2, "Log", 0)
		LandmarkFrParts.opening(lm, "Trim", "Glass", Vector3(x, 7.6, 1.4), Vector3.BACK, 1.1, 1.3,
			LandmarkFrParts.HEAD_FLAT, 0.12, 0.08, 1)
	lm.frustum("Stone", Vector3(-7.0, 0, 9.1), 3.0, 2.88, 9.0, 24)
	lm.lathe("Roof", Vector3(-7.0, 9.0, 9.1), PackedVector2Array([Vector2(3.5, 0), Vector2(2.6, 1.6),
		Vector2(1.2, 3.8), Vector2(0.06, 5.4)]), 24)
	for k2 in 3:
		var a := PI * 0.5 + 0.5 * float(k2 - 1)
		var on := Vector3(cos(a), 0, sin(a))
		LandmarkFrParts.opening(lm, "Trim", "Glass", Vector3(-7.0, 1.8 + 2.4 * float(k2), 9.1) + on * 2.92, on, 0.6,
			1.1, LandmarkFrParts.HEAD_ROUND, 0.12, 0.08)
	for p in [Vector3(-16.0, 0, 0.0), Vector3(8.0, 0, -3.0), Vector3(22.2, 0, 5.4)]:
		var pv: Vector3 = p
		lm.box("Stone", Vector3(pv.x, 8.3, pv.z), Vector3(1.8, 12.0, 1.8))
		lm.box("Trim", Vector3(pv.x, 14.35, pv.z), Vector3(2.2, 0.3, 2.2))
		lm.box("Stone", Vector3(pv.x, 13.6, pv.z), Vector3(2.0, 0.4, 2.0))
	# Windows: stone-framed below, small-paned in the logs above.
	for k3 in 4:
		var wx := -21.5 + 4.2 * float(k3)
		LandmarkFrParts.opening(lm, "Trim", "Glass", Vector3(wx, 4.0, 9.1), Vector3.BACK, 1.4, 1.8,
			LandmarkFrParts.HEAD_FLAT, 0.14, 0.1, 2)
		LandmarkFrParts.opening(lm, "Stone", "Glass", Vector3(wx, 0.9, 9.1), Vector3.BACK, 1.0, 1.4,
			LandmarkFrParts.HEAD_ROUND, 0.3, 0.16, 1)
		LandmarkFrParts.opening(lm, "Trim", "Glass", Vector3(wx, 4.0, -9.1), Vector3.FORWARD, 1.4, 1.8,
			LandmarkFrParts.HEAD_FLAT, 0.14, 0.1, 2)
	LandmarkFrParts.openings(lm, "Trim", "Glass", Vector3(-5.0, 3.8, -8.2), Vector3(24.0, 3.8, -8.2), Vector3.FORWARD, 6,
		1.3, 1.7, LandmarkFrParts.HEAD_FLAT, 0.14, 0.1, 2)
	LandmarkFrParts.openings(lm, "Stone", "Glass", Vector3(-5.0, 0.8, -8.2), Vector3(24.0, 0.8, -8.2), Vector3.FORWARD, 6,
		1.0, 1.4, LandmarkFrParts.HEAD_ROUND, 0.3, 0.16, 1)
	LandmarkFrParts.openings(lm, "Trim", "Glass", Vector3(-4.0, 3.8, 1.8), Vector3(18.0, 3.8, 1.8), Vector3.BACK, 4,
		1.3, 1.7, LandmarkFrParts.HEAD_FLAT, 0.14, 0.1, 2)
	LandmarkFrParts.opening(lm, "Stone", "Glass", Vector3(3.0, 0.0, 1.8), Vector3.BACK, 1.6, 2.6,
		LandmarkFrParts.HEAD_ROUND, 0.4, 0.22)
	lm.commit(model)

## Hvittrask block: granite storey to `stone_h` with coursed bands, log
## storey with courses and corner joints to the eaves, red-tile roof with
## its bargeboards (ridge along X when ridge_x = 1, along Z when 0).
static func _hv_block(lm: LandmarkMesh, x0: float, x1: float, z0: float, z1: float, stone_h: float, eave: float,
		rise: float, ridge_x: int) -> void:
	LandmarkFrKit.rect(lm, "Stone", x0 - 0.2, x1 + 0.2, z0 - 0.2, z1 + 0.2, 0.0, 0.6)
	LandmarkFrKit.rect(lm, "Stone", x0, x1, z0, z1, 0.0, stone_h)
	LandmarkFrParts.band(lm, "Stone", x0, x1, z0, z1, stone_h - 0.35, 0.35, 0.12)
	LandmarkFrKit.rect(lm, "Log", x0, x1, z0, z1, stone_h, eave)
	LandmarkFrParts.log_corners(lm, "Log", x0, x1, z0, z1, stone_h, eave, 0.3, 0.3)
	for w in [[Vector3(x0, stone_h, z0), Vector3(x1, stone_h, z0), Vector3.FORWARD],
			[Vector3(x0, stone_h, z1), Vector3(x1, stone_h, z1), Vector3.BACK],
			[Vector3(x0, stone_h, z0), Vector3(x0, stone_h, z1), Vector3.LEFT],
			[Vector3(x1, stone_h, z0), Vector3(x1, stone_h, z1), Vector3.RIGHT]]:
		LandmarkFrParts.log_courses(lm, "Log", w[0], w[1], w[2], eave - stone_h, 0.3)
	LandmarkFrKit.gable(lm, "Roof", x0, x1, z0, z1, eave, rise, 0.9, "Log", ridge_x)
	LandmarkFrParts.roof_trim(lm, "Log", x0, x1, z0, z1, eave, rise, 0.9, ridge_x, 0.3)
