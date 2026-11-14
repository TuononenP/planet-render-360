class_name LandmarkFhKallio
extends RefCounted

## Kallio, true metres, extruded from OpenStreetMap outlines
## (LandmarkFhInnerFootprints): Karl Hård af Segerstad's late-Jugend
## Kallio Library (1912), red brick with light stone quoins under a red
## tiled mansard; Kaija and Heikki Siren's Kallio Office Building (1965),
## an 11-storey white north–south slab among lower east–west wings; and
## Linnanmäki on the hill above, the 1951 Vuoristorata (a 24 m timber
## side-friction coaster) along its mapped centreline with the Kingi
## (75 m), Raketti (60 m) and Panoraama (53 m) towers. Sources and
## estimates: docs/helsinki-landmark-sources.md.

const U = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")
const F = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_mall_footprints.gd")
const W = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_west_footprints.gd")
const I = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_inner_footprints.gd")
const FhP = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_parts.gd")

const LIBRARY_M := 19.0
const VIRASTOTALO_M := 40.0
const LINNANMAKI_M := 75.0
const COASTER_M := 24.0
## Vuoristorata's track height (m) at fractions of its mapped centreline:
## the station, the lift to 24 m, then falling hills (estimated profile).
const COASTER_PROFILE := [[0.0, 7.0], [0.1, 8.0], [0.3, 24.0], [0.42, 11.0], [0.55, 18.0],
	[0.68, 9.0], [0.8, 14.0], [0.92, 8.0], [1.0, 7.0]]

static func library(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#8A4232", 3.0))
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#DCCFB4", 2.0))
	lm.use("Granite", LandmarkMaterials.pbr("stone", "#706B64", 3.0))
	lm.use("Tile", LandmarkMaterials.pbr("terracotta", "#B4502F", 2.0))
	lm.use("Glass", LandmarkMaterials.glass("#2E383C"))
	var poly := I.outline("kallio_library")
	var eave := 12.0
	lm.poly_prism("Granite", F.offset(poly, 0.15), 0.0, 1.3)
	lm.poly_prism("Brick", poly, 1.3, eave)
	lm.poly_prism("Stone", F.offset(poly, 0.1), 5.5, 5.8, false)
	lm.poly_prism("Stone", F.offset(poly, 0.25), eave - 0.4, eave, false)
	W.edge_windows(lm, "Glass", poly, 1.8, 3, 3.6, 2.6, 1.3, 2.2, "Stone")
	_quoins(lm, poly, 1.3, eave - 0.4)
	# Red tiled mansard: a steep lower skirt, a low upper hip, chimneys.
	var cen := FhP.centre(poly)
	var skirt := F.offset(poly, 0.3)
	FhP.slope_roof(lm, "Tile", skirt, cen, 0.8, eave, eave + 3.4)
	var upper := PackedVector2Array()
	for p in skirt:
		upper.append(cen + (p - cen) * 0.8)
	FhP.slope_roof(lm, "Tile", upper, cen, 0.6, eave + 3.4, eave + 5.0)
	for s: float in [-1.0, 1.0]:
		U.blk(lm, "Brick", cen.x + 4.5 * s, eave + 2.5, cen.y, 1.2, LIBRARY_M - eave - 2.5, 1.2)
	lm.commit(model, "Kallio_library_")

## Light stone quoins at every corner between two edges at least 3 m long.
static func _quoins(lm: LandmarkMesh, poly: PackedVector2Array, y0: float, y1: float) -> void:
	var n := poly.size()
	for i in n:
		var p := poly[i]
		var prev := poly[(i + n - 1) % n]
		var next := poly[(i + 1) % n]
		if p.distance_to(prev) < 3.0 or p.distance_to(next) < 3.0:
			continue
		var along := (next - p).normalized()
		lm.box("Stone", Vector3(p.x, (y0 + y1) * 0.5, p.y), Vector3(0.9, y1 - y0, 0.9),
			Basis(Vector3.UP, atan2(-along.y, along.x)), 0.0)

## The 11-storey slab (its long sides run north–south) rising through
## four-storey wings, white tile with dark window strips on every floor.
static func virastotalo(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("White", LandmarkMaterials.pbr("concrete", "#ECEAE3", 2.5))
	lm.use("Glass", LandmarkMaterials.glass("#2C3A42"))
	lm.use("Metal", LandmarkMaterials.paint("#5C6266", 0.5))
	lm.use("Roof", LandmarkMaterials.paint("#55524F", 0.8))
	var poly := I.outline("kallio_virastotalo")
	var wing := 14.4
	lm.poly_prism("White", poly, 0.0, wing)
	W.ribbons(lm, "Glass", poly, 1.2, 1.5, 4, 3.4)
	lm.poly_prism("White", F.offset(poly, 0.15), wing - 0.4, wing, false)
	lm.poly_prism("Roof", F.offset(poly, -0.2), wing, wing + 0.1)
	var tower := PackedVector2Array([Vector2(-1.9, -31.7), Vector2(18.7, -32.5), Vector2(22.0, 45.8), Vector2(1.2, 46.6)])
	var top := 37.4
	lm.poly_prism("White", tower, 0.0, top)
	W.ribbons(lm, "Glass", tower, 1.2, 1.6, 11, 3.3)
	W.ribs(lm, "Metal", tower, 1.0, top - 1.0, 1.6, 0.1, 0.12)
	lm.poly_prism("Roof", F.offset(tower, -0.2), top, top + 0.2)
	lm.poly_prism("White", F.offset(tower, -2.5), top, VIRASTOTALO_M)
	lm.commit(model, "Kallio_virastotalo_")

## Linnanmäki's skyline: the timber coaster and the three tall rides.
static func linnanmaki(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Timber", LandmarkMaterials.pbr("wood", "#6B4A32", 2.0))
	lm.use("Steel", LandmarkMaterials.paint("#D6DADB", 0.45, 0.5))
	lm.use("Red", LandmarkMaterials.paint("#C23B2E", 0.5, 0.2))
	lm.use("Glass", LandmarkMaterials.glass("#3A4C55"))
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#A9A59D", 3.0))
	_coaster(lm)
	# Kingi: the 75 m drop tower, its seat ring waiting at the base.
	var k := I.KINGI
	lm.poly_prism("Concrete", I.circle(k, 3.0), 0.0, 0.6)
	lm.frustum("Steel", Vector3(k.x, 0.6, k.y), 1.9, 1.6, LINNANMAKI_M - 3.6, 16)
	lm.frustum("Red", Vector3(k.x, LINNANMAKI_M - 3.0, k.y), 2.4, 2.4, 3.0, 16)
	lm.frustum("Red", Vector3(k.x, 1.4, k.y), 4.0, 4.0, 1.6, 20)
	# Raketti: a slim tower under a rocket's nose cone.
	var r := I.RAKETTI
	lm.poly_prism("Concrete", I.circle(r, 2.6), 0.0, 0.6)
	lm.frustum("Steel", Vector3(r.x, 0.6, r.y), 1.6, 1.4, 53.4, 14)
	lm.frustum("Red", Vector3(r.x, 54.0, r.y), 2.2, 0.0, 6.0, 14)
	lm.frustum("Red", Vector3(r.x, 1.4, r.y), 3.4, 3.4, 1.4, 18)
	# Panoraama: the observation gondola ring on its column.
	var p := I.PANORAAMA
	lm.poly_prism("Concrete", I.circle(p, 2.4), 0.0, 0.6)
	lm.frustum("Steel", Vector3(p.x, 0.6, p.y), 1.4, 1.2, 49.4, 14)
	lm.frustum("Steel", Vector3(p.x, 50.0, p.y), 1.8, 1.8, 3.0, 14)
	lm.frustum("Red", Vector3(p.x, 18.0, p.y), 5.0, 5.0, 0.6, 24)
	lm.frustum("Glass", Vector3(p.x, 18.6, p.y), 4.9, 4.9, 2.0, 24)
	lm.frustum("Red", Vector3(p.x, 20.6, p.y), 5.0, 5.0, 0.5, 24)
	lm.commit(model, "Linnanmaki_")

## Bents of timber posts every few metres along the centreline, X-braced
## side walls up to the track, cross ties, and two track decks on top.
static func _coaster(lm: LandmarkMesh) -> void:
	var line := I.coaster_line()
	var length := 0.0
	for i in line.size() - 1:
		length += line[i].distance_to(line[i + 1])
	var steps := int(length / 4.5)
	var half := I.COASTER_HALF_M - 1.0
	var prev_l := Vector3.ZERO
	var prev_r := Vector3.ZERO
	var prev_h := 0.0
	for s in steps + 1:
		var t := float(s) / float(steps)
		var at := _along(line, t * length)
		var c: Vector2 = at[0]
		var side: Vector2 = at[1]
		var h := _coaster_height(t)
		# Feet a little above the ground so member ends do not dip below it.
		var l := Vector3(c.x + side.x * half, 0.3, c.y + side.y * half)
		var r := Vector3(c.x - side.x * half, 0.3, c.y - side.y * half)
		lm.beam("Timber", l, l + Vector3.UP * h, 0.4)
		lm.beam("Timber", r, r + Vector3.UP * h, 0.4)
		var y := 4.5
		while y < h:
			lm.beam("Timber", l + Vector3.UP * y, r + Vector3.UP * y, 0.25)
			y += 4.5
		if s > 0:
			var cells := maxi(1, int(maxf(h, prev_h) / 4.5))
			lm.lattice_panel("Timber", prev_l, l, prev_l + Vector3.UP * prev_h, l + Vector3.UP * h, 0.22, cells)
			lm.lattice_panel("Timber", prev_r, r, prev_r + Vector3.UP * prev_h, r + Vector3.UP * h, 0.22, cells)
			for k: float in [-0.45, 0.45]:
				var a := prev_l.lerp(prev_r, 0.5 + k) + Vector3.UP * (prev_h + 0.3)
				var b := l.lerp(r, 0.5 + k) + Vector3.UP * (h + 0.3)
				lm.beam("Timber", a, b, 2.0, 0.35)
		prev_l = l
		prev_r = r
		prev_h = h

## Point and left-hand normal `dist` metres along the polyline.
static func _along(line: PackedVector2Array, dist: float) -> Array:
	var left := dist
	for i in line.size() - 1:
		var a := line[i]
		var b := line[i + 1]
		var seg := a.distance_to(b)
		if left <= seg or i == line.size() - 2:
			var d := (b - a).normalized()
			return [a + d * minf(left, seg), Vector2(-d.y, d.x)]
		left -= seg
	return [line[0], Vector2.UP]

static func _coaster_height(t: float) -> float:
	for i in COASTER_PROFILE.size() - 1:
		var a: Array = COASTER_PROFILE[i]
		var b: Array = COASTER_PROFILE[i + 1]
		if t <= float(b[0]):
			var k := smoothstep(float(a[0]), float(b[0]), t)
			return lerpf(float(a[1]), float(b[1]), k)
	return float(COASTER_PROFILE[-1][1])
