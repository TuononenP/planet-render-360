class_name LandmarkBrStayed
extends RefCounted

## The cable-stayed bridges of the bridges batch in true metres, along +X
## on the shared LandmarkBrKit parts: Millau's seven-mast viaduct over a
## valley, the Oresund Bridge's two H pylons and Rotterdam's leaning
## Erasmus Bridge, the last two with y = 0 at the water.

## Millau Viaduct (y = 0 at the Tarn valley floor, bridge over land): 2460 m
## in eight spans (204 + 6 x 342 + 204 m) carried on seven concrete
## piers of 77 to 245 m that fork into two columns under the 32 m wide
## steel box deck, each topped by a 93 m mast with eleven stays a side
## in a single central plane; the mast tips stand 343 m over the valley.
const MI_PIER_X: Array[float] = [-1026.0, -684.0, -342.0, 0.0, 342.0, 684.0, 1026.0]
const MI_PIER_H: Array[float] = [94.5, 245.0, 221.0, 144.2, 136.4, 111.9, 77.6]
const MI_DECK_M := 250.0
const MI_DEPTH := 4.2
const MI_MAST_M := 93.0

static func millau(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	LandmarkBrKit.base_mats(lm, "#E6E7E5", "#D3D0C8")
	var under := MI_DECK_M - MI_DEPTH
	for i in MI_PIER_X.size():
		var x := MI_PIER_X[i]
		var h := MI_PIER_H[i]
		var base := under - h - 8.0
		var fork := minf(90.0, h * 0.6)
		var split := under - fork
		var f := (split - base) / (under - base)
		var hx := lerpf(7.5, 5.5, f)
		var hz := lerpf(9.0, 7.0, f)
		LandmarkBrKit.tapered_box(lm, "Concrete", Vector3(x, base, 0), 7.5, 9.0, hx, hz, split - base)
		for z in [-4.8, 4.8]:
			LandmarkBrKit.tapered_box(lm, "Concrete", Vector3(x, split, z), hx, 2.7, 4.2, 2.1, fork)
		lm.box("Concrete", Vector3(x, under - 0.6, 0), Vector3(10.0, 1.2, 14.0))
		# Mast: two legs closing into one blade, then the stay fan.
		for z in [-6.5, 6.5]:
			lm.beam("Steel", Vector3(x, MI_DECK_M, z), Vector3(x, MI_DECK_M + 30.0, z * 0.25), 3.0, 3.4,
				Vector3(0, 0, 1))
		var blade := MI_DECK_M + 30.0
		LandmarkBrKit.tapered_box(lm, "Steel", Vector3(x, blade, 0), 1.9, 2.4, 1.0, 1.2,
			MI_DECK_M + MI_MAST_M - blade)
		for dir in [-1.0, 1.0]:
			LandmarkBrKit.stays(lm, "Steel", x, dir, MI_DECK_M + 40.0, MI_DECK_M + MI_MAST_M - 6.0,
				11, 40.0, 13.0, MI_DECK_M, 0.0, 0.0, 0.5)
	LandmarkBrKit.deck_girder(lm, -1230.0, 1230.0, MI_DECK_M, 16.0, MI_DEPTH)
	for s in [-1.0, 1.0]:
		lm.box("Concrete", Vector3(s * 1236.0, MI_DECK_M - 6.0, 0), Vector3(12.0, 12.0, 30.0))
	lm.commit(model)

## Oresund Bridge, cable-stayed section: 490 m main span and 301 m side
## spans (1092 m) between two H pylons of 204 m with their stay fans in
## two planes, the 23.5 m two-level truss (motorway over railway) 57 m
## over the sound on side-span piers, and the lower approach spans.
const OR_MAIN := 490.0
const OR_SIDE := 301.0
const OR_TOWER_M := 204.0
const OR_DECK_M := 67.0
const OR_HALF_W := 11.75

static func oresund(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	LandmarkBrKit.base_mats(lm, "#B4BABC", "#D2D1CC")
	var tx := OR_MAIN * 0.5
	var end := tx + OR_SIDE
	for s in [-1.0, 1.0]:
		LandmarkBrKit.portal_tower(lm, "Concrete", s * tx, 0.0, OR_TOWER_M, 14.5, Vector2(4.6, 2.2),
			Vector2(2.7, 1.7), [142.0, 198.0], 6.0)
		for dir in [-1.0, 1.0]:
			for z in [-1.0, 1.0]:
				LandmarkBrKit.stays(lm, "Steel", s * tx, dir, 112.0, 196.0, 14, 40.0, 15.0,
					OR_DECK_M, z * 12.6, z * 10.5, 0.35)
		for off in [100.0, 200.0]:
			lm.box("Concrete", Vector3(s * (tx + off), 30.0, 0), Vector3(6.0, 62.0, 10.0))
		LandmarkBrKit.viaduct(lm, s * end, OR_DECK_M, s * (end + 420.0), 30.0, OR_HALF_W, 9.0, 140.0)
	LandmarkBrKit.deck_girder(lm, -end, end, OR_DECK_M, OR_HALF_W, 10.0, 20.0)
	lm.commit(model)

## Erasmus Bridge, Rotterdam ("The Swan"): 802 m with the 139 m steel
## pylon on the south bank bent back over the river, 32 stays fanning
## from it to the 284 m cable-stayed span (a short bundle of backstays
## the other way) on the 32.8 m box deck 15 m over the Nieuwe Maas.
const ER_PYLON_X := -5.0
const ER_TOP_M := 139.0
const ER_DECK_M := 15.0
const ER_MAST: Array[Vector2] = [Vector2(-5.0, 40.0), Vector2(-8.0, 78.0), Vector2(-13.0, 110.0),
	Vector2(-19.0, ER_TOP_M)]

static func erasmus(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	LandmarkBrKit.base_mats(lm, "#C6CED3")
	for z in [-5.5, 5.5]:
		LandmarkBrKit.tapered_box(lm, "Steel", Vector3(ER_PYLON_X, 0, z), 4.2, 2.4, 3.2, 2.0, 40.0)
	lm.box("Steel", Vector3(ER_PYLON_X, 14.0, 0), Vector3(7.0, 4.0, 11.0))
	for i in ER_MAST.size() - 1:
		var w := lerpf(5.2, 3.0, float(i) / (ER_MAST.size() - 1))
		lm.beam("Steel", Vector3(ER_MAST[i].x, ER_MAST[i].y, 0), Vector3(ER_MAST[i + 1].x, ER_MAST[i + 1].y, 0),
			w, w * 1.1, Vector3(0, 0, 1))
	# 17 stays to the main span, six backstays to the south deck.
	for i in 17:
		var ty := lerpf(70.0, 136.0, float(i) / 16.0)
		lm.beam("Steel", Vector3(_mast_x(ty), ty, 0), Vector3(ER_PYLON_X + 20.0 + 16.2 * i, ER_DECK_M, 0), 0.4, 0.4)
	for i in 6:
		var ty := lerpf(100.0, 137.0, float(i) / 5.0)
		lm.beam("Steel", Vector3(_mast_x(ty), ty, 0), Vector3(ER_PYLON_X - 45.0 - 17.0 * i, ER_DECK_M, 0), 0.5, 0.5)
	LandmarkBrKit.deck_girder(lm, -401.0, 401.0, ER_DECK_M, 16.4, 3.3)
	for x in [-71.0, -137.0, -203.0, -269.0, -335.0, -394.0, 300.0, 350.0, 396.0]:
		lm.box("Concrete", Vector3(x, 6.5, 0), Vector3(4.5, 17.0, 14.0))
	lm.commit(model)

## x of the bent mast at height y.
static func _mast_x(y: float) -> float:
	for i in ER_MAST.size() - 1:
		if y <= ER_MAST[i + 1].y:
			return lerpf(ER_MAST[i].x, ER_MAST[i + 1].x, (y - ER_MAST[i].y) / (ER_MAST[i + 1].y - ER_MAST[i].y))
	return ER_MAST[ER_MAST.size() - 1].x
