class_name SuomenlinnaGate
extends RefCounted

## King's Gate at the mapped entrance on Kustaanmiekka. The measured
## map footprint supplies the waterfront terrace; facade dimensions are
## photographic estimates from the user's third reference.
static func build(lm: LandmarkMesh, ring: PackedVector2Array, ground: GroundTruth,
		data: LocationData) -> void:
	var p := WorldScale.xz_from_latlon(60.1395806, 24.9899411, data.latitude, data.longitude)
	# Axis follows the mapped passage (way 117478902).
	var n := Vector3(-0.18, 0, 0.984).normalized()
	var u := Vector3(n.z, 0, -n.x)
	var base := maxf(ground.render_y(1.8), ground.height_at_world(p.x, p.y))
	var origin := Vector3(p.x, base, p.y)
	var indices := Geometry2D.triangulate_polygon(ring)
	for i in range(0, indices.size(), 3):
		var a := ring[indices[i]]
		var b := ring[indices[i + 1]]
		var c := ring[indices[i + 2]]
		lm.tri("Path", Vector3(a.x, base, a.y), Vector3(b.x, base, b.y), Vector3(c.x, base, c.y),
			Vector3.UP, Vector3.UP, Vector3.UP, a, b, c)
	for i in ring.size():
		var a := ring[i]
		var b := ring[(i + 1) % ring.size()]
		var dir := (b - a).normalized()
		var out := Vector3(dir.y, 0, -dir.x) * (1.0 if RingGeometry.signed_area(ring) > 0.0 else -1.0)
		lm.quad("Stone", Vector3(a.x, ground.render_y(-0.4), a.y),
			Vector3(b.x, ground.render_y(-0.4), b.y), Vector3(b.x, base, b.y), Vector3(a.x, base, a.y), out)
	var a := origin - u * 5.5
	var b := origin + u * 5.5
	SuomenlinnaFortress.recess(lm, a, b, b + Vector3.UP * 6.8, a + Vector3.UP * 6.8,
		n, 3.0, 0.0, 4.5)
	var basis := Basis(u, Vector3.UP, n)
	for side in [-1.0, 1.0]:
		var wing: Vector3 = origin + u * float(side) * 8.0 - n * 1.5
		lm.box("Stone", wing + Vector3.UP * 2.8, Vector3(5.0, 5.6, 3.0), basis)
		lm.box("Coping", wing + Vector3.UP * 5.65, Vector3(5.2, 0.25, 3.2), basis)
		# Classical granite pilasters either side of the recessed arch.
		lm.box("Coping", origin + u * side * 2.2 + n * 0.2 + Vector3.UP * 2.7,
			Vector3(0.75, 5.4, 0.5), basis)
	lm.box("Coping", origin + Vector3.UP * 6.9 - n * 0.7, Vector3(11.6, 0.4, 2.4), basis)
	lm.box("Stone", origin + Vector3.UP * 6.2 - n * 1.0, Vector3(11.0, 1.0, 2.0), basis)
	# Curved low waterfront steps. Each tread is an annular sector, not
	# a filled disc that would cover the recessed entrance behind it.
	for tier in 3:
		var r0 := 8.0 + float(tier) * 0.65
		var r1 := r0 + 0.65
		var y := base - float(tier + 1) * 0.18
		for k in 24:
			var t0 := PI * float(k) / 24.0
			var t1 := PI * float(k + 1) / 24.0
			var d0 := u * cos(t0) + n * sin(t0)
			var d1 := u * cos(t1) + n * sin(t1)
			var c0 := origin + d0 * r0
			var c1 := origin + d1 * r0
			var c2 := origin + d1 * r1
			var c3 := origin + d0 * r1
			c0.y = y
			c1.y = y
			c2.y = y
			c3.y = y
			lm.quad("Coping", c0, c1, c2, c3, Vector3.UP)
			lm.quad("Stone", c3 - Vector3.UP * 0.18, c2 - Vector3.UP * 0.18, c2, c3)

## Small white navigation beacon visible at the southern shore in the
## supplied photos, on its own mapped 3.8 m footprint.
static func beacon(lm: LandmarkMesh, ring: PackedVector2Array, ground: GroundTruth) -> void:
	var p := RingGeometry.centroid(ring)
	var y := maxf(ground.height_at_world(p.x, p.y), ground.render_y(0.8))
	var origin := Vector3(p.x, y, p.y)
	lm.frustum("Stone", origin, 1.9, 1.8, 0.45, 8)
	lm.frustum("Beacon", origin + Vector3.UP * 0.45, 1.45, 0.85, 2.5, 12)
	lm.frustum("Beacon", origin + Vector3.UP * 2.95, 1.0, 1.0, 0.2, 12)
	lm.frustum("BeaconMetal", origin + Vector3.UP * 3.15, 0.6, 0.6, 0.65, 10)
	lm.frustum("BeaconMetal", origin + Vector3.UP * 3.8, 0.85, 0.0, 0.4, 10)
