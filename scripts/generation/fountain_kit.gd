class_name FountainKit
extends RefCounted

## Reusable flowing-water geometry builder for landmark fountains and PlazaLife.
## All coordinates are in the caller's coordinate space (model metres for
## landmarks; world units with `scale = m2u` for PlazaLife).
## Commits up to 3 lightweight GPU-animated draw calls:
## - FountainFlow: crossed vertical plumes, parabolic arcs, bowl overflow
##   curtains and stepped cascades (FountainWater.flow_material())
## - FountainFoam: basin splash boil discs and cascade plunge strips
##   (FountainWater.foam_material())
## - FountainMist: rising spray mist billboards in one MultiMeshInstance3D
##   (FountainWater.mist_material(), hidden below High by FountainWater.upgrade)

var _fv := PackedVector3Array()
var _fn := PackedVector3Array()
var _fu := PackedVector2Array()
var _fc := PackedColorArray()

var _bv := PackedVector3Array()
var _bn := PackedVector3Array()
var _bu := PackedVector2Array()
var _bc := PackedColorArray()

var _mists: Array = []  # Array of [Vector3 pos, float rise, float radius, int count]
static var _mist_quad: QuadMesh

func is_empty() -> bool:
	return _fv.is_empty() and _bv.is_empty() and _mists.is_empty()

func _flow_quad(a: Vector3, b: Vector3, c: Vector3, d: Vector3,
		na: Vector3, nb: Vector3, nc: Vector3, nd: Vector3,
		ua: Vector2, ub: Vector2, uc: Vector2, ud: Vector2,
		ca: Color, cb: Color, cc: Color, cd: Color) -> void:
	_fv.append_array([a, b, c, a, c, d])
	_fn.append_array([na, nb, nc, na, nc, nd])
	_fu.append_array([ua, ub, uc, ua, uc, ud])
	_fc.append_array([ca, cb, cc, ca, cc, cd])

func _foam_quad(a: Vector3, b: Vector3, c: Vector3, d: Vector3,
		ua: Vector2, ub: Vector2, uc: Vector2, ud: Vector2, col: Color) -> void:
	_bv.append_array([a, b, c, a, c, d])
	_bn.append_array([Vector3.UP, Vector3.UP, Vector3.UP, Vector3.UP, Vector3.UP, Vector3.UP])
	_bu.append_array([ua, ub, uc, ua, uc, ud])
	_bc.append_array([col, col, col, col, col, col])

## Multi-fin vertical rising & feathering fountain jet plume.
## `fins` crossed vertical ribbons taper slightly through the waist, flare softly
## toward the aerated crest and curtain downward at the tip.
func jet_plume(base: Vector3, height: float, r_base: float = 0.14,
		r_apex: float = 0.34, wind_lean: Vector2 = Vector2.ZERO, fins: int = 4) -> void:
	if height <= 0.05:
		return
	var segs := 8
	var spd := clampf((2.8 + sqrt(height) * 1.4) / 6.0, 0.25, 1.0)
	for f in fins:
		var ang := PI * float(f) / float(fins)
		var side := Vector3(cos(ang), 0.0, sin(ang))
		var norm := Vector3(-side.z, 0.0, side.x)
		var prev_l := Vector3.ZERO
		var prev_r := Vector3.ZERO
		var prev_v := 0.0
		var prev_c := Color.WHITE
		for i in segs + 1:
			var t := float(i) / float(segs)
			# Profile: tight coherent jet near nozzle, swelling into aerated plume near apex.
			var flare := sin(t * PI * 0.82)
			var w := lerpf(r_base, r_apex, clampf(flare * 0.85 + t * 0.35, 0.0, 1.0)) * (1.0 - 0.32 * pow(t, 4.0))
			var drift := Vector3(wind_lean.x, 0.0, wind_lean.y) * (t * t)
			var p := base + Vector3(0.0, height * t, 0.0) + drift
			var pl := p - side * w
			var pr := p + side * w
			var aero := clampf(0.28 + t * 0.72, 0.0, 1.0)
			var end_fade := smoothstep(0.0, 0.08, t) * (1.0 - smoothstep(0.76, 1.0, t))
			var col := Color(aero, spd, clampf(end_fade, 0.05, 1.0), 1.0)
			var v := t * height
			if i > 0:
				_flow_quad(prev_l, prev_r, pr, pl, norm, norm, norm, norm,
					Vector2(0.0, prev_v), Vector2(1.0, prev_v), Vector2(1.0, v), Vector2(0.0, v),
					prev_c, prev_c, col, col)
			prev_l = pl
			prev_r = pr
			prev_v = v
			prev_c = col
	# Outer falling curtain veil around tall plumes (> 2.2 m).
	if height >= 2.2:
		var veil_r := maxf(r_apex * 1.15, r_base * 2.2)
		bowl_curtain(base, veil_r * 0.45, height * 0.86, 0.0, veil_r * 1.1, 10, 1.0, 1.0, 0.65)

## Smooth parabolic water arc spouting from `start` to `end` with extra `apex_lift`.
## Built as two orthogonal crossed ribbons along the true gravity parabola so it
## reads full-bodied from every camera azimuth without faceted tube artifacts.
func arc_stream(start: Vector3, end: Vector3, apex_lift: float = 0.6,
		width_start: float = 0.09, width_end: float = 0.24, aeration_end: float = 0.92,
		segs: int = 12) -> void:
	if start.distance_to(end) < 0.05 and apex_lift < 0.05:
		return
	var pts := PackedVector3Array()
	var tangs := PackedVector3Array()
	var lens := PackedFloat32Array()
	var total := 0.0
	for i in segs + 1:
		var t := float(i) / float(segs)
		var p := start.lerp(end, t) + Vector3(0.0, 4.0 * apex_lift * t * (1.0 - t), 0.0)
		pts.append(p)
		if i > 0:
			total += p.distance_to(pts[i - 1])
		lens.append(total)
	if total < 0.05:
		return
	for i in segs + 1:
		var i0 := maxi(i - 1, 0)
		var i1 := mini(i + 1, segs)
		tangs.append((pts[i1] - pts[i0]).normalized())
	var spd := clampf((3.0 + sqrt(total + apex_lift) * 1.1) / 6.0, 0.35, 1.0)
	for plane in 2:
		var prev_l := Vector3.ZERO
		var prev_r := Vector3.ZERO
		var prev_n := Vector3.UP
		var prev_v := 0.0
		var prev_c := Color.WHITE
		for i in segs + 1:
			var t := float(i) / float(segs)
			var tan_v := tangs[i]
			var ref := Vector3.UP if absf(tan_v.y) < 0.92 else Vector3.RIGHT
			var s1 := tan_v.cross(ref).normalized()
			var s2 := tan_v.cross(s1).normalized()
			var side := s1 if plane == 0 else s2
			var norm := s2 if plane == 0 else s1
			var hw := lerpf(width_start, width_end, pow(t, 0.85)) * 0.5
			var pl := pts[i] - side * hw
			var pr := pts[i] + side * hw
			var aero := clampf(lerpf(0.22, aeration_end, pow(t, 0.75)), 0.0, 1.0)
			var end_fade := smoothstep(0.0, 0.06, t) * (1.0 - smoothstep(0.90, 1.0, t))
			var col := Color(aero, spd, clampf(end_fade, 0.12, 1.0), 1.0)
			var v := lens[i]
			if i > 0:
				_flow_quad(prev_l, prev_r, pr, pl, prev_n, prev_n, norm, norm,
					Vector2(0.0, prev_v), Vector2(1.0, prev_v), Vector2(1.0, v), Vector2(0.0, v),
					prev_c, prev_c, col, col)
			prev_l = pl
			prev_r = pr
			prev_n = norm
			prev_v = v
			prev_c = col

## 360-degree parabolic water curtain overflowing a circular or elliptical bowl rim.
## `center` is at y = 0 reference; sheet falls from `y_top` to `y_bottom`, curving
## outward from `radius` to `radius + flare_out`.
func bowl_curtain(center: Vector3, radius: float, y_top: float, y_bottom: float,
		flare_out: float = 0.45, segs: int = 24, sx: float = 1.0, sz: float = 1.0,
		aero_base: float = 0.30) -> void:
	var drop := y_top - y_bottom
	if drop <= 0.05 or radius <= 0.05:
		return
	var v_segs := 6
	var spd := clampf((2.4 + sqrt(drop) * 1.5) / 6.0, 0.35, 1.0)
	var rows: Array = []
	var norms: Array = []
	var vs: PackedFloat32Array = PackedFloat32Array()
	var cols: Array[Color] = []
	var acc := 0.0
	for j in v_segs + 1:
		var t := float(j) / float(v_segs)
		# Gravity fall curve: horizontal overflow lip curving steeply downward.
		var r_off := flare_out * sqrt(t)
		var y := y_top - drop * (t * t * 0.72 + t * 0.28)
		if j > 0:
			var pt := float(j - 1) / float(v_segs)
			var pr_off := flare_out * sqrt(pt)
			var py := y_top - drop * (pt * pt * 0.72 + pt * 0.28)
			acc += Vector2(r_off - pr_off, y - py).length()
		vs.append(acc)
		var aero := clampf(lerpf(aero_base, 0.94, pow(t, 0.7)), 0.0, 1.0)
		var fade := smoothstep(0.0, 0.08, t) * (1.0 - smoothstep(0.92, 1.0, t))
		cols.append(Color(aero, spd, clampf(fade, 0.18, 1.0), 1.0))
		var ring := PackedVector3Array()
		var nring := PackedVector3Array()
		for i in segs + 1:
			var a := TAU * float(i) / float(segs)
			var dir := Vector3(cos(a), 0.0, sin(a))
			ring.append(Vector3(center.x + dir.x * (radius + r_off) * sx,
				center.y + y, center.z + dir.z * (radius + r_off) * sz))
			nring.append(Vector3(dir.x / sx, 0.25 * (1.0 - t), dir.z / sz).normalized())
		rows.append(ring)
		norms.append(nring)
	var circ := TAU * (radius + flare_out * 0.5) * (sx + sz) * 0.5
	var tiles := maxf(roundf(circ / 1.8), 2.0)
	for j in v_segs:
		var r0: PackedVector3Array = rows[j]
		var r1: PackedVector3Array = rows[j + 1]
		var n0: PackedVector3Array = norms[j]
		var n1: PackedVector3Array = norms[j + 1]
		var v0 := vs[j]
		var v1 := vs[j + 1]
		var c0 := cols[j]
		var c1 := cols[j + 1]
		for i in segs:
			# Wrap U across 0.2..0.8 per tile so continuous curtain has no hard edge gaps.
			var u0 := fposmod(float(i) / float(segs) * tiles, 1.0) * 0.52 + 0.24
			var u1 := fposmod(float(i + 1) / float(segs) * tiles, 1.0) * 0.52 + 0.24
			if u1 < u0:
				u1 = 0.76
			_flow_quad(r0[i], r0[i + 1], r1[i + 1], r1[i],
				n0[i], n0[i + 1], n1[i + 1], n1[i],
				Vector2(u0, v0), Vector2(u1, v0), Vector2(u1, v1), Vector2(u0, v1),
				c0, c0, c1, c1)

## Curved waterfall / weir cascade sheet spanning `p0..p1` (at their XZ) from
## `y_top` down to `y_bottom`, bowing forward along `forward_dir` by `bow_out`.
func cascade_sheet(p0: Vector3, p1: Vector3, y_top: float, y_bottom: float,
		forward_dir: Vector3, bow_out: float = 0.55, aeration: float = 0.72) -> void:
	var drop := y_top - y_bottom
	var width := Vector2(p1.x - p0.x, p1.z - p0.z).length()
	if drop <= 0.05 or width <= 0.05:
		return
	var fwd := Vector3(forward_dir.x, 0.0, forward_dir.z).normalized()
	if fwd.length_squared() < 0.01:
		fwd = Vector3(0.0, 0.0, 1.0)
	var v_segs := 6
	var u_segs := clampi(int(ceil(width / 1.4)), 2, 16)
	var spd := clampf((2.8 + sqrt(drop) * 1.6) / 6.0, 0.4, 1.0)
	var rows: Array = []
	var norms: Array = []
	var vs := PackedFloat32Array()
	var cols: Array[Color] = []
	var acc := 0.0
	for j in v_segs + 1:
		var t := float(j) / float(v_segs)
		var out_d := bow_out * sqrt(t)
		var y := y_top - drop * (t * t * 0.74 + t * 0.26)
		if j > 0:
			var pt := float(j - 1) / float(v_segs)
			var pout := bow_out * sqrt(pt)
			var py := y_top - drop * (pt * pt * 0.74 + pt * 0.26)
			acc += Vector2(out_d - pout, y - py).length()
		vs.append(acc)
		var aero := clampf(lerpf(aeration * 0.55, minf(aeration + 0.28, 1.0), t), 0.0, 1.0)
		var fade := smoothstep(0.0, 0.06, t) * (1.0 - smoothstep(0.94, 1.0, t))
		cols.append(Color(aero, spd, clampf(fade, 0.22, 1.0), 1.0))
		var row := PackedVector3Array()
		var nrow := PackedVector3Array()
		var n := (fwd + Vector3(0.0, 0.35 * (1.0 - t), 0.0)).normalized()
		for i in u_segs + 1:
			var s := float(i) / float(u_segs)
			var base_p := p0.lerp(p1, s)
			row.append(Vector3(base_p.x, y, base_p.z) + fwd * out_d)
			nrow.append(n)
		rows.append(row)
		norms.append(nrow)
	for j in v_segs:
		var r0: PackedVector3Array = rows[j]
		var r1: PackedVector3Array = rows[j + 1]
		var n0: PackedVector3Array = norms[j]
		var n1: PackedVector3Array = norms[j + 1]
		for i in u_segs:
			var u0 := float(i) / float(u_segs)
			var u1 := float(i + 1) / float(u_segs)
			_flow_quad(r0[i], r0[i + 1], r1[i + 1], r1[i],
				n0[i], n0[i + 1], n1[i + 1], n1[i],
				Vector2(u0, vs[j]), Vector2(u1, vs[j]), Vector2(u1, vs[j + 1]), Vector2(u0, vs[j + 1]),
				cols[j], cols[j], cols[j + 1], cols[j + 1])

## Circular basin splash boil + expanding concentric ripple ring just above water.
func splash_ring(center: Vector3, radius: float, intensity: float = 0.85,
		lift: float = 0.028) -> void:
	if radius <= 0.05:
		return
	var y := center.y + lift
	var a := Vector3(center.x - radius, y, center.z - radius)
	var b := Vector3(center.x + radius, y, center.z - radius)
	var c := Vector3(center.x + radius, y, center.z + radius)
	var d := Vector3(center.x - radius, y, center.z + radius)
	_foam_quad(a, b, c, d, Vector2(0.0, 0.0), Vector2(1.0, 0.0), Vector2(1.0, 1.0), Vector2(0.0, 1.0),
		Color(clampf(intensity, 0.1, 1.0), 0.0, 0.0, 1.0))

## Linear plunge-pool foam boil strip along `p0..p1` extending `width` along `forward_dir`.
func splash_strip(p0: Vector3, p1: Vector3, forward_dir: Vector3, width: float,
		intensity: float = 0.9, lift: float = 0.028) -> void:
	var length := Vector2(p1.x - p0.x, p1.z - p0.z).length()
	if length <= 0.05 or width <= 0.05:
		return
	var fwd := Vector3(forward_dir.x, 0.0, forward_dir.z).normalized()
	if fwd.length_squared() < 0.01:
		fwd = Vector3(0.0, 0.0, 1.0)
	var y := (p0.y + p1.y) * 0.5 + lift
	var a := Vector3(p0.x, y, p0.z) - fwd * (width * 0.18)
	var b := Vector3(p1.x, y, p1.z) - fwd * (width * 0.18)
	var c := Vector3(p1.x, y, p1.z) + fwd * (width * 0.82)
	var d := Vector3(p0.x, y, p0.z) + fwd * (width * 0.82)
	_foam_quad(a, b, c, d, Vector2(0.0, 0.0), Vector2(length, 0.0), Vector2(length, 1.0), Vector2(0.0, 1.0),
		Color(clampf(intensity, 0.1, 1.0), 1.0, 0.0, 1.0))

## Registers a soft rising spray-mist emitter (batched into one MultiMeshInstance3D).
func mist_emitter(center: Vector3, rise_m: float = 1.6, puff_radius_m: float = 1.1,
		count: int = 5) -> void:
	if count <= 0 or puff_radius_m <= 0.05:
		return
	_mists.append([center, rise_m, puff_radius_m, count])

## Commits accumulated flow, foam and mist nodes under `parent`.
func commit(parent: Node3D, prefix: String = "", include_mist: bool = true) -> Array[Node3D]:
	var out: Array[Node3D] = []
	if not _fv.is_empty():
		var mi := _commit_mesh(prefix + "FountainFlow", _fv, _fn, _fu, _fc,
			FountainWater.flow_fallback_material(), FountainWater.flow_material())
		parent.add_child(mi)
		out.append(mi)
	if not _bv.is_empty():
		var mi := _commit_mesh(prefix + "FountainFoam", _bv, _bn, _bu, _bc,
			FountainWater.foam_fallback_material(), FountainWater.foam_material())
		parent.add_child(mi)
		out.append(mi)
	if include_mist and not _mists.is_empty():
		var mmi := _commit_mist(prefix + FountainWater.MIST_NODE_PREFIX)
		if mmi != null:
			parent.add_child(mmi)
			out.append(mmi)
	return out

static func _commit_mesh(node_name: String, verts: PackedVector3Array, norms: PackedVector3Array,
		uvs: PackedVector2Array, cols: PackedColorArray, base_mat: Material,
		shader_override: Material = null) -> MeshInstance3D:
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = norms
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_COLOR] = cols
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh.surface_set_material(0, base_mat)
	var mi := MeshInstance3D.new()
	mi.name = node_name
	mi.mesh = mesh
	if shader_override != null:
		mi.set_surface_override_material(0, shader_override)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.set_meta(FountainWater.IMPOSTOR_SKIP_META, true)
	return mi

func _commit_mist(node_name: String) -> MultiMeshInstance3D:
	var total := 0
	for e: Array in _mists:
		total += int(e[3])
	if total <= 0:
		return null
	if _mist_quad == null:
		_mist_quad = QuadMesh.new()
		_mist_quad.size = Vector2.ONE
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = true
	mm.mesh = _mist_quad
	mm.instance_count = total
	var lo := Vector3(INF, INF, INF)
	var hi := Vector3(-INF, -INF, -INF)
	var idx := 0
	for ei in _mists.size():
		var e: Array = _mists[ei]
		var pos: Vector3 = e[0]
		var rise: float = float(e[1])
		var rad: float = float(e[2])
		var cnt: int = int(e[3])
		lo = lo.min(pos - Vector3(rad * 2.5, rad, rad * 2.5))
		hi = hi.max(pos + Vector3(rad * 2.5, rise + rad * 2.5, rad * 2.5))
		for k in cnt:
			var ang := TAU * float(k) / float(maxi(cnt, 1)) + float(ei) * 1.13
			var jitter := Vector3(cos(ang), 0.0, sin(ang)) * (rad * 0.25)
			mm.set_instance_transform(idx, Transform3D(Basis(), pos + jitter))
			var phase := fposmod(float(k) / float(maxi(cnt, 1)) + float(ei) * 0.173, 1.0)
			mm.set_instance_custom_data(idx, Color(phase, rise, rad, 0.45))
			idx += 1
	var mmi := MultiMeshInstance3D.new()
	mmi.name = node_name
	mmi.multimesh = mm
	mmi.material_override = FountainWater.mist_material()
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mmi.custom_aabb = AABB(lo, (hi - lo).max(Vector3.ONE))
	mmi.set_meta(FountainWater.IMPOSTOR_SKIP_META, true)
	return mmi
