class_name PlinthStyle
extends RefCounted

## The one look of an exposed foundation wall, wherever a slope shows
## one: a rough grey granite plinth (the Nordic stone socle) under a
## lighter dressed-stone coping course that stands proud of the wall
## above it. Hillside buildings (BuildingFoundation.plinth) and
## outline-built landmarks (LandmarkTerrain) share it. Colours are
## calibrated against each texture set's mean (LandmarkMaterials.tint),
## so the warm stone maps read as the grey named here, not brown.

const BODY_SET := "stone"
const BODY_HEX := "#7A766F"
const COPING_SET := "limestone"
const COPING_HEX := "#A39F99"
## Coping course: its depth below the plinth top, and how far it stands
## proud of the plinth face.
const COPING_DEPTH_M := 0.35
const COPING_PROUD_M := 0.18
## A plinth needs at least this much exposed wall to carry a coping;
## shallower ones stay plain granite.
const COPING_MIN_M := 0.6

static var _body: Material
static var _coping: Material

## Building-pipeline materials: the same calibrated LandmarkMaterials
## the landmark plinth uses (MaterialLibrary's own stone set reads tan
## here), built once. Building UVs run one unit per 4 m, so tile_m 0.75
## lays the stone courses every 3 m and 0.5 the coping every 2 m, as the
## landmark plinth's metre UVs with tile_m 3.0 and 2.0 do.
static func body_material() -> Material:
	if _body == null:
		_body = LandmarkMaterials.pbr(BODY_SET, BODY_HEX, 0.75)
	return _body

static func coping_material() -> Material:
	if _coping == null:
		_coping = LandmarkMaterials.pbr(COPING_SET, COPING_HEX, 0.5)
	return _coping

## Mitred outward direction at each vertex of `ring` (scaled so a face set
## `d` out along each edge's normal meets its neighbour at the corner).
## `outward` is +1 when (e.y, -e.x) points out of the ring, else -1.
static func miters(ring: PackedVector2Array, outward: float) -> PackedVector2Array:
	var count := ring.size()
	var normals := PackedVector2Array()
	for i in count:
		var e := ring[(i + 1) % count] - ring[i]
		normals.append(Vector2(e.y, -e.x).normalized() * outward)
	var out := PackedVector2Array()
	for i in count:
		var n1 := normals[i]
		var m := (normals[(i - 1 + count) % count] + n1).normalized()
		out.append(m / maxf(m.dot(n1), 0.35) if m != Vector2.ZERO else n1)
	return out

## Coping on one building edge a→b (face normal `n`, vertex mitres
## `ma`, `mb`) into BuildingWalls face arrays: the proud face from
## `top - COPING_DEPTH_M` to `top`, its upper ledge back to the wall and
## its drip underside.
static func coping(arr: Array, a: Vector2, b: Vector2, ma: Vector2, mb: Vector2,
		n: Vector2, top: float) -> void:
	var m := WorldScale.metres_to_units()
	var proud := COPING_PROUD_M * m
	var bot := top - COPING_DEPTH_M * m
	var ca := a + ma * proud
	var cb := b + mb * proud
	BuildingWalls._quad(arr, ca, cb, bot, top, n,
		Vector2(ca.distance_to(cb) / m / 4.0, COPING_DEPTH_M / 4.0))
	_flat(arr, a, b, cb, ca, top, 1.0)
	_flat(arr, a, b, cb, ca, bot, -1.0)

## Horizontal quad p0-p1-p2-p3 at height `y`, facing up (`up` > 0) or down.
static func _flat(arr: Array, p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2,
		y: float, up: float) -> void:
	var verts: PackedVector3Array = arr[0]
	var normals: PackedVector3Array = arr[1]
	var uvs: PackedVector2Array = arr[2]
	var tangents: PackedFloat32Array = arr[3]
	var indices: PackedInt32Array = arr[4]
	var k := verts.size()
	var m := WorldScale.metres_to_units()
	var t := Vector3(p1.x - p0.x, 0.0, p1.y - p0.y).normalized()
	for p in [p0, p1, p2, p3]:
		var q := p as Vector2
		verts.push_back(Vector3(q.x, y, q.y))
		normals.push_back(Vector3(0.0, up, 0.0))
		uvs.push_back(q / m / 4.0)
		if BuildingBuilder._batch == null:
			tangents.push_back(t.x); tangents.push_back(t.y); tangents.push_back(t.z); tangents.push_back(1.0)
	# Wind so the front face points along `up` (as BuildingWalls._roof_cap:
	# forward order faces up when its 2D cross is positive).
	var face_up := (p1 - p0).cross(p3 - p0) > 0.0
	if face_up == (up > 0.0):
		indices.push_back(k); indices.push_back(k + 1); indices.push_back(k + 2)
		indices.push_back(k); indices.push_back(k + 2); indices.push_back(k + 3)
	else:
		indices.push_back(k); indices.push_back(k + 2); indices.push_back(k + 1)
		indices.push_back(k); indices.push_back(k + 3); indices.push_back(k + 2)
