extends RefCounted

## Tyska kyrkan (Sankta Gertrud) in Gamla stan. The brick tower and
## copper-clad spire are 96 m high; the two-aisled church dates from
## the 1638–1642 enlargement. The church and its tower share one model
## so the replacement stands on the real site rather than the nearby
## generic OSM extrusion. Sources: Stockholms läns museum, "Tyska
## kyrkan", and Wikipedia, "German Church, Stockholm".
## Footprint axis follows OSM way 8049509 (nave runs northeast); nave
## dimensions and the roof profile are approximate.

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("render", "#D5C9B5", 3.0))
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#8E4C3B", 2.5))
	lm.use("Trim", LandmarkMaterials.pbr("stone", "#B2A797", 2.5))
	lm.use("Copper", LandmarkMaterials.pbr("concrete", "#5B806F", 2.0, 0.6, 0.3))
	lm.use("Glass", LandmarkMaterials.glass("#242B2D"))
	lm.use("Gilt", LandmarkMaterials.gold())
	# Nave, its copper pitched roof, and its tall round-headed windows.
	lm.box("Wall", Vector3(3.0, 10.5, 0), Vector3(37.0, 21.0, 25.0))
	lm.gable("Copper", Vector3(3.0, 21.0, 0), 25.0, 37.0, 8.0, Basis(Vector3.UP, PI * 0.5), 0.3, "Wall")
	for side in [-1.0, 1.0]:
		var out := Vector3(0, 0, float(side))
		for x in [-11.0, -4.0, 3.0, 10.0, 17.0]:
			var at := Vector3(float(x), 10.0, float(side) * 12.54)
			LandmarkDetail.window(lm, "Trim", "Glass", at, out, 2.5, 8.0, true, 0.25)
			lm.box("Trim", Vector3(float(x) - 3.0, 10.5, float(side) * 12.75), Vector3(0.6, 20.0, 0.5))
	# West tower: square brick shaft, corner buttresses, belfry openings,
	# clock faces and the four little corner pinnacles of its spire base.
	var t := Vector3(-18.0, 0, 0)
	lm.box("Brick", t + Vector3(0, 22.0, 0), Vector3(12.0, 44.0, 12.0))
	for x in [-5.5, 5.5]:
		for z in [-5.5, 5.5]:
			lm.box("Brick", t + Vector3(float(x), 19.0, float(z)), Vector3(1.2, 38.0, 1.2))
	for side in [Vector3.FORWARD, Vector3.BACK, Vector3.LEFT, Vector3.RIGHT]:
		LandmarkDetail.window(lm, "Trim", "Glass", t + side * 6.05 + Vector3.UP * 35.5, side, 2.4, 6.0, true, 0.25)
		lm.box("Trim", t + side * 6.14 + Vector3.UP * 27.0, Vector3(3.4, 3.4, 0.15),
			Basis(Vector3.UP, atan2(side.x, side.z)))
	for x in [-5.4, 5.4]:
		for z in [-5.4, 5.4]:
			var p := t + Vector3(float(x), 44.0, float(z))
			lm.frustum("Brick", p, 1.0, 0.8, 3.0, 4, PI * 0.25)
			lm.spire("Copper", p + Vector3.UP * 3.0, 1.0, 5.0)
	# Octagonal copper helm, the open-looking narrow lantern and needle.
	lm.frustum("Trim", t + Vector3.UP * 43.5, 8.2, 8.2, 0.8, 8, PI / 8.0)
	lm.lathe("Copper", t + Vector3.UP * 44.3, PackedVector2Array([
		Vector2(7.4, 0), Vector2(6.3, 4), Vector2(4.0, 11),
		Vector2(2.7, 17), Vector2(2.5, 22)]), 8, 1.0, 1.0, PI / 8.0, false)
	lm.frustum("Copper", t + Vector3.UP * 66.3, 2.7, 2.7, 5.5, 8, PI / 8.0)
	lm.spire("Copper", t + Vector3.UP * 71.8, 3.2, 22.2)
	lm.frustum("Gilt", t + Vector3.UP * 94.0, 0.15, 0.03, 2.0, 6)
	lm.commit(model)
