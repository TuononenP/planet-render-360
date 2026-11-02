class_name LandmarkMaParts
extends RefCounted

## Small shared shapes for the Middle East / Africa landmark batch, in
## true metres on LandmarkMesh.

## Dome profile (radius, y), bottom to top, ending on the axis. `tip`
## > 0 pulls the crown into an onion point (radius * cos^(1 + tip)).
static func dome_profile(r: float, h: float, steps: int = 8, tip: float = 0.0) -> PackedVector2Array:
	var p := PackedVector2Array()
	for i in steps + 1:
		var a := PI * 0.5 * float(i) / steps
		p.append(Vector2(r * pow(cos(a), 1.0 + tip), h * sin(a)))
	return p

## Dome of radius r and height h standing on `base`.
static func dome(lm: LandmarkMesh, key: String, base: Vector3, r: float, h: float,
		seg: int = 16, tip: float = 0.0) -> void:
	lm.lathe(key, base, dome_profile(r, h, 6, tip), seg)

## Ellipsoid (sphere stretched by sy) centred on `c`.
static func sphere(lm: LandmarkMesh, key: String, c: Vector3, r: float, seg: int = 20,
		rings: int = 10, sy: float = 1.0) -> void:
	var p := PackedVector2Array()
	for i in rings + 1:
		var a := -PI * 0.5 + PI * float(i) / rings
		p.append(Vector2(r * cos(a), r * sy * (1.0 + sin(a))))
	lm.lathe(key, c - Vector3(0, r * sy, 0), p, seg)

## Needle / mast: radius tapers through `prof` (height m, radius m) pairs.
static func needle(lm: LandmarkMesh, key: String, base: Vector3, prof: PackedVector2Array,
		seg: int = 12) -> void:
	var p := PackedVector2Array()
	for v in prof:
		p.append(Vector2(v.y, v.x))
	lm.lathe(key, base, p, seg)

## Crescent in the XY plane: an arc of `r` round `c`, open upward.
static func crescent(lm: LandmarkMesh, key: String, c: Vector3, r: float, w: float) -> void:
	var prev := c + Vector3(sin(deg_to_rad(-130.0)), -cos(deg_to_rad(-130.0)), 0) * r
	for k in range(1, 15):
		var t := deg_to_rad(-130.0 + 260.0 * float(k) / 14.0)
		var p := c + Vector3(sin(t), -cos(t), 0) * r
		lm.beam(key, prev, p, w, w * 1.6, Vector3(0, 0, 1))
		prev = p
