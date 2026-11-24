class_name SculptureKit
extends RefCounted

## High-resolution anatomical & sculptural geometry builders on LandmarkMesh.
## Uses quaternion parallel-transport frames, rounded dome end-caps, and
## per-ring analytical outward normals (`emit_rings`) so curved limbs, ankles,
## flippers, wings, and contrapposto torsos never twist, tear, or show flat seams
## even in 1920x1200 eye-level close-ups.

## Emits a closed periodic tube/surface from cross-section `rows` around per-ring
## `centers`. Wraps U normals seamlessly across `i == 0 / segs` and orients every
## vertex normal strictly outward from its own ring centre `centers[j]`.
static func emit_rings(lm: LandmarkMesh, key: String, centers: PackedVector3Array,
		rows: Array) -> void:
	var nv := rows.size()
	if nv < 2 or centers.size() != nv:
		return
	var nu := (rows[0] as PackedVector3Array).size()
	if nu < 3:
		return
	var segs := nu - 1
	var closed_u := (rows[0] as PackedVector3Array)[0].distance_to((rows[0] as PackedVector3Array)[segs]) < 0.004 \
		and (rows[nv / 2] as PackedVector3Array)[0].distance_to((rows[nv / 2] as PackedVector3Array)[segs]) < 0.004
	var norms: Array = []
	var axis_end0 := (centers[0] - centers[mini(1, nv - 1)]).normalized()
	var axis_end1 := (centers[nv - 1] - centers[maxi(nv - 2, 0)]).normalized()
	for j in nv:
		var row: PackedVector3Array = rows[j]
		var c := centers[j]
		var nr := PackedVector3Array()
		for i in nu:
			var idx := (i % segs) if (closed_u and i == segs) else i
			var ip := ((idx - 1 + segs) % segs) if closed_u else maxi(idx - 1, 0)
			var inx := ((idx + 1) % segs) if closed_u else mini(idx + 1, nu - 1)
			var du := row[inx] - row[ip]
			var dv := (rows[mini(j + 1, nv - 1)] as PackedVector3Array)[idx] \
				- (rows[maxi(j - 1, 0)] as PackedVector3Array)[idx]
			var rad := row[idx] - c
			var is_pole := (j == 0 or j == nv - 1) and rad.length_squared() < 1e-4
			var n: Vector3
			if is_pole:
				n = axis_end0 if j == 0 else axis_end1
			else:
				n = du.cross(dv)
				if n.length_squared() < 1e-10:
					n = rad.normalized() if rad.length_squared() > 1e-8 else (axis_end0 if j == 0 else axis_end1)
				else:
					n = n.normalized()
					var hint := rad if rad.length_squared() > 1e-8 else (axis_end0 if j == 0 else axis_end1)
					if hint.length_squared() > 1e-10 and n.dot(hint) < 0.0:
						n = -n
			nr.append(n if n.length_squared() > 0.1 else Vector3.UP)
		norms.append(nr)

	var vacc := PackedFloat32Array()
	vacc.resize(nu)
	for j in nv - 1:
		var r0: PackedVector3Array = rows[j]
		var r1: PackedVector3Array = rows[j + 1]
		var n0: PackedVector3Array = norms[j]
		var n1: PackedVector3Array = norms[j + 1]
		var u0 := 0.0
		for i in segs:
			var step_u := maxf(r0[i].distance_to(r0[i + 1]), r1[i].distance_to(r1[i + 1]))
			var u1 := u0 + step_u
			var va := vacc[i]
			var vb := vacc[i + 1]
			var vc := vb + r0[i + 1].distance_to(r1[i + 1])
			var vd := va + r0[i].distance_to(r1[i])
			if r0[i].distance_squared_to(r0[i + 1]) > 1e-10:
				lm.tri(key, r0[i], r0[i + 1], r1[i + 1], n0[i], n0[i + 1], n1[i + 1],
					Vector2(u0, va), Vector2(u1, vb), Vector2(u1, vc))
			if r1[i].distance_squared_to(r1[i + 1]) > 1e-10:
				lm.tri(key, r0[i], r1[i + 1], r1[i], n0[i], n1[i + 1], n1[i],
					Vector2(u0, va), Vector2(u1, vc), Vector2(u0, vd))
			u0 = u1
		for i in nu:
			vacc[i] += r0[i].distance_to(r1[i])

## Lofts a smooth organic surface along `spine` using quaternion parallel-transport
## frames (twist-free on 3D bends) and rounded ellipsoid dome caps (`cap_ends = true`)
## so shoulders, muzzles, hands, and flippers never end in flat razor-sharp discs.
static func loft_tube(lm: LandmarkMesh, key: String, spine: PackedVector3Array,
		radii: PackedVector2Array, segs: int = 16, cap_ends: bool = true) -> void:
	var n := spine.size()
	if n < 2 or radii.size() != n:
		return
	var tangents := PackedVector3Array()
	var sides := PackedVector3Array()
	var fwds := PackedVector3Array()
	for j in n:
		var t_dir: Vector3
		if j == 0:
			t_dir = spine[1] - spine[0]
		elif j == n - 1:
			t_dir = spine[n - 1] - spine[n - 2]
		else:
			t_dir = spine[j + 1] - spine[j - 1]
		t_dir = t_dir.normalized() if t_dir.length_squared() > 1e-8 else Vector3.UP
		tangents.append(t_dir)
		var side: Vector3
		if j == 0:
			var ref := Vector3.FORWARD if absf(t_dir.x) > 0.9 else Vector3.RIGHT
			side = (ref - t_dir * ref.dot(t_dir)).normalized()
		else:
			var q := Quaternion(tangents[j - 1], t_dir)
			side = (q * sides[j - 1])
			side = (side - t_dir * side.dot(t_dir)).normalized()
		if side.length_squared() < 0.001:
			side = Vector3.RIGHT
		sides.append(side)
		fwds.append(side.cross(t_dir).normalized())

	var centers := PackedVector3Array()
	var rows: Array = []
	var make_ring := func(c: Vector3, sd: Vector3, fd: Vector3, rx: float, rz: float) -> PackedVector3Array:
		var row := PackedVector3Array()
		for i in segs + 1:
			var a := TAU * float(i) / float(segs) if i < segs else 0.0
			row.append(c + sd * (cos(a) * rx) + fd * (sin(a) * rz))
		return row

	# Smooth rounded dome cap at start
	if cap_ends and (radii[0].x > 0.003 or radii[0].y > 0.003):
		var d0 := minf(minf(radii[0].x, radii[0].y) * 0.65, spine[0].distance_to(spine[1]) * 0.45)
		var c_apex := spine[0] - tangents[0] * d0
		centers.append(c_apex)
		rows.append(make_ring.call(c_apex, sides[0], fwds[0], 0.0004, 0.0004))
		var c_mid := spine[0] - tangents[0] * (d0 * 0.55)
		centers.append(c_mid)
		rows.append(make_ring.call(c_mid, sides[0], fwds[0], radii[0].x * 0.68, radii[0].y * 0.68))

	for j in n:
		var rx := maxf(radii[j].x, 0.0008)
		var rz := maxf(radii[j].y, 0.0008)
		centers.append(spine[j])
		rows.append(make_ring.call(spine[j], sides[j], fwds[j], rx, rz))

	# Smooth rounded dome cap at end
	if cap_ends and (radii[n - 1].x > 0.003 or radii[n - 1].y > 0.003):
		var d1 := minf(minf(radii[n - 1].x, radii[n - 1].y) * 0.65, spine[n - 1].distance_to(spine[n - 2]) * 0.45)
		var c_mid := spine[n - 1] + tangents[n - 1] * (d1 * 0.55)
		centers.append(c_mid)
		rows.append(make_ring.call(c_mid, sides[n - 1], fwds[n - 1], radii[n - 1].x * 0.68, radii[n - 1].y * 0.68))
		var c_apex := spine[n - 1] + tangents[n - 1] * d1
		centers.append(c_apex)
		rows.append(make_ring.call(c_apex, sides[n - 1], fwds[n - 1], 0.0004, 0.0004))

	emit_rings(lm, key, centers, rows)

## High-detail sculpted human head (14 rings x 28 segments) with 3D facial relief:
## oval chin & jawline, Cupid's-bow lips, nose bridge & alae, recessed orbital eye
## sockets under smooth brow arches, cheekbones, ears, and carved wavy hair swept
## naturally over the crown and nape (no hanging tusk tubes).
static func sculpted_head(lm: LandmarkMesh, key: String, base: Vector3, h: float,
		yaw: float = 0.0, long_hair: bool = false, tilt_x: float = 0.0) -> void:
	var rot := Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, tilt_x)
	var centers := PackedVector3Array()
	var rows: Array = []
	var segs := 28
	var prof := [
		# [y_frac, rx_frac, rz_frac, cz_frac]
		[0.00, 0.16, 0.17, -0.02], # neck transition
		[0.09, 0.22, 0.28,  0.01], # chin / submental
		[0.17, 0.26, 0.32,  0.01], # labiomental hollow
		[0.24, 0.29, 0.34,  0.01], # lower lip
		[0.30, 0.30, 0.35,  0.01], # upper lip
		[0.37, 0.33, 0.37,  0.00], # subnasale / cheek
		[0.45, 0.35, 0.39,  0.00], # nose tip / cheekbone
		[0.53, 0.35, 0.38, -0.01], # nose bridge / eye sockets
		[0.61, 0.36, 0.41, -0.01], # supraorbital brow arch
		[0.70, 0.36, 0.42, -0.02], # forehead
		[0.80, 0.34, 0.40, -0.03], # hairline / crown
		[0.89, 0.27, 0.33, -0.03], # upper cranium
		[0.96, 0.16, 0.20, -0.03], # dome
		[1.00, 0.002, 0.002, -0.03], # apex
	]
	for j in prof.size():
		var q: Array = prof[j]
		var y := float(q[0]) * h
		var rx := float(q[1]) * h
		var rz := float(q[2]) * h
		var cz := float(q[3]) * h
		centers.append(base + rot * Vector3(0.0, y, cz))
		var row := PackedVector3Array()
		for i in segs + 1:
			var a := TAU * float(i) / float(segs) if i < segs else 0.0
			var ca := cos(a)
			var sa := sin(a) # +1 front (+Z), -1 occiput (-Z)
			var lx := ca * rx
			var lz := cz + sa * rz
			if sa > 0.12 and j < 13:
				var mid := exp(-pow(ca / 0.15, 2.0))
				var eye_band := exp(-pow((absf(ca) - 0.34) / 0.14, 2.0))
				var cheek := exp(-pow((absf(ca) - 0.56) / 0.22, 2.0))
				if j == 1:
					lz += h * 0.040 * exp(-pow(ca / 0.26, 2.0))
				elif j == 3 or j == 4:
					lz += h * 0.032 * exp(-pow(ca / 0.22, 2.0))
				elif j == 6:
					lz += h * 0.088 * mid + h * 0.020 * cheek
					lx *= 1.0 + 0.04 * cheek
				elif j == 7:
					lz += h * 0.064 * mid - h * 0.034 * eye_band
				elif j == 8:
					lz += h * 0.038 * exp(-pow(ca / 0.50, 2.0))
			if absf(ca) > 0.90 and absf(sa) < 0.34 and j >= 5 and j <= 8:
				lx += signf(ca) * h * 0.032
			# Carved wavy hair locks framing temples, crown, and swept back over nape
			var hair_mask := clampf((-sa + 0.18) * 1.35, 0.0, 1.0) if j < 10 else (1.0 if j < 13 else 0.0)
			if hair_mask > 0.01 and j >= 2 and j <= 12:
				var locks := 0.5 + 0.5 * sin(a * 11.0 + float(j) * 0.9)
				var swell := (0.095 if long_hair else 0.048) * hair_mask * (0.65 + 0.70 * locks)
				lx *= 1.0 + swell * 0.80
				lz -= h * swell * (1.05 if sa < 0.0 else -0.25)
			row.append(base + rot * Vector3(lx, y, lz))
		rows.append(row)
	emit_rings(lm, key, centers, rows)

	if long_hair:
		# Swept-back Art Nouveau / classical chignon & wavy hair mass resting on occiput & nape
		var chig := PackedVector3Array([
			base + rot * Vector3(0.0, h * 0.64, -h * 0.28),
			base + rot * Vector3(0.0, h * 0.46, -h * 0.52),
			base + rot * Vector3(0.0, h * 0.22, -h * 0.46),
			base + rot * Vector3(0.0, -h * 0.06, -h * 0.30),
		])
		loft_tube(lm, key, chig, PackedVector2Array([
			Vector2(h * 0.28, h * 0.18), Vector2(h * 0.27, h * 0.22),
			Vector2(h * 0.22, h * 0.17), Vector2(h * 0.14, h * 0.10),
		]), 16)

## Articulated hand: sculpted palm, thumb and gracefully curved finger cluster.
static func _hand(lm: LandmarkMesh, key: String, wrist: Vector3, dir: Vector3,
		up_hint: Vector3, scale_h: float, side_sign: float) -> void:
	var fwd := dir.normalized()
	var side := fwd.cross(up_hint).normalized()
	if side.length_squared() < 0.001:
		side = Vector3.RIGHT
	var normal := side.cross(fwd).normalized()
	var palm_mid := wrist + fwd * (scale_h * 0.022)
	var palm_end := wrist + fwd * (scale_h * 0.044)
	var fingers_end := palm_end + fwd * (scale_h * 0.036) - normal * (scale_h * 0.010)
	loft_tube(lm, key, PackedVector3Array([wrist, palm_mid, palm_end, fingers_end]), PackedVector2Array([
		Vector2(scale_h * 0.019, scale_h * 0.015),
		Vector2(scale_h * 0.025, scale_h * 0.014),
		Vector2(scale_h * 0.024, scale_h * 0.012),
		Vector2(scale_h * 0.015, scale_h * 0.008),
	]), 12)
	var thumb_end := wrist + fwd * (scale_h * 0.034) + side * (side_sign * scale_h * 0.024)
	loft_tube(lm, key, PackedVector3Array([wrist + fwd * (scale_h * 0.010), thumb_end]), PackedVector2Array([
		Vector2(scale_h * 0.010, scale_h * 0.010), Vector2(scale_h * 0.006, scale_h * 0.006),
	]), 8)

## Classical / Baroque draped standing statue: ONE continuous 20-ring x 32-segment
## sculpted surface from fluted chiton hem through diagonal himation folds, waist,
## chest, and shoulder mantle up to the neck (no detached sash cylinder!), plus
## peeking sandals, deeply socketed arms, articulated hands, and 28-seg head.
static func classical_figure(lm: LandmarkMesh, key: String, base: Vector3, h: float,
		arm_up: bool = false, yaw: float = 0.0) -> void:
	if h <= 0.15:
		return
	var rot := Basis(Vector3.UP, yaw)
	var p := func(v: Vector3) -> Vector3: return base + rot * v

	var prof := [
		# [y_frac, cx, cz, rx, rz, pleat_amp]
		[0.005,  0.000,  0.000, 0.158, 0.138, 1.00],
		[0.080, -0.002,  0.002, 0.150, 0.132, 1.00],
		[0.180, -0.006,  0.004, 0.138, 0.120, 0.95],
		[0.280, -0.010,  0.008, 0.128, 0.110, 0.90], # contrapposto knee zone
		[0.380, -0.012,  0.005, 0.120, 0.100, 0.82],
		[0.470, -0.010,  0.000, 0.116, 0.092, 0.72], # draped hips
		[0.545, -0.006,  0.002, 0.102, 0.082, 0.60], # gathered waist / belt fold
		[0.605, -0.002,  0.006, 0.108, 0.086, 0.50], # lower ribcage
		[0.665,  0.003,  0.010, 0.122, 0.092, 0.44], # chest / diagonal toga folds
		[0.715,  0.006,  0.006, 0.132, 0.088, 0.36], # upper chest
		[0.745,  0.006,  0.000, 0.138, 0.080, 0.25], # broad shoulder / deltoid mantle
		[0.775,  0.004, -0.004, 0.096, 0.062, 0.12], # trapezius slope
		[0.805,  0.001, -0.006, 0.044, 0.042, 0.00], # neck base
		[0.835,  0.000, -0.006, 0.034, 0.035, 0.00], # mid neck
		[0.860,  0.000, -0.006, 0.032, 0.033, 0.00], # upper neck into jaw
	]
	var b_segs := 32
	var b_centers := PackedVector3Array()
	var b_rows: Array = []
	for j in prof.size():
		var q: Array = prof[j]
		var yf := float(q[0])
		var cx := float(q[1]) * h
		var cz := float(q[2]) * h
		var rx := float(q[3]) * h
		var rz := float(q[4]) * h
		var pw := float(q[5])
		b_centers.append(p.call(Vector3(cx, yf * h, cz)))
		var row := PackedVector3Array()
		for i in b_segs + 1:
			var a := TAU * float(i) / float(b_segs) if i < b_segs else 0.0
			var ca := cos(a)
			var sa := sin(a)
			# Deeply carved vertical chiton flutes + sweeping diagonal himation folds integrated into mesh!
			var flute := 0.165 * (1.0 - absf(sin(a * 5.0 + yf * 1.4))) + 0.065 * sin(a * 10.0 - yf * 2.4)
			var diag_fold := 0.135 * pow(maxf(sin(a + yf * 4.4 - 0.8), 0.0), 2.0) if yf >= 0.30 and yf <= 0.76 else 0.0
			var mod := 1.0 + (flute + diag_fold) * pw
			# Right bent knee pressing gracefully forward under the drapery
			var knee := 1.0 + 0.16 * exp(-pow((yf - 0.28) / 0.10, 2.0)) * pow(maxf(sin(a - 0.35), 0.0), 2.0)
			row.append(p.call(Vector3(cx + ca * rx * mod, yf * h, cz + sa * rz * mod * knee)))
		b_rows.append(row)
	emit_rings(lm, key, b_centers, b_rows)

	# Peeking sculpted sandals/feet under the front hem
	for s in [-1.0, 1.0]:
		var sf := float(s)
		var foot_z := h * (0.148 if sf > 0.0 else 0.128)
		loft_tube(lm, key, PackedVector3Array([
			p.call(Vector3(sf * h * 0.052, h * 0.024, foot_z * 0.35)),
			p.call(Vector3(sf * h * 0.060, h * 0.016, foot_z)),
		]), PackedVector2Array([
			Vector2(h * 0.030, h * 0.022), Vector2(h * 0.025, h * 0.014),
		]), 10)

	# Sculpted head
	sculpted_head(lm, key, p.call(Vector3(0.0, h * 0.842, -h * 0.004)), h * 0.158,
		yaw + (0.12 if arm_up else -0.08), true, -0.04)

	# Deeply socketed arms (root tucked well inside shoulder mantle -> zero gap!)
	var arm_r := PackedVector2Array([
		Vector2(h * 0.048, h * 0.046), Vector2(h * 0.044, h * 0.042),
		Vector2(h * 0.035, h * 0.034), Vector2(h * 0.029, h * 0.028),
		Vector2(h * 0.021, h * 0.020),
	])
	var lw: Vector3 = p.call(Vector3(-h * 0.092, h * 0.535, h * 0.102))
	loft_tube(lm, key, PackedVector3Array([
		p.call(Vector3(-h * 0.078, h * 0.738, 0.0)),
		p.call(Vector3(-h * 0.126, h * 0.726, 0.0)),
		p.call(Vector3(-h * 0.154, h * 0.635, -0.008 * h)),
		p.call(Vector3(-h * 0.136, h * 0.568, 0.048 * h)),
		lw,
	]), arm_r, 14)
	_hand(lm, key, lw, (p.call(Vector3(-h * 0.048, h * 0.515, h * 0.148)) as Vector3) - lw, Vector3.UP, h, -1.0)

	var rw: Vector3
	var r_dir: Vector3
	var r_arm: PackedVector3Array
	if arm_up:
		rw = p.call(Vector3(h * 0.132, h * 0.915, h * 0.082))
		r_dir = ((p.call(Vector3(h * 0.105, h * 0.978, h * 0.090)) as Vector3) - rw).normalized()
		r_arm = PackedVector3Array([
			p.call(Vector3(h * 0.078, h * 0.740, 0.0)),
			p.call(Vector3(h * 0.128, h * 0.748, 0.012 * h)),
			p.call(Vector3(h * 0.168, h * 0.798, 0.038 * h)),
			p.call(Vector3(h * 0.158, h * 0.860, 0.066 * h)),
			rw,
		])
	else:
		rw = p.call(Vector3(h * 0.114, h * 0.568, h * 0.128))
		r_dir = ((p.call(Vector3(h * 0.080, h * 0.575, h * 0.176)) as Vector3) - rw).normalized()
		r_arm = PackedVector3Array([
			p.call(Vector3(h * 0.078, h * 0.738, 0.0)),
			p.call(Vector3(h * 0.128, h * 0.728, 0.008 * h)),
			p.call(Vector3(h * 0.158, h * 0.642, 0.025 * h)),
			p.call(Vector3(h * 0.144, h * 0.588, 0.078 * h)),
			rw,
		])
	loft_tube(lm, key, r_arm, arm_r, 14)
	_hand(lm, key, rw, r_dir, Vector3.UP, h, 1.0)

## Seamless anatomical contrapposto nude (Ville Vallgren's Havis Amanda):
## Swirling bronze wave mound, sculpted feet/ankles/calves/thighs whose hip roots
## taper smoothly INSIDE the fuller sculpted pelvis/gluteal envelope (zero hip shelf!),
## continuous 17-ring x 32-seg pelvis->waist->bust->clavicle->neck surface, and
## deeply socketed deltoid shoulders (zero shoulder gap!).
static func contrapposto_nude(lm: LandmarkMesh, key: String, base: Vector3, h: float,
		yaw: float = 0.0) -> void:
	var rot := Basis(Vector3.UP, yaw)
	var p := func(v: Vector3) -> Vector3: return base + rot * v

	# Swirling Art Nouveau bronze wave & sea-foam mound under her feet (closed smooth dome)
	var w_centers := PackedVector3Array()
	var w_rows: Array = []
	var w_prof := [
		[0.000, 0.215], [0.022, 0.205], [0.048, 0.168],
		[0.072, 0.115], [0.088, 0.055], [0.094, 0.002],
	]
	for j in w_prof.size():
		var yf := float((w_prof[j] as Array)[0])
		var rw := float((w_prof[j] as Array)[1]) * h
		w_centers.append(p.call(Vector3(0.0, yf * h, 0.0)))
		var row := PackedVector3Array()
		for i in 29:
			var a := TAU * float(i) / 28.0 if i < 28 else 0.0
			var curl := (1.0 + 0.14 * sin(a * 5.0 + yf * 18.0)) if j < 5 else 1.0
			row.append(p.call(Vector3(cos(a) * rw * curl, yf * h, sin(a) * rw * curl)))
		w_rows.append(row)
	emit_rings(lm, key, w_centers, w_rows)

	# Anatomical legs: toes & heel nestled firmly in the wave mound, rising through
	# slender ankles, gastrocnemius calves, patella knees, and full thighs whose upper
	# hip roots angle INWARD inside the wider sculpted pelvis (zero outer shelf!).
	var leg_radii := PackedVector2Array([
		Vector2(h * 0.024, h * 0.016), # forefoot / toes
		Vector2(h * 0.028, h * 0.038), # instep / heel
		Vector2(h * 0.025, h * 0.028), # malleolus ankle
		Vector2(h * 0.036, h * 0.040), # lower shin
		Vector2(h * 0.045, h * 0.049), # gastrocnemius calf belly
		Vector2(h * 0.038, h * 0.041), # knee patella
		Vector2(h * 0.050, h * 0.054), # mid-thigh
		Vector2(h * 0.055, h * 0.060), # upper thigh (outer x = ~0.102*h)
		Vector2(h * 0.052, h * 0.058), # trochanter blend into hip
		Vector2(h * 0.038, h * 0.044), # deep hip-socket root (enclosed inside pelvis)
	])
	var leg_l := PackedVector3Array([
		p.call(Vector3(-h * 0.046, h * 0.042, h * 0.082)),
		p.call(Vector3(-h * 0.048, h * 0.055, h * 0.015)),
		p.call(Vector3(-h * 0.050, h * 0.095, -h * 0.006)),
		p.call(Vector3(-h * 0.053, h * 0.155, -h * 0.016)),
		p.call(Vector3(-h * 0.055, h * 0.215, -h * 0.020)),
		p.call(Vector3(-h * 0.051, h * 0.290, h * 0.004)),
		p.call(Vector3(-h * 0.051, h * 0.368, h * 0.004)),
		p.call(Vector3(-h * 0.048, h * 0.436, -h * 0.002)),
		p.call(Vector3(-h * 0.042, h * 0.484, -h * 0.006)),
		p.call(Vector3(-h * 0.032, h * 0.526, -h * 0.008)),
	])
	loft_tube(lm, key, leg_l, leg_radii, 18)

	var leg_r := PackedVector3Array([
		p.call(Vector3(h * 0.058, h * 0.042, h * 0.048)),
		p.call(Vector3(h * 0.060, h * 0.058, -h * 0.014)),
		p.call(Vector3(h * 0.062, h * 0.098, -h * 0.022)),
		p.call(Vector3(h * 0.064, h * 0.160, -h * 0.014)),
		p.call(Vector3(h * 0.064, h * 0.215, -h * 0.004)),
		p.call(Vector3(h * 0.057, h * 0.288, h * 0.042)),
		p.call(Vector3(h * 0.053, h * 0.364, h * 0.028)),
		p.call(Vector3(h * 0.047, h * 0.434, h * 0.012)),
		p.call(Vector3(h * 0.040, h * 0.482, 0.000)),
		p.call(Vector3(h * 0.030, h * 0.524, -h * 0.006)),
	])
	loft_tube(lm, key, leg_r, leg_radii, 18)

	# Continuous sculpted pelvis -> waist -> ribcage/bust -> shoulders -> slender neck (17 rings x 32 segs)
	var t_centers := PackedVector3Array()
	var t_rows: Array = []
	var t_segs := 32
	var t_prof := [
		# [y_frac, cx, cz, rx, rz] — smooth continuous line from outer thigh (~0.102) through hip to waist
		[0.432,  0.000, -0.006, 0.003, 0.003], # closed perineal apex tucked between inner thighs
		[0.448, -0.001, -0.007, 0.046, 0.054], # lower pubic / gluteal wedge (narrower than thighs!)
		[0.472, -0.003, -0.008, 0.082, 0.070], # inner hip blend
		[0.498, -0.006, -0.010, 0.101, 0.076], # smooth greater-trochanter / hip continuation
		[0.528, -0.008, -0.009, 0.100, 0.074], # iliac crest
		[0.558, -0.007, -0.006, 0.085, 0.064], # lower abdomen
		[0.592, -0.005, -0.002, 0.072, 0.056], # slender arched waist
		[0.625, -0.001,  0.003, 0.080, 0.062], # lower ribcage
		[0.655,  0.003,  0.006, 0.089, 0.068], # under-bust
		[0.686,  0.005,  0.008, 0.095, 0.071], # mid-bust contour
		[0.716,  0.006,  0.003, 0.098, 0.066], # upper chest
		[0.742,  0.007, -0.004, 0.116, 0.062], # clavicle & rounded deltoid span
		[0.768,  0.005, -0.009, 0.082, 0.050], # trapezius slope
		[0.794,  0.002, -0.013, 0.038, 0.036], # graceful neck base
		[0.825,  0.001, -0.016, 0.029, 0.030], # slender mid neck
		[0.856,  0.000, -0.018, 0.028, 0.029], # upper neck into chin/jaw
	]
	for j in t_prof.size():
		var q: Array = t_prof[j]
		var yf := float(q[0])
		var cx := float(q[1]) * h
		var cz := float(q[2]) * h
		var rx := float(q[3]) * h
		var rz := float(q[4]) * h
		t_centers.append(p.call(Vector3(cx, yf * h, cz)))
		var row := PackedVector3Array()
		for i in t_segs + 1:
			var a := TAU * float(i) / float(t_segs) if i < t_segs else 0.0
			var ca := cos(a)
			var sa := sin(a)
			var lx := ca * rx
			var lz := sa * rz
			if j > 0:
				# Natural integrated bust relief (y = 0.64..0.73)
				if sa > 0.15 and yf >= 0.64 and yf <= 0.73:
					var by := sin((yf - 0.64) / 0.09 * PI)
					var breasts := exp(-pow((absf(ca) - 0.45) / 0.24, 2.0))
					lz += h * 0.038 * by * breasts * sa
					lx *= 1.0 + 0.04 * by * breasts
				# Rounded posterior gluteal lobes (y = 0.45..0.53, sa < -0.15)
				if sa < -0.15 and yf >= 0.45 and yf <= 0.535:
					var gy := sin((yf - 0.45) / 0.085 * PI)
					var glutes := exp(-pow((absf(ca) - 0.38) / 0.26, 2.0))
					lz -= h * 0.028 * gy * glutes * (-sa)
				# Subtle lumbar & thoracic spinal furrow down the back midline
				if sa < -0.65 and yf >= 0.50 and yf <= 0.75:
					lz += h * 0.011 * exp(-pow(ca / 0.14, 2.0))
			row.append(p.call(Vector3(cx + lx, yf * h, cz + lz)))
		t_rows.append(row)
	emit_rings(lm, key, t_centers, t_rows)

	# Vallgren's youthful head tilted subtly upward, wavy Art Nouveau hair swept over nape
	sculpted_head(lm, key, p.call(Vector3(0.0, h * 0.846, -h * 0.018)), h * 0.154,
		yaw + 0.16, true, -0.11)

	# Deeply socketed anatomical arms + articulated hands (shoulder root well inside chest -> zero air gap!)
	var arm_r := PackedVector2Array([
		Vector2(h * 0.040, h * 0.038), # deep chest root
		Vector2(h * 0.036, h * 0.034), # deltoid ball
		Vector2(h * 0.028, h * 0.027), # upper arm / elbow
		Vector2(h * 0.024, h * 0.023), # forearm
		Vector2(h * 0.017, h * 0.016), # slender wrist
	])
	var lw: Vector3 = p.call(Vector3(-h * 0.106, h * 0.520, -h * 0.032))
	loft_tube(lm, key, PackedVector3Array([
		p.call(Vector3(-h * 0.068, h * 0.738, -h * 0.006)),
		p.call(Vector3(-h * 0.112, h * 0.730, -h * 0.010)),
		p.call(Vector3(-h * 0.150, h * 0.648, -h * 0.042)),
		p.call(Vector3(-h * 0.140, h * 0.578, -h * 0.045)),
		lw,
	]), arm_r, 16)
	_hand(lm, key, lw, (p.call(Vector3(-h * 0.075, h * 0.482, -h * 0.012)) as Vector3) - lw, Vector3.FORWARD, h * 0.82, -1.0)

	var rw: Vector3 = p.call(Vector3(h * 0.108, h * 0.848, h * 0.024))
	loft_tube(lm, key, PackedVector3Array([
		p.call(Vector3(h * 0.070, h * 0.742, -h * 0.004)),
		p.call(Vector3(h * 0.114, h * 0.738, 0.004 * h)),
		p.call(Vector3(h * 0.168, h * 0.742, 0.030 * h)),
		p.call(Vector3(h * 0.154, h * 0.798, 0.042 * h)),
		rw,
	]), arm_r, 16)
	_hand(lm, key, rw, (p.call(Vector3(h * 0.060, h * 0.882, -h * 0.018)) as Vector3) - rw, Vector3.UP, h * 0.82, 1.0)

## Winged angel sculpture (Emma Stebbins' Bethesda *Angel of the Waters*):
## Draped Neo-Classical figure with FULL, broad, closed 3D cambered feathered wings
## (front & back plumage lofted as closed airfoil rings so `cull_back` never hides them!).
static func winged_angel(lm: LandmarkMesh, key: String, base: Vector3, h: float,
		yaw: float = 0.0) -> void:
	var fig_h := h * 0.84
	classical_figure(lm, key, base, fig_h, false, yaw)
	var rot := Basis(Vector3.UP, yaw)
	var p := func(v: Vector3) -> Vector3: return base + rot * v

	for side in [-1.0, 1.0]:
		var s := float(side)
		# Closed 3D cambered feathered wing: 18 span stations so individual primary & secondary
		# flight feather tips step cleanly along the sweeping trailing edge!
		var span_n := 18
		var chord_segs := 22
		var w_centers := PackedVector3Array()
		var w_rows: Array = []
		for j in span_n:
			var u := float(j) / float(span_n - 1)
			var lead_x := s * fig_h * (0.045 + pow(u, 0.82) * 0.46)
			var lead_y := minf(fig_h * (0.71 + sin(u * PI * 0.62) * 0.48), h * 0.995)
			var lead_z := -fig_h * (0.045 + u * 0.24 + sin(u * PI) * 0.07)
			var tip_taper := sin(acos(clampf(u * 0.985, 0.0, 0.9995)))
			var feather_scallop := 1.0 + 0.16 * absf(sin(u * PI * 7.5)) * smoothstep(0.15, 0.85, u)
			var chord := fig_h * (0.28 + 0.30 * sin(u * PI * 0.76)) * feather_scallop * maxf(tip_taper, 0.02)
			var thick := fig_h * lerpf(0.036, 0.010, u) * maxf(tip_taper, 0.04)
			w_centers.append(p.call(Vector3(lead_x, lead_y - chord * 0.45, lead_z - chord * 0.08)))
			var row := PackedVector3Array()
			for i in chord_segs + 1:
				var a := TAU * float(i) / float(chord_segs) if i < chord_segs else 0.0
				var v_c := 0.5 * (1.0 - cos(a))
				var side_f := sin(a)
				# 3 overlapping plumage tiers (coverts, secondaries, primaries) + deep feather vanes
				var tier := 0.012 * fig_h * (sin(v_c * PI * 3.0) * 0.5 + 0.5) * tip_taper
				var vane := 0.016 * fig_h * (0.5 + 0.5 * sin(u * PI * 15.0 + v_c * 2.0)) * v_c * tip_taper
				var thickness_env := thick * (1.0 - 0.72 * v_c) + tier + vane
				var px := lead_x - s * v_c * chord * 0.12 + s * side_f * thickness_env * 0.35
				var py := lead_y - v_c * chord
				var pz := lead_z - v_c * chord * 0.18 + sin(v_c * PI) * fig_h * 0.038 + side_f * thickness_env
				row.append(p.call(Vector3(px, py, pz)))
			w_rows.append(row)
		emit_rings(lm, key, w_centers, w_rows)

## Heroic muscular Triton / River God figure with coiled marine tails, broad
## sculpted chest/shoulders, wavy-haired 28-seg head, and spiral conch horn.
static func triton_figure(lm: LandmarkMesh, key: String, base: Vector3, h: float,
		yaw: float = 0.0, blowing_conch: bool = true) -> void:
	var rot := Basis(Vector3.UP, yaw)
	var p := func(v: Vector3) -> Vector3: return base + rot * v
	for s in [-1.0, 1.0]:
		var sf := float(s)
		var tail := PackedVector3Array([
			p.call(Vector3(sf * h * 0.06, h * 0.38, 0.0)),
			p.call(Vector3(sf * h * 0.14, h * 0.22, h * 0.16)),
			p.call(Vector3(sf * h * 0.19, h * 0.09, h * 0.08)),
			p.call(Vector3(sf * h * 0.25, h * 0.05, -h * 0.12)),
			p.call(Vector3(sf * h * 0.29, h * 0.07, -h * 0.24)),
		])
		loft_tube(lm, key, tail, PackedVector2Array([
			Vector2(h * 0.082, h * 0.082), Vector2(h * 0.068, h * 0.068),
			Vector2(h * 0.050, h * 0.050), Vector2(h * 0.032, h * 0.048),
			Vector2(h * 0.016, h * 0.068),
		]), 14)
	var ts := PackedVector3Array([
		p.call(Vector3(0.0, h * 0.28, 0.0)),
		p.call(Vector3(0.0, h * 0.46, h * 0.02)),
		p.call(Vector3(0.0, h * 0.64, h * 0.05)),
		p.call(Vector3(0.0, h * 0.74, h * 0.04)),
		p.call(Vector3(0.0, h * 0.83, h * 0.05)),
	])
	loft_tube(lm, key, ts, PackedVector2Array([
		Vector2(h * 0.122, h * 0.100), Vector2(h * 0.108, h * 0.090),
		Vector2(h * 0.152, h * 0.108), Vector2(h * 0.132, h * 0.086),
		Vector2(h * 0.040, h * 0.040),
	]), 18)
	sculpted_head(lm, key, p.call(Vector3(0.0, h * 0.82, h * 0.05)), h * 0.18,
		yaw, true, -0.20 if blowing_conch else 0.0)
	var arm_r := PackedVector2Array([
		Vector2(h * 0.054, h * 0.052), Vector2(h * 0.046, h * 0.044),
		Vector2(h * 0.038, h * 0.036), Vector2(h * 0.027, h * 0.026),
	])
	for s in [-1.0, 1.0]:
		var sf := float(s)
		var arm := PackedVector3Array([
			p.call(Vector3(sf * h * 0.085, h * 0.72, h * 0.04)),
			p.call(Vector3(sf * h * 0.145, h * 0.72, h * 0.06)),
			p.call(Vector3(sf * h * 0.185, h * 0.78 if blowing_conch else h * 0.58, h * 0.18)),
			p.call(Vector3(sf * h * 0.055, h * 0.88, h * 0.24) if blowing_conch else Vector3(sf * h * 0.14, h * 0.48, h * 0.26)),
		])
		loft_tube(lm, key, arm, arm_r, 14)
	if blowing_conch:
		var conch := PackedVector3Array([
			p.call(Vector3(0.0, h * 0.89, h * 0.20)),
			p.call(Vector3(0.0, h * 0.96, h * 0.34)),
			p.call(Vector3(0.0, h * 1.04, h * 0.48)),
		])
		loft_tube(lm, key, conch, PackedVector2Array([
			Vector2(h * 0.022, h * 0.022), Vector2(h * 0.062, h * 0.062), Vector2(h * 0.095, h * 0.095),
		]), 14)

## Lifelike Art Nouveau sea lion with broad pectoral chest, whiskered snout,
## parted open spouting lower jaw, eyes, ear pinnae, and smooth twist-free
## webbed fore- and hind-flippers gripping the granite plinth.
static func sea_lion(lm: LandmarkMesh, key: String, base: Vector3, length: float,
		yaw: float = 0.0) -> Vector3:
	var rot := Basis(Vector3.UP, yaw)
	var p := func(v: Vector3) -> Vector3: return base + rot * v
	var s := length / 1.55
	var spine := PackedVector3Array([
		p.call(Vector3(0.0, 0.05 * s, -0.80 * s)),
		p.call(Vector3(0.0, 0.11 * s, -0.62 * s)),
		p.call(Vector3(0.0, 0.19 * s, -0.40 * s)),
		p.call(Vector3(0.0, 0.27 * s, -0.16 * s)),
		p.call(Vector3(0.0, 0.34 * s, 0.08 * s)),  # broad muscular chest
		p.call(Vector3(0.0, 0.48 * s, 0.26 * s)),  # shoulder arch
		p.call(Vector3(0.0, 0.66 * s, 0.38 * s)),  # mid neck
		p.call(Vector3(0.0, 0.82 * s, 0.46 * s)),  # cranium / brow
		p.call(Vector3(0.0, 0.91 * s, 0.56 * s)),  # eyes / forehead
		p.call(Vector3(0.0, 0.96 * s, 0.68 * s)),  # upper whiskered snout
		p.call(Vector3(0.0, 0.99 * s, 0.77 * s)),  # rounded nose tip
	])
	var radii := PackedVector2Array([
		Vector2(0.09 * s, 0.05 * s),
		Vector2(0.16 * s, 0.12 * s),
		Vector2(0.23 * s, 0.19 * s),
		Vector2(0.28 * s, 0.24 * s),
		Vector2(0.30 * s, 0.27 * s),
		Vector2(0.25 * s, 0.23 * s),
		Vector2(0.19 * s, 0.19 * s),
		Vector2(0.16 * s, 0.17 * s),
		Vector2(0.14 * s, 0.15 * s),
		Vector2(0.092 * s, 0.096 * s),
		Vector2(0.044 * s, 0.048 * s),
	])
	loft_tube(lm, key, spine, radii, 22)
	# Parted open lower jaw beneath the upper snout
	loft_tube(lm, key, PackedVector3Array([
		p.call(Vector3(0.0, 0.80 * s, 0.48 * s)),
		p.call(Vector3(0.0, 0.84 * s, 0.63 * s)),
		p.call(Vector3(0.0, 0.86 * s, 0.73 * s)),
	]), PackedVector2Array([
		Vector2(0.095 * s, 0.075 * s), Vector2(0.068 * s, 0.048 * s), Vector2(0.036 * s, 0.026 * s),
	]), 14)
	for side in [-1.0, 1.0]:
		var sg := float(side)
		loft_tube(lm, key, PackedVector3Array([
			p.call(Vector3(sg * 0.095 * s, 0.91 * s, 0.56 * s)),
			p.call(Vector3(sg * 0.126 * s, 0.91 * s, 0.57 * s)),
		]), PackedVector2Array([Vector2(0.032 * s, 0.032 * s), Vector2(0.018 * s, 0.018 * s)]), 10)
		loft_tube(lm, key, PackedVector3Array([
			p.call(Vector3(sg * 0.135 * s, 0.84 * s, 0.44 * s)),
			p.call(Vector3(sg * 0.172 * s, 0.81 * s, 0.39 * s)),
		]), PackedVector2Array([Vector2(0.022 * s, 0.016 * s), Vector2(0.009 * s, 0.009 * s)]), 8)
		# Deeply rooted muscular fore-flippers (start well inside pectoral chest -> zero seam!)
		var flip := PackedVector3Array([
			p.call(Vector3(sg * 0.12 * s, 0.31 * s, 0.08 * s)),
			p.call(Vector3(sg * 0.25 * s, 0.22 * s, 0.12 * s)),
			p.call(Vector3(sg * 0.39 * s, 0.09 * s, 0.16 * s)),
			p.call(Vector3(sg * 0.52 * s, 0.03 * s, 0.09 * s)),
		])
		loft_tube(lm, key, flip, PackedVector2Array([
			Vector2(0.11 * s, 0.13 * s), Vector2(0.095 * s, 0.11 * s),
			Vector2(0.11 * s, 0.048 * s), Vector2(0.085 * s, 0.022 * s),
		]), 14)
		# Smooth fanned bilobed hind-flippers emerging from tail root
		loft_tube(lm, key, PackedVector3Array([
			p.call(Vector3(sg * 0.03 * s, 0.06 * s, -0.74 * s)),
			p.call(Vector3(sg * 0.14 * s, 0.04 * s, -0.90 * s)),
			p.call(Vector3(sg * 0.24 * s, 0.025 * s, -1.03 * s)),
		]), PackedVector2Array([
			Vector2(0.075 * s, 0.042 * s), Vector2(0.105 * s, 0.028 * s), Vector2(0.065 * s, 0.018 * s),
		]), 12)
	return p.call(Vector3(0.0, 0.93 * s, 0.74 * s))

## Detailed sculpted rearing / surging horse with rounded equine muzzle & nostrils,
## masseter cheek & lower jaw, pricked ears, flowing mane, and muscular shoulder/haunch blends.
static func rearing_horse(lm: LandmarkMesh, key: String, base: Vector3, scale_m: float = 1.0,
		yaw: float = 0.0, rear_pitch: float = 0.32) -> void:
	var rot := Basis(Vector3.UP, yaw)
	var pitch := Basis(Vector3.RIGHT, -rear_pitch)
	var p := func(v: Vector3) -> Vector3: return base + rot * (pitch * (v * scale_m))
	var body := PackedVector3Array([
		p.call(Vector3(0.0, 1.16, -1.08)), # rounded croup
		p.call(Vector3(0.0, 1.24, -0.68)), # loins
		p.call(Vector3(0.0, 1.21, 0.0)),   # barrel
		p.call(Vector3(0.0, 1.36, 0.58)),  # deep chest / withers
		p.call(Vector3(0.0, 1.82, 0.88)),  # arched muscular neck
		p.call(Vector3(0.0, 2.20, 1.04)),  # poll
		p.call(Vector3(0.0, 2.13, 1.24)),  # forehead / masseter cheek
		p.call(Vector3(0.0, 1.96, 1.48)),  # nasal bridge
		p.call(Vector3(0.0, 1.82, 1.66)),  # flared nostrils
		p.call(Vector3(0.0, 1.75, 1.74)),  # rounded upper lip / muzzle tip
	])
	loft_tube(lm, key, body, PackedVector2Array([
		Vector2(0.32 * scale_m, 0.34 * scale_m), Vector2(0.43 * scale_m, 0.46 * scale_m),
		Vector2(0.44 * scale_m, 0.49 * scale_m), Vector2(0.42 * scale_m, 0.47 * scale_m),
		Vector2(0.24 * scale_m, 0.35 * scale_m), Vector2(0.18 * scale_m, 0.24 * scale_m),
		Vector2(0.16 * scale_m, 0.22 * scale_m), Vector2(0.105 * scale_m, 0.135 * scale_m),
		Vector2(0.092 * scale_m, 0.105 * scale_m), Vector2(0.052 * scale_m, 0.058 * scale_m),
	]), 18)
	# Sculpted lower equine jaw & chin groove
	loft_tube(lm, key, PackedVector3Array([
		p.call(Vector3(0.0, 1.98, 1.18)),
		p.call(Vector3(0.0, 1.84, 1.44)),
		p.call(Vector3(0.0, 1.71, 1.66)),
	]), PackedVector2Array([
		Vector2(0.12 * scale_m, 0.13 * scale_m), Vector2(0.075 * scale_m, 0.08 * scale_m),
		Vector2(0.048 * scale_m, 0.048 * scale_m),
	]), 12)
	# Carved flowing wavy mane along neck crest
	loft_tube(lm, key, PackedVector3Array([
		p.call(Vector3(0.0, 1.42, 0.46)),
		p.call(Vector3(0.04, 1.88, 0.74)),
		p.call(Vector3(0.02, 2.27, 0.98)),
	]), PackedVector2Array([
		Vector2(0.09 * scale_m, 0.15 * scale_m), Vector2(0.11 * scale_m, 0.19 * scale_m),
		Vector2(0.08 * scale_m, 0.13 * scale_m),
	]), 12)
	for side in [-1.0, 1.0]:
		var sg := float(side)
		loft_tube(lm, key, PackedVector3Array([
			p.call(Vector3(sg * 0.09, 2.21, 1.04)),
			p.call(Vector3(sg * 0.13, 2.42, 1.08)),
		]), PackedVector2Array([Vector2(0.040 * scale_m, 0.050 * scale_m), Vector2(0.012 * scale_m, 0.016 * scale_m)]), 8)
		var lift := 0.24 if sg > 0.0 else 0.0
		# Deeply rooted muscular shoulder -> forearm -> knee -> cannon -> fetlock -> hoof
		var fore := PackedVector3Array([
			p.call(Vector3(sg * 0.18, 1.28, 0.50)),
			p.call(Vector3(sg * 0.25, 1.12, 0.64)),
			p.call(Vector3(sg * 0.26, 0.86 + lift, 1.08)),
			p.call(Vector3(sg * 0.24, 0.44 + lift, 0.94)),
			p.call(Vector3(sg * 0.24, 0.24 + lift, 1.04)),
		])
		loft_tube(lm, key, fore, PackedVector2Array([
			Vector2(0.21 * scale_m, 0.24 * scale_m), Vector2(0.15 * scale_m, 0.18 * scale_m),
			Vector2(0.095 * scale_m, 0.105 * scale_m), Vector2(0.065 * scale_m, 0.072 * scale_m),
			Vector2(0.090 * scale_m, 0.102 * scale_m),
		]), 12)
		var hind := PackedVector3Array([
			base + rot * (Vector3(sg * 0.18, 1.20, -0.74) * scale_m),
			base + rot * (Vector3(sg * 0.26, 0.98, -0.86) * scale_m),
			base + rot * (Vector3(sg * 0.27, 0.62, -1.04) * scale_m),
			base + rot * (Vector3(sg * 0.25, 0.22, -0.92) * scale_m),
			base + rot * (Vector3(sg * 0.25, 0.03, -0.84) * scale_m),
		])
		loft_tube(lm, key, hind, PackedVector2Array([
			Vector2(0.23 * scale_m, 0.27 * scale_m), Vector2(0.18 * scale_m, 0.21 * scale_m),
			Vector2(0.105 * scale_m, 0.13 * scale_m), Vector2(0.070 * scale_m, 0.078 * scale_m),
			Vector2(0.092 * scale_m, 0.108 * scale_m),
		]), 12)
	loft_tube(lm, key, PackedVector3Array([
		p.call(Vector3(0.0, 1.22, -1.04)),
		p.call(Vector3(0.0, 0.86, -1.50)),
		p.call(Vector3(0.0, 0.34, -1.66)),
	]), PackedVector2Array([Vector2(0.10 * scale_m, 0.10 * scale_m), Vector2(0.15 * scale_m, 0.13 * scale_m), Vector2(0.055 * scale_m, 0.055 * scale_m)]), 12)

## Monumental couchant lion with furrowed multi-lobed shaggy mane, sculpted feline
## brow/muzzle/lower jaw, rounded ears, and massive 3-toed outstretched forepaws.
static func couchant_lion(lm: LandmarkMesh, key: String, base: Vector3, length: float,
		yaw: float = 0.0) -> Vector3:
	var rot := Basis(Vector3.UP, yaw)
	var p := func(v: Vector3) -> Vector3: return base + rot * v
	var s := length / 3.6
	var centers := PackedVector3Array()
	var rows: Array = []
	var segs := 24
	var prof := [
		[0.36, -1.52, 0.002, 0.002, 0.0],
		[0.38, -1.44, 0.34, 0.30, 0.0],
		[0.56, -0.92, 0.44, 0.42, 0.0],
		[0.62, -0.18, 0.42, 0.44, 0.0],
		[0.78,  0.38, 0.56, 0.54, 1.0],
		[1.06,  0.68, 0.64, 0.62, 1.0], # massive shaggy mane ruff
		[1.28,  0.88, 0.54, 0.52, 0.85],
		[1.34,  1.08, 0.36, 0.36, 0.25], # broad feline brow & cheekbones
		[1.25,  1.28, 0.25, 0.24, 0.0],  # nasal bridge
		[1.18,  1.45, 0.21, 0.19, 0.0],  # broad whiskered upper muzzle / jowls
		[1.16,  1.52, 0.13, 0.11, 0.0],  # rounded feline nose leather
		[1.15,  1.55, 0.002, 0.002, 0.0],
	]
	for j in prof.size():
		var q: Array = prof[j]
		var cy := float(q[0]) * s
		var cz := float(q[1]) * s
		var rx := float(q[2]) * s
		var rz := float(q[3]) * s
		var mane_w := float(q[4])
		centers.append(p.call(Vector3(0.0, cy, cz)))
		var row := PackedVector3Array()
		for i in segs + 1:
			var a := TAU * float(i) / float(segs) if i < segs else 0.0
			var locks := 1.0 + 0.13 * mane_w * (sin(a * 9.0 + float(j) * 1.4) * 0.6 + cos(a * 15.0) * 0.4)
			row.append(p.call(Vector3(cos(a) * rx * locks, cy + sin(a) * rz * 0.85 * locks, cz + sin(a) * rz * 0.28)))
		rows.append(row)
	emit_rings(lm, key, centers, rows)
	# Sculpted feline lower jaw & chin tuft under muzzle
	loft_tube(lm, key, PackedVector3Array([
		p.call(Vector3(0.0, 1.04 * s, 1.12 * s)),
		p.call(Vector3(0.0, 1.01 * s, 1.34 * s)),
		p.call(Vector3(0.0, 1.02 * s, 1.46 * s)),
	]), PackedVector2Array([
		Vector2(0.18 * s, 0.14 * s), Vector2(0.14 * s, 0.10 * s), Vector2(0.09 * s, 0.07 * s),
	]), 12)
	for side in [-1.0, 1.0]:
		var sg := float(side)
		loft_tube(lm, key, PackedVector3Array([
			p.call(Vector3(sg * 0.30 * s, 1.50 * s, 0.96 * s)),
			p.call(Vector3(sg * 0.36 * s, 1.62 * s, 0.94 * s)),
		]), PackedVector2Array([Vector2(0.09 * s, 0.07 * s), Vector2(0.045 * s, 0.038 * s)]), 8)
		# Massive outstretched foreleg + broad paw with 3 sculpted toes
		loft_tube(lm, key, PackedVector3Array([
			p.call(Vector3(sg * 0.28 * s, 0.44 * s, 0.48 * s)),
			p.call(Vector3(sg * 0.32 * s, 0.20 * s, 1.25 * s)),
			p.call(Vector3(sg * 0.32 * s, 0.14 * s, 1.66 * s)),
		]), PackedVector2Array([
			Vector2(0.22 * s, 0.24 * s), Vector2(0.15 * s, 0.14 * s), Vector2(0.19 * s, 0.12 * s),
		]), 14)
		for toe in [-1.0, 0.0, 1.0]:
			var tf := float(toe)
			loft_tube(lm, key, PackedVector3Array([
				p.call(Vector3((sg * 0.32 + tf * 0.068) * s, 0.12 * s, 1.64 * s)),
				p.call(Vector3((sg * 0.32 + tf * 0.074) * s, 0.09 * s, 1.82 * s)),
			]), PackedVector2Array([Vector2(0.055 * s, 0.065 * s), Vector2(0.042 * s, 0.048 * s)]), 8)
	return p.call(Vector3(0.0, 1.12 * s, 1.48 * s))
