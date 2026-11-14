class_name RockOutcrops
extends RefCounted

## Mapped bare rock that stands up out of the ground: Central Park's
## glaciated schist (Umpire Rock, Rat Rock, Vista Rock's shoulders) is
## natural=bare_rock, which the ground otherwise only paints. Each rock
## land polygon of park size (MIN_M2 to MAX_M2; mountain scree and cliffs
## stay paint, the DEM carries their relief) becomes a low faceted mound:
## its outline sunk into the ground, rings shrunk toward its centre rising
## to a rounded, uneven top, one merged mesh in the rock texture. Every
## point lifts from the ground under it, so a patch running down a slope
## to the water stays a low skin on the slope, never a cone over it.

const MIN_M2 := 15.0
const MAX_M2 := 6000.0
## Ring shrink and the share of the mound's height each ring reaches.
const RINGS := [[0.78, 0.55], [0.5, 0.86], [0.22, 1.0]]
## Mound height from the patch's size: K_H x sqrt(area), clamped.
const K_H := 0.06
const H_RANGE := Vector2(0.7, 3.2)

static func build(root: Node3D, data: LocationData, ground: GroundTruth) -> int:
	var lm := LandmarkMesh.new()
	lm.use("Rock", LandmarkMaterials.pbr("rock", "#77736c", 3.0))
	var count := 0
	for poly in data.land_polygons:
		if not (poly is Dictionary) or str((poly as Dictionary).get("class", "")) != "rock":
			continue
		var pts: Variant = (poly as Dictionary).get("points", null)
		if not (pts is PackedVector2Array) or (pts as PackedVector2Array).size() < 3:
			continue
		var ring := pts as PackedVector2Array
		var area := absf(SkyKit.winding(ring)) * 0.5
		if area < MIN_M2 or area > MAX_M2:
			continue
		var c := Vector2.ZERO
		for p in ring:
			c += p
		c /= float(ring.size())
		if not ground.is_inside(c.x, c.y):
			continue
		mound(lm, ring, c, clampf(K_H * sqrt(area), H_RANGE.x, H_RANGE.y), ground)
		count += 1
	if count > 0:
		var node := Node3D.new()
		node.name = "RockOutcrops"
		lm.commit(node)
		root.add_child(node)
	return count

## One mound over `ring` (centre `c`, top `h` metres over its ground).
static func mound(lm: LandmarkMesh, ring: PackedVector2Array, c: Vector2, h: float, ground: GroundTruth) -> void:
	var rings: Array = []
	var edge := PackedVector3Array()
	for p in ring:
		edge.append(Vector3(p.x, ground.height_at_world(p.x, p.y) - 0.3, p.y))
	rings.append(edge)
	for r in RINGS:
		var k := float(r[0])
		var row := PackedVector3Array()
		for p in ring:
			var q := c + (p - c) * k
			var lift := h * float(r[1]) * (0.75 + 0.5 * _hash(q.x, q.y))
			row.append(Vector3(q.x, ground.height_at_world(q.x, q.y) + lift, q.y))
		rings.append(row)
	var apex := Vector3(c.x, ground.height_at_world(c.x, c.y) + h, c.y)
	for j in rings.size() - 1:
		var a: PackedVector3Array = rings[j]
		var b: PackedVector3Array = rings[j + 1]
		for i in a.size():
			var i2 := (i + 1) % a.size()
			_face(lm, a[i], a[i2], b[i2])
			_face(lm, a[i], b[i2], b[i])
	var top: PackedVector3Array = rings.back()
	for i in top.size():
		_face(lm, top[i], top[(i + 1) % top.size()], apex)

## A faceted triangle of the mound's surface, its normal turned upward
## (a mound is a height field over its outline).
static func _face(lm: LandmarkMesh, a: Vector3, b: Vector3, c: Vector3) -> void:
	var n := (b - a).cross(c - a)
	if n.length_squared() < 1e-8:
		return
	n = n.normalized()
	if n.y < 0.0:
		n = -n
	lm.tri("Rock", a, b, c, n, n, n, Vector2(a.x, a.z), Vector2(b.x, b.z), Vector2(c.x, c.z))

static func _hash(x: float, z: float) -> float:
	return fposmod(sin(x * 12.9898 + z * 78.233) * 43758.5453, 1.0)
