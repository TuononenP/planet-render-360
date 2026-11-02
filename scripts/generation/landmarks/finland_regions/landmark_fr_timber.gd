class_name LandmarkFrTimber
extends RefCounted

## Finnish timber landmarks in true metres, in the frame of the real plan
## (+X east, +Z south, turned onto the map by yaw_deg): Kerimaki Church,
## Petajavesi Old Church, Sibelius' Ainola and Hvittrask. Plans follow the
## OpenStreetMap footprints.

## Kerimaki Church (Kerimaen kirkko), Anders Fredrik Granstedt, 1847: the
## world's largest wooden church, a Greek cross 45 m long and 42 m wide in
## pale-yellow painted boards with three rows of windows, the great green
## roofs (ridge 27 m) crossing over the centre, the octagonal drum and
## dome-shaped cupola with its cross at 37 m, and a pedimented entrance on
## each end of the east-west arm. The 42 m belfry beside it is left out.
const KERIMAKI_TOP := 37.0

static func kerimaki(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("wood", "#E0D3A2", 2.0))
	lm.use("Trim", LandmarkMaterials.pbr("wood", "#EFEBDD", 2.0))
	lm.use("Roof", LandmarkMaterials.pbr("concrete", "#5E8566", 2.5, 0.55, 0.3))
	lm.use("Glass", LandmarkMaterials.glass("#20282C"))
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#8A857A", 3.0))
	lm.use("Gilt", LandmarkMaterials.gold())
	# Central block (x -25.5..5.5, z -22.3..22.3) and the two end arms.
	LandmarkFrKit.rect(lm, "Stone", -25.8, 5.8, -22.6, 22.6, 0.0, 1.0)
	LandmarkFrKit.rect(lm, "Wall", -25.5, 5.5, -22.3, 22.3, 1.0, 12.0)
	LandmarkFrKit.gable(lm, "Roof", -25.5, 5.5, -22.3, 22.3, 12.0, 15.0, 0.9, "Wall", 0)
	LandmarkFrKit.rect(lm, "Wall", 5.5, 35.0, -7.2, 6.2, 0.0, 10.5)
	LandmarkFrKit.gable(lm, "Roof", -2.0, 35.0, -7.2, 6.2, 10.5, 7.5, 0.7, "Wall", 1)
	LandmarkFrKit.rect(lm, "Wall", -35.0, -25.5, -8.8, 8.0, 0.0, 10.5)
	LandmarkFrKit.gable(lm, "Roof", -35.0, -18.0, -8.8, 8.0, 10.5, 7.5, 0.7, "Wall", 1)
	# Three rows of windows on every wall of the cross, doors in the arms.
	for row in 3:
		var y := 3.0 + 3.6 * float(row)
		for sz in [-1.0, 1.0]:
			LandmarkFrKit.windows(lm, "Glass", Vector3(-10.0, y, sz * 22.35), Vector3.RIGHT, 6, 4.4,
				Vector3(1.4, 2.3, 0.15))
		for sx in [5.55, -25.55]:
			LandmarkFrKit.windows(lm, "Glass", Vector3(sx, y, 14.5), Vector3.BACK, 2, 4.4, Vector3(0.15, 2.3, 1.4))
			LandmarkFrKit.windows(lm, "Glass", Vector3(sx, y, -14.5), Vector3.BACK, 2, 4.4, Vector3(0.15, 2.3, 1.4))
		LandmarkFrKit.windows(lm, "Glass", Vector3(35.05, y, 0), Vector3.BACK, 1, 1.0, Vector3(0.15, 2.3, 1.6))
		LandmarkFrKit.windows(lm, "Glass", Vector3(-35.05, y, 0), Vector3.BACK, 1, 1.0, Vector3(0.15, 2.3, 1.6))
	for sx in [-1.0, 1.0]:
		var ex: float = 35.0 if sx > 0.0 else -35.0
		lm.box("Trim", Vector3(ex, 2.0, 0), Vector3(0.3, 4.0, 2.2))
		for sz in [-1.0, 1.0]:
			lm.box("Trim", Vector3(ex + sx * 0.3, 5.0, sz * 4.4), Vector3(0.3, 10.0, 0.6))
	# Central drum, dome-shaped cupola, lantern and cross on the crossing.
	var c := Vector3(-10.0, 27.0, 0.0)
	lm.frustum("Wall", c, 5.0, 4.8, 4.0, 8, PI / 8.0)
	for k in 8:
		var a := TAU * float(k) / 8.0 + PI / 8.0
		lm.box("Glass", c + Vector3(cos(a) * 4.9, 2.0, sin(a) * 4.9), Vector3(0.15, 2.0, 1.7),
			Basis(Vector3.UP, -a + PI * 0.5))
	lm.frustum("Trim", c + Vector3(0, 4.0, 0), 5.5, 5.4, 0.7, 8, PI / 8.0)
	lm.lathe("Roof", c + Vector3(0, 4.7, 0), LandmarkFrKit.dome(5.4, 3.3), 16)
	lm.frustum("Wall", c + Vector3(0, 8.0, 0), 1.3, 1.2, 0.8, 8)
	LandmarkFrKit.cross(lm, "Gilt", c + Vector3(0, 8.8, 0), 1.2)
	lm.commit(model)

## Petajavesi Old Church (Petajaveden vanha kirkko), Jaakko Klemetinpoika
## Leppanen, 1764 (UNESCO): the log church of a Greek cross with arms about
## 17 x 7 m, the high steep hipped shingle roofs crossing over a small
## octagonal cupola, ochre-trimmed boards, and the separate log bell tower of
## 1821 joined to the west end by a short passage.
const PETAJA_TOP := 21.5

static func petajavesi(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Log", LandmarkMaterials.pbr("wood", "#6E5846", 1.8))
	lm.use("Shingle", LandmarkFrKit.shingle("#54483E"))
	lm.use("Ochre", LandmarkMaterials.pbr("wood", "#8E4A32", 1.8))
	lm.use("Glass", LandmarkMaterials.glass("#20282C"))
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#7C776D", 3.0))
	var eave := 5.8
	# The cross: east-west arm and north-south arm, logs to the eaves.
	LandmarkFrKit.rect(lm, "Stone", -1.8, 17.5, -4.9, 4.6, -0.5, 0.5)
	LandmarkFrKit.rect(lm, "Stone", 3.0, 12.4, -9.5, 9.5, -0.5, 0.5)
	LandmarkFrKit.rect(lm, "Log", -1.4, 17.1, -4.5, 4.2, 0.5, eave)
	LandmarkFrKit.rect(lm, "Log", 3.3, 12.0, -9.1, 9.1, 0.5, eave)
	LandmarkFrKit.hip(lm, "Shingle", -1.4, 17.1, -4.5, 4.2, eave, 8.6, 0.8)
	LandmarkFrKit.hip(lm, "Shingle", 3.3, 12.0, -9.1, 9.1, eave, 8.6, 0.8)
	# Octagonal cupola on the crossing.
	var c := Vector3(7.65, eave + 8.6, 0.0)
	lm.frustum("Log", c, 1.9, 1.8, 2.0, 8, PI / 8.0)
	lm.lathe("Shingle", c + Vector3(0, 2.0, 0), PackedVector2Array([Vector2(2.4, 0), Vector2(0.15, 2.8)]), 8, 1.0, 1.0,
		PI / 8.0, false)
	lm.box("Ochre", c + Vector3(0, 5.0, 0), Vector3(0.12, 0.7, 0.12))
	# Windows in the arm ends and long sides, ochre bargeboards on the gables.
	for k in 2:
		var y := 2.2 + 2.2 * float(k)
		lm.box("Glass", Vector3(17.15, y, 0), Vector3(0.15, 1.5, 1.2))
		lm.box("Glass", Vector3(7.65, y, 9.15), Vector3(1.2, 1.5, 0.15))
		lm.box("Glass", Vector3(7.65, y, -9.15), Vector3(1.2, 1.5, 0.15))
		for sz in [-1.0, 1.0]:
			lm.box("Glass", Vector3(10.0, y, sz * 4.25), Vector3(1.2, 1.5, 0.15))
			lm.box("Glass", Vector3(0.5, y, sz * 4.25), Vector3(1.2, 1.5, 0.15))
	lm.box("Ochre", Vector3(17.2, 1.0, 0), Vector3(0.2, 2.0, 1.2))
	# Passage and the bell tower: logs, a tent-roofed lantern and a shingle spire.
	LandmarkFrKit.house(lm, "Log", "Shingle", -7.2, -1.4, -2.8, 2.3, 0.0, 3.4, 2.2, 0.4, 1)
	LandmarkFrKit.rect(lm, "Log", -17.1, -7.1, -5.4, 4.7, 0.0, 9.0)
	LandmarkFrKit.hip(lm, "Shingle", -17.1, -7.1, -5.4, 4.7, 9.0, 3.4, 0.8)
	var bt := Vector3(-12.1, 12.4, -0.35)
	lm.frustum("Log", bt, 3.4, 3.1, 3.4, 8, PI / 8.0)
	lm.lathe("Shingle", bt + Vector3(0, 3.4, 0), PackedVector2Array([Vector2(4.2, 0), Vector2(3.6, 0.9),
		Vector2(0.14, 5.2)]), 8, 1.0, 1.0, PI / 8.0, false)
	lm.box("Ochre", bt + Vector3(0, 8.9, 0), Vector3(0.14, 0.4, 0.14))
	lm.box("Glass", Vector3(-12.1, 4.8, 4.75), Vector3(1.4, 2.2, 0.15))
	lm.commit(model)

## Ainola (Lars Sonck, 1904), Jarvenpaa: the home of Jean Sibelius, a
## two-storey log villa clad in white-painted vertical boards with green
## trim under a steep hipped roof of red clay tiles (1932), an entrance
## bay, the veranda of round logs on the garden side and the tall
## chimney stacks.
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
	LandmarkFrKit.rect(lm, "Stone", -9.8, 9.8, -4.3, 8.2, -0.5, 0.7)
	LandmarkFrKit.rect(lm, "Log", -9.6, 9.6, -4.1, 8.0, 0.7, 6.0)
	LandmarkFrKit.hip(lm, "Roof", -9.6, 9.6, -4.1, 8.0, 6.0, 4.4, 0.8)
	# Entrance bay on the north side with its own gable.
	LandmarkFrKit.rect(lm, "Log", -4.8, 4.8, -8.0, -4.1, 0.7, 5.4)
	LandmarkFrKit.gable(lm, "Roof", -4.8, 4.8, -8.0, -4.1, 5.4, 3.0, 0.6, "Log", 0)
	# Veranda on the garden side: white posts, balustrade and a lean-to roof.
	LandmarkFrKit.rect(lm, "Stone", -6.5, 6.5, 8.0, 11.2, -0.3, 0.6)
	for k in 6:
		var x := -6.0 + 2.4 * float(k)
		lm.box("Posts", Vector3(x, 2.1, 11.0), Vector3(0.3, 3.0, 0.3))
	lm.box("Posts", Vector3(0, 1.1, 11.0), Vector3(12.6, 0.14, 0.14))
	lm.quad("Roof", Vector3(-6.8, 3.6, 11.4), Vector3(6.8, 3.6, 11.4), Vector3(6.8, 4.9, 8.0), Vector3(-6.8, 4.9, 8.0),
		Vector3(0, 3.0, 1.3).normalized())
	for k in 4:
		var x := -6.0 + 4.0 * float(k)
		_pane(lm, Vector3(x, 2.1, 8.05), Vector3(1.6, 1.8, 0.15))
		_pane(lm, Vector3(x, 5.0, 8.05), Vector3(1.2, 1.4, 0.15))
		_pane(lm, Vector3(x, 5.0, -4.15), Vector3(1.2, 1.4, 0.15))
	for sx in [-1.0, 1.0]:
		_pane(lm, Vector3(sx * 9.65, 2.2, 1.9), Vector3(0.15, 1.8, 1.4))
		_pane(lm, Vector3(sx * 9.65, 4.8, 1.9), Vector3(0.15, 1.4, 1.2))
	# Two tall brick chimney stacks with caps rising over the ridge.
	for x in [-5.5, 5.5]:
		lm.box("Brick", Vector3(x, 8.4, 2.0), Vector3(1.5, 8.0, 1.5))
		lm.box("Stone", Vector3(x, 12.35, 2.0), Vector3(1.9, 0.3, 1.9))
	lm.commit(model)

## A window pane in a green frame (the frame is the wider of the two boxes).
static func _pane(lm: LandmarkMesh, pos: Vector3, size: Vector3) -> void:
	var grow := Vector3(0.0 if size.x < 0.3 else 0.4, 0.4, 0.0 if size.z < 0.3 else 0.4)
	lm.box("Trim", pos, size + grow - Vector3(0.1 if size.x < 0.3 else 0.0, 0.0, 0.1 if size.z < 0.3 else 0.0))
	lm.box("Glass", pos, size)

## Hvittrask (Gesellius, Lindgren and Saarinen, 1901-03), Kirkkonummi: the
## National Romantic studio-home above Lake Vitträsk, a long range of
## massive granite lower storeys and log upper floors under steep red-tile
## roofs with dormers, tall stone chimneys and a round stair tower.
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
	LandmarkFrKit.rect(lm, "Stone", -25.4, -7.0, -9.1, 9.1, 0.0, 3.2)
	LandmarkFrKit.rect(lm, "Log", -25.4, -7.0, -9.1, 9.1, 3.2, 7.4)
	LandmarkFrKit.gable(lm, "Roof", -25.4, -7.0, -9.1, 9.1, 7.4, 6.2, 0.9, "Log", 0)
	# Long middle range (x -7..25.4, z -8.2..1.8) with the east gable.
	LandmarkFrKit.rect(lm, "Stone", -7.0, 25.4, -8.2, 1.8, 0.0, 3.0)
	LandmarkFrKit.rect(lm, "Log", -7.0, 25.4, -8.2, 1.8, 3.0, 6.6)
	LandmarkFrKit.gable(lm, "Roof", -7.0, 25.4, -8.2, 1.8, 6.6, 5.0, 0.9, "Log", 1)
	# South wing at the east end with its gable to the lake.
	LandmarkFrKit.rect(lm, "Stone", 19.0, 25.4, 1.8, 9.1, 0.0, 3.0)
	LandmarkFrKit.rect(lm, "Log", 19.0, 25.4, 1.8, 9.1, 3.0, 6.4)
	LandmarkFrKit.gable(lm, "Roof", 19.0, 25.4, 1.8, 9.1, 6.4, 3.4, 0.7, "Log", 0)
	# Dormers on the long south roof, round stair tower, stone chimneys.
	for k in 5:
		var x := -2.0 + 6.0 * float(k)
		lm.box("Log", Vector3(x, 8.2, 0.4), Vector3(2.2, 2.6, 2.0))
		LandmarkFrKit.gable(lm, "Roof", x - 1.1, x + 1.1, -0.6, 1.4, 9.5, 1.2, 0.2, "Log", 0)
		lm.box("Glass", Vector3(x, 8.2, 1.45), Vector3(1.0, 1.2, 0.15))
	LandmarkFrKit.round_tower(lm, "Stone", "Roof", -7.0, 9.1, 3.0, 0.0, 9.0, 5.4, 12)
	for p in [Vector3(-16.0, 0, 0.0), Vector3(8.0, 0, -3.0)]:
		lm.box("Stone", Vector3(p.x, 8.3, p.z), Vector3(1.8, 12.0, 1.8))
		lm.box("Trim", Vector3(p.x, 14.35, p.z), Vector3(2.2, 0.3, 2.2))
	for k in 4:
		lm.box("Glass", Vector3(-21.5 + 4.2 * float(k), 4.9, 9.15), Vector3(1.4, 1.8, 0.15))
		lm.box("Glass", Vector3(-21.5 + 4.2 * float(k), 1.6, 9.15), Vector3(1.0, 1.4, 0.15))
	lm.commit(model)
