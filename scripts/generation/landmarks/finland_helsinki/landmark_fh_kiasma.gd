extends RefCounted

## Kiasma (Steven Holl, 1998), Mannerheimintie, built on its OpenStreetMap
## outline (way 8042215, simplified to 1 m) in the model frame the registry
## yaw (67) turns onto the map; the origin is the footprint centre.
##
## From the Commons photos in visual-plan/refs/landmarks/kiasma/:
## - Two bars cross at an angle (the "chiasma"). The long straight bar is
##   clad in smooth pale aluminium panels, with a few glazed bands and
##   a curved sweep at its roof edge.
## - The west prow is a heavy curved shell in dark brown bronze-toned metal
##   whose end wall carries one huge segmental-arched window and stacked
##   glazed boxes below.
## - Between them a tilted glass wall shows the stair and ramp zig-zag.
## - At night the window bands and the glass wall glow warm white.
##
## Measured: the outline (OSM) and the 26 m height (LoD2 and the registry,
## which agree). Estimated: which outline edges are prow, bar and glass wall
## (read from the photos), the window positions and the roof sweep.

const FhU = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")
const FhP = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_parts.gd")

const ENTRY := {"type": "kiasma", "name": "Kiasma", "lat": 60.17204, "lon": 24.93674,
	"radius_m": 5000.0, "wiki_title": "Kiasma", "height_m": 26.0, "clear_m": 82.0,
	"yaw_deg": 67.0, "kind": "Museum", "aliases": ["kiasma", "kiasma museum", "nykytaiteen museo kiasma",
		"museum of contemporary art, helsinki", "kiasma helsinki"]}

const FOOT := [Vector2(55.1, 18.5), Vector2(52.0, 29.3), Vector2(-21.6, 7.5), Vector2(-49.6, 19.8),
	Vector2(-63.3, -5.3), Vector2(-26.4, -11.8), Vector2(4.1, -12.8), Vector2(56.4, 2.2), Vector2(52.8, 15.9),
	Vector2(55.6, 16.7)]
const EAVE := 19.0

static func _p3(v: Vector2, y: float = 0.0) -> Vector3:
	return Vector3(v.x, y, v.y)

## A window strip on edge a..b of the ring between fractions t0..t1 and heights y0..y1.
static func _strip(lm: LandmarkMesh, glass: String, frame: String, a: Vector2, b: Vector2, o: Vector3,
		t0: float, t1: float, y0: float, y1: float, mull: float) -> void:
	var p := _p3(a.lerp(b, t0)) + o * 0.08
	var q := _p3(a.lerp(b, t1)) + o * 0.08
	lm.quad(glass, p + Vector3(0, y0, 0), q + Vector3(0, y0, 0), q + Vector3(0, y1, 0), p + Vector3(0, y1, 0), o)
	var n := maxi(int(p.distance_to(q) / mull), 1)
	for k in n + 1:
		var m := p.lerp(q, float(k) / float(n))
		lm.box(frame, m + Vector3(0, (y0 + y1) * 0.5, 0) + o * 0.04, Vector3(0.1, y1 - y0, 0.12), Basis(Vector3.UP, atan2(o.x, o.z)), 0.0)
	for yy in [y0, y1, (y0 + y1) * 0.5]:
		var d := p.distance_to(q)
		lm.box(frame, (p + q) * 0.5 + Vector3(0, yy, 0) + o * 0.04, Vector3(d, 0.1, 0.12), Basis(Vector3.UP, atan2(o.x, o.z)), 0.0)

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Silver", LandmarkMaterials.pbr("concrete", "#B4BABD", 3.0, 0.35, 0.65))
	lm.use("Bronze", LandmarkMaterials.pbr("concrete", "#4F3B30", 3.0, 0.4, 0.6))
	lm.use("Glass", LandmarkMaterials.paint("#6C929A", 0.2, 0.5))
	lm.use("Lit", LandmarkMaterials.lit("#E8DDC0", 0.25))
	lm.use("Frame", LandmarkMaterials.paint("#3B3F42", 0.5, 0.5))
	lm.use("Roof", LandmarkMaterials.pbr("concrete", "#A9AFB2", 3.0, 0.4, 0.55))
	lm.use("Plinth", LandmarkMaterials.pbr("stone", "#8A8780", 4.0))
	var foot := PackedVector2Array(FOOT)
	lm.poly_prism("Plinth", foot, 0.0, 0.8)
	lm.poly_prism("Silver", foot, 0.8, EAVE)
	for i in foot.size():
		var a := foot[i]
		var b := foot[(i + 1) % foot.size()]
		var o := FhP.edge_out(foot, i)
		var a3 := _p3(a)
		var b3 := _p3(b)
		if i == 3 or i == 4:
			# The dark bronze prow shell: its end wall and its north-west flank.
			lm.quad("Bronze", a3 + o * 0.05 + Vector3(0, 0.8, 0), b3 + o * 0.05 + Vector3(0, 0.8, 0),
				b3 + o * 0.05 + Vector3(0, EAVE, 0), a3 + o * 0.05 + Vector3(0, EAVE, 0), o)
		elif a.distance_to(b) > 9.0:
			# Panel seams of the aluminium skin.
			FhP.ribs(lm, "Frame", a3, b3, o, 0.8, EAVE, 3.0, 0.05, 0.05)
			for y in [4.9, 9.4, 14.0]:
				FhP.band(lm, "Frame", a3, b3, o, y, 0.06, 0.04)
	# Front long side (edge 1-2): shop-floor glazing and two upper glazed bands.
	var a1 := foot[1]
	var b1 := foot[2]
	var o1 := FhP.edge_out(foot, 1)
	_strip(lm, "Glass", "Frame", a1, b1, o1, 0.40, 0.97, 1.0, 4.8, 3.0)
	_strip(lm, "Glass", "Frame", a1, b1, o1, 0.03, 0.34, 6.4, 8.6, 3.0)
	_strip(lm, "Lit", "Frame", a1, b1, o1, 0.50, 0.92, 10.8, 13.0, 3.0)
	# Back long side (edge 6-7): a ground glazing band.
	_strip(lm, "Glass", "Frame", foot[6], foot[7], FhP.edge_out(foot, 6) * 1.0, 0.10, 0.60, 1.0, 4.6, 3.0)
	# The tilted glass wall at the crossing (edge 2-3) with its stair zig-zag.
	var a2 := foot[2]
	var b2 := foot[3]
	var o2 := FhP.edge_out(foot, 2)
	var p2 := _p3(a2) + o2 * 0.06
	var q2 := _p3(b2) + o2 * 0.06
	var lean := o2 * 2.5
	lm.quad("Glass", p2 + Vector3(0, 0.8, 0), q2 + Vector3(0, 0.8, 0), q2 + Vector3(0, EAVE, 0) + lean,
		p2 + Vector3(0, EAVE, 0) + lean, o2)
	for k in 13:
		var t := float(k) / 12.0
		var m := p2.lerp(q2, t)
		lm.beam("Frame", m + Vector3(0, 0.8, 0), m + Vector3(0, EAVE, 0) + lean, 0.1, 0.12, Vector3.UP.cross(o2))
	for k in 6:
		var y := 0.8 + float(k) * 3.1
		var lerp_lean := lean * ((y - 0.8) / (EAVE - 0.8))
		lm.beam("Frame", p2 + Vector3(0, y, 0) + lerp_lean, q2 + Vector3(0, y, 0) + lerp_lean, 0.1, 0.12, o2)
	# The prow's huge segmental-arched window on the end wall (edge 3-4).
	var pa := foot[3]
	var pb := foot[4]
	var po := FhP.edge_out(foot, 3)
	var w0 := _p3(pa.lerp(pb, 0.08)) + po * 0.1
	var w1 := _p3(pa.lerp(pb, 0.92)) + po * 0.1
	var steps := 14
	var prev_b := w0 + Vector3(0, 11.0, 0)
	var prev_t := w0 + Vector3(0, 11.0, 0)
	for k in range(1, steps + 1):
		var t := float(k) / float(steps)
		var base_pt := w0.lerp(w1, t) + Vector3(0, 11.0, 0)
		var rise := 9.0 * sqrt(maxf(1.0 - pow(1.0 - t, 2.0), 0.0)) + 1.0
		var top_pt := base_pt + Vector3(0, rise, 0)
		lm.quad("Lit", prev_b, base_pt, top_pt, prev_t, po)
		if k % 3 == 0:
			lm.beam("Frame", base_pt, top_pt, 0.12, 0.14, Vector3.UP.cross(po))
		prev_b = base_pt
		prev_t = top_pt
	# Stacked glazed boxes under the arch window.
	_strip(lm, "Glass", "Frame", pa, pb, po, 0.10, 0.90, 1.0, 4.4, 3.0)
	_strip(lm, "Glass", "Frame", pa, pb, po, 0.10, 0.90, 5.4, 9.8, 3.0)
	# The curved roof of the long northern bar: a shell bowing across its depth
	# and drooping toward the prow, closed down to the wall tops.
	var nx := 21
	var nz := 7
	var rows: Array = []
	for j in nz:
		var t := float(j) / float(nz - 1)
		var z := lerpf(-12.0, 3.0, t)
		var row := PackedVector3Array()
		for i in nx:
			var x := lerpf(-50.0, 50.0, float(i) / float(nx - 1))
			var y := EAVE + 2.0 + 5.0 * (1.0 - t * t) - 4.0 * pow(maxf((x - 25.0) / 25.0, 0.0), 2.0)
			row.append(Vector3(x, y, z))
		rows.append(row)
	# The prow part of the sweep (west of x = -25) is bronze, the rest silver.
	var split := 5
	var west: Array = []
	var east: Array = []
	for r in rows:
		var rr := r as PackedVector3Array
		west.append(rr.slice(0, split + 1))
		east.append(rr.slice(split))
	lm.grid("Bronze", west, Vector3.UP)
	lm.grid("Roof", east, Vector3.UP)
	for j in [0, nz - 1]:
		var row: PackedVector3Array = rows[j]
		var o := Vector3(0, 0, -1.0 if j == 0 else 1.0)
		for i in nx - 1:
			lm.quad("Bronze" if i < split else "Silver", Vector3(row[i].x, EAVE, row[i].z),
				Vector3(row[i + 1].x, EAVE, row[i + 1].z), row[i + 1], row[i], o)
	for i in [0, nx - 1]:
		for j in nz - 1:
			var p0: Vector3 = (rows[j] as PackedVector3Array)[i]
			var p1: Vector3 = (rows[j + 1] as PackedVector3Array)[i]
			lm.quad("Bronze" if i == 0 else "Silver", Vector3(p0.x, EAVE, p0.z), Vector3(p1.x, EAVE, p1.z), p1, p0,
				Vector3(signf(p0.x), 0, 0))
	# The bronze lid over the prow, under the sweep of the roof.
	lm.poly_prism("Bronze", PackedVector2Array([Vector2(-63.3, -5.3), Vector2(-26.4, -11.8), Vector2(-21.6, 7.5),
		Vector2(-49.6, 19.8)]), EAVE, EAVE + 2.2)
	# The southern bar's raised roof and the plinth on the Mannerheimintie side.
	lm.poly_prism("Roof", PackedVector2Array([Vector2(51.0, 27.6), Vector2(-19.5, 9.8), Vector2(-19.5, 3.5),
		Vector2(51.0, 3.5)]), EAVE, EAVE + 3.5)
	FhU.blk(lm, "Plinth", 52.0, 0.0, 10.0, 6.0, 1.2, 36.0)
	lm.commit(model)
