class_name LandmarkSfFerryTower
extends RefCounted

## The Ferry Building's 75 m clock tower in true metres on LandmarkMesh
## (keys of LandmarkSfFerry): rises from the facade's centre, front face
## 4 m proud of the wall at z = 18.

const TZ := LandmarkSfFerry.TOWER_Z

static func tower(lm: LandmarkMesh) -> void:
	# Stage A (0-22): the base block with its three entrance arches.
	lm.box("Stone", Vector3(0, 11.0, TZ), Vector3(20.0, 22.0, 20.0), Basis(), 0.0)
	lm.box("Trim", Vector3(0, 0.6, TZ), Vector3(21.0, 1.2, 21.0), Basis(), 0.0)
	var zf := TZ + 10.0
	for g in [[0.0, 7.0, 8.5], [-6.2, 3.0, 5.0], [6.2, 3.0, 5.0]]:
		var gx: float = g[0]
		var span: float = g[1]
		var spring: float = g[2]
		lm.box("Glass", Vector3(gx, spring * 0.5 + 0.6, zf + 0.03), Vector3(span, spring - 1.2, 0.06), Basis(), 0.0)
		var c := Vector3(gx, spring, zf + 0.03)
		for i in 8:
			var t0 := PI * float(i) / 8.0
			var t1 := PI * float(i + 1) / 8.0
			lm.tri("Glass", c, c + Vector3(cos(t0), sin(t0), 0) * span * 0.5, c + Vector3(cos(t1), sin(t1), 0) * span * 0.5,
				Vector3.BACK, Vector3.BACK, Vector3.BACK, Vector2.ZERO, Vector2(cos(t0), sin(t0)) * span * 0.5,
				Vector2(cos(t1), sin(t1)) * span * 0.5)
		LandmarkDetail.arch(lm, "Trim", Vector3(gx, spring, zf + 0.02), Vector3.BACK, span, 0.6 if span > 5.0 else 0.4,
			0.4, 18)
	for s in [-1.0, 1.0]:
		lm.box("Trim", Vector3(s * 3.9, 6.0, zf + 0.25), Vector3(0.9, 12.0, 0.5), Basis(), 0.0)
		lm.box("Trim", Vector3(s * 9.6, 11.0, zf + 0.3), Vector3(0.9, 22.0, 0.6), Basis(), 0.0)
	lm.box("Trim", Vector3(0, 22.3, TZ), Vector3(21.2, 0.7, 21.2), Basis(), 0.0)
	# Stage B (22-47): the shaft, two rows of paired arched windows per face.
	var bh := 8.8
	lm.box("Stone", Vector3(0, 34.5, TZ), Vector3(bh * 2.0, 25.0, bh * 2.0), Basis(), 0.0)
	for f in 4:
		var n := Vector3(0, 0, 1).rotated(Vector3.UP, PI * 0.5 * float(f))
		var right := Vector3.UP.cross(n).normalized()
		var face_c := Vector3(0, 0, TZ) + n * bh
		for row in [28.0, 39.0]:
			for side in [-1.0, 1.0]:
				LandmarkDetail.window(lm, "Trim", "Glass", face_c + right * float(side) * 2.7 + Vector3(0, row, 0), n,
					1.9, 5.4, true, 0.3)
		lm.box("Trim", face_c + Vector3(0, 33.2, 0) + n * 0.2, Vector3(bh * 2.0 + 0.9, 0.55, 0.6),
			Basis(right, Vector3.UP, n), 0.0)
	for q in [Vector2(1, 1), Vector2(-1, 1), Vector2(-1, -1), Vector2(1, -1)]:
		var v: Vector2 = q
		lm.box("Trim", Vector3(v.x * bh, 34.5, TZ + v.y * bh), Vector3(1.2, 25.0, 1.2), Basis(), 0.0)
	lm.box("Trim", Vector3(0, 47.2, TZ), Vector3(bh * 2.0 + 1.2, 0.8, bh * 2.0 + 1.2), Basis(), 0.0)
	# Stage C (47.6-58): clock stage with four dials.
	var ch := 7.9
	lm.box("Stone", Vector3(0, 53.1, TZ), Vector3(ch * 2.0, 10.8, ch * 2.0), Basis(), 0.0)
	for f in 4:
		var n := Vector3(0, 0, 1).rotated(Vector3.UP, PI * 0.5 * float(f))
		var right := Vector3.UP.cross(n).normalized()
		var dc := Vector3(0, 52.7, TZ) + n * (ch + 0.06)
		lm.box("Trim", dc - n * 0.0 + n * 0.1, Vector3(8.2, 8.2, 0.3), Basis(right, Vector3.UP, n), 0.0)
		lm.disc("Dial", dc + n * 0.3, n, 3.35, 40)
		for h in 12:
			var a := TAU * float(h) / 12.0
			var tp := dc + n * 0.34 + right * cos(a) * 2.85 + Vector3.UP * sin(a) * 2.85
			lm.box("Glass", tp, Vector3(0.22 if h % 3 else 0.4, 0.7 if h % 3 else 1.0, 0.06),
				Basis(right, Vector3.UP, n).rotated(n, a - PI * 0.5), 0.0)
		lm.beam("Glass", dc + n * 0.38, dc + n * 0.38 + Vector3.UP * 2.7, 0.2, 0.06, n)
		lm.beam("Glass", dc + n * 0.38, dc + n * 0.38 + right * -1.8 + Vector3.UP * 1.0, 0.3, 0.06, n)
	for q in [Vector2(1, 1), Vector2(-1, 1), Vector2(-1, -1), Vector2(1, -1)]:
		var v: Vector2 = q
		lm.box("Trim", Vector3(v.x * ch, 53.1, TZ + v.y * ch), Vector3(1.1, 10.8, 1.1), Basis(), 0.0)
	lm.box("Trim", Vector3(0, 58.2, TZ), Vector3(ch * 2.0 + 1.0, 0.8, ch * 2.0 + 1.0), Basis(), 0.0)
	# Stage D (58.6-67): the open belfry, three arches a face.
	var dh := 7.4
	lm.box("Glass", Vector3(0, 62.8, TZ), Vector3(dh * 2.0 - 1.2, 8.4, dh * 2.0 - 1.2), Basis(), 0.0)
	for q in [Vector2(1, 1), Vector2(-1, 1), Vector2(-1, -1), Vector2(1, -1)]:
		var v: Vector2 = q
		lm.box("Stone", Vector3(v.x * (dh - 0.7), 62.8, TZ + v.y * (dh - 0.7)), Vector3(2.6, 8.4, 2.6), Basis(), 0.0)
	for f in 4:
		var n := Vector3(0, 0, 1).rotated(Vector3.UP, PI * 0.5 * float(f))
		var right := Vector3.UP.cross(n).normalized()
		var face_c := Vector3(0, 0, TZ) + n * (dh - 0.1)
		for k in 3:
			var ax := (float(k) - 1.0) * 3.2
			LandmarkDetail.arch(lm, "Trim", face_c + right * ax + Vector3(0, 62.0, 0), n, 2.2, 0.3, 0.3, 12)
			lm.box("Stone", face_c + right * (ax + 1.6) + Vector3(0, 61.0, 0), Vector3(1.0, 6.0, 0.7), Basis(right, Vector3.UP, n))
		lm.box("Stone", face_c + Vector3(0, 65.7, 0), Vector3(dh * 2.0, 2.6, 0.8), Basis(right, Vector3.UP, n), 0.0)
	# Cornice and balustrade, the corner pinnacles, the tiled pyramid.
	lm.box("Trim", Vector3(0, 67.4, TZ), Vector3(dh * 2.0 + 2.2, 0.9, dh * 2.0 + 2.2), Basis(), 0.0)
	lm.box("Trim", Vector3(0, 68.0, TZ), Vector3(dh * 2.0 + 1.6, 0.4, dh * 2.0 + 1.6), Basis(), 0.0)
	var bz := dh + 0.6
	for f in 4:
		var n := Vector3(0, 0, 1).rotated(Vector3.UP, PI * 0.5 * float(f))
		var right := Vector3.UP.cross(n).normalized()
		var c := Vector3(0, 68.2, TZ) + n * bz
		LandmarkNaParts.balusters(lm, "Trim", c - right * bz, c + right * bz, 1.1, 0.55, 4.4, false)
	for q in [Vector2(1, 1), Vector2(-1, 1), Vector2(-1, -1), Vector2(1, -1)]:
		var v: Vector2 = q
		lm.spire("Trim", Vector3(v.x * bz, 68.2, TZ + v.y * bz), 0.75, 3.4, 0.0)
	lm.spire("Roof", Vector3(0, 68.2, TZ), dh - 0.4, 5.0, 1.0)
	lm.box("Trim", Vector3(0, 74.0, TZ), Vector3(2.0, 1.2, 2.0), Basis(), 0.0)
	lm.spire("Metal", Vector3(0, 74.6, TZ), 0.8, LandmarkSfFerry.TOWER_TOP_M - 74.6, 0.0)
