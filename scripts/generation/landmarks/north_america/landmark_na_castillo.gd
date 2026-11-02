class_name LandmarkNaCastillo
extends RefCounted

## Chichén Itzá's El Castillo (Temple of Kukulcán) in true metres; the
## north stairway (with the serpent heads) faces -Z.

const TOP_M := 30.0
const BODY_M := 24.0
const BASE_HW := 27.65
const TERRACES := 9
const STEPS := 91

## El Castillo (9th-12th c.): the nine-terrace stepped pyramid, 55.3 m
## square and 24 m high, each terrace a sloping talud under a vertical
## tablero of recessed panels (52 a side, the years of the calendar
## round, split into 18 by the stairways for the months); the four
## stairways of 91 steps (with the top platform, 365) between their
## balustrades, the north one ending at the foot in the two great
## feathered-serpent heads whose shadow-body appears at the equinoxes;
## and on top the Temple of Kukulcán: a triple north doorway divided
## by two serpent columns, one door on each other side, the moulded
## frieze and cornice, and the crest of stepped merlons, to 30 m.
static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#BDB39B", 4.0))
	lm.use("Steps", LandmarkMaterials.pbr("limestone", "#CEC5AD", 3.0))
	lm.use("Door", LandmarkMaterials.glass("#1F2528"))
	var th := BODY_M / float(TERRACES)
	for k in TERRACES:
		_terrace(lm, float(k) * th, th, BASE_HW - 2.0 * float(k), 2 if k == TERRACES - 1 else 3)
	var rise := BODY_M / float(STEPS)
	var run := (BASE_HW + 0.25 - 11.65) / float(STEPS)
	for q in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * float(q))
		for i in STEPS:
			var top := rise * float(i + 1)
			lm.box("Steps", r * Vector3(0, top * 0.5, BASE_HW + 0.25 - run * (float(i) + 0.5)),
				Vector3(8.9, top, run + 0.02), r, 0.0)
		# Balustrades: a sloping ramp each side of the flight.
		for sx in [-1.0, 1.0]:
			var a := r * Vector3(sx * 5.25, 0.0, BASE_HW + 0.6)
			var b := r * Vector3(sx * 5.25, BODY_M, 11.4)
			var dir := (b - a).normalized()
			var up := dir.cross(r * Vector3(1, 0, 0)).normalized()
			if up.y < 0.0:
				up = -up
			lm.beam("Stone", a + up * 0.9, b + up * 0.9, 1.6, 1.8, r * Vector3(1, 0, 0))
			lm.beam("Stone", a + up * 1.85, b + up * 1.85, 1.75, 0.25, r * Vector3(1, 0, 0))
			if q == 2:
				_serpent_head(lm, r * Vector3(sx * 5.25, 0.0, BASE_HW + 1.2), r)
	_temple(lm, Vector3(0, BODY_M, 0))
	lm.commit(model)

## One terrace from y0, `h` tall, half-width hw at its foot: the talud
## sloping in, the recessed tablero with `panels` framed panels on each
## half of every face (split by the stairway), and the top band.
static func _terrace(lm: LandmarkMesh, y0: float, h: float, hw: float, panels: int) -> void:
	var tal := h * 0.5
	lm.spire("Stone", Vector3(0, y0, 0), hw, tal, hw - 0.4)
	lm.box("Stone", Vector3(0, y0 + tal + (h - tal) * 0.5, 0), Vector3((hw - 0.45) * 2.0, h - tal, (hw - 0.45) * 2.0),
		Basis(), 0.0)
	var band := 0.28
	var top_y := y0 + h - band * 0.5
	lm.box("Stone", Vector3(0, top_y, 0), Vector3((hw - 0.2) * 2.0, band, (hw - 0.2) * 2.0), Basis(), 0.0)
	var gap := 6.2
	for q in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * float(q))
		for sx in [-1.0, 1.0]:
			var x0 := gap
			var x1 := hw - 0.4
			var ln := x1 - x0
			var cx: float = (x0 + x1) * 0.5 * sx
			var z := hw - 0.3
			# Lower band of the panel frames.
			lm.box("Stone", r * Vector3(cx, y0 + tal + 0.12, z), Vector3(ln, 0.24, 0.3), r, 0.0)
			# Uprights between the recessed panels.
			for p in panels + 1:
				var x: float = (x0 + ln * float(p) / float(panels)) * sx
				lm.box("Stone", r * Vector3(x, y0 + tal + (h - tal) * 0.5, z), Vector3(0.3, h - tal, 0.3), r, 0.0)
			# Each recessed panel: an inner frame round a raised tablet.
			var pw := ln / float(panels)
			var ph := h - tal - band
			for p in panels:
				var x: float = (x0 + ln * (float(p) + 0.5) / float(panels)) * sx
				var pc := r * Vector3(x, y0 + tal + ph * 0.5, z - 0.12)
				lm.box("Stone", pc + Vector3(0, ph * 0.32, 0), Vector3(pw * 0.8, 0.1, 0.12), r, 0.0)
				lm.box("Stone", pc - Vector3(0, ph * 0.32, 0), Vector3(pw * 0.8, 0.1, 0.12), r, 0.0)
				for e in [-1.0, 1.0]:
					lm.box("Stone", pc + r * Vector3(e * pw * 0.38, 0, 0), Vector3(0.1, ph * 0.66, 0.12), r, 0.0)
				lm.box("Stone", pc + r * Vector3(0, 0, -0.05), Vector3(pw * 0.5, ph * 0.36, 0.12), r, 0.0)

## A feathered-serpent head at the foot of the north balustrade at
## `p`: the great head with its plumed brow, open jaws and fangs, and
## the forked tongue on the ground.
static func _serpent_head(lm: LandmarkMesh, p: Vector3, r: Basis) -> void:
	var f := r * Vector3(0, 0, 1)
	lm.box("Stone", p + Vector3(0, 1.1, 0), Vector3(2.2, 2.2, 2.6), r)
	lm.box("Stone", p + Vector3(0, 2.3, -0.2), Vector3(2.5, 0.5, 2.4), r)
	lm.box("Stone", p + Vector3(0, 1.6, 0) + f * 1.6, Vector3(2.0, 0.9, 1.0), r)
	lm.box("Stone", p + Vector3(0, 0.45, 0) + f * 1.5, Vector3(1.9, 0.6, 1.0), r)
	for s in [-0.6, 0.6]:
		lm.frustum("Stone", p + r * Vector3(s, 0.75, 1.9), 0.13, 0.02, 0.5, 6)
		lm.lathe("Stone", p + r * Vector3(s * 1.4, 1.9, 0.4), PackedVector2Array([Vector2(0.0, 0.0),
			Vector2(0.28, 0.1), Vector2(0.3, 0.4), Vector2(0.0, 0.5)]), 8)
	lm.box("Stone", p + Vector3(0, 0.08, 0) + f * 2.6, Vector3(0.5, 0.16, 1.4), r, 0.0)

## The Temple of Kukulcán on the top platform at `b`.
static func _temple(lm: LandmarkMesh, b: Vector3) -> void:
	var hw := 6.5
	var wall := 1.2
	var wh := 3.4
	lm.box("Stone", b + Vector3(0, 0.2, 0), Vector3(hw * 2.0 + 0.6, 0.4, hw * 2.0 + 0.6))
	lm.box("Door", b + Vector3(0, wh * 0.5 + 0.4, 0), Vector3((hw - wall) * 2.0, wh, (hw - wall) * 2.0))
	for q in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * float(q))
		var north := q == 2
		# Openings along the face: three on the north, one elsewhere.
		var spans: Array = [[-4.4, 4.4]] if north else [[-1.2, 1.2]]
		var lo: float = (spans[0] as Array)[0]
		var hi: float = (spans[0] as Array)[1]
		var z := hw - wall * 0.5
		var y0 := b.y + 0.4
		var dh := 2.6
		lm.box("Stone", r * Vector3((-hw + lo) * 0.5, y0 + wh * 0.5, z), Vector3(lo + hw, wh, wall), r)
		lm.box("Stone", r * Vector3((hw + hi) * 0.5, y0 + wh * 0.5, z), Vector3(hw - hi, wh, wall), r)
		lm.box("Stone", r * Vector3((lo + hi) * 0.5, y0 + dh + (wh - dh) * 0.5, z), Vector3(hi - lo, wh - dh, wall), r)
		if north:
			# Two serpent columns: heads on the floor, rattles up under the
			# lintel.
			for x in [-1.5, 1.5]:
				var cb := r * Vector3(x, y0, z)
				lm.box("Stone", cb + r * Vector3(0, 0.45, 0.5), Vector3(1.0, 0.9, 1.6), r)
				lm.frustum("Stone", cb + Vector3(0, 0.9, 0), 0.5, 0.45, dh - 1.3, 12)
				lm.box("Stone", cb + Vector3(0, dh - 0.25, 0), Vector3(1.2, 0.5, 1.2), r)
				for k in 3:
					lm.frustum("Stone", cb + Vector3(0, 1.3 + 0.5 * k, 0), 0.53, 0.53, 0.1, 12)
		# Mouldings: the medial moulding, the frieze, the cornice.
		var ww := hw * 2.0 + 0.2
		lm.box("Stone", r * Vector3(0, y0 + wh + 0.15, hw), Vector3(ww, 0.3, 0.5), r, 0.0)
		lm.box("Stone", r * Vector3(0, y0 + wh + 0.65, hw - 0.1), Vector3(ww - 0.2, 0.7, 0.4), r, 0.0)
		for k in 9:
			var x := -hw + 0.9 + (hw * 2.0 - 1.8) * float(k) / 8.0
			lm.box("Stone", r * Vector3(x, y0 + wh + 0.65, hw + 0.12), Vector3(0.7, 0.4, 0.12), r, 0.0)
		lm.box("Stone", r * Vector3(0, y0 + wh + 1.12, hw + 0.05), Vector3(ww + 0.2, 0.25, 0.6), r, 0.0)
	var roof := b + Vector3(0, 0.4 + wh + 1.24, 0)
	lm.box("Stone", roof - Vector3(0, 0.62, 0), Vector3(hw * 2.0, 1.24, hw * 2.0))
	# Crest of stepped merlons round the roof edge.
	var mh := TOP_M - roof.y
	for q in 4:
		var r := Basis(Vector3.UP, PI * 0.5 * float(q))
		for k in 7:
			var x := -hw + 0.9 + (hw * 2.0 - 1.8) * float(k) / 6.0
			var c := roof + r * Vector3(x, 0, hw - 0.4)
			lm.box("Stone", c + Vector3(0, mh * 0.3, 0), Vector3(1.1, mh * 0.6, 0.5), r, 0.0)
			lm.box("Stone", c + Vector3(0, mh * 0.8, 0), Vector3(0.6, mh * 0.4, 0.5), r, 0.0)
