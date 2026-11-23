class_name LandmarkLnPortcullisHouse
extends RefCounted

## Portcullis House, Westminster (Hopkins Architects, 2001; OSM way 256497249, 362 m
## from preset eye, directly opposite Big Ben). Portland-stone ground arcade, dark
## patinated bronze bay-window facades, steeply pitched pleated bronze roof, and its
## unmistakable row of 14 tall dark-bronze ventilation chimneys rising to 32.0 m.

const W := 72.0
const D := 54.0
const EAVES_H := 20.5
const ROOF_TOP := 27.5
const TOP_H := 32.0

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkLnKit.portland("#DDD6C6", 3.2))
	lm.use("Bronze", LandmarkMaterials.paint("#2E2B27", 0.48, 0.65))
	lm.use("Glass", LandmarkMaterials.glass("#263038"))
	lm.use("Lamp", LandmarkMaterials.lit("#FFE2B0", 1.1))
	# Ground-floor Portland-stone colonnade arcade
	lm.box("Stone", Vector3(0.0, 2.8, 0.0), Vector3(W - 2.0, 5.6, D - 2.0))
	for i in 11:
		var x := lerpf(-W * 0.47, W * 0.47, float(i) / 10.0)
		for sz in [-1.0, 1.0]:
			lm.box("Stone", Vector3(x, 3.0, float(sz) * (D * 0.5 - 0.5)), Vector3(1.5, 6.0, 1.5))
	# Upper bronze-framed facade bays with recessed stone piers
	lm.box("Stone", Vector3(0.0, (5.6 + EAVES_H) * 0.5, 0.0), Vector3(W - 0.8, EAVES_H - 5.6, D - 0.8))
	for i in 11:
		var x := lerpf(-W * 0.46, W * 0.46, float(i) / 10.0)
		for sz in [-1.0, 1.0]:
			lm.box("Stone", Vector3(x, (5.6 + EAVES_H) * 0.5, float(sz) * (D * 0.5 + 0.2)), Vector3(1.2, EAVES_H - 5.6, 1.0))
			if i < 10:
				var bx := x + (W * 0.92 / 10.0) * 0.5
				for row in 3:
					var wy := 8.2 + float(row) * 4.2
					lm.box("Bronze", Vector3(bx, wy, float(sz) * (D * 0.5 + 0.25)), Vector3(5.2, 3.5, 0.55))
					lm.box("Glass", Vector3(bx, wy, float(sz) * (D * 0.5 + 0.54)), Vector3(4.5, 2.8, 0.12))
	# Steep pleated bronze mansard roof
	LandmarkLnKit.mansard_roof(lm, "Bronze", "Bronze", "Glass", Vector3(0.0, EAVES_H, 0.0), W, D, ROOF_TOP - EAVES_H, 8)
	# Signature 14 tall bronze ventilation chimneys around the roof perimeter (top 32.0 m)
	for sz in [-1.0, 1.0]:
		for i in 7:
			var cx := lerpf(-W * 0.39, W * 0.39, float(i) / 6.0)
			var cz := float(sz) * (D * 0.36)
			lm.box("Bronze", Vector3(cx, (ROOF_TOP + TOP_H) * 0.5 - 0.8, cz), Vector3(2.2, TOP_H - ROOF_TOP + 1.6, 2.2))
			lm.box("Bronze", Vector3(cx, TOP_H - 0.4, cz), Vector3(2.8, 0.8, 2.8))
	lm.commit(model)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(0.0, 2.0, D * 0.5 + 10.0), Vector3(0.0, 18.0, D * 0.5), 60.0, 0.8, 48.0],
	])
