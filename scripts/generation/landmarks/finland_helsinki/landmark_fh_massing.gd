class_name LandmarkFhMassing
extends RefCounted

## Building blocks for the Helsinki massing models (true metres, +X east, +Z
## south, front +Z): a walled body with plinth, cornice, roof and window
## rows, a columned portico, a round tower, a barrel vault and a square
## tower with a spire. Each landmark class sets its own materials and
## dimensions and adds the features that make it recognisable; these
## helpers only keep the repeated geometry in one place.
##
## Materials a body needs, by key: Wall, Stone (plinth), Trim (cornice),
## Roof, Window, Column. `mats` sets them from one wall set and two colours.

const U = preload("res://scripts/generation/landmarks/finland_helsinki/landmark_fh_util.gd")

static func mats(lm: LandmarkMesh, wall_set: String, wall_hex: String, roof_hex: String,
		stone_hex: String = "#8E8B85", trim_hex: String = "#EDE8DA") -> void:
	lm.use("Wall", LandmarkMaterials.pbr(wall_set, wall_hex, 3.0))
	lm.use("Stone", LandmarkMaterials.pbr("stone", stone_hex, 3.0))
	lm.use("Trim", LandmarkMaterials.pbr("limestone", trim_hex, 2.0))
	lm.use("Roof", LandmarkMaterials.paint(roof_hex, 0.65))
	lm.use("Window", LandmarkMaterials.glass("#2B3236"))
	lm.use("Column", LandmarkMaterials.pbr("limestone", trim_hex, 2.0))

## A body w (X) by d (Z) centred at (cx, cz): plinth, walls to `eave`, a
## cornice and a roof. `o` keys: plinth (0.8), roof "flat" | "hip" |
## "gable_x" | "gable_z", rise (0), top (hip top share, 0.3), rows, pitch,
## y0 (first window row), bays (front and back), side (side bays), ww, wh.
## Returns the height of the roof's highest point (flat: `eave`).
static func body(lm: LandmarkMesh, w: float, d: float, eave: float, o: Dictionary = {},
		cx: float = 0.0, cz: float = 0.0) -> float:
	var plinth: float = o.get("plinth", 0.8)
	var rise: float = o.get("rise", 0.0)
	var roof: String = o.get("roof", "flat")
	var hw := w * 0.5
	var hd := d * 0.5
	if plinth > 0.0:
		U.blk(lm, "Stone", cx, 0.0, cz, w + 0.4, plinth, d + 0.4)
	U.blk(lm, "Wall", cx, plinth, cz, w, eave - plinth, d)
	U.blk(lm, "Trim", cx, eave - 0.4, cz, w + 0.6, 0.4, d + 0.6)
	var c := Vector3(cx, eave, cz)
	match roof:
		"hip":
			U.hip(lm, "Roof", c, w + 1.0, d + 1.0, rise, o.get("top", 0.3))
		"gable_x":
			U.ridge_x(lm, "Roof", "Wall", c, w + 0.8, d + 0.8, rise, 0.4)
		"gable_z":
			U.ridge_z(lm, "Roof", "Wall", c, w + 0.8, d + 0.8, rise, 0.4)
		_:
			U.blk(lm, "Roof", cx, eave, cz, w - 0.6, 0.1, d - 0.6)
	var rows: int = o.get("rows", 0)
	if rows > 0:
		var pitch: float = o.get("pitch", 3.2)
		var y0: float = o.get("y0", 1.6)
		var ww: float = o.get("ww", 1.1)
		var wh: float = o.get("wh", 1.8)
		var bays: int = o.get("bays", 7)
		var side: int = o.get("side", 3)
		for s in [-1.0, 1.0]:
			U.window_grid(lm, "Window", Vector3(cx - hw + 1.6, 0, cz + s * hd), Vector3(cx + hw - 1.6, 0, cz + s * hd),
				Vector3(0, 0, s), y0, rows, pitch, bays, ww, wh)
			U.window_grid(lm, "Window", Vector3(cx + s * hw, 0, cz - hd + 1.6), Vector3(cx + s * hw, 0, cz + hd - 1.6),
				Vector3(s, 0, 0), y0, rows, pitch, side, ww, wh)
	return eave + (rise if roof != "flat" else 0.0)

## Columns carrying an architrave and a pediment in front of the wall at
## z = `zw` (front +Z), `n` columns across `width`, `h` tall from `base_y`.
static func portico(lm: LandmarkMesh, cx: float, zw: float, width: float, n: int, h: float,
		base_y: float, rise: float, depth: float = 3.0, key: String = "Column") -> void:
	var zc := zw + depth - 0.5
	U.blk(lm, "Stone", cx, 0.0, zw + depth * 0.5, width + 1.0, base_y, depth)
	U.columns(lm, key, Vector3(cx - width * 0.5 + 0.5, base_y, zc), Vector3(cx + width * 0.5 - 0.5, base_y, zc), n, h, 0.45)
	U.blk(lm, "Trim", cx, base_y + h, zw + depth * 0.5, width + 0.4, 0.9, depth + 0.2)
	U.ridge_z(lm, "Trim", "Trim", Vector3(cx, base_y + h + 0.9, zw + depth * 0.5), width + 0.8, depth + 0.4, rise, 0.1)

## Round tower: a drum of radius r from y0 to y0 + h, a cone of height `cone`.
static func round_tower(lm: LandmarkMesh, wall: String, roof: String, x: float, z: float, r: float,
		y0: float, h: float, cone: float, seg: int = 20) -> void:
	lm.frustum(wall, Vector3(x, y0, z), r, r, h, seg)
	lm.frustum("Trim", Vector3(x, y0 + h, z), r + 0.2, r + 0.2, 0.3, seg)
	lm.frustum(roof, Vector3(x, y0 + h + 0.3, z), r + 0.5, 0.0, cone, seg)

## Barrel vault along X from x0 to x1: a half-cylinder of half-width
## `half_w` over z = `zc`, springing at y0, `rise` high; round end windows.
static func barrel(lm: LandmarkMesh, key: String, end_key: String, x0: float, x1: float, zc: float,
		half_w: float, y0: float, rise: float, seg: int = 10) -> void:
	var prev := Vector2(zc + half_w, y0)
	for i in range(1, seg + 1):
		var a := PI * float(i) / float(seg)
		var p := Vector2(zc + half_w * cos(a), y0 + rise * sin(a))
		var mid := (prev + p) * 0.5
		var n := Vector3(0.0, mid.y - y0, mid.x - zc).normalized()
		lm.quad(key, Vector3(x0, prev.y, prev.x), Vector3(x1, prev.y, prev.x), Vector3(x1, p.y, p.x),
			Vector3(x0, p.y, p.x), n)
		for sgn in [-1.0, 1.0]:
			var x: float = x0 if sgn < 0.0 else x1
			var nx := Vector3(sgn, 0, 0)
			lm.tri(end_key, Vector3(x, y0, zc), Vector3(x, prev.y, prev.x), Vector3(x, p.y, p.x), nx, nx, nx,
				Vector2.ZERO, Vector2.ZERO, Vector2.ZERO)
		prev = p

## A glazed box with a frame: glass walls between horizontal frame bands
## every `pitch` metres and four corner posts. Keys: Glass, Frame.
static func glass_block(lm: LandmarkMesh, cx: float, cz: float, w: float, d: float, y0: float,
		h: float, pitch: float = 3.6) -> void:
	U.blk(lm, "Glass", cx, y0, cz, w, h, d)
	var n := maxi(int(h / pitch), 1)
	for k in n + 1:
		U.blk(lm, "Frame", cx, y0 + minf(float(k) * pitch, h - 0.25), cz, w + 0.25, 0.25, d + 0.25)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			U.blk(lm, "Frame", cx + sx * w * 0.5, y0, cz + sz * d * 0.5, 0.4, h, 0.4)

## A low rounded rock mound (granite islet or hill) of radii rx, rz and
## height h, its foot sunk 1 m so it meets the ground. Key `key` holds it.
static func mound(lm: LandmarkMesh, key: String, x: float, z: float, rx: float, rz: float, h: float,
		y0: float = 0.0) -> void:
	var prof := PackedVector2Array([Vector2(1.0, -1.0), Vector2(0.97, 0.0), Vector2(0.84, h * 0.45),
		Vector2(0.62, h * 0.8), Vector2(0.32, h * 0.97), Vector2(0.0, h)])
	lm.lathe(key, Vector3(x, y0, z), prof, 28, rx, rz)
