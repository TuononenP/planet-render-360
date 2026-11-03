extends RefCounted

## Additional Stockholm skyline landmarks in true metres. Tower and opera
## footprints follow OSM ways 27347857, 121854812/3/4/7, 37299689 and
## 16108358. Stockholm's building ordinance records Hötorgsskraporna as
## 19 floors and +72 m at a +11 m base: 61 m above ground. The other
## heights are OSM (Opera 41.5 m, Katarinahissen 42.5 m, Söder Torn 86 m),
## Kastellet's 20 m stair tower (SFV/Wikipedia) and Eclipse's 121 m
## (Gröna Lund). Hotel dimensions and decorative detail are approximate.

const Palaces = preload("res://scripts/generation/landmarks/sweden_stockholm/landmark_ss_hero_palaces.gd")
const GronaLund = preload("res://scripts/generation/landmarks/sweden_stockholm/landmark_ss_gronalund.gd")

static func _steel(lm: LandmarkMesh) -> void:
	lm.use("Steel", LandmarkMaterials.pbr("concrete", "#69727A", 2.0, 0.55, 0.45))
	lm.use("Glass", LandmarkMaterials.glass("#24303A"))
	lm.use("Accent", LandmarkMaterials.pbr("concrete", "#DBD0B9", 2.0))

static func hotorg(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	_steel(lm)
	LandmarkFhUtil.blk(lm, "Glass", 0, 0, 0, 39.0, 61.0, 14.0)
	# Closely spaced pale horizontal floor strips and vertical mullions.
	for row in 20:
		var y := float(row) * 3.05 + 0.15
		LandmarkFhParts.box_band(lm, "Accent", 0, 0, 39.0, 14.0, y, 0.22, 0.18)
	for side in [-1.0, 1.0]:
		for i in 16:
			var x := -18.3 + float(i) * 2.44
			lm.box("Steel", Vector3(x, 30.5, float(side) * 7.08), Vector3(0.11, 60.6, 0.12))
	lm.commit(model)

static func soder_torn(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	_steel(lm)
	lm.use("Wall", LandmarkMaterials.pbr("render", "#D7C9AF", 3.0))
	# Eight-sided 24-storey residential shaft and characteristic crown.
	lm.frustum("Wall", Vector3.ZERO, 13.0, 13.0, 74.0, 8, PI / 8.0)
	for k in 8:
		var a := TAU * float(k) / 8.0
		var d := Vector3(cos(a), 0, sin(a))
		var tangent := Vector3(d.z, 0, -d.x)
		var basis := Basis(tangent, Vector3.UP, d)
		for row in 24:
			var y := 2.0 + float(row) * 3.0
			for shift in [-2.4, 0.0, 2.4]:
				lm.box("Glass", d * 12.04 + tangent * float(shift) + Vector3.UP * y,
					Vector3(1.6, 1.8, 0.08), basis, 0.0)
	lm.frustum("Steel", Vector3(0, 74, 0), 13.1, 11.0, 1.0, 8, PI / 8.0)
	for k in 8:
		var a := TAU * (float(k) + 0.5) / 8.0
		var d := Vector3(cos(a), 0, sin(a))
		lm.beam("Steel", d * 10.5 + Vector3.UP * 75.0, d * 6.0 + Vector3.UP * 84.5, 0.55, 0.55)
	lm.frustum("Steel", Vector3(0, 84.5, 0), 6.0, 4.5, 1.5, 8, PI / 8.0)
	lm.commit(model)

static func katarinahissen(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	_steel(lm)
	# Exposed steel elevator and the elevated pedestrian/restaurant bridge.
	for x in [-2.5, 2.5]:
		for z in [-2.5, 2.5]:
			lm.beam("Steel", Vector3(float(x), 0, float(z)), Vector3(float(x), 42.0, float(z)), 0.55, 0.55)
	for y in range(0, 42, 6):
		var y0 := maxf(float(y), 0.3)
		for z in [-2.5, 2.5]:
			lm.beam("Steel", Vector3(-2.5, y0, float(z)), Vector3(2.5, y0 + 6.0, float(z)), 0.3, 0.3)
			lm.beam("Steel", Vector3(2.5, y0, float(z)), Vector3(-2.5, y0 + 6.0, float(z)), 0.3, 0.3)
	lm.box("Glass", Vector3(0, 19, 0), Vector3(3.4, 31, 3.4))
	lm.box("Steel", Vector3(0, 42.25, 0), Vector3(7.0, 0.5, 7.0))
	lm.box("Steel", Vector3(21, 35, 0), Vector3(42, 1.2, 5.0))
	lm.box("Glass", Vector3(21, 37.2, 0), Vector3(39, 3.2, 4.2))
	lm.box("Steel", Vector3(21, 39, 0), Vector3(40, 0.4, 5.0))
	lm.commit(model)

static func eclipse(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	_steel(lm)
	lm.use("Gilt", LandmarkMaterials.gold())
	# Eclipse, Gröna Lund's 121 m swing tower; nearby rides remain OSM.
	lm.frustum("Steel", Vector3.ZERO, 3.0, 1.6, 116.0, 12)
	lm.frustum("Accent", Vector3(0, 107, 0), 6.5, 6.5, 2.0, 16)
	for k in 12:
		var a := TAU * float(k) / 12.0
		var d := Vector3(cos(a), 0, sin(a))
		lm.beam("Steel", d * 5.0 + Vector3.UP * 107.0, d * 7.0 + Vector3.UP * 100.0, 0.12, 0.12)
	lm.frustum("Gilt", Vector3(0, 116, 0), 2.0, 0.0, 5.0, 12)
	GronaLund.add(lm)
	lm.commit(model)

static func kastellet(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#9E4C3E", 2.5))
	lm.use("Trim", LandmarkMaterials.pbr("stone", "#AA9687", 2.5))
	lm.use("Glass", LandmarkMaterials.glass("#25292B"))
	lm.frustum("Brick", Vector3.ZERO, 9.0, 9.0, 12.5, 24)
	lm.box("Brick", Vector3(8, 9.0, 0), Vector3(6, 18, 6))
	lm.frustum("Trim", Vector3(8, 18, 0), 3.8, 3.8, 0.7, 4, PI / 4.0)
	for k in 4:
		var a := TAU * float(k) / 4.0 + PI / 4.0
		lm.box("Brick", Vector3(8 + cos(a) * 3.0, 19.35, sin(a) * 3.0), Vector3(1.1, 1.3, 1.1))
	for k in 16:
		var a := TAU * float(k) / 16.0
		var d := Vector3(cos(a), 0, sin(a))
		lm.box("Brick", d * 8.6 + Vector3.UP * 13.1, Vector3(1.3, 1.2, 1.3))
		if k % 2 == 0:
			LandmarkDetail.window(lm, "Trim", "Glass", d * 9.03 + Vector3.UP * 7.0, d, 1.2, 3.2, true, 0.15)
	lm.commit(model)

static func opera(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	Palaces._materials(lm, "#CFC0A6")
	Palaces._block(lm, Vector2.ZERO, 115.0, 64.0, 26.0, 3)
	LandmarkFhUtil.hip(lm, "Copper", Vector3(0, 26, 0), 115.5, 64.5, 4.5, 0.55)
	# The fly tower rises behind the richly articulated opera frontage.
	Palaces._block(lm, Vector2(13, -3), 35.0, 28.0, 36.0, 2)
	LandmarkFhUtil.hip(lm, "Copper", Vector3(13, 36, -3), 35.5, 28.5, 5.5, 0.45)
	for x in [-9.0, -4.5, 0.0, 4.5, 9.0]:
		LandmarkDetail.column(lm, "Stone", Vector3(float(x), 8.0, 33.0), 0.6, 13.0, "corinthian", 0, 10)
	lm.box("Stone", Vector3(0, 22.0, 33.0), Vector3(24, 1.4, 2.0))
	lm.commit(model)

static func grand_hotel(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	Palaces._materials(lm, "#D8CBB5")
	Palaces._block(lm, Vector2.ZERO, 78.0, 26.0, 24.0, 4)
	LandmarkFhUtil.hip(lm, "Copper", Vector3(0, 24, 0), 78.5, 26.5, 6.0, 0.55)
	for x in [-25.0, -15.0, -5.0, 5.0, 15.0, 25.0]:
		lm.box("Stone", Vector3(float(x), 25.7, 12.0), Vector3(3.0, 3.2, 2.0))
		lm.box("Glass", Vector3(float(x), 25.7, 13.05), Vector3(1.6, 2.0, 0.05))
		lm.gable("Copper", Vector3(float(x), 27.3, 12.0), 3.3, 2.2, 1.5, Basis(), 0.1, "Stone")
	lm.commit(model)
