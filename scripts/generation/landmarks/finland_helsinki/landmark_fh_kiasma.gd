extends RefCounted

## Kiasma (Steven Holl, 1998), Mannerheimintie, built on its OpenStreetMap
## outline (way 8042215, simplified to 1 m) in the model frame the registry
## yaw (67) turns onto the map; the origin is the footprint centre.
##
## From the Commons photos in visual-plan/refs/landmarks/kiasma/:
## - Two bars cross at an angle (the "chiasma"). The long straight bar is
##   clad in smooth pale zinc/aluminium panels, with longitudinal standing
##   seams, glazed bands and a curved sweep at its roof edge.
## - The west prow is a heavy curved shell in dark brown bronze-toned metal
##   whose end wall carries one huge segmental-arched window and stacked
##   glazed boxes below.
## - Between them a tilted glass wall shows the stair and ramp zig-zag.
## - On the Mannerheimintie plaza in front stands the bronze equestrian
##   statue of Marshal Mannerheim on its red granite pedestal.
## - At night the window bands, glass wall, prow arch and statue are lit.

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
		lm.box(frame, m + Vector3(0, (y0 + y1) * 0.5, 0) + o * 0.04,
			Vector3(0.1, y1 - y0, 0.12), Basis(Vector3.UP, atan2(o.x, o.z)), 0.0)
	for yy in [y0, y1, (y0 + y1) * 0.5]:
		var d := p.distance_to(q)
		lm.box(frame, (p + q) * 0.5 + Vector3(0, yy, 0) + o * 0.04,
			Vector3(d, 0.1, 0.12), Basis(Vector3.UP, atan2(o.x, o.z)), 0.0)

static func _roof_y(x: float, t: float) -> float:
	var drop := 4.0 * pow(maxf((x - 22.0) / 28.0, 0.0), 2.0)
	var prow_dip := 1.4 * pow(maxf((-x - 24.0) / 28.0, 0.0), 2.0)
	return EAVE + 2.0 + 5.0 * (1.0 - t * t) - drop - prow_dip

static func build(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Silver", LandmarkMaterials.pbr("concrete", "#B4BABD", 3.0, 0.35, 0.65))
	lm.use("Bronze", LandmarkMaterials.pbr("concrete", "#4F3B30", 3.0, 0.4, 0.6))
	lm.use("Glass", LandmarkMaterials.glass("#5A7E86"))
	lm.use("Lit", LandmarkMaterials.lit("#E8DDC0", 0.3))
	lm.use("Frame", LandmarkMaterials.paint("#3B3F42", 0.5, 0.5))
	lm.use("Roof", LandmarkMaterials.pbr("concrete", "#A9AFB2", 3.0, 0.4, 0.55))
	lm.use("Plinth", LandmarkMaterials.pbr("stone", "#8A8780", 4.0))
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#8C5950", 2.0))
	lm.use("Statue", LandmarkMaterials.paint("#3E4C42", 0.45, 0.6))
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
			# The dark bronze prow shell: its end wall and north-west flank.
			lm.quad("Bronze", a3 + o * 0.05 + Vector3(0, 0.8, 0), b3 + o * 0.05 + Vector3(0, 0.8, 0),
				b3 + o * 0.05 + Vector3(0, EAVE, 0), a3 + o * 0.05 + Vector3(0, EAVE, 0), o)
			FhP.ribs(lm, "Bronze", a3, b3, o, 0.8, EAVE, 3.2, 0.06, 0.08)
		elif a.distance_to(b) > 9.0:
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
	# Back long side (edge 6-7): ground glazing band and upper ribbon slot.
	var o6 := FhP.edge_out(foot, 6)
	_strip(lm, "Glass", "Frame", foot[6], foot[7], o6, 0.10, 0.60, 1.0, 4.6, 3.0)
	_strip(lm, "Lit", "Frame", foot[6], foot[7], o6, 0.22, 0.54, 12.2, 14.0, 3.0)
	_tilted_glass_wall(lm, foot)
	_prow_arch_window(lm, foot)
	_curved_chiasma_roof(lm)
	# Southern bar raised roof and Mannerheimintie plaza plinth.
	lm.poly_prism("Roof", PackedVector2Array([Vector2(51.0, 27.6), Vector2(-19.5, 9.8), Vector2(-19.5, 3.5),
		Vector2(51.0, 3.5)]), EAVE, EAVE + 3.5)
	FhU.blk(lm, "Plinth", 52.0, 0.0, 10.0, 6.0, 1.2, 36.0)
	_mannerheim_statue(lm, Vector3(30.0, 0.0, 33.5), -0.45)
	lm.commit(model)
	var warm := Color(1.0, 0.90, 0.72)
	var cool := Color(0.84, 0.92, 1.0)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[Vector3(16.0, 1.5, 36.0), Vector3(14.0, 12.0, 16.0), 50.0, 0.9, 60.0, cool],
		[Vector3(-34.0, 1.5, 30.0), Vector3(-36.0, 14.0, 13.0), 45.0, 1.0, 55.0, warm],
		[Vector3(-68.0, 1.5, 10.0), Vector3(-54.0, 14.0, 6.0), 48.0, 1.0, 50.0, warm],
		[Vector3(10.0, 1.5, -28.0), Vector3(0.0, 16.0, -8.0), 55.0, 0.8, 60.0, cool],
		[Vector3(36.0, 1.2, 42.0), Vector3(30.0, 7.0, 33.5), 32.0, 1.1, 30.0, warm],
	])

## Tilted glass wall at the crossing (edge 2-3) with ramp & stair zig-zag.
static func _tilted_glass_wall(lm: LandmarkMesh, foot: PackedVector2Array) -> void:
	var a2 := foot[2]
	var b2 := foot[3]
	var o2 := FhP.edge_out(foot, 2)
	var p2 := _p3(a2) + o2 * 0.06
	var q2 := _p3(b2) + o2 * 0.06
	var lean := o2 * 2.6
	lm.quad("Glass", p2 + Vector3(0, 0.8, 0), q2 + Vector3(0, 0.8, 0),
		q2 + Vector3(0, EAVE, 0) + lean, p2 + Vector3(0, EAVE, 0) + lean, o2)
	for k in 15:
		var t := float(k) / 14.0
		var m := p2.lerp(q2, t)
		lm.beam("Frame", m + Vector3(0, 0.8, 0), m + Vector3(0, EAVE, 0) + lean,
			0.09, 0.12, Vector3.UP.cross(o2))
	for k in 7:
		var y := 0.8 + float(k) * 3.0
		if y > EAVE:
			continue
		var lerp_lean := lean * ((y - 0.8) / (EAVE - 0.8))
		lm.beam("Frame", p2 + Vector3(0, y, 0) + lerp_lean, q2 + Vector3(0, y, 0) + lerp_lean, 0.09, 0.12, o2)
	# Signature diagonal ramp zig-zag visible behind the tilted glazing.
	var flights := [0.12, 0.88, 0.15, 0.85, 0.18]
	for k in flights.size() - 1:
		var y0 := 1.4 + float(k) * 4.0
		var y1 := y0 + 4.0
		var l0 := lean * ((y0 - 0.8) / (EAVE - 0.8)) - o2 * 0.25
		var l1 := lean * ((y1 - 0.8) / (EAVE - 0.8)) - o2 * 0.25
		lm.beam("Lit", p2.lerp(q2, flights[k]) + Vector3(0, y0, 0) + l0,
			p2.lerp(q2, flights[k + 1]) + Vector3(0, y1, 0) + l1, 0.35, 0.18, o2)

## Prow segmental-arched window on edge 3-4 with arched bronze surround.
static func _prow_arch_window(lm: LandmarkMesh, foot: PackedVector2Array) -> void:
	var pa := foot[3]
	var pb := foot[4]
	var po := FhP.edge_out(foot, 3)
	var w0 := _p3(pa.lerp(pb, 0.08)) + po * 0.12
	var w1 := _p3(pa.lerp(pb, 0.92)) + po * 0.12
	var steps := 20
	var prev_b := w0 + Vector3(0, 10.6, 0)
	var prev_t := prev_b
	var prev_arch := prev_b
	for k in range(1, steps + 1):
		var t := float(k) / float(steps)
		var base_pt := w0.lerp(w1, t) + Vector3(0, 10.6, 0)
		var rise := 9.6 * sqrt(maxf(1.0 - pow(1.0 - t, 2.0), 0.0)) + 0.8
		var top_pt := base_pt + Vector3(0, rise, 0)
		lm.quad("Lit", prev_b, base_pt, top_pt, prev_t, po)
		lm.beam("Bronze", prev_arch, top_pt + po * 0.08, 0.24, 0.22, po)
		if k % 3 == 0:
			lm.beam("Frame", base_pt, top_pt, 0.12, 0.14, Vector3.UP.cross(po))
		prev_b = base_pt
		prev_t = top_pt
		prev_arch = top_pt + po * 0.08
	lm.beam("Frame", w0 + Vector3(0, 15.4, 0) + po * 0.05, w1 + Vector3(0, 15.4, 0) + po * 0.05, 0.12, 0.14, po)
	_strip(lm, "Glass", "Frame", pa, pb, po, 0.10, 0.90, 1.0, 4.4, 3.0)
	_strip(lm, "Glass", "Frame", pa, pb, po, 0.10, 0.90, 5.4, 9.8, 3.0)

## Smooth curved chiasma roof shell with longitudinal standing-seam ribs.
static func _curved_chiasma_roof(lm: LandmarkMesh) -> void:
	var nx := 33
	var nz := 11
	var rows: Array = []
	for j in nz:
		var t := float(j) / float(nz - 1)
		var z := lerpf(-12.2, 3.2, t)
		var row := PackedVector3Array()
		for i in nx:
			var x := lerpf(-52.0, 52.0, float(i) / float(nx - 1))
			row.append(Vector3(x, _roof_y(x, t), z))
		rows.append(row)
	var split := 8
	var west: Array = []
	var east: Array = []
	for r in rows:
		var rr := r as PackedVector3Array
		west.append(rr.slice(0, split + 1))
		east.append(rr.slice(split))
	lm.grid("Bronze", west, Vector3.UP)
	lm.grid("Roof", east, Vector3.UP)
	# Longitudinal standing-seam ribs along the curved zinc & bronze shell.
	for j in [1, 3, 5, 7, 9]:
		var r: PackedVector3Array = rows[j]
		for i in nx - 1:
			var key := "Bronze" if i < split else "Frame"
			lm.beam(key, r[i] + Vector3(0, 0.05, 0), r[i + 1] + Vector3(0, 0.05, 0), 0.07, 0.08, Vector3.UP)
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
			lm.quad("Bronze" if i == 0 else "Silver", Vector3(p0.x, EAVE, p0.z),
				Vector3(p1.x, EAVE, p1.z), p1, p0, Vector3(signf(p0.x), 0, 0))
	lm.poly_prism("Bronze", PackedVector2Array([Vector2(-63.3, -5.3), Vector2(-26.4, -11.8),
		Vector2(-21.6, 7.5), Vector2(-49.6, 19.8)]), EAVE, EAVE + 2.2)

## Marshal Mannerheim equestrian monument (Aimo Tukiainen, 1960) on red granite.
static func _mannerheim_statue(lm: LandmarkMesh, pos: Vector3, yaw: float) -> void:
	var sub := LandmarkMesh.new()
	sub.use("Granite", null)
	sub.use("Statue", null)
	# Stepped red granite platform and tall monolithic pedestal.
	FhU.blk(sub, "Granite", 0.0, 0.0, 0.0, 4.4, 0.3, 6.0)
	FhU.blk(sub, "Granite", 0.0, 0.3, 0.0, 3.6, 0.35, 5.2)
	FhU.blk(sub, "Granite", 0.0, 0.65, 0.0, 2.2, 3.8, 3.8)
	FhU.blk(sub, "Granite", 0.0, 4.45, 0.0, 2.5, 0.3, 4.1)
	# Bronze horse (barrel, arched neck, head, tail, striding legs) and rider.
	var top := Vector3(0.0, 4.75, 0.0)
	var s := 1.15
	var barrel := PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.32, 0.12), Vector2(0.48, 0.5),
		Vector2(0.52, 1.1), Vector2(0.48, 1.7), Vector2(0.35, 2.1), Vector2(0.0, 2.3)])
	for i in barrel.size():
		barrel[i] *= s
	var body := LandmarkMesh.new()
	body.use("Statue", null)
	body.lathe("Statue", Vector3.ZERO, barrel, 14, 0.82, 1.0)
	sub.merge(body, Transform3D(Basis(Vector3.RIGHT, PI * 0.5), top + Vector3(0, 1.85, -1.15) * s))
	_limb(sub, "Statue", top + Vector3(0, 2.0, 0.85) * s, top + Vector3(0, 3.05, 1.32) * s, 0.3 * s, 0.17 * s)
	_limb(sub, "Statue", top + Vector3(0, 3.15, 1.25) * s, top + Vector3(0, 2.6, 1.85) * s, 0.17 * s, 0.1 * s)
	_limb(sub, "Statue", top + Vector3(0, 2.0, -1.1) * s, top + Vector3(0, 0.9, -1.4) * s, 0.12 * s, 0.05 * s)
	for lz in [-0.8, 0.8]:
		for lx in [-0.24, 0.24]:
			var stride := 0.35 if lz > 0.0 and lx > 0.0 else 0.0
			_limb(sub, "Statue", top + Vector3(lx, 1.6, lz) * s,
				top + Vector3(lx, 0.0, lz + stride) * s, 0.13 * s, 0.07 * s)
	LandmarkKits.statue_figure(sub, "Statue", top + Vector3(0, 1.9, -0.08) * s, 2.35 * s, false)
	lm.merge(sub, Transform3D(Basis(Vector3.UP, yaw), pos))

static func _limb(lm: LandmarkMesh, key: String, a: Vector3, b: Vector3, r0: float, r1: float) -> void:
	var axis := b - a
	if axis.length() < 0.001:
		return
	var y := axis.normalized()
	var x := y.cross(Vector3.FORWARD if absf(y.z) < 0.9 else Vector3.RIGHT).normalized()
	var piece := LandmarkMesh.new()
	piece.use(key, null)
	piece.frustum(key, Vector3.ZERO, r0, r1, axis.length(), 8)
	lm.merge(piece, Transform3D(Basis(x, y, x.cross(y)), a))
