class_name LandmarkSalute
extends RefCounted

## Santa Maria della Salute (Longhena) in true metres: the octagonal
## church in white Istrian stone, a triumphal-arch façade with statues
## over the steps to the Grand Canal (+Z), the drum ringed by sixteen
## great scroll volutes ("orecchioni") carrying statues, the lead main
## dome and its lantern (~60 m to the statue), and behind it (−Z) the
## presbytery under a smaller dome flanked by two slim campanili.

const TOP_M := 60.0
## The octagon is 47 m across its flats.
const OCT_R := 25.4
const BODY_M := 24.0

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#ECE6DA", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", "#F4F0E6", 2.0))
	lm.use("Lead", LandmarkMaterials.pbr("concrete", "#8A8F94", 2.0, 0.5, 0.4))
	lm.use("Windows", LandmarkMaterials.glass("#2A3338"))
	lm.use("Steps", LandmarkMaterials.pbr("stone", "#BDB6A8", 2.0))
	var oct_rot := PI / 8.0
	# Octagonal body, cornice and attic.
	lm.frustum("Stone", Vector3.ZERO, OCT_R, OCT_R, BODY_M, 8, oct_rot)
	lm.frustum("Trim", Vector3(0, BODY_M, 0), OCT_R + 0.8, OCT_R + 0.8, 1.4, 8, oct_rot)
	lm.frustum("Stone", Vector3(0, BODY_M + 1.4, 0), OCT_R - 1.5, OCT_R - 1.5, 2.6, 8, oct_rot)
	# Each face: paired pilasters, a chapel window and a pediment.
	var apothem := OCT_R * cos(PI / 8.0)
	for f in 8:
		var a := PI * 0.25 * f + PI * 0.5
		var r := Basis(Vector3.UP, a)
		var out := r * Vector3(0, 0, 1)
		var face := out * (apothem + 0.3)
		for s in [-1.0, 1.0]:
			lm.box("Trim", face + r * Vector3(s * 8.2, BODY_M * 0.5, 0), Vector3(1.4, BODY_M, 0.8), r)
		lm.box("Windows", face + Vector3(0, 13.0, 0), Vector3(3.4, 7.0, 0.2), r)
		lm.gable("Trim", face + Vector3(0, BODY_M - 4.0, 0) + out * 0.4, 14.0, 1.2, 2.6,
			r, 0.2, "Trim")
	# Grand Canal façade: triumphal arch, columns, statues and steps.
	var front := Vector3(0, 0, apothem + 1.2)
	lm.box("Stone", front + Vector3(0, 12.0, 0), Vector3(16.0, 24.0, 2.4))
	lm.box("Windows", front + Vector3(0, 7.5, 1.25), Vector3(5.0, 12.0, 0.2))
	lm.disc("Windows", front + Vector3(0, 13.5, 1.26), Vector3(0, 0, 1), 2.5, 16)
	for s in [-1.0, -0.55, 0.55, 1.0]:
		lm.lathe("Trim", front + Vector3(s * 6.8, 0, 1.4), PackedVector2Array([Vector2(0.75, 0),
			Vector2(0.65, 19.0)]), 10)
	lm.gable("Trim", front + Vector3(0, 21.0, 0.6), 17.0, 2.6, 3.4, Basis(), 0.3, "Stone")
	for s in [-1.0, 0.0, 1.0]:
		_statue(lm, front + Vector3(s * 7.5, 24.4 + (1.0 if s == 0.0 else 0.0), 0.6), 2.4)
	for k in 5:
		lm.box("Steps", Vector3(0, 0.2 + 0.4 * k, apothem + 8.5 - 1.1 * k), Vector3(24.0 - k, 0.4, 2.2))
	# Drum ringed by sixteen volutes with statues.
	var drum_y := BODY_M + 4.0
	lm.frustum("Stone", Vector3(0, drum_y, 0), 15.0, 15.0, 11.0, 16)
	for k in 16:
		var a := TAU * k / 16.0
		var dir := Vector3(cos(a), 0, sin(a))
		lm.box("Windows", dir * 15.05 + Vector3(0, drum_y + 5.5, 0), Vector3(2.0, 4.6, 0.2),
			Basis(Vector3.UP, atan2(dir.x, dir.z)))
		var vb := Basis(Vector3.UP, atan2(dir.x, dir.z)) * Basis(Vector3.RIGHT, -0.5)
		lm.box("Trim", dir * 18.2 + Vector3(0, drum_y + 1.4, 0), Vector3(1.6, 8.0, 3.2), vb)
		lm.lathe("Trim", dir * 20.4 + Vector3(0, drum_y - 2.4, 0), _spiral(1.5), 10)
		if k % 2 == 0:
			_statue(lm, dir * 16.6 + Vector3(0, drum_y + 5.0, 0), 1.8)
	lm.frustum("Trim", Vector3(0, drum_y + 11.0, 0), 15.8, 15.8, 1.0, 16)
	# Main dome (lead, ribbed) and lantern.
	var dome_y := drum_y + 12.0
	lm.lathe("Lead", Vector3(0, dome_y, 0), _dome(15.5, 10.0), 24)
	for k in 16:
		var a := TAU * k / 16.0
		var pts := _dome(15.65, 10.1)
		for j in pts.size() - 2:
			lm.beam("Trim", Vector3(cos(a) * pts[j].x, dome_y + pts[j].y, sin(a) * pts[j].x),
				Vector3(cos(a) * pts[j + 1].x, dome_y + pts[j + 1].y, sin(a) * pts[j + 1].x), 0.35, 0.25)
	var lan_y := dome_y + 10.0
	lm.frustum("Stone", Vector3(0, lan_y, 0), 3.4, 3.2, 4.2, 8, PI / 8.0)
	lm.lathe("Lead", Vector3(0, lan_y + 4.2, 0), _dome(3.6, 2.4), 12)
	lm.frustum("Trim", Vector3(0, lan_y + 6.6, 0), 0.6, 0.4, 0.8, 8)
	_statue(lm, Vector3(0, lan_y + 7.4, 0), TOP_M - lan_y - 7.4)
	# Presbytery: lower block, smaller dome and the two campanili.
	lm.box("Stone", Vector3(0, 11.0, -30.0), Vector3(30.0, 22.0, 16.0))
	lm.box("Trim", Vector3(0, 22.6, -30.0), Vector3(31.0, 1.2, 17.0))
	lm.frustum("Stone", Vector3(0, 23.2, -30.0), 8.0, 8.0, 6.0, 16)
	lm.lathe("Lead", Vector3(0, 29.2, -30.0), _dome(8.4, 7.0), 20)
	lm.frustum("Stone", Vector3(0, 36.2, -30.0), 1.8, 1.6, 2.6, 8, PI / 8.0)
	lm.lathe("Lead", Vector3(0, 38.8, -30.0), _dome(1.9, 1.4), 10)
	for s in [-1.0, 1.0]:
		var cx: float = s * 12.0
		lm.box("Stone", Vector3(cx, 19.0, -38.0), Vector3(4.6, 38.0, 4.6))
		lm.box("Windows", Vector3(cx, 33.0, -35.65), Vector3(1.6, 3.6, 0.2))
		lm.box("Trim", Vector3(cx, 38.4, -38.0), Vector3(5.4, 0.8, 5.4))
		lm.lathe("Lead", Vector3(cx, 38.8, -38.0), _dome(2.6, 3.4), 10)
		lm.frustum("Trim", Vector3(cx, 42.2, -38.0), 0.5, 0.1, 3.0, 6)
	lm.commit(model)

## A dome profile (radius, y): a raised half-circle of base radius r
## rising h, closed at the apex.
static func _dome(r: float, h: float) -> PackedVector2Array:
	var pr := PackedVector2Array()
	for k in 9:
		var t := PI * 0.5 * float(k) / 8.0
		pr.append(Vector2(cos(t) * r, sin(t) * h))
	pr[pr.size() - 1] = Vector2(0.0, h)
	return pr

## The curled foot of a volute: a squat round scroll.
static func _spiral(r: float) -> PackedVector2Array:
	return PackedVector2Array([Vector2(r * 0.6, 0), Vector2(r, r * 0.6), Vector2(r * 0.9, r * 1.4),
		Vector2(r * 0.4, r * 1.8), Vector2(0.0, r * 1.9)])

## A standing statue on its plinth, h tall overall.
static func _statue(lm: LandmarkMesh, base: Vector3, h: float) -> void:
	lm.box("Trim", base + Vector3(0, h * 0.12, 0), Vector3(h * 0.35, h * 0.24, h * 0.35))
	lm.lathe("Trim", base + Vector3(0, h * 0.24, 0), PackedVector2Array([Vector2(h * 0.14, 0),
		Vector2(h * 0.12, h * 0.5), Vector2(h * 0.08, h * 0.62), Vector2(h * 0.07, h * 0.7),
		Vector2(0.0, h * 0.76)]), 8)
