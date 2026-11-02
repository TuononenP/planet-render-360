class_name LandmarkKits
extends RefCounted

## Reusable landmark parts shared by the region batches
## (scripts/generation/landmarks/*), in true metres on LandmarkMesh.
## Every kit takes the material KEYS to draw with (registered by the
## caller with lm.use), builds upward from `base`, and stays small:
## a recognizable silhouette at skyline distance, not close-up detail.

## Round or ribbed dome on a drum, with an optional lantern and finial.
## Total height = drum_h + dome_h + lantern_h.
static func dome_on_drum(lm: LandmarkMesh, wall: String, dome: String, base: Vector3, r: float,
		drum_h: float, dome_h: float, lantern_h: float = 0.0, seg: int = 32) -> void:
	lm.frustum(wall, base, r, r, drum_h, seg)
	lm.lathe(dome, base + Vector3(0, drum_h, 0), _dome_profile(r * 1.02, dome_h), seg)
	if lantern_h > 0.0:
		var top := base + Vector3(0, drum_h + dome_h, 0)
		lm.frustum(wall, top, r * 0.16, r * 0.14, lantern_h * 0.7, 12)
		lm.frustum(dome, top + Vector3(0, lantern_h * 0.7, 0), r * 0.17, 0.0, lantern_h * 0.3, 12)

## Quarter-ellipse dome profile (radius, y), `steps` rings.
static func _dome_profile(r: float, h: float, steps: int = 8) -> PackedVector2Array:
	var p := PackedVector2Array()
	for i in steps + 1:
		var a := PI * 0.5 * float(i) / steps
		p.append(Vector2(r * cos(a), h * sin(a)))
	return p

## Slim round minaret: shaft, `balconies` ledges, spire cap. Height h.
static func minaret(lm: LandmarkMesh, shaft: String, cap: String, base: Vector3, r: float,
		h: float, balconies: int = 2) -> void:
	var cap_h := h * 0.14
	var body := h - cap_h
	lm.frustum(shaft, base, r * 1.15, r * 0.85, body, 14)
	for i in balconies:
		var y := body * (0.55 + 0.35 * float(i) / maxf(balconies - 1, 1))
		lm.frustum(shaft, base + Vector3(0, y, 0), r * 1.7, r * 1.7, r * 0.5, 14)
	lm.spire(cap, base + Vector3(0, body, 0), r * 1.1, cap_h, 0.0, 8)

## Coarse standing figure (robed body, head, raised arm) of height h,
## feet at `base`. The statue kit for monuments on a pedestal.
static func statue_figure(lm: LandmarkMesh, key: String, base: Vector3, h: float,
		arm_up: bool = false) -> void:
	var prof := PackedVector2Array([Vector2(h * 0.17, 0), Vector2(h * 0.14, h * 0.35),
		Vector2(h * 0.12, h * 0.65), Vector2(h * 0.14, h * 0.78), Vector2(h * 0.07, h * 0.85),
		Vector2(h * 0.05, h * 0.88)])
	lm.lathe(key, base, prof, 12)
	lm.lathe(key, base + Vector3(0, h * 0.88, 0), _dome_profile(h * 0.06, h * 0.12, 4), 10)
	if arm_up:
		lm.beam(key, base + Vector3(h * 0.1, h * 0.75, 0), base + Vector3(h * 0.2, h * 0.98, 0),
			h * 0.04, h * 0.04)
