class_name StoDjurgKit
extends RefCounted

## Small helpers shared by the Djurgården landmark builders (Skansen gate and
## Bredablick, Waldemarsudde, Rosendal, ABBA, Liljevalchs, Cirkus): a framed
## window built once on its own origin and merged to every bay, a Swedish
## flag, and a regular octagon ring. True metres, +X east, +Z south, y up.

## A framed window facing +Z with its base on y = 0 and the frame in `frame`
## (a painted key of the caller's own), built once and placed with
## `StoChurchKit.place`.
static func unit(mats: Dictionary, w: float, h: float, arched: bool = false, depth: float = 0.25,
		frame: String = "Frame") -> LandmarkMesh:
	var u := LandmarkMesh.new()
	StoChurchKit.use_all(u, mats)
	LandmarkDetail.window(u, frame, "Glass", Vector3(0, h * 0.5, 0), Vector3.BACK, w, h, arched, depth)
	return u

## `n` units of `u` along a wall run `a`..`b` (ground points) facing `out`,
## their bases at height `y`, spaced evenly (first and last half a bay from
## the ends).
static func row(lm: LandmarkMesh, u: LandmarkMesh, a: Vector3, b: Vector3, out: Vector3, y: float, n: int,
		tilt: float = 0.0) -> void:
	for i in n:
		var p := a.lerp(b, (float(i) + 0.5) / float(n))
		StoChurchKit.place(lm, u, Vector3(p.x, y, p.z), out, tilt)

## Swedish flag (blue field, yellow Nordic cross) hanging from a pole at
## `pole` (x, z), its top edge `top` above the ground, flying toward +X.
## Keys "Blue" and "Yellow" must exist on `lm`.
static func flag(lm: LandmarkMesh, pole: Vector3, top: float, w: float = 1.8, h: float = 1.1) -> void:
	var c := Vector3(pole.x + w * 0.5 + 0.05, top - h * 0.5, pole.z)
	lm.box("Blue", c, Vector3(w, h, 0.04), Basis(), 0.0)
	lm.box("Yellow", c + Vector3(-w * 0.14, 0, 0), Vector3(w * 0.2, h, 0.06), Basis(), 0.0)
	lm.box("Yellow", c, Vector3(w, h * 0.2, 0.06), Basis(), 0.0)

## Closed ring of `n` posts and two rails between corners `pts` (a closed
## polygon at height y), rail heights `h`. Keys: "Metal".
static func railing(lm: LandmarkMesh, pts: Array, y: float, h: float, post_step: float = 0.9,
		key: String = "Metal") -> void:
	for i in pts.size():
		var a: Vector3 = pts[i]
		var b: Vector3 = pts[(i + 1) % pts.size()]
		a.y = y
		b.y = y
		lm.beam(key, a + Vector3(0, h, 0), b + Vector3(0, h, 0), 0.06, 0.06)
		lm.beam(key, a + Vector3(0, h * 0.5, 0), b + Vector3(0, h * 0.5, 0), 0.04, 0.04)
		var count := maxi(int(a.distance_to(b) / post_step), 1)
		for k in count + 1:
			var p := a.lerp(b, float(k) / float(count))
			lm.box(key, p + Vector3(0, h * 0.5, 0), Vector3(0.05, h, 0.05), Basis(), 0.0)

## Corners of a regular octagon of apothem `a` (flat faces on the axes) at
## height 0, circumradius a / cos(22.5 deg).
static func octagon(a: float) -> Array:
	var r := a / cos(PI / 8.0)
	var pts := []
	for i in 8:
		var t := PI / 8.0 + TAU * float(i) / 8.0
		pts.append(Vector3(cos(t) * r, 0.0, sin(t) * r))
	return pts
