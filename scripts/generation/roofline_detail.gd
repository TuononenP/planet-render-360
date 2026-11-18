class_name RooflineDetail
extends RefCounted

## Roofline detail that follows the street rather than the footprint's
## centre (BuildingDetail places the rest):
## - party-wall chimney stacks: where a roof stands a gable on a shared
##   wall (PartyWalls), a broad stack rides the wall line at the ridge,
##   coped and crowned with a row of clay pots — the Paris roofscape;
## - bay dormers: on a mansard's steep lower slope (and the eave slopes of
##   gabled/hipped roofs) dormers stand on the facade's own window axes,
##   every bay on a Paris mansard, every other bay elsewhere, each with a
##   glazed front and a small hipped cap.
## Seeded by the building; merged into its BuildingDetail.Batch.

static var _mats: Dictionary = {}

static func _mat(key: String) -> Material:
	if _mats.has(key):
		return _mats[key] as Material
	var m := StandardMaterial3D.new()
	match key:
		"pot":
			m.albedo_color = Color(0.62, 0.32, 0.20)
			m.roughness = 0.85
		"render":
			m.albedo_color = Color(0.80, 0.76, 0.68)
			m.roughness = 0.95
		"glass":
			return ReliefKit.glass()
		"frame":
			m.albedo_color = Color(0.24, 0.26, 0.28)
			m.metallic = 0.2
			m.roughness = 0.65
		_:
			m.albedo_color = Color(0.5, 0.5, 0.5)
	_mats[key] = m
	return m

## Basis with x along `dir`, y up and z on the outward normal `n`
## (right-handed, so unit boxes keep their winding).
static func _basis(dir: Vector2, n: Vector2) -> Basis:
	var x := Vector3(dir.x, 0.0, dir.y)
	var z := x.cross(Vector3.UP)
	if z.dot(Vector3(n.x, 0.0, n.y)) < 0.0:
		x = -x
		z = -z
	return Basis(x, Vector3.UP, z)

## Stacks on party edges; true when any stood (BuildingDetail then skips
## its own chimneys). Works on courtyard and multi-corner blocks as well as
## boxy parcels, checking that each stack stays inside `ring` and clear of `holes`.
static func party_stacks(batch: BuildingDetail.Batch, ring: PackedVector2Array,
		c: Vector2, top: float, roof_h: float, party: PackedByteArray,
		look: Dictionary, holes: Array = []) -> bool:
	if party.size() != ring.size() or not party.has(1) or float(look.get("chimney", 0.0)) < 0.3:
		return false
	var m := WorldScale.metres_to_units()
	var masonry := BuildingDetail._mat("brick")
	if str(look.get("wall_set", "")) in ["limestone", "render", "stone"]:
		masonry = _mat("render")
	var placed := false
	for i in ring.size():
		if party[i] == 0:
			continue
		var a := ring[i]
		var e := ring[(i + 1) % ring.size()] - a
		var L := e.length()
		if L < 4.0 * m:
			continue
		var dir := e / L
		var n := PartyWalls.outward(ring, i)
		var ts: Array[float] = []
		if L >= 14.0 * m:
			ts.append(L * 0.30)
			ts.append(L * 0.70)
		else:
			# The ridge meets the party wall about where the centre projects.
			ts.append(clampf((c - a).dot(dir), L * 0.25, L * 0.75))
		var w := clampf(L * 0.24, 1.2 * m, 3.6 * m)
		var d := 0.6 * m
		var h := roof_h + 1.1 * m
		var basis := _basis(dir, n)
		for t in ts:
			var p := a + dir * t - n * (d * 0.5 + 0.04 * m)
			if not _clear_of_holes(p, ring, holes, 0.3 * m):
				continue
			_add_stack(batch, basis, p, dir, n, top, h, w, d, masonry, true)
			placed = true
	return placed

## Parisian mansard terrasson detail: rendered limestone chimney stacks with
## terracotta clay pots (mitrons) riding behind the brisis eaves on courtyard
## and multi-corner blocks, plus subtle flush skylights on wide mansards.
static func mansard_roof_details(batch: BuildingDetail.Batch, ring: PackedVector2Array,
		holes: Array, top: float, roof_h: float, shape: String, party: PackedByteArray,
		look: Dictionary, seed_v: float, area_m2: float, with_skylights: bool = false) -> bool:
	if shape != "mansard":
		return false
	var m := WorldScale.metres_to_units()
	if roof_h < 1.4 * m or float(look.get("chimney", 0.0)) < 0.4:
		return false
	var masonry := BuildingDetail._mat("brick")
	if str(look.get("wall_set", "")) in ["limestone", "render", "stone"]:
		masonry = _mat("render")
	var has_party := party.size() == ring.size() and party.has(1)
	var placed := false
	var sky_count := 0
	for i in ring.size():
		if has_party and party[i] == 1:
			continue
		var a := ring[i]
		var e := ring[(i + 1) % ring.size()] - a
		var L := e.length()
		if L < 8.0 * m:
			continue
		var dir := e / L
		var n := PartyWalls.outward(ring, i)
		var basis := _basis(dir, n)
		var count := maxi(1, int(L / (12.0 * m)))
		var step := L / float(count)
		for k in count:
			var hval := ArchitectureStyle._h(seed_v + float(i) * 0.31, 60 + k * 7)
			if hval > 0.68:
				continue
			var along := step * (float(k) + 0.3 + 0.4 * ArchitectureStyle._h(seed_v + float(i), 80 + k))
			if along < 2.2 * m or L - along < 2.2 * m:
				continue
			var inset := lerpf(2.3, 3.2, ArchitectureStyle._h(seed_v + float(i), 95 + k)) * m
			var p := a + dir * along - n * inset
			if not _clear_of_holes(p, ring, holes, 1.4 * m):
				continue
			var w := lerpf(1.6, 2.8, ArchitectureStyle._h(seed_v + float(i), 110 + k)) * m
			var d := 0.56 * m
			var h := roof_h + lerpf(0.85, 1.25, ArchitectureStyle._h(seed_v + float(i), 125 + k)) * m
			_add_stack(batch, basis, p, dir, n, top, h, w, d, masonry, false)
			placed = true
		# Subtle flush roof skylights on wide mansard terrassons.
		if with_skylights and area_m2 >= 220.0 and sky_count < 4 and L >= 10.0 * m:
			var hs := ArchitectureStyle._h(seed_v + float(i) * 0.53, 140)
			if hs < 0.55:
				var sp := a + dir * (L * (0.35 + 0.3 * hs)) - n * (3.6 * m)
				if _clear_of_holes(sp, ring, holes, 1.8 * m):
					var y_sky := top + roof_h * 0.88
					batch.add("box", BuildingDetail._xf(basis, Vector3(sp.x, y_sky, sp.y),
						Vector3(1.5 * m, 0.14 * m, 1.1 * m)), _mat("frame"))
					batch.add("box", BuildingDetail._xf(basis, Vector3(sp.x, y_sky + 0.04 * m, sp.y),
						Vector3(1.32 * m, 0.10 * m, 0.92 * m)), _mat("glass"))
					sky_count += 1
	return placed

static func _add_stack(batch: BuildingDetail.Batch, basis: Basis, p: Vector2,
		dir: Vector2, n: Vector2, top: float, h: float, w: float, d: float,
		masonry: Material, flush_party: bool) -> void:
	var m := WorldScale.metres_to_units()
	batch.add("box", BuildingDetail._xf(basis, Vector3(p.x, top + h * 0.5 - 0.2 * m, p.y),
		Vector3(w, h, d)), masonry)
	var y_cap := top + h - 0.2 * m
	# A party-wall stack's cap stops short of the lot line so an equal-height
	# neighbour's cap never z-fights it.
	var pc := p - n * (0.035 * m) if flush_party else p
	batch.add("box", BuildingDetail._xf(basis, Vector3(pc.x, y_cap + 0.06 * m, pc.y),
		Vector3(w + 0.14 * m, 0.12 * m, d + 0.14 * m)), masonry)
	var pots := clampi(int(w / (0.42 * m)), 2, 9)
	for k in pots:
		var q := p + dir * (-w * 0.5 + (float(k) + 0.5) * w / float(pots))
		batch.add("cyl", BuildingDetail._xf(Basis(), Vector3(q.x, y_cap + 0.37 * m, q.y),
			Vector3(0.24 * m, 0.5 * m, 0.24 * m)), _mat("pot"))

static func _clear_of_holes(p: Vector2, ring: PackedVector2Array, holes: Array, margin: float) -> bool:
	if not RingGeometry.point_in_ring(p, ring):
		return false
	for h in holes:
		var hr := h as PackedVector2Array
		if hr.size() < 3:
			continue
		if RingGeometry.point_in_ring(p, hr):
			return false
		if margin > 0.0:
			for j in hr.size():
				var q := Geometry2D.get_closest_point_to_segment(p, hr[j], hr[(j + 1) % hr.size()])
				if p.distance_to(q) < margin:
					return false
	return true

## Dormers on the window axes of exposed eave edges. True when this rule
## decided (dormers placed or rolled out); false leaves BuildingDetail's
## centre-placed dormers to shapes this rule does not cover.
static func bay_dormers(batch: BuildingDetail.Batch, ring: PackedVector2Array,
		top: float, roof_h: float, shape: String, party: PackedByteArray,
		gable_front: bool, look: Dictionary, roof_mat: Material, seed_v: float) -> bool:
	if not shape in ["mansard", "gambrel", "gabled", "hipped", "half-hipped"]:
		return false
	var m := WorldScale.metres_to_units()
	if roof_h < 1.4 * m or ArchitectureStyle._h(seed_v, 25) >= float(look.get("dormer", 0.0)):
		return true
	var c := RingGeometry.interior_point(ring)
	var u := RingGeometry.dominant_axis(ring)
	var has_party := party.size() == ring.size() and party.has(1) and RoofForms.boxy(ring)
	if has_party:
		u = RoofForms._party_axis(ring, party)
		if gable_front:
			u = Vector2(-u.y, u.x)
	var steep := shape in ["mansard", "gambrel"]
	var bay := maxf(float(look.get("bay_m", 3.0)), 1.6) * m
	var every := 1 if float(look.get("dormer", 0.0)) >= 0.9 else 2
	var half := maxf(RingGeometry.half_extent(ring, c, Vector2(-u.y, u.x)), 0.5 * m)
	for i in ring.size():
		if has_party and party[i] == 1:
			continue
		var a := ring[i]
		var e := ring[(i + 1) % ring.size()] - a
		var L := e.length()
		var dir := e / maxf(L, 0.0001)
		# Gabled roofs: eave edges only (along the ridge), never a gable end.
		if L < 3.0 * m or (shape != "mansard" and shape != "hipped" and absf(dir.dot(u)) < 0.8):
			continue
		var n := PartyWalls.outward(ring, i)
		var nb := maxi(1, roundi(L / bay))
		var step := L / float(nb)
		var inward := 0.35 * m if steep else 0.7 * m
		var rise := (roof_h * 0.75 / (1.5 * m)) if steep else roof_h / half
		var y0 := top + inward * minf(rise, 4.0)
		var hd := minf(1.6 * m, maxf(top + roof_h * (0.72 if steep else 0.85) - y0, 0.0))
		if hd < 0.9 * m:
			continue
		var depth := 1.3 * m
		var basis := _basis(dir, n)
		for j in nb:
			if j % every != 0 or step * (float(j) + 0.5) < 0.8 * m \
					or L - step * (float(j) + 0.5) < 0.8 * m:
				continue
			var p := a + dir * step * (float(j) + 0.5) - n * (inward + depth * 0.5)
			if not RingGeometry.point_in_ring(p, ring):
				continue
			var w := minf(1.15 * m, step * 0.7)
			batch.add("box", BuildingDetail._xf(basis, Vector3(p.x, y0 + hd * 0.5, p.y),
				Vector3(w, hd, depth)), roof_mat)
			batch.add("pyramid", BuildingDetail._xf(basis, Vector3(p.x, y0 + hd + 0.25 * m, p.y),
				Vector3(w * 1.15, 0.5 * m, depth * 1.1)), roof_mat)
			# Zinc cheeks and front (the roof material), a slim stone surround
			# and a tall pane: not the white block with a dark hole.
			var f := p + n * (depth * 0.5 + 0.03 * m)
			batch.add("box", BuildingDetail._xf(basis, Vector3(f.x, y0 + hd * 0.47, f.y),
				Vector3(w * 0.72, hd * 0.80, 0.05 * m)), BuildingDetail._mat("cream"))
			var g := f + n * 0.035 * m
			batch.add("box", BuildingDetail._xf(basis, Vector3(g.x, y0 + hd * 0.47, g.y),
				Vector3(w * 0.62, hd * 0.70, 0.04 * m)), _mat("glass"))
	return true
