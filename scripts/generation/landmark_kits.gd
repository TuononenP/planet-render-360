class_name LandmarkKits
extends RefCounted

## Reusable landmark parts shared by the region batches
## (scripts/generation/landmarks/*), in true metres on LandmarkMesh.
## Every kit takes the material KEYS to draw with (registered by the
## caller with lm.use) and builds upward from `base`. Architectural
## detail kits (columns, cornices, windows, balustrades) live in
## LandmarkDetail.

## Round dome on a drum: a plinth moulding and cornice on the drum,
## pilasters between its windows' bays, ribs up the shell (`ribs` > 0,
## drawn in the dome key), and an optional colonnaded lantern with a
## cupola and finial. Total height = drum_h + dome_h + lantern_h.
static func dome_on_drum(lm: LandmarkMesh, wall: String, dome: String, base: Vector3, r: float,
		drum_h: float, dome_h: float, lantern_h: float = 0.0, seg: int = 32, ribs: int = 0) -> void:
	var sg := maxi(seg, 40)
	lm.frustum(wall, base, r, r, drum_h, sg)
	# Plinth and crowning cornice rings on the drum.
	lm.frustum(wall, base, r * 1.05, r * 1.04, minf(drum_h * 0.08, 1.2), sg)
	var cy := base + Vector3(0, drum_h - minf(drum_h * 0.07, 1.0), 0)
	lm.lathe(wall, cy, PackedVector2Array([Vector2(r * 1.0, 0), Vector2(r * 1.05, minf(drum_h * 0.04, 0.6)),
		Vector2(r * 1.07, minf(drum_h * 0.07, 1.0))]), sg)
	# Pilasters round the drum.
	var bays := clampi(int(TAU * r / 4.5), 8, 32)
	if drum_h > 2.0:
		var pw := clampf(r * 0.07, 0.25, 1.4)
		for i in bays:
			var a := TAU * (float(i) + 0.5) / float(bays)
			var d := Vector3(cos(a), 0, sin(a))
			lm.box(wall, base + d * (r + pw * 0.2) + Vector3(0, drum_h * 0.5, 0),
				Vector3(pw, drum_h * 0.86, pw * 0.5), Basis.looking_at(d))
	var shell := base + Vector3(0, drum_h, 0)
	lm.lathe(dome, shell, _dome_profile(r * 1.02, dome_h, 16), sg)
	if ribs > 0:
		var prof := _dome_profile(r * 1.035, dome_h * 1.01, 12)
		var rw := clampf(r * 0.045, 0.15, 1.0)
		for i in ribs:
			var a := TAU * float(i) / float(ribs)
			var d := Vector3(cos(a), 0, sin(a))
			for j in prof.size() - 2:
				var p0 := shell + d * prof[j].x + Vector3(0, prof[j].y, 0)
				var p1 := shell + d * prof[j + 1].x + Vector3(0, prof[j + 1].y, 0)
				lm.beam(dome, p0, p1, rw, rw * 0.6, d.cross(Vector3.UP))
	if lantern_h > 0.0:
		var top := base + Vector3(0, drum_h + dome_h, 0)
		var lr := r * 0.16
		var lh := lantern_h * 0.56
		lm.frustum(wall, top, lr * 1.15, lr * 1.1, lh * 0.12, 16)
		lm.frustum(wall, top, lr * 0.8, lr * 0.8, lh, 16)
		for i in 8:
			var a := TAU * float(i) / 8.0
			var d := Vector3(cos(a), 0, sin(a))
			lm.frustum(wall, top + d * lr * 0.98, lr * 0.09, lr * 0.08, lh, 8)
		lm.frustum(wall, top + Vector3(0, lh, 0), lr * 1.15, lr * 1.18, lh * 0.1, 16)
		var cup := top + Vector3(0, lh * 1.1, 0)
		lm.lathe(dome, cup, _dome_profile(lr * 1.05, lantern_h * 0.24, 8), 16)
		lm.frustum(dome, cup + Vector3(0, lantern_h * 0.24, 0), lr * 0.14, 0.0, lantern_h * 0.14, 8)

## Quarter-ellipse dome profile (radius, y), `steps` rings.
static func _dome_profile(r: float, h: float, steps: int = 12) -> PackedVector2Array:
	var p := PackedVector2Array()
	for i in steps + 1:
		var a := PI * 0.5 * float(i) / steps
		p.append(Vector2(r * cos(a), h * sin(a)))
	return p

## Onion dome profile of radius r, height h: swells past the drum,
## pinches and draws out to a point.
static func onion_profile(r: float, h: float) -> PackedVector2Array:
	var p := PackedVector2Array()
	var pts := [[0.78, 0.0], [0.96, 0.08], [1.08, 0.2], [1.1, 0.3], [1.02, 0.42], [0.82, 0.55],
		[0.55, 0.66], [0.3, 0.76], [0.14, 0.86], [0.06, 0.94], [0.0, 1.0]]
	for q in pts:
		p.append(Vector2(r * float(q[0]), h * float(q[1])))
	return p

## Slim round minaret of height h: moulded base, tapering shaft with
## string courses, `balconies` corbelled galleries with parapets, a
## pencil cone with a crescent finial.
static func minaret(lm: LandmarkMesh, shaft: String, cap: String, base: Vector3, r: float,
		h: float, balconies: int = 2) -> void:
	var cap_h := h * 0.14
	var body := h - cap_h
	lm.frustum(shaft, base, r * 1.5, r * 1.4, body * 0.06, 20)
	lm.frustum(shaft, base + Vector3(0, body * 0.06, 0), r * 1.3, r * 1.25, body * 0.04, 20)
	lm.frustum(shaft, base, r * 1.15, r * 0.85, body, 20)
	for i in 5:
		var y := body * (0.15 + 0.15 * float(i))
		var rr := lerpf(r * 1.15, r * 0.85, y / body)
		lm.frustum(shaft, base + Vector3(0, y, 0), rr * 1.06, rr * 1.06, r * 0.12, 20)
	for i in balconies:
		var y := body * (0.55 + 0.35 * float(i) / maxf(balconies - 1, 1))
		var b := base + Vector3(0, y, 0)
		# Corbels flaring out to the gallery floor, then a pierced parapet.
		lm.lathe(shaft, b - Vector3(0, r * 0.9, 0), PackedVector2Array([Vector2(r * 0.95, 0),
			Vector2(r * 1.15, r * 0.35), Vector2(r * 1.45, r * 0.7), Vector2(r * 1.75, r * 0.9)]), 20)
		lm.frustum(shaft, b, r * 1.75, r * 1.75, r * 0.12, 20)
		for k in 16:
			var a := TAU * float(k) / 16.0
			lm.frustum(shaft, b + Vector3(cos(a), 0, sin(a)) * r * 1.65, r * 0.06, r * 0.06, r * 0.55, 6)
		lm.frustum(shaft, b + Vector3(0, r * 0.55, 0), r * 1.72, r * 1.72, r * 0.08, 20)
	var top := base + Vector3(0, body, 0)
	lm.frustum(shaft, top, r * 0.9, r * 1.0, r * 0.25, 20)
	lm.lathe(cap, top + Vector3(0, r * 0.25, 0), PackedVector2Array([Vector2(r * 1.05, 0),
		Vector2(r * 0.8, cap_h * 0.35), Vector2(r * 0.4, cap_h * 0.7), Vector2(0.0, cap_h - r * 0.25)]), 16)
	var tip := top + Vector3(0, cap_h, 0)
	lm.frustum(cap, tip - Vector3(0, r * 0.3, 0), r * 0.05, r * 0.05, r * 0.7, 6)
	lm.lathe(cap, tip + Vector3(0, r * 0.2, 0), _dome_profile(r * 0.12, r * 0.12, 4), 8)

## Standing robed figure of height h, feet at `base`: fluted classical
## drapery folds, contrapposto torso, sculpted facial profile & hair, and
## smooth anatomical multi-jointed arms via SculptureKit.
static func statue_figure(lm: LandmarkMesh, key: String, base: Vector3, h: float,
		arm_up: bool = false, yaw: float = 0.0) -> void:
	SculptureKit.classical_figure(lm, key, base, h, arm_up, yaw)
