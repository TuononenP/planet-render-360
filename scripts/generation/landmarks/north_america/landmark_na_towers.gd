class_name LandmarkNaTowers
extends RefCounted

## Three observation towers in true metres: Toronto's CN Tower, Seattle's
## Space Needle and Las Vegas's STRAT.

const CN_TIP_M := 553.3
const CN_SKYPOD_M := 446.5
const CN_MAST_M := 457.2
const NEEDLE_TIP_M := 184.0
const STRAT_TIP_M := 350.2

## CN Tower: the hexagonal concrete shaft with three tapering buttress
## legs (the Y plan) that merge into it below the main pod, the glazed
## elevator shafts in the three re-entrant angles (two cars each), the
## main pod (white radome at 338 m, glass-floor terrace at 342 m,
## LookOut at 346 m, 360 Restaurant at 351 m, EdgeWalk ledge on the roof
## at 356 m), The Top (SkyPod) at 446.5 m and the 102 m steel broadcast
## mast from 457 m to the 553.3 m tip.
static func cn_tower(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#B9B6AE", 5.0))
	lm.use("Glass", LandmarkMaterials.glass("#5E7686"))
	lm.use("Mast", LandmarkMaterials.paint("#D9DBDC", 0.4, 0.5))
	lm.use("Radome", LandmarkMaterials.paint("#ECEBE6", 0.55, 0.05))
	var shaft := PackedVector2Array([Vector2(11.0, 0.0), Vector2(8.6, 90.0), Vector2(6.8, 200.0),
		Vector2(5.8, 320.0), Vector2(5.4, 335.0), Vector2(5.0, CN_SKYPOD_M)])
	lm.lathe("Concrete", Vector3.ZERO, shaft, 6, 1.0, 1.0, PI / 6.0, false)
	for k in 3:
		_fin(lm, TAU * float(k) / 3.0 + PI / 6.0, 8.0, 26.0, 335.0, 3.4)
	# Glass-fronted elevator shafts in the three angles between the legs,
	# each framed by concrete cheeks, rising from the base to the pod.
	for k in 3:
		var a := TAU * float(k) / 3.0 + PI / 6.0 + PI / 3.0
		var d := Vector3(cos(a), 0, sin(a))
		var prev_y := 6.0
		for y in [60.0, 120.0, 180.0, 240.0, 300.0, 331.0]:
			var r0 := LandmarkNaParts.radius_at(shaft, prev_y) + 1.6
			var r1 := LandmarkNaParts.radius_at(shaft, float(y)) + 1.6
			var p0 := d * r0 + Vector3(0, prev_y, 0)
			var p1 := d * r1 + Vector3(0, float(y), 0)
			lm.beam("Glass", p0, p1, 4.2, 2.4, d.cross(Vector3.UP))
			for s in [-1.0, 1.0]:
				var off: Vector3 = d.cross(Vector3.UP) * 2.5 * float(s)
				lm.beam("Concrete", p0 + off - d * 0.4, p1 + off - d * 0.4, 0.8, 3.4, d.cross(Vector3.UP))
			prev_y = float(y)
		# Entrance hood where the cars leave the base building.
		lm.box("Concrete", d * 12.5 + Vector3(0, 3.0, 0), Vector3(7.0, 6.0, 4.0), Basis.looking_at(d))
	# Base: the low entrance pavilion round the foot of the legs.
	lm.frustum("Concrete", Vector3.ZERO, 34.0, 33.0, 1.2, 6, PI / 6.0)
	_cn_pod(lm, Vector3(0, 329.0, 0))
	_cn_skypod(lm, Vector3(0, CN_SKYPOD_M - 4.0, 0))
	_cn_mast(lm, Vector3(0, CN_MAST_M, 0))
	lm.commit(model)

## The main pod from its flared underside (329 m) to the roof cap.
static func _cn_pod(lm: LandmarkMesh, pod: Vector3) -> void:
	# Radome: the white doughnut of the old UHF transmitters (338 m).
	lm.lathe("Concrete", pod, PackedVector2Array([Vector2(5.4, 0.0), Vector2(9.0, 1.6),
		Vector2(13.0, 4.0), Vector2(15.0, 6.0)]), 36)
	lm.lathe("Radome", pod + Vector3(0, 6.0, 0), PackedVector2Array([Vector2(15.0, 0.0),
		Vector2(17.6, 0.6), Vector2(19.3, 1.8), Vector2(20.0, 3.4), Vector2(19.3, 5.0),
		Vector2(17.6, 6.2), Vector2(15.6, 6.8)]), 48)
	# Lower Observation Level (342 m): glass floor, outdoor terrace rail.
	var lo := pod + Vector3(0, 12.8, 0)
	lm.frustum("Concrete", lo, 18.2, 18.2, 0.6, 48)
	lm.lathe("Glass", lo + Vector3(0, 0.6, 0), PackedVector2Array([Vector2(16.4, 0.0),
		Vector2(16.4, 3.0)]), 48, 1.0, 1.0, 0.0, true, false)
	LandmarkNaParts.ring_rail(lm, "Mast", lo + Vector3(0, 0.6, 0), 17.9, 1.5, 2.2)
	LandmarkNaParts.ring_posts(lm, "Mast", lo + Vector3(0, 0.6, 0), 16.5, 3.0, 36, 0.2, 0.3)
	# LookOut (346 m) and the 360 Restaurant (351 m): outward-leaning
	# glazed bands with mullions, a concrete spandrel between them.
	var y := lo.y + 3.6
	for band in [[19.0, 20.2, 4.2], [19.6, 20.6, 4.2]]:
		var r0: float = band[0]
		var r1: float = band[1]
		var h: float = band[2]
		lm.frustum("Concrete", Vector3(0, y, 0), r0 + 0.2, r0 + 0.2, 0.8, 48)
		lm.lathe("Glass", Vector3(0, y + 0.8, 0), PackedVector2Array([Vector2(r0, 0.0),
			Vector2(r1, h)]), 48, 1.0, 1.0, 0.0, true, false)
		for i in 48:
			var a := TAU * float(i) / 48.0
			var d := Vector3(cos(a), 0, sin(a))
			lm.beam("Mast", d * (r0 + 0.08) + Vector3(0, y + 0.8, 0),
				d * (r1 + 0.08) + Vector3(0, y + 0.8 + h, 0), 0.16, 0.2, d.cross(Vector3.UP))
		y += 0.8 + h
	# Roof ring with the EdgeWalk ledge (356 m, 1.5 m wide) and its
	# overhead tether rail, then the cap drawing in to the shaft.
	lm.lathe("Concrete", Vector3(0, y, 0), PackedVector2Array([Vector2(21.0, 0.0), Vector2(22.2, 0.3),
		Vector2(22.2, 1.0), Vector2(20.5, 1.2)]), 48)
	LandmarkNaParts.ring_rail(lm, "Mast", Vector3(0, y + 1.0, 0), 22.0, 0.5, 3.0)
	LandmarkNaParts.ring_posts(lm, "Mast", Vector3(0, y + 1.0, 0), 19.2, 4.2, 12, 0.25, 0.25)
	LandmarkNaParts.ring(lm, "Mast", Vector3(0, y + 5.0, 0), 20.2, 2.2, 0.25, 48)
	lm.lathe("Concrete", Vector3(0, y + 1.2, 0), PackedVector2Array([Vector2(20.5, 0.0),
		Vector2(17.0, 2.5), Vector2(12.0, 4.5), Vector2(7.5, 6.0), Vector2(5.4, 6.5)]), 36)

## The Top (SkyPod, 446.5 m): a small flared pod with its window band.
static func _cn_skypod(lm: LandmarkMesh, b: Vector3) -> void:
	lm.lathe("Concrete", b, PackedVector2Array([Vector2(5.0, 0.0), Vector2(6.8, 1.6),
		Vector2(8.2, 3.6)]), 24)
	lm.lathe("Glass", b + Vector3(0, 3.6, 0), PackedVector2Array([Vector2(8.4, 0.0),
		Vector2(8.7, 3.2)]), 24, 1.0, 1.0, 0.0, true, false)
	LandmarkNaParts.ring_posts(lm, "Mast", b + Vector3(0, 3.6, 0), 8.65, 3.2, 24, 0.14, 0.18)
	lm.lathe("Concrete", b + Vector3(0, 6.8, 0), PackedVector2Array([Vector2(9.0, 0.0),
		Vector2(9.0, 0.6), Vector2(7.0, 2.4), Vector2(5.0, 4.6), Vector2(3.9, 10.7)]), 24)

## Broadcast mast: a tapering steel tube in flanged sections, the
## maintenance platforms and the red aircraft beacons near the tip.
static func _cn_mast(lm: LandmarkMesh, b: Vector3) -> void:
	var prof := PackedVector2Array([Vector2(3.6, 0.0), Vector2(2.6, 30.0), Vector2(1.6, 60.0),
		Vector2(0.9, 82.0), Vector2(0.15, CN_TIP_M - CN_MAST_M)])
	lm.lathe("Mast", b, prof, 12)
	var y := 6.0
	while y < 88.0:
		var r := LandmarkNaParts.radius_at(prof, y)
		LandmarkNaParts.ring(lm, "Mast", b + Vector3(0, y, 0), r + 0.12, 0.25, 0.35, 12)
		y += 7.5
	for py in [18.0, 44.0, 70.0]:
		var r := LandmarkNaParts.radius_at(prof, py)
		lm.frustum("Mast", b + Vector3(0, py, 0), r + 1.2, r + 1.2, 0.25, 12)
		LandmarkNaParts.ring_rail(lm, "Mast", b + Vector3(0, py + 0.25, 0), r + 1.1, 1.0, 1.2)

## One concave buttress fin: a thin radial slab `thick` wide, `r_in` at
## the shaft and `r_out` at the ground, narrowing to nothing at `h`.
static func _fin(lm: LandmarkMesh, yaw: float, r_in: float, r_out: float, h: float,
		thick: float) -> void:
	var b := Basis(Vector3.UP, -yaw)
	var steps := 14
	var prev := Vector2(r_out, 0.0)
	for k in range(1, steps + 1):
		var f := float(k) / steps
		var cur := Vector2(r_in + (r_out - r_in) * pow(1.0 - f, 2.2), h * f)
		var s := cur - prev
		var n_out: Vector3 = b * Vector3(s.y, -s.x, 0.0).normalized()
		for z in [-1.0, 1.0]:
			var zz: float = z * thick * 0.5
			var side: Vector3 = b * Vector3(0, 0, z)
			lm.quad("Concrete", b * Vector3(r_in, prev.y, zz), b * Vector3(prev.x, prev.y, zz),
				b * Vector3(cur.x, cur.y, zz), b * Vector3(r_in, cur.y, zz), side)
		lm.quad("Concrete", b * Vector3(prev.x, prev.y, -thick * 0.5), b * Vector3(prev.x, prev.y, thick * 0.5),
			b * Vector3(cur.x, cur.y, thick * 0.5), b * Vector3(cur.x, cur.y, -thick * 0.5), n_out)
		prev = cur
	# Foot of the leg: a stepped plinth where it meets the ground.
	lm.box("Concrete", b * Vector3(r_out - 2.0, 1.5, 0), Vector3(7.0, 3.0, thick + 1.6), b)

## Space Needle (1962): the tripod of three steel legs, each a pair of
## curved columns tied like a ladder, pinched into the hourglass waist
## and splaying out under the top house; the core with its three
## elevator rails; the SkyLine level at 30 m; the top house: ribbed
## underside, the revolving Loupe restaurant (152 m), the observation
## deck (160 m) behind its tilted glass barrier, the Galaxy Gold roof,
## and the beacon and spire to 184 m.
static func space_needle(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("White", LandmarkMaterials.paint("#F1EFE9", 0.5, 0.15))
	lm.use("Gold", LandmarkMaterials.paint("#C98A2B", 0.4, 0.45))
	lm.use("Glass", LandmarkMaterials.glass("#4F6674"))
	lm.use("Base", LandmarkMaterials.pbr("concrete", "#A9A59C", 4.0))
	lm.use("Core", LandmarkMaterials.paint("#9DA39A", 0.55, 0.3))
	# Leg centre radius and the half-spread of each column pair by height.
	var ys := [1.2, 14.0, 30.0, 50.0, 70.0, 88.0, 100.0, 112.0, 124.0, 134.0, 141.0]
	var rs := [17.5, 14.6, 11.6, 8.6, 6.2, 4.7, 4.2, 4.5, 5.7, 7.4, 8.8]
	var ws := [5.2, 4.4, 3.6, 2.7, 2.0, 1.5, 1.3, 1.4, 1.9, 2.5, 3.0]
	for leg in 3:
		var a := TAU * float(leg) / 3.0 + PI * 0.5
		var d := Vector3(cos(a), 0, sin(a))
		var t := Vector3(-d.z, 0, d.x)
		var pts: Array = [[], []]
		for i in ys.size():
			for s in 2:
				var sg := -1.0 if s == 0 else 1.0
				(pts[s] as Array).append(d * float(rs[i]) + t * float(ws[i]) * sg + Vector3(0, float(ys[i]), 0))
		for s in 2:
			var col: Array = pts[s]
			for i in col.size() - 1:
				lm.beam("White", col[i], col[i + 1], 1.5, 1.1, t)
		# Ladder rungs and X braces between the pair.
		for i in ys.size() - 1:
			var a0: Vector3 = (pts[0] as Array)[i]
			var b0: Vector3 = (pts[1] as Array)[i]
			var a1: Vector3 = (pts[0] as Array)[i + 1]
			var b1: Vector3 = (pts[1] as Array)[i + 1]
			lm.beam("White", a0, b0, 0.7, 0.7)
			lm.beam("White", a0, b1, 0.35, 0.35)
			lm.beam("White", b0, a1, 0.35, 0.35)
		# Foot: the anchor pier where the pair lands.
		lm.box("Base", d * 17.5 + Vector3(0, 0.8, 0), Vector3(13.0, 1.6, 3.6), Basis.looking_at(d))
		# Struts from the waist and the SkyLine level in to the core.
		for yi in [2, 6]:
			var p := d * float(rs[yi]) + Vector3(0, float(ys[yi]), 0)
			lm.beam("White", p, d * 3.2 + Vector3(0, float(ys[yi]), 0), 0.8, 0.8)
	# Tie rings joining the three legs (at the SkyLine level and waist).
	for yi in [2, 6, 9]:
		var y: float = ys[yi]
		for leg in 3:
			var a0 := TAU * float(leg) / 3.0 + PI * 0.5
			var a1 := a0 + TAU / 3.0
			lm.beam("White", Vector3(cos(a0), 0, sin(a0)) * float(rs[yi]) + Vector3(0, y, 0),
				Vector3(cos(a1), 0, sin(a1)) * float(rs[yi]) + Vector3(0, y, 0), 0.7, 0.7)
	# Core with the three elevator rails (glass cars on two of them).
	lm.frustum("Core", Vector3.ZERO, 3.2, 3.0, 150.0, 16)
	for k in 3:
		var a := TAU * float(k) / 3.0 + PI / 6.0
		var d := Vector3(cos(a), 0, sin(a))
		lm.box("White", d * 3.4 + Vector3(0, 75.0, 0), Vector3(1.6, 150.0, 0.6), Basis.looking_at(d), 0.0)
		lm.box("Glass", d * 4.2 + Vector3(0, 40.0 + 45.0 * k, 0), Vector3(2.4, 3.0, 1.8), Basis.looking_at(d))
	# SkyLine level (30 m): a round pavilion clamped round the core.
	lm.frustum("White", Vector3(0, 28.0, 0), 9.6, 9.6, 0.8, 32)
	lm.lathe("Glass", Vector3(0, 28.8, 0), PackedVector2Array([Vector2(9.2, 0.0), Vector2(9.2, 3.0)]),
		32, 1.0, 1.0, 0.0, true, false)
	LandmarkNaParts.ring_posts(lm, "White", Vector3(0, 28.8, 0), 9.25, 3.0, 24, 0.15, 0.15)
	lm.frustum("White", Vector3(0, 31.8, 0), 9.8, 9.6, 0.7, 32)
	_needle_top(lm)
	# Base plaza pad under the foundation.
	lm.frustum("Base", Vector3.ZERO, 20.0, 19.5, 0.3, 24)
	lm.commit(model)

## The Space Needle's top house, 138 m to the 184 m tip.
static func _needle_top(lm: LandmarkMesh) -> void:
	# Underside: the saucer cone with its radial ribs (the halo).
	lm.lathe("White", Vector3(0, 138.0, 0), PackedVector2Array([Vector2(6.0, 0.0), Vector2(12.0, 3.0),
		Vector2(18.0, 6.0), Vector2(21.0, 8.5), Vector2(21.6, 10.5)]), 48)
	for i in 36:
		var a := TAU * float(i) / 36.0
		var d := Vector3(cos(a), 0, sin(a))
		lm.beam("White", d * 6.5 + Vector3(0, 138.0, 0), d * 21.8 + Vector3(0, 148.4, 0), 0.45, 0.7,
			d.cross(Vector3.UP))
	# The Loupe (152 m): the revolving restaurant's glazing and mullions.
	lm.frustum("Glass", Vector3(0, 148.5, 0), 21.4, 21.4, 5.0, 48)
	LandmarkNaParts.ring_posts(lm, "White", Vector3(0, 148.5, 0), 21.45, 5.0, 48, 0.18, 0.15)
	lm.frustum("White", Vector3(0, 153.5, 0), 22.0, 22.0, 0.8, 48)
	# Observation deck (160 m): the tilted glass barrier panels outside
	# the inner glazing, under the gold roof's eave.
	lm.frustum("Glass", Vector3(0, 154.3, 0), 19.6, 19.6, 3.4, 48)
	for i in 48:
		var a := TAU * (float(i) + 0.5) / 48.0
		var d := Vector3(cos(a), 0, sin(a))
		var p0 := d * 21.8 + Vector3(0, 154.3, 0)
		var p1 := d * 22.5 + Vector3(0, 157.0, 0)
		lm.beam("White", p0, p1, 0.12, 0.12)
	lm.lathe("Glass", Vector3(0, 154.3, 0), PackedVector2Array([Vector2(21.8, 0.0), Vector2(22.5, 2.7)]),
		48, 1.0, 1.0, 0.0, true, false)
	# Galaxy Gold roof with its standing seams, the beacon housing and
	# the spire.
	lm.lathe("Gold", Vector3(0, 157.0, 0), PackedVector2Array([Vector2(22.6, 0.0), Vector2(22.8, 0.6),
		Vector2(20.0, 2.0), Vector2(14.0, 3.2), Vector2(6.0, 4.0)]), 48)
	for i in 24:
		var a := TAU * float(i) / 24.0
		var d := Vector3(cos(a), 0, sin(a))
		lm.beam("Gold", d * 22.6 + Vector3(0, 157.7, 0), d * 14.0 + Vector3(0, 160.35, 0), 0.25, 0.2)
		lm.beam("Gold", d * 14.0 + Vector3(0, 160.35, 0), d * 6.2 + Vector3(0, 161.15, 0), 0.25, 0.2)
	lm.frustum("White", Vector3(0, 161.0, 0), 5.0, 4.6, 2.6, 24)
	LandmarkNaParts.ring_rail(lm, "White", Vector3(0, 163.6, 0), 4.6, 1.0, 1.5)
	lm.frustum("Gold", Vector3(0, 163.6, 0), 3.6, 3.2, 1.6, 16)
	lm.lathe("White", Vector3(0, 165.2, 0), PackedVector2Array([Vector2(2.4, 0.0), Vector2(1.9, 3.0),
		Vector2(0.8, 9.0), Vector2(0.1, NEEDLE_TIP_M - 165.2)]), 12)
	for k in 3:
		LandmarkNaParts.ring(lm, "White", Vector3(0, 167.0 + 3.0 * k, 0), 2.0 - 0.35 * k, 0.3, 0.3, 12)

## The STRAT (Stratosphere Tower, 1996): the core and its three fluted
## concrete legs (the Y plan), the twelve-level pod flaring out at
## 250 m (the restaurant and the indoor and outdoor observation decks
## at 265 m) with the X-Scream see-saw and the Insanity crane arm on its
## roof, and the needle carrying the Big Shot ride's seat ring to the
## 350.2 m tip.
static func strat(model: Node3D) -> void:
	var lm := LandmarkMesh.new()
	lm.use("Concrete", LandmarkMaterials.pbr("concrete", "#C9C3B8", 5.0))
	lm.use("Glass", LandmarkMaterials.glass("#6A8494"))
	lm.use("Mast", LandmarkMaterials.paint("#D6D8DA", 0.4, 0.55))
	lm.use("Light", LandmarkMaterials.lit("#E9C46A", 0.5))
	lm.use("Ride", LandmarkMaterials.paint("#B8322A", 0.5, 0.4))
	# Legs: three tapering shafts with a vertical flute down each face.
	for k in 3:
		var a := TAU * float(k) / 3.0 + PI * 0.5
		var d := Vector3(cos(a), 0, sin(a))
		var leg := PackedVector2Array([Vector2(5.6, 0.0), Vector2(5.0, 120.0), Vector2(4.2, 250.0)])
		lm.lathe("Concrete", d * 7.0, leg, 18)
		for f in 3:
			var fa := a + (float(f) - 1.0) * 0.9
			var fd := Vector3(cos(fa), 0, sin(fa))
			lm.beam("Concrete", d * 7.0 + fd * 5.75, d * 7.0 + fd * 4.35 + Vector3(0, 248.0, 0), 0.9, 0.5,
				fd.cross(Vector3.UP))
		# Glass elevator band up the outer face of one leg.
		if k == 0:
			lm.beam("Glass", d * 12.7 + Vector3(0, 8.0, 0), d * 11.3 + Vector3(0, 246.0, 0), 2.4, 0.4,
				d.cross(Vector3.UP))
		lm.box("Concrete", d * 9.0 + Vector3(0, 2.0, 0), Vector3(12.0, 4.0, 9.0), Basis.looking_at(d))
	lm.frustum("Concrete", Vector3.ZERO, 7.0, 5.6, 254.0, 18)
	_strat_pod(lm, Vector3(0, 250.0, 0))
	# The needle: concrete lower mast, steel upper mast to the tip with the
	# Big Shot's four-sided seat ring and track.
	var top := Vector3(0, 280.0, 0)
	lm.lathe("Concrete", top, PackedVector2Array([Vector2(7.5, 0.0), Vector2(5.8, 22.0),
		Vector2(4.2, 45.0)]), 18)
	lm.lathe("Mast", top + Vector3(0, 45.0, 0), PackedVector2Array([Vector2(3.4, 0.0),
		Vector2(2.2, 9.0), Vector2(1.0, 18.0), Vector2(0.15, STRAT_TIP_M - 325.0)]), 12)
	for q in 4:
		var d := Vector3(cos(PI * 0.5 * q), 0, sin(PI * 0.5 * q))
		lm.beam("Mast", top + d * 6.4 + Vector3(0, 6.0, 0), top + d * 4.0 + Vector3(0, 46.0, 0), 0.5, 0.5)
		lm.box("Ride", top + d * 7.6 + Vector3(0, 10.0, 0), Vector3(5.4, 1.6, 1.6), Basis.looking_at(d))
	LandmarkNaParts.ring(lm, "Ride", top + Vector3(0, 9.0, 0), 7.2, 1.2, 0.6, 24)
	lm.frustum("Light", top + Vector3(0, 44.0, 0), 4.5, 4.5, 0.8, 16)
	lm.frustum("Concrete", Vector3.ZERO, 22.0, 21.5, 0.6, 18)
	lm.commit(model)

## The STRAT's pod: flared underside, two glazed restaurant levels with
## mullions, the open-air deck with its railing, the roof and its rides.
static func _strat_pod(lm: LandmarkMesh, pod: Vector3) -> void:
	lm.lathe("Concrete", pod, PackedVector2Array([Vector2(8.0, 0.0), Vector2(15.0, 3.0),
		Vector2(24.0, 8.0), Vector2(28.5, 10.0)]), 48)
	lm.frustum("Light", pod + Vector3(0, 8.0, 0), 25.6, 25.6, 0.5, 48)
	var y := 10.0
	for band in [[28.5, 4.0], [29.0, 4.0]]:
		var r: float = band[0]
		var h: float = band[1]
		lm.frustum("Concrete", pod + Vector3(0, y, 0), r + 0.3, r + 0.3, 0.7, 48)
		lm.lathe("Glass", pod + Vector3(0, y + 0.7, 0), PackedVector2Array([Vector2(r, 0.0),
			Vector2(r + 0.6, h)]), 48, 1.0, 1.0, 0.0, true, false)
		for i in 48:
			var a := TAU * float(i) / 48.0
			var d := Vector3(cos(a), 0, sin(a))
			lm.beam("Mast", pod + d * (r + 0.06) + Vector3(0, y + 0.7, 0),
				pod + d * (r + 0.66) + Vector3(0, y + 0.7 + h, 0), 0.15, 0.2, d.cross(Vector3.UP))
		y += 0.7 + h
	# Outdoor observation deck: set-back wall, deck slab, railing.
	lm.frustum("Concrete", pod + Vector3(0, y, 0), 30.4, 30.4, 0.6, 48)
	lm.frustum("Glass", pod + Vector3(0, y + 0.6, 0), 25.0, 25.0, 3.4, 48)
	LandmarkNaParts.ring_posts(lm, "Mast", pod + Vector3(0, y + 0.6, 0), 25.05, 3.4, 32, 0.2, 0.15)
	LandmarkNaParts.ring_rail(lm, "Mast", pod + Vector3(0, y + 0.6, 0), 30.0, 1.3, 2.0)
	LandmarkNaParts.ring_posts(lm, "Mast", pod + Vector3(0, y + 0.6, 0), 29.9, 3.2, 24, 0.2, 0.2)
	LandmarkNaParts.ring(lm, "Mast", pod + Vector3(0, y + 3.8, 0), 29.9, 0.3, 0.2, 48)
	lm.lathe("Concrete", pod + Vector3(0, y + 4.0, 0), PackedVector2Array([Vector2(26.0, 0.0),
		Vector2(25.0, 4.0), Vector2(14.0, 6.0), Vector2(7.5, 6.6)]), 48)
	# X-Scream: a see-saw track cantilevered 8 m past the pod's edge.
	var roof := pod + Vector3(0, y + 4.6, 0)
	lm.beam("Ride", roof + Vector3(-6.0, 1.0, 0), roof + Vector3(-37.0, -1.5, 0), 1.2, 0.8)
	lm.box("Ride", roof + Vector3(-34.0, -0.4, 0), Vector3(4.0, 1.4, 2.0))
	lm.beam("Mast", roof + Vector3(-6.0, 0.0, -1.2), roof + Vector3(-6.0, 2.4, -1.2), 0.6, 0.6)
	lm.beam("Mast", roof + Vector3(-6.0, 0.0, 1.2), roof + Vector3(-6.0, 2.4, 1.2), 0.6, 0.6)
	# Insanity: the crane arm reaching 20 m out with its hanging seats.
	var pivot := roof + Vector3(0, 1.2, 9.0)
	lm.frustum("Mast", roof + Vector3(0, -1.0, 9.0), 1.4, 1.2, 3.0, 12)
	lm.beam("Ride", pivot + Vector3(0, 1.0, 0), pivot + Vector3(0, 4.0, 30.0), 1.0, 1.0)
	for k in 5:
		var s := pivot + Vector3((float(k) - 2.0) * 1.2, 4.0, 30.0)
		lm.beam("Mast", s, s + Vector3(0, -4.0, 0), 0.12, 0.12)
		lm.box("Ride", s + Vector3(0, -4.5, 0), Vector3(0.8, 1.0, 0.8), Basis(), 0.0)
