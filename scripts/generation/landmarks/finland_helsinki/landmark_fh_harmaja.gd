extends RefCounted

## Harmaja Lighthouse (Harmajan majakka, 1883), on the rocky islet Harmaja
## at the mouth of Helsinki harbour. Frame: origin at the centre of the
## granite base (OSM way 203713854), X along its 6.5 m side; registry yaw
## 100 lays +X on the map (the base is 6.5 x 5.8 m).
##
## What the photographs show (visual-plan/refs/landmarks/harmaja_lighthouse/):
## a square tower of rock-faced granite ashlar, slightly battered, with a
## heavier base course, two small framed windows and a dark-metal capping
## plate with a slender cornice; on top a cast-iron conical tower painted
## rust red, white and rust red, flaring out under an orange-railed gallery;
## the glazed lantern with red panes round its lens; a verdigris dome,
## a ball and a weather vane. Low flat-roofed pilot-station wings in grey
## boarding with pale-green fascias stand against the sides of the base.
##
## Measured from OSM: the 6.5 x 5.8 m granite base. Read from photographs,
## scaled by that width: the base is 7.3 m tall, the iron tower 5.7 m
## above it, lantern, dome and vane 4.4 m more, 17.4 m in all above the
## rock; the published 25 m (not verified) is probably above the sea. The
## 3 m rock mound under the tower makes the model 20.4 m tall. The
## island's own buildings (pilot station complex, bunkers, the 56 m
## mast) are left to the mapped-building pass.

const U = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")
const M = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_massing.gd")

const ENTRY := {"type": "harmaja_lighthouse", "name": "Harmaja Lighthouse", "lat": 60.105015, "lon": 24.975562,
	"radius_m": 1500.0, "wiki_title": "Harmaja", "height_m": 20.4, "clear_m": 12.0,
	"yaw_deg": 100.0, "kind": "Lighthouse",
	"aliases": ["harmaja lighthouse", "harmajan majakka", "gråhara fyr"]}

const MOUND := 3.0
const BW := 6.5
const BD := 5.8

## Box frustum: w0 x d0 at y0 tapering to w1 x d1 over h.
static func _taper(lm: LandmarkMesh, key: String, y0: float, h: float, w0: float, d0: float, w1: float) -> void:
	lm.lathe(key, Vector3(0, y0, 0), PackedVector2Array([Vector2(1.4142, 0), Vector2(1.4142 * w1 / w0, h)]),
		4, w0 * 0.5, d0 * 0.5, PI * 0.25, false)

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#9A8F88", 2.0))
	lm.use("Rock", LandmarkMaterials.pbr("rock", "#8E7F78", 4.0))
	lm.use("Rust", LandmarkMaterials.paint("#B45A36", 0.6, 0.45))
	lm.use("White", LandmarkMaterials.paint("#ECEAE4", 0.55, 0.3))
	lm.use("Cap", LandmarkMaterials.paint("#34383A", 0.5, 0.5))
	lm.use("Copper", LandmarkMaterials.pbr("concrete", "#4FA386", 2.0, 0.45, 0.35))
	lm.use("Rail", LandmarkMaterials.paint("#D2602F", 0.6, 0.4))
	lm.use("Window", LandmarkMaterials.glass("#26303A"))
	lm.use("Lamp", LandmarkMaterials.lit("#FFE2A8", 1.2))
	lm.use("RedPane", LandmarkMaterials.pbr("render", "#C8302A", 2.0, 0.4))
	lm.use("Board", LandmarkMaterials.pbr("wood", "#6C6858", 2.0))
	lm.use("Fascia", LandmarkMaterials.paint("#A5CDB1", 0.6, 0.2))
	M.mound(lm, "Rock", 0.0, 0.0, 17.0, 14.0, MOUND)
	_tower(lm)
	_wings(lm)
	lm.commit(model)
	model.set_meta(LandmarkLights.HALO_META, [[Vector3(0, MOUND + 14.0, 0), 4.5, Color(1.0, 0.94, 0.78)],
		[Vector3(0, MOUND + 14.0, 0), 2.2, Color(1.0, 0.3, 0.2)]])

static func _tower(lm: LandmarkMesh) -> void:
	var y := MOUND
	# Heavy base course, the battered ashlar shaft, the capping plate.
	U.blk(lm, "Granite", 0.0, y, 0.0, BW + 0.9, 1.3, BD + 0.9)
	_taper(lm, "Granite", y + 1.3, 5.7, BW + 0.2, BD + 0.2, BW - 0.6)
	# Ashlar joints: thin courses read as rock-faced blocks.
	var yy := y + 1.9
	while yy < y + 6.8:
		U.blk(lm, "Cap", 0.0, yy, 0.0, BW - 0.2 - (yy - y) * 0.05, 0.035, BD - 0.2 - (yy - y) * 0.05)
		yy += 0.6
	U.blk(lm, "Cap", 0.0, y + 7.0, 0.0, BW + 1.2, 0.3, BD + 1.2)
	U.blk(lm, "Granite", 0.0, y + 6.7, 0.0, BW + 0.5, 0.3, BD + 0.5)
	# Two small framed windows, one on the +Z face and one on the +X face.
	U.blk(lm, "Granite", -1.0, y + 3.0, BD * 0.5 - 0.1, 1.0, 1.3, 0.35)
	U.opening(lm, "Window", Vector3(-1.0, y + 3.25, BD * 0.5 + 0.09), Vector3(0, 0, 1), 0.5, 0.8, false)
	U.blk(lm, "Granite", BW * 0.5 - 0.1, y + 4.0, 0.4, 0.35, 1.3, 1.0)
	U.opening(lm, "Window", Vector3(BW * 0.5 + 0.09, y + 4.25, 0.4), Vector3(1, 0, 0), 0.5, 0.8, false)
	# Cast-iron tower: rust, white, rust bands, flaring to the gallery.
	var iy := y + 7.3
	lm.lathe("Rust", Vector3(0, iy, 0), PackedVector2Array([Vector2(1.5, 0), Vector2(1.48, 1.2)]), 20)
	lm.lathe("White", Vector3(0, iy + 1.2, 0), PackedVector2Array([Vector2(1.48, 0), Vector2(1.36, 2.2)]), 20)
	lm.lathe("Rust", Vector3(0, iy + 3.4, 0), PackedVector2Array([Vector2(1.36, 0), Vector2(1.3, 1.8),
		Vector2(1.5, 2.05), Vector2(1.75, 2.3)]), 20)
	# Gallery: floor ring, railing, posts, the lantern base.
	var gy := iy + 5.7
	lm.lathe("Cap", Vector3(0, gy - 0.1, 0), PackedVector2Array([Vector2(1.9, 0), Vector2(1.9, 0.12)]), 20)
	lm.lathe("Rail", Vector3(0, gy + 0.95, 0), PackedVector2Array([Vector2(1.88, 0), Vector2(1.88, 0.06)]), 20)
	for k in 16:
		var a := TAU * float(k) / 16.0
		lm.beam("Rail", Vector3(cos(a) * 1.88, gy, sin(a) * 1.88), Vector3(cos(a) * 1.88, gy + 1.0, sin(a) * 1.88), 0.05, 0.05)
	# Lantern: lens glow, red panes between mullions.
	lm.frustum("Lamp", Vector3(0, gy, 0), 0.95, 0.95, 1.4, 12)
	for k in 8:
		var a := TAU * float(k) / 8.0 + PI / 8.0
		lm.beam("Cap", Vector3(cos(a) * 1.02, gy, sin(a) * 1.02), Vector3(cos(a) * 1.02, gy + 1.45, sin(a) * 1.02), 0.09, 0.09)
		if k % 2 == 0:
			var a2 := a + PI / 8.0
			lm.beam("RedPane", Vector3(cos(a2) * 1.0, gy + 0.15, sin(a2) * 1.0), Vector3(cos(a2) * 1.0, gy + 1.3, sin(a2) * 1.0), 0.32, 0.06)
	lm.frustum("Cap", Vector3(0, gy + 1.4, 0), 1.12, 1.12, 0.12, 12)
	var dprof := PackedVector2Array()
	for i in 7:
		var t := float(i) / 6.0 * PI * 0.5
		dprof.append(Vector2(1.18 * cos(t), 0.95 * sin(t)))
	lm.lathe("Copper", Vector3(0, gy + 1.5, 0), dprof, 18)
	lm.lathe("Cap", Vector3(0, gy + 2.45, 0), U.ball(0.18), 8)
	lm.beam("Cap", Vector3(0, gy + 2.7, 0), Vector3(0, MOUND + 17.4, 0), 0.05, 0.05)
	lm.box("Cap", Vector3(0.45, MOUND + 17.0, 0), Vector3(0.9, 0.25, 0.04))

## Low pilot-station wings against the sides of the base.
static func _wings(lm: LandmarkMesh) -> void:
	for s in [-1.0, 1.0]:
		var cx: float = s * (BW * 0.5 + 3.4)
		U.blk(lm, "Board", cx, MOUND, 0.6, 7.0, 3.1, 4.6)
		U.blk(lm, "Fascia", cx, MOUND + 3.1, 0.6, 7.4, 0.35, 5.0)
		U.blk(lm, "Cap", cx, MOUND + 3.45, 0.6, 6.6, 0.1, 4.2)
		for k in 2:
			U.blk(lm, "Window", cx - 1.6 + float(k) * 3.2, MOUND + 1.0, 2.92, 1.6, 1.3, 0.06)
