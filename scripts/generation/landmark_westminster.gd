class_name LandmarkWestminster
extends RefCounted

## Elizabeth Tower ("Big Ben", 96 m) with the Palace of Westminster in
## true metres: the 12 m square Anston-limestone shaft with Perpendicular
## Gothic panelling, four 7 m gilt-framed opal clock dials at 55 m, the
## gabled clock stage with corner pinnacles, the arcaded belfry and the
## steep cast-iron spire with the Ayrton Light lantern; the palace's
## river-front range runs south (+Z) to the 98 m Victoria Tower, with
## the octagonal Central Tower spire between. River (Thames) is east.

const SHAFT_TOP := 50.0
const DIAL_Y := 55.0
const STAGE_TOP := 61.0
const BELFRY_TOP := 72.0
const TOP := 96.0

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#C9B488", 3.0))
	lm.use("Palace", LandmarkMaterials.pbr("limestone", "#C2AD84", 3.5))
	lm.use("Roof", LandmarkMaterials.pbr("slate", "#4A5254", 2.0))
	lm.use("Iron", LandmarkMaterials.paint("#2C3236", 0.55, 0.4))
	lm.use("Gilt", LandmarkMaterials.gold())
	lm.use("Dial", LandmarkMaterials.lit("#F2EEDF", 0.35))
	lm.use("Windows", LandmarkMaterials.glass("#252C30"))
	_elizabeth(lm)
	_palace(lm)
	lm.commit(model)

static func _elizabeth(lm: LandmarkMesh) -> void:
	var w := 12.0
	lm.box("Stone", Vector3(0, 1.5, 0), Vector3(w + 1.2, 3.0, w + 1.2))  # plinth
	lm.box("Stone", Vector3(0, SHAFT_TOP * 0.5, 0), Vector3(w, SHAFT_TOP, w))
	# Corner buttress strips and vertical panel mullions on each face.
	for side in 4:
		var rot := Basis(Vector3.UP, PI * 0.5 * float(side))
		for k in [-1.0, 1.0]:
			lm.box("Stone", rot * Vector3(k * (w * 0.5 - 0.3), SHAFT_TOP * 0.5, w * 0.5 + 0.25),
				Vector3(0.9, SHAFT_TOP, 0.5), rot)
		for m in 5:
			var x := -w * 0.5 + 2.0 * float(m + 1)
			lm.box("Stone", rot * Vector3(x, 26.0, w * 0.5 + 0.12), Vector3(0.25, 44.0, 0.24), rot)
		for row in 9:
			var y := 6.0 + float(row) * 5.0
			lm.box("Stone", rot * Vector3(0, y, w * 0.5 + 0.14), Vector3(w - 1.6, 0.3, 0.28), rot)
			lm.box("Windows", rot * Vector3(0, y + 2.2, w * 0.5 + 0.03), Vector3(1.0, 2.6, 0.1), rot)
	# Clock stage: slightly wider block with the four dials.
	var sw := w + 1.4
	lm.box("Stone", Vector3(0, (SHAFT_TOP + STAGE_TOP) * 0.5, 0), Vector3(sw, STAGE_TOP - SHAFT_TOP, sw))
	for side in 4:
		var rot := Basis(Vector3.UP, PI * 0.5 * float(side))
		var out := rot * Vector3(0, 0, 1)
		var c := rot * Vector3(0, DIAL_Y, sw * 0.5)
		lm.box("Gilt", c + out * 0.15, Vector3(8.2, 8.2, 0.3), rot)
		lm.disc("Dial", c + out * 0.35, out, 3.5, 32)
		for h in 12:
			var a := TAU * float(h) / 12.0
			var p := c + out * 0.42 + rot * Vector3(sin(a), cos(a), 0) * 3.15
			lm.box("Iron", p, Vector3(0.22, 0.6, 0.08), rot * Basis(Vector3.BACK, -a))
		lm.beam("Iron", c + out * 0.5, c + out * 0.5 + rot * Vector3(1.6, 1.4, 0), 0.22, 0.08, out)
		lm.beam("Iron", c + out * 0.5, c + out * 0.5 + rot * Vector3(-0.4, 2.9, 0), 0.16, 0.08, out)
		# Gable over each dial.
		lm.gable("Stone", rot * Vector3(0, STAGE_TOP, sw * 0.5 - 1.0), 8.0, 2.0, 4.0, rot, 0.1, "Stone")
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var p := Vector3(sx * sw * 0.5, STAGE_TOP, sz * sw * 0.5)
			lm.frustum("Stone", p - Vector3(0, 2.0, 0), 0.8, 0.8, 3.0, 8)
			lm.spire("Gilt", p + Vector3(0, 1.0, 0), 0.6, 5.0)
	# Belfry: arcaded stage under the spire.
	var bw := w - 0.6
	lm.box("Stone", Vector3(0, STAGE_TOP + 0.6, 0), Vector3(sw, 1.2, sw))
	for side in 4:
		var rot := Basis(Vector3.UP, PI * 0.5 * float(side))
		for k in 4:
			var x := -bw * 0.5 + bw * (float(k) + 0.5) / 4.0
			lm.box("Windows", rot * Vector3(x, STAGE_TOP + 5.5, bw * 0.5 - 0.3), Vector3(2.0, 7.0, 0.4), rot)
		for k in 5:
			var x := -bw * 0.5 + bw * float(k) / 4.0
			lm.box("Stone", rot * Vector3(x, STAGE_TOP + 5.5, bw * 0.5), Vector3(0.7, 9.8, 0.9), rot)
	lm.box("Stone", Vector3(0, BELFRY_TOP - 0.6, 0), Vector3(bw + 0.8, 1.2, bw + 0.8))
	# Spire: steep cast-iron pyramid, lantern, spirelet and finial.
	lm.spire("Iron", Vector3(0, BELFRY_TOP, 0), bw * 0.5, 12.0, 2.4)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			lm.spire("Gilt", Vector3(sx * bw * 0.42, BELFRY_TOP, sz * bw * 0.42), 0.45, 6.0)
	lm.frustum("Gilt", Vector3(0, BELFRY_TOP + 12.0, 0), 2.6, 2.6, 0.5, 8)
	lm.frustum("Windows", Vector3(0, BELFRY_TOP + 12.5, 0), 2.1, 2.1, 3.0, 8)
	lm.spire("Iron", Vector3(0, BELFRY_TOP + 15.5, 0), 2.3, 6.5, 0.2)
	lm.frustum("Gilt", Vector3(0, BELFRY_TOP + 22.0, 0), 0.25, 0.05, TOP - BELFRY_TOP - 22.0, 6)

## Palace of Westminster river range, inner range, Central Tower and
## Victoria Tower (to the south, +Z).
static func _palace(lm: LandmarkMesh) -> void:
	# River front: 265 m of Perpendicular Gothic, 24 m to the parapet.
	var z0 := 10.0
	var z1 := 262.0
	var h := 24.0
	lm.box("Palace", Vector3(4.0, h * 0.5, (z0 + z1) * 0.5), Vector3(20.0, h, z1 - z0))
	lm.gable("Roof", Vector3(4.0, h, (z0 + z1) * 0.5), 18.0, z1 - z0, 7.0, Basis(), 0.2)
	var bays := 44
	for i in bays + 1:
		var z := z0 + (z1 - z0) * float(i) / float(bays)
		lm.box("Palace", Vector3(14.3, h * 0.5 + 1.0, z), Vector3(0.8, h + 2.0, 0.9))
		lm.spire("Palace", Vector3(14.3, h + 2.0, z), 0.5, 3.6)
		if i < bays:
			for row in 3:
				lm.box("Windows", Vector3(14.05, 4.0 + float(row) * 7.0, z + 2.85),
					Vector3(0.12, 4.2, 2.6))
	# Inner ranges (the courts behind), lower and set back.
	lm.box("Palace", Vector3(-38.0, 10.0, 130.0), Vector3(64.0, 20.0, 200.0))
	lm.gable("Roof", Vector3(-38.0, 20.0, 130.0), 62.0, 200.0, 9.0, Basis(), 0.2)
	# Gothic dressing on the street (west) and end faces of the courts.
	for i in 33:
		var z := 32.0 + float(i) * 6.0
		lm.box("Palace", Vector3(-70.3, 11.0, z), Vector3(0.8, 22.0, 0.9))
		lm.spire("Palace", Vector3(-70.3, 22.0, z), 0.5, 3.2)
		for row in 2:
			lm.box("Windows", Vector3(-70.05, 4.5 + float(row) * 8.0, z + 3.0), Vector3(0.12, 4.4, 2.4))
	for i in 10:
		var x := -66.0 + float(i) * 6.4
		for zz in [30.0, 230.0]:
			var sgn := -1.0 if zz < 100.0 else 1.0
			for row in 2:
				lm.box("Windows", Vector3(x, 4.5 + float(row) * 8.0, zz + sgn * 0.05), Vector3(2.4, 4.4, 0.12))
	# Central Tower: octagonal lantern and spire, 91 m.
	var ct := Vector3(-30.0, 0, 128.0)
	lm.frustum("Palace", ct + Vector3(0, 20.0, 0), 9.0, 9.0, 34.0, 8, PI / 8.0)
	for k in 8:
		var a := PI / 8.0 + TAU * float(k) / 8.0
		lm.box("Windows", ct + Vector3(cos(a) * 8.75, 42.0, sin(a) * 8.75), Vector3(2.4, 9.0, 2.4),
			Basis(Vector3.UP, -a))
	lm.lathe("Roof", ct + Vector3(0, 54.0, 0), PackedVector2Array([Vector2(9.2, 0), Vector2(6.0, 9.0),
		Vector2(1.6, 30.0), Vector2(0.15, 37.0)]), 8, 1.0, 1.0, PI / 8.0, false)
	# Victoria Tower: 23 m square, corner turrets, 98.5 m with flagstaff.
	var vt := Vector3(-40.0, 0, 250.0)
	var vh := 85.0
	lm.box("Palace", vt + Vector3(0, vh * 0.5, 0), Vector3(23.0, vh, 23.0))
	for side in 4:
		var rot := Basis(Vector3.UP, PI * 0.5 * float(side))
		for k in 3:
			lm.box("Windows", vt + rot * Vector3(-6.0 + 6.0 * float(k), 66.0, 11.55),
				Vector3(2.4, 14.0, 0.12), rot)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var p := vt + Vector3(sx * 11.0, 0, sz * 11.0)
			lm.frustum("Palace", p, 2.0, 2.0, vh + 4.0, 8, PI / 8.0)
			lm.spire("Gilt", p + Vector3(0, vh + 4.0, 0), 1.6, 9.5, 0.0, 8)
	lm.frustum("Iron", vt + Vector3(0, vh, 0), 0.35, 0.2, 13.5, 6)
