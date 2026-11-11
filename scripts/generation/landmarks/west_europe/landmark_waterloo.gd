class_name LandmarkWaterloo
extends RefCounted

## London Waterloo in true metres on its mapped plan (LandmarkWaterlooData):
## the brick undercroft the station stands on, the platforms, the Portland
## stone office range on Mepham Street and Waterloo Road (1909-22, J. R.
## Scott), the canopies past the roof's end. The roofs are
## LandmarkWaterlooRoofs and the Victory Arch LandmarkWaterlooArch. The
## tracks and trains are the city's own, laid on their mapped viaducts.

const D := preload("res://scripts/generation/landmarks/west_europe/landmark_waterloo_data.gd")
## The office range: eaves over the street, storey, and how far the
## stone skin stands proud of the mass.
const EAVE_Y := 21.0
const STOREY := 4.3
const CANOPY_Y := D.PLAT_Y + 4.2
## Blind arches in the undercroft wall: pitch and width (metres).
const UNDERCROFT_PITCH := 7.5
const UNDERCROFT_W := 4.2

static func waterloo(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Stone", LandmarkMaterials.pbr("limestone", "#E2DCCD", 3.0))
	lm.use("Rustic", LandmarkMaterials.pbr("stone", "#D3CCBB", 2.5))
	lm.use("Brick", LandmarkMaterials.pbr("brick", "#5C4639", 3.0))
	lm.use("Ballast", LandmarkMaterials.pbr("gravel", "#5E5953", 3.0))
	lm.use("Paving", LandmarkMaterials.pbr("pavement", "#9C978D", 3.0))
	lm.use("Lead", LandmarkMaterials.pbr("slate", "#5C6165", 3.0))
	lm.use("Glass", LandmarkMaterials.glass("#3A4A55"))
	lm.use("Iron", LandmarkMaterials.paint("#3D4246"))
	lm.use("Blue", LandmarkMaterials.paint("#2D63A6", 0.45, 0.35))
	lm.use("Steel", LandmarkMaterials.pbr("concrete", "#B4B8BB", 3.0, 0.35, 0.6))
	lm.use("Bronze", LandmarkMaterials.pbr("concrete", "#5A4A33", 2.0, 0.4, 0.7))
	lm.use("Recess", LandmarkMaterials.paint("#1E1F21", 0.9, 0.0))
	lm.use("Clock", LandmarkMaterials.lit("#F4F0E0", 0.3))
	lm.use("Gold", LandmarkMaterials.gold())
	_undercroft(lm)
	_platforms(lm)
	_canopies(lm)
	_office_range(lm)
	LandmarkWaterlooRoofs.main_shed(lm)
	LandmarkWaterlooRoofs.concourse(lm)
	LandmarkWaterlooRoofs.international(lm)
	LandmarkWaterlooArch.victory_arch(lm)
	lm.commit(model)

## The brick block under the whole station up to the track bed, its
## walls lined with blind arches except where the office range and the
## arch stand in front.
static func _undercroft(lm: LandmarkMesh) -> void:
	lm.poly_prism("Brick", D.OUTLINE, 0.0, D.TRACK_Y, false)
	lm.poly_prism("Ballast", D.OUTLINE, D.TRACK_Y - 0.02, D.TRACK_Y)
	var n := D.OUTLINE.size()
	for i in n:
		var a := D.OUTLINE[i]
		var b := D.OUTLINE[(i + 1) % n]
		var mid := (a + b) * 0.5
		if a.distance_to(b) < UNDERCROFT_PITCH or _on_front(mid):
			continue
		var out := D.outward(a, b, D.OUTLINE)
		var dir := (b - a).normalized()
		var bays := int(a.distance_to(b) / UNDERCROFT_PITCH)
		var pitch := a.distance_to(b) / float(bays)
		for k in bays:
			var c := a + dir * pitch * (float(k) + 0.5)
			blind_arch(lm, D.v3(c + out * 0.02, 0.0), Vector3(out.x, 0, out.y), UNDERCROFT_W, D.TRACK_Y - 1.2)
		# Stone coping over the arcade.
		lm.box("Rustic", D.v3(mid + out * 0.15, D.TRACK_Y - 0.2), Vector3(a.distance_to(b), 0.4, 0.5),
			Basis(Vector3(dir.x, 0, dir.y), Vector3.UP, Vector3(out.x, 0, out.y)), 0.0)

## True near the office range's street front or the arch.
static func _on_front(p: Vector2) -> bool:
	for i in D.FRONT.size() - 1:
		if p.distance_to(Geometry2D.get_closest_point_to_segment(p, D.FRONT[i], D.FRONT[i + 1])) < 3.0:
			return true
	return Geometry2D.is_point_in_polygon(p, D.ARCH) or p.distance_to(D.ARCH[1]) < 12.0

## A dark arched recess `w` wide springing at `spring` on a wall at
## `base` (its foot, on the face) facing `normal`, with a brick archivolt.
static func blind_arch(lm: LandmarkMesh, base: Vector3, normal: Vector3, w: float, spring: float) -> void:
	var n := normal.normalized()
	var r := Vector3.UP.cross(n).normalized()
	var h := w * 0.5
	lm.quad("Recess", base - r * h, base + r * h, base + r * h + Vector3.UP * spring,
		base - r * h + Vector3.UP * spring, n)
	var c := base + Vector3.UP * spring
	for i in 10:
		var a0 := PI * float(i) / 10.0
		var a1 := PI * float(i + 1) / 10.0
		lm.tri("Recess", c, c + (r * cos(a0) + Vector3.UP * sin(a0)) * h, c + (r * cos(a1) + Vector3.UP * sin(a1)) * h,
			n, n, n, Vector2.ZERO, Vector2(cos(a0), sin(a0)), Vector2(cos(a1), sin(a1)))
	LandmarkDetail.arch(lm, "Brick", c + n * 0.03, n, w, 0.45, 0.2, 12)

## The platform islands, track bed to platform height.
static func _platforms(lm: LandmarkMesh) -> void:
	for p in D.PLATFORMS:
		lm.poly_prism("Paving", p as PackedVector2Array, D.TRACK_Y, D.PLAT_Y)

## The ridged canopies on cast-iron columns over the platforms that run
## on past the roof's end (the mapped fingers of the station outline).
static func _canopies(lm: LandmarkMesh) -> void:
	for piece in Geometry2D.intersect_polygons(D.OUTLINE, D.SOUTH):
		var poly: PackedVector2Array = piece
		if absf(_area(poly)) < 40.0:
			continue
		lm.poly_prism("Lead", poly, CANOPY_Y, CANOPY_Y + 0.3)
		# Its spine: between the two outline points farthest apart.
		var a := poly[0]
		var b := poly[1]
		for i in poly.size():
			for j in range(i + 1, poly.size()):
				if poly[i].distance_to(poly[j]) > a.distance_to(b):
					a = poly[i]
					b = poly[j]
		var c := Vector2.ZERO
		for p in poly:
			c += p
		c /= float(poly.size())
		var dir := (b - a).normalized()
		var half := a.distance_to(b) * 0.5 - 3.0
		var lo := c - dir * half
		var hi := c + dir * half
		lm.gable("Glass", D.v3((lo + hi) * 0.5, CANOPY_Y + 0.3), 2.4, half * 2.0, 0.9,
			Basis(Vector3.UP, atan2(dir.x, dir.y)), 0.1)
		var posts := maxi(int(half * 2.0 / 12.0), 1)
		for k in posts + 1:
			var p := lo.lerp(hi, float(k) / float(posts))
			if Geometry2D.is_point_in_polygon(p, poly):
				lm.lathe("Iron", D.v3(p, D.PLAT_Y), PackedVector2Array([Vector2(0.22, 0.0), Vector2(0.14, 0.4),
					Vector2(0.12, CANOPY_Y - D.PLAT_Y - 0.8), Vector2(0.35, CANOPY_Y - D.PLAT_Y)]), 8)

static func _area(poly: PackedVector2Array) -> float:
	var s := 0.0
	for i in poly.size():
		var p := poly[i]
		var q := poly[(i + 1) % poly.size()]
		s += p.x * q.y - q.x * p.y
	return s * 0.5

## The office range: a Portland stone mass along the street front, a
## rusticated base storey up to the concourse, three storeys of windows
## between pilasters, a cornice and parapet; doorways under arches in
## the base.
static func _office_range(lm: LandmarkMesh) -> void:
	var plan := PackedVector2Array(D.FRONT)
	for i in range(D.INNER.size() - 1, -1, -1):
		plan.append(D.INNER[i])
	lm.poly_prism("Stone", plan, 0.0, EAVE_Y)
	lm.poly_prism("Lead", plan, EAVE_Y, EAVE_Y + 0.2)
	for i in D.FRONT.size() - 1:
		var a := D.FRONT[i]
		var b := D.FRONT[i + 1]
		var w := a.distance_to(b)
		if w < 4.0:
			continue
		var o := D.outward(a, b, plan)
		var dir := (b - a).normalized()
		var out := Vector3(o.x, 0, o.y)
		var right := Vector3(dir.x, 0, dir.y)
		var basis := Basis(right, Vector3.UP, out)
		var mid := (a + b) * 0.5
		# Rusticated base: courses standing proud in turn.
		for k in int(D.PLAT_Y / 0.75):
			var depth := 0.45 if k % 2 == 0 else 0.35
			lm.box("Rustic", D.v3(mid, 0.375 + 0.75 * float(k)) + out * depth * 0.5, Vector3(w, 0.7, depth), basis, 0.0)
		var doors := int(w / 9.0)
		for k in doors:
			var c := a + dir * (w * (float(k) + 0.5) / float(doors))
			blind_arch(lm, D.v3(c, 0.0) + out * 0.47, out, 3.0, 3.2)
		lm.box("Stone", D.v3(mid, D.PLAT_Y + 0.25) + out * 0.35, Vector3(w + 0.4, 0.5, 0.7), basis)
		# Upper storeys.
		var cols := maxi(int(w / 3.6), 1)
		var h := EAVE_Y - 1.4 - D.PLAT_Y
		LandmarkDetail.pierced_face(lm, "Stone", "Glass", D.v3(a, D.PLAT_Y + 0.5), right, out, w, h - 0.5,
			cols, 3, Vector2(1.5, 2.6), 1.1, STOREY, 0.3)
		var pitch := w / float(cols)
		for k in range(0, cols + 1, 3):
			lm.box("Stone", D.v3(a + dir * pitch * float(k), D.PLAT_Y + 0.5 + h * 0.5) + out * 0.45,
				Vector3(0.9, h, 0.3), basis)
		LandmarkDetail.cornice(lm, "Stone", D.v3(a, EAVE_Y - 1.4) + out * 0.3, D.v3(b, EAVE_Y - 1.4) + out * 0.3,
			out, 1.0, false)
		# Parapet with piers.
		lm.box("Stone", D.v3(mid, EAVE_Y + 0.6) + out * 0.1, Vector3(w, 1.2, 0.5), basis)
		for k in range(0, cols + 1, 3):
			lm.box("Stone", D.v3(a + dir * pitch * float(k), EAVE_Y + 0.8) + out * 0.1, Vector3(0.8, 1.6, 0.7), basis)
	# Chimney stacks along the roof.
	for i in range(1, D.INNER.size() - 1):
		var p := (D.FRONT[i] + D.INNER[i]) * 0.5
		lm.box("Brick", D.v3(p, EAVE_Y + 1.6), Vector3(1.6, 3.2, 3.0))
		lm.box("Stone", D.v3(p, EAVE_Y + 3.3), Vector3(1.9, 0.3, 3.3))
