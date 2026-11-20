extends RefCounted

## Roofs of Stockholm Central, all black slate:
## - Each wing and pavilion has a two-stage mansard: a steep skirt over the
##   cornice, a shallower upper stage and a flat cap; one rectangular dormer
##   per bay on the front skirt, chimneys along the cap.
## - The central block has a taller mansard with five round-headed dormers,
##   a hipped crown above it (the highest roof, 24.3 m) with chimneys and the
##   flagpole that sets the model top (P.TOP).
## Abutting sides get no inset, so the skirts meet the neighbouring block.

const P = preload("res://scripts/generation/landmarks/sweden_stockholm/stations/sto_cs_plan.gd")
const FhU = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")

## Ridge of the central crown.
const CROWN := 24.3

static func build(lm: LandmarkMesh) -> void:
	var dormer := _dormer_template()
	for i in P.SECTIONS.size():
		var s: Array = P.SECTIONS[i]
		var x0 := float(s[0])
		var x1 := float(s[1])
		var zf := float(s[2])
		var kind := str(s[3])
		if kind == "centre":
			_centre(lm, x0, x1, zf)
			continue
		var il := 0.0 if i > 0 else 2.2
		var ir := 0.0 if i < P.SECTIONS.size() - 1 else 2.2
		var skirt := 3.8 if kind == "wing" else 4.7
		var cap := 1.4 if kind == "wing" else 1.8
		var ins := 2.2 if kind == "wing" else 2.5
		var r := _tier(lm, x0, x1, P.ZB, zf, P.EAVE, [il, ir, ins, ins], skirt)
		r = _tier(lm, r[0], r[1], r[2], r[3], r[4], [0.0, 0.0, 3.6, 3.2], cap)
		_cap(lm, r)
		var bays := int(s[4])
		var pitch := (x1 - x0) / float(bays)
		for b in bays:
			lm.merge(dormer, Transform3D(Basis(), Vector3(x0 + pitch * (float(b) + 0.5), 0.0, zf)))
		var top: float = r[4]
		var n := maxi(int((x1 - x0) / 14.0), 1)
		for k in n:
			_chimney(lm, x0 + (x1 - x0) * (float(k) + 0.5) / float(n), top, (P.ZB + zf) * 0.5 - 1.0)

## A sloped stage from the rectangle (x0..x1, z0..z1) at y0 up `h`, the sides
## inset by [left, right, back, front]; returns the rectangle on top as
## [x0, x1, z0, z1, y].
static func _tier(lm: LandmarkMesh, x0: float, x1: float, z0: float, z1: float, y0: float,
		ins: Array, h: float) -> Array:
	var y1 := y0 + h
	var ax0 := x0 + float(ins[0])
	var ax1 := x1 - float(ins[1])
	var az0 := z0 + float(ins[2])
	var az1 := z1 - float(ins[3])
	var lo := [Vector3(x0, y0, z0), Vector3(x1, y0, z0), Vector3(x1, y0, z1), Vector3(x0, y0, z1)]
	var hi := [Vector3(ax0, y1, az0), Vector3(ax1, y1, az0), Vector3(ax1, y1, az1), Vector3(ax0, y1, az1)]
	var outs := [Vector3(0, 0, -1), Vector3(1, 0, 0), Vector3(0, 0, 1), Vector3(-1, 0, 0)]
	var run := [float(ins[2]), float(ins[1]), float(ins[3]), float(ins[0])]
	for k in 4:
		var j := (k + 1) % 4
		var n: Vector3 = (outs[k] * h + Vector3.UP * maxf(float(run[k]), 0.05)).normalized()
		lm.quad("Roof", lo[k], lo[j], hi[j], hi[k], n)
	return [ax0, ax1, az0, az1, y1]

## Flat slate cap over the rectangle the last stage ended on.
static func _cap(lm: LandmarkMesh, r: Array) -> void:
	var y: float = r[4]
	lm.quad("Roof", Vector3(r[0], y, r[3]), Vector3(r[1], y, r[3]), Vector3(r[1], y, r[2]), Vector3(r[0], y, r[2]),
		Vector3.UP)

static func _chimney(lm: LandmarkMesh, x: float, y: float, z: float) -> void:
	lm.box("Wall", Vector3(x, y + 1.0, z), Vector3(1.2, 2.0, 1.2))
	lm.box("Trim", Vector3(x, y + 2.1, z), Vector3(1.5, 0.25, 1.5))

## A rectangular dormer on the front skirt of a wing (eave at y = 14.5), built
## once with its front plane at z = 0.
static func _dormer_template() -> LandmarkMesh:
	var t := LandmarkMesh.new()
	P.materials(t)
	t.box("Roof", Vector3(0, 16.4, -1.8), Vector3(1.9, 2.4, 2.6))
	t.gable("Roof", Vector3(0, 17.6, -1.8), 2.3, 2.9, 0.8, Basis(), 0.1)
	LandmarkDetail.window(t, "Trim", "Glass", Vector3(0, 16.35, -0.48), Vector3.BACK, 1.1, 1.7, false, 0.15)
	return t

## The central mansard and crown: the five round-headed dormers, the hipped
## crown, chimneys and the flagpole.
static func _centre(lm: LandmarkMesh, x0: float, x1: float, zf: float) -> void:
	var r := _tier(lm, x0, x1, P.ZC_BACK, zf, P.C_EAVE, [0.0, 0.0, 3.0, 3.0], 4.6)
	r = _tier(lm, r[0], r[1], r[2], r[3], r[4], [8.0, 8.0, 10.0, 12.0], CROWN - float(r[4]))
	_cap(lm, r)
	for i in 5:
		var x := P.CX + (float(i) - 2.0) * 3.6
		lm.box("Roof", Vector3(x, 18.1, zf - 2.0), Vector3(2.4, 3.4, 3.2))
		LandmarkDetail.window(lm, "Trim", "Glass", Vector3(x, 18.15, zf - 0.38), Vector3.BACK, 1.7, 2.7, true, 0.15)
		lm.box("Roof", Vector3(x, 19.9, zf - 2.0), Vector3(2.9, 0.3, 3.6))
	# Chimneys on the crown, the tall flagpole beside the ridge.
	for x in [P.CX - 6.0, P.CX + 6.0]:
		_chimney(lm, x, CROWN, 14.0)
	var base := Vector3(P.CX - 3.0, CROWN, 18.0)
	lm.beam("Pole", base, Vector3(base.x, P.TOP, base.z), 0.2)
	var fy := P.TOP - 0.2
	lm.quad("Pole", Vector3(base.x, fy - 1.6, base.z), Vector3(base.x - 2.6, fy - 1.6, base.z),
		Vector3(base.x - 2.6, fy, base.z), Vector3(base.x, fy, base.z), Vector3.BACK)
	lm.quad("Pole", Vector3(base.x - 2.6, fy - 1.6, base.z), Vector3(base.x, fy - 1.6, base.z),
		Vector3(base.x, fy, base.z), Vector3(base.x - 2.6, fy, base.z), Vector3.FORWARD)
