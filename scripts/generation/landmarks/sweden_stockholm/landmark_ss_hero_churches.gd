extends RefCounted

## Klara and Sofia churches. OSM ways 163637452 and 1350868500 provide
## footprint axes and their tagged 116 m and 78 m heights. Klara's brick
## cruciform nave, west tower and copper spire are described by the Church
## of Sweden's "S:ta Clara kyrkas historia"; its restored tower dates
## from the 1880s. The Church of Sweden's "Sofia kyrka" building record
## describes the equal cross arms, octagonal tower and copper roofs.
## Details and eave heights are approximations.

static func _materials(lm: LandmarkMesh) -> void:
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#8D5544", 3.0))
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#B1A79B", 3.0))
	lm.use("Copper", LandmarkMaterials.pbr("concrete", "#5F806F", 2.0, 0.6, 0.3))
	lm.use("Glass", LandmarkMaterials.glass("#20282D"))
	lm.use("Gilt", LandmarkMaterials.gold())

static func _nave(lm: LandmarkMesh, centre: Vector2, w: float, d: float, h: float) -> void:
	LandmarkFhUtil.blk(lm, "Brick", centre.x, 0.0, centre.y, w, h, d)
	LandmarkFhParts.box_band(lm, "Stone", centre.x, centre.y, w, d, 1.0, 1.3, 0.3)
	for face in LandmarkFhParts.faces(centre.x, centre.y, w, d):
		var a: Vector3 = face[0]
		var b: Vector3 = face[1]
		var out: Vector3 = face[2]
		var n := maxi(1, int(a.distance_to(b) / 7.0))
		for i in n:
			var p := a.lerp(b, (float(i) + 0.5) / float(n)) + out * 0.03
			LandmarkFhParts.lancet(lm, "Stone", "Glass", p + Vector3.UP * 5.0, out, 2.0, 8.0)

static func klara(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	_materials(lm)
	_nave(lm, Vector2(7, 0), 48.0, 18.0, 21.0)
	_nave(lm, Vector2(7, 0), 13.0, 32.0, 20.0)
	LandmarkFhUtil.ridge_x(lm, "Copper", "Brick", Vector3(7, 21, 0), 48.0, 18.0, 8.0)
	LandmarkFhUtil.ridge_z(lm, "Copper", "Brick", Vector3(7, 20, 0), 13.0, 32.0, 7.0)
	var t := Vector3(-20, 0, 0)
	lm.box("Brick", t + Vector3(0, 24, 0), Vector3(13, 48, 13))
	for side in [Vector3.FORWARD, Vector3.BACK, Vector3.LEFT, Vector3.RIGHT]:
		LandmarkFhParts.lancet(lm, "Stone", "Glass", t + side * 6.55 + Vector3.UP * 30.0, side, 2.3, 9.0)
	for x in [-5.8, 5.8]:
		for z in [-5.8, 5.8]:
			var p := t + Vector3(float(x), 0, float(z))
			lm.box("Stone", p + Vector3.UP * 24.0, Vector3(1.0, 48.0, 1.0))
			lm.frustum("Brick", p + Vector3.UP * 48.0, 1.1, 0.85, 4.0, 4, PI * 0.25)
			lm.spire("Copper", p + Vector3.UP * 52.0, 1.2, 7.0)
	lm.frustum("Stone", t + Vector3.UP * 47.5, 8.7, 8.7, 0.8, 8, PI / 8.0)
	lm.frustum("Copper", t + Vector3.UP * 48.3, 8.0, 4.3, 12.0, 8, PI / 8.0)
	lm.frustum("Copper", t + Vector3.UP * 60.3, 4.3, 4.3, 9.0, 8, PI / 8.0)
	lm.spire("Copper", t + Vector3.UP * 69.3, 4.7, 44.7)
	lm.frustum("Gilt", t + Vector3.UP * 114.0, 0.18, 0.03, 2.0, 6)
	lm.commit(model)

static func sofia(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	_materials(lm)
	_nave(lm, Vector2.ZERO, 47.0, 16.0, 17.0)
	_nave(lm, Vector2.ZERO, 16.0, 36.0, 17.0)
	LandmarkFhUtil.ridge_x(lm, "Copper", "Brick", Vector3(0, 17, 0), 47.0, 16.0, 7.0)
	LandmarkFhUtil.ridge_z(lm, "Copper", "Brick", Vector3(0, 17, 0), 16.0, 36.0, 7.0)
	lm.frustum("Brick", Vector3(0, 17, 0), 8.5, 8.5, 25.0, 8, PI / 8.0)
	for k in 8:
		var a := TAU * float(k) / 8.0
		var d := Vector3(cos(a), 0, sin(a))
		LandmarkDetail.window(lm, "Stone", "Glass", d * 7.92 + Vector3.UP * 35.5, d, 1.7, 6.0, true, 0.2)
		var p := d * 8.0 + Vector3.UP * 41.5
		lm.frustum("Brick", p, 1.0, 0.8, 3.0, 6)
		lm.spire("Copper", p + Vector3.UP * 3.0, 1.0, 5.0)
	lm.frustum("Stone", Vector3(0, 41.5, 0), 8.9, 8.9, 0.8, 8, PI / 8.0)
	lm.frustum("Copper", Vector3(0, 42.3, 0), 8.5, 4.2, 12.0, 8, PI / 8.0)
	lm.spire("Copper", Vector3(0, 54.3, 0), 4.3, 21.7)
	lm.frustum("Gilt", Vector3(0, 76.0, 0), 0.15, 0.03, 2.0, 6)
	lm.commit(model)
