class_name LandmarkShipTerminalKit
extends RefCounted

## Shared builder for the ship_terminals batch (LandmarkRegistryShipTerminals):
## principal ferry and cruise terminals whose outlines are measured from
## OpenStreetMap (way IDs in the registry comments) but which need no
## individual sculpt. Each hall (`outline_m`, plus `outline_b_m` at
## `height_b_m` for a second hall; rings in model-frame metres): a hall
## block with a clerestory
## glass band, a proud fascia and a flat roof at exactly its height, plus a
## column canopy along both long sides. Cruise halls read white with blue
## glass, ferry halls pale grey with green glass; a registry row may set
## `wall` / `glass` hexes to dress its own livery.

static func build(model: Node3D, entry: Dictionary) -> void:
	var cruise := str(entry.get("kind", "")) == "Cruise terminal"
	var lm := LandmarkMesh.new()
	lm.use("Wall", LandmarkMaterials.pbr("render",
		str(entry.get("wall", "#EDEFF1" if cruise else "#DDE0DE")), 4.0))
	lm.use("Glass", LandmarkMaterials.glass(
		str(entry.get("glass", "#3D5A78" if cruise else "#4E6B74"))))
	lm.use("Roof", LandmarkMaterials.pbr("membrane", "#7E8387", 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("concrete", "#E8E8E2", 3.0))
	var h := float(entry.get("height_m", 0.0))
	_hall(lm, _ring(entry.get("outline_m", [])), h)
	var outline_b := _ring(entry.get("outline_b_m", []))
	if outline_b.size() >= 3:
		_hall(lm, outline_b, float(entry.get("height_b_m", h)))
	lm.commit(model)

static func _ring(raw: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in raw:
		out.append(Vector2(float(p[0]), float(p[1])))
	return out

## A hall block: walls to half a metre under its height, a clerestory glass
## band round the whole perimeter, a proud fascia to exactly its height and
## a flat roof, with a column canopy along both long sides.
static func _hall(lm: LandmarkMesh, ring: PackedVector2Array, h: float) -> void:
	if ring.size() < 3 or h <= 0.0:
		return
	lm.poly_prism("Wall", ring, 0.0, h - 0.5, false)
	_band(lm, "Glass", ring, maxf(h - 3.5, 2.5), h - 0.5)
	for piece in Geometry2D.offset_polygon(ring, 0.35, Geometry2D.JOIN_MITER):
		lm.poly_prism("Trim", piece, h - 0.5, h, false)
		_cap(lm, "Roof", piece, h)
	_canopies(lm, ring)

## A vertical band of `key` on every face of `ring`, standing a hair proud.
static func _band(lm: LandmarkMesh, key: String, ring: PackedVector2Array, y0: float, y1: float) -> void:
	var wind := 1.0 if _area(ring) > 0.0 else -1.0
	for i in ring.size():
		var p := ring[i]
		var q := ring[(i + 1) % ring.size()]
		if p.distance_to(q) < 2.0:
			continue
		var e := q - p
		var n := Vector3(e.y, 0.0, -e.x).normalized() * wind
		var o := n * 0.05
		lm.quad(key, Vector3(p.x, y0, p.y) + o, Vector3(q.x, y0, q.y) + o,
			Vector3(q.x, y1, q.y) + o, Vector3(p.x, y1, p.y) + o, n)

## A flat polygon at height `y`.
static func _cap(lm: LandmarkMesh, key: String, ring: PackedVector2Array, y: float) -> void:
	var idx := Geometry2D.triangulate_polygon(ring)
	for t in range(0, idx.size(), 3):
		var a := ring[idx[t]]
		var b := ring[idx[t + 1]]
		var c := ring[idx[t + 2]]
		lm.tri(key, Vector3(a.x, y, a.y), Vector3(b.x, y, b.y), Vector3(c.x, y, c.y),
			Vector3.UP, Vector3.UP, Vector3.UP, a, b, c)

static func _area(ring: PackedVector2Array) -> float:
	var a := 0.0
	for i in ring.size():
		var p := ring[i]
		var q := ring[(i + 1) % ring.size()]
		a += p.x * q.y - q.x * p.y
	return a * 0.5

## A column canopy along both long sides: a slab at 5 m on columns every 8 m.
static func _canopies(lm: LandmarkMesh, ring: PackedVector2Array) -> void:
	var best := 0.0
	var ax := Vector2.RIGHT
	for i in ring.size():
		var e := ring[(i + 1) % ring.size()] - ring[i]
		if e.length() > best:
			best = e.length()
			ax = e.normalized()
	if best < 12.0:
		return
	var cr := Vector2(-ax.y, ax.x)
	var c0 := INF
	var c1 := -INF
	for v in ring:
		c0 = minf(c0, v.dot(cr))
		c1 = maxf(c1, v.dot(cr))
	for side: float in [-1.0, 1.0]:
		var mid := (c0 + c1) * 0.5 + side * ((c1 - c0) * 0.5 + 2.0)
		var a0 := -INF
		var a1 := INF
		for v in ring:
			a0 = maxf(a0, v.dot(ax))
			a1 = minf(a1, v.dot(ax))
		var span := a0 - a1
		if span < 12.0:
			continue
		var ctr := ax * (a0 + a1) * 0.5 + cr * mid
		var along := Basis(Vector3.UP, PI * 0.5 - ax.angle())
		lm.box("Trim", Vector3(ctr.x, 5.0, ctr.y), Vector3(4.0, 0.3, span), along, 0.0)
		var n := int(span / 8.0)
		for k in n + 1:
			var at := ctr + ax * (span * 0.5 - span * float(k) / float(maxi(n, 1)))
			lm.beam("Trim", Vector3(at.x, 0.0, at.y), Vector3(at.x, 5.0, at.y), 0.35, 0.35)
