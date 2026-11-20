extends RefCounted

## Helpers shared by the sto_far_* builders (Stockholm Tier C, plan S-3):
## footprints traced from OpenStreetMap rings in the model frame, extruded
## to walls with rows of window quads, mitre-inset hipped roofs over any
## outline, string courses. True metres on LandmarkMesh, +Z the front,
## polygons are XZ.

const FhU = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")
const FhP = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_parts.gd")
const Kit = preload("res://scripts/generation/landmarks/sweden_stockholm/palaces/sto_baroque_kit.gd")

## A mesh with every material of `mats` registered.
static func fresh(mats: Dictionary) -> LandmarkMesh:
	return Kit.fresh(mats)

## Axis rectangle as a polygon: centre, width (X), depth (Z).
static func rect(cx: float, cz: float, w: float, d: float) -> PackedVector2Array:
	return PackedVector2Array([Vector2(cx - w * 0.5, cz - d * 0.5), Vector2(cx + w * 0.5, cz - d * 0.5),
		Vector2(cx + w * 0.5, cz + d * 0.5), Vector2(cx - w * 0.5, cz + d * 0.5)])

## Outward unit normal (XZ) of polygon edge `i`, either winding.
static func out2(poly: PackedVector2Array, i: int) -> Vector2:
	var o := FhP.edge_out(poly, i)
	return Vector2(o.x, o.z)

## The polygon moved inward by `d` along every mitre; fine for the
## near-orthogonal outlines of these buildings.
static func inset(poly: PackedVector2Array, d: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	var n := poly.size()
	for i in n:
		var n0 := out2(poly, (i - 1 + n) % n)
		var n1 := out2(poly, i)
		out.append(poly[i] - (n0 + n1) / maxf(1.0 + n0.dot(n1), 0.25) * d)
	return out

## Hipped roof: a skirt from the outline at y0 up to the same outline
## moved inward by `d` at y0 + rise, closed by a flat top.
static func hip_roof(lm: LandmarkMesh, key: String, poly: PackedVector2Array, y0: float, d: float,
		rise: float) -> void:
	var inner := inset(poly, d)
	var n := poly.size()
	for i in n:
		var j := (i + 1) % n
		var o := out2(poly, i)
		var nrm := (Vector3(o.x, 0, o.y) * rise + Vector3.UP * d).normalized()
		lm.quad(key, Vector3(poly[i].x, y0, poly[i].y), Vector3(poly[j].x, y0, poly[j].y),
			Vector3(inner[j].x, y0 + rise, inner[j].y), Vector3(inner[i].x, y0 + rise, inner[i].y), nrm)
	lm.poly_prism(key, inner, y0 + rise - 0.02, y0 + rise)

## Rows of window quads on every edge of `poly` at least `min_len` long:
## `rows` rows `pitch` apart from y0, one window per `spacing` metres.
static func windows(lm: LandmarkMesh, key: String, poly: PackedVector2Array, y0: float, rows: int,
		pitch: float, spacing: float, w: float, h: float, min_len: float = 7.0, margin: float = 1.2,
		skip: Array = []) -> void:
	var n := poly.size()
	for i in n:
		if skip.has(i):
			continue
		var a := poly[i]
		var b := poly[(i + 1) % n]
		var len := a.distance_to(b)
		if len < min_len:
			continue
		var cnt := int((len - margin * 2.0) / spacing)
		if cnt < 1:
			continue
		var dir := (b - a) / len
		var a2 := a + dir * margin
		var b2 := b - dir * margin
		var o := out2(poly, i)
		FhU.window_grid(lm, key, Vector3(a2.x, 0, a2.y), Vector3(b2.x, 0, b2.y), Vector3(o.x, 0, o.y),
			y0, rows, pitch, cnt, w, h)

## A horizontal band (string course, cornice) round every edge of `poly`.
static func band(lm: LandmarkMesh, key: String, poly: PackedVector2Array, y: float, h: float,
		proj: float, min_len: float = 4.0) -> void:
	var n := poly.size()
	for i in n:
		var a := poly[i]
		var b := poly[(i + 1) % n]
		if a.distance_to(b) < min_len:
			continue
		var o := out2(poly, i)
		FhP.band(lm, key, Vector3(a.x, 0, a.y), Vector3(b.x, 0, b.y), Vector3(o.x, 0, o.y), y, h, proj)

## Centre (vertex mean) of a polygon.
static func centre(poly: PackedVector2Array) -> Vector2:
	return FhP.centre(poly)

## Octagonal (or any `seg`-sided) low roof drum with a flat cone cap.
static func drum(lm: LandmarkMesh, wall: String, roof: String, c: Vector3, r: float, h: float,
		cap_h: float, seg: int = 8) -> void:
	lm.lathe(wall, c, PackedVector2Array([Vector2(r, 0), Vector2(r, h)]), seg, 1.0, 1.0, PI / float(seg), false)
	lm.lathe(roof, c + Vector3(0, h, 0), PackedVector2Array([Vector2(r * 1.04, 0), Vector2(r * 0.12, cap_h)]),
		seg, 1.0, 1.0, PI / float(seg), false)
