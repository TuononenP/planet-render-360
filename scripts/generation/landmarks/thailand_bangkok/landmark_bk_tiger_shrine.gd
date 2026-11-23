class_name LandmarkBkTigerShrine
extends RefCounted

## San Chao Pho Suea — Tiger God Shrine (`ศาลเจ้าพ่อเสือ`) — Thanon Tanao, Bangkok BK-5.5
## Site: OSM way 1481450245, centroid 13.753804, 100.498306
## (`height_m: 11.0`, `radius_m: 300.0`, `yaw_deg: 6.0` — local walk landmark).
## Spec (1834 Teochew Chinese temple on Thanon Tanao, Commons `front.jpg`):
##   - Vermilion-red & gold Southern Chinese temple hall (`18 × 24 m`) with sweeping curved
##     emerald-green & gold glazed tile roof (`9.6 m`) crowned by twin ceramic dragons flanking
##     a golden pearl (`10.4 m`).
##   - Forecourt incense canopy (`+Z`) draped with green-and-red bunting and rows of glowing
##     vermilion Chinese lanterns (`LanternLamp`), bronze incense cauldron, and a `11.0 m`
##     dragon-wrapped crimson pillar (`front.jpg`).

const HEIGHT_M := 11.0

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Red", LandmarkMaterials.pbr("render", "#A8241E", 2.5))
	lm.use("Cream", LandmarkMaterials.pbr("render", "#EAE0CA", 3.0))
	lm.use("GreenTile", LandmarkMaterials.pbr("slate", "#2A6B4C", 2.2))
	lm.use("Canopy", LandmarkMaterials.pbr("concrete", "#244D39", 3.0))
	lm.use("Gold", LandmarkMaterials.gold())
	lm.use("LanternLamp", LandmarkMaterials.lit("#FF3B1F", 2.4))
	lm.use("Dark", LandmarkMaterials.paint("#221916", 0.9, 0.0))

	_shrine_hall(lm)
	_forecourt_canopy_and_dragon_pillar(lm)
	lm.commit(model)

static func _shrine_hall(lm: LandmarkMesh) -> void:
	lm.box("Cream", Vector3(0, 0.25, -2.0), Vector3(20.0, 0.5, 26.0))
	lm.box("Red", Vector3(0, 3.3, -3.5), Vector3(17.2, 5.6, 18.0))
	for sx in [-6.2, -2.2, 2.2, 6.2]:
		lm.frustum("Red", Vector3(sx, 0.5, 5.8), 0.32, 0.28, 5.4, 10)
		lm.box("Gold", Vector3(sx, 5.6, 5.8), Vector3(0.75, 0.5, 0.75))
	lm.box("Dark", Vector3(0, 2.4, 5.55), Vector3(3.2, 3.8, 0.14), Basis(), 0.0)
	lm.box("Gold", Vector3(0, 4.7, 5.65), Vector3(3.8, 0.85, 0.18))

	# Sweeping Southern Chinese green-glazed gable roof + golden ridge & twin ceramic dragons
	LandmarkFhUtil.ridge_x(lm, "GreenTile", "Cream", Vector3(0, 6.1, -3.5), 19.0, 19.6, 3.3)
	lm.box("Gold", Vector3(0, 9.55, -3.5), Vector3(19.4, 0.42, 0.45))
	# Upturned swallowtail ridge horns (`yanwei`) + central flaming pearl + twin dragons
	for sx in [-1.0, 1.0]:
		var s := float(sx)
		lm.beam("Gold", Vector3(s * 8.6, 9.6, -3.5), Vector3(s * 10.1, 10.55, -3.5), 0.28, 0.45)
		lm.box("Red", Vector3(s * 3.4, 9.95, -3.5), Vector3(2.4, 0.65, 0.42))
	lm.lathe("Gold", Vector3(0, 9.75, -3.5), PackedVector2Array([
		Vector2(0.25, 0.0), Vector2(0.45, 0.35), Vector2(0.0, 0.85)]), 8)

static func _forecourt_canopy_and_dragon_pillar(lm: LandmarkMesh) -> void:
	# Covered worship court (`z = +5.5..+11.5 m`) with red festooned trim & glowing lantern row (`front.jpg`)
	lm.gable("Canopy", Vector3(0, 4.5, 8.5), 6.4, 17.6, 1.2, Basis(Vector3.UP, PI * 0.5), 0.2, "Red")
	lm.box("Red", Vector3(0, 4.25, 11.65), Vector3(17.6, 0.55, 0.16))
	for i in 12:
		var lx := -7.8 + 15.6 * float(i) / 11.0
		lm.lathe("LanternLamp", Vector3(lx, 4.35, 11.95), PackedVector2Array([
			Vector2(0.08, 0.0), Vector2(0.26, 0.18), Vector2(0.26, 0.34), Vector2(0.08, 0.48)]), 8)

	# Crimson dragon-wrapped celestial lantern pillar rising to `HEIGHT_M = 11.0 m` (`front.jpg`)
	var pc := Vector3(5.2, 0.5, 10.2)
	lm.frustum("Red", pc, 0.42, 0.32, 9.6, 10)
	for k in 8:
		var a0 := float(k) * 0.9
		var a1 := float(k + 1) * 0.9
		var y0 := 1.4 + float(k) * 0.92
		lm.beam("Gold", pc + Vector3(cos(a0) * 0.44, y0, sin(a0) * 0.44),
			pc + Vector3(cos(a1) * 0.42, y0 + 0.92, sin(a1) * 0.42), 0.18, 0.18)
	lm.lathe("Gold", pc + Vector3(0, 9.6, 0), PackedVector2Array([
		Vector2(0.32, 0.0), Vector2(0.48, 0.45), Vector2(0.0, 0.9)]), 8)
