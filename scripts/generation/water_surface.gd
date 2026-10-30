class_name WaterSurface
extends RefCounted

## Water look v2 (T3.8): the water ShaderMaterial plus the surface
## meshes WaterBuilder places. Split out of WaterBuilder so the look
## (shader, colour, micro-normals) and the surface tessellation evolve
## without growing the builder.
##
## Look (PRD §4.3): a dark green-grey/teal body (#2C5566-class) that
## shallows toward the shore, procedural travelling micro-normals in
## metres (no texture dependency, mobile-cheap: 4 sine slopes + 2
## value-noise octaves), Fresnel-weighted sky reflection and sun glint
## from the engine's own sky radiance + directional light. SPECULAR is
## held low (F0 ≈ 0.018, f90 ≈ 0.9 in Godot's dielectric model) so the
## surface reads dark when looking down and only brightens at grazing
## angles — the v1 material (SPECULAR 0.6 + a speckle texture used as
## a biased normal map) mirrored the pale golden-hour sky everywhere
## and read as a mint/cream sheet. Detail fades and roughness rises
## with distance so far water never shimmers. No screen-space
## refraction or depth reads: water stays opaque on every tier.
##
## Per-vertex COLOR.r carries "openness" (0 at the shoreline → 1 at
## OPEN_RAMP_M from it); meshes without COLOR (sea/datum planes) read
## as open water.

## Shore → open-water colour ramp (metres from the nearest shoreline).
const OPEN_RAMP_M := 30.0

const SHADER := """
shader_type spatial;
render_mode cull_disabled, depth_draw_opaque, specular_schlick_ggx;

// Body colours (sRGB): open water ≈ Seine/Aura green-grey teal, the
// shore band lighter and greener (shallow, silty).
uniform vec4 deep_color : source_color = vec4(0.150, 0.262, 0.250, 1.0);
uniform vec4 shallow_color : source_color = vec4(0.235, 0.300, 0.250, 1.0);
uniform float units_per_metre = 1.0;
uniform float wave_amp = 1.0;
uniform float near_rough = 0.06;
uniform float far_rough = 0.16;
uniform float spec = 0.34;
uniform vec2 drift = vec2(0.18, 0.07);

// @SNOW
varying vec3 wpos;
varying float openv;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	openv = COLOR.r;
}

float hash12(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

// Value noise derivative (iq): returns d/dx, d/dy.
vec2 noise_grad(vec2 x) {
	vec2 i = floor(x);
	vec2 f = fract(x);
	vec2 u = f * f * (3.0 - 2.0 * f);
	vec2 du = 6.0 * f * (1.0 - f);
	float a = hash12(i);
	float b = hash12(i + vec2(1.0, 0.0));
	float c = hash12(i + vec2(0.0, 1.0));
	float d = hash12(i + vec2(1.0, 1.0));
	return du * (vec2(b - a, c - a) + (a - b - c + d) * u.yx);
}

// Slope of one travelling sine wave (deep-water dispersion).
vec2 wave_slope(vec2 p, vec2 dir, float len, float steep, float t) {
	float k = 6.2831853 / len;
	float ph = dot(dir, p) * k - t * sqrt(9.81 * k);
	return dir * (steep * cos(ph));
}

void fragment() {
	vec2 pm = wpos.xz / units_per_metre;
	float dist_m = length(wpos - CAMERA_POSITION_WORLD) / units_per_metre;
	float t = TIME;
	vec2 s = vec2(0.0);
	// Low sine steepness: alone they band into visible stripes; the
	// value-noise octaves break them into irregular chop.
	s += wave_slope(pm, normalize(vec2(0.86, 0.51)), 3.7, 0.032, t);
	s += wave_slope(pm, normalize(vec2(-0.42, 0.91)), 2.3, 0.026, t);
	s += wave_slope(pm, normalize(vec2(0.97, -0.24)), 1.3, 0.020, t);
	s += wave_slope(pm, normalize(vec2(-0.71, -0.70)), 0.8, 0.016, t);
	s += noise_grad(pm * 0.55 + drift * t) * 0.070;
	s += noise_grad(pm * 1.9 - drift.yx * t * 1.6) * 0.040;
	// Fade the micro-normals with distance (no far shimmer); rough
	// rises instead, which keeps the far sheen soft.
	s *= wave_amp / (1.0 + dist_m / 90.0);
	// Frozen water: still, matte, white-grey ice (ClimateModel).
	s *= 1.0 - climate_water_ice;
	vec3 n_world = normalize(vec3(-s.x, 1.0, -s.y));
	// Always the upward normal: water is only ever seen from above,
	// and its triangles wind either way (cull_disabled).
	NORMAL = normalize((VIEW_MATRIX * vec4(n_world, 0.0)).xyz);
	float open_w = smoothstep(0.0, 1.0, clamp(openv, 0.0, 1.0));
	vec3 ice = mix(vec3(0.70, 0.76, 0.80), vec3(0.86, 0.89, 0.92), snow_line(wpos));
	ALBEDO = mix(mix(shallow_color.rgb, deep_color.rgb, open_w), ice, climate_water_ice);
	ROUGHNESS = mix(mix(near_rough, far_rough, smoothstep(60.0, 900.0, dist_m)), 0.55, climate_water_ice);
	SPECULAR = mix(spec, 0.25, climate_water_ice);
	METALLIC = 0.0;
}
"""

static var _mat: ShaderMaterial

## Shared water material; units_per_metre tracks WorldScale (the
## legacy 880 m equivalence flag may flip between builds/tests).
static func material() -> ShaderMaterial:
	if _mat == null:
		var sh := Shader.new()
		sh.code = SHADER.replace("// @SNOW", ClimateModel.SNOW_GLSL)
		_mat = ShaderMaterial.new()
		_mat.shader = sh
	_mat.set_shader_parameter("units_per_metre", WorldScale.metres_to_units())
	return _mat

static func _commit(root: Node3D, verts: PackedVector3Array,
		colors: PackedColorArray, indices: PackedInt32Array,
		mat: Material) -> void:
	if indices.is_empty():
		return
	var normals := PackedVector3Array()
	normals.resize(verts.size())
	normals.fill(Vector3.UP)
	var uvs := PackedVector2Array()
	uvs.resize(verts.size())
	for i in verts.size():
		uvs[i] = Vector2(verts[i].x, verts[i].z) * 0.02
	var mesh := ArrayMesh.new()
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	TerrainBuilder._add(root, mesh, mat)

## One clipped water-polygon part as a flat surface at `level`: rim
## samples (exact shoreline + island rims) plus interior posts, Delaunay
## triangulated and kept where the triangle centroid is water. Interior
## vertices carry openness for the shore → open-water colour ramp; this
## also replaces the v1 half-post block grid for holed polygons, so
## islands keep their real outline.
static func add_polygon(root: Node3D, part: PackedVector2Array,
		holes: Array, level: float, step: float, mat: Material) -> void:
	if part.size() < 3:
		return
	var rim_sp := maxf(step * 0.5, 0.5)
	var grid := maxf(step, 1.0)
	var ramp := OPEN_RAMP_M * WorldScale.metres_to_units()
	var bb := _bbox(part)
	var rims := PackedVector2Array(_resample_ring(part, rim_sp))
	for h in holes:
		if not (h is PackedVector2Array):
			continue
		for p in _resample_ring(h as PackedVector2Array, rim_sp):
			if p.x >= bb[0] - grid and p.x <= bb[2] + grid \
					and p.y >= bb[1] - grid and p.y <= bb[3] + grid:
				rims.append(p)
	var buckets := _bucket(rims, grid)
	var pts := PackedVector2Array(rims)
	var openness := PackedFloat32Array()
	openness.resize(rims.size())
	openness.fill(0.0)
	var reach := int(ceil(ramp / grid))
	var z: float = bb[1] + grid * 0.5
	while z < bb[3]:
		var x: float = bb[0] + grid * 0.5
		while x < bb[2]:
			var c := Vector2(x, z)
			if Geometry2D.is_point_in_polygon(c, part) \
					and not _in_any_hole(c, holes):
				var d := _nearest(buckets, c, grid, reach)
				if d > grid * 0.45:
					pts.append(c)
					openness.append(clampf(d / maxf(ramp, 0.001), 0.0, 1.0))
			x += grid
		z += grid
	var tri := Geometry2D.triangulate_delaunay(pts)
	if tri.is_empty():
		# Degenerate input (duplicate/collinear rim): exact rim only.
		pts = part
		openness.resize(part.size())
		openness.fill(0.0)
		tri = Geometry2D.triangulate_polygon(part)
	var verts := PackedVector3Array()
	var colors := PackedColorArray()
	for i in pts.size():
		verts.append(Vector3(pts[i].x, level, pts[i].y))
		colors.append(Color(openness[i], 0.0, 0.0))
	var indices := PackedInt32Array()
	for t in range(0, tri.size(), 3):
		var cen := (pts[tri[t]] + pts[tri[t + 1]] + pts[tri[t + 2]]) / 3.0
		if Geometry2D.is_point_in_polygon(cen, part) \
				and not _in_any_hole(cen, holes):
			indices.append_array([tri[t], tri[t + 1], tri[t + 2]])
	_commit(root, verts, colors, indices, mat)

## Miter-joint channel ribbon with a centre row (openness 0 at both
## banks, rising toward the centre for wide rivers). Draped ribbons
## hug the ground + 0.06; others sit flat at `level`.
static func add_ribbon(root: Node3D, line: PackedVector2Array,
		half: float, ground: GroundTruth, level: float, draped: bool,
		mat: Material, lift: float = 0.05) -> void:
	var ramp := OPEN_RAMP_M * WorldScale.metres_to_units()
	var mid_open := clampf(half / maxf(ramp, 0.001), 0.0, 1.0)
	var verts := PackedVector3Array()
	var colors := PackedColorArray()
	var indices := PackedInt32Array()
	for i in line.size():
		var prev := line[maxi(i - 1, 0)]
		var next := line[mini(i + 1, line.size() - 1)]
		var dir := next - prev
		if dir.length() < 0.001:
			dir = Vector2(1, 0)
		dir = dir.normalized()
		var n := Vector2(-dir.y, dir.x)
		var row := [line[i] + n * half, line[i], line[i] - n * half]
		# Sloping channels follow GroundTruth's bank-levelled carve
		# surface down the valley; `level` (the run's bank level) only
		# where the centreline has no carved post near it.
		var row_level := level
		var local := ground.water_level_at(line[i].x, line[i].y)
		if local > ground.water_level_m + 0.001:
			row_level = local + lift
		for j in 3:
			var p: Vector2 = row[j]
			var y := ground.height_at_world(p.x, p.y) + 0.06 if draped \
				else row_level
			verts.append(Vector3(p.x, y, p.y))
			colors.append(Color(mid_open if j == 1 else 0.0, 0.0, 0.0))
		if i > 0:
			var k := i * 3
			var q := k - 3
			indices.append_array([q, q + 1, k, q + 1, k + 1, k,
				q + 1, q + 2, k + 1, q + 2, k + 2, k + 1])
	_commit(root, verts, colors, indices, mat)

## Closed ring resampled ≤ sp apart (vertices kept exactly).
static func _resample_ring(ring: PackedVector2Array, sp: float) -> Array:
	var out: Array = []
	var seen := {}
	for i in ring.size():
		var a := ring[i]
		var b := ring[(i + 1) % ring.size()]
		var n := maxi(1, int(ceil(a.distance_to(b) / sp)))
		for s in n:
			var p := a.lerp(b, float(s) / float(n))
			# Delaunay rejects coincident points (closed rings repeat
			# their first vertex; OSM rings can double back).
			var key := Vector2i(roundi(p.x * 100.0), roundi(p.y * 100.0))
			if not seen.has(key):
				seen[key] = true
				out.append(p)
	return out

static func _bucket(pts: PackedVector2Array, cell: float) -> Dictionary:
	var out := {}
	for p in pts:
		var key := Vector2i(floori(p.x / cell), floori(p.y / cell))
		if not out.has(key):
			out[key] = PackedVector2Array()
		var arr: PackedVector2Array = out[key]
		arr.append(p)
		out[key] = arr
	return out

## Distance to the nearest rim sample within `reach` buckets (INF-free:
## past the reach the point is open water, returned as reach cells).
static func _nearest(buckets: Dictionary, c: Vector2, cell: float,
		reach: int) -> float:
	var key := Vector2i(floori(c.x / cell), floori(c.y / cell))
	var best := float(reach + 1) * cell
	for dz in range(-reach, reach + 1):
		for dx in range(-reach, reach + 1):
			var k := key + Vector2i(dx, dz)
			if not buckets.has(k):
				continue
			for p in buckets[k] as PackedVector2Array:
				best = minf(best, p.distance_to(c))
	return best

static func _in_any_hole(c: Vector2, holes: Array) -> bool:
	for h in holes:
		if h is PackedVector2Array \
				and Geometry2D.is_point_in_polygon(c, h as PackedVector2Array):
			return true
	return false

## [minx, minz, maxx, maxz] bounds of a ring.
static func _bbox(ring: PackedVector2Array) -> Array:
	var bb := [INF, INF, -INF, -INF]
	for p in ring:
		bb[0] = minf(bb[0], p.x)
		bb[1] = minf(bb[1], p.y)
		bb[2] = maxf(bb[2], p.x)
		bb[3] = maxf(bb[3], p.y)
	return bb
