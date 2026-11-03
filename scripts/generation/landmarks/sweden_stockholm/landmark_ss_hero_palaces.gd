extends RefCounted

## Stockholm waterfront buildings in true metres. Footprints and axes
## follow OSM ways 8049544 (Riddarhuset), 34590009 (Wrangel), 16095343
## (Bonde), and 24968329 (Nationalmuseum). Their mapped heights are 25.5,
## 32.5, 23.5 and 33.5 m respectively; facade detail is simplified.
## Historical forms: Swedish National Property Board (sfv.se), "Wrangelska
## palatset" and "Bondeska palatset"; Nationalmuseum, building history;
## Riddarhuset.se, "The House of Nobility".

static func _materials(lm: LandmarkMesh, wall: String) -> void:
	lm.use("Wall", LandmarkMaterials.pbr("render", wall, 3.0))
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#BEB4A1", 3.0))
	lm.use("Copper", LandmarkMaterials.pbr("concrete", "#628675", 2.0, 0.6, 0.3))
	lm.use("Glass", LandmarkMaterials.glass("#262C30"))
	lm.use("Dark", LandmarkMaterials.pbr("stone", "#63594E", 2.5))

static func _block(lm: LandmarkMesh, c: Vector2, w: float, d: float, h: float, floors: int,
		wall: String = "Wall") -> void:
	LandmarkFhUtil.blk(lm, wall, c.x, 0.0, c.y, w, h, d)
	LandmarkFhParts.box_band(lm, "Stone", c.x, c.y, w, d, 1.0, 1.5, 0.3)
	LandmarkFhParts.box_band(lm, "Stone", c.x, c.y, w, d, h - 0.5, 0.7, 0.4)
	for face in LandmarkFhParts.faces(c.x, c.y, w, d):
		var a: Vector3 = face[0]
		var b: Vector3 = face[1]
		var out: Vector3 = face[2]
		var bays := maxi(1, int(round(a.distance_to(b) / 5.0)))
		for row in floors:
			var sill := 2.4 + float(row) * (h - 4.4) / float(floors)
			LandmarkFhParts.win_row(lm, "Stone", "Glass", a, b, out, sill, bays, 1.6, 2.7,
				row == floors - 1 and floors == 2)

static func riddarhuset(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	_materials(lm, "#AC6B59")
	_block(lm, Vector2.ZERO, 57.9, 17.6, 18.0, 2)
	LandmarkFhUtil.hip(lm, "Copper", Vector3(0, 18, 0), 58.5, 18.2, 7.5, 0.48)
	# Giant pale pilasters and the two central pediments.
	for side in [-1.0, 1.0]:
		var z := float(side) * 8.95
		for x in range(-5, 6):
			lm.box("Stone", Vector3(float(x) * 5.1, 11.0, z), Vector3(0.55, 13.0, 0.35))
	# The main pediments cap the two short ends of the long hall.
	for side in [-1.0, 1.0]:
		var x := float(side) * 29.0
		lm.gable("Stone", Vector3(x, 18.0, 0), 17.6, 1.0, 3.5,
			Basis(Vector3.UP, float(side) * PI * 0.5), 0.0, "Wall")
	lm.commit(model)

static func wrangel(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	_materials(lm, "#D9C6A4")
	# Main waterfront range and two returning wings, surrounding the court.
	_block(lm, Vector2(-8, 0), 20.0, 52.0, 22.0, 4)
	_block(lm, Vector2(13, -19), 25.0, 14.0, 20.0, 4)
	_block(lm, Vector2(13, 19), 25.0, 14.0, 20.0, 4)
	LandmarkFhUtil.hip(lm, "Copper", Vector3(-8, 22, 0), 20.6, 52.6, 5.0, 0.35)
	for z in [-19.0, 19.0]:
		LandmarkFhUtil.hip(lm, "Copper", Vector3(13, 20, float(z)), 25.6, 14.6, 4.0, 0.35)
	# Circular historic waterfront tower with its low copper cap.
	lm.frustum("Wall", Vector3(-14, 0, 22), 6.0, 6.0, 27.5, 16)
	lm.frustum("Stone", Vector3(-14, 26.8, 22), 6.3, 6.3, 0.7, 16)
	LandmarkFhUtil.hip(lm, "Copper", Vector3(-14, 27.5, 22), 12.0, 12.0, 5.0, 0.0)
	lm.commit(model)

static func bonde(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	_materials(lm, "#DDD7C9")
	# H plan: the centre and four wings around its two courts.
	_block(lm, Vector2.ZERO, 34.0, 22.0, 20.0, 3)
	for x in [-12.0, 12.0]:
		_block(lm, Vector2(float(x), 0), 10.0, 70.0, 19.0, 3)
		LandmarkFhUtil.hip(lm, "Copper", Vector3(float(x), 19, 0), 10.6, 70.6, 4.0, 0.6)
	LandmarkFhUtil.hip(lm, "Copper", Vector3(0, 20, 0), 34.6, 22.6, 3.5, 0.42)
	lm.commit(model)

static func nationalmuseum(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	_materials(lm, "#C9B99D")
	# Limestone Italian Renaissance block surrounding two internal courts.
	_block(lm, Vector2(0, -31), 62.0, 17.0, 26.0, 3)
	_block(lm, Vector2(0, 31), 62.0, 17.0, 26.0, 3)
	for x in [-23.0, 0.0, 23.0]:
		_block(lm, Vector2(float(x), 0), 16.0, 46.0, 26.0, 3)
		LandmarkFhUtil.hip(lm, "Copper", Vector3(float(x), 26, 0), 16.4, 46.4, 4.5, 0.42)
	for z in [-31.0, 31.0]:
		LandmarkFhUtil.hip(lm, "Copper", Vector3(0, 26, float(z)), 62.4, 17.4, 4.5, 0.42)
	# The projecting central portal and its temple pediment.
	lm.box("Stone", Vector3(-32.0, 14.0, 0), Vector3(2.0, 28.0, 20.0))
	lm.gable("Stone", Vector3(-32.2, 28.0, 0), 21.0, 2.0, 5.5,
		Basis(Vector3.UP, -PI * 0.5), 0.0, "Stone")
	for z in [-7.0, -3.5, 3.5, 7.0]:
		LandmarkDetail.column(lm, "Stone", Vector3(-33.2, 9.0, float(z)), 0.6, 14.0, "ionic", 0, 10)
	lm.box("Glass", Vector3(-33.1, 4.5, 0), Vector3(0.1, 8.0, 4.0))
	lm.commit(model)
