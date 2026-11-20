extends RefCounted

## The Skeppsbron merchant-house row on the quay of Gamla stan: seven tall
## plastered 17th-18th century houses (OSM ways 169754205, 169754191,
## 169754186, 169754183, 169754192, 169754185, 169754187) facing east over the
## Skeppsbron quay road to Strömmen.
##
## Frame: origin on the 7-house centroid (59.324041, 18.074956), registry yaw
## -79.6 so +X runs along the row at bearing 10.4 (north-north-east) and the
## facades face +Z (bearing 100, the quay). The row spans x -71 to 80 (151 m);
## the mapped houses between Brandenburgska and Pauliska (x -10 to 20) are
## kept. Each house keeps its mapped front, width and depth.
##
## From the photos (visual-plan/refs/landmarks/skeppsbron_stockholm/): four
## floors over a rusticated pink-grey granite ground floor with a stone
## string course; plastered walls in ochre, cream, pale yellow, salmon,
## beige, rust and yellow; deep window surrounds in cream stone; a heavy
## cornice; steep dark-slate mansard or hipped roofs with dormers and brick
## or iron chimneys, the dormers showing curved shoulders on Nordström &
## Thulins hus; arched doors with a stone doorstep. From south to north:
## Thuenska huset (ochre, 5 bays), Nordström & Thulins hus (cream plaster over
## pink granite, 6 bays, two portals, three dormers), Hebbeska huset (pale
## yellow), Brandenburgska huset (salmon, 5 bays, the best known front,
## 22 m), Pauliska huset (beige, hipped), Dångerska huset (rust, 1630),
## Hobelinska huset (yellow, gambrel). Küselska huset, Tullhuset and the
## 1901 Brandstodsbolagets hus beyond the ends are not rebuilt.
## The quay stone is a raised granite footway under the facades with lamp
## standards along the kerb.
## Heights: the mapped 21.6-22 m is the roof top; here the roofs top out at
## 22-22.5 m with the chimneys to 24.5 m (the model top).

const K = preload("res://scripts/generation/landmarks/sweden_stockholm/gamla/sto_gamla_kit.gd")

const G := 0.3

static func materials() -> Dictionary:
	return {
		"Ochre": LandmarkMaterials.pbr("render", "#D5AD66", 3.0),
		"Cream": LandmarkMaterials.pbr("render", "#E9DEC9", 3.0),
		"Pale": LandmarkMaterials.pbr("render", "#E3D49E", 3.0),
		"Salmon": LandmarkMaterials.pbr("render", "#D9715D", 3.0),
		"Beige": LandmarkMaterials.pbr("render", "#D3BE94", 3.0),
		"Rust": LandmarkMaterials.pbr("render", "#B9664E", 3.0),
		"Yellow": LandmarkMaterials.pbr("render", "#DDAF58", 3.0),
		"Trim": LandmarkMaterials.pbr("limestone", "#E4DDCB", 2.5),
		"Stone": LandmarkMaterials.pbr("stone", "#A58E83", 2.5),
		"Slate": LandmarkMaterials.pbr("slate", "#3B3F44", 2.5),
		"Paving": LandmarkMaterials.pbr("pavement", "#8D8883", 2.5),
		"Iron": LandmarkMaterials.paint("#2B2E2F", 0.5, 0.5),
		"Glass": LandmarkMaterials.glass("#2A3236"),
		"Lamp": LandmarkMaterials.lit("#FFE2A8", 1.2),
	}

## x0, x1, front z of the wall, depth, spec.
static func _houses() -> Array:
	return [
		[-71.1, -56.6, 12.3, 26.5, {"wall": "Ochre", "eave": 16.5, "base_h": 4.4, "cols": 5, "rows": 3,
			"rise": 5.4, "dormers": 3, "chimneys": 2, "door": 2, "sides": true}],
		[-56.6, -41.5, 12.4, 24.5, {"wall": "Cream", "eave": 17.0, "base_h": 5.0, "cols": 6, "rows": 3,
			"win": Vector2(1.3, 2.1), "rise": 5.4, "dormers": 3, "chimneys": 3, "door": [2, 3]}],
		[-36.1, -23.6, 12.6, 26.6, {"wall": "Pale", "eave": 16.8, "base_h": 4.4, "cols": 5, "rows": 3,
			"rise": 5.2, "dormers": 2, "chimneys": 2, "door": 2}],
		[-23.6, -10.2, 12.6, 31.5, {"wall": "Salmon", "eave": 16.5, "base_h": 4.6, "cols": 5, "rows": 3,
			"win": Vector2(1.3, 2.0), "rise": 5.6, "dormers": 3, "chimneys": 2, "door": 2, "sides": true}],
		[19.8, 38.0, 12.3, 21.4, {"wall": "Beige", "eave": 16.5, "base_h": 4.2, "cols": 7, "rows": 3,
			"roof": "hip", "rise": 5.3, "chimneys": 3, "door": 3, "sides": true}],
		[43.6, 61.6, 12.4, 19.6, {"wall": "Rust", "eave": 16.2, "base_h": 4.2, "cols": 7, "rows": 3,
			"rise": 5.0, "dormers": 4, "chimneys": 2, "door": 3}],
		[64.1, 80.3, 12.6, 24.5, {"wall": "Yellow", "eave": 16.0, "base_h": 4.2, "cols": 6, "rows": 3,
			"rise": 5.5, "dormers": 3, "chimneys": 2, "door": 2, "sides": true}],
	]

static func build(model: Node3D) -> void:
	var mats := materials()
	var lm := K.fresh(mats)
	for h in _houses():
		var x0: float = h[0]
		var x1: float = h[1]
		var spec: Dictionary = (h[4] as Dictionary).duplicate()
		spec["w"] = x1 - x0
		spec["d"] = h[3]
		K.place(lm, K.house(mats, spec), Vector3((x0 + x1) * 0.5, 0.0, float(h[2])))
	_quay(lm)
	lm.commit(model)
	var warm := Color(1.0, 0.86, 0.66)
	var spots: Array = []
	for x in [-60.0, -30.0, -5.0, 30.0, 52.0, 72.0]:
		spots.append([Vector3(float(x), 1.5, 24.0), Vector3(float(x), 11.0, 12.8), 48.0, 0.85, 38.0, warm])
	model.set_meta(LandmarkLights.FLOOD_META, spots)

## Granite footway under the facades and lamp standards along its kerb.
static func _quay(lm: LandmarkMesh) -> void:
	K.Pal.rb(lm, "Paving", -73.0, 82.0, G, G + 0.1, 12.9, 16.2, 0.0)
	K.Pal.rb(lm, "Stone", -73.0, 82.0, G, G + 0.16, 16.2, 16.6, 0.0)
	var x := -66.0
	while x < 80.0:
		var p := Vector3(x, G, 16.0)
		lm.frustum("Iron", p, 0.13, 0.08, 4.8, 6)
		lm.box("Lamp", p + Vector3(0, 5.1, 0), Vector3(0.34, 0.5, 0.34), Basis(), 0.0)
		lm.spire("Iron", p + Vector3(0, 5.35, 0), 0.28, 0.3)
		x += 24.0
