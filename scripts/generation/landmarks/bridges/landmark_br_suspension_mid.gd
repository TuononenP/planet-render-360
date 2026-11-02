class_name LandmarkBrSuspensionMid
extends RefCounted

## Three more suspension bridges of the bridges batch in true metres,
## along +X with y = 0 at the water (LocationData `base: water`), on the
## shared LandmarkBrKit parts: the two orange-and-green steel crossings
## of Lisbon and Vancouver and Budapest's stone-towered Chain Bridge.

## Ponte 25 de Abril, Lisbon: 1013 m main span and two 483.6 m side
## spans between the 190 m International Orange towers (four struts),
## the 26 m wide road deck 74 m over the Tagus on its 9 m truss (the
## railway runs in it) and concrete approach viaducts.
const PA_MAIN := 1013.0
const PA_SIDE := 483.6
const PA_TOWER_M := 190.0
const PA_DECK_M := 76.0
const PA_Z := 17.0

static func ponte_25_abril(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	LandmarkBrKit.base_mats(lm, "#B8452B", "#BDB8AC")
	var tx := PA_MAIN * 0.5
	var end := tx + PA_SIDE
	for s in [-1.0, 1.0]:
		LandmarkBrKit.portal_tower(lm, "Steel", s * tx, 0.0, PA_TOWER_M, PA_Z, Vector2(4.6, 3.6),
			Vector2(3.3, 2.7), [100.0, 126.0, 152.0, 176.0, 186.0], 5.0, false)
		for z in [-PA_Z, PA_Z]:
			lm.box("Concrete", Vector3(s * tx, 4.0, z), Vector3(16.0, 8.0, 12.0))
		lm.box("Concrete", Vector3(s * (end + 16.0), PA_DECK_M * 0.5, 0), Vector3(32.0, PA_DECK_M + 6.0, 36.0))
		LandmarkBrKit.viaduct(lm, s * (end + 32.0), PA_DECK_M, s * (end + 190.0), 58.0, 13.0, 4.0, 52.0)
	LandmarkBrKit.deck_girder(lm, -end, end, PA_DECK_M, 13.0, 9.0, 26.0)
	LandmarkBrKit.suspension(lm, "Steel", {"tx0": -tx, "tx1": tx, "e0": -end, "e1": end,
		"top": PA_TOWER_M - 2.0, "low": PA_DECK_M + 8.0, "end0": PA_DECK_M + 6.0,
		"end1": PA_DECK_M + 6.0, "sag0": 34.0, "sag1": 34.0, "z": PA_Z, "dz": 12.4,
		"deck_y": PA_DECK_M,
		"w": 1.0, "step": 26.0, "hw": 0.35})
	lm.commit(model)

## Lions Gate Bridge, Vancouver: 473 m main span between the 111 m
## steel towers, 187 m side spans, the slim pale-green truss deck 61 m
## over the First Narrows and concrete approach viaducts to the shores.
const LG_MAIN := 473.0
const LG_SIDE := 187.0
const LG_TOWER_M := 111.0
const LG_DECK_M := 62.0
const LG_Z := 9.0

static func lions_gate(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	LandmarkBrKit.base_mats(lm, "#8DB093", "#B5B0A4")
	var tx := LG_MAIN * 0.5
	var end := tx + LG_SIDE
	for s in [-1.0, 1.0]:
		LandmarkBrKit.portal_tower(lm, "Steel", s * tx, 0.0, LG_TOWER_M, LG_Z, Vector2(2.6, 1.5),
			Vector2(1.7, 1.2), [76.0, 88.0, 98.0, 106.0], 2.4, true, 1.0)
		for z in [-LG_Z, LG_Z]:
			lm.box("Concrete", Vector3(s * tx, 5.0, z), Vector3(10.0, 10.0, 7.0))
	LandmarkBrKit.viaduct(lm, end, LG_DECK_M, end + 330.0, 40.0, 8.0, 3.0, 55.0)
	LandmarkBrKit.viaduct(lm, -end, LG_DECK_M, -end - 330.0, 14.0, 8.0, 3.0, 55.0)
	LandmarkBrKit.deck_girder(lm, -end, end, LG_DECK_M, 7.5, 3.6, 15.0)
	LandmarkBrKit.suspension(lm, "Steel", {"tx0": -tx, "tx1": tx, "e0": -end, "e1": end,
		"top": LG_TOWER_M - 1.5, "low": LG_DECK_M + 3.0, "end0": LG_DECK_M + 3.0,
		"end1": LG_DECK_M + 3.0, "sag0": 10.0, "sag1": 10.0, "z": LG_Z, "dz": 6.9,
		"deck_y": LG_DECK_M,
		"w": 0.6, "step": 15.0, "hw": 0.2})
	for s in [-1.0, 1.0]:
		lm.box("Concrete", Vector3(s * (end + 8.0), 36.0, 0), Vector3(18.0, 72.0, 22.0))
	lm.commit(model)

## Szechenyi Chain Bridge, Budapest: 202 m main span between two
## triumphal-arch limestone towers (48 m) and 87 m side spans, the
## dark iron chains over them, a hanger every 3.6 m, the 15 m carriageway
## 14.5 m over the Danube and the abutments with their stone lions.
const SZ_MAIN := 202.0
const SZ_SIDE := 87.0
const SZ_DECK_M := 14.5

static func chain_bridge(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	LandmarkBrKit.base_mats(lm, "#48504A")
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#C9C1AE", 3.0))
	var tx := SZ_MAIN * 0.5
	var end := tx + SZ_SIDE
	for s in [-1.0, 1.0]:
		var x: float = s * tx
		# River pier, the two legs of the gate, lintel, attic and pediment.
		lm.box("Stone", Vector3(x, 7.0, 0), Vector3(12.0, 14.0, 22.0))
		# Three openings: the 7.8 m carriageway and a footway either side.
		for pz in [[-8.6, 2.0], [-4.3, 0.8], [4.3, 0.8], [8.6, 2.0]]:
			lm.box("Stone", Vector3(x, 23.0, pz[0]), Vector3(7.0, 17.0, pz[1]))
		lm.box("Stone", Vector3(x, 34.5, 0), Vector3(8.0, 6.0, 19.6))
		lm.box("Stone", Vector3(x, 41.0, 0), Vector3(6.4, 7.0, 17.0))
		lm.gable("Stone", Vector3(x, 44.5, 0), 6.4, 17.0, 3.5, Basis(), 0.5, "Stone")
		# Abutment buildings with their lions.
		var ax: float = s * (end + 9.0)
		lm.box("Stone", Vector3(ax, 10.0, 0), Vector3(18.0, 20.0, 22.0))
		lm.box("Stone", Vector3(ax, 20.6, 0), Vector3(19.0, 1.2, 23.0))
		for z in [-9.0, 9.0]:
			var lx: float = s * (end + 2.4)
			lm.box("Stone", Vector3(lx, 15.6, z), Vector3(3.4, 1.6, 2.2))
			lm.box("Stone", Vector3(lx, 17.1, z), Vector3(2.8, 1.6, 1.3))
			lm.box("Stone", Vector3(lx - s * 1.0, 18.4, z), Vector3(1.0, 1.1, 1.0))
	LandmarkBrKit.deck_girder(lm, -end, end, SZ_DECK_M, 7.5, 1.8)
	LandmarkBrKit.suspension(lm, "Steel", {"tx0": -tx, "tx1": tx, "e0": -end, "e1": end,
		"top": 37.0, "low": SZ_DECK_M + 3.0, "end0": SZ_DECK_M + 2.0, "end1": SZ_DECK_M + 2.0,
		"sag0": 5.0, "sag1": 5.0, "z": 8.4, "dz": 7.0, "deck_y": SZ_DECK_M, "w": 1.6, "step": 3.6,
		"hw": 0.16, "side": true})
	lm.commit(model)
