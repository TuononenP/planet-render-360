class_name StoChurchKit
extends RefCounted

## Shared pieces of the three Stockholm churches (Klara, Sofia, Tyska
## kyrkan): the materials, a pointed window built once and merged to every
## bay, a hip roof with a gabled west end, a tapered square tower shaft and
## its stone bands, a round clock face, copper spirelets and a finial.
## True metres, model +X along the long axis, +Z south, origin at the
## footprint centre the registry yaw turns onto the map.

const COPPER := "#78A18F"
const COPPER_DARK := "#4D6B5D"

## Surface key -> material for one church; keys beyond the brick/stone pair
## are named per church.
static func materials(wall_set: String, wall_hex: String, trim_hex: String, copper_hex: String = COPPER) -> Dictionary:
	return {
		"Wall": LandmarkMaterials.pbr(wall_set, wall_hex, 3.0),
		"Trim": LandmarkMaterials.pbr("stone", trim_hex, 2.5),
		"Copper": LandmarkMaterials.pbr("concrete", copper_hex, 2.0, 0.55, 0.3),
		"Glass": LandmarkMaterials.glass("#20282D"),
		"Gilt": LandmarkMaterials.gold(),
		"Dial": LandmarkMaterials.pbr("render", "#E6DFCB", 1.5),
	}

static func use_all(lm: LandmarkMesh, mats: Dictionary) -> void:
	for k in mats:
		lm.use(str(k), mats[k] as Material)

## A pointed (gothic) window of the church's trim and glass, standing on
## its own origin facing +Z; built once and placed with `place`.
static func lancet_unit(mats: Dictionary, w: float, h: float, depth: float = 0.35, mullion: bool = true) -> LandmarkMesh:
	var u := LandmarkMesh.new()
	use_all(u, mats)
	LandmarkFhParts.lancet(u, "Trim", "Glass", Vector3.ZERO, Vector3.BACK, w, h, depth, mullion)
	return u

## A round-headed framed window, same convention.
static func round_unit(mats: Dictionary, w: float, h: float, depth: float = 0.3) -> LandmarkMesh:
	var u := LandmarkMesh.new()
	use_all(u, mats)
	LandmarkDetail.window(u, "Trim", "Glass", Vector3(0, h * 0.5, 0), Vector3.BACK, w, h, true, depth)
	return u

## Merge a part built facing +Z onto a wall facing `out` at `pos`; `tilt` leans
## its face back by that angle (a battered tower wall).
static func place(lm: LandmarkMesh, unit: LandmarkMesh, pos: Vector3, out: Vector3, tilt: float = 0.0) -> void:
	var b := Basis(Vector3.UP, atan2(out.x, out.z)) * Basis(Vector3.RIGHT, -tilt)
	lm.merge(unit, Transform3D(b, pos))

## Hip roof over x0..x1 by +-hz with the ridge along X: a hip at the +X end
## and, when `west_hip` is false, a gable wall `gable_key` at x0. Eaves at
## `y`, `rise` to the ridge, `over` eave overhang.
static func half_hip(lm: LandmarkMesh, key: String, gable_key: String, x0: float, x1: float, hz: float,
		y: float, rise: float, over: float = 0.5, west_hip: bool = false) -> void:
	var ridge0 := x0 + (hz if west_hip else 0.0)
	var ridge1 := x1 - hz
	var xe0 := x0 - (over if west_hip else 0.0)
	var xe1 := x1 + over
	var zo := hz + over
	var low := Vector3(0, y - over * rise / hz, 0)
	for s in [-1.0, 1.0]:
		var sg: float = s
		var a := Vector3(xe0, low.y, sg * zo)
		var b := Vector3(xe1, low.y, sg * zo)
		lm.quad(key, a, b, Vector3(ridge1, y + rise, 0), Vector3(ridge0, y + rise, 0),
			Vector3(0, hz, sg * rise).normalized())
	var e1 := Vector3(xe1, low.y, zo)
	var e2 := Vector3(xe1, low.y, -zo)
	var ne := Vector3(rise, hz, 0).normalized()
	lm.tri(key, e1, e2, Vector3(ridge1, y + rise, 0), ne, ne, ne,
		Vector2(0, 0), Vector2(zo * 2.0, 0), Vector2(zo, -rise))
	if west_hip:
		var w1 := Vector3(xe0, low.y, zo)
		var w2 := Vector3(xe0, low.y, -zo)
		var nw := Vector3(-rise, hz, 0).normalized()
		lm.tri(key, w1, w2, Vector3(ridge0, y + rise, 0), nw, nw, nw,
			Vector2(0, 0), Vector2(zo * 2.0, 0), Vector2(zo, -rise))
	elif gable_key != "":
		lm.tri(gable_key, Vector3(x0, y, hz), Vector3(x0, y, -hz), Vector3(x0, y + rise, 0),
			Vector3.LEFT, Vector3.LEFT, Vector3.LEFT, Vector2(0, 0), Vector2(hz * 2.0, 0), Vector2(hz, -rise))

## Square tapered shaft (half-width hw0 at y0 to hw1 at y0 + h) centred (cx, cz).
static func tapered_shaft(lm: LandmarkMesh, key: String, cx: float, cz: float, y0: float, h: float,
		hw0: float, hw1: float) -> void:
	lm.frustum(key, Vector3(cx, y0, cz), hw0 * 1.41421356, hw1 * 1.41421356, h, 4, PI * 0.25)

## Horizontal stone band round a square tower at height y.
static func tower_band(lm: LandmarkMesh, key: String, cx: float, cz: float, hw: float, y: float,
		h: float, proj: float) -> void:
	lm.box(key, Vector3(cx, y + h * 0.5, cz), Vector3(hw * 2.0 + proj * 2.0, h, hw * 2.0 + proj * 2.0))

## Clock dial on a wall at `c` facing `out`: a trim ring, a cream face, two hands.
static func clock(lm: LandmarkMesh, c: Vector3, out: Vector3, r: float) -> void:
	var n := out.normalized()
	lm.disc("Trim", c + n * 0.06, n, r * 1.22, 20)
	lm.disc("Dial", c + n * 0.12, n, r, 20)
	var right := Vector3.UP.cross(n).normalized()
	lm.beam("Glass", c + n * 0.16, c + n * 0.16 + Vector3.UP * r * 0.8, r * 0.07, r * 0.03, right)
	lm.beam("Glass", c + n * 0.16, c + n * 0.16 + right * r * 0.55, r * 0.07, r * 0.03, Vector3.UP)

## Octagonal pinnacle: stone neck and a copper spire, `base` at the neck foot.
static func pinnacle(lm: LandmarkMesh, base: Vector3, r: float, neck: float, spire_h: float) -> void:
	lm.frustum("Trim", base, r * 1.05, r, neck, 8, PI / 8.0)
	lm.lathe("Copper", base + Vector3.UP * neck, PackedVector2Array([
		Vector2(r * 1.02, 0), Vector2(r * 0.72, spire_h * 0.42), Vector2(r * 0.3, spire_h * 0.82),
		Vector2(0.0, spire_h)]), 8, 1.0, 1.0, PI / 8.0, false)

## Gilt ball and a slim vane on a spire tip at `tip`; the model ends `total` above it.
static func finial(lm: LandmarkMesh, tip: Vector3, ball_r: float, total: float) -> void:
	lm.lathe("Gilt", tip, LandmarkFhUtil.ball(ball_r), 10)
	var y0 := ball_r * 2.0
	lm.beam("Gilt", tip + Vector3.UP * y0, tip + Vector3.UP * total, 0.12, 0.12)
	lm.beam("Gilt", tip + Vector3(-0.5, y0 + (total - y0) * 0.55, 0), tip + Vector3(0.5, y0 + (total - y0) * 0.55, 0), 0.08, 0.08)

## Night wash of a church tower and its nave: two warm spots either side.
static func flood(model: Node3D, tower: Vector3, tower_h: float, reach: float) -> void:
	var warm := Color(1.0, 0.92, 0.78)
	model.set_meta(LandmarkLights.FLOOD_META, [
		[tower + Vector3(-reach, 1.0, reach), tower + Vector3(0, tower_h * 0.4, 0), 28.0, 1.0, tower_h * 1.5, warm],
		[tower + Vector3(reach, 1.0, -reach), tower + Vector3(0, tower_h * 0.4, 0), 28.0, 1.0, tower_h * 1.5, warm],
		[tower + Vector3(reach * 1.6, 1.0, reach * 1.1), tower + Vector3(reach * 1.4, 8.0, 0), 45.0, 0.8, 60.0, warm],
	])
