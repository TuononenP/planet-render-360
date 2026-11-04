class_name SuomenlinnaFortress
extends RefCounted

## Mapped defensive masses, batched across all five main islands. No
## residential facade inference; occupied buildings stay in BuildingBuilder.
## Default dimensions are photographic estimates (see source notes).
const WALL_M := 4.8
const CASEMATE_M := 3.4
const BATTER_M := 0.45

static func accepts(b: Dictionary) -> bool:
	return SuomenlinnaSite.fortress(b)

static func accumulator() -> LandmarkMesh:
	var lm := LandmarkMesh.new()
	lm.use("Beacon", LandmarkMaterials.pbr("render", "#e6e4dc", 2.0))
	lm.use("BeaconMetal", LandmarkMaterials.paint("#414a3f"))
	lm.use("Stone", LandmarkMaterials.pbr("stone", "#858278", 3.5))
	lm.use("Coping", LandmarkMaterials.pbr("limestone", "#969286", 2.0))
	lm.use("Grass", StreetSnow.material(LandmarkMaterials.pbr("grass", "#82905b", 5.0)))
	lm.use("Rock", LandmarkMaterials.pbr("cliff", "#77776e", 5.0))
	lm.use("Dark", LandmarkMaterials.pbr("concrete", "#252820", 2.0, 1.0))
	lm.use("Path", StreetSnow.material(LandmarkMaterials.pbr("gravel", "#b0a590", 3.0)))
	return lm

static func height(b: Dictionary) -> float:
	if str(b.get("height_source", "")) in ["tag_height", "reference"]:
		return maxf(float(b["height"]), 0.5)
	if float(b.get("levels", 0.0)) > 0.0:
		return float(b["levels"]) * 3.0
	return CASEMATE_M if str(b.get("fortress_form", "")) == "casemate" else WALL_M

static func build_mass(lm: LandmarkMesh, mass: Dictionary, data: LocationData, ground: GroundTruth) -> bool:
	var b: Dictionary = mass["b_eff"]
	if not accepts(b):
		return false
	var ring: PackedVector2Array = mass["ring"]
	var holes: Array = []
	for raw_hole in mass.get("holes", []):
		var hole := BuildingWalls._clean_ring(raw_hole)
		if hole.size() >= 3:
			holes.append(hole)
	if str(b["fortress_form"]) == "gate":
		SuomenlinnaGate.build(lm, ring, ground, data)
		return true
	if str(b["fortress_form"]) == "beacon":
		SuomenlinnaGate.beacon(lm, ring, ground)
		return true
	var h := height(b)
	var berm := minf(1.8, h * 0.3)
	if str(b.get("height_source", "")) in ["tag_height", "reference"]:
		h = maxf(0.2, h - berm)  # OSM height includes the earth covering.
	var top_ring := _battered(ring, false)
	var top_holes: Array = []
	for hole in holes:
		top_holes.append(_battered(hole, true))
	var cap := RingGeometry.bridge_holes(top_ring, top_holes) if not top_holes.is_empty() else top_ring
	var indices := Geometry2D.triangulate_polygon(cap)
	if not top_holes.is_empty():
		indices = RingGeometry.drop_hole_triangles(cap, indices, top_holes)
	if indices.is_empty():
		# A very narrow courtyard ring can collapse under the batter inset.
		# Keep its exact mapped outline instead of falling back to apartments.
		top_ring = ring
		top_holes = holes
		cap = RingGeometry.bridge_holes(ring, holes) if not holes.is_empty() else ring
		indices = Geometry2D.triangulate_polygon(cap)
		if not holes.is_empty():
			indices = RingGeometry.drop_hole_triangles(cap, indices, holes)
	_wall_ring(lm, ring, top_ring, h, ground, false, b)
	for i in holes.size():
		_wall_ring(lm, holes[i], top_holes[i], h, ground, true, b)
	# Tessellated grass follows the real relief and rises gently inland
	# from each masonry edge, including the edges of courtyard holes.
	for i in range(0, indices.size(), 3):
		_cap(lm, cap[indices[i]], cap[indices[i + 1]], cap[indices[i + 2]],
			top_ring, top_holes, h, berm, ground)
	_paths(lm, top_ring, top_holes, h, berm, data, ground)
	return true

static func _battered(ring: PackedVector2Array, hole: bool) -> PackedVector2Array:
	var out := RoofGeometry._shift_ring(ring, BATTER_M if hole else -BATTER_M)
	# Very thin mapped walls must not invert their roof or close a court.
	if absf(RingGeometry.signed_area(out)) < 0.2 * absf(RingGeometry.signed_area(ring)) \
			or RingGeometry.signed_area(out) * RingGeometry.signed_area(ring) <= 0.0:
		return ring
	for i in out.size():
		if not hole and not Geometry2D.is_point_in_polygon(out[i], ring):
			out[i] = ring[i]
	return out

static func _crest(p: Vector2, h: float, ground: GroundTruth) -> float:
	return maxf(ground.height_at_world(p.x, p.y), ground.render_y(0.5)) + h

static func _wall_ring(lm: LandmarkMesh, ring: PackedVector2Array, top_ring: PackedVector2Array,
		h: float, ground: GroundTruth, hole: bool, b: Dictionary) -> void:
	var sign_w := 1.0 if RingGeometry.signed_area(ring) > 0.0 else -1.0
	var longest := 0
	for i in ring.size():
		if ring[i].distance_to(ring[(i + 1) % ring.size()]) > ring[longest].distance_to(ring[(longest + 1) % ring.size()]):
			longest = i
	for i in ring.size():
		var j := (i + 1) % ring.size()
		var a := ring[i]
		var z := ring[j]
		var dir := (z - a).normalized()
		var out := Vector2(dir.y, -dir.x) * sign_w * (-1.0 if hole else 1.0)
		var count := maxi(1, ceili(a.distance_to(z) / 7.0))
		for k in count:
			var t0 := float(k) / float(count)
			var t1 := float(k + 1) / float(count)
			var p := a.lerp(z, t0)
			var q := a.lerp(z, t1)
			var tp := top_ring[i].lerp(top_ring[j], t0)
			var tq := top_ring[i].lerp(top_ring[j], t1)
			var yp := _crest(tp, h, ground)
			var yq := _crest(tq, h, ground)
			var bp := _foot(p, out, ground)
			var bq := _foot(q, out, ground)
			var p0 := Vector3(p.x, bp, p.y)
			var p1 := Vector3(q.x, bq, q.y)
			var p2 := Vector3(tq.x, yq, tq.y)
			var p3 := Vector3(tp.x, yp, tp.y)
			var normal := Vector3(out.x, 0, out.y)
			var entry := not hole and i == longest and k == count / 2 \
				and str(b.get("fortress_form", "")) == "casemate" and p.distance_to(q) > 3.5
			var embrasure := not hole and str(b.get("osm_id", "")) == SuomenlinnaSite.SHORE_DEFENSE \
				and k % 2 == 0 and p.distance_to(q) > 4.0
			if entry or embrasure:
				recess(lm, p0, p1, p2, p3, normal, 1.7 if entry else 1.2,
					0.0 if entry else 1.0, 2.6 if entry else 1.1)
			else:
				lm.quad("Stone", p0, p1, p2, p3, normal)
			# Low continuous coping, without medieval crenellations.
			var rt := normal * -0.3
			lm.quad("Coping", p3, p2, p2 + rt + Vector3.UP * 0.12,
				p3 + rt + Vector3.UP * 0.12, Vector3.UP)
			# Small exposed foundation ledge blends the wall into coastal rock.
			if minf(bp, bq) < ground.render_y(3.0) and not hole:
				lm.quad("Rock", p0 - Vector3.UP * 0.5 + normal * 0.6,
					p1 - Vector3.UP * 0.5 + normal * 0.6, p1, p0)

static func _foot(p: Vector2, out: Vector2, ground: GroundTruth) -> float:
	var h := ground.height_at_world(p.x, p.y)
	for d in [1.0, 3.0]:
		var q: Vector2 = p + out * float(d)
		h = minf(h, ground.height_at_world(q.x, q.y))
	return maxf(h - 0.6, ground.render_y(-0.5))

## A real arched recess: cut the front face, build reveals and a dark
## back inside the wall. It never paints a window onto intact masonry.
static func recess(lm: LandmarkMesh, a: Vector3, b: Vector3, c: Vector3, d: Vector3,
		n: Vector3, width: float, sill: float, opening_h: float) -> void:
	var span := a.distance_to(b)
	var u := (b - a).normalized()
	var mid := (a + b) * 0.5
	var lo := mid - u * width * 0.5
	var hi := mid + u * width * 0.5
	var top := minf(c.y, d.y)
	var floor_y := maxf(a.y, b.y) + sill
	var spring := floor_y + maxf(opening_h - width * 0.5, 0.3)
	var t0 := clampf((span - width) * 0.5 / span, 0.0, 1.0)
	var t1 := 1.0 - t0
	var lt := d.lerp(c, t0)
	var ht := d.lerp(c, t1)
	lm.quad("Stone", a, lo, lt, d, n)
	lm.quad("Stone", hi, b, c, ht, n)
	var l := Vector3(lo.x, floor_y, lo.z)
	var r := Vector3(hi.x, floor_y, hi.z)
	if sill > 0.0:
		lm.quad("Stone", lo, hi, r, l, n)
	var ls := Vector3(lo.x, spring, lo.z)
	var rs := Vector3(hi.x, spring, hi.z)
	var depth := n * -1.4
	lm.quad("Stone", l, l + depth, ls + depth, ls, u)
	lm.quad("Stone", r + depth, r, rs, rs + depth, -u)
	lm.quad("Dark", l + depth, r + depth, rs + depth, ls + depth, n)
	for k in 8:
		var x0 := -PI + PI * float(k) / 8.0
		var x1 := -PI + PI * float(k + 1) / 8.0
		var p := Vector3(mid.x, spring, mid.z) + u * cos(x0) * width * 0.5 - Vector3.UP * sin(x0) * width * 0.5
		var q := Vector3(mid.x, spring, mid.z) + u * cos(x1) * width * 0.5 - Vector3.UP * sin(x1) * width * 0.5
		lm.quad("Stone", p, q, Vector3(q.x, top, q.z), Vector3(p.x, top, p.z), n)
		lm.quad("Stone", p + depth, q + depth, q, p)
		lm.tri("Dark", ls + depth, p + depth, q + depth, n, n, n,
			Vector2.ZERO, Vector2.ZERO, Vector2.ZERO)

static func _distance(p: Vector2, ring: PackedVector2Array) -> float:
	var d := INF
	for i in ring.size():
		d = minf(d, p.distance_to(Geometry2D.get_closest_point_to_segment(p, ring[i], ring[(i + 1) % ring.size()])))
	return d

static func _cap_y(p: Vector2, ring: PackedVector2Array, holes: Array,
		h: float, berm: float, ground: GroundTruth) -> float:
	var d := _distance(p, ring)
	for hole in holes:
		d = minf(d, _distance(p, hole))
	return _crest(p, h, ground) + berm * smoothstep(0.5, 7.0, d)

static func _cap(lm: LandmarkMesh, a: Vector2, b: Vector2, c: Vector2,
		ring: PackedVector2Array, holes: Array, h: float, berm: float, ground: GroundTruth, depth: int = 0) -> void:
	if depth < 7 and maxf(a.distance_to(b), maxf(b.distance_to(c), c.distance_to(a))) > 6.0:
		var ab := (a + b) * 0.5
		var bc := (b + c) * 0.5
		var ca := (c + a) * 0.5
		_cap(lm, a, ab, ca, ring, holes, h, berm, ground, depth + 1)
		_cap(lm, ab, b, bc, ring, holes, h, berm, ground, depth + 1)
		_cap(lm, ca, bc, c, ring, holes, h, berm, ground, depth + 1)
		_cap(lm, ab, bc, ca, ring, holes, h, berm, ground, depth + 1)
		return
	var pa := Vector3(a.x, _cap_y(a, ring, holes, h, berm, ground), a.y)
	var pb := Vector3(b.x, _cap_y(b, ring, holes, h, berm, ground), b.y)
	var pc := Vector3(c.x, _cap_y(c, ring, holes, h, berm, ground), c.y)
	var n := (pc - pa).cross(pb - pa).normalized()
	if n.y < 0.0:
		n = -n
	lm.tri("Grass", pa, pb, pc, n, n, n, a, b, c)

static func _paths(lm: LandmarkMesh, ring: PackedVector2Array, holes: Array,
		h: float, berm: float, data: LocationData, ground: GroundTruth) -> void:
	var box := RingGeometry.aabb(ring)
	for road in data.roads:
		if not (road is Dictionary) or bool(road.get("tunnel", false)) \
				or bool(road.get("bridge", false)) or str(road.get("class", "")) not in ["footway", "path", "steps", "pedestrian"]:
			continue
		var pts: PackedVector2Array = road.get("points", PackedVector2Array())
		if pts.size() < 2 or not box.intersects(RingGeometry.aabb(pts).grow(1.0)):
			continue
		for i in pts.size() - 1:
			var count := maxi(1, ceili(pts[i].distance_to(pts[i + 1]) / 2.0))
			var dir := (pts[i + 1] - pts[i]).normalized()
			var side := Vector2(-dir.y, dir.x) * 0.65
			for k in count:
				var p := pts[i].lerp(pts[i + 1], float(k) / float(count))
				var q := pts[i].lerp(pts[i + 1], float(k + 1) / float(count))
				var corners := PackedVector2Array([p - side, q - side, q + side, p + side])
				var inside := true
				for corner in corners:
					if not _inside(corner, ring, holes):
						inside = false
				if not inside:
					continue
				var v := PackedVector3Array()
				for corner in corners:
					v.append(Vector3(corner.x, _cap_y(corner, ring, holes, h, berm, ground) + 0.06, corner.y))
				lm.quad("Path", v[0], v[1], v[2], v[3], Vector3.UP)

static func _inside(p: Vector2, ring: PackedVector2Array, holes: Array) -> bool:
	if not Geometry2D.is_point_in_polygon(p, ring):
		return false
	for hole in holes:
		if Geometry2D.is_point_in_polygon(p, hole):
			return false
	return true

static func finish(lm: LandmarkMesh, root: Node3D, preset: int) -> void:
	var holder := Node3D.new()
	holder.name = "SuomenlinnaFortress"
	lm.commit(holder, "Fortress_")
	if holder.get_child_count() == 0:
		holder.free()
		return
	if RenderQuality.ultra_desktop(preset):
		LandmarkShader.upgrade(holder)
	holder.set_meta("fortress_triangles", lm.triangle_count())
	print("SUOMENLINNA fortress: %d triangles / %d material batches" % [lm.triangle_count(), holder.get_child_count()])
	root.add_child(holder)

## Mapped retaining walls next to defensive masses share this batch.
## Coincident footprint edges already have masonry, so they are skipped.
static func add_walls(lm: LandmarkMesh, data: LocationData, ground: GroundTruth) -> void:
	var outlines := SuomenlinnaSite.rings(data.buildings)
	for barrier in data.barriers:
		if not bool(barrier.get("fortress_wall", false)):
			continue
		var pts: PackedVector2Array = barrier["points"]
		var tagged := float(barrier.get("height_m", NAN))
		for i in pts.size() - 1:
			var count := maxi(1, ceili(pts[i].distance_to(pts[i + 1]) / 4.0))
			var dir := (pts[i + 1] - pts[i]).normalized()
			var out := Vector2(dir.y, -dir.x)
			for k in count:
				var a := pts[i].lerp(pts[i + 1], float(k) / float(count))
				var b := pts[i].lerp(pts[i + 1], float(k + 1) / float(count))
				if owns_bank(a, b, outlines):
					continue
				var mid := (a + b) * 0.5
				if not ground.is_inside(mid.x, mid.y):
					continue
				var left := ground.height_at_world(mid.x + out.x * 3.0, mid.y + out.y * 3.0)
				var right := ground.height_at_world(mid.x - out.x * 3.0, mid.y - out.y * 3.0)
				if left > right:
					out = -out
				var h := tagged if is_finite(tagged) else maxf(2.8, absf(left - right) + 0.5)
				var ya := _foot(a, out, ground)
				var yb := _foot(b, out, ground)
				var normal := Vector3(out.x, 0, out.y)
				var p := Vector3(a.x, ya, a.y)
				var q := Vector3(b.x, yb, b.y)
				var pt := p + Vector3.UP * h - normal * BATTER_M
				var qt := q + Vector3.UP * h - normal * BATTER_M
				lm.quad("Stone", p, q, qt, pt, normal)
				var back_a := a - out * 3.0
				var back_b := b - out * 3.0
				var pa := Vector3(back_a.x, ground.height_at_world(back_a.x, back_a.y) - 0.1, back_a.y)
				var pb := Vector3(back_b.x, ground.height_at_world(back_b.x, back_b.y) - 0.1, back_b.y)
				lm.quad("Grass", pt, qt, pb, pa, Vector3.UP)
				lm.quad("Stone", p, pt, pa, pa - Vector3.UP * 0.2, -Vector3(dir.x, 0, dir.y))
				lm.quad("Stone", qt, q, pb - Vector3.UP * 0.2, pb, Vector3(dir.x, 0, dir.y))

static func owns_bank(a: Vector2, b: Vector2, outlines: Array) -> bool:
	if outlines.is_empty():
		return false
	return SuomenlinnaSite.distance(a, outlines) < 1.6 and SuomenlinnaSite.distance(b, outlines) < 1.6 \
		and SuomenlinnaSite.distance((a + b) * 0.5, outlines) < 1.6
