class_name StatueBuilder
extends RefCounted

## A mapped statue (OsmTags.statue_kind: historic=statue, memorial=statue,
## or tourism=artwork with artwork_type=statue) drawn as what it is: a
## stone pedestal on the footprint with a bronze figure on top, a rider
## when statue=equestrian, never a windowed building box. Paris maps
## Henri IV on the Pont Neuf as building=yes, which stood a little house
## with a window inside the statue's railings.
##
## The footprint is the pedestal: its longest edge orients it, and the
## figure faces along it (the `direction` tag when mapped, else the
## eastward end). The pedestal's height scales with its width; a mapped
## `height` is the whole statue's.

const STONE_HEX := "#B9B2A3"
const BRONZE_HEX := "#4C5A4E"
## Pedestal height per metre of the footprint's short side, and bounds (m).
const PEDESTAL_K := 1.6
const PEDESTAL_MIN_M := 1.2
const PEDESTAL_MAX_M := 4.5
## A footprint larger than this (m²) is a monument building, not a pedestal.
const MAX_AREA_M2 := 200.0
## Horse length (tail to muzzle) at scale 1, and its share of the pedestal.
const HORSE_LEN_M := 3.3
const HORSE_FILL := 0.75

static func accepts(b: Dictionary) -> bool:
	if str(b.get("statue", "")) == "" or bool(b.get("mapped_landmark", false)):
		return false
	var ring: PackedVector2Array = b.get("footprint", PackedVector2Array())
	var m := WorldScale.metres_to_units()
	return ring.size() < 3 or absf(RingGeometry.signed_area(ring)) <= MAX_AREA_M2 * m * m

## {centre, heading (unit Vector2 the figure faces), length, width} in
## world units: the footprint measured along its longest edge.
static func frame(b: Dictionary) -> Dictionary:
	var m := WorldScale.metres_to_units()
	var centre := Vector2(float(b.get("x", 0.0)), float(b.get("z", 0.0)))
	var ring: PackedVector2Array = b.get("footprint", PackedVector2Array())
	var axis := Vector2.RIGHT
	var best := 0.0
	for i in ring.size() - 1:
		var e := ring[i + 1] - ring[i]
		if e.length() > best:
			best = e.length()
			axis = e / best
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for p in ring:
		var q := Vector2((p - centre).dot(axis), (p - centre).dot(axis.orthogonal()))
		lo = lo.min(q)
		hi = hi.max(q)
	var size := hi - lo if ring.size() >= 3 \
		else Vector2(float(b.get("size_x", 3.0)), float(b.get("size_z", 2.0)))
	if ring.size() >= 3:
		centre += axis * (lo.x + hi.x) * 0.5 + axis.orthogonal() * (lo.y + hi.y) * 0.5
	if axis.x < 0.0 or (axis.x == 0.0 and axis.y < 0.0):
		axis = -axis
	var dir := float(b.get("statue_dir", NAN))
	if not is_nan(dir):
		# Compass degrees: 0 north (-z), 90 east (+x).
		var want := Vector2(sin(deg_to_rad(dir)), -cos(deg_to_rad(dir)))
		axis = axis if axis.dot(want) >= 0.0 else -axis
		if absf(axis.dot(want)) < 0.7:
			axis = axis.orthogonal() if axis.orthogonal().dot(want) >= 0.0 else -axis.orthogonal()
			size = Vector2(size.y, size.x)
	return {"centre": centre, "heading": axis,
		"length": maxf(size.x, 0.8 * m), "width": maxf(size.y, 0.6 * m)}

## The statue as a LandmarkMesh, its pedestal's foot at height `y`.
static func mesh(b: Dictionary, y: float) -> LandmarkMesh:
	var m := WorldScale.metres_to_units()
	var f := frame(b)
	var l: float = f["length"]
	var w: float = f["width"]
	var rider := str(b.get("statue", "")) == "equestrian"
	var s := clampf(l * HORSE_FILL / (HORSE_LEN_M * m), 0.6, 2.0) * m
	var fig_h := 4.2 * s if rider else clampf(w * 1.3, 1.8 * m, 6.0 * m)
	var ph := clampf(w * PEDESTAL_K, PEDESTAL_MIN_M * m, PEDESTAL_MAX_M * m)
	if str(b.get("height_source", "")) == "tag_height":
		ph = maxf(float(b.get("height", 0.0)) * m - fig_h, PEDESTAL_MIN_M * m)
	# Built facing +z about the origin, then turned onto the heading.
	var part := LandmarkMesh.new()
	part.use("Stone", LandmarkMaterials.pbr("limestone", STONE_HEX, 3.0))
	part.use("Bronze", LandmarkMaterials.paint(BRONZE_HEX, 0.45, 0.5))
	var step := 0.3 * m
	part.box("Stone", Vector3(0, step * 0.5, 0), Vector3(w + step * 1.4, step, l + step * 1.4))
	part.box("Stone", Vector3(0, step + (ph - 2.0 * step) * 0.5, 0), Vector3(w, ph - 2.0 * step, l))
	part.box("Stone", Vector3(0, ph - step * 0.5, 0), Vector3(w + step, step, l + step))
	var top := Vector3(0, ph, 0)
	if rider:
		_horse(part, top, s)
		LandmarkKits.statue_figure(part, "Bronze", top + Vector3(0, 1.9, -0.1) * s, 2.3 * s)
	else:
		LandmarkKits.statue_figure(part, "Bronze", top, fig_h)
	var head: Vector2 = f["heading"]
	var c: Vector2 = f["centre"]
	var basis := Basis(Vector3.UP, atan2(head.x, head.y))
	var lm := LandmarkMesh.new()
	lm.merge(part, Transform3D(basis, Vector3(c.x, y, c.y)))
	return lm

## A bronze horse standing/striding along +z on `base`, scaled by `s`,
## using smooth lofted equine anatomy via SculptureKit.
static func _horse(lm: LandmarkMesh, base: Vector3, s: float) -> void:
	SculptureKit.rearing_horse(lm, "Bronze", base, s * 1.15, 0.0, 0.05)

## A tapered round member from `a` (radius r0) to `b` (radius r1).
static func _limb(lm: LandmarkMesh, a: Vector3, b: Vector3, r0: float, r1: float) -> void:
	var axis := b - a
	if axis.length() < 0.001:
		return
	var y := axis.normalized()
	var x := y.cross(Vector3.FORWARD if absf(y.z) < 0.9 else Vector3.RIGHT).normalized()
	var piece := LandmarkMesh.new()
	piece.use("Bronze", null)  # lm carries the material
	piece.frustum("Bronze", Vector3.ZERO, r0, r1, axis.length(), 8)
	lm.merge(piece, Transform3D(Basis(x, y, x.cross(y)), a))

## Builds `b` under `root` when it is a statue; false otherwise.
static func build(root: Node3D, b: Dictionary, ground: GroundTruth, sea_y: float = -INF) -> bool:
	if not accepts(b):
		return false
	var f := frame(b)
	var ring: PackedVector2Array = b.get("footprint", PackedVector2Array())
	if ring.size() < 3:
		ring = BuildingWalls._rect_ring(f["centre"], Vector2(f["width"], f["length"]), 0.0)
	var footing := BuildingFoundation.sample(ground, ring, f["centre"], sea_y)
	# Sunk as walls are, so a slope leaves no gap under the plinth.
	var foot := float(footing["low"]) - BuildingFoundation.SINK_M * WorldScale.metres_to_units()
	for part in mesh(b, foot).commit(root, "Statue_"):
		part.set_meta("mapped_statue", true)
		part.set_meta("osm_id", str(b.get("osm_id", "")))
	return true
