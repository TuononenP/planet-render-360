class_name LandmarkBrSuspensionLong
extends RefCounted

## The four great suspension bridges of the bridges batch in true metres,
## along +X with y = 0 at the water (LocationData `base: water`), on the
## shared LandmarkBrKit parts: towers, main cables over them down to the
## anchorages, hangers and the stiffened deck (RoadBuilder leaves the OSM
## deck out of the span, so this deck is the road).

## Akashi Kaikyo Bridge: the longest main span (1991 m) between two
## 282.8 m steel towers, 960 m side spans, the 14 m stiffening truss
## 66 m over the strait and the cables 35.5 m apart.
const AK_MAIN := 1991.0
const AK_SIDE := 960.0
const AK_TOWER_M := 282.8
const AK_DECK_M := 66.0
const AK_Z := 17.75
const AK_HALF_W := 14.4

static func akashi(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	LandmarkBrKit.base_mats(lm, "#C9CDCE")
	var tx := AK_MAIN * 0.5
	var end := tx + AK_SIDE
	for s in [-1.0, 1.0]:
		LandmarkBrKit.portal_tower(lm, "Steel", s * tx, 0.0, AK_TOWER_M, AK_Z, Vector2(4.4, 3.0),
			Vector2(3.0, 2.2), [92.0, 138.0, 184.0, 230.0, 276.0], 5.0, true, 2.2)
		for z in [-AK_Z, AK_Z]:
			lm.box("Concrete", Vector3(s * tx, 5.0, z), Vector3(18.0, 10.0, 15.0))
		lm.box("Concrete", Vector3(s * (end + 20.0), AK_DECK_M * 0.5, 0), Vector3(70.0, AK_DECK_M + 8.0, 64.0))
	LandmarkBrKit.deck_girder(lm, -end, end, AK_DECK_M, AK_HALF_W, 14.0, 28.8)
	LandmarkBrKit.suspension(lm, "Steel", {"tx0": -tx, "tx1": tx, "e0": -end, "e1": end,
		"top": AK_TOWER_M - 1.5, "low": AK_DECK_M + 8.0, "end0": AK_DECK_M + 6.0,
		"end1": AK_DECK_M + 6.0, "sag0": 60.0, "sag1": 60.0, "z": AK_Z, "dz": AK_HALF_W - 0.6,
		"deck_y": AK_DECK_M,
		"w": 1.2, "step": 28.8, "hw": 0.4})
	lm.commit(model)

## Tsing Ma Bridge: 1377 m main span between two 206 m concrete towers,
## a 355.5 m Ma Wan side span and a 300 m Tsing Yi one, the 41 m wide
## double-deck truss (roadway over railway) 62 m over the water.
const TM_MAIN := 1377.0
const TM_TOWER_M := 206.0
const TM_DECK_M := 70.0
const TM_Z := 20.0
const TM_HALF_W := 17.6

static func tsing_ma(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	LandmarkBrKit.base_mats(lm, "#D5D8D8", "#CFCCC3")
	var tx := TM_MAIN * 0.5
	for s in [-1.0, 1.0]:
		LandmarkBrKit.portal_tower(lm, "Concrete", s * tx, 0.0, TM_TOWER_M, TM_Z, Vector2(4.6, 2.8),
			Vector2(3.2, 2.2), [98.0, 136.0, 170.0, 202.0], 6.0)
	LandmarkBrKit.deck_girder(lm, -tx - 355.5, tx + 300.0, TM_DECK_M, TM_HALF_W, 8.0, 22.9)
	LandmarkBrKit.suspension(lm, "Steel", {"tx0": -tx, "tx1": tx, "e0": -tx - 355.5,
		"e1": tx + 300.0, "top": TM_TOWER_M - 2.0, "low": TM_DECK_M + 4.0, "end0": TM_DECK_M + 6.0,
		"end1": TM_DECK_M + 6.0, "sag0": 18.0, "sag1": 14.0, "z": TM_Z, "dz": TM_HALF_W - 0.6,
		"deck_y": TM_DECK_M,
		"w": 1.1, "step": 22.9, "hw": 0.4})
	lm.box("Concrete", Vector3(-tx - 375.5, 35.0, 0), Vector3(40.0, 80.0, 44.0))
	lm.box("Concrete", Vector3(tx + 320.0, 35.0, 0), Vector3(40.0, 80.0, 44.0))
	lm.commit(model)

## Verrazzano-Narrows Bridge: 1298 m main span and 370 m side spans
## between the two 211.5 m steel towers (four X-braced panels), the
## double-deck truss carrying twelve lanes 69 m over the Narrows.
const VZ_MAIN := 1298.0
const VZ_SIDE := 370.0
const VZ_TOWER_M := 211.5
const VZ_DECK_M := 77.0
const VZ_Z := 18.2
const VZ_HALF_W := 14.6

static func verrazzano(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	LandmarkBrKit.base_mats(lm, "#A4ABAE", "#B1ABA0")
	var tx := VZ_MAIN * 0.5
	var end := tx + VZ_SIDE
	for s in [-1.0, 1.0]:
		LandmarkBrKit.portal_tower(lm, "Steel", s * tx, 0.0, VZ_TOWER_M, VZ_Z, Vector2(5.0, 3.0),
			Vector2(3.4, 2.4), [100.0, 140.0, 175.0, 206.0], 5.0, true, 2.0)
		for z in [-VZ_Z, VZ_Z]:
			lm.box("Concrete", Vector3(s * tx, 6.0, z), Vector3(18.0, 12.0, 14.0))
		lm.box("Concrete", Vector3(s * (end + 24.0), VZ_DECK_M * 0.5, 0), Vector3(60.0, VZ_DECK_M + 10.0, 50.0))
	LandmarkBrKit.deck_girder(lm, -end, end, VZ_DECK_M, VZ_HALF_W, 8.0, 23.0)
	LandmarkBrKit.suspension(lm, "Steel", {"tx0": -tx, "tx1": tx, "e0": -end, "e1": end,
		"top": VZ_TOWER_M - 1.5, "low": VZ_DECK_M + 10.0, "end0": VZ_DECK_M + 4.0,
		"end1": VZ_DECK_M + 4.0, "sag0": 26.0, "sag1": 26.0, "z": VZ_Z, "dz": VZ_HALF_W - 0.6,
		"deck_y": VZ_DECK_M,
		"w": 1.0, "step": 18.0, "hw": 0.35})
	lm.commit(model)

## Bosphorus Bridge (15 July Martyrs Bridge): 1074 m main span between
## 165 m steel towers (three struts), a 231 m European and a 255 m
## Asian side span, the slim aerofoil box deck 64 m over the strait on
## the inclined V hangers that set it apart.
const BO_MAIN := 1074.0
const BO_TOWER_M := 165.0
const BO_DECK_M := 66.0
const BO_Z := 19.0
const BO_HALF_W := 15.5

static func bosphorus(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	LandmarkBrKit.base_mats(lm, "#C4C8CA")
	var tx := BO_MAIN * 0.5
	for s in [-1.0, 1.0]:
		LandmarkBrKit.portal_tower(lm, "Steel", s * tx, 0.0, BO_TOWER_M, BO_Z, Vector2(3.6, 2.6),
			Vector2(2.4, 1.9), [88.0, 122.0, 158.0], 4.0)
	var x0 := -tx - 231.0
	var x1 := tx + 255.0
	lm.box("Deck", Vector3((x0 + x1) * 0.5, BO_DECK_M - 0.2, 0), Vector3(x1 - x0, 0.4, BO_HALF_W * 2.0))
	lm.box("Steel", Vector3((x0 + x1) * 0.5, BO_DECK_M - 1.8, 0), Vector3(x1 - x0, 2.6, 24.0))
	lm.box("Steel", Vector3((x0 + x1) * 0.5, BO_DECK_M - 0.7, 0), Vector3(x1 - x0, 0.6, BO_HALF_W * 2.0 - 0.4))
	LandmarkBrKit.suspension(lm, "Steel", {"tx0": -tx, "tx1": tx, "e0": x0, "e1": x1,
		"top": BO_TOWER_M - 1.5, "low": BO_DECK_M + 2.0, "end0": BO_DECK_M + 3.0,
		"end1": BO_DECK_M + 3.0, "sag0": 14.0, "sag1": 16.0, "z": BO_Z, "dz": BO_HALF_W - 0.6,
		"deck_y": BO_DECK_M,
		"w": 0.8, "step": 24.0, "hw": 0.3, "vee": true})
	for ex in [x0 - 18.0, x1 + 18.0]:
		lm.box("Concrete", Vector3(ex, 35.0, 0), Vector3(40.0, 80.0, 44.0))
	lm.commit(model)
