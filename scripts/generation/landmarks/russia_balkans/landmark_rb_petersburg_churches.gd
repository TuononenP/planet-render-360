class_name LandmarkRbPetersburgChurches
extends RefCounted

## Two Saint Petersburg churches in true metres: the Peter and Paul
## Cathedral (cream Petrine Baroque hall with its stepped bell tower and
## the 122.5 m gilded spire and angel) and the Church of the Saviour on
## Spilled Blood (red-brick Muscovite revival: tented central tower,
## four coloured onion domes and the bell tower, 81 m).

const PP_TOP := 122.5

## Origin at the hall centre; the bell tower stands in the west end
## (-X), the apse at the east end (+X); the long walls face north and
## south. Hall 55 x 29 m (OSM outline), apse block 8 x 20 m.
static func peter_paul(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("render", "#E4D5A4", 4.0))
	lm.use("White", LandmarkMaterials.pbr("render", "#F1EDE0", 3.0))
	lm.use("Plinth", LandmarkMaterials.pbr("stone", "#8A8478", 3.0))
	lm.use("Roof", LandmarkMaterials.pbr("slate", "#5F8E78", 3.0, 0.55, 0.3))
	lm.use("Windows", LandmarkMaterials.glass("#26323A"))
	lm.use("Gilt", LandmarkMaterials.gold())
	# Hall (eaves 17 m), cornice, plinth, nave roof and the apse.
	lm.box("Plinth", Vector3(0, 0.6, 0), Vector3(56.2, 1.2, 30.1))
	lm.box("Wall", Vector3(0, 9.0, 0), Vector3(55.2, 17.0, 29.1))
	lm.box("White", Vector3(0, 17.3, 0), Vector3(56.2, 0.9, 30.1))
	lm.gable("Roof", Vector3(8.0, 17.7, 0), 29.1, 39.0, 7.0, Basis(Vector3.UP, PI * 0.5), 0.7, "Wall")
	lm.frustum("Wall", Vector3(27.6, 0, 0), 10.0, 10.0, 14.0, 16, 0.0, 0.8, 1.0)
	lm.frustum("White", Vector3(27.6, 14.0, 0), 10.5, 10.5, 0.8, 16, 0.0, 0.8, 1.0)
	lm.lathe("Roof", Vector3(27.6, 14.8, 0), PackedVector2Array([Vector2(10.4, 0), Vector2(6.0, 4.0),
		Vector2(0.0, 8.0)]), 16, 0.8, 1.0, 0.0, false)
	for sz in [-1.0, 1.0]:
		var o := Vector3(0, 0, sz * 14.62)
		var out := Vector3(0, 0, sz)
		LandmarkRbParts.windows(lm, "Windows", o, Vector3.RIGHT, out, 2.8, 9, 5.8, 2.0, 5.5)
		LandmarkRbParts.windows(lm, "Windows", o, Vector3.RIGHT, out, 10.2, 9, 5.8, 2.0, 5.5)
		for i in 10:
			lm.box("White", Vector3((float(i) - 4.5) * 5.8, 8.5, sz * 14.7), Vector3(0.9, 15.0, 0.5))
	LandmarkRbParts.windows(lm, "Windows", Vector3(27.65, 0, 0), Vector3(0, 0, 1), Vector3(1, 0, 0), 3.0, 1, 4.0, 2.0, 7.0)
	# Crossing cupola with a gilded dome and a needle spire.
	var cu := Vector3(6.0, 24.7, 0)
	lm.frustum("Wall", cu, 3.4, 3.4, 4.0, 12)
	lm.frustum("White", cu + Vector3(0, 4.0, 0), 3.8, 3.8, 0.5, 12)
	lm.lathe("Gilt", cu + Vector3(0, 4.5, 0), LandmarkRbParts.dome_profile(3.6, 3.2, 6), 12)
	lm.spire("Gilt", cu + Vector3(0, 7.7, 0), 0.5, 7.0, 0.0, 8)
	_pp_tower(lm)
	lm.commit(model)

## The bell tower in the west front: three square stages, the octagonal
## belfry, the gilded spire, ball, angel and cross (122.5 m).
static func _pp_tower(lm: LandmarkMesh) -> void:
	var cx := -19.5
	lm.box("Wall", Vector3(cx, 12.0, 0), Vector3(17.0, 24.0, 18.0))
	lm.box("White", Vector3(cx, 24.4, 0), Vector3(18.0, 0.9, 19.0))
	# West portal and windows of the lowest stage.
	lm.box("White", Vector3(-29.6, 7.0, 0), Vector3(4.0, 14.0, 9.0))
	SEuUtil.opening(lm, "Windows", Vector3(-31.65, 0.0, 0), Vector3(0, 0, -1), Vector3.UP, 3.6, 9.0)
	for sz in [-1.0, 1.0]:
		SEuUtil.opening(lm, "Windows", Vector3(cx, 3.0, sz * 9.05), Vector3.RIGHT, Vector3.UP, 2.4, 7.0)
		lm.box("White", Vector3(cx, 12.0, sz * 9.1), Vector3(1.0, 21.0, 0.4))
	# Second stage with the clock faces, volutes at its corners.
	lm.box("Wall", Vector3(cx, 31.5, 0), Vector3(12.0, 14.0, 12.0))
	lm.box("White", Vector3(cx, 38.8, 0), Vector3(13.0, 0.8, 13.0))
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			lm.spire("White", Vector3(cx + sx * 6.4, 24.8, sz * 6.8), 1.6, 6.0, 0.4)
	lm.disc("White", Vector3(cx - 6.05, 32.0, 0), Vector3(-1, 0, 0), 2.6, 24)
	lm.disc("White", Vector3(cx, 32.0, 6.05), Vector3(0, 0, 1), 2.6, 24)
	lm.disc("White", Vector3(cx, 32.0, -6.05), Vector3(0, 0, -1), 2.6, 24)
	# Belfry stage with arched openings, then the octagonal drum.
	lm.box("Wall", Vector3(cx, 46.0, 0), Vector3(9.4, 14.0, 9.4))
	for k in 4:
		var out := Vector3(cos(PI * 0.5 * k), 0, sin(PI * 0.5 * k))
		var right := Vector3.UP.cross(out)
		for sgn in [-1.0, 1.0]:
			SEuUtil.opening(lm, "Windows", Vector3(cx, 41.0, 0) + out * 4.75 + right * sgn * 2.0, right, Vector3.UP, 1.8, 7.5)
	lm.box("White", Vector3(cx, 53.4, 0), Vector3(10.6, 0.8, 10.6))
	lm.frustum("Wall", Vector3(cx, 53.8, 0), 4.6, 4.2, 6.0, 8, PI / 8.0)
	lm.frustum("White", Vector3(cx, 59.8, 0), 4.8, 4.8, 0.7, 8, PI / 8.0)
	var s0 := Vector3(cx, 60.5, 0)
	lm.lathe("Gilt", s0, PackedVector2Array([Vector2(3.6, 0), Vector2(3.0, 6.0), Vector2(2.3, 16.0),
		Vector2(1.6, 28.0), Vector2(1.0, 38.0), Vector2(0.55, 46.0), Vector2(0.4, 51.0)]), 8,
		1.0, 1.0, PI / 8.0, false)
	var ball := s0 + Vector3(0, 50.6, 0)
	var sphere := PackedVector2Array()
	for i in 9:
		var a := PI * float(i) / 8.0
		sphere.append(Vector2(1.3 * sin(a), 1.3 - 1.3 * cos(a)))
	lm.lathe("Gilt", ball, sphere, 12)
	LandmarkKits.statue_figure(lm, "Gilt", ball + Vector3(0, 2.6, 0), 4.0)
	LandmarkRbParts.cross(lm, "Gilt", ball + Vector3(0.4, 4.4, 0), PP_TOP - (ball.y + 4.4))

# --- Church of the Saviour on Spilled Blood ---

const SOB_TOP := 81.0
const SOB_CX := 1.0

## Origin at the footprint centre; the apse faces +X (the real axis runs
## 102° clockwise from north), the bell tower the opposite way (-X).
static func savior_on_blood(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#A9503E", 4.0))
	lm.use("White", LandmarkMaterials.pbr("render", "#EFE9DA", 3.0))
	lm.use("Plinth", LandmarkMaterials.pbr("stone", "#7E7468", 3.0))
	lm.use("Tent", LandmarkMaterials.pbr("terracotta", "#2E8E86", 2.5, 0.45, 0.2))
	lm.use("Blue", LandmarkMaterials.pbr("concrete", "#2F5FA8", 2.0, 0.4, 0.3))
	lm.use("Green", LandmarkMaterials.pbr("concrete", "#2F9460", 2.0, 0.4, 0.3))
	lm.use("Red", LandmarkMaterials.pbr("terracotta", "#B8352B", 2.0, 0.4, 0.2))
	lm.use("Windows", LandmarkMaterials.glass("#26323A"))
	lm.use("Gilt", LandmarkMaterials.gold())
	# Greek-cross block, west bell tower with its two porch wings, apse.
	lm.box("Plinth", Vector3(SOB_CX, 1.0, 0), Vector3(37.0, 2.0, 30.0))
	lm.box("Brick", Vector3(SOB_CX, 11.0, 0), Vector3(36.0, 20.0, 29.0))
	lm.box("White", Vector3(SOB_CX, 21.0, 0), Vector3(36.8, 0.9, 29.8))
	lm.frustum("Brick", Vector3(19.0, 0, 0), 10.0, 10.0, 18.0, 16)
	lm.frustum("White", Vector3(19.0, 18.0, 0), 10.5, 10.5, 0.8, 16)
	for sz in [-1.0, 1.0]:
		var o := Vector3(SOB_CX, 0, sz * 14.55)
		LandmarkRbParts.windows(lm, "Windows", o, Vector3.RIGHT, Vector3(0, 0, sz), 3.5, 6, 5.4, 2.2, 6.0)
		LandmarkRbParts.windows(lm, "Windows", o, Vector3.RIGHT, Vector3(0, 0, sz), 12.0, 6, 5.4, 2.2, 6.0)
		# Cross-gable ("zakomara") of the north and south arms.
		lm.gable("White", Vector3(SOB_CX, 21.0, sz * 10.5), 8.0, 8.0, 6.5, Basis(), 0.3, "Brick")
		lm.box("Brick", Vector3(-21.0, 9.0, sz * 14.2), Vector3(8.4, 18.0, 10.8))
		lm.box("White", Vector3(-21.0, 18.3, sz * 14.2), Vector3(9.0, 0.7, 11.4))
		LandmarkRbParts.onion_on_drum(lm, "White", "Gilt", "Gilt", Vector3(-21.0, 18.6, sz * 14.2), 2.2, 3.5, 4.5, 2.0, 12)
	LandmarkRbParts.onion_on_drum(lm, "White", "Gilt", "Gilt", Vector3(19.0, 18.8, 0), 3.8, 4.0, 6.0, 2.5, 12)
	# Four coloured onion domes on tall octagonal drums at the cross corners.
	var domes := ["Blue", "Green", "Red", "Gilt"]
	for k in 4:
		var c := Vector3(SOB_CX + (9.8 if k % 2 == 0 else -9.8), 21.5, (9.8 if k < 2 else -9.8))
		lm.frustum("Brick", c, 4.6, 4.2, 12.0, 8, PI / 8.0)
		lm.frustum("White", c + Vector3(0, 12.0, 0), 4.6, 4.6, 0.8, 8, PI / 8.0)
		lm.frustum("Windows", c + Vector3(0, 5.0, 0), 4.55, 4.5, 3.5, 8, PI / 8.0)
		lm.frustum("White", c + Vector3(0, 12.8, 0), 2.9, 2.9, 2.5, 12)
		LandmarkCeParts.onion(lm, domes[k], c + Vector3(0, 15.3, 0), 4.7, 8.5, 16)
		LandmarkRbParts.cross(lm, "Gilt", c + Vector3(0, 23.8, 0), 3.2)
	_sob_centre(lm)
	_sob_bell_tower(lm)
	lm.commit(model)

## The central tower: octagonal brick drum, kokoshnik crown, tall
## patterned tent, gilded onion and cross (81 m).
static func _sob_centre(lm: LandmarkMesh) -> void:
	var c := Vector3(SOB_CX, 21.0, 0)
	lm.frustum("Brick", c, 8.4, 8.0, 22.0, 8, PI / 8.0)
	lm.frustum("Windows", c + Vector3(0, 8.0, 0), 8.2, 8.0, 7.0, 8, PI / 8.0)
	for k in 8:
		var a := PI / 8.0 + TAU * float(k) / 8.0
		lm.box("White", c + Vector3(cos(a) * 8.1, 11.0, sin(a) * 8.1), Vector3(0.9, 22.0, 0.9), Basis(Vector3.UP, -a))
	lm.frustum("White", c + Vector3(0, 22.0, 0), 8.8, 8.8, 1.2, 8, PI / 8.0)
	lm.frustum("White", c + Vector3(0, 23.2, 0), 8.4, 8.4, 0.6, 8, PI / 8.0)
	var tent := c + Vector3(0, 23.8, 0)
	lm.lathe("Tent", tent, PackedVector2Array([Vector2(8.3, 0), Vector2(6.8, 7.0), Vector2(4.8, 14.0),
		Vector2(3.2, 20.0), Vector2(2.4, 23.5)]), 8, 1.0, 1.0, PI / 8.0, false)
	for k in 8:
		var a := PI / 8.0 + TAU * float(k) / 8.0
		lm.beam("White", tent + Vector3(cos(a) * 8.7, 0.1, sin(a) * 8.7), tent + Vector3(cos(a) * 2.5, 23.4, sin(a) * 2.5), 0.45, 0.35)
	lm.frustum("White", tent + Vector3(0, 23.4, 0), 2.4, 2.1, 2.2, 8)
	LandmarkCeParts.onion(lm, "Gilt", tent + Vector3(0, 25.6, 0), 3.1, 7.4, 16)
	LandmarkRbParts.cross(lm, "Gilt", tent + Vector3(0, 33.0, 0), SOB_TOP - (tent.y + 33.0))

## West bell tower: brick shaft, white band, octagon, tent, onion (63 m).
static func _sob_bell_tower(lm: LandmarkMesh) -> void:
	var c := Vector3(-23.0, 0, 0)
	lm.box("Brick", c + Vector3(0, 16.5, 0), Vector3(12.0, 33.0, 17.0))
	lm.box("White", c + Vector3(0, 33.5, 0), Vector3(12.8, 1.0, 17.8))
	SEuUtil.opening(lm, "Windows", c + Vector3(-6.05, 1.0, 0), Vector3(0, 0, -1), Vector3.UP, 4.0, 10.0)
	for sz in [-1.0, 1.0]:
		SEuUtil.opening(lm, "Windows", c + Vector3(0, 22.0, sz * 8.55), Vector3.RIGHT, Vector3.UP, 3.0, 7.0)
	lm.frustum("Brick", c + Vector3(0, 34.0, 0), 6.0, 5.6, 8.0, 8, PI / 8.0)
	lm.frustum("Windows", c + Vector3(0, 36.5, 0), 5.9, 5.65, 3.0, 8, PI / 8.0)
	lm.frustum("White", c + Vector3(0, 42.0, 0), 6.4, 6.4, 1.0, 8, PI / 8.0)
	var tent := c + Vector3(0, 43.0, 0)
	lm.lathe("Tent", tent, PackedVector2Array([Vector2(6.3, 0), Vector2(4.2, 5.0), Vector2(2.3, 9.5),
		Vector2(1.5, 11.5)]), 8, 1.0, 1.0, PI / 8.0, false)
	lm.frustum("White", tent + Vector3(0, 11.4, 0), 1.5, 1.3, 1.2, 8)
	LandmarkCeParts.onion(lm, "Gilt", tent + Vector3(0, 12.6, 0), 2.3, 4.4, 14)
	LandmarkRbParts.cross(lm, "Gilt", tent + Vector3(0, 17.0, 0), 3.0)
