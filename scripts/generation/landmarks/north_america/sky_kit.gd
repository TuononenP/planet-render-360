class_name SkyKit
extends RefCounted

## Shared kit for hand-built skyscrapers: walls as single quads with real
## bay-and-storey UVs on the tower facade materials, instead of a box per
## spandrel, so a 300 m tower costs a few thousand triangles and shares the
## generated towers' glass, weathering and night lights. Plan coordinates
## are metres in the model's frame (x, z), y up.

## Facade finishes: wall set, tiled pattern and the glazing or stone colour.
const FINISHES := {
	"limestone_pier": ["limestone", "pier", "#d2c8b4"],
	"buff_pier": ["brick", "pier", "#b89a72"],
	"terracotta_pier": ["limestone", "pier", "#e2dccb"],
	"granite_strip": ["stone", "strip", "#7c7068"],
	"white_panel": ["concrete", "panel", "#dcdad4"],
	"steel_panel": ["concrete", "panel", "#a4a8ac"],
	"brick_punched": ["brick", "punched", "#a8654c"],
	"white_brick_pier": ["brick", "pier", "#cdc8ba"],
}

static var _mutex := Mutex.new()
static var _mats := {}

var lm: LandmarkMesh
var _tile := {}

func _init(mesh: LandmarkMesh) -> void:
	lm = mesh

## A facade material for finish `id`: a glazing type of FacadeCurtainKit or a
## FINISHES row. Composed here, not through FacadeMaterials, whose caches
## belong to the building thread; landmarks build beside it.
static func material(id: String, bay_m: float, floor_m: float) -> StandardMaterial3D:
	var key := "%s|%.2f|%.2f" % [id, bay_m, floor_m]
	_mutex.lock()
	if _mats.has(key):
		var hit := _mats[key] as StandardMaterial3D
		_mutex.unlock()
		return hit
	var glass := FacadeCurtainKit.has(id)
	var set_name := "glass" if glass else str((FINISHES[id] as Array)[0])
	var pattern := "curtain" if glass else str((FINISHES[id] as Array)[1])
	var look := {"bay_m": bay_m, "floor_h": floor_m, "curtain": id if glass else "",
		"frame": Color(0.16, 0.16, 0.16), "window": "wide", "variant": 0}
	var texs := FacadeComposer.compose_tile(set_name, pattern, 1, look, Callable(MaterialLibrary, "_set_image"))
	var tint := Color.WHITE
	if not glass:
		tint = FacadeMaterials._calib(set_name, ArchitectureStyle._lin(str((FINISHES[id] as Array)[2])))
	var m := FacadeTextures._material_from(texs, set_name, 1, tint)
	m.set_meta("facade_pattern", pattern)
	m.set_meta("facade_rows", 0)
	m.set_meta("facade_floor_m", floor_m)
	m.set_meta("fc_uv", Vector3(bay_m, float(FacadeComposer.BAYS), 1.0))
	_mats[key] = m
	_mutex.unlock()
	return m

## Registers surface `key` as finish `id` at this bay and storey.
func wall(key: String, id: String, bay_m: float, floor_m: float) -> void:
	lm.use(key, material(id, bay_m, floor_m))
	_tile[key] = Vector2(bay_m * float(FacadeComposer.BAYS), floor_m)

## One wall quad a..b from y0 to y1 facing `normal`. `bays` > 0 pins the tile
## to that many bays, so windows land between geometry at a known pitch.
func face(key: String, a: Vector2, b: Vector2, y0: float, y1: float, normal: Vector3, bays: int = 0) -> void:
	var t: Vector2 = _tile[key]
	var u := float(bays) / float(FacadeComposer.BAYS) if bays > 0 else maxf(1.0, roundf(a.distance_to(b) / t.x * 4.0)) / 4.0
	var v := maxf(1.0, roundf((y1 - y0) / t.y))
	var p0 := Vector3(a.x, y0, a.y)
	var p1 := Vector3(b.x, y0, b.y)
	var p2 := Vector3(b.x, y1, b.y)
	var p3 := Vector3(a.x, y1, a.y)
	lm.tri(key, p0, p1, p2, normal, normal, normal, Vector2(0, v), Vector2(u, v), Vector2(u, 0))
	lm.tri(key, p0, p2, p3, normal, normal, normal, Vector2(0, v), Vector2(u, 0), Vector2(0, 0))

## One triangle of a sloped wall: a..c, tiled from `origin` along horizontal
## `across`, its storeys counted down from `y_top`.
func wall_tri(key: String, a: Vector3, b: Vector3, c: Vector3, origin: Vector3, across: Vector3, y_top: float) -> void:
	var t: Vector2 = _tile[key]
	var n := (b - a).cross(c - a).normalized()
	var mid := (a + b + c) / 3.0
	if n.dot(Vector3(mid.x, 0.0, mid.z)) < 0.0:
		n = -n
	lm.tri(key, a, b, c, n, n, n, Vector2((a - origin).dot(across) / t.x, (y_top - a.y) / t.y),
		Vector2((b - origin).dot(across) / t.x, (y_top - b.y) / t.y),
		Vector2((c - origin).dot(across) / t.x, (y_top - c.y) / t.y))

## Outward normal of edge p..q of `poly`, whose winding is `sign`.
static func _edge_normal(p: Vector2, q: Vector2, winding: float) -> Vector3:
	var e := q - p
	return Vector3(e.y, 0, -e.x).normalized() * (1.0 if winding > 0.0 else -1.0)

static func winding(poly: PackedVector2Array) -> float:
	var w := 0.0
	for i in poly.size():
		var p := poly[i]
		var q := poly[(i + 1) % poly.size()]
		w += p.x * q.y - q.x * p.y
	return w

## Walls round `poly` from y0 to y1; a roof of surface `cap` when given.
func prism(key: String, poly: PackedVector2Array, y0: float, y1: float, cap: String = "") -> void:
	var w := winding(poly)
	for i in poly.size():
		var p := poly[i]
		var q := poly[(i + 1) % poly.size()]
		face(key, p, q, y0, y1, _edge_normal(p, q, w))
	if cap != "":
		roof(cap, poly, y1)

## A flat roof over `poly` at height y.
func roof(key: String, poly: PackedVector2Array, y: float) -> void:
	var idx := Geometry2D.triangulate_polygon(poly)
	for t in range(0, idx.size(), 3):
		var a := poly[idx[t]]
		var b := poly[idx[t + 1]]
		var c := poly[idx[t + 2]]
		lm.tri(key, Vector3(a.x, y, a.y), Vector3(b.x, y, b.y), Vector3(c.x, y, c.y),
			Vector3.UP, Vector3.UP, Vector3.UP, a, b, c)

## A tower of stacked tiers [y0, y1, w, d] with optional [notch, cx, cz], its
## surfaces "Facade", "Trim" and "Roof". Ribs stand every `rib_m` metres when
## given. The caller adds its crown to `kit.lm`, then commits.
static func tower(finish: String, bay_m: float, floor_m: float, tiers: Array,
		trim_hex: String = "#8b8e90", rib_m: float = 0.0) -> SkyKit:
	var mesh := LandmarkMesh.new()
	mesh.use("Trim", LandmarkMaterials.paint(trim_hex, 0.45, 0.4))
	mesh.use("Roof", LandmarkMaterials.pbr("concrete", "#6c6c6a", 4.0))
	var kit := SkyKit.new(mesh)
	kit.wall("Facade", finish, bay_m, floor_m)
	for t in tiers:
		var row := t as Array
		var notch := float(row[4]) if row.size() > 4 else 0.0
		var cx := float(row[5]) if row.size() > 5 else 0.0
		var cz := float(row[6]) if row.size() > 6 else 0.0
		var plan := notched(float(row[2]), float(row[3]), notch) if notch > 0.0 else rect(float(row[2]), float(row[3]), cx, cz)
		kit.prism("Facade", plan, float(row[0]), float(row[1]), "Roof")
		if notch <= 0.0:
			kit.band("Trim", plan, float(row[1]) - 0.5, float(row[1]) + 0.4, 0.3)
		if rib_m > 0.0:
			kit.rib_all("Trim", plan, float(row[0]), float(row[1]), rib_m)
	return kit

## Ribs every `spacing` metres round `poly`.
func rib_all(key: String, poly: PackedVector2Array, y0: float, y1: float, spacing: float,
		width: float = 0.7, proud: float = 0.5) -> void:
	var w := winding(poly)
	for i in poly.size():
		var p := poly[i]
		var q := poly[(i + 1) % poly.size()]
		var count := roundi(p.distance_to(q) / spacing)
		if count >= 2:
			ribs(key, p, q, count, y0, y1, width, proud, _edge_normal(p, q, w))

## Walls lofted from `low` at y0 to `high` at y1 (matching vertex counts),
## for tapers and sloped crowns. Each storey still tiles at real height.
func loft(key: String, low: PackedVector2Array, high: PackedVector2Array, y0: float, y1: float) -> void:
	var t: Vector2 = _tile[key]
	var w := winding(low)
	var v := maxf(1.0, roundf((y1 - y0) / t.y))
	for i in low.size():
		var j := (i + 1) % low.size()
		var p0 := Vector3(low[i].x, y0, low[i].y)
		var p1 := Vector3(low[j].x, y0, low[j].y)
		var p2 := Vector3(high[j].x, y1, high[j].y)
		var p3 := Vector3(high[i].x, y1, high[i].y)
		var n := (p1 - p0).cross(p3 - p0).normalized()
		if n.dot(_edge_normal(low[i], low[j], w)) < 0.0:
			n = -n
		var u := maxf(1.0, roundf(low[i].distance_to(low[j]) / t.x * 4.0)) / 4.0
		lm.tri(key, p0, p1, p2, n, n, n, Vector2(0, v), Vector2(u, v), Vector2(u, 0))
		lm.tri(key, p0, p2, p3, n, n, n, Vector2(0, v), Vector2(u, 0), Vector2(0, 0))

## `count` full-height ribs evenly along p..q, standing `proud` off the wall.
func ribs(key: String, p: Vector2, q: Vector2, count: int, y0: float, y1: float, width: float,
		proud: float, normal: Vector3) -> void:
	var e := q - p
	var basis := Basis(Vector3.UP, -atan2(e.y, e.x))
	for k in count:
		var at := p.lerp(q, (float(k) + 0.5) / float(count))
		lm.box(key, Vector3(at.x, (y0 + y1) * 0.5, at.y) + normal * proud * 0.5,
			Vector3(width, y1 - y0, proud), basis, 0.0)

## A horizontal band round `poly`, grown outward by `out`, from y0 to y1.
func band(key: String, poly: PackedVector2Array, y0: float, y1: float, out: float) -> void:
	var grown := inset(poly, -out)
	lm.poly_prism(key, grown, y0, y1, true)

## `poly` moved inward by `d` along each corner's bisector (convex plans).
static func inset(poly: PackedVector2Array, d: float) -> PackedVector2Array:
	var c := Vector2.ZERO
	for p in poly:
		c += p
	c /= float(poly.size())
	var out := PackedVector2Array()
	for i in poly.size():
		var prev := poly[(i + poly.size() - 1) % poly.size()]
		var p := poly[i]
		var next := poly[(i + 1) % poly.size()]
		var a := (p - prev).normalized()
		var b := (next - p).normalized()
		var n := Vector2(a.y, -a.x) + Vector2(b.y, -b.x)
		n = n.normalized() / maxf(0.2, Vector2(a.y, -a.x).dot(n.normalized()))
		if n.dot(c - p) < 0.0:
			n = -n
		out.append(p + n * d)
	return out

## A w x d rectangle centred on (cx, cz).
static func rect(w: float, d: float, cx: float = 0.0, cz: float = 0.0) -> PackedVector2Array:
	return PackedVector2Array([Vector2(cx - w * 0.5, cz - d * 0.5), Vector2(cx + w * 0.5, cz - d * 0.5),
		Vector2(cx + w * 0.5, cz + d * 0.5), Vector2(cx - w * 0.5, cz + d * 0.5)])

## A w x d rectangle with `n` metres cut from each corner (12 corners).
static func notched(w: float, d: float, n: float) -> PackedVector2Array:
	var x := w * 0.5
	var z := d * 0.5
	return PackedVector2Array([Vector2(-x + n, -z), Vector2(x - n, -z), Vector2(x - n, -z + n), Vector2(x, -z + n),
		Vector2(x, z - n), Vector2(x - n, z - n), Vector2(x - n, z), Vector2(-x + n, z),
		Vector2(-x + n, z - n), Vector2(-x, z - n), Vector2(-x, -z + n), Vector2(-x + n, -z + n)])
