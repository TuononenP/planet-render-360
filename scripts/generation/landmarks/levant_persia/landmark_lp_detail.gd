class_name LandmarkLpDetail
extends RefCounted

## Mid-scale detail of the Levant / Persia / Central Asia batch, in true
## metres on LandmarkMesh: arcade skins with real recessed niches, pointed
## archivolt bands, rectangular tile frames (alfiz) round iwan arches,
## stepped muqarnas hoods, stepped Near Eastern merlons and tiled minarets.
## Walls follow LandmarkLpParts' frame: `yaw` 0 faces +Z.

## A wall skin `depth` thick laid in front of a mass face (its front plane
## at `front`, the skin's foot at front.y), W x H, cut from its foot by the
## arched openings [centre u, half-width, spring, rise]: the openings are
## real niches `depth` deep whose backs (the mass face) are painted `dark`.
static func arcade_skin(lm: LandmarkMesh, face: String, dark: String, front: Vector3, yaw: float,
		w: float, h: float, arches: Array, depth: float, steps: int = 8) -> void:
	LandmarkLpParts.slab(lm, face, LandmarkLpParts.arcade_outline(w, h, arches, steps), front, yaw, depth)
	var f := LandmarkLpParts.outward(yaw)
	var r := LandmarkLpParts.across(yaw)
	for ar in arches:
		var fill := PackedVector2Array([Vector2(-float(ar[1]), 0.0)])
		for p in LandmarkLpParts.arch_outline(float(ar[1]), float(ar[3]), steps):
			fill.append(p + Vector2(0.0, float(ar[2])))
		fill.append(Vector2(float(ar[1]), 0.0))
		LandmarkLpParts.slab(lm, dark, fill, front + r * float(ar[0]) - f * (depth - 0.04), yaw, 0.08)

## `n` equal arched bays across W (half-width a, spring s, rise `rise`, 0
## for a round arch) as arcade_outline entries centred on u = 0.
static func bays(n: int, w: float, a: float, s: float, rise: float = 0.0) -> Array:
	var out: Array = []
	var pitch := w / float(n)
	for i in n:
		out.append([(float(i) + 0.5) * pitch - w * 0.5, a, s, a if rise <= 0.0 else rise])
	return out

## Pointed (or round) archivolt band b wide over an opening of half-width
## a springing at `spring` (centre u on the wall frame of `yaw`), `depth`
## proud of `front`, carried down the jambs to the foot.
static func arch_band(lm: LandmarkMesh, key: String, front: Vector3, yaw: float, a: float, spring: float,
		rise: float, b: float, depth: float, steps: int = 8) -> void:
	var outer := LandmarkLpParts.arch_outline(a + b, rise + b, steps)
	var inner := LandmarkLpParts.arch_outline(a, rise, steps)
	var band := PackedVector2Array([Vector2(-a - b, 0.0)])
	for p in outer:
		band.append(p + Vector2(0.0, spring))
	band.append(Vector2(a + b, 0.0))
	band.append(Vector2(a, 0.0))
	for i in range(inner.size() - 1, -1, -1):
		band.append(inner[i] + Vector2(0.0, spring))
	band.append(Vector2(-a, 0.0))
	LandmarkLpParts.slab(lm, key, band, front + LandmarkLpParts.outward(yaw) * depth, yaw, depth)

## Rectangular frame (alfiz) b wide round an arch of half-width a whose
## crown is at `top` above front.y: two jambs and a head, `depth` proud.
static func alfiz(lm: LandmarkMesh, key: String, front: Vector3, yaw: float, a: float, top: float,
		b: float, depth: float) -> void:
	var r := LandmarkLpParts.across(yaw)
	var f := LandmarkLpParts.outward(yaw)
	var basis := Basis(Vector3.UP, yaw)
	for s in [-1.0, 1.0]:
		lm.box(key, front + r * (float(s) * (a + b * 0.5)) + f * depth * 0.5 + Vector3(0, top * 0.5, 0),
			Vector3(b, top, depth), basis)
	lm.box(key, front + f * depth * 0.5 + Vector3(0, top + b * 0.5, 0), Vector3(a * 2.0 + b * 2.0, b, depth), basis)

## Stepped muqarnas hood: `tiers` nested pointed arch bands inside a niche
## of half-width a (spring, rise), each smaller and set further back by
## `step`, so the vault reads as corbelled cells stepping into the shadow.
static func muqarnas_hood(lm: LandmarkMesh, key: String, front: Vector3, yaw: float, a: float, spring: float,
		rise: float, tiers: int, step: float) -> void:
	var f := LandmarkLpParts.outward(yaw)
	var b := a / float(tiers + 1)
	for k in tiers:
		var ak := a - b * float(k)
		var rk := rise - b * 0.9 * float(k)
		var sk := spring + b * 0.35 * float(k)
		arch_band(lm, key, front - f * step * float(k + 1), yaw, ak - b, sk, rk - b, b, step * 0.9, 6)

## Stepped (Mesopotamian / Achaemenid) merlons along a -> b standing on
## a.y: three diminishing tiers each, `w` wide at the foot, h tall.
static func stepped_merlons(lm: LandmarkMesh, key: String, a: Vector3, b: Vector3, w: float, h: float,
		thick: float, pitch: float) -> void:
	var d := b - a
	var n := maxi(int(d.length() / pitch), 1)
	var basis := Basis(Vector3.UP, atan2(-d.z, d.x))
	for i in n:
		var p := a.lerp(b, (float(i) + 0.5) / float(n))
		for t in 3:
			var tw := w * (1.0 - 0.3 * float(t))
			lm.box(key, p + Vector3(0, h * (float(t) + 0.5) / 3.0, 0), Vector3(tw, h / 3.0, thick), basis, 0.0)

## Ring of `n` slit windows (arrow loops) round a vertical axis at radius
## r and height y: thin dark plates standing just proud of the wall.
static func slit_ring(lm: LandmarkMesh, key: String, c: Vector3, r: float, y: float, n: int,
		h: float = 1.8, w: float = 0.3, rot: float = 0.0) -> void:
	for k in n:
		var a := rot + TAU * float(k) / float(n)
		var d := Vector3(cos(a), 0, sin(a))
		lm.box(key, c + d * (r + 0.03) + Vector3(0, y, 0), Vector3(w, h, 0.08), Basis.looking_at(d), 0.0)

## Tiled Persian / Timurid minaret of height h on `base` (r at the foot):
## moulded plinth, tapering brick shaft with glazed bands and an
## inscription frieze, a muqarnas balcony of corbel rings with a pierced
## parapet, an arcaded lantern on eight posts and a glazed bulb cap with
## a gilt finial. `balcony_y` is the gallery floor (default 0.78 h).
static func tile_minaret(lm: LandmarkMesh, brick: String, tile: String, base: Vector3, r: float, h: float,
		balcony_y: float = -1.0, gold: String = "") -> void:
	var by := balcony_y if balcony_y > 0.0 else h * 0.78
	var r_top := r * 0.8
	lm.lathe(brick, base, PackedVector2Array([Vector2(r * 1.4, 0.0), Vector2(r * 1.4, h * 0.05),
		Vector2(r * 1.25, h * 0.055), Vector2(r * 1.2, h * 0.07), Vector2(r * 1.08, h * 0.075)]), 20)
	var y0 := h * 0.075
	lm.lathe(brick, base + Vector3(0, y0, 0), PackedVector2Array([Vector2(r * 1.08, 0.0),
		Vector2(lerpf(r * 1.08, r_top, 0.5), (by - y0) * 0.5), Vector2(r_top, by - y0)]), 20, 1.0, 1.0, 0.0, true, false)
	# Glazed bands and the inscription frieze below the balcony.
	for f in [0.12, 0.3, 0.48, 0.64]:
		var y := h * float(f)
		var rr := lerpf(r * 1.08, r_top, (y - y0) / (by - y0)) + 0.06
		lm.frustum(tile, base + Vector3(0, y, 0), rr, rr, h * 0.025, 20)
		lm.frustum(tile, base + Vector3(0, y + h * 0.04, 0), rr - 0.02, rr - 0.02, h * 0.008, 20)
	var fy := by - h * 0.1
	lm.frustum(tile, base + Vector3(0, fy, 0), r_top * 1.07, r_top * 1.05, h * 0.06, 20)
	# Muqarnas balcony: four corbel rings flaring to the gallery floor.
	var cy := by - r * 1.0
	for k in 4:
		var t0 := float(k) / 4.0
		var t1 := float(k + 1) / 4.0
		lm.frustum(tile if k % 2 == 0 else brick, base + Vector3(0, cy + r * t0, 0),
			lerpf(r_top, r * 1.6, t0 * t0), lerpf(r_top, r * 1.6, t1 * t1), r * 0.25, 20)
	lm.frustum(brick, base + Vector3(0, by, 0), r * 1.65, r * 1.65, r * 0.12, 20)
	for k in 16:
		var a := TAU * float(k) / 16.0
		lm.box(brick, base + Vector3(cos(a) * r * 1.55, by + r * 0.42, sin(a) * r * 1.55),
			Vector3(r * 0.1, r * 0.6, r * 0.1), Basis(Vector3.UP, -a), 0.0)
	lm.frustum(brick, base + Vector3(0, by + r * 0.72, 0), r * 1.62, r * 1.62, r * 0.08, 20)
	# Lantern: eight posts carrying a ring, the glazed drum and the bulb.
	var lr := r * 0.72
	var lh := (h - by) * 0.32
	var ly := by + r * 0.12
	for k in 8:
		var a := TAU * float(k) / 8.0
		lm.box(brick, base + Vector3(cos(a) * lr, ly + lh * 0.5, sin(a) * lr), Vector3(r * 0.18, lh, r * 0.18),
			Basis(Vector3.UP, -a), 0.0)
	lm.frustum(brick, base + Vector3(0, ly, 0), lr * 0.7, lr * 0.7, lh, 10)
	lm.frustum(tile, base + Vector3(0, ly + lh, 0), lr * 1.12, lr * 1.12, r * 0.25, 16)
	var cap := base + Vector3(0, ly + lh + r * 0.25, 0)
	var cap_h := h - (ly + lh + r * 0.25) - r * 0.5
	lm.lathe(tile, cap, LandmarkLpParts.bulb_profile(lr * 1.05, cap_h, 1.14, 10, 1.3), 16)
	LandmarkLpParts.needle(lm, gold if gold != "" else tile, cap + Vector3(0, cap_h, 0),
		PackedVector2Array([Vector2(0, r * 0.12), Vector2(r * 0.2, r * 0.18), Vector2(r * 0.5, r * 0.04)]), 8)
